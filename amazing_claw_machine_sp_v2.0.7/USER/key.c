#include "key.h"

//按键初始化函数
void Key_Init(void) //IO初始化
{ 
 	GPIO_InitTypeDef GPIO_InitStructure;
	EXTI_InitTypeDef EXTI_InitStructure;//中断配置结构体
 	NVIC_InitTypeDef NVIC_InitStructure;//中断管理器配置结构体
	
 	RCC_APB2PeriphClockCmd(RCC_APB2Periph_AFIO,  ENABLE);//需要使能AFIO端口复用时
 	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);//使能PORTC时钟
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOE, ENABLE);
	
	
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU ; 
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
	GPIO_InitStructure.GPIO_Pin =  GPIO_Pin_15;
	GPIO_Init(GPIOA, &GPIO_InitStructure);

	GPIO_EXTILineConfig(GPIO_PortSourceGPIOA, GPIO_PinSource15);//端口中断线映射
			
	EXTI_InitStructure.EXTI_Line = EXTI_Line15;
  	EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;	//中断模式
  	EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Falling;//下降沿触发
  	EXTI_InitStructure.EXTI_LineCmd = ENABLE;
  	EXTI_Init(&EXTI_InitStructure);
  	
  	NVIC_InitStructure.NVIC_IRQChannel = EXTI15_10_IRQn;//使能对应外部中断通道
  	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0x01;//抢占优先级2 
  	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0x01;//子优先级1
  	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;			
  	NVIC_Init(&NVIC_InitStructure);
	
	NVIC_InitStructure.NVIC_IRQChannel = EXTI1_IRQn;//使能对应外部中断通道
	NVIC_Init(&NVIC_InitStructure);
	
	NVIC_InitStructure.NVIC_IRQChannel = EXTI2_IRQn;//使能对应外部中断通道
	NVIC_Init(&NVIC_InitStructure);
	
	NVIC_InitStructure.NVIC_IRQChannel = EXTI3_IRQn;//使能对应外部中断通道
	NVIC_Init(&NVIC_InitStructure);
	
	GPIO_SetBits(GPIOA, GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_4);
}

//中断线0-4分别对应一个中断函数，所以退出中断函数只需要清楚标志位

void EXTI15_10_IRQHandler(void)
{
	//用户代码
	if(EXTI_GetITStatus(EXTI_Line15) == SET)
	{		
		TIM_Cmd(TIM3, ENABLE);
		EXTI_ClearITPendingBit(EXTI_Line15);  //清除LINE1中断标志位
	}
}
