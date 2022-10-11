
user/_sysinfotest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <sinfo>:
#include "user/user.h"
#include "kernel/fcntl.h"


void
sinfo(struct sysinfo *info) {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
  if (sysinfo(info) < 0) {
   8:	00000097          	auipc	ra,0x0
   c:	746080e7          	jalr	1862(ra) # 74e <sysinfo>
  10:	00054663          	bltz	a0,1c <sinfo+0x1c>
    printf("FAIL: sysinfo failed");
    exit(1);
  }
}
  14:	60a2                	ld	ra,8(sp)
  16:	6402                	ld	s0,0(sp)
  18:	0141                	addi	sp,sp,16
  1a:	8082                	ret
    printf("FAIL: sysinfo failed");
  1c:	00001517          	auipc	a0,0x1
  20:	bb450513          	addi	a0,a0,-1100 # bd0 <malloc+0xe4>
  24:	00001097          	auipc	ra,0x1
  28:	a0a080e7          	jalr	-1526(ra) # a2e <printf>
    exit(1);
  2c:	4505                	li	a0,1
  2e:	00000097          	auipc	ra,0x0
  32:	678080e7          	jalr	1656(ra) # 6a6 <exit>

0000000000000036 <countfree>:
//
// use sbrk() to count how many free physical memory pages there are.
//
int
countfree()
{
  36:	715d                	addi	sp,sp,-80
  38:	e486                	sd	ra,72(sp)
  3a:	e0a2                	sd	s0,64(sp)
  3c:	fc26                	sd	s1,56(sp)
  3e:	f84a                	sd	s2,48(sp)
  40:	f44e                	sd	s3,40(sp)
  42:	f052                	sd	s4,32(sp)
  44:	0880                	addi	s0,sp,80
  uint64 sz0 = (uint64)sbrk(0);
  46:	4501                	li	a0,0
  48:	00000097          	auipc	ra,0x0
  4c:	6e6080e7          	jalr	1766(ra) # 72e <sbrk>
  50:	8a2a                	mv	s4,a0
  struct sysinfo info;
  int n = 0;
  52:	4481                	li	s1,0

  while(1){
    if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  54:	597d                	li	s2,-1
      break;
    }
    n += PGSIZE;
  56:	6985                	lui	s3,0x1
  58:	a019                	j	5e <countfree+0x28>
  5a:	009984bb          	addw	s1,s3,s1
    if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  5e:	6505                	lui	a0,0x1
  60:	00000097          	auipc	ra,0x0
  64:	6ce080e7          	jalr	1742(ra) # 72e <sbrk>
  68:	ff2519e3          	bne	a0,s2,5a <countfree+0x24>
  }
  sinfo(&info);
  6c:	fb840513          	addi	a0,s0,-72
  70:	00000097          	auipc	ra,0x0
  74:	f90080e7          	jalr	-112(ra) # 0 <sinfo>
  if (info.freemem != 0) {
  78:	fb843583          	ld	a1,-72(s0)
  7c:	e58d                	bnez	a1,a6 <countfree+0x70>
    printf("FAIL: there is no free mem, but sysinfo.freemem=%d\n",
      info.freemem);
    exit(1);
  }
  sbrk(-((uint64)sbrk(0) - sz0));
  7e:	4501                	li	a0,0
  80:	00000097          	auipc	ra,0x0
  84:	6ae080e7          	jalr	1710(ra) # 72e <sbrk>
  88:	40aa053b          	subw	a0,s4,a0
  8c:	00000097          	auipc	ra,0x0
  90:	6a2080e7          	jalr	1698(ra) # 72e <sbrk>
  return n;
}
  94:	8526                	mv	a0,s1
  96:	60a6                	ld	ra,72(sp)
  98:	6406                	ld	s0,64(sp)
  9a:	74e2                	ld	s1,56(sp)
  9c:	7942                	ld	s2,48(sp)
  9e:	79a2                	ld	s3,40(sp)
  a0:	7a02                	ld	s4,32(sp)
  a2:	6161                	addi	sp,sp,80
  a4:	8082                	ret
    printf("FAIL: there is no free mem, but sysinfo.freemem=%d\n",
  a6:	00001517          	auipc	a0,0x1
  aa:	b4250513          	addi	a0,a0,-1214 # be8 <malloc+0xfc>
  ae:	00001097          	auipc	ra,0x1
  b2:	980080e7          	jalr	-1664(ra) # a2e <printf>
    exit(1);
  b6:	4505                	li	a0,1
  b8:	00000097          	auipc	ra,0x0
  bc:	5ee080e7          	jalr	1518(ra) # 6a6 <exit>

00000000000000c0 <testmem>:

void
testmem() {
  c0:	7139                	addi	sp,sp,-64
  c2:	fc06                	sd	ra,56(sp)
  c4:	f822                	sd	s0,48(sp)
  c6:	f426                	sd	s1,40(sp)
  c8:	f04a                	sd	s2,32(sp)
  ca:	0080                	addi	s0,sp,64
  struct sysinfo info;
  uint64 n = countfree();
  cc:	00000097          	auipc	ra,0x0
  d0:	f6a080e7          	jalr	-150(ra) # 36 <countfree>
  d4:	84aa                	mv	s1,a0
  
  sinfo(&info);
  d6:	fc840513          	addi	a0,s0,-56
  da:	00000097          	auipc	ra,0x0
  de:	f26080e7          	jalr	-218(ra) # 0 <sinfo>

  if (info.freemem!= n) {
  e2:	fc843583          	ld	a1,-56(s0)
  e6:	04959e63          	bne	a1,s1,142 <testmem+0x82>
    printf("FAIL: free mem %d (bytes) instead of %d\n", info.freemem, n);
    exit(1);
  }
  
  if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  ea:	6505                	lui	a0,0x1
  ec:	00000097          	auipc	ra,0x0
  f0:	642080e7          	jalr	1602(ra) # 72e <sbrk>
  f4:	57fd                	li	a5,-1
  f6:	06f50463          	beq	a0,a5,15e <testmem+0x9e>
    printf("sbrk failed");
    exit(1);
  }

  sinfo(&info);
  fa:	fc840513          	addi	a0,s0,-56
  fe:	00000097          	auipc	ra,0x0
 102:	f02080e7          	jalr	-254(ra) # 0 <sinfo>
    
  if (info.freemem != n-PGSIZE) {
 106:	fc843603          	ld	a2,-56(s0)
 10a:	75fd                	lui	a1,0xfffff
 10c:	95a6                	add	a1,a1,s1
 10e:	06b61563          	bne	a2,a1,178 <testmem+0xb8>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n-PGSIZE, info.freemem);
    exit(1);
  }
  
  if((uint64)sbrk(-PGSIZE) == 0xffffffffffffffff){
 112:	757d                	lui	a0,0xfffff
 114:	00000097          	auipc	ra,0x0
 118:	61a080e7          	jalr	1562(ra) # 72e <sbrk>
 11c:	57fd                	li	a5,-1
 11e:	06f50a63          	beq	a0,a5,192 <testmem+0xd2>
    printf("sbrk failed");
    exit(1);
  }

  sinfo(&info);
 122:	fc840513          	addi	a0,s0,-56
 126:	00000097          	auipc	ra,0x0
 12a:	eda080e7          	jalr	-294(ra) # 0 <sinfo>
    
  if (info.freemem != n) {
 12e:	fc843603          	ld	a2,-56(s0)
 132:	06961d63          	bne	a2,s1,1ac <testmem+0xec>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n, info.freemem);
    exit(1);
  }
}
 136:	70e2                	ld	ra,56(sp)
 138:	7442                	ld	s0,48(sp)
 13a:	74a2                	ld	s1,40(sp)
 13c:	7902                	ld	s2,32(sp)
 13e:	6121                	addi	sp,sp,64
 140:	8082                	ret
    printf("FAIL: free mem %d (bytes) instead of %d\n", info.freemem, n);
 142:	8626                	mv	a2,s1
 144:	00001517          	auipc	a0,0x1
 148:	adc50513          	addi	a0,a0,-1316 # c20 <malloc+0x134>
 14c:	00001097          	auipc	ra,0x1
 150:	8e2080e7          	jalr	-1822(ra) # a2e <printf>
    exit(1);
 154:	4505                	li	a0,1
 156:	00000097          	auipc	ra,0x0
 15a:	550080e7          	jalr	1360(ra) # 6a6 <exit>
    printf("sbrk failed");
 15e:	00001517          	auipc	a0,0x1
 162:	af250513          	addi	a0,a0,-1294 # c50 <malloc+0x164>
 166:	00001097          	auipc	ra,0x1
 16a:	8c8080e7          	jalr	-1848(ra) # a2e <printf>
    exit(1);
 16e:	4505                	li	a0,1
 170:	00000097          	auipc	ra,0x0
 174:	536080e7          	jalr	1334(ra) # 6a6 <exit>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n-PGSIZE, info.freemem);
 178:	00001517          	auipc	a0,0x1
 17c:	aa850513          	addi	a0,a0,-1368 # c20 <malloc+0x134>
 180:	00001097          	auipc	ra,0x1
 184:	8ae080e7          	jalr	-1874(ra) # a2e <printf>
    exit(1);
 188:	4505                	li	a0,1
 18a:	00000097          	auipc	ra,0x0
 18e:	51c080e7          	jalr	1308(ra) # 6a6 <exit>
    printf("sbrk failed");
 192:	00001517          	auipc	a0,0x1
 196:	abe50513          	addi	a0,a0,-1346 # c50 <malloc+0x164>
 19a:	00001097          	auipc	ra,0x1
 19e:	894080e7          	jalr	-1900(ra) # a2e <printf>
    exit(1);
 1a2:	4505                	li	a0,1
 1a4:	00000097          	auipc	ra,0x0
 1a8:	502080e7          	jalr	1282(ra) # 6a6 <exit>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n, info.freemem);
 1ac:	85a6                	mv	a1,s1
 1ae:	00001517          	auipc	a0,0x1
 1b2:	a7250513          	addi	a0,a0,-1422 # c20 <malloc+0x134>
 1b6:	00001097          	auipc	ra,0x1
 1ba:	878080e7          	jalr	-1928(ra) # a2e <printf>
    exit(1);
 1be:	4505                	li	a0,1
 1c0:	00000097          	auipc	ra,0x0
 1c4:	4e6080e7          	jalr	1254(ra) # 6a6 <exit>

00000000000001c8 <testcall>:

void
testcall() {
 1c8:	7179                	addi	sp,sp,-48
 1ca:	f406                	sd	ra,40(sp)
 1cc:	f022                	sd	s0,32(sp)
 1ce:	1800                	addi	s0,sp,48
  struct sysinfo info;
  
  if (sysinfo(&info) < 0) {
 1d0:	fd840513          	addi	a0,s0,-40
 1d4:	00000097          	auipc	ra,0x0
 1d8:	57a080e7          	jalr	1402(ra) # 74e <sysinfo>
 1dc:	02054163          	bltz	a0,1fe <testcall+0x36>
    printf("FAIL: sysinfo failed\n");
    exit(1);
  }

  if (sysinfo((struct sysinfo *) 0xeaeb0b5b00002f5e) !=  0xffffffffffffffff) {
 1e0:	00001517          	auipc	a0,0x1
 1e4:	ba053503          	ld	a0,-1120(a0) # d80 <__SDATA_BEGIN__>
 1e8:	00000097          	auipc	ra,0x0
 1ec:	566080e7          	jalr	1382(ra) # 74e <sysinfo>
 1f0:	57fd                	li	a5,-1
 1f2:	02f51363          	bne	a0,a5,218 <testcall+0x50>
    printf("FAIL: sysinfo succeeded with bad argument\n");
    exit(1);
  }
}
 1f6:	70a2                	ld	ra,40(sp)
 1f8:	7402                	ld	s0,32(sp)
 1fa:	6145                	addi	sp,sp,48
 1fc:	8082                	ret
    printf("FAIL: sysinfo failed\n");
 1fe:	00001517          	auipc	a0,0x1
 202:	a6250513          	addi	a0,a0,-1438 # c60 <malloc+0x174>
 206:	00001097          	auipc	ra,0x1
 20a:	828080e7          	jalr	-2008(ra) # a2e <printf>
    exit(1);
 20e:	4505                	li	a0,1
 210:	00000097          	auipc	ra,0x0
 214:	496080e7          	jalr	1174(ra) # 6a6 <exit>
    printf("FAIL: sysinfo succeeded with bad argument\n");
 218:	00001517          	auipc	a0,0x1
 21c:	a6050513          	addi	a0,a0,-1440 # c78 <malloc+0x18c>
 220:	00001097          	auipc	ra,0x1
 224:	80e080e7          	jalr	-2034(ra) # a2e <printf>
    exit(1);
 228:	4505                	li	a0,1
 22a:	00000097          	auipc	ra,0x0
 22e:	47c080e7          	jalr	1148(ra) # 6a6 <exit>

0000000000000232 <testproc>:

void testproc() {
 232:	7139                	addi	sp,sp,-64
 234:	fc06                	sd	ra,56(sp)
 236:	f822                	sd	s0,48(sp)
 238:	f426                	sd	s1,40(sp)
 23a:	0080                	addi	s0,sp,64
  struct sysinfo info;
  uint64 nproc;
  int status;
  int pid;
  
  sinfo(&info);
 23c:	fc840513          	addi	a0,s0,-56
 240:	00000097          	auipc	ra,0x0
 244:	dc0080e7          	jalr	-576(ra) # 0 <sinfo>
  nproc = info.nproc;
 248:	fd043483          	ld	s1,-48(s0)

  pid = fork();
 24c:	00000097          	auipc	ra,0x0
 250:	452080e7          	jalr	1106(ra) # 69e <fork>
  if(pid < 0){
 254:	02054c63          	bltz	a0,28c <testproc+0x5a>
    printf("sysinfotest: fork failed\n");
    exit(1);
  }
  if(pid == 0){
 258:	ed21                	bnez	a0,2b0 <testproc+0x7e>
    sinfo(&info);
 25a:	fc840513          	addi	a0,s0,-56
 25e:	00000097          	auipc	ra,0x0
 262:	da2080e7          	jalr	-606(ra) # 0 <sinfo>
    if(info.nproc != nproc-1) {
 266:	fd043583          	ld	a1,-48(s0)
 26a:	fff48613          	addi	a2,s1,-1
 26e:	02c58c63          	beq	a1,a2,2a6 <testproc+0x74>
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc-1);
 272:	00001517          	auipc	a0,0x1
 276:	a5650513          	addi	a0,a0,-1450 # cc8 <malloc+0x1dc>
 27a:	00000097          	auipc	ra,0x0
 27e:	7b4080e7          	jalr	1972(ra) # a2e <printf>
      exit(1);
 282:	4505                	li	a0,1
 284:	00000097          	auipc	ra,0x0
 288:	422080e7          	jalr	1058(ra) # 6a6 <exit>
    printf("sysinfotest: fork failed\n");
 28c:	00001517          	auipc	a0,0x1
 290:	a1c50513          	addi	a0,a0,-1508 # ca8 <malloc+0x1bc>
 294:	00000097          	auipc	ra,0x0
 298:	79a080e7          	jalr	1946(ra) # a2e <printf>
    exit(1);
 29c:	4505                	li	a0,1
 29e:	00000097          	auipc	ra,0x0
 2a2:	408080e7          	jalr	1032(ra) # 6a6 <exit>
    }
    exit(0);
 2a6:	4501                	li	a0,0
 2a8:	00000097          	auipc	ra,0x0
 2ac:	3fe080e7          	jalr	1022(ra) # 6a6 <exit>
  }
  wait(&status);
 2b0:	fc440513          	addi	a0,s0,-60
 2b4:	00000097          	auipc	ra,0x0
 2b8:	3fa080e7          	jalr	1018(ra) # 6ae <wait>
  sinfo(&info);
 2bc:	fc840513          	addi	a0,s0,-56
 2c0:	00000097          	auipc	ra,0x0
 2c4:	d40080e7          	jalr	-704(ra) # 0 <sinfo>
  if(info.nproc != nproc) {
 2c8:	fd043583          	ld	a1,-48(s0)
 2cc:	00959763          	bne	a1,s1,2da <testproc+0xa8>
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc);
      exit(1);
  }
}
 2d0:	70e2                	ld	ra,56(sp)
 2d2:	7442                	ld	s0,48(sp)
 2d4:	74a2                	ld	s1,40(sp)
 2d6:	6121                	addi	sp,sp,64
 2d8:	8082                	ret
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc);
 2da:	8626                	mv	a2,s1
 2dc:	00001517          	auipc	a0,0x1
 2e0:	9ec50513          	addi	a0,a0,-1556 # cc8 <malloc+0x1dc>
 2e4:	00000097          	auipc	ra,0x0
 2e8:	74a080e7          	jalr	1866(ra) # a2e <printf>
      exit(1);
 2ec:	4505                	li	a0,1
 2ee:	00000097          	auipc	ra,0x0
 2f2:	3b8080e7          	jalr	952(ra) # 6a6 <exit>

00000000000002f6 <testfd>:

void testfd(){
 2f6:	715d                	addi	sp,sp,-80
 2f8:	e486                	sd	ra,72(sp)
 2fa:	e0a2                	sd	s0,64(sp)
 2fc:	fc26                	sd	s1,56(sp)
 2fe:	f84a                	sd	s2,48(sp)
 300:	f44e                	sd	s3,40(sp)
 302:	0880                	addi	s0,sp,80
  struct sysinfo info;
  sinfo(&info);
 304:	fb840513          	addi	a0,s0,-72
 308:	00000097          	auipc	ra,0x0
 30c:	cf8080e7          	jalr	-776(ra) # 0 <sinfo>
  uint64 nfd = info.freefd;
 310:	fc843983          	ld	s3,-56(s0)

  int fd = open("cat",O_RDONLY);
 314:	4581                	li	a1,0
 316:	00001517          	auipc	a0,0x1
 31a:	9e250513          	addi	a0,a0,-1566 # cf8 <malloc+0x20c>
 31e:	00000097          	auipc	ra,0x0
 322:	3c8080e7          	jalr	968(ra) # 6e6 <open>
 326:	892a                	mv	s2,a0

  sinfo(&info);
 328:	fb840513          	addi	a0,s0,-72
 32c:	00000097          	auipc	ra,0x0
 330:	cd4080e7          	jalr	-812(ra) # 0 <sinfo>
  if(info.freefd != nfd - 1) {
 334:	fc843583          	ld	a1,-56(s0)
 338:	fff98613          	addi	a2,s3,-1 # fff <__BSS_END__+0x25f>
 33c:	44a9                	li	s1,10
 33e:	04c59c63          	bne	a1,a2,396 <testfd+0xa0>
    printf("sysinfotest: FAIL freefd is %d instead of %d\n", info.freefd, nfd - 1);
    exit(1);
  }
  
  for(int i = 0; i < 10; i++){
    dup(fd);
 342:	854a                	mv	a0,s2
 344:	00000097          	auipc	ra,0x0
 348:	3da080e7          	jalr	986(ra) # 71e <dup>
  for(int i = 0; i < 10; i++){
 34c:	34fd                	addiw	s1,s1,-1
 34e:	f8f5                	bnez	s1,342 <testfd+0x4c>
  }
  sinfo(&info);
 350:	fb840513          	addi	a0,s0,-72
 354:	00000097          	auipc	ra,0x0
 358:	cac080e7          	jalr	-852(ra) # 0 <sinfo>
  if(info.freefd != nfd - 11) {
 35c:	fc843583          	ld	a1,-56(s0)
 360:	ff598613          	addi	a2,s3,-11
 364:	04c59663          	bne	a1,a2,3b0 <testfd+0xba>
    printf("sysinfotest: FAIL freefd is %d instead of %d\n", info.freefd, nfd-11);
    exit(1);
  }

  close(fd);
 368:	854a                	mv	a0,s2
 36a:	00000097          	auipc	ra,0x0
 36e:	364080e7          	jalr	868(ra) # 6ce <close>
  sinfo(&info);
 372:	fb840513          	addi	a0,s0,-72
 376:	00000097          	auipc	ra,0x0
 37a:	c8a080e7          	jalr	-886(ra) # 0 <sinfo>
  if(info.freefd != nfd - 10) {
 37e:	fc843583          	ld	a1,-56(s0)
 382:	19d9                	addi	s3,s3,-10
 384:	05359363          	bne	a1,s3,3ca <testfd+0xd4>
    printf("sysinfotest: FAIL freefd is %d instead of %d\n", info.freefd, nfd-10);
    exit(1);
  }
}
 388:	60a6                	ld	ra,72(sp)
 38a:	6406                	ld	s0,64(sp)
 38c:	74e2                	ld	s1,56(sp)
 38e:	7942                	ld	s2,48(sp)
 390:	79a2                	ld	s3,40(sp)
 392:	6161                	addi	sp,sp,80
 394:	8082                	ret
    printf("sysinfotest: FAIL freefd is %d instead of %d\n", info.freefd, nfd - 1);
 396:	00001517          	auipc	a0,0x1
 39a:	96a50513          	addi	a0,a0,-1686 # d00 <malloc+0x214>
 39e:	00000097          	auipc	ra,0x0
 3a2:	690080e7          	jalr	1680(ra) # a2e <printf>
    exit(1);
 3a6:	4505                	li	a0,1
 3a8:	00000097          	auipc	ra,0x0
 3ac:	2fe080e7          	jalr	766(ra) # 6a6 <exit>
    printf("sysinfotest: FAIL freefd is %d instead of %d\n", info.freefd, nfd-11);
 3b0:	00001517          	auipc	a0,0x1
 3b4:	95050513          	addi	a0,a0,-1712 # d00 <malloc+0x214>
 3b8:	00000097          	auipc	ra,0x0
 3bc:	676080e7          	jalr	1654(ra) # a2e <printf>
    exit(1);
 3c0:	4505                	li	a0,1
 3c2:	00000097          	auipc	ra,0x0
 3c6:	2e4080e7          	jalr	740(ra) # 6a6 <exit>
    printf("sysinfotest: FAIL freefd is %d instead of %d\n", info.freefd, nfd-10);
 3ca:	864e                	mv	a2,s3
 3cc:	00001517          	auipc	a0,0x1
 3d0:	93450513          	addi	a0,a0,-1740 # d00 <malloc+0x214>
 3d4:	00000097          	auipc	ra,0x0
 3d8:	65a080e7          	jalr	1626(ra) # a2e <printf>
    exit(1);
 3dc:	4505                	li	a0,1
 3de:	00000097          	auipc	ra,0x0
 3e2:	2c8080e7          	jalr	712(ra) # 6a6 <exit>

00000000000003e6 <main>:

int
main(int argc, char *argv[])
{
 3e6:	1141                	addi	sp,sp,-16
 3e8:	e406                	sd	ra,8(sp)
 3ea:	e022                	sd	s0,0(sp)
 3ec:	0800                	addi	s0,sp,16
  printf("sysinfotest: start\n");
 3ee:	00001517          	auipc	a0,0x1
 3f2:	94250513          	addi	a0,a0,-1726 # d30 <malloc+0x244>
 3f6:	00000097          	auipc	ra,0x0
 3fa:	638080e7          	jalr	1592(ra) # a2e <printf>
  testcall();
 3fe:	00000097          	auipc	ra,0x0
 402:	dca080e7          	jalr	-566(ra) # 1c8 <testcall>
  testmem();
 406:	00000097          	auipc	ra,0x0
 40a:	cba080e7          	jalr	-838(ra) # c0 <testmem>
  testproc();
 40e:	00000097          	auipc	ra,0x0
 412:	e24080e7          	jalr	-476(ra) # 232 <testproc>
  testfd();
 416:	00000097          	auipc	ra,0x0
 41a:	ee0080e7          	jalr	-288(ra) # 2f6 <testfd>
  printf("sysinfotest: OK\n");
 41e:	00001517          	auipc	a0,0x1
 422:	92a50513          	addi	a0,a0,-1750 # d48 <malloc+0x25c>
 426:	00000097          	auipc	ra,0x0
 42a:	608080e7          	jalr	1544(ra) # a2e <printf>
  exit(0);
 42e:	4501                	li	a0,0
 430:	00000097          	auipc	ra,0x0
 434:	276080e7          	jalr	630(ra) # 6a6 <exit>

0000000000000438 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 438:	1141                	addi	sp,sp,-16
 43a:	e422                	sd	s0,8(sp)
 43c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 43e:	87aa                	mv	a5,a0
 440:	0585                	addi	a1,a1,1
 442:	0785                	addi	a5,a5,1
 444:	fff5c703          	lbu	a4,-1(a1) # ffffffffffffefff <__global_pointer$+0xffffffffffffda86>
 448:	fee78fa3          	sb	a4,-1(a5)
 44c:	fb75                	bnez	a4,440 <strcpy+0x8>
    ;
  return os;
}
 44e:	6422                	ld	s0,8(sp)
 450:	0141                	addi	sp,sp,16
 452:	8082                	ret

0000000000000454 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 454:	1141                	addi	sp,sp,-16
 456:	e422                	sd	s0,8(sp)
 458:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 45a:	00054783          	lbu	a5,0(a0)
 45e:	cb91                	beqz	a5,472 <strcmp+0x1e>
 460:	0005c703          	lbu	a4,0(a1)
 464:	00f71763          	bne	a4,a5,472 <strcmp+0x1e>
    p++, q++;
 468:	0505                	addi	a0,a0,1
 46a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 46c:	00054783          	lbu	a5,0(a0)
 470:	fbe5                	bnez	a5,460 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 472:	0005c503          	lbu	a0,0(a1)
}
 476:	40a7853b          	subw	a0,a5,a0
 47a:	6422                	ld	s0,8(sp)
 47c:	0141                	addi	sp,sp,16
 47e:	8082                	ret

0000000000000480 <strlen>:

uint
strlen(const char *s)
{
 480:	1141                	addi	sp,sp,-16
 482:	e422                	sd	s0,8(sp)
 484:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 486:	00054783          	lbu	a5,0(a0)
 48a:	cf91                	beqz	a5,4a6 <strlen+0x26>
 48c:	0505                	addi	a0,a0,1
 48e:	87aa                	mv	a5,a0
 490:	4685                	li	a3,1
 492:	9e89                	subw	a3,a3,a0
 494:	00f6853b          	addw	a0,a3,a5
 498:	0785                	addi	a5,a5,1
 49a:	fff7c703          	lbu	a4,-1(a5)
 49e:	fb7d                	bnez	a4,494 <strlen+0x14>
    ;
  return n;
}
 4a0:	6422                	ld	s0,8(sp)
 4a2:	0141                	addi	sp,sp,16
 4a4:	8082                	ret
  for(n = 0; s[n]; n++)
 4a6:	4501                	li	a0,0
 4a8:	bfe5                	j	4a0 <strlen+0x20>

00000000000004aa <memset>:

void*
memset(void *dst, int c, uint n)
{
 4aa:	1141                	addi	sp,sp,-16
 4ac:	e422                	sd	s0,8(sp)
 4ae:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 4b0:	ca19                	beqz	a2,4c6 <memset+0x1c>
 4b2:	87aa                	mv	a5,a0
 4b4:	1602                	slli	a2,a2,0x20
 4b6:	9201                	srli	a2,a2,0x20
 4b8:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 4bc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 4c0:	0785                	addi	a5,a5,1
 4c2:	fee79de3          	bne	a5,a4,4bc <memset+0x12>
  }
  return dst;
}
 4c6:	6422                	ld	s0,8(sp)
 4c8:	0141                	addi	sp,sp,16
 4ca:	8082                	ret

00000000000004cc <strchr>:

char*
strchr(const char *s, char c)
{
 4cc:	1141                	addi	sp,sp,-16
 4ce:	e422                	sd	s0,8(sp)
 4d0:	0800                	addi	s0,sp,16
  for(; *s; s++)
 4d2:	00054783          	lbu	a5,0(a0)
 4d6:	cb99                	beqz	a5,4ec <strchr+0x20>
    if(*s == c)
 4d8:	00f58763          	beq	a1,a5,4e6 <strchr+0x1a>
  for(; *s; s++)
 4dc:	0505                	addi	a0,a0,1
 4de:	00054783          	lbu	a5,0(a0)
 4e2:	fbfd                	bnez	a5,4d8 <strchr+0xc>
      return (char*)s;
  return 0;
 4e4:	4501                	li	a0,0
}
 4e6:	6422                	ld	s0,8(sp)
 4e8:	0141                	addi	sp,sp,16
 4ea:	8082                	ret
  return 0;
 4ec:	4501                	li	a0,0
 4ee:	bfe5                	j	4e6 <strchr+0x1a>

00000000000004f0 <gets>:

char*
gets(char *buf, int max)
{
 4f0:	711d                	addi	sp,sp,-96
 4f2:	ec86                	sd	ra,88(sp)
 4f4:	e8a2                	sd	s0,80(sp)
 4f6:	e4a6                	sd	s1,72(sp)
 4f8:	e0ca                	sd	s2,64(sp)
 4fa:	fc4e                	sd	s3,56(sp)
 4fc:	f852                	sd	s4,48(sp)
 4fe:	f456                	sd	s5,40(sp)
 500:	f05a                	sd	s6,32(sp)
 502:	ec5e                	sd	s7,24(sp)
 504:	1080                	addi	s0,sp,96
 506:	8baa                	mv	s7,a0
 508:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 50a:	892a                	mv	s2,a0
 50c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 50e:	4aa9                	li	s5,10
 510:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 512:	89a6                	mv	s3,s1
 514:	2485                	addiw	s1,s1,1
 516:	0344d863          	bge	s1,s4,546 <gets+0x56>
    cc = read(0, &c, 1);
 51a:	4605                	li	a2,1
 51c:	faf40593          	addi	a1,s0,-81
 520:	4501                	li	a0,0
 522:	00000097          	auipc	ra,0x0
 526:	19c080e7          	jalr	412(ra) # 6be <read>
    if(cc < 1)
 52a:	00a05e63          	blez	a0,546 <gets+0x56>
    buf[i++] = c;
 52e:	faf44783          	lbu	a5,-81(s0)
 532:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 536:	01578763          	beq	a5,s5,544 <gets+0x54>
 53a:	0905                	addi	s2,s2,1
 53c:	fd679be3          	bne	a5,s6,512 <gets+0x22>
  for(i=0; i+1 < max; ){
 540:	89a6                	mv	s3,s1
 542:	a011                	j	546 <gets+0x56>
 544:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 546:	99de                	add	s3,s3,s7
 548:	00098023          	sb	zero,0(s3)
  return buf;
}
 54c:	855e                	mv	a0,s7
 54e:	60e6                	ld	ra,88(sp)
 550:	6446                	ld	s0,80(sp)
 552:	64a6                	ld	s1,72(sp)
 554:	6906                	ld	s2,64(sp)
 556:	79e2                	ld	s3,56(sp)
 558:	7a42                	ld	s4,48(sp)
 55a:	7aa2                	ld	s5,40(sp)
 55c:	7b02                	ld	s6,32(sp)
 55e:	6be2                	ld	s7,24(sp)
 560:	6125                	addi	sp,sp,96
 562:	8082                	ret

0000000000000564 <stat>:

int
stat(const char *n, struct stat *st)
{
 564:	1101                	addi	sp,sp,-32
 566:	ec06                	sd	ra,24(sp)
 568:	e822                	sd	s0,16(sp)
 56a:	e426                	sd	s1,8(sp)
 56c:	e04a                	sd	s2,0(sp)
 56e:	1000                	addi	s0,sp,32
 570:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 572:	4581                	li	a1,0
 574:	00000097          	auipc	ra,0x0
 578:	172080e7          	jalr	370(ra) # 6e6 <open>
  if(fd < 0)
 57c:	02054563          	bltz	a0,5a6 <stat+0x42>
 580:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 582:	85ca                	mv	a1,s2
 584:	00000097          	auipc	ra,0x0
 588:	17a080e7          	jalr	378(ra) # 6fe <fstat>
 58c:	892a                	mv	s2,a0
  close(fd);
 58e:	8526                	mv	a0,s1
 590:	00000097          	auipc	ra,0x0
 594:	13e080e7          	jalr	318(ra) # 6ce <close>
  return r;
}
 598:	854a                	mv	a0,s2
 59a:	60e2                	ld	ra,24(sp)
 59c:	6442                	ld	s0,16(sp)
 59e:	64a2                	ld	s1,8(sp)
 5a0:	6902                	ld	s2,0(sp)
 5a2:	6105                	addi	sp,sp,32
 5a4:	8082                	ret
    return -1;
 5a6:	597d                	li	s2,-1
 5a8:	bfc5                	j	598 <stat+0x34>

00000000000005aa <atoi>:

int
atoi(const char *s)
{
 5aa:	1141                	addi	sp,sp,-16
 5ac:	e422                	sd	s0,8(sp)
 5ae:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 5b0:	00054603          	lbu	a2,0(a0)
 5b4:	fd06079b          	addiw	a5,a2,-48
 5b8:	0ff7f793          	andi	a5,a5,255
 5bc:	4725                	li	a4,9
 5be:	02f76963          	bltu	a4,a5,5f0 <atoi+0x46>
 5c2:	86aa                	mv	a3,a0
  n = 0;
 5c4:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 5c6:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 5c8:	0685                	addi	a3,a3,1
 5ca:	0025179b          	slliw	a5,a0,0x2
 5ce:	9fa9                	addw	a5,a5,a0
 5d0:	0017979b          	slliw	a5,a5,0x1
 5d4:	9fb1                	addw	a5,a5,a2
 5d6:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 5da:	0006c603          	lbu	a2,0(a3)
 5de:	fd06071b          	addiw	a4,a2,-48
 5e2:	0ff77713          	andi	a4,a4,255
 5e6:	fee5f1e3          	bgeu	a1,a4,5c8 <atoi+0x1e>
  return n;
}
 5ea:	6422                	ld	s0,8(sp)
 5ec:	0141                	addi	sp,sp,16
 5ee:	8082                	ret
  n = 0;
 5f0:	4501                	li	a0,0
 5f2:	bfe5                	j	5ea <atoi+0x40>

00000000000005f4 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 5f4:	1141                	addi	sp,sp,-16
 5f6:	e422                	sd	s0,8(sp)
 5f8:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 5fa:	02b57463          	bgeu	a0,a1,622 <memmove+0x2e>
    while(n-- > 0)
 5fe:	00c05f63          	blez	a2,61c <memmove+0x28>
 602:	1602                	slli	a2,a2,0x20
 604:	9201                	srli	a2,a2,0x20
 606:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 60a:	872a                	mv	a4,a0
      *dst++ = *src++;
 60c:	0585                	addi	a1,a1,1
 60e:	0705                	addi	a4,a4,1
 610:	fff5c683          	lbu	a3,-1(a1)
 614:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 618:	fee79ae3          	bne	a5,a4,60c <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 61c:	6422                	ld	s0,8(sp)
 61e:	0141                	addi	sp,sp,16
 620:	8082                	ret
    dst += n;
 622:	00c50733          	add	a4,a0,a2
    src += n;
 626:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 628:	fec05ae3          	blez	a2,61c <memmove+0x28>
 62c:	fff6079b          	addiw	a5,a2,-1
 630:	1782                	slli	a5,a5,0x20
 632:	9381                	srli	a5,a5,0x20
 634:	fff7c793          	not	a5,a5
 638:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 63a:	15fd                	addi	a1,a1,-1
 63c:	177d                	addi	a4,a4,-1
 63e:	0005c683          	lbu	a3,0(a1)
 642:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 646:	fee79ae3          	bne	a5,a4,63a <memmove+0x46>
 64a:	bfc9                	j	61c <memmove+0x28>

000000000000064c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 64c:	1141                	addi	sp,sp,-16
 64e:	e422                	sd	s0,8(sp)
 650:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 652:	ca05                	beqz	a2,682 <memcmp+0x36>
 654:	fff6069b          	addiw	a3,a2,-1
 658:	1682                	slli	a3,a3,0x20
 65a:	9281                	srli	a3,a3,0x20
 65c:	0685                	addi	a3,a3,1
 65e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 660:	00054783          	lbu	a5,0(a0)
 664:	0005c703          	lbu	a4,0(a1)
 668:	00e79863          	bne	a5,a4,678 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 66c:	0505                	addi	a0,a0,1
    p2++;
 66e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 670:	fed518e3          	bne	a0,a3,660 <memcmp+0x14>
  }
  return 0;
 674:	4501                	li	a0,0
 676:	a019                	j	67c <memcmp+0x30>
      return *p1 - *p2;
 678:	40e7853b          	subw	a0,a5,a4
}
 67c:	6422                	ld	s0,8(sp)
 67e:	0141                	addi	sp,sp,16
 680:	8082                	ret
  return 0;
 682:	4501                	li	a0,0
 684:	bfe5                	j	67c <memcmp+0x30>

0000000000000686 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 686:	1141                	addi	sp,sp,-16
 688:	e406                	sd	ra,8(sp)
 68a:	e022                	sd	s0,0(sp)
 68c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 68e:	00000097          	auipc	ra,0x0
 692:	f66080e7          	jalr	-154(ra) # 5f4 <memmove>
}
 696:	60a2                	ld	ra,8(sp)
 698:	6402                	ld	s0,0(sp)
 69a:	0141                	addi	sp,sp,16
 69c:	8082                	ret

000000000000069e <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 69e:	4885                	li	a7,1
 ecall
 6a0:	00000073          	ecall
 ret
 6a4:	8082                	ret

00000000000006a6 <exit>:
.global exit
exit:
 li a7, SYS_exit
 6a6:	4889                	li	a7,2
 ecall
 6a8:	00000073          	ecall
 ret
 6ac:	8082                	ret

00000000000006ae <wait>:
.global wait
wait:
 li a7, SYS_wait
 6ae:	488d                	li	a7,3
 ecall
 6b0:	00000073          	ecall
 ret
 6b4:	8082                	ret

00000000000006b6 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 6b6:	4891                	li	a7,4
 ecall
 6b8:	00000073          	ecall
 ret
 6bc:	8082                	ret

00000000000006be <read>:
.global read
read:
 li a7, SYS_read
 6be:	4895                	li	a7,5
 ecall
 6c0:	00000073          	ecall
 ret
 6c4:	8082                	ret

00000000000006c6 <write>:
.global write
write:
 li a7, SYS_write
 6c6:	48c1                	li	a7,16
 ecall
 6c8:	00000073          	ecall
 ret
 6cc:	8082                	ret

00000000000006ce <close>:
.global close
close:
 li a7, SYS_close
 6ce:	48d5                	li	a7,21
 ecall
 6d0:	00000073          	ecall
 ret
 6d4:	8082                	ret

00000000000006d6 <kill>:
.global kill
kill:
 li a7, SYS_kill
 6d6:	4899                	li	a7,6
 ecall
 6d8:	00000073          	ecall
 ret
 6dc:	8082                	ret

00000000000006de <exec>:
.global exec
exec:
 li a7, SYS_exec
 6de:	489d                	li	a7,7
 ecall
 6e0:	00000073          	ecall
 ret
 6e4:	8082                	ret

00000000000006e6 <open>:
.global open
open:
 li a7, SYS_open
 6e6:	48bd                	li	a7,15
 ecall
 6e8:	00000073          	ecall
 ret
 6ec:	8082                	ret

00000000000006ee <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 6ee:	48c5                	li	a7,17
 ecall
 6f0:	00000073          	ecall
 ret
 6f4:	8082                	ret

00000000000006f6 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 6f6:	48c9                	li	a7,18
 ecall
 6f8:	00000073          	ecall
 ret
 6fc:	8082                	ret

00000000000006fe <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 6fe:	48a1                	li	a7,8
 ecall
 700:	00000073          	ecall
 ret
 704:	8082                	ret

0000000000000706 <link>:
.global link
link:
 li a7, SYS_link
 706:	48cd                	li	a7,19
 ecall
 708:	00000073          	ecall
 ret
 70c:	8082                	ret

000000000000070e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 70e:	48d1                	li	a7,20
 ecall
 710:	00000073          	ecall
 ret
 714:	8082                	ret

0000000000000716 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 716:	48a5                	li	a7,9
 ecall
 718:	00000073          	ecall
 ret
 71c:	8082                	ret

000000000000071e <dup>:
.global dup
dup:
 li a7, SYS_dup
 71e:	48a9                	li	a7,10
 ecall
 720:	00000073          	ecall
 ret
 724:	8082                	ret

0000000000000726 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 726:	48ad                	li	a7,11
 ecall
 728:	00000073          	ecall
 ret
 72c:	8082                	ret

000000000000072e <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 72e:	48b1                	li	a7,12
 ecall
 730:	00000073          	ecall
 ret
 734:	8082                	ret

0000000000000736 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 736:	48b5                	li	a7,13
 ecall
 738:	00000073          	ecall
 ret
 73c:	8082                	ret

000000000000073e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 73e:	48b9                	li	a7,14
 ecall
 740:	00000073          	ecall
 ret
 744:	8082                	ret

0000000000000746 <trace>:
.global trace
trace:
 li a7, SYS_trace
 746:	48d9                	li	a7,22
 ecall
 748:	00000073          	ecall
 ret
 74c:	8082                	ret

000000000000074e <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 74e:	48dd                	li	a7,23
 ecall
 750:	00000073          	ecall
 ret
 754:	8082                	ret

0000000000000756 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 756:	1101                	addi	sp,sp,-32
 758:	ec06                	sd	ra,24(sp)
 75a:	e822                	sd	s0,16(sp)
 75c:	1000                	addi	s0,sp,32
 75e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 762:	4605                	li	a2,1
 764:	fef40593          	addi	a1,s0,-17
 768:	00000097          	auipc	ra,0x0
 76c:	f5e080e7          	jalr	-162(ra) # 6c6 <write>
}
 770:	60e2                	ld	ra,24(sp)
 772:	6442                	ld	s0,16(sp)
 774:	6105                	addi	sp,sp,32
 776:	8082                	ret

0000000000000778 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 778:	7139                	addi	sp,sp,-64
 77a:	fc06                	sd	ra,56(sp)
 77c:	f822                	sd	s0,48(sp)
 77e:	f426                	sd	s1,40(sp)
 780:	f04a                	sd	s2,32(sp)
 782:	ec4e                	sd	s3,24(sp)
 784:	0080                	addi	s0,sp,64
 786:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 788:	c299                	beqz	a3,78e <printint+0x16>
 78a:	0805c863          	bltz	a1,81a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 78e:	2581                	sext.w	a1,a1
  neg = 0;
 790:	4881                	li	a7,0
 792:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 796:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 798:	2601                	sext.w	a2,a2
 79a:	00000517          	auipc	a0,0x0
 79e:	5ce50513          	addi	a0,a0,1486 # d68 <digits>
 7a2:	883a                	mv	a6,a4
 7a4:	2705                	addiw	a4,a4,1
 7a6:	02c5f7bb          	remuw	a5,a1,a2
 7aa:	1782                	slli	a5,a5,0x20
 7ac:	9381                	srli	a5,a5,0x20
 7ae:	97aa                	add	a5,a5,a0
 7b0:	0007c783          	lbu	a5,0(a5)
 7b4:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 7b8:	0005879b          	sext.w	a5,a1
 7bc:	02c5d5bb          	divuw	a1,a1,a2
 7c0:	0685                	addi	a3,a3,1
 7c2:	fec7f0e3          	bgeu	a5,a2,7a2 <printint+0x2a>
  if(neg)
 7c6:	00088b63          	beqz	a7,7dc <printint+0x64>
    buf[i++] = '-';
 7ca:	fd040793          	addi	a5,s0,-48
 7ce:	973e                	add	a4,a4,a5
 7d0:	02d00793          	li	a5,45
 7d4:	fef70823          	sb	a5,-16(a4)
 7d8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 7dc:	02e05863          	blez	a4,80c <printint+0x94>
 7e0:	fc040793          	addi	a5,s0,-64
 7e4:	00e78933          	add	s2,a5,a4
 7e8:	fff78993          	addi	s3,a5,-1
 7ec:	99ba                	add	s3,s3,a4
 7ee:	377d                	addiw	a4,a4,-1
 7f0:	1702                	slli	a4,a4,0x20
 7f2:	9301                	srli	a4,a4,0x20
 7f4:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 7f8:	fff94583          	lbu	a1,-1(s2)
 7fc:	8526                	mv	a0,s1
 7fe:	00000097          	auipc	ra,0x0
 802:	f58080e7          	jalr	-168(ra) # 756 <putc>
  while(--i >= 0)
 806:	197d                	addi	s2,s2,-1
 808:	ff3918e3          	bne	s2,s3,7f8 <printint+0x80>
}
 80c:	70e2                	ld	ra,56(sp)
 80e:	7442                	ld	s0,48(sp)
 810:	74a2                	ld	s1,40(sp)
 812:	7902                	ld	s2,32(sp)
 814:	69e2                	ld	s3,24(sp)
 816:	6121                	addi	sp,sp,64
 818:	8082                	ret
    x = -xx;
 81a:	40b005bb          	negw	a1,a1
    neg = 1;
 81e:	4885                	li	a7,1
    x = -xx;
 820:	bf8d                	j	792 <printint+0x1a>

0000000000000822 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 822:	7119                	addi	sp,sp,-128
 824:	fc86                	sd	ra,120(sp)
 826:	f8a2                	sd	s0,112(sp)
 828:	f4a6                	sd	s1,104(sp)
 82a:	f0ca                	sd	s2,96(sp)
 82c:	ecce                	sd	s3,88(sp)
 82e:	e8d2                	sd	s4,80(sp)
 830:	e4d6                	sd	s5,72(sp)
 832:	e0da                	sd	s6,64(sp)
 834:	fc5e                	sd	s7,56(sp)
 836:	f862                	sd	s8,48(sp)
 838:	f466                	sd	s9,40(sp)
 83a:	f06a                	sd	s10,32(sp)
 83c:	ec6e                	sd	s11,24(sp)
 83e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 840:	0005c903          	lbu	s2,0(a1)
 844:	18090f63          	beqz	s2,9e2 <vprintf+0x1c0>
 848:	8aaa                	mv	s5,a0
 84a:	8b32                	mv	s6,a2
 84c:	00158493          	addi	s1,a1,1
  state = 0;
 850:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 852:	02500a13          	li	s4,37
      if(c == 'd'){
 856:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 85a:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 85e:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 862:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 866:	00000b97          	auipc	s7,0x0
 86a:	502b8b93          	addi	s7,s7,1282 # d68 <digits>
 86e:	a839                	j	88c <vprintf+0x6a>
        putc(fd, c);
 870:	85ca                	mv	a1,s2
 872:	8556                	mv	a0,s5
 874:	00000097          	auipc	ra,0x0
 878:	ee2080e7          	jalr	-286(ra) # 756 <putc>
 87c:	a019                	j	882 <vprintf+0x60>
    } else if(state == '%'){
 87e:	01498f63          	beq	s3,s4,89c <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 882:	0485                	addi	s1,s1,1
 884:	fff4c903          	lbu	s2,-1(s1)
 888:	14090d63          	beqz	s2,9e2 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 88c:	0009079b          	sext.w	a5,s2
    if(state == 0){
 890:	fe0997e3          	bnez	s3,87e <vprintf+0x5c>
      if(c == '%'){
 894:	fd479ee3          	bne	a5,s4,870 <vprintf+0x4e>
        state = '%';
 898:	89be                	mv	s3,a5
 89a:	b7e5                	j	882 <vprintf+0x60>
      if(c == 'd'){
 89c:	05878063          	beq	a5,s8,8dc <vprintf+0xba>
      } else if(c == 'l') {
 8a0:	05978c63          	beq	a5,s9,8f8 <vprintf+0xd6>
      } else if(c == 'x') {
 8a4:	07a78863          	beq	a5,s10,914 <vprintf+0xf2>
      } else if(c == 'p') {
 8a8:	09b78463          	beq	a5,s11,930 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 8ac:	07300713          	li	a4,115
 8b0:	0ce78663          	beq	a5,a4,97c <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 8b4:	06300713          	li	a4,99
 8b8:	0ee78e63          	beq	a5,a4,9b4 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 8bc:	11478863          	beq	a5,s4,9cc <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 8c0:	85d2                	mv	a1,s4
 8c2:	8556                	mv	a0,s5
 8c4:	00000097          	auipc	ra,0x0
 8c8:	e92080e7          	jalr	-366(ra) # 756 <putc>
        putc(fd, c);
 8cc:	85ca                	mv	a1,s2
 8ce:	8556                	mv	a0,s5
 8d0:	00000097          	auipc	ra,0x0
 8d4:	e86080e7          	jalr	-378(ra) # 756 <putc>
      }
      state = 0;
 8d8:	4981                	li	s3,0
 8da:	b765                	j	882 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 8dc:	008b0913          	addi	s2,s6,8
 8e0:	4685                	li	a3,1
 8e2:	4629                	li	a2,10
 8e4:	000b2583          	lw	a1,0(s6)
 8e8:	8556                	mv	a0,s5
 8ea:	00000097          	auipc	ra,0x0
 8ee:	e8e080e7          	jalr	-370(ra) # 778 <printint>
 8f2:	8b4a                	mv	s6,s2
      state = 0;
 8f4:	4981                	li	s3,0
 8f6:	b771                	j	882 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 8f8:	008b0913          	addi	s2,s6,8
 8fc:	4681                	li	a3,0
 8fe:	4629                	li	a2,10
 900:	000b2583          	lw	a1,0(s6)
 904:	8556                	mv	a0,s5
 906:	00000097          	auipc	ra,0x0
 90a:	e72080e7          	jalr	-398(ra) # 778 <printint>
 90e:	8b4a                	mv	s6,s2
      state = 0;
 910:	4981                	li	s3,0
 912:	bf85                	j	882 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 914:	008b0913          	addi	s2,s6,8
 918:	4681                	li	a3,0
 91a:	4641                	li	a2,16
 91c:	000b2583          	lw	a1,0(s6)
 920:	8556                	mv	a0,s5
 922:	00000097          	auipc	ra,0x0
 926:	e56080e7          	jalr	-426(ra) # 778 <printint>
 92a:	8b4a                	mv	s6,s2
      state = 0;
 92c:	4981                	li	s3,0
 92e:	bf91                	j	882 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 930:	008b0793          	addi	a5,s6,8
 934:	f8f43423          	sd	a5,-120(s0)
 938:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 93c:	03000593          	li	a1,48
 940:	8556                	mv	a0,s5
 942:	00000097          	auipc	ra,0x0
 946:	e14080e7          	jalr	-492(ra) # 756 <putc>
  putc(fd, 'x');
 94a:	85ea                	mv	a1,s10
 94c:	8556                	mv	a0,s5
 94e:	00000097          	auipc	ra,0x0
 952:	e08080e7          	jalr	-504(ra) # 756 <putc>
 956:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 958:	03c9d793          	srli	a5,s3,0x3c
 95c:	97de                	add	a5,a5,s7
 95e:	0007c583          	lbu	a1,0(a5)
 962:	8556                	mv	a0,s5
 964:	00000097          	auipc	ra,0x0
 968:	df2080e7          	jalr	-526(ra) # 756 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 96c:	0992                	slli	s3,s3,0x4
 96e:	397d                	addiw	s2,s2,-1
 970:	fe0914e3          	bnez	s2,958 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 974:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 978:	4981                	li	s3,0
 97a:	b721                	j	882 <vprintf+0x60>
        s = va_arg(ap, char*);
 97c:	008b0993          	addi	s3,s6,8
 980:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 984:	02090163          	beqz	s2,9a6 <vprintf+0x184>
        while(*s != 0){
 988:	00094583          	lbu	a1,0(s2)
 98c:	c9a1                	beqz	a1,9dc <vprintf+0x1ba>
          putc(fd, *s);
 98e:	8556                	mv	a0,s5
 990:	00000097          	auipc	ra,0x0
 994:	dc6080e7          	jalr	-570(ra) # 756 <putc>
          s++;
 998:	0905                	addi	s2,s2,1
        while(*s != 0){
 99a:	00094583          	lbu	a1,0(s2)
 99e:	f9e5                	bnez	a1,98e <vprintf+0x16c>
        s = va_arg(ap, char*);
 9a0:	8b4e                	mv	s6,s3
      state = 0;
 9a2:	4981                	li	s3,0
 9a4:	bdf9                	j	882 <vprintf+0x60>
          s = "(null)";
 9a6:	00000917          	auipc	s2,0x0
 9aa:	3ba90913          	addi	s2,s2,954 # d60 <malloc+0x274>
        while(*s != 0){
 9ae:	02800593          	li	a1,40
 9b2:	bff1                	j	98e <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 9b4:	008b0913          	addi	s2,s6,8
 9b8:	000b4583          	lbu	a1,0(s6)
 9bc:	8556                	mv	a0,s5
 9be:	00000097          	auipc	ra,0x0
 9c2:	d98080e7          	jalr	-616(ra) # 756 <putc>
 9c6:	8b4a                	mv	s6,s2
      state = 0;
 9c8:	4981                	li	s3,0
 9ca:	bd65                	j	882 <vprintf+0x60>
        putc(fd, c);
 9cc:	85d2                	mv	a1,s4
 9ce:	8556                	mv	a0,s5
 9d0:	00000097          	auipc	ra,0x0
 9d4:	d86080e7          	jalr	-634(ra) # 756 <putc>
      state = 0;
 9d8:	4981                	li	s3,0
 9da:	b565                	j	882 <vprintf+0x60>
        s = va_arg(ap, char*);
 9dc:	8b4e                	mv	s6,s3
      state = 0;
 9de:	4981                	li	s3,0
 9e0:	b54d                	j	882 <vprintf+0x60>
    }
  }
}
 9e2:	70e6                	ld	ra,120(sp)
 9e4:	7446                	ld	s0,112(sp)
 9e6:	74a6                	ld	s1,104(sp)
 9e8:	7906                	ld	s2,96(sp)
 9ea:	69e6                	ld	s3,88(sp)
 9ec:	6a46                	ld	s4,80(sp)
 9ee:	6aa6                	ld	s5,72(sp)
 9f0:	6b06                	ld	s6,64(sp)
 9f2:	7be2                	ld	s7,56(sp)
 9f4:	7c42                	ld	s8,48(sp)
 9f6:	7ca2                	ld	s9,40(sp)
 9f8:	7d02                	ld	s10,32(sp)
 9fa:	6de2                	ld	s11,24(sp)
 9fc:	6109                	addi	sp,sp,128
 9fe:	8082                	ret

0000000000000a00 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 a00:	715d                	addi	sp,sp,-80
 a02:	ec06                	sd	ra,24(sp)
 a04:	e822                	sd	s0,16(sp)
 a06:	1000                	addi	s0,sp,32
 a08:	e010                	sd	a2,0(s0)
 a0a:	e414                	sd	a3,8(s0)
 a0c:	e818                	sd	a4,16(s0)
 a0e:	ec1c                	sd	a5,24(s0)
 a10:	03043023          	sd	a6,32(s0)
 a14:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 a18:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 a1c:	8622                	mv	a2,s0
 a1e:	00000097          	auipc	ra,0x0
 a22:	e04080e7          	jalr	-508(ra) # 822 <vprintf>
}
 a26:	60e2                	ld	ra,24(sp)
 a28:	6442                	ld	s0,16(sp)
 a2a:	6161                	addi	sp,sp,80
 a2c:	8082                	ret

0000000000000a2e <printf>:

void
printf(const char *fmt, ...)
{
 a2e:	711d                	addi	sp,sp,-96
 a30:	ec06                	sd	ra,24(sp)
 a32:	e822                	sd	s0,16(sp)
 a34:	1000                	addi	s0,sp,32
 a36:	e40c                	sd	a1,8(s0)
 a38:	e810                	sd	a2,16(s0)
 a3a:	ec14                	sd	a3,24(s0)
 a3c:	f018                	sd	a4,32(s0)
 a3e:	f41c                	sd	a5,40(s0)
 a40:	03043823          	sd	a6,48(s0)
 a44:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 a48:	00840613          	addi	a2,s0,8
 a4c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 a50:	85aa                	mv	a1,a0
 a52:	4505                	li	a0,1
 a54:	00000097          	auipc	ra,0x0
 a58:	dce080e7          	jalr	-562(ra) # 822 <vprintf>
}
 a5c:	60e2                	ld	ra,24(sp)
 a5e:	6442                	ld	s0,16(sp)
 a60:	6125                	addi	sp,sp,96
 a62:	8082                	ret

0000000000000a64 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 a64:	1141                	addi	sp,sp,-16
 a66:	e422                	sd	s0,8(sp)
 a68:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 a6a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 a6e:	00000797          	auipc	a5,0x0
 a72:	31a7b783          	ld	a5,794(a5) # d88 <freep>
 a76:	a805                	j	aa6 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 a78:	4618                	lw	a4,8(a2)
 a7a:	9db9                	addw	a1,a1,a4
 a7c:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 a80:	6398                	ld	a4,0(a5)
 a82:	6318                	ld	a4,0(a4)
 a84:	fee53823          	sd	a4,-16(a0)
 a88:	a091                	j	acc <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 a8a:	ff852703          	lw	a4,-8(a0)
 a8e:	9e39                	addw	a2,a2,a4
 a90:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 a92:	ff053703          	ld	a4,-16(a0)
 a96:	e398                	sd	a4,0(a5)
 a98:	a099                	j	ade <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 a9a:	6398                	ld	a4,0(a5)
 a9c:	00e7e463          	bltu	a5,a4,aa4 <free+0x40>
 aa0:	00e6ea63          	bltu	a3,a4,ab4 <free+0x50>
{
 aa4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 aa6:	fed7fae3          	bgeu	a5,a3,a9a <free+0x36>
 aaa:	6398                	ld	a4,0(a5)
 aac:	00e6e463          	bltu	a3,a4,ab4 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 ab0:	fee7eae3          	bltu	a5,a4,aa4 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 ab4:	ff852583          	lw	a1,-8(a0)
 ab8:	6390                	ld	a2,0(a5)
 aba:	02059713          	slli	a4,a1,0x20
 abe:	9301                	srli	a4,a4,0x20
 ac0:	0712                	slli	a4,a4,0x4
 ac2:	9736                	add	a4,a4,a3
 ac4:	fae60ae3          	beq	a2,a4,a78 <free+0x14>
    bp->s.ptr = p->s.ptr;
 ac8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 acc:	4790                	lw	a2,8(a5)
 ace:	02061713          	slli	a4,a2,0x20
 ad2:	9301                	srli	a4,a4,0x20
 ad4:	0712                	slli	a4,a4,0x4
 ad6:	973e                	add	a4,a4,a5
 ad8:	fae689e3          	beq	a3,a4,a8a <free+0x26>
  } else
    p->s.ptr = bp;
 adc:	e394                	sd	a3,0(a5)
  freep = p;
 ade:	00000717          	auipc	a4,0x0
 ae2:	2af73523          	sd	a5,682(a4) # d88 <freep>
}
 ae6:	6422                	ld	s0,8(sp)
 ae8:	0141                	addi	sp,sp,16
 aea:	8082                	ret

0000000000000aec <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 aec:	7139                	addi	sp,sp,-64
 aee:	fc06                	sd	ra,56(sp)
 af0:	f822                	sd	s0,48(sp)
 af2:	f426                	sd	s1,40(sp)
 af4:	f04a                	sd	s2,32(sp)
 af6:	ec4e                	sd	s3,24(sp)
 af8:	e852                	sd	s4,16(sp)
 afa:	e456                	sd	s5,8(sp)
 afc:	e05a                	sd	s6,0(sp)
 afe:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 b00:	02051493          	slli	s1,a0,0x20
 b04:	9081                	srli	s1,s1,0x20
 b06:	04bd                	addi	s1,s1,15
 b08:	8091                	srli	s1,s1,0x4
 b0a:	0014899b          	addiw	s3,s1,1
 b0e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 b10:	00000517          	auipc	a0,0x0
 b14:	27853503          	ld	a0,632(a0) # d88 <freep>
 b18:	c515                	beqz	a0,b44 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b1a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b1c:	4798                	lw	a4,8(a5)
 b1e:	02977f63          	bgeu	a4,s1,b5c <malloc+0x70>
 b22:	8a4e                	mv	s4,s3
 b24:	0009871b          	sext.w	a4,s3
 b28:	6685                	lui	a3,0x1
 b2a:	00d77363          	bgeu	a4,a3,b30 <malloc+0x44>
 b2e:	6a05                	lui	s4,0x1
 b30:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 b34:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 b38:	00000917          	auipc	s2,0x0
 b3c:	25090913          	addi	s2,s2,592 # d88 <freep>
  if(p == (char*)-1)
 b40:	5afd                	li	s5,-1
 b42:	a88d                	j	bb4 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 b44:	00000797          	auipc	a5,0x0
 b48:	24c78793          	addi	a5,a5,588 # d90 <base>
 b4c:	00000717          	auipc	a4,0x0
 b50:	22f73e23          	sd	a5,572(a4) # d88 <freep>
 b54:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 b56:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 b5a:	b7e1                	j	b22 <malloc+0x36>
      if(p->s.size == nunits)
 b5c:	02e48b63          	beq	s1,a4,b92 <malloc+0xa6>
        p->s.size -= nunits;
 b60:	4137073b          	subw	a4,a4,s3
 b64:	c798                	sw	a4,8(a5)
        p += p->s.size;
 b66:	1702                	slli	a4,a4,0x20
 b68:	9301                	srli	a4,a4,0x20
 b6a:	0712                	slli	a4,a4,0x4
 b6c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 b6e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 b72:	00000717          	auipc	a4,0x0
 b76:	20a73b23          	sd	a0,534(a4) # d88 <freep>
      return (void*)(p + 1);
 b7a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 b7e:	70e2                	ld	ra,56(sp)
 b80:	7442                	ld	s0,48(sp)
 b82:	74a2                	ld	s1,40(sp)
 b84:	7902                	ld	s2,32(sp)
 b86:	69e2                	ld	s3,24(sp)
 b88:	6a42                	ld	s4,16(sp)
 b8a:	6aa2                	ld	s5,8(sp)
 b8c:	6b02                	ld	s6,0(sp)
 b8e:	6121                	addi	sp,sp,64
 b90:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 b92:	6398                	ld	a4,0(a5)
 b94:	e118                	sd	a4,0(a0)
 b96:	bff1                	j	b72 <malloc+0x86>
  hp->s.size = nu;
 b98:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 b9c:	0541                	addi	a0,a0,16
 b9e:	00000097          	auipc	ra,0x0
 ba2:	ec6080e7          	jalr	-314(ra) # a64 <free>
  return freep;
 ba6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 baa:	d971                	beqz	a0,b7e <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 bac:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 bae:	4798                	lw	a4,8(a5)
 bb0:	fa9776e3          	bgeu	a4,s1,b5c <malloc+0x70>
    if(p == freep)
 bb4:	00093703          	ld	a4,0(s2)
 bb8:	853e                	mv	a0,a5
 bba:	fef719e3          	bne	a4,a5,bac <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 bbe:	8552                	mv	a0,s4
 bc0:	00000097          	auipc	ra,0x0
 bc4:	b6e080e7          	jalr	-1170(ra) # 72e <sbrk>
  if(p == (char*)-1)
 bc8:	fd5518e3          	bne	a0,s5,b98 <malloc+0xac>
        return 0;
 bcc:	4501                	li	a0,0
 bce:	bf45                	j	b7e <malloc+0x92>
