#ifndef __KEY_DRIVER_H
#define __KEY_DRIVER_H

#include "bsp.h"

#define KEY_SCAN_TIME 10  // 扫描间隔ms

#define STABLE 0
#define JITTER 1
#define REPLYED 0
#define NO_REPLY 1

#define KEY_UP_PRESS 0x0001       // 按键1按下
#define KEY_DOWN_PRESS 0x0002     // 按键2按下
#define KEY_MENU_PRESS 0x0004     // 按键3按下
#define KEY_FACTORY_PRESS 0x0008  // 按键4按下

#define KEY5_PRESS 0x0010                                      // 按键5按下
#define KEY6_PRESS 0x0020                                      // 按键5按下
#define KEY7_PRESS 0x0040                                      // 按键5按下
#define KEY1N2_PRESS (KEY1_PRESS | KEY2_PRESS)                 // 按键1和按键2同时按下
#define KEY1N3_PRESS (KEY1_PRESS | KEY3_PRESS)                 // 按键1和按键3同时按下
#define KEY1N4_PRESS (KEY1_PRESS | KEY4_PRESS)                 // 按键1和按键3同时按下
#define KEY2N3_PRESS (KEY2_PRESS | KEY3_PRESS)                 // 按键1和按键3同时按下
#define KEY3N5_PRESS (KEY3_PRESS | KEY5_PRESS)                 // 按键3和按键5同时按下
#define KEY1N2N3_PRESS (KEY1_PRESS | KEY2_PRESS | KEY3_PRESS)  // 按键1\2和按键3同时按下
#define KEY1N2N4_PRESS (KEY1_PRESS | KEY2_PRESS | KEY4_PRESS)  // 按键1\2和按键4同时按下

#define SET_KEY_IN(GPIO, PIN, PUPD)

#define KEY_READ_PIN(GPIO, PIN) (GPIO_ReadInputDataBit(GPIO, PIN) ? 1 : 0)

#define KEY_DelayMs(ms) Delay1ms(ms)

typedef struct key_hal {
  GPIO_TypeDef* port;
  uint32_t pin;
  uint8_t polarity : 1;  // 按键极性 0:低电平有效 1:高电平有效
} TypedefStr_key_hal;

typedef struct str_key TypeStr_key;
struct str_key {
  TypedefStr_key_hal* hal;
  volatile uint8_t channel;             // 通道数
  volatile uint8_t status : 1;          // 按键设备运行状态 STABLE：稳定状态 JITTER:抖动状态
  volatile uint8_t reply_status : 1;    // 事件响应状态  REPLYED 已响应 NO_REPAY未响应
  volatile uint8_t last_value;          // 上轮扫描时按键数据（消抖用）
  volatile uint8_t current_value;       // 本轮扫描按键数据（消抖用）
  volatile uint16_t true_value;          // 按键有效数据
  volatile uint16_t start_change_time;  // 发生状态变化时按键tick值
  volatile uint16_t stable_time;        // 按键稳定的时间
  volatile uint16_t key_tick;           // 按键设备tick
  void (*callback)(uint8_t value);
};

void KEY_Scan_Isr(TypeStr_key* key_device);
TypeStr_key* NEW_KeyDrv(TypedefStr_key_hal* key_hal, uint8_t channel, void (*callback)(uint8_t));
void DELE_KeyDrv(TypeStr_key** key_device);

#endif
