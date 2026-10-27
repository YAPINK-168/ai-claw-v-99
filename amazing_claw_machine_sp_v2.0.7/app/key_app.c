#include "key_app.h"

// #include <math.h>
// #include <stdio.h>
// #include <stdlib.h>
#include <string.h>

#include "adc.h"
#include "define.h"
#include "key_driver.h"
#include "lcd.h"
#include "setgame.h"

extern u16 allcoin;
extern u16 alltoy;
extern u16 surprisecount;
extern u16 free_mode_toy;

TypeStr_key *key_dev;
TypedefStr_key_hal key_dev_hal[5];
volatile uint16_t key_status = 0;

void KEYAPP_Isr(uint8_t value) { key_status = key_dev->true_value; }

void KEY_Init(void) {
  key_dev_hal[0].port = GPIOD;
#ifdef HARDWARE_V2
  key_dev_hal[0].pin = GPIO_Pin_2;  // FRONTKEY / 上
#else
  key_dev_hal[0].pin = GPIO_Pin_4;
#endif
  key_dev_hal[0].polarity = 0;

  key_dev_hal[1].port = GPIOD;
  key_dev_hal[1].pin = GPIO_Pin_3;
  key_dev_hal[1].polarity = 0;

  key_dev_hal[2].port = GPIOD;
  key_dev_hal[2].pin = GPIO_Pin_1;
  key_dev_hal[2].polarity = 0;

  key_dev_hal[3].port = GPIOD;
  key_dev_hal[3].pin = GPIO_Pin_0;
  key_dev_hal[3].polarity = 0;

  key_dev_hal[4].port = GPIOA;
  key_dev_hal[4].pin = GPIO_Pin_15;
  key_dev_hal[4].polarity = 0;

  key_dev = NEW_KeyDrv(key_dev_hal, sizeof(key_dev_hal) / sizeof(key_dev_hal[0]), KEYAPP_Isr);
}

void KEY_Task(void) {
  u16 tmp = 0;
  if (SETKEY() == 0 && ENTERKEY() == 0) {
    Delay1ms(50);
    if (SETKEY() == 0 && ENTERKEY() == 0) {
      Clr_Scr();
      SendCMD(0x30);
      SendCMD(0x30);
      LCD_Set_XY(1, 1);
      LCD_Write_String(1, 0, "总收入");
      LCD_Set_XY(1, 4);
      LCD_Write_Number(allcoin / 10000);
      LCD_Write_Number(allcoin % 10000 / 1000);
      LCD_Write_Number(allcoin % 1000 / 100);
      LCD_Write_Number(allcoin % 100 / 10);
      LCD_Write_Number(allcoin % 10);
      LCD_Write_String(2, 0, "礼品数");
      LCD_Set_XY(2, 4);
      LCD_Write_Number(alltoy / 10000);
      LCD_Write_Number(alltoy % 10000 / 1000);
      LCD_Write_Number(alltoy % 1000 / 100);
      LCD_Write_Number(alltoy % 100 / 10);
      LCD_Write_Number(alltoy % 10);
      LCD_Write_String(3, 0, "意外数");
      LCD_Set_XY(3, 4);
      LCD_Write_Number(surprisecount / 10000);
      LCD_Write_Number(surprisecount % 10000 / 1000);
      LCD_Write_Number(surprisecount % 1000 / 100);
      LCD_Write_Number(surprisecount % 100 / 10);
      LCD_Write_Number(surprisecount % 10);
      LCD_Write_String(4, 0, "免费数");
      LCD_Set_XY(4, 4);
      LCD_Write_Number(free_mode_toy / 10000);
      LCD_Write_Number(free_mode_toy % 10000 / 1000);
      LCD_Write_Number(free_mode_toy % 1000 / 100);
      LCD_Write_Number(free_mode_toy % 100 / 10);
      LCD_Write_Number(free_mode_toy % 10);
      while (SETKEY() == 0 && ENTERKEY() == 0)
        ;

      for (tmp = 15; tmp > 0; tmp--) {
        LCD_Set_XY(4, 7);
        LCD_Write_Number(tmp % 100 / 10);
        LCD_Write_Number(tmp % 10);
        Delay1ms(1500);
      }
      displayinit(0);
    }
  }
}
