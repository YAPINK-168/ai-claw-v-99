#include <string.h>

#include "basic.h"

#define disp_scan 1     // 扫描中
#define disp_payed 3    // 支付完成
#define disp_coinin 4   // 投币
#define disp_carderr 5  // 卡错误
#define disp_count 6    // 余额
#define disp_QRonly 7
#define disp_QRCH 8
#define disp_QCHUSR 9

#if defined(HARDWARE_V0) || defined(HARDWARE_V1)

#define M_LED1_ON()
#define M_LED1_OFF()

#define M_LED2_ON()
#define M_LED2_OFF()

// LED 端口  低电平亮
#define LEDON1() GPIO_ResetBits(GPIOB, GPIO_Pin_6)
#define LEDOFF1() GPIO_SetBits(GPIOB, GPIO_Pin_6)
#define LEDON2() GPIO_ResetBits(GPIOB, GPIO_Pin_7)
#define LEDOFF2() GPIO_SetBits(GPIOB, GPIO_Pin_7)

// 按键灯高电平亮
#define KEYLEDOFF() GPIO_ResetBits(GPIOB, GPIO_Pin_5)
#define KEYLEDON() GPIO_SetBits(GPIOB, GPIO_Pin_5)

// 爪子控制
#define CLAWOFF() GPIO_SetBits(GPIOC, GPIO_Pin_7)
#define CLAWON() GPIO_ResetBits(GPIOC, GPIO_Pin_7)

#define LED4ON() GPIO_SetBits(GPIOA, GPIO_Pin_4)
#define LED4OFF() GPIO_ResetBits(GPIOA, GPIO_Pin_4)

// 电机控制

#define UPSTOP() GPIO_SetBits(GPIOD, GPIO_Pin_11)
#define UPRUN() GPIO_ResetBits(GPIOD, GPIO_Pin_11)
#define DOWNSTOP() GPIO_SetBits(GPIOD, GPIO_Pin_12)
#define DOWNRUN() GPIO_ResetBits(GPIOD, GPIO_Pin_12)
#define LEFTSTOP() GPIO_SetBits(GPIOD, GPIO_Pin_14)
#define LEFTRUN() GPIO_ResetBits(GPIOD, GPIO_Pin_14)
#define RIGHTSTOP() GPIO_SetBits(GPIOD, GPIO_Pin_13)
#define RIGHTRUN() GPIO_ResetBits(GPIOD, GPIO_Pin_13)
#define FRONTSTOP() GPIO_SetBits(GPIOC, GPIO_Pin_6)
#define FRONTRUN() GPIO_ResetBits(GPIOC, GPIO_Pin_6)  // pd15
#define BACKSTOP() GPIO_SetBits(GPIOD, GPIO_Pin_15)   // pc6
#define BACKRUN() GPIO_ResetBits(GPIOD, GPIO_Pin_15)

#define coincounton() GPIO_SetBits(GPIOC, GPIO_Pin_9)
#define coincountoff() GPIO_ResetBits(GPIOC, GPIO_Pin_9)

#define toycounton() GPIO_SetBits(GPIOC, GPIO_Pin_8)
#define toycointoff() GPIO_ResetBits(GPIOC, GPIO_Pin_8)

#define coinpoweron() GPIO_SetBits(GPIOD, GPIO_Pin_10)
#define coinpoweroff() GPIO_ResetBits(GPIOD, GPIO_Pin_10)

// 摇杆  按键 INNC 未接，礼品口光眼
#define FRONTKEY() GPIO_ReadInputDataBit(GPIOD, GPIO_Pin_3)  // front pd4
#define BACKKEY() GPIO_ReadInputDataBit(GPIOD, GPIO_Pin_4)   // back  pd3
#define LEFTKEY() GPIO_ReadInputDataBit(GPIOD, GPIO_Pin_1)
#define RIGHTKEY() GPIO_ReadInputDataBit(GPIOD, GPIO_Pin_0)
#define ENTERKEY() GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_15)
// #define SETKEY()  	  GPIO_ReadInputDataBit(GPIOB,GPIO_Pin_0)//PB0 刘总
#define SETKEY() GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_2)   // PE2本来的
#define SETKEY2() GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_3)  // PE2本来的
#define OUTSENTOR() GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_11)

// 天车微动
#define COININ() GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_8)
#define GROUNDSW() GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_0)  // pb0本来的
// #define GROUNDSW()  	GPIO_ReadInputDataBit(GPIOE,GPIO_Pin_10)//pe10刘总
#define DOWNSW() GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_8)
#define LEFTSW() GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_9)
#define FRONTSW() GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_11)
#define BACKSW() GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_12)
// #define SWNC()      	GPIO_ReadInputDataBit(GPIOE,GPIO_Pin_10)//本来的
#define SWNC() GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_5)  // pa5空脚刘总

#define WIFIEN() GPIO_SetBits(GPIOA, GPIO_Pin_7);
#define WIFIDISEN() GPIO_ResetBits(GPIOA, GPIO_Pin_7);
#define WIFIRSTOFF() GPIO_ResetBits(GPIOA, GPIO_Pin_6);
#define WIFIRSTON() GPIO_SetBits(GPIOA, GPIO_Pin_6);

#define MUSICBUSY() GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_1)

#endif

#ifdef HARDWARE_V2

// LED 端口  低电平亮
#define LEDON1() GPIO_ResetBits(GPIOB, GPIO_Pin_6)
#define LEDOFF1() GPIO_SetBits(GPIOB, GPIO_Pin_6)
#define LEDON2() GPIO_ResetBits(GPIOB, GPIO_Pin_7)
#define LEDOFF2() GPIO_SetBits(GPIOB, GPIO_Pin_7)

// 按键灯高电平亮
#define KEYLEDOFF() GPIO_ResetBits(GPIOC, GPIO_Pin_7)
#define KEYLEDON() GPIO_SetBits(GPIOC, GPIO_Pin_7)

#define M_LED1_ON() GPIO_ResetBits(GPIOC, GPIO_Pin_5)
#define M_LED1_OFF() GPIO_SetBits(GPIOC, GPIO_Pin_5)

#define M_LED2_ON() GPIO_ResetBits(GPIOC, GPIO_Pin_4)
#define M_LED2_OFF() GPIO_SetBits(GPIOC, GPIO_Pin_4)

// 爪子控制
#define CLAWOFF()                   \
  GPIO_SetBits(GPIOD, GPIO_Pin_15); \
  GPIO_SetBits(GPIOC, GPIO_Pin_6)
#define CLAWON()                      \
  GPIO_ResetBits(GPIOD, GPIO_Pin_15); \
  GPIO_ResetBits(GPIOC, GPIO_Pin_6)

#define LED4ON() GPIO_SetBits(GPIOE, GPIO_Pin_5)
#define LED4OFF() GPIO_ResetBits(GPIOE, GPIO_Pin_5)

#define DOWNSTOP()                  \
  GPIO_SetBits(GPIOB, GPIO_Pin_14); \
  GPIO_ResetBits(GPIOB, GPIO_Pin_15);
#define DOWNRUN()                     \
  GPIO_ResetBits(GPIOB, GPIO_Pin_14); \
  GPIO_SetBits(GPIOB, GPIO_Pin_15);

#define UPSTOP()                     \
  GPIO_ResetBits(GPIOD, GPIO_Pin_8); \
  GPIO_SetBits(GPIOB, GPIO_Pin_15);
#define UPRUN()                    \
  GPIO_SetBits(GPIOD, GPIO_Pin_8); \
  GPIO_ResetBits(GPIOB, GPIO_Pin_15);

#define LEFTSTOP()                 \
  GPIO_SetBits(GPIOD, GPIO_Pin_9); \
  GPIO_ResetBits(GPIOD, GPIO_Pin_10);

#define LEFTRUN()                    \
  GPIO_ResetBits(GPIOD, GPIO_Pin_9); \
  GPIO_SetBits(GPIOD, GPIO_Pin_10);

#define RIGHTSTOP()                   \
  GPIO_ResetBits(GPIOD, GPIO_Pin_11); \
  GPIO_SetBits(GPIOD, GPIO_Pin_10);
#define RIGHTRUN()                  \
  GPIO_SetBits(GPIOD, GPIO_Pin_11); \
  GPIO_ResetBits(GPIOD, GPIO_Pin_10);

#define BACKSTOP()                    \
  GPIO_ResetBits(GPIOD, GPIO_Pin_14); \
  GPIO_SetBits(GPIOD, GPIO_Pin_13)
#define BACKRUN()                   \
  GPIO_SetBits(GPIOD, GPIO_Pin_14); \
  GPIO_ResetBits(GPIOD, GPIO_Pin_13)

#define FRONTSTOP()                 \
  GPIO_SetBits(GPIOD, GPIO_Pin_12); \
  GPIO_ResetBits(GPIOD, GPIO_Pin_13)
#define FRONTRUN()                    \
  GPIO_ResetBits(GPIOD, GPIO_Pin_12); \
  GPIO_SetBits(GPIOD, GPIO_Pin_13)

#define coincounton() GPIO_SetBits(GPIOC, GPIO_Pin_9)
#define coincountoff() GPIO_ResetBits(GPIOC, GPIO_Pin_9)

#define toycounton() GPIO_SetBits(GPIOC, GPIO_Pin_8)
#define toycointoff() GPIO_ResetBits(GPIOC, GPIO_Pin_8)

#define coinpoweron() GPIO_SetBits(GPIOC, GPIO_Pin_12)
#define coinpoweroff() GPIO_ResetBits(GPIOC, GPIO_Pin_12)

// 摇杆 按键 INNC 未接，礼品口光眼
#define FRONTKEY() GPIO_ReadInputDataBit(GPIOD, GPIO_Pin_2)  // front pd4
#define BACKKEY() GPIO_ReadInputDataBit(GPIOD, GPIO_Pin_3)   // back  pd3
#define LEFTKEY() GPIO_ReadInputDataBit(GPIOD, GPIO_Pin_1)
#define RIGHTKEY() GPIO_ReadInputDataBit(GPIOD, GPIO_Pin_0)
#define ENTERKEY() GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_15)
#define SETKEY() GPIO_ReadInputDataBit(GPIOD, GPIO_Pin_4)   // PE2本来的
#define SETKEY2() GPIO_ReadInputDataBit(GPIOD, GPIO_Pin_5)  // PE2本来的
#define OUTSENTOR() GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_11)

// 天车微动
#define COININ() GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_8)
#define GROUNDSW() GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_0)  // pb0本来的
#define DOWNSW() GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_8)
#define LEFTSW() GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_9)
#define FRONTSW() GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_11)
#define BACKSW() GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_12)
#define SWNC() GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_10)  // 本来的

#define WIFIEN() GPIO_SetBits(GPIOA, GPIO_Pin_7);
#define WIFIDISEN() GPIO_ResetBits(GPIOA, GPIO_Pin_7);
#define WIFIRSTOFF() GPIO_ResetBits(GPIOA, GPIO_Pin_6);
#define WIFIRSTON() GPIO_SetBits(GPIOA, GPIO_Pin_6);

#define MUSICBUSY() GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_5)

#endif

#define GgsmVest 0  // 1：测试指令 0:正常运行
#define GsmAT 0     // 纯AT测试   0关掉
#define IMEI 0      // 1，以IMEI为机台号 ，0：自定义机台号

#define Ver 0x10  // 程序版本号2.9
#define md5 1
