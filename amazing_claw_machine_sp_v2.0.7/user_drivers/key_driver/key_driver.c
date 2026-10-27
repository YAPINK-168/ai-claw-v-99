#include "key_driver.h"

#include <stdlib.h>

// #include "gpio_driver.h"

void KEY_GpioInit(TypeStr_key* key_device) {
  uint8_t i;
  for (i = 0; i < key_device->channel; i++) {
    if (key_device->hal[i].polarity) {
      SET_KEY_IN(key_device->hal[i].port, key_device->hal[i].pin, GPIO_PuPd_DOWN);
    } else {
      SET_KEY_IN(key_device->hal[i].port, key_device->hal[i].pin, GPIO_PuPd_UP);
    }
  }
}

uint16_t KEY_ReadValue(TypeStr_key* key_device) {
  uint8_t i;
  uint16_t tmp = 0;
  for (i = key_device->channel; i > 0; i--) {
    tmp = tmp << 1;
    if (key_device->hal[i - 1].polarity) {
      if (KEY_READ_PIN(key_device->hal[i - 1].port, key_device->hal[i - 1].pin)) {
        tmp |= 0x0001;
      }
    } else {
      if (!KEY_READ_PIN(key_device->hal[i - 1].port, key_device->hal[i - 1].pin)) {
        tmp |= 0x0001;
      }
    }
  }
  return tmp;
}

void KEY_Scan_Isr(TypeStr_key* key_device) {
  if (key_device == NULL) return;
  key_device->current_value = KEY_ReadValue(key_device);
  key_device->key_tick += KEY_SCAN_TIME;
  switch (key_device->status) {
    case STABLE:
      // 本轮扫描值和上轮扫描值一致，按键保持稳定状态
      if (key_device->current_value == key_device->last_value) {
        key_device->true_value = key_device->current_value;                              // 更新按键有效值
        key_device->stable_time = key_device->key_tick - key_device->start_change_time;  // 更新稳定时间
      } else {                                                                           // 本轮扫描值与上轮扫描值不一致，按键进入抖动状态
        key_device->last_value = key_device->current_value;                              // 保存本轮扫描结果
        // 记录状态变化开始的时间
        key_device->start_change_time = key_device->key_tick;
        key_device->stable_time = 0;
        // 更新按键状态
        key_device->status = JITTER;
      }
      break;
    case JITTER:
      // 抖动达到指定时间，按键进入稳定状态
      if ((uint8_t)(key_device->key_tick - key_device->start_change_time) > 0) {
        key_device->true_value = key_device->current_value;  // 更新按键有效值
        key_device->reply_status = NO_REPLY;                 // 新的按键事件，等待响应
        key_device->start_change_time = key_device->key_tick;
        key_device->status = STABLE;
      }
      break;
    default:
      break;
  }
  key_device->callback(key_device->true_value);
}

TypeStr_key* NEW_KeyDrv(TypedefStr_key_hal* key_hal, uint8_t channel, void (*callback)(uint8_t)) {
  if (key_hal == NULL) return NULL;
  TypeStr_key* key_device;
  key_device = (TypeStr_key*)malloc(sizeof(TypeStr_key));
  key_device->hal = key_hal;
  key_device->channel = channel;
  KEY_GpioInit(key_device);
  key_device->status = STABLE;
  key_device->callback = callback;
  return key_device;
}

void DELE_KeyDrv(TypeStr_key** key_device) {
  free(*key_device);
  *key_device = NULL;
}
