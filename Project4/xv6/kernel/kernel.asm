
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
    80000f66:	dfe080e7          	jalr	-514(ra) # 80002d60 <binit>
    iinit();         // inode cache
    80000f6a:	00002097          	auipc	ra,0x2
    80000f6e:	48e080e7          	jalr	1166(ra) # 800033f8 <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	438080e7          	jalr	1080(ra) # 800043aa <fileinit>
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
    80001a0c:	970080e7          	jalr	-1680(ra) # 80003378 <fsinit>
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
    80001cce:	0dc080e7          	jalr	220(ra) # 80003da6 <namei>
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
    80001e04:	63c080e7          	jalr	1596(ra) # 8000443c <filedup>
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
    80001e26:	790080e7          	jalr	1936(ra) # 800035b2 <idup>
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
    800022f0:	1a2080e7          	jalr	418(ra) # 8000448e <fileclose>
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
    80002308:	cbe080e7          	jalr	-834(ra) # 80003fc2 <begin_op>
  iput(p->cwd);
    8000230c:	1509b503          	ld	a0,336(s3)
    80002310:	00001097          	auipc	ra,0x1
    80002314:	49a080e7          	jalr	1178(ra) # 800037aa <iput>
  end_op();
    80002318:	00002097          	auipc	ra,0x2
    8000231c:	d2a080e7          	jalr	-726(ra) # 80004042 <end_op>
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
  int tticks;

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
  
    80002d54:	8526                	mv	a0,s1
    80002d56:	60e2                	ld	ra,24(sp)
    80002d58:	6442                	ld	s0,16(sp)
    80002d5a:	64a2                	ld	s1,8(sp)
    80002d5c:	6105                	addi	sp,sp,32
    80002d5e:	8082                	ret

0000000080002d60 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d60:	7179                	addi	sp,sp,-48
    80002d62:	f406                	sd	ra,40(sp)
    80002d64:	f022                	sd	s0,32(sp)
    80002d66:	ec26                	sd	s1,24(sp)
    80002d68:	e84a                	sd	s2,16(sp)
    80002d6a:	e44e                	sd	s3,8(sp)
    80002d6c:	e052                	sd	s4,0(sp)
    80002d6e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d70:	00005597          	auipc	a1,0x5
    80002d74:	77858593          	addi	a1,a1,1912 # 800084e8 <syscalls+0xb8>
    80002d78:	00014517          	auipc	a0,0x14
    80002d7c:	37050513          	addi	a0,a0,880 # 800170e8 <bcache>
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	dc6080e7          	jalr	-570(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d88:	0001c797          	auipc	a5,0x1c
    80002d8c:	36078793          	addi	a5,a5,864 # 8001f0e8 <bcache+0x8000>
    80002d90:	0001c717          	auipc	a4,0x1c
    80002d94:	5c070713          	addi	a4,a4,1472 # 8001f350 <bcache+0x8268>
    80002d98:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002d9c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002da0:	00014497          	auipc	s1,0x14
    80002da4:	36048493          	addi	s1,s1,864 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002da8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002daa:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002dac:	00005a17          	auipc	s4,0x5
    80002db0:	744a0a13          	addi	s4,s4,1860 # 800084f0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002db4:	2b893783          	ld	a5,696(s2)
    80002db8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002dba:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002dbe:	85d2                	mv	a1,s4
    80002dc0:	01048513          	addi	a0,s1,16
    80002dc4:	00001097          	auipc	ra,0x1
    80002dc8:	4bc080e7          	jalr	1212(ra) # 80004280 <initsleeplock>
    bcache.head.next->prev = b;
    80002dcc:	2b893783          	ld	a5,696(s2)
    80002dd0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002dd2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dd6:	45848493          	addi	s1,s1,1112
    80002dda:	fd349de3          	bne	s1,s3,80002db4 <binit+0x54>
  }
}
    80002dde:	70a2                	ld	ra,40(sp)
    80002de0:	7402                	ld	s0,32(sp)
    80002de2:	64e2                	ld	s1,24(sp)
    80002de4:	6942                	ld	s2,16(sp)
    80002de6:	69a2                	ld	s3,8(sp)
    80002de8:	6a02                	ld	s4,0(sp)
    80002dea:	6145                	addi	sp,sp,48
    80002dec:	8082                	ret

0000000080002dee <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002dee:	7179                	addi	sp,sp,-48
    80002df0:	f406                	sd	ra,40(sp)
    80002df2:	f022                	sd	s0,32(sp)
    80002df4:	ec26                	sd	s1,24(sp)
    80002df6:	e84a                	sd	s2,16(sp)
    80002df8:	e44e                	sd	s3,8(sp)
    80002dfa:	1800                	addi	s0,sp,48
    80002dfc:	89aa                	mv	s3,a0
    80002dfe:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e00:	00014517          	auipc	a0,0x14
    80002e04:	2e850513          	addi	a0,a0,744 # 800170e8 <bcache>
    80002e08:	ffffe097          	auipc	ra,0xffffe
    80002e0c:	dce080e7          	jalr	-562(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e10:	0001c497          	auipc	s1,0x1c
    80002e14:	5904b483          	ld	s1,1424(s1) # 8001f3a0 <bcache+0x82b8>
    80002e18:	0001c797          	auipc	a5,0x1c
    80002e1c:	53878793          	addi	a5,a5,1336 # 8001f350 <bcache+0x8268>
    80002e20:	02f48f63          	beq	s1,a5,80002e5e <bread+0x70>
    80002e24:	873e                	mv	a4,a5
    80002e26:	a021                	j	80002e2e <bread+0x40>
    80002e28:	68a4                	ld	s1,80(s1)
    80002e2a:	02e48a63          	beq	s1,a4,80002e5e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e2e:	449c                	lw	a5,8(s1)
    80002e30:	ff379ce3          	bne	a5,s3,80002e28 <bread+0x3a>
    80002e34:	44dc                	lw	a5,12(s1)
    80002e36:	ff2799e3          	bne	a5,s2,80002e28 <bread+0x3a>
      b->refcnt++;
    80002e3a:	40bc                	lw	a5,64(s1)
    80002e3c:	2785                	addiw	a5,a5,1
    80002e3e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e40:	00014517          	auipc	a0,0x14
    80002e44:	2a850513          	addi	a0,a0,680 # 800170e8 <bcache>
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002e50:	01048513          	addi	a0,s1,16
    80002e54:	00001097          	auipc	ra,0x1
    80002e58:	466080e7          	jalr	1126(ra) # 800042ba <acquiresleep>
      return b;
    80002e5c:	a8b9                	j	80002eba <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e5e:	0001c497          	auipc	s1,0x1c
    80002e62:	53a4b483          	ld	s1,1338(s1) # 8001f398 <bcache+0x82b0>
    80002e66:	0001c797          	auipc	a5,0x1c
    80002e6a:	4ea78793          	addi	a5,a5,1258 # 8001f350 <bcache+0x8268>
    80002e6e:	00f48863          	beq	s1,a5,80002e7e <bread+0x90>
    80002e72:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e74:	40bc                	lw	a5,64(s1)
    80002e76:	cf81                	beqz	a5,80002e8e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e78:	64a4                	ld	s1,72(s1)
    80002e7a:	fee49de3          	bne	s1,a4,80002e74 <bread+0x86>
  panic("bget: no buffers");
    80002e7e:	00005517          	auipc	a0,0x5
    80002e82:	67a50513          	addi	a0,a0,1658 # 800084f8 <syscalls+0xc8>
    80002e86:	ffffd097          	auipc	ra,0xffffd
    80002e8a:	6aa080e7          	jalr	1706(ra) # 80000530 <panic>
      b->dev = dev;
    80002e8e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002e92:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002e96:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e9a:	4785                	li	a5,1
    80002e9c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e9e:	00014517          	auipc	a0,0x14
    80002ea2:	24a50513          	addi	a0,a0,586 # 800170e8 <bcache>
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	de4080e7          	jalr	-540(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002eae:	01048513          	addi	a0,s1,16
    80002eb2:	00001097          	auipc	ra,0x1
    80002eb6:	408080e7          	jalr	1032(ra) # 800042ba <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002eba:	409c                	lw	a5,0(s1)
    80002ebc:	cb89                	beqz	a5,80002ece <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ebe:	8526                	mv	a0,s1
    80002ec0:	70a2                	ld	ra,40(sp)
    80002ec2:	7402                	ld	s0,32(sp)
    80002ec4:	64e2                	ld	s1,24(sp)
    80002ec6:	6942                	ld	s2,16(sp)
    80002ec8:	69a2                	ld	s3,8(sp)
    80002eca:	6145                	addi	sp,sp,48
    80002ecc:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ece:	4581                	li	a1,0
    80002ed0:	8526                	mv	a0,s1
    80002ed2:	00003097          	auipc	ra,0x3
    80002ed6:	f14080e7          	jalr	-236(ra) # 80005de6 <virtio_disk_rw>
    b->valid = 1;
    80002eda:	4785                	li	a5,1
    80002edc:	c09c                	sw	a5,0(s1)
  return b;
    80002ede:	b7c5                	j	80002ebe <bread+0xd0>

0000000080002ee0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ee0:	1101                	addi	sp,sp,-32
    80002ee2:	ec06                	sd	ra,24(sp)
    80002ee4:	e822                	sd	s0,16(sp)
    80002ee6:	e426                	sd	s1,8(sp)
    80002ee8:	1000                	addi	s0,sp,32
    80002eea:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002eec:	0541                	addi	a0,a0,16
    80002eee:	00001097          	auipc	ra,0x1
    80002ef2:	466080e7          	jalr	1126(ra) # 80004354 <holdingsleep>
    80002ef6:	cd01                	beqz	a0,80002f0e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ef8:	4585                	li	a1,1
    80002efa:	8526                	mv	a0,s1
    80002efc:	00003097          	auipc	ra,0x3
    80002f00:	eea080e7          	jalr	-278(ra) # 80005de6 <virtio_disk_rw>
}
    80002f04:	60e2                	ld	ra,24(sp)
    80002f06:	6442                	ld	s0,16(sp)
    80002f08:	64a2                	ld	s1,8(sp)
    80002f0a:	6105                	addi	sp,sp,32
    80002f0c:	8082                	ret
    panic("bwrite");
    80002f0e:	00005517          	auipc	a0,0x5
    80002f12:	60250513          	addi	a0,a0,1538 # 80008510 <syscalls+0xe0>
    80002f16:	ffffd097          	auipc	ra,0xffffd
    80002f1a:	61a080e7          	jalr	1562(ra) # 80000530 <panic>

0000000080002f1e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f1e:	1101                	addi	sp,sp,-32
    80002f20:	ec06                	sd	ra,24(sp)
    80002f22:	e822                	sd	s0,16(sp)
    80002f24:	e426                	sd	s1,8(sp)
    80002f26:	e04a                	sd	s2,0(sp)
    80002f28:	1000                	addi	s0,sp,32
    80002f2a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f2c:	01050913          	addi	s2,a0,16
    80002f30:	854a                	mv	a0,s2
    80002f32:	00001097          	auipc	ra,0x1
    80002f36:	422080e7          	jalr	1058(ra) # 80004354 <holdingsleep>
    80002f3a:	c92d                	beqz	a0,80002fac <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f3c:	854a                	mv	a0,s2
    80002f3e:	00001097          	auipc	ra,0x1
    80002f42:	3d2080e7          	jalr	978(ra) # 80004310 <releasesleep>

  acquire(&bcache.lock);
    80002f46:	00014517          	auipc	a0,0x14
    80002f4a:	1a250513          	addi	a0,a0,418 # 800170e8 <bcache>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	c88080e7          	jalr	-888(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80002f56:	40bc                	lw	a5,64(s1)
    80002f58:	37fd                	addiw	a5,a5,-1
    80002f5a:	0007871b          	sext.w	a4,a5
    80002f5e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f60:	eb05                	bnez	a4,80002f90 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f62:	68bc                	ld	a5,80(s1)
    80002f64:	64b8                	ld	a4,72(s1)
    80002f66:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f68:	64bc                	ld	a5,72(s1)
    80002f6a:	68b8                	ld	a4,80(s1)
    80002f6c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f6e:	0001c797          	auipc	a5,0x1c
    80002f72:	17a78793          	addi	a5,a5,378 # 8001f0e8 <bcache+0x8000>
    80002f76:	2b87b703          	ld	a4,696(a5)
    80002f7a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f7c:	0001c717          	auipc	a4,0x1c
    80002f80:	3d470713          	addi	a4,a4,980 # 8001f350 <bcache+0x8268>
    80002f84:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f86:	2b87b703          	ld	a4,696(a5)
    80002f8a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f8c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f90:	00014517          	auipc	a0,0x14
    80002f94:	15850513          	addi	a0,a0,344 # 800170e8 <bcache>
    80002f98:	ffffe097          	auipc	ra,0xffffe
    80002f9c:	cf2080e7          	jalr	-782(ra) # 80000c8a <release>
}
    80002fa0:	60e2                	ld	ra,24(sp)
    80002fa2:	6442                	ld	s0,16(sp)
    80002fa4:	64a2                	ld	s1,8(sp)
    80002fa6:	6902                	ld	s2,0(sp)
    80002fa8:	6105                	addi	sp,sp,32
    80002faa:	8082                	ret
    panic("brelse");
    80002fac:	00005517          	auipc	a0,0x5
    80002fb0:	56c50513          	addi	a0,a0,1388 # 80008518 <syscalls+0xe8>
    80002fb4:	ffffd097          	auipc	ra,0xffffd
    80002fb8:	57c080e7          	jalr	1404(ra) # 80000530 <panic>

0000000080002fbc <bpin>:

void
bpin(struct buf *b) {
    80002fbc:	1101                	addi	sp,sp,-32
    80002fbe:	ec06                	sd	ra,24(sp)
    80002fc0:	e822                	sd	s0,16(sp)
    80002fc2:	e426                	sd	s1,8(sp)
    80002fc4:	1000                	addi	s0,sp,32
    80002fc6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fc8:	00014517          	auipc	a0,0x14
    80002fcc:	12050513          	addi	a0,a0,288 # 800170e8 <bcache>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	c06080e7          	jalr	-1018(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80002fd8:	40bc                	lw	a5,64(s1)
    80002fda:	2785                	addiw	a5,a5,1
    80002fdc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fde:	00014517          	auipc	a0,0x14
    80002fe2:	10a50513          	addi	a0,a0,266 # 800170e8 <bcache>
    80002fe6:	ffffe097          	auipc	ra,0xffffe
    80002fea:	ca4080e7          	jalr	-860(ra) # 80000c8a <release>
}
    80002fee:	60e2                	ld	ra,24(sp)
    80002ff0:	6442                	ld	s0,16(sp)
    80002ff2:	64a2                	ld	s1,8(sp)
    80002ff4:	6105                	addi	sp,sp,32
    80002ff6:	8082                	ret

0000000080002ff8 <bunpin>:

void
bunpin(struct buf *b) {
    80002ff8:	1101                	addi	sp,sp,-32
    80002ffa:	ec06                	sd	ra,24(sp)
    80002ffc:	e822                	sd	s0,16(sp)
    80002ffe:	e426                	sd	s1,8(sp)
    80003000:	1000                	addi	s0,sp,32
    80003002:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003004:	00014517          	auipc	a0,0x14
    80003008:	0e450513          	addi	a0,a0,228 # 800170e8 <bcache>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	bca080e7          	jalr	-1078(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003014:	40bc                	lw	a5,64(s1)
    80003016:	37fd                	addiw	a5,a5,-1
    80003018:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000301a:	00014517          	auipc	a0,0x14
    8000301e:	0ce50513          	addi	a0,a0,206 # 800170e8 <bcache>
    80003022:	ffffe097          	auipc	ra,0xffffe
    80003026:	c68080e7          	jalr	-920(ra) # 80000c8a <release>
}
    8000302a:	60e2                	ld	ra,24(sp)
    8000302c:	6442                	ld	s0,16(sp)
    8000302e:	64a2                	ld	s1,8(sp)
    80003030:	6105                	addi	sp,sp,32
    80003032:	8082                	ret

0000000080003034 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003034:	1101                	addi	sp,sp,-32
    80003036:	ec06                	sd	ra,24(sp)
    80003038:	e822                	sd	s0,16(sp)
    8000303a:	e426                	sd	s1,8(sp)
    8000303c:	e04a                	sd	s2,0(sp)
    8000303e:	1000                	addi	s0,sp,32
    80003040:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003042:	00d5d59b          	srliw	a1,a1,0xd
    80003046:	0001c797          	auipc	a5,0x1c
    8000304a:	77e7a783          	lw	a5,1918(a5) # 8001f7c4 <sb+0x1c>
    8000304e:	9dbd                	addw	a1,a1,a5
    80003050:	00000097          	auipc	ra,0x0
    80003054:	d9e080e7          	jalr	-610(ra) # 80002dee <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003058:	0074f713          	andi	a4,s1,7
    8000305c:	4785                	li	a5,1
    8000305e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003062:	14ce                	slli	s1,s1,0x33
    80003064:	90d9                	srli	s1,s1,0x36
    80003066:	00950733          	add	a4,a0,s1
    8000306a:	05874703          	lbu	a4,88(a4)
    8000306e:	00e7f6b3          	and	a3,a5,a4
    80003072:	c69d                	beqz	a3,800030a0 <bfree+0x6c>
    80003074:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003076:	94aa                	add	s1,s1,a0
    80003078:	fff7c793          	not	a5,a5
    8000307c:	8ff9                	and	a5,a5,a4
    8000307e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003082:	00001097          	auipc	ra,0x1
    80003086:	118080e7          	jalr	280(ra) # 8000419a <log_write>
  brelse(bp);
    8000308a:	854a                	mv	a0,s2
    8000308c:	00000097          	auipc	ra,0x0
    80003090:	e92080e7          	jalr	-366(ra) # 80002f1e <brelse>
}
    80003094:	60e2                	ld	ra,24(sp)
    80003096:	6442                	ld	s0,16(sp)
    80003098:	64a2                	ld	s1,8(sp)
    8000309a:	6902                	ld	s2,0(sp)
    8000309c:	6105                	addi	sp,sp,32
    8000309e:	8082                	ret
    panic("freeing free block");
    800030a0:	00005517          	auipc	a0,0x5
    800030a4:	48050513          	addi	a0,a0,1152 # 80008520 <syscalls+0xf0>
    800030a8:	ffffd097          	auipc	ra,0xffffd
    800030ac:	488080e7          	jalr	1160(ra) # 80000530 <panic>

00000000800030b0 <balloc>:
{
    800030b0:	711d                	addi	sp,sp,-96
    800030b2:	ec86                	sd	ra,88(sp)
    800030b4:	e8a2                	sd	s0,80(sp)
    800030b6:	e4a6                	sd	s1,72(sp)
    800030b8:	e0ca                	sd	s2,64(sp)
    800030ba:	fc4e                	sd	s3,56(sp)
    800030bc:	f852                	sd	s4,48(sp)
    800030be:	f456                	sd	s5,40(sp)
    800030c0:	f05a                	sd	s6,32(sp)
    800030c2:	ec5e                	sd	s7,24(sp)
    800030c4:	e862                	sd	s8,16(sp)
    800030c6:	e466                	sd	s9,8(sp)
    800030c8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030ca:	0001c797          	auipc	a5,0x1c
    800030ce:	6e27a783          	lw	a5,1762(a5) # 8001f7ac <sb+0x4>
    800030d2:	cbd1                	beqz	a5,80003166 <balloc+0xb6>
    800030d4:	8baa                	mv	s7,a0
    800030d6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030d8:	0001cb17          	auipc	s6,0x1c
    800030dc:	6d0b0b13          	addi	s6,s6,1744 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030e0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030e2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030e4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030e6:	6c89                	lui	s9,0x2
    800030e8:	a831                	j	80003104 <balloc+0x54>
    brelse(bp);
    800030ea:	854a                	mv	a0,s2
    800030ec:	00000097          	auipc	ra,0x0
    800030f0:	e32080e7          	jalr	-462(ra) # 80002f1e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030f4:	015c87bb          	addw	a5,s9,s5
    800030f8:	00078a9b          	sext.w	s5,a5
    800030fc:	004b2703          	lw	a4,4(s6)
    80003100:	06eaf363          	bgeu	s5,a4,80003166 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003104:	41fad79b          	sraiw	a5,s5,0x1f
    80003108:	0137d79b          	srliw	a5,a5,0x13
    8000310c:	015787bb          	addw	a5,a5,s5
    80003110:	40d7d79b          	sraiw	a5,a5,0xd
    80003114:	01cb2583          	lw	a1,28(s6)
    80003118:	9dbd                	addw	a1,a1,a5
    8000311a:	855e                	mv	a0,s7
    8000311c:	00000097          	auipc	ra,0x0
    80003120:	cd2080e7          	jalr	-814(ra) # 80002dee <bread>
    80003124:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003126:	004b2503          	lw	a0,4(s6)
    8000312a:	000a849b          	sext.w	s1,s5
    8000312e:	8662                	mv	a2,s8
    80003130:	faa4fde3          	bgeu	s1,a0,800030ea <balloc+0x3a>
      m = 1 << (bi % 8);
    80003134:	41f6579b          	sraiw	a5,a2,0x1f
    80003138:	01d7d69b          	srliw	a3,a5,0x1d
    8000313c:	00c6873b          	addw	a4,a3,a2
    80003140:	00777793          	andi	a5,a4,7
    80003144:	9f95                	subw	a5,a5,a3
    80003146:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000314a:	4037571b          	sraiw	a4,a4,0x3
    8000314e:	00e906b3          	add	a3,s2,a4
    80003152:	0586c683          	lbu	a3,88(a3)
    80003156:	00d7f5b3          	and	a1,a5,a3
    8000315a:	cd91                	beqz	a1,80003176 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000315c:	2605                	addiw	a2,a2,1
    8000315e:	2485                	addiw	s1,s1,1
    80003160:	fd4618e3          	bne	a2,s4,80003130 <balloc+0x80>
    80003164:	b759                	j	800030ea <balloc+0x3a>
  panic("balloc: out of blocks");
    80003166:	00005517          	auipc	a0,0x5
    8000316a:	3d250513          	addi	a0,a0,978 # 80008538 <syscalls+0x108>
    8000316e:	ffffd097          	auipc	ra,0xffffd
    80003172:	3c2080e7          	jalr	962(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003176:	974a                	add	a4,a4,s2
    80003178:	8fd5                	or	a5,a5,a3
    8000317a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000317e:	854a                	mv	a0,s2
    80003180:	00001097          	auipc	ra,0x1
    80003184:	01a080e7          	jalr	26(ra) # 8000419a <log_write>
        brelse(bp);
    80003188:	854a                	mv	a0,s2
    8000318a:	00000097          	auipc	ra,0x0
    8000318e:	d94080e7          	jalr	-620(ra) # 80002f1e <brelse>
  bp = bread(dev, bno);
    80003192:	85a6                	mv	a1,s1
    80003194:	855e                	mv	a0,s7
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	c58080e7          	jalr	-936(ra) # 80002dee <bread>
    8000319e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031a0:	40000613          	li	a2,1024
    800031a4:	4581                	li	a1,0
    800031a6:	05850513          	addi	a0,a0,88
    800031aa:	ffffe097          	auipc	ra,0xffffe
    800031ae:	b28080e7          	jalr	-1240(ra) # 80000cd2 <memset>
  log_write(bp);
    800031b2:	854a                	mv	a0,s2
    800031b4:	00001097          	auipc	ra,0x1
    800031b8:	fe6080e7          	jalr	-26(ra) # 8000419a <log_write>
  brelse(bp);
    800031bc:	854a                	mv	a0,s2
    800031be:	00000097          	auipc	ra,0x0
    800031c2:	d60080e7          	jalr	-672(ra) # 80002f1e <brelse>
}
    800031c6:	8526                	mv	a0,s1
    800031c8:	60e6                	ld	ra,88(sp)
    800031ca:	6446                	ld	s0,80(sp)
    800031cc:	64a6                	ld	s1,72(sp)
    800031ce:	6906                	ld	s2,64(sp)
    800031d0:	79e2                	ld	s3,56(sp)
    800031d2:	7a42                	ld	s4,48(sp)
    800031d4:	7aa2                	ld	s5,40(sp)
    800031d6:	7b02                	ld	s6,32(sp)
    800031d8:	6be2                	ld	s7,24(sp)
    800031da:	6c42                	ld	s8,16(sp)
    800031dc:	6ca2                	ld	s9,8(sp)
    800031de:	6125                	addi	sp,sp,96
    800031e0:	8082                	ret

00000000800031e2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031e2:	7179                	addi	sp,sp,-48
    800031e4:	f406                	sd	ra,40(sp)
    800031e6:	f022                	sd	s0,32(sp)
    800031e8:	ec26                	sd	s1,24(sp)
    800031ea:	e84a                	sd	s2,16(sp)
    800031ec:	e44e                	sd	s3,8(sp)
    800031ee:	e052                	sd	s4,0(sp)
    800031f0:	1800                	addi	s0,sp,48
    800031f2:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031f4:	47ad                	li	a5,11
    800031f6:	04b7fe63          	bgeu	a5,a1,80003252 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031fa:	ff45849b          	addiw	s1,a1,-12
    800031fe:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003202:	0ff00793          	li	a5,255
    80003206:	0ae7e363          	bltu	a5,a4,800032ac <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000320a:	08052583          	lw	a1,128(a0)
    8000320e:	c5ad                	beqz	a1,80003278 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003210:	00092503          	lw	a0,0(s2)
    80003214:	00000097          	auipc	ra,0x0
    80003218:	bda080e7          	jalr	-1062(ra) # 80002dee <bread>
    8000321c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000321e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003222:	02049593          	slli	a1,s1,0x20
    80003226:	9181                	srli	a1,a1,0x20
    80003228:	058a                	slli	a1,a1,0x2
    8000322a:	00b784b3          	add	s1,a5,a1
    8000322e:	0004a983          	lw	s3,0(s1)
    80003232:	04098d63          	beqz	s3,8000328c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003236:	8552                	mv	a0,s4
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	ce6080e7          	jalr	-794(ra) # 80002f1e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003240:	854e                	mv	a0,s3
    80003242:	70a2                	ld	ra,40(sp)
    80003244:	7402                	ld	s0,32(sp)
    80003246:	64e2                	ld	s1,24(sp)
    80003248:	6942                	ld	s2,16(sp)
    8000324a:	69a2                	ld	s3,8(sp)
    8000324c:	6a02                	ld	s4,0(sp)
    8000324e:	6145                	addi	sp,sp,48
    80003250:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003252:	02059493          	slli	s1,a1,0x20
    80003256:	9081                	srli	s1,s1,0x20
    80003258:	048a                	slli	s1,s1,0x2
    8000325a:	94aa                	add	s1,s1,a0
    8000325c:	0504a983          	lw	s3,80(s1)
    80003260:	fe0990e3          	bnez	s3,80003240 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003264:	4108                	lw	a0,0(a0)
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	e4a080e7          	jalr	-438(ra) # 800030b0 <balloc>
    8000326e:	0005099b          	sext.w	s3,a0
    80003272:	0534a823          	sw	s3,80(s1)
    80003276:	b7e9                	j	80003240 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003278:	4108                	lw	a0,0(a0)
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	e36080e7          	jalr	-458(ra) # 800030b0 <balloc>
    80003282:	0005059b          	sext.w	a1,a0
    80003286:	08b92023          	sw	a1,128(s2)
    8000328a:	b759                	j	80003210 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000328c:	00092503          	lw	a0,0(s2)
    80003290:	00000097          	auipc	ra,0x0
    80003294:	e20080e7          	jalr	-480(ra) # 800030b0 <balloc>
    80003298:	0005099b          	sext.w	s3,a0
    8000329c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032a0:	8552                	mv	a0,s4
    800032a2:	00001097          	auipc	ra,0x1
    800032a6:	ef8080e7          	jalr	-264(ra) # 8000419a <log_write>
    800032aa:	b771                	j	80003236 <bmap+0x54>
  panic("bmap: out of range");
    800032ac:	00005517          	auipc	a0,0x5
    800032b0:	2a450513          	addi	a0,a0,676 # 80008550 <syscalls+0x120>
    800032b4:	ffffd097          	auipc	ra,0xffffd
    800032b8:	27c080e7          	jalr	636(ra) # 80000530 <panic>

00000000800032bc <iget>:
{
    800032bc:	7179                	addi	sp,sp,-48
    800032be:	f406                	sd	ra,40(sp)
    800032c0:	f022                	sd	s0,32(sp)
    800032c2:	ec26                	sd	s1,24(sp)
    800032c4:	e84a                	sd	s2,16(sp)
    800032c6:	e44e                	sd	s3,8(sp)
    800032c8:	e052                	sd	s4,0(sp)
    800032ca:	1800                	addi	s0,sp,48
    800032cc:	89aa                	mv	s3,a0
    800032ce:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800032d0:	0001c517          	auipc	a0,0x1c
    800032d4:	4f850513          	addi	a0,a0,1272 # 8001f7c8 <itable>
    800032d8:	ffffe097          	auipc	ra,0xffffe
    800032dc:	8fe080e7          	jalr	-1794(ra) # 80000bd6 <acquire>
  empty = 0;
    800032e0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032e2:	0001c497          	auipc	s1,0x1c
    800032e6:	4fe48493          	addi	s1,s1,1278 # 8001f7e0 <itable+0x18>
    800032ea:	0001e697          	auipc	a3,0x1e
    800032ee:	f8668693          	addi	a3,a3,-122 # 80021270 <log>
    800032f2:	a039                	j	80003300 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800032f4:	02090b63          	beqz	s2,8000332a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800032f8:	08848493          	addi	s1,s1,136
    800032fc:	02d48a63          	beq	s1,a3,80003330 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003300:	449c                	lw	a5,8(s1)
    80003302:	fef059e3          	blez	a5,800032f4 <iget+0x38>
    80003306:	4098                	lw	a4,0(s1)
    80003308:	ff3716e3          	bne	a4,s3,800032f4 <iget+0x38>
    8000330c:	40d8                	lw	a4,4(s1)
    8000330e:	ff4713e3          	bne	a4,s4,800032f4 <iget+0x38>
      ip->ref++;
    80003312:	2785                	addiw	a5,a5,1
    80003314:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003316:	0001c517          	auipc	a0,0x1c
    8000331a:	4b250513          	addi	a0,a0,1202 # 8001f7c8 <itable>
    8000331e:	ffffe097          	auipc	ra,0xffffe
    80003322:	96c080e7          	jalr	-1684(ra) # 80000c8a <release>
      return ip;
    80003326:	8926                	mv	s2,s1
    80003328:	a03d                	j	80003356 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000332a:	f7f9                	bnez	a5,800032f8 <iget+0x3c>
    8000332c:	8926                	mv	s2,s1
    8000332e:	b7e9                	j	800032f8 <iget+0x3c>
  if(empty == 0)
    80003330:	02090c63          	beqz	s2,80003368 <iget+0xac>
  ip->dev = dev;
    80003334:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003338:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000333c:	4785                	li	a5,1
    8000333e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003342:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003346:	0001c517          	auipc	a0,0x1c
    8000334a:	48250513          	addi	a0,a0,1154 # 8001f7c8 <itable>
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	93c080e7          	jalr	-1732(ra) # 80000c8a <release>
}
    80003356:	854a                	mv	a0,s2
    80003358:	70a2                	ld	ra,40(sp)
    8000335a:	7402                	ld	s0,32(sp)
    8000335c:	64e2                	ld	s1,24(sp)
    8000335e:	6942                	ld	s2,16(sp)
    80003360:	69a2                	ld	s3,8(sp)
    80003362:	6a02                	ld	s4,0(sp)
    80003364:	6145                	addi	sp,sp,48
    80003366:	8082                	ret
    panic("iget: no inodes");
    80003368:	00005517          	auipc	a0,0x5
    8000336c:	20050513          	addi	a0,a0,512 # 80008568 <syscalls+0x138>
    80003370:	ffffd097          	auipc	ra,0xffffd
    80003374:	1c0080e7          	jalr	448(ra) # 80000530 <panic>

0000000080003378 <fsinit>:
fsinit(int dev) {
    80003378:	7179                	addi	sp,sp,-48
    8000337a:	f406                	sd	ra,40(sp)
    8000337c:	f022                	sd	s0,32(sp)
    8000337e:	ec26                	sd	s1,24(sp)
    80003380:	e84a                	sd	s2,16(sp)
    80003382:	e44e                	sd	s3,8(sp)
    80003384:	1800                	addi	s0,sp,48
    80003386:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003388:	4585                	li	a1,1
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	a64080e7          	jalr	-1436(ra) # 80002dee <bread>
    80003392:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003394:	0001c997          	auipc	s3,0x1c
    80003398:	41498993          	addi	s3,s3,1044 # 8001f7a8 <sb>
    8000339c:	02000613          	li	a2,32
    800033a0:	05850593          	addi	a1,a0,88
    800033a4:	854e                	mv	a0,s3
    800033a6:	ffffe097          	auipc	ra,0xffffe
    800033aa:	98c080e7          	jalr	-1652(ra) # 80000d32 <memmove>
  brelse(bp);
    800033ae:	8526                	mv	a0,s1
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	b6e080e7          	jalr	-1170(ra) # 80002f1e <brelse>
  if(sb.magic != FSMAGIC)
    800033b8:	0009a703          	lw	a4,0(s3)
    800033bc:	102037b7          	lui	a5,0x10203
    800033c0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800033c4:	02f71263          	bne	a4,a5,800033e8 <fsinit+0x70>
  initlog(dev, &sb);
    800033c8:	0001c597          	auipc	a1,0x1c
    800033cc:	3e058593          	addi	a1,a1,992 # 8001f7a8 <sb>
    800033d0:	854a                	mv	a0,s2
    800033d2:	00001097          	auipc	ra,0x1
    800033d6:	b4c080e7          	jalr	-1204(ra) # 80003f1e <initlog>
}
    800033da:	70a2                	ld	ra,40(sp)
    800033dc:	7402                	ld	s0,32(sp)
    800033de:	64e2                	ld	s1,24(sp)
    800033e0:	6942                	ld	s2,16(sp)
    800033e2:	69a2                	ld	s3,8(sp)
    800033e4:	6145                	addi	sp,sp,48
    800033e6:	8082                	ret
    panic("invalid file system");
    800033e8:	00005517          	auipc	a0,0x5
    800033ec:	19050513          	addi	a0,a0,400 # 80008578 <syscalls+0x148>
    800033f0:	ffffd097          	auipc	ra,0xffffd
    800033f4:	140080e7          	jalr	320(ra) # 80000530 <panic>

00000000800033f8 <iinit>:
{
    800033f8:	7179                	addi	sp,sp,-48
    800033fa:	f406                	sd	ra,40(sp)
    800033fc:	f022                	sd	s0,32(sp)
    800033fe:	ec26                	sd	s1,24(sp)
    80003400:	e84a                	sd	s2,16(sp)
    80003402:	e44e                	sd	s3,8(sp)
    80003404:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003406:	00005597          	auipc	a1,0x5
    8000340a:	18a58593          	addi	a1,a1,394 # 80008590 <syscalls+0x160>
    8000340e:	0001c517          	auipc	a0,0x1c
    80003412:	3ba50513          	addi	a0,a0,954 # 8001f7c8 <itable>
    80003416:	ffffd097          	auipc	ra,0xffffd
    8000341a:	730080e7          	jalr	1840(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000341e:	0001c497          	auipc	s1,0x1c
    80003422:	3d248493          	addi	s1,s1,978 # 8001f7f0 <itable+0x28>
    80003426:	0001e997          	auipc	s3,0x1e
    8000342a:	e5a98993          	addi	s3,s3,-422 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000342e:	00005917          	auipc	s2,0x5
    80003432:	16a90913          	addi	s2,s2,362 # 80008598 <syscalls+0x168>
    80003436:	85ca                	mv	a1,s2
    80003438:	8526                	mv	a0,s1
    8000343a:	00001097          	auipc	ra,0x1
    8000343e:	e46080e7          	jalr	-442(ra) # 80004280 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003442:	08848493          	addi	s1,s1,136
    80003446:	ff3498e3          	bne	s1,s3,80003436 <iinit+0x3e>
}
    8000344a:	70a2                	ld	ra,40(sp)
    8000344c:	7402                	ld	s0,32(sp)
    8000344e:	64e2                	ld	s1,24(sp)
    80003450:	6942                	ld	s2,16(sp)
    80003452:	69a2                	ld	s3,8(sp)
    80003454:	6145                	addi	sp,sp,48
    80003456:	8082                	ret

0000000080003458 <ialloc>:
{
    80003458:	715d                	addi	sp,sp,-80
    8000345a:	e486                	sd	ra,72(sp)
    8000345c:	e0a2                	sd	s0,64(sp)
    8000345e:	fc26                	sd	s1,56(sp)
    80003460:	f84a                	sd	s2,48(sp)
    80003462:	f44e                	sd	s3,40(sp)
    80003464:	f052                	sd	s4,32(sp)
    80003466:	ec56                	sd	s5,24(sp)
    80003468:	e85a                	sd	s6,16(sp)
    8000346a:	e45e                	sd	s7,8(sp)
    8000346c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000346e:	0001c717          	auipc	a4,0x1c
    80003472:	34672703          	lw	a4,838(a4) # 8001f7b4 <sb+0xc>
    80003476:	4785                	li	a5,1
    80003478:	04e7fa63          	bgeu	a5,a4,800034cc <ialloc+0x74>
    8000347c:	8aaa                	mv	s5,a0
    8000347e:	8bae                	mv	s7,a1
    80003480:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003482:	0001ca17          	auipc	s4,0x1c
    80003486:	326a0a13          	addi	s4,s4,806 # 8001f7a8 <sb>
    8000348a:	00048b1b          	sext.w	s6,s1
    8000348e:	0044d593          	srli	a1,s1,0x4
    80003492:	018a2783          	lw	a5,24(s4)
    80003496:	9dbd                	addw	a1,a1,a5
    80003498:	8556                	mv	a0,s5
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	954080e7          	jalr	-1708(ra) # 80002dee <bread>
    800034a2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034a4:	05850993          	addi	s3,a0,88
    800034a8:	00f4f793          	andi	a5,s1,15
    800034ac:	079a                	slli	a5,a5,0x6
    800034ae:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034b0:	00099783          	lh	a5,0(s3)
    800034b4:	c785                	beqz	a5,800034dc <ialloc+0x84>
    brelse(bp);
    800034b6:	00000097          	auipc	ra,0x0
    800034ba:	a68080e7          	jalr	-1432(ra) # 80002f1e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800034be:	0485                	addi	s1,s1,1
    800034c0:	00ca2703          	lw	a4,12(s4)
    800034c4:	0004879b          	sext.w	a5,s1
    800034c8:	fce7e1e3          	bltu	a5,a4,8000348a <ialloc+0x32>
  panic("ialloc: no inodes");
    800034cc:	00005517          	auipc	a0,0x5
    800034d0:	0d450513          	addi	a0,a0,212 # 800085a0 <syscalls+0x170>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	05c080e7          	jalr	92(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    800034dc:	04000613          	li	a2,64
    800034e0:	4581                	li	a1,0
    800034e2:	854e                	mv	a0,s3
    800034e4:	ffffd097          	auipc	ra,0xffffd
    800034e8:	7ee080e7          	jalr	2030(ra) # 80000cd2 <memset>
      dip->type = type;
    800034ec:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800034f0:	854a                	mv	a0,s2
    800034f2:	00001097          	auipc	ra,0x1
    800034f6:	ca8080e7          	jalr	-856(ra) # 8000419a <log_write>
      brelse(bp);
    800034fa:	854a                	mv	a0,s2
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	a22080e7          	jalr	-1502(ra) # 80002f1e <brelse>
      return iget(dev, inum);
    80003504:	85da                	mv	a1,s6
    80003506:	8556                	mv	a0,s5
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	db4080e7          	jalr	-588(ra) # 800032bc <iget>
}
    80003510:	60a6                	ld	ra,72(sp)
    80003512:	6406                	ld	s0,64(sp)
    80003514:	74e2                	ld	s1,56(sp)
    80003516:	7942                	ld	s2,48(sp)
    80003518:	79a2                	ld	s3,40(sp)
    8000351a:	7a02                	ld	s4,32(sp)
    8000351c:	6ae2                	ld	s5,24(sp)
    8000351e:	6b42                	ld	s6,16(sp)
    80003520:	6ba2                	ld	s7,8(sp)
    80003522:	6161                	addi	sp,sp,80
    80003524:	8082                	ret

0000000080003526 <iupdate>:
{
    80003526:	1101                	addi	sp,sp,-32
    80003528:	ec06                	sd	ra,24(sp)
    8000352a:	e822                	sd	s0,16(sp)
    8000352c:	e426                	sd	s1,8(sp)
    8000352e:	e04a                	sd	s2,0(sp)
    80003530:	1000                	addi	s0,sp,32
    80003532:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003534:	415c                	lw	a5,4(a0)
    80003536:	0047d79b          	srliw	a5,a5,0x4
    8000353a:	0001c597          	auipc	a1,0x1c
    8000353e:	2865a583          	lw	a1,646(a1) # 8001f7c0 <sb+0x18>
    80003542:	9dbd                	addw	a1,a1,a5
    80003544:	4108                	lw	a0,0(a0)
    80003546:	00000097          	auipc	ra,0x0
    8000354a:	8a8080e7          	jalr	-1880(ra) # 80002dee <bread>
    8000354e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003550:	05850793          	addi	a5,a0,88
    80003554:	40c8                	lw	a0,4(s1)
    80003556:	893d                	andi	a0,a0,15
    80003558:	051a                	slli	a0,a0,0x6
    8000355a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000355c:	04449703          	lh	a4,68(s1)
    80003560:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003564:	04649703          	lh	a4,70(s1)
    80003568:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000356c:	04849703          	lh	a4,72(s1)
    80003570:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003574:	04a49703          	lh	a4,74(s1)
    80003578:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000357c:	44f8                	lw	a4,76(s1)
    8000357e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003580:	03400613          	li	a2,52
    80003584:	05048593          	addi	a1,s1,80
    80003588:	0531                	addi	a0,a0,12
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	7a8080e7          	jalr	1960(ra) # 80000d32 <memmove>
  log_write(bp);
    80003592:	854a                	mv	a0,s2
    80003594:	00001097          	auipc	ra,0x1
    80003598:	c06080e7          	jalr	-1018(ra) # 8000419a <log_write>
  brelse(bp);
    8000359c:	854a                	mv	a0,s2
    8000359e:	00000097          	auipc	ra,0x0
    800035a2:	980080e7          	jalr	-1664(ra) # 80002f1e <brelse>
}
    800035a6:	60e2                	ld	ra,24(sp)
    800035a8:	6442                	ld	s0,16(sp)
    800035aa:	64a2                	ld	s1,8(sp)
    800035ac:	6902                	ld	s2,0(sp)
    800035ae:	6105                	addi	sp,sp,32
    800035b0:	8082                	ret

00000000800035b2 <idup>:
{
    800035b2:	1101                	addi	sp,sp,-32
    800035b4:	ec06                	sd	ra,24(sp)
    800035b6:	e822                	sd	s0,16(sp)
    800035b8:	e426                	sd	s1,8(sp)
    800035ba:	1000                	addi	s0,sp,32
    800035bc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800035be:	0001c517          	auipc	a0,0x1c
    800035c2:	20a50513          	addi	a0,a0,522 # 8001f7c8 <itable>
    800035c6:	ffffd097          	auipc	ra,0xffffd
    800035ca:	610080e7          	jalr	1552(ra) # 80000bd6 <acquire>
  ip->ref++;
    800035ce:	449c                	lw	a5,8(s1)
    800035d0:	2785                	addiw	a5,a5,1
    800035d2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800035d4:	0001c517          	auipc	a0,0x1c
    800035d8:	1f450513          	addi	a0,a0,500 # 8001f7c8 <itable>
    800035dc:	ffffd097          	auipc	ra,0xffffd
    800035e0:	6ae080e7          	jalr	1710(ra) # 80000c8a <release>
}
    800035e4:	8526                	mv	a0,s1
    800035e6:	60e2                	ld	ra,24(sp)
    800035e8:	6442                	ld	s0,16(sp)
    800035ea:	64a2                	ld	s1,8(sp)
    800035ec:	6105                	addi	sp,sp,32
    800035ee:	8082                	ret

00000000800035f0 <ilock>:
{
    800035f0:	1101                	addi	sp,sp,-32
    800035f2:	ec06                	sd	ra,24(sp)
    800035f4:	e822                	sd	s0,16(sp)
    800035f6:	e426                	sd	s1,8(sp)
    800035f8:	e04a                	sd	s2,0(sp)
    800035fa:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800035fc:	c115                	beqz	a0,80003620 <ilock+0x30>
    800035fe:	84aa                	mv	s1,a0
    80003600:	451c                	lw	a5,8(a0)
    80003602:	00f05f63          	blez	a5,80003620 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003606:	0541                	addi	a0,a0,16
    80003608:	00001097          	auipc	ra,0x1
    8000360c:	cb2080e7          	jalr	-846(ra) # 800042ba <acquiresleep>
  if(ip->valid == 0){
    80003610:	40bc                	lw	a5,64(s1)
    80003612:	cf99                	beqz	a5,80003630 <ilock+0x40>
}
    80003614:	60e2                	ld	ra,24(sp)
    80003616:	6442                	ld	s0,16(sp)
    80003618:	64a2                	ld	s1,8(sp)
    8000361a:	6902                	ld	s2,0(sp)
    8000361c:	6105                	addi	sp,sp,32
    8000361e:	8082                	ret
    panic("ilock");
    80003620:	00005517          	auipc	a0,0x5
    80003624:	f9850513          	addi	a0,a0,-104 # 800085b8 <syscalls+0x188>
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	f08080e7          	jalr	-248(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003630:	40dc                	lw	a5,4(s1)
    80003632:	0047d79b          	srliw	a5,a5,0x4
    80003636:	0001c597          	auipc	a1,0x1c
    8000363a:	18a5a583          	lw	a1,394(a1) # 8001f7c0 <sb+0x18>
    8000363e:	9dbd                	addw	a1,a1,a5
    80003640:	4088                	lw	a0,0(s1)
    80003642:	fffff097          	auipc	ra,0xfffff
    80003646:	7ac080e7          	jalr	1964(ra) # 80002dee <bread>
    8000364a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000364c:	05850593          	addi	a1,a0,88
    80003650:	40dc                	lw	a5,4(s1)
    80003652:	8bbd                	andi	a5,a5,15
    80003654:	079a                	slli	a5,a5,0x6
    80003656:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003658:	00059783          	lh	a5,0(a1)
    8000365c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003660:	00259783          	lh	a5,2(a1)
    80003664:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003668:	00459783          	lh	a5,4(a1)
    8000366c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003670:	00659783          	lh	a5,6(a1)
    80003674:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003678:	459c                	lw	a5,8(a1)
    8000367a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000367c:	03400613          	li	a2,52
    80003680:	05b1                	addi	a1,a1,12
    80003682:	05048513          	addi	a0,s1,80
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	6ac080e7          	jalr	1708(ra) # 80000d32 <memmove>
    brelse(bp);
    8000368e:	854a                	mv	a0,s2
    80003690:	00000097          	auipc	ra,0x0
    80003694:	88e080e7          	jalr	-1906(ra) # 80002f1e <brelse>
    ip->valid = 1;
    80003698:	4785                	li	a5,1
    8000369a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000369c:	04449783          	lh	a5,68(s1)
    800036a0:	fbb5                	bnez	a5,80003614 <ilock+0x24>
      panic("ilock: no type");
    800036a2:	00005517          	auipc	a0,0x5
    800036a6:	f1e50513          	addi	a0,a0,-226 # 800085c0 <syscalls+0x190>
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	e86080e7          	jalr	-378(ra) # 80000530 <panic>

00000000800036b2 <iunlock>:
{
    800036b2:	1101                	addi	sp,sp,-32
    800036b4:	ec06                	sd	ra,24(sp)
    800036b6:	e822                	sd	s0,16(sp)
    800036b8:	e426                	sd	s1,8(sp)
    800036ba:	e04a                	sd	s2,0(sp)
    800036bc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800036be:	c905                	beqz	a0,800036ee <iunlock+0x3c>
    800036c0:	84aa                	mv	s1,a0
    800036c2:	01050913          	addi	s2,a0,16
    800036c6:	854a                	mv	a0,s2
    800036c8:	00001097          	auipc	ra,0x1
    800036cc:	c8c080e7          	jalr	-884(ra) # 80004354 <holdingsleep>
    800036d0:	cd19                	beqz	a0,800036ee <iunlock+0x3c>
    800036d2:	449c                	lw	a5,8(s1)
    800036d4:	00f05d63          	blez	a5,800036ee <iunlock+0x3c>
  releasesleep(&ip->lock);
    800036d8:	854a                	mv	a0,s2
    800036da:	00001097          	auipc	ra,0x1
    800036de:	c36080e7          	jalr	-970(ra) # 80004310 <releasesleep>
}
    800036e2:	60e2                	ld	ra,24(sp)
    800036e4:	6442                	ld	s0,16(sp)
    800036e6:	64a2                	ld	s1,8(sp)
    800036e8:	6902                	ld	s2,0(sp)
    800036ea:	6105                	addi	sp,sp,32
    800036ec:	8082                	ret
    panic("iunlock");
    800036ee:	00005517          	auipc	a0,0x5
    800036f2:	ee250513          	addi	a0,a0,-286 # 800085d0 <syscalls+0x1a0>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	e3a080e7          	jalr	-454(ra) # 80000530 <panic>

00000000800036fe <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800036fe:	7179                	addi	sp,sp,-48
    80003700:	f406                	sd	ra,40(sp)
    80003702:	f022                	sd	s0,32(sp)
    80003704:	ec26                	sd	s1,24(sp)
    80003706:	e84a                	sd	s2,16(sp)
    80003708:	e44e                	sd	s3,8(sp)
    8000370a:	e052                	sd	s4,0(sp)
    8000370c:	1800                	addi	s0,sp,48
    8000370e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003710:	05050493          	addi	s1,a0,80
    80003714:	08050913          	addi	s2,a0,128
    80003718:	a021                	j	80003720 <itrunc+0x22>
    8000371a:	0491                	addi	s1,s1,4
    8000371c:	01248d63          	beq	s1,s2,80003736 <itrunc+0x38>
    if(ip->addrs[i]){
    80003720:	408c                	lw	a1,0(s1)
    80003722:	dde5                	beqz	a1,8000371a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003724:	0009a503          	lw	a0,0(s3)
    80003728:	00000097          	auipc	ra,0x0
    8000372c:	90c080e7          	jalr	-1780(ra) # 80003034 <bfree>
      ip->addrs[i] = 0;
    80003730:	0004a023          	sw	zero,0(s1)
    80003734:	b7dd                	j	8000371a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003736:	0809a583          	lw	a1,128(s3)
    8000373a:	e185                	bnez	a1,8000375a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000373c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003740:	854e                	mv	a0,s3
    80003742:	00000097          	auipc	ra,0x0
    80003746:	de4080e7          	jalr	-540(ra) # 80003526 <iupdate>
}
    8000374a:	70a2                	ld	ra,40(sp)
    8000374c:	7402                	ld	s0,32(sp)
    8000374e:	64e2                	ld	s1,24(sp)
    80003750:	6942                	ld	s2,16(sp)
    80003752:	69a2                	ld	s3,8(sp)
    80003754:	6a02                	ld	s4,0(sp)
    80003756:	6145                	addi	sp,sp,48
    80003758:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000375a:	0009a503          	lw	a0,0(s3)
    8000375e:	fffff097          	auipc	ra,0xfffff
    80003762:	690080e7          	jalr	1680(ra) # 80002dee <bread>
    80003766:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003768:	05850493          	addi	s1,a0,88
    8000376c:	45850913          	addi	s2,a0,1112
    80003770:	a811                	j	80003784 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003772:	0009a503          	lw	a0,0(s3)
    80003776:	00000097          	auipc	ra,0x0
    8000377a:	8be080e7          	jalr	-1858(ra) # 80003034 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000377e:	0491                	addi	s1,s1,4
    80003780:	01248563          	beq	s1,s2,8000378a <itrunc+0x8c>
      if(a[j])
    80003784:	408c                	lw	a1,0(s1)
    80003786:	dde5                	beqz	a1,8000377e <itrunc+0x80>
    80003788:	b7ed                	j	80003772 <itrunc+0x74>
    brelse(bp);
    8000378a:	8552                	mv	a0,s4
    8000378c:	fffff097          	auipc	ra,0xfffff
    80003790:	792080e7          	jalr	1938(ra) # 80002f1e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003794:	0809a583          	lw	a1,128(s3)
    80003798:	0009a503          	lw	a0,0(s3)
    8000379c:	00000097          	auipc	ra,0x0
    800037a0:	898080e7          	jalr	-1896(ra) # 80003034 <bfree>
    ip->addrs[NDIRECT] = 0;
    800037a4:	0809a023          	sw	zero,128(s3)
    800037a8:	bf51                	j	8000373c <itrunc+0x3e>

00000000800037aa <iput>:
{
    800037aa:	1101                	addi	sp,sp,-32
    800037ac:	ec06                	sd	ra,24(sp)
    800037ae:	e822                	sd	s0,16(sp)
    800037b0:	e426                	sd	s1,8(sp)
    800037b2:	e04a                	sd	s2,0(sp)
    800037b4:	1000                	addi	s0,sp,32
    800037b6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037b8:	0001c517          	auipc	a0,0x1c
    800037bc:	01050513          	addi	a0,a0,16 # 8001f7c8 <itable>
    800037c0:	ffffd097          	auipc	ra,0xffffd
    800037c4:	416080e7          	jalr	1046(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037c8:	4498                	lw	a4,8(s1)
    800037ca:	4785                	li	a5,1
    800037cc:	02f70363          	beq	a4,a5,800037f2 <iput+0x48>
  ip->ref--;
    800037d0:	449c                	lw	a5,8(s1)
    800037d2:	37fd                	addiw	a5,a5,-1
    800037d4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037d6:	0001c517          	auipc	a0,0x1c
    800037da:	ff250513          	addi	a0,a0,-14 # 8001f7c8 <itable>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	4ac080e7          	jalr	1196(ra) # 80000c8a <release>
}
    800037e6:	60e2                	ld	ra,24(sp)
    800037e8:	6442                	ld	s0,16(sp)
    800037ea:	64a2                	ld	s1,8(sp)
    800037ec:	6902                	ld	s2,0(sp)
    800037ee:	6105                	addi	sp,sp,32
    800037f0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800037f2:	40bc                	lw	a5,64(s1)
    800037f4:	dff1                	beqz	a5,800037d0 <iput+0x26>
    800037f6:	04a49783          	lh	a5,74(s1)
    800037fa:	fbf9                	bnez	a5,800037d0 <iput+0x26>
    acquiresleep(&ip->lock);
    800037fc:	01048913          	addi	s2,s1,16
    80003800:	854a                	mv	a0,s2
    80003802:	00001097          	auipc	ra,0x1
    80003806:	ab8080e7          	jalr	-1352(ra) # 800042ba <acquiresleep>
    release(&itable.lock);
    8000380a:	0001c517          	auipc	a0,0x1c
    8000380e:	fbe50513          	addi	a0,a0,-66 # 8001f7c8 <itable>
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	478080e7          	jalr	1144(ra) # 80000c8a <release>
    itrunc(ip);
    8000381a:	8526                	mv	a0,s1
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	ee2080e7          	jalr	-286(ra) # 800036fe <itrunc>
    ip->type = 0;
    80003824:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003828:	8526                	mv	a0,s1
    8000382a:	00000097          	auipc	ra,0x0
    8000382e:	cfc080e7          	jalr	-772(ra) # 80003526 <iupdate>
    ip->valid = 0;
    80003832:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003836:	854a                	mv	a0,s2
    80003838:	00001097          	auipc	ra,0x1
    8000383c:	ad8080e7          	jalr	-1320(ra) # 80004310 <releasesleep>
    acquire(&itable.lock);
    80003840:	0001c517          	auipc	a0,0x1c
    80003844:	f8850513          	addi	a0,a0,-120 # 8001f7c8 <itable>
    80003848:	ffffd097          	auipc	ra,0xffffd
    8000384c:	38e080e7          	jalr	910(ra) # 80000bd6 <acquire>
    80003850:	b741                	j	800037d0 <iput+0x26>

0000000080003852 <iunlockput>:
{
    80003852:	1101                	addi	sp,sp,-32
    80003854:	ec06                	sd	ra,24(sp)
    80003856:	e822                	sd	s0,16(sp)
    80003858:	e426                	sd	s1,8(sp)
    8000385a:	1000                	addi	s0,sp,32
    8000385c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000385e:	00000097          	auipc	ra,0x0
    80003862:	e54080e7          	jalr	-428(ra) # 800036b2 <iunlock>
  iput(ip);
    80003866:	8526                	mv	a0,s1
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	f42080e7          	jalr	-190(ra) # 800037aa <iput>
}
    80003870:	60e2                	ld	ra,24(sp)
    80003872:	6442                	ld	s0,16(sp)
    80003874:	64a2                	ld	s1,8(sp)
    80003876:	6105                	addi	sp,sp,32
    80003878:	8082                	ret

000000008000387a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000387a:	1141                	addi	sp,sp,-16
    8000387c:	e422                	sd	s0,8(sp)
    8000387e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003880:	411c                	lw	a5,0(a0)
    80003882:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003884:	415c                	lw	a5,4(a0)
    80003886:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003888:	04451783          	lh	a5,68(a0)
    8000388c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003890:	04a51783          	lh	a5,74(a0)
    80003894:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003898:	04c56783          	lwu	a5,76(a0)
    8000389c:	e99c                	sd	a5,16(a1)
}
    8000389e:	6422                	ld	s0,8(sp)
    800038a0:	0141                	addi	sp,sp,16
    800038a2:	8082                	ret

00000000800038a4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038a4:	457c                	lw	a5,76(a0)
    800038a6:	0ed7e963          	bltu	a5,a3,80003998 <readi+0xf4>
{
    800038aa:	7159                	addi	sp,sp,-112
    800038ac:	f486                	sd	ra,104(sp)
    800038ae:	f0a2                	sd	s0,96(sp)
    800038b0:	eca6                	sd	s1,88(sp)
    800038b2:	e8ca                	sd	s2,80(sp)
    800038b4:	e4ce                	sd	s3,72(sp)
    800038b6:	e0d2                	sd	s4,64(sp)
    800038b8:	fc56                	sd	s5,56(sp)
    800038ba:	f85a                	sd	s6,48(sp)
    800038bc:	f45e                	sd	s7,40(sp)
    800038be:	f062                	sd	s8,32(sp)
    800038c0:	ec66                	sd	s9,24(sp)
    800038c2:	e86a                	sd	s10,16(sp)
    800038c4:	e46e                	sd	s11,8(sp)
    800038c6:	1880                	addi	s0,sp,112
    800038c8:	8baa                	mv	s7,a0
    800038ca:	8c2e                	mv	s8,a1
    800038cc:	8ab2                	mv	s5,a2
    800038ce:	84b6                	mv	s1,a3
    800038d0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800038d2:	9f35                	addw	a4,a4,a3
    return 0;
    800038d4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800038d6:	0ad76063          	bltu	a4,a3,80003976 <readi+0xd2>
  if(off + n > ip->size)
    800038da:	00e7f463          	bgeu	a5,a4,800038e2 <readi+0x3e>
    n = ip->size - off;
    800038de:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800038e2:	0a0b0963          	beqz	s6,80003994 <readi+0xf0>
    800038e6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800038e8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800038ec:	5cfd                	li	s9,-1
    800038ee:	a82d                	j	80003928 <readi+0x84>
    800038f0:	020a1d93          	slli	s11,s4,0x20
    800038f4:	020ddd93          	srli	s11,s11,0x20
    800038f8:	05890613          	addi	a2,s2,88
    800038fc:	86ee                	mv	a3,s11
    800038fe:	963a                	add	a2,a2,a4
    80003900:	85d6                	mv	a1,s5
    80003902:	8562                	mv	a0,s8
    80003904:	fffff097          	auipc	ra,0xfffff
    80003908:	af0080e7          	jalr	-1296(ra) # 800023f4 <either_copyout>
    8000390c:	05950d63          	beq	a0,s9,80003966 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003910:	854a                	mv	a0,s2
    80003912:	fffff097          	auipc	ra,0xfffff
    80003916:	60c080e7          	jalr	1548(ra) # 80002f1e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000391a:	013a09bb          	addw	s3,s4,s3
    8000391e:	009a04bb          	addw	s1,s4,s1
    80003922:	9aee                	add	s5,s5,s11
    80003924:	0569f763          	bgeu	s3,s6,80003972 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003928:	000ba903          	lw	s2,0(s7)
    8000392c:	00a4d59b          	srliw	a1,s1,0xa
    80003930:	855e                	mv	a0,s7
    80003932:	00000097          	auipc	ra,0x0
    80003936:	8b0080e7          	jalr	-1872(ra) # 800031e2 <bmap>
    8000393a:	0005059b          	sext.w	a1,a0
    8000393e:	854a                	mv	a0,s2
    80003940:	fffff097          	auipc	ra,0xfffff
    80003944:	4ae080e7          	jalr	1198(ra) # 80002dee <bread>
    80003948:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000394a:	3ff4f713          	andi	a4,s1,1023
    8000394e:	40ed07bb          	subw	a5,s10,a4
    80003952:	413b06bb          	subw	a3,s6,s3
    80003956:	8a3e                	mv	s4,a5
    80003958:	2781                	sext.w	a5,a5
    8000395a:	0006861b          	sext.w	a2,a3
    8000395e:	f8f679e3          	bgeu	a2,a5,800038f0 <readi+0x4c>
    80003962:	8a36                	mv	s4,a3
    80003964:	b771                	j	800038f0 <readi+0x4c>
      brelse(bp);
    80003966:	854a                	mv	a0,s2
    80003968:	fffff097          	auipc	ra,0xfffff
    8000396c:	5b6080e7          	jalr	1462(ra) # 80002f1e <brelse>
      tot = -1;
    80003970:	59fd                	li	s3,-1
  }
  return tot;
    80003972:	0009851b          	sext.w	a0,s3
}
    80003976:	70a6                	ld	ra,104(sp)
    80003978:	7406                	ld	s0,96(sp)
    8000397a:	64e6                	ld	s1,88(sp)
    8000397c:	6946                	ld	s2,80(sp)
    8000397e:	69a6                	ld	s3,72(sp)
    80003980:	6a06                	ld	s4,64(sp)
    80003982:	7ae2                	ld	s5,56(sp)
    80003984:	7b42                	ld	s6,48(sp)
    80003986:	7ba2                	ld	s7,40(sp)
    80003988:	7c02                	ld	s8,32(sp)
    8000398a:	6ce2                	ld	s9,24(sp)
    8000398c:	6d42                	ld	s10,16(sp)
    8000398e:	6da2                	ld	s11,8(sp)
    80003990:	6165                	addi	sp,sp,112
    80003992:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003994:	89da                	mv	s3,s6
    80003996:	bff1                	j	80003972 <readi+0xce>
    return 0;
    80003998:	4501                	li	a0,0
}
    8000399a:	8082                	ret

000000008000399c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000399c:	457c                	lw	a5,76(a0)
    8000399e:	10d7e863          	bltu	a5,a3,80003aae <writei+0x112>
{
    800039a2:	7159                	addi	sp,sp,-112
    800039a4:	f486                	sd	ra,104(sp)
    800039a6:	f0a2                	sd	s0,96(sp)
    800039a8:	eca6                	sd	s1,88(sp)
    800039aa:	e8ca                	sd	s2,80(sp)
    800039ac:	e4ce                	sd	s3,72(sp)
    800039ae:	e0d2                	sd	s4,64(sp)
    800039b0:	fc56                	sd	s5,56(sp)
    800039b2:	f85a                	sd	s6,48(sp)
    800039b4:	f45e                	sd	s7,40(sp)
    800039b6:	f062                	sd	s8,32(sp)
    800039b8:	ec66                	sd	s9,24(sp)
    800039ba:	e86a                	sd	s10,16(sp)
    800039bc:	e46e                	sd	s11,8(sp)
    800039be:	1880                	addi	s0,sp,112
    800039c0:	8b2a                	mv	s6,a0
    800039c2:	8c2e                	mv	s8,a1
    800039c4:	8ab2                	mv	s5,a2
    800039c6:	8936                	mv	s2,a3
    800039c8:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800039ca:	00e687bb          	addw	a5,a3,a4
    800039ce:	0ed7e263          	bltu	a5,a3,80003ab2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800039d2:	00043737          	lui	a4,0x43
    800039d6:	0ef76063          	bltu	a4,a5,80003ab6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800039da:	0c0b8863          	beqz	s7,80003aaa <writei+0x10e>
    800039de:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039e0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800039e4:	5cfd                	li	s9,-1
    800039e6:	a091                	j	80003a2a <writei+0x8e>
    800039e8:	02099d93          	slli	s11,s3,0x20
    800039ec:	020ddd93          	srli	s11,s11,0x20
    800039f0:	05848513          	addi	a0,s1,88
    800039f4:	86ee                	mv	a3,s11
    800039f6:	8656                	mv	a2,s5
    800039f8:	85e2                	mv	a1,s8
    800039fa:	953a                	add	a0,a0,a4
    800039fc:	fffff097          	auipc	ra,0xfffff
    80003a00:	a4e080e7          	jalr	-1458(ra) # 8000244a <either_copyin>
    80003a04:	07950263          	beq	a0,s9,80003a68 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a08:	8526                	mv	a0,s1
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	790080e7          	jalr	1936(ra) # 8000419a <log_write>
    brelse(bp);
    80003a12:	8526                	mv	a0,s1
    80003a14:	fffff097          	auipc	ra,0xfffff
    80003a18:	50a080e7          	jalr	1290(ra) # 80002f1e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a1c:	01498a3b          	addw	s4,s3,s4
    80003a20:	0129893b          	addw	s2,s3,s2
    80003a24:	9aee                	add	s5,s5,s11
    80003a26:	057a7663          	bgeu	s4,s7,80003a72 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a2a:	000b2483          	lw	s1,0(s6)
    80003a2e:	00a9559b          	srliw	a1,s2,0xa
    80003a32:	855a                	mv	a0,s6
    80003a34:	fffff097          	auipc	ra,0xfffff
    80003a38:	7ae080e7          	jalr	1966(ra) # 800031e2 <bmap>
    80003a3c:	0005059b          	sext.w	a1,a0
    80003a40:	8526                	mv	a0,s1
    80003a42:	fffff097          	auipc	ra,0xfffff
    80003a46:	3ac080e7          	jalr	940(ra) # 80002dee <bread>
    80003a4a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a4c:	3ff97713          	andi	a4,s2,1023
    80003a50:	40ed07bb          	subw	a5,s10,a4
    80003a54:	414b86bb          	subw	a3,s7,s4
    80003a58:	89be                	mv	s3,a5
    80003a5a:	2781                	sext.w	a5,a5
    80003a5c:	0006861b          	sext.w	a2,a3
    80003a60:	f8f674e3          	bgeu	a2,a5,800039e8 <writei+0x4c>
    80003a64:	89b6                	mv	s3,a3
    80003a66:	b749                	j	800039e8 <writei+0x4c>
      brelse(bp);
    80003a68:	8526                	mv	a0,s1
    80003a6a:	fffff097          	auipc	ra,0xfffff
    80003a6e:	4b4080e7          	jalr	1204(ra) # 80002f1e <brelse>
  }

  if(off > ip->size)
    80003a72:	04cb2783          	lw	a5,76(s6)
    80003a76:	0127f463          	bgeu	a5,s2,80003a7e <writei+0xe2>
    ip->size = off;
    80003a7a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003a7e:	855a                	mv	a0,s6
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	aa6080e7          	jalr	-1370(ra) # 80003526 <iupdate>

  return tot;
    80003a88:	000a051b          	sext.w	a0,s4
}
    80003a8c:	70a6                	ld	ra,104(sp)
    80003a8e:	7406                	ld	s0,96(sp)
    80003a90:	64e6                	ld	s1,88(sp)
    80003a92:	6946                	ld	s2,80(sp)
    80003a94:	69a6                	ld	s3,72(sp)
    80003a96:	6a06                	ld	s4,64(sp)
    80003a98:	7ae2                	ld	s5,56(sp)
    80003a9a:	7b42                	ld	s6,48(sp)
    80003a9c:	7ba2                	ld	s7,40(sp)
    80003a9e:	7c02                	ld	s8,32(sp)
    80003aa0:	6ce2                	ld	s9,24(sp)
    80003aa2:	6d42                	ld	s10,16(sp)
    80003aa4:	6da2                	ld	s11,8(sp)
    80003aa6:	6165                	addi	sp,sp,112
    80003aa8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aaa:	8a5e                	mv	s4,s7
    80003aac:	bfc9                	j	80003a7e <writei+0xe2>
    return -1;
    80003aae:	557d                	li	a0,-1
}
    80003ab0:	8082                	ret
    return -1;
    80003ab2:	557d                	li	a0,-1
    80003ab4:	bfe1                	j	80003a8c <writei+0xf0>
    return -1;
    80003ab6:	557d                	li	a0,-1
    80003ab8:	bfd1                	j	80003a8c <writei+0xf0>

0000000080003aba <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003aba:	1141                	addi	sp,sp,-16
    80003abc:	e406                	sd	ra,8(sp)
    80003abe:	e022                	sd	s0,0(sp)
    80003ac0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ac2:	4639                	li	a2,14
    80003ac4:	ffffd097          	auipc	ra,0xffffd
    80003ac8:	2ea080e7          	jalr	746(ra) # 80000dae <strncmp>
}
    80003acc:	60a2                	ld	ra,8(sp)
    80003ace:	6402                	ld	s0,0(sp)
    80003ad0:	0141                	addi	sp,sp,16
    80003ad2:	8082                	ret

0000000080003ad4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ad4:	7139                	addi	sp,sp,-64
    80003ad6:	fc06                	sd	ra,56(sp)
    80003ad8:	f822                	sd	s0,48(sp)
    80003ada:	f426                	sd	s1,40(sp)
    80003adc:	f04a                	sd	s2,32(sp)
    80003ade:	ec4e                	sd	s3,24(sp)
    80003ae0:	e852                	sd	s4,16(sp)
    80003ae2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ae4:	04451703          	lh	a4,68(a0)
    80003ae8:	4785                	li	a5,1
    80003aea:	00f71a63          	bne	a4,a5,80003afe <dirlookup+0x2a>
    80003aee:	892a                	mv	s2,a0
    80003af0:	89ae                	mv	s3,a1
    80003af2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003af4:	457c                	lw	a5,76(a0)
    80003af6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003af8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003afa:	e79d                	bnez	a5,80003b28 <dirlookup+0x54>
    80003afc:	a8a5                	j	80003b74 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003afe:	00005517          	auipc	a0,0x5
    80003b02:	ada50513          	addi	a0,a0,-1318 # 800085d8 <syscalls+0x1a8>
    80003b06:	ffffd097          	auipc	ra,0xffffd
    80003b0a:	a2a080e7          	jalr	-1494(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003b0e:	00005517          	auipc	a0,0x5
    80003b12:	ae250513          	addi	a0,a0,-1310 # 800085f0 <syscalls+0x1c0>
    80003b16:	ffffd097          	auipc	ra,0xffffd
    80003b1a:	a1a080e7          	jalr	-1510(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b1e:	24c1                	addiw	s1,s1,16
    80003b20:	04c92783          	lw	a5,76(s2)
    80003b24:	04f4f763          	bgeu	s1,a5,80003b72 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b28:	4741                	li	a4,16
    80003b2a:	86a6                	mv	a3,s1
    80003b2c:	fc040613          	addi	a2,s0,-64
    80003b30:	4581                	li	a1,0
    80003b32:	854a                	mv	a0,s2
    80003b34:	00000097          	auipc	ra,0x0
    80003b38:	d70080e7          	jalr	-656(ra) # 800038a4 <readi>
    80003b3c:	47c1                	li	a5,16
    80003b3e:	fcf518e3          	bne	a0,a5,80003b0e <dirlookup+0x3a>
    if(de.inum == 0)
    80003b42:	fc045783          	lhu	a5,-64(s0)
    80003b46:	dfe1                	beqz	a5,80003b1e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b48:	fc240593          	addi	a1,s0,-62
    80003b4c:	854e                	mv	a0,s3
    80003b4e:	00000097          	auipc	ra,0x0
    80003b52:	f6c080e7          	jalr	-148(ra) # 80003aba <namecmp>
    80003b56:	f561                	bnez	a0,80003b1e <dirlookup+0x4a>
      if(poff)
    80003b58:	000a0463          	beqz	s4,80003b60 <dirlookup+0x8c>
        *poff = off;
    80003b5c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b60:	fc045583          	lhu	a1,-64(s0)
    80003b64:	00092503          	lw	a0,0(s2)
    80003b68:	fffff097          	auipc	ra,0xfffff
    80003b6c:	754080e7          	jalr	1876(ra) # 800032bc <iget>
    80003b70:	a011                	j	80003b74 <dirlookup+0xa0>
  return 0;
    80003b72:	4501                	li	a0,0
}
    80003b74:	70e2                	ld	ra,56(sp)
    80003b76:	7442                	ld	s0,48(sp)
    80003b78:	74a2                	ld	s1,40(sp)
    80003b7a:	7902                	ld	s2,32(sp)
    80003b7c:	69e2                	ld	s3,24(sp)
    80003b7e:	6a42                	ld	s4,16(sp)
    80003b80:	6121                	addi	sp,sp,64
    80003b82:	8082                	ret

0000000080003b84 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003b84:	711d                	addi	sp,sp,-96
    80003b86:	ec86                	sd	ra,88(sp)
    80003b88:	e8a2                	sd	s0,80(sp)
    80003b8a:	e4a6                	sd	s1,72(sp)
    80003b8c:	e0ca                	sd	s2,64(sp)
    80003b8e:	fc4e                	sd	s3,56(sp)
    80003b90:	f852                	sd	s4,48(sp)
    80003b92:	f456                	sd	s5,40(sp)
    80003b94:	f05a                	sd	s6,32(sp)
    80003b96:	ec5e                	sd	s7,24(sp)
    80003b98:	e862                	sd	s8,16(sp)
    80003b9a:	e466                	sd	s9,8(sp)
    80003b9c:	1080                	addi	s0,sp,96
    80003b9e:	84aa                	mv	s1,a0
    80003ba0:	8b2e                	mv	s6,a1
    80003ba2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ba4:	00054703          	lbu	a4,0(a0)
    80003ba8:	02f00793          	li	a5,47
    80003bac:	02f70363          	beq	a4,a5,80003bd2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bb0:	ffffe097          	auipc	ra,0xffffe
    80003bb4:	de4080e7          	jalr	-540(ra) # 80001994 <myproc>
    80003bb8:	15053503          	ld	a0,336(a0)
    80003bbc:	00000097          	auipc	ra,0x0
    80003bc0:	9f6080e7          	jalr	-1546(ra) # 800035b2 <idup>
    80003bc4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003bc6:	02f00913          	li	s2,47
  len = path - s;
    80003bca:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003bcc:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003bce:	4c05                	li	s8,1
    80003bd0:	a865                	j	80003c88 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003bd2:	4585                	li	a1,1
    80003bd4:	4505                	li	a0,1
    80003bd6:	fffff097          	auipc	ra,0xfffff
    80003bda:	6e6080e7          	jalr	1766(ra) # 800032bc <iget>
    80003bde:	89aa                	mv	s3,a0
    80003be0:	b7dd                	j	80003bc6 <namex+0x42>
      iunlockput(ip);
    80003be2:	854e                	mv	a0,s3
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	c6e080e7          	jalr	-914(ra) # 80003852 <iunlockput>
      return 0;
    80003bec:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003bee:	854e                	mv	a0,s3
    80003bf0:	60e6                	ld	ra,88(sp)
    80003bf2:	6446                	ld	s0,80(sp)
    80003bf4:	64a6                	ld	s1,72(sp)
    80003bf6:	6906                	ld	s2,64(sp)
    80003bf8:	79e2                	ld	s3,56(sp)
    80003bfa:	7a42                	ld	s4,48(sp)
    80003bfc:	7aa2                	ld	s5,40(sp)
    80003bfe:	7b02                	ld	s6,32(sp)
    80003c00:	6be2                	ld	s7,24(sp)
    80003c02:	6c42                	ld	s8,16(sp)
    80003c04:	6ca2                	ld	s9,8(sp)
    80003c06:	6125                	addi	sp,sp,96
    80003c08:	8082                	ret
      iunlock(ip);
    80003c0a:	854e                	mv	a0,s3
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	aa6080e7          	jalr	-1370(ra) # 800036b2 <iunlock>
      return ip;
    80003c14:	bfe9                	j	80003bee <namex+0x6a>
      iunlockput(ip);
    80003c16:	854e                	mv	a0,s3
    80003c18:	00000097          	auipc	ra,0x0
    80003c1c:	c3a080e7          	jalr	-966(ra) # 80003852 <iunlockput>
      return 0;
    80003c20:	89d2                	mv	s3,s4
    80003c22:	b7f1                	j	80003bee <namex+0x6a>
  len = path - s;
    80003c24:	40b48633          	sub	a2,s1,a1
    80003c28:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003c2c:	094cd463          	bge	s9,s4,80003cb4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003c30:	4639                	li	a2,14
    80003c32:	8556                	mv	a0,s5
    80003c34:	ffffd097          	auipc	ra,0xffffd
    80003c38:	0fe080e7          	jalr	254(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003c3c:	0004c783          	lbu	a5,0(s1)
    80003c40:	01279763          	bne	a5,s2,80003c4e <namex+0xca>
    path++;
    80003c44:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c46:	0004c783          	lbu	a5,0(s1)
    80003c4a:	ff278de3          	beq	a5,s2,80003c44 <namex+0xc0>
    ilock(ip);
    80003c4e:	854e                	mv	a0,s3
    80003c50:	00000097          	auipc	ra,0x0
    80003c54:	9a0080e7          	jalr	-1632(ra) # 800035f0 <ilock>
    if(ip->type != T_DIR){
    80003c58:	04499783          	lh	a5,68(s3)
    80003c5c:	f98793e3          	bne	a5,s8,80003be2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003c60:	000b0563          	beqz	s6,80003c6a <namex+0xe6>
    80003c64:	0004c783          	lbu	a5,0(s1)
    80003c68:	d3cd                	beqz	a5,80003c0a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c6a:	865e                	mv	a2,s7
    80003c6c:	85d6                	mv	a1,s5
    80003c6e:	854e                	mv	a0,s3
    80003c70:	00000097          	auipc	ra,0x0
    80003c74:	e64080e7          	jalr	-412(ra) # 80003ad4 <dirlookup>
    80003c78:	8a2a                	mv	s4,a0
    80003c7a:	dd51                	beqz	a0,80003c16 <namex+0x92>
    iunlockput(ip);
    80003c7c:	854e                	mv	a0,s3
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	bd4080e7          	jalr	-1068(ra) # 80003852 <iunlockput>
    ip = next;
    80003c86:	89d2                	mv	s3,s4
  while(*path == '/')
    80003c88:	0004c783          	lbu	a5,0(s1)
    80003c8c:	05279763          	bne	a5,s2,80003cda <namex+0x156>
    path++;
    80003c90:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c92:	0004c783          	lbu	a5,0(s1)
    80003c96:	ff278de3          	beq	a5,s2,80003c90 <namex+0x10c>
  if(*path == 0)
    80003c9a:	c79d                	beqz	a5,80003cc8 <namex+0x144>
    path++;
    80003c9c:	85a6                	mv	a1,s1
  len = path - s;
    80003c9e:	8a5e                	mv	s4,s7
    80003ca0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ca2:	01278963          	beq	a5,s2,80003cb4 <namex+0x130>
    80003ca6:	dfbd                	beqz	a5,80003c24 <namex+0xa0>
    path++;
    80003ca8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003caa:	0004c783          	lbu	a5,0(s1)
    80003cae:	ff279ce3          	bne	a5,s2,80003ca6 <namex+0x122>
    80003cb2:	bf8d                	j	80003c24 <namex+0xa0>
    memmove(name, s, len);
    80003cb4:	2601                	sext.w	a2,a2
    80003cb6:	8556                	mv	a0,s5
    80003cb8:	ffffd097          	auipc	ra,0xffffd
    80003cbc:	07a080e7          	jalr	122(ra) # 80000d32 <memmove>
    name[len] = 0;
    80003cc0:	9a56                	add	s4,s4,s5
    80003cc2:	000a0023          	sb	zero,0(s4)
    80003cc6:	bf9d                	j	80003c3c <namex+0xb8>
  if(nameiparent){
    80003cc8:	f20b03e3          	beqz	s6,80003bee <namex+0x6a>
    iput(ip);
    80003ccc:	854e                	mv	a0,s3
    80003cce:	00000097          	auipc	ra,0x0
    80003cd2:	adc080e7          	jalr	-1316(ra) # 800037aa <iput>
    return 0;
    80003cd6:	4981                	li	s3,0
    80003cd8:	bf19                	j	80003bee <namex+0x6a>
  if(*path == 0)
    80003cda:	d7fd                	beqz	a5,80003cc8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003cdc:	0004c783          	lbu	a5,0(s1)
    80003ce0:	85a6                	mv	a1,s1
    80003ce2:	b7d1                	j	80003ca6 <namex+0x122>

0000000080003ce4 <dirlink>:
{
    80003ce4:	7139                	addi	sp,sp,-64
    80003ce6:	fc06                	sd	ra,56(sp)
    80003ce8:	f822                	sd	s0,48(sp)
    80003cea:	f426                	sd	s1,40(sp)
    80003cec:	f04a                	sd	s2,32(sp)
    80003cee:	ec4e                	sd	s3,24(sp)
    80003cf0:	e852                	sd	s4,16(sp)
    80003cf2:	0080                	addi	s0,sp,64
    80003cf4:	892a                	mv	s2,a0
    80003cf6:	8a2e                	mv	s4,a1
    80003cf8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003cfa:	4601                	li	a2,0
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	dd8080e7          	jalr	-552(ra) # 80003ad4 <dirlookup>
    80003d04:	e93d                	bnez	a0,80003d7a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d06:	04c92483          	lw	s1,76(s2)
    80003d0a:	c49d                	beqz	s1,80003d38 <dirlink+0x54>
    80003d0c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d0e:	4741                	li	a4,16
    80003d10:	86a6                	mv	a3,s1
    80003d12:	fc040613          	addi	a2,s0,-64
    80003d16:	4581                	li	a1,0
    80003d18:	854a                	mv	a0,s2
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	b8a080e7          	jalr	-1142(ra) # 800038a4 <readi>
    80003d22:	47c1                	li	a5,16
    80003d24:	06f51163          	bne	a0,a5,80003d86 <dirlink+0xa2>
    if(de.inum == 0)
    80003d28:	fc045783          	lhu	a5,-64(s0)
    80003d2c:	c791                	beqz	a5,80003d38 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d2e:	24c1                	addiw	s1,s1,16
    80003d30:	04c92783          	lw	a5,76(s2)
    80003d34:	fcf4ede3          	bltu	s1,a5,80003d0e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d38:	4639                	li	a2,14
    80003d3a:	85d2                	mv	a1,s4
    80003d3c:	fc240513          	addi	a0,s0,-62
    80003d40:	ffffd097          	auipc	ra,0xffffd
    80003d44:	0aa080e7          	jalr	170(ra) # 80000dea <strncpy>
  de.inum = inum;
    80003d48:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d4c:	4741                	li	a4,16
    80003d4e:	86a6                	mv	a3,s1
    80003d50:	fc040613          	addi	a2,s0,-64
    80003d54:	4581                	li	a1,0
    80003d56:	854a                	mv	a0,s2
    80003d58:	00000097          	auipc	ra,0x0
    80003d5c:	c44080e7          	jalr	-956(ra) # 8000399c <writei>
    80003d60:	872a                	mv	a4,a0
    80003d62:	47c1                	li	a5,16
  return 0;
    80003d64:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d66:	02f71863          	bne	a4,a5,80003d96 <dirlink+0xb2>
}
    80003d6a:	70e2                	ld	ra,56(sp)
    80003d6c:	7442                	ld	s0,48(sp)
    80003d6e:	74a2                	ld	s1,40(sp)
    80003d70:	7902                	ld	s2,32(sp)
    80003d72:	69e2                	ld	s3,24(sp)
    80003d74:	6a42                	ld	s4,16(sp)
    80003d76:	6121                	addi	sp,sp,64
    80003d78:	8082                	ret
    iput(ip);
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	a30080e7          	jalr	-1488(ra) # 800037aa <iput>
    return -1;
    80003d82:	557d                	li	a0,-1
    80003d84:	b7dd                	j	80003d6a <dirlink+0x86>
      panic("dirlink read");
    80003d86:	00005517          	auipc	a0,0x5
    80003d8a:	87a50513          	addi	a0,a0,-1926 # 80008600 <syscalls+0x1d0>
    80003d8e:	ffffc097          	auipc	ra,0xffffc
    80003d92:	7a2080e7          	jalr	1954(ra) # 80000530 <panic>
    panic("dirlink");
    80003d96:	00005517          	auipc	a0,0x5
    80003d9a:	97a50513          	addi	a0,a0,-1670 # 80008710 <syscalls+0x2e0>
    80003d9e:	ffffc097          	auipc	ra,0xffffc
    80003da2:	792080e7          	jalr	1938(ra) # 80000530 <panic>

0000000080003da6 <namei>:

struct inode*
namei(char *path)
{
    80003da6:	1101                	addi	sp,sp,-32
    80003da8:	ec06                	sd	ra,24(sp)
    80003daa:	e822                	sd	s0,16(sp)
    80003dac:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dae:	fe040613          	addi	a2,s0,-32
    80003db2:	4581                	li	a1,0
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	dd0080e7          	jalr	-560(ra) # 80003b84 <namex>
}
    80003dbc:	60e2                	ld	ra,24(sp)
    80003dbe:	6442                	ld	s0,16(sp)
    80003dc0:	6105                	addi	sp,sp,32
    80003dc2:	8082                	ret

0000000080003dc4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003dc4:	1141                	addi	sp,sp,-16
    80003dc6:	e406                	sd	ra,8(sp)
    80003dc8:	e022                	sd	s0,0(sp)
    80003dca:	0800                	addi	s0,sp,16
    80003dcc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003dce:	4585                	li	a1,1
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	db4080e7          	jalr	-588(ra) # 80003b84 <namex>
}
    80003dd8:	60a2                	ld	ra,8(sp)
    80003dda:	6402                	ld	s0,0(sp)
    80003ddc:	0141                	addi	sp,sp,16
    80003dde:	8082                	ret

0000000080003de0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003de0:	1101                	addi	sp,sp,-32
    80003de2:	ec06                	sd	ra,24(sp)
    80003de4:	e822                	sd	s0,16(sp)
    80003de6:	e426                	sd	s1,8(sp)
    80003de8:	e04a                	sd	s2,0(sp)
    80003dea:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003dec:	0001d917          	auipc	s2,0x1d
    80003df0:	48490913          	addi	s2,s2,1156 # 80021270 <log>
    80003df4:	01892583          	lw	a1,24(s2)
    80003df8:	02892503          	lw	a0,40(s2)
    80003dfc:	fffff097          	auipc	ra,0xfffff
    80003e00:	ff2080e7          	jalr	-14(ra) # 80002dee <bread>
    80003e04:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e06:	02c92683          	lw	a3,44(s2)
    80003e0a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e0c:	02d05763          	blez	a3,80003e3a <write_head+0x5a>
    80003e10:	0001d797          	auipc	a5,0x1d
    80003e14:	49078793          	addi	a5,a5,1168 # 800212a0 <log+0x30>
    80003e18:	05c50713          	addi	a4,a0,92
    80003e1c:	36fd                	addiw	a3,a3,-1
    80003e1e:	1682                	slli	a3,a3,0x20
    80003e20:	9281                	srli	a3,a3,0x20
    80003e22:	068a                	slli	a3,a3,0x2
    80003e24:	0001d617          	auipc	a2,0x1d
    80003e28:	48060613          	addi	a2,a2,1152 # 800212a4 <log+0x34>
    80003e2c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e2e:	4390                	lw	a2,0(a5)
    80003e30:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e32:	0791                	addi	a5,a5,4
    80003e34:	0711                	addi	a4,a4,4
    80003e36:	fed79ce3          	bne	a5,a3,80003e2e <write_head+0x4e>
  }
  bwrite(buf);
    80003e3a:	8526                	mv	a0,s1
    80003e3c:	fffff097          	auipc	ra,0xfffff
    80003e40:	0a4080e7          	jalr	164(ra) # 80002ee0 <bwrite>
  brelse(buf);
    80003e44:	8526                	mv	a0,s1
    80003e46:	fffff097          	auipc	ra,0xfffff
    80003e4a:	0d8080e7          	jalr	216(ra) # 80002f1e <brelse>
}
    80003e4e:	60e2                	ld	ra,24(sp)
    80003e50:	6442                	ld	s0,16(sp)
    80003e52:	64a2                	ld	s1,8(sp)
    80003e54:	6902                	ld	s2,0(sp)
    80003e56:	6105                	addi	sp,sp,32
    80003e58:	8082                	ret

0000000080003e5a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e5a:	0001d797          	auipc	a5,0x1d
    80003e5e:	4427a783          	lw	a5,1090(a5) # 8002129c <log+0x2c>
    80003e62:	0af05d63          	blez	a5,80003f1c <install_trans+0xc2>
{
    80003e66:	7139                	addi	sp,sp,-64
    80003e68:	fc06                	sd	ra,56(sp)
    80003e6a:	f822                	sd	s0,48(sp)
    80003e6c:	f426                	sd	s1,40(sp)
    80003e6e:	f04a                	sd	s2,32(sp)
    80003e70:	ec4e                	sd	s3,24(sp)
    80003e72:	e852                	sd	s4,16(sp)
    80003e74:	e456                	sd	s5,8(sp)
    80003e76:	e05a                	sd	s6,0(sp)
    80003e78:	0080                	addi	s0,sp,64
    80003e7a:	8b2a                	mv	s6,a0
    80003e7c:	0001da97          	auipc	s5,0x1d
    80003e80:	424a8a93          	addi	s5,s5,1060 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e84:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e86:	0001d997          	auipc	s3,0x1d
    80003e8a:	3ea98993          	addi	s3,s3,1002 # 80021270 <log>
    80003e8e:	a035                	j	80003eba <install_trans+0x60>
      bunpin(dbuf);
    80003e90:	8526                	mv	a0,s1
    80003e92:	fffff097          	auipc	ra,0xfffff
    80003e96:	166080e7          	jalr	358(ra) # 80002ff8 <bunpin>
    brelse(lbuf);
    80003e9a:	854a                	mv	a0,s2
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	082080e7          	jalr	130(ra) # 80002f1e <brelse>
    brelse(dbuf);
    80003ea4:	8526                	mv	a0,s1
    80003ea6:	fffff097          	auipc	ra,0xfffff
    80003eaa:	078080e7          	jalr	120(ra) # 80002f1e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eae:	2a05                	addiw	s4,s4,1
    80003eb0:	0a91                	addi	s5,s5,4
    80003eb2:	02c9a783          	lw	a5,44(s3)
    80003eb6:	04fa5963          	bge	s4,a5,80003f08 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003eba:	0189a583          	lw	a1,24(s3)
    80003ebe:	014585bb          	addw	a1,a1,s4
    80003ec2:	2585                	addiw	a1,a1,1
    80003ec4:	0289a503          	lw	a0,40(s3)
    80003ec8:	fffff097          	auipc	ra,0xfffff
    80003ecc:	f26080e7          	jalr	-218(ra) # 80002dee <bread>
    80003ed0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ed2:	000aa583          	lw	a1,0(s5)
    80003ed6:	0289a503          	lw	a0,40(s3)
    80003eda:	fffff097          	auipc	ra,0xfffff
    80003ede:	f14080e7          	jalr	-236(ra) # 80002dee <bread>
    80003ee2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ee4:	40000613          	li	a2,1024
    80003ee8:	05890593          	addi	a1,s2,88
    80003eec:	05850513          	addi	a0,a0,88
    80003ef0:	ffffd097          	auipc	ra,0xffffd
    80003ef4:	e42080e7          	jalr	-446(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003ef8:	8526                	mv	a0,s1
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	fe6080e7          	jalr	-26(ra) # 80002ee0 <bwrite>
    if(recovering == 0)
    80003f02:	f80b1ce3          	bnez	s6,80003e9a <install_trans+0x40>
    80003f06:	b769                	j	80003e90 <install_trans+0x36>
}
    80003f08:	70e2                	ld	ra,56(sp)
    80003f0a:	7442                	ld	s0,48(sp)
    80003f0c:	74a2                	ld	s1,40(sp)
    80003f0e:	7902                	ld	s2,32(sp)
    80003f10:	69e2                	ld	s3,24(sp)
    80003f12:	6a42                	ld	s4,16(sp)
    80003f14:	6aa2                	ld	s5,8(sp)
    80003f16:	6b02                	ld	s6,0(sp)
    80003f18:	6121                	addi	sp,sp,64
    80003f1a:	8082                	ret
    80003f1c:	8082                	ret

0000000080003f1e <initlog>:
{
    80003f1e:	7179                	addi	sp,sp,-48
    80003f20:	f406                	sd	ra,40(sp)
    80003f22:	f022                	sd	s0,32(sp)
    80003f24:	ec26                	sd	s1,24(sp)
    80003f26:	e84a                	sd	s2,16(sp)
    80003f28:	e44e                	sd	s3,8(sp)
    80003f2a:	1800                	addi	s0,sp,48
    80003f2c:	892a                	mv	s2,a0
    80003f2e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f30:	0001d497          	auipc	s1,0x1d
    80003f34:	34048493          	addi	s1,s1,832 # 80021270 <log>
    80003f38:	00004597          	auipc	a1,0x4
    80003f3c:	6d858593          	addi	a1,a1,1752 # 80008610 <syscalls+0x1e0>
    80003f40:	8526                	mv	a0,s1
    80003f42:	ffffd097          	auipc	ra,0xffffd
    80003f46:	c04080e7          	jalr	-1020(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80003f4a:	0149a583          	lw	a1,20(s3)
    80003f4e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f50:	0109a783          	lw	a5,16(s3)
    80003f54:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f56:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f5a:	854a                	mv	a0,s2
    80003f5c:	fffff097          	auipc	ra,0xfffff
    80003f60:	e92080e7          	jalr	-366(ra) # 80002dee <bread>
  log.lh.n = lh->n;
    80003f64:	4d3c                	lw	a5,88(a0)
    80003f66:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f68:	02f05563          	blez	a5,80003f92 <initlog+0x74>
    80003f6c:	05c50713          	addi	a4,a0,92
    80003f70:	0001d697          	auipc	a3,0x1d
    80003f74:	33068693          	addi	a3,a3,816 # 800212a0 <log+0x30>
    80003f78:	37fd                	addiw	a5,a5,-1
    80003f7a:	1782                	slli	a5,a5,0x20
    80003f7c:	9381                	srli	a5,a5,0x20
    80003f7e:	078a                	slli	a5,a5,0x2
    80003f80:	06050613          	addi	a2,a0,96
    80003f84:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80003f86:	4310                	lw	a2,0(a4)
    80003f88:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80003f8a:	0711                	addi	a4,a4,4
    80003f8c:	0691                	addi	a3,a3,4
    80003f8e:	fef71ce3          	bne	a4,a5,80003f86 <initlog+0x68>
  brelse(buf);
    80003f92:	fffff097          	auipc	ra,0xfffff
    80003f96:	f8c080e7          	jalr	-116(ra) # 80002f1e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f9a:	4505                	li	a0,1
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	ebe080e7          	jalr	-322(ra) # 80003e5a <install_trans>
  log.lh.n = 0;
    80003fa4:	0001d797          	auipc	a5,0x1d
    80003fa8:	2e07ac23          	sw	zero,760(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	e34080e7          	jalr	-460(ra) # 80003de0 <write_head>
}
    80003fb4:	70a2                	ld	ra,40(sp)
    80003fb6:	7402                	ld	s0,32(sp)
    80003fb8:	64e2                	ld	s1,24(sp)
    80003fba:	6942                	ld	s2,16(sp)
    80003fbc:	69a2                	ld	s3,8(sp)
    80003fbe:	6145                	addi	sp,sp,48
    80003fc0:	8082                	ret

0000000080003fc2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003fc2:	1101                	addi	sp,sp,-32
    80003fc4:	ec06                	sd	ra,24(sp)
    80003fc6:	e822                	sd	s0,16(sp)
    80003fc8:	e426                	sd	s1,8(sp)
    80003fca:	e04a                	sd	s2,0(sp)
    80003fcc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003fce:	0001d517          	auipc	a0,0x1d
    80003fd2:	2a250513          	addi	a0,a0,674 # 80021270 <log>
    80003fd6:	ffffd097          	auipc	ra,0xffffd
    80003fda:	c00080e7          	jalr	-1024(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80003fde:	0001d497          	auipc	s1,0x1d
    80003fe2:	29248493          	addi	s1,s1,658 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003fe6:	4979                	li	s2,30
    80003fe8:	a039                	j	80003ff6 <begin_op+0x34>
      sleep(&log, &log.lock);
    80003fea:	85a6                	mv	a1,s1
    80003fec:	8526                	mv	a0,s1
    80003fee:	ffffe097          	auipc	ra,0xffffe
    80003ff2:	062080e7          	jalr	98(ra) # 80002050 <sleep>
    if(log.committing){
    80003ff6:	50dc                	lw	a5,36(s1)
    80003ff8:	fbed                	bnez	a5,80003fea <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80003ffa:	509c                	lw	a5,32(s1)
    80003ffc:	0017871b          	addiw	a4,a5,1
    80004000:	0007069b          	sext.w	a3,a4
    80004004:	0027179b          	slliw	a5,a4,0x2
    80004008:	9fb9                	addw	a5,a5,a4
    8000400a:	0017979b          	slliw	a5,a5,0x1
    8000400e:	54d8                	lw	a4,44(s1)
    80004010:	9fb9                	addw	a5,a5,a4
    80004012:	00f95963          	bge	s2,a5,80004024 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004016:	85a6                	mv	a1,s1
    80004018:	8526                	mv	a0,s1
    8000401a:	ffffe097          	auipc	ra,0xffffe
    8000401e:	036080e7          	jalr	54(ra) # 80002050 <sleep>
    80004022:	bfd1                	j	80003ff6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004024:	0001d517          	auipc	a0,0x1d
    80004028:	24c50513          	addi	a0,a0,588 # 80021270 <log>
    8000402c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000402e:	ffffd097          	auipc	ra,0xffffd
    80004032:	c5c080e7          	jalr	-932(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004036:	60e2                	ld	ra,24(sp)
    80004038:	6442                	ld	s0,16(sp)
    8000403a:	64a2                	ld	s1,8(sp)
    8000403c:	6902                	ld	s2,0(sp)
    8000403e:	6105                	addi	sp,sp,32
    80004040:	8082                	ret

0000000080004042 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004042:	7139                	addi	sp,sp,-64
    80004044:	fc06                	sd	ra,56(sp)
    80004046:	f822                	sd	s0,48(sp)
    80004048:	f426                	sd	s1,40(sp)
    8000404a:	f04a                	sd	s2,32(sp)
    8000404c:	ec4e                	sd	s3,24(sp)
    8000404e:	e852                	sd	s4,16(sp)
    80004050:	e456                	sd	s5,8(sp)
    80004052:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004054:	0001d497          	auipc	s1,0x1d
    80004058:	21c48493          	addi	s1,s1,540 # 80021270 <log>
    8000405c:	8526                	mv	a0,s1
    8000405e:	ffffd097          	auipc	ra,0xffffd
    80004062:	b78080e7          	jalr	-1160(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004066:	509c                	lw	a5,32(s1)
    80004068:	37fd                	addiw	a5,a5,-1
    8000406a:	0007891b          	sext.w	s2,a5
    8000406e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004070:	50dc                	lw	a5,36(s1)
    80004072:	efb9                	bnez	a5,800040d0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004074:	06091663          	bnez	s2,800040e0 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004078:	0001d497          	auipc	s1,0x1d
    8000407c:	1f848493          	addi	s1,s1,504 # 80021270 <log>
    80004080:	4785                	li	a5,1
    80004082:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004084:	8526                	mv	a0,s1
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	c04080e7          	jalr	-1020(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000408e:	54dc                	lw	a5,44(s1)
    80004090:	06f04763          	bgtz	a5,800040fe <end_op+0xbc>
    acquire(&log.lock);
    80004094:	0001d497          	auipc	s1,0x1d
    80004098:	1dc48493          	addi	s1,s1,476 # 80021270 <log>
    8000409c:	8526                	mv	a0,s1
    8000409e:	ffffd097          	auipc	ra,0xffffd
    800040a2:	b38080e7          	jalr	-1224(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800040a6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040aa:	8526                	mv	a0,s1
    800040ac:	ffffe097          	auipc	ra,0xffffe
    800040b0:	130080e7          	jalr	304(ra) # 800021dc <wakeup>
    release(&log.lock);
    800040b4:	8526                	mv	a0,s1
    800040b6:	ffffd097          	auipc	ra,0xffffd
    800040ba:	bd4080e7          	jalr	-1068(ra) # 80000c8a <release>
}
    800040be:	70e2                	ld	ra,56(sp)
    800040c0:	7442                	ld	s0,48(sp)
    800040c2:	74a2                	ld	s1,40(sp)
    800040c4:	7902                	ld	s2,32(sp)
    800040c6:	69e2                	ld	s3,24(sp)
    800040c8:	6a42                	ld	s4,16(sp)
    800040ca:	6aa2                	ld	s5,8(sp)
    800040cc:	6121                	addi	sp,sp,64
    800040ce:	8082                	ret
    panic("log.committing");
    800040d0:	00004517          	auipc	a0,0x4
    800040d4:	54850513          	addi	a0,a0,1352 # 80008618 <syscalls+0x1e8>
    800040d8:	ffffc097          	auipc	ra,0xffffc
    800040dc:	458080e7          	jalr	1112(ra) # 80000530 <panic>
    wakeup(&log);
    800040e0:	0001d497          	auipc	s1,0x1d
    800040e4:	19048493          	addi	s1,s1,400 # 80021270 <log>
    800040e8:	8526                	mv	a0,s1
    800040ea:	ffffe097          	auipc	ra,0xffffe
    800040ee:	0f2080e7          	jalr	242(ra) # 800021dc <wakeup>
  release(&log.lock);
    800040f2:	8526                	mv	a0,s1
    800040f4:	ffffd097          	auipc	ra,0xffffd
    800040f8:	b96080e7          	jalr	-1130(ra) # 80000c8a <release>
  if(do_commit){
    800040fc:	b7c9                	j	800040be <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040fe:	0001da97          	auipc	s5,0x1d
    80004102:	1a2a8a93          	addi	s5,s5,418 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004106:	0001da17          	auipc	s4,0x1d
    8000410a:	16aa0a13          	addi	s4,s4,362 # 80021270 <log>
    8000410e:	018a2583          	lw	a1,24(s4)
    80004112:	012585bb          	addw	a1,a1,s2
    80004116:	2585                	addiw	a1,a1,1
    80004118:	028a2503          	lw	a0,40(s4)
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	cd2080e7          	jalr	-814(ra) # 80002dee <bread>
    80004124:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004126:	000aa583          	lw	a1,0(s5)
    8000412a:	028a2503          	lw	a0,40(s4)
    8000412e:	fffff097          	auipc	ra,0xfffff
    80004132:	cc0080e7          	jalr	-832(ra) # 80002dee <bread>
    80004136:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004138:	40000613          	li	a2,1024
    8000413c:	05850593          	addi	a1,a0,88
    80004140:	05848513          	addi	a0,s1,88
    80004144:	ffffd097          	auipc	ra,0xffffd
    80004148:	bee080e7          	jalr	-1042(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    8000414c:	8526                	mv	a0,s1
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	d92080e7          	jalr	-622(ra) # 80002ee0 <bwrite>
    brelse(from);
    80004156:	854e                	mv	a0,s3
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	dc6080e7          	jalr	-570(ra) # 80002f1e <brelse>
    brelse(to);
    80004160:	8526                	mv	a0,s1
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	dbc080e7          	jalr	-580(ra) # 80002f1e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416a:	2905                	addiw	s2,s2,1
    8000416c:	0a91                	addi	s5,s5,4
    8000416e:	02ca2783          	lw	a5,44(s4)
    80004172:	f8f94ee3          	blt	s2,a5,8000410e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	c6a080e7          	jalr	-918(ra) # 80003de0 <write_head>
    install_trans(0); // Now install writes to home locations
    8000417e:	4501                	li	a0,0
    80004180:	00000097          	auipc	ra,0x0
    80004184:	cda080e7          	jalr	-806(ra) # 80003e5a <install_trans>
    log.lh.n = 0;
    80004188:	0001d797          	auipc	a5,0x1d
    8000418c:	1007aa23          	sw	zero,276(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004190:	00000097          	auipc	ra,0x0
    80004194:	c50080e7          	jalr	-944(ra) # 80003de0 <write_head>
    80004198:	bdf5                	j	80004094 <end_op+0x52>

000000008000419a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000419a:	1101                	addi	sp,sp,-32
    8000419c:	ec06                	sd	ra,24(sp)
    8000419e:	e822                	sd	s0,16(sp)
    800041a0:	e426                	sd	s1,8(sp)
    800041a2:	e04a                	sd	s2,0(sp)
    800041a4:	1000                	addi	s0,sp,32
    800041a6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800041a8:	0001d917          	auipc	s2,0x1d
    800041ac:	0c890913          	addi	s2,s2,200 # 80021270 <log>
    800041b0:	854a                	mv	a0,s2
    800041b2:	ffffd097          	auipc	ra,0xffffd
    800041b6:	a24080e7          	jalr	-1500(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041ba:	02c92603          	lw	a2,44(s2)
    800041be:	47f5                	li	a5,29
    800041c0:	06c7c563          	blt	a5,a2,8000422a <log_write+0x90>
    800041c4:	0001d797          	auipc	a5,0x1d
    800041c8:	0c87a783          	lw	a5,200(a5) # 8002128c <log+0x1c>
    800041cc:	37fd                	addiw	a5,a5,-1
    800041ce:	04f65e63          	bge	a2,a5,8000422a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800041d2:	0001d797          	auipc	a5,0x1d
    800041d6:	0be7a783          	lw	a5,190(a5) # 80021290 <log+0x20>
    800041da:	06f05063          	blez	a5,8000423a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800041de:	4781                	li	a5,0
    800041e0:	06c05563          	blez	a2,8000424a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800041e4:	44cc                	lw	a1,12(s1)
    800041e6:	0001d717          	auipc	a4,0x1d
    800041ea:	0ba70713          	addi	a4,a4,186 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800041ee:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800041f0:	4314                	lw	a3,0(a4)
    800041f2:	04b68c63          	beq	a3,a1,8000424a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800041f6:	2785                	addiw	a5,a5,1
    800041f8:	0711                	addi	a4,a4,4
    800041fa:	fef61be3          	bne	a2,a5,800041f0 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800041fe:	0621                	addi	a2,a2,8
    80004200:	060a                	slli	a2,a2,0x2
    80004202:	0001d797          	auipc	a5,0x1d
    80004206:	06e78793          	addi	a5,a5,110 # 80021270 <log>
    8000420a:	963e                	add	a2,a2,a5
    8000420c:	44dc                	lw	a5,12(s1)
    8000420e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004210:	8526                	mv	a0,s1
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	daa080e7          	jalr	-598(ra) # 80002fbc <bpin>
    log.lh.n++;
    8000421a:	0001d717          	auipc	a4,0x1d
    8000421e:	05670713          	addi	a4,a4,86 # 80021270 <log>
    80004222:	575c                	lw	a5,44(a4)
    80004224:	2785                	addiw	a5,a5,1
    80004226:	d75c                	sw	a5,44(a4)
    80004228:	a835                	j	80004264 <log_write+0xca>
    panic("too big a transaction");
    8000422a:	00004517          	auipc	a0,0x4
    8000422e:	3fe50513          	addi	a0,a0,1022 # 80008628 <syscalls+0x1f8>
    80004232:	ffffc097          	auipc	ra,0xffffc
    80004236:	2fe080e7          	jalr	766(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    8000423a:	00004517          	auipc	a0,0x4
    8000423e:	40650513          	addi	a0,a0,1030 # 80008640 <syscalls+0x210>
    80004242:	ffffc097          	auipc	ra,0xffffc
    80004246:	2ee080e7          	jalr	750(ra) # 80000530 <panic>
  log.lh.block[i] = b->blockno;
    8000424a:	00878713          	addi	a4,a5,8
    8000424e:	00271693          	slli	a3,a4,0x2
    80004252:	0001d717          	auipc	a4,0x1d
    80004256:	01e70713          	addi	a4,a4,30 # 80021270 <log>
    8000425a:	9736                	add	a4,a4,a3
    8000425c:	44d4                	lw	a3,12(s1)
    8000425e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004260:	faf608e3          	beq	a2,a5,80004210 <log_write+0x76>
  }
  release(&log.lock);
    80004264:	0001d517          	auipc	a0,0x1d
    80004268:	00c50513          	addi	a0,a0,12 # 80021270 <log>
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	a1e080e7          	jalr	-1506(ra) # 80000c8a <release>
}
    80004274:	60e2                	ld	ra,24(sp)
    80004276:	6442                	ld	s0,16(sp)
    80004278:	64a2                	ld	s1,8(sp)
    8000427a:	6902                	ld	s2,0(sp)
    8000427c:	6105                	addi	sp,sp,32
    8000427e:	8082                	ret

0000000080004280 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004280:	1101                	addi	sp,sp,-32
    80004282:	ec06                	sd	ra,24(sp)
    80004284:	e822                	sd	s0,16(sp)
    80004286:	e426                	sd	s1,8(sp)
    80004288:	e04a                	sd	s2,0(sp)
    8000428a:	1000                	addi	s0,sp,32
    8000428c:	84aa                	mv	s1,a0
    8000428e:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004290:	00004597          	auipc	a1,0x4
    80004294:	3d058593          	addi	a1,a1,976 # 80008660 <syscalls+0x230>
    80004298:	0521                	addi	a0,a0,8
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	8ac080e7          	jalr	-1876(ra) # 80000b46 <initlock>
  lk->name = name;
    800042a2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042a6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042aa:	0204a423          	sw	zero,40(s1)
}
    800042ae:	60e2                	ld	ra,24(sp)
    800042b0:	6442                	ld	s0,16(sp)
    800042b2:	64a2                	ld	s1,8(sp)
    800042b4:	6902                	ld	s2,0(sp)
    800042b6:	6105                	addi	sp,sp,32
    800042b8:	8082                	ret

00000000800042ba <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800042ba:	1101                	addi	sp,sp,-32
    800042bc:	ec06                	sd	ra,24(sp)
    800042be:	e822                	sd	s0,16(sp)
    800042c0:	e426                	sd	s1,8(sp)
    800042c2:	e04a                	sd	s2,0(sp)
    800042c4:	1000                	addi	s0,sp,32
    800042c6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800042c8:	00850913          	addi	s2,a0,8
    800042cc:	854a                	mv	a0,s2
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	908080e7          	jalr	-1784(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800042d6:	409c                	lw	a5,0(s1)
    800042d8:	cb89                	beqz	a5,800042ea <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800042da:	85ca                	mv	a1,s2
    800042dc:	8526                	mv	a0,s1
    800042de:	ffffe097          	auipc	ra,0xffffe
    800042e2:	d72080e7          	jalr	-654(ra) # 80002050 <sleep>
  while (lk->locked) {
    800042e6:	409c                	lw	a5,0(s1)
    800042e8:	fbed                	bnez	a5,800042da <acquiresleep+0x20>
  }
  lk->locked = 1;
    800042ea:	4785                	li	a5,1
    800042ec:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	6a6080e7          	jalr	1702(ra) # 80001994 <myproc>
    800042f6:	591c                	lw	a5,48(a0)
    800042f8:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800042fa:	854a                	mv	a0,s2
    800042fc:	ffffd097          	auipc	ra,0xffffd
    80004300:	98e080e7          	jalr	-1650(ra) # 80000c8a <release>
}
    80004304:	60e2                	ld	ra,24(sp)
    80004306:	6442                	ld	s0,16(sp)
    80004308:	64a2                	ld	s1,8(sp)
    8000430a:	6902                	ld	s2,0(sp)
    8000430c:	6105                	addi	sp,sp,32
    8000430e:	8082                	ret

0000000080004310 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004310:	1101                	addi	sp,sp,-32
    80004312:	ec06                	sd	ra,24(sp)
    80004314:	e822                	sd	s0,16(sp)
    80004316:	e426                	sd	s1,8(sp)
    80004318:	e04a                	sd	s2,0(sp)
    8000431a:	1000                	addi	s0,sp,32
    8000431c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000431e:	00850913          	addi	s2,a0,8
    80004322:	854a                	mv	a0,s2
    80004324:	ffffd097          	auipc	ra,0xffffd
    80004328:	8b2080e7          	jalr	-1870(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000432c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004330:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004334:	8526                	mv	a0,s1
    80004336:	ffffe097          	auipc	ra,0xffffe
    8000433a:	ea6080e7          	jalr	-346(ra) # 800021dc <wakeup>
  release(&lk->lk);
    8000433e:	854a                	mv	a0,s2
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	94a080e7          	jalr	-1718(ra) # 80000c8a <release>
}
    80004348:	60e2                	ld	ra,24(sp)
    8000434a:	6442                	ld	s0,16(sp)
    8000434c:	64a2                	ld	s1,8(sp)
    8000434e:	6902                	ld	s2,0(sp)
    80004350:	6105                	addi	sp,sp,32
    80004352:	8082                	ret

0000000080004354 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004354:	7179                	addi	sp,sp,-48
    80004356:	f406                	sd	ra,40(sp)
    80004358:	f022                	sd	s0,32(sp)
    8000435a:	ec26                	sd	s1,24(sp)
    8000435c:	e84a                	sd	s2,16(sp)
    8000435e:	e44e                	sd	s3,8(sp)
    80004360:	1800                	addi	s0,sp,48
    80004362:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004364:	00850913          	addi	s2,a0,8
    80004368:	854a                	mv	a0,s2
    8000436a:	ffffd097          	auipc	ra,0xffffd
    8000436e:	86c080e7          	jalr	-1940(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004372:	409c                	lw	a5,0(s1)
    80004374:	ef99                	bnez	a5,80004392 <holdingsleep+0x3e>
    80004376:	4481                	li	s1,0
  release(&lk->lk);
    80004378:	854a                	mv	a0,s2
    8000437a:	ffffd097          	auipc	ra,0xffffd
    8000437e:	910080e7          	jalr	-1776(ra) # 80000c8a <release>
  return r;
}
    80004382:	8526                	mv	a0,s1
    80004384:	70a2                	ld	ra,40(sp)
    80004386:	7402                	ld	s0,32(sp)
    80004388:	64e2                	ld	s1,24(sp)
    8000438a:	6942                	ld	s2,16(sp)
    8000438c:	69a2                	ld	s3,8(sp)
    8000438e:	6145                	addi	sp,sp,48
    80004390:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004392:	0284a983          	lw	s3,40(s1)
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	5fe080e7          	jalr	1534(ra) # 80001994 <myproc>
    8000439e:	5904                	lw	s1,48(a0)
    800043a0:	413484b3          	sub	s1,s1,s3
    800043a4:	0014b493          	seqz	s1,s1
    800043a8:	bfc1                	j	80004378 <holdingsleep+0x24>

00000000800043aa <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043aa:	1141                	addi	sp,sp,-16
    800043ac:	e406                	sd	ra,8(sp)
    800043ae:	e022                	sd	s0,0(sp)
    800043b0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043b2:	00004597          	auipc	a1,0x4
    800043b6:	2be58593          	addi	a1,a1,702 # 80008670 <syscalls+0x240>
    800043ba:	0001d517          	auipc	a0,0x1d
    800043be:	ffe50513          	addi	a0,a0,-2 # 800213b8 <ftable>
    800043c2:	ffffc097          	auipc	ra,0xffffc
    800043c6:	784080e7          	jalr	1924(ra) # 80000b46 <initlock>
}
    800043ca:	60a2                	ld	ra,8(sp)
    800043cc:	6402                	ld	s0,0(sp)
    800043ce:	0141                	addi	sp,sp,16
    800043d0:	8082                	ret

00000000800043d2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800043d2:	1101                	addi	sp,sp,-32
    800043d4:	ec06                	sd	ra,24(sp)
    800043d6:	e822                	sd	s0,16(sp)
    800043d8:	e426                	sd	s1,8(sp)
    800043da:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800043dc:	0001d517          	auipc	a0,0x1d
    800043e0:	fdc50513          	addi	a0,a0,-36 # 800213b8 <ftable>
    800043e4:	ffffc097          	auipc	ra,0xffffc
    800043e8:	7f2080e7          	jalr	2034(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800043ec:	0001d497          	auipc	s1,0x1d
    800043f0:	fe448493          	addi	s1,s1,-28 # 800213d0 <ftable+0x18>
    800043f4:	0001e717          	auipc	a4,0x1e
    800043f8:	f7c70713          	addi	a4,a4,-132 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800043fc:	40dc                	lw	a5,4(s1)
    800043fe:	cf99                	beqz	a5,8000441c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004400:	02848493          	addi	s1,s1,40
    80004404:	fee49ce3          	bne	s1,a4,800043fc <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004408:	0001d517          	auipc	a0,0x1d
    8000440c:	fb050513          	addi	a0,a0,-80 # 800213b8 <ftable>
    80004410:	ffffd097          	auipc	ra,0xffffd
    80004414:	87a080e7          	jalr	-1926(ra) # 80000c8a <release>
  return 0;
    80004418:	4481                	li	s1,0
    8000441a:	a819                	j	80004430 <filealloc+0x5e>
      f->ref = 1;
    8000441c:	4785                	li	a5,1
    8000441e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004420:	0001d517          	auipc	a0,0x1d
    80004424:	f9850513          	addi	a0,a0,-104 # 800213b8 <ftable>
    80004428:	ffffd097          	auipc	ra,0xffffd
    8000442c:	862080e7          	jalr	-1950(ra) # 80000c8a <release>
}
    80004430:	8526                	mv	a0,s1
    80004432:	60e2                	ld	ra,24(sp)
    80004434:	6442                	ld	s0,16(sp)
    80004436:	64a2                	ld	s1,8(sp)
    80004438:	6105                	addi	sp,sp,32
    8000443a:	8082                	ret

000000008000443c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000443c:	1101                	addi	sp,sp,-32
    8000443e:	ec06                	sd	ra,24(sp)
    80004440:	e822                	sd	s0,16(sp)
    80004442:	e426                	sd	s1,8(sp)
    80004444:	1000                	addi	s0,sp,32
    80004446:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004448:	0001d517          	auipc	a0,0x1d
    8000444c:	f7050513          	addi	a0,a0,-144 # 800213b8 <ftable>
    80004450:	ffffc097          	auipc	ra,0xffffc
    80004454:	786080e7          	jalr	1926(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004458:	40dc                	lw	a5,4(s1)
    8000445a:	02f05263          	blez	a5,8000447e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000445e:	2785                	addiw	a5,a5,1
    80004460:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004462:	0001d517          	auipc	a0,0x1d
    80004466:	f5650513          	addi	a0,a0,-170 # 800213b8 <ftable>
    8000446a:	ffffd097          	auipc	ra,0xffffd
    8000446e:	820080e7          	jalr	-2016(ra) # 80000c8a <release>
  return f;
}
    80004472:	8526                	mv	a0,s1
    80004474:	60e2                	ld	ra,24(sp)
    80004476:	6442                	ld	s0,16(sp)
    80004478:	64a2                	ld	s1,8(sp)
    8000447a:	6105                	addi	sp,sp,32
    8000447c:	8082                	ret
    panic("filedup");
    8000447e:	00004517          	auipc	a0,0x4
    80004482:	1fa50513          	addi	a0,a0,506 # 80008678 <syscalls+0x248>
    80004486:	ffffc097          	auipc	ra,0xffffc
    8000448a:	0aa080e7          	jalr	170(ra) # 80000530 <panic>

000000008000448e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000448e:	7139                	addi	sp,sp,-64
    80004490:	fc06                	sd	ra,56(sp)
    80004492:	f822                	sd	s0,48(sp)
    80004494:	f426                	sd	s1,40(sp)
    80004496:	f04a                	sd	s2,32(sp)
    80004498:	ec4e                	sd	s3,24(sp)
    8000449a:	e852                	sd	s4,16(sp)
    8000449c:	e456                	sd	s5,8(sp)
    8000449e:	0080                	addi	s0,sp,64
    800044a0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800044a2:	0001d517          	auipc	a0,0x1d
    800044a6:	f1650513          	addi	a0,a0,-234 # 800213b8 <ftable>
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	72c080e7          	jalr	1836(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800044b2:	40dc                	lw	a5,4(s1)
    800044b4:	06f05163          	blez	a5,80004516 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044b8:	37fd                	addiw	a5,a5,-1
    800044ba:	0007871b          	sext.w	a4,a5
    800044be:	c0dc                	sw	a5,4(s1)
    800044c0:	06e04363          	bgtz	a4,80004526 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800044c4:	0004a903          	lw	s2,0(s1)
    800044c8:	0094ca83          	lbu	s5,9(s1)
    800044cc:	0104ba03          	ld	s4,16(s1)
    800044d0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800044d4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800044d8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800044dc:	0001d517          	auipc	a0,0x1d
    800044e0:	edc50513          	addi	a0,a0,-292 # 800213b8 <ftable>
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	7a6080e7          	jalr	1958(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800044ec:	4785                	li	a5,1
    800044ee:	04f90d63          	beq	s2,a5,80004548 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800044f2:	3979                	addiw	s2,s2,-2
    800044f4:	4785                	li	a5,1
    800044f6:	0527e063          	bltu	a5,s2,80004536 <fileclose+0xa8>
    begin_op();
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	ac8080e7          	jalr	-1336(ra) # 80003fc2 <begin_op>
    iput(ff.ip);
    80004502:	854e                	mv	a0,s3
    80004504:	fffff097          	auipc	ra,0xfffff
    80004508:	2a6080e7          	jalr	678(ra) # 800037aa <iput>
    end_op();
    8000450c:	00000097          	auipc	ra,0x0
    80004510:	b36080e7          	jalr	-1226(ra) # 80004042 <end_op>
    80004514:	a00d                	j	80004536 <fileclose+0xa8>
    panic("fileclose");
    80004516:	00004517          	auipc	a0,0x4
    8000451a:	16a50513          	addi	a0,a0,362 # 80008680 <syscalls+0x250>
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	012080e7          	jalr	18(ra) # 80000530 <panic>
    release(&ftable.lock);
    80004526:	0001d517          	auipc	a0,0x1d
    8000452a:	e9250513          	addi	a0,a0,-366 # 800213b8 <ftable>
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	75c080e7          	jalr	1884(ra) # 80000c8a <release>
  }
}
    80004536:	70e2                	ld	ra,56(sp)
    80004538:	7442                	ld	s0,48(sp)
    8000453a:	74a2                	ld	s1,40(sp)
    8000453c:	7902                	ld	s2,32(sp)
    8000453e:	69e2                	ld	s3,24(sp)
    80004540:	6a42                	ld	s4,16(sp)
    80004542:	6aa2                	ld	s5,8(sp)
    80004544:	6121                	addi	sp,sp,64
    80004546:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004548:	85d6                	mv	a1,s5
    8000454a:	8552                	mv	a0,s4
    8000454c:	00000097          	auipc	ra,0x0
    80004550:	34c080e7          	jalr	844(ra) # 80004898 <pipeclose>
    80004554:	b7cd                	j	80004536 <fileclose+0xa8>

0000000080004556 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004556:	715d                	addi	sp,sp,-80
    80004558:	e486                	sd	ra,72(sp)
    8000455a:	e0a2                	sd	s0,64(sp)
    8000455c:	fc26                	sd	s1,56(sp)
    8000455e:	f84a                	sd	s2,48(sp)
    80004560:	f44e                	sd	s3,40(sp)
    80004562:	0880                	addi	s0,sp,80
    80004564:	84aa                	mv	s1,a0
    80004566:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004568:	ffffd097          	auipc	ra,0xffffd
    8000456c:	42c080e7          	jalr	1068(ra) # 80001994 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004570:	409c                	lw	a5,0(s1)
    80004572:	37f9                	addiw	a5,a5,-2
    80004574:	4705                	li	a4,1
    80004576:	04f76763          	bltu	a4,a5,800045c4 <filestat+0x6e>
    8000457a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000457c:	6c88                	ld	a0,24(s1)
    8000457e:	fffff097          	auipc	ra,0xfffff
    80004582:	072080e7          	jalr	114(ra) # 800035f0 <ilock>
    stati(f->ip, &st);
    80004586:	fb840593          	addi	a1,s0,-72
    8000458a:	6c88                	ld	a0,24(s1)
    8000458c:	fffff097          	auipc	ra,0xfffff
    80004590:	2ee080e7          	jalr	750(ra) # 8000387a <stati>
    iunlock(f->ip);
    80004594:	6c88                	ld	a0,24(s1)
    80004596:	fffff097          	auipc	ra,0xfffff
    8000459a:	11c080e7          	jalr	284(ra) # 800036b2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000459e:	46e1                	li	a3,24
    800045a0:	fb840613          	addi	a2,s0,-72
    800045a4:	85ce                	mv	a1,s3
    800045a6:	05093503          	ld	a0,80(s2)
    800045aa:	ffffd097          	auipc	ra,0xffffd
    800045ae:	0ac080e7          	jalr	172(ra) # 80001656 <copyout>
    800045b2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045b6:	60a6                	ld	ra,72(sp)
    800045b8:	6406                	ld	s0,64(sp)
    800045ba:	74e2                	ld	s1,56(sp)
    800045bc:	7942                	ld	s2,48(sp)
    800045be:	79a2                	ld	s3,40(sp)
    800045c0:	6161                	addi	sp,sp,80
    800045c2:	8082                	ret
  return -1;
    800045c4:	557d                	li	a0,-1
    800045c6:	bfc5                	j	800045b6 <filestat+0x60>

00000000800045c8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800045c8:	7179                	addi	sp,sp,-48
    800045ca:	f406                	sd	ra,40(sp)
    800045cc:	f022                	sd	s0,32(sp)
    800045ce:	ec26                	sd	s1,24(sp)
    800045d0:	e84a                	sd	s2,16(sp)
    800045d2:	e44e                	sd	s3,8(sp)
    800045d4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800045d6:	00854783          	lbu	a5,8(a0)
    800045da:	c3d5                	beqz	a5,8000467e <fileread+0xb6>
    800045dc:	84aa                	mv	s1,a0
    800045de:	89ae                	mv	s3,a1
    800045e0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800045e2:	411c                	lw	a5,0(a0)
    800045e4:	4705                	li	a4,1
    800045e6:	04e78963          	beq	a5,a4,80004638 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800045ea:	470d                	li	a4,3
    800045ec:	04e78d63          	beq	a5,a4,80004646 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800045f0:	4709                	li	a4,2
    800045f2:	06e79e63          	bne	a5,a4,8000466e <fileread+0xa6>
    ilock(f->ip);
    800045f6:	6d08                	ld	a0,24(a0)
    800045f8:	fffff097          	auipc	ra,0xfffff
    800045fc:	ff8080e7          	jalr	-8(ra) # 800035f0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004600:	874a                	mv	a4,s2
    80004602:	5094                	lw	a3,32(s1)
    80004604:	864e                	mv	a2,s3
    80004606:	4585                	li	a1,1
    80004608:	6c88                	ld	a0,24(s1)
    8000460a:	fffff097          	auipc	ra,0xfffff
    8000460e:	29a080e7          	jalr	666(ra) # 800038a4 <readi>
    80004612:	892a                	mv	s2,a0
    80004614:	00a05563          	blez	a0,8000461e <fileread+0x56>
      f->off += r;
    80004618:	509c                	lw	a5,32(s1)
    8000461a:	9fa9                	addw	a5,a5,a0
    8000461c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000461e:	6c88                	ld	a0,24(s1)
    80004620:	fffff097          	auipc	ra,0xfffff
    80004624:	092080e7          	jalr	146(ra) # 800036b2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004628:	854a                	mv	a0,s2
    8000462a:	70a2                	ld	ra,40(sp)
    8000462c:	7402                	ld	s0,32(sp)
    8000462e:	64e2                	ld	s1,24(sp)
    80004630:	6942                	ld	s2,16(sp)
    80004632:	69a2                	ld	s3,8(sp)
    80004634:	6145                	addi	sp,sp,48
    80004636:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004638:	6908                	ld	a0,16(a0)
    8000463a:	00000097          	auipc	ra,0x0
    8000463e:	3c8080e7          	jalr	968(ra) # 80004a02 <piperead>
    80004642:	892a                	mv	s2,a0
    80004644:	b7d5                	j	80004628 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004646:	02451783          	lh	a5,36(a0)
    8000464a:	03079693          	slli	a3,a5,0x30
    8000464e:	92c1                	srli	a3,a3,0x30
    80004650:	4725                	li	a4,9
    80004652:	02d76863          	bltu	a4,a3,80004682 <fileread+0xba>
    80004656:	0792                	slli	a5,a5,0x4
    80004658:	0001d717          	auipc	a4,0x1d
    8000465c:	cc070713          	addi	a4,a4,-832 # 80021318 <devsw>
    80004660:	97ba                	add	a5,a5,a4
    80004662:	639c                	ld	a5,0(a5)
    80004664:	c38d                	beqz	a5,80004686 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004666:	4505                	li	a0,1
    80004668:	9782                	jalr	a5
    8000466a:	892a                	mv	s2,a0
    8000466c:	bf75                	j	80004628 <fileread+0x60>
    panic("fileread");
    8000466e:	00004517          	auipc	a0,0x4
    80004672:	02250513          	addi	a0,a0,34 # 80008690 <syscalls+0x260>
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	eba080e7          	jalr	-326(ra) # 80000530 <panic>
    return -1;
    8000467e:	597d                	li	s2,-1
    80004680:	b765                	j	80004628 <fileread+0x60>
      return -1;
    80004682:	597d                	li	s2,-1
    80004684:	b755                	j	80004628 <fileread+0x60>
    80004686:	597d                	li	s2,-1
    80004688:	b745                	j	80004628 <fileread+0x60>

000000008000468a <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000468a:	715d                	addi	sp,sp,-80
    8000468c:	e486                	sd	ra,72(sp)
    8000468e:	e0a2                	sd	s0,64(sp)
    80004690:	fc26                	sd	s1,56(sp)
    80004692:	f84a                	sd	s2,48(sp)
    80004694:	f44e                	sd	s3,40(sp)
    80004696:	f052                	sd	s4,32(sp)
    80004698:	ec56                	sd	s5,24(sp)
    8000469a:	e85a                	sd	s6,16(sp)
    8000469c:	e45e                	sd	s7,8(sp)
    8000469e:	e062                	sd	s8,0(sp)
    800046a0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800046a2:	00954783          	lbu	a5,9(a0)
    800046a6:	10078663          	beqz	a5,800047b2 <filewrite+0x128>
    800046aa:	892a                	mv	s2,a0
    800046ac:	8aae                	mv	s5,a1
    800046ae:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800046b0:	411c                	lw	a5,0(a0)
    800046b2:	4705                	li	a4,1
    800046b4:	02e78263          	beq	a5,a4,800046d8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046b8:	470d                	li	a4,3
    800046ba:	02e78663          	beq	a5,a4,800046e6 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800046be:	4709                	li	a4,2
    800046c0:	0ee79163          	bne	a5,a4,800047a2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800046c4:	0ac05d63          	blez	a2,8000477e <filewrite+0xf4>
    int i = 0;
    800046c8:	4981                	li	s3,0
    800046ca:	6b05                	lui	s6,0x1
    800046cc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800046d0:	6b85                	lui	s7,0x1
    800046d2:	c00b8b9b          	addiw	s7,s7,-1024
    800046d6:	a861                	j	8000476e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800046d8:	6908                	ld	a0,16(a0)
    800046da:	00000097          	auipc	ra,0x0
    800046de:	22e080e7          	jalr	558(ra) # 80004908 <pipewrite>
    800046e2:	8a2a                	mv	s4,a0
    800046e4:	a045                	j	80004784 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800046e6:	02451783          	lh	a5,36(a0)
    800046ea:	03079693          	slli	a3,a5,0x30
    800046ee:	92c1                	srli	a3,a3,0x30
    800046f0:	4725                	li	a4,9
    800046f2:	0cd76263          	bltu	a4,a3,800047b6 <filewrite+0x12c>
    800046f6:	0792                	slli	a5,a5,0x4
    800046f8:	0001d717          	auipc	a4,0x1d
    800046fc:	c2070713          	addi	a4,a4,-992 # 80021318 <devsw>
    80004700:	97ba                	add	a5,a5,a4
    80004702:	679c                	ld	a5,8(a5)
    80004704:	cbdd                	beqz	a5,800047ba <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004706:	4505                	li	a0,1
    80004708:	9782                	jalr	a5
    8000470a:	8a2a                	mv	s4,a0
    8000470c:	a8a5                	j	80004784 <filewrite+0xfa>
    8000470e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004712:	00000097          	auipc	ra,0x0
    80004716:	8b0080e7          	jalr	-1872(ra) # 80003fc2 <begin_op>
      ilock(f->ip);
    8000471a:	01893503          	ld	a0,24(s2)
    8000471e:	fffff097          	auipc	ra,0xfffff
    80004722:	ed2080e7          	jalr	-302(ra) # 800035f0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004726:	8762                	mv	a4,s8
    80004728:	02092683          	lw	a3,32(s2)
    8000472c:	01598633          	add	a2,s3,s5
    80004730:	4585                	li	a1,1
    80004732:	01893503          	ld	a0,24(s2)
    80004736:	fffff097          	auipc	ra,0xfffff
    8000473a:	266080e7          	jalr	614(ra) # 8000399c <writei>
    8000473e:	84aa                	mv	s1,a0
    80004740:	00a05763          	blez	a0,8000474e <filewrite+0xc4>
        f->off += r;
    80004744:	02092783          	lw	a5,32(s2)
    80004748:	9fa9                	addw	a5,a5,a0
    8000474a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000474e:	01893503          	ld	a0,24(s2)
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	f60080e7          	jalr	-160(ra) # 800036b2 <iunlock>
      end_op();
    8000475a:	00000097          	auipc	ra,0x0
    8000475e:	8e8080e7          	jalr	-1816(ra) # 80004042 <end_op>

      if(r != n1){
    80004762:	009c1f63          	bne	s8,s1,80004780 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004766:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000476a:	0149db63          	bge	s3,s4,80004780 <filewrite+0xf6>
      int n1 = n - i;
    8000476e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004772:	84be                	mv	s1,a5
    80004774:	2781                	sext.w	a5,a5
    80004776:	f8fb5ce3          	bge	s6,a5,8000470e <filewrite+0x84>
    8000477a:	84de                	mv	s1,s7
    8000477c:	bf49                	j	8000470e <filewrite+0x84>
    int i = 0;
    8000477e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004780:	013a1f63          	bne	s4,s3,8000479e <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004784:	8552                	mv	a0,s4
    80004786:	60a6                	ld	ra,72(sp)
    80004788:	6406                	ld	s0,64(sp)
    8000478a:	74e2                	ld	s1,56(sp)
    8000478c:	7942                	ld	s2,48(sp)
    8000478e:	79a2                	ld	s3,40(sp)
    80004790:	7a02                	ld	s4,32(sp)
    80004792:	6ae2                	ld	s5,24(sp)
    80004794:	6b42                	ld	s6,16(sp)
    80004796:	6ba2                	ld	s7,8(sp)
    80004798:	6c02                	ld	s8,0(sp)
    8000479a:	6161                	addi	sp,sp,80
    8000479c:	8082                	ret
    ret = (i == n ? n : -1);
    8000479e:	5a7d                	li	s4,-1
    800047a0:	b7d5                	j	80004784 <filewrite+0xfa>
    panic("filewrite");
    800047a2:	00004517          	auipc	a0,0x4
    800047a6:	efe50513          	addi	a0,a0,-258 # 800086a0 <syscalls+0x270>
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	d86080e7          	jalr	-634(ra) # 80000530 <panic>
    return -1;
    800047b2:	5a7d                	li	s4,-1
    800047b4:	bfc1                	j	80004784 <filewrite+0xfa>
      return -1;
    800047b6:	5a7d                	li	s4,-1
    800047b8:	b7f1                	j	80004784 <filewrite+0xfa>
    800047ba:	5a7d                	li	s4,-1
    800047bc:	b7e1                	j	80004784 <filewrite+0xfa>

00000000800047be <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800047be:	7179                	addi	sp,sp,-48
    800047c0:	f406                	sd	ra,40(sp)
    800047c2:	f022                	sd	s0,32(sp)
    800047c4:	ec26                	sd	s1,24(sp)
    800047c6:	e84a                	sd	s2,16(sp)
    800047c8:	e44e                	sd	s3,8(sp)
    800047ca:	e052                	sd	s4,0(sp)
    800047cc:	1800                	addi	s0,sp,48
    800047ce:	84aa                	mv	s1,a0
    800047d0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800047d2:	0005b023          	sd	zero,0(a1)
    800047d6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800047da:	00000097          	auipc	ra,0x0
    800047de:	bf8080e7          	jalr	-1032(ra) # 800043d2 <filealloc>
    800047e2:	e088                	sd	a0,0(s1)
    800047e4:	c551                	beqz	a0,80004870 <pipealloc+0xb2>
    800047e6:	00000097          	auipc	ra,0x0
    800047ea:	bec080e7          	jalr	-1044(ra) # 800043d2 <filealloc>
    800047ee:	00aa3023          	sd	a0,0(s4)
    800047f2:	c92d                	beqz	a0,80004864 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	2f2080e7          	jalr	754(ra) # 80000ae6 <kalloc>
    800047fc:	892a                	mv	s2,a0
    800047fe:	c125                	beqz	a0,8000485e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004800:	4985                	li	s3,1
    80004802:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004806:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000480a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000480e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004812:	00004597          	auipc	a1,0x4
    80004816:	e9e58593          	addi	a1,a1,-354 # 800086b0 <syscalls+0x280>
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	32c080e7          	jalr	812(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004822:	609c                	ld	a5,0(s1)
    80004824:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004828:	609c                	ld	a5,0(s1)
    8000482a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000482e:	609c                	ld	a5,0(s1)
    80004830:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004834:	609c                	ld	a5,0(s1)
    80004836:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000483a:	000a3783          	ld	a5,0(s4)
    8000483e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004842:	000a3783          	ld	a5,0(s4)
    80004846:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000484a:	000a3783          	ld	a5,0(s4)
    8000484e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004852:	000a3783          	ld	a5,0(s4)
    80004856:	0127b823          	sd	s2,16(a5)
  return 0;
    8000485a:	4501                	li	a0,0
    8000485c:	a025                	j	80004884 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000485e:	6088                	ld	a0,0(s1)
    80004860:	e501                	bnez	a0,80004868 <pipealloc+0xaa>
    80004862:	a039                	j	80004870 <pipealloc+0xb2>
    80004864:	6088                	ld	a0,0(s1)
    80004866:	c51d                	beqz	a0,80004894 <pipealloc+0xd6>
    fileclose(*f0);
    80004868:	00000097          	auipc	ra,0x0
    8000486c:	c26080e7          	jalr	-986(ra) # 8000448e <fileclose>
  if(*f1)
    80004870:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004874:	557d                	li	a0,-1
  if(*f1)
    80004876:	c799                	beqz	a5,80004884 <pipealloc+0xc6>
    fileclose(*f1);
    80004878:	853e                	mv	a0,a5
    8000487a:	00000097          	auipc	ra,0x0
    8000487e:	c14080e7          	jalr	-1004(ra) # 8000448e <fileclose>
  return -1;
    80004882:	557d                	li	a0,-1
}
    80004884:	70a2                	ld	ra,40(sp)
    80004886:	7402                	ld	s0,32(sp)
    80004888:	64e2                	ld	s1,24(sp)
    8000488a:	6942                	ld	s2,16(sp)
    8000488c:	69a2                	ld	s3,8(sp)
    8000488e:	6a02                	ld	s4,0(sp)
    80004890:	6145                	addi	sp,sp,48
    80004892:	8082                	ret
  return -1;
    80004894:	557d                	li	a0,-1
    80004896:	b7fd                	j	80004884 <pipealloc+0xc6>

0000000080004898 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004898:	1101                	addi	sp,sp,-32
    8000489a:	ec06                	sd	ra,24(sp)
    8000489c:	e822                	sd	s0,16(sp)
    8000489e:	e426                	sd	s1,8(sp)
    800048a0:	e04a                	sd	s2,0(sp)
    800048a2:	1000                	addi	s0,sp,32
    800048a4:	84aa                	mv	s1,a0
    800048a6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	32e080e7          	jalr	814(ra) # 80000bd6 <acquire>
  if(writable){
    800048b0:	02090d63          	beqz	s2,800048ea <pipeclose+0x52>
    pi->writeopen = 0;
    800048b4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800048b8:	21848513          	addi	a0,s1,536
    800048bc:	ffffe097          	auipc	ra,0xffffe
    800048c0:	920080e7          	jalr	-1760(ra) # 800021dc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800048c4:	2204b783          	ld	a5,544(s1)
    800048c8:	eb95                	bnez	a5,800048fc <pipeclose+0x64>
    release(&pi->lock);
    800048ca:	8526                	mv	a0,s1
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	3be080e7          	jalr	958(ra) # 80000c8a <release>
    kfree((char*)pi);
    800048d4:	8526                	mv	a0,s1
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	114080e7          	jalr	276(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    800048de:	60e2                	ld	ra,24(sp)
    800048e0:	6442                	ld	s0,16(sp)
    800048e2:	64a2                	ld	s1,8(sp)
    800048e4:	6902                	ld	s2,0(sp)
    800048e6:	6105                	addi	sp,sp,32
    800048e8:	8082                	ret
    pi->readopen = 0;
    800048ea:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800048ee:	21c48513          	addi	a0,s1,540
    800048f2:	ffffe097          	auipc	ra,0xffffe
    800048f6:	8ea080e7          	jalr	-1814(ra) # 800021dc <wakeup>
    800048fa:	b7e9                	j	800048c4 <pipeclose+0x2c>
    release(&pi->lock);
    800048fc:	8526                	mv	a0,s1
    800048fe:	ffffc097          	auipc	ra,0xffffc
    80004902:	38c080e7          	jalr	908(ra) # 80000c8a <release>
}
    80004906:	bfe1                	j	800048de <pipeclose+0x46>

0000000080004908 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004908:	7159                	addi	sp,sp,-112
    8000490a:	f486                	sd	ra,104(sp)
    8000490c:	f0a2                	sd	s0,96(sp)
    8000490e:	eca6                	sd	s1,88(sp)
    80004910:	e8ca                	sd	s2,80(sp)
    80004912:	e4ce                	sd	s3,72(sp)
    80004914:	e0d2                	sd	s4,64(sp)
    80004916:	fc56                	sd	s5,56(sp)
    80004918:	f85a                	sd	s6,48(sp)
    8000491a:	f45e                	sd	s7,40(sp)
    8000491c:	f062                	sd	s8,32(sp)
    8000491e:	ec66                	sd	s9,24(sp)
    80004920:	1880                	addi	s0,sp,112
    80004922:	84aa                	mv	s1,a0
    80004924:	8aae                	mv	s5,a1
    80004926:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004928:	ffffd097          	auipc	ra,0xffffd
    8000492c:	06c080e7          	jalr	108(ra) # 80001994 <myproc>
    80004930:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004932:	8526                	mv	a0,s1
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	2a2080e7          	jalr	674(ra) # 80000bd6 <acquire>
  while(i < n){
    8000493c:	0d405163          	blez	s4,800049fe <pipewrite+0xf6>
    80004940:	8ba6                	mv	s7,s1
  int i = 0;
    80004942:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004944:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004946:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000494a:	21c48c13          	addi	s8,s1,540
    8000494e:	a08d                	j	800049b0 <pipewrite+0xa8>
      release(&pi->lock);
    80004950:	8526                	mv	a0,s1
    80004952:	ffffc097          	auipc	ra,0xffffc
    80004956:	338080e7          	jalr	824(ra) # 80000c8a <release>
      return -1;
    8000495a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000495c:	854a                	mv	a0,s2
    8000495e:	70a6                	ld	ra,104(sp)
    80004960:	7406                	ld	s0,96(sp)
    80004962:	64e6                	ld	s1,88(sp)
    80004964:	6946                	ld	s2,80(sp)
    80004966:	69a6                	ld	s3,72(sp)
    80004968:	6a06                	ld	s4,64(sp)
    8000496a:	7ae2                	ld	s5,56(sp)
    8000496c:	7b42                	ld	s6,48(sp)
    8000496e:	7ba2                	ld	s7,40(sp)
    80004970:	7c02                	ld	s8,32(sp)
    80004972:	6ce2                	ld	s9,24(sp)
    80004974:	6165                	addi	sp,sp,112
    80004976:	8082                	ret
      wakeup(&pi->nread);
    80004978:	8566                	mv	a0,s9
    8000497a:	ffffe097          	auipc	ra,0xffffe
    8000497e:	862080e7          	jalr	-1950(ra) # 800021dc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004982:	85de                	mv	a1,s7
    80004984:	8562                	mv	a0,s8
    80004986:	ffffd097          	auipc	ra,0xffffd
    8000498a:	6ca080e7          	jalr	1738(ra) # 80002050 <sleep>
    8000498e:	a839                	j	800049ac <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004990:	21c4a783          	lw	a5,540(s1)
    80004994:	0017871b          	addiw	a4,a5,1
    80004998:	20e4ae23          	sw	a4,540(s1)
    8000499c:	1ff7f793          	andi	a5,a5,511
    800049a0:	97a6                	add	a5,a5,s1
    800049a2:	f9f44703          	lbu	a4,-97(s0)
    800049a6:	00e78c23          	sb	a4,24(a5)
      i++;
    800049aa:	2905                	addiw	s2,s2,1
  while(i < n){
    800049ac:	03495d63          	bge	s2,s4,800049e6 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    800049b0:	2204a783          	lw	a5,544(s1)
    800049b4:	dfd1                	beqz	a5,80004950 <pipewrite+0x48>
    800049b6:	0289a783          	lw	a5,40(s3)
    800049ba:	fbd9                	bnez	a5,80004950 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800049bc:	2184a783          	lw	a5,536(s1)
    800049c0:	21c4a703          	lw	a4,540(s1)
    800049c4:	2007879b          	addiw	a5,a5,512
    800049c8:	faf708e3          	beq	a4,a5,80004978 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049cc:	4685                	li	a3,1
    800049ce:	01590633          	add	a2,s2,s5
    800049d2:	f9f40593          	addi	a1,s0,-97
    800049d6:	0509b503          	ld	a0,80(s3)
    800049da:	ffffd097          	auipc	ra,0xffffd
    800049de:	d08080e7          	jalr	-760(ra) # 800016e2 <copyin>
    800049e2:	fb6517e3          	bne	a0,s6,80004990 <pipewrite+0x88>
  wakeup(&pi->nread);
    800049e6:	21848513          	addi	a0,s1,536
    800049ea:	ffffd097          	auipc	ra,0xffffd
    800049ee:	7f2080e7          	jalr	2034(ra) # 800021dc <wakeup>
  release(&pi->lock);
    800049f2:	8526                	mv	a0,s1
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	296080e7          	jalr	662(ra) # 80000c8a <release>
  return i;
    800049fc:	b785                	j	8000495c <pipewrite+0x54>
  int i = 0;
    800049fe:	4901                	li	s2,0
    80004a00:	b7dd                	j	800049e6 <pipewrite+0xde>

0000000080004a02 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a02:	715d                	addi	sp,sp,-80
    80004a04:	e486                	sd	ra,72(sp)
    80004a06:	e0a2                	sd	s0,64(sp)
    80004a08:	fc26                	sd	s1,56(sp)
    80004a0a:	f84a                	sd	s2,48(sp)
    80004a0c:	f44e                	sd	s3,40(sp)
    80004a0e:	f052                	sd	s4,32(sp)
    80004a10:	ec56                	sd	s5,24(sp)
    80004a12:	e85a                	sd	s6,16(sp)
    80004a14:	0880                	addi	s0,sp,80
    80004a16:	84aa                	mv	s1,a0
    80004a18:	892e                	mv	s2,a1
    80004a1a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a1c:	ffffd097          	auipc	ra,0xffffd
    80004a20:	f78080e7          	jalr	-136(ra) # 80001994 <myproc>
    80004a24:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a26:	8b26                	mv	s6,s1
    80004a28:	8526                	mv	a0,s1
    80004a2a:	ffffc097          	auipc	ra,0xffffc
    80004a2e:	1ac080e7          	jalr	428(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a32:	2184a703          	lw	a4,536(s1)
    80004a36:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a3a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a3e:	02f71463          	bne	a4,a5,80004a66 <piperead+0x64>
    80004a42:	2244a783          	lw	a5,548(s1)
    80004a46:	c385                	beqz	a5,80004a66 <piperead+0x64>
    if(pr->killed){
    80004a48:	028a2783          	lw	a5,40(s4)
    80004a4c:	ebc1                	bnez	a5,80004adc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004a4e:	85da                	mv	a1,s6
    80004a50:	854e                	mv	a0,s3
    80004a52:	ffffd097          	auipc	ra,0xffffd
    80004a56:	5fe080e7          	jalr	1534(ra) # 80002050 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004a5a:	2184a703          	lw	a4,536(s1)
    80004a5e:	21c4a783          	lw	a5,540(s1)
    80004a62:	fef700e3          	beq	a4,a5,80004a42 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004a66:	09505263          	blez	s5,80004aea <piperead+0xe8>
    80004a6a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a6c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004a6e:	2184a783          	lw	a5,536(s1)
    80004a72:	21c4a703          	lw	a4,540(s1)
    80004a76:	02f70d63          	beq	a4,a5,80004ab0 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004a7a:	0017871b          	addiw	a4,a5,1
    80004a7e:	20e4ac23          	sw	a4,536(s1)
    80004a82:	1ff7f793          	andi	a5,a5,511
    80004a86:	97a6                	add	a5,a5,s1
    80004a88:	0187c783          	lbu	a5,24(a5)
    80004a8c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004a90:	4685                	li	a3,1
    80004a92:	fbf40613          	addi	a2,s0,-65
    80004a96:	85ca                	mv	a1,s2
    80004a98:	050a3503          	ld	a0,80(s4)
    80004a9c:	ffffd097          	auipc	ra,0xffffd
    80004aa0:	bba080e7          	jalr	-1094(ra) # 80001656 <copyout>
    80004aa4:	01650663          	beq	a0,s6,80004ab0 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aa8:	2985                	addiw	s3,s3,1
    80004aaa:	0905                	addi	s2,s2,1
    80004aac:	fd3a91e3          	bne	s5,s3,80004a6e <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ab0:	21c48513          	addi	a0,s1,540
    80004ab4:	ffffd097          	auipc	ra,0xffffd
    80004ab8:	728080e7          	jalr	1832(ra) # 800021dc <wakeup>
  release(&pi->lock);
    80004abc:	8526                	mv	a0,s1
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	1cc080e7          	jalr	460(ra) # 80000c8a <release>
  return i;
}
    80004ac6:	854e                	mv	a0,s3
    80004ac8:	60a6                	ld	ra,72(sp)
    80004aca:	6406                	ld	s0,64(sp)
    80004acc:	74e2                	ld	s1,56(sp)
    80004ace:	7942                	ld	s2,48(sp)
    80004ad0:	79a2                	ld	s3,40(sp)
    80004ad2:	7a02                	ld	s4,32(sp)
    80004ad4:	6ae2                	ld	s5,24(sp)
    80004ad6:	6b42                	ld	s6,16(sp)
    80004ad8:	6161                	addi	sp,sp,80
    80004ada:	8082                	ret
      release(&pi->lock);
    80004adc:	8526                	mv	a0,s1
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	1ac080e7          	jalr	428(ra) # 80000c8a <release>
      return -1;
    80004ae6:	59fd                	li	s3,-1
    80004ae8:	bff9                	j	80004ac6 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004aea:	4981                	li	s3,0
    80004aec:	b7d1                	j	80004ab0 <piperead+0xae>

0000000080004aee <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004aee:	df010113          	addi	sp,sp,-528
    80004af2:	20113423          	sd	ra,520(sp)
    80004af6:	20813023          	sd	s0,512(sp)
    80004afa:	ffa6                	sd	s1,504(sp)
    80004afc:	fbca                	sd	s2,496(sp)
    80004afe:	f7ce                	sd	s3,488(sp)
    80004b00:	f3d2                	sd	s4,480(sp)
    80004b02:	efd6                	sd	s5,472(sp)
    80004b04:	ebda                	sd	s6,464(sp)
    80004b06:	e7de                	sd	s7,456(sp)
    80004b08:	e3e2                	sd	s8,448(sp)
    80004b0a:	ff66                	sd	s9,440(sp)
    80004b0c:	fb6a                	sd	s10,432(sp)
    80004b0e:	f76e                	sd	s11,424(sp)
    80004b10:	0c00                	addi	s0,sp,528
    80004b12:	84aa                	mv	s1,a0
    80004b14:	dea43c23          	sd	a0,-520(s0)
    80004b18:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004b1c:	ffffd097          	auipc	ra,0xffffd
    80004b20:	e78080e7          	jalr	-392(ra) # 80001994 <myproc>
    80004b24:	892a                	mv	s2,a0

  begin_op();
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	49c080e7          	jalr	1180(ra) # 80003fc2 <begin_op>

  if((ip = namei(path)) == 0){
    80004b2e:	8526                	mv	a0,s1
    80004b30:	fffff097          	auipc	ra,0xfffff
    80004b34:	276080e7          	jalr	630(ra) # 80003da6 <namei>
    80004b38:	c92d                	beqz	a0,80004baa <exec+0xbc>
    80004b3a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004b3c:	fffff097          	auipc	ra,0xfffff
    80004b40:	ab4080e7          	jalr	-1356(ra) # 800035f0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004b44:	04000713          	li	a4,64
    80004b48:	4681                	li	a3,0
    80004b4a:	e4840613          	addi	a2,s0,-440
    80004b4e:	4581                	li	a1,0
    80004b50:	8526                	mv	a0,s1
    80004b52:	fffff097          	auipc	ra,0xfffff
    80004b56:	d52080e7          	jalr	-686(ra) # 800038a4 <readi>
    80004b5a:	04000793          	li	a5,64
    80004b5e:	00f51a63          	bne	a0,a5,80004b72 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004b62:	e4842703          	lw	a4,-440(s0)
    80004b66:	464c47b7          	lui	a5,0x464c4
    80004b6a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004b6e:	04f70463          	beq	a4,a5,80004bb6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004b72:	8526                	mv	a0,s1
    80004b74:	fffff097          	auipc	ra,0xfffff
    80004b78:	cde080e7          	jalr	-802(ra) # 80003852 <iunlockput>
    end_op();
    80004b7c:	fffff097          	auipc	ra,0xfffff
    80004b80:	4c6080e7          	jalr	1222(ra) # 80004042 <end_op>
  }
  return -1;
    80004b84:	557d                	li	a0,-1
}
    80004b86:	20813083          	ld	ra,520(sp)
    80004b8a:	20013403          	ld	s0,512(sp)
    80004b8e:	74fe                	ld	s1,504(sp)
    80004b90:	795e                	ld	s2,496(sp)
    80004b92:	79be                	ld	s3,488(sp)
    80004b94:	7a1e                	ld	s4,480(sp)
    80004b96:	6afe                	ld	s5,472(sp)
    80004b98:	6b5e                	ld	s6,464(sp)
    80004b9a:	6bbe                	ld	s7,456(sp)
    80004b9c:	6c1e                	ld	s8,448(sp)
    80004b9e:	7cfa                	ld	s9,440(sp)
    80004ba0:	7d5a                	ld	s10,432(sp)
    80004ba2:	7dba                	ld	s11,424(sp)
    80004ba4:	21010113          	addi	sp,sp,528
    80004ba8:	8082                	ret
    end_op();
    80004baa:	fffff097          	auipc	ra,0xfffff
    80004bae:	498080e7          	jalr	1176(ra) # 80004042 <end_op>
    return -1;
    80004bb2:	557d                	li	a0,-1
    80004bb4:	bfc9                	j	80004b86 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004bb6:	854a                	mv	a0,s2
    80004bb8:	ffffd097          	auipc	ra,0xffffd
    80004bbc:	ea0080e7          	jalr	-352(ra) # 80001a58 <proc_pagetable>
    80004bc0:	8baa                	mv	s7,a0
    80004bc2:	d945                	beqz	a0,80004b72 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bc4:	e6842983          	lw	s3,-408(s0)
    80004bc8:	e8045783          	lhu	a5,-384(s0)
    80004bcc:	c7ad                	beqz	a5,80004c36 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004bce:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004bd0:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004bd2:	6c85                	lui	s9,0x1
    80004bd4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004bd8:	def43823          	sd	a5,-528(s0)
    80004bdc:	a42d                	j	80004e06 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004bde:	00004517          	auipc	a0,0x4
    80004be2:	ada50513          	addi	a0,a0,-1318 # 800086b8 <syscalls+0x288>
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	94a080e7          	jalr	-1718(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004bee:	8756                	mv	a4,s5
    80004bf0:	012d86bb          	addw	a3,s11,s2
    80004bf4:	4581                	li	a1,0
    80004bf6:	8526                	mv	a0,s1
    80004bf8:	fffff097          	auipc	ra,0xfffff
    80004bfc:	cac080e7          	jalr	-852(ra) # 800038a4 <readi>
    80004c00:	2501                	sext.w	a0,a0
    80004c02:	1aaa9963          	bne	s5,a0,80004db4 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004c06:	6785                	lui	a5,0x1
    80004c08:	0127893b          	addw	s2,a5,s2
    80004c0c:	77fd                	lui	a5,0xfffff
    80004c0e:	01478a3b          	addw	s4,a5,s4
    80004c12:	1f897163          	bgeu	s2,s8,80004df4 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004c16:	02091593          	slli	a1,s2,0x20
    80004c1a:	9181                	srli	a1,a1,0x20
    80004c1c:	95ea                	add	a1,a1,s10
    80004c1e:	855e                	mv	a0,s7
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	444080e7          	jalr	1092(ra) # 80001064 <walkaddr>
    80004c28:	862a                	mv	a2,a0
    if(pa == 0)
    80004c2a:	d955                	beqz	a0,80004bde <exec+0xf0>
      n = PGSIZE;
    80004c2c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004c2e:	fd9a70e3          	bgeu	s4,s9,80004bee <exec+0x100>
      n = sz - i;
    80004c32:	8ad2                	mv	s5,s4
    80004c34:	bf6d                	j	80004bee <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004c36:	4901                	li	s2,0
  iunlockput(ip);
    80004c38:	8526                	mv	a0,s1
    80004c3a:	fffff097          	auipc	ra,0xfffff
    80004c3e:	c18080e7          	jalr	-1000(ra) # 80003852 <iunlockput>
  end_op();
    80004c42:	fffff097          	auipc	ra,0xfffff
    80004c46:	400080e7          	jalr	1024(ra) # 80004042 <end_op>
  p = myproc();
    80004c4a:	ffffd097          	auipc	ra,0xffffd
    80004c4e:	d4a080e7          	jalr	-694(ra) # 80001994 <myproc>
    80004c52:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004c54:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004c58:	6785                	lui	a5,0x1
    80004c5a:	17fd                	addi	a5,a5,-1
    80004c5c:	993e                	add	s2,s2,a5
    80004c5e:	757d                	lui	a0,0xfffff
    80004c60:	00a977b3          	and	a5,s2,a0
    80004c64:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c68:	6609                	lui	a2,0x2
    80004c6a:	963e                	add	a2,a2,a5
    80004c6c:	85be                	mv	a1,a5
    80004c6e:	855e                	mv	a0,s7
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	796080e7          	jalr	1942(ra) # 80001406 <uvmalloc>
    80004c78:	8b2a                	mv	s6,a0
  ip = 0;
    80004c7a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004c7c:	12050c63          	beqz	a0,80004db4 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004c80:	75f9                	lui	a1,0xffffe
    80004c82:	95aa                	add	a1,a1,a0
    80004c84:	855e                	mv	a0,s7
    80004c86:	ffffd097          	auipc	ra,0xffffd
    80004c8a:	99e080e7          	jalr	-1634(ra) # 80001624 <uvmclear>
  stackbase = sp - PGSIZE;
    80004c8e:	7c7d                	lui	s8,0xfffff
    80004c90:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004c92:	e0043783          	ld	a5,-512(s0)
    80004c96:	6388                	ld	a0,0(a5)
    80004c98:	c535                	beqz	a0,80004d04 <exec+0x216>
    80004c9a:	e8840993          	addi	s3,s0,-376
    80004c9e:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004ca2:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	1b6080e7          	jalr	438(ra) # 80000e5a <strlen>
    80004cac:	2505                	addiw	a0,a0,1
    80004cae:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004cb2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004cb6:	13896363          	bltu	s2,s8,80004ddc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004cba:	e0043d83          	ld	s11,-512(s0)
    80004cbe:	000dba03          	ld	s4,0(s11)
    80004cc2:	8552                	mv	a0,s4
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	196080e7          	jalr	406(ra) # 80000e5a <strlen>
    80004ccc:	0015069b          	addiw	a3,a0,1
    80004cd0:	8652                	mv	a2,s4
    80004cd2:	85ca                	mv	a1,s2
    80004cd4:	855e                	mv	a0,s7
    80004cd6:	ffffd097          	auipc	ra,0xffffd
    80004cda:	980080e7          	jalr	-1664(ra) # 80001656 <copyout>
    80004cde:	10054363          	bltz	a0,80004de4 <exec+0x2f6>
    ustack[argc] = sp;
    80004ce2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ce6:	0485                	addi	s1,s1,1
    80004ce8:	008d8793          	addi	a5,s11,8
    80004cec:	e0f43023          	sd	a5,-512(s0)
    80004cf0:	008db503          	ld	a0,8(s11)
    80004cf4:	c911                	beqz	a0,80004d08 <exec+0x21a>
    if(argc >= MAXARG)
    80004cf6:	09a1                	addi	s3,s3,8
    80004cf8:	fb3c96e3          	bne	s9,s3,80004ca4 <exec+0x1b6>
  sz = sz1;
    80004cfc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d00:	4481                	li	s1,0
    80004d02:	a84d                	j	80004db4 <exec+0x2c6>
  sp = sz;
    80004d04:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004d06:	4481                	li	s1,0
  ustack[argc] = 0;
    80004d08:	00349793          	slli	a5,s1,0x3
    80004d0c:	f9040713          	addi	a4,s0,-112
    80004d10:	97ba                	add	a5,a5,a4
    80004d12:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004d16:	00148693          	addi	a3,s1,1
    80004d1a:	068e                	slli	a3,a3,0x3
    80004d1c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004d20:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004d24:	01897663          	bgeu	s2,s8,80004d30 <exec+0x242>
  sz = sz1;
    80004d28:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004d2c:	4481                	li	s1,0
    80004d2e:	a059                	j	80004db4 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004d30:	e8840613          	addi	a2,s0,-376
    80004d34:	85ca                	mv	a1,s2
    80004d36:	855e                	mv	a0,s7
    80004d38:	ffffd097          	auipc	ra,0xffffd
    80004d3c:	91e080e7          	jalr	-1762(ra) # 80001656 <copyout>
    80004d40:	0a054663          	bltz	a0,80004dec <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004d44:	058ab783          	ld	a5,88(s5)
    80004d48:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004d4c:	df843783          	ld	a5,-520(s0)
    80004d50:	0007c703          	lbu	a4,0(a5)
    80004d54:	cf11                	beqz	a4,80004d70 <exec+0x282>
    80004d56:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004d58:	02f00693          	li	a3,47
    80004d5c:	a029                	j	80004d66 <exec+0x278>
  for(last=s=path; *s; s++)
    80004d5e:	0785                	addi	a5,a5,1
    80004d60:	fff7c703          	lbu	a4,-1(a5)
    80004d64:	c711                	beqz	a4,80004d70 <exec+0x282>
    if(*s == '/')
    80004d66:	fed71ce3          	bne	a4,a3,80004d5e <exec+0x270>
      last = s+1;
    80004d6a:	def43c23          	sd	a5,-520(s0)
    80004d6e:	bfc5                	j	80004d5e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004d70:	4641                	li	a2,16
    80004d72:	df843583          	ld	a1,-520(s0)
    80004d76:	158a8513          	addi	a0,s5,344
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	0ae080e7          	jalr	174(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    80004d82:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004d86:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004d8a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004d8e:	058ab783          	ld	a5,88(s5)
    80004d92:	e6043703          	ld	a4,-416(s0)
    80004d96:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004d98:	058ab783          	ld	a5,88(s5)
    80004d9c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004da0:	85ea                	mv	a1,s10
    80004da2:	ffffd097          	auipc	ra,0xffffd
    80004da6:	d52080e7          	jalr	-686(ra) # 80001af4 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004daa:	0004851b          	sext.w	a0,s1
    80004dae:	bbe1                	j	80004b86 <exec+0x98>
    80004db0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004db4:	e0843583          	ld	a1,-504(s0)
    80004db8:	855e                	mv	a0,s7
    80004dba:	ffffd097          	auipc	ra,0xffffd
    80004dbe:	d3a080e7          	jalr	-710(ra) # 80001af4 <proc_freepagetable>
  if(ip){
    80004dc2:	da0498e3          	bnez	s1,80004b72 <exec+0x84>
  return -1;
    80004dc6:	557d                	li	a0,-1
    80004dc8:	bb7d                	j	80004b86 <exec+0x98>
    80004dca:	e1243423          	sd	s2,-504(s0)
    80004dce:	b7dd                	j	80004db4 <exec+0x2c6>
    80004dd0:	e1243423          	sd	s2,-504(s0)
    80004dd4:	b7c5                	j	80004db4 <exec+0x2c6>
    80004dd6:	e1243423          	sd	s2,-504(s0)
    80004dda:	bfe9                	j	80004db4 <exec+0x2c6>
  sz = sz1;
    80004ddc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004de0:	4481                	li	s1,0
    80004de2:	bfc9                	j	80004db4 <exec+0x2c6>
  sz = sz1;
    80004de4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004de8:	4481                	li	s1,0
    80004dea:	b7e9                	j	80004db4 <exec+0x2c6>
  sz = sz1;
    80004dec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004df0:	4481                	li	s1,0
    80004df2:	b7c9                	j	80004db4 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004df4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004df8:	2b05                	addiw	s6,s6,1
    80004dfa:	0389899b          	addiw	s3,s3,56
    80004dfe:	e8045783          	lhu	a5,-384(s0)
    80004e02:	e2fb5be3          	bge	s6,a5,80004c38 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004e06:	2981                	sext.w	s3,s3
    80004e08:	03800713          	li	a4,56
    80004e0c:	86ce                	mv	a3,s3
    80004e0e:	e1040613          	addi	a2,s0,-496
    80004e12:	4581                	li	a1,0
    80004e14:	8526                	mv	a0,s1
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	a8e080e7          	jalr	-1394(ra) # 800038a4 <readi>
    80004e1e:	03800793          	li	a5,56
    80004e22:	f8f517e3          	bne	a0,a5,80004db0 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004e26:	e1042783          	lw	a5,-496(s0)
    80004e2a:	4705                	li	a4,1
    80004e2c:	fce796e3          	bne	a5,a4,80004df8 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004e30:	e3843603          	ld	a2,-456(s0)
    80004e34:	e3043783          	ld	a5,-464(s0)
    80004e38:	f8f669e3          	bltu	a2,a5,80004dca <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004e3c:	e2043783          	ld	a5,-480(s0)
    80004e40:	963e                	add	a2,a2,a5
    80004e42:	f8f667e3          	bltu	a2,a5,80004dd0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e46:	85ca                	mv	a1,s2
    80004e48:	855e                	mv	a0,s7
    80004e4a:	ffffc097          	auipc	ra,0xffffc
    80004e4e:	5bc080e7          	jalr	1468(ra) # 80001406 <uvmalloc>
    80004e52:	e0a43423          	sd	a0,-504(s0)
    80004e56:	d141                	beqz	a0,80004dd6 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004e58:	e2043d03          	ld	s10,-480(s0)
    80004e5c:	df043783          	ld	a5,-528(s0)
    80004e60:	00fd77b3          	and	a5,s10,a5
    80004e64:	fba1                	bnez	a5,80004db4 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004e66:	e1842d83          	lw	s11,-488(s0)
    80004e6a:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004e6e:	f80c03e3          	beqz	s8,80004df4 <exec+0x306>
    80004e72:	8a62                	mv	s4,s8
    80004e74:	4901                	li	s2,0
    80004e76:	b345                	j	80004c16 <exec+0x128>

0000000080004e78 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004e78:	7179                	addi	sp,sp,-48
    80004e7a:	f406                	sd	ra,40(sp)
    80004e7c:	f022                	sd	s0,32(sp)
    80004e7e:	ec26                	sd	s1,24(sp)
    80004e80:	e84a                	sd	s2,16(sp)
    80004e82:	1800                	addi	s0,sp,48
    80004e84:	892e                	mv	s2,a1
    80004e86:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004e88:	fdc40593          	addi	a1,s0,-36
    80004e8c:	ffffe097          	auipc	ra,0xffffe
    80004e90:	bb4080e7          	jalr	-1100(ra) # 80002a40 <argint>
    80004e94:	04054063          	bltz	a0,80004ed4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004e98:	fdc42703          	lw	a4,-36(s0)
    80004e9c:	47bd                	li	a5,15
    80004e9e:	02e7ed63          	bltu	a5,a4,80004ed8 <argfd+0x60>
    80004ea2:	ffffd097          	auipc	ra,0xffffd
    80004ea6:	af2080e7          	jalr	-1294(ra) # 80001994 <myproc>
    80004eaa:	fdc42703          	lw	a4,-36(s0)
    80004eae:	01a70793          	addi	a5,a4,26
    80004eb2:	078e                	slli	a5,a5,0x3
    80004eb4:	953e                	add	a0,a0,a5
    80004eb6:	611c                	ld	a5,0(a0)
    80004eb8:	c395                	beqz	a5,80004edc <argfd+0x64>
    return -1;
  if(pfd)
    80004eba:	00090463          	beqz	s2,80004ec2 <argfd+0x4a>
    *pfd = fd;
    80004ebe:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004ec2:	4501                	li	a0,0
  if(pf)
    80004ec4:	c091                	beqz	s1,80004ec8 <argfd+0x50>
    *pf = f;
    80004ec6:	e09c                	sd	a5,0(s1)
}
    80004ec8:	70a2                	ld	ra,40(sp)
    80004eca:	7402                	ld	s0,32(sp)
    80004ecc:	64e2                	ld	s1,24(sp)
    80004ece:	6942                	ld	s2,16(sp)
    80004ed0:	6145                	addi	sp,sp,48
    80004ed2:	8082                	ret
    return -1;
    80004ed4:	557d                	li	a0,-1
    80004ed6:	bfcd                	j	80004ec8 <argfd+0x50>
    return -1;
    80004ed8:	557d                	li	a0,-1
    80004eda:	b7fd                	j	80004ec8 <argfd+0x50>
    80004edc:	557d                	li	a0,-1
    80004ede:	b7ed                	j	80004ec8 <argfd+0x50>

0000000080004ee0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004ee0:	1101                	addi	sp,sp,-32
    80004ee2:	ec06                	sd	ra,24(sp)
    80004ee4:	e822                	sd	s0,16(sp)
    80004ee6:	e426                	sd	s1,8(sp)
    80004ee8:	1000                	addi	s0,sp,32
    80004eea:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004eec:	ffffd097          	auipc	ra,0xffffd
    80004ef0:	aa8080e7          	jalr	-1368(ra) # 80001994 <myproc>
    80004ef4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004ef6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80004efa:	4501                	li	a0,0
    80004efc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004efe:	6398                	ld	a4,0(a5)
    80004f00:	cb19                	beqz	a4,80004f16 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004f02:	2505                	addiw	a0,a0,1
    80004f04:	07a1                	addi	a5,a5,8
    80004f06:	fed51ce3          	bne	a0,a3,80004efe <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004f0a:	557d                	li	a0,-1
}
    80004f0c:	60e2                	ld	ra,24(sp)
    80004f0e:	6442                	ld	s0,16(sp)
    80004f10:	64a2                	ld	s1,8(sp)
    80004f12:	6105                	addi	sp,sp,32
    80004f14:	8082                	ret
      p->ofile[fd] = f;
    80004f16:	01a50793          	addi	a5,a0,26
    80004f1a:	078e                	slli	a5,a5,0x3
    80004f1c:	963e                	add	a2,a2,a5
    80004f1e:	e204                	sd	s1,0(a2)
      return fd;
    80004f20:	b7f5                	j	80004f0c <fdalloc+0x2c>

0000000080004f22 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004f22:	715d                	addi	sp,sp,-80
    80004f24:	e486                	sd	ra,72(sp)
    80004f26:	e0a2                	sd	s0,64(sp)
    80004f28:	fc26                	sd	s1,56(sp)
    80004f2a:	f84a                	sd	s2,48(sp)
    80004f2c:	f44e                	sd	s3,40(sp)
    80004f2e:	f052                	sd	s4,32(sp)
    80004f30:	ec56                	sd	s5,24(sp)
    80004f32:	0880                	addi	s0,sp,80
    80004f34:	89ae                	mv	s3,a1
    80004f36:	8ab2                	mv	s5,a2
    80004f38:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004f3a:	fb040593          	addi	a1,s0,-80
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	e86080e7          	jalr	-378(ra) # 80003dc4 <nameiparent>
    80004f46:	892a                	mv	s2,a0
    80004f48:	12050f63          	beqz	a0,80005086 <create+0x164>
    return 0;

  ilock(dp);
    80004f4c:	ffffe097          	auipc	ra,0xffffe
    80004f50:	6a4080e7          	jalr	1700(ra) # 800035f0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004f54:	4601                	li	a2,0
    80004f56:	fb040593          	addi	a1,s0,-80
    80004f5a:	854a                	mv	a0,s2
    80004f5c:	fffff097          	auipc	ra,0xfffff
    80004f60:	b78080e7          	jalr	-1160(ra) # 80003ad4 <dirlookup>
    80004f64:	84aa                	mv	s1,a0
    80004f66:	c921                	beqz	a0,80004fb6 <create+0x94>
    iunlockput(dp);
    80004f68:	854a                	mv	a0,s2
    80004f6a:	fffff097          	auipc	ra,0xfffff
    80004f6e:	8e8080e7          	jalr	-1816(ra) # 80003852 <iunlockput>
    ilock(ip);
    80004f72:	8526                	mv	a0,s1
    80004f74:	ffffe097          	auipc	ra,0xffffe
    80004f78:	67c080e7          	jalr	1660(ra) # 800035f0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004f7c:	2981                	sext.w	s3,s3
    80004f7e:	4789                	li	a5,2
    80004f80:	02f99463          	bne	s3,a5,80004fa8 <create+0x86>
    80004f84:	0444d783          	lhu	a5,68(s1)
    80004f88:	37f9                	addiw	a5,a5,-2
    80004f8a:	17c2                	slli	a5,a5,0x30
    80004f8c:	93c1                	srli	a5,a5,0x30
    80004f8e:	4705                	li	a4,1
    80004f90:	00f76c63          	bltu	a4,a5,80004fa8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80004f94:	8526                	mv	a0,s1
    80004f96:	60a6                	ld	ra,72(sp)
    80004f98:	6406                	ld	s0,64(sp)
    80004f9a:	74e2                	ld	s1,56(sp)
    80004f9c:	7942                	ld	s2,48(sp)
    80004f9e:	79a2                	ld	s3,40(sp)
    80004fa0:	7a02                	ld	s4,32(sp)
    80004fa2:	6ae2                	ld	s5,24(sp)
    80004fa4:	6161                	addi	sp,sp,80
    80004fa6:	8082                	ret
    iunlockput(ip);
    80004fa8:	8526                	mv	a0,s1
    80004faa:	fffff097          	auipc	ra,0xfffff
    80004fae:	8a8080e7          	jalr	-1880(ra) # 80003852 <iunlockput>
    return 0;
    80004fb2:	4481                	li	s1,0
    80004fb4:	b7c5                	j	80004f94 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80004fb6:	85ce                	mv	a1,s3
    80004fb8:	00092503          	lw	a0,0(s2)
    80004fbc:	ffffe097          	auipc	ra,0xffffe
    80004fc0:	49c080e7          	jalr	1180(ra) # 80003458 <ialloc>
    80004fc4:	84aa                	mv	s1,a0
    80004fc6:	c529                	beqz	a0,80005010 <create+0xee>
  ilock(ip);
    80004fc8:	ffffe097          	auipc	ra,0xffffe
    80004fcc:	628080e7          	jalr	1576(ra) # 800035f0 <ilock>
  ip->major = major;
    80004fd0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80004fd4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80004fd8:	4785                	li	a5,1
    80004fda:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004fde:	8526                	mv	a0,s1
    80004fe0:	ffffe097          	auipc	ra,0xffffe
    80004fe4:	546080e7          	jalr	1350(ra) # 80003526 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004fe8:	2981                	sext.w	s3,s3
    80004fea:	4785                	li	a5,1
    80004fec:	02f98a63          	beq	s3,a5,80005020 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80004ff0:	40d0                	lw	a2,4(s1)
    80004ff2:	fb040593          	addi	a1,s0,-80
    80004ff6:	854a                	mv	a0,s2
    80004ff8:	fffff097          	auipc	ra,0xfffff
    80004ffc:	cec080e7          	jalr	-788(ra) # 80003ce4 <dirlink>
    80005000:	06054b63          	bltz	a0,80005076 <create+0x154>
  iunlockput(dp);
    80005004:	854a                	mv	a0,s2
    80005006:	fffff097          	auipc	ra,0xfffff
    8000500a:	84c080e7          	jalr	-1972(ra) # 80003852 <iunlockput>
  return ip;
    8000500e:	b759                	j	80004f94 <create+0x72>
    panic("create: ialloc");
    80005010:	00003517          	auipc	a0,0x3
    80005014:	6c850513          	addi	a0,a0,1736 # 800086d8 <syscalls+0x2a8>
    80005018:	ffffb097          	auipc	ra,0xffffb
    8000501c:	518080e7          	jalr	1304(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    80005020:	04a95783          	lhu	a5,74(s2)
    80005024:	2785                	addiw	a5,a5,1
    80005026:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000502a:	854a                	mv	a0,s2
    8000502c:	ffffe097          	auipc	ra,0xffffe
    80005030:	4fa080e7          	jalr	1274(ra) # 80003526 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005034:	40d0                	lw	a2,4(s1)
    80005036:	00003597          	auipc	a1,0x3
    8000503a:	6b258593          	addi	a1,a1,1714 # 800086e8 <syscalls+0x2b8>
    8000503e:	8526                	mv	a0,s1
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	ca4080e7          	jalr	-860(ra) # 80003ce4 <dirlink>
    80005048:	00054f63          	bltz	a0,80005066 <create+0x144>
    8000504c:	00492603          	lw	a2,4(s2)
    80005050:	00003597          	auipc	a1,0x3
    80005054:	6a058593          	addi	a1,a1,1696 # 800086f0 <syscalls+0x2c0>
    80005058:	8526                	mv	a0,s1
    8000505a:	fffff097          	auipc	ra,0xfffff
    8000505e:	c8a080e7          	jalr	-886(ra) # 80003ce4 <dirlink>
    80005062:	f80557e3          	bgez	a0,80004ff0 <create+0xce>
      panic("create dots");
    80005066:	00003517          	auipc	a0,0x3
    8000506a:	69250513          	addi	a0,a0,1682 # 800086f8 <syscalls+0x2c8>
    8000506e:	ffffb097          	auipc	ra,0xffffb
    80005072:	4c2080e7          	jalr	1218(ra) # 80000530 <panic>
    panic("create: dirlink");
    80005076:	00003517          	auipc	a0,0x3
    8000507a:	69250513          	addi	a0,a0,1682 # 80008708 <syscalls+0x2d8>
    8000507e:	ffffb097          	auipc	ra,0xffffb
    80005082:	4b2080e7          	jalr	1202(ra) # 80000530 <panic>
    return 0;
    80005086:	84aa                	mv	s1,a0
    80005088:	b731                	j	80004f94 <create+0x72>

000000008000508a <sys_dup>:
{
    8000508a:	7179                	addi	sp,sp,-48
    8000508c:	f406                	sd	ra,40(sp)
    8000508e:	f022                	sd	s0,32(sp)
    80005090:	ec26                	sd	s1,24(sp)
    80005092:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005094:	fd840613          	addi	a2,s0,-40
    80005098:	4581                	li	a1,0
    8000509a:	4501                	li	a0,0
    8000509c:	00000097          	auipc	ra,0x0
    800050a0:	ddc080e7          	jalr	-548(ra) # 80004e78 <argfd>
    return -1;
    800050a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800050a6:	02054363          	bltz	a0,800050cc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800050aa:	fd843503          	ld	a0,-40(s0)
    800050ae:	00000097          	auipc	ra,0x0
    800050b2:	e32080e7          	jalr	-462(ra) # 80004ee0 <fdalloc>
    800050b6:	84aa                	mv	s1,a0
    return -1;
    800050b8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800050ba:	00054963          	bltz	a0,800050cc <sys_dup+0x42>
  filedup(f);
    800050be:	fd843503          	ld	a0,-40(s0)
    800050c2:	fffff097          	auipc	ra,0xfffff
    800050c6:	37a080e7          	jalr	890(ra) # 8000443c <filedup>
  return fd;
    800050ca:	87a6                	mv	a5,s1
}
    800050cc:	853e                	mv	a0,a5
    800050ce:	70a2                	ld	ra,40(sp)
    800050d0:	7402                	ld	s0,32(sp)
    800050d2:	64e2                	ld	s1,24(sp)
    800050d4:	6145                	addi	sp,sp,48
    800050d6:	8082                	ret

00000000800050d8 <sys_read>:
{
    800050d8:	7179                	addi	sp,sp,-48
    800050da:	f406                	sd	ra,40(sp)
    800050dc:	f022                	sd	s0,32(sp)
    800050de:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050e0:	fe840613          	addi	a2,s0,-24
    800050e4:	4581                	li	a1,0
    800050e6:	4501                	li	a0,0
    800050e8:	00000097          	auipc	ra,0x0
    800050ec:	d90080e7          	jalr	-624(ra) # 80004e78 <argfd>
    return -1;
    800050f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800050f2:	04054163          	bltz	a0,80005134 <sys_read+0x5c>
    800050f6:	fe440593          	addi	a1,s0,-28
    800050fa:	4509                	li	a0,2
    800050fc:	ffffe097          	auipc	ra,0xffffe
    80005100:	944080e7          	jalr	-1724(ra) # 80002a40 <argint>
    return -1;
    80005104:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005106:	02054763          	bltz	a0,80005134 <sys_read+0x5c>
    8000510a:	fd840593          	addi	a1,s0,-40
    8000510e:	4505                	li	a0,1
    80005110:	ffffe097          	auipc	ra,0xffffe
    80005114:	952080e7          	jalr	-1710(ra) # 80002a62 <argaddr>
    return -1;
    80005118:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000511a:	00054d63          	bltz	a0,80005134 <sys_read+0x5c>
  return fileread(f, p, n);
    8000511e:	fe442603          	lw	a2,-28(s0)
    80005122:	fd843583          	ld	a1,-40(s0)
    80005126:	fe843503          	ld	a0,-24(s0)
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	49e080e7          	jalr	1182(ra) # 800045c8 <fileread>
    80005132:	87aa                	mv	a5,a0
}
    80005134:	853e                	mv	a0,a5
    80005136:	70a2                	ld	ra,40(sp)
    80005138:	7402                	ld	s0,32(sp)
    8000513a:	6145                	addi	sp,sp,48
    8000513c:	8082                	ret

000000008000513e <sys_write>:
{
    8000513e:	7179                	addi	sp,sp,-48
    80005140:	f406                	sd	ra,40(sp)
    80005142:	f022                	sd	s0,32(sp)
    80005144:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005146:	fe840613          	addi	a2,s0,-24
    8000514a:	4581                	li	a1,0
    8000514c:	4501                	li	a0,0
    8000514e:	00000097          	auipc	ra,0x0
    80005152:	d2a080e7          	jalr	-726(ra) # 80004e78 <argfd>
    return -1;
    80005156:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005158:	04054163          	bltz	a0,8000519a <sys_write+0x5c>
    8000515c:	fe440593          	addi	a1,s0,-28
    80005160:	4509                	li	a0,2
    80005162:	ffffe097          	auipc	ra,0xffffe
    80005166:	8de080e7          	jalr	-1826(ra) # 80002a40 <argint>
    return -1;
    8000516a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000516c:	02054763          	bltz	a0,8000519a <sys_write+0x5c>
    80005170:	fd840593          	addi	a1,s0,-40
    80005174:	4505                	li	a0,1
    80005176:	ffffe097          	auipc	ra,0xffffe
    8000517a:	8ec080e7          	jalr	-1812(ra) # 80002a62 <argaddr>
    return -1;
    8000517e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005180:	00054d63          	bltz	a0,8000519a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005184:	fe442603          	lw	a2,-28(s0)
    80005188:	fd843583          	ld	a1,-40(s0)
    8000518c:	fe843503          	ld	a0,-24(s0)
    80005190:	fffff097          	auipc	ra,0xfffff
    80005194:	4fa080e7          	jalr	1274(ra) # 8000468a <filewrite>
    80005198:	87aa                	mv	a5,a0
}
    8000519a:	853e                	mv	a0,a5
    8000519c:	70a2                	ld	ra,40(sp)
    8000519e:	7402                	ld	s0,32(sp)
    800051a0:	6145                	addi	sp,sp,48
    800051a2:	8082                	ret

00000000800051a4 <sys_close>:
{
    800051a4:	1101                	addi	sp,sp,-32
    800051a6:	ec06                	sd	ra,24(sp)
    800051a8:	e822                	sd	s0,16(sp)
    800051aa:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800051ac:	fe040613          	addi	a2,s0,-32
    800051b0:	fec40593          	addi	a1,s0,-20
    800051b4:	4501                	li	a0,0
    800051b6:	00000097          	auipc	ra,0x0
    800051ba:	cc2080e7          	jalr	-830(ra) # 80004e78 <argfd>
    return -1;
    800051be:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800051c0:	02054463          	bltz	a0,800051e8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	7d0080e7          	jalr	2000(ra) # 80001994 <myproc>
    800051cc:	fec42783          	lw	a5,-20(s0)
    800051d0:	07e9                	addi	a5,a5,26
    800051d2:	078e                	slli	a5,a5,0x3
    800051d4:	97aa                	add	a5,a5,a0
    800051d6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800051da:	fe043503          	ld	a0,-32(s0)
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	2b0080e7          	jalr	688(ra) # 8000448e <fileclose>
  return 0;
    800051e6:	4781                	li	a5,0
}
    800051e8:	853e                	mv	a0,a5
    800051ea:	60e2                	ld	ra,24(sp)
    800051ec:	6442                	ld	s0,16(sp)
    800051ee:	6105                	addi	sp,sp,32
    800051f0:	8082                	ret

00000000800051f2 <sys_fstat>:
{
    800051f2:	1101                	addi	sp,sp,-32
    800051f4:	ec06                	sd	ra,24(sp)
    800051f6:	e822                	sd	s0,16(sp)
    800051f8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800051fa:	fe840613          	addi	a2,s0,-24
    800051fe:	4581                	li	a1,0
    80005200:	4501                	li	a0,0
    80005202:	00000097          	auipc	ra,0x0
    80005206:	c76080e7          	jalr	-906(ra) # 80004e78 <argfd>
    return -1;
    8000520a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000520c:	02054563          	bltz	a0,80005236 <sys_fstat+0x44>
    80005210:	fe040593          	addi	a1,s0,-32
    80005214:	4505                	li	a0,1
    80005216:	ffffe097          	auipc	ra,0xffffe
    8000521a:	84c080e7          	jalr	-1972(ra) # 80002a62 <argaddr>
    return -1;
    8000521e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005220:	00054b63          	bltz	a0,80005236 <sys_fstat+0x44>
  return filestat(f, st);
    80005224:	fe043583          	ld	a1,-32(s0)
    80005228:	fe843503          	ld	a0,-24(s0)
    8000522c:	fffff097          	auipc	ra,0xfffff
    80005230:	32a080e7          	jalr	810(ra) # 80004556 <filestat>
    80005234:	87aa                	mv	a5,a0
}
    80005236:	853e                	mv	a0,a5
    80005238:	60e2                	ld	ra,24(sp)
    8000523a:	6442                	ld	s0,16(sp)
    8000523c:	6105                	addi	sp,sp,32
    8000523e:	8082                	ret

0000000080005240 <sys_link>:
{
    80005240:	7169                	addi	sp,sp,-304
    80005242:	f606                	sd	ra,296(sp)
    80005244:	f222                	sd	s0,288(sp)
    80005246:	ee26                	sd	s1,280(sp)
    80005248:	ea4a                	sd	s2,272(sp)
    8000524a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000524c:	08000613          	li	a2,128
    80005250:	ed040593          	addi	a1,s0,-304
    80005254:	4501                	li	a0,0
    80005256:	ffffe097          	auipc	ra,0xffffe
    8000525a:	82e080e7          	jalr	-2002(ra) # 80002a84 <argstr>
    return -1;
    8000525e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005260:	10054e63          	bltz	a0,8000537c <sys_link+0x13c>
    80005264:	08000613          	li	a2,128
    80005268:	f5040593          	addi	a1,s0,-176
    8000526c:	4505                	li	a0,1
    8000526e:	ffffe097          	auipc	ra,0xffffe
    80005272:	816080e7          	jalr	-2026(ra) # 80002a84 <argstr>
    return -1;
    80005276:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005278:	10054263          	bltz	a0,8000537c <sys_link+0x13c>
  begin_op();
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	d46080e7          	jalr	-698(ra) # 80003fc2 <begin_op>
  if((ip = namei(old)) == 0){
    80005284:	ed040513          	addi	a0,s0,-304
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	b1e080e7          	jalr	-1250(ra) # 80003da6 <namei>
    80005290:	84aa                	mv	s1,a0
    80005292:	c551                	beqz	a0,8000531e <sys_link+0xde>
  ilock(ip);
    80005294:	ffffe097          	auipc	ra,0xffffe
    80005298:	35c080e7          	jalr	860(ra) # 800035f0 <ilock>
  if(ip->type == T_DIR){
    8000529c:	04449703          	lh	a4,68(s1)
    800052a0:	4785                	li	a5,1
    800052a2:	08f70463          	beq	a4,a5,8000532a <sys_link+0xea>
  ip->nlink++;
    800052a6:	04a4d783          	lhu	a5,74(s1)
    800052aa:	2785                	addiw	a5,a5,1
    800052ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052b0:	8526                	mv	a0,s1
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	274080e7          	jalr	628(ra) # 80003526 <iupdate>
  iunlock(ip);
    800052ba:	8526                	mv	a0,s1
    800052bc:	ffffe097          	auipc	ra,0xffffe
    800052c0:	3f6080e7          	jalr	1014(ra) # 800036b2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800052c4:	fd040593          	addi	a1,s0,-48
    800052c8:	f5040513          	addi	a0,s0,-176
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	af8080e7          	jalr	-1288(ra) # 80003dc4 <nameiparent>
    800052d4:	892a                	mv	s2,a0
    800052d6:	c935                	beqz	a0,8000534a <sys_link+0x10a>
  ilock(dp);
    800052d8:	ffffe097          	auipc	ra,0xffffe
    800052dc:	318080e7          	jalr	792(ra) # 800035f0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800052e0:	00092703          	lw	a4,0(s2)
    800052e4:	409c                	lw	a5,0(s1)
    800052e6:	04f71d63          	bne	a4,a5,80005340 <sys_link+0x100>
    800052ea:	40d0                	lw	a2,4(s1)
    800052ec:	fd040593          	addi	a1,s0,-48
    800052f0:	854a                	mv	a0,s2
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	9f2080e7          	jalr	-1550(ra) # 80003ce4 <dirlink>
    800052fa:	04054363          	bltz	a0,80005340 <sys_link+0x100>
  iunlockput(dp);
    800052fe:	854a                	mv	a0,s2
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	552080e7          	jalr	1362(ra) # 80003852 <iunlockput>
  iput(ip);
    80005308:	8526                	mv	a0,s1
    8000530a:	ffffe097          	auipc	ra,0xffffe
    8000530e:	4a0080e7          	jalr	1184(ra) # 800037aa <iput>
  end_op();
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	d30080e7          	jalr	-720(ra) # 80004042 <end_op>
  return 0;
    8000531a:	4781                	li	a5,0
    8000531c:	a085                	j	8000537c <sys_link+0x13c>
    end_op();
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	d24080e7          	jalr	-732(ra) # 80004042 <end_op>
    return -1;
    80005326:	57fd                	li	a5,-1
    80005328:	a891                	j	8000537c <sys_link+0x13c>
    iunlockput(ip);
    8000532a:	8526                	mv	a0,s1
    8000532c:	ffffe097          	auipc	ra,0xffffe
    80005330:	526080e7          	jalr	1318(ra) # 80003852 <iunlockput>
    end_op();
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	d0e080e7          	jalr	-754(ra) # 80004042 <end_op>
    return -1;
    8000533c:	57fd                	li	a5,-1
    8000533e:	a83d                	j	8000537c <sys_link+0x13c>
    iunlockput(dp);
    80005340:	854a                	mv	a0,s2
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	510080e7          	jalr	1296(ra) # 80003852 <iunlockput>
  ilock(ip);
    8000534a:	8526                	mv	a0,s1
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	2a4080e7          	jalr	676(ra) # 800035f0 <ilock>
  ip->nlink--;
    80005354:	04a4d783          	lhu	a5,74(s1)
    80005358:	37fd                	addiw	a5,a5,-1
    8000535a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000535e:	8526                	mv	a0,s1
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	1c6080e7          	jalr	454(ra) # 80003526 <iupdate>
  iunlockput(ip);
    80005368:	8526                	mv	a0,s1
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	4e8080e7          	jalr	1256(ra) # 80003852 <iunlockput>
  end_op();
    80005372:	fffff097          	auipc	ra,0xfffff
    80005376:	cd0080e7          	jalr	-816(ra) # 80004042 <end_op>
  return -1;
    8000537a:	57fd                	li	a5,-1
}
    8000537c:	853e                	mv	a0,a5
    8000537e:	70b2                	ld	ra,296(sp)
    80005380:	7412                	ld	s0,288(sp)
    80005382:	64f2                	ld	s1,280(sp)
    80005384:	6952                	ld	s2,272(sp)
    80005386:	6155                	addi	sp,sp,304
    80005388:	8082                	ret

000000008000538a <sys_unlink>:
{
    8000538a:	7151                	addi	sp,sp,-240
    8000538c:	f586                	sd	ra,232(sp)
    8000538e:	f1a2                	sd	s0,224(sp)
    80005390:	eda6                	sd	s1,216(sp)
    80005392:	e9ca                	sd	s2,208(sp)
    80005394:	e5ce                	sd	s3,200(sp)
    80005396:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005398:	08000613          	li	a2,128
    8000539c:	f3040593          	addi	a1,s0,-208
    800053a0:	4501                	li	a0,0
    800053a2:	ffffd097          	auipc	ra,0xffffd
    800053a6:	6e2080e7          	jalr	1762(ra) # 80002a84 <argstr>
    800053aa:	18054163          	bltz	a0,8000552c <sys_unlink+0x1a2>
  begin_op();
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	c14080e7          	jalr	-1004(ra) # 80003fc2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800053b6:	fb040593          	addi	a1,s0,-80
    800053ba:	f3040513          	addi	a0,s0,-208
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	a06080e7          	jalr	-1530(ra) # 80003dc4 <nameiparent>
    800053c6:	84aa                	mv	s1,a0
    800053c8:	c979                	beqz	a0,8000549e <sys_unlink+0x114>
  ilock(dp);
    800053ca:	ffffe097          	auipc	ra,0xffffe
    800053ce:	226080e7          	jalr	550(ra) # 800035f0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800053d2:	00003597          	auipc	a1,0x3
    800053d6:	31658593          	addi	a1,a1,790 # 800086e8 <syscalls+0x2b8>
    800053da:	fb040513          	addi	a0,s0,-80
    800053de:	ffffe097          	auipc	ra,0xffffe
    800053e2:	6dc080e7          	jalr	1756(ra) # 80003aba <namecmp>
    800053e6:	14050a63          	beqz	a0,8000553a <sys_unlink+0x1b0>
    800053ea:	00003597          	auipc	a1,0x3
    800053ee:	30658593          	addi	a1,a1,774 # 800086f0 <syscalls+0x2c0>
    800053f2:	fb040513          	addi	a0,s0,-80
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	6c4080e7          	jalr	1732(ra) # 80003aba <namecmp>
    800053fe:	12050e63          	beqz	a0,8000553a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005402:	f2c40613          	addi	a2,s0,-212
    80005406:	fb040593          	addi	a1,s0,-80
    8000540a:	8526                	mv	a0,s1
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	6c8080e7          	jalr	1736(ra) # 80003ad4 <dirlookup>
    80005414:	892a                	mv	s2,a0
    80005416:	12050263          	beqz	a0,8000553a <sys_unlink+0x1b0>
  ilock(ip);
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	1d6080e7          	jalr	470(ra) # 800035f0 <ilock>
  if(ip->nlink < 1)
    80005422:	04a91783          	lh	a5,74(s2)
    80005426:	08f05263          	blez	a5,800054aa <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000542a:	04491703          	lh	a4,68(s2)
    8000542e:	4785                	li	a5,1
    80005430:	08f70563          	beq	a4,a5,800054ba <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005434:	4641                	li	a2,16
    80005436:	4581                	li	a1,0
    80005438:	fc040513          	addi	a0,s0,-64
    8000543c:	ffffc097          	auipc	ra,0xffffc
    80005440:	896080e7          	jalr	-1898(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005444:	4741                	li	a4,16
    80005446:	f2c42683          	lw	a3,-212(s0)
    8000544a:	fc040613          	addi	a2,s0,-64
    8000544e:	4581                	li	a1,0
    80005450:	8526                	mv	a0,s1
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	54a080e7          	jalr	1354(ra) # 8000399c <writei>
    8000545a:	47c1                	li	a5,16
    8000545c:	0af51563          	bne	a0,a5,80005506 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005460:	04491703          	lh	a4,68(s2)
    80005464:	4785                	li	a5,1
    80005466:	0af70863          	beq	a4,a5,80005516 <sys_unlink+0x18c>
  iunlockput(dp);
    8000546a:	8526                	mv	a0,s1
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	3e6080e7          	jalr	998(ra) # 80003852 <iunlockput>
  ip->nlink--;
    80005474:	04a95783          	lhu	a5,74(s2)
    80005478:	37fd                	addiw	a5,a5,-1
    8000547a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000547e:	854a                	mv	a0,s2
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	0a6080e7          	jalr	166(ra) # 80003526 <iupdate>
  iunlockput(ip);
    80005488:	854a                	mv	a0,s2
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	3c8080e7          	jalr	968(ra) # 80003852 <iunlockput>
  end_op();
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	bb0080e7          	jalr	-1104(ra) # 80004042 <end_op>
  return 0;
    8000549a:	4501                	li	a0,0
    8000549c:	a84d                	j	8000554e <sys_unlink+0x1c4>
    end_op();
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	ba4080e7          	jalr	-1116(ra) # 80004042 <end_op>
    return -1;
    800054a6:	557d                	li	a0,-1
    800054a8:	a05d                	j	8000554e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800054aa:	00003517          	auipc	a0,0x3
    800054ae:	26e50513          	addi	a0,a0,622 # 80008718 <syscalls+0x2e8>
    800054b2:	ffffb097          	auipc	ra,0xffffb
    800054b6:	07e080e7          	jalr	126(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054ba:	04c92703          	lw	a4,76(s2)
    800054be:	02000793          	li	a5,32
    800054c2:	f6e7f9e3          	bgeu	a5,a4,80005434 <sys_unlink+0xaa>
    800054c6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800054ca:	4741                	li	a4,16
    800054cc:	86ce                	mv	a3,s3
    800054ce:	f1840613          	addi	a2,s0,-232
    800054d2:	4581                	li	a1,0
    800054d4:	854a                	mv	a0,s2
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	3ce080e7          	jalr	974(ra) # 800038a4 <readi>
    800054de:	47c1                	li	a5,16
    800054e0:	00f51b63          	bne	a0,a5,800054f6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800054e4:	f1845783          	lhu	a5,-232(s0)
    800054e8:	e7a1                	bnez	a5,80005530 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800054ea:	29c1                	addiw	s3,s3,16
    800054ec:	04c92783          	lw	a5,76(s2)
    800054f0:	fcf9ede3          	bltu	s3,a5,800054ca <sys_unlink+0x140>
    800054f4:	b781                	j	80005434 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800054f6:	00003517          	auipc	a0,0x3
    800054fa:	23a50513          	addi	a0,a0,570 # 80008730 <syscalls+0x300>
    800054fe:	ffffb097          	auipc	ra,0xffffb
    80005502:	032080e7          	jalr	50(ra) # 80000530 <panic>
    panic("unlink: writei");
    80005506:	00003517          	auipc	a0,0x3
    8000550a:	24250513          	addi	a0,a0,578 # 80008748 <syscalls+0x318>
    8000550e:	ffffb097          	auipc	ra,0xffffb
    80005512:	022080e7          	jalr	34(ra) # 80000530 <panic>
    dp->nlink--;
    80005516:	04a4d783          	lhu	a5,74(s1)
    8000551a:	37fd                	addiw	a5,a5,-1
    8000551c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005520:	8526                	mv	a0,s1
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	004080e7          	jalr	4(ra) # 80003526 <iupdate>
    8000552a:	b781                	j	8000546a <sys_unlink+0xe0>
    return -1;
    8000552c:	557d                	li	a0,-1
    8000552e:	a005                	j	8000554e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005530:	854a                	mv	a0,s2
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	320080e7          	jalr	800(ra) # 80003852 <iunlockput>
  iunlockput(dp);
    8000553a:	8526                	mv	a0,s1
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	316080e7          	jalr	790(ra) # 80003852 <iunlockput>
  end_op();
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	afe080e7          	jalr	-1282(ra) # 80004042 <end_op>
  return -1;
    8000554c:	557d                	li	a0,-1
}
    8000554e:	70ae                	ld	ra,232(sp)
    80005550:	740e                	ld	s0,224(sp)
    80005552:	64ee                	ld	s1,216(sp)
    80005554:	694e                	ld	s2,208(sp)
    80005556:	69ae                	ld	s3,200(sp)
    80005558:	616d                	addi	sp,sp,240
    8000555a:	8082                	ret

000000008000555c <sys_open>:

uint64
sys_open(void)
{
    8000555c:	7131                	addi	sp,sp,-192
    8000555e:	fd06                	sd	ra,184(sp)
    80005560:	f922                	sd	s0,176(sp)
    80005562:	f526                	sd	s1,168(sp)
    80005564:	f14a                	sd	s2,160(sp)
    80005566:	ed4e                	sd	s3,152(sp)
    80005568:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000556a:	08000613          	li	a2,128
    8000556e:	f5040593          	addi	a1,s0,-176
    80005572:	4501                	li	a0,0
    80005574:	ffffd097          	auipc	ra,0xffffd
    80005578:	510080e7          	jalr	1296(ra) # 80002a84 <argstr>
    return -1;
    8000557c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000557e:	0c054163          	bltz	a0,80005640 <sys_open+0xe4>
    80005582:	f4c40593          	addi	a1,s0,-180
    80005586:	4505                	li	a0,1
    80005588:	ffffd097          	auipc	ra,0xffffd
    8000558c:	4b8080e7          	jalr	1208(ra) # 80002a40 <argint>
    80005590:	0a054863          	bltz	a0,80005640 <sys_open+0xe4>

  begin_op();
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	a2e080e7          	jalr	-1490(ra) # 80003fc2 <begin_op>

  if(omode & O_CREATE){
    8000559c:	f4c42783          	lw	a5,-180(s0)
    800055a0:	2007f793          	andi	a5,a5,512
    800055a4:	cbdd                	beqz	a5,8000565a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800055a6:	4681                	li	a3,0
    800055a8:	4601                	li	a2,0
    800055aa:	4589                	li	a1,2
    800055ac:	f5040513          	addi	a0,s0,-176
    800055b0:	00000097          	auipc	ra,0x0
    800055b4:	972080e7          	jalr	-1678(ra) # 80004f22 <create>
    800055b8:	892a                	mv	s2,a0
    if(ip == 0){
    800055ba:	c959                	beqz	a0,80005650 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800055bc:	04491703          	lh	a4,68(s2)
    800055c0:	478d                	li	a5,3
    800055c2:	00f71763          	bne	a4,a5,800055d0 <sys_open+0x74>
    800055c6:	04695703          	lhu	a4,70(s2)
    800055ca:	47a5                	li	a5,9
    800055cc:	0ce7ec63          	bltu	a5,a4,800056a4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	e02080e7          	jalr	-510(ra) # 800043d2 <filealloc>
    800055d8:	89aa                	mv	s3,a0
    800055da:	10050263          	beqz	a0,800056de <sys_open+0x182>
    800055de:	00000097          	auipc	ra,0x0
    800055e2:	902080e7          	jalr	-1790(ra) # 80004ee0 <fdalloc>
    800055e6:	84aa                	mv	s1,a0
    800055e8:	0e054663          	bltz	a0,800056d4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800055ec:	04491703          	lh	a4,68(s2)
    800055f0:	478d                	li	a5,3
    800055f2:	0cf70463          	beq	a4,a5,800056ba <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800055f6:	4789                	li	a5,2
    800055f8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800055fc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005600:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005604:	f4c42783          	lw	a5,-180(s0)
    80005608:	0017c713          	xori	a4,a5,1
    8000560c:	8b05                	andi	a4,a4,1
    8000560e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005612:	0037f713          	andi	a4,a5,3
    80005616:	00e03733          	snez	a4,a4
    8000561a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000561e:	4007f793          	andi	a5,a5,1024
    80005622:	c791                	beqz	a5,8000562e <sys_open+0xd2>
    80005624:	04491703          	lh	a4,68(s2)
    80005628:	4789                	li	a5,2
    8000562a:	08f70f63          	beq	a4,a5,800056c8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000562e:	854a                	mv	a0,s2
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	082080e7          	jalr	130(ra) # 800036b2 <iunlock>
  end_op();
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	a0a080e7          	jalr	-1526(ra) # 80004042 <end_op>

  return fd;
}
    80005640:	8526                	mv	a0,s1
    80005642:	70ea                	ld	ra,184(sp)
    80005644:	744a                	ld	s0,176(sp)
    80005646:	74aa                	ld	s1,168(sp)
    80005648:	790a                	ld	s2,160(sp)
    8000564a:	69ea                	ld	s3,152(sp)
    8000564c:	6129                	addi	sp,sp,192
    8000564e:	8082                	ret
      end_op();
    80005650:	fffff097          	auipc	ra,0xfffff
    80005654:	9f2080e7          	jalr	-1550(ra) # 80004042 <end_op>
      return -1;
    80005658:	b7e5                	j	80005640 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000565a:	f5040513          	addi	a0,s0,-176
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	748080e7          	jalr	1864(ra) # 80003da6 <namei>
    80005666:	892a                	mv	s2,a0
    80005668:	c905                	beqz	a0,80005698 <sys_open+0x13c>
    ilock(ip);
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	f86080e7          	jalr	-122(ra) # 800035f0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005672:	04491703          	lh	a4,68(s2)
    80005676:	4785                	li	a5,1
    80005678:	f4f712e3          	bne	a4,a5,800055bc <sys_open+0x60>
    8000567c:	f4c42783          	lw	a5,-180(s0)
    80005680:	dba1                	beqz	a5,800055d0 <sys_open+0x74>
      iunlockput(ip);
    80005682:	854a                	mv	a0,s2
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	1ce080e7          	jalr	462(ra) # 80003852 <iunlockput>
      end_op();
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	9b6080e7          	jalr	-1610(ra) # 80004042 <end_op>
      return -1;
    80005694:	54fd                	li	s1,-1
    80005696:	b76d                	j	80005640 <sys_open+0xe4>
      end_op();
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	9aa080e7          	jalr	-1622(ra) # 80004042 <end_op>
      return -1;
    800056a0:	54fd                	li	s1,-1
    800056a2:	bf79                	j	80005640 <sys_open+0xe4>
    iunlockput(ip);
    800056a4:	854a                	mv	a0,s2
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	1ac080e7          	jalr	428(ra) # 80003852 <iunlockput>
    end_op();
    800056ae:	fffff097          	auipc	ra,0xfffff
    800056b2:	994080e7          	jalr	-1644(ra) # 80004042 <end_op>
    return -1;
    800056b6:	54fd                	li	s1,-1
    800056b8:	b761                	j	80005640 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800056ba:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800056be:	04691783          	lh	a5,70(s2)
    800056c2:	02f99223          	sh	a5,36(s3)
    800056c6:	bf2d                	j	80005600 <sys_open+0xa4>
    itrunc(ip);
    800056c8:	854a                	mv	a0,s2
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	034080e7          	jalr	52(ra) # 800036fe <itrunc>
    800056d2:	bfb1                	j	8000562e <sys_open+0xd2>
      fileclose(f);
    800056d4:	854e                	mv	a0,s3
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	db8080e7          	jalr	-584(ra) # 8000448e <fileclose>
    iunlockput(ip);
    800056de:	854a                	mv	a0,s2
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	172080e7          	jalr	370(ra) # 80003852 <iunlockput>
    end_op();
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	95a080e7          	jalr	-1702(ra) # 80004042 <end_op>
    return -1;
    800056f0:	54fd                	li	s1,-1
    800056f2:	b7b9                	j	80005640 <sys_open+0xe4>

00000000800056f4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800056f4:	7175                	addi	sp,sp,-144
    800056f6:	e506                	sd	ra,136(sp)
    800056f8:	e122                	sd	s0,128(sp)
    800056fa:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	8c6080e7          	jalr	-1850(ra) # 80003fc2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005704:	08000613          	li	a2,128
    80005708:	f7040593          	addi	a1,s0,-144
    8000570c:	4501                	li	a0,0
    8000570e:	ffffd097          	auipc	ra,0xffffd
    80005712:	376080e7          	jalr	886(ra) # 80002a84 <argstr>
    80005716:	02054963          	bltz	a0,80005748 <sys_mkdir+0x54>
    8000571a:	4681                	li	a3,0
    8000571c:	4601                	li	a2,0
    8000571e:	4585                	li	a1,1
    80005720:	f7040513          	addi	a0,s0,-144
    80005724:	fffff097          	auipc	ra,0xfffff
    80005728:	7fe080e7          	jalr	2046(ra) # 80004f22 <create>
    8000572c:	cd11                	beqz	a0,80005748 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	124080e7          	jalr	292(ra) # 80003852 <iunlockput>
  end_op();
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	90c080e7          	jalr	-1780(ra) # 80004042 <end_op>
  return 0;
    8000573e:	4501                	li	a0,0
}
    80005740:	60aa                	ld	ra,136(sp)
    80005742:	640a                	ld	s0,128(sp)
    80005744:	6149                	addi	sp,sp,144
    80005746:	8082                	ret
    end_op();
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	8fa080e7          	jalr	-1798(ra) # 80004042 <end_op>
    return -1;
    80005750:	557d                	li	a0,-1
    80005752:	b7fd                	j	80005740 <sys_mkdir+0x4c>

0000000080005754 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005754:	7135                	addi	sp,sp,-160
    80005756:	ed06                	sd	ra,152(sp)
    80005758:	e922                	sd	s0,144(sp)
    8000575a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	866080e7          	jalr	-1946(ra) # 80003fc2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005764:	08000613          	li	a2,128
    80005768:	f7040593          	addi	a1,s0,-144
    8000576c:	4501                	li	a0,0
    8000576e:	ffffd097          	auipc	ra,0xffffd
    80005772:	316080e7          	jalr	790(ra) # 80002a84 <argstr>
    80005776:	04054a63          	bltz	a0,800057ca <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000577a:	f6c40593          	addi	a1,s0,-148
    8000577e:	4505                	li	a0,1
    80005780:	ffffd097          	auipc	ra,0xffffd
    80005784:	2c0080e7          	jalr	704(ra) # 80002a40 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005788:	04054163          	bltz	a0,800057ca <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000578c:	f6840593          	addi	a1,s0,-152
    80005790:	4509                	li	a0,2
    80005792:	ffffd097          	auipc	ra,0xffffd
    80005796:	2ae080e7          	jalr	686(ra) # 80002a40 <argint>
     argint(1, &major) < 0 ||
    8000579a:	02054863          	bltz	a0,800057ca <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000579e:	f6841683          	lh	a3,-152(s0)
    800057a2:	f6c41603          	lh	a2,-148(s0)
    800057a6:	458d                	li	a1,3
    800057a8:	f7040513          	addi	a0,s0,-144
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	776080e7          	jalr	1910(ra) # 80004f22 <create>
     argint(2, &minor) < 0 ||
    800057b4:	c919                	beqz	a0,800057ca <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	09c080e7          	jalr	156(ra) # 80003852 <iunlockput>
  end_op();
    800057be:	fffff097          	auipc	ra,0xfffff
    800057c2:	884080e7          	jalr	-1916(ra) # 80004042 <end_op>
  return 0;
    800057c6:	4501                	li	a0,0
    800057c8:	a031                	j	800057d4 <sys_mknod+0x80>
    end_op();
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	878080e7          	jalr	-1928(ra) # 80004042 <end_op>
    return -1;
    800057d2:	557d                	li	a0,-1
}
    800057d4:	60ea                	ld	ra,152(sp)
    800057d6:	644a                	ld	s0,144(sp)
    800057d8:	610d                	addi	sp,sp,160
    800057da:	8082                	ret

00000000800057dc <sys_chdir>:

uint64
sys_chdir(void)
{
    800057dc:	7135                	addi	sp,sp,-160
    800057de:	ed06                	sd	ra,152(sp)
    800057e0:	e922                	sd	s0,144(sp)
    800057e2:	e526                	sd	s1,136(sp)
    800057e4:	e14a                	sd	s2,128(sp)
    800057e6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800057e8:	ffffc097          	auipc	ra,0xffffc
    800057ec:	1ac080e7          	jalr	428(ra) # 80001994 <myproc>
    800057f0:	892a                	mv	s2,a0
  
  begin_op();
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	7d0080e7          	jalr	2000(ra) # 80003fc2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800057fa:	08000613          	li	a2,128
    800057fe:	f6040593          	addi	a1,s0,-160
    80005802:	4501                	li	a0,0
    80005804:	ffffd097          	auipc	ra,0xffffd
    80005808:	280080e7          	jalr	640(ra) # 80002a84 <argstr>
    8000580c:	04054b63          	bltz	a0,80005862 <sys_chdir+0x86>
    80005810:	f6040513          	addi	a0,s0,-160
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	592080e7          	jalr	1426(ra) # 80003da6 <namei>
    8000581c:	84aa                	mv	s1,a0
    8000581e:	c131                	beqz	a0,80005862 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	dd0080e7          	jalr	-560(ra) # 800035f0 <ilock>
  if(ip->type != T_DIR){
    80005828:	04449703          	lh	a4,68(s1)
    8000582c:	4785                	li	a5,1
    8000582e:	04f71063          	bne	a4,a5,8000586e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005832:	8526                	mv	a0,s1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	e7e080e7          	jalr	-386(ra) # 800036b2 <iunlock>
  iput(p->cwd);
    8000583c:	15093503          	ld	a0,336(s2)
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	f6a080e7          	jalr	-150(ra) # 800037aa <iput>
  end_op();
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	7fa080e7          	jalr	2042(ra) # 80004042 <end_op>
  p->cwd = ip;
    80005850:	14993823          	sd	s1,336(s2)
  return 0;
    80005854:	4501                	li	a0,0
}
    80005856:	60ea                	ld	ra,152(sp)
    80005858:	644a                	ld	s0,144(sp)
    8000585a:	64aa                	ld	s1,136(sp)
    8000585c:	690a                	ld	s2,128(sp)
    8000585e:	610d                	addi	sp,sp,160
    80005860:	8082                	ret
    end_op();
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	7e0080e7          	jalr	2016(ra) # 80004042 <end_op>
    return -1;
    8000586a:	557d                	li	a0,-1
    8000586c:	b7ed                	j	80005856 <sys_chdir+0x7a>
    iunlockput(ip);
    8000586e:	8526                	mv	a0,s1
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	fe2080e7          	jalr	-30(ra) # 80003852 <iunlockput>
    end_op();
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	7ca080e7          	jalr	1994(ra) # 80004042 <end_op>
    return -1;
    80005880:	557d                	li	a0,-1
    80005882:	bfd1                	j	80005856 <sys_chdir+0x7a>

0000000080005884 <sys_exec>:

uint64
sys_exec(void)
{
    80005884:	7145                	addi	sp,sp,-464
    80005886:	e786                	sd	ra,456(sp)
    80005888:	e3a2                	sd	s0,448(sp)
    8000588a:	ff26                	sd	s1,440(sp)
    8000588c:	fb4a                	sd	s2,432(sp)
    8000588e:	f74e                	sd	s3,424(sp)
    80005890:	f352                	sd	s4,416(sp)
    80005892:	ef56                	sd	s5,408(sp)
    80005894:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005896:	08000613          	li	a2,128
    8000589a:	f4040593          	addi	a1,s0,-192
    8000589e:	4501                	li	a0,0
    800058a0:	ffffd097          	auipc	ra,0xffffd
    800058a4:	1e4080e7          	jalr	484(ra) # 80002a84 <argstr>
    return -1;
    800058a8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800058aa:	0c054a63          	bltz	a0,8000597e <sys_exec+0xfa>
    800058ae:	e3840593          	addi	a1,s0,-456
    800058b2:	4505                	li	a0,1
    800058b4:	ffffd097          	auipc	ra,0xffffd
    800058b8:	1ae080e7          	jalr	430(ra) # 80002a62 <argaddr>
    800058bc:	0c054163          	bltz	a0,8000597e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800058c0:	10000613          	li	a2,256
    800058c4:	4581                	li	a1,0
    800058c6:	e4040513          	addi	a0,s0,-448
    800058ca:	ffffb097          	auipc	ra,0xffffb
    800058ce:	408080e7          	jalr	1032(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800058d2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800058d6:	89a6                	mv	s3,s1
    800058d8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800058da:	02000a13          	li	s4,32
    800058de:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800058e2:	00391513          	slli	a0,s2,0x3
    800058e6:	e3040593          	addi	a1,s0,-464
    800058ea:	e3843783          	ld	a5,-456(s0)
    800058ee:	953e                	add	a0,a0,a5
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	0b6080e7          	jalr	182(ra) # 800029a6 <fetchaddr>
    800058f8:	02054a63          	bltz	a0,8000592c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800058fc:	e3043783          	ld	a5,-464(s0)
    80005900:	c3b9                	beqz	a5,80005946 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005902:	ffffb097          	auipc	ra,0xffffb
    80005906:	1e4080e7          	jalr	484(ra) # 80000ae6 <kalloc>
    8000590a:	85aa                	mv	a1,a0
    8000590c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005910:	cd11                	beqz	a0,8000592c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005912:	6605                	lui	a2,0x1
    80005914:	e3043503          	ld	a0,-464(s0)
    80005918:	ffffd097          	auipc	ra,0xffffd
    8000591c:	0e0080e7          	jalr	224(ra) # 800029f8 <fetchstr>
    80005920:	00054663          	bltz	a0,8000592c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005924:	0905                	addi	s2,s2,1
    80005926:	09a1                	addi	s3,s3,8
    80005928:	fb491be3          	bne	s2,s4,800058de <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000592c:	10048913          	addi	s2,s1,256
    80005930:	6088                	ld	a0,0(s1)
    80005932:	c529                	beqz	a0,8000597c <sys_exec+0xf8>
    kfree(argv[i]);
    80005934:	ffffb097          	auipc	ra,0xffffb
    80005938:	0b6080e7          	jalr	182(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000593c:	04a1                	addi	s1,s1,8
    8000593e:	ff2499e3          	bne	s1,s2,80005930 <sys_exec+0xac>
  return -1;
    80005942:	597d                	li	s2,-1
    80005944:	a82d                	j	8000597e <sys_exec+0xfa>
      argv[i] = 0;
    80005946:	0a8e                	slli	s5,s5,0x3
    80005948:	fc040793          	addi	a5,s0,-64
    8000594c:	9abe                	add	s5,s5,a5
    8000594e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005952:	e4040593          	addi	a1,s0,-448
    80005956:	f4040513          	addi	a0,s0,-192
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	194080e7          	jalr	404(ra) # 80004aee <exec>
    80005962:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005964:	10048993          	addi	s3,s1,256
    80005968:	6088                	ld	a0,0(s1)
    8000596a:	c911                	beqz	a0,8000597e <sys_exec+0xfa>
    kfree(argv[i]);
    8000596c:	ffffb097          	auipc	ra,0xffffb
    80005970:	07e080e7          	jalr	126(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005974:	04a1                	addi	s1,s1,8
    80005976:	ff3499e3          	bne	s1,s3,80005968 <sys_exec+0xe4>
    8000597a:	a011                	j	8000597e <sys_exec+0xfa>
  return -1;
    8000597c:	597d                	li	s2,-1
}
    8000597e:	854a                	mv	a0,s2
    80005980:	60be                	ld	ra,456(sp)
    80005982:	641e                	ld	s0,448(sp)
    80005984:	74fa                	ld	s1,440(sp)
    80005986:	795a                	ld	s2,432(sp)
    80005988:	79ba                	ld	s3,424(sp)
    8000598a:	7a1a                	ld	s4,416(sp)
    8000598c:	6afa                	ld	s5,408(sp)
    8000598e:	6179                	addi	sp,sp,464
    80005990:	8082                	ret

0000000080005992 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005992:	7139                	addi	sp,sp,-64
    80005994:	fc06                	sd	ra,56(sp)
    80005996:	f822                	sd	s0,48(sp)
    80005998:	f426                	sd	s1,40(sp)
    8000599a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000599c:	ffffc097          	auipc	ra,0xffffc
    800059a0:	ff8080e7          	jalr	-8(ra) # 80001994 <myproc>
    800059a4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800059a6:	fd840593          	addi	a1,s0,-40
    800059aa:	4501                	li	a0,0
    800059ac:	ffffd097          	auipc	ra,0xffffd
    800059b0:	0b6080e7          	jalr	182(ra) # 80002a62 <argaddr>
    return -1;
    800059b4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800059b6:	0e054063          	bltz	a0,80005a96 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800059ba:	fc840593          	addi	a1,s0,-56
    800059be:	fd040513          	addi	a0,s0,-48
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	dfc080e7          	jalr	-516(ra) # 800047be <pipealloc>
    return -1;
    800059ca:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800059cc:	0c054563          	bltz	a0,80005a96 <sys_pipe+0x104>
  fd0 = -1;
    800059d0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800059d4:	fd043503          	ld	a0,-48(s0)
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	508080e7          	jalr	1288(ra) # 80004ee0 <fdalloc>
    800059e0:	fca42223          	sw	a0,-60(s0)
    800059e4:	08054c63          	bltz	a0,80005a7c <sys_pipe+0xea>
    800059e8:	fc843503          	ld	a0,-56(s0)
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	4f4080e7          	jalr	1268(ra) # 80004ee0 <fdalloc>
    800059f4:	fca42023          	sw	a0,-64(s0)
    800059f8:	06054863          	bltz	a0,80005a68 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800059fc:	4691                	li	a3,4
    800059fe:	fc440613          	addi	a2,s0,-60
    80005a02:	fd843583          	ld	a1,-40(s0)
    80005a06:	68a8                	ld	a0,80(s1)
    80005a08:	ffffc097          	auipc	ra,0xffffc
    80005a0c:	c4e080e7          	jalr	-946(ra) # 80001656 <copyout>
    80005a10:	02054063          	bltz	a0,80005a30 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005a14:	4691                	li	a3,4
    80005a16:	fc040613          	addi	a2,s0,-64
    80005a1a:	fd843583          	ld	a1,-40(s0)
    80005a1e:	0591                	addi	a1,a1,4
    80005a20:	68a8                	ld	a0,80(s1)
    80005a22:	ffffc097          	auipc	ra,0xffffc
    80005a26:	c34080e7          	jalr	-972(ra) # 80001656 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005a2a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005a2c:	06055563          	bgez	a0,80005a96 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005a30:	fc442783          	lw	a5,-60(s0)
    80005a34:	07e9                	addi	a5,a5,26
    80005a36:	078e                	slli	a5,a5,0x3
    80005a38:	97a6                	add	a5,a5,s1
    80005a3a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005a3e:	fc042503          	lw	a0,-64(s0)
    80005a42:	0569                	addi	a0,a0,26
    80005a44:	050e                	slli	a0,a0,0x3
    80005a46:	9526                	add	a0,a0,s1
    80005a48:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a4c:	fd043503          	ld	a0,-48(s0)
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	a3e080e7          	jalr	-1474(ra) # 8000448e <fileclose>
    fileclose(wf);
    80005a58:	fc843503          	ld	a0,-56(s0)
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	a32080e7          	jalr	-1486(ra) # 8000448e <fileclose>
    return -1;
    80005a64:	57fd                	li	a5,-1
    80005a66:	a805                	j	80005a96 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005a68:	fc442783          	lw	a5,-60(s0)
    80005a6c:	0007c863          	bltz	a5,80005a7c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005a70:	01a78513          	addi	a0,a5,26
    80005a74:	050e                	slli	a0,a0,0x3
    80005a76:	9526                	add	a0,a0,s1
    80005a78:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005a7c:	fd043503          	ld	a0,-48(s0)
    80005a80:	fffff097          	auipc	ra,0xfffff
    80005a84:	a0e080e7          	jalr	-1522(ra) # 8000448e <fileclose>
    fileclose(wf);
    80005a88:	fc843503          	ld	a0,-56(s0)
    80005a8c:	fffff097          	auipc	ra,0xfffff
    80005a90:	a02080e7          	jalr	-1534(ra) # 8000448e <fileclose>
    return -1;
    80005a94:	57fd                	li	a5,-1
}
    80005a96:	853e                	mv	a0,a5
    80005a98:	70e2                	ld	ra,56(sp)
    80005a9a:	7442                	ld	s0,48(sp)
    80005a9c:	74a2                	ld	s1,40(sp)
    80005a9e:	6121                	addi	sp,sp,64
    80005aa0:	8082                	ret
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
