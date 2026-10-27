#ifndef __STM32_CPU_H
#define __STM32_CPU_H
#include "stm32f10x_type.h"
//#include "sys.h"

void Platform_Init(void);
void GPIO_Configuration(void);
void RCC_Configuration(void);
void NVIC_Configuration(void);
void IWDG_Configuration(u16 time);
void USART1_Configuration(void);
void USART2_Configuration(void);
void USART3_Configuration(void);
void USART4_Configuration(void);
void USART5_Configuration(void);
void TIM2_Configuration(void);
void TIME1_Configuration(void);
void WDG_Configuration(void);
void Tim3_Init(u16 arr,u16 psc);
#endif
