#ifdef HARDWARE_V2

#ifndef __IRQ_HV2_H
#define __IRQ_HV2_H

#include "stm32_cpu.h"

//typedef struct{

//Mybit Req;
//Mybit Res;

//}DATA_Type;

//DATA_Type Com;
//DATA_Type Enable;
//DATA_Type Sout;

//extern DATA_Type Com;
//extern DATA_Type Enable;
//extern DATA_Type Sout;

u8 coininlock1=0;
u8 coininlock2=0;

u8 enterkeylock1=0;
u8 enterkeylock2=0;

u8 outsentorlock1=0;
u8 outsentorlock2=0;

u8 setkeylock1=0;
u8 setkeylock2=0;

u8 frontkeylock1=0;
u8 frontkeylock2=0;

u8 backkeylock1=0;
u8 backkeylock2=0;

u8 rightkeylock1=0;
u8 rightkeylock2=0;

u8 leftkeylock1=0;
u8 leftkeylock2=0;

u8 coinlock=0;
u8 loselock=0;
volatile u8 losetimeH=5;
volatile u8 losetimeL=2;
volatile u8 losetime=0;
u8  losesqr=0;

volatile u32 losttime=0;

u8 ledflash=0;
u8 RX1count=0;
u8 RX2count=0;
u8 RX3count=0;
u16 Time_10ms_cnt=0;
u16 Time1_1s_cnt=0;
u16 Time2_1s_cnt=0;
u8 USART2_Rx_time=0;
u8 USART3_Rx_time=0;
u8 USART1_Rx_time=0;
volatile	u8 USART2_SR_temp=0;

u8 Cartnum[9]={"00A6E1421"};//卡号
u8 Count[6]={"765432"};//余额
//u8 Screnub[17]={"12345678912345678"};//密钥
u8 Coinnum[4]={"4560"};//投币金额
u8 Qrnum[10]={"1234567890"};//Qr码
u8 QrCH[10]={"1234567890"};//充值Qr码UsrCH

u8 UsrCH[12]={"123456789000"};//充值用户

u8 Userid[12]={"123456789000"};//用户id

u8 Userid0[12]={"123456789000"};//用户id
u8 paymoney[4]={"0020"};//支付金额

u8  RX1_buffer[300]={0x00,0x00,0x00,};
// u8  RX2_buffer[100]={"000000"};
u8  RX2_buffer[300]={"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"};

void USART1_IRQHandler(void);
void USART2_IRQHandler(void);
void USART3_IRQHandler(void);

void TIM1_CC_IRQHandler(void);

#endif

#endif
