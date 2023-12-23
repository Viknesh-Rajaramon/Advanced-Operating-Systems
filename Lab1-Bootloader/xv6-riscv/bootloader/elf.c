#include "types.h"
#include "param.h"
#include "layout.h"
#include "riscv.h"
#include "defs.h"
#include "buf.h"
#include "elf.h"

#include <stdbool.h>

struct elfhdr* kernel_elfhdr;
struct proghdr* kernel_phdr;

uint64 find_kernel_load_addr(enum kernel ktype) {
    /* CSE 536: Get kernel load address from headers */
    uint64 addr = 0x0;
  
    if (ktype == NORMAL)
      addr = RAMDISK;
    else if (ktype == RECOVERY)
      addr = RECOVERYDISK;
    
    kernel_elfhdr = (struct elfhdr *) addr;
    kernel_phdr = (struct proghdr *) (addr + kernel_elfhdr->phoff + kernel_elfhdr->phentsize);
    return kernel_phdr->vaddr;
}

uint64 find_kernel_size(enum kernel ktype) {
    /* CSE 536: Get kernel binary size from headers */
    uint64 addr = 0x0;
  
    if (ktype == NORMAL)
      addr = RAMDISK;
    else if (ktype == RECOVERY)
      addr = RECOVERYDISK;
      
    kernel_elfhdr = (struct elfhdr *) addr;
    uint64 ksize = (uint64) (kernel_elfhdr->shoff + kernel_elfhdr->shentsize * kernel_elfhdr->shnum);
    return ksize;
}

uint64 find_kernel_entry_addr(enum kernel ktype) {
    /* CSE 536: Get kernel entry point from headers */
    uint64 addr = 0x0;
  
    if (ktype == NORMAL)
      addr = RAMDISK;
    else if (ktype == RECOVERY)
      addr = RECOVERYDISK;
      
    kernel_elfhdr = (struct elfhdr *) addr;
    return kernel_elfhdr->entry;
}

