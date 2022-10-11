
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	cd478793          	addi	a5,a5,-812 # 80005d30 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e2678793          	addi	a5,a5,-474 # 80000ecc <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b16080e7          	jalr	-1258(ra) # 80000c22 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	390080e7          	jalr	912(ra) # 800024b6 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	796080e7          	jalr	1942(ra) # 800008cc <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b88080e7          	jalr	-1144(ra) # 80000cd6 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7159                	addi	sp,sp,-112
    80000170:	f486                	sd	ra,104(sp)
    80000172:	f0a2                	sd	s0,96(sp)
    80000174:	eca6                	sd	s1,88(sp)
    80000176:	e8ca                	sd	s2,80(sp)
    80000178:	e4ce                	sd	s3,72(sp)
    8000017a:	e0d2                	sd	s4,64(sp)
    8000017c:	fc56                	sd	s5,56(sp)
    8000017e:	f85a                	sd	s6,48(sp)
    80000180:	f45e                	sd	s7,40(sp)
    80000182:	f062                	sd	s8,32(sp)
    80000184:	ec66                	sd	s9,24(sp)
    80000186:	e86a                	sd	s10,16(sp)
    80000188:	1880                	addi	s0,sp,112
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000194:	00011517          	auipc	a0,0x11
    80000198:	69c50513          	addi	a0,a0,1692 # 80011830 <cons>
    8000019c:	00001097          	auipc	ra,0x1
    800001a0:	a86080e7          	jalr	-1402(ra) # 80000c22 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a4:	00011497          	auipc	s1,0x11
    800001a8:	68c48493          	addi	s1,s1,1676 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ac:	00011917          	auipc	s2,0x11
    800001b0:	71c90913          	addi	s2,s2,1820 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b4:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b6:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b8:	4ca9                	li	s9,10
  while(n > 0){
    800001ba:	07305863          	blez	s3,8000022a <consoleread+0xbc>
    while(cons.r == cons.w){
    800001be:	0984a783          	lw	a5,152(s1)
    800001c2:	09c4a703          	lw	a4,156(s1)
    800001c6:	02f71463          	bne	a4,a5,800001ee <consoleread+0x80>
      if(myproc()->killed){
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	824080e7          	jalr	-2012(ra) # 800019ee <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	02c080e7          	jalr	44(ra) # 80002206 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fef700e3          	beq	a4,a5,800001ca <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000204:	077d0563          	beq	s10,s7,8000026e <consoleread+0x100>
    cbuf = c;
    80000208:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f9f40613          	addi	a2,s0,-97
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	24a080e7          	jalr	586(ra) # 80002460 <either_copyout>
    8000021e:	01850663          	beq	a0,s8,8000022a <consoleread+0xbc>
    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000226:	f99d1ae3          	bne	s10,s9,800001ba <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	60650513          	addi	a0,a0,1542 # 80011830 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	aa4080e7          	jalr	-1372(ra) # 80000cd6 <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a8e080e7          	jalr	-1394(ra) # 80000cd6 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70a6                	ld	ra,104(sp)
    80000254:	7406                	ld	s0,96(sp)
    80000256:	64e6                	ld	s1,88(sp)
    80000258:	6946                	ld	s2,80(sp)
    8000025a:	69a6                	ld	s3,72(sp)
    8000025c:	6a06                	ld	s4,64(sp)
    8000025e:	7ae2                	ld	s5,56(sp)
    80000260:	7b42                	ld	s6,48(sp)
    80000262:	7ba2                	ld	s7,40(sp)
    80000264:	7c02                	ld	s8,32(sp)
    80000266:	6ce2                	ld	s9,24(sp)
    80000268:	6d42                	ld	s10,16(sp)
    8000026a:	6165                	addi	sp,sp,112
    8000026c:	8082                	ret
      if(n < target){
    8000026e:	0009871b          	sext.w	a4,s3
    80000272:	fb677ce3          	bgeu	a4,s6,8000022a <consoleread+0xbc>
        cons.r--;
    80000276:	00011717          	auipc	a4,0x11
    8000027a:	64f72923          	sw	a5,1618(a4) # 800118c8 <cons+0x98>
    8000027e:	b775                	j	8000022a <consoleread+0xbc>

0000000080000280 <consputc>:
{
    80000280:	1141                	addi	sp,sp,-16
    80000282:	e406                	sd	ra,8(sp)
    80000284:	e022                	sd	s0,0(sp)
    80000286:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000288:	10000793          	li	a5,256
    8000028c:	00f50a63          	beq	a0,a5,800002a0 <consputc+0x20>
    uartputc_sync(c);
    80000290:	00000097          	auipc	ra,0x0
    80000294:	55e080e7          	jalr	1374(ra) # 800007ee <uartputc_sync>
}
    80000298:	60a2                	ld	ra,8(sp)
    8000029a:	6402                	ld	s0,0(sp)
    8000029c:	0141                	addi	sp,sp,16
    8000029e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a0:	4521                	li	a0,8
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	54c080e7          	jalr	1356(ra) # 800007ee <uartputc_sync>
    800002aa:	02000513          	li	a0,32
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	540080e7          	jalr	1344(ra) # 800007ee <uartputc_sync>
    800002b6:	4521                	li	a0,8
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	536080e7          	jalr	1334(ra) # 800007ee <uartputc_sync>
    800002c0:	bfe1                	j	80000298 <consputc+0x18>

00000000800002c2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c2:	1101                	addi	sp,sp,-32
    800002c4:	ec06                	sd	ra,24(sp)
    800002c6:	e822                	sd	s0,16(sp)
    800002c8:	e426                	sd	s1,8(sp)
    800002ca:	e04a                	sd	s2,0(sp)
    800002cc:	1000                	addi	s0,sp,32
    800002ce:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d0:	00011517          	auipc	a0,0x11
    800002d4:	56050513          	addi	a0,a0,1376 # 80011830 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	94a080e7          	jalr	-1718(ra) # 80000c22 <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	0af48663          	beq	s1,a5,8000038e <consoleintr+0xcc>
    800002e6:	0297ca63          	blt	a5,s1,8000031a <consoleintr+0x58>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48763          	beq	s1,a5,800003da <consoleintr+0x118>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49a63          	bne	s1,a5,80000406 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f6:	00002097          	auipc	ra,0x2
    800002fa:	216080e7          	jalr	534(ra) # 8000250c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	9d0080e7          	jalr	-1584(ra) # 80000cd6 <release>
}
    8000030e:	60e2                	ld	ra,24(sp)
    80000310:	6442                	ld	s0,16(sp)
    80000312:	64a2                	ld	s1,8(sp)
    80000314:	6902                	ld	s2,0(sp)
    80000316:	6105                	addi	sp,sp,32
    80000318:	8082                	ret
  switch(c){
    8000031a:	07f00793          	li	a5,127
    8000031e:	0af48e63          	beq	s1,a5,800003da <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000322:	00011717          	auipc	a4,0x11
    80000326:	50e70713          	addi	a4,a4,1294 # 80011830 <cons>
    8000032a:	0a072783          	lw	a5,160(a4)
    8000032e:	09872703          	lw	a4,152(a4)
    80000332:	9f99                	subw	a5,a5,a4
    80000334:	07f00713          	li	a4,127
    80000338:	fcf763e3          	bltu	a4,a5,800002fe <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033c:	47b5                	li	a5,13
    8000033e:	0cf48763          	beq	s1,a5,8000040c <consoleintr+0x14a>
      consputc(c);
    80000342:	8526                	mv	a0,s1
    80000344:	00000097          	auipc	ra,0x0
    80000348:	f3c080e7          	jalr	-196(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034c:	00011797          	auipc	a5,0x11
    80000350:	4e478793          	addi	a5,a5,1252 # 80011830 <cons>
    80000354:	0a07a703          	lw	a4,160(a5)
    80000358:	0017069b          	addiw	a3,a4,1
    8000035c:	0006861b          	sext.w	a2,a3
    80000360:	0ad7a023          	sw	a3,160(a5)
    80000364:	07f77713          	andi	a4,a4,127
    80000368:	97ba                	add	a5,a5,a4
    8000036a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036e:	47a9                	li	a5,10
    80000370:	0cf48563          	beq	s1,a5,8000043a <consoleintr+0x178>
    80000374:	4791                	li	a5,4
    80000376:	0cf48263          	beq	s1,a5,8000043a <consoleintr+0x178>
    8000037a:	00011797          	auipc	a5,0x11
    8000037e:	54e7a783          	lw	a5,1358(a5) # 800118c8 <cons+0x98>
    80000382:	0807879b          	addiw	a5,a5,128
    80000386:	f6f61ce3          	bne	a2,a5,800002fe <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038a:	863e                	mv	a2,a5
    8000038c:	a07d                	j	8000043a <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038e:	00011717          	auipc	a4,0x11
    80000392:	4a270713          	addi	a4,a4,1186 # 80011830 <cons>
    80000396:	0a072783          	lw	a5,160(a4)
    8000039a:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039e:	00011497          	auipc	s1,0x11
    800003a2:	49248493          	addi	s1,s1,1170 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a6:	4929                	li	s2,10
    800003a8:	f4f70be3          	beq	a4,a5,800002fe <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	37fd                	addiw	a5,a5,-1
    800003ae:	07f7f713          	andi	a4,a5,127
    800003b2:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b4:	01874703          	lbu	a4,24(a4)
    800003b8:	f52703e3          	beq	a4,s2,800002fe <consoleintr+0x3c>
      cons.e--;
    800003bc:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c0:	10000513          	li	a0,256
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	ebc080e7          	jalr	-324(ra) # 80000280 <consputc>
    while(cons.e != cons.w &&
    800003cc:	0a04a783          	lw	a5,160(s1)
    800003d0:	09c4a703          	lw	a4,156(s1)
    800003d4:	fcf71ce3          	bne	a4,a5,800003ac <consoleintr+0xea>
    800003d8:	b71d                	j	800002fe <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003da:	00011717          	auipc	a4,0x11
    800003de:	45670713          	addi	a4,a4,1110 # 80011830 <cons>
    800003e2:	0a072783          	lw	a5,160(a4)
    800003e6:	09c72703          	lw	a4,156(a4)
    800003ea:	f0f70ae3          	beq	a4,a5,800002fe <consoleintr+0x3c>
      cons.e--;
    800003ee:	37fd                	addiw	a5,a5,-1
    800003f0:	00011717          	auipc	a4,0x11
    800003f4:	4ef72023          	sw	a5,1248(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f8:	10000513          	li	a0,256
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e84080e7          	jalr	-380(ra) # 80000280 <consputc>
    80000404:	bded                	j	800002fe <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000406:	ee048ce3          	beqz	s1,800002fe <consoleintr+0x3c>
    8000040a:	bf21                	j	80000322 <consoleintr+0x60>
      consputc(c);
    8000040c:	4529                	li	a0,10
    8000040e:	00000097          	auipc	ra,0x0
    80000412:	e72080e7          	jalr	-398(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000416:	00011797          	auipc	a5,0x11
    8000041a:	41a78793          	addi	a5,a5,1050 # 80011830 <cons>
    8000041e:	0a07a703          	lw	a4,160(a5)
    80000422:	0017069b          	addiw	a3,a4,1
    80000426:	0006861b          	sext.w	a2,a3
    8000042a:	0ad7a023          	sw	a3,160(a5)
    8000042e:	07f77713          	andi	a4,a4,127
    80000432:	97ba                	add	a5,a5,a4
    80000434:	4729                	li	a4,10
    80000436:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043a:	00011797          	auipc	a5,0x11
    8000043e:	48c7a923          	sw	a2,1170(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000442:	00011517          	auipc	a0,0x11
    80000446:	48650513          	addi	a0,a0,1158 # 800118c8 <cons+0x98>
    8000044a:	00002097          	auipc	ra,0x2
    8000044e:	f3c080e7          	jalr	-196(ra) # 80002386 <wakeup>
    80000452:	b575                	j	800002fe <consoleintr+0x3c>

0000000080000454 <consoleinit>:

void
consoleinit(void)
{
    80000454:	1141                	addi	sp,sp,-16
    80000456:	e406                	sd	ra,8(sp)
    80000458:	e022                	sd	s0,0(sp)
    8000045a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045c:	00008597          	auipc	a1,0x8
    80000460:	bb458593          	addi	a1,a1,-1100 # 80008010 <etext+0x10>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	726080e7          	jalr	1830(ra) # 80000b92 <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	32a080e7          	jalr	810(ra) # 8000079e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00021797          	auipc	a5,0x21
    80000480:	73478793          	addi	a5,a5,1844 # 80021bb0 <devsw>
    80000484:	00000717          	auipc	a4,0x0
    80000488:	cea70713          	addi	a4,a4,-790 # 8000016e <consoleread>
    8000048c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048e:	00000717          	auipc	a4,0x0
    80000492:	c5e70713          	addi	a4,a4,-930 # 800000ec <consolewrite>
    80000496:	ef98                	sd	a4,24(a5)
}
    80000498:	60a2                	ld	ra,8(sp)
    8000049a:	6402                	ld	s0,0(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret

00000000800004a0 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a0:	7179                	addi	sp,sp,-48
    800004a2:	f406                	sd	ra,40(sp)
    800004a4:	f022                	sd	s0,32(sp)
    800004a6:	ec26                	sd	s1,24(sp)
    800004a8:	e84a                	sd	s2,16(sp)
    800004aa:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ac:	c219                	beqz	a2,800004b2 <printint+0x12>
    800004ae:	08054663          	bltz	a0,8000053a <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b2:	2501                	sext.w	a0,a0
    800004b4:	4881                	li	a7,0
    800004b6:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ba:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004bc:	2581                	sext.w	a1,a1
    800004be:	00008617          	auipc	a2,0x8
    800004c2:	b8260613          	addi	a2,a2,-1150 # 80008040 <digits>
    800004c6:	883a                	mv	a6,a4
    800004c8:	2705                	addiw	a4,a4,1
    800004ca:	02b577bb          	remuw	a5,a0,a1
    800004ce:	1782                	slli	a5,a5,0x20
    800004d0:	9381                	srli	a5,a5,0x20
    800004d2:	97b2                	add	a5,a5,a2
    800004d4:	0007c783          	lbu	a5,0(a5)
    800004d8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004dc:	0005079b          	sext.w	a5,a0
    800004e0:	02b5553b          	divuw	a0,a0,a1
    800004e4:	0685                	addi	a3,a3,1
    800004e6:	feb7f0e3          	bgeu	a5,a1,800004c6 <printint+0x26>

  if(sign)
    800004ea:	00088b63          	beqz	a7,80000500 <printint+0x60>
    buf[i++] = '-';
    800004ee:	fe040793          	addi	a5,s0,-32
    800004f2:	973e                	add	a4,a4,a5
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x8e>
    80000504:	fd040793          	addi	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	addi	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addiw	a4,a4,-1
    80000514:	1702                	slli	a4,a4,0x20
    80000516:	9301                	srli	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d60080e7          	jalr	-672(ra) # 80000280 <consputc>
  while(--i >= 0)
    80000528:	14fd                	addi	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7c>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	addi	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf9d                	j	800004b6 <printint+0x16>

0000000080000542 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000542:	1101                	addi	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	addi	s0,sp,32
    8000054c:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054e:	00011797          	auipc	a5,0x11
    80000552:	3a07a123          	sw	zero,930(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000556:	00008517          	auipc	a0,0x8
    8000055a:	ac250513          	addi	a0,a0,-1342 # 80008018 <etext+0x18>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b5850513          	addi	a0,a0,-1192 # 800080c8 <digits+0x88>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	014080e7          	jalr	20(ra) # 8000058c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000580:	4785                	li	a5,1
    80000582:	00009717          	auipc	a4,0x9
    80000586:	a6f72f23          	sw	a5,-1410(a4) # 80009000 <panicked>
  for(;;)
    8000058a:	a001                	j	8000058a <panic+0x48>

000000008000058c <printf>:
{
    8000058c:	7131                	addi	sp,sp,-192
    8000058e:	fc86                	sd	ra,120(sp)
    80000590:	f8a2                	sd	s0,112(sp)
    80000592:	f4a6                	sd	s1,104(sp)
    80000594:	f0ca                	sd	s2,96(sp)
    80000596:	ecce                	sd	s3,88(sp)
    80000598:	e8d2                	sd	s4,80(sp)
    8000059a:	e4d6                	sd	s5,72(sp)
    8000059c:	e0da                	sd	s6,64(sp)
    8000059e:	fc5e                	sd	s7,56(sp)
    800005a0:	f862                	sd	s8,48(sp)
    800005a2:	f466                	sd	s9,40(sp)
    800005a4:	f06a                	sd	s10,32(sp)
    800005a6:	ec6e                	sd	s11,24(sp)
    800005a8:	0100                	addi	s0,sp,128
    800005aa:	8a2a                	mv	s4,a0
    800005ac:	e40c                	sd	a1,8(s0)
    800005ae:	e810                	sd	a2,16(s0)
    800005b0:	ec14                	sd	a3,24(s0)
    800005b2:	f018                	sd	a4,32(s0)
    800005b4:	f41c                	sd	a5,40(s0)
    800005b6:	03043823          	sd	a6,48(s0)
    800005ba:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005be:	00011d97          	auipc	s11,0x11
    800005c2:	332dad83          	lw	s11,818(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c6:	020d9b63          	bnez	s11,800005fc <printf+0x70>
  if (fmt == 0)
    800005ca:	040a0263          	beqz	s4,8000060e <printf+0x82>
  va_start(ap, fmt);
    800005ce:	00840793          	addi	a5,s0,8
    800005d2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d6:	000a4503          	lbu	a0,0(s4)
    800005da:	14050f63          	beqz	a0,80000738 <printf+0x1ac>
    800005de:	4981                	li	s3,0
    if(c != '%'){
    800005e0:	02500a93          	li	s5,37
    switch(c){
    800005e4:	07000b93          	li	s7,112
  consputc('x');
    800005e8:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ea:	00008b17          	auipc	s6,0x8
    800005ee:	a56b0b13          	addi	s6,s6,-1450 # 80008040 <digits>
    switch(c){
    800005f2:	07300c93          	li	s9,115
    800005f6:	06400c13          	li	s8,100
    800005fa:	a82d                	j	80000634 <printf+0xa8>
    acquire(&pr.lock);
    800005fc:	00011517          	auipc	a0,0x11
    80000600:	2dc50513          	addi	a0,a0,732 # 800118d8 <pr>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	61e080e7          	jalr	1566(ra) # 80000c22 <acquire>
    8000060c:	bf7d                	j	800005ca <printf+0x3e>
    panic("null fmt");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a1a50513          	addi	a0,a0,-1510 # 80008028 <etext+0x28>
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	f2c080e7          	jalr	-212(ra) # 80000542 <panic>
      consputc(c);
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	c62080e7          	jalr	-926(ra) # 80000280 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000626:	2985                	addiw	s3,s3,1
    80000628:	013a07b3          	add	a5,s4,s3
    8000062c:	0007c503          	lbu	a0,0(a5)
    80000630:	10050463          	beqz	a0,80000738 <printf+0x1ac>
    if(c != '%'){
    80000634:	ff5515e3          	bne	a0,s5,8000061e <printf+0x92>
    c = fmt[++i] & 0xff;
    80000638:	2985                	addiw	s3,s3,1
    8000063a:	013a07b3          	add	a5,s4,s3
    8000063e:	0007c783          	lbu	a5,0(a5)
    80000642:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000646:	cbed                	beqz	a5,80000738 <printf+0x1ac>
    switch(c){
    80000648:	05778a63          	beq	a5,s7,8000069c <printf+0x110>
    8000064c:	02fbf663          	bgeu	s7,a5,80000678 <printf+0xec>
    80000650:	09978863          	beq	a5,s9,800006e0 <printf+0x154>
    80000654:	07800713          	li	a4,120
    80000658:	0ce79563          	bne	a5,a4,80000722 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065c:	f8843783          	ld	a5,-120(s0)
    80000660:	00878713          	addi	a4,a5,8
    80000664:	f8e43423          	sd	a4,-120(s0)
    80000668:	4605                	li	a2,1
    8000066a:	85ea                	mv	a1,s10
    8000066c:	4388                	lw	a0,0(a5)
    8000066e:	00000097          	auipc	ra,0x0
    80000672:	e32080e7          	jalr	-462(ra) # 800004a0 <printint>
      break;
    80000676:	bf45                	j	80000626 <printf+0x9a>
    switch(c){
    80000678:	09578f63          	beq	a5,s5,80000716 <printf+0x18a>
    8000067c:	0b879363          	bne	a5,s8,80000722 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000680:	f8843783          	ld	a5,-120(s0)
    80000684:	00878713          	addi	a4,a5,8
    80000688:	f8e43423          	sd	a4,-120(s0)
    8000068c:	4605                	li	a2,1
    8000068e:	45a9                	li	a1,10
    80000690:	4388                	lw	a0,0(a5)
    80000692:	00000097          	auipc	ra,0x0
    80000696:	e0e080e7          	jalr	-498(ra) # 800004a0 <printint>
      break;
    8000069a:	b771                	j	80000626 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069c:	f8843783          	ld	a5,-120(s0)
    800006a0:	00878713          	addi	a4,a5,8
    800006a4:	f8e43423          	sd	a4,-120(s0)
    800006a8:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006ac:	03000513          	li	a0,48
    800006b0:	00000097          	auipc	ra,0x0
    800006b4:	bd0080e7          	jalr	-1072(ra) # 80000280 <consputc>
  consputc('x');
    800006b8:	07800513          	li	a0,120
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bc4080e7          	jalr	-1084(ra) # 80000280 <consputc>
    800006c4:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c6:	03c95793          	srli	a5,s2,0x3c
    800006ca:	97da                	add	a5,a5,s6
    800006cc:	0007c503          	lbu	a0,0(a5)
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bb0080e7          	jalr	-1104(ra) # 80000280 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d8:	0912                	slli	s2,s2,0x4
    800006da:	34fd                	addiw	s1,s1,-1
    800006dc:	f4ed                	bnez	s1,800006c6 <printf+0x13a>
    800006de:	b7a1                	j	80000626 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	addi	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	6384                	ld	s1,0(a5)
    800006ee:	cc89                	beqz	s1,80000708 <printf+0x17c>
      for(; *s; s++)
    800006f0:	0004c503          	lbu	a0,0(s1)
    800006f4:	d90d                	beqz	a0,80000626 <printf+0x9a>
        consputc(*s);
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	b8a080e7          	jalr	-1142(ra) # 80000280 <consputc>
      for(; *s; s++)
    800006fe:	0485                	addi	s1,s1,1
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	f96d                	bnez	a0,800006f6 <printf+0x16a>
    80000706:	b705                	j	80000626 <printf+0x9a>
        s = "(null)";
    80000708:	00008497          	auipc	s1,0x8
    8000070c:	91848493          	addi	s1,s1,-1768 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000710:	02800513          	li	a0,40
    80000714:	b7cd                	j	800006f6 <printf+0x16a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b68080e7          	jalr	-1176(ra) # 80000280 <consputc>
      break;
    80000720:	b719                	j	80000626 <printf+0x9a>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b5c080e7          	jalr	-1188(ra) # 80000280 <consputc>
      consputc(c);
    8000072c:	8526                	mv	a0,s1
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b52080e7          	jalr	-1198(ra) # 80000280 <consputc>
      break;
    80000736:	bdc5                	j	80000626 <printf+0x9a>
  if(locking)
    80000738:	020d9163          	bnez	s11,8000075a <printf+0x1ce>
}
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	addi	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	00011517          	auipc	a0,0x11
    8000075e:	17e50513          	addi	a0,a0,382 # 800118d8 <pr>
    80000762:	00000097          	auipc	ra,0x0
    80000766:	574080e7          	jalr	1396(ra) # 80000cd6 <release>
}
    8000076a:	bfc9                	j	8000073c <printf+0x1b0>

000000008000076c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076c:	1101                	addi	sp,sp,-32
    8000076e:	ec06                	sd	ra,24(sp)
    80000770:	e822                	sd	s0,16(sp)
    80000772:	e426                	sd	s1,8(sp)
    80000774:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000776:	00011497          	auipc	s1,0x11
    8000077a:	16248493          	addi	s1,s1,354 # 800118d8 <pr>
    8000077e:	00008597          	auipc	a1,0x8
    80000782:	8ba58593          	addi	a1,a1,-1862 # 80008038 <etext+0x38>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	40a080e7          	jalr	1034(ra) # 80000b92 <initlock>
  pr.locking = 1;
    80000790:	4785                	li	a5,1
    80000792:	cc9c                	sw	a5,24(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	addi	sp,sp,32
    8000079c:	8082                	ret

000000008000079e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079e:	1141                	addi	sp,sp,-16
    800007a0:	e406                	sd	ra,8(sp)
    800007a2:	e022                	sd	s0,0(sp)
    800007a4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a6:	100007b7          	lui	a5,0x10000
    800007aa:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ae:	f8000713          	li	a4,-128
    800007b2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b6:	470d                	li	a4,3
    800007b8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007bc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c4:	469d                	li	a3,7
    800007c6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ca:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ce:	00008597          	auipc	a1,0x8
    800007d2:	88a58593          	addi	a1,a1,-1910 # 80008058 <digits+0x18>
    800007d6:	00011517          	auipc	a0,0x11
    800007da:	12250513          	addi	a0,a0,290 # 800118f8 <uart_tx_lock>
    800007de:	00000097          	auipc	ra,0x0
    800007e2:	3b4080e7          	jalr	948(ra) # 80000b92 <initlock>
}
    800007e6:	60a2                	ld	ra,8(sp)
    800007e8:	6402                	ld	s0,0(sp)
    800007ea:	0141                	addi	sp,sp,16
    800007ec:	8082                	ret

00000000800007ee <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ee:	1101                	addi	sp,sp,-32
    800007f0:	ec06                	sd	ra,24(sp)
    800007f2:	e822                	sd	s0,16(sp)
    800007f4:	e426                	sd	s1,8(sp)
    800007f6:	1000                	addi	s0,sp,32
    800007f8:	84aa                	mv	s1,a0
  push_off();
    800007fa:	00000097          	auipc	ra,0x0
    800007fe:	3dc080e7          	jalr	988(ra) # 80000bd6 <push_off>

  if(panicked){
    80000802:	00008797          	auipc	a5,0x8
    80000806:	7fe7a783          	lw	a5,2046(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080e:	c391                	beqz	a5,80000812 <uartputc_sync+0x24>
    for(;;)
    80000810:	a001                	j	80000810 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000816:	0207f793          	andi	a5,a5,32
    8000081a:	dfe5                	beqz	a5,80000812 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081c:	0ff4f513          	andi	a0,s1,255
    80000820:	100007b7          	lui	a5,0x10000
    80000824:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	44e080e7          	jalr	1102(ra) # 80000c76 <pop_off>
}
    80000830:	60e2                	ld	ra,24(sp)
    80000832:	6442                	ld	s0,16(sp)
    80000834:	64a2                	ld	s1,8(sp)
    80000836:	6105                	addi	sp,sp,32
    80000838:	8082                	ret

000000008000083a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7ca7a783          	lw	a5,1994(a5) # 80009004 <uart_tx_r>
    80000842:	00008717          	auipc	a4,0x8
    80000846:	7c672703          	lw	a4,1990(a4) # 80009008 <uart_tx_w>
    8000084a:	08f70063          	beq	a4,a5,800008ca <uartstart+0x90>
{
    8000084e:	7139                	addi	sp,sp,-64
    80000850:	fc06                	sd	ra,56(sp)
    80000852:	f822                	sd	s0,48(sp)
    80000854:	f426                	sd	s1,40(sp)
    80000856:	f04a                	sd	s2,32(sp)
    80000858:	ec4e                	sd	s3,24(sp)
    8000085a:	e852                	sd	s4,16(sp)
    8000085c:	e456                	sd	s5,8(sp)
    8000085e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000860:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000864:	00011a97          	auipc	s5,0x11
    80000868:	094a8a93          	addi	s5,s5,148 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086c:	00008497          	auipc	s1,0x8
    80000870:	79848493          	addi	s1,s1,1944 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000874:	00008a17          	auipc	s4,0x8
    80000878:	794a0a13          	addi	s4,s4,1940 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000880:	02077713          	andi	a4,a4,32
    80000884:	cb15                	beqz	a4,800008b8 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000886:	00fa8733          	add	a4,s5,a5
    8000088a:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088e:	2785                	addiw	a5,a5,1
    80000890:	41f7d71b          	sraiw	a4,a5,0x1f
    80000894:	01b7571b          	srliw	a4,a4,0x1b
    80000898:	9fb9                	addw	a5,a5,a4
    8000089a:	8bfd                	andi	a5,a5,31
    8000089c:	9f99                	subw	a5,a5,a4
    8000089e:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	ae4080e7          	jalr	-1308(ra) # 80002386 <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	409c                	lw	a5,0(s1)
    800008b0:	000a2703          	lw	a4,0(s4)
    800008b4:	fcf714e3          	bne	a4,a5,8000087c <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008de:	00011517          	auipc	a0,0x11
    800008e2:	01a50513          	addi	a0,a0,26 # 800118f8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	33c080e7          	jalr	828(ra) # 80000c22 <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	7127a783          	lw	a5,1810(a5) # 80009000 <panicked>
    800008f6:	c391                	beqz	a5,800008fa <uartputc+0x2e>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008fa:	00008697          	auipc	a3,0x8
    800008fe:	70e6a683          	lw	a3,1806(a3) # 80009008 <uart_tx_w>
    80000902:	0016879b          	addiw	a5,a3,1
    80000906:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090a:	01b7571b          	srliw	a4,a4,0x1b
    8000090e:	9fb9                	addw	a5,a5,a4
    80000910:	8bfd                	andi	a5,a5,31
    80000912:	9f99                	subw	a5,a5,a4
    80000914:	00008717          	auipc	a4,0x8
    80000918:	6f072703          	lw	a4,1776(a4) # 80009004 <uart_tx_r>
    8000091c:	04f71363          	bne	a4,a5,80000962 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000920:	00011a17          	auipc	s4,0x11
    80000924:	fd8a0a13          	addi	s4,s4,-40 # 800118f8 <uart_tx_lock>
    80000928:	00008917          	auipc	s2,0x8
    8000092c:	6dc90913          	addi	s2,s2,1756 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000930:	00008997          	auipc	s3,0x8
    80000934:	6d898993          	addi	s3,s3,1752 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000938:	85d2                	mv	a1,s4
    8000093a:	854a                	mv	a0,s2
    8000093c:	00002097          	auipc	ra,0x2
    80000940:	8ca080e7          	jalr	-1846(ra) # 80002206 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	0009a683          	lw	a3,0(s3)
    80000948:	0016879b          	addiw	a5,a3,1
    8000094c:	41f7d71b          	sraiw	a4,a5,0x1f
    80000950:	01b7571b          	srliw	a4,a4,0x1b
    80000954:	9fb9                	addw	a5,a5,a4
    80000956:	8bfd                	andi	a5,a5,31
    80000958:	9f99                	subw	a5,a5,a4
    8000095a:	00092703          	lw	a4,0(s2)
    8000095e:	fcf70de3          	beq	a4,a5,80000938 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000962:	00011917          	auipc	s2,0x11
    80000966:	f9690913          	addi	s2,s2,-106 # 800118f8 <uart_tx_lock>
    8000096a:	96ca                	add	a3,a3,s2
    8000096c:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000970:	00008717          	auipc	a4,0x8
    80000974:	68f72c23          	sw	a5,1688(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000978:	00000097          	auipc	ra,0x0
    8000097c:	ec2080e7          	jalr	-318(ra) # 8000083a <uartstart>
      release(&uart_tx_lock);
    80000980:	854a                	mv	a0,s2
    80000982:	00000097          	auipc	ra,0x0
    80000986:	354080e7          	jalr	852(ra) # 80000cd6 <release>
}
    8000098a:	70a2                	ld	ra,40(sp)
    8000098c:	7402                	ld	s0,32(sp)
    8000098e:	64e2                	ld	s1,24(sp)
    80000990:	6942                	ld	s2,16(sp)
    80000992:	69a2                	ld	s3,8(sp)
    80000994:	6a02                	ld	s4,0(sp)
    80000996:	6145                	addi	sp,sp,48
    80000998:	8082                	ret

000000008000099a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000099a:	1141                	addi	sp,sp,-16
    8000099c:	e422                	sd	s0,8(sp)
    8000099e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a0:	100007b7          	lui	a5,0x10000
    800009a4:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a8:	8b85                	andi	a5,a5,1
    800009aa:	cb91                	beqz	a5,800009be <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009ac:	100007b7          	lui	a5,0x10000
    800009b0:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b4:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b8:	6422                	ld	s0,8(sp)
    800009ba:	0141                	addi	sp,sp,16
    800009bc:	8082                	ret
    return -1;
    800009be:	557d                	li	a0,-1
    800009c0:	bfe5                	j	800009b8 <uartgetc+0x1e>

00000000800009c2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c2:	1101                	addi	sp,sp,-32
    800009c4:	ec06                	sd	ra,24(sp)
    800009c6:	e822                	sd	s0,16(sp)
    800009c8:	e426                	sd	s1,8(sp)
    800009ca:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009cc:	54fd                	li	s1,-1
    800009ce:	a029                	j	800009d8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	8f2080e7          	jalr	-1806(ra) # 800002c2 <consoleintr>
    int c = uartgetc();
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	fc2080e7          	jalr	-62(ra) # 8000099a <uartgetc>
    if(c == -1)
    800009e0:	fe9518e3          	bne	a0,s1,800009d0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e4:	00011497          	auipc	s1,0x11
    800009e8:	f1448493          	addi	s1,s1,-236 # 800118f8 <uart_tx_lock>
    800009ec:	8526                	mv	a0,s1
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	234080e7          	jalr	564(ra) # 80000c22 <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e44080e7          	jalr	-444(ra) # 8000083a <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	2d6080e7          	jalr	726(ra) # 80000cd6 <release>
}
    80000a08:	60e2                	ld	ra,24(sp)
    80000a0a:	6442                	ld	s0,16(sp)
    80000a0c:	64a2                	ld	s1,8(sp)
    80000a0e:	6105                	addi	sp,sp,32
    80000a10:	8082                	ret

0000000080000a12 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a12:	1101                	addi	sp,sp,-32
    80000a14:	ec06                	sd	ra,24(sp)
    80000a16:	e822                	sd	s0,16(sp)
    80000a18:	e426                	sd	s1,8(sp)
    80000a1a:	e04a                	sd	s2,0(sp)
    80000a1c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03451793          	slli	a5,a0,0x34
    80000a22:	ebb9                	bnez	a5,80000a78 <kfree+0x66>
    80000a24:	84aa                	mv	s1,a0
    80000a26:	00025797          	auipc	a5,0x25
    80000a2a:	5da78793          	addi	a5,a5,1498 # 80026000 <end>
    80000a2e:	04f56563          	bltu	a0,a5,80000a78 <kfree+0x66>
    80000a32:	47c5                	li	a5,17
    80000a34:	07ee                	slli	a5,a5,0x1b
    80000a36:	04f57163          	bgeu	a0,a5,80000a78 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a3a:	6605                	lui	a2,0x1
    80000a3c:	4585                	li	a1,1
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	2e0080e7          	jalr	736(ra) # 80000d1e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a46:	00011917          	auipc	s2,0x11
    80000a4a:	eea90913          	addi	s2,s2,-278 # 80011930 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	1d2080e7          	jalr	466(ra) # 80000c22 <acquire>
  r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a62:	854a                	mv	a0,s2
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	272080e7          	jalr	626(ra) # 80000cd6 <release>
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6902                	ld	s2,0(sp)
    80000a74:	6105                	addi	sp,sp,32
    80000a76:	8082                	ret
    panic("kfree");
    80000a78:	00007517          	auipc	a0,0x7
    80000a7c:	5e850513          	addi	a0,a0,1512 # 80008060 <digits+0x20>
    80000a80:	00000097          	auipc	ra,0x0
    80000a84:	ac2080e7          	jalr	-1342(ra) # 80000542 <panic>

0000000080000a88 <freerange>:
{
    80000a88:	7179                	addi	sp,sp,-48
    80000a8a:	f406                	sd	ra,40(sp)
    80000a8c:	f022                	sd	s0,32(sp)
    80000a8e:	ec26                	sd	s1,24(sp)
    80000a90:	e84a                	sd	s2,16(sp)
    80000a92:	e44e                	sd	s3,8(sp)
    80000a94:	e052                	sd	s4,0(sp)
    80000a96:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a98:	6785                	lui	a5,0x1
    80000a9a:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a9e:	94aa                	add	s1,s1,a0
    80000aa0:	757d                	lui	a0,0xfffff
    80000aa2:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa4:	94be                	add	s1,s1,a5
    80000aa6:	0095ee63          	bltu	a1,s1,80000ac2 <freerange+0x3a>
    80000aaa:	892e                	mv	s2,a1
    kfree(p);
    80000aac:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aae:	6985                	lui	s3,0x1
    kfree(p);
    80000ab0:	01448533          	add	a0,s1,s4
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	f5e080e7          	jalr	-162(ra) # 80000a12 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000abc:	94ce                	add	s1,s1,s3
    80000abe:	fe9979e3          	bgeu	s2,s1,80000ab0 <freerange+0x28>
}
    80000ac2:	70a2                	ld	ra,40(sp)
    80000ac4:	7402                	ld	s0,32(sp)
    80000ac6:	64e2                	ld	s1,24(sp)
    80000ac8:	6942                	ld	s2,16(sp)
    80000aca:	69a2                	ld	s3,8(sp)
    80000acc:	6a02                	ld	s4,0(sp)
    80000ace:	6145                	addi	sp,sp,48
    80000ad0:	8082                	ret

0000000080000ad2 <kinit>:
{
    80000ad2:	1141                	addi	sp,sp,-16
    80000ad4:	e406                	sd	ra,8(sp)
    80000ad6:	e022                	sd	s0,0(sp)
    80000ad8:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ada:	00007597          	auipc	a1,0x7
    80000ade:	58e58593          	addi	a1,a1,1422 # 80008068 <digits+0x28>
    80000ae2:	00011517          	auipc	a0,0x11
    80000ae6:	e4e50513          	addi	a0,a0,-434 # 80011930 <kmem>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	0a8080e7          	jalr	168(ra) # 80000b92 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af2:	45c5                	li	a1,17
    80000af4:	05ee                	slli	a1,a1,0x1b
    80000af6:	00025517          	auipc	a0,0x25
    80000afa:	50a50513          	addi	a0,a0,1290 # 80026000 <end>
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f8a080e7          	jalr	-118(ra) # 80000a88 <freerange>
}
    80000b06:	60a2                	ld	ra,8(sp)
    80000b08:	6402                	ld	s0,0(sp)
    80000b0a:	0141                	addi	sp,sp,16
    80000b0c:	8082                	ret

0000000080000b0e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b0e:	1101                	addi	sp,sp,-32
    80000b10:	ec06                	sd	ra,24(sp)
    80000b12:	e822                	sd	s0,16(sp)
    80000b14:	e426                	sd	s1,8(sp)
    80000b16:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b18:	00011497          	auipc	s1,0x11
    80000b1c:	e1848493          	addi	s1,s1,-488 # 80011930 <kmem>
    80000b20:	8526                	mv	a0,s1
    80000b22:	00000097          	auipc	ra,0x0
    80000b26:	100080e7          	jalr	256(ra) # 80000c22 <acquire>
  r = kmem.freelist;
    80000b2a:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2c:	c885                	beqz	s1,80000b5c <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b2e:	609c                	ld	a5,0(s1)
    80000b30:	00011517          	auipc	a0,0x11
    80000b34:	e0050513          	addi	a0,a0,-512 # 80011930 <kmem>
    80000b38:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	19c080e7          	jalr	412(ra) # 80000cd6 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b42:	6605                	lui	a2,0x1
    80000b44:	4595                	li	a1,5
    80000b46:	8526                	mv	a0,s1
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	1d6080e7          	jalr	470(ra) # 80000d1e <memset>
  return (void*)r;
}
    80000b50:	8526                	mv	a0,s1
    80000b52:	60e2                	ld	ra,24(sp)
    80000b54:	6442                	ld	s0,16(sp)
    80000b56:	64a2                	ld	s1,8(sp)
    80000b58:	6105                	addi	sp,sp,32
    80000b5a:	8082                	ret
  release(&kmem.lock);
    80000b5c:	00011517          	auipc	a0,0x11
    80000b60:	dd450513          	addi	a0,a0,-556 # 80011930 <kmem>
    80000b64:	00000097          	auipc	ra,0x0
    80000b68:	172080e7          	jalr	370(ra) # 80000cd6 <release>
  if(r)
    80000b6c:	b7d5                	j	80000b50 <kalloc+0x42>

0000000080000b6e <freememory>:

uint64
freememory(){
    80000b6e:	1141                	addi	sp,sp,-16
    80000b70:	e422                	sd	s0,8(sp)
    80000b72:	0800                	addi	s0,sp,16
  struct run* p = kmem.freelist;
    80000b74:	00011797          	auipc	a5,0x11
    80000b78:	dd47b783          	ld	a5,-556(a5) # 80011948 <kmem+0x18>
  uint64 num = 0;
  while(p){
    80000b7c:	cb89                	beqz	a5,80000b8e <freememory+0x20>
  uint64 num = 0;
    80000b7e:	4501                	li	a0,0
    num++;
    80000b80:	0505                	addi	a0,a0,1
    p = p->next;
    80000b82:	639c                	ld	a5,0(a5)
  while(p){
    80000b84:	fff5                	bnez	a5,80000b80 <freememory+0x12>
  }
  return num * PGSIZE;
}
    80000b86:	0532                	slli	a0,a0,0xc
    80000b88:	6422                	ld	s0,8(sp)
    80000b8a:	0141                	addi	sp,sp,16
    80000b8c:	8082                	ret
  uint64 num = 0;
    80000b8e:	4501                	li	a0,0
    80000b90:	bfdd                	j	80000b86 <freememory+0x18>

0000000080000b92 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b92:	1141                	addi	sp,sp,-16
    80000b94:	e422                	sd	s0,8(sp)
    80000b96:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b98:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b9a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b9e:	00053823          	sd	zero,16(a0)
}
    80000ba2:	6422                	ld	s0,8(sp)
    80000ba4:	0141                	addi	sp,sp,16
    80000ba6:	8082                	ret

0000000080000ba8 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	411c                	lw	a5,0(a0)
    80000baa:	e399                	bnez	a5,80000bb0 <holding+0x8>
    80000bac:	4501                	li	a0,0
  return r;
}
    80000bae:	8082                	ret
{
    80000bb0:	1101                	addi	sp,sp,-32
    80000bb2:	ec06                	sd	ra,24(sp)
    80000bb4:	e822                	sd	s0,16(sp)
    80000bb6:	e426                	sd	s1,8(sp)
    80000bb8:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bba:	6904                	ld	s1,16(a0)
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e16080e7          	jalr	-490(ra) # 800019d2 <mycpu>
    80000bc4:	40a48533          	sub	a0,s1,a0
    80000bc8:	00153513          	seqz	a0,a0
}
    80000bcc:	60e2                	ld	ra,24(sp)
    80000bce:	6442                	ld	s0,16(sp)
    80000bd0:	64a2                	ld	s1,8(sp)
    80000bd2:	6105                	addi	sp,sp,32
    80000bd4:	8082                	ret

0000000080000bd6 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000be0:	100024f3          	csrr	s1,sstatus
    80000be4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000be8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bea:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bee:	00001097          	auipc	ra,0x1
    80000bf2:	de4080e7          	jalr	-540(ra) # 800019d2 <mycpu>
    80000bf6:	5d3c                	lw	a5,120(a0)
    80000bf8:	cf89                	beqz	a5,80000c12 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bfa:	00001097          	auipc	ra,0x1
    80000bfe:	dd8080e7          	jalr	-552(ra) # 800019d2 <mycpu>
    80000c02:	5d3c                	lw	a5,120(a0)
    80000c04:	2785                	addiw	a5,a5,1
    80000c06:	dd3c                	sw	a5,120(a0)
}
    80000c08:	60e2                	ld	ra,24(sp)
    80000c0a:	6442                	ld	s0,16(sp)
    80000c0c:	64a2                	ld	s1,8(sp)
    80000c0e:	6105                	addi	sp,sp,32
    80000c10:	8082                	ret
    mycpu()->intena = old;
    80000c12:	00001097          	auipc	ra,0x1
    80000c16:	dc0080e7          	jalr	-576(ra) # 800019d2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c1a:	8085                	srli	s1,s1,0x1
    80000c1c:	8885                	andi	s1,s1,1
    80000c1e:	dd64                	sw	s1,124(a0)
    80000c20:	bfe9                	j	80000bfa <push_off+0x24>

0000000080000c22 <acquire>:
{
    80000c22:	1101                	addi	sp,sp,-32
    80000c24:	ec06                	sd	ra,24(sp)
    80000c26:	e822                	sd	s0,16(sp)
    80000c28:	e426                	sd	s1,8(sp)
    80000c2a:	1000                	addi	s0,sp,32
    80000c2c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c2e:	00000097          	auipc	ra,0x0
    80000c32:	fa8080e7          	jalr	-88(ra) # 80000bd6 <push_off>
  if(holding(lk))
    80000c36:	8526                	mv	a0,s1
    80000c38:	00000097          	auipc	ra,0x0
    80000c3c:	f70080e7          	jalr	-144(ra) # 80000ba8 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c40:	4705                	li	a4,1
  if(holding(lk))
    80000c42:	e115                	bnez	a0,80000c66 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c44:	87ba                	mv	a5,a4
    80000c46:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c4a:	2781                	sext.w	a5,a5
    80000c4c:	ffe5                	bnez	a5,80000c44 <acquire+0x22>
  __sync_synchronize();
    80000c4e:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c52:	00001097          	auipc	ra,0x1
    80000c56:	d80080e7          	jalr	-640(ra) # 800019d2 <mycpu>
    80000c5a:	e888                	sd	a0,16(s1)
}
    80000c5c:	60e2                	ld	ra,24(sp)
    80000c5e:	6442                	ld	s0,16(sp)
    80000c60:	64a2                	ld	s1,8(sp)
    80000c62:	6105                	addi	sp,sp,32
    80000c64:	8082                	ret
    panic("acquire");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	40a50513          	addi	a0,a0,1034 # 80008070 <digits+0x30>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8d4080e7          	jalr	-1836(ra) # 80000542 <panic>

0000000080000c76 <pop_off>:

void
pop_off(void)
{
    80000c76:	1141                	addi	sp,sp,-16
    80000c78:	e406                	sd	ra,8(sp)
    80000c7a:	e022                	sd	s0,0(sp)
    80000c7c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c7e:	00001097          	auipc	ra,0x1
    80000c82:	d54080e7          	jalr	-684(ra) # 800019d2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c8c:	e78d                	bnez	a5,80000cb6 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c8e:	5d3c                	lw	a5,120(a0)
    80000c90:	02f05b63          	blez	a5,80000cc6 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c94:	37fd                	addiw	a5,a5,-1
    80000c96:	0007871b          	sext.w	a4,a5
    80000c9a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c9c:	eb09                	bnez	a4,80000cae <pop_off+0x38>
    80000c9e:	5d7c                	lw	a5,124(a0)
    80000ca0:	c799                	beqz	a5,80000cae <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ca2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ca6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000caa:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cae:	60a2                	ld	ra,8(sp)
    80000cb0:	6402                	ld	s0,0(sp)
    80000cb2:	0141                	addi	sp,sp,16
    80000cb4:	8082                	ret
    panic("pop_off - interruptible");
    80000cb6:	00007517          	auipc	a0,0x7
    80000cba:	3c250513          	addi	a0,a0,962 # 80008078 <digits+0x38>
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	884080e7          	jalr	-1916(ra) # 80000542 <panic>
    panic("pop_off");
    80000cc6:	00007517          	auipc	a0,0x7
    80000cca:	3ca50513          	addi	a0,a0,970 # 80008090 <digits+0x50>
    80000cce:	00000097          	auipc	ra,0x0
    80000cd2:	874080e7          	jalr	-1932(ra) # 80000542 <panic>

0000000080000cd6 <release>:
{
    80000cd6:	1101                	addi	sp,sp,-32
    80000cd8:	ec06                	sd	ra,24(sp)
    80000cda:	e822                	sd	s0,16(sp)
    80000cdc:	e426                	sd	s1,8(sp)
    80000cde:	1000                	addi	s0,sp,32
    80000ce0:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ce2:	00000097          	auipc	ra,0x0
    80000ce6:	ec6080e7          	jalr	-314(ra) # 80000ba8 <holding>
    80000cea:	c115                	beqz	a0,80000d0e <release+0x38>
  lk->cpu = 0;
    80000cec:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cf0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cf4:	0f50000f          	fence	iorw,ow
    80000cf8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	f7a080e7          	jalr	-134(ra) # 80000c76 <pop_off>
}
    80000d04:	60e2                	ld	ra,24(sp)
    80000d06:	6442                	ld	s0,16(sp)
    80000d08:	64a2                	ld	s1,8(sp)
    80000d0a:	6105                	addi	sp,sp,32
    80000d0c:	8082                	ret
    panic("release");
    80000d0e:	00007517          	auipc	a0,0x7
    80000d12:	38a50513          	addi	a0,a0,906 # 80008098 <digits+0x58>
    80000d16:	00000097          	auipc	ra,0x0
    80000d1a:	82c080e7          	jalr	-2004(ra) # 80000542 <panic>

0000000080000d1e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d1e:	1141                	addi	sp,sp,-16
    80000d20:	e422                	sd	s0,8(sp)
    80000d22:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d24:	ca19                	beqz	a2,80000d3a <memset+0x1c>
    80000d26:	87aa                	mv	a5,a0
    80000d28:	1602                	slli	a2,a2,0x20
    80000d2a:	9201                	srli	a2,a2,0x20
    80000d2c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d30:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d34:	0785                	addi	a5,a5,1
    80000d36:	fee79de3          	bne	a5,a4,80000d30 <memset+0x12>
  }
  return dst;
}
    80000d3a:	6422                	ld	s0,8(sp)
    80000d3c:	0141                	addi	sp,sp,16
    80000d3e:	8082                	ret

0000000080000d40 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d46:	ca05                	beqz	a2,80000d76 <memcmp+0x36>
    80000d48:	fff6069b          	addiw	a3,a2,-1
    80000d4c:	1682                	slli	a3,a3,0x20
    80000d4e:	9281                	srli	a3,a3,0x20
    80000d50:	0685                	addi	a3,a3,1
    80000d52:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d54:	00054783          	lbu	a5,0(a0)
    80000d58:	0005c703          	lbu	a4,0(a1)
    80000d5c:	00e79863          	bne	a5,a4,80000d6c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d60:	0505                	addi	a0,a0,1
    80000d62:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d64:	fed518e3          	bne	a0,a3,80000d54 <memcmp+0x14>
  }

  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	a019                	j	80000d70 <memcmp+0x30>
      return *s1 - *s2;
    80000d6c:	40e7853b          	subw	a0,a5,a4
}
    80000d70:	6422                	ld	s0,8(sp)
    80000d72:	0141                	addi	sp,sp,16
    80000d74:	8082                	ret
  return 0;
    80000d76:	4501                	li	a0,0
    80000d78:	bfe5                	j	80000d70 <memcmp+0x30>

0000000080000d7a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d7a:	1141                	addi	sp,sp,-16
    80000d7c:	e422                	sd	s0,8(sp)
    80000d7e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d80:	02a5e563          	bltu	a1,a0,80000daa <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x2a>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x1a>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
  if(s < d && s + n > d){
    80000daa:	02061713          	slli	a4,a2,0x20
    80000dae:	9301                	srli	a4,a4,0x20
    80000db0:	00e587b3          	add	a5,a1,a4
    80000db4:	fcf578e3          	bgeu	a0,a5,80000d84 <memmove+0xa>
    d += n;
    80000db8:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dba:	fff6069b          	addiw	a3,a2,-1
    80000dbe:	d27d                	beqz	a2,80000da4 <memmove+0x2a>
    80000dc0:	02069613          	slli	a2,a3,0x20
    80000dc4:	9201                	srli	a2,a2,0x20
    80000dc6:	fff64613          	not	a2,a2
    80000dca:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dcc:	17fd                	addi	a5,a5,-1
    80000dce:	177d                	addi	a4,a4,-1
    80000dd0:	0007c683          	lbu	a3,0(a5)
    80000dd4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dd8:	fef61ae3          	bne	a2,a5,80000dcc <memmove+0x52>
    80000ddc:	b7e1                	j	80000da4 <memmove+0x2a>

0000000080000dde <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e406                	sd	ra,8(sp)
    80000de2:	e022                	sd	s0,0(sp)
    80000de4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000de6:	00000097          	auipc	ra,0x0
    80000dea:	f94080e7          	jalr	-108(ra) # 80000d7a <memmove>
}
    80000dee:	60a2                	ld	ra,8(sp)
    80000df0:	6402                	ld	s0,0(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret

0000000080000df6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000df6:	1141                	addi	sp,sp,-16
    80000df8:	e422                	sd	s0,8(sp)
    80000dfa:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dfc:	ce11                	beqz	a2,80000e18 <strncmp+0x22>
    80000dfe:	00054783          	lbu	a5,0(a0)
    80000e02:	cf89                	beqz	a5,80000e1c <strncmp+0x26>
    80000e04:	0005c703          	lbu	a4,0(a1)
    80000e08:	00f71a63          	bne	a4,a5,80000e1c <strncmp+0x26>
    n--, p++, q++;
    80000e0c:	367d                	addiw	a2,a2,-1
    80000e0e:	0505                	addi	a0,a0,1
    80000e10:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e12:	f675                	bnez	a2,80000dfe <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e14:	4501                	li	a0,0
    80000e16:	a809                	j	80000e28 <strncmp+0x32>
    80000e18:	4501                	li	a0,0
    80000e1a:	a039                	j	80000e28 <strncmp+0x32>
  if(n == 0)
    80000e1c:	ca09                	beqz	a2,80000e2e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e1e:	00054503          	lbu	a0,0(a0)
    80000e22:	0005c783          	lbu	a5,0(a1)
    80000e26:	9d1d                	subw	a0,a0,a5
}
    80000e28:	6422                	ld	s0,8(sp)
    80000e2a:	0141                	addi	sp,sp,16
    80000e2c:	8082                	ret
    return 0;
    80000e2e:	4501                	li	a0,0
    80000e30:	bfe5                	j	80000e28 <strncmp+0x32>

0000000080000e32 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e38:	872a                	mv	a4,a0
    80000e3a:	8832                	mv	a6,a2
    80000e3c:	367d                	addiw	a2,a2,-1
    80000e3e:	01005963          	blez	a6,80000e50 <strncpy+0x1e>
    80000e42:	0705                	addi	a4,a4,1
    80000e44:	0005c783          	lbu	a5,0(a1)
    80000e48:	fef70fa3          	sb	a5,-1(a4)
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	f7f5                	bnez	a5,80000e3a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e50:	86ba                	mv	a3,a4
    80000e52:	00c05c63          	blez	a2,80000e6a <strncpy+0x38>
    *s++ = 0;
    80000e56:	0685                	addi	a3,a3,1
    80000e58:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e5c:	fff6c793          	not	a5,a3
    80000e60:	9fb9                	addw	a5,a5,a4
    80000e62:	010787bb          	addw	a5,a5,a6
    80000e66:	fef048e3          	bgtz	a5,80000e56 <strncpy+0x24>
  return os;
}
    80000e6a:	6422                	ld	s0,8(sp)
    80000e6c:	0141                	addi	sp,sp,16
    80000e6e:	8082                	ret

0000000080000e70 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e70:	1141                	addi	sp,sp,-16
    80000e72:	e422                	sd	s0,8(sp)
    80000e74:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e76:	02c05363          	blez	a2,80000e9c <safestrcpy+0x2c>
    80000e7a:	fff6069b          	addiw	a3,a2,-1
    80000e7e:	1682                	slli	a3,a3,0x20
    80000e80:	9281                	srli	a3,a3,0x20
    80000e82:	96ae                	add	a3,a3,a1
    80000e84:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e86:	00d58963          	beq	a1,a3,80000e98 <safestrcpy+0x28>
    80000e8a:	0585                	addi	a1,a1,1
    80000e8c:	0785                	addi	a5,a5,1
    80000e8e:	fff5c703          	lbu	a4,-1(a1)
    80000e92:	fee78fa3          	sb	a4,-1(a5)
    80000e96:	fb65                	bnez	a4,80000e86 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e98:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e9c:	6422                	ld	s0,8(sp)
    80000e9e:	0141                	addi	sp,sp,16
    80000ea0:	8082                	ret

0000000080000ea2 <strlen>:

int
strlen(const char *s)
{
    80000ea2:	1141                	addi	sp,sp,-16
    80000ea4:	e422                	sd	s0,8(sp)
    80000ea6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ea8:	00054783          	lbu	a5,0(a0)
    80000eac:	cf91                	beqz	a5,80000ec8 <strlen+0x26>
    80000eae:	0505                	addi	a0,a0,1
    80000eb0:	87aa                	mv	a5,a0
    80000eb2:	4685                	li	a3,1
    80000eb4:	9e89                	subw	a3,a3,a0
    80000eb6:	00f6853b          	addw	a0,a3,a5
    80000eba:	0785                	addi	a5,a5,1
    80000ebc:	fff7c703          	lbu	a4,-1(a5)
    80000ec0:	fb7d                	bnez	a4,80000eb6 <strlen+0x14>
    ;
  return n;
}
    80000ec2:	6422                	ld	s0,8(sp)
    80000ec4:	0141                	addi	sp,sp,16
    80000ec6:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ec8:	4501                	li	a0,0
    80000eca:	bfe5                	j	80000ec2 <strlen+0x20>

0000000080000ecc <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ecc:	1141                	addi	sp,sp,-16
    80000ece:	e406                	sd	ra,8(sp)
    80000ed0:	e022                	sd	s0,0(sp)
    80000ed2:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	aee080e7          	jalr	-1298(ra) # 800019c2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000edc:	00008717          	auipc	a4,0x8
    80000ee0:	13070713          	addi	a4,a4,304 # 8000900c <started>
  if(cpuid() == 0){
    80000ee4:	c139                	beqz	a0,80000f2a <main+0x5e>
    while(started == 0)
    80000ee6:	431c                	lw	a5,0(a4)
    80000ee8:	2781                	sext.w	a5,a5
    80000eea:	dff5                	beqz	a5,80000ee6 <main+0x1a>
      ;
    __sync_synchronize();
    80000eec:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	ad2080e7          	jalr	-1326(ra) # 800019c2 <cpuid>
    80000ef8:	85aa                	mv	a1,a0
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1be50513          	addi	a0,a0,446 # 800080b8 <digits+0x78>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	68a080e7          	jalr	1674(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	0d8080e7          	jalr	216(ra) # 80000fe2 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f12:	00001097          	auipc	ra,0x1
    80000f16:	7f0080e7          	jalr	2032(ra) # 80002702 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f1a:	00005097          	auipc	ra,0x5
    80000f1e:	e56080e7          	jalr	-426(ra) # 80005d70 <plicinithart>
  }

  scheduler();        
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	008080e7          	jalr	8(ra) # 80001f2a <scheduler>
    consoleinit();
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	52a080e7          	jalr	1322(ra) # 80000454 <consoleinit>
    printfinit();
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	83a080e7          	jalr	-1990(ra) # 8000076c <printfinit>
    printf("\n");
    80000f3a:	00007517          	auipc	a0,0x7
    80000f3e:	18e50513          	addi	a0,a0,398 # 800080c8 <digits+0x88>
    80000f42:	fffff097          	auipc	ra,0xfffff
    80000f46:	64a080e7          	jalr	1610(ra) # 8000058c <printf>
    printf("xv6 kernel is booting\n");
    80000f4a:	00007517          	auipc	a0,0x7
    80000f4e:	15650513          	addi	a0,a0,342 # 800080a0 <digits+0x60>
    80000f52:	fffff097          	auipc	ra,0xfffff
    80000f56:	63a080e7          	jalr	1594(ra) # 8000058c <printf>
    printf("\n");
    80000f5a:	00007517          	auipc	a0,0x7
    80000f5e:	16e50513          	addi	a0,a0,366 # 800080c8 <digits+0x88>
    80000f62:	fffff097          	auipc	ra,0xfffff
    80000f66:	62a080e7          	jalr	1578(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80000f6a:	00000097          	auipc	ra,0x0
    80000f6e:	b68080e7          	jalr	-1176(ra) # 80000ad2 <kinit>
    kvminit();       // create kernel page table
    80000f72:	00000097          	auipc	ra,0x0
    80000f76:	2a0080e7          	jalr	672(ra) # 80001212 <kvminit>
    kvminithart();   // turn on paging
    80000f7a:	00000097          	auipc	ra,0x0
    80000f7e:	068080e7          	jalr	104(ra) # 80000fe2 <kvminithart>
    procinit();      // process table
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	970080e7          	jalr	-1680(ra) # 800018f2 <procinit>
    trapinit();      // trap vectors
    80000f8a:	00001097          	auipc	ra,0x1
    80000f8e:	750080e7          	jalr	1872(ra) # 800026da <trapinit>
    trapinithart();  // install kernel trap vector
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	770080e7          	jalr	1904(ra) # 80002702 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f9a:	00005097          	auipc	ra,0x5
    80000f9e:	dc0080e7          	jalr	-576(ra) # 80005d5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fa2:	00005097          	auipc	ra,0x5
    80000fa6:	dce080e7          	jalr	-562(ra) # 80005d70 <plicinithart>
    binit();         // buffer cache
    80000faa:	00002097          	auipc	ra,0x2
    80000fae:	f82080e7          	jalr	-126(ra) # 80002f2c <binit>
    iinit();         // inode cache
    80000fb2:	00002097          	auipc	ra,0x2
    80000fb6:	612080e7          	jalr	1554(ra) # 800035c4 <iinit>
    fileinit();      // file table
    80000fba:	00003097          	auipc	ra,0x3
    80000fbe:	5ac080e7          	jalr	1452(ra) # 80004566 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fc2:	00005097          	auipc	ra,0x5
    80000fc6:	eb6080e7          	jalr	-330(ra) # 80005e78 <virtio_disk_init>
    userinit();      // first user process
    80000fca:	00001097          	auipc	ra,0x1
    80000fce:	cee080e7          	jalr	-786(ra) # 80001cb8 <userinit>
    __sync_synchronize();
    80000fd2:	0ff0000f          	fence
    started = 1;
    80000fd6:	4785                	li	a5,1
    80000fd8:	00008717          	auipc	a4,0x8
    80000fdc:	02f72a23          	sw	a5,52(a4) # 8000900c <started>
    80000fe0:	b789                	j	80000f22 <main+0x56>

0000000080000fe2 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fe2:	1141                	addi	sp,sp,-16
    80000fe4:	e422                	sd	s0,8(sp)
    80000fe6:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe8:	00008797          	auipc	a5,0x8
    80000fec:	0287b783          	ld	a5,40(a5) # 80009010 <kernel_pagetable>
    80000ff0:	83b1                	srli	a5,a5,0xc
    80000ff2:	577d                	li	a4,-1
    80000ff4:	177e                	slli	a4,a4,0x3f
    80000ff6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff8:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ffc:	12000073          	sfence.vma
  sfence_vma();
}
    80001000:	6422                	ld	s0,8(sp)
    80001002:	0141                	addi	sp,sp,16
    80001004:	8082                	ret

0000000080001006 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001006:	7139                	addi	sp,sp,-64
    80001008:	fc06                	sd	ra,56(sp)
    8000100a:	f822                	sd	s0,48(sp)
    8000100c:	f426                	sd	s1,40(sp)
    8000100e:	f04a                	sd	s2,32(sp)
    80001010:	ec4e                	sd	s3,24(sp)
    80001012:	e852                	sd	s4,16(sp)
    80001014:	e456                	sd	s5,8(sp)
    80001016:	e05a                	sd	s6,0(sp)
    80001018:	0080                	addi	s0,sp,64
    8000101a:	84aa                	mv	s1,a0
    8000101c:	89ae                	mv	s3,a1
    8000101e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001020:	57fd                	li	a5,-1
    80001022:	83e9                	srli	a5,a5,0x1a
    80001024:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001026:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001028:	04b7f263          	bgeu	a5,a1,8000106c <walk+0x66>
    panic("walk");
    8000102c:	00007517          	auipc	a0,0x7
    80001030:	0a450513          	addi	a0,a0,164 # 800080d0 <digits+0x90>
    80001034:	fffff097          	auipc	ra,0xfffff
    80001038:	50e080e7          	jalr	1294(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000103c:	060a8663          	beqz	s5,800010a8 <walk+0xa2>
    80001040:	00000097          	auipc	ra,0x0
    80001044:	ace080e7          	jalr	-1330(ra) # 80000b0e <kalloc>
    80001048:	84aa                	mv	s1,a0
    8000104a:	c529                	beqz	a0,80001094 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000104c:	6605                	lui	a2,0x1
    8000104e:	4581                	li	a1,0
    80001050:	00000097          	auipc	ra,0x0
    80001054:	cce080e7          	jalr	-818(ra) # 80000d1e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001058:	00c4d793          	srli	a5,s1,0xc
    8000105c:	07aa                	slli	a5,a5,0xa
    8000105e:	0017e793          	ori	a5,a5,1
    80001062:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001066:	3a5d                	addiw	s4,s4,-9
    80001068:	036a0063          	beq	s4,s6,80001088 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000106c:	0149d933          	srl	s2,s3,s4
    80001070:	1ff97913          	andi	s2,s2,511
    80001074:	090e                	slli	s2,s2,0x3
    80001076:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001078:	00093483          	ld	s1,0(s2)
    8000107c:	0014f793          	andi	a5,s1,1
    80001080:	dfd5                	beqz	a5,8000103c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001082:	80a9                	srli	s1,s1,0xa
    80001084:	04b2                	slli	s1,s1,0xc
    80001086:	b7c5                	j	80001066 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001088:	00c9d513          	srli	a0,s3,0xc
    8000108c:	1ff57513          	andi	a0,a0,511
    80001090:	050e                	slli	a0,a0,0x3
    80001092:	9526                	add	a0,a0,s1
}
    80001094:	70e2                	ld	ra,56(sp)
    80001096:	7442                	ld	s0,48(sp)
    80001098:	74a2                	ld	s1,40(sp)
    8000109a:	7902                	ld	s2,32(sp)
    8000109c:	69e2                	ld	s3,24(sp)
    8000109e:	6a42                	ld	s4,16(sp)
    800010a0:	6aa2                	ld	s5,8(sp)
    800010a2:	6b02                	ld	s6,0(sp)
    800010a4:	6121                	addi	sp,sp,64
    800010a6:	8082                	ret
        return 0;
    800010a8:	4501                	li	a0,0
    800010aa:	b7ed                	j	80001094 <walk+0x8e>

00000000800010ac <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010ac:	57fd                	li	a5,-1
    800010ae:	83e9                	srli	a5,a5,0x1a
    800010b0:	00b7f463          	bgeu	a5,a1,800010b8 <walkaddr+0xc>
    return 0;
    800010b4:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b6:	8082                	ret
{
    800010b8:	1141                	addi	sp,sp,-16
    800010ba:	e406                	sd	ra,8(sp)
    800010bc:	e022                	sd	s0,0(sp)
    800010be:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010c0:	4601                	li	a2,0
    800010c2:	00000097          	auipc	ra,0x0
    800010c6:	f44080e7          	jalr	-188(ra) # 80001006 <walk>
  if(pte == 0)
    800010ca:	c105                	beqz	a0,800010ea <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010cc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010ce:	0117f693          	andi	a3,a5,17
    800010d2:	4745                	li	a4,17
    return 0;
    800010d4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d6:	00e68663          	beq	a3,a4,800010e2 <walkaddr+0x36>
}
    800010da:	60a2                	ld	ra,8(sp)
    800010dc:	6402                	ld	s0,0(sp)
    800010de:	0141                	addi	sp,sp,16
    800010e0:	8082                	ret
  pa = PTE2PA(*pte);
    800010e2:	00a7d513          	srli	a0,a5,0xa
    800010e6:	0532                	slli	a0,a0,0xc
  return pa;
    800010e8:	bfcd                	j	800010da <walkaddr+0x2e>
    return 0;
    800010ea:	4501                	li	a0,0
    800010ec:	b7fd                	j	800010da <walkaddr+0x2e>

00000000800010ee <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010ee:	1101                	addi	sp,sp,-32
    800010f0:	ec06                	sd	ra,24(sp)
    800010f2:	e822                	sd	s0,16(sp)
    800010f4:	e426                	sd	s1,8(sp)
    800010f6:	1000                	addi	s0,sp,32
    800010f8:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010fa:	1552                	slli	a0,a0,0x34
    800010fc:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001100:	4601                	li	a2,0
    80001102:	00008517          	auipc	a0,0x8
    80001106:	f0e53503          	ld	a0,-242(a0) # 80009010 <kernel_pagetable>
    8000110a:	00000097          	auipc	ra,0x0
    8000110e:	efc080e7          	jalr	-260(ra) # 80001006 <walk>
  if(pte == 0)
    80001112:	cd09                	beqz	a0,8000112c <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001114:	6108                	ld	a0,0(a0)
    80001116:	00157793          	andi	a5,a0,1
    8000111a:	c38d                	beqz	a5,8000113c <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000111c:	8129                	srli	a0,a0,0xa
    8000111e:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001120:	9526                	add	a0,a0,s1
    80001122:	60e2                	ld	ra,24(sp)
    80001124:	6442                	ld	s0,16(sp)
    80001126:	64a2                	ld	s1,8(sp)
    80001128:	6105                	addi	sp,sp,32
    8000112a:	8082                	ret
    panic("kvmpa");
    8000112c:	00007517          	auipc	a0,0x7
    80001130:	fac50513          	addi	a0,a0,-84 # 800080d8 <digits+0x98>
    80001134:	fffff097          	auipc	ra,0xfffff
    80001138:	40e080e7          	jalr	1038(ra) # 80000542 <panic>
    panic("kvmpa");
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	f9c50513          	addi	a0,a0,-100 # 800080d8 <digits+0x98>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	3fe080e7          	jalr	1022(ra) # 80000542 <panic>

000000008000114c <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000114c:	715d                	addi	sp,sp,-80
    8000114e:	e486                	sd	ra,72(sp)
    80001150:	e0a2                	sd	s0,64(sp)
    80001152:	fc26                	sd	s1,56(sp)
    80001154:	f84a                	sd	s2,48(sp)
    80001156:	f44e                	sd	s3,40(sp)
    80001158:	f052                	sd	s4,32(sp)
    8000115a:	ec56                	sd	s5,24(sp)
    8000115c:	e85a                	sd	s6,16(sp)
    8000115e:	e45e                	sd	s7,8(sp)
    80001160:	0880                	addi	s0,sp,80
    80001162:	8aaa                	mv	s5,a0
    80001164:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001166:	777d                	lui	a4,0xfffff
    80001168:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000116c:	167d                	addi	a2,a2,-1
    8000116e:	00b609b3          	add	s3,a2,a1
    80001172:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001176:	893e                	mv	s2,a5
    80001178:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000117c:	6b85                	lui	s7,0x1
    8000117e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001182:	4605                	li	a2,1
    80001184:	85ca                	mv	a1,s2
    80001186:	8556                	mv	a0,s5
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	e7e080e7          	jalr	-386(ra) # 80001006 <walk>
    80001190:	c51d                	beqz	a0,800011be <mappages+0x72>
    if(*pte & PTE_V)
    80001192:	611c                	ld	a5,0(a0)
    80001194:	8b85                	andi	a5,a5,1
    80001196:	ef81                	bnez	a5,800011ae <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001198:	80b1                	srli	s1,s1,0xc
    8000119a:	04aa                	slli	s1,s1,0xa
    8000119c:	0164e4b3          	or	s1,s1,s6
    800011a0:	0014e493          	ori	s1,s1,1
    800011a4:	e104                	sd	s1,0(a0)
    if(a == last)
    800011a6:	03390863          	beq	s2,s3,800011d6 <mappages+0x8a>
    a += PGSIZE;
    800011aa:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011ac:	bfc9                	j	8000117e <mappages+0x32>
      panic("remap");
    800011ae:	00007517          	auipc	a0,0x7
    800011b2:	f3250513          	addi	a0,a0,-206 # 800080e0 <digits+0xa0>
    800011b6:	fffff097          	auipc	ra,0xfffff
    800011ba:	38c080e7          	jalr	908(ra) # 80000542 <panic>
      return -1;
    800011be:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011c0:	60a6                	ld	ra,72(sp)
    800011c2:	6406                	ld	s0,64(sp)
    800011c4:	74e2                	ld	s1,56(sp)
    800011c6:	7942                	ld	s2,48(sp)
    800011c8:	79a2                	ld	s3,40(sp)
    800011ca:	7a02                	ld	s4,32(sp)
    800011cc:	6ae2                	ld	s5,24(sp)
    800011ce:	6b42                	ld	s6,16(sp)
    800011d0:	6ba2                	ld	s7,8(sp)
    800011d2:	6161                	addi	sp,sp,80
    800011d4:	8082                	ret
  return 0;
    800011d6:	4501                	li	a0,0
    800011d8:	b7e5                	j	800011c0 <mappages+0x74>

00000000800011da <kvmmap>:
{
    800011da:	1141                	addi	sp,sp,-16
    800011dc:	e406                	sd	ra,8(sp)
    800011de:	e022                	sd	s0,0(sp)
    800011e0:	0800                	addi	s0,sp,16
    800011e2:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011e4:	86ae                	mv	a3,a1
    800011e6:	85aa                	mv	a1,a0
    800011e8:	00008517          	auipc	a0,0x8
    800011ec:	e2853503          	ld	a0,-472(a0) # 80009010 <kernel_pagetable>
    800011f0:	00000097          	auipc	ra,0x0
    800011f4:	f5c080e7          	jalr	-164(ra) # 8000114c <mappages>
    800011f8:	e509                	bnez	a0,80001202 <kvmmap+0x28>
}
    800011fa:	60a2                	ld	ra,8(sp)
    800011fc:	6402                	ld	s0,0(sp)
    800011fe:	0141                	addi	sp,sp,16
    80001200:	8082                	ret
    panic("kvmmap");
    80001202:	00007517          	auipc	a0,0x7
    80001206:	ee650513          	addi	a0,a0,-282 # 800080e8 <digits+0xa8>
    8000120a:	fffff097          	auipc	ra,0xfffff
    8000120e:	338080e7          	jalr	824(ra) # 80000542 <panic>

0000000080001212 <kvminit>:
{
    80001212:	1101                	addi	sp,sp,-32
    80001214:	ec06                	sd	ra,24(sp)
    80001216:	e822                	sd	s0,16(sp)
    80001218:	e426                	sd	s1,8(sp)
    8000121a:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000121c:	00000097          	auipc	ra,0x0
    80001220:	8f2080e7          	jalr	-1806(ra) # 80000b0e <kalloc>
    80001224:	00008797          	auipc	a5,0x8
    80001228:	dea7b623          	sd	a0,-532(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000122c:	6605                	lui	a2,0x1
    8000122e:	4581                	li	a1,0
    80001230:	00000097          	auipc	ra,0x0
    80001234:	aee080e7          	jalr	-1298(ra) # 80000d1e <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001238:	4699                	li	a3,6
    8000123a:	6605                	lui	a2,0x1
    8000123c:	100005b7          	lui	a1,0x10000
    80001240:	10000537          	lui	a0,0x10000
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f96080e7          	jalr	-106(ra) # 800011da <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000124c:	4699                	li	a3,6
    8000124e:	6605                	lui	a2,0x1
    80001250:	100015b7          	lui	a1,0x10001
    80001254:	10001537          	lui	a0,0x10001
    80001258:	00000097          	auipc	ra,0x0
    8000125c:	f82080e7          	jalr	-126(ra) # 800011da <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001260:	4699                	li	a3,6
    80001262:	6641                	lui	a2,0x10
    80001264:	020005b7          	lui	a1,0x2000
    80001268:	02000537          	lui	a0,0x2000
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f6e080e7          	jalr	-146(ra) # 800011da <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	00400637          	lui	a2,0x400
    8000127a:	0c0005b7          	lui	a1,0xc000
    8000127e:	0c000537          	lui	a0,0xc000
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f58080e7          	jalr	-168(ra) # 800011da <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000128a:	00007497          	auipc	s1,0x7
    8000128e:	d7648493          	addi	s1,s1,-650 # 80008000 <etext>
    80001292:	46a9                	li	a3,10
    80001294:	80007617          	auipc	a2,0x80007
    80001298:	d6c60613          	addi	a2,a2,-660 # 8000 <_entry-0x7fff8000>
    8000129c:	4585                	li	a1,1
    8000129e:	05fe                	slli	a1,a1,0x1f
    800012a0:	852e                	mv	a0,a1
    800012a2:	00000097          	auipc	ra,0x0
    800012a6:	f38080e7          	jalr	-200(ra) # 800011da <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012aa:	4699                	li	a3,6
    800012ac:	4645                	li	a2,17
    800012ae:	066e                	slli	a2,a2,0x1b
    800012b0:	8e05                	sub	a2,a2,s1
    800012b2:	85a6                	mv	a1,s1
    800012b4:	8526                	mv	a0,s1
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	f24080e7          	jalr	-220(ra) # 800011da <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012be:	46a9                	li	a3,10
    800012c0:	6605                	lui	a2,0x1
    800012c2:	00006597          	auipc	a1,0x6
    800012c6:	d3e58593          	addi	a1,a1,-706 # 80007000 <_trampoline>
    800012ca:	04000537          	lui	a0,0x4000
    800012ce:	157d                	addi	a0,a0,-1
    800012d0:	0532                	slli	a0,a0,0xc
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	f08080e7          	jalr	-248(ra) # 800011da <kvmmap>
}
    800012da:	60e2                	ld	ra,24(sp)
    800012dc:	6442                	ld	s0,16(sp)
    800012de:	64a2                	ld	s1,8(sp)
    800012e0:	6105                	addi	sp,sp,32
    800012e2:	8082                	ret

00000000800012e4 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012e4:	715d                	addi	sp,sp,-80
    800012e6:	e486                	sd	ra,72(sp)
    800012e8:	e0a2                	sd	s0,64(sp)
    800012ea:	fc26                	sd	s1,56(sp)
    800012ec:	f84a                	sd	s2,48(sp)
    800012ee:	f44e                	sd	s3,40(sp)
    800012f0:	f052                	sd	s4,32(sp)
    800012f2:	ec56                	sd	s5,24(sp)
    800012f4:	e85a                	sd	s6,16(sp)
    800012f6:	e45e                	sd	s7,8(sp)
    800012f8:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012fa:	03459793          	slli	a5,a1,0x34
    800012fe:	e795                	bnez	a5,8000132a <uvmunmap+0x46>
    80001300:	8a2a                	mv	s4,a0
    80001302:	892e                	mv	s2,a1
    80001304:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001306:	0632                	slli	a2,a2,0xc
    80001308:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130e:	6b05                	lui	s6,0x1
    80001310:	0735e263          	bltu	a1,s3,80001374 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001314:	60a6                	ld	ra,72(sp)
    80001316:	6406                	ld	s0,64(sp)
    80001318:	74e2                	ld	s1,56(sp)
    8000131a:	7942                	ld	s2,48(sp)
    8000131c:	79a2                	ld	s3,40(sp)
    8000131e:	7a02                	ld	s4,32(sp)
    80001320:	6ae2                	ld	s5,24(sp)
    80001322:	6b42                	ld	s6,16(sp)
    80001324:	6ba2                	ld	s7,8(sp)
    80001326:	6161                	addi	sp,sp,80
    80001328:	8082                	ret
    panic("uvmunmap: not aligned");
    8000132a:	00007517          	auipc	a0,0x7
    8000132e:	dc650513          	addi	a0,a0,-570 # 800080f0 <digits+0xb0>
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	210080e7          	jalr	528(ra) # 80000542 <panic>
      panic("uvmunmap: walk");
    8000133a:	00007517          	auipc	a0,0x7
    8000133e:	dce50513          	addi	a0,a0,-562 # 80008108 <digits+0xc8>
    80001342:	fffff097          	auipc	ra,0xfffff
    80001346:	200080e7          	jalr	512(ra) # 80000542 <panic>
      panic("uvmunmap: not mapped");
    8000134a:	00007517          	auipc	a0,0x7
    8000134e:	dce50513          	addi	a0,a0,-562 # 80008118 <digits+0xd8>
    80001352:	fffff097          	auipc	ra,0xfffff
    80001356:	1f0080e7          	jalr	496(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    8000135a:	00007517          	auipc	a0,0x7
    8000135e:	dd650513          	addi	a0,a0,-554 # 80008130 <digits+0xf0>
    80001362:	fffff097          	auipc	ra,0xfffff
    80001366:	1e0080e7          	jalr	480(ra) # 80000542 <panic>
    *pte = 0;
    8000136a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000136e:	995a                	add	s2,s2,s6
    80001370:	fb3972e3          	bgeu	s2,s3,80001314 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001374:	4601                	li	a2,0
    80001376:	85ca                	mv	a1,s2
    80001378:	8552                	mv	a0,s4
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	c8c080e7          	jalr	-884(ra) # 80001006 <walk>
    80001382:	84aa                	mv	s1,a0
    80001384:	d95d                	beqz	a0,8000133a <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001386:	6108                	ld	a0,0(a0)
    80001388:	00157793          	andi	a5,a0,1
    8000138c:	dfdd                	beqz	a5,8000134a <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000138e:	3ff57793          	andi	a5,a0,1023
    80001392:	fd7784e3          	beq	a5,s7,8000135a <uvmunmap+0x76>
    if(do_free){
    80001396:	fc0a8ae3          	beqz	s5,8000136a <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000139a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000139c:	0532                	slli	a0,a0,0xc
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	674080e7          	jalr	1652(ra) # 80000a12 <kfree>
    800013a6:	b7d1                	j	8000136a <uvmunmap+0x86>

00000000800013a8 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013a8:	1101                	addi	sp,sp,-32
    800013aa:	ec06                	sd	ra,24(sp)
    800013ac:	e822                	sd	s0,16(sp)
    800013ae:	e426                	sd	s1,8(sp)
    800013b0:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013b2:	fffff097          	auipc	ra,0xfffff
    800013b6:	75c080e7          	jalr	1884(ra) # 80000b0e <kalloc>
    800013ba:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013bc:	c519                	beqz	a0,800013ca <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013be:	6605                	lui	a2,0x1
    800013c0:	4581                	li	a1,0
    800013c2:	00000097          	auipc	ra,0x0
    800013c6:	95c080e7          	jalr	-1700(ra) # 80000d1e <memset>
  return pagetable;
}
    800013ca:	8526                	mv	a0,s1
    800013cc:	60e2                	ld	ra,24(sp)
    800013ce:	6442                	ld	s0,16(sp)
    800013d0:	64a2                	ld	s1,8(sp)
    800013d2:	6105                	addi	sp,sp,32
    800013d4:	8082                	ret

00000000800013d6 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013d6:	7179                	addi	sp,sp,-48
    800013d8:	f406                	sd	ra,40(sp)
    800013da:	f022                	sd	s0,32(sp)
    800013dc:	ec26                	sd	s1,24(sp)
    800013de:	e84a                	sd	s2,16(sp)
    800013e0:	e44e                	sd	s3,8(sp)
    800013e2:	e052                	sd	s4,0(sp)
    800013e4:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013e6:	6785                	lui	a5,0x1
    800013e8:	04f67863          	bgeu	a2,a5,80001438 <uvminit+0x62>
    800013ec:	8a2a                	mv	s4,a0
    800013ee:	89ae                	mv	s3,a1
    800013f0:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013f2:	fffff097          	auipc	ra,0xfffff
    800013f6:	71c080e7          	jalr	1820(ra) # 80000b0e <kalloc>
    800013fa:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013fc:	6605                	lui	a2,0x1
    800013fe:	4581                	li	a1,0
    80001400:	00000097          	auipc	ra,0x0
    80001404:	91e080e7          	jalr	-1762(ra) # 80000d1e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001408:	4779                	li	a4,30
    8000140a:	86ca                	mv	a3,s2
    8000140c:	6605                	lui	a2,0x1
    8000140e:	4581                	li	a1,0
    80001410:	8552                	mv	a0,s4
    80001412:	00000097          	auipc	ra,0x0
    80001416:	d3a080e7          	jalr	-710(ra) # 8000114c <mappages>
  memmove(mem, src, sz);
    8000141a:	8626                	mv	a2,s1
    8000141c:	85ce                	mv	a1,s3
    8000141e:	854a                	mv	a0,s2
    80001420:	00000097          	auipc	ra,0x0
    80001424:	95a080e7          	jalr	-1702(ra) # 80000d7a <memmove>
}
    80001428:	70a2                	ld	ra,40(sp)
    8000142a:	7402                	ld	s0,32(sp)
    8000142c:	64e2                	ld	s1,24(sp)
    8000142e:	6942                	ld	s2,16(sp)
    80001430:	69a2                	ld	s3,8(sp)
    80001432:	6a02                	ld	s4,0(sp)
    80001434:	6145                	addi	sp,sp,48
    80001436:	8082                	ret
    panic("inituvm: more than a page");
    80001438:	00007517          	auipc	a0,0x7
    8000143c:	d1050513          	addi	a0,a0,-752 # 80008148 <digits+0x108>
    80001440:	fffff097          	auipc	ra,0xfffff
    80001444:	102080e7          	jalr	258(ra) # 80000542 <panic>

0000000080001448 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001448:	1101                	addi	sp,sp,-32
    8000144a:	ec06                	sd	ra,24(sp)
    8000144c:	e822                	sd	s0,16(sp)
    8000144e:	e426                	sd	s1,8(sp)
    80001450:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001452:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001454:	00b67d63          	bgeu	a2,a1,8000146e <uvmdealloc+0x26>
    80001458:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000145a:	6785                	lui	a5,0x1
    8000145c:	17fd                	addi	a5,a5,-1
    8000145e:	00f60733          	add	a4,a2,a5
    80001462:	767d                	lui	a2,0xfffff
    80001464:	8f71                	and	a4,a4,a2
    80001466:	97ae                	add	a5,a5,a1
    80001468:	8ff1                	and	a5,a5,a2
    8000146a:	00f76863          	bltu	a4,a5,8000147a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000146e:	8526                	mv	a0,s1
    80001470:	60e2                	ld	ra,24(sp)
    80001472:	6442                	ld	s0,16(sp)
    80001474:	64a2                	ld	s1,8(sp)
    80001476:	6105                	addi	sp,sp,32
    80001478:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000147a:	8f99                	sub	a5,a5,a4
    8000147c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000147e:	4685                	li	a3,1
    80001480:	0007861b          	sext.w	a2,a5
    80001484:	85ba                	mv	a1,a4
    80001486:	00000097          	auipc	ra,0x0
    8000148a:	e5e080e7          	jalr	-418(ra) # 800012e4 <uvmunmap>
    8000148e:	b7c5                	j	8000146e <uvmdealloc+0x26>

0000000080001490 <uvmalloc>:
  if(newsz < oldsz)
    80001490:	0ab66163          	bltu	a2,a1,80001532 <uvmalloc+0xa2>
{
    80001494:	7139                	addi	sp,sp,-64
    80001496:	fc06                	sd	ra,56(sp)
    80001498:	f822                	sd	s0,48(sp)
    8000149a:	f426                	sd	s1,40(sp)
    8000149c:	f04a                	sd	s2,32(sp)
    8000149e:	ec4e                	sd	s3,24(sp)
    800014a0:	e852                	sd	s4,16(sp)
    800014a2:	e456                	sd	s5,8(sp)
    800014a4:	0080                	addi	s0,sp,64
    800014a6:	8aaa                	mv	s5,a0
    800014a8:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014aa:	6985                	lui	s3,0x1
    800014ac:	19fd                	addi	s3,s3,-1
    800014ae:	95ce                	add	a1,a1,s3
    800014b0:	79fd                	lui	s3,0xfffff
    800014b2:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b6:	08c9f063          	bgeu	s3,a2,80001536 <uvmalloc+0xa6>
    800014ba:	894e                	mv	s2,s3
    mem = kalloc();
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	652080e7          	jalr	1618(ra) # 80000b0e <kalloc>
    800014c4:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c6:	c51d                	beqz	a0,800014f4 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014c8:	6605                	lui	a2,0x1
    800014ca:	4581                	li	a1,0
    800014cc:	00000097          	auipc	ra,0x0
    800014d0:	852080e7          	jalr	-1966(ra) # 80000d1e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014d4:	4779                	li	a4,30
    800014d6:	86a6                	mv	a3,s1
    800014d8:	6605                	lui	a2,0x1
    800014da:	85ca                	mv	a1,s2
    800014dc:	8556                	mv	a0,s5
    800014de:	00000097          	auipc	ra,0x0
    800014e2:	c6e080e7          	jalr	-914(ra) # 8000114c <mappages>
    800014e6:	e905                	bnez	a0,80001516 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e8:	6785                	lui	a5,0x1
    800014ea:	993e                	add	s2,s2,a5
    800014ec:	fd4968e3          	bltu	s2,s4,800014bc <uvmalloc+0x2c>
  return newsz;
    800014f0:	8552                	mv	a0,s4
    800014f2:	a809                	j	80001504 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014f4:	864e                	mv	a2,s3
    800014f6:	85ca                	mv	a1,s2
    800014f8:	8556                	mv	a0,s5
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	f4e080e7          	jalr	-178(ra) # 80001448 <uvmdealloc>
      return 0;
    80001502:	4501                	li	a0,0
}
    80001504:	70e2                	ld	ra,56(sp)
    80001506:	7442                	ld	s0,48(sp)
    80001508:	74a2                	ld	s1,40(sp)
    8000150a:	7902                	ld	s2,32(sp)
    8000150c:	69e2                	ld	s3,24(sp)
    8000150e:	6a42                	ld	s4,16(sp)
    80001510:	6aa2                	ld	s5,8(sp)
    80001512:	6121                	addi	sp,sp,64
    80001514:	8082                	ret
      kfree(mem);
    80001516:	8526                	mv	a0,s1
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	4fa080e7          	jalr	1274(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001520:	864e                	mv	a2,s3
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	f22080e7          	jalr	-222(ra) # 80001448 <uvmdealloc>
      return 0;
    8000152e:	4501                	li	a0,0
    80001530:	bfd1                	j	80001504 <uvmalloc+0x74>
    return oldsz;
    80001532:	852e                	mv	a0,a1
}
    80001534:	8082                	ret
  return newsz;
    80001536:	8532                	mv	a0,a2
    80001538:	b7f1                	j	80001504 <uvmalloc+0x74>

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
    80001554:	a821                	j	8000156c <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001556:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001558:	0532                	slli	a0,a0,0xc
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	fe0080e7          	jalr	-32(ra) # 8000153a <freewalk>
      pagetable[i] = 0;
    80001562:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001566:	04a1                	addi	s1,s1,8
    80001568:	03248163          	beq	s1,s2,8000158a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000156c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000156e:	00f57793          	andi	a5,a0,15
    80001572:	ff3782e3          	beq	a5,s3,80001556 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001576:	8905                	andi	a0,a0,1
    80001578:	d57d                	beqz	a0,80001566 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000157a:	00007517          	auipc	a0,0x7
    8000157e:	bee50513          	addi	a0,a0,-1042 # 80008168 <digits+0x128>
    80001582:	fffff097          	auipc	ra,0xfffff
    80001586:	fc0080e7          	jalr	-64(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158a:	8552                	mv	a0,s4
    8000158c:	fffff097          	auipc	ra,0xfffff
    80001590:	486080e7          	jalr	1158(ra) # 80000a12 <kfree>
}
    80001594:	70a2                	ld	ra,40(sp)
    80001596:	7402                	ld	s0,32(sp)
    80001598:	64e2                	ld	s1,24(sp)
    8000159a:	6942                	ld	s2,16(sp)
    8000159c:	69a2                	ld	s3,8(sp)
    8000159e:	6a02                	ld	s4,0(sp)
    800015a0:	6145                	addi	sp,sp,48
    800015a2:	8082                	ret

00000000800015a4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a4:	1101                	addi	sp,sp,-32
    800015a6:	ec06                	sd	ra,24(sp)
    800015a8:	e822                	sd	s0,16(sp)
    800015aa:	e426                	sd	s1,8(sp)
    800015ac:	1000                	addi	s0,sp,32
    800015ae:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b0:	e999                	bnez	a1,800015c6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b2:	8526                	mv	a0,s1
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	f86080e7          	jalr	-122(ra) # 8000153a <freewalk>
}
    800015bc:	60e2                	ld	ra,24(sp)
    800015be:	6442                	ld	s0,16(sp)
    800015c0:	64a2                	ld	s1,8(sp)
    800015c2:	6105                	addi	sp,sp,32
    800015c4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c6:	6605                	lui	a2,0x1
    800015c8:	167d                	addi	a2,a2,-1
    800015ca:	962e                	add	a2,a2,a1
    800015cc:	4685                	li	a3,1
    800015ce:	8231                	srli	a2,a2,0xc
    800015d0:	4581                	li	a1,0
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	d12080e7          	jalr	-750(ra) # 800012e4 <uvmunmap>
    800015da:	bfe1                	j	800015b2 <uvmfree+0xe>

00000000800015dc <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015dc:	c679                	beqz	a2,800016aa <uvmcopy+0xce>
{
    800015de:	715d                	addi	sp,sp,-80
    800015e0:	e486                	sd	ra,72(sp)
    800015e2:	e0a2                	sd	s0,64(sp)
    800015e4:	fc26                	sd	s1,56(sp)
    800015e6:	f84a                	sd	s2,48(sp)
    800015e8:	f44e                	sd	s3,40(sp)
    800015ea:	f052                	sd	s4,32(sp)
    800015ec:	ec56                	sd	s5,24(sp)
    800015ee:	e85a                	sd	s6,16(sp)
    800015f0:	e45e                	sd	s7,8(sp)
    800015f2:	0880                	addi	s0,sp,80
    800015f4:	8b2a                	mv	s6,a0
    800015f6:	8aae                	mv	s5,a1
    800015f8:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fa:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015fc:	4601                	li	a2,0
    800015fe:	85ce                	mv	a1,s3
    80001600:	855a                	mv	a0,s6
    80001602:	00000097          	auipc	ra,0x0
    80001606:	a04080e7          	jalr	-1532(ra) # 80001006 <walk>
    8000160a:	c531                	beqz	a0,80001656 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000160c:	6118                	ld	a4,0(a0)
    8000160e:	00177793          	andi	a5,a4,1
    80001612:	cbb1                	beqz	a5,80001666 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001614:	00a75593          	srli	a1,a4,0xa
    80001618:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000161c:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001620:	fffff097          	auipc	ra,0xfffff
    80001624:	4ee080e7          	jalr	1262(ra) # 80000b0e <kalloc>
    80001628:	892a                	mv	s2,a0
    8000162a:	c939                	beqz	a0,80001680 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000162c:	6605                	lui	a2,0x1
    8000162e:	85de                	mv	a1,s7
    80001630:	fffff097          	auipc	ra,0xfffff
    80001634:	74a080e7          	jalr	1866(ra) # 80000d7a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001638:	8726                	mv	a4,s1
    8000163a:	86ca                	mv	a3,s2
    8000163c:	6605                	lui	a2,0x1
    8000163e:	85ce                	mv	a1,s3
    80001640:	8556                	mv	a0,s5
    80001642:	00000097          	auipc	ra,0x0
    80001646:	b0a080e7          	jalr	-1270(ra) # 8000114c <mappages>
    8000164a:	e515                	bnez	a0,80001676 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000164c:	6785                	lui	a5,0x1
    8000164e:	99be                	add	s3,s3,a5
    80001650:	fb49e6e3          	bltu	s3,s4,800015fc <uvmcopy+0x20>
    80001654:	a081                	j	80001694 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001656:	00007517          	auipc	a0,0x7
    8000165a:	b2250513          	addi	a0,a0,-1246 # 80008178 <digits+0x138>
    8000165e:	fffff097          	auipc	ra,0xfffff
    80001662:	ee4080e7          	jalr	-284(ra) # 80000542 <panic>
      panic("uvmcopy: page not present");
    80001666:	00007517          	auipc	a0,0x7
    8000166a:	b3250513          	addi	a0,a0,-1230 # 80008198 <digits+0x158>
    8000166e:	fffff097          	auipc	ra,0xfffff
    80001672:	ed4080e7          	jalr	-300(ra) # 80000542 <panic>
      kfree(mem);
    80001676:	854a                	mv	a0,s2
    80001678:	fffff097          	auipc	ra,0xfffff
    8000167c:	39a080e7          	jalr	922(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001680:	4685                	li	a3,1
    80001682:	00c9d613          	srli	a2,s3,0xc
    80001686:	4581                	li	a1,0
    80001688:	8556                	mv	a0,s5
    8000168a:	00000097          	auipc	ra,0x0
    8000168e:	c5a080e7          	jalr	-934(ra) # 800012e4 <uvmunmap>
  return -1;
    80001692:	557d                	li	a0,-1
}
    80001694:	60a6                	ld	ra,72(sp)
    80001696:	6406                	ld	s0,64(sp)
    80001698:	74e2                	ld	s1,56(sp)
    8000169a:	7942                	ld	s2,48(sp)
    8000169c:	79a2                	ld	s3,40(sp)
    8000169e:	7a02                	ld	s4,32(sp)
    800016a0:	6ae2                	ld	s5,24(sp)
    800016a2:	6b42                	ld	s6,16(sp)
    800016a4:	6ba2                	ld	s7,8(sp)
    800016a6:	6161                	addi	sp,sp,80
    800016a8:	8082                	ret
  return 0;
    800016aa:	4501                	li	a0,0
}
    800016ac:	8082                	ret

00000000800016ae <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016ae:	1141                	addi	sp,sp,-16
    800016b0:	e406                	sd	ra,8(sp)
    800016b2:	e022                	sd	s0,0(sp)
    800016b4:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016b6:	4601                	li	a2,0
    800016b8:	00000097          	auipc	ra,0x0
    800016bc:	94e080e7          	jalr	-1714(ra) # 80001006 <walk>
  if(pte == 0)
    800016c0:	c901                	beqz	a0,800016d0 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c2:	611c                	ld	a5,0(a0)
    800016c4:	9bbd                	andi	a5,a5,-17
    800016c6:	e11c                	sd	a5,0(a0)
}
    800016c8:	60a2                	ld	ra,8(sp)
    800016ca:	6402                	ld	s0,0(sp)
    800016cc:	0141                	addi	sp,sp,16
    800016ce:	8082                	ret
    panic("uvmclear");
    800016d0:	00007517          	auipc	a0,0x7
    800016d4:	ae850513          	addi	a0,a0,-1304 # 800081b8 <digits+0x178>
    800016d8:	fffff097          	auipc	ra,0xfffff
    800016dc:	e6a080e7          	jalr	-406(ra) # 80000542 <panic>

00000000800016e0 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e0:	c6bd                	beqz	a3,8000174e <copyout+0x6e>
{
    800016e2:	715d                	addi	sp,sp,-80
    800016e4:	e486                	sd	ra,72(sp)
    800016e6:	e0a2                	sd	s0,64(sp)
    800016e8:	fc26                	sd	s1,56(sp)
    800016ea:	f84a                	sd	s2,48(sp)
    800016ec:	f44e                	sd	s3,40(sp)
    800016ee:	f052                	sd	s4,32(sp)
    800016f0:	ec56                	sd	s5,24(sp)
    800016f2:	e85a                	sd	s6,16(sp)
    800016f4:	e45e                	sd	s7,8(sp)
    800016f6:	e062                	sd	s8,0(sp)
    800016f8:	0880                	addi	s0,sp,80
    800016fa:	8b2a                	mv	s6,a0
    800016fc:	8c2e                	mv	s8,a1
    800016fe:	8a32                	mv	s4,a2
    80001700:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001702:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001704:	6a85                	lui	s5,0x1
    80001706:	a015                	j	8000172a <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001708:	9562                	add	a0,a0,s8
    8000170a:	0004861b          	sext.w	a2,s1
    8000170e:	85d2                	mv	a1,s4
    80001710:	41250533          	sub	a0,a0,s2
    80001714:	fffff097          	auipc	ra,0xfffff
    80001718:	666080e7          	jalr	1638(ra) # 80000d7a <memmove>

    len -= n;
    8000171c:	409989b3          	sub	s3,s3,s1
    src += n;
    80001720:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001722:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001726:	02098263          	beqz	s3,8000174a <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000172e:	85ca                	mv	a1,s2
    80001730:	855a                	mv	a0,s6
    80001732:	00000097          	auipc	ra,0x0
    80001736:	97a080e7          	jalr	-1670(ra) # 800010ac <walkaddr>
    if(pa0 == 0)
    8000173a:	cd01                	beqz	a0,80001752 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000173c:	418904b3          	sub	s1,s2,s8
    80001740:	94d6                	add	s1,s1,s5
    if(n > len)
    80001742:	fc99f3e3          	bgeu	s3,s1,80001708 <copyout+0x28>
    80001746:	84ce                	mv	s1,s3
    80001748:	b7c1                	j	80001708 <copyout+0x28>
  }
  return 0;
    8000174a:	4501                	li	a0,0
    8000174c:	a021                	j	80001754 <copyout+0x74>
    8000174e:	4501                	li	a0,0
}
    80001750:	8082                	ret
      return -1;
    80001752:	557d                	li	a0,-1
}
    80001754:	60a6                	ld	ra,72(sp)
    80001756:	6406                	ld	s0,64(sp)
    80001758:	74e2                	ld	s1,56(sp)
    8000175a:	7942                	ld	s2,48(sp)
    8000175c:	79a2                	ld	s3,40(sp)
    8000175e:	7a02                	ld	s4,32(sp)
    80001760:	6ae2                	ld	s5,24(sp)
    80001762:	6b42                	ld	s6,16(sp)
    80001764:	6ba2                	ld	s7,8(sp)
    80001766:	6c02                	ld	s8,0(sp)
    80001768:	6161                	addi	sp,sp,80
    8000176a:	8082                	ret

000000008000176c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000176c:	caa5                	beqz	a3,800017dc <copyin+0x70>
{
    8000176e:	715d                	addi	sp,sp,-80
    80001770:	e486                	sd	ra,72(sp)
    80001772:	e0a2                	sd	s0,64(sp)
    80001774:	fc26                	sd	s1,56(sp)
    80001776:	f84a                	sd	s2,48(sp)
    80001778:	f44e                	sd	s3,40(sp)
    8000177a:	f052                	sd	s4,32(sp)
    8000177c:	ec56                	sd	s5,24(sp)
    8000177e:	e85a                	sd	s6,16(sp)
    80001780:	e45e                	sd	s7,8(sp)
    80001782:	e062                	sd	s8,0(sp)
    80001784:	0880                	addi	s0,sp,80
    80001786:	8b2a                	mv	s6,a0
    80001788:	8a2e                	mv	s4,a1
    8000178a:	8c32                	mv	s8,a2
    8000178c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000178e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001790:	6a85                	lui	s5,0x1
    80001792:	a01d                	j	800017b8 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001794:	018505b3          	add	a1,a0,s8
    80001798:	0004861b          	sext.w	a2,s1
    8000179c:	412585b3          	sub	a1,a1,s2
    800017a0:	8552                	mv	a0,s4
    800017a2:	fffff097          	auipc	ra,0xfffff
    800017a6:	5d8080e7          	jalr	1496(ra) # 80000d7a <memmove>

    len -= n;
    800017aa:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017ae:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017b0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b4:	02098263          	beqz	s3,800017d8 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017b8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017bc:	85ca                	mv	a1,s2
    800017be:	855a                	mv	a0,s6
    800017c0:	00000097          	auipc	ra,0x0
    800017c4:	8ec080e7          	jalr	-1812(ra) # 800010ac <walkaddr>
    if(pa0 == 0)
    800017c8:	cd01                	beqz	a0,800017e0 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ca:	418904b3          	sub	s1,s2,s8
    800017ce:	94d6                	add	s1,s1,s5
    if(n > len)
    800017d0:	fc99f2e3          	bgeu	s3,s1,80001794 <copyin+0x28>
    800017d4:	84ce                	mv	s1,s3
    800017d6:	bf7d                	j	80001794 <copyin+0x28>
  }
  return 0;
    800017d8:	4501                	li	a0,0
    800017da:	a021                	j	800017e2 <copyin+0x76>
    800017dc:	4501                	li	a0,0
}
    800017de:	8082                	ret
      return -1;
    800017e0:	557d                	li	a0,-1
}
    800017e2:	60a6                	ld	ra,72(sp)
    800017e4:	6406                	ld	s0,64(sp)
    800017e6:	74e2                	ld	s1,56(sp)
    800017e8:	7942                	ld	s2,48(sp)
    800017ea:	79a2                	ld	s3,40(sp)
    800017ec:	7a02                	ld	s4,32(sp)
    800017ee:	6ae2                	ld	s5,24(sp)
    800017f0:	6b42                	ld	s6,16(sp)
    800017f2:	6ba2                	ld	s7,8(sp)
    800017f4:	6c02                	ld	s8,0(sp)
    800017f6:	6161                	addi	sp,sp,80
    800017f8:	8082                	ret

00000000800017fa <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017fa:	c6c5                	beqz	a3,800018a2 <copyinstr+0xa8>
{
    800017fc:	715d                	addi	sp,sp,-80
    800017fe:	e486                	sd	ra,72(sp)
    80001800:	e0a2                	sd	s0,64(sp)
    80001802:	fc26                	sd	s1,56(sp)
    80001804:	f84a                	sd	s2,48(sp)
    80001806:	f44e                	sd	s3,40(sp)
    80001808:	f052                	sd	s4,32(sp)
    8000180a:	ec56                	sd	s5,24(sp)
    8000180c:	e85a                	sd	s6,16(sp)
    8000180e:	e45e                	sd	s7,8(sp)
    80001810:	0880                	addi	s0,sp,80
    80001812:	8a2a                	mv	s4,a0
    80001814:	8b2e                	mv	s6,a1
    80001816:	8bb2                	mv	s7,a2
    80001818:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000181a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000181c:	6985                	lui	s3,0x1
    8000181e:	a035                	j	8000184a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001820:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001824:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001826:	0017b793          	seqz	a5,a5
    8000182a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000182e:	60a6                	ld	ra,72(sp)
    80001830:	6406                	ld	s0,64(sp)
    80001832:	74e2                	ld	s1,56(sp)
    80001834:	7942                	ld	s2,48(sp)
    80001836:	79a2                	ld	s3,40(sp)
    80001838:	7a02                	ld	s4,32(sp)
    8000183a:	6ae2                	ld	s5,24(sp)
    8000183c:	6b42                	ld	s6,16(sp)
    8000183e:	6ba2                	ld	s7,8(sp)
    80001840:	6161                	addi	sp,sp,80
    80001842:	8082                	ret
    srcva = va0 + PGSIZE;
    80001844:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001848:	c8a9                	beqz	s1,8000189a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000184a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000184e:	85ca                	mv	a1,s2
    80001850:	8552                	mv	a0,s4
    80001852:	00000097          	auipc	ra,0x0
    80001856:	85a080e7          	jalr	-1958(ra) # 800010ac <walkaddr>
    if(pa0 == 0)
    8000185a:	c131                	beqz	a0,8000189e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000185c:	41790833          	sub	a6,s2,s7
    80001860:	984e                	add	a6,a6,s3
    if(n > max)
    80001862:	0104f363          	bgeu	s1,a6,80001868 <copyinstr+0x6e>
    80001866:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001868:	955e                	add	a0,a0,s7
    8000186a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000186e:	fc080be3          	beqz	a6,80001844 <copyinstr+0x4a>
    80001872:	985a                	add	a6,a6,s6
    80001874:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001876:	41650633          	sub	a2,a0,s6
    8000187a:	14fd                	addi	s1,s1,-1
    8000187c:	9b26                	add	s6,s6,s1
    8000187e:	00f60733          	add	a4,a2,a5
    80001882:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001886:	df49                	beqz	a4,80001820 <copyinstr+0x26>
        *dst = *p;
    80001888:	00e78023          	sb	a4,0(a5)
      --max;
    8000188c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001890:	0785                	addi	a5,a5,1
    while(n > 0){
    80001892:	ff0796e3          	bne	a5,a6,8000187e <copyinstr+0x84>
      dst++;
    80001896:	8b42                	mv	s6,a6
    80001898:	b775                	j	80001844 <copyinstr+0x4a>
    8000189a:	4781                	li	a5,0
    8000189c:	b769                	j	80001826 <copyinstr+0x2c>
      return -1;
    8000189e:	557d                	li	a0,-1
    800018a0:	b779                	j	8000182e <copyinstr+0x34>
  int got_null = 0;
    800018a2:	4781                	li	a5,0
  if(got_null){
    800018a4:	0017b793          	seqz	a5,a5
    800018a8:	40f00533          	neg	a0,a5
}
    800018ac:	8082                	ret

00000000800018ae <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018ae:	1101                	addi	sp,sp,-32
    800018b0:	ec06                	sd	ra,24(sp)
    800018b2:	e822                	sd	s0,16(sp)
    800018b4:	e426                	sd	s1,8(sp)
    800018b6:	1000                	addi	s0,sp,32
    800018b8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018ba:	fffff097          	auipc	ra,0xfffff
    800018be:	2ee080e7          	jalr	750(ra) # 80000ba8 <holding>
    800018c2:	c909                	beqz	a0,800018d4 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018c4:	749c                	ld	a5,40(s1)
    800018c6:	00978f63          	beq	a5,s1,800018e4 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018ca:	60e2                	ld	ra,24(sp)
    800018cc:	6442                	ld	s0,16(sp)
    800018ce:	64a2                	ld	s1,8(sp)
    800018d0:	6105                	addi	sp,sp,32
    800018d2:	8082                	ret
    panic("wakeup1");
    800018d4:	00007517          	auipc	a0,0x7
    800018d8:	8f450513          	addi	a0,a0,-1804 # 800081c8 <digits+0x188>
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	c66080e7          	jalr	-922(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018e4:	4c98                	lw	a4,24(s1)
    800018e6:	4785                	li	a5,1
    800018e8:	fef711e3          	bne	a4,a5,800018ca <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018ec:	4789                	li	a5,2
    800018ee:	cc9c                	sw	a5,24(s1)
}
    800018f0:	bfe9                	j	800018ca <wakeup1+0x1c>

00000000800018f2 <procinit>:
{
    800018f2:	715d                	addi	sp,sp,-80
    800018f4:	e486                	sd	ra,72(sp)
    800018f6:	e0a2                	sd	s0,64(sp)
    800018f8:	fc26                	sd	s1,56(sp)
    800018fa:	f84a                	sd	s2,48(sp)
    800018fc:	f44e                	sd	s3,40(sp)
    800018fe:	f052                	sd	s4,32(sp)
    80001900:	ec56                	sd	s5,24(sp)
    80001902:	e85a                	sd	s6,16(sp)
    80001904:	e45e                	sd	s7,8(sp)
    80001906:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001908:	00007597          	auipc	a1,0x7
    8000190c:	8c858593          	addi	a1,a1,-1848 # 800081d0 <digits+0x190>
    80001910:	00010517          	auipc	a0,0x10
    80001914:	04050513          	addi	a0,a0,64 # 80011950 <pid_lock>
    80001918:	fffff097          	auipc	ra,0xfffff
    8000191c:	27a080e7          	jalr	634(ra) # 80000b92 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00010917          	auipc	s2,0x10
    80001924:	44890913          	addi	s2,s2,1096 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001928:	00007b97          	auipc	s7,0x7
    8000192c:	8b0b8b93          	addi	s7,s7,-1872 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001930:	8b4a                	mv	s6,s2
    80001932:	00006a97          	auipc	s5,0x6
    80001936:	6cea8a93          	addi	s5,s5,1742 # 80008000 <etext>
    8000193a:	040009b7          	lui	s3,0x4000
    8000193e:	19fd                	addi	s3,s3,-1
    80001940:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001942:	00016a17          	auipc	s4,0x16
    80001946:	026a0a13          	addi	s4,s4,38 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    8000194a:	85de                	mv	a1,s7
    8000194c:	854a                	mv	a0,s2
    8000194e:	fffff097          	auipc	ra,0xfffff
    80001952:	244080e7          	jalr	580(ra) # 80000b92 <initlock>
      char *pa = kalloc();
    80001956:	fffff097          	auipc	ra,0xfffff
    8000195a:	1b8080e7          	jalr	440(ra) # 80000b0e <kalloc>
    8000195e:	85aa                	mv	a1,a0
      if(pa == 0)
    80001960:	c929                	beqz	a0,800019b2 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001962:	416904b3          	sub	s1,s2,s6
    80001966:	8491                	srai	s1,s1,0x4
    80001968:	000ab783          	ld	a5,0(s5)
    8000196c:	02f484b3          	mul	s1,s1,a5
    80001970:	2485                	addiw	s1,s1,1
    80001972:	00d4949b          	slliw	s1,s1,0xd
    80001976:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000197a:	4699                	li	a3,6
    8000197c:	6605                	lui	a2,0x1
    8000197e:	8526                	mv	a0,s1
    80001980:	00000097          	auipc	ra,0x0
    80001984:	85a080e7          	jalr	-1958(ra) # 800011da <kvmmap>
      p->kstack = va;
    80001988:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198c:	17090913          	addi	s2,s2,368
    80001990:	fb491de3          	bne	s2,s4,8000194a <procinit+0x58>
  kvminithart();
    80001994:	fffff097          	auipc	ra,0xfffff
    80001998:	64e080e7          	jalr	1614(ra) # 80000fe2 <kvminithart>
}
    8000199c:	60a6                	ld	ra,72(sp)
    8000199e:	6406                	ld	s0,64(sp)
    800019a0:	74e2                	ld	s1,56(sp)
    800019a2:	7942                	ld	s2,48(sp)
    800019a4:	79a2                	ld	s3,40(sp)
    800019a6:	7a02                	ld	s4,32(sp)
    800019a8:	6ae2                	ld	s5,24(sp)
    800019aa:	6b42                	ld	s6,16(sp)
    800019ac:	6ba2                	ld	s7,8(sp)
    800019ae:	6161                	addi	sp,sp,80
    800019b0:	8082                	ret
        panic("kalloc");
    800019b2:	00007517          	auipc	a0,0x7
    800019b6:	82e50513          	addi	a0,a0,-2002 # 800081e0 <digits+0x1a0>
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	b88080e7          	jalr	-1144(ra) # 80000542 <panic>

00000000800019c2 <cpuid>:
{
    800019c2:	1141                	addi	sp,sp,-16
    800019c4:	e422                	sd	s0,8(sp)
    800019c6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019c8:	8512                	mv	a0,tp
}
    800019ca:	2501                	sext.w	a0,a0
    800019cc:	6422                	ld	s0,8(sp)
    800019ce:	0141                	addi	sp,sp,16
    800019d0:	8082                	ret

00000000800019d2 <mycpu>:
mycpu(void) {
    800019d2:	1141                	addi	sp,sp,-16
    800019d4:	e422                	sd	s0,8(sp)
    800019d6:	0800                	addi	s0,sp,16
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
}
    800019de:	00010517          	auipc	a0,0x10
    800019e2:	f8a50513          	addi	a0,a0,-118 # 80011968 <cpus>
    800019e6:	953e                	add	a0,a0,a5
    800019e8:	6422                	ld	s0,8(sp)
    800019ea:	0141                	addi	sp,sp,16
    800019ec:	8082                	ret

00000000800019ee <myproc>:
myproc(void) {
    800019ee:	1101                	addi	sp,sp,-32
    800019f0:	ec06                	sd	ra,24(sp)
    800019f2:	e822                	sd	s0,16(sp)
    800019f4:	e426                	sd	s1,8(sp)
    800019f6:	1000                	addi	s0,sp,32
  push_off();
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	1de080e7          	jalr	478(ra) # 80000bd6 <push_off>
    80001a00:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a02:	2781                	sext.w	a5,a5
    80001a04:	079e                	slli	a5,a5,0x7
    80001a06:	00010717          	auipc	a4,0x10
    80001a0a:	f4a70713          	addi	a4,a4,-182 # 80011950 <pid_lock>
    80001a0e:	97ba                	add	a5,a5,a4
    80001a10:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a12:	fffff097          	auipc	ra,0xfffff
    80001a16:	264080e7          	jalr	612(ra) # 80000c76 <pop_off>
}
    80001a1a:	8526                	mv	a0,s1
    80001a1c:	60e2                	ld	ra,24(sp)
    80001a1e:	6442                	ld	s0,16(sp)
    80001a20:	64a2                	ld	s1,8(sp)
    80001a22:	6105                	addi	sp,sp,32
    80001a24:	8082                	ret

0000000080001a26 <forkret>:
{
    80001a26:	1141                	addi	sp,sp,-16
    80001a28:	e406                	sd	ra,8(sp)
    80001a2a:	e022                	sd	s0,0(sp)
    80001a2c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a2e:	00000097          	auipc	ra,0x0
    80001a32:	fc0080e7          	jalr	-64(ra) # 800019ee <myproc>
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	2a0080e7          	jalr	672(ra) # 80000cd6 <release>
  if (first) {
    80001a3e:	00007797          	auipc	a5,0x7
    80001a42:	f027a783          	lw	a5,-254(a5) # 80008940 <first.1>
    80001a46:	eb89                	bnez	a5,80001a58 <forkret+0x32>
  usertrapret();
    80001a48:	00001097          	auipc	ra,0x1
    80001a4c:	cd2080e7          	jalr	-814(ra) # 8000271a <usertrapret>
}
    80001a50:	60a2                	ld	ra,8(sp)
    80001a52:	6402                	ld	s0,0(sp)
    80001a54:	0141                	addi	sp,sp,16
    80001a56:	8082                	ret
    first = 0;
    80001a58:	00007797          	auipc	a5,0x7
    80001a5c:	ee07a423          	sw	zero,-280(a5) # 80008940 <first.1>
    fsinit(ROOTDEV);
    80001a60:	4505                	li	a0,1
    80001a62:	00002097          	auipc	ra,0x2
    80001a66:	ae2080e7          	jalr	-1310(ra) # 80003544 <fsinit>
    80001a6a:	bff9                	j	80001a48 <forkret+0x22>

0000000080001a6c <allocpid>:
allocpid() {
    80001a6c:	1101                	addi	sp,sp,-32
    80001a6e:	ec06                	sd	ra,24(sp)
    80001a70:	e822                	sd	s0,16(sp)
    80001a72:	e426                	sd	s1,8(sp)
    80001a74:	e04a                	sd	s2,0(sp)
    80001a76:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a78:	00010917          	auipc	s2,0x10
    80001a7c:	ed890913          	addi	s2,s2,-296 # 80011950 <pid_lock>
    80001a80:	854a                	mv	a0,s2
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	1a0080e7          	jalr	416(ra) # 80000c22 <acquire>
  pid = nextpid;
    80001a8a:	00007797          	auipc	a5,0x7
    80001a8e:	eba78793          	addi	a5,a5,-326 # 80008944 <nextpid>
    80001a92:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a94:	0014871b          	addiw	a4,s1,1
    80001a98:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a9a:	854a                	mv	a0,s2
    80001a9c:	fffff097          	auipc	ra,0xfffff
    80001aa0:	23a080e7          	jalr	570(ra) # 80000cd6 <release>
}
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	60e2                	ld	ra,24(sp)
    80001aa8:	6442                	ld	s0,16(sp)
    80001aaa:	64a2                	ld	s1,8(sp)
    80001aac:	6902                	ld	s2,0(sp)
    80001aae:	6105                	addi	sp,sp,32
    80001ab0:	8082                	ret

0000000080001ab2 <proc_pagetable>:
{
    80001ab2:	1101                	addi	sp,sp,-32
    80001ab4:	ec06                	sd	ra,24(sp)
    80001ab6:	e822                	sd	s0,16(sp)
    80001ab8:	e426                	sd	s1,8(sp)
    80001aba:	e04a                	sd	s2,0(sp)
    80001abc:	1000                	addi	s0,sp,32
    80001abe:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ac0:	00000097          	auipc	ra,0x0
    80001ac4:	8e8080e7          	jalr	-1816(ra) # 800013a8 <uvmcreate>
    80001ac8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aca:	c121                	beqz	a0,80001b0a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001acc:	4729                	li	a4,10
    80001ace:	00005697          	auipc	a3,0x5
    80001ad2:	53268693          	addi	a3,a3,1330 # 80007000 <_trampoline>
    80001ad6:	6605                	lui	a2,0x1
    80001ad8:	040005b7          	lui	a1,0x4000
    80001adc:	15fd                	addi	a1,a1,-1
    80001ade:	05b2                	slli	a1,a1,0xc
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	66c080e7          	jalr	1644(ra) # 8000114c <mappages>
    80001ae8:	02054863          	bltz	a0,80001b18 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aec:	4719                	li	a4,6
    80001aee:	05893683          	ld	a3,88(s2)
    80001af2:	6605                	lui	a2,0x1
    80001af4:	020005b7          	lui	a1,0x2000
    80001af8:	15fd                	addi	a1,a1,-1
    80001afa:	05b6                	slli	a1,a1,0xd
    80001afc:	8526                	mv	a0,s1
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	64e080e7          	jalr	1614(ra) # 8000114c <mappages>
    80001b06:	02054163          	bltz	a0,80001b28 <proc_pagetable+0x76>
}
    80001b0a:	8526                	mv	a0,s1
    80001b0c:	60e2                	ld	ra,24(sp)
    80001b0e:	6442                	ld	s0,16(sp)
    80001b10:	64a2                	ld	s1,8(sp)
    80001b12:	6902                	ld	s2,0(sp)
    80001b14:	6105                	addi	sp,sp,32
    80001b16:	8082                	ret
    uvmfree(pagetable, 0);
    80001b18:	4581                	li	a1,0
    80001b1a:	8526                	mv	a0,s1
    80001b1c:	00000097          	auipc	ra,0x0
    80001b20:	a88080e7          	jalr	-1400(ra) # 800015a4 <uvmfree>
    return 0;
    80001b24:	4481                	li	s1,0
    80001b26:	b7d5                	j	80001b0a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b28:	4681                	li	a3,0
    80001b2a:	4605                	li	a2,1
    80001b2c:	040005b7          	lui	a1,0x4000
    80001b30:	15fd                	addi	a1,a1,-1
    80001b32:	05b2                	slli	a1,a1,0xc
    80001b34:	8526                	mv	a0,s1
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	7ae080e7          	jalr	1966(ra) # 800012e4 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b3e:	4581                	li	a1,0
    80001b40:	8526                	mv	a0,s1
    80001b42:	00000097          	auipc	ra,0x0
    80001b46:	a62080e7          	jalr	-1438(ra) # 800015a4 <uvmfree>
    return 0;
    80001b4a:	4481                	li	s1,0
    80001b4c:	bf7d                	j	80001b0a <proc_pagetable+0x58>

0000000080001b4e <proc_freepagetable>:
{
    80001b4e:	1101                	addi	sp,sp,-32
    80001b50:	ec06                	sd	ra,24(sp)
    80001b52:	e822                	sd	s0,16(sp)
    80001b54:	e426                	sd	s1,8(sp)
    80001b56:	e04a                	sd	s2,0(sp)
    80001b58:	1000                	addi	s0,sp,32
    80001b5a:	84aa                	mv	s1,a0
    80001b5c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b5e:	4681                	li	a3,0
    80001b60:	4605                	li	a2,1
    80001b62:	040005b7          	lui	a1,0x4000
    80001b66:	15fd                	addi	a1,a1,-1
    80001b68:	05b2                	slli	a1,a1,0xc
    80001b6a:	fffff097          	auipc	ra,0xfffff
    80001b6e:	77a080e7          	jalr	1914(ra) # 800012e4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b72:	4681                	li	a3,0
    80001b74:	4605                	li	a2,1
    80001b76:	020005b7          	lui	a1,0x2000
    80001b7a:	15fd                	addi	a1,a1,-1
    80001b7c:	05b6                	slli	a1,a1,0xd
    80001b7e:	8526                	mv	a0,s1
    80001b80:	fffff097          	auipc	ra,0xfffff
    80001b84:	764080e7          	jalr	1892(ra) # 800012e4 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b88:	85ca                	mv	a1,s2
    80001b8a:	8526                	mv	a0,s1
    80001b8c:	00000097          	auipc	ra,0x0
    80001b90:	a18080e7          	jalr	-1512(ra) # 800015a4 <uvmfree>
}
    80001b94:	60e2                	ld	ra,24(sp)
    80001b96:	6442                	ld	s0,16(sp)
    80001b98:	64a2                	ld	s1,8(sp)
    80001b9a:	6902                	ld	s2,0(sp)
    80001b9c:	6105                	addi	sp,sp,32
    80001b9e:	8082                	ret

0000000080001ba0 <freeproc>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	1000                	addi	s0,sp,32
    80001baa:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bac:	6d28                	ld	a0,88(a0)
    80001bae:	c509                	beqz	a0,80001bb8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	e62080e7          	jalr	-414(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001bb8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bbc:	68a8                	ld	a0,80(s1)
    80001bbe:	c511                	beqz	a0,80001bca <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bc0:	64ac                	ld	a1,72(s1)
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	f8c080e7          	jalr	-116(ra) # 80001b4e <proc_freepagetable>
  p->pagetable = 0;
    80001bca:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bce:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bd2:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bd6:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bda:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bde:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001be2:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001be6:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bea:	0004ac23          	sw	zero,24(s1)
}
    80001bee:	60e2                	ld	ra,24(sp)
    80001bf0:	6442                	ld	s0,16(sp)
    80001bf2:	64a2                	ld	s1,8(sp)
    80001bf4:	6105                	addi	sp,sp,32
    80001bf6:	8082                	ret

0000000080001bf8 <allocproc>:
{
    80001bf8:	1101                	addi	sp,sp,-32
    80001bfa:	ec06                	sd	ra,24(sp)
    80001bfc:	e822                	sd	s0,16(sp)
    80001bfe:	e426                	sd	s1,8(sp)
    80001c00:	e04a                	sd	s2,0(sp)
    80001c02:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c04:	00010497          	auipc	s1,0x10
    80001c08:	16448493          	addi	s1,s1,356 # 80011d68 <proc>
    80001c0c:	00016917          	auipc	s2,0x16
    80001c10:	d5c90913          	addi	s2,s2,-676 # 80017968 <tickslock>
    acquire(&p->lock);
    80001c14:	8526                	mv	a0,s1
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	00c080e7          	jalr	12(ra) # 80000c22 <acquire>
    if(p->state == UNUSED) {
    80001c1e:	4c9c                	lw	a5,24(s1)
    80001c20:	cf81                	beqz	a5,80001c38 <allocproc+0x40>
      release(&p->lock);
    80001c22:	8526                	mv	a0,s1
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	0b2080e7          	jalr	178(ra) # 80000cd6 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c2c:	17048493          	addi	s1,s1,368
    80001c30:	ff2492e3          	bne	s1,s2,80001c14 <allocproc+0x1c>
  return 0;
    80001c34:	4481                	li	s1,0
    80001c36:	a0b9                	j	80001c84 <allocproc+0x8c>
  p->pid = allocpid();
    80001c38:	00000097          	auipc	ra,0x0
    80001c3c:	e34080e7          	jalr	-460(ra) # 80001a6c <allocpid>
    80001c40:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	ecc080e7          	jalr	-308(ra) # 80000b0e <kalloc>
    80001c4a:	892a                	mv	s2,a0
    80001c4c:	eca8                	sd	a0,88(s1)
    80001c4e:	c131                	beqz	a0,80001c92 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c50:	8526                	mv	a0,s1
    80001c52:	00000097          	auipc	ra,0x0
    80001c56:	e60080e7          	jalr	-416(ra) # 80001ab2 <proc_pagetable>
    80001c5a:	892a                	mv	s2,a0
    80001c5c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c5e:	c129                	beqz	a0,80001ca0 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c60:	07000613          	li	a2,112
    80001c64:	4581                	li	a1,0
    80001c66:	06048513          	addi	a0,s1,96
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	0b4080e7          	jalr	180(ra) # 80000d1e <memset>
  p->context.ra = (uint64)forkret;
    80001c72:	00000797          	auipc	a5,0x0
    80001c76:	db478793          	addi	a5,a5,-588 # 80001a26 <forkret>
    80001c7a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c7c:	60bc                	ld	a5,64(s1)
    80001c7e:	6705                	lui	a4,0x1
    80001c80:	97ba                	add	a5,a5,a4
    80001c82:	f4bc                	sd	a5,104(s1)
}
    80001c84:	8526                	mv	a0,s1
    80001c86:	60e2                	ld	ra,24(sp)
    80001c88:	6442                	ld	s0,16(sp)
    80001c8a:	64a2                	ld	s1,8(sp)
    80001c8c:	6902                	ld	s2,0(sp)
    80001c8e:	6105                	addi	sp,sp,32
    80001c90:	8082                	ret
    release(&p->lock);
    80001c92:	8526                	mv	a0,s1
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	042080e7          	jalr	66(ra) # 80000cd6 <release>
    return 0;
    80001c9c:	84ca                	mv	s1,s2
    80001c9e:	b7dd                	j	80001c84 <allocproc+0x8c>
    freeproc(p);
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	00000097          	auipc	ra,0x0
    80001ca6:	efe080e7          	jalr	-258(ra) # 80001ba0 <freeproc>
    release(&p->lock);
    80001caa:	8526                	mv	a0,s1
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	02a080e7          	jalr	42(ra) # 80000cd6 <release>
    return 0;
    80001cb4:	84ca                	mv	s1,s2
    80001cb6:	b7f9                	j	80001c84 <allocproc+0x8c>

0000000080001cb8 <userinit>:
{
    80001cb8:	1101                	addi	sp,sp,-32
    80001cba:	ec06                	sd	ra,24(sp)
    80001cbc:	e822                	sd	s0,16(sp)
    80001cbe:	e426                	sd	s1,8(sp)
    80001cc0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc2:	00000097          	auipc	ra,0x0
    80001cc6:	f36080e7          	jalr	-202(ra) # 80001bf8 <allocproc>
    80001cca:	84aa                	mv	s1,a0
  initproc = p;
    80001ccc:	00007797          	auipc	a5,0x7
    80001cd0:	34a7b623          	sd	a0,844(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cd4:	03400613          	li	a2,52
    80001cd8:	00007597          	auipc	a1,0x7
    80001cdc:	c7858593          	addi	a1,a1,-904 # 80008950 <initcode>
    80001ce0:	6928                	ld	a0,80(a0)
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	6f4080e7          	jalr	1780(ra) # 800013d6 <uvminit>
  p->sz = PGSIZE;
    80001cea:	6785                	lui	a5,0x1
    80001cec:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cee:	6cb8                	ld	a4,88(s1)
    80001cf0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cf4:	6cb8                	ld	a4,88(s1)
    80001cf6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cf8:	4641                	li	a2,16
    80001cfa:	00006597          	auipc	a1,0x6
    80001cfe:	4ee58593          	addi	a1,a1,1262 # 800081e8 <digits+0x1a8>
    80001d02:	15848513          	addi	a0,s1,344
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	16a080e7          	jalr	362(ra) # 80000e70 <safestrcpy>
  p->cwd = namei("/");
    80001d0e:	00006517          	auipc	a0,0x6
    80001d12:	4ea50513          	addi	a0,a0,1258 # 800081f8 <digits+0x1b8>
    80001d16:	00002097          	auipc	ra,0x2
    80001d1a:	256080e7          	jalr	598(ra) # 80003f6c <namei>
    80001d1e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d22:	4789                	li	a5,2
    80001d24:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d26:	8526                	mv	a0,s1
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	fae080e7          	jalr	-82(ra) # 80000cd6 <release>
}
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6105                	addi	sp,sp,32
    80001d38:	8082                	ret

0000000080001d3a <growproc>:
{
    80001d3a:	1101                	addi	sp,sp,-32
    80001d3c:	ec06                	sd	ra,24(sp)
    80001d3e:	e822                	sd	s0,16(sp)
    80001d40:	e426                	sd	s1,8(sp)
    80001d42:	e04a                	sd	s2,0(sp)
    80001d44:	1000                	addi	s0,sp,32
    80001d46:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	ca6080e7          	jalr	-858(ra) # 800019ee <myproc>
    80001d50:	892a                	mv	s2,a0
  sz = p->sz;
    80001d52:	652c                	ld	a1,72(a0)
    80001d54:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d58:	00904f63          	bgtz	s1,80001d76 <growproc+0x3c>
  } else if(n < 0){
    80001d5c:	0204cc63          	bltz	s1,80001d94 <growproc+0x5a>
  p->sz = sz;
    80001d60:	1602                	slli	a2,a2,0x20
    80001d62:	9201                	srli	a2,a2,0x20
    80001d64:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d68:	4501                	li	a0,0
}
    80001d6a:	60e2                	ld	ra,24(sp)
    80001d6c:	6442                	ld	s0,16(sp)
    80001d6e:	64a2                	ld	s1,8(sp)
    80001d70:	6902                	ld	s2,0(sp)
    80001d72:	6105                	addi	sp,sp,32
    80001d74:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d76:	9e25                	addw	a2,a2,s1
    80001d78:	1602                	slli	a2,a2,0x20
    80001d7a:	9201                	srli	a2,a2,0x20
    80001d7c:	1582                	slli	a1,a1,0x20
    80001d7e:	9181                	srli	a1,a1,0x20
    80001d80:	6928                	ld	a0,80(a0)
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	70e080e7          	jalr	1806(ra) # 80001490 <uvmalloc>
    80001d8a:	0005061b          	sext.w	a2,a0
    80001d8e:	fa69                	bnez	a2,80001d60 <growproc+0x26>
      return -1;
    80001d90:	557d                	li	a0,-1
    80001d92:	bfe1                	j	80001d6a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d94:	9e25                	addw	a2,a2,s1
    80001d96:	1602                	slli	a2,a2,0x20
    80001d98:	9201                	srli	a2,a2,0x20
    80001d9a:	1582                	slli	a1,a1,0x20
    80001d9c:	9181                	srli	a1,a1,0x20
    80001d9e:	6928                	ld	a0,80(a0)
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	6a8080e7          	jalr	1704(ra) # 80001448 <uvmdealloc>
    80001da8:	0005061b          	sext.w	a2,a0
    80001dac:	bf55                	j	80001d60 <growproc+0x26>

0000000080001dae <fork>:
{
    80001dae:	7139                	addi	sp,sp,-64
    80001db0:	fc06                	sd	ra,56(sp)
    80001db2:	f822                	sd	s0,48(sp)
    80001db4:	f426                	sd	s1,40(sp)
    80001db6:	f04a                	sd	s2,32(sp)
    80001db8:	ec4e                	sd	s3,24(sp)
    80001dba:	e852                	sd	s4,16(sp)
    80001dbc:	e456                	sd	s5,8(sp)
    80001dbe:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dc0:	00000097          	auipc	ra,0x0
    80001dc4:	c2e080e7          	jalr	-978(ra) # 800019ee <myproc>
    80001dc8:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	e2e080e7          	jalr	-466(ra) # 80001bf8 <allocproc>
    80001dd2:	c57d                	beqz	a0,80001ec0 <fork+0x112>
    80001dd4:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dd6:	048ab603          	ld	a2,72(s5)
    80001dda:	692c                	ld	a1,80(a0)
    80001ddc:	050ab503          	ld	a0,80(s5)
    80001de0:	fffff097          	auipc	ra,0xfffff
    80001de4:	7fc080e7          	jalr	2044(ra) # 800015dc <uvmcopy>
    80001de8:	04054a63          	bltz	a0,80001e3c <fork+0x8e>
  np->sz = p->sz;
    80001dec:	048ab783          	ld	a5,72(s5)
    80001df0:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001df4:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001df8:	058ab683          	ld	a3,88(s5)
    80001dfc:	87b6                	mv	a5,a3
    80001dfe:	058a3703          	ld	a4,88(s4)
    80001e02:	12068693          	addi	a3,a3,288
    80001e06:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e0a:	6788                	ld	a0,8(a5)
    80001e0c:	6b8c                	ld	a1,16(a5)
    80001e0e:	6f90                	ld	a2,24(a5)
    80001e10:	01073023          	sd	a6,0(a4)
    80001e14:	e708                	sd	a0,8(a4)
    80001e16:	eb0c                	sd	a1,16(a4)
    80001e18:	ef10                	sd	a2,24(a4)
    80001e1a:	02078793          	addi	a5,a5,32
    80001e1e:	02070713          	addi	a4,a4,32
    80001e22:	fed792e3          	bne	a5,a3,80001e06 <fork+0x58>
  np->trapframe->a0 = 0;
    80001e26:	058a3783          	ld	a5,88(s4)
    80001e2a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e2e:	0d0a8493          	addi	s1,s5,208
    80001e32:	0d0a0913          	addi	s2,s4,208
    80001e36:	150a8993          	addi	s3,s5,336
    80001e3a:	a00d                	j	80001e5c <fork+0xae>
    freeproc(np);
    80001e3c:	8552                	mv	a0,s4
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	d62080e7          	jalr	-670(ra) # 80001ba0 <freeproc>
    release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e8e080e7          	jalr	-370(ra) # 80000cd6 <release>
    return -1;
    80001e50:	54fd                	li	s1,-1
    80001e52:	a8a9                	j	80001eac <fork+0xfe>
  for(i = 0; i < NOFILE; i++)
    80001e54:	04a1                	addi	s1,s1,8
    80001e56:	0921                	addi	s2,s2,8
    80001e58:	01348b63          	beq	s1,s3,80001e6e <fork+0xc0>
    if(p->ofile[i])
    80001e5c:	6088                	ld	a0,0(s1)
    80001e5e:	d97d                	beqz	a0,80001e54 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e60:	00002097          	auipc	ra,0x2
    80001e64:	798080e7          	jalr	1944(ra) # 800045f8 <filedup>
    80001e68:	00a93023          	sd	a0,0(s2)
    80001e6c:	b7e5                	j	80001e54 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001e6e:	150ab503          	ld	a0,336(s5)
    80001e72:	00002097          	auipc	ra,0x2
    80001e76:	90c080e7          	jalr	-1780(ra) # 8000377e <idup>
    80001e7a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e7e:	4641                	li	a2,16
    80001e80:	158a8593          	addi	a1,s5,344
    80001e84:	158a0513          	addi	a0,s4,344
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	fe8080e7          	jalr	-24(ra) # 80000e70 <safestrcpy>
  np -> tracemask = p-> tracemask;
    80001e90:	168aa783          	lw	a5,360(s5)
    80001e94:	16fa2423          	sw	a5,360(s4)
  pid = np->pid;
    80001e98:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001e9c:	4789                	li	a5,2
    80001e9e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ea2:	8552                	mv	a0,s4
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	e32080e7          	jalr	-462(ra) # 80000cd6 <release>
}
    80001eac:	8526                	mv	a0,s1
    80001eae:	70e2                	ld	ra,56(sp)
    80001eb0:	7442                	ld	s0,48(sp)
    80001eb2:	74a2                	ld	s1,40(sp)
    80001eb4:	7902                	ld	s2,32(sp)
    80001eb6:	69e2                	ld	s3,24(sp)
    80001eb8:	6a42                	ld	s4,16(sp)
    80001eba:	6aa2                	ld	s5,8(sp)
    80001ebc:	6121                	addi	sp,sp,64
    80001ebe:	8082                	ret
    return -1;
    80001ec0:	54fd                	li	s1,-1
    80001ec2:	b7ed                	j	80001eac <fork+0xfe>

0000000080001ec4 <reparent>:
{
    80001ec4:	7179                	addi	sp,sp,-48
    80001ec6:	f406                	sd	ra,40(sp)
    80001ec8:	f022                	sd	s0,32(sp)
    80001eca:	ec26                	sd	s1,24(sp)
    80001ecc:	e84a                	sd	s2,16(sp)
    80001ece:	e44e                	sd	s3,8(sp)
    80001ed0:	e052                	sd	s4,0(sp)
    80001ed2:	1800                	addi	s0,sp,48
    80001ed4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ed6:	00010497          	auipc	s1,0x10
    80001eda:	e9248493          	addi	s1,s1,-366 # 80011d68 <proc>
      pp->parent = initproc;
    80001ede:	00007a17          	auipc	s4,0x7
    80001ee2:	13aa0a13          	addi	s4,s4,314 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ee6:	00016997          	auipc	s3,0x16
    80001eea:	a8298993          	addi	s3,s3,-1406 # 80017968 <tickslock>
    80001eee:	a029                	j	80001ef8 <reparent+0x34>
    80001ef0:	17048493          	addi	s1,s1,368
    80001ef4:	03348363          	beq	s1,s3,80001f1a <reparent+0x56>
    if(pp->parent == p){
    80001ef8:	709c                	ld	a5,32(s1)
    80001efa:	ff279be3          	bne	a5,s2,80001ef0 <reparent+0x2c>
      acquire(&pp->lock);
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d22080e7          	jalr	-734(ra) # 80000c22 <acquire>
      pp->parent = initproc;
    80001f08:	000a3783          	ld	a5,0(s4)
    80001f0c:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f0e:	8526                	mv	a0,s1
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	dc6080e7          	jalr	-570(ra) # 80000cd6 <release>
    80001f18:	bfe1                	j	80001ef0 <reparent+0x2c>
}
    80001f1a:	70a2                	ld	ra,40(sp)
    80001f1c:	7402                	ld	s0,32(sp)
    80001f1e:	64e2                	ld	s1,24(sp)
    80001f20:	6942                	ld	s2,16(sp)
    80001f22:	69a2                	ld	s3,8(sp)
    80001f24:	6a02                	ld	s4,0(sp)
    80001f26:	6145                	addi	sp,sp,48
    80001f28:	8082                	ret

0000000080001f2a <scheduler>:
{
    80001f2a:	715d                	addi	sp,sp,-80
    80001f2c:	e486                	sd	ra,72(sp)
    80001f2e:	e0a2                	sd	s0,64(sp)
    80001f30:	fc26                	sd	s1,56(sp)
    80001f32:	f84a                	sd	s2,48(sp)
    80001f34:	f44e                	sd	s3,40(sp)
    80001f36:	f052                	sd	s4,32(sp)
    80001f38:	ec56                	sd	s5,24(sp)
    80001f3a:	e85a                	sd	s6,16(sp)
    80001f3c:	e45e                	sd	s7,8(sp)
    80001f3e:	e062                	sd	s8,0(sp)
    80001f40:	0880                	addi	s0,sp,80
    80001f42:	8792                	mv	a5,tp
  int id = r_tp();
    80001f44:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f46:	00779b13          	slli	s6,a5,0x7
    80001f4a:	00010717          	auipc	a4,0x10
    80001f4e:	a0670713          	addi	a4,a4,-1530 # 80011950 <pid_lock>
    80001f52:	975a                	add	a4,a4,s6
    80001f54:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f58:	00010717          	auipc	a4,0x10
    80001f5c:	a1870713          	addi	a4,a4,-1512 # 80011970 <cpus+0x8>
    80001f60:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f62:	4c0d                	li	s8,3
        c->proc = p;
    80001f64:	079e                	slli	a5,a5,0x7
    80001f66:	00010a17          	auipc	s4,0x10
    80001f6a:	9eaa0a13          	addi	s4,s4,-1558 # 80011950 <pid_lock>
    80001f6e:	9a3e                	add	s4,s4,a5
        found = 1;
    80001f70:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f72:	00016997          	auipc	s3,0x16
    80001f76:	9f698993          	addi	s3,s3,-1546 # 80017968 <tickslock>
    80001f7a:	a899                	j	80001fd0 <scheduler+0xa6>
      release(&p->lock);
    80001f7c:	8526                	mv	a0,s1
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	d58080e7          	jalr	-680(ra) # 80000cd6 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f86:	17048493          	addi	s1,s1,368
    80001f8a:	03348963          	beq	s1,s3,80001fbc <scheduler+0x92>
      acquire(&p->lock);
    80001f8e:	8526                	mv	a0,s1
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	c92080e7          	jalr	-878(ra) # 80000c22 <acquire>
      if(p->state == RUNNABLE) {
    80001f98:	4c9c                	lw	a5,24(s1)
    80001f9a:	ff2791e3          	bne	a5,s2,80001f7c <scheduler+0x52>
        p->state = RUNNING;
    80001f9e:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fa2:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fa6:	06048593          	addi	a1,s1,96
    80001faa:	855a                	mv	a0,s6
    80001fac:	00000097          	auipc	ra,0x0
    80001fb0:	6c4080e7          	jalr	1732(ra) # 80002670 <swtch>
        c->proc = 0;
    80001fb4:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fb8:	8ade                	mv	s5,s7
    80001fba:	b7c9                	j	80001f7c <scheduler+0x52>
    if(found == 0) {
    80001fbc:	000a9a63          	bnez	s5,80001fd0 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fc4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc8:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001fcc:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fd4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fd8:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001fdc:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fde:	00010497          	auipc	s1,0x10
    80001fe2:	d8a48493          	addi	s1,s1,-630 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80001fe6:	4909                	li	s2,2
    80001fe8:	b75d                	j	80001f8e <scheduler+0x64>

0000000080001fea <sched>:
{
    80001fea:	7179                	addi	sp,sp,-48
    80001fec:	f406                	sd	ra,40(sp)
    80001fee:	f022                	sd	s0,32(sp)
    80001ff0:	ec26                	sd	s1,24(sp)
    80001ff2:	e84a                	sd	s2,16(sp)
    80001ff4:	e44e                	sd	s3,8(sp)
    80001ff6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ff8:	00000097          	auipc	ra,0x0
    80001ffc:	9f6080e7          	jalr	-1546(ra) # 800019ee <myproc>
    80002000:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002002:	fffff097          	auipc	ra,0xfffff
    80002006:	ba6080e7          	jalr	-1114(ra) # 80000ba8 <holding>
    8000200a:	c93d                	beqz	a0,80002080 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000200c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000200e:	2781                	sext.w	a5,a5
    80002010:	079e                	slli	a5,a5,0x7
    80002012:	00010717          	auipc	a4,0x10
    80002016:	93e70713          	addi	a4,a4,-1730 # 80011950 <pid_lock>
    8000201a:	97ba                	add	a5,a5,a4
    8000201c:	0907a703          	lw	a4,144(a5)
    80002020:	4785                	li	a5,1
    80002022:	06f71763          	bne	a4,a5,80002090 <sched+0xa6>
  if(p->state == RUNNING)
    80002026:	4c98                	lw	a4,24(s1)
    80002028:	478d                	li	a5,3
    8000202a:	06f70b63          	beq	a4,a5,800020a0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002032:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002034:	efb5                	bnez	a5,800020b0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002036:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002038:	00010917          	auipc	s2,0x10
    8000203c:	91890913          	addi	s2,s2,-1768 # 80011950 <pid_lock>
    80002040:	2781                	sext.w	a5,a5
    80002042:	079e                	slli	a5,a5,0x7
    80002044:	97ca                	add	a5,a5,s2
    80002046:	0947a983          	lw	s3,148(a5)
    8000204a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000204c:	2781                	sext.w	a5,a5
    8000204e:	079e                	slli	a5,a5,0x7
    80002050:	00010597          	auipc	a1,0x10
    80002054:	92058593          	addi	a1,a1,-1760 # 80011970 <cpus+0x8>
    80002058:	95be                	add	a1,a1,a5
    8000205a:	06048513          	addi	a0,s1,96
    8000205e:	00000097          	auipc	ra,0x0
    80002062:	612080e7          	jalr	1554(ra) # 80002670 <swtch>
    80002066:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002068:	2781                	sext.w	a5,a5
    8000206a:	079e                	slli	a5,a5,0x7
    8000206c:	97ca                	add	a5,a5,s2
    8000206e:	0937aa23          	sw	s3,148(a5)
}
    80002072:	70a2                	ld	ra,40(sp)
    80002074:	7402                	ld	s0,32(sp)
    80002076:	64e2                	ld	s1,24(sp)
    80002078:	6942                	ld	s2,16(sp)
    8000207a:	69a2                	ld	s3,8(sp)
    8000207c:	6145                	addi	sp,sp,48
    8000207e:	8082                	ret
    panic("sched p->lock");
    80002080:	00006517          	auipc	a0,0x6
    80002084:	18050513          	addi	a0,a0,384 # 80008200 <digits+0x1c0>
    80002088:	ffffe097          	auipc	ra,0xffffe
    8000208c:	4ba080e7          	jalr	1210(ra) # 80000542 <panic>
    panic("sched locks");
    80002090:	00006517          	auipc	a0,0x6
    80002094:	18050513          	addi	a0,a0,384 # 80008210 <digits+0x1d0>
    80002098:	ffffe097          	auipc	ra,0xffffe
    8000209c:	4aa080e7          	jalr	1194(ra) # 80000542 <panic>
    panic("sched running");
    800020a0:	00006517          	auipc	a0,0x6
    800020a4:	18050513          	addi	a0,a0,384 # 80008220 <digits+0x1e0>
    800020a8:	ffffe097          	auipc	ra,0xffffe
    800020ac:	49a080e7          	jalr	1178(ra) # 80000542 <panic>
    panic("sched interruptible");
    800020b0:	00006517          	auipc	a0,0x6
    800020b4:	18050513          	addi	a0,a0,384 # 80008230 <digits+0x1f0>
    800020b8:	ffffe097          	auipc	ra,0xffffe
    800020bc:	48a080e7          	jalr	1162(ra) # 80000542 <panic>

00000000800020c0 <exit>:
{
    800020c0:	7179                	addi	sp,sp,-48
    800020c2:	f406                	sd	ra,40(sp)
    800020c4:	f022                	sd	s0,32(sp)
    800020c6:	ec26                	sd	s1,24(sp)
    800020c8:	e84a                	sd	s2,16(sp)
    800020ca:	e44e                	sd	s3,8(sp)
    800020cc:	e052                	sd	s4,0(sp)
    800020ce:	1800                	addi	s0,sp,48
    800020d0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020d2:	00000097          	auipc	ra,0x0
    800020d6:	91c080e7          	jalr	-1764(ra) # 800019ee <myproc>
    800020da:	89aa                	mv	s3,a0
  if(p == initproc)
    800020dc:	00007797          	auipc	a5,0x7
    800020e0:	f3c7b783          	ld	a5,-196(a5) # 80009018 <initproc>
    800020e4:	0d050493          	addi	s1,a0,208
    800020e8:	15050913          	addi	s2,a0,336
    800020ec:	02a79363          	bne	a5,a0,80002112 <exit+0x52>
    panic("init exiting");
    800020f0:	00006517          	auipc	a0,0x6
    800020f4:	15850513          	addi	a0,a0,344 # 80008248 <digits+0x208>
    800020f8:	ffffe097          	auipc	ra,0xffffe
    800020fc:	44a080e7          	jalr	1098(ra) # 80000542 <panic>
      fileclose(f);
    80002100:	00002097          	auipc	ra,0x2
    80002104:	54a080e7          	jalr	1354(ra) # 8000464a <fileclose>
      p->ofile[fd] = 0;
    80002108:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000210c:	04a1                	addi	s1,s1,8
    8000210e:	01248563          	beq	s1,s2,80002118 <exit+0x58>
    if(p->ofile[fd]){
    80002112:	6088                	ld	a0,0(s1)
    80002114:	f575                	bnez	a0,80002100 <exit+0x40>
    80002116:	bfdd                	j	8000210c <exit+0x4c>
  begin_op();
    80002118:	00002097          	auipc	ra,0x2
    8000211c:	060080e7          	jalr	96(ra) # 80004178 <begin_op>
  iput(p->cwd);
    80002120:	1509b503          	ld	a0,336(s3)
    80002124:	00002097          	auipc	ra,0x2
    80002128:	852080e7          	jalr	-1966(ra) # 80003976 <iput>
  end_op();
    8000212c:	00002097          	auipc	ra,0x2
    80002130:	0cc080e7          	jalr	204(ra) # 800041f8 <end_op>
  p->cwd = 0;
    80002134:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002138:	00007497          	auipc	s1,0x7
    8000213c:	ee048493          	addi	s1,s1,-288 # 80009018 <initproc>
    80002140:	6088                	ld	a0,0(s1)
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	ae0080e7          	jalr	-1312(ra) # 80000c22 <acquire>
  wakeup1(initproc);
    8000214a:	6088                	ld	a0,0(s1)
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	762080e7          	jalr	1890(ra) # 800018ae <wakeup1>
  release(&initproc->lock);
    80002154:	6088                	ld	a0,0(s1)
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	b80080e7          	jalr	-1152(ra) # 80000cd6 <release>
  acquire(&p->lock);
    8000215e:	854e                	mv	a0,s3
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	ac2080e7          	jalr	-1342(ra) # 80000c22 <acquire>
  struct proc *original_parent = p->parent;
    80002168:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000216c:	854e                	mv	a0,s3
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b68080e7          	jalr	-1176(ra) # 80000cd6 <release>
  acquire(&original_parent->lock);
    80002176:	8526                	mv	a0,s1
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	aaa080e7          	jalr	-1366(ra) # 80000c22 <acquire>
  acquire(&p->lock);
    80002180:	854e                	mv	a0,s3
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	aa0080e7          	jalr	-1376(ra) # 80000c22 <acquire>
  reparent(p);
    8000218a:	854e                	mv	a0,s3
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	d38080e7          	jalr	-712(ra) # 80001ec4 <reparent>
  wakeup1(original_parent);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	718080e7          	jalr	1816(ra) # 800018ae <wakeup1>
  p->xstate = status;
    8000219e:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021a2:	4791                	li	a5,4
    800021a4:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021a8:	8526                	mv	a0,s1
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	b2c080e7          	jalr	-1236(ra) # 80000cd6 <release>
  sched();
    800021b2:	00000097          	auipc	ra,0x0
    800021b6:	e38080e7          	jalr	-456(ra) # 80001fea <sched>
  panic("zombie exit");
    800021ba:	00006517          	auipc	a0,0x6
    800021be:	09e50513          	addi	a0,a0,158 # 80008258 <digits+0x218>
    800021c2:	ffffe097          	auipc	ra,0xffffe
    800021c6:	380080e7          	jalr	896(ra) # 80000542 <panic>

00000000800021ca <yield>:
{
    800021ca:	1101                	addi	sp,sp,-32
    800021cc:	ec06                	sd	ra,24(sp)
    800021ce:	e822                	sd	s0,16(sp)
    800021d0:	e426                	sd	s1,8(sp)
    800021d2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021d4:	00000097          	auipc	ra,0x0
    800021d8:	81a080e7          	jalr	-2022(ra) # 800019ee <myproc>
    800021dc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	a44080e7          	jalr	-1468(ra) # 80000c22 <acquire>
  p->state = RUNNABLE;
    800021e6:	4789                	li	a5,2
    800021e8:	cc9c                	sw	a5,24(s1)
  sched();
    800021ea:	00000097          	auipc	ra,0x0
    800021ee:	e00080e7          	jalr	-512(ra) # 80001fea <sched>
  release(&p->lock);
    800021f2:	8526                	mv	a0,s1
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	ae2080e7          	jalr	-1310(ra) # 80000cd6 <release>
}
    800021fc:	60e2                	ld	ra,24(sp)
    800021fe:	6442                	ld	s0,16(sp)
    80002200:	64a2                	ld	s1,8(sp)
    80002202:	6105                	addi	sp,sp,32
    80002204:	8082                	ret

0000000080002206 <sleep>:
{
    80002206:	7179                	addi	sp,sp,-48
    80002208:	f406                	sd	ra,40(sp)
    8000220a:	f022                	sd	s0,32(sp)
    8000220c:	ec26                	sd	s1,24(sp)
    8000220e:	e84a                	sd	s2,16(sp)
    80002210:	e44e                	sd	s3,8(sp)
    80002212:	1800                	addi	s0,sp,48
    80002214:	89aa                	mv	s3,a0
    80002216:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	7d6080e7          	jalr	2006(ra) # 800019ee <myproc>
    80002220:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002222:	05250663          	beq	a0,s2,8000226e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	9fc080e7          	jalr	-1540(ra) # 80000c22 <acquire>
    release(lk);
    8000222e:	854a                	mv	a0,s2
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	aa6080e7          	jalr	-1370(ra) # 80000cd6 <release>
  p->chan = chan;
    80002238:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000223c:	4785                	li	a5,1
    8000223e:	cc9c                	sw	a5,24(s1)
  sched();
    80002240:	00000097          	auipc	ra,0x0
    80002244:	daa080e7          	jalr	-598(ra) # 80001fea <sched>
  p->chan = 0;
    80002248:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000224c:	8526                	mv	a0,s1
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	a88080e7          	jalr	-1400(ra) # 80000cd6 <release>
    acquire(lk);
    80002256:	854a                	mv	a0,s2
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	9ca080e7          	jalr	-1590(ra) # 80000c22 <acquire>
}
    80002260:	70a2                	ld	ra,40(sp)
    80002262:	7402                	ld	s0,32(sp)
    80002264:	64e2                	ld	s1,24(sp)
    80002266:	6942                	ld	s2,16(sp)
    80002268:	69a2                	ld	s3,8(sp)
    8000226a:	6145                	addi	sp,sp,48
    8000226c:	8082                	ret
  p->chan = chan;
    8000226e:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002272:	4785                	li	a5,1
    80002274:	cd1c                	sw	a5,24(a0)
  sched();
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	d74080e7          	jalr	-652(ra) # 80001fea <sched>
  p->chan = 0;
    8000227e:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002282:	bff9                	j	80002260 <sleep+0x5a>

0000000080002284 <wait>:
{
    80002284:	715d                	addi	sp,sp,-80
    80002286:	e486                	sd	ra,72(sp)
    80002288:	e0a2                	sd	s0,64(sp)
    8000228a:	fc26                	sd	s1,56(sp)
    8000228c:	f84a                	sd	s2,48(sp)
    8000228e:	f44e                	sd	s3,40(sp)
    80002290:	f052                	sd	s4,32(sp)
    80002292:	ec56                	sd	s5,24(sp)
    80002294:	e85a                	sd	s6,16(sp)
    80002296:	e45e                	sd	s7,8(sp)
    80002298:	0880                	addi	s0,sp,80
    8000229a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	752080e7          	jalr	1874(ra) # 800019ee <myproc>
    800022a4:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	97c080e7          	jalr	-1668(ra) # 80000c22 <acquire>
    havekids = 0;
    800022ae:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022b0:	4a11                	li	s4,4
        havekids = 1;
    800022b2:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800022b4:	00015997          	auipc	s3,0x15
    800022b8:	6b498993          	addi	s3,s3,1716 # 80017968 <tickslock>
    havekids = 0;
    800022bc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022be:	00010497          	auipc	s1,0x10
    800022c2:	aaa48493          	addi	s1,s1,-1366 # 80011d68 <proc>
    800022c6:	a08d                	j	80002328 <wait+0xa4>
          pid = np->pid;
    800022c8:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022cc:	000b0e63          	beqz	s6,800022e8 <wait+0x64>
    800022d0:	4691                	li	a3,4
    800022d2:	03448613          	addi	a2,s1,52
    800022d6:	85da                	mv	a1,s6
    800022d8:	05093503          	ld	a0,80(s2)
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	404080e7          	jalr	1028(ra) # 800016e0 <copyout>
    800022e4:	02054263          	bltz	a0,80002308 <wait+0x84>
          freeproc(np);
    800022e8:	8526                	mv	a0,s1
    800022ea:	00000097          	auipc	ra,0x0
    800022ee:	8b6080e7          	jalr	-1866(ra) # 80001ba0 <freeproc>
          release(&np->lock);
    800022f2:	8526                	mv	a0,s1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	9e2080e7          	jalr	-1566(ra) # 80000cd6 <release>
          release(&p->lock);
    800022fc:	854a                	mv	a0,s2
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	9d8080e7          	jalr	-1576(ra) # 80000cd6 <release>
          return pid;
    80002306:	a8a9                	j	80002360 <wait+0xdc>
            release(&np->lock);
    80002308:	8526                	mv	a0,s1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	9cc080e7          	jalr	-1588(ra) # 80000cd6 <release>
            release(&p->lock);
    80002312:	854a                	mv	a0,s2
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	9c2080e7          	jalr	-1598(ra) # 80000cd6 <release>
            return -1;
    8000231c:	59fd                	li	s3,-1
    8000231e:	a089                	j	80002360 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002320:	17048493          	addi	s1,s1,368
    80002324:	03348463          	beq	s1,s3,8000234c <wait+0xc8>
      if(np->parent == p){
    80002328:	709c                	ld	a5,32(s1)
    8000232a:	ff279be3          	bne	a5,s2,80002320 <wait+0x9c>
        acquire(&np->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	8f2080e7          	jalr	-1806(ra) # 80000c22 <acquire>
        if(np->state == ZOMBIE){
    80002338:	4c9c                	lw	a5,24(s1)
    8000233a:	f94787e3          	beq	a5,s4,800022c8 <wait+0x44>
        release(&np->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	996080e7          	jalr	-1642(ra) # 80000cd6 <release>
        havekids = 1;
    80002348:	8756                	mv	a4,s5
    8000234a:	bfd9                	j	80002320 <wait+0x9c>
    if(!havekids || p->killed){
    8000234c:	c701                	beqz	a4,80002354 <wait+0xd0>
    8000234e:	03092783          	lw	a5,48(s2)
    80002352:	c39d                	beqz	a5,80002378 <wait+0xf4>
      release(&p->lock);
    80002354:	854a                	mv	a0,s2
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	980080e7          	jalr	-1664(ra) # 80000cd6 <release>
      return -1;
    8000235e:	59fd                	li	s3,-1
}
    80002360:	854e                	mv	a0,s3
    80002362:	60a6                	ld	ra,72(sp)
    80002364:	6406                	ld	s0,64(sp)
    80002366:	74e2                	ld	s1,56(sp)
    80002368:	7942                	ld	s2,48(sp)
    8000236a:	79a2                	ld	s3,40(sp)
    8000236c:	7a02                	ld	s4,32(sp)
    8000236e:	6ae2                	ld	s5,24(sp)
    80002370:	6b42                	ld	s6,16(sp)
    80002372:	6ba2                	ld	s7,8(sp)
    80002374:	6161                	addi	sp,sp,80
    80002376:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002378:	85ca                	mv	a1,s2
    8000237a:	854a                	mv	a0,s2
    8000237c:	00000097          	auipc	ra,0x0
    80002380:	e8a080e7          	jalr	-374(ra) # 80002206 <sleep>
    havekids = 0;
    80002384:	bf25                	j	800022bc <wait+0x38>

0000000080002386 <wakeup>:
{
    80002386:	7139                	addi	sp,sp,-64
    80002388:	fc06                	sd	ra,56(sp)
    8000238a:	f822                	sd	s0,48(sp)
    8000238c:	f426                	sd	s1,40(sp)
    8000238e:	f04a                	sd	s2,32(sp)
    80002390:	ec4e                	sd	s3,24(sp)
    80002392:	e852                	sd	s4,16(sp)
    80002394:	e456                	sd	s5,8(sp)
    80002396:	0080                	addi	s0,sp,64
    80002398:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000239a:	00010497          	auipc	s1,0x10
    8000239e:	9ce48493          	addi	s1,s1,-1586 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023a2:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023a4:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023a6:	00015917          	auipc	s2,0x15
    800023aa:	5c290913          	addi	s2,s2,1474 # 80017968 <tickslock>
    800023ae:	a811                	j	800023c2 <wakeup+0x3c>
    release(&p->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	924080e7          	jalr	-1756(ra) # 80000cd6 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023ba:	17048493          	addi	s1,s1,368
    800023be:	03248063          	beq	s1,s2,800023de <wakeup+0x58>
    acquire(&p->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	85e080e7          	jalr	-1954(ra) # 80000c22 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023cc:	4c9c                	lw	a5,24(s1)
    800023ce:	ff3791e3          	bne	a5,s3,800023b0 <wakeup+0x2a>
    800023d2:	749c                	ld	a5,40(s1)
    800023d4:	fd479ee3          	bne	a5,s4,800023b0 <wakeup+0x2a>
      p->state = RUNNABLE;
    800023d8:	0154ac23          	sw	s5,24(s1)
    800023dc:	bfd1                	j	800023b0 <wakeup+0x2a>
}
    800023de:	70e2                	ld	ra,56(sp)
    800023e0:	7442                	ld	s0,48(sp)
    800023e2:	74a2                	ld	s1,40(sp)
    800023e4:	7902                	ld	s2,32(sp)
    800023e6:	69e2                	ld	s3,24(sp)
    800023e8:	6a42                	ld	s4,16(sp)
    800023ea:	6aa2                	ld	s5,8(sp)
    800023ec:	6121                	addi	sp,sp,64
    800023ee:	8082                	ret

00000000800023f0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023f0:	7179                	addi	sp,sp,-48
    800023f2:	f406                	sd	ra,40(sp)
    800023f4:	f022                	sd	s0,32(sp)
    800023f6:	ec26                	sd	s1,24(sp)
    800023f8:	e84a                	sd	s2,16(sp)
    800023fa:	e44e                	sd	s3,8(sp)
    800023fc:	1800                	addi	s0,sp,48
    800023fe:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002400:	00010497          	auipc	s1,0x10
    80002404:	96848493          	addi	s1,s1,-1688 # 80011d68 <proc>
    80002408:	00015997          	auipc	s3,0x15
    8000240c:	56098993          	addi	s3,s3,1376 # 80017968 <tickslock>
    acquire(&p->lock);
    80002410:	8526                	mv	a0,s1
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	810080e7          	jalr	-2032(ra) # 80000c22 <acquire>
    if(p->pid == pid){
    8000241a:	5c9c                	lw	a5,56(s1)
    8000241c:	01278d63          	beq	a5,s2,80002436 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002420:	8526                	mv	a0,s1
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	8b4080e7          	jalr	-1868(ra) # 80000cd6 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000242a:	17048493          	addi	s1,s1,368
    8000242e:	ff3491e3          	bne	s1,s3,80002410 <kill+0x20>
  }
  return -1;
    80002432:	557d                	li	a0,-1
    80002434:	a821                	j	8000244c <kill+0x5c>
      p->killed = 1;
    80002436:	4785                	li	a5,1
    80002438:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000243a:	4c98                	lw	a4,24(s1)
    8000243c:	00f70f63          	beq	a4,a5,8000245a <kill+0x6a>
      release(&p->lock);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	894080e7          	jalr	-1900(ra) # 80000cd6 <release>
      return 0;
    8000244a:	4501                	li	a0,0
}
    8000244c:	70a2                	ld	ra,40(sp)
    8000244e:	7402                	ld	s0,32(sp)
    80002450:	64e2                	ld	s1,24(sp)
    80002452:	6942                	ld	s2,16(sp)
    80002454:	69a2                	ld	s3,8(sp)
    80002456:	6145                	addi	sp,sp,48
    80002458:	8082                	ret
        p->state = RUNNABLE;
    8000245a:	4789                	li	a5,2
    8000245c:	cc9c                	sw	a5,24(s1)
    8000245e:	b7cd                	j	80002440 <kill+0x50>

0000000080002460 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002460:	7179                	addi	sp,sp,-48
    80002462:	f406                	sd	ra,40(sp)
    80002464:	f022                	sd	s0,32(sp)
    80002466:	ec26                	sd	s1,24(sp)
    80002468:	e84a                	sd	s2,16(sp)
    8000246a:	e44e                	sd	s3,8(sp)
    8000246c:	e052                	sd	s4,0(sp)
    8000246e:	1800                	addi	s0,sp,48
    80002470:	84aa                	mv	s1,a0
    80002472:	892e                	mv	s2,a1
    80002474:	89b2                	mv	s3,a2
    80002476:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	576080e7          	jalr	1398(ra) # 800019ee <myproc>
  if(user_dst){
    80002480:	c08d                	beqz	s1,800024a2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002482:	86d2                	mv	a3,s4
    80002484:	864e                	mv	a2,s3
    80002486:	85ca                	mv	a1,s2
    80002488:	6928                	ld	a0,80(a0)
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	256080e7          	jalr	598(ra) # 800016e0 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002492:	70a2                	ld	ra,40(sp)
    80002494:	7402                	ld	s0,32(sp)
    80002496:	64e2                	ld	s1,24(sp)
    80002498:	6942                	ld	s2,16(sp)
    8000249a:	69a2                	ld	s3,8(sp)
    8000249c:	6a02                	ld	s4,0(sp)
    8000249e:	6145                	addi	sp,sp,48
    800024a0:	8082                	ret
    memmove((char *)dst, src, len);
    800024a2:	000a061b          	sext.w	a2,s4
    800024a6:	85ce                	mv	a1,s3
    800024a8:	854a                	mv	a0,s2
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	8d0080e7          	jalr	-1840(ra) # 80000d7a <memmove>
    return 0;
    800024b2:	8526                	mv	a0,s1
    800024b4:	bff9                	j	80002492 <either_copyout+0x32>

00000000800024b6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b6:	7179                	addi	sp,sp,-48
    800024b8:	f406                	sd	ra,40(sp)
    800024ba:	f022                	sd	s0,32(sp)
    800024bc:	ec26                	sd	s1,24(sp)
    800024be:	e84a                	sd	s2,16(sp)
    800024c0:	e44e                	sd	s3,8(sp)
    800024c2:	e052                	sd	s4,0(sp)
    800024c4:	1800                	addi	s0,sp,48
    800024c6:	892a                	mv	s2,a0
    800024c8:	84ae                	mv	s1,a1
    800024ca:	89b2                	mv	s3,a2
    800024cc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	520080e7          	jalr	1312(ra) # 800019ee <myproc>
  if(user_src){
    800024d6:	c08d                	beqz	s1,800024f8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d8:	86d2                	mv	a3,s4
    800024da:	864e                	mv	a2,s3
    800024dc:	85ca                	mv	a1,s2
    800024de:	6928                	ld	a0,80(a0)
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	28c080e7          	jalr	652(ra) # 8000176c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024e8:	70a2                	ld	ra,40(sp)
    800024ea:	7402                	ld	s0,32(sp)
    800024ec:	64e2                	ld	s1,24(sp)
    800024ee:	6942                	ld	s2,16(sp)
    800024f0:	69a2                	ld	s3,8(sp)
    800024f2:	6a02                	ld	s4,0(sp)
    800024f4:	6145                	addi	sp,sp,48
    800024f6:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f8:	000a061b          	sext.w	a2,s4
    800024fc:	85ce                	mv	a1,s3
    800024fe:	854a                	mv	a0,s2
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	87a080e7          	jalr	-1926(ra) # 80000d7a <memmove>
    return 0;
    80002508:	8526                	mv	a0,s1
    8000250a:	bff9                	j	800024e8 <either_copyin+0x32>

000000008000250c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000250c:	715d                	addi	sp,sp,-80
    8000250e:	e486                	sd	ra,72(sp)
    80002510:	e0a2                	sd	s0,64(sp)
    80002512:	fc26                	sd	s1,56(sp)
    80002514:	f84a                	sd	s2,48(sp)
    80002516:	f44e                	sd	s3,40(sp)
    80002518:	f052                	sd	s4,32(sp)
    8000251a:	ec56                	sd	s5,24(sp)
    8000251c:	e85a                	sd	s6,16(sp)
    8000251e:	e45e                	sd	s7,8(sp)
    80002520:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002522:	00006517          	auipc	a0,0x6
    80002526:	ba650513          	addi	a0,a0,-1114 # 800080c8 <digits+0x88>
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	062080e7          	jalr	98(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002532:	00010497          	auipc	s1,0x10
    80002536:	98e48493          	addi	s1,s1,-1650 # 80011ec0 <proc+0x158>
    8000253a:	00015917          	auipc	s2,0x15
    8000253e:	58690913          	addi	s2,s2,1414 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002542:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002544:	00006997          	auipc	s3,0x6
    80002548:	d2498993          	addi	s3,s3,-732 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000254c:	00006a97          	auipc	s5,0x6
    80002550:	d24a8a93          	addi	s5,s5,-732 # 80008270 <digits+0x230>
    printf("\n");
    80002554:	00006a17          	auipc	s4,0x6
    80002558:	b74a0a13          	addi	s4,s4,-1164 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255c:	00006b97          	auipc	s7,0x6
    80002560:	dacb8b93          	addi	s7,s7,-596 # 80008308 <states.0>
    80002564:	a00d                	j	80002586 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002566:	ee06a583          	lw	a1,-288(a3)
    8000256a:	8556                	mv	a0,s5
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	020080e7          	jalr	32(ra) # 8000058c <printf>
    printf("\n");
    80002574:	8552                	mv	a0,s4
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	016080e7          	jalr	22(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257e:	17048493          	addi	s1,s1,368
    80002582:	03248163          	beq	s1,s2,800025a4 <procdump+0x98>
    if(p->state == UNUSED)
    80002586:	86a6                	mv	a3,s1
    80002588:	ec04a783          	lw	a5,-320(s1)
    8000258c:	dbed                	beqz	a5,8000257e <procdump+0x72>
      state = "???";
    8000258e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002590:	fcfb6be3          	bltu	s6,a5,80002566 <procdump+0x5a>
    80002594:	1782                	slli	a5,a5,0x20
    80002596:	9381                	srli	a5,a5,0x20
    80002598:	078e                	slli	a5,a5,0x3
    8000259a:	97de                	add	a5,a5,s7
    8000259c:	6390                	ld	a2,0(a5)
    8000259e:	f661                	bnez	a2,80002566 <procdump+0x5a>
      state = "???";
    800025a0:	864e                	mv	a2,s3
    800025a2:	b7d1                	j	80002566 <procdump+0x5a>
  }
}
    800025a4:	60a6                	ld	ra,72(sp)
    800025a6:	6406                	ld	s0,64(sp)
    800025a8:	74e2                	ld	s1,56(sp)
    800025aa:	7942                	ld	s2,48(sp)
    800025ac:	79a2                	ld	s3,40(sp)
    800025ae:	7a02                	ld	s4,32(sp)
    800025b0:	6ae2                	ld	s5,24(sp)
    800025b2:	6b42                	ld	s6,16(sp)
    800025b4:	6ba2                	ld	s7,8(sp)
    800025b6:	6161                	addi	sp,sp,80
    800025b8:	8082                	ret

00000000800025ba <proc_size>:

// add
int 
proc_size(){
    800025ba:	1141                	addi	sp,sp,-16
    800025bc:	e422                	sd	s0,8(sp)
    800025be:	0800                	addi	s0,sp,16
  int ans=0;
  for(int i=0;i<NPROC;i++){
    800025c0:	0000f797          	auipc	a5,0xf
    800025c4:	7c078793          	addi	a5,a5,1984 # 80011d80 <proc+0x18>
    800025c8:	00015697          	auipc	a3,0x15
    800025cc:	3b868693          	addi	a3,a3,952 # 80017980 <bcache>
  int ans=0;
    800025d0:	4501                	li	a0,0
    800025d2:	a029                	j	800025dc <proc_size+0x22>
  for(int i=0;i<NPROC;i++){
    800025d4:	17078793          	addi	a5,a5,368
    800025d8:	00d78663          	beq	a5,a3,800025e4 <proc_size+0x2a>
    if(proc[i].state == UNUSED) ans++;
    800025dc:	4398                	lw	a4,0(a5)
    800025de:	fb7d                	bnez	a4,800025d4 <proc_size+0x1a>
    800025e0:	2505                	addiw	a0,a0,1
    800025e2:	bfcd                	j	800025d4 <proc_size+0x1a>
  }
  return ans;
}
    800025e4:	6422                	ld	s0,8(sp)
    800025e6:	0141                	addi	sp,sp,16
    800025e8:	8082                	ret

00000000800025ea <freefd>:
// self
int freefd(int test){
    800025ea:	7125                	addi	sp,sp,-416
    800025ec:	ef06                	sd	ra,408(sp)
    800025ee:	eb22                	sd	s0,400(sp)
    800025f0:	e726                	sd	s1,392(sp)
    800025f2:	e34a                	sd	s2,384(sp)
    800025f4:	fece                	sd	s3,376(sp)
    800025f6:	fad2                	sd	s4,368(sp)
    800025f8:	1300                	addi	s0,sp,416
  // int ans =0;
  int em[90];
  for(int j=0;j<=63;j++){
    800025fa:	e6840913          	addi	s2,s0,-408
    800025fe:	00010497          	auipc	s1,0x10
    80002602:	8ba48493          	addi	s1,s1,-1862 # 80011eb8 <proc+0x150>
    80002606:	00015a17          	auipc	s4,0x15
    8000260a:	4b2a0a13          	addi	s4,s4,1202 # 80017ab8 <bcache+0x138>
    for(int i=0;i<16;i++){
      // printf("%d\n",i);
      // if(proc[test].ofile[i] == 0) ans++;
      if(proc[j].ofile[i]==0) em[j]++;
    }
    printf("%d,",em[j]);
    8000260e:	00006997          	auipc	s3,0x6
    80002612:	c7298993          	addi	s3,s3,-910 # 80008280 <digits+0x240>
    80002616:	a02d                	j	80002640 <freefd+0x56>
    for(int i=0;i<16;i++){
    80002618:	07a1                	addi	a5,a5,8
    8000261a:	00978863          	beq	a5,s1,8000262a <freefd+0x40>
      if(proc[j].ofile[i]==0) em[j]++;
    8000261e:	6398                	ld	a4,0(a5)
    80002620:	ff65                	bnez	a4,80002618 <freefd+0x2e>
    80002622:	4298                	lw	a4,0(a3)
    80002624:	2705                	addiw	a4,a4,1
    80002626:	c298                	sw	a4,0(a3)
    80002628:	bfc5                	j	80002618 <freefd+0x2e>
    printf("%d,",em[j]);
    8000262a:	428c                	lw	a1,0(a3)
    8000262c:	854e                	mv	a0,s3
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	f5e080e7          	jalr	-162(ra) # 8000058c <printf>
  for(int j=0;j<=63;j++){
    80002636:	0911                	addi	s2,s2,4
    80002638:	17048493          	addi	s1,s1,368
    8000263c:	01448863          	beq	s1,s4,8000264c <freefd+0x62>
    em[j]=0;
    80002640:	86ca                	mv	a3,s2
    80002642:	00092023          	sw	zero,0(s2)
    for(int i=0;i<16;i++){
    80002646:	f8048793          	addi	a5,s1,-128
    8000264a:	bfd1                	j	8000261e <freefd+0x34>
  }
  printf("\n========================================\n========================================\n");
    8000264c:	00006517          	auipc	a0,0x6
    80002650:	c3c50513          	addi	a0,a0,-964 # 80008288 <digits+0x248>
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	f38080e7          	jalr	-200(ra) # 8000058c <printf>
  
  return em[2];
}
    8000265c:	e7042503          	lw	a0,-400(s0)
    80002660:	60fa                	ld	ra,408(sp)
    80002662:	645a                	ld	s0,400(sp)
    80002664:	64ba                	ld	s1,392(sp)
    80002666:	691a                	ld	s2,384(sp)
    80002668:	79f6                	ld	s3,376(sp)
    8000266a:	7a56                	ld	s4,368(sp)
    8000266c:	611d                	addi	sp,sp,416
    8000266e:	8082                	ret

0000000080002670 <swtch>:
    80002670:	00153023          	sd	ra,0(a0)
    80002674:	00253423          	sd	sp,8(a0)
    80002678:	e900                	sd	s0,16(a0)
    8000267a:	ed04                	sd	s1,24(a0)
    8000267c:	03253023          	sd	s2,32(a0)
    80002680:	03353423          	sd	s3,40(a0)
    80002684:	03453823          	sd	s4,48(a0)
    80002688:	03553c23          	sd	s5,56(a0)
    8000268c:	05653023          	sd	s6,64(a0)
    80002690:	05753423          	sd	s7,72(a0)
    80002694:	05853823          	sd	s8,80(a0)
    80002698:	05953c23          	sd	s9,88(a0)
    8000269c:	07a53023          	sd	s10,96(a0)
    800026a0:	07b53423          	sd	s11,104(a0)
    800026a4:	0005b083          	ld	ra,0(a1)
    800026a8:	0085b103          	ld	sp,8(a1)
    800026ac:	6980                	ld	s0,16(a1)
    800026ae:	6d84                	ld	s1,24(a1)
    800026b0:	0205b903          	ld	s2,32(a1)
    800026b4:	0285b983          	ld	s3,40(a1)
    800026b8:	0305ba03          	ld	s4,48(a1)
    800026bc:	0385ba83          	ld	s5,56(a1)
    800026c0:	0405bb03          	ld	s6,64(a1)
    800026c4:	0485bb83          	ld	s7,72(a1)
    800026c8:	0505bc03          	ld	s8,80(a1)
    800026cc:	0585bc83          	ld	s9,88(a1)
    800026d0:	0605bd03          	ld	s10,96(a1)
    800026d4:	0685bd83          	ld	s11,104(a1)
    800026d8:	8082                	ret

00000000800026da <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026da:	1141                	addi	sp,sp,-16
    800026dc:	e406                	sd	ra,8(sp)
    800026de:	e022                	sd	s0,0(sp)
    800026e0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026e2:	00006597          	auipc	a1,0x6
    800026e6:	c4e58593          	addi	a1,a1,-946 # 80008330 <states.0+0x28>
    800026ea:	00015517          	auipc	a0,0x15
    800026ee:	27e50513          	addi	a0,a0,638 # 80017968 <tickslock>
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	4a0080e7          	jalr	1184(ra) # 80000b92 <initlock>
}
    800026fa:	60a2                	ld	ra,8(sp)
    800026fc:	6402                	ld	s0,0(sp)
    800026fe:	0141                	addi	sp,sp,16
    80002700:	8082                	ret

0000000080002702 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002702:	1141                	addi	sp,sp,-16
    80002704:	e422                	sd	s0,8(sp)
    80002706:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002708:	00003797          	auipc	a5,0x3
    8000270c:	59878793          	addi	a5,a5,1432 # 80005ca0 <kernelvec>
    80002710:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002714:	6422                	ld	s0,8(sp)
    80002716:	0141                	addi	sp,sp,16
    80002718:	8082                	ret

000000008000271a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000271a:	1141                	addi	sp,sp,-16
    8000271c:	e406                	sd	ra,8(sp)
    8000271e:	e022                	sd	s0,0(sp)
    80002720:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002722:	fffff097          	auipc	ra,0xfffff
    80002726:	2cc080e7          	jalr	716(ra) # 800019ee <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000272a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000272e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002730:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002734:	00005617          	auipc	a2,0x5
    80002738:	8cc60613          	addi	a2,a2,-1844 # 80007000 <_trampoline>
    8000273c:	00005697          	auipc	a3,0x5
    80002740:	8c468693          	addi	a3,a3,-1852 # 80007000 <_trampoline>
    80002744:	8e91                	sub	a3,a3,a2
    80002746:	040007b7          	lui	a5,0x4000
    8000274a:	17fd                	addi	a5,a5,-1
    8000274c:	07b2                	slli	a5,a5,0xc
    8000274e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002750:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002754:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002756:	180026f3          	csrr	a3,satp
    8000275a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000275c:	6d38                	ld	a4,88(a0)
    8000275e:	6134                	ld	a3,64(a0)
    80002760:	6585                	lui	a1,0x1
    80002762:	96ae                	add	a3,a3,a1
    80002764:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002766:	6d38                	ld	a4,88(a0)
    80002768:	00000697          	auipc	a3,0x0
    8000276c:	13868693          	addi	a3,a3,312 # 800028a0 <usertrap>
    80002770:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002772:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002774:	8692                	mv	a3,tp
    80002776:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002778:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000277c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002780:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002784:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002788:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000278a:	6f18                	ld	a4,24(a4)
    8000278c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002790:	692c                	ld	a1,80(a0)
    80002792:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002794:	00005717          	auipc	a4,0x5
    80002798:	8fc70713          	addi	a4,a4,-1796 # 80007090 <userret>
    8000279c:	8f11                	sub	a4,a4,a2
    8000279e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027a0:	577d                	li	a4,-1
    800027a2:	177e                	slli	a4,a4,0x3f
    800027a4:	8dd9                	or	a1,a1,a4
    800027a6:	02000537          	lui	a0,0x2000
    800027aa:	157d                	addi	a0,a0,-1
    800027ac:	0536                	slli	a0,a0,0xd
    800027ae:	9782                	jalr	a5
}
    800027b0:	60a2                	ld	ra,8(sp)
    800027b2:	6402                	ld	s0,0(sp)
    800027b4:	0141                	addi	sp,sp,16
    800027b6:	8082                	ret

00000000800027b8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027b8:	1101                	addi	sp,sp,-32
    800027ba:	ec06                	sd	ra,24(sp)
    800027bc:	e822                	sd	s0,16(sp)
    800027be:	e426                	sd	s1,8(sp)
    800027c0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027c2:	00015497          	auipc	s1,0x15
    800027c6:	1a648493          	addi	s1,s1,422 # 80017968 <tickslock>
    800027ca:	8526                	mv	a0,s1
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	456080e7          	jalr	1110(ra) # 80000c22 <acquire>
  ticks++;
    800027d4:	00007517          	auipc	a0,0x7
    800027d8:	84c50513          	addi	a0,a0,-1972 # 80009020 <ticks>
    800027dc:	411c                	lw	a5,0(a0)
    800027de:	2785                	addiw	a5,a5,1
    800027e0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027e2:	00000097          	auipc	ra,0x0
    800027e6:	ba4080e7          	jalr	-1116(ra) # 80002386 <wakeup>
  release(&tickslock);
    800027ea:	8526                	mv	a0,s1
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	4ea080e7          	jalr	1258(ra) # 80000cd6 <release>
}
    800027f4:	60e2                	ld	ra,24(sp)
    800027f6:	6442                	ld	s0,16(sp)
    800027f8:	64a2                	ld	s1,8(sp)
    800027fa:	6105                	addi	sp,sp,32
    800027fc:	8082                	ret

00000000800027fe <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027fe:	1101                	addi	sp,sp,-32
    80002800:	ec06                	sd	ra,24(sp)
    80002802:	e822                	sd	s0,16(sp)
    80002804:	e426                	sd	s1,8(sp)
    80002806:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002808:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000280c:	00074d63          	bltz	a4,80002826 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002810:	57fd                	li	a5,-1
    80002812:	17fe                	slli	a5,a5,0x3f
    80002814:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002816:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002818:	06f70363          	beq	a4,a5,8000287e <devintr+0x80>
  }
}
    8000281c:	60e2                	ld	ra,24(sp)
    8000281e:	6442                	ld	s0,16(sp)
    80002820:	64a2                	ld	s1,8(sp)
    80002822:	6105                	addi	sp,sp,32
    80002824:	8082                	ret
     (scause & 0xff) == 9){
    80002826:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000282a:	46a5                	li	a3,9
    8000282c:	fed792e3          	bne	a5,a3,80002810 <devintr+0x12>
    int irq = plic_claim();
    80002830:	00003097          	auipc	ra,0x3
    80002834:	578080e7          	jalr	1400(ra) # 80005da8 <plic_claim>
    80002838:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000283a:	47a9                	li	a5,10
    8000283c:	02f50763          	beq	a0,a5,8000286a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002840:	4785                	li	a5,1
    80002842:	02f50963          	beq	a0,a5,80002874 <devintr+0x76>
    return 1;
    80002846:	4505                	li	a0,1
    } else if(irq){
    80002848:	d8f1                	beqz	s1,8000281c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000284a:	85a6                	mv	a1,s1
    8000284c:	00006517          	auipc	a0,0x6
    80002850:	aec50513          	addi	a0,a0,-1300 # 80008338 <states.0+0x30>
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	d38080e7          	jalr	-712(ra) # 8000058c <printf>
      plic_complete(irq);
    8000285c:	8526                	mv	a0,s1
    8000285e:	00003097          	auipc	ra,0x3
    80002862:	56e080e7          	jalr	1390(ra) # 80005dcc <plic_complete>
    return 1;
    80002866:	4505                	li	a0,1
    80002868:	bf55                	j	8000281c <devintr+0x1e>
      uartintr();
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	158080e7          	jalr	344(ra) # 800009c2 <uartintr>
    80002872:	b7ed                	j	8000285c <devintr+0x5e>
      virtio_disk_intr();
    80002874:	00004097          	auipc	ra,0x4
    80002878:	9d2080e7          	jalr	-1582(ra) # 80006246 <virtio_disk_intr>
    8000287c:	b7c5                	j	8000285c <devintr+0x5e>
    if(cpuid() == 0){
    8000287e:	fffff097          	auipc	ra,0xfffff
    80002882:	144080e7          	jalr	324(ra) # 800019c2 <cpuid>
    80002886:	c901                	beqz	a0,80002896 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002888:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000288c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000288e:	14479073          	csrw	sip,a5
    return 2;
    80002892:	4509                	li	a0,2
    80002894:	b761                	j	8000281c <devintr+0x1e>
      clockintr();
    80002896:	00000097          	auipc	ra,0x0
    8000289a:	f22080e7          	jalr	-222(ra) # 800027b8 <clockintr>
    8000289e:	b7ed                	j	80002888 <devintr+0x8a>

00000000800028a0 <usertrap>:
{
    800028a0:	1101                	addi	sp,sp,-32
    800028a2:	ec06                	sd	ra,24(sp)
    800028a4:	e822                	sd	s0,16(sp)
    800028a6:	e426                	sd	s1,8(sp)
    800028a8:	e04a                	sd	s2,0(sp)
    800028aa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ac:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028b0:	1007f793          	andi	a5,a5,256
    800028b4:	e3ad                	bnez	a5,80002916 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028b6:	00003797          	auipc	a5,0x3
    800028ba:	3ea78793          	addi	a5,a5,1002 # 80005ca0 <kernelvec>
    800028be:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028c2:	fffff097          	auipc	ra,0xfffff
    800028c6:	12c080e7          	jalr	300(ra) # 800019ee <myproc>
    800028ca:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028cc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ce:	14102773          	csrr	a4,sepc
    800028d2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028d8:	47a1                	li	a5,8
    800028da:	04f71c63          	bne	a4,a5,80002932 <usertrap+0x92>
    if(p->killed)
    800028de:	591c                	lw	a5,48(a0)
    800028e0:	e3b9                	bnez	a5,80002926 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028e2:	6cb8                	ld	a4,88(s1)
    800028e4:	6f1c                	ld	a5,24(a4)
    800028e6:	0791                	addi	a5,a5,4
    800028e8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028ee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f2:	10079073          	csrw	sstatus,a5
    syscall();
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	2e0080e7          	jalr	736(ra) # 80002bd6 <syscall>
  if(p->killed)
    800028fe:	589c                	lw	a5,48(s1)
    80002900:	ebc1                	bnez	a5,80002990 <usertrap+0xf0>
  usertrapret();
    80002902:	00000097          	auipc	ra,0x0
    80002906:	e18080e7          	jalr	-488(ra) # 8000271a <usertrapret>
}
    8000290a:	60e2                	ld	ra,24(sp)
    8000290c:	6442                	ld	s0,16(sp)
    8000290e:	64a2                	ld	s1,8(sp)
    80002910:	6902                	ld	s2,0(sp)
    80002912:	6105                	addi	sp,sp,32
    80002914:	8082                	ret
    panic("usertrap: not from user mode");
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	a4250513          	addi	a0,a0,-1470 # 80008358 <states.0+0x50>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c24080e7          	jalr	-988(ra) # 80000542 <panic>
      exit(-1);
    80002926:	557d                	li	a0,-1
    80002928:	fffff097          	auipc	ra,0xfffff
    8000292c:	798080e7          	jalr	1944(ra) # 800020c0 <exit>
    80002930:	bf4d                	j	800028e2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002932:	00000097          	auipc	ra,0x0
    80002936:	ecc080e7          	jalr	-308(ra) # 800027fe <devintr>
    8000293a:	892a                	mv	s2,a0
    8000293c:	c501                	beqz	a0,80002944 <usertrap+0xa4>
  if(p->killed)
    8000293e:	589c                	lw	a5,48(s1)
    80002940:	c3a1                	beqz	a5,80002980 <usertrap+0xe0>
    80002942:	a815                	j	80002976 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002944:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002948:	5c90                	lw	a2,56(s1)
    8000294a:	00006517          	auipc	a0,0x6
    8000294e:	a2e50513          	addi	a0,a0,-1490 # 80008378 <states.0+0x70>
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	c3a080e7          	jalr	-966(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000295a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000295e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002962:	00006517          	auipc	a0,0x6
    80002966:	a4650513          	addi	a0,a0,-1466 # 800083a8 <states.0+0xa0>
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	c22080e7          	jalr	-990(ra) # 8000058c <printf>
    p->killed = 1;
    80002972:	4785                	li	a5,1
    80002974:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002976:	557d                	li	a0,-1
    80002978:	fffff097          	auipc	ra,0xfffff
    8000297c:	748080e7          	jalr	1864(ra) # 800020c0 <exit>
  if(which_dev == 2)
    80002980:	4789                	li	a5,2
    80002982:	f8f910e3          	bne	s2,a5,80002902 <usertrap+0x62>
    yield();
    80002986:	00000097          	auipc	ra,0x0
    8000298a:	844080e7          	jalr	-1980(ra) # 800021ca <yield>
    8000298e:	bf95                	j	80002902 <usertrap+0x62>
  int which_dev = 0;
    80002990:	4901                	li	s2,0
    80002992:	b7d5                	j	80002976 <usertrap+0xd6>

0000000080002994 <kerneltrap>:
{
    80002994:	7179                	addi	sp,sp,-48
    80002996:	f406                	sd	ra,40(sp)
    80002998:	f022                	sd	s0,32(sp)
    8000299a:	ec26                	sd	s1,24(sp)
    8000299c:	e84a                	sd	s2,16(sp)
    8000299e:	e44e                	sd	s3,8(sp)
    800029a0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029a2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029aa:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029ae:	1004f793          	andi	a5,s1,256
    800029b2:	cb85                	beqz	a5,800029e2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029b8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029ba:	ef85                	bnez	a5,800029f2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029bc:	00000097          	auipc	ra,0x0
    800029c0:	e42080e7          	jalr	-446(ra) # 800027fe <devintr>
    800029c4:	cd1d                	beqz	a0,80002a02 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029c6:	4789                	li	a5,2
    800029c8:	06f50a63          	beq	a0,a5,80002a3c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029cc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d0:	10049073          	csrw	sstatus,s1
}
    800029d4:	70a2                	ld	ra,40(sp)
    800029d6:	7402                	ld	s0,32(sp)
    800029d8:	64e2                	ld	s1,24(sp)
    800029da:	6942                	ld	s2,16(sp)
    800029dc:	69a2                	ld	s3,8(sp)
    800029de:	6145                	addi	sp,sp,48
    800029e0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	9e650513          	addi	a0,a0,-1562 # 800083c8 <states.0+0xc0>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	b58080e7          	jalr	-1192(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    800029f2:	00006517          	auipc	a0,0x6
    800029f6:	9fe50513          	addi	a0,a0,-1538 # 800083f0 <states.0+0xe8>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	b48080e7          	jalr	-1208(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    80002a02:	85ce                	mv	a1,s3
    80002a04:	00006517          	auipc	a0,0x6
    80002a08:	a0c50513          	addi	a0,a0,-1524 # 80008410 <states.0+0x108>
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	b80080e7          	jalr	-1152(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a14:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a18:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a1c:	00006517          	auipc	a0,0x6
    80002a20:	a0450513          	addi	a0,a0,-1532 # 80008420 <states.0+0x118>
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	b68080e7          	jalr	-1176(ra) # 8000058c <printf>
    panic("kerneltrap");
    80002a2c:	00006517          	auipc	a0,0x6
    80002a30:	a0c50513          	addi	a0,a0,-1524 # 80008438 <states.0+0x130>
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	b0e080e7          	jalr	-1266(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a3c:	fffff097          	auipc	ra,0xfffff
    80002a40:	fb2080e7          	jalr	-78(ra) # 800019ee <myproc>
    80002a44:	d541                	beqz	a0,800029cc <kerneltrap+0x38>
    80002a46:	fffff097          	auipc	ra,0xfffff
    80002a4a:	fa8080e7          	jalr	-88(ra) # 800019ee <myproc>
    80002a4e:	4d18                	lw	a4,24(a0)
    80002a50:	478d                	li	a5,3
    80002a52:	f6f71de3          	bne	a4,a5,800029cc <kerneltrap+0x38>
    yield();
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	774080e7          	jalr	1908(ra) # 800021ca <yield>
    80002a5e:	b7bd                	j	800029cc <kerneltrap+0x38>

0000000080002a60 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a60:	1101                	addi	sp,sp,-32
    80002a62:	ec06                	sd	ra,24(sp)
    80002a64:	e822                	sd	s0,16(sp)
    80002a66:	e426                	sd	s1,8(sp)
    80002a68:	1000                	addi	s0,sp,32
    80002a6a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a6c:	fffff097          	auipc	ra,0xfffff
    80002a70:	f82080e7          	jalr	-126(ra) # 800019ee <myproc>
  switch (n) {
    80002a74:	4795                	li	a5,5
    80002a76:	0497e163          	bltu	a5,s1,80002ab8 <argraw+0x58>
    80002a7a:	048a                	slli	s1,s1,0x2
    80002a7c:	00006717          	auipc	a4,0x6
    80002a80:	ab470713          	addi	a4,a4,-1356 # 80008530 <states.0+0x228>
    80002a84:	94ba                	add	s1,s1,a4
    80002a86:	409c                	lw	a5,0(s1)
    80002a88:	97ba                	add	a5,a5,a4
    80002a8a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a8c:	6d3c                	ld	a5,88(a0)
    80002a8e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a90:	60e2                	ld	ra,24(sp)
    80002a92:	6442                	ld	s0,16(sp)
    80002a94:	64a2                	ld	s1,8(sp)
    80002a96:	6105                	addi	sp,sp,32
    80002a98:	8082                	ret
    return p->trapframe->a1;
    80002a9a:	6d3c                	ld	a5,88(a0)
    80002a9c:	7fa8                	ld	a0,120(a5)
    80002a9e:	bfcd                	j	80002a90 <argraw+0x30>
    return p->trapframe->a2;
    80002aa0:	6d3c                	ld	a5,88(a0)
    80002aa2:	63c8                	ld	a0,128(a5)
    80002aa4:	b7f5                	j	80002a90 <argraw+0x30>
    return p->trapframe->a3;
    80002aa6:	6d3c                	ld	a5,88(a0)
    80002aa8:	67c8                	ld	a0,136(a5)
    80002aaa:	b7dd                	j	80002a90 <argraw+0x30>
    return p->trapframe->a4;
    80002aac:	6d3c                	ld	a5,88(a0)
    80002aae:	6bc8                	ld	a0,144(a5)
    80002ab0:	b7c5                	j	80002a90 <argraw+0x30>
    return p->trapframe->a5;
    80002ab2:	6d3c                	ld	a5,88(a0)
    80002ab4:	6fc8                	ld	a0,152(a5)
    80002ab6:	bfe9                	j	80002a90 <argraw+0x30>
  panic("argraw");
    80002ab8:	00006517          	auipc	a0,0x6
    80002abc:	99050513          	addi	a0,a0,-1648 # 80008448 <states.0+0x140>
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	a82080e7          	jalr	-1406(ra) # 80000542 <panic>

0000000080002ac8 <fetchaddr>:
{
    80002ac8:	1101                	addi	sp,sp,-32
    80002aca:	ec06                	sd	ra,24(sp)
    80002acc:	e822                	sd	s0,16(sp)
    80002ace:	e426                	sd	s1,8(sp)
    80002ad0:	e04a                	sd	s2,0(sp)
    80002ad2:	1000                	addi	s0,sp,32
    80002ad4:	84aa                	mv	s1,a0
    80002ad6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	f16080e7          	jalr	-234(ra) # 800019ee <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ae0:	653c                	ld	a5,72(a0)
    80002ae2:	02f4f863          	bgeu	s1,a5,80002b12 <fetchaddr+0x4a>
    80002ae6:	00848713          	addi	a4,s1,8
    80002aea:	02e7e663          	bltu	a5,a4,80002b16 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002aee:	46a1                	li	a3,8
    80002af0:	8626                	mv	a2,s1
    80002af2:	85ca                	mv	a1,s2
    80002af4:	6928                	ld	a0,80(a0)
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	c76080e7          	jalr	-906(ra) # 8000176c <copyin>
    80002afe:	00a03533          	snez	a0,a0
    80002b02:	40a00533          	neg	a0,a0
}
    80002b06:	60e2                	ld	ra,24(sp)
    80002b08:	6442                	ld	s0,16(sp)
    80002b0a:	64a2                	ld	s1,8(sp)
    80002b0c:	6902                	ld	s2,0(sp)
    80002b0e:	6105                	addi	sp,sp,32
    80002b10:	8082                	ret
    return -1;
    80002b12:	557d                	li	a0,-1
    80002b14:	bfcd                	j	80002b06 <fetchaddr+0x3e>
    80002b16:	557d                	li	a0,-1
    80002b18:	b7fd                	j	80002b06 <fetchaddr+0x3e>

0000000080002b1a <fetchstr>:
{
    80002b1a:	7179                	addi	sp,sp,-48
    80002b1c:	f406                	sd	ra,40(sp)
    80002b1e:	f022                	sd	s0,32(sp)
    80002b20:	ec26                	sd	s1,24(sp)
    80002b22:	e84a                	sd	s2,16(sp)
    80002b24:	e44e                	sd	s3,8(sp)
    80002b26:	1800                	addi	s0,sp,48
    80002b28:	892a                	mv	s2,a0
    80002b2a:	84ae                	mv	s1,a1
    80002b2c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	ec0080e7          	jalr	-320(ra) # 800019ee <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b36:	86ce                	mv	a3,s3
    80002b38:	864a                	mv	a2,s2
    80002b3a:	85a6                	mv	a1,s1
    80002b3c:	6928                	ld	a0,80(a0)
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	cbc080e7          	jalr	-836(ra) # 800017fa <copyinstr>
  if(err < 0)
    80002b46:	00054763          	bltz	a0,80002b54 <fetchstr+0x3a>
  return strlen(buf);
    80002b4a:	8526                	mv	a0,s1
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	356080e7          	jalr	854(ra) # 80000ea2 <strlen>
}
    80002b54:	70a2                	ld	ra,40(sp)
    80002b56:	7402                	ld	s0,32(sp)
    80002b58:	64e2                	ld	s1,24(sp)
    80002b5a:	6942                	ld	s2,16(sp)
    80002b5c:	69a2                	ld	s3,8(sp)
    80002b5e:	6145                	addi	sp,sp,48
    80002b60:	8082                	ret

0000000080002b62 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b62:	1101                	addi	sp,sp,-32
    80002b64:	ec06                	sd	ra,24(sp)
    80002b66:	e822                	sd	s0,16(sp)
    80002b68:	e426                	sd	s1,8(sp)
    80002b6a:	1000                	addi	s0,sp,32
    80002b6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b6e:	00000097          	auipc	ra,0x0
    80002b72:	ef2080e7          	jalr	-270(ra) # 80002a60 <argraw>
    80002b76:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b78:	4501                	li	a0,0
    80002b7a:	60e2                	ld	ra,24(sp)
    80002b7c:	6442                	ld	s0,16(sp)
    80002b7e:	64a2                	ld	s1,8(sp)
    80002b80:	6105                	addi	sp,sp,32
    80002b82:	8082                	ret

0000000080002b84 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b84:	1101                	addi	sp,sp,-32
    80002b86:	ec06                	sd	ra,24(sp)
    80002b88:	e822                	sd	s0,16(sp)
    80002b8a:	e426                	sd	s1,8(sp)
    80002b8c:	1000                	addi	s0,sp,32
    80002b8e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b90:	00000097          	auipc	ra,0x0
    80002b94:	ed0080e7          	jalr	-304(ra) # 80002a60 <argraw>
    80002b98:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b9a:	4501                	li	a0,0
    80002b9c:	60e2                	ld	ra,24(sp)
    80002b9e:	6442                	ld	s0,16(sp)
    80002ba0:	64a2                	ld	s1,8(sp)
    80002ba2:	6105                	addi	sp,sp,32
    80002ba4:	8082                	ret

0000000080002ba6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ba6:	1101                	addi	sp,sp,-32
    80002ba8:	ec06                	sd	ra,24(sp)
    80002baa:	e822                	sd	s0,16(sp)
    80002bac:	e426                	sd	s1,8(sp)
    80002bae:	e04a                	sd	s2,0(sp)
    80002bb0:	1000                	addi	s0,sp,32
    80002bb2:	84ae                	mv	s1,a1
    80002bb4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bb6:	00000097          	auipc	ra,0x0
    80002bba:	eaa080e7          	jalr	-342(ra) # 80002a60 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bbe:	864a                	mv	a2,s2
    80002bc0:	85a6                	mv	a1,s1
    80002bc2:	00000097          	auipc	ra,0x0
    80002bc6:	f58080e7          	jalr	-168(ra) # 80002b1a <fetchstr>
}
    80002bca:	60e2                	ld	ra,24(sp)
    80002bcc:	6442                	ld	s0,16(sp)
    80002bce:	64a2                	ld	s1,8(sp)
    80002bd0:	6902                	ld	s2,0(sp)
    80002bd2:	6105                	addi	sp,sp,32
    80002bd4:	8082                	ret

0000000080002bd6 <syscall>:
};
char * syscalls_name[24] = {"","fork","exit","wait","pipe","read","kill","exec","fstate","chdir","dup","getpid","sbrk","sleep","uptime","open","write","mknod","unlink","link","mkdir","close","trace"};

void
syscall(void)
{
    80002bd6:	7179                	addi	sp,sp,-48
    80002bd8:	f406                	sd	ra,40(sp)
    80002bda:	f022                	sd	s0,32(sp)
    80002bdc:	ec26                	sd	s1,24(sp)
    80002bde:	e84a                	sd	s2,16(sp)
    80002be0:	e44e                	sd	s3,8(sp)
    80002be2:	e052                	sd	s4,0(sp)
    80002be4:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	e08080e7          	jalr	-504(ra) # 800019ee <myproc>
    80002bee:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bf0:	05853903          	ld	s2,88(a0)
    80002bf4:	0a893783          	ld	a5,168(s2)
    80002bf8:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bfc:	37fd                	addiw	a5,a5,-1
    80002bfe:	4759                	li	a4,22
    80002c00:	04f76c63          	bltu	a4,a5,80002c58 <syscall+0x82>
    80002c04:	00399713          	slli	a4,s3,0x3
    80002c08:	00006797          	auipc	a5,0x6
    80002c0c:	94078793          	addi	a5,a5,-1728 # 80008548 <syscalls>
    80002c10:	97ba                	add	a5,a5,a4
    80002c12:	639c                	ld	a5,0(a5)
    80002c14:	c3b1                	beqz	a5,80002c58 <syscall+0x82>
    int test = p -> trapframe ->a0;
    80002c16:	07093a03          	ld	s4,112(s2)
    p->trapframe->a0 = syscalls[num]();
    80002c1a:	9782                	jalr	a5
    80002c1c:	06a93823          	sd	a0,112(s2)
    // add
    if( p->tracemask &(1<<num)){
    80002c20:	1684a783          	lw	a5,360(s1)
    80002c24:	4137d7bb          	sraw	a5,a5,s3
    80002c28:	8b85                	andi	a5,a5,1
    80002c2a:	c7b1                	beqz	a5,80002c76 <syscall+0xa0>
      printf("%d: sys_%s(%d) -> %d\n",p->pid,syscalls_name[num],test,p->trapframe->a0);
    80002c2c:	6cb8                	ld	a4,88(s1)
    80002c2e:	098e                	slli	s3,s3,0x3
    80002c30:	00006797          	auipc	a5,0x6
    80002c34:	d5878793          	addi	a5,a5,-680 # 80008988 <syscalls_name>
    80002c38:	99be                	add	s3,s3,a5
    80002c3a:	7b38                	ld	a4,112(a4)
    80002c3c:	000a069b          	sext.w	a3,s4
    80002c40:	0009b603          	ld	a2,0(s3)
    80002c44:	5c8c                	lw	a1,56(s1)
    80002c46:	00006517          	auipc	a0,0x6
    80002c4a:	80a50513          	addi	a0,a0,-2038 # 80008450 <states.0+0x148>
    80002c4e:	ffffe097          	auipc	ra,0xffffe
    80002c52:	93e080e7          	jalr	-1730(ra) # 8000058c <printf>
    80002c56:	a005                	j	80002c76 <syscall+0xa0>
      // printf("%d,%d,%d\n",p->pid,num,test);
    }
    // add
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c58:	86ce                	mv	a3,s3
    80002c5a:	15848613          	addi	a2,s1,344
    80002c5e:	5c8c                	lw	a1,56(s1)
    80002c60:	00006517          	auipc	a0,0x6
    80002c64:	80850513          	addi	a0,a0,-2040 # 80008468 <states.0+0x160>
    80002c68:	ffffe097          	auipc	ra,0xffffe
    80002c6c:	924080e7          	jalr	-1756(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c70:	6cbc                	ld	a5,88(s1)
    80002c72:	577d                	li	a4,-1
    80002c74:	fbb8                	sd	a4,112(a5)
  }
}
    80002c76:	70a2                	ld	ra,40(sp)
    80002c78:	7402                	ld	s0,32(sp)
    80002c7a:	64e2                	ld	s1,24(sp)
    80002c7c:	6942                	ld	s2,16(sp)
    80002c7e:	69a2                	ld	s3,8(sp)
    80002c80:	6a02                	ld	s4,0(sp)
    80002c82:	6145                	addi	sp,sp,48
    80002c84:	8082                	ret

0000000080002c86 <sys_exit>:
// add
#include "sysinfo.h"

uint64
sys_exit(void)
{
    80002c86:	1101                	addi	sp,sp,-32
    80002c88:	ec06                	sd	ra,24(sp)
    80002c8a:	e822                	sd	s0,16(sp)
    80002c8c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c8e:	fec40593          	addi	a1,s0,-20
    80002c92:	4501                	li	a0,0
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	ece080e7          	jalr	-306(ra) # 80002b62 <argint>
    return -1;
    80002c9c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c9e:	00054963          	bltz	a0,80002cb0 <sys_exit+0x2a>
  exit(n);
    80002ca2:	fec42503          	lw	a0,-20(s0)
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	41a080e7          	jalr	1050(ra) # 800020c0 <exit>
  return 0;  // not reached
    80002cae:	4781                	li	a5,0
}
    80002cb0:	853e                	mv	a0,a5
    80002cb2:	60e2                	ld	ra,24(sp)
    80002cb4:	6442                	ld	s0,16(sp)
    80002cb6:	6105                	addi	sp,sp,32
    80002cb8:	8082                	ret

0000000080002cba <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cba:	1141                	addi	sp,sp,-16
    80002cbc:	e406                	sd	ra,8(sp)
    80002cbe:	e022                	sd	s0,0(sp)
    80002cc0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	d2c080e7          	jalr	-724(ra) # 800019ee <myproc>
}
    80002cca:	5d08                	lw	a0,56(a0)
    80002ccc:	60a2                	ld	ra,8(sp)
    80002cce:	6402                	ld	s0,0(sp)
    80002cd0:	0141                	addi	sp,sp,16
    80002cd2:	8082                	ret

0000000080002cd4 <sys_fork>:

uint64
sys_fork(void)
{
    80002cd4:	1141                	addi	sp,sp,-16
    80002cd6:	e406                	sd	ra,8(sp)
    80002cd8:	e022                	sd	s0,0(sp)
    80002cda:	0800                	addi	s0,sp,16
  return fork();
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	0d2080e7          	jalr	210(ra) # 80001dae <fork>
}
    80002ce4:	60a2                	ld	ra,8(sp)
    80002ce6:	6402                	ld	s0,0(sp)
    80002ce8:	0141                	addi	sp,sp,16
    80002cea:	8082                	ret

0000000080002cec <sys_wait>:

uint64
sys_wait(void)
{
    80002cec:	1101                	addi	sp,sp,-32
    80002cee:	ec06                	sd	ra,24(sp)
    80002cf0:	e822                	sd	s0,16(sp)
    80002cf2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cf4:	fe840593          	addi	a1,s0,-24
    80002cf8:	4501                	li	a0,0
    80002cfa:	00000097          	auipc	ra,0x0
    80002cfe:	e8a080e7          	jalr	-374(ra) # 80002b84 <argaddr>
    80002d02:	87aa                	mv	a5,a0
    return -1;
    80002d04:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d06:	0007c863          	bltz	a5,80002d16 <sys_wait+0x2a>
  return wait(p);
    80002d0a:	fe843503          	ld	a0,-24(s0)
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	576080e7          	jalr	1398(ra) # 80002284 <wait>
}
    80002d16:	60e2                	ld	ra,24(sp)
    80002d18:	6442                	ld	s0,16(sp)
    80002d1a:	6105                	addi	sp,sp,32
    80002d1c:	8082                	ret

0000000080002d1e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d1e:	7179                	addi	sp,sp,-48
    80002d20:	f406                	sd	ra,40(sp)
    80002d22:	f022                	sd	s0,32(sp)
    80002d24:	ec26                	sd	s1,24(sp)
    80002d26:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d28:	fdc40593          	addi	a1,s0,-36
    80002d2c:	4501                	li	a0,0
    80002d2e:	00000097          	auipc	ra,0x0
    80002d32:	e34080e7          	jalr	-460(ra) # 80002b62 <argint>
    return -1;
    80002d36:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002d38:	00054f63          	bltz	a0,80002d56 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	cb2080e7          	jalr	-846(ra) # 800019ee <myproc>
    80002d44:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d46:	fdc42503          	lw	a0,-36(s0)
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	ff0080e7          	jalr	-16(ra) # 80001d3a <growproc>
    80002d52:	00054863          	bltz	a0,80002d62 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002d56:	8526                	mv	a0,s1
    80002d58:	70a2                	ld	ra,40(sp)
    80002d5a:	7402                	ld	s0,32(sp)
    80002d5c:	64e2                	ld	s1,24(sp)
    80002d5e:	6145                	addi	sp,sp,48
    80002d60:	8082                	ret
    return -1;
    80002d62:	54fd                	li	s1,-1
    80002d64:	bfcd                	j	80002d56 <sys_sbrk+0x38>

0000000080002d66 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d66:	7139                	addi	sp,sp,-64
    80002d68:	fc06                	sd	ra,56(sp)
    80002d6a:	f822                	sd	s0,48(sp)
    80002d6c:	f426                	sd	s1,40(sp)
    80002d6e:	f04a                	sd	s2,32(sp)
    80002d70:	ec4e                	sd	s3,24(sp)
    80002d72:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d74:	fcc40593          	addi	a1,s0,-52
    80002d78:	4501                	li	a0,0
    80002d7a:	00000097          	auipc	ra,0x0
    80002d7e:	de8080e7          	jalr	-536(ra) # 80002b62 <argint>
    return -1;
    80002d82:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d84:	06054563          	bltz	a0,80002dee <sys_sleep+0x88>
  acquire(&tickslock);
    80002d88:	00015517          	auipc	a0,0x15
    80002d8c:	be050513          	addi	a0,a0,-1056 # 80017968 <tickslock>
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	e92080e7          	jalr	-366(ra) # 80000c22 <acquire>
  ticks0 = ticks;
    80002d98:	00006917          	auipc	s2,0x6
    80002d9c:	28892903          	lw	s2,648(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002da0:	fcc42783          	lw	a5,-52(s0)
    80002da4:	cf85                	beqz	a5,80002ddc <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002da6:	00015997          	auipc	s3,0x15
    80002daa:	bc298993          	addi	s3,s3,-1086 # 80017968 <tickslock>
    80002dae:	00006497          	auipc	s1,0x6
    80002db2:	27248493          	addi	s1,s1,626 # 80009020 <ticks>
    if(myproc()->killed){
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	c38080e7          	jalr	-968(ra) # 800019ee <myproc>
    80002dbe:	591c                	lw	a5,48(a0)
    80002dc0:	ef9d                	bnez	a5,80002dfe <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002dc2:	85ce                	mv	a1,s3
    80002dc4:	8526                	mv	a0,s1
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	440080e7          	jalr	1088(ra) # 80002206 <sleep>
  while(ticks - ticks0 < n){
    80002dce:	409c                	lw	a5,0(s1)
    80002dd0:	412787bb          	subw	a5,a5,s2
    80002dd4:	fcc42703          	lw	a4,-52(s0)
    80002dd8:	fce7efe3          	bltu	a5,a4,80002db6 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ddc:	00015517          	auipc	a0,0x15
    80002de0:	b8c50513          	addi	a0,a0,-1140 # 80017968 <tickslock>
    80002de4:	ffffe097          	auipc	ra,0xffffe
    80002de8:	ef2080e7          	jalr	-270(ra) # 80000cd6 <release>
  return 0;
    80002dec:	4781                	li	a5,0
}
    80002dee:	853e                	mv	a0,a5
    80002df0:	70e2                	ld	ra,56(sp)
    80002df2:	7442                	ld	s0,48(sp)
    80002df4:	74a2                	ld	s1,40(sp)
    80002df6:	7902                	ld	s2,32(sp)
    80002df8:	69e2                	ld	s3,24(sp)
    80002dfa:	6121                	addi	sp,sp,64
    80002dfc:	8082                	ret
      release(&tickslock);
    80002dfe:	00015517          	auipc	a0,0x15
    80002e02:	b6a50513          	addi	a0,a0,-1174 # 80017968 <tickslock>
    80002e06:	ffffe097          	auipc	ra,0xffffe
    80002e0a:	ed0080e7          	jalr	-304(ra) # 80000cd6 <release>
      return -1;
    80002e0e:	57fd                	li	a5,-1
    80002e10:	bff9                	j	80002dee <sys_sleep+0x88>

0000000080002e12 <sys_kill>:

uint64
sys_kill(void)
{
    80002e12:	1101                	addi	sp,sp,-32
    80002e14:	ec06                	sd	ra,24(sp)
    80002e16:	e822                	sd	s0,16(sp)
    80002e18:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e1a:	fec40593          	addi	a1,s0,-20
    80002e1e:	4501                	li	a0,0
    80002e20:	00000097          	auipc	ra,0x0
    80002e24:	d42080e7          	jalr	-702(ra) # 80002b62 <argint>
    80002e28:	87aa                	mv	a5,a0
    return -1;
    80002e2a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e2c:	0007c863          	bltz	a5,80002e3c <sys_kill+0x2a>
  return kill(pid);
    80002e30:	fec42503          	lw	a0,-20(s0)
    80002e34:	fffff097          	auipc	ra,0xfffff
    80002e38:	5bc080e7          	jalr	1468(ra) # 800023f0 <kill>
}
    80002e3c:	60e2                	ld	ra,24(sp)
    80002e3e:	6442                	ld	s0,16(sp)
    80002e40:	6105                	addi	sp,sp,32
    80002e42:	8082                	ret

0000000080002e44 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e44:	1101                	addi	sp,sp,-32
    80002e46:	ec06                	sd	ra,24(sp)
    80002e48:	e822                	sd	s0,16(sp)
    80002e4a:	e426                	sd	s1,8(sp)
    80002e4c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e4e:	00015517          	auipc	a0,0x15
    80002e52:	b1a50513          	addi	a0,a0,-1254 # 80017968 <tickslock>
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	dcc080e7          	jalr	-564(ra) # 80000c22 <acquire>
  xticks = ticks;
    80002e5e:	00006497          	auipc	s1,0x6
    80002e62:	1c24a483          	lw	s1,450(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e66:	00015517          	auipc	a0,0x15
    80002e6a:	b0250513          	addi	a0,a0,-1278 # 80017968 <tickslock>
    80002e6e:	ffffe097          	auipc	ra,0xffffe
    80002e72:	e68080e7          	jalr	-408(ra) # 80000cd6 <release>
  return xticks;
}
    80002e76:	02049513          	slli	a0,s1,0x20
    80002e7a:	9101                	srli	a0,a0,0x20
    80002e7c:	60e2                	ld	ra,24(sp)
    80002e7e:	6442                	ld	s0,16(sp)
    80002e80:	64a2                	ld	s1,8(sp)
    80002e82:	6105                	addi	sp,sp,32
    80002e84:	8082                	ret

0000000080002e86 <sys_trace>:

// add
uint64
sys_trace(void)
{
    80002e86:	1101                	addi	sp,sp,-32
    80002e88:	ec06                	sd	ra,24(sp)
    80002e8a:	e822                	sd	s0,16(sp)
    80002e8c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0,&n)<0){
    80002e8e:	fec40593          	addi	a1,s0,-20
    80002e92:	4501                	li	a0,0
    80002e94:	00000097          	auipc	ra,0x0
    80002e98:	cce080e7          	jalr	-818(ra) # 80002b62 <argint>
    return -1;
    80002e9c:	57fd                	li	a5,-1
  if(argint(0,&n)<0){
    80002e9e:	00054b63          	bltz	a0,80002eb4 <sys_trace+0x2e>
  }
  myproc() -> tracemask = n;
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	b4c080e7          	jalr	-1204(ra) # 800019ee <myproc>
    80002eaa:	fec42783          	lw	a5,-20(s0)
    80002eae:	16f52423          	sw	a5,360(a0)
  return 0;
    80002eb2:	4781                	li	a5,0
}
    80002eb4:	853e                	mv	a0,a5
    80002eb6:	60e2                	ld	ra,24(sp)
    80002eb8:	6442                	ld	s0,16(sp)
    80002eba:	6105                	addi	sp,sp,32
    80002ebc:	8082                	ret

0000000080002ebe <sys_sysinfo>:

// add


uint64
sys_sysinfo(void){
    80002ebe:	7139                	addi	sp,sp,-64
    80002ec0:	fc06                	sd	ra,56(sp)
    80002ec2:	f822                	sd	s0,48(sp)
    80002ec4:	f426                	sd	s1,40(sp)
    80002ec6:	0080                	addi	s0,sp,64
  struct sysinfo info;
  struct sysinfo *addr;
  if(argaddr(0,(uint64*)&addr)<0){
    80002ec8:	fc040593          	addi	a1,s0,-64
    80002ecc:	4501                	li	a0,0
    80002ece:	00000097          	auipc	ra,0x0
    80002ed2:	cb6080e7          	jalr	-842(ra) # 80002b84 <argaddr>
    80002ed6:	87aa                	mv	a5,a0
    return -1;
    80002ed8:	557d                	li	a0,-1
  if(argaddr(0,(uint64*)&addr)<0){
    80002eda:	0407c463          	bltz	a5,80002f22 <sys_sysinfo+0x64>
  }
  struct proc* p = myproc();
    80002ede:	fffff097          	auipc	ra,0xfffff
    80002ee2:	b10080e7          	jalr	-1264(ra) # 800019ee <myproc>
    80002ee6:	84aa                	mv	s1,a0

  info.freemem = freememory();
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	c86080e7          	jalr	-890(ra) # 80000b6e <freememory>
    80002ef0:	fca43423          	sd	a0,-56(s0)

  info.nproc = proc_size();
    80002ef4:	fffff097          	auipc	ra,0xfffff
    80002ef8:	6c6080e7          	jalr	1734(ra) # 800025ba <proc_size>
    80002efc:	fca43823          	sd	a0,-48(s0)

  info.freefd = freefd(info.nproc);
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	6ea080e7          	jalr	1770(ra) # 800025ea <freefd>
    80002f08:	fca43c23          	sd	a0,-40(s0)

  if(copyout(p->pagetable,(uint64)addr,(char*)&info,sizeof(info))<0){
    80002f0c:	46e1                	li	a3,24
    80002f0e:	fc840613          	addi	a2,s0,-56
    80002f12:	fc043583          	ld	a1,-64(s0)
    80002f16:	68a8                	ld	a0,80(s1)
    80002f18:	ffffe097          	auipc	ra,0xffffe
    80002f1c:	7c8080e7          	jalr	1992(ra) # 800016e0 <copyout>
    80002f20:	957d                	srai	a0,a0,0x3f
    return -1;
  }
  return 0;
  
    80002f22:	70e2                	ld	ra,56(sp)
    80002f24:	7442                	ld	s0,48(sp)
    80002f26:	74a2                	ld	s1,40(sp)
    80002f28:	6121                	addi	sp,sp,64
    80002f2a:	8082                	ret

0000000080002f2c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f2c:	7179                	addi	sp,sp,-48
    80002f2e:	f406                	sd	ra,40(sp)
    80002f30:	f022                	sd	s0,32(sp)
    80002f32:	ec26                	sd	s1,24(sp)
    80002f34:	e84a                	sd	s2,16(sp)
    80002f36:	e44e                	sd	s3,8(sp)
    80002f38:	e052                	sd	s4,0(sp)
    80002f3a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f3c:	00005597          	auipc	a1,0x5
    80002f40:	6cc58593          	addi	a1,a1,1740 # 80008608 <syscalls+0xc0>
    80002f44:	00015517          	auipc	a0,0x15
    80002f48:	a3c50513          	addi	a0,a0,-1476 # 80017980 <bcache>
    80002f4c:	ffffe097          	auipc	ra,0xffffe
    80002f50:	c46080e7          	jalr	-954(ra) # 80000b92 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f54:	0001d797          	auipc	a5,0x1d
    80002f58:	a2c78793          	addi	a5,a5,-1492 # 8001f980 <bcache+0x8000>
    80002f5c:	0001d717          	auipc	a4,0x1d
    80002f60:	c8c70713          	addi	a4,a4,-884 # 8001fbe8 <bcache+0x8268>
    80002f64:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f68:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f6c:	00015497          	auipc	s1,0x15
    80002f70:	a2c48493          	addi	s1,s1,-1492 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002f74:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f76:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f78:	00005a17          	auipc	s4,0x5
    80002f7c:	698a0a13          	addi	s4,s4,1688 # 80008610 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f80:	2b893783          	ld	a5,696(s2)
    80002f84:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f86:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f8a:	85d2                	mv	a1,s4
    80002f8c:	01048513          	addi	a0,s1,16
    80002f90:	00001097          	auipc	ra,0x1
    80002f94:	4ac080e7          	jalr	1196(ra) # 8000443c <initsleeplock>
    bcache.head.next->prev = b;
    80002f98:	2b893783          	ld	a5,696(s2)
    80002f9c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f9e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fa2:	45848493          	addi	s1,s1,1112
    80002fa6:	fd349de3          	bne	s1,s3,80002f80 <binit+0x54>
  }
}
    80002faa:	70a2                	ld	ra,40(sp)
    80002fac:	7402                	ld	s0,32(sp)
    80002fae:	64e2                	ld	s1,24(sp)
    80002fb0:	6942                	ld	s2,16(sp)
    80002fb2:	69a2                	ld	s3,8(sp)
    80002fb4:	6a02                	ld	s4,0(sp)
    80002fb6:	6145                	addi	sp,sp,48
    80002fb8:	8082                	ret

0000000080002fba <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fba:	7179                	addi	sp,sp,-48
    80002fbc:	f406                	sd	ra,40(sp)
    80002fbe:	f022                	sd	s0,32(sp)
    80002fc0:	ec26                	sd	s1,24(sp)
    80002fc2:	e84a                	sd	s2,16(sp)
    80002fc4:	e44e                	sd	s3,8(sp)
    80002fc6:	1800                	addi	s0,sp,48
    80002fc8:	892a                	mv	s2,a0
    80002fca:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002fcc:	00015517          	auipc	a0,0x15
    80002fd0:	9b450513          	addi	a0,a0,-1612 # 80017980 <bcache>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	c4e080e7          	jalr	-946(ra) # 80000c22 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fdc:	0001d497          	auipc	s1,0x1d
    80002fe0:	c5c4b483          	ld	s1,-932(s1) # 8001fc38 <bcache+0x82b8>
    80002fe4:	0001d797          	auipc	a5,0x1d
    80002fe8:	c0478793          	addi	a5,a5,-1020 # 8001fbe8 <bcache+0x8268>
    80002fec:	02f48f63          	beq	s1,a5,8000302a <bread+0x70>
    80002ff0:	873e                	mv	a4,a5
    80002ff2:	a021                	j	80002ffa <bread+0x40>
    80002ff4:	68a4                	ld	s1,80(s1)
    80002ff6:	02e48a63          	beq	s1,a4,8000302a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ffa:	449c                	lw	a5,8(s1)
    80002ffc:	ff279ce3          	bne	a5,s2,80002ff4 <bread+0x3a>
    80003000:	44dc                	lw	a5,12(s1)
    80003002:	ff3799e3          	bne	a5,s3,80002ff4 <bread+0x3a>
      b->refcnt++;
    80003006:	40bc                	lw	a5,64(s1)
    80003008:	2785                	addiw	a5,a5,1
    8000300a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000300c:	00015517          	auipc	a0,0x15
    80003010:	97450513          	addi	a0,a0,-1676 # 80017980 <bcache>
    80003014:	ffffe097          	auipc	ra,0xffffe
    80003018:	cc2080e7          	jalr	-830(ra) # 80000cd6 <release>
      acquiresleep(&b->lock);
    8000301c:	01048513          	addi	a0,s1,16
    80003020:	00001097          	auipc	ra,0x1
    80003024:	456080e7          	jalr	1110(ra) # 80004476 <acquiresleep>
      return b;
    80003028:	a8b9                	j	80003086 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000302a:	0001d497          	auipc	s1,0x1d
    8000302e:	c064b483          	ld	s1,-1018(s1) # 8001fc30 <bcache+0x82b0>
    80003032:	0001d797          	auipc	a5,0x1d
    80003036:	bb678793          	addi	a5,a5,-1098 # 8001fbe8 <bcache+0x8268>
    8000303a:	00f48863          	beq	s1,a5,8000304a <bread+0x90>
    8000303e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003040:	40bc                	lw	a5,64(s1)
    80003042:	cf81                	beqz	a5,8000305a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003044:	64a4                	ld	s1,72(s1)
    80003046:	fee49de3          	bne	s1,a4,80003040 <bread+0x86>
  panic("bget: no buffers");
    8000304a:	00005517          	auipc	a0,0x5
    8000304e:	5ce50513          	addi	a0,a0,1486 # 80008618 <syscalls+0xd0>
    80003052:	ffffd097          	auipc	ra,0xffffd
    80003056:	4f0080e7          	jalr	1264(ra) # 80000542 <panic>
      b->dev = dev;
    8000305a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000305e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003062:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003066:	4785                	li	a5,1
    80003068:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000306a:	00015517          	auipc	a0,0x15
    8000306e:	91650513          	addi	a0,a0,-1770 # 80017980 <bcache>
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	c64080e7          	jalr	-924(ra) # 80000cd6 <release>
      acquiresleep(&b->lock);
    8000307a:	01048513          	addi	a0,s1,16
    8000307e:	00001097          	auipc	ra,0x1
    80003082:	3f8080e7          	jalr	1016(ra) # 80004476 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003086:	409c                	lw	a5,0(s1)
    80003088:	cb89                	beqz	a5,8000309a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000308a:	8526                	mv	a0,s1
    8000308c:	70a2                	ld	ra,40(sp)
    8000308e:	7402                	ld	s0,32(sp)
    80003090:	64e2                	ld	s1,24(sp)
    80003092:	6942                	ld	s2,16(sp)
    80003094:	69a2                	ld	s3,8(sp)
    80003096:	6145                	addi	sp,sp,48
    80003098:	8082                	ret
    virtio_disk_rw(b, 0);
    8000309a:	4581                	li	a1,0
    8000309c:	8526                	mv	a0,s1
    8000309e:	00003097          	auipc	ra,0x3
    800030a2:	f1e080e7          	jalr	-226(ra) # 80005fbc <virtio_disk_rw>
    b->valid = 1;
    800030a6:	4785                	li	a5,1
    800030a8:	c09c                	sw	a5,0(s1)
  return b;
    800030aa:	b7c5                	j	8000308a <bread+0xd0>

00000000800030ac <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030ac:	1101                	addi	sp,sp,-32
    800030ae:	ec06                	sd	ra,24(sp)
    800030b0:	e822                	sd	s0,16(sp)
    800030b2:	e426                	sd	s1,8(sp)
    800030b4:	1000                	addi	s0,sp,32
    800030b6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b8:	0541                	addi	a0,a0,16
    800030ba:	00001097          	auipc	ra,0x1
    800030be:	456080e7          	jalr	1110(ra) # 80004510 <holdingsleep>
    800030c2:	cd01                	beqz	a0,800030da <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030c4:	4585                	li	a1,1
    800030c6:	8526                	mv	a0,s1
    800030c8:	00003097          	auipc	ra,0x3
    800030cc:	ef4080e7          	jalr	-268(ra) # 80005fbc <virtio_disk_rw>
}
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret
    panic("bwrite");
    800030da:	00005517          	auipc	a0,0x5
    800030de:	55650513          	addi	a0,a0,1366 # 80008630 <syscalls+0xe8>
    800030e2:	ffffd097          	auipc	ra,0xffffd
    800030e6:	460080e7          	jalr	1120(ra) # 80000542 <panic>

00000000800030ea <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030ea:	1101                	addi	sp,sp,-32
    800030ec:	ec06                	sd	ra,24(sp)
    800030ee:	e822                	sd	s0,16(sp)
    800030f0:	e426                	sd	s1,8(sp)
    800030f2:	e04a                	sd	s2,0(sp)
    800030f4:	1000                	addi	s0,sp,32
    800030f6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030f8:	01050913          	addi	s2,a0,16
    800030fc:	854a                	mv	a0,s2
    800030fe:	00001097          	auipc	ra,0x1
    80003102:	412080e7          	jalr	1042(ra) # 80004510 <holdingsleep>
    80003106:	c92d                	beqz	a0,80003178 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003108:	854a                	mv	a0,s2
    8000310a:	00001097          	auipc	ra,0x1
    8000310e:	3c2080e7          	jalr	962(ra) # 800044cc <releasesleep>

  acquire(&bcache.lock);
    80003112:	00015517          	auipc	a0,0x15
    80003116:	86e50513          	addi	a0,a0,-1938 # 80017980 <bcache>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	b08080e7          	jalr	-1272(ra) # 80000c22 <acquire>
  b->refcnt--;
    80003122:	40bc                	lw	a5,64(s1)
    80003124:	37fd                	addiw	a5,a5,-1
    80003126:	0007871b          	sext.w	a4,a5
    8000312a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000312c:	eb05                	bnez	a4,8000315c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000312e:	68bc                	ld	a5,80(s1)
    80003130:	64b8                	ld	a4,72(s1)
    80003132:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003134:	64bc                	ld	a5,72(s1)
    80003136:	68b8                	ld	a4,80(s1)
    80003138:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000313a:	0001d797          	auipc	a5,0x1d
    8000313e:	84678793          	addi	a5,a5,-1978 # 8001f980 <bcache+0x8000>
    80003142:	2b87b703          	ld	a4,696(a5)
    80003146:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003148:	0001d717          	auipc	a4,0x1d
    8000314c:	aa070713          	addi	a4,a4,-1376 # 8001fbe8 <bcache+0x8268>
    80003150:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003152:	2b87b703          	ld	a4,696(a5)
    80003156:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003158:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000315c:	00015517          	auipc	a0,0x15
    80003160:	82450513          	addi	a0,a0,-2012 # 80017980 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	b72080e7          	jalr	-1166(ra) # 80000cd6 <release>
}
    8000316c:	60e2                	ld	ra,24(sp)
    8000316e:	6442                	ld	s0,16(sp)
    80003170:	64a2                	ld	s1,8(sp)
    80003172:	6902                	ld	s2,0(sp)
    80003174:	6105                	addi	sp,sp,32
    80003176:	8082                	ret
    panic("brelse");
    80003178:	00005517          	auipc	a0,0x5
    8000317c:	4c050513          	addi	a0,a0,1216 # 80008638 <syscalls+0xf0>
    80003180:	ffffd097          	auipc	ra,0xffffd
    80003184:	3c2080e7          	jalr	962(ra) # 80000542 <panic>

0000000080003188 <bpin>:

void
bpin(struct buf *b) {
    80003188:	1101                	addi	sp,sp,-32
    8000318a:	ec06                	sd	ra,24(sp)
    8000318c:	e822                	sd	s0,16(sp)
    8000318e:	e426                	sd	s1,8(sp)
    80003190:	1000                	addi	s0,sp,32
    80003192:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003194:	00014517          	auipc	a0,0x14
    80003198:	7ec50513          	addi	a0,a0,2028 # 80017980 <bcache>
    8000319c:	ffffe097          	auipc	ra,0xffffe
    800031a0:	a86080e7          	jalr	-1402(ra) # 80000c22 <acquire>
  b->refcnt++;
    800031a4:	40bc                	lw	a5,64(s1)
    800031a6:	2785                	addiw	a5,a5,1
    800031a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031aa:	00014517          	auipc	a0,0x14
    800031ae:	7d650513          	addi	a0,a0,2006 # 80017980 <bcache>
    800031b2:	ffffe097          	auipc	ra,0xffffe
    800031b6:	b24080e7          	jalr	-1244(ra) # 80000cd6 <release>
}
    800031ba:	60e2                	ld	ra,24(sp)
    800031bc:	6442                	ld	s0,16(sp)
    800031be:	64a2                	ld	s1,8(sp)
    800031c0:	6105                	addi	sp,sp,32
    800031c2:	8082                	ret

00000000800031c4 <bunpin>:

void
bunpin(struct buf *b) {
    800031c4:	1101                	addi	sp,sp,-32
    800031c6:	ec06                	sd	ra,24(sp)
    800031c8:	e822                	sd	s0,16(sp)
    800031ca:	e426                	sd	s1,8(sp)
    800031cc:	1000                	addi	s0,sp,32
    800031ce:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031d0:	00014517          	auipc	a0,0x14
    800031d4:	7b050513          	addi	a0,a0,1968 # 80017980 <bcache>
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	a4a080e7          	jalr	-1462(ra) # 80000c22 <acquire>
  b->refcnt--;
    800031e0:	40bc                	lw	a5,64(s1)
    800031e2:	37fd                	addiw	a5,a5,-1
    800031e4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031e6:	00014517          	auipc	a0,0x14
    800031ea:	79a50513          	addi	a0,a0,1946 # 80017980 <bcache>
    800031ee:	ffffe097          	auipc	ra,0xffffe
    800031f2:	ae8080e7          	jalr	-1304(ra) # 80000cd6 <release>
}
    800031f6:	60e2                	ld	ra,24(sp)
    800031f8:	6442                	ld	s0,16(sp)
    800031fa:	64a2                	ld	s1,8(sp)
    800031fc:	6105                	addi	sp,sp,32
    800031fe:	8082                	ret

0000000080003200 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003200:	1101                	addi	sp,sp,-32
    80003202:	ec06                	sd	ra,24(sp)
    80003204:	e822                	sd	s0,16(sp)
    80003206:	e426                	sd	s1,8(sp)
    80003208:	e04a                	sd	s2,0(sp)
    8000320a:	1000                	addi	s0,sp,32
    8000320c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000320e:	00d5d59b          	srliw	a1,a1,0xd
    80003212:	0001d797          	auipc	a5,0x1d
    80003216:	e4a7a783          	lw	a5,-438(a5) # 8002005c <sb+0x1c>
    8000321a:	9dbd                	addw	a1,a1,a5
    8000321c:	00000097          	auipc	ra,0x0
    80003220:	d9e080e7          	jalr	-610(ra) # 80002fba <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003224:	0074f713          	andi	a4,s1,7
    80003228:	4785                	li	a5,1
    8000322a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000322e:	14ce                	slli	s1,s1,0x33
    80003230:	90d9                	srli	s1,s1,0x36
    80003232:	00950733          	add	a4,a0,s1
    80003236:	05874703          	lbu	a4,88(a4)
    8000323a:	00e7f6b3          	and	a3,a5,a4
    8000323e:	c69d                	beqz	a3,8000326c <bfree+0x6c>
    80003240:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003242:	94aa                	add	s1,s1,a0
    80003244:	fff7c793          	not	a5,a5
    80003248:	8ff9                	and	a5,a5,a4
    8000324a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000324e:	00001097          	auipc	ra,0x1
    80003252:	100080e7          	jalr	256(ra) # 8000434e <log_write>
  brelse(bp);
    80003256:	854a                	mv	a0,s2
    80003258:	00000097          	auipc	ra,0x0
    8000325c:	e92080e7          	jalr	-366(ra) # 800030ea <brelse>
}
    80003260:	60e2                	ld	ra,24(sp)
    80003262:	6442                	ld	s0,16(sp)
    80003264:	64a2                	ld	s1,8(sp)
    80003266:	6902                	ld	s2,0(sp)
    80003268:	6105                	addi	sp,sp,32
    8000326a:	8082                	ret
    panic("freeing free block");
    8000326c:	00005517          	auipc	a0,0x5
    80003270:	3d450513          	addi	a0,a0,980 # 80008640 <syscalls+0xf8>
    80003274:	ffffd097          	auipc	ra,0xffffd
    80003278:	2ce080e7          	jalr	718(ra) # 80000542 <panic>

000000008000327c <balloc>:
{
    8000327c:	711d                	addi	sp,sp,-96
    8000327e:	ec86                	sd	ra,88(sp)
    80003280:	e8a2                	sd	s0,80(sp)
    80003282:	e4a6                	sd	s1,72(sp)
    80003284:	e0ca                	sd	s2,64(sp)
    80003286:	fc4e                	sd	s3,56(sp)
    80003288:	f852                	sd	s4,48(sp)
    8000328a:	f456                	sd	s5,40(sp)
    8000328c:	f05a                	sd	s6,32(sp)
    8000328e:	ec5e                	sd	s7,24(sp)
    80003290:	e862                	sd	s8,16(sp)
    80003292:	e466                	sd	s9,8(sp)
    80003294:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003296:	0001d797          	auipc	a5,0x1d
    8000329a:	dae7a783          	lw	a5,-594(a5) # 80020044 <sb+0x4>
    8000329e:	cbd1                	beqz	a5,80003332 <balloc+0xb6>
    800032a0:	8baa                	mv	s7,a0
    800032a2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032a4:	0001db17          	auipc	s6,0x1d
    800032a8:	d9cb0b13          	addi	s6,s6,-612 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ac:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032ae:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032b2:	6c89                	lui	s9,0x2
    800032b4:	a831                	j	800032d0 <balloc+0x54>
    brelse(bp);
    800032b6:	854a                	mv	a0,s2
    800032b8:	00000097          	auipc	ra,0x0
    800032bc:	e32080e7          	jalr	-462(ra) # 800030ea <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032c0:	015c87bb          	addw	a5,s9,s5
    800032c4:	00078a9b          	sext.w	s5,a5
    800032c8:	004b2703          	lw	a4,4(s6)
    800032cc:	06eaf363          	bgeu	s5,a4,80003332 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032d0:	41fad79b          	sraiw	a5,s5,0x1f
    800032d4:	0137d79b          	srliw	a5,a5,0x13
    800032d8:	015787bb          	addw	a5,a5,s5
    800032dc:	40d7d79b          	sraiw	a5,a5,0xd
    800032e0:	01cb2583          	lw	a1,28(s6)
    800032e4:	9dbd                	addw	a1,a1,a5
    800032e6:	855e                	mv	a0,s7
    800032e8:	00000097          	auipc	ra,0x0
    800032ec:	cd2080e7          	jalr	-814(ra) # 80002fba <bread>
    800032f0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f2:	004b2503          	lw	a0,4(s6)
    800032f6:	000a849b          	sext.w	s1,s5
    800032fa:	8662                	mv	a2,s8
    800032fc:	faa4fde3          	bgeu	s1,a0,800032b6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003300:	41f6579b          	sraiw	a5,a2,0x1f
    80003304:	01d7d69b          	srliw	a3,a5,0x1d
    80003308:	00c6873b          	addw	a4,a3,a2
    8000330c:	00777793          	andi	a5,a4,7
    80003310:	9f95                	subw	a5,a5,a3
    80003312:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003316:	4037571b          	sraiw	a4,a4,0x3
    8000331a:	00e906b3          	add	a3,s2,a4
    8000331e:	0586c683          	lbu	a3,88(a3)
    80003322:	00d7f5b3          	and	a1,a5,a3
    80003326:	cd91                	beqz	a1,80003342 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003328:	2605                	addiw	a2,a2,1
    8000332a:	2485                	addiw	s1,s1,1
    8000332c:	fd4618e3          	bne	a2,s4,800032fc <balloc+0x80>
    80003330:	b759                	j	800032b6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003332:	00005517          	auipc	a0,0x5
    80003336:	32650513          	addi	a0,a0,806 # 80008658 <syscalls+0x110>
    8000333a:	ffffd097          	auipc	ra,0xffffd
    8000333e:	208080e7          	jalr	520(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003342:	974a                	add	a4,a4,s2
    80003344:	8fd5                	or	a5,a5,a3
    80003346:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000334a:	854a                	mv	a0,s2
    8000334c:	00001097          	auipc	ra,0x1
    80003350:	002080e7          	jalr	2(ra) # 8000434e <log_write>
        brelse(bp);
    80003354:	854a                	mv	a0,s2
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	d94080e7          	jalr	-620(ra) # 800030ea <brelse>
  bp = bread(dev, bno);
    8000335e:	85a6                	mv	a1,s1
    80003360:	855e                	mv	a0,s7
    80003362:	00000097          	auipc	ra,0x0
    80003366:	c58080e7          	jalr	-936(ra) # 80002fba <bread>
    8000336a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000336c:	40000613          	li	a2,1024
    80003370:	4581                	li	a1,0
    80003372:	05850513          	addi	a0,a0,88
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	9a8080e7          	jalr	-1624(ra) # 80000d1e <memset>
  log_write(bp);
    8000337e:	854a                	mv	a0,s2
    80003380:	00001097          	auipc	ra,0x1
    80003384:	fce080e7          	jalr	-50(ra) # 8000434e <log_write>
  brelse(bp);
    80003388:	854a                	mv	a0,s2
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	d60080e7          	jalr	-672(ra) # 800030ea <brelse>
}
    80003392:	8526                	mv	a0,s1
    80003394:	60e6                	ld	ra,88(sp)
    80003396:	6446                	ld	s0,80(sp)
    80003398:	64a6                	ld	s1,72(sp)
    8000339a:	6906                	ld	s2,64(sp)
    8000339c:	79e2                	ld	s3,56(sp)
    8000339e:	7a42                	ld	s4,48(sp)
    800033a0:	7aa2                	ld	s5,40(sp)
    800033a2:	7b02                	ld	s6,32(sp)
    800033a4:	6be2                	ld	s7,24(sp)
    800033a6:	6c42                	ld	s8,16(sp)
    800033a8:	6ca2                	ld	s9,8(sp)
    800033aa:	6125                	addi	sp,sp,96
    800033ac:	8082                	ret

00000000800033ae <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033ae:	7179                	addi	sp,sp,-48
    800033b0:	f406                	sd	ra,40(sp)
    800033b2:	f022                	sd	s0,32(sp)
    800033b4:	ec26                	sd	s1,24(sp)
    800033b6:	e84a                	sd	s2,16(sp)
    800033b8:	e44e                	sd	s3,8(sp)
    800033ba:	e052                	sd	s4,0(sp)
    800033bc:	1800                	addi	s0,sp,48
    800033be:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033c0:	47ad                	li	a5,11
    800033c2:	04b7fe63          	bgeu	a5,a1,8000341e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033c6:	ff45849b          	addiw	s1,a1,-12
    800033ca:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033ce:	0ff00793          	li	a5,255
    800033d2:	0ae7e363          	bltu	a5,a4,80003478 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033d6:	08052583          	lw	a1,128(a0)
    800033da:	c5ad                	beqz	a1,80003444 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033dc:	00092503          	lw	a0,0(s2)
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	bda080e7          	jalr	-1062(ra) # 80002fba <bread>
    800033e8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033ea:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033ee:	02049593          	slli	a1,s1,0x20
    800033f2:	9181                	srli	a1,a1,0x20
    800033f4:	058a                	slli	a1,a1,0x2
    800033f6:	00b784b3          	add	s1,a5,a1
    800033fa:	0004a983          	lw	s3,0(s1)
    800033fe:	04098d63          	beqz	s3,80003458 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003402:	8552                	mv	a0,s4
    80003404:	00000097          	auipc	ra,0x0
    80003408:	ce6080e7          	jalr	-794(ra) # 800030ea <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000340c:	854e                	mv	a0,s3
    8000340e:	70a2                	ld	ra,40(sp)
    80003410:	7402                	ld	s0,32(sp)
    80003412:	64e2                	ld	s1,24(sp)
    80003414:	6942                	ld	s2,16(sp)
    80003416:	69a2                	ld	s3,8(sp)
    80003418:	6a02                	ld	s4,0(sp)
    8000341a:	6145                	addi	sp,sp,48
    8000341c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000341e:	02059493          	slli	s1,a1,0x20
    80003422:	9081                	srli	s1,s1,0x20
    80003424:	048a                	slli	s1,s1,0x2
    80003426:	94aa                	add	s1,s1,a0
    80003428:	0504a983          	lw	s3,80(s1)
    8000342c:	fe0990e3          	bnez	s3,8000340c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003430:	4108                	lw	a0,0(a0)
    80003432:	00000097          	auipc	ra,0x0
    80003436:	e4a080e7          	jalr	-438(ra) # 8000327c <balloc>
    8000343a:	0005099b          	sext.w	s3,a0
    8000343e:	0534a823          	sw	s3,80(s1)
    80003442:	b7e9                	j	8000340c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003444:	4108                	lw	a0,0(a0)
    80003446:	00000097          	auipc	ra,0x0
    8000344a:	e36080e7          	jalr	-458(ra) # 8000327c <balloc>
    8000344e:	0005059b          	sext.w	a1,a0
    80003452:	08b92023          	sw	a1,128(s2)
    80003456:	b759                	j	800033dc <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003458:	00092503          	lw	a0,0(s2)
    8000345c:	00000097          	auipc	ra,0x0
    80003460:	e20080e7          	jalr	-480(ra) # 8000327c <balloc>
    80003464:	0005099b          	sext.w	s3,a0
    80003468:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000346c:	8552                	mv	a0,s4
    8000346e:	00001097          	auipc	ra,0x1
    80003472:	ee0080e7          	jalr	-288(ra) # 8000434e <log_write>
    80003476:	b771                	j	80003402 <bmap+0x54>
  panic("bmap: out of range");
    80003478:	00005517          	auipc	a0,0x5
    8000347c:	1f850513          	addi	a0,a0,504 # 80008670 <syscalls+0x128>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	0c2080e7          	jalr	194(ra) # 80000542 <panic>

0000000080003488 <iget>:
{
    80003488:	7179                	addi	sp,sp,-48
    8000348a:	f406                	sd	ra,40(sp)
    8000348c:	f022                	sd	s0,32(sp)
    8000348e:	ec26                	sd	s1,24(sp)
    80003490:	e84a                	sd	s2,16(sp)
    80003492:	e44e                	sd	s3,8(sp)
    80003494:	e052                	sd	s4,0(sp)
    80003496:	1800                	addi	s0,sp,48
    80003498:	89aa                	mv	s3,a0
    8000349a:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000349c:	0001d517          	auipc	a0,0x1d
    800034a0:	bc450513          	addi	a0,a0,-1084 # 80020060 <icache>
    800034a4:	ffffd097          	auipc	ra,0xffffd
    800034a8:	77e080e7          	jalr	1918(ra) # 80000c22 <acquire>
  empty = 0;
    800034ac:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034ae:	0001d497          	auipc	s1,0x1d
    800034b2:	bca48493          	addi	s1,s1,-1078 # 80020078 <icache+0x18>
    800034b6:	0001e697          	auipc	a3,0x1e
    800034ba:	65268693          	addi	a3,a3,1618 # 80021b08 <log>
    800034be:	a039                	j	800034cc <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034c0:	02090b63          	beqz	s2,800034f6 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034c4:	08848493          	addi	s1,s1,136
    800034c8:	02d48a63          	beq	s1,a3,800034fc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034cc:	449c                	lw	a5,8(s1)
    800034ce:	fef059e3          	blez	a5,800034c0 <iget+0x38>
    800034d2:	4098                	lw	a4,0(s1)
    800034d4:	ff3716e3          	bne	a4,s3,800034c0 <iget+0x38>
    800034d8:	40d8                	lw	a4,4(s1)
    800034da:	ff4713e3          	bne	a4,s4,800034c0 <iget+0x38>
      ip->ref++;
    800034de:	2785                	addiw	a5,a5,1
    800034e0:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034e2:	0001d517          	auipc	a0,0x1d
    800034e6:	b7e50513          	addi	a0,a0,-1154 # 80020060 <icache>
    800034ea:	ffffd097          	auipc	ra,0xffffd
    800034ee:	7ec080e7          	jalr	2028(ra) # 80000cd6 <release>
      return ip;
    800034f2:	8926                	mv	s2,s1
    800034f4:	a03d                	j	80003522 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034f6:	f7f9                	bnez	a5,800034c4 <iget+0x3c>
    800034f8:	8926                	mv	s2,s1
    800034fa:	b7e9                	j	800034c4 <iget+0x3c>
  if(empty == 0)
    800034fc:	02090c63          	beqz	s2,80003534 <iget+0xac>
  ip->dev = dev;
    80003500:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003504:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003508:	4785                	li	a5,1
    8000350a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000350e:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003512:	0001d517          	auipc	a0,0x1d
    80003516:	b4e50513          	addi	a0,a0,-1202 # 80020060 <icache>
    8000351a:	ffffd097          	auipc	ra,0xffffd
    8000351e:	7bc080e7          	jalr	1980(ra) # 80000cd6 <release>
}
    80003522:	854a                	mv	a0,s2
    80003524:	70a2                	ld	ra,40(sp)
    80003526:	7402                	ld	s0,32(sp)
    80003528:	64e2                	ld	s1,24(sp)
    8000352a:	6942                	ld	s2,16(sp)
    8000352c:	69a2                	ld	s3,8(sp)
    8000352e:	6a02                	ld	s4,0(sp)
    80003530:	6145                	addi	sp,sp,48
    80003532:	8082                	ret
    panic("iget: no inodes");
    80003534:	00005517          	auipc	a0,0x5
    80003538:	15450513          	addi	a0,a0,340 # 80008688 <syscalls+0x140>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	006080e7          	jalr	6(ra) # 80000542 <panic>

0000000080003544 <fsinit>:
fsinit(int dev) {
    80003544:	7179                	addi	sp,sp,-48
    80003546:	f406                	sd	ra,40(sp)
    80003548:	f022                	sd	s0,32(sp)
    8000354a:	ec26                	sd	s1,24(sp)
    8000354c:	e84a                	sd	s2,16(sp)
    8000354e:	e44e                	sd	s3,8(sp)
    80003550:	1800                	addi	s0,sp,48
    80003552:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003554:	4585                	li	a1,1
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	a64080e7          	jalr	-1436(ra) # 80002fba <bread>
    8000355e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003560:	0001d997          	auipc	s3,0x1d
    80003564:	ae098993          	addi	s3,s3,-1312 # 80020040 <sb>
    80003568:	02000613          	li	a2,32
    8000356c:	05850593          	addi	a1,a0,88
    80003570:	854e                	mv	a0,s3
    80003572:	ffffe097          	auipc	ra,0xffffe
    80003576:	808080e7          	jalr	-2040(ra) # 80000d7a <memmove>
  brelse(bp);
    8000357a:	8526                	mv	a0,s1
    8000357c:	00000097          	auipc	ra,0x0
    80003580:	b6e080e7          	jalr	-1170(ra) # 800030ea <brelse>
  if(sb.magic != FSMAGIC)
    80003584:	0009a703          	lw	a4,0(s3)
    80003588:	102037b7          	lui	a5,0x10203
    8000358c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003590:	02f71263          	bne	a4,a5,800035b4 <fsinit+0x70>
  initlog(dev, &sb);
    80003594:	0001d597          	auipc	a1,0x1d
    80003598:	aac58593          	addi	a1,a1,-1364 # 80020040 <sb>
    8000359c:	854a                	mv	a0,s2
    8000359e:	00001097          	auipc	ra,0x1
    800035a2:	b38080e7          	jalr	-1224(ra) # 800040d6 <initlog>
}
    800035a6:	70a2                	ld	ra,40(sp)
    800035a8:	7402                	ld	s0,32(sp)
    800035aa:	64e2                	ld	s1,24(sp)
    800035ac:	6942                	ld	s2,16(sp)
    800035ae:	69a2                	ld	s3,8(sp)
    800035b0:	6145                	addi	sp,sp,48
    800035b2:	8082                	ret
    panic("invalid file system");
    800035b4:	00005517          	auipc	a0,0x5
    800035b8:	0e450513          	addi	a0,a0,228 # 80008698 <syscalls+0x150>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	f86080e7          	jalr	-122(ra) # 80000542 <panic>

00000000800035c4 <iinit>:
{
    800035c4:	7179                	addi	sp,sp,-48
    800035c6:	f406                	sd	ra,40(sp)
    800035c8:	f022                	sd	s0,32(sp)
    800035ca:	ec26                	sd	s1,24(sp)
    800035cc:	e84a                	sd	s2,16(sp)
    800035ce:	e44e                	sd	s3,8(sp)
    800035d0:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035d2:	00005597          	auipc	a1,0x5
    800035d6:	0de58593          	addi	a1,a1,222 # 800086b0 <syscalls+0x168>
    800035da:	0001d517          	auipc	a0,0x1d
    800035de:	a8650513          	addi	a0,a0,-1402 # 80020060 <icache>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	5b0080e7          	jalr	1456(ra) # 80000b92 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035ea:	0001d497          	auipc	s1,0x1d
    800035ee:	a9e48493          	addi	s1,s1,-1378 # 80020088 <icache+0x28>
    800035f2:	0001e997          	auipc	s3,0x1e
    800035f6:	52698993          	addi	s3,s3,1318 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035fa:	00005917          	auipc	s2,0x5
    800035fe:	0be90913          	addi	s2,s2,190 # 800086b8 <syscalls+0x170>
    80003602:	85ca                	mv	a1,s2
    80003604:	8526                	mv	a0,s1
    80003606:	00001097          	auipc	ra,0x1
    8000360a:	e36080e7          	jalr	-458(ra) # 8000443c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000360e:	08848493          	addi	s1,s1,136
    80003612:	ff3498e3          	bne	s1,s3,80003602 <iinit+0x3e>
}
    80003616:	70a2                	ld	ra,40(sp)
    80003618:	7402                	ld	s0,32(sp)
    8000361a:	64e2                	ld	s1,24(sp)
    8000361c:	6942                	ld	s2,16(sp)
    8000361e:	69a2                	ld	s3,8(sp)
    80003620:	6145                	addi	sp,sp,48
    80003622:	8082                	ret

0000000080003624 <ialloc>:
{
    80003624:	715d                	addi	sp,sp,-80
    80003626:	e486                	sd	ra,72(sp)
    80003628:	e0a2                	sd	s0,64(sp)
    8000362a:	fc26                	sd	s1,56(sp)
    8000362c:	f84a                	sd	s2,48(sp)
    8000362e:	f44e                	sd	s3,40(sp)
    80003630:	f052                	sd	s4,32(sp)
    80003632:	ec56                	sd	s5,24(sp)
    80003634:	e85a                	sd	s6,16(sp)
    80003636:	e45e                	sd	s7,8(sp)
    80003638:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000363a:	0001d717          	auipc	a4,0x1d
    8000363e:	a1272703          	lw	a4,-1518(a4) # 8002004c <sb+0xc>
    80003642:	4785                	li	a5,1
    80003644:	04e7fa63          	bgeu	a5,a4,80003698 <ialloc+0x74>
    80003648:	8aaa                	mv	s5,a0
    8000364a:	8bae                	mv	s7,a1
    8000364c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000364e:	0001da17          	auipc	s4,0x1d
    80003652:	9f2a0a13          	addi	s4,s4,-1550 # 80020040 <sb>
    80003656:	00048b1b          	sext.w	s6,s1
    8000365a:	0044d793          	srli	a5,s1,0x4
    8000365e:	018a2583          	lw	a1,24(s4)
    80003662:	9dbd                	addw	a1,a1,a5
    80003664:	8556                	mv	a0,s5
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	954080e7          	jalr	-1708(ra) # 80002fba <bread>
    8000366e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003670:	05850993          	addi	s3,a0,88
    80003674:	00f4f793          	andi	a5,s1,15
    80003678:	079a                	slli	a5,a5,0x6
    8000367a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000367c:	00099783          	lh	a5,0(s3)
    80003680:	c785                	beqz	a5,800036a8 <ialloc+0x84>
    brelse(bp);
    80003682:	00000097          	auipc	ra,0x0
    80003686:	a68080e7          	jalr	-1432(ra) # 800030ea <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000368a:	0485                	addi	s1,s1,1
    8000368c:	00ca2703          	lw	a4,12(s4)
    80003690:	0004879b          	sext.w	a5,s1
    80003694:	fce7e1e3          	bltu	a5,a4,80003656 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003698:	00005517          	auipc	a0,0x5
    8000369c:	02850513          	addi	a0,a0,40 # 800086c0 <syscalls+0x178>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	ea2080e7          	jalr	-350(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    800036a8:	04000613          	li	a2,64
    800036ac:	4581                	li	a1,0
    800036ae:	854e                	mv	a0,s3
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	66e080e7          	jalr	1646(ra) # 80000d1e <memset>
      dip->type = type;
    800036b8:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036bc:	854a                	mv	a0,s2
    800036be:	00001097          	auipc	ra,0x1
    800036c2:	c90080e7          	jalr	-880(ra) # 8000434e <log_write>
      brelse(bp);
    800036c6:	854a                	mv	a0,s2
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	a22080e7          	jalr	-1502(ra) # 800030ea <brelse>
      return iget(dev, inum);
    800036d0:	85da                	mv	a1,s6
    800036d2:	8556                	mv	a0,s5
    800036d4:	00000097          	auipc	ra,0x0
    800036d8:	db4080e7          	jalr	-588(ra) # 80003488 <iget>
}
    800036dc:	60a6                	ld	ra,72(sp)
    800036de:	6406                	ld	s0,64(sp)
    800036e0:	74e2                	ld	s1,56(sp)
    800036e2:	7942                	ld	s2,48(sp)
    800036e4:	79a2                	ld	s3,40(sp)
    800036e6:	7a02                	ld	s4,32(sp)
    800036e8:	6ae2                	ld	s5,24(sp)
    800036ea:	6b42                	ld	s6,16(sp)
    800036ec:	6ba2                	ld	s7,8(sp)
    800036ee:	6161                	addi	sp,sp,80
    800036f0:	8082                	ret

00000000800036f2 <iupdate>:
{
    800036f2:	1101                	addi	sp,sp,-32
    800036f4:	ec06                	sd	ra,24(sp)
    800036f6:	e822                	sd	s0,16(sp)
    800036f8:	e426                	sd	s1,8(sp)
    800036fa:	e04a                	sd	s2,0(sp)
    800036fc:	1000                	addi	s0,sp,32
    800036fe:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003700:	415c                	lw	a5,4(a0)
    80003702:	0047d79b          	srliw	a5,a5,0x4
    80003706:	0001d597          	auipc	a1,0x1d
    8000370a:	9525a583          	lw	a1,-1710(a1) # 80020058 <sb+0x18>
    8000370e:	9dbd                	addw	a1,a1,a5
    80003710:	4108                	lw	a0,0(a0)
    80003712:	00000097          	auipc	ra,0x0
    80003716:	8a8080e7          	jalr	-1880(ra) # 80002fba <bread>
    8000371a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000371c:	05850793          	addi	a5,a0,88
    80003720:	40c8                	lw	a0,4(s1)
    80003722:	893d                	andi	a0,a0,15
    80003724:	051a                	slli	a0,a0,0x6
    80003726:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003728:	04449703          	lh	a4,68(s1)
    8000372c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003730:	04649703          	lh	a4,70(s1)
    80003734:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003738:	04849703          	lh	a4,72(s1)
    8000373c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003740:	04a49703          	lh	a4,74(s1)
    80003744:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003748:	44f8                	lw	a4,76(s1)
    8000374a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000374c:	03400613          	li	a2,52
    80003750:	05048593          	addi	a1,s1,80
    80003754:	0531                	addi	a0,a0,12
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	624080e7          	jalr	1572(ra) # 80000d7a <memmove>
  log_write(bp);
    8000375e:	854a                	mv	a0,s2
    80003760:	00001097          	auipc	ra,0x1
    80003764:	bee080e7          	jalr	-1042(ra) # 8000434e <log_write>
  brelse(bp);
    80003768:	854a                	mv	a0,s2
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	980080e7          	jalr	-1664(ra) # 800030ea <brelse>
}
    80003772:	60e2                	ld	ra,24(sp)
    80003774:	6442                	ld	s0,16(sp)
    80003776:	64a2                	ld	s1,8(sp)
    80003778:	6902                	ld	s2,0(sp)
    8000377a:	6105                	addi	sp,sp,32
    8000377c:	8082                	ret

000000008000377e <idup>:
{
    8000377e:	1101                	addi	sp,sp,-32
    80003780:	ec06                	sd	ra,24(sp)
    80003782:	e822                	sd	s0,16(sp)
    80003784:	e426                	sd	s1,8(sp)
    80003786:	1000                	addi	s0,sp,32
    80003788:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000378a:	0001d517          	auipc	a0,0x1d
    8000378e:	8d650513          	addi	a0,a0,-1834 # 80020060 <icache>
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	490080e7          	jalr	1168(ra) # 80000c22 <acquire>
  ip->ref++;
    8000379a:	449c                	lw	a5,8(s1)
    8000379c:	2785                	addiw	a5,a5,1
    8000379e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037a0:	0001d517          	auipc	a0,0x1d
    800037a4:	8c050513          	addi	a0,a0,-1856 # 80020060 <icache>
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	52e080e7          	jalr	1326(ra) # 80000cd6 <release>
}
    800037b0:	8526                	mv	a0,s1
    800037b2:	60e2                	ld	ra,24(sp)
    800037b4:	6442                	ld	s0,16(sp)
    800037b6:	64a2                	ld	s1,8(sp)
    800037b8:	6105                	addi	sp,sp,32
    800037ba:	8082                	ret

00000000800037bc <ilock>:
{
    800037bc:	1101                	addi	sp,sp,-32
    800037be:	ec06                	sd	ra,24(sp)
    800037c0:	e822                	sd	s0,16(sp)
    800037c2:	e426                	sd	s1,8(sp)
    800037c4:	e04a                	sd	s2,0(sp)
    800037c6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037c8:	c115                	beqz	a0,800037ec <ilock+0x30>
    800037ca:	84aa                	mv	s1,a0
    800037cc:	451c                	lw	a5,8(a0)
    800037ce:	00f05f63          	blez	a5,800037ec <ilock+0x30>
  acquiresleep(&ip->lock);
    800037d2:	0541                	addi	a0,a0,16
    800037d4:	00001097          	auipc	ra,0x1
    800037d8:	ca2080e7          	jalr	-862(ra) # 80004476 <acquiresleep>
  if(ip->valid == 0){
    800037dc:	40bc                	lw	a5,64(s1)
    800037de:	cf99                	beqz	a5,800037fc <ilock+0x40>
}
    800037e0:	60e2                	ld	ra,24(sp)
    800037e2:	6442                	ld	s0,16(sp)
    800037e4:	64a2                	ld	s1,8(sp)
    800037e6:	6902                	ld	s2,0(sp)
    800037e8:	6105                	addi	sp,sp,32
    800037ea:	8082                	ret
    panic("ilock");
    800037ec:	00005517          	auipc	a0,0x5
    800037f0:	eec50513          	addi	a0,a0,-276 # 800086d8 <syscalls+0x190>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	d4e080e7          	jalr	-690(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037fc:	40dc                	lw	a5,4(s1)
    800037fe:	0047d79b          	srliw	a5,a5,0x4
    80003802:	0001d597          	auipc	a1,0x1d
    80003806:	8565a583          	lw	a1,-1962(a1) # 80020058 <sb+0x18>
    8000380a:	9dbd                	addw	a1,a1,a5
    8000380c:	4088                	lw	a0,0(s1)
    8000380e:	fffff097          	auipc	ra,0xfffff
    80003812:	7ac080e7          	jalr	1964(ra) # 80002fba <bread>
    80003816:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003818:	05850593          	addi	a1,a0,88
    8000381c:	40dc                	lw	a5,4(s1)
    8000381e:	8bbd                	andi	a5,a5,15
    80003820:	079a                	slli	a5,a5,0x6
    80003822:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003824:	00059783          	lh	a5,0(a1)
    80003828:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000382c:	00259783          	lh	a5,2(a1)
    80003830:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003834:	00459783          	lh	a5,4(a1)
    80003838:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000383c:	00659783          	lh	a5,6(a1)
    80003840:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003844:	459c                	lw	a5,8(a1)
    80003846:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003848:	03400613          	li	a2,52
    8000384c:	05b1                	addi	a1,a1,12
    8000384e:	05048513          	addi	a0,s1,80
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	528080e7          	jalr	1320(ra) # 80000d7a <memmove>
    brelse(bp);
    8000385a:	854a                	mv	a0,s2
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	88e080e7          	jalr	-1906(ra) # 800030ea <brelse>
    ip->valid = 1;
    80003864:	4785                	li	a5,1
    80003866:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003868:	04449783          	lh	a5,68(s1)
    8000386c:	fbb5                	bnez	a5,800037e0 <ilock+0x24>
      panic("ilock: no type");
    8000386e:	00005517          	auipc	a0,0x5
    80003872:	e7250513          	addi	a0,a0,-398 # 800086e0 <syscalls+0x198>
    80003876:	ffffd097          	auipc	ra,0xffffd
    8000387a:	ccc080e7          	jalr	-820(ra) # 80000542 <panic>

000000008000387e <iunlock>:
{
    8000387e:	1101                	addi	sp,sp,-32
    80003880:	ec06                	sd	ra,24(sp)
    80003882:	e822                	sd	s0,16(sp)
    80003884:	e426                	sd	s1,8(sp)
    80003886:	e04a                	sd	s2,0(sp)
    80003888:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000388a:	c905                	beqz	a0,800038ba <iunlock+0x3c>
    8000388c:	84aa                	mv	s1,a0
    8000388e:	01050913          	addi	s2,a0,16
    80003892:	854a                	mv	a0,s2
    80003894:	00001097          	auipc	ra,0x1
    80003898:	c7c080e7          	jalr	-900(ra) # 80004510 <holdingsleep>
    8000389c:	cd19                	beqz	a0,800038ba <iunlock+0x3c>
    8000389e:	449c                	lw	a5,8(s1)
    800038a0:	00f05d63          	blez	a5,800038ba <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038a4:	854a                	mv	a0,s2
    800038a6:	00001097          	auipc	ra,0x1
    800038aa:	c26080e7          	jalr	-986(ra) # 800044cc <releasesleep>
}
    800038ae:	60e2                	ld	ra,24(sp)
    800038b0:	6442                	ld	s0,16(sp)
    800038b2:	64a2                	ld	s1,8(sp)
    800038b4:	6902                	ld	s2,0(sp)
    800038b6:	6105                	addi	sp,sp,32
    800038b8:	8082                	ret
    panic("iunlock");
    800038ba:	00005517          	auipc	a0,0x5
    800038be:	e3650513          	addi	a0,a0,-458 # 800086f0 <syscalls+0x1a8>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	c80080e7          	jalr	-896(ra) # 80000542 <panic>

00000000800038ca <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038ca:	7179                	addi	sp,sp,-48
    800038cc:	f406                	sd	ra,40(sp)
    800038ce:	f022                	sd	s0,32(sp)
    800038d0:	ec26                	sd	s1,24(sp)
    800038d2:	e84a                	sd	s2,16(sp)
    800038d4:	e44e                	sd	s3,8(sp)
    800038d6:	e052                	sd	s4,0(sp)
    800038d8:	1800                	addi	s0,sp,48
    800038da:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038dc:	05050493          	addi	s1,a0,80
    800038e0:	08050913          	addi	s2,a0,128
    800038e4:	a021                	j	800038ec <itrunc+0x22>
    800038e6:	0491                	addi	s1,s1,4
    800038e8:	01248d63          	beq	s1,s2,80003902 <itrunc+0x38>
    if(ip->addrs[i]){
    800038ec:	408c                	lw	a1,0(s1)
    800038ee:	dde5                	beqz	a1,800038e6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038f0:	0009a503          	lw	a0,0(s3)
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	90c080e7          	jalr	-1780(ra) # 80003200 <bfree>
      ip->addrs[i] = 0;
    800038fc:	0004a023          	sw	zero,0(s1)
    80003900:	b7dd                	j	800038e6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003902:	0809a583          	lw	a1,128(s3)
    80003906:	e185                	bnez	a1,80003926 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003908:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000390c:	854e                	mv	a0,s3
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	de4080e7          	jalr	-540(ra) # 800036f2 <iupdate>
}
    80003916:	70a2                	ld	ra,40(sp)
    80003918:	7402                	ld	s0,32(sp)
    8000391a:	64e2                	ld	s1,24(sp)
    8000391c:	6942                	ld	s2,16(sp)
    8000391e:	69a2                	ld	s3,8(sp)
    80003920:	6a02                	ld	s4,0(sp)
    80003922:	6145                	addi	sp,sp,48
    80003924:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003926:	0009a503          	lw	a0,0(s3)
    8000392a:	fffff097          	auipc	ra,0xfffff
    8000392e:	690080e7          	jalr	1680(ra) # 80002fba <bread>
    80003932:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003934:	05850493          	addi	s1,a0,88
    80003938:	45850913          	addi	s2,a0,1112
    8000393c:	a021                	j	80003944 <itrunc+0x7a>
    8000393e:	0491                	addi	s1,s1,4
    80003940:	01248b63          	beq	s1,s2,80003956 <itrunc+0x8c>
      if(a[j])
    80003944:	408c                	lw	a1,0(s1)
    80003946:	dde5                	beqz	a1,8000393e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003948:	0009a503          	lw	a0,0(s3)
    8000394c:	00000097          	auipc	ra,0x0
    80003950:	8b4080e7          	jalr	-1868(ra) # 80003200 <bfree>
    80003954:	b7ed                	j	8000393e <itrunc+0x74>
    brelse(bp);
    80003956:	8552                	mv	a0,s4
    80003958:	fffff097          	auipc	ra,0xfffff
    8000395c:	792080e7          	jalr	1938(ra) # 800030ea <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003960:	0809a583          	lw	a1,128(s3)
    80003964:	0009a503          	lw	a0,0(s3)
    80003968:	00000097          	auipc	ra,0x0
    8000396c:	898080e7          	jalr	-1896(ra) # 80003200 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003970:	0809a023          	sw	zero,128(s3)
    80003974:	bf51                	j	80003908 <itrunc+0x3e>

0000000080003976 <iput>:
{
    80003976:	1101                	addi	sp,sp,-32
    80003978:	ec06                	sd	ra,24(sp)
    8000397a:	e822                	sd	s0,16(sp)
    8000397c:	e426                	sd	s1,8(sp)
    8000397e:	e04a                	sd	s2,0(sp)
    80003980:	1000                	addi	s0,sp,32
    80003982:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003984:	0001c517          	auipc	a0,0x1c
    80003988:	6dc50513          	addi	a0,a0,1756 # 80020060 <icache>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	296080e7          	jalr	662(ra) # 80000c22 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003994:	4498                	lw	a4,8(s1)
    80003996:	4785                	li	a5,1
    80003998:	02f70363          	beq	a4,a5,800039be <iput+0x48>
  ip->ref--;
    8000399c:	449c                	lw	a5,8(s1)
    8000399e:	37fd                	addiw	a5,a5,-1
    800039a0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039a2:	0001c517          	auipc	a0,0x1c
    800039a6:	6be50513          	addi	a0,a0,1726 # 80020060 <icache>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	32c080e7          	jalr	812(ra) # 80000cd6 <release>
}
    800039b2:	60e2                	ld	ra,24(sp)
    800039b4:	6442                	ld	s0,16(sp)
    800039b6:	64a2                	ld	s1,8(sp)
    800039b8:	6902                	ld	s2,0(sp)
    800039ba:	6105                	addi	sp,sp,32
    800039bc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039be:	40bc                	lw	a5,64(s1)
    800039c0:	dff1                	beqz	a5,8000399c <iput+0x26>
    800039c2:	04a49783          	lh	a5,74(s1)
    800039c6:	fbf9                	bnez	a5,8000399c <iput+0x26>
    acquiresleep(&ip->lock);
    800039c8:	01048913          	addi	s2,s1,16
    800039cc:	854a                	mv	a0,s2
    800039ce:	00001097          	auipc	ra,0x1
    800039d2:	aa8080e7          	jalr	-1368(ra) # 80004476 <acquiresleep>
    release(&icache.lock);
    800039d6:	0001c517          	auipc	a0,0x1c
    800039da:	68a50513          	addi	a0,a0,1674 # 80020060 <icache>
    800039de:	ffffd097          	auipc	ra,0xffffd
    800039e2:	2f8080e7          	jalr	760(ra) # 80000cd6 <release>
    itrunc(ip);
    800039e6:	8526                	mv	a0,s1
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	ee2080e7          	jalr	-286(ra) # 800038ca <itrunc>
    ip->type = 0;
    800039f0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039f4:	8526                	mv	a0,s1
    800039f6:	00000097          	auipc	ra,0x0
    800039fa:	cfc080e7          	jalr	-772(ra) # 800036f2 <iupdate>
    ip->valid = 0;
    800039fe:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a02:	854a                	mv	a0,s2
    80003a04:	00001097          	auipc	ra,0x1
    80003a08:	ac8080e7          	jalr	-1336(ra) # 800044cc <releasesleep>
    acquire(&icache.lock);
    80003a0c:	0001c517          	auipc	a0,0x1c
    80003a10:	65450513          	addi	a0,a0,1620 # 80020060 <icache>
    80003a14:	ffffd097          	auipc	ra,0xffffd
    80003a18:	20e080e7          	jalr	526(ra) # 80000c22 <acquire>
    80003a1c:	b741                	j	8000399c <iput+0x26>

0000000080003a1e <iunlockput>:
{
    80003a1e:	1101                	addi	sp,sp,-32
    80003a20:	ec06                	sd	ra,24(sp)
    80003a22:	e822                	sd	s0,16(sp)
    80003a24:	e426                	sd	s1,8(sp)
    80003a26:	1000                	addi	s0,sp,32
    80003a28:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	e54080e7          	jalr	-428(ra) # 8000387e <iunlock>
  iput(ip);
    80003a32:	8526                	mv	a0,s1
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	f42080e7          	jalr	-190(ra) # 80003976 <iput>
}
    80003a3c:	60e2                	ld	ra,24(sp)
    80003a3e:	6442                	ld	s0,16(sp)
    80003a40:	64a2                	ld	s1,8(sp)
    80003a42:	6105                	addi	sp,sp,32
    80003a44:	8082                	ret

0000000080003a46 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a46:	1141                	addi	sp,sp,-16
    80003a48:	e422                	sd	s0,8(sp)
    80003a4a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a4c:	411c                	lw	a5,0(a0)
    80003a4e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a50:	415c                	lw	a5,4(a0)
    80003a52:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a54:	04451783          	lh	a5,68(a0)
    80003a58:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a5c:	04a51783          	lh	a5,74(a0)
    80003a60:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a64:	04c56783          	lwu	a5,76(a0)
    80003a68:	e99c                	sd	a5,16(a1)
}
    80003a6a:	6422                	ld	s0,8(sp)
    80003a6c:	0141                	addi	sp,sp,16
    80003a6e:	8082                	ret

0000000080003a70 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a70:	457c                	lw	a5,76(a0)
    80003a72:	0ed7e863          	bltu	a5,a3,80003b62 <readi+0xf2>
{
    80003a76:	7159                	addi	sp,sp,-112
    80003a78:	f486                	sd	ra,104(sp)
    80003a7a:	f0a2                	sd	s0,96(sp)
    80003a7c:	eca6                	sd	s1,88(sp)
    80003a7e:	e8ca                	sd	s2,80(sp)
    80003a80:	e4ce                	sd	s3,72(sp)
    80003a82:	e0d2                	sd	s4,64(sp)
    80003a84:	fc56                	sd	s5,56(sp)
    80003a86:	f85a                	sd	s6,48(sp)
    80003a88:	f45e                	sd	s7,40(sp)
    80003a8a:	f062                	sd	s8,32(sp)
    80003a8c:	ec66                	sd	s9,24(sp)
    80003a8e:	e86a                	sd	s10,16(sp)
    80003a90:	e46e                	sd	s11,8(sp)
    80003a92:	1880                	addi	s0,sp,112
    80003a94:	8baa                	mv	s7,a0
    80003a96:	8c2e                	mv	s8,a1
    80003a98:	8ab2                	mv	s5,a2
    80003a9a:	84b6                	mv	s1,a3
    80003a9c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a9e:	9f35                	addw	a4,a4,a3
    return 0;
    80003aa0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003aa2:	08d76f63          	bltu	a4,a3,80003b40 <readi+0xd0>
  if(off + n > ip->size)
    80003aa6:	00e7f463          	bgeu	a5,a4,80003aae <readi+0x3e>
    n = ip->size - off;
    80003aaa:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aae:	0a0b0863          	beqz	s6,80003b5e <readi+0xee>
    80003ab2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ab8:	5cfd                	li	s9,-1
    80003aba:	a82d                	j	80003af4 <readi+0x84>
    80003abc:	020a1d93          	slli	s11,s4,0x20
    80003ac0:	020ddd93          	srli	s11,s11,0x20
    80003ac4:	05890793          	addi	a5,s2,88
    80003ac8:	86ee                	mv	a3,s11
    80003aca:	963e                	add	a2,a2,a5
    80003acc:	85d6                	mv	a1,s5
    80003ace:	8562                	mv	a0,s8
    80003ad0:	fffff097          	auipc	ra,0xfffff
    80003ad4:	990080e7          	jalr	-1648(ra) # 80002460 <either_copyout>
    80003ad8:	05950d63          	beq	a0,s9,80003b32 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003adc:	854a                	mv	a0,s2
    80003ade:	fffff097          	auipc	ra,0xfffff
    80003ae2:	60c080e7          	jalr	1548(ra) # 800030ea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ae6:	013a09bb          	addw	s3,s4,s3
    80003aea:	009a04bb          	addw	s1,s4,s1
    80003aee:	9aee                	add	s5,s5,s11
    80003af0:	0569f663          	bgeu	s3,s6,80003b3c <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003af4:	000ba903          	lw	s2,0(s7)
    80003af8:	00a4d59b          	srliw	a1,s1,0xa
    80003afc:	855e                	mv	a0,s7
    80003afe:	00000097          	auipc	ra,0x0
    80003b02:	8b0080e7          	jalr	-1872(ra) # 800033ae <bmap>
    80003b06:	0005059b          	sext.w	a1,a0
    80003b0a:	854a                	mv	a0,s2
    80003b0c:	fffff097          	auipc	ra,0xfffff
    80003b10:	4ae080e7          	jalr	1198(ra) # 80002fba <bread>
    80003b14:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b16:	3ff4f613          	andi	a2,s1,1023
    80003b1a:	40cd07bb          	subw	a5,s10,a2
    80003b1e:	413b073b          	subw	a4,s6,s3
    80003b22:	8a3e                	mv	s4,a5
    80003b24:	2781                	sext.w	a5,a5
    80003b26:	0007069b          	sext.w	a3,a4
    80003b2a:	f8f6f9e3          	bgeu	a3,a5,80003abc <readi+0x4c>
    80003b2e:	8a3a                	mv	s4,a4
    80003b30:	b771                	j	80003abc <readi+0x4c>
      brelse(bp);
    80003b32:	854a                	mv	a0,s2
    80003b34:	fffff097          	auipc	ra,0xfffff
    80003b38:	5b6080e7          	jalr	1462(ra) # 800030ea <brelse>
  }
  return tot;
    80003b3c:	0009851b          	sext.w	a0,s3
}
    80003b40:	70a6                	ld	ra,104(sp)
    80003b42:	7406                	ld	s0,96(sp)
    80003b44:	64e6                	ld	s1,88(sp)
    80003b46:	6946                	ld	s2,80(sp)
    80003b48:	69a6                	ld	s3,72(sp)
    80003b4a:	6a06                	ld	s4,64(sp)
    80003b4c:	7ae2                	ld	s5,56(sp)
    80003b4e:	7b42                	ld	s6,48(sp)
    80003b50:	7ba2                	ld	s7,40(sp)
    80003b52:	7c02                	ld	s8,32(sp)
    80003b54:	6ce2                	ld	s9,24(sp)
    80003b56:	6d42                	ld	s10,16(sp)
    80003b58:	6da2                	ld	s11,8(sp)
    80003b5a:	6165                	addi	sp,sp,112
    80003b5c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b5e:	89da                	mv	s3,s6
    80003b60:	bff1                	j	80003b3c <readi+0xcc>
    return 0;
    80003b62:	4501                	li	a0,0
}
    80003b64:	8082                	ret

0000000080003b66 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b66:	457c                	lw	a5,76(a0)
    80003b68:	10d7e663          	bltu	a5,a3,80003c74 <writei+0x10e>
{
    80003b6c:	7159                	addi	sp,sp,-112
    80003b6e:	f486                	sd	ra,104(sp)
    80003b70:	f0a2                	sd	s0,96(sp)
    80003b72:	eca6                	sd	s1,88(sp)
    80003b74:	e8ca                	sd	s2,80(sp)
    80003b76:	e4ce                	sd	s3,72(sp)
    80003b78:	e0d2                	sd	s4,64(sp)
    80003b7a:	fc56                	sd	s5,56(sp)
    80003b7c:	f85a                	sd	s6,48(sp)
    80003b7e:	f45e                	sd	s7,40(sp)
    80003b80:	f062                	sd	s8,32(sp)
    80003b82:	ec66                	sd	s9,24(sp)
    80003b84:	e86a                	sd	s10,16(sp)
    80003b86:	e46e                	sd	s11,8(sp)
    80003b88:	1880                	addi	s0,sp,112
    80003b8a:	8baa                	mv	s7,a0
    80003b8c:	8c2e                	mv	s8,a1
    80003b8e:	8ab2                	mv	s5,a2
    80003b90:	8936                	mv	s2,a3
    80003b92:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b94:	00e687bb          	addw	a5,a3,a4
    80003b98:	0ed7e063          	bltu	a5,a3,80003c78 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b9c:	00043737          	lui	a4,0x43
    80003ba0:	0cf76e63          	bltu	a4,a5,80003c7c <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba4:	0a0b0763          	beqz	s6,80003c52 <writei+0xec>
    80003ba8:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003baa:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bae:	5cfd                	li	s9,-1
    80003bb0:	a091                	j	80003bf4 <writei+0x8e>
    80003bb2:	02099d93          	slli	s11,s3,0x20
    80003bb6:	020ddd93          	srli	s11,s11,0x20
    80003bba:	05848793          	addi	a5,s1,88
    80003bbe:	86ee                	mv	a3,s11
    80003bc0:	8656                	mv	a2,s5
    80003bc2:	85e2                	mv	a1,s8
    80003bc4:	953e                	add	a0,a0,a5
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	8f0080e7          	jalr	-1808(ra) # 800024b6 <either_copyin>
    80003bce:	07950263          	beq	a0,s9,80003c32 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bd2:	8526                	mv	a0,s1
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	77a080e7          	jalr	1914(ra) # 8000434e <log_write>
    brelse(bp);
    80003bdc:	8526                	mv	a0,s1
    80003bde:	fffff097          	auipc	ra,0xfffff
    80003be2:	50c080e7          	jalr	1292(ra) # 800030ea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003be6:	01498a3b          	addw	s4,s3,s4
    80003bea:	0129893b          	addw	s2,s3,s2
    80003bee:	9aee                	add	s5,s5,s11
    80003bf0:	056a7663          	bgeu	s4,s6,80003c3c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bf4:	000ba483          	lw	s1,0(s7)
    80003bf8:	00a9559b          	srliw	a1,s2,0xa
    80003bfc:	855e                	mv	a0,s7
    80003bfe:	fffff097          	auipc	ra,0xfffff
    80003c02:	7b0080e7          	jalr	1968(ra) # 800033ae <bmap>
    80003c06:	0005059b          	sext.w	a1,a0
    80003c0a:	8526                	mv	a0,s1
    80003c0c:	fffff097          	auipc	ra,0xfffff
    80003c10:	3ae080e7          	jalr	942(ra) # 80002fba <bread>
    80003c14:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c16:	3ff97513          	andi	a0,s2,1023
    80003c1a:	40ad07bb          	subw	a5,s10,a0
    80003c1e:	414b073b          	subw	a4,s6,s4
    80003c22:	89be                	mv	s3,a5
    80003c24:	2781                	sext.w	a5,a5
    80003c26:	0007069b          	sext.w	a3,a4
    80003c2a:	f8f6f4e3          	bgeu	a3,a5,80003bb2 <writei+0x4c>
    80003c2e:	89ba                	mv	s3,a4
    80003c30:	b749                	j	80003bb2 <writei+0x4c>
      brelse(bp);
    80003c32:	8526                	mv	a0,s1
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	4b6080e7          	jalr	1206(ra) # 800030ea <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003c3c:	04cba783          	lw	a5,76(s7)
    80003c40:	0127f463          	bgeu	a5,s2,80003c48 <writei+0xe2>
      ip->size = off;
    80003c44:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c48:	855e                	mv	a0,s7
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	aa8080e7          	jalr	-1368(ra) # 800036f2 <iupdate>
  }

  return n;
    80003c52:	000b051b          	sext.w	a0,s6
}
    80003c56:	70a6                	ld	ra,104(sp)
    80003c58:	7406                	ld	s0,96(sp)
    80003c5a:	64e6                	ld	s1,88(sp)
    80003c5c:	6946                	ld	s2,80(sp)
    80003c5e:	69a6                	ld	s3,72(sp)
    80003c60:	6a06                	ld	s4,64(sp)
    80003c62:	7ae2                	ld	s5,56(sp)
    80003c64:	7b42                	ld	s6,48(sp)
    80003c66:	7ba2                	ld	s7,40(sp)
    80003c68:	7c02                	ld	s8,32(sp)
    80003c6a:	6ce2                	ld	s9,24(sp)
    80003c6c:	6d42                	ld	s10,16(sp)
    80003c6e:	6da2                	ld	s11,8(sp)
    80003c70:	6165                	addi	sp,sp,112
    80003c72:	8082                	ret
    return -1;
    80003c74:	557d                	li	a0,-1
}
    80003c76:	8082                	ret
    return -1;
    80003c78:	557d                	li	a0,-1
    80003c7a:	bff1                	j	80003c56 <writei+0xf0>
    return -1;
    80003c7c:	557d                	li	a0,-1
    80003c7e:	bfe1                	j	80003c56 <writei+0xf0>

0000000080003c80 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c80:	1141                	addi	sp,sp,-16
    80003c82:	e406                	sd	ra,8(sp)
    80003c84:	e022                	sd	s0,0(sp)
    80003c86:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c88:	4639                	li	a2,14
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	16c080e7          	jalr	364(ra) # 80000df6 <strncmp>
}
    80003c92:	60a2                	ld	ra,8(sp)
    80003c94:	6402                	ld	s0,0(sp)
    80003c96:	0141                	addi	sp,sp,16
    80003c98:	8082                	ret

0000000080003c9a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c9a:	7139                	addi	sp,sp,-64
    80003c9c:	fc06                	sd	ra,56(sp)
    80003c9e:	f822                	sd	s0,48(sp)
    80003ca0:	f426                	sd	s1,40(sp)
    80003ca2:	f04a                	sd	s2,32(sp)
    80003ca4:	ec4e                	sd	s3,24(sp)
    80003ca6:	e852                	sd	s4,16(sp)
    80003ca8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003caa:	04451703          	lh	a4,68(a0)
    80003cae:	4785                	li	a5,1
    80003cb0:	00f71a63          	bne	a4,a5,80003cc4 <dirlookup+0x2a>
    80003cb4:	892a                	mv	s2,a0
    80003cb6:	89ae                	mv	s3,a1
    80003cb8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cba:	457c                	lw	a5,76(a0)
    80003cbc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cbe:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc0:	e79d                	bnez	a5,80003cee <dirlookup+0x54>
    80003cc2:	a8a5                	j	80003d3a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cc4:	00005517          	auipc	a0,0x5
    80003cc8:	a3450513          	addi	a0,a0,-1484 # 800086f8 <syscalls+0x1b0>
    80003ccc:	ffffd097          	auipc	ra,0xffffd
    80003cd0:	876080e7          	jalr	-1930(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003cd4:	00005517          	auipc	a0,0x5
    80003cd8:	a3c50513          	addi	a0,a0,-1476 # 80008710 <syscalls+0x1c8>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	866080e7          	jalr	-1946(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce4:	24c1                	addiw	s1,s1,16
    80003ce6:	04c92783          	lw	a5,76(s2)
    80003cea:	04f4f763          	bgeu	s1,a5,80003d38 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cee:	4741                	li	a4,16
    80003cf0:	86a6                	mv	a3,s1
    80003cf2:	fc040613          	addi	a2,s0,-64
    80003cf6:	4581                	li	a1,0
    80003cf8:	854a                	mv	a0,s2
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	d76080e7          	jalr	-650(ra) # 80003a70 <readi>
    80003d02:	47c1                	li	a5,16
    80003d04:	fcf518e3          	bne	a0,a5,80003cd4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d08:	fc045783          	lhu	a5,-64(s0)
    80003d0c:	dfe1                	beqz	a5,80003ce4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d0e:	fc240593          	addi	a1,s0,-62
    80003d12:	854e                	mv	a0,s3
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	f6c080e7          	jalr	-148(ra) # 80003c80 <namecmp>
    80003d1c:	f561                	bnez	a0,80003ce4 <dirlookup+0x4a>
      if(poff)
    80003d1e:	000a0463          	beqz	s4,80003d26 <dirlookup+0x8c>
        *poff = off;
    80003d22:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d26:	fc045583          	lhu	a1,-64(s0)
    80003d2a:	00092503          	lw	a0,0(s2)
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	75a080e7          	jalr	1882(ra) # 80003488 <iget>
    80003d36:	a011                	j	80003d3a <dirlookup+0xa0>
  return 0;
    80003d38:	4501                	li	a0,0
}
    80003d3a:	70e2                	ld	ra,56(sp)
    80003d3c:	7442                	ld	s0,48(sp)
    80003d3e:	74a2                	ld	s1,40(sp)
    80003d40:	7902                	ld	s2,32(sp)
    80003d42:	69e2                	ld	s3,24(sp)
    80003d44:	6a42                	ld	s4,16(sp)
    80003d46:	6121                	addi	sp,sp,64
    80003d48:	8082                	ret

0000000080003d4a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d4a:	711d                	addi	sp,sp,-96
    80003d4c:	ec86                	sd	ra,88(sp)
    80003d4e:	e8a2                	sd	s0,80(sp)
    80003d50:	e4a6                	sd	s1,72(sp)
    80003d52:	e0ca                	sd	s2,64(sp)
    80003d54:	fc4e                	sd	s3,56(sp)
    80003d56:	f852                	sd	s4,48(sp)
    80003d58:	f456                	sd	s5,40(sp)
    80003d5a:	f05a                	sd	s6,32(sp)
    80003d5c:	ec5e                	sd	s7,24(sp)
    80003d5e:	e862                	sd	s8,16(sp)
    80003d60:	e466                	sd	s9,8(sp)
    80003d62:	1080                	addi	s0,sp,96
    80003d64:	84aa                	mv	s1,a0
    80003d66:	8aae                	mv	s5,a1
    80003d68:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d6a:	00054703          	lbu	a4,0(a0)
    80003d6e:	02f00793          	li	a5,47
    80003d72:	02f70363          	beq	a4,a5,80003d98 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d76:	ffffe097          	auipc	ra,0xffffe
    80003d7a:	c78080e7          	jalr	-904(ra) # 800019ee <myproc>
    80003d7e:	15053503          	ld	a0,336(a0)
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	9fc080e7          	jalr	-1540(ra) # 8000377e <idup>
    80003d8a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d8c:	02f00913          	li	s2,47
  len = path - s;
    80003d90:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d92:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d94:	4b85                	li	s7,1
    80003d96:	a865                	j	80003e4e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d98:	4585                	li	a1,1
    80003d9a:	4505                	li	a0,1
    80003d9c:	fffff097          	auipc	ra,0xfffff
    80003da0:	6ec080e7          	jalr	1772(ra) # 80003488 <iget>
    80003da4:	89aa                	mv	s3,a0
    80003da6:	b7dd                	j	80003d8c <namex+0x42>
      iunlockput(ip);
    80003da8:	854e                	mv	a0,s3
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	c74080e7          	jalr	-908(ra) # 80003a1e <iunlockput>
      return 0;
    80003db2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003db4:	854e                	mv	a0,s3
    80003db6:	60e6                	ld	ra,88(sp)
    80003db8:	6446                	ld	s0,80(sp)
    80003dba:	64a6                	ld	s1,72(sp)
    80003dbc:	6906                	ld	s2,64(sp)
    80003dbe:	79e2                	ld	s3,56(sp)
    80003dc0:	7a42                	ld	s4,48(sp)
    80003dc2:	7aa2                	ld	s5,40(sp)
    80003dc4:	7b02                	ld	s6,32(sp)
    80003dc6:	6be2                	ld	s7,24(sp)
    80003dc8:	6c42                	ld	s8,16(sp)
    80003dca:	6ca2                	ld	s9,8(sp)
    80003dcc:	6125                	addi	sp,sp,96
    80003dce:	8082                	ret
      iunlock(ip);
    80003dd0:	854e                	mv	a0,s3
    80003dd2:	00000097          	auipc	ra,0x0
    80003dd6:	aac080e7          	jalr	-1364(ra) # 8000387e <iunlock>
      return ip;
    80003dda:	bfe9                	j	80003db4 <namex+0x6a>
      iunlockput(ip);
    80003ddc:	854e                	mv	a0,s3
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	c40080e7          	jalr	-960(ra) # 80003a1e <iunlockput>
      return 0;
    80003de6:	89e6                	mv	s3,s9
    80003de8:	b7f1                	j	80003db4 <namex+0x6a>
  len = path - s;
    80003dea:	40b48633          	sub	a2,s1,a1
    80003dee:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003df2:	099c5463          	bge	s8,s9,80003e7a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003df6:	4639                	li	a2,14
    80003df8:	8552                	mv	a0,s4
    80003dfa:	ffffd097          	auipc	ra,0xffffd
    80003dfe:	f80080e7          	jalr	-128(ra) # 80000d7a <memmove>
  while(*path == '/')
    80003e02:	0004c783          	lbu	a5,0(s1)
    80003e06:	01279763          	bne	a5,s2,80003e14 <namex+0xca>
    path++;
    80003e0a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e0c:	0004c783          	lbu	a5,0(s1)
    80003e10:	ff278de3          	beq	a5,s2,80003e0a <namex+0xc0>
    ilock(ip);
    80003e14:	854e                	mv	a0,s3
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	9a6080e7          	jalr	-1626(ra) # 800037bc <ilock>
    if(ip->type != T_DIR){
    80003e1e:	04499783          	lh	a5,68(s3)
    80003e22:	f97793e3          	bne	a5,s7,80003da8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e26:	000a8563          	beqz	s5,80003e30 <namex+0xe6>
    80003e2a:	0004c783          	lbu	a5,0(s1)
    80003e2e:	d3cd                	beqz	a5,80003dd0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e30:	865a                	mv	a2,s6
    80003e32:	85d2                	mv	a1,s4
    80003e34:	854e                	mv	a0,s3
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	e64080e7          	jalr	-412(ra) # 80003c9a <dirlookup>
    80003e3e:	8caa                	mv	s9,a0
    80003e40:	dd51                	beqz	a0,80003ddc <namex+0x92>
    iunlockput(ip);
    80003e42:	854e                	mv	a0,s3
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	bda080e7          	jalr	-1062(ra) # 80003a1e <iunlockput>
    ip = next;
    80003e4c:	89e6                	mv	s3,s9
  while(*path == '/')
    80003e4e:	0004c783          	lbu	a5,0(s1)
    80003e52:	05279763          	bne	a5,s2,80003ea0 <namex+0x156>
    path++;
    80003e56:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e58:	0004c783          	lbu	a5,0(s1)
    80003e5c:	ff278de3          	beq	a5,s2,80003e56 <namex+0x10c>
  if(*path == 0)
    80003e60:	c79d                	beqz	a5,80003e8e <namex+0x144>
    path++;
    80003e62:	85a6                	mv	a1,s1
  len = path - s;
    80003e64:	8cda                	mv	s9,s6
    80003e66:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003e68:	01278963          	beq	a5,s2,80003e7a <namex+0x130>
    80003e6c:	dfbd                	beqz	a5,80003dea <namex+0xa0>
    path++;
    80003e6e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e70:	0004c783          	lbu	a5,0(s1)
    80003e74:	ff279ce3          	bne	a5,s2,80003e6c <namex+0x122>
    80003e78:	bf8d                	j	80003dea <namex+0xa0>
    memmove(name, s, len);
    80003e7a:	2601                	sext.w	a2,a2
    80003e7c:	8552                	mv	a0,s4
    80003e7e:	ffffd097          	auipc	ra,0xffffd
    80003e82:	efc080e7          	jalr	-260(ra) # 80000d7a <memmove>
    name[len] = 0;
    80003e86:	9cd2                	add	s9,s9,s4
    80003e88:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e8c:	bf9d                	j	80003e02 <namex+0xb8>
  if(nameiparent){
    80003e8e:	f20a83e3          	beqz	s5,80003db4 <namex+0x6a>
    iput(ip);
    80003e92:	854e                	mv	a0,s3
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	ae2080e7          	jalr	-1310(ra) # 80003976 <iput>
    return 0;
    80003e9c:	4981                	li	s3,0
    80003e9e:	bf19                	j	80003db4 <namex+0x6a>
  if(*path == 0)
    80003ea0:	d7fd                	beqz	a5,80003e8e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ea2:	0004c783          	lbu	a5,0(s1)
    80003ea6:	85a6                	mv	a1,s1
    80003ea8:	b7d1                	j	80003e6c <namex+0x122>

0000000080003eaa <dirlink>:
{
    80003eaa:	7139                	addi	sp,sp,-64
    80003eac:	fc06                	sd	ra,56(sp)
    80003eae:	f822                	sd	s0,48(sp)
    80003eb0:	f426                	sd	s1,40(sp)
    80003eb2:	f04a                	sd	s2,32(sp)
    80003eb4:	ec4e                	sd	s3,24(sp)
    80003eb6:	e852                	sd	s4,16(sp)
    80003eb8:	0080                	addi	s0,sp,64
    80003eba:	892a                	mv	s2,a0
    80003ebc:	8a2e                	mv	s4,a1
    80003ebe:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ec0:	4601                	li	a2,0
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	dd8080e7          	jalr	-552(ra) # 80003c9a <dirlookup>
    80003eca:	e93d                	bnez	a0,80003f40 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ecc:	04c92483          	lw	s1,76(s2)
    80003ed0:	c49d                	beqz	s1,80003efe <dirlink+0x54>
    80003ed2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ed4:	4741                	li	a4,16
    80003ed6:	86a6                	mv	a3,s1
    80003ed8:	fc040613          	addi	a2,s0,-64
    80003edc:	4581                	li	a1,0
    80003ede:	854a                	mv	a0,s2
    80003ee0:	00000097          	auipc	ra,0x0
    80003ee4:	b90080e7          	jalr	-1136(ra) # 80003a70 <readi>
    80003ee8:	47c1                	li	a5,16
    80003eea:	06f51163          	bne	a0,a5,80003f4c <dirlink+0xa2>
    if(de.inum == 0)
    80003eee:	fc045783          	lhu	a5,-64(s0)
    80003ef2:	c791                	beqz	a5,80003efe <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef4:	24c1                	addiw	s1,s1,16
    80003ef6:	04c92783          	lw	a5,76(s2)
    80003efa:	fcf4ede3          	bltu	s1,a5,80003ed4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003efe:	4639                	li	a2,14
    80003f00:	85d2                	mv	a1,s4
    80003f02:	fc240513          	addi	a0,s0,-62
    80003f06:	ffffd097          	auipc	ra,0xffffd
    80003f0a:	f2c080e7          	jalr	-212(ra) # 80000e32 <strncpy>
  de.inum = inum;
    80003f0e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f12:	4741                	li	a4,16
    80003f14:	86a6                	mv	a3,s1
    80003f16:	fc040613          	addi	a2,s0,-64
    80003f1a:	4581                	li	a1,0
    80003f1c:	854a                	mv	a0,s2
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	c48080e7          	jalr	-952(ra) # 80003b66 <writei>
    80003f26:	872a                	mv	a4,a0
    80003f28:	47c1                	li	a5,16
  return 0;
    80003f2a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f2c:	02f71863          	bne	a4,a5,80003f5c <dirlink+0xb2>
}
    80003f30:	70e2                	ld	ra,56(sp)
    80003f32:	7442                	ld	s0,48(sp)
    80003f34:	74a2                	ld	s1,40(sp)
    80003f36:	7902                	ld	s2,32(sp)
    80003f38:	69e2                	ld	s3,24(sp)
    80003f3a:	6a42                	ld	s4,16(sp)
    80003f3c:	6121                	addi	sp,sp,64
    80003f3e:	8082                	ret
    iput(ip);
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	a36080e7          	jalr	-1482(ra) # 80003976 <iput>
    return -1;
    80003f48:	557d                	li	a0,-1
    80003f4a:	b7dd                	j	80003f30 <dirlink+0x86>
      panic("dirlink read");
    80003f4c:	00004517          	auipc	a0,0x4
    80003f50:	7d450513          	addi	a0,a0,2004 # 80008720 <syscalls+0x1d8>
    80003f54:	ffffc097          	auipc	ra,0xffffc
    80003f58:	5ee080e7          	jalr	1518(ra) # 80000542 <panic>
    panic("dirlink");
    80003f5c:	00005517          	auipc	a0,0x5
    80003f60:	8dc50513          	addi	a0,a0,-1828 # 80008838 <syscalls+0x2f0>
    80003f64:	ffffc097          	auipc	ra,0xffffc
    80003f68:	5de080e7          	jalr	1502(ra) # 80000542 <panic>

0000000080003f6c <namei>:

struct inode*
namei(char *path)
{
    80003f6c:	1101                	addi	sp,sp,-32
    80003f6e:	ec06                	sd	ra,24(sp)
    80003f70:	e822                	sd	s0,16(sp)
    80003f72:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f74:	fe040613          	addi	a2,s0,-32
    80003f78:	4581                	li	a1,0
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	dd0080e7          	jalr	-560(ra) # 80003d4a <namex>
}
    80003f82:	60e2                	ld	ra,24(sp)
    80003f84:	6442                	ld	s0,16(sp)
    80003f86:	6105                	addi	sp,sp,32
    80003f88:	8082                	ret

0000000080003f8a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f8a:	1141                	addi	sp,sp,-16
    80003f8c:	e406                	sd	ra,8(sp)
    80003f8e:	e022                	sd	s0,0(sp)
    80003f90:	0800                	addi	s0,sp,16
    80003f92:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f94:	4585                	li	a1,1
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	db4080e7          	jalr	-588(ra) # 80003d4a <namex>
}
    80003f9e:	60a2                	ld	ra,8(sp)
    80003fa0:	6402                	ld	s0,0(sp)
    80003fa2:	0141                	addi	sp,sp,16
    80003fa4:	8082                	ret

0000000080003fa6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fa6:	1101                	addi	sp,sp,-32
    80003fa8:	ec06                	sd	ra,24(sp)
    80003faa:	e822                	sd	s0,16(sp)
    80003fac:	e426                	sd	s1,8(sp)
    80003fae:	e04a                	sd	s2,0(sp)
    80003fb0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fb2:	0001e917          	auipc	s2,0x1e
    80003fb6:	b5690913          	addi	s2,s2,-1194 # 80021b08 <log>
    80003fba:	01892583          	lw	a1,24(s2)
    80003fbe:	02892503          	lw	a0,40(s2)
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	ff8080e7          	jalr	-8(ra) # 80002fba <bread>
    80003fca:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fcc:	02c92683          	lw	a3,44(s2)
    80003fd0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fd2:	02d05763          	blez	a3,80004000 <write_head+0x5a>
    80003fd6:	0001e797          	auipc	a5,0x1e
    80003fda:	b6278793          	addi	a5,a5,-1182 # 80021b38 <log+0x30>
    80003fde:	05c50713          	addi	a4,a0,92
    80003fe2:	36fd                	addiw	a3,a3,-1
    80003fe4:	1682                	slli	a3,a3,0x20
    80003fe6:	9281                	srli	a3,a3,0x20
    80003fe8:	068a                	slli	a3,a3,0x2
    80003fea:	0001e617          	auipc	a2,0x1e
    80003fee:	b5260613          	addi	a2,a2,-1198 # 80021b3c <log+0x34>
    80003ff2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ff4:	4390                	lw	a2,0(a5)
    80003ff6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ff8:	0791                	addi	a5,a5,4
    80003ffa:	0711                	addi	a4,a4,4
    80003ffc:	fed79ce3          	bne	a5,a3,80003ff4 <write_head+0x4e>
  }
  bwrite(buf);
    80004000:	8526                	mv	a0,s1
    80004002:	fffff097          	auipc	ra,0xfffff
    80004006:	0aa080e7          	jalr	170(ra) # 800030ac <bwrite>
  brelse(buf);
    8000400a:	8526                	mv	a0,s1
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	0de080e7          	jalr	222(ra) # 800030ea <brelse>
}
    80004014:	60e2                	ld	ra,24(sp)
    80004016:	6442                	ld	s0,16(sp)
    80004018:	64a2                	ld	s1,8(sp)
    8000401a:	6902                	ld	s2,0(sp)
    8000401c:	6105                	addi	sp,sp,32
    8000401e:	8082                	ret

0000000080004020 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004020:	0001e797          	auipc	a5,0x1e
    80004024:	b147a783          	lw	a5,-1260(a5) # 80021b34 <log+0x2c>
    80004028:	0af05663          	blez	a5,800040d4 <install_trans+0xb4>
{
    8000402c:	7139                	addi	sp,sp,-64
    8000402e:	fc06                	sd	ra,56(sp)
    80004030:	f822                	sd	s0,48(sp)
    80004032:	f426                	sd	s1,40(sp)
    80004034:	f04a                	sd	s2,32(sp)
    80004036:	ec4e                	sd	s3,24(sp)
    80004038:	e852                	sd	s4,16(sp)
    8000403a:	e456                	sd	s5,8(sp)
    8000403c:	0080                	addi	s0,sp,64
    8000403e:	0001ea97          	auipc	s5,0x1e
    80004042:	afaa8a93          	addi	s5,s5,-1286 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004046:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004048:	0001e997          	auipc	s3,0x1e
    8000404c:	ac098993          	addi	s3,s3,-1344 # 80021b08 <log>
    80004050:	0189a583          	lw	a1,24(s3)
    80004054:	014585bb          	addw	a1,a1,s4
    80004058:	2585                	addiw	a1,a1,1
    8000405a:	0289a503          	lw	a0,40(s3)
    8000405e:	fffff097          	auipc	ra,0xfffff
    80004062:	f5c080e7          	jalr	-164(ra) # 80002fba <bread>
    80004066:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004068:	000aa583          	lw	a1,0(s5)
    8000406c:	0289a503          	lw	a0,40(s3)
    80004070:	fffff097          	auipc	ra,0xfffff
    80004074:	f4a080e7          	jalr	-182(ra) # 80002fba <bread>
    80004078:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000407a:	40000613          	li	a2,1024
    8000407e:	05890593          	addi	a1,s2,88
    80004082:	05850513          	addi	a0,a0,88
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	cf4080e7          	jalr	-780(ra) # 80000d7a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000408e:	8526                	mv	a0,s1
    80004090:	fffff097          	auipc	ra,0xfffff
    80004094:	01c080e7          	jalr	28(ra) # 800030ac <bwrite>
    bunpin(dbuf);
    80004098:	8526                	mv	a0,s1
    8000409a:	fffff097          	auipc	ra,0xfffff
    8000409e:	12a080e7          	jalr	298(ra) # 800031c4 <bunpin>
    brelse(lbuf);
    800040a2:	854a                	mv	a0,s2
    800040a4:	fffff097          	auipc	ra,0xfffff
    800040a8:	046080e7          	jalr	70(ra) # 800030ea <brelse>
    brelse(dbuf);
    800040ac:	8526                	mv	a0,s1
    800040ae:	fffff097          	auipc	ra,0xfffff
    800040b2:	03c080e7          	jalr	60(ra) # 800030ea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040b6:	2a05                	addiw	s4,s4,1
    800040b8:	0a91                	addi	s5,s5,4
    800040ba:	02c9a783          	lw	a5,44(s3)
    800040be:	f8fa49e3          	blt	s4,a5,80004050 <install_trans+0x30>
}
    800040c2:	70e2                	ld	ra,56(sp)
    800040c4:	7442                	ld	s0,48(sp)
    800040c6:	74a2                	ld	s1,40(sp)
    800040c8:	7902                	ld	s2,32(sp)
    800040ca:	69e2                	ld	s3,24(sp)
    800040cc:	6a42                	ld	s4,16(sp)
    800040ce:	6aa2                	ld	s5,8(sp)
    800040d0:	6121                	addi	sp,sp,64
    800040d2:	8082                	ret
    800040d4:	8082                	ret

00000000800040d6 <initlog>:
{
    800040d6:	7179                	addi	sp,sp,-48
    800040d8:	f406                	sd	ra,40(sp)
    800040da:	f022                	sd	s0,32(sp)
    800040dc:	ec26                	sd	s1,24(sp)
    800040de:	e84a                	sd	s2,16(sp)
    800040e0:	e44e                	sd	s3,8(sp)
    800040e2:	1800                	addi	s0,sp,48
    800040e4:	892a                	mv	s2,a0
    800040e6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040e8:	0001e497          	auipc	s1,0x1e
    800040ec:	a2048493          	addi	s1,s1,-1504 # 80021b08 <log>
    800040f0:	00004597          	auipc	a1,0x4
    800040f4:	64058593          	addi	a1,a1,1600 # 80008730 <syscalls+0x1e8>
    800040f8:	8526                	mv	a0,s1
    800040fa:	ffffd097          	auipc	ra,0xffffd
    800040fe:	a98080e7          	jalr	-1384(ra) # 80000b92 <initlock>
  log.start = sb->logstart;
    80004102:	0149a583          	lw	a1,20(s3)
    80004106:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004108:	0109a783          	lw	a5,16(s3)
    8000410c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000410e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004112:	854a                	mv	a0,s2
    80004114:	fffff097          	auipc	ra,0xfffff
    80004118:	ea6080e7          	jalr	-346(ra) # 80002fba <bread>
  log.lh.n = lh->n;
    8000411c:	4d34                	lw	a3,88(a0)
    8000411e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004120:	02d05563          	blez	a3,8000414a <initlog+0x74>
    80004124:	05c50793          	addi	a5,a0,92
    80004128:	0001e717          	auipc	a4,0x1e
    8000412c:	a1070713          	addi	a4,a4,-1520 # 80021b38 <log+0x30>
    80004130:	36fd                	addiw	a3,a3,-1
    80004132:	1682                	slli	a3,a3,0x20
    80004134:	9281                	srli	a3,a3,0x20
    80004136:	068a                	slli	a3,a3,0x2
    80004138:	06050613          	addi	a2,a0,96
    8000413c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000413e:	4390                	lw	a2,0(a5)
    80004140:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004142:	0791                	addi	a5,a5,4
    80004144:	0711                	addi	a4,a4,4
    80004146:	fed79ce3          	bne	a5,a3,8000413e <initlog+0x68>
  brelse(buf);
    8000414a:	fffff097          	auipc	ra,0xfffff
    8000414e:	fa0080e7          	jalr	-96(ra) # 800030ea <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004152:	00000097          	auipc	ra,0x0
    80004156:	ece080e7          	jalr	-306(ra) # 80004020 <install_trans>
  log.lh.n = 0;
    8000415a:	0001e797          	auipc	a5,0x1e
    8000415e:	9c07ad23          	sw	zero,-1574(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004162:	00000097          	auipc	ra,0x0
    80004166:	e44080e7          	jalr	-444(ra) # 80003fa6 <write_head>
}
    8000416a:	70a2                	ld	ra,40(sp)
    8000416c:	7402                	ld	s0,32(sp)
    8000416e:	64e2                	ld	s1,24(sp)
    80004170:	6942                	ld	s2,16(sp)
    80004172:	69a2                	ld	s3,8(sp)
    80004174:	6145                	addi	sp,sp,48
    80004176:	8082                	ret

0000000080004178 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004178:	1101                	addi	sp,sp,-32
    8000417a:	ec06                	sd	ra,24(sp)
    8000417c:	e822                	sd	s0,16(sp)
    8000417e:	e426                	sd	s1,8(sp)
    80004180:	e04a                	sd	s2,0(sp)
    80004182:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004184:	0001e517          	auipc	a0,0x1e
    80004188:	98450513          	addi	a0,a0,-1660 # 80021b08 <log>
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	a96080e7          	jalr	-1386(ra) # 80000c22 <acquire>
  while(1){
    if(log.committing){
    80004194:	0001e497          	auipc	s1,0x1e
    80004198:	97448493          	addi	s1,s1,-1676 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000419c:	4979                	li	s2,30
    8000419e:	a039                	j	800041ac <begin_op+0x34>
      sleep(&log, &log.lock);
    800041a0:	85a6                	mv	a1,s1
    800041a2:	8526                	mv	a0,s1
    800041a4:	ffffe097          	auipc	ra,0xffffe
    800041a8:	062080e7          	jalr	98(ra) # 80002206 <sleep>
    if(log.committing){
    800041ac:	50dc                	lw	a5,36(s1)
    800041ae:	fbed                	bnez	a5,800041a0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041b0:	509c                	lw	a5,32(s1)
    800041b2:	0017871b          	addiw	a4,a5,1
    800041b6:	0007069b          	sext.w	a3,a4
    800041ba:	0027179b          	slliw	a5,a4,0x2
    800041be:	9fb9                	addw	a5,a5,a4
    800041c0:	0017979b          	slliw	a5,a5,0x1
    800041c4:	54d8                	lw	a4,44(s1)
    800041c6:	9fb9                	addw	a5,a5,a4
    800041c8:	00f95963          	bge	s2,a5,800041da <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041cc:	85a6                	mv	a1,s1
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffe097          	auipc	ra,0xffffe
    800041d4:	036080e7          	jalr	54(ra) # 80002206 <sleep>
    800041d8:	bfd1                	j	800041ac <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041da:	0001e517          	auipc	a0,0x1e
    800041de:	92e50513          	addi	a0,a0,-1746 # 80021b08 <log>
    800041e2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	af2080e7          	jalr	-1294(ra) # 80000cd6 <release>
      break;
    }
  }
}
    800041ec:	60e2                	ld	ra,24(sp)
    800041ee:	6442                	ld	s0,16(sp)
    800041f0:	64a2                	ld	s1,8(sp)
    800041f2:	6902                	ld	s2,0(sp)
    800041f4:	6105                	addi	sp,sp,32
    800041f6:	8082                	ret

00000000800041f8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041f8:	7139                	addi	sp,sp,-64
    800041fa:	fc06                	sd	ra,56(sp)
    800041fc:	f822                	sd	s0,48(sp)
    800041fe:	f426                	sd	s1,40(sp)
    80004200:	f04a                	sd	s2,32(sp)
    80004202:	ec4e                	sd	s3,24(sp)
    80004204:	e852                	sd	s4,16(sp)
    80004206:	e456                	sd	s5,8(sp)
    80004208:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000420a:	0001e497          	auipc	s1,0x1e
    8000420e:	8fe48493          	addi	s1,s1,-1794 # 80021b08 <log>
    80004212:	8526                	mv	a0,s1
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	a0e080e7          	jalr	-1522(ra) # 80000c22 <acquire>
  log.outstanding -= 1;
    8000421c:	509c                	lw	a5,32(s1)
    8000421e:	37fd                	addiw	a5,a5,-1
    80004220:	0007891b          	sext.w	s2,a5
    80004224:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004226:	50dc                	lw	a5,36(s1)
    80004228:	e7b9                	bnez	a5,80004276 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000422a:	04091e63          	bnez	s2,80004286 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000422e:	0001e497          	auipc	s1,0x1e
    80004232:	8da48493          	addi	s1,s1,-1830 # 80021b08 <log>
    80004236:	4785                	li	a5,1
    80004238:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000423a:	8526                	mv	a0,s1
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	a9a080e7          	jalr	-1382(ra) # 80000cd6 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004244:	54dc                	lw	a5,44(s1)
    80004246:	06f04763          	bgtz	a5,800042b4 <end_op+0xbc>
    acquire(&log.lock);
    8000424a:	0001e497          	auipc	s1,0x1e
    8000424e:	8be48493          	addi	s1,s1,-1858 # 80021b08 <log>
    80004252:	8526                	mv	a0,s1
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	9ce080e7          	jalr	-1586(ra) # 80000c22 <acquire>
    log.committing = 0;
    8000425c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004260:	8526                	mv	a0,s1
    80004262:	ffffe097          	auipc	ra,0xffffe
    80004266:	124080e7          	jalr	292(ra) # 80002386 <wakeup>
    release(&log.lock);
    8000426a:	8526                	mv	a0,s1
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	a6a080e7          	jalr	-1430(ra) # 80000cd6 <release>
}
    80004274:	a03d                	j	800042a2 <end_op+0xaa>
    panic("log.committing");
    80004276:	00004517          	auipc	a0,0x4
    8000427a:	4c250513          	addi	a0,a0,1218 # 80008738 <syscalls+0x1f0>
    8000427e:	ffffc097          	auipc	ra,0xffffc
    80004282:	2c4080e7          	jalr	708(ra) # 80000542 <panic>
    wakeup(&log);
    80004286:	0001e497          	auipc	s1,0x1e
    8000428a:	88248493          	addi	s1,s1,-1918 # 80021b08 <log>
    8000428e:	8526                	mv	a0,s1
    80004290:	ffffe097          	auipc	ra,0xffffe
    80004294:	0f6080e7          	jalr	246(ra) # 80002386 <wakeup>
  release(&log.lock);
    80004298:	8526                	mv	a0,s1
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	a3c080e7          	jalr	-1476(ra) # 80000cd6 <release>
}
    800042a2:	70e2                	ld	ra,56(sp)
    800042a4:	7442                	ld	s0,48(sp)
    800042a6:	74a2                	ld	s1,40(sp)
    800042a8:	7902                	ld	s2,32(sp)
    800042aa:	69e2                	ld	s3,24(sp)
    800042ac:	6a42                	ld	s4,16(sp)
    800042ae:	6aa2                	ld	s5,8(sp)
    800042b0:	6121                	addi	sp,sp,64
    800042b2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b4:	0001ea97          	auipc	s5,0x1e
    800042b8:	884a8a93          	addi	s5,s5,-1916 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042bc:	0001ea17          	auipc	s4,0x1e
    800042c0:	84ca0a13          	addi	s4,s4,-1972 # 80021b08 <log>
    800042c4:	018a2583          	lw	a1,24(s4)
    800042c8:	012585bb          	addw	a1,a1,s2
    800042cc:	2585                	addiw	a1,a1,1
    800042ce:	028a2503          	lw	a0,40(s4)
    800042d2:	fffff097          	auipc	ra,0xfffff
    800042d6:	ce8080e7          	jalr	-792(ra) # 80002fba <bread>
    800042da:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042dc:	000aa583          	lw	a1,0(s5)
    800042e0:	028a2503          	lw	a0,40(s4)
    800042e4:	fffff097          	auipc	ra,0xfffff
    800042e8:	cd6080e7          	jalr	-810(ra) # 80002fba <bread>
    800042ec:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042ee:	40000613          	li	a2,1024
    800042f2:	05850593          	addi	a1,a0,88
    800042f6:	05848513          	addi	a0,s1,88
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	a80080e7          	jalr	-1408(ra) # 80000d7a <memmove>
    bwrite(to);  // write the log
    80004302:	8526                	mv	a0,s1
    80004304:	fffff097          	auipc	ra,0xfffff
    80004308:	da8080e7          	jalr	-600(ra) # 800030ac <bwrite>
    brelse(from);
    8000430c:	854e                	mv	a0,s3
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	ddc080e7          	jalr	-548(ra) # 800030ea <brelse>
    brelse(to);
    80004316:	8526                	mv	a0,s1
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	dd2080e7          	jalr	-558(ra) # 800030ea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004320:	2905                	addiw	s2,s2,1
    80004322:	0a91                	addi	s5,s5,4
    80004324:	02ca2783          	lw	a5,44(s4)
    80004328:	f8f94ee3          	blt	s2,a5,800042c4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	c7a080e7          	jalr	-902(ra) # 80003fa6 <write_head>
    install_trans(); // Now install writes to home locations
    80004334:	00000097          	auipc	ra,0x0
    80004338:	cec080e7          	jalr	-788(ra) # 80004020 <install_trans>
    log.lh.n = 0;
    8000433c:	0001d797          	auipc	a5,0x1d
    80004340:	7e07ac23          	sw	zero,2040(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004344:	00000097          	auipc	ra,0x0
    80004348:	c62080e7          	jalr	-926(ra) # 80003fa6 <write_head>
    8000434c:	bdfd                	j	8000424a <end_op+0x52>

000000008000434e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000434e:	1101                	addi	sp,sp,-32
    80004350:	ec06                	sd	ra,24(sp)
    80004352:	e822                	sd	s0,16(sp)
    80004354:	e426                	sd	s1,8(sp)
    80004356:	e04a                	sd	s2,0(sp)
    80004358:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000435a:	0001d717          	auipc	a4,0x1d
    8000435e:	7da72703          	lw	a4,2010(a4) # 80021b34 <log+0x2c>
    80004362:	47f5                	li	a5,29
    80004364:	08e7c063          	blt	a5,a4,800043e4 <log_write+0x96>
    80004368:	84aa                	mv	s1,a0
    8000436a:	0001d797          	auipc	a5,0x1d
    8000436e:	7ba7a783          	lw	a5,1978(a5) # 80021b24 <log+0x1c>
    80004372:	37fd                	addiw	a5,a5,-1
    80004374:	06f75863          	bge	a4,a5,800043e4 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004378:	0001d797          	auipc	a5,0x1d
    8000437c:	7b07a783          	lw	a5,1968(a5) # 80021b28 <log+0x20>
    80004380:	06f05a63          	blez	a5,800043f4 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004384:	0001d917          	auipc	s2,0x1d
    80004388:	78490913          	addi	s2,s2,1924 # 80021b08 <log>
    8000438c:	854a                	mv	a0,s2
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	894080e7          	jalr	-1900(ra) # 80000c22 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004396:	02c92603          	lw	a2,44(s2)
    8000439a:	06c05563          	blez	a2,80004404 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000439e:	44cc                	lw	a1,12(s1)
    800043a0:	0001d717          	auipc	a4,0x1d
    800043a4:	79870713          	addi	a4,a4,1944 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043a8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043aa:	4314                	lw	a3,0(a4)
    800043ac:	04b68d63          	beq	a3,a1,80004406 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800043b0:	2785                	addiw	a5,a5,1
    800043b2:	0711                	addi	a4,a4,4
    800043b4:	fec79be3          	bne	a5,a2,800043aa <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043b8:	0621                	addi	a2,a2,8
    800043ba:	060a                	slli	a2,a2,0x2
    800043bc:	0001d797          	auipc	a5,0x1d
    800043c0:	74c78793          	addi	a5,a5,1868 # 80021b08 <log>
    800043c4:	963e                	add	a2,a2,a5
    800043c6:	44dc                	lw	a5,12(s1)
    800043c8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043ca:	8526                	mv	a0,s1
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	dbc080e7          	jalr	-580(ra) # 80003188 <bpin>
    log.lh.n++;
    800043d4:	0001d717          	auipc	a4,0x1d
    800043d8:	73470713          	addi	a4,a4,1844 # 80021b08 <log>
    800043dc:	575c                	lw	a5,44(a4)
    800043de:	2785                	addiw	a5,a5,1
    800043e0:	d75c                	sw	a5,44(a4)
    800043e2:	a83d                	j	80004420 <log_write+0xd2>
    panic("too big a transaction");
    800043e4:	00004517          	auipc	a0,0x4
    800043e8:	36450513          	addi	a0,a0,868 # 80008748 <syscalls+0x200>
    800043ec:	ffffc097          	auipc	ra,0xffffc
    800043f0:	156080e7          	jalr	342(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    800043f4:	00004517          	auipc	a0,0x4
    800043f8:	36c50513          	addi	a0,a0,876 # 80008760 <syscalls+0x218>
    800043fc:	ffffc097          	auipc	ra,0xffffc
    80004400:	146080e7          	jalr	326(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004404:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004406:	00878713          	addi	a4,a5,8
    8000440a:	00271693          	slli	a3,a4,0x2
    8000440e:	0001d717          	auipc	a4,0x1d
    80004412:	6fa70713          	addi	a4,a4,1786 # 80021b08 <log>
    80004416:	9736                	add	a4,a4,a3
    80004418:	44d4                	lw	a3,12(s1)
    8000441a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000441c:	faf607e3          	beq	a2,a5,800043ca <log_write+0x7c>
  }
  release(&log.lock);
    80004420:	0001d517          	auipc	a0,0x1d
    80004424:	6e850513          	addi	a0,a0,1768 # 80021b08 <log>
    80004428:	ffffd097          	auipc	ra,0xffffd
    8000442c:	8ae080e7          	jalr	-1874(ra) # 80000cd6 <release>
}
    80004430:	60e2                	ld	ra,24(sp)
    80004432:	6442                	ld	s0,16(sp)
    80004434:	64a2                	ld	s1,8(sp)
    80004436:	6902                	ld	s2,0(sp)
    80004438:	6105                	addi	sp,sp,32
    8000443a:	8082                	ret

000000008000443c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000443c:	1101                	addi	sp,sp,-32
    8000443e:	ec06                	sd	ra,24(sp)
    80004440:	e822                	sd	s0,16(sp)
    80004442:	e426                	sd	s1,8(sp)
    80004444:	e04a                	sd	s2,0(sp)
    80004446:	1000                	addi	s0,sp,32
    80004448:	84aa                	mv	s1,a0
    8000444a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000444c:	00004597          	auipc	a1,0x4
    80004450:	33458593          	addi	a1,a1,820 # 80008780 <syscalls+0x238>
    80004454:	0521                	addi	a0,a0,8
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	73c080e7          	jalr	1852(ra) # 80000b92 <initlock>
  lk->name = name;
    8000445e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004462:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004466:	0204a423          	sw	zero,40(s1)
}
    8000446a:	60e2                	ld	ra,24(sp)
    8000446c:	6442                	ld	s0,16(sp)
    8000446e:	64a2                	ld	s1,8(sp)
    80004470:	6902                	ld	s2,0(sp)
    80004472:	6105                	addi	sp,sp,32
    80004474:	8082                	ret

0000000080004476 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004476:	1101                	addi	sp,sp,-32
    80004478:	ec06                	sd	ra,24(sp)
    8000447a:	e822                	sd	s0,16(sp)
    8000447c:	e426                	sd	s1,8(sp)
    8000447e:	e04a                	sd	s2,0(sp)
    80004480:	1000                	addi	s0,sp,32
    80004482:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004484:	00850913          	addi	s2,a0,8
    80004488:	854a                	mv	a0,s2
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	798080e7          	jalr	1944(ra) # 80000c22 <acquire>
  while (lk->locked) {
    80004492:	409c                	lw	a5,0(s1)
    80004494:	cb89                	beqz	a5,800044a6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004496:	85ca                	mv	a1,s2
    80004498:	8526                	mv	a0,s1
    8000449a:	ffffe097          	auipc	ra,0xffffe
    8000449e:	d6c080e7          	jalr	-660(ra) # 80002206 <sleep>
  while (lk->locked) {
    800044a2:	409c                	lw	a5,0(s1)
    800044a4:	fbed                	bnez	a5,80004496 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044a6:	4785                	li	a5,1
    800044a8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044aa:	ffffd097          	auipc	ra,0xffffd
    800044ae:	544080e7          	jalr	1348(ra) # 800019ee <myproc>
    800044b2:	5d1c                	lw	a5,56(a0)
    800044b4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044b6:	854a                	mv	a0,s2
    800044b8:	ffffd097          	auipc	ra,0xffffd
    800044bc:	81e080e7          	jalr	-2018(ra) # 80000cd6 <release>
}
    800044c0:	60e2                	ld	ra,24(sp)
    800044c2:	6442                	ld	s0,16(sp)
    800044c4:	64a2                	ld	s1,8(sp)
    800044c6:	6902                	ld	s2,0(sp)
    800044c8:	6105                	addi	sp,sp,32
    800044ca:	8082                	ret

00000000800044cc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044cc:	1101                	addi	sp,sp,-32
    800044ce:	ec06                	sd	ra,24(sp)
    800044d0:	e822                	sd	s0,16(sp)
    800044d2:	e426                	sd	s1,8(sp)
    800044d4:	e04a                	sd	s2,0(sp)
    800044d6:	1000                	addi	s0,sp,32
    800044d8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044da:	00850913          	addi	s2,a0,8
    800044de:	854a                	mv	a0,s2
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	742080e7          	jalr	1858(ra) # 80000c22 <acquire>
  lk->locked = 0;
    800044e8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044ec:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044f0:	8526                	mv	a0,s1
    800044f2:	ffffe097          	auipc	ra,0xffffe
    800044f6:	e94080e7          	jalr	-364(ra) # 80002386 <wakeup>
  release(&lk->lk);
    800044fa:	854a                	mv	a0,s2
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	7da080e7          	jalr	2010(ra) # 80000cd6 <release>
}
    80004504:	60e2                	ld	ra,24(sp)
    80004506:	6442                	ld	s0,16(sp)
    80004508:	64a2                	ld	s1,8(sp)
    8000450a:	6902                	ld	s2,0(sp)
    8000450c:	6105                	addi	sp,sp,32
    8000450e:	8082                	ret

0000000080004510 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004510:	7179                	addi	sp,sp,-48
    80004512:	f406                	sd	ra,40(sp)
    80004514:	f022                	sd	s0,32(sp)
    80004516:	ec26                	sd	s1,24(sp)
    80004518:	e84a                	sd	s2,16(sp)
    8000451a:	e44e                	sd	s3,8(sp)
    8000451c:	1800                	addi	s0,sp,48
    8000451e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004520:	00850913          	addi	s2,a0,8
    80004524:	854a                	mv	a0,s2
    80004526:	ffffc097          	auipc	ra,0xffffc
    8000452a:	6fc080e7          	jalr	1788(ra) # 80000c22 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000452e:	409c                	lw	a5,0(s1)
    80004530:	ef99                	bnez	a5,8000454e <holdingsleep+0x3e>
    80004532:	4481                	li	s1,0
  release(&lk->lk);
    80004534:	854a                	mv	a0,s2
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	7a0080e7          	jalr	1952(ra) # 80000cd6 <release>
  return r;
}
    8000453e:	8526                	mv	a0,s1
    80004540:	70a2                	ld	ra,40(sp)
    80004542:	7402                	ld	s0,32(sp)
    80004544:	64e2                	ld	s1,24(sp)
    80004546:	6942                	ld	s2,16(sp)
    80004548:	69a2                	ld	s3,8(sp)
    8000454a:	6145                	addi	sp,sp,48
    8000454c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000454e:	0284a983          	lw	s3,40(s1)
    80004552:	ffffd097          	auipc	ra,0xffffd
    80004556:	49c080e7          	jalr	1180(ra) # 800019ee <myproc>
    8000455a:	5d04                	lw	s1,56(a0)
    8000455c:	413484b3          	sub	s1,s1,s3
    80004560:	0014b493          	seqz	s1,s1
    80004564:	bfc1                	j	80004534 <holdingsleep+0x24>

0000000080004566 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004566:	1141                	addi	sp,sp,-16
    80004568:	e406                	sd	ra,8(sp)
    8000456a:	e022                	sd	s0,0(sp)
    8000456c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000456e:	00004597          	auipc	a1,0x4
    80004572:	22258593          	addi	a1,a1,546 # 80008790 <syscalls+0x248>
    80004576:	0001d517          	auipc	a0,0x1d
    8000457a:	6da50513          	addi	a0,a0,1754 # 80021c50 <ftable>
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	614080e7          	jalr	1556(ra) # 80000b92 <initlock>
}
    80004586:	60a2                	ld	ra,8(sp)
    80004588:	6402                	ld	s0,0(sp)
    8000458a:	0141                	addi	sp,sp,16
    8000458c:	8082                	ret

000000008000458e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000458e:	1101                	addi	sp,sp,-32
    80004590:	ec06                	sd	ra,24(sp)
    80004592:	e822                	sd	s0,16(sp)
    80004594:	e426                	sd	s1,8(sp)
    80004596:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004598:	0001d517          	auipc	a0,0x1d
    8000459c:	6b850513          	addi	a0,a0,1720 # 80021c50 <ftable>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	682080e7          	jalr	1666(ra) # 80000c22 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a8:	0001d497          	auipc	s1,0x1d
    800045ac:	6c048493          	addi	s1,s1,1728 # 80021c68 <ftable+0x18>
    800045b0:	0001e717          	auipc	a4,0x1e
    800045b4:	65870713          	addi	a4,a4,1624 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    800045b8:	40dc                	lw	a5,4(s1)
    800045ba:	cf99                	beqz	a5,800045d8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045bc:	02848493          	addi	s1,s1,40
    800045c0:	fee49ce3          	bne	s1,a4,800045b8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045c4:	0001d517          	auipc	a0,0x1d
    800045c8:	68c50513          	addi	a0,a0,1676 # 80021c50 <ftable>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	70a080e7          	jalr	1802(ra) # 80000cd6 <release>
  return 0;
    800045d4:	4481                	li	s1,0
    800045d6:	a819                	j	800045ec <filealloc+0x5e>
      f->ref = 1;
    800045d8:	4785                	li	a5,1
    800045da:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045dc:	0001d517          	auipc	a0,0x1d
    800045e0:	67450513          	addi	a0,a0,1652 # 80021c50 <ftable>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	6f2080e7          	jalr	1778(ra) # 80000cd6 <release>
}
    800045ec:	8526                	mv	a0,s1
    800045ee:	60e2                	ld	ra,24(sp)
    800045f0:	6442                	ld	s0,16(sp)
    800045f2:	64a2                	ld	s1,8(sp)
    800045f4:	6105                	addi	sp,sp,32
    800045f6:	8082                	ret

00000000800045f8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045f8:	1101                	addi	sp,sp,-32
    800045fa:	ec06                	sd	ra,24(sp)
    800045fc:	e822                	sd	s0,16(sp)
    800045fe:	e426                	sd	s1,8(sp)
    80004600:	1000                	addi	s0,sp,32
    80004602:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004604:	0001d517          	auipc	a0,0x1d
    80004608:	64c50513          	addi	a0,a0,1612 # 80021c50 <ftable>
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	616080e7          	jalr	1558(ra) # 80000c22 <acquire>
  if(f->ref < 1)
    80004614:	40dc                	lw	a5,4(s1)
    80004616:	02f05263          	blez	a5,8000463a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000461a:	2785                	addiw	a5,a5,1
    8000461c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000461e:	0001d517          	auipc	a0,0x1d
    80004622:	63250513          	addi	a0,a0,1586 # 80021c50 <ftable>
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	6b0080e7          	jalr	1712(ra) # 80000cd6 <release>
  return f;
}
    8000462e:	8526                	mv	a0,s1
    80004630:	60e2                	ld	ra,24(sp)
    80004632:	6442                	ld	s0,16(sp)
    80004634:	64a2                	ld	s1,8(sp)
    80004636:	6105                	addi	sp,sp,32
    80004638:	8082                	ret
    panic("filedup");
    8000463a:	00004517          	auipc	a0,0x4
    8000463e:	15e50513          	addi	a0,a0,350 # 80008798 <syscalls+0x250>
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	f00080e7          	jalr	-256(ra) # 80000542 <panic>

000000008000464a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000464a:	7139                	addi	sp,sp,-64
    8000464c:	fc06                	sd	ra,56(sp)
    8000464e:	f822                	sd	s0,48(sp)
    80004650:	f426                	sd	s1,40(sp)
    80004652:	f04a                	sd	s2,32(sp)
    80004654:	ec4e                	sd	s3,24(sp)
    80004656:	e852                	sd	s4,16(sp)
    80004658:	e456                	sd	s5,8(sp)
    8000465a:	0080                	addi	s0,sp,64
    8000465c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000465e:	0001d517          	auipc	a0,0x1d
    80004662:	5f250513          	addi	a0,a0,1522 # 80021c50 <ftable>
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	5bc080e7          	jalr	1468(ra) # 80000c22 <acquire>
  if(f->ref < 1)
    8000466e:	40dc                	lw	a5,4(s1)
    80004670:	06f05163          	blez	a5,800046d2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004674:	37fd                	addiw	a5,a5,-1
    80004676:	0007871b          	sext.w	a4,a5
    8000467a:	c0dc                	sw	a5,4(s1)
    8000467c:	06e04363          	bgtz	a4,800046e2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004680:	0004a903          	lw	s2,0(s1)
    80004684:	0094ca83          	lbu	s5,9(s1)
    80004688:	0104ba03          	ld	s4,16(s1)
    8000468c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004690:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004694:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004698:	0001d517          	auipc	a0,0x1d
    8000469c:	5b850513          	addi	a0,a0,1464 # 80021c50 <ftable>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	636080e7          	jalr	1590(ra) # 80000cd6 <release>

  if(ff.type == FD_PIPE){
    800046a8:	4785                	li	a5,1
    800046aa:	04f90d63          	beq	s2,a5,80004704 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046ae:	3979                	addiw	s2,s2,-2
    800046b0:	4785                	li	a5,1
    800046b2:	0527e063          	bltu	a5,s2,800046f2 <fileclose+0xa8>
    begin_op();
    800046b6:	00000097          	auipc	ra,0x0
    800046ba:	ac2080e7          	jalr	-1342(ra) # 80004178 <begin_op>
    iput(ff.ip);
    800046be:	854e                	mv	a0,s3
    800046c0:	fffff097          	auipc	ra,0xfffff
    800046c4:	2b6080e7          	jalr	694(ra) # 80003976 <iput>
    end_op();
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	b30080e7          	jalr	-1232(ra) # 800041f8 <end_op>
    800046d0:	a00d                	j	800046f2 <fileclose+0xa8>
    panic("fileclose");
    800046d2:	00004517          	auipc	a0,0x4
    800046d6:	0ce50513          	addi	a0,a0,206 # 800087a0 <syscalls+0x258>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	e68080e7          	jalr	-408(ra) # 80000542 <panic>
    release(&ftable.lock);
    800046e2:	0001d517          	auipc	a0,0x1d
    800046e6:	56e50513          	addi	a0,a0,1390 # 80021c50 <ftable>
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	5ec080e7          	jalr	1516(ra) # 80000cd6 <release>
  }
}
    800046f2:	70e2                	ld	ra,56(sp)
    800046f4:	7442                	ld	s0,48(sp)
    800046f6:	74a2                	ld	s1,40(sp)
    800046f8:	7902                	ld	s2,32(sp)
    800046fa:	69e2                	ld	s3,24(sp)
    800046fc:	6a42                	ld	s4,16(sp)
    800046fe:	6aa2                	ld	s5,8(sp)
    80004700:	6121                	addi	sp,sp,64
    80004702:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004704:	85d6                	mv	a1,s5
    80004706:	8552                	mv	a0,s4
    80004708:	00000097          	auipc	ra,0x0
    8000470c:	372080e7          	jalr	882(ra) # 80004a7a <pipeclose>
    80004710:	b7cd                	j	800046f2 <fileclose+0xa8>

0000000080004712 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004712:	715d                	addi	sp,sp,-80
    80004714:	e486                	sd	ra,72(sp)
    80004716:	e0a2                	sd	s0,64(sp)
    80004718:	fc26                	sd	s1,56(sp)
    8000471a:	f84a                	sd	s2,48(sp)
    8000471c:	f44e                	sd	s3,40(sp)
    8000471e:	0880                	addi	s0,sp,80
    80004720:	84aa                	mv	s1,a0
    80004722:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004724:	ffffd097          	auipc	ra,0xffffd
    80004728:	2ca080e7          	jalr	714(ra) # 800019ee <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000472c:	409c                	lw	a5,0(s1)
    8000472e:	37f9                	addiw	a5,a5,-2
    80004730:	4705                	li	a4,1
    80004732:	04f76763          	bltu	a4,a5,80004780 <filestat+0x6e>
    80004736:	892a                	mv	s2,a0
    ilock(f->ip);
    80004738:	6c88                	ld	a0,24(s1)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	082080e7          	jalr	130(ra) # 800037bc <ilock>
    stati(f->ip, &st);
    80004742:	fb840593          	addi	a1,s0,-72
    80004746:	6c88                	ld	a0,24(s1)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	2fe080e7          	jalr	766(ra) # 80003a46 <stati>
    iunlock(f->ip);
    80004750:	6c88                	ld	a0,24(s1)
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	12c080e7          	jalr	300(ra) # 8000387e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000475a:	46e1                	li	a3,24
    8000475c:	fb840613          	addi	a2,s0,-72
    80004760:	85ce                	mv	a1,s3
    80004762:	05093503          	ld	a0,80(s2)
    80004766:	ffffd097          	auipc	ra,0xffffd
    8000476a:	f7a080e7          	jalr	-134(ra) # 800016e0 <copyout>
    8000476e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004772:	60a6                	ld	ra,72(sp)
    80004774:	6406                	ld	s0,64(sp)
    80004776:	74e2                	ld	s1,56(sp)
    80004778:	7942                	ld	s2,48(sp)
    8000477a:	79a2                	ld	s3,40(sp)
    8000477c:	6161                	addi	sp,sp,80
    8000477e:	8082                	ret
  return -1;
    80004780:	557d                	li	a0,-1
    80004782:	bfc5                	j	80004772 <filestat+0x60>

0000000080004784 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004784:	7179                	addi	sp,sp,-48
    80004786:	f406                	sd	ra,40(sp)
    80004788:	f022                	sd	s0,32(sp)
    8000478a:	ec26                	sd	s1,24(sp)
    8000478c:	e84a                	sd	s2,16(sp)
    8000478e:	e44e                	sd	s3,8(sp)
    80004790:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004792:	00854783          	lbu	a5,8(a0)
    80004796:	c3d5                	beqz	a5,8000483a <fileread+0xb6>
    80004798:	84aa                	mv	s1,a0
    8000479a:	89ae                	mv	s3,a1
    8000479c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000479e:	411c                	lw	a5,0(a0)
    800047a0:	4705                	li	a4,1
    800047a2:	04e78963          	beq	a5,a4,800047f4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047a6:	470d                	li	a4,3
    800047a8:	04e78d63          	beq	a5,a4,80004802 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ac:	4709                	li	a4,2
    800047ae:	06e79e63          	bne	a5,a4,8000482a <fileread+0xa6>
    ilock(f->ip);
    800047b2:	6d08                	ld	a0,24(a0)
    800047b4:	fffff097          	auipc	ra,0xfffff
    800047b8:	008080e7          	jalr	8(ra) # 800037bc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047bc:	874a                	mv	a4,s2
    800047be:	5094                	lw	a3,32(s1)
    800047c0:	864e                	mv	a2,s3
    800047c2:	4585                	li	a1,1
    800047c4:	6c88                	ld	a0,24(s1)
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	2aa080e7          	jalr	682(ra) # 80003a70 <readi>
    800047ce:	892a                	mv	s2,a0
    800047d0:	00a05563          	blez	a0,800047da <fileread+0x56>
      f->off += r;
    800047d4:	509c                	lw	a5,32(s1)
    800047d6:	9fa9                	addw	a5,a5,a0
    800047d8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047da:	6c88                	ld	a0,24(s1)
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	0a2080e7          	jalr	162(ra) # 8000387e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047e4:	854a                	mv	a0,s2
    800047e6:	70a2                	ld	ra,40(sp)
    800047e8:	7402                	ld	s0,32(sp)
    800047ea:	64e2                	ld	s1,24(sp)
    800047ec:	6942                	ld	s2,16(sp)
    800047ee:	69a2                	ld	s3,8(sp)
    800047f0:	6145                	addi	sp,sp,48
    800047f2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047f4:	6908                	ld	a0,16(a0)
    800047f6:	00000097          	auipc	ra,0x0
    800047fa:	3f4080e7          	jalr	1012(ra) # 80004bea <piperead>
    800047fe:	892a                	mv	s2,a0
    80004800:	b7d5                	j	800047e4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004802:	02451783          	lh	a5,36(a0)
    80004806:	03079693          	slli	a3,a5,0x30
    8000480a:	92c1                	srli	a3,a3,0x30
    8000480c:	4725                	li	a4,9
    8000480e:	02d76863          	bltu	a4,a3,8000483e <fileread+0xba>
    80004812:	0792                	slli	a5,a5,0x4
    80004814:	0001d717          	auipc	a4,0x1d
    80004818:	39c70713          	addi	a4,a4,924 # 80021bb0 <devsw>
    8000481c:	97ba                	add	a5,a5,a4
    8000481e:	639c                	ld	a5,0(a5)
    80004820:	c38d                	beqz	a5,80004842 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004822:	4505                	li	a0,1
    80004824:	9782                	jalr	a5
    80004826:	892a                	mv	s2,a0
    80004828:	bf75                	j	800047e4 <fileread+0x60>
    panic("fileread");
    8000482a:	00004517          	auipc	a0,0x4
    8000482e:	f8650513          	addi	a0,a0,-122 # 800087b0 <syscalls+0x268>
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	d10080e7          	jalr	-752(ra) # 80000542 <panic>
    return -1;
    8000483a:	597d                	li	s2,-1
    8000483c:	b765                	j	800047e4 <fileread+0x60>
      return -1;
    8000483e:	597d                	li	s2,-1
    80004840:	b755                	j	800047e4 <fileread+0x60>
    80004842:	597d                	li	s2,-1
    80004844:	b745                	j	800047e4 <fileread+0x60>

0000000080004846 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004846:	00954783          	lbu	a5,9(a0)
    8000484a:	14078563          	beqz	a5,80004994 <filewrite+0x14e>
{
    8000484e:	715d                	addi	sp,sp,-80
    80004850:	e486                	sd	ra,72(sp)
    80004852:	e0a2                	sd	s0,64(sp)
    80004854:	fc26                	sd	s1,56(sp)
    80004856:	f84a                	sd	s2,48(sp)
    80004858:	f44e                	sd	s3,40(sp)
    8000485a:	f052                	sd	s4,32(sp)
    8000485c:	ec56                	sd	s5,24(sp)
    8000485e:	e85a                	sd	s6,16(sp)
    80004860:	e45e                	sd	s7,8(sp)
    80004862:	e062                	sd	s8,0(sp)
    80004864:	0880                	addi	s0,sp,80
    80004866:	892a                	mv	s2,a0
    80004868:	8aae                	mv	s5,a1
    8000486a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000486c:	411c                	lw	a5,0(a0)
    8000486e:	4705                	li	a4,1
    80004870:	02e78263          	beq	a5,a4,80004894 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004874:	470d                	li	a4,3
    80004876:	02e78563          	beq	a5,a4,800048a0 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000487a:	4709                	li	a4,2
    8000487c:	10e79463          	bne	a5,a4,80004984 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004880:	0ec05e63          	blez	a2,8000497c <filewrite+0x136>
    int i = 0;
    80004884:	4981                	li	s3,0
    80004886:	6b05                	lui	s6,0x1
    80004888:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000488c:	6b85                	lui	s7,0x1
    8000488e:	c00b8b9b          	addiw	s7,s7,-1024
    80004892:	a851                	j	80004926 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004894:	6908                	ld	a0,16(a0)
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	254080e7          	jalr	596(ra) # 80004aea <pipewrite>
    8000489e:	a85d                	j	80004954 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048a0:	02451783          	lh	a5,36(a0)
    800048a4:	03079693          	slli	a3,a5,0x30
    800048a8:	92c1                	srli	a3,a3,0x30
    800048aa:	4725                	li	a4,9
    800048ac:	0ed76663          	bltu	a4,a3,80004998 <filewrite+0x152>
    800048b0:	0792                	slli	a5,a5,0x4
    800048b2:	0001d717          	auipc	a4,0x1d
    800048b6:	2fe70713          	addi	a4,a4,766 # 80021bb0 <devsw>
    800048ba:	97ba                	add	a5,a5,a4
    800048bc:	679c                	ld	a5,8(a5)
    800048be:	cff9                	beqz	a5,8000499c <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800048c0:	4505                	li	a0,1
    800048c2:	9782                	jalr	a5
    800048c4:	a841                	j	80004954 <filewrite+0x10e>
    800048c6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048ca:	00000097          	auipc	ra,0x0
    800048ce:	8ae080e7          	jalr	-1874(ra) # 80004178 <begin_op>
      ilock(f->ip);
    800048d2:	01893503          	ld	a0,24(s2)
    800048d6:	fffff097          	auipc	ra,0xfffff
    800048da:	ee6080e7          	jalr	-282(ra) # 800037bc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048de:	8762                	mv	a4,s8
    800048e0:	02092683          	lw	a3,32(s2)
    800048e4:	01598633          	add	a2,s3,s5
    800048e8:	4585                	li	a1,1
    800048ea:	01893503          	ld	a0,24(s2)
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	278080e7          	jalr	632(ra) # 80003b66 <writei>
    800048f6:	84aa                	mv	s1,a0
    800048f8:	02a05f63          	blez	a0,80004936 <filewrite+0xf0>
        f->off += r;
    800048fc:	02092783          	lw	a5,32(s2)
    80004900:	9fa9                	addw	a5,a5,a0
    80004902:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004906:	01893503          	ld	a0,24(s2)
    8000490a:	fffff097          	auipc	ra,0xfffff
    8000490e:	f74080e7          	jalr	-140(ra) # 8000387e <iunlock>
      end_op();
    80004912:	00000097          	auipc	ra,0x0
    80004916:	8e6080e7          	jalr	-1818(ra) # 800041f8 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000491a:	049c1963          	bne	s8,s1,8000496c <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000491e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004922:	0349d663          	bge	s3,s4,8000494e <filewrite+0x108>
      int n1 = n - i;
    80004926:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000492a:	84be                	mv	s1,a5
    8000492c:	2781                	sext.w	a5,a5
    8000492e:	f8fb5ce3          	bge	s6,a5,800048c6 <filewrite+0x80>
    80004932:	84de                	mv	s1,s7
    80004934:	bf49                	j	800048c6 <filewrite+0x80>
      iunlock(f->ip);
    80004936:	01893503          	ld	a0,24(s2)
    8000493a:	fffff097          	auipc	ra,0xfffff
    8000493e:	f44080e7          	jalr	-188(ra) # 8000387e <iunlock>
      end_op();
    80004942:	00000097          	auipc	ra,0x0
    80004946:	8b6080e7          	jalr	-1866(ra) # 800041f8 <end_op>
      if(r < 0)
    8000494a:	fc04d8e3          	bgez	s1,8000491a <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    8000494e:	8552                	mv	a0,s4
    80004950:	033a1863          	bne	s4,s3,80004980 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004954:	60a6                	ld	ra,72(sp)
    80004956:	6406                	ld	s0,64(sp)
    80004958:	74e2                	ld	s1,56(sp)
    8000495a:	7942                	ld	s2,48(sp)
    8000495c:	79a2                	ld	s3,40(sp)
    8000495e:	7a02                	ld	s4,32(sp)
    80004960:	6ae2                	ld	s5,24(sp)
    80004962:	6b42                	ld	s6,16(sp)
    80004964:	6ba2                	ld	s7,8(sp)
    80004966:	6c02                	ld	s8,0(sp)
    80004968:	6161                	addi	sp,sp,80
    8000496a:	8082                	ret
        panic("short filewrite");
    8000496c:	00004517          	auipc	a0,0x4
    80004970:	e5450513          	addi	a0,a0,-428 # 800087c0 <syscalls+0x278>
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	bce080e7          	jalr	-1074(ra) # 80000542 <panic>
    int i = 0;
    8000497c:	4981                	li	s3,0
    8000497e:	bfc1                	j	8000494e <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004980:	557d                	li	a0,-1
    80004982:	bfc9                	j	80004954 <filewrite+0x10e>
    panic("filewrite");
    80004984:	00004517          	auipc	a0,0x4
    80004988:	e4c50513          	addi	a0,a0,-436 # 800087d0 <syscalls+0x288>
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	bb6080e7          	jalr	-1098(ra) # 80000542 <panic>
    return -1;
    80004994:	557d                	li	a0,-1
}
    80004996:	8082                	ret
      return -1;
    80004998:	557d                	li	a0,-1
    8000499a:	bf6d                	j	80004954 <filewrite+0x10e>
    8000499c:	557d                	li	a0,-1
    8000499e:	bf5d                	j	80004954 <filewrite+0x10e>

00000000800049a0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049a0:	7179                	addi	sp,sp,-48
    800049a2:	f406                	sd	ra,40(sp)
    800049a4:	f022                	sd	s0,32(sp)
    800049a6:	ec26                	sd	s1,24(sp)
    800049a8:	e84a                	sd	s2,16(sp)
    800049aa:	e44e                	sd	s3,8(sp)
    800049ac:	e052                	sd	s4,0(sp)
    800049ae:	1800                	addi	s0,sp,48
    800049b0:	84aa                	mv	s1,a0
    800049b2:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049b4:	0005b023          	sd	zero,0(a1)
    800049b8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049bc:	00000097          	auipc	ra,0x0
    800049c0:	bd2080e7          	jalr	-1070(ra) # 8000458e <filealloc>
    800049c4:	e088                	sd	a0,0(s1)
    800049c6:	c551                	beqz	a0,80004a52 <pipealloc+0xb2>
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	bc6080e7          	jalr	-1082(ra) # 8000458e <filealloc>
    800049d0:	00aa3023          	sd	a0,0(s4)
    800049d4:	c92d                	beqz	a0,80004a46 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	138080e7          	jalr	312(ra) # 80000b0e <kalloc>
    800049de:	892a                	mv	s2,a0
    800049e0:	c125                	beqz	a0,80004a40 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049e2:	4985                	li	s3,1
    800049e4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049e8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049ec:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049f0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049f4:	00004597          	auipc	a1,0x4
    800049f8:	aac58593          	addi	a1,a1,-1364 # 800084a0 <states.0+0x198>
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	196080e7          	jalr	406(ra) # 80000b92 <initlock>
  (*f0)->type = FD_PIPE;
    80004a04:	609c                	ld	a5,0(s1)
    80004a06:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a0a:	609c                	ld	a5,0(s1)
    80004a0c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a10:	609c                	ld	a5,0(s1)
    80004a12:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a16:	609c                	ld	a5,0(s1)
    80004a18:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a1c:	000a3783          	ld	a5,0(s4)
    80004a20:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a24:	000a3783          	ld	a5,0(s4)
    80004a28:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a2c:	000a3783          	ld	a5,0(s4)
    80004a30:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a34:	000a3783          	ld	a5,0(s4)
    80004a38:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a3c:	4501                	li	a0,0
    80004a3e:	a025                	j	80004a66 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a40:	6088                	ld	a0,0(s1)
    80004a42:	e501                	bnez	a0,80004a4a <pipealloc+0xaa>
    80004a44:	a039                	j	80004a52 <pipealloc+0xb2>
    80004a46:	6088                	ld	a0,0(s1)
    80004a48:	c51d                	beqz	a0,80004a76 <pipealloc+0xd6>
    fileclose(*f0);
    80004a4a:	00000097          	auipc	ra,0x0
    80004a4e:	c00080e7          	jalr	-1024(ra) # 8000464a <fileclose>
  if(*f1)
    80004a52:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a56:	557d                	li	a0,-1
  if(*f1)
    80004a58:	c799                	beqz	a5,80004a66 <pipealloc+0xc6>
    fileclose(*f1);
    80004a5a:	853e                	mv	a0,a5
    80004a5c:	00000097          	auipc	ra,0x0
    80004a60:	bee080e7          	jalr	-1042(ra) # 8000464a <fileclose>
  return -1;
    80004a64:	557d                	li	a0,-1
}
    80004a66:	70a2                	ld	ra,40(sp)
    80004a68:	7402                	ld	s0,32(sp)
    80004a6a:	64e2                	ld	s1,24(sp)
    80004a6c:	6942                	ld	s2,16(sp)
    80004a6e:	69a2                	ld	s3,8(sp)
    80004a70:	6a02                	ld	s4,0(sp)
    80004a72:	6145                	addi	sp,sp,48
    80004a74:	8082                	ret
  return -1;
    80004a76:	557d                	li	a0,-1
    80004a78:	b7fd                	j	80004a66 <pipealloc+0xc6>

0000000080004a7a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a7a:	1101                	addi	sp,sp,-32
    80004a7c:	ec06                	sd	ra,24(sp)
    80004a7e:	e822                	sd	s0,16(sp)
    80004a80:	e426                	sd	s1,8(sp)
    80004a82:	e04a                	sd	s2,0(sp)
    80004a84:	1000                	addi	s0,sp,32
    80004a86:	84aa                	mv	s1,a0
    80004a88:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	198080e7          	jalr	408(ra) # 80000c22 <acquire>
  if(writable){
    80004a92:	02090d63          	beqz	s2,80004acc <pipeclose+0x52>
    pi->writeopen = 0;
    80004a96:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a9a:	21848513          	addi	a0,s1,536
    80004a9e:	ffffe097          	auipc	ra,0xffffe
    80004aa2:	8e8080e7          	jalr	-1816(ra) # 80002386 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004aa6:	2204b783          	ld	a5,544(s1)
    80004aaa:	eb95                	bnez	a5,80004ade <pipeclose+0x64>
    release(&pi->lock);
    80004aac:	8526                	mv	a0,s1
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	228080e7          	jalr	552(ra) # 80000cd6 <release>
    kfree((char*)pi);
    80004ab6:	8526                	mv	a0,s1
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	f5a080e7          	jalr	-166(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    80004ac0:	60e2                	ld	ra,24(sp)
    80004ac2:	6442                	ld	s0,16(sp)
    80004ac4:	64a2                	ld	s1,8(sp)
    80004ac6:	6902                	ld	s2,0(sp)
    80004ac8:	6105                	addi	sp,sp,32
    80004aca:	8082                	ret
    pi->readopen = 0;
    80004acc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ad0:	21c48513          	addi	a0,s1,540
    80004ad4:	ffffe097          	auipc	ra,0xffffe
    80004ad8:	8b2080e7          	jalr	-1870(ra) # 80002386 <wakeup>
    80004adc:	b7e9                	j	80004aa6 <pipeclose+0x2c>
    release(&pi->lock);
    80004ade:	8526                	mv	a0,s1
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	1f6080e7          	jalr	502(ra) # 80000cd6 <release>
}
    80004ae8:	bfe1                	j	80004ac0 <pipeclose+0x46>

0000000080004aea <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aea:	711d                	addi	sp,sp,-96
    80004aec:	ec86                	sd	ra,88(sp)
    80004aee:	e8a2                	sd	s0,80(sp)
    80004af0:	e4a6                	sd	s1,72(sp)
    80004af2:	e0ca                	sd	s2,64(sp)
    80004af4:	fc4e                	sd	s3,56(sp)
    80004af6:	f852                	sd	s4,48(sp)
    80004af8:	f456                	sd	s5,40(sp)
    80004afa:	f05a                	sd	s6,32(sp)
    80004afc:	ec5e                	sd	s7,24(sp)
    80004afe:	e862                	sd	s8,16(sp)
    80004b00:	1080                	addi	s0,sp,96
    80004b02:	84aa                	mv	s1,a0
    80004b04:	8b2e                	mv	s6,a1
    80004b06:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b08:	ffffd097          	auipc	ra,0xffffd
    80004b0c:	ee6080e7          	jalr	-282(ra) # 800019ee <myproc>
    80004b10:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b12:	8526                	mv	a0,s1
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	10e080e7          	jalr	270(ra) # 80000c22 <acquire>
  for(i = 0; i < n; i++){
    80004b1c:	09505763          	blez	s5,80004baa <pipewrite+0xc0>
    80004b20:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b22:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b26:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b2a:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b2c:	2184a783          	lw	a5,536(s1)
    80004b30:	21c4a703          	lw	a4,540(s1)
    80004b34:	2007879b          	addiw	a5,a5,512
    80004b38:	02f71b63          	bne	a4,a5,80004b6e <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004b3c:	2204a783          	lw	a5,544(s1)
    80004b40:	c3d1                	beqz	a5,80004bc4 <pipewrite+0xda>
    80004b42:	03092783          	lw	a5,48(s2)
    80004b46:	efbd                	bnez	a5,80004bc4 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004b48:	8552                	mv	a0,s4
    80004b4a:	ffffe097          	auipc	ra,0xffffe
    80004b4e:	83c080e7          	jalr	-1988(ra) # 80002386 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b52:	85a6                	mv	a1,s1
    80004b54:	854e                	mv	a0,s3
    80004b56:	ffffd097          	auipc	ra,0xffffd
    80004b5a:	6b0080e7          	jalr	1712(ra) # 80002206 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b5e:	2184a783          	lw	a5,536(s1)
    80004b62:	21c4a703          	lw	a4,540(s1)
    80004b66:	2007879b          	addiw	a5,a5,512
    80004b6a:	fcf709e3          	beq	a4,a5,80004b3c <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b6e:	4685                	li	a3,1
    80004b70:	865a                	mv	a2,s6
    80004b72:	faf40593          	addi	a1,s0,-81
    80004b76:	05093503          	ld	a0,80(s2)
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	bf2080e7          	jalr	-1038(ra) # 8000176c <copyin>
    80004b82:	03850563          	beq	a0,s8,80004bac <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b86:	21c4a783          	lw	a5,540(s1)
    80004b8a:	0017871b          	addiw	a4,a5,1
    80004b8e:	20e4ae23          	sw	a4,540(s1)
    80004b92:	1ff7f793          	andi	a5,a5,511
    80004b96:	97a6                	add	a5,a5,s1
    80004b98:	faf44703          	lbu	a4,-81(s0)
    80004b9c:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004ba0:	2b85                	addiw	s7,s7,1
    80004ba2:	0b05                	addi	s6,s6,1
    80004ba4:	f97a94e3          	bne	s5,s7,80004b2c <pipewrite+0x42>
    80004ba8:	a011                	j	80004bac <pipewrite+0xc2>
    80004baa:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004bac:	21848513          	addi	a0,s1,536
    80004bb0:	ffffd097          	auipc	ra,0xffffd
    80004bb4:	7d6080e7          	jalr	2006(ra) # 80002386 <wakeup>
  release(&pi->lock);
    80004bb8:	8526                	mv	a0,s1
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	11c080e7          	jalr	284(ra) # 80000cd6 <release>
  return i;
    80004bc2:	a039                	j	80004bd0 <pipewrite+0xe6>
        release(&pi->lock);
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	110080e7          	jalr	272(ra) # 80000cd6 <release>
        return -1;
    80004bce:	5bfd                	li	s7,-1
}
    80004bd0:	855e                	mv	a0,s7
    80004bd2:	60e6                	ld	ra,88(sp)
    80004bd4:	6446                	ld	s0,80(sp)
    80004bd6:	64a6                	ld	s1,72(sp)
    80004bd8:	6906                	ld	s2,64(sp)
    80004bda:	79e2                	ld	s3,56(sp)
    80004bdc:	7a42                	ld	s4,48(sp)
    80004bde:	7aa2                	ld	s5,40(sp)
    80004be0:	7b02                	ld	s6,32(sp)
    80004be2:	6be2                	ld	s7,24(sp)
    80004be4:	6c42                	ld	s8,16(sp)
    80004be6:	6125                	addi	sp,sp,96
    80004be8:	8082                	ret

0000000080004bea <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bea:	715d                	addi	sp,sp,-80
    80004bec:	e486                	sd	ra,72(sp)
    80004bee:	e0a2                	sd	s0,64(sp)
    80004bf0:	fc26                	sd	s1,56(sp)
    80004bf2:	f84a                	sd	s2,48(sp)
    80004bf4:	f44e                	sd	s3,40(sp)
    80004bf6:	f052                	sd	s4,32(sp)
    80004bf8:	ec56                	sd	s5,24(sp)
    80004bfa:	e85a                	sd	s6,16(sp)
    80004bfc:	0880                	addi	s0,sp,80
    80004bfe:	84aa                	mv	s1,a0
    80004c00:	892e                	mv	s2,a1
    80004c02:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c04:	ffffd097          	auipc	ra,0xffffd
    80004c08:	dea080e7          	jalr	-534(ra) # 800019ee <myproc>
    80004c0c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c0e:	8526                	mv	a0,s1
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	012080e7          	jalr	18(ra) # 80000c22 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c18:	2184a703          	lw	a4,536(s1)
    80004c1c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c20:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c24:	02f71463          	bne	a4,a5,80004c4c <piperead+0x62>
    80004c28:	2244a783          	lw	a5,548(s1)
    80004c2c:	c385                	beqz	a5,80004c4c <piperead+0x62>
    if(pr->killed){
    80004c2e:	030a2783          	lw	a5,48(s4)
    80004c32:	ebc1                	bnez	a5,80004cc2 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c34:	85a6                	mv	a1,s1
    80004c36:	854e                	mv	a0,s3
    80004c38:	ffffd097          	auipc	ra,0xffffd
    80004c3c:	5ce080e7          	jalr	1486(ra) # 80002206 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c40:	2184a703          	lw	a4,536(s1)
    80004c44:	21c4a783          	lw	a5,540(s1)
    80004c48:	fef700e3          	beq	a4,a5,80004c28 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c4c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c4e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c50:	05505363          	blez	s5,80004c96 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004c54:	2184a783          	lw	a5,536(s1)
    80004c58:	21c4a703          	lw	a4,540(s1)
    80004c5c:	02f70d63          	beq	a4,a5,80004c96 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c60:	0017871b          	addiw	a4,a5,1
    80004c64:	20e4ac23          	sw	a4,536(s1)
    80004c68:	1ff7f793          	andi	a5,a5,511
    80004c6c:	97a6                	add	a5,a5,s1
    80004c6e:	0187c783          	lbu	a5,24(a5)
    80004c72:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c76:	4685                	li	a3,1
    80004c78:	fbf40613          	addi	a2,s0,-65
    80004c7c:	85ca                	mv	a1,s2
    80004c7e:	050a3503          	ld	a0,80(s4)
    80004c82:	ffffd097          	auipc	ra,0xffffd
    80004c86:	a5e080e7          	jalr	-1442(ra) # 800016e0 <copyout>
    80004c8a:	01650663          	beq	a0,s6,80004c96 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c8e:	2985                	addiw	s3,s3,1
    80004c90:	0905                	addi	s2,s2,1
    80004c92:	fd3a91e3          	bne	s5,s3,80004c54 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c96:	21c48513          	addi	a0,s1,540
    80004c9a:	ffffd097          	auipc	ra,0xffffd
    80004c9e:	6ec080e7          	jalr	1772(ra) # 80002386 <wakeup>
  release(&pi->lock);
    80004ca2:	8526                	mv	a0,s1
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	032080e7          	jalr	50(ra) # 80000cd6 <release>
  return i;
}
    80004cac:	854e                	mv	a0,s3
    80004cae:	60a6                	ld	ra,72(sp)
    80004cb0:	6406                	ld	s0,64(sp)
    80004cb2:	74e2                	ld	s1,56(sp)
    80004cb4:	7942                	ld	s2,48(sp)
    80004cb6:	79a2                	ld	s3,40(sp)
    80004cb8:	7a02                	ld	s4,32(sp)
    80004cba:	6ae2                	ld	s5,24(sp)
    80004cbc:	6b42                	ld	s6,16(sp)
    80004cbe:	6161                	addi	sp,sp,80
    80004cc0:	8082                	ret
      release(&pi->lock);
    80004cc2:	8526                	mv	a0,s1
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	012080e7          	jalr	18(ra) # 80000cd6 <release>
      return -1;
    80004ccc:	59fd                	li	s3,-1
    80004cce:	bff9                	j	80004cac <piperead+0xc2>

0000000080004cd0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cd0:	de010113          	addi	sp,sp,-544
    80004cd4:	20113c23          	sd	ra,536(sp)
    80004cd8:	20813823          	sd	s0,528(sp)
    80004cdc:	20913423          	sd	s1,520(sp)
    80004ce0:	21213023          	sd	s2,512(sp)
    80004ce4:	ffce                	sd	s3,504(sp)
    80004ce6:	fbd2                	sd	s4,496(sp)
    80004ce8:	f7d6                	sd	s5,488(sp)
    80004cea:	f3da                	sd	s6,480(sp)
    80004cec:	efde                	sd	s7,472(sp)
    80004cee:	ebe2                	sd	s8,464(sp)
    80004cf0:	e7e6                	sd	s9,456(sp)
    80004cf2:	e3ea                	sd	s10,448(sp)
    80004cf4:	ff6e                	sd	s11,440(sp)
    80004cf6:	1400                	addi	s0,sp,544
    80004cf8:	892a                	mv	s2,a0
    80004cfa:	dea43423          	sd	a0,-536(s0)
    80004cfe:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d02:	ffffd097          	auipc	ra,0xffffd
    80004d06:	cec080e7          	jalr	-788(ra) # 800019ee <myproc>
    80004d0a:	84aa                	mv	s1,a0

  begin_op();
    80004d0c:	fffff097          	auipc	ra,0xfffff
    80004d10:	46c080e7          	jalr	1132(ra) # 80004178 <begin_op>

  if((ip = namei(path)) == 0){
    80004d14:	854a                	mv	a0,s2
    80004d16:	fffff097          	auipc	ra,0xfffff
    80004d1a:	256080e7          	jalr	598(ra) # 80003f6c <namei>
    80004d1e:	c93d                	beqz	a0,80004d94 <exec+0xc4>
    80004d20:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	a9a080e7          	jalr	-1382(ra) # 800037bc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d2a:	04000713          	li	a4,64
    80004d2e:	4681                	li	a3,0
    80004d30:	e4840613          	addi	a2,s0,-440
    80004d34:	4581                	li	a1,0
    80004d36:	8556                	mv	a0,s5
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	d38080e7          	jalr	-712(ra) # 80003a70 <readi>
    80004d40:	04000793          	li	a5,64
    80004d44:	00f51a63          	bne	a0,a5,80004d58 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d48:	e4842703          	lw	a4,-440(s0)
    80004d4c:	464c47b7          	lui	a5,0x464c4
    80004d50:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d54:	04f70663          	beq	a4,a5,80004da0 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d58:	8556                	mv	a0,s5
    80004d5a:	fffff097          	auipc	ra,0xfffff
    80004d5e:	cc4080e7          	jalr	-828(ra) # 80003a1e <iunlockput>
    end_op();
    80004d62:	fffff097          	auipc	ra,0xfffff
    80004d66:	496080e7          	jalr	1174(ra) # 800041f8 <end_op>
  }
  return -1;
    80004d6a:	557d                	li	a0,-1
}
    80004d6c:	21813083          	ld	ra,536(sp)
    80004d70:	21013403          	ld	s0,528(sp)
    80004d74:	20813483          	ld	s1,520(sp)
    80004d78:	20013903          	ld	s2,512(sp)
    80004d7c:	79fe                	ld	s3,504(sp)
    80004d7e:	7a5e                	ld	s4,496(sp)
    80004d80:	7abe                	ld	s5,488(sp)
    80004d82:	7b1e                	ld	s6,480(sp)
    80004d84:	6bfe                	ld	s7,472(sp)
    80004d86:	6c5e                	ld	s8,464(sp)
    80004d88:	6cbe                	ld	s9,456(sp)
    80004d8a:	6d1e                	ld	s10,448(sp)
    80004d8c:	7dfa                	ld	s11,440(sp)
    80004d8e:	22010113          	addi	sp,sp,544
    80004d92:	8082                	ret
    end_op();
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	464080e7          	jalr	1124(ra) # 800041f8 <end_op>
    return -1;
    80004d9c:	557d                	li	a0,-1
    80004d9e:	b7f9                	j	80004d6c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004da0:	8526                	mv	a0,s1
    80004da2:	ffffd097          	auipc	ra,0xffffd
    80004da6:	d10080e7          	jalr	-752(ra) # 80001ab2 <proc_pagetable>
    80004daa:	8b2a                	mv	s6,a0
    80004dac:	d555                	beqz	a0,80004d58 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dae:	e6842783          	lw	a5,-408(s0)
    80004db2:	e8045703          	lhu	a4,-384(s0)
    80004db6:	c735                	beqz	a4,80004e22 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004db8:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dba:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004dbe:	6a05                	lui	s4,0x1
    80004dc0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004dc4:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004dc8:	6d85                	lui	s11,0x1
    80004dca:	7d7d                	lui	s10,0xfffff
    80004dcc:	ac1d                	j	80005002 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dce:	00004517          	auipc	a0,0x4
    80004dd2:	a1250513          	addi	a0,a0,-1518 # 800087e0 <syscalls+0x298>
    80004dd6:	ffffb097          	auipc	ra,0xffffb
    80004dda:	76c080e7          	jalr	1900(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dde:	874a                	mv	a4,s2
    80004de0:	009c86bb          	addw	a3,s9,s1
    80004de4:	4581                	li	a1,0
    80004de6:	8556                	mv	a0,s5
    80004de8:	fffff097          	auipc	ra,0xfffff
    80004dec:	c88080e7          	jalr	-888(ra) # 80003a70 <readi>
    80004df0:	2501                	sext.w	a0,a0
    80004df2:	1aa91863          	bne	s2,a0,80004fa2 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004df6:	009d84bb          	addw	s1,s11,s1
    80004dfa:	013d09bb          	addw	s3,s10,s3
    80004dfe:	1f74f263          	bgeu	s1,s7,80004fe2 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004e02:	02049593          	slli	a1,s1,0x20
    80004e06:	9181                	srli	a1,a1,0x20
    80004e08:	95e2                	add	a1,a1,s8
    80004e0a:	855a                	mv	a0,s6
    80004e0c:	ffffc097          	auipc	ra,0xffffc
    80004e10:	2a0080e7          	jalr	672(ra) # 800010ac <walkaddr>
    80004e14:	862a                	mv	a2,a0
    if(pa == 0)
    80004e16:	dd45                	beqz	a0,80004dce <exec+0xfe>
      n = PGSIZE;
    80004e18:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e1a:	fd49f2e3          	bgeu	s3,s4,80004dde <exec+0x10e>
      n = sz - i;
    80004e1e:	894e                	mv	s2,s3
    80004e20:	bf7d                	j	80004dde <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e22:	4481                	li	s1,0
  iunlockput(ip);
    80004e24:	8556                	mv	a0,s5
    80004e26:	fffff097          	auipc	ra,0xfffff
    80004e2a:	bf8080e7          	jalr	-1032(ra) # 80003a1e <iunlockput>
  end_op();
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	3ca080e7          	jalr	970(ra) # 800041f8 <end_op>
  p = myproc();
    80004e36:	ffffd097          	auipc	ra,0xffffd
    80004e3a:	bb8080e7          	jalr	-1096(ra) # 800019ee <myproc>
    80004e3e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e40:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e44:	6785                	lui	a5,0x1
    80004e46:	17fd                	addi	a5,a5,-1
    80004e48:	94be                	add	s1,s1,a5
    80004e4a:	77fd                	lui	a5,0xfffff
    80004e4c:	8fe5                	and	a5,a5,s1
    80004e4e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e52:	6609                	lui	a2,0x2
    80004e54:	963e                	add	a2,a2,a5
    80004e56:	85be                	mv	a1,a5
    80004e58:	855a                	mv	a0,s6
    80004e5a:	ffffc097          	auipc	ra,0xffffc
    80004e5e:	636080e7          	jalr	1590(ra) # 80001490 <uvmalloc>
    80004e62:	8c2a                	mv	s8,a0
  ip = 0;
    80004e64:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e66:	12050e63          	beqz	a0,80004fa2 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e6a:	75f9                	lui	a1,0xffffe
    80004e6c:	95aa                	add	a1,a1,a0
    80004e6e:	855a                	mv	a0,s6
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	83e080e7          	jalr	-1986(ra) # 800016ae <uvmclear>
  stackbase = sp - PGSIZE;
    80004e78:	7afd                	lui	s5,0xfffff
    80004e7a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e7c:	df043783          	ld	a5,-528(s0)
    80004e80:	6388                	ld	a0,0(a5)
    80004e82:	c925                	beqz	a0,80004ef2 <exec+0x222>
    80004e84:	e8840993          	addi	s3,s0,-376
    80004e88:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e8c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e8e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e90:	ffffc097          	auipc	ra,0xffffc
    80004e94:	012080e7          	jalr	18(ra) # 80000ea2 <strlen>
    80004e98:	0015079b          	addiw	a5,a0,1
    80004e9c:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ea0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ea4:	13596363          	bltu	s2,s5,80004fca <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ea8:	df043d83          	ld	s11,-528(s0)
    80004eac:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004eb0:	8552                	mv	a0,s4
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	ff0080e7          	jalr	-16(ra) # 80000ea2 <strlen>
    80004eba:	0015069b          	addiw	a3,a0,1
    80004ebe:	8652                	mv	a2,s4
    80004ec0:	85ca                	mv	a1,s2
    80004ec2:	855a                	mv	a0,s6
    80004ec4:	ffffd097          	auipc	ra,0xffffd
    80004ec8:	81c080e7          	jalr	-2020(ra) # 800016e0 <copyout>
    80004ecc:	10054363          	bltz	a0,80004fd2 <exec+0x302>
    ustack[argc] = sp;
    80004ed0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ed4:	0485                	addi	s1,s1,1
    80004ed6:	008d8793          	addi	a5,s11,8
    80004eda:	def43823          	sd	a5,-528(s0)
    80004ede:	008db503          	ld	a0,8(s11)
    80004ee2:	c911                	beqz	a0,80004ef6 <exec+0x226>
    if(argc >= MAXARG)
    80004ee4:	09a1                	addi	s3,s3,8
    80004ee6:	fb3c95e3          	bne	s9,s3,80004e90 <exec+0x1c0>
  sz = sz1;
    80004eea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eee:	4a81                	li	s5,0
    80004ef0:	a84d                	j	80004fa2 <exec+0x2d2>
  sp = sz;
    80004ef2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ef4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ef6:	00349793          	slli	a5,s1,0x3
    80004efa:	f9040713          	addi	a4,s0,-112
    80004efe:	97ba                	add	a5,a5,a4
    80004f00:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004f04:	00148693          	addi	a3,s1,1
    80004f08:	068e                	slli	a3,a3,0x3
    80004f0a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f0e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f12:	01597663          	bgeu	s2,s5,80004f1e <exec+0x24e>
  sz = sz1;
    80004f16:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f1a:	4a81                	li	s5,0
    80004f1c:	a059                	j	80004fa2 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f1e:	e8840613          	addi	a2,s0,-376
    80004f22:	85ca                	mv	a1,s2
    80004f24:	855a                	mv	a0,s6
    80004f26:	ffffc097          	auipc	ra,0xffffc
    80004f2a:	7ba080e7          	jalr	1978(ra) # 800016e0 <copyout>
    80004f2e:	0a054663          	bltz	a0,80004fda <exec+0x30a>
  p->trapframe->a1 = sp;
    80004f32:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f36:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f3a:	de843783          	ld	a5,-536(s0)
    80004f3e:	0007c703          	lbu	a4,0(a5)
    80004f42:	cf11                	beqz	a4,80004f5e <exec+0x28e>
    80004f44:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f46:	02f00693          	li	a3,47
    80004f4a:	a039                	j	80004f58 <exec+0x288>
      last = s+1;
    80004f4c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f50:	0785                	addi	a5,a5,1
    80004f52:	fff7c703          	lbu	a4,-1(a5)
    80004f56:	c701                	beqz	a4,80004f5e <exec+0x28e>
    if(*s == '/')
    80004f58:	fed71ce3          	bne	a4,a3,80004f50 <exec+0x280>
    80004f5c:	bfc5                	j	80004f4c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f5e:	4641                	li	a2,16
    80004f60:	de843583          	ld	a1,-536(s0)
    80004f64:	158b8513          	addi	a0,s7,344
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	f08080e7          	jalr	-248(ra) # 80000e70 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f70:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f74:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f78:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f7c:	058bb783          	ld	a5,88(s7)
    80004f80:	e6043703          	ld	a4,-416(s0)
    80004f84:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f86:	058bb783          	ld	a5,88(s7)
    80004f8a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f8e:	85ea                	mv	a1,s10
    80004f90:	ffffd097          	auipc	ra,0xffffd
    80004f94:	bbe080e7          	jalr	-1090(ra) # 80001b4e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f98:	0004851b          	sext.w	a0,s1
    80004f9c:	bbc1                	j	80004d6c <exec+0x9c>
    80004f9e:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004fa2:	df843583          	ld	a1,-520(s0)
    80004fa6:	855a                	mv	a0,s6
    80004fa8:	ffffd097          	auipc	ra,0xffffd
    80004fac:	ba6080e7          	jalr	-1114(ra) # 80001b4e <proc_freepagetable>
  if(ip){
    80004fb0:	da0a94e3          	bnez	s5,80004d58 <exec+0x88>
  return -1;
    80004fb4:	557d                	li	a0,-1
    80004fb6:	bb5d                	j	80004d6c <exec+0x9c>
    80004fb8:	de943c23          	sd	s1,-520(s0)
    80004fbc:	b7dd                	j	80004fa2 <exec+0x2d2>
    80004fbe:	de943c23          	sd	s1,-520(s0)
    80004fc2:	b7c5                	j	80004fa2 <exec+0x2d2>
    80004fc4:	de943c23          	sd	s1,-520(s0)
    80004fc8:	bfe9                	j	80004fa2 <exec+0x2d2>
  sz = sz1;
    80004fca:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fce:	4a81                	li	s5,0
    80004fd0:	bfc9                	j	80004fa2 <exec+0x2d2>
  sz = sz1;
    80004fd2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fd6:	4a81                	li	s5,0
    80004fd8:	b7e9                	j	80004fa2 <exec+0x2d2>
  sz = sz1;
    80004fda:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fde:	4a81                	li	s5,0
    80004fe0:	b7c9                	j	80004fa2 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fe2:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fe6:	e0843783          	ld	a5,-504(s0)
    80004fea:	0017869b          	addiw	a3,a5,1
    80004fee:	e0d43423          	sd	a3,-504(s0)
    80004ff2:	e0043783          	ld	a5,-512(s0)
    80004ff6:	0387879b          	addiw	a5,a5,56
    80004ffa:	e8045703          	lhu	a4,-384(s0)
    80004ffe:	e2e6d3e3          	bge	a3,a4,80004e24 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005002:	2781                	sext.w	a5,a5
    80005004:	e0f43023          	sd	a5,-512(s0)
    80005008:	03800713          	li	a4,56
    8000500c:	86be                	mv	a3,a5
    8000500e:	e1040613          	addi	a2,s0,-496
    80005012:	4581                	li	a1,0
    80005014:	8556                	mv	a0,s5
    80005016:	fffff097          	auipc	ra,0xfffff
    8000501a:	a5a080e7          	jalr	-1446(ra) # 80003a70 <readi>
    8000501e:	03800793          	li	a5,56
    80005022:	f6f51ee3          	bne	a0,a5,80004f9e <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005026:	e1042783          	lw	a5,-496(s0)
    8000502a:	4705                	li	a4,1
    8000502c:	fae79de3          	bne	a5,a4,80004fe6 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005030:	e3843603          	ld	a2,-456(s0)
    80005034:	e3043783          	ld	a5,-464(s0)
    80005038:	f8f660e3          	bltu	a2,a5,80004fb8 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000503c:	e2043783          	ld	a5,-480(s0)
    80005040:	963e                	add	a2,a2,a5
    80005042:	f6f66ee3          	bltu	a2,a5,80004fbe <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005046:	85a6                	mv	a1,s1
    80005048:	855a                	mv	a0,s6
    8000504a:	ffffc097          	auipc	ra,0xffffc
    8000504e:	446080e7          	jalr	1094(ra) # 80001490 <uvmalloc>
    80005052:	dea43c23          	sd	a0,-520(s0)
    80005056:	d53d                	beqz	a0,80004fc4 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005058:	e2043c03          	ld	s8,-480(s0)
    8000505c:	de043783          	ld	a5,-544(s0)
    80005060:	00fc77b3          	and	a5,s8,a5
    80005064:	ff9d                	bnez	a5,80004fa2 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005066:	e1842c83          	lw	s9,-488(s0)
    8000506a:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000506e:	f60b8ae3          	beqz	s7,80004fe2 <exec+0x312>
    80005072:	89de                	mv	s3,s7
    80005074:	4481                	li	s1,0
    80005076:	b371                	j	80004e02 <exec+0x132>

0000000080005078 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005078:	7179                	addi	sp,sp,-48
    8000507a:	f406                	sd	ra,40(sp)
    8000507c:	f022                	sd	s0,32(sp)
    8000507e:	ec26                	sd	s1,24(sp)
    80005080:	e84a                	sd	s2,16(sp)
    80005082:	1800                	addi	s0,sp,48
    80005084:	892e                	mv	s2,a1
    80005086:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005088:	fdc40593          	addi	a1,s0,-36
    8000508c:	ffffe097          	auipc	ra,0xffffe
    80005090:	ad6080e7          	jalr	-1322(ra) # 80002b62 <argint>
    80005094:	04054063          	bltz	a0,800050d4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005098:	fdc42703          	lw	a4,-36(s0)
    8000509c:	47bd                	li	a5,15
    8000509e:	02e7ed63          	bltu	a5,a4,800050d8 <argfd+0x60>
    800050a2:	ffffd097          	auipc	ra,0xffffd
    800050a6:	94c080e7          	jalr	-1716(ra) # 800019ee <myproc>
    800050aa:	fdc42703          	lw	a4,-36(s0)
    800050ae:	01a70793          	addi	a5,a4,26
    800050b2:	078e                	slli	a5,a5,0x3
    800050b4:	953e                	add	a0,a0,a5
    800050b6:	611c                	ld	a5,0(a0)
    800050b8:	c395                	beqz	a5,800050dc <argfd+0x64>
    return -1;
  if(pfd)
    800050ba:	00090463          	beqz	s2,800050c2 <argfd+0x4a>
    *pfd = fd;
    800050be:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050c2:	4501                	li	a0,0
  if(pf)
    800050c4:	c091                	beqz	s1,800050c8 <argfd+0x50>
    *pf = f;
    800050c6:	e09c                	sd	a5,0(s1)
}
    800050c8:	70a2                	ld	ra,40(sp)
    800050ca:	7402                	ld	s0,32(sp)
    800050cc:	64e2                	ld	s1,24(sp)
    800050ce:	6942                	ld	s2,16(sp)
    800050d0:	6145                	addi	sp,sp,48
    800050d2:	8082                	ret
    return -1;
    800050d4:	557d                	li	a0,-1
    800050d6:	bfcd                	j	800050c8 <argfd+0x50>
    return -1;
    800050d8:	557d                	li	a0,-1
    800050da:	b7fd                	j	800050c8 <argfd+0x50>
    800050dc:	557d                	li	a0,-1
    800050de:	b7ed                	j	800050c8 <argfd+0x50>

00000000800050e0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050e0:	1101                	addi	sp,sp,-32
    800050e2:	ec06                	sd	ra,24(sp)
    800050e4:	e822                	sd	s0,16(sp)
    800050e6:	e426                	sd	s1,8(sp)
    800050e8:	1000                	addi	s0,sp,32
    800050ea:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050ec:	ffffd097          	auipc	ra,0xffffd
    800050f0:	902080e7          	jalr	-1790(ra) # 800019ee <myproc>
    800050f4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050f6:	0d050793          	addi	a5,a0,208
    800050fa:	4501                	li	a0,0
    800050fc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050fe:	6398                	ld	a4,0(a5)
    80005100:	cb19                	beqz	a4,80005116 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005102:	2505                	addiw	a0,a0,1
    80005104:	07a1                	addi	a5,a5,8
    80005106:	fed51ce3          	bne	a0,a3,800050fe <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000510a:	557d                	li	a0,-1
}
    8000510c:	60e2                	ld	ra,24(sp)
    8000510e:	6442                	ld	s0,16(sp)
    80005110:	64a2                	ld	s1,8(sp)
    80005112:	6105                	addi	sp,sp,32
    80005114:	8082                	ret
      p->ofile[fd] = f;
    80005116:	01a50793          	addi	a5,a0,26
    8000511a:	078e                	slli	a5,a5,0x3
    8000511c:	963e                	add	a2,a2,a5
    8000511e:	e204                	sd	s1,0(a2)
      return fd;
    80005120:	b7f5                	j	8000510c <fdalloc+0x2c>

0000000080005122 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005122:	715d                	addi	sp,sp,-80
    80005124:	e486                	sd	ra,72(sp)
    80005126:	e0a2                	sd	s0,64(sp)
    80005128:	fc26                	sd	s1,56(sp)
    8000512a:	f84a                	sd	s2,48(sp)
    8000512c:	f44e                	sd	s3,40(sp)
    8000512e:	f052                	sd	s4,32(sp)
    80005130:	ec56                	sd	s5,24(sp)
    80005132:	0880                	addi	s0,sp,80
    80005134:	89ae                	mv	s3,a1
    80005136:	8ab2                	mv	s5,a2
    80005138:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000513a:	fb040593          	addi	a1,s0,-80
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	e4c080e7          	jalr	-436(ra) # 80003f8a <nameiparent>
    80005146:	892a                	mv	s2,a0
    80005148:	12050e63          	beqz	a0,80005284 <create+0x162>
    return 0;

  ilock(dp);
    8000514c:	ffffe097          	auipc	ra,0xffffe
    80005150:	670080e7          	jalr	1648(ra) # 800037bc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005154:	4601                	li	a2,0
    80005156:	fb040593          	addi	a1,s0,-80
    8000515a:	854a                	mv	a0,s2
    8000515c:	fffff097          	auipc	ra,0xfffff
    80005160:	b3e080e7          	jalr	-1218(ra) # 80003c9a <dirlookup>
    80005164:	84aa                	mv	s1,a0
    80005166:	c921                	beqz	a0,800051b6 <create+0x94>
    iunlockput(dp);
    80005168:	854a                	mv	a0,s2
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	8b4080e7          	jalr	-1868(ra) # 80003a1e <iunlockput>
    ilock(ip);
    80005172:	8526                	mv	a0,s1
    80005174:	ffffe097          	auipc	ra,0xffffe
    80005178:	648080e7          	jalr	1608(ra) # 800037bc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000517c:	2981                	sext.w	s3,s3
    8000517e:	4789                	li	a5,2
    80005180:	02f99463          	bne	s3,a5,800051a8 <create+0x86>
    80005184:	0444d783          	lhu	a5,68(s1)
    80005188:	37f9                	addiw	a5,a5,-2
    8000518a:	17c2                	slli	a5,a5,0x30
    8000518c:	93c1                	srli	a5,a5,0x30
    8000518e:	4705                	li	a4,1
    80005190:	00f76c63          	bltu	a4,a5,800051a8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005194:	8526                	mv	a0,s1
    80005196:	60a6                	ld	ra,72(sp)
    80005198:	6406                	ld	s0,64(sp)
    8000519a:	74e2                	ld	s1,56(sp)
    8000519c:	7942                	ld	s2,48(sp)
    8000519e:	79a2                	ld	s3,40(sp)
    800051a0:	7a02                	ld	s4,32(sp)
    800051a2:	6ae2                	ld	s5,24(sp)
    800051a4:	6161                	addi	sp,sp,80
    800051a6:	8082                	ret
    iunlockput(ip);
    800051a8:	8526                	mv	a0,s1
    800051aa:	fffff097          	auipc	ra,0xfffff
    800051ae:	874080e7          	jalr	-1932(ra) # 80003a1e <iunlockput>
    return 0;
    800051b2:	4481                	li	s1,0
    800051b4:	b7c5                	j	80005194 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051b6:	85ce                	mv	a1,s3
    800051b8:	00092503          	lw	a0,0(s2)
    800051bc:	ffffe097          	auipc	ra,0xffffe
    800051c0:	468080e7          	jalr	1128(ra) # 80003624 <ialloc>
    800051c4:	84aa                	mv	s1,a0
    800051c6:	c521                	beqz	a0,8000520e <create+0xec>
  ilock(ip);
    800051c8:	ffffe097          	auipc	ra,0xffffe
    800051cc:	5f4080e7          	jalr	1524(ra) # 800037bc <ilock>
  ip->major = major;
    800051d0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051d4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051d8:	4a05                	li	s4,1
    800051da:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800051de:	8526                	mv	a0,s1
    800051e0:	ffffe097          	auipc	ra,0xffffe
    800051e4:	512080e7          	jalr	1298(ra) # 800036f2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051e8:	2981                	sext.w	s3,s3
    800051ea:	03498a63          	beq	s3,s4,8000521e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800051ee:	40d0                	lw	a2,4(s1)
    800051f0:	fb040593          	addi	a1,s0,-80
    800051f4:	854a                	mv	a0,s2
    800051f6:	fffff097          	auipc	ra,0xfffff
    800051fa:	cb4080e7          	jalr	-844(ra) # 80003eaa <dirlink>
    800051fe:	06054b63          	bltz	a0,80005274 <create+0x152>
  iunlockput(dp);
    80005202:	854a                	mv	a0,s2
    80005204:	fffff097          	auipc	ra,0xfffff
    80005208:	81a080e7          	jalr	-2022(ra) # 80003a1e <iunlockput>
  return ip;
    8000520c:	b761                	j	80005194 <create+0x72>
    panic("create: ialloc");
    8000520e:	00003517          	auipc	a0,0x3
    80005212:	5f250513          	addi	a0,a0,1522 # 80008800 <syscalls+0x2b8>
    80005216:	ffffb097          	auipc	ra,0xffffb
    8000521a:	32c080e7          	jalr	812(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    8000521e:	04a95783          	lhu	a5,74(s2)
    80005222:	2785                	addiw	a5,a5,1
    80005224:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005228:	854a                	mv	a0,s2
    8000522a:	ffffe097          	auipc	ra,0xffffe
    8000522e:	4c8080e7          	jalr	1224(ra) # 800036f2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005232:	40d0                	lw	a2,4(s1)
    80005234:	00003597          	auipc	a1,0x3
    80005238:	5dc58593          	addi	a1,a1,1500 # 80008810 <syscalls+0x2c8>
    8000523c:	8526                	mv	a0,s1
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	c6c080e7          	jalr	-916(ra) # 80003eaa <dirlink>
    80005246:	00054f63          	bltz	a0,80005264 <create+0x142>
    8000524a:	00492603          	lw	a2,4(s2)
    8000524e:	00003597          	auipc	a1,0x3
    80005252:	5ca58593          	addi	a1,a1,1482 # 80008818 <syscalls+0x2d0>
    80005256:	8526                	mv	a0,s1
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	c52080e7          	jalr	-942(ra) # 80003eaa <dirlink>
    80005260:	f80557e3          	bgez	a0,800051ee <create+0xcc>
      panic("create dots");
    80005264:	00003517          	auipc	a0,0x3
    80005268:	5bc50513          	addi	a0,a0,1468 # 80008820 <syscalls+0x2d8>
    8000526c:	ffffb097          	auipc	ra,0xffffb
    80005270:	2d6080e7          	jalr	726(ra) # 80000542 <panic>
    panic("create: dirlink");
    80005274:	00003517          	auipc	a0,0x3
    80005278:	5bc50513          	addi	a0,a0,1468 # 80008830 <syscalls+0x2e8>
    8000527c:	ffffb097          	auipc	ra,0xffffb
    80005280:	2c6080e7          	jalr	710(ra) # 80000542 <panic>
    return 0;
    80005284:	84aa                	mv	s1,a0
    80005286:	b739                	j	80005194 <create+0x72>

0000000080005288 <sys_dup>:
{
    80005288:	7179                	addi	sp,sp,-48
    8000528a:	f406                	sd	ra,40(sp)
    8000528c:	f022                	sd	s0,32(sp)
    8000528e:	ec26                	sd	s1,24(sp)
    80005290:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005292:	fd840613          	addi	a2,s0,-40
    80005296:	4581                	li	a1,0
    80005298:	4501                	li	a0,0
    8000529a:	00000097          	auipc	ra,0x0
    8000529e:	dde080e7          	jalr	-546(ra) # 80005078 <argfd>
    return -1;
    800052a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052a4:	02054363          	bltz	a0,800052ca <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052a8:	fd843503          	ld	a0,-40(s0)
    800052ac:	00000097          	auipc	ra,0x0
    800052b0:	e34080e7          	jalr	-460(ra) # 800050e0 <fdalloc>
    800052b4:	84aa                	mv	s1,a0
    return -1;
    800052b6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052b8:	00054963          	bltz	a0,800052ca <sys_dup+0x42>
  filedup(f);
    800052bc:	fd843503          	ld	a0,-40(s0)
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	338080e7          	jalr	824(ra) # 800045f8 <filedup>
  return fd;
    800052c8:	87a6                	mv	a5,s1
}
    800052ca:	853e                	mv	a0,a5
    800052cc:	70a2                	ld	ra,40(sp)
    800052ce:	7402                	ld	s0,32(sp)
    800052d0:	64e2                	ld	s1,24(sp)
    800052d2:	6145                	addi	sp,sp,48
    800052d4:	8082                	ret

00000000800052d6 <sys_read>:
{
    800052d6:	7179                	addi	sp,sp,-48
    800052d8:	f406                	sd	ra,40(sp)
    800052da:	f022                	sd	s0,32(sp)
    800052dc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052de:	fe840613          	addi	a2,s0,-24
    800052e2:	4581                	li	a1,0
    800052e4:	4501                	li	a0,0
    800052e6:	00000097          	auipc	ra,0x0
    800052ea:	d92080e7          	jalr	-622(ra) # 80005078 <argfd>
    return -1;
    800052ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f0:	04054163          	bltz	a0,80005332 <sys_read+0x5c>
    800052f4:	fe440593          	addi	a1,s0,-28
    800052f8:	4509                	li	a0,2
    800052fa:	ffffe097          	auipc	ra,0xffffe
    800052fe:	868080e7          	jalr	-1944(ra) # 80002b62 <argint>
    return -1;
    80005302:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005304:	02054763          	bltz	a0,80005332 <sys_read+0x5c>
    80005308:	fd840593          	addi	a1,s0,-40
    8000530c:	4505                	li	a0,1
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	876080e7          	jalr	-1930(ra) # 80002b84 <argaddr>
    return -1;
    80005316:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005318:	00054d63          	bltz	a0,80005332 <sys_read+0x5c>
  return fileread(f, p, n);
    8000531c:	fe442603          	lw	a2,-28(s0)
    80005320:	fd843583          	ld	a1,-40(s0)
    80005324:	fe843503          	ld	a0,-24(s0)
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	45c080e7          	jalr	1116(ra) # 80004784 <fileread>
    80005330:	87aa                	mv	a5,a0
}
    80005332:	853e                	mv	a0,a5
    80005334:	70a2                	ld	ra,40(sp)
    80005336:	7402                	ld	s0,32(sp)
    80005338:	6145                	addi	sp,sp,48
    8000533a:	8082                	ret

000000008000533c <sys_write>:
{
    8000533c:	7179                	addi	sp,sp,-48
    8000533e:	f406                	sd	ra,40(sp)
    80005340:	f022                	sd	s0,32(sp)
    80005342:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005344:	fe840613          	addi	a2,s0,-24
    80005348:	4581                	li	a1,0
    8000534a:	4501                	li	a0,0
    8000534c:	00000097          	auipc	ra,0x0
    80005350:	d2c080e7          	jalr	-724(ra) # 80005078 <argfd>
    return -1;
    80005354:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005356:	04054163          	bltz	a0,80005398 <sys_write+0x5c>
    8000535a:	fe440593          	addi	a1,s0,-28
    8000535e:	4509                	li	a0,2
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	802080e7          	jalr	-2046(ra) # 80002b62 <argint>
    return -1;
    80005368:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000536a:	02054763          	bltz	a0,80005398 <sys_write+0x5c>
    8000536e:	fd840593          	addi	a1,s0,-40
    80005372:	4505                	li	a0,1
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	810080e7          	jalr	-2032(ra) # 80002b84 <argaddr>
    return -1;
    8000537c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537e:	00054d63          	bltz	a0,80005398 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005382:	fe442603          	lw	a2,-28(s0)
    80005386:	fd843583          	ld	a1,-40(s0)
    8000538a:	fe843503          	ld	a0,-24(s0)
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	4b8080e7          	jalr	1208(ra) # 80004846 <filewrite>
    80005396:	87aa                	mv	a5,a0
}
    80005398:	853e                	mv	a0,a5
    8000539a:	70a2                	ld	ra,40(sp)
    8000539c:	7402                	ld	s0,32(sp)
    8000539e:	6145                	addi	sp,sp,48
    800053a0:	8082                	ret

00000000800053a2 <sys_close>:
{
    800053a2:	1101                	addi	sp,sp,-32
    800053a4:	ec06                	sd	ra,24(sp)
    800053a6:	e822                	sd	s0,16(sp)
    800053a8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053aa:	fe040613          	addi	a2,s0,-32
    800053ae:	fec40593          	addi	a1,s0,-20
    800053b2:	4501                	li	a0,0
    800053b4:	00000097          	auipc	ra,0x0
    800053b8:	cc4080e7          	jalr	-828(ra) # 80005078 <argfd>
    return -1;
    800053bc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053be:	02054463          	bltz	a0,800053e6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053c2:	ffffc097          	auipc	ra,0xffffc
    800053c6:	62c080e7          	jalr	1580(ra) # 800019ee <myproc>
    800053ca:	fec42783          	lw	a5,-20(s0)
    800053ce:	07e9                	addi	a5,a5,26
    800053d0:	078e                	slli	a5,a5,0x3
    800053d2:	97aa                	add	a5,a5,a0
    800053d4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053d8:	fe043503          	ld	a0,-32(s0)
    800053dc:	fffff097          	auipc	ra,0xfffff
    800053e0:	26e080e7          	jalr	622(ra) # 8000464a <fileclose>
  return 0;
    800053e4:	4781                	li	a5,0
}
    800053e6:	853e                	mv	a0,a5
    800053e8:	60e2                	ld	ra,24(sp)
    800053ea:	6442                	ld	s0,16(sp)
    800053ec:	6105                	addi	sp,sp,32
    800053ee:	8082                	ret

00000000800053f0 <sys_fstat>:
{
    800053f0:	1101                	addi	sp,sp,-32
    800053f2:	ec06                	sd	ra,24(sp)
    800053f4:	e822                	sd	s0,16(sp)
    800053f6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053f8:	fe840613          	addi	a2,s0,-24
    800053fc:	4581                	li	a1,0
    800053fe:	4501                	li	a0,0
    80005400:	00000097          	auipc	ra,0x0
    80005404:	c78080e7          	jalr	-904(ra) # 80005078 <argfd>
    return -1;
    80005408:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000540a:	02054563          	bltz	a0,80005434 <sys_fstat+0x44>
    8000540e:	fe040593          	addi	a1,s0,-32
    80005412:	4505                	li	a0,1
    80005414:	ffffd097          	auipc	ra,0xffffd
    80005418:	770080e7          	jalr	1904(ra) # 80002b84 <argaddr>
    return -1;
    8000541c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000541e:	00054b63          	bltz	a0,80005434 <sys_fstat+0x44>
  return filestat(f, st);
    80005422:	fe043583          	ld	a1,-32(s0)
    80005426:	fe843503          	ld	a0,-24(s0)
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	2e8080e7          	jalr	744(ra) # 80004712 <filestat>
    80005432:	87aa                	mv	a5,a0
}
    80005434:	853e                	mv	a0,a5
    80005436:	60e2                	ld	ra,24(sp)
    80005438:	6442                	ld	s0,16(sp)
    8000543a:	6105                	addi	sp,sp,32
    8000543c:	8082                	ret

000000008000543e <sys_link>:
{
    8000543e:	7169                	addi	sp,sp,-304
    80005440:	f606                	sd	ra,296(sp)
    80005442:	f222                	sd	s0,288(sp)
    80005444:	ee26                	sd	s1,280(sp)
    80005446:	ea4a                	sd	s2,272(sp)
    80005448:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000544a:	08000613          	li	a2,128
    8000544e:	ed040593          	addi	a1,s0,-304
    80005452:	4501                	li	a0,0
    80005454:	ffffd097          	auipc	ra,0xffffd
    80005458:	752080e7          	jalr	1874(ra) # 80002ba6 <argstr>
    return -1;
    8000545c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000545e:	10054e63          	bltz	a0,8000557a <sys_link+0x13c>
    80005462:	08000613          	li	a2,128
    80005466:	f5040593          	addi	a1,s0,-176
    8000546a:	4505                	li	a0,1
    8000546c:	ffffd097          	auipc	ra,0xffffd
    80005470:	73a080e7          	jalr	1850(ra) # 80002ba6 <argstr>
    return -1;
    80005474:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005476:	10054263          	bltz	a0,8000557a <sys_link+0x13c>
  begin_op();
    8000547a:	fffff097          	auipc	ra,0xfffff
    8000547e:	cfe080e7          	jalr	-770(ra) # 80004178 <begin_op>
  if((ip = namei(old)) == 0){
    80005482:	ed040513          	addi	a0,s0,-304
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	ae6080e7          	jalr	-1306(ra) # 80003f6c <namei>
    8000548e:	84aa                	mv	s1,a0
    80005490:	c551                	beqz	a0,8000551c <sys_link+0xde>
  ilock(ip);
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	32a080e7          	jalr	810(ra) # 800037bc <ilock>
  if(ip->type == T_DIR){
    8000549a:	04449703          	lh	a4,68(s1)
    8000549e:	4785                	li	a5,1
    800054a0:	08f70463          	beq	a4,a5,80005528 <sys_link+0xea>
  ip->nlink++;
    800054a4:	04a4d783          	lhu	a5,74(s1)
    800054a8:	2785                	addiw	a5,a5,1
    800054aa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ae:	8526                	mv	a0,s1
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	242080e7          	jalr	578(ra) # 800036f2 <iupdate>
  iunlock(ip);
    800054b8:	8526                	mv	a0,s1
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	3c4080e7          	jalr	964(ra) # 8000387e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054c2:	fd040593          	addi	a1,s0,-48
    800054c6:	f5040513          	addi	a0,s0,-176
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	ac0080e7          	jalr	-1344(ra) # 80003f8a <nameiparent>
    800054d2:	892a                	mv	s2,a0
    800054d4:	c935                	beqz	a0,80005548 <sys_link+0x10a>
  ilock(dp);
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	2e6080e7          	jalr	742(ra) # 800037bc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054de:	00092703          	lw	a4,0(s2)
    800054e2:	409c                	lw	a5,0(s1)
    800054e4:	04f71d63          	bne	a4,a5,8000553e <sys_link+0x100>
    800054e8:	40d0                	lw	a2,4(s1)
    800054ea:	fd040593          	addi	a1,s0,-48
    800054ee:	854a                	mv	a0,s2
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	9ba080e7          	jalr	-1606(ra) # 80003eaa <dirlink>
    800054f8:	04054363          	bltz	a0,8000553e <sys_link+0x100>
  iunlockput(dp);
    800054fc:	854a                	mv	a0,s2
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	520080e7          	jalr	1312(ra) # 80003a1e <iunlockput>
  iput(ip);
    80005506:	8526                	mv	a0,s1
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	46e080e7          	jalr	1134(ra) # 80003976 <iput>
  end_op();
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	ce8080e7          	jalr	-792(ra) # 800041f8 <end_op>
  return 0;
    80005518:	4781                	li	a5,0
    8000551a:	a085                	j	8000557a <sys_link+0x13c>
    end_op();
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	cdc080e7          	jalr	-804(ra) # 800041f8 <end_op>
    return -1;
    80005524:	57fd                	li	a5,-1
    80005526:	a891                	j	8000557a <sys_link+0x13c>
    iunlockput(ip);
    80005528:	8526                	mv	a0,s1
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	4f4080e7          	jalr	1268(ra) # 80003a1e <iunlockput>
    end_op();
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	cc6080e7          	jalr	-826(ra) # 800041f8 <end_op>
    return -1;
    8000553a:	57fd                	li	a5,-1
    8000553c:	a83d                	j	8000557a <sys_link+0x13c>
    iunlockput(dp);
    8000553e:	854a                	mv	a0,s2
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	4de080e7          	jalr	1246(ra) # 80003a1e <iunlockput>
  ilock(ip);
    80005548:	8526                	mv	a0,s1
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	272080e7          	jalr	626(ra) # 800037bc <ilock>
  ip->nlink--;
    80005552:	04a4d783          	lhu	a5,74(s1)
    80005556:	37fd                	addiw	a5,a5,-1
    80005558:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000555c:	8526                	mv	a0,s1
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	194080e7          	jalr	404(ra) # 800036f2 <iupdate>
  iunlockput(ip);
    80005566:	8526                	mv	a0,s1
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	4b6080e7          	jalr	1206(ra) # 80003a1e <iunlockput>
  end_op();
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	c88080e7          	jalr	-888(ra) # 800041f8 <end_op>
  return -1;
    80005578:	57fd                	li	a5,-1
}
    8000557a:	853e                	mv	a0,a5
    8000557c:	70b2                	ld	ra,296(sp)
    8000557e:	7412                	ld	s0,288(sp)
    80005580:	64f2                	ld	s1,280(sp)
    80005582:	6952                	ld	s2,272(sp)
    80005584:	6155                	addi	sp,sp,304
    80005586:	8082                	ret

0000000080005588 <sys_unlink>:
{
    80005588:	7151                	addi	sp,sp,-240
    8000558a:	f586                	sd	ra,232(sp)
    8000558c:	f1a2                	sd	s0,224(sp)
    8000558e:	eda6                	sd	s1,216(sp)
    80005590:	e9ca                	sd	s2,208(sp)
    80005592:	e5ce                	sd	s3,200(sp)
    80005594:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005596:	08000613          	li	a2,128
    8000559a:	f3040593          	addi	a1,s0,-208
    8000559e:	4501                	li	a0,0
    800055a0:	ffffd097          	auipc	ra,0xffffd
    800055a4:	606080e7          	jalr	1542(ra) # 80002ba6 <argstr>
    800055a8:	18054163          	bltz	a0,8000572a <sys_unlink+0x1a2>
  begin_op();
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	bcc080e7          	jalr	-1076(ra) # 80004178 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055b4:	fb040593          	addi	a1,s0,-80
    800055b8:	f3040513          	addi	a0,s0,-208
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	9ce080e7          	jalr	-1586(ra) # 80003f8a <nameiparent>
    800055c4:	84aa                	mv	s1,a0
    800055c6:	c979                	beqz	a0,8000569c <sys_unlink+0x114>
  ilock(dp);
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	1f4080e7          	jalr	500(ra) # 800037bc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055d0:	00003597          	auipc	a1,0x3
    800055d4:	24058593          	addi	a1,a1,576 # 80008810 <syscalls+0x2c8>
    800055d8:	fb040513          	addi	a0,s0,-80
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	6a4080e7          	jalr	1700(ra) # 80003c80 <namecmp>
    800055e4:	14050a63          	beqz	a0,80005738 <sys_unlink+0x1b0>
    800055e8:	00003597          	auipc	a1,0x3
    800055ec:	23058593          	addi	a1,a1,560 # 80008818 <syscalls+0x2d0>
    800055f0:	fb040513          	addi	a0,s0,-80
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	68c080e7          	jalr	1676(ra) # 80003c80 <namecmp>
    800055fc:	12050e63          	beqz	a0,80005738 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005600:	f2c40613          	addi	a2,s0,-212
    80005604:	fb040593          	addi	a1,s0,-80
    80005608:	8526                	mv	a0,s1
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	690080e7          	jalr	1680(ra) # 80003c9a <dirlookup>
    80005612:	892a                	mv	s2,a0
    80005614:	12050263          	beqz	a0,80005738 <sys_unlink+0x1b0>
  ilock(ip);
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	1a4080e7          	jalr	420(ra) # 800037bc <ilock>
  if(ip->nlink < 1)
    80005620:	04a91783          	lh	a5,74(s2)
    80005624:	08f05263          	blez	a5,800056a8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005628:	04491703          	lh	a4,68(s2)
    8000562c:	4785                	li	a5,1
    8000562e:	08f70563          	beq	a4,a5,800056b8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005632:	4641                	li	a2,16
    80005634:	4581                	li	a1,0
    80005636:	fc040513          	addi	a0,s0,-64
    8000563a:	ffffb097          	auipc	ra,0xffffb
    8000563e:	6e4080e7          	jalr	1764(ra) # 80000d1e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005642:	4741                	li	a4,16
    80005644:	f2c42683          	lw	a3,-212(s0)
    80005648:	fc040613          	addi	a2,s0,-64
    8000564c:	4581                	li	a1,0
    8000564e:	8526                	mv	a0,s1
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	516080e7          	jalr	1302(ra) # 80003b66 <writei>
    80005658:	47c1                	li	a5,16
    8000565a:	0af51563          	bne	a0,a5,80005704 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000565e:	04491703          	lh	a4,68(s2)
    80005662:	4785                	li	a5,1
    80005664:	0af70863          	beq	a4,a5,80005714 <sys_unlink+0x18c>
  iunlockput(dp);
    80005668:	8526                	mv	a0,s1
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	3b4080e7          	jalr	948(ra) # 80003a1e <iunlockput>
  ip->nlink--;
    80005672:	04a95783          	lhu	a5,74(s2)
    80005676:	37fd                	addiw	a5,a5,-1
    80005678:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000567c:	854a                	mv	a0,s2
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	074080e7          	jalr	116(ra) # 800036f2 <iupdate>
  iunlockput(ip);
    80005686:	854a                	mv	a0,s2
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	396080e7          	jalr	918(ra) # 80003a1e <iunlockput>
  end_op();
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	b68080e7          	jalr	-1176(ra) # 800041f8 <end_op>
  return 0;
    80005698:	4501                	li	a0,0
    8000569a:	a84d                	j	8000574c <sys_unlink+0x1c4>
    end_op();
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	b5c080e7          	jalr	-1188(ra) # 800041f8 <end_op>
    return -1;
    800056a4:	557d                	li	a0,-1
    800056a6:	a05d                	j	8000574c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056a8:	00003517          	auipc	a0,0x3
    800056ac:	19850513          	addi	a0,a0,408 # 80008840 <syscalls+0x2f8>
    800056b0:	ffffb097          	auipc	ra,0xffffb
    800056b4:	e92080e7          	jalr	-366(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b8:	04c92703          	lw	a4,76(s2)
    800056bc:	02000793          	li	a5,32
    800056c0:	f6e7f9e3          	bgeu	a5,a4,80005632 <sys_unlink+0xaa>
    800056c4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056c8:	4741                	li	a4,16
    800056ca:	86ce                	mv	a3,s3
    800056cc:	f1840613          	addi	a2,s0,-232
    800056d0:	4581                	li	a1,0
    800056d2:	854a                	mv	a0,s2
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	39c080e7          	jalr	924(ra) # 80003a70 <readi>
    800056dc:	47c1                	li	a5,16
    800056de:	00f51b63          	bne	a0,a5,800056f4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056e2:	f1845783          	lhu	a5,-232(s0)
    800056e6:	e7a1                	bnez	a5,8000572e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056e8:	29c1                	addiw	s3,s3,16
    800056ea:	04c92783          	lw	a5,76(s2)
    800056ee:	fcf9ede3          	bltu	s3,a5,800056c8 <sys_unlink+0x140>
    800056f2:	b781                	j	80005632 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056f4:	00003517          	auipc	a0,0x3
    800056f8:	16450513          	addi	a0,a0,356 # 80008858 <syscalls+0x310>
    800056fc:	ffffb097          	auipc	ra,0xffffb
    80005700:	e46080e7          	jalr	-442(ra) # 80000542 <panic>
    panic("unlink: writei");
    80005704:	00003517          	auipc	a0,0x3
    80005708:	16c50513          	addi	a0,a0,364 # 80008870 <syscalls+0x328>
    8000570c:	ffffb097          	auipc	ra,0xffffb
    80005710:	e36080e7          	jalr	-458(ra) # 80000542 <panic>
    dp->nlink--;
    80005714:	04a4d783          	lhu	a5,74(s1)
    80005718:	37fd                	addiw	a5,a5,-1
    8000571a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000571e:	8526                	mv	a0,s1
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	fd2080e7          	jalr	-46(ra) # 800036f2 <iupdate>
    80005728:	b781                	j	80005668 <sys_unlink+0xe0>
    return -1;
    8000572a:	557d                	li	a0,-1
    8000572c:	a005                	j	8000574c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000572e:	854a                	mv	a0,s2
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	2ee080e7          	jalr	750(ra) # 80003a1e <iunlockput>
  iunlockput(dp);
    80005738:	8526                	mv	a0,s1
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	2e4080e7          	jalr	740(ra) # 80003a1e <iunlockput>
  end_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	ab6080e7          	jalr	-1354(ra) # 800041f8 <end_op>
  return -1;
    8000574a:	557d                	li	a0,-1
}
    8000574c:	70ae                	ld	ra,232(sp)
    8000574e:	740e                	ld	s0,224(sp)
    80005750:	64ee                	ld	s1,216(sp)
    80005752:	694e                	ld	s2,208(sp)
    80005754:	69ae                	ld	s3,200(sp)
    80005756:	616d                	addi	sp,sp,240
    80005758:	8082                	ret

000000008000575a <sys_open>:

uint64
sys_open(void)
{
    8000575a:	7131                	addi	sp,sp,-192
    8000575c:	fd06                	sd	ra,184(sp)
    8000575e:	f922                	sd	s0,176(sp)
    80005760:	f526                	sd	s1,168(sp)
    80005762:	f14a                	sd	s2,160(sp)
    80005764:	ed4e                	sd	s3,152(sp)
    80005766:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005768:	08000613          	li	a2,128
    8000576c:	f5040593          	addi	a1,s0,-176
    80005770:	4501                	li	a0,0
    80005772:	ffffd097          	auipc	ra,0xffffd
    80005776:	434080e7          	jalr	1076(ra) # 80002ba6 <argstr>
    return -1;
    8000577a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000577c:	0c054163          	bltz	a0,8000583e <sys_open+0xe4>
    80005780:	f4c40593          	addi	a1,s0,-180
    80005784:	4505                	li	a0,1
    80005786:	ffffd097          	auipc	ra,0xffffd
    8000578a:	3dc080e7          	jalr	988(ra) # 80002b62 <argint>
    8000578e:	0a054863          	bltz	a0,8000583e <sys_open+0xe4>

  begin_op();
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	9e6080e7          	jalr	-1562(ra) # 80004178 <begin_op>

  if(omode & O_CREATE){
    8000579a:	f4c42783          	lw	a5,-180(s0)
    8000579e:	2007f793          	andi	a5,a5,512
    800057a2:	cbdd                	beqz	a5,80005858 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057a4:	4681                	li	a3,0
    800057a6:	4601                	li	a2,0
    800057a8:	4589                	li	a1,2
    800057aa:	f5040513          	addi	a0,s0,-176
    800057ae:	00000097          	auipc	ra,0x0
    800057b2:	974080e7          	jalr	-1676(ra) # 80005122 <create>
    800057b6:	892a                	mv	s2,a0
    if(ip == 0){
    800057b8:	c959                	beqz	a0,8000584e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057ba:	04491703          	lh	a4,68(s2)
    800057be:	478d                	li	a5,3
    800057c0:	00f71763          	bne	a4,a5,800057ce <sys_open+0x74>
    800057c4:	04695703          	lhu	a4,70(s2)
    800057c8:	47a5                	li	a5,9
    800057ca:	0ce7ec63          	bltu	a5,a4,800058a2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	dc0080e7          	jalr	-576(ra) # 8000458e <filealloc>
    800057d6:	89aa                	mv	s3,a0
    800057d8:	10050263          	beqz	a0,800058dc <sys_open+0x182>
    800057dc:	00000097          	auipc	ra,0x0
    800057e0:	904080e7          	jalr	-1788(ra) # 800050e0 <fdalloc>
    800057e4:	84aa                	mv	s1,a0
    800057e6:	0e054663          	bltz	a0,800058d2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057ea:	04491703          	lh	a4,68(s2)
    800057ee:	478d                	li	a5,3
    800057f0:	0cf70463          	beq	a4,a5,800058b8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057f4:	4789                	li	a5,2
    800057f6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057fa:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057fe:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005802:	f4c42783          	lw	a5,-180(s0)
    80005806:	0017c713          	xori	a4,a5,1
    8000580a:	8b05                	andi	a4,a4,1
    8000580c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005810:	0037f713          	andi	a4,a5,3
    80005814:	00e03733          	snez	a4,a4
    80005818:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000581c:	4007f793          	andi	a5,a5,1024
    80005820:	c791                	beqz	a5,8000582c <sys_open+0xd2>
    80005822:	04491703          	lh	a4,68(s2)
    80005826:	4789                	li	a5,2
    80005828:	08f70f63          	beq	a4,a5,800058c6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000582c:	854a                	mv	a0,s2
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	050080e7          	jalr	80(ra) # 8000387e <iunlock>
  end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	9c2080e7          	jalr	-1598(ra) # 800041f8 <end_op>

  return fd;
}
    8000583e:	8526                	mv	a0,s1
    80005840:	70ea                	ld	ra,184(sp)
    80005842:	744a                	ld	s0,176(sp)
    80005844:	74aa                	ld	s1,168(sp)
    80005846:	790a                	ld	s2,160(sp)
    80005848:	69ea                	ld	s3,152(sp)
    8000584a:	6129                	addi	sp,sp,192
    8000584c:	8082                	ret
      end_op();
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	9aa080e7          	jalr	-1622(ra) # 800041f8 <end_op>
      return -1;
    80005856:	b7e5                	j	8000583e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005858:	f5040513          	addi	a0,s0,-176
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	710080e7          	jalr	1808(ra) # 80003f6c <namei>
    80005864:	892a                	mv	s2,a0
    80005866:	c905                	beqz	a0,80005896 <sys_open+0x13c>
    ilock(ip);
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	f54080e7          	jalr	-172(ra) # 800037bc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005870:	04491703          	lh	a4,68(s2)
    80005874:	4785                	li	a5,1
    80005876:	f4f712e3          	bne	a4,a5,800057ba <sys_open+0x60>
    8000587a:	f4c42783          	lw	a5,-180(s0)
    8000587e:	dba1                	beqz	a5,800057ce <sys_open+0x74>
      iunlockput(ip);
    80005880:	854a                	mv	a0,s2
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	19c080e7          	jalr	412(ra) # 80003a1e <iunlockput>
      end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	96e080e7          	jalr	-1682(ra) # 800041f8 <end_op>
      return -1;
    80005892:	54fd                	li	s1,-1
    80005894:	b76d                	j	8000583e <sys_open+0xe4>
      end_op();
    80005896:	fffff097          	auipc	ra,0xfffff
    8000589a:	962080e7          	jalr	-1694(ra) # 800041f8 <end_op>
      return -1;
    8000589e:	54fd                	li	s1,-1
    800058a0:	bf79                	j	8000583e <sys_open+0xe4>
    iunlockput(ip);
    800058a2:	854a                	mv	a0,s2
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	17a080e7          	jalr	378(ra) # 80003a1e <iunlockput>
    end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	94c080e7          	jalr	-1716(ra) # 800041f8 <end_op>
    return -1;
    800058b4:	54fd                	li	s1,-1
    800058b6:	b761                	j	8000583e <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058b8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058bc:	04691783          	lh	a5,70(s2)
    800058c0:	02f99223          	sh	a5,36(s3)
    800058c4:	bf2d                	j	800057fe <sys_open+0xa4>
    itrunc(ip);
    800058c6:	854a                	mv	a0,s2
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	002080e7          	jalr	2(ra) # 800038ca <itrunc>
    800058d0:	bfb1                	j	8000582c <sys_open+0xd2>
      fileclose(f);
    800058d2:	854e                	mv	a0,s3
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	d76080e7          	jalr	-650(ra) # 8000464a <fileclose>
    iunlockput(ip);
    800058dc:	854a                	mv	a0,s2
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	140080e7          	jalr	320(ra) # 80003a1e <iunlockput>
    end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	912080e7          	jalr	-1774(ra) # 800041f8 <end_op>
    return -1;
    800058ee:	54fd                	li	s1,-1
    800058f0:	b7b9                	j	8000583e <sys_open+0xe4>

00000000800058f2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058f2:	7175                	addi	sp,sp,-144
    800058f4:	e506                	sd	ra,136(sp)
    800058f6:	e122                	sd	s0,128(sp)
    800058f8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	87e080e7          	jalr	-1922(ra) # 80004178 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005902:	08000613          	li	a2,128
    80005906:	f7040593          	addi	a1,s0,-144
    8000590a:	4501                	li	a0,0
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	29a080e7          	jalr	666(ra) # 80002ba6 <argstr>
    80005914:	02054963          	bltz	a0,80005946 <sys_mkdir+0x54>
    80005918:	4681                	li	a3,0
    8000591a:	4601                	li	a2,0
    8000591c:	4585                	li	a1,1
    8000591e:	f7040513          	addi	a0,s0,-144
    80005922:	00000097          	auipc	ra,0x0
    80005926:	800080e7          	jalr	-2048(ra) # 80005122 <create>
    8000592a:	cd11                	beqz	a0,80005946 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	0f2080e7          	jalr	242(ra) # 80003a1e <iunlockput>
  end_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	8c4080e7          	jalr	-1852(ra) # 800041f8 <end_op>
  return 0;
    8000593c:	4501                	li	a0,0
}
    8000593e:	60aa                	ld	ra,136(sp)
    80005940:	640a                	ld	s0,128(sp)
    80005942:	6149                	addi	sp,sp,144
    80005944:	8082                	ret
    end_op();
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	8b2080e7          	jalr	-1870(ra) # 800041f8 <end_op>
    return -1;
    8000594e:	557d                	li	a0,-1
    80005950:	b7fd                	j	8000593e <sys_mkdir+0x4c>

0000000080005952 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005952:	7135                	addi	sp,sp,-160
    80005954:	ed06                	sd	ra,152(sp)
    80005956:	e922                	sd	s0,144(sp)
    80005958:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	81e080e7          	jalr	-2018(ra) # 80004178 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005962:	08000613          	li	a2,128
    80005966:	f7040593          	addi	a1,s0,-144
    8000596a:	4501                	li	a0,0
    8000596c:	ffffd097          	auipc	ra,0xffffd
    80005970:	23a080e7          	jalr	570(ra) # 80002ba6 <argstr>
    80005974:	04054a63          	bltz	a0,800059c8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005978:	f6c40593          	addi	a1,s0,-148
    8000597c:	4505                	li	a0,1
    8000597e:	ffffd097          	auipc	ra,0xffffd
    80005982:	1e4080e7          	jalr	484(ra) # 80002b62 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005986:	04054163          	bltz	a0,800059c8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000598a:	f6840593          	addi	a1,s0,-152
    8000598e:	4509                	li	a0,2
    80005990:	ffffd097          	auipc	ra,0xffffd
    80005994:	1d2080e7          	jalr	466(ra) # 80002b62 <argint>
     argint(1, &major) < 0 ||
    80005998:	02054863          	bltz	a0,800059c8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000599c:	f6841683          	lh	a3,-152(s0)
    800059a0:	f6c41603          	lh	a2,-148(s0)
    800059a4:	458d                	li	a1,3
    800059a6:	f7040513          	addi	a0,s0,-144
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	778080e7          	jalr	1912(ra) # 80005122 <create>
     argint(2, &minor) < 0 ||
    800059b2:	c919                	beqz	a0,800059c8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	06a080e7          	jalr	106(ra) # 80003a1e <iunlockput>
  end_op();
    800059bc:	fffff097          	auipc	ra,0xfffff
    800059c0:	83c080e7          	jalr	-1988(ra) # 800041f8 <end_op>
  return 0;
    800059c4:	4501                	li	a0,0
    800059c6:	a031                	j	800059d2 <sys_mknod+0x80>
    end_op();
    800059c8:	fffff097          	auipc	ra,0xfffff
    800059cc:	830080e7          	jalr	-2000(ra) # 800041f8 <end_op>
    return -1;
    800059d0:	557d                	li	a0,-1
}
    800059d2:	60ea                	ld	ra,152(sp)
    800059d4:	644a                	ld	s0,144(sp)
    800059d6:	610d                	addi	sp,sp,160
    800059d8:	8082                	ret

00000000800059da <sys_chdir>:

uint64
sys_chdir(void)
{
    800059da:	7135                	addi	sp,sp,-160
    800059dc:	ed06                	sd	ra,152(sp)
    800059de:	e922                	sd	s0,144(sp)
    800059e0:	e526                	sd	s1,136(sp)
    800059e2:	e14a                	sd	s2,128(sp)
    800059e4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059e6:	ffffc097          	auipc	ra,0xffffc
    800059ea:	008080e7          	jalr	8(ra) # 800019ee <myproc>
    800059ee:	892a                	mv	s2,a0
  
  begin_op();
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	788080e7          	jalr	1928(ra) # 80004178 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059f8:	08000613          	li	a2,128
    800059fc:	f6040593          	addi	a1,s0,-160
    80005a00:	4501                	li	a0,0
    80005a02:	ffffd097          	auipc	ra,0xffffd
    80005a06:	1a4080e7          	jalr	420(ra) # 80002ba6 <argstr>
    80005a0a:	04054b63          	bltz	a0,80005a60 <sys_chdir+0x86>
    80005a0e:	f6040513          	addi	a0,s0,-160
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	55a080e7          	jalr	1370(ra) # 80003f6c <namei>
    80005a1a:	84aa                	mv	s1,a0
    80005a1c:	c131                	beqz	a0,80005a60 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	d9e080e7          	jalr	-610(ra) # 800037bc <ilock>
  if(ip->type != T_DIR){
    80005a26:	04449703          	lh	a4,68(s1)
    80005a2a:	4785                	li	a5,1
    80005a2c:	04f71063          	bne	a4,a5,80005a6c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a30:	8526                	mv	a0,s1
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	e4c080e7          	jalr	-436(ra) # 8000387e <iunlock>
  iput(p->cwd);
    80005a3a:	15093503          	ld	a0,336(s2)
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	f38080e7          	jalr	-200(ra) # 80003976 <iput>
  end_op();
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	7b2080e7          	jalr	1970(ra) # 800041f8 <end_op>
  p->cwd = ip;
    80005a4e:	14993823          	sd	s1,336(s2)
  return 0;
    80005a52:	4501                	li	a0,0
}
    80005a54:	60ea                	ld	ra,152(sp)
    80005a56:	644a                	ld	s0,144(sp)
    80005a58:	64aa                	ld	s1,136(sp)
    80005a5a:	690a                	ld	s2,128(sp)
    80005a5c:	610d                	addi	sp,sp,160
    80005a5e:	8082                	ret
    end_op();
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	798080e7          	jalr	1944(ra) # 800041f8 <end_op>
    return -1;
    80005a68:	557d                	li	a0,-1
    80005a6a:	b7ed                	j	80005a54 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a6c:	8526                	mv	a0,s1
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	fb0080e7          	jalr	-80(ra) # 80003a1e <iunlockput>
    end_op();
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	782080e7          	jalr	1922(ra) # 800041f8 <end_op>
    return -1;
    80005a7e:	557d                	li	a0,-1
    80005a80:	bfd1                	j	80005a54 <sys_chdir+0x7a>

0000000080005a82 <sys_exec>:

uint64
sys_exec(void)
{
    80005a82:	7145                	addi	sp,sp,-464
    80005a84:	e786                	sd	ra,456(sp)
    80005a86:	e3a2                	sd	s0,448(sp)
    80005a88:	ff26                	sd	s1,440(sp)
    80005a8a:	fb4a                	sd	s2,432(sp)
    80005a8c:	f74e                	sd	s3,424(sp)
    80005a8e:	f352                	sd	s4,416(sp)
    80005a90:	ef56                	sd	s5,408(sp)
    80005a92:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a94:	08000613          	li	a2,128
    80005a98:	f4040593          	addi	a1,s0,-192
    80005a9c:	4501                	li	a0,0
    80005a9e:	ffffd097          	auipc	ra,0xffffd
    80005aa2:	108080e7          	jalr	264(ra) # 80002ba6 <argstr>
    return -1;
    80005aa6:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005aa8:	0c054a63          	bltz	a0,80005b7c <sys_exec+0xfa>
    80005aac:	e3840593          	addi	a1,s0,-456
    80005ab0:	4505                	li	a0,1
    80005ab2:	ffffd097          	auipc	ra,0xffffd
    80005ab6:	0d2080e7          	jalr	210(ra) # 80002b84 <argaddr>
    80005aba:	0c054163          	bltz	a0,80005b7c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005abe:	10000613          	li	a2,256
    80005ac2:	4581                	li	a1,0
    80005ac4:	e4040513          	addi	a0,s0,-448
    80005ac8:	ffffb097          	auipc	ra,0xffffb
    80005acc:	256080e7          	jalr	598(ra) # 80000d1e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ad0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ad4:	89a6                	mv	s3,s1
    80005ad6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ad8:	02000a13          	li	s4,32
    80005adc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ae0:	00391793          	slli	a5,s2,0x3
    80005ae4:	e3040593          	addi	a1,s0,-464
    80005ae8:	e3843503          	ld	a0,-456(s0)
    80005aec:	953e                	add	a0,a0,a5
    80005aee:	ffffd097          	auipc	ra,0xffffd
    80005af2:	fda080e7          	jalr	-38(ra) # 80002ac8 <fetchaddr>
    80005af6:	02054a63          	bltz	a0,80005b2a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005afa:	e3043783          	ld	a5,-464(s0)
    80005afe:	c3b9                	beqz	a5,80005b44 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b00:	ffffb097          	auipc	ra,0xffffb
    80005b04:	00e080e7          	jalr	14(ra) # 80000b0e <kalloc>
    80005b08:	85aa                	mv	a1,a0
    80005b0a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b0e:	cd11                	beqz	a0,80005b2a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b10:	6605                	lui	a2,0x1
    80005b12:	e3043503          	ld	a0,-464(s0)
    80005b16:	ffffd097          	auipc	ra,0xffffd
    80005b1a:	004080e7          	jalr	4(ra) # 80002b1a <fetchstr>
    80005b1e:	00054663          	bltz	a0,80005b2a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b22:	0905                	addi	s2,s2,1
    80005b24:	09a1                	addi	s3,s3,8
    80005b26:	fb491be3          	bne	s2,s4,80005adc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2a:	10048913          	addi	s2,s1,256
    80005b2e:	6088                	ld	a0,0(s1)
    80005b30:	c529                	beqz	a0,80005b7a <sys_exec+0xf8>
    kfree(argv[i]);
    80005b32:	ffffb097          	auipc	ra,0xffffb
    80005b36:	ee0080e7          	jalr	-288(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3a:	04a1                	addi	s1,s1,8
    80005b3c:	ff2499e3          	bne	s1,s2,80005b2e <sys_exec+0xac>
  return -1;
    80005b40:	597d                	li	s2,-1
    80005b42:	a82d                	j	80005b7c <sys_exec+0xfa>
      argv[i] = 0;
    80005b44:	0a8e                	slli	s5,s5,0x3
    80005b46:	fc040793          	addi	a5,s0,-64
    80005b4a:	9abe                	add	s5,s5,a5
    80005b4c:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005b50:	e4040593          	addi	a1,s0,-448
    80005b54:	f4040513          	addi	a0,s0,-192
    80005b58:	fffff097          	auipc	ra,0xfffff
    80005b5c:	178080e7          	jalr	376(ra) # 80004cd0 <exec>
    80005b60:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b62:	10048993          	addi	s3,s1,256
    80005b66:	6088                	ld	a0,0(s1)
    80005b68:	c911                	beqz	a0,80005b7c <sys_exec+0xfa>
    kfree(argv[i]);
    80005b6a:	ffffb097          	auipc	ra,0xffffb
    80005b6e:	ea8080e7          	jalr	-344(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b72:	04a1                	addi	s1,s1,8
    80005b74:	ff3499e3          	bne	s1,s3,80005b66 <sys_exec+0xe4>
    80005b78:	a011                	j	80005b7c <sys_exec+0xfa>
  return -1;
    80005b7a:	597d                	li	s2,-1
}
    80005b7c:	854a                	mv	a0,s2
    80005b7e:	60be                	ld	ra,456(sp)
    80005b80:	641e                	ld	s0,448(sp)
    80005b82:	74fa                	ld	s1,440(sp)
    80005b84:	795a                	ld	s2,432(sp)
    80005b86:	79ba                	ld	s3,424(sp)
    80005b88:	7a1a                	ld	s4,416(sp)
    80005b8a:	6afa                	ld	s5,408(sp)
    80005b8c:	6179                	addi	sp,sp,464
    80005b8e:	8082                	ret

0000000080005b90 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b90:	7139                	addi	sp,sp,-64
    80005b92:	fc06                	sd	ra,56(sp)
    80005b94:	f822                	sd	s0,48(sp)
    80005b96:	f426                	sd	s1,40(sp)
    80005b98:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b9a:	ffffc097          	auipc	ra,0xffffc
    80005b9e:	e54080e7          	jalr	-428(ra) # 800019ee <myproc>
    80005ba2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ba4:	fd840593          	addi	a1,s0,-40
    80005ba8:	4501                	li	a0,0
    80005baa:	ffffd097          	auipc	ra,0xffffd
    80005bae:	fda080e7          	jalr	-38(ra) # 80002b84 <argaddr>
    return -1;
    80005bb2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bb4:	0e054063          	bltz	a0,80005c94 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bb8:	fc840593          	addi	a1,s0,-56
    80005bbc:	fd040513          	addi	a0,s0,-48
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	de0080e7          	jalr	-544(ra) # 800049a0 <pipealloc>
    return -1;
    80005bc8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bca:	0c054563          	bltz	a0,80005c94 <sys_pipe+0x104>
  fd0 = -1;
    80005bce:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bd2:	fd043503          	ld	a0,-48(s0)
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	50a080e7          	jalr	1290(ra) # 800050e0 <fdalloc>
    80005bde:	fca42223          	sw	a0,-60(s0)
    80005be2:	08054c63          	bltz	a0,80005c7a <sys_pipe+0xea>
    80005be6:	fc843503          	ld	a0,-56(s0)
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	4f6080e7          	jalr	1270(ra) # 800050e0 <fdalloc>
    80005bf2:	fca42023          	sw	a0,-64(s0)
    80005bf6:	06054863          	bltz	a0,80005c66 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bfa:	4691                	li	a3,4
    80005bfc:	fc440613          	addi	a2,s0,-60
    80005c00:	fd843583          	ld	a1,-40(s0)
    80005c04:	68a8                	ld	a0,80(s1)
    80005c06:	ffffc097          	auipc	ra,0xffffc
    80005c0a:	ada080e7          	jalr	-1318(ra) # 800016e0 <copyout>
    80005c0e:	02054063          	bltz	a0,80005c2e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c12:	4691                	li	a3,4
    80005c14:	fc040613          	addi	a2,s0,-64
    80005c18:	fd843583          	ld	a1,-40(s0)
    80005c1c:	0591                	addi	a1,a1,4
    80005c1e:	68a8                	ld	a0,80(s1)
    80005c20:	ffffc097          	auipc	ra,0xffffc
    80005c24:	ac0080e7          	jalr	-1344(ra) # 800016e0 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c28:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c2a:	06055563          	bgez	a0,80005c94 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c2e:	fc442783          	lw	a5,-60(s0)
    80005c32:	07e9                	addi	a5,a5,26
    80005c34:	078e                	slli	a5,a5,0x3
    80005c36:	97a6                	add	a5,a5,s1
    80005c38:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c3c:	fc042503          	lw	a0,-64(s0)
    80005c40:	0569                	addi	a0,a0,26
    80005c42:	050e                	slli	a0,a0,0x3
    80005c44:	9526                	add	a0,a0,s1
    80005c46:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c4a:	fd043503          	ld	a0,-48(s0)
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	9fc080e7          	jalr	-1540(ra) # 8000464a <fileclose>
    fileclose(wf);
    80005c56:	fc843503          	ld	a0,-56(s0)
    80005c5a:	fffff097          	auipc	ra,0xfffff
    80005c5e:	9f0080e7          	jalr	-1552(ra) # 8000464a <fileclose>
    return -1;
    80005c62:	57fd                	li	a5,-1
    80005c64:	a805                	j	80005c94 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c66:	fc442783          	lw	a5,-60(s0)
    80005c6a:	0007c863          	bltz	a5,80005c7a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c6e:	01a78513          	addi	a0,a5,26
    80005c72:	050e                	slli	a0,a0,0x3
    80005c74:	9526                	add	a0,a0,s1
    80005c76:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c7a:	fd043503          	ld	a0,-48(s0)
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	9cc080e7          	jalr	-1588(ra) # 8000464a <fileclose>
    fileclose(wf);
    80005c86:	fc843503          	ld	a0,-56(s0)
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	9c0080e7          	jalr	-1600(ra) # 8000464a <fileclose>
    return -1;
    80005c92:	57fd                	li	a5,-1
}
    80005c94:	853e                	mv	a0,a5
    80005c96:	70e2                	ld	ra,56(sp)
    80005c98:	7442                	ld	s0,48(sp)
    80005c9a:	74a2                	ld	s1,40(sp)
    80005c9c:	6121                	addi	sp,sp,64
    80005c9e:	8082                	ret

0000000080005ca0 <kernelvec>:
    80005ca0:	7111                	addi	sp,sp,-256
    80005ca2:	e006                	sd	ra,0(sp)
    80005ca4:	e40a                	sd	sp,8(sp)
    80005ca6:	e80e                	sd	gp,16(sp)
    80005ca8:	ec12                	sd	tp,24(sp)
    80005caa:	f016                	sd	t0,32(sp)
    80005cac:	f41a                	sd	t1,40(sp)
    80005cae:	f81e                	sd	t2,48(sp)
    80005cb0:	fc22                	sd	s0,56(sp)
    80005cb2:	e0a6                	sd	s1,64(sp)
    80005cb4:	e4aa                	sd	a0,72(sp)
    80005cb6:	e8ae                	sd	a1,80(sp)
    80005cb8:	ecb2                	sd	a2,88(sp)
    80005cba:	f0b6                	sd	a3,96(sp)
    80005cbc:	f4ba                	sd	a4,104(sp)
    80005cbe:	f8be                	sd	a5,112(sp)
    80005cc0:	fcc2                	sd	a6,120(sp)
    80005cc2:	e146                	sd	a7,128(sp)
    80005cc4:	e54a                	sd	s2,136(sp)
    80005cc6:	e94e                	sd	s3,144(sp)
    80005cc8:	ed52                	sd	s4,152(sp)
    80005cca:	f156                	sd	s5,160(sp)
    80005ccc:	f55a                	sd	s6,168(sp)
    80005cce:	f95e                	sd	s7,176(sp)
    80005cd0:	fd62                	sd	s8,184(sp)
    80005cd2:	e1e6                	sd	s9,192(sp)
    80005cd4:	e5ea                	sd	s10,200(sp)
    80005cd6:	e9ee                	sd	s11,208(sp)
    80005cd8:	edf2                	sd	t3,216(sp)
    80005cda:	f1f6                	sd	t4,224(sp)
    80005cdc:	f5fa                	sd	t5,232(sp)
    80005cde:	f9fe                	sd	t6,240(sp)
    80005ce0:	cb5fc0ef          	jal	ra,80002994 <kerneltrap>
    80005ce4:	6082                	ld	ra,0(sp)
    80005ce6:	6122                	ld	sp,8(sp)
    80005ce8:	61c2                	ld	gp,16(sp)
    80005cea:	7282                	ld	t0,32(sp)
    80005cec:	7322                	ld	t1,40(sp)
    80005cee:	73c2                	ld	t2,48(sp)
    80005cf0:	7462                	ld	s0,56(sp)
    80005cf2:	6486                	ld	s1,64(sp)
    80005cf4:	6526                	ld	a0,72(sp)
    80005cf6:	65c6                	ld	a1,80(sp)
    80005cf8:	6666                	ld	a2,88(sp)
    80005cfa:	7686                	ld	a3,96(sp)
    80005cfc:	7726                	ld	a4,104(sp)
    80005cfe:	77c6                	ld	a5,112(sp)
    80005d00:	7866                	ld	a6,120(sp)
    80005d02:	688a                	ld	a7,128(sp)
    80005d04:	692a                	ld	s2,136(sp)
    80005d06:	69ca                	ld	s3,144(sp)
    80005d08:	6a6a                	ld	s4,152(sp)
    80005d0a:	7a8a                	ld	s5,160(sp)
    80005d0c:	7b2a                	ld	s6,168(sp)
    80005d0e:	7bca                	ld	s7,176(sp)
    80005d10:	7c6a                	ld	s8,184(sp)
    80005d12:	6c8e                	ld	s9,192(sp)
    80005d14:	6d2e                	ld	s10,200(sp)
    80005d16:	6dce                	ld	s11,208(sp)
    80005d18:	6e6e                	ld	t3,216(sp)
    80005d1a:	7e8e                	ld	t4,224(sp)
    80005d1c:	7f2e                	ld	t5,232(sp)
    80005d1e:	7fce                	ld	t6,240(sp)
    80005d20:	6111                	addi	sp,sp,256
    80005d22:	10200073          	sret
    80005d26:	00000013          	nop
    80005d2a:	00000013          	nop
    80005d2e:	0001                	nop

0000000080005d30 <timervec>:
    80005d30:	34051573          	csrrw	a0,mscratch,a0
    80005d34:	e10c                	sd	a1,0(a0)
    80005d36:	e510                	sd	a2,8(a0)
    80005d38:	e914                	sd	a3,16(a0)
    80005d3a:	710c                	ld	a1,32(a0)
    80005d3c:	7510                	ld	a2,40(a0)
    80005d3e:	6194                	ld	a3,0(a1)
    80005d40:	96b2                	add	a3,a3,a2
    80005d42:	e194                	sd	a3,0(a1)
    80005d44:	4589                	li	a1,2
    80005d46:	14459073          	csrw	sip,a1
    80005d4a:	6914                	ld	a3,16(a0)
    80005d4c:	6510                	ld	a2,8(a0)
    80005d4e:	610c                	ld	a1,0(a0)
    80005d50:	34051573          	csrrw	a0,mscratch,a0
    80005d54:	30200073          	mret
	...

0000000080005d5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d5a:	1141                	addi	sp,sp,-16
    80005d5c:	e422                	sd	s0,8(sp)
    80005d5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d60:	0c0007b7          	lui	a5,0xc000
    80005d64:	4705                	li	a4,1
    80005d66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d68:	c3d8                	sw	a4,4(a5)
}
    80005d6a:	6422                	ld	s0,8(sp)
    80005d6c:	0141                	addi	sp,sp,16
    80005d6e:	8082                	ret

0000000080005d70 <plicinithart>:

void
plicinithart(void)
{
    80005d70:	1141                	addi	sp,sp,-16
    80005d72:	e406                	sd	ra,8(sp)
    80005d74:	e022                	sd	s0,0(sp)
    80005d76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	c4a080e7          	jalr	-950(ra) # 800019c2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d80:	0085171b          	slliw	a4,a0,0x8
    80005d84:	0c0027b7          	lui	a5,0xc002
    80005d88:	97ba                	add	a5,a5,a4
    80005d8a:	40200713          	li	a4,1026
    80005d8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d92:	00d5151b          	slliw	a0,a0,0xd
    80005d96:	0c2017b7          	lui	a5,0xc201
    80005d9a:	953e                	add	a0,a0,a5
    80005d9c:	00052023          	sw	zero,0(a0)
}
    80005da0:	60a2                	ld	ra,8(sp)
    80005da2:	6402                	ld	s0,0(sp)
    80005da4:	0141                	addi	sp,sp,16
    80005da6:	8082                	ret

0000000080005da8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005da8:	1141                	addi	sp,sp,-16
    80005daa:	e406                	sd	ra,8(sp)
    80005dac:	e022                	sd	s0,0(sp)
    80005dae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005db0:	ffffc097          	auipc	ra,0xffffc
    80005db4:	c12080e7          	jalr	-1006(ra) # 800019c2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005db8:	00d5179b          	slliw	a5,a0,0xd
    80005dbc:	0c201537          	lui	a0,0xc201
    80005dc0:	953e                	add	a0,a0,a5
  return irq;
}
    80005dc2:	4148                	lw	a0,4(a0)
    80005dc4:	60a2                	ld	ra,8(sp)
    80005dc6:	6402                	ld	s0,0(sp)
    80005dc8:	0141                	addi	sp,sp,16
    80005dca:	8082                	ret

0000000080005dcc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dcc:	1101                	addi	sp,sp,-32
    80005dce:	ec06                	sd	ra,24(sp)
    80005dd0:	e822                	sd	s0,16(sp)
    80005dd2:	e426                	sd	s1,8(sp)
    80005dd4:	1000                	addi	s0,sp,32
    80005dd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	bea080e7          	jalr	-1046(ra) # 800019c2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005de0:	00d5151b          	slliw	a0,a0,0xd
    80005de4:	0c2017b7          	lui	a5,0xc201
    80005de8:	97aa                	add	a5,a5,a0
    80005dea:	c3c4                	sw	s1,4(a5)
}
    80005dec:	60e2                	ld	ra,24(sp)
    80005dee:	6442                	ld	s0,16(sp)
    80005df0:	64a2                	ld	s1,8(sp)
    80005df2:	6105                	addi	sp,sp,32
    80005df4:	8082                	ret

0000000080005df6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005df6:	1141                	addi	sp,sp,-16
    80005df8:	e406                	sd	ra,8(sp)
    80005dfa:	e022                	sd	s0,0(sp)
    80005dfc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dfe:	479d                	li	a5,7
    80005e00:	04a7cc63          	blt	a5,a0,80005e58 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e04:	0001d797          	auipc	a5,0x1d
    80005e08:	1fc78793          	addi	a5,a5,508 # 80023000 <disk>
    80005e0c:	00a78733          	add	a4,a5,a0
    80005e10:	6789                	lui	a5,0x2
    80005e12:	97ba                	add	a5,a5,a4
    80005e14:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e18:	eba1                	bnez	a5,80005e68 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e1a:	00451713          	slli	a4,a0,0x4
    80005e1e:	0001f797          	auipc	a5,0x1f
    80005e22:	1e27b783          	ld	a5,482(a5) # 80025000 <disk+0x2000>
    80005e26:	97ba                	add	a5,a5,a4
    80005e28:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005e2c:	0001d797          	auipc	a5,0x1d
    80005e30:	1d478793          	addi	a5,a5,468 # 80023000 <disk>
    80005e34:	97aa                	add	a5,a5,a0
    80005e36:	6509                	lui	a0,0x2
    80005e38:	953e                	add	a0,a0,a5
    80005e3a:	4785                	li	a5,1
    80005e3c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e40:	0001f517          	auipc	a0,0x1f
    80005e44:	1d850513          	addi	a0,a0,472 # 80025018 <disk+0x2018>
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	53e080e7          	jalr	1342(ra) # 80002386 <wakeup>
}
    80005e50:	60a2                	ld	ra,8(sp)
    80005e52:	6402                	ld	s0,0(sp)
    80005e54:	0141                	addi	sp,sp,16
    80005e56:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e58:	00003517          	auipc	a0,0x3
    80005e5c:	a2850513          	addi	a0,a0,-1496 # 80008880 <syscalls+0x338>
    80005e60:	ffffa097          	auipc	ra,0xffffa
    80005e64:	6e2080e7          	jalr	1762(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005e68:	00003517          	auipc	a0,0x3
    80005e6c:	a3050513          	addi	a0,a0,-1488 # 80008898 <syscalls+0x350>
    80005e70:	ffffa097          	auipc	ra,0xffffa
    80005e74:	6d2080e7          	jalr	1746(ra) # 80000542 <panic>

0000000080005e78 <virtio_disk_init>:
{
    80005e78:	1101                	addi	sp,sp,-32
    80005e7a:	ec06                	sd	ra,24(sp)
    80005e7c:	e822                	sd	s0,16(sp)
    80005e7e:	e426                	sd	s1,8(sp)
    80005e80:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e82:	00003597          	auipc	a1,0x3
    80005e86:	a2e58593          	addi	a1,a1,-1490 # 800088b0 <syscalls+0x368>
    80005e8a:	0001f517          	auipc	a0,0x1f
    80005e8e:	21e50513          	addi	a0,a0,542 # 800250a8 <disk+0x20a8>
    80005e92:	ffffb097          	auipc	ra,0xffffb
    80005e96:	d00080e7          	jalr	-768(ra) # 80000b92 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e9a:	100017b7          	lui	a5,0x10001
    80005e9e:	4398                	lw	a4,0(a5)
    80005ea0:	2701                	sext.w	a4,a4
    80005ea2:	747277b7          	lui	a5,0x74727
    80005ea6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eaa:	0ef71163          	bne	a4,a5,80005f8c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	43dc                	lw	a5,4(a5)
    80005eb4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eb6:	4705                	li	a4,1
    80005eb8:	0ce79a63          	bne	a5,a4,80005f8c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ebc:	100017b7          	lui	a5,0x10001
    80005ec0:	479c                	lw	a5,8(a5)
    80005ec2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ec4:	4709                	li	a4,2
    80005ec6:	0ce79363          	bne	a5,a4,80005f8c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eca:	100017b7          	lui	a5,0x10001
    80005ece:	47d8                	lw	a4,12(a5)
    80005ed0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ed2:	554d47b7          	lui	a5,0x554d4
    80005ed6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eda:	0af71963          	bne	a4,a5,80005f8c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ede:	100017b7          	lui	a5,0x10001
    80005ee2:	4705                	li	a4,1
    80005ee4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ee6:	470d                	li	a4,3
    80005ee8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eea:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005eec:	c7ffe737          	lui	a4,0xc7ffe
    80005ef0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ef4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ef6:	2701                	sext.w	a4,a4
    80005ef8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efa:	472d                	li	a4,11
    80005efc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efe:	473d                	li	a4,15
    80005f00:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f02:	6705                	lui	a4,0x1
    80005f04:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f06:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f0a:	5bdc                	lw	a5,52(a5)
    80005f0c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f0e:	c7d9                	beqz	a5,80005f9c <virtio_disk_init+0x124>
  if(max < NUM)
    80005f10:	471d                	li	a4,7
    80005f12:	08f77d63          	bgeu	a4,a5,80005fac <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f16:	100014b7          	lui	s1,0x10001
    80005f1a:	47a1                	li	a5,8
    80005f1c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f1e:	6609                	lui	a2,0x2
    80005f20:	4581                	li	a1,0
    80005f22:	0001d517          	auipc	a0,0x1d
    80005f26:	0de50513          	addi	a0,a0,222 # 80023000 <disk>
    80005f2a:	ffffb097          	auipc	ra,0xffffb
    80005f2e:	df4080e7          	jalr	-524(ra) # 80000d1e <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f32:	0001d717          	auipc	a4,0x1d
    80005f36:	0ce70713          	addi	a4,a4,206 # 80023000 <disk>
    80005f3a:	00c75793          	srli	a5,a4,0xc
    80005f3e:	2781                	sext.w	a5,a5
    80005f40:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f42:	0001f797          	auipc	a5,0x1f
    80005f46:	0be78793          	addi	a5,a5,190 # 80025000 <disk+0x2000>
    80005f4a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f4c:	0001d717          	auipc	a4,0x1d
    80005f50:	13470713          	addi	a4,a4,308 # 80023080 <disk+0x80>
    80005f54:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f56:	0001e717          	auipc	a4,0x1e
    80005f5a:	0aa70713          	addi	a4,a4,170 # 80024000 <disk+0x1000>
    80005f5e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f60:	4705                	li	a4,1
    80005f62:	00e78c23          	sb	a4,24(a5)
    80005f66:	00e78ca3          	sb	a4,25(a5)
    80005f6a:	00e78d23          	sb	a4,26(a5)
    80005f6e:	00e78da3          	sb	a4,27(a5)
    80005f72:	00e78e23          	sb	a4,28(a5)
    80005f76:	00e78ea3          	sb	a4,29(a5)
    80005f7a:	00e78f23          	sb	a4,30(a5)
    80005f7e:	00e78fa3          	sb	a4,31(a5)
}
    80005f82:	60e2                	ld	ra,24(sp)
    80005f84:	6442                	ld	s0,16(sp)
    80005f86:	64a2                	ld	s1,8(sp)
    80005f88:	6105                	addi	sp,sp,32
    80005f8a:	8082                	ret
    panic("could not find virtio disk");
    80005f8c:	00003517          	auipc	a0,0x3
    80005f90:	93450513          	addi	a0,a0,-1740 # 800088c0 <syscalls+0x378>
    80005f94:	ffffa097          	auipc	ra,0xffffa
    80005f98:	5ae080e7          	jalr	1454(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    80005f9c:	00003517          	auipc	a0,0x3
    80005fa0:	94450513          	addi	a0,a0,-1724 # 800088e0 <syscalls+0x398>
    80005fa4:	ffffa097          	auipc	ra,0xffffa
    80005fa8:	59e080e7          	jalr	1438(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    80005fac:	00003517          	auipc	a0,0x3
    80005fb0:	95450513          	addi	a0,a0,-1708 # 80008900 <syscalls+0x3b8>
    80005fb4:	ffffa097          	auipc	ra,0xffffa
    80005fb8:	58e080e7          	jalr	1422(ra) # 80000542 <panic>

0000000080005fbc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fbc:	7175                	addi	sp,sp,-144
    80005fbe:	e506                	sd	ra,136(sp)
    80005fc0:	e122                	sd	s0,128(sp)
    80005fc2:	fca6                	sd	s1,120(sp)
    80005fc4:	f8ca                	sd	s2,112(sp)
    80005fc6:	f4ce                	sd	s3,104(sp)
    80005fc8:	f0d2                	sd	s4,96(sp)
    80005fca:	ecd6                	sd	s5,88(sp)
    80005fcc:	e8da                	sd	s6,80(sp)
    80005fce:	e4de                	sd	s7,72(sp)
    80005fd0:	e0e2                	sd	s8,64(sp)
    80005fd2:	fc66                	sd	s9,56(sp)
    80005fd4:	f86a                	sd	s10,48(sp)
    80005fd6:	f46e                	sd	s11,40(sp)
    80005fd8:	0900                	addi	s0,sp,144
    80005fda:	8aaa                	mv	s5,a0
    80005fdc:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fde:	00c52c83          	lw	s9,12(a0)
    80005fe2:	001c9c9b          	slliw	s9,s9,0x1
    80005fe6:	1c82                	slli	s9,s9,0x20
    80005fe8:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fec:	0001f517          	auipc	a0,0x1f
    80005ff0:	0bc50513          	addi	a0,a0,188 # 800250a8 <disk+0x20a8>
    80005ff4:	ffffb097          	auipc	ra,0xffffb
    80005ff8:	c2e080e7          	jalr	-978(ra) # 80000c22 <acquire>
  for(int i = 0; i < 3; i++){
    80005ffc:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005ffe:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006000:	0001dc17          	auipc	s8,0x1d
    80006004:	000c0c13          	mv	s8,s8
    80006008:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    8000600a:	4b0d                	li	s6,3
    8000600c:	a0ad                	j	80006076 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000600e:	00fc0733          	add	a4,s8,a5
    80006012:	975e                	add	a4,a4,s7
    80006014:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006018:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    8000601a:	0207c563          	bltz	a5,80006044 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000601e:	2905                	addiw	s2,s2,1
    80006020:	0611                	addi	a2,a2,4
    80006022:	19690d63          	beq	s2,s6,800061bc <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006026:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006028:	0001f717          	auipc	a4,0x1f
    8000602c:	ff070713          	addi	a4,a4,-16 # 80025018 <disk+0x2018>
    80006030:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006032:	00074683          	lbu	a3,0(a4)
    80006036:	fee1                	bnez	a3,8000600e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006038:	2785                	addiw	a5,a5,1
    8000603a:	0705                	addi	a4,a4,1
    8000603c:	fe979be3          	bne	a5,s1,80006032 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006040:	57fd                	li	a5,-1
    80006042:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006044:	01205d63          	blez	s2,8000605e <virtio_disk_rw+0xa2>
    80006048:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000604a:	000a2503          	lw	a0,0(s4)
    8000604e:	00000097          	auipc	ra,0x0
    80006052:	da8080e7          	jalr	-600(ra) # 80005df6 <free_desc>
      for(int j = 0; j < i; j++)
    80006056:	2d85                	addiw	s11,s11,1
    80006058:	0a11                	addi	s4,s4,4
    8000605a:	ffb918e3          	bne	s2,s11,8000604a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000605e:	0001f597          	auipc	a1,0x1f
    80006062:	04a58593          	addi	a1,a1,74 # 800250a8 <disk+0x20a8>
    80006066:	0001f517          	auipc	a0,0x1f
    8000606a:	fb250513          	addi	a0,a0,-78 # 80025018 <disk+0x2018>
    8000606e:	ffffc097          	auipc	ra,0xffffc
    80006072:	198080e7          	jalr	408(ra) # 80002206 <sleep>
  for(int i = 0; i < 3; i++){
    80006076:	f8040a13          	addi	s4,s0,-128
{
    8000607a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000607c:	894e                	mv	s2,s3
    8000607e:	b765                	j	80006026 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006080:	0001f717          	auipc	a4,0x1f
    80006084:	f8073703          	ld	a4,-128(a4) # 80025000 <disk+0x2000>
    80006088:	973e                	add	a4,a4,a5
    8000608a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000608e:	0001d517          	auipc	a0,0x1d
    80006092:	f7250513          	addi	a0,a0,-142 # 80023000 <disk>
    80006096:	0001f717          	auipc	a4,0x1f
    8000609a:	f6a70713          	addi	a4,a4,-150 # 80025000 <disk+0x2000>
    8000609e:	6314                	ld	a3,0(a4)
    800060a0:	96be                	add	a3,a3,a5
    800060a2:	00c6d603          	lhu	a2,12(a3)
    800060a6:	00166613          	ori	a2,a2,1
    800060aa:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060ae:	f8842683          	lw	a3,-120(s0)
    800060b2:	6310                	ld	a2,0(a4)
    800060b4:	97b2                	add	a5,a5,a2
    800060b6:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    800060ba:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    800060be:	0612                	slli	a2,a2,0x4
    800060c0:	962a                	add	a2,a2,a0
    800060c2:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060c6:	00469793          	slli	a5,a3,0x4
    800060ca:	630c                	ld	a1,0(a4)
    800060cc:	95be                	add	a1,a1,a5
    800060ce:	6689                	lui	a3,0x2
    800060d0:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    800060d4:	96ca                	add	a3,a3,s2
    800060d6:	96aa                	add	a3,a3,a0
    800060d8:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    800060da:	6314                	ld	a3,0(a4)
    800060dc:	96be                	add	a3,a3,a5
    800060de:	4585                	li	a1,1
    800060e0:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060e2:	6314                	ld	a3,0(a4)
    800060e4:	96be                	add	a3,a3,a5
    800060e6:	4509                	li	a0,2
    800060e8:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800060ec:	6314                	ld	a3,0(a4)
    800060ee:	97b6                	add	a5,a5,a3
    800060f0:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060f4:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800060f8:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800060fc:	6714                	ld	a3,8(a4)
    800060fe:	0026d783          	lhu	a5,2(a3)
    80006102:	8b9d                	andi	a5,a5,7
    80006104:	0789                	addi	a5,a5,2
    80006106:	0786                	slli	a5,a5,0x1
    80006108:	97b6                	add	a5,a5,a3
    8000610a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000610e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006112:	6718                	ld	a4,8(a4)
    80006114:	00275783          	lhu	a5,2(a4)
    80006118:	2785                	addiw	a5,a5,1
    8000611a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000611e:	100017b7          	lui	a5,0x10001
    80006122:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006126:	004aa783          	lw	a5,4(s5)
    8000612a:	02b79163          	bne	a5,a1,8000614c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000612e:	0001f917          	auipc	s2,0x1f
    80006132:	f7a90913          	addi	s2,s2,-134 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006136:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006138:	85ca                	mv	a1,s2
    8000613a:	8556                	mv	a0,s5
    8000613c:	ffffc097          	auipc	ra,0xffffc
    80006140:	0ca080e7          	jalr	202(ra) # 80002206 <sleep>
  while(b->disk == 1) {
    80006144:	004aa783          	lw	a5,4(s5)
    80006148:	fe9788e3          	beq	a5,s1,80006138 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000614c:	f8042483          	lw	s1,-128(s0)
    80006150:	20048793          	addi	a5,s1,512
    80006154:	00479713          	slli	a4,a5,0x4
    80006158:	0001d797          	auipc	a5,0x1d
    8000615c:	ea878793          	addi	a5,a5,-344 # 80023000 <disk>
    80006160:	97ba                	add	a5,a5,a4
    80006162:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006166:	0001f917          	auipc	s2,0x1f
    8000616a:	e9a90913          	addi	s2,s2,-358 # 80025000 <disk+0x2000>
    8000616e:	a019                	j	80006174 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006170:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006174:	8526                	mv	a0,s1
    80006176:	00000097          	auipc	ra,0x0
    8000617a:	c80080e7          	jalr	-896(ra) # 80005df6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000617e:	0492                	slli	s1,s1,0x4
    80006180:	00093783          	ld	a5,0(s2)
    80006184:	94be                	add	s1,s1,a5
    80006186:	00c4d783          	lhu	a5,12(s1)
    8000618a:	8b85                	andi	a5,a5,1
    8000618c:	f3f5                	bnez	a5,80006170 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000618e:	0001f517          	auipc	a0,0x1f
    80006192:	f1a50513          	addi	a0,a0,-230 # 800250a8 <disk+0x20a8>
    80006196:	ffffb097          	auipc	ra,0xffffb
    8000619a:	b40080e7          	jalr	-1216(ra) # 80000cd6 <release>
}
    8000619e:	60aa                	ld	ra,136(sp)
    800061a0:	640a                	ld	s0,128(sp)
    800061a2:	74e6                	ld	s1,120(sp)
    800061a4:	7946                	ld	s2,112(sp)
    800061a6:	79a6                	ld	s3,104(sp)
    800061a8:	7a06                	ld	s4,96(sp)
    800061aa:	6ae6                	ld	s5,88(sp)
    800061ac:	6b46                	ld	s6,80(sp)
    800061ae:	6ba6                	ld	s7,72(sp)
    800061b0:	6c06                	ld	s8,64(sp)
    800061b2:	7ce2                	ld	s9,56(sp)
    800061b4:	7d42                	ld	s10,48(sp)
    800061b6:	7da2                	ld	s11,40(sp)
    800061b8:	6149                	addi	sp,sp,144
    800061ba:	8082                	ret
  if(write)
    800061bc:	01a037b3          	snez	a5,s10
    800061c0:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800061c4:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800061c8:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800061cc:	f8042483          	lw	s1,-128(s0)
    800061d0:	00449913          	slli	s2,s1,0x4
    800061d4:	0001f997          	auipc	s3,0x1f
    800061d8:	e2c98993          	addi	s3,s3,-468 # 80025000 <disk+0x2000>
    800061dc:	0009ba03          	ld	s4,0(s3)
    800061e0:	9a4a                	add	s4,s4,s2
    800061e2:	f7040513          	addi	a0,s0,-144
    800061e6:	ffffb097          	auipc	ra,0xffffb
    800061ea:	f08080e7          	jalr	-248(ra) # 800010ee <kvmpa>
    800061ee:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    800061f2:	0009b783          	ld	a5,0(s3)
    800061f6:	97ca                	add	a5,a5,s2
    800061f8:	4741                	li	a4,16
    800061fa:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061fc:	0009b783          	ld	a5,0(s3)
    80006200:	97ca                	add	a5,a5,s2
    80006202:	4705                	li	a4,1
    80006204:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006208:	f8442783          	lw	a5,-124(s0)
    8000620c:	0009b703          	ld	a4,0(s3)
    80006210:	974a                	add	a4,a4,s2
    80006212:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006216:	0792                	slli	a5,a5,0x4
    80006218:	0009b703          	ld	a4,0(s3)
    8000621c:	973e                	add	a4,a4,a5
    8000621e:	058a8693          	addi	a3,s5,88
    80006222:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80006224:	0009b703          	ld	a4,0(s3)
    80006228:	973e                	add	a4,a4,a5
    8000622a:	40000693          	li	a3,1024
    8000622e:	c714                	sw	a3,8(a4)
  if(write)
    80006230:	e40d18e3          	bnez	s10,80006080 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006234:	0001f717          	auipc	a4,0x1f
    80006238:	dcc73703          	ld	a4,-564(a4) # 80025000 <disk+0x2000>
    8000623c:	973e                	add	a4,a4,a5
    8000623e:	4689                	li	a3,2
    80006240:	00d71623          	sh	a3,12(a4)
    80006244:	b5a9                	j	8000608e <virtio_disk_rw+0xd2>

0000000080006246 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006246:	1101                	addi	sp,sp,-32
    80006248:	ec06                	sd	ra,24(sp)
    8000624a:	e822                	sd	s0,16(sp)
    8000624c:	e426                	sd	s1,8(sp)
    8000624e:	e04a                	sd	s2,0(sp)
    80006250:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006252:	0001f517          	auipc	a0,0x1f
    80006256:	e5650513          	addi	a0,a0,-426 # 800250a8 <disk+0x20a8>
    8000625a:	ffffb097          	auipc	ra,0xffffb
    8000625e:	9c8080e7          	jalr	-1592(ra) # 80000c22 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006262:	0001f717          	auipc	a4,0x1f
    80006266:	d9e70713          	addi	a4,a4,-610 # 80025000 <disk+0x2000>
    8000626a:	02075783          	lhu	a5,32(a4)
    8000626e:	6b18                	ld	a4,16(a4)
    80006270:	00275683          	lhu	a3,2(a4)
    80006274:	8ebd                	xor	a3,a3,a5
    80006276:	8a9d                	andi	a3,a3,7
    80006278:	cab9                	beqz	a3,800062ce <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000627a:	0001d917          	auipc	s2,0x1d
    8000627e:	d8690913          	addi	s2,s2,-634 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006282:	0001f497          	auipc	s1,0x1f
    80006286:	d7e48493          	addi	s1,s1,-642 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000628a:	078e                	slli	a5,a5,0x3
    8000628c:	97ba                	add	a5,a5,a4
    8000628e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006290:	20078713          	addi	a4,a5,512
    80006294:	0712                	slli	a4,a4,0x4
    80006296:	974a                	add	a4,a4,s2
    80006298:	03074703          	lbu	a4,48(a4)
    8000629c:	ef21                	bnez	a4,800062f4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000629e:	20078793          	addi	a5,a5,512
    800062a2:	0792                	slli	a5,a5,0x4
    800062a4:	97ca                	add	a5,a5,s2
    800062a6:	7798                	ld	a4,40(a5)
    800062a8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800062ac:	7788                	ld	a0,40(a5)
    800062ae:	ffffc097          	auipc	ra,0xffffc
    800062b2:	0d8080e7          	jalr	216(ra) # 80002386 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062b6:	0204d783          	lhu	a5,32(s1)
    800062ba:	2785                	addiw	a5,a5,1
    800062bc:	8b9d                	andi	a5,a5,7
    800062be:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062c2:	6898                	ld	a4,16(s1)
    800062c4:	00275683          	lhu	a3,2(a4)
    800062c8:	8a9d                	andi	a3,a3,7
    800062ca:	fcf690e3          	bne	a3,a5,8000628a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062ce:	10001737          	lui	a4,0x10001
    800062d2:	533c                	lw	a5,96(a4)
    800062d4:	8b8d                	andi	a5,a5,3
    800062d6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062d8:	0001f517          	auipc	a0,0x1f
    800062dc:	dd050513          	addi	a0,a0,-560 # 800250a8 <disk+0x20a8>
    800062e0:	ffffb097          	auipc	ra,0xffffb
    800062e4:	9f6080e7          	jalr	-1546(ra) # 80000cd6 <release>
}
    800062e8:	60e2                	ld	ra,24(sp)
    800062ea:	6442                	ld	s0,16(sp)
    800062ec:	64a2                	ld	s1,8(sp)
    800062ee:	6902                	ld	s2,0(sp)
    800062f0:	6105                	addi	sp,sp,32
    800062f2:	8082                	ret
      panic("virtio_disk_intr status");
    800062f4:	00002517          	auipc	a0,0x2
    800062f8:	62c50513          	addi	a0,a0,1580 # 80008920 <syscalls+0x3d8>
    800062fc:	ffffa097          	auipc	ra,0xffffa
    80006300:	246080e7          	jalr	582(ra) # 80000542 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
