
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	85013103          	ld	sp,-1968(sp) # 80008850 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	adc78793          	addi	a5,a5,-1316 # 80005b40 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dd678793          	addi	a5,a5,-554 # 80000e84 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	32c080e7          	jalr	812(ra) # 8000244a <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	78e080e7          	jalr	1934(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7119                	addi	sp,sp,-128
    80000158:	fc86                	sd	ra,120(sp)
    8000015a:	f8a2                	sd	s0,112(sp)
    8000015c:	f4a6                	sd	s1,104(sp)
    8000015e:	f0ca                	sd	s2,96(sp)
    80000160:	ecce                	sd	s3,88(sp)
    80000162:	e8d2                	sd	s4,80(sp)
    80000164:	e4d6                	sd	s5,72(sp)
    80000166:	e0da                	sd	s6,64(sp)
    80000168:	fc5e                	sd	s7,56(sp)
    8000016a:	f862                	sd	s8,48(sp)
    8000016c:	f466                	sd	s9,40(sp)
    8000016e:	f06a                	sd	s10,32(sp)
    80000170:	ec6e                	sd	s11,24(sp)
    80000172:	0100                	addi	s0,sp,128
    80000174:	8b2a                	mv	s6,a0
    80000176:	8aae                	mv	s5,a1
    80000178:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000017e:	00011517          	auipc	a0,0x11
    80000182:	00250513          	addi	a0,a0,2 # 80011180 <cons>
    80000186:	00001097          	auipc	ra,0x1
    8000018a:	a50080e7          	jalr	-1456(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018e:	00011497          	auipc	s1,0x11
    80000192:	ff248493          	addi	s1,s1,-14 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000196:	89a6                	mv	s3,s1
    80000198:	00011917          	auipc	s2,0x11
    8000019c:	08090913          	addi	s2,s2,128 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001a0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001a2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a4:	4da9                	li	s11,10
  while(n > 0){
    800001a6:	07405863          	blez	s4,80000216 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001aa:	0984a783          	lw	a5,152(s1)
    800001ae:	09c4a703          	lw	a4,156(s1)
    800001b2:	02f71463          	bne	a4,a5,800001da <consoleread+0x84>
      if(myproc()->killed){
    800001b6:	00001097          	auipc	ra,0x1
    800001ba:	7de080e7          	jalr	2014(ra) # 80001994 <myproc>
    800001be:	551c                	lw	a5,40(a0)
    800001c0:	e7b5                	bnez	a5,8000022c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001c2:	85ce                	mv	a1,s3
    800001c4:	854a                	mv	a0,s2
    800001c6:	00002097          	auipc	ra,0x2
    800001ca:	e8a080e7          	jalr	-374(ra) # 80002050 <sleep>
    while(cons.r == cons.w){
    800001ce:	0984a783          	lw	a5,152(s1)
    800001d2:	09c4a703          	lw	a4,156(s1)
    800001d6:	fef700e3          	beq	a4,a5,800001b6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001da:	0017871b          	addiw	a4,a5,1
    800001de:	08e4ac23          	sw	a4,152(s1)
    800001e2:	07f7f713          	andi	a4,a5,127
    800001e6:	9726                	add	a4,a4,s1
    800001e8:	01874703          	lbu	a4,24(a4)
    800001ec:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001f0:	079c0663          	beq	s8,s9,8000025c <consoleread+0x106>
    cbuf = c;
    800001f4:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f8:	4685                	li	a3,1
    800001fa:	f8f40613          	addi	a2,s0,-113
    800001fe:	85d6                	mv	a1,s5
    80000200:	855a                	mv	a0,s6
    80000202:	00002097          	auipc	ra,0x2
    80000206:	1f2080e7          	jalr	498(ra) # 800023f4 <either_copyout>
    8000020a:	01a50663          	beq	a0,s10,80000216 <consoleread+0xc0>
    dst++;
    8000020e:	0a85                	addi	s5,s5,1
    --n;
    80000210:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000212:	f9bc1ae3          	bne	s8,s11,800001a6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000216:	00011517          	auipc	a0,0x11
    8000021a:	f6a50513          	addi	a0,a0,-150 # 80011180 <cons>
    8000021e:	00001097          	auipc	ra,0x1
    80000222:	a6c080e7          	jalr	-1428(ra) # 80000c8a <release>

  return target - n;
    80000226:	414b853b          	subw	a0,s7,s4
    8000022a:	a811                	j	8000023e <consoleread+0xe8>
        release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	f5450513          	addi	a0,a0,-172 # 80011180 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	a56080e7          	jalr	-1450(ra) # 80000c8a <release>
        return -1;
    8000023c:	557d                	li	a0,-1
}
    8000023e:	70e6                	ld	ra,120(sp)
    80000240:	7446                	ld	s0,112(sp)
    80000242:	74a6                	ld	s1,104(sp)
    80000244:	7906                	ld	s2,96(sp)
    80000246:	69e6                	ld	s3,88(sp)
    80000248:	6a46                	ld	s4,80(sp)
    8000024a:	6aa6                	ld	s5,72(sp)
    8000024c:	6b06                	ld	s6,64(sp)
    8000024e:	7be2                	ld	s7,56(sp)
    80000250:	7c42                	ld	s8,48(sp)
    80000252:	7ca2                	ld	s9,40(sp)
    80000254:	7d02                	ld	s10,32(sp)
    80000256:	6de2                	ld	s11,24(sp)
    80000258:	6109                	addi	sp,sp,128
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	000a071b          	sext.w	a4,s4
    80000260:	fb777be3          	bgeu	a4,s7,80000216 <consoleread+0xc0>
        cons.r--;
    80000264:	00011717          	auipc	a4,0x11
    80000268:	faf72a23          	sw	a5,-76(a4) # 80011218 <cons+0x98>
    8000026c:	b76d                	j	80000216 <consoleread+0xc0>

000000008000026e <consputc>:
{
    8000026e:	1141                	addi	sp,sp,-16
    80000270:	e406                	sd	ra,8(sp)
    80000272:	e022                	sd	s0,0(sp)
    80000274:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000276:	10000793          	li	a5,256
    8000027a:	00f50a63          	beq	a0,a5,8000028e <consputc+0x20>
    uartputc_sync(c);
    8000027e:	00000097          	auipc	ra,0x0
    80000282:	564080e7          	jalr	1380(ra) # 800007e2 <uartputc_sync>
}
    80000286:	60a2                	ld	ra,8(sp)
    80000288:	6402                	ld	s0,0(sp)
    8000028a:	0141                	addi	sp,sp,16
    8000028c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000028e:	4521                	li	a0,8
    80000290:	00000097          	auipc	ra,0x0
    80000294:	552080e7          	jalr	1362(ra) # 800007e2 <uartputc_sync>
    80000298:	02000513          	li	a0,32
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	546080e7          	jalr	1350(ra) # 800007e2 <uartputc_sync>
    800002a4:	4521                	li	a0,8
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	53c080e7          	jalr	1340(ra) # 800007e2 <uartputc_sync>
    800002ae:	bfe1                	j	80000286 <consputc+0x18>

00000000800002b0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b0:	1101                	addi	sp,sp,-32
    800002b2:	ec06                	sd	ra,24(sp)
    800002b4:	e822                	sd	s0,16(sp)
    800002b6:	e426                	sd	s1,8(sp)
    800002b8:	e04a                	sd	s2,0(sp)
    800002ba:	1000                	addi	s0,sp,32
    800002bc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002be:	00011517          	auipc	a0,0x11
    800002c2:	ec250513          	addi	a0,a0,-318 # 80011180 <cons>
    800002c6:	00001097          	auipc	ra,0x1
    800002ca:	910080e7          	jalr	-1776(ra) # 80000bd6 <acquire>

  switch(c){
    800002ce:	47d5                	li	a5,21
    800002d0:	0af48663          	beq	s1,a5,8000037c <consoleintr+0xcc>
    800002d4:	0297ca63          	blt	a5,s1,80000308 <consoleintr+0x58>
    800002d8:	47a1                	li	a5,8
    800002da:	0ef48763          	beq	s1,a5,800003c8 <consoleintr+0x118>
    800002de:	47c1                	li	a5,16
    800002e0:	10f49a63          	bne	s1,a5,800003f4 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002e4:	00002097          	auipc	ra,0x2
    800002e8:	1bc080e7          	jalr	444(ra) # 800024a0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ec:	00011517          	auipc	a0,0x11
    800002f0:	e9450513          	addi	a0,a0,-364 # 80011180 <cons>
    800002f4:	00001097          	auipc	ra,0x1
    800002f8:	996080e7          	jalr	-1642(ra) # 80000c8a <release>
}
    800002fc:	60e2                	ld	ra,24(sp)
    800002fe:	6442                	ld	s0,16(sp)
    80000300:	64a2                	ld	s1,8(sp)
    80000302:	6902                	ld	s2,0(sp)
    80000304:	6105                	addi	sp,sp,32
    80000306:	8082                	ret
  switch(c){
    80000308:	07f00793          	li	a5,127
    8000030c:	0af48e63          	beq	s1,a5,800003c8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000310:	00011717          	auipc	a4,0x11
    80000314:	e7070713          	addi	a4,a4,-400 # 80011180 <cons>
    80000318:	0a072783          	lw	a5,160(a4)
    8000031c:	09872703          	lw	a4,152(a4)
    80000320:	9f99                	subw	a5,a5,a4
    80000322:	07f00713          	li	a4,127
    80000326:	fcf763e3          	bltu	a4,a5,800002ec <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000032a:	47b5                	li	a5,13
    8000032c:	0cf48763          	beq	s1,a5,800003fa <consoleintr+0x14a>
      consputc(c);
    80000330:	8526                	mv	a0,s1
    80000332:	00000097          	auipc	ra,0x0
    80000336:	f3c080e7          	jalr	-196(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000033a:	00011797          	auipc	a5,0x11
    8000033e:	e4678793          	addi	a5,a5,-442 # 80011180 <cons>
    80000342:	0a07a703          	lw	a4,160(a5)
    80000346:	0017069b          	addiw	a3,a4,1
    8000034a:	0006861b          	sext.w	a2,a3
    8000034e:	0ad7a023          	sw	a3,160(a5)
    80000352:	07f77713          	andi	a4,a4,127
    80000356:	97ba                	add	a5,a5,a4
    80000358:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000035c:	47a9                	li	a5,10
    8000035e:	0cf48563          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000362:	4791                	li	a5,4
    80000364:	0cf48263          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000368:	00011797          	auipc	a5,0x11
    8000036c:	eb07a783          	lw	a5,-336(a5) # 80011218 <cons+0x98>
    80000370:	0807879b          	addiw	a5,a5,128
    80000374:	f6f61ce3          	bne	a2,a5,800002ec <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000378:	863e                	mv	a2,a5
    8000037a:	a07d                	j	80000428 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000037c:	00011717          	auipc	a4,0x11
    80000380:	e0470713          	addi	a4,a4,-508 # 80011180 <cons>
    80000384:	0a072783          	lw	a5,160(a4)
    80000388:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000038c:	00011497          	auipc	s1,0x11
    80000390:	df448493          	addi	s1,s1,-524 # 80011180 <cons>
    while(cons.e != cons.w &&
    80000394:	4929                	li	s2,10
    80000396:	f4f70be3          	beq	a4,a5,800002ec <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	37fd                	addiw	a5,a5,-1
    8000039c:	07f7f713          	andi	a4,a5,127
    800003a0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003a2:	01874703          	lbu	a4,24(a4)
    800003a6:	f52703e3          	beq	a4,s2,800002ec <consoleintr+0x3c>
      cons.e--;
    800003aa:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ae:	10000513          	li	a0,256
    800003b2:	00000097          	auipc	ra,0x0
    800003b6:	ebc080e7          	jalr	-324(ra) # 8000026e <consputc>
    while(cons.e != cons.w &&
    800003ba:	0a04a783          	lw	a5,160(s1)
    800003be:	09c4a703          	lw	a4,156(s1)
    800003c2:	fcf71ce3          	bne	a4,a5,8000039a <consoleintr+0xea>
    800003c6:	b71d                	j	800002ec <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c8:	00011717          	auipc	a4,0x11
    800003cc:	db870713          	addi	a4,a4,-584 # 80011180 <cons>
    800003d0:	0a072783          	lw	a5,160(a4)
    800003d4:	09c72703          	lw	a4,156(a4)
    800003d8:	f0f70ae3          	beq	a4,a5,800002ec <consoleintr+0x3c>
      cons.e--;
    800003dc:	37fd                	addiw	a5,a5,-1
    800003de:	00011717          	auipc	a4,0x11
    800003e2:	e4f72123          	sw	a5,-446(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e6:	10000513          	li	a0,256
    800003ea:	00000097          	auipc	ra,0x0
    800003ee:	e84080e7          	jalr	-380(ra) # 8000026e <consputc>
    800003f2:	bded                	j	800002ec <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003f4:	ee048ce3          	beqz	s1,800002ec <consoleintr+0x3c>
    800003f8:	bf21                	j	80000310 <consoleintr+0x60>
      consputc(c);
    800003fa:	4529                	li	a0,10
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e72080e7          	jalr	-398(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000404:	00011797          	auipc	a5,0x11
    80000408:	d7c78793          	addi	a5,a5,-644 # 80011180 <cons>
    8000040c:	0a07a703          	lw	a4,160(a5)
    80000410:	0017069b          	addiw	a3,a4,1
    80000414:	0006861b          	sext.w	a2,a3
    80000418:	0ad7a023          	sw	a3,160(a5)
    8000041c:	07f77713          	andi	a4,a4,127
    80000420:	97ba                	add	a5,a5,a4
    80000422:	4729                	li	a4,10
    80000424:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000428:	00011797          	auipc	a5,0x11
    8000042c:	dec7aa23          	sw	a2,-524(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000430:	00011517          	auipc	a0,0x11
    80000434:	de850513          	addi	a0,a0,-536 # 80011218 <cons+0x98>
    80000438:	00002097          	auipc	ra,0x2
    8000043c:	da4080e7          	jalr	-604(ra) # 800021dc <wakeup>
    80000440:	b575                	j	800002ec <consoleintr+0x3c>

0000000080000442 <consoleinit>:

void
consoleinit(void)
{
    80000442:	1141                	addi	sp,sp,-16
    80000444:	e406                	sd	ra,8(sp)
    80000446:	e022                	sd	s0,0(sp)
    80000448:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000044a:	00008597          	auipc	a1,0x8
    8000044e:	bc658593          	addi	a1,a1,-1082 # 80008010 <etext+0x10>
    80000452:	00011517          	auipc	a0,0x11
    80000456:	d2e50513          	addi	a0,a0,-722 # 80011180 <cons>
    8000045a:	00000097          	auipc	ra,0x0
    8000045e:	6ec080e7          	jalr	1772(ra) # 80000b46 <initlock>

  uartinit();
    80000462:	00000097          	auipc	ra,0x0
    80000466:	330080e7          	jalr	816(ra) # 80000792 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000046a:	00021797          	auipc	a5,0x21
    8000046e:	eae78793          	addi	a5,a5,-338 # 80021318 <devsw>
    80000472:	00000717          	auipc	a4,0x0
    80000476:	ce470713          	addi	a4,a4,-796 # 80000156 <consoleread>
    8000047a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	c7870713          	addi	a4,a4,-904 # 800000f4 <consolewrite>
    80000484:	ef98                	sd	a4,24(a5)
}
    80000486:	60a2                	ld	ra,8(sp)
    80000488:	6402                	ld	s0,0(sp)
    8000048a:	0141                	addi	sp,sp,16
    8000048c:	8082                	ret

000000008000048e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000048e:	7179                	addi	sp,sp,-48
    80000490:	f406                	sd	ra,40(sp)
    80000492:	f022                	sd	s0,32(sp)
    80000494:	ec26                	sd	s1,24(sp)
    80000496:	e84a                	sd	s2,16(sp)
    80000498:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000049a:	c219                	beqz	a2,800004a0 <printint+0x12>
    8000049c:	08054663          	bltz	a0,80000528 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a0:	2501                	sext.w	a0,a0
    800004a2:	4881                	li	a7,0
    800004a4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004aa:	2581                	sext.w	a1,a1
    800004ac:	00008617          	auipc	a2,0x8
    800004b0:	b9460613          	addi	a2,a2,-1132 # 80008040 <digits>
    800004b4:	883a                	mv	a6,a4
    800004b6:	2705                	addiw	a4,a4,1
    800004b8:	02b577bb          	remuw	a5,a0,a1
    800004bc:	1782                	slli	a5,a5,0x20
    800004be:	9381                	srli	a5,a5,0x20
    800004c0:	97b2                	add	a5,a5,a2
    800004c2:	0007c783          	lbu	a5,0(a5)
    800004c6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ca:	0005079b          	sext.w	a5,a0
    800004ce:	02b5553b          	divuw	a0,a0,a1
    800004d2:	0685                	addi	a3,a3,1
    800004d4:	feb7f0e3          	bgeu	a5,a1,800004b4 <printint+0x26>

  if(sign)
    800004d8:	00088b63          	beqz	a7,800004ee <printint+0x60>
    buf[i++] = '-';
    800004dc:	fe040793          	addi	a5,s0,-32
    800004e0:	973e                	add	a4,a4,a5
    800004e2:	02d00793          	li	a5,45
    800004e6:	fef70823          	sb	a5,-16(a4)
    800004ea:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004ee:	02e05763          	blez	a4,8000051c <printint+0x8e>
    800004f2:	fd040793          	addi	a5,s0,-48
    800004f6:	00e784b3          	add	s1,a5,a4
    800004fa:	fff78913          	addi	s2,a5,-1
    800004fe:	993a                	add	s2,s2,a4
    80000500:	377d                	addiw	a4,a4,-1
    80000502:	1702                	slli	a4,a4,0x20
    80000504:	9301                	srli	a4,a4,0x20
    80000506:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000050a:	fff4c503          	lbu	a0,-1(s1)
    8000050e:	00000097          	auipc	ra,0x0
    80000512:	d60080e7          	jalr	-672(ra) # 8000026e <consputc>
  while(--i >= 0)
    80000516:	14fd                	addi	s1,s1,-1
    80000518:	ff2499e3          	bne	s1,s2,8000050a <printint+0x7c>
}
    8000051c:	70a2                	ld	ra,40(sp)
    8000051e:	7402                	ld	s0,32(sp)
    80000520:	64e2                	ld	s1,24(sp)
    80000522:	6942                	ld	s2,16(sp)
    80000524:	6145                	addi	sp,sp,48
    80000526:	8082                	ret
    x = -xx;
    80000528:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000052c:	4885                	li	a7,1
    x = -xx;
    8000052e:	bf9d                	j	800004a4 <printint+0x16>

0000000080000530 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000530:	1101                	addi	sp,sp,-32
    80000532:	ec06                	sd	ra,24(sp)
    80000534:	e822                	sd	s0,16(sp)
    80000536:	e426                	sd	s1,8(sp)
    80000538:	1000                	addi	s0,sp,32
    8000053a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000053c:	00011797          	auipc	a5,0x11
    80000540:	d007a223          	sw	zero,-764(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000544:	00008517          	auipc	a0,0x8
    80000548:	ad450513          	addi	a0,a0,-1324 # 80008018 <etext+0x18>
    8000054c:	00000097          	auipc	ra,0x0
    80000550:	02e080e7          	jalr	46(ra) # 8000057a <printf>
  printf(s);
    80000554:	8526                	mv	a0,s1
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	024080e7          	jalr	36(ra) # 8000057a <printf>
  printf("\n");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	b6a50513          	addi	a0,a0,-1174 # 800080c8 <digits+0x88>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	014080e7          	jalr	20(ra) # 8000057a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000056e:	4785                	li	a5,1
    80000570:	00009717          	auipc	a4,0x9
    80000574:	a8f72823          	sw	a5,-1392(a4) # 80009000 <panicked>
  for(;;)
    80000578:	a001                	j	80000578 <panic+0x48>

000000008000057a <printf>:
{
    8000057a:	7131                	addi	sp,sp,-192
    8000057c:	fc86                	sd	ra,120(sp)
    8000057e:	f8a2                	sd	s0,112(sp)
    80000580:	f4a6                	sd	s1,104(sp)
    80000582:	f0ca                	sd	s2,96(sp)
    80000584:	ecce                	sd	s3,88(sp)
    80000586:	e8d2                	sd	s4,80(sp)
    80000588:	e4d6                	sd	s5,72(sp)
    8000058a:	e0da                	sd	s6,64(sp)
    8000058c:	fc5e                	sd	s7,56(sp)
    8000058e:	f862                	sd	s8,48(sp)
    80000590:	f466                	sd	s9,40(sp)
    80000592:	f06a                	sd	s10,32(sp)
    80000594:	ec6e                	sd	s11,24(sp)
    80000596:	0100                	addi	s0,sp,128
    80000598:	8a2a                	mv	s4,a0
    8000059a:	e40c                	sd	a1,8(s0)
    8000059c:	e810                	sd	a2,16(s0)
    8000059e:	ec14                	sd	a3,24(s0)
    800005a0:	f018                	sd	a4,32(s0)
    800005a2:	f41c                	sd	a5,40(s0)
    800005a4:	03043823          	sd	a6,48(s0)
    800005a8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ac:	00011d97          	auipc	s11,0x11
    800005b0:	c94dad83          	lw	s11,-876(s11) # 80011240 <pr+0x18>
  if(locking)
    800005b4:	020d9b63          	bnez	s11,800005ea <printf+0x70>
  if (fmt == 0)
    800005b8:	040a0263          	beqz	s4,800005fc <printf+0x82>
  va_start(ap, fmt);
    800005bc:	00840793          	addi	a5,s0,8
    800005c0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c4:	000a4503          	lbu	a0,0(s4)
    800005c8:	16050263          	beqz	a0,8000072c <printf+0x1b2>
    800005cc:	4481                	li	s1,0
    if(c != '%'){
    800005ce:	02500a93          	li	s5,37
    switch(c){
    800005d2:	07000b13          	li	s6,112
  consputc('x');
    800005d6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008b97          	auipc	s7,0x8
    800005dc:	a68b8b93          	addi	s7,s7,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	06400c13          	li	s8,100
    800005e8:	a82d                	j	80000622 <printf+0xa8>
    acquire(&pr.lock);
    800005ea:	00011517          	auipc	a0,0x11
    800005ee:	c3e50513          	addi	a0,a0,-962 # 80011228 <pr>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
    800005fa:	bf7d                	j	800005b8 <printf+0x3e>
    panic("null fmt");
    800005fc:	00008517          	auipc	a0,0x8
    80000600:	a2c50513          	addi	a0,a0,-1492 # 80008028 <etext+0x28>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	f2c080e7          	jalr	-212(ra) # 80000530 <panic>
      consputc(c);
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	c62080e7          	jalr	-926(ra) # 8000026e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000614:	2485                	addiw	s1,s1,1
    80000616:	009a07b3          	add	a5,s4,s1
    8000061a:	0007c503          	lbu	a0,0(a5)
    8000061e:	10050763          	beqz	a0,8000072c <printf+0x1b2>
    if(c != '%'){
    80000622:	ff5515e3          	bne	a0,s5,8000060c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000626:	2485                	addiw	s1,s1,1
    80000628:	009a07b3          	add	a5,s4,s1
    8000062c:	0007c783          	lbu	a5,0(a5)
    80000630:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000634:	cfe5                	beqz	a5,8000072c <printf+0x1b2>
    switch(c){
    80000636:	05678a63          	beq	a5,s6,8000068a <printf+0x110>
    8000063a:	02fb7663          	bgeu	s6,a5,80000666 <printf+0xec>
    8000063e:	09978963          	beq	a5,s9,800006d0 <printf+0x156>
    80000642:	07800713          	li	a4,120
    80000646:	0ce79863          	bne	a5,a4,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000064a:	f8843783          	ld	a5,-120(s0)
    8000064e:	00878713          	addi	a4,a5,8
    80000652:	f8e43423          	sd	a4,-120(s0)
    80000656:	4605                	li	a2,1
    80000658:	85ea                	mv	a1,s10
    8000065a:	4388                	lw	a0,0(a5)
    8000065c:	00000097          	auipc	ra,0x0
    80000660:	e32080e7          	jalr	-462(ra) # 8000048e <printint>
      break;
    80000664:	bf45                	j	80000614 <printf+0x9a>
    switch(c){
    80000666:	0b578263          	beq	a5,s5,8000070a <printf+0x190>
    8000066a:	0b879663          	bne	a5,s8,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000066e:	f8843783          	ld	a5,-120(s0)
    80000672:	00878713          	addi	a4,a5,8
    80000676:	f8e43423          	sd	a4,-120(s0)
    8000067a:	4605                	li	a2,1
    8000067c:	45a9                	li	a1,10
    8000067e:	4388                	lw	a0,0(a5)
    80000680:	00000097          	auipc	ra,0x0
    80000684:	e0e080e7          	jalr	-498(ra) # 8000048e <printint>
      break;
    80000688:	b771                	j	80000614 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000068a:	f8843783          	ld	a5,-120(s0)
    8000068e:	00878713          	addi	a4,a5,8
    80000692:	f8e43423          	sd	a4,-120(s0)
    80000696:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000069a:	03000513          	li	a0,48
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	bd0080e7          	jalr	-1072(ra) # 8000026e <consputc>
  consputc('x');
    800006a6:	07800513          	li	a0,120
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bc4080e7          	jalr	-1084(ra) # 8000026e <consputc>
    800006b2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006b4:	03c9d793          	srli	a5,s3,0x3c
    800006b8:	97de                	add	a5,a5,s7
    800006ba:	0007c503          	lbu	a0,0(a5)
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bb0080e7          	jalr	-1104(ra) # 8000026e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c6:	0992                	slli	s3,s3,0x4
    800006c8:	397d                	addiw	s2,s2,-1
    800006ca:	fe0915e3          	bnez	s2,800006b4 <printf+0x13a>
    800006ce:	b799                	j	80000614 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d0:	f8843783          	ld	a5,-120(s0)
    800006d4:	00878713          	addi	a4,a5,8
    800006d8:	f8e43423          	sd	a4,-120(s0)
    800006dc:	0007b903          	ld	s2,0(a5)
    800006e0:	00090e63          	beqz	s2,800006fc <printf+0x182>
      for(; *s; s++)
    800006e4:	00094503          	lbu	a0,0(s2)
    800006e8:	d515                	beqz	a0,80000614 <printf+0x9a>
        consputc(*s);
    800006ea:	00000097          	auipc	ra,0x0
    800006ee:	b84080e7          	jalr	-1148(ra) # 8000026e <consputc>
      for(; *s; s++)
    800006f2:	0905                	addi	s2,s2,1
    800006f4:	00094503          	lbu	a0,0(s2)
    800006f8:	f96d                	bnez	a0,800006ea <printf+0x170>
    800006fa:	bf29                	j	80000614 <printf+0x9a>
        s = "(null)";
    800006fc:	00008917          	auipc	s2,0x8
    80000700:	92490913          	addi	s2,s2,-1756 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000704:	02800513          	li	a0,40
    80000708:	b7cd                	j	800006ea <printf+0x170>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b62080e7          	jalr	-1182(ra) # 8000026e <consputc>
      break;
    80000714:	b701                	j	80000614 <printf+0x9a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b56080e7          	jalr	-1194(ra) # 8000026e <consputc>
      consputc(c);
    80000720:	854a                	mv	a0,s2
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b4c080e7          	jalr	-1204(ra) # 8000026e <consputc>
      break;
    8000072a:	b5ed                	j	80000614 <printf+0x9a>
  if(locking)
    8000072c:	020d9163          	bnez	s11,8000074e <printf+0x1d4>
}
    80000730:	70e6                	ld	ra,120(sp)
    80000732:	7446                	ld	s0,112(sp)
    80000734:	74a6                	ld	s1,104(sp)
    80000736:	7906                	ld	s2,96(sp)
    80000738:	69e6                	ld	s3,88(sp)
    8000073a:	6a46                	ld	s4,80(sp)
    8000073c:	6aa6                	ld	s5,72(sp)
    8000073e:	6b06                	ld	s6,64(sp)
    80000740:	7be2                	ld	s7,56(sp)
    80000742:	7c42                	ld	s8,48(sp)
    80000744:	7ca2                	ld	s9,40(sp)
    80000746:	7d02                	ld	s10,32(sp)
    80000748:	6de2                	ld	s11,24(sp)
    8000074a:	6129                	addi	sp,sp,192
    8000074c:	8082                	ret
    release(&pr.lock);
    8000074e:	00011517          	auipc	a0,0x11
    80000752:	ada50513          	addi	a0,a0,-1318 # 80011228 <pr>
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	534080e7          	jalr	1332(ra) # 80000c8a <release>
}
    8000075e:	bfc9                	j	80000730 <printf+0x1b6>

0000000080000760 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000760:	1101                	addi	sp,sp,-32
    80000762:	ec06                	sd	ra,24(sp)
    80000764:	e822                	sd	s0,16(sp)
    80000766:	e426                	sd	s1,8(sp)
    80000768:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076a:	00011497          	auipc	s1,0x11
    8000076e:	abe48493          	addi	s1,s1,-1346 # 80011228 <pr>
    80000772:	00008597          	auipc	a1,0x8
    80000776:	8c658593          	addi	a1,a1,-1850 # 80008038 <etext+0x38>
    8000077a:	8526                	mv	a0,s1
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	3ca080e7          	jalr	970(ra) # 80000b46 <initlock>
  pr.locking = 1;
    80000784:	4785                	li	a5,1
    80000786:	cc9c                	sw	a5,24(s1)
}
    80000788:	60e2                	ld	ra,24(sp)
    8000078a:	6442                	ld	s0,16(sp)
    8000078c:	64a2                	ld	s1,8(sp)
    8000078e:	6105                	addi	sp,sp,32
    80000790:	8082                	ret

0000000080000792 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000792:	1141                	addi	sp,sp,-16
    80000794:	e406                	sd	ra,8(sp)
    80000796:	e022                	sd	s0,0(sp)
    80000798:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079a:	100007b7          	lui	a5,0x10000
    8000079e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a2:	f8000713          	li	a4,-128
    800007a6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007aa:	470d                	li	a4,3
    800007ac:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007b8:	469d                	li	a3,7
    800007ba:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007be:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c2:	00008597          	auipc	a1,0x8
    800007c6:	89658593          	addi	a1,a1,-1898 # 80008058 <digits+0x18>
    800007ca:	00011517          	auipc	a0,0x11
    800007ce:	a7e50513          	addi	a0,a0,-1410 # 80011248 <uart_tx_lock>
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	374080e7          	jalr	884(ra) # 80000b46 <initlock>
}
    800007da:	60a2                	ld	ra,8(sp)
    800007dc:	6402                	ld	s0,0(sp)
    800007de:	0141                	addi	sp,sp,16
    800007e0:	8082                	ret

00000000800007e2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e2:	1101                	addi	sp,sp,-32
    800007e4:	ec06                	sd	ra,24(sp)
    800007e6:	e822                	sd	s0,16(sp)
    800007e8:	e426                	sd	s1,8(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  push_off();
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	39c080e7          	jalr	924(ra) # 80000b8a <push_off>

  if(panicked){
    800007f6:	00009797          	auipc	a5,0x9
    800007fa:	80a7a783          	lw	a5,-2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fe:	10000737          	lui	a4,0x10000
  if(panicked){
    80000802:	c391                	beqz	a5,80000806 <uartputc_sync+0x24>
    for(;;)
    80000804:	a001                	j	80000804 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080a:	0ff7f793          	andi	a5,a5,255
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dbf5                	beqz	a5,80000806 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f793          	andi	a5,s1,255
    80000818:	10000737          	lui	a4,0x10000
    8000081c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	40a080e7          	jalr	1034(ra) # 80000c2a <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008717          	auipc	a4,0x8
    80000836:	7d673703          	ld	a4,2006(a4) # 80009008 <uart_tx_r>
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7d67b783          	ld	a5,2006(a5) # 80009010 <uart_tx_w>
    80000842:	06e78c63          	beq	a5,a4,800008ba <uartstart+0x88>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	0ff7f793          	andi	a5,a5,255
    8000087c:	0207f793          	andi	a5,a5,32
    80000880:	c785                	beqz	a5,800008a8 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f77793          	andi	a5,a4,31
    80000886:	97d2                	add	a5,a5,s4
    80000888:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000088c:	0705                	addi	a4,a4,1
    8000088e:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	94a080e7          	jalr	-1718(ra) # 800021dc <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	6098                	ld	a4,0(s1)
    800008a0:	0009b783          	ld	a5,0(s3)
    800008a4:	fce798e3          	bne	a5,a4,80000874 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	97a50513          	addi	a0,a0,-1670 # 80011248 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	7227a783          	lw	a5,1826(a5) # 80009000 <panicked>
    800008e6:	c391                	beqz	a5,800008ea <uartputc+0x2e>
    for(;;)
    800008e8:	a001                	j	800008e8 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008797          	auipc	a5,0x8
    800008ee:	7267b783          	ld	a5,1830(a5) # 80009010 <uart_tx_w>
    800008f2:	00008717          	auipc	a4,0x8
    800008f6:	71673703          	ld	a4,1814(a4) # 80009008 <uart_tx_r>
    800008fa:	02070713          	addi	a4,a4,32
    800008fe:	02f71b63          	bne	a4,a5,80000934 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000902:	00011a17          	auipc	s4,0x11
    80000906:	946a0a13          	addi	s4,s4,-1722 # 80011248 <uart_tx_lock>
    8000090a:	00008497          	auipc	s1,0x8
    8000090e:	6fe48493          	addi	s1,s1,1790 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00008917          	auipc	s2,0x8
    80000916:	6fe90913          	addi	s2,s2,1790 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85d2                	mv	a1,s4
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	732080e7          	jalr	1842(ra) # 80002050 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093783          	ld	a5,0(s2)
    8000092a:	6098                	ld	a4,0(s1)
    8000092c:	02070713          	addi	a4,a4,32
    80000930:	fef705e3          	beq	a4,a5,8000091a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00011497          	auipc	s1,0x11
    80000938:	91448493          	addi	s1,s1,-1772 # 80011248 <uart_tx_lock>
    8000093c:	01f7f713          	andi	a4,a5,31
    80000940:	9726                	add	a4,a4,s1
    80000942:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000946:	0785                	addi	a5,a5,1
    80000948:	00008717          	auipc	a4,0x8
    8000094c:	6cf73423          	sd	a5,1736(a4) # 80009010 <uart_tx_w>
      uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee2080e7          	jalr	-286(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    int c = uartgetc();
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	fcc080e7          	jalr	-52(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009ae:	00950763          	beq	a0,s1,800009bc <uartintr+0x22>
      break;
    consoleintr(c);
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	8fe080e7          	jalr	-1794(ra) # 800002b0 <consoleintr>
  while(1){
    800009ba:	b7f5                	j	800009a6 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	88c48493          	addi	s1,s1,-1908 # 80011248 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e64080e7          	jalr	-412(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00025797          	auipc	a5,0x25
    80000a02:	60278793          	addi	a5,a5,1538 # 80026000 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00011917          	auipc	s2,0x11
    80000a22:	86290913          	addi	s2,s2,-1950 # 80011280 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ad8080e7          	jalr	-1320(ra) # 80000530 <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	7c650513          	addi	a0,a0,1990 # 80011280 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00025517          	auipc	a0,0x25
    80000ad2:	53250513          	addi	a0,a0,1330 # 80026000 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	79048493          	addi	s1,s1,1936 # 80011280 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	77850513          	addi	a0,a0,1912 # 80011280 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	74c50513          	addi	a0,a0,1868 # 80011280 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e08080e7          	jalr	-504(ra) # 80001978 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dd6080e7          	jalr	-554(ra) # 80001978 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	dca080e7          	jalr	-566(ra) # 80001978 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	db2080e7          	jalr	-590(ra) # 80001978 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d72080e7          	jalr	-654(ra) # 80001978 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	90e080e7          	jalr	-1778(ra) # 80000530 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d46080e7          	jalr	-698(ra) # 80001978 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8be080e7          	jalr	-1858(ra) # 80000530 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8ae080e7          	jalr	-1874(ra) # 80000530 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	866080e7          	jalr	-1946(ra) # 80000530 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ce09                	beqz	a2,80000cf2 <memset+0x20>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	fff6071b          	addiw	a4,a2,-1
    80000ce0:	1702                	slli	a4,a4,0x20
    80000ce2:	9301                	srli	a4,a4,0x20
    80000ce4:	0705                	addi	a4,a4,1
    80000ce6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000ce8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cec:	0785                	addi	a5,a5,1
    80000cee:	fee79de3          	bne	a5,a4,80000ce8 <memset+0x16>
  }
  return dst;
}
    80000cf2:	6422                	ld	s0,8(sp)
    80000cf4:	0141                	addi	sp,sp,16
    80000cf6:	8082                	ret

0000000080000cf8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfe:	ca05                	beqz	a2,80000d2e <memcmp+0x36>
    80000d00:	fff6069b          	addiw	a3,a2,-1
    80000d04:	1682                	slli	a3,a3,0x20
    80000d06:	9281                	srli	a3,a3,0x20
    80000d08:	0685                	addi	a3,a3,1
    80000d0a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d0c:	00054783          	lbu	a5,0(a0)
    80000d10:	0005c703          	lbu	a4,0(a1)
    80000d14:	00e79863          	bne	a5,a4,80000d24 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d18:	0505                	addi	a0,a0,1
    80000d1a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d1c:	fed518e3          	bne	a0,a3,80000d0c <memcmp+0x14>
  }

  return 0;
    80000d20:	4501                	li	a0,0
    80000d22:	a019                	j	80000d28 <memcmp+0x30>
      return *s1 - *s2;
    80000d24:	40e7853b          	subw	a0,a5,a4
}
    80000d28:	6422                	ld	s0,8(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret
  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	bfe5                	j	80000d28 <memcmp+0x30>

0000000080000d32 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d38:	00a5f963          	bgeu	a1,a0,80000d4a <memmove+0x18>
    80000d3c:	02061713          	slli	a4,a2,0x20
    80000d40:	9301                	srli	a4,a4,0x20
    80000d42:	00e587b3          	add	a5,a1,a4
    80000d46:	02f56563          	bltu	a0,a5,80000d70 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d4a:	fff6069b          	addiw	a3,a2,-1
    80000d4e:	ce11                	beqz	a2,80000d6a <memmove+0x38>
    80000d50:	1682                	slli	a3,a3,0x20
    80000d52:	9281                	srli	a3,a3,0x20
    80000d54:	0685                	addi	a3,a3,1
    80000d56:	96ae                	add	a3,a3,a1
    80000d58:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d5a:	0585                	addi	a1,a1,1
    80000d5c:	0785                	addi	a5,a5,1
    80000d5e:	fff5c703          	lbu	a4,-1(a1)
    80000d62:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d66:	fed59ae3          	bne	a1,a3,80000d5a <memmove+0x28>

  return dst;
}
    80000d6a:	6422                	ld	s0,8(sp)
    80000d6c:	0141                	addi	sp,sp,16
    80000d6e:	8082                	ret
    d += n;
    80000d70:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d72:	fff6069b          	addiw	a3,a2,-1
    80000d76:	da75                	beqz	a2,80000d6a <memmove+0x38>
    80000d78:	02069613          	slli	a2,a3,0x20
    80000d7c:	9201                	srli	a2,a2,0x20
    80000d7e:	fff64613          	not	a2,a2
    80000d82:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d84:	17fd                	addi	a5,a5,-1
    80000d86:	177d                	addi	a4,a4,-1
    80000d88:	0007c683          	lbu	a3,0(a5)
    80000d8c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d90:	fec79ae3          	bne	a5,a2,80000d84 <memmove+0x52>
    80000d94:	bfd9                	j	80000d6a <memmove+0x38>

0000000080000d96 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e406                	sd	ra,8(sp)
    80000d9a:	e022                	sd	s0,0(sp)
    80000d9c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d9e:	00000097          	auipc	ra,0x0
    80000da2:	f94080e7          	jalr	-108(ra) # 80000d32 <memmove>
}
    80000da6:	60a2                	ld	ra,8(sp)
    80000da8:	6402                	ld	s0,0(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret

0000000080000dae <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e422                	sd	s0,8(sp)
    80000db2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000db4:	ce11                	beqz	a2,80000dd0 <strncmp+0x22>
    80000db6:	00054783          	lbu	a5,0(a0)
    80000dba:	cf89                	beqz	a5,80000dd4 <strncmp+0x26>
    80000dbc:	0005c703          	lbu	a4,0(a1)
    80000dc0:	00f71a63          	bne	a4,a5,80000dd4 <strncmp+0x26>
    n--, p++, q++;
    80000dc4:	367d                	addiw	a2,a2,-1
    80000dc6:	0505                	addi	a0,a0,1
    80000dc8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dca:	f675                	bnez	a2,80000db6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dcc:	4501                	li	a0,0
    80000dce:	a809                	j	80000de0 <strncmp+0x32>
    80000dd0:	4501                	li	a0,0
    80000dd2:	a039                	j	80000de0 <strncmp+0x32>
  if(n == 0)
    80000dd4:	ca09                	beqz	a2,80000de6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dd6:	00054503          	lbu	a0,0(a0)
    80000dda:	0005c783          	lbu	a5,0(a1)
    80000dde:	9d1d                	subw	a0,a0,a5
}
    80000de0:	6422                	ld	s0,8(sp)
    80000de2:	0141                	addi	sp,sp,16
    80000de4:	8082                	ret
    return 0;
    80000de6:	4501                	li	a0,0
    80000de8:	bfe5                	j	80000de0 <strncmp+0x32>

0000000080000dea <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dea:	1141                	addi	sp,sp,-16
    80000dec:	e422                	sd	s0,8(sp)
    80000dee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000df0:	872a                	mv	a4,a0
    80000df2:	8832                	mv	a6,a2
    80000df4:	367d                	addiw	a2,a2,-1
    80000df6:	01005963          	blez	a6,80000e08 <strncpy+0x1e>
    80000dfa:	0705                	addi	a4,a4,1
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	fef70fa3          	sb	a5,-1(a4)
    80000e04:	0585                	addi	a1,a1,1
    80000e06:	f7f5                	bnez	a5,80000df2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e08:	00c05d63          	blez	a2,80000e22 <strncpy+0x38>
    80000e0c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e0e:	0685                	addi	a3,a3,1
    80000e10:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e14:	fff6c793          	not	a5,a3
    80000e18:	9fb9                	addw	a5,a5,a4
    80000e1a:	010787bb          	addw	a5,a5,a6
    80000e1e:	fef048e3          	bgtz	a5,80000e0e <strncpy+0x24>
  return os;
}
    80000e22:	6422                	ld	s0,8(sp)
    80000e24:	0141                	addi	sp,sp,16
    80000e26:	8082                	ret

0000000080000e28 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e28:	1141                	addi	sp,sp,-16
    80000e2a:	e422                	sd	s0,8(sp)
    80000e2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e2e:	02c05363          	blez	a2,80000e54 <safestrcpy+0x2c>
    80000e32:	fff6069b          	addiw	a3,a2,-1
    80000e36:	1682                	slli	a3,a3,0x20
    80000e38:	9281                	srli	a3,a3,0x20
    80000e3a:	96ae                	add	a3,a3,a1
    80000e3c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e3e:	00d58963          	beq	a1,a3,80000e50 <safestrcpy+0x28>
    80000e42:	0585                	addi	a1,a1,1
    80000e44:	0785                	addi	a5,a5,1
    80000e46:	fff5c703          	lbu	a4,-1(a1)
    80000e4a:	fee78fa3          	sb	a4,-1(a5)
    80000e4e:	fb65                	bnez	a4,80000e3e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e50:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <strlen>:

int
strlen(const char *s)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e60:	00054783          	lbu	a5,0(a0)
    80000e64:	cf91                	beqz	a5,80000e80 <strlen+0x26>
    80000e66:	0505                	addi	a0,a0,1
    80000e68:	87aa                	mv	a5,a0
    80000e6a:	4685                	li	a3,1
    80000e6c:	9e89                	subw	a3,a3,a0
    80000e6e:	00f6853b          	addw	a0,a3,a5
    80000e72:	0785                	addi	a5,a5,1
    80000e74:	fff7c703          	lbu	a4,-1(a5)
    80000e78:	fb7d                	bnez	a4,80000e6e <strlen+0x14>
    ;
  return n;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e80:	4501                	li	a0,0
    80000e82:	bfe5                	j	80000e7a <strlen+0x20>

0000000080000e84 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e84:	1141                	addi	sp,sp,-16
    80000e86:	e406                	sd	ra,8(sp)
    80000e88:	e022                	sd	s0,0(sp)
    80000e8a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e8c:	00001097          	auipc	ra,0x1
    80000e90:	adc080e7          	jalr	-1316(ra) # 80001968 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e94:	00008717          	auipc	a4,0x8
    80000e98:	18470713          	addi	a4,a4,388 # 80009018 <started>
  if(cpuid() == 0){
    80000e9c:	c139                	beqz	a0,80000ee2 <main+0x5e>
    while(started == 0)
    80000e9e:	431c                	lw	a5,0(a4)
    80000ea0:	2781                	sext.w	a5,a5
    80000ea2:	dff5                	beqz	a5,80000e9e <main+0x1a>
      ;
    __sync_synchronize();
    80000ea4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ea8:	00001097          	auipc	ra,0x1
    80000eac:	ac0080e7          	jalr	-1344(ra) # 80001968 <cpuid>
    80000eb0:	85aa                	mv	a1,a0
    80000eb2:	00007517          	auipc	a0,0x7
    80000eb6:	20650513          	addi	a0,a0,518 # 800080b8 <digits+0x78>
    80000eba:	fffff097          	auipc	ra,0xfffff
    80000ebe:	6c0080e7          	jalr	1728(ra) # 8000057a <printf>
    kvminithart();    // turn on paging
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	0d8080e7          	jalr	216(ra) # 80000f9a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eca:	00001097          	auipc	ra,0x1
    80000ece:	716080e7          	jalr	1814(ra) # 800025e0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed2:	00005097          	auipc	ra,0x5
    80000ed6:	cae080e7          	jalr	-850(ra) # 80005b80 <plicinithart>
  }

  scheduler();        
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	fc4080e7          	jalr	-60(ra) # 80001e9e <scheduler>
    consoleinit();
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	560080e7          	jalr	1376(ra) # 80000442 <consoleinit>
    printfinit();
    80000eea:	00000097          	auipc	ra,0x0
    80000eee:	876080e7          	jalr	-1930(ra) # 80000760 <printfinit>
    printf("\n");
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	1d650513          	addi	a0,a0,470 # 800080c8 <digits+0x88>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	680080e7          	jalr	1664(ra) # 8000057a <printf>
    printf("xv6 kernel is booting\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	19e50513          	addi	a0,a0,414 # 800080a0 <digits+0x60>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	670080e7          	jalr	1648(ra) # 8000057a <printf>
    printf("\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	1b650513          	addi	a0,a0,438 # 800080c8 <digits+0x88>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	660080e7          	jalr	1632(ra) # 8000057a <printf>
    kinit();         // physical page allocator
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	b88080e7          	jalr	-1144(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	310080e7          	jalr	784(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	068080e7          	jalr	104(ra) # 80000f9a <kvminithart>
    procinit();      // process table
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	97e080e7          	jalr	-1666(ra) # 800018b8 <procinit>
    trapinit();      // trap vectors
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	676080e7          	jalr	1654(ra) # 800025b8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	696080e7          	jalr	1686(ra) # 800025e0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	c18080e7          	jalr	-1000(ra) # 80005b6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	c26080e7          	jalr	-986(ra) # 80005b80 <plicinithart>
    binit();         // buffer cache
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	e02080e7          	jalr	-510(ra) # 80002d64 <binit>
    iinit();         // inode cache
    80000f6a:	00002097          	auipc	ra,0x2
    80000f6e:	492080e7          	jalr	1170(ra) # 800033fc <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	43c080e7          	jalr	1084(ra) # 800043ae <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	d28080e7          	jalr	-728(ra) # 80005ca2 <virtio_disk_init>
    userinit();      // first user process
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	cea080e7          	jalr	-790(ra) # 80001c6c <userinit>
    __sync_synchronize();
    80000f8a:	0ff0000f          	fence
    started = 1;
    80000f8e:	4785                	li	a5,1
    80000f90:	00008717          	auipc	a4,0x8
    80000f94:	08f72423          	sw	a5,136(a4) # 80009018 <started>
    80000f98:	b789                	j	80000eda <main+0x56>

0000000080000f9a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f9a:	1141                	addi	sp,sp,-16
    80000f9c:	e422                	sd	s0,8(sp)
    80000f9e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa0:	00008797          	auipc	a5,0x8
    80000fa4:	0807b783          	ld	a5,128(a5) # 80009020 <kernel_pagetable>
    80000fa8:	83b1                	srli	a5,a5,0xc
    80000faa:	577d                	li	a4,-1
    80000fac:	177e                	slli	a4,a4,0x3f
    80000fae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fb0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma
  sfence_vma();
}
    80000fb8:	6422                	ld	s0,8(sp)
    80000fba:	0141                	addi	sp,sp,16
    80000fbc:	8082                	ret

0000000080000fbe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fbe:	7139                	addi	sp,sp,-64
    80000fc0:	fc06                	sd	ra,56(sp)
    80000fc2:	f822                	sd	s0,48(sp)
    80000fc4:	f426                	sd	s1,40(sp)
    80000fc6:	f04a                	sd	s2,32(sp)
    80000fc8:	ec4e                	sd	s3,24(sp)
    80000fca:	e852                	sd	s4,16(sp)
    80000fcc:	e456                	sd	s5,8(sp)
    80000fce:	e05a                	sd	s6,0(sp)
    80000fd0:	0080                	addi	s0,sp,64
    80000fd2:	84aa                	mv	s1,a0
    80000fd4:	89ae                	mv	s3,a1
    80000fd6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd8:	57fd                	li	a5,-1
    80000fda:	83e9                	srli	a5,a5,0x1a
    80000fdc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fde:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fe0:	04b7f263          	bgeu	a5,a1,80001024 <walk+0x66>
    panic("walk");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0ec50513          	addi	a0,a0,236 # 800080d0 <digits+0x90>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	544080e7          	jalr	1348(ra) # 80000530 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ff4:	060a8663          	beqz	s5,80001060 <walk+0xa2>
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	aee080e7          	jalr	-1298(ra) # 80000ae6 <kalloc>
    80001000:	84aa                	mv	s1,a0
    80001002:	c529                	beqz	a0,8000104c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001004:	6605                	lui	a2,0x1
    80001006:	4581                	li	a1,0
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	cca080e7          	jalr	-822(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001010:	00c4d793          	srli	a5,s1,0xc
    80001014:	07aa                	slli	a5,a5,0xa
    80001016:	0017e793          	ori	a5,a5,1
    8000101a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000101e:	3a5d                	addiw	s4,s4,-9
    80001020:	036a0063          	beq	s4,s6,80001040 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001024:	0149d933          	srl	s2,s3,s4
    80001028:	1ff97913          	andi	s2,s2,511
    8000102c:	090e                	slli	s2,s2,0x3
    8000102e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001030:	00093483          	ld	s1,0(s2)
    80001034:	0014f793          	andi	a5,s1,1
    80001038:	dfd5                	beqz	a5,80000ff4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000103a:	80a9                	srli	s1,s1,0xa
    8000103c:	04b2                	slli	s1,s1,0xc
    8000103e:	b7c5                	j	8000101e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001040:	00c9d513          	srli	a0,s3,0xc
    80001044:	1ff57513          	andi	a0,a0,511
    80001048:	050e                	slli	a0,a0,0x3
    8000104a:	9526                	add	a0,a0,s1
}
    8000104c:	70e2                	ld	ra,56(sp)
    8000104e:	7442                	ld	s0,48(sp)
    80001050:	74a2                	ld	s1,40(sp)
    80001052:	7902                	ld	s2,32(sp)
    80001054:	69e2                	ld	s3,24(sp)
    80001056:	6a42                	ld	s4,16(sp)
    80001058:	6aa2                	ld	s5,8(sp)
    8000105a:	6b02                	ld	s6,0(sp)
    8000105c:	6121                	addi	sp,sp,64
    8000105e:	8082                	ret
        return 0;
    80001060:	4501                	li	a0,0
    80001062:	b7ed                	j	8000104c <walk+0x8e>

0000000080001064 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	00b7f463          	bgeu	a5,a1,80001070 <walkaddr+0xc>
    return 0;
    8000106c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000106e:	8082                	ret
{
    80001070:	1141                	addi	sp,sp,-16
    80001072:	e406                	sd	ra,8(sp)
    80001074:	e022                	sd	s0,0(sp)
    80001076:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001078:	4601                	li	a2,0
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	f44080e7          	jalr	-188(ra) # 80000fbe <walk>
  if(pte == 0)
    80001082:	c105                	beqz	a0,800010a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001084:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001086:	0117f693          	andi	a3,a5,17
    8000108a:	4745                	li	a4,17
    return 0;
    8000108c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000108e:	00e68663          	beq	a3,a4,8000109a <walkaddr+0x36>
}
    80001092:	60a2                	ld	ra,8(sp)
    80001094:	6402                	ld	s0,0(sp)
    80001096:	0141                	addi	sp,sp,16
    80001098:	8082                	ret
  pa = PTE2PA(*pte);
    8000109a:	00a7d513          	srli	a0,a5,0xa
    8000109e:	0532                	slli	a0,a0,0xc
  return pa;
    800010a0:	bfcd                	j	80001092 <walkaddr+0x2e>
    return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7fd                	j	80001092 <walkaddr+0x2e>

00000000800010a6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010a6:	715d                	addi	sp,sp,-80
    800010a8:	e486                	sd	ra,72(sp)
    800010aa:	e0a2                	sd	s0,64(sp)
    800010ac:	fc26                	sd	s1,56(sp)
    800010ae:	f84a                	sd	s2,48(sp)
    800010b0:	f44e                	sd	s3,40(sp)
    800010b2:	f052                	sd	s4,32(sp)
    800010b4:	ec56                	sd	s5,24(sp)
    800010b6:	e85a                	sd	s6,16(sp)
    800010b8:	e45e                	sd	s7,8(sp)
    800010ba:	0880                	addi	s0,sp,80
    800010bc:	8aaa                	mv	s5,a0
    800010be:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010c0:	777d                	lui	a4,0xfffff
    800010c2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c6:	167d                	addi	a2,a2,-1
    800010c8:	00b609b3          	add	s3,a2,a1
    800010cc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010d0:	893e                	mv	s2,a5
    800010d2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d6:	6b85                	lui	s7,0x1
    800010d8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010dc:	4605                	li	a2,1
    800010de:	85ca                	mv	a1,s2
    800010e0:	8556                	mv	a0,s5
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	edc080e7          	jalr	-292(ra) # 80000fbe <walk>
    800010ea:	c51d                	beqz	a0,80001118 <mappages+0x72>
    if(*pte & PTE_V)
    800010ec:	611c                	ld	a5,0(a0)
    800010ee:	8b85                	andi	a5,a5,1
    800010f0:	ef81                	bnez	a5,80001108 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010f2:	80b1                	srli	s1,s1,0xc
    800010f4:	04aa                	slli	s1,s1,0xa
    800010f6:	0164e4b3          	or	s1,s1,s6
    800010fa:	0014e493          	ori	s1,s1,1
    800010fe:	e104                	sd	s1,0(a0)
    if(a == last)
    80001100:	03390863          	beq	s2,s3,80001130 <mappages+0x8a>
    a += PGSIZE;
    80001104:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001106:	bfc9                	j	800010d8 <mappages+0x32>
      panic("remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fd050513          	addi	a0,a0,-48 # 800080d8 <digits+0x98>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	420080e7          	jalr	1056(ra) # 80000530 <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x74>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f64080e7          	jalr	-156(ra) # 800010a6 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	f8c50513          	addi	a0,a0,-116 # 800080e0 <digits+0xa0>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3d4080e7          	jalr	980(ra) # 80000530 <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	976080e7          	jalr	-1674(ra) # 80000ae6 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b54080e7          	jalr	-1196(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	5fe080e7          	jalr	1534(ra) # 80001822 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e863          	bltu	a1,s3,800012f6 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e4850513          	addi	a0,a0,-440 # 800080e8 <digits+0xa8>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	288080e7          	jalr	648(ra) # 80000530 <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e5050513          	addi	a0,a0,-432 # 80008100 <digits+0xc0>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	278080e7          	jalr	632(ra) # 80000530 <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e5050513          	addi	a0,a0,-432 # 80008110 <digits+0xd0>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	268080e7          	jalr	616(ra) # 80000530 <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e5850513          	addi	a0,a0,-424 # 80008128 <digits+0xe8>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	258080e7          	jalr	600(ra) # 80000530 <panic>
      uint64 pa = PTE2PA(*pte);
    800012e0:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012e2:	0532                	slli	a0,a0,0xc
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	706080e7          	jalr	1798(ra) # 800009ea <kfree>
    *pte = 0;
    800012ec:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f0:	995a                	add	s2,s2,s6
    800012f2:	f9397ce3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f6:	4601                	li	a2,0
    800012f8:	85ca                	mv	a1,s2
    800012fa:	8552                	mv	a0,s4
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	cc2080e7          	jalr	-830(ra) # 80000fbe <walk>
    80001304:	84aa                	mv	s1,a0
    80001306:	d54d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001308:	6108                	ld	a0,0(a0)
    8000130a:	00157793          	andi	a5,a0,1
    8000130e:	dbcd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001310:	3ff57793          	andi	a5,a0,1023
    80001314:	fb778ee3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    80001318:	fc0a8ae3          	beqz	s5,800012ec <uvmunmap+0x92>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7be080e7          	jalr	1982(ra) # 80000ae6 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	99a080e7          	jalr	-1638(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	77e080e7          	jalr	1918(ra) # 80000ae6 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	95c080e7          	jalr	-1700(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d1e080e7          	jalr	-738(ra) # 800010a6 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	99c080e7          	jalr	-1636(ra) # 80000d32 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	d9250513          	addi	a0,a0,-622 # 80008140 <digits+0x100>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	17a080e7          	jalr	378(ra) # 80000530 <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	767d                	lui	a2,0xfffff
    800013da:	8f71                	and	a4,a4,a2
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff1                	and	a5,a5,a2
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6985                	lui	s3,0x1
    80001422:	19fd                	addi	s3,s3,-1
    80001424:	95ce                	add	a1,a1,s3
    80001426:	79fd                	lui	s3,0xfffff
    80001428:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6b4080e7          	jalr	1716(ra) # 80000ae6 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	890080e7          	jalr	-1904(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c52080e7          	jalr	-942(ra) # 800010a6 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	55c080e7          	jalr	1372(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a821                	j	800014e2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ce:	0532                	slli	a0,a0,0xc
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	fe0080e7          	jalr	-32(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014d8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014dc:	04a1                	addi	s1,s1,8
    800014de:	03248163          	beq	s1,s2,80001500 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014e2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	00f57793          	andi	a5,a0,15
    800014e8:	ff3782e3          	beq	a5,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ec:	8905                	andi	a0,a0,1
    800014ee:	d57d                	beqz	a0,800014dc <freewalk+0x2c>
      panic("freewalk: leaf");
    800014f0:	00007517          	auipc	a0,0x7
    800014f4:	c7050513          	addi	a0,a0,-912 # 80008160 <digits+0x120>
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	038080e7          	jalr	56(ra) # 80000530 <panic>
    }
  }
  kfree((void*)pagetable);
    80001500:	8552                	mv	a0,s4
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	4e8080e7          	jalr	1256(ra) # 800009ea <kfree>
}
    8000150a:	70a2                	ld	ra,40(sp)
    8000150c:	7402                	ld	s0,32(sp)
    8000150e:	64e2                	ld	s1,24(sp)
    80001510:	6942                	ld	s2,16(sp)
    80001512:	69a2                	ld	s3,8(sp)
    80001514:	6a02                	ld	s4,0(sp)
    80001516:	6145                	addi	sp,sp,48
    80001518:	8082                	ret

000000008000151a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151a:	1101                	addi	sp,sp,-32
    8000151c:	ec06                	sd	ra,24(sp)
    8000151e:	e822                	sd	s0,16(sp)
    80001520:	e426                	sd	s1,8(sp)
    80001522:	1000                	addi	s0,sp,32
    80001524:	84aa                	mv	s1,a0
  if(sz > 0)
    80001526:	e999                	bnez	a1,8000153c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001528:	8526                	mv	a0,s1
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	f86080e7          	jalr	-122(ra) # 800014b0 <freewalk>
}
    80001532:	60e2                	ld	ra,24(sp)
    80001534:	6442                	ld	s0,16(sp)
    80001536:	64a2                	ld	s1,8(sp)
    80001538:	6105                	addi	sp,sp,32
    8000153a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153c:	6605                	lui	a2,0x1
    8000153e:	167d                	addi	a2,a2,-1
    80001540:	962e                	add	a2,a2,a1
    80001542:	4685                	li	a3,1
    80001544:	8231                	srli	a2,a2,0xc
    80001546:	4581                	li	a1,0
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	d12080e7          	jalr	-750(ra) # 8000125a <uvmunmap>
    80001550:	bfe1                	j	80001528 <uvmfree+0xe>

0000000080001552 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001552:	c679                	beqz	a2,80001620 <uvmcopy+0xce>
{
    80001554:	715d                	addi	sp,sp,-80
    80001556:	e486                	sd	ra,72(sp)
    80001558:	e0a2                	sd	s0,64(sp)
    8000155a:	fc26                	sd	s1,56(sp)
    8000155c:	f84a                	sd	s2,48(sp)
    8000155e:	f44e                	sd	s3,40(sp)
    80001560:	f052                	sd	s4,32(sp)
    80001562:	ec56                	sd	s5,24(sp)
    80001564:	e85a                	sd	s6,16(sp)
    80001566:	e45e                	sd	s7,8(sp)
    80001568:	0880                	addi	s0,sp,80
    8000156a:	8b2a                	mv	s6,a0
    8000156c:	8aae                	mv	s5,a1
    8000156e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001570:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001572:	4601                	li	a2,0
    80001574:	85ce                	mv	a1,s3
    80001576:	855a                	mv	a0,s6
    80001578:	00000097          	auipc	ra,0x0
    8000157c:	a46080e7          	jalr	-1466(ra) # 80000fbe <walk>
    80001580:	c531                	beqz	a0,800015cc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001582:	6118                	ld	a4,0(a0)
    80001584:	00177793          	andi	a5,a4,1
    80001588:	cbb1                	beqz	a5,800015dc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158a:	00a75593          	srli	a1,a4,0xa
    8000158e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001592:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001596:	fffff097          	auipc	ra,0xfffff
    8000159a:	550080e7          	jalr	1360(ra) # 80000ae6 <kalloc>
    8000159e:	892a                	mv	s2,a0
    800015a0:	c939                	beqz	a0,800015f6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a2:	6605                	lui	a2,0x1
    800015a4:	85de                	mv	a1,s7
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	78c080e7          	jalr	1932(ra) # 80000d32 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ae:	8726                	mv	a4,s1
    800015b0:	86ca                	mv	a3,s2
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85ce                	mv	a1,s3
    800015b6:	8556                	mv	a0,s5
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	aee080e7          	jalr	-1298(ra) # 800010a6 <mappages>
    800015c0:	e515                	bnez	a0,800015ec <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c2:	6785                	lui	a5,0x1
    800015c4:	99be                	add	s3,s3,a5
    800015c6:	fb49e6e3          	bltu	s3,s4,80001572 <uvmcopy+0x20>
    800015ca:	a081                	j	8000160a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015cc:	00007517          	auipc	a0,0x7
    800015d0:	ba450513          	addi	a0,a0,-1116 # 80008170 <digits+0x130>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	f5c080e7          	jalr	-164(ra) # 80000530 <panic>
      panic("uvmcopy: page not present");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bb450513          	addi	a0,a0,-1100 # 80008190 <digits+0x150>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f4c080e7          	jalr	-180(ra) # 80000530 <panic>
      kfree(mem);
    800015ec:	854a                	mv	a0,s2
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	3fc080e7          	jalr	1020(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015f6:	4685                	li	a3,1
    800015f8:	00c9d613          	srli	a2,s3,0xc
    800015fc:	4581                	li	a1,0
    800015fe:	8556                	mv	a0,s5
    80001600:	00000097          	auipc	ra,0x0
    80001604:	c5a080e7          	jalr	-934(ra) # 8000125a <uvmunmap>
  return -1;
    80001608:	557d                	li	a0,-1
}
    8000160a:	60a6                	ld	ra,72(sp)
    8000160c:	6406                	ld	s0,64(sp)
    8000160e:	74e2                	ld	s1,56(sp)
    80001610:	7942                	ld	s2,48(sp)
    80001612:	79a2                	ld	s3,40(sp)
    80001614:	7a02                	ld	s4,32(sp)
    80001616:	6ae2                	ld	s5,24(sp)
    80001618:	6b42                	ld	s6,16(sp)
    8000161a:	6ba2                	ld	s7,8(sp)
    8000161c:	6161                	addi	sp,sp,80
    8000161e:	8082                	ret
  return 0;
    80001620:	4501                	li	a0,0
}
    80001622:	8082                	ret

0000000080001624 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001624:	1141                	addi	sp,sp,-16
    80001626:	e406                	sd	ra,8(sp)
    80001628:	e022                	sd	s0,0(sp)
    8000162a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000162c:	4601                	li	a2,0
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	990080e7          	jalr	-1648(ra) # 80000fbe <walk>
  if(pte == 0)
    80001636:	c901                	beqz	a0,80001646 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001638:	611c                	ld	a5,0(a0)
    8000163a:	9bbd                	andi	a5,a5,-17
    8000163c:	e11c                	sd	a5,0(a0)
}
    8000163e:	60a2                	ld	ra,8(sp)
    80001640:	6402                	ld	s0,0(sp)
    80001642:	0141                	addi	sp,sp,16
    80001644:	8082                	ret
    panic("uvmclear");
    80001646:	00007517          	auipc	a0,0x7
    8000164a:	b6a50513          	addi	a0,a0,-1174 # 800081b0 <digits+0x170>
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	ee2080e7          	jalr	-286(ra) # 80000530 <panic>

0000000080001656 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001656:	c6bd                	beqz	a3,800016c4 <copyout+0x6e>
{
    80001658:	715d                	addi	sp,sp,-80
    8000165a:	e486                	sd	ra,72(sp)
    8000165c:	e0a2                	sd	s0,64(sp)
    8000165e:	fc26                	sd	s1,56(sp)
    80001660:	f84a                	sd	s2,48(sp)
    80001662:	f44e                	sd	s3,40(sp)
    80001664:	f052                	sd	s4,32(sp)
    80001666:	ec56                	sd	s5,24(sp)
    80001668:	e85a                	sd	s6,16(sp)
    8000166a:	e45e                	sd	s7,8(sp)
    8000166c:	e062                	sd	s8,0(sp)
    8000166e:	0880                	addi	s0,sp,80
    80001670:	8b2a                	mv	s6,a0
    80001672:	8c2e                	mv	s8,a1
    80001674:	8a32                	mv	s4,a2
    80001676:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001678:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167a:	6a85                	lui	s5,0x1
    8000167c:	a015                	j	800016a0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000167e:	9562                	add	a0,a0,s8
    80001680:	0004861b          	sext.w	a2,s1
    80001684:	85d2                	mv	a1,s4
    80001686:	41250533          	sub	a0,a0,s2
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	6a8080e7          	jalr	1704(ra) # 80000d32 <memmove>

    len -= n;
    80001692:	409989b3          	sub	s3,s3,s1
    src += n;
    80001696:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001698:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000169c:	02098263          	beqz	s3,800016c0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a4:	85ca                	mv	a1,s2
    800016a6:	855a                	mv	a0,s6
    800016a8:	00000097          	auipc	ra,0x0
    800016ac:	9bc080e7          	jalr	-1604(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800016b0:	cd01                	beqz	a0,800016c8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b2:	418904b3          	sub	s1,s2,s8
    800016b6:	94d6                	add	s1,s1,s5
    if(n > len)
    800016b8:	fc99f3e3          	bgeu	s3,s1,8000167e <copyout+0x28>
    800016bc:	84ce                	mv	s1,s3
    800016be:	b7c1                	j	8000167e <copyout+0x28>
  }
  return 0;
    800016c0:	4501                	li	a0,0
    800016c2:	a021                	j	800016ca <copyout+0x74>
    800016c4:	4501                	li	a0,0
}
    800016c6:	8082                	ret
      return -1;
    800016c8:	557d                	li	a0,-1
}
    800016ca:	60a6                	ld	ra,72(sp)
    800016cc:	6406                	ld	s0,64(sp)
    800016ce:	74e2                	ld	s1,56(sp)
    800016d0:	7942                	ld	s2,48(sp)
    800016d2:	79a2                	ld	s3,40(sp)
    800016d4:	7a02                	ld	s4,32(sp)
    800016d6:	6ae2                	ld	s5,24(sp)
    800016d8:	6b42                	ld	s6,16(sp)
    800016da:	6ba2                	ld	s7,8(sp)
    800016dc:	6c02                	ld	s8,0(sp)
    800016de:	6161                	addi	sp,sp,80
    800016e0:	8082                	ret

00000000800016e2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	c6bd                	beqz	a3,80001750 <copyin+0x6e>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8a2e                	mv	s4,a1
    80001700:	8c32                	mv	s8,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a015                	j	8000172c <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170a:	9562                	add	a0,a0,s8
    8000170c:	0004861b          	sext.w	a2,s1
    80001710:	412505b3          	sub	a1,a0,s2
    80001714:	8552                	mv	a0,s4
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	61c080e7          	jalr	1564(ra) # 80000d32 <memmove>

    len -= n;
    8000171e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001722:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001724:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001728:	02098263          	beqz	s3,8000174c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000172c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001730:	85ca                	mv	a1,s2
    80001732:	855a                	mv	a0,s6
    80001734:	00000097          	auipc	ra,0x0
    80001738:	930080e7          	jalr	-1744(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    8000173c:	cd01                	beqz	a0,80001754 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000173e:	418904b3          	sub	s1,s2,s8
    80001742:	94d6                	add	s1,s1,s5
    if(n > len)
    80001744:	fc99f3e3          	bgeu	s3,s1,8000170a <copyin+0x28>
    80001748:	84ce                	mv	s1,s3
    8000174a:	b7c1                	j	8000170a <copyin+0x28>
  }
  return 0;
    8000174c:	4501                	li	a0,0
    8000174e:	a021                	j	80001756 <copyin+0x74>
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret
      return -1;
    80001754:	557d                	li	a0,-1
}
    80001756:	60a6                	ld	ra,72(sp)
    80001758:	6406                	ld	s0,64(sp)
    8000175a:	74e2                	ld	s1,56(sp)
    8000175c:	7942                	ld	s2,48(sp)
    8000175e:	79a2                	ld	s3,40(sp)
    80001760:	7a02                	ld	s4,32(sp)
    80001762:	6ae2                	ld	s5,24(sp)
    80001764:	6b42                	ld	s6,16(sp)
    80001766:	6ba2                	ld	s7,8(sp)
    80001768:	6c02                	ld	s8,0(sp)
    8000176a:	6161                	addi	sp,sp,80
    8000176c:	8082                	ret

000000008000176e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000176e:	c6c5                	beqz	a3,80001816 <copyinstr+0xa8>
{
    80001770:	715d                	addi	sp,sp,-80
    80001772:	e486                	sd	ra,72(sp)
    80001774:	e0a2                	sd	s0,64(sp)
    80001776:	fc26                	sd	s1,56(sp)
    80001778:	f84a                	sd	s2,48(sp)
    8000177a:	f44e                	sd	s3,40(sp)
    8000177c:	f052                	sd	s4,32(sp)
    8000177e:	ec56                	sd	s5,24(sp)
    80001780:	e85a                	sd	s6,16(sp)
    80001782:	e45e                	sd	s7,8(sp)
    80001784:	0880                	addi	s0,sp,80
    80001786:	8a2a                	mv	s4,a0
    80001788:	8b2e                	mv	s6,a1
    8000178a:	8bb2                	mv	s7,a2
    8000178c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000178e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001790:	6985                	lui	s3,0x1
    80001792:	a035                	j	800017be <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001794:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001798:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000179a:	0017b793          	seqz	a5,a5
    8000179e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a2:	60a6                	ld	ra,72(sp)
    800017a4:	6406                	ld	s0,64(sp)
    800017a6:	74e2                	ld	s1,56(sp)
    800017a8:	7942                	ld	s2,48(sp)
    800017aa:	79a2                	ld	s3,40(sp)
    800017ac:	7a02                	ld	s4,32(sp)
    800017ae:	6ae2                	ld	s5,24(sp)
    800017b0:	6b42                	ld	s6,16(sp)
    800017b2:	6ba2                	ld	s7,8(sp)
    800017b4:	6161                	addi	sp,sp,80
    800017b6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017b8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017bc:	c8a9                	beqz	s1,8000180e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017be:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c2:	85ca                	mv	a1,s2
    800017c4:	8552                	mv	a0,s4
    800017c6:	00000097          	auipc	ra,0x0
    800017ca:	89e080e7          	jalr	-1890(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800017ce:	c131                	beqz	a0,80001812 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017d0:	41790833          	sub	a6,s2,s7
    800017d4:	984e                	add	a6,a6,s3
    if(n > max)
    800017d6:	0104f363          	bgeu	s1,a6,800017dc <copyinstr+0x6e>
    800017da:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017dc:	955e                	add	a0,a0,s7
    800017de:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e2:	fc080be3          	beqz	a6,800017b8 <copyinstr+0x4a>
    800017e6:	985a                	add	a6,a6,s6
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	14fd                	addi	s1,s1,-1
    800017f0:	9b26                	add	s6,s6,s1
    800017f2:	00f60733          	add	a4,a2,a5
    800017f6:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800017fa:	df49                	beqz	a4,80001794 <copyinstr+0x26>
        *dst = *p;
    800017fc:	00e78023          	sb	a4,0(a5)
      --max;
    80001800:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001804:	0785                	addi	a5,a5,1
    while(n > 0){
    80001806:	ff0796e3          	bne	a5,a6,800017f2 <copyinstr+0x84>
      dst++;
    8000180a:	8b42                	mv	s6,a6
    8000180c:	b775                	j	800017b8 <copyinstr+0x4a>
    8000180e:	4781                	li	a5,0
    80001810:	b769                	j	8000179a <copyinstr+0x2c>
      return -1;
    80001812:	557d                	li	a0,-1
    80001814:	b779                	j	800017a2 <copyinstr+0x34>
  int got_null = 0;
    80001816:	4781                	li	a5,0
  if(got_null){
    80001818:	0017b793          	seqz	a5,a5
    8000181c:	40f00533          	neg	a0,a5
}
    80001820:	8082                	ret

0000000080001822 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001822:	7139                	addi	sp,sp,-64
    80001824:	fc06                	sd	ra,56(sp)
    80001826:	f822                	sd	s0,48(sp)
    80001828:	f426                	sd	s1,40(sp)
    8000182a:	f04a                	sd	s2,32(sp)
    8000182c:	ec4e                	sd	s3,24(sp)
    8000182e:	e852                	sd	s4,16(sp)
    80001830:	e456                	sd	s5,8(sp)
    80001832:	e05a                	sd	s6,0(sp)
    80001834:	0080                	addi	s0,sp,64
    80001836:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001838:	00010497          	auipc	s1,0x10
    8000183c:	e9848493          	addi	s1,s1,-360 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001840:	8b26                	mv	s6,s1
    80001842:	00006a97          	auipc	s5,0x6
    80001846:	7bea8a93          	addi	s5,s5,1982 # 80008000 <etext>
    8000184a:	04000937          	lui	s2,0x4000
    8000184e:	197d                	addi	s2,s2,-1
    80001850:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001852:	00016a17          	auipc	s4,0x16
    80001856:	87ea0a13          	addi	s4,s4,-1922 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000185a:	fffff097          	auipc	ra,0xfffff
    8000185e:	28c080e7          	jalr	652(ra) # 80000ae6 <kalloc>
    80001862:	862a                	mv	a2,a0
    if(pa == 0)
    80001864:	c131                	beqz	a0,800018a8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001866:	416485b3          	sub	a1,s1,s6
    8000186a:	858d                	srai	a1,a1,0x3
    8000186c:	000ab783          	ld	a5,0(s5)
    80001870:	02f585b3          	mul	a1,a1,a5
    80001874:	2585                	addiw	a1,a1,1
    80001876:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000187a:	4719                	li	a4,6
    8000187c:	6685                	lui	a3,0x1
    8000187e:	40b905b3          	sub	a1,s2,a1
    80001882:	854e                	mv	a0,s3
    80001884:	00000097          	auipc	ra,0x0
    80001888:	8b0080e7          	jalr	-1872(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188c:	16848493          	addi	s1,s1,360
    80001890:	fd4495e3          	bne	s1,s4,8000185a <proc_mapstacks+0x38>
  }
}
    80001894:	70e2                	ld	ra,56(sp)
    80001896:	7442                	ld	s0,48(sp)
    80001898:	74a2                	ld	s1,40(sp)
    8000189a:	7902                	ld	s2,32(sp)
    8000189c:	69e2                	ld	s3,24(sp)
    8000189e:	6a42                	ld	s4,16(sp)
    800018a0:	6aa2                	ld	s5,8(sp)
    800018a2:	6b02                	ld	s6,0(sp)
    800018a4:	6121                	addi	sp,sp,64
    800018a6:	8082                	ret
      panic("kalloc");
    800018a8:	00007517          	auipc	a0,0x7
    800018ac:	91850513          	addi	a0,a0,-1768 # 800081c0 <digits+0x180>
    800018b0:	fffff097          	auipc	ra,0xfffff
    800018b4:	c80080e7          	jalr	-896(ra) # 80000530 <panic>

00000000800018b8 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018b8:	7139                	addi	sp,sp,-64
    800018ba:	fc06                	sd	ra,56(sp)
    800018bc:	f822                	sd	s0,48(sp)
    800018be:	f426                	sd	s1,40(sp)
    800018c0:	f04a                	sd	s2,32(sp)
    800018c2:	ec4e                	sd	s3,24(sp)
    800018c4:	e852                	sd	s4,16(sp)
    800018c6:	e456                	sd	s5,8(sp)
    800018c8:	e05a                	sd	s6,0(sp)
    800018ca:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018cc:	00007597          	auipc	a1,0x7
    800018d0:	8fc58593          	addi	a1,a1,-1796 # 800081c8 <digits+0x188>
    800018d4:	00010517          	auipc	a0,0x10
    800018d8:	9cc50513          	addi	a0,a0,-1588 # 800112a0 <pid_lock>
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	26a080e7          	jalr	618(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018e4:	00007597          	auipc	a1,0x7
    800018e8:	8ec58593          	addi	a1,a1,-1812 # 800081d0 <digits+0x190>
    800018ec:	00010517          	auipc	a0,0x10
    800018f0:	9cc50513          	addi	a0,a0,-1588 # 800112b8 <wait_lock>
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	252080e7          	jalr	594(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fc:	00010497          	auipc	s1,0x10
    80001900:	dd448493          	addi	s1,s1,-556 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001904:	00007b17          	auipc	s6,0x7
    80001908:	8dcb0b13          	addi	s6,s6,-1828 # 800081e0 <digits+0x1a0>
      p->kstack = KSTACK((int) (p - proc));
    8000190c:	8aa6                	mv	s5,s1
    8000190e:	00006a17          	auipc	s4,0x6
    80001912:	6f2a0a13          	addi	s4,s4,1778 # 80008000 <etext>
    80001916:	04000937          	lui	s2,0x4000
    8000191a:	197d                	addi	s2,s2,-1
    8000191c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000191e:	00015997          	auipc	s3,0x15
    80001922:	7b298993          	addi	s3,s3,1970 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001926:	85da                	mv	a1,s6
    80001928:	8526                	mv	a0,s1
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	21c080e7          	jalr	540(ra) # 80000b46 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001932:	415487b3          	sub	a5,s1,s5
    80001936:	878d                	srai	a5,a5,0x3
    80001938:	000a3703          	ld	a4,0(s4)
    8000193c:	02e787b3          	mul	a5,a5,a4
    80001940:	2785                	addiw	a5,a5,1
    80001942:	00d7979b          	slliw	a5,a5,0xd
    80001946:	40f907b3          	sub	a5,s2,a5
    8000194a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	16848493          	addi	s1,s1,360
    80001950:	fd349be3          	bne	s1,s3,80001926 <procinit+0x6e>
  }
}
    80001954:	70e2                	ld	ra,56(sp)
    80001956:	7442                	ld	s0,48(sp)
    80001958:	74a2                	ld	s1,40(sp)
    8000195a:	7902                	ld	s2,32(sp)
    8000195c:	69e2                	ld	s3,24(sp)
    8000195e:	6a42                	ld	s4,16(sp)
    80001960:	6aa2                	ld	s5,8(sp)
    80001962:	6b02                	ld	s6,0(sp)
    80001964:	6121                	addi	sp,sp,64
    80001966:	8082                	ret

0000000080001968 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001968:	1141                	addi	sp,sp,-16
    8000196a:	e422                	sd	s0,8(sp)
    8000196c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000196e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001970:	2501                	sext.w	a0,a0
    80001972:	6422                	ld	s0,8(sp)
    80001974:	0141                	addi	sp,sp,16
    80001976:	8082                	ret

0000000080001978 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001978:	1141                	addi	sp,sp,-16
    8000197a:	e422                	sd	s0,8(sp)
    8000197c:	0800                	addi	s0,sp,16
    8000197e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001980:	2781                	sext.w	a5,a5
    80001982:	079e                	slli	a5,a5,0x7
  return c;
}
    80001984:	00010517          	auipc	a0,0x10
    80001988:	94c50513          	addi	a0,a0,-1716 # 800112d0 <cpus>
    8000198c:	953e                	add	a0,a0,a5
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001994:	1101                	addi	sp,sp,-32
    80001996:	ec06                	sd	ra,24(sp)
    80001998:	e822                	sd	s0,16(sp)
    8000199a:	e426                	sd	s1,8(sp)
    8000199c:	1000                	addi	s0,sp,32
  push_off();
    8000199e:	fffff097          	auipc	ra,0xfffff
    800019a2:	1ec080e7          	jalr	492(ra) # 80000b8a <push_off>
    800019a6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019a8:	2781                	sext.w	a5,a5
    800019aa:	079e                	slli	a5,a5,0x7
    800019ac:	00010717          	auipc	a4,0x10
    800019b0:	8f470713          	addi	a4,a4,-1804 # 800112a0 <pid_lock>
    800019b4:	97ba                	add	a5,a5,a4
    800019b6:	7b84                	ld	s1,48(a5)
  pop_off();
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	272080e7          	jalr	626(ra) # 80000c2a <pop_off>
  return p;
}
    800019c0:	8526                	mv	a0,s1
    800019c2:	60e2                	ld	ra,24(sp)
    800019c4:	6442                	ld	s0,16(sp)
    800019c6:	64a2                	ld	s1,8(sp)
    800019c8:	6105                	addi	sp,sp,32
    800019ca:	8082                	ret

00000000800019cc <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019cc:	1141                	addi	sp,sp,-16
    800019ce:	e406                	sd	ra,8(sp)
    800019d0:	e022                	sd	s0,0(sp)
    800019d2:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019d4:	00000097          	auipc	ra,0x0
    800019d8:	fc0080e7          	jalr	-64(ra) # 80001994 <myproc>
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	2ae080e7          	jalr	686(ra) # 80000c8a <release>

  if (first) {
    800019e4:	00007797          	auipc	a5,0x7
    800019e8:	e1c7a783          	lw	a5,-484(a5) # 80008800 <first.1668>
    800019ec:	eb89                	bnez	a5,800019fe <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019ee:	00001097          	auipc	ra,0x1
    800019f2:	c0a080e7          	jalr	-1014(ra) # 800025f8 <usertrapret>
}
    800019f6:	60a2                	ld	ra,8(sp)
    800019f8:	6402                	ld	s0,0(sp)
    800019fa:	0141                	addi	sp,sp,16
    800019fc:	8082                	ret
    first = 0;
    800019fe:	00007797          	auipc	a5,0x7
    80001a02:	e007a123          	sw	zero,-510(a5) # 80008800 <first.1668>
    fsinit(ROOTDEV);
    80001a06:	4505                	li	a0,1
    80001a08:	00002097          	auipc	ra,0x2
    80001a0c:	974080e7          	jalr	-1676(ra) # 8000337c <fsinit>
    80001a10:	bff9                	j	800019ee <forkret+0x22>

0000000080001a12 <allocpid>:
allocpid() {
    80001a12:	1101                	addi	sp,sp,-32
    80001a14:	ec06                	sd	ra,24(sp)
    80001a16:	e822                	sd	s0,16(sp)
    80001a18:	e426                	sd	s1,8(sp)
    80001a1a:	e04a                	sd	s2,0(sp)
    80001a1c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a1e:	00010917          	auipc	s2,0x10
    80001a22:	88290913          	addi	s2,s2,-1918 # 800112a0 <pid_lock>
    80001a26:	854a                	mv	a0,s2
    80001a28:	fffff097          	auipc	ra,0xfffff
    80001a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	dd478793          	addi	a5,a5,-556 # 80008804 <nextpid>
    80001a38:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a3a:	0014871b          	addiw	a4,s1,1
    80001a3e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a40:	854a                	mv	a0,s2
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	248080e7          	jalr	584(ra) # 80000c8a <release>
}
    80001a4a:	8526                	mv	a0,s1
    80001a4c:	60e2                	ld	ra,24(sp)
    80001a4e:	6442                	ld	s0,16(sp)
    80001a50:	64a2                	ld	s1,8(sp)
    80001a52:	6902                	ld	s2,0(sp)
    80001a54:	6105                	addi	sp,sp,32
    80001a56:	8082                	ret

0000000080001a58 <proc_pagetable>:
{
    80001a58:	1101                	addi	sp,sp,-32
    80001a5a:	ec06                	sd	ra,24(sp)
    80001a5c:	e822                	sd	s0,16(sp)
    80001a5e:	e426                	sd	s1,8(sp)
    80001a60:	e04a                	sd	s2,0(sp)
    80001a62:	1000                	addi	s0,sp,32
    80001a64:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a66:	00000097          	auipc	ra,0x0
    80001a6a:	8b8080e7          	jalr	-1864(ra) # 8000131e <uvmcreate>
    80001a6e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a70:	c121                	beqz	a0,80001ab0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a72:	4729                	li	a4,10
    80001a74:	00005697          	auipc	a3,0x5
    80001a78:	58c68693          	addi	a3,a3,1420 # 80007000 <_trampoline>
    80001a7c:	6605                	lui	a2,0x1
    80001a7e:	040005b7          	lui	a1,0x4000
    80001a82:	15fd                	addi	a1,a1,-1
    80001a84:	05b2                	slli	a1,a1,0xc
    80001a86:	fffff097          	auipc	ra,0xfffff
    80001a8a:	620080e7          	jalr	1568(ra) # 800010a6 <mappages>
    80001a8e:	02054863          	bltz	a0,80001abe <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a92:	4719                	li	a4,6
    80001a94:	05893683          	ld	a3,88(s2)
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	020005b7          	lui	a1,0x2000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b6                	slli	a1,a1,0xd
    80001aa2:	8526                	mv	a0,s1
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	602080e7          	jalr	1538(ra) # 800010a6 <mappages>
    80001aac:	02054163          	bltz	a0,80001ace <proc_pagetable+0x76>
}
    80001ab0:	8526                	mv	a0,s1
    80001ab2:	60e2                	ld	ra,24(sp)
    80001ab4:	6442                	ld	s0,16(sp)
    80001ab6:	64a2                	ld	s1,8(sp)
    80001ab8:	6902                	ld	s2,0(sp)
    80001aba:	6105                	addi	sp,sp,32
    80001abc:	8082                	ret
    uvmfree(pagetable, 0);
    80001abe:	4581                	li	a1,0
    80001ac0:	8526                	mv	a0,s1
    80001ac2:	00000097          	auipc	ra,0x0
    80001ac6:	a58080e7          	jalr	-1448(ra) # 8000151a <uvmfree>
    return 0;
    80001aca:	4481                	li	s1,0
    80001acc:	b7d5                	j	80001ab0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ace:	4681                	li	a3,0
    80001ad0:	4605                	li	a2,1
    80001ad2:	040005b7          	lui	a1,0x4000
    80001ad6:	15fd                	addi	a1,a1,-1
    80001ad8:	05b2                	slli	a1,a1,0xc
    80001ada:	8526                	mv	a0,s1
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	77e080e7          	jalr	1918(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ae4:	4581                	li	a1,0
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	00000097          	auipc	ra,0x0
    80001aec:	a32080e7          	jalr	-1486(ra) # 8000151a <uvmfree>
    return 0;
    80001af0:	4481                	li	s1,0
    80001af2:	bf7d                	j	80001ab0 <proc_pagetable+0x58>

0000000080001af4 <proc_freepagetable>:
{
    80001af4:	1101                	addi	sp,sp,-32
    80001af6:	ec06                	sd	ra,24(sp)
    80001af8:	e822                	sd	s0,16(sp)
    80001afa:	e426                	sd	s1,8(sp)
    80001afc:	e04a                	sd	s2,0(sp)
    80001afe:	1000                	addi	s0,sp,32
    80001b00:	84aa                	mv	s1,a0
    80001b02:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b04:	4681                	li	a3,0
    80001b06:	4605                	li	a2,1
    80001b08:	040005b7          	lui	a1,0x4000
    80001b0c:	15fd                	addi	a1,a1,-1
    80001b0e:	05b2                	slli	a1,a1,0xc
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	74a080e7          	jalr	1866(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b18:	4681                	li	a3,0
    80001b1a:	4605                	li	a2,1
    80001b1c:	020005b7          	lui	a1,0x2000
    80001b20:	15fd                	addi	a1,a1,-1
    80001b22:	05b6                	slli	a1,a1,0xd
    80001b24:	8526                	mv	a0,s1
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	734080e7          	jalr	1844(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b2e:	85ca                	mv	a1,s2
    80001b30:	8526                	mv	a0,s1
    80001b32:	00000097          	auipc	ra,0x0
    80001b36:	9e8080e7          	jalr	-1560(ra) # 8000151a <uvmfree>
}
    80001b3a:	60e2                	ld	ra,24(sp)
    80001b3c:	6442                	ld	s0,16(sp)
    80001b3e:	64a2                	ld	s1,8(sp)
    80001b40:	6902                	ld	s2,0(sp)
    80001b42:	6105                	addi	sp,sp,32
    80001b44:	8082                	ret

0000000080001b46 <freeproc>:
{
    80001b46:	1101                	addi	sp,sp,-32
    80001b48:	ec06                	sd	ra,24(sp)
    80001b4a:	e822                	sd	s0,16(sp)
    80001b4c:	e426                	sd	s1,8(sp)
    80001b4e:	1000                	addi	s0,sp,32
    80001b50:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b52:	6d28                	ld	a0,88(a0)
    80001b54:	c509                	beqz	a0,80001b5e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b56:	fffff097          	auipc	ra,0xfffff
    80001b5a:	e94080e7          	jalr	-364(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b5e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b62:	68a8                	ld	a0,80(s1)
    80001b64:	c511                	beqz	a0,80001b70 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b66:	64ac                	ld	a1,72(s1)
    80001b68:	00000097          	auipc	ra,0x0
    80001b6c:	f8c080e7          	jalr	-116(ra) # 80001af4 <proc_freepagetable>
  p->pagetable = 0;
    80001b70:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b74:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b78:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b80:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b84:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b88:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b8c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b90:	0004ac23          	sw	zero,24(s1)
}
    80001b94:	60e2                	ld	ra,24(sp)
    80001b96:	6442                	ld	s0,16(sp)
    80001b98:	64a2                	ld	s1,8(sp)
    80001b9a:	6105                	addi	sp,sp,32
    80001b9c:	8082                	ret

0000000080001b9e <allocproc>:
{
    80001b9e:	1101                	addi	sp,sp,-32
    80001ba0:	ec06                	sd	ra,24(sp)
    80001ba2:	e822                	sd	s0,16(sp)
    80001ba4:	e426                	sd	s1,8(sp)
    80001ba6:	e04a                	sd	s2,0(sp)
    80001ba8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001baa:	00010497          	auipc	s1,0x10
    80001bae:	b2648493          	addi	s1,s1,-1242 # 800116d0 <proc>
    80001bb2:	00015917          	auipc	s2,0x15
    80001bb6:	51e90913          	addi	s2,s2,1310 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001bba:	8526                	mv	a0,s1
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	01a080e7          	jalr	26(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bc4:	4c9c                	lw	a5,24(s1)
    80001bc6:	cf81                	beqz	a5,80001bde <allocproc+0x40>
      release(&p->lock);
    80001bc8:	8526                	mv	a0,s1
    80001bca:	fffff097          	auipc	ra,0xfffff
    80001bce:	0c0080e7          	jalr	192(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd2:	16848493          	addi	s1,s1,360
    80001bd6:	ff2492e3          	bne	s1,s2,80001bba <allocproc+0x1c>
  return 0;
    80001bda:	4481                	li	s1,0
    80001bdc:	a889                	j	80001c2e <allocproc+0x90>
  p->pid = allocpid();
    80001bde:	00000097          	auipc	ra,0x0
    80001be2:	e34080e7          	jalr	-460(ra) # 80001a12 <allocpid>
    80001be6:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001be8:	4785                	li	a5,1
    80001bea:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	efa080e7          	jalr	-262(ra) # 80000ae6 <kalloc>
    80001bf4:	892a                	mv	s2,a0
    80001bf6:	eca8                	sd	a0,88(s1)
    80001bf8:	c131                	beqz	a0,80001c3c <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	00000097          	auipc	ra,0x0
    80001c00:	e5c080e7          	jalr	-420(ra) # 80001a58 <proc_pagetable>
    80001c04:	892a                	mv	s2,a0
    80001c06:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c08:	c531                	beqz	a0,80001c54 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c0a:	07000613          	li	a2,112
    80001c0e:	4581                	li	a1,0
    80001c10:	06048513          	addi	a0,s1,96
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	0be080e7          	jalr	190(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c1c:	00000797          	auipc	a5,0x0
    80001c20:	db078793          	addi	a5,a5,-592 # 800019cc <forkret>
    80001c24:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c26:	60bc                	ld	a5,64(s1)
    80001c28:	6705                	lui	a4,0x1
    80001c2a:	97ba                	add	a5,a5,a4
    80001c2c:	f4bc                	sd	a5,104(s1)
}
    80001c2e:	8526                	mv	a0,s1
    80001c30:	60e2                	ld	ra,24(sp)
    80001c32:	6442                	ld	s0,16(sp)
    80001c34:	64a2                	ld	s1,8(sp)
    80001c36:	6902                	ld	s2,0(sp)
    80001c38:	6105                	addi	sp,sp,32
    80001c3a:	8082                	ret
    freeproc(p);
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	f08080e7          	jalr	-248(ra) # 80001b46 <freeproc>
    release(&p->lock);
    80001c46:	8526                	mv	a0,s1
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	042080e7          	jalr	66(ra) # 80000c8a <release>
    return 0;
    80001c50:	84ca                	mv	s1,s2
    80001c52:	bff1                	j	80001c2e <allocproc+0x90>
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	ef0080e7          	jalr	-272(ra) # 80001b46 <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	b7d1                	j	80001c2e <allocproc+0x90>

0000000080001c6c <userinit>:
{
    80001c6c:	1101                	addi	sp,sp,-32
    80001c6e:	ec06                	sd	ra,24(sp)
    80001c70:	e822                	sd	s0,16(sp)
    80001c72:	e426                	sd	s1,8(sp)
    80001c74:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	f28080e7          	jalr	-216(ra) # 80001b9e <allocproc>
    80001c7e:	84aa                	mv	s1,a0
  initproc = p;
    80001c80:	00007797          	auipc	a5,0x7
    80001c84:	3aa7b423          	sd	a0,936(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c88:	03400613          	li	a2,52
    80001c8c:	00007597          	auipc	a1,0x7
    80001c90:	b8458593          	addi	a1,a1,-1148 # 80008810 <initcode>
    80001c94:	6928                	ld	a0,80(a0)
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	6b6080e7          	jalr	1718(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001c9e:	6785                	lui	a5,0x1
    80001ca0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ca2:	6cb8                	ld	a4,88(s1)
    80001ca4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ca8:	6cb8                	ld	a4,88(s1)
    80001caa:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cac:	4641                	li	a2,16
    80001cae:	00006597          	auipc	a1,0x6
    80001cb2:	53a58593          	addi	a1,a1,1338 # 800081e8 <digits+0x1a8>
    80001cb6:	15848513          	addi	a0,s1,344
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	16e080e7          	jalr	366(ra) # 80000e28 <safestrcpy>
  p->cwd = namei("/");
    80001cc2:	00006517          	auipc	a0,0x6
    80001cc6:	53650513          	addi	a0,a0,1334 # 800081f8 <digits+0x1b8>
    80001cca:	00002097          	auipc	ra,0x2
    80001cce:	0e0080e7          	jalr	224(ra) # 80003daa <namei>
    80001cd2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cd6:	478d                	li	a5,3
    80001cd8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cda:	8526                	mv	a0,s1
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	fae080e7          	jalr	-82(ra) # 80000c8a <release>
}
    80001ce4:	60e2                	ld	ra,24(sp)
    80001ce6:	6442                	ld	s0,16(sp)
    80001ce8:	64a2                	ld	s1,8(sp)
    80001cea:	6105                	addi	sp,sp,32
    80001cec:	8082                	ret

0000000080001cee <growproc>:
{
    80001cee:	1101                	addi	sp,sp,-32
    80001cf0:	ec06                	sd	ra,24(sp)
    80001cf2:	e822                	sd	s0,16(sp)
    80001cf4:	e426                	sd	s1,8(sp)
    80001cf6:	e04a                	sd	s2,0(sp)
    80001cf8:	1000                	addi	s0,sp,32
    80001cfa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	c98080e7          	jalr	-872(ra) # 80001994 <myproc>
    80001d04:	892a                	mv	s2,a0
  sz = p->sz;
    80001d06:	652c                	ld	a1,72(a0)
    80001d08:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d0c:	00904f63          	bgtz	s1,80001d2a <growproc+0x3c>
  } else if(n < 0){
    80001d10:	0204cc63          	bltz	s1,80001d48 <growproc+0x5a>
  p->sz = sz;
    80001d14:	1602                	slli	a2,a2,0x20
    80001d16:	9201                	srli	a2,a2,0x20
    80001d18:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d1c:	4501                	li	a0,0
}
    80001d1e:	60e2                	ld	ra,24(sp)
    80001d20:	6442                	ld	s0,16(sp)
    80001d22:	64a2                	ld	s1,8(sp)
    80001d24:	6902                	ld	s2,0(sp)
    80001d26:	6105                	addi	sp,sp,32
    80001d28:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d2a:	9e25                	addw	a2,a2,s1
    80001d2c:	1602                	slli	a2,a2,0x20
    80001d2e:	9201                	srli	a2,a2,0x20
    80001d30:	1582                	slli	a1,a1,0x20
    80001d32:	9181                	srli	a1,a1,0x20
    80001d34:	6928                	ld	a0,80(a0)
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	6d0080e7          	jalr	1744(ra) # 80001406 <uvmalloc>
    80001d3e:	0005061b          	sext.w	a2,a0
    80001d42:	fa69                	bnez	a2,80001d14 <growproc+0x26>
      return -1;
    80001d44:	557d                	li	a0,-1
    80001d46:	bfe1                	j	80001d1e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d48:	9e25                	addw	a2,a2,s1
    80001d4a:	1602                	slli	a2,a2,0x20
    80001d4c:	9201                	srli	a2,a2,0x20
    80001d4e:	1582                	slli	a1,a1,0x20
    80001d50:	9181                	srli	a1,a1,0x20
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	66a080e7          	jalr	1642(ra) # 800013be <uvmdealloc>
    80001d5c:	0005061b          	sext.w	a2,a0
    80001d60:	bf55                	j	80001d14 <growproc+0x26>

0000000080001d62 <fork>:
{
    80001d62:	7179                	addi	sp,sp,-48
    80001d64:	f406                	sd	ra,40(sp)
    80001d66:	f022                	sd	s0,32(sp)
    80001d68:	ec26                	sd	s1,24(sp)
    80001d6a:	e84a                	sd	s2,16(sp)
    80001d6c:	e44e                	sd	s3,8(sp)
    80001d6e:	e052                	sd	s4,0(sp)
    80001d70:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d72:	00000097          	auipc	ra,0x0
    80001d76:	c22080e7          	jalr	-990(ra) # 80001994 <myproc>
    80001d7a:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	e22080e7          	jalr	-478(ra) # 80001b9e <allocproc>
    80001d84:	10050b63          	beqz	a0,80001e9a <fork+0x138>
    80001d88:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8a:	04893603          	ld	a2,72(s2)
    80001d8e:	692c                	ld	a1,80(a0)
    80001d90:	05093503          	ld	a0,80(s2)
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	7be080e7          	jalr	1982(ra) # 80001552 <uvmcopy>
    80001d9c:	04054663          	bltz	a0,80001de8 <fork+0x86>
  np->sz = p->sz;
    80001da0:	04893783          	ld	a5,72(s2)
    80001da4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001da8:	05893683          	ld	a3,88(s2)
    80001dac:	87b6                	mv	a5,a3
    80001dae:	0589b703          	ld	a4,88(s3)
    80001db2:	12068693          	addi	a3,a3,288
    80001db6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dba:	6788                	ld	a0,8(a5)
    80001dbc:	6b8c                	ld	a1,16(a5)
    80001dbe:	6f90                	ld	a2,24(a5)
    80001dc0:	01073023          	sd	a6,0(a4)
    80001dc4:	e708                	sd	a0,8(a4)
    80001dc6:	eb0c                	sd	a1,16(a4)
    80001dc8:	ef10                	sd	a2,24(a4)
    80001dca:	02078793          	addi	a5,a5,32
    80001dce:	02070713          	addi	a4,a4,32
    80001dd2:	fed792e3          	bne	a5,a3,80001db6 <fork+0x54>
  np->trapframe->a0 = 0;
    80001dd6:	0589b783          	ld	a5,88(s3)
    80001dda:	0607b823          	sd	zero,112(a5)
    80001dde:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001de2:	15000a13          	li	s4,336
    80001de6:	a03d                	j	80001e14 <fork+0xb2>
    freeproc(np);
    80001de8:	854e                	mv	a0,s3
    80001dea:	00000097          	auipc	ra,0x0
    80001dee:	d5c080e7          	jalr	-676(ra) # 80001b46 <freeproc>
    release(&np->lock);
    80001df2:	854e                	mv	a0,s3
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	e96080e7          	jalr	-362(ra) # 80000c8a <release>
    return -1;
    80001dfc:	5a7d                	li	s4,-1
    80001dfe:	a069                	j	80001e88 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e00:	00002097          	auipc	ra,0x2
    80001e04:	640080e7          	jalr	1600(ra) # 80004440 <filedup>
    80001e08:	009987b3          	add	a5,s3,s1
    80001e0c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e0e:	04a1                	addi	s1,s1,8
    80001e10:	01448763          	beq	s1,s4,80001e1e <fork+0xbc>
    if(p->ofile[i])
    80001e14:	009907b3          	add	a5,s2,s1
    80001e18:	6388                	ld	a0,0(a5)
    80001e1a:	f17d                	bnez	a0,80001e00 <fork+0x9e>
    80001e1c:	bfcd                	j	80001e0e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e1e:	15093503          	ld	a0,336(s2)
    80001e22:	00001097          	auipc	ra,0x1
    80001e26:	794080e7          	jalr	1940(ra) # 800035b6 <idup>
    80001e2a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e2e:	4641                	li	a2,16
    80001e30:	15890593          	addi	a1,s2,344
    80001e34:	15898513          	addi	a0,s3,344
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	ff0080e7          	jalr	-16(ra) # 80000e28 <safestrcpy>
  pid = np->pid;
    80001e40:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e44:	854e                	mv	a0,s3
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	e44080e7          	jalr	-444(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e4e:	0000f497          	auipc	s1,0xf
    80001e52:	46a48493          	addi	s1,s1,1130 # 800112b8 <wait_lock>
    80001e56:	8526                	mv	a0,s1
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	d7e080e7          	jalr	-642(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e60:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e64:	8526                	mv	a0,s1
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	e24080e7          	jalr	-476(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e6e:	854e                	mv	a0,s3
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	d66080e7          	jalr	-666(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e78:	478d                	li	a5,3
    80001e7a:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e7e:	854e                	mv	a0,s3
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	e0a080e7          	jalr	-502(ra) # 80000c8a <release>
}
    80001e88:	8552                	mv	a0,s4
    80001e8a:	70a2                	ld	ra,40(sp)
    80001e8c:	7402                	ld	s0,32(sp)
    80001e8e:	64e2                	ld	s1,24(sp)
    80001e90:	6942                	ld	s2,16(sp)
    80001e92:	69a2                	ld	s3,8(sp)
    80001e94:	6a02                	ld	s4,0(sp)
    80001e96:	6145                	addi	sp,sp,48
    80001e98:	8082                	ret
    return -1;
    80001e9a:	5a7d                	li	s4,-1
    80001e9c:	b7f5                	j	80001e88 <fork+0x126>

0000000080001e9e <scheduler>:
{
    80001e9e:	7139                	addi	sp,sp,-64
    80001ea0:	fc06                	sd	ra,56(sp)
    80001ea2:	f822                	sd	s0,48(sp)
    80001ea4:	f426                	sd	s1,40(sp)
    80001ea6:	f04a                	sd	s2,32(sp)
    80001ea8:	ec4e                	sd	s3,24(sp)
    80001eaa:	e852                	sd	s4,16(sp)
    80001eac:	e456                	sd	s5,8(sp)
    80001eae:	e05a                	sd	s6,0(sp)
    80001eb0:	0080                	addi	s0,sp,64
    80001eb2:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eb6:	00779a93          	slli	s5,a5,0x7
    80001eba:	0000f717          	auipc	a4,0xf
    80001ebe:	3e670713          	addi	a4,a4,998 # 800112a0 <pid_lock>
    80001ec2:	9756                	add	a4,a4,s5
    80001ec4:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ec8:	0000f717          	auipc	a4,0xf
    80001ecc:	41070713          	addi	a4,a4,1040 # 800112d8 <cpus+0x8>
    80001ed0:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed2:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed4:	4b11                	li	s6,4
        c->proc = p;
    80001ed6:	079e                	slli	a5,a5,0x7
    80001ed8:	0000fa17          	auipc	s4,0xf
    80001edc:	3c8a0a13          	addi	s4,s4,968 # 800112a0 <pid_lock>
    80001ee0:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee2:	00015917          	auipc	s2,0x15
    80001ee6:	1ee90913          	addi	s2,s2,494 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001eee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef2:	10079073          	csrw	sstatus,a5
    80001ef6:	0000f497          	auipc	s1,0xf
    80001efa:	7da48493          	addi	s1,s1,2010 # 800116d0 <proc>
    80001efe:	a03d                	j	80001f2c <scheduler+0x8e>
        p->state = RUNNING;
    80001f00:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f04:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f08:	06048593          	addi	a1,s1,96
    80001f0c:	8556                	mv	a0,s5
    80001f0e:	00000097          	auipc	ra,0x0
    80001f12:	640080e7          	jalr	1600(ra) # 8000254e <swtch>
        c->proc = 0;
    80001f16:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f1a:	8526                	mv	a0,s1
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	d6e080e7          	jalr	-658(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f24:	16848493          	addi	s1,s1,360
    80001f28:	fd2481e3          	beq	s1,s2,80001eea <scheduler+0x4c>
      acquire(&p->lock);
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	ca8080e7          	jalr	-856(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f36:	4c9c                	lw	a5,24(s1)
    80001f38:	ff3791e3          	bne	a5,s3,80001f1a <scheduler+0x7c>
    80001f3c:	b7d1                	j	80001f00 <scheduler+0x62>

0000000080001f3e <sched>:
{
    80001f3e:	7179                	addi	sp,sp,-48
    80001f40:	f406                	sd	ra,40(sp)
    80001f42:	f022                	sd	s0,32(sp)
    80001f44:	ec26                	sd	s1,24(sp)
    80001f46:	e84a                	sd	s2,16(sp)
    80001f48:	e44e                	sd	s3,8(sp)
    80001f4a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f4c:	00000097          	auipc	ra,0x0
    80001f50:	a48080e7          	jalr	-1464(ra) # 80001994 <myproc>
    80001f54:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	c06080e7          	jalr	-1018(ra) # 80000b5c <holding>
    80001f5e:	c93d                	beqz	a0,80001fd4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f60:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f62:	2781                	sext.w	a5,a5
    80001f64:	079e                	slli	a5,a5,0x7
    80001f66:	0000f717          	auipc	a4,0xf
    80001f6a:	33a70713          	addi	a4,a4,826 # 800112a0 <pid_lock>
    80001f6e:	97ba                	add	a5,a5,a4
    80001f70:	0a87a703          	lw	a4,168(a5)
    80001f74:	4785                	li	a5,1
    80001f76:	06f71763          	bne	a4,a5,80001fe4 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7a:	4c98                	lw	a4,24(s1)
    80001f7c:	4791                	li	a5,4
    80001f7e:	06f70b63          	beq	a4,a5,80001ff4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f82:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f86:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f88:	efb5                	bnez	a5,80002004 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f8c:	0000f917          	auipc	s2,0xf
    80001f90:	31490913          	addi	s2,s2,788 # 800112a0 <pid_lock>
    80001f94:	2781                	sext.w	a5,a5
    80001f96:	079e                	slli	a5,a5,0x7
    80001f98:	97ca                	add	a5,a5,s2
    80001f9a:	0ac7a983          	lw	s3,172(a5)
    80001f9e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa0:	2781                	sext.w	a5,a5
    80001fa2:	079e                	slli	a5,a5,0x7
    80001fa4:	0000f597          	auipc	a1,0xf
    80001fa8:	33458593          	addi	a1,a1,820 # 800112d8 <cpus+0x8>
    80001fac:	95be                	add	a1,a1,a5
    80001fae:	06048513          	addi	a0,s1,96
    80001fb2:	00000097          	auipc	ra,0x0
    80001fb6:	59c080e7          	jalr	1436(ra) # 8000254e <swtch>
    80001fba:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fbc:	2781                	sext.w	a5,a5
    80001fbe:	079e                	slli	a5,a5,0x7
    80001fc0:	97ca                	add	a5,a5,s2
    80001fc2:	0b37a623          	sw	s3,172(a5)
}
    80001fc6:	70a2                	ld	ra,40(sp)
    80001fc8:	7402                	ld	s0,32(sp)
    80001fca:	64e2                	ld	s1,24(sp)
    80001fcc:	6942                	ld	s2,16(sp)
    80001fce:	69a2                	ld	s3,8(sp)
    80001fd0:	6145                	addi	sp,sp,48
    80001fd2:	8082                	ret
    panic("sched p->lock");
    80001fd4:	00006517          	auipc	a0,0x6
    80001fd8:	22c50513          	addi	a0,a0,556 # 80008200 <digits+0x1c0>
    80001fdc:	ffffe097          	auipc	ra,0xffffe
    80001fe0:	554080e7          	jalr	1364(ra) # 80000530 <panic>
    panic("sched locks");
    80001fe4:	00006517          	auipc	a0,0x6
    80001fe8:	22c50513          	addi	a0,a0,556 # 80008210 <digits+0x1d0>
    80001fec:	ffffe097          	auipc	ra,0xffffe
    80001ff0:	544080e7          	jalr	1348(ra) # 80000530 <panic>
    panic("sched running");
    80001ff4:	00006517          	auipc	a0,0x6
    80001ff8:	22c50513          	addi	a0,a0,556 # 80008220 <digits+0x1e0>
    80001ffc:	ffffe097          	auipc	ra,0xffffe
    80002000:	534080e7          	jalr	1332(ra) # 80000530 <panic>
    panic("sched interruptible");
    80002004:	00006517          	auipc	a0,0x6
    80002008:	22c50513          	addi	a0,a0,556 # 80008230 <digits+0x1f0>
    8000200c:	ffffe097          	auipc	ra,0xffffe
    80002010:	524080e7          	jalr	1316(ra) # 80000530 <panic>

0000000080002014 <yield>:
{
    80002014:	1101                	addi	sp,sp,-32
    80002016:	ec06                	sd	ra,24(sp)
    80002018:	e822                	sd	s0,16(sp)
    8000201a:	e426                	sd	s1,8(sp)
    8000201c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000201e:	00000097          	auipc	ra,0x0
    80002022:	976080e7          	jalr	-1674(ra) # 80001994 <myproc>
    80002026:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	bae080e7          	jalr	-1106(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002030:	478d                	li	a5,3
    80002032:	cc9c                	sw	a5,24(s1)
  sched();
    80002034:	00000097          	auipc	ra,0x0
    80002038:	f0a080e7          	jalr	-246(ra) # 80001f3e <sched>
  release(&p->lock);
    8000203c:	8526                	mv	a0,s1
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	c4c080e7          	jalr	-948(ra) # 80000c8a <release>
}
    80002046:	60e2                	ld	ra,24(sp)
    80002048:	6442                	ld	s0,16(sp)
    8000204a:	64a2                	ld	s1,8(sp)
    8000204c:	6105                	addi	sp,sp,32
    8000204e:	8082                	ret

0000000080002050 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002050:	7179                	addi	sp,sp,-48
    80002052:	f406                	sd	ra,40(sp)
    80002054:	f022                	sd	s0,32(sp)
    80002056:	ec26                	sd	s1,24(sp)
    80002058:	e84a                	sd	s2,16(sp)
    8000205a:	e44e                	sd	s3,8(sp)
    8000205c:	1800                	addi	s0,sp,48
    8000205e:	89aa                	mv	s3,a0
    80002060:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002062:	00000097          	auipc	ra,0x0
    80002066:	932080e7          	jalr	-1742(ra) # 80001994 <myproc>
    8000206a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	b6a080e7          	jalr	-1174(ra) # 80000bd6 <acquire>
  release(lk);
    80002074:	854a                	mv	a0,s2
    80002076:	fffff097          	auipc	ra,0xfffff
    8000207a:	c14080e7          	jalr	-1004(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    8000207e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002082:	4789                	li	a5,2
    80002084:	cc9c                	sw	a5,24(s1)

  sched();
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	eb8080e7          	jalr	-328(ra) # 80001f3e <sched>

  // Tidy up.
  p->chan = 0;
    8000208e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002092:	8526                	mv	a0,s1
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	bf6080e7          	jalr	-1034(ra) # 80000c8a <release>
  acquire(lk);
    8000209c:	854a                	mv	a0,s2
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	b38080e7          	jalr	-1224(ra) # 80000bd6 <acquire>
}
    800020a6:	70a2                	ld	ra,40(sp)
    800020a8:	7402                	ld	s0,32(sp)
    800020aa:	64e2                	ld	s1,24(sp)
    800020ac:	6942                	ld	s2,16(sp)
    800020ae:	69a2                	ld	s3,8(sp)
    800020b0:	6145                	addi	sp,sp,48
    800020b2:	8082                	ret

00000000800020b4 <wait>:
{
    800020b4:	715d                	addi	sp,sp,-80
    800020b6:	e486                	sd	ra,72(sp)
    800020b8:	e0a2                	sd	s0,64(sp)
    800020ba:	fc26                	sd	s1,56(sp)
    800020bc:	f84a                	sd	s2,48(sp)
    800020be:	f44e                	sd	s3,40(sp)
    800020c0:	f052                	sd	s4,32(sp)
    800020c2:	ec56                	sd	s5,24(sp)
    800020c4:	e85a                	sd	s6,16(sp)
    800020c6:	e45e                	sd	s7,8(sp)
    800020c8:	e062                	sd	s8,0(sp)
    800020ca:	0880                	addi	s0,sp,80
    800020cc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800020ce:	00000097          	auipc	ra,0x0
    800020d2:	8c6080e7          	jalr	-1850(ra) # 80001994 <myproc>
    800020d6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800020d8:	0000f517          	auipc	a0,0xf
    800020dc:	1e050513          	addi	a0,a0,480 # 800112b8 <wait_lock>
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	af6080e7          	jalr	-1290(ra) # 80000bd6 <acquire>
    havekids = 0;
    800020e8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020ea:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800020ec:	00015997          	auipc	s3,0x15
    800020f0:	fe498993          	addi	s3,s3,-28 # 800170d0 <tickslock>
        havekids = 1;
    800020f4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020f6:	0000fc17          	auipc	s8,0xf
    800020fa:	1c2c0c13          	addi	s8,s8,450 # 800112b8 <wait_lock>
    havekids = 0;
    800020fe:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002100:	0000f497          	auipc	s1,0xf
    80002104:	5d048493          	addi	s1,s1,1488 # 800116d0 <proc>
    80002108:	a0bd                	j	80002176 <wait+0xc2>
          pid = np->pid;
    8000210a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000210e:	000b0e63          	beqz	s6,8000212a <wait+0x76>
    80002112:	4691                	li	a3,4
    80002114:	02c48613          	addi	a2,s1,44
    80002118:	85da                	mv	a1,s6
    8000211a:	05093503          	ld	a0,80(s2)
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	538080e7          	jalr	1336(ra) # 80001656 <copyout>
    80002126:	02054563          	bltz	a0,80002150 <wait+0x9c>
          freeproc(np);
    8000212a:	8526                	mv	a0,s1
    8000212c:	00000097          	auipc	ra,0x0
    80002130:	a1a080e7          	jalr	-1510(ra) # 80001b46 <freeproc>
          release(&np->lock);
    80002134:	8526                	mv	a0,s1
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	b54080e7          	jalr	-1196(ra) # 80000c8a <release>
          release(&wait_lock);
    8000213e:	0000f517          	auipc	a0,0xf
    80002142:	17a50513          	addi	a0,a0,378 # 800112b8 <wait_lock>
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	b44080e7          	jalr	-1212(ra) # 80000c8a <release>
          return pid;
    8000214e:	a09d                	j	800021b4 <wait+0x100>
            release(&np->lock);
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	b38080e7          	jalr	-1224(ra) # 80000c8a <release>
            release(&wait_lock);
    8000215a:	0000f517          	auipc	a0,0xf
    8000215e:	15e50513          	addi	a0,a0,350 # 800112b8 <wait_lock>
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	b28080e7          	jalr	-1240(ra) # 80000c8a <release>
            return -1;
    8000216a:	59fd                	li	s3,-1
    8000216c:	a0a1                	j	800021b4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000216e:	16848493          	addi	s1,s1,360
    80002172:	03348463          	beq	s1,s3,8000219a <wait+0xe6>
      if(np->parent == p){
    80002176:	7c9c                	ld	a5,56(s1)
    80002178:	ff279be3          	bne	a5,s2,8000216e <wait+0xba>
        acquire(&np->lock);
    8000217c:	8526                	mv	a0,s1
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	a58080e7          	jalr	-1448(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    80002186:	4c9c                	lw	a5,24(s1)
    80002188:	f94781e3          	beq	a5,s4,8000210a <wait+0x56>
        release(&np->lock);
    8000218c:	8526                	mv	a0,s1
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	afc080e7          	jalr	-1284(ra) # 80000c8a <release>
        havekids = 1;
    80002196:	8756                	mv	a4,s5
    80002198:	bfd9                	j	8000216e <wait+0xba>
    if(!havekids || p->killed){
    8000219a:	c701                	beqz	a4,800021a2 <wait+0xee>
    8000219c:	02892783          	lw	a5,40(s2)
    800021a0:	c79d                	beqz	a5,800021ce <wait+0x11a>
      release(&wait_lock);
    800021a2:	0000f517          	auipc	a0,0xf
    800021a6:	11650513          	addi	a0,a0,278 # 800112b8 <wait_lock>
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	ae0080e7          	jalr	-1312(ra) # 80000c8a <release>
      return -1;
    800021b2:	59fd                	li	s3,-1
}
    800021b4:	854e                	mv	a0,s3
    800021b6:	60a6                	ld	ra,72(sp)
    800021b8:	6406                	ld	s0,64(sp)
    800021ba:	74e2                	ld	s1,56(sp)
    800021bc:	7942                	ld	s2,48(sp)
    800021be:	79a2                	ld	s3,40(sp)
    800021c0:	7a02                	ld	s4,32(sp)
    800021c2:	6ae2                	ld	s5,24(sp)
    800021c4:	6b42                	ld	s6,16(sp)
    800021c6:	6ba2                	ld	s7,8(sp)
    800021c8:	6c02                	ld	s8,0(sp)
    800021ca:	6161                	addi	sp,sp,80
    800021cc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021ce:	85e2                	mv	a1,s8
    800021d0:	854a                	mv	a0,s2
    800021d2:	00000097          	auipc	ra,0x0
    800021d6:	e7e080e7          	jalr	-386(ra) # 80002050 <sleep>
    havekids = 0;
    800021da:	b715                	j	800020fe <wait+0x4a>

00000000800021dc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021dc:	7139                	addi	sp,sp,-64
    800021de:	fc06                	sd	ra,56(sp)
    800021e0:	f822                	sd	s0,48(sp)
    800021e2:	f426                	sd	s1,40(sp)
    800021e4:	f04a                	sd	s2,32(sp)
    800021e6:	ec4e                	sd	s3,24(sp)
    800021e8:	e852                	sd	s4,16(sp)
    800021ea:	e456                	sd	s5,8(sp)
    800021ec:	0080                	addi	s0,sp,64
    800021ee:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021f0:	0000f497          	auipc	s1,0xf
    800021f4:	4e048493          	addi	s1,s1,1248 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021f8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021fa:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021fc:	00015917          	auipc	s2,0x15
    80002200:	ed490913          	addi	s2,s2,-300 # 800170d0 <tickslock>
    80002204:	a821                	j	8000221c <wakeup+0x40>
        p->state = RUNNABLE;
    80002206:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000220a:	8526                	mv	a0,s1
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	a7e080e7          	jalr	-1410(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002214:	16848493          	addi	s1,s1,360
    80002218:	03248463          	beq	s1,s2,80002240 <wakeup+0x64>
    if(p != myproc()){
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	778080e7          	jalr	1912(ra) # 80001994 <myproc>
    80002224:	fea488e3          	beq	s1,a0,80002214 <wakeup+0x38>
      acquire(&p->lock);
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002232:	4c9c                	lw	a5,24(s1)
    80002234:	fd379be3          	bne	a5,s3,8000220a <wakeup+0x2e>
    80002238:	709c                	ld	a5,32(s1)
    8000223a:	fd4798e3          	bne	a5,s4,8000220a <wakeup+0x2e>
    8000223e:	b7e1                	j	80002206 <wakeup+0x2a>
    }
  }
}
    80002240:	70e2                	ld	ra,56(sp)
    80002242:	7442                	ld	s0,48(sp)
    80002244:	74a2                	ld	s1,40(sp)
    80002246:	7902                	ld	s2,32(sp)
    80002248:	69e2                	ld	s3,24(sp)
    8000224a:	6a42                	ld	s4,16(sp)
    8000224c:	6aa2                	ld	s5,8(sp)
    8000224e:	6121                	addi	sp,sp,64
    80002250:	8082                	ret

0000000080002252 <reparent>:
{
    80002252:	7179                	addi	sp,sp,-48
    80002254:	f406                	sd	ra,40(sp)
    80002256:	f022                	sd	s0,32(sp)
    80002258:	ec26                	sd	s1,24(sp)
    8000225a:	e84a                	sd	s2,16(sp)
    8000225c:	e44e                	sd	s3,8(sp)
    8000225e:	e052                	sd	s4,0(sp)
    80002260:	1800                	addi	s0,sp,48
    80002262:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002264:	0000f497          	auipc	s1,0xf
    80002268:	46c48493          	addi	s1,s1,1132 # 800116d0 <proc>
      pp->parent = initproc;
    8000226c:	00007a17          	auipc	s4,0x7
    80002270:	dbca0a13          	addi	s4,s4,-580 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002274:	00015997          	auipc	s3,0x15
    80002278:	e5c98993          	addi	s3,s3,-420 # 800170d0 <tickslock>
    8000227c:	a029                	j	80002286 <reparent+0x34>
    8000227e:	16848493          	addi	s1,s1,360
    80002282:	01348d63          	beq	s1,s3,8000229c <reparent+0x4a>
    if(pp->parent == p){
    80002286:	7c9c                	ld	a5,56(s1)
    80002288:	ff279be3          	bne	a5,s2,8000227e <reparent+0x2c>
      pp->parent = initproc;
    8000228c:	000a3503          	ld	a0,0(s4)
    80002290:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002292:	00000097          	auipc	ra,0x0
    80002296:	f4a080e7          	jalr	-182(ra) # 800021dc <wakeup>
    8000229a:	b7d5                	j	8000227e <reparent+0x2c>
}
    8000229c:	70a2                	ld	ra,40(sp)
    8000229e:	7402                	ld	s0,32(sp)
    800022a0:	64e2                	ld	s1,24(sp)
    800022a2:	6942                	ld	s2,16(sp)
    800022a4:	69a2                	ld	s3,8(sp)
    800022a6:	6a02                	ld	s4,0(sp)
    800022a8:	6145                	addi	sp,sp,48
    800022aa:	8082                	ret

00000000800022ac <exit>:
{
    800022ac:	7179                	addi	sp,sp,-48
    800022ae:	f406                	sd	ra,40(sp)
    800022b0:	f022                	sd	s0,32(sp)
    800022b2:	ec26                	sd	s1,24(sp)
    800022b4:	e84a                	sd	s2,16(sp)
    800022b6:	e44e                	sd	s3,8(sp)
    800022b8:	e052                	sd	s4,0(sp)
    800022ba:	1800                	addi	s0,sp,48
    800022bc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	6d6080e7          	jalr	1750(ra) # 80001994 <myproc>
    800022c6:	89aa                	mv	s3,a0
  if(p == initproc)
    800022c8:	00007797          	auipc	a5,0x7
    800022cc:	d607b783          	ld	a5,-672(a5) # 80009028 <initproc>
    800022d0:	0d050493          	addi	s1,a0,208
    800022d4:	15050913          	addi	s2,a0,336
    800022d8:	02a79363          	bne	a5,a0,800022fe <exit+0x52>
    panic("init exiting");
    800022dc:	00006517          	auipc	a0,0x6
    800022e0:	f6c50513          	addi	a0,a0,-148 # 80008248 <digits+0x208>
    800022e4:	ffffe097          	auipc	ra,0xffffe
    800022e8:	24c080e7          	jalr	588(ra) # 80000530 <panic>
      fileclose(f);
    800022ec:	00002097          	auipc	ra,0x2
    800022f0:	1a6080e7          	jalr	422(ra) # 80004492 <fileclose>
      p->ofile[fd] = 0;
    800022f4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022f8:	04a1                	addi	s1,s1,8
    800022fa:	01248563          	beq	s1,s2,80002304 <exit+0x58>
    if(p->ofile[fd]){
    800022fe:	6088                	ld	a0,0(s1)
    80002300:	f575                	bnez	a0,800022ec <exit+0x40>
    80002302:	bfdd                	j	800022f8 <exit+0x4c>
  begin_op();
    80002304:	00002097          	auipc	ra,0x2
    80002308:	cc2080e7          	jalr	-830(ra) # 80003fc6 <begin_op>
  iput(p->cwd);
    8000230c:	1509b503          	ld	a0,336(s3)
    80002310:	00001097          	auipc	ra,0x1
    80002314:	49e080e7          	jalr	1182(ra) # 800037ae <iput>
  end_op();
    80002318:	00002097          	auipc	ra,0x2
    8000231c:	d2e080e7          	jalr	-722(ra) # 80004046 <end_op>
  p->cwd = 0;
    80002320:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002324:	0000f497          	auipc	s1,0xf
    80002328:	f9448493          	addi	s1,s1,-108 # 800112b8 <wait_lock>
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	8a8080e7          	jalr	-1880(ra) # 80000bd6 <acquire>
  reparent(p);
    80002336:	854e                	mv	a0,s3
    80002338:	00000097          	auipc	ra,0x0
    8000233c:	f1a080e7          	jalr	-230(ra) # 80002252 <reparent>
  wakeup(p->parent);
    80002340:	0389b503          	ld	a0,56(s3)
    80002344:	00000097          	auipc	ra,0x0
    80002348:	e98080e7          	jalr	-360(ra) # 800021dc <wakeup>
  acquire(&p->lock);
    8000234c:	854e                	mv	a0,s3
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	888080e7          	jalr	-1912(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002356:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000235a:	4795                	li	a5,5
    8000235c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	928080e7          	jalr	-1752(ra) # 80000c8a <release>
  sched();
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	bd4080e7          	jalr	-1068(ra) # 80001f3e <sched>
  panic("zombie exit");
    80002372:	00006517          	auipc	a0,0x6
    80002376:	ee650513          	addi	a0,a0,-282 # 80008258 <digits+0x218>
    8000237a:	ffffe097          	auipc	ra,0xffffe
    8000237e:	1b6080e7          	jalr	438(ra) # 80000530 <panic>

0000000080002382 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002382:	7179                	addi	sp,sp,-48
    80002384:	f406                	sd	ra,40(sp)
    80002386:	f022                	sd	s0,32(sp)
    80002388:	ec26                	sd	s1,24(sp)
    8000238a:	e84a                	sd	s2,16(sp)
    8000238c:	e44e                	sd	s3,8(sp)
    8000238e:	1800                	addi	s0,sp,48
    80002390:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002392:	0000f497          	auipc	s1,0xf
    80002396:	33e48493          	addi	s1,s1,830 # 800116d0 <proc>
    8000239a:	00015997          	auipc	s3,0x15
    8000239e:	d3698993          	addi	s3,s3,-714 # 800170d0 <tickslock>
    acquire(&p->lock);
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	832080e7          	jalr	-1998(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800023ac:	589c                	lw	a5,48(s1)
    800023ae:	01278d63          	beq	a5,s2,800023c8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8d6080e7          	jalr	-1834(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023bc:	16848493          	addi	s1,s1,360
    800023c0:	ff3491e3          	bne	s1,s3,800023a2 <kill+0x20>
  }
  return -1;
    800023c4:	557d                	li	a0,-1
    800023c6:	a829                	j	800023e0 <kill+0x5e>
      p->killed = 1;
    800023c8:	4785                	li	a5,1
    800023ca:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023cc:	4c98                	lw	a4,24(s1)
    800023ce:	4789                	li	a5,2
    800023d0:	00f70f63          	beq	a4,a5,800023ee <kill+0x6c>
      release(&p->lock);
    800023d4:	8526                	mv	a0,s1
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	8b4080e7          	jalr	-1868(ra) # 80000c8a <release>
      return 0;
    800023de:	4501                	li	a0,0
}
    800023e0:	70a2                	ld	ra,40(sp)
    800023e2:	7402                	ld	s0,32(sp)
    800023e4:	64e2                	ld	s1,24(sp)
    800023e6:	6942                	ld	s2,16(sp)
    800023e8:	69a2                	ld	s3,8(sp)
    800023ea:	6145                	addi	sp,sp,48
    800023ec:	8082                	ret
        p->state = RUNNABLE;
    800023ee:	478d                	li	a5,3
    800023f0:	cc9c                	sw	a5,24(s1)
    800023f2:	b7cd                	j	800023d4 <kill+0x52>

00000000800023f4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800023f4:	7179                	addi	sp,sp,-48
    800023f6:	f406                	sd	ra,40(sp)
    800023f8:	f022                	sd	s0,32(sp)
    800023fa:	ec26                	sd	s1,24(sp)
    800023fc:	e84a                	sd	s2,16(sp)
    800023fe:	e44e                	sd	s3,8(sp)
    80002400:	e052                	sd	s4,0(sp)
    80002402:	1800                	addi	s0,sp,48
    80002404:	84aa                	mv	s1,a0
    80002406:	892e                	mv	s2,a1
    80002408:	89b2                	mv	s3,a2
    8000240a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	588080e7          	jalr	1416(ra) # 80001994 <myproc>
  if(user_dst){
    80002414:	c08d                	beqz	s1,80002436 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002416:	86d2                	mv	a3,s4
    80002418:	864e                	mv	a2,s3
    8000241a:	85ca                	mv	a1,s2
    8000241c:	6928                	ld	a0,80(a0)
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	238080e7          	jalr	568(ra) # 80001656 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002426:	70a2                	ld	ra,40(sp)
    80002428:	7402                	ld	s0,32(sp)
    8000242a:	64e2                	ld	s1,24(sp)
    8000242c:	6942                	ld	s2,16(sp)
    8000242e:	69a2                	ld	s3,8(sp)
    80002430:	6a02                	ld	s4,0(sp)
    80002432:	6145                	addi	sp,sp,48
    80002434:	8082                	ret
    memmove((char *)dst, src, len);
    80002436:	000a061b          	sext.w	a2,s4
    8000243a:	85ce                	mv	a1,s3
    8000243c:	854a                	mv	a0,s2
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	8f4080e7          	jalr	-1804(ra) # 80000d32 <memmove>
    return 0;
    80002446:	8526                	mv	a0,s1
    80002448:	bff9                	j	80002426 <either_copyout+0x32>

000000008000244a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000244a:	7179                	addi	sp,sp,-48
    8000244c:	f406                	sd	ra,40(sp)
    8000244e:	f022                	sd	s0,32(sp)
    80002450:	ec26                	sd	s1,24(sp)
    80002452:	e84a                	sd	s2,16(sp)
    80002454:	e44e                	sd	s3,8(sp)
    80002456:	e052                	sd	s4,0(sp)
    80002458:	1800                	addi	s0,sp,48
    8000245a:	892a                	mv	s2,a0
    8000245c:	84ae                	mv	s1,a1
    8000245e:	89b2                	mv	s3,a2
    80002460:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	532080e7          	jalr	1330(ra) # 80001994 <myproc>
  if(user_src){
    8000246a:	c08d                	beqz	s1,8000248c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000246c:	86d2                	mv	a3,s4
    8000246e:	864e                	mv	a2,s3
    80002470:	85ca                	mv	a1,s2
    80002472:	6928                	ld	a0,80(a0)
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	26e080e7          	jalr	622(ra) # 800016e2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000247c:	70a2                	ld	ra,40(sp)
    8000247e:	7402                	ld	s0,32(sp)
    80002480:	64e2                	ld	s1,24(sp)
    80002482:	6942                	ld	s2,16(sp)
    80002484:	69a2                	ld	s3,8(sp)
    80002486:	6a02                	ld	s4,0(sp)
    80002488:	6145                	addi	sp,sp,48
    8000248a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000248c:	000a061b          	sext.w	a2,s4
    80002490:	85ce                	mv	a1,s3
    80002492:	854a                	mv	a0,s2
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	89e080e7          	jalr	-1890(ra) # 80000d32 <memmove>
    return 0;
    8000249c:	8526                	mv	a0,s1
    8000249e:	bff9                	j	8000247c <either_copyin+0x32>

00000000800024a0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024a0:	715d                	addi	sp,sp,-80
    800024a2:	e486                	sd	ra,72(sp)
    800024a4:	e0a2                	sd	s0,64(sp)
    800024a6:	fc26                	sd	s1,56(sp)
    800024a8:	f84a                	sd	s2,48(sp)
    800024aa:	f44e                	sd	s3,40(sp)
    800024ac:	f052                	sd	s4,32(sp)
    800024ae:	ec56                	sd	s5,24(sp)
    800024b0:	e85a                	sd	s6,16(sp)
    800024b2:	e45e                	sd	s7,8(sp)
    800024b4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024b6:	00006517          	auipc	a0,0x6
    800024ba:	c1250513          	addi	a0,a0,-1006 # 800080c8 <digits+0x88>
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	0bc080e7          	jalr	188(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024c6:	0000f497          	auipc	s1,0xf
    800024ca:	36248493          	addi	s1,s1,866 # 80011828 <proc+0x158>
    800024ce:	00015917          	auipc	s2,0x15
    800024d2:	d5a90913          	addi	s2,s2,-678 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024d6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800024d8:	00006997          	auipc	s3,0x6
    800024dc:	d9098993          	addi	s3,s3,-624 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800024e0:	00006a97          	auipc	s5,0x6
    800024e4:	d90a8a93          	addi	s5,s5,-624 # 80008270 <digits+0x230>
    printf("\n");
    800024e8:	00006a17          	auipc	s4,0x6
    800024ec:	be0a0a13          	addi	s4,s4,-1056 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024f0:	00006b97          	auipc	s7,0x6
    800024f4:	db8b8b93          	addi	s7,s7,-584 # 800082a8 <states.1705>
    800024f8:	a00d                	j	8000251a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800024fa:	ed86a583          	lw	a1,-296(a3)
    800024fe:	8556                	mv	a0,s5
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	07a080e7          	jalr	122(ra) # 8000057a <printf>
    printf("\n");
    80002508:	8552                	mv	a0,s4
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	070080e7          	jalr	112(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002512:	16848493          	addi	s1,s1,360
    80002516:	03248163          	beq	s1,s2,80002538 <procdump+0x98>
    if(p->state == UNUSED)
    8000251a:	86a6                	mv	a3,s1
    8000251c:	ec04a783          	lw	a5,-320(s1)
    80002520:	dbed                	beqz	a5,80002512 <procdump+0x72>
      state = "???";
    80002522:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002524:	fcfb6be3          	bltu	s6,a5,800024fa <procdump+0x5a>
    80002528:	1782                	slli	a5,a5,0x20
    8000252a:	9381                	srli	a5,a5,0x20
    8000252c:	078e                	slli	a5,a5,0x3
    8000252e:	97de                	add	a5,a5,s7
    80002530:	6390                	ld	a2,0(a5)
    80002532:	f661                	bnez	a2,800024fa <procdump+0x5a>
      state = "???";
    80002534:	864e                	mv	a2,s3
    80002536:	b7d1                	j	800024fa <procdump+0x5a>
  }
}
    80002538:	60a6                	ld	ra,72(sp)
    8000253a:	6406                	ld	s0,64(sp)
    8000253c:	74e2                	ld	s1,56(sp)
    8000253e:	7942                	ld	s2,48(sp)
    80002540:	79a2                	ld	s3,40(sp)
    80002542:	7a02                	ld	s4,32(sp)
    80002544:	6ae2                	ld	s5,24(sp)
    80002546:	6b42                	ld	s6,16(sp)
    80002548:	6ba2                	ld	s7,8(sp)
    8000254a:	6161                	addi	sp,sp,80
    8000254c:	8082                	ret

000000008000254e <swtch>:
    8000254e:	00153023          	sd	ra,0(a0)
    80002552:	00253423          	sd	sp,8(a0)
    80002556:	e900                	sd	s0,16(a0)
    80002558:	ed04                	sd	s1,24(a0)
    8000255a:	03253023          	sd	s2,32(a0)
    8000255e:	03353423          	sd	s3,40(a0)
    80002562:	03453823          	sd	s4,48(a0)
    80002566:	03553c23          	sd	s5,56(a0)
    8000256a:	05653023          	sd	s6,64(a0)
    8000256e:	05753423          	sd	s7,72(a0)
    80002572:	05853823          	sd	s8,80(a0)
    80002576:	05953c23          	sd	s9,88(a0)
    8000257a:	07a53023          	sd	s10,96(a0)
    8000257e:	07b53423          	sd	s11,104(a0)
    80002582:	0005b083          	ld	ra,0(a1)
    80002586:	0085b103          	ld	sp,8(a1)
    8000258a:	6980                	ld	s0,16(a1)
    8000258c:	6d84                	ld	s1,24(a1)
    8000258e:	0205b903          	ld	s2,32(a1)
    80002592:	0285b983          	ld	s3,40(a1)
    80002596:	0305ba03          	ld	s4,48(a1)
    8000259a:	0385ba83          	ld	s5,56(a1)
    8000259e:	0405bb03          	ld	s6,64(a1)
    800025a2:	0485bb83          	ld	s7,72(a1)
    800025a6:	0505bc03          	ld	s8,80(a1)
    800025aa:	0585bc83          	ld	s9,88(a1)
    800025ae:	0605bd03          	ld	s10,96(a1)
    800025b2:	0685bd83          	ld	s11,104(a1)
    800025b6:	8082                	ret

00000000800025b8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025b8:	1141                	addi	sp,sp,-16
    800025ba:	e406                	sd	ra,8(sp)
    800025bc:	e022                	sd	s0,0(sp)
    800025be:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025c0:	00006597          	auipc	a1,0x6
    800025c4:	d1858593          	addi	a1,a1,-744 # 800082d8 <states.1705+0x30>
    800025c8:	00015517          	auipc	a0,0x15
    800025cc:	b0850513          	addi	a0,a0,-1272 # 800170d0 <tickslock>
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	576080e7          	jalr	1398(ra) # 80000b46 <initlock>
}
    800025d8:	60a2                	ld	ra,8(sp)
    800025da:	6402                	ld	s0,0(sp)
    800025dc:	0141                	addi	sp,sp,16
    800025de:	8082                	ret

00000000800025e0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025e0:	1141                	addi	sp,sp,-16
    800025e2:	e422                	sd	s0,8(sp)
    800025e4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025e6:	00003797          	auipc	a5,0x3
    800025ea:	4ca78793          	addi	a5,a5,1226 # 80005ab0 <kernelvec>
    800025ee:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800025f2:	6422                	ld	s0,8(sp)
    800025f4:	0141                	addi	sp,sp,16
    800025f6:	8082                	ret

00000000800025f8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800025f8:	1141                	addi	sp,sp,-16
    800025fa:	e406                	sd	ra,8(sp)
    800025fc:	e022                	sd	s0,0(sp)
    800025fe:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002600:	fffff097          	auipc	ra,0xfffff
    80002604:	394080e7          	jalr	916(ra) # 80001994 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002608:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000260c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000260e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002612:	00005617          	auipc	a2,0x5
    80002616:	9ee60613          	addi	a2,a2,-1554 # 80007000 <_trampoline>
    8000261a:	00005697          	auipc	a3,0x5
    8000261e:	9e668693          	addi	a3,a3,-1562 # 80007000 <_trampoline>
    80002622:	8e91                	sub	a3,a3,a2
    80002624:	040007b7          	lui	a5,0x4000
    80002628:	17fd                	addi	a5,a5,-1
    8000262a:	07b2                	slli	a5,a5,0xc
    8000262c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000262e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002632:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002634:	180026f3          	csrr	a3,satp
    80002638:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000263a:	6d38                	ld	a4,88(a0)
    8000263c:	6134                	ld	a3,64(a0)
    8000263e:	6585                	lui	a1,0x1
    80002640:	96ae                	add	a3,a3,a1
    80002642:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002644:	6d38                	ld	a4,88(a0)
    80002646:	00000697          	auipc	a3,0x0
    8000264a:	13868693          	addi	a3,a3,312 # 8000277e <usertrap>
    8000264e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002650:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002652:	8692                	mv	a3,tp
    80002654:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002656:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000265a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000265e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002662:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002666:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002668:	6f18                	ld	a4,24(a4)
    8000266a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000266e:	692c                	ld	a1,80(a0)
    80002670:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002672:	00005717          	auipc	a4,0x5
    80002676:	a1e70713          	addi	a4,a4,-1506 # 80007090 <userret>
    8000267a:	8f11                	sub	a4,a4,a2
    8000267c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000267e:	577d                	li	a4,-1
    80002680:	177e                	slli	a4,a4,0x3f
    80002682:	8dd9                	or	a1,a1,a4
    80002684:	02000537          	lui	a0,0x2000
    80002688:	157d                	addi	a0,a0,-1
    8000268a:	0536                	slli	a0,a0,0xd
    8000268c:	9782                	jalr	a5
}
    8000268e:	60a2                	ld	ra,8(sp)
    80002690:	6402                	ld	s0,0(sp)
    80002692:	0141                	addi	sp,sp,16
    80002694:	8082                	ret

0000000080002696 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002696:	1101                	addi	sp,sp,-32
    80002698:	ec06                	sd	ra,24(sp)
    8000269a:	e822                	sd	s0,16(sp)
    8000269c:	e426                	sd	s1,8(sp)
    8000269e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026a0:	00015497          	auipc	s1,0x15
    800026a4:	a3048493          	addi	s1,s1,-1488 # 800170d0 <tickslock>
    800026a8:	8526                	mv	a0,s1
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	52c080e7          	jalr	1324(ra) # 80000bd6 <acquire>
  ticks++;
    800026b2:	00007517          	auipc	a0,0x7
    800026b6:	97e50513          	addi	a0,a0,-1666 # 80009030 <ticks>
    800026ba:	411c                	lw	a5,0(a0)
    800026bc:	2785                	addiw	a5,a5,1
    800026be:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026c0:	00000097          	auipc	ra,0x0
    800026c4:	b1c080e7          	jalr	-1252(ra) # 800021dc <wakeup>
  release(&tickslock);
    800026c8:	8526                	mv	a0,s1
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	5c0080e7          	jalr	1472(ra) # 80000c8a <release>
}
    800026d2:	60e2                	ld	ra,24(sp)
    800026d4:	6442                	ld	s0,16(sp)
    800026d6:	64a2                	ld	s1,8(sp)
    800026d8:	6105                	addi	sp,sp,32
    800026da:	8082                	ret

00000000800026dc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026dc:	1101                	addi	sp,sp,-32
    800026de:	ec06                	sd	ra,24(sp)
    800026e0:	e822                	sd	s0,16(sp)
    800026e2:	e426                	sd	s1,8(sp)
    800026e4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026e6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800026ea:	00074d63          	bltz	a4,80002704 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800026ee:	57fd                	li	a5,-1
    800026f0:	17fe                	slli	a5,a5,0x3f
    800026f2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800026f4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800026f6:	06f70363          	beq	a4,a5,8000275c <devintr+0x80>
  }
}
    800026fa:	60e2                	ld	ra,24(sp)
    800026fc:	6442                	ld	s0,16(sp)
    800026fe:	64a2                	ld	s1,8(sp)
    80002700:	6105                	addi	sp,sp,32
    80002702:	8082                	ret
     (scause & 0xff) == 9){
    80002704:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002708:	46a5                	li	a3,9
    8000270a:	fed792e3          	bne	a5,a3,800026ee <devintr+0x12>
    int irq = plic_claim();
    8000270e:	00003097          	auipc	ra,0x3
    80002712:	4aa080e7          	jalr	1194(ra) # 80005bb8 <plic_claim>
    80002716:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002718:	47a9                	li	a5,10
    8000271a:	02f50763          	beq	a0,a5,80002748 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000271e:	4785                	li	a5,1
    80002720:	02f50963          	beq	a0,a5,80002752 <devintr+0x76>
    return 1;
    80002724:	4505                	li	a0,1
    } else if(irq){
    80002726:	d8f1                	beqz	s1,800026fa <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002728:	85a6                	mv	a1,s1
    8000272a:	00006517          	auipc	a0,0x6
    8000272e:	bb650513          	addi	a0,a0,-1098 # 800082e0 <states.1705+0x38>
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	e48080e7          	jalr	-440(ra) # 8000057a <printf>
      plic_complete(irq);
    8000273a:	8526                	mv	a0,s1
    8000273c:	00003097          	auipc	ra,0x3
    80002740:	4a0080e7          	jalr	1184(ra) # 80005bdc <plic_complete>
    return 1;
    80002744:	4505                	li	a0,1
    80002746:	bf55                	j	800026fa <devintr+0x1e>
      uartintr();
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	252080e7          	jalr	594(ra) # 8000099a <uartintr>
    80002750:	b7ed                	j	8000273a <devintr+0x5e>
      virtio_disk_intr();
    80002752:	00004097          	auipc	ra,0x4
    80002756:	96a080e7          	jalr	-1686(ra) # 800060bc <virtio_disk_intr>
    8000275a:	b7c5                	j	8000273a <devintr+0x5e>
    if(cpuid() == 0){
    8000275c:	fffff097          	auipc	ra,0xfffff
    80002760:	20c080e7          	jalr	524(ra) # 80001968 <cpuid>
    80002764:	c901                	beqz	a0,80002774 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002766:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000276a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000276c:	14479073          	csrw	sip,a5
    return 2;
    80002770:	4509                	li	a0,2
    80002772:	b761                	j	800026fa <devintr+0x1e>
      clockintr();
    80002774:	00000097          	auipc	ra,0x0
    80002778:	f22080e7          	jalr	-222(ra) # 80002696 <clockintr>
    8000277c:	b7ed                	j	80002766 <devintr+0x8a>

000000008000277e <usertrap>:
{
    8000277e:	1101                	addi	sp,sp,-32
    80002780:	ec06                	sd	ra,24(sp)
    80002782:	e822                	sd	s0,16(sp)
    80002784:	e426                	sd	s1,8(sp)
    80002786:	e04a                	sd	s2,0(sp)
    80002788:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000278a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000278e:	1007f793          	andi	a5,a5,256
    80002792:	e3ad                	bnez	a5,800027f4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002794:	00003797          	auipc	a5,0x3
    80002798:	31c78793          	addi	a5,a5,796 # 80005ab0 <kernelvec>
    8000279c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027a0:	fffff097          	auipc	ra,0xfffff
    800027a4:	1f4080e7          	jalr	500(ra) # 80001994 <myproc>
    800027a8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027aa:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027ac:	14102773          	csrr	a4,sepc
    800027b0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027b2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027b6:	47a1                	li	a5,8
    800027b8:	04f71c63          	bne	a4,a5,80002810 <usertrap+0x92>
    if(p->killed)
    800027bc:	551c                	lw	a5,40(a0)
    800027be:	e3b9                	bnez	a5,80002804 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027c0:	6cb8                	ld	a4,88(s1)
    800027c2:	6f1c                	ld	a5,24(a4)
    800027c4:	0791                	addi	a5,a5,4
    800027c6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027cc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d0:	10079073          	csrw	sstatus,a5
    syscall();
    800027d4:	00000097          	auipc	ra,0x0
    800027d8:	2e0080e7          	jalr	736(ra) # 80002ab4 <syscall>
  if(p->killed)
    800027dc:	549c                	lw	a5,40(s1)
    800027de:	ebc1                	bnez	a5,8000286e <usertrap+0xf0>
  usertrapret();
    800027e0:	00000097          	auipc	ra,0x0
    800027e4:	e18080e7          	jalr	-488(ra) # 800025f8 <usertrapret>
}
    800027e8:	60e2                	ld	ra,24(sp)
    800027ea:	6442                	ld	s0,16(sp)
    800027ec:	64a2                	ld	s1,8(sp)
    800027ee:	6902                	ld	s2,0(sp)
    800027f0:	6105                	addi	sp,sp,32
    800027f2:	8082                	ret
    panic("usertrap: not from user mode");
    800027f4:	00006517          	auipc	a0,0x6
    800027f8:	b0c50513          	addi	a0,a0,-1268 # 80008300 <states.1705+0x58>
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	d34080e7          	jalr	-716(ra) # 80000530 <panic>
      exit(-1);
    80002804:	557d                	li	a0,-1
    80002806:	00000097          	auipc	ra,0x0
    8000280a:	aa6080e7          	jalr	-1370(ra) # 800022ac <exit>
    8000280e:	bf4d                	j	800027c0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002810:	00000097          	auipc	ra,0x0
    80002814:	ecc080e7          	jalr	-308(ra) # 800026dc <devintr>
    80002818:	892a                	mv	s2,a0
    8000281a:	c501                	beqz	a0,80002822 <usertrap+0xa4>
  if(p->killed)
    8000281c:	549c                	lw	a5,40(s1)
    8000281e:	c3a1                	beqz	a5,8000285e <usertrap+0xe0>
    80002820:	a815                	j	80002854 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002822:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002826:	5890                	lw	a2,48(s1)
    80002828:	00006517          	auipc	a0,0x6
    8000282c:	af850513          	addi	a0,a0,-1288 # 80008320 <states.1705+0x78>
    80002830:	ffffe097          	auipc	ra,0xffffe
    80002834:	d4a080e7          	jalr	-694(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002838:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000283c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002840:	00006517          	auipc	a0,0x6
    80002844:	b1050513          	addi	a0,a0,-1264 # 80008350 <states.1705+0xa8>
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	d32080e7          	jalr	-718(ra) # 8000057a <printf>
    p->killed = 1;
    80002850:	4785                	li	a5,1
    80002852:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002854:	557d                	li	a0,-1
    80002856:	00000097          	auipc	ra,0x0
    8000285a:	a56080e7          	jalr	-1450(ra) # 800022ac <exit>
  if(which_dev == 2)
    8000285e:	4789                	li	a5,2
    80002860:	f8f910e3          	bne	s2,a5,800027e0 <usertrap+0x62>
    yield();
    80002864:	fffff097          	auipc	ra,0xfffff
    80002868:	7b0080e7          	jalr	1968(ra) # 80002014 <yield>
    8000286c:	bf95                	j	800027e0 <usertrap+0x62>
  int which_dev = 0;
    8000286e:	4901                	li	s2,0
    80002870:	b7d5                	j	80002854 <usertrap+0xd6>

0000000080002872 <kerneltrap>:
{
    80002872:	7179                	addi	sp,sp,-48
    80002874:	f406                	sd	ra,40(sp)
    80002876:	f022                	sd	s0,32(sp)
    80002878:	ec26                	sd	s1,24(sp)
    8000287a:	e84a                	sd	s2,16(sp)
    8000287c:	e44e                	sd	s3,8(sp)
    8000287e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002880:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002884:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002888:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000288c:	1004f793          	andi	a5,s1,256
    80002890:	cb85                	beqz	a5,800028c0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002892:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002896:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002898:	ef85                	bnez	a5,800028d0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000289a:	00000097          	auipc	ra,0x0
    8000289e:	e42080e7          	jalr	-446(ra) # 800026dc <devintr>
    800028a2:	cd1d                	beqz	a0,800028e0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028a4:	4789                	li	a5,2
    800028a6:	06f50a63          	beq	a0,a5,8000291a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028aa:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ae:	10049073          	csrw	sstatus,s1
}
    800028b2:	70a2                	ld	ra,40(sp)
    800028b4:	7402                	ld	s0,32(sp)
    800028b6:	64e2                	ld	s1,24(sp)
    800028b8:	6942                	ld	s2,16(sp)
    800028ba:	69a2                	ld	s3,8(sp)
    800028bc:	6145                	addi	sp,sp,48
    800028be:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028c0:	00006517          	auipc	a0,0x6
    800028c4:	ab050513          	addi	a0,a0,-1360 # 80008370 <states.1705+0xc8>
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	c68080e7          	jalr	-920(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    800028d0:	00006517          	auipc	a0,0x6
    800028d4:	ac850513          	addi	a0,a0,-1336 # 80008398 <states.1705+0xf0>
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	c58080e7          	jalr	-936(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    800028e0:	85ce                	mv	a1,s3
    800028e2:	00006517          	auipc	a0,0x6
    800028e6:	ad650513          	addi	a0,a0,-1322 # 800083b8 <states.1705+0x110>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	c90080e7          	jalr	-880(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028f2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028f6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028fa:	00006517          	auipc	a0,0x6
    800028fe:	ace50513          	addi	a0,a0,-1330 # 800083c8 <states.1705+0x120>
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	c78080e7          	jalr	-904(ra) # 8000057a <printf>
    panic("kerneltrap");
    8000290a:	00006517          	auipc	a0,0x6
    8000290e:	ad650513          	addi	a0,a0,-1322 # 800083e0 <states.1705+0x138>
    80002912:	ffffe097          	auipc	ra,0xffffe
    80002916:	c1e080e7          	jalr	-994(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000291a:	fffff097          	auipc	ra,0xfffff
    8000291e:	07a080e7          	jalr	122(ra) # 80001994 <myproc>
    80002922:	d541                	beqz	a0,800028aa <kerneltrap+0x38>
    80002924:	fffff097          	auipc	ra,0xfffff
    80002928:	070080e7          	jalr	112(ra) # 80001994 <myproc>
    8000292c:	4d18                	lw	a4,24(a0)
    8000292e:	4791                	li	a5,4
    80002930:	f6f71de3          	bne	a4,a5,800028aa <kerneltrap+0x38>
    yield();
    80002934:	fffff097          	auipc	ra,0xfffff
    80002938:	6e0080e7          	jalr	1760(ra) # 80002014 <yield>
    8000293c:	b7bd                	j	800028aa <kerneltrap+0x38>

000000008000293e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000293e:	1101                	addi	sp,sp,-32
    80002940:	ec06                	sd	ra,24(sp)
    80002942:	e822                	sd	s0,16(sp)
    80002944:	e426                	sd	s1,8(sp)
    80002946:	1000                	addi	s0,sp,32
    80002948:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000294a:	fffff097          	auipc	ra,0xfffff
    8000294e:	04a080e7          	jalr	74(ra) # 80001994 <myproc>
  switch (n) {
    80002952:	4795                	li	a5,5
    80002954:	0497e163          	bltu	a5,s1,80002996 <argraw+0x58>
    80002958:	048a                	slli	s1,s1,0x2
    8000295a:	00006717          	auipc	a4,0x6
    8000295e:	abe70713          	addi	a4,a4,-1346 # 80008418 <states.1705+0x170>
    80002962:	94ba                	add	s1,s1,a4
    80002964:	409c                	lw	a5,0(s1)
    80002966:	97ba                	add	a5,a5,a4
    80002968:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000296a:	6d3c                	ld	a5,88(a0)
    8000296c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000296e:	60e2                	ld	ra,24(sp)
    80002970:	6442                	ld	s0,16(sp)
    80002972:	64a2                	ld	s1,8(sp)
    80002974:	6105                	addi	sp,sp,32
    80002976:	8082                	ret
    return p->trapframe->a1;
    80002978:	6d3c                	ld	a5,88(a0)
    8000297a:	7fa8                	ld	a0,120(a5)
    8000297c:	bfcd                	j	8000296e <argraw+0x30>
    return p->trapframe->a2;
    8000297e:	6d3c                	ld	a5,88(a0)
    80002980:	63c8                	ld	a0,128(a5)
    80002982:	b7f5                	j	8000296e <argraw+0x30>
    return p->trapframe->a3;
    80002984:	6d3c                	ld	a5,88(a0)
    80002986:	67c8                	ld	a0,136(a5)
    80002988:	b7dd                	j	8000296e <argraw+0x30>
    return p->trapframe->a4;
    8000298a:	6d3c                	ld	a5,88(a0)
    8000298c:	6bc8                	ld	a0,144(a5)
    8000298e:	b7c5                	j	8000296e <argraw+0x30>
    return p->trapframe->a5;
    80002990:	6d3c                	ld	a5,88(a0)
    80002992:	6fc8                	ld	a0,152(a5)
    80002994:	bfe9                	j	8000296e <argraw+0x30>
  panic("argraw");
    80002996:	00006517          	auipc	a0,0x6
    8000299a:	a5a50513          	addi	a0,a0,-1446 # 800083f0 <states.1705+0x148>
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	b92080e7          	jalr	-1134(ra) # 80000530 <panic>

00000000800029a6 <fetchaddr>:
{
    800029a6:	1101                	addi	sp,sp,-32
    800029a8:	ec06                	sd	ra,24(sp)
    800029aa:	e822                	sd	s0,16(sp)
    800029ac:	e426                	sd	s1,8(sp)
    800029ae:	e04a                	sd	s2,0(sp)
    800029b0:	1000                	addi	s0,sp,32
    800029b2:	84aa                	mv	s1,a0
    800029b4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029b6:	fffff097          	auipc	ra,0xfffff
    800029ba:	fde080e7          	jalr	-34(ra) # 80001994 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029be:	653c                	ld	a5,72(a0)
    800029c0:	02f4f863          	bgeu	s1,a5,800029f0 <fetchaddr+0x4a>
    800029c4:	00848713          	addi	a4,s1,8
    800029c8:	02e7e663          	bltu	a5,a4,800029f4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029cc:	46a1                	li	a3,8
    800029ce:	8626                	mv	a2,s1
    800029d0:	85ca                	mv	a1,s2
    800029d2:	6928                	ld	a0,80(a0)
    800029d4:	fffff097          	auipc	ra,0xfffff
    800029d8:	d0e080e7          	jalr	-754(ra) # 800016e2 <copyin>
    800029dc:	00a03533          	snez	a0,a0
    800029e0:	40a00533          	neg	a0,a0
}
    800029e4:	60e2                	ld	ra,24(sp)
    800029e6:	6442                	ld	s0,16(sp)
    800029e8:	64a2                	ld	s1,8(sp)
    800029ea:	6902                	ld	s2,0(sp)
    800029ec:	6105                	addi	sp,sp,32
    800029ee:	8082                	ret
    return -1;
    800029f0:	557d                	li	a0,-1
    800029f2:	bfcd                	j	800029e4 <fetchaddr+0x3e>
    800029f4:	557d                	li	a0,-1
    800029f6:	b7fd                	j	800029e4 <fetchaddr+0x3e>

00000000800029f8 <fetchstr>:
{
    800029f8:	7179                	addi	sp,sp,-48
    800029fa:	f406                	sd	ra,40(sp)
    800029fc:	f022                	sd	s0,32(sp)
    800029fe:	ec26                	sd	s1,24(sp)
    80002a00:	e84a                	sd	s2,16(sp)
    80002a02:	e44e                	sd	s3,8(sp)
    80002a04:	1800                	addi	s0,sp,48
    80002a06:	892a                	mv	s2,a0
    80002a08:	84ae                	mv	s1,a1
    80002a0a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a0c:	fffff097          	auipc	ra,0xfffff
    80002a10:	f88080e7          	jalr	-120(ra) # 80001994 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a14:	86ce                	mv	a3,s3
    80002a16:	864a                	mv	a2,s2
    80002a18:	85a6                	mv	a1,s1
    80002a1a:	6928                	ld	a0,80(a0)
    80002a1c:	fffff097          	auipc	ra,0xfffff
    80002a20:	d52080e7          	jalr	-686(ra) # 8000176e <copyinstr>
  if(err < 0)
    80002a24:	00054763          	bltz	a0,80002a32 <fetchstr+0x3a>
  return strlen(buf);
    80002a28:	8526                	mv	a0,s1
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	430080e7          	jalr	1072(ra) # 80000e5a <strlen>
}
    80002a32:	70a2                	ld	ra,40(sp)
    80002a34:	7402                	ld	s0,32(sp)
    80002a36:	64e2                	ld	s1,24(sp)
    80002a38:	6942                	ld	s2,16(sp)
    80002a3a:	69a2                	ld	s3,8(sp)
    80002a3c:	6145                	addi	sp,sp,48
    80002a3e:	8082                	ret

0000000080002a40 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a40:	1101                	addi	sp,sp,-32
    80002a42:	ec06                	sd	ra,24(sp)
    80002a44:	e822                	sd	s0,16(sp)
    80002a46:	e426                	sd	s1,8(sp)
    80002a48:	1000                	addi	s0,sp,32
    80002a4a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a4c:	00000097          	auipc	ra,0x0
    80002a50:	ef2080e7          	jalr	-270(ra) # 8000293e <argraw>
    80002a54:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a56:	4501                	li	a0,0
    80002a58:	60e2                	ld	ra,24(sp)
    80002a5a:	6442                	ld	s0,16(sp)
    80002a5c:	64a2                	ld	s1,8(sp)
    80002a5e:	6105                	addi	sp,sp,32
    80002a60:	8082                	ret

0000000080002a62 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a62:	1101                	addi	sp,sp,-32
    80002a64:	ec06                	sd	ra,24(sp)
    80002a66:	e822                	sd	s0,16(sp)
    80002a68:	e426                	sd	s1,8(sp)
    80002a6a:	1000                	addi	s0,sp,32
    80002a6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a6e:	00000097          	auipc	ra,0x0
    80002a72:	ed0080e7          	jalr	-304(ra) # 8000293e <argraw>
    80002a76:	e088                	sd	a0,0(s1)
  return 0;
}
    80002a78:	4501                	li	a0,0
    80002a7a:	60e2                	ld	ra,24(sp)
    80002a7c:	6442                	ld	s0,16(sp)
    80002a7e:	64a2                	ld	s1,8(sp)
    80002a80:	6105                	addi	sp,sp,32
    80002a82:	8082                	ret

0000000080002a84 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002a84:	1101                	addi	sp,sp,-32
    80002a86:	ec06                	sd	ra,24(sp)
    80002a88:	e822                	sd	s0,16(sp)
    80002a8a:	e426                	sd	s1,8(sp)
    80002a8c:	e04a                	sd	s2,0(sp)
    80002a8e:	1000                	addi	s0,sp,32
    80002a90:	84ae                	mv	s1,a1
    80002a92:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002a94:	00000097          	auipc	ra,0x0
    80002a98:	eaa080e7          	jalr	-342(ra) # 8000293e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002a9c:	864a                	mv	a2,s2
    80002a9e:	85a6                	mv	a1,s1
    80002aa0:	00000097          	auipc	ra,0x0
    80002aa4:	f58080e7          	jalr	-168(ra) # 800029f8 <fetchstr>
}
    80002aa8:	60e2                	ld	ra,24(sp)
    80002aaa:	6442                	ld	s0,16(sp)
    80002aac:	64a2                	ld	s1,8(sp)
    80002aae:	6902                	ld	s2,0(sp)
    80002ab0:	6105                	addi	sp,sp,32
    80002ab2:	8082                	ret

0000000080002ab4 <syscall>:
[SYS_time]    sys_time,
};

void
syscall(void)
{
    80002ab4:	1101                	addi	sp,sp,-32
    80002ab6:	ec06                	sd	ra,24(sp)
    80002ab8:	e822                	sd	s0,16(sp)
    80002aba:	e426                	sd	s1,8(sp)
    80002abc:	e04a                	sd	s2,0(sp)
    80002abe:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	ed4080e7          	jalr	-300(ra) # 80001994 <myproc>
    80002ac8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002aca:	05853903          	ld	s2,88(a0)
    80002ace:	0a893783          	ld	a5,168(s2)
    80002ad2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ad6:	37fd                	addiw	a5,a5,-1
    80002ad8:	4755                	li	a4,21
    80002ada:	00f76f63          	bltu	a4,a5,80002af8 <syscall+0x44>
    80002ade:	00369713          	slli	a4,a3,0x3
    80002ae2:	00006797          	auipc	a5,0x6
    80002ae6:	94e78793          	addi	a5,a5,-1714 # 80008430 <syscalls>
    80002aea:	97ba                	add	a5,a5,a4
    80002aec:	639c                	ld	a5,0(a5)
    80002aee:	c789                	beqz	a5,80002af8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002af0:	9782                	jalr	a5
    80002af2:	06a93823          	sd	a0,112(s2)
    80002af6:	a839                	j	80002b14 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002af8:	15848613          	addi	a2,s1,344
    80002afc:	588c                	lw	a1,48(s1)
    80002afe:	00006517          	auipc	a0,0x6
    80002b02:	8fa50513          	addi	a0,a0,-1798 # 800083f8 <states.1705+0x150>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	a74080e7          	jalr	-1420(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b0e:	6cbc                	ld	a5,88(s1)
    80002b10:	577d                	li	a4,-1
    80002b12:	fbb8                	sd	a4,112(a5)
  }
}
    80002b14:	60e2                	ld	ra,24(sp)
    80002b16:	6442                	ld	s0,16(sp)
    80002b18:	64a2                	ld	s1,8(sp)
    80002b1a:	6902                	ld	s2,0(sp)
    80002b1c:	6105                	addi	sp,sp,32
    80002b1e:	8082                	ret

0000000080002b20 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b20:	1101                	addi	sp,sp,-32
    80002b22:	ec06                	sd	ra,24(sp)
    80002b24:	e822                	sd	s0,16(sp)
    80002b26:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b28:	fec40593          	addi	a1,s0,-20
    80002b2c:	4501                	li	a0,0
    80002b2e:	00000097          	auipc	ra,0x0
    80002b32:	f12080e7          	jalr	-238(ra) # 80002a40 <argint>
    return -1;
    80002b36:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b38:	00054963          	bltz	a0,80002b4a <sys_exit+0x2a>
  exit(n);
    80002b3c:	fec42503          	lw	a0,-20(s0)
    80002b40:	fffff097          	auipc	ra,0xfffff
    80002b44:	76c080e7          	jalr	1900(ra) # 800022ac <exit>
  return 0;  // not reached
    80002b48:	4781                	li	a5,0
}
    80002b4a:	853e                	mv	a0,a5
    80002b4c:	60e2                	ld	ra,24(sp)
    80002b4e:	6442                	ld	s0,16(sp)
    80002b50:	6105                	addi	sp,sp,32
    80002b52:	8082                	ret

0000000080002b54 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b54:	1141                	addi	sp,sp,-16
    80002b56:	e406                	sd	ra,8(sp)
    80002b58:	e022                	sd	s0,0(sp)
    80002b5a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	e38080e7          	jalr	-456(ra) # 80001994 <myproc>
}
    80002b64:	5908                	lw	a0,48(a0)
    80002b66:	60a2                	ld	ra,8(sp)
    80002b68:	6402                	ld	s0,0(sp)
    80002b6a:	0141                	addi	sp,sp,16
    80002b6c:	8082                	ret

0000000080002b6e <sys_fork>:

uint64
sys_fork(void)
{
    80002b6e:	1141                	addi	sp,sp,-16
    80002b70:	e406                	sd	ra,8(sp)
    80002b72:	e022                	sd	s0,0(sp)
    80002b74:	0800                	addi	s0,sp,16
  return fork();
    80002b76:	fffff097          	auipc	ra,0xfffff
    80002b7a:	1ec080e7          	jalr	492(ra) # 80001d62 <fork>
}
    80002b7e:	60a2                	ld	ra,8(sp)
    80002b80:	6402                	ld	s0,0(sp)
    80002b82:	0141                	addi	sp,sp,16
    80002b84:	8082                	ret

0000000080002b86 <sys_wait>:

uint64
sys_wait(void)
{
    80002b86:	1101                	addi	sp,sp,-32
    80002b88:	ec06                	sd	ra,24(sp)
    80002b8a:	e822                	sd	s0,16(sp)
    80002b8c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002b8e:	fe840593          	addi	a1,s0,-24
    80002b92:	4501                	li	a0,0
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	ece080e7          	jalr	-306(ra) # 80002a62 <argaddr>
    80002b9c:	87aa                	mv	a5,a0
    return -1;
    80002b9e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ba0:	0007c863          	bltz	a5,80002bb0 <sys_wait+0x2a>
  return wait(p);
    80002ba4:	fe843503          	ld	a0,-24(s0)
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	50c080e7          	jalr	1292(ra) # 800020b4 <wait>
}
    80002bb0:	60e2                	ld	ra,24(sp)
    80002bb2:	6442                	ld	s0,16(sp)
    80002bb4:	6105                	addi	sp,sp,32
    80002bb6:	8082                	ret

0000000080002bb8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002bb8:	7179                	addi	sp,sp,-48
    80002bba:	f406                	sd	ra,40(sp)
    80002bbc:	f022                	sd	s0,32(sp)
    80002bbe:	ec26                	sd	s1,24(sp)
    80002bc0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002bc2:	fdc40593          	addi	a1,s0,-36
    80002bc6:	4501                	li	a0,0
    80002bc8:	00000097          	auipc	ra,0x0
    80002bcc:	e78080e7          	jalr	-392(ra) # 80002a40 <argint>
    80002bd0:	87aa                	mv	a5,a0
    return -1;
    80002bd2:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002bd4:	0207c063          	bltz	a5,80002bf4 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002bd8:	fffff097          	auipc	ra,0xfffff
    80002bdc:	dbc080e7          	jalr	-580(ra) # 80001994 <myproc>
    80002be0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002be2:	fdc42503          	lw	a0,-36(s0)
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	108080e7          	jalr	264(ra) # 80001cee <growproc>
    80002bee:	00054863          	bltz	a0,80002bfe <sys_sbrk+0x46>
    return -1;
  return addr;
    80002bf2:	8526                	mv	a0,s1
}
    80002bf4:	70a2                	ld	ra,40(sp)
    80002bf6:	7402                	ld	s0,32(sp)
    80002bf8:	64e2                	ld	s1,24(sp)
    80002bfa:	6145                	addi	sp,sp,48
    80002bfc:	8082                	ret
    return -1;
    80002bfe:	557d                	li	a0,-1
    80002c00:	bfd5                	j	80002bf4 <sys_sbrk+0x3c>

0000000080002c02 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c02:	7139                	addi	sp,sp,-64
    80002c04:	fc06                	sd	ra,56(sp)
    80002c06:	f822                	sd	s0,48(sp)
    80002c08:	f426                	sd	s1,40(sp)
    80002c0a:	f04a                	sd	s2,32(sp)
    80002c0c:	ec4e                	sd	s3,24(sp)
    80002c0e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c10:	fcc40593          	addi	a1,s0,-52
    80002c14:	4501                	li	a0,0
    80002c16:	00000097          	auipc	ra,0x0
    80002c1a:	e2a080e7          	jalr	-470(ra) # 80002a40 <argint>
    return -1;
    80002c1e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c20:	06054563          	bltz	a0,80002c8a <sys_sleep+0x88>
  acquire(&tickslock);
    80002c24:	00014517          	auipc	a0,0x14
    80002c28:	4ac50513          	addi	a0,a0,1196 # 800170d0 <tickslock>
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	faa080e7          	jalr	-86(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002c34:	00006917          	auipc	s2,0x6
    80002c38:	3fc92903          	lw	s2,1020(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c3c:	fcc42783          	lw	a5,-52(s0)
    80002c40:	cf85                	beqz	a5,80002c78 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c42:	00014997          	auipc	s3,0x14
    80002c46:	48e98993          	addi	s3,s3,1166 # 800170d0 <tickslock>
    80002c4a:	00006497          	auipc	s1,0x6
    80002c4e:	3e648493          	addi	s1,s1,998 # 80009030 <ticks>
    if(myproc()->killed){
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	d42080e7          	jalr	-702(ra) # 80001994 <myproc>
    80002c5a:	551c                	lw	a5,40(a0)
    80002c5c:	ef9d                	bnez	a5,80002c9a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c5e:	85ce                	mv	a1,s3
    80002c60:	8526                	mv	a0,s1
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	3ee080e7          	jalr	1006(ra) # 80002050 <sleep>
  while(ticks - ticks0 < n){
    80002c6a:	409c                	lw	a5,0(s1)
    80002c6c:	412787bb          	subw	a5,a5,s2
    80002c70:	fcc42703          	lw	a4,-52(s0)
    80002c74:	fce7efe3          	bltu	a5,a4,80002c52 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002c78:	00014517          	auipc	a0,0x14
    80002c7c:	45850513          	addi	a0,a0,1112 # 800170d0 <tickslock>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	00a080e7          	jalr	10(ra) # 80000c8a <release>
  return 0;
    80002c88:	4781                	li	a5,0
}
    80002c8a:	853e                	mv	a0,a5
    80002c8c:	70e2                	ld	ra,56(sp)
    80002c8e:	7442                	ld	s0,48(sp)
    80002c90:	74a2                	ld	s1,40(sp)
    80002c92:	7902                	ld	s2,32(sp)
    80002c94:	69e2                	ld	s3,24(sp)
    80002c96:	6121                	addi	sp,sp,64
    80002c98:	8082                	ret
      release(&tickslock);
    80002c9a:	00014517          	auipc	a0,0x14
    80002c9e:	43650513          	addi	a0,a0,1078 # 800170d0 <tickslock>
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	fe8080e7          	jalr	-24(ra) # 80000c8a <release>
      return -1;
    80002caa:	57fd                	li	a5,-1
    80002cac:	bff9                	j	80002c8a <sys_sleep+0x88>

0000000080002cae <sys_kill>:

uint64
sys_kill(void)
{
    80002cae:	1101                	addi	sp,sp,-32
    80002cb0:	ec06                	sd	ra,24(sp)
    80002cb2:	e822                	sd	s0,16(sp)
    80002cb4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002cb6:	fec40593          	addi	a1,s0,-20
    80002cba:	4501                	li	a0,0
    80002cbc:	00000097          	auipc	ra,0x0
    80002cc0:	d84080e7          	jalr	-636(ra) # 80002a40 <argint>
    80002cc4:	87aa                	mv	a5,a0
    return -1;
    80002cc6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002cc8:	0007c863          	bltz	a5,80002cd8 <sys_kill+0x2a>
  return kill(pid);
    80002ccc:	fec42503          	lw	a0,-20(s0)
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	6b2080e7          	jalr	1714(ra) # 80002382 <kill>
}
    80002cd8:	60e2                	ld	ra,24(sp)
    80002cda:	6442                	ld	s0,16(sp)
    80002cdc:	6105                	addi	sp,sp,32
    80002cde:	8082                	ret

0000000080002ce0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ce0:	1101                	addi	sp,sp,-32
    80002ce2:	ec06                	sd	ra,24(sp)
    80002ce4:	e822                	sd	s0,16(sp)
    80002ce6:	e426                	sd	s1,8(sp)
    80002ce8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002cea:	00014517          	auipc	a0,0x14
    80002cee:	3e650513          	addi	a0,a0,998 # 800170d0 <tickslock>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	ee4080e7          	jalr	-284(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002cfa:	00006497          	auipc	s1,0x6
    80002cfe:	3364a483          	lw	s1,822(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d02:	00014517          	auipc	a0,0x14
    80002d06:	3ce50513          	addi	a0,a0,974 # 800170d0 <tickslock>
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	f80080e7          	jalr	-128(ra) # 80000c8a <release>
  return xticks;
}
    80002d12:	02049513          	slli	a0,s1,0x20
    80002d16:	9101                	srli	a0,a0,0x20
    80002d18:	60e2                	ld	ra,24(sp)
    80002d1a:	6442                	ld	s0,16(sp)
    80002d1c:	64a2                	ld	s1,8(sp)
    80002d1e:	6105                	addi	sp,sp,32
    80002d20:	8082                	ret

0000000080002d22 <sys_time>:

//return time
uint64
sys_time(void)
{
    80002d22:	1101                	addi	sp,sp,-32
    80002d24:	ec06                	sd	ra,24(sp)
    80002d26:	e822                	sd	s0,16(sp)
    80002d28:	e426                	sd	s1,8(sp)
    80002d2a:	1000                	addi	s0,sp,32
  uint tticks;

  acquire(&tickslock);
    80002d2c:	00014517          	auipc	a0,0x14
    80002d30:	3a450513          	addi	a0,a0,932 # 800170d0 <tickslock>
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	ea2080e7          	jalr	-350(ra) # 80000bd6 <acquire>
  tticks = ticks;
    80002d3c:	00006497          	auipc	s1,0x6
    80002d40:	2f44a483          	lw	s1,756(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d44:	00014517          	auipc	a0,0x14
    80002d48:	38c50513          	addi	a0,a0,908 # 800170d0 <tickslock>
    80002d4c:	ffffe097          	auipc	ra,0xffffe
    80002d50:	f3e080e7          	jalr	-194(ra) # 80000c8a <release>
  return tticks;
    80002d54:	02049513          	slli	a0,s1,0x20
    80002d58:	9101                	srli	a0,a0,0x20
    80002d5a:	60e2                	ld	ra,24(sp)
    80002d5c:	6442                	ld	s0,16(sp)
    80002d5e:	64a2                	ld	s1,8(sp)
    80002d60:	6105                	addi	sp,sp,32
    80002d62:	8082                	ret

0000000080002d64 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d64:	7179                	addi	sp,sp,-48
    80002d66:	f406                	sd	ra,40(sp)
    80002d68:	f022                	sd	s0,32(sp)
    80002d6a:	ec26                	sd	s1,24(sp)
    80002d6c:	e84a                	sd	s2,16(sp)
    80002d6e:	e44e                	sd	s3,8(sp)
    80002d70:	e052                	sd	s4,0(sp)
    80002d72:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d74:	00005597          	auipc	a1,0x5
    80002d78:	77458593          	addi	a1,a1,1908 # 800084e8 <syscalls+0xb8>
    80002d7c:	00014517          	auipc	a0,0x14
    80002d80:	36c50513          	addi	a0,a0,876 # 800170e8 <bcache>
    80002d84:	ffffe097          	auipc	ra,0xffffe
    80002d88:	dc2080e7          	jalr	-574(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d8c:	0001c797          	auipc	a5,0x1c
    80002d90:	35c78793          	addi	a5,a5,860 # 8001f0e8 <bcache+0x8000>
    80002d94:	0001c717          	auipc	a4,0x1c
    80002d98:	5bc70713          	addi	a4,a4,1468 # 8001f350 <bcache+0x8268>
    80002d9c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002da0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002da4:	00014497          	auipc	s1,0x14
    80002da8:	35c48493          	addi	s1,s1,860 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002dac:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002dae:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002db0:	00005a17          	auipc	s4,0x5
    80002db4:	740a0a13          	addi	s4,s4,1856 # 800084f0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002db8:	2b893783          	ld	a5,696(s2)
    80002dbc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002dbe:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002dc2:	85d2                	mv	a1,s4
    80002dc4:	01048513          	addi	a0,s1,16
    80002dc8:	00001097          	auipc	ra,0x1
    80002dcc:	4bc080e7          	jalr	1212(ra) # 80004284 <initsleeplock>
    bcache.head.next->prev = b;
    80002dd0:	2b893783          	ld	a5,696(s2)
    80002dd4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002dd6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dda:	45848493          	addi	s1,s1,1112
    80002dde:	fd349de3          	bne	s1,s3,80002db8 <binit+0x54>
  }
}
    80002de2:	70a2                	ld	ra,40(sp)
    80002de4:	7402                	ld	s0,32(sp)
    80002de6:	64e2                	ld	s1,24(sp)
    80002de8:	6942                	ld	s2,16(sp)
    80002dea:	69a2                	ld	s3,8(sp)
    80002dec:	6a02                	ld	s4,0(sp)
    80002dee:	6145                	addi	sp,sp,48
    80002df0:	8082                	ret

0000000080002df2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002df2:	7179                	addi	sp,sp,-48
    80002df4:	f406                	sd	ra,40(sp)
    80002df6:	f022                	sd	s0,32(sp)
    80002df8:	ec26                	sd	s1,24(sp)
    80002dfa:	e84a                	sd	s2,16(sp)
    80002dfc:	e44e                	sd	s3,8(sp)
    80002dfe:	1800                	addi	s0,sp,48
    80002e00:	89aa                	mv	s3,a0
    80002e02:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e04:	00014517          	auipc	a0,0x14
    80002e08:	2e450513          	addi	a0,a0,740 # 800170e8 <bcache>
    80002e0c:	ffffe097          	auipc	ra,0xffffe
    80002e10:	dca080e7          	jalr	-566(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e14:	0001c497          	auipc	s1,0x1c
    80002e18:	58c4b483          	ld	s1,1420(s1) # 8001f3a0 <bcache+0x82b8>
    80002e1c:	0001c797          	auipc	a5,0x1c
    80002e20:	53478793          	addi	a5,a5,1332 # 8001f350 <bcache+0x8268>
    80002e24:	02f48f63          	beq	s1,a5,80002e62 <bread+0x70>
    80002e28:	873e                	mv	a4,a5
    80002e2a:	a021                	j	80002e32 <bread+0x40>
    80002e2c:	68a4                	ld	s1,80(s1)
    80002e2e:	02e48a63          	beq	s1,a4,80002e62 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e32:	449c                	lw	a5,8(s1)
    80002e34:	ff379ce3          	bne	a5,s3,80002e2c <bread+0x3a>
    80002e38:	44dc                	lw	a5,12(s1)
    80002e3a:	ff2799e3          	bne	a5,s2,80002e2c <bread+0x3a>
      b->refcnt++;
    80002e3e:	40bc                	lw	a5,64(s1)
    80002e40:	2785                	addiw	a5,a5,1
    80002e42:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e44:	00014517          	auipc	a0,0x14
    80002e48:	2a450513          	addi	a0,a0,676 # 800170e8 <bcache>
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	e3e080e7          	jalr	-450(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002e54:	01048513          	addi	a0,s1,16
    80002e58:	00001097          	auipc	ra,0x1
    80002e5c:	466080e7          	jalr	1126(ra) # 800042be <acquiresleep>
      return b;
    80002e60:	a8b9                	j	80002ebe <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e62:	0001c497          	auipc	s1,0x1c
    80002e66:	5364b483          	ld	s1,1334(s1) # 8001f398 <bcache+0x82b0>
    80002e6a:	0001c797          	auipc	a5,0x1c
    80002e6e:	4e678793          	addi	a5,a5,1254 # 8001f350 <bcache+0x8268>
    80002e72:	00f48863          	beq	s1,a5,80002e82 <bread+0x90>
    80002e76:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e78:	40bc                	lw	a5,64(s1)
    80002e7a:	cf81                	beqz	a5,80002e92 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e7c:	64a4                	ld	s1,72(s1)
    80002e7e:	fee49de3          	bne	s1,a4,80002e78 <bread+0x86>
  panic("bget: no buffers");
    80002e82:	00005517          	auipc	a0,0x5
    80002e86:	67650513          	addi	a0,a0,1654 # 800084f8 <syscalls+0xc8>
    80002e8a:	ffffd097          	auipc	ra,0xffffd
    80002e8e:	6a6080e7          	jalr	1702(ra) # 80000530 <panic>
      b->dev = dev;
    80002e92:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002e96:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002e9a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e9e:	4785                	li	a5,1
    80002ea0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002ea2:	00014517          	auipc	a0,0x14
    80002ea6:	24650513          	addi	a0,a0,582 # 800170e8 <bcache>
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	de0080e7          	jalr	-544(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002eb2:	01048513          	addi	a0,s1,16
    80002eb6:	00001097          	auipc	ra,0x1
    80002eba:	408080e7          	jalr	1032(ra) # 800042be <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002ebe:	409c                	lw	a5,0(s1)
    80002ec0:	cb89                	beqz	a5,80002ed2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ec2:	8526                	mv	a0,s1
    80002ec4:	70a2                	ld	ra,40(sp)
    80002ec6:	7402                	ld	s0,32(sp)
    80002ec8:	64e2                	ld	s1,24(sp)
    80002eca:	6942                	ld	s2,16(sp)
    80002ecc:	69a2                	ld	s3,8(sp)
    80002ece:	6145                	addi	sp,sp,48
    80002ed0:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ed2:	4581                	li	a1,0
    80002ed4:	8526                	mv	a0,s1
    80002ed6:	00003097          	auipc	ra,0x3
    80002eda:	f10080e7          	jalr	-240(ra) # 80005de6 <virtio_disk_rw>
    b->valid = 1;
    80002ede:	4785                	li	a5,1
    80002ee0:	c09c                	sw	a5,0(s1)
  return b;
    80002ee2:	b7c5                	j	80002ec2 <bread+0xd0>

0000000080002ee4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ee4:	1101                	addi	sp,sp,-32
    80002ee6:	ec06                	sd	ra,24(sp)
    80002ee8:	e822                	sd	s0,16(sp)
    80002eea:	e426                	sd	s1,8(sp)
    80002eec:	1000                	addi	s0,sp,32
    80002eee:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ef0:	0541                	addi	a0,a0,16
    80002ef2:	00001097          	auipc	ra,0x1
    80002ef6:	466080e7          	jalr	1126(ra) # 80004358 <holdingsleep>
    80002efa:	cd01                	beqz	a0,80002f12 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002efc:	4585                	li	a1,1
    80002efe:	8526                	mv	a0,s1
    80002f00:	00003097          	auipc	ra,0x3
    80002f04:	ee6080e7          	jalr	-282(ra) # 80005de6 <virtio_disk_rw>
}
    80002f08:	60e2                	ld	ra,24(sp)
    80002f0a:	6442                	ld	s0,16(sp)
    80002f0c:	64a2                	ld	s1,8(sp)
    80002f0e:	6105                	addi	sp,sp,32
    80002f10:	8082                	ret
    panic("bwrite");
    80002f12:	00005517          	auipc	a0,0x5
    80002f16:	5fe50513          	addi	a0,a0,1534 # 80008510 <syscalls+0xe0>
    80002f1a:	ffffd097          	auipc	ra,0xffffd
    80002f1e:	616080e7          	jalr	1558(ra) # 80000530 <panic>

0000000080002f22 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f22:	1101                	addi	sp,sp,-32
    80002f24:	ec06                	sd	ra,24(sp)
    80002f26:	e822                	sd	s0,16(sp)
    80002f28:	e426                	sd	s1,8(sp)
    80002f2a:	e04a                	sd	s2,0(sp)
    80002f2c:	1000                	addi	s0,sp,32
    80002f2e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f30:	01050913          	addi	s2,a0,16
    80002f34:	854a                	mv	a0,s2
    80002f36:	00001097          	auipc	ra,0x1
    80002f3a:	422080e7          	jalr	1058(ra) # 80004358 <holdingsleep>
    80002f3e:	c92d                	beqz	a0,80002fb0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f40:	854a                	mv	a0,s2
    80002f42:	00001097          	auipc	ra,0x1
    80002f46:	3d2080e7          	jalr	978(ra) # 80004314 <releasesleep>

  acquire(&bcache.lock);
    80002f4a:	00014517          	auipc	a0,0x14
    80002f4e:	19e50513          	addi	a0,a0,414 # 800170e8 <bcache>
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	c84080e7          	jalr	-892(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80002f5a:	40bc                	lw	a5,64(s1)
    80002f5c:	37fd                	addiw	a5,a5,-1
    80002f5e:	0007871b          	sext.w	a4,a5
    80002f62:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f64:	eb05                	bnez	a4,80002f94 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f66:	68bc                	ld	a5,80(s1)
    80002f68:	64b8                	ld	a4,72(s1)
    80002f6a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f6c:	64bc                	ld	a5,72(s1)
    80002f6e:	68b8                	ld	a4,80(s1)
    80002f70:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f72:	0001c797          	auipc	a5,0x1c
    80002f76:	17678793          	addi	a5,a5,374 # 8001f0e8 <bcache+0x8000>
    80002f7a:	2b87b703          	ld	a4,696(a5)
    80002f7e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f80:	0001c717          	auipc	a4,0x1c
    80002f84:	3d070713          	addi	a4,a4,976 # 8001f350 <bcache+0x8268>
    80002f88:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f8a:	2b87b703          	ld	a4,696(a5)
    80002f8e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f90:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f94:	00014517          	auipc	a0,0x14
    80002f98:	15450513          	addi	a0,a0,340 # 800170e8 <bcache>
    80002f9c:	ffffe097          	auipc	ra,0xffffe
    80002fa0:	cee080e7          	jalr	-786(ra) # 80000c8a <release>
}
    80002fa4:	60e2                	ld	ra,24(sp)
    80002fa6:	6442                	ld	s0,16(sp)
    80002fa8:	64a2                	ld	s1,8(sp)
    80002faa:	6902                	ld	s2,0(sp)
    80002fac:	6105                	addi	sp,sp,32
    80002fae:	8082                	ret
    panic("brelse");
    80002fb0:	00005517          	auipc	a0,0x5
    80002fb4:	56850513          	addi	a0,a0,1384 # 80008518 <syscalls+0xe8>
    80002fb8:	ffffd097          	auipc	ra,0xffffd
    80002fbc:	578080e7          	jalr	1400(ra) # 80000530 <panic>

0000000080002fc0 <bpin>:

void
bpin(struct buf *b) {
    80002fc0:	1101                	addi	sp,sp,-32
    80002fc2:	ec06                	sd	ra,24(sp)
    80002fc4:	e822                	sd	s0,16(sp)
    80002fc6:	e426                	sd	s1,8(sp)
    80002fc8:	1000                	addi	s0,sp,32
    80002fca:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fcc:	00014517          	auipc	a0,0x14
    80002fd0:	11c50513          	addi	a0,a0,284 # 800170e8 <bcache>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	c02080e7          	jalr	-1022(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80002fdc:	40bc                	lw	a5,64(s1)
    80002fde:	2785                	addiw	a5,a5,1
    80002fe0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fe2:	00014517          	auipc	a0,0x14
    80002fe6:	10650513          	addi	a0,a0,262 # 800170e8 <bcache>
    80002fea:	ffffe097          	auipc	ra,0xffffe
    80002fee:	ca0080e7          	jalr	-864(ra) # 80000c8a <release>
}
    80002ff2:	60e2                	ld	ra,24(sp)
    80002ff4:	6442                	ld	s0,16(sp)
    80002ff6:	64a2                	ld	s1,8(sp)
    80002ff8:	6105                	addi	sp,sp,32
    80002ffa:	8082                	ret

0000000080002ffc <bunpin>:

void
bunpin(struct buf *b) {
    80002ffc:	1101                	addi	sp,sp,-32
    80002ffe:	ec06                	sd	ra,24(sp)
    80003000:	e822                	sd	s0,16(sp)
    80003002:	e426                	sd	s1,8(sp)
    80003004:	1000                	addi	s0,sp,32
    80003006:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003008:	00014517          	auipc	a0,0x14
    8000300c:	0e050513          	addi	a0,a0,224 # 800170e8 <bcache>
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	bc6080e7          	jalr	-1082(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003018:	40bc                	lw	a5,64(s1)
    8000301a:	37fd                	addiw	a5,a5,-1
    8000301c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000301e:	00014517          	auipc	a0,0x14
    80003022:	0ca50513          	addi	a0,a0,202 # 800170e8 <bcache>
    80003026:	ffffe097          	auipc	ra,0xffffe
    8000302a:	c64080e7          	jalr	-924(ra) # 80000c8a <release>
}
    8000302e:	60e2                	ld	ra,24(sp)
    80003030:	6442                	ld	s0,16(sp)
    80003032:	64a2                	ld	s1,8(sp)
    80003034:	6105                	addi	sp,sp,32
    80003036:	8082                	ret

0000000080003038 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003038:	1101                	addi	sp,sp,-32
    8000303a:	ec06                	sd	ra,24(sp)
    8000303c:	e822                	sd	s0,16(sp)
    8000303e:	e426                	sd	s1,8(sp)
    80003040:	e04a                	sd	s2,0(sp)
    80003042:	1000                	addi	s0,sp,32
    80003044:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003046:	00d5d59b          	srliw	a1,a1,0xd
    8000304a:	0001c797          	auipc	a5,0x1c
    8000304e:	77a7a783          	lw	a5,1914(a5) # 8001f7c4 <sb+0x1c>
    80003052:	9dbd                	addw	a1,a1,a5
    80003054:	00000097          	auipc	ra,0x0
    80003058:	d9e080e7          	jalr	-610(ra) # 80002df2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000305c:	0074f713          	andi	a4,s1,7
    80003060:	4785                	li	a5,1
    80003062:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003066:	14ce                	slli	s1,s1,0x33
    80003068:	90d9                	srli	s1,s1,0x36
    8000306a:	00950733          	add	a4,a0,s1
    8000306e:	05874703          	lbu	a4,88(a4)
    80003072:	00e7f6b3          	and	a3,a5,a4
    80003076:	c69d                	beqz	a3,800030a4 <bfree+0x6c>
    80003078:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000307a:	94aa                	add	s1,s1,a0
    8000307c:	fff7c793          	not	a5,a5
    80003080:	8ff9                	and	a5,a5,a4
    80003082:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003086:	00001097          	auipc	ra,0x1
    8000308a:	118080e7          	jalr	280(ra) # 8000419e <log_write>
  brelse(bp);
    8000308e:	854a                	mv	a0,s2
    80003090:	00000097          	auipc	ra,0x0
    80003094:	e92080e7          	jalr	-366(ra) # 80002f22 <brelse>
}
    80003098:	60e2                	ld	ra,24(sp)
    8000309a:	6442                	ld	s0,16(sp)
    8000309c:	64a2                	ld	s1,8(sp)
    8000309e:	6902                	ld	s2,0(sp)
    800030a0:	6105                	addi	sp,sp,32
    800030a2:	8082                	ret
    panic("freeing free block");
    800030a4:	00005517          	auipc	a0,0x5
    800030a8:	47c50513          	addi	a0,a0,1148 # 80008520 <syscalls+0xf0>
    800030ac:	ffffd097          	auipc	ra,0xffffd
    800030b0:	484080e7          	jalr	1156(ra) # 80000530 <panic>

00000000800030b4 <balloc>:
{
    800030b4:	711d                	addi	sp,sp,-96
    800030b6:	ec86                	sd	ra,88(sp)
    800030b8:	e8a2                	sd	s0,80(sp)
    800030ba:	e4a6                	sd	s1,72(sp)
    800030bc:	e0ca                	sd	s2,64(sp)
    800030be:	fc4e                	sd	s3,56(sp)
    800030c0:	f852                	sd	s4,48(sp)
    800030c2:	f456                	sd	s5,40(sp)
    800030c4:	f05a                	sd	s6,32(sp)
    800030c6:	ec5e                	sd	s7,24(sp)
    800030c8:	e862                	sd	s8,16(sp)
    800030ca:	e466                	sd	s9,8(sp)
    800030cc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030ce:	0001c797          	auipc	a5,0x1c
    800030d2:	6de7a783          	lw	a5,1758(a5) # 8001f7ac <sb+0x4>
    800030d6:	cbd1                	beqz	a5,8000316a <balloc+0xb6>
    800030d8:	8baa                	mv	s7,a0
    800030da:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030dc:	0001cb17          	auipc	s6,0x1c
    800030e0:	6ccb0b13          	addi	s6,s6,1740 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030e4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030e6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030e8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030ea:	6c89                	lui	s9,0x2
    800030ec:	a831                	j	80003108 <balloc+0x54>
    brelse(bp);
    800030ee:	854a                	mv	a0,s2
    800030f0:	00000097          	auipc	ra,0x0
    800030f4:	e32080e7          	jalr	-462(ra) # 80002f22 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030f8:	015c87bb          	addw	a5,s9,s5
    800030fc:	00078a9b          	sext.w	s5,a5
    80003100:	004b2703          	lw	a4,4(s6)
    80003104:	06eaf363          	bgeu	s5,a4,8000316a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003108:	41fad79b          	sraiw	a5,s5,0x1f
    8000310c:	0137d79b          	srliw	a5,a5,0x13
    80003110:	015787bb          	addw	a5,a5,s5
    80003114:	40d7d79b          	sraiw	a5,a5,0xd
    80003118:	01cb2583          	lw	a1,28(s6)
    8000311c:	9dbd                	addw	a1,a1,a5
    8000311e:	855e                	mv	a0,s7
    80003120:	00000097          	auipc	ra,0x0
    80003124:	cd2080e7          	jalr	-814(ra) # 80002df2 <bread>
    80003128:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000312a:	004b2503          	lw	a0,4(s6)
    8000312e:	000a849b          	sext.w	s1,s5
    80003132:	8662                	mv	a2,s8
    80003134:	faa4fde3          	bgeu	s1,a0,800030ee <balloc+0x3a>
      m = 1 << (bi % 8);
    80003138:	41f6579b          	sraiw	a5,a2,0x1f
    8000313c:	01d7d69b          	srliw	a3,a5,0x1d
    80003140:	00c6873b          	addw	a4,a3,a2
    80003144:	00777793          	andi	a5,a4,7
    80003148:	9f95                	subw	a5,a5,a3
    8000314a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000314e:	4037571b          	sraiw	a4,a4,0x3
    80003152:	00e906b3          	add	a3,s2,a4
    80003156:	0586c683          	lbu	a3,88(a3)
    8000315a:	00d7f5b3          	and	a1,a5,a3
    8000315e:	cd91                	beqz	a1,8000317a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003160:	2605                	addiw	a2,a2,1
    80003162:	2485                	addiw	s1,s1,1
    80003164:	fd4618e3          	bne	a2,s4,80003134 <balloc+0x80>
    80003168:	b759                	j	800030ee <balloc+0x3a>
  panic("balloc: out of blocks");
    8000316a:	00005517          	auipc	a0,0x5
    8000316e:	3ce50513          	addi	a0,a0,974 # 80008538 <syscalls+0x108>
    80003172:	ffffd097          	auipc	ra,0xffffd
    80003176:	3be080e7          	jalr	958(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000317a:	974a                	add	a4,a4,s2
    8000317c:	8fd5                	or	a5,a5,a3
    8000317e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003182:	854a                	mv	a0,s2
    80003184:	00001097          	auipc	ra,0x1
    80003188:	01a080e7          	jalr	26(ra) # 8000419e <log_write>
        brelse(bp);
    8000318c:	854a                	mv	a0,s2
    8000318e:	00000097          	auipc	ra,0x0
    80003192:	d94080e7          	jalr	-620(ra) # 80002f22 <brelse>
  bp = bread(dev, bno);
    80003196:	85a6                	mv	a1,s1
    80003198:	855e                	mv	a0,s7
    8000319a:	00000097          	auipc	ra,0x0
    8000319e:	c58080e7          	jalr	-936(ra) # 80002df2 <bread>
    800031a2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031a4:	40000613          	li	a2,1024
    800031a8:	4581                	li	a1,0
    800031aa:	05850513          	addi	a0,a0,88
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	b24080e7          	jalr	-1244(ra) # 80000cd2 <memset>
  log_write(bp);
    800031b6:	854a                	mv	a0,s2
    800031b8:	00001097          	auipc	ra,0x1
    800031bc:	fe6080e7          	jalr	-26(ra) # 8000419e <log_write>
  brelse(bp);
    800031c0:	854a                	mv	a0,s2
    800031c2:	00000097          	auipc	ra,0x0
    800031c6:	d60080e7          	jalr	-672(ra) # 80002f22 <brelse>
}
    800031ca:	8526                	mv	a0,s1
    800031cc:	60e6                	ld	ra,88(sp)
    800031ce:	6446                	ld	s0,80(sp)
    800031d0:	64a6                	ld	s1,72(sp)
    800031d2:	6906                	ld	s2,64(sp)
    800031d4:	79e2                	ld	s3,56(sp)
    800031d6:	7a42                	ld	s4,48(sp)
    800031d8:	7aa2                	ld	s5,40(sp)
    800031da:	7b02                	ld	s6,32(sp)
    800031dc:	6be2                	ld	s7,24(sp)
    800031de:	6c42                	ld	s8,16(sp)
    800031e0:	6ca2                	ld	s9,8(sp)
    800031e2:	6125                	addi	sp,sp,96
    800031e4:	8082                	ret

00000000800031e6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031e6:	7179                	addi	sp,sp,-48
    800031e8:	f406                	sd	ra,40(sp)
    800031ea:	f022                	sd	s0,32(sp)
    800031ec:	ec26                	sd	s1,24(sp)
    800031ee:	e84a                	sd	s2,16(sp)
    800031f0:	e44e                	sd	s3,8(sp)
    800031f2:	e052                	sd	s4,0(sp)
    800031f4:	1800                	addi	s0,sp,48
    800031f6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031f8:	47ad                	li	a5,11
    800031fa:	04b7fe63          	bgeu	a5,a1,80003256 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031fe:	ff45849b          	addiw	s1,a1,-12
    80003202:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003206:	0ff00793          	li	a5,255
    8000320a:	0ae7e363          	bltu	a5,a4,800032b0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000320e:	08052583          	lw	a1,128(a0)
    80003212:	c5ad                	beqz	a1,8000327c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003214:	00092503          	lw	a0,0(s2)
    80003218:	00000097          	auipc	ra,0x0
    8000321c:	bda080e7          	jalr	-1062(ra) # 80002df2 <bread>
    80003220:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003222:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003226:	02049593          	slli	a1,s1,0x20
    8000322a:	9181                	srli	a1,a1,0x20
    8000322c:	058a                	slli	a1,a1,0x2
    8000322e:	00b784b3          	add	s1,a5,a1
    80003232:	0004a983          	lw	s3,0(s1)
    80003236:	04098d63          	beqz	s3,80003290 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000323a:	8552                	mv	a0,s4
    8000323c:	00000097          	auipc	ra,0x0
    80003240:	ce6080e7          	jalr	-794(ra) # 80002f22 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003244:	854e                	mv	a0,s3
    80003246:	70a2                	ld	ra,40(sp)
    80003248:	7402                	ld	s0,32(sp)
    8000324a:	64e2                	ld	s1,24(sp)
    8000324c:	6942                	ld	s2,16(sp)
    8000324e:	69a2                	ld	s3,8(sp)
    80003250:	6a02                	ld	s4,0(sp)
    80003252:	6145                	addi	sp,sp,48
    80003254:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003256:	02059493          	slli	s1,a1,0x20
    8000325a:	9081                	srli	s1,s1,0x20
    8000325c:	048a                	slli	s1,s1,0x2
    8000325e:	94aa                	add	s1,s1,a0
    80003260:	0504a983          	lw	s3,80(s1)
    80003264:	fe0990e3          	bnez	s3,80003244 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003268:	4108                	lw	a0,0(a0)
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	e4a080e7          	jalr	-438(ra) # 800030b4 <balloc>
    80003272:	0005099b          	sext.w	s3,a0
    80003276:	0534a823          	sw	s3,80(s1)
    8000327a:	b7e9                	j	80003244 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000327c:	4108                	lw	a0,0(a0)
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	e36080e7          	jalr	-458(ra) # 800030b4 <balloc>
    80003286:	0005059b          	sext.w	a1,a0
    8000328a:	08b92023          	sw	a1,128(s2)
    8000328e:	b759                	j	80003214 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003290:	00092503          	lw	a0,0(s2)
    80003294:	00000097          	auipc	ra,0x0
    80003298:	e20080e7          	jalr	-480(ra) # 800030b4 <balloc>
    8000329c:	0005099b          	sext.w	s3,a0
    800032a0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032a4:	8552                	mv	a0,s4
    800032a6:	00001097          	auipc	ra,0x1
    800032aa:	ef8080e7          	jalr	-264(ra) # 8000419e <log_write>
    800032ae:	b771                	j	8000323a <bmap+0x54>
  panic("bmap: out of range");
    800032b0:	00005517          	auipc	a0,0x5
    800032b4:	2a050513          	addi	a0,a0,672 # 80008550 <syscalls+0x120>
    800032b8:	ffffd097          	auipc	ra,0xffffd
    800032bc:	278080e7          	jalr	632(ra) # 80000530 <panic>

00000000800032c0 <iget>:
{
    800032c0:	7179                	addi	sp,sp,-48
    800032c2:	f406                	sd	ra,40(sp)
    800032c4:	f022                	sd	s0,32(sp)
    800032c6:	ec26                	sd	s1,24(sp)
    800032c8:	e84a                	sd	s2,16(sp)
    800032ca:	e44e                	sd	s3,8(sp)
    800032cc:	e052                	sd	s4,0(sp)
    800032ce:	1800                	addi	s0,sp,48
    800032d0:	89aa                	mv	s3,a0
    800032d2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800032d4:	0001c517          	auipc	a0,0x1c
    800032d8:	4f450513          	addi	a0,a0,1268 # 8001f7c8 <itable>
    800032dc:	ffffe097          	auipc	ra,0xffffe
    800032e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  empty = 0;
    800032e4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032e6:	0001c497          	auipc	s1,0x1c
    800032ea:	4fa48493          	addi	s1,s1,1274 # 8001f7e0 <itable+0x18>
    800032ee:	0001e697          	auipc	a3,0x1e
    800032f2:	f8268693          	addi	a3,a3,-126 # 80021270 <log>
    800032f6:	a039                	j	80003304 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032f8:	02090b63          	beqz	s2,8000332e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032fc:	08848493          	addi	s1,s1,136
    80003300:	02d48a63          	beq	s1,a3,80003334 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003304:	449c                	lw	a5,8(s1)
    80003306:	fef059e3          	blez	a5,800032f8 <iget+0x38>
    8000330a:	4098                	lw	a4,0(s1)
    8000330c:	ff3716e3          	bne	a4,s3,800032f8 <iget+0x38>
    80003310:	40d8                	lw	a4,4(s1)
    80003312:	ff4713e3          	bne	a4,s4,800032f8 <iget+0x38>
      ip->ref++;
    80003316:	2785                	addiw	a5,a5,1
    80003318:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000331a:	0001c517          	auipc	a0,0x1c
    8000331e:	4ae50513          	addi	a0,a0,1198 # 8001f7c8 <itable>
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	968080e7          	jalr	-1688(ra) # 80000c8a <release>
      return ip;
    8000332a:	8926                	mv	s2,s1
    8000332c:	a03d                	j	8000335a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000332e:	f7f9                	bnez	a5,800032fc <iget+0x3c>
    80003330:	8926                	mv	s2,s1
    80003332:	b7e9                	j	800032fc <iget+0x3c>
  if(empty == 0)
    80003334:	02090c63          	beqz	s2,8000336c <iget+0xac>
  ip->dev = dev;
    80003338:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000333c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003340:	4785                	li	a5,1
    80003342:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003346:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000334a:	0001c517          	auipc	a0,0x1c
    8000334e:	47e50513          	addi	a0,a0,1150 # 8001f7c8 <itable>
    80003352:	ffffe097          	auipc	ra,0xffffe
    80003356:	938080e7          	jalr	-1736(ra) # 80000c8a <release>
}
    8000335a:	854a                	mv	a0,s2
    8000335c:	70a2                	ld	ra,40(sp)
    8000335e:	7402                	ld	s0,32(sp)
    80003360:	64e2                	ld	s1,24(sp)
    80003362:	6942                	ld	s2,16(sp)
    80003364:	69a2                	ld	s3,8(sp)
    80003366:	6a02                	ld	s4,0(sp)
    80003368:	6145                	addi	sp,sp,48
    8000336a:	8082                	ret
    panic("iget: no inodes");
    8000336c:	00005517          	auipc	a0,0x5
    80003370:	1fc50513          	addi	a0,a0,508 # 80008568 <syscalls+0x138>
    80003374:	ffffd097          	auipc	ra,0xffffd
    80003378:	1bc080e7          	jalr	444(ra) # 80000530 <panic>

000000008000337c <fsinit>:
fsinit(int dev) {
    8000337c:	7179                	addi	sp,sp,-48
    8000337e:	f406                	sd	ra,40(sp)
    80003380:	f022                	sd	s0,32(sp)
    80003382:	ec26                	sd	s1,24(sp)
    80003384:	e84a                	sd	s2,16(sp)
    80003386:	e44e                	sd	s3,8(sp)
    80003388:	1800                	addi	s0,sp,48
    8000338a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000338c:	4585                	li	a1,1
    8000338e:	00000097          	auipc	ra,0x0
    80003392:	a64080e7          	jalr	-1436(ra) # 80002df2 <bread>
    80003396:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003398:	0001c997          	auipc	s3,0x1c
    8000339c:	41098993          	addi	s3,s3,1040 # 8001f7a8 <sb>
    800033a0:	02000613          	li	a2,32
    800033a4:	05850593          	addi	a1,a0,88
    800033a8:	854e                	mv	a0,s3
    800033aa:	ffffe097          	auipc	ra,0xffffe
    800033ae:	988080e7          	jalr	-1656(ra) # 80000d32 <memmove>
  brelse(bp);
    800033b2:	8526                	mv	a0,s1
    800033b4:	00000097          	auipc	ra,0x0
    800033b8:	b6e080e7          	jalr	-1170(ra) # 80002f22 <brelse>
  if(sb.magic != FSMAGIC)
    800033bc:	0009a703          	lw	a4,0(s3)
    800033c0:	102037b7          	lui	a5,0x10203
    800033c4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033c8:	02f71263          	bne	a4,a5,800033ec <fsinit+0x70>
  initlog(dev, &sb);
    800033cc:	0001c597          	auipc	a1,0x1c
    800033d0:	3dc58593          	addi	a1,a1,988 # 8001f7a8 <sb>
    800033d4:	854a                	mv	a0,s2
    800033d6:	00001097          	auipc	ra,0x1
    800033da:	b4c080e7          	jalr	-1204(ra) # 80003f22 <initlog>
}
    800033de:	70a2                	ld	ra,40(sp)
    800033e0:	7402                	ld	s0,32(sp)
    800033e2:	64e2                	ld	s1,24(sp)
    800033e4:	6942                	ld	s2,16(sp)
    800033e6:	69a2                	ld	s3,8(sp)
    800033e8:	6145                	addi	sp,sp,48
    800033ea:	8082                	ret
    panic("invalid file system");
    800033ec:	00005517          	auipc	a0,0x5
    800033f0:	18c50513          	addi	a0,a0,396 # 80008578 <syscalls+0x148>
    800033f4:	ffffd097          	auipc	ra,0xffffd
    800033f8:	13c080e7          	jalr	316(ra) # 80000530 <panic>

00000000800033fc <iinit>:
{
    800033fc:	7179                	addi	sp,sp,-48
    800033fe:	f406                	sd	ra,40(sp)
    80003400:	f022                	sd	s0,32(sp)
    80003402:	ec26                	sd	s1,24(sp)
    80003404:	e84a                	sd	s2,16(sp)
    80003406:	e44e                	sd	s3,8(sp)
    80003408:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000340a:	00005597          	auipc	a1,0x5
    8000340e:	18658593          	addi	a1,a1,390 # 80008590 <syscalls+0x160>
    80003412:	0001c517          	auipc	a0,0x1c
    80003416:	3b650513          	addi	a0,a0,950 # 8001f7c8 <itable>
    8000341a:	ffffd097          	auipc	ra,0xffffd
    8000341e:	72c080e7          	jalr	1836(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003422:	0001c497          	auipc	s1,0x1c
    80003426:	3ce48493          	addi	s1,s1,974 # 8001f7f0 <itable+0x28>
    8000342a:	0001e997          	auipc	s3,0x1e
    8000342e:	e5698993          	addi	s3,s3,-426 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003432:	00005917          	auipc	s2,0x5
    80003436:	16690913          	addi	s2,s2,358 # 80008598 <syscalls+0x168>
    8000343a:	85ca                	mv	a1,s2
    8000343c:	8526                	mv	a0,s1
    8000343e:	00001097          	auipc	ra,0x1
    80003442:	e46080e7          	jalr	-442(ra) # 80004284 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003446:	08848493          	addi	s1,s1,136
    8000344a:	ff3498e3          	bne	s1,s3,8000343a <iinit+0x3e>
}
    8000344e:	70a2                	ld	ra,40(sp)
    80003450:	7402                	ld	s0,32(sp)
    80003452:	64e2                	ld	s1,24(sp)
    80003454:	6942                	ld	s2,16(sp)
    80003456:	69a2                	ld	s3,8(sp)
    80003458:	6145                	addi	sp,sp,48
    8000345a:	8082                	ret

000000008000345c <ialloc>:
{
    8000345c:	715d                	addi	sp,sp,-80
    8000345e:	e486                	sd	ra,72(sp)
    80003460:	e0a2                	sd	s0,64(sp)
    80003462:	fc26                	sd	s1,56(sp)
    80003464:	f84a                	sd	s2,48(sp)
    80003466:	f44e                	sd	s3,40(sp)
    80003468:	f052                	sd	s4,32(sp)
    8000346a:	ec56                	sd	s5,24(sp)
    8000346c:	e85a                	sd	s6,16(sp)
    8000346e:	e45e                	sd	s7,8(sp)
    80003470:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003472:	0001c717          	auipc	a4,0x1c
    80003476:	34272703          	lw	a4,834(a4) # 8001f7b4 <sb+0xc>
    8000347a:	4785                	li	a5,1
    8000347c:	04e7fa63          	bgeu	a5,a4,800034d0 <ialloc+0x74>
    80003480:	8aaa                	mv	s5,a0
    80003482:	8bae                	mv	s7,a1
    80003484:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003486:	0001ca17          	auipc	s4,0x1c
    8000348a:	322a0a13          	addi	s4,s4,802 # 8001f7a8 <sb>
    8000348e:	00048b1b          	sext.w	s6,s1
    80003492:	0044d593          	srli	a1,s1,0x4
    80003496:	018a2783          	lw	a5,24(s4)
    8000349a:	9dbd                	addw	a1,a1,a5
    8000349c:	8556                	mv	a0,s5
    8000349e:	00000097          	auipc	ra,0x0
    800034a2:	954080e7          	jalr	-1708(ra) # 80002df2 <bread>
    800034a6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034a8:	05850993          	addi	s3,a0,88
    800034ac:	00f4f793          	andi	a5,s1,15
    800034b0:	079a                	slli	a5,a5,0x6
    800034b2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034b4:	00099783          	lh	a5,0(s3)
    800034b8:	c785                	beqz	a5,800034e0 <ialloc+0x84>
    brelse(bp);
    800034ba:	00000097          	auipc	ra,0x0
    800034be:	a68080e7          	jalr	-1432(ra) # 80002f22 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034c2:	0485                	addi	s1,s1,1
    800034c4:	00ca2703          	lw	a4,12(s4)
    800034c8:	0004879b          	sext.w	a5,s1
    800034cc:	fce7e1e3          	bltu	a5,a4,8000348e <ialloc+0x32>
  panic("ialloc: no inodes");
    800034d0:	00005517          	auipc	a0,0x5
    800034d4:	0d050513          	addi	a0,a0,208 # 800085a0 <syscalls+0x170>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	058080e7          	jalr	88(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    800034e0:	04000613          	li	a2,64
    800034e4:	4581                	li	a1,0
    800034e6:	854e                	mv	a0,s3
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	7ea080e7          	jalr	2026(ra) # 80000cd2 <memset>
      dip->type = type;
    800034f0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800034f4:	854a                	mv	a0,s2
    800034f6:	00001097          	auipc	ra,0x1
    800034fa:	ca8080e7          	jalr	-856(ra) # 8000419e <log_write>
      brelse(bp);
    800034fe:	854a                	mv	a0,s2
    80003500:	00000097          	auipc	ra,0x0
    80003504:	a22080e7          	jalr	-1502(ra) # 80002f22 <brelse>
      return iget(dev, inum);
    80003508:	85da                	mv	a1,s6
    8000350a:	8556                	mv	a0,s5
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	db4080e7          	jalr	-588(ra) # 800032c0 <iget>
}
    80003514:	60a6                	ld	ra,72(sp)
    80003516:	6406                	ld	s0,64(sp)
    80003518:	74e2                	ld	s1,56(sp)
    8000351a:	7942                	ld	s2,48(sp)
    8000351c:	79a2                	ld	s3,40(sp)
    8000351e:	7a02                	ld	s4,32(sp)
    80003520:	6ae2                	ld	s5,24(sp)
    80003522:	6b42                	ld	s6,16(sp)
    80003524:	6ba2                	ld	s7,8(sp)
    80003526:	6161                	addi	sp,sp,80
    80003528:	8082                	ret

000000008000352a <iupdate>:
{
    8000352a:	1101                	addi	sp,sp,-32
    8000352c:	ec06                	sd	ra,24(sp)
    8000352e:	e822                	sd	s0,16(sp)
    80003530:	e426                	sd	s1,8(sp)
    80003532:	e04a                	sd	s2,0(sp)
    80003534:	1000                	addi	s0,sp,32
    80003536:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003538:	415c                	lw	a5,4(a0)
    8000353a:	0047d79b          	srliw	a5,a5,0x4
    8000353e:	0001c597          	auipc	a1,0x1c
    80003542:	2825a583          	lw	a1,642(a1) # 8001f7c0 <sb+0x18>
    80003546:	9dbd                	addw	a1,a1,a5
    80003548:	4108                	lw	a0,0(a0)
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	8a8080e7          	jalr	-1880(ra) # 80002df2 <bread>
    80003552:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003554:	05850793          	addi	a5,a0,88
    80003558:	40c8                	lw	a0,4(s1)
    8000355a:	893d                	andi	a0,a0,15
    8000355c:	051a                	slli	a0,a0,0x6
    8000355e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003560:	04449703          	lh	a4,68(s1)
    80003564:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003568:	04649703          	lh	a4,70(s1)
    8000356c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003570:	04849703          	lh	a4,72(s1)
    80003574:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003578:	04a49703          	lh	a4,74(s1)
    8000357c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003580:	44f8                	lw	a4,76(s1)
    80003582:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003584:	03400613          	li	a2,52
    80003588:	05048593          	addi	a1,s1,80
    8000358c:	0531                	addi	a0,a0,12
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	7a4080e7          	jalr	1956(ra) # 80000d32 <memmove>
  log_write(bp);
    80003596:	854a                	mv	a0,s2
    80003598:	00001097          	auipc	ra,0x1
    8000359c:	c06080e7          	jalr	-1018(ra) # 8000419e <log_write>
  brelse(bp);
    800035a0:	854a                	mv	a0,s2
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	980080e7          	jalr	-1664(ra) # 80002f22 <brelse>
}
    800035aa:	60e2                	ld	ra,24(sp)
    800035ac:	6442                	ld	s0,16(sp)
    800035ae:	64a2                	ld	s1,8(sp)
    800035b0:	6902                	ld	s2,0(sp)
    800035b2:	6105                	addi	sp,sp,32
    800035b4:	8082                	ret

00000000800035b6 <idup>:
{
    800035b6:	1101                	addi	sp,sp,-32
    800035b8:	ec06                	sd	ra,24(sp)
    800035ba:	e822                	sd	s0,16(sp)
    800035bc:	e426                	sd	s1,8(sp)
    800035be:	1000                	addi	s0,sp,32
    800035c0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035c2:	0001c517          	auipc	a0,0x1c
    800035c6:	20650513          	addi	a0,a0,518 # 8001f7c8 <itable>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	60c080e7          	jalr	1548(ra) # 80000bd6 <acquire>
  ip->ref++;
    800035d2:	449c                	lw	a5,8(s1)
    800035d4:	2785                	addiw	a5,a5,1
    800035d6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800035d8:	0001c517          	auipc	a0,0x1c
    800035dc:	1f050513          	addi	a0,a0,496 # 8001f7c8 <itable>
    800035e0:	ffffd097          	auipc	ra,0xffffd
    800035e4:	6aa080e7          	jalr	1706(ra) # 80000c8a <release>
}
    800035e8:	8526                	mv	a0,s1
    800035ea:	60e2                	ld	ra,24(sp)
    800035ec:	6442                	ld	s0,16(sp)
    800035ee:	64a2                	ld	s1,8(sp)
    800035f0:	6105                	addi	sp,sp,32
    800035f2:	8082                	ret

00000000800035f4 <ilock>:
{
    800035f4:	1101                	addi	sp,sp,-32
    800035f6:	ec06                	sd	ra,24(sp)
    800035f8:	e822                	sd	s0,16(sp)
    800035fa:	e426                	sd	s1,8(sp)
    800035fc:	e04a                	sd	s2,0(sp)
    800035fe:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003600:	c115                	beqz	a0,80003624 <ilock+0x30>
    80003602:	84aa                	mv	s1,a0
    80003604:	451c                	lw	a5,8(a0)
    80003606:	00f05f63          	blez	a5,80003624 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000360a:	0541                	addi	a0,a0,16
    8000360c:	00001097          	auipc	ra,0x1
    80003610:	cb2080e7          	jalr	-846(ra) # 800042be <acquiresleep>
  if(ip->valid == 0){
    80003614:	40bc                	lw	a5,64(s1)
    80003616:	cf99                	beqz	a5,80003634 <ilock+0x40>
}
    80003618:	60e2                	ld	ra,24(sp)
    8000361a:	6442                	ld	s0,16(sp)
    8000361c:	64a2                	ld	s1,8(sp)
    8000361e:	6902                	ld	s2,0(sp)
    80003620:	6105                	addi	sp,sp,32
    80003622:	8082                	ret
    panic("ilock");
    80003624:	00005517          	auipc	a0,0x5
    80003628:	f9450513          	addi	a0,a0,-108 # 800085b8 <syscalls+0x188>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	f04080e7          	jalr	-252(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003634:	40dc                	lw	a5,4(s1)
    80003636:	0047d79b          	srliw	a5,a5,0x4
    8000363a:	0001c597          	auipc	a1,0x1c
    8000363e:	1865a583          	lw	a1,390(a1) # 8001f7c0 <sb+0x18>
    80003642:	9dbd                	addw	a1,a1,a5
    80003644:	4088                	lw	a0,0(s1)
    80003646:	fffff097          	auipc	ra,0xfffff
    8000364a:	7ac080e7          	jalr	1964(ra) # 80002df2 <bread>
    8000364e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003650:	05850593          	addi	a1,a0,88
    80003654:	40dc                	lw	a5,4(s1)
    80003656:	8bbd                	andi	a5,a5,15
    80003658:	079a                	slli	a5,a5,0x6
    8000365a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000365c:	00059783          	lh	a5,0(a1)
    80003660:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003664:	00259783          	lh	a5,2(a1)
    80003668:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000366c:	00459783          	lh	a5,4(a1)
    80003670:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003674:	00659783          	lh	a5,6(a1)
    80003678:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000367c:	459c                	lw	a5,8(a1)
    8000367e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003680:	03400613          	li	a2,52
    80003684:	05b1                	addi	a1,a1,12
    80003686:	05048513          	addi	a0,s1,80
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	6a8080e7          	jalr	1704(ra) # 80000d32 <memmove>
    brelse(bp);
    80003692:	854a                	mv	a0,s2
    80003694:	00000097          	auipc	ra,0x0
    80003698:	88e080e7          	jalr	-1906(ra) # 80002f22 <brelse>
    ip->valid = 1;
    8000369c:	4785                	li	a5,1
    8000369e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036a0:	04449783          	lh	a5,68(s1)
    800036a4:	fbb5                	bnez	a5,80003618 <ilock+0x24>
      panic("ilock: no type");
    800036a6:	00005517          	auipc	a0,0x5
    800036aa:	f1a50513          	addi	a0,a0,-230 # 800085c0 <syscalls+0x190>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	e82080e7          	jalr	-382(ra) # 80000530 <panic>

00000000800036b6 <iunlock>:
{
    800036b6:	1101                	addi	sp,sp,-32
    800036b8:	ec06                	sd	ra,24(sp)
    800036ba:	e822                	sd	s0,16(sp)
    800036bc:	e426                	sd	s1,8(sp)
    800036be:	e04a                	sd	s2,0(sp)
    800036c0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036c2:	c905                	beqz	a0,800036f2 <iunlock+0x3c>
    800036c4:	84aa                	mv	s1,a0
    800036c6:	01050913          	addi	s2,a0,16
    800036ca:	854a                	mv	a0,s2
    800036cc:	00001097          	auipc	ra,0x1
    800036d0:	c8c080e7          	jalr	-884(ra) # 80004358 <holdingsleep>
    800036d4:	cd19                	beqz	a0,800036f2 <iunlock+0x3c>
    800036d6:	449c                	lw	a5,8(s1)
    800036d8:	00f05d63          	blez	a5,800036f2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036dc:	854a                	mv	a0,s2
    800036de:	00001097          	auipc	ra,0x1
    800036e2:	c36080e7          	jalr	-970(ra) # 80004314 <releasesleep>
}
    800036e6:	60e2                	ld	ra,24(sp)
    800036e8:	6442                	ld	s0,16(sp)
    800036ea:	64a2                	ld	s1,8(sp)
    800036ec:	6902                	ld	s2,0(sp)
    800036ee:	6105                	addi	sp,sp,32
    800036f0:	8082                	ret
    panic("iunlock");
    800036f2:	00005517          	auipc	a0,0x5
    800036f6:	ede50513          	addi	a0,a0,-290 # 800085d0 <syscalls+0x1a0>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	e36080e7          	jalr	-458(ra) # 80000530 <panic>

0000000080003702 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003702:	7179                	addi	sp,sp,-48
    80003704:	f406                	sd	ra,40(sp)
    80003706:	f022                	sd	s0,32(sp)
    80003708:	ec26                	sd	s1,24(sp)
    8000370a:	e84a                	sd	s2,16(sp)
    8000370c:	e44e                	sd	s3,8(sp)
    8000370e:	e052                	sd	s4,0(sp)
    80003710:	1800                	addi	s0,sp,48
    80003712:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003714:	05050493          	addi	s1,a0,80
    80003718:	08050913          	addi	s2,a0,128
    8000371c:	a021                	j	80003724 <itrunc+0x22>
    8000371e:	0491                	addi	s1,s1,4
    80003720:	01248d63          	beq	s1,s2,8000373a <itrunc+0x38>
    if(ip->addrs[i]){
    80003724:	408c                	lw	a1,0(s1)
    80003726:	dde5                	beqz	a1,8000371e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003728:	0009a503          	lw	a0,0(s3)
    8000372c:	00000097          	auipc	ra,0x0
    80003730:	90c080e7          	jalr	-1780(ra) # 80003038 <bfree>
      ip->addrs[i] = 0;
    80003734:	0004a023          	sw	zero,0(s1)
    80003738:	b7dd                	j	8000371e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000373a:	0809a583          	lw	a1,128(s3)
    8000373e:	e185                	bnez	a1,8000375e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003740:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003744:	854e                	mv	a0,s3
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	de4080e7          	jalr	-540(ra) # 8000352a <iupdate>
}
    8000374e:	70a2                	ld	ra,40(sp)
    80003750:	7402                	ld	s0,32(sp)
    80003752:	64e2                	ld	s1,24(sp)
    80003754:	6942                	ld	s2,16(sp)
    80003756:	69a2                	ld	s3,8(sp)
    80003758:	6a02                	ld	s4,0(sp)
    8000375a:	6145                	addi	sp,sp,48
    8000375c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000375e:	0009a503          	lw	a0,0(s3)
    80003762:	fffff097          	auipc	ra,0xfffff
    80003766:	690080e7          	jalr	1680(ra) # 80002df2 <bread>
    8000376a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000376c:	05850493          	addi	s1,a0,88
    80003770:	45850913          	addi	s2,a0,1112
    80003774:	a811                	j	80003788 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003776:	0009a503          	lw	a0,0(s3)
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	8be080e7          	jalr	-1858(ra) # 80003038 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003782:	0491                	addi	s1,s1,4
    80003784:	01248563          	beq	s1,s2,8000378e <itrunc+0x8c>
      if(a[j])
    80003788:	408c                	lw	a1,0(s1)
    8000378a:	dde5                	beqz	a1,80003782 <itrunc+0x80>
    8000378c:	b7ed                	j	80003776 <itrunc+0x74>
    brelse(bp);
    8000378e:	8552                	mv	a0,s4
    80003790:	fffff097          	auipc	ra,0xfffff
    80003794:	792080e7          	jalr	1938(ra) # 80002f22 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003798:	0809a583          	lw	a1,128(s3)
    8000379c:	0009a503          	lw	a0,0(s3)
    800037a0:	00000097          	auipc	ra,0x0
    800037a4:	898080e7          	jalr	-1896(ra) # 80003038 <bfree>
    ip->addrs[NDIRECT] = 0;
    800037a8:	0809a023          	sw	zero,128(s3)
    800037ac:	bf51                	j	80003740 <itrunc+0x3e>

00000000800037ae <iput>:
{
    800037ae:	1101                	addi	sp,sp,-32
    800037b0:	ec06                	sd	ra,24(sp)
    800037b2:	e822                	sd	s0,16(sp)
    800037b4:	e426                	sd	s1,8(sp)
    800037b6:	e04a                	sd	s2,0(sp)
    800037b8:	1000                	addi	s0,sp,32
    800037ba:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037bc:	0001c517          	auipc	a0,0x1c
    800037c0:	00c50513          	addi	a0,a0,12 # 8001f7c8 <itable>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	412080e7          	jalr	1042(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037cc:	4498                	lw	a4,8(s1)
    800037ce:	4785                	li	a5,1
    800037d0:	02f70363          	beq	a4,a5,800037f6 <iput+0x48>
  ip->ref--;
    800037d4:	449c                	lw	a5,8(s1)
    800037d6:	37fd                	addiw	a5,a5,-1
    800037d8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037da:	0001c517          	auipc	a0,0x1c
    800037de:	fee50513          	addi	a0,a0,-18 # 8001f7c8 <itable>
    800037e2:	ffffd097          	auipc	ra,0xffffd
    800037e6:	4a8080e7          	jalr	1192(ra) # 80000c8a <release>
}
    800037ea:	60e2                	ld	ra,24(sp)
    800037ec:	6442                	ld	s0,16(sp)
    800037ee:	64a2                	ld	s1,8(sp)
    800037f0:	6902                	ld	s2,0(sp)
    800037f2:	6105                	addi	sp,sp,32
    800037f4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037f6:	40bc                	lw	a5,64(s1)
    800037f8:	dff1                	beqz	a5,800037d4 <iput+0x26>
    800037fa:	04a49783          	lh	a5,74(s1)
    800037fe:	fbf9                	bnez	a5,800037d4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003800:	01048913          	addi	s2,s1,16
    80003804:	854a                	mv	a0,s2
    80003806:	00001097          	auipc	ra,0x1
    8000380a:	ab8080e7          	jalr	-1352(ra) # 800042be <acquiresleep>
    release(&itable.lock);
    8000380e:	0001c517          	auipc	a0,0x1c
    80003812:	fba50513          	addi	a0,a0,-70 # 8001f7c8 <itable>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	474080e7          	jalr	1140(ra) # 80000c8a <release>
    itrunc(ip);
    8000381e:	8526                	mv	a0,s1
    80003820:	00000097          	auipc	ra,0x0
    80003824:	ee2080e7          	jalr	-286(ra) # 80003702 <itrunc>
    ip->type = 0;
    80003828:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000382c:	8526                	mv	a0,s1
    8000382e:	00000097          	auipc	ra,0x0
    80003832:	cfc080e7          	jalr	-772(ra) # 8000352a <iupdate>
    ip->valid = 0;
    80003836:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000383a:	854a                	mv	a0,s2
    8000383c:	00001097          	auipc	ra,0x1
    80003840:	ad8080e7          	jalr	-1320(ra) # 80004314 <releasesleep>
    acquire(&itable.lock);
    80003844:	0001c517          	auipc	a0,0x1c
    80003848:	f8450513          	addi	a0,a0,-124 # 8001f7c8 <itable>
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	38a080e7          	jalr	906(ra) # 80000bd6 <acquire>
    80003854:	b741                	j	800037d4 <iput+0x26>

0000000080003856 <iunlockput>:
{
    80003856:	1101                	addi	sp,sp,-32
    80003858:	ec06                	sd	ra,24(sp)
    8000385a:	e822                	sd	s0,16(sp)
    8000385c:	e426                	sd	s1,8(sp)
    8000385e:	1000                	addi	s0,sp,32
    80003860:	84aa                	mv	s1,a0
  iunlock(ip);
    80003862:	00000097          	auipc	ra,0x0
    80003866:	e54080e7          	jalr	-428(ra) # 800036b6 <iunlock>
  iput(ip);
    8000386a:	8526                	mv	a0,s1
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	f42080e7          	jalr	-190(ra) # 800037ae <iput>
}
    80003874:	60e2                	ld	ra,24(sp)
    80003876:	6442                	ld	s0,16(sp)
    80003878:	64a2                	ld	s1,8(sp)
    8000387a:	6105                	addi	sp,sp,32
    8000387c:	8082                	ret

000000008000387e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000387e:	1141                	addi	sp,sp,-16
    80003880:	e422                	sd	s0,8(sp)
    80003882:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003884:	411c                	lw	a5,0(a0)
    80003886:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003888:	415c                	lw	a5,4(a0)
    8000388a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000388c:	04451783          	lh	a5,68(a0)
    80003890:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003894:	04a51783          	lh	a5,74(a0)
    80003898:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000389c:	04c56783          	lwu	a5,76(a0)
    800038a0:	e99c                	sd	a5,16(a1)
}
    800038a2:	6422                	ld	s0,8(sp)
    800038a4:	0141                	addi	sp,sp,16
    800038a6:	8082                	ret

00000000800038a8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038a8:	457c                	lw	a5,76(a0)
    800038aa:	0ed7e963          	bltu	a5,a3,8000399c <readi+0xf4>
{
    800038ae:	7159                	addi	sp,sp,-112
    800038b0:	f486                	sd	ra,104(sp)
    800038b2:	f0a2                	sd	s0,96(sp)
    800038b4:	eca6                	sd	s1,88(sp)
    800038b6:	e8ca                	sd	s2,80(sp)
    800038b8:	e4ce                	sd	s3,72(sp)
    800038ba:	e0d2                	sd	s4,64(sp)
    800038bc:	fc56                	sd	s5,56(sp)
    800038be:	f85a                	sd	s6,48(sp)
    800038c0:	f45e                	sd	s7,40(sp)
    800038c2:	f062                	sd	s8,32(sp)
    800038c4:	ec66                	sd	s9,24(sp)
    800038c6:	e86a                	sd	s10,16(sp)
    800038c8:	e46e                	sd	s11,8(sp)
    800038ca:	1880                	addi	s0,sp,112
    800038cc:	8baa                	mv	s7,a0
    800038ce:	8c2e                	mv	s8,a1
    800038d0:	8ab2                	mv	s5,a2
    800038d2:	84b6                	mv	s1,a3
    800038d4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038d6:	9f35                	addw	a4,a4,a3
    return 0;
    800038d8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038da:	0ad76063          	bltu	a4,a3,8000397a <readi+0xd2>
  if(off + n > ip->size)
    800038de:	00e7f463          	bgeu	a5,a4,800038e6 <readi+0x3e>
    n = ip->size - off;
    800038e2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038e6:	0a0b0963          	beqz	s6,80003998 <readi+0xf0>
    800038ea:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800038ec:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800038f0:	5cfd                	li	s9,-1
    800038f2:	a82d                	j	8000392c <readi+0x84>
    800038f4:	020a1d93          	slli	s11,s4,0x20
    800038f8:	020ddd93          	srli	s11,s11,0x20
    800038fc:	05890613          	addi	a2,s2,88
    80003900:	86ee                	mv	a3,s11
    80003902:	963a                	add	a2,a2,a4
    80003904:	85d6                	mv	a1,s5
    80003906:	8562                	mv	a0,s8
    80003908:	fffff097          	auipc	ra,0xfffff
    8000390c:	aec080e7          	jalr	-1300(ra) # 800023f4 <either_copyout>
    80003910:	05950d63          	beq	a0,s9,8000396a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003914:	854a                	mv	a0,s2
    80003916:	fffff097          	auipc	ra,0xfffff
    8000391a:	60c080e7          	jalr	1548(ra) # 80002f22 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000391e:	013a09bb          	addw	s3,s4,s3
    80003922:	009a04bb          	addw	s1,s4,s1
    80003926:	9aee                	add	s5,s5,s11
    80003928:	0569f763          	bgeu	s3,s6,80003976 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000392c:	000ba903          	lw	s2,0(s7)
    80003930:	00a4d59b          	srliw	a1,s1,0xa
    80003934:	855e                	mv	a0,s7
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	8b0080e7          	jalr	-1872(ra) # 800031e6 <bmap>
    8000393e:	0005059b          	sext.w	a1,a0
    80003942:	854a                	mv	a0,s2
    80003944:	fffff097          	auipc	ra,0xfffff
    80003948:	4ae080e7          	jalr	1198(ra) # 80002df2 <bread>
    8000394c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000394e:	3ff4f713          	andi	a4,s1,1023
    80003952:	40ed07bb          	subw	a5,s10,a4
    80003956:	413b06bb          	subw	a3,s6,s3
    8000395a:	8a3e                	mv	s4,a5
    8000395c:	2781                	sext.w	a5,a5
    8000395e:	0006861b          	sext.w	a2,a3
    80003962:	f8f679e3          	bgeu	a2,a5,800038f4 <readi+0x4c>
    80003966:	8a36                	mv	s4,a3
    80003968:	b771                	j	800038f4 <readi+0x4c>
      brelse(bp);
    8000396a:	854a                	mv	a0,s2
    8000396c:	fffff097          	auipc	ra,0xfffff
    80003970:	5b6080e7          	jalr	1462(ra) # 80002f22 <brelse>
      tot = -1;
    80003974:	59fd                	li	s3,-1
  }
  return tot;
    80003976:	0009851b          	sext.w	a0,s3
}
    8000397a:	70a6                	ld	ra,104(sp)
    8000397c:	7406                	ld	s0,96(sp)
    8000397e:	64e6                	ld	s1,88(sp)
    80003980:	6946                	ld	s2,80(sp)
    80003982:	69a6                	ld	s3,72(sp)
    80003984:	6a06                	ld	s4,64(sp)
    80003986:	7ae2                	ld	s5,56(sp)
    80003988:	7b42                	ld	s6,48(sp)
    8000398a:	7ba2                	ld	s7,40(sp)
    8000398c:	7c02                	ld	s8,32(sp)
    8000398e:	6ce2                	ld	s9,24(sp)
    80003990:	6d42                	ld	s10,16(sp)
    80003992:	6da2                	ld	s11,8(sp)
    80003994:	6165                	addi	sp,sp,112
    80003996:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003998:	89da                	mv	s3,s6
    8000399a:	bff1                	j	80003976 <readi+0xce>
    return 0;
    8000399c:	4501                	li	a0,0
}
    8000399e:	8082                	ret

00000000800039a0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039a0:	457c                	lw	a5,76(a0)
    800039a2:	10d7e863          	bltu	a5,a3,80003ab2 <writei+0x112>
{
    800039a6:	7159                	addi	sp,sp,-112
    800039a8:	f486                	sd	ra,104(sp)
    800039aa:	f0a2                	sd	s0,96(sp)
    800039ac:	eca6                	sd	s1,88(sp)
    800039ae:	e8ca                	sd	s2,80(sp)
    800039b0:	e4ce                	sd	s3,72(sp)
    800039b2:	e0d2                	sd	s4,64(sp)
    800039b4:	fc56                	sd	s5,56(sp)
    800039b6:	f85a                	sd	s6,48(sp)
    800039b8:	f45e                	sd	s7,40(sp)
    800039ba:	f062                	sd	s8,32(sp)
    800039bc:	ec66                	sd	s9,24(sp)
    800039be:	e86a                	sd	s10,16(sp)
    800039c0:	e46e                	sd	s11,8(sp)
    800039c2:	1880                	addi	s0,sp,112
    800039c4:	8b2a                	mv	s6,a0
    800039c6:	8c2e                	mv	s8,a1
    800039c8:	8ab2                	mv	s5,a2
    800039ca:	8936                	mv	s2,a3
    800039cc:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800039ce:	00e687bb          	addw	a5,a3,a4
    800039d2:	0ed7e263          	bltu	a5,a3,80003ab6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039d6:	00043737          	lui	a4,0x43
    800039da:	0ef76063          	bltu	a4,a5,80003aba <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039de:	0c0b8863          	beqz	s7,80003aae <writei+0x10e>
    800039e2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039e4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800039e8:	5cfd                	li	s9,-1
    800039ea:	a091                	j	80003a2e <writei+0x8e>
    800039ec:	02099d93          	slli	s11,s3,0x20
    800039f0:	020ddd93          	srli	s11,s11,0x20
    800039f4:	05848513          	addi	a0,s1,88
    800039f8:	86ee                	mv	a3,s11
    800039fa:	8656                	mv	a2,s5
    800039fc:	85e2                	mv	a1,s8
    800039fe:	953a                	add	a0,a0,a4
    80003a00:	fffff097          	auipc	ra,0xfffff
    80003a04:	a4a080e7          	jalr	-1462(ra) # 8000244a <either_copyin>
    80003a08:	07950263          	beq	a0,s9,80003a6c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a0c:	8526                	mv	a0,s1
    80003a0e:	00000097          	auipc	ra,0x0
    80003a12:	790080e7          	jalr	1936(ra) # 8000419e <log_write>
    brelse(bp);
    80003a16:	8526                	mv	a0,s1
    80003a18:	fffff097          	auipc	ra,0xfffff
    80003a1c:	50a080e7          	jalr	1290(ra) # 80002f22 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a20:	01498a3b          	addw	s4,s3,s4
    80003a24:	0129893b          	addw	s2,s3,s2
    80003a28:	9aee                	add	s5,s5,s11
    80003a2a:	057a7663          	bgeu	s4,s7,80003a76 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a2e:	000b2483          	lw	s1,0(s6)
    80003a32:	00a9559b          	srliw	a1,s2,0xa
    80003a36:	855a                	mv	a0,s6
    80003a38:	fffff097          	auipc	ra,0xfffff
    80003a3c:	7ae080e7          	jalr	1966(ra) # 800031e6 <bmap>
    80003a40:	0005059b          	sext.w	a1,a0
    80003a44:	8526                	mv	a0,s1
    80003a46:	fffff097          	auipc	ra,0xfffff
    80003a4a:	3ac080e7          	jalr	940(ra) # 80002df2 <bread>
    80003a4e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a50:	3ff97713          	andi	a4,s2,1023
    80003a54:	40ed07bb          	subw	a5,s10,a4
    80003a58:	414b86bb          	subw	a3,s7,s4
    80003a5c:	89be                	mv	s3,a5
    80003a5e:	2781                	sext.w	a5,a5
    80003a60:	0006861b          	sext.w	a2,a3
    80003a64:	f8f674e3          	bgeu	a2,a5,800039ec <writei+0x4c>
    80003a68:	89b6                	mv	s3,a3
    80003a6a:	b749                	j	800039ec <writei+0x4c>
      brelse(bp);
    80003a6c:	8526                	mv	a0,s1
    80003a6e:	fffff097          	auipc	ra,0xfffff
    80003a72:	4b4080e7          	jalr	1204(ra) # 80002f22 <brelse>
  }

  if(off > ip->size)
    80003a76:	04cb2783          	lw	a5,76(s6)
    80003a7a:	0127f463          	bgeu	a5,s2,80003a82 <writei+0xe2>
    ip->size = off;
    80003a7e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003a82:	855a                	mv	a0,s6
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	aa6080e7          	jalr	-1370(ra) # 8000352a <iupdate>

  return tot;
    80003a8c:	000a051b          	sext.w	a0,s4
}
    80003a90:	70a6                	ld	ra,104(sp)
    80003a92:	7406                	ld	s0,96(sp)
    80003a94:	64e6                	ld	s1,88(sp)
    80003a96:	6946                	ld	s2,80(sp)
    80003a98:	69a6                	ld	s3,72(sp)
    80003a9a:	6a06                	ld	s4,64(sp)
    80003a9c:	7ae2                	ld	s5,56(sp)
    80003a9e:	7b42                	ld	s6,48(sp)
    80003aa0:	7ba2                	ld	s7,40(sp)
    80003aa2:	7c02                	ld	s8,32(sp)
    80003aa4:	6ce2                	ld	s9,24(sp)
    80003aa6:	6d42                	ld	s10,16(sp)
    80003aa8:	6da2                	ld	s11,8(sp)
    80003aaa:	6165                	addi	sp,sp,112
    80003aac:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aae:	8a5e                	mv	s4,s7
    80003ab0:	bfc9                	j	80003a82 <writei+0xe2>
    return -1;
    80003ab2:	557d                	li	a0,-1
}
    80003ab4:	8082                	ret
    return -1;
    80003ab6:	557d                	li	a0,-1
    80003ab8:	bfe1                	j	80003a90 <writei+0xf0>
    return -1;
    80003aba:	557d                	li	a0,-1
    80003abc:	bfd1                	j	80003a90 <writei+0xf0>

0000000080003abe <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003abe:	1141                	addi	sp,sp,-16
    80003ac0:	e406                	sd	ra,8(sp)
    80003ac2:	e022                	sd	s0,0(sp)
    80003ac4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ac6:	4639                	li	a2,14
    80003ac8:	ffffd097          	auipc	ra,0xffffd
    80003acc:	2e6080e7          	jalr	742(ra) # 80000dae <strncmp>
}
    80003ad0:	60a2                	ld	ra,8(sp)
    80003ad2:	6402                	ld	s0,0(sp)
    80003ad4:	0141                	addi	sp,sp,16
    80003ad6:	8082                	ret

0000000080003ad8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ad8:	7139                	addi	sp,sp,-64
    80003ada:	fc06                	sd	ra,56(sp)
    80003adc:	f822                	sd	s0,48(sp)
    80003ade:	f426                	sd	s1,40(sp)
    80003ae0:	f04a                	sd	s2,32(sp)
    80003ae2:	ec4e                	sd	s3,24(sp)
    80003ae4:	e852                	sd	s4,16(sp)
    80003ae6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ae8:	04451703          	lh	a4,68(a0)
    80003aec:	4785                	li	a5,1
    80003aee:	00f71a63          	bne	a4,a5,80003b02 <dirlookup+0x2a>
    80003af2:	892a                	mv	s2,a0
    80003af4:	89ae                	mv	s3,a1
    80003af6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003af8:	457c                	lw	a5,76(a0)
    80003afa:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003afc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003afe:	e79d                	bnez	a5,80003b2c <dirlookup+0x54>
    80003b00:	a8a5                	j	80003b78 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b02:	00005517          	auipc	a0,0x5
    80003b06:	ad650513          	addi	a0,a0,-1322 # 800085d8 <syscalls+0x1a8>
    80003b0a:	ffffd097          	auipc	ra,0xffffd
    80003b0e:	a26080e7          	jalr	-1498(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003b12:	00005517          	auipc	a0,0x5
    80003b16:	ade50513          	addi	a0,a0,-1314 # 800085f0 <syscalls+0x1c0>
    80003b1a:	ffffd097          	auipc	ra,0xffffd
    80003b1e:	a16080e7          	jalr	-1514(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b22:	24c1                	addiw	s1,s1,16
    80003b24:	04c92783          	lw	a5,76(s2)
    80003b28:	04f4f763          	bgeu	s1,a5,80003b76 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b2c:	4741                	li	a4,16
    80003b2e:	86a6                	mv	a3,s1
    80003b30:	fc040613          	addi	a2,s0,-64
    80003b34:	4581                	li	a1,0
    80003b36:	854a                	mv	a0,s2
    80003b38:	00000097          	auipc	ra,0x0
    80003b3c:	d70080e7          	jalr	-656(ra) # 800038a8 <readi>
    80003b40:	47c1                	li	a5,16
    80003b42:	fcf518e3          	bne	a0,a5,80003b12 <dirlookup+0x3a>
    if(de.inum == 0)
    80003b46:	fc045783          	lhu	a5,-64(s0)
    80003b4a:	dfe1                	beqz	a5,80003b22 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b4c:	fc240593          	addi	a1,s0,-62
    80003b50:	854e                	mv	a0,s3
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	f6c080e7          	jalr	-148(ra) # 80003abe <namecmp>
    80003b5a:	f561                	bnez	a0,80003b22 <dirlookup+0x4a>
      if(poff)
    80003b5c:	000a0463          	beqz	s4,80003b64 <dirlookup+0x8c>
        *poff = off;
    80003b60:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b64:	fc045583          	lhu	a1,-64(s0)
    80003b68:	00092503          	lw	a0,0(s2)
    80003b6c:	fffff097          	auipc	ra,0xfffff
    80003b70:	754080e7          	jalr	1876(ra) # 800032c0 <iget>
    80003b74:	a011                	j	80003b78 <dirlookup+0xa0>
  return 0;
    80003b76:	4501                	li	a0,0
}
    80003b78:	70e2                	ld	ra,56(sp)
    80003b7a:	7442                	ld	s0,48(sp)
    80003b7c:	74a2                	ld	s1,40(sp)
    80003b7e:	7902                	ld	s2,32(sp)
    80003b80:	69e2                	ld	s3,24(sp)
    80003b82:	6a42                	ld	s4,16(sp)
    80003b84:	6121                	addi	sp,sp,64
    80003b86:	8082                	ret

0000000080003b88 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003b88:	711d                	addi	sp,sp,-96
    80003b8a:	ec86                	sd	ra,88(sp)
    80003b8c:	e8a2                	sd	s0,80(sp)
    80003b8e:	e4a6                	sd	s1,72(sp)
    80003b90:	e0ca                	sd	s2,64(sp)
    80003b92:	fc4e                	sd	s3,56(sp)
    80003b94:	f852                	sd	s4,48(sp)
    80003b96:	f456                	sd	s5,40(sp)
    80003b98:	f05a                	sd	s6,32(sp)
    80003b9a:	ec5e                	sd	s7,24(sp)
    80003b9c:	e862                	sd	s8,16(sp)
    80003b9e:	e466                	sd	s9,8(sp)
    80003ba0:	1080                	addi	s0,sp,96
    80003ba2:	84aa                	mv	s1,a0
    80003ba4:	8b2e                	mv	s6,a1
    80003ba6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ba8:	00054703          	lbu	a4,0(a0)
    80003bac:	02f00793          	li	a5,47
    80003bb0:	02f70363          	beq	a4,a5,80003bd6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bb4:	ffffe097          	auipc	ra,0xffffe
    80003bb8:	de0080e7          	jalr	-544(ra) # 80001994 <myproc>
    80003bbc:	15053503          	ld	a0,336(a0)
    80003bc0:	00000097          	auipc	ra,0x0
    80003bc4:	9f6080e7          	jalr	-1546(ra) # 800035b6 <idup>
    80003bc8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003bca:	02f00913          	li	s2,47
  len = path - s;
    80003bce:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003bd0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bd2:	4c05                	li	s8,1
    80003bd4:	a865                	j	80003c8c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003bd6:	4585                	li	a1,1
    80003bd8:	4505                	li	a0,1
    80003bda:	fffff097          	auipc	ra,0xfffff
    80003bde:	6e6080e7          	jalr	1766(ra) # 800032c0 <iget>
    80003be2:	89aa                	mv	s3,a0
    80003be4:	b7dd                	j	80003bca <namex+0x42>
      iunlockput(ip);
    80003be6:	854e                	mv	a0,s3
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	c6e080e7          	jalr	-914(ra) # 80003856 <iunlockput>
      return 0;
    80003bf0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003bf2:	854e                	mv	a0,s3
    80003bf4:	60e6                	ld	ra,88(sp)
    80003bf6:	6446                	ld	s0,80(sp)
    80003bf8:	64a6                	ld	s1,72(sp)
    80003bfa:	6906                	ld	s2,64(sp)
    80003bfc:	79e2                	ld	s3,56(sp)
    80003bfe:	7a42                	ld	s4,48(sp)
    80003c00:	7aa2                	ld	s5,40(sp)
    80003c02:	7b02                	ld	s6,32(sp)
    80003c04:	6be2                	ld	s7,24(sp)
    80003c06:	6c42                	ld	s8,16(sp)
    80003c08:	6ca2                	ld	s9,8(sp)
    80003c0a:	6125                	addi	sp,sp,96
    80003c0c:	8082                	ret
      iunlock(ip);
    80003c0e:	854e                	mv	a0,s3
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	aa6080e7          	jalr	-1370(ra) # 800036b6 <iunlock>
      return ip;
    80003c18:	bfe9                	j	80003bf2 <namex+0x6a>
      iunlockput(ip);
    80003c1a:	854e                	mv	a0,s3
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	c3a080e7          	jalr	-966(ra) # 80003856 <iunlockput>
      return 0;
    80003c24:	89d2                	mv	s3,s4
    80003c26:	b7f1                	j	80003bf2 <namex+0x6a>
  len = path - s;
    80003c28:	40b48633          	sub	a2,s1,a1
    80003c2c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003c30:	094cd463          	bge	s9,s4,80003cb8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c34:	4639                	li	a2,14
    80003c36:	8556                	mv	a0,s5
    80003c38:	ffffd097          	auipc	ra,0xffffd
    80003c3c:	0fa080e7          	jalr	250(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003c40:	0004c783          	lbu	a5,0(s1)
    80003c44:	01279763          	bne	a5,s2,80003c52 <namex+0xca>
    path++;
    80003c48:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c4a:	0004c783          	lbu	a5,0(s1)
    80003c4e:	ff278de3          	beq	a5,s2,80003c48 <namex+0xc0>
    ilock(ip);
    80003c52:	854e                	mv	a0,s3
    80003c54:	00000097          	auipc	ra,0x0
    80003c58:	9a0080e7          	jalr	-1632(ra) # 800035f4 <ilock>
    if(ip->type != T_DIR){
    80003c5c:	04499783          	lh	a5,68(s3)
    80003c60:	f98793e3          	bne	a5,s8,80003be6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c64:	000b0563          	beqz	s6,80003c6e <namex+0xe6>
    80003c68:	0004c783          	lbu	a5,0(s1)
    80003c6c:	d3cd                	beqz	a5,80003c0e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c6e:	865e                	mv	a2,s7
    80003c70:	85d6                	mv	a1,s5
    80003c72:	854e                	mv	a0,s3
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	e64080e7          	jalr	-412(ra) # 80003ad8 <dirlookup>
    80003c7c:	8a2a                	mv	s4,a0
    80003c7e:	dd51                	beqz	a0,80003c1a <namex+0x92>
    iunlockput(ip);
    80003c80:	854e                	mv	a0,s3
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	bd4080e7          	jalr	-1068(ra) # 80003856 <iunlockput>
    ip = next;
    80003c8a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003c8c:	0004c783          	lbu	a5,0(s1)
    80003c90:	05279763          	bne	a5,s2,80003cde <namex+0x156>
    path++;
    80003c94:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c96:	0004c783          	lbu	a5,0(s1)
    80003c9a:	ff278de3          	beq	a5,s2,80003c94 <namex+0x10c>
  if(*path == 0)
    80003c9e:	c79d                	beqz	a5,80003ccc <namex+0x144>
    path++;
    80003ca0:	85a6                	mv	a1,s1
  len = path - s;
    80003ca2:	8a5e                	mv	s4,s7
    80003ca4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ca6:	01278963          	beq	a5,s2,80003cb8 <namex+0x130>
    80003caa:	dfbd                	beqz	a5,80003c28 <namex+0xa0>
    path++;
    80003cac:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003cae:	0004c783          	lbu	a5,0(s1)
    80003cb2:	ff279ce3          	bne	a5,s2,80003caa <namex+0x122>
    80003cb6:	bf8d                	j	80003c28 <namex+0xa0>
    memmove(name, s, len);
    80003cb8:	2601                	sext.w	a2,a2
    80003cba:	8556                	mv	a0,s5
    80003cbc:	ffffd097          	auipc	ra,0xffffd
    80003cc0:	076080e7          	jalr	118(ra) # 80000d32 <memmove>
    name[len] = 0;
    80003cc4:	9a56                	add	s4,s4,s5
    80003cc6:	000a0023          	sb	zero,0(s4)
    80003cca:	bf9d                	j	80003c40 <namex+0xb8>
  if(nameiparent){
    80003ccc:	f20b03e3          	beqz	s6,80003bf2 <namex+0x6a>
    iput(ip);
    80003cd0:	854e                	mv	a0,s3
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	adc080e7          	jalr	-1316(ra) # 800037ae <iput>
    return 0;
    80003cda:	4981                	li	s3,0
    80003cdc:	bf19                	j	80003bf2 <namex+0x6a>
  if(*path == 0)
    80003cde:	d7fd                	beqz	a5,80003ccc <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ce0:	0004c783          	lbu	a5,0(s1)
    80003ce4:	85a6                	mv	a1,s1
    80003ce6:	b7d1                	j	80003caa <namex+0x122>

0000000080003ce8 <dirlink>:
{
    80003ce8:	7139                	addi	sp,sp,-64
    80003cea:	fc06                	sd	ra,56(sp)
    80003cec:	f822                	sd	s0,48(sp)
    80003cee:	f426                	sd	s1,40(sp)
    80003cf0:	f04a                	sd	s2,32(sp)
    80003cf2:	ec4e                	sd	s3,24(sp)
    80003cf4:	e852                	sd	s4,16(sp)
    80003cf6:	0080                	addi	s0,sp,64
    80003cf8:	892a                	mv	s2,a0
    80003cfa:	8a2e                	mv	s4,a1
    80003cfc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003cfe:	4601                	li	a2,0
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	dd8080e7          	jalr	-552(ra) # 80003ad8 <dirlookup>
    80003d08:	e93d                	bnez	a0,80003d7e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d0a:	04c92483          	lw	s1,76(s2)
    80003d0e:	c49d                	beqz	s1,80003d3c <dirlink+0x54>
    80003d10:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d12:	4741                	li	a4,16
    80003d14:	86a6                	mv	a3,s1
    80003d16:	fc040613          	addi	a2,s0,-64
    80003d1a:	4581                	li	a1,0
    80003d1c:	854a                	mv	a0,s2
    80003d1e:	00000097          	auipc	ra,0x0
    80003d22:	b8a080e7          	jalr	-1142(ra) # 800038a8 <readi>
    80003d26:	47c1                	li	a5,16
    80003d28:	06f51163          	bne	a0,a5,80003d8a <dirlink+0xa2>
    if(de.inum == 0)
    80003d2c:	fc045783          	lhu	a5,-64(s0)
    80003d30:	c791                	beqz	a5,80003d3c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d32:	24c1                	addiw	s1,s1,16
    80003d34:	04c92783          	lw	a5,76(s2)
    80003d38:	fcf4ede3          	bltu	s1,a5,80003d12 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d3c:	4639                	li	a2,14
    80003d3e:	85d2                	mv	a1,s4
    80003d40:	fc240513          	addi	a0,s0,-62
    80003d44:	ffffd097          	auipc	ra,0xffffd
    80003d48:	0a6080e7          	jalr	166(ra) # 80000dea <strncpy>
  de.inum = inum;
    80003d4c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d50:	4741                	li	a4,16
    80003d52:	86a6                	mv	a3,s1
    80003d54:	fc040613          	addi	a2,s0,-64
    80003d58:	4581                	li	a1,0
    80003d5a:	854a                	mv	a0,s2
    80003d5c:	00000097          	auipc	ra,0x0
    80003d60:	c44080e7          	jalr	-956(ra) # 800039a0 <writei>
    80003d64:	872a                	mv	a4,a0
    80003d66:	47c1                	li	a5,16
  return 0;
    80003d68:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d6a:	02f71863          	bne	a4,a5,80003d9a <dirlink+0xb2>
}
    80003d6e:	70e2                	ld	ra,56(sp)
    80003d70:	7442                	ld	s0,48(sp)
    80003d72:	74a2                	ld	s1,40(sp)
    80003d74:	7902                	ld	s2,32(sp)
    80003d76:	69e2                	ld	s3,24(sp)
    80003d78:	6a42                	ld	s4,16(sp)
    80003d7a:	6121                	addi	sp,sp,64
    80003d7c:	8082                	ret
    iput(ip);
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	a30080e7          	jalr	-1488(ra) # 800037ae <iput>
    return -1;
    80003d86:	557d                	li	a0,-1
    80003d88:	b7dd                	j	80003d6e <dirlink+0x86>
      panic("dirlink read");
    80003d8a:	00005517          	auipc	a0,0x5
    80003d8e:	87650513          	addi	a0,a0,-1930 # 80008600 <syscalls+0x1d0>
    80003d92:	ffffc097          	auipc	ra,0xffffc
    80003d96:	79e080e7          	jalr	1950(ra) # 80000530 <panic>
    panic("dirlink");
    80003d9a:	00005517          	auipc	a0,0x5
    80003d9e:	97650513          	addi	a0,a0,-1674 # 80008710 <syscalls+0x2e0>
    80003da2:	ffffc097          	auipc	ra,0xffffc
    80003da6:	78e080e7          	jalr	1934(ra) # 80000530 <panic>

0000000080003daa <namei>:

struct inode*
namei(char *path)
{
    80003daa:	1101                	addi	sp,sp,-32
    80003dac:	ec06                	sd	ra,24(sp)
    80003dae:	e822                	sd	s0,16(sp)
    80003db0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003db2:	fe040613          	addi	a2,s0,-32
    80003db6:	4581                	li	a1,0
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	dd0080e7          	jalr	-560(ra) # 80003b88 <namex>
}
    80003dc0:	60e2                	ld	ra,24(sp)
    80003dc2:	6442                	ld	s0,16(sp)
    80003dc4:	6105                	addi	sp,sp,32
    80003dc6:	8082                	ret

0000000080003dc8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003dc8:	1141                	addi	sp,sp,-16
    80003dca:	e406                	sd	ra,8(sp)
    80003dcc:	e022                	sd	s0,0(sp)
    80003dce:	0800                	addi	s0,sp,16
    80003dd0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dd2:	4585                	li	a1,1
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	db4080e7          	jalr	-588(ra) # 80003b88 <namex>
}
    80003ddc:	60a2                	ld	ra,8(sp)
    80003dde:	6402                	ld	s0,0(sp)
    80003de0:	0141                	addi	sp,sp,16
    80003de2:	8082                	ret

0000000080003de4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003de4:	1101                	addi	sp,sp,-32
    80003de6:	ec06                	sd	ra,24(sp)
    80003de8:	e822                	sd	s0,16(sp)
    80003dea:	e426                	sd	s1,8(sp)
    80003dec:	e04a                	sd	s2,0(sp)
    80003dee:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003df0:	0001d917          	auipc	s2,0x1d
    80003df4:	48090913          	addi	s2,s2,1152 # 80021270 <log>
    80003df8:	01892583          	lw	a1,24(s2)
    80003dfc:	02892503          	lw	a0,40(s2)
    80003e00:	fffff097          	auipc	ra,0xfffff
    80003e04:	ff2080e7          	jalr	-14(ra) # 80002df2 <bread>
    80003e08:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e0a:	02c92683          	lw	a3,44(s2)
    80003e0e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e10:	02d05763          	blez	a3,80003e3e <write_head+0x5a>
    80003e14:	0001d797          	auipc	a5,0x1d
    80003e18:	48c78793          	addi	a5,a5,1164 # 800212a0 <log+0x30>
    80003e1c:	05c50713          	addi	a4,a0,92
    80003e20:	36fd                	addiw	a3,a3,-1
    80003e22:	1682                	slli	a3,a3,0x20
    80003e24:	9281                	srli	a3,a3,0x20
    80003e26:	068a                	slli	a3,a3,0x2
    80003e28:	0001d617          	auipc	a2,0x1d
    80003e2c:	47c60613          	addi	a2,a2,1148 # 800212a4 <log+0x34>
    80003e30:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e32:	4390                	lw	a2,0(a5)
    80003e34:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e36:	0791                	addi	a5,a5,4
    80003e38:	0711                	addi	a4,a4,4
    80003e3a:	fed79ce3          	bne	a5,a3,80003e32 <write_head+0x4e>
  }
  bwrite(buf);
    80003e3e:	8526                	mv	a0,s1
    80003e40:	fffff097          	auipc	ra,0xfffff
    80003e44:	0a4080e7          	jalr	164(ra) # 80002ee4 <bwrite>
  brelse(buf);
    80003e48:	8526                	mv	a0,s1
    80003e4a:	fffff097          	auipc	ra,0xfffff
    80003e4e:	0d8080e7          	jalr	216(ra) # 80002f22 <brelse>
}
    80003e52:	60e2                	ld	ra,24(sp)
    80003e54:	6442                	ld	s0,16(sp)
    80003e56:	64a2                	ld	s1,8(sp)
    80003e58:	6902                	ld	s2,0(sp)
    80003e5a:	6105                	addi	sp,sp,32
    80003e5c:	8082                	ret

0000000080003e5e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e5e:	0001d797          	auipc	a5,0x1d
    80003e62:	43e7a783          	lw	a5,1086(a5) # 8002129c <log+0x2c>
    80003e66:	0af05d63          	blez	a5,80003f20 <install_trans+0xc2>
{
    80003e6a:	7139                	addi	sp,sp,-64
    80003e6c:	fc06                	sd	ra,56(sp)
    80003e6e:	f822                	sd	s0,48(sp)
    80003e70:	f426                	sd	s1,40(sp)
    80003e72:	f04a                	sd	s2,32(sp)
    80003e74:	ec4e                	sd	s3,24(sp)
    80003e76:	e852                	sd	s4,16(sp)
    80003e78:	e456                	sd	s5,8(sp)
    80003e7a:	e05a                	sd	s6,0(sp)
    80003e7c:	0080                	addi	s0,sp,64
    80003e7e:	8b2a                	mv	s6,a0
    80003e80:	0001da97          	auipc	s5,0x1d
    80003e84:	420a8a93          	addi	s5,s5,1056 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e88:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e8a:	0001d997          	auipc	s3,0x1d
    80003e8e:	3e698993          	addi	s3,s3,998 # 80021270 <log>
    80003e92:	a035                	j	80003ebe <install_trans+0x60>
      bunpin(dbuf);
    80003e94:	8526                	mv	a0,s1
    80003e96:	fffff097          	auipc	ra,0xfffff
    80003e9a:	166080e7          	jalr	358(ra) # 80002ffc <bunpin>
    brelse(lbuf);
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	fffff097          	auipc	ra,0xfffff
    80003ea4:	082080e7          	jalr	130(ra) # 80002f22 <brelse>
    brelse(dbuf);
    80003ea8:	8526                	mv	a0,s1
    80003eaa:	fffff097          	auipc	ra,0xfffff
    80003eae:	078080e7          	jalr	120(ra) # 80002f22 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eb2:	2a05                	addiw	s4,s4,1
    80003eb4:	0a91                	addi	s5,s5,4
    80003eb6:	02c9a783          	lw	a5,44(s3)
    80003eba:	04fa5963          	bge	s4,a5,80003f0c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ebe:	0189a583          	lw	a1,24(s3)
    80003ec2:	014585bb          	addw	a1,a1,s4
    80003ec6:	2585                	addiw	a1,a1,1
    80003ec8:	0289a503          	lw	a0,40(s3)
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	f26080e7          	jalr	-218(ra) # 80002df2 <bread>
    80003ed4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ed6:	000aa583          	lw	a1,0(s5)
    80003eda:	0289a503          	lw	a0,40(s3)
    80003ede:	fffff097          	auipc	ra,0xfffff
    80003ee2:	f14080e7          	jalr	-236(ra) # 80002df2 <bread>
    80003ee6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ee8:	40000613          	li	a2,1024
    80003eec:	05890593          	addi	a1,s2,88
    80003ef0:	05850513          	addi	a0,a0,88
    80003ef4:	ffffd097          	auipc	ra,0xffffd
    80003ef8:	e3e080e7          	jalr	-450(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003efc:	8526                	mv	a0,s1
    80003efe:	fffff097          	auipc	ra,0xfffff
    80003f02:	fe6080e7          	jalr	-26(ra) # 80002ee4 <bwrite>
    if(recovering == 0)
    80003f06:	f80b1ce3          	bnez	s6,80003e9e <install_trans+0x40>
    80003f0a:	b769                	j	80003e94 <install_trans+0x36>
}
    80003f0c:	70e2                	ld	ra,56(sp)
    80003f0e:	7442                	ld	s0,48(sp)
    80003f10:	74a2                	ld	s1,40(sp)
    80003f12:	7902                	ld	s2,32(sp)
    80003f14:	69e2                	ld	s3,24(sp)
    80003f16:	6a42                	ld	s4,16(sp)
    80003f18:	6aa2                	ld	s5,8(sp)
    80003f1a:	6b02                	ld	s6,0(sp)
    80003f1c:	6121                	addi	sp,sp,64
    80003f1e:	8082                	ret
    80003f20:	8082                	ret

0000000080003f22 <initlog>:
{
    80003f22:	7179                	addi	sp,sp,-48
    80003f24:	f406                	sd	ra,40(sp)
    80003f26:	f022                	sd	s0,32(sp)
    80003f28:	ec26                	sd	s1,24(sp)
    80003f2a:	e84a                	sd	s2,16(sp)
    80003f2c:	e44e                	sd	s3,8(sp)
    80003f2e:	1800                	addi	s0,sp,48
    80003f30:	892a                	mv	s2,a0
    80003f32:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f34:	0001d497          	auipc	s1,0x1d
    80003f38:	33c48493          	addi	s1,s1,828 # 80021270 <log>
    80003f3c:	00004597          	auipc	a1,0x4
    80003f40:	6d458593          	addi	a1,a1,1748 # 80008610 <syscalls+0x1e0>
    80003f44:	8526                	mv	a0,s1
    80003f46:	ffffd097          	auipc	ra,0xffffd
    80003f4a:	c00080e7          	jalr	-1024(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80003f4e:	0149a583          	lw	a1,20(s3)
    80003f52:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f54:	0109a783          	lw	a5,16(s3)
    80003f58:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f5a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f5e:	854a                	mv	a0,s2
    80003f60:	fffff097          	auipc	ra,0xfffff
    80003f64:	e92080e7          	jalr	-366(ra) # 80002df2 <bread>
  log.lh.n = lh->n;
    80003f68:	4d3c                	lw	a5,88(a0)
    80003f6a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f6c:	02f05563          	blez	a5,80003f96 <initlog+0x74>
    80003f70:	05c50713          	addi	a4,a0,92
    80003f74:	0001d697          	auipc	a3,0x1d
    80003f78:	32c68693          	addi	a3,a3,812 # 800212a0 <log+0x30>
    80003f7c:	37fd                	addiw	a5,a5,-1
    80003f7e:	1782                	slli	a5,a5,0x20
    80003f80:	9381                	srli	a5,a5,0x20
    80003f82:	078a                	slli	a5,a5,0x2
    80003f84:	06050613          	addi	a2,a0,96
    80003f88:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003f8a:	4310                	lw	a2,0(a4)
    80003f8c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003f8e:	0711                	addi	a4,a4,4
    80003f90:	0691                	addi	a3,a3,4
    80003f92:	fef71ce3          	bne	a4,a5,80003f8a <initlog+0x68>
  brelse(buf);
    80003f96:	fffff097          	auipc	ra,0xfffff
    80003f9a:	f8c080e7          	jalr	-116(ra) # 80002f22 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f9e:	4505                	li	a0,1
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	ebe080e7          	jalr	-322(ra) # 80003e5e <install_trans>
  log.lh.n = 0;
    80003fa8:	0001d797          	auipc	a5,0x1d
    80003fac:	2e07aa23          	sw	zero,756(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	e34080e7          	jalr	-460(ra) # 80003de4 <write_head>
}
    80003fb8:	70a2                	ld	ra,40(sp)
    80003fba:	7402                	ld	s0,32(sp)
    80003fbc:	64e2                	ld	s1,24(sp)
    80003fbe:	6942                	ld	s2,16(sp)
    80003fc0:	69a2                	ld	s3,8(sp)
    80003fc2:	6145                	addi	sp,sp,48
    80003fc4:	8082                	ret

0000000080003fc6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fc6:	1101                	addi	sp,sp,-32
    80003fc8:	ec06                	sd	ra,24(sp)
    80003fca:	e822                	sd	s0,16(sp)
    80003fcc:	e426                	sd	s1,8(sp)
    80003fce:	e04a                	sd	s2,0(sp)
    80003fd0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fd2:	0001d517          	auipc	a0,0x1d
    80003fd6:	29e50513          	addi	a0,a0,670 # 80021270 <log>
    80003fda:	ffffd097          	auipc	ra,0xffffd
    80003fde:	bfc080e7          	jalr	-1028(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80003fe2:	0001d497          	auipc	s1,0x1d
    80003fe6:	28e48493          	addi	s1,s1,654 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fea:	4979                	li	s2,30
    80003fec:	a039                	j	80003ffa <begin_op+0x34>
      sleep(&log, &log.lock);
    80003fee:	85a6                	mv	a1,s1
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	ffffe097          	auipc	ra,0xffffe
    80003ff6:	05e080e7          	jalr	94(ra) # 80002050 <sleep>
    if(log.committing){
    80003ffa:	50dc                	lw	a5,36(s1)
    80003ffc:	fbed                	bnez	a5,80003fee <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003ffe:	509c                	lw	a5,32(s1)
    80004000:	0017871b          	addiw	a4,a5,1
    80004004:	0007069b          	sext.w	a3,a4
    80004008:	0027179b          	slliw	a5,a4,0x2
    8000400c:	9fb9                	addw	a5,a5,a4
    8000400e:	0017979b          	slliw	a5,a5,0x1
    80004012:	54d8                	lw	a4,44(s1)
    80004014:	9fb9                	addw	a5,a5,a4
    80004016:	00f95963          	bge	s2,a5,80004028 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000401a:	85a6                	mv	a1,s1
    8000401c:	8526                	mv	a0,s1
    8000401e:	ffffe097          	auipc	ra,0xffffe
    80004022:	032080e7          	jalr	50(ra) # 80002050 <sleep>
    80004026:	bfd1                	j	80003ffa <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004028:	0001d517          	auipc	a0,0x1d
    8000402c:	24850513          	addi	a0,a0,584 # 80021270 <log>
    80004030:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004032:	ffffd097          	auipc	ra,0xffffd
    80004036:	c58080e7          	jalr	-936(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000403a:	60e2                	ld	ra,24(sp)
    8000403c:	6442                	ld	s0,16(sp)
    8000403e:	64a2                	ld	s1,8(sp)
    80004040:	6902                	ld	s2,0(sp)
    80004042:	6105                	addi	sp,sp,32
    80004044:	8082                	ret

0000000080004046 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004046:	7139                	addi	sp,sp,-64
    80004048:	fc06                	sd	ra,56(sp)
    8000404a:	f822                	sd	s0,48(sp)
    8000404c:	f426                	sd	s1,40(sp)
    8000404e:	f04a                	sd	s2,32(sp)
    80004050:	ec4e                	sd	s3,24(sp)
    80004052:	e852                	sd	s4,16(sp)
    80004054:	e456                	sd	s5,8(sp)
    80004056:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004058:	0001d497          	auipc	s1,0x1d
    8000405c:	21848493          	addi	s1,s1,536 # 80021270 <log>
    80004060:	8526                	mv	a0,s1
    80004062:	ffffd097          	auipc	ra,0xffffd
    80004066:	b74080e7          	jalr	-1164(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000406a:	509c                	lw	a5,32(s1)
    8000406c:	37fd                	addiw	a5,a5,-1
    8000406e:	0007891b          	sext.w	s2,a5
    80004072:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004074:	50dc                	lw	a5,36(s1)
    80004076:	efb9                	bnez	a5,800040d4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004078:	06091663          	bnez	s2,800040e4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000407c:	0001d497          	auipc	s1,0x1d
    80004080:	1f448493          	addi	s1,s1,500 # 80021270 <log>
    80004084:	4785                	li	a5,1
    80004086:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004088:	8526                	mv	a0,s1
    8000408a:	ffffd097          	auipc	ra,0xffffd
    8000408e:	c00080e7          	jalr	-1024(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004092:	54dc                	lw	a5,44(s1)
    80004094:	06f04763          	bgtz	a5,80004102 <end_op+0xbc>
    acquire(&log.lock);
    80004098:	0001d497          	auipc	s1,0x1d
    8000409c:	1d848493          	addi	s1,s1,472 # 80021270 <log>
    800040a0:	8526                	mv	a0,s1
    800040a2:	ffffd097          	auipc	ra,0xffffd
    800040a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800040aa:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040ae:	8526                	mv	a0,s1
    800040b0:	ffffe097          	auipc	ra,0xffffe
    800040b4:	12c080e7          	jalr	300(ra) # 800021dc <wakeup>
    release(&log.lock);
    800040b8:	8526                	mv	a0,s1
    800040ba:	ffffd097          	auipc	ra,0xffffd
    800040be:	bd0080e7          	jalr	-1072(ra) # 80000c8a <release>
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
    panic("log.committing");
    800040d4:	00004517          	auipc	a0,0x4
    800040d8:	54450513          	addi	a0,a0,1348 # 80008618 <syscalls+0x1e8>
    800040dc:	ffffc097          	auipc	ra,0xffffc
    800040e0:	454080e7          	jalr	1108(ra) # 80000530 <panic>
    wakeup(&log);
    800040e4:	0001d497          	auipc	s1,0x1d
    800040e8:	18c48493          	addi	s1,s1,396 # 80021270 <log>
    800040ec:	8526                	mv	a0,s1
    800040ee:	ffffe097          	auipc	ra,0xffffe
    800040f2:	0ee080e7          	jalr	238(ra) # 800021dc <wakeup>
  release(&log.lock);
    800040f6:	8526                	mv	a0,s1
    800040f8:	ffffd097          	auipc	ra,0xffffd
    800040fc:	b92080e7          	jalr	-1134(ra) # 80000c8a <release>
  if(do_commit){
    80004100:	b7c9                	j	800040c2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004102:	0001da97          	auipc	s5,0x1d
    80004106:	19ea8a93          	addi	s5,s5,414 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000410a:	0001da17          	auipc	s4,0x1d
    8000410e:	166a0a13          	addi	s4,s4,358 # 80021270 <log>
    80004112:	018a2583          	lw	a1,24(s4)
    80004116:	012585bb          	addw	a1,a1,s2
    8000411a:	2585                	addiw	a1,a1,1
    8000411c:	028a2503          	lw	a0,40(s4)
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	cd2080e7          	jalr	-814(ra) # 80002df2 <bread>
    80004128:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000412a:	000aa583          	lw	a1,0(s5)
    8000412e:	028a2503          	lw	a0,40(s4)
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	cc0080e7          	jalr	-832(ra) # 80002df2 <bread>
    8000413a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000413c:	40000613          	li	a2,1024
    80004140:	05850593          	addi	a1,a0,88
    80004144:	05848513          	addi	a0,s1,88
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	bea080e7          	jalr	-1046(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    80004150:	8526                	mv	a0,s1
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	d92080e7          	jalr	-622(ra) # 80002ee4 <bwrite>
    brelse(from);
    8000415a:	854e                	mv	a0,s3
    8000415c:	fffff097          	auipc	ra,0xfffff
    80004160:	dc6080e7          	jalr	-570(ra) # 80002f22 <brelse>
    brelse(to);
    80004164:	8526                	mv	a0,s1
    80004166:	fffff097          	auipc	ra,0xfffff
    8000416a:	dbc080e7          	jalr	-580(ra) # 80002f22 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416e:	2905                	addiw	s2,s2,1
    80004170:	0a91                	addi	s5,s5,4
    80004172:	02ca2783          	lw	a5,44(s4)
    80004176:	f8f94ee3          	blt	s2,a5,80004112 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000417a:	00000097          	auipc	ra,0x0
    8000417e:	c6a080e7          	jalr	-918(ra) # 80003de4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004182:	4501                	li	a0,0
    80004184:	00000097          	auipc	ra,0x0
    80004188:	cda080e7          	jalr	-806(ra) # 80003e5e <install_trans>
    log.lh.n = 0;
    8000418c:	0001d797          	auipc	a5,0x1d
    80004190:	1007a823          	sw	zero,272(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004194:	00000097          	auipc	ra,0x0
    80004198:	c50080e7          	jalr	-944(ra) # 80003de4 <write_head>
    8000419c:	bdf5                	j	80004098 <end_op+0x52>

000000008000419e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000419e:	1101                	addi	sp,sp,-32
    800041a0:	ec06                	sd	ra,24(sp)
    800041a2:	e822                	sd	s0,16(sp)
    800041a4:	e426                	sd	s1,8(sp)
    800041a6:	e04a                	sd	s2,0(sp)
    800041a8:	1000                	addi	s0,sp,32
    800041aa:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041ac:	0001d917          	auipc	s2,0x1d
    800041b0:	0c490913          	addi	s2,s2,196 # 80021270 <log>
    800041b4:	854a                	mv	a0,s2
    800041b6:	ffffd097          	auipc	ra,0xffffd
    800041ba:	a20080e7          	jalr	-1504(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041be:	02c92603          	lw	a2,44(s2)
    800041c2:	47f5                	li	a5,29
    800041c4:	06c7c563          	blt	a5,a2,8000422e <log_write+0x90>
    800041c8:	0001d797          	auipc	a5,0x1d
    800041cc:	0c47a783          	lw	a5,196(a5) # 8002128c <log+0x1c>
    800041d0:	37fd                	addiw	a5,a5,-1
    800041d2:	04f65e63          	bge	a2,a5,8000422e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041d6:	0001d797          	auipc	a5,0x1d
    800041da:	0ba7a783          	lw	a5,186(a5) # 80021290 <log+0x20>
    800041de:	06f05063          	blez	a5,8000423e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800041e2:	4781                	li	a5,0
    800041e4:	06c05563          	blez	a2,8000424e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800041e8:	44cc                	lw	a1,12(s1)
    800041ea:	0001d717          	auipc	a4,0x1d
    800041ee:	0b670713          	addi	a4,a4,182 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800041f2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800041f4:	4314                	lw	a3,0(a4)
    800041f6:	04b68c63          	beq	a3,a1,8000424e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800041fa:	2785                	addiw	a5,a5,1
    800041fc:	0711                	addi	a4,a4,4
    800041fe:	fef61be3          	bne	a2,a5,800041f4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004202:	0621                	addi	a2,a2,8
    80004204:	060a                	slli	a2,a2,0x2
    80004206:	0001d797          	auipc	a5,0x1d
    8000420a:	06a78793          	addi	a5,a5,106 # 80021270 <log>
    8000420e:	963e                	add	a2,a2,a5
    80004210:	44dc                	lw	a5,12(s1)
    80004212:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004214:	8526                	mv	a0,s1
    80004216:	fffff097          	auipc	ra,0xfffff
    8000421a:	daa080e7          	jalr	-598(ra) # 80002fc0 <bpin>
    log.lh.n++;
    8000421e:	0001d717          	auipc	a4,0x1d
    80004222:	05270713          	addi	a4,a4,82 # 80021270 <log>
    80004226:	575c                	lw	a5,44(a4)
    80004228:	2785                	addiw	a5,a5,1
    8000422a:	d75c                	sw	a5,44(a4)
    8000422c:	a835                	j	80004268 <log_write+0xca>
    panic("too big a transaction");
    8000422e:	00004517          	auipc	a0,0x4
    80004232:	3fa50513          	addi	a0,a0,1018 # 80008628 <syscalls+0x1f8>
    80004236:	ffffc097          	auipc	ra,0xffffc
    8000423a:	2fa080e7          	jalr	762(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    8000423e:	00004517          	auipc	a0,0x4
    80004242:	40250513          	addi	a0,a0,1026 # 80008640 <syscalls+0x210>
    80004246:	ffffc097          	auipc	ra,0xffffc
    8000424a:	2ea080e7          	jalr	746(ra) # 80000530 <panic>
  log.lh.block[i] = b->blockno;
    8000424e:	00878713          	addi	a4,a5,8
    80004252:	00271693          	slli	a3,a4,0x2
    80004256:	0001d717          	auipc	a4,0x1d
    8000425a:	01a70713          	addi	a4,a4,26 # 80021270 <log>
    8000425e:	9736                	add	a4,a4,a3
    80004260:	44d4                	lw	a3,12(s1)
    80004262:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004264:	faf608e3          	beq	a2,a5,80004214 <log_write+0x76>
  }
  release(&log.lock);
    80004268:	0001d517          	auipc	a0,0x1d
    8000426c:	00850513          	addi	a0,a0,8 # 80021270 <log>
    80004270:	ffffd097          	auipc	ra,0xffffd
    80004274:	a1a080e7          	jalr	-1510(ra) # 80000c8a <release>
}
    80004278:	60e2                	ld	ra,24(sp)
    8000427a:	6442                	ld	s0,16(sp)
    8000427c:	64a2                	ld	s1,8(sp)
    8000427e:	6902                	ld	s2,0(sp)
    80004280:	6105                	addi	sp,sp,32
    80004282:	8082                	ret

0000000080004284 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004284:	1101                	addi	sp,sp,-32
    80004286:	ec06                	sd	ra,24(sp)
    80004288:	e822                	sd	s0,16(sp)
    8000428a:	e426                	sd	s1,8(sp)
    8000428c:	e04a                	sd	s2,0(sp)
    8000428e:	1000                	addi	s0,sp,32
    80004290:	84aa                	mv	s1,a0
    80004292:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004294:	00004597          	auipc	a1,0x4
    80004298:	3cc58593          	addi	a1,a1,972 # 80008660 <syscalls+0x230>
    8000429c:	0521                	addi	a0,a0,8
    8000429e:	ffffd097          	auipc	ra,0xffffd
    800042a2:	8a8080e7          	jalr	-1880(ra) # 80000b46 <initlock>
  lk->name = name;
    800042a6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042aa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042ae:	0204a423          	sw	zero,40(s1)
}
    800042b2:	60e2                	ld	ra,24(sp)
    800042b4:	6442                	ld	s0,16(sp)
    800042b6:	64a2                	ld	s1,8(sp)
    800042b8:	6902                	ld	s2,0(sp)
    800042ba:	6105                	addi	sp,sp,32
    800042bc:	8082                	ret

00000000800042be <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042be:	1101                	addi	sp,sp,-32
    800042c0:	ec06                	sd	ra,24(sp)
    800042c2:	e822                	sd	s0,16(sp)
    800042c4:	e426                	sd	s1,8(sp)
    800042c6:	e04a                	sd	s2,0(sp)
    800042c8:	1000                	addi	s0,sp,32
    800042ca:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042cc:	00850913          	addi	s2,a0,8
    800042d0:	854a                	mv	a0,s2
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	904080e7          	jalr	-1788(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800042da:	409c                	lw	a5,0(s1)
    800042dc:	cb89                	beqz	a5,800042ee <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042de:	85ca                	mv	a1,s2
    800042e0:	8526                	mv	a0,s1
    800042e2:	ffffe097          	auipc	ra,0xffffe
    800042e6:	d6e080e7          	jalr	-658(ra) # 80002050 <sleep>
  while (lk->locked) {
    800042ea:	409c                	lw	a5,0(s1)
    800042ec:	fbed                	bnez	a5,800042de <acquiresleep+0x20>
  }
  lk->locked = 1;
    800042ee:	4785                	li	a5,1
    800042f0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	6a2080e7          	jalr	1698(ra) # 80001994 <myproc>
    800042fa:	591c                	lw	a5,48(a0)
    800042fc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800042fe:	854a                	mv	a0,s2
    80004300:	ffffd097          	auipc	ra,0xffffd
    80004304:	98a080e7          	jalr	-1654(ra) # 80000c8a <release>
}
    80004308:	60e2                	ld	ra,24(sp)
    8000430a:	6442                	ld	s0,16(sp)
    8000430c:	64a2                	ld	s1,8(sp)
    8000430e:	6902                	ld	s2,0(sp)
    80004310:	6105                	addi	sp,sp,32
    80004312:	8082                	ret

0000000080004314 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004314:	1101                	addi	sp,sp,-32
    80004316:	ec06                	sd	ra,24(sp)
    80004318:	e822                	sd	s0,16(sp)
    8000431a:	e426                	sd	s1,8(sp)
    8000431c:	e04a                	sd	s2,0(sp)
    8000431e:	1000                	addi	s0,sp,32
    80004320:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004322:	00850913          	addi	s2,a0,8
    80004326:	854a                	mv	a0,s2
    80004328:	ffffd097          	auipc	ra,0xffffd
    8000432c:	8ae080e7          	jalr	-1874(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004330:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004334:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004338:	8526                	mv	a0,s1
    8000433a:	ffffe097          	auipc	ra,0xffffe
    8000433e:	ea2080e7          	jalr	-350(ra) # 800021dc <wakeup>
  release(&lk->lk);
    80004342:	854a                	mv	a0,s2
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	946080e7          	jalr	-1722(ra) # 80000c8a <release>
}
    8000434c:	60e2                	ld	ra,24(sp)
    8000434e:	6442                	ld	s0,16(sp)
    80004350:	64a2                	ld	s1,8(sp)
    80004352:	6902                	ld	s2,0(sp)
    80004354:	6105                	addi	sp,sp,32
    80004356:	8082                	ret

0000000080004358 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004358:	7179                	addi	sp,sp,-48
    8000435a:	f406                	sd	ra,40(sp)
    8000435c:	f022                	sd	s0,32(sp)
    8000435e:	ec26                	sd	s1,24(sp)
    80004360:	e84a                	sd	s2,16(sp)
    80004362:	e44e                	sd	s3,8(sp)
    80004364:	1800                	addi	s0,sp,48
    80004366:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004368:	00850913          	addi	s2,a0,8
    8000436c:	854a                	mv	a0,s2
    8000436e:	ffffd097          	auipc	ra,0xffffd
    80004372:	868080e7          	jalr	-1944(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004376:	409c                	lw	a5,0(s1)
    80004378:	ef99                	bnez	a5,80004396 <holdingsleep+0x3e>
    8000437a:	4481                	li	s1,0
  release(&lk->lk);
    8000437c:	854a                	mv	a0,s2
    8000437e:	ffffd097          	auipc	ra,0xffffd
    80004382:	90c080e7          	jalr	-1780(ra) # 80000c8a <release>
  return r;
}
    80004386:	8526                	mv	a0,s1
    80004388:	70a2                	ld	ra,40(sp)
    8000438a:	7402                	ld	s0,32(sp)
    8000438c:	64e2                	ld	s1,24(sp)
    8000438e:	6942                	ld	s2,16(sp)
    80004390:	69a2                	ld	s3,8(sp)
    80004392:	6145                	addi	sp,sp,48
    80004394:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004396:	0284a983          	lw	s3,40(s1)
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	5fa080e7          	jalr	1530(ra) # 80001994 <myproc>
    800043a2:	5904                	lw	s1,48(a0)
    800043a4:	413484b3          	sub	s1,s1,s3
    800043a8:	0014b493          	seqz	s1,s1
    800043ac:	bfc1                	j	8000437c <holdingsleep+0x24>

00000000800043ae <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043ae:	1141                	addi	sp,sp,-16
    800043b0:	e406                	sd	ra,8(sp)
    800043b2:	e022                	sd	s0,0(sp)
    800043b4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043b6:	00004597          	auipc	a1,0x4
    800043ba:	2ba58593          	addi	a1,a1,698 # 80008670 <syscalls+0x240>
    800043be:	0001d517          	auipc	a0,0x1d
    800043c2:	ffa50513          	addi	a0,a0,-6 # 800213b8 <ftable>
    800043c6:	ffffc097          	auipc	ra,0xffffc
    800043ca:	780080e7          	jalr	1920(ra) # 80000b46 <initlock>
}
    800043ce:	60a2                	ld	ra,8(sp)
    800043d0:	6402                	ld	s0,0(sp)
    800043d2:	0141                	addi	sp,sp,16
    800043d4:	8082                	ret

00000000800043d6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043d6:	1101                	addi	sp,sp,-32
    800043d8:	ec06                	sd	ra,24(sp)
    800043da:	e822                	sd	s0,16(sp)
    800043dc:	e426                	sd	s1,8(sp)
    800043de:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043e0:	0001d517          	auipc	a0,0x1d
    800043e4:	fd850513          	addi	a0,a0,-40 # 800213b8 <ftable>
    800043e8:	ffffc097          	auipc	ra,0xffffc
    800043ec:	7ee080e7          	jalr	2030(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043f0:	0001d497          	auipc	s1,0x1d
    800043f4:	fe048493          	addi	s1,s1,-32 # 800213d0 <ftable+0x18>
    800043f8:	0001e717          	auipc	a4,0x1e
    800043fc:	f7870713          	addi	a4,a4,-136 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    80004400:	40dc                	lw	a5,4(s1)
    80004402:	cf99                	beqz	a5,80004420 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004404:	02848493          	addi	s1,s1,40
    80004408:	fee49ce3          	bne	s1,a4,80004400 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000440c:	0001d517          	auipc	a0,0x1d
    80004410:	fac50513          	addi	a0,a0,-84 # 800213b8 <ftable>
    80004414:	ffffd097          	auipc	ra,0xffffd
    80004418:	876080e7          	jalr	-1930(ra) # 80000c8a <release>
  return 0;
    8000441c:	4481                	li	s1,0
    8000441e:	a819                	j	80004434 <filealloc+0x5e>
      f->ref = 1;
    80004420:	4785                	li	a5,1
    80004422:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004424:	0001d517          	auipc	a0,0x1d
    80004428:	f9450513          	addi	a0,a0,-108 # 800213b8 <ftable>
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	85e080e7          	jalr	-1954(ra) # 80000c8a <release>
}
    80004434:	8526                	mv	a0,s1
    80004436:	60e2                	ld	ra,24(sp)
    80004438:	6442                	ld	s0,16(sp)
    8000443a:	64a2                	ld	s1,8(sp)
    8000443c:	6105                	addi	sp,sp,32
    8000443e:	8082                	ret

0000000080004440 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004440:	1101                	addi	sp,sp,-32
    80004442:	ec06                	sd	ra,24(sp)
    80004444:	e822                	sd	s0,16(sp)
    80004446:	e426                	sd	s1,8(sp)
    80004448:	1000                	addi	s0,sp,32
    8000444a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000444c:	0001d517          	auipc	a0,0x1d
    80004450:	f6c50513          	addi	a0,a0,-148 # 800213b8 <ftable>
    80004454:	ffffc097          	auipc	ra,0xffffc
    80004458:	782080e7          	jalr	1922(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000445c:	40dc                	lw	a5,4(s1)
    8000445e:	02f05263          	blez	a5,80004482 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004462:	2785                	addiw	a5,a5,1
    80004464:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004466:	0001d517          	auipc	a0,0x1d
    8000446a:	f5250513          	addi	a0,a0,-174 # 800213b8 <ftable>
    8000446e:	ffffd097          	auipc	ra,0xffffd
    80004472:	81c080e7          	jalr	-2020(ra) # 80000c8a <release>
  return f;
}
    80004476:	8526                	mv	a0,s1
    80004478:	60e2                	ld	ra,24(sp)
    8000447a:	6442                	ld	s0,16(sp)
    8000447c:	64a2                	ld	s1,8(sp)
    8000447e:	6105                	addi	sp,sp,32
    80004480:	8082                	ret
    panic("filedup");
    80004482:	00004517          	auipc	a0,0x4
    80004486:	1f650513          	addi	a0,a0,502 # 80008678 <syscalls+0x248>
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	0a6080e7          	jalr	166(ra) # 80000530 <panic>

0000000080004492 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004492:	7139                	addi	sp,sp,-64
    80004494:	fc06                	sd	ra,56(sp)
    80004496:	f822                	sd	s0,48(sp)
    80004498:	f426                	sd	s1,40(sp)
    8000449a:	f04a                	sd	s2,32(sp)
    8000449c:	ec4e                	sd	s3,24(sp)
    8000449e:	e852                	sd	s4,16(sp)
    800044a0:	e456                	sd	s5,8(sp)
    800044a2:	0080                	addi	s0,sp,64
    800044a4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800044a6:	0001d517          	auipc	a0,0x1d
    800044aa:	f1250513          	addi	a0,a0,-238 # 800213b8 <ftable>
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	728080e7          	jalr	1832(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800044b6:	40dc                	lw	a5,4(s1)
    800044b8:	06f05163          	blez	a5,8000451a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044bc:	37fd                	addiw	a5,a5,-1
    800044be:	0007871b          	sext.w	a4,a5
    800044c2:	c0dc                	sw	a5,4(s1)
    800044c4:	06e04363          	bgtz	a4,8000452a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044c8:	0004a903          	lw	s2,0(s1)
    800044cc:	0094ca83          	lbu	s5,9(s1)
    800044d0:	0104ba03          	ld	s4,16(s1)
    800044d4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044d8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044dc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044e0:	0001d517          	auipc	a0,0x1d
    800044e4:	ed850513          	addi	a0,a0,-296 # 800213b8 <ftable>
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	7a2080e7          	jalr	1954(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800044f0:	4785                	li	a5,1
    800044f2:	04f90d63          	beq	s2,a5,8000454c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800044f6:	3979                	addiw	s2,s2,-2
    800044f8:	4785                	li	a5,1
    800044fa:	0527e063          	bltu	a5,s2,8000453a <fileclose+0xa8>
    begin_op();
    800044fe:	00000097          	auipc	ra,0x0
    80004502:	ac8080e7          	jalr	-1336(ra) # 80003fc6 <begin_op>
    iput(ff.ip);
    80004506:	854e                	mv	a0,s3
    80004508:	fffff097          	auipc	ra,0xfffff
    8000450c:	2a6080e7          	jalr	678(ra) # 800037ae <iput>
    end_op();
    80004510:	00000097          	auipc	ra,0x0
    80004514:	b36080e7          	jalr	-1226(ra) # 80004046 <end_op>
    80004518:	a00d                	j	8000453a <fileclose+0xa8>
    panic("fileclose");
    8000451a:	00004517          	auipc	a0,0x4
    8000451e:	16650513          	addi	a0,a0,358 # 80008680 <syscalls+0x250>
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	00e080e7          	jalr	14(ra) # 80000530 <panic>
    release(&ftable.lock);
    8000452a:	0001d517          	auipc	a0,0x1d
    8000452e:	e8e50513          	addi	a0,a0,-370 # 800213b8 <ftable>
    80004532:	ffffc097          	auipc	ra,0xffffc
    80004536:	758080e7          	jalr	1880(ra) # 80000c8a <release>
  }
}
    8000453a:	70e2                	ld	ra,56(sp)
    8000453c:	7442                	ld	s0,48(sp)
    8000453e:	74a2                	ld	s1,40(sp)
    80004540:	7902                	ld	s2,32(sp)
    80004542:	69e2                	ld	s3,24(sp)
    80004544:	6a42                	ld	s4,16(sp)
    80004546:	6aa2                	ld	s5,8(sp)
    80004548:	6121                	addi	sp,sp,64
    8000454a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000454c:	85d6                	mv	a1,s5
    8000454e:	8552                	mv	a0,s4
    80004550:	00000097          	auipc	ra,0x0
    80004554:	34c080e7          	jalr	844(ra) # 8000489c <pipeclose>
    80004558:	b7cd                	j	8000453a <fileclose+0xa8>

000000008000455a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000455a:	715d                	addi	sp,sp,-80
    8000455c:	e486                	sd	ra,72(sp)
    8000455e:	e0a2                	sd	s0,64(sp)
    80004560:	fc26                	sd	s1,56(sp)
    80004562:	f84a                	sd	s2,48(sp)
    80004564:	f44e                	sd	s3,40(sp)
    80004566:	0880                	addi	s0,sp,80
    80004568:	84aa                	mv	s1,a0
    8000456a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000456c:	ffffd097          	auipc	ra,0xffffd
    80004570:	428080e7          	jalr	1064(ra) # 80001994 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004574:	409c                	lw	a5,0(s1)
    80004576:	37f9                	addiw	a5,a5,-2
    80004578:	4705                	li	a4,1
    8000457a:	04f76763          	bltu	a4,a5,800045c8 <filestat+0x6e>
    8000457e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004580:	6c88                	ld	a0,24(s1)
    80004582:	fffff097          	auipc	ra,0xfffff
    80004586:	072080e7          	jalr	114(ra) # 800035f4 <ilock>
    stati(f->ip, &st);
    8000458a:	fb840593          	addi	a1,s0,-72
    8000458e:	6c88                	ld	a0,24(s1)
    80004590:	fffff097          	auipc	ra,0xfffff
    80004594:	2ee080e7          	jalr	750(ra) # 8000387e <stati>
    iunlock(f->ip);
    80004598:	6c88                	ld	a0,24(s1)
    8000459a:	fffff097          	auipc	ra,0xfffff
    8000459e:	11c080e7          	jalr	284(ra) # 800036b6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045a2:	46e1                	li	a3,24
    800045a4:	fb840613          	addi	a2,s0,-72
    800045a8:	85ce                	mv	a1,s3
    800045aa:	05093503          	ld	a0,80(s2)
    800045ae:	ffffd097          	auipc	ra,0xffffd
    800045b2:	0a8080e7          	jalr	168(ra) # 80001656 <copyout>
    800045b6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045ba:	60a6                	ld	ra,72(sp)
    800045bc:	6406                	ld	s0,64(sp)
    800045be:	74e2                	ld	s1,56(sp)
    800045c0:	7942                	ld	s2,48(sp)
    800045c2:	79a2                	ld	s3,40(sp)
    800045c4:	6161                	addi	sp,sp,80
    800045c6:	8082                	ret
  return -1;
    800045c8:	557d                	li	a0,-1
    800045ca:	bfc5                	j	800045ba <filestat+0x60>

00000000800045cc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045cc:	7179                	addi	sp,sp,-48
    800045ce:	f406                	sd	ra,40(sp)
    800045d0:	f022                	sd	s0,32(sp)
    800045d2:	ec26                	sd	s1,24(sp)
    800045d4:	e84a                	sd	s2,16(sp)
    800045d6:	e44e                	sd	s3,8(sp)
    800045d8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045da:	00854783          	lbu	a5,8(a0)
    800045de:	c3d5                	beqz	a5,80004682 <fileread+0xb6>
    800045e0:	84aa                	mv	s1,a0
    800045e2:	89ae                	mv	s3,a1
    800045e4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045e6:	411c                	lw	a5,0(a0)
    800045e8:	4705                	li	a4,1
    800045ea:	04e78963          	beq	a5,a4,8000463c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045ee:	470d                	li	a4,3
    800045f0:	04e78d63          	beq	a5,a4,8000464a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800045f4:	4709                	li	a4,2
    800045f6:	06e79e63          	bne	a5,a4,80004672 <fileread+0xa6>
    ilock(f->ip);
    800045fa:	6d08                	ld	a0,24(a0)
    800045fc:	fffff097          	auipc	ra,0xfffff
    80004600:	ff8080e7          	jalr	-8(ra) # 800035f4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004604:	874a                	mv	a4,s2
    80004606:	5094                	lw	a3,32(s1)
    80004608:	864e                	mv	a2,s3
    8000460a:	4585                	li	a1,1
    8000460c:	6c88                	ld	a0,24(s1)
    8000460e:	fffff097          	auipc	ra,0xfffff
    80004612:	29a080e7          	jalr	666(ra) # 800038a8 <readi>
    80004616:	892a                	mv	s2,a0
    80004618:	00a05563          	blez	a0,80004622 <fileread+0x56>
      f->off += r;
    8000461c:	509c                	lw	a5,32(s1)
    8000461e:	9fa9                	addw	a5,a5,a0
    80004620:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004622:	6c88                	ld	a0,24(s1)
    80004624:	fffff097          	auipc	ra,0xfffff
    80004628:	092080e7          	jalr	146(ra) # 800036b6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000462c:	854a                	mv	a0,s2
    8000462e:	70a2                	ld	ra,40(sp)
    80004630:	7402                	ld	s0,32(sp)
    80004632:	64e2                	ld	s1,24(sp)
    80004634:	6942                	ld	s2,16(sp)
    80004636:	69a2                	ld	s3,8(sp)
    80004638:	6145                	addi	sp,sp,48
    8000463a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000463c:	6908                	ld	a0,16(a0)
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	3c8080e7          	jalr	968(ra) # 80004a06 <piperead>
    80004646:	892a                	mv	s2,a0
    80004648:	b7d5                	j	8000462c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000464a:	02451783          	lh	a5,36(a0)
    8000464e:	03079693          	slli	a3,a5,0x30
    80004652:	92c1                	srli	a3,a3,0x30
    80004654:	4725                	li	a4,9
    80004656:	02d76863          	bltu	a4,a3,80004686 <fileread+0xba>
    8000465a:	0792                	slli	a5,a5,0x4
    8000465c:	0001d717          	auipc	a4,0x1d
    80004660:	cbc70713          	addi	a4,a4,-836 # 80021318 <devsw>
    80004664:	97ba                	add	a5,a5,a4
    80004666:	639c                	ld	a5,0(a5)
    80004668:	c38d                	beqz	a5,8000468a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000466a:	4505                	li	a0,1
    8000466c:	9782                	jalr	a5
    8000466e:	892a                	mv	s2,a0
    80004670:	bf75                	j	8000462c <fileread+0x60>
    panic("fileread");
    80004672:	00004517          	auipc	a0,0x4
    80004676:	01e50513          	addi	a0,a0,30 # 80008690 <syscalls+0x260>
    8000467a:	ffffc097          	auipc	ra,0xffffc
    8000467e:	eb6080e7          	jalr	-330(ra) # 80000530 <panic>
    return -1;
    80004682:	597d                	li	s2,-1
    80004684:	b765                	j	8000462c <fileread+0x60>
      return -1;
    80004686:	597d                	li	s2,-1
    80004688:	b755                	j	8000462c <fileread+0x60>
    8000468a:	597d                	li	s2,-1
    8000468c:	b745                	j	8000462c <fileread+0x60>

000000008000468e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000468e:	715d                	addi	sp,sp,-80
    80004690:	e486                	sd	ra,72(sp)
    80004692:	e0a2                	sd	s0,64(sp)
    80004694:	fc26                	sd	s1,56(sp)
    80004696:	f84a                	sd	s2,48(sp)
    80004698:	f44e                	sd	s3,40(sp)
    8000469a:	f052                	sd	s4,32(sp)
    8000469c:	ec56                	sd	s5,24(sp)
    8000469e:	e85a                	sd	s6,16(sp)
    800046a0:	e45e                	sd	s7,8(sp)
    800046a2:	e062                	sd	s8,0(sp)
    800046a4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800046a6:	00954783          	lbu	a5,9(a0)
    800046aa:	10078663          	beqz	a5,800047b6 <filewrite+0x128>
    800046ae:	892a                	mv	s2,a0
    800046b0:	8aae                	mv	s5,a1
    800046b2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800046b4:	411c                	lw	a5,0(a0)
    800046b6:	4705                	li	a4,1
    800046b8:	02e78263          	beq	a5,a4,800046dc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046bc:	470d                	li	a4,3
    800046be:	02e78663          	beq	a5,a4,800046ea <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046c2:	4709                	li	a4,2
    800046c4:	0ee79163          	bne	a5,a4,800047a6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046c8:	0ac05d63          	blez	a2,80004782 <filewrite+0xf4>
    int i = 0;
    800046cc:	4981                	li	s3,0
    800046ce:	6b05                	lui	s6,0x1
    800046d0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800046d4:	6b85                	lui	s7,0x1
    800046d6:	c00b8b9b          	addiw	s7,s7,-1024
    800046da:	a861                	j	80004772 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800046dc:	6908                	ld	a0,16(a0)
    800046de:	00000097          	auipc	ra,0x0
    800046e2:	22e080e7          	jalr	558(ra) # 8000490c <pipewrite>
    800046e6:	8a2a                	mv	s4,a0
    800046e8:	a045                	j	80004788 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800046ea:	02451783          	lh	a5,36(a0)
    800046ee:	03079693          	slli	a3,a5,0x30
    800046f2:	92c1                	srli	a3,a3,0x30
    800046f4:	4725                	li	a4,9
    800046f6:	0cd76263          	bltu	a4,a3,800047ba <filewrite+0x12c>
    800046fa:	0792                	slli	a5,a5,0x4
    800046fc:	0001d717          	auipc	a4,0x1d
    80004700:	c1c70713          	addi	a4,a4,-996 # 80021318 <devsw>
    80004704:	97ba                	add	a5,a5,a4
    80004706:	679c                	ld	a5,8(a5)
    80004708:	cbdd                	beqz	a5,800047be <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000470a:	4505                	li	a0,1
    8000470c:	9782                	jalr	a5
    8000470e:	8a2a                	mv	s4,a0
    80004710:	a8a5                	j	80004788 <filewrite+0xfa>
    80004712:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004716:	00000097          	auipc	ra,0x0
    8000471a:	8b0080e7          	jalr	-1872(ra) # 80003fc6 <begin_op>
      ilock(f->ip);
    8000471e:	01893503          	ld	a0,24(s2)
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	ed2080e7          	jalr	-302(ra) # 800035f4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000472a:	8762                	mv	a4,s8
    8000472c:	02092683          	lw	a3,32(s2)
    80004730:	01598633          	add	a2,s3,s5
    80004734:	4585                	li	a1,1
    80004736:	01893503          	ld	a0,24(s2)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	266080e7          	jalr	614(ra) # 800039a0 <writei>
    80004742:	84aa                	mv	s1,a0
    80004744:	00a05763          	blez	a0,80004752 <filewrite+0xc4>
        f->off += r;
    80004748:	02092783          	lw	a5,32(s2)
    8000474c:	9fa9                	addw	a5,a5,a0
    8000474e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004752:	01893503          	ld	a0,24(s2)
    80004756:	fffff097          	auipc	ra,0xfffff
    8000475a:	f60080e7          	jalr	-160(ra) # 800036b6 <iunlock>
      end_op();
    8000475e:	00000097          	auipc	ra,0x0
    80004762:	8e8080e7          	jalr	-1816(ra) # 80004046 <end_op>

      if(r != n1){
    80004766:	009c1f63          	bne	s8,s1,80004784 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000476a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000476e:	0149db63          	bge	s3,s4,80004784 <filewrite+0xf6>
      int n1 = n - i;
    80004772:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004776:	84be                	mv	s1,a5
    80004778:	2781                	sext.w	a5,a5
    8000477a:	f8fb5ce3          	bge	s6,a5,80004712 <filewrite+0x84>
    8000477e:	84de                	mv	s1,s7
    80004780:	bf49                	j	80004712 <filewrite+0x84>
    int i = 0;
    80004782:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004784:	013a1f63          	bne	s4,s3,800047a2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004788:	8552                	mv	a0,s4
    8000478a:	60a6                	ld	ra,72(sp)
    8000478c:	6406                	ld	s0,64(sp)
    8000478e:	74e2                	ld	s1,56(sp)
    80004790:	7942                	ld	s2,48(sp)
    80004792:	79a2                	ld	s3,40(sp)
    80004794:	7a02                	ld	s4,32(sp)
    80004796:	6ae2                	ld	s5,24(sp)
    80004798:	6b42                	ld	s6,16(sp)
    8000479a:	6ba2                	ld	s7,8(sp)
    8000479c:	6c02                	ld	s8,0(sp)
    8000479e:	6161                	addi	sp,sp,80
    800047a0:	8082                	ret
    ret = (i == n ? n : -1);
    800047a2:	5a7d                	li	s4,-1
    800047a4:	b7d5                	j	80004788 <filewrite+0xfa>
    panic("filewrite");
    800047a6:	00004517          	auipc	a0,0x4
    800047aa:	efa50513          	addi	a0,a0,-262 # 800086a0 <syscalls+0x270>
    800047ae:	ffffc097          	auipc	ra,0xffffc
    800047b2:	d82080e7          	jalr	-638(ra) # 80000530 <panic>
    return -1;
    800047b6:	5a7d                	li	s4,-1
    800047b8:	bfc1                	j	80004788 <filewrite+0xfa>
      return -1;
    800047ba:	5a7d                	li	s4,-1
    800047bc:	b7f1                	j	80004788 <filewrite+0xfa>
    800047be:	5a7d                	li	s4,-1
    800047c0:	b7e1                	j	80004788 <filewrite+0xfa>

00000000800047c2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047c2:	7179                	addi	sp,sp,-48
    800047c4:	f406                	sd	ra,40(sp)
    800047c6:	f022                	sd	s0,32(sp)
    800047c8:	ec26                	sd	s1,24(sp)
    800047ca:	e84a                	sd	s2,16(sp)
    800047cc:	e44e                	sd	s3,8(sp)
    800047ce:	e052                	sd	s4,0(sp)
    800047d0:	1800                	addi	s0,sp,48
    800047d2:	84aa                	mv	s1,a0
    800047d4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047d6:	0005b023          	sd	zero,0(a1)
    800047da:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047de:	00000097          	auipc	ra,0x0
    800047e2:	bf8080e7          	jalr	-1032(ra) # 800043d6 <filealloc>
    800047e6:	e088                	sd	a0,0(s1)
    800047e8:	c551                	beqz	a0,80004874 <pipealloc+0xb2>
    800047ea:	00000097          	auipc	ra,0x0
    800047ee:	bec080e7          	jalr	-1044(ra) # 800043d6 <filealloc>
    800047f2:	00aa3023          	sd	a0,0(s4)
    800047f6:	c92d                	beqz	a0,80004868 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047f8:	ffffc097          	auipc	ra,0xffffc
    800047fc:	2ee080e7          	jalr	750(ra) # 80000ae6 <kalloc>
    80004800:	892a                	mv	s2,a0
    80004802:	c125                	beqz	a0,80004862 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004804:	4985                	li	s3,1
    80004806:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000480a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000480e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004812:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004816:	00004597          	auipc	a1,0x4
    8000481a:	e9a58593          	addi	a1,a1,-358 # 800086b0 <syscalls+0x280>
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	328080e7          	jalr	808(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004826:	609c                	ld	a5,0(s1)
    80004828:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000482c:	609c                	ld	a5,0(s1)
    8000482e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004832:	609c                	ld	a5,0(s1)
    80004834:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004838:	609c                	ld	a5,0(s1)
    8000483a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000483e:	000a3783          	ld	a5,0(s4)
    80004842:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004846:	000a3783          	ld	a5,0(s4)
    8000484a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000484e:	000a3783          	ld	a5,0(s4)
    80004852:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004856:	000a3783          	ld	a5,0(s4)
    8000485a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000485e:	4501                	li	a0,0
    80004860:	a025                	j	80004888 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004862:	6088                	ld	a0,0(s1)
    80004864:	e501                	bnez	a0,8000486c <pipealloc+0xaa>
    80004866:	a039                	j	80004874 <pipealloc+0xb2>
    80004868:	6088                	ld	a0,0(s1)
    8000486a:	c51d                	beqz	a0,80004898 <pipealloc+0xd6>
    fileclose(*f0);
    8000486c:	00000097          	auipc	ra,0x0
    80004870:	c26080e7          	jalr	-986(ra) # 80004492 <fileclose>
  if(*f1)
    80004874:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004878:	557d                	li	a0,-1
  if(*f1)
    8000487a:	c799                	beqz	a5,80004888 <pipealloc+0xc6>
    fileclose(*f1);
    8000487c:	853e                	mv	a0,a5
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	c14080e7          	jalr	-1004(ra) # 80004492 <fileclose>
  return -1;
    80004886:	557d                	li	a0,-1
}
    80004888:	70a2                	ld	ra,40(sp)
    8000488a:	7402                	ld	s0,32(sp)
    8000488c:	64e2                	ld	s1,24(sp)
    8000488e:	6942                	ld	s2,16(sp)
    80004890:	69a2                	ld	s3,8(sp)
    80004892:	6a02                	ld	s4,0(sp)
    80004894:	6145                	addi	sp,sp,48
    80004896:	8082                	ret
  return -1;
    80004898:	557d                	li	a0,-1
    8000489a:	b7fd                	j	80004888 <pipealloc+0xc6>

000000008000489c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000489c:	1101                	addi	sp,sp,-32
    8000489e:	ec06                	sd	ra,24(sp)
    800048a0:	e822                	sd	s0,16(sp)
    800048a2:	e426                	sd	s1,8(sp)
    800048a4:	e04a                	sd	s2,0(sp)
    800048a6:	1000                	addi	s0,sp,32
    800048a8:	84aa                	mv	s1,a0
    800048aa:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	32a080e7          	jalr	810(ra) # 80000bd6 <acquire>
  if(writable){
    800048b4:	02090d63          	beqz	s2,800048ee <pipeclose+0x52>
    pi->writeopen = 0;
    800048b8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048bc:	21848513          	addi	a0,s1,536
    800048c0:	ffffe097          	auipc	ra,0xffffe
    800048c4:	91c080e7          	jalr	-1764(ra) # 800021dc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048c8:	2204b783          	ld	a5,544(s1)
    800048cc:	eb95                	bnez	a5,80004900 <pipeclose+0x64>
    release(&pi->lock);
    800048ce:	8526                	mv	a0,s1
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	3ba080e7          	jalr	954(ra) # 80000c8a <release>
    kfree((char*)pi);
    800048d8:	8526                	mv	a0,s1
    800048da:	ffffc097          	auipc	ra,0xffffc
    800048de:	110080e7          	jalr	272(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    800048e2:	60e2                	ld	ra,24(sp)
    800048e4:	6442                	ld	s0,16(sp)
    800048e6:	64a2                	ld	s1,8(sp)
    800048e8:	6902                	ld	s2,0(sp)
    800048ea:	6105                	addi	sp,sp,32
    800048ec:	8082                	ret
    pi->readopen = 0;
    800048ee:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048f2:	21c48513          	addi	a0,s1,540
    800048f6:	ffffe097          	auipc	ra,0xffffe
    800048fa:	8e6080e7          	jalr	-1818(ra) # 800021dc <wakeup>
    800048fe:	b7e9                	j	800048c8 <pipeclose+0x2c>
    release(&pi->lock);
    80004900:	8526                	mv	a0,s1
    80004902:	ffffc097          	auipc	ra,0xffffc
    80004906:	388080e7          	jalr	904(ra) # 80000c8a <release>
}
    8000490a:	bfe1                	j	800048e2 <pipeclose+0x46>

000000008000490c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000490c:	7159                	addi	sp,sp,-112
    8000490e:	f486                	sd	ra,104(sp)
    80004910:	f0a2                	sd	s0,96(sp)
    80004912:	eca6                	sd	s1,88(sp)
    80004914:	e8ca                	sd	s2,80(sp)
    80004916:	e4ce                	sd	s3,72(sp)
    80004918:	e0d2                	sd	s4,64(sp)
    8000491a:	fc56                	sd	s5,56(sp)
    8000491c:	f85a                	sd	s6,48(sp)
    8000491e:	f45e                	sd	s7,40(sp)
    80004920:	f062                	sd	s8,32(sp)
    80004922:	ec66                	sd	s9,24(sp)
    80004924:	1880                	addi	s0,sp,112
    80004926:	84aa                	mv	s1,a0
    80004928:	8aae                	mv	s5,a1
    8000492a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000492c:	ffffd097          	auipc	ra,0xffffd
    80004930:	068080e7          	jalr	104(ra) # 80001994 <myproc>
    80004934:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004936:	8526                	mv	a0,s1
    80004938:	ffffc097          	auipc	ra,0xffffc
    8000493c:	29e080e7          	jalr	670(ra) # 80000bd6 <acquire>
  while(i < n){
    80004940:	0d405163          	blez	s4,80004a02 <pipewrite+0xf6>
    80004944:	8ba6                	mv	s7,s1
  int i = 0;
    80004946:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004948:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000494a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000494e:	21c48c13          	addi	s8,s1,540
    80004952:	a08d                	j	800049b4 <pipewrite+0xa8>
      release(&pi->lock);
    80004954:	8526                	mv	a0,s1
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	334080e7          	jalr	820(ra) # 80000c8a <release>
      return -1;
    8000495e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004960:	854a                	mv	a0,s2
    80004962:	70a6                	ld	ra,104(sp)
    80004964:	7406                	ld	s0,96(sp)
    80004966:	64e6                	ld	s1,88(sp)
    80004968:	6946                	ld	s2,80(sp)
    8000496a:	69a6                	ld	s3,72(sp)
    8000496c:	6a06                	ld	s4,64(sp)
    8000496e:	7ae2                	ld	s5,56(sp)
    80004970:	7b42                	ld	s6,48(sp)
    80004972:	7ba2                	ld	s7,40(sp)
    80004974:	7c02                	ld	s8,32(sp)
    80004976:	6ce2                	ld	s9,24(sp)
    80004978:	6165                	addi	sp,sp,112
    8000497a:	8082                	ret
      wakeup(&pi->nread);
    8000497c:	8566                	mv	a0,s9
    8000497e:	ffffe097          	auipc	ra,0xffffe
    80004982:	85e080e7          	jalr	-1954(ra) # 800021dc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004986:	85de                	mv	a1,s7
    80004988:	8562                	mv	a0,s8
    8000498a:	ffffd097          	auipc	ra,0xffffd
    8000498e:	6c6080e7          	jalr	1734(ra) # 80002050 <sleep>
    80004992:	a839                	j	800049b0 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004994:	21c4a783          	lw	a5,540(s1)
    80004998:	0017871b          	addiw	a4,a5,1
    8000499c:	20e4ae23          	sw	a4,540(s1)
    800049a0:	1ff7f793          	andi	a5,a5,511
    800049a4:	97a6                	add	a5,a5,s1
    800049a6:	f9f44703          	lbu	a4,-97(s0)
    800049aa:	00e78c23          	sb	a4,24(a5)
      i++;
    800049ae:	2905                	addiw	s2,s2,1
  while(i < n){
    800049b0:	03495d63          	bge	s2,s4,800049ea <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800049b4:	2204a783          	lw	a5,544(s1)
    800049b8:	dfd1                	beqz	a5,80004954 <pipewrite+0x48>
    800049ba:	0289a783          	lw	a5,40(s3)
    800049be:	fbd9                	bnez	a5,80004954 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800049c0:	2184a783          	lw	a5,536(s1)
    800049c4:	21c4a703          	lw	a4,540(s1)
    800049c8:	2007879b          	addiw	a5,a5,512
    800049cc:	faf708e3          	beq	a4,a5,8000497c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049d0:	4685                	li	a3,1
    800049d2:	01590633          	add	a2,s2,s5
    800049d6:	f9f40593          	addi	a1,s0,-97
    800049da:	0509b503          	ld	a0,80(s3)
    800049de:	ffffd097          	auipc	ra,0xffffd
    800049e2:	d04080e7          	jalr	-764(ra) # 800016e2 <copyin>
    800049e6:	fb6517e3          	bne	a0,s6,80004994 <pipewrite+0x88>
  wakeup(&pi->nread);
    800049ea:	21848513          	addi	a0,s1,536
    800049ee:	ffffd097          	auipc	ra,0xffffd
    800049f2:	7ee080e7          	jalr	2030(ra) # 800021dc <wakeup>
  release(&pi->lock);
    800049f6:	8526                	mv	a0,s1
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	292080e7          	jalr	658(ra) # 80000c8a <release>
  return i;
    80004a00:	b785                	j	80004960 <pipewrite+0x54>
  int i = 0;
    80004a02:	4901                	li	s2,0
    80004a04:	b7dd                	j	800049ea <pipewrite+0xde>

0000000080004a06 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a06:	715d                	addi	sp,sp,-80
    80004a08:	e486                	sd	ra,72(sp)
    80004a0a:	e0a2                	sd	s0,64(sp)
    80004a0c:	fc26                	sd	s1,56(sp)
    80004a0e:	f84a                	sd	s2,48(sp)
    80004a10:	f44e                	sd	s3,40(sp)
    80004a12:	f052                	sd	s4,32(sp)
    80004a14:	ec56                	sd	s5,24(sp)
    80004a16:	e85a                	sd	s6,16(sp)
    80004a18:	0880                	addi	s0,sp,80
    80004a1a:	84aa                	mv	s1,a0
    80004a1c:	892e                	mv	s2,a1
    80004a1e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a20:	ffffd097          	auipc	ra,0xffffd
    80004a24:	f74080e7          	jalr	-140(ra) # 80001994 <myproc>
    80004a28:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a2a:	8b26                	mv	s6,s1
    80004a2c:	8526                	mv	a0,s1
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	1a8080e7          	jalr	424(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a36:	2184a703          	lw	a4,536(s1)
    80004a3a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a3e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a42:	02f71463          	bne	a4,a5,80004a6a <piperead+0x64>
    80004a46:	2244a783          	lw	a5,548(s1)
    80004a4a:	c385                	beqz	a5,80004a6a <piperead+0x64>
    if(pr->killed){
    80004a4c:	028a2783          	lw	a5,40(s4)
    80004a50:	ebc1                	bnez	a5,80004ae0 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a52:	85da                	mv	a1,s6
    80004a54:	854e                	mv	a0,s3
    80004a56:	ffffd097          	auipc	ra,0xffffd
    80004a5a:	5fa080e7          	jalr	1530(ra) # 80002050 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a5e:	2184a703          	lw	a4,536(s1)
    80004a62:	21c4a783          	lw	a5,540(s1)
    80004a66:	fef700e3          	beq	a4,a5,80004a46 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a6a:	09505263          	blez	s5,80004aee <piperead+0xe8>
    80004a6e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a70:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004a72:	2184a783          	lw	a5,536(s1)
    80004a76:	21c4a703          	lw	a4,540(s1)
    80004a7a:	02f70d63          	beq	a4,a5,80004ab4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a7e:	0017871b          	addiw	a4,a5,1
    80004a82:	20e4ac23          	sw	a4,536(s1)
    80004a86:	1ff7f793          	andi	a5,a5,511
    80004a8a:	97a6                	add	a5,a5,s1
    80004a8c:	0187c783          	lbu	a5,24(a5)
    80004a90:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a94:	4685                	li	a3,1
    80004a96:	fbf40613          	addi	a2,s0,-65
    80004a9a:	85ca                	mv	a1,s2
    80004a9c:	050a3503          	ld	a0,80(s4)
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	bb6080e7          	jalr	-1098(ra) # 80001656 <copyout>
    80004aa8:	01650663          	beq	a0,s6,80004ab4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aac:	2985                	addiw	s3,s3,1
    80004aae:	0905                	addi	s2,s2,1
    80004ab0:	fd3a91e3          	bne	s5,s3,80004a72 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ab4:	21c48513          	addi	a0,s1,540
    80004ab8:	ffffd097          	auipc	ra,0xffffd
    80004abc:	724080e7          	jalr	1828(ra) # 800021dc <wakeup>
  release(&pi->lock);
    80004ac0:	8526                	mv	a0,s1
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	1c8080e7          	jalr	456(ra) # 80000c8a <release>
  return i;
}
    80004aca:	854e                	mv	a0,s3
    80004acc:	60a6                	ld	ra,72(sp)
    80004ace:	6406                	ld	s0,64(sp)
    80004ad0:	74e2                	ld	s1,56(sp)
    80004ad2:	7942                	ld	s2,48(sp)
    80004ad4:	79a2                	ld	s3,40(sp)
    80004ad6:	7a02                	ld	s4,32(sp)
    80004ad8:	6ae2                	ld	s5,24(sp)
    80004ada:	6b42                	ld	s6,16(sp)
    80004adc:	6161                	addi	sp,sp,80
    80004ade:	8082                	ret
      release(&pi->lock);
    80004ae0:	8526                	mv	a0,s1
    80004ae2:	ffffc097          	auipc	ra,0xffffc
    80004ae6:	1a8080e7          	jalr	424(ra) # 80000c8a <release>
      return -1;
    80004aea:	59fd                	li	s3,-1
    80004aec:	bff9                	j	80004aca <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aee:	4981                	li	s3,0
    80004af0:	b7d1                	j	80004ab4 <piperead+0xae>

0000000080004af2 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004af2:	df010113          	addi	sp,sp,-528
    80004af6:	20113423          	sd	ra,520(sp)
    80004afa:	20813023          	sd	s0,512(sp)
    80004afe:	ffa6                	sd	s1,504(sp)
    80004b00:	fbca                	sd	s2,496(sp)
    80004b02:	f7ce                	sd	s3,488(sp)
    80004b04:	f3d2                	sd	s4,480(sp)
    80004b06:	efd6                	sd	s5,472(sp)
    80004b08:	ebda                	sd	s6,464(sp)
    80004b0a:	e7de                	sd	s7,456(sp)
    80004b0c:	e3e2                	sd	s8,448(sp)
    80004b0e:	ff66                	sd	s9,440(sp)
    80004b10:	fb6a                	sd	s10,432(sp)
    80004b12:	f76e                	sd	s11,424(sp)
    80004b14:	0c00                	addi	s0,sp,528
    80004b16:	84aa                	mv	s1,a0
    80004b18:	dea43c23          	sd	a0,-520(s0)
    80004b1c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b20:	ffffd097          	auipc	ra,0xffffd
    80004b24:	e74080e7          	jalr	-396(ra) # 80001994 <myproc>
    80004b28:	892a                	mv	s2,a0

  begin_op();
    80004b2a:	fffff097          	auipc	ra,0xfffff
    80004b2e:	49c080e7          	jalr	1180(ra) # 80003fc6 <begin_op>

  if((ip = namei(path)) == 0){
    80004b32:	8526                	mv	a0,s1
    80004b34:	fffff097          	auipc	ra,0xfffff
    80004b38:	276080e7          	jalr	630(ra) # 80003daa <namei>
    80004b3c:	c92d                	beqz	a0,80004bae <exec+0xbc>
    80004b3e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b40:	fffff097          	auipc	ra,0xfffff
    80004b44:	ab4080e7          	jalr	-1356(ra) # 800035f4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b48:	04000713          	li	a4,64
    80004b4c:	4681                	li	a3,0
    80004b4e:	e4840613          	addi	a2,s0,-440
    80004b52:	4581                	li	a1,0
    80004b54:	8526                	mv	a0,s1
    80004b56:	fffff097          	auipc	ra,0xfffff
    80004b5a:	d52080e7          	jalr	-686(ra) # 800038a8 <readi>
    80004b5e:	04000793          	li	a5,64
    80004b62:	00f51a63          	bne	a0,a5,80004b76 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b66:	e4842703          	lw	a4,-440(s0)
    80004b6a:	464c47b7          	lui	a5,0x464c4
    80004b6e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b72:	04f70463          	beq	a4,a5,80004bba <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b76:	8526                	mv	a0,s1
    80004b78:	fffff097          	auipc	ra,0xfffff
    80004b7c:	cde080e7          	jalr	-802(ra) # 80003856 <iunlockput>
    end_op();
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	4c6080e7          	jalr	1222(ra) # 80004046 <end_op>
  }
  return -1;
    80004b88:	557d                	li	a0,-1
}
    80004b8a:	20813083          	ld	ra,520(sp)
    80004b8e:	20013403          	ld	s0,512(sp)
    80004b92:	74fe                	ld	s1,504(sp)
    80004b94:	795e                	ld	s2,496(sp)
    80004b96:	79be                	ld	s3,488(sp)
    80004b98:	7a1e                	ld	s4,480(sp)
    80004b9a:	6afe                	ld	s5,472(sp)
    80004b9c:	6b5e                	ld	s6,464(sp)
    80004b9e:	6bbe                	ld	s7,456(sp)
    80004ba0:	6c1e                	ld	s8,448(sp)
    80004ba2:	7cfa                	ld	s9,440(sp)
    80004ba4:	7d5a                	ld	s10,432(sp)
    80004ba6:	7dba                	ld	s11,424(sp)
    80004ba8:	21010113          	addi	sp,sp,528
    80004bac:	8082                	ret
    end_op();
    80004bae:	fffff097          	auipc	ra,0xfffff
    80004bb2:	498080e7          	jalr	1176(ra) # 80004046 <end_op>
    return -1;
    80004bb6:	557d                	li	a0,-1
    80004bb8:	bfc9                	j	80004b8a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bba:	854a                	mv	a0,s2
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	e9c080e7          	jalr	-356(ra) # 80001a58 <proc_pagetable>
    80004bc4:	8baa                	mv	s7,a0
    80004bc6:	d945                	beqz	a0,80004b76 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bc8:	e6842983          	lw	s3,-408(s0)
    80004bcc:	e8045783          	lhu	a5,-384(s0)
    80004bd0:	c7ad                	beqz	a5,80004c3a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004bd2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bd4:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004bd6:	6c85                	lui	s9,0x1
    80004bd8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004bdc:	def43823          	sd	a5,-528(s0)
    80004be0:	a42d                	j	80004e0a <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004be2:	00004517          	auipc	a0,0x4
    80004be6:	ad650513          	addi	a0,a0,-1322 # 800086b8 <syscalls+0x288>
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	946080e7          	jalr	-1722(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004bf2:	8756                	mv	a4,s5
    80004bf4:	012d86bb          	addw	a3,s11,s2
    80004bf8:	4581                	li	a1,0
    80004bfa:	8526                	mv	a0,s1
    80004bfc:	fffff097          	auipc	ra,0xfffff
    80004c00:	cac080e7          	jalr	-852(ra) # 800038a8 <readi>
    80004c04:	2501                	sext.w	a0,a0
    80004c06:	1aaa9963          	bne	s5,a0,80004db8 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004c0a:	6785                	lui	a5,0x1
    80004c0c:	0127893b          	addw	s2,a5,s2
    80004c10:	77fd                	lui	a5,0xfffff
    80004c12:	01478a3b          	addw	s4,a5,s4
    80004c16:	1f897163          	bgeu	s2,s8,80004df8 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004c1a:	02091593          	slli	a1,s2,0x20
    80004c1e:	9181                	srli	a1,a1,0x20
    80004c20:	95ea                	add	a1,a1,s10
    80004c22:	855e                	mv	a0,s7
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	440080e7          	jalr	1088(ra) # 80001064 <walkaddr>
    80004c2c:	862a                	mv	a2,a0
    if(pa == 0)
    80004c2e:	d955                	beqz	a0,80004be2 <exec+0xf0>
      n = PGSIZE;
    80004c30:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004c32:	fd9a70e3          	bgeu	s4,s9,80004bf2 <exec+0x100>
      n = sz - i;
    80004c36:	8ad2                	mv	s5,s4
    80004c38:	bf6d                	j	80004bf2 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c3a:	4901                	li	s2,0
  iunlockput(ip);
    80004c3c:	8526                	mv	a0,s1
    80004c3e:	fffff097          	auipc	ra,0xfffff
    80004c42:	c18080e7          	jalr	-1000(ra) # 80003856 <iunlockput>
  end_op();
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	400080e7          	jalr	1024(ra) # 80004046 <end_op>
  p = myproc();
    80004c4e:	ffffd097          	auipc	ra,0xffffd
    80004c52:	d46080e7          	jalr	-698(ra) # 80001994 <myproc>
    80004c56:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004c58:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c5c:	6785                	lui	a5,0x1
    80004c5e:	17fd                	addi	a5,a5,-1
    80004c60:	993e                	add	s2,s2,a5
    80004c62:	757d                	lui	a0,0xfffff
    80004c64:	00a977b3          	and	a5,s2,a0
    80004c68:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c6c:	6609                	lui	a2,0x2
    80004c6e:	963e                	add	a2,a2,a5
    80004c70:	85be                	mv	a1,a5
    80004c72:	855e                	mv	a0,s7
    80004c74:	ffffc097          	auipc	ra,0xffffc
    80004c78:	792080e7          	jalr	1938(ra) # 80001406 <uvmalloc>
    80004c7c:	8b2a                	mv	s6,a0
  ip = 0;
    80004c7e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c80:	12050c63          	beqz	a0,80004db8 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004c84:	75f9                	lui	a1,0xffffe
    80004c86:	95aa                	add	a1,a1,a0
    80004c88:	855e                	mv	a0,s7
    80004c8a:	ffffd097          	auipc	ra,0xffffd
    80004c8e:	99a080e7          	jalr	-1638(ra) # 80001624 <uvmclear>
  stackbase = sp - PGSIZE;
    80004c92:	7c7d                	lui	s8,0xfffff
    80004c94:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004c96:	e0043783          	ld	a5,-512(s0)
    80004c9a:	6388                	ld	a0,0(a5)
    80004c9c:	c535                	beqz	a0,80004d08 <exec+0x216>
    80004c9e:	e8840993          	addi	s3,s0,-376
    80004ca2:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004ca6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ca8:	ffffc097          	auipc	ra,0xffffc
    80004cac:	1b2080e7          	jalr	434(ra) # 80000e5a <strlen>
    80004cb0:	2505                	addiw	a0,a0,1
    80004cb2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004cb6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004cba:	13896363          	bltu	s2,s8,80004de0 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004cbe:	e0043d83          	ld	s11,-512(s0)
    80004cc2:	000dba03          	ld	s4,0(s11)
    80004cc6:	8552                	mv	a0,s4
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	192080e7          	jalr	402(ra) # 80000e5a <strlen>
    80004cd0:	0015069b          	addiw	a3,a0,1
    80004cd4:	8652                	mv	a2,s4
    80004cd6:	85ca                	mv	a1,s2
    80004cd8:	855e                	mv	a0,s7
    80004cda:	ffffd097          	auipc	ra,0xffffd
    80004cde:	97c080e7          	jalr	-1668(ra) # 80001656 <copyout>
    80004ce2:	10054363          	bltz	a0,80004de8 <exec+0x2f6>
    ustack[argc] = sp;
    80004ce6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004cea:	0485                	addi	s1,s1,1
    80004cec:	008d8793          	addi	a5,s11,8
    80004cf0:	e0f43023          	sd	a5,-512(s0)
    80004cf4:	008db503          	ld	a0,8(s11)
    80004cf8:	c911                	beqz	a0,80004d0c <exec+0x21a>
    if(argc >= MAXARG)
    80004cfa:	09a1                	addi	s3,s3,8
    80004cfc:	fb3c96e3          	bne	s9,s3,80004ca8 <exec+0x1b6>
  sz = sz1;
    80004d00:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d04:	4481                	li	s1,0
    80004d06:	a84d                	j	80004db8 <exec+0x2c6>
  sp = sz;
    80004d08:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d0a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d0c:	00349793          	slli	a5,s1,0x3
    80004d10:	f9040713          	addi	a4,s0,-112
    80004d14:	97ba                	add	a5,a5,a4
    80004d16:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004d1a:	00148693          	addi	a3,s1,1
    80004d1e:	068e                	slli	a3,a3,0x3
    80004d20:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d24:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d28:	01897663          	bgeu	s2,s8,80004d34 <exec+0x242>
  sz = sz1;
    80004d2c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d30:	4481                	li	s1,0
    80004d32:	a059                	j	80004db8 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d34:	e8840613          	addi	a2,s0,-376
    80004d38:	85ca                	mv	a1,s2
    80004d3a:	855e                	mv	a0,s7
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	91a080e7          	jalr	-1766(ra) # 80001656 <copyout>
    80004d44:	0a054663          	bltz	a0,80004df0 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004d48:	058ab783          	ld	a5,88(s5)
    80004d4c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004d50:	df843783          	ld	a5,-520(s0)
    80004d54:	0007c703          	lbu	a4,0(a5)
    80004d58:	cf11                	beqz	a4,80004d74 <exec+0x282>
    80004d5a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d5c:	02f00693          	li	a3,47
    80004d60:	a029                	j	80004d6a <exec+0x278>
  for(last=s=path; *s; s++)
    80004d62:	0785                	addi	a5,a5,1
    80004d64:	fff7c703          	lbu	a4,-1(a5)
    80004d68:	c711                	beqz	a4,80004d74 <exec+0x282>
    if(*s == '/')
    80004d6a:	fed71ce3          	bne	a4,a3,80004d62 <exec+0x270>
      last = s+1;
    80004d6e:	def43c23          	sd	a5,-520(s0)
    80004d72:	bfc5                	j	80004d62 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d74:	4641                	li	a2,16
    80004d76:	df843583          	ld	a1,-520(s0)
    80004d7a:	158a8513          	addi	a0,s5,344
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	0aa080e7          	jalr	170(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    80004d86:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004d8a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004d8e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004d92:	058ab783          	ld	a5,88(s5)
    80004d96:	e6043703          	ld	a4,-416(s0)
    80004d9a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004d9c:	058ab783          	ld	a5,88(s5)
    80004da0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004da4:	85ea                	mv	a1,s10
    80004da6:	ffffd097          	auipc	ra,0xffffd
    80004daa:	d4e080e7          	jalr	-690(ra) # 80001af4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004dae:	0004851b          	sext.w	a0,s1
    80004db2:	bbe1                	j	80004b8a <exec+0x98>
    80004db4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004db8:	e0843583          	ld	a1,-504(s0)
    80004dbc:	855e                	mv	a0,s7
    80004dbe:	ffffd097          	auipc	ra,0xffffd
    80004dc2:	d36080e7          	jalr	-714(ra) # 80001af4 <proc_freepagetable>
  if(ip){
    80004dc6:	da0498e3          	bnez	s1,80004b76 <exec+0x84>
  return -1;
    80004dca:	557d                	li	a0,-1
    80004dcc:	bb7d                	j	80004b8a <exec+0x98>
    80004dce:	e1243423          	sd	s2,-504(s0)
    80004dd2:	b7dd                	j	80004db8 <exec+0x2c6>
    80004dd4:	e1243423          	sd	s2,-504(s0)
    80004dd8:	b7c5                	j	80004db8 <exec+0x2c6>
    80004dda:	e1243423          	sd	s2,-504(s0)
    80004dde:	bfe9                	j	80004db8 <exec+0x2c6>
  sz = sz1;
    80004de0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004de4:	4481                	li	s1,0
    80004de6:	bfc9                	j	80004db8 <exec+0x2c6>
  sz = sz1;
    80004de8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004dec:	4481                	li	s1,0
    80004dee:	b7e9                	j	80004db8 <exec+0x2c6>
  sz = sz1;
    80004df0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004df4:	4481                	li	s1,0
    80004df6:	b7c9                	j	80004db8 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004df8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dfc:	2b05                	addiw	s6,s6,1
    80004dfe:	0389899b          	addiw	s3,s3,56
    80004e02:	e8045783          	lhu	a5,-384(s0)
    80004e06:	e2fb5be3          	bge	s6,a5,80004c3c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e0a:	2981                	sext.w	s3,s3
    80004e0c:	03800713          	li	a4,56
    80004e10:	86ce                	mv	a3,s3
    80004e12:	e1040613          	addi	a2,s0,-496
    80004e16:	4581                	li	a1,0
    80004e18:	8526                	mv	a0,s1
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	a8e080e7          	jalr	-1394(ra) # 800038a8 <readi>
    80004e22:	03800793          	li	a5,56
    80004e26:	f8f517e3          	bne	a0,a5,80004db4 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004e2a:	e1042783          	lw	a5,-496(s0)
    80004e2e:	4705                	li	a4,1
    80004e30:	fce796e3          	bne	a5,a4,80004dfc <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004e34:	e3843603          	ld	a2,-456(s0)
    80004e38:	e3043783          	ld	a5,-464(s0)
    80004e3c:	f8f669e3          	bltu	a2,a5,80004dce <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e40:	e2043783          	ld	a5,-480(s0)
    80004e44:	963e                	add	a2,a2,a5
    80004e46:	f8f667e3          	bltu	a2,a5,80004dd4 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e4a:	85ca                	mv	a1,s2
    80004e4c:	855e                	mv	a0,s7
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	5b8080e7          	jalr	1464(ra) # 80001406 <uvmalloc>
    80004e56:	e0a43423          	sd	a0,-504(s0)
    80004e5a:	d141                	beqz	a0,80004dda <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004e5c:	e2043d03          	ld	s10,-480(s0)
    80004e60:	df043783          	ld	a5,-528(s0)
    80004e64:	00fd77b3          	and	a5,s10,a5
    80004e68:	fba1                	bnez	a5,80004db8 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e6a:	e1842d83          	lw	s11,-488(s0)
    80004e6e:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e72:	f80c03e3          	beqz	s8,80004df8 <exec+0x306>
    80004e76:	8a62                	mv	s4,s8
    80004e78:	4901                	li	s2,0
    80004e7a:	b345                	j	80004c1a <exec+0x128>

0000000080004e7c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004e7c:	7179                	addi	sp,sp,-48
    80004e7e:	f406                	sd	ra,40(sp)
    80004e80:	f022                	sd	s0,32(sp)
    80004e82:	ec26                	sd	s1,24(sp)
    80004e84:	e84a                	sd	s2,16(sp)
    80004e86:	1800                	addi	s0,sp,48
    80004e88:	892e                	mv	s2,a1
    80004e8a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004e8c:	fdc40593          	addi	a1,s0,-36
    80004e90:	ffffe097          	auipc	ra,0xffffe
    80004e94:	bb0080e7          	jalr	-1104(ra) # 80002a40 <argint>
    80004e98:	04054063          	bltz	a0,80004ed8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004e9c:	fdc42703          	lw	a4,-36(s0)
    80004ea0:	47bd                	li	a5,15
    80004ea2:	02e7ed63          	bltu	a5,a4,80004edc <argfd+0x60>
    80004ea6:	ffffd097          	auipc	ra,0xffffd
    80004eaa:	aee080e7          	jalr	-1298(ra) # 80001994 <myproc>
    80004eae:	fdc42703          	lw	a4,-36(s0)
    80004eb2:	01a70793          	addi	a5,a4,26
    80004eb6:	078e                	slli	a5,a5,0x3
    80004eb8:	953e                	add	a0,a0,a5
    80004eba:	611c                	ld	a5,0(a0)
    80004ebc:	c395                	beqz	a5,80004ee0 <argfd+0x64>
    return -1;
  if(pfd)
    80004ebe:	00090463          	beqz	s2,80004ec6 <argfd+0x4a>
    *pfd = fd;
    80004ec2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ec6:	4501                	li	a0,0
  if(pf)
    80004ec8:	c091                	beqz	s1,80004ecc <argfd+0x50>
    *pf = f;
    80004eca:	e09c                	sd	a5,0(s1)
}
    80004ecc:	70a2                	ld	ra,40(sp)
    80004ece:	7402                	ld	s0,32(sp)
    80004ed0:	64e2                	ld	s1,24(sp)
    80004ed2:	6942                	ld	s2,16(sp)
    80004ed4:	6145                	addi	sp,sp,48
    80004ed6:	8082                	ret
    return -1;
    80004ed8:	557d                	li	a0,-1
    80004eda:	bfcd                	j	80004ecc <argfd+0x50>
    return -1;
    80004edc:	557d                	li	a0,-1
    80004ede:	b7fd                	j	80004ecc <argfd+0x50>
    80004ee0:	557d                	li	a0,-1
    80004ee2:	b7ed                	j	80004ecc <argfd+0x50>

0000000080004ee4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004ee4:	1101                	addi	sp,sp,-32
    80004ee6:	ec06                	sd	ra,24(sp)
    80004ee8:	e822                	sd	s0,16(sp)
    80004eea:	e426                	sd	s1,8(sp)
    80004eec:	1000                	addi	s0,sp,32
    80004eee:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004ef0:	ffffd097          	auipc	ra,0xffffd
    80004ef4:	aa4080e7          	jalr	-1372(ra) # 80001994 <myproc>
    80004ef8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004efa:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004efe:	4501                	li	a0,0
    80004f00:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004f02:	6398                	ld	a4,0(a5)
    80004f04:	cb19                	beqz	a4,80004f1a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f06:	2505                	addiw	a0,a0,1
    80004f08:	07a1                	addi	a5,a5,8
    80004f0a:	fed51ce3          	bne	a0,a3,80004f02 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f0e:	557d                	li	a0,-1
}
    80004f10:	60e2                	ld	ra,24(sp)
    80004f12:	6442                	ld	s0,16(sp)
    80004f14:	64a2                	ld	s1,8(sp)
    80004f16:	6105                	addi	sp,sp,32
    80004f18:	8082                	ret
      p->ofile[fd] = f;
    80004f1a:	01a50793          	addi	a5,a0,26
    80004f1e:	078e                	slli	a5,a5,0x3
    80004f20:	963e                	add	a2,a2,a5
    80004f22:	e204                	sd	s1,0(a2)
      return fd;
    80004f24:	b7f5                	j	80004f10 <fdalloc+0x2c>

0000000080004f26 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f26:	715d                	addi	sp,sp,-80
    80004f28:	e486                	sd	ra,72(sp)
    80004f2a:	e0a2                	sd	s0,64(sp)
    80004f2c:	fc26                	sd	s1,56(sp)
    80004f2e:	f84a                	sd	s2,48(sp)
    80004f30:	f44e                	sd	s3,40(sp)
    80004f32:	f052                	sd	s4,32(sp)
    80004f34:	ec56                	sd	s5,24(sp)
    80004f36:	0880                	addi	s0,sp,80
    80004f38:	89ae                	mv	s3,a1
    80004f3a:	8ab2                	mv	s5,a2
    80004f3c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f3e:	fb040593          	addi	a1,s0,-80
    80004f42:	fffff097          	auipc	ra,0xfffff
    80004f46:	e86080e7          	jalr	-378(ra) # 80003dc8 <nameiparent>
    80004f4a:	892a                	mv	s2,a0
    80004f4c:	12050f63          	beqz	a0,8000508a <create+0x164>
    return 0;

  ilock(dp);
    80004f50:	ffffe097          	auipc	ra,0xffffe
    80004f54:	6a4080e7          	jalr	1700(ra) # 800035f4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f58:	4601                	li	a2,0
    80004f5a:	fb040593          	addi	a1,s0,-80
    80004f5e:	854a                	mv	a0,s2
    80004f60:	fffff097          	auipc	ra,0xfffff
    80004f64:	b78080e7          	jalr	-1160(ra) # 80003ad8 <dirlookup>
    80004f68:	84aa                	mv	s1,a0
    80004f6a:	c921                	beqz	a0,80004fba <create+0x94>
    iunlockput(dp);
    80004f6c:	854a                	mv	a0,s2
    80004f6e:	fffff097          	auipc	ra,0xfffff
    80004f72:	8e8080e7          	jalr	-1816(ra) # 80003856 <iunlockput>
    ilock(ip);
    80004f76:	8526                	mv	a0,s1
    80004f78:	ffffe097          	auipc	ra,0xffffe
    80004f7c:	67c080e7          	jalr	1660(ra) # 800035f4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004f80:	2981                	sext.w	s3,s3
    80004f82:	4789                	li	a5,2
    80004f84:	02f99463          	bne	s3,a5,80004fac <create+0x86>
    80004f88:	0444d783          	lhu	a5,68(s1)
    80004f8c:	37f9                	addiw	a5,a5,-2
    80004f8e:	17c2                	slli	a5,a5,0x30
    80004f90:	93c1                	srli	a5,a5,0x30
    80004f92:	4705                	li	a4,1
    80004f94:	00f76c63          	bltu	a4,a5,80004fac <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004f98:	8526                	mv	a0,s1
    80004f9a:	60a6                	ld	ra,72(sp)
    80004f9c:	6406                	ld	s0,64(sp)
    80004f9e:	74e2                	ld	s1,56(sp)
    80004fa0:	7942                	ld	s2,48(sp)
    80004fa2:	79a2                	ld	s3,40(sp)
    80004fa4:	7a02                	ld	s4,32(sp)
    80004fa6:	6ae2                	ld	s5,24(sp)
    80004fa8:	6161                	addi	sp,sp,80
    80004faa:	8082                	ret
    iunlockput(ip);
    80004fac:	8526                	mv	a0,s1
    80004fae:	fffff097          	auipc	ra,0xfffff
    80004fb2:	8a8080e7          	jalr	-1880(ra) # 80003856 <iunlockput>
    return 0;
    80004fb6:	4481                	li	s1,0
    80004fb8:	b7c5                	j	80004f98 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004fba:	85ce                	mv	a1,s3
    80004fbc:	00092503          	lw	a0,0(s2)
    80004fc0:	ffffe097          	auipc	ra,0xffffe
    80004fc4:	49c080e7          	jalr	1180(ra) # 8000345c <ialloc>
    80004fc8:	84aa                	mv	s1,a0
    80004fca:	c529                	beqz	a0,80005014 <create+0xee>
  ilock(ip);
    80004fcc:	ffffe097          	auipc	ra,0xffffe
    80004fd0:	628080e7          	jalr	1576(ra) # 800035f4 <ilock>
  ip->major = major;
    80004fd4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004fd8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80004fdc:	4785                	li	a5,1
    80004fde:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004fe2:	8526                	mv	a0,s1
    80004fe4:	ffffe097          	auipc	ra,0xffffe
    80004fe8:	546080e7          	jalr	1350(ra) # 8000352a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004fec:	2981                	sext.w	s3,s3
    80004fee:	4785                	li	a5,1
    80004ff0:	02f98a63          	beq	s3,a5,80005024 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80004ff4:	40d0                	lw	a2,4(s1)
    80004ff6:	fb040593          	addi	a1,s0,-80
    80004ffa:	854a                	mv	a0,s2
    80004ffc:	fffff097          	auipc	ra,0xfffff
    80005000:	cec080e7          	jalr	-788(ra) # 80003ce8 <dirlink>
    80005004:	06054b63          	bltz	a0,8000507a <create+0x154>
  iunlockput(dp);
    80005008:	854a                	mv	a0,s2
    8000500a:	fffff097          	auipc	ra,0xfffff
    8000500e:	84c080e7          	jalr	-1972(ra) # 80003856 <iunlockput>
  return ip;
    80005012:	b759                	j	80004f98 <create+0x72>
    panic("create: ialloc");
    80005014:	00003517          	auipc	a0,0x3
    80005018:	6c450513          	addi	a0,a0,1732 # 800086d8 <syscalls+0x2a8>
    8000501c:	ffffb097          	auipc	ra,0xffffb
    80005020:	514080e7          	jalr	1300(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    80005024:	04a95783          	lhu	a5,74(s2)
    80005028:	2785                	addiw	a5,a5,1
    8000502a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000502e:	854a                	mv	a0,s2
    80005030:	ffffe097          	auipc	ra,0xffffe
    80005034:	4fa080e7          	jalr	1274(ra) # 8000352a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005038:	40d0                	lw	a2,4(s1)
    8000503a:	00003597          	auipc	a1,0x3
    8000503e:	6ae58593          	addi	a1,a1,1710 # 800086e8 <syscalls+0x2b8>
    80005042:	8526                	mv	a0,s1
    80005044:	fffff097          	auipc	ra,0xfffff
    80005048:	ca4080e7          	jalr	-860(ra) # 80003ce8 <dirlink>
    8000504c:	00054f63          	bltz	a0,8000506a <create+0x144>
    80005050:	00492603          	lw	a2,4(s2)
    80005054:	00003597          	auipc	a1,0x3
    80005058:	69c58593          	addi	a1,a1,1692 # 800086f0 <syscalls+0x2c0>
    8000505c:	8526                	mv	a0,s1
    8000505e:	fffff097          	auipc	ra,0xfffff
    80005062:	c8a080e7          	jalr	-886(ra) # 80003ce8 <dirlink>
    80005066:	f80557e3          	bgez	a0,80004ff4 <create+0xce>
      panic("create dots");
    8000506a:	00003517          	auipc	a0,0x3
    8000506e:	68e50513          	addi	a0,a0,1678 # 800086f8 <syscalls+0x2c8>
    80005072:	ffffb097          	auipc	ra,0xffffb
    80005076:	4be080e7          	jalr	1214(ra) # 80000530 <panic>
    panic("create: dirlink");
    8000507a:	00003517          	auipc	a0,0x3
    8000507e:	68e50513          	addi	a0,a0,1678 # 80008708 <syscalls+0x2d8>
    80005082:	ffffb097          	auipc	ra,0xffffb
    80005086:	4ae080e7          	jalr	1198(ra) # 80000530 <panic>
    return 0;
    8000508a:	84aa                	mv	s1,a0
    8000508c:	b731                	j	80004f98 <create+0x72>

000000008000508e <sys_dup>:
{
    8000508e:	7179                	addi	sp,sp,-48
    80005090:	f406                	sd	ra,40(sp)
    80005092:	f022                	sd	s0,32(sp)
    80005094:	ec26                	sd	s1,24(sp)
    80005096:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005098:	fd840613          	addi	a2,s0,-40
    8000509c:	4581                	li	a1,0
    8000509e:	4501                	li	a0,0
    800050a0:	00000097          	auipc	ra,0x0
    800050a4:	ddc080e7          	jalr	-548(ra) # 80004e7c <argfd>
    return -1;
    800050a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050aa:	02054363          	bltz	a0,800050d0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800050ae:	fd843503          	ld	a0,-40(s0)
    800050b2:	00000097          	auipc	ra,0x0
    800050b6:	e32080e7          	jalr	-462(ra) # 80004ee4 <fdalloc>
    800050ba:	84aa                	mv	s1,a0
    return -1;
    800050bc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050be:	00054963          	bltz	a0,800050d0 <sys_dup+0x42>
  filedup(f);
    800050c2:	fd843503          	ld	a0,-40(s0)
    800050c6:	fffff097          	auipc	ra,0xfffff
    800050ca:	37a080e7          	jalr	890(ra) # 80004440 <filedup>
  return fd;
    800050ce:	87a6                	mv	a5,s1
}
    800050d0:	853e                	mv	a0,a5
    800050d2:	70a2                	ld	ra,40(sp)
    800050d4:	7402                	ld	s0,32(sp)
    800050d6:	64e2                	ld	s1,24(sp)
    800050d8:	6145                	addi	sp,sp,48
    800050da:	8082                	ret

00000000800050dc <sys_read>:
{
    800050dc:	7179                	addi	sp,sp,-48
    800050de:	f406                	sd	ra,40(sp)
    800050e0:	f022                	sd	s0,32(sp)
    800050e2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050e4:	fe840613          	addi	a2,s0,-24
    800050e8:	4581                	li	a1,0
    800050ea:	4501                	li	a0,0
    800050ec:	00000097          	auipc	ra,0x0
    800050f0:	d90080e7          	jalr	-624(ra) # 80004e7c <argfd>
    return -1;
    800050f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050f6:	04054163          	bltz	a0,80005138 <sys_read+0x5c>
    800050fa:	fe440593          	addi	a1,s0,-28
    800050fe:	4509                	li	a0,2
    80005100:	ffffe097          	auipc	ra,0xffffe
    80005104:	940080e7          	jalr	-1728(ra) # 80002a40 <argint>
    return -1;
    80005108:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000510a:	02054763          	bltz	a0,80005138 <sys_read+0x5c>
    8000510e:	fd840593          	addi	a1,s0,-40
    80005112:	4505                	li	a0,1
    80005114:	ffffe097          	auipc	ra,0xffffe
    80005118:	94e080e7          	jalr	-1714(ra) # 80002a62 <argaddr>
    return -1;
    8000511c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000511e:	00054d63          	bltz	a0,80005138 <sys_read+0x5c>
  return fileread(f, p, n);
    80005122:	fe442603          	lw	a2,-28(s0)
    80005126:	fd843583          	ld	a1,-40(s0)
    8000512a:	fe843503          	ld	a0,-24(s0)
    8000512e:	fffff097          	auipc	ra,0xfffff
    80005132:	49e080e7          	jalr	1182(ra) # 800045cc <fileread>
    80005136:	87aa                	mv	a5,a0
}
    80005138:	853e                	mv	a0,a5
    8000513a:	70a2                	ld	ra,40(sp)
    8000513c:	7402                	ld	s0,32(sp)
    8000513e:	6145                	addi	sp,sp,48
    80005140:	8082                	ret

0000000080005142 <sys_write>:
{
    80005142:	7179                	addi	sp,sp,-48
    80005144:	f406                	sd	ra,40(sp)
    80005146:	f022                	sd	s0,32(sp)
    80005148:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000514a:	fe840613          	addi	a2,s0,-24
    8000514e:	4581                	li	a1,0
    80005150:	4501                	li	a0,0
    80005152:	00000097          	auipc	ra,0x0
    80005156:	d2a080e7          	jalr	-726(ra) # 80004e7c <argfd>
    return -1;
    8000515a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000515c:	04054163          	bltz	a0,8000519e <sys_write+0x5c>
    80005160:	fe440593          	addi	a1,s0,-28
    80005164:	4509                	li	a0,2
    80005166:	ffffe097          	auipc	ra,0xffffe
    8000516a:	8da080e7          	jalr	-1830(ra) # 80002a40 <argint>
    return -1;
    8000516e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005170:	02054763          	bltz	a0,8000519e <sys_write+0x5c>
    80005174:	fd840593          	addi	a1,s0,-40
    80005178:	4505                	li	a0,1
    8000517a:	ffffe097          	auipc	ra,0xffffe
    8000517e:	8e8080e7          	jalr	-1816(ra) # 80002a62 <argaddr>
    return -1;
    80005182:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005184:	00054d63          	bltz	a0,8000519e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005188:	fe442603          	lw	a2,-28(s0)
    8000518c:	fd843583          	ld	a1,-40(s0)
    80005190:	fe843503          	ld	a0,-24(s0)
    80005194:	fffff097          	auipc	ra,0xfffff
    80005198:	4fa080e7          	jalr	1274(ra) # 8000468e <filewrite>
    8000519c:	87aa                	mv	a5,a0
}
    8000519e:	853e                	mv	a0,a5
    800051a0:	70a2                	ld	ra,40(sp)
    800051a2:	7402                	ld	s0,32(sp)
    800051a4:	6145                	addi	sp,sp,48
    800051a6:	8082                	ret

00000000800051a8 <sys_close>:
{
    800051a8:	1101                	addi	sp,sp,-32
    800051aa:	ec06                	sd	ra,24(sp)
    800051ac:	e822                	sd	s0,16(sp)
    800051ae:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051b0:	fe040613          	addi	a2,s0,-32
    800051b4:	fec40593          	addi	a1,s0,-20
    800051b8:	4501                	li	a0,0
    800051ba:	00000097          	auipc	ra,0x0
    800051be:	cc2080e7          	jalr	-830(ra) # 80004e7c <argfd>
    return -1;
    800051c2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051c4:	02054463          	bltz	a0,800051ec <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051c8:	ffffc097          	auipc	ra,0xffffc
    800051cc:	7cc080e7          	jalr	1996(ra) # 80001994 <myproc>
    800051d0:	fec42783          	lw	a5,-20(s0)
    800051d4:	07e9                	addi	a5,a5,26
    800051d6:	078e                	slli	a5,a5,0x3
    800051d8:	97aa                	add	a5,a5,a0
    800051da:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800051de:	fe043503          	ld	a0,-32(s0)
    800051e2:	fffff097          	auipc	ra,0xfffff
    800051e6:	2b0080e7          	jalr	688(ra) # 80004492 <fileclose>
  return 0;
    800051ea:	4781                	li	a5,0
}
    800051ec:	853e                	mv	a0,a5
    800051ee:	60e2                	ld	ra,24(sp)
    800051f0:	6442                	ld	s0,16(sp)
    800051f2:	6105                	addi	sp,sp,32
    800051f4:	8082                	ret

00000000800051f6 <sys_fstat>:
{
    800051f6:	1101                	addi	sp,sp,-32
    800051f8:	ec06                	sd	ra,24(sp)
    800051fa:	e822                	sd	s0,16(sp)
    800051fc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051fe:	fe840613          	addi	a2,s0,-24
    80005202:	4581                	li	a1,0
    80005204:	4501                	li	a0,0
    80005206:	00000097          	auipc	ra,0x0
    8000520a:	c76080e7          	jalr	-906(ra) # 80004e7c <argfd>
    return -1;
    8000520e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005210:	02054563          	bltz	a0,8000523a <sys_fstat+0x44>
    80005214:	fe040593          	addi	a1,s0,-32
    80005218:	4505                	li	a0,1
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	848080e7          	jalr	-1976(ra) # 80002a62 <argaddr>
    return -1;
    80005222:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005224:	00054b63          	bltz	a0,8000523a <sys_fstat+0x44>
  return filestat(f, st);
    80005228:	fe043583          	ld	a1,-32(s0)
    8000522c:	fe843503          	ld	a0,-24(s0)
    80005230:	fffff097          	auipc	ra,0xfffff
    80005234:	32a080e7          	jalr	810(ra) # 8000455a <filestat>
    80005238:	87aa                	mv	a5,a0
}
    8000523a:	853e                	mv	a0,a5
    8000523c:	60e2                	ld	ra,24(sp)
    8000523e:	6442                	ld	s0,16(sp)
    80005240:	6105                	addi	sp,sp,32
    80005242:	8082                	ret

0000000080005244 <sys_link>:
{
    80005244:	7169                	addi	sp,sp,-304
    80005246:	f606                	sd	ra,296(sp)
    80005248:	f222                	sd	s0,288(sp)
    8000524a:	ee26                	sd	s1,280(sp)
    8000524c:	ea4a                	sd	s2,272(sp)
    8000524e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005250:	08000613          	li	a2,128
    80005254:	ed040593          	addi	a1,s0,-304
    80005258:	4501                	li	a0,0
    8000525a:	ffffe097          	auipc	ra,0xffffe
    8000525e:	82a080e7          	jalr	-2006(ra) # 80002a84 <argstr>
    return -1;
    80005262:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005264:	10054e63          	bltz	a0,80005380 <sys_link+0x13c>
    80005268:	08000613          	li	a2,128
    8000526c:	f5040593          	addi	a1,s0,-176
    80005270:	4505                	li	a0,1
    80005272:	ffffe097          	auipc	ra,0xffffe
    80005276:	812080e7          	jalr	-2030(ra) # 80002a84 <argstr>
    return -1;
    8000527a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000527c:	10054263          	bltz	a0,80005380 <sys_link+0x13c>
  begin_op();
    80005280:	fffff097          	auipc	ra,0xfffff
    80005284:	d46080e7          	jalr	-698(ra) # 80003fc6 <begin_op>
  if((ip = namei(old)) == 0){
    80005288:	ed040513          	addi	a0,s0,-304
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	b1e080e7          	jalr	-1250(ra) # 80003daa <namei>
    80005294:	84aa                	mv	s1,a0
    80005296:	c551                	beqz	a0,80005322 <sys_link+0xde>
  ilock(ip);
    80005298:	ffffe097          	auipc	ra,0xffffe
    8000529c:	35c080e7          	jalr	860(ra) # 800035f4 <ilock>
  if(ip->type == T_DIR){
    800052a0:	04449703          	lh	a4,68(s1)
    800052a4:	4785                	li	a5,1
    800052a6:	08f70463          	beq	a4,a5,8000532e <sys_link+0xea>
  ip->nlink++;
    800052aa:	04a4d783          	lhu	a5,74(s1)
    800052ae:	2785                	addiw	a5,a5,1
    800052b0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052b4:	8526                	mv	a0,s1
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	274080e7          	jalr	628(ra) # 8000352a <iupdate>
  iunlock(ip);
    800052be:	8526                	mv	a0,s1
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	3f6080e7          	jalr	1014(ra) # 800036b6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052c8:	fd040593          	addi	a1,s0,-48
    800052cc:	f5040513          	addi	a0,s0,-176
    800052d0:	fffff097          	auipc	ra,0xfffff
    800052d4:	af8080e7          	jalr	-1288(ra) # 80003dc8 <nameiparent>
    800052d8:	892a                	mv	s2,a0
    800052da:	c935                	beqz	a0,8000534e <sys_link+0x10a>
  ilock(dp);
    800052dc:	ffffe097          	auipc	ra,0xffffe
    800052e0:	318080e7          	jalr	792(ra) # 800035f4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800052e4:	00092703          	lw	a4,0(s2)
    800052e8:	409c                	lw	a5,0(s1)
    800052ea:	04f71d63          	bne	a4,a5,80005344 <sys_link+0x100>
    800052ee:	40d0                	lw	a2,4(s1)
    800052f0:	fd040593          	addi	a1,s0,-48
    800052f4:	854a                	mv	a0,s2
    800052f6:	fffff097          	auipc	ra,0xfffff
    800052fa:	9f2080e7          	jalr	-1550(ra) # 80003ce8 <dirlink>
    800052fe:	04054363          	bltz	a0,80005344 <sys_link+0x100>
  iunlockput(dp);
    80005302:	854a                	mv	a0,s2
    80005304:	ffffe097          	auipc	ra,0xffffe
    80005308:	552080e7          	jalr	1362(ra) # 80003856 <iunlockput>
  iput(ip);
    8000530c:	8526                	mv	a0,s1
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	4a0080e7          	jalr	1184(ra) # 800037ae <iput>
  end_op();
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	d30080e7          	jalr	-720(ra) # 80004046 <end_op>
  return 0;
    8000531e:	4781                	li	a5,0
    80005320:	a085                	j	80005380 <sys_link+0x13c>
    end_op();
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	d24080e7          	jalr	-732(ra) # 80004046 <end_op>
    return -1;
    8000532a:	57fd                	li	a5,-1
    8000532c:	a891                	j	80005380 <sys_link+0x13c>
    iunlockput(ip);
    8000532e:	8526                	mv	a0,s1
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	526080e7          	jalr	1318(ra) # 80003856 <iunlockput>
    end_op();
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	d0e080e7          	jalr	-754(ra) # 80004046 <end_op>
    return -1;
    80005340:	57fd                	li	a5,-1
    80005342:	a83d                	j	80005380 <sys_link+0x13c>
    iunlockput(dp);
    80005344:	854a                	mv	a0,s2
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	510080e7          	jalr	1296(ra) # 80003856 <iunlockput>
  ilock(ip);
    8000534e:	8526                	mv	a0,s1
    80005350:	ffffe097          	auipc	ra,0xffffe
    80005354:	2a4080e7          	jalr	676(ra) # 800035f4 <ilock>
  ip->nlink--;
    80005358:	04a4d783          	lhu	a5,74(s1)
    8000535c:	37fd                	addiw	a5,a5,-1
    8000535e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005362:	8526                	mv	a0,s1
    80005364:	ffffe097          	auipc	ra,0xffffe
    80005368:	1c6080e7          	jalr	454(ra) # 8000352a <iupdate>
  iunlockput(ip);
    8000536c:	8526                	mv	a0,s1
    8000536e:	ffffe097          	auipc	ra,0xffffe
    80005372:	4e8080e7          	jalr	1256(ra) # 80003856 <iunlockput>
  end_op();
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	cd0080e7          	jalr	-816(ra) # 80004046 <end_op>
  return -1;
    8000537e:	57fd                	li	a5,-1
}
    80005380:	853e                	mv	a0,a5
    80005382:	70b2                	ld	ra,296(sp)
    80005384:	7412                	ld	s0,288(sp)
    80005386:	64f2                	ld	s1,280(sp)
    80005388:	6952                	ld	s2,272(sp)
    8000538a:	6155                	addi	sp,sp,304
    8000538c:	8082                	ret

000000008000538e <sys_unlink>:
{
    8000538e:	7151                	addi	sp,sp,-240
    80005390:	f586                	sd	ra,232(sp)
    80005392:	f1a2                	sd	s0,224(sp)
    80005394:	eda6                	sd	s1,216(sp)
    80005396:	e9ca                	sd	s2,208(sp)
    80005398:	e5ce                	sd	s3,200(sp)
    8000539a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000539c:	08000613          	li	a2,128
    800053a0:	f3040593          	addi	a1,s0,-208
    800053a4:	4501                	li	a0,0
    800053a6:	ffffd097          	auipc	ra,0xffffd
    800053aa:	6de080e7          	jalr	1758(ra) # 80002a84 <argstr>
    800053ae:	18054163          	bltz	a0,80005530 <sys_unlink+0x1a2>
  begin_op();
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	c14080e7          	jalr	-1004(ra) # 80003fc6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053ba:	fb040593          	addi	a1,s0,-80
    800053be:	f3040513          	addi	a0,s0,-208
    800053c2:	fffff097          	auipc	ra,0xfffff
    800053c6:	a06080e7          	jalr	-1530(ra) # 80003dc8 <nameiparent>
    800053ca:	84aa                	mv	s1,a0
    800053cc:	c979                	beqz	a0,800054a2 <sys_unlink+0x114>
  ilock(dp);
    800053ce:	ffffe097          	auipc	ra,0xffffe
    800053d2:	226080e7          	jalr	550(ra) # 800035f4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053d6:	00003597          	auipc	a1,0x3
    800053da:	31258593          	addi	a1,a1,786 # 800086e8 <syscalls+0x2b8>
    800053de:	fb040513          	addi	a0,s0,-80
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	6dc080e7          	jalr	1756(ra) # 80003abe <namecmp>
    800053ea:	14050a63          	beqz	a0,8000553e <sys_unlink+0x1b0>
    800053ee:	00003597          	auipc	a1,0x3
    800053f2:	30258593          	addi	a1,a1,770 # 800086f0 <syscalls+0x2c0>
    800053f6:	fb040513          	addi	a0,s0,-80
    800053fa:	ffffe097          	auipc	ra,0xffffe
    800053fe:	6c4080e7          	jalr	1732(ra) # 80003abe <namecmp>
    80005402:	12050e63          	beqz	a0,8000553e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005406:	f2c40613          	addi	a2,s0,-212
    8000540a:	fb040593          	addi	a1,s0,-80
    8000540e:	8526                	mv	a0,s1
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	6c8080e7          	jalr	1736(ra) # 80003ad8 <dirlookup>
    80005418:	892a                	mv	s2,a0
    8000541a:	12050263          	beqz	a0,8000553e <sys_unlink+0x1b0>
  ilock(ip);
    8000541e:	ffffe097          	auipc	ra,0xffffe
    80005422:	1d6080e7          	jalr	470(ra) # 800035f4 <ilock>
  if(ip->nlink < 1)
    80005426:	04a91783          	lh	a5,74(s2)
    8000542a:	08f05263          	blez	a5,800054ae <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000542e:	04491703          	lh	a4,68(s2)
    80005432:	4785                	li	a5,1
    80005434:	08f70563          	beq	a4,a5,800054be <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005438:	4641                	li	a2,16
    8000543a:	4581                	li	a1,0
    8000543c:	fc040513          	addi	a0,s0,-64
    80005440:	ffffc097          	auipc	ra,0xffffc
    80005444:	892080e7          	jalr	-1902(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005448:	4741                	li	a4,16
    8000544a:	f2c42683          	lw	a3,-212(s0)
    8000544e:	fc040613          	addi	a2,s0,-64
    80005452:	4581                	li	a1,0
    80005454:	8526                	mv	a0,s1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	54a080e7          	jalr	1354(ra) # 800039a0 <writei>
    8000545e:	47c1                	li	a5,16
    80005460:	0af51563          	bne	a0,a5,8000550a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005464:	04491703          	lh	a4,68(s2)
    80005468:	4785                	li	a5,1
    8000546a:	0af70863          	beq	a4,a5,8000551a <sys_unlink+0x18c>
  iunlockput(dp);
    8000546e:	8526                	mv	a0,s1
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	3e6080e7          	jalr	998(ra) # 80003856 <iunlockput>
  ip->nlink--;
    80005478:	04a95783          	lhu	a5,74(s2)
    8000547c:	37fd                	addiw	a5,a5,-1
    8000547e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005482:	854a                	mv	a0,s2
    80005484:	ffffe097          	auipc	ra,0xffffe
    80005488:	0a6080e7          	jalr	166(ra) # 8000352a <iupdate>
  iunlockput(ip);
    8000548c:	854a                	mv	a0,s2
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	3c8080e7          	jalr	968(ra) # 80003856 <iunlockput>
  end_op();
    80005496:	fffff097          	auipc	ra,0xfffff
    8000549a:	bb0080e7          	jalr	-1104(ra) # 80004046 <end_op>
  return 0;
    8000549e:	4501                	li	a0,0
    800054a0:	a84d                	j	80005552 <sys_unlink+0x1c4>
    end_op();
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	ba4080e7          	jalr	-1116(ra) # 80004046 <end_op>
    return -1;
    800054aa:	557d                	li	a0,-1
    800054ac:	a05d                	j	80005552 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054ae:	00003517          	auipc	a0,0x3
    800054b2:	26a50513          	addi	a0,a0,618 # 80008718 <syscalls+0x2e8>
    800054b6:	ffffb097          	auipc	ra,0xffffb
    800054ba:	07a080e7          	jalr	122(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054be:	04c92703          	lw	a4,76(s2)
    800054c2:	02000793          	li	a5,32
    800054c6:	f6e7f9e3          	bgeu	a5,a4,80005438 <sys_unlink+0xaa>
    800054ca:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ce:	4741                	li	a4,16
    800054d0:	86ce                	mv	a3,s3
    800054d2:	f1840613          	addi	a2,s0,-232
    800054d6:	4581                	li	a1,0
    800054d8:	854a                	mv	a0,s2
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	3ce080e7          	jalr	974(ra) # 800038a8 <readi>
    800054e2:	47c1                	li	a5,16
    800054e4:	00f51b63          	bne	a0,a5,800054fa <sys_unlink+0x16c>
    if(de.inum != 0)
    800054e8:	f1845783          	lhu	a5,-232(s0)
    800054ec:	e7a1                	bnez	a5,80005534 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054ee:	29c1                	addiw	s3,s3,16
    800054f0:	04c92783          	lw	a5,76(s2)
    800054f4:	fcf9ede3          	bltu	s3,a5,800054ce <sys_unlink+0x140>
    800054f8:	b781                	j	80005438 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800054fa:	00003517          	auipc	a0,0x3
    800054fe:	23650513          	addi	a0,a0,566 # 80008730 <syscalls+0x300>
    80005502:	ffffb097          	auipc	ra,0xffffb
    80005506:	02e080e7          	jalr	46(ra) # 80000530 <panic>
    panic("unlink: writei");
    8000550a:	00003517          	auipc	a0,0x3
    8000550e:	23e50513          	addi	a0,a0,574 # 80008748 <syscalls+0x318>
    80005512:	ffffb097          	auipc	ra,0xffffb
    80005516:	01e080e7          	jalr	30(ra) # 80000530 <panic>
    dp->nlink--;
    8000551a:	04a4d783          	lhu	a5,74(s1)
    8000551e:	37fd                	addiw	a5,a5,-1
    80005520:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005524:	8526                	mv	a0,s1
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	004080e7          	jalr	4(ra) # 8000352a <iupdate>
    8000552e:	b781                	j	8000546e <sys_unlink+0xe0>
    return -1;
    80005530:	557d                	li	a0,-1
    80005532:	a005                	j	80005552 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005534:	854a                	mv	a0,s2
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	320080e7          	jalr	800(ra) # 80003856 <iunlockput>
  iunlockput(dp);
    8000553e:	8526                	mv	a0,s1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	316080e7          	jalr	790(ra) # 80003856 <iunlockput>
  end_op();
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	afe080e7          	jalr	-1282(ra) # 80004046 <end_op>
  return -1;
    80005550:	557d                	li	a0,-1
}
    80005552:	70ae                	ld	ra,232(sp)
    80005554:	740e                	ld	s0,224(sp)
    80005556:	64ee                	ld	s1,216(sp)
    80005558:	694e                	ld	s2,208(sp)
    8000555a:	69ae                	ld	s3,200(sp)
    8000555c:	616d                	addi	sp,sp,240
    8000555e:	8082                	ret

0000000080005560 <sys_open>:

uint64
sys_open(void)
{
    80005560:	7131                	addi	sp,sp,-192
    80005562:	fd06                	sd	ra,184(sp)
    80005564:	f922                	sd	s0,176(sp)
    80005566:	f526                	sd	s1,168(sp)
    80005568:	f14a                	sd	s2,160(sp)
    8000556a:	ed4e                	sd	s3,152(sp)
    8000556c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000556e:	08000613          	li	a2,128
    80005572:	f5040593          	addi	a1,s0,-176
    80005576:	4501                	li	a0,0
    80005578:	ffffd097          	auipc	ra,0xffffd
    8000557c:	50c080e7          	jalr	1292(ra) # 80002a84 <argstr>
    return -1;
    80005580:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005582:	0c054163          	bltz	a0,80005644 <sys_open+0xe4>
    80005586:	f4c40593          	addi	a1,s0,-180
    8000558a:	4505                	li	a0,1
    8000558c:	ffffd097          	auipc	ra,0xffffd
    80005590:	4b4080e7          	jalr	1204(ra) # 80002a40 <argint>
    80005594:	0a054863          	bltz	a0,80005644 <sys_open+0xe4>

  begin_op();
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	a2e080e7          	jalr	-1490(ra) # 80003fc6 <begin_op>

  if(omode & O_CREATE){
    800055a0:	f4c42783          	lw	a5,-180(s0)
    800055a4:	2007f793          	andi	a5,a5,512
    800055a8:	cbdd                	beqz	a5,8000565e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800055aa:	4681                	li	a3,0
    800055ac:	4601                	li	a2,0
    800055ae:	4589                	li	a1,2
    800055b0:	f5040513          	addi	a0,s0,-176
    800055b4:	00000097          	auipc	ra,0x0
    800055b8:	972080e7          	jalr	-1678(ra) # 80004f26 <create>
    800055bc:	892a                	mv	s2,a0
    if(ip == 0){
    800055be:	c959                	beqz	a0,80005654 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055c0:	04491703          	lh	a4,68(s2)
    800055c4:	478d                	li	a5,3
    800055c6:	00f71763          	bne	a4,a5,800055d4 <sys_open+0x74>
    800055ca:	04695703          	lhu	a4,70(s2)
    800055ce:	47a5                	li	a5,9
    800055d0:	0ce7ec63          	bltu	a5,a4,800056a8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	e02080e7          	jalr	-510(ra) # 800043d6 <filealloc>
    800055dc:	89aa                	mv	s3,a0
    800055de:	10050263          	beqz	a0,800056e2 <sys_open+0x182>
    800055e2:	00000097          	auipc	ra,0x0
    800055e6:	902080e7          	jalr	-1790(ra) # 80004ee4 <fdalloc>
    800055ea:	84aa                	mv	s1,a0
    800055ec:	0e054663          	bltz	a0,800056d8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800055f0:	04491703          	lh	a4,68(s2)
    800055f4:	478d                	li	a5,3
    800055f6:	0cf70463          	beq	a4,a5,800056be <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800055fa:	4789                	li	a5,2
    800055fc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005600:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005604:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005608:	f4c42783          	lw	a5,-180(s0)
    8000560c:	0017c713          	xori	a4,a5,1
    80005610:	8b05                	andi	a4,a4,1
    80005612:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005616:	0037f713          	andi	a4,a5,3
    8000561a:	00e03733          	snez	a4,a4
    8000561e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005622:	4007f793          	andi	a5,a5,1024
    80005626:	c791                	beqz	a5,80005632 <sys_open+0xd2>
    80005628:	04491703          	lh	a4,68(s2)
    8000562c:	4789                	li	a5,2
    8000562e:	08f70f63          	beq	a4,a5,800056cc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005632:	854a                	mv	a0,s2
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	082080e7          	jalr	130(ra) # 800036b6 <iunlock>
  end_op();
    8000563c:	fffff097          	auipc	ra,0xfffff
    80005640:	a0a080e7          	jalr	-1526(ra) # 80004046 <end_op>

  return fd;
}
    80005644:	8526                	mv	a0,s1
    80005646:	70ea                	ld	ra,184(sp)
    80005648:	744a                	ld	s0,176(sp)
    8000564a:	74aa                	ld	s1,168(sp)
    8000564c:	790a                	ld	s2,160(sp)
    8000564e:	69ea                	ld	s3,152(sp)
    80005650:	6129                	addi	sp,sp,192
    80005652:	8082                	ret
      end_op();
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	9f2080e7          	jalr	-1550(ra) # 80004046 <end_op>
      return -1;
    8000565c:	b7e5                	j	80005644 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000565e:	f5040513          	addi	a0,s0,-176
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	748080e7          	jalr	1864(ra) # 80003daa <namei>
    8000566a:	892a                	mv	s2,a0
    8000566c:	c905                	beqz	a0,8000569c <sys_open+0x13c>
    ilock(ip);
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	f86080e7          	jalr	-122(ra) # 800035f4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005676:	04491703          	lh	a4,68(s2)
    8000567a:	4785                	li	a5,1
    8000567c:	f4f712e3          	bne	a4,a5,800055c0 <sys_open+0x60>
    80005680:	f4c42783          	lw	a5,-180(s0)
    80005684:	dba1                	beqz	a5,800055d4 <sys_open+0x74>
      iunlockput(ip);
    80005686:	854a                	mv	a0,s2
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	1ce080e7          	jalr	462(ra) # 80003856 <iunlockput>
      end_op();
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	9b6080e7          	jalr	-1610(ra) # 80004046 <end_op>
      return -1;
    80005698:	54fd                	li	s1,-1
    8000569a:	b76d                	j	80005644 <sys_open+0xe4>
      end_op();
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	9aa080e7          	jalr	-1622(ra) # 80004046 <end_op>
      return -1;
    800056a4:	54fd                	li	s1,-1
    800056a6:	bf79                	j	80005644 <sys_open+0xe4>
    iunlockput(ip);
    800056a8:	854a                	mv	a0,s2
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	1ac080e7          	jalr	428(ra) # 80003856 <iunlockput>
    end_op();
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	994080e7          	jalr	-1644(ra) # 80004046 <end_op>
    return -1;
    800056ba:	54fd                	li	s1,-1
    800056bc:	b761                	j	80005644 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800056be:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056c2:	04691783          	lh	a5,70(s2)
    800056c6:	02f99223          	sh	a5,36(s3)
    800056ca:	bf2d                	j	80005604 <sys_open+0xa4>
    itrunc(ip);
    800056cc:	854a                	mv	a0,s2
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	034080e7          	jalr	52(ra) # 80003702 <itrunc>
    800056d6:	bfb1                	j	80005632 <sys_open+0xd2>
      fileclose(f);
    800056d8:	854e                	mv	a0,s3
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	db8080e7          	jalr	-584(ra) # 80004492 <fileclose>
    iunlockput(ip);
    800056e2:	854a                	mv	a0,s2
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	172080e7          	jalr	370(ra) # 80003856 <iunlockput>
    end_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	95a080e7          	jalr	-1702(ra) # 80004046 <end_op>
    return -1;
    800056f4:	54fd                	li	s1,-1
    800056f6:	b7b9                	j	80005644 <sys_open+0xe4>

00000000800056f8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800056f8:	7175                	addi	sp,sp,-144
    800056fa:	e506                	sd	ra,136(sp)
    800056fc:	e122                	sd	s0,128(sp)
    800056fe:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	8c6080e7          	jalr	-1850(ra) # 80003fc6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005708:	08000613          	li	a2,128
    8000570c:	f7040593          	addi	a1,s0,-144
    80005710:	4501                	li	a0,0
    80005712:	ffffd097          	auipc	ra,0xffffd
    80005716:	372080e7          	jalr	882(ra) # 80002a84 <argstr>
    8000571a:	02054963          	bltz	a0,8000574c <sys_mkdir+0x54>
    8000571e:	4681                	li	a3,0
    80005720:	4601                	li	a2,0
    80005722:	4585                	li	a1,1
    80005724:	f7040513          	addi	a0,s0,-144
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	7fe080e7          	jalr	2046(ra) # 80004f26 <create>
    80005730:	cd11                	beqz	a0,8000574c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005732:	ffffe097          	auipc	ra,0xffffe
    80005736:	124080e7          	jalr	292(ra) # 80003856 <iunlockput>
  end_op();
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	90c080e7          	jalr	-1780(ra) # 80004046 <end_op>
  return 0;
    80005742:	4501                	li	a0,0
}
    80005744:	60aa                	ld	ra,136(sp)
    80005746:	640a                	ld	s0,128(sp)
    80005748:	6149                	addi	sp,sp,144
    8000574a:	8082                	ret
    end_op();
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	8fa080e7          	jalr	-1798(ra) # 80004046 <end_op>
    return -1;
    80005754:	557d                	li	a0,-1
    80005756:	b7fd                	j	80005744 <sys_mkdir+0x4c>

0000000080005758 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005758:	7135                	addi	sp,sp,-160
    8000575a:	ed06                	sd	ra,152(sp)
    8000575c:	e922                	sd	s0,144(sp)
    8000575e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	866080e7          	jalr	-1946(ra) # 80003fc6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005768:	08000613          	li	a2,128
    8000576c:	f7040593          	addi	a1,s0,-144
    80005770:	4501                	li	a0,0
    80005772:	ffffd097          	auipc	ra,0xffffd
    80005776:	312080e7          	jalr	786(ra) # 80002a84 <argstr>
    8000577a:	04054a63          	bltz	a0,800057ce <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000577e:	f6c40593          	addi	a1,s0,-148
    80005782:	4505                	li	a0,1
    80005784:	ffffd097          	auipc	ra,0xffffd
    80005788:	2bc080e7          	jalr	700(ra) # 80002a40 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000578c:	04054163          	bltz	a0,800057ce <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005790:	f6840593          	addi	a1,s0,-152
    80005794:	4509                	li	a0,2
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	2aa080e7          	jalr	682(ra) # 80002a40 <argint>
     argint(1, &major) < 0 ||
    8000579e:	02054863          	bltz	a0,800057ce <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800057a2:	f6841683          	lh	a3,-152(s0)
    800057a6:	f6c41603          	lh	a2,-148(s0)
    800057aa:	458d                	li	a1,3
    800057ac:	f7040513          	addi	a0,s0,-144
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	776080e7          	jalr	1910(ra) # 80004f26 <create>
     argint(2, &minor) < 0 ||
    800057b8:	c919                	beqz	a0,800057ce <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	09c080e7          	jalr	156(ra) # 80003856 <iunlockput>
  end_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	884080e7          	jalr	-1916(ra) # 80004046 <end_op>
  return 0;
    800057ca:	4501                	li	a0,0
    800057cc:	a031                	j	800057d8 <sys_mknod+0x80>
    end_op();
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	878080e7          	jalr	-1928(ra) # 80004046 <end_op>
    return -1;
    800057d6:	557d                	li	a0,-1
}
    800057d8:	60ea                	ld	ra,152(sp)
    800057da:	644a                	ld	s0,144(sp)
    800057dc:	610d                	addi	sp,sp,160
    800057de:	8082                	ret

00000000800057e0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800057e0:	7135                	addi	sp,sp,-160
    800057e2:	ed06                	sd	ra,152(sp)
    800057e4:	e922                	sd	s0,144(sp)
    800057e6:	e526                	sd	s1,136(sp)
    800057e8:	e14a                	sd	s2,128(sp)
    800057ea:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800057ec:	ffffc097          	auipc	ra,0xffffc
    800057f0:	1a8080e7          	jalr	424(ra) # 80001994 <myproc>
    800057f4:	892a                	mv	s2,a0
  
  begin_op();
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	7d0080e7          	jalr	2000(ra) # 80003fc6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800057fe:	08000613          	li	a2,128
    80005802:	f6040593          	addi	a1,s0,-160
    80005806:	4501                	li	a0,0
    80005808:	ffffd097          	auipc	ra,0xffffd
    8000580c:	27c080e7          	jalr	636(ra) # 80002a84 <argstr>
    80005810:	04054b63          	bltz	a0,80005866 <sys_chdir+0x86>
    80005814:	f6040513          	addi	a0,s0,-160
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	592080e7          	jalr	1426(ra) # 80003daa <namei>
    80005820:	84aa                	mv	s1,a0
    80005822:	c131                	beqz	a0,80005866 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	dd0080e7          	jalr	-560(ra) # 800035f4 <ilock>
  if(ip->type != T_DIR){
    8000582c:	04449703          	lh	a4,68(s1)
    80005830:	4785                	li	a5,1
    80005832:	04f71063          	bne	a4,a5,80005872 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005836:	8526                	mv	a0,s1
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	e7e080e7          	jalr	-386(ra) # 800036b6 <iunlock>
  iput(p->cwd);
    80005840:	15093503          	ld	a0,336(s2)
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	f6a080e7          	jalr	-150(ra) # 800037ae <iput>
  end_op();
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	7fa080e7          	jalr	2042(ra) # 80004046 <end_op>
  p->cwd = ip;
    80005854:	14993823          	sd	s1,336(s2)
  return 0;
    80005858:	4501                	li	a0,0
}
    8000585a:	60ea                	ld	ra,152(sp)
    8000585c:	644a                	ld	s0,144(sp)
    8000585e:	64aa                	ld	s1,136(sp)
    80005860:	690a                	ld	s2,128(sp)
    80005862:	610d                	addi	sp,sp,160
    80005864:	8082                	ret
    end_op();
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	7e0080e7          	jalr	2016(ra) # 80004046 <end_op>
    return -1;
    8000586e:	557d                	li	a0,-1
    80005870:	b7ed                	j	8000585a <sys_chdir+0x7a>
    iunlockput(ip);
    80005872:	8526                	mv	a0,s1
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	fe2080e7          	jalr	-30(ra) # 80003856 <iunlockput>
    end_op();
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	7ca080e7          	jalr	1994(ra) # 80004046 <end_op>
    return -1;
    80005884:	557d                	li	a0,-1
    80005886:	bfd1                	j	8000585a <sys_chdir+0x7a>

0000000080005888 <sys_exec>:

uint64
sys_exec(void)
{
    80005888:	7145                	addi	sp,sp,-464
    8000588a:	e786                	sd	ra,456(sp)
    8000588c:	e3a2                	sd	s0,448(sp)
    8000588e:	ff26                	sd	s1,440(sp)
    80005890:	fb4a                	sd	s2,432(sp)
    80005892:	f74e                	sd	s3,424(sp)
    80005894:	f352                	sd	s4,416(sp)
    80005896:	ef56                	sd	s5,408(sp)
    80005898:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000589a:	08000613          	li	a2,128
    8000589e:	f4040593          	addi	a1,s0,-192
    800058a2:	4501                	li	a0,0
    800058a4:	ffffd097          	auipc	ra,0xffffd
    800058a8:	1e0080e7          	jalr	480(ra) # 80002a84 <argstr>
    return -1;
    800058ac:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058ae:	0c054a63          	bltz	a0,80005982 <sys_exec+0xfa>
    800058b2:	e3840593          	addi	a1,s0,-456
    800058b6:	4505                	li	a0,1
    800058b8:	ffffd097          	auipc	ra,0xffffd
    800058bc:	1aa080e7          	jalr	426(ra) # 80002a62 <argaddr>
    800058c0:	0c054163          	bltz	a0,80005982 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800058c4:	10000613          	li	a2,256
    800058c8:	4581                	li	a1,0
    800058ca:	e4040513          	addi	a0,s0,-448
    800058ce:	ffffb097          	auipc	ra,0xffffb
    800058d2:	404080e7          	jalr	1028(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058d6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800058da:	89a6                	mv	s3,s1
    800058dc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800058de:	02000a13          	li	s4,32
    800058e2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800058e6:	00391513          	slli	a0,s2,0x3
    800058ea:	e3040593          	addi	a1,s0,-464
    800058ee:	e3843783          	ld	a5,-456(s0)
    800058f2:	953e                	add	a0,a0,a5
    800058f4:	ffffd097          	auipc	ra,0xffffd
    800058f8:	0b2080e7          	jalr	178(ra) # 800029a6 <fetchaddr>
    800058fc:	02054a63          	bltz	a0,80005930 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005900:	e3043783          	ld	a5,-464(s0)
    80005904:	c3b9                	beqz	a5,8000594a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005906:	ffffb097          	auipc	ra,0xffffb
    8000590a:	1e0080e7          	jalr	480(ra) # 80000ae6 <kalloc>
    8000590e:	85aa                	mv	a1,a0
    80005910:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005914:	cd11                	beqz	a0,80005930 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005916:	6605                	lui	a2,0x1
    80005918:	e3043503          	ld	a0,-464(s0)
    8000591c:	ffffd097          	auipc	ra,0xffffd
    80005920:	0dc080e7          	jalr	220(ra) # 800029f8 <fetchstr>
    80005924:	00054663          	bltz	a0,80005930 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005928:	0905                	addi	s2,s2,1
    8000592a:	09a1                	addi	s3,s3,8
    8000592c:	fb491be3          	bne	s2,s4,800058e2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005930:	10048913          	addi	s2,s1,256
    80005934:	6088                	ld	a0,0(s1)
    80005936:	c529                	beqz	a0,80005980 <sys_exec+0xf8>
    kfree(argv[i]);
    80005938:	ffffb097          	auipc	ra,0xffffb
    8000593c:	0b2080e7          	jalr	178(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005940:	04a1                	addi	s1,s1,8
    80005942:	ff2499e3          	bne	s1,s2,80005934 <sys_exec+0xac>
  return -1;
    80005946:	597d                	li	s2,-1
    80005948:	a82d                	j	80005982 <sys_exec+0xfa>
      argv[i] = 0;
    8000594a:	0a8e                	slli	s5,s5,0x3
    8000594c:	fc040793          	addi	a5,s0,-64
    80005950:	9abe                	add	s5,s5,a5
    80005952:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005956:	e4040593          	addi	a1,s0,-448
    8000595a:	f4040513          	addi	a0,s0,-192
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	194080e7          	jalr	404(ra) # 80004af2 <exec>
    80005966:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005968:	10048993          	addi	s3,s1,256
    8000596c:	6088                	ld	a0,0(s1)
    8000596e:	c911                	beqz	a0,80005982 <sys_exec+0xfa>
    kfree(argv[i]);
    80005970:	ffffb097          	auipc	ra,0xffffb
    80005974:	07a080e7          	jalr	122(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005978:	04a1                	addi	s1,s1,8
    8000597a:	ff3499e3          	bne	s1,s3,8000596c <sys_exec+0xe4>
    8000597e:	a011                	j	80005982 <sys_exec+0xfa>
  return -1;
    80005980:	597d                	li	s2,-1
}
    80005982:	854a                	mv	a0,s2
    80005984:	60be                	ld	ra,456(sp)
    80005986:	641e                	ld	s0,448(sp)
    80005988:	74fa                	ld	s1,440(sp)
    8000598a:	795a                	ld	s2,432(sp)
    8000598c:	79ba                	ld	s3,424(sp)
    8000598e:	7a1a                	ld	s4,416(sp)
    80005990:	6afa                	ld	s5,408(sp)
    80005992:	6179                	addi	sp,sp,464
    80005994:	8082                	ret

0000000080005996 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005996:	7139                	addi	sp,sp,-64
    80005998:	fc06                	sd	ra,56(sp)
    8000599a:	f822                	sd	s0,48(sp)
    8000599c:	f426                	sd	s1,40(sp)
    8000599e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800059a0:	ffffc097          	auipc	ra,0xffffc
    800059a4:	ff4080e7          	jalr	-12(ra) # 80001994 <myproc>
    800059a8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800059aa:	fd840593          	addi	a1,s0,-40
    800059ae:	4501                	li	a0,0
    800059b0:	ffffd097          	auipc	ra,0xffffd
    800059b4:	0b2080e7          	jalr	178(ra) # 80002a62 <argaddr>
    return -1;
    800059b8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800059ba:	0e054063          	bltz	a0,80005a9a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800059be:	fc840593          	addi	a1,s0,-56
    800059c2:	fd040513          	addi	a0,s0,-48
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	dfc080e7          	jalr	-516(ra) # 800047c2 <pipealloc>
    return -1;
    800059ce:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059d0:	0c054563          	bltz	a0,80005a9a <sys_pipe+0x104>
  fd0 = -1;
    800059d4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059d8:	fd043503          	ld	a0,-48(s0)
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	508080e7          	jalr	1288(ra) # 80004ee4 <fdalloc>
    800059e4:	fca42223          	sw	a0,-60(s0)
    800059e8:	08054c63          	bltz	a0,80005a80 <sys_pipe+0xea>
    800059ec:	fc843503          	ld	a0,-56(s0)
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	4f4080e7          	jalr	1268(ra) # 80004ee4 <fdalloc>
    800059f8:	fca42023          	sw	a0,-64(s0)
    800059fc:	06054863          	bltz	a0,80005a6c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a00:	4691                	li	a3,4
    80005a02:	fc440613          	addi	a2,s0,-60
    80005a06:	fd843583          	ld	a1,-40(s0)
    80005a0a:	68a8                	ld	a0,80(s1)
    80005a0c:	ffffc097          	auipc	ra,0xffffc
    80005a10:	c4a080e7          	jalr	-950(ra) # 80001656 <copyout>
    80005a14:	02054063          	bltz	a0,80005a34 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a18:	4691                	li	a3,4
    80005a1a:	fc040613          	addi	a2,s0,-64
    80005a1e:	fd843583          	ld	a1,-40(s0)
    80005a22:	0591                	addi	a1,a1,4
    80005a24:	68a8                	ld	a0,80(s1)
    80005a26:	ffffc097          	auipc	ra,0xffffc
    80005a2a:	c30080e7          	jalr	-976(ra) # 80001656 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a2e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a30:	06055563          	bgez	a0,80005a9a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a34:	fc442783          	lw	a5,-60(s0)
    80005a38:	07e9                	addi	a5,a5,26
    80005a3a:	078e                	slli	a5,a5,0x3
    80005a3c:	97a6                	add	a5,a5,s1
    80005a3e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a42:	fc042503          	lw	a0,-64(s0)
    80005a46:	0569                	addi	a0,a0,26
    80005a48:	050e                	slli	a0,a0,0x3
    80005a4a:	9526                	add	a0,a0,s1
    80005a4c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a50:	fd043503          	ld	a0,-48(s0)
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	a3e080e7          	jalr	-1474(ra) # 80004492 <fileclose>
    fileclose(wf);
    80005a5c:	fc843503          	ld	a0,-56(s0)
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	a32080e7          	jalr	-1486(ra) # 80004492 <fileclose>
    return -1;
    80005a68:	57fd                	li	a5,-1
    80005a6a:	a805                	j	80005a9a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a6c:	fc442783          	lw	a5,-60(s0)
    80005a70:	0007c863          	bltz	a5,80005a80 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005a74:	01a78513          	addi	a0,a5,26
    80005a78:	050e                	slli	a0,a0,0x3
    80005a7a:	9526                	add	a0,a0,s1
    80005a7c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a80:	fd043503          	ld	a0,-48(s0)
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	a0e080e7          	jalr	-1522(ra) # 80004492 <fileclose>
    fileclose(wf);
    80005a8c:	fc843503          	ld	a0,-56(s0)
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	a02080e7          	jalr	-1534(ra) # 80004492 <fileclose>
    return -1;
    80005a98:	57fd                	li	a5,-1
}
    80005a9a:	853e                	mv	a0,a5
    80005a9c:	70e2                	ld	ra,56(sp)
    80005a9e:	7442                	ld	s0,48(sp)
    80005aa0:	74a2                	ld	s1,40(sp)
    80005aa2:	6121                	addi	sp,sp,64
    80005aa4:	8082                	ret
	...

0000000080005ab0 <kernelvec>:
    80005ab0:	7111                	addi	sp,sp,-256
    80005ab2:	e006                	sd	ra,0(sp)
    80005ab4:	e40a                	sd	sp,8(sp)
    80005ab6:	e80e                	sd	gp,16(sp)
    80005ab8:	ec12                	sd	tp,24(sp)
    80005aba:	f016                	sd	t0,32(sp)
    80005abc:	f41a                	sd	t1,40(sp)
    80005abe:	f81e                	sd	t2,48(sp)
    80005ac0:	fc22                	sd	s0,56(sp)
    80005ac2:	e0a6                	sd	s1,64(sp)
    80005ac4:	e4aa                	sd	a0,72(sp)
    80005ac6:	e8ae                	sd	a1,80(sp)
    80005ac8:	ecb2                	sd	a2,88(sp)
    80005aca:	f0b6                	sd	a3,96(sp)
    80005acc:	f4ba                	sd	a4,104(sp)
    80005ace:	f8be                	sd	a5,112(sp)
    80005ad0:	fcc2                	sd	a6,120(sp)
    80005ad2:	e146                	sd	a7,128(sp)
    80005ad4:	e54a                	sd	s2,136(sp)
    80005ad6:	e94e                	sd	s3,144(sp)
    80005ad8:	ed52                	sd	s4,152(sp)
    80005ada:	f156                	sd	s5,160(sp)
    80005adc:	f55a                	sd	s6,168(sp)
    80005ade:	f95e                	sd	s7,176(sp)
    80005ae0:	fd62                	sd	s8,184(sp)
    80005ae2:	e1e6                	sd	s9,192(sp)
    80005ae4:	e5ea                	sd	s10,200(sp)
    80005ae6:	e9ee                	sd	s11,208(sp)
    80005ae8:	edf2                	sd	t3,216(sp)
    80005aea:	f1f6                	sd	t4,224(sp)
    80005aec:	f5fa                	sd	t5,232(sp)
    80005aee:	f9fe                	sd	t6,240(sp)
    80005af0:	d83fc0ef          	jal	ra,80002872 <kerneltrap>
    80005af4:	6082                	ld	ra,0(sp)
    80005af6:	6122                	ld	sp,8(sp)
    80005af8:	61c2                	ld	gp,16(sp)
    80005afa:	7282                	ld	t0,32(sp)
    80005afc:	7322                	ld	t1,40(sp)
    80005afe:	73c2                	ld	t2,48(sp)
    80005b00:	7462                	ld	s0,56(sp)
    80005b02:	6486                	ld	s1,64(sp)
    80005b04:	6526                	ld	a0,72(sp)
    80005b06:	65c6                	ld	a1,80(sp)
    80005b08:	6666                	ld	a2,88(sp)
    80005b0a:	7686                	ld	a3,96(sp)
    80005b0c:	7726                	ld	a4,104(sp)
    80005b0e:	77c6                	ld	a5,112(sp)
    80005b10:	7866                	ld	a6,120(sp)
    80005b12:	688a                	ld	a7,128(sp)
    80005b14:	692a                	ld	s2,136(sp)
    80005b16:	69ca                	ld	s3,144(sp)
    80005b18:	6a6a                	ld	s4,152(sp)
    80005b1a:	7a8a                	ld	s5,160(sp)
    80005b1c:	7b2a                	ld	s6,168(sp)
    80005b1e:	7bca                	ld	s7,176(sp)
    80005b20:	7c6a                	ld	s8,184(sp)
    80005b22:	6c8e                	ld	s9,192(sp)
    80005b24:	6d2e                	ld	s10,200(sp)
    80005b26:	6dce                	ld	s11,208(sp)
    80005b28:	6e6e                	ld	t3,216(sp)
    80005b2a:	7e8e                	ld	t4,224(sp)
    80005b2c:	7f2e                	ld	t5,232(sp)
    80005b2e:	7fce                	ld	t6,240(sp)
    80005b30:	6111                	addi	sp,sp,256
    80005b32:	10200073          	sret
    80005b36:	00000013          	nop
    80005b3a:	00000013          	nop
    80005b3e:	0001                	nop

0000000080005b40 <timervec>:
    80005b40:	34051573          	csrrw	a0,mscratch,a0
    80005b44:	e10c                	sd	a1,0(a0)
    80005b46:	e510                	sd	a2,8(a0)
    80005b48:	e914                	sd	a3,16(a0)
    80005b4a:	6d0c                	ld	a1,24(a0)
    80005b4c:	7110                	ld	a2,32(a0)
    80005b4e:	6194                	ld	a3,0(a1)
    80005b50:	96b2                	add	a3,a3,a2
    80005b52:	e194                	sd	a3,0(a1)
    80005b54:	4589                	li	a1,2
    80005b56:	14459073          	csrw	sip,a1
    80005b5a:	6914                	ld	a3,16(a0)
    80005b5c:	6510                	ld	a2,8(a0)
    80005b5e:	610c                	ld	a1,0(a0)
    80005b60:	34051573          	csrrw	a0,mscratch,a0
    80005b64:	30200073          	mret
	...

0000000080005b6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005b6a:	1141                	addi	sp,sp,-16
    80005b6c:	e422                	sd	s0,8(sp)
    80005b6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005b70:	0c0007b7          	lui	a5,0xc000
    80005b74:	4705                	li	a4,1
    80005b76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005b78:	c3d8                	sw	a4,4(a5)
}
    80005b7a:	6422                	ld	s0,8(sp)
    80005b7c:	0141                	addi	sp,sp,16
    80005b7e:	8082                	ret

0000000080005b80 <plicinithart>:

void
plicinithart(void)
{
    80005b80:	1141                	addi	sp,sp,-16
    80005b82:	e406                	sd	ra,8(sp)
    80005b84:	e022                	sd	s0,0(sp)
    80005b86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005b88:	ffffc097          	auipc	ra,0xffffc
    80005b8c:	de0080e7          	jalr	-544(ra) # 80001968 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005b90:	0085171b          	slliw	a4,a0,0x8
    80005b94:	0c0027b7          	lui	a5,0xc002
    80005b98:	97ba                	add	a5,a5,a4
    80005b9a:	40200713          	li	a4,1026
    80005b9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ba2:	00d5151b          	slliw	a0,a0,0xd
    80005ba6:	0c2017b7          	lui	a5,0xc201
    80005baa:	953e                	add	a0,a0,a5
    80005bac:	00052023          	sw	zero,0(a0)
}
    80005bb0:	60a2                	ld	ra,8(sp)
    80005bb2:	6402                	ld	s0,0(sp)
    80005bb4:	0141                	addi	sp,sp,16
    80005bb6:	8082                	ret

0000000080005bb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005bb8:	1141                	addi	sp,sp,-16
    80005bba:	e406                	sd	ra,8(sp)
    80005bbc:	e022                	sd	s0,0(sp)
    80005bbe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005bc0:	ffffc097          	auipc	ra,0xffffc
    80005bc4:	da8080e7          	jalr	-600(ra) # 80001968 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005bc8:	00d5179b          	slliw	a5,a0,0xd
    80005bcc:	0c201537          	lui	a0,0xc201
    80005bd0:	953e                	add	a0,a0,a5
  return irq;
}
    80005bd2:	4148                	lw	a0,4(a0)
    80005bd4:	60a2                	ld	ra,8(sp)
    80005bd6:	6402                	ld	s0,0(sp)
    80005bd8:	0141                	addi	sp,sp,16
    80005bda:	8082                	ret

0000000080005bdc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005bdc:	1101                	addi	sp,sp,-32
    80005bde:	ec06                	sd	ra,24(sp)
    80005be0:	e822                	sd	s0,16(sp)
    80005be2:	e426                	sd	s1,8(sp)
    80005be4:	1000                	addi	s0,sp,32
    80005be6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005be8:	ffffc097          	auipc	ra,0xffffc
    80005bec:	d80080e7          	jalr	-640(ra) # 80001968 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005bf0:	00d5151b          	slliw	a0,a0,0xd
    80005bf4:	0c2017b7          	lui	a5,0xc201
    80005bf8:	97aa                	add	a5,a5,a0
    80005bfa:	c3c4                	sw	s1,4(a5)
}
    80005bfc:	60e2                	ld	ra,24(sp)
    80005bfe:	6442                	ld	s0,16(sp)
    80005c00:	64a2                	ld	s1,8(sp)
    80005c02:	6105                	addi	sp,sp,32
    80005c04:	8082                	ret

0000000080005c06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005c06:	1141                	addi	sp,sp,-16
    80005c08:	e406                	sd	ra,8(sp)
    80005c0a:	e022                	sd	s0,0(sp)
    80005c0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005c0e:	479d                	li	a5,7
    80005c10:	06a7c963          	blt	a5,a0,80005c82 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005c14:	0001d797          	auipc	a5,0x1d
    80005c18:	3ec78793          	addi	a5,a5,1004 # 80023000 <disk>
    80005c1c:	00a78733          	add	a4,a5,a0
    80005c20:	6789                	lui	a5,0x2
    80005c22:	97ba                	add	a5,a5,a4
    80005c24:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005c28:	e7ad                	bnez	a5,80005c92 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005c2a:	00451793          	slli	a5,a0,0x4
    80005c2e:	0001f717          	auipc	a4,0x1f
    80005c32:	3d270713          	addi	a4,a4,978 # 80025000 <disk+0x2000>
    80005c36:	6314                	ld	a3,0(a4)
    80005c38:	96be                	add	a3,a3,a5
    80005c3a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005c3e:	6314                	ld	a3,0(a4)
    80005c40:	96be                	add	a3,a3,a5
    80005c42:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005c46:	6314                	ld	a3,0(a4)
    80005c48:	96be                	add	a3,a3,a5
    80005c4a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005c4e:	6318                	ld	a4,0(a4)
    80005c50:	97ba                	add	a5,a5,a4
    80005c52:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005c56:	0001d797          	auipc	a5,0x1d
    80005c5a:	3aa78793          	addi	a5,a5,938 # 80023000 <disk>
    80005c5e:	97aa                	add	a5,a5,a0
    80005c60:	6509                	lui	a0,0x2
    80005c62:	953e                	add	a0,a0,a5
    80005c64:	4785                	li	a5,1
    80005c66:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005c6a:	0001f517          	auipc	a0,0x1f
    80005c6e:	3ae50513          	addi	a0,a0,942 # 80025018 <disk+0x2018>
    80005c72:	ffffc097          	auipc	ra,0xffffc
    80005c76:	56a080e7          	jalr	1386(ra) # 800021dc <wakeup>
}
    80005c7a:	60a2                	ld	ra,8(sp)
    80005c7c:	6402                	ld	s0,0(sp)
    80005c7e:	0141                	addi	sp,sp,16
    80005c80:	8082                	ret
    panic("free_desc 1");
    80005c82:	00003517          	auipc	a0,0x3
    80005c86:	ad650513          	addi	a0,a0,-1322 # 80008758 <syscalls+0x328>
    80005c8a:	ffffb097          	auipc	ra,0xffffb
    80005c8e:	8a6080e7          	jalr	-1882(ra) # 80000530 <panic>
    panic("free_desc 2");
    80005c92:	00003517          	auipc	a0,0x3
    80005c96:	ad650513          	addi	a0,a0,-1322 # 80008768 <syscalls+0x338>
    80005c9a:	ffffb097          	auipc	ra,0xffffb
    80005c9e:	896080e7          	jalr	-1898(ra) # 80000530 <panic>

0000000080005ca2 <virtio_disk_init>:
{
    80005ca2:	1101                	addi	sp,sp,-32
    80005ca4:	ec06                	sd	ra,24(sp)
    80005ca6:	e822                	sd	s0,16(sp)
    80005ca8:	e426                	sd	s1,8(sp)
    80005caa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005cac:	00003597          	auipc	a1,0x3
    80005cb0:	acc58593          	addi	a1,a1,-1332 # 80008778 <syscalls+0x348>
    80005cb4:	0001f517          	auipc	a0,0x1f
    80005cb8:	47450513          	addi	a0,a0,1140 # 80025128 <disk+0x2128>
    80005cbc:	ffffb097          	auipc	ra,0xffffb
    80005cc0:	e8a080e7          	jalr	-374(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005cc4:	100017b7          	lui	a5,0x10001
    80005cc8:	4398                	lw	a4,0(a5)
    80005cca:	2701                	sext.w	a4,a4
    80005ccc:	747277b7          	lui	a5,0x74727
    80005cd0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005cd4:	0ef71163          	bne	a4,a5,80005db6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cd8:	100017b7          	lui	a5,0x10001
    80005cdc:	43dc                	lw	a5,4(a5)
    80005cde:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ce0:	4705                	li	a4,1
    80005ce2:	0ce79a63          	bne	a5,a4,80005db6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ce6:	100017b7          	lui	a5,0x10001
    80005cea:	479c                	lw	a5,8(a5)
    80005cec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005cee:	4709                	li	a4,2
    80005cf0:	0ce79363          	bne	a5,a4,80005db6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005cf4:	100017b7          	lui	a5,0x10001
    80005cf8:	47d8                	lw	a4,12(a5)
    80005cfa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005cfc:	554d47b7          	lui	a5,0x554d4
    80005d00:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005d04:	0af71963          	bne	a4,a5,80005db6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d08:	100017b7          	lui	a5,0x10001
    80005d0c:	4705                	li	a4,1
    80005d0e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d10:	470d                	li	a4,3
    80005d12:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005d14:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005d16:	c7ffe737          	lui	a4,0xc7ffe
    80005d1a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005d1e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005d20:	2701                	sext.w	a4,a4
    80005d22:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d24:	472d                	li	a4,11
    80005d26:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005d28:	473d                	li	a4,15
    80005d2a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005d2c:	6705                	lui	a4,0x1
    80005d2e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005d30:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005d34:	5bdc                	lw	a5,52(a5)
    80005d36:	2781                	sext.w	a5,a5
  if(max == 0)
    80005d38:	c7d9                	beqz	a5,80005dc6 <virtio_disk_init+0x124>
  if(max < NUM)
    80005d3a:	471d                	li	a4,7
    80005d3c:	08f77d63          	bgeu	a4,a5,80005dd6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005d40:	100014b7          	lui	s1,0x10001
    80005d44:	47a1                	li	a5,8
    80005d46:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005d48:	6609                	lui	a2,0x2
    80005d4a:	4581                	li	a1,0
    80005d4c:	0001d517          	auipc	a0,0x1d
    80005d50:	2b450513          	addi	a0,a0,692 # 80023000 <disk>
    80005d54:	ffffb097          	auipc	ra,0xffffb
    80005d58:	f7e080e7          	jalr	-130(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005d5c:	0001d717          	auipc	a4,0x1d
    80005d60:	2a470713          	addi	a4,a4,676 # 80023000 <disk>
    80005d64:	00c75793          	srli	a5,a4,0xc
    80005d68:	2781                	sext.w	a5,a5
    80005d6a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005d6c:	0001f797          	auipc	a5,0x1f
    80005d70:	29478793          	addi	a5,a5,660 # 80025000 <disk+0x2000>
    80005d74:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005d76:	0001d717          	auipc	a4,0x1d
    80005d7a:	30a70713          	addi	a4,a4,778 # 80023080 <disk+0x80>
    80005d7e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005d80:	0001e717          	auipc	a4,0x1e
    80005d84:	28070713          	addi	a4,a4,640 # 80024000 <disk+0x1000>
    80005d88:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005d8a:	4705                	li	a4,1
    80005d8c:	00e78c23          	sb	a4,24(a5)
    80005d90:	00e78ca3          	sb	a4,25(a5)
    80005d94:	00e78d23          	sb	a4,26(a5)
    80005d98:	00e78da3          	sb	a4,27(a5)
    80005d9c:	00e78e23          	sb	a4,28(a5)
    80005da0:	00e78ea3          	sb	a4,29(a5)
    80005da4:	00e78f23          	sb	a4,30(a5)
    80005da8:	00e78fa3          	sb	a4,31(a5)
}
    80005dac:	60e2                	ld	ra,24(sp)
    80005dae:	6442                	ld	s0,16(sp)
    80005db0:	64a2                	ld	s1,8(sp)
    80005db2:	6105                	addi	sp,sp,32
    80005db4:	8082                	ret
    panic("could not find virtio disk");
    80005db6:	00003517          	auipc	a0,0x3
    80005dba:	9d250513          	addi	a0,a0,-1582 # 80008788 <syscalls+0x358>
    80005dbe:	ffffa097          	auipc	ra,0xffffa
    80005dc2:	772080e7          	jalr	1906(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    80005dc6:	00003517          	auipc	a0,0x3
    80005dca:	9e250513          	addi	a0,a0,-1566 # 800087a8 <syscalls+0x378>
    80005dce:	ffffa097          	auipc	ra,0xffffa
    80005dd2:	762080e7          	jalr	1890(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    80005dd6:	00003517          	auipc	a0,0x3
    80005dda:	9f250513          	addi	a0,a0,-1550 # 800087c8 <syscalls+0x398>
    80005dde:	ffffa097          	auipc	ra,0xffffa
    80005de2:	752080e7          	jalr	1874(ra) # 80000530 <panic>

0000000080005de6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005de6:	7159                	addi	sp,sp,-112
    80005de8:	f486                	sd	ra,104(sp)
    80005dea:	f0a2                	sd	s0,96(sp)
    80005dec:	eca6                	sd	s1,88(sp)
    80005dee:	e8ca                	sd	s2,80(sp)
    80005df0:	e4ce                	sd	s3,72(sp)
    80005df2:	e0d2                	sd	s4,64(sp)
    80005df4:	fc56                	sd	s5,56(sp)
    80005df6:	f85a                	sd	s6,48(sp)
    80005df8:	f45e                	sd	s7,40(sp)
    80005dfa:	f062                	sd	s8,32(sp)
    80005dfc:	ec66                	sd	s9,24(sp)
    80005dfe:	e86a                	sd	s10,16(sp)
    80005e00:	1880                	addi	s0,sp,112
    80005e02:	892a                	mv	s2,a0
    80005e04:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005e06:	00c52c83          	lw	s9,12(a0)
    80005e0a:	001c9c9b          	slliw	s9,s9,0x1
    80005e0e:	1c82                	slli	s9,s9,0x20
    80005e10:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005e14:	0001f517          	auipc	a0,0x1f
    80005e18:	31450513          	addi	a0,a0,788 # 80025128 <disk+0x2128>
    80005e1c:	ffffb097          	auipc	ra,0xffffb
    80005e20:	dba080e7          	jalr	-582(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80005e24:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005e26:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005e28:	0001db97          	auipc	s7,0x1d
    80005e2c:	1d8b8b93          	addi	s7,s7,472 # 80023000 <disk>
    80005e30:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005e32:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005e34:	8a4e                	mv	s4,s3
    80005e36:	a051                	j	80005eba <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005e38:	00fb86b3          	add	a3,s7,a5
    80005e3c:	96da                	add	a3,a3,s6
    80005e3e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005e42:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005e44:	0207c563          	bltz	a5,80005e6e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005e48:	2485                	addiw	s1,s1,1
    80005e4a:	0711                	addi	a4,a4,4
    80005e4c:	25548063          	beq	s1,s5,8000608c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80005e50:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005e52:	0001f697          	auipc	a3,0x1f
    80005e56:	1c668693          	addi	a3,a3,454 # 80025018 <disk+0x2018>
    80005e5a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005e5c:	0006c583          	lbu	a1,0(a3)
    80005e60:	fde1                	bnez	a1,80005e38 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005e62:	2785                	addiw	a5,a5,1
    80005e64:	0685                	addi	a3,a3,1
    80005e66:	ff879be3          	bne	a5,s8,80005e5c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005e6a:	57fd                	li	a5,-1
    80005e6c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005e6e:	02905a63          	blez	s1,80005ea2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005e72:	f9042503          	lw	a0,-112(s0)
    80005e76:	00000097          	auipc	ra,0x0
    80005e7a:	d90080e7          	jalr	-624(ra) # 80005c06 <free_desc>
      for(int j = 0; j < i; j++)
    80005e7e:	4785                	li	a5,1
    80005e80:	0297d163          	bge	a5,s1,80005ea2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005e84:	f9442503          	lw	a0,-108(s0)
    80005e88:	00000097          	auipc	ra,0x0
    80005e8c:	d7e080e7          	jalr	-642(ra) # 80005c06 <free_desc>
      for(int j = 0; j < i; j++)
    80005e90:	4789                	li	a5,2
    80005e92:	0097d863          	bge	a5,s1,80005ea2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005e96:	f9842503          	lw	a0,-104(s0)
    80005e9a:	00000097          	auipc	ra,0x0
    80005e9e:	d6c080e7          	jalr	-660(ra) # 80005c06 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ea2:	0001f597          	auipc	a1,0x1f
    80005ea6:	28658593          	addi	a1,a1,646 # 80025128 <disk+0x2128>
    80005eaa:	0001f517          	auipc	a0,0x1f
    80005eae:	16e50513          	addi	a0,a0,366 # 80025018 <disk+0x2018>
    80005eb2:	ffffc097          	auipc	ra,0xffffc
    80005eb6:	19e080e7          	jalr	414(ra) # 80002050 <sleep>
  for(int i = 0; i < 3; i++){
    80005eba:	f9040713          	addi	a4,s0,-112
    80005ebe:	84ce                	mv	s1,s3
    80005ec0:	bf41                	j	80005e50 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80005ec2:	20058713          	addi	a4,a1,512
    80005ec6:	00471693          	slli	a3,a4,0x4
    80005eca:	0001d717          	auipc	a4,0x1d
    80005ece:	13670713          	addi	a4,a4,310 # 80023000 <disk>
    80005ed2:	9736                	add	a4,a4,a3
    80005ed4:	4685                	li	a3,1
    80005ed6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005eda:	20058713          	addi	a4,a1,512
    80005ede:	00471693          	slli	a3,a4,0x4
    80005ee2:	0001d717          	auipc	a4,0x1d
    80005ee6:	11e70713          	addi	a4,a4,286 # 80023000 <disk>
    80005eea:	9736                	add	a4,a4,a3
    80005eec:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80005ef0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005ef4:	7679                	lui	a2,0xffffe
    80005ef6:	963e                	add	a2,a2,a5
    80005ef8:	0001f697          	auipc	a3,0x1f
    80005efc:	10868693          	addi	a3,a3,264 # 80025000 <disk+0x2000>
    80005f00:	6298                	ld	a4,0(a3)
    80005f02:	9732                	add	a4,a4,a2
    80005f04:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005f06:	6298                	ld	a4,0(a3)
    80005f08:	9732                	add	a4,a4,a2
    80005f0a:	4541                	li	a0,16
    80005f0c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005f0e:	6298                	ld	a4,0(a3)
    80005f10:	9732                	add	a4,a4,a2
    80005f12:	4505                	li	a0,1
    80005f14:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80005f18:	f9442703          	lw	a4,-108(s0)
    80005f1c:	6288                	ld	a0,0(a3)
    80005f1e:	962a                	add	a2,a2,a0
    80005f20:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005f24:	0712                	slli	a4,a4,0x4
    80005f26:	6290                	ld	a2,0(a3)
    80005f28:	963a                	add	a2,a2,a4
    80005f2a:	05890513          	addi	a0,s2,88
    80005f2e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005f30:	6294                	ld	a3,0(a3)
    80005f32:	96ba                	add	a3,a3,a4
    80005f34:	40000613          	li	a2,1024
    80005f38:	c690                	sw	a2,8(a3)
  if(write)
    80005f3a:	140d0063          	beqz	s10,8000607a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f3e:	0001f697          	auipc	a3,0x1f
    80005f42:	0c26b683          	ld	a3,194(a3) # 80025000 <disk+0x2000>
    80005f46:	96ba                	add	a3,a3,a4
    80005f48:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f4c:	0001d817          	auipc	a6,0x1d
    80005f50:	0b480813          	addi	a6,a6,180 # 80023000 <disk>
    80005f54:	0001f517          	auipc	a0,0x1f
    80005f58:	0ac50513          	addi	a0,a0,172 # 80025000 <disk+0x2000>
    80005f5c:	6114                	ld	a3,0(a0)
    80005f5e:	96ba                	add	a3,a3,a4
    80005f60:	00c6d603          	lhu	a2,12(a3)
    80005f64:	00166613          	ori	a2,a2,1
    80005f68:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005f6c:	f9842683          	lw	a3,-104(s0)
    80005f70:	6110                	ld	a2,0(a0)
    80005f72:	9732                	add	a4,a4,a2
    80005f74:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005f78:	20058613          	addi	a2,a1,512
    80005f7c:	0612                	slli	a2,a2,0x4
    80005f7e:	9642                	add	a2,a2,a6
    80005f80:	577d                	li	a4,-1
    80005f82:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005f86:	00469713          	slli	a4,a3,0x4
    80005f8a:	6114                	ld	a3,0(a0)
    80005f8c:	96ba                	add	a3,a3,a4
    80005f8e:	03078793          	addi	a5,a5,48
    80005f92:	97c2                	add	a5,a5,a6
    80005f94:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80005f96:	611c                	ld	a5,0(a0)
    80005f98:	97ba                	add	a5,a5,a4
    80005f9a:	4685                	li	a3,1
    80005f9c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005f9e:	611c                	ld	a5,0(a0)
    80005fa0:	97ba                	add	a5,a5,a4
    80005fa2:	4809                	li	a6,2
    80005fa4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80005fa8:	611c                	ld	a5,0(a0)
    80005faa:	973e                	add	a4,a4,a5
    80005fac:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005fb0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80005fb4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005fb8:	6518                	ld	a4,8(a0)
    80005fba:	00275783          	lhu	a5,2(a4)
    80005fbe:	8b9d                	andi	a5,a5,7
    80005fc0:	0786                	slli	a5,a5,0x1
    80005fc2:	97ba                	add	a5,a5,a4
    80005fc4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80005fc8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005fcc:	6518                	ld	a4,8(a0)
    80005fce:	00275783          	lhu	a5,2(a4)
    80005fd2:	2785                	addiw	a5,a5,1
    80005fd4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005fd8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005fdc:	100017b7          	lui	a5,0x10001
    80005fe0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005fe4:	00492703          	lw	a4,4(s2)
    80005fe8:	4785                	li	a5,1
    80005fea:	02f71163          	bne	a4,a5,8000600c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    80005fee:	0001f997          	auipc	s3,0x1f
    80005ff2:	13a98993          	addi	s3,s3,314 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80005ff6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80005ff8:	85ce                	mv	a1,s3
    80005ffa:	854a                	mv	a0,s2
    80005ffc:	ffffc097          	auipc	ra,0xffffc
    80006000:	054080e7          	jalr	84(ra) # 80002050 <sleep>
  while(b->disk == 1) {
    80006004:	00492783          	lw	a5,4(s2)
    80006008:	fe9788e3          	beq	a5,s1,80005ff8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000600c:	f9042903          	lw	s2,-112(s0)
    80006010:	20090793          	addi	a5,s2,512
    80006014:	00479713          	slli	a4,a5,0x4
    80006018:	0001d797          	auipc	a5,0x1d
    8000601c:	fe878793          	addi	a5,a5,-24 # 80023000 <disk>
    80006020:	97ba                	add	a5,a5,a4
    80006022:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006026:	0001f997          	auipc	s3,0x1f
    8000602a:	fda98993          	addi	s3,s3,-38 # 80025000 <disk+0x2000>
    8000602e:	00491713          	slli	a4,s2,0x4
    80006032:	0009b783          	ld	a5,0(s3)
    80006036:	97ba                	add	a5,a5,a4
    80006038:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000603c:	854a                	mv	a0,s2
    8000603e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006042:	00000097          	auipc	ra,0x0
    80006046:	bc4080e7          	jalr	-1084(ra) # 80005c06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000604a:	8885                	andi	s1,s1,1
    8000604c:	f0ed                	bnez	s1,8000602e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000604e:	0001f517          	auipc	a0,0x1f
    80006052:	0da50513          	addi	a0,a0,218 # 80025128 <disk+0x2128>
    80006056:	ffffb097          	auipc	ra,0xffffb
    8000605a:	c34080e7          	jalr	-972(ra) # 80000c8a <release>
}
    8000605e:	70a6                	ld	ra,104(sp)
    80006060:	7406                	ld	s0,96(sp)
    80006062:	64e6                	ld	s1,88(sp)
    80006064:	6946                	ld	s2,80(sp)
    80006066:	69a6                	ld	s3,72(sp)
    80006068:	6a06                	ld	s4,64(sp)
    8000606a:	7ae2                	ld	s5,56(sp)
    8000606c:	7b42                	ld	s6,48(sp)
    8000606e:	7ba2                	ld	s7,40(sp)
    80006070:	7c02                	ld	s8,32(sp)
    80006072:	6ce2                	ld	s9,24(sp)
    80006074:	6d42                	ld	s10,16(sp)
    80006076:	6165                	addi	sp,sp,112
    80006078:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000607a:	0001f697          	auipc	a3,0x1f
    8000607e:	f866b683          	ld	a3,-122(a3) # 80025000 <disk+0x2000>
    80006082:	96ba                	add	a3,a3,a4
    80006084:	4609                	li	a2,2
    80006086:	00c69623          	sh	a2,12(a3)
    8000608a:	b5c9                	j	80005f4c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000608c:	f9042583          	lw	a1,-112(s0)
    80006090:	20058793          	addi	a5,a1,512
    80006094:	0792                	slli	a5,a5,0x4
    80006096:	0001d517          	auipc	a0,0x1d
    8000609a:	01250513          	addi	a0,a0,18 # 800230a8 <disk+0xa8>
    8000609e:	953e                	add	a0,a0,a5
  if(write)
    800060a0:	e20d11e3          	bnez	s10,80005ec2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800060a4:	20058713          	addi	a4,a1,512
    800060a8:	00471693          	slli	a3,a4,0x4
    800060ac:	0001d717          	auipc	a4,0x1d
    800060b0:	f5470713          	addi	a4,a4,-172 # 80023000 <disk>
    800060b4:	9736                	add	a4,a4,a3
    800060b6:	0a072423          	sw	zero,168(a4)
    800060ba:	b505                	j	80005eda <virtio_disk_rw+0xf4>

00000000800060bc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800060bc:	1101                	addi	sp,sp,-32
    800060be:	ec06                	sd	ra,24(sp)
    800060c0:	e822                	sd	s0,16(sp)
    800060c2:	e426                	sd	s1,8(sp)
    800060c4:	e04a                	sd	s2,0(sp)
    800060c6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800060c8:	0001f517          	auipc	a0,0x1f
    800060cc:	06050513          	addi	a0,a0,96 # 80025128 <disk+0x2128>
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	b06080e7          	jalr	-1274(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800060d8:	10001737          	lui	a4,0x10001
    800060dc:	533c                	lw	a5,96(a4)
    800060de:	8b8d                	andi	a5,a5,3
    800060e0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800060e2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800060e6:	0001f797          	auipc	a5,0x1f
    800060ea:	f1a78793          	addi	a5,a5,-230 # 80025000 <disk+0x2000>
    800060ee:	6b94                	ld	a3,16(a5)
    800060f0:	0207d703          	lhu	a4,32(a5)
    800060f4:	0026d783          	lhu	a5,2(a3)
    800060f8:	06f70163          	beq	a4,a5,8000615a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800060fc:	0001d917          	auipc	s2,0x1d
    80006100:	f0490913          	addi	s2,s2,-252 # 80023000 <disk>
    80006104:	0001f497          	auipc	s1,0x1f
    80006108:	efc48493          	addi	s1,s1,-260 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000610c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006110:	6898                	ld	a4,16(s1)
    80006112:	0204d783          	lhu	a5,32(s1)
    80006116:	8b9d                	andi	a5,a5,7
    80006118:	078e                	slli	a5,a5,0x3
    8000611a:	97ba                	add	a5,a5,a4
    8000611c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000611e:	20078713          	addi	a4,a5,512
    80006122:	0712                	slli	a4,a4,0x4
    80006124:	974a                	add	a4,a4,s2
    80006126:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000612a:	e731                	bnez	a4,80006176 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000612c:	20078793          	addi	a5,a5,512
    80006130:	0792                	slli	a5,a5,0x4
    80006132:	97ca                	add	a5,a5,s2
    80006134:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006136:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000613a:	ffffc097          	auipc	ra,0xffffc
    8000613e:	0a2080e7          	jalr	162(ra) # 800021dc <wakeup>

    disk.used_idx += 1;
    80006142:	0204d783          	lhu	a5,32(s1)
    80006146:	2785                	addiw	a5,a5,1
    80006148:	17c2                	slli	a5,a5,0x30
    8000614a:	93c1                	srli	a5,a5,0x30
    8000614c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006150:	6898                	ld	a4,16(s1)
    80006152:	00275703          	lhu	a4,2(a4)
    80006156:	faf71be3          	bne	a4,a5,8000610c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000615a:	0001f517          	auipc	a0,0x1f
    8000615e:	fce50513          	addi	a0,a0,-50 # 80025128 <disk+0x2128>
    80006162:	ffffb097          	auipc	ra,0xffffb
    80006166:	b28080e7          	jalr	-1240(ra) # 80000c8a <release>
}
    8000616a:	60e2                	ld	ra,24(sp)
    8000616c:	6442                	ld	s0,16(sp)
    8000616e:	64a2                	ld	s1,8(sp)
    80006170:	6902                	ld	s2,0(sp)
    80006172:	6105                	addi	sp,sp,32
    80006174:	8082                	ret
      panic("virtio_disk_intr status");
    80006176:	00002517          	auipc	a0,0x2
    8000617a:	67250513          	addi	a0,a0,1650 # 800087e8 <syscalls+0x3b8>
    8000617e:	ffffa097          	auipc	ra,0xffffa
    80006182:	3b2080e7          	jalr	946(ra) # 80000530 <panic>
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
