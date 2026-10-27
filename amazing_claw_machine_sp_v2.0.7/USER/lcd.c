
#include "lcd.h"

#include "define.h"
#include "setgame.h"

u8 const num_lcd[] = {"0123456789 *:.-     "};

// void delay_us(u8 di) {
//   u16 da, db;
//   for (da = 0; da < di; da++)
//     for (db = 0; db < 10; db++)
//       ;
// }

// void delay10US(u8 x) {
//   u8 k;
//   for (k = 0; k < x; k++)
//     ;
// }

// void delaylcdMS(u8 x) {
//   u8 k, j;
//   x = x << 1;
//   for (k = 0; k < x; k++)
//     for (j = 0; j < 255; j++)
//       ;
// }

void Send_Byte(u8 bbyte) {
  u8 i, t;
  for (i = 0; i < 8; i++) {
    if ((bbyte) & 0x80)
      SID_H;  // 取出最高位
    else
      SID_L;
    delay_us(1);
    SCLK_H;
    delay_us(1);
    SCLK_L;
    bbyte <<= 1;  // 左移
    delay_us(1);
  }
}

void SendByteLCD(u8 WLCDData) {
  u8 i;
  for (i = 0; i < 8; i++) {
    if ((WLCDData << i) & 0x80)
      SID_H;  // SID_H   SID_L   CS_H  SCLK_H
    else
      SID_L;
    delay_us(1);
    SCLK_L;
    delay_us(1);
    SCLK_H;
    delay_us(1);
  }
}

void SPIWR(u8 Wdata, u8 WRS) {
  SendByteLCD(0xf8 + (WRS << 1));
  SendByteLCD(Wdata & 0xf0);
  SendByteLCD((Wdata << 4) & 0xf0);
}
void SendCMD(u8 CMD) {
  SPIWR(CMD, 0);
  delay_us(100);
}

void SendData(u8 Data) {
  SPIWR(Data, 1);
  delay_us(100);
}

void LCDInittest(void) {
  CS_L;
  Delay1ms(100);
  CS_H;
  Delay1ms(100);
  SendCMD(0x30);  // 功能设置，一次送8位数据，基本指令集
  SendCMD(0x0C);  // 0000,1100  整体显示，游标off，游标位置off
  SendCMD(0x01);  // 0000,0001 清DDRAM
  SendCMD(0x02);  // 0000,0010 DDRAM地址归位
  SendCMD(0x80);  // 1000,0000 设定DDRAM 7位地址000，0000到地址计数器AC//
  SendCMD(0x04);  // 点设定，显示字符/光标从左到右移位，DDRAM地址加 一//
  SendCMD(0x0C);  // 显示设定，开显示，显示光标，当前显示位反白闪动
}

/*****************************
清文本区
*****************************/
void LcmClearTXT(void) {
  unsigned char i;
  SendCMD(0x30);  // 8BitMCU,基本指令集合
  SendCMD(0x80);  // AC归起始位
  for (i = 0; i < 64; i++) SendData(0x20);
}

void LcmClearBMP(void) {
  u8 i, j, x, yC;
  LCDInittest();
  SendCMD(0x3e);  // RE=1  扩展指令选择  G=1  开图形显示
  x = 0x80;
  yC = 0x80;
  for (j = 0; j < 64; j++) {
    yC = 0x80;
    SendCMD(x);
    SendCMD(yC);
    for (i = 0; i < 32; i++) {
      SendData(0x00);
    }
    x = x + 1;
  }
}

void Put(u8 *p) {
  u8 xx, yy;
  for (yy = 0; yy < 32; yy++)
    for (xx = 0; xx < 8; xx++) {
      SendCMD(0x80 + yy);  // y 按位
      SendCMD(0x80 + xx);  // x 按16位
      SendData(*p);
      p++;
      SendData(*p);
      p++;
    }
  for (yy = 0; yy < 32; yy++)
    for (xx = 8; xx < 16; xx++) {
      SendCMD(0x80 + yy);  // y 按位
      SendCMD(0x80 + xx);  // x 按16位
      SendData(*p);
      p++;
      SendData(*p);
      p++;
    }
}

void Write_Char(u8 start, u8 ddata) {
  u8 start_data, Hdata, Ldata;
  if (start == 0)
    start_data = 0xf8;  // 写指令
  else
    start_data = 0xfa;          // 写数据
  Hdata = ddata & 0xf0;         // 取高四位
  Ldata = (ddata << 4) & 0xf0;  // 取低四位
  Send_Byte(start_data);        // 发送起始信号
  delay_us(100);                // 延时是必须的
  Send_Byte(Hdata);             // 发送高四位
  delay_us(100);                // 延时是必须的
  Send_Byte(Ldata);             // 发送低四位
  delay_us(100);                // 延时是必须的
}

void Lcd_Init(void) {
  CS_L;
  Delay1ms(250);  // 启动等待，等LCM讲入工作状态
  CS_H;
  Write_Char(0, 0x30);  // 8 位介面，基本指令集
  // delay_us(250);
  Write_Char(0, 0x30);  // 8 位介面，基本指令集
  // delay_us(250);
  Write_Char(0, 0x0c);  // 显示打开，光标关，反白关
  // delay_us(250);
  Write_Char(0, 0x01);  // 清屏，将DDRAM的地址计数器归零
  Delay1ms(100);
}

void Clr_Scr(void) {  // 清屏函数
  Write_Char(0, 0x01);
  Delay1ms(50);
}

void LCD_Set_XY(u8 X, u8 Y) {
  u8 address;
  switch (X) {
    case 0:
      address = 0x80 + Y;
      break;
    case 1:
      address = 0x80 + Y;
      break;
    case 2:
      address = 0x90 + Y;
      break;
    case 3:
      address = 0x88 + Y;
      break;
    case 4:
      address = 0x98 + Y;
      break;
    default:
      address = 0x80 + Y;
      break;
  }
  Write_Char(0, address);
  // delay_us(100);
}

void LCD_Write_String(u8 X, u8 Y, uc8 *s)  //
{
  // delay_us(100);
  LCD_Set_XY(X, Y);
  // delay_us(50);
  while (*s) {
    Write_Char(1, *s);
    s++;
    // delay_us(100);
  }
}

void LCD_Write_String1(u8 X, u8 Y, u8 len, uc8 *s)  //
{
  // delay_us(100);
  LCD_Set_XY(X, Y);
  // delay_us(50);
  while (len--) {
    Write_Char(1, *s);
    s++;
    // delay_us(100);
  }
}
void LCD_Write_Number(u8 s)  // 数字显示函数
{
  if (s > 15) s = 0;
  Write_Char(1, num_lcd[s]);
  // delay_us(100);
}

void Put1(u8 *p) {
  u8 yy;  // xx,
  for (yy = 0; yy < 16; yy++)
  // for(xx=0;xx<8;xx++)
  {
    SendCMD(0x80 + yy);  // y 按位
    SendCMD(0x80);       // x 按16位
    SendData(*p);
    p++;
    SendData(*p);
    p++;
  }
  //	for(yy=0;yy<32;yy++)
  //		for(xx=8;xx<16;xx++)
  //		{
  //			SendCMD(0x80+yy);   //y 按位
  //			SendCMD(0x80+xx);//x 按16位
  //			SendData(*p);
  //			p++;
  //			SendData(*p);
  //			p++;
  //		}
}

void Set_White(u8 x, u8 y, u8 end_x, u8 clear) {
  u8 i, j, white_x, white_y, white_end_x, clr_x, clr_y;  //
  white_end_x = (end_x - x + 1);
  white_end_x <<= 1;
  if (y == 1) {
    white_x = (0x80 + x - 1);
    white_y = 0x80;
    clr_x = 0x80;
    clr_y = 0x80;
  } else if (y == 2) {
    white_x = (0x80 + x - 1);
    white_y = 0x90;
    clr_x = 0x80;
    clr_y = 0x90;
  } else if (y == 3) {
    white_x = (0x88 + x - 1);
    white_y = 0x80;
    clr_x = 0x88;
    clr_y = 0x80;
  } else if (y == 4) {
    white_x = (0x88 + x - 1);
    white_y = 0x90;
    clr_x = 0x88;
    clr_y = 0x90;
  }
  if (clear == 0)  // 要反白时，先将整行的液晶全部清成不反白（此处行指y）
  {
    for (i = 0; i < 16; i++) {  // 16行
      SendCMD(clr_y++);         // 设置绘图区的Y地址坐标0
      SendCMD(clr_x);           // 设置绘图区的X地址坐标0
      for (j = 0; j < 16; j++) {
        SendData(0x00);  // 清成不反白
      }
    }
  }
  // delay_us(100);
  for (i = 0; i < 16; i++)  // 16行，因为是16*16汉字
  {
    SendCMD(white_y++);  // 设置绘图区的Y地址坐标0
    SendCMD(white_x);    // 设置绘图区的X地址坐标0
    for (j = 0; j < white_end_x; j++) {
      if (clear == 1) {
        SendData(0x00);  // 取消这一行的8个点的反白，液晶地址自动加1
        // （此处行指一个一个液晶点所组成的行）
      } else {
        SendData(0xff);  // 反白这一行的8个点，液晶地址自动加1
        // （此处行指一个一个液晶点所组成的行）
      }
    }
  }
}
