
#ifndef __BASICCODE_H
#define __BASICCODE_H

#include <stdlib.h>
//#include "MyTypeDef.h"
#include "stm32_cpu.h"



void UART3Cont(u8 *data, u8 length);
void UART1_len(u8 *data, u8 length);
void UART2_len(u8 *data, u8 length);
void UART3_len(u8 *data, u8 length);

void UART1_SendString(char* s);
void UART2_SendString(char* s);
void UART3_SendString(char* s);

u8 chr2hex(u8 chr);
u8 hex2chr(u8 hex);

void mymemclr(u8 *pt, u16 len);
u8  mymemext(u8 *ps, u8 *pt,u8 ex, u8 et, u8 nm, u8 len);//提取指定位置的数据
u8  mymemext1(u8 *ps, u8 *pt,u8 ex, u8 et, u8 nm, u8 len);//提取指定位置的数据
void mymemecy(u8 *ps, u8 *pt,u8 ex, u8 nm, u8 len);//拷贝
void  mymemecys(u8 *ps, u8 *pt,u8 ex,  u8 len);
void  mymemecyl(u8 *ps, u8 *pt,u8 ex,  u8 len);
bool mymemcpm(u8 *ps, u8 *pt, u16 len);//比较
void mymemcpy(u8 *ps, u8 *pt, u16 len);//拷贝
void mymemnull(u8 *pt, u16 len);//清空，即‘\0’
void mymemclr0(u8 *pt, u16 len);//清零
void  mymemecyup(u8 *ps, u8 *pt,u8 ex,  u8 len);

void uDelay(u8 n);

void mDelay(unsigned int Delay);

#endif


