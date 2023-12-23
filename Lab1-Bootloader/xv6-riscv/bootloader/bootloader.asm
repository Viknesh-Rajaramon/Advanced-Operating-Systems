
bootloader/bootloader:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00001117          	auipc	sp,0x1
    80000004:	c9010113          	addi	sp,sp,-880 # 80000c90 <bl_stack>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	1be000ef          	jal	ra,800001d4 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <panic>:
};
struct sys_info* sys_info_ptr;

extern void _entry(void);
void panic(char *s)
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
  for(;;)
    80000022:	a001                	j	80000022 <panic+0x6>

0000000080000024 <setup_recovery_kernel>:
    ;
}

/* CSE 536: Boot into the RECOVERY kernel instead of NORMAL kernel
 * when hash verification fails. */
void setup_recovery_kernel(void) {
    80000024:	b8010113          	addi	sp,sp,-1152
    80000028:	46113c23          	sd	ra,1144(sp)
    8000002c:	46813823          	sd	s0,1136(sp)
    80000030:	46913423          	sd	s1,1128(sp)
    80000034:	47213023          	sd	s2,1120(sp)
    80000038:	45313c23          	sd	s3,1112(sp)
    8000003c:	45413823          	sd	s4,1104(sp)
    80000040:	45513423          	sd	s5,1096(sp)
    80000044:	45613023          	sd	s6,1088(sp)
    80000048:	43713c23          	sd	s7,1080(sp)
    8000004c:	48010413          	addi	s0,sp,1152
  uint64 kernel_load_addr       = find_kernel_load_addr(RECOVERY);
    80000050:	4505                	li	a0,1
    80000052:	00000097          	auipc	ra,0x0
    80000056:	56a080e7          	jalr	1386(ra) # 800005bc <find_kernel_load_addr>
    8000005a:	8baa                	mv	s7,a0
  uint64 kernel_binary_size     = find_kernel_size(RECOVERY);   
    8000005c:	4505                	li	a0,1
    8000005e:	00000097          	auipc	ra,0x0
    80000062:	59e080e7          	jalr	1438(ra) # 800005fc <find_kernel_size>
    80000066:	8aaa                	mv	s5,a0
  uint64 kernel_entry           = find_kernel_entry_addr(RECOVERY);  
    80000068:	4505                	li	a0,1
    8000006a:	00000097          	auipc	ra,0x0
    8000006e:	5d0080e7          	jalr	1488(ra) # 8000063a <find_kernel_entry_addr>
    80000072:	8b2a                	mv	s6,a0
  
  char *kernel_load_address = (char *) kernel_load_addr;
    80000074:	84de                	mv	s1,s7
  uint64 no_of_blocks = kernel_binary_size / BSIZE;
    80000076:	00aada13          	srli	s4,s5,0xa
  
  for (uint64 i = 4; i < no_of_blocks; ++i) {
    8000007a:	6785                	lui	a5,0x1
    8000007c:	3ff78793          	addi	a5,a5,1023 # 13ff <_entry-0x7fffec01>
    80000080:	0557f863          	bgeu	a5,s5,800000d0 <setup_recovery_kernel+0xac>
  char *kernel_load_address = (char *) kernel_load_addr;
    80000084:	89de                	mv	s3,s7
  for (uint64 i = 4; i < no_of_blocks; ++i) {
    80000086:	4911                	li	s2,4
    80000088:	fb040493          	addi	s1,s0,-80
    struct buf b;
    b.blockno = i;
    8000008c:	b9242a23          	sw	s2,-1132(s0)
    kernel_copy(RECOVERY, &b);    
    80000090:	b8840593          	addi	a1,s0,-1144
    80000094:	4505                	li	a0,1
    80000096:	00000097          	auipc	ra,0x0
    8000009a:	30e080e7          	jalr	782(ra) # 800003a4 <kernel_copy>
    for (uint64 j = 0; j < BSIZE; ++j) {
    8000009e:	bb040793          	addi	a5,s0,-1104
    kernel_copy(RECOVERY, &b);    
    800000a2:	874e                	mv	a4,s3
      *(kernel_load_address) = b.data[j];
    800000a4:	0007c683          	lbu	a3,0(a5)
    800000a8:	00d70023          	sb	a3,0(a4)
      ++kernel_load_address;
    800000ac:	0705                	addi	a4,a4,1
    for (uint64 j = 0; j < BSIZE; ++j) {
    800000ae:	0785                	addi	a5,a5,1
    800000b0:	fef49ae3          	bne	s1,a5,800000a4 <setup_recovery_kernel+0x80>
      ++kernel_load_address;
    800000b4:	40098993          	addi	s3,s3,1024
  for (uint64 i = 4; i < no_of_blocks; ++i) {
    800000b8:	0905                	addi	s2,s2,1
    800000ba:	fd4969e3          	bltu	s2,s4,8000008c <setup_recovery_kernel+0x68>
      ++kernel_load_address;
    800000be:	87d2                	mv	a5,s4
    800000c0:	4715                	li	a4,5
    800000c2:	00ea7363          	bgeu	s4,a4,800000c8 <setup_recovery_kernel+0xa4>
    800000c6:	4795                	li	a5,5
    800000c8:	ffc78493          	addi	s1,a5,-4
    800000cc:	04aa                	slli	s1,s1,0xa
    800000ce:	94de                	add	s1,s1,s7
    }
  }
  
  if (kernel_binary_size%BSIZE != 0) {
    800000d0:	3ffafa93          	andi	s5,s5,1023
    800000d4:	020a9963          	bnez	s5,80000106 <setup_recovery_kernel+0xe2>
// instruction address to which a return from
// exception will go.
static inline void 
w_mepc(uint64 x)
{
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000d8:	341b1073          	csrw	mepc,s6
      ++kernel_load_address;
    }
  }
  
  w_mepc((uint64) kernel_entry);
}
    800000dc:	47813083          	ld	ra,1144(sp)
    800000e0:	47013403          	ld	s0,1136(sp)
    800000e4:	46813483          	ld	s1,1128(sp)
    800000e8:	46013903          	ld	s2,1120(sp)
    800000ec:	45813983          	ld	s3,1112(sp)
    800000f0:	45013a03          	ld	s4,1104(sp)
    800000f4:	44813a83          	ld	s5,1096(sp)
    800000f8:	44013b03          	ld	s6,1088(sp)
    800000fc:	43813b83          	ld	s7,1080(sp)
    80000100:	48010113          	addi	sp,sp,1152
    80000104:	8082                	ret
    b.blockno = no_of_blocks + 1;
    80000106:	2a05                	addiw	s4,s4,1
    80000108:	b9442a23          	sw	s4,-1132(s0)
    kernel_copy(RECOVERY, &b);    
    8000010c:	b8840593          	addi	a1,s0,-1144
    80000110:	4505                	li	a0,1
    80000112:	00000097          	auipc	ra,0x0
    80000116:	292080e7          	jalr	658(ra) # 800003a4 <kernel_copy>
    for (uint64 j = 0; j < kernel_binary_size%BSIZE; ++j) {
    8000011a:	bb040713          	addi	a4,s0,-1104
    8000011e:	015487b3          	add	a5,s1,s5
      *(kernel_load_address) = b.data[j];
    80000122:	00074683          	lbu	a3,0(a4)
    80000126:	00d48023          	sb	a3,0(s1)
      ++kernel_load_address;
    8000012a:	0485                	addi	s1,s1,1
    for (uint64 j = 0; j < kernel_binary_size%BSIZE; ++j) {
    8000012c:	0705                	addi	a4,a4,1
    8000012e:	fe979ae3          	bne	a5,s1,80000122 <setup_recovery_kernel+0xfe>
    80000132:	b75d                	j	800000d8 <setup_recovery_kernel+0xb4>

0000000080000134 <is_secure_boot>:

/* CSE 536: Function verifies if NORMAL kernel is expected or tampered. */
bool is_secure_boot(void) {
    80000134:	1101                	addi	sp,sp,-32
    80000136:	ec06                	sd	ra,24(sp)
    80000138:	e822                	sd	s0,16(sp)
    8000013a:	e426                	sd	s1,8(sp)
    8000013c:	e04a                	sd	s2,0(sp)
    8000013e:	1000                	addi	s0,sp,32
  bool verification = true;

  /* Read the binary and update the observed measurement 
   * (simplified template provided below) */
  sha256_init(&sha256_ctx);
    80000140:	00001497          	auipc	s1,0x1
    80000144:	ae048493          	addi	s1,s1,-1312 # 80000c20 <sha256_ctx>
    80000148:	8526                	mv	a0,s1
    8000014a:	00000097          	auipc	ra,0x0
    8000014e:	726080e7          	jalr	1830(ra) # 80000870 <sha256_init>
  sha256_update(&sha256_ctx, (const unsigned char*) RAMDISK, find_kernel_size(NORMAL));
    80000152:	4501                	li	a0,0
    80000154:	00000097          	auipc	ra,0x0
    80000158:	4a8080e7          	jalr	1192(ra) # 800005fc <find_kernel_size>
    8000015c:	862a                	mv	a2,a0
    8000015e:	02100593          	li	a1,33
    80000162:	05ea                	slli	a1,a1,0x1a
    80000164:	8526                	mv	a0,s1
    80000166:	00000097          	auipc	ra,0x0
    8000016a:	76e080e7          	jalr	1902(ra) # 800008d4 <sha256_update>
  sha256_final(&sha256_ctx, sys_info_ptr->observed_kernel_measurement);
    8000016e:	00009917          	auipc	s2,0x9
    80000172:	b2290913          	addi	s2,s2,-1246 # 80008c90 <sys_info_ptr>
    80000176:	00093583          	ld	a1,0(s2)
    8000017a:	04058593          	addi	a1,a1,64
    8000017e:	8526                	mv	a0,s1
    80000180:	00000097          	auipc	ra,0x0
    80000184:	7d8080e7          	jalr	2008(ra) # 80000958 <sha256_final>
      verification = false;
    }
  }
  */
  
  if (sys_info_ptr->observed_kernel_measurement != trusted_kernel_hash) {
    80000188:	00093783          	ld	a5,0(s2)
    8000018c:	04078793          	addi	a5,a5,64
    80000190:	00001717          	auipc	a4,0x1
    80000194:	95070713          	addi	a4,a4,-1712 # 80000ae0 <trusted_kernel_hash>
  bool verification = true;
    80000198:	4505                	li	a0,1
  if (sys_info_ptr->observed_kernel_measurement != trusted_kernel_hash) {
    8000019a:	02f70763          	beq	a4,a5,800001c8 <is_secure_boot+0x94>
      setup_recovery_kernel();
    8000019e:	00000097          	auipc	ra,0x0
    800001a2:	e86080e7          	jalr	-378(ra) # 80000024 <setup_recovery_kernel>
      memmove(sys_info_ptr->expected_kernel_measurement, trusted_kernel_hash, 32);
    800001a6:	02000613          	li	a2,32
    800001aa:	00001597          	auipc	a1,0x1
    800001ae:	93658593          	addi	a1,a1,-1738 # 80000ae0 <trusted_kernel_hash>
    800001b2:	00009517          	auipc	a0,0x9
    800001b6:	ade53503          	ld	a0,-1314(a0) # 80008c90 <sys_info_ptr>
    800001ba:	02050513          	addi	a0,a0,32
    800001be:	00000097          	auipc	ra,0x0
    800001c2:	2b6080e7          	jalr	694(ra) # 80000474 <memmove>
      verification = false;
    800001c6:	4501                	li	a0,0
  }
    
  return verification;
}
    800001c8:	60e2                	ld	ra,24(sp)
    800001ca:	6442                	ld	s0,16(sp)
    800001cc:	64a2                	ld	s1,8(sp)
    800001ce:	6902                	ld	s2,0(sp)
    800001d0:	6105                	addi	sp,sp,32
    800001d2:	8082                	ret

00000000800001d4 <start>:

// entry.S jumps here in machine mode on stack0.
void start()
{
    800001d4:	b8010113          	addi	sp,sp,-1152
    800001d8:	46113c23          	sd	ra,1144(sp)
    800001dc:	46813823          	sd	s0,1136(sp)
    800001e0:	46913423          	sd	s1,1128(sp)
    800001e4:	47213023          	sd	s2,1120(sp)
    800001e8:	45313c23          	sd	s3,1112(sp)
    800001ec:	45413823          	sd	s4,1104(sp)
    800001f0:	45513423          	sd	s5,1096(sp)
    800001f4:	45613023          	sd	s6,1088(sp)
    800001f8:	43713c23          	sd	s7,1080(sp)
    800001fc:	48010413          	addi	s0,sp,1152
  /* CSE 536: Define the system information table's location. */
  sys_info_ptr = (struct sys_info*) 0x80080000;
    80000200:	010017b7          	lui	a5,0x1001
    80000204:	079e                	slli	a5,a5,0x7
    80000206:	00009717          	auipc	a4,0x9
    8000020a:	a8f73523          	sd	a5,-1398(a4) # 80008c90 <sys_info_ptr>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    8000020e:	f14027f3          	csrr	a5,mhartid

  // keep each CPU's hartid in its tp register, for cpuid().
  int id = r_mhartid();
  w_tp(id);
    80000212:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    80000214:	823e                	mv	tp,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000216:	300027f3          	csrr	a5,mstatus

  // set M Previous Privilege mode to Supervisor, for mret.
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
    8000021a:	7779                	lui	a4,0xffffe
    8000021c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <kernel_elfhdr+0xffffffff7fff5b5f>
    80000220:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000222:	6705                	lui	a4,0x1
    80000224:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    80000228:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000022a:	30079073          	csrw	mstatus,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000022e:	4781                	li	a5,0
    80000230:	18079073          	csrw	satp,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    80000234:	57fd                	li	a5,-1
    80000236:	83a9                	srli	a5,a5,0xa
    80000238:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    8000023c:	47bd                	li	a5,15
    8000023e:	3a079073          	csrw	pmpcfg0,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    80000242:	21d807b7          	lui	a5,0x21d80
    80000246:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpaddr1, %0" : : "r" (x));
    8000024a:	10f807b7          	lui	a5,0x10f80
    8000024e:	17fd                	addi	a5,a5,-1 # 10f7ffff <_entry-0x6f080001>
    80000250:	3b179073          	csrw	pmpaddr1,a5
  asm volatile("csrw pmpaddr2, %0" : : "r" (x));
    80000254:	43f807b7          	lui	a5,0x43f80
    80000258:	17fd                	addi	a5,a5,-1 # 43f7ffff <_entry-0x3c080001>
    8000025a:	3b279073          	csrw	pmpaddr2,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    8000025e:	001f27b7          	lui	a5,0x1f2
    80000262:	f0f78793          	addi	a5,a5,-241 # 1f1f0f <_entry-0x7fe0e0f1>
    80000266:	3a079073          	csrw	pmpcfg0,a5
    w_pmpaddr2(0x43f7ffffull);
    w_pmpcfg0(0x1f1f0f);
  #endif

  /* CSE 536: Verify if the kernel is untampered for secure boot */
  if (!is_secure_boot()) {
    8000026a:	00000097          	auipc	ra,0x0
    8000026e:	eca080e7          	jalr	-310(ra) # 80000134 <is_secure_boot>
    80000272:	e93d                	bnez	a0,800002e8 <start+0x114>
  
  w_mepc((uint64) kernel_entry);
 
 out:
  /* CSE 536: Provide system information to the kernel. */
  sys_info_ptr->bl_start = 0x80000000;
    80000274:	00009717          	auipc	a4,0x9
    80000278:	a1c70713          	addi	a4,a4,-1508 # 80008c90 <sys_info_ptr>
    8000027c:	6314                	ld	a3,0(a4)
    8000027e:	4785                	li	a5,1
    80000280:	07fe                	slli	a5,a5,0x1f
    80000282:	e29c                	sd	a5,0(a3)
  sys_info_ptr->bl_end = end;
    80000284:	6318                	ld	a4,0(a4)
    80000286:	00009697          	auipc	a3,0x9
    8000028a:	a0a6b683          	ld	a3,-1526(a3) # 80008c90 <sys_info_ptr>
    8000028e:	e714                	sd	a3,8(a4)
  sys_info_ptr->dr_start = KERNBASE;
    80000290:	eb1c                	sd	a5,16(a4)
  sys_info_ptr->dr_end = PHYSTOP;
    80000292:	47c5                	li	a5,17
    80000294:	07ee                	slli	a5,a5,0x1b
    80000296:	ef1c                	sd	a5,24(a4)
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000298:	67c1                	lui	a5,0x10
    8000029a:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    8000029c:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800002a0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800002a4:	104027f3          	csrr	a5,sie
  // Done inside is_secure_boot()
  
  // delegate all interrupts and exceptions to supervisor mode.
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800002a8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800002ac:	10479073          	csrw	sie,a5

  // return address fix
  uint64 addr = (uint64) panic;
  asm volatile("mv ra, %0" : : "r" (addr));
    800002b0:	00000797          	auipc	a5,0x0
    800002b4:	d6c78793          	addi	a5,a5,-660 # 8000001c <panic>
    800002b8:	80be                	mv	ra,a5

  // switch to supervisor mode and jump to main().
  asm volatile("mret");
    800002ba:	30200073          	mret
}
    800002be:	47813083          	ld	ra,1144(sp)
    800002c2:	47013403          	ld	s0,1136(sp)
    800002c6:	46813483          	ld	s1,1128(sp)
    800002ca:	46013903          	ld	s2,1120(sp)
    800002ce:	45813983          	ld	s3,1112(sp)
    800002d2:	45013a03          	ld	s4,1104(sp)
    800002d6:	44813a83          	ld	s5,1096(sp)
    800002da:	44013b03          	ld	s6,1088(sp)
    800002de:	43813b83          	ld	s7,1080(sp)
    800002e2:	48010113          	addi	sp,sp,1152
    800002e6:	8082                	ret
  uint64 kernel_load_addr       = find_kernel_load_addr(NORMAL);
    800002e8:	4501                	li	a0,0
    800002ea:	00000097          	auipc	ra,0x0
    800002ee:	2d2080e7          	jalr	722(ra) # 800005bc <find_kernel_load_addr>
    800002f2:	8baa                	mv	s7,a0
  uint64 kernel_binary_size     = find_kernel_size(NORMAL);   
    800002f4:	4501                	li	a0,0
    800002f6:	00000097          	auipc	ra,0x0
    800002fa:	306080e7          	jalr	774(ra) # 800005fc <find_kernel_size>
    800002fe:	8aaa                	mv	s5,a0
  uint64 kernel_entry           = find_kernel_entry_addr(NORMAL);  
    80000300:	4501                	li	a0,0
    80000302:	00000097          	auipc	ra,0x0
    80000306:	338080e7          	jalr	824(ra) # 8000063a <find_kernel_entry_addr>
    8000030a:	8b2a                	mv	s6,a0
  char *kernel_load_address = (char *) kernel_load_addr;
    8000030c:	84de                	mv	s1,s7
  uint64 no_of_blocks = kernel_binary_size / BSIZE;
    8000030e:	00aada13          	srli	s4,s5,0xa
  for (uint64 i = 4; i < no_of_blocks; ++i) {
    80000312:	6785                	lui	a5,0x1
    80000314:	3ff78793          	addi	a5,a5,1023 # 13ff <_entry-0x7fffec01>
    80000318:	0557f863          	bgeu	a5,s5,80000368 <start+0x194>
  char *kernel_load_address = (char *) kernel_load_addr;
    8000031c:	89de                	mv	s3,s7
  for (uint64 i = 4; i < no_of_blocks; ++i) {
    8000031e:	4911                	li	s2,4
    80000320:	fb040493          	addi	s1,s0,-80
    b.blockno = i;
    80000324:	b9242a23          	sw	s2,-1132(s0)
    kernel_copy(NORMAL, &b);    
    80000328:	b8840593          	addi	a1,s0,-1144
    8000032c:	4501                	li	a0,0
    8000032e:	00000097          	auipc	ra,0x0
    80000332:	076080e7          	jalr	118(ra) # 800003a4 <kernel_copy>
    for (uint64 j = 0; j < BSIZE; ++j) {
    80000336:	bb040793          	addi	a5,s0,-1104
    kernel_copy(NORMAL, &b);    
    8000033a:	874e                	mv	a4,s3
      *(kernel_load_address) = b.data[j];
    8000033c:	0007c683          	lbu	a3,0(a5)
    80000340:	00d70023          	sb	a3,0(a4)
      ++kernel_load_address;
    80000344:	0705                	addi	a4,a4,1
    for (uint64 j = 0; j < BSIZE; ++j) {
    80000346:	0785                	addi	a5,a5,1
    80000348:	fef49ae3          	bne	s1,a5,8000033c <start+0x168>
      ++kernel_load_address;
    8000034c:	40098993          	addi	s3,s3,1024
  for (uint64 i = 4; i < no_of_blocks; ++i) {
    80000350:	0905                	addi	s2,s2,1
    80000352:	fd4969e3          	bltu	s2,s4,80000324 <start+0x150>
      ++kernel_load_address;
    80000356:	87d2                	mv	a5,s4
    80000358:	4715                	li	a4,5
    8000035a:	00ea7363          	bgeu	s4,a4,80000360 <start+0x18c>
    8000035e:	4795                	li	a5,5
    80000360:	ffc78493          	addi	s1,a5,-4
    80000364:	04aa                	slli	s1,s1,0xa
    80000366:	94de                	add	s1,s1,s7
  if (kernel_binary_size%BSIZE != 0) {
    80000368:	3ffafa93          	andi	s5,s5,1023
    8000036c:	000a9563          	bnez	s5,80000376 <start+0x1a2>
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000370:	341b1073          	csrw	mepc,s6
}
    80000374:	b701                	j	80000274 <start+0xa0>
    b.blockno = no_of_blocks + 1;
    80000376:	2a05                	addiw	s4,s4,1
    80000378:	b9442a23          	sw	s4,-1132(s0)
    kernel_copy(NORMAL, &b);    
    8000037c:	b8840593          	addi	a1,s0,-1144
    80000380:	4501                	li	a0,0
    80000382:	00000097          	auipc	ra,0x0
    80000386:	022080e7          	jalr	34(ra) # 800003a4 <kernel_copy>
    for (uint64 j = 0; j < kernel_binary_size%BSIZE; ++j) {
    8000038a:	bb040713          	addi	a4,s0,-1104
    8000038e:	015487b3          	add	a5,s1,s5
      *(kernel_load_address) = b.data[j];
    80000392:	00074683          	lbu	a3,0(a4)
    80000396:	00d48023          	sb	a3,0(s1)
      ++kernel_load_address;
    8000039a:	0485                	addi	s1,s1,1
    for (uint64 j = 0; j < kernel_binary_size%BSIZE; ++j) {
    8000039c:	0705                	addi	a4,a4,1
    8000039e:	fe979ae3          	bne	a5,s1,80000392 <start+0x1be>
    800003a2:	b7f9                	j	80000370 <start+0x19c>

00000000800003a4 <kernel_copy>:
#include "layout.h"
#include "buf.h"

/* In-built function to load NORMAL/RECOVERY kernels */
void kernel_copy(enum kernel ktype, struct buf *b)
{
    800003a4:	1101                	addi	sp,sp,-32
    800003a6:	ec06                	sd	ra,24(sp)
    800003a8:	e822                	sd	s0,16(sp)
    800003aa:	e426                	sd	s1,8(sp)
    800003ac:	e04a                	sd	s2,0(sp)
    800003ae:	1000                	addi	s0,sp,32
    800003b0:	892a                	mv	s2,a0
    800003b2:	84ae                	mv	s1,a1
  if(b->blockno >= FSSIZE)
    800003b4:	45d8                	lw	a4,12(a1)
    800003b6:	7cf00793          	li	a5,1999
    800003ba:	02e7ed63          	bltu	a5,a4,800003f4 <kernel_copy+0x50>
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
    800003be:	44dc                	lw	a5,12(s1)
    800003c0:	00a7979b          	slliw	a5,a5,0xa
    800003c4:	1782                	slli	a5,a5,0x20
    800003c6:	9381                	srli	a5,a5,0x20
  char* addr = 0x0; 
  
  if (ktype == NORMAL)
    800003c8:	02091f63          	bnez	s2,80000406 <kernel_copy+0x62>
    addr = (char *)RAMDISK + diskaddr;
    800003cc:	02100593          	li	a1,33
    800003d0:	05ea                	slli	a1,a1,0x1a
    800003d2:	95be                	add	a1,a1,a5
  else if (ktype == RECOVERY)
    addr = (char *)RECOVERYDISK + diskaddr;

  memmove(b->data, addr, BSIZE);
    800003d4:	40000613          	li	a2,1024
    800003d8:	02848513          	addi	a0,s1,40
    800003dc:	00000097          	auipc	ra,0x0
    800003e0:	098080e7          	jalr	152(ra) # 80000474 <memmove>
  b->valid = 1;
    800003e4:	4785                	li	a5,1
    800003e6:	c09c                	sw	a5,0(s1)
    800003e8:	60e2                	ld	ra,24(sp)
    800003ea:	6442                	ld	s0,16(sp)
    800003ec:	64a2                	ld	s1,8(sp)
    800003ee:	6902                	ld	s2,0(sp)
    800003f0:	6105                	addi	sp,sp,32
    800003f2:	8082                	ret
    panic("ramdiskrw: blockno too big");
    800003f4:	00001517          	auipc	a0,0x1
    800003f8:	80c50513          	addi	a0,a0,-2036 # 80000c00 <k+0x100>
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	c20080e7          	jalr	-992(ra) # 8000001c <panic>
    80000404:	bf6d                	j	800003be <kernel_copy+0x1a>
  else if (ktype == RECOVERY)
    80000406:	4705                	li	a4,1
  char* addr = 0x0; 
    80000408:	4581                	li	a1,0
  else if (ktype == RECOVERY)
    8000040a:	fce915e3          	bne	s2,a4,800003d4 <kernel_copy+0x30>
    addr = (char *)RECOVERYDISK + diskaddr;
    8000040e:	008455b7          	lui	a1,0x845
    80000412:	05a2                	slli	a1,a1,0x8
    80000414:	95be                	add	a1,a1,a5
    80000416:	bf7d                	j	800003d4 <kernel_copy+0x30>

0000000080000418 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000418:	1141                	addi	sp,sp,-16
    8000041a:	e422                	sd	s0,8(sp)
    8000041c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    8000041e:	ca19                	beqz	a2,80000434 <memset+0x1c>
    80000420:	87aa                	mv	a5,a0
    80000422:	1602                	slli	a2,a2,0x20
    80000424:	9201                	srli	a2,a2,0x20
    80000426:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    8000042a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    8000042e:	0785                	addi	a5,a5,1
    80000430:	fee79de3          	bne	a5,a4,8000042a <memset+0x12>
  }
  return dst;
}
    80000434:	6422                	ld	s0,8(sp)
    80000436:	0141                	addi	sp,sp,16
    80000438:	8082                	ret

000000008000043a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    8000043a:	1141                	addi	sp,sp,-16
    8000043c:	e422                	sd	s0,8(sp)
    8000043e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000440:	ca05                	beqz	a2,80000470 <memcmp+0x36>
    80000442:	fff6069b          	addiw	a3,a2,-1
    80000446:	1682                	slli	a3,a3,0x20
    80000448:	9281                	srli	a3,a3,0x20
    8000044a:	0685                	addi	a3,a3,1
    8000044c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    8000044e:	00054783          	lbu	a5,0(a0)
    80000452:	0005c703          	lbu	a4,0(a1) # 845000 <_entry-0x7f7bb000>
    80000456:	00e79863          	bne	a5,a4,80000466 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    8000045a:	0505                	addi	a0,a0,1
    8000045c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    8000045e:	fed518e3          	bne	a0,a3,8000044e <memcmp+0x14>
  }

  return 0;
    80000462:	4501                	li	a0,0
    80000464:	a019                	j	8000046a <memcmp+0x30>
      return *s1 - *s2;
    80000466:	40e7853b          	subw	a0,a5,a4
}
    8000046a:	6422                	ld	s0,8(sp)
    8000046c:	0141                	addi	sp,sp,16
    8000046e:	8082                	ret
  return 0;
    80000470:	4501                	li	a0,0
    80000472:	bfe5                	j	8000046a <memcmp+0x30>

0000000080000474 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000474:	1141                	addi	sp,sp,-16
    80000476:	e422                	sd	s0,8(sp)
    80000478:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    8000047a:	c205                	beqz	a2,8000049a <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    8000047c:	02a5e263          	bltu	a1,a0,800004a0 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000480:	1602                	slli	a2,a2,0x20
    80000482:	9201                	srli	a2,a2,0x20
    80000484:	00c587b3          	add	a5,a1,a2
{
    80000488:	872a                	mv	a4,a0
      *d++ = *s++;
    8000048a:	0585                	addi	a1,a1,1
    8000048c:	0705                	addi	a4,a4,1
    8000048e:	fff5c683          	lbu	a3,-1(a1)
    80000492:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000496:	fef59ae3          	bne	a1,a5,8000048a <memmove+0x16>

  return dst;
}
    8000049a:	6422                	ld	s0,8(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret
  if(s < d && s + n > d){
    800004a0:	02061693          	slli	a3,a2,0x20
    800004a4:	9281                	srli	a3,a3,0x20
    800004a6:	00d58733          	add	a4,a1,a3
    800004aa:	fce57be3          	bgeu	a0,a4,80000480 <memmove+0xc>
    d += n;
    800004ae:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    800004b0:	fff6079b          	addiw	a5,a2,-1
    800004b4:	1782                	slli	a5,a5,0x20
    800004b6:	9381                	srli	a5,a5,0x20
    800004b8:	fff7c793          	not	a5,a5
    800004bc:	97ba                	add	a5,a5,a4
      *--d = *--s;
    800004be:	177d                	addi	a4,a4,-1
    800004c0:	16fd                	addi	a3,a3,-1
    800004c2:	00074603          	lbu	a2,0(a4)
    800004c6:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    800004ca:	fee79ae3          	bne	a5,a4,800004be <memmove+0x4a>
    800004ce:	b7f1                	j	8000049a <memmove+0x26>

00000000800004d0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    800004d0:	1141                	addi	sp,sp,-16
    800004d2:	e406                	sd	ra,8(sp)
    800004d4:	e022                	sd	s0,0(sp)
    800004d6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    800004d8:	00000097          	auipc	ra,0x0
    800004dc:	f9c080e7          	jalr	-100(ra) # 80000474 <memmove>
}
    800004e0:	60a2                	ld	ra,8(sp)
    800004e2:	6402                	ld	s0,0(sp)
    800004e4:	0141                	addi	sp,sp,16
    800004e6:	8082                	ret

00000000800004e8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    800004e8:	1141                	addi	sp,sp,-16
    800004ea:	e422                	sd	s0,8(sp)
    800004ec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    800004ee:	ce11                	beqz	a2,8000050a <strncmp+0x22>
    800004f0:	00054783          	lbu	a5,0(a0)
    800004f4:	cf89                	beqz	a5,8000050e <strncmp+0x26>
    800004f6:	0005c703          	lbu	a4,0(a1)
    800004fa:	00f71a63          	bne	a4,a5,8000050e <strncmp+0x26>
    n--, p++, q++;
    800004fe:	367d                	addiw	a2,a2,-1
    80000500:	0505                	addi	a0,a0,1
    80000502:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000504:	f675                	bnez	a2,800004f0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000506:	4501                	li	a0,0
    80000508:	a809                	j	8000051a <strncmp+0x32>
    8000050a:	4501                	li	a0,0
    8000050c:	a039                	j	8000051a <strncmp+0x32>
  if(n == 0)
    8000050e:	ca09                	beqz	a2,80000520 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000510:	00054503          	lbu	a0,0(a0)
    80000514:	0005c783          	lbu	a5,0(a1)
    80000518:	9d1d                	subw	a0,a0,a5
}
    8000051a:	6422                	ld	s0,8(sp)
    8000051c:	0141                	addi	sp,sp,16
    8000051e:	8082                	ret
    return 0;
    80000520:	4501                	li	a0,0
    80000522:	bfe5                	j	8000051a <strncmp+0x32>

0000000080000524 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000524:	1141                	addi	sp,sp,-16
    80000526:	e422                	sd	s0,8(sp)
    80000528:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    8000052a:	87aa                	mv	a5,a0
    8000052c:	86b2                	mv	a3,a2
    8000052e:	367d                	addiw	a2,a2,-1
    80000530:	00d05963          	blez	a3,80000542 <strncpy+0x1e>
    80000534:	0785                	addi	a5,a5,1
    80000536:	0005c703          	lbu	a4,0(a1)
    8000053a:	fee78fa3          	sb	a4,-1(a5)
    8000053e:	0585                	addi	a1,a1,1
    80000540:	f775                	bnez	a4,8000052c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000542:	873e                	mv	a4,a5
    80000544:	9fb5                	addw	a5,a5,a3
    80000546:	37fd                	addiw	a5,a5,-1
    80000548:	00c05963          	blez	a2,8000055a <strncpy+0x36>
    *s++ = 0;
    8000054c:	0705                	addi	a4,a4,1
    8000054e:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000552:	40e786bb          	subw	a3,a5,a4
    80000556:	fed04be3          	bgtz	a3,8000054c <strncpy+0x28>
  return os;
}
    8000055a:	6422                	ld	s0,8(sp)
    8000055c:	0141                	addi	sp,sp,16
    8000055e:	8082                	ret

0000000080000560 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000560:	1141                	addi	sp,sp,-16
    80000562:	e422                	sd	s0,8(sp)
    80000564:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000566:	02c05363          	blez	a2,8000058c <safestrcpy+0x2c>
    8000056a:	fff6069b          	addiw	a3,a2,-1
    8000056e:	1682                	slli	a3,a3,0x20
    80000570:	9281                	srli	a3,a3,0x20
    80000572:	96ae                	add	a3,a3,a1
    80000574:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000576:	00d58963          	beq	a1,a3,80000588 <safestrcpy+0x28>
    8000057a:	0585                	addi	a1,a1,1
    8000057c:	0785                	addi	a5,a5,1
    8000057e:	fff5c703          	lbu	a4,-1(a1)
    80000582:	fee78fa3          	sb	a4,-1(a5)
    80000586:	fb65                	bnez	a4,80000576 <safestrcpy+0x16>
    ;
  *s = 0;
    80000588:	00078023          	sb	zero,0(a5)
  return os;
}
    8000058c:	6422                	ld	s0,8(sp)
    8000058e:	0141                	addi	sp,sp,16
    80000590:	8082                	ret

0000000080000592 <strlen>:

int
strlen(const char *s)
{
    80000592:	1141                	addi	sp,sp,-16
    80000594:	e422                	sd	s0,8(sp)
    80000596:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000598:	00054783          	lbu	a5,0(a0)
    8000059c:	cf91                	beqz	a5,800005b8 <strlen+0x26>
    8000059e:	0505                	addi	a0,a0,1
    800005a0:	87aa                	mv	a5,a0
    800005a2:	86be                	mv	a3,a5
    800005a4:	0785                	addi	a5,a5,1
    800005a6:	fff7c703          	lbu	a4,-1(a5)
    800005aa:	ff65                	bnez	a4,800005a2 <strlen+0x10>
    800005ac:	40a6853b          	subw	a0,a3,a0
    800005b0:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    800005b2:	6422                	ld	s0,8(sp)
    800005b4:	0141                	addi	sp,sp,16
    800005b6:	8082                	ret
  for(n = 0; s[n]; n++)
    800005b8:	4501                	li	a0,0
    800005ba:	bfe5                	j	800005b2 <strlen+0x20>

00000000800005bc <find_kernel_load_addr>:
#include <stdbool.h>

struct elfhdr* kernel_elfhdr;
struct proghdr* kernel_phdr;

uint64 find_kernel_load_addr(enum kernel ktype) {
    800005bc:	1141                	addi	sp,sp,-16
    800005be:	e422                	sd	s0,8(sp)
    800005c0:	0800                	addi	s0,sp,16
    /* CSE 536: Get kernel load address from headers */
    uint64 addr = 0x0;
  
    if (ktype == NORMAL)
    800005c2:	c909                	beqz	a0,800005d4 <find_kernel_load_addr+0x18>
      addr = RAMDISK;
    else if (ktype == RECOVERY)
    800005c4:	4785                	li	a5,1
    uint64 addr = 0x0;
    800005c6:	4701                	li	a4,0
    else if (ktype == RECOVERY)
    800005c8:	00f51963          	bne	a0,a5,800005da <find_kernel_load_addr+0x1e>
      addr = RECOVERYDISK;
    800005cc:	00845737          	lui	a4,0x845
    800005d0:	0722                	slli	a4,a4,0x8
    800005d2:	a021                	j	800005da <find_kernel_load_addr+0x1e>
      addr = RAMDISK;
    800005d4:	02100713          	li	a4,33
    800005d8:	076a                	slli	a4,a4,0x1a
    
    kernel_elfhdr = (struct elfhdr *) addr;
    800005da:	00008797          	auipc	a5,0x8
    800005de:	6ce7b323          	sd	a4,1734(a5) # 80008ca0 <kernel_elfhdr>
    kernel_phdr = (struct proghdr *) (addr + kernel_elfhdr->phoff + kernel_elfhdr->phentsize);
    800005e2:	731c                	ld	a5,32(a4)
    800005e4:	97ba                	add	a5,a5,a4
    800005e6:	03675703          	lhu	a4,54(a4) # 845036 <_entry-0x7f7bafca>
    800005ea:	97ba                	add	a5,a5,a4
    800005ec:	00008717          	auipc	a4,0x8
    800005f0:	6af73623          	sd	a5,1708(a4) # 80008c98 <kernel_phdr>
    return kernel_phdr->vaddr;
}
    800005f4:	6b88                	ld	a0,16(a5)
    800005f6:	6422                	ld	s0,8(sp)
    800005f8:	0141                	addi	sp,sp,16
    800005fa:	8082                	ret

00000000800005fc <find_kernel_size>:

uint64 find_kernel_size(enum kernel ktype) {
    800005fc:	1141                	addi	sp,sp,-16
    800005fe:	e422                	sd	s0,8(sp)
    80000600:	0800                	addi	s0,sp,16
    /* CSE 536: Get kernel binary size from headers */
    uint64 addr = 0x0;
  
    if (ktype == NORMAL)
    80000602:	c511                	beqz	a0,8000060e <find_kernel_size+0x12>
      addr = RAMDISK;
    else if (ktype == RECOVERY)
    80000604:	4785                	li	a5,1
    80000606:	02f50663          	beq	a0,a5,80000632 <find_kernel_size+0x36>
    uint64 addr = 0x0;
    8000060a:	4781                	li	a5,0
    8000060c:	a021                	j	80000614 <find_kernel_size+0x18>
      addr = RAMDISK;
    8000060e:	02100793          	li	a5,33
    80000612:	07ea                	slli	a5,a5,0x1a
      addr = RECOVERYDISK;
      
    kernel_elfhdr = (struct elfhdr *) addr;
    80000614:	00008717          	auipc	a4,0x8
    80000618:	68f73623          	sd	a5,1676(a4) # 80008ca0 <kernel_elfhdr>
    uint64 ksize = (uint64) (kernel_elfhdr->shoff + kernel_elfhdr->shentsize * kernel_elfhdr->shnum);
    8000061c:	03a7d703          	lhu	a4,58(a5)
    80000620:	03c7d683          	lhu	a3,60(a5)
    80000624:	02d7073b          	mulw	a4,a4,a3
    80000628:	7788                	ld	a0,40(a5)
    return ksize;
}
    8000062a:	953a                	add	a0,a0,a4
    8000062c:	6422                	ld	s0,8(sp)
    8000062e:	0141                	addi	sp,sp,16
    80000630:	8082                	ret
      addr = RECOVERYDISK;
    80000632:	008457b7          	lui	a5,0x845
    80000636:	07a2                	slli	a5,a5,0x8
    80000638:	bff1                	j	80000614 <find_kernel_size+0x18>

000000008000063a <find_kernel_entry_addr>:

uint64 find_kernel_entry_addr(enum kernel ktype) {
    8000063a:	1141                	addi	sp,sp,-16
    8000063c:	e422                	sd	s0,8(sp)
    8000063e:	0800                	addi	s0,sp,16
    /* CSE 536: Get kernel entry point from headers */
    uint64 addr = 0x0;
  
    if (ktype == NORMAL)
    80000640:	c511                	beqz	a0,8000064c <find_kernel_entry_addr+0x12>
      addr = RAMDISK;
    else if (ktype == RECOVERY)
    80000642:	4785                	li	a5,1
    80000644:	00f50f63          	beq	a0,a5,80000662 <find_kernel_entry_addr+0x28>
    uint64 addr = 0x0;
    80000648:	4781                	li	a5,0
    8000064a:	a021                	j	80000652 <find_kernel_entry_addr+0x18>
      addr = RAMDISK;
    8000064c:	02100793          	li	a5,33
    80000650:	07ea                	slli	a5,a5,0x1a
      addr = RECOVERYDISK;
      
    kernel_elfhdr = (struct elfhdr *) addr;
    80000652:	00008717          	auipc	a4,0x8
    80000656:	64f73723          	sd	a5,1614(a4) # 80008ca0 <kernel_elfhdr>
    return kernel_elfhdr->entry;
}
    8000065a:	6f88                	ld	a0,24(a5)
    8000065c:	6422                	ld	s0,8(sp)
    8000065e:	0141                	addi	sp,sp,16
    80000660:	8082                	ret
      addr = RECOVERYDISK;
    80000662:	008457b7          	lui	a5,0x845
    80000666:	07a2                	slli	a5,a5,0x8
    80000668:	b7ed                	j	80000652 <find_kernel_entry_addr+0x18>

000000008000066a <sha256_transform>:
	0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};

/*********************** FUNCTION DEFINITIONS ***********************/
void sha256_transform(SHA256_CTX *ctx, const BYTE data[])
{
    8000066a:	710d                	addi	sp,sp,-352
    8000066c:	eea2                	sd	s0,344(sp)
    8000066e:	eaa6                	sd	s1,336(sp)
    80000670:	e6ca                	sd	s2,328(sp)
    80000672:	e2ce                	sd	s3,320(sp)
    80000674:	fe52                	sd	s4,312(sp)
    80000676:	fa56                	sd	s5,304(sp)
    80000678:	f65a                	sd	s6,296(sp)
    8000067a:	f25e                	sd	s7,288(sp)
    8000067c:	ee62                	sd	s8,280(sp)
    8000067e:	ea66                	sd	s9,272(sp)
    80000680:	e66a                	sd	s10,264(sp)
    80000682:	e26e                	sd	s11,256(sp)
    80000684:	1280                	addi	s0,sp,352
	WORD a, b, c, d, e, f, g, h, i, j, t1, t2, m[64];

	for (i = 0, j = 0; i < 16; ++i, j += 4)
    80000686:	ea040e13          	addi	t3,s0,-352
    8000068a:	ee040613          	addi	a2,s0,-288
{
    8000068e:	8772                	mv	a4,t3
		m[i] = (data[j] << 24) | (data[j + 1] << 16) | (data[j + 2] << 8) | (data[j + 3]);
    80000690:	0005c783          	lbu	a5,0(a1)
    80000694:	0187979b          	slliw	a5,a5,0x18
    80000698:	0015c683          	lbu	a3,1(a1)
    8000069c:	0106969b          	slliw	a3,a3,0x10
    800006a0:	8fd5                	or	a5,a5,a3
    800006a2:	0035c683          	lbu	a3,3(a1)
    800006a6:	8fd5                	or	a5,a5,a3
    800006a8:	0025c683          	lbu	a3,2(a1)
    800006ac:	0086969b          	slliw	a3,a3,0x8
    800006b0:	8fd5                	or	a5,a5,a3
    800006b2:	c31c                	sw	a5,0(a4)
	for (i = 0, j = 0; i < 16; ++i, j += 4)
    800006b4:	0591                	addi	a1,a1,4
    800006b6:	0711                	addi	a4,a4,4
    800006b8:	fcc71ce3          	bne	a4,a2,80000690 <sha256_transform+0x26>
	for ( ; i < 64; ++i)
    800006bc:	0c0e0893          	addi	a7,t3,192
	for (i = 0, j = 0; i < 16; ++i, j += 4)
    800006c0:	87f2                	mv	a5,t3
		m[i] = SIG1(m[i - 2]) + m[i - 7] + SIG0(m[i - 15]) + m[i - 16];
    800006c2:	5f98                	lw	a4,56(a5)
    800006c4:	43d0                	lw	a2,4(a5)
    800006c6:	00f7169b          	slliw	a3,a4,0xf
    800006ca:	0117559b          	srliw	a1,a4,0x11
    800006ce:	8ecd                	or	a3,a3,a1
    800006d0:	00d7159b          	slliw	a1,a4,0xd
    800006d4:	0137581b          	srliw	a6,a4,0x13
    800006d8:	0105e5b3          	or	a1,a1,a6
    800006dc:	8ead                	xor	a3,a3,a1
    800006de:	00a7571b          	srliw	a4,a4,0xa
    800006e2:	8eb9                	xor	a3,a3,a4
    800006e4:	53cc                	lw	a1,36(a5)
    800006e6:	4398                	lw	a4,0(a5)
    800006e8:	9f2d                	addw	a4,a4,a1
    800006ea:	9f35                	addw	a4,a4,a3
    800006ec:	0076569b          	srliw	a3,a2,0x7
    800006f0:	0196159b          	slliw	a1,a2,0x19
    800006f4:	8ecd                	or	a3,a3,a1
    800006f6:	00e6159b          	slliw	a1,a2,0xe
    800006fa:	0126581b          	srliw	a6,a2,0x12
    800006fe:	0105e5b3          	or	a1,a1,a6
    80000702:	8ead                	xor	a3,a3,a1
    80000704:	0036561b          	srliw	a2,a2,0x3
    80000708:	8eb1                	xor	a3,a3,a2
    8000070a:	9f35                	addw	a4,a4,a3
    8000070c:	c3b8                	sw	a4,64(a5)
	for ( ; i < 64; ++i)
    8000070e:	0791                	addi	a5,a5,4 # 845004 <_entry-0x7f7baffc>
    80000710:	fb1799e3          	bne	a5,a7,800006c2 <sha256_transform+0x58>

	a = ctx->state[0];
    80000714:	05052b03          	lw	s6,80(a0)
	b = ctx->state[1];
    80000718:	05452a83          	lw	s5,84(a0)
	c = ctx->state[2];
    8000071c:	05852a03          	lw	s4,88(a0)
	d = ctx->state[3];
    80000720:	05c52983          	lw	s3,92(a0)
	e = ctx->state[4];
    80000724:	06052903          	lw	s2,96(a0)
	f = ctx->state[5];
    80000728:	5164                	lw	s1,100(a0)
	g = ctx->state[6];
    8000072a:	06852383          	lw	t2,104(a0)
	h = ctx->state[7];
    8000072e:	06c52283          	lw	t0,108(a0)

	for (i = 0; i < 64; ++i) {
    80000732:	00000317          	auipc	t1,0x0
    80000736:	3ce30313          	addi	t1,t1,974 # 80000b00 <k>
    8000073a:	00000f97          	auipc	t6,0x0
    8000073e:	4c6f8f93          	addi	t6,t6,1222 # 80000c00 <k+0x100>
	h = ctx->state[7];
    80000742:	8b96                	mv	s7,t0
	g = ctx->state[6];
    80000744:	8e9e                	mv	t4,t2
	f = ctx->state[5];
    80000746:	8826                	mv	a6,s1
	e = ctx->state[4];
    80000748:	86ca                	mv	a3,s2
	d = ctx->state[3];
    8000074a:	8f4e                	mv	t5,s3
	c = ctx->state[2];
    8000074c:	88d2                	mv	a7,s4
	b = ctx->state[1];
    8000074e:	85d6                	mv	a1,s5
	a = ctx->state[0];
    80000750:	865a                	mv	a2,s6
    80000752:	a039                	j	80000760 <sha256_transform+0xf6>
    80000754:	8ec2                	mv	t4,a6
    80000756:	883a                	mv	a6,a4
		t1 = h + EP1(e) + CH(e,f,g) + k[i] + m[i];
		t2 = EP0(a) + MAJ(a,b,c);
		h = g;
		g = f;
		f = e;
		e = d + t1;
    80000758:	86e6                	mv	a3,s9
    8000075a:	88ae                	mv	a7,a1
    8000075c:	85ea                	mv	a1,s10
		d = c;
		c = b;
		b = a;
		a = t1 + t2;
    8000075e:	866e                	mv	a2,s11
		t1 = h + EP1(e) + CH(e,f,g) + k[i] + m[i];
    80000760:	0066d71b          	srliw	a4,a3,0x6
    80000764:	01a6979b          	slliw	a5,a3,0x1a
    80000768:	8f5d                	or	a4,a4,a5
    8000076a:	00b6d79b          	srliw	a5,a3,0xb
    8000076e:	01569c1b          	slliw	s8,a3,0x15
    80000772:	0187e7b3          	or	a5,a5,s8
    80000776:	8f3d                	xor	a4,a4,a5
    80000778:	0076979b          	slliw	a5,a3,0x7
    8000077c:	0196dc1b          	srliw	s8,a3,0x19
    80000780:	0187e7b3          	or	a5,a5,s8
    80000784:	8f3d                	xor	a4,a4,a5
    80000786:	00032c03          	lw	s8,0(t1)
    8000078a:	000e2783          	lw	a5,0(t3)
    8000078e:	018787bb          	addw	a5,a5,s8
    80000792:	9fb9                	addw	a5,a5,a4
    80000794:	fff6c713          	not	a4,a3
    80000798:	01d77733          	and	a4,a4,t4
    8000079c:	0106fc33          	and	s8,a3,a6
    800007a0:	01874733          	xor	a4,a4,s8
    800007a4:	9fb9                	addw	a5,a5,a4
    800007a6:	017787bb          	addw	a5,a5,s7
		t2 = EP0(a) + MAJ(a,b,c);
    800007aa:	0026571b          	srliw	a4,a2,0x2
    800007ae:	01e61b9b          	slliw	s7,a2,0x1e
    800007b2:	01776733          	or	a4,a4,s7
    800007b6:	00d65b9b          	srliw	s7,a2,0xd
    800007ba:	01361c1b          	slliw	s8,a2,0x13
    800007be:	018bebb3          	or	s7,s7,s8
    800007c2:	01774733          	xor	a4,a4,s7
    800007c6:	00a61b9b          	slliw	s7,a2,0xa
    800007ca:	01665c1b          	srliw	s8,a2,0x16
    800007ce:	018bebb3          	or	s7,s7,s8
    800007d2:	01774733          	xor	a4,a4,s7
    800007d6:	0115cbb3          	xor	s7,a1,a7
    800007da:	01767bb3          	and	s7,a2,s7
    800007de:	0115fc33          	and	s8,a1,a7
    800007e2:	018bcbb3          	xor	s7,s7,s8
    800007e6:	0177073b          	addw	a4,a4,s7
		e = d + t1;
    800007ea:	2681                	sext.w	a3,a3
    800007ec:	01e78c3b          	addw	s8,a5,t5
    800007f0:	000c0c9b          	sext.w	s9,s8
		a = t1 + t2;
    800007f4:	2601                	sext.w	a2,a2
    800007f6:	9fb9                	addw	a5,a5,a4
    800007f8:	00078d9b          	sext.w	s11,a5
	for (i = 0; i < 64; ++i) {
    800007fc:	0311                	addi	t1,t1,4
    800007fe:	0e11                	addi	t3,t3,4
    80000800:	00060d1b          	sext.w	s10,a2
    80000804:	2581                	sext.w	a1,a1
    80000806:	00088f1b          	sext.w	t5,a7
    8000080a:	0006871b          	sext.w	a4,a3
    8000080e:	2801                	sext.w	a6,a6
    80000810:	000e8b9b          	sext.w	s7,t4
    80000814:	f5f310e3          	bne	t1,t6,80000754 <sha256_transform+0xea>
	}

	ctx->state[0] += a;
    80000818:	00fb0b3b          	addw	s6,s6,a5
    8000081c:	05652823          	sw	s6,80(a0)
	ctx->state[1] += b;
    80000820:	00ca8abb          	addw	s5,s5,a2
    80000824:	05552a23          	sw	s5,84(a0)
	ctx->state[2] += c;
    80000828:	00ba0a3b          	addw	s4,s4,a1
    8000082c:	05452c23          	sw	s4,88(a0)
	ctx->state[3] += d;
    80000830:	011989bb          	addw	s3,s3,a7
    80000834:	05352e23          	sw	s3,92(a0)
	ctx->state[4] += e;
    80000838:	0189093b          	addw	s2,s2,s8
    8000083c:	07252023          	sw	s2,96(a0)
	ctx->state[5] += f;
    80000840:	9cb5                	addw	s1,s1,a3
    80000842:	d164                	sw	s1,100(a0)
	ctx->state[6] += g;
    80000844:	010383bb          	addw	t2,t2,a6
    80000848:	06752423          	sw	t2,104(a0)
	ctx->state[7] += h;
    8000084c:	01d282bb          	addw	t0,t0,t4
    80000850:	06552623          	sw	t0,108(a0)
}
    80000854:	6476                	ld	s0,344(sp)
    80000856:	64d6                	ld	s1,336(sp)
    80000858:	6936                	ld	s2,328(sp)
    8000085a:	6996                	ld	s3,320(sp)
    8000085c:	7a72                	ld	s4,312(sp)
    8000085e:	7ad2                	ld	s5,304(sp)
    80000860:	7b32                	ld	s6,296(sp)
    80000862:	7b92                	ld	s7,288(sp)
    80000864:	6c72                	ld	s8,280(sp)
    80000866:	6cd2                	ld	s9,272(sp)
    80000868:	6d32                	ld	s10,264(sp)
    8000086a:	6d92                	ld	s11,256(sp)
    8000086c:	6135                	addi	sp,sp,352
    8000086e:	8082                	ret

0000000080000870 <sha256_init>:

void sha256_init(SHA256_CTX *ctx)
{
    80000870:	1141                	addi	sp,sp,-16
    80000872:	e422                	sd	s0,8(sp)
    80000874:	0800                	addi	s0,sp,16
	ctx->datalen = 0;
    80000876:	04052023          	sw	zero,64(a0)
	ctx->bitlen = 0;
    8000087a:	04053423          	sd	zero,72(a0)
	ctx->state[0] = 0x6a09e667;
    8000087e:	6a09e7b7          	lui	a5,0x6a09e
    80000882:	66778793          	addi	a5,a5,1639 # 6a09e667 <_entry-0x15f61999>
    80000886:	c93c                	sw	a5,80(a0)
	ctx->state[1] = 0xbb67ae85;
    80000888:	bb67b7b7          	lui	a5,0xbb67b
    8000088c:	e8578793          	addi	a5,a5,-379 # ffffffffbb67ae85 <kernel_elfhdr+0xffffffff3b6721e5>
    80000890:	c97c                	sw	a5,84(a0)
	ctx->state[2] = 0x3c6ef372;
    80000892:	3c6ef7b7          	lui	a5,0x3c6ef
    80000896:	37278793          	addi	a5,a5,882 # 3c6ef372 <_entry-0x43910c8e>
    8000089a:	cd3c                	sw	a5,88(a0)
	ctx->state[3] = 0xa54ff53a;
    8000089c:	a54ff7b7          	lui	a5,0xa54ff
    800008a0:	53a78793          	addi	a5,a5,1338 # ffffffffa54ff53a <kernel_elfhdr+0xffffffff254f689a>
    800008a4:	cd7c                	sw	a5,92(a0)
	ctx->state[4] = 0x510e527f;
    800008a6:	510e57b7          	lui	a5,0x510e5
    800008aa:	27f78793          	addi	a5,a5,639 # 510e527f <_entry-0x2ef1ad81>
    800008ae:	d13c                	sw	a5,96(a0)
	ctx->state[5] = 0x9b05688c;
    800008b0:	9b0577b7          	lui	a5,0x9b057
    800008b4:	88c78793          	addi	a5,a5,-1908 # ffffffff9b05688c <kernel_elfhdr+0xffffffff1b04dbec>
    800008b8:	d17c                	sw	a5,100(a0)
	ctx->state[6] = 0x1f83d9ab;
    800008ba:	1f83e7b7          	lui	a5,0x1f83e
    800008be:	9ab78793          	addi	a5,a5,-1621 # 1f83d9ab <_entry-0x607c2655>
    800008c2:	d53c                	sw	a5,104(a0)
	ctx->state[7] = 0x5be0cd19;
    800008c4:	5be0d7b7          	lui	a5,0x5be0d
    800008c8:	d1978793          	addi	a5,a5,-743 # 5be0cd19 <_entry-0x241f32e7>
    800008cc:	d57c                	sw	a5,108(a0)
}
    800008ce:	6422                	ld	s0,8(sp)
    800008d0:	0141                	addi	sp,sp,16
    800008d2:	8082                	ret

00000000800008d4 <sha256_update>:

void sha256_update(SHA256_CTX *ctx, const BYTE data[], size_t len)
{
	WORD i;

	for (i = 0; i < len; ++i) {
    800008d4:	c249                	beqz	a2,80000956 <sha256_update+0x82>
{
    800008d6:	7139                	addi	sp,sp,-64
    800008d8:	fc06                	sd	ra,56(sp)
    800008da:	f822                	sd	s0,48(sp)
    800008dc:	f426                	sd	s1,40(sp)
    800008de:	f04a                	sd	s2,32(sp)
    800008e0:	ec4e                	sd	s3,24(sp)
    800008e2:	e852                	sd	s4,16(sp)
    800008e4:	e456                	sd	s5,8(sp)
    800008e6:	0080                	addi	s0,sp,64
    800008e8:	84aa                	mv	s1,a0
    800008ea:	8a2e                	mv	s4,a1
    800008ec:	89b2                	mv	s3,a2
	for (i = 0; i < len; ++i) {
    800008ee:	4901                	li	s2,0
    800008f0:	4781                	li	a5,0
		ctx->data[ctx->datalen] = data[i];
		ctx->datalen++;
		if (ctx->datalen == 64) {
    800008f2:	04000a93          	li	s5,64
    800008f6:	a809                	j	80000908 <sha256_update+0x34>
	for (i = 0; i < len; ++i) {
    800008f8:	0019079b          	addiw	a5,s2,1
    800008fc:	0007891b          	sext.w	s2,a5
    80000900:	1782                	slli	a5,a5,0x20
    80000902:	9381                	srli	a5,a5,0x20
    80000904:	0537f063          	bgeu	a5,s3,80000944 <sha256_update+0x70>
		ctx->data[ctx->datalen] = data[i];
    80000908:	40b8                	lw	a4,64(s1)
    8000090a:	97d2                	add	a5,a5,s4
    8000090c:	0007c683          	lbu	a3,0(a5)
    80000910:	02071793          	slli	a5,a4,0x20
    80000914:	9381                	srli	a5,a5,0x20
    80000916:	97a6                	add	a5,a5,s1
    80000918:	00d78023          	sb	a3,0(a5)
		ctx->datalen++;
    8000091c:	0017079b          	addiw	a5,a4,1
    80000920:	0007871b          	sext.w	a4,a5
    80000924:	c0bc                	sw	a5,64(s1)
		if (ctx->datalen == 64) {
    80000926:	fd5719e3          	bne	a4,s5,800008f8 <sha256_update+0x24>
			sha256_transform(ctx, ctx->data);
    8000092a:	85a6                	mv	a1,s1
    8000092c:	8526                	mv	a0,s1
    8000092e:	00000097          	auipc	ra,0x0
    80000932:	d3c080e7          	jalr	-708(ra) # 8000066a <sha256_transform>
			ctx->bitlen += 512;
    80000936:	64bc                	ld	a5,72(s1)
    80000938:	20078793          	addi	a5,a5,512
    8000093c:	e4bc                	sd	a5,72(s1)
			ctx->datalen = 0;
    8000093e:	0404a023          	sw	zero,64(s1)
    80000942:	bf5d                	j	800008f8 <sha256_update+0x24>
		}
	}
}
    80000944:	70e2                	ld	ra,56(sp)
    80000946:	7442                	ld	s0,48(sp)
    80000948:	74a2                	ld	s1,40(sp)
    8000094a:	7902                	ld	s2,32(sp)
    8000094c:	69e2                	ld	s3,24(sp)
    8000094e:	6a42                	ld	s4,16(sp)
    80000950:	6aa2                	ld	s5,8(sp)
    80000952:	6121                	addi	sp,sp,64
    80000954:	8082                	ret
    80000956:	8082                	ret

0000000080000958 <sha256_final>:

void sha256_final(SHA256_CTX *ctx, BYTE hash[])
{
    80000958:	1101                	addi	sp,sp,-32
    8000095a:	ec06                	sd	ra,24(sp)
    8000095c:	e822                	sd	s0,16(sp)
    8000095e:	e426                	sd	s1,8(sp)
    80000960:	e04a                	sd	s2,0(sp)
    80000962:	1000                	addi	s0,sp,32
    80000964:	84aa                	mv	s1,a0
    80000966:	892e                	mv	s2,a1
	WORD i;

	i = ctx->datalen;
    80000968:	4134                	lw	a3,64(a0)

	// Pad whatever data is left in the buffer.
	if (ctx->datalen < 56) {
    8000096a:	03700793          	li	a5,55
    8000096e:	04d7e763          	bltu	a5,a3,800009bc <sha256_final+0x64>
		ctx->data[i++] = 0x80;
    80000972:	0016879b          	addiw	a5,a3,1
    80000976:	0007861b          	sext.w	a2,a5
    8000097a:	02069713          	slli	a4,a3,0x20
    8000097e:	9301                	srli	a4,a4,0x20
    80000980:	972a                	add	a4,a4,a0
    80000982:	f8000593          	li	a1,-128
    80000986:	00b70023          	sb	a1,0(a4)
		while (i < 56)
    8000098a:	03700713          	li	a4,55
    8000098e:	08c76963          	bltu	a4,a2,80000a20 <sha256_final+0xc8>
    80000992:	02079613          	slli	a2,a5,0x20
    80000996:	9201                	srli	a2,a2,0x20
    80000998:	00c507b3          	add	a5,a0,a2
    8000099c:	00150713          	addi	a4,a0,1
    800009a0:	9732                	add	a4,a4,a2
    800009a2:	03600613          	li	a2,54
    800009a6:	40d606bb          	subw	a3,a2,a3
    800009aa:	1682                	slli	a3,a3,0x20
    800009ac:	9281                	srli	a3,a3,0x20
    800009ae:	9736                	add	a4,a4,a3
			ctx->data[i++] = 0x00;
    800009b0:	00078023          	sb	zero,0(a5)
		while (i < 56)
    800009b4:	0785                	addi	a5,a5,1
    800009b6:	fee79de3          	bne	a5,a4,800009b0 <sha256_final+0x58>
    800009ba:	a09d                	j	80000a20 <sha256_final+0xc8>
	}
	else {
		ctx->data[i++] = 0x80;
    800009bc:	0016879b          	addiw	a5,a3,1
    800009c0:	0007861b          	sext.w	a2,a5
    800009c4:	02069713          	slli	a4,a3,0x20
    800009c8:	9301                	srli	a4,a4,0x20
    800009ca:	972a                	add	a4,a4,a0
    800009cc:	f8000593          	li	a1,-128
    800009d0:	00b70023          	sb	a1,0(a4)
		while (i < 64)
    800009d4:	03f00713          	li	a4,63
    800009d8:	02c76663          	bltu	a4,a2,80000a04 <sha256_final+0xac>
    800009dc:	02079613          	slli	a2,a5,0x20
    800009e0:	9201                	srli	a2,a2,0x20
    800009e2:	00c507b3          	add	a5,a0,a2
    800009e6:	00150713          	addi	a4,a0,1
    800009ea:	9732                	add	a4,a4,a2
    800009ec:	03e00613          	li	a2,62
    800009f0:	40d606bb          	subw	a3,a2,a3
    800009f4:	1682                	slli	a3,a3,0x20
    800009f6:	9281                	srli	a3,a3,0x20
    800009f8:	9736                	add	a4,a4,a3
			ctx->data[i++] = 0x00;
    800009fa:	00078023          	sb	zero,0(a5)
		while (i < 64)
    800009fe:	0785                	addi	a5,a5,1
    80000a00:	fee79de3          	bne	a5,a4,800009fa <sha256_final+0xa2>
		sha256_transform(ctx, ctx->data);
    80000a04:	85a6                	mv	a1,s1
    80000a06:	8526                	mv	a0,s1
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	c62080e7          	jalr	-926(ra) # 8000066a <sha256_transform>
		memset(ctx->data, 0, 56);
    80000a10:	03800613          	li	a2,56
    80000a14:	4581                	li	a1,0
    80000a16:	8526                	mv	a0,s1
    80000a18:	00000097          	auipc	ra,0x0
    80000a1c:	a00080e7          	jalr	-1536(ra) # 80000418 <memset>
	}

	// Append to the padding the total message's length in bits and transform.
	ctx->bitlen += ctx->datalen * 8;
    80000a20:	40bc                	lw	a5,64(s1)
    80000a22:	0037979b          	slliw	a5,a5,0x3
    80000a26:	1782                	slli	a5,a5,0x20
    80000a28:	9381                	srli	a5,a5,0x20
    80000a2a:	64b8                	ld	a4,72(s1)
    80000a2c:	97ba                	add	a5,a5,a4
    80000a2e:	e4bc                	sd	a5,72(s1)
	ctx->data[63] = ctx->bitlen;
    80000a30:	02f48fa3          	sb	a5,63(s1)
	ctx->data[62] = ctx->bitlen >> 8;
    80000a34:	0087d713          	srli	a4,a5,0x8
    80000a38:	02e48f23          	sb	a4,62(s1)
	ctx->data[61] = ctx->bitlen >> 16;
    80000a3c:	0107d713          	srli	a4,a5,0x10
    80000a40:	02e48ea3          	sb	a4,61(s1)
	ctx->data[60] = ctx->bitlen >> 24;
    80000a44:	0187d713          	srli	a4,a5,0x18
    80000a48:	02e48e23          	sb	a4,60(s1)
	ctx->data[59] = ctx->bitlen >> 32;
    80000a4c:	0207d713          	srli	a4,a5,0x20
    80000a50:	02e48da3          	sb	a4,59(s1)
	ctx->data[58] = ctx->bitlen >> 40;
    80000a54:	0287d713          	srli	a4,a5,0x28
    80000a58:	02e48d23          	sb	a4,58(s1)
	ctx->data[57] = ctx->bitlen >> 48;
    80000a5c:	0307d713          	srli	a4,a5,0x30
    80000a60:	02e48ca3          	sb	a4,57(s1)
	ctx->data[56] = ctx->bitlen >> 56;
    80000a64:	93e1                	srli	a5,a5,0x38
    80000a66:	02f48c23          	sb	a5,56(s1)
	sha256_transform(ctx, ctx->data);
    80000a6a:	85a6                	mv	a1,s1
    80000a6c:	8526                	mv	a0,s1
    80000a6e:	00000097          	auipc	ra,0x0
    80000a72:	bfc080e7          	jalr	-1028(ra) # 8000066a <sha256_transform>

	// Since this implementation uses little endian byte ordering and SHA uses big endian,
	// reverse all the bytes when copying the final state to the output hash.
	for (i = 0; i < 4; ++i) {
    80000a76:	85ca                	mv	a1,s2
	sha256_transform(ctx, ctx->data);
    80000a78:	47e1                	li	a5,24
	for (i = 0; i < 4; ++i) {
    80000a7a:	56e1                	li	a3,-8
		hash[i]      = (ctx->state[0] >> (24 - i * 8)) & 0x000000ff;
    80000a7c:	48b8                	lw	a4,80(s1)
    80000a7e:	00f7573b          	srlw	a4,a4,a5
    80000a82:	00e58023          	sb	a4,0(a1)
		hash[i + 4]  = (ctx->state[1] >> (24 - i * 8)) & 0x000000ff;
    80000a86:	48f8                	lw	a4,84(s1)
    80000a88:	00f7573b          	srlw	a4,a4,a5
    80000a8c:	00e58223          	sb	a4,4(a1)
		hash[i + 8]  = (ctx->state[2] >> (24 - i * 8)) & 0x000000ff;
    80000a90:	4cb8                	lw	a4,88(s1)
    80000a92:	00f7573b          	srlw	a4,a4,a5
    80000a96:	00e58423          	sb	a4,8(a1)
		hash[i + 12] = (ctx->state[3] >> (24 - i * 8)) & 0x000000ff;
    80000a9a:	4cf8                	lw	a4,92(s1)
    80000a9c:	00f7573b          	srlw	a4,a4,a5
    80000aa0:	00e58623          	sb	a4,12(a1)
		hash[i + 16] = (ctx->state[4] >> (24 - i * 8)) & 0x000000ff;
    80000aa4:	50b8                	lw	a4,96(s1)
    80000aa6:	00f7573b          	srlw	a4,a4,a5
    80000aaa:	00e58823          	sb	a4,16(a1)
		hash[i + 20] = (ctx->state[5] >> (24 - i * 8)) & 0x000000ff;
    80000aae:	50f8                	lw	a4,100(s1)
    80000ab0:	00f7573b          	srlw	a4,a4,a5
    80000ab4:	00e58a23          	sb	a4,20(a1)
		hash[i + 24] = (ctx->state[6] >> (24 - i * 8)) & 0x000000ff;
    80000ab8:	54b8                	lw	a4,104(s1)
    80000aba:	00f7573b          	srlw	a4,a4,a5
    80000abe:	00e58c23          	sb	a4,24(a1)
		hash[i + 28] = (ctx->state[7] >> (24 - i * 8)) & 0x000000ff;
    80000ac2:	54f8                	lw	a4,108(s1)
    80000ac4:	00f7573b          	srlw	a4,a4,a5
    80000ac8:	00e58e23          	sb	a4,28(a1)
	for (i = 0; i < 4; ++i) {
    80000acc:	37e1                	addiw	a5,a5,-8
    80000ace:	0585                	addi	a1,a1,1
    80000ad0:	fad796e3          	bne	a5,a3,80000a7c <sha256_final+0x124>
	}
    80000ad4:	60e2                	ld	ra,24(sp)
    80000ad6:	6442                	ld	s0,16(sp)
    80000ad8:	64a2                	ld	s1,8(sp)
    80000ada:	6902                	ld	s2,0(sp)
    80000adc:	6105                	addi	sp,sp,32
    80000ade:	8082                	ret
