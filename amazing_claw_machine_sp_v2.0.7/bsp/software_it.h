#ifndef __SOFTWARE_IT_H
#define __SOFTWARE_IT_H

#include "bsp.h"

#define KEY1_IF_BIT ((uint16_t)0x0001)  /* Pin 0 selected    */
#define KEY2_IF_BIT ((uint16_t)0x0002)  /* Pin 1 selected    */
#define KEY3_IF_BIT ((uint16_t)0x0004)  /* Pin 2 selected    */
#define KEY4_IF_BIT ((uint16_t)0x0008)  /* Pin 3 selected    */
#define KEY_IF_BIT ((uint16_t)0x0010)   /* Pin 4 selected    */
#define SLEEP_IF_BIT ((uint16_t)0x0020) /* Pin 5 selected    */
#define RF_IF_BIT ((uint16_t)0x0040)    /* Pin 6 selected    */
#define LPT_IF_BIT ((uint16_t)0x0080)  /* Pin 7 selected    */
#define KEY9_IF_BIT ((uint16_t)0x0100)  /* Pin 8 selected    */
#define KEY10_IF_BIT ((uint16_t)0x0200) /* Pin 9 selected    */
#define KEY11_IF_BIT ((uint16_t)0x0400) /* Pin 10 selected   */
#define KEY12_IF_BIT ((uint16_t)0x0800) /* Pin 11 selected   */
#define KEY13_IF_BIT ((uint16_t)0x1000) /* Pin 12 selected   */
#define KEY14_IF_BIT ((uint16_t)0x2000) /* Pin 13 selected   */
#define KEY15_IF_BIT ((uint16_t)0x4000) /* Pin 14 selected   */
#define KEY16_IF_BIT ((uint16_t)0x8000) /* Pin 15 selected   */
#define IF_All ((uint16_t)0xFFFF)       /* All pins selected */

#define SYS_IF_REG g_software_if
#define SET_SYS_IF(a) (SYS_IF_REG |= (a))
#define CRL_SYS_IF(a) (SYS_IF_REG &= ~(a))
#define GET_SYS_IF(a) (SYS_IF_REG & (a))

void SoftwareTick_Handler(void);
void CycleTask_Isr(void);

#endif
