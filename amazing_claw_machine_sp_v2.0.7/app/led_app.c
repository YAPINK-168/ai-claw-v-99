#include "led_app.h"

volatile uint16_t m_led1_on_time = 300;
volatile uint16_t m_led1_off_time = 300;
volatile uint8_t m_led1_flash_sw = 0;
volatile uint16_t m_led2_on_time = 300;
volatile uint16_t m_led2_off_time = 300;
volatile uint8_t m_led2_flash_sw = 0;
volatile uint16_t led1_on_time_tmp = 0;
volatile uint16_t led1_off_time_tmp = 0;
volatile uint16_t led2_on_time_tmp = 0;
volatile uint16_t led2_off_time_tmp = 0;
volatile uint32_t led1_show_time = 0;
volatile uint32_t led2_show_time = 0;
volatile uint8_t led1_off_status = 0;
volatile uint8_t led2_off_status = 0;

void LED_App_Init(void) {
  LED_App_SetLed1FlashOff(0);
  LED_App_SetLed2FlashOff(0);
}

void LED_App_Isr(void) {
#ifdef HARDWARE_V2
  if (led1_show_time) {
    led1_show_time--;
    if (led1_show_time == 0) {
      LED_App_SetLed1FlashOff(led1_off_status);
    }
    if (m_led1_flash_sw) {
      if (led1_on_time_tmp) {
        led1_on_time_tmp--;
        if (led1_on_time_tmp == 0) {
          M_LED1_OFF();
          led1_off_time_tmp = m_led1_off_time;
        }
      } else {
        if (led1_off_time_tmp) {
          led1_off_time_tmp--;
          if (led1_off_time_tmp == 0) {
            M_LED1_ON();
            led1_on_time_tmp = m_led1_on_time;
          }
        }
      }
    }
  }

  if (led2_show_time) {
    led2_show_time--;
    if (led2_show_time == 0) {
      LED_App_SetLed2FlashOff(led2_off_status);
    }
    if (m_led2_flash_sw) {
      if (led2_on_time_tmp) {
        led2_on_time_tmp--;
        if (led2_on_time_tmp == 0) {
          M_LED2_OFF();
          led2_off_time_tmp = m_led2_off_time;
        }
      } else {
        if (led2_off_time_tmp) {
          led2_off_time_tmp--;
          if (led2_off_time_tmp == 0) {
            M_LED2_ON();
            led2_on_time_tmp = m_led2_on_time;
          }
        }
      }
    }
  }
#endif
}

void LED_App_SetLed1FlashOn(uint16_t on_time, uint16_t off_time, uint32_t show_time, uint8_t off_status) {
  m_led1_on_time = on_time;
  m_led1_off_time = off_time;
  m_led1_flash_sw = 1;
  led1_on_time_tmp = m_led1_on_time;
  led1_off_time_tmp = 0;
  led1_off_status = off_status;
  led1_show_time = show_time;
  M_LED1_ON();
}

void LED_App_SetLed1FlashOff(uint8_t off_status) {
  m_led1_flash_sw = 0;
  led1_on_time_tmp = 0;
  led1_off_time_tmp = 0;
  led1_show_time = 0;
  if (off_status) {
    M_LED1_ON();
  } else {
    M_LED1_OFF();
  }
}

void LED_App_SetLed2Flash(uint16_t on_time, uint16_t off_time, uint32_t show_time, uint8_t off_status) {
  m_led2_on_time = on_time;
  m_led2_off_time = off_time;
  m_led2_flash_sw = 1;
  led2_on_time_tmp = m_led2_on_time;
  led2_off_time_tmp = 0;
  led2_show_time = show_time;
  led2_off_status = off_status;
  M_LED2_ON();
}

void LED_App_SetLed2FlashOff(uint8_t off_status) {
  m_led2_flash_sw = 0;
  led2_on_time_tmp = 0;
  led2_off_time_tmp = 0;
  led2_show_time = 0;
  if (off_status) {
    M_LED2_ON();
  } else {
    M_LED2_OFF();
  }
}
