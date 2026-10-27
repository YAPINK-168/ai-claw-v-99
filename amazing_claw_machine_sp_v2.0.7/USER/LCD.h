// #ifndef __LCD_H
// #define __LCD_H

#include "stm32_cpu.h"

#define  SID_H   GPIO_SetBits(GPIOB,GPIO_Pin_3)
#define  SID_L   GPIO_ResetBits(GPIOB,GPIO_Pin_3) 
#define  CS_H  	 GPIO_SetBits(GPIOD,GPIO_Pin_7)
#define  CS_L  	 GPIO_ResetBits(GPIOD,GPIO_Pin_7) 
#define  SCLK_H  GPIO_SetBits(GPIOB,GPIO_Pin_4)
#define  SCLK_L  GPIO_ResetBits(GPIOB,GPIO_Pin_4) //

// void delay_us(u8 di) ;
void Send_Byte(u8 bbyte) ;
void SendByteLCD(u8 WLCDData);
void SendCMD(u8 CMD);
void SendData(u8 Data);
void LCDInittest(void);
void LcmClearTXT(void);
void  LcmClearBMP(void);
void Put(u8 *p);
void Write_Char(u8 start, u8 ddata) ;
void Lcd_Init(void) ;
void Clr_Scr(void);//清屏函数
void LCD_Set_XY( u8 X, u8 Y );
void LCD_Write_String(u8 X,u8 Y,uc8  *s);//
void LCD_Write_String1(u8 X,u8 Y,u8 len,uc8  *s);//

void LCD_Write_Number(u8 s);// 数字显示函数
void Put1(u8 *p);
void Set_White(u8 x,u8 y,u8 end_x,u8 clear);

// #endif
