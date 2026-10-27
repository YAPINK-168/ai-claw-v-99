#ifndef __KEY_APP_H
#define __KEY_APP_H

#include "bsp.h"

#define UP_KEY_PUSH 0x01
#define DOWN_KEY_PUSH 0x02
#define LEFT_KEY_PUSH 0x04
#define RIGHT_KEY_PUSH 0x08
#define ENTER_KEY_PUSH 0x10

typedef struct {
  volatile uint8_t up_key;
  volatile uint8_t down_key;
  volatile uint8_t left_key;
  volatile uint8_t right_key;
  volatile uint8_t enter_key;
} KEY_StatusTypeDef;

void KEY_Init(void);
void KEY_Task(void);

#endif
