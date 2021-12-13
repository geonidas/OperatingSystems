
user/_time:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/date.h"
#include "user/user.h"
#include "kernel/param.h"

int main (int argc, char *argv[])
{
   0:	7169                	addi	sp,sp,-304
   2:	f606                	sd	ra,296(sp)
   4:	f222                	sd	s0,288(sp)
   6:	ee26                	sd	s1,280(sp)
   8:	ea4a                	sd	s2,272(sp)
   a:	e64e                	sd	s3,264(sp)
   c:	1a00                	addi	s0,sp,304
   e:	84aa                	mv	s1,a0
  10:	892e                	mv	s2,a1
	int startTime = uptime();
  12:	00000097          	auipc	ra,0x0
  16:	3b0080e7          	jalr	944(ra) # 3c2 <uptime>
  1a:	89aa                	mv	s3,a0
	int pid = fork();
  1c:	00000097          	auipc	ra,0x0
  20:	306080e7          	jalr	774(ra) # 322 <fork>
	char* nargv[MAXARG];
	int i;

	for(i = 2; i < argc && i < MAXARG; i++)
  24:	4789                	li	a5,2
  26:	0297d663          	bge	a5,s1,52 <main+0x52>
  2a:	01090793          	addi	a5,s2,16
  2e:	ed040713          	addi	a4,s0,-304
  32:	ffd4869b          	addiw	a3,s1,-3
  36:	1682                	slli	a3,a3,0x20
  38:	9281                	srli	a3,a3,0x20
  3a:	068e                	slli	a3,a3,0x3
  3c:	96be                	add	a3,a3,a5
  3e:	10090813          	addi	a6,s2,256
	{
    	nargv[i-2] = argv[i];
  42:	6390                	ld	a2,0(a5)
  44:	e310                	sd	a2,0(a4)
	for(i = 2; i < argc && i < MAXARG; i++)
  46:	00d78663          	beq	a5,a3,52 <main+0x52>
  4a:	07a1                	addi	a5,a5,8
  4c:	0721                	addi	a4,a4,8
  4e:	ff079ae3          	bne	a5,a6,42 <main+0x42>
  	} 

	if(pid > 0)
  52:	02a04063          	bgtz	a0,72 <main+0x72>
	{
		//printf("parent proc start \n");
		pid = wait((int *) 0);
	}
	else if(pid == 0)
  56:	e531                	bnez	a0,a2 <main+0xa2>
	{
		//printf("child proc start \n");
		exec(argv[1], nargv);
  58:	ed040593          	addi	a1,s0,-304
  5c:	00893503          	ld	a0,8(s2)
  60:	00000097          	auipc	ra,0x0
  64:	302080e7          	jalr	770(ra) # 362 <exec>
		exit(0);
  68:	4501                	li	a0,0
  6a:	00000097          	auipc	ra,0x0
  6e:	2c0080e7          	jalr	704(ra) # 32a <exit>
		pid = wait((int *) 0);
  72:	4501                	li	a0,0
  74:	00000097          	auipc	ra,0x0
  78:	2be080e7          	jalr	702(ra) # 332 <wait>
	else
	{
		printf("fork error\n");
	}
	
	int endtime = uptime();
  7c:	00000097          	auipc	ra,0x0
  80:	346080e7          	jalr	838(ra) # 3c2 <uptime>
	int ticks = (endtime - startTime);
	printf("Real-time in ticks: %d\n", ticks);
  84:	413505bb          	subw	a1,a0,s3
  88:	00000517          	auipc	a0,0x0
  8c:	7e050513          	addi	a0,a0,2016 # 868 <malloc+0xf8>
  90:	00000097          	auipc	ra,0x0
  94:	622080e7          	jalr	1570(ra) # 6b2 <printf>

	exit(0);
  98:	4501                	li	a0,0
  9a:	00000097          	auipc	ra,0x0
  9e:	290080e7          	jalr	656(ra) # 32a <exit>
		printf("fork error\n");
  a2:	00000517          	auipc	a0,0x0
  a6:	7b650513          	addi	a0,a0,1974 # 858 <malloc+0xe8>
  aa:	00000097          	auipc	ra,0x0
  ae:	608080e7          	jalr	1544(ra) # 6b2 <printf>
  b2:	b7e9                	j	7c <main+0x7c>

00000000000000b4 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  b4:	1141                	addi	sp,sp,-16
  b6:	e422                	sd	s0,8(sp)
  b8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  ba:	87aa                	mv	a5,a0
  bc:	0585                	addi	a1,a1,1
  be:	0785                	addi	a5,a5,1
  c0:	fff5c703          	lbu	a4,-1(a1)
  c4:	fee78fa3          	sb	a4,-1(a5)
  c8:	fb75                	bnez	a4,bc <strcpy+0x8>
    ;
  return os;
}
  ca:	6422                	ld	s0,8(sp)
  cc:	0141                	addi	sp,sp,16
  ce:	8082                	ret

00000000000000d0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  d0:	1141                	addi	sp,sp,-16
  d2:	e422                	sd	s0,8(sp)
  d4:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  d6:	00054783          	lbu	a5,0(a0)
  da:	cb91                	beqz	a5,ee <strcmp+0x1e>
  dc:	0005c703          	lbu	a4,0(a1)
  e0:	00f71763          	bne	a4,a5,ee <strcmp+0x1e>
    p++, q++;
  e4:	0505                	addi	a0,a0,1
  e6:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  e8:	00054783          	lbu	a5,0(a0)
  ec:	fbe5                	bnez	a5,dc <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  ee:	0005c503          	lbu	a0,0(a1)
}
  f2:	40a7853b          	subw	a0,a5,a0
  f6:	6422                	ld	s0,8(sp)
  f8:	0141                	addi	sp,sp,16
  fa:	8082                	ret

00000000000000fc <strlen>:

uint
strlen(const char *s)
{
  fc:	1141                	addi	sp,sp,-16
  fe:	e422                	sd	s0,8(sp)
 100:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 102:	00054783          	lbu	a5,0(a0)
 106:	cf91                	beqz	a5,122 <strlen+0x26>
 108:	0505                	addi	a0,a0,1
 10a:	87aa                	mv	a5,a0
 10c:	4685                	li	a3,1
 10e:	9e89                	subw	a3,a3,a0
 110:	00f6853b          	addw	a0,a3,a5
 114:	0785                	addi	a5,a5,1
 116:	fff7c703          	lbu	a4,-1(a5)
 11a:	fb7d                	bnez	a4,110 <strlen+0x14>
    ;
  return n;
}
 11c:	6422                	ld	s0,8(sp)
 11e:	0141                	addi	sp,sp,16
 120:	8082                	ret
  for(n = 0; s[n]; n++)
 122:	4501                	li	a0,0
 124:	bfe5                	j	11c <strlen+0x20>

0000000000000126 <memset>:

void*
memset(void *dst, int c, uint n)
{
 126:	1141                	addi	sp,sp,-16
 128:	e422                	sd	s0,8(sp)
 12a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 12c:	ce09                	beqz	a2,146 <memset+0x20>
 12e:	87aa                	mv	a5,a0
 130:	fff6071b          	addiw	a4,a2,-1
 134:	1702                	slli	a4,a4,0x20
 136:	9301                	srli	a4,a4,0x20
 138:	0705                	addi	a4,a4,1
 13a:	972a                	add	a4,a4,a0
    cdst[i] = c;
 13c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 140:	0785                	addi	a5,a5,1
 142:	fee79de3          	bne	a5,a4,13c <memset+0x16>
  }
  return dst;
}
 146:	6422                	ld	s0,8(sp)
 148:	0141                	addi	sp,sp,16
 14a:	8082                	ret

000000000000014c <strchr>:

char*
strchr(const char *s, char c)
{
 14c:	1141                	addi	sp,sp,-16
 14e:	e422                	sd	s0,8(sp)
 150:	0800                	addi	s0,sp,16
  for(; *s; s++)
 152:	00054783          	lbu	a5,0(a0)
 156:	cb99                	beqz	a5,16c <strchr+0x20>
    if(*s == c)
 158:	00f58763          	beq	a1,a5,166 <strchr+0x1a>
  for(; *s; s++)
 15c:	0505                	addi	a0,a0,1
 15e:	00054783          	lbu	a5,0(a0)
 162:	fbfd                	bnez	a5,158 <strchr+0xc>
      return (char*)s;
  return 0;
 164:	4501                	li	a0,0
}
 166:	6422                	ld	s0,8(sp)
 168:	0141                	addi	sp,sp,16
 16a:	8082                	ret
  return 0;
 16c:	4501                	li	a0,0
 16e:	bfe5                	j	166 <strchr+0x1a>

0000000000000170 <gets>:

char*
gets(char *buf, int max)
{
 170:	711d                	addi	sp,sp,-96
 172:	ec86                	sd	ra,88(sp)
 174:	e8a2                	sd	s0,80(sp)
 176:	e4a6                	sd	s1,72(sp)
 178:	e0ca                	sd	s2,64(sp)
 17a:	fc4e                	sd	s3,56(sp)
 17c:	f852                	sd	s4,48(sp)
 17e:	f456                	sd	s5,40(sp)
 180:	f05a                	sd	s6,32(sp)
 182:	ec5e                	sd	s7,24(sp)
 184:	1080                	addi	s0,sp,96
 186:	8baa                	mv	s7,a0
 188:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 18a:	892a                	mv	s2,a0
 18c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 18e:	4aa9                	li	s5,10
 190:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 192:	89a6                	mv	s3,s1
 194:	2485                	addiw	s1,s1,1
 196:	0344d863          	bge	s1,s4,1c6 <gets+0x56>
    cc = read(0, &c, 1);
 19a:	4605                	li	a2,1
 19c:	faf40593          	addi	a1,s0,-81
 1a0:	4501                	li	a0,0
 1a2:	00000097          	auipc	ra,0x0
 1a6:	1a0080e7          	jalr	416(ra) # 342 <read>
    if(cc < 1)
 1aa:	00a05e63          	blez	a0,1c6 <gets+0x56>
    buf[i++] = c;
 1ae:	faf44783          	lbu	a5,-81(s0)
 1b2:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1b6:	01578763          	beq	a5,s5,1c4 <gets+0x54>
 1ba:	0905                	addi	s2,s2,1
 1bc:	fd679be3          	bne	a5,s6,192 <gets+0x22>
  for(i=0; i+1 < max; ){
 1c0:	89a6                	mv	s3,s1
 1c2:	a011                	j	1c6 <gets+0x56>
 1c4:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1c6:	99de                	add	s3,s3,s7
 1c8:	00098023          	sb	zero,0(s3)
  return buf;
}
 1cc:	855e                	mv	a0,s7
 1ce:	60e6                	ld	ra,88(sp)
 1d0:	6446                	ld	s0,80(sp)
 1d2:	64a6                	ld	s1,72(sp)
 1d4:	6906                	ld	s2,64(sp)
 1d6:	79e2                	ld	s3,56(sp)
 1d8:	7a42                	ld	s4,48(sp)
 1da:	7aa2                	ld	s5,40(sp)
 1dc:	7b02                	ld	s6,32(sp)
 1de:	6be2                	ld	s7,24(sp)
 1e0:	6125                	addi	sp,sp,96
 1e2:	8082                	ret

00000000000001e4 <stat>:

int
stat(const char *n, struct stat *st)
{
 1e4:	1101                	addi	sp,sp,-32
 1e6:	ec06                	sd	ra,24(sp)
 1e8:	e822                	sd	s0,16(sp)
 1ea:	e426                	sd	s1,8(sp)
 1ec:	e04a                	sd	s2,0(sp)
 1ee:	1000                	addi	s0,sp,32
 1f0:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1f2:	4581                	li	a1,0
 1f4:	00000097          	auipc	ra,0x0
 1f8:	176080e7          	jalr	374(ra) # 36a <open>
  if(fd < 0)
 1fc:	02054563          	bltz	a0,226 <stat+0x42>
 200:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 202:	85ca                	mv	a1,s2
 204:	00000097          	auipc	ra,0x0
 208:	17e080e7          	jalr	382(ra) # 382 <fstat>
 20c:	892a                	mv	s2,a0
  close(fd);
 20e:	8526                	mv	a0,s1
 210:	00000097          	auipc	ra,0x0
 214:	142080e7          	jalr	322(ra) # 352 <close>
  return r;
}
 218:	854a                	mv	a0,s2
 21a:	60e2                	ld	ra,24(sp)
 21c:	6442                	ld	s0,16(sp)
 21e:	64a2                	ld	s1,8(sp)
 220:	6902                	ld	s2,0(sp)
 222:	6105                	addi	sp,sp,32
 224:	8082                	ret
    return -1;
 226:	597d                	li	s2,-1
 228:	bfc5                	j	218 <stat+0x34>

000000000000022a <atoi>:

int
atoi(const char *s)
{
 22a:	1141                	addi	sp,sp,-16
 22c:	e422                	sd	s0,8(sp)
 22e:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 230:	00054603          	lbu	a2,0(a0)
 234:	fd06079b          	addiw	a5,a2,-48
 238:	0ff7f793          	andi	a5,a5,255
 23c:	4725                	li	a4,9
 23e:	02f76963          	bltu	a4,a5,270 <atoi+0x46>
 242:	86aa                	mv	a3,a0
  n = 0;
 244:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 246:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 248:	0685                	addi	a3,a3,1
 24a:	0025179b          	slliw	a5,a0,0x2
 24e:	9fa9                	addw	a5,a5,a0
 250:	0017979b          	slliw	a5,a5,0x1
 254:	9fb1                	addw	a5,a5,a2
 256:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 25a:	0006c603          	lbu	a2,0(a3)
 25e:	fd06071b          	addiw	a4,a2,-48
 262:	0ff77713          	andi	a4,a4,255
 266:	fee5f1e3          	bgeu	a1,a4,248 <atoi+0x1e>
  return n;
}
 26a:	6422                	ld	s0,8(sp)
 26c:	0141                	addi	sp,sp,16
 26e:	8082                	ret
  n = 0;
 270:	4501                	li	a0,0
 272:	bfe5                	j	26a <atoi+0x40>

0000000000000274 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 274:	1141                	addi	sp,sp,-16
 276:	e422                	sd	s0,8(sp)
 278:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 27a:	02b57663          	bgeu	a0,a1,2a6 <memmove+0x32>
    while(n-- > 0)
 27e:	02c05163          	blez	a2,2a0 <memmove+0x2c>
 282:	fff6079b          	addiw	a5,a2,-1
 286:	1782                	slli	a5,a5,0x20
 288:	9381                	srli	a5,a5,0x20
 28a:	0785                	addi	a5,a5,1
 28c:	97aa                	add	a5,a5,a0
  dst = vdst;
 28e:	872a                	mv	a4,a0
      *dst++ = *src++;
 290:	0585                	addi	a1,a1,1
 292:	0705                	addi	a4,a4,1
 294:	fff5c683          	lbu	a3,-1(a1)
 298:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 29c:	fee79ae3          	bne	a5,a4,290 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2a0:	6422                	ld	s0,8(sp)
 2a2:	0141                	addi	sp,sp,16
 2a4:	8082                	ret
    dst += n;
 2a6:	00c50733          	add	a4,a0,a2
    src += n;
 2aa:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2ac:	fec05ae3          	blez	a2,2a0 <memmove+0x2c>
 2b0:	fff6079b          	addiw	a5,a2,-1
 2b4:	1782                	slli	a5,a5,0x20
 2b6:	9381                	srli	a5,a5,0x20
 2b8:	fff7c793          	not	a5,a5
 2bc:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2be:	15fd                	addi	a1,a1,-1
 2c0:	177d                	addi	a4,a4,-1
 2c2:	0005c683          	lbu	a3,0(a1)
 2c6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2ca:	fee79ae3          	bne	a5,a4,2be <memmove+0x4a>
 2ce:	bfc9                	j	2a0 <memmove+0x2c>

00000000000002d0 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2d0:	1141                	addi	sp,sp,-16
 2d2:	e422                	sd	s0,8(sp)
 2d4:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2d6:	ca05                	beqz	a2,306 <memcmp+0x36>
 2d8:	fff6069b          	addiw	a3,a2,-1
 2dc:	1682                	slli	a3,a3,0x20
 2de:	9281                	srli	a3,a3,0x20
 2e0:	0685                	addi	a3,a3,1
 2e2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2e4:	00054783          	lbu	a5,0(a0)
 2e8:	0005c703          	lbu	a4,0(a1)
 2ec:	00e79863          	bne	a5,a4,2fc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2f0:	0505                	addi	a0,a0,1
    p2++;
 2f2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2f4:	fed518e3          	bne	a0,a3,2e4 <memcmp+0x14>
  }
  return 0;
 2f8:	4501                	li	a0,0
 2fa:	a019                	j	300 <memcmp+0x30>
      return *p1 - *p2;
 2fc:	40e7853b          	subw	a0,a5,a4
}
 300:	6422                	ld	s0,8(sp)
 302:	0141                	addi	sp,sp,16
 304:	8082                	ret
  return 0;
 306:	4501                	li	a0,0
 308:	bfe5                	j	300 <memcmp+0x30>

000000000000030a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 30a:	1141                	addi	sp,sp,-16
 30c:	e406                	sd	ra,8(sp)
 30e:	e022                	sd	s0,0(sp)
 310:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 312:	00000097          	auipc	ra,0x0
 316:	f62080e7          	jalr	-158(ra) # 274 <memmove>
}
 31a:	60a2                	ld	ra,8(sp)
 31c:	6402                	ld	s0,0(sp)
 31e:	0141                	addi	sp,sp,16
 320:	8082                	ret

0000000000000322 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 322:	4885                	li	a7,1
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <exit>:
.global exit
exit:
 li a7, SYS_exit
 32a:	4889                	li	a7,2
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <wait>:
.global wait
wait:
 li a7, SYS_wait
 332:	488d                	li	a7,3
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 33a:	4891                	li	a7,4
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <read>:
.global read
read:
 li a7, SYS_read
 342:	4895                	li	a7,5
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <write>:
.global write
write:
 li a7, SYS_write
 34a:	48c1                	li	a7,16
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <close>:
.global close
close:
 li a7, SYS_close
 352:	48d5                	li	a7,21
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <kill>:
.global kill
kill:
 li a7, SYS_kill
 35a:	4899                	li	a7,6
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <exec>:
.global exec
exec:
 li a7, SYS_exec
 362:	489d                	li	a7,7
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <open>:
.global open
open:
 li a7, SYS_open
 36a:	48bd                	li	a7,15
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 372:	48c5                	li	a7,17
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 37a:	48c9                	li	a7,18
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 382:	48a1                	li	a7,8
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <link>:
.global link
link:
 li a7, SYS_link
 38a:	48cd                	li	a7,19
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 392:	48d1                	li	a7,20
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 39a:	48a5                	li	a7,9
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3a2:	48a9                	li	a7,10
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3aa:	48ad                	li	a7,11
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3b2:	48b1                	li	a7,12
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3ba:	48b5                	li	a7,13
 ecall
 3bc:	00000073          	ecall
 ret
 3c0:	8082                	ret

00000000000003c2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3c2:	48b9                	li	a7,14
 ecall
 3c4:	00000073          	ecall
 ret
 3c8:	8082                	ret

00000000000003ca <time>:
.global time
time:
 li a7, SYS_time
 3ca:	48d9                	li	a7,22
 ecall
 3cc:	00000073          	ecall
 ret
 3d0:	8082                	ret

00000000000003d2 <trace>:
.global trace
trace:
 li a7, SYS_trace
 3d2:	48dd                	li	a7,23
 ecall
 3d4:	00000073          	ecall
 ret
 3d8:	8082                	ret

00000000000003da <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3da:	1101                	addi	sp,sp,-32
 3dc:	ec06                	sd	ra,24(sp)
 3de:	e822                	sd	s0,16(sp)
 3e0:	1000                	addi	s0,sp,32
 3e2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3e6:	4605                	li	a2,1
 3e8:	fef40593          	addi	a1,s0,-17
 3ec:	00000097          	auipc	ra,0x0
 3f0:	f5e080e7          	jalr	-162(ra) # 34a <write>
}
 3f4:	60e2                	ld	ra,24(sp)
 3f6:	6442                	ld	s0,16(sp)
 3f8:	6105                	addi	sp,sp,32
 3fa:	8082                	ret

00000000000003fc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3fc:	7139                	addi	sp,sp,-64
 3fe:	fc06                	sd	ra,56(sp)
 400:	f822                	sd	s0,48(sp)
 402:	f426                	sd	s1,40(sp)
 404:	f04a                	sd	s2,32(sp)
 406:	ec4e                	sd	s3,24(sp)
 408:	0080                	addi	s0,sp,64
 40a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 40c:	c299                	beqz	a3,412 <printint+0x16>
 40e:	0805c863          	bltz	a1,49e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 412:	2581                	sext.w	a1,a1
  neg = 0;
 414:	4881                	li	a7,0
 416:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 41a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 41c:	2601                	sext.w	a2,a2
 41e:	00000517          	auipc	a0,0x0
 422:	46a50513          	addi	a0,a0,1130 # 888 <digits>
 426:	883a                	mv	a6,a4
 428:	2705                	addiw	a4,a4,1
 42a:	02c5f7bb          	remuw	a5,a1,a2
 42e:	1782                	slli	a5,a5,0x20
 430:	9381                	srli	a5,a5,0x20
 432:	97aa                	add	a5,a5,a0
 434:	0007c783          	lbu	a5,0(a5)
 438:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 43c:	0005879b          	sext.w	a5,a1
 440:	02c5d5bb          	divuw	a1,a1,a2
 444:	0685                	addi	a3,a3,1
 446:	fec7f0e3          	bgeu	a5,a2,426 <printint+0x2a>
  if(neg)
 44a:	00088b63          	beqz	a7,460 <printint+0x64>
    buf[i++] = '-';
 44e:	fd040793          	addi	a5,s0,-48
 452:	973e                	add	a4,a4,a5
 454:	02d00793          	li	a5,45
 458:	fef70823          	sb	a5,-16(a4)
 45c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 460:	02e05863          	blez	a4,490 <printint+0x94>
 464:	fc040793          	addi	a5,s0,-64
 468:	00e78933          	add	s2,a5,a4
 46c:	fff78993          	addi	s3,a5,-1
 470:	99ba                	add	s3,s3,a4
 472:	377d                	addiw	a4,a4,-1
 474:	1702                	slli	a4,a4,0x20
 476:	9301                	srli	a4,a4,0x20
 478:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 47c:	fff94583          	lbu	a1,-1(s2)
 480:	8526                	mv	a0,s1
 482:	00000097          	auipc	ra,0x0
 486:	f58080e7          	jalr	-168(ra) # 3da <putc>
  while(--i >= 0)
 48a:	197d                	addi	s2,s2,-1
 48c:	ff3918e3          	bne	s2,s3,47c <printint+0x80>
}
 490:	70e2                	ld	ra,56(sp)
 492:	7442                	ld	s0,48(sp)
 494:	74a2                	ld	s1,40(sp)
 496:	7902                	ld	s2,32(sp)
 498:	69e2                	ld	s3,24(sp)
 49a:	6121                	addi	sp,sp,64
 49c:	8082                	ret
    x = -xx;
 49e:	40b005bb          	negw	a1,a1
    neg = 1;
 4a2:	4885                	li	a7,1
    x = -xx;
 4a4:	bf8d                	j	416 <printint+0x1a>

00000000000004a6 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4a6:	7119                	addi	sp,sp,-128
 4a8:	fc86                	sd	ra,120(sp)
 4aa:	f8a2                	sd	s0,112(sp)
 4ac:	f4a6                	sd	s1,104(sp)
 4ae:	f0ca                	sd	s2,96(sp)
 4b0:	ecce                	sd	s3,88(sp)
 4b2:	e8d2                	sd	s4,80(sp)
 4b4:	e4d6                	sd	s5,72(sp)
 4b6:	e0da                	sd	s6,64(sp)
 4b8:	fc5e                	sd	s7,56(sp)
 4ba:	f862                	sd	s8,48(sp)
 4bc:	f466                	sd	s9,40(sp)
 4be:	f06a                	sd	s10,32(sp)
 4c0:	ec6e                	sd	s11,24(sp)
 4c2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4c4:	0005c903          	lbu	s2,0(a1)
 4c8:	18090f63          	beqz	s2,666 <vprintf+0x1c0>
 4cc:	8aaa                	mv	s5,a0
 4ce:	8b32                	mv	s6,a2
 4d0:	00158493          	addi	s1,a1,1
  state = 0;
 4d4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4d6:	02500a13          	li	s4,37
      if(c == 'd'){
 4da:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4de:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4e2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4e6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4ea:	00000b97          	auipc	s7,0x0
 4ee:	39eb8b93          	addi	s7,s7,926 # 888 <digits>
 4f2:	a839                	j	510 <vprintf+0x6a>
        putc(fd, c);
 4f4:	85ca                	mv	a1,s2
 4f6:	8556                	mv	a0,s5
 4f8:	00000097          	auipc	ra,0x0
 4fc:	ee2080e7          	jalr	-286(ra) # 3da <putc>
 500:	a019                	j	506 <vprintf+0x60>
    } else if(state == '%'){
 502:	01498f63          	beq	s3,s4,520 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 506:	0485                	addi	s1,s1,1
 508:	fff4c903          	lbu	s2,-1(s1)
 50c:	14090d63          	beqz	s2,666 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 510:	0009079b          	sext.w	a5,s2
    if(state == 0){
 514:	fe0997e3          	bnez	s3,502 <vprintf+0x5c>
      if(c == '%'){
 518:	fd479ee3          	bne	a5,s4,4f4 <vprintf+0x4e>
        state = '%';
 51c:	89be                	mv	s3,a5
 51e:	b7e5                	j	506 <vprintf+0x60>
      if(c == 'd'){
 520:	05878063          	beq	a5,s8,560 <vprintf+0xba>
      } else if(c == 'l') {
 524:	05978c63          	beq	a5,s9,57c <vprintf+0xd6>
      } else if(c == 'x') {
 528:	07a78863          	beq	a5,s10,598 <vprintf+0xf2>
      } else if(c == 'p') {
 52c:	09b78463          	beq	a5,s11,5b4 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 530:	07300713          	li	a4,115
 534:	0ce78663          	beq	a5,a4,600 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 538:	06300713          	li	a4,99
 53c:	0ee78e63          	beq	a5,a4,638 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 540:	11478863          	beq	a5,s4,650 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 544:	85d2                	mv	a1,s4
 546:	8556                	mv	a0,s5
 548:	00000097          	auipc	ra,0x0
 54c:	e92080e7          	jalr	-366(ra) # 3da <putc>
        putc(fd, c);
 550:	85ca                	mv	a1,s2
 552:	8556                	mv	a0,s5
 554:	00000097          	auipc	ra,0x0
 558:	e86080e7          	jalr	-378(ra) # 3da <putc>
      }
      state = 0;
 55c:	4981                	li	s3,0
 55e:	b765                	j	506 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 560:	008b0913          	addi	s2,s6,8
 564:	4685                	li	a3,1
 566:	4629                	li	a2,10
 568:	000b2583          	lw	a1,0(s6)
 56c:	8556                	mv	a0,s5
 56e:	00000097          	auipc	ra,0x0
 572:	e8e080e7          	jalr	-370(ra) # 3fc <printint>
 576:	8b4a                	mv	s6,s2
      state = 0;
 578:	4981                	li	s3,0
 57a:	b771                	j	506 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 57c:	008b0913          	addi	s2,s6,8
 580:	4681                	li	a3,0
 582:	4629                	li	a2,10
 584:	000b2583          	lw	a1,0(s6)
 588:	8556                	mv	a0,s5
 58a:	00000097          	auipc	ra,0x0
 58e:	e72080e7          	jalr	-398(ra) # 3fc <printint>
 592:	8b4a                	mv	s6,s2
      state = 0;
 594:	4981                	li	s3,0
 596:	bf85                	j	506 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 598:	008b0913          	addi	s2,s6,8
 59c:	4681                	li	a3,0
 59e:	4641                	li	a2,16
 5a0:	000b2583          	lw	a1,0(s6)
 5a4:	8556                	mv	a0,s5
 5a6:	00000097          	auipc	ra,0x0
 5aa:	e56080e7          	jalr	-426(ra) # 3fc <printint>
 5ae:	8b4a                	mv	s6,s2
      state = 0;
 5b0:	4981                	li	s3,0
 5b2:	bf91                	j	506 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5b4:	008b0793          	addi	a5,s6,8
 5b8:	f8f43423          	sd	a5,-120(s0)
 5bc:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5c0:	03000593          	li	a1,48
 5c4:	8556                	mv	a0,s5
 5c6:	00000097          	auipc	ra,0x0
 5ca:	e14080e7          	jalr	-492(ra) # 3da <putc>
  putc(fd, 'x');
 5ce:	85ea                	mv	a1,s10
 5d0:	8556                	mv	a0,s5
 5d2:	00000097          	auipc	ra,0x0
 5d6:	e08080e7          	jalr	-504(ra) # 3da <putc>
 5da:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5dc:	03c9d793          	srli	a5,s3,0x3c
 5e0:	97de                	add	a5,a5,s7
 5e2:	0007c583          	lbu	a1,0(a5)
 5e6:	8556                	mv	a0,s5
 5e8:	00000097          	auipc	ra,0x0
 5ec:	df2080e7          	jalr	-526(ra) # 3da <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5f0:	0992                	slli	s3,s3,0x4
 5f2:	397d                	addiw	s2,s2,-1
 5f4:	fe0914e3          	bnez	s2,5dc <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5f8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5fc:	4981                	li	s3,0
 5fe:	b721                	j	506 <vprintf+0x60>
        s = va_arg(ap, char*);
 600:	008b0993          	addi	s3,s6,8
 604:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 608:	02090163          	beqz	s2,62a <vprintf+0x184>
        while(*s != 0){
 60c:	00094583          	lbu	a1,0(s2)
 610:	c9a1                	beqz	a1,660 <vprintf+0x1ba>
          putc(fd, *s);
 612:	8556                	mv	a0,s5
 614:	00000097          	auipc	ra,0x0
 618:	dc6080e7          	jalr	-570(ra) # 3da <putc>
          s++;
 61c:	0905                	addi	s2,s2,1
        while(*s != 0){
 61e:	00094583          	lbu	a1,0(s2)
 622:	f9e5                	bnez	a1,612 <vprintf+0x16c>
        s = va_arg(ap, char*);
 624:	8b4e                	mv	s6,s3
      state = 0;
 626:	4981                	li	s3,0
 628:	bdf9                	j	506 <vprintf+0x60>
          s = "(null)";
 62a:	00000917          	auipc	s2,0x0
 62e:	25690913          	addi	s2,s2,598 # 880 <malloc+0x110>
        while(*s != 0){
 632:	02800593          	li	a1,40
 636:	bff1                	j	612 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 638:	008b0913          	addi	s2,s6,8
 63c:	000b4583          	lbu	a1,0(s6)
 640:	8556                	mv	a0,s5
 642:	00000097          	auipc	ra,0x0
 646:	d98080e7          	jalr	-616(ra) # 3da <putc>
 64a:	8b4a                	mv	s6,s2
      state = 0;
 64c:	4981                	li	s3,0
 64e:	bd65                	j	506 <vprintf+0x60>
        putc(fd, c);
 650:	85d2                	mv	a1,s4
 652:	8556                	mv	a0,s5
 654:	00000097          	auipc	ra,0x0
 658:	d86080e7          	jalr	-634(ra) # 3da <putc>
      state = 0;
 65c:	4981                	li	s3,0
 65e:	b565                	j	506 <vprintf+0x60>
        s = va_arg(ap, char*);
 660:	8b4e                	mv	s6,s3
      state = 0;
 662:	4981                	li	s3,0
 664:	b54d                	j	506 <vprintf+0x60>
    }
  }
}
 666:	70e6                	ld	ra,120(sp)
 668:	7446                	ld	s0,112(sp)
 66a:	74a6                	ld	s1,104(sp)
 66c:	7906                	ld	s2,96(sp)
 66e:	69e6                	ld	s3,88(sp)
 670:	6a46                	ld	s4,80(sp)
 672:	6aa6                	ld	s5,72(sp)
 674:	6b06                	ld	s6,64(sp)
 676:	7be2                	ld	s7,56(sp)
 678:	7c42                	ld	s8,48(sp)
 67a:	7ca2                	ld	s9,40(sp)
 67c:	7d02                	ld	s10,32(sp)
 67e:	6de2                	ld	s11,24(sp)
 680:	6109                	addi	sp,sp,128
 682:	8082                	ret

0000000000000684 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 684:	715d                	addi	sp,sp,-80
 686:	ec06                	sd	ra,24(sp)
 688:	e822                	sd	s0,16(sp)
 68a:	1000                	addi	s0,sp,32
 68c:	e010                	sd	a2,0(s0)
 68e:	e414                	sd	a3,8(s0)
 690:	e818                	sd	a4,16(s0)
 692:	ec1c                	sd	a5,24(s0)
 694:	03043023          	sd	a6,32(s0)
 698:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 69c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6a0:	8622                	mv	a2,s0
 6a2:	00000097          	auipc	ra,0x0
 6a6:	e04080e7          	jalr	-508(ra) # 4a6 <vprintf>
}
 6aa:	60e2                	ld	ra,24(sp)
 6ac:	6442                	ld	s0,16(sp)
 6ae:	6161                	addi	sp,sp,80
 6b0:	8082                	ret

00000000000006b2 <printf>:

void
printf(const char *fmt, ...)
{
 6b2:	711d                	addi	sp,sp,-96
 6b4:	ec06                	sd	ra,24(sp)
 6b6:	e822                	sd	s0,16(sp)
 6b8:	1000                	addi	s0,sp,32
 6ba:	e40c                	sd	a1,8(s0)
 6bc:	e810                	sd	a2,16(s0)
 6be:	ec14                	sd	a3,24(s0)
 6c0:	f018                	sd	a4,32(s0)
 6c2:	f41c                	sd	a5,40(s0)
 6c4:	03043823          	sd	a6,48(s0)
 6c8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6cc:	00840613          	addi	a2,s0,8
 6d0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6d4:	85aa                	mv	a1,a0
 6d6:	4505                	li	a0,1
 6d8:	00000097          	auipc	ra,0x0
 6dc:	dce080e7          	jalr	-562(ra) # 4a6 <vprintf>
}
 6e0:	60e2                	ld	ra,24(sp)
 6e2:	6442                	ld	s0,16(sp)
 6e4:	6125                	addi	sp,sp,96
 6e6:	8082                	ret

00000000000006e8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6e8:	1141                	addi	sp,sp,-16
 6ea:	e422                	sd	s0,8(sp)
 6ec:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6ee:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6f2:	00000797          	auipc	a5,0x0
 6f6:	1ae7b783          	ld	a5,430(a5) # 8a0 <freep>
 6fa:	a805                	j	72a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6fc:	4618                	lw	a4,8(a2)
 6fe:	9db9                	addw	a1,a1,a4
 700:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 704:	6398                	ld	a4,0(a5)
 706:	6318                	ld	a4,0(a4)
 708:	fee53823          	sd	a4,-16(a0)
 70c:	a091                	j	750 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 70e:	ff852703          	lw	a4,-8(a0)
 712:	9e39                	addw	a2,a2,a4
 714:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 716:	ff053703          	ld	a4,-16(a0)
 71a:	e398                	sd	a4,0(a5)
 71c:	a099                	j	762 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 71e:	6398                	ld	a4,0(a5)
 720:	00e7e463          	bltu	a5,a4,728 <free+0x40>
 724:	00e6ea63          	bltu	a3,a4,738 <free+0x50>
{
 728:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 72a:	fed7fae3          	bgeu	a5,a3,71e <free+0x36>
 72e:	6398                	ld	a4,0(a5)
 730:	00e6e463          	bltu	a3,a4,738 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 734:	fee7eae3          	bltu	a5,a4,728 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 738:	ff852583          	lw	a1,-8(a0)
 73c:	6390                	ld	a2,0(a5)
 73e:	02059713          	slli	a4,a1,0x20
 742:	9301                	srli	a4,a4,0x20
 744:	0712                	slli	a4,a4,0x4
 746:	9736                	add	a4,a4,a3
 748:	fae60ae3          	beq	a2,a4,6fc <free+0x14>
    bp->s.ptr = p->s.ptr;
 74c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 750:	4790                	lw	a2,8(a5)
 752:	02061713          	slli	a4,a2,0x20
 756:	9301                	srli	a4,a4,0x20
 758:	0712                	slli	a4,a4,0x4
 75a:	973e                	add	a4,a4,a5
 75c:	fae689e3          	beq	a3,a4,70e <free+0x26>
  } else
    p->s.ptr = bp;
 760:	e394                	sd	a3,0(a5)
  freep = p;
 762:	00000717          	auipc	a4,0x0
 766:	12f73f23          	sd	a5,318(a4) # 8a0 <freep>
}
 76a:	6422                	ld	s0,8(sp)
 76c:	0141                	addi	sp,sp,16
 76e:	8082                	ret

0000000000000770 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 770:	7139                	addi	sp,sp,-64
 772:	fc06                	sd	ra,56(sp)
 774:	f822                	sd	s0,48(sp)
 776:	f426                	sd	s1,40(sp)
 778:	f04a                	sd	s2,32(sp)
 77a:	ec4e                	sd	s3,24(sp)
 77c:	e852                	sd	s4,16(sp)
 77e:	e456                	sd	s5,8(sp)
 780:	e05a                	sd	s6,0(sp)
 782:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 784:	02051493          	slli	s1,a0,0x20
 788:	9081                	srli	s1,s1,0x20
 78a:	04bd                	addi	s1,s1,15
 78c:	8091                	srli	s1,s1,0x4
 78e:	0014899b          	addiw	s3,s1,1
 792:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 794:	00000517          	auipc	a0,0x0
 798:	10c53503          	ld	a0,268(a0) # 8a0 <freep>
 79c:	c515                	beqz	a0,7c8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 79e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7a0:	4798                	lw	a4,8(a5)
 7a2:	02977f63          	bgeu	a4,s1,7e0 <malloc+0x70>
 7a6:	8a4e                	mv	s4,s3
 7a8:	0009871b          	sext.w	a4,s3
 7ac:	6685                	lui	a3,0x1
 7ae:	00d77363          	bgeu	a4,a3,7b4 <malloc+0x44>
 7b2:	6a05                	lui	s4,0x1
 7b4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7b8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7bc:	00000917          	auipc	s2,0x0
 7c0:	0e490913          	addi	s2,s2,228 # 8a0 <freep>
  if(p == (char*)-1)
 7c4:	5afd                	li	s5,-1
 7c6:	a88d                	j	838 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7c8:	00000797          	auipc	a5,0x0
 7cc:	0e078793          	addi	a5,a5,224 # 8a8 <base>
 7d0:	00000717          	auipc	a4,0x0
 7d4:	0cf73823          	sd	a5,208(a4) # 8a0 <freep>
 7d8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7da:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7de:	b7e1                	j	7a6 <malloc+0x36>
      if(p->s.size == nunits)
 7e0:	02e48b63          	beq	s1,a4,816 <malloc+0xa6>
        p->s.size -= nunits;
 7e4:	4137073b          	subw	a4,a4,s3
 7e8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7ea:	1702                	slli	a4,a4,0x20
 7ec:	9301                	srli	a4,a4,0x20
 7ee:	0712                	slli	a4,a4,0x4
 7f0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7f2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7f6:	00000717          	auipc	a4,0x0
 7fa:	0aa73523          	sd	a0,170(a4) # 8a0 <freep>
      return (void*)(p + 1);
 7fe:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 802:	70e2                	ld	ra,56(sp)
 804:	7442                	ld	s0,48(sp)
 806:	74a2                	ld	s1,40(sp)
 808:	7902                	ld	s2,32(sp)
 80a:	69e2                	ld	s3,24(sp)
 80c:	6a42                	ld	s4,16(sp)
 80e:	6aa2                	ld	s5,8(sp)
 810:	6b02                	ld	s6,0(sp)
 812:	6121                	addi	sp,sp,64
 814:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 816:	6398                	ld	a4,0(a5)
 818:	e118                	sd	a4,0(a0)
 81a:	bff1                	j	7f6 <malloc+0x86>
  hp->s.size = nu;
 81c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 820:	0541                	addi	a0,a0,16
 822:	00000097          	auipc	ra,0x0
 826:	ec6080e7          	jalr	-314(ra) # 6e8 <free>
  return freep;
 82a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 82e:	d971                	beqz	a0,802 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 830:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 832:	4798                	lw	a4,8(a5)
 834:	fa9776e3          	bgeu	a4,s1,7e0 <malloc+0x70>
    if(p == freep)
 838:	00093703          	ld	a4,0(s2)
 83c:	853e                	mv	a0,a5
 83e:	fef719e3          	bne	a4,a5,830 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 842:	8552                	mv	a0,s4
 844:	00000097          	auipc	ra,0x0
 848:	b6e080e7          	jalr	-1170(ra) # 3b2 <sbrk>
  if(p == (char*)-1)
 84c:	fd5518e3          	bne	a0,s5,81c <malloc+0xac>
        return 0;
 850:	4501                	li	a0,0
 852:	bf45                	j	802 <malloc+0x92>
