#ifndef __LED_APP_H
#define __LED_APP_H

#include "bsp.h"
#include "define.h"

void LED_App_Init(void);
void LED_App_Isr(void);
void LED_App_SetLed1FlashOn(uint16_t on_time, uint16_t off_time, uint32_t show_time, uint8_t off_status);
void LED_App_SetLed1FlashOff(uint8_t off_status);
void LED_App_SetLed2Flash(uint16_t on_time, uint16_t off_time, uint32_t show_time, uint8_t off_status);
void LED_App_SetLed2FlashOff(uint8_t off_status);

#endif
