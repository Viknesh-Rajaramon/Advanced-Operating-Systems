
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	d9010113          	addi	sp,sp,-624 # 80009d90 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	07a000ef          	jal	ra,80000090 <start>

000000008000001a <_entry_kernel>:
    8000001a:	6cf000ef          	jal	ra,80000ee8 <main>

000000008000001e <_entry_test>:
    8000001e:	a001                	j	8000001e <_entry_test>

0000000080000020 <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    80000020:	1141                	addi	sp,sp,-16
    80000022:	e422                	sd	s0,8(sp)
    80000024:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000026:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    8000002a:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002e:	0037979b          	slliw	a5,a5,0x3
    80000032:	02004737          	lui	a4,0x2004
    80000036:	97ba                	add	a5,a5,a4
    80000038:	0200c737          	lui	a4,0x200c
    8000003c:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000040:	000f4637          	lui	a2,0xf4
    80000044:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000048:	9732                	add	a4,a4,a2
    8000004a:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    8000004c:	00259693          	slli	a3,a1,0x2
    80000050:	96ae                	add	a3,a3,a1
    80000052:	068e                	slli	a3,a3,0x3
    80000054:	0000a717          	auipc	a4,0xa
    80000058:	bfc70713          	addi	a4,a4,-1028 # 80009c50 <timer_scratch>
    8000005c:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005e:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    80000060:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000062:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000066:	00006797          	auipc	a5,0x6
    8000006a:	c5a78793          	addi	a5,a5,-934 # 80005cc0 <timervec>
    8000006e:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000072:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000076:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007a:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007e:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000082:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000086:	30479073          	csrw	mie,a5
}
    8000008a:	6422                	ld	s0,8(sp)
    8000008c:	0141                	addi	sp,sp,16
    8000008e:	8082                	ret

0000000080000090 <start>:
{
    80000090:	1141                	addi	sp,sp,-16
    80000092:	e406                	sd	ra,8(sp)
    80000094:	e022                	sd	s0,0(sp)
    80000096:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000098:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    8000009c:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    8000009e:	823e                	mv	tp,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    800000a0:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    800000a4:	7779                	lui	a4,0xffffe
    800000a6:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdaddf>
    800000aa:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000ac:	6705                	lui	a4,0x1
    800000ae:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000b2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000b4:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000b8:	00001797          	auipc	a5,0x1
    800000bc:	e3078793          	addi	a5,a5,-464 # 80000ee8 <main>
    800000c0:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000c4:	4781                	li	a5,0
    800000c6:	18079073          	csrw	satp,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000ca:	57fd                	li	a5,-1
    800000cc:	83a9                	srli	a5,a5,0xa
    800000ce:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000d2:	47bd                	li	a5,15
    800000d4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f48080e7          	jalr	-184(ra) # 80000020 <timerinit>
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000e0:	67c1                	lui	a5,0x10
    800000e2:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000e4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000e8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ec:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000f0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000f4:	10479073          	csrw	sie,a5
  asm volatile("mret");
    800000f8:	30200073          	mret
}
    800000fc:	60a2                	ld	ra,8(sp)
    800000fe:	6402                	ld	s0,0(sp)
    80000100:	0141                	addi	sp,sp,16
    80000102:	8082                	ret

0000000080000104 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000104:	715d                	addi	sp,sp,-80
    80000106:	e486                	sd	ra,72(sp)
    80000108:	e0a2                	sd	s0,64(sp)
    8000010a:	fc26                	sd	s1,56(sp)
    8000010c:	f84a                	sd	s2,48(sp)
    8000010e:	f44e                	sd	s3,40(sp)
    80000110:	f052                	sd	s4,32(sp)
    80000112:	ec56                	sd	s5,24(sp)
    80000114:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000116:	04c05763          	blez	a2,80000164 <consolewrite+0x60>
    8000011a:	8a2a                	mv	s4,a0
    8000011c:	84ae                	mv	s1,a1
    8000011e:	89b2                	mv	s3,a2
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	42a080e7          	jalr	1066(ra) # 80002558 <either_copyin>
    80000136:	01550d63          	beq	a0,s5,80000150 <consolewrite+0x4c>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7f2080e7          	jalr	2034(ra) # 80000930 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x20>
    8000014e:	894e                	mv	s2,s3
  }

  return i;
}
    80000150:	854a                	mv	a0,s2
    80000152:	60a6                	ld	ra,72(sp)
    80000154:	6406                	ld	s0,64(sp)
    80000156:	74e2                	ld	s1,56(sp)
    80000158:	7942                	ld	s2,48(sp)
    8000015a:	79a2                	ld	s3,40(sp)
    8000015c:	7a02                	ld	s4,32(sp)
    8000015e:	6ae2                	ld	s5,24(sp)
    80000160:	6161                	addi	sp,sp,80
    80000162:	8082                	ret
  for(i = 0; i < n; i++){
    80000164:	4901                	li	s2,0
    80000166:	b7ed                	j	80000150 <consolewrite+0x4c>

0000000080000168 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000168:	711d                	addi	sp,sp,-96
    8000016a:	ec86                	sd	ra,88(sp)
    8000016c:	e8a2                	sd	s0,80(sp)
    8000016e:	e4a6                	sd	s1,72(sp)
    80000170:	e0ca                	sd	s2,64(sp)
    80000172:	fc4e                	sd	s3,56(sp)
    80000174:	f852                	sd	s4,48(sp)
    80000176:	f456                	sd	s5,40(sp)
    80000178:	f05a                	sd	s6,32(sp)
    8000017a:	ec5e                	sd	s7,24(sp)
    8000017c:	1080                	addi	s0,sp,96
    8000017e:	8aaa                	mv	s5,a0
    80000180:	8a2e                	mv	s4,a1
    80000182:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000184:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000188:	00012517          	auipc	a0,0x12
    8000018c:	c0850513          	addi	a0,a0,-1016 # 80011d90 <cons>
    80000190:	00001097          	auipc	ra,0x1
    80000194:	ab8080e7          	jalr	-1352(ra) # 80000c48 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00012497          	auipc	s1,0x12
    8000019c:	bf848493          	addi	s1,s1,-1032 # 80011d90 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00012917          	auipc	s2,0x12
    800001a4:	c8890913          	addi	s2,s2,-888 # 80011e28 <cons+0x98>
  while(n > 0){
    800001a8:	09305263          	blez	s3,8000022c <consoleread+0xc4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	02f71763          	bne	a4,a5,800001e2 <consoleread+0x7a>
      if(killed(myproc())){
    800001b8:	00002097          	auipc	ra,0x2
    800001bc:	86c080e7          	jalr	-1940(ra) # 80001a24 <myproc>
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	1e2080e7          	jalr	482(ra) # 800023a2 <killed>
    800001c8:	ed2d                	bnez	a0,80000242 <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001ca:	85a6                	mv	a1,s1
    800001cc:	854a                	mv	a0,s2
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	f2c080e7          	jalr	-212(ra) # 800020fa <sleep>
    while(cons.r == cons.w){
    800001d6:	0984a783          	lw	a5,152(s1)
    800001da:	09c4a703          	lw	a4,156(s1)
    800001de:	fcf70de3          	beq	a4,a5,800001b8 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e2:	00012717          	auipc	a4,0x12
    800001e6:	bae70713          	addi	a4,a4,-1106 # 80011d90 <cons>
    800001ea:	0017869b          	addiw	a3,a5,1
    800001ee:	08d72c23          	sw	a3,152(a4)
    800001f2:	07f7f693          	andi	a3,a5,127
    800001f6:	9736                	add	a4,a4,a3
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000200:	4691                	li	a3,4
    80000202:	06db8463          	beq	s7,a3,8000026a <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000206:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020a:	4685                	li	a3,1
    8000020c:	faf40613          	addi	a2,s0,-81
    80000210:	85d2                	mv	a1,s4
    80000212:	8556                	mv	a0,s5
    80000214:	00002097          	auipc	ra,0x2
    80000218:	2ee080e7          	jalr	750(ra) # 80002502 <either_copyout>
    8000021c:	57fd                	li	a5,-1
    8000021e:	00f50763          	beq	a0,a5,8000022c <consoleread+0xc4>
      break;

    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000226:	47a9                	li	a5,10
    80000228:	f8fb90e3          	bne	s7,a5,800001a8 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022c:	00012517          	auipc	a0,0x12
    80000230:	b6450513          	addi	a0,a0,-1180 # 80011d90 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	ac8080e7          	jalr	-1336(ra) # 80000cfc <release>

  return target - n;
    8000023c:	413b053b          	subw	a0,s6,s3
    80000240:	a811                	j	80000254 <consoleread+0xec>
        release(&cons.lock);
    80000242:	00012517          	auipc	a0,0x12
    80000246:	b4e50513          	addi	a0,a0,-1202 # 80011d90 <cons>
    8000024a:	00001097          	auipc	ra,0x1
    8000024e:	ab2080e7          	jalr	-1358(ra) # 80000cfc <release>
        return -1;
    80000252:	557d                	li	a0,-1
}
    80000254:	60e6                	ld	ra,88(sp)
    80000256:	6446                	ld	s0,80(sp)
    80000258:	64a6                	ld	s1,72(sp)
    8000025a:	6906                	ld	s2,64(sp)
    8000025c:	79e2                	ld	s3,56(sp)
    8000025e:	7a42                	ld	s4,48(sp)
    80000260:	7aa2                	ld	s5,40(sp)
    80000262:	7b02                	ld	s6,32(sp)
    80000264:	6be2                	ld	s7,24(sp)
    80000266:	6125                	addi	sp,sp,96
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677fe3          	bgeu	a4,s6,8000022c <consoleread+0xc4>
        cons.r--;
    80000272:	00012717          	auipc	a4,0x12
    80000276:	baf72b23          	sw	a5,-1098(a4) # 80011e28 <cons+0x98>
    8000027a:	bf4d                	j	8000022c <consoleread+0xc4>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	5de080e7          	jalr	1502(ra) # 8000086a <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	5cc080e7          	jalr	1484(ra) # 8000086a <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	5c0080e7          	jalr	1472(ra) # 8000086a <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5b6080e7          	jalr	1462(ra) # 8000086a <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00012517          	auipc	a0,0x12
    800002d0:	ac450513          	addi	a0,a0,-1340 # 80011d90 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	974080e7          	jalr	-1676(ra) # 80000c48 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2bc080e7          	jalr	700(ra) # 800025ae <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00012517          	auipc	a0,0x12
    800002fe:	a9650513          	addi	a0,a0,-1386 # 80011d90 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9fa080e7          	jalr	-1542(ra) # 80000cfc <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00012717          	auipc	a4,0x12
    80000322:	a7270713          	addi	a4,a4,-1422 # 80011d90 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00012797          	auipc	a5,0x12
    8000034c:	a4878793          	addi	a5,a5,-1464 # 80011d90 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00012797          	auipc	a5,0x12
    8000037a:	ab27a783          	lw	a5,-1358(a5) # 80011e28 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00012717          	auipc	a4,0x12
    8000038e:	a0670713          	addi	a4,a4,-1530 # 80011d90 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00012497          	auipc	s1,0x12
    8000039e:	9f648493          	addi	s1,s1,-1546 # 80011d90 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00012717          	auipc	a4,0x12
    800003da:	9ba70713          	addi	a4,a4,-1606 # 80011d90 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00012717          	auipc	a4,0x12
    800003f0:	a4f72223          	sw	a5,-1468(a4) # 80011e30 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00012797          	auipc	a5,0x12
    80000416:	97e78793          	addi	a5,a5,-1666 # 80011d90 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00012797          	auipc	a5,0x12
    8000043a:	9ec7ab23          	sw	a2,-1546(a5) # 80011e2c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00012517          	auipc	a0,0x12
    80000442:	9ea50513          	addi	a0,a0,-1558 # 80011e28 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d18080e7          	jalr	-744(ra) # 8000215e <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00009597          	auipc	a1,0x9
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80009010 <etext+0x10>
    80000460:	00012517          	auipc	a0,0x12
    80000464:	93050513          	addi	a0,a0,-1744 # 80011d90 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	750080e7          	jalr	1872(ra) # 80000bb8 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	3aa080e7          	jalr	938(ra) # 8000081a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00022797          	auipc	a5,0x22
    8000047c:	cb078793          	addi	a5,a5,-848 # 80022128 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce870713          	addi	a4,a4,-792 # 80000168 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7a70713          	addi	a4,a4,-902 # 80000104 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00009617          	auipc	a2,0x9
    800004be:	b8660613          	addi	a2,a2,-1146 # 80009040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
  //   release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00012797          	auipc	a5,0x12
    80000550:	9007a223          	sw	zero,-1788(a5) # 80011e50 <pr+0x18>
  printf("panic: ");
    80000554:	00009517          	auipc	a0,0x9
    80000558:	ac450513          	addi	a0,a0,-1340 # 80009018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00009517          	auipc	a0,0x9
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800090c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00009717          	auipc	a4,0x9
    80000584:	68f72823          	sw	a5,1680(a4) # 80009c10 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  if (fmt == 0)
    800005ba:	c90d                	beqz	a0,800005ec <printf+0x62>
    800005bc:	8a2a                	mv	s4,a0
  va_start(ap, fmt);
    800005be:	00840793          	addi	a5,s0,8
    800005c2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c6:	00054503          	lbu	a0,0(a0)
    800005ca:	20050063          	beqz	a0,800007ca <printf+0x240>
    800005ce:	4481                	li	s1,0
    if(c != '%'){
    800005d0:	02500b13          	li	s6,37
    switch(c){
    800005d4:	07000b93          	li	s7,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00009a97          	auipc	s5,0x9
    800005dc:	a68a8a93          	addi	s5,s5,-1432 # 80009040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	03400c13          	li	s8,52
  } while((x /= base) != 0);
    800005e8:	4d3d                	li	s10,15
    800005ea:	a025                	j	80000612 <printf+0x88>
    panic("null fmt");
    800005ec:	00009517          	auipc	a0,0x9
    800005f0:	a3c50513          	addi	a0,a0,-1476 # 80009028 <etext+0x28>
    800005f4:	00000097          	auipc	ra,0x0
    800005f8:	f4c080e7          	jalr	-180(ra) # 80000540 <panic>
      consputc(c);
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	c80080e7          	jalr	-896(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000604:	2485                	addiw	s1,s1,1
    80000606:	009a07b3          	add	a5,s4,s1
    8000060a:	0007c503          	lbu	a0,0(a5)
    8000060e:	1a050e63          	beqz	a0,800007ca <printf+0x240>
    if(c != '%'){
    80000612:	ff6515e3          	bne	a0,s6,800005fc <printf+0x72>
    c = fmt[++i] & 0xff;
    80000616:	2485                	addiw	s1,s1,1
    80000618:	009a07b3          	add	a5,s4,s1
    8000061c:	0007c783          	lbu	a5,0(a5)
    80000620:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000624:	1a078363          	beqz	a5,800007ca <printf+0x240>
    switch(c){
    80000628:	11778563          	beq	a5,s7,80000732 <printf+0x1a8>
    8000062c:	02fbee63          	bltu	s7,a5,80000668 <printf+0xde>
    80000630:	07878063          	beq	a5,s8,80000690 <printf+0x106>
    80000634:	06400713          	li	a4,100
    80000638:	02e79063          	bne	a5,a4,80000658 <printf+0xce>
      printint(va_arg(ap, int), 10, 1);
    8000063c:	f8843783          	ld	a5,-120(s0)
    80000640:	00878713          	addi	a4,a5,8
    80000644:	f8e43423          	sd	a4,-120(s0)
    80000648:	4605                	li	a2,1
    8000064a:	45a9                	li	a1,10
    8000064c:	4388                	lw	a0,0(a5)
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	e4e080e7          	jalr	-434(ra) # 8000049c <printint>
      break;
    80000656:	b77d                	j	80000604 <printf+0x7a>
    switch(c){
    80000658:	15679e63          	bne	a5,s6,800007b4 <printf+0x22a>
      consputc('%');
    8000065c:	855a                	mv	a0,s6
    8000065e:	00000097          	auipc	ra,0x0
    80000662:	c1e080e7          	jalr	-994(ra) # 8000027c <consputc>
      break;
    80000666:	bf79                	j	80000604 <printf+0x7a>
    switch(c){
    80000668:	11978863          	beq	a5,s9,80000778 <printf+0x1ee>
    8000066c:	07800713          	li	a4,120
    80000670:	14e79263          	bne	a5,a4,800007b4 <printf+0x22a>
      printint(va_arg(ap, int), 16, 1);
    80000674:	f8843783          	ld	a5,-120(s0)
    80000678:	00878713          	addi	a4,a5,8
    8000067c:	f8e43423          	sd	a4,-120(s0)
    80000680:	4605                	li	a2,1
    80000682:	45c1                	li	a1,16
    80000684:	4388                	lw	a0,0(a5)
    80000686:	00000097          	auipc	ra,0x0
    8000068a:	e16080e7          	jalr	-490(ra) # 8000049c <printint>
      break;
    8000068e:	bf9d                	j	80000604 <printf+0x7a>
      print4hex(va_arg(ap, int), 16, 1);
    80000690:	f8843783          	ld	a5,-120(s0)
    80000694:	00878713          	addi	a4,a5,8
    80000698:	f8e43423          	sd	a4,-120(s0)
    8000069c:	438c                	lw	a1,0(a5)
    x = xx;
    8000069e:	0005879b          	sext.w	a5,a1
  if(sign && (sign = xx < 0))
    800006a2:	0805c563          	bltz	a1,8000072c <printf+0x1a2>
    800006a6:	f8040693          	addi	a3,s0,-128
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006aa:	4901                	li	s2,0
    buf[i++] = digits[x % base];
    800006ac:	864a                	mv	a2,s2
    800006ae:	2905                	addiw	s2,s2,1
    800006b0:	00f7f713          	andi	a4,a5,15
    800006b4:	9756                	add	a4,a4,s5
    800006b6:	00074703          	lbu	a4,0(a4)
    800006ba:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    800006be:	0007871b          	sext.w	a4,a5
    800006c2:	0047d79b          	srliw	a5,a5,0x4
    800006c6:	0685                	addi	a3,a3,1
    800006c8:	feed62e3          	bltu	s10,a4,800006ac <printf+0x122>
  if(sign)
    800006cc:	0005dc63          	bgez	a1,800006e4 <printf+0x15a>
    buf[i++] = '-';
    800006d0:	f9090793          	addi	a5,s2,-112
    800006d4:	00878933          	add	s2,a5,s0
    800006d8:	02d00793          	li	a5,45
    800006dc:	fef90823          	sb	a5,-16(s2)
    800006e0:	0026091b          	addiw	s2,a2,2
  for (int p=4-i; p>=0; p--)
    800006e4:	4991                	li	s3,4
    800006e6:	412989bb          	subw	s3,s3,s2
    800006ea:	0009cc63          	bltz	s3,80000702 <printf+0x178>
    800006ee:	5dfd                	li	s11,-1
    consputc('0');
    800006f0:	03000513          	li	a0,48
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
  for (int p=4-i; p>=0; p--)
    800006fc:	39fd                	addiw	s3,s3,-1
    800006fe:	ffb999e3          	bne	s3,s11,800006f0 <printf+0x166>
  while(--i >= 0)
    80000702:	fff9099b          	addiw	s3,s2,-1
    80000706:	f609c7e3          	bltz	s3,80000674 <printf+0xea>
    8000070a:	f9090793          	addi	a5,s2,-112
    8000070e:	00878933          	add	s2,a5,s0
    80000712:	193d                	addi	s2,s2,-17
    80000714:	5dfd                	li	s11,-1
    consputc(buf[i]);
    80000716:	00094503          	lbu	a0,0(s2)
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000722:	39fd                	addiw	s3,s3,-1
    80000724:	197d                	addi	s2,s2,-1
    80000726:	ffb998e3          	bne	s3,s11,80000716 <printf+0x18c>
    8000072a:	b7a9                	j	80000674 <printf+0xea>
    x = -xx;
    8000072c:	40b007bb          	negw	a5,a1
    80000730:	bf9d                	j	800006a6 <printf+0x11c>
      printptr(va_arg(ap, uint64));
    80000732:	f8843783          	ld	a5,-120(s0)
    80000736:	00878713          	addi	a4,a5,8
    8000073a:	f8e43423          	sd	a4,-120(s0)
    8000073e:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000742:	03000513          	li	a0,48
    80000746:	00000097          	auipc	ra,0x0
    8000074a:	b36080e7          	jalr	-1226(ra) # 8000027c <consputc>
  consputc('x');
    8000074e:	07800513          	li	a0,120
    80000752:	00000097          	auipc	ra,0x0
    80000756:	b2a080e7          	jalr	-1238(ra) # 8000027c <consputc>
    8000075a:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000075c:	03c9d793          	srli	a5,s3,0x3c
    80000760:	97d6                	add	a5,a5,s5
    80000762:	0007c503          	lbu	a0,0(a5)
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	b16080e7          	jalr	-1258(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000076e:	0992                	slli	s3,s3,0x4
    80000770:	397d                	addiw	s2,s2,-1
    80000772:	fe0915e3          	bnez	s2,8000075c <printf+0x1d2>
    80000776:	b579                	j	80000604 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    80000778:	f8843783          	ld	a5,-120(s0)
    8000077c:	00878713          	addi	a4,a5,8
    80000780:	f8e43423          	sd	a4,-120(s0)
    80000784:	0007b903          	ld	s2,0(a5)
    80000788:	00090f63          	beqz	s2,800007a6 <printf+0x21c>
      for(; *s; s++)
    8000078c:	00094503          	lbu	a0,0(s2)
    80000790:	e6050ae3          	beqz	a0,80000604 <printf+0x7a>
        consputc(*s);
    80000794:	00000097          	auipc	ra,0x0
    80000798:	ae8080e7          	jalr	-1304(ra) # 8000027c <consputc>
      for(; *s; s++)
    8000079c:	0905                	addi	s2,s2,1
    8000079e:	00094503          	lbu	a0,0(s2)
    800007a2:	f96d                	bnez	a0,80000794 <printf+0x20a>
    800007a4:	b585                	j	80000604 <printf+0x7a>
        s = "(null)";
    800007a6:	00009917          	auipc	s2,0x9
    800007aa:	87a90913          	addi	s2,s2,-1926 # 80009020 <etext+0x20>
      for(; *s; s++)
    800007ae:	02800513          	li	a0,40
    800007b2:	b7cd                	j	80000794 <printf+0x20a>
      consputc('%');
    800007b4:	855a                	mv	a0,s6
    800007b6:	00000097          	auipc	ra,0x0
    800007ba:	ac6080e7          	jalr	-1338(ra) # 8000027c <consputc>
      consputc(c);
    800007be:	854a                	mv	a0,s2
    800007c0:	00000097          	auipc	ra,0x0
    800007c4:	abc080e7          	jalr	-1348(ra) # 8000027c <consputc>
      break;
    800007c8:	bd35                	j	80000604 <printf+0x7a>
}
    800007ca:	70e6                	ld	ra,120(sp)
    800007cc:	7446                	ld	s0,112(sp)
    800007ce:	74a6                	ld	s1,104(sp)
    800007d0:	7906                	ld	s2,96(sp)
    800007d2:	69e6                	ld	s3,88(sp)
    800007d4:	6a46                	ld	s4,80(sp)
    800007d6:	6aa6                	ld	s5,72(sp)
    800007d8:	6b06                	ld	s6,64(sp)
    800007da:	7be2                	ld	s7,56(sp)
    800007dc:	7c42                	ld	s8,48(sp)
    800007de:	7ca2                	ld	s9,40(sp)
    800007e0:	7d02                	ld	s10,32(sp)
    800007e2:	6de2                	ld	s11,24(sp)
    800007e4:	6129                	addi	sp,sp,192
    800007e6:	8082                	ret

00000000800007e8 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007e8:	1101                	addi	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007f2:	00011497          	auipc	s1,0x11
    800007f6:	64648493          	addi	s1,s1,1606 # 80011e38 <pr>
    800007fa:	00009597          	auipc	a1,0x9
    800007fe:	83e58593          	addi	a1,a1,-1986 # 80009038 <etext+0x38>
    80000802:	8526                	mv	a0,s1
    80000804:	00000097          	auipc	ra,0x0
    80000808:	3b4080e7          	jalr	948(ra) # 80000bb8 <initlock>
  pr.locking = 1;
    8000080c:	4785                	li	a5,1
    8000080e:	cc9c                	sw	a5,24(s1)
}
    80000810:	60e2                	ld	ra,24(sp)
    80000812:	6442                	ld	s0,16(sp)
    80000814:	64a2                	ld	s1,8(sp)
    80000816:	6105                	addi	sp,sp,32
    80000818:	8082                	ret

000000008000081a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000081a:	1141                	addi	sp,sp,-16
    8000081c:	e406                	sd	ra,8(sp)
    8000081e:	e022                	sd	s0,0(sp)
    80000820:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000822:	100007b7          	lui	a5,0x10000
    80000826:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000082a:	f8000713          	li	a4,-128
    8000082e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000832:	470d                	li	a4,3
    80000834:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000838:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000083c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000840:	469d                	li	a3,7
    80000842:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000846:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000084a:	00009597          	auipc	a1,0x9
    8000084e:	80e58593          	addi	a1,a1,-2034 # 80009058 <digits+0x18>
    80000852:	00011517          	auipc	a0,0x11
    80000856:	60650513          	addi	a0,a0,1542 # 80011e58 <uart_tx_lock>
    8000085a:	00000097          	auipc	ra,0x0
    8000085e:	35e080e7          	jalr	862(ra) # 80000bb8 <initlock>
}
    80000862:	60a2                	ld	ra,8(sp)
    80000864:	6402                	ld	s0,0(sp)
    80000866:	0141                	addi	sp,sp,16
    80000868:	8082                	ret

000000008000086a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000086a:	1101                	addi	sp,sp,-32
    8000086c:	ec06                	sd	ra,24(sp)
    8000086e:	e822                	sd	s0,16(sp)
    80000870:	e426                	sd	s1,8(sp)
    80000872:	1000                	addi	s0,sp,32
    80000874:	84aa                	mv	s1,a0
  push_off();
    80000876:	00000097          	auipc	ra,0x0
    8000087a:	386080e7          	jalr	902(ra) # 80000bfc <push_off>
  //   for(;;)
  //     ;
  // }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000087e:	10000737          	lui	a4,0x10000
    80000882:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000886:	0207f793          	andi	a5,a5,32
    8000088a:	dfe5                	beqz	a5,80000882 <uartputc_sync+0x18>
    ;
  WriteReg(THR, c);
    8000088c:	0ff4f493          	zext.b	s1,s1
    80000890:	100007b7          	lui	a5,0x10000
    80000894:	00978023          	sb	s1,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000898:	00000097          	auipc	ra,0x0
    8000089c:	404080e7          	jalr	1028(ra) # 80000c9c <pop_off>
}
    800008a0:	60e2                	ld	ra,24(sp)
    800008a2:	6442                	ld	s0,16(sp)
    800008a4:	64a2                	ld	s1,8(sp)
    800008a6:	6105                	addi	sp,sp,32
    800008a8:	8082                	ret

00000000800008aa <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008aa:	00009797          	auipc	a5,0x9
    800008ae:	36e7b783          	ld	a5,878(a5) # 80009c18 <uart_tx_r>
    800008b2:	00009717          	auipc	a4,0x9
    800008b6:	36e73703          	ld	a4,878(a4) # 80009c20 <uart_tx_w>
    800008ba:	06f70a63          	beq	a4,a5,8000092e <uartstart+0x84>
{
    800008be:	7139                	addi	sp,sp,-64
    800008c0:	fc06                	sd	ra,56(sp)
    800008c2:	f822                	sd	s0,48(sp)
    800008c4:	f426                	sd	s1,40(sp)
    800008c6:	f04a                	sd	s2,32(sp)
    800008c8:	ec4e                	sd	s3,24(sp)
    800008ca:	e852                	sd	s4,16(sp)
    800008cc:	e456                	sd	s5,8(sp)
    800008ce:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d0:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008d4:	00011a17          	auipc	s4,0x11
    800008d8:	584a0a13          	addi	s4,s4,1412 # 80011e58 <uart_tx_lock>
    uart_tx_r += 1;
    800008dc:	00009497          	auipc	s1,0x9
    800008e0:	33c48493          	addi	s1,s1,828 # 80009c18 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008e4:	00009997          	auipc	s3,0x9
    800008e8:	33c98993          	addi	s3,s3,828 # 80009c20 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008ec:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008f0:	02077713          	andi	a4,a4,32
    800008f4:	c705                	beqz	a4,8000091c <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008f6:	01f7f713          	andi	a4,a5,31
    800008fa:	9752                	add	a4,a4,s4
    800008fc:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000900:	0785                	addi	a5,a5,1
    80000902:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000904:	8526                	mv	a0,s1
    80000906:	00002097          	auipc	ra,0x2
    8000090a:	858080e7          	jalr	-1960(ra) # 8000215e <wakeup>
    
    WriteReg(THR, c);
    8000090e:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000912:	609c                	ld	a5,0(s1)
    80000914:	0009b703          	ld	a4,0(s3)
    80000918:	fcf71ae3          	bne	a4,a5,800008ec <uartstart+0x42>
  }
}
    8000091c:	70e2                	ld	ra,56(sp)
    8000091e:	7442                	ld	s0,48(sp)
    80000920:	74a2                	ld	s1,40(sp)
    80000922:	7902                	ld	s2,32(sp)
    80000924:	69e2                	ld	s3,24(sp)
    80000926:	6a42                	ld	s4,16(sp)
    80000928:	6aa2                	ld	s5,8(sp)
    8000092a:	6121                	addi	sp,sp,64
    8000092c:	8082                	ret
    8000092e:	8082                	ret

0000000080000930 <uartputc>:
{
    80000930:	7179                	addi	sp,sp,-48
    80000932:	f406                	sd	ra,40(sp)
    80000934:	f022                	sd	s0,32(sp)
    80000936:	ec26                	sd	s1,24(sp)
    80000938:	e84a                	sd	s2,16(sp)
    8000093a:	e44e                	sd	s3,8(sp)
    8000093c:	e052                	sd	s4,0(sp)
    8000093e:	1800                	addi	s0,sp,48
    80000940:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000942:	00011517          	auipc	a0,0x11
    80000946:	51650513          	addi	a0,a0,1302 # 80011e58 <uart_tx_lock>
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	2fe080e7          	jalr	766(ra) # 80000c48 <acquire>
  if(panicked){
    80000952:	00009797          	auipc	a5,0x9
    80000956:	2be7a783          	lw	a5,702(a5) # 80009c10 <panicked>
    8000095a:	e7c9                	bnez	a5,800009e4 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000095c:	00009717          	auipc	a4,0x9
    80000960:	2c473703          	ld	a4,708(a4) # 80009c20 <uart_tx_w>
    80000964:	00009797          	auipc	a5,0x9
    80000968:	2b47b783          	ld	a5,692(a5) # 80009c18 <uart_tx_r>
    8000096c:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000970:	00011997          	auipc	s3,0x11
    80000974:	4e898993          	addi	s3,s3,1256 # 80011e58 <uart_tx_lock>
    80000978:	00009497          	auipc	s1,0x9
    8000097c:	2a048493          	addi	s1,s1,672 # 80009c18 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000980:	00009917          	auipc	s2,0x9
    80000984:	2a090913          	addi	s2,s2,672 # 80009c20 <uart_tx_w>
    80000988:	00e79f63          	bne	a5,a4,800009a6 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000098c:	85ce                	mv	a1,s3
    8000098e:	8526                	mv	a0,s1
    80000990:	00001097          	auipc	ra,0x1
    80000994:	76a080e7          	jalr	1898(ra) # 800020fa <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000998:	00093703          	ld	a4,0(s2)
    8000099c:	609c                	ld	a5,0(s1)
    8000099e:	02078793          	addi	a5,a5,32
    800009a2:	fee785e3          	beq	a5,a4,8000098c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    800009a6:	00011497          	auipc	s1,0x11
    800009aa:	4b248493          	addi	s1,s1,1202 # 80011e58 <uart_tx_lock>
    800009ae:	01f77793          	andi	a5,a4,31
    800009b2:	97a6                	add	a5,a5,s1
    800009b4:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009b8:	0705                	addi	a4,a4,1
    800009ba:	00009797          	auipc	a5,0x9
    800009be:	26e7b323          	sd	a4,614(a5) # 80009c20 <uart_tx_w>
  uartstart();
    800009c2:	00000097          	auipc	ra,0x0
    800009c6:	ee8080e7          	jalr	-280(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    800009ca:	8526                	mv	a0,s1
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	330080e7          	jalr	816(ra) # 80000cfc <release>
}
    800009d4:	70a2                	ld	ra,40(sp)
    800009d6:	7402                	ld	s0,32(sp)
    800009d8:	64e2                	ld	s1,24(sp)
    800009da:	6942                	ld	s2,16(sp)
    800009dc:	69a2                	ld	s3,8(sp)
    800009de:	6a02                	ld	s4,0(sp)
    800009e0:	6145                	addi	sp,sp,48
    800009e2:	8082                	ret
    for(;;)
    800009e4:	a001                	j	800009e4 <uartputc+0xb4>

00000000800009e6 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009e6:	1141                	addi	sp,sp,-16
    800009e8:	e422                	sd	s0,8(sp)
    800009ea:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ec:	100007b7          	lui	a5,0x10000
    800009f0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009f4:	8b85                	andi	a5,a5,1
    800009f6:	cb81                	beqz	a5,80000a06 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800009f8:	100007b7          	lui	a5,0x10000
    800009fc:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000a00:	6422                	ld	s0,8(sp)
    80000a02:	0141                	addi	sp,sp,16
    80000a04:	8082                	ret
    return -1;
    80000a06:	557d                	li	a0,-1
    80000a08:	bfe5                	j	80000a00 <uartgetc+0x1a>

0000000080000a0a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000a0a:	1101                	addi	sp,sp,-32
    80000a0c:	ec06                	sd	ra,24(sp)
    80000a0e:	e822                	sd	s0,16(sp)
    80000a10:	e426                	sd	s1,8(sp)
    80000a12:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a14:	54fd                	li	s1,-1
    80000a16:	a029                	j	80000a20 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a18:	00000097          	auipc	ra,0x0
    80000a1c:	8a6080e7          	jalr	-1882(ra) # 800002be <consoleintr>
    int c = uartgetc();
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	fc6080e7          	jalr	-58(ra) # 800009e6 <uartgetc>
    if(c == -1)
    80000a28:	fe9518e3          	bne	a0,s1,80000a18 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a2c:	00011497          	auipc	s1,0x11
    80000a30:	42c48493          	addi	s1,s1,1068 # 80011e58 <uart_tx_lock>
    80000a34:	8526                	mv	a0,s1
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	212080e7          	jalr	530(ra) # 80000c48 <acquire>
  uartstart();
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	e6c080e7          	jalr	-404(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    80000a46:	8526                	mv	a0,s1
    80000a48:	00000097          	auipc	ra,0x0
    80000a4c:	2b4080e7          	jalr	692(ra) # 80000cfc <release>
}
    80000a50:	60e2                	ld	ra,24(sp)
    80000a52:	6442                	ld	s0,16(sp)
    80000a54:	64a2                	ld	s1,8(sp)
    80000a56:	6105                	addi	sp,sp,32
    80000a58:	8082                	ret

0000000080000a5a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a5a:	1101                	addi	sp,sp,-32
    80000a5c:	ec06                	sd	ra,24(sp)
    80000a5e:	e822                	sd	s0,16(sp)
    80000a60:	e426                	sd	s1,8(sp)
    80000a62:	e04a                	sd	s2,0(sp)
    80000a64:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a66:	03451793          	slli	a5,a0,0x34
    80000a6a:	ebb9                	bnez	a5,80000ac0 <kfree+0x66>
    80000a6c:	84aa                	mv	s1,a0
    80000a6e:	00023797          	auipc	a5,0x23
    80000a72:	fb278793          	addi	a5,a5,-78 # 80023a20 <end>
    80000a76:	04f56563          	bltu	a0,a5,80000ac0 <kfree+0x66>
    80000a7a:	47c5                	li	a5,17
    80000a7c:	07ee                	slli	a5,a5,0x1b
    80000a7e:	04f57163          	bgeu	a0,a5,80000ac0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a82:	6605                	lui	a2,0x1
    80000a84:	4585                	li	a1,1
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	2be080e7          	jalr	702(ra) # 80000d44 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a8e:	00011917          	auipc	s2,0x11
    80000a92:	40290913          	addi	s2,s2,1026 # 80011e90 <kmem>
    80000a96:	854a                	mv	a0,s2
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	1b0080e7          	jalr	432(ra) # 80000c48 <acquire>
  r->next = kmem.freelist;
    80000aa0:	01893783          	ld	a5,24(s2)
    80000aa4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000aa6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000aaa:	854a                	mv	a0,s2
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	250080e7          	jalr	592(ra) # 80000cfc <release>
}
    80000ab4:	60e2                	ld	ra,24(sp)
    80000ab6:	6442                	ld	s0,16(sp)
    80000ab8:	64a2                	ld	s1,8(sp)
    80000aba:	6902                	ld	s2,0(sp)
    80000abc:	6105                	addi	sp,sp,32
    80000abe:	8082                	ret
    panic("kfree");
    80000ac0:	00008517          	auipc	a0,0x8
    80000ac4:	5a050513          	addi	a0,a0,1440 # 80009060 <digits+0x20>
    80000ac8:	00000097          	auipc	ra,0x0
    80000acc:	a78080e7          	jalr	-1416(ra) # 80000540 <panic>

0000000080000ad0 <freerange>:
{
    80000ad0:	7179                	addi	sp,sp,-48
    80000ad2:	f406                	sd	ra,40(sp)
    80000ad4:	f022                	sd	s0,32(sp)
    80000ad6:	ec26                	sd	s1,24(sp)
    80000ad8:	e84a                	sd	s2,16(sp)
    80000ada:	e44e                	sd	s3,8(sp)
    80000adc:	e052                	sd	s4,0(sp)
    80000ade:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae0:	6785                	lui	a5,0x1
    80000ae2:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ae6:	00e504b3          	add	s1,a0,a4
    80000aea:	777d                	lui	a4,0xfffff
    80000aec:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aee:	94be                	add	s1,s1,a5
    80000af0:	0095ee63          	bltu	a1,s1,80000b0c <freerange+0x3c>
    80000af4:	892e                	mv	s2,a1
    kfree(p);
    80000af6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	6985                	lui	s3,0x1
    kfree(p);
    80000afa:	01448533          	add	a0,s1,s4
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f5c080e7          	jalr	-164(ra) # 80000a5a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94ce                	add	s1,s1,s3
    80000b08:	fe9979e3          	bgeu	s2,s1,80000afa <freerange+0x2a>
}
    80000b0c:	70a2                	ld	ra,40(sp)
    80000b0e:	7402                	ld	s0,32(sp)
    80000b10:	64e2                	ld	s1,24(sp)
    80000b12:	6942                	ld	s2,16(sp)
    80000b14:	69a2                	ld	s3,8(sp)
    80000b16:	6a02                	ld	s4,0(sp)
    80000b18:	6145                	addi	sp,sp,48
    80000b1a:	8082                	ret

0000000080000b1c <kinit>:
{
    80000b1c:	1141                	addi	sp,sp,-16
    80000b1e:	e406                	sd	ra,8(sp)
    80000b20:	e022                	sd	s0,0(sp)
    80000b22:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b24:	00008597          	auipc	a1,0x8
    80000b28:	54458593          	addi	a1,a1,1348 # 80009068 <digits+0x28>
    80000b2c:	00011517          	auipc	a0,0x11
    80000b30:	36450513          	addi	a0,a0,868 # 80011e90 <kmem>
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	084080e7          	jalr	132(ra) # 80000bb8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b3c:	45c5                	li	a1,17
    80000b3e:	05ee                	slli	a1,a1,0x1b
    80000b40:	00023517          	auipc	a0,0x23
    80000b44:	ee050513          	addi	a0,a0,-288 # 80023a20 <end>
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	f88080e7          	jalr	-120(ra) # 80000ad0 <freerange>
}
    80000b50:	60a2                	ld	ra,8(sp)
    80000b52:	6402                	ld	s0,0(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b58:	1101                	addi	sp,sp,-32
    80000b5a:	ec06                	sd	ra,24(sp)
    80000b5c:	e822                	sd	s0,16(sp)
    80000b5e:	e426                	sd	s1,8(sp)
    80000b60:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b62:	00011497          	auipc	s1,0x11
    80000b66:	32e48493          	addi	s1,s1,814 # 80011e90 <kmem>
    80000b6a:	8526                	mv	a0,s1
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	0dc080e7          	jalr	220(ra) # 80000c48 <acquire>
  r = kmem.freelist;
    80000b74:	6c84                	ld	s1,24(s1)
  if(r)
    80000b76:	c885                	beqz	s1,80000ba6 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b78:	609c                	ld	a5,0(s1)
    80000b7a:	00011517          	auipc	a0,0x11
    80000b7e:	31650513          	addi	a0,a0,790 # 80011e90 <kmem>
    80000b82:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	178080e7          	jalr	376(ra) # 80000cfc <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b8c:	6605                	lui	a2,0x1
    80000b8e:	4595                	li	a1,5
    80000b90:	8526                	mv	a0,s1
    80000b92:	00000097          	auipc	ra,0x0
    80000b96:	1b2080e7          	jalr	434(ra) # 80000d44 <memset>
  return (void*)r;
}
    80000b9a:	8526                	mv	a0,s1
    80000b9c:	60e2                	ld	ra,24(sp)
    80000b9e:	6442                	ld	s0,16(sp)
    80000ba0:	64a2                	ld	s1,8(sp)
    80000ba2:	6105                	addi	sp,sp,32
    80000ba4:	8082                	ret
  release(&kmem.lock);
    80000ba6:	00011517          	auipc	a0,0x11
    80000baa:	2ea50513          	addi	a0,a0,746 # 80011e90 <kmem>
    80000bae:	00000097          	auipc	ra,0x0
    80000bb2:	14e080e7          	jalr	334(ra) # 80000cfc <release>
  if(r)
    80000bb6:	b7d5                	j	80000b9a <kalloc+0x42>

0000000080000bb8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bb8:	1141                	addi	sp,sp,-16
    80000bba:	e422                	sd	s0,8(sp)
    80000bbc:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bbe:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bc0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bc4:	00053823          	sd	zero,16(a0)
}
    80000bc8:	6422                	ld	s0,8(sp)
    80000bca:	0141                	addi	sp,sp,16
    80000bcc:	8082                	ret

0000000080000bce <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bce:	411c                	lw	a5,0(a0)
    80000bd0:	e399                	bnez	a5,80000bd6 <holding+0x8>
    80000bd2:	4501                	li	a0,0
  return r;
}
    80000bd4:	8082                	ret
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	6904                	ld	s1,16(a0)
    80000be2:	00001097          	auipc	ra,0x1
    80000be6:	e26080e7          	jalr	-474(ra) # 80001a08 <mycpu>
    80000bea:	40a48533          	sub	a0,s1,a0
    80000bee:	00153513          	seqz	a0,a0
}
    80000bf2:	60e2                	ld	ra,24(sp)
    80000bf4:	6442                	ld	s0,16(sp)
    80000bf6:	64a2                	ld	s1,8(sp)
    80000bf8:	6105                	addi	sp,sp,32
    80000bfa:	8082                	ret

0000000080000bfc <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bfc:	1101                	addi	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c06:	100024f3          	csrr	s1,sstatus
    80000c0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c0e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c10:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	df4080e7          	jalr	-524(ra) # 80001a08 <mycpu>
    80000c1c:	5d3c                	lw	a5,120(a0)
    80000c1e:	cf89                	beqz	a5,80000c38 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c20:	00001097          	auipc	ra,0x1
    80000c24:	de8080e7          	jalr	-536(ra) # 80001a08 <mycpu>
    80000c28:	5d3c                	lw	a5,120(a0)
    80000c2a:	2785                	addiw	a5,a5,1
    80000c2c:	dd3c                	sw	a5,120(a0)
}
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6105                	addi	sp,sp,32
    80000c36:	8082                	ret
    mycpu()->intena = old;
    80000c38:	00001097          	auipc	ra,0x1
    80000c3c:	dd0080e7          	jalr	-560(ra) # 80001a08 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c40:	8085                	srli	s1,s1,0x1
    80000c42:	8885                	andi	s1,s1,1
    80000c44:	dd64                	sw	s1,124(a0)
    80000c46:	bfe9                	j	80000c20 <push_off+0x24>

0000000080000c48 <acquire>:
{
    80000c48:	1101                	addi	sp,sp,-32
    80000c4a:	ec06                	sd	ra,24(sp)
    80000c4c:	e822                	sd	s0,16(sp)
    80000c4e:	e426                	sd	s1,8(sp)
    80000c50:	1000                	addi	s0,sp,32
    80000c52:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c54:	00000097          	auipc	ra,0x0
    80000c58:	fa8080e7          	jalr	-88(ra) # 80000bfc <push_off>
  if(holding(lk))
    80000c5c:	8526                	mv	a0,s1
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	f70080e7          	jalr	-144(ra) # 80000bce <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c66:	4705                	li	a4,1
  if(holding(lk))
    80000c68:	e115                	bnez	a0,80000c8c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c6a:	87ba                	mv	a5,a4
    80000c6c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c70:	2781                	sext.w	a5,a5
    80000c72:	ffe5                	bnez	a5,80000c6a <acquire+0x22>
  __sync_synchronize();
    80000c74:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c78:	00001097          	auipc	ra,0x1
    80000c7c:	d90080e7          	jalr	-624(ra) # 80001a08 <mycpu>
    80000c80:	e888                	sd	a0,16(s1)
}
    80000c82:	60e2                	ld	ra,24(sp)
    80000c84:	6442                	ld	s0,16(sp)
    80000c86:	64a2                	ld	s1,8(sp)
    80000c88:	6105                	addi	sp,sp,32
    80000c8a:	8082                	ret
    panic("acquire");
    80000c8c:	00008517          	auipc	a0,0x8
    80000c90:	3e450513          	addi	a0,a0,996 # 80009070 <digits+0x30>
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	8ac080e7          	jalr	-1876(ra) # 80000540 <panic>

0000000080000c9c <pop_off>:

void
pop_off(void)
{
    80000c9c:	1141                	addi	sp,sp,-16
    80000c9e:	e406                	sd	ra,8(sp)
    80000ca0:	e022                	sd	s0,0(sp)
    80000ca2:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000ca4:	00001097          	auipc	ra,0x1
    80000ca8:	d64080e7          	jalr	-668(ra) # 80001a08 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cb0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cb2:	e78d                	bnez	a5,80000cdc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cb4:	5d3c                	lw	a5,120(a0)
    80000cb6:	02f05b63          	blez	a5,80000cec <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cba:	37fd                	addiw	a5,a5,-1
    80000cbc:	0007871b          	sext.w	a4,a5
    80000cc0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cc2:	eb09                	bnez	a4,80000cd4 <pop_off+0x38>
    80000cc4:	5d7c                	lw	a5,124(a0)
    80000cc6:	c799                	beqz	a5,80000cd4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ccc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cd4:	60a2                	ld	ra,8(sp)
    80000cd6:	6402                	ld	s0,0(sp)
    80000cd8:	0141                	addi	sp,sp,16
    80000cda:	8082                	ret
    panic("pop_off - interruptible");
    80000cdc:	00008517          	auipc	a0,0x8
    80000ce0:	39c50513          	addi	a0,a0,924 # 80009078 <digits+0x38>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	85c080e7          	jalr	-1956(ra) # 80000540 <panic>
    panic("pop_off");
    80000cec:	00008517          	auipc	a0,0x8
    80000cf0:	3a450513          	addi	a0,a0,932 # 80009090 <digits+0x50>
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	84c080e7          	jalr	-1972(ra) # 80000540 <panic>

0000000080000cfc <release>:
{
    80000cfc:	1101                	addi	sp,sp,-32
    80000cfe:	ec06                	sd	ra,24(sp)
    80000d00:	e822                	sd	s0,16(sp)
    80000d02:	e426                	sd	s1,8(sp)
    80000d04:	1000                	addi	s0,sp,32
    80000d06:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	ec6080e7          	jalr	-314(ra) # 80000bce <holding>
    80000d10:	c115                	beqz	a0,80000d34 <release+0x38>
  lk->cpu = 0;
    80000d12:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d16:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d1a:	0f50000f          	fence	iorw,ow
    80000d1e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	f7a080e7          	jalr	-134(ra) # 80000c9c <pop_off>
}
    80000d2a:	60e2                	ld	ra,24(sp)
    80000d2c:	6442                	ld	s0,16(sp)
    80000d2e:	64a2                	ld	s1,8(sp)
    80000d30:	6105                	addi	sp,sp,32
    80000d32:	8082                	ret
    panic("release");
    80000d34:	00008517          	auipc	a0,0x8
    80000d38:	36450513          	addi	a0,a0,868 # 80009098 <digits+0x58>
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	804080e7          	jalr	-2044(ra) # 80000540 <panic>

0000000080000d44 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d44:	1141                	addi	sp,sp,-16
    80000d46:	e422                	sd	s0,8(sp)
    80000d48:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d4a:	ca19                	beqz	a2,80000d60 <memset+0x1c>
    80000d4c:	87aa                	mv	a5,a0
    80000d4e:	1602                	slli	a2,a2,0x20
    80000d50:	9201                	srli	a2,a2,0x20
    80000d52:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d56:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d5a:	0785                	addi	a5,a5,1
    80000d5c:	fee79de3          	bne	a5,a4,80000d56 <memset+0x12>
  }
  return dst;
}
    80000d60:	6422                	ld	s0,8(sp)
    80000d62:	0141                	addi	sp,sp,16
    80000d64:	8082                	ret

0000000080000d66 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d66:	1141                	addi	sp,sp,-16
    80000d68:	e422                	sd	s0,8(sp)
    80000d6a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d6c:	ca05                	beqz	a2,80000d9c <memcmp+0x36>
    80000d6e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d72:	1682                	slli	a3,a3,0x20
    80000d74:	9281                	srli	a3,a3,0x20
    80000d76:	0685                	addi	a3,a3,1
    80000d78:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d7a:	00054783          	lbu	a5,0(a0)
    80000d7e:	0005c703          	lbu	a4,0(a1)
    80000d82:	00e79863          	bne	a5,a4,80000d92 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d86:	0505                	addi	a0,a0,1
    80000d88:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d8a:	fed518e3          	bne	a0,a3,80000d7a <memcmp+0x14>
  }

  return 0;
    80000d8e:	4501                	li	a0,0
    80000d90:	a019                	j	80000d96 <memcmp+0x30>
      return *s1 - *s2;
    80000d92:	40e7853b          	subw	a0,a5,a4
}
    80000d96:	6422                	ld	s0,8(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret
  return 0;
    80000d9c:	4501                	li	a0,0
    80000d9e:	bfe5                	j	80000d96 <memcmp+0x30>

0000000080000da0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e422                	sd	s0,8(sp)
    80000da4:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000da6:	c205                	beqz	a2,80000dc6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000da8:	02a5e263          	bltu	a1,a0,80000dcc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dac:	1602                	slli	a2,a2,0x20
    80000dae:	9201                	srli	a2,a2,0x20
    80000db0:	00c587b3          	add	a5,a1,a2
{
    80000db4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000db6:	0585                	addi	a1,a1,1
    80000db8:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdb5e1>
    80000dba:	fff5c683          	lbu	a3,-1(a1)
    80000dbe:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dc2:	fef59ae3          	bne	a1,a5,80000db6 <memmove+0x16>

  return dst;
}
    80000dc6:	6422                	ld	s0,8(sp)
    80000dc8:	0141                	addi	sp,sp,16
    80000dca:	8082                	ret
  if(s < d && s + n > d){
    80000dcc:	02061693          	slli	a3,a2,0x20
    80000dd0:	9281                	srli	a3,a3,0x20
    80000dd2:	00d58733          	add	a4,a1,a3
    80000dd6:	fce57be3          	bgeu	a0,a4,80000dac <memmove+0xc>
    d += n;
    80000dda:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ddc:	fff6079b          	addiw	a5,a2,-1
    80000de0:	1782                	slli	a5,a5,0x20
    80000de2:	9381                	srli	a5,a5,0x20
    80000de4:	fff7c793          	not	a5,a5
    80000de8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dea:	177d                	addi	a4,a4,-1
    80000dec:	16fd                	addi	a3,a3,-1
    80000dee:	00074603          	lbu	a2,0(a4)
    80000df2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000df6:	fee79ae3          	bne	a5,a4,80000dea <memmove+0x4a>
    80000dfa:	b7f1                	j	80000dc6 <memmove+0x26>

0000000080000dfc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dfc:	1141                	addi	sp,sp,-16
    80000dfe:	e406                	sd	ra,8(sp)
    80000e00:	e022                	sd	s0,0(sp)
    80000e02:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e04:	00000097          	auipc	ra,0x0
    80000e08:	f9c080e7          	jalr	-100(ra) # 80000da0 <memmove>
}
    80000e0c:	60a2                	ld	ra,8(sp)
    80000e0e:	6402                	ld	s0,0(sp)
    80000e10:	0141                	addi	sp,sp,16
    80000e12:	8082                	ret

0000000080000e14 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e14:	1141                	addi	sp,sp,-16
    80000e16:	e422                	sd	s0,8(sp)
    80000e18:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e1a:	ce11                	beqz	a2,80000e36 <strncmp+0x22>
    80000e1c:	00054783          	lbu	a5,0(a0)
    80000e20:	cf89                	beqz	a5,80000e3a <strncmp+0x26>
    80000e22:	0005c703          	lbu	a4,0(a1)
    80000e26:	00f71a63          	bne	a4,a5,80000e3a <strncmp+0x26>
    n--, p++, q++;
    80000e2a:	367d                	addiw	a2,a2,-1
    80000e2c:	0505                	addi	a0,a0,1
    80000e2e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e30:	f675                	bnez	a2,80000e1c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e32:	4501                	li	a0,0
    80000e34:	a809                	j	80000e46 <strncmp+0x32>
    80000e36:	4501                	li	a0,0
    80000e38:	a039                	j	80000e46 <strncmp+0x32>
  if(n == 0)
    80000e3a:	ca09                	beqz	a2,80000e4c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e3c:	00054503          	lbu	a0,0(a0)
    80000e40:	0005c783          	lbu	a5,0(a1)
    80000e44:	9d1d                	subw	a0,a0,a5
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret
    return 0;
    80000e4c:	4501                	li	a0,0
    80000e4e:	bfe5                	j	80000e46 <strncmp+0x32>

0000000080000e50 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e50:	1141                	addi	sp,sp,-16
    80000e52:	e422                	sd	s0,8(sp)
    80000e54:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86b2                	mv	a3,a2
    80000e5a:	367d                	addiw	a2,a2,-1
    80000e5c:	00d05963          	blez	a3,80000e6e <strncpy+0x1e>
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	0005c703          	lbu	a4,0(a1)
    80000e66:	fee78fa3          	sb	a4,-1(a5)
    80000e6a:	0585                	addi	a1,a1,1
    80000e6c:	f775                	bnez	a4,80000e58 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e6e:	873e                	mv	a4,a5
    80000e70:	9fb5                	addw	a5,a5,a3
    80000e72:	37fd                	addiw	a5,a5,-1
    80000e74:	00c05963          	blez	a2,80000e86 <strncpy+0x36>
    *s++ = 0;
    80000e78:	0705                	addi	a4,a4,1
    80000e7a:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e7e:	40e786bb          	subw	a3,a5,a4
    80000e82:	fed04be3          	bgtz	a3,80000e78 <strncpy+0x28>
  return os;
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret

0000000080000e8c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e8c:	1141                	addi	sp,sp,-16
    80000e8e:	e422                	sd	s0,8(sp)
    80000e90:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e92:	02c05363          	blez	a2,80000eb8 <safestrcpy+0x2c>
    80000e96:	fff6069b          	addiw	a3,a2,-1
    80000e9a:	1682                	slli	a3,a3,0x20
    80000e9c:	9281                	srli	a3,a3,0x20
    80000e9e:	96ae                	add	a3,a3,a1
    80000ea0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ea2:	00d58963          	beq	a1,a3,80000eb4 <safestrcpy+0x28>
    80000ea6:	0585                	addi	a1,a1,1
    80000ea8:	0785                	addi	a5,a5,1
    80000eaa:	fff5c703          	lbu	a4,-1(a1)
    80000eae:	fee78fa3          	sb	a4,-1(a5)
    80000eb2:	fb65                	bnez	a4,80000ea2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000eb4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret

0000000080000ebe <strlen>:

int
strlen(const char *s)
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e422                	sd	s0,8(sp)
    80000ec2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ec4:	00054783          	lbu	a5,0(a0)
    80000ec8:	cf91                	beqz	a5,80000ee4 <strlen+0x26>
    80000eca:	0505                	addi	a0,a0,1
    80000ecc:	87aa                	mv	a5,a0
    80000ece:	86be                	mv	a3,a5
    80000ed0:	0785                	addi	a5,a5,1
    80000ed2:	fff7c703          	lbu	a4,-1(a5)
    80000ed6:	ff65                	bnez	a4,80000ece <strlen+0x10>
    80000ed8:	40a6853b          	subw	a0,a3,a0
    80000edc:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000ede:	6422                	ld	s0,8(sp)
    80000ee0:	0141                	addi	sp,sp,16
    80000ee2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ee4:	4501                	li	a0,0
    80000ee6:	bfe5                	j	80000ede <strlen+0x20>

0000000080000ee8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ee8:	1141                	addi	sp,sp,-16
    80000eea:	e406                	sd	ra,8(sp)
    80000eec:	e022                	sd	s0,0(sp)
    80000eee:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	b08080e7          	jalr	-1272(ra) # 800019f8 <cpuid>
    trap_and_emulate_init();

    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ef8:	00009717          	auipc	a4,0x9
    80000efc:	d3070713          	addi	a4,a4,-720 # 80009c28 <started>
  if(cpuid() == 0){
    80000f00:	c139                	beqz	a0,80000f46 <main+0x5e>
    while(started == 0)
    80000f02:	431c                	lw	a5,0(a4)
    80000f04:	2781                	sext.w	a5,a5
    80000f06:	dff5                	beqz	a5,80000f02 <main+0x1a>
      ;
    __sync_synchronize();
    80000f08:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f0c:	00001097          	auipc	ra,0x1
    80000f10:	aec080e7          	jalr	-1300(ra) # 800019f8 <cpuid>
    80000f14:	85aa                	mv	a1,a0
    80000f16:	00008517          	auipc	a0,0x8
    80000f1a:	1a250513          	addi	a0,a0,418 # 800090b8 <digits+0x78>
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	66c080e7          	jalr	1644(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	0e0080e7          	jalr	224(ra) # 80001006 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	7c2080e7          	jalr	1986(ra) # 800026f0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f36:	00005097          	auipc	ra,0x5
    80000f3a:	dca080e7          	jalr	-566(ra) # 80005d00 <plicinithart>
  }

  scheduler();        
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	00a080e7          	jalr	10(ra) # 80001f48 <scheduler>
    consoleinit();
    80000f46:	fffff097          	auipc	ra,0xfffff
    80000f4a:	50a080e7          	jalr	1290(ra) # 80000450 <consoleinit>
    printfinit();
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	89a080e7          	jalr	-1894(ra) # 800007e8 <printfinit>
    printf("\n");
    80000f56:	00008517          	auipc	a0,0x8
    80000f5a:	17250513          	addi	a0,a0,370 # 800090c8 <digits+0x88>
    80000f5e:	fffff097          	auipc	ra,0xfffff
    80000f62:	62c080e7          	jalr	1580(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f66:	00008517          	auipc	a0,0x8
    80000f6a:	13a50513          	addi	a0,a0,314 # 800090a0 <digits+0x60>
    80000f6e:	fffff097          	auipc	ra,0xfffff
    80000f72:	61c080e7          	jalr	1564(ra) # 8000058a <printf>
    printf("\n");
    80000f76:	00008517          	auipc	a0,0x8
    80000f7a:	15250513          	addi	a0,a0,338 # 800090c8 <digits+0x88>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	60c080e7          	jalr	1548(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f86:	00000097          	auipc	ra,0x0
    80000f8a:	b96080e7          	jalr	-1130(ra) # 80000b1c <kinit>
    kvminit();       // create kernel page table
    80000f8e:	00000097          	auipc	ra,0x0
    80000f92:	32e080e7          	jalr	814(ra) # 800012bc <kvminit>
    kvminithart();   // turn on paging
    80000f96:	00000097          	auipc	ra,0x0
    80000f9a:	070080e7          	jalr	112(ra) # 80001006 <kvminithart>
    procinit();      // process table
    80000f9e:	00001097          	auipc	ra,0x1
    80000fa2:	9a6080e7          	jalr	-1626(ra) # 80001944 <procinit>
    trapinit();      // trap vectors
    80000fa6:	00001097          	auipc	ra,0x1
    80000faa:	722080e7          	jalr	1826(ra) # 800026c8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	742080e7          	jalr	1858(ra) # 800026f0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fb6:	00005097          	auipc	ra,0x5
    80000fba:	d34080e7          	jalr	-716(ra) # 80005cea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fbe:	00005097          	auipc	ra,0x5
    80000fc2:	d42080e7          	jalr	-702(ra) # 80005d00 <plicinithart>
    binit();         // buffer cache
    80000fc6:	00002097          	auipc	ra,0x2
    80000fca:	ed4080e7          	jalr	-300(ra) # 80002e9a <binit>
    iinit();         // inode table
    80000fce:	00002097          	auipc	ra,0x2
    80000fd2:	572080e7          	jalr	1394(ra) # 80003540 <iinit>
    fileinit();      // file table
    80000fd6:	00003097          	auipc	ra,0x3
    80000fda:	4e8080e7          	jalr	1256(ra) # 800044be <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	e2a080e7          	jalr	-470(ra) # 80005e08 <virtio_disk_init>
    userinit();      // first user process
    80000fe6:	00001097          	auipc	ra,0x1
    80000fea:	d44080e7          	jalr	-700(ra) # 80001d2a <userinit>
    trap_and_emulate_init();
    80000fee:	00006097          	auipc	ra,0x6
    80000ff2:	172080e7          	jalr	370(ra) # 80007160 <trap_and_emulate_init>
    __sync_synchronize();
    80000ff6:	0ff0000f          	fence
    started = 1;
    80000ffa:	4785                	li	a5,1
    80000ffc:	00009717          	auipc	a4,0x9
    80001000:	c2f72623          	sw	a5,-980(a4) # 80009c28 <started>
    80001004:	bf2d                	j	80000f3e <main+0x56>

0000000080001006 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001006:	1141                	addi	sp,sp,-16
    80001008:	e422                	sd	s0,8(sp)
    8000100a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000100c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001010:	00009797          	auipc	a5,0x9
    80001014:	c207b783          	ld	a5,-992(a5) # 80009c30 <kernel_pagetable>
    80001018:	83b1                	srli	a5,a5,0xc
    8000101a:	577d                	li	a4,-1
    8000101c:	177e                	slli	a4,a4,0x3f
    8000101e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001020:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001024:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001028:	6422                	ld	s0,8(sp)
    8000102a:	0141                	addi	sp,sp,16
    8000102c:	8082                	ret

000000008000102e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000102e:	7139                	addi	sp,sp,-64
    80001030:	fc06                	sd	ra,56(sp)
    80001032:	f822                	sd	s0,48(sp)
    80001034:	f426                	sd	s1,40(sp)
    80001036:	f04a                	sd	s2,32(sp)
    80001038:	ec4e                	sd	s3,24(sp)
    8000103a:	e852                	sd	s4,16(sp)
    8000103c:	e456                	sd	s5,8(sp)
    8000103e:	e05a                	sd	s6,0(sp)
    80001040:	0080                	addi	s0,sp,64
    80001042:	84aa                	mv	s1,a0
    80001044:	89ae                	mv	s3,a1
    80001046:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001048:	57fd                	li	a5,-1
    8000104a:	83e9                	srli	a5,a5,0x1a
    8000104c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000104e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001050:	04b7f263          	bgeu	a5,a1,80001094 <walk+0x66>
    panic("walk");
    80001054:	00008517          	auipc	a0,0x8
    80001058:	07c50513          	addi	a0,a0,124 # 800090d0 <digits+0x90>
    8000105c:	fffff097          	auipc	ra,0xfffff
    80001060:	4e4080e7          	jalr	1252(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001064:	060a8663          	beqz	s5,800010d0 <walk+0xa2>
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	af0080e7          	jalr	-1296(ra) # 80000b58 <kalloc>
    80001070:	84aa                	mv	s1,a0
    80001072:	c529                	beqz	a0,800010bc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001074:	6605                	lui	a2,0x1
    80001076:	4581                	li	a1,0
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	ccc080e7          	jalr	-820(ra) # 80000d44 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001080:	00c4d793          	srli	a5,s1,0xc
    80001084:	07aa                	slli	a5,a5,0xa
    80001086:	0017e793          	ori	a5,a5,1
    8000108a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000108e:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdb5d7>
    80001090:	036a0063          	beq	s4,s6,800010b0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001094:	0149d933          	srl	s2,s3,s4
    80001098:	1ff97913          	andi	s2,s2,511
    8000109c:	090e                	slli	s2,s2,0x3
    8000109e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a0:	00093483          	ld	s1,0(s2)
    800010a4:	0014f793          	andi	a5,s1,1
    800010a8:	dfd5                	beqz	a5,80001064 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010aa:	80a9                	srli	s1,s1,0xa
    800010ac:	04b2                	slli	s1,s1,0xc
    800010ae:	b7c5                	j	8000108e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010b0:	00c9d513          	srli	a0,s3,0xc
    800010b4:	1ff57513          	andi	a0,a0,511
    800010b8:	050e                	slli	a0,a0,0x3
    800010ba:	9526                	add	a0,a0,s1
}
    800010bc:	70e2                	ld	ra,56(sp)
    800010be:	7442                	ld	s0,48(sp)
    800010c0:	74a2                	ld	s1,40(sp)
    800010c2:	7902                	ld	s2,32(sp)
    800010c4:	69e2                	ld	s3,24(sp)
    800010c6:	6a42                	ld	s4,16(sp)
    800010c8:	6aa2                	ld	s5,8(sp)
    800010ca:	6b02                	ld	s6,0(sp)
    800010cc:	6121                	addi	sp,sp,64
    800010ce:	8082                	ret
        return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7ed                	j	800010bc <walk+0x8e>

00000000800010d4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010d4:	57fd                	li	a5,-1
    800010d6:	83e9                	srli	a5,a5,0x1a
    800010d8:	00b7f463          	bgeu	a5,a1,800010e0 <walkaddr+0xc>
    return 0;
    800010dc:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010de:	8082                	ret
{
    800010e0:	1141                	addi	sp,sp,-16
    800010e2:	e406                	sd	ra,8(sp)
    800010e4:	e022                	sd	s0,0(sp)
    800010e6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010e8:	4601                	li	a2,0
    800010ea:	00000097          	auipc	ra,0x0
    800010ee:	f44080e7          	jalr	-188(ra) # 8000102e <walk>
  if(pte == 0)
    800010f2:	c105                	beqz	a0,80001112 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010f4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010f6:	0117f693          	andi	a3,a5,17
    800010fa:	4745                	li	a4,17
    return 0;
    800010fc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010fe:	00e68663          	beq	a3,a4,8000110a <walkaddr+0x36>
}
    80001102:	60a2                	ld	ra,8(sp)
    80001104:	6402                	ld	s0,0(sp)
    80001106:	0141                	addi	sp,sp,16
    80001108:	8082                	ret
  pa = PTE2PA(*pte);
    8000110a:	83a9                	srli	a5,a5,0xa
    8000110c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001110:	bfcd                	j	80001102 <walkaddr+0x2e>
    return 0;
    80001112:	4501                	li	a0,0
    80001114:	b7fd                	j	80001102 <walkaddr+0x2e>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	addi	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000112c:	c639                	beqz	a2,8000117a <mappages+0x64>
    8000112e:	8aaa                	mv	s5,a0
    80001130:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001132:	777d                	lui	a4,0xfffff
    80001134:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001138:	fff58993          	addi	s3,a1,-1
    8000113c:	99b2                	add	s3,s3,a2
    8000113e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001142:	893e                	mv	s2,a5
    80001144:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001148:	6b85                	lui	s7,0x1
    8000114a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114e:	4605                	li	a2,1
    80001150:	85ca                	mv	a1,s2
    80001152:	8556                	mv	a0,s5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	eda080e7          	jalr	-294(ra) # 8000102e <walk>
    8000115c:	cd1d                	beqz	a0,8000119a <mappages+0x84>
    if(*pte & PTE_V)
    8000115e:	611c                	ld	a5,0(a0)
    80001160:	8b85                	andi	a5,a5,1
    80001162:	e785                	bnez	a5,8000118a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001164:	80b1                	srli	s1,s1,0xc
    80001166:	04aa                	slli	s1,s1,0xa
    80001168:	0164e4b3          	or	s1,s1,s6
    8000116c:	0014e493          	ori	s1,s1,1
    80001170:	e104                	sd	s1,0(a0)
    if(a == last)
    80001172:	05390063          	beq	s2,s3,800011b2 <mappages+0x9c>
    a += PGSIZE;
    80001176:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001178:	bfc9                	j	8000114a <mappages+0x34>
    panic("mappages: size");
    8000117a:	00008517          	auipc	a0,0x8
    8000117e:	f5e50513          	addi	a0,a0,-162 # 800090d8 <digits+0x98>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3be080e7          	jalr	958(ra) # 80000540 <panic>
      panic("mappages: remap");
    8000118a:	00008517          	auipc	a0,0x8
    8000118e:	f5e50513          	addi	a0,a0,-162 # 800090e8 <digits+0xa8>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3ae080e7          	jalr	942(ra) # 80000540 <panic>
      return -1;
    8000119a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000119c:	60a6                	ld	ra,72(sp)
    8000119e:	6406                	ld	s0,64(sp)
    800011a0:	74e2                	ld	s1,56(sp)
    800011a2:	7942                	ld	s2,48(sp)
    800011a4:	79a2                	ld	s3,40(sp)
    800011a6:	7a02                	ld	s4,32(sp)
    800011a8:	6ae2                	ld	s5,24(sp)
    800011aa:	6b42                	ld	s6,16(sp)
    800011ac:	6ba2                	ld	s7,8(sp)
    800011ae:	6161                	addi	sp,sp,80
    800011b0:	8082                	ret
  return 0;
    800011b2:	4501                	li	a0,0
    800011b4:	b7e5                	j	8000119c <mappages+0x86>

00000000800011b6 <kvmmap>:
{
    800011b6:	1141                	addi	sp,sp,-16
    800011b8:	e406                	sd	ra,8(sp)
    800011ba:	e022                	sd	s0,0(sp)
    800011bc:	0800                	addi	s0,sp,16
    800011be:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011c0:	86b2                	mv	a3,a2
    800011c2:	863e                	mv	a2,a5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f52080e7          	jalr	-174(ra) # 80001116 <mappages>
    800011cc:	e509                	bnez	a0,800011d6 <kvmmap+0x20>
}
    800011ce:	60a2                	ld	ra,8(sp)
    800011d0:	6402                	ld	s0,0(sp)
    800011d2:	0141                	addi	sp,sp,16
    800011d4:	8082                	ret
    panic("kvmmap");
    800011d6:	00008517          	auipc	a0,0x8
    800011da:	f2250513          	addi	a0,a0,-222 # 800090f8 <digits+0xb8>
    800011de:	fffff097          	auipc	ra,0xfffff
    800011e2:	362080e7          	jalr	866(ra) # 80000540 <panic>

00000000800011e6 <kvmmake>:
{
    800011e6:	1101                	addi	sp,sp,-32
    800011e8:	ec06                	sd	ra,24(sp)
    800011ea:	e822                	sd	s0,16(sp)
    800011ec:	e426                	sd	s1,8(sp)
    800011ee:	e04a                	sd	s2,0(sp)
    800011f0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	966080e7          	jalr	-1690(ra) # 80000b58 <kalloc>
    800011fa:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011fc:	6605                	lui	a2,0x1
    800011fe:	4581                	li	a1,0
    80001200:	00000097          	auipc	ra,0x0
    80001204:	b44080e7          	jalr	-1212(ra) # 80000d44 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	6685                	lui	a3,0x1
    8000120c:	10000637          	lui	a2,0x10000
    80001210:	100005b7          	lui	a1,0x10000
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	fa0080e7          	jalr	-96(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000121e:	4719                	li	a4,6
    80001220:	6685                	lui	a3,0x1
    80001222:	10001637          	lui	a2,0x10001
    80001226:	100015b7          	lui	a1,0x10001
    8000122a:	8526                	mv	a0,s1
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f8a080e7          	jalr	-118(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001234:	4719                	li	a4,6
    80001236:	004006b7          	lui	a3,0x400
    8000123a:	0c000637          	lui	a2,0xc000
    8000123e:	0c0005b7          	lui	a1,0xc000
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f72080e7          	jalr	-142(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000124c:	00008917          	auipc	s2,0x8
    80001250:	db490913          	addi	s2,s2,-588 # 80009000 <etext>
    80001254:	4729                	li	a4,10
    80001256:	80008697          	auipc	a3,0x80008
    8000125a:	daa68693          	addi	a3,a3,-598 # 9000 <_entry-0x7fff7000>
    8000125e:	4605                	li	a2,1
    80001260:	067e                	slli	a2,a2,0x1f
    80001262:	85b2                	mv	a1,a2
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f50080e7          	jalr	-176(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000126e:	4719                	li	a4,6
    80001270:	46c5                	li	a3,17
    80001272:	06ee                	slli	a3,a3,0x1b
    80001274:	412686b3          	sub	a3,a3,s2
    80001278:	864a                	mv	a2,s2
    8000127a:	85ca                	mv	a1,s2
    8000127c:	8526                	mv	a0,s1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f38080e7          	jalr	-200(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001286:	4729                	li	a4,10
    80001288:	6685                	lui	a3,0x1
    8000128a:	00007617          	auipc	a2,0x7
    8000128e:	d7660613          	addi	a2,a2,-650 # 80008000 <_trampoline>
    80001292:	040005b7          	lui	a1,0x4000
    80001296:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001298:	05b2                	slli	a1,a1,0xc
    8000129a:	8526                	mv	a0,s1
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f1a080e7          	jalr	-230(ra) # 800011b6 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012a4:	8526                	mv	a0,s1
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	608080e7          	jalr	1544(ra) # 800018ae <proc_mapstacks>
}
    800012ae:	8526                	mv	a0,s1
    800012b0:	60e2                	ld	ra,24(sp)
    800012b2:	6442                	ld	s0,16(sp)
    800012b4:	64a2                	ld	s1,8(sp)
    800012b6:	6902                	ld	s2,0(sp)
    800012b8:	6105                	addi	sp,sp,32
    800012ba:	8082                	ret

00000000800012bc <kvminit>:
{
    800012bc:	1141                	addi	sp,sp,-16
    800012be:	e406                	sd	ra,8(sp)
    800012c0:	e022                	sd	s0,0(sp)
    800012c2:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f22080e7          	jalr	-222(ra) # 800011e6 <kvmmake>
    800012cc:	00009797          	auipc	a5,0x9
    800012d0:	96a7b223          	sd	a0,-1692(a5) # 80009c30 <kernel_pagetable>
}
    800012d4:	60a2                	ld	ra,8(sp)
    800012d6:	6402                	ld	s0,0(sp)
    800012d8:	0141                	addi	sp,sp,16
    800012da:	8082                	ret

00000000800012dc <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012dc:	715d                	addi	sp,sp,-80
    800012de:	e486                	sd	ra,72(sp)
    800012e0:	e0a2                	sd	s0,64(sp)
    800012e2:	fc26                	sd	s1,56(sp)
    800012e4:	f84a                	sd	s2,48(sp)
    800012e6:	f44e                	sd	s3,40(sp)
    800012e8:	f052                	sd	s4,32(sp)
    800012ea:	ec56                	sd	s5,24(sp)
    800012ec:	e85a                	sd	s6,16(sp)
    800012ee:	e45e                	sd	s7,8(sp)
    800012f0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012f2:	03459793          	slli	a5,a1,0x34
    800012f6:	e795                	bnez	a5,80001322 <uvmunmap+0x46>
    800012f8:	8a2a                	mv	s4,a0
    800012fa:	892e                	mv	s2,a1
    800012fc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fe:	0632                	slli	a2,a2,0xc
    80001300:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001306:	6b05                	lui	s6,0x1
    80001308:	0735e263          	bltu	a1,s3,8000136c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000130c:	60a6                	ld	ra,72(sp)
    8000130e:	6406                	ld	s0,64(sp)
    80001310:	74e2                	ld	s1,56(sp)
    80001312:	7942                	ld	s2,48(sp)
    80001314:	79a2                	ld	s3,40(sp)
    80001316:	7a02                	ld	s4,32(sp)
    80001318:	6ae2                	ld	s5,24(sp)
    8000131a:	6b42                	ld	s6,16(sp)
    8000131c:	6ba2                	ld	s7,8(sp)
    8000131e:	6161                	addi	sp,sp,80
    80001320:	8082                	ret
    panic("uvmunmap: not aligned");
    80001322:	00008517          	auipc	a0,0x8
    80001326:	dde50513          	addi	a0,a0,-546 # 80009100 <digits+0xc0>
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	216080e7          	jalr	534(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001332:	00008517          	auipc	a0,0x8
    80001336:	de650513          	addi	a0,a0,-538 # 80009118 <digits+0xd8>
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	206080e7          	jalr	518(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001342:	00008517          	auipc	a0,0x8
    80001346:	de650513          	addi	a0,a0,-538 # 80009128 <digits+0xe8>
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001352:	00008517          	auipc	a0,0x8
    80001356:	dee50513          	addi	a0,a0,-530 # 80009140 <digits+0x100>
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>
    *pte = 0;
    80001362:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001366:	995a                	add	s2,s2,s6
    80001368:	fb3972e3          	bgeu	s2,s3,8000130c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000136c:	4601                	li	a2,0
    8000136e:	85ca                	mv	a1,s2
    80001370:	8552                	mv	a0,s4
    80001372:	00000097          	auipc	ra,0x0
    80001376:	cbc080e7          	jalr	-836(ra) # 8000102e <walk>
    8000137a:	84aa                	mv	s1,a0
    8000137c:	d95d                	beqz	a0,80001332 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000137e:	6108                	ld	a0,0(a0)
    80001380:	00157793          	andi	a5,a0,1
    80001384:	dfdd                	beqz	a5,80001342 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001386:	3ff57793          	andi	a5,a0,1023
    8000138a:	fd7784e3          	beq	a5,s7,80001352 <uvmunmap+0x76>
    if(do_free){
    8000138e:	fc0a8ae3          	beqz	s5,80001362 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001392:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001394:	0532                	slli	a0,a0,0xc
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	6c4080e7          	jalr	1732(ra) # 80000a5a <kfree>
    8000139e:	b7d1                	j	80001362 <uvmunmap+0x86>

00000000800013a0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013a0:	1101                	addi	sp,sp,-32
    800013a2:	ec06                	sd	ra,24(sp)
    800013a4:	e822                	sd	s0,16(sp)
    800013a6:	e426                	sd	s1,8(sp)
    800013a8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	7ae080e7          	jalr	1966(ra) # 80000b58 <kalloc>
    800013b2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013b4:	c519                	beqz	a0,800013c2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b6:	6605                	lui	a2,0x1
    800013b8:	4581                	li	a1,0
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	98a080e7          	jalr	-1654(ra) # 80000d44 <memset>
  return pagetable;
}
    800013c2:	8526                	mv	a0,s1
    800013c4:	60e2                	ld	ra,24(sp)
    800013c6:	6442                	ld	s0,16(sp)
    800013c8:	64a2                	ld	s1,8(sp)
    800013ca:	6105                	addi	sp,sp,32
    800013cc:	8082                	ret

00000000800013ce <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ce:	7179                	addi	sp,sp,-48
    800013d0:	f406                	sd	ra,40(sp)
    800013d2:	f022                	sd	s0,32(sp)
    800013d4:	ec26                	sd	s1,24(sp)
    800013d6:	e84a                	sd	s2,16(sp)
    800013d8:	e44e                	sd	s3,8(sp)
    800013da:	e052                	sd	s4,0(sp)
    800013dc:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013de:	6785                	lui	a5,0x1
    800013e0:	04f67863          	bgeu	a2,a5,80001430 <uvmfirst+0x62>
    800013e4:	8a2a                	mv	s4,a0
    800013e6:	89ae                	mv	s3,a1
    800013e8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	76e080e7          	jalr	1902(ra) # 80000b58 <kalloc>
    800013f2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013f4:	6605                	lui	a2,0x1
    800013f6:	4581                	li	a1,0
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	94c080e7          	jalr	-1716(ra) # 80000d44 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001400:	4779                	li	a4,30
    80001402:	86ca                	mv	a3,s2
    80001404:	6605                	lui	a2,0x1
    80001406:	4581                	li	a1,0
    80001408:	8552                	mv	a0,s4
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	d0c080e7          	jalr	-756(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    80001412:	8626                	mv	a2,s1
    80001414:	85ce                	mv	a1,s3
    80001416:	854a                	mv	a0,s2
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	988080e7          	jalr	-1656(ra) # 80000da0 <memmove>
}
    80001420:	70a2                	ld	ra,40(sp)
    80001422:	7402                	ld	s0,32(sp)
    80001424:	64e2                	ld	s1,24(sp)
    80001426:	6942                	ld	s2,16(sp)
    80001428:	69a2                	ld	s3,8(sp)
    8000142a:	6a02                	ld	s4,0(sp)
    8000142c:	6145                	addi	sp,sp,48
    8000142e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001430:	00008517          	auipc	a0,0x8
    80001434:	d2850513          	addi	a0,a0,-728 # 80009158 <digits+0x118>
    80001438:	fffff097          	auipc	ra,0xfffff
    8000143c:	108080e7          	jalr	264(ra) # 80000540 <panic>

0000000080001440 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001440:	1101                	addi	sp,sp,-32
    80001442:	ec06                	sd	ra,24(sp)
    80001444:	e822                	sd	s0,16(sp)
    80001446:	e426                	sd	s1,8(sp)
    80001448:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000144a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000144c:	00b67d63          	bgeu	a2,a1,80001466 <uvmdealloc+0x26>
    80001450:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001452:	6785                	lui	a5,0x1
    80001454:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001456:	00f60733          	add	a4,a2,a5
    8000145a:	76fd                	lui	a3,0xfffff
    8000145c:	8f75                	and	a4,a4,a3
    8000145e:	97ae                	add	a5,a5,a1
    80001460:	8ff5                	and	a5,a5,a3
    80001462:	00f76863          	bltu	a4,a5,80001472 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001466:	8526                	mv	a0,s1
    80001468:	60e2                	ld	ra,24(sp)
    8000146a:	6442                	ld	s0,16(sp)
    8000146c:	64a2                	ld	s1,8(sp)
    8000146e:	6105                	addi	sp,sp,32
    80001470:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001472:	8f99                	sub	a5,a5,a4
    80001474:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001476:	4685                	li	a3,1
    80001478:	0007861b          	sext.w	a2,a5
    8000147c:	85ba                	mv	a1,a4
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	e5e080e7          	jalr	-418(ra) # 800012dc <uvmunmap>
    80001486:	b7c5                	j	80001466 <uvmdealloc+0x26>

0000000080001488 <uvmalloc>:
  if(newsz < oldsz)
    80001488:	0ab66563          	bltu	a2,a1,80001532 <uvmalloc+0xaa>
{
    8000148c:	7139                	addi	sp,sp,-64
    8000148e:	fc06                	sd	ra,56(sp)
    80001490:	f822                	sd	s0,48(sp)
    80001492:	f426                	sd	s1,40(sp)
    80001494:	f04a                	sd	s2,32(sp)
    80001496:	ec4e                	sd	s3,24(sp)
    80001498:	e852                	sd	s4,16(sp)
    8000149a:	e456                	sd	s5,8(sp)
    8000149c:	e05a                	sd	s6,0(sp)
    8000149e:	0080                	addi	s0,sp,64
    800014a0:	8aaa                	mv	s5,a0
    800014a2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014a4:	6785                	lui	a5,0x1
    800014a6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014a8:	95be                	add	a1,a1,a5
    800014aa:	77fd                	lui	a5,0xfffff
    800014ac:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b0:	08c9f363          	bgeu	s3,a2,80001536 <uvmalloc+0xae>
    800014b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014b6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	69e080e7          	jalr	1694(ra) # 80000b58 <kalloc>
    800014c2:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c4:	c51d                	beqz	a0,800014f2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014c6:	6605                	lui	a2,0x1
    800014c8:	4581                	li	a1,0
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	87a080e7          	jalr	-1926(ra) # 80000d44 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014d2:	875a                	mv	a4,s6
    800014d4:	86a6                	mv	a3,s1
    800014d6:	6605                	lui	a2,0x1
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	c3a080e7          	jalr	-966(ra) # 80001116 <mappages>
    800014e4:	e90d                	bnez	a0,80001516 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e6:	6785                	lui	a5,0x1
    800014e8:	993e                	add	s2,s2,a5
    800014ea:	fd4968e3          	bltu	s2,s4,800014ba <uvmalloc+0x32>
  return newsz;
    800014ee:	8552                	mv	a0,s4
    800014f0:	a809                	j	80001502 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014f2:	864e                	mv	a2,s3
    800014f4:	85ca                	mv	a1,s2
    800014f6:	8556                	mv	a0,s5
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	f48080e7          	jalr	-184(ra) # 80001440 <uvmdealloc>
      return 0;
    80001500:	4501                	li	a0,0
}
    80001502:	70e2                	ld	ra,56(sp)
    80001504:	7442                	ld	s0,48(sp)
    80001506:	74a2                	ld	s1,40(sp)
    80001508:	7902                	ld	s2,32(sp)
    8000150a:	69e2                	ld	s3,24(sp)
    8000150c:	6a42                	ld	s4,16(sp)
    8000150e:	6aa2                	ld	s5,8(sp)
    80001510:	6b02                	ld	s6,0(sp)
    80001512:	6121                	addi	sp,sp,64
    80001514:	8082                	ret
      kfree(mem);
    80001516:	8526                	mv	a0,s1
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	542080e7          	jalr	1346(ra) # 80000a5a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001520:	864e                	mv	a2,s3
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	f1a080e7          	jalr	-230(ra) # 80001440 <uvmdealloc>
      return 0;
    8000152e:	4501                	li	a0,0
    80001530:	bfc9                	j	80001502 <uvmalloc+0x7a>
    return oldsz;
    80001532:	852e                	mv	a0,a1
}
    80001534:	8082                	ret
  return newsz;
    80001536:	8532                	mv	a0,a2
    80001538:	b7e9                	j	80001502 <uvmalloc+0x7a>

000000008000153a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153a:	7179                	addi	sp,sp,-48
    8000153c:	f406                	sd	ra,40(sp)
    8000153e:	f022                	sd	s0,32(sp)
    80001540:	ec26                	sd	s1,24(sp)
    80001542:	e84a                	sd	s2,16(sp)
    80001544:	e44e                	sd	s3,8(sp)
    80001546:	e052                	sd	s4,0(sp)
    80001548:	1800                	addi	s0,sp,48
    8000154a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154c:	84aa                	mv	s1,a0
    8000154e:	6905                	lui	s2,0x1
    80001550:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001552:	4985                	li	s3,1
    80001554:	a829                	j	8000156e <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001556:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001558:	00c79513          	slli	a0,a5,0xc
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	fde080e7          	jalr	-34(ra) # 8000153a <freewalk>
      pagetable[i] = 0;
    80001564:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001568:	04a1                	addi	s1,s1,8
    8000156a:	03248163          	beq	s1,s2,8000158c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000156e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001570:	00f7f713          	andi	a4,a5,15
    80001574:	ff3701e3          	beq	a4,s3,80001556 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001578:	8b85                	andi	a5,a5,1
    8000157a:	d7fd                	beqz	a5,80001568 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000157c:	00008517          	auipc	a0,0x8
    80001580:	bfc50513          	addi	a0,a0,-1028 # 80009178 <digits+0x138>
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	fbc080e7          	jalr	-68(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158c:	8552                	mv	a0,s4
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	4cc080e7          	jalr	1228(ra) # 80000a5a <kfree>
}
    80001596:	70a2                	ld	ra,40(sp)
    80001598:	7402                	ld	s0,32(sp)
    8000159a:	64e2                	ld	s1,24(sp)
    8000159c:	6942                	ld	s2,16(sp)
    8000159e:	69a2                	ld	s3,8(sp)
    800015a0:	6a02                	ld	s4,0(sp)
    800015a2:	6145                	addi	sp,sp,48
    800015a4:	8082                	ret

00000000800015a6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a6:	1101                	addi	sp,sp,-32
    800015a8:	ec06                	sd	ra,24(sp)
    800015aa:	e822                	sd	s0,16(sp)
    800015ac:	e426                	sd	s1,8(sp)
    800015ae:	1000                	addi	s0,sp,32
    800015b0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b2:	e999                	bnez	a1,800015c8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b4:	8526                	mv	a0,s1
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f84080e7          	jalr	-124(ra) # 8000153a <freewalk>
}
    800015be:	60e2                	ld	ra,24(sp)
    800015c0:	6442                	ld	s0,16(sp)
    800015c2:	64a2                	ld	s1,8(sp)
    800015c4:	6105                	addi	sp,sp,32
    800015c6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c8:	6785                	lui	a5,0x1
    800015ca:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015cc:	95be                	add	a1,a1,a5
    800015ce:	4685                	li	a3,1
    800015d0:	00c5d613          	srli	a2,a1,0xc
    800015d4:	4581                	li	a1,0
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	d06080e7          	jalr	-762(ra) # 800012dc <uvmunmap>
    800015de:	bfd9                	j	800015b4 <uvmfree+0xe>

00000000800015e0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015e0:	c679                	beqz	a2,800016ae <uvmcopy+0xce>
{
    800015e2:	715d                	addi	sp,sp,-80
    800015e4:	e486                	sd	ra,72(sp)
    800015e6:	e0a2                	sd	s0,64(sp)
    800015e8:	fc26                	sd	s1,56(sp)
    800015ea:	f84a                	sd	s2,48(sp)
    800015ec:	f44e                	sd	s3,40(sp)
    800015ee:	f052                	sd	s4,32(sp)
    800015f0:	ec56                	sd	s5,24(sp)
    800015f2:	e85a                	sd	s6,16(sp)
    800015f4:	e45e                	sd	s7,8(sp)
    800015f6:	0880                	addi	s0,sp,80
    800015f8:	8b2a                	mv	s6,a0
    800015fa:	8aae                	mv	s5,a1
    800015fc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fe:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001600:	4601                	li	a2,0
    80001602:	85ce                	mv	a1,s3
    80001604:	855a                	mv	a0,s6
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	a28080e7          	jalr	-1496(ra) # 8000102e <walk>
    8000160e:	c531                	beqz	a0,8000165a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001610:	6118                	ld	a4,0(a0)
    80001612:	00177793          	andi	a5,a4,1
    80001616:	cbb1                	beqz	a5,8000166a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001618:	00a75593          	srli	a1,a4,0xa
    8000161c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001620:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	534080e7          	jalr	1332(ra) # 80000b58 <kalloc>
    8000162c:	892a                	mv	s2,a0
    8000162e:	c939                	beqz	a0,80001684 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001630:	6605                	lui	a2,0x1
    80001632:	85de                	mv	a1,s7
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	76c080e7          	jalr	1900(ra) # 80000da0 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163c:	8726                	mv	a4,s1
    8000163e:	86ca                	mv	a3,s2
    80001640:	6605                	lui	a2,0x1
    80001642:	85ce                	mv	a1,s3
    80001644:	8556                	mv	a0,s5
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	ad0080e7          	jalr	-1328(ra) # 80001116 <mappages>
    8000164e:	e515                	bnez	a0,8000167a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001650:	6785                	lui	a5,0x1
    80001652:	99be                	add	s3,s3,a5
    80001654:	fb49e6e3          	bltu	s3,s4,80001600 <uvmcopy+0x20>
    80001658:	a081                	j	80001698 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000165a:	00008517          	auipc	a0,0x8
    8000165e:	b2e50513          	addi	a0,a0,-1234 # 80009188 <digits+0x148>
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	ede080e7          	jalr	-290(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000166a:	00008517          	auipc	a0,0x8
    8000166e:	b3e50513          	addi	a0,a0,-1218 # 800091a8 <digits+0x168>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ece080e7          	jalr	-306(ra) # 80000540 <panic>
      kfree(mem);
    8000167a:	854a                	mv	a0,s2
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	3de080e7          	jalr	990(ra) # 80000a5a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001684:	4685                	li	a3,1
    80001686:	00c9d613          	srli	a2,s3,0xc
    8000168a:	4581                	li	a1,0
    8000168c:	8556                	mv	a0,s5
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	c4e080e7          	jalr	-946(ra) # 800012dc <uvmunmap>
  return -1;
    80001696:	557d                	li	a0,-1
}
    80001698:	60a6                	ld	ra,72(sp)
    8000169a:	6406                	ld	s0,64(sp)
    8000169c:	74e2                	ld	s1,56(sp)
    8000169e:	7942                	ld	s2,48(sp)
    800016a0:	79a2                	ld	s3,40(sp)
    800016a2:	7a02                	ld	s4,32(sp)
    800016a4:	6ae2                	ld	s5,24(sp)
    800016a6:	6b42                	ld	s6,16(sp)
    800016a8:	6ba2                	ld	s7,8(sp)
    800016aa:	6161                	addi	sp,sp,80
    800016ac:	8082                	ret
  return 0;
    800016ae:	4501                	li	a0,0
}
    800016b0:	8082                	ret

00000000800016b2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b2:	1141                	addi	sp,sp,-16
    800016b4:	e406                	sd	ra,8(sp)
    800016b6:	e022                	sd	s0,0(sp)
    800016b8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016ba:	4601                	li	a2,0
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	972080e7          	jalr	-1678(ra) # 8000102e <walk>
  if(pte == 0)
    800016c4:	c901                	beqz	a0,800016d4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c6:	611c                	ld	a5,0(a0)
    800016c8:	9bbd                	andi	a5,a5,-17
    800016ca:	e11c                	sd	a5,0(a0)
}
    800016cc:	60a2                	ld	ra,8(sp)
    800016ce:	6402                	ld	s0,0(sp)
    800016d0:	0141                	addi	sp,sp,16
    800016d2:	8082                	ret
    panic("uvmclear");
    800016d4:	00008517          	auipc	a0,0x8
    800016d8:	af450513          	addi	a0,a0,-1292 # 800091c8 <digits+0x188>
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	e64080e7          	jalr	-412(ra) # 80000540 <panic>

00000000800016e4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e4:	c6bd                	beqz	a3,80001752 <copyout+0x6e>
{
    800016e6:	715d                	addi	sp,sp,-80
    800016e8:	e486                	sd	ra,72(sp)
    800016ea:	e0a2                	sd	s0,64(sp)
    800016ec:	fc26                	sd	s1,56(sp)
    800016ee:	f84a                	sd	s2,48(sp)
    800016f0:	f44e                	sd	s3,40(sp)
    800016f2:	f052                	sd	s4,32(sp)
    800016f4:	ec56                	sd	s5,24(sp)
    800016f6:	e85a                	sd	s6,16(sp)
    800016f8:	e45e                	sd	s7,8(sp)
    800016fa:	e062                	sd	s8,0(sp)
    800016fc:	0880                	addi	s0,sp,80
    800016fe:	8b2a                	mv	s6,a0
    80001700:	8c2e                	mv	s8,a1
    80001702:	8a32                	mv	s4,a2
    80001704:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001706:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001708:	6a85                	lui	s5,0x1
    8000170a:	a015                	j	8000172e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170c:	9562                	add	a0,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	85d2                	mv	a1,s4
    80001714:	41250533          	sub	a0,a0,s2
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	688080e7          	jalr	1672(ra) # 80000da0 <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    src += n;
    80001724:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	99e080e7          	jalr	-1634(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    80001746:	fc99f3e3          	bgeu	s3,s1,8000170c <copyout+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	b7c1                	j	8000170c <copyout+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyout+0x74>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001770:	caa5                	beqz	a3,800017e0 <copyin+0x70>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	e062                	sd	s8,0(sp)
    80001788:	0880                	addi	s0,sp,80
    8000178a:	8b2a                	mv	s6,a0
    8000178c:	8a2e                	mv	s4,a1
    8000178e:	8c32                	mv	s8,a2
    80001790:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001792:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001794:	6a85                	lui	s5,0x1
    80001796:	a01d                	j	800017bc <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001798:	018505b3          	add	a1,a0,s8
    8000179c:	0004861b          	sext.w	a2,s1
    800017a0:	412585b3          	sub	a1,a1,s2
    800017a4:	8552                	mv	a0,s4
    800017a6:	fffff097          	auipc	ra,0xfffff
    800017aa:	5fa080e7          	jalr	1530(ra) # 80000da0 <memmove>

    len -= n;
    800017ae:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017b2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b8:	02098263          	beqz	s3,800017dc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017c0:	85ca                	mv	a1,s2
    800017c2:	855a                	mv	a0,s6
    800017c4:	00000097          	auipc	ra,0x0
    800017c8:	910080e7          	jalr	-1776(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    800017cc:	cd01                	beqz	a0,800017e4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ce:	418904b3          	sub	s1,s2,s8
    800017d2:	94d6                	add	s1,s1,s5
    800017d4:	fc99f2e3          	bgeu	s3,s1,80001798 <copyin+0x28>
    800017d8:	84ce                	mv	s1,s3
    800017da:	bf7d                	j	80001798 <copyin+0x28>
  }
  return 0;
    800017dc:	4501                	li	a0,0
    800017de:	a021                	j	800017e6 <copyin+0x76>
    800017e0:	4501                	li	a0,0
}
    800017e2:	8082                	ret
      return -1;
    800017e4:	557d                	li	a0,-1
}
    800017e6:	60a6                	ld	ra,72(sp)
    800017e8:	6406                	ld	s0,64(sp)
    800017ea:	74e2                	ld	s1,56(sp)
    800017ec:	7942                	ld	s2,48(sp)
    800017ee:	79a2                	ld	s3,40(sp)
    800017f0:	7a02                	ld	s4,32(sp)
    800017f2:	6ae2                	ld	s5,24(sp)
    800017f4:	6b42                	ld	s6,16(sp)
    800017f6:	6ba2                	ld	s7,8(sp)
    800017f8:	6c02                	ld	s8,0(sp)
    800017fa:	6161                	addi	sp,sp,80
    800017fc:	8082                	ret

00000000800017fe <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017fe:	c2dd                	beqz	a3,800018a4 <copyinstr+0xa6>
{
    80001800:	715d                	addi	sp,sp,-80
    80001802:	e486                	sd	ra,72(sp)
    80001804:	e0a2                	sd	s0,64(sp)
    80001806:	fc26                	sd	s1,56(sp)
    80001808:	f84a                	sd	s2,48(sp)
    8000180a:	f44e                	sd	s3,40(sp)
    8000180c:	f052                	sd	s4,32(sp)
    8000180e:	ec56                	sd	s5,24(sp)
    80001810:	e85a                	sd	s6,16(sp)
    80001812:	e45e                	sd	s7,8(sp)
    80001814:	0880                	addi	s0,sp,80
    80001816:	8a2a                	mv	s4,a0
    80001818:	8b2e                	mv	s6,a1
    8000181a:	8bb2                	mv	s7,a2
    8000181c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000181e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001820:	6985                	lui	s3,0x1
    80001822:	a02d                	j	8000184c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001824:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001828:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000182a:	37fd                	addiw	a5,a5,-1
    8000182c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001830:	60a6                	ld	ra,72(sp)
    80001832:	6406                	ld	s0,64(sp)
    80001834:	74e2                	ld	s1,56(sp)
    80001836:	7942                	ld	s2,48(sp)
    80001838:	79a2                	ld	s3,40(sp)
    8000183a:	7a02                	ld	s4,32(sp)
    8000183c:	6ae2                	ld	s5,24(sp)
    8000183e:	6b42                	ld	s6,16(sp)
    80001840:	6ba2                	ld	s7,8(sp)
    80001842:	6161                	addi	sp,sp,80
    80001844:	8082                	ret
    srcva = va0 + PGSIZE;
    80001846:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000184a:	c8a9                	beqz	s1,8000189c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000184c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001850:	85ca                	mv	a1,s2
    80001852:	8552                	mv	a0,s4
    80001854:	00000097          	auipc	ra,0x0
    80001858:	880080e7          	jalr	-1920(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000185c:	c131                	beqz	a0,800018a0 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000185e:	417906b3          	sub	a3,s2,s7
    80001862:	96ce                	add	a3,a3,s3
    80001864:	00d4f363          	bgeu	s1,a3,8000186a <copyinstr+0x6c>
    80001868:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000186a:	955e                	add	a0,a0,s7
    8000186c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001870:	daf9                	beqz	a3,80001846 <copyinstr+0x48>
    80001872:	87da                	mv	a5,s6
    80001874:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001876:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000187a:	96da                	add	a3,a3,s6
    8000187c:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000187e:	00f60733          	add	a4,a2,a5
    80001882:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdb5e0>
    80001886:	df59                	beqz	a4,80001824 <copyinstr+0x26>
        *dst = *p;
    80001888:	00e78023          	sb	a4,0(a5)
      dst++;
    8000188c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000188e:	fed797e3          	bne	a5,a3,8000187c <copyinstr+0x7e>
    80001892:	14fd                	addi	s1,s1,-1
    80001894:	94c2                	add	s1,s1,a6
      --max;
    80001896:	8c8d                	sub	s1,s1,a1
      dst++;
    80001898:	8b3e                	mv	s6,a5
    8000189a:	b775                	j	80001846 <copyinstr+0x48>
    8000189c:	4781                	li	a5,0
    8000189e:	b771                	j	8000182a <copyinstr+0x2c>
      return -1;
    800018a0:	557d                	li	a0,-1
    800018a2:	b779                	j	80001830 <copyinstr+0x32>
  int got_null = 0;
    800018a4:	4781                	li	a5,0
  if(got_null){
    800018a6:	37fd                	addiw	a5,a5,-1
    800018a8:	0007851b          	sext.w	a0,a5
}
    800018ac:	8082                	ret

00000000800018ae <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800018ae:	7139                	addi	sp,sp,-64
    800018b0:	fc06                	sd	ra,56(sp)
    800018b2:	f822                	sd	s0,48(sp)
    800018b4:	f426                	sd	s1,40(sp)
    800018b6:	f04a                	sd	s2,32(sp)
    800018b8:	ec4e                	sd	s3,24(sp)
    800018ba:	e852                	sd	s4,16(sp)
    800018bc:	e456                	sd	s5,8(sp)
    800018be:	e05a                	sd	s6,0(sp)
    800018c0:	0080                	addi	s0,sp,64
    800018c2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c4:	00011497          	auipc	s1,0x11
    800018c8:	a1c48493          	addi	s1,s1,-1508 # 800122e0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018cc:	8b26                	mv	s6,s1
    800018ce:	00007a97          	auipc	s5,0x7
    800018d2:	732a8a93          	addi	s5,s5,1842 # 80009000 <etext>
    800018d6:	04000937          	lui	s2,0x4000
    800018da:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018dc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018de:	00016a17          	auipc	s4,0x16
    800018e2:	602a0a13          	addi	s4,s4,1538 # 80017ee0 <tickslock>
    char *pa = kalloc();
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	272080e7          	jalr	626(ra) # 80000b58 <kalloc>
    800018ee:	862a                	mv	a2,a0
    if(pa == 0)
    800018f0:	c131                	beqz	a0,80001934 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018f2:	416485b3          	sub	a1,s1,s6
    800018f6:	8591                	srai	a1,a1,0x4
    800018f8:	000ab783          	ld	a5,0(s5)
    800018fc:	02f585b3          	mul	a1,a1,a5
    80001900:	2585                	addiw	a1,a1,1
    80001902:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001906:	4719                	li	a4,6
    80001908:	6685                	lui	a3,0x1
    8000190a:	40b905b3          	sub	a1,s2,a1
    8000190e:	854e                	mv	a0,s3
    80001910:	00000097          	auipc	ra,0x0
    80001914:	8a6080e7          	jalr	-1882(ra) # 800011b6 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	17048493          	addi	s1,s1,368
    8000191c:	fd4495e3          	bne	s1,s4,800018e6 <proc_mapstacks+0x38>
  }
}
    80001920:	70e2                	ld	ra,56(sp)
    80001922:	7442                	ld	s0,48(sp)
    80001924:	74a2                	ld	s1,40(sp)
    80001926:	7902                	ld	s2,32(sp)
    80001928:	69e2                	ld	s3,24(sp)
    8000192a:	6a42                	ld	s4,16(sp)
    8000192c:	6aa2                	ld	s5,8(sp)
    8000192e:	6b02                	ld	s6,0(sp)
    80001930:	6121                	addi	sp,sp,64
    80001932:	8082                	ret
      panic("kalloc");
    80001934:	00008517          	auipc	a0,0x8
    80001938:	8a450513          	addi	a0,a0,-1884 # 800091d8 <digits+0x198>
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	c04080e7          	jalr	-1020(ra) # 80000540 <panic>

0000000080001944 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001944:	7139                	addi	sp,sp,-64
    80001946:	fc06                	sd	ra,56(sp)
    80001948:	f822                	sd	s0,48(sp)
    8000194a:	f426                	sd	s1,40(sp)
    8000194c:	f04a                	sd	s2,32(sp)
    8000194e:	ec4e                	sd	s3,24(sp)
    80001950:	e852                	sd	s4,16(sp)
    80001952:	e456                	sd	s5,8(sp)
    80001954:	e05a                	sd	s6,0(sp)
    80001956:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001958:	00008597          	auipc	a1,0x8
    8000195c:	88858593          	addi	a1,a1,-1912 # 800091e0 <digits+0x1a0>
    80001960:	00010517          	auipc	a0,0x10
    80001964:	55050513          	addi	a0,a0,1360 # 80011eb0 <pid_lock>
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	250080e7          	jalr	592(ra) # 80000bb8 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001970:	00008597          	auipc	a1,0x8
    80001974:	87858593          	addi	a1,a1,-1928 # 800091e8 <digits+0x1a8>
    80001978:	00010517          	auipc	a0,0x10
    8000197c:	55050513          	addi	a0,a0,1360 # 80011ec8 <wait_lock>
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	238080e7          	jalr	568(ra) # 80000bb8 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001988:	00011497          	auipc	s1,0x11
    8000198c:	95848493          	addi	s1,s1,-1704 # 800122e0 <proc>
      initlock(&p->lock, "proc");
    80001990:	00008b17          	auipc	s6,0x8
    80001994:	868b0b13          	addi	s6,s6,-1944 # 800091f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001998:	8aa6                	mv	s5,s1
    8000199a:	00007a17          	auipc	s4,0x7
    8000199e:	666a0a13          	addi	s4,s4,1638 # 80009000 <etext>
    800019a2:	04000937          	lui	s2,0x4000
    800019a6:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019a8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019aa:	00016997          	auipc	s3,0x16
    800019ae:	53698993          	addi	s3,s3,1334 # 80017ee0 <tickslock>
      initlock(&p->lock, "proc");
    800019b2:	85da                	mv	a1,s6
    800019b4:	8526                	mv	a0,s1
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	202080e7          	jalr	514(ra) # 80000bb8 <initlock>
      p->state = UNUSED;
    800019be:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800019c2:	415487b3          	sub	a5,s1,s5
    800019c6:	8791                	srai	a5,a5,0x4
    800019c8:	000a3703          	ld	a4,0(s4)
    800019cc:	02e787b3          	mul	a5,a5,a4
    800019d0:	2785                	addiw	a5,a5,1
    800019d2:	00d7979b          	slliw	a5,a5,0xd
    800019d6:	40f907b3          	sub	a5,s2,a5
    800019da:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019dc:	17048493          	addi	s1,s1,368
    800019e0:	fd3499e3          	bne	s1,s3,800019b2 <procinit+0x6e>
  }
}
    800019e4:	70e2                	ld	ra,56(sp)
    800019e6:	7442                	ld	s0,48(sp)
    800019e8:	74a2                	ld	s1,40(sp)
    800019ea:	7902                	ld	s2,32(sp)
    800019ec:	69e2                	ld	s3,24(sp)
    800019ee:	6a42                	ld	s4,16(sp)
    800019f0:	6aa2                	ld	s5,8(sp)
    800019f2:	6b02                	ld	s6,0(sp)
    800019f4:	6121                	addi	sp,sp,64
    800019f6:	8082                	ret

00000000800019f8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019f8:	1141                	addi	sp,sp,-16
    800019fa:	e422                	sd	s0,8(sp)
    800019fc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019fe:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a00:	2501                	sext.w	a0,a0
    80001a02:	6422                	ld	s0,8(sp)
    80001a04:	0141                	addi	sp,sp,16
    80001a06:	8082                	ret

0000000080001a08 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a08:	1141                	addi	sp,sp,-16
    80001a0a:	e422                	sd	s0,8(sp)
    80001a0c:	0800                	addi	s0,sp,16
    80001a0e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a10:	2781                	sext.w	a5,a5
    80001a12:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a14:	00010517          	auipc	a0,0x10
    80001a18:	4cc50513          	addi	a0,a0,1228 # 80011ee0 <cpus>
    80001a1c:	953e                	add	a0,a0,a5
    80001a1e:	6422                	ld	s0,8(sp)
    80001a20:	0141                	addi	sp,sp,16
    80001a22:	8082                	ret

0000000080001a24 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	1000                	addi	s0,sp,32
  push_off();
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	1ce080e7          	jalr	462(ra) # 80000bfc <push_off>
    80001a36:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a38:	2781                	sext.w	a5,a5
    80001a3a:	079e                	slli	a5,a5,0x7
    80001a3c:	00010717          	auipc	a4,0x10
    80001a40:	47470713          	addi	a4,a4,1140 # 80011eb0 <pid_lock>
    80001a44:	97ba                	add	a5,a5,a4
    80001a46:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	254080e7          	jalr	596(ra) # 80000c9c <pop_off>
  return p;
}
    80001a50:	8526                	mv	a0,s1
    80001a52:	60e2                	ld	ra,24(sp)
    80001a54:	6442                	ld	s0,16(sp)
    80001a56:	64a2                	ld	s1,8(sp)
    80001a58:	6105                	addi	sp,sp,32
    80001a5a:	8082                	ret

0000000080001a5c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a5c:	1141                	addi	sp,sp,-16
    80001a5e:	e406                	sd	ra,8(sp)
    80001a60:	e022                	sd	s0,0(sp)
    80001a62:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a64:	00000097          	auipc	ra,0x0
    80001a68:	fc0080e7          	jalr	-64(ra) # 80001a24 <myproc>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	290080e7          	jalr	656(ra) # 80000cfc <release>

  if (first) {
    80001a74:	00008797          	auipc	a5,0x8
    80001a78:	14c7a783          	lw	a5,332(a5) # 80009bc0 <first.1>
    80001a7c:	eb89                	bnez	a5,80001a8e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a7e:	00001097          	auipc	ra,0x1
    80001a82:	c8a080e7          	jalr	-886(ra) # 80002708 <usertrapret>
}
    80001a86:	60a2                	ld	ra,8(sp)
    80001a88:	6402                	ld	s0,0(sp)
    80001a8a:	0141                	addi	sp,sp,16
    80001a8c:	8082                	ret
    first = 0;
    80001a8e:	00008797          	auipc	a5,0x8
    80001a92:	1207a923          	sw	zero,306(a5) # 80009bc0 <first.1>
    fsinit(ROOTDEV);
    80001a96:	4505                	li	a0,1
    80001a98:	00002097          	auipc	ra,0x2
    80001a9c:	a28080e7          	jalr	-1496(ra) # 800034c0 <fsinit>
    80001aa0:	bff9                	j	80001a7e <forkret+0x22>

0000000080001aa2 <allocpid>:
{
    80001aa2:	1101                	addi	sp,sp,-32
    80001aa4:	ec06                	sd	ra,24(sp)
    80001aa6:	e822                	sd	s0,16(sp)
    80001aa8:	e426                	sd	s1,8(sp)
    80001aaa:	e04a                	sd	s2,0(sp)
    80001aac:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aae:	00010917          	auipc	s2,0x10
    80001ab2:	40290913          	addi	s2,s2,1026 # 80011eb0 <pid_lock>
    80001ab6:	854a                	mv	a0,s2
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	190080e7          	jalr	400(ra) # 80000c48 <acquire>
  pid = nextpid;
    80001ac0:	00008797          	auipc	a5,0x8
    80001ac4:	10478793          	addi	a5,a5,260 # 80009bc4 <nextpid>
    80001ac8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aca:	0014871b          	addiw	a4,s1,1
    80001ace:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad0:	854a                	mv	a0,s2
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	22a080e7          	jalr	554(ra) # 80000cfc <release>
}
    80001ada:	8526                	mv	a0,s1
    80001adc:	60e2                	ld	ra,24(sp)
    80001ade:	6442                	ld	s0,16(sp)
    80001ae0:	64a2                	ld	s1,8(sp)
    80001ae2:	6902                	ld	s2,0(sp)
    80001ae4:	6105                	addi	sp,sp,32
    80001ae6:	8082                	ret

0000000080001ae8 <proc_pagetable>:
{
    80001ae8:	1101                	addi	sp,sp,-32
    80001aea:	ec06                	sd	ra,24(sp)
    80001aec:	e822                	sd	s0,16(sp)
    80001aee:	e426                	sd	s1,8(sp)
    80001af0:	e04a                	sd	s2,0(sp)
    80001af2:	1000                	addi	s0,sp,32
    80001af4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	8aa080e7          	jalr	-1878(ra) # 800013a0 <uvmcreate>
    80001afe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b00:	c121                	beqz	a0,80001b40 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b02:	4729                	li	a4,10
    80001b04:	00006697          	auipc	a3,0x6
    80001b08:	4fc68693          	addi	a3,a3,1276 # 80008000 <_trampoline>
    80001b0c:	6605                	lui	a2,0x1
    80001b0e:	040005b7          	lui	a1,0x4000
    80001b12:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b14:	05b2                	slli	a1,a1,0xc
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	600080e7          	jalr	1536(ra) # 80001116 <mappages>
    80001b1e:	02054863          	bltz	a0,80001b4e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b22:	4719                	li	a4,6
    80001b24:	05893683          	ld	a3,88(s2)
    80001b28:	6605                	lui	a2,0x1
    80001b2a:	020005b7          	lui	a1,0x2000
    80001b2e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b30:	05b6                	slli	a1,a1,0xd
    80001b32:	8526                	mv	a0,s1
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	5e2080e7          	jalr	1506(ra) # 80001116 <mappages>
    80001b3c:	02054163          	bltz	a0,80001b5e <proc_pagetable+0x76>
}
    80001b40:	8526                	mv	a0,s1
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6902                	ld	s2,0(sp)
    80001b4a:	6105                	addi	sp,sp,32
    80001b4c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b4e:	4581                	li	a1,0
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	a54080e7          	jalr	-1452(ra) # 800015a6 <uvmfree>
    return 0;
    80001b5a:	4481                	li	s1,0
    80001b5c:	b7d5                	j	80001b40 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b5e:	4681                	li	a3,0
    80001b60:	4605                	li	a2,1
    80001b62:	040005b7          	lui	a1,0x4000
    80001b66:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b68:	05b2                	slli	a1,a1,0xc
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	770080e7          	jalr	1904(ra) # 800012dc <uvmunmap>
    uvmfree(pagetable, 0);
    80001b74:	4581                	li	a1,0
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	a2e080e7          	jalr	-1490(ra) # 800015a6 <uvmfree>
    return 0;
    80001b80:	4481                	li	s1,0
    80001b82:	bf7d                	j	80001b40 <proc_pagetable+0x58>

0000000080001b84 <proc_freepagetable>:
{
    80001b84:	1101                	addi	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	e04a                	sd	s2,0(sp)
    80001b8e:	1000                	addi	s0,sp,32
    80001b90:	84aa                	mv	s1,a0
    80001b92:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b94:	4681                	li	a3,0
    80001b96:	4605                	li	a2,1
    80001b98:	040005b7          	lui	a1,0x4000
    80001b9c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b9e:	05b2                	slli	a1,a1,0xc
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	73c080e7          	jalr	1852(ra) # 800012dc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	020005b7          	lui	a1,0x2000
    80001bb0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bb2:	05b6                	slli	a1,a1,0xd
    80001bb4:	8526                	mv	a0,s1
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	726080e7          	jalr	1830(ra) # 800012dc <uvmunmap>
  uvmfree(pagetable, sz);
    80001bbe:	85ca                	mv	a1,s2
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	9e4080e7          	jalr	-1564(ra) # 800015a6 <uvmfree>
}
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6902                	ld	s2,0(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <freeproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	1000                	addi	s0,sp,32
    80001be0:	84aa                	mv	s1,a0
  if (strncmp(p->name, "vm-", 3) == 0) {
    80001be2:	460d                	li	a2,3
    80001be4:	00007597          	auipc	a1,0x7
    80001be8:	61c58593          	addi	a1,a1,1564 # 80009200 <digits+0x1c0>
    80001bec:	15850513          	addi	a0,a0,344
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	224080e7          	jalr	548(ra) # 80000e14 <strncmp>
    80001bf8:	c539                	beqz	a0,80001c46 <freeproc+0x70>
  if(p->trapframe)
    80001bfa:	6ca8                	ld	a0,88(s1)
    80001bfc:	c509                	beqz	a0,80001c06 <freeproc+0x30>
    kfree((void*)p->trapframe);
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	e5c080e7          	jalr	-420(ra) # 80000a5a <kfree>
  p->trapframe = 0;
    80001c06:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c0a:	68a8                	ld	a0,80(s1)
    80001c0c:	c511                	beqz	a0,80001c18 <freeproc+0x42>
    proc_freepagetable(p->pagetable, p->sz);
    80001c0e:	64ac                	ld	a1,72(s1)
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	f74080e7          	jalr	-140(ra) # 80001b84 <proc_freepagetable>
  p->pagetable = 0;
    80001c18:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c1c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c20:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c24:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c28:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c2c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c30:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c34:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c38:	0004ac23          	sw	zero,24(s1)
}
    80001c3c:	60e2                	ld	ra,24(sp)
    80001c3e:	6442                	ld	s0,16(sp)
    80001c40:	64a2                	ld	s1,8(sp)
    80001c42:	6105                	addi	sp,sp,32
    80001c44:	8082                	ret
    uvmunmap(p->pagetable, memaddr_start, memaddr_count, 0);
    80001c46:	4681                	li	a3,0
    80001c48:	40000613          	li	a2,1024
    80001c4c:	4585                	li	a1,1
    80001c4e:	05fe                	slli	a1,a1,0x1f
    80001c50:	68a8                	ld	a0,80(s1)
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	68a080e7          	jalr	1674(ra) # 800012dc <uvmunmap>
    80001c5a:	b745                	j	80001bfa <freeproc+0x24>

0000000080001c5c <allocproc>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c68:	00010497          	auipc	s1,0x10
    80001c6c:	67848493          	addi	s1,s1,1656 # 800122e0 <proc>
    80001c70:	00016917          	auipc	s2,0x16
    80001c74:	27090913          	addi	s2,s2,624 # 80017ee0 <tickslock>
    acquire(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	fce080e7          	jalr	-50(ra) # 80000c48 <acquire>
    if(p->state == UNUSED) {
    80001c82:	4c9c                	lw	a5,24(s1)
    80001c84:	cf81                	beqz	a5,80001c9c <allocproc+0x40>
      release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	074080e7          	jalr	116(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c90:	17048493          	addi	s1,s1,368
    80001c94:	ff2492e3          	bne	s1,s2,80001c78 <allocproc+0x1c>
  return 0;
    80001c98:	4481                	li	s1,0
    80001c9a:	a889                	j	80001cec <allocproc+0x90>
  p->pid = allocpid();
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	e06080e7          	jalr	-506(ra) # 80001aa2 <allocpid>
    80001ca4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ca6:	4785                	li	a5,1
    80001ca8:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	eae080e7          	jalr	-338(ra) # 80000b58 <kalloc>
    80001cb2:	892a                	mv	s2,a0
    80001cb4:	eca8                	sd	a0,88(s1)
    80001cb6:	c131                	beqz	a0,80001cfa <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	e2e080e7          	jalr	-466(ra) # 80001ae8 <proc_pagetable>
    80001cc2:	892a                	mv	s2,a0
    80001cc4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cc6:	c531                	beqz	a0,80001d12 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001cc8:	07000613          	li	a2,112
    80001ccc:	4581                	li	a1,0
    80001cce:	06048513          	addi	a0,s1,96
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	072080e7          	jalr	114(ra) # 80000d44 <memset>
  p->context.ra = (uint64)forkret;
    80001cda:	00000797          	auipc	a5,0x0
    80001cde:	d8278793          	addi	a5,a5,-638 # 80001a5c <forkret>
    80001ce2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce4:	60bc                	ld	a5,64(s1)
    80001ce6:	6705                	lui	a4,0x1
    80001ce8:	97ba                	add	a5,a5,a4
    80001cea:	f4bc                	sd	a5,104(s1)
}
    80001cec:	8526                	mv	a0,s1
    80001cee:	60e2                	ld	ra,24(sp)
    80001cf0:	6442                	ld	s0,16(sp)
    80001cf2:	64a2                	ld	s1,8(sp)
    80001cf4:	6902                	ld	s2,0(sp)
    80001cf6:	6105                	addi	sp,sp,32
    80001cf8:	8082                	ret
    freeproc(p);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	eda080e7          	jalr	-294(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	ff6080e7          	jalr	-10(ra) # 80000cfc <release>
    return 0;
    80001d0e:	84ca                	mv	s1,s2
    80001d10:	bff1                	j	80001cec <allocproc+0x90>
    freeproc(p);
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	ec2080e7          	jalr	-318(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	fde080e7          	jalr	-34(ra) # 80000cfc <release>
    return 0;
    80001d26:	84ca                	mv	s1,s2
    80001d28:	b7d1                	j	80001cec <allocproc+0x90>

0000000080001d2a <userinit>:
{
    80001d2a:	1101                	addi	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	f28080e7          	jalr	-216(ra) # 80001c5c <allocproc>
    80001d3c:	84aa                	mv	s1,a0
  initproc = p;
    80001d3e:	00008797          	auipc	a5,0x8
    80001d42:	eea7bd23          	sd	a0,-262(a5) # 80009c38 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d46:	03400613          	li	a2,52
    80001d4a:	00008597          	auipc	a1,0x8
    80001d4e:	e8658593          	addi	a1,a1,-378 # 80009bd0 <initcode>
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	67a080e7          	jalr	1658(ra) # 800013ce <uvmfirst>
  p->sz = PGSIZE;
    80001d5c:	6785                	lui	a5,0x1
    80001d5e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d60:	6cb8                	ld	a4,88(s1)
    80001d62:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d66:	6cb8                	ld	a4,88(s1)
    80001d68:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d6a:	4641                	li	a2,16
    80001d6c:	00007597          	auipc	a1,0x7
    80001d70:	49c58593          	addi	a1,a1,1180 # 80009208 <digits+0x1c8>
    80001d74:	15848513          	addi	a0,s1,344
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	114080e7          	jalr	276(ra) # 80000e8c <safestrcpy>
  p->cwd = namei("/");
    80001d80:	00007517          	auipc	a0,0x7
    80001d84:	49850513          	addi	a0,a0,1176 # 80009218 <digits+0x1d8>
    80001d88:	00002097          	auipc	ra,0x2
    80001d8c:	156080e7          	jalr	342(ra) # 80003ede <namei>
    80001d90:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d94:	478d                	li	a5,3
    80001d96:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d98:	8526                	mv	a0,s1
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	f62080e7          	jalr	-158(ra) # 80000cfc <release>
}
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6105                	addi	sp,sp,32
    80001daa:	8082                	ret

0000000080001dac <growproc>:
{
    80001dac:	1101                	addi	sp,sp,-32
    80001dae:	ec06                	sd	ra,24(sp)
    80001db0:	e822                	sd	s0,16(sp)
    80001db2:	e426                	sd	s1,8(sp)
    80001db4:	e04a                	sd	s2,0(sp)
    80001db6:	1000                	addi	s0,sp,32
    80001db8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	c6a080e7          	jalr	-918(ra) # 80001a24 <myproc>
    80001dc2:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dc4:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001dc6:	01204c63          	bgtz	s2,80001dde <growproc+0x32>
  } else if(n < 0){
    80001dca:	02094663          	bltz	s2,80001df6 <growproc+0x4a>
  p->sz = sz;
    80001dce:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dd0:	4501                	li	a0,0
}
    80001dd2:	60e2                	ld	ra,24(sp)
    80001dd4:	6442                	ld	s0,16(sp)
    80001dd6:	64a2                	ld	s1,8(sp)
    80001dd8:	6902                	ld	s2,0(sp)
    80001dda:	6105                	addi	sp,sp,32
    80001ddc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001dde:	4691                	li	a3,4
    80001de0:	00b90633          	add	a2,s2,a1
    80001de4:	6928                	ld	a0,80(a0)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	6a2080e7          	jalr	1698(ra) # 80001488 <uvmalloc>
    80001dee:	85aa                	mv	a1,a0
    80001df0:	fd79                	bnez	a0,80001dce <growproc+0x22>
      return -1;
    80001df2:	557d                	li	a0,-1
    80001df4:	bff9                	j	80001dd2 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001df6:	00b90633          	add	a2,s2,a1
    80001dfa:	6928                	ld	a0,80(a0)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	644080e7          	jalr	1604(ra) # 80001440 <uvmdealloc>
    80001e04:	85aa                	mv	a1,a0
    80001e06:	b7e1                	j	80001dce <growproc+0x22>

0000000080001e08 <fork>:
{
    80001e08:	7139                	addi	sp,sp,-64
    80001e0a:	fc06                	sd	ra,56(sp)
    80001e0c:	f822                	sd	s0,48(sp)
    80001e0e:	f426                	sd	s1,40(sp)
    80001e10:	f04a                	sd	s2,32(sp)
    80001e12:	ec4e                	sd	s3,24(sp)
    80001e14:	e852                	sd	s4,16(sp)
    80001e16:	e456                	sd	s5,8(sp)
    80001e18:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	c0a080e7          	jalr	-1014(ra) # 80001a24 <myproc>
    80001e22:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	e38080e7          	jalr	-456(ra) # 80001c5c <allocproc>
    80001e2c:	10050c63          	beqz	a0,80001f44 <fork+0x13c>
    80001e30:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e32:	048ab603          	ld	a2,72(s5)
    80001e36:	692c                	ld	a1,80(a0)
    80001e38:	050ab503          	ld	a0,80(s5)
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	7a4080e7          	jalr	1956(ra) # 800015e0 <uvmcopy>
    80001e44:	04054863          	bltz	a0,80001e94 <fork+0x8c>
  np->sz = p->sz;
    80001e48:	048ab783          	ld	a5,72(s5)
    80001e4c:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e50:	058ab683          	ld	a3,88(s5)
    80001e54:	87b6                	mv	a5,a3
    80001e56:	058a3703          	ld	a4,88(s4)
    80001e5a:	12068693          	addi	a3,a3,288
    80001e5e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e62:	6788                	ld	a0,8(a5)
    80001e64:	6b8c                	ld	a1,16(a5)
    80001e66:	6f90                	ld	a2,24(a5)
    80001e68:	01073023          	sd	a6,0(a4)
    80001e6c:	e708                	sd	a0,8(a4)
    80001e6e:	eb0c                	sd	a1,16(a4)
    80001e70:	ef10                	sd	a2,24(a4)
    80001e72:	02078793          	addi	a5,a5,32
    80001e76:	02070713          	addi	a4,a4,32
    80001e7a:	fed792e3          	bne	a5,a3,80001e5e <fork+0x56>
  np->trapframe->a0 = 0;
    80001e7e:	058a3783          	ld	a5,88(s4)
    80001e82:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e86:	0d0a8493          	addi	s1,s5,208
    80001e8a:	0d0a0913          	addi	s2,s4,208
    80001e8e:	150a8993          	addi	s3,s5,336
    80001e92:	a00d                	j	80001eb4 <fork+0xac>
    freeproc(np);
    80001e94:	8552                	mv	a0,s4
    80001e96:	00000097          	auipc	ra,0x0
    80001e9a:	d40080e7          	jalr	-704(ra) # 80001bd6 <freeproc>
    release(&np->lock);
    80001e9e:	8552                	mv	a0,s4
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	e5c080e7          	jalr	-420(ra) # 80000cfc <release>
    return -1;
    80001ea8:	597d                	li	s2,-1
    80001eaa:	a059                	j	80001f30 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001eac:	04a1                	addi	s1,s1,8
    80001eae:	0921                	addi	s2,s2,8
    80001eb0:	01348b63          	beq	s1,s3,80001ec6 <fork+0xbe>
    if(p->ofile[i])
    80001eb4:	6088                	ld	a0,0(s1)
    80001eb6:	d97d                	beqz	a0,80001eac <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb8:	00002097          	auipc	ra,0x2
    80001ebc:	698080e7          	jalr	1688(ra) # 80004550 <filedup>
    80001ec0:	00a93023          	sd	a0,0(s2)
    80001ec4:	b7e5                	j	80001eac <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ec6:	150ab503          	ld	a0,336(s5)
    80001eca:	00002097          	auipc	ra,0x2
    80001ece:	830080e7          	jalr	-2000(ra) # 800036fa <idup>
    80001ed2:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ed6:	4641                	li	a2,16
    80001ed8:	158a8593          	addi	a1,s5,344
    80001edc:	158a0513          	addi	a0,s4,344
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	fac080e7          	jalr	-84(ra) # 80000e8c <safestrcpy>
  pid = np->pid;
    80001ee8:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001eec:	8552                	mv	a0,s4
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	e0e080e7          	jalr	-498(ra) # 80000cfc <release>
  acquire(&wait_lock);
    80001ef6:	00010497          	auipc	s1,0x10
    80001efa:	fd248493          	addi	s1,s1,-46 # 80011ec8 <wait_lock>
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d48080e7          	jalr	-696(ra) # 80000c48 <acquire>
  np->parent = p;
    80001f08:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	dee080e7          	jalr	-530(ra) # 80000cfc <release>
  acquire(&np->lock);
    80001f16:	8552                	mv	a0,s4
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d30080e7          	jalr	-720(ra) # 80000c48 <acquire>
  np->state = RUNNABLE;
    80001f20:	478d                	li	a5,3
    80001f22:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f26:	8552                	mv	a0,s4
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	dd4080e7          	jalr	-556(ra) # 80000cfc <release>
}
    80001f30:	854a                	mv	a0,s2
    80001f32:	70e2                	ld	ra,56(sp)
    80001f34:	7442                	ld	s0,48(sp)
    80001f36:	74a2                	ld	s1,40(sp)
    80001f38:	7902                	ld	s2,32(sp)
    80001f3a:	69e2                	ld	s3,24(sp)
    80001f3c:	6a42                	ld	s4,16(sp)
    80001f3e:	6aa2                	ld	s5,8(sp)
    80001f40:	6121                	addi	sp,sp,64
    80001f42:	8082                	ret
    return -1;
    80001f44:	597d                	li	s2,-1
    80001f46:	b7ed                	j	80001f30 <fork+0x128>

0000000080001f48 <scheduler>:
{
    80001f48:	7139                	addi	sp,sp,-64
    80001f4a:	fc06                	sd	ra,56(sp)
    80001f4c:	f822                	sd	s0,48(sp)
    80001f4e:	f426                	sd	s1,40(sp)
    80001f50:	f04a                	sd	s2,32(sp)
    80001f52:	ec4e                	sd	s3,24(sp)
    80001f54:	e852                	sd	s4,16(sp)
    80001f56:	e456                	sd	s5,8(sp)
    80001f58:	e05a                	sd	s6,0(sp)
    80001f5a:	0080                	addi	s0,sp,64
    80001f5c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f5e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f60:	00779a93          	slli	s5,a5,0x7
    80001f64:	00010717          	auipc	a4,0x10
    80001f68:	f4c70713          	addi	a4,a4,-180 # 80011eb0 <pid_lock>
    80001f6c:	9756                	add	a4,a4,s5
    80001f6e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f72:	00010717          	auipc	a4,0x10
    80001f76:	f7670713          	addi	a4,a4,-138 # 80011ee8 <cpus+0x8>
    80001f7a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f7c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f7e:	4b11                	li	s6,4
        c->proc = p;
    80001f80:	079e                	slli	a5,a5,0x7
    80001f82:	00010a17          	auipc	s4,0x10
    80001f86:	f2ea0a13          	addi	s4,s4,-210 # 80011eb0 <pid_lock>
    80001f8a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8c:	00016917          	auipc	s2,0x16
    80001f90:	f5490913          	addi	s2,s2,-172 # 80017ee0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9c:	10079073          	csrw	sstatus,a5
    80001fa0:	00010497          	auipc	s1,0x10
    80001fa4:	34048493          	addi	s1,s1,832 # 800122e0 <proc>
    80001fa8:	a811                	j	80001fbc <scheduler+0x74>
      release(&p->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	d50080e7          	jalr	-688(ra) # 80000cfc <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	17048493          	addi	s1,s1,368
    80001fb8:	fd248ee3          	beq	s1,s2,80001f94 <scheduler+0x4c>
      acquire(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	c8a080e7          	jalr	-886(ra) # 80000c48 <acquire>
      if(p->state == RUNNABLE) {
    80001fc6:	4c9c                	lw	a5,24(s1)
    80001fc8:	ff3791e3          	bne	a5,s3,80001faa <scheduler+0x62>
        p->state = RUNNING;
    80001fcc:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fd0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fd4:	06048593          	addi	a1,s1,96
    80001fd8:	8556                	mv	a0,s5
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	684080e7          	jalr	1668(ra) # 8000265e <swtch>
        c->proc = 0;
    80001fe2:	020a3823          	sd	zero,48(s4)
    80001fe6:	b7d1                	j	80001faa <scheduler+0x62>

0000000080001fe8 <sched>:
{
    80001fe8:	7179                	addi	sp,sp,-48
    80001fea:	f406                	sd	ra,40(sp)
    80001fec:	f022                	sd	s0,32(sp)
    80001fee:	ec26                	sd	s1,24(sp)
    80001ff0:	e84a                	sd	s2,16(sp)
    80001ff2:	e44e                	sd	s3,8(sp)
    80001ff4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	a2e080e7          	jalr	-1490(ra) # 80001a24 <myproc>
    80001ffe:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	bce080e7          	jalr	-1074(ra) # 80000bce <holding>
    80002008:	c93d                	beqz	a0,8000207e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000200a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	00010717          	auipc	a4,0x10
    80002014:	ea070713          	addi	a4,a4,-352 # 80011eb0 <pid_lock>
    80002018:	97ba                	add	a5,a5,a4
    8000201a:	0a87a703          	lw	a4,168(a5)
    8000201e:	4785                	li	a5,1
    80002020:	06f71763          	bne	a4,a5,8000208e <sched+0xa6>
  if(p->state == RUNNING)
    80002024:	4c98                	lw	a4,24(s1)
    80002026:	4791                	li	a5,4
    80002028:	06f70b63          	beq	a4,a5,8000209e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002030:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002032:	efb5                	bnez	a5,800020ae <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002034:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002036:	00010917          	auipc	s2,0x10
    8000203a:	e7a90913          	addi	s2,s2,-390 # 80011eb0 <pid_lock>
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	97ca                	add	a5,a5,s2
    80002044:	0ac7a983          	lw	s3,172(a5)
    80002048:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000204a:	2781                	sext.w	a5,a5
    8000204c:	079e                	slli	a5,a5,0x7
    8000204e:	00010597          	auipc	a1,0x10
    80002052:	e9a58593          	addi	a1,a1,-358 # 80011ee8 <cpus+0x8>
    80002056:	95be                	add	a1,a1,a5
    80002058:	06048513          	addi	a0,s1,96
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	602080e7          	jalr	1538(ra) # 8000265e <swtch>
    80002064:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	993e                	add	s2,s2,a5
    8000206c:	0b392623          	sw	s3,172(s2)
}
    80002070:	70a2                	ld	ra,40(sp)
    80002072:	7402                	ld	s0,32(sp)
    80002074:	64e2                	ld	s1,24(sp)
    80002076:	6942                	ld	s2,16(sp)
    80002078:	69a2                	ld	s3,8(sp)
    8000207a:	6145                	addi	sp,sp,48
    8000207c:	8082                	ret
    panic("sched p->lock");
    8000207e:	00007517          	auipc	a0,0x7
    80002082:	1a250513          	addi	a0,a0,418 # 80009220 <digits+0x1e0>
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	4ba080e7          	jalr	1210(ra) # 80000540 <panic>
    panic("sched locks");
    8000208e:	00007517          	auipc	a0,0x7
    80002092:	1a250513          	addi	a0,a0,418 # 80009230 <digits+0x1f0>
    80002096:	ffffe097          	auipc	ra,0xffffe
    8000209a:	4aa080e7          	jalr	1194(ra) # 80000540 <panic>
    panic("sched running");
    8000209e:	00007517          	auipc	a0,0x7
    800020a2:	1a250513          	addi	a0,a0,418 # 80009240 <digits+0x200>
    800020a6:	ffffe097          	auipc	ra,0xffffe
    800020aa:	49a080e7          	jalr	1178(ra) # 80000540 <panic>
    panic("sched interruptible");
    800020ae:	00007517          	auipc	a0,0x7
    800020b2:	1a250513          	addi	a0,a0,418 # 80009250 <digits+0x210>
    800020b6:	ffffe097          	auipc	ra,0xffffe
    800020ba:	48a080e7          	jalr	1162(ra) # 80000540 <panic>

00000000800020be <yield>:
{
    800020be:	1101                	addi	sp,sp,-32
    800020c0:	ec06                	sd	ra,24(sp)
    800020c2:	e822                	sd	s0,16(sp)
    800020c4:	e426                	sd	s1,8(sp)
    800020c6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	95c080e7          	jalr	-1700(ra) # 80001a24 <myproc>
    800020d0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b76080e7          	jalr	-1162(ra) # 80000c48 <acquire>
  p->state = RUNNABLE;
    800020da:	478d                	li	a5,3
    800020dc:	cc9c                	sw	a5,24(s1)
  sched();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	f0a080e7          	jalr	-246(ra) # 80001fe8 <sched>
  release(&p->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	c14080e7          	jalr	-1004(ra) # 80000cfc <release>
}
    800020f0:	60e2                	ld	ra,24(sp)
    800020f2:	6442                	ld	s0,16(sp)
    800020f4:	64a2                	ld	s1,8(sp)
    800020f6:	6105                	addi	sp,sp,32
    800020f8:	8082                	ret

00000000800020fa <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020fa:	7179                	addi	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	1800                	addi	s0,sp,48
    80002108:	89aa                	mv	s3,a0
    8000210a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	918080e7          	jalr	-1768(ra) # 80001a24 <myproc>
    80002114:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	b32080e7          	jalr	-1230(ra) # 80000c48 <acquire>
  release(lk);
    8000211e:	854a                	mv	a0,s2
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	bdc080e7          	jalr	-1060(ra) # 80000cfc <release>

  // Go to sleep.
  p->chan = chan;
    80002128:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000212c:	4789                	li	a5,2
    8000212e:	cc9c                	sw	a5,24(s1)

  sched();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	eb8080e7          	jalr	-328(ra) # 80001fe8 <sched>

  // Tidy up.
  p->chan = 0;
    80002138:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	bbe080e7          	jalr	-1090(ra) # 80000cfc <release>
  acquire(lk);
    80002146:	854a                	mv	a0,s2
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b00080e7          	jalr	-1280(ra) # 80000c48 <acquire>
}
    80002150:	70a2                	ld	ra,40(sp)
    80002152:	7402                	ld	s0,32(sp)
    80002154:	64e2                	ld	s1,24(sp)
    80002156:	6942                	ld	s2,16(sp)
    80002158:	69a2                	ld	s3,8(sp)
    8000215a:	6145                	addi	sp,sp,48
    8000215c:	8082                	ret

000000008000215e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000215e:	7139                	addi	sp,sp,-64
    80002160:	fc06                	sd	ra,56(sp)
    80002162:	f822                	sd	s0,48(sp)
    80002164:	f426                	sd	s1,40(sp)
    80002166:	f04a                	sd	s2,32(sp)
    80002168:	ec4e                	sd	s3,24(sp)
    8000216a:	e852                	sd	s4,16(sp)
    8000216c:	e456                	sd	s5,8(sp)
    8000216e:	0080                	addi	s0,sp,64
    80002170:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002172:	00010497          	auipc	s1,0x10
    80002176:	16e48493          	addi	s1,s1,366 # 800122e0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000217a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000217c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217e:	00016917          	auipc	s2,0x16
    80002182:	d6290913          	addi	s2,s2,-670 # 80017ee0 <tickslock>
    80002186:	a811                	j	8000219a <wakeup+0x3c>
      }
      release(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	b72080e7          	jalr	-1166(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002192:	17048493          	addi	s1,s1,368
    80002196:	03248663          	beq	s1,s2,800021c2 <wakeup+0x64>
    if(p != myproc()){
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	88a080e7          	jalr	-1910(ra) # 80001a24 <myproc>
    800021a2:	fea488e3          	beq	s1,a0,80002192 <wakeup+0x34>
      acquire(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	aa0080e7          	jalr	-1376(ra) # 80000c48 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021b0:	4c9c                	lw	a5,24(s1)
    800021b2:	fd379be3          	bne	a5,s3,80002188 <wakeup+0x2a>
    800021b6:	709c                	ld	a5,32(s1)
    800021b8:	fd4798e3          	bne	a5,s4,80002188 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021bc:	0154ac23          	sw	s5,24(s1)
    800021c0:	b7e1                	j	80002188 <wakeup+0x2a>
    }
  }
}
    800021c2:	70e2                	ld	ra,56(sp)
    800021c4:	7442                	ld	s0,48(sp)
    800021c6:	74a2                	ld	s1,40(sp)
    800021c8:	7902                	ld	s2,32(sp)
    800021ca:	69e2                	ld	s3,24(sp)
    800021cc:	6a42                	ld	s4,16(sp)
    800021ce:	6aa2                	ld	s5,8(sp)
    800021d0:	6121                	addi	sp,sp,64
    800021d2:	8082                	ret

00000000800021d4 <reparent>:
{
    800021d4:	7179                	addi	sp,sp,-48
    800021d6:	f406                	sd	ra,40(sp)
    800021d8:	f022                	sd	s0,32(sp)
    800021da:	ec26                	sd	s1,24(sp)
    800021dc:	e84a                	sd	s2,16(sp)
    800021de:	e44e                	sd	s3,8(sp)
    800021e0:	e052                	sd	s4,0(sp)
    800021e2:	1800                	addi	s0,sp,48
    800021e4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e6:	00010497          	auipc	s1,0x10
    800021ea:	0fa48493          	addi	s1,s1,250 # 800122e0 <proc>
      pp->parent = initproc;
    800021ee:	00008a17          	auipc	s4,0x8
    800021f2:	a4aa0a13          	addi	s4,s4,-1462 # 80009c38 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f6:	00016997          	auipc	s3,0x16
    800021fa:	cea98993          	addi	s3,s3,-790 # 80017ee0 <tickslock>
    800021fe:	a029                	j	80002208 <reparent+0x34>
    80002200:	17048493          	addi	s1,s1,368
    80002204:	01348d63          	beq	s1,s3,8000221e <reparent+0x4a>
    if(pp->parent == p){
    80002208:	7c9c                	ld	a5,56(s1)
    8000220a:	ff279be3          	bne	a5,s2,80002200 <reparent+0x2c>
      pp->parent = initproc;
    8000220e:	000a3503          	ld	a0,0(s4)
    80002212:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f4a080e7          	jalr	-182(ra) # 8000215e <wakeup>
    8000221c:	b7d5                	j	80002200 <reparent+0x2c>
}
    8000221e:	70a2                	ld	ra,40(sp)
    80002220:	7402                	ld	s0,32(sp)
    80002222:	64e2                	ld	s1,24(sp)
    80002224:	6942                	ld	s2,16(sp)
    80002226:	69a2                	ld	s3,8(sp)
    80002228:	6a02                	ld	s4,0(sp)
    8000222a:	6145                	addi	sp,sp,48
    8000222c:	8082                	ret

000000008000222e <exit>:
{
    8000222e:	7179                	addi	sp,sp,-48
    80002230:	f406                	sd	ra,40(sp)
    80002232:	f022                	sd	s0,32(sp)
    80002234:	ec26                	sd	s1,24(sp)
    80002236:	e84a                	sd	s2,16(sp)
    80002238:	e44e                	sd	s3,8(sp)
    8000223a:	e052                	sd	s4,0(sp)
    8000223c:	1800                	addi	s0,sp,48
    8000223e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	7e4080e7          	jalr	2020(ra) # 80001a24 <myproc>
    80002248:	89aa                	mv	s3,a0
  if(p == initproc)
    8000224a:	00008797          	auipc	a5,0x8
    8000224e:	9ee7b783          	ld	a5,-1554(a5) # 80009c38 <initproc>
    80002252:	0d050493          	addi	s1,a0,208
    80002256:	15050913          	addi	s2,a0,336
    8000225a:	02a79363          	bne	a5,a0,80002280 <exit+0x52>
    panic("init exiting");
    8000225e:	00007517          	auipc	a0,0x7
    80002262:	00a50513          	addi	a0,a0,10 # 80009268 <digits+0x228>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2da080e7          	jalr	730(ra) # 80000540 <panic>
      fileclose(f);
    8000226e:	00002097          	auipc	ra,0x2
    80002272:	334080e7          	jalr	820(ra) # 800045a2 <fileclose>
      p->ofile[fd] = 0;
    80002276:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000227a:	04a1                	addi	s1,s1,8
    8000227c:	01248563          	beq	s1,s2,80002286 <exit+0x58>
    if(p->ofile[fd]){
    80002280:	6088                	ld	a0,0(s1)
    80002282:	f575                	bnez	a0,8000226e <exit+0x40>
    80002284:	bfdd                	j	8000227a <exit+0x4c>
  begin_op();
    80002286:	00002097          	auipc	ra,0x2
    8000228a:	e58080e7          	jalr	-424(ra) # 800040de <begin_op>
  iput(p->cwd);
    8000228e:	1509b503          	ld	a0,336(s3)
    80002292:	00001097          	auipc	ra,0x1
    80002296:	660080e7          	jalr	1632(ra) # 800038f2 <iput>
  end_op();
    8000229a:	00002097          	auipc	ra,0x2
    8000229e:	ebe080e7          	jalr	-322(ra) # 80004158 <end_op>
  p->cwd = 0;
    800022a2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022a6:	00010497          	auipc	s1,0x10
    800022aa:	c2248493          	addi	s1,s1,-990 # 80011ec8 <wait_lock>
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	998080e7          	jalr	-1640(ra) # 80000c48 <acquire>
  reparent(p);
    800022b8:	854e                	mv	a0,s3
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	f1a080e7          	jalr	-230(ra) # 800021d4 <reparent>
  wakeup(p->parent);
    800022c2:	0389b503          	ld	a0,56(s3)
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	e98080e7          	jalr	-360(ra) # 8000215e <wakeup>
  acquire(&p->lock);
    800022ce:	854e                	mv	a0,s3
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	978080e7          	jalr	-1672(ra) # 80000c48 <acquire>
  p->xstate = status;
    800022d8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022dc:	4795                	li	a5,5
    800022de:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	a18080e7          	jalr	-1512(ra) # 80000cfc <release>
  sched();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	cfc080e7          	jalr	-772(ra) # 80001fe8 <sched>
  panic("zombie exit");
    800022f4:	00007517          	auipc	a0,0x7
    800022f8:	f8450513          	addi	a0,a0,-124 # 80009278 <digits+0x238>
    800022fc:	ffffe097          	auipc	ra,0xffffe
    80002300:	244080e7          	jalr	580(ra) # 80000540 <panic>

0000000080002304 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002304:	7179                	addi	sp,sp,-48
    80002306:	f406                	sd	ra,40(sp)
    80002308:	f022                	sd	s0,32(sp)
    8000230a:	ec26                	sd	s1,24(sp)
    8000230c:	e84a                	sd	s2,16(sp)
    8000230e:	e44e                	sd	s3,8(sp)
    80002310:	1800                	addi	s0,sp,48
    80002312:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002314:	00010497          	auipc	s1,0x10
    80002318:	fcc48493          	addi	s1,s1,-52 # 800122e0 <proc>
    8000231c:	00016997          	auipc	s3,0x16
    80002320:	bc498993          	addi	s3,s3,-1084 # 80017ee0 <tickslock>
    acquire(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	922080e7          	jalr	-1758(ra) # 80000c48 <acquire>
    if(p->pid == pid){
    8000232e:	589c                	lw	a5,48(s1)
    80002330:	01278d63          	beq	a5,s2,8000234a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	9c6080e7          	jalr	-1594(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000233e:	17048493          	addi	s1,s1,368
    80002342:	ff3491e3          	bne	s1,s3,80002324 <kill+0x20>
  }
  return -1;
    80002346:	557d                	li	a0,-1
    80002348:	a829                	j	80002362 <kill+0x5e>
      p->killed = 1;
    8000234a:	4785                	li	a5,1
    8000234c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000234e:	4c98                	lw	a4,24(s1)
    80002350:	4789                	li	a5,2
    80002352:	00f70f63          	beq	a4,a5,80002370 <kill+0x6c>
      release(&p->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	9a4080e7          	jalr	-1628(ra) # 80000cfc <release>
      return 0;
    80002360:	4501                	li	a0,0
}
    80002362:	70a2                	ld	ra,40(sp)
    80002364:	7402                	ld	s0,32(sp)
    80002366:	64e2                	ld	s1,24(sp)
    80002368:	6942                	ld	s2,16(sp)
    8000236a:	69a2                	ld	s3,8(sp)
    8000236c:	6145                	addi	sp,sp,48
    8000236e:	8082                	ret
        p->state = RUNNABLE;
    80002370:	478d                	li	a5,3
    80002372:	cc9c                	sw	a5,24(s1)
    80002374:	b7cd                	j	80002356 <kill+0x52>

0000000080002376 <setkilled>:

void
setkilled(struct proc *p)
{
    80002376:	1101                	addi	sp,sp,-32
    80002378:	ec06                	sd	ra,24(sp)
    8000237a:	e822                	sd	s0,16(sp)
    8000237c:	e426                	sd	s1,8(sp)
    8000237e:	1000                	addi	s0,sp,32
    80002380:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	8c6080e7          	jalr	-1850(ra) # 80000c48 <acquire>
  p->killed = 1;
    8000238a:	4785                	li	a5,1
    8000238c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	96c080e7          	jalr	-1684(ra) # 80000cfc <release>
}
    80002398:	60e2                	ld	ra,24(sp)
    8000239a:	6442                	ld	s0,16(sp)
    8000239c:	64a2                	ld	s1,8(sp)
    8000239e:	6105                	addi	sp,sp,32
    800023a0:	8082                	ret

00000000800023a2 <killed>:

int
killed(struct proc *p)
{
    800023a2:	1101                	addi	sp,sp,-32
    800023a4:	ec06                	sd	ra,24(sp)
    800023a6:	e822                	sd	s0,16(sp)
    800023a8:	e426                	sd	s1,8(sp)
    800023aa:	e04a                	sd	s2,0(sp)
    800023ac:	1000                	addi	s0,sp,32
    800023ae:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	898080e7          	jalr	-1896(ra) # 80000c48 <acquire>
  k = p->killed;
    800023b8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	93e080e7          	jalr	-1730(ra) # 80000cfc <release>
  return k;
}
    800023c6:	854a                	mv	a0,s2
    800023c8:	60e2                	ld	ra,24(sp)
    800023ca:	6442                	ld	s0,16(sp)
    800023cc:	64a2                	ld	s1,8(sp)
    800023ce:	6902                	ld	s2,0(sp)
    800023d0:	6105                	addi	sp,sp,32
    800023d2:	8082                	ret

00000000800023d4 <wait>:
{
    800023d4:	715d                	addi	sp,sp,-80
    800023d6:	e486                	sd	ra,72(sp)
    800023d8:	e0a2                	sd	s0,64(sp)
    800023da:	fc26                	sd	s1,56(sp)
    800023dc:	f84a                	sd	s2,48(sp)
    800023de:	f44e                	sd	s3,40(sp)
    800023e0:	f052                	sd	s4,32(sp)
    800023e2:	ec56                	sd	s5,24(sp)
    800023e4:	e85a                	sd	s6,16(sp)
    800023e6:	e45e                	sd	s7,8(sp)
    800023e8:	e062                	sd	s8,0(sp)
    800023ea:	0880                	addi	s0,sp,80
    800023ec:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	636080e7          	jalr	1590(ra) # 80001a24 <myproc>
    800023f6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023f8:	00010517          	auipc	a0,0x10
    800023fc:	ad050513          	addi	a0,a0,-1328 # 80011ec8 <wait_lock>
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	848080e7          	jalr	-1976(ra) # 80000c48 <acquire>
    havekids = 0;
    80002408:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000240a:	4a15                	li	s4,5
        havekids = 1;
    8000240c:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000240e:	00016997          	auipc	s3,0x16
    80002412:	ad298993          	addi	s3,s3,-1326 # 80017ee0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002416:	00010c17          	auipc	s8,0x10
    8000241a:	ab2c0c13          	addi	s8,s8,-1358 # 80011ec8 <wait_lock>
    8000241e:	a0d1                	j	800024e2 <wait+0x10e>
          pid = pp->pid;
    80002420:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002424:	000b0e63          	beqz	s6,80002440 <wait+0x6c>
    80002428:	4691                	li	a3,4
    8000242a:	02c48613          	addi	a2,s1,44
    8000242e:	85da                	mv	a1,s6
    80002430:	05093503          	ld	a0,80(s2)
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	2b0080e7          	jalr	688(ra) # 800016e4 <copyout>
    8000243c:	04054163          	bltz	a0,8000247e <wait+0xaa>
          freeproc(pp);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	794080e7          	jalr	1940(ra) # 80001bd6 <freeproc>
          release(&pp->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	8b0080e7          	jalr	-1872(ra) # 80000cfc <release>
          release(&wait_lock);
    80002454:	00010517          	auipc	a0,0x10
    80002458:	a7450513          	addi	a0,a0,-1420 # 80011ec8 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	8a0080e7          	jalr	-1888(ra) # 80000cfc <release>
}
    80002464:	854e                	mv	a0,s3
    80002466:	60a6                	ld	ra,72(sp)
    80002468:	6406                	ld	s0,64(sp)
    8000246a:	74e2                	ld	s1,56(sp)
    8000246c:	7942                	ld	s2,48(sp)
    8000246e:	79a2                	ld	s3,40(sp)
    80002470:	7a02                	ld	s4,32(sp)
    80002472:	6ae2                	ld	s5,24(sp)
    80002474:	6b42                	ld	s6,16(sp)
    80002476:	6ba2                	ld	s7,8(sp)
    80002478:	6c02                	ld	s8,0(sp)
    8000247a:	6161                	addi	sp,sp,80
    8000247c:	8082                	ret
            release(&pp->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	87c080e7          	jalr	-1924(ra) # 80000cfc <release>
            release(&wait_lock);
    80002488:	00010517          	auipc	a0,0x10
    8000248c:	a4050513          	addi	a0,a0,-1472 # 80011ec8 <wait_lock>
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	86c080e7          	jalr	-1940(ra) # 80000cfc <release>
            return -1;
    80002498:	59fd                	li	s3,-1
    8000249a:	b7e9                	j	80002464 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000249c:	17048493          	addi	s1,s1,368
    800024a0:	03348463          	beq	s1,s3,800024c8 <wait+0xf4>
      if(pp->parent == p){
    800024a4:	7c9c                	ld	a5,56(s1)
    800024a6:	ff279be3          	bne	a5,s2,8000249c <wait+0xc8>
        acquire(&pp->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	79c080e7          	jalr	1948(ra) # 80000c48 <acquire>
        if(pp->state == ZOMBIE){
    800024b4:	4c9c                	lw	a5,24(s1)
    800024b6:	f74785e3          	beq	a5,s4,80002420 <wait+0x4c>
        release(&pp->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	840080e7          	jalr	-1984(ra) # 80000cfc <release>
        havekids = 1;
    800024c4:	8756                	mv	a4,s5
    800024c6:	bfd9                	j	8000249c <wait+0xc8>
    if(!havekids || killed(p)){
    800024c8:	c31d                	beqz	a4,800024ee <wait+0x11a>
    800024ca:	854a                	mv	a0,s2
    800024cc:	00000097          	auipc	ra,0x0
    800024d0:	ed6080e7          	jalr	-298(ra) # 800023a2 <killed>
    800024d4:	ed09                	bnez	a0,800024ee <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024d6:	85e2                	mv	a1,s8
    800024d8:	854a                	mv	a0,s2
    800024da:	00000097          	auipc	ra,0x0
    800024de:	c20080e7          	jalr	-992(ra) # 800020fa <sleep>
    havekids = 0;
    800024e2:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024e4:	00010497          	auipc	s1,0x10
    800024e8:	dfc48493          	addi	s1,s1,-516 # 800122e0 <proc>
    800024ec:	bf65                	j	800024a4 <wait+0xd0>
      release(&wait_lock);
    800024ee:	00010517          	auipc	a0,0x10
    800024f2:	9da50513          	addi	a0,a0,-1574 # 80011ec8 <wait_lock>
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	806080e7          	jalr	-2042(ra) # 80000cfc <release>
      return -1;
    800024fe:	59fd                	li	s3,-1
    80002500:	b795                	j	80002464 <wait+0x90>

0000000080002502 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002502:	7179                	addi	sp,sp,-48
    80002504:	f406                	sd	ra,40(sp)
    80002506:	f022                	sd	s0,32(sp)
    80002508:	ec26                	sd	s1,24(sp)
    8000250a:	e84a                	sd	s2,16(sp)
    8000250c:	e44e                	sd	s3,8(sp)
    8000250e:	e052                	sd	s4,0(sp)
    80002510:	1800                	addi	s0,sp,48
    80002512:	84aa                	mv	s1,a0
    80002514:	892e                	mv	s2,a1
    80002516:	89b2                	mv	s3,a2
    80002518:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	50a080e7          	jalr	1290(ra) # 80001a24 <myproc>
  if(user_dst){
    80002522:	c08d                	beqz	s1,80002544 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002524:	86d2                	mv	a3,s4
    80002526:	864e                	mv	a2,s3
    80002528:	85ca                	mv	a1,s2
    8000252a:	6928                	ld	a0,80(a0)
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	1b8080e7          	jalr	440(ra) # 800016e4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002534:	70a2                	ld	ra,40(sp)
    80002536:	7402                	ld	s0,32(sp)
    80002538:	64e2                	ld	s1,24(sp)
    8000253a:	6942                	ld	s2,16(sp)
    8000253c:	69a2                	ld	s3,8(sp)
    8000253e:	6a02                	ld	s4,0(sp)
    80002540:	6145                	addi	sp,sp,48
    80002542:	8082                	ret
    memmove((char *)dst, src, len);
    80002544:	000a061b          	sext.w	a2,s4
    80002548:	85ce                	mv	a1,s3
    8000254a:	854a                	mv	a0,s2
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	854080e7          	jalr	-1964(ra) # 80000da0 <memmove>
    return 0;
    80002554:	8526                	mv	a0,s1
    80002556:	bff9                	j	80002534 <either_copyout+0x32>

0000000080002558 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002558:	7179                	addi	sp,sp,-48
    8000255a:	f406                	sd	ra,40(sp)
    8000255c:	f022                	sd	s0,32(sp)
    8000255e:	ec26                	sd	s1,24(sp)
    80002560:	e84a                	sd	s2,16(sp)
    80002562:	e44e                	sd	s3,8(sp)
    80002564:	e052                	sd	s4,0(sp)
    80002566:	1800                	addi	s0,sp,48
    80002568:	892a                	mv	s2,a0
    8000256a:	84ae                	mv	s1,a1
    8000256c:	89b2                	mv	s3,a2
    8000256e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	4b4080e7          	jalr	1204(ra) # 80001a24 <myproc>
  if(user_src){
    80002578:	c08d                	beqz	s1,8000259a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000257a:	86d2                	mv	a3,s4
    8000257c:	864e                	mv	a2,s3
    8000257e:	85ca                	mv	a1,s2
    80002580:	6928                	ld	a0,80(a0)
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	1ee080e7          	jalr	494(ra) # 80001770 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6a02                	ld	s4,0(sp)
    80002596:	6145                	addi	sp,sp,48
    80002598:	8082                	ret
    memmove(dst, (char*)src, len);
    8000259a:	000a061b          	sext.w	a2,s4
    8000259e:	85ce                	mv	a1,s3
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	7fe080e7          	jalr	2046(ra) # 80000da0 <memmove>
    return 0;
    800025aa:	8526                	mv	a0,s1
    800025ac:	bff9                	j	8000258a <either_copyin+0x32>

00000000800025ae <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ae:	715d                	addi	sp,sp,-80
    800025b0:	e486                	sd	ra,72(sp)
    800025b2:	e0a2                	sd	s0,64(sp)
    800025b4:	fc26                	sd	s1,56(sp)
    800025b6:	f84a                	sd	s2,48(sp)
    800025b8:	f44e                	sd	s3,40(sp)
    800025ba:	f052                	sd	s4,32(sp)
    800025bc:	ec56                	sd	s5,24(sp)
    800025be:	e85a                	sd	s6,16(sp)
    800025c0:	e45e                	sd	s7,8(sp)
    800025c2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025c4:	00007517          	auipc	a0,0x7
    800025c8:	b0450513          	addi	a0,a0,-1276 # 800090c8 <digits+0x88>
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fbe080e7          	jalr	-66(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d4:	00010497          	auipc	s1,0x10
    800025d8:	e6448493          	addi	s1,s1,-412 # 80012438 <proc+0x158>
    800025dc:	00016917          	auipc	s2,0x16
    800025e0:	a5c90913          	addi	s2,s2,-1444 # 80018038 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025e6:	00007997          	auipc	s3,0x7
    800025ea:	ca298993          	addi	s3,s3,-862 # 80009288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800025ee:	00007a97          	auipc	s5,0x7
    800025f2:	ca2a8a93          	addi	s5,s5,-862 # 80009290 <digits+0x250>
    printf("\n");
    800025f6:	00007a17          	auipc	s4,0x7
    800025fa:	ad2a0a13          	addi	s4,s4,-1326 # 800090c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025fe:	00007b97          	auipc	s7,0x7
    80002602:	cd2b8b93          	addi	s7,s7,-814 # 800092d0 <states.0>
    80002606:	a00d                	j	80002628 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002608:	ed86a583          	lw	a1,-296(a3)
    8000260c:	8556                	mv	a0,s5
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f7c080e7          	jalr	-132(ra) # 8000058a <printf>
    printf("\n");
    80002616:	8552                	mv	a0,s4
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f72080e7          	jalr	-142(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002620:	17048493          	addi	s1,s1,368
    80002624:	03248263          	beq	s1,s2,80002648 <procdump+0x9a>
    if(p->state == UNUSED)
    80002628:	86a6                	mv	a3,s1
    8000262a:	ec04a783          	lw	a5,-320(s1)
    8000262e:	dbed                	beqz	a5,80002620 <procdump+0x72>
      state = "???";
    80002630:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002632:	fcfb6be3          	bltu	s6,a5,80002608 <procdump+0x5a>
    80002636:	02079713          	slli	a4,a5,0x20
    8000263a:	01d75793          	srli	a5,a4,0x1d
    8000263e:	97de                	add	a5,a5,s7
    80002640:	6390                	ld	a2,0(a5)
    80002642:	f279                	bnez	a2,80002608 <procdump+0x5a>
      state = "???";
    80002644:	864e                	mv	a2,s3
    80002646:	b7c9                	j	80002608 <procdump+0x5a>
  }
}
    80002648:	60a6                	ld	ra,72(sp)
    8000264a:	6406                	ld	s0,64(sp)
    8000264c:	74e2                	ld	s1,56(sp)
    8000264e:	7942                	ld	s2,48(sp)
    80002650:	79a2                	ld	s3,40(sp)
    80002652:	7a02                	ld	s4,32(sp)
    80002654:	6ae2                	ld	s5,24(sp)
    80002656:	6b42                	ld	s6,16(sp)
    80002658:	6ba2                	ld	s7,8(sp)
    8000265a:	6161                	addi	sp,sp,80
    8000265c:	8082                	ret

000000008000265e <swtch>:
    8000265e:	00153023          	sd	ra,0(a0)
    80002662:	00253423          	sd	sp,8(a0)
    80002666:	e900                	sd	s0,16(a0)
    80002668:	ed04                	sd	s1,24(a0)
    8000266a:	03253023          	sd	s2,32(a0)
    8000266e:	03353423          	sd	s3,40(a0)
    80002672:	03453823          	sd	s4,48(a0)
    80002676:	03553c23          	sd	s5,56(a0)
    8000267a:	05653023          	sd	s6,64(a0)
    8000267e:	05753423          	sd	s7,72(a0)
    80002682:	05853823          	sd	s8,80(a0)
    80002686:	05953c23          	sd	s9,88(a0)
    8000268a:	07a53023          	sd	s10,96(a0)
    8000268e:	07b53423          	sd	s11,104(a0)
    80002692:	0005b083          	ld	ra,0(a1)
    80002696:	0085b103          	ld	sp,8(a1)
    8000269a:	6980                	ld	s0,16(a1)
    8000269c:	6d84                	ld	s1,24(a1)
    8000269e:	0205b903          	ld	s2,32(a1)
    800026a2:	0285b983          	ld	s3,40(a1)
    800026a6:	0305ba03          	ld	s4,48(a1)
    800026aa:	0385ba83          	ld	s5,56(a1)
    800026ae:	0405bb03          	ld	s6,64(a1)
    800026b2:	0485bb83          	ld	s7,72(a1)
    800026b6:	0505bc03          	ld	s8,80(a1)
    800026ba:	0585bc83          	ld	s9,88(a1)
    800026be:	0605bd03          	ld	s10,96(a1)
    800026c2:	0685bd83          	ld	s11,104(a1)
    800026c6:	8082                	ret

00000000800026c8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026c8:	1141                	addi	sp,sp,-16
    800026ca:	e406                	sd	ra,8(sp)
    800026cc:	e022                	sd	s0,0(sp)
    800026ce:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026d0:	00007597          	auipc	a1,0x7
    800026d4:	c3058593          	addi	a1,a1,-976 # 80009300 <states.0+0x30>
    800026d8:	00016517          	auipc	a0,0x16
    800026dc:	80850513          	addi	a0,a0,-2040 # 80017ee0 <tickslock>
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	4d8080e7          	jalr	1240(ra) # 80000bb8 <initlock>
}
    800026e8:	60a2                	ld	ra,8(sp)
    800026ea:	6402                	ld	s0,0(sp)
    800026ec:	0141                	addi	sp,sp,16
    800026ee:	8082                	ret

00000000800026f0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f0:	1141                	addi	sp,sp,-16
    800026f2:	e422                	sd	s0,8(sp)
    800026f4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f6:	00003797          	auipc	a5,0x3
    800026fa:	53a78793          	addi	a5,a5,1338 # 80005c30 <kernelvec>
    800026fe:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002702:	6422                	ld	s0,8(sp)
    80002704:	0141                	addi	sp,sp,16
    80002706:	8082                	ret

0000000080002708 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002708:	1141                	addi	sp,sp,-16
    8000270a:	e406                	sd	ra,8(sp)
    8000270c:	e022                	sd	s0,0(sp)
    8000270e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	314080e7          	jalr	788(ra) # 80001a24 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002718:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000271c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002722:	00006697          	auipc	a3,0x6
    80002726:	8de68693          	addi	a3,a3,-1826 # 80008000 <_trampoline>
    8000272a:	00006717          	auipc	a4,0x6
    8000272e:	8d670713          	addi	a4,a4,-1834 # 80008000 <_trampoline>
    80002732:	8f15                	sub	a4,a4,a3
    80002734:	040007b7          	lui	a5,0x4000
    80002738:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000273a:	07b2                	slli	a5,a5,0xc
    8000273c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000273e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002742:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002744:	18002673          	csrr	a2,satp
    80002748:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000274a:	6d30                	ld	a2,88(a0)
    8000274c:	6138                	ld	a4,64(a0)
    8000274e:	6585                	lui	a1,0x1
    80002750:	972e                	add	a4,a4,a1
    80002752:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002754:	6d38                	ld	a4,88(a0)
    80002756:	00000617          	auipc	a2,0x0
    8000275a:	13460613          	addi	a2,a2,308 # 8000288a <usertrap>
    8000275e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002760:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002762:	8612                	mv	a2,tp
    80002764:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002766:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000276a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000276e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002772:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002776:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002778:	6f18                	ld	a4,24(a4)
    8000277a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000277e:	6928                	ld	a0,80(a0)
    80002780:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002782:	00006717          	auipc	a4,0x6
    80002786:	91a70713          	addi	a4,a4,-1766 # 8000809c <userret>
    8000278a:	8f15                	sub	a4,a4,a3
    8000278c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000278e:	577d                	li	a4,-1
    80002790:	177e                	slli	a4,a4,0x3f
    80002792:	8d59                	or	a0,a0,a4
    80002794:	9782                	jalr	a5
}
    80002796:	60a2                	ld	ra,8(sp)
    80002798:	6402                	ld	s0,0(sp)
    8000279a:	0141                	addi	sp,sp,16
    8000279c:	8082                	ret

000000008000279e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000279e:	1101                	addi	sp,sp,-32
    800027a0:	ec06                	sd	ra,24(sp)
    800027a2:	e822                	sd	s0,16(sp)
    800027a4:	e426                	sd	s1,8(sp)
    800027a6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027a8:	00015497          	auipc	s1,0x15
    800027ac:	73848493          	addi	s1,s1,1848 # 80017ee0 <tickslock>
    800027b0:	8526                	mv	a0,s1
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	496080e7          	jalr	1174(ra) # 80000c48 <acquire>
  ticks++;
    800027ba:	00007517          	auipc	a0,0x7
    800027be:	48650513          	addi	a0,a0,1158 # 80009c40 <ticks>
    800027c2:	411c                	lw	a5,0(a0)
    800027c4:	2785                	addiw	a5,a5,1
    800027c6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c8:	00000097          	auipc	ra,0x0
    800027cc:	996080e7          	jalr	-1642(ra) # 8000215e <wakeup>
  release(&tickslock);
    800027d0:	8526                	mv	a0,s1
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	52a080e7          	jalr	1322(ra) # 80000cfc <release>
}
    800027da:	60e2                	ld	ra,24(sp)
    800027dc:	6442                	ld	s0,16(sp)
    800027de:	64a2                	ld	s1,8(sp)
    800027e0:	6105                	addi	sp,sp,32
    800027e2:	8082                	ret

00000000800027e4 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e4:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027e8:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    800027ea:	0807df63          	bgez	a5,80002888 <devintr+0xa4>
{
    800027ee:	1101                	addi	sp,sp,-32
    800027f0:	ec06                	sd	ra,24(sp)
    800027f2:	e822                	sd	s0,16(sp)
    800027f4:	e426                	sd	s1,8(sp)
    800027f6:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    800027f8:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    800027fc:	46a5                	li	a3,9
    800027fe:	00d70d63          	beq	a4,a3,80002818 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002802:	577d                	li	a4,-1
    80002804:	177e                	slli	a4,a4,0x3f
    80002806:	0705                	addi	a4,a4,1
    return 0;
    80002808:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000280a:	04e78e63          	beq	a5,a4,80002866 <devintr+0x82>
  }
}
    8000280e:	60e2                	ld	ra,24(sp)
    80002810:	6442                	ld	s0,16(sp)
    80002812:	64a2                	ld	s1,8(sp)
    80002814:	6105                	addi	sp,sp,32
    80002816:	8082                	ret
    int irq = plic_claim();
    80002818:	00003097          	auipc	ra,0x3
    8000281c:	520080e7          	jalr	1312(ra) # 80005d38 <plic_claim>
    80002820:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002822:	47a9                	li	a5,10
    80002824:	02f50763          	beq	a0,a5,80002852 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002828:	4785                	li	a5,1
    8000282a:	02f50963          	beq	a0,a5,8000285c <devintr+0x78>
    return 1;
    8000282e:	4505                	li	a0,1
    } else if(irq){
    80002830:	dcf9                	beqz	s1,8000280e <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002832:	85a6                	mv	a1,s1
    80002834:	00007517          	auipc	a0,0x7
    80002838:	ad450513          	addi	a0,a0,-1324 # 80009308 <states.0+0x38>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	d4e080e7          	jalr	-690(ra) # 8000058a <printf>
      plic_complete(irq);
    80002844:	8526                	mv	a0,s1
    80002846:	00003097          	auipc	ra,0x3
    8000284a:	516080e7          	jalr	1302(ra) # 80005d5c <plic_complete>
    return 1;
    8000284e:	4505                	li	a0,1
    80002850:	bf7d                	j	8000280e <devintr+0x2a>
      uartintr();
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	1b8080e7          	jalr	440(ra) # 80000a0a <uartintr>
    if(irq)
    8000285a:	b7ed                	j	80002844 <devintr+0x60>
      virtio_disk_intr();
    8000285c:	00004097          	auipc	ra,0x4
    80002860:	b78080e7          	jalr	-1160(ra) # 800063d4 <virtio_disk_intr>
    if(irq)
    80002864:	b7c5                	j	80002844 <devintr+0x60>
    if(cpuid() == 0){
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	192080e7          	jalr	402(ra) # 800019f8 <cpuid>
    8000286e:	c901                	beqz	a0,8000287e <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002870:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002874:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002876:	14479073          	csrw	sip,a5
    return 2;
    8000287a:	4509                	li	a0,2
    8000287c:	bf49                	j	8000280e <devintr+0x2a>
      clockintr();
    8000287e:	00000097          	auipc	ra,0x0
    80002882:	f20080e7          	jalr	-224(ra) # 8000279e <clockintr>
    80002886:	b7ed                	j	80002870 <devintr+0x8c>
}
    80002888:	8082                	ret

000000008000288a <usertrap>:
{
    8000288a:	1101                	addi	sp,sp,-32
    8000288c:	ec06                	sd	ra,24(sp)
    8000288e:	e822                	sd	s0,16(sp)
    80002890:	e426                	sd	s1,8(sp)
    80002892:	e04a                	sd	s2,0(sp)
    80002894:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002896:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000289a:	1007f793          	andi	a5,a5,256
    8000289e:	e3b1                	bnez	a5,800028e2 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a0:	00003797          	auipc	a5,0x3
    800028a4:	39078793          	addi	a5,a5,912 # 80005c30 <kernelvec>
    800028a8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ac:	fffff097          	auipc	ra,0xfffff
    800028b0:	178080e7          	jalr	376(ra) # 80001a24 <myproc>
    800028b4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028b6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b8:	14102773          	csrr	a4,sepc
    800028bc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028be:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028c2:	47a1                	li	a5,8
    800028c4:	02f70763          	beq	a4,a5,800028f2 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	f1c080e7          	jalr	-228(ra) # 800027e4 <devintr>
    800028d0:	892a                	mv	s2,a0
    800028d2:	c55d                	beqz	a0,80002980 <usertrap+0xf6>
  if(killed(p))
    800028d4:	8526                	mv	a0,s1
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	acc080e7          	jalr	-1332(ra) # 800023a2 <killed>
    800028de:	c535                	beqz	a0,8000294a <usertrap+0xc0>
    800028e0:	a085                	j	80002940 <usertrap+0xb6>
    panic("usertrap: not from user mode");
    800028e2:	00007517          	auipc	a0,0x7
    800028e6:	a4650513          	addi	a0,a0,-1466 # 80009328 <states.0+0x58>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	c56080e7          	jalr	-938(ra) # 80000540 <panic>
    if (strncmp(p->name, "vm-", 3) == 0) {
    800028f2:	460d                	li	a2,3
    800028f4:	00007597          	auipc	a1,0x7
    800028f8:	90c58593          	addi	a1,a1,-1780 # 80009200 <digits+0x1c0>
    800028fc:	15850513          	addi	a0,a0,344
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	514080e7          	jalr	1300(ra) # 80000e14 <strncmp>
    80002908:	cd31                	beqz	a0,80002964 <usertrap+0xda>
    if(killed(p))
    8000290a:	8526                	mv	a0,s1
    8000290c:	00000097          	auipc	ra,0x0
    80002910:	a96080e7          	jalr	-1386(ra) # 800023a2 <killed>
    80002914:	e125                	bnez	a0,80002974 <usertrap+0xea>
    p->trapframe->epc += 4;
    80002916:	6cb8                	ld	a4,88(s1)
    80002918:	6f1c                	ld	a5,24(a4)
    8000291a:	0791                	addi	a5,a5,4
    8000291c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000291e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002922:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002926:	10079073          	csrw	sstatus,a5
    syscall();
    8000292a:	00000097          	auipc	ra,0x0
    8000292e:	324080e7          	jalr	804(ra) # 80002c4e <syscall>
  if(killed(p))
    80002932:	8526                	mv	a0,s1
    80002934:	00000097          	auipc	ra,0x0
    80002938:	a6e080e7          	jalr	-1426(ra) # 800023a2 <killed>
    8000293c:	c911                	beqz	a0,80002950 <usertrap+0xc6>
    8000293e:	4901                	li	s2,0
    exit(-1);
    80002940:	557d                	li	a0,-1
    80002942:	00000097          	auipc	ra,0x0
    80002946:	8ec080e7          	jalr	-1812(ra) # 8000222e <exit>
  if(which_dev == 2)
    8000294a:	4789                	li	a5,2
    8000294c:	0af90763          	beq	s2,a5,800029fa <usertrap+0x170>
  usertrapret();
    80002950:	00000097          	auipc	ra,0x0
    80002954:	db8080e7          	jalr	-584(ra) # 80002708 <usertrapret>
}
    80002958:	60e2                	ld	ra,24(sp)
    8000295a:	6442                	ld	s0,16(sp)
    8000295c:	64a2                	ld	s1,8(sp)
    8000295e:	6902                	ld	s2,0(sp)
    80002960:	6105                	addi	sp,sp,32
    80002962:	8082                	ret
      p->proc_te_vm = 1;
    80002964:	4785                	li	a5,1
    80002966:	16f4a423          	sw	a5,360(s1)
      trap_and_emulate();
    8000296a:	00004097          	auipc	ra,0x4
    8000296e:	086080e7          	jalr	134(ra) # 800069f0 <trap_and_emulate>
    80002972:	bf61                	j	8000290a <usertrap+0x80>
      exit(-1);
    80002974:	557d                	li	a0,-1
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	8b8080e7          	jalr	-1864(ra) # 8000222e <exit>
    8000297e:	bf61                	j	80002916 <usertrap+0x8c>
  } else if ((strncmp(p->name, "vm-", 3) == 0) && r_scause() != 12 && r_scause() != 13 && r_scause() != 15) {
    80002980:	460d                	li	a2,3
    80002982:	00007597          	auipc	a1,0x7
    80002986:	87e58593          	addi	a1,a1,-1922 # 80009200 <digits+0x1c0>
    8000298a:	15848513          	addi	a0,s1,344
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	486080e7          	jalr	1158(ra) # 80000e14 <strncmp>
    80002996:	e105                	bnez	a0,800029b6 <usertrap+0x12c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002998:	14202773          	csrr	a4,scause
    8000299c:	47b1                	li	a5,12
    8000299e:	00f70c63          	beq	a4,a5,800029b6 <usertrap+0x12c>
    800029a2:	14202773          	csrr	a4,scause
    800029a6:	47b5                	li	a5,13
    800029a8:	00f70763          	beq	a4,a5,800029b6 <usertrap+0x12c>
    800029ac:	14202773          	csrr	a4,scause
    800029b0:	47bd                	li	a5,15
    800029b2:	02f71f63          	bne	a4,a5,800029f0 <usertrap+0x166>
    800029b6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029ba:	5890                	lw	a2,48(s1)
    800029bc:	00007517          	auipc	a0,0x7
    800029c0:	98c50513          	addi	a0,a0,-1652 # 80009348 <states.0+0x78>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	bc6080e7          	jalr	-1082(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029cc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029d0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029d4:	00007517          	auipc	a0,0x7
    800029d8:	9a450513          	addi	a0,a0,-1628 # 80009378 <states.0+0xa8>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	bae080e7          	jalr	-1106(ra) # 8000058a <printf>
    setkilled(p);
    800029e4:	8526                	mv	a0,s1
    800029e6:	00000097          	auipc	ra,0x0
    800029ea:	990080e7          	jalr	-1648(ra) # 80002376 <setkilled>
    800029ee:	b791                	j	80002932 <usertrap+0xa8>
    trap_and_emulate();
    800029f0:	00004097          	auipc	ra,0x4
    800029f4:	000080e7          	jalr	ra # 800069f0 <trap_and_emulate>
    800029f8:	bf2d                	j	80002932 <usertrap+0xa8>
    yield();
    800029fa:	fffff097          	auipc	ra,0xfffff
    800029fe:	6c4080e7          	jalr	1732(ra) # 800020be <yield>
    80002a02:	b7b9                	j	80002950 <usertrap+0xc6>

0000000080002a04 <kerneltrap>:
{
    80002a04:	7179                	addi	sp,sp,-48
    80002a06:	f406                	sd	ra,40(sp)
    80002a08:	f022                	sd	s0,32(sp)
    80002a0a:	ec26                	sd	s1,24(sp)
    80002a0c:	e84a                	sd	s2,16(sp)
    80002a0e:	e44e                	sd	s3,8(sp)
    80002a10:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a12:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a16:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a1a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a1e:	1004f793          	andi	a5,s1,256
    80002a22:	cb85                	beqz	a5,80002a52 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a24:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a28:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a2a:	ef85                	bnez	a5,80002a62 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a2c:	00000097          	auipc	ra,0x0
    80002a30:	db8080e7          	jalr	-584(ra) # 800027e4 <devintr>
    80002a34:	cd1d                	beqz	a0,80002a72 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a36:	4789                	li	a5,2
    80002a38:	06f50a63          	beq	a0,a5,80002aac <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a3c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a40:	10049073          	csrw	sstatus,s1
}
    80002a44:	70a2                	ld	ra,40(sp)
    80002a46:	7402                	ld	s0,32(sp)
    80002a48:	64e2                	ld	s1,24(sp)
    80002a4a:	6942                	ld	s2,16(sp)
    80002a4c:	69a2                	ld	s3,8(sp)
    80002a4e:	6145                	addi	sp,sp,48
    80002a50:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a52:	00007517          	auipc	a0,0x7
    80002a56:	94650513          	addi	a0,a0,-1722 # 80009398 <states.0+0xc8>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	ae6080e7          	jalr	-1306(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a62:	00007517          	auipc	a0,0x7
    80002a66:	95e50513          	addi	a0,a0,-1698 # 800093c0 <states.0+0xf0>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	ad6080e7          	jalr	-1322(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002a72:	85ce                	mv	a1,s3
    80002a74:	00007517          	auipc	a0,0x7
    80002a78:	96c50513          	addi	a0,a0,-1684 # 800093e0 <states.0+0x110>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	b0e080e7          	jalr	-1266(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a84:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a88:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a8c:	00007517          	auipc	a0,0x7
    80002a90:	96450513          	addi	a0,a0,-1692 # 800093f0 <states.0+0x120>
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	af6080e7          	jalr	-1290(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a9c:	00007517          	auipc	a0,0x7
    80002aa0:	96c50513          	addi	a0,a0,-1684 # 80009408 <states.0+0x138>
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	a9c080e7          	jalr	-1380(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	f78080e7          	jalr	-136(ra) # 80001a24 <myproc>
    80002ab4:	d541                	beqz	a0,80002a3c <kerneltrap+0x38>
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	f6e080e7          	jalr	-146(ra) # 80001a24 <myproc>
    80002abe:	4d18                	lw	a4,24(a0)
    80002ac0:	4791                	li	a5,4
    80002ac2:	f6f71de3          	bne	a4,a5,80002a3c <kerneltrap+0x38>
    yield();
    80002ac6:	fffff097          	auipc	ra,0xfffff
    80002aca:	5f8080e7          	jalr	1528(ra) # 800020be <yield>
    80002ace:	b7bd                	j	80002a3c <kerneltrap+0x38>

0000000080002ad0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ad0:	1101                	addi	sp,sp,-32
    80002ad2:	ec06                	sd	ra,24(sp)
    80002ad4:	e822                	sd	s0,16(sp)
    80002ad6:	e426                	sd	s1,8(sp)
    80002ad8:	1000                	addi	s0,sp,32
    80002ada:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	f48080e7          	jalr	-184(ra) # 80001a24 <myproc>
  switch (n) {
    80002ae4:	4795                	li	a5,5
    80002ae6:	0497e163          	bltu	a5,s1,80002b28 <argraw+0x58>
    80002aea:	048a                	slli	s1,s1,0x2
    80002aec:	00007717          	auipc	a4,0x7
    80002af0:	95470713          	addi	a4,a4,-1708 # 80009440 <states.0+0x170>
    80002af4:	94ba                	add	s1,s1,a4
    80002af6:	409c                	lw	a5,0(s1)
    80002af8:	97ba                	add	a5,a5,a4
    80002afa:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002afc:	6d3c                	ld	a5,88(a0)
    80002afe:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b00:	60e2                	ld	ra,24(sp)
    80002b02:	6442                	ld	s0,16(sp)
    80002b04:	64a2                	ld	s1,8(sp)
    80002b06:	6105                	addi	sp,sp,32
    80002b08:	8082                	ret
    return p->trapframe->a1;
    80002b0a:	6d3c                	ld	a5,88(a0)
    80002b0c:	7fa8                	ld	a0,120(a5)
    80002b0e:	bfcd                	j	80002b00 <argraw+0x30>
    return p->trapframe->a2;
    80002b10:	6d3c                	ld	a5,88(a0)
    80002b12:	63c8                	ld	a0,128(a5)
    80002b14:	b7f5                	j	80002b00 <argraw+0x30>
    return p->trapframe->a3;
    80002b16:	6d3c                	ld	a5,88(a0)
    80002b18:	67c8                	ld	a0,136(a5)
    80002b1a:	b7dd                	j	80002b00 <argraw+0x30>
    return p->trapframe->a4;
    80002b1c:	6d3c                	ld	a5,88(a0)
    80002b1e:	6bc8                	ld	a0,144(a5)
    80002b20:	b7c5                	j	80002b00 <argraw+0x30>
    return p->trapframe->a5;
    80002b22:	6d3c                	ld	a5,88(a0)
    80002b24:	6fc8                	ld	a0,152(a5)
    80002b26:	bfe9                	j	80002b00 <argraw+0x30>
  panic("argraw");
    80002b28:	00007517          	auipc	a0,0x7
    80002b2c:	8f050513          	addi	a0,a0,-1808 # 80009418 <states.0+0x148>
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	a10080e7          	jalr	-1520(ra) # 80000540 <panic>

0000000080002b38 <fetchaddr>:
{
    80002b38:	1101                	addi	sp,sp,-32
    80002b3a:	ec06                	sd	ra,24(sp)
    80002b3c:	e822                	sd	s0,16(sp)
    80002b3e:	e426                	sd	s1,8(sp)
    80002b40:	e04a                	sd	s2,0(sp)
    80002b42:	1000                	addi	s0,sp,32
    80002b44:	84aa                	mv	s1,a0
    80002b46:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	edc080e7          	jalr	-292(ra) # 80001a24 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b50:	653c                	ld	a5,72(a0)
    80002b52:	02f4f863          	bgeu	s1,a5,80002b82 <fetchaddr+0x4a>
    80002b56:	00848713          	addi	a4,s1,8
    80002b5a:	02e7e663          	bltu	a5,a4,80002b86 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b5e:	46a1                	li	a3,8
    80002b60:	8626                	mv	a2,s1
    80002b62:	85ca                	mv	a1,s2
    80002b64:	6928                	ld	a0,80(a0)
    80002b66:	fffff097          	auipc	ra,0xfffff
    80002b6a:	c0a080e7          	jalr	-1014(ra) # 80001770 <copyin>
    80002b6e:	00a03533          	snez	a0,a0
    80002b72:	40a00533          	neg	a0,a0
}
    80002b76:	60e2                	ld	ra,24(sp)
    80002b78:	6442                	ld	s0,16(sp)
    80002b7a:	64a2                	ld	s1,8(sp)
    80002b7c:	6902                	ld	s2,0(sp)
    80002b7e:	6105                	addi	sp,sp,32
    80002b80:	8082                	ret
    return -1;
    80002b82:	557d                	li	a0,-1
    80002b84:	bfcd                	j	80002b76 <fetchaddr+0x3e>
    80002b86:	557d                	li	a0,-1
    80002b88:	b7fd                	j	80002b76 <fetchaddr+0x3e>

0000000080002b8a <fetchstr>:
{
    80002b8a:	7179                	addi	sp,sp,-48
    80002b8c:	f406                	sd	ra,40(sp)
    80002b8e:	f022                	sd	s0,32(sp)
    80002b90:	ec26                	sd	s1,24(sp)
    80002b92:	e84a                	sd	s2,16(sp)
    80002b94:	e44e                	sd	s3,8(sp)
    80002b96:	1800                	addi	s0,sp,48
    80002b98:	892a                	mv	s2,a0
    80002b9a:	84ae                	mv	s1,a1
    80002b9c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	e86080e7          	jalr	-378(ra) # 80001a24 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ba6:	86ce                	mv	a3,s3
    80002ba8:	864a                	mv	a2,s2
    80002baa:	85a6                	mv	a1,s1
    80002bac:	6928                	ld	a0,80(a0)
    80002bae:	fffff097          	auipc	ra,0xfffff
    80002bb2:	c50080e7          	jalr	-944(ra) # 800017fe <copyinstr>
    80002bb6:	00054e63          	bltz	a0,80002bd2 <fetchstr+0x48>
  return strlen(buf);
    80002bba:	8526                	mv	a0,s1
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	302080e7          	jalr	770(ra) # 80000ebe <strlen>
}
    80002bc4:	70a2                	ld	ra,40(sp)
    80002bc6:	7402                	ld	s0,32(sp)
    80002bc8:	64e2                	ld	s1,24(sp)
    80002bca:	6942                	ld	s2,16(sp)
    80002bcc:	69a2                	ld	s3,8(sp)
    80002bce:	6145                	addi	sp,sp,48
    80002bd0:	8082                	ret
    return -1;
    80002bd2:	557d                	li	a0,-1
    80002bd4:	bfc5                	j	80002bc4 <fetchstr+0x3a>

0000000080002bd6 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bd6:	1101                	addi	sp,sp,-32
    80002bd8:	ec06                	sd	ra,24(sp)
    80002bda:	e822                	sd	s0,16(sp)
    80002bdc:	e426                	sd	s1,8(sp)
    80002bde:	1000                	addi	s0,sp,32
    80002be0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002be2:	00000097          	auipc	ra,0x0
    80002be6:	eee080e7          	jalr	-274(ra) # 80002ad0 <argraw>
    80002bea:	c088                	sw	a0,0(s1)
}
    80002bec:	60e2                	ld	ra,24(sp)
    80002bee:	6442                	ld	s0,16(sp)
    80002bf0:	64a2                	ld	s1,8(sp)
    80002bf2:	6105                	addi	sp,sp,32
    80002bf4:	8082                	ret

0000000080002bf6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002bf6:	1101                	addi	sp,sp,-32
    80002bf8:	ec06                	sd	ra,24(sp)
    80002bfa:	e822                	sd	s0,16(sp)
    80002bfc:	e426                	sd	s1,8(sp)
    80002bfe:	1000                	addi	s0,sp,32
    80002c00:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c02:	00000097          	auipc	ra,0x0
    80002c06:	ece080e7          	jalr	-306(ra) # 80002ad0 <argraw>
    80002c0a:	e088                	sd	a0,0(s1)
}
    80002c0c:	60e2                	ld	ra,24(sp)
    80002c0e:	6442                	ld	s0,16(sp)
    80002c10:	64a2                	ld	s1,8(sp)
    80002c12:	6105                	addi	sp,sp,32
    80002c14:	8082                	ret

0000000080002c16 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c16:	7179                	addi	sp,sp,-48
    80002c18:	f406                	sd	ra,40(sp)
    80002c1a:	f022                	sd	s0,32(sp)
    80002c1c:	ec26                	sd	s1,24(sp)
    80002c1e:	e84a                	sd	s2,16(sp)
    80002c20:	1800                	addi	s0,sp,48
    80002c22:	84ae                	mv	s1,a1
    80002c24:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c26:	fd840593          	addi	a1,s0,-40
    80002c2a:	00000097          	auipc	ra,0x0
    80002c2e:	fcc080e7          	jalr	-52(ra) # 80002bf6 <argaddr>
  return fetchstr(addr, buf, max);
    80002c32:	864a                	mv	a2,s2
    80002c34:	85a6                	mv	a1,s1
    80002c36:	fd843503          	ld	a0,-40(s0)
    80002c3a:	00000097          	auipc	ra,0x0
    80002c3e:	f50080e7          	jalr	-176(ra) # 80002b8a <fetchstr>
}
    80002c42:	70a2                	ld	ra,40(sp)
    80002c44:	7402                	ld	s0,32(sp)
    80002c46:	64e2                	ld	s1,24(sp)
    80002c48:	6942                	ld	s2,16(sp)
    80002c4a:	6145                	addi	sp,sp,48
    80002c4c:	8082                	ret

0000000080002c4e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c4e:	1101                	addi	sp,sp,-32
    80002c50:	ec06                	sd	ra,24(sp)
    80002c52:	e822                	sd	s0,16(sp)
    80002c54:	e426                	sd	s1,8(sp)
    80002c56:	e04a                	sd	s2,0(sp)
    80002c58:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c5a:	fffff097          	auipc	ra,0xfffff
    80002c5e:	dca080e7          	jalr	-566(ra) # 80001a24 <myproc>
    80002c62:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c64:	05853903          	ld	s2,88(a0)
    80002c68:	0a893783          	ld	a5,168(s2)
    80002c6c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c70:	37fd                	addiw	a5,a5,-1
    80002c72:	4751                	li	a4,20
    80002c74:	00f76f63          	bltu	a4,a5,80002c92 <syscall+0x44>
    80002c78:	00369713          	slli	a4,a3,0x3
    80002c7c:	00006797          	auipc	a5,0x6
    80002c80:	7dc78793          	addi	a5,a5,2012 # 80009458 <syscalls>
    80002c84:	97ba                	add	a5,a5,a4
    80002c86:	639c                	ld	a5,0(a5)
    80002c88:	c789                	beqz	a5,80002c92 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c8a:	9782                	jalr	a5
    80002c8c:	06a93823          	sd	a0,112(s2)
    80002c90:	a839                	j	80002cae <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c92:	15848613          	addi	a2,s1,344
    80002c96:	588c                	lw	a1,48(s1)
    80002c98:	00006517          	auipc	a0,0x6
    80002c9c:	78850513          	addi	a0,a0,1928 # 80009420 <states.0+0x150>
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	8ea080e7          	jalr	-1814(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ca8:	6cbc                	ld	a5,88(s1)
    80002caa:	577d                	li	a4,-1
    80002cac:	fbb8                	sd	a4,112(a5)
  }
}
    80002cae:	60e2                	ld	ra,24(sp)
    80002cb0:	6442                	ld	s0,16(sp)
    80002cb2:	64a2                	ld	s1,8(sp)
    80002cb4:	6902                	ld	s2,0(sp)
    80002cb6:	6105                	addi	sp,sp,32
    80002cb8:	8082                	ret

0000000080002cba <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cba:	1101                	addi	sp,sp,-32
    80002cbc:	ec06                	sd	ra,24(sp)
    80002cbe:	e822                	sd	s0,16(sp)
    80002cc0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cc2:	fec40593          	addi	a1,s0,-20
    80002cc6:	4501                	li	a0,0
    80002cc8:	00000097          	auipc	ra,0x0
    80002ccc:	f0e080e7          	jalr	-242(ra) # 80002bd6 <argint>
  exit(n);
    80002cd0:	fec42503          	lw	a0,-20(s0)
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	55a080e7          	jalr	1370(ra) # 8000222e <exit>
  return 0;  // not reached
}
    80002cdc:	4501                	li	a0,0
    80002cde:	60e2                	ld	ra,24(sp)
    80002ce0:	6442                	ld	s0,16(sp)
    80002ce2:	6105                	addi	sp,sp,32
    80002ce4:	8082                	ret

0000000080002ce6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ce6:	1141                	addi	sp,sp,-16
    80002ce8:	e406                	sd	ra,8(sp)
    80002cea:	e022                	sd	s0,0(sp)
    80002cec:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	d36080e7          	jalr	-714(ra) # 80001a24 <myproc>
}
    80002cf6:	5908                	lw	a0,48(a0)
    80002cf8:	60a2                	ld	ra,8(sp)
    80002cfa:	6402                	ld	s0,0(sp)
    80002cfc:	0141                	addi	sp,sp,16
    80002cfe:	8082                	ret

0000000080002d00 <sys_fork>:

uint64
sys_fork(void)
{
    80002d00:	1141                	addi	sp,sp,-16
    80002d02:	e406                	sd	ra,8(sp)
    80002d04:	e022                	sd	s0,0(sp)
    80002d06:	0800                	addi	s0,sp,16
  return fork();
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	100080e7          	jalr	256(ra) # 80001e08 <fork>
}
    80002d10:	60a2                	ld	ra,8(sp)
    80002d12:	6402                	ld	s0,0(sp)
    80002d14:	0141                	addi	sp,sp,16
    80002d16:	8082                	ret

0000000080002d18 <sys_wait>:

uint64
sys_wait(void)
{
    80002d18:	1101                	addi	sp,sp,-32
    80002d1a:	ec06                	sd	ra,24(sp)
    80002d1c:	e822                	sd	s0,16(sp)
    80002d1e:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d20:	fe840593          	addi	a1,s0,-24
    80002d24:	4501                	li	a0,0
    80002d26:	00000097          	auipc	ra,0x0
    80002d2a:	ed0080e7          	jalr	-304(ra) # 80002bf6 <argaddr>
  return wait(p);
    80002d2e:	fe843503          	ld	a0,-24(s0)
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	6a2080e7          	jalr	1698(ra) # 800023d4 <wait>
}
    80002d3a:	60e2                	ld	ra,24(sp)
    80002d3c:	6442                	ld	s0,16(sp)
    80002d3e:	6105                	addi	sp,sp,32
    80002d40:	8082                	ret

0000000080002d42 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d42:	7179                	addi	sp,sp,-48
    80002d44:	f406                	sd	ra,40(sp)
    80002d46:	f022                	sd	s0,32(sp)
    80002d48:	ec26                	sd	s1,24(sp)
    80002d4a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d4c:	fdc40593          	addi	a1,s0,-36
    80002d50:	4501                	li	a0,0
    80002d52:	00000097          	auipc	ra,0x0
    80002d56:	e84080e7          	jalr	-380(ra) # 80002bd6 <argint>
  addr = myproc()->sz;
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	cca080e7          	jalr	-822(ra) # 80001a24 <myproc>
    80002d62:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d64:	fdc42503          	lw	a0,-36(s0)
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	044080e7          	jalr	68(ra) # 80001dac <growproc>
    80002d70:	00054863          	bltz	a0,80002d80 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d74:	8526                	mv	a0,s1
    80002d76:	70a2                	ld	ra,40(sp)
    80002d78:	7402                	ld	s0,32(sp)
    80002d7a:	64e2                	ld	s1,24(sp)
    80002d7c:	6145                	addi	sp,sp,48
    80002d7e:	8082                	ret
    return -1;
    80002d80:	54fd                	li	s1,-1
    80002d82:	bfcd                	j	80002d74 <sys_sbrk+0x32>

0000000080002d84 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d84:	7139                	addi	sp,sp,-64
    80002d86:	fc06                	sd	ra,56(sp)
    80002d88:	f822                	sd	s0,48(sp)
    80002d8a:	f426                	sd	s1,40(sp)
    80002d8c:	f04a                	sd	s2,32(sp)
    80002d8e:	ec4e                	sd	s3,24(sp)
    80002d90:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d92:	fcc40593          	addi	a1,s0,-52
    80002d96:	4501                	li	a0,0
    80002d98:	00000097          	auipc	ra,0x0
    80002d9c:	e3e080e7          	jalr	-450(ra) # 80002bd6 <argint>
  acquire(&tickslock);
    80002da0:	00015517          	auipc	a0,0x15
    80002da4:	14050513          	addi	a0,a0,320 # 80017ee0 <tickslock>
    80002da8:	ffffe097          	auipc	ra,0xffffe
    80002dac:	ea0080e7          	jalr	-352(ra) # 80000c48 <acquire>
  ticks0 = ticks;
    80002db0:	00007917          	auipc	s2,0x7
    80002db4:	e9092903          	lw	s2,-368(s2) # 80009c40 <ticks>
  while(ticks - ticks0 < n){
    80002db8:	fcc42783          	lw	a5,-52(s0)
    80002dbc:	cf9d                	beqz	a5,80002dfa <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dbe:	00015997          	auipc	s3,0x15
    80002dc2:	12298993          	addi	s3,s3,290 # 80017ee0 <tickslock>
    80002dc6:	00007497          	auipc	s1,0x7
    80002dca:	e7a48493          	addi	s1,s1,-390 # 80009c40 <ticks>
    if(killed(myproc())){
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	c56080e7          	jalr	-938(ra) # 80001a24 <myproc>
    80002dd6:	fffff097          	auipc	ra,0xfffff
    80002dda:	5cc080e7          	jalr	1484(ra) # 800023a2 <killed>
    80002dde:	ed15                	bnez	a0,80002e1a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002de0:	85ce                	mv	a1,s3
    80002de2:	8526                	mv	a0,s1
    80002de4:	fffff097          	auipc	ra,0xfffff
    80002de8:	316080e7          	jalr	790(ra) # 800020fa <sleep>
  while(ticks - ticks0 < n){
    80002dec:	409c                	lw	a5,0(s1)
    80002dee:	412787bb          	subw	a5,a5,s2
    80002df2:	fcc42703          	lw	a4,-52(s0)
    80002df6:	fce7ece3          	bltu	a5,a4,80002dce <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002dfa:	00015517          	auipc	a0,0x15
    80002dfe:	0e650513          	addi	a0,a0,230 # 80017ee0 <tickslock>
    80002e02:	ffffe097          	auipc	ra,0xffffe
    80002e06:	efa080e7          	jalr	-262(ra) # 80000cfc <release>
  return 0;
    80002e0a:	4501                	li	a0,0
}
    80002e0c:	70e2                	ld	ra,56(sp)
    80002e0e:	7442                	ld	s0,48(sp)
    80002e10:	74a2                	ld	s1,40(sp)
    80002e12:	7902                	ld	s2,32(sp)
    80002e14:	69e2                	ld	s3,24(sp)
    80002e16:	6121                	addi	sp,sp,64
    80002e18:	8082                	ret
      release(&tickslock);
    80002e1a:	00015517          	auipc	a0,0x15
    80002e1e:	0c650513          	addi	a0,a0,198 # 80017ee0 <tickslock>
    80002e22:	ffffe097          	auipc	ra,0xffffe
    80002e26:	eda080e7          	jalr	-294(ra) # 80000cfc <release>
      return -1;
    80002e2a:	557d                	li	a0,-1
    80002e2c:	b7c5                	j	80002e0c <sys_sleep+0x88>

0000000080002e2e <sys_kill>:

uint64
sys_kill(void)
{
    80002e2e:	1101                	addi	sp,sp,-32
    80002e30:	ec06                	sd	ra,24(sp)
    80002e32:	e822                	sd	s0,16(sp)
    80002e34:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e36:	fec40593          	addi	a1,s0,-20
    80002e3a:	4501                	li	a0,0
    80002e3c:	00000097          	auipc	ra,0x0
    80002e40:	d9a080e7          	jalr	-614(ra) # 80002bd6 <argint>
  return kill(pid);
    80002e44:	fec42503          	lw	a0,-20(s0)
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	4bc080e7          	jalr	1212(ra) # 80002304 <kill>
}
    80002e50:	60e2                	ld	ra,24(sp)
    80002e52:	6442                	ld	s0,16(sp)
    80002e54:	6105                	addi	sp,sp,32
    80002e56:	8082                	ret

0000000080002e58 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e58:	1101                	addi	sp,sp,-32
    80002e5a:	ec06                	sd	ra,24(sp)
    80002e5c:	e822                	sd	s0,16(sp)
    80002e5e:	e426                	sd	s1,8(sp)
    80002e60:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e62:	00015517          	auipc	a0,0x15
    80002e66:	07e50513          	addi	a0,a0,126 # 80017ee0 <tickslock>
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	dde080e7          	jalr	-546(ra) # 80000c48 <acquire>
  xticks = ticks;
    80002e72:	00007497          	auipc	s1,0x7
    80002e76:	dce4a483          	lw	s1,-562(s1) # 80009c40 <ticks>
  release(&tickslock);
    80002e7a:	00015517          	auipc	a0,0x15
    80002e7e:	06650513          	addi	a0,a0,102 # 80017ee0 <tickslock>
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	e7a080e7          	jalr	-390(ra) # 80000cfc <release>
  return xticks;
}
    80002e8a:	02049513          	slli	a0,s1,0x20
    80002e8e:	9101                	srli	a0,a0,0x20
    80002e90:	60e2                	ld	ra,24(sp)
    80002e92:	6442                	ld	s0,16(sp)
    80002e94:	64a2                	ld	s1,8(sp)
    80002e96:	6105                	addi	sp,sp,32
    80002e98:	8082                	ret

0000000080002e9a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e9a:	7179                	addi	sp,sp,-48
    80002e9c:	f406                	sd	ra,40(sp)
    80002e9e:	f022                	sd	s0,32(sp)
    80002ea0:	ec26                	sd	s1,24(sp)
    80002ea2:	e84a                	sd	s2,16(sp)
    80002ea4:	e44e                	sd	s3,8(sp)
    80002ea6:	e052                	sd	s4,0(sp)
    80002ea8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eaa:	00006597          	auipc	a1,0x6
    80002eae:	65e58593          	addi	a1,a1,1630 # 80009508 <syscalls+0xb0>
    80002eb2:	00015517          	auipc	a0,0x15
    80002eb6:	04650513          	addi	a0,a0,70 # 80017ef8 <bcache>
    80002eba:	ffffe097          	auipc	ra,0xffffe
    80002ebe:	cfe080e7          	jalr	-770(ra) # 80000bb8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ec2:	0001d797          	auipc	a5,0x1d
    80002ec6:	03678793          	addi	a5,a5,54 # 8001fef8 <bcache+0x8000>
    80002eca:	0001d717          	auipc	a4,0x1d
    80002ece:	29670713          	addi	a4,a4,662 # 80020160 <bcache+0x8268>
    80002ed2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ed6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eda:	00015497          	auipc	s1,0x15
    80002ede:	03648493          	addi	s1,s1,54 # 80017f10 <bcache+0x18>
    b->next = bcache.head.next;
    80002ee2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ee4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ee6:	00006a17          	auipc	s4,0x6
    80002eea:	62aa0a13          	addi	s4,s4,1578 # 80009510 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002eee:	2b893783          	ld	a5,696(s2)
    80002ef2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ef4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ef8:	85d2                	mv	a1,s4
    80002efa:	01048513          	addi	a0,s1,16
    80002efe:	00001097          	auipc	ra,0x1
    80002f02:	496080e7          	jalr	1174(ra) # 80004394 <initsleeplock>
    bcache.head.next->prev = b;
    80002f06:	2b893783          	ld	a5,696(s2)
    80002f0a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f0c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f10:	45848493          	addi	s1,s1,1112
    80002f14:	fd349de3          	bne	s1,s3,80002eee <binit+0x54>
  }
}
    80002f18:	70a2                	ld	ra,40(sp)
    80002f1a:	7402                	ld	s0,32(sp)
    80002f1c:	64e2                	ld	s1,24(sp)
    80002f1e:	6942                	ld	s2,16(sp)
    80002f20:	69a2                	ld	s3,8(sp)
    80002f22:	6a02                	ld	s4,0(sp)
    80002f24:	6145                	addi	sp,sp,48
    80002f26:	8082                	ret

0000000080002f28 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f28:	7179                	addi	sp,sp,-48
    80002f2a:	f406                	sd	ra,40(sp)
    80002f2c:	f022                	sd	s0,32(sp)
    80002f2e:	ec26                	sd	s1,24(sp)
    80002f30:	e84a                	sd	s2,16(sp)
    80002f32:	e44e                	sd	s3,8(sp)
    80002f34:	1800                	addi	s0,sp,48
    80002f36:	892a                	mv	s2,a0
    80002f38:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f3a:	00015517          	auipc	a0,0x15
    80002f3e:	fbe50513          	addi	a0,a0,-66 # 80017ef8 <bcache>
    80002f42:	ffffe097          	auipc	ra,0xffffe
    80002f46:	d06080e7          	jalr	-762(ra) # 80000c48 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f4a:	0001d497          	auipc	s1,0x1d
    80002f4e:	2664b483          	ld	s1,614(s1) # 800201b0 <bcache+0x82b8>
    80002f52:	0001d797          	auipc	a5,0x1d
    80002f56:	20e78793          	addi	a5,a5,526 # 80020160 <bcache+0x8268>
    80002f5a:	02f48f63          	beq	s1,a5,80002f98 <bread+0x70>
    80002f5e:	873e                	mv	a4,a5
    80002f60:	a021                	j	80002f68 <bread+0x40>
    80002f62:	68a4                	ld	s1,80(s1)
    80002f64:	02e48a63          	beq	s1,a4,80002f98 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f68:	449c                	lw	a5,8(s1)
    80002f6a:	ff279ce3          	bne	a5,s2,80002f62 <bread+0x3a>
    80002f6e:	44dc                	lw	a5,12(s1)
    80002f70:	ff3799e3          	bne	a5,s3,80002f62 <bread+0x3a>
      b->refcnt++;
    80002f74:	40bc                	lw	a5,64(s1)
    80002f76:	2785                	addiw	a5,a5,1
    80002f78:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f7a:	00015517          	auipc	a0,0x15
    80002f7e:	f7e50513          	addi	a0,a0,-130 # 80017ef8 <bcache>
    80002f82:	ffffe097          	auipc	ra,0xffffe
    80002f86:	d7a080e7          	jalr	-646(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002f8a:	01048513          	addi	a0,s1,16
    80002f8e:	00001097          	auipc	ra,0x1
    80002f92:	440080e7          	jalr	1088(ra) # 800043ce <acquiresleep>
      return b;
    80002f96:	a8b9                	j	80002ff4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f98:	0001d497          	auipc	s1,0x1d
    80002f9c:	2104b483          	ld	s1,528(s1) # 800201a8 <bcache+0x82b0>
    80002fa0:	0001d797          	auipc	a5,0x1d
    80002fa4:	1c078793          	addi	a5,a5,448 # 80020160 <bcache+0x8268>
    80002fa8:	00f48863          	beq	s1,a5,80002fb8 <bread+0x90>
    80002fac:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fae:	40bc                	lw	a5,64(s1)
    80002fb0:	cf81                	beqz	a5,80002fc8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fb2:	64a4                	ld	s1,72(s1)
    80002fb4:	fee49de3          	bne	s1,a4,80002fae <bread+0x86>
  panic("bget: no buffers");
    80002fb8:	00006517          	auipc	a0,0x6
    80002fbc:	56050513          	addi	a0,a0,1376 # 80009518 <syscalls+0xc0>
    80002fc0:	ffffd097          	auipc	ra,0xffffd
    80002fc4:	580080e7          	jalr	1408(ra) # 80000540 <panic>
      b->dev = dev;
    80002fc8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fcc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fd0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fd4:	4785                	li	a5,1
    80002fd6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fd8:	00015517          	auipc	a0,0x15
    80002fdc:	f2050513          	addi	a0,a0,-224 # 80017ef8 <bcache>
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	d1c080e7          	jalr	-740(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002fe8:	01048513          	addi	a0,s1,16
    80002fec:	00001097          	auipc	ra,0x1
    80002ff0:	3e2080e7          	jalr	994(ra) # 800043ce <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ff4:	409c                	lw	a5,0(s1)
    80002ff6:	cb89                	beqz	a5,80003008 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ff8:	8526                	mv	a0,s1
    80002ffa:	70a2                	ld	ra,40(sp)
    80002ffc:	7402                	ld	s0,32(sp)
    80002ffe:	64e2                	ld	s1,24(sp)
    80003000:	6942                	ld	s2,16(sp)
    80003002:	69a2                	ld	s3,8(sp)
    80003004:	6145                	addi	sp,sp,48
    80003006:	8082                	ret
    virtio_disk_rw(b, 0);
    80003008:	4581                	li	a1,0
    8000300a:	8526                	mv	a0,s1
    8000300c:	00003097          	auipc	ra,0x3
    80003010:	198080e7          	jalr	408(ra) # 800061a4 <virtio_disk_rw>
    b->valid = 1;
    80003014:	4785                	li	a5,1
    80003016:	c09c                	sw	a5,0(s1)
  return b;
    80003018:	b7c5                	j	80002ff8 <bread+0xd0>

000000008000301a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000301a:	1101                	addi	sp,sp,-32
    8000301c:	ec06                	sd	ra,24(sp)
    8000301e:	e822                	sd	s0,16(sp)
    80003020:	e426                	sd	s1,8(sp)
    80003022:	1000                	addi	s0,sp,32
    80003024:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003026:	0541                	addi	a0,a0,16
    80003028:	00001097          	auipc	ra,0x1
    8000302c:	440080e7          	jalr	1088(ra) # 80004468 <holdingsleep>
    80003030:	cd01                	beqz	a0,80003048 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003032:	4585                	li	a1,1
    80003034:	8526                	mv	a0,s1
    80003036:	00003097          	auipc	ra,0x3
    8000303a:	16e080e7          	jalr	366(ra) # 800061a4 <virtio_disk_rw>
}
    8000303e:	60e2                	ld	ra,24(sp)
    80003040:	6442                	ld	s0,16(sp)
    80003042:	64a2                	ld	s1,8(sp)
    80003044:	6105                	addi	sp,sp,32
    80003046:	8082                	ret
    panic("bwrite");
    80003048:	00006517          	auipc	a0,0x6
    8000304c:	4e850513          	addi	a0,a0,1256 # 80009530 <syscalls+0xd8>
    80003050:	ffffd097          	auipc	ra,0xffffd
    80003054:	4f0080e7          	jalr	1264(ra) # 80000540 <panic>

0000000080003058 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003058:	1101                	addi	sp,sp,-32
    8000305a:	ec06                	sd	ra,24(sp)
    8000305c:	e822                	sd	s0,16(sp)
    8000305e:	e426                	sd	s1,8(sp)
    80003060:	e04a                	sd	s2,0(sp)
    80003062:	1000                	addi	s0,sp,32
    80003064:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003066:	01050913          	addi	s2,a0,16
    8000306a:	854a                	mv	a0,s2
    8000306c:	00001097          	auipc	ra,0x1
    80003070:	3fc080e7          	jalr	1020(ra) # 80004468 <holdingsleep>
    80003074:	c925                	beqz	a0,800030e4 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003076:	854a                	mv	a0,s2
    80003078:	00001097          	auipc	ra,0x1
    8000307c:	3ac080e7          	jalr	940(ra) # 80004424 <releasesleep>

  acquire(&bcache.lock);
    80003080:	00015517          	auipc	a0,0x15
    80003084:	e7850513          	addi	a0,a0,-392 # 80017ef8 <bcache>
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	bc0080e7          	jalr	-1088(ra) # 80000c48 <acquire>
  b->refcnt--;
    80003090:	40bc                	lw	a5,64(s1)
    80003092:	37fd                	addiw	a5,a5,-1
    80003094:	0007871b          	sext.w	a4,a5
    80003098:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000309a:	e71d                	bnez	a4,800030c8 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000309c:	68b8                	ld	a4,80(s1)
    8000309e:	64bc                	ld	a5,72(s1)
    800030a0:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    800030a2:	68b8                	ld	a4,80(s1)
    800030a4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030a6:	0001d797          	auipc	a5,0x1d
    800030aa:	e5278793          	addi	a5,a5,-430 # 8001fef8 <bcache+0x8000>
    800030ae:	2b87b703          	ld	a4,696(a5)
    800030b2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030b4:	0001d717          	auipc	a4,0x1d
    800030b8:	0ac70713          	addi	a4,a4,172 # 80020160 <bcache+0x8268>
    800030bc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030be:	2b87b703          	ld	a4,696(a5)
    800030c2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030c4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030c8:	00015517          	auipc	a0,0x15
    800030cc:	e3050513          	addi	a0,a0,-464 # 80017ef8 <bcache>
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	c2c080e7          	jalr	-980(ra) # 80000cfc <release>
}
    800030d8:	60e2                	ld	ra,24(sp)
    800030da:	6442                	ld	s0,16(sp)
    800030dc:	64a2                	ld	s1,8(sp)
    800030de:	6902                	ld	s2,0(sp)
    800030e0:	6105                	addi	sp,sp,32
    800030e2:	8082                	ret
    panic("brelse");
    800030e4:	00006517          	auipc	a0,0x6
    800030e8:	45450513          	addi	a0,a0,1108 # 80009538 <syscalls+0xe0>
    800030ec:	ffffd097          	auipc	ra,0xffffd
    800030f0:	454080e7          	jalr	1108(ra) # 80000540 <panic>

00000000800030f4 <bpin>:

void
bpin(struct buf *b) {
    800030f4:	1101                	addi	sp,sp,-32
    800030f6:	ec06                	sd	ra,24(sp)
    800030f8:	e822                	sd	s0,16(sp)
    800030fa:	e426                	sd	s1,8(sp)
    800030fc:	1000                	addi	s0,sp,32
    800030fe:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003100:	00015517          	auipc	a0,0x15
    80003104:	df850513          	addi	a0,a0,-520 # 80017ef8 <bcache>
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	b40080e7          	jalr	-1216(ra) # 80000c48 <acquire>
  b->refcnt++;
    80003110:	40bc                	lw	a5,64(s1)
    80003112:	2785                	addiw	a5,a5,1
    80003114:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003116:	00015517          	auipc	a0,0x15
    8000311a:	de250513          	addi	a0,a0,-542 # 80017ef8 <bcache>
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	bde080e7          	jalr	-1058(ra) # 80000cfc <release>
}
    80003126:	60e2                	ld	ra,24(sp)
    80003128:	6442                	ld	s0,16(sp)
    8000312a:	64a2                	ld	s1,8(sp)
    8000312c:	6105                	addi	sp,sp,32
    8000312e:	8082                	ret

0000000080003130 <bunpin>:

void
bunpin(struct buf *b) {
    80003130:	1101                	addi	sp,sp,-32
    80003132:	ec06                	sd	ra,24(sp)
    80003134:	e822                	sd	s0,16(sp)
    80003136:	e426                	sd	s1,8(sp)
    80003138:	1000                	addi	s0,sp,32
    8000313a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000313c:	00015517          	auipc	a0,0x15
    80003140:	dbc50513          	addi	a0,a0,-580 # 80017ef8 <bcache>
    80003144:	ffffe097          	auipc	ra,0xffffe
    80003148:	b04080e7          	jalr	-1276(ra) # 80000c48 <acquire>
  b->refcnt--;
    8000314c:	40bc                	lw	a5,64(s1)
    8000314e:	37fd                	addiw	a5,a5,-1
    80003150:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003152:	00015517          	auipc	a0,0x15
    80003156:	da650513          	addi	a0,a0,-602 # 80017ef8 <bcache>
    8000315a:	ffffe097          	auipc	ra,0xffffe
    8000315e:	ba2080e7          	jalr	-1118(ra) # 80000cfc <release>
}
    80003162:	60e2                	ld	ra,24(sp)
    80003164:	6442                	ld	s0,16(sp)
    80003166:	64a2                	ld	s1,8(sp)
    80003168:	6105                	addi	sp,sp,32
    8000316a:	8082                	ret

000000008000316c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000316c:	1101                	addi	sp,sp,-32
    8000316e:	ec06                	sd	ra,24(sp)
    80003170:	e822                	sd	s0,16(sp)
    80003172:	e426                	sd	s1,8(sp)
    80003174:	e04a                	sd	s2,0(sp)
    80003176:	1000                	addi	s0,sp,32
    80003178:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000317a:	00d5d59b          	srliw	a1,a1,0xd
    8000317e:	0001d797          	auipc	a5,0x1d
    80003182:	4567a783          	lw	a5,1110(a5) # 800205d4 <sb+0x1c>
    80003186:	9dbd                	addw	a1,a1,a5
    80003188:	00000097          	auipc	ra,0x0
    8000318c:	da0080e7          	jalr	-608(ra) # 80002f28 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003190:	0074f713          	andi	a4,s1,7
    80003194:	4785                	li	a5,1
    80003196:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000319a:	14ce                	slli	s1,s1,0x33
    8000319c:	90d9                	srli	s1,s1,0x36
    8000319e:	00950733          	add	a4,a0,s1
    800031a2:	05874703          	lbu	a4,88(a4)
    800031a6:	00e7f6b3          	and	a3,a5,a4
    800031aa:	c69d                	beqz	a3,800031d8 <bfree+0x6c>
    800031ac:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031ae:	94aa                	add	s1,s1,a0
    800031b0:	fff7c793          	not	a5,a5
    800031b4:	8f7d                	and	a4,a4,a5
    800031b6:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031ba:	00001097          	auipc	ra,0x1
    800031be:	0f6080e7          	jalr	246(ra) # 800042b0 <log_write>
  brelse(bp);
    800031c2:	854a                	mv	a0,s2
    800031c4:	00000097          	auipc	ra,0x0
    800031c8:	e94080e7          	jalr	-364(ra) # 80003058 <brelse>
}
    800031cc:	60e2                	ld	ra,24(sp)
    800031ce:	6442                	ld	s0,16(sp)
    800031d0:	64a2                	ld	s1,8(sp)
    800031d2:	6902                	ld	s2,0(sp)
    800031d4:	6105                	addi	sp,sp,32
    800031d6:	8082                	ret
    panic("freeing free block");
    800031d8:	00006517          	auipc	a0,0x6
    800031dc:	36850513          	addi	a0,a0,872 # 80009540 <syscalls+0xe8>
    800031e0:	ffffd097          	auipc	ra,0xffffd
    800031e4:	360080e7          	jalr	864(ra) # 80000540 <panic>

00000000800031e8 <balloc>:
{
    800031e8:	711d                	addi	sp,sp,-96
    800031ea:	ec86                	sd	ra,88(sp)
    800031ec:	e8a2                	sd	s0,80(sp)
    800031ee:	e4a6                	sd	s1,72(sp)
    800031f0:	e0ca                	sd	s2,64(sp)
    800031f2:	fc4e                	sd	s3,56(sp)
    800031f4:	f852                	sd	s4,48(sp)
    800031f6:	f456                	sd	s5,40(sp)
    800031f8:	f05a                	sd	s6,32(sp)
    800031fa:	ec5e                	sd	s7,24(sp)
    800031fc:	e862                	sd	s8,16(sp)
    800031fe:	e466                	sd	s9,8(sp)
    80003200:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003202:	0001d797          	auipc	a5,0x1d
    80003206:	3ba7a783          	lw	a5,954(a5) # 800205bc <sb+0x4>
    8000320a:	cff5                	beqz	a5,80003306 <balloc+0x11e>
    8000320c:	8baa                	mv	s7,a0
    8000320e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003210:	0001db17          	auipc	s6,0x1d
    80003214:	3a8b0b13          	addi	s6,s6,936 # 800205b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003218:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000321a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000321c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000321e:	6c89                	lui	s9,0x2
    80003220:	a061                	j	800032a8 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003222:	97ca                	add	a5,a5,s2
    80003224:	8e55                	or	a2,a2,a3
    80003226:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000322a:	854a                	mv	a0,s2
    8000322c:	00001097          	auipc	ra,0x1
    80003230:	084080e7          	jalr	132(ra) # 800042b0 <log_write>
        brelse(bp);
    80003234:	854a                	mv	a0,s2
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	e22080e7          	jalr	-478(ra) # 80003058 <brelse>
  bp = bread(dev, bno);
    8000323e:	85a6                	mv	a1,s1
    80003240:	855e                	mv	a0,s7
    80003242:	00000097          	auipc	ra,0x0
    80003246:	ce6080e7          	jalr	-794(ra) # 80002f28 <bread>
    8000324a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000324c:	40000613          	li	a2,1024
    80003250:	4581                	li	a1,0
    80003252:	05850513          	addi	a0,a0,88
    80003256:	ffffe097          	auipc	ra,0xffffe
    8000325a:	aee080e7          	jalr	-1298(ra) # 80000d44 <memset>
  log_write(bp);
    8000325e:	854a                	mv	a0,s2
    80003260:	00001097          	auipc	ra,0x1
    80003264:	050080e7          	jalr	80(ra) # 800042b0 <log_write>
  brelse(bp);
    80003268:	854a                	mv	a0,s2
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	dee080e7          	jalr	-530(ra) # 80003058 <brelse>
}
    80003272:	8526                	mv	a0,s1
    80003274:	60e6                	ld	ra,88(sp)
    80003276:	6446                	ld	s0,80(sp)
    80003278:	64a6                	ld	s1,72(sp)
    8000327a:	6906                	ld	s2,64(sp)
    8000327c:	79e2                	ld	s3,56(sp)
    8000327e:	7a42                	ld	s4,48(sp)
    80003280:	7aa2                	ld	s5,40(sp)
    80003282:	7b02                	ld	s6,32(sp)
    80003284:	6be2                	ld	s7,24(sp)
    80003286:	6c42                	ld	s8,16(sp)
    80003288:	6ca2                	ld	s9,8(sp)
    8000328a:	6125                	addi	sp,sp,96
    8000328c:	8082                	ret
    brelse(bp);
    8000328e:	854a                	mv	a0,s2
    80003290:	00000097          	auipc	ra,0x0
    80003294:	dc8080e7          	jalr	-568(ra) # 80003058 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003298:	015c87bb          	addw	a5,s9,s5
    8000329c:	00078a9b          	sext.w	s5,a5
    800032a0:	004b2703          	lw	a4,4(s6)
    800032a4:	06eaf163          	bgeu	s5,a4,80003306 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800032a8:	41fad79b          	sraiw	a5,s5,0x1f
    800032ac:	0137d79b          	srliw	a5,a5,0x13
    800032b0:	015787bb          	addw	a5,a5,s5
    800032b4:	40d7d79b          	sraiw	a5,a5,0xd
    800032b8:	01cb2583          	lw	a1,28(s6)
    800032bc:	9dbd                	addw	a1,a1,a5
    800032be:	855e                	mv	a0,s7
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	c68080e7          	jalr	-920(ra) # 80002f28 <bread>
    800032c8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ca:	004b2503          	lw	a0,4(s6)
    800032ce:	000a849b          	sext.w	s1,s5
    800032d2:	8762                	mv	a4,s8
    800032d4:	faa4fde3          	bgeu	s1,a0,8000328e <balloc+0xa6>
      m = 1 << (bi % 8);
    800032d8:	00777693          	andi	a3,a4,7
    800032dc:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032e0:	41f7579b          	sraiw	a5,a4,0x1f
    800032e4:	01d7d79b          	srliw	a5,a5,0x1d
    800032e8:	9fb9                	addw	a5,a5,a4
    800032ea:	4037d79b          	sraiw	a5,a5,0x3
    800032ee:	00f90633          	add	a2,s2,a5
    800032f2:	05864603          	lbu	a2,88(a2)
    800032f6:	00c6f5b3          	and	a1,a3,a2
    800032fa:	d585                	beqz	a1,80003222 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032fc:	2705                	addiw	a4,a4,1
    800032fe:	2485                	addiw	s1,s1,1
    80003300:	fd471ae3          	bne	a4,s4,800032d4 <balloc+0xec>
    80003304:	b769                	j	8000328e <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003306:	00006517          	auipc	a0,0x6
    8000330a:	25250513          	addi	a0,a0,594 # 80009558 <syscalls+0x100>
    8000330e:	ffffd097          	auipc	ra,0xffffd
    80003312:	27c080e7          	jalr	636(ra) # 8000058a <printf>
  return 0;
    80003316:	4481                	li	s1,0
    80003318:	bfa9                	j	80003272 <balloc+0x8a>

000000008000331a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000331a:	7179                	addi	sp,sp,-48
    8000331c:	f406                	sd	ra,40(sp)
    8000331e:	f022                	sd	s0,32(sp)
    80003320:	ec26                	sd	s1,24(sp)
    80003322:	e84a                	sd	s2,16(sp)
    80003324:	e44e                	sd	s3,8(sp)
    80003326:	e052                	sd	s4,0(sp)
    80003328:	1800                	addi	s0,sp,48
    8000332a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000332c:	47ad                	li	a5,11
    8000332e:	02b7e863          	bltu	a5,a1,8000335e <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003332:	02059793          	slli	a5,a1,0x20
    80003336:	01e7d593          	srli	a1,a5,0x1e
    8000333a:	00b504b3          	add	s1,a0,a1
    8000333e:	0504a903          	lw	s2,80(s1)
    80003342:	06091e63          	bnez	s2,800033be <bmap+0xa4>
      addr = balloc(ip->dev);
    80003346:	4108                	lw	a0,0(a0)
    80003348:	00000097          	auipc	ra,0x0
    8000334c:	ea0080e7          	jalr	-352(ra) # 800031e8 <balloc>
    80003350:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003354:	06090563          	beqz	s2,800033be <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003358:	0524a823          	sw	s2,80(s1)
    8000335c:	a08d                	j	800033be <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000335e:	ff45849b          	addiw	s1,a1,-12
    80003362:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003366:	0ff00793          	li	a5,255
    8000336a:	08e7e563          	bltu	a5,a4,800033f4 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000336e:	08052903          	lw	s2,128(a0)
    80003372:	00091d63          	bnez	s2,8000338c <bmap+0x72>
      addr = balloc(ip->dev);
    80003376:	4108                	lw	a0,0(a0)
    80003378:	00000097          	auipc	ra,0x0
    8000337c:	e70080e7          	jalr	-400(ra) # 800031e8 <balloc>
    80003380:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003384:	02090d63          	beqz	s2,800033be <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003388:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000338c:	85ca                	mv	a1,s2
    8000338e:	0009a503          	lw	a0,0(s3)
    80003392:	00000097          	auipc	ra,0x0
    80003396:	b96080e7          	jalr	-1130(ra) # 80002f28 <bread>
    8000339a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000339c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033a0:	02049713          	slli	a4,s1,0x20
    800033a4:	01e75593          	srli	a1,a4,0x1e
    800033a8:	00b784b3          	add	s1,a5,a1
    800033ac:	0004a903          	lw	s2,0(s1)
    800033b0:	02090063          	beqz	s2,800033d0 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033b4:	8552                	mv	a0,s4
    800033b6:	00000097          	auipc	ra,0x0
    800033ba:	ca2080e7          	jalr	-862(ra) # 80003058 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033be:	854a                	mv	a0,s2
    800033c0:	70a2                	ld	ra,40(sp)
    800033c2:	7402                	ld	s0,32(sp)
    800033c4:	64e2                	ld	s1,24(sp)
    800033c6:	6942                	ld	s2,16(sp)
    800033c8:	69a2                	ld	s3,8(sp)
    800033ca:	6a02                	ld	s4,0(sp)
    800033cc:	6145                	addi	sp,sp,48
    800033ce:	8082                	ret
      addr = balloc(ip->dev);
    800033d0:	0009a503          	lw	a0,0(s3)
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	e14080e7          	jalr	-492(ra) # 800031e8 <balloc>
    800033dc:	0005091b          	sext.w	s2,a0
      if(addr){
    800033e0:	fc090ae3          	beqz	s2,800033b4 <bmap+0x9a>
        a[bn] = addr;
    800033e4:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800033e8:	8552                	mv	a0,s4
    800033ea:	00001097          	auipc	ra,0x1
    800033ee:	ec6080e7          	jalr	-314(ra) # 800042b0 <log_write>
    800033f2:	b7c9                	j	800033b4 <bmap+0x9a>
  panic("bmap: out of range");
    800033f4:	00006517          	auipc	a0,0x6
    800033f8:	17c50513          	addi	a0,a0,380 # 80009570 <syscalls+0x118>
    800033fc:	ffffd097          	auipc	ra,0xffffd
    80003400:	144080e7          	jalr	324(ra) # 80000540 <panic>

0000000080003404 <iget>:
{
    80003404:	7179                	addi	sp,sp,-48
    80003406:	f406                	sd	ra,40(sp)
    80003408:	f022                	sd	s0,32(sp)
    8000340a:	ec26                	sd	s1,24(sp)
    8000340c:	e84a                	sd	s2,16(sp)
    8000340e:	e44e                	sd	s3,8(sp)
    80003410:	e052                	sd	s4,0(sp)
    80003412:	1800                	addi	s0,sp,48
    80003414:	89aa                	mv	s3,a0
    80003416:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003418:	0001d517          	auipc	a0,0x1d
    8000341c:	1c050513          	addi	a0,a0,448 # 800205d8 <itable>
    80003420:	ffffe097          	auipc	ra,0xffffe
    80003424:	828080e7          	jalr	-2008(ra) # 80000c48 <acquire>
  empty = 0;
    80003428:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000342a:	0001d497          	auipc	s1,0x1d
    8000342e:	1c648493          	addi	s1,s1,454 # 800205f0 <itable+0x18>
    80003432:	0001f697          	auipc	a3,0x1f
    80003436:	c4e68693          	addi	a3,a3,-946 # 80022080 <log>
    8000343a:	a039                	j	80003448 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000343c:	02090b63          	beqz	s2,80003472 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003440:	08848493          	addi	s1,s1,136
    80003444:	02d48a63          	beq	s1,a3,80003478 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003448:	449c                	lw	a5,8(s1)
    8000344a:	fef059e3          	blez	a5,8000343c <iget+0x38>
    8000344e:	4098                	lw	a4,0(s1)
    80003450:	ff3716e3          	bne	a4,s3,8000343c <iget+0x38>
    80003454:	40d8                	lw	a4,4(s1)
    80003456:	ff4713e3          	bne	a4,s4,8000343c <iget+0x38>
      ip->ref++;
    8000345a:	2785                	addiw	a5,a5,1
    8000345c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000345e:	0001d517          	auipc	a0,0x1d
    80003462:	17a50513          	addi	a0,a0,378 # 800205d8 <itable>
    80003466:	ffffe097          	auipc	ra,0xffffe
    8000346a:	896080e7          	jalr	-1898(ra) # 80000cfc <release>
      return ip;
    8000346e:	8926                	mv	s2,s1
    80003470:	a03d                	j	8000349e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003472:	f7f9                	bnez	a5,80003440 <iget+0x3c>
    80003474:	8926                	mv	s2,s1
    80003476:	b7e9                	j	80003440 <iget+0x3c>
  if(empty == 0)
    80003478:	02090c63          	beqz	s2,800034b0 <iget+0xac>
  ip->dev = dev;
    8000347c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003480:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003484:	4785                	li	a5,1
    80003486:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000348a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000348e:	0001d517          	auipc	a0,0x1d
    80003492:	14a50513          	addi	a0,a0,330 # 800205d8 <itable>
    80003496:	ffffe097          	auipc	ra,0xffffe
    8000349a:	866080e7          	jalr	-1946(ra) # 80000cfc <release>
}
    8000349e:	854a                	mv	a0,s2
    800034a0:	70a2                	ld	ra,40(sp)
    800034a2:	7402                	ld	s0,32(sp)
    800034a4:	64e2                	ld	s1,24(sp)
    800034a6:	6942                	ld	s2,16(sp)
    800034a8:	69a2                	ld	s3,8(sp)
    800034aa:	6a02                	ld	s4,0(sp)
    800034ac:	6145                	addi	sp,sp,48
    800034ae:	8082                	ret
    panic("iget: no inodes");
    800034b0:	00006517          	auipc	a0,0x6
    800034b4:	0d850513          	addi	a0,a0,216 # 80009588 <syscalls+0x130>
    800034b8:	ffffd097          	auipc	ra,0xffffd
    800034bc:	088080e7          	jalr	136(ra) # 80000540 <panic>

00000000800034c0 <fsinit>:
fsinit(int dev) {
    800034c0:	7179                	addi	sp,sp,-48
    800034c2:	f406                	sd	ra,40(sp)
    800034c4:	f022                	sd	s0,32(sp)
    800034c6:	ec26                	sd	s1,24(sp)
    800034c8:	e84a                	sd	s2,16(sp)
    800034ca:	e44e                	sd	s3,8(sp)
    800034cc:	1800                	addi	s0,sp,48
    800034ce:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034d0:	4585                	li	a1,1
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	a56080e7          	jalr	-1450(ra) # 80002f28 <bread>
    800034da:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034dc:	0001d997          	auipc	s3,0x1d
    800034e0:	0dc98993          	addi	s3,s3,220 # 800205b8 <sb>
    800034e4:	02000613          	li	a2,32
    800034e8:	05850593          	addi	a1,a0,88
    800034ec:	854e                	mv	a0,s3
    800034ee:	ffffe097          	auipc	ra,0xffffe
    800034f2:	8b2080e7          	jalr	-1870(ra) # 80000da0 <memmove>
  brelse(bp);
    800034f6:	8526                	mv	a0,s1
    800034f8:	00000097          	auipc	ra,0x0
    800034fc:	b60080e7          	jalr	-1184(ra) # 80003058 <brelse>
  if(sb.magic != FSMAGIC)
    80003500:	0009a703          	lw	a4,0(s3)
    80003504:	102037b7          	lui	a5,0x10203
    80003508:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000350c:	02f71263          	bne	a4,a5,80003530 <fsinit+0x70>
  initlog(dev, &sb);
    80003510:	0001d597          	auipc	a1,0x1d
    80003514:	0a858593          	addi	a1,a1,168 # 800205b8 <sb>
    80003518:	854a                	mv	a0,s2
    8000351a:	00001097          	auipc	ra,0x1
    8000351e:	b2c080e7          	jalr	-1236(ra) # 80004046 <initlog>
}
    80003522:	70a2                	ld	ra,40(sp)
    80003524:	7402                	ld	s0,32(sp)
    80003526:	64e2                	ld	s1,24(sp)
    80003528:	6942                	ld	s2,16(sp)
    8000352a:	69a2                	ld	s3,8(sp)
    8000352c:	6145                	addi	sp,sp,48
    8000352e:	8082                	ret
    panic("invalid file system");
    80003530:	00006517          	auipc	a0,0x6
    80003534:	06850513          	addi	a0,a0,104 # 80009598 <syscalls+0x140>
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	008080e7          	jalr	8(ra) # 80000540 <panic>

0000000080003540 <iinit>:
{
    80003540:	7179                	addi	sp,sp,-48
    80003542:	f406                	sd	ra,40(sp)
    80003544:	f022                	sd	s0,32(sp)
    80003546:	ec26                	sd	s1,24(sp)
    80003548:	e84a                	sd	s2,16(sp)
    8000354a:	e44e                	sd	s3,8(sp)
    8000354c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000354e:	00006597          	auipc	a1,0x6
    80003552:	06258593          	addi	a1,a1,98 # 800095b0 <syscalls+0x158>
    80003556:	0001d517          	auipc	a0,0x1d
    8000355a:	08250513          	addi	a0,a0,130 # 800205d8 <itable>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	65a080e7          	jalr	1626(ra) # 80000bb8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003566:	0001d497          	auipc	s1,0x1d
    8000356a:	09a48493          	addi	s1,s1,154 # 80020600 <itable+0x28>
    8000356e:	0001f997          	auipc	s3,0x1f
    80003572:	b2298993          	addi	s3,s3,-1246 # 80022090 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003576:	00006917          	auipc	s2,0x6
    8000357a:	04290913          	addi	s2,s2,66 # 800095b8 <syscalls+0x160>
    8000357e:	85ca                	mv	a1,s2
    80003580:	8526                	mv	a0,s1
    80003582:	00001097          	auipc	ra,0x1
    80003586:	e12080e7          	jalr	-494(ra) # 80004394 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000358a:	08848493          	addi	s1,s1,136
    8000358e:	ff3498e3          	bne	s1,s3,8000357e <iinit+0x3e>
}
    80003592:	70a2                	ld	ra,40(sp)
    80003594:	7402                	ld	s0,32(sp)
    80003596:	64e2                	ld	s1,24(sp)
    80003598:	6942                	ld	s2,16(sp)
    8000359a:	69a2                	ld	s3,8(sp)
    8000359c:	6145                	addi	sp,sp,48
    8000359e:	8082                	ret

00000000800035a0 <ialloc>:
{
    800035a0:	7139                	addi	sp,sp,-64
    800035a2:	fc06                	sd	ra,56(sp)
    800035a4:	f822                	sd	s0,48(sp)
    800035a6:	f426                	sd	s1,40(sp)
    800035a8:	f04a                	sd	s2,32(sp)
    800035aa:	ec4e                	sd	s3,24(sp)
    800035ac:	e852                	sd	s4,16(sp)
    800035ae:	e456                	sd	s5,8(sp)
    800035b0:	e05a                	sd	s6,0(sp)
    800035b2:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800035b4:	0001d717          	auipc	a4,0x1d
    800035b8:	01072703          	lw	a4,16(a4) # 800205c4 <sb+0xc>
    800035bc:	4785                	li	a5,1
    800035be:	04e7f863          	bgeu	a5,a4,8000360e <ialloc+0x6e>
    800035c2:	8aaa                	mv	s5,a0
    800035c4:	8b2e                	mv	s6,a1
    800035c6:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035c8:	0001da17          	auipc	s4,0x1d
    800035cc:	ff0a0a13          	addi	s4,s4,-16 # 800205b8 <sb>
    800035d0:	00495593          	srli	a1,s2,0x4
    800035d4:	018a2783          	lw	a5,24(s4)
    800035d8:	9dbd                	addw	a1,a1,a5
    800035da:	8556                	mv	a0,s5
    800035dc:	00000097          	auipc	ra,0x0
    800035e0:	94c080e7          	jalr	-1716(ra) # 80002f28 <bread>
    800035e4:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035e6:	05850993          	addi	s3,a0,88
    800035ea:	00f97793          	andi	a5,s2,15
    800035ee:	079a                	slli	a5,a5,0x6
    800035f0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035f2:	00099783          	lh	a5,0(s3)
    800035f6:	cf9d                	beqz	a5,80003634 <ialloc+0x94>
    brelse(bp);
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	a60080e7          	jalr	-1440(ra) # 80003058 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003600:	0905                	addi	s2,s2,1
    80003602:	00ca2703          	lw	a4,12(s4)
    80003606:	0009079b          	sext.w	a5,s2
    8000360a:	fce7e3e3          	bltu	a5,a4,800035d0 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    8000360e:	00006517          	auipc	a0,0x6
    80003612:	fb250513          	addi	a0,a0,-78 # 800095c0 <syscalls+0x168>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	f74080e7          	jalr	-140(ra) # 8000058a <printf>
  return 0;
    8000361e:	4501                	li	a0,0
}
    80003620:	70e2                	ld	ra,56(sp)
    80003622:	7442                	ld	s0,48(sp)
    80003624:	74a2                	ld	s1,40(sp)
    80003626:	7902                	ld	s2,32(sp)
    80003628:	69e2                	ld	s3,24(sp)
    8000362a:	6a42                	ld	s4,16(sp)
    8000362c:	6aa2                	ld	s5,8(sp)
    8000362e:	6b02                	ld	s6,0(sp)
    80003630:	6121                	addi	sp,sp,64
    80003632:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003634:	04000613          	li	a2,64
    80003638:	4581                	li	a1,0
    8000363a:	854e                	mv	a0,s3
    8000363c:	ffffd097          	auipc	ra,0xffffd
    80003640:	708080e7          	jalr	1800(ra) # 80000d44 <memset>
      dip->type = type;
    80003644:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003648:	8526                	mv	a0,s1
    8000364a:	00001097          	auipc	ra,0x1
    8000364e:	c66080e7          	jalr	-922(ra) # 800042b0 <log_write>
      brelse(bp);
    80003652:	8526                	mv	a0,s1
    80003654:	00000097          	auipc	ra,0x0
    80003658:	a04080e7          	jalr	-1532(ra) # 80003058 <brelse>
      return iget(dev, inum);
    8000365c:	0009059b          	sext.w	a1,s2
    80003660:	8556                	mv	a0,s5
    80003662:	00000097          	auipc	ra,0x0
    80003666:	da2080e7          	jalr	-606(ra) # 80003404 <iget>
    8000366a:	bf5d                	j	80003620 <ialloc+0x80>

000000008000366c <iupdate>:
{
    8000366c:	1101                	addi	sp,sp,-32
    8000366e:	ec06                	sd	ra,24(sp)
    80003670:	e822                	sd	s0,16(sp)
    80003672:	e426                	sd	s1,8(sp)
    80003674:	e04a                	sd	s2,0(sp)
    80003676:	1000                	addi	s0,sp,32
    80003678:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000367a:	415c                	lw	a5,4(a0)
    8000367c:	0047d79b          	srliw	a5,a5,0x4
    80003680:	0001d597          	auipc	a1,0x1d
    80003684:	f505a583          	lw	a1,-176(a1) # 800205d0 <sb+0x18>
    80003688:	9dbd                	addw	a1,a1,a5
    8000368a:	4108                	lw	a0,0(a0)
    8000368c:	00000097          	auipc	ra,0x0
    80003690:	89c080e7          	jalr	-1892(ra) # 80002f28 <bread>
    80003694:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003696:	05850793          	addi	a5,a0,88
    8000369a:	40d8                	lw	a4,4(s1)
    8000369c:	8b3d                	andi	a4,a4,15
    8000369e:	071a                	slli	a4,a4,0x6
    800036a0:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800036a2:	04449703          	lh	a4,68(s1)
    800036a6:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036aa:	04649703          	lh	a4,70(s1)
    800036ae:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800036b2:	04849703          	lh	a4,72(s1)
    800036b6:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036ba:	04a49703          	lh	a4,74(s1)
    800036be:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800036c2:	44f8                	lw	a4,76(s1)
    800036c4:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036c6:	03400613          	li	a2,52
    800036ca:	05048593          	addi	a1,s1,80
    800036ce:	00c78513          	addi	a0,a5,12
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	6ce080e7          	jalr	1742(ra) # 80000da0 <memmove>
  log_write(bp);
    800036da:	854a                	mv	a0,s2
    800036dc:	00001097          	auipc	ra,0x1
    800036e0:	bd4080e7          	jalr	-1068(ra) # 800042b0 <log_write>
  brelse(bp);
    800036e4:	854a                	mv	a0,s2
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	972080e7          	jalr	-1678(ra) # 80003058 <brelse>
}
    800036ee:	60e2                	ld	ra,24(sp)
    800036f0:	6442                	ld	s0,16(sp)
    800036f2:	64a2                	ld	s1,8(sp)
    800036f4:	6902                	ld	s2,0(sp)
    800036f6:	6105                	addi	sp,sp,32
    800036f8:	8082                	ret

00000000800036fa <idup>:
{
    800036fa:	1101                	addi	sp,sp,-32
    800036fc:	ec06                	sd	ra,24(sp)
    800036fe:	e822                	sd	s0,16(sp)
    80003700:	e426                	sd	s1,8(sp)
    80003702:	1000                	addi	s0,sp,32
    80003704:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003706:	0001d517          	auipc	a0,0x1d
    8000370a:	ed250513          	addi	a0,a0,-302 # 800205d8 <itable>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	53a080e7          	jalr	1338(ra) # 80000c48 <acquire>
  ip->ref++;
    80003716:	449c                	lw	a5,8(s1)
    80003718:	2785                	addiw	a5,a5,1
    8000371a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000371c:	0001d517          	auipc	a0,0x1d
    80003720:	ebc50513          	addi	a0,a0,-324 # 800205d8 <itable>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	5d8080e7          	jalr	1496(ra) # 80000cfc <release>
}
    8000372c:	8526                	mv	a0,s1
    8000372e:	60e2                	ld	ra,24(sp)
    80003730:	6442                	ld	s0,16(sp)
    80003732:	64a2                	ld	s1,8(sp)
    80003734:	6105                	addi	sp,sp,32
    80003736:	8082                	ret

0000000080003738 <ilock>:
{
    80003738:	1101                	addi	sp,sp,-32
    8000373a:	ec06                	sd	ra,24(sp)
    8000373c:	e822                	sd	s0,16(sp)
    8000373e:	e426                	sd	s1,8(sp)
    80003740:	e04a                	sd	s2,0(sp)
    80003742:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003744:	c115                	beqz	a0,80003768 <ilock+0x30>
    80003746:	84aa                	mv	s1,a0
    80003748:	451c                	lw	a5,8(a0)
    8000374a:	00f05f63          	blez	a5,80003768 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000374e:	0541                	addi	a0,a0,16
    80003750:	00001097          	auipc	ra,0x1
    80003754:	c7e080e7          	jalr	-898(ra) # 800043ce <acquiresleep>
  if(ip->valid == 0){
    80003758:	40bc                	lw	a5,64(s1)
    8000375a:	cf99                	beqz	a5,80003778 <ilock+0x40>
}
    8000375c:	60e2                	ld	ra,24(sp)
    8000375e:	6442                	ld	s0,16(sp)
    80003760:	64a2                	ld	s1,8(sp)
    80003762:	6902                	ld	s2,0(sp)
    80003764:	6105                	addi	sp,sp,32
    80003766:	8082                	ret
    panic("ilock");
    80003768:	00006517          	auipc	a0,0x6
    8000376c:	e7050513          	addi	a0,a0,-400 # 800095d8 <syscalls+0x180>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	dd0080e7          	jalr	-560(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003778:	40dc                	lw	a5,4(s1)
    8000377a:	0047d79b          	srliw	a5,a5,0x4
    8000377e:	0001d597          	auipc	a1,0x1d
    80003782:	e525a583          	lw	a1,-430(a1) # 800205d0 <sb+0x18>
    80003786:	9dbd                	addw	a1,a1,a5
    80003788:	4088                	lw	a0,0(s1)
    8000378a:	fffff097          	auipc	ra,0xfffff
    8000378e:	79e080e7          	jalr	1950(ra) # 80002f28 <bread>
    80003792:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003794:	05850593          	addi	a1,a0,88
    80003798:	40dc                	lw	a5,4(s1)
    8000379a:	8bbd                	andi	a5,a5,15
    8000379c:	079a                	slli	a5,a5,0x6
    8000379e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037a0:	00059783          	lh	a5,0(a1)
    800037a4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037a8:	00259783          	lh	a5,2(a1)
    800037ac:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037b0:	00459783          	lh	a5,4(a1)
    800037b4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037b8:	00659783          	lh	a5,6(a1)
    800037bc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037c0:	459c                	lw	a5,8(a1)
    800037c2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037c4:	03400613          	li	a2,52
    800037c8:	05b1                	addi	a1,a1,12
    800037ca:	05048513          	addi	a0,s1,80
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	5d2080e7          	jalr	1490(ra) # 80000da0 <memmove>
    brelse(bp);
    800037d6:	854a                	mv	a0,s2
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	880080e7          	jalr	-1920(ra) # 80003058 <brelse>
    ip->valid = 1;
    800037e0:	4785                	li	a5,1
    800037e2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037e4:	04449783          	lh	a5,68(s1)
    800037e8:	fbb5                	bnez	a5,8000375c <ilock+0x24>
      panic("ilock: no type");
    800037ea:	00006517          	auipc	a0,0x6
    800037ee:	df650513          	addi	a0,a0,-522 # 800095e0 <syscalls+0x188>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	d4e080e7          	jalr	-690(ra) # 80000540 <panic>

00000000800037fa <iunlock>:
{
    800037fa:	1101                	addi	sp,sp,-32
    800037fc:	ec06                	sd	ra,24(sp)
    800037fe:	e822                	sd	s0,16(sp)
    80003800:	e426                	sd	s1,8(sp)
    80003802:	e04a                	sd	s2,0(sp)
    80003804:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003806:	c905                	beqz	a0,80003836 <iunlock+0x3c>
    80003808:	84aa                	mv	s1,a0
    8000380a:	01050913          	addi	s2,a0,16
    8000380e:	854a                	mv	a0,s2
    80003810:	00001097          	auipc	ra,0x1
    80003814:	c58080e7          	jalr	-936(ra) # 80004468 <holdingsleep>
    80003818:	cd19                	beqz	a0,80003836 <iunlock+0x3c>
    8000381a:	449c                	lw	a5,8(s1)
    8000381c:	00f05d63          	blez	a5,80003836 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003820:	854a                	mv	a0,s2
    80003822:	00001097          	auipc	ra,0x1
    80003826:	c02080e7          	jalr	-1022(ra) # 80004424 <releasesleep>
}
    8000382a:	60e2                	ld	ra,24(sp)
    8000382c:	6442                	ld	s0,16(sp)
    8000382e:	64a2                	ld	s1,8(sp)
    80003830:	6902                	ld	s2,0(sp)
    80003832:	6105                	addi	sp,sp,32
    80003834:	8082                	ret
    panic("iunlock");
    80003836:	00006517          	auipc	a0,0x6
    8000383a:	dba50513          	addi	a0,a0,-582 # 800095f0 <syscalls+0x198>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	d02080e7          	jalr	-766(ra) # 80000540 <panic>

0000000080003846 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003846:	7179                	addi	sp,sp,-48
    80003848:	f406                	sd	ra,40(sp)
    8000384a:	f022                	sd	s0,32(sp)
    8000384c:	ec26                	sd	s1,24(sp)
    8000384e:	e84a                	sd	s2,16(sp)
    80003850:	e44e                	sd	s3,8(sp)
    80003852:	e052                	sd	s4,0(sp)
    80003854:	1800                	addi	s0,sp,48
    80003856:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003858:	05050493          	addi	s1,a0,80
    8000385c:	08050913          	addi	s2,a0,128
    80003860:	a021                	j	80003868 <itrunc+0x22>
    80003862:	0491                	addi	s1,s1,4
    80003864:	01248d63          	beq	s1,s2,8000387e <itrunc+0x38>
    if(ip->addrs[i]){
    80003868:	408c                	lw	a1,0(s1)
    8000386a:	dde5                	beqz	a1,80003862 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000386c:	0009a503          	lw	a0,0(s3)
    80003870:	00000097          	auipc	ra,0x0
    80003874:	8fc080e7          	jalr	-1796(ra) # 8000316c <bfree>
      ip->addrs[i] = 0;
    80003878:	0004a023          	sw	zero,0(s1)
    8000387c:	b7dd                	j	80003862 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000387e:	0809a583          	lw	a1,128(s3)
    80003882:	e185                	bnez	a1,800038a2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003884:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003888:	854e                	mv	a0,s3
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	de2080e7          	jalr	-542(ra) # 8000366c <iupdate>
}
    80003892:	70a2                	ld	ra,40(sp)
    80003894:	7402                	ld	s0,32(sp)
    80003896:	64e2                	ld	s1,24(sp)
    80003898:	6942                	ld	s2,16(sp)
    8000389a:	69a2                	ld	s3,8(sp)
    8000389c:	6a02                	ld	s4,0(sp)
    8000389e:	6145                	addi	sp,sp,48
    800038a0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038a2:	0009a503          	lw	a0,0(s3)
    800038a6:	fffff097          	auipc	ra,0xfffff
    800038aa:	682080e7          	jalr	1666(ra) # 80002f28 <bread>
    800038ae:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038b0:	05850493          	addi	s1,a0,88
    800038b4:	45850913          	addi	s2,a0,1112
    800038b8:	a021                	j	800038c0 <itrunc+0x7a>
    800038ba:	0491                	addi	s1,s1,4
    800038bc:	01248b63          	beq	s1,s2,800038d2 <itrunc+0x8c>
      if(a[j])
    800038c0:	408c                	lw	a1,0(s1)
    800038c2:	dde5                	beqz	a1,800038ba <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038c4:	0009a503          	lw	a0,0(s3)
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	8a4080e7          	jalr	-1884(ra) # 8000316c <bfree>
    800038d0:	b7ed                	j	800038ba <itrunc+0x74>
    brelse(bp);
    800038d2:	8552                	mv	a0,s4
    800038d4:	fffff097          	auipc	ra,0xfffff
    800038d8:	784080e7          	jalr	1924(ra) # 80003058 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038dc:	0809a583          	lw	a1,128(s3)
    800038e0:	0009a503          	lw	a0,0(s3)
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	888080e7          	jalr	-1912(ra) # 8000316c <bfree>
    ip->addrs[NDIRECT] = 0;
    800038ec:	0809a023          	sw	zero,128(s3)
    800038f0:	bf51                	j	80003884 <itrunc+0x3e>

00000000800038f2 <iput>:
{
    800038f2:	1101                	addi	sp,sp,-32
    800038f4:	ec06                	sd	ra,24(sp)
    800038f6:	e822                	sd	s0,16(sp)
    800038f8:	e426                	sd	s1,8(sp)
    800038fa:	e04a                	sd	s2,0(sp)
    800038fc:	1000                	addi	s0,sp,32
    800038fe:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003900:	0001d517          	auipc	a0,0x1d
    80003904:	cd850513          	addi	a0,a0,-808 # 800205d8 <itable>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	340080e7          	jalr	832(ra) # 80000c48 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003910:	4498                	lw	a4,8(s1)
    80003912:	4785                	li	a5,1
    80003914:	02f70363          	beq	a4,a5,8000393a <iput+0x48>
  ip->ref--;
    80003918:	449c                	lw	a5,8(s1)
    8000391a:	37fd                	addiw	a5,a5,-1
    8000391c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000391e:	0001d517          	auipc	a0,0x1d
    80003922:	cba50513          	addi	a0,a0,-838 # 800205d8 <itable>
    80003926:	ffffd097          	auipc	ra,0xffffd
    8000392a:	3d6080e7          	jalr	982(ra) # 80000cfc <release>
}
    8000392e:	60e2                	ld	ra,24(sp)
    80003930:	6442                	ld	s0,16(sp)
    80003932:	64a2                	ld	s1,8(sp)
    80003934:	6902                	ld	s2,0(sp)
    80003936:	6105                	addi	sp,sp,32
    80003938:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000393a:	40bc                	lw	a5,64(s1)
    8000393c:	dff1                	beqz	a5,80003918 <iput+0x26>
    8000393e:	04a49783          	lh	a5,74(s1)
    80003942:	fbf9                	bnez	a5,80003918 <iput+0x26>
    acquiresleep(&ip->lock);
    80003944:	01048913          	addi	s2,s1,16
    80003948:	854a                	mv	a0,s2
    8000394a:	00001097          	auipc	ra,0x1
    8000394e:	a84080e7          	jalr	-1404(ra) # 800043ce <acquiresleep>
    release(&itable.lock);
    80003952:	0001d517          	auipc	a0,0x1d
    80003956:	c8650513          	addi	a0,a0,-890 # 800205d8 <itable>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	3a2080e7          	jalr	930(ra) # 80000cfc <release>
    itrunc(ip);
    80003962:	8526                	mv	a0,s1
    80003964:	00000097          	auipc	ra,0x0
    80003968:	ee2080e7          	jalr	-286(ra) # 80003846 <itrunc>
    ip->type = 0;
    8000396c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003970:	8526                	mv	a0,s1
    80003972:	00000097          	auipc	ra,0x0
    80003976:	cfa080e7          	jalr	-774(ra) # 8000366c <iupdate>
    ip->valid = 0;
    8000397a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000397e:	854a                	mv	a0,s2
    80003980:	00001097          	auipc	ra,0x1
    80003984:	aa4080e7          	jalr	-1372(ra) # 80004424 <releasesleep>
    acquire(&itable.lock);
    80003988:	0001d517          	auipc	a0,0x1d
    8000398c:	c5050513          	addi	a0,a0,-944 # 800205d8 <itable>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	2b8080e7          	jalr	696(ra) # 80000c48 <acquire>
    80003998:	b741                	j	80003918 <iput+0x26>

000000008000399a <iunlockput>:
{
    8000399a:	1101                	addi	sp,sp,-32
    8000399c:	ec06                	sd	ra,24(sp)
    8000399e:	e822                	sd	s0,16(sp)
    800039a0:	e426                	sd	s1,8(sp)
    800039a2:	1000                	addi	s0,sp,32
    800039a4:	84aa                	mv	s1,a0
  iunlock(ip);
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	e54080e7          	jalr	-428(ra) # 800037fa <iunlock>
  iput(ip);
    800039ae:	8526                	mv	a0,s1
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	f42080e7          	jalr	-190(ra) # 800038f2 <iput>
}
    800039b8:	60e2                	ld	ra,24(sp)
    800039ba:	6442                	ld	s0,16(sp)
    800039bc:	64a2                	ld	s1,8(sp)
    800039be:	6105                	addi	sp,sp,32
    800039c0:	8082                	ret

00000000800039c2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039c2:	1141                	addi	sp,sp,-16
    800039c4:	e422                	sd	s0,8(sp)
    800039c6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039c8:	411c                	lw	a5,0(a0)
    800039ca:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039cc:	415c                	lw	a5,4(a0)
    800039ce:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039d0:	04451783          	lh	a5,68(a0)
    800039d4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039d8:	04a51783          	lh	a5,74(a0)
    800039dc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039e0:	04c56783          	lwu	a5,76(a0)
    800039e4:	e99c                	sd	a5,16(a1)
}
    800039e6:	6422                	ld	s0,8(sp)
    800039e8:	0141                	addi	sp,sp,16
    800039ea:	8082                	ret

00000000800039ec <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039ec:	457c                	lw	a5,76(a0)
    800039ee:	0ed7e963          	bltu	a5,a3,80003ae0 <readi+0xf4>
{
    800039f2:	7159                	addi	sp,sp,-112
    800039f4:	f486                	sd	ra,104(sp)
    800039f6:	f0a2                	sd	s0,96(sp)
    800039f8:	eca6                	sd	s1,88(sp)
    800039fa:	e8ca                	sd	s2,80(sp)
    800039fc:	e4ce                	sd	s3,72(sp)
    800039fe:	e0d2                	sd	s4,64(sp)
    80003a00:	fc56                	sd	s5,56(sp)
    80003a02:	f85a                	sd	s6,48(sp)
    80003a04:	f45e                	sd	s7,40(sp)
    80003a06:	f062                	sd	s8,32(sp)
    80003a08:	ec66                	sd	s9,24(sp)
    80003a0a:	e86a                	sd	s10,16(sp)
    80003a0c:	e46e                	sd	s11,8(sp)
    80003a0e:	1880                	addi	s0,sp,112
    80003a10:	8b2a                	mv	s6,a0
    80003a12:	8bae                	mv	s7,a1
    80003a14:	8a32                	mv	s4,a2
    80003a16:	84b6                	mv	s1,a3
    80003a18:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a1a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a1c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a1e:	0ad76063          	bltu	a4,a3,80003abe <readi+0xd2>
  if(off + n > ip->size)
    80003a22:	00e7f463          	bgeu	a5,a4,80003a2a <readi+0x3e>
    n = ip->size - off;
    80003a26:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a2a:	0a0a8963          	beqz	s5,80003adc <readi+0xf0>
    80003a2e:	4981                	li	s3,0
#if 0
    // Adil: Remove later
    printf("ip->dev; %d\n", ip->dev);
#endif

    m = min(n - tot, BSIZE - off%BSIZE);
    80003a30:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a34:	5c7d                	li	s8,-1
    80003a36:	a82d                	j	80003a70 <readi+0x84>
    80003a38:	020d1d93          	slli	s11,s10,0x20
    80003a3c:	020ddd93          	srli	s11,s11,0x20
    80003a40:	05890613          	addi	a2,s2,88
    80003a44:	86ee                	mv	a3,s11
    80003a46:	963a                	add	a2,a2,a4
    80003a48:	85d2                	mv	a1,s4
    80003a4a:	855e                	mv	a0,s7
    80003a4c:	fffff097          	auipc	ra,0xfffff
    80003a50:	ab6080e7          	jalr	-1354(ra) # 80002502 <either_copyout>
    80003a54:	05850d63          	beq	a0,s8,80003aae <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a58:	854a                	mv	a0,s2
    80003a5a:	fffff097          	auipc	ra,0xfffff
    80003a5e:	5fe080e7          	jalr	1534(ra) # 80003058 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a62:	013d09bb          	addw	s3,s10,s3
    80003a66:	009d04bb          	addw	s1,s10,s1
    80003a6a:	9a6e                	add	s4,s4,s11
    80003a6c:	0559f763          	bgeu	s3,s5,80003aba <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a70:	00a4d59b          	srliw	a1,s1,0xa
    80003a74:	855a                	mv	a0,s6
    80003a76:	00000097          	auipc	ra,0x0
    80003a7a:	8a4080e7          	jalr	-1884(ra) # 8000331a <bmap>
    80003a7e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a82:	cd85                	beqz	a1,80003aba <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a84:	000b2503          	lw	a0,0(s6)
    80003a88:	fffff097          	auipc	ra,0xfffff
    80003a8c:	4a0080e7          	jalr	1184(ra) # 80002f28 <bread>
    80003a90:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a92:	3ff4f713          	andi	a4,s1,1023
    80003a96:	40ec87bb          	subw	a5,s9,a4
    80003a9a:	413a86bb          	subw	a3,s5,s3
    80003a9e:	8d3e                	mv	s10,a5
    80003aa0:	2781                	sext.w	a5,a5
    80003aa2:	0006861b          	sext.w	a2,a3
    80003aa6:	f8f679e3          	bgeu	a2,a5,80003a38 <readi+0x4c>
    80003aaa:	8d36                	mv	s10,a3
    80003aac:	b771                	j	80003a38 <readi+0x4c>
      brelse(bp);
    80003aae:	854a                	mv	a0,s2
    80003ab0:	fffff097          	auipc	ra,0xfffff
    80003ab4:	5a8080e7          	jalr	1448(ra) # 80003058 <brelse>
      tot = -1;
    80003ab8:	59fd                	li	s3,-1
  }
  return tot;
    80003aba:	0009851b          	sext.w	a0,s3
}
    80003abe:	70a6                	ld	ra,104(sp)
    80003ac0:	7406                	ld	s0,96(sp)
    80003ac2:	64e6                	ld	s1,88(sp)
    80003ac4:	6946                	ld	s2,80(sp)
    80003ac6:	69a6                	ld	s3,72(sp)
    80003ac8:	6a06                	ld	s4,64(sp)
    80003aca:	7ae2                	ld	s5,56(sp)
    80003acc:	7b42                	ld	s6,48(sp)
    80003ace:	7ba2                	ld	s7,40(sp)
    80003ad0:	7c02                	ld	s8,32(sp)
    80003ad2:	6ce2                	ld	s9,24(sp)
    80003ad4:	6d42                	ld	s10,16(sp)
    80003ad6:	6da2                	ld	s11,8(sp)
    80003ad8:	6165                	addi	sp,sp,112
    80003ada:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003adc:	89d6                	mv	s3,s5
    80003ade:	bff1                	j	80003aba <readi+0xce>
    return 0;
    80003ae0:	4501                	li	a0,0
}
    80003ae2:	8082                	ret

0000000080003ae4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ae4:	457c                	lw	a5,76(a0)
    80003ae6:	10d7e863          	bltu	a5,a3,80003bf6 <writei+0x112>
{
    80003aea:	7159                	addi	sp,sp,-112
    80003aec:	f486                	sd	ra,104(sp)
    80003aee:	f0a2                	sd	s0,96(sp)
    80003af0:	eca6                	sd	s1,88(sp)
    80003af2:	e8ca                	sd	s2,80(sp)
    80003af4:	e4ce                	sd	s3,72(sp)
    80003af6:	e0d2                	sd	s4,64(sp)
    80003af8:	fc56                	sd	s5,56(sp)
    80003afa:	f85a                	sd	s6,48(sp)
    80003afc:	f45e                	sd	s7,40(sp)
    80003afe:	f062                	sd	s8,32(sp)
    80003b00:	ec66                	sd	s9,24(sp)
    80003b02:	e86a                	sd	s10,16(sp)
    80003b04:	e46e                	sd	s11,8(sp)
    80003b06:	1880                	addi	s0,sp,112
    80003b08:	8aaa                	mv	s5,a0
    80003b0a:	8bae                	mv	s7,a1
    80003b0c:	8a32                	mv	s4,a2
    80003b0e:	8936                	mv	s2,a3
    80003b10:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b12:	00e687bb          	addw	a5,a3,a4
    80003b16:	0ed7e263          	bltu	a5,a3,80003bfa <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b1a:	00043737          	lui	a4,0x43
    80003b1e:	0ef76063          	bltu	a4,a5,80003bfe <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b22:	0c0b0863          	beqz	s6,80003bf2 <writei+0x10e>
    80003b26:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b28:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b2c:	5c7d                	li	s8,-1
    80003b2e:	a091                	j	80003b72 <writei+0x8e>
    80003b30:	020d1d93          	slli	s11,s10,0x20
    80003b34:	020ddd93          	srli	s11,s11,0x20
    80003b38:	05848513          	addi	a0,s1,88
    80003b3c:	86ee                	mv	a3,s11
    80003b3e:	8652                	mv	a2,s4
    80003b40:	85de                	mv	a1,s7
    80003b42:	953a                	add	a0,a0,a4
    80003b44:	fffff097          	auipc	ra,0xfffff
    80003b48:	a14080e7          	jalr	-1516(ra) # 80002558 <either_copyin>
    80003b4c:	07850263          	beq	a0,s8,80003bb0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b50:	8526                	mv	a0,s1
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	75e080e7          	jalr	1886(ra) # 800042b0 <log_write>
    brelse(bp);
    80003b5a:	8526                	mv	a0,s1
    80003b5c:	fffff097          	auipc	ra,0xfffff
    80003b60:	4fc080e7          	jalr	1276(ra) # 80003058 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b64:	013d09bb          	addw	s3,s10,s3
    80003b68:	012d093b          	addw	s2,s10,s2
    80003b6c:	9a6e                	add	s4,s4,s11
    80003b6e:	0569f663          	bgeu	s3,s6,80003bba <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b72:	00a9559b          	srliw	a1,s2,0xa
    80003b76:	8556                	mv	a0,s5
    80003b78:	fffff097          	auipc	ra,0xfffff
    80003b7c:	7a2080e7          	jalr	1954(ra) # 8000331a <bmap>
    80003b80:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b84:	c99d                	beqz	a1,80003bba <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b86:	000aa503          	lw	a0,0(s5)
    80003b8a:	fffff097          	auipc	ra,0xfffff
    80003b8e:	39e080e7          	jalr	926(ra) # 80002f28 <bread>
    80003b92:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b94:	3ff97713          	andi	a4,s2,1023
    80003b98:	40ec87bb          	subw	a5,s9,a4
    80003b9c:	413b06bb          	subw	a3,s6,s3
    80003ba0:	8d3e                	mv	s10,a5
    80003ba2:	2781                	sext.w	a5,a5
    80003ba4:	0006861b          	sext.w	a2,a3
    80003ba8:	f8f674e3          	bgeu	a2,a5,80003b30 <writei+0x4c>
    80003bac:	8d36                	mv	s10,a3
    80003bae:	b749                	j	80003b30 <writei+0x4c>
      brelse(bp);
    80003bb0:	8526                	mv	a0,s1
    80003bb2:	fffff097          	auipc	ra,0xfffff
    80003bb6:	4a6080e7          	jalr	1190(ra) # 80003058 <brelse>
  }

  if(off > ip->size)
    80003bba:	04caa783          	lw	a5,76(s5)
    80003bbe:	0127f463          	bgeu	a5,s2,80003bc6 <writei+0xe2>
    ip->size = off;
    80003bc2:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bc6:	8556                	mv	a0,s5
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	aa4080e7          	jalr	-1372(ra) # 8000366c <iupdate>

  return tot;
    80003bd0:	0009851b          	sext.w	a0,s3
}
    80003bd4:	70a6                	ld	ra,104(sp)
    80003bd6:	7406                	ld	s0,96(sp)
    80003bd8:	64e6                	ld	s1,88(sp)
    80003bda:	6946                	ld	s2,80(sp)
    80003bdc:	69a6                	ld	s3,72(sp)
    80003bde:	6a06                	ld	s4,64(sp)
    80003be0:	7ae2                	ld	s5,56(sp)
    80003be2:	7b42                	ld	s6,48(sp)
    80003be4:	7ba2                	ld	s7,40(sp)
    80003be6:	7c02                	ld	s8,32(sp)
    80003be8:	6ce2                	ld	s9,24(sp)
    80003bea:	6d42                	ld	s10,16(sp)
    80003bec:	6da2                	ld	s11,8(sp)
    80003bee:	6165                	addi	sp,sp,112
    80003bf0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bf2:	89da                	mv	s3,s6
    80003bf4:	bfc9                	j	80003bc6 <writei+0xe2>
    return -1;
    80003bf6:	557d                	li	a0,-1
}
    80003bf8:	8082                	ret
    return -1;
    80003bfa:	557d                	li	a0,-1
    80003bfc:	bfe1                	j	80003bd4 <writei+0xf0>
    return -1;
    80003bfe:	557d                	li	a0,-1
    80003c00:	bfd1                	j	80003bd4 <writei+0xf0>

0000000080003c02 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c02:	1141                	addi	sp,sp,-16
    80003c04:	e406                	sd	ra,8(sp)
    80003c06:	e022                	sd	s0,0(sp)
    80003c08:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c0a:	4639                	li	a2,14
    80003c0c:	ffffd097          	auipc	ra,0xffffd
    80003c10:	208080e7          	jalr	520(ra) # 80000e14 <strncmp>
}
    80003c14:	60a2                	ld	ra,8(sp)
    80003c16:	6402                	ld	s0,0(sp)
    80003c18:	0141                	addi	sp,sp,16
    80003c1a:	8082                	ret

0000000080003c1c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c1c:	7139                	addi	sp,sp,-64
    80003c1e:	fc06                	sd	ra,56(sp)
    80003c20:	f822                	sd	s0,48(sp)
    80003c22:	f426                	sd	s1,40(sp)
    80003c24:	f04a                	sd	s2,32(sp)
    80003c26:	ec4e                	sd	s3,24(sp)
    80003c28:	e852                	sd	s4,16(sp)
    80003c2a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c2c:	04451703          	lh	a4,68(a0)
    80003c30:	4785                	li	a5,1
    80003c32:	00f71a63          	bne	a4,a5,80003c46 <dirlookup+0x2a>
    80003c36:	892a                	mv	s2,a0
    80003c38:	89ae                	mv	s3,a1
    80003c3a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c3c:	457c                	lw	a5,76(a0)
    80003c3e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c40:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c42:	e79d                	bnez	a5,80003c70 <dirlookup+0x54>
    80003c44:	a8a5                	j	80003cbc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c46:	00006517          	auipc	a0,0x6
    80003c4a:	9b250513          	addi	a0,a0,-1614 # 800095f8 <syscalls+0x1a0>
    80003c4e:	ffffd097          	auipc	ra,0xffffd
    80003c52:	8f2080e7          	jalr	-1806(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003c56:	00006517          	auipc	a0,0x6
    80003c5a:	9ba50513          	addi	a0,a0,-1606 # 80009610 <syscalls+0x1b8>
    80003c5e:	ffffd097          	auipc	ra,0xffffd
    80003c62:	8e2080e7          	jalr	-1822(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c66:	24c1                	addiw	s1,s1,16
    80003c68:	04c92783          	lw	a5,76(s2)
    80003c6c:	04f4f763          	bgeu	s1,a5,80003cba <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c70:	4741                	li	a4,16
    80003c72:	86a6                	mv	a3,s1
    80003c74:	fc040613          	addi	a2,s0,-64
    80003c78:	4581                	li	a1,0
    80003c7a:	854a                	mv	a0,s2
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	d70080e7          	jalr	-656(ra) # 800039ec <readi>
    80003c84:	47c1                	li	a5,16
    80003c86:	fcf518e3          	bne	a0,a5,80003c56 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c8a:	fc045783          	lhu	a5,-64(s0)
    80003c8e:	dfe1                	beqz	a5,80003c66 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c90:	fc240593          	addi	a1,s0,-62
    80003c94:	854e                	mv	a0,s3
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	f6c080e7          	jalr	-148(ra) # 80003c02 <namecmp>
    80003c9e:	f561                	bnez	a0,80003c66 <dirlookup+0x4a>
      if(poff)
    80003ca0:	000a0463          	beqz	s4,80003ca8 <dirlookup+0x8c>
        *poff = off;
    80003ca4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ca8:	fc045583          	lhu	a1,-64(s0)
    80003cac:	00092503          	lw	a0,0(s2)
    80003cb0:	fffff097          	auipc	ra,0xfffff
    80003cb4:	754080e7          	jalr	1876(ra) # 80003404 <iget>
    80003cb8:	a011                	j	80003cbc <dirlookup+0xa0>
  return 0;
    80003cba:	4501                	li	a0,0
}
    80003cbc:	70e2                	ld	ra,56(sp)
    80003cbe:	7442                	ld	s0,48(sp)
    80003cc0:	74a2                	ld	s1,40(sp)
    80003cc2:	7902                	ld	s2,32(sp)
    80003cc4:	69e2                	ld	s3,24(sp)
    80003cc6:	6a42                	ld	s4,16(sp)
    80003cc8:	6121                	addi	sp,sp,64
    80003cca:	8082                	ret

0000000080003ccc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ccc:	711d                	addi	sp,sp,-96
    80003cce:	ec86                	sd	ra,88(sp)
    80003cd0:	e8a2                	sd	s0,80(sp)
    80003cd2:	e4a6                	sd	s1,72(sp)
    80003cd4:	e0ca                	sd	s2,64(sp)
    80003cd6:	fc4e                	sd	s3,56(sp)
    80003cd8:	f852                	sd	s4,48(sp)
    80003cda:	f456                	sd	s5,40(sp)
    80003cdc:	f05a                	sd	s6,32(sp)
    80003cde:	ec5e                	sd	s7,24(sp)
    80003ce0:	e862                	sd	s8,16(sp)
    80003ce2:	e466                	sd	s9,8(sp)
    80003ce4:	1080                	addi	s0,sp,96
    80003ce6:	84aa                	mv	s1,a0
    80003ce8:	8b2e                	mv	s6,a1
    80003cea:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cec:	00054703          	lbu	a4,0(a0)
    80003cf0:	02f00793          	li	a5,47
    80003cf4:	02f70263          	beq	a4,a5,80003d18 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cf8:	ffffe097          	auipc	ra,0xffffe
    80003cfc:	d2c080e7          	jalr	-724(ra) # 80001a24 <myproc>
    80003d00:	15053503          	ld	a0,336(a0)
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	9f6080e7          	jalr	-1546(ra) # 800036fa <idup>
    80003d0c:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d0e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d12:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d14:	4b85                	li	s7,1
    80003d16:	a875                	j	80003dd2 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003d18:	4585                	li	a1,1
    80003d1a:	4505                	li	a0,1
    80003d1c:	fffff097          	auipc	ra,0xfffff
    80003d20:	6e8080e7          	jalr	1768(ra) # 80003404 <iget>
    80003d24:	8a2a                	mv	s4,a0
    80003d26:	b7e5                	j	80003d0e <namex+0x42>
      iunlockput(ip);
    80003d28:	8552                	mv	a0,s4
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	c70080e7          	jalr	-912(ra) # 8000399a <iunlockput>
      return 0;
    80003d32:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d34:	8552                	mv	a0,s4
    80003d36:	60e6                	ld	ra,88(sp)
    80003d38:	6446                	ld	s0,80(sp)
    80003d3a:	64a6                	ld	s1,72(sp)
    80003d3c:	6906                	ld	s2,64(sp)
    80003d3e:	79e2                	ld	s3,56(sp)
    80003d40:	7a42                	ld	s4,48(sp)
    80003d42:	7aa2                	ld	s5,40(sp)
    80003d44:	7b02                	ld	s6,32(sp)
    80003d46:	6be2                	ld	s7,24(sp)
    80003d48:	6c42                	ld	s8,16(sp)
    80003d4a:	6ca2                	ld	s9,8(sp)
    80003d4c:	6125                	addi	sp,sp,96
    80003d4e:	8082                	ret
      iunlock(ip);
    80003d50:	8552                	mv	a0,s4
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	aa8080e7          	jalr	-1368(ra) # 800037fa <iunlock>
      return ip;
    80003d5a:	bfe9                	j	80003d34 <namex+0x68>
      iunlockput(ip);
    80003d5c:	8552                	mv	a0,s4
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	c3c080e7          	jalr	-964(ra) # 8000399a <iunlockput>
      return 0;
    80003d66:	8a4e                	mv	s4,s3
    80003d68:	b7f1                	j	80003d34 <namex+0x68>
  len = path - s;
    80003d6a:	40998633          	sub	a2,s3,s1
    80003d6e:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d72:	099c5863          	bge	s8,s9,80003e02 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003d76:	4639                	li	a2,14
    80003d78:	85a6                	mv	a1,s1
    80003d7a:	8556                	mv	a0,s5
    80003d7c:	ffffd097          	auipc	ra,0xffffd
    80003d80:	024080e7          	jalr	36(ra) # 80000da0 <memmove>
    80003d84:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d86:	0004c783          	lbu	a5,0(s1)
    80003d8a:	01279763          	bne	a5,s2,80003d98 <namex+0xcc>
    path++;
    80003d8e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d90:	0004c783          	lbu	a5,0(s1)
    80003d94:	ff278de3          	beq	a5,s2,80003d8e <namex+0xc2>
    ilock(ip);
    80003d98:	8552                	mv	a0,s4
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	99e080e7          	jalr	-1634(ra) # 80003738 <ilock>
    if(ip->type != T_DIR){
    80003da2:	044a1783          	lh	a5,68(s4)
    80003da6:	f97791e3          	bne	a5,s7,80003d28 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003daa:	000b0563          	beqz	s6,80003db4 <namex+0xe8>
    80003dae:	0004c783          	lbu	a5,0(s1)
    80003db2:	dfd9                	beqz	a5,80003d50 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003db4:	4601                	li	a2,0
    80003db6:	85d6                	mv	a1,s5
    80003db8:	8552                	mv	a0,s4
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	e62080e7          	jalr	-414(ra) # 80003c1c <dirlookup>
    80003dc2:	89aa                	mv	s3,a0
    80003dc4:	dd41                	beqz	a0,80003d5c <namex+0x90>
    iunlockput(ip);
    80003dc6:	8552                	mv	a0,s4
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	bd2080e7          	jalr	-1070(ra) # 8000399a <iunlockput>
    ip = next;
    80003dd0:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003dd2:	0004c783          	lbu	a5,0(s1)
    80003dd6:	01279763          	bne	a5,s2,80003de4 <namex+0x118>
    path++;
    80003dda:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ddc:	0004c783          	lbu	a5,0(s1)
    80003de0:	ff278de3          	beq	a5,s2,80003dda <namex+0x10e>
  if(*path == 0)
    80003de4:	cb9d                	beqz	a5,80003e1a <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003de6:	0004c783          	lbu	a5,0(s1)
    80003dea:	89a6                	mv	s3,s1
  len = path - s;
    80003dec:	4c81                	li	s9,0
    80003dee:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003df0:	01278963          	beq	a5,s2,80003e02 <namex+0x136>
    80003df4:	dbbd                	beqz	a5,80003d6a <namex+0x9e>
    path++;
    80003df6:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003df8:	0009c783          	lbu	a5,0(s3)
    80003dfc:	ff279ce3          	bne	a5,s2,80003df4 <namex+0x128>
    80003e00:	b7ad                	j	80003d6a <namex+0x9e>
    memmove(name, s, len);
    80003e02:	2601                	sext.w	a2,a2
    80003e04:	85a6                	mv	a1,s1
    80003e06:	8556                	mv	a0,s5
    80003e08:	ffffd097          	auipc	ra,0xffffd
    80003e0c:	f98080e7          	jalr	-104(ra) # 80000da0 <memmove>
    name[len] = 0;
    80003e10:	9cd6                	add	s9,s9,s5
    80003e12:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e16:	84ce                	mv	s1,s3
    80003e18:	b7bd                	j	80003d86 <namex+0xba>
  if(nameiparent){
    80003e1a:	f00b0de3          	beqz	s6,80003d34 <namex+0x68>
    iput(ip);
    80003e1e:	8552                	mv	a0,s4
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	ad2080e7          	jalr	-1326(ra) # 800038f2 <iput>
    return 0;
    80003e28:	4a01                	li	s4,0
    80003e2a:	b729                	j	80003d34 <namex+0x68>

0000000080003e2c <dirlink>:
{
    80003e2c:	7139                	addi	sp,sp,-64
    80003e2e:	fc06                	sd	ra,56(sp)
    80003e30:	f822                	sd	s0,48(sp)
    80003e32:	f426                	sd	s1,40(sp)
    80003e34:	f04a                	sd	s2,32(sp)
    80003e36:	ec4e                	sd	s3,24(sp)
    80003e38:	e852                	sd	s4,16(sp)
    80003e3a:	0080                	addi	s0,sp,64
    80003e3c:	892a                	mv	s2,a0
    80003e3e:	8a2e                	mv	s4,a1
    80003e40:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e42:	4601                	li	a2,0
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	dd8080e7          	jalr	-552(ra) # 80003c1c <dirlookup>
    80003e4c:	e93d                	bnez	a0,80003ec2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e4e:	04c92483          	lw	s1,76(s2)
    80003e52:	c49d                	beqz	s1,80003e80 <dirlink+0x54>
    80003e54:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e56:	4741                	li	a4,16
    80003e58:	86a6                	mv	a3,s1
    80003e5a:	fc040613          	addi	a2,s0,-64
    80003e5e:	4581                	li	a1,0
    80003e60:	854a                	mv	a0,s2
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	b8a080e7          	jalr	-1142(ra) # 800039ec <readi>
    80003e6a:	47c1                	li	a5,16
    80003e6c:	06f51163          	bne	a0,a5,80003ece <dirlink+0xa2>
    if(de.inum == 0)
    80003e70:	fc045783          	lhu	a5,-64(s0)
    80003e74:	c791                	beqz	a5,80003e80 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e76:	24c1                	addiw	s1,s1,16
    80003e78:	04c92783          	lw	a5,76(s2)
    80003e7c:	fcf4ede3          	bltu	s1,a5,80003e56 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e80:	4639                	li	a2,14
    80003e82:	85d2                	mv	a1,s4
    80003e84:	fc240513          	addi	a0,s0,-62
    80003e88:	ffffd097          	auipc	ra,0xffffd
    80003e8c:	fc8080e7          	jalr	-56(ra) # 80000e50 <strncpy>
  de.inum = inum;
    80003e90:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e94:	4741                	li	a4,16
    80003e96:	86a6                	mv	a3,s1
    80003e98:	fc040613          	addi	a2,s0,-64
    80003e9c:	4581                	li	a1,0
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	c44080e7          	jalr	-956(ra) # 80003ae4 <writei>
    80003ea8:	1541                	addi	a0,a0,-16
    80003eaa:	00a03533          	snez	a0,a0
    80003eae:	40a00533          	neg	a0,a0
}
    80003eb2:	70e2                	ld	ra,56(sp)
    80003eb4:	7442                	ld	s0,48(sp)
    80003eb6:	74a2                	ld	s1,40(sp)
    80003eb8:	7902                	ld	s2,32(sp)
    80003eba:	69e2                	ld	s3,24(sp)
    80003ebc:	6a42                	ld	s4,16(sp)
    80003ebe:	6121                	addi	sp,sp,64
    80003ec0:	8082                	ret
    iput(ip);
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	a30080e7          	jalr	-1488(ra) # 800038f2 <iput>
    return -1;
    80003eca:	557d                	li	a0,-1
    80003ecc:	b7dd                	j	80003eb2 <dirlink+0x86>
      panic("dirlink read");
    80003ece:	00005517          	auipc	a0,0x5
    80003ed2:	75250513          	addi	a0,a0,1874 # 80009620 <syscalls+0x1c8>
    80003ed6:	ffffc097          	auipc	ra,0xffffc
    80003eda:	66a080e7          	jalr	1642(ra) # 80000540 <panic>

0000000080003ede <namei>:

struct inode*
namei(char *path)
{
    80003ede:	1101                	addi	sp,sp,-32
    80003ee0:	ec06                	sd	ra,24(sp)
    80003ee2:	e822                	sd	s0,16(sp)
    80003ee4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ee6:	fe040613          	addi	a2,s0,-32
    80003eea:	4581                	li	a1,0
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	de0080e7          	jalr	-544(ra) # 80003ccc <namex>
}
    80003ef4:	60e2                	ld	ra,24(sp)
    80003ef6:	6442                	ld	s0,16(sp)
    80003ef8:	6105                	addi	sp,sp,32
    80003efa:	8082                	ret

0000000080003efc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003efc:	1141                	addi	sp,sp,-16
    80003efe:	e406                	sd	ra,8(sp)
    80003f00:	e022                	sd	s0,0(sp)
    80003f02:	0800                	addi	s0,sp,16
    80003f04:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f06:	4585                	li	a1,1
    80003f08:	00000097          	auipc	ra,0x0
    80003f0c:	dc4080e7          	jalr	-572(ra) # 80003ccc <namex>
}
    80003f10:	60a2                	ld	ra,8(sp)
    80003f12:	6402                	ld	s0,0(sp)
    80003f14:	0141                	addi	sp,sp,16
    80003f16:	8082                	ret

0000000080003f18 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f18:	1101                	addi	sp,sp,-32
    80003f1a:	ec06                	sd	ra,24(sp)
    80003f1c:	e822                	sd	s0,16(sp)
    80003f1e:	e426                	sd	s1,8(sp)
    80003f20:	e04a                	sd	s2,0(sp)
    80003f22:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f24:	0001e917          	auipc	s2,0x1e
    80003f28:	15c90913          	addi	s2,s2,348 # 80022080 <log>
    80003f2c:	01892583          	lw	a1,24(s2)
    80003f30:	02892503          	lw	a0,40(s2)
    80003f34:	fffff097          	auipc	ra,0xfffff
    80003f38:	ff4080e7          	jalr	-12(ra) # 80002f28 <bread>
    80003f3c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f3e:	02c92603          	lw	a2,44(s2)
    80003f42:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f44:	00c05f63          	blez	a2,80003f62 <write_head+0x4a>
    80003f48:	0001e717          	auipc	a4,0x1e
    80003f4c:	16870713          	addi	a4,a4,360 # 800220b0 <log+0x30>
    80003f50:	87aa                	mv	a5,a0
    80003f52:	060a                	slli	a2,a2,0x2
    80003f54:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003f56:	4314                	lw	a3,0(a4)
    80003f58:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003f5a:	0711                	addi	a4,a4,4
    80003f5c:	0791                	addi	a5,a5,4
    80003f5e:	fec79ce3          	bne	a5,a2,80003f56 <write_head+0x3e>
  }
  bwrite(buf);
    80003f62:	8526                	mv	a0,s1
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	0b6080e7          	jalr	182(ra) # 8000301a <bwrite>
  brelse(buf);
    80003f6c:	8526                	mv	a0,s1
    80003f6e:	fffff097          	auipc	ra,0xfffff
    80003f72:	0ea080e7          	jalr	234(ra) # 80003058 <brelse>
}
    80003f76:	60e2                	ld	ra,24(sp)
    80003f78:	6442                	ld	s0,16(sp)
    80003f7a:	64a2                	ld	s1,8(sp)
    80003f7c:	6902                	ld	s2,0(sp)
    80003f7e:	6105                	addi	sp,sp,32
    80003f80:	8082                	ret

0000000080003f82 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f82:	0001e797          	auipc	a5,0x1e
    80003f86:	12a7a783          	lw	a5,298(a5) # 800220ac <log+0x2c>
    80003f8a:	0af05d63          	blez	a5,80004044 <install_trans+0xc2>
{
    80003f8e:	7139                	addi	sp,sp,-64
    80003f90:	fc06                	sd	ra,56(sp)
    80003f92:	f822                	sd	s0,48(sp)
    80003f94:	f426                	sd	s1,40(sp)
    80003f96:	f04a                	sd	s2,32(sp)
    80003f98:	ec4e                	sd	s3,24(sp)
    80003f9a:	e852                	sd	s4,16(sp)
    80003f9c:	e456                	sd	s5,8(sp)
    80003f9e:	e05a                	sd	s6,0(sp)
    80003fa0:	0080                	addi	s0,sp,64
    80003fa2:	8b2a                	mv	s6,a0
    80003fa4:	0001ea97          	auipc	s5,0x1e
    80003fa8:	10ca8a93          	addi	s5,s5,268 # 800220b0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fac:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fae:	0001e997          	auipc	s3,0x1e
    80003fb2:	0d298993          	addi	s3,s3,210 # 80022080 <log>
    80003fb6:	a00d                	j	80003fd8 <install_trans+0x56>
    brelse(lbuf);
    80003fb8:	854a                	mv	a0,s2
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	09e080e7          	jalr	158(ra) # 80003058 <brelse>
    brelse(dbuf);
    80003fc2:	8526                	mv	a0,s1
    80003fc4:	fffff097          	auipc	ra,0xfffff
    80003fc8:	094080e7          	jalr	148(ra) # 80003058 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fcc:	2a05                	addiw	s4,s4,1
    80003fce:	0a91                	addi	s5,s5,4
    80003fd0:	02c9a783          	lw	a5,44(s3)
    80003fd4:	04fa5e63          	bge	s4,a5,80004030 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fd8:	0189a583          	lw	a1,24(s3)
    80003fdc:	014585bb          	addw	a1,a1,s4
    80003fe0:	2585                	addiw	a1,a1,1
    80003fe2:	0289a503          	lw	a0,40(s3)
    80003fe6:	fffff097          	auipc	ra,0xfffff
    80003fea:	f42080e7          	jalr	-190(ra) # 80002f28 <bread>
    80003fee:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ff0:	000aa583          	lw	a1,0(s5)
    80003ff4:	0289a503          	lw	a0,40(s3)
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	f30080e7          	jalr	-208(ra) # 80002f28 <bread>
    80004000:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004002:	40000613          	li	a2,1024
    80004006:	05890593          	addi	a1,s2,88
    8000400a:	05850513          	addi	a0,a0,88
    8000400e:	ffffd097          	auipc	ra,0xffffd
    80004012:	d92080e7          	jalr	-622(ra) # 80000da0 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004016:	8526                	mv	a0,s1
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	002080e7          	jalr	2(ra) # 8000301a <bwrite>
    if(recovering == 0)
    80004020:	f80b1ce3          	bnez	s6,80003fb8 <install_trans+0x36>
      bunpin(dbuf);
    80004024:	8526                	mv	a0,s1
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	10a080e7          	jalr	266(ra) # 80003130 <bunpin>
    8000402e:	b769                	j	80003fb8 <install_trans+0x36>
}
    80004030:	70e2                	ld	ra,56(sp)
    80004032:	7442                	ld	s0,48(sp)
    80004034:	74a2                	ld	s1,40(sp)
    80004036:	7902                	ld	s2,32(sp)
    80004038:	69e2                	ld	s3,24(sp)
    8000403a:	6a42                	ld	s4,16(sp)
    8000403c:	6aa2                	ld	s5,8(sp)
    8000403e:	6b02                	ld	s6,0(sp)
    80004040:	6121                	addi	sp,sp,64
    80004042:	8082                	ret
    80004044:	8082                	ret

0000000080004046 <initlog>:
{
    80004046:	7179                	addi	sp,sp,-48
    80004048:	f406                	sd	ra,40(sp)
    8000404a:	f022                	sd	s0,32(sp)
    8000404c:	ec26                	sd	s1,24(sp)
    8000404e:	e84a                	sd	s2,16(sp)
    80004050:	e44e                	sd	s3,8(sp)
    80004052:	1800                	addi	s0,sp,48
    80004054:	892a                	mv	s2,a0
    80004056:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004058:	0001e497          	auipc	s1,0x1e
    8000405c:	02848493          	addi	s1,s1,40 # 80022080 <log>
    80004060:	00005597          	auipc	a1,0x5
    80004064:	5d058593          	addi	a1,a1,1488 # 80009630 <syscalls+0x1d8>
    80004068:	8526                	mv	a0,s1
    8000406a:	ffffd097          	auipc	ra,0xffffd
    8000406e:	b4e080e7          	jalr	-1202(ra) # 80000bb8 <initlock>
  log.start = sb->logstart;
    80004072:	0149a583          	lw	a1,20(s3)
    80004076:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004078:	0109a783          	lw	a5,16(s3)
    8000407c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000407e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004082:	854a                	mv	a0,s2
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	ea4080e7          	jalr	-348(ra) # 80002f28 <bread>
  log.lh.n = lh->n;
    8000408c:	4d30                	lw	a2,88(a0)
    8000408e:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004090:	00c05f63          	blez	a2,800040ae <initlog+0x68>
    80004094:	87aa                	mv	a5,a0
    80004096:	0001e717          	auipc	a4,0x1e
    8000409a:	01a70713          	addi	a4,a4,26 # 800220b0 <log+0x30>
    8000409e:	060a                	slli	a2,a2,0x2
    800040a0:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    800040a2:	4ff4                	lw	a3,92(a5)
    800040a4:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040a6:	0791                	addi	a5,a5,4
    800040a8:	0711                	addi	a4,a4,4
    800040aa:	fec79ce3          	bne	a5,a2,800040a2 <initlog+0x5c>
  brelse(buf);
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	faa080e7          	jalr	-86(ra) # 80003058 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040b6:	4505                	li	a0,1
    800040b8:	00000097          	auipc	ra,0x0
    800040bc:	eca080e7          	jalr	-310(ra) # 80003f82 <install_trans>
  log.lh.n = 0;
    800040c0:	0001e797          	auipc	a5,0x1e
    800040c4:	fe07a623          	sw	zero,-20(a5) # 800220ac <log+0x2c>
  write_head(); // clear the log
    800040c8:	00000097          	auipc	ra,0x0
    800040cc:	e50080e7          	jalr	-432(ra) # 80003f18 <write_head>
}
    800040d0:	70a2                	ld	ra,40(sp)
    800040d2:	7402                	ld	s0,32(sp)
    800040d4:	64e2                	ld	s1,24(sp)
    800040d6:	6942                	ld	s2,16(sp)
    800040d8:	69a2                	ld	s3,8(sp)
    800040da:	6145                	addi	sp,sp,48
    800040dc:	8082                	ret

00000000800040de <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040de:	1101                	addi	sp,sp,-32
    800040e0:	ec06                	sd	ra,24(sp)
    800040e2:	e822                	sd	s0,16(sp)
    800040e4:	e426                	sd	s1,8(sp)
    800040e6:	e04a                	sd	s2,0(sp)
    800040e8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040ea:	0001e517          	auipc	a0,0x1e
    800040ee:	f9650513          	addi	a0,a0,-106 # 80022080 <log>
    800040f2:	ffffd097          	auipc	ra,0xffffd
    800040f6:	b56080e7          	jalr	-1194(ra) # 80000c48 <acquire>
  while(1){
    if(log.committing){
    800040fa:	0001e497          	auipc	s1,0x1e
    800040fe:	f8648493          	addi	s1,s1,-122 # 80022080 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004102:	4979                	li	s2,30
    80004104:	a039                	j	80004112 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004106:	85a6                	mv	a1,s1
    80004108:	8526                	mv	a0,s1
    8000410a:	ffffe097          	auipc	ra,0xffffe
    8000410e:	ff0080e7          	jalr	-16(ra) # 800020fa <sleep>
    if(log.committing){
    80004112:	50dc                	lw	a5,36(s1)
    80004114:	fbed                	bnez	a5,80004106 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004116:	5098                	lw	a4,32(s1)
    80004118:	2705                	addiw	a4,a4,1
    8000411a:	0027179b          	slliw	a5,a4,0x2
    8000411e:	9fb9                	addw	a5,a5,a4
    80004120:	0017979b          	slliw	a5,a5,0x1
    80004124:	54d4                	lw	a3,44(s1)
    80004126:	9fb5                	addw	a5,a5,a3
    80004128:	00f95963          	bge	s2,a5,8000413a <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000412c:	85a6                	mv	a1,s1
    8000412e:	8526                	mv	a0,s1
    80004130:	ffffe097          	auipc	ra,0xffffe
    80004134:	fca080e7          	jalr	-54(ra) # 800020fa <sleep>
    80004138:	bfe9                	j	80004112 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000413a:	0001e517          	auipc	a0,0x1e
    8000413e:	f4650513          	addi	a0,a0,-186 # 80022080 <log>
    80004142:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004144:	ffffd097          	auipc	ra,0xffffd
    80004148:	bb8080e7          	jalr	-1096(ra) # 80000cfc <release>
      break;
    }
  }
}
    8000414c:	60e2                	ld	ra,24(sp)
    8000414e:	6442                	ld	s0,16(sp)
    80004150:	64a2                	ld	s1,8(sp)
    80004152:	6902                	ld	s2,0(sp)
    80004154:	6105                	addi	sp,sp,32
    80004156:	8082                	ret

0000000080004158 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004158:	7139                	addi	sp,sp,-64
    8000415a:	fc06                	sd	ra,56(sp)
    8000415c:	f822                	sd	s0,48(sp)
    8000415e:	f426                	sd	s1,40(sp)
    80004160:	f04a                	sd	s2,32(sp)
    80004162:	ec4e                	sd	s3,24(sp)
    80004164:	e852                	sd	s4,16(sp)
    80004166:	e456                	sd	s5,8(sp)
    80004168:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000416a:	0001e497          	auipc	s1,0x1e
    8000416e:	f1648493          	addi	s1,s1,-234 # 80022080 <log>
    80004172:	8526                	mv	a0,s1
    80004174:	ffffd097          	auipc	ra,0xffffd
    80004178:	ad4080e7          	jalr	-1324(ra) # 80000c48 <acquire>
  log.outstanding -= 1;
    8000417c:	509c                	lw	a5,32(s1)
    8000417e:	37fd                	addiw	a5,a5,-1
    80004180:	0007891b          	sext.w	s2,a5
    80004184:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004186:	50dc                	lw	a5,36(s1)
    80004188:	e7b9                	bnez	a5,800041d6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000418a:	04091e63          	bnez	s2,800041e6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000418e:	0001e497          	auipc	s1,0x1e
    80004192:	ef248493          	addi	s1,s1,-270 # 80022080 <log>
    80004196:	4785                	li	a5,1
    80004198:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000419a:	8526                	mv	a0,s1
    8000419c:	ffffd097          	auipc	ra,0xffffd
    800041a0:	b60080e7          	jalr	-1184(ra) # 80000cfc <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041a4:	54dc                	lw	a5,44(s1)
    800041a6:	06f04763          	bgtz	a5,80004214 <end_op+0xbc>
    acquire(&log.lock);
    800041aa:	0001e497          	auipc	s1,0x1e
    800041ae:	ed648493          	addi	s1,s1,-298 # 80022080 <log>
    800041b2:	8526                	mv	a0,s1
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	a94080e7          	jalr	-1388(ra) # 80000c48 <acquire>
    log.committing = 0;
    800041bc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041c0:	8526                	mv	a0,s1
    800041c2:	ffffe097          	auipc	ra,0xffffe
    800041c6:	f9c080e7          	jalr	-100(ra) # 8000215e <wakeup>
    release(&log.lock);
    800041ca:	8526                	mv	a0,s1
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	b30080e7          	jalr	-1232(ra) # 80000cfc <release>
}
    800041d4:	a03d                	j	80004202 <end_op+0xaa>
    panic("log.committing");
    800041d6:	00005517          	auipc	a0,0x5
    800041da:	46250513          	addi	a0,a0,1122 # 80009638 <syscalls+0x1e0>
    800041de:	ffffc097          	auipc	ra,0xffffc
    800041e2:	362080e7          	jalr	866(ra) # 80000540 <panic>
    wakeup(&log);
    800041e6:	0001e497          	auipc	s1,0x1e
    800041ea:	e9a48493          	addi	s1,s1,-358 # 80022080 <log>
    800041ee:	8526                	mv	a0,s1
    800041f0:	ffffe097          	auipc	ra,0xffffe
    800041f4:	f6e080e7          	jalr	-146(ra) # 8000215e <wakeup>
  release(&log.lock);
    800041f8:	8526                	mv	a0,s1
    800041fa:	ffffd097          	auipc	ra,0xffffd
    800041fe:	b02080e7          	jalr	-1278(ra) # 80000cfc <release>
}
    80004202:	70e2                	ld	ra,56(sp)
    80004204:	7442                	ld	s0,48(sp)
    80004206:	74a2                	ld	s1,40(sp)
    80004208:	7902                	ld	s2,32(sp)
    8000420a:	69e2                	ld	s3,24(sp)
    8000420c:	6a42                	ld	s4,16(sp)
    8000420e:	6aa2                	ld	s5,8(sp)
    80004210:	6121                	addi	sp,sp,64
    80004212:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004214:	0001ea97          	auipc	s5,0x1e
    80004218:	e9ca8a93          	addi	s5,s5,-356 # 800220b0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000421c:	0001ea17          	auipc	s4,0x1e
    80004220:	e64a0a13          	addi	s4,s4,-412 # 80022080 <log>
    80004224:	018a2583          	lw	a1,24(s4)
    80004228:	012585bb          	addw	a1,a1,s2
    8000422c:	2585                	addiw	a1,a1,1
    8000422e:	028a2503          	lw	a0,40(s4)
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	cf6080e7          	jalr	-778(ra) # 80002f28 <bread>
    8000423a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000423c:	000aa583          	lw	a1,0(s5)
    80004240:	028a2503          	lw	a0,40(s4)
    80004244:	fffff097          	auipc	ra,0xfffff
    80004248:	ce4080e7          	jalr	-796(ra) # 80002f28 <bread>
    8000424c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000424e:	40000613          	li	a2,1024
    80004252:	05850593          	addi	a1,a0,88
    80004256:	05848513          	addi	a0,s1,88
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	b46080e7          	jalr	-1210(ra) # 80000da0 <memmove>
    bwrite(to);  // write the log
    80004262:	8526                	mv	a0,s1
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	db6080e7          	jalr	-586(ra) # 8000301a <bwrite>
    brelse(from);
    8000426c:	854e                	mv	a0,s3
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	dea080e7          	jalr	-534(ra) # 80003058 <brelse>
    brelse(to);
    80004276:	8526                	mv	a0,s1
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	de0080e7          	jalr	-544(ra) # 80003058 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004280:	2905                	addiw	s2,s2,1
    80004282:	0a91                	addi	s5,s5,4
    80004284:	02ca2783          	lw	a5,44(s4)
    80004288:	f8f94ee3          	blt	s2,a5,80004224 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	c8c080e7          	jalr	-884(ra) # 80003f18 <write_head>
    install_trans(0); // Now install writes to home locations
    80004294:	4501                	li	a0,0
    80004296:	00000097          	auipc	ra,0x0
    8000429a:	cec080e7          	jalr	-788(ra) # 80003f82 <install_trans>
    log.lh.n = 0;
    8000429e:	0001e797          	auipc	a5,0x1e
    800042a2:	e007a723          	sw	zero,-498(a5) # 800220ac <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042a6:	00000097          	auipc	ra,0x0
    800042aa:	c72080e7          	jalr	-910(ra) # 80003f18 <write_head>
    800042ae:	bdf5                	j	800041aa <end_op+0x52>

00000000800042b0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042b0:	1101                	addi	sp,sp,-32
    800042b2:	ec06                	sd	ra,24(sp)
    800042b4:	e822                	sd	s0,16(sp)
    800042b6:	e426                	sd	s1,8(sp)
    800042b8:	e04a                	sd	s2,0(sp)
    800042ba:	1000                	addi	s0,sp,32
    800042bc:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042be:	0001e917          	auipc	s2,0x1e
    800042c2:	dc290913          	addi	s2,s2,-574 # 80022080 <log>
    800042c6:	854a                	mv	a0,s2
    800042c8:	ffffd097          	auipc	ra,0xffffd
    800042cc:	980080e7          	jalr	-1664(ra) # 80000c48 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042d0:	02c92603          	lw	a2,44(s2)
    800042d4:	47f5                	li	a5,29
    800042d6:	06c7c563          	blt	a5,a2,80004340 <log_write+0x90>
    800042da:	0001e797          	auipc	a5,0x1e
    800042de:	dc27a783          	lw	a5,-574(a5) # 8002209c <log+0x1c>
    800042e2:	37fd                	addiw	a5,a5,-1
    800042e4:	04f65e63          	bge	a2,a5,80004340 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042e8:	0001e797          	auipc	a5,0x1e
    800042ec:	db87a783          	lw	a5,-584(a5) # 800220a0 <log+0x20>
    800042f0:	06f05063          	blez	a5,80004350 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042f4:	4781                	li	a5,0
    800042f6:	06c05563          	blez	a2,80004360 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042fa:	44cc                	lw	a1,12(s1)
    800042fc:	0001e717          	auipc	a4,0x1e
    80004300:	db470713          	addi	a4,a4,-588 # 800220b0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004304:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004306:	4314                	lw	a3,0(a4)
    80004308:	04b68c63          	beq	a3,a1,80004360 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000430c:	2785                	addiw	a5,a5,1
    8000430e:	0711                	addi	a4,a4,4
    80004310:	fef61be3          	bne	a2,a5,80004306 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004314:	0621                	addi	a2,a2,8
    80004316:	060a                	slli	a2,a2,0x2
    80004318:	0001e797          	auipc	a5,0x1e
    8000431c:	d6878793          	addi	a5,a5,-664 # 80022080 <log>
    80004320:	97b2                	add	a5,a5,a2
    80004322:	44d8                	lw	a4,12(s1)
    80004324:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004326:	8526                	mv	a0,s1
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	dcc080e7          	jalr	-564(ra) # 800030f4 <bpin>
    log.lh.n++;
    80004330:	0001e717          	auipc	a4,0x1e
    80004334:	d5070713          	addi	a4,a4,-688 # 80022080 <log>
    80004338:	575c                	lw	a5,44(a4)
    8000433a:	2785                	addiw	a5,a5,1
    8000433c:	d75c                	sw	a5,44(a4)
    8000433e:	a82d                	j	80004378 <log_write+0xc8>
    panic("too big a transaction");
    80004340:	00005517          	auipc	a0,0x5
    80004344:	30850513          	addi	a0,a0,776 # 80009648 <syscalls+0x1f0>
    80004348:	ffffc097          	auipc	ra,0xffffc
    8000434c:	1f8080e7          	jalr	504(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004350:	00005517          	auipc	a0,0x5
    80004354:	31050513          	addi	a0,a0,784 # 80009660 <syscalls+0x208>
    80004358:	ffffc097          	auipc	ra,0xffffc
    8000435c:	1e8080e7          	jalr	488(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004360:	00878693          	addi	a3,a5,8
    80004364:	068a                	slli	a3,a3,0x2
    80004366:	0001e717          	auipc	a4,0x1e
    8000436a:	d1a70713          	addi	a4,a4,-742 # 80022080 <log>
    8000436e:	9736                	add	a4,a4,a3
    80004370:	44d4                	lw	a3,12(s1)
    80004372:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004374:	faf609e3          	beq	a2,a5,80004326 <log_write+0x76>
  }
  release(&log.lock);
    80004378:	0001e517          	auipc	a0,0x1e
    8000437c:	d0850513          	addi	a0,a0,-760 # 80022080 <log>
    80004380:	ffffd097          	auipc	ra,0xffffd
    80004384:	97c080e7          	jalr	-1668(ra) # 80000cfc <release>
}
    80004388:	60e2                	ld	ra,24(sp)
    8000438a:	6442                	ld	s0,16(sp)
    8000438c:	64a2                	ld	s1,8(sp)
    8000438e:	6902                	ld	s2,0(sp)
    80004390:	6105                	addi	sp,sp,32
    80004392:	8082                	ret

0000000080004394 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004394:	1101                	addi	sp,sp,-32
    80004396:	ec06                	sd	ra,24(sp)
    80004398:	e822                	sd	s0,16(sp)
    8000439a:	e426                	sd	s1,8(sp)
    8000439c:	e04a                	sd	s2,0(sp)
    8000439e:	1000                	addi	s0,sp,32
    800043a0:	84aa                	mv	s1,a0
    800043a2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043a4:	00005597          	auipc	a1,0x5
    800043a8:	2dc58593          	addi	a1,a1,732 # 80009680 <syscalls+0x228>
    800043ac:	0521                	addi	a0,a0,8
    800043ae:	ffffd097          	auipc	ra,0xffffd
    800043b2:	80a080e7          	jalr	-2038(ra) # 80000bb8 <initlock>
  lk->name = name;
    800043b6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043ba:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043be:	0204a423          	sw	zero,40(s1)
}
    800043c2:	60e2                	ld	ra,24(sp)
    800043c4:	6442                	ld	s0,16(sp)
    800043c6:	64a2                	ld	s1,8(sp)
    800043c8:	6902                	ld	s2,0(sp)
    800043ca:	6105                	addi	sp,sp,32
    800043cc:	8082                	ret

00000000800043ce <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043ce:	1101                	addi	sp,sp,-32
    800043d0:	ec06                	sd	ra,24(sp)
    800043d2:	e822                	sd	s0,16(sp)
    800043d4:	e426                	sd	s1,8(sp)
    800043d6:	e04a                	sd	s2,0(sp)
    800043d8:	1000                	addi	s0,sp,32
    800043da:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043dc:	00850913          	addi	s2,a0,8
    800043e0:	854a                	mv	a0,s2
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	866080e7          	jalr	-1946(ra) # 80000c48 <acquire>
  while (lk->locked) {
    800043ea:	409c                	lw	a5,0(s1)
    800043ec:	cb89                	beqz	a5,800043fe <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043ee:	85ca                	mv	a1,s2
    800043f0:	8526                	mv	a0,s1
    800043f2:	ffffe097          	auipc	ra,0xffffe
    800043f6:	d08080e7          	jalr	-760(ra) # 800020fa <sleep>
  while (lk->locked) {
    800043fa:	409c                	lw	a5,0(s1)
    800043fc:	fbed                	bnez	a5,800043ee <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043fe:	4785                	li	a5,1
    80004400:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004402:	ffffd097          	auipc	ra,0xffffd
    80004406:	622080e7          	jalr	1570(ra) # 80001a24 <myproc>
    8000440a:	591c                	lw	a5,48(a0)
    8000440c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000440e:	854a                	mv	a0,s2
    80004410:	ffffd097          	auipc	ra,0xffffd
    80004414:	8ec080e7          	jalr	-1812(ra) # 80000cfc <release>
}
    80004418:	60e2                	ld	ra,24(sp)
    8000441a:	6442                	ld	s0,16(sp)
    8000441c:	64a2                	ld	s1,8(sp)
    8000441e:	6902                	ld	s2,0(sp)
    80004420:	6105                	addi	sp,sp,32
    80004422:	8082                	ret

0000000080004424 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004424:	1101                	addi	sp,sp,-32
    80004426:	ec06                	sd	ra,24(sp)
    80004428:	e822                	sd	s0,16(sp)
    8000442a:	e426                	sd	s1,8(sp)
    8000442c:	e04a                	sd	s2,0(sp)
    8000442e:	1000                	addi	s0,sp,32
    80004430:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004432:	00850913          	addi	s2,a0,8
    80004436:	854a                	mv	a0,s2
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	810080e7          	jalr	-2032(ra) # 80000c48 <acquire>
  lk->locked = 0;
    80004440:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004444:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004448:	8526                	mv	a0,s1
    8000444a:	ffffe097          	auipc	ra,0xffffe
    8000444e:	d14080e7          	jalr	-748(ra) # 8000215e <wakeup>
  release(&lk->lk);
    80004452:	854a                	mv	a0,s2
    80004454:	ffffd097          	auipc	ra,0xffffd
    80004458:	8a8080e7          	jalr	-1880(ra) # 80000cfc <release>
}
    8000445c:	60e2                	ld	ra,24(sp)
    8000445e:	6442                	ld	s0,16(sp)
    80004460:	64a2                	ld	s1,8(sp)
    80004462:	6902                	ld	s2,0(sp)
    80004464:	6105                	addi	sp,sp,32
    80004466:	8082                	ret

0000000080004468 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004468:	7179                	addi	sp,sp,-48
    8000446a:	f406                	sd	ra,40(sp)
    8000446c:	f022                	sd	s0,32(sp)
    8000446e:	ec26                	sd	s1,24(sp)
    80004470:	e84a                	sd	s2,16(sp)
    80004472:	e44e                	sd	s3,8(sp)
    80004474:	1800                	addi	s0,sp,48
    80004476:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004478:	00850913          	addi	s2,a0,8
    8000447c:	854a                	mv	a0,s2
    8000447e:	ffffc097          	auipc	ra,0xffffc
    80004482:	7ca080e7          	jalr	1994(ra) # 80000c48 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004486:	409c                	lw	a5,0(s1)
    80004488:	ef99                	bnez	a5,800044a6 <holdingsleep+0x3e>
    8000448a:	4481                	li	s1,0
  release(&lk->lk);
    8000448c:	854a                	mv	a0,s2
    8000448e:	ffffd097          	auipc	ra,0xffffd
    80004492:	86e080e7          	jalr	-1938(ra) # 80000cfc <release>
  return r;
}
    80004496:	8526                	mv	a0,s1
    80004498:	70a2                	ld	ra,40(sp)
    8000449a:	7402                	ld	s0,32(sp)
    8000449c:	64e2                	ld	s1,24(sp)
    8000449e:	6942                	ld	s2,16(sp)
    800044a0:	69a2                	ld	s3,8(sp)
    800044a2:	6145                	addi	sp,sp,48
    800044a4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044a6:	0284a983          	lw	s3,40(s1)
    800044aa:	ffffd097          	auipc	ra,0xffffd
    800044ae:	57a080e7          	jalr	1402(ra) # 80001a24 <myproc>
    800044b2:	5904                	lw	s1,48(a0)
    800044b4:	413484b3          	sub	s1,s1,s3
    800044b8:	0014b493          	seqz	s1,s1
    800044bc:	bfc1                	j	8000448c <holdingsleep+0x24>

00000000800044be <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044be:	1141                	addi	sp,sp,-16
    800044c0:	e406                	sd	ra,8(sp)
    800044c2:	e022                	sd	s0,0(sp)
    800044c4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044c6:	00005597          	auipc	a1,0x5
    800044ca:	1ca58593          	addi	a1,a1,458 # 80009690 <syscalls+0x238>
    800044ce:	0001e517          	auipc	a0,0x1e
    800044d2:	cfa50513          	addi	a0,a0,-774 # 800221c8 <ftable>
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	6e2080e7          	jalr	1762(ra) # 80000bb8 <initlock>
}
    800044de:	60a2                	ld	ra,8(sp)
    800044e0:	6402                	ld	s0,0(sp)
    800044e2:	0141                	addi	sp,sp,16
    800044e4:	8082                	ret

00000000800044e6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044e6:	1101                	addi	sp,sp,-32
    800044e8:	ec06                	sd	ra,24(sp)
    800044ea:	e822                	sd	s0,16(sp)
    800044ec:	e426                	sd	s1,8(sp)
    800044ee:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044f0:	0001e517          	auipc	a0,0x1e
    800044f4:	cd850513          	addi	a0,a0,-808 # 800221c8 <ftable>
    800044f8:	ffffc097          	auipc	ra,0xffffc
    800044fc:	750080e7          	jalr	1872(ra) # 80000c48 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004500:	0001e497          	auipc	s1,0x1e
    80004504:	ce048493          	addi	s1,s1,-800 # 800221e0 <ftable+0x18>
    80004508:	0001f717          	auipc	a4,0x1f
    8000450c:	c7870713          	addi	a4,a4,-904 # 80023180 <disk>
    if(f->ref == 0){
    80004510:	40dc                	lw	a5,4(s1)
    80004512:	cf99                	beqz	a5,80004530 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004514:	02848493          	addi	s1,s1,40
    80004518:	fee49ce3          	bne	s1,a4,80004510 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000451c:	0001e517          	auipc	a0,0x1e
    80004520:	cac50513          	addi	a0,a0,-852 # 800221c8 <ftable>
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	7d8080e7          	jalr	2008(ra) # 80000cfc <release>
  return 0;
    8000452c:	4481                	li	s1,0
    8000452e:	a819                	j	80004544 <filealloc+0x5e>
      f->ref = 1;
    80004530:	4785                	li	a5,1
    80004532:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004534:	0001e517          	auipc	a0,0x1e
    80004538:	c9450513          	addi	a0,a0,-876 # 800221c8 <ftable>
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	7c0080e7          	jalr	1984(ra) # 80000cfc <release>
}
    80004544:	8526                	mv	a0,s1
    80004546:	60e2                	ld	ra,24(sp)
    80004548:	6442                	ld	s0,16(sp)
    8000454a:	64a2                	ld	s1,8(sp)
    8000454c:	6105                	addi	sp,sp,32
    8000454e:	8082                	ret

0000000080004550 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004550:	1101                	addi	sp,sp,-32
    80004552:	ec06                	sd	ra,24(sp)
    80004554:	e822                	sd	s0,16(sp)
    80004556:	e426                	sd	s1,8(sp)
    80004558:	1000                	addi	s0,sp,32
    8000455a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000455c:	0001e517          	auipc	a0,0x1e
    80004560:	c6c50513          	addi	a0,a0,-916 # 800221c8 <ftable>
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	6e4080e7          	jalr	1764(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    8000456c:	40dc                	lw	a5,4(s1)
    8000456e:	02f05263          	blez	a5,80004592 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004572:	2785                	addiw	a5,a5,1
    80004574:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004576:	0001e517          	auipc	a0,0x1e
    8000457a:	c5250513          	addi	a0,a0,-942 # 800221c8 <ftable>
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	77e080e7          	jalr	1918(ra) # 80000cfc <release>
  return f;
}
    80004586:	8526                	mv	a0,s1
    80004588:	60e2                	ld	ra,24(sp)
    8000458a:	6442                	ld	s0,16(sp)
    8000458c:	64a2                	ld	s1,8(sp)
    8000458e:	6105                	addi	sp,sp,32
    80004590:	8082                	ret
    panic("filedup");
    80004592:	00005517          	auipc	a0,0x5
    80004596:	10650513          	addi	a0,a0,262 # 80009698 <syscalls+0x240>
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	fa6080e7          	jalr	-90(ra) # 80000540 <panic>

00000000800045a2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045a2:	7139                	addi	sp,sp,-64
    800045a4:	fc06                	sd	ra,56(sp)
    800045a6:	f822                	sd	s0,48(sp)
    800045a8:	f426                	sd	s1,40(sp)
    800045aa:	f04a                	sd	s2,32(sp)
    800045ac:	ec4e                	sd	s3,24(sp)
    800045ae:	e852                	sd	s4,16(sp)
    800045b0:	e456                	sd	s5,8(sp)
    800045b2:	0080                	addi	s0,sp,64
    800045b4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045b6:	0001e517          	auipc	a0,0x1e
    800045ba:	c1250513          	addi	a0,a0,-1006 # 800221c8 <ftable>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	68a080e7          	jalr	1674(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    800045c6:	40dc                	lw	a5,4(s1)
    800045c8:	06f05163          	blez	a5,8000462a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045cc:	37fd                	addiw	a5,a5,-1
    800045ce:	0007871b          	sext.w	a4,a5
    800045d2:	c0dc                	sw	a5,4(s1)
    800045d4:	06e04363          	bgtz	a4,8000463a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045d8:	0004a903          	lw	s2,0(s1)
    800045dc:	0094ca83          	lbu	s5,9(s1)
    800045e0:	0104ba03          	ld	s4,16(s1)
    800045e4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045e8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045ec:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045f0:	0001e517          	auipc	a0,0x1e
    800045f4:	bd850513          	addi	a0,a0,-1064 # 800221c8 <ftable>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	704080e7          	jalr	1796(ra) # 80000cfc <release>

  if(ff.type == FD_PIPE){
    80004600:	4785                	li	a5,1
    80004602:	04f90d63          	beq	s2,a5,8000465c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004606:	3979                	addiw	s2,s2,-2
    80004608:	4785                	li	a5,1
    8000460a:	0527e063          	bltu	a5,s2,8000464a <fileclose+0xa8>
    begin_op();
    8000460e:	00000097          	auipc	ra,0x0
    80004612:	ad0080e7          	jalr	-1328(ra) # 800040de <begin_op>
    iput(ff.ip);
    80004616:	854e                	mv	a0,s3
    80004618:	fffff097          	auipc	ra,0xfffff
    8000461c:	2da080e7          	jalr	730(ra) # 800038f2 <iput>
    end_op();
    80004620:	00000097          	auipc	ra,0x0
    80004624:	b38080e7          	jalr	-1224(ra) # 80004158 <end_op>
    80004628:	a00d                	j	8000464a <fileclose+0xa8>
    panic("fileclose");
    8000462a:	00005517          	auipc	a0,0x5
    8000462e:	07650513          	addi	a0,a0,118 # 800096a0 <syscalls+0x248>
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	f0e080e7          	jalr	-242(ra) # 80000540 <panic>
    release(&ftable.lock);
    8000463a:	0001e517          	auipc	a0,0x1e
    8000463e:	b8e50513          	addi	a0,a0,-1138 # 800221c8 <ftable>
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	6ba080e7          	jalr	1722(ra) # 80000cfc <release>
  }
}
    8000464a:	70e2                	ld	ra,56(sp)
    8000464c:	7442                	ld	s0,48(sp)
    8000464e:	74a2                	ld	s1,40(sp)
    80004650:	7902                	ld	s2,32(sp)
    80004652:	69e2                	ld	s3,24(sp)
    80004654:	6a42                	ld	s4,16(sp)
    80004656:	6aa2                	ld	s5,8(sp)
    80004658:	6121                	addi	sp,sp,64
    8000465a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000465c:	85d6                	mv	a1,s5
    8000465e:	8552                	mv	a0,s4
    80004660:	00000097          	auipc	ra,0x0
    80004664:	348080e7          	jalr	840(ra) # 800049a8 <pipeclose>
    80004668:	b7cd                	j	8000464a <fileclose+0xa8>

000000008000466a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000466a:	715d                	addi	sp,sp,-80
    8000466c:	e486                	sd	ra,72(sp)
    8000466e:	e0a2                	sd	s0,64(sp)
    80004670:	fc26                	sd	s1,56(sp)
    80004672:	f84a                	sd	s2,48(sp)
    80004674:	f44e                	sd	s3,40(sp)
    80004676:	0880                	addi	s0,sp,80
    80004678:	84aa                	mv	s1,a0
    8000467a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000467c:	ffffd097          	auipc	ra,0xffffd
    80004680:	3a8080e7          	jalr	936(ra) # 80001a24 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004684:	409c                	lw	a5,0(s1)
    80004686:	37f9                	addiw	a5,a5,-2
    80004688:	4705                	li	a4,1
    8000468a:	04f76763          	bltu	a4,a5,800046d8 <filestat+0x6e>
    8000468e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004690:	6c88                	ld	a0,24(s1)
    80004692:	fffff097          	auipc	ra,0xfffff
    80004696:	0a6080e7          	jalr	166(ra) # 80003738 <ilock>
    stati(f->ip, &st);
    8000469a:	fb840593          	addi	a1,s0,-72
    8000469e:	6c88                	ld	a0,24(s1)
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	322080e7          	jalr	802(ra) # 800039c2 <stati>
    iunlock(f->ip);
    800046a8:	6c88                	ld	a0,24(s1)
    800046aa:	fffff097          	auipc	ra,0xfffff
    800046ae:	150080e7          	jalr	336(ra) # 800037fa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046b2:	46e1                	li	a3,24
    800046b4:	fb840613          	addi	a2,s0,-72
    800046b8:	85ce                	mv	a1,s3
    800046ba:	05093503          	ld	a0,80(s2)
    800046be:	ffffd097          	auipc	ra,0xffffd
    800046c2:	026080e7          	jalr	38(ra) # 800016e4 <copyout>
    800046c6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046ca:	60a6                	ld	ra,72(sp)
    800046cc:	6406                	ld	s0,64(sp)
    800046ce:	74e2                	ld	s1,56(sp)
    800046d0:	7942                	ld	s2,48(sp)
    800046d2:	79a2                	ld	s3,40(sp)
    800046d4:	6161                	addi	sp,sp,80
    800046d6:	8082                	ret
  return -1;
    800046d8:	557d                	li	a0,-1
    800046da:	bfc5                	j	800046ca <filestat+0x60>

00000000800046dc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046dc:	7179                	addi	sp,sp,-48
    800046de:	f406                	sd	ra,40(sp)
    800046e0:	f022                	sd	s0,32(sp)
    800046e2:	ec26                	sd	s1,24(sp)
    800046e4:	e84a                	sd	s2,16(sp)
    800046e6:	e44e                	sd	s3,8(sp)
    800046e8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046ea:	00854783          	lbu	a5,8(a0)
    800046ee:	c3d5                	beqz	a5,80004792 <fileread+0xb6>
    800046f0:	84aa                	mv	s1,a0
    800046f2:	89ae                	mv	s3,a1
    800046f4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046f6:	411c                	lw	a5,0(a0)
    800046f8:	4705                	li	a4,1
    800046fa:	04e78963          	beq	a5,a4,8000474c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046fe:	470d                	li	a4,3
    80004700:	04e78d63          	beq	a5,a4,8000475a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004704:	4709                	li	a4,2
    80004706:	06e79e63          	bne	a5,a4,80004782 <fileread+0xa6>
    ilock(f->ip);
    8000470a:	6d08                	ld	a0,24(a0)
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	02c080e7          	jalr	44(ra) # 80003738 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004714:	874a                	mv	a4,s2
    80004716:	5094                	lw	a3,32(s1)
    80004718:	864e                	mv	a2,s3
    8000471a:	4585                	li	a1,1
    8000471c:	6c88                	ld	a0,24(s1)
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	2ce080e7          	jalr	718(ra) # 800039ec <readi>
    80004726:	892a                	mv	s2,a0
    80004728:	00a05563          	blez	a0,80004732 <fileread+0x56>
      f->off += r;
    8000472c:	509c                	lw	a5,32(s1)
    8000472e:	9fa9                	addw	a5,a5,a0
    80004730:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004732:	6c88                	ld	a0,24(s1)
    80004734:	fffff097          	auipc	ra,0xfffff
    80004738:	0c6080e7          	jalr	198(ra) # 800037fa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000473c:	854a                	mv	a0,s2
    8000473e:	70a2                	ld	ra,40(sp)
    80004740:	7402                	ld	s0,32(sp)
    80004742:	64e2                	ld	s1,24(sp)
    80004744:	6942                	ld	s2,16(sp)
    80004746:	69a2                	ld	s3,8(sp)
    80004748:	6145                	addi	sp,sp,48
    8000474a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000474c:	6908                	ld	a0,16(a0)
    8000474e:	00000097          	auipc	ra,0x0
    80004752:	3c2080e7          	jalr	962(ra) # 80004b10 <piperead>
    80004756:	892a                	mv	s2,a0
    80004758:	b7d5                	j	8000473c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000475a:	02451783          	lh	a5,36(a0)
    8000475e:	03079693          	slli	a3,a5,0x30
    80004762:	92c1                	srli	a3,a3,0x30
    80004764:	4725                	li	a4,9
    80004766:	02d76863          	bltu	a4,a3,80004796 <fileread+0xba>
    8000476a:	0792                	slli	a5,a5,0x4
    8000476c:	0001e717          	auipc	a4,0x1e
    80004770:	9bc70713          	addi	a4,a4,-1604 # 80022128 <devsw>
    80004774:	97ba                	add	a5,a5,a4
    80004776:	639c                	ld	a5,0(a5)
    80004778:	c38d                	beqz	a5,8000479a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000477a:	4505                	li	a0,1
    8000477c:	9782                	jalr	a5
    8000477e:	892a                	mv	s2,a0
    80004780:	bf75                	j	8000473c <fileread+0x60>
    panic("fileread");
    80004782:	00005517          	auipc	a0,0x5
    80004786:	f2e50513          	addi	a0,a0,-210 # 800096b0 <syscalls+0x258>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	db6080e7          	jalr	-586(ra) # 80000540 <panic>
    return -1;
    80004792:	597d                	li	s2,-1
    80004794:	b765                	j	8000473c <fileread+0x60>
      return -1;
    80004796:	597d                	li	s2,-1
    80004798:	b755                	j	8000473c <fileread+0x60>
    8000479a:	597d                	li	s2,-1
    8000479c:	b745                	j	8000473c <fileread+0x60>

000000008000479e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000479e:	00954783          	lbu	a5,9(a0)
    800047a2:	10078e63          	beqz	a5,800048be <filewrite+0x120>
{
    800047a6:	715d                	addi	sp,sp,-80
    800047a8:	e486                	sd	ra,72(sp)
    800047aa:	e0a2                	sd	s0,64(sp)
    800047ac:	fc26                	sd	s1,56(sp)
    800047ae:	f84a                	sd	s2,48(sp)
    800047b0:	f44e                	sd	s3,40(sp)
    800047b2:	f052                	sd	s4,32(sp)
    800047b4:	ec56                	sd	s5,24(sp)
    800047b6:	e85a                	sd	s6,16(sp)
    800047b8:	e45e                	sd	s7,8(sp)
    800047ba:	e062                	sd	s8,0(sp)
    800047bc:	0880                	addi	s0,sp,80
    800047be:	892a                	mv	s2,a0
    800047c0:	8b2e                	mv	s6,a1
    800047c2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047c4:	411c                	lw	a5,0(a0)
    800047c6:	4705                	li	a4,1
    800047c8:	02e78263          	beq	a5,a4,800047ec <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047cc:	470d                	li	a4,3
    800047ce:	02e78563          	beq	a5,a4,800047f8 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047d2:	4709                	li	a4,2
    800047d4:	0ce79d63          	bne	a5,a4,800048ae <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047d8:	0ac05b63          	blez	a2,8000488e <filewrite+0xf0>
    int i = 0;
    800047dc:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800047de:	6b85                	lui	s7,0x1
    800047e0:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047e4:	6c05                	lui	s8,0x1
    800047e6:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047ea:	a851                	j	8000487e <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047ec:	6908                	ld	a0,16(a0)
    800047ee:	00000097          	auipc	ra,0x0
    800047f2:	22a080e7          	jalr	554(ra) # 80004a18 <pipewrite>
    800047f6:	a045                	j	80004896 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047f8:	02451783          	lh	a5,36(a0)
    800047fc:	03079693          	slli	a3,a5,0x30
    80004800:	92c1                	srli	a3,a3,0x30
    80004802:	4725                	li	a4,9
    80004804:	0ad76f63          	bltu	a4,a3,800048c2 <filewrite+0x124>
    80004808:	0792                	slli	a5,a5,0x4
    8000480a:	0001e717          	auipc	a4,0x1e
    8000480e:	91e70713          	addi	a4,a4,-1762 # 80022128 <devsw>
    80004812:	97ba                	add	a5,a5,a4
    80004814:	679c                	ld	a5,8(a5)
    80004816:	cbc5                	beqz	a5,800048c6 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004818:	4505                	li	a0,1
    8000481a:	9782                	jalr	a5
    8000481c:	a8ad                	j	80004896 <filewrite+0xf8>
      if(n1 > max)
    8000481e:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004822:	00000097          	auipc	ra,0x0
    80004826:	8bc080e7          	jalr	-1860(ra) # 800040de <begin_op>
      ilock(f->ip);
    8000482a:	01893503          	ld	a0,24(s2)
    8000482e:	fffff097          	auipc	ra,0xfffff
    80004832:	f0a080e7          	jalr	-246(ra) # 80003738 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004836:	8756                	mv	a4,s5
    80004838:	02092683          	lw	a3,32(s2)
    8000483c:	01698633          	add	a2,s3,s6
    80004840:	4585                	li	a1,1
    80004842:	01893503          	ld	a0,24(s2)
    80004846:	fffff097          	auipc	ra,0xfffff
    8000484a:	29e080e7          	jalr	670(ra) # 80003ae4 <writei>
    8000484e:	84aa                	mv	s1,a0
    80004850:	00a05763          	blez	a0,8000485e <filewrite+0xc0>
        f->off += r;
    80004854:	02092783          	lw	a5,32(s2)
    80004858:	9fa9                	addw	a5,a5,a0
    8000485a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000485e:	01893503          	ld	a0,24(s2)
    80004862:	fffff097          	auipc	ra,0xfffff
    80004866:	f98080e7          	jalr	-104(ra) # 800037fa <iunlock>
      end_op();
    8000486a:	00000097          	auipc	ra,0x0
    8000486e:	8ee080e7          	jalr	-1810(ra) # 80004158 <end_op>

      if(r != n1){
    80004872:	009a9f63          	bne	s5,s1,80004890 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004876:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000487a:	0149db63          	bge	s3,s4,80004890 <filewrite+0xf2>
      int n1 = n - i;
    8000487e:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004882:	0004879b          	sext.w	a5,s1
    80004886:	f8fbdce3          	bge	s7,a5,8000481e <filewrite+0x80>
    8000488a:	84e2                	mv	s1,s8
    8000488c:	bf49                	j	8000481e <filewrite+0x80>
    int i = 0;
    8000488e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004890:	033a1d63          	bne	s4,s3,800048ca <filewrite+0x12c>
    80004894:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004896:	60a6                	ld	ra,72(sp)
    80004898:	6406                	ld	s0,64(sp)
    8000489a:	74e2                	ld	s1,56(sp)
    8000489c:	7942                	ld	s2,48(sp)
    8000489e:	79a2                	ld	s3,40(sp)
    800048a0:	7a02                	ld	s4,32(sp)
    800048a2:	6ae2                	ld	s5,24(sp)
    800048a4:	6b42                	ld	s6,16(sp)
    800048a6:	6ba2                	ld	s7,8(sp)
    800048a8:	6c02                	ld	s8,0(sp)
    800048aa:	6161                	addi	sp,sp,80
    800048ac:	8082                	ret
    panic("filewrite");
    800048ae:	00005517          	auipc	a0,0x5
    800048b2:	e1250513          	addi	a0,a0,-494 # 800096c0 <syscalls+0x268>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	c8a080e7          	jalr	-886(ra) # 80000540 <panic>
    return -1;
    800048be:	557d                	li	a0,-1
}
    800048c0:	8082                	ret
      return -1;
    800048c2:	557d                	li	a0,-1
    800048c4:	bfc9                	j	80004896 <filewrite+0xf8>
    800048c6:	557d                	li	a0,-1
    800048c8:	b7f9                	j	80004896 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800048ca:	557d                	li	a0,-1
    800048cc:	b7e9                	j	80004896 <filewrite+0xf8>

00000000800048ce <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048ce:	7179                	addi	sp,sp,-48
    800048d0:	f406                	sd	ra,40(sp)
    800048d2:	f022                	sd	s0,32(sp)
    800048d4:	ec26                	sd	s1,24(sp)
    800048d6:	e84a                	sd	s2,16(sp)
    800048d8:	e44e                	sd	s3,8(sp)
    800048da:	e052                	sd	s4,0(sp)
    800048dc:	1800                	addi	s0,sp,48
    800048de:	84aa                	mv	s1,a0
    800048e0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048e2:	0005b023          	sd	zero,0(a1)
    800048e6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048ea:	00000097          	auipc	ra,0x0
    800048ee:	bfc080e7          	jalr	-1028(ra) # 800044e6 <filealloc>
    800048f2:	e088                	sd	a0,0(s1)
    800048f4:	c551                	beqz	a0,80004980 <pipealloc+0xb2>
    800048f6:	00000097          	auipc	ra,0x0
    800048fa:	bf0080e7          	jalr	-1040(ra) # 800044e6 <filealloc>
    800048fe:	00aa3023          	sd	a0,0(s4)
    80004902:	c92d                	beqz	a0,80004974 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	254080e7          	jalr	596(ra) # 80000b58 <kalloc>
    8000490c:	892a                	mv	s2,a0
    8000490e:	c125                	beqz	a0,8000496e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004910:	4985                	li	s3,1
    80004912:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004916:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000491a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000491e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004922:	00005597          	auipc	a1,0x5
    80004926:	dae58593          	addi	a1,a1,-594 # 800096d0 <syscalls+0x278>
    8000492a:	ffffc097          	auipc	ra,0xffffc
    8000492e:	28e080e7          	jalr	654(ra) # 80000bb8 <initlock>
  (*f0)->type = FD_PIPE;
    80004932:	609c                	ld	a5,0(s1)
    80004934:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004938:	609c                	ld	a5,0(s1)
    8000493a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000493e:	609c                	ld	a5,0(s1)
    80004940:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004944:	609c                	ld	a5,0(s1)
    80004946:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000494a:	000a3783          	ld	a5,0(s4)
    8000494e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004952:	000a3783          	ld	a5,0(s4)
    80004956:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000495a:	000a3783          	ld	a5,0(s4)
    8000495e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004962:	000a3783          	ld	a5,0(s4)
    80004966:	0127b823          	sd	s2,16(a5)
  return 0;
    8000496a:	4501                	li	a0,0
    8000496c:	a025                	j	80004994 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000496e:	6088                	ld	a0,0(s1)
    80004970:	e501                	bnez	a0,80004978 <pipealloc+0xaa>
    80004972:	a039                	j	80004980 <pipealloc+0xb2>
    80004974:	6088                	ld	a0,0(s1)
    80004976:	c51d                	beqz	a0,800049a4 <pipealloc+0xd6>
    fileclose(*f0);
    80004978:	00000097          	auipc	ra,0x0
    8000497c:	c2a080e7          	jalr	-982(ra) # 800045a2 <fileclose>
  if(*f1)
    80004980:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004984:	557d                	li	a0,-1
  if(*f1)
    80004986:	c799                	beqz	a5,80004994 <pipealloc+0xc6>
    fileclose(*f1);
    80004988:	853e                	mv	a0,a5
    8000498a:	00000097          	auipc	ra,0x0
    8000498e:	c18080e7          	jalr	-1000(ra) # 800045a2 <fileclose>
  return -1;
    80004992:	557d                	li	a0,-1
}
    80004994:	70a2                	ld	ra,40(sp)
    80004996:	7402                	ld	s0,32(sp)
    80004998:	64e2                	ld	s1,24(sp)
    8000499a:	6942                	ld	s2,16(sp)
    8000499c:	69a2                	ld	s3,8(sp)
    8000499e:	6a02                	ld	s4,0(sp)
    800049a0:	6145                	addi	sp,sp,48
    800049a2:	8082                	ret
  return -1;
    800049a4:	557d                	li	a0,-1
    800049a6:	b7fd                	j	80004994 <pipealloc+0xc6>

00000000800049a8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049a8:	1101                	addi	sp,sp,-32
    800049aa:	ec06                	sd	ra,24(sp)
    800049ac:	e822                	sd	s0,16(sp)
    800049ae:	e426                	sd	s1,8(sp)
    800049b0:	e04a                	sd	s2,0(sp)
    800049b2:	1000                	addi	s0,sp,32
    800049b4:	84aa                	mv	s1,a0
    800049b6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	290080e7          	jalr	656(ra) # 80000c48 <acquire>
  if(writable){
    800049c0:	02090d63          	beqz	s2,800049fa <pipeclose+0x52>
    pi->writeopen = 0;
    800049c4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049c8:	21848513          	addi	a0,s1,536
    800049cc:	ffffd097          	auipc	ra,0xffffd
    800049d0:	792080e7          	jalr	1938(ra) # 8000215e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049d4:	2204b783          	ld	a5,544(s1)
    800049d8:	eb95                	bnez	a5,80004a0c <pipeclose+0x64>
    release(&pi->lock);
    800049da:	8526                	mv	a0,s1
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	320080e7          	jalr	800(ra) # 80000cfc <release>
    kfree((char*)pi);
    800049e4:	8526                	mv	a0,s1
    800049e6:	ffffc097          	auipc	ra,0xffffc
    800049ea:	074080e7          	jalr	116(ra) # 80000a5a <kfree>
  } else
    release(&pi->lock);
}
    800049ee:	60e2                	ld	ra,24(sp)
    800049f0:	6442                	ld	s0,16(sp)
    800049f2:	64a2                	ld	s1,8(sp)
    800049f4:	6902                	ld	s2,0(sp)
    800049f6:	6105                	addi	sp,sp,32
    800049f8:	8082                	ret
    pi->readopen = 0;
    800049fa:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049fe:	21c48513          	addi	a0,s1,540
    80004a02:	ffffd097          	auipc	ra,0xffffd
    80004a06:	75c080e7          	jalr	1884(ra) # 8000215e <wakeup>
    80004a0a:	b7e9                	j	800049d4 <pipeclose+0x2c>
    release(&pi->lock);
    80004a0c:	8526                	mv	a0,s1
    80004a0e:	ffffc097          	auipc	ra,0xffffc
    80004a12:	2ee080e7          	jalr	750(ra) # 80000cfc <release>
}
    80004a16:	bfe1                	j	800049ee <pipeclose+0x46>

0000000080004a18 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a18:	711d                	addi	sp,sp,-96
    80004a1a:	ec86                	sd	ra,88(sp)
    80004a1c:	e8a2                	sd	s0,80(sp)
    80004a1e:	e4a6                	sd	s1,72(sp)
    80004a20:	e0ca                	sd	s2,64(sp)
    80004a22:	fc4e                	sd	s3,56(sp)
    80004a24:	f852                	sd	s4,48(sp)
    80004a26:	f456                	sd	s5,40(sp)
    80004a28:	f05a                	sd	s6,32(sp)
    80004a2a:	ec5e                	sd	s7,24(sp)
    80004a2c:	e862                	sd	s8,16(sp)
    80004a2e:	1080                	addi	s0,sp,96
    80004a30:	84aa                	mv	s1,a0
    80004a32:	8aae                	mv	s5,a1
    80004a34:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a36:	ffffd097          	auipc	ra,0xffffd
    80004a3a:	fee080e7          	jalr	-18(ra) # 80001a24 <myproc>
    80004a3e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a40:	8526                	mv	a0,s1
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	206080e7          	jalr	518(ra) # 80000c48 <acquire>
  while(i < n){
    80004a4a:	0b405663          	blez	s4,80004af6 <pipewrite+0xde>
  int i = 0;
    80004a4e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a50:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a52:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a56:	21c48b93          	addi	s7,s1,540
    80004a5a:	a089                	j	80004a9c <pipewrite+0x84>
      release(&pi->lock);
    80004a5c:	8526                	mv	a0,s1
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	29e080e7          	jalr	670(ra) # 80000cfc <release>
      return -1;
    80004a66:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a68:	854a                	mv	a0,s2
    80004a6a:	60e6                	ld	ra,88(sp)
    80004a6c:	6446                	ld	s0,80(sp)
    80004a6e:	64a6                	ld	s1,72(sp)
    80004a70:	6906                	ld	s2,64(sp)
    80004a72:	79e2                	ld	s3,56(sp)
    80004a74:	7a42                	ld	s4,48(sp)
    80004a76:	7aa2                	ld	s5,40(sp)
    80004a78:	7b02                	ld	s6,32(sp)
    80004a7a:	6be2                	ld	s7,24(sp)
    80004a7c:	6c42                	ld	s8,16(sp)
    80004a7e:	6125                	addi	sp,sp,96
    80004a80:	8082                	ret
      wakeup(&pi->nread);
    80004a82:	8562                	mv	a0,s8
    80004a84:	ffffd097          	auipc	ra,0xffffd
    80004a88:	6da080e7          	jalr	1754(ra) # 8000215e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a8c:	85a6                	mv	a1,s1
    80004a8e:	855e                	mv	a0,s7
    80004a90:	ffffd097          	auipc	ra,0xffffd
    80004a94:	66a080e7          	jalr	1642(ra) # 800020fa <sleep>
  while(i < n){
    80004a98:	07495063          	bge	s2,s4,80004af8 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004a9c:	2204a783          	lw	a5,544(s1)
    80004aa0:	dfd5                	beqz	a5,80004a5c <pipewrite+0x44>
    80004aa2:	854e                	mv	a0,s3
    80004aa4:	ffffe097          	auipc	ra,0xffffe
    80004aa8:	8fe080e7          	jalr	-1794(ra) # 800023a2 <killed>
    80004aac:	f945                	bnez	a0,80004a5c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004aae:	2184a783          	lw	a5,536(s1)
    80004ab2:	21c4a703          	lw	a4,540(s1)
    80004ab6:	2007879b          	addiw	a5,a5,512
    80004aba:	fcf704e3          	beq	a4,a5,80004a82 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004abe:	4685                	li	a3,1
    80004ac0:	01590633          	add	a2,s2,s5
    80004ac4:	faf40593          	addi	a1,s0,-81
    80004ac8:	0509b503          	ld	a0,80(s3)
    80004acc:	ffffd097          	auipc	ra,0xffffd
    80004ad0:	ca4080e7          	jalr	-860(ra) # 80001770 <copyin>
    80004ad4:	03650263          	beq	a0,s6,80004af8 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ad8:	21c4a783          	lw	a5,540(s1)
    80004adc:	0017871b          	addiw	a4,a5,1
    80004ae0:	20e4ae23          	sw	a4,540(s1)
    80004ae4:	1ff7f793          	andi	a5,a5,511
    80004ae8:	97a6                	add	a5,a5,s1
    80004aea:	faf44703          	lbu	a4,-81(s0)
    80004aee:	00e78c23          	sb	a4,24(a5)
      i++;
    80004af2:	2905                	addiw	s2,s2,1
    80004af4:	b755                	j	80004a98 <pipewrite+0x80>
  int i = 0;
    80004af6:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004af8:	21848513          	addi	a0,s1,536
    80004afc:	ffffd097          	auipc	ra,0xffffd
    80004b00:	662080e7          	jalr	1634(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004b04:	8526                	mv	a0,s1
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	1f6080e7          	jalr	502(ra) # 80000cfc <release>
  return i;
    80004b0e:	bfa9                	j	80004a68 <pipewrite+0x50>

0000000080004b10 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b10:	715d                	addi	sp,sp,-80
    80004b12:	e486                	sd	ra,72(sp)
    80004b14:	e0a2                	sd	s0,64(sp)
    80004b16:	fc26                	sd	s1,56(sp)
    80004b18:	f84a                	sd	s2,48(sp)
    80004b1a:	f44e                	sd	s3,40(sp)
    80004b1c:	f052                	sd	s4,32(sp)
    80004b1e:	ec56                	sd	s5,24(sp)
    80004b20:	e85a                	sd	s6,16(sp)
    80004b22:	0880                	addi	s0,sp,80
    80004b24:	84aa                	mv	s1,a0
    80004b26:	892e                	mv	s2,a1
    80004b28:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b2a:	ffffd097          	auipc	ra,0xffffd
    80004b2e:	efa080e7          	jalr	-262(ra) # 80001a24 <myproc>
    80004b32:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b34:	8526                	mv	a0,s1
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	112080e7          	jalr	274(ra) # 80000c48 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b3e:	2184a703          	lw	a4,536(s1)
    80004b42:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b46:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b4a:	02f71763          	bne	a4,a5,80004b78 <piperead+0x68>
    80004b4e:	2244a783          	lw	a5,548(s1)
    80004b52:	c39d                	beqz	a5,80004b78 <piperead+0x68>
    if(killed(pr)){
    80004b54:	8552                	mv	a0,s4
    80004b56:	ffffe097          	auipc	ra,0xffffe
    80004b5a:	84c080e7          	jalr	-1972(ra) # 800023a2 <killed>
    80004b5e:	e949                	bnez	a0,80004bf0 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b60:	85a6                	mv	a1,s1
    80004b62:	854e                	mv	a0,s3
    80004b64:	ffffd097          	auipc	ra,0xffffd
    80004b68:	596080e7          	jalr	1430(ra) # 800020fa <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b6c:	2184a703          	lw	a4,536(s1)
    80004b70:	21c4a783          	lw	a5,540(s1)
    80004b74:	fcf70de3          	beq	a4,a5,80004b4e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b78:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b7a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b7c:	05505463          	blez	s5,80004bc4 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004b80:	2184a783          	lw	a5,536(s1)
    80004b84:	21c4a703          	lw	a4,540(s1)
    80004b88:	02f70e63          	beq	a4,a5,80004bc4 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b8c:	0017871b          	addiw	a4,a5,1
    80004b90:	20e4ac23          	sw	a4,536(s1)
    80004b94:	1ff7f793          	andi	a5,a5,511
    80004b98:	97a6                	add	a5,a5,s1
    80004b9a:	0187c783          	lbu	a5,24(a5)
    80004b9e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ba2:	4685                	li	a3,1
    80004ba4:	fbf40613          	addi	a2,s0,-65
    80004ba8:	85ca                	mv	a1,s2
    80004baa:	050a3503          	ld	a0,80(s4)
    80004bae:	ffffd097          	auipc	ra,0xffffd
    80004bb2:	b36080e7          	jalr	-1226(ra) # 800016e4 <copyout>
    80004bb6:	01650763          	beq	a0,s6,80004bc4 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bba:	2985                	addiw	s3,s3,1
    80004bbc:	0905                	addi	s2,s2,1
    80004bbe:	fd3a91e3          	bne	s5,s3,80004b80 <piperead+0x70>
    80004bc2:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bc4:	21c48513          	addi	a0,s1,540
    80004bc8:	ffffd097          	auipc	ra,0xffffd
    80004bcc:	596080e7          	jalr	1430(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004bd0:	8526                	mv	a0,s1
    80004bd2:	ffffc097          	auipc	ra,0xffffc
    80004bd6:	12a080e7          	jalr	298(ra) # 80000cfc <release>
  return i;
}
    80004bda:	854e                	mv	a0,s3
    80004bdc:	60a6                	ld	ra,72(sp)
    80004bde:	6406                	ld	s0,64(sp)
    80004be0:	74e2                	ld	s1,56(sp)
    80004be2:	7942                	ld	s2,48(sp)
    80004be4:	79a2                	ld	s3,40(sp)
    80004be6:	7a02                	ld	s4,32(sp)
    80004be8:	6ae2                	ld	s5,24(sp)
    80004bea:	6b42                	ld	s6,16(sp)
    80004bec:	6161                	addi	sp,sp,80
    80004bee:	8082                	ret
      release(&pi->lock);
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	ffffc097          	auipc	ra,0xffffc
    80004bf6:	10a080e7          	jalr	266(ra) # 80000cfc <release>
      return -1;
    80004bfa:	59fd                	li	s3,-1
    80004bfc:	bff9                	j	80004bda <piperead+0xca>

0000000080004bfe <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004bfe:	1141                	addi	sp,sp,-16
    80004c00:	e422                	sd	s0,8(sp)
    80004c02:	0800                	addi	s0,sp,16
    80004c04:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c06:	8905                	andi	a0,a0,1
    80004c08:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004c0a:	8b89                	andi	a5,a5,2
    80004c0c:	c399                	beqz	a5,80004c12 <flags2perm+0x14>
      perm |= PTE_W;
    80004c0e:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c12:	6422                	ld	s0,8(sp)
    80004c14:	0141                	addi	sp,sp,16
    80004c16:	8082                	ret

0000000080004c18 <exec>:

int
exec(char *path, char **argv)
{
    80004c18:	df010113          	addi	sp,sp,-528
    80004c1c:	20113423          	sd	ra,520(sp)
    80004c20:	20813023          	sd	s0,512(sp)
    80004c24:	ffa6                	sd	s1,504(sp)
    80004c26:	fbca                	sd	s2,496(sp)
    80004c28:	f7ce                	sd	s3,488(sp)
    80004c2a:	f3d2                	sd	s4,480(sp)
    80004c2c:	efd6                	sd	s5,472(sp)
    80004c2e:	ebda                	sd	s6,464(sp)
    80004c30:	e7de                	sd	s7,456(sp)
    80004c32:	e3e2                	sd	s8,448(sp)
    80004c34:	ff66                	sd	s9,440(sp)
    80004c36:	fb6a                	sd	s10,432(sp)
    80004c38:	f76e                	sd	s11,424(sp)
    80004c3a:	0c00                	addi	s0,sp,528
    80004c3c:	892a                	mv	s2,a0
    80004c3e:	dea43c23          	sd	a0,-520(s0)
    80004c42:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	dde080e7          	jalr	-546(ra) # 80001a24 <myproc>
    80004c4e:	84aa                	mv	s1,a0

  begin_op();
    80004c50:	fffff097          	auipc	ra,0xfffff
    80004c54:	48e080e7          	jalr	1166(ra) # 800040de <begin_op>

  if((ip = namei(path)) == 0){
    80004c58:	854a                	mv	a0,s2
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	284080e7          	jalr	644(ra) # 80003ede <namei>
    80004c62:	c92d                	beqz	a0,80004cd4 <exec+0xbc>
    80004c64:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c66:	fffff097          	auipc	ra,0xfffff
    80004c6a:	ad2080e7          	jalr	-1326(ra) # 80003738 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c6e:	04000713          	li	a4,64
    80004c72:	4681                	li	a3,0
    80004c74:	e5040613          	addi	a2,s0,-432
    80004c78:	4581                	li	a1,0
    80004c7a:	8552                	mv	a0,s4
    80004c7c:	fffff097          	auipc	ra,0xfffff
    80004c80:	d70080e7          	jalr	-656(ra) # 800039ec <readi>
    80004c84:	04000793          	li	a5,64
    80004c88:	00f51a63          	bne	a0,a5,80004c9c <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c8c:	e5042703          	lw	a4,-432(s0)
    80004c90:	464c47b7          	lui	a5,0x464c4
    80004c94:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c98:	04f70463          	beq	a4,a5,80004ce0 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c9c:	8552                	mv	a0,s4
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	cfc080e7          	jalr	-772(ra) # 8000399a <iunlockput>
    end_op();
    80004ca6:	fffff097          	auipc	ra,0xfffff
    80004caa:	4b2080e7          	jalr	1202(ra) # 80004158 <end_op>
  }
  return -1;
    80004cae:	557d                	li	a0,-1
}
    80004cb0:	20813083          	ld	ra,520(sp)
    80004cb4:	20013403          	ld	s0,512(sp)
    80004cb8:	74fe                	ld	s1,504(sp)
    80004cba:	795e                	ld	s2,496(sp)
    80004cbc:	79be                	ld	s3,488(sp)
    80004cbe:	7a1e                	ld	s4,480(sp)
    80004cc0:	6afe                	ld	s5,472(sp)
    80004cc2:	6b5e                	ld	s6,464(sp)
    80004cc4:	6bbe                	ld	s7,456(sp)
    80004cc6:	6c1e                	ld	s8,448(sp)
    80004cc8:	7cfa                	ld	s9,440(sp)
    80004cca:	7d5a                	ld	s10,432(sp)
    80004ccc:	7dba                	ld	s11,424(sp)
    80004cce:	21010113          	addi	sp,sp,528
    80004cd2:	8082                	ret
    end_op();
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	484080e7          	jalr	1156(ra) # 80004158 <end_op>
    return -1;
    80004cdc:	557d                	li	a0,-1
    80004cde:	bfc9                	j	80004cb0 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ce0:	8526                	mv	a0,s1
    80004ce2:	ffffd097          	auipc	ra,0xffffd
    80004ce6:	e06080e7          	jalr	-506(ra) # 80001ae8 <proc_pagetable>
    80004cea:	8b2a                	mv	s6,a0
    80004cec:	d945                	beqz	a0,80004c9c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cee:	e7042d03          	lw	s10,-400(s0)
    80004cf2:	e8845783          	lhu	a5,-376(s0)
    80004cf6:	10078463          	beqz	a5,80004dfe <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cfa:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cfc:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004cfe:	6c85                	lui	s9,0x1
    80004d00:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d04:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004d08:	6a85                	lui	s5,0x1
    80004d0a:	a0b5                	j	80004d76 <exec+0x15e>
      panic("loadseg: address should exist");
    80004d0c:	00005517          	auipc	a0,0x5
    80004d10:	9cc50513          	addi	a0,a0,-1588 # 800096d8 <syscalls+0x280>
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	82c080e7          	jalr	-2004(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
    80004d1c:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d1e:	8726                	mv	a4,s1
    80004d20:	012c06bb          	addw	a3,s8,s2
    80004d24:	4581                	li	a1,0
    80004d26:	8552                	mv	a0,s4
    80004d28:	fffff097          	auipc	ra,0xfffff
    80004d2c:	cc4080e7          	jalr	-828(ra) # 800039ec <readi>
    80004d30:	2501                	sext.w	a0,a0
    80004d32:	2aa49d63          	bne	s1,a0,80004fec <exec+0x3d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004d36:	012a893b          	addw	s2,s5,s2
    80004d3a:	03397563          	bgeu	s2,s3,80004d64 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004d3e:	02091593          	slli	a1,s2,0x20
    80004d42:	9181                	srli	a1,a1,0x20
    80004d44:	95de                	add	a1,a1,s7
    80004d46:	855a                	mv	a0,s6
    80004d48:	ffffc097          	auipc	ra,0xffffc
    80004d4c:	38c080e7          	jalr	908(ra) # 800010d4 <walkaddr>
    80004d50:	862a                	mv	a2,a0
    if(pa == 0)
    80004d52:	dd4d                	beqz	a0,80004d0c <exec+0xf4>
    if(sz - i < PGSIZE)
    80004d54:	412984bb          	subw	s1,s3,s2
    80004d58:	0004879b          	sext.w	a5,s1
    80004d5c:	fcfcf0e3          	bgeu	s9,a5,80004d1c <exec+0x104>
    80004d60:	84d6                	mv	s1,s5
    80004d62:	bf6d                	j	80004d1c <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d64:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d68:	2d85                	addiw	s11,s11,1
    80004d6a:	038d0d1b          	addiw	s10,s10,56
    80004d6e:	e8845783          	lhu	a5,-376(s0)
    80004d72:	08fdd763          	bge	s11,a5,80004e00 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004d76:	2d01                	sext.w	s10,s10
    80004d78:	03800713          	li	a4,56
    80004d7c:	86ea                	mv	a3,s10
    80004d7e:	e1840613          	addi	a2,s0,-488
    80004d82:	4581                	li	a1,0
    80004d84:	8552                	mv	a0,s4
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	c66080e7          	jalr	-922(ra) # 800039ec <readi>
    80004d8e:	03800793          	li	a5,56
    80004d92:	24f51b63          	bne	a0,a5,80004fe8 <exec+0x3d0>
    if(ph.type != ELF_PROG_LOAD)
    80004d96:	e1842783          	lw	a5,-488(s0)
    80004d9a:	4705                	li	a4,1
    80004d9c:	fce796e3          	bne	a5,a4,80004d68 <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004da0:	e4043483          	ld	s1,-448(s0)
    80004da4:	e3843783          	ld	a5,-456(s0)
    80004da8:	24f4ed63          	bltu	s1,a5,80005002 <exec+0x3ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004dac:	e2843783          	ld	a5,-472(s0)
    80004db0:	94be                	add	s1,s1,a5
    80004db2:	24f4eb63          	bltu	s1,a5,80005008 <exec+0x3f0>
    if(ph.vaddr % PGSIZE != 0)
    80004db6:	df043703          	ld	a4,-528(s0)
    80004dba:	8ff9                	and	a5,a5,a4
    80004dbc:	24079963          	bnez	a5,8000500e <exec+0x3f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004dc0:	e1c42503          	lw	a0,-484(s0)
    80004dc4:	00000097          	auipc	ra,0x0
    80004dc8:	e3a080e7          	jalr	-454(ra) # 80004bfe <flags2perm>
    80004dcc:	86aa                	mv	a3,a0
    80004dce:	8626                	mv	a2,s1
    80004dd0:	85ca                	mv	a1,s2
    80004dd2:	855a                	mv	a0,s6
    80004dd4:	ffffc097          	auipc	ra,0xffffc
    80004dd8:	6b4080e7          	jalr	1716(ra) # 80001488 <uvmalloc>
    80004ddc:	e0a43423          	sd	a0,-504(s0)
    80004de0:	22050a63          	beqz	a0,80005014 <exec+0x3fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004de4:	e2843b83          	ld	s7,-472(s0)
    80004de8:	e2042c03          	lw	s8,-480(s0)
    80004dec:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004df0:	00098463          	beqz	s3,80004df8 <exec+0x1e0>
    80004df4:	4901                	li	s2,0
    80004df6:	b7a1                	j	80004d3e <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004df8:	e0843903          	ld	s2,-504(s0)
    80004dfc:	b7b5                	j	80004d68 <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dfe:	4901                	li	s2,0
  iunlockput(ip);
    80004e00:	8552                	mv	a0,s4
    80004e02:	fffff097          	auipc	ra,0xfffff
    80004e06:	b98080e7          	jalr	-1128(ra) # 8000399a <iunlockput>
  end_op();
    80004e0a:	fffff097          	auipc	ra,0xfffff
    80004e0e:	34e080e7          	jalr	846(ra) # 80004158 <end_op>
  p = myproc();
    80004e12:	ffffd097          	auipc	ra,0xffffd
    80004e16:	c12080e7          	jalr	-1006(ra) # 80001a24 <myproc>
    80004e1a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e1c:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004e20:	6985                	lui	s3,0x1
    80004e22:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004e24:	99ca                	add	s3,s3,s2
    80004e26:	77fd                	lui	a5,0xfffff
    80004e28:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e2c:	4691                	li	a3,4
    80004e2e:	6609                	lui	a2,0x2
    80004e30:	964e                	add	a2,a2,s3
    80004e32:	85ce                	mv	a1,s3
    80004e34:	855a                	mv	a0,s6
    80004e36:	ffffc097          	auipc	ra,0xffffc
    80004e3a:	652080e7          	jalr	1618(ra) # 80001488 <uvmalloc>
    80004e3e:	892a                	mv	s2,a0
    80004e40:	e0a43423          	sd	a0,-504(s0)
    80004e44:	e509                	bnez	a0,80004e4e <exec+0x236>
  if(pagetable)
    80004e46:	e1343423          	sd	s3,-504(s0)
    80004e4a:	4a01                	li	s4,0
    80004e4c:	a245                	j	80004fec <exec+0x3d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e4e:	75f9                	lui	a1,0xffffe
    80004e50:	95aa                	add	a1,a1,a0
    80004e52:	855a                	mv	a0,s6
    80004e54:	ffffd097          	auipc	ra,0xffffd
    80004e58:	85e080e7          	jalr	-1954(ra) # 800016b2 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e5c:	7bfd                	lui	s7,0xfffff
    80004e5e:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004e60:	e0043783          	ld	a5,-512(s0)
    80004e64:	6388                	ld	a0,0(a5)
    80004e66:	c52d                	beqz	a0,80004ed0 <exec+0x2b8>
    80004e68:	e9040993          	addi	s3,s0,-368
    80004e6c:	f9040c13          	addi	s8,s0,-112
    80004e70:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	04c080e7          	jalr	76(ra) # 80000ebe <strlen>
    80004e7a:	0015079b          	addiw	a5,a0,1
    80004e7e:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e82:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e86:	19796a63          	bltu	s2,s7,8000501a <exec+0x402>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e8a:	e0043d03          	ld	s10,-512(s0)
    80004e8e:	000d3a03          	ld	s4,0(s10)
    80004e92:	8552                	mv	a0,s4
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	02a080e7          	jalr	42(ra) # 80000ebe <strlen>
    80004e9c:	0015069b          	addiw	a3,a0,1
    80004ea0:	8652                	mv	a2,s4
    80004ea2:	85ca                	mv	a1,s2
    80004ea4:	855a                	mv	a0,s6
    80004ea6:	ffffd097          	auipc	ra,0xffffd
    80004eaa:	83e080e7          	jalr	-1986(ra) # 800016e4 <copyout>
    80004eae:	16054863          	bltz	a0,8000501e <exec+0x406>
    ustack[argc] = sp;
    80004eb2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eb6:	0485                	addi	s1,s1,1
    80004eb8:	008d0793          	addi	a5,s10,8
    80004ebc:	e0f43023          	sd	a5,-512(s0)
    80004ec0:	008d3503          	ld	a0,8(s10)
    80004ec4:	c909                	beqz	a0,80004ed6 <exec+0x2be>
    if(argc >= MAXARG)
    80004ec6:	09a1                	addi	s3,s3,8
    80004ec8:	fb8995e3          	bne	s3,s8,80004e72 <exec+0x25a>
  ip = 0;
    80004ecc:	4a01                	li	s4,0
    80004ece:	aa39                	j	80004fec <exec+0x3d4>
  sp = sz;
    80004ed0:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004ed4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ed6:	00349793          	slli	a5,s1,0x3
    80004eda:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdb570>
    80004ede:	97a2                	add	a5,a5,s0
    80004ee0:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004ee4:	00148693          	addi	a3,s1,1
    80004ee8:	068e                	slli	a3,a3,0x3
    80004eea:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004eee:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004ef2:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004ef6:	f57968e3          	bltu	s2,s7,80004e46 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004efa:	e9040613          	addi	a2,s0,-368
    80004efe:	85ca                	mv	a1,s2
    80004f00:	855a                	mv	a0,s6
    80004f02:	ffffc097          	auipc	ra,0xffffc
    80004f06:	7e2080e7          	jalr	2018(ra) # 800016e4 <copyout>
    80004f0a:	10054c63          	bltz	a0,80005022 <exec+0x40a>
  p->trapframe->a1 = sp;
    80004f0e:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004f12:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f16:	df843783          	ld	a5,-520(s0)
    80004f1a:	0007c703          	lbu	a4,0(a5)
    80004f1e:	cf11                	beqz	a4,80004f3a <exec+0x322>
    80004f20:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f22:	02f00693          	li	a3,47
    80004f26:	a039                	j	80004f34 <exec+0x31c>
      last = s+1;
    80004f28:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f2c:	0785                	addi	a5,a5,1
    80004f2e:	fff7c703          	lbu	a4,-1(a5)
    80004f32:	c701                	beqz	a4,80004f3a <exec+0x322>
    if(*s == '/')
    80004f34:	fed71ce3          	bne	a4,a3,80004f2c <exec+0x314>
    80004f38:	bfc5                	j	80004f28 <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f3a:	158a8993          	addi	s3,s5,344
    80004f3e:	4641                	li	a2,16
    80004f40:	df843583          	ld	a1,-520(s0)
    80004f44:	854e                	mv	a0,s3
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	f46080e7          	jalr	-186(ra) # 80000e8c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f4e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f52:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004f56:	e0843783          	ld	a5,-504(s0)
    80004f5a:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f5e:	058ab783          	ld	a5,88(s5)
    80004f62:	e6843703          	ld	a4,-408(s0)
    80004f66:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f68:	058ab783          	ld	a5,88(s5)
    80004f6c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f70:	85e6                	mv	a1,s9
    80004f72:	ffffd097          	auipc	ra,0xffffd
    80004f76:	c12080e7          	jalr	-1006(ra) # 80001b84 <proc_freepagetable>
  if (strncmp(p->name, "vm-", 3) == 0) {
    80004f7a:	460d                	li	a2,3
    80004f7c:	00004597          	auipc	a1,0x4
    80004f80:	28458593          	addi	a1,a1,644 # 80009200 <digits+0x1c0>
    80004f84:	854e                	mv	a0,s3
    80004f86:	ffffc097          	auipc	ra,0xffffc
    80004f8a:	e8e080e7          	jalr	-370(ra) # 80000e14 <strncmp>
    80004f8e:	c501                	beqz	a0,80004f96 <exec+0x37e>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f90:	0004851b          	sext.w	a0,s1
    80004f94:	bb31                	j	80004cb0 <exec+0x98>
    if((sz1 = uvmalloc(pagetable, memaddr, memaddr + 1024*PGSIZE, PTE_W)) == 0) {
    80004f96:	4691                	li	a3,4
    80004f98:	20100613          	li	a2,513
    80004f9c:	065a                	slli	a2,a2,0x16
    80004f9e:	4585                	li	a1,1
    80004fa0:	05fe                	slli	a1,a1,0x1f
    80004fa2:	855a                	mv	a0,s6
    80004fa4:	ffffc097          	auipc	ra,0xffffc
    80004fa8:	4e4080e7          	jalr	1252(ra) # 80001488 <uvmalloc>
    80004fac:	c11d                	beqz	a0,80004fd2 <exec+0x3ba>
    printf("Created a VM process and allocated memory region (%p - %p).\n", memaddr, memaddr + 1024*PGSIZE);
    80004fae:	20100613          	li	a2,513
    80004fb2:	065a                	slli	a2,a2,0x16
    80004fb4:	4585                	li	a1,1
    80004fb6:	05fe                	slli	a1,a1,0x1f
    80004fb8:	00004517          	auipc	a0,0x4
    80004fbc:	77850513          	addi	a0,a0,1912 # 80009730 <syscalls+0x2d8>
    80004fc0:	ffffb097          	auipc	ra,0xffffb
    80004fc4:	5ca080e7          	jalr	1482(ra) # 8000058a <printf>
    trap_and_emulate_init();
    80004fc8:	00002097          	auipc	ra,0x2
    80004fcc:	198080e7          	jalr	408(ra) # 80007160 <trap_and_emulate_init>
    80004fd0:	b7c1                	j	80004f90 <exec+0x378>
      printf("Error: could not allocate memory at 0x80000000 for VM.\n");
    80004fd2:	00004517          	auipc	a0,0x4
    80004fd6:	72650513          	addi	a0,a0,1830 # 800096f8 <syscalls+0x2a0>
    80004fda:	ffffb097          	auipc	ra,0xffffb
    80004fde:	5b0080e7          	jalr	1456(ra) # 8000058a <printf>
  sz = sz1;
    80004fe2:	e0843983          	ld	s3,-504(s0)
      goto bad;
    80004fe6:	b585                	j	80004e46 <exec+0x22e>
    80004fe8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fec:	e0843583          	ld	a1,-504(s0)
    80004ff0:	855a                	mv	a0,s6
    80004ff2:	ffffd097          	auipc	ra,0xffffd
    80004ff6:	b92080e7          	jalr	-1134(ra) # 80001b84 <proc_freepagetable>
  return -1;
    80004ffa:	557d                	li	a0,-1
  if(ip){
    80004ffc:	ca0a0ae3          	beqz	s4,80004cb0 <exec+0x98>
    80005000:	b971                	j	80004c9c <exec+0x84>
    80005002:	e1243423          	sd	s2,-504(s0)
    80005006:	b7dd                	j	80004fec <exec+0x3d4>
    80005008:	e1243423          	sd	s2,-504(s0)
    8000500c:	b7c5                	j	80004fec <exec+0x3d4>
    8000500e:	e1243423          	sd	s2,-504(s0)
    80005012:	bfe9                	j	80004fec <exec+0x3d4>
    80005014:	e1243423          	sd	s2,-504(s0)
    80005018:	bfd1                	j	80004fec <exec+0x3d4>
  ip = 0;
    8000501a:	4a01                	li	s4,0
    8000501c:	bfc1                	j	80004fec <exec+0x3d4>
    8000501e:	4a01                	li	s4,0
  if(pagetable)
    80005020:	b7f1                	j	80004fec <exec+0x3d4>
  sz = sz1;
    80005022:	e0843983          	ld	s3,-504(s0)
    80005026:	b505                	j	80004e46 <exec+0x22e>

0000000080005028 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005028:	7179                	addi	sp,sp,-48
    8000502a:	f406                	sd	ra,40(sp)
    8000502c:	f022                	sd	s0,32(sp)
    8000502e:	ec26                	sd	s1,24(sp)
    80005030:	e84a                	sd	s2,16(sp)
    80005032:	1800                	addi	s0,sp,48
    80005034:	892e                	mv	s2,a1
    80005036:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005038:	fdc40593          	addi	a1,s0,-36
    8000503c:	ffffe097          	auipc	ra,0xffffe
    80005040:	b9a080e7          	jalr	-1126(ra) # 80002bd6 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005044:	fdc42703          	lw	a4,-36(s0)
    80005048:	47bd                	li	a5,15
    8000504a:	02e7eb63          	bltu	a5,a4,80005080 <argfd+0x58>
    8000504e:	ffffd097          	auipc	ra,0xffffd
    80005052:	9d6080e7          	jalr	-1578(ra) # 80001a24 <myproc>
    80005056:	fdc42703          	lw	a4,-36(s0)
    8000505a:	01a70793          	addi	a5,a4,26
    8000505e:	078e                	slli	a5,a5,0x3
    80005060:	953e                	add	a0,a0,a5
    80005062:	611c                	ld	a5,0(a0)
    80005064:	c385                	beqz	a5,80005084 <argfd+0x5c>
    return -1;
  if(pfd)
    80005066:	00090463          	beqz	s2,8000506e <argfd+0x46>
    *pfd = fd;
    8000506a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000506e:	4501                	li	a0,0
  if(pf)
    80005070:	c091                	beqz	s1,80005074 <argfd+0x4c>
    *pf = f;
    80005072:	e09c                	sd	a5,0(s1)
}
    80005074:	70a2                	ld	ra,40(sp)
    80005076:	7402                	ld	s0,32(sp)
    80005078:	64e2                	ld	s1,24(sp)
    8000507a:	6942                	ld	s2,16(sp)
    8000507c:	6145                	addi	sp,sp,48
    8000507e:	8082                	ret
    return -1;
    80005080:	557d                	li	a0,-1
    80005082:	bfcd                	j	80005074 <argfd+0x4c>
    80005084:	557d                	li	a0,-1
    80005086:	b7fd                	j	80005074 <argfd+0x4c>

0000000080005088 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005088:	1101                	addi	sp,sp,-32
    8000508a:	ec06                	sd	ra,24(sp)
    8000508c:	e822                	sd	s0,16(sp)
    8000508e:	e426                	sd	s1,8(sp)
    80005090:	1000                	addi	s0,sp,32
    80005092:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005094:	ffffd097          	auipc	ra,0xffffd
    80005098:	990080e7          	jalr	-1648(ra) # 80001a24 <myproc>
    8000509c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000509e:	0d050793          	addi	a5,a0,208
    800050a2:	4501                	li	a0,0
    800050a4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050a6:	6398                	ld	a4,0(a5)
    800050a8:	cb19                	beqz	a4,800050be <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050aa:	2505                	addiw	a0,a0,1
    800050ac:	07a1                	addi	a5,a5,8
    800050ae:	fed51ce3          	bne	a0,a3,800050a6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050b2:	557d                	li	a0,-1
}
    800050b4:	60e2                	ld	ra,24(sp)
    800050b6:	6442                	ld	s0,16(sp)
    800050b8:	64a2                	ld	s1,8(sp)
    800050ba:	6105                	addi	sp,sp,32
    800050bc:	8082                	ret
      p->ofile[fd] = f;
    800050be:	01a50793          	addi	a5,a0,26
    800050c2:	078e                	slli	a5,a5,0x3
    800050c4:	963e                	add	a2,a2,a5
    800050c6:	e204                	sd	s1,0(a2)
      return fd;
    800050c8:	b7f5                	j	800050b4 <fdalloc+0x2c>

00000000800050ca <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050ca:	715d                	addi	sp,sp,-80
    800050cc:	e486                	sd	ra,72(sp)
    800050ce:	e0a2                	sd	s0,64(sp)
    800050d0:	fc26                	sd	s1,56(sp)
    800050d2:	f84a                	sd	s2,48(sp)
    800050d4:	f44e                	sd	s3,40(sp)
    800050d6:	f052                	sd	s4,32(sp)
    800050d8:	ec56                	sd	s5,24(sp)
    800050da:	e85a                	sd	s6,16(sp)
    800050dc:	0880                	addi	s0,sp,80
    800050de:	8b2e                	mv	s6,a1
    800050e0:	89b2                	mv	s3,a2
    800050e2:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050e4:	fb040593          	addi	a1,s0,-80
    800050e8:	fffff097          	auipc	ra,0xfffff
    800050ec:	e14080e7          	jalr	-492(ra) # 80003efc <nameiparent>
    800050f0:	84aa                	mv	s1,a0
    800050f2:	14050b63          	beqz	a0,80005248 <create+0x17e>
    return 0;

  ilock(dp);
    800050f6:	ffffe097          	auipc	ra,0xffffe
    800050fa:	642080e7          	jalr	1602(ra) # 80003738 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050fe:	4601                	li	a2,0
    80005100:	fb040593          	addi	a1,s0,-80
    80005104:	8526                	mv	a0,s1
    80005106:	fffff097          	auipc	ra,0xfffff
    8000510a:	b16080e7          	jalr	-1258(ra) # 80003c1c <dirlookup>
    8000510e:	8aaa                	mv	s5,a0
    80005110:	c921                	beqz	a0,80005160 <create+0x96>
    iunlockput(dp);
    80005112:	8526                	mv	a0,s1
    80005114:	fffff097          	auipc	ra,0xfffff
    80005118:	886080e7          	jalr	-1914(ra) # 8000399a <iunlockput>
    ilock(ip);
    8000511c:	8556                	mv	a0,s5
    8000511e:	ffffe097          	auipc	ra,0xffffe
    80005122:	61a080e7          	jalr	1562(ra) # 80003738 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005126:	4789                	li	a5,2
    80005128:	02fb1563          	bne	s6,a5,80005152 <create+0x88>
    8000512c:	044ad783          	lhu	a5,68(s5)
    80005130:	37f9                	addiw	a5,a5,-2
    80005132:	17c2                	slli	a5,a5,0x30
    80005134:	93c1                	srli	a5,a5,0x30
    80005136:	4705                	li	a4,1
    80005138:	00f76d63          	bltu	a4,a5,80005152 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000513c:	8556                	mv	a0,s5
    8000513e:	60a6                	ld	ra,72(sp)
    80005140:	6406                	ld	s0,64(sp)
    80005142:	74e2                	ld	s1,56(sp)
    80005144:	7942                	ld	s2,48(sp)
    80005146:	79a2                	ld	s3,40(sp)
    80005148:	7a02                	ld	s4,32(sp)
    8000514a:	6ae2                	ld	s5,24(sp)
    8000514c:	6b42                	ld	s6,16(sp)
    8000514e:	6161                	addi	sp,sp,80
    80005150:	8082                	ret
    iunlockput(ip);
    80005152:	8556                	mv	a0,s5
    80005154:	fffff097          	auipc	ra,0xfffff
    80005158:	846080e7          	jalr	-1978(ra) # 8000399a <iunlockput>
    return 0;
    8000515c:	4a81                	li	s5,0
    8000515e:	bff9                	j	8000513c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005160:	85da                	mv	a1,s6
    80005162:	4088                	lw	a0,0(s1)
    80005164:	ffffe097          	auipc	ra,0xffffe
    80005168:	43c080e7          	jalr	1084(ra) # 800035a0 <ialloc>
    8000516c:	8a2a                	mv	s4,a0
    8000516e:	c529                	beqz	a0,800051b8 <create+0xee>
  ilock(ip);
    80005170:	ffffe097          	auipc	ra,0xffffe
    80005174:	5c8080e7          	jalr	1480(ra) # 80003738 <ilock>
  ip->major = major;
    80005178:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000517c:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005180:	4905                	li	s2,1
    80005182:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005186:	8552                	mv	a0,s4
    80005188:	ffffe097          	auipc	ra,0xffffe
    8000518c:	4e4080e7          	jalr	1252(ra) # 8000366c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005190:	032b0b63          	beq	s6,s2,800051c6 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005194:	004a2603          	lw	a2,4(s4)
    80005198:	fb040593          	addi	a1,s0,-80
    8000519c:	8526                	mv	a0,s1
    8000519e:	fffff097          	auipc	ra,0xfffff
    800051a2:	c8e080e7          	jalr	-882(ra) # 80003e2c <dirlink>
    800051a6:	06054f63          	bltz	a0,80005224 <create+0x15a>
  iunlockput(dp);
    800051aa:	8526                	mv	a0,s1
    800051ac:	ffffe097          	auipc	ra,0xffffe
    800051b0:	7ee080e7          	jalr	2030(ra) # 8000399a <iunlockput>
  return ip;
    800051b4:	8ad2                	mv	s5,s4
    800051b6:	b759                	j	8000513c <create+0x72>
    iunlockput(dp);
    800051b8:	8526                	mv	a0,s1
    800051ba:	ffffe097          	auipc	ra,0xffffe
    800051be:	7e0080e7          	jalr	2016(ra) # 8000399a <iunlockput>
    return 0;
    800051c2:	8ad2                	mv	s5,s4
    800051c4:	bfa5                	j	8000513c <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051c6:	004a2603          	lw	a2,4(s4)
    800051ca:	00004597          	auipc	a1,0x4
    800051ce:	5a658593          	addi	a1,a1,1446 # 80009770 <syscalls+0x318>
    800051d2:	8552                	mv	a0,s4
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	c58080e7          	jalr	-936(ra) # 80003e2c <dirlink>
    800051dc:	04054463          	bltz	a0,80005224 <create+0x15a>
    800051e0:	40d0                	lw	a2,4(s1)
    800051e2:	00004597          	auipc	a1,0x4
    800051e6:	59658593          	addi	a1,a1,1430 # 80009778 <syscalls+0x320>
    800051ea:	8552                	mv	a0,s4
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	c40080e7          	jalr	-960(ra) # 80003e2c <dirlink>
    800051f4:	02054863          	bltz	a0,80005224 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800051f8:	004a2603          	lw	a2,4(s4)
    800051fc:	fb040593          	addi	a1,s0,-80
    80005200:	8526                	mv	a0,s1
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	c2a080e7          	jalr	-982(ra) # 80003e2c <dirlink>
    8000520a:	00054d63          	bltz	a0,80005224 <create+0x15a>
    dp->nlink++;  // for ".."
    8000520e:	04a4d783          	lhu	a5,74(s1)
    80005212:	2785                	addiw	a5,a5,1
    80005214:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005218:	8526                	mv	a0,s1
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	452080e7          	jalr	1106(ra) # 8000366c <iupdate>
    80005222:	b761                	j	800051aa <create+0xe0>
  ip->nlink = 0;
    80005224:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005228:	8552                	mv	a0,s4
    8000522a:	ffffe097          	auipc	ra,0xffffe
    8000522e:	442080e7          	jalr	1090(ra) # 8000366c <iupdate>
  iunlockput(ip);
    80005232:	8552                	mv	a0,s4
    80005234:	ffffe097          	auipc	ra,0xffffe
    80005238:	766080e7          	jalr	1894(ra) # 8000399a <iunlockput>
  iunlockput(dp);
    8000523c:	8526                	mv	a0,s1
    8000523e:	ffffe097          	auipc	ra,0xffffe
    80005242:	75c080e7          	jalr	1884(ra) # 8000399a <iunlockput>
  return 0;
    80005246:	bddd                	j	8000513c <create+0x72>
    return 0;
    80005248:	8aaa                	mv	s5,a0
    8000524a:	bdcd                	j	8000513c <create+0x72>

000000008000524c <sys_dup>:
{
    8000524c:	7179                	addi	sp,sp,-48
    8000524e:	f406                	sd	ra,40(sp)
    80005250:	f022                	sd	s0,32(sp)
    80005252:	ec26                	sd	s1,24(sp)
    80005254:	e84a                	sd	s2,16(sp)
    80005256:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005258:	fd840613          	addi	a2,s0,-40
    8000525c:	4581                	li	a1,0
    8000525e:	4501                	li	a0,0
    80005260:	00000097          	auipc	ra,0x0
    80005264:	dc8080e7          	jalr	-568(ra) # 80005028 <argfd>
    return -1;
    80005268:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000526a:	02054363          	bltz	a0,80005290 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000526e:	fd843903          	ld	s2,-40(s0)
    80005272:	854a                	mv	a0,s2
    80005274:	00000097          	auipc	ra,0x0
    80005278:	e14080e7          	jalr	-492(ra) # 80005088 <fdalloc>
    8000527c:	84aa                	mv	s1,a0
    return -1;
    8000527e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005280:	00054863          	bltz	a0,80005290 <sys_dup+0x44>
  filedup(f);
    80005284:	854a                	mv	a0,s2
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	2ca080e7          	jalr	714(ra) # 80004550 <filedup>
  return fd;
    8000528e:	87a6                	mv	a5,s1
}
    80005290:	853e                	mv	a0,a5
    80005292:	70a2                	ld	ra,40(sp)
    80005294:	7402                	ld	s0,32(sp)
    80005296:	64e2                	ld	s1,24(sp)
    80005298:	6942                	ld	s2,16(sp)
    8000529a:	6145                	addi	sp,sp,48
    8000529c:	8082                	ret

000000008000529e <sys_read>:
{
    8000529e:	7179                	addi	sp,sp,-48
    800052a0:	f406                	sd	ra,40(sp)
    800052a2:	f022                	sd	s0,32(sp)
    800052a4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052a6:	fd840593          	addi	a1,s0,-40
    800052aa:	4505                	li	a0,1
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	94a080e7          	jalr	-1718(ra) # 80002bf6 <argaddr>
  argint(2, &n);
    800052b4:	fe440593          	addi	a1,s0,-28
    800052b8:	4509                	li	a0,2
    800052ba:	ffffe097          	auipc	ra,0xffffe
    800052be:	91c080e7          	jalr	-1764(ra) # 80002bd6 <argint>
  if(argfd(0, 0, &f) < 0)
    800052c2:	fe840613          	addi	a2,s0,-24
    800052c6:	4581                	li	a1,0
    800052c8:	4501                	li	a0,0
    800052ca:	00000097          	auipc	ra,0x0
    800052ce:	d5e080e7          	jalr	-674(ra) # 80005028 <argfd>
    800052d2:	87aa                	mv	a5,a0
    return -1;
    800052d4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052d6:	0007cc63          	bltz	a5,800052ee <sys_read+0x50>
  return fileread(f, p, n);
    800052da:	fe442603          	lw	a2,-28(s0)
    800052de:	fd843583          	ld	a1,-40(s0)
    800052e2:	fe843503          	ld	a0,-24(s0)
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	3f6080e7          	jalr	1014(ra) # 800046dc <fileread>
}
    800052ee:	70a2                	ld	ra,40(sp)
    800052f0:	7402                	ld	s0,32(sp)
    800052f2:	6145                	addi	sp,sp,48
    800052f4:	8082                	ret

00000000800052f6 <sys_write>:
{
    800052f6:	7179                	addi	sp,sp,-48
    800052f8:	f406                	sd	ra,40(sp)
    800052fa:	f022                	sd	s0,32(sp)
    800052fc:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052fe:	fd840593          	addi	a1,s0,-40
    80005302:	4505                	li	a0,1
    80005304:	ffffe097          	auipc	ra,0xffffe
    80005308:	8f2080e7          	jalr	-1806(ra) # 80002bf6 <argaddr>
  argint(2, &n);
    8000530c:	fe440593          	addi	a1,s0,-28
    80005310:	4509                	li	a0,2
    80005312:	ffffe097          	auipc	ra,0xffffe
    80005316:	8c4080e7          	jalr	-1852(ra) # 80002bd6 <argint>
  if(argfd(0, 0, &f) < 0)
    8000531a:	fe840613          	addi	a2,s0,-24
    8000531e:	4581                	li	a1,0
    80005320:	4501                	li	a0,0
    80005322:	00000097          	auipc	ra,0x0
    80005326:	d06080e7          	jalr	-762(ra) # 80005028 <argfd>
    8000532a:	87aa                	mv	a5,a0
    return -1;
    8000532c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000532e:	0007cc63          	bltz	a5,80005346 <sys_write+0x50>
  return filewrite(f, p, n);
    80005332:	fe442603          	lw	a2,-28(s0)
    80005336:	fd843583          	ld	a1,-40(s0)
    8000533a:	fe843503          	ld	a0,-24(s0)
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	460080e7          	jalr	1120(ra) # 8000479e <filewrite>
}
    80005346:	70a2                	ld	ra,40(sp)
    80005348:	7402                	ld	s0,32(sp)
    8000534a:	6145                	addi	sp,sp,48
    8000534c:	8082                	ret

000000008000534e <sys_close>:
{
    8000534e:	1101                	addi	sp,sp,-32
    80005350:	ec06                	sd	ra,24(sp)
    80005352:	e822                	sd	s0,16(sp)
    80005354:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005356:	fe040613          	addi	a2,s0,-32
    8000535a:	fec40593          	addi	a1,s0,-20
    8000535e:	4501                	li	a0,0
    80005360:	00000097          	auipc	ra,0x0
    80005364:	cc8080e7          	jalr	-824(ra) # 80005028 <argfd>
    return -1;
    80005368:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000536a:	02054463          	bltz	a0,80005392 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000536e:	ffffc097          	auipc	ra,0xffffc
    80005372:	6b6080e7          	jalr	1718(ra) # 80001a24 <myproc>
    80005376:	fec42783          	lw	a5,-20(s0)
    8000537a:	07e9                	addi	a5,a5,26
    8000537c:	078e                	slli	a5,a5,0x3
    8000537e:	953e                	add	a0,a0,a5
    80005380:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005384:	fe043503          	ld	a0,-32(s0)
    80005388:	fffff097          	auipc	ra,0xfffff
    8000538c:	21a080e7          	jalr	538(ra) # 800045a2 <fileclose>
  return 0;
    80005390:	4781                	li	a5,0
}
    80005392:	853e                	mv	a0,a5
    80005394:	60e2                	ld	ra,24(sp)
    80005396:	6442                	ld	s0,16(sp)
    80005398:	6105                	addi	sp,sp,32
    8000539a:	8082                	ret

000000008000539c <sys_fstat>:
{
    8000539c:	1101                	addi	sp,sp,-32
    8000539e:	ec06                	sd	ra,24(sp)
    800053a0:	e822                	sd	s0,16(sp)
    800053a2:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053a4:	fe040593          	addi	a1,s0,-32
    800053a8:	4505                	li	a0,1
    800053aa:	ffffe097          	auipc	ra,0xffffe
    800053ae:	84c080e7          	jalr	-1972(ra) # 80002bf6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053b2:	fe840613          	addi	a2,s0,-24
    800053b6:	4581                	li	a1,0
    800053b8:	4501                	li	a0,0
    800053ba:	00000097          	auipc	ra,0x0
    800053be:	c6e080e7          	jalr	-914(ra) # 80005028 <argfd>
    800053c2:	87aa                	mv	a5,a0
    return -1;
    800053c4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053c6:	0007ca63          	bltz	a5,800053da <sys_fstat+0x3e>
  return filestat(f, st);
    800053ca:	fe043583          	ld	a1,-32(s0)
    800053ce:	fe843503          	ld	a0,-24(s0)
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	298080e7          	jalr	664(ra) # 8000466a <filestat>
}
    800053da:	60e2                	ld	ra,24(sp)
    800053dc:	6442                	ld	s0,16(sp)
    800053de:	6105                	addi	sp,sp,32
    800053e0:	8082                	ret

00000000800053e2 <sys_link>:
{
    800053e2:	7169                	addi	sp,sp,-304
    800053e4:	f606                	sd	ra,296(sp)
    800053e6:	f222                	sd	s0,288(sp)
    800053e8:	ee26                	sd	s1,280(sp)
    800053ea:	ea4a                	sd	s2,272(sp)
    800053ec:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ee:	08000613          	li	a2,128
    800053f2:	ed040593          	addi	a1,s0,-304
    800053f6:	4501                	li	a0,0
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	81e080e7          	jalr	-2018(ra) # 80002c16 <argstr>
    return -1;
    80005400:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005402:	10054e63          	bltz	a0,8000551e <sys_link+0x13c>
    80005406:	08000613          	li	a2,128
    8000540a:	f5040593          	addi	a1,s0,-176
    8000540e:	4505                	li	a0,1
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	806080e7          	jalr	-2042(ra) # 80002c16 <argstr>
    return -1;
    80005418:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000541a:	10054263          	bltz	a0,8000551e <sys_link+0x13c>
  begin_op();
    8000541e:	fffff097          	auipc	ra,0xfffff
    80005422:	cc0080e7          	jalr	-832(ra) # 800040de <begin_op>
  if((ip = namei(old)) == 0){
    80005426:	ed040513          	addi	a0,s0,-304
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	ab4080e7          	jalr	-1356(ra) # 80003ede <namei>
    80005432:	84aa                	mv	s1,a0
    80005434:	c551                	beqz	a0,800054c0 <sys_link+0xde>
  ilock(ip);
    80005436:	ffffe097          	auipc	ra,0xffffe
    8000543a:	302080e7          	jalr	770(ra) # 80003738 <ilock>
  if(ip->type == T_DIR){
    8000543e:	04449703          	lh	a4,68(s1)
    80005442:	4785                	li	a5,1
    80005444:	08f70463          	beq	a4,a5,800054cc <sys_link+0xea>
  ip->nlink++;
    80005448:	04a4d783          	lhu	a5,74(s1)
    8000544c:	2785                	addiw	a5,a5,1
    8000544e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005452:	8526                	mv	a0,s1
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	218080e7          	jalr	536(ra) # 8000366c <iupdate>
  iunlock(ip);
    8000545c:	8526                	mv	a0,s1
    8000545e:	ffffe097          	auipc	ra,0xffffe
    80005462:	39c080e7          	jalr	924(ra) # 800037fa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005466:	fd040593          	addi	a1,s0,-48
    8000546a:	f5040513          	addi	a0,s0,-176
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	a8e080e7          	jalr	-1394(ra) # 80003efc <nameiparent>
    80005476:	892a                	mv	s2,a0
    80005478:	c935                	beqz	a0,800054ec <sys_link+0x10a>
  ilock(dp);
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	2be080e7          	jalr	702(ra) # 80003738 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005482:	00092703          	lw	a4,0(s2)
    80005486:	409c                	lw	a5,0(s1)
    80005488:	04f71d63          	bne	a4,a5,800054e2 <sys_link+0x100>
    8000548c:	40d0                	lw	a2,4(s1)
    8000548e:	fd040593          	addi	a1,s0,-48
    80005492:	854a                	mv	a0,s2
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	998080e7          	jalr	-1640(ra) # 80003e2c <dirlink>
    8000549c:	04054363          	bltz	a0,800054e2 <sys_link+0x100>
  iunlockput(dp);
    800054a0:	854a                	mv	a0,s2
    800054a2:	ffffe097          	auipc	ra,0xffffe
    800054a6:	4f8080e7          	jalr	1272(ra) # 8000399a <iunlockput>
  iput(ip);
    800054aa:	8526                	mv	a0,s1
    800054ac:	ffffe097          	auipc	ra,0xffffe
    800054b0:	446080e7          	jalr	1094(ra) # 800038f2 <iput>
  end_op();
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	ca4080e7          	jalr	-860(ra) # 80004158 <end_op>
  return 0;
    800054bc:	4781                	li	a5,0
    800054be:	a085                	j	8000551e <sys_link+0x13c>
    end_op();
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	c98080e7          	jalr	-872(ra) # 80004158 <end_op>
    return -1;
    800054c8:	57fd                	li	a5,-1
    800054ca:	a891                	j	8000551e <sys_link+0x13c>
    iunlockput(ip);
    800054cc:	8526                	mv	a0,s1
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	4cc080e7          	jalr	1228(ra) # 8000399a <iunlockput>
    end_op();
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	c82080e7          	jalr	-894(ra) # 80004158 <end_op>
    return -1;
    800054de:	57fd                	li	a5,-1
    800054e0:	a83d                	j	8000551e <sys_link+0x13c>
    iunlockput(dp);
    800054e2:	854a                	mv	a0,s2
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	4b6080e7          	jalr	1206(ra) # 8000399a <iunlockput>
  ilock(ip);
    800054ec:	8526                	mv	a0,s1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	24a080e7          	jalr	586(ra) # 80003738 <ilock>
  ip->nlink--;
    800054f6:	04a4d783          	lhu	a5,74(s1)
    800054fa:	37fd                	addiw	a5,a5,-1
    800054fc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005500:	8526                	mv	a0,s1
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	16a080e7          	jalr	362(ra) # 8000366c <iupdate>
  iunlockput(ip);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	48e080e7          	jalr	1166(ra) # 8000399a <iunlockput>
  end_op();
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	c44080e7          	jalr	-956(ra) # 80004158 <end_op>
  return -1;
    8000551c:	57fd                	li	a5,-1
}
    8000551e:	853e                	mv	a0,a5
    80005520:	70b2                	ld	ra,296(sp)
    80005522:	7412                	ld	s0,288(sp)
    80005524:	64f2                	ld	s1,280(sp)
    80005526:	6952                	ld	s2,272(sp)
    80005528:	6155                	addi	sp,sp,304
    8000552a:	8082                	ret

000000008000552c <sys_unlink>:
{
    8000552c:	7151                	addi	sp,sp,-240
    8000552e:	f586                	sd	ra,232(sp)
    80005530:	f1a2                	sd	s0,224(sp)
    80005532:	eda6                	sd	s1,216(sp)
    80005534:	e9ca                	sd	s2,208(sp)
    80005536:	e5ce                	sd	s3,200(sp)
    80005538:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000553a:	08000613          	li	a2,128
    8000553e:	f3040593          	addi	a1,s0,-208
    80005542:	4501                	li	a0,0
    80005544:	ffffd097          	auipc	ra,0xffffd
    80005548:	6d2080e7          	jalr	1746(ra) # 80002c16 <argstr>
    8000554c:	18054163          	bltz	a0,800056ce <sys_unlink+0x1a2>
  begin_op();
    80005550:	fffff097          	auipc	ra,0xfffff
    80005554:	b8e080e7          	jalr	-1138(ra) # 800040de <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005558:	fb040593          	addi	a1,s0,-80
    8000555c:	f3040513          	addi	a0,s0,-208
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	99c080e7          	jalr	-1636(ra) # 80003efc <nameiparent>
    80005568:	84aa                	mv	s1,a0
    8000556a:	c979                	beqz	a0,80005640 <sys_unlink+0x114>
  ilock(dp);
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	1cc080e7          	jalr	460(ra) # 80003738 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005574:	00004597          	auipc	a1,0x4
    80005578:	1fc58593          	addi	a1,a1,508 # 80009770 <syscalls+0x318>
    8000557c:	fb040513          	addi	a0,s0,-80
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	682080e7          	jalr	1666(ra) # 80003c02 <namecmp>
    80005588:	14050a63          	beqz	a0,800056dc <sys_unlink+0x1b0>
    8000558c:	00004597          	auipc	a1,0x4
    80005590:	1ec58593          	addi	a1,a1,492 # 80009778 <syscalls+0x320>
    80005594:	fb040513          	addi	a0,s0,-80
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	66a080e7          	jalr	1642(ra) # 80003c02 <namecmp>
    800055a0:	12050e63          	beqz	a0,800056dc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055a4:	f2c40613          	addi	a2,s0,-212
    800055a8:	fb040593          	addi	a1,s0,-80
    800055ac:	8526                	mv	a0,s1
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	66e080e7          	jalr	1646(ra) # 80003c1c <dirlookup>
    800055b6:	892a                	mv	s2,a0
    800055b8:	12050263          	beqz	a0,800056dc <sys_unlink+0x1b0>
  ilock(ip);
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	17c080e7          	jalr	380(ra) # 80003738 <ilock>
  if(ip->nlink < 1)
    800055c4:	04a91783          	lh	a5,74(s2)
    800055c8:	08f05263          	blez	a5,8000564c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055cc:	04491703          	lh	a4,68(s2)
    800055d0:	4785                	li	a5,1
    800055d2:	08f70563          	beq	a4,a5,8000565c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055d6:	4641                	li	a2,16
    800055d8:	4581                	li	a1,0
    800055da:	fc040513          	addi	a0,s0,-64
    800055de:	ffffb097          	auipc	ra,0xffffb
    800055e2:	766080e7          	jalr	1894(ra) # 80000d44 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055e6:	4741                	li	a4,16
    800055e8:	f2c42683          	lw	a3,-212(s0)
    800055ec:	fc040613          	addi	a2,s0,-64
    800055f0:	4581                	li	a1,0
    800055f2:	8526                	mv	a0,s1
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	4f0080e7          	jalr	1264(ra) # 80003ae4 <writei>
    800055fc:	47c1                	li	a5,16
    800055fe:	0af51563          	bne	a0,a5,800056a8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005602:	04491703          	lh	a4,68(s2)
    80005606:	4785                	li	a5,1
    80005608:	0af70863          	beq	a4,a5,800056b8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	38c080e7          	jalr	908(ra) # 8000399a <iunlockput>
  ip->nlink--;
    80005616:	04a95783          	lhu	a5,74(s2)
    8000561a:	37fd                	addiw	a5,a5,-1
    8000561c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005620:	854a                	mv	a0,s2
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	04a080e7          	jalr	74(ra) # 8000366c <iupdate>
  iunlockput(ip);
    8000562a:	854a                	mv	a0,s2
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	36e080e7          	jalr	878(ra) # 8000399a <iunlockput>
  end_op();
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	b24080e7          	jalr	-1244(ra) # 80004158 <end_op>
  return 0;
    8000563c:	4501                	li	a0,0
    8000563e:	a84d                	j	800056f0 <sys_unlink+0x1c4>
    end_op();
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	b18080e7          	jalr	-1256(ra) # 80004158 <end_op>
    return -1;
    80005648:	557d                	li	a0,-1
    8000564a:	a05d                	j	800056f0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000564c:	00004517          	auipc	a0,0x4
    80005650:	13450513          	addi	a0,a0,308 # 80009780 <syscalls+0x328>
    80005654:	ffffb097          	auipc	ra,0xffffb
    80005658:	eec080e7          	jalr	-276(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000565c:	04c92703          	lw	a4,76(s2)
    80005660:	02000793          	li	a5,32
    80005664:	f6e7f9e3          	bgeu	a5,a4,800055d6 <sys_unlink+0xaa>
    80005668:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000566c:	4741                	li	a4,16
    8000566e:	86ce                	mv	a3,s3
    80005670:	f1840613          	addi	a2,s0,-232
    80005674:	4581                	li	a1,0
    80005676:	854a                	mv	a0,s2
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	374080e7          	jalr	884(ra) # 800039ec <readi>
    80005680:	47c1                	li	a5,16
    80005682:	00f51b63          	bne	a0,a5,80005698 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005686:	f1845783          	lhu	a5,-232(s0)
    8000568a:	e7a1                	bnez	a5,800056d2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000568c:	29c1                	addiw	s3,s3,16
    8000568e:	04c92783          	lw	a5,76(s2)
    80005692:	fcf9ede3          	bltu	s3,a5,8000566c <sys_unlink+0x140>
    80005696:	b781                	j	800055d6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005698:	00004517          	auipc	a0,0x4
    8000569c:	10050513          	addi	a0,a0,256 # 80009798 <syscalls+0x340>
    800056a0:	ffffb097          	auipc	ra,0xffffb
    800056a4:	ea0080e7          	jalr	-352(ra) # 80000540 <panic>
    panic("unlink: writei");
    800056a8:	00004517          	auipc	a0,0x4
    800056ac:	10850513          	addi	a0,a0,264 # 800097b0 <syscalls+0x358>
    800056b0:	ffffb097          	auipc	ra,0xffffb
    800056b4:	e90080e7          	jalr	-368(ra) # 80000540 <panic>
    dp->nlink--;
    800056b8:	04a4d783          	lhu	a5,74(s1)
    800056bc:	37fd                	addiw	a5,a5,-1
    800056be:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	fa8080e7          	jalr	-88(ra) # 8000366c <iupdate>
    800056cc:	b781                	j	8000560c <sys_unlink+0xe0>
    return -1;
    800056ce:	557d                	li	a0,-1
    800056d0:	a005                	j	800056f0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056d2:	854a                	mv	a0,s2
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	2c6080e7          	jalr	710(ra) # 8000399a <iunlockput>
  iunlockput(dp);
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	2bc080e7          	jalr	700(ra) # 8000399a <iunlockput>
  end_op();
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	a72080e7          	jalr	-1422(ra) # 80004158 <end_op>
  return -1;
    800056ee:	557d                	li	a0,-1
}
    800056f0:	70ae                	ld	ra,232(sp)
    800056f2:	740e                	ld	s0,224(sp)
    800056f4:	64ee                	ld	s1,216(sp)
    800056f6:	694e                	ld	s2,208(sp)
    800056f8:	69ae                	ld	s3,200(sp)
    800056fa:	616d                	addi	sp,sp,240
    800056fc:	8082                	ret

00000000800056fe <sys_open>:

uint64
sys_open(void)
{
    800056fe:	7131                	addi	sp,sp,-192
    80005700:	fd06                	sd	ra,184(sp)
    80005702:	f922                	sd	s0,176(sp)
    80005704:	f526                	sd	s1,168(sp)
    80005706:	f14a                	sd	s2,160(sp)
    80005708:	ed4e                	sd	s3,152(sp)
    8000570a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000570c:	f4c40593          	addi	a1,s0,-180
    80005710:	4505                	li	a0,1
    80005712:	ffffd097          	auipc	ra,0xffffd
    80005716:	4c4080e7          	jalr	1220(ra) # 80002bd6 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000571a:	08000613          	li	a2,128
    8000571e:	f5040593          	addi	a1,s0,-176
    80005722:	4501                	li	a0,0
    80005724:	ffffd097          	auipc	ra,0xffffd
    80005728:	4f2080e7          	jalr	1266(ra) # 80002c16 <argstr>
    8000572c:	87aa                	mv	a5,a0
    return -1;
    8000572e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005730:	0a07c863          	bltz	a5,800057e0 <sys_open+0xe2>

  begin_op();
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	9aa080e7          	jalr	-1622(ra) # 800040de <begin_op>

  if(omode & O_CREATE){
    8000573c:	f4c42783          	lw	a5,-180(s0)
    80005740:	2007f793          	andi	a5,a5,512
    80005744:	cbdd                	beqz	a5,800057fa <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005746:	4681                	li	a3,0
    80005748:	4601                	li	a2,0
    8000574a:	4589                	li	a1,2
    8000574c:	f5040513          	addi	a0,s0,-176
    80005750:	00000097          	auipc	ra,0x0
    80005754:	97a080e7          	jalr	-1670(ra) # 800050ca <create>
    80005758:	84aa                	mv	s1,a0
    if(ip == 0){
    8000575a:	c951                	beqz	a0,800057ee <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000575c:	04449703          	lh	a4,68(s1)
    80005760:	478d                	li	a5,3
    80005762:	00f71763          	bne	a4,a5,80005770 <sys_open+0x72>
    80005766:	0464d703          	lhu	a4,70(s1)
    8000576a:	47a5                	li	a5,9
    8000576c:	0ce7ec63          	bltu	a5,a4,80005844 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	d76080e7          	jalr	-650(ra) # 800044e6 <filealloc>
    80005778:	892a                	mv	s2,a0
    8000577a:	c56d                	beqz	a0,80005864 <sys_open+0x166>
    8000577c:	00000097          	auipc	ra,0x0
    80005780:	90c080e7          	jalr	-1780(ra) # 80005088 <fdalloc>
    80005784:	89aa                	mv	s3,a0
    80005786:	0c054a63          	bltz	a0,8000585a <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000578a:	04449703          	lh	a4,68(s1)
    8000578e:	478d                	li	a5,3
    80005790:	0ef70563          	beq	a4,a5,8000587a <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005794:	4789                	li	a5,2
    80005796:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    8000579a:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000579e:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800057a2:	f4c42783          	lw	a5,-180(s0)
    800057a6:	0017c713          	xori	a4,a5,1
    800057aa:	8b05                	andi	a4,a4,1
    800057ac:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057b0:	0037f713          	andi	a4,a5,3
    800057b4:	00e03733          	snez	a4,a4
    800057b8:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057bc:	4007f793          	andi	a5,a5,1024
    800057c0:	c791                	beqz	a5,800057cc <sys_open+0xce>
    800057c2:	04449703          	lh	a4,68(s1)
    800057c6:	4789                	li	a5,2
    800057c8:	0cf70063          	beq	a4,a5,80005888 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    800057cc:	8526                	mv	a0,s1
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	02c080e7          	jalr	44(ra) # 800037fa <iunlock>
  end_op();
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	982080e7          	jalr	-1662(ra) # 80004158 <end_op>

  return fd;
    800057de:	854e                	mv	a0,s3
}
    800057e0:	70ea                	ld	ra,184(sp)
    800057e2:	744a                	ld	s0,176(sp)
    800057e4:	74aa                	ld	s1,168(sp)
    800057e6:	790a                	ld	s2,160(sp)
    800057e8:	69ea                	ld	s3,152(sp)
    800057ea:	6129                	addi	sp,sp,192
    800057ec:	8082                	ret
      end_op();
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	96a080e7          	jalr	-1686(ra) # 80004158 <end_op>
      return -1;
    800057f6:	557d                	li	a0,-1
    800057f8:	b7e5                	j	800057e0 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800057fa:	f5040513          	addi	a0,s0,-176
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	6e0080e7          	jalr	1760(ra) # 80003ede <namei>
    80005806:	84aa                	mv	s1,a0
    80005808:	c905                	beqz	a0,80005838 <sys_open+0x13a>
    ilock(ip);
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	f2e080e7          	jalr	-210(ra) # 80003738 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005812:	04449703          	lh	a4,68(s1)
    80005816:	4785                	li	a5,1
    80005818:	f4f712e3          	bne	a4,a5,8000575c <sys_open+0x5e>
    8000581c:	f4c42783          	lw	a5,-180(s0)
    80005820:	dba1                	beqz	a5,80005770 <sys_open+0x72>
      iunlockput(ip);
    80005822:	8526                	mv	a0,s1
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	176080e7          	jalr	374(ra) # 8000399a <iunlockput>
      end_op();
    8000582c:	fffff097          	auipc	ra,0xfffff
    80005830:	92c080e7          	jalr	-1748(ra) # 80004158 <end_op>
      return -1;
    80005834:	557d                	li	a0,-1
    80005836:	b76d                	j	800057e0 <sys_open+0xe2>
      end_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	920080e7          	jalr	-1760(ra) # 80004158 <end_op>
      return -1;
    80005840:	557d                	li	a0,-1
    80005842:	bf79                	j	800057e0 <sys_open+0xe2>
    iunlockput(ip);
    80005844:	8526                	mv	a0,s1
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	154080e7          	jalr	340(ra) # 8000399a <iunlockput>
    end_op();
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	90a080e7          	jalr	-1782(ra) # 80004158 <end_op>
    return -1;
    80005856:	557d                	li	a0,-1
    80005858:	b761                	j	800057e0 <sys_open+0xe2>
      fileclose(f);
    8000585a:	854a                	mv	a0,s2
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	d46080e7          	jalr	-698(ra) # 800045a2 <fileclose>
    iunlockput(ip);
    80005864:	8526                	mv	a0,s1
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	134080e7          	jalr	308(ra) # 8000399a <iunlockput>
    end_op();
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	8ea080e7          	jalr	-1814(ra) # 80004158 <end_op>
    return -1;
    80005876:	557d                	li	a0,-1
    80005878:	b7a5                	j	800057e0 <sys_open+0xe2>
    f->type = FD_DEVICE;
    8000587a:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    8000587e:	04649783          	lh	a5,70(s1)
    80005882:	02f91223          	sh	a5,36(s2)
    80005886:	bf21                	j	8000579e <sys_open+0xa0>
    itrunc(ip);
    80005888:	8526                	mv	a0,s1
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	fbc080e7          	jalr	-68(ra) # 80003846 <itrunc>
    80005892:	bf2d                	j	800057cc <sys_open+0xce>

0000000080005894 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005894:	7175                	addi	sp,sp,-144
    80005896:	e506                	sd	ra,136(sp)
    80005898:	e122                	sd	s0,128(sp)
    8000589a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	842080e7          	jalr	-1982(ra) # 800040de <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058a4:	08000613          	li	a2,128
    800058a8:	f7040593          	addi	a1,s0,-144
    800058ac:	4501                	li	a0,0
    800058ae:	ffffd097          	auipc	ra,0xffffd
    800058b2:	368080e7          	jalr	872(ra) # 80002c16 <argstr>
    800058b6:	02054963          	bltz	a0,800058e8 <sys_mkdir+0x54>
    800058ba:	4681                	li	a3,0
    800058bc:	4601                	li	a2,0
    800058be:	4585                	li	a1,1
    800058c0:	f7040513          	addi	a0,s0,-144
    800058c4:	00000097          	auipc	ra,0x0
    800058c8:	806080e7          	jalr	-2042(ra) # 800050ca <create>
    800058cc:	cd11                	beqz	a0,800058e8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	0cc080e7          	jalr	204(ra) # 8000399a <iunlockput>
  end_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	882080e7          	jalr	-1918(ra) # 80004158 <end_op>
  return 0;
    800058de:	4501                	li	a0,0
}
    800058e0:	60aa                	ld	ra,136(sp)
    800058e2:	640a                	ld	s0,128(sp)
    800058e4:	6149                	addi	sp,sp,144
    800058e6:	8082                	ret
    end_op();
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	870080e7          	jalr	-1936(ra) # 80004158 <end_op>
    return -1;
    800058f0:	557d                	li	a0,-1
    800058f2:	b7fd                	j	800058e0 <sys_mkdir+0x4c>

00000000800058f4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058f4:	7135                	addi	sp,sp,-160
    800058f6:	ed06                	sd	ra,152(sp)
    800058f8:	e922                	sd	s0,144(sp)
    800058fa:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	7e2080e7          	jalr	2018(ra) # 800040de <begin_op>
  argint(1, &major);
    80005904:	f6c40593          	addi	a1,s0,-148
    80005908:	4505                	li	a0,1
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	2cc080e7          	jalr	716(ra) # 80002bd6 <argint>
  argint(2, &minor);
    80005912:	f6840593          	addi	a1,s0,-152
    80005916:	4509                	li	a0,2
    80005918:	ffffd097          	auipc	ra,0xffffd
    8000591c:	2be080e7          	jalr	702(ra) # 80002bd6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005920:	08000613          	li	a2,128
    80005924:	f7040593          	addi	a1,s0,-144
    80005928:	4501                	li	a0,0
    8000592a:	ffffd097          	auipc	ra,0xffffd
    8000592e:	2ec080e7          	jalr	748(ra) # 80002c16 <argstr>
    80005932:	02054b63          	bltz	a0,80005968 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005936:	f6841683          	lh	a3,-152(s0)
    8000593a:	f6c41603          	lh	a2,-148(s0)
    8000593e:	458d                	li	a1,3
    80005940:	f7040513          	addi	a0,s0,-144
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	786080e7          	jalr	1926(ra) # 800050ca <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000594c:	cd11                	beqz	a0,80005968 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	04c080e7          	jalr	76(ra) # 8000399a <iunlockput>
  end_op();
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	802080e7          	jalr	-2046(ra) # 80004158 <end_op>
  return 0;
    8000595e:	4501                	li	a0,0
}
    80005960:	60ea                	ld	ra,152(sp)
    80005962:	644a                	ld	s0,144(sp)
    80005964:	610d                	addi	sp,sp,160
    80005966:	8082                	ret
    end_op();
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	7f0080e7          	jalr	2032(ra) # 80004158 <end_op>
    return -1;
    80005970:	557d                	li	a0,-1
    80005972:	b7fd                	j	80005960 <sys_mknod+0x6c>

0000000080005974 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005974:	7135                	addi	sp,sp,-160
    80005976:	ed06                	sd	ra,152(sp)
    80005978:	e922                	sd	s0,144(sp)
    8000597a:	e526                	sd	s1,136(sp)
    8000597c:	e14a                	sd	s2,128(sp)
    8000597e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005980:	ffffc097          	auipc	ra,0xffffc
    80005984:	0a4080e7          	jalr	164(ra) # 80001a24 <myproc>
    80005988:	892a                	mv	s2,a0
  
  begin_op();
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	754080e7          	jalr	1876(ra) # 800040de <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005992:	08000613          	li	a2,128
    80005996:	f6040593          	addi	a1,s0,-160
    8000599a:	4501                	li	a0,0
    8000599c:	ffffd097          	auipc	ra,0xffffd
    800059a0:	27a080e7          	jalr	634(ra) # 80002c16 <argstr>
    800059a4:	04054b63          	bltz	a0,800059fa <sys_chdir+0x86>
    800059a8:	f6040513          	addi	a0,s0,-160
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	532080e7          	jalr	1330(ra) # 80003ede <namei>
    800059b4:	84aa                	mv	s1,a0
    800059b6:	c131                	beqz	a0,800059fa <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	d80080e7          	jalr	-640(ra) # 80003738 <ilock>
  if(ip->type != T_DIR){
    800059c0:	04449703          	lh	a4,68(s1)
    800059c4:	4785                	li	a5,1
    800059c6:	04f71063          	bne	a4,a5,80005a06 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059ca:	8526                	mv	a0,s1
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	e2e080e7          	jalr	-466(ra) # 800037fa <iunlock>
  iput(p->cwd);
    800059d4:	15093503          	ld	a0,336(s2)
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	f1a080e7          	jalr	-230(ra) # 800038f2 <iput>
  end_op();
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	778080e7          	jalr	1912(ra) # 80004158 <end_op>
  p->cwd = ip;
    800059e8:	14993823          	sd	s1,336(s2)
  return 0;
    800059ec:	4501                	li	a0,0
}
    800059ee:	60ea                	ld	ra,152(sp)
    800059f0:	644a                	ld	s0,144(sp)
    800059f2:	64aa                	ld	s1,136(sp)
    800059f4:	690a                	ld	s2,128(sp)
    800059f6:	610d                	addi	sp,sp,160
    800059f8:	8082                	ret
    end_op();
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	75e080e7          	jalr	1886(ra) # 80004158 <end_op>
    return -1;
    80005a02:	557d                	li	a0,-1
    80005a04:	b7ed                	j	800059ee <sys_chdir+0x7a>
    iunlockput(ip);
    80005a06:	8526                	mv	a0,s1
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	f92080e7          	jalr	-110(ra) # 8000399a <iunlockput>
    end_op();
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	748080e7          	jalr	1864(ra) # 80004158 <end_op>
    return -1;
    80005a18:	557d                	li	a0,-1
    80005a1a:	bfd1                	j	800059ee <sys_chdir+0x7a>

0000000080005a1c <sys_exec>:

uint64
sys_exec(void)
{
    80005a1c:	7121                	addi	sp,sp,-448
    80005a1e:	ff06                	sd	ra,440(sp)
    80005a20:	fb22                	sd	s0,432(sp)
    80005a22:	f726                	sd	s1,424(sp)
    80005a24:	f34a                	sd	s2,416(sp)
    80005a26:	ef4e                	sd	s3,408(sp)
    80005a28:	eb52                	sd	s4,400(sp)
    80005a2a:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a2c:	e4840593          	addi	a1,s0,-440
    80005a30:	4505                	li	a0,1
    80005a32:	ffffd097          	auipc	ra,0xffffd
    80005a36:	1c4080e7          	jalr	452(ra) # 80002bf6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a3a:	08000613          	li	a2,128
    80005a3e:	f5040593          	addi	a1,s0,-176
    80005a42:	4501                	li	a0,0
    80005a44:	ffffd097          	auipc	ra,0xffffd
    80005a48:	1d2080e7          	jalr	466(ra) # 80002c16 <argstr>
    80005a4c:	87aa                	mv	a5,a0
    return -1;
    80005a4e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a50:	0c07c263          	bltz	a5,80005b14 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005a54:	10000613          	li	a2,256
    80005a58:	4581                	li	a1,0
    80005a5a:	e5040513          	addi	a0,s0,-432
    80005a5e:	ffffb097          	auipc	ra,0xffffb
    80005a62:	2e6080e7          	jalr	742(ra) # 80000d44 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a66:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005a6a:	89a6                	mv	s3,s1
    80005a6c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a6e:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a72:	00391513          	slli	a0,s2,0x3
    80005a76:	e4040593          	addi	a1,s0,-448
    80005a7a:	e4843783          	ld	a5,-440(s0)
    80005a7e:	953e                	add	a0,a0,a5
    80005a80:	ffffd097          	auipc	ra,0xffffd
    80005a84:	0b8080e7          	jalr	184(ra) # 80002b38 <fetchaddr>
    80005a88:	02054a63          	bltz	a0,80005abc <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005a8c:	e4043783          	ld	a5,-448(s0)
    80005a90:	c3b9                	beqz	a5,80005ad6 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a92:	ffffb097          	auipc	ra,0xffffb
    80005a96:	0c6080e7          	jalr	198(ra) # 80000b58 <kalloc>
    80005a9a:	85aa                	mv	a1,a0
    80005a9c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005aa0:	cd11                	beqz	a0,80005abc <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aa2:	6605                	lui	a2,0x1
    80005aa4:	e4043503          	ld	a0,-448(s0)
    80005aa8:	ffffd097          	auipc	ra,0xffffd
    80005aac:	0e2080e7          	jalr	226(ra) # 80002b8a <fetchstr>
    80005ab0:	00054663          	bltz	a0,80005abc <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005ab4:	0905                	addi	s2,s2,1
    80005ab6:	09a1                	addi	s3,s3,8
    80005ab8:	fb491de3          	bne	s2,s4,80005a72 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005abc:	f5040913          	addi	s2,s0,-176
    80005ac0:	6088                	ld	a0,0(s1)
    80005ac2:	c921                	beqz	a0,80005b12 <sys_exec+0xf6>
    kfree(argv[i]);
    80005ac4:	ffffb097          	auipc	ra,0xffffb
    80005ac8:	f96080e7          	jalr	-106(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005acc:	04a1                	addi	s1,s1,8
    80005ace:	ff2499e3          	bne	s1,s2,80005ac0 <sys_exec+0xa4>
  return -1;
    80005ad2:	557d                	li	a0,-1
    80005ad4:	a081                	j	80005b14 <sys_exec+0xf8>
      argv[i] = 0;
    80005ad6:	0009079b          	sext.w	a5,s2
    80005ada:	078e                	slli	a5,a5,0x3
    80005adc:	fd078793          	addi	a5,a5,-48
    80005ae0:	97a2                	add	a5,a5,s0
    80005ae2:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005ae6:	e5040593          	addi	a1,s0,-432
    80005aea:	f5040513          	addi	a0,s0,-176
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	12a080e7          	jalr	298(ra) # 80004c18 <exec>
    80005af6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af8:	f5040993          	addi	s3,s0,-176
    80005afc:	6088                	ld	a0,0(s1)
    80005afe:	c901                	beqz	a0,80005b0e <sys_exec+0xf2>
    kfree(argv[i]);
    80005b00:	ffffb097          	auipc	ra,0xffffb
    80005b04:	f5a080e7          	jalr	-166(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b08:	04a1                	addi	s1,s1,8
    80005b0a:	ff3499e3          	bne	s1,s3,80005afc <sys_exec+0xe0>
  return ret;
    80005b0e:	854a                	mv	a0,s2
    80005b10:	a011                	j	80005b14 <sys_exec+0xf8>
  return -1;
    80005b12:	557d                	li	a0,-1
}
    80005b14:	70fa                	ld	ra,440(sp)
    80005b16:	745a                	ld	s0,432(sp)
    80005b18:	74ba                	ld	s1,424(sp)
    80005b1a:	791a                	ld	s2,416(sp)
    80005b1c:	69fa                	ld	s3,408(sp)
    80005b1e:	6a5a                	ld	s4,400(sp)
    80005b20:	6139                	addi	sp,sp,448
    80005b22:	8082                	ret

0000000080005b24 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b24:	7139                	addi	sp,sp,-64
    80005b26:	fc06                	sd	ra,56(sp)
    80005b28:	f822                	sd	s0,48(sp)
    80005b2a:	f426                	sd	s1,40(sp)
    80005b2c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b2e:	ffffc097          	auipc	ra,0xffffc
    80005b32:	ef6080e7          	jalr	-266(ra) # 80001a24 <myproc>
    80005b36:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b38:	fd840593          	addi	a1,s0,-40
    80005b3c:	4501                	li	a0,0
    80005b3e:	ffffd097          	auipc	ra,0xffffd
    80005b42:	0b8080e7          	jalr	184(ra) # 80002bf6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b46:	fc840593          	addi	a1,s0,-56
    80005b4a:	fd040513          	addi	a0,s0,-48
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	d80080e7          	jalr	-640(ra) # 800048ce <pipealloc>
    return -1;
    80005b56:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b58:	0c054463          	bltz	a0,80005c20 <sys_pipe+0xfc>
  fd0 = -1;
    80005b5c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b60:	fd043503          	ld	a0,-48(s0)
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	524080e7          	jalr	1316(ra) # 80005088 <fdalloc>
    80005b6c:	fca42223          	sw	a0,-60(s0)
    80005b70:	08054b63          	bltz	a0,80005c06 <sys_pipe+0xe2>
    80005b74:	fc843503          	ld	a0,-56(s0)
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	510080e7          	jalr	1296(ra) # 80005088 <fdalloc>
    80005b80:	fca42023          	sw	a0,-64(s0)
    80005b84:	06054863          	bltz	a0,80005bf4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b88:	4691                	li	a3,4
    80005b8a:	fc440613          	addi	a2,s0,-60
    80005b8e:	fd843583          	ld	a1,-40(s0)
    80005b92:	68a8                	ld	a0,80(s1)
    80005b94:	ffffc097          	auipc	ra,0xffffc
    80005b98:	b50080e7          	jalr	-1200(ra) # 800016e4 <copyout>
    80005b9c:	02054063          	bltz	a0,80005bbc <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ba0:	4691                	li	a3,4
    80005ba2:	fc040613          	addi	a2,s0,-64
    80005ba6:	fd843583          	ld	a1,-40(s0)
    80005baa:	0591                	addi	a1,a1,4
    80005bac:	68a8                	ld	a0,80(s1)
    80005bae:	ffffc097          	auipc	ra,0xffffc
    80005bb2:	b36080e7          	jalr	-1226(ra) # 800016e4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bb6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bb8:	06055463          	bgez	a0,80005c20 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005bbc:	fc442783          	lw	a5,-60(s0)
    80005bc0:	07e9                	addi	a5,a5,26
    80005bc2:	078e                	slli	a5,a5,0x3
    80005bc4:	97a6                	add	a5,a5,s1
    80005bc6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bca:	fc042783          	lw	a5,-64(s0)
    80005bce:	07e9                	addi	a5,a5,26
    80005bd0:	078e                	slli	a5,a5,0x3
    80005bd2:	94be                	add	s1,s1,a5
    80005bd4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bd8:	fd043503          	ld	a0,-48(s0)
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	9c6080e7          	jalr	-1594(ra) # 800045a2 <fileclose>
    fileclose(wf);
    80005be4:	fc843503          	ld	a0,-56(s0)
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	9ba080e7          	jalr	-1606(ra) # 800045a2 <fileclose>
    return -1;
    80005bf0:	57fd                	li	a5,-1
    80005bf2:	a03d                	j	80005c20 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005bf4:	fc442783          	lw	a5,-60(s0)
    80005bf8:	0007c763          	bltz	a5,80005c06 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005bfc:	07e9                	addi	a5,a5,26
    80005bfe:	078e                	slli	a5,a5,0x3
    80005c00:	97a6                	add	a5,a5,s1
    80005c02:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c06:	fd043503          	ld	a0,-48(s0)
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	998080e7          	jalr	-1640(ra) # 800045a2 <fileclose>
    fileclose(wf);
    80005c12:	fc843503          	ld	a0,-56(s0)
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	98c080e7          	jalr	-1652(ra) # 800045a2 <fileclose>
    return -1;
    80005c1e:	57fd                	li	a5,-1
}
    80005c20:	853e                	mv	a0,a5
    80005c22:	70e2                	ld	ra,56(sp)
    80005c24:	7442                	ld	s0,48(sp)
    80005c26:	74a2                	ld	s1,40(sp)
    80005c28:	6121                	addi	sp,sp,64
    80005c2a:	8082                	ret
    80005c2c:	0000                	unimp
	...

0000000080005c30 <kernelvec>:
    80005c30:	7111                	addi	sp,sp,-256
    80005c32:	e006                	sd	ra,0(sp)
    80005c34:	e40a                	sd	sp,8(sp)
    80005c36:	e80e                	sd	gp,16(sp)
    80005c38:	ec12                	sd	tp,24(sp)
    80005c3a:	f016                	sd	t0,32(sp)
    80005c3c:	f41a                	sd	t1,40(sp)
    80005c3e:	f81e                	sd	t2,48(sp)
    80005c40:	fc22                	sd	s0,56(sp)
    80005c42:	e0a6                	sd	s1,64(sp)
    80005c44:	e4aa                	sd	a0,72(sp)
    80005c46:	e8ae                	sd	a1,80(sp)
    80005c48:	ecb2                	sd	a2,88(sp)
    80005c4a:	f0b6                	sd	a3,96(sp)
    80005c4c:	f4ba                	sd	a4,104(sp)
    80005c4e:	f8be                	sd	a5,112(sp)
    80005c50:	fcc2                	sd	a6,120(sp)
    80005c52:	e146                	sd	a7,128(sp)
    80005c54:	e54a                	sd	s2,136(sp)
    80005c56:	e94e                	sd	s3,144(sp)
    80005c58:	ed52                	sd	s4,152(sp)
    80005c5a:	f156                	sd	s5,160(sp)
    80005c5c:	f55a                	sd	s6,168(sp)
    80005c5e:	f95e                	sd	s7,176(sp)
    80005c60:	fd62                	sd	s8,184(sp)
    80005c62:	e1e6                	sd	s9,192(sp)
    80005c64:	e5ea                	sd	s10,200(sp)
    80005c66:	e9ee                	sd	s11,208(sp)
    80005c68:	edf2                	sd	t3,216(sp)
    80005c6a:	f1f6                	sd	t4,224(sp)
    80005c6c:	f5fa                	sd	t5,232(sp)
    80005c6e:	f9fe                	sd	t6,240(sp)
    80005c70:	d95fc0ef          	jal	ra,80002a04 <kerneltrap>
    80005c74:	6082                	ld	ra,0(sp)
    80005c76:	6122                	ld	sp,8(sp)
    80005c78:	61c2                	ld	gp,16(sp)
    80005c7a:	7282                	ld	t0,32(sp)
    80005c7c:	7322                	ld	t1,40(sp)
    80005c7e:	73c2                	ld	t2,48(sp)
    80005c80:	7462                	ld	s0,56(sp)
    80005c82:	6486                	ld	s1,64(sp)
    80005c84:	6526                	ld	a0,72(sp)
    80005c86:	65c6                	ld	a1,80(sp)
    80005c88:	6666                	ld	a2,88(sp)
    80005c8a:	7686                	ld	a3,96(sp)
    80005c8c:	7726                	ld	a4,104(sp)
    80005c8e:	77c6                	ld	a5,112(sp)
    80005c90:	7866                	ld	a6,120(sp)
    80005c92:	688a                	ld	a7,128(sp)
    80005c94:	692a                	ld	s2,136(sp)
    80005c96:	69ca                	ld	s3,144(sp)
    80005c98:	6a6a                	ld	s4,152(sp)
    80005c9a:	7a8a                	ld	s5,160(sp)
    80005c9c:	7b2a                	ld	s6,168(sp)
    80005c9e:	7bca                	ld	s7,176(sp)
    80005ca0:	7c6a                	ld	s8,184(sp)
    80005ca2:	6c8e                	ld	s9,192(sp)
    80005ca4:	6d2e                	ld	s10,200(sp)
    80005ca6:	6dce                	ld	s11,208(sp)
    80005ca8:	6e6e                	ld	t3,216(sp)
    80005caa:	7e8e                	ld	t4,224(sp)
    80005cac:	7f2e                	ld	t5,232(sp)
    80005cae:	7fce                	ld	t6,240(sp)
    80005cb0:	6111                	addi	sp,sp,256
    80005cb2:	10200073          	sret
    80005cb6:	00000013          	nop
    80005cba:	00000013          	nop
    80005cbe:	0001                	nop

0000000080005cc0 <timervec>:
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	e10c                	sd	a1,0(a0)
    80005cc6:	e510                	sd	a2,8(a0)
    80005cc8:	e914                	sd	a3,16(a0)
    80005cca:	6d0c                	ld	a1,24(a0)
    80005ccc:	7110                	ld	a2,32(a0)
    80005cce:	6194                	ld	a3,0(a1)
    80005cd0:	96b2                	add	a3,a3,a2
    80005cd2:	e194                	sd	a3,0(a1)
    80005cd4:	4589                	li	a1,2
    80005cd6:	14459073          	csrw	sip,a1
    80005cda:	6914                	ld	a3,16(a0)
    80005cdc:	6510                	ld	a2,8(a0)
    80005cde:	610c                	ld	a1,0(a0)
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	30200073          	mret
	...

0000000080005cea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cea:	1141                	addi	sp,sp,-16
    80005cec:	e422                	sd	s0,8(sp)
    80005cee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cf0:	0c0007b7          	lui	a5,0xc000
    80005cf4:	4705                	li	a4,1
    80005cf6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cf8:	c3d8                	sw	a4,4(a5)
}
    80005cfa:	6422                	ld	s0,8(sp)
    80005cfc:	0141                	addi	sp,sp,16
    80005cfe:	8082                	ret

0000000080005d00 <plicinithart>:

void
plicinithart(void)
{
    80005d00:	1141                	addi	sp,sp,-16
    80005d02:	e406                	sd	ra,8(sp)
    80005d04:	e022                	sd	s0,0(sp)
    80005d06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	cf0080e7          	jalr	-784(ra) # 800019f8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d10:	0085171b          	slliw	a4,a0,0x8
    80005d14:	0c0027b7          	lui	a5,0xc002
    80005d18:	97ba                	add	a5,a5,a4
    80005d1a:	40200713          	li	a4,1026
    80005d1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d22:	00d5151b          	slliw	a0,a0,0xd
    80005d26:	0c2017b7          	lui	a5,0xc201
    80005d2a:	97aa                	add	a5,a5,a0
    80005d2c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d30:	60a2                	ld	ra,8(sp)
    80005d32:	6402                	ld	s0,0(sp)
    80005d34:	0141                	addi	sp,sp,16
    80005d36:	8082                	ret

0000000080005d38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d38:	1141                	addi	sp,sp,-16
    80005d3a:	e406                	sd	ra,8(sp)
    80005d3c:	e022                	sd	s0,0(sp)
    80005d3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d40:	ffffc097          	auipc	ra,0xffffc
    80005d44:	cb8080e7          	jalr	-840(ra) # 800019f8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d48:	00d5151b          	slliw	a0,a0,0xd
    80005d4c:	0c2017b7          	lui	a5,0xc201
    80005d50:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d52:	43c8                	lw	a0,4(a5)
    80005d54:	60a2                	ld	ra,8(sp)
    80005d56:	6402                	ld	s0,0(sp)
    80005d58:	0141                	addi	sp,sp,16
    80005d5a:	8082                	ret

0000000080005d5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d5c:	1101                	addi	sp,sp,-32
    80005d5e:	ec06                	sd	ra,24(sp)
    80005d60:	e822                	sd	s0,16(sp)
    80005d62:	e426                	sd	s1,8(sp)
    80005d64:	1000                	addi	s0,sp,32
    80005d66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	c90080e7          	jalr	-880(ra) # 800019f8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d70:	00d5151b          	slliw	a0,a0,0xd
    80005d74:	0c2017b7          	lui	a5,0xc201
    80005d78:	97aa                	add	a5,a5,a0
    80005d7a:	c3c4                	sw	s1,4(a5)
}
    80005d7c:	60e2                	ld	ra,24(sp)
    80005d7e:	6442                	ld	s0,16(sp)
    80005d80:	64a2                	ld	s1,8(sp)
    80005d82:	6105                	addi	sp,sp,32
    80005d84:	8082                	ret

0000000080005d86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d86:	1141                	addi	sp,sp,-16
    80005d88:	e406                	sd	ra,8(sp)
    80005d8a:	e022                	sd	s0,0(sp)
    80005d8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d8e:	479d                	li	a5,7
    80005d90:	04a7cc63          	blt	a5,a0,80005de8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d94:	0001d797          	auipc	a5,0x1d
    80005d98:	3ec78793          	addi	a5,a5,1004 # 80023180 <disk>
    80005d9c:	97aa                	add	a5,a5,a0
    80005d9e:	0187c783          	lbu	a5,24(a5)
    80005da2:	ebb9                	bnez	a5,80005df8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005da4:	00451693          	slli	a3,a0,0x4
    80005da8:	0001d797          	auipc	a5,0x1d
    80005dac:	3d878793          	addi	a5,a5,984 # 80023180 <disk>
    80005db0:	6398                	ld	a4,0(a5)
    80005db2:	9736                	add	a4,a4,a3
    80005db4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005db8:	6398                	ld	a4,0(a5)
    80005dba:	9736                	add	a4,a4,a3
    80005dbc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005dc0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005dc4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005dc8:	97aa                	add	a5,a5,a0
    80005dca:	4705                	li	a4,1
    80005dcc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005dd0:	0001d517          	auipc	a0,0x1d
    80005dd4:	3c850513          	addi	a0,a0,968 # 80023198 <disk+0x18>
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	386080e7          	jalr	902(ra) # 8000215e <wakeup>
}
    80005de0:	60a2                	ld	ra,8(sp)
    80005de2:	6402                	ld	s0,0(sp)
    80005de4:	0141                	addi	sp,sp,16
    80005de6:	8082                	ret
    panic("free_desc 1");
    80005de8:	00004517          	auipc	a0,0x4
    80005dec:	9d850513          	addi	a0,a0,-1576 # 800097c0 <syscalls+0x368>
    80005df0:	ffffa097          	auipc	ra,0xffffa
    80005df4:	750080e7          	jalr	1872(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005df8:	00004517          	auipc	a0,0x4
    80005dfc:	9d850513          	addi	a0,a0,-1576 # 800097d0 <syscalls+0x378>
    80005e00:	ffffa097          	auipc	ra,0xffffa
    80005e04:	740080e7          	jalr	1856(ra) # 80000540 <panic>

0000000080005e08 <virtio_disk_init>:
{
    80005e08:	1101                	addi	sp,sp,-32
    80005e0a:	ec06                	sd	ra,24(sp)
    80005e0c:	e822                	sd	s0,16(sp)
    80005e0e:	e426                	sd	s1,8(sp)
    80005e10:	e04a                	sd	s2,0(sp)
    80005e12:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e14:	00004597          	auipc	a1,0x4
    80005e18:	9cc58593          	addi	a1,a1,-1588 # 800097e0 <syscalls+0x388>
    80005e1c:	0001d517          	auipc	a0,0x1d
    80005e20:	48c50513          	addi	a0,a0,1164 # 800232a8 <disk+0x128>
    80005e24:	ffffb097          	auipc	ra,0xffffb
    80005e28:	d94080e7          	jalr	-620(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e2c:	100017b7          	lui	a5,0x10001
    80005e30:	4398                	lw	a4,0(a5)
    80005e32:	2701                	sext.w	a4,a4
    80005e34:	747277b7          	lui	a5,0x74727
    80005e38:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e3c:	14f71b63          	bne	a4,a5,80005f92 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e40:	100017b7          	lui	a5,0x10001
    80005e44:	43dc                	lw	a5,4(a5)
    80005e46:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e48:	4709                	li	a4,2
    80005e4a:	14e79463          	bne	a5,a4,80005f92 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e4e:	100017b7          	lui	a5,0x10001
    80005e52:	479c                	lw	a5,8(a5)
    80005e54:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e56:	12e79e63          	bne	a5,a4,80005f92 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e5a:	100017b7          	lui	a5,0x10001
    80005e5e:	47d8                	lw	a4,12(a5)
    80005e60:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e62:	554d47b7          	lui	a5,0x554d4
    80005e66:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e6a:	12f71463          	bne	a4,a5,80005f92 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6e:	100017b7          	lui	a5,0x10001
    80005e72:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e76:	4705                	li	a4,1
    80005e78:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7a:	470d                	li	a4,3
    80005e7c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e7e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e80:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e84:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdad3f>
    80005e88:	8f75                	and	a4,a4,a3
    80005e8a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8c:	472d                	li	a4,11
    80005e8e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e90:	5bbc                	lw	a5,112(a5)
    80005e92:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e96:	8ba1                	andi	a5,a5,8
    80005e98:	10078563          	beqz	a5,80005fa2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e9c:	100017b7          	lui	a5,0x10001
    80005ea0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ea4:	43fc                	lw	a5,68(a5)
    80005ea6:	2781                	sext.w	a5,a5
    80005ea8:	10079563          	bnez	a5,80005fb2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eac:	100017b7          	lui	a5,0x10001
    80005eb0:	5bdc                	lw	a5,52(a5)
    80005eb2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005eb4:	10078763          	beqz	a5,80005fc2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005eb8:	471d                	li	a4,7
    80005eba:	10f77c63          	bgeu	a4,a5,80005fd2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005ebe:	ffffb097          	auipc	ra,0xffffb
    80005ec2:	c9a080e7          	jalr	-870(ra) # 80000b58 <kalloc>
    80005ec6:	0001d497          	auipc	s1,0x1d
    80005eca:	2ba48493          	addi	s1,s1,698 # 80023180 <disk>
    80005ece:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005ed0:	ffffb097          	auipc	ra,0xffffb
    80005ed4:	c88080e7          	jalr	-888(ra) # 80000b58 <kalloc>
    80005ed8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005eda:	ffffb097          	auipc	ra,0xffffb
    80005ede:	c7e080e7          	jalr	-898(ra) # 80000b58 <kalloc>
    80005ee2:	87aa                	mv	a5,a0
    80005ee4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005ee6:	6088                	ld	a0,0(s1)
    80005ee8:	cd6d                	beqz	a0,80005fe2 <virtio_disk_init+0x1da>
    80005eea:	0001d717          	auipc	a4,0x1d
    80005eee:	29e73703          	ld	a4,670(a4) # 80023188 <disk+0x8>
    80005ef2:	cb65                	beqz	a4,80005fe2 <virtio_disk_init+0x1da>
    80005ef4:	c7fd                	beqz	a5,80005fe2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005ef6:	6605                	lui	a2,0x1
    80005ef8:	4581                	li	a1,0
    80005efa:	ffffb097          	auipc	ra,0xffffb
    80005efe:	e4a080e7          	jalr	-438(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f02:	0001d497          	auipc	s1,0x1d
    80005f06:	27e48493          	addi	s1,s1,638 # 80023180 <disk>
    80005f0a:	6605                	lui	a2,0x1
    80005f0c:	4581                	li	a1,0
    80005f0e:	6488                	ld	a0,8(s1)
    80005f10:	ffffb097          	auipc	ra,0xffffb
    80005f14:	e34080e7          	jalr	-460(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f18:	6605                	lui	a2,0x1
    80005f1a:	4581                	li	a1,0
    80005f1c:	6888                	ld	a0,16(s1)
    80005f1e:	ffffb097          	auipc	ra,0xffffb
    80005f22:	e26080e7          	jalr	-474(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f26:	100017b7          	lui	a5,0x10001
    80005f2a:	4721                	li	a4,8
    80005f2c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f2e:	4098                	lw	a4,0(s1)
    80005f30:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f34:	40d8                	lw	a4,4(s1)
    80005f36:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f3a:	6498                	ld	a4,8(s1)
    80005f3c:	0007069b          	sext.w	a3,a4
    80005f40:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f44:	9701                	srai	a4,a4,0x20
    80005f46:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f4a:	6898                	ld	a4,16(s1)
    80005f4c:	0007069b          	sext.w	a3,a4
    80005f50:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f54:	9701                	srai	a4,a4,0x20
    80005f56:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f5a:	4705                	li	a4,1
    80005f5c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f5e:	00e48c23          	sb	a4,24(s1)
    80005f62:	00e48ca3          	sb	a4,25(s1)
    80005f66:	00e48d23          	sb	a4,26(s1)
    80005f6a:	00e48da3          	sb	a4,27(s1)
    80005f6e:	00e48e23          	sb	a4,28(s1)
    80005f72:	00e48ea3          	sb	a4,29(s1)
    80005f76:	00e48f23          	sb	a4,30(s1)
    80005f7a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f7e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f82:	0727a823          	sw	s2,112(a5)
}
    80005f86:	60e2                	ld	ra,24(sp)
    80005f88:	6442                	ld	s0,16(sp)
    80005f8a:	64a2                	ld	s1,8(sp)
    80005f8c:	6902                	ld	s2,0(sp)
    80005f8e:	6105                	addi	sp,sp,32
    80005f90:	8082                	ret
    panic("could not find virtio disk");
    80005f92:	00004517          	auipc	a0,0x4
    80005f96:	85e50513          	addi	a0,a0,-1954 # 800097f0 <syscalls+0x398>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	5a6080e7          	jalr	1446(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005fa2:	00004517          	auipc	a0,0x4
    80005fa6:	86e50513          	addi	a0,a0,-1938 # 80009810 <syscalls+0x3b8>
    80005faa:	ffffa097          	auipc	ra,0xffffa
    80005fae:	596080e7          	jalr	1430(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005fb2:	00004517          	auipc	a0,0x4
    80005fb6:	87e50513          	addi	a0,a0,-1922 # 80009830 <syscalls+0x3d8>
    80005fba:	ffffa097          	auipc	ra,0xffffa
    80005fbe:	586080e7          	jalr	1414(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005fc2:	00004517          	auipc	a0,0x4
    80005fc6:	88e50513          	addi	a0,a0,-1906 # 80009850 <syscalls+0x3f8>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	576080e7          	jalr	1398(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005fd2:	00004517          	auipc	a0,0x4
    80005fd6:	89e50513          	addi	a0,a0,-1890 # 80009870 <syscalls+0x418>
    80005fda:	ffffa097          	auipc	ra,0xffffa
    80005fde:	566080e7          	jalr	1382(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005fe2:	00004517          	auipc	a0,0x4
    80005fe6:	8ae50513          	addi	a0,a0,-1874 # 80009890 <syscalls+0x438>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	556080e7          	jalr	1366(ra) # 80000540 <panic>

0000000080005ff2 <virtio_disk_init_bootloader>:
{
    80005ff2:	1101                	addi	sp,sp,-32
    80005ff4:	ec06                	sd	ra,24(sp)
    80005ff6:	e822                	sd	s0,16(sp)
    80005ff8:	e426                	sd	s1,8(sp)
    80005ffa:	e04a                	sd	s2,0(sp)
    80005ffc:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ffe:	00003597          	auipc	a1,0x3
    80006002:	7e258593          	addi	a1,a1,2018 # 800097e0 <syscalls+0x388>
    80006006:	0001d517          	auipc	a0,0x1d
    8000600a:	2a250513          	addi	a0,a0,674 # 800232a8 <disk+0x128>
    8000600e:	ffffb097          	auipc	ra,0xffffb
    80006012:	baa080e7          	jalr	-1110(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006016:	100017b7          	lui	a5,0x10001
    8000601a:	4398                	lw	a4,0(a5)
    8000601c:	2701                	sext.w	a4,a4
    8000601e:	747277b7          	lui	a5,0x74727
    80006022:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006026:	12f71763          	bne	a4,a5,80006154 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000602a:	100017b7          	lui	a5,0x10001
    8000602e:	43dc                	lw	a5,4(a5)
    80006030:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006032:	4709                	li	a4,2
    80006034:	12e79063          	bne	a5,a4,80006154 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006038:	100017b7          	lui	a5,0x10001
    8000603c:	479c                	lw	a5,8(a5)
    8000603e:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006040:	10e79a63          	bne	a5,a4,80006154 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006044:	100017b7          	lui	a5,0x10001
    80006048:	47d8                	lw	a4,12(a5)
    8000604a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000604c:	554d47b7          	lui	a5,0x554d4
    80006050:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006054:	10f71063          	bne	a4,a5,80006154 <virtio_disk_init_bootloader+0x162>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006058:	100017b7          	lui	a5,0x10001
    8000605c:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006060:	4705                	li	a4,1
    80006062:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006064:	470d                	li	a4,3
    80006066:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006068:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000606a:	c7ffe6b7          	lui	a3,0xc7ffe
    8000606e:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdad3f>
    80006072:	8f75                	and	a4,a4,a3
    80006074:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006076:	472d                	li	a4,11
    80006078:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000607a:	5bbc                	lw	a5,112(a5)
    8000607c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006080:	8ba1                	andi	a5,a5,8
    80006082:	c3ed                	beqz	a5,80006164 <virtio_disk_init_bootloader+0x172>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006084:	100017b7          	lui	a5,0x10001
    80006088:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000608c:	43fc                	lw	a5,68(a5)
    8000608e:	2781                	sext.w	a5,a5
    80006090:	e3f5                	bnez	a5,80006174 <virtio_disk_init_bootloader+0x182>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006092:	100017b7          	lui	a5,0x10001
    80006096:	5bdc                	lw	a5,52(a5)
    80006098:	2781                	sext.w	a5,a5
  if(max == 0)
    8000609a:	c7ed                	beqz	a5,80006184 <virtio_disk_init_bootloader+0x192>
  if(max < NUM)
    8000609c:	471d                	li	a4,7
    8000609e:	0ef77b63          	bgeu	a4,a5,80006194 <virtio_disk_init_bootloader+0x1a2>
  disk.desc  = (void*) 0x77000000;
    800060a2:	0001d497          	auipc	s1,0x1d
    800060a6:	0de48493          	addi	s1,s1,222 # 80023180 <disk>
    800060aa:	770007b7          	lui	a5,0x77000
    800060ae:	e09c                	sd	a5,0(s1)
  disk.avail = (void*) 0x77001000;
    800060b0:	770017b7          	lui	a5,0x77001
    800060b4:	e49c                	sd	a5,8(s1)
  disk.used  = (void*) 0x77002000;
    800060b6:	770027b7          	lui	a5,0x77002
    800060ba:	e89c                	sd	a5,16(s1)
  memset(disk.desc, 0, PGSIZE);
    800060bc:	6605                	lui	a2,0x1
    800060be:	4581                	li	a1,0
    800060c0:	77000537          	lui	a0,0x77000
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	c80080e7          	jalr	-896(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060cc:	6605                	lui	a2,0x1
    800060ce:	4581                	li	a1,0
    800060d0:	6488                	ld	a0,8(s1)
    800060d2:	ffffb097          	auipc	ra,0xffffb
    800060d6:	c72080e7          	jalr	-910(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    800060da:	6605                	lui	a2,0x1
    800060dc:	4581                	li	a1,0
    800060de:	6888                	ld	a0,16(s1)
    800060e0:	ffffb097          	auipc	ra,0xffffb
    800060e4:	c64080e7          	jalr	-924(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060e8:	100017b7          	lui	a5,0x10001
    800060ec:	4721                	li	a4,8
    800060ee:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060f0:	4098                	lw	a4,0(s1)
    800060f2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060f6:	40d8                	lw	a4,4(s1)
    800060f8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060fc:	6498                	ld	a4,8(s1)
    800060fe:	0007069b          	sext.w	a3,a4
    80006102:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006106:	9701                	srai	a4,a4,0x20
    80006108:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000610c:	6898                	ld	a4,16(s1)
    8000610e:	0007069b          	sext.w	a3,a4
    80006112:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006116:	9701                	srai	a4,a4,0x20
    80006118:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000611c:	4705                	li	a4,1
    8000611e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006120:	00e48c23          	sb	a4,24(s1)
    80006124:	00e48ca3          	sb	a4,25(s1)
    80006128:	00e48d23          	sb	a4,26(s1)
    8000612c:	00e48da3          	sb	a4,27(s1)
    80006130:	00e48e23          	sb	a4,28(s1)
    80006134:	00e48ea3          	sb	a4,29(s1)
    80006138:	00e48f23          	sb	a4,30(s1)
    8000613c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006140:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006144:	0727a823          	sw	s2,112(a5)
}
    80006148:	60e2                	ld	ra,24(sp)
    8000614a:	6442                	ld	s0,16(sp)
    8000614c:	64a2                	ld	s1,8(sp)
    8000614e:	6902                	ld	s2,0(sp)
    80006150:	6105                	addi	sp,sp,32
    80006152:	8082                	ret
    panic("could not find virtio disk");
    80006154:	00003517          	auipc	a0,0x3
    80006158:	69c50513          	addi	a0,a0,1692 # 800097f0 <syscalls+0x398>
    8000615c:	ffffa097          	auipc	ra,0xffffa
    80006160:	3e4080e7          	jalr	996(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006164:	00003517          	auipc	a0,0x3
    80006168:	6ac50513          	addi	a0,a0,1708 # 80009810 <syscalls+0x3b8>
    8000616c:	ffffa097          	auipc	ra,0xffffa
    80006170:	3d4080e7          	jalr	980(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006174:	00003517          	auipc	a0,0x3
    80006178:	6bc50513          	addi	a0,a0,1724 # 80009830 <syscalls+0x3d8>
    8000617c:	ffffa097          	auipc	ra,0xffffa
    80006180:	3c4080e7          	jalr	964(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006184:	00003517          	auipc	a0,0x3
    80006188:	6cc50513          	addi	a0,a0,1740 # 80009850 <syscalls+0x3f8>
    8000618c:	ffffa097          	auipc	ra,0xffffa
    80006190:	3b4080e7          	jalr	948(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006194:	00003517          	auipc	a0,0x3
    80006198:	6dc50513          	addi	a0,a0,1756 # 80009870 <syscalls+0x418>
    8000619c:	ffffa097          	auipc	ra,0xffffa
    800061a0:	3a4080e7          	jalr	932(ra) # 80000540 <panic>

00000000800061a4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061a4:	7159                	addi	sp,sp,-112
    800061a6:	f486                	sd	ra,104(sp)
    800061a8:	f0a2                	sd	s0,96(sp)
    800061aa:	eca6                	sd	s1,88(sp)
    800061ac:	e8ca                	sd	s2,80(sp)
    800061ae:	e4ce                	sd	s3,72(sp)
    800061b0:	e0d2                	sd	s4,64(sp)
    800061b2:	fc56                	sd	s5,56(sp)
    800061b4:	f85a                	sd	s6,48(sp)
    800061b6:	f45e                	sd	s7,40(sp)
    800061b8:	f062                	sd	s8,32(sp)
    800061ba:	ec66                	sd	s9,24(sp)
    800061bc:	e86a                	sd	s10,16(sp)
    800061be:	1880                	addi	s0,sp,112
    800061c0:	8a2a                	mv	s4,a0
    800061c2:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061c4:	00c52c83          	lw	s9,12(a0)
    800061c8:	001c9c9b          	slliw	s9,s9,0x1
    800061cc:	1c82                	slli	s9,s9,0x20
    800061ce:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061d2:	0001d517          	auipc	a0,0x1d
    800061d6:	0d650513          	addi	a0,a0,214 # 800232a8 <disk+0x128>
    800061da:	ffffb097          	auipc	ra,0xffffb
    800061de:	a6e080e7          	jalr	-1426(ra) # 80000c48 <acquire>
  for(int i = 0; i < 3; i++){
    800061e2:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800061e4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061e6:	0001db17          	auipc	s6,0x1d
    800061ea:	f9ab0b13          	addi	s6,s6,-102 # 80023180 <disk>
  for(int i = 0; i < 3; i++){
    800061ee:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061f0:	0001dc17          	auipc	s8,0x1d
    800061f4:	0b8c0c13          	addi	s8,s8,184 # 800232a8 <disk+0x128>
    800061f8:	a095                	j	8000625c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800061fa:	00fb0733          	add	a4,s6,a5
    800061fe:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006202:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006204:	0207c563          	bltz	a5,8000622e <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006208:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    8000620a:	0591                	addi	a1,a1,4
    8000620c:	05560d63          	beq	a2,s5,80006266 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006210:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006212:	0001d717          	auipc	a4,0x1d
    80006216:	f6e70713          	addi	a4,a4,-146 # 80023180 <disk>
    8000621a:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000621c:	01874683          	lbu	a3,24(a4)
    80006220:	fee9                	bnez	a3,800061fa <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006222:	2785                	addiw	a5,a5,1
    80006224:	0705                	addi	a4,a4,1
    80006226:	fe979be3          	bne	a5,s1,8000621c <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    8000622a:	57fd                	li	a5,-1
    8000622c:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000622e:	00c05e63          	blez	a2,8000624a <virtio_disk_rw+0xa6>
    80006232:	060a                	slli	a2,a2,0x2
    80006234:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006238:	0009a503          	lw	a0,0(s3)
    8000623c:	00000097          	auipc	ra,0x0
    80006240:	b4a080e7          	jalr	-1206(ra) # 80005d86 <free_desc>
      for(int j = 0; j < i; j++)
    80006244:	0991                	addi	s3,s3,4
    80006246:	ffa999e3          	bne	s3,s10,80006238 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000624a:	85e2                	mv	a1,s8
    8000624c:	0001d517          	auipc	a0,0x1d
    80006250:	f4c50513          	addi	a0,a0,-180 # 80023198 <disk+0x18>
    80006254:	ffffc097          	auipc	ra,0xffffc
    80006258:	ea6080e7          	jalr	-346(ra) # 800020fa <sleep>
  for(int i = 0; i < 3; i++){
    8000625c:	f9040993          	addi	s3,s0,-112
{
    80006260:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006262:	864a                	mv	a2,s2
    80006264:	b775                	j	80006210 <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006266:	f9042503          	lw	a0,-112(s0)
    8000626a:	00a50713          	addi	a4,a0,10
    8000626e:	0712                	slli	a4,a4,0x4

  if(write)
    80006270:	0001d797          	auipc	a5,0x1d
    80006274:	f1078793          	addi	a5,a5,-240 # 80023180 <disk>
    80006278:	00e786b3          	add	a3,a5,a4
    8000627c:	01703633          	snez	a2,s7
    80006280:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006282:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006286:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000628a:	f6070613          	addi	a2,a4,-160
    8000628e:	6394                	ld	a3,0(a5)
    80006290:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006292:	00870593          	addi	a1,a4,8
    80006296:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006298:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000629a:	0007b803          	ld	a6,0(a5)
    8000629e:	9642                	add	a2,a2,a6
    800062a0:	46c1                	li	a3,16
    800062a2:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062a4:	4585                	li	a1,1
    800062a6:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800062aa:	f9442683          	lw	a3,-108(s0)
    800062ae:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062b2:	0692                	slli	a3,a3,0x4
    800062b4:	9836                	add	a6,a6,a3
    800062b6:	058a0613          	addi	a2,s4,88
    800062ba:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800062be:	0007b803          	ld	a6,0(a5)
    800062c2:	96c2                	add	a3,a3,a6
    800062c4:	40000613          	li	a2,1024
    800062c8:	c690                	sw	a2,8(a3)
  if(write)
    800062ca:	001bb613          	seqz	a2,s7
    800062ce:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062d2:	00166613          	ori	a2,a2,1
    800062d6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062da:	f9842603          	lw	a2,-104(s0)
    800062de:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062e2:	00250693          	addi	a3,a0,2
    800062e6:	0692                	slli	a3,a3,0x4
    800062e8:	96be                	add	a3,a3,a5
    800062ea:	58fd                	li	a7,-1
    800062ec:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062f0:	0612                	slli	a2,a2,0x4
    800062f2:	9832                	add	a6,a6,a2
    800062f4:	f9070713          	addi	a4,a4,-112
    800062f8:	973e                	add	a4,a4,a5
    800062fa:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800062fe:	6398                	ld	a4,0(a5)
    80006300:	9732                	add	a4,a4,a2
    80006302:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006304:	4609                	li	a2,2
    80006306:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    8000630a:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000630e:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006312:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006316:	6794                	ld	a3,8(a5)
    80006318:	0026d703          	lhu	a4,2(a3)
    8000631c:	8b1d                	andi	a4,a4,7
    8000631e:	0706                	slli	a4,a4,0x1
    80006320:	96ba                	add	a3,a3,a4
    80006322:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006326:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000632a:	6798                	ld	a4,8(a5)
    8000632c:	00275783          	lhu	a5,2(a4)
    80006330:	2785                	addiw	a5,a5,1
    80006332:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006336:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000633a:	100017b7          	lui	a5,0x10001
    8000633e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006342:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006346:	0001d917          	auipc	s2,0x1d
    8000634a:	f6290913          	addi	s2,s2,-158 # 800232a8 <disk+0x128>
  while(b->disk == 1) {
    8000634e:	4485                	li	s1,1
    80006350:	00b79c63          	bne	a5,a1,80006368 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006354:	85ca                	mv	a1,s2
    80006356:	8552                	mv	a0,s4
    80006358:	ffffc097          	auipc	ra,0xffffc
    8000635c:	da2080e7          	jalr	-606(ra) # 800020fa <sleep>
  while(b->disk == 1) {
    80006360:	004a2783          	lw	a5,4(s4)
    80006364:	fe9788e3          	beq	a5,s1,80006354 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006368:	f9042903          	lw	s2,-112(s0)
    8000636c:	00290713          	addi	a4,s2,2
    80006370:	0712                	slli	a4,a4,0x4
    80006372:	0001d797          	auipc	a5,0x1d
    80006376:	e0e78793          	addi	a5,a5,-498 # 80023180 <disk>
    8000637a:	97ba                	add	a5,a5,a4
    8000637c:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006380:	0001d997          	auipc	s3,0x1d
    80006384:	e0098993          	addi	s3,s3,-512 # 80023180 <disk>
    80006388:	00491713          	slli	a4,s2,0x4
    8000638c:	0009b783          	ld	a5,0(s3)
    80006390:	97ba                	add	a5,a5,a4
    80006392:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006396:	854a                	mv	a0,s2
    80006398:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000639c:	00000097          	auipc	ra,0x0
    800063a0:	9ea080e7          	jalr	-1558(ra) # 80005d86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063a4:	8885                	andi	s1,s1,1
    800063a6:	f0ed                	bnez	s1,80006388 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063a8:	0001d517          	auipc	a0,0x1d
    800063ac:	f0050513          	addi	a0,a0,-256 # 800232a8 <disk+0x128>
    800063b0:	ffffb097          	auipc	ra,0xffffb
    800063b4:	94c080e7          	jalr	-1716(ra) # 80000cfc <release>
}
    800063b8:	70a6                	ld	ra,104(sp)
    800063ba:	7406                	ld	s0,96(sp)
    800063bc:	64e6                	ld	s1,88(sp)
    800063be:	6946                	ld	s2,80(sp)
    800063c0:	69a6                	ld	s3,72(sp)
    800063c2:	6a06                	ld	s4,64(sp)
    800063c4:	7ae2                	ld	s5,56(sp)
    800063c6:	7b42                	ld	s6,48(sp)
    800063c8:	7ba2                	ld	s7,40(sp)
    800063ca:	7c02                	ld	s8,32(sp)
    800063cc:	6ce2                	ld	s9,24(sp)
    800063ce:	6d42                	ld	s10,16(sp)
    800063d0:	6165                	addi	sp,sp,112
    800063d2:	8082                	ret

00000000800063d4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063d4:	1101                	addi	sp,sp,-32
    800063d6:	ec06                	sd	ra,24(sp)
    800063d8:	e822                	sd	s0,16(sp)
    800063da:	e426                	sd	s1,8(sp)
    800063dc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063de:	0001d497          	auipc	s1,0x1d
    800063e2:	da248493          	addi	s1,s1,-606 # 80023180 <disk>
    800063e6:	0001d517          	auipc	a0,0x1d
    800063ea:	ec250513          	addi	a0,a0,-318 # 800232a8 <disk+0x128>
    800063ee:	ffffb097          	auipc	ra,0xffffb
    800063f2:	85a080e7          	jalr	-1958(ra) # 80000c48 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063f6:	10001737          	lui	a4,0x10001
    800063fa:	533c                	lw	a5,96(a4)
    800063fc:	8b8d                	andi	a5,a5,3
    800063fe:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006400:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006404:	689c                	ld	a5,16(s1)
    80006406:	0204d703          	lhu	a4,32(s1)
    8000640a:	0027d783          	lhu	a5,2(a5)
    8000640e:	04f70863          	beq	a4,a5,8000645e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006412:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006416:	6898                	ld	a4,16(s1)
    80006418:	0204d783          	lhu	a5,32(s1)
    8000641c:	8b9d                	andi	a5,a5,7
    8000641e:	078e                	slli	a5,a5,0x3
    80006420:	97ba                	add	a5,a5,a4
    80006422:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006424:	00278713          	addi	a4,a5,2
    80006428:	0712                	slli	a4,a4,0x4
    8000642a:	9726                	add	a4,a4,s1
    8000642c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006430:	e721                	bnez	a4,80006478 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006432:	0789                	addi	a5,a5,2
    80006434:	0792                	slli	a5,a5,0x4
    80006436:	97a6                	add	a5,a5,s1
    80006438:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000643a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000643e:	ffffc097          	auipc	ra,0xffffc
    80006442:	d20080e7          	jalr	-736(ra) # 8000215e <wakeup>

    disk.used_idx += 1;
    80006446:	0204d783          	lhu	a5,32(s1)
    8000644a:	2785                	addiw	a5,a5,1
    8000644c:	17c2                	slli	a5,a5,0x30
    8000644e:	93c1                	srli	a5,a5,0x30
    80006450:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006454:	6898                	ld	a4,16(s1)
    80006456:	00275703          	lhu	a4,2(a4)
    8000645a:	faf71ce3          	bne	a4,a5,80006412 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000645e:	0001d517          	auipc	a0,0x1d
    80006462:	e4a50513          	addi	a0,a0,-438 # 800232a8 <disk+0x128>
    80006466:	ffffb097          	auipc	ra,0xffffb
    8000646a:	896080e7          	jalr	-1898(ra) # 80000cfc <release>
}
    8000646e:	60e2                	ld	ra,24(sp)
    80006470:	6442                	ld	s0,16(sp)
    80006472:	64a2                	ld	s1,8(sp)
    80006474:	6105                	addi	sp,sp,32
    80006476:	8082                	ret
      panic("virtio_disk_intr status");
    80006478:	00003517          	auipc	a0,0x3
    8000647c:	43050513          	addi	a0,a0,1072 # 800098a8 <syscalls+0x450>
    80006480:	ffffa097          	auipc	ra,0xffffa
    80006484:	0c0080e7          	jalr	192(ra) # 80000540 <panic>

0000000080006488 <ramdiskinit>:
/* TODO: find the location of the QEMU ramdisk. */
#define RAMDISK 0x84000000

void
ramdiskinit(void)
{
    80006488:	1141                	addi	sp,sp,-16
    8000648a:	e422                	sd	s0,8(sp)
    8000648c:	0800                	addi	s0,sp,16
}
    8000648e:	6422                	ld	s0,8(sp)
    80006490:	0141                	addi	sp,sp,16
    80006492:	8082                	ret

0000000080006494 <ramdiskrw>:

// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
ramdiskrw(struct buf *b)
{
    80006494:	1101                	addi	sp,sp,-32
    80006496:	ec06                	sd	ra,24(sp)
    80006498:	e822                	sd	s0,16(sp)
    8000649a:	e426                	sd	s1,8(sp)
    8000649c:	1000                	addi	s0,sp,32
    panic("ramdiskrw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("ramdiskrw: nothing to do");
#endif

  if(b->blockno >= FSSIZE)
    8000649e:	454c                	lw	a1,12(a0)
    800064a0:	7cf00793          	li	a5,1999
    800064a4:	02b7ea63          	bltu	a5,a1,800064d8 <ramdiskrw+0x44>
    800064a8:	84aa                	mv	s1,a0
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
    800064aa:	00a5959b          	slliw	a1,a1,0xa
    800064ae:	1582                	slli	a1,a1,0x20
    800064b0:	9181                	srli	a1,a1,0x20
  char *addr = (char *)RAMDISK + diskaddr;

  // read from the location
  memmove(b->data, addr, BSIZE);
    800064b2:	40000613          	li	a2,1024
    800064b6:	02100793          	li	a5,33
    800064ba:	07ea                	slli	a5,a5,0x1a
    800064bc:	95be                	add	a1,a1,a5
    800064be:	05850513          	addi	a0,a0,88
    800064c2:	ffffb097          	auipc	ra,0xffffb
    800064c6:	8de080e7          	jalr	-1826(ra) # 80000da0 <memmove>
  b->valid = 1;
    800064ca:	4785                	li	a5,1
    800064cc:	c09c                	sw	a5,0(s1)
    // read
    memmove(b->data, addr, BSIZE);
    b->flags |= B_VALID;
  }
#endif
}
    800064ce:	60e2                	ld	ra,24(sp)
    800064d0:	6442                	ld	s0,16(sp)
    800064d2:	64a2                	ld	s1,8(sp)
    800064d4:	6105                	addi	sp,sp,32
    800064d6:	8082                	ret
    panic("ramdiskrw: blockno too big");
    800064d8:	00003517          	auipc	a0,0x3
    800064dc:	3e850513          	addi	a0,a0,1000 # 800098c0 <syscalls+0x468>
    800064e0:	ffffa097          	auipc	ra,0xffffa
    800064e4:	060080e7          	jalr	96(ra) # 80000540 <panic>

00000000800064e8 <dump_hex>:
#include "fs.h"
#include "buf.h"
#include <stddef.h>

/* Acknowledgement: https://gist.github.com/ccbrown/9722406 */
void dump_hex(const void* data, size_t size) {
    800064e8:	7119                	addi	sp,sp,-128
    800064ea:	fc86                	sd	ra,120(sp)
    800064ec:	f8a2                	sd	s0,112(sp)
    800064ee:	f4a6                	sd	s1,104(sp)
    800064f0:	f0ca                	sd	s2,96(sp)
    800064f2:	ecce                	sd	s3,88(sp)
    800064f4:	e8d2                	sd	s4,80(sp)
    800064f6:	e4d6                	sd	s5,72(sp)
    800064f8:	e0da                	sd	s6,64(sp)
    800064fa:	fc5e                	sd	s7,56(sp)
    800064fc:	f862                	sd	s8,48(sp)
    800064fe:	f466                	sd	s9,40(sp)
    80006500:	0100                	addi	s0,sp,128
	char ascii[17];
	size_t i, j;
	ascii[16] = '\0';
    80006502:	f8040c23          	sb	zero,-104(s0)
	for (i = 0; i < size; ++i) {
    80006506:	c5e1                	beqz	a1,800065ce <dump_hex+0xe6>
    80006508:	89ae                	mv	s3,a1
    8000650a:	892a                	mv	s2,a0
    8000650c:	4481                	li	s1,0
		printf("%x ", ((unsigned char*)data)[i]);
    8000650e:	00003a97          	auipc	s5,0x3
    80006512:	3d2a8a93          	addi	s5,s5,978 # 800098e0 <syscalls+0x488>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    80006516:	05e00a13          	li	s4,94
			ascii[i % 16] = ((unsigned char*)data)[i];
		} else {
			ascii[i % 16] = '.';
    8000651a:	02e00b13          	li	s6,46
		}
		if ((i+1) % 8 == 0 || i+1 == size) {
			printf(" ");
			if ((i+1) % 16 == 0) {
				printf("|  %s \n", ascii);
    8000651e:	00003c17          	auipc	s8,0x3
    80006522:	3d2c0c13          	addi	s8,s8,978 # 800098f0 <syscalls+0x498>
			printf(" ");
    80006526:	00003b97          	auipc	s7,0x3
    8000652a:	3c2b8b93          	addi	s7,s7,962 # 800098e8 <syscalls+0x490>
    8000652e:	a839                	j	8000654c <dump_hex+0x64>
			ascii[i % 16] = '.';
    80006530:	00f4f793          	andi	a5,s1,15
    80006534:	fa078793          	addi	a5,a5,-96
    80006538:	97a2                	add	a5,a5,s0
    8000653a:	ff678423          	sb	s6,-24(a5)
		if ((i+1) % 8 == 0 || i+1 == size) {
    8000653e:	0485                	addi	s1,s1,1
    80006540:	0074f793          	andi	a5,s1,7
    80006544:	cb9d                	beqz	a5,8000657a <dump_hex+0x92>
    80006546:	0b348a63          	beq	s1,s3,800065fa <dump_hex+0x112>
	for (i = 0; i < size; ++i) {
    8000654a:	0905                	addi	s2,s2,1
		printf("%x ", ((unsigned char*)data)[i]);
    8000654c:	00094583          	lbu	a1,0(s2)
    80006550:	8556                	mv	a0,s5
    80006552:	ffffa097          	auipc	ra,0xffffa
    80006556:	038080e7          	jalr	56(ra) # 8000058a <printf>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    8000655a:	00094703          	lbu	a4,0(s2)
    8000655e:	fe07079b          	addiw	a5,a4,-32
    80006562:	0ff7f793          	zext.b	a5,a5
    80006566:	fcfa65e3          	bltu	s4,a5,80006530 <dump_hex+0x48>
			ascii[i % 16] = ((unsigned char*)data)[i];
    8000656a:	00f4f793          	andi	a5,s1,15
    8000656e:	fa078793          	addi	a5,a5,-96
    80006572:	97a2                	add	a5,a5,s0
    80006574:	fee78423          	sb	a4,-24(a5)
    80006578:	b7d9                	j	8000653e <dump_hex+0x56>
			printf(" ");
    8000657a:	855e                	mv	a0,s7
    8000657c:	ffffa097          	auipc	ra,0xffffa
    80006580:	00e080e7          	jalr	14(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    80006584:	00f4fc93          	andi	s9,s1,15
    80006588:	080c8263          	beqz	s9,8000660c <dump_hex+0x124>
			} else if (i+1 == size) {
    8000658c:	fb349fe3          	bne	s1,s3,8000654a <dump_hex+0x62>
				ascii[(i+1) % 16] = '\0';
    80006590:	fa0c8793          	addi	a5,s9,-96
    80006594:	97a2                	add	a5,a5,s0
    80006596:	fe078423          	sb	zero,-24(a5)
				if ((i+1) % 16 <= 8) {
    8000659a:	47a1                	li	a5,8
    8000659c:	0597f663          	bgeu	a5,s9,800065e8 <dump_hex+0x100>
					printf(" ");
				}
				for (j = (i+1) % 16; j < 16; ++j) {
					printf("   ");
    800065a0:	00003917          	auipc	s2,0x3
    800065a4:	35890913          	addi	s2,s2,856 # 800098f8 <syscalls+0x4a0>
				for (j = (i+1) % 16; j < 16; ++j) {
    800065a8:	44bd                	li	s1,15
					printf("   ");
    800065aa:	854a                	mv	a0,s2
    800065ac:	ffffa097          	auipc	ra,0xffffa
    800065b0:	fde080e7          	jalr	-34(ra) # 8000058a <printf>
				for (j = (i+1) % 16; j < 16; ++j) {
    800065b4:	0c85                	addi	s9,s9,1
    800065b6:	ff94fae3          	bgeu	s1,s9,800065aa <dump_hex+0xc2>
				}
				printf("|  %s \n", ascii);
    800065ba:	f8840593          	addi	a1,s0,-120
    800065be:	00003517          	auipc	a0,0x3
    800065c2:	33250513          	addi	a0,a0,818 # 800098f0 <syscalls+0x498>
    800065c6:	ffffa097          	auipc	ra,0xffffa
    800065ca:	fc4080e7          	jalr	-60(ra) # 8000058a <printf>
			}
		}
	}
    800065ce:	70e6                	ld	ra,120(sp)
    800065d0:	7446                	ld	s0,112(sp)
    800065d2:	74a6                	ld	s1,104(sp)
    800065d4:	7906                	ld	s2,96(sp)
    800065d6:	69e6                	ld	s3,88(sp)
    800065d8:	6a46                	ld	s4,80(sp)
    800065da:	6aa6                	ld	s5,72(sp)
    800065dc:	6b06                	ld	s6,64(sp)
    800065de:	7be2                	ld	s7,56(sp)
    800065e0:	7c42                	ld	s8,48(sp)
    800065e2:	7ca2                	ld	s9,40(sp)
    800065e4:	6109                	addi	sp,sp,128
    800065e6:	8082                	ret
					printf(" ");
    800065e8:	00003517          	auipc	a0,0x3
    800065ec:	30050513          	addi	a0,a0,768 # 800098e8 <syscalls+0x490>
    800065f0:	ffffa097          	auipc	ra,0xffffa
    800065f4:	f9a080e7          	jalr	-102(ra) # 8000058a <printf>
    800065f8:	b765                	j	800065a0 <dump_hex+0xb8>
			printf(" ");
    800065fa:	855e                	mv	a0,s7
    800065fc:	ffffa097          	auipc	ra,0xffffa
    80006600:	f8e080e7          	jalr	-114(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    80006604:	00f9fc93          	andi	s9,s3,15
    80006608:	f80c94e3          	bnez	s9,80006590 <dump_hex+0xa8>
				printf("|  %s \n", ascii);
    8000660c:	f8840593          	addi	a1,s0,-120
    80006610:	8562                	mv	a0,s8
    80006612:	ffffa097          	auipc	ra,0xffffa
    80006616:	f78080e7          	jalr	-136(ra) # 8000058a <printf>
	for (i = 0; i < size; ++i) {
    8000661a:	fb348ae3          	beq	s1,s3,800065ce <dump_hex+0xe6>
    8000661e:	0905                	addi	s2,s2,1
    80006620:	b735                	j	8000654c <dump_hex+0x64>

0000000080006622 <get_vm_privileged_register>:
    pagetable_t og_pagetable;
};

struct vm_virtual_state vm;

struct vm_reg *get_vm_privileged_register(uint32 reg, struct vm_virtual_state *vm) {
    80006622:	1141                	addi	sp,sp,-16
    80006624:	e422                	sd	s0,8(sp)
    80006626:	0800                	addi	s0,sp,16
    switch (reg) {
    80006628:	18000713          	li	a4,384
    8000662c:	1ae50863          	beq	a0,a4,800067dc <get_vm_privileged_register+0x1ba>
    80006630:	87aa                	mv	a5,a0
    80006632:	08a76a63          	bltu	a4,a0,800066c6 <get_vm_privileged_register+0xa4>
    80006636:	14400713          	li	a4,324
    8000663a:	20a76863          	bltu	a4,a0,8000684a <get_vm_privileged_register+0x228>
    8000663e:	0ff00713          	li	a4,255
    80006642:	02a77663          	bgeu	a4,a0,8000666e <get_vm_privileged_register+0x4c>
    80006646:	f005079b          	addiw	a5,a0,-256
    8000664a:	0007869b          	sext.w	a3,a5
    8000664e:	04400713          	li	a4,68
    80006652:	20d76263          	bltu	a4,a3,80006856 <get_vm_privileged_register+0x234>
    80006656:	02079713          	slli	a4,a5,0x20
    8000665a:	01e75793          	srli	a5,a4,0x1e
    8000665e:	00003717          	auipc	a4,0x3
    80006662:	29e70713          	addi	a4,a4,670 # 800098fc <syscalls+0x4a4>
    80006666:	97ba                	add	a5,a5,a4
    80006668:	439c                	lw	a5,0(a5)
    8000666a:	97ba                	add	a5,a5,a4
    8000666c:	8782                	jr	a5
    8000666e:	04400713          	li	a4,68
    80006672:	1ca76e63          	bltu	a4,a0,8000684e <get_vm_privileged_register+0x22c>
    80006676:	03f00713          	li	a4,63
    8000667a:	02a77563          	bgeu	a4,a0,800066a4 <get_vm_privileged_register+0x82>
    8000667e:	fc05079b          	addiw	a5,a0,-64
    80006682:	0007869b          	sext.w	a3,a5
    80006686:	4711                	li	a4,4
    80006688:	1cd76963          	bltu	a4,a3,8000685a <get_vm_privileged_register+0x238>
    8000668c:	02079713          	slli	a4,a5,0x20
    80006690:	01e75793          	srli	a5,a4,0x1e
    80006694:	00003717          	auipc	a4,0x3
    80006698:	37c70713          	addi	a4,a4,892 # 80009a10 <syscalls+0x5b8>
    8000669c:	97ba                	add	a5,a5,a4
    8000669e:	439c                	lw	a5,0(a5)
    800066a0:	97ba                	add	a5,a5,a4
    800066a2:	8782                	jr	a5
    800066a4:	4711                	li	a4,4
        // User trap setup
        case 0x0000:
            return &vm->ustatus;
        case 0x0004:
            return &vm->uie;
    800066a6:	01058513          	addi	a0,a1,16
    switch (reg) {
    800066aa:	00e78763          	beq	a5,a4,800066b8 <get_vm_privileged_register+0x96>
    800066ae:	4715                	li	a4,5
        case 0x0005:
            return &vm->utvec;
    800066b0:	02058513          	addi	a0,a1,32
    switch (reg) {
    800066b4:	00e79563          	bne	a5,a4,800066be <get_vm_privileged_register+0x9c>
        default:
            break;
    }

    return (struct vm_reg *) 0;
}
    800066b8:	6422                	ld	s0,8(sp)
    800066ba:	0141                	addi	sp,sp,16
    800066bc:	8082                	ret
            return &vm->ustatus;
    800066be:	852e                	mv	a0,a1
    switch (reg) {
    800066c0:	dfe5                	beqz	a5,800066b8 <get_vm_privileged_register+0x96>
    800066c2:	4501                	li	a0,0
    800066c4:	bfd5                	j	800066b8 <get_vm_privileged_register+0x96>
    800066c6:	34400713          	li	a4,836
    800066ca:	02a76b63          	bltu	a4,a0,80006700 <get_vm_privileged_register+0xde>
    800066ce:	2ff00713          	li	a4,767
    800066d2:	4501                	li	a0,0
    800066d4:	fef772e3          	bgeu	a4,a5,800066b8 <get_vm_privileged_register+0x96>
    800066d8:	d007879b          	addiw	a5,a5,-768
    800066dc:	0007869b          	sext.w	a3,a5
    800066e0:	04400713          	li	a4,68
    800066e4:	16d76763          	bltu	a4,a3,80006852 <get_vm_privileged_register+0x230>
    800066e8:	02079713          	slli	a4,a5,0x20
    800066ec:	01e75793          	srli	a5,a4,0x1e
    800066f0:	00003717          	auipc	a4,0x3
    800066f4:	33470713          	addi	a4,a4,820 # 80009a24 <syscalls+0x5cc>
    800066f8:	97ba                	add	a5,a5,a4
    800066fa:	439c                	lw	a5,0(a5)
    800066fc:	97ba                	add	a5,a5,a4
    800066fe:	8782                	jr	a5
    80006700:	6705                	lui	a4,0x1
    80006702:	f1270713          	addi	a4,a4,-238 # f12 <_entry-0x7ffff0ee>
    80006706:	0ce50e63          	beq	a0,a4,800067e2 <get_vm_privileged_register+0x1c0>
    8000670a:	6705                	lui	a4,0x1
    8000670c:	f1270713          	addi	a4,a4,-238 # f12 <_entry-0x7ffff0ee>
    80006710:	02a77263          	bgeu	a4,a0,80006734 <get_vm_privileged_register+0x112>
    80006714:	6705                	lui	a4,0x1
    80006716:	f1370713          	addi	a4,a4,-237 # f13 <_entry-0x7ffff0ed>
            return &vm->mimpid;
    8000671a:	16058513          	addi	a0,a1,352
    switch (reg) {
    8000671e:	f8e78de3          	beq	a5,a4,800066b8 <get_vm_privileged_register+0x96>
    80006722:	6705                	lui	a4,0x1
    80006724:	f1470713          	addi	a4,a4,-236 # f14 <_entry-0x7ffff0ec>
            return &vm->mhartid;
    80006728:	17058513          	addi	a0,a1,368
    switch (reg) {
    8000672c:	f8e786e3          	beq	a5,a4,800066b8 <get_vm_privileged_register+0x96>
    80006730:	4501                	li	a0,0
    80006732:	b759                	j	800066b8 <get_vm_privileged_register+0x96>
    80006734:	3ef00713          	li	a4,1007
    80006738:	02a76963          	bltu	a4,a0,8000676a <get_vm_privileged_register+0x148>
    8000673c:	3af00713          	li	a4,943
    80006740:	0ea76c63          	bltu	a4,a0,80006838 <get_vm_privileged_register+0x216>
    80006744:	c605071b          	addiw	a4,a0,-928
    80006748:	0007061b          	sext.w	a2,a4
    8000674c:	46bd                	li	a3,15
    8000674e:	10c6e863          	bltu	a3,a2,8000685e <get_vm_privileged_register+0x23c>
            if (reg == 0x03a0) // Enable PMP only using pmpcfg0 register to avoid crashing
    80006752:	3a000693          	li	a3,928
    80006756:	0cd50d63          	beq	a0,a3,80006830 <get_vm_privileged_register+0x20e>
            return &vm->pmpcfg[reg - 0x03a0];
    8000675a:	02071793          	slli	a5,a4,0x20
    8000675e:	01c7d513          	srli	a0,a5,0x1c
    80006762:	24050513          	addi	a0,a0,576
    80006766:	952e                	add	a0,a0,a1
    80006768:	bf81                	j	800066b8 <get_vm_privileged_register+0x96>
    switch (reg) {
    8000676a:	6705                	lui	a4,0x1
    8000676c:	f1170713          	addi	a4,a4,-239 # f11 <_entry-0x7ffff0ef>
            return &vm->mvendorid;
    80006770:	14058513          	addi	a0,a1,320
    switch (reg) {
    80006774:	f4e782e3          	beq	a5,a4,800066b8 <get_vm_privileged_register+0x96>
    80006778:	4501                	li	a0,0
    8000677a:	bf3d                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->uscratch;
    8000677c:	03058513          	addi	a0,a1,48
    80006780:	bf25                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->uepc;
    80006782:	04058513          	addi	a0,a1,64
    80006786:	bf0d                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->ucause;
    80006788:	05058513          	addi	a0,a1,80
    8000678c:	b735                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->utval;
    8000678e:	06058513          	addi	a0,a1,96
    80006792:	b71d                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->uip;
    80006794:	07058513          	addi	a0,a1,112
    80006798:	b705                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->sstatus;
    8000679a:	08058513          	addi	a0,a1,128
    8000679e:	bf29                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->sedeleg;
    800067a0:	09058513          	addi	a0,a1,144
    800067a4:	bf11                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->sideleg;
    800067a6:	0a058513          	addi	a0,a1,160
    800067aa:	b739                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->sie;
    800067ac:	0b058513          	addi	a0,a1,176
    800067b0:	b721                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->stvec;
    800067b2:	0c058513          	addi	a0,a1,192
    800067b6:	b709                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->scounteren;
    800067b8:	0d058513          	addi	a0,a1,208
    800067bc:	bdf5                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->sscratch;
    800067be:	0e058513          	addi	a0,a1,224
    800067c2:	bddd                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->sepc;
    800067c4:	0f058513          	addi	a0,a1,240
    800067c8:	bdc5                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->scause;
    800067ca:	10058513          	addi	a0,a1,256
    800067ce:	b5ed                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->stval;
    800067d0:	11058513          	addi	a0,a1,272
    800067d4:	b5d5                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->sip;
    800067d6:	12058513          	addi	a0,a1,288
    800067da:	bdf9                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->satp;
    800067dc:	13058513          	addi	a0,a1,304
    800067e0:	bde1                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->marchid;
    800067e2:	15058513          	addi	a0,a1,336
    800067e6:	bdc9                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->mstatus;
    800067e8:	18058513          	addi	a0,a1,384
    800067ec:	b5f1                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->misa;
    800067ee:	19058513          	addi	a0,a1,400
    800067f2:	b5d9                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->medeleg;
    800067f4:	1a058513          	addi	a0,a1,416
    800067f8:	b5c1                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->mideleg;
    800067fa:	1b058513          	addi	a0,a1,432
    800067fe:	bd6d                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->mie;
    80006800:	1c058513          	addi	a0,a1,448
    80006804:	bd55                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->mtvec;
    80006806:	1d058513          	addi	a0,a1,464
    8000680a:	b57d                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->mcounteren;
    8000680c:	1e058513          	addi	a0,a1,480
    80006810:	b565                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->mscratch;
    80006812:	1f058513          	addi	a0,a1,496
    80006816:	b54d                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->mepc;
    80006818:	20058513          	addi	a0,a1,512
    8000681c:	bd71                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->mcause;
    8000681e:	21058513          	addi	a0,a1,528
    80006822:	bd59                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->mtval;
    80006824:	22058513          	addi	a0,a1,544
    80006828:	bd41                	j	800066b8 <get_vm_privileged_register+0x96>
            return &vm->mip;
    8000682a:	23058513          	addi	a0,a1,560
    8000682e:	b569                	j	800066b8 <get_vm_privileged_register+0x96>
                vm->pmp_setup = true;
    80006830:	4785                	li	a5,1
    80006832:	74f58423          	sb	a5,1864(a1)
    80006836:	b715                	j	8000675a <get_vm_privileged_register+0x138>
            return &vm->pmpaddr[reg - 0x03b0];
    80006838:	c845079b          	addiw	a5,a0,-892
    8000683c:	02079713          	slli	a4,a5,0x20
    80006840:	01c75793          	srli	a5,a4,0x1c
    80006844:	00f58533          	add	a0,a1,a5
    80006848:	bd85                	j	800066b8 <get_vm_privileged_register+0x96>
    switch (reg) {
    8000684a:	4501                	li	a0,0
    8000684c:	b5b5                	j	800066b8 <get_vm_privileged_register+0x96>
    8000684e:	4501                	li	a0,0
    80006850:	b5a5                	j	800066b8 <get_vm_privileged_register+0x96>
    80006852:	4501                	li	a0,0
    80006854:	b595                	j	800066b8 <get_vm_privileged_register+0x96>
    80006856:	4501                	li	a0,0
    80006858:	b585                	j	800066b8 <get_vm_privileged_register+0x96>
    8000685a:	4501                	li	a0,0
    8000685c:	bdb1                	j	800066b8 <get_vm_privileged_register+0x96>
    8000685e:	4501                	li	a0,0
    80006860:	bda1                	j	800066b8 <get_vm_privileged_register+0x96>

0000000080006862 <get_vm_trapframe_register>:

uint64 *get_vm_trapframe_register(uint32 reg, struct trapframe *tf) {
    80006862:	1141                	addi	sp,sp,-16
    80006864:	e422                	sd	s0,8(sp)
    80006866:	0800                	addi	s0,sp,16
    return (uint64 *)((reg - 1) * 8 + (uint64)&tf->ra); // reg == 1 is tf->ra
    80006868:	fff5079b          	addiw	a5,a0,-1
    8000686c:	0037979b          	slliw	a5,a5,0x3
    80006870:	1782                	slli	a5,a5,0x20
    80006872:	9381                	srli	a5,a5,0x20
    80006874:	02858593          	addi	a1,a1,40
}
    80006878:	00f58533          	add	a0,a1,a5
    8000687c:	6422                	ld	s0,8(sp)
    8000687e:	0141                	addi	sp,sp,16
    80006880:	8082                	ret

0000000080006882 <copy_psuedo>:
int copy_psuedo(pagetable_t old, pagetable_t new, uint64 sz) {
    pte_t *pte;
    uint64 pa, i;
    uint flags;

    for (i = 0; i < sz; i += PGSIZE) {
    80006882:	ce49                	beqz	a2,8000691c <copy_psuedo+0x9a>
int copy_psuedo(pagetable_t old, pagetable_t new, uint64 sz) {
    80006884:	7179                	addi	sp,sp,-48
    80006886:	f406                	sd	ra,40(sp)
    80006888:	f022                	sd	s0,32(sp)
    8000688a:	ec26                	sd	s1,24(sp)
    8000688c:	e84a                	sd	s2,16(sp)
    8000688e:	e44e                	sd	s3,8(sp)
    80006890:	e052                	sd	s4,0(sp)
    80006892:	1800                	addi	s0,sp,48
    80006894:	8a2a                	mv	s4,a0
    80006896:	89ae                	mv	s3,a1
    80006898:	8932                	mv	s2,a2
    for (i = 0; i < sz; i += PGSIZE) {
    8000689a:	4481                	li	s1,0
        if ((pte = walk(old, i, 0)) == 0)
    8000689c:	4601                	li	a2,0
    8000689e:	85a6                	mv	a1,s1
    800068a0:	8552                	mv	a0,s4
    800068a2:	ffffa097          	auipc	ra,0xffffa
    800068a6:	78c080e7          	jalr	1932(ra) # 8000102e <walk>
    800068aa:	c51d                	beqz	a0,800068d8 <copy_psuedo+0x56>
            panic("uvmcopy: pte should exist");
        if ((*pte & PTE_V) == 0)
    800068ac:	6118                	ld	a4,0(a0)
    800068ae:	00177793          	andi	a5,a4,1
    800068b2:	cb9d                	beqz	a5,800068e8 <copy_psuedo+0x66>
            panic("uvmcopy: page not present");
        
        pa = PTE2PA(*pte);
    800068b4:	00a75693          	srli	a3,a4,0xa
        flags = PTE_FLAGS(*pte);

        if (mappages(new, i, PGSIZE, pa, flags) != 0)
    800068b8:	3ff77713          	andi	a4,a4,1023
    800068bc:	06b2                	slli	a3,a3,0xc
    800068be:	6605                	lui	a2,0x1
    800068c0:	85a6                	mv	a1,s1
    800068c2:	854e                	mv	a0,s3
    800068c4:	ffffb097          	auipc	ra,0xffffb
    800068c8:	852080e7          	jalr	-1966(ra) # 80001116 <mappages>
    800068cc:	e515                	bnez	a0,800068f8 <copy_psuedo+0x76>
    for (i = 0; i < sz; i += PGSIZE) {
    800068ce:	6785                	lui	a5,0x1
    800068d0:	94be                	add	s1,s1,a5
    800068d2:	fd24e5e3          	bltu	s1,s2,8000689c <copy_psuedo+0x1a>
    800068d6:	a81d                	j	8000690c <copy_psuedo+0x8a>
            panic("uvmcopy: pte should exist");
    800068d8:	00003517          	auipc	a0,0x3
    800068dc:	8b050513          	addi	a0,a0,-1872 # 80009188 <digits+0x148>
    800068e0:	ffffa097          	auipc	ra,0xffffa
    800068e4:	c60080e7          	jalr	-928(ra) # 80000540 <panic>
            panic("uvmcopy: page not present");
    800068e8:	00003517          	auipc	a0,0x3
    800068ec:	8c050513          	addi	a0,a0,-1856 # 800091a8 <digits+0x168>
    800068f0:	ffffa097          	auipc	ra,0xffffa
    800068f4:	c50080e7          	jalr	-944(ra) # 80000540 <panic>
            goto err;
    }
    return 0;

    err:
        uvmunmap(new, 0, i / PGSIZE, 1);
    800068f8:	4685                	li	a3,1
    800068fa:	00c4d613          	srli	a2,s1,0xc
    800068fe:	4581                	li	a1,0
    80006900:	854e                	mv	a0,s3
    80006902:	ffffb097          	auipc	ra,0xffffb
    80006906:	9da080e7          	jalr	-1574(ra) # 800012dc <uvmunmap>
        return -1;
    8000690a:	557d                	li	a0,-1
}
    8000690c:	70a2                	ld	ra,40(sp)
    8000690e:	7402                	ld	s0,32(sp)
    80006910:	64e2                	ld	s1,24(sp)
    80006912:	6942                	ld	s2,16(sp)
    80006914:	69a2                	ld	s3,8(sp)
    80006916:	6a02                	ld	s4,0(sp)
    80006918:	6145                	addi	sp,sp,48
    8000691a:	8082                	ret
    return 0;
    8000691c:	4501                	li	a0,0
}
    8000691e:	8082                	ret

0000000080006920 <map_psuedo>:

int map_psuedo(pagetable_t old, pagetable_t new, uint64 lowerbound, uint64 upperbound) {
    80006920:	7179                	addi	sp,sp,-48
    80006922:	f406                	sd	ra,40(sp)
    80006924:	f022                	sd	s0,32(sp)
    80006926:	ec26                	sd	s1,24(sp)
    80006928:	e84a                	sd	s2,16(sp)
    8000692a:	e44e                	sd	s3,8(sp)
    8000692c:	e052                	sd	s4,0(sp)
    8000692e:	1800                	addi	s0,sp,48
    80006930:	8a2a                	mv	s4,a0
    80006932:	89ae                	mv	s3,a1
    80006934:	84b2                	mv	s1,a2
    80006936:	8936                	mv	s2,a3
    pte_t *pte;
    uint64 pa, i;
    uint flags;

    for (i = lowerbound; i < upperbound; i += PGSIZE) {
    80006938:	08d67263          	bgeu	a2,a3,800069bc <map_psuedo+0x9c>
        if ((pte = walk(old, i, 0)) == 0)
    8000693c:	4601                	li	a2,0
    8000693e:	85a6                	mv	a1,s1
    80006940:	8552                	mv	a0,s4
    80006942:	ffffa097          	auipc	ra,0xffffa
    80006946:	6ec080e7          	jalr	1772(ra) # 8000102e <walk>
    8000694a:	c51d                	beqz	a0,80006978 <map_psuedo+0x58>
            panic("uvmcopy: pte should exist");
        if ((*pte & PTE_V) == 0)
    8000694c:	6118                	ld	a4,0(a0)
    8000694e:	00177793          	andi	a5,a4,1
    80006952:	cb9d                	beqz	a5,80006988 <map_psuedo+0x68>
            panic("uvmcopy: page not present");
        
        pa = PTE2PA(*pte);
    80006954:	00a75693          	srli	a3,a4,0xa
        flags = PTE_FLAGS(*pte);

        if (mappages(new, i, PGSIZE, pa, flags) != 0)
    80006958:	3ff77713          	andi	a4,a4,1023
    8000695c:	06b2                	slli	a3,a3,0xc
    8000695e:	6605                	lui	a2,0x1
    80006960:	85a6                	mv	a1,s1
    80006962:	854e                	mv	a0,s3
    80006964:	ffffa097          	auipc	ra,0xffffa
    80006968:	7b2080e7          	jalr	1970(ra) # 80001116 <mappages>
    8000696c:	e515                	bnez	a0,80006998 <map_psuedo+0x78>
    for (i = lowerbound; i < upperbound; i += PGSIZE) {
    8000696e:	6785                	lui	a5,0x1
    80006970:	94be                	add	s1,s1,a5
    80006972:	fd24e5e3          	bltu	s1,s2,8000693c <map_psuedo+0x1c>
    80006976:	a81d                	j	800069ac <map_psuedo+0x8c>
            panic("uvmcopy: pte should exist");
    80006978:	00003517          	auipc	a0,0x3
    8000697c:	81050513          	addi	a0,a0,-2032 # 80009188 <digits+0x148>
    80006980:	ffffa097          	auipc	ra,0xffffa
    80006984:	bc0080e7          	jalr	-1088(ra) # 80000540 <panic>
            panic("uvmcopy: page not present");
    80006988:	00003517          	auipc	a0,0x3
    8000698c:	82050513          	addi	a0,a0,-2016 # 800091a8 <digits+0x168>
    80006990:	ffffa097          	auipc	ra,0xffffa
    80006994:	bb0080e7          	jalr	-1104(ra) # 80000540 <panic>
            goto err;
    }
    return 0;

    err:
        uvmunmap(new, 0, i / PGSIZE, 1);
    80006998:	4685                	li	a3,1
    8000699a:	00c4d613          	srli	a2,s1,0xc
    8000699e:	4581                	li	a1,0
    800069a0:	854e                	mv	a0,s3
    800069a2:	ffffb097          	auipc	ra,0xffffb
    800069a6:	93a080e7          	jalr	-1734(ra) # 800012dc <uvmunmap>
        return -1;
    800069aa:	557d                	li	a0,-1
}
    800069ac:	70a2                	ld	ra,40(sp)
    800069ae:	7402                	ld	s0,32(sp)
    800069b0:	64e2                	ld	s1,24(sp)
    800069b2:	6942                	ld	s2,16(sp)
    800069b4:	69a2                	ld	s3,8(sp)
    800069b6:	6a02                	ld	s4,0(sp)
    800069b8:	6145                	addi	sp,sp,48
    800069ba:	8082                	ret
    return 0;
    800069bc:	4501                	li	a0,0
    800069be:	b7fd                	j	800069ac <map_psuedo+0x8c>

00000000800069c0 <pmp_not_configured>:

void pmp_not_configured(struct proc *p) {
    800069c0:	1101                	addi	sp,sp,-32
    800069c2:	ec06                	sd	ra,24(sp)
    800069c4:	e822                	sd	s0,16(sp)
    800069c6:	e426                	sd	s1,8(sp)
    800069c8:	1000                	addi	s0,sp,32
    800069ca:	84aa                	mv	s1,a0
    printf("[DEBUG]: Accessing unmapped region. Killing VM...\n");
    800069cc:	00003517          	auipc	a0,0x3
    800069d0:	16c50513          	addi	a0,a0,364 # 80009b38 <syscalls+0x6e0>
    800069d4:	ffffa097          	auipc	ra,0xffffa
    800069d8:	bb6080e7          	jalr	-1098(ra) # 8000058a <printf>
    setkilled(p);
    800069dc:	8526                	mv	a0,s1
    800069de:	ffffc097          	auipc	ra,0xffffc
    800069e2:	998080e7          	jalr	-1640(ra) # 80002376 <setkilled>
}
    800069e6:	60e2                	ld	ra,24(sp)
    800069e8:	6442                	ld	s0,16(sp)
    800069ea:	64a2                	ld	s1,8(sp)
    800069ec:	6105                	addi	sp,sp,32
    800069ee:	8082                	ret

00000000800069f0 <trap_and_emulate>:

void trap_and_emulate(void) {
    800069f0:	715d                	addi	sp,sp,-80
    800069f2:	e486                	sd	ra,72(sp)
    800069f4:	e0a2                	sd	s0,64(sp)
    800069f6:	fc26                	sd	s1,56(sp)
    800069f8:	f84a                	sd	s2,48(sp)
    800069fa:	f44e                	sd	s3,40(sp)
    800069fc:	f052                	sd	s4,32(sp)
    800069fe:	ec56                	sd	s5,24(sp)
    80006a00:	e85a                	sd	s6,16(sp)
    80006a02:	0880                	addi	s0,sp,80
    /* Comes here when a VM tries to execute a supervisor instruction. */
    struct proc *p = myproc();
    80006a04:	ffffb097          	auipc	ra,0xffffb
    80006a08:	020080e7          	jalr	32(ra) # 80001a24 <myproc>
    80006a0c:	892a                	mv	s2,a0
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80006a0e:	141029f3          	csrr	s3,sepc

    /* Retrieve all required values from the instruction */
    uint64 addr     = r_sepc();
    uint32 inst;
    copyin(p->pagetable, (char *) &inst, addr, sizeof(uint32));
    80006a12:	4691                	li	a3,4
    80006a14:	864e                	mv	a2,s3
    80006a16:	fbc40593          	addi	a1,s0,-68
    80006a1a:	6928                	ld	a0,80(a0)
    80006a1c:	ffffb097          	auipc	ra,0xffffb
    80006a20:	d54080e7          	jalr	-684(ra) # 80001770 <copyin>
    uint32 op       = (inst) & 0x7F;
    80006a24:	fbc42803          	lw	a6,-68(s0)
    80006a28:	07f87a13          	andi	s4,a6,127
    uint32 rd       = (inst >> 7) & 0x1F;
    80006a2c:	0078571b          	srliw	a4,a6,0x7
    80006a30:	01f77a93          	andi	s5,a4,31
    uint32 funct3   = (inst >> 12) & 0x7;
    80006a34:	00c8579b          	srliw	a5,a6,0xc
    80006a38:	8b9d                	andi	a5,a5,7
    uint32 rs1      = (inst >> 15) & 0x1F;
    80006a3a:	00f8569b          	srliw	a3,a6,0xf
    80006a3e:	01f6fb13          	andi	s6,a3,31
    uint32 uimm     = (inst >> 20) & 0xFFF;
    80006a42:	0148549b          	srliw	s1,a6,0x14
    
    switch (funct3) {
    80006a46:	4605                	li	a2,1
    80006a48:	26c78463          	beq	a5,a2,80006cb0 <trap_and_emulate+0x2c0>
    80006a4c:	4609                	li	a2,2
    80006a4e:	3ac78563          	beq	a5,a2,80006df8 <trap_and_emulate+0x408>
    80006a52:	c385                	beqz	a5,80006a72 <trap_and_emulate+0x82>
                setkilled(p);
            }
            break;
        
        default:
            setkilled(p);
    80006a54:	854a                	mv	a0,s2
    80006a56:	ffffc097          	auipc	ra,0xffffc
    80006a5a:	920080e7          	jalr	-1760(ra) # 80002376 <setkilled>
            break;
    }
}
    80006a5e:	60a6                	ld	ra,72(sp)
    80006a60:	6406                	ld	s0,64(sp)
    80006a62:	74e2                	ld	s1,56(sp)
    80006a64:	7942                	ld	s2,48(sp)
    80006a66:	79a2                	ld	s3,40(sp)
    80006a68:	7a02                	ld	s4,32(sp)
    80006a6a:	6ae2                	ld	s5,24(sp)
    80006a6c:	6b42                	ld	s6,16(sp)
    80006a6e:	6161                	addi	sp,sp,80
    80006a70:	8082                	ret
            if (op == 0x73 && rd == 0x0 && rs1 == 0x0) {
    80006a72:	07300793          	li	a5,115
    80006a76:	20fa1363          	bne	s4,a5,80006c7c <trap_and_emulate+0x28c>
    80006a7a:	8f55                	or	a4,a4,a3
    80006a7c:	8b7d                	andi	a4,a4,31
    80006a7e:	1e071f63          	bnez	a4,80006c7c <trap_and_emulate+0x28c>
                if (uimm == 0x0 && p->proc_te_vm == 1) { // ECALL
    80006a82:	e8f1                	bnez	s1,80006b56 <trap_and_emulate+0x166>
    80006a84:	16892703          	lw	a4,360(s2)
    80006a88:	4785                	li	a5,1
    80006a8a:	02f70d63          	beq	a4,a5,80006ac4 <trap_and_emulate+0xd4>
                    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);
    80006a8e:	8826                	mv	a6,s1
    80006a90:	87da                	mv	a5,s6
    80006a92:	4701                	li	a4,0
    80006a94:	86d6                	mv	a3,s5
    80006a96:	07300613          	li	a2,115
    80006a9a:	85ce                	mv	a1,s3
    80006a9c:	00003517          	auipc	a0,0x3
    80006aa0:	0e450513          	addi	a0,a0,228 # 80009b80 <syscalls+0x728>
    80006aa4:	ffffa097          	auipc	ra,0xffffa
    80006aa8:	ae6080e7          	jalr	-1306(ra) # 8000058a <printf>
                    p->pagetable = vm.og_pagetable;
    80006aac:	0001d797          	auipc	a5,0x1d
    80006ab0:	f6c7b783          	ld	a5,-148(a5) # 80023a18 <vm+0x758>
    80006ab4:	04f93823          	sd	a5,80(s2)
                    setkilled(p);
    80006ab8:	854a                	mv	a0,s2
    80006aba:	ffffc097          	auipc	ra,0xffffc
    80006abe:	8bc080e7          	jalr	-1860(ra) # 80002376 <setkilled>
    80006ac2:	bf71                	j	80006a5e <trap_and_emulate+0x6e>
                    printf("(EC at %p)\n", p->trapframe->epc);
    80006ac4:	05893783          	ld	a5,88(s2)
    80006ac8:	6f8c                	ld	a1,24(a5)
    80006aca:	00003517          	auipc	a0,0x3
    80006ace:	0a650513          	addi	a0,a0,166 # 80009b70 <syscalls+0x718>
    80006ad2:	ffffa097          	auipc	ra,0xffffa
    80006ad6:	ab8080e7          	jalr	-1352(ra) # 8000058a <printf>
                    switch (vm.priviledge_mode) {
    80006ada:	0001d797          	auipc	a5,0x1d
    80006ade:	f267b783          	ld	a5,-218(a5) # 80023a00 <vm+0x740>
    80006ae2:	4705                	li	a4,1
    80006ae4:	04e78063          	beq	a5,a4,80006b24 <trap_and_emulate+0x134>
    80006ae8:	4709                	li	a4,2
    80006aea:	f6e79ae3          	bne	a5,a4,80006a5e <trap_and_emulate+0x6e>
                            vm.mepc.val = p->trapframe->epc;
    80006aee:	05893783          	ld	a5,88(s2)
    80006af2:	6f98                	ld	a4,24(a5)
    80006af4:	0001c797          	auipc	a5,0x1c
    80006af8:	7cc78793          	addi	a5,a5,1996 # 800232c0 <vm>
    80006afc:	20e7b423          	sd	a4,520(a5)
                            vm.priviledge_mode = M_MODE;
    80006b00:	470d                	li	a4,3
    80006b02:	74e7b023          	sd	a4,1856(a5)
                            p->trapframe->epc = vm.mtvec.val;
    80006b06:	05893703          	ld	a4,88(s2)
    80006b0a:	1d87b683          	ld	a3,472(a5)
    80006b0e:	ef14                	sd	a3,24(a4)
                            if (vm.pmp_setup == true)
    80006b10:	7487c783          	lbu	a5,1864(a5)
    80006b14:	d7a9                	beqz	a5,80006a5e <trap_and_emulate+0x6e>
                                p->pagetable = vm.og_pagetable;
    80006b16:	0001d797          	auipc	a5,0x1d
    80006b1a:	f027b783          	ld	a5,-254(a5) # 80023a18 <vm+0x758>
    80006b1e:	04f93823          	sd	a5,80(s2)
    80006b22:	bf35                	j	80006a5e <trap_and_emulate+0x6e>
                            vm.sepc.val = p->trapframe->epc;
    80006b24:	05893783          	ld	a5,88(s2)
    80006b28:	6f98                	ld	a4,24(a5)
    80006b2a:	0001c797          	auipc	a5,0x1c
    80006b2e:	79678793          	addi	a5,a5,1942 # 800232c0 <vm>
    80006b32:	fff8                	sd	a4,248(a5)
                            vm.priviledge_mode = S_MODE;
    80006b34:	4709                	li	a4,2
    80006b36:	74e7b023          	sd	a4,1856(a5)
                            p->trapframe->epc = vm.stvec.val;
    80006b3a:	05893703          	ld	a4,88(s2)
    80006b3e:	67f4                	ld	a3,200(a5)
    80006b40:	ef14                	sd	a3,24(a4)
                            if (vm.pmp_setup == true)
    80006b42:	7487c783          	lbu	a5,1864(a5)
    80006b46:	df81                	beqz	a5,80006a5e <trap_and_emulate+0x6e>
                                p->pagetable = vm.pmp_pagetable;
    80006b48:	0001d797          	auipc	a5,0x1d
    80006b4c:	ec87b783          	ld	a5,-312(a5) # 80023a10 <vm+0x750>
    80006b50:	04f93823          	sd	a5,80(s2)
    80006b54:	b729                	j	80006a5e <trap_and_emulate+0x6e>
                } else if (uimm == 0x102 && vm.priviledge_mode == S_MODE) { // SRET
    80006b56:	10200793          	li	a5,258
    80006b5a:	06f48063          	beq	s1,a5,80006bba <trap_and_emulate+0x1ca>
                } else if (uimm == 0x302 && vm.priviledge_mode == M_MODE) { // MRET
    80006b5e:	30200793          	li	a5,770
    80006b62:	f2f496e3          	bne	s1,a5,80006a8e <trap_and_emulate+0x9e>
    80006b66:	0001d717          	auipc	a4,0x1d
    80006b6a:	e9a73703          	ld	a4,-358(a4) # 80023a00 <vm+0x740>
    80006b6e:	478d                	li	a5,3
    80006b70:	f0f71fe3          	bne	a4,a5,80006a8e <trap_and_emulate+0x9e>
                    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);
    80006b74:	30200813          	li	a6,770
    80006b78:	87da                	mv	a5,s6
    80006b7a:	4701                	li	a4,0
    80006b7c:	86d6                	mv	a3,s5
    80006b7e:	07300613          	li	a2,115
    80006b82:	85ce                	mv	a1,s3
    80006b84:	00003517          	auipc	a0,0x3
    80006b88:	ffc50513          	addi	a0,a0,-4 # 80009b80 <syscalls+0x728>
    80006b8c:	ffffa097          	auipc	ra,0xffffa
    80006b90:	9fe080e7          	jalr	-1538(ra) # 8000058a <printf>
                    switch ((vm.mstatus.val & MSTATUS_MPP_MASK) >> 11) {
    80006b94:	0001d797          	auipc	a5,0x1d
    80006b98:	8b47b783          	ld	a5,-1868(a5) # 80023448 <vm+0x188>
    80006b9c:	83ad                	srli	a5,a5,0xb
    80006b9e:	8b8d                	andi	a5,a5,3
    80006ba0:	4705                	li	a4,1
    80006ba2:	08e78963          	beq	a5,a4,80006c34 <trap_and_emulate+0x244>
    80006ba6:	470d                	li	a4,3
    80006ba8:	0ae78d63          	beq	a5,a4,80006c62 <trap_and_emulate+0x272>
    80006bac:	cfa9                	beqz	a5,80006c06 <trap_and_emulate+0x216>
                            setkilled(p);
    80006bae:	854a                	mv	a0,s2
    80006bb0:	ffffb097          	auipc	ra,0xffffb
    80006bb4:	7c6080e7          	jalr	1990(ra) # 80002376 <setkilled>
                            return;
    80006bb8:	b55d                	j	80006a5e <trap_and_emulate+0x6e>
                } else if (uimm == 0x102 && vm.priviledge_mode == S_MODE) { // SRET
    80006bba:	0001d717          	auipc	a4,0x1d
    80006bbe:	e4673703          	ld	a4,-442(a4) # 80023a00 <vm+0x740>
    80006bc2:	4789                	li	a5,2
    80006bc4:	ecf715e3          	bne	a4,a5,80006a8e <trap_and_emulate+0x9e>
                    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);
    80006bc8:	10200813          	li	a6,258
    80006bcc:	87da                	mv	a5,s6
    80006bce:	4701                	li	a4,0
    80006bd0:	86d6                	mv	a3,s5
    80006bd2:	07300613          	li	a2,115
    80006bd6:	85ce                	mv	a1,s3
    80006bd8:	00003517          	auipc	a0,0x3
    80006bdc:	fa850513          	addi	a0,a0,-88 # 80009b80 <syscalls+0x728>
    80006be0:	ffffa097          	auipc	ra,0xffffa
    80006be4:	9aa080e7          	jalr	-1622(ra) # 8000058a <printf>
                            vm.priviledge_mode = U_MODE;
    80006be8:	0001c717          	auipc	a4,0x1c
    80006bec:	6d870713          	addi	a4,a4,1752 # 800232c0 <vm>
                    switch ((vm.sstatus.val & SSTATUS_SPP) >> 8) {
    80006bf0:	675c                	ld	a5,136(a4)
    80006bf2:	83a1                	srli	a5,a5,0x8
    80006bf4:	8b85                	andi	a5,a5,1
                            vm.priviledge_mode = U_MODE;
    80006bf6:	0785                	addi	a5,a5,1
    80006bf8:	74f73023          	sd	a5,1856(a4)
                    p->trapframe->epc = vm.sepc.val;
    80006bfc:	05893783          	ld	a5,88(s2)
    80006c00:	7f78                	ld	a4,248(a4)
    80006c02:	ef98                	sd	a4,24(a5)
    80006c04:	bda9                	j	80006a5e <trap_and_emulate+0x6e>
                            vm.priviledge_mode = U_MODE;
    80006c06:	0001c797          	auipc	a5,0x1c
    80006c0a:	6ba78793          	addi	a5,a5,1722 # 800232c0 <vm>
    80006c0e:	4705                	li	a4,1
    80006c10:	74e7b023          	sd	a4,1856(a5)
                            if (vm.pmp_setup == true)
    80006c14:	7487c783          	lbu	a5,1864(a5)
    80006c18:	cb81                	beqz	a5,80006c28 <trap_and_emulate+0x238>
                                p->pagetable = vm.pmp_pagetable;
    80006c1a:	0001d797          	auipc	a5,0x1d
    80006c1e:	df67b783          	ld	a5,-522(a5) # 80023a10 <vm+0x750>
    80006c22:	04f93823          	sd	a5,80(s2)
    80006c26:	a099                	j	80006c6c <trap_and_emulate+0x27c>
                                pmp_not_configured(p);
    80006c28:	854a                	mv	a0,s2
    80006c2a:	00000097          	auipc	ra,0x0
    80006c2e:	d96080e7          	jalr	-618(ra) # 800069c0 <pmp_not_configured>
    80006c32:	a82d                	j	80006c6c <trap_and_emulate+0x27c>
                            vm.priviledge_mode = S_MODE;
    80006c34:	0001c797          	auipc	a5,0x1c
    80006c38:	68c78793          	addi	a5,a5,1676 # 800232c0 <vm>
    80006c3c:	4709                	li	a4,2
    80006c3e:	74e7b023          	sd	a4,1856(a5)
                            if (vm.pmp_setup == true)
    80006c42:	7487c783          	lbu	a5,1864(a5)
    80006c46:	cb81                	beqz	a5,80006c56 <trap_and_emulate+0x266>
                                p->pagetable = vm.pmp_pagetable;
    80006c48:	0001d797          	auipc	a5,0x1d
    80006c4c:	dc87b783          	ld	a5,-568(a5) # 80023a10 <vm+0x750>
    80006c50:	04f93823          	sd	a5,80(s2)
    80006c54:	a821                	j	80006c6c <trap_and_emulate+0x27c>
                                pmp_not_configured(p);
    80006c56:	854a                	mv	a0,s2
    80006c58:	00000097          	auipc	ra,0x0
    80006c5c:	d68080e7          	jalr	-664(ra) # 800069c0 <pmp_not_configured>
    80006c60:	a031                	j	80006c6c <trap_and_emulate+0x27c>
                            vm.priviledge_mode = M_MODE;
    80006c62:	478d                	li	a5,3
    80006c64:	0001d717          	auipc	a4,0x1d
    80006c68:	d8f73e23          	sd	a5,-612(a4) # 80023a00 <vm+0x740>
                    p->trapframe->epc = vm.mepc.val;
    80006c6c:	05893783          	ld	a5,88(s2)
    80006c70:	0001d717          	auipc	a4,0x1d
    80006c74:	85873703          	ld	a4,-1960(a4) # 800234c8 <vm+0x208>
    80006c78:	ef98                	sd	a4,24(a5)
    80006c7a:	b3d5                	j	80006a5e <trap_and_emulate+0x6e>
                printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);
    80006c7c:	8826                	mv	a6,s1
    80006c7e:	87da                	mv	a5,s6
    80006c80:	4701                	li	a4,0
    80006c82:	86d6                	mv	a3,s5
    80006c84:	8652                	mv	a2,s4
    80006c86:	85ce                	mv	a1,s3
    80006c88:	00003517          	auipc	a0,0x3
    80006c8c:	ef850513          	addi	a0,a0,-264 # 80009b80 <syscalls+0x728>
    80006c90:	ffffa097          	auipc	ra,0xffffa
    80006c94:	8fa080e7          	jalr	-1798(ra) # 8000058a <printf>
                p->pagetable = vm.og_pagetable;
    80006c98:	0001d797          	auipc	a5,0x1d
    80006c9c:	d807b783          	ld	a5,-640(a5) # 80023a18 <vm+0x758>
    80006ca0:	04f93823          	sd	a5,80(s2)
                setkilled(p);
    80006ca4:	854a                	mv	a0,s2
    80006ca6:	ffffb097          	auipc	ra,0xffffb
    80006caa:	6d0080e7          	jalr	1744(ra) # 80002376 <setkilled>
    80006cae:	bb45                	j	80006a5e <trap_and_emulate+0x6e>
            printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);
    80006cb0:	8826                	mv	a6,s1
    80006cb2:	87da                	mv	a5,s6
    80006cb4:	4705                	li	a4,1
    80006cb6:	86d6                	mv	a3,s5
    80006cb8:	8652                	mv	a2,s4
    80006cba:	85ce                	mv	a1,s3
    80006cbc:	00003517          	auipc	a0,0x3
    80006cc0:	ec450513          	addi	a0,a0,-316 # 80009b80 <syscalls+0x728>
    80006cc4:	ffffa097          	auipc	ra,0xffffa
    80006cc8:	8c6080e7          	jalr	-1850(ra) # 8000058a <printf>
            if (op == 0x73 && rd == 0x0) { // CSRW
    80006ccc:	07300793          	li	a5,115
    80006cd0:	00fa1463          	bne	s4,a5,80006cd8 <trap_and_emulate+0x2e8>
    80006cd4:	000a8e63          	beqz	s5,80006cf0 <trap_and_emulate+0x300>
                p->pagetable = vm.og_pagetable;
    80006cd8:	0001d797          	auipc	a5,0x1d
    80006cdc:	d407b783          	ld	a5,-704(a5) # 80023a18 <vm+0x758>
    80006ce0:	04f93823          	sd	a5,80(s2)
                setkilled(p);
    80006ce4:	854a                	mv	a0,s2
    80006ce6:	ffffb097          	auipc	ra,0xffffb
    80006cea:	690080e7          	jalr	1680(ra) # 80002376 <setkilled>
    80006cee:	bb85                	j	80006a5e <trap_and_emulate+0x6e>
                uint64 *src = get_vm_trapframe_register(rs1, p->trapframe);
    80006cf0:	05893a03          	ld	s4,88(s2)
                struct vm_reg *dest = get_vm_privileged_register(uimm, &vm);
    80006cf4:	0001c997          	auipc	s3,0x1c
    80006cf8:	5cc98993          	addi	s3,s3,1484 # 800232c0 <vm>
    80006cfc:	85ce                	mv	a1,s3
    80006cfe:	8526                	mv	a0,s1
    80006d00:	00000097          	auipc	ra,0x0
    80006d04:	922080e7          	jalr	-1758(ra) # 80006622 <get_vm_privileged_register>
                if (vm.priviledge_mode >= dest->mode && uimm != 0xf11) {                    
    80006d08:	415c                	lw	a5,4(a0)
    80006d0a:	7409b703          	ld	a4,1856(s3)
    80006d0e:	0cf76963          	bltu	a4,a5,80006de0 <trap_and_emulate+0x3f0>
    return (uint64 *)((reg - 1) * 8 + (uint64)&tf->ra); // reg == 1 is tf->ra
    80006d12:	fffb079b          	addiw	a5,s6,-1
    80006d16:	0037979b          	slliw	a5,a5,0x3
    80006d1a:	1782                	slli	a5,a5,0x20
    80006d1c:	9381                	srli	a5,a5,0x20
    80006d1e:	028a0a13          	addi	s4,s4,40
    80006d22:	97d2                	add	a5,a5,s4
                if (vm.priviledge_mode >= dest->mode && uimm != 0xf11) {                    
    80006d24:	6705                	lui	a4,0x1
    80006d26:	f1170713          	addi	a4,a4,-239 # f11 <_entry-0x7ffff0ef>
    80006d2a:	08e48b63          	beq	s1,a4,80006dc0 <trap_and_emulate+0x3d0>
                    dest->val = *src;
    80006d2e:	639c                	ld	a5,0(a5)
    80006d30:	e51c                	sd	a5,8(a0)
                    p->trapframe->epc += 4;
    80006d32:	05893703          	ld	a4,88(s2)
    80006d36:	6f1c                	ld	a5,24(a4)
    80006d38:	0791                	addi	a5,a5,4
    80006d3a:	ef1c                	sd	a5,24(a4)
                    if (vm.pmp_setup == true && dest->code == 0x03a0) { // Check if PMP enabled and pmpcfg0 is fetched
    80006d3c:	0001d797          	auipc	a5,0x1d
    80006d40:	ccc7c783          	lbu	a5,-820(a5) # 80023a08 <vm+0x748>
    80006d44:	d0078de3          	beqz	a5,80006a5e <trap_and_emulate+0x6e>
    80006d48:	4118                	lw	a4,0(a0)
    80006d4a:	3a000793          	li	a5,928
    80006d4e:	d0f718e3          	bne	a4,a5,80006a5e <trap_and_emulate+0x6e>
                        if (((dest->val >> 3) & 0x3) == 0x1) { // Check if TOR mode is enabled
    80006d52:	651c                	ld	a5,8(a0)
    80006d54:	838d                	srli	a5,a5,0x3
    80006d56:	8b8d                	andi	a5,a5,3
    80006d58:	4705                	li	a4,1
    80006d5a:	00e78763          	beq	a5,a4,80006d68 <trap_and_emulate+0x378>
                            vm.pmp_setup = false;
    80006d5e:	0001d797          	auipc	a5,0x1d
    80006d62:	ca078523          	sb	zero,-854(a5) # 80023a08 <vm+0x748>
    80006d66:	b9e5                	j	80006a5e <trap_and_emulate+0x6e>
                            uint64 pmp_addr = (dest + 0x10)->val << 2; // << 2 is since TOR is 4-byte aligned
    80006d68:	10853983          	ld	s3,264(a0)
    80006d6c:	098a                	slli	s3,s3,0x2
                            vm.og_pagetable = p->pagetable;
    80006d6e:	05093783          	ld	a5,80(s2)
    80006d72:	0001c497          	auipc	s1,0x1c
    80006d76:	54e48493          	addi	s1,s1,1358 # 800232c0 <vm>
    80006d7a:	74f4bc23          	sd	a5,1880(s1)
                            vm.pmp_pagetable = proc_pagetable(p);
    80006d7e:	854a                	mv	a0,s2
    80006d80:	ffffb097          	auipc	ra,0xffffb
    80006d84:	d68080e7          	jalr	-664(ra) # 80001ae8 <proc_pagetable>
    80006d88:	85aa                	mv	a1,a0
    80006d8a:	74a4b823          	sd	a0,1872(s1)
                            copy_psuedo(vm.og_pagetable, vm.pmp_pagetable, p->sz);
    80006d8e:	04893603          	ld	a2,72(s2)
    80006d92:	7584b503          	ld	a0,1880(s1)
    80006d96:	00000097          	auipc	ra,0x0
    80006d9a:	aec080e7          	jalr	-1300(ra) # 80006882 <copy_psuedo>
                            map_psuedo(vm.og_pagetable, vm.pmp_pagetable, VMM_BASE_ADDRESS, PGROUNDUP(pmp_addr));
    80006d9e:	6785                	lui	a5,0x1
    80006da0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80006da2:	99be                	add	s3,s3,a5
    80006da4:	76fd                	lui	a3,0xfffff
    80006da6:	00d9f6b3          	and	a3,s3,a3
    80006daa:	4605                	li	a2,1
    80006dac:	067e                	slli	a2,a2,0x1f
    80006dae:	7504b583          	ld	a1,1872(s1)
    80006db2:	7584b503          	ld	a0,1880(s1)
    80006db6:	00000097          	auipc	ra,0x0
    80006dba:	b6a080e7          	jalr	-1174(ra) # 80006920 <map_psuedo>
    80006dbe:	b145                	j	80006a5e <trap_and_emulate+0x6e>
                    dest->val = *src;
    80006dc0:	639c                	ld	a5,0(a5)
    80006dc2:	e51c                	sd	a5,8(a0)
                    p->trapframe->epc += 4;
    80006dc4:	05893703          	ld	a4,88(s2)
    80006dc8:	6f1c                	ld	a5,24(a4)
    80006dca:	0791                	addi	a5,a5,4
    80006dcc:	ef1c                	sd	a5,24(a4)
                    if (dest->val == 0x0)
    80006dce:	651c                	ld	a5,8(a0)
    80006dd0:	c80797e3          	bnez	a5,80006a5e <trap_and_emulate+0x6e>
                        setkilled(p);
    80006dd4:	854a                	mv	a0,s2
    80006dd6:	ffffb097          	auipc	ra,0xffffb
    80006dda:	5a0080e7          	jalr	1440(ra) # 80002376 <setkilled>
    80006dde:	b141                	j	80006a5e <trap_and_emulate+0x6e>
                    p->pagetable = vm.og_pagetable;
    80006de0:	0001d797          	auipc	a5,0x1d
    80006de4:	c387b783          	ld	a5,-968(a5) # 80023a18 <vm+0x758>
    80006de8:	04f93823          	sd	a5,80(s2)
                    setkilled(p);
    80006dec:	854a                	mv	a0,s2
    80006dee:	ffffb097          	auipc	ra,0xffffb
    80006df2:	588080e7          	jalr	1416(ra) # 80002376 <setkilled>
    80006df6:	b1a5                	j	80006a5e <trap_and_emulate+0x6e>
            printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", addr, op, rd, funct3, rs1, uimm);
    80006df8:	8826                	mv	a6,s1
    80006dfa:	87da                	mv	a5,s6
    80006dfc:	4709                	li	a4,2
    80006dfe:	86d6                	mv	a3,s5
    80006e00:	8652                	mv	a2,s4
    80006e02:	85ce                	mv	a1,s3
    80006e04:	00003517          	auipc	a0,0x3
    80006e08:	d7c50513          	addi	a0,a0,-644 # 80009b80 <syscalls+0x728>
    80006e0c:	ffff9097          	auipc	ra,0xffff9
    80006e10:	77e080e7          	jalr	1918(ra) # 8000058a <printf>
            if (op == 0x73 && rs1 == 0x0) { // CSRR
    80006e14:	07300793          	li	a5,115
    80006e18:	00fa1463          	bne	s4,a5,80006e20 <trap_and_emulate+0x430>
    80006e1c:	000b0e63          	beqz	s6,80006e38 <trap_and_emulate+0x448>
                p->pagetable = vm.og_pagetable;
    80006e20:	0001d797          	auipc	a5,0x1d
    80006e24:	bf87b783          	ld	a5,-1032(a5) # 80023a18 <vm+0x758>
    80006e28:	04f93823          	sd	a5,80(s2)
                setkilled(p);
    80006e2c:	854a                	mv	a0,s2
    80006e2e:	ffffb097          	auipc	ra,0xffffb
    80006e32:	548080e7          	jalr	1352(ra) # 80002376 <setkilled>
    80006e36:	b125                	j	80006a5e <trap_and_emulate+0x6e>
                struct vm_reg *src = get_vm_privileged_register(uimm, &vm);
    80006e38:	0001c997          	auipc	s3,0x1c
    80006e3c:	48898993          	addi	s3,s3,1160 # 800232c0 <vm>
    80006e40:	85ce                	mv	a1,s3
    80006e42:	8526                	mv	a0,s1
    80006e44:	fffff097          	auipc	ra,0xfffff
    80006e48:	7de080e7          	jalr	2014(ra) # 80006622 <get_vm_privileged_register>
    return (uint64 *)((reg - 1) * 8 + (uint64)&tf->ra); // reg == 1 is tf->ra
    80006e4c:	fffa879b          	addiw	a5,s5,-1
    80006e50:	0037979b          	slliw	a5,a5,0x3
    80006e54:	1782                	slli	a5,a5,0x20
    80006e56:	9381                	srli	a5,a5,0x20
    80006e58:	05893703          	ld	a4,88(s2)
    80006e5c:	02870713          	addi	a4,a4,40
    80006e60:	97ba                	add	a5,a5,a4
                if (vm.priviledge_mode >= src->mode) {
    80006e62:	4158                	lw	a4,4(a0)
    80006e64:	7409b683          	ld	a3,1856(s3)
    80006e68:	00e6ea63          	bltu	a3,a4,80006e7c <trap_and_emulate+0x48c>
                    *dest = src->val;
    80006e6c:	6518                	ld	a4,8(a0)
    80006e6e:	e398                	sd	a4,0(a5)
                    p->trapframe->epc += 4;
    80006e70:	05893703          	ld	a4,88(s2)
    80006e74:	6f1c                	ld	a5,24(a4)
    80006e76:	0791                	addi	a5,a5,4
    80006e78:	ef1c                	sd	a5,24(a4)
    80006e7a:	b6d5                	j	80006a5e <trap_and_emulate+0x6e>
                } else if (src->code == 0x0f11) { // allow mvendorid register to be read in all modes
    80006e7c:	4114                	lw	a3,0(a0)
    80006e7e:	6705                	lui	a4,0x1
    80006e80:	f1170713          	addi	a4,a4,-239 # f11 <_entry-0x7ffff0ef>
    80006e84:	00e69a63          	bne	a3,a4,80006e98 <trap_and_emulate+0x4a8>
                    *dest = src->val;
    80006e88:	6518                	ld	a4,8(a0)
    80006e8a:	e398                	sd	a4,0(a5)
                    p->trapframe->epc += 4;
    80006e8c:	05893703          	ld	a4,88(s2)
    80006e90:	6f1c                	ld	a5,24(a4)
    80006e92:	0791                	addi	a5,a5,4
    80006e94:	ef1c                	sd	a5,24(a4)
    80006e96:	b6e1                	j	80006a5e <trap_and_emulate+0x6e>
                p->pagetable = vm.og_pagetable;
    80006e98:	0001d797          	auipc	a5,0x1d
    80006e9c:	b807b783          	ld	a5,-1152(a5) # 80023a18 <vm+0x758>
    80006ea0:	04f93823          	sd	a5,80(s2)
                    setkilled(p);
    80006ea4:	854a                	mv	a0,s2
    80006ea6:	ffffb097          	auipc	ra,0xffffb
    80006eaa:	4d0080e7          	jalr	1232(ra) # 80002376 <setkilled>
    80006eae:	be45                	j	80006a5e <trap_and_emulate+0x6e>

0000000080006eb0 <init_user_mode_registers>:

void init_user_mode_registers() {
    80006eb0:	1141                	addi	sp,sp,-16
    80006eb2:	e422                	sd	s0,8(sp)
    80006eb4:	0800                	addi	s0,sp,16
    // User trap setup
    vm.ustatus.code = 0x0000;
    80006eb6:	0001c797          	auipc	a5,0x1c
    80006eba:	40a78793          	addi	a5,a5,1034 # 800232c0 <vm>
    80006ebe:	0007a023          	sw	zero,0(a5)
    vm.ustatus.mode = U_MODE;
    80006ec2:	4705                	li	a4,1
    80006ec4:	c3d8                	sw	a4,4(a5)
    vm.ustatus.val = 0x0;
    80006ec6:	0007b423          	sd	zero,8(a5)
    
    vm.uie.code = 0x0004;
    80006eca:	4691                	li	a3,4
    80006ecc:	cb94                	sw	a3,16(a5)
    vm.uie.mode = U_MODE;
    80006ece:	cbd8                	sw	a4,20(a5)
    vm.uie.val = 0x0;
    80006ed0:	0007bc23          	sd	zero,24(a5)
    
    vm.utvec.code = 0x0005;
    80006ed4:	4695                	li	a3,5
    80006ed6:	d394                	sw	a3,32(a5)
    vm.utvec.mode = U_MODE;
    80006ed8:	d3d8                	sw	a4,36(a5)
    vm.utvec.val = 0x0;
    80006eda:	0207b423          	sd	zero,40(a5)

    // User trap handling
    vm.uscratch.code = 0x0040;
    80006ede:	04000693          	li	a3,64
    80006ee2:	db94                	sw	a3,48(a5)
    vm.uscratch.mode = U_MODE;
    80006ee4:	dbd8                	sw	a4,52(a5)
    vm.uscratch.val = 0x0;
    80006ee6:	0207bc23          	sd	zero,56(a5)

    vm.uepc.code = 0x0041;
    80006eea:	04100693          	li	a3,65
    80006eee:	c3b4                	sw	a3,64(a5)
    vm.uepc.mode = U_MODE;
    80006ef0:	c3f8                	sw	a4,68(a5)
    vm.uepc.val = 0x0;
    80006ef2:	0407b423          	sd	zero,72(a5)

    vm.ucause.code = 0x0042;
    80006ef6:	04200693          	li	a3,66
    80006efa:	cbb4                	sw	a3,80(a5)
    vm.ucause.mode = U_MODE;
    80006efc:	cbf8                	sw	a4,84(a5)
    vm.ucause.val = 0x0;
    80006efe:	0407bc23          	sd	zero,88(a5)

    vm.utval.code = 0x0043;
    80006f02:	04300693          	li	a3,67
    80006f06:	d3b4                	sw	a3,96(a5)
    vm.utval.mode = U_MODE;
    80006f08:	d3f8                	sw	a4,100(a5)
    vm.utval.val = 0x0;
    80006f0a:	0607b423          	sd	zero,104(a5)

    vm.uip.code = 0x0044;
    80006f0e:	04400693          	li	a3,68
    80006f12:	dbb4                	sw	a3,112(a5)
    vm.uip.mode = U_MODE;
    80006f14:	dbf8                	sw	a4,116(a5)
    vm.uip.val = 0x0;
    80006f16:	0607bc23          	sd	zero,120(a5)
}
    80006f1a:	6422                	ld	s0,8(sp)
    80006f1c:	0141                	addi	sp,sp,16
    80006f1e:	8082                	ret

0000000080006f20 <init_supervisor_mode_registers>:

void init_supervisor_mode_registers() {
    80006f20:	1141                	addi	sp,sp,-16
    80006f22:	e422                	sd	s0,8(sp)
    80006f24:	0800                	addi	s0,sp,16
    // Supervisor trap setup
    vm.sstatus.code = 0x0100;
    80006f26:	0001c797          	auipc	a5,0x1c
    80006f2a:	39a78793          	addi	a5,a5,922 # 800232c0 <vm>
    80006f2e:	10000713          	li	a4,256
    80006f32:	08e7a023          	sw	a4,128(a5)
    vm.sstatus.mode = S_MODE;
    80006f36:	4709                	li	a4,2
    80006f38:	08e7a223          	sw	a4,132(a5)
    vm.sstatus.val = 0x0;
    80006f3c:	0807b423          	sd	zero,136(a5)

    vm.sedeleg.code = 0x0102;
    80006f40:	10200693          	li	a3,258
    80006f44:	08d7a823          	sw	a3,144(a5)
    vm.sedeleg.mode = S_MODE;
    80006f48:	08e7aa23          	sw	a4,148(a5)
    vm.sedeleg.val = 0x0;
    80006f4c:	0807bc23          	sd	zero,152(a5)

    vm.sideleg.code = 0x0103;
    80006f50:	10300693          	li	a3,259
    80006f54:	0ad7a023          	sw	a3,160(a5)
    vm.sideleg.mode = S_MODE;
    80006f58:	0ae7a223          	sw	a4,164(a5)
    vm.sideleg.val = 0x0;
    80006f5c:	0a07b423          	sd	zero,168(a5)

    vm.sie.code = 0x0104;
    80006f60:	10400693          	li	a3,260
    80006f64:	0ad7a823          	sw	a3,176(a5)
    vm.sie.mode = S_MODE;
    80006f68:	0ae7aa23          	sw	a4,180(a5)
    vm.sie.val = 0x0;
    80006f6c:	0a07bc23          	sd	zero,184(a5)

    vm.stvec.code = 0x0105;
    80006f70:	10500693          	li	a3,261
    80006f74:	0cd7a023          	sw	a3,192(a5)
    vm.stvec.mode = S_MODE;
    80006f78:	0ce7a223          	sw	a4,196(a5)
    vm.stvec.val = 0x0;
    80006f7c:	0c07b423          	sd	zero,200(a5)

    vm.scounteren.code = 0x0106;
    80006f80:	10600693          	li	a3,262
    80006f84:	0cd7a823          	sw	a3,208(a5)
    vm.scounteren.mode = S_MODE;
    80006f88:	0ce7aa23          	sw	a4,212(a5)
    vm.scounteren.val = 0x0;
    80006f8c:	0c07bc23          	sd	zero,216(a5)

    // Supervisor trap handling
    vm.sscratch.code = 0x0140;
    80006f90:	14000693          	li	a3,320
    80006f94:	0ed7a023          	sw	a3,224(a5)
    vm.sscratch.mode = S_MODE;
    80006f98:	0ee7a223          	sw	a4,228(a5)
    vm.sscratch.val = 0x0;
    80006f9c:	0e07b423          	sd	zero,232(a5)

    vm.sepc.code = 0x0141;
    80006fa0:	14100693          	li	a3,321
    80006fa4:	0ed7a823          	sw	a3,240(a5)
    vm.sepc.mode = S_MODE;
    80006fa8:	0ee7aa23          	sw	a4,244(a5)
    vm.sepc.val = 0x0;
    80006fac:	0e07bc23          	sd	zero,248(a5)

    vm.scause.code = 0x0142;
    80006fb0:	14200693          	li	a3,322
    80006fb4:	10d7a023          	sw	a3,256(a5)
    vm.scause.mode = S_MODE;
    80006fb8:	10e7a223          	sw	a4,260(a5)
    vm.scause.val = 0x0;
    80006fbc:	1007b423          	sd	zero,264(a5)

    vm.stval.code = 0x0143;
    80006fc0:	14300693          	li	a3,323
    80006fc4:	10d7a823          	sw	a3,272(a5)
    vm.stval.mode = S_MODE;
    80006fc8:	10e7aa23          	sw	a4,276(a5)
    vm.stval.val = 0x0;
    80006fcc:	1007bc23          	sd	zero,280(a5)

    vm.sip.code = 0x0144;
    80006fd0:	14400693          	li	a3,324
    80006fd4:	12d7a023          	sw	a3,288(a5)
    vm.sip.mode = S_MODE;
    80006fd8:	12e7a223          	sw	a4,292(a5)
    vm.sip.val = 0x0;
    80006fdc:	1207b423          	sd	zero,296(a5)

    // Supervisor page table
    vm.satp.code = 0x0180;
    80006fe0:	18000693          	li	a3,384
    80006fe4:	12d7a823          	sw	a3,304(a5)
    vm.satp.mode = S_MODE;
    80006fe8:	12e7aa23          	sw	a4,308(a5)
    vm.satp.val = 0x0;
    80006fec:	1207bc23          	sd	zero,312(a5)
}
    80006ff0:	6422                	ld	s0,8(sp)
    80006ff2:	0141                	addi	sp,sp,16
    80006ff4:	8082                	ret

0000000080006ff6 <init_machine_mode_registers>:

void init_machine_mode_registers() {
    80006ff6:	1141                	addi	sp,sp,-16
    80006ff8:	e422                	sd	s0,8(sp)
    80006ffa:	0800                	addi	s0,sp,16
    // Machine information
    vm.mvendorid.code = 0x0f11;
    80006ffc:	0001c797          	auipc	a5,0x1c
    80007000:	2c478793          	addi	a5,a5,708 # 800232c0 <vm>
    80007004:	6685                	lui	a3,0x1
    80007006:	f1168713          	addi	a4,a3,-239 # f11 <_entry-0x7ffff0ef>
    8000700a:	14e7a023          	sw	a4,320(a5)
    vm.mvendorid.mode = S_MODE;
    8000700e:	4709                	li	a4,2
    80007010:	14e7a223          	sw	a4,324(a5)
    vm.mvendorid.val = 0x0;
    80007014:	1407b423          	sd	zero,328(a5)

    vm.marchid.code = 0x0f12;
    80007018:	f1268713          	addi	a4,a3,-238
    8000701c:	14e7a823          	sw	a4,336(a5)
    vm.marchid.mode = M_MODE;
    80007020:	470d                	li	a4,3
    80007022:	14e7aa23          	sw	a4,340(a5)
    vm.marchid.val = 0x0;
    80007026:	1407bc23          	sd	zero,344(a5)

    vm.mimpid.code = 0x0f13;
    8000702a:	f1368613          	addi	a2,a3,-237
    8000702e:	16c7a023          	sw	a2,352(a5)
    vm.mimpid.mode = M_MODE;
    80007032:	16e7a223          	sw	a4,356(a5)
    vm.mimpid.val = 0x0;
    80007036:	1607b423          	sd	zero,360(a5)

    vm.mhartid.code = 0x0f14;
    8000703a:	f1468693          	addi	a3,a3,-236
    8000703e:	16d7a823          	sw	a3,368(a5)
    vm.mhartid.mode = M_MODE;
    80007042:	16e7aa23          	sw	a4,372(a5)
    vm.mhartid.val = 0x0;
    80007046:	1607bc23          	sd	zero,376(a5)

    // Machine trap setup
    vm.mstatus.code = 0x0300;
    8000704a:	30000693          	li	a3,768
    8000704e:	18d7a023          	sw	a3,384(a5)
    vm.mstatus.mode = M_MODE;
    80007052:	18e7a223          	sw	a4,388(a5)
    vm.mstatus.val = 0x0;
    80007056:	1807b423          	sd	zero,392(a5)

    vm.misa.code = 0x0301;
    8000705a:	30100693          	li	a3,769
    8000705e:	18d7a823          	sw	a3,400(a5)
    vm.misa.mode = M_MODE;
    80007062:	18e7aa23          	sw	a4,404(a5)
    vm.misa.val = 0x0;
    80007066:	1807bc23          	sd	zero,408(a5)

    vm.medeleg.code = 0x0302;
    8000706a:	30200693          	li	a3,770
    8000706e:	1ad7a023          	sw	a3,416(a5)
    vm.medeleg.mode = M_MODE;
    80007072:	1ae7a223          	sw	a4,420(a5)
    vm.medeleg.val = 0xffff;
    80007076:	66c1                	lui	a3,0x10
    80007078:	16fd                	addi	a3,a3,-1 # ffff <_entry-0x7fff0001>
    8000707a:	1ad7b423          	sd	a3,424(a5)

    vm.mideleg.code = 0x0303;
    8000707e:	30300613          	li	a2,771
    80007082:	1ac7a823          	sw	a2,432(a5)
    vm.mideleg.mode = M_MODE;
    80007086:	1ae7aa23          	sw	a4,436(a5)
    vm.mideleg.val = 0xffff;
    8000708a:	1ad7bc23          	sd	a3,440(a5)

    vm.mie.code = 0x0304;
    8000708e:	30400693          	li	a3,772
    80007092:	1cd7a023          	sw	a3,448(a5)
    vm.mie.mode = M_MODE;
    80007096:	1ce7a223          	sw	a4,452(a5)
    vm.mie.val = 0x0;
    8000709a:	1c07b423          	sd	zero,456(a5)

    vm.mtvec.code = 0x0305;
    8000709e:	30500693          	li	a3,773
    800070a2:	1cd7a823          	sw	a3,464(a5)
    vm.mtvec.mode = M_MODE;
    800070a6:	1ce7aa23          	sw	a4,468(a5)
    vm.mtvec.val = 0x0;
    800070aa:	1c07bc23          	sd	zero,472(a5)

    vm.mcounteren.code = 0x0306;
    800070ae:	30600693          	li	a3,774
    800070b2:	1ed7a023          	sw	a3,480(a5)
    vm.mcounteren.mode = M_MODE;
    800070b6:	1ee7a223          	sw	a4,484(a5)
    vm.mcounteren.val = 0x0;
    800070ba:	1e07b423          	sd	zero,488(a5)

    // Machine trap handling
    vm.mscratch.code = 0x0340;
    800070be:	34000693          	li	a3,832
    800070c2:	1ed7a823          	sw	a3,496(a5)
    vm.mscratch.mode = M_MODE;
    800070c6:	1ee7aa23          	sw	a4,500(a5)
    vm.mscratch.val = 0x0;
    800070ca:	1e07bc23          	sd	zero,504(a5)

    vm.mepc.code = 0x0341;
    800070ce:	34100693          	li	a3,833
    800070d2:	20d7a023          	sw	a3,512(a5)
    vm.mepc.mode = M_MODE;
    800070d6:	20e7a223          	sw	a4,516(a5)
    vm.mepc.val = 0x0;
    800070da:	2007b423          	sd	zero,520(a5)

    vm.mcause.code = 0x0342;
    800070de:	34200693          	li	a3,834
    800070e2:	20d7a823          	sw	a3,528(a5)
    vm.mcause.mode = M_MODE;
    800070e6:	20e7aa23          	sw	a4,532(a5)
    vm.mcause.val = 0x0;
    800070ea:	2007bc23          	sd	zero,536(a5)

    vm.mtval.code = 0x0343;
    800070ee:	34300693          	li	a3,835
    800070f2:	22d7a023          	sw	a3,544(a5)
    vm.mtval.mode = M_MODE;
    800070f6:	22e7a223          	sw	a4,548(a5)
    vm.mtval.val = 0x0;
    800070fa:	2207b423          	sd	zero,552(a5)

    vm.mip.code = 0x0344;
    800070fe:	34400693          	li	a3,836
    80007102:	22d7a823          	sw	a3,560(a5)
    vm.mip.mode = M_MODE;
    80007106:	22e7aa23          	sw	a4,564(a5)
    vm.mip.val = 0x0;
    8000710a:	2207bc23          	sd	zero,568(a5)

    // Machine physical memory protection
    for (int i =0; i < 16; i++) {
    8000710e:	0001c797          	auipc	a5,0x1c
    80007112:	3f278793          	addi	a5,a5,1010 # 80023500 <vm+0x240>
    80007116:	0001c617          	auipc	a2,0x1c
    8000711a:	4ea60613          	addi	a2,a2,1258 # 80023600 <vm+0x340>
    vm.mip.val = 0x0;
    8000711e:	3a000713          	li	a4,928
        vm.pmpcfg[i].code = 0x03a0 + i;
        vm.pmpcfg[i].mode = M_MODE;
    80007122:	468d                	li	a3,3
        vm.pmpcfg[i].code = 0x03a0 + i;
    80007124:	c398                	sw	a4,0(a5)
        vm.pmpcfg[i].mode = M_MODE;
    80007126:	c3d4                	sw	a3,4(a5)
        vm.pmpcfg[i].val = 0x0;
    80007128:	0007b423          	sd	zero,8(a5)
    for (int i =0; i < 16; i++) {
    8000712c:	2705                	addiw	a4,a4,1
    8000712e:	07c1                	addi	a5,a5,16
    80007130:	fec79ae3          	bne	a5,a2,80007124 <init_machine_mode_registers+0x12e>
    80007134:	0001c797          	auipc	a5,0x1c
    80007138:	4cc78793          	addi	a5,a5,1228 # 80023600 <vm+0x340>
    8000713c:	0001d617          	auipc	a2,0x1d
    80007140:	8c460613          	addi	a2,a2,-1852 # 80023a00 <vm+0x740>
    80007144:	3b000713          	li	a4,944
    }
    
    for (int i =0; i < 64; i++) {
        vm.pmpaddr[i].code = 0x03b0 + i;
        vm.pmpaddr[i].mode = M_MODE;
    80007148:	468d                	li	a3,3
        vm.pmpaddr[i].code = 0x03b0 + i;
    8000714a:	c398                	sw	a4,0(a5)
        vm.pmpaddr[i].mode = M_MODE;
    8000714c:	c3d4                	sw	a3,4(a5)
        vm.pmpaddr[i].val = 0x0;
    8000714e:	0007b423          	sd	zero,8(a5)
    for (int i =0; i < 64; i++) {
    80007152:	2705                	addiw	a4,a4,1
    80007154:	07c1                	addi	a5,a5,16
    80007156:	fec79ae3          	bne	a5,a2,8000714a <init_machine_mode_registers+0x154>
    }
}
    8000715a:	6422                	ld	s0,8(sp)
    8000715c:	0141                	addi	sp,sp,16
    8000715e:	8082                	ret

0000000080007160 <trap_and_emulate_init>:

void trap_and_emulate_init(void) {
    80007160:	1141                	addi	sp,sp,-16
    80007162:	e406                	sd	ra,8(sp)
    80007164:	e022                	sd	s0,0(sp)
    80007166:	0800                	addi	s0,sp,16
    /* Create and initialize all state for the VM */
    init_user_mode_registers();
    80007168:	00000097          	auipc	ra,0x0
    8000716c:	d48080e7          	jalr	-696(ra) # 80006eb0 <init_user_mode_registers>
    init_supervisor_mode_registers();
    80007170:	00000097          	auipc	ra,0x0
    80007174:	db0080e7          	jalr	-592(ra) # 80006f20 <init_supervisor_mode_registers>
    init_machine_mode_registers();
    80007178:	00000097          	auipc	ra,0x0
    8000717c:	e7e080e7          	jalr	-386(ra) # 80006ff6 <init_machine_mode_registers>

    vm.mvendorid.val = 0x637365353336; // Set mvendorid to "cse536" in hexadecimal
    80007180:	0001c797          	auipc	a5,0x1c
    80007184:	14078793          	addi	a5,a5,320 # 800232c0 <vm>
    80007188:	00002717          	auipc	a4,0x2
    8000718c:	e8073703          	ld	a4,-384(a4) # 80009008 <etext+0x8>
    80007190:	14e7b423          	sd	a4,328(a5)
    vm.priviledge_mode = M_MODE;       // VM should boot at M-Mode
    80007194:	470d                	li	a4,3
    80007196:	74e7b023          	sd	a4,1856(a5)
}
    8000719a:	60a2                	ld	ra,8(sp)
    8000719c:	6402                	ld	s0,0(sp)
    8000719e:	0141                	addi	sp,sp,16
    800071a0:	8082                	ret
	...

0000000080008000 <_trampoline>:
    80008000:	14051073          	csrw	sscratch,a0
    80008004:	02000537          	lui	a0,0x2000
    80008008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000800a:	0536                	slli	a0,a0,0xd
    8000800c:	02153423          	sd	ra,40(a0)
    80008010:	02253823          	sd	sp,48(a0)
    80008014:	02353c23          	sd	gp,56(a0)
    80008018:	04453023          	sd	tp,64(a0)
    8000801c:	04553423          	sd	t0,72(a0)
    80008020:	04653823          	sd	t1,80(a0)
    80008024:	04753c23          	sd	t2,88(a0)
    80008028:	f120                	sd	s0,96(a0)
    8000802a:	f524                	sd	s1,104(a0)
    8000802c:	fd2c                	sd	a1,120(a0)
    8000802e:	e150                	sd	a2,128(a0)
    80008030:	e554                	sd	a3,136(a0)
    80008032:	e958                	sd	a4,144(a0)
    80008034:	ed5c                	sd	a5,152(a0)
    80008036:	0b053023          	sd	a6,160(a0)
    8000803a:	0b153423          	sd	a7,168(a0)
    8000803e:	0b253823          	sd	s2,176(a0)
    80008042:	0b353c23          	sd	s3,184(a0)
    80008046:	0d453023          	sd	s4,192(a0)
    8000804a:	0d553423          	sd	s5,200(a0)
    8000804e:	0d653823          	sd	s6,208(a0)
    80008052:	0d753c23          	sd	s7,216(a0)
    80008056:	0f853023          	sd	s8,224(a0)
    8000805a:	0f953423          	sd	s9,232(a0)
    8000805e:	0fa53823          	sd	s10,240(a0)
    80008062:	0fb53c23          	sd	s11,248(a0)
    80008066:	11c53023          	sd	t3,256(a0)
    8000806a:	11d53423          	sd	t4,264(a0)
    8000806e:	11e53823          	sd	t5,272(a0)
    80008072:	11f53c23          	sd	t6,280(a0)
    80008076:	140022f3          	csrr	t0,sscratch
    8000807a:	06553823          	sd	t0,112(a0)
    8000807e:	00853103          	ld	sp,8(a0)
    80008082:	02053203          	ld	tp,32(a0)
    80008086:	01053283          	ld	t0,16(a0)
    8000808a:	00053303          	ld	t1,0(a0)
    8000808e:	12000073          	sfence.vma
    80008092:	18031073          	csrw	satp,t1
    80008096:	12000073          	sfence.vma
    8000809a:	8282                	jr	t0

000000008000809c <userret>:
    8000809c:	12000073          	sfence.vma
    800080a0:	18051073          	csrw	satp,a0
    800080a4:	12000073          	sfence.vma
    800080a8:	02000537          	lui	a0,0x2000
    800080ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800080ae:	0536                	slli	a0,a0,0xd
    800080b0:	02853083          	ld	ra,40(a0)
    800080b4:	03053103          	ld	sp,48(a0)
    800080b8:	03853183          	ld	gp,56(a0)
    800080bc:	04053203          	ld	tp,64(a0)
    800080c0:	04853283          	ld	t0,72(a0)
    800080c4:	05053303          	ld	t1,80(a0)
    800080c8:	05853383          	ld	t2,88(a0)
    800080cc:	7120                	ld	s0,96(a0)
    800080ce:	7524                	ld	s1,104(a0)
    800080d0:	7d2c                	ld	a1,120(a0)
    800080d2:	6150                	ld	a2,128(a0)
    800080d4:	6554                	ld	a3,136(a0)
    800080d6:	6958                	ld	a4,144(a0)
    800080d8:	6d5c                	ld	a5,152(a0)
    800080da:	0a053803          	ld	a6,160(a0)
    800080de:	0a853883          	ld	a7,168(a0)
    800080e2:	0b053903          	ld	s2,176(a0)
    800080e6:	0b853983          	ld	s3,184(a0)
    800080ea:	0c053a03          	ld	s4,192(a0)
    800080ee:	0c853a83          	ld	s5,200(a0)
    800080f2:	0d053b03          	ld	s6,208(a0)
    800080f6:	0d853b83          	ld	s7,216(a0)
    800080fa:	0e053c03          	ld	s8,224(a0)
    800080fe:	0e853c83          	ld	s9,232(a0)
    80008102:	0f053d03          	ld	s10,240(a0)
    80008106:	0f853d83          	ld	s11,248(a0)
    8000810a:	10053e03          	ld	t3,256(a0)
    8000810e:	10853e83          	ld	t4,264(a0)
    80008112:	11053f03          	ld	t5,272(a0)
    80008116:	11853f83          	ld	t6,280(a0)
    8000811a:	7928                	ld	a0,112(a0)
    8000811c:	10200073          	sret
	...
