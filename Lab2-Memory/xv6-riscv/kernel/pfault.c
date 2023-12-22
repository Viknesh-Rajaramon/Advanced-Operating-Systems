/* This file contains code for a generic page fault handler for processes. */
#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "elf.h"

#include "sleeplock.h"
#include "fs.h"
#include "buf.h"

int loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz);
int flags2perm(int flags);

/* CSE 536: (2.4) read current time. */
uint64 read_current_timestamp() {
  uint64 curticks = 0;
  acquire(&tickslock);
  curticks = ticks;
  wakeup(&ticks);
  release(&tickslock);
  return curticks;
}

bool psa_tracker[PSASIZE];

/* All blocks are free during initialization. */
void init_psa_regions(void)
{
    for (int i = 0; i < PSASIZE; i++) 
        psa_tracker[i] = false;
}

/* Evict heap page to disk when resident pages exceed limit */
void evict_page_to_disk(struct proc* p) {
    /* Find free block */
    int blockno = -1;
    for (int i = 0; i < PSASIZE; i+=4) {
        if (psa_tracker[i] == false) {
            blockno = i;
            break;
        }
    }
    /* Find victim page using FIFO. */
    int victim_page_index = -1;
    for (int i = 0; i < MAXHEAP; i++) {
        if (p->heap_tracker[i].loaded == true && victim_page_index == -1)
            victim_page_index = i;
        else if (p->heap_tracker[i].loaded == true && p->heap_tracker[i].last_load_time < p->heap_tracker[victim_page_index].last_load_time)
            victim_page_index = i;
        else {}
    }
    /* Print statement. */
    print_evict_page(p->heap_tracker[victim_page_index].addr, blockno);
    p->heap_tracker[victim_page_index].startblock = blockno;
    p->heap_tracker[victim_page_index].loaded = false;
    
    /* Read memory from the user to kernel memory first. */
    char *kernel_page = kalloc();
    if (copyin(p->pagetable, kernel_page, p->heap_tracker[victim_page_index].addr, PGSIZE) < 0)
        panic("Error in copyin()");

    /* Write to the disk blocks. Below is a template as to how this works. There is
     * definitely a better way but this works for now. :p */
    struct buf* b;
    for (int i = 0; i < 4; i++) {
        b = bread(1, PSASTART+(blockno+i));
        memmove(b->data, kernel_page + i*BSIZE, BSIZE); // Copy page contents to b.data using memmove.
        bwrite(b);
        brelse(b);
        psa_tracker[blockno+i] = true;
    }

    /* Unmap swapped out page */
    uvmunmap(p->pagetable, p->heap_tracker[victim_page_index].addr, 1, 0);
    kfree(kernel_page);
    /* Update the resident heap tracker. */
    p->resident_heap_pages--;
}

/* Retrieve faulted page from disk. */
void retrieve_page_from_disk(struct proc* p, uint64 uvaddr) {
    /* Find where the page is located in disk */
    int index = -1;
    for (index = 0; index < MAXHEAP; index++) {
        if (p->heap_tracker[index].addr == uvaddr && p->heap_tracker[index].startblock != -1) {
            break;
        }
    }
    /* Print statement. */
    print_retrieve_page(uvaddr, p->heap_tracker[index].startblock);

    /* Create a kernel page to read memory temporarily into first. */
    char *kernel_page = kalloc();
    
    /* Read the disk block into temp kernel page. */
    struct buf* b;
    for (int i = 0; i < 4; i++) {
        b = bread(1, PSASTART+(p->heap_tracker[index].startblock+i));
        memmove(kernel_page + i*BSIZE, b->data, BSIZE);
        brelse(b);
        psa_tracker[p->heap_tracker[index].startblock+i] = false;
    }

    /* Copy from temp kernel page to uvaddr (use copyout) */
    if (copyout(p->pagetable, uvaddr, kernel_page, PGSIZE) == -1)
        panic("Error in copyout()");
    
    kfree(kernel_page);
}


void page_fault_handler(void) 
{
    /* Current process struct */
    struct proc *p = myproc();

    /* Find faulting address. */
    uint64 faulting_addr = PGROUNDDOWN(r_stval());
    print_page_fault(p->name, faulting_addr);

    if (r_scause() == 15 && p->cow_enabled) {
        copy_on_write();
        goto out;
    }

    /* Track whether the heap page should be brought back from disk or not. */
    bool load_from_disk = false;
    for (int i = 0; i < MAXHEAP; i++) {
        if (p->heap_tracker[i].addr == faulting_addr && p->heap_tracker[i].startblock != -1) {
            load_from_disk = true;
            break;
        }
    }

    /* Check if the fault address is a heap page. Use p->heap_tracker */
    bool is_heap_page = false;
    int index = -1;
    for (int i = 0; i < MAXHEAP; i++) {
        if (p->heap_tracker[i].addr == faulting_addr) {
            is_heap_page = true;
            index = i;
            break;
        }
    }

    if (is_heap_page) {
        goto heap_handle;
    }

    /* If it came here, it is a page from the program binary that we must load. */
    struct inode *ip;
    if((ip = namei(p->name)) == 0)
        return;

    struct elfhdr elf;
    readi(ip, 0, (uint64)&elf, 0, sizeof(elf));

    struct proghdr ph;
    for(int i = 0, off = elf.phoff; i < elf.phnum; i++, off += sizeof(ph)) {
        readi(ip, 0, (uint64)&ph, off, sizeof(ph));
        if (ph.vaddr <= faulting_addr && faulting_addr < ph.vaddr + ph.memsz)
            break;
    }
    uvmalloc(p->pagetable, faulting_addr, faulting_addr + ph.memsz, flags2perm(ph.flags));
    loadseg(p->pagetable, faulting_addr, ip, ph.off, ph.filesz);
    print_load_seg(faulting_addr, ph.off, ph.filesz);

    /* Go to out, since the remainder of this code is for the heap. */
    goto out;

heap_handle:
    /* 2.4: Check if resident pages are more than heap pages. If yes, evict. */
    if (p->resident_heap_pages == MAXRESHEAP) {
        evict_page_to_disk(p);
    }

    /* 2.3: Map a heap page into the process' address space. (Hint: check growproc) */
    uint64 sz;
    if ((sz = uvmalloc(p->pagetable, faulting_addr, faulting_addr + PGSIZE, PTE_W)) < 0)
        panic("uvmalloc error inside heap_handle");

    /* 2.4: Heap page was swapped to disk previously. We must load it from disk. */
    if (load_from_disk) {
        retrieve_page_from_disk(p, faulting_addr);
    }

    /* 2.4: Update the last load time for the loaded heap page in p->heap_tracker. */
    p->heap_tracker[index].last_load_time = read_current_timestamp();
    p->heap_tracker[index].loaded = true;

    /* Track that another heap page has been brought into memory. */
    p->resident_heap_pages++;

out:
    /* Flush stale page table entries. This is important to always do. */
    sfence_vma();
    return;
}
