
#ifndef __GSMBT_H
#define __GSMBT_H
#include "stm32_cpu.h"

u16  Tick_ReqKeep_OnLine_time=0;
u8 md5key[]={"pW5guzEMkas2PIqh"};

void Tick(void);
void Send_Tick(void);
void GsmSend(char* p);
void Add_md5_keymark(u8 *str);
void Add_md5_keymark_coinin(u8 *str);
void Add_md5_keymark_CHSQ(u8 *str);
u8 Compare_md5_keymark(u8 *str);

#endif



