#include "stm32_cpu.h"

#include "adc.h"
#include "define.h"
#include "key.h"

extern u8 enterkeyvalue;
extern u8 gift_pulse_flag;

// #include "stm32f10x_map_lin.h"
void Platform_Init(void) {
  RCC_Configuration();
  // WDG_Configuration();
  GPIO_Configuration();
  USART1_Configuration();
  USART2_Configuration();
  USART3_Configuration();
  Adc_Init();
  TIME1_Configuration(); 
  TIM2_Configuration();
  NVIC_Configuration();
  Tim3_Init(500 - 1, 7200 - 1);
}
/*initialize the system clock*/
void GPIO_Configuration(void) {
  // 模拟输入0;浮空输入4; 弱拉输入8;推挽输出2;复用推挽输出B;集开输出6;
  GPIO_InitTypeDef GPIO_InitStructure;  // 定义GPIO初始化结构体
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_AFIO | RCC_APB2Periph_GPIOB | RCC_APB2Periph_GPIOC | RCC_APB2Periph_GPIOD | RCC_APB2Periph_GPIOE, ENABLE);

#if defined(HARDWARE_V0) || defined(HARDWARE_V1)
  GPIO_SetBits(GPIOD, GPIO_Pin_11);
  GPIO_SetBits(GPIOD, GPIO_Pin_12);
  GPIO_SetBits(GPIOD, GPIO_Pin_13);
  GPIO_SetBits(GPIOD, GPIO_Pin_14);
  GPIO_SetBits(GPIOD, GPIO_Pin_15);
  GPIO_SetBits(GPIOC, GPIO_Pin_6);

  GPIO_SetBits(GPIOE, GPIO_Pin_2);  // 设置
  GPIO_ResetBits(GPIOA, GPIO_Pin_8);

  GPIO_SetBits(GPIOC, GPIO_Pin_4);
  GPIO_SetBits(GPIOC, GPIO_Pin_5);
  GPIO_SetBits(GPIOB, GPIO_Pin_5);

  GPIO_SetBits(GPIOC, GPIO_Pin_7);
  GPIO_ResetBits(GPIOC, GPIO_Pin_9);  // 投币码表

  GPIO_ResetBits(GPIOC, GPIO_Pin_8);  // 出礼品码表

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;  // 上拉输入
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_8 | GPIO_Pin_11 | GPIO_Pin_12 | GPIO_Pin_15;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;  // 上拉输入
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;  // 上拉输入
  GPIO_Init(GPIOB, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_3 | GPIO_Pin_4;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;  // 上拉输入
  GPIO_Init(GPIOD, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_3 | GPIO_Pin_8 | GPIO_Pin_9 | GPIO_Pin_10 | GPIO_Pin_11 | GPIO_Pin_12;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;  // 上拉输入
  GPIO_Init(GPIOE, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_7 | GPIO_Pin_14 | GPIO_Pin_12 | GPIO_Pin_13 | GPIO_Pin_11 | GPIO_Pin_15 | GPIO_Pin_10;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(GPIOD, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_3 | GPIO_Pin_4 | GPIO_Pin_6 | GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(GPIOB, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_4 | GPIO_Pin_6 | GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_11 | GPIO_Pin_10;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(GPIOB, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6 | GPIO_Pin_7 | GPIO_Pin_4 | GPIO_Pin_5 | GPIO_Pin_8 | GPIO_Pin_9;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(GPIOC, &GPIO_InitStructure);

  GPIO_PinRemapConfig(GPIO_Remap_SWJ_Disable, ENABLE);
#endif
#ifdef HARDWARE_V2

  GPIO_SetBits(GPIOB, GPIO_Pin_6);
  GPIO_SetBits(GPIOB, GPIO_Pin_7);
  GPIO_SetBits(GPIOB, GPIO_Pin_14);
  GPIO_SetBits(GPIOB, GPIO_Pin_15);

  GPIO_SetBits(GPIOC, GPIO_Pin_4);
  GPIO_SetBits(GPIOC, GPIO_Pin_5);
  GPIO_SetBits(GPIOC, GPIO_Pin_6);
  GPIO_ResetBits(GPIOC, GPIO_Pin_7);
  GPIO_ResetBits(GPIOC, GPIO_Pin_8);
  GPIO_ResetBits(GPIOC, GPIO_Pin_9);

  GPIO_ResetBits(GPIOD, GPIO_Pin_8);
  GPIO_SetBits(GPIOD, GPIO_Pin_9);
  GPIO_SetBits(GPIOD, GPIO_Pin_10);
  GPIO_ResetBits(GPIOD, GPIO_Pin_11);
  GPIO_SetBits(GPIOD, GPIO_Pin_12);
  GPIO_SetBits(GPIOD, GPIO_Pin_13);
  GPIO_ResetBits(GPIOD, GPIO_Pin_14);
  GPIO_SetBits(GPIOD, GPIO_Pin_15);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6 | GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_8 | GPIO_Pin_11 | GPIO_Pin_12 | GPIO_Pin_15;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;  // 上拉输入
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0 | GPIO_Pin_5;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;  // 上拉输入
  GPIO_Init(GPIOB, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_3 | GPIO_Pin_4 | GPIO_Pin_6 | GPIO_Pin_7 | GPIO_Pin_10 | GPIO_Pin_11 | GPIO_Pin_14 | GPIO_Pin_15;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(GPIOB, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4 | GPIO_Pin_5 | GPIO_Pin_6 | GPIO_Pin_7 | GPIO_Pin_8 | GPIO_Pin_9 | GPIO_Pin_12;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(GPIOC, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_3 | GPIO_Pin_4 | GPIO_Pin_5;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;  // 上拉输入
  GPIO_Init(GPIOD, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6 | GPIO_Pin_7 | GPIO_Pin_8 | GPIO_Pin_9 | GPIO_Pin_10 | GPIO_Pin_11 | GPIO_Pin_12 | GPIO_Pin_13 | GPIO_Pin_14 | GPIO_Pin_15;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(GPIOD, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4 | GPIO_Pin_8 | GPIO_Pin_9 | GPIO_Pin_10 | GPIO_Pin_11 | GPIO_Pin_12;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;  // 上拉输入
  GPIO_Init(GPIOE, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_5;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(GPIOE, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_11 | GPIO_Pin_10;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_Init(GPIOB, &GPIO_InitStructure);

  GPIO_PinRemapConfig(GPIO_Remap_SWJ_Disable, ENABLE);
#endif
}
/*************************************************
函数: void WDG_Configuration()
功能: 独立看门狗初始化
参数: 无
返回: 无
**************************************************/
void WDG_Configuration(void) {
  IWDG_KR = 0x5555;  // 启动寄存器读写
  IWDG_PR = 0x06;    // 40K时钟4分频
  IWDG_RLR = 0xFF;   // 计数器数值 40MS
  IWDG_KR = 0xcccc;  // 启动看门狗
  while ((IWDG_SR) & 0x03);
  IWDG_KR = 0xaaaa;  // 重启计数器
}

void RCC_Configuration(void) {
  ErrorStatus HSEStartUpStatus;
  RCC_DeInit();  // 复位RCC外部寄存器到默认值

  RCC_HSEConfig(RCC_HSE_ON);  // 打开外部高速晶振

  HSEStartUpStatus = RCC_WaitForHSEStartUp();  // 等待外部高速时钟准备好

  if (HSEStartUpStatus == SUCCESS)  // 外部高速时钟已经准备好
  {
    /*设置AHB时钟（HCLK）*/
    FLASH_PrefetchBufferCmd(FLASH_PrefetchBuffer_Enable);  // 开启FLASH预读缓冲功能，加速FLASH的读取。所有程序中必须的用法，位置：RCC初始化子函数里面，时钟起振之后

    FLASH_SetLatency(
        FLASH_Latency_2);  // FLASH时序延迟几个周期，等待总线同步操作。推荐按照单片机系统运行频率，0—24MHz时，取Latency=0；24—48MHz时，取Latency=1；48~72MHz时，取Latency=2。

    RCC_HCLKConfig(RCC_SYSCLK_Div1);  // 配置AHB(HCLK)==系统时钟/1  //RCC_SYSCLK_Div1——AHB时钟= 系统时钟72M

    RCC_PCLK2Config(RCC_HCLK_Div1);  // 配置APB2(高速)(PCLK2)==系统时钟/1 //RCC_HCLK_Div1——APB2时钟= HCLK

    RCC_PCLK1Config(RCC_HCLK_Div2);  // 配置APB1(低速)(PCLK1)==系统时钟/2 RCC_HCLK_Div2——APB1时钟= HCLK / 2

    // 注：AHB主要负责外部存储器时钟。APB2负责AD，I/O，高级TIM，串口1。APB1负责DA，USB，SPI，I2C，CAN，串口2345，普通TIM。

    /*设置PLL时钟源及倍频系数*/
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_6);  // 配置PLL时钟==(外部高速晶体时钟/1）12* 6 ==72MHz  外部时钟

    RCC_PLLCmd(ENABLE);  // 使能PLL时钟

    while (RCC_GetFlagStatus(RCC_FLAG_PLLRDY) == RESET);  // 等待PLL时钟就绪

    RCC_SYSCLKConfig(RCC_SYSCLKSource_PLLCLK);  // 配置系统时钟==PLL时钟

    while (RCC_GetSYSCLKSource() != 0x08);  // 等待系统时钟源的启动
  }

  //==============以下为开启外设时钟的操作============================//
  // RCC_AHBPeriphClockCmd (ABP2设备1 | ABP2设备2 , ENABLE); //启动AHB设备
  // RCC_APB2PeriphClockCmd(ABP2设备1 | ABP2设备2 , ENABLE); //启动ABP2设备
  // RCC_APB1PeriphClockCmd(ABP2设备1 | ABP2设备2 , ENABLE); //启动ABP1设备

  // RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_AFIO | RCC_APB2Periph_USART1 , ENABLE); //打开APB2外设
  /* Enable GPIOx clock */
  RCC_APB2PeriphClockCmd(
      RCC_APB2Periph_GPIOA | RCC_APB2Periph_AFIO | RCC_APB2Periph_GPIOB | RCC_APB2Periph_GPIOC | RCC_APB2Periph_GPIOD | RCC_APB2Periph_USART1 | RCC_APB2Periph_TIM1, ENABLE);

  //   RCC_APB2PeriphClockCmd( RCC_APB2Periph_GPIOA | RCC_APB2Periph_AFIO | RCC_APB2Periph_GPIOB| RCC_APB2Periph_TIM1 | RCC_APB2Periph_USART1
  //   |RCC_APB2Periph_GPIOC | RCC_APB2Periph_GPIOD|RCC_APB2Periph_GPIOE, ENABLE);
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART3 | RCC_APB1Periph_USART2 | RCC_APB1Periph_TIM2, ENABLE);  // 启动串口3 控制打印机，普通定时器2，时钟启动
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_AFIO, ENABLE);

  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART2, ENABLE);
  // GPIO_PinRemapConfig(GPIO_Remap_USART2, ENABLE);
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOD, ENABLE);
}
/*initialize the priority of interruptions used*/
void NVIC_Configuration(void) {
  NVIC_InitTypeDef NVIC_InitStructure;  // 定义一个中断结构体

  // NVIC_SetVectorTable(NVIC_VectTab_FLASH, 0x0); //设置中断向量表的起始地址为0x08000000
  NVIC_PriorityGroupConfig(NVIC_PriorityGroup_1);  // 设置NVIC优先级分组，方式。
  // 注：一共16个优先级，分为抢占式和响应式。两种优先级所占的数量由此代码确定，NVIC_PriorityGroup_x可以是0、1、2、3、4，
  // 分别代表抢占优先级有1、2、4、8、16个和响应优先级有16、8、4、2、1个。规定两种优先级的数量后，所有的中断级别必须在其中选择，
  // 抢占级别高的会打断其他中断优先执行，而响应级别高的会在其他中断执行完优先执行。

  // NVIC_Init(&NVIC_InitStructure); //初始化
  //?êDíTIM1?D??
  // NVIC_InitStructure.NVIC_IRQChannel = TIM1_UP_IRQChannel;  	// ?êDíTIM1?üD??D??
  NVIC_InitStructure.NVIC_IRQChannel = TIM1_CC_IRQn;         // ?êDíTIM12?×?/±è???￥???D??
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;  // ?à??ó??è???a0
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;         // ′?òaó??è???a2
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /*TIM2*/
  NVIC_InitStructure.NVIC_IRQChannel = TIM2_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 2;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  //	NVIC_InitStructure.NVIC_IRQChannel = EXTI0_IRQn;			//使能出币所在的外部中断通道
  //	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;	//抢占优先级0，
  //	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;					//子优先级5
  //	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;								//使能外部中断通道
  //	NVIC_Init(&NVIC_InitStructure);

  //	NVIC_InitStructure.NVIC_IRQChannel = EXTI9_5_IRQn;			//使能出币所在的外部中断通道
  //  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;	//抢占优先级0，
  //  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 3;					//子优先级5
  //  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;								//使能外部中断通道
  //	NVIC_Init(&NVIC_InitStructure);

  //	/*UART1*/
  NVIC_InitStructure.NVIC_IRQChannel = USART1_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);

  //	/*UART2*/
  	NVIC_InitStructure.NVIC_IRQChannel = USART2_IRQn;
  	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 2;
  	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  	NVIC_Init(&NVIC_InitStructure);
  //
  NVIC_InitStructure.NVIC_IRQChannel = USART3_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 1;  // 抢占优先级1
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 2;         // 中断响应优先级1
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}
void IWDG_Configuration(u16 time) {
  /* 写入0x5555,用于允许狗狗寄存器写入功能 */
  IWDG_WriteAccessCmd(IWDG_WriteAccess_Enable);
  /* 狗狗时钟分频,40K/256=156HZ(6.4ms)*/
  IWDG_SetPrescaler(IWDG_Prescaler_256);
  /* 喂狗时间 5s/6.4MS=781 .注意不能大于0xfff*/
  IWDG_SetReload(time);
  /* 喂狗*/
  IWDG_ReloadCounter();
  /* 使能狗狗*/
  IWDG_Enable();
}

void USART1_Configuration(void) {
  USART_InitTypeDef USART_InitStructure;
  GPIO_InitTypeDef GPIO_InitStructure;
  //	USART_ClockInitTypeDef  USART_ClockInitStructure;

  USART_DeInit(USART1);

  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_USART1, ENABLE);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;  // Pushpull out-TX			 A9 USART1_Tx
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_10;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;  // In floating in-RX         A10 USART1_Rx
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  USART_InitStructure.USART_BaudRate = 115200;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;  // stm32 奇偶校验时必须要9位USART_WordLength_9b; //数据位9
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No;  // USART_Parity_Odd ;//奇校验  ///SART_Parity_Even;//偶校验 //USART_Parity_No无校验位
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
  USART_Init(USART1, &USART_InitStructure);
  USART_ITConfig(USART1, USART_IT_RXNE, ENABLE);  // usart1 interrupt enable
  USART_Cmd(USART1, ENABLE);
  USART_ClearFlag(USART1, USART_FLAG_TC);  //////清标志,解决第1个字节无法正确发送出去的问题
}

void USART2_Configuration(void) {
  USART_InitTypeDef USART_InitStructure;
  GPIO_InitTypeDef GPIO_InitStructure;
  // USART_ClockInitTypeDef  USART_ClockInitStructure;

  USART_DeInit(USART2);

  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA, ENABLE);
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART2, ENABLE);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_2;  // A2 --T2X
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_3;  // A3 --R2X
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  USART_InitStructure.USART_BaudRate = 115200;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;  // stm32 奇偶校验时必须要9位USART_WordLength_9b; //数据位9
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No;

  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
  USART_Init(USART2, &USART_InitStructure);

  /* USART_ClockInitStructure.USART_Clock = USART_Clock_Disable;
          USART_ClockInitStructure.USART_CPOL = USART_CPOL_Low;
          USART_ClockInitStructure.USART_CPHA = USART_CPHA_2Edge;
          USART_ClockInitStructure.USART_LastBit = USART_LastBit_Disable;

          USART_ClockInit(USART2, &USART_ClockInitStructure);	 */

  USART_ITConfig(USART2, USART_IT_RXNE, ENABLE);
  // USART_ITConfig(USART2,USART_IT_TXE,ENABLE);
  // USART_ITConfig(USART2,USART_IT_TC,ENABLE);

  USART_Cmd(USART2, ENABLE);
  USART_ClearFlag(USART2, USART_FLAG_TC);  //////清标志,解决第1个字节无法正确发送出去的问题
}

#if defined(HARDWARE_V0) || defined(HARDWARE_V1)
void USART3_Configuration(void) {
  USART_InitTypeDef USART_InitStructure;
  // USART_ClockInitTypeDef  USART_ClockInitStructure;
  GPIO_InitTypeDef GPIO_InitStructure;

  USART_DeInit(USART3);

  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOC, ENABLE);
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART3, ENABLE);
  // GPIO_PinRemapConfig(GPIO_FullRemap_USART3, ENABLE);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_10;  // B10 --T3X
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_Init(GPIOC, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_11;  // B11 --R3X
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_Init(GPIOC, &GPIO_InitStructure);

  USART_InitStructure.USART_BaudRate = 115200;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;  // stm32 奇偶校验时必须要9位USART_WordLength_9b; //数据位9
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No;                              // USART_Parity_Odd ;//奇校验  ///SART_Parity_Even;//偶校验 //USART_Parity_No无校验位
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;  //  USART_HardwareFlowControl_RTS//	 USART_HardwareFlowControl_RTS_CTS;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;

  /* USART_ClockInitStructure.USART_Clock = USART_Clock_Disable;
          USART_ClockInitStructure.USART_CPOL = USART_CPOL_Low;
          USART_ClockInitStructure.USART_CPHA = USART_CPHA_2Edge;
          USART_ClockInitStructure.USART_LastBit = USART_LastBit_Disable;

          USART_ClockInit(USART3, &USART_ClockInitStructure);*/
  USART_Init(USART3, &USART_InitStructure);

  USART_ITConfig(USART3, USART_IT_RXNE, ENABLE);
  // USART_ITConfig(USART3,USART_IT_TXE,ENABLE);
  // USART_ITConfig(USART3,USART_IT_TC,ENABLE);

  USART_Cmd(USART3, ENABLE);
  USART_ClearFlag(USART3, USART_FLAG_TC);  //////清标志,解决第1个字节无法正确发送出去的问题
}
#endif

#ifdef HARDWARE_V2
void USART3_Configuration(void) {
  USART_InitTypeDef USART_InitStructure;
  // USART_ClockInitTypeDef  USART_ClockInitStructure;
  GPIO_InitTypeDef GPIO_InitStructure;

  USART_DeInit(USART3);

  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOC, ENABLE);
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART3, ENABLE);
  // GPIO_PinRemapConfig(GPIO_FullRemap_USART3, ENABLE);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_10;  // B10 --T3X
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_Init(GPIOC, &GPIO_InitStructure);

  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_11;  // B11 --R3X
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_Init(GPIOC, &GPIO_InitStructure);

  USART_InitStructure.USART_BaudRate = 9600;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;  // stm32 奇偶校验时必须要9位USART_WordLength_9b; //数据位9
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No;                              // USART_Parity_Odd ;//奇校验  ///SART_Parity_Even;//偶校验 //USART_Parity_No无校验位
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;  //  USART_HardwareFlowControl_RTS//	 USART_HardwareFlowControl_RTS_CTS;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;

  /* USART_ClockInitStructure.USART_Clock = USART_Clock_Disable;
          USART_ClockInitStructure.USART_CPOL = USART_CPOL_Low;
          USART_ClockInitStructure.USART_CPHA = USART_CPHA_2Edge;
          USART_ClockInitStructure.USART_LastBit = USART_LastBit_Disable;

          USART_ClockInit(USART3, &USART_ClockInitStructure);*/
  USART_Init(USART3, &USART_InitStructure);

  USART_ITConfig(USART3, USART_IT_RXNE, ENABLE);
  // USART_ITConfig(USART3,USART_IT_TXE,ENABLE);
  // USART_ITConfig(USART3,USART_IT_TC,ENABLE);

  USART_Cmd(USART3, ENABLE);
  USART_ClearFlag(USART3, USART_FLAG_TC);  //////清标志,解决第1个字节无法正确发送出去的问题
}
#endif

void TIME1_Configuration(void) {
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  TIM_OCInitTypeDef TIM_OCInitStructure;

  TIM_TimeBaseStructInit(&TIM_TimeBaseStructure);  // °?TIM_TimeBaseStructure?Dμ???ò???2?êy°′è±ê??μì?è?

  // 3?ê??ˉTIME1μ?ê±???ùêyμ￥??
  // 72x10^6 / TIM_Prescaler/ TIM_Period = 1us
  TIM_TimeBaseStructure.TIM_Period = 100 - 1;                  // 1us  *100=100us
  TIM_TimeBaseStructure.TIM_Prescaler = 71;                    // 定时器时钟为= 72MHz/72 = 1MHz  =1us  one
  TIM_TimeBaseStructure.TIM_ClockDivision = 0x0;               // ê±?ó·????μ
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;  // ?òé???êy?￡ê?
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;             // ??′??òé?ò?3???2úéú?üD?ê??t
  TIM_TimeBaseInit(TIM1, &TIM_TimeBaseStructure);

  TIM_OCStructInit(&TIM_OCInitStructure);  // °?TIM_OCInitStructure?Dμ???ò???2?êy°′è±ê??μì?è?

  // ê?3?±è??′￥·￠?￡ê?????￡oí¨μà1
  TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_Toggle;            // 1ü??ê?3??￡ê?￡o·-×a
  TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;  // ê1?üTIM1_CH1í¨μà
  TIM_OCInitStructure.TIM_Pulse = 9999;                          // ′y×°è?2?×?±è????′??÷μ???3??μ￡??′·-×a?ü?ú￡¨′?′|éè???a1ms￡?
  TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_Low;       // TIMê?3?±è???￡ê???μ?ê?3???D??aμí￡¨ê?3??a?o???-￡?
  TIM_OC1Init(TIM1, &TIM_OCInitStructure);                       // íê3é????

  TIM_ClearFlag(TIM1, TIM_FLAG_CC1);       // ???D??±ê??￡?ò??aò???ó??D??oóá￠?′2úéú?D??
  TIM_ITConfig(TIM1, TIM_IT_CC1, ENABLE);  // TIM1?D???′éè??￡??a??í¨μà1μ?2?×?±è???D??
  TIM_Cmd(TIM1, ENABLE);
}

void TIM2_Configuration(void) {
  // TIM_TimeBaseInitTypeDef  TIM_TimeBaseStructure;//定时器初始化结构
  // RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2, ENABLE);

  // TIM_ICInitTypeDef TIM_ICInitStructure;         //通道输入初始化结构
  // TIM_OCInitTypeDef  TIM_OCInitStructure;
  //(1+TIM_Prescaler )/72M)*(1+TIM_Period )=时间  例如：((（1+7200-1）/72000000)*(1+10-1) )*1000=1ms  /////系统时钟

  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  // RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2, ENABLE);

  TIM_TimeBaseStructure.TIM_Period = 1000 - 1;                                 /*计数值 1mS*/
  TIM_TimeBaseStructure.TIM_Prescaler = 72 - 1; /*预分频,此值+1为分频的除数*/  // 1us
  TIM_TimeBaseStructure.TIM_ClockDivision = 0x0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM2, &TIM_TimeBaseStructure);

  /*preload enable*/
  TIM_ARRPreloadConfig(TIM2, ENABLE);

  /*clear the pending bit*/
  TIM_ClearITPendingBit(TIM2, TIM_IT_Update);

  /*4 channels in the interruption mode*/
  TIM_ITConfig(TIM2, TIM_IT_Update, ENABLE);
  TIM_Cmd(TIM2, ENABLE);
}

void Tim3_Init(u16 arr, u16 psc) {
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  NVIC_InitTypeDef NVIC_InitStructure;

  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM3, ENABLE);  // 时钟使能

  // 定时器TIM3初始化
  TIM_TimeBaseStructure.TIM_Period = arr;     // 设置在下一个更新事件装入活动的自动重装载寄存器周期的值
  TIM_TimeBaseStructure.TIM_Prescaler = psc;  // 设置用来作为TIMx时钟频率除数的预分频值
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;  // TIM向上计数模式
  TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);              // 根据指定的参数初始化TIMx的时间基数单位

  TIM_ARRPreloadConfig(TIM3, ENABLE);  // 使能TIM重载寄存器ARR

  TIM_ClearFlag(TIM3, TIM_FLAG_Update);  // 清除计数器中断标志位

  TIM_ITConfig(TIM3, TIM_IT_Update, ENABLE);  // 使能指定的TIM3中断,允许更新中断

  // 中断优先级NVIC设置
  NVIC_InitStructure.NVIC_IRQChannel = TIM3_IRQn;            // TIM3中断
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;  // 先占优先级0级
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;         // 从优先级3级
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;            // IRQ通道被使能
  NVIC_Init(&NVIC_InitStructure);                            // 初始化NVIC寄存器

  TIM_Cmd(TIM3, DISABLE);  // 失能TIMx
}

// 定时器3中断服务程序
void TIM3_IRQHandler(void)  // TIM3中断
{
  if (TIM_GetITStatus(TIM3, TIM_IT_Update) != RESET)  // 检查TIM3更新中断发生与否
  {
    TIM_ClearITPendingBit(TIM3, TIM_IT_Update);  // 清除TIMx更新中断标志
    gift_pulse_flag = 0;
    toycointoff();
    TIM_SetCounter(TIM3, 0);  // 清零定时器
    TIM_Cmd(TIM3, DISABLE);
    //		if(GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_15))
    //		{
    //			enterkeyvalue = 1;
    //			TIM_SetCounter(TIM3, 0); //清零定时器
    //			TIM_Cmd(TIM3, DISABLE);  //失能定时器
    //		}
  }
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
