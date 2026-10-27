#ifndef __SERIAL_APP_H
#define __SERIAL_APP_H

#include "bsp.h"

#ifdef HARDWARE_V1
#define SERIAL_TX(a, b) UART3_len(a, b)
#define SERIAL_DEV uart3_dev
#endif

#if defined(HARDWARE_V0) || defined(HARDWARE_V2)
#define SERIAL_TX(a, b) UART1_len(a, b)
#define SERIAL_DEV uart1_dev
#endif

typedef struct {
  uint8_t sn;
  uint8_t coin;
  uint8_t balance;
  uint8_t normal_out;
  // uint8_t abnormal_out;
  uint8_t send_num;  // 重发send_num - 1次
  uint32_t countdown;
} SERIAL_CoinInfoTypeDef;

#define SERIAL_CMD_EVENT 0x09

#define MECH_EVT_COIN 0x01
#define MECH_EVT_CONTROL_START 0x02
#define MECH_EVT_GRAB_START 0x03
#define MECH_EVT_CLAW_DOWN_START 0x04
#define MECH_EVT_CLAW_DOWN 0x05
#define MECH_EVT_CLAW_CATCH 0x06
#define MECH_EVT_CLAW_UP_START 0x07
#define MECH_EVT_CLAW_UP 0x08
#define MECH_EVT_GRAB_END 0x09
#define MECH_EVT_SUCCESS 0x0A
#define MECH_EVT_FAIL 0x0B /* sent after GRAB_END if no SUCCESS this round */

void SERIAL_Init(void);
void SERIAL_APP_Isr(void);
void SERIAL_SendHeartbeat(uint8_t status, uint8_t coin_num, uint16_t id, uint16_t version);
void SERIAL_SendCoin(SERIAL_CoinInfoTypeDef *coin_info);
void SERIAL_SendKey(uint16_t key_value);
void SERIAL_SendStatus(uint8_t status, uint8_t coin_num, uint16_t id, uint16_t version);
void SERIAL_SendFreeNum(uint8_t free_num);
void SERIAL_SendEvent(uint8_t event_id);
void MACHINE_EventPost(uint8_t event_id);
void MACHINE_EventPostOnce(uint8_t event_id);
void MACHINE_EventResetRound(void);
/** Mark round finished; flush after OUTSENTOR poll (same ISR) posts 0x09 then 0x0B if needed. */
void MACHINE_EventRequestRoundEnd(void);
void MACHINE_EventFlushRoundEnd(void);
void SERIAL_Task(void);
#endif
