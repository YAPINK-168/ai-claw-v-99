

#ifndef __KEY_H
#define __KEY_H

#include "sys.h"
#include "stm32_cpu.h"

extern  u8 KeyTime;  //继电器时长
extern  u8 KeyNum;   //继电器值
extern u8 KeyTime;  //继电器时长
extern u8  KeyTime1, KeyTime2, KeyTime3, KeyTime4;
extern u8 KeyNum1,KeyNum2,KeyNum3,KeyNum4;   //继电器值 

extern u16 Leftdoortime;
extern u16 rightdoortime;
extern u16 Leftcuptime;
extern u16 rightcuptime;
extern u8 rightdoorflay;

void Key_Init(void);
void Relay_on_proc(void);         //继电器开
void Relay_off_proc(void);         //继电器关	
void automatic(u8 PK);//自动门控制
void playkey(void);



#endif

