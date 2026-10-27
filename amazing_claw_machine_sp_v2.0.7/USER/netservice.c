#include "netservice.h"

#include <string.h>

#include "basic.h"
#include "define.h"
#include "extern.h"
#include "lcd.h"
#include "md5.h"

// 4G发送数据////////////////////////////////
void GsmSend(char *p) {
  volatile u8 delaytime = 0;
  // mDelay(1000);
  // UART3_SendString("netsending....\r\n\0");
  for (delaytime = 0; delaytime < 100; delaytime++);
  // Time_10ms_cnt=50;
  // while(Time_10ms_cnt);
#ifdef HARDWARE_V1
  UART1_SendString(p);
#endif
#ifdef HARDWARE_V0
  UART3_SendString(p);
#endif
#ifdef HARDWARE_V2
  UART2_SendString(p);
#endif
  // UART3_SendString("netsended...\r\n\0");
}

// 生成8位随机数
void Creat_8Byte_Rand(u8 *redat) {
  u8 i, j;
  u8 temp;
  for (i = 0, j = 0; i < 4; i++) {
    temp = (u8)rand();
    redat[j++] = hex2chr(0x0f & (temp >> 4));
    redat[j++] = hex2chr(0x0f & temp);
  }
}
// 请求余额
//[n|机台号(5位)|卡id8bit|02|签名]#$-$#-------卡合法，读取余额
// u8 strrequcount[100]={"[n|00000|00000000|01|00000000000000000000000000000000]#$-$#"};
void Add_md5_keymark_COU(u8 *str) {
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去4\r\n\0");
  Creat_8Byte_Rand(md5mark);  // 8bit随机数
  for (i = 0; i < 8; i++) md5mark[i] = '0' + i;
  // mymemecy(md5mark,str,'|',4,8);//??8????//第几位开始，共几位
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'n';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 8;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c999991001
  len += 2;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 4, 32);  //??16???
                                           // UART3_SendString("出来4\r\n\0");
}
// 请求充值二维码
//[l|机台号(5bit)|单号4bit|充值金额6bit|8bit随机|MD5签名]
// u8 changesq[68]={"[l|80002|1234|123456|12345678|A000000000000000000000000000000B]#$-$#"};
void Add_md5_keymark_CHSQ(u8 *str) {
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去4\r\n\0");
  Creat_8Byte_Rand(md5mark);  // 8bit随机数
  for (i = 0; i < 8; i++) md5mark[i] = '0' + i;
  // mymemecy(md5mark,str,'|',4,8);//??8????//第几位开始，共几位
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'l';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 4;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c999991001
  len += 6;
  mymemext1(str, &calmd5buf[len], '|', '|', 4, 100);  //??8???,???????c999991001
  len += 8;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 5, 32);  //??16???
                                           // UART3_SendString("出来4\r\n\0");
}

////投币
//[ a | 机台号(5位) | 订单ID（10位）| 随机串 | 签名]
//[c|机器编号(5bit)|支付类型1bit|支付金额3位|8bit 随机数|MD5sign]#$-$#
// strcoinin[100]={"[c|99999|1|001|12345678|9999999989ABCDEF0123456789ABCDEF]#$-$#"};
void Add_md5_keymark_coinin(u8 *str) {
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去1\r\n\0");
  Creat_8Byte_Rand(md5mark);  // 8bit随机数
  for (i = 0; i < 8; i++) md5mark[i] = '0' + i;
  // mymemecy(md5mark,str,'|',4,8);//??8????//第几位开始，共几位
  // mymemecyl(md5mark,str,15,8);//??8????//第几位开始，共几位
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'c';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 1;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c999991001
  len += 3;
  mymemext1(str, &calmd5buf[len], '|', '|', 4, 100);  //??8???,???????c99999100112345678
  len += 8;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 5, 32);  //??16???
                                           // UART3_SendString("出来1\r\n\0");
}

// 请求二维码
//[e|机台号(5位)|支付类型1位|金额3位|8位随机|MD5签名]#$-$#
// u8 strrequqr[100]={"[e|00000|0|000|00000000|00000000000000000000000000000000]#$-$#"};
void Add_md5_keymark_QR(u8 *str) {
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去2\r\n\0");
  Creat_8Byte_Rand(md5mark);  // 8bit随机数
  for (i = 0; i < 8; i++) md5mark[i] = '0' + i;
  // mymemecy(md5mark,str,'|',4,8);//??8????//第几位开始，共几位
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'e';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 1;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c999991001
  len += 3;
  mymemext1(str, &calmd5buf[len], '|', '|', 4, 100);  //??8???,???????c99999100112345678
  len += 8;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 5, 32);  //??16???
                                           // UART3_SendString("出来2\r\n\0");
}

// 扣卡请求
//[m|机台号(5位)|卡id8bit|金额3位|签名]#$-$#-------余额3位：卡合法则为扣币服
// u8 strrequcoinpay[100]="[m|00002|00000000|002|00000000000000000000000000000000]#$-$#""};
void Add_md5_keymark_Pay(u8 *str) {
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去3\r\n\0");
  Creat_8Byte_Rand(md5mark);  // 8bit随机数
  for (i = 0; i < 8; i++) md5mark[i] = '0' + i;
  // mymemecy(md5mark,str,'|',4,8);//??8????//第几位开始，共几位
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'm';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 8;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c999991001
  len += 3;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 4, 32);  //??16???
                                           // UART3_SendString("出来3\r\n\0");
}

// 请求余额
//[n|机台号(5位)|卡id8bit|02|签名]#$-$#-------卡合法，读取余额
// u8 strrequcount[100]={"[n|00000|00000000|01|00000000000000000000000000000000]#$-$#"};
void Add_md5_keymark_rech(u8 *str) {
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去5\r\n\0");
  Creat_8Byte_Rand(md5mark);  // 8bit随机数
  for (i = 0; i < 8; i++) md5mark[i] = '0' + i;
  // mymemecy(md5mark,str,'|',4,8);//??8????//第几位开始，共几位
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'w';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 8;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c999991001
  len += 2;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 4, 32);  //??16???
                                           // UART3_SendString("出来5\r\n\0");
}

// 更新
//[u|00001|0|000003|12345678|00000000000000000000000000000000]#$-$#
void Add_md5_keymark_gsmupdatabuff(u8 *str)  // Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
{
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去6\r\n\0");
  Creat_8Byte_Rand(md5mark);  // 8bit随机数
  for (i = 0; i < 8; i++) md5mark[i] = '0' + i;
  // mymemecy(md5mark,str,'|',4,8);//??8????//第几位开始，共几位
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'u';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 1;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c99999100112345678
  len += 6;
  mymemext1(str, &calmd5buf[len], '|', '|', 4, 100);  //??8???,???????c99999100112345678
  len += 8;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 6, 32);  //??16???
                                           // UART3_SendString("出来6\r\n\0");
}

// 查询设置参数
//[q|00001|2|01|000002|12345678|00000000000000000000000000000000]#$-$#
void Add_md5_keymark_gsmsetdatabuff(u8 *str)  // Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
{
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去6\r\n\0");
  Creat_8Byte_Rand(md5mark);  // 8bit随机数
  for (i = 0; i < 8; i++) md5mark[i] = '0' + i;
  // mymemecy(md5mark,str,'|',4,8);//??8????//第几位开始，共几位
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'q';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 1;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c999991001
  len += 2;
  mymemext1(str, &calmd5buf[len], '|', '|', 4, 100);  //??8???,???????c99999100112345678
  len += 6;
  mymemext1(str, &calmd5buf[len], '|', '|', 5, 100);  //??8???,???????c99999100112345678
  len += 8;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 6, 32);  //??16???
                                           // UART3_SendString("出来6\r\n\0");
}

// 查询账单
//[g|00001|1|01|000020|12345678|sign]#$-$#
//[g|00001|1|01|000020|12345678|sign]#$-$#
void Add_md5_keymark_gsmgetdatabuff(u8 *str)  // Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
{
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去6\r\n\0");
  Creat_8Byte_Rand(md5mark);  // 8bit随机数
  for (i = 0; i < 8; i++) md5mark[i] = '0' + i;
  // mymemecy(md5mark,str,'|',5,8);//??8????//第几位开始，共几位
  // mymemecyl(md5mark,str,15,8);
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'g';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 1;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c999991001
  len += 2;
  mymemext1(str, &calmd5buf[len], '|', '|', 4, 100);  //??8???,???????c99999100112345678
  len += 6;
  mymemext1(str, &calmd5buf[len], '|', '|', 5, 100);  //??8???,???????c99999100112345678
  len += 8;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 6, 32);  //??16???
                                           // UART3_SendString("出来6\r\n\0");
}

// 即时出礼品，投币数据
// u8  gsmrealtimecoinindatabuff[64]={"[m|00001|6|00001|12345678|00000000000000000000000000000000]#$-$#"};
// u8  gsmrealtimetoyoutdatabuff[64]={"[n|00001|7|00001|12345678|00000000000000000000000000000000]#$-$#"};
void Add_md5_keymark_gsmcoinindatabuff(u8 *str)  // Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
{
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去6\r\n\0");
  Creat_8Byte_Rand(md5mark);  // 8bit随机数
  for (i = 0; i < 8; i++) md5mark[i] = '0' + i;
  // mymemecy(md5mark,str,'|',4,8);//??8????//第几位开始，共几位
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'm';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 1;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c999991001
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 4, 100);  //??8???,???????c99999100112345678
  len += 8;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 5, 32);  //??16???
                                           // UART3_SendString("出来6\r\n\0");
}
//[n|00001|7|00001|12345678|00000000000000000000000000000000]#$-$#"};
void Add_md5_keymark_gsmtoyoutdatabuff(u8 *str)  // Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
{
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去6\r\n\0");
  Creat_8Byte_Rand(md5mark);  // 8bit随机数
  for (i = 0; i < 8; i++) md5mark[i] = '0' + i;
  // mymemecy(md5mark,str,'|',4,8);//??8????//第几位开始，共几位
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'n';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 1;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c999991001
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 4, 100);  //??8???,???????c99999100112345678
  len += 8;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 5, 32);  //??16???
                                           // UART3_SendString("出来6\r\n\0");
}

//[s|00001|7|00001|12345678|00000000000000000000000000000000]#$-$#"};
void Add_md5_keymark_gsmsetyoudatabuff(u8 *str)  // Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
{
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去6\r\n\0");
  Creat_8Byte_Rand(md5mark);  // 8bit随机数
  for (i = 0; i < 8; i++) md5mark[i] = '0' + i;
  // mymemecy(md5mark,str,'|',4,8);//??8????//第几位开始，共几位
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 's';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 1;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c999991001
  len += 2;
  mymemext1(str, &calmd5buf[len], '|', '|', 4, 100);  //??8???,???????c99999100112345678
  len += 6;
  mymemext1(str, &calmd5buf[len], '|', '|', 5, 100);  //??8???,???????c99999100112345678
  len += 8;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 6, 32);  //??16???
                                           // UART3_SendString("出来6\r\n\0");
}

void Add_md5_keymark_coin(u8 *str) {
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u16 i, j, len;
  // UART3_SendString("进去1\r\n\0");
  //	Creat_8Byte_Rand(md5mark);//8bit随机数
  //	for(i=0; i<8; i++)
  //			md5mark[i]='0'+i;
  // mymemecy(md5mark,str,'|',4,8);//??8????//第几位开始，共几位
  mymemecyl(str, md5mark, 14, 8);  //??8????//第几位开始，共几位
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'e';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????,???????//c99999
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????,???????c999991
  len += 1;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8???,???????c999991001
  len += 2;
  mymemext1(str, &calmd5buf[len], '|', '|', 4, 100);  //??8???,???????c99999100112345678
  len += 8;
  for (i = 0; i < (sizeof(md5key) - 1); i++) calmd5buf[len++] = md5key[i];
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  mymemecy(md5markchar, str, '|', 5, 32);  //??16???
                                           // UART3_SendString("出来1\r\n\0");
}

u8 Compare_md5_keymark(u8 *str) {
  u8 calmd5buf[100];
  u8 md5mark[100];
  u8 md5markchar[100];
  u8 packet_md5markchar[100];
  u16 i, j, len;
  //		Creat_8Byte_Rand(md5mark);
  ////		for(i=0; i<8; i++)
  ////				md5mark[i]='0'+i;
  //		mymemecy(md5mark,str,'|',4,8);//添加8位随机数
  for (i = 0; i < sizeof(calmd5buf); i++) calmd5buf[i] = 0;
  len = 0;
  calmd5buf[len++] = 'a';
  mymemext1(str, &calmd5buf[len], '|', '|', 1, 100);  //?????
  len += 5;
  mymemext1(str, &calmd5buf[len], '|', '|', 2, 100);  //?????
  len += 10;
  mymemext1(str, &calmd5buf[len], '|', '|', 3, 100);  //??8????
  len += 8;
  for (i = 0; i < (sizeof(md5key) - 1); i++)  //????
    calmd5buf[len++] = md5key[i];
  //		printf("md5=%s\n",calmd5buf);
  for (i = 0; i < sizeof(md5mark); i++) md5mark[i] = 0;
  MD5Digest((char *)calmd5buf, len, (char *)md5mark);
  for (i = 0, j = 0; i < 16; i++) {
    md5markchar[j++] = hex2chr(0x0f & (md5mark[i] >> 4));
    md5markchar[j++] = hex2chr(0x0f & md5mark[i]);
  }
  //		printf("\n");
  //		printf("%s\n",md5mark);
  //		for(i=0; i<16; i++)
  //		{
  //			if(i<10)
  //				md5mark[i]='0'+i;
  //			else
  //				md5mark[i]='A'+i-10;
  //		}
  // mymemecy(md5markchar,str,'|',5,32);//
  mymemext1(str, packet_md5markchar, '|', ']', 4, 100);  //????? ?
  return mymemcpm(packet_md5markchar, md5markchar, 32);  // 0?? ????,1????
}

void Tick(void) {
  if (Tick_ReqKeep_OnLine_time > 20 && reconnect == 0 && combusy == 0 && sendbusy == 0)  // 10秒发一次心跳信号给服务器
  {
    Tick_ReqKeep_OnLine_time = 1;
    BUF_CLR();
    Time_10ms_cnt = 20;
    while (Time_10ms_cnt);
#ifdef HARDWARE_V1
    UART1_SendString("AT+CIPSEND=21\r\n");  // 发数据
#endif
#ifdef HARDWARE_V0
    UART3_SendString("AT+CIPSEND=21\r\n");  // 发数据
#endif
#ifdef HARDWARE_V2
    UART2_SendString("AT+CIPSEND=21\r\n");  // 发数据
#endif
    // mDelay(2000);
    Time_10ms_cnt = 10;
    while (Time_10ms_cnt);
    // GsmSend((char *)tickinfo);
    // UART3_SendString("[t|90098|000|F0]#$-$#");
#ifdef HARDWARE_V1
    UART1_SendString((char *)tickinfo);
#endif
#ifdef HARDWARE_V0
    UART3_SendString((char *)tickinfo);
#endif
#ifdef HARDWARE_V2
    UART2_SendString((char *)tickinfo);
#endif
    // LCD_Set_XY(3,3);
    // Write_Char(1,0x20);
    // Write_Char(1,0x03);
  }
  // else{
  //   LCD_Set_XY(3, 3);
  //   Write_Char(1, 0x20);
  // 	Write_Char(1, 0x20);
  // }
}
void Send_Tick(void) {
  Tick_ReqKeep_OnLine_time = 1;
  BUF_CLR();
  Time_10ms_cnt = 20;
  while (Time_10ms_cnt);
#ifdef HARDWARE_V1
  UART1_SendString("AT+CIPSEND=21\r\n");  // 发数据
#endif
#ifdef HARDWARE_V0
  UART3_SendString("AT+CIPSEND=21\r\n");  // 发数据
#endif
#ifdef HARDWARE_V2
  UART2_SendString("AT+CIPSEND=21\r\n");  // 发数据
#endif
  // mDelay(2000);
  Time_10ms_cnt = 10;
  while (Time_10ms_cnt);
  // GsmSend((char *)tickinfo);
  // UART3_SendString("[t|90098|000|F0]#$-$#");
#ifdef HARDWARE_V1
  UART1_SendString((char *)tickinfo);
#endif
#ifdef HARDWARE_V0
  UART3_SendString((char *)tickinfo);
#endif
#ifdef HARDWARE_V2
  UART2_SendString((char *)tickinfo);
#endif
  // LCD_Set_XY(3, 3);
  // Write_Char(1, 0x20);
  // Write_Char(1, 0x03);
}
