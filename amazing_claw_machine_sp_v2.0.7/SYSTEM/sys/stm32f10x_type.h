/******************** (C) COPYRIGHT 2007 STMicroelectronics ********************
* File Name          : stm32f10x_type.h
* Author             : MCD Application Team
* Version            : V1.0
* Date               : 10/08/2007
* Description        : This file contains all the common data types used for the
*                      STM32F10x firmware library.
********************************************************************************
* THE PRESENT SOFTWARE WHICH IS FOR GUIDANCE ONLY AIMS AT PROVIDING CUSTOMERS
* WITH CODING INFORMATION REGARDING THEIR PRODUCTS IN ORDER FOR THEM TO SAVE TIME.
* AS A RESULT, STMICROELECTRONICS SHALL NOT BE HELD LIABLE FOR ANY DIRECT,
* INDIRECT OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING FROM THE
* CONTENT OF SUCH SOFTWARE AND/OR THE USE MADE BY CUSTOMERS OF THE CODING
* INFORMATION CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
*******************************************************************************/

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __STM32F10x_TYPE_H
#define __STM32F10x_TYPE_H

#include "sys.h"

/* Includes ------------------------------------------------------------------*/
/* Exported types ------------------------------------------------------------*/
//typedef signed long  s32;
//typedef signed short s16;
//typedef signed char  s8;  
//
//typedef signed long  const sc32;  /* Read Only */
//typedef signed short const sc16;  /* Read Only */
//typedef signed char  const sc8;   /* Read Only */
//
//typedef volatile signed long  vs32;
//typedef volatile signed short vs16;
//typedef volatile signed char  vs8;
//
//typedef volatile signed long  const vsc32;  /* Read Only */
//typedef volatile signed short const vsc16;  /* Read Only */
//typedef volatile signed char  const vsc8;   /* Read Only */
//
//typedef unsigned long  u32;
//typedef unsigned short u16;
//typedef unsigned char  u8;
//
//typedef unsigned long  const uc32;  /* Read Only */
//typedef unsigned short const uc16;  /* Read Only */
//typedef unsigned char  const uc8;   /* Read Only */
//
//typedef volatile unsigned long  vu32;
//typedef volatile unsigned short vu16;
//typedef volatile unsigned char  vu8;
//
//typedef volatile unsigned long  const vuc32;  /* Read Only */
//typedef volatile unsigned short const vuc16;  /* Read Only */
//typedef volatile unsigned char  const vuc8;   /* Read Only */

typedef enum {FALSE = 0, TRUE = !FALSE} bool;

//typedef enum {RESET = 0, SET = !RESET} FlagStatus, ITStatus;

//typedef enum {DISABLE = 0, ENABLE = !DISABLE} FunctionalState;
//#define IS_FUNCTIONAL_STATE(STATE) ((STATE == DISABLE) || (STATE == ENABLE))

//typedef enum {ERROR = 0, SUCCESS = !ERROR} ErrorStatus;

#define U8_MAX     ((u8)255)
#define S8_MAX     ((s8)127)
#define S8_MIN     ((s8)-128)
#define U16_MAX    ((u16)65535u)
#define S16_MAX    ((s16)32767)
#define S16_MIN    ((s16)-32768)
#define U32_MAX    ((u32)4294967295uL)
#define S32_MAX    ((s32)2147483647)
#define S32_MIN    ((s32)2147483648uL)
//#define GPIO_Pin_0                 ((u16)0x0001)  /* Pin 0 selected */
//#define GPIO_Pin_1                 ((u16)0x0002)  /* Pin 1 selected */
//#define GPIO_Pin_2                 ((u16)0x0004)  /* Pin 2 selected */
//#define GPIO_Pin_3                 ((u16)0x0008)  /* Pin 3 selected */
//#define GPIO_Pin_4                 ((u16)0x0010)  /* Pin 4 selected */
//#define GPIO_Pin_5                 ((u16)0x0020)  /* Pin 5 selected */
//#define GPIO_Pin_6                 ((u16)0x0040)  /* Pin 6 selected */
//#define GPIO_Pin_7                 ((u16)0x0080)  /* Pin 7 selected */
//#define GPIO_Pin_8                 ((u16)0x0100)  /* Pin 8 selected */
//#define GPIO_Pin_9                 ((u16)0x0200)  /* Pin 9 selected */
//#define GPIO_Pin_10                ((u16)0x0400)  /* Pin 10 selected */
//#define GPIO_Pin_11                ((u16)0x0800)  /* Pin 11 selected */
//#define GPIO_Pin_12                ((u16)0x1000)  /* Pin 12 selected */
//#define GPIO_Pin_13                ((u16)0x2000)  /* Pin 13 selected */
//#define GPIO_Pin_14                ((u16)0x4000)  /* Pin 14 selected */
//#define GPIO_Pin_15                ((u16)0x8000)  /* Pin 15 selected */
//#define GPIO_Pin_All               ((u16)0xFFFF)  /* All pins selected */

/* 32位处理器的数据结构  */
	typedef union {
	        u8   B8[2];
	        u16  B16;
	} WORD2;
	
	typedef union {
	        u8   B8[4];
	        u16  B16[2];
	        u32  B32;
	} WORD4;

	typedef union {
	  u32 Long;
	  struct {
	    u8 B0       :1;                                       
	    u8 B1       :1;                                       
	    u8 B2       :1;                                       
	    u8 B3       :1;                                       
	    u8 B4       :1;                                       
	    u8 B5       :1;                                       
	    u8 B6       :1;                                       
	    u8 B7       :1;  
	
	    u8 B8       :1;                                       
	    u8 B9       :1;                                       
	    u8 B10       :1;                                       
	    u8 B11       :1;                                       
	    u8 B12       :1;                                       
	    u8 B13       :1;                                       
	    u8 B14       :1;                                       
	    u8 B15       :1;  
	
	    u8 B16       :1;                                       
	    u8 B17       :1;                                       
	    u8 B18       :1;                                       
	    u8 B19       :1;                                       
	    u8 B20       :1;                                       
	    u8 B21       :1;                                       
	    u8 B22       :1;                                       
	    u8 B23       :1;  
		
			u8 B24       :1;                                       
	    u8 B25       :1;                                       
	    u8 B26       :1;                                       
	    u8 B27       :1;                                       
	    u8 B28       :1;                                       
	    u8 B29       :1;                                       
	    u8 B30       :1;                                       
	    u8 B31       :1;  	                                     
	  } Bits;
	} Mybit;
	
	typedef union {
	  u16 Word;
	  struct {
	    u8 B0       :1;                                       
	    u8 B1       :1;                                       
	    u8 B2       :1;                                       
	    u8 B3       :1;                                       
	    u8 B4       :1;                                       
	    u8 B5       :1;                                       
	    u8 B6       :1;                                       
	    u8 B7       :1;  
	
	    u8 B8       :1;                                       
	    u8 B9       :1;                                       
	    u8 B10       :1;                                       
	    u8 B11       :1;                                       
	    u8 B12       :1;                                       
	    u8 B13       :1;                                       
	    u8 B14       :1;                                       
	    u8 B15       :1;  
	  } Bits;
	} Mybit16;
	
	typedef union {
	  u8 Byte;
	  struct {
	    u8 B0       :1;                                       
	    u8 B1       :1;                                       
	    u8 B2       :1;                                       
	    u8 B3       :1;                                       
	    u8 B4       :1;                                       
	    u8 B5       :1;                                       
	    u8 B6       :1;                                       
	    u8 B7       :1;  
	  } Bits;
	} Mybit8;
	
/* Exported constants --------------------------------------------------------*/
/* Exported macro ------------------------------------------------------------*/
/* Exported functions ------------------------------------------------------- */

#endif /* __STM32F10x_TYPE_H */

/******************* (C) COPYRIGHT 2007 STMicroelectronics *****END OF FILE****/
