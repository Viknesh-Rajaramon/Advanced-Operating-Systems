#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "elf.h"
#include <stdbool.h>

struct spinlock cow_lock;

// Max number of pages a CoW group of processes can share
#define SHMEM_MAX 100

struct cow_group {
    int group; // group id
    uint64 shmem[SHMEM_MAX]; // list of pages a CoW group share
    int count; // Number of active processes
};

struct cow_group cow_group[NPROC];

struct cow_group* get_cow_group(int group) {
    if(group == -1)
        return 0;

    for(int i = 0; i < NPROC; i++) {
        if(cow_group[i].group == group)
            return &cow_group[i];
    }
    return 0;
}

void cow_group_init(int groupno) {
    for(int i = 0; i < NPROC; i++) {
        if(cow_group[i].group == -1) {
            cow_group[i].group = groupno;
            return;
        }
    }
} 

int get_cow_group_count(int group) {
    return get_cow_group(group)->count;
}
void incr_cow_group_count(int group) {
    get_cow_group(group)->count = get_cow_group_count(group)+1;
}
void decr_cow_group_count(int group) {
    get_cow_group(group)->count = get_cow_group_count(group)-1;
}

void add_shmem(int group, uint64 pa) {
    if(group == -1)
        return;

    uint64 *shmem = get_cow_group(group)->shmem;
    int index;
    for(index = 0; index < SHMEM_MAX; index++) {
        // duplicate address
        if(shmem[index] == pa)
            return;
        if(shmem[index] == 0)
            break;
    }
    shmem[index] = pa;
}

int is_shmem(int group, uint64 pa) {
    if(group == -1)
        return 0;

    uint64 *shmem = get_cow_group(group)->shmem;
    for(int i = 0; i < SHMEM_MAX; i++) {
        if(shmem[i] == 0)
            return 0;
        if(shmem[i] == pa)
            return 1;
    }
    return 0;
}

void cow_init() {
    for(int i = 0; i < NPROC; i++) {
        cow_group[i].count = 0;
        cow_group[i].group = -1;
        for(int j = 0; j < SHMEM_MAX; j++)
            cow_group[i].shmem[j] = 0;
    }
    initlock(&cow_lock, "cow_lock");
}

int uvmcopy_cow(pagetable_t old, pagetable_t new, uint64 sz) {
    
    /* CSE 536: (2.6.1) Handling Copy-on-write fork() */
	pte_t *pte;
	uint64 pa, i;
	int flags;

	struct proc *p = myproc();
	if ((get_cow_group(p->cow_group)) == 0) {
		cow_group_init(p->cow_group);
		incr_cow_group_count(p->cow_group);
	}

	for (i = 0; i < sz; i += PGSIZE)
	{
		if ((pte = walk(old, i, 0)) == 0)
			panic("uvmcopy_cow: pte should exist");
		if ((*pte & PTE_V) == 0)
			panic("uvmcopy_cow: page not present");

		pa = PTE2PA(*pte);
		flags = PTE_FLAGS(*pte);
		flags &= (~PTE_W);
		// Copy user vitual memory from old(parent) to new(child) process
		if (mappages(new, i, PGSIZE, pa, flags) != 0)
			panic("uvmcopy_cow: mappages new");
		
		uvmunmap(old, i, 1, 0);
    	// Map pages as Read-Only in both the processes
		if (mappages(old, i, PGSIZE, pa, flags) != 0)
			panic("uvmcopy_cow: mappages old");

		add_shmem(p->cow_group, pa);
	}
	incr_cow_group_count(p->cow_group);
	
    return 0;
}

void copy_on_write() {
    /* CSE 536: (2.6.2) Handling Copy-on-write */
	struct proc *p = myproc();
	uint64 faulting_addr = PGROUNDDOWN(r_stval());
	print_copy_on_write(p, faulting_addr);

    // Allocate a new page 
	char *mem;
	if ((mem = kalloc()) == 0)
		panic("copy_on_write: kalloc");

    // Copy contents from the shared page to the new page
  	pte_t *pte;
  	if ((pte = walk(p->pagetable, faulting_addr, 0)) == 0)
    	panic("copy_on_write: pte should exist");

    char *pa = (char *)PTE2PA(*pte);
    memmove(mem, pa, PGSIZE);
	int flags = PTE_FLAGS(*pte) | PTE_W;

    uvmunmap(p->pagetable, faulting_addr, 1, 0);
    // Map the new page in the faulting process's page table with write permissions
    if (mappages(p->pagetable, faulting_addr, PGSIZE, (uint64)mem, flags) != 0)
    	panic("copy_on_write: mappages");
}

