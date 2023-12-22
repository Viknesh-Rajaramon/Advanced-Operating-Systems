
vm/vm:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <_entry>:
   0:	00001117          	auipc	sp,0x1
   4:	01010113          	addi	sp,sp,16 # 1010 <stack0>
   8:	6505                	lui	a0,0x1
   a:	f14025f3          	csrr	a1,mhartid
   e:	0585                	addi	a1,a1,1
  10:	02b50533          	mul	a0,a0,a1
  14:	912a                	add	sp,sp,a0
  16:	006000ef          	jal	ra,1c <start>

000000000000001a <spin>:
  1a:	a001                	j	1a <spin>

000000000000001c <start>:
extern void _entry(void);

// entry.S jumps here in machine mode on stack0.
void
start()
{
  1c:	1141                	addi	sp,sp,-16
  1e:	e406                	sd	ra,8(sp)
  20:	e022                	sd	s0,0(sp)
  22:	0800                	addi	s0,sp,16
  assert_linker_symbols();
  24:	00000097          	auipc	ra,0x0
  28:	262080e7          	jalr	610(ra) # 286 <assert_linker_symbols>
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
  2c:	f14027f3          	csrr	a5,mhartid

  // keep each CPU's hartid in its tp register, for cpuid().
  int id = r_mhartid();
  w_tp(id);
  30:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
  32:	823e                	mv	tp,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
  34:	300027f3          	csrr	a5,mstatus

  // set M Previous Privilege mode to Supervisor, for mret.
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
  38:	7779                	lui	a4,0xffffe
  3a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <ustack+0xfffffffffffed71f>
  3e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
  40:	6705                	lui	a4,0x1
  42:	80070713          	addi	a4,a4,-2048 # 800 <process_entry+0x3e4>
  46:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
  48:	30079073          	csrw	mstatus,a5
  asm volatile("csrw satp, %0" : : "r" (x));
  4c:	4781                	li	a5,0
  4e:	18079073          	csrw	satp,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
  52:	00000797          	auipc	a5,0x0
  56:	3b878793          	addi	a5,a5,952 # 40a <kernel_entry>
  5a:	34179073          	csrw	mepc,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
  5e:	67c1                	lui	a5,0x10
  60:	17fd                	addi	a5,a5,-1 # ffff <kstack+0x6f1f>
  62:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
  66:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
  6a:	104027f3          	csrr	a5,sie
  w_mepc((uint64)kernel_entry);

  // delegate all interrupts and exceptions to supervisor mode.
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
  6e:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
  72:	10479073          	csrw	sie,a5

  // switch to supervisor mode and jump to main().
  asm volatile("mret");
  76:	30200073          	mret
  7a:	60a2                	ld	ra,8(sp)
  7c:	6402                	ld	s0,0(sp)
  7e:	0141                	addi	sp,sp,16
  80:	8082                	ret

0000000000000082 <ramdiskrw>:

// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
ramdiskrw(struct buf *b)
{
  82:	1101                	addi	sp,sp,-32
  84:	ec06                	sd	ra,24(sp)
  86:	e822                	sd	s0,16(sp)
  88:	e426                	sd	s1,8(sp)
  8a:	1000                	addi	s0,sp,32
  8c:	84aa                	mv	s1,a0
  /* Ramdisk is not even reading from the damn file.. */
  if(b->blockno >= FSSIZE)
  8e:	4558                	lw	a4,12(a0)
  90:	7cf00793          	li	a5,1999
  94:	02e7ea63          	bltu	a5,a4,c8 <userret+0x2c>
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
  98:	44dc                	lw	a5,12(s1)
  9a:	00a7979b          	slliw	a5,a5,0xa
  9e:	1782                	slli	a5,a5,0x20
  a0:	9381                	srli	a5,a5,0x20
  char *addr = (char *)RAMDISK + diskaddr;

  // read from the location
  memmove(b->data, addr, BSIZE);
  a2:	40000613          	li	a2,1024
  a6:	02100593          	li	a1,33
  aa:	05ea                	slli	a1,a1,0x1a
  ac:	95be                	add	a1,a1,a5
  ae:	02848513          	addi	a0,s1,40
  b2:	00000097          	auipc	ra,0x0
  b6:	084080e7          	jalr	132(ra) # 136 <memmove>
  b->valid = 1;
  ba:	4785                	li	a5,1
  bc:	c09c                	sw	a5,0(s1)
}
  be:	60e2                	ld	ra,24(sp)
  c0:	6442                	ld	s0,16(sp)
  c2:	64a2                	ld	s1,8(sp)
  c4:	6105                	addi	sp,sp,32
  c6:	8082                	ret
    panic("ramdiskrw: blockno too big");
  c8:	00000517          	auipc	a0,0x0
  cc:	36850513          	addi	a0,a0,872 # 430 <process_entry+0x14>
  d0:	00000097          	auipc	ra,0x0
  d4:	1ae080e7          	jalr	430(ra) # 27e <panic>
  d8:	b7c1                	j	98 <ramdiskrw+0x16>

00000000000000da <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
  da:	1141                	addi	sp,sp,-16
  dc:	e422                	sd	s0,8(sp)
  de:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  e0:	ca19                	beqz	a2,f6 <memset+0x1c>
  e2:	87aa                	mv	a5,a0
  e4:	1602                	slli	a2,a2,0x20
  e6:	9201                	srli	a2,a2,0x20
  e8:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  ec:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  f0:	0785                	addi	a5,a5,1
  f2:	fee79de3          	bne	a5,a4,ec <memset+0x12>
  }
  return dst;
}
  f6:	6422                	ld	s0,8(sp)
  f8:	0141                	addi	sp,sp,16
  fa:	8082                	ret

00000000000000fc <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
  fc:	1141                	addi	sp,sp,-16
  fe:	e422                	sd	s0,8(sp)
 100:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
 102:	ca05                	beqz	a2,132 <memcmp+0x36>
 104:	fff6069b          	addiw	a3,a2,-1
 108:	1682                	slli	a3,a3,0x20
 10a:	9281                	srli	a3,a3,0x20
 10c:	0685                	addi	a3,a3,1
 10e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
 110:	00054783          	lbu	a5,0(a0)
 114:	0005c703          	lbu	a4,0(a1)
 118:	00e79863          	bne	a5,a4,128 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
 11c:	0505                	addi	a0,a0,1
 11e:	0585                	addi	a1,a1,1
  while(n-- > 0){
 120:	fed518e3          	bne	a0,a3,110 <memcmp+0x14>
  }

  return 0;
 124:	4501                	li	a0,0
 126:	a019                	j	12c <memcmp+0x30>
      return *s1 - *s2;
 128:	40e7853b          	subw	a0,a5,a4
}
 12c:	6422                	ld	s0,8(sp)
 12e:	0141                	addi	sp,sp,16
 130:	8082                	ret
  return 0;
 132:	4501                	li	a0,0
 134:	bfe5                	j	12c <memcmp+0x30>

0000000000000136 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
 136:	1141                	addi	sp,sp,-16
 138:	e422                	sd	s0,8(sp)
 13a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
 13c:	c205                	beqz	a2,15c <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
 13e:	02a5e263          	bltu	a1,a0,162 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
 142:	1602                	slli	a2,a2,0x20
 144:	9201                	srli	a2,a2,0x20
 146:	00c587b3          	add	a5,a1,a2
{
 14a:	872a                	mv	a4,a0
      *d++ = *s++;
 14c:	0585                	addi	a1,a1,1
 14e:	0705                	addi	a4,a4,1
 150:	fff5c683          	lbu	a3,-1(a1)
 154:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 158:	fef59ae3          	bne	a1,a5,14c <memmove+0x16>

  return dst;
}
 15c:	6422                	ld	s0,8(sp)
 15e:	0141                	addi	sp,sp,16
 160:	8082                	ret
  if(s < d && s + n > d){
 162:	02061693          	slli	a3,a2,0x20
 166:	9281                	srli	a3,a3,0x20
 168:	00d58733          	add	a4,a1,a3
 16c:	fce57be3          	bgeu	a0,a4,142 <memmove+0xc>
    d += n;
 170:	96aa                	add	a3,a3,a0
    while(n-- > 0)
 172:	fff6079b          	addiw	a5,a2,-1
 176:	1782                	slli	a5,a5,0x20
 178:	9381                	srli	a5,a5,0x20
 17a:	fff7c793          	not	a5,a5
 17e:	97ba                	add	a5,a5,a4
      *--d = *--s;
 180:	177d                	addi	a4,a4,-1
 182:	16fd                	addi	a3,a3,-1
 184:	00074603          	lbu	a2,0(a4)
 188:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
 18c:	fee79ae3          	bne	a5,a4,180 <memmove+0x4a>
 190:	b7f1                	j	15c <memmove+0x26>

0000000000000192 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
 192:	1141                	addi	sp,sp,-16
 194:	e406                	sd	ra,8(sp)
 196:	e022                	sd	s0,0(sp)
 198:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 19a:	00000097          	auipc	ra,0x0
 19e:	f9c080e7          	jalr	-100(ra) # 136 <memmove>
}
 1a2:	60a2                	ld	ra,8(sp)
 1a4:	6402                	ld	s0,0(sp)
 1a6:	0141                	addi	sp,sp,16
 1a8:	8082                	ret

00000000000001aa <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
 1aa:	1141                	addi	sp,sp,-16
 1ac:	e422                	sd	s0,8(sp)
 1ae:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
 1b0:	ce11                	beqz	a2,1cc <strncmp+0x22>
 1b2:	00054783          	lbu	a5,0(a0)
 1b6:	cf89                	beqz	a5,1d0 <strncmp+0x26>
 1b8:	0005c703          	lbu	a4,0(a1)
 1bc:	00f71a63          	bne	a4,a5,1d0 <strncmp+0x26>
    n--, p++, q++;
 1c0:	367d                	addiw	a2,a2,-1
 1c2:	0505                	addi	a0,a0,1
 1c4:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
 1c6:	f675                	bnez	a2,1b2 <strncmp+0x8>
  if(n == 0)
    return 0;
 1c8:	4501                	li	a0,0
 1ca:	a809                	j	1dc <strncmp+0x32>
 1cc:	4501                	li	a0,0
 1ce:	a039                	j	1dc <strncmp+0x32>
  if(n == 0)
 1d0:	ca09                	beqz	a2,1e2 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
 1d2:	00054503          	lbu	a0,0(a0)
 1d6:	0005c783          	lbu	a5,0(a1)
 1da:	9d1d                	subw	a0,a0,a5
}
 1dc:	6422                	ld	s0,8(sp)
 1de:	0141                	addi	sp,sp,16
 1e0:	8082                	ret
    return 0;
 1e2:	4501                	li	a0,0
 1e4:	bfe5                	j	1dc <strncmp+0x32>

00000000000001e6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
 1e6:	1141                	addi	sp,sp,-16
 1e8:	e422                	sd	s0,8(sp)
 1ea:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
 1ec:	87aa                	mv	a5,a0
 1ee:	86b2                	mv	a3,a2
 1f0:	367d                	addiw	a2,a2,-1
 1f2:	00d05963          	blez	a3,204 <strncpy+0x1e>
 1f6:	0785                	addi	a5,a5,1
 1f8:	0005c703          	lbu	a4,0(a1)
 1fc:	fee78fa3          	sb	a4,-1(a5)
 200:	0585                	addi	a1,a1,1
 202:	f775                	bnez	a4,1ee <strncpy+0x8>
    ;
  while(n-- > 0)
 204:	873e                	mv	a4,a5
 206:	9fb5                	addw	a5,a5,a3
 208:	37fd                	addiw	a5,a5,-1
 20a:	00c05963          	blez	a2,21c <strncpy+0x36>
    *s++ = 0;
 20e:	0705                	addi	a4,a4,1
 210:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
 214:	40e786bb          	subw	a3,a5,a4
 218:	fed04be3          	bgtz	a3,20e <strncpy+0x28>
  return os;
}
 21c:	6422                	ld	s0,8(sp)
 21e:	0141                	addi	sp,sp,16
 220:	8082                	ret

0000000000000222 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
 222:	1141                	addi	sp,sp,-16
 224:	e422                	sd	s0,8(sp)
 226:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
 228:	02c05363          	blez	a2,24e <safestrcpy+0x2c>
 22c:	fff6069b          	addiw	a3,a2,-1
 230:	1682                	slli	a3,a3,0x20
 232:	9281                	srli	a3,a3,0x20
 234:	96ae                	add	a3,a3,a1
 236:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
 238:	00d58963          	beq	a1,a3,24a <safestrcpy+0x28>
 23c:	0585                	addi	a1,a1,1
 23e:	0785                	addi	a5,a5,1
 240:	fff5c703          	lbu	a4,-1(a1)
 244:	fee78fa3          	sb	a4,-1(a5)
 248:	fb65                	bnez	a4,238 <safestrcpy+0x16>
    ;
  *s = 0;
 24a:	00078023          	sb	zero,0(a5)
  return os;
}
 24e:	6422                	ld	s0,8(sp)
 250:	0141                	addi	sp,sp,16
 252:	8082                	ret

0000000000000254 <strlen>:

int
strlen(const char *s)
{
 254:	1141                	addi	sp,sp,-16
 256:	e422                	sd	s0,8(sp)
 258:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 25a:	00054783          	lbu	a5,0(a0)
 25e:	cf91                	beqz	a5,27a <strlen+0x26>
 260:	0505                	addi	a0,a0,1
 262:	87aa                	mv	a5,a0
 264:	86be                	mv	a3,a5
 266:	0785                	addi	a5,a5,1
 268:	fff7c703          	lbu	a4,-1(a5)
 26c:	ff65                	bnez	a4,264 <strlen+0x10>
 26e:	40a6853b          	subw	a0,a3,a0
 272:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 274:	6422                	ld	s0,8(sp)
 276:	0141                	addi	sp,sp,16
 278:	8082                	ret
  for(n = 0; s[n]; n++)
 27a:	4501                	li	a0,0
 27c:	bfe5                	j	274 <strlen+0x20>

000000000000027e <panic>:
#include "buf.h"

#include <stdbool.h>

void panic(char *s)
{
 27e:	1141                	addi	sp,sp,-16
 280:	e422                	sd	s0,8(sp)
 282:	0800                	addi	s0,sp,16
  for(;;)
 284:	a001                	j	284 <panic+0x6>

0000000000000286 <assert_linker_symbols>:
    ;
}

int assert_linker_symbols(void) {
 286:	1141                	addi	sp,sp,-16
 288:	e422                	sd	s0,8(sp)
 28a:	0800                	addi	s0,sp,16
    return 0;
}
 28c:	4501                	li	a0,0
 28e:	6422                	ld	s0,8(sp)
 290:	0141                	addi	sp,sp,16
 292:	8082                	ret

0000000000000294 <assert_stack_address>:

int assert_stack_address(void) {
 294:	1141                	addi	sp,sp,-16
 296:	e422                	sd	s0,8(sp)
 298:	0800                	addi	s0,sp,16
    return 1;
 29a:	4505                	li	a0,1
 29c:	6422                	ld	s0,8(sp)
 29e:	0141                	addi	sp,sp,16
 2a0:	8082                	ret

00000000000002a2 <read_kernel_elf>:
#include "elf.h"

#include <stdbool.h>

// Task: Read the ELF header, perform a sanity check, and return binary entry point
uint64 read_kernel_elf(void) {
 2a2:	715d                	addi	sp,sp,-80
 2a4:	e486                	sd	ra,72(sp)
 2a6:	e0a2                	sd	s0,64(sp)
 2a8:	0880                	addi	s0,sp,80
    struct elfhdr elf;
    memmove((void*) &elf, (void*) RAMDISK, sizeof(elf));
 2aa:	04000613          	li	a2,64
 2ae:	02100593          	li	a1,33
 2b2:	05ea                	slli	a1,a1,0x1a
 2b4:	fb040513          	addi	a0,s0,-80
 2b8:	00000097          	auipc	ra,0x0
 2bc:	e7e080e7          	jalr	-386(ra) # 136 <memmove>
    if(elf.magic != ELF_MAGIC)
 2c0:	fb042703          	lw	a4,-80(s0)
 2c4:	464c47b7          	lui	a5,0x464c4
 2c8:	57f78793          	addi	a5,a5,1407 # 464c457f <ustack+0x464b349f>
 2cc:	00f71863          	bne	a4,a5,2dc <read_kernel_elf+0x3a>
        panic (NULL);
    return elf.entry;
 2d0:	fc843503          	ld	a0,-56(s0)
 2d4:	60a6                	ld	ra,72(sp)
 2d6:	6406                	ld	s0,64(sp)
 2d8:	6161                	addi	sp,sp,80
 2da:	8082                	ret
        panic (NULL);
 2dc:	4501                	li	a0,0
 2de:	00000097          	auipc	ra,0x0
 2e2:	fa0080e7          	jalr	-96(ra) # 27e <panic>
 2e6:	b7ed                	j	2d0 <read_kernel_elf+0x2e>

00000000000002e8 <kalloc>:

void usertrapret(void);

// simple page-by-page memory allocator
void* kalloc(void) {
    if (alloc_pages == KMEMSIZE) {
 2e8:	00001717          	auipc	a4,0x1
 2ec:	d1872703          	lw	a4,-744(a4) # 1000 <alloc_pages>
 2f0:	40000793          	li	a5,1024
 2f4:	02f70063          	beq	a4,a5,314 <kalloc+0x2c>
        panic("panic!");
    }
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
 2f8:	00001797          	auipc	a5,0x1
 2fc:	d0878793          	addi	a5,a5,-760 # 1000 <alloc_pages>
 300:	4388                	lw	a0,0(a5)
    alloc_pages++;
 302:	0015071b          	addiw	a4,a0,1
 306:	c398                	sw	a4,0(a5)
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
 308:	00c5151b          	slliw	a0,a0,0xc
    return (void*) addr;
}
 30c:	4785                	li	a5,1
 30e:	07fe                	slli	a5,a5,0x1f
 310:	953e                	add	a0,a0,a5
 312:	8082                	ret
void* kalloc(void) {
 314:	1141                	addi	sp,sp,-16
 316:	e406                	sd	ra,8(sp)
 318:	e022                	sd	s0,0(sp)
 31a:	0800                	addi	s0,sp,16
        panic("panic!");
 31c:	00000517          	auipc	a0,0x0
 320:	13450513          	addi	a0,a0,308 # 450 <process_entry+0x34>
 324:	00000097          	auipc	ra,0x0
 328:	f5a080e7          	jalr	-166(ra) # 27e <panic>
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
 32c:	00001797          	auipc	a5,0x1
 330:	cd478793          	addi	a5,a5,-812 # 1000 <alloc_pages>
 334:	4388                	lw	a0,0(a5)
    alloc_pages++;
 336:	0015071b          	addiw	a4,a0,1
 33a:	c398                	sw	a4,0(a5)
    uint64 addr = ((uint64)KMEMSTART+(alloc_pages*PGSIZE));
 33c:	00c5151b          	slliw	a0,a0,0xc
}
 340:	4785                	li	a5,1
 342:	07fe                	slli	a5,a5,0x1f
 344:	953e                	add	a0,a0,a5
 346:	60a2                	ld	ra,8(sp)
 348:	6402                	ld	s0,0(sp)
 34a:	0141                	addi	sp,sp,16
 34c:	8082                	ret

000000000000034e <usertrapret>:
  /* traps here when back from the userspace code. */
  p.trapframe->epc = r_sepc() + 4;
  usertrapret();
}

void usertrapret(void) {
 34e:	1141                	addi	sp,sp,-16
 350:	e422                	sd	s0,8(sp)
 352:	0800                	addi	s0,sp,16
    // Set-up for process entry and exit
    p.trapframe->kernel_sp = (uint64) kstack+PGSIZE;
 354:	00009717          	auipc	a4,0x9
 358:	cbc70713          	addi	a4,a4,-836 # 9010 <p>
 35c:	633c                	ld	a5,64(a4)
 35e:	0000a697          	auipc	a3,0xa
 362:	d8268693          	addi	a3,a3,-638 # a0e0 <kstack+0x1000>
 366:	e794                	sd	a3,8(a5)

    // Set return trap location
    p.trapframe->kernel_trap = (uint64) usertrap;
 368:	633c                	ld	a5,64(a4)
 36a:	00000697          	auipc	a3,0x0
 36e:	03868693          	addi	a3,a3,56 # 3a2 <usertrap>
 372:	eb94                	sd	a3,16(a5)
    w_stvec((uint64) p.trapframe->kernel_trap);
 374:	633c                	ld	a5,64(a4)
  asm volatile("csrw stvec, %0" : : "r" (x));
 376:	6b94                	ld	a3,16(a5)
 378:	10569073          	csrw	stvec,a3
  asm volatile("mv %0, tp" : "=r" (x) );
 37c:	8692                	mv	a3,tp

    // Save hart id
    p.trapframe->kernel_hartid = r_tp();
 37e:	f394                	sd	a3,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
 380:	100027f3          	csrr	a5,sstatus

    // set S Previous Privilege mode to User.
    unsigned long x = r_sstatus();
    x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
 384:	eff7f793          	andi	a5,a5,-257
    x |= SSTATUS_SPIE; // enable interrupts in user mode
 388:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
 38c:	10079073          	csrw	sstatus,a5
    w_sstatus(x);

    // Set entry location
    w_sepc((uint64) p.trapframe->epc);
 390:	633c                	ld	a5,64(a4)
  asm volatile("csrw sepc, %0" : : "r" (x));
 392:	6f9c                	ld	a5,24(a5)
 394:	14179073          	csrw	sepc,a5

    asm("sret");
 398:	10200073          	sret
}
 39c:	6422                	ld	s0,8(sp)
 39e:	0141                	addi	sp,sp,16
 3a0:	8082                	ret

00000000000003a2 <usertrap>:
void usertrap(void) {
 3a2:	1141                	addi	sp,sp,-16
 3a4:	e406                	sd	ra,8(sp)
 3a6:	e022                	sd	s0,0(sp)
 3a8:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, sepc" : "=r" (x) );
 3aa:	141027f3          	csrr	a5,sepc
  p.trapframe->epc = r_sepc() + 4;
 3ae:	0791                	addi	a5,a5,4
 3b0:	00009717          	auipc	a4,0x9
 3b4:	ca073703          	ld	a4,-864(a4) # 9050 <p+0x40>
 3b8:	ef1c                	sd	a5,24(a4)
  usertrapret();
 3ba:	00000097          	auipc	ra,0x0
 3be:	f94080e7          	jalr	-108(ra) # 34e <usertrapret>
}
 3c2:	60a2                	ld	ra,8(sp)
 3c4:	6402                	ld	s0,0(sp)
 3c6:	0141                	addi	sp,sp,16
 3c8:	8082                	ret

00000000000003ca <create_process>:

// Creates the user-level process and sets-up initial
void create_process(void) {
 3ca:	1141                	addi	sp,sp,-16
 3cc:	e406                	sd	ra,8(sp)
 3ce:	e022                	sd	s0,0(sp)
 3d0:	0800                	addi	s0,sp,16
    // allocate trapframe memory
    p.trapframe = (struct trapframe*) kalloc();
 3d2:	00000097          	auipc	ra,0x0
 3d6:	f16080e7          	jalr	-234(ra) # 2e8 <kalloc>
 3da:	00009797          	auipc	a5,0x9
 3de:	c3678793          	addi	a5,a5,-970 # 9010 <p>
 3e2:	e3a8                	sd	a0,64(a5)

    // entry point
    p.trapframe->epc = (uint64) process_entry;
 3e4:	00000717          	auipc	a4,0x0
 3e8:	03870713          	addi	a4,a4,56 # 41c <process_entry>
 3ec:	ed18                	sd	a4,24(a0)

    // initial stack values
    p.trapframe->a1 = (uint64) ustack+PGSIZE;
 3ee:	63bc                	ld	a5,64(a5)
 3f0:	00012717          	auipc	a4,0x12
 3f4:	cf070713          	addi	a4,a4,-784 # 120e0 <ustack+0x1000>
 3f8:	ffb8                	sd	a4,120(a5)

    // usertrapret
    usertrapret();
 3fa:	00000097          	auipc	ra,0x0
 3fe:	f54080e7          	jalr	-172(ra) # 34e <usertrapret>
}
 402:	60a2                	ld	ra,8(sp)
 404:	6402                	ld	s0,0(sp)
 406:	0141                	addi	sp,sp,16
 408:	8082                	ret

000000000000040a <kernel_entry>:

void kernel_entry(void) {
 40a:	1141                	addi	sp,sp,-16
 40c:	e406                	sd	ra,8(sp)
 40e:	e022                	sd	s0,0(sp)
 410:	0800                	addi	s0,sp,16
  create_process();
 412:	00000097          	auipc	ra,0x0
 416:	fb8080e7          	jalr	-72(ra) # 3ca <create_process>

  /* Nothing to go back to */
  while (true);
 41a:	a001                	j	41a <kernel_entry+0x10>

000000000000041c <process_entry>:
void process_entry(void) {
 41c:	1141                	addi	sp,sp,-16
 41e:	e422                	sd	s0,8(sp)
 420:	0800                	addi	s0,sp,16
  asm("ecall");
 422:	00000073          	ecall
  asm("sret");
 426:	10200073          	sret
 42a:	6422                	ld	s0,8(sp)
 42c:	0141                	addi	sp,sp,16
 42e:	8082                	ret
