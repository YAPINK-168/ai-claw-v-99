
/******************** (C) COPYRIGHT 2010 Linsir ********************
* File Name          : stm32f10x_map_lin.h (from:stm32f10xxB.h)
* Author             : Linsir
* Date First Issued  : 2010-4-15
* Revision           : V1.0
* Description        : This file be only used for STM32F1*(volatile unsigned long *)0x.
*        说明        : 定义了STM32F10x寄存器地址
***********************************************************************/

#ifndef __stm32f10x_map_lin_h
#define __stm32f10x_map_lin_h


#define BITBAND(addr, bitnum) ((addr & 0xF0000000)+0x2000000+((addr &0xFFFFF)<<5)+(bitnum<<2)) 
#define MEM_ADDR(addr)  *((volatile unsigned long  *)(addr)) 
#define BIT_ADDR(addr, bitnum)   MEM_ADDR(BITBAND(addr, bitnum)) 
//IO口地址映射
#define GPIOA_ODR_Addr    (GPIOA_BASE+12) //0x4001080C 
#define GPIOB_ODR_Addr    (GPIOB_BASE+12) //0x40010C0C 
#define GPIOC_ODR_Addr    (GPIOC_BASE+12) //0x4001100C 
#define GPIOD_ODR_Addr    (GPIOD_BASE+12) //0x4001140C 
#define GPIOE_ODR_Addr    (GPIOE_BASE+12) //0x4001180C 
#define GPIOF_ODR_Addr    (GPIOF_BASE+12) //0x40011A0C    
#define GPIOG_ODR_Addr    (GPIOG_BASE+12) //0x40011E0C    

#define GPIOA_IDR_Addr    (GPIOA_BASE+8) //0x40010808 
#define GPIOB_IDR_Addr    (GPIOB_BASE+8) //0x40010C08 
#define GPIOC_IDR_Addr    (GPIOC_BASE+8) //0x40011008 
#define GPIOD_IDR_Addr    (GPIOD_BASE+8) //0x40011408 
#define GPIOE_IDR_Addr    (GPIOE_BASE+8) //0x40011808 
#define GPIOF_IDR_Addr    (GPIOF_BASE+8) //0x40011A08 
#define GPIOG_IDR_Addr    (GPIOG_BASE+8) //0x40011E08 
 
//IO口操作,只对单一的IO口!
//确保n的值小于16!
#define PAout(n)   BIT_ADDR(GPIOA_ODR_Addr,n)  //输出 
#define PAin(n)    BIT_ADDR(GPIOA_IDR_Addr,n)  //输入 

#define PBout(n)   BIT_ADDR(GPIOB_ODR_Addr,n)  //输出 
#define PBin(n)    BIT_ADDR(GPIOB_IDR_Addr,n)  //输入 

#define PCout(n)   BIT_ADDR(GPIOC_ODR_Addr,n)  //输出 
#define PCin(n)    BIT_ADDR(GPIOC_IDR_Addr,n)  //输入 

#define PDout(n)   BIT_ADDR(GPIOD_ODR_Addr,n)  //输出 
#define PDin(n)    BIT_ADDR(GPIOD_IDR_Addr,n)  //输入 

#define PEout(n)   BIT_ADDR(GPIOE_ODR_Addr,n)  //输出 
#define PEin(n)    BIT_ADDR(GPIOE_IDR_Addr,n)  //输入

#define PFout(n)   BIT_ADDR(GPIOF_ODR_Addr,n)  //输出 
#define PFin(n)    BIT_ADDR(GPIOF_IDR_Addr,n)  //输入

#define PGout(n)   BIT_ADDR(GPIOG_ODR_Addr,n)  //输出 
#define PGin(n)    BIT_ADDR(GPIOG_IDR_Addr,n)  //输入

/* Declarations common to compiler and assembler  **************************/	
/***************************************************************************	
 **	
 ** PWR	
 **	
 ***************************************************************************/	
#define PWR_CR	            *(volatile unsigned long *)0x40007000              
#define PWR_CSR	            *(volatile unsigned long *)0x40007004              
	
/***************************************************************************	
 **	
 ** RCC	
 **	
 ***************************************************************************/	
#define RCC_CR	             *(volatile unsigned long *)0x40021000              
#define RCC_CFGR	         *(volatile unsigned long *)0x40021004              
#define RCC_CIR	             *(volatile unsigned long *)0x40021008              
#define RCC_APB2RSTR	     *(volatile unsigned long *)0x4002100C              
#define RCC_APB1RSTR	     *(volatile unsigned long *)0x40021010              
#define RCC_AHBENR	         *(volatile unsigned long *)0x40021014              
#define RCC_APB2ENR	         *(volatile unsigned long *)0x40021018              
#define RCC_APB1ENR	         *(volatile unsigned long *)0x4002101C              
#define RCC_BDCR	         *(volatile unsigned long *)0x40021020              
#define RCC_CSR	          	 *(volatile unsigned long *)0x40021024              
	
/***************************************************************************	
 **	
 ** GPIOA	
 **	
 ***************************************************************************/	
#define GPIOA_CRL	         *(volatile unsigned long *)0x40010800              
#define GPIOA_CRH	         *(volatile unsigned long *)0x40010804              
#define GPIOA_IDR	         *(volatile unsigned long *)0x40010808                    
#define GPIOA_ODR	         *(volatile unsigned long *)0x4001080C              
#define GPIOA_BSRR	      	 *(volatile unsigned long *)0x40010810                   
#define GPIOA_BRR	         *(volatile unsigned long *)0x40010814                   
#define GPIOA_LCKR	      	 *(volatile unsigned long *)0x40010818              
	
/***************************************************************************	
 **	
 ** GPIOB	
 **	
 ***************************************************************************/	
#define GPIOB_CRL	         *(volatile unsigned long *)0x40010C00              
#define GPIOB_CRH	         *(volatile unsigned long *)0x40010C04              
#define GPIOB_IDR	         *(volatile unsigned long *)0x40010C08                    
#define GPIOB_ODR	         *(volatile unsigned long *)0x40010C0C              
#define GPIOB_BSRR	       	 *(volatile unsigned long *)0x40010C10                   
#define GPIOB_BRR	         *(volatile unsigned long *)0x40010C14                   
#define GPIOB_LCKR	       	 *(volatile unsigned long *)0x40010C18              
	
/***************************************************************************	
 **	
 ** GPIOC	
 **	
 ***************************************************************************/	
#define GPIOC_CRL	         *(volatile unsigned long *)0x40011000              
#define GPIOC_CRH	         *(volatile unsigned long *)0x40011004              
#define GPIOC_IDR	         *(volatile unsigned long *)0x40011008                    
#define GPIOC_ODR	         *(volatile unsigned long *)0x4001100C              
#define GPIOC_BSRR	       	 *(volatile unsigned long *)0x40011010                   
#define GPIOC_BRR	         *(volatile unsigned long *)0x40011014                   
#define GPIOC_LCKR	       	 *(volatile unsigned long *)0x40011018              
	
/***************************************************************************	
 **	
 ** GPIOD	
 **	
 ***************************************************************************/	
#define GPIOD_CRL	         *(volatile unsigned long *)0x40011400              
#define GPIOD_CRH	         *(volatile unsigned long *)0x40011404              
#define GPIOD_IDR	         *(volatile unsigned long *)0x40011408                    
#define GPIOD_ODR	         *(volatile unsigned long *)0x4001140C              
#define GPIOD_BSRR	       	 *(volatile unsigned long *)0x40011410                   
#define GPIOD_BRR	         *(volatile unsigned long *)0x40011414                   
#define GPIOD_LCKR	       	 *(volatile unsigned long *)0x40011418              
	
/***************************************************************************	
 **	
 ** GPIOE	
 **	
 ***************************************************************************/	
#define GPIOE_CRL	         *(volatile unsigned long *)0x40011800              
#define GPIOE_CRH	         *(volatile unsigned long *)0x40011804              
#define GPIOE_IDR	         *(volatile unsigned long *)0x40011808                    
#define GPIOE_ODR	         *(volatile unsigned long *)0x4001180C              
#define GPIOE_BSRR	       	 *(volatile unsigned long *)0x40011810                   
#define GPIOE_BRR	         *(volatile unsigned long *)0x40011814                   
#define GPIOE_LCKR	       	 *(volatile unsigned long *)0x40011818              
	
/***************************************************************************	
 **	
 ** AFIO	
 **	
 ***************************************************************************/	
#define AFIO_EVCR	          *(volatile unsigned long *)0x40010000              
#define AFIO_MAPR	          *(volatile unsigned long *)0x40010004              
#define AFIO_EXTICR1	      *(volatile unsigned long *)0x40010008              
#define AFIO_EXTICR2	      *(volatile unsigned long *)0x4001000C              
#define AFIO_EXTICR3	      *(volatile unsigned long *)0x40010010              
#define AFIO_EXTICR4	      *(volatile unsigned long *)0x40010014              
	
/***************************************************************************	
 **	
 ** EXTI	
 **	
 ***************************************************************************/	
#define EXTI_IMR	          *(volatile unsigned long *)0x40010400              
#define EXTI_EMR	          *(volatile unsigned long *)0x40010404              
#define EXTI_RTSR	          *(volatile unsigned long *)0x40010408              
#define EXTI_FTSR	          *(volatile unsigned long *)0x4001040C              
#define EXTI_SWIER			  *(volatile unsigned long *)0x40010410              
#define EXTI_PR	              *(volatile unsigned long *)0x40010414              
	
/***************************************************************************	
 **	
 ** DMA	
 **	
 ***************************************************************************/	
#define     DMA_ISR	            *(volatile unsigned long *)0x40020000                    
#define     DMA_IFCR	          *(volatile unsigned long *)0x40020004 
             
#define     DMA_CCR1	          *(volatile unsigned long *)0x40020008              
#define     DMA_CNDTR1	        *(volatile unsigned long *)0x4002000C              
#define     DMA_CPAR1	         *(volatile unsigned long *)0x40020010              
#define     DMA_CMAR1	         *(volatile unsigned long *)0x40020014  
           
#define     DMA_CCR2	         *(volatile unsigned long *)0x4002001C              
#define     DMA_CNDTR2	       *(volatile unsigned long *)0x40020020              
#define     DMA_CPAR2	         *(volatile unsigned long *)0x40020024             
#define     DMA_CMAR2	         *(volatile unsigned long *)0x40020028  
            
#define     DMA_CCR3	         *(volatile unsigned long *)0x40020030              
#define     DMA_CNDTR3	       *(volatile unsigned long *)0x40020034              
#define     DMA_CPAR3	         *(volatile unsigned long *)0x40020038              
#define     DMA_CMAR3	         *(volatile unsigned long *)0x4002003C  
            
#define     DMA_CCR4	         *(volatile unsigned long *)0x40020044              
#define     DMA_CNDTR4	       *(volatile unsigned long *)0x40020048              
#define     DMA_CPAR4	         *(volatile unsigned long *)0x4002004C             
#define     DMA_CMAR4	         *(volatile unsigned long *)0x40020050  
          
#define     DMA_CCR5	         *(volatile unsigned long *)0x40020058              
#define     DMA_CNDTR5	       *(volatile unsigned long *)0x4002005C              
#define     DMA_CPAR5	         *(volatile unsigned long *)0x40020060           
#define     DMA_CMAR5	         *(volatile unsigned long *)0x40020064  
       
#define     DMA_CCR6	         *(volatile unsigned long *)0x4002006C              
#define     DMA_CNDTR6	       *(volatile unsigned long *)0x40020070              
#define     DMA_CPAR6	         *(volatile unsigned long *)0x40020074           
#define     DMA_CMAR6	         *(volatile unsigned long *)0x40020078   
      
#define     DMA_CCR7	         *(volatile unsigned long *)0x40020080              
#define     DMA_CNDTR7	       *(volatile unsigned long *)0x40020084              
#define     DMA_CPAR7	         *(volatile unsigned long *)0x40020088          
#define     DMA_CMAR7	         *(volatile unsigned long *)0x4002008C        
	
/***************************************************************************	
 **	
 ** RTC	
 **	
 ***************************************************************************/	
#define     RTC_CRH	              *(volatile unsigned long *)0x40002800              
#define     RTC_CRL	              *(volatile unsigned long *)0x40002804              
#define     RTC_PRLH	          *(volatile unsigned long *)0x40002808                   
#define     RTC_PRLL	          *(volatile unsigned long *)0x4000280C             
#define     RTC_DIVH	          *(volatile unsigned long *)0x40002810                    
#define     RTC_DIVL	          *(volatile unsigned long *)0x40002814               
#define     RTC_CNTH	          *(volatile unsigned long *)0x40002818           
#define     RTC_CNTL	          *(volatile unsigned long *)0x4000281C             
#define     RTC_ALRH	          *(volatile unsigned long *)0x40002820                 
#define     RTC_ALRL	          *(volatile unsigned long *)0x40002824                  
	
/***************************************************************************	
 **	
 ** BKP	
 **	
 ***************************************************************************/	
//#define     BKP_DR1	           *(volatile unsigned long *)0x40006C04              
//#define     BKP_DR2	           *(volatile unsigned long *)0x40006C08              
//#define     BKP_DR3	           *(volatile unsigned long *)0x40006C0C             
//#define     BKP_DR4	           *(volatile unsigned long *)0x40006C10             
//#define     BKP_DR5	           *(volatile unsigned long *)0x40006C14             
//#define     BKP_DR6	           *(volatile unsigned long *)0x40006C18            
//#define     BKP_DR7	           *(volatile unsigned long *)0x40006C1C              
//#define     BKP_DR8	           *(volatile unsigned long *)0x40006C20              
//#define     BKP_DR9	           *(volatile unsigned long *)0x40006C24              
//#define     BKP_DR10	         *(volatile unsigned long *)0x40006C28              
//#define     BKP_RTCCR	         *(volatile unsigned long *)0x40006C2C              
//#define     BKP_CR	           *(volatile unsigned long *)0x40006C30              
//#define     BKP_CSR	           *(volatile unsigned long *)0x40006C34              
	
/***************************************************************************	
 **	
 ** IWDG	
 **	
 ***************************************************************************/	
#define IWDG_KR	           *(volatile unsigned long *)0x40003000                  
#define IWDG_PR	           *(volatile unsigned long *)0x40003004              
#define IWDG_RLR	         *(volatile unsigned long *)0x40003008              
#define IWDG_SR	           *(volatile unsigned long *)0x4000300C                    
	
/***************************************************************************	
 **	
 ** WWDG	
 **	
 ***************************************************************************/	
#define WWDG_CR	           *(volatile unsigned long *)0x40002C00              
#define WWDG_CFR	         *(volatile unsigned long *)0x40002C04              
#define WWDG_SR	           *(volatile unsigned long *)0x40002C08              
	
/***************************************************************************	
 **	
 ** TIM1	
 **	
 ***************************************************************************/	
#define TIM1_CR1	          *(volatile unsigned long *)0x40012C00              
#define TIM1_CR2	          *(volatile unsigned long *)0x40012C04              
#define TIM1_SMCR	          *(volatile unsigned long *)0x40012C08              
#define TIM1_DIER	          *(volatile unsigned long *)0x40012C0C              
#define TIM1_SR	              *(volatile unsigned long *)0x40012C10              
#define TIM1_EGR	            *(volatile unsigned long *)0x40012C14              
#define TIM1_CCMR1	          *(volatile unsigned long *)0x40012C18              
#define TIM1_OCMR1            TIM1_CCMR1	
#define TIM1_CCMR2	          *(volatile unsigned long *)0x40012C1C              
#define TIM1_OCMR2            TIM1_CCMR2	
#define TIM1_CCER	          *(volatile unsigned long *)0x40012C20              
#define TIM1_CNT	          *(volatile unsigned long *)0x40012C24              
#define TIM1_PSC	          *(volatile unsigned long *)0x40012C28              
#define TIM1_ARR	          *(volatile unsigned long *)0x40012C2C              
#define TIM1_RCR	          *(volatile unsigned long *)0x40012C30              
#define TIM1_CCR1	         *(volatile unsigned long *)0x40012C34              
#define TIM1_CCR2	         *(volatile unsigned long *)0x40012C38              
#define TIM1_CCR3	         *(volatile unsigned long *)0x40012C3C              
#define TIM1_CCR4	         *(volatile unsigned long *)0x40012C40              
#define TIM1_BDTR	         *(volatile unsigned long *)0x40012C44              
#define TIM1_DCR	         *(volatile unsigned long *)0x40012C48              
#define TIM1_DMAR	         *(volatile unsigned long *)0x40012C4C              
	
/***************************************************************************	
 **	
 ** TIM2	
 **	
 ***************************************************************************/	
#define TIM2_CR1	        *(volatile unsigned long *)0x40000000              
#define TIM2_CR2	        *(volatile unsigned long *)0x40000004              
#define TIM2_SMCR	        *(volatile unsigned long *)0x40000008              
#define TIM2_DIER	        *(volatile unsigned long *)0x4000000C              
#define TIM2_SR	         	*(volatile unsigned long *)0x40000010              
#define TIM2_EGR	        *(volatile unsigned long *)0x40000014              
#define TIM2_CCMR1	     	*(volatile unsigned long *)0x40000018              
#define TIM2_OCMR1        	TIM2_CCMR1		
#define TIM2_CCMR2	     	 *(volatile unsigned long *)0x4000001C              
#define TIM2_OCMR2       	 TIM2_CCMR2	
#define TIM2_CCER	         *(volatile unsigned long *)0x40000020              
#define TIM2_CNT	         *(volatile unsigned long *)0x40000024              
#define TIM2_PSC	         *(volatile unsigned long *)0x40000028              
#define TIM2_ARR	         *(volatile unsigned long *)0x4000002C              
#define TIM2_CCR1	         *(volatile unsigned long *)0x40000034              
#define TIM2_CCR2	         *(volatile unsigned long *)0x40000038              
#define TIM2_CCR3	         *(volatile unsigned long *)0x4000003C              
#define TIM2_CCR4	         *(volatile unsigned long *)0x40000040              
#define TIM2_DCR	         *(volatile unsigned long *)0x40000048              
#define TIM2_DMAR	         *(volatile unsigned long *)0x4000004C              
	
/***************************************************************************	
 **	
 ** TIM3	
 **	
 ***************************************************************************/	
#define TIM3_CR1	         *(volatile unsigned long *)0x40000400              
#define TIM3_CR2	         *(volatile unsigned long *)0x40000404              
#define TIM3_SMCR	         *(volatile unsigned long *)0x40000408              
#define TIM3_DIER	         *(volatile unsigned long *)0x4000040C              
#define TIM3_SR	           *(volatile unsigned long *)0x40000410              
#define TIM3_EGR	         *(volatile unsigned long *)0x40000414              
#define TIM3_CCMR1	         *(volatile unsigned long *)0x40000418              
#define TIM3_OCMR1           TIM3_CCMR1	
#define TIM3_CCMR2	         *(volatile unsigned long *)0x4000041C              
#define TIM3_OCMR2           TIM3_CCMR2		
#define TIM3_CCER	         *(volatile unsigned long *)0x40000420              
#define TIM3_CNT	         *(volatile unsigned long *)0x40000424              
#define TIM3_PSC	         *(volatile unsigned long *)0x40000428              
#define TIM3_ARR	         *(volatile unsigned long *)0x4000042C              
#define TIM3_CCR1	         *(volatile unsigned long *)0x40000434              
#define TIM3_CCR2	         *(volatile unsigned long *)0x40000438              
#define TIM3_CCR3	         *(volatile unsigned long *)0x4000043C              
#define TIM3_CCR4	         *(volatile unsigned long *)0x40000440              
#define TIM3_DCR	         *(volatile unsigned long *)0x40000448              
#define TIM3_DMAR	         *(volatile unsigned long *)0x4000044C              
	
/***************************************************************************	
 **	
 ** TIM4	
 **	
 ***************************************************************************/	
#define TIM4_CR1	        *(volatile unsigned long *)0x40000800              
#define TIM4_CR2	        *(volatile unsigned long *)0x40000804              
#define TIM4_SMCR	        *(volatile unsigned long *)0x40000808              
#define TIM4_DIER	        *(volatile unsigned long *)0x4000080C              
#define TIM4_SR	          *(volatile unsigned long *)0x40000810              
#define TIM4_EGR	        *(volatile unsigned long *)0x40000814              
#define TIM4_CCMR1	       *(volatile unsigned long *)0x40000818              
#define TIM4_OCMR1         TIM4_CCMR1		
#define TIM4_CCMR2	       *(volatile unsigned long *)0x4000081C              
#define TIM4_OCMR2         TIM4_CCMR2		
#define TIM4_CCER	         *(volatile unsigned long *)0x40000820              
#define TIM4_CNT	         *(volatile unsigned long *)0x40000824              
#define TIM4_PSC	         *(volatile unsigned long *)0x40000828              
#define TIM4_ARR	         *(volatile unsigned long *)0x4000082C              
#define TIM4_CCR1	         *(volatile unsigned long *)0x40000834              
#define TIM4_CCR2	         *(volatile unsigned long *)0x40000838              
#define TIM4_CCR3	         *(volatile unsigned long *)0x4000083C              
#define TIM4_CCR4	         *(volatile unsigned long *)0x40000840              
#define TIM4_DCR	         *(volatile unsigned long *)0x40000848              
#define TIM4_DMAR	         *(volatile unsigned long *)0x4000084C              
	
/***************************************************************************	
 **	
 ** bxCAN	
 **	
 ***************************************************************************/	
#define CAN_MCR	           *(volatile unsigned long *)0x40006400              
#define CAN_MSR	           *(volatile unsigned long *)0x40006404              
#define CAN_TSR	           *(volatile unsigned long *)0x40006408              
#define CAN_RF0R	         *(volatile unsigned long *)0x4000640C              
#define CAN_RF1R	         *(volatile unsigned long *)0x40006410              
#define CAN_IER	           *(volatile unsigned long *)0x40006414              
#define CAN_ESR	           *(volatile unsigned long *)0x40006418              
#define CAN_BTR	           *(volatile unsigned long *)0x4000641C              
#define CAN_TI0R	         *(volatile unsigned long *)0x40006580              
#define CAN_TDT0R	         *(volatile unsigned long *)0x40006584              
#define CAN_TDL0R	         *(volatile unsigned long *)0x40006588              
#define CAN_TDH0R	         *(volatile unsigned long *)0x4000658c              
#define CAN_TI1R	         *(volatile unsigned long *)0x40006590              
#define CAN_TDT1R	         *(volatile unsigned long *)0x40006594              
#define CAN_TDL1R	         *(volatile unsigned long *)0x40006598              
#define CAN_TDH1R	         *(volatile unsigned long *)0x4000659C              
#define CAN_TI2R	         *(volatile unsigned long *)0x400065A0              
#define CAN_TDT2R	         *(volatile unsigned long *)0x400065A4              
#define CAN_TDL2R	         *(volatile unsigned long *)0x400065A8              
#define CAN_TDH2R	         *(volatile unsigned long *)0x400065AC              
#define CAN_RI0R	         *(volatile unsigned long *)0x400065B0                    
#define CAN_RDT0R	         *(volatile unsigned long *)0x400065B4                    
#define CAN_RDL0R	         *(volatile unsigned long *)0x400065B8                    
#define CAN_RDH0R	         *(volatile unsigned long *)0x400065BC                    
#define CAN_RI1R	         *(volatile unsigned long *)0x400065C0                    
#define CAN_RDT1R	         *(volatile unsigned long *)0x400065C4                    
#define CAN_RDL1R	         *(volatile unsigned long *)0x400065C8                    
#define CAN_RDH1R	         *(volatile unsigned long *)0x400065CC                    
#define CAN_FMR	            *(volatile unsigned long *)0x40006600              
#define CAN_FM1R	          *(volatile unsigned long *)0x40006604              
#define CAN_FS1R	          *(volatile unsigned long *)0x4000660C              
#define CAN_FFA1R	          *(volatile unsigned long *)0x40006614              
#define CAN_FA1R	          *(volatile unsigned long *)0x4000661C              
#define CAN_F0R1	          *(volatile unsigned long *)0x40006640              
#define CAN_F0R2	          *(volatile unsigned long *)0x40006644              
#define CAN_F1R1	          *(volatile unsigned long *)0x40006648              
#define CAN_F1R2	          *(volatile unsigned long *)0x4000664C              
#define CAN_F2R1	          *(volatile unsigned long *)0x40006650              
#define CAN_F2R2	          *(volatile unsigned long *)0x40006654              
#define CAN_F3R1	          *(volatile unsigned long *)0x40006658              
#define CAN_F3R2	          *(volatile unsigned long *)0x4000665C              
#define CAN_F4R1	          *(volatile unsigned long *)0x40006660              
#define CAN_F4R2	          *(volatile unsigned long *)0x40006664              
#define CAN_F5R1	          *(volatile unsigned long *)0x40006668              
#define CAN_F5R2	          *(volatile unsigned long *)0x4000666C              
#define CAN_F6R1	          *(volatile unsigned long *)0x40006670              
#define CAN_F6R2	          *(volatile unsigned long *)0x40006674              
#define CAN_F7R1	          *(volatile unsigned long *)0x40006678              
#define CAN_F7R2	          *(volatile unsigned long *)0x4000667C              
#define CAN_F8R1	          *(volatile unsigned long *)0x40006680              
#define CAN_F8R2	          *(volatile unsigned long *)0x40006684              
#define CAN_F9R1	          *(volatile unsigned long *)0x40006688              
#define CAN_F9R2	          *(volatile unsigned long *)0x4000668C              
#define CAN_F10R1	         *(volatile unsigned long *)0x40006690              
#define CAN_F10R2	         *(volatile unsigned long *)0x40006694              
#define CAN_F11R1	         *(volatile unsigned long *)0x40006698              
#define CAN_F11R2	         *(volatile unsigned long *)0x4000669C              
#define CAN_F12R1	         *(volatile unsigned long *)0x400066A0              
#define CAN_F12R2	         *(volatile unsigned long *)0x400066A4              
#define CAN_F13R1	         *(volatile unsigned long *)0x400066A8              
#define CAN_F13R2	         *(volatile unsigned long *)0x400066AC              
	
/***************************************************************************	
 **	
 ** I2C1	
 **	
 ***************************************************************************/	
#define I2C1_CR1	          *(volatile unsigned long *)0x40005400              
#define I2C1_CR2	          *(volatile unsigned long *)0x40005404              
#define I2C1_OAR1	          *(volatile unsigned long *)0x40005408              
#define I2C1_OAR2	          *(volatile unsigned long *)0x4000540C              
#define I2C1_DR	           	  *(volatile unsigned long *)0x40005410              
#define I2C1_SR1	          *(volatile unsigned long *)0x40005414              
#define I2C1_SR2	          *(volatile unsigned long *)0x40005418                    
#define I2C1_CCR	          *(volatile unsigned long *)0x4000541C              
#define I2C1_TRISE	          *(volatile unsigned long *)0x40005420              
	
/***************************************************************************	
 **	
 ** I2C2	
 **	
 ***************************************************************************/	
#define I2C2_CR1	        *(volatile unsigned long *)0x40005800              
#define I2C2_CR2	        *(volatile unsigned long *)0x40005804              
#define I2C2_OAR1	        *(volatile unsigned long *)0x40005808              
#define I2C2_OAR2	        *(volatile unsigned long *)0x4000580C              
#define I2C2_DR	            *(volatile unsigned long *)0x40005810              
#define I2C2_SR1	        *(volatile unsigned long *)0x40005814              
#define I2C2_SR2	        *(volatile unsigned long *)0x40005818              
#define I2C2_CCR	        *(volatile unsigned long *)0x4000581C              
#define I2C2_TRISE	        *(volatile unsigned long *)0x40005820              
	
/***************************************************************************	
 **	
 ** SPI1	
 **	
 ***************************************************************************/	
#define SPI1_CR1	         *(volatile unsigned long *)0x40013000              
#define SPI1_CR2	         *(volatile unsigned long *)0x40013004              
#define SPI1_SR	           *(volatile unsigned long *)0x40013008              
#define SPI1_DR	           *(volatile unsigned long *)0x4001300C              
#define SPI1_CRCPR	       *(volatile unsigned long *)0x40013010              
#define SPI1_RXCRCR	       *(volatile unsigned long *)0x40013014                    
#define SPI1_TXCRCR	       *(volatile unsigned long *)0x40013018                    
	
/***************************************************************************	
 **	
 ** SPI2	
 **	
 ***************************************************************************/	
#define SPI2_CR1	         *(volatile unsigned long *)0x40003800              
#define SPI2_CR2	         *(volatile unsigned long *)0x40003804              
#define SPI2_SR	           *(volatile unsigned long *)0x40003808              
#define SPI2_DR	           *(volatile unsigned long *)0x4000380C              
#define SPI2_CRCPR	       *(volatile unsigned long *)0x40003810              
#define SPI2_RXCRCR	       *(volatile unsigned long *)0x40003814                    
#define SPI2_TXCRCR	       *(volatile unsigned long *)0x40003818                    
	
/***************************************************************************	
 **	
 ** USART1	
 **	
 ***************************************************************************/	
#define USART1_SR	          *(volatile unsigned long *)0x40013800              
#define USART1_DR	          *(volatile unsigned long *)0x40013804              
#define USART1_BRR	        *(volatile unsigned long *)0x40013808              
#define USART1_CR1	        *(volatile unsigned long *)0x4001380C              
#define USART1_CR2	        *(volatile unsigned long *)0x40013810              
#define USART1_CR3	        *(volatile unsigned long *)0x40013814              
#define USART1_GTPR	        *(volatile unsigned long *)0x40013818              
	
/***************************************************************************	
 **	
 ** USART2	
 **	
 ***************************************************************************/	
#define USART2_SR	          *(volatile unsigned long *)0x40004400              
#define USART2_DR	          *(volatile unsigned long *)0x40004404              
#define USART2_BRR	        *(volatile unsigned long *)0x40004408              
#define USART2_CR1	        *(volatile unsigned long *)0x4000440C              
#define USART2_CR2	        *(volatile unsigned long *)0x40004410              
#define USART2_CR3	        *(volatile unsigned long *)0x40004414              
#define USART2_GTPR	        *(volatile unsigned long *)0x40004418              
	
/***************************************************************************	
 **	
 ** USART3	
 **	
 ***************************************************************************/	
#define USART3_SR	          *(volatile unsigned long *)0x40004800              
#define USART3_DR	          *(volatile unsigned long *)0x40004804              
#define USART3_BRR	        *(volatile unsigned long *)0x40004808              
#define USART3_CR1	        *(volatile unsigned long *)0x4000480C              
#define USART3_CR2	        *(volatile unsigned long *)0x40004810              
#define USART3_CR3	        *(volatile unsigned long *)0x40004814              
#define USART3_GTPR	        *(volatile unsigned long *)0x40004818              
	
/***************************************************************************	
 **	
 ** USB	
 **	
 ***************************************************************************/	
#define USB_EP0R	          *(volatile unsigned long *)0x40005C00              
#define USB_EP1R	          *(volatile unsigned long *)0x40005C04              
#define USB_EP2R	          *(volatile unsigned long *)0x40005C08              
#define USB_EP3R	          *(volatile unsigned long *)0x40005C0C              
#define USB_EP4R	          *(volatile unsigned long *)0x40005C10              
#define USB_EP5R	          *(volatile unsigned long *)0x40005C14              
#define USB_EP6R	          *(volatile unsigned long *)0x40005C18              
#define USB_EP7R	          *(volatile unsigned long *)0x40005C1C              
#define USB_CR	            *(volatile unsigned long *)0x40005C40              
#define USB_ISR	            *(volatile unsigned long *)0x40005C44              
#define USB_FNR	            *(volatile unsigned long *)0x40005C48                    
#define USB_ADDR	          *(volatile unsigned long *)0x40005C4C              
#define USB_BTAR	          *(volatile unsigned long *)0x40005C50              
	
/***************************************************************************	
 **	
 ** ADC1	
 **	
 ***************************************************************************/	
#define ADC1_SR	            *(volatile unsigned long *)0x40012400              
#define ADC1_CR1	          *(volatile unsigned long *)0x40012404              
#define ADC1_CR2	          *(volatile unsigned long *)0x40012408              
#define ADC1_SMPR1	        *(volatile unsigned long *)0x4001240C              
#define ADC1_SMPR2	        *(volatile unsigned long *)0x40012410              
#define ADC1_JOFR1	        *(volatile unsigned long *)0x40012414              
#define ADC1_JOFR2	        *(volatile unsigned long *)0x40012418              
#define ADC1_JOFR3	        *(volatile unsigned long *)0x4001241C              
#define ADC1_JOFR4	        *(volatile unsigned long *)0x40012420              
#define ADC1_HTR	         *(volatile unsigned long *)0x40012424              
#define ADC1_LTR	         *(volatile unsigned long *)0x40012428              
#define ADC1_SQR1	         *(volatile unsigned long *)0x4001242C              
#define ADC1_SQR2	         *(volatile unsigned long *)0x40012430              
#define ADC1_SQR3	         *(volatile unsigned long *)0x40012434              
#define ADC1_JSQR	         *(volatile unsigned long *)0x40012438              
#define ADC1_JDR1	         *(volatile unsigned long *)0x4001243C                    
#define ADC1_JDR2	         *(volatile unsigned long *)0x40012440                    
#define ADC1_JDR3	         *(volatile unsigned long *)0x40012444                    
#define ADC1_JDR4	         *(volatile unsigned long *)0x40012448                    
#define ADC1_DR	           	 *(volatile unsigned long *)0x4001244C                    
	
/***************************************************************************	
 **	
 ** ADC2	
 **	
 ***************************************************************************/	
#define ADC2_SR	            *(volatile unsigned long *)0x40012800              
#define ADC2_CR1	          *(volatile unsigned long *)0x40012804              
#define ADC2_CR2	          *(volatile unsigned long *)0x40012808              
#define ADC2_SMPR1	        *(volatile unsigned long *)0x4001280C              
#define ADC2_SMPR2	        *(volatile unsigned long *)0x40012810              
#define ADC2_JOFR1	        *(volatile unsigned long *)0x40012814              
#define ADC2_JOFR2	        *(volatile unsigned long *)0x40012818              
#define ADC2_JOFR3	        *(volatile unsigned long *)0x4001281C              
#define ADC2_JOFR4	        *(volatile unsigned long *)0x40012820              
#define ADC2_HTR	         *(volatile unsigned long *)0x40012824              
#define ADC2_LTR	         *(volatile unsigned long *)0x40012828              
#define ADC2_SQR1	         *(volatile unsigned long *)0x4001282C              
#define ADC2_SQR2	         *(volatile unsigned long *)0x40012830              
#define ADC2_SQR3	         *(volatile unsigned long *)0x40012834              
#define ADC2_JSQR	         *(volatile unsigned long *)0x40012838              
#define ADC2_JDR1	         *(volatile unsigned long *)0x4001283C              
#define ADC2_JDR2	         *(volatile unsigned long *)0x40012840              
#define ADC2_JDR3	         *(volatile unsigned long *)0x40012844              
#define ADC2_JDR4	         *(volatile unsigned long *)0x40012848              
#define ADC2_DR	           *(volatile unsigned long *)0x4001284C              
	
/***************************************************************************	
 **	
 ** DBG	
 **	
 ***************************************************************************/	
#define DBGMCU_IDCODE	     *(volatile unsigned long *)0xE0042000                    
#define DBGMCU_CR	         *(volatile unsigned long *)0xE0042004              
	
/***************************************************************************	
 **	
 ** NVIC	
 **	
 ***************************************************************************/	
//#define NVIC	             *(volatile unsigned long *)0xE000E004                    
#define SYSTICKCSR	       *(volatile unsigned long *)0xE000E010              
#define SYSTICKRVR	       *(volatile unsigned long *)0xE000E014              
#define SYSTICKCVR	       *(volatile unsigned long *)0xE000E018              
#define SYSTICKCALVR	     *(volatile unsigned long *)0xE000E01C                    
#define SETENA0	           *(volatile unsigned long *)0xE000E100              
#define SETENA1	           *(volatile unsigned long *)0xE000E104              
#define CLRENA0	           *(volatile unsigned long *)0xE000E180              
#define CLRENA1	           *(volatile unsigned long *)0xE000E184              
#define SETPEND0	         *(volatile unsigned long *)0xE000E200              
#define SETPEND1	         *(volatile unsigned long *)0xE000E204              
#define CLRPEND0	         *(volatile unsigned long *)0xE000E280              
#define CLRPEND1	         *(volatile unsigned long *)0xE000E284              
#define ACTIVE0	           *(volatile unsigned long *)0xE000E300                    
#define ACTIVE1	           *(volatile unsigned long *)0xE000E304                    
// #define IP0	               *(volatile unsigned long *)0xE000E400              
// #define IP1	               *(volatile unsigned long *)0xE000E404              
// #define IP2	               *(volatile unsigned long *)0xE000E408              
// #define IP3	               *(volatile unsigned long *)0xE000E40C              
// #define IP4	               *(volatile unsigned long *)0xE000E410              
// #define IP5	               *(volatile unsigned long *)0xE000E414              
// #define IP6	               *(volatile unsigned long *)0xE000E418              
// #define IP7	               *(volatile unsigned long *)0xE000E41C              
// #define IP8	               *(volatile unsigned long *)0xE000E420              
// #define IP9	               *(volatile unsigned long *)0xE000E424              
// #define IP10	             *(volatile unsigned long *)0xE000E428              
// #define IP11	             *(volatile unsigned long *)0xE000E42C              
// #define IP12	             *(volatile unsigned long *)0xE000E430              
// #define IP13	             *(volatile unsigned long *)0xE000E434              
// #define IP14	             *(volatile unsigned long *)0xE000E438              
// #define IP15	             *(volatile unsigned long *)0xE000E43C              
// #define CPUIDBR	           	 *(volatile unsigned long *)0xE000ED00                    
// #define ICSR	             *(volatile unsigned long *)0xE000ED04              
// #define VTOR	             *(volatile unsigned long *)0xE000ED08              
// #define AITCR	             *(volatile unsigned long *)0xE000ED0C              
// #define SCR	               	 *(volatile unsigned long *)0xE000ED10              
// #define CCR	               	 *(volatile unsigned long *)0xE000ED14              
// #define SHPR0	             *(volatile unsigned long *)0xE000ED18              
// #define SHPR1	             *(volatile unsigned long *)0xE000ED1C              
// #define SHPR2	             *(volatile unsigned long *)0xE000ED20              
// #define SHCSR	             *(volatile unsigned long *)0xE000ED24              
// #define CFSR	             *(volatile unsigned long *)0xE000ED28              
// #define HFSR	             *(volatile unsigned long *)0xE000ED2C              
// #define DFSR	             *(volatile unsigned long *)0xE000ED30              
// #define MMFAR	             *(volatile unsigned long *)0xE000ED34
// #define BFAR	             *(volatile unsigned long *)0xE000ED38
// #define STIR	             *(volatile unsigned long *)0xE000EF00                   
	
/***************************************************************************	
 **	
 ** Flash	
 **	
 ***************************************************************************/	
#define FLASH_ACR	        *(volatile unsigned long *)0x40022000              
#define FLASH_KEYR	      	*(volatile unsigned long *)0x40022004                  
#define FLASH_OPTKEYR	    *(volatile unsigned long *)0x40022008                  
#define FLASH_SR	        *(volatile unsigned long *)0x4002200C              
#define FLASH_CR	        *(volatile unsigned long *)0x40022010              
#define FLASH_AR	        *(volatile unsigned long *)0x40022014                   
#define FLASH_OBR	        *(volatile unsigned long *)0x4002201C                    
#define FLASH_WRPR	     	*(volatile unsigned long *)0x40022020  
   

#endif    /* __IOSTM32F10xxB_H */
              
