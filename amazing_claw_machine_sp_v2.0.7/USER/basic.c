#include "basic.h"

#include "define.h"
#include "extern.h"

volatile u8 chsq[82] = {"CLR(15);QRCODE(25,25,1234567890);DC24(5,170,'Coin out!please scan QR soon!',1);\r\n"};
volatile u8 a = 0;
volatile u8 countdisp[66] = {"CLR(15);QRCODE(25,25,1234567890);DC24(5,185,'count:',1);\r\n"};
volatile u8 userpaydisp[90] = {"CLR(15);QRCODE(25,25,1234567890);DC24(25,170,'*******8900',1);DC24(50,188,'pay...',1);\r\n"};
volatile u8 userscandisp[91] = {"CLR(15);QRCODE(25,25,1234567890);DC24(25,170,'*******8900',1);DC24(50,188,'scan...',1);\r\n"};
volatile u8 Qrnumdisp[110] = {"CLR(15);QRCODE(25,25,1234567890);DC16(108,205,'ID:12345',1);DC24(2,1,'coins:--',1);DC16(3,205,'SS:2345',1);\r\n"};  // 10 76 77 76+24=100
// volatile u8 Qrnumdisp[86]={"CLR(15);QRCODE(25,25,1234567890);DC16(108,205,'ID:12345',1);DC24(2,1,'coins:--',1);\r\n"};//10 76 77
volatile u8 disp[] = {"BTN(35,180,96,32,'123456',1,0,1,4);\r\n"};
// u8 machid[]={"BTN(5,2,48,16,'ID:123456',1,0,1,4);BTN(130,3,96,32,'10',1,0,1,4);\r\n"};
volatile u8 machid[] = {"DC16(5,2,'ID:123456',1);DC24(150,3,'10',1);\r\n"};
volatile u8 chur[89] = {"CLR(15);QRCODE(25,25,1234567890);DC24(25,170,'*******8900',1);DC24(50,188,'scan..',1);\r\n"};

void UART1_Send(u8 dat) {
  while (!(USART1->SR & USART_FLAG_TXE))
    ;
  USART_SendData(USART1, dat);
  while (USART_GetFlagStatus(USART1, USART_FLAG_TC) != SET)
    ;  // 等待发送结束
}
void UART3_Send(u8 dat) {
  while (!(USART3->SR & USART_FLAG_TXE))
    ;
  USART_SendData(USART3, dat);
  while (USART_GetFlagStatus(USART3, USART_FLAG_TC) != SET)
    ;  // 等待发送结束
}
void UART1_len(u8 *data, u8 length) {
  u8 i;
  for (i = 0; i < length; i++) UART1_Send(data[i]);
}
void UART3_len(u8 *data, u8 length) {
  u8 i;
  for (i = 0; i < length; i++) UART3_Send(data[i]);
}

void UART2_Send(u8 dat) {
  while (!(USART2->SR & USART_FLAG_TXE))
    ;
  USART_SendData(USART2, dat);
  while (USART_GetFlagStatus(USART2, USART_FLAG_TC) != SET)
    ;  // 等待发送结束
}
void UART2_len(u8 *data, u8 length) {
  u8 i;
  for (i = 0; i < length; i++) UART2_Send(data[i]);
}

void UART1_SendString(char *s) {
  while (*s)  // 检测字符串结束符		  != '\0'
  {
    while (!(USART1->SR & USART_FLAG_TXE))
      ;
    USART_SendData(USART1, *s++);  // 发送当前字符
    while (USART_GetFlagStatus(USART1, USART_FLAG_TC) != SET)
      ;  // 等待发送结束
  }
}
void UART2_SendString(char *s) {
  while (*s)  // 检测字符串结束符		  != '\0'
  {
    while (!(USART2->SR & USART_FLAG_TXE))
      ;
    USART_SendData(USART2, *s++);  // 发送当前字符
    while (USART_GetFlagStatus(USART2, USART_FLAG_TC) != SET)
      ;  // 等待发送结束
  }
}

/*******************************************************************************
 * 函数名  : UART3_SendString
 * 描述    : USART3发送字符串
 * 输入    : *s字符串指针
 * 输出    : 无
 * 返回    : 无
 * 说明    : 无
 *******************************************************************************/
void UART3_SendString(char *s) {
  while (*s)  // 检测字符串结束符		  != '\0'
  {
    // while (!(USART3->SR & USART_FLAG_TXE));
    while (USART_GetFlagStatus(USART3, USART_FLAG_TC) == RESET)
      ;                            // 等待发送结束
    USART_SendData(USART3, *s++);  // 发送当前字符
  }
}

// 将1个字符转换为16进制数字
// chr:字符,0~9/A~F/a~F
// 返回值:chr对应的16进制数值
u8 chr2hex(u8 chr) {
  if (chr >= '0' && chr <= '9') return chr - '0';
  if (chr >= 'A' && chr <= 'F') return (chr - 'A' + 10);
  if (chr >= 'a' && chr <= 'f') return (chr - 'a' + 10);
  return 0;
}
// 将1个16进制数字转换为字符
// hex:16进制数字,0~15;
// 返回值:字符
u8 hex2chr(u8 hex) {
  if (hex <= 9) return hex + '0';
  if (hex >= 10 && hex <= 15) return (hex - 10 + 'A');
  return '0';
}

void mymemclr(u8 *pt, u16 len)  // 清零
{
  while (len > 0) {
    *pt++ = 0;
    len--;
  }
}

void mymemclr0(u8 *pt, u16 len)  // 清零
{
  while (len > 0) {
    *pt++ = '0';
    len--;
  }
}

// Ord_Count=mymemext(RX3_buffer,Ord_buffer,'|',   ']',   2,      40);
// 从rx3buffer复制给ordbuffer，从第2个|开始到结束
//[a|10101|0000000001|01|01234567|40ED5F0AB89308DACE53D00877E5DCBF]
// mymemext(RX3_buffer,Ord_buffer,'|',   ']',   2,      40);
u8 mymemext(u8 *ps, u8 *pt, u8 ex, u8 et, u8 nm, u8 len)  // 提取指定位置的数据
{
  u8 i, j = 0, z = 0;
  for (i = 0; i < len; i++) {
    if (j != nm && ps[i] == ex) j++;
    if (j == nm) {
      if (i < 30)
        pt[z++] = ps[i + 1];
      else
        return z;
    }
  }
  return z;
}
// mymemext(RX3_buffer,Ord_buffer,'|',   ']',   2,      40);
//[s|00001|3|1|000002|12345678|sign]#$-$#
// mymemext1(RX3_buffer,datatempbuff6,'|','|',4,80);
u8 mymemext1(u8 *ps, u8 *pt, u8 ex, u8 et, u8 nm, u8 len)  // 提取指定位置的数据
{
  u8 i, j = 0, z = 0;
  for (i = 0; i < len; i++) {
    if (j != nm && ps[i] == ex) j++;
    if (j == nm) {
      if (ps[i + 1] != et)
        pt[z++] = ps[i + 1];
      else
        return z;
    }
  }
  return z;
}

// 从第几位开始读，复制，复制几位
void mymemecys(u8 *ps, u8 *pt, u8 ex, u8 len) {
  u8 j = 0;
  for (j = 0; j < len; j++) {
    ps[ex + j] = pt[j];
  }
}

void mymemecyup(u8 *ps, u8 *pt, u8 ex, u8 len) {
  u8 j = 0;
  for (j = 0; j < len; j++) {
    ps[ex + j] = pt[ex + j];
  }
}

// 从第几位开始读，复制，复制几位
void mymemecyl(u8 *ps, u8 *pt, u8 ex, u8 len) {
  u8 j = 0;
  for (j = 0; j < len; j++) {
    pt[j] = ps[ex + j];
  }
}

// 将*ps拷贝到指定字节数到*pt指定第几个相同值后面；
// mymemecy((u8*)(&tep),Shop_0kA,'|',3,2);  2shi tep的长度，把tep拼过去
void mymemecy(u8 *ps, u8 *pt, u8 ex, u8 nm, u8 len) {
  u8 i, j = 0, z = 0;
  for (i = 0;; i++) {
    if (pt[i] == ex) z++;
    if (z == nm) break;
  }
  for (j = 0; j < len; j++) {
    pt[i + j + 1] = ps[j];
  }
}

bool mymemcpm(u8 *ps, u8 *pt, u16 len) {
  while (len-- > 0) {
    if (*pt++ != *ps++) return FALSE;
  }
  return TRUE;
}
// mymemcpy((u8*)McNoZ, (u8*)&strMCYA[3],x);//拷贝
void mymemcpy(u8 *ps, u8 *pt, u16 len)  // 拷贝
{
  while (len > 0) {
    *pt++ = *ps++;
    len--;
  }
}
void mymemnull(u8 *pt, u16 len)  // 清空，即‘\0’
{
  while (len > 0) {
    *pt++ = '\0';
    len--;
  }
}
