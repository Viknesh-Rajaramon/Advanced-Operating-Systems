#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

#include <stdbool.h>

#define U_MODE 1
#define S_MODE 2
#define M_MODE 3

#define VMM_BASE_ADDRESS 0x80000000
#define VMM_MAX_ADDRESS  0x80400000

// Struct to keep VM registers (Sample; feel free to change.)
struct vm_reg {
    int     code;
    int     mode;
    uint64  val;
};

// Keep the virtual state of the VM's privileged registers
struct vm_virtual_state {
    // User trap setup
    struct vm_reg ustatus;
    struct vm_reg uie;
    struct vm_reg utvec;

    // User trap handling
    struct vm_reg uscratch;
    struct vm_reg uepc;
    struct vm_reg ucause;
    struct vm_reg utval;
    struct vm_reg uip;

    // Supervisor trap setup
    struct vm_reg sstatus;
    struct vm_reg sedeleg;
    struct vm_reg sideleg;
    struct vm_reg sie;
    struct vm_reg stvec;
    struct vm_reg scounteren;

    // Supervisor trap handling
    struct vm_reg sscratch;
    struct vm_reg sepc;
    struct vm_reg scause;
    struct vm_reg stval;
    struct vm_reg sip;

    // Supervisor page table register
    struct vm_reg satp;

    // Machine information registers
    struct vm_reg mvendorid;
    struct vm_reg marchid;
    struct vm_reg mimpid;
    struct vm_reg mhartid;

    // Machine trap setup registers
    struct vm_reg mstatus;
    struct vm_reg misa;
    struct vm_reg medeleg;
    struct vm_reg mideleg;
    struct vm_reg mie;
    struct vm_reg mtvec;
    struct vm_reg mcounteren;

    // Machine trap handling registers
    struct vm_reg mscratch;
    struct vm_reg mepc;
    struct vm_reg mcause;
    struct vm_reg mtval;
    struct vm_reg mip;

    // Machine physical memory protection registers
    struct vm_reg pmpcfg[16];
    struct vm_reg pmpaddr[64];    

    uint64 priviledge_mode;
    bool pmp_setup;
    pagetable_t pmp_pagetable;
    pagetable_t og_pagetable;
};

struct vm_virtual_state vm;

struct vm_reg *get_vm_privileged_register(uint32 reg, struct vm_virtual_state *vm) {
    switch (reg) {
        // User trap setup
        case 0x0000:
            return &vm->ustatus;
        case 0x0004:
            return &vm->uie;
        case 0x0005:
            return &vm->utvec;
        
        // User trap handling
        case 0x0040:
            return &vm->uscratch;
        case 0x0041:
            return &vm->uepc;
        case 0x0042:
            return &vm->ucause;
        case 0x0043:
            return &vm->utval;
        case 0x0044:
            return &vm->uip;
        
        // Supervisor trap setup
        case 0x0100:
            return &vm->sstatus;
        case 0x0102:
            return &vm->sedeleg;
        case 0x0103:
            return &vm->sideleg;
        case 0x0104:
            return &vm->sie;
        case 0x0105:
            return &vm->stvec;
        case 0x0106:
            return &vm->scounteren;
        
        // Supervisor trap handling
        case 0x0140:
            return &vm->sscratch;
        case 0x0141:
            return &vm->sepc;
        case 0x0142:
            return &vm->scause;
        case 0x0143:
            return &vm->stval;
        case 0x0144:
            return &vm->sip;
        
        // Supervisor page table
        case 0x0180:
            return &vm->satp;
        
        // Machine information
        case 0x0f11:
            return &vm->mvendorid;
        case 0x0f12:
            return &vm->marchid;
        case 0x0f13:
            return &vm->mimpid;
        case 0x0f14:
            return &vm->mhartid;
        
        // Machine trap setup
        case 0x0300:
            return &vm->mstatus;
        case 0x0301:
            return &vm->misa;
        case 0x0302:
            return &vm->medeleg;
        case 0x0303:
            return &vm->mideleg;
        case 0x0304:
            return &vm->mie;
        case 0x0305:
            return &vm->mtvec;
        case 0x0306:
            return &vm->mcounteren;
        
        // Machine trap handling
        case 0x0340:
            return &vm->mscratch;
        case 0x0341:
            return &vm->mepc;
        case 0x0342:
            return &vm->mcause;
        case 0x0343:
            return &vm->mtval;
        case 0x0344:
            return &vm->mip;
        
        // Machine physical memory protection
        case 0x03a0 ... 0x03af:
            if (reg == 0x03a0) // Enable PMP only using pmpcfg0 register to avoid crashing
                vm->pmp_setup = true;
            return &vm->pmpcfg[reg - 0x03a0];
        case 0x03b0 ... 0x03ef:
            return &vm->pmpaddr[reg - 0x03b0];
        
        default:
            break;
    }

    return (struct vm_reg *) 0;
}

uint64 *get_vm_trapframe_register(uint32 reg, struct trapframe *tf) {
    return (uint64 *)((reg - 1) * 8 + (uint64)&tf->ra); // reg == 1 is tf->ra
}

// In your ECALL, add the following for prints
// struct proc* p = myproc();
// printf("(EC at %p)\n", p->trapframe->epc);

int copy_psuedo(pagetable_t old, pagetable_t new, uint64 sz) {
    pte_t *pte;
    uint64 pa, i;
    uint flags;

    for (i = 0; i < sz; i += PGSIZE) {
        if ((pte = walk(old, i, 0)) == 0)
            panic("uvmcopy: pte should exist");
        if ((*pte & PTE_V) == 0)
            panic("uvmcopy: page not present");
        
        pa = PTE2PA(*pte);
        flags = PTE_FLAGS(*pte);

        if (mappages(new, i, PGSIZE, pa, flags) != 0)
            goto err;
    }
    return 0;

    err:
        uvmunmap(new, 0, i / PGSIZE, 1);
        return -1;
}

int map_psuedo(pagetable_t old, pagetable_t new, uint64 lowerbound, uint64 upperbound) {
    pte_t *pte;
    uint64 pa, i;
    uint flags;

    for (i = lowerbound; i < upperbound; i += PGSIZE) {
        if ((pte = walk(old, i, 0)) == 0)
            panic("uvmcopy: pte should exist");
        if ((*pte & PTE_V) == 0)
            panic("uvmcopy: page not present");
        
        pa = PTE2PA(*pte);
        flags = PTE_FLAGS(*pte);

        if (mappages(new, i, PGSIZE, pa, flags) != 0)
            goto err;
    }
    return 0;

    err:
        uvmunmap(new, 0, i / PGSIZE, 1);
        return -1;
}

void pmp_not_configured(struct proc *p) {
    printf("[DEBUG]: Accessing unmapped region. Killing VM...\n");
    setkilled(p);
}

void trap_and_emulate(void) {
    /* Comes here when a VM tries to execute a supervisor instruction. */
    struct proc *p = myproc();

    /* Retrieve all required values from the instruction */
    uint64 addr     = r_sepc();
    uint32 inst;
    copyin(p->pagetable, (char *) &inst, addr, sizeof(uint32));
    uint32 op       = (inst) & 0x7F;
    uint32 rd       = (inst >> 7) & 0x1F;
    uint32 funct3   = (inst >> 12) & 0x7;
    uint32 rs1      = (inst >> 15) & 0x1F;
    uint32 uimm     = (inst >> 20) & 0xFFF;
    
    switch (funct3) {
        case 0x0: // ECALL, SRET, MRET
            if (op == 0x73 && rd == 0x0 && rs1 == 0x0) {
                if (uimm == 0x0 && p->proc_te_vm == 1) { // ECALL
                    printf("(EC at %p)\n", p->trapframe->epc);

                    switch (vm.priviledge_mode) {
                        case U_MODE:
                            vm.sepc.val = p->trapframe->epc;
                            vm.priviledge_mode = S_MODE;
                            p->trapframe->epc = vm.stvec.val;
                            if (vm.pmp_setup == true)
                                p->pagetable = vm.pmp_pagetable;
                            break;

                        case S_MODE:
                            vm.mepc.val = p->trapframe->epc;
                            vm.priviledge_mode = M_MODE;
                            p->trapframe->epc = vm.mtvec.val;
                            if (vm.pmp_setup == true)
                                p->pagetable = vm.og_pagetable;
                            break;

                        default:
                            break;
                    }
                } else if (uimm == 0x102 && vm.priviledge_mode == S_MODE) { // SRET
                    /* Print the statement */
                    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);
                    
                    switch ((vm.sstatus.val & SSTATUS_SPP) >> 8) {
                        case 0x0: // User
                            vm.priviledge_mode = U_MODE;
                            break;
                        
                        case 0x1: // Supervisor
                            vm.priviledge_mode = S_MODE;
                            break;
                        
                        default:
                            setkilled(p);
                            return;
                    }
                    p->trapframe->epc = vm.sepc.val;
                } else if (uimm == 0x302 && vm.priviledge_mode == M_MODE) { // MRET
                    /* Print the statement */
                    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);
                    
                    switch ((vm.mstatus.val & MSTATUS_MPP_MASK) >> 11) {
                        case 0x0: // User
                            vm.priviledge_mode = U_MODE;
                            if (vm.pmp_setup == true)
                                p->pagetable = vm.pmp_pagetable;
                            else
                                pmp_not_configured(p);
                            break;
                        
                        case 0x1: // Supervisor
                            vm.priviledge_mode = S_MODE;
                            if (vm.pmp_setup == true)
                                p->pagetable = vm.pmp_pagetable;
                            else
                                pmp_not_configured(p);
                            break;
                        
                        case 0x3: // Machine
                            vm.priviledge_mode = M_MODE;
                            break;                        
                        
                        default:
                            setkilled(p);
                            return;
                    }
                    p->trapframe->epc = vm.mepc.val;
                } else {
                    /* Print the statement */
                    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);
                    p->pagetable = vm.og_pagetable;
                    setkilled(p);
                }
            } else {
                /* Print the statement */
                printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);
                p->pagetable = vm.og_pagetable;
                setkilled(p);
            }
            break;
        
        case 0x1: // CSRW
            /* Print the statement */
            printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);

            if (op == 0x73 && rd == 0x0) { // CSRW
                uint64 *src = get_vm_trapframe_register(rs1, p->trapframe);
                struct vm_reg *dest = get_vm_privileged_register(uimm, &vm);

                if (vm.priviledge_mode >= dest->mode && uimm != 0xf11) {                    
                    dest->val = *src;
                    p->trapframe->epc += 4;

                    if (vm.pmp_setup == true && dest->code == 0x03a0) { // Check if PMP enabled and pmpcfg0 is fetched
                        if (((dest->val >> 3) & 0x3) == 0x1) { // Check if TOR mode is enabled
                            // dest points to pmpcfg0
                            uint64 pmp_addr = (dest + 0x10)->val << 2; // << 2 is since TOR is 4-byte aligned
                            vm.og_pagetable = p->pagetable;
                            vm.pmp_pagetable = proc_pagetable(p);
                            copy_psuedo(vm.og_pagetable, vm.pmp_pagetable, p->sz);
                            map_psuedo(vm.og_pagetable, vm.pmp_pagetable, VMM_BASE_ADDRESS, PGROUNDUP(pmp_addr));
                        } else {           
                            vm.pmp_setup = false;
                        }
                    }
                } else if (vm.priviledge_mode >= dest->mode && uimm == 0xf11) { // Writing to mvendorid
                    dest->val = *src;
                    p->trapframe->epc += 4;
                    if (dest->val == 0x0)
                        setkilled(p);
                } else {
                    p->pagetable = vm.og_pagetable;
                    setkilled(p);
                }
            } else {
                p->pagetable = vm.og_pagetable;
                setkilled(p);
            }
            break;
        
        case 0x2: // CSRR
            /* Print the statement */
            printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);

            if (op == 0x73 && rs1 == 0x0) { // CSRR
                struct vm_reg *src = get_vm_privileged_register(uimm, &vm);
                uint64 *dest = get_vm_trapframe_register(rd, p->trapframe);
                
                if (vm.priviledge_mode >= src->mode) {
                    *dest = src->val;
                    p->trapframe->epc += 4;
                } else if (src->code == 0x0f11) { // allow mvendorid register to be read in all modes
                    *dest = src->val;
                    p->trapframe->epc += 4;
                } else {
                p->pagetable = vm.og_pagetable;
                    setkilled(p);
                }
            } else {
                p->pagetable = vm.og_pagetable;
                setkilled(p);
            }
            break;
        
        default:
            setkilled(p);
            break;
    }
}

void init_user_mode_registers() {
    // User trap setup
    vm.ustatus.code = 0x0000;
    vm.ustatus.mode = U_MODE;
    vm.ustatus.val = 0x0;
    
    vm.uie.code = 0x0004;
    vm.uie.mode = U_MODE;
    vm.uie.val = 0x0;
    
    vm.utvec.code = 0x0005;
    vm.utvec.mode = U_MODE;
    vm.utvec.val = 0x0;

    // User trap handling
    vm.uscratch.code = 0x0040;
    vm.uscratch.mode = U_MODE;
    vm.uscratch.val = 0x0;

    vm.uepc.code = 0x0041;
    vm.uepc.mode = U_MODE;
    vm.uepc.val = 0x0;

    vm.ucause.code = 0x0042;
    vm.ucause.mode = U_MODE;
    vm.ucause.val = 0x0;

    vm.utval.code = 0x0043;
    vm.utval.mode = U_MODE;
    vm.utval.val = 0x0;

    vm.uip.code = 0x0044;
    vm.uip.mode = U_MODE;
    vm.uip.val = 0x0;
}

void init_supervisor_mode_registers() {
    // Supervisor trap setup
    vm.sstatus.code = 0x0100;
    vm.sstatus.mode = S_MODE;
    vm.sstatus.val = 0x0;

    vm.sedeleg.code = 0x0102;
    vm.sedeleg.mode = S_MODE;
    vm.sedeleg.val = 0x0;

    vm.sideleg.code = 0x0103;
    vm.sideleg.mode = S_MODE;
    vm.sideleg.val = 0x0;

    vm.sie.code = 0x0104;
    vm.sie.mode = S_MODE;
    vm.sie.val = 0x0;

    vm.stvec.code = 0x0105;
    vm.stvec.mode = S_MODE;
    vm.stvec.val = 0x0;

    vm.scounteren.code = 0x0106;
    vm.scounteren.mode = S_MODE;
    vm.scounteren.val = 0x0;

    // Supervisor trap handling
    vm.sscratch.code = 0x0140;
    vm.sscratch.mode = S_MODE;
    vm.sscratch.val = 0x0;

    vm.sepc.code = 0x0141;
    vm.sepc.mode = S_MODE;
    vm.sepc.val = 0x0;

    vm.scause.code = 0x0142;
    vm.scause.mode = S_MODE;
    vm.scause.val = 0x0;

    vm.stval.code = 0x0143;
    vm.stval.mode = S_MODE;
    vm.stval.val = 0x0;

    vm.sip.code = 0x0144;
    vm.sip.mode = S_MODE;
    vm.sip.val = 0x0;

    // Supervisor page table
    vm.satp.code = 0x0180;
    vm.satp.mode = S_MODE;
    vm.satp.val = 0x0;
}

void init_machine_mode_registers() {
    // Machine information
    vm.mvendorid.code = 0x0f11;
    vm.mvendorid.mode = S_MODE;
    vm.mvendorid.val = 0x0;

    vm.marchid.code = 0x0f12;
    vm.marchid.mode = M_MODE;
    vm.marchid.val = 0x0;

    vm.mimpid.code = 0x0f13;
    vm.mimpid.mode = M_MODE;
    vm.mimpid.val = 0x0;

    vm.mhartid.code = 0x0f14;
    vm.mhartid.mode = M_MODE;
    vm.mhartid.val = 0x0;

    // Machine trap setup
    vm.mstatus.code = 0x0300;
    vm.mstatus.mode = M_MODE;
    vm.mstatus.val = 0x0;

    vm.misa.code = 0x0301;
    vm.misa.mode = M_MODE;
    vm.misa.val = 0x0;

    vm.medeleg.code = 0x0302;
    vm.medeleg.mode = M_MODE;
    vm.medeleg.val = 0xffff;

    vm.mideleg.code = 0x0303;
    vm.mideleg.mode = M_MODE;
    vm.mideleg.val = 0xffff;

    vm.mie.code = 0x0304;
    vm.mie.mode = M_MODE;
    vm.mie.val = 0x0;

    vm.mtvec.code = 0x0305;
    vm.mtvec.mode = M_MODE;
    vm.mtvec.val = 0x0;

    vm.mcounteren.code = 0x0306;
    vm.mcounteren.mode = M_MODE;
    vm.mcounteren.val = 0x0;

    // Machine trap handling
    vm.mscratch.code = 0x0340;
    vm.mscratch.mode = M_MODE;
    vm.mscratch.val = 0x0;

    vm.mepc.code = 0x0341;
    vm.mepc.mode = M_MODE;
    vm.mepc.val = 0x0;

    vm.mcause.code = 0x0342;
    vm.mcause.mode = M_MODE;
    vm.mcause.val = 0x0;

    vm.mtval.code = 0x0343;
    vm.mtval.mode = M_MODE;
    vm.mtval.val = 0x0;

    vm.mip.code = 0x0344;
    vm.mip.mode = M_MODE;
    vm.mip.val = 0x0;

    // Machine physical memory protection
    for (int i =0; i < 16; i++) {
        vm.pmpcfg[i].code = 0x03a0 + i;
        vm.pmpcfg[i].mode = M_MODE;
        vm.pmpcfg[i].val = 0x0;
    }
    
    for (int i =0; i < 64; i++) {
        vm.pmpaddr[i].code = 0x03b0 + i;
        vm.pmpaddr[i].mode = M_MODE;
        vm.pmpaddr[i].val = 0x0;
    }
}

void trap_and_emulate_init(void) {
    /* Create and initialize all state for the VM */
    init_user_mode_registers();
    init_supervisor_mode_registers();
    init_machine_mode_registers();

    vm.mvendorid.val = 0x637365353336; // Set mvendorid to "cse536" in hexadecimal
    vm.priviledge_mode = M_MODE;       // VM should boot at M-Mode
}
