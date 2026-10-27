#include "software_it.h"

#include "bsp.h"
#include "key_driver.h"
#include "led_app.h"
#include "serial_app.h"
#include "usart_driver.h"

extern volatile uint32_t g_sys_tick_count;
extern TypeStr_key *key_dev;

volatile uint16_t g_software_if = 0;

volatile uint16_t g_random_num = 0;
volatile uint8_t guc_10ms_task_tick = 0;
volatile uint8_t guc_15ms_task_tick = 0;
volatile uint8_t guc_20ms_task_tick = 0;
volatile uint8_t guc_30ms_task_tick = 0;
volatile uint8_t guc_50ms_task_tick = 0;
volatile uint8_t guc_100ms_task_tick = 0;
volatile uint8_t guc_200ms_task_tick = 0;
volatile uint16_t guc_1s_task_tick = 0;
volatile uint16_t guc_20s_task_tick = 0;
volatile uint16_t guc_60s_task_tick = 0;

void CycleTask_Isr(void) {
  g_sys_tick_count++;
  g_random_num++;
  guc_10ms_task_tick++;
  SERIAL_APP_Isr();
  USART1_Isr();
  USART3_Isr();
  LED_App_Isr();
  if (guc_10ms_task_tick == 10) {
    guc_10ms_task_tick = 0;
  }

  guc_20ms_task_tick++;
  if (guc_20ms_task_tick == 20) {
    guc_20ms_task_tick = 0;
    KEY_Scan_Isr(key_dev);
  }
  // guc_30ms_task_tick++;
  // if (guc_30ms_task_tick == 30) {
  //   guc_30ms_task_tick = 0;
  // }

  guc_50ms_task_tick++;
  if (guc_50ms_task_tick == 50) {
    guc_50ms_task_tick = 0;
    // KEY_Scan_Isr(key_dev);
  }

  guc_100ms_task_tick++;
  if (guc_100ms_task_tick == 100) {
    guc_100ms_task_tick = 0;
  }

  // guc_200ms_task_tick++;
  // if (guc_200ms_task_tick == 200) {
  //   guc_200ms_task_tick = 0;
  // }

  guc_1s_task_tick++;
  if (guc_1s_task_tick == 1000) {
    guc_1s_task_tick = 0;
    // LL_GPIO_TogglePin(MCU_LED_GPIO_Port, MCU_LED_Pin);
  }

  guc_20s_task_tick++;
  if (guc_20s_task_tick == 20000) {
    guc_20s_task_tick = 0;
  }

  // guc_60s_task_tick++;
  // if (guc_60s_task_tick == 60000) {
  //   guc_60s_task_tick = 0;
  // }
}
