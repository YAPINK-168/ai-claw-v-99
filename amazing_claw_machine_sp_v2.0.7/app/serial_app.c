#include "serial_app.h"

#include "basic.h"
#include "crc.h"
#include "extern.h"
#include "lcd.h"
#include "setgame.h"
#include "stm32f10x.h"
#include "usart_driver.h"

extern TPYESTR_USART SERIAL_DEV;
extern uint8_t control_mode;
extern uint8_t free_play_num;
extern uint8_t free_mode_flag;
extern uint8_t beginning;
extern volatile uint16_t key_status;
extern u32 display_refresh_time;
// uint8_t g_serial_sn = 1;

// uint32_t serial_send_coin_time = 0;
volatile uint32_t serial_heartbeat_time = 0;
volatile uint32_t serial_control_time = 0;
SERIAL_CoinInfoTypeDef coin_info = {1, 0, 0, 0, 0, 0};

#define MACHINE_EVENT_QSIZE 16
static volatile uint8_t machine_event_q[MACHINE_EVENT_QSIZE];
static volatile uint8_t machine_event_w = 0;
static volatile uint8_t machine_event_r = 0;
static volatile uint16_t machine_event_once = 0;
static volatile uint8_t machine_round_won = 0;
static volatile uint8_t machine_round_end_pending = 0;

static void MACHINE_EventMarkSuccess(void) {
  machine_round_won = 1;
}

void SERIAL_Init(void) {
  SERIAL_DEV.status = RX_IDLE;
  SERIAL_DEV.rx_buffer_pointer = 0;
  coin_info.sn = 1;
  machine_event_w = 0;
  machine_event_r = 0;
  machine_event_once = 0;
  machine_round_won = 0;
  machine_round_end_pending = 0;
}

void MACHINE_EventPost(uint8_t event_id) {
  uint8_t next;
  if (event_id == MECH_EVT_SUCCESS) {
    MACHINE_EventMarkSuccess();
  }
  __disable_irq();
  next = (uint8_t)(machine_event_w + 1);
  if (next >= MACHINE_EVENT_QSIZE) {
    next = 0;
  }
  if (next != machine_event_r) {
    machine_event_q[machine_event_w] = event_id;
    machine_event_w = next;
  }
  __enable_irq();
}

void MACHINE_EventPostOnce(uint8_t event_id) {
  uint16_t bit;
  uint8_t already;
  if (event_id == MECH_EVT_SUCCESS) {
    MACHINE_EventMarkSuccess();
  }
  if (event_id >= 16) {
    return;
  }
  bit = (uint16_t)(1u << event_id);
  __disable_irq();
  already = (machine_event_once & bit) ? 1 : 0;
  if (!already) {
    machine_event_once |= bit;
  }
  __enable_irq();
  if (!already) {
    MACHINE_EventPost(event_id);
  }
}

void MACHINE_EventResetRound(void) {
  __disable_irq();
  machine_event_once = 0;
  machine_round_won = 0;
  machine_round_end_pending = 0;
  __enable_irq();
}

void MACHINE_EventRequestRoundEnd(void) {
  machine_round_end_pending = 1;
}

void MACHINE_EventFlushRoundEnd(void) {
  uint8_t pending;
  __disable_irq();
  pending = machine_round_end_pending;
  if (pending) {
    machine_round_end_pending = 0;
  }
  __enable_irq();
  if (!pending) {
    return;
  }
  MACHINE_EventPostOnce(MECH_EVT_GRAB_END);
  if (!machine_round_won) {
    MACHINE_EventPostOnce(MECH_EVT_FAIL);
  }
}

void SERIAL_SendEvent(uint8_t event_id) {
  uint8_t send_tmp[8];
  uint16_t crc_tmp;
  static uint8_t sn_tmp = 1;
  send_tmp[0] = 0xfa;
  send_tmp[1] = 0x06;
  send_tmp[2] = sn_tmp++;
  send_tmp[3] = (uint8_t)BSP_GetTick();
  send_tmp[4] = SERIAL_CMD_EVENT;
  send_tmp[5] = event_id;
  crc_tmp = CRC_GetCrc16(send_tmp, 6);
  send_tmp[6] = crc_tmp;
  send_tmp[7] = crc_tmp >> 8;
  serial_heartbeat_time = 20000;
  SERIAL_TX(send_tmp, 8);
}

static void SERIAL_PollMachineEvents(void) {
  uint8_t id;
  uint8_t has;
  for (;;) {
    has = 0;
    id = 0;
    __disable_irq();
    if (machine_event_r != machine_event_w) {
      id = machine_event_q[machine_event_r];
      machine_event_r++;
      if (machine_event_r >= MACHINE_EVENT_QSIZE) {
        machine_event_r = 0;
      }
      has = 1;
    }
    __enable_irq();
    if (!has) {
      break;
    }
    SERIAL_SendEvent(id);
  }
}

void SERIAL_SendHeartbeat(uint8_t status, uint8_t coin_num, uint16_t id, uint16_t version) {
  uint8_t send_tmp[13];
  uint16_t crc_tmp;
  static uint8_t sn_tmp = 1;
  send_tmp[0] = 0xfa;
  send_tmp[1] = 0x0b;
  send_tmp[2] = sn_tmp++;
  send_tmp[3] = (uint8_t)BSP_GetTick();
  send_tmp[4] = 0x00;
  send_tmp[5] = status;
  send_tmp[6] = coin_num;
  send_tmp[7] = id;
  send_tmp[8] = id >> 8;
  send_tmp[9] = version;
  send_tmp[10] = version >> 8;
  crc_tmp = CRC_GetCrc16(send_tmp, 11);
  send_tmp[11] = crc_tmp;
  send_tmp[12] = crc_tmp >> 8;
  SERIAL_TX(send_tmp, 13);
}

void SERIAL_SendCoin(SERIAL_CoinInfoTypeDef *coin_info) {
  uint8_t send_tmp[10];
  uint16_t crc_tmp;
  send_tmp[0] = 0xfa;
  send_tmp[1] = 0x08;
  send_tmp[2] = coin_info->sn;
  send_tmp[3] = (uint8_t)BSP_GetTick();
  send_tmp[4] = 0x01;
  send_tmp[5] = coin_info->coin;
  send_tmp[6] = coin_info->normal_out;
  send_tmp[7] = coin_info->balance;
  crc_tmp = CRC_GetCrc16(send_tmp, 8);
  send_tmp[8] = crc_tmp;
  send_tmp[9] = crc_tmp >> 8;
  serial_heartbeat_time = 20000;
  SERIAL_TX(send_tmp, 10);
  // coin_info ->countdown = 1000;
}

void SERIAL_SendKey(uint16_t key_value) {
  uint8_t send_tmp[9];
  uint16_t crc_tmp;
  static uint8_t sn_tmp = 1;
  send_tmp[0] = 0xfa;
  send_tmp[1] = 0x07;
  send_tmp[2] = sn_tmp++;
  send_tmp[3] = (uint8_t)BSP_GetTick();
  send_tmp[4] = 0x02;
  send_tmp[5] = key_value;
  send_tmp[6] = key_value >> 8;
  crc_tmp = CRC_GetCrc16(send_tmp, 7);
  send_tmp[7] = crc_tmp;
  send_tmp[8] = crc_tmp >> 8;
  serial_heartbeat_time = 20000;
  SERIAL_TX(send_tmp, 9);
}

void SERIAL_SendStatus(uint8_t status, uint8_t coin_num, uint16_t id, uint16_t version) {
  uint8_t send_tmp[13];
  uint16_t crc_tmp;
  static uint8_t sn_tmp = 1;
  send_tmp[0] = 0xfa;
  send_tmp[1] = 0x0b;
  send_tmp[2] = sn_tmp++;
  send_tmp[3] = (uint8_t)BSP_GetTick();
  send_tmp[4] = 0x03;
  send_tmp[5] = status;
  send_tmp[6] = coin_num;
  send_tmp[7] = id;
  send_tmp[8] = id >> 8;
  send_tmp[9] = version;
  send_tmp[10] = version >> 8;

  crc_tmp = CRC_GetCrc16(send_tmp, 11);
  send_tmp[11] = crc_tmp;
  send_tmp[12] = crc_tmp >> 8;
  serial_heartbeat_time = 20000;
  SERIAL_TX(send_tmp, 13);
}

void SERIAL_SendBill(uint32_t coin, uint32_t normal_out, uint32_t abnormal_out) {
  uint8_t send_tmp[19];
  uint16_t crc_tmp;
  static uint8_t sn_tmp = 1;
  send_tmp[0] = 0xfa;
  send_tmp[1] = 0x11;
  send_tmp[2] = sn_tmp++;
  send_tmp[3] = (uint8_t)BSP_GetTick();
  send_tmp[4] = 0x04;
  send_tmp[5] = coin;
  send_tmp[6] = coin >> 8;
  send_tmp[7] = coin >> 16;
  send_tmp[8] = coin >> 24;
  send_tmp[9] = normal_out;
  send_tmp[10] = normal_out >> 8;
  send_tmp[11] = normal_out >> 16;
  send_tmp[12] = normal_out >> 24;
  send_tmp[13] = abnormal_out;
  send_tmp[14] = abnormal_out >> 8;
  send_tmp[15] = abnormal_out >> 16;
  send_tmp[16] = abnormal_out >> 24;
  crc_tmp = CRC_GetCrc16(send_tmp, 17);
  send_tmp[17] = crc_tmp;
  send_tmp[18] = crc_tmp >> 8;
  serial_heartbeat_time = 20000;
  SERIAL_TX(send_tmp, 19);
}

void SERIAL_SendControl(uint8_t status) {
  uint8_t send_tmp[8];
  uint16_t crc_tmp;
  static uint8_t sn_tmp = 1;
  send_tmp[0] = 0xfa;
  send_tmp[1] = 0x06;
  send_tmp[2] = sn_tmp++;
  send_tmp[3] = (uint8_t)BSP_GetTick();
  send_tmp[4] = 0x06;
  send_tmp[5] = status;
  crc_tmp = CRC_GetCrc16(send_tmp, 6);
  send_tmp[6] = crc_tmp;
  send_tmp[7] = crc_tmp >> 8;
  serial_heartbeat_time = 20000;
  SERIAL_TX(send_tmp, 8);
}

void SERIAL_SendFreeNum(uint8_t free_num) {
  uint8_t send_tmp[8];
  uint16_t crc_tmp;
  static uint8_t sn_tmp = 1;
  send_tmp[0] = 0xfa;
  send_tmp[1] = 0x06;
  send_tmp[2] = sn_tmp++;
  send_tmp[3] = (uint8_t)BSP_GetTick();
  send_tmp[4] = 0x07;
  send_tmp[5] = free_num;
  crc_tmp = CRC_GetCrc16(send_tmp, 6);
  send_tmp[6] = crc_tmp;
  send_tmp[7] = crc_tmp >> 8;
  serial_heartbeat_time = 20000;
  SERIAL_TX(send_tmp, 8);
}

void SERIAL_SendValue(uint16_t coin_num, uint16_t price, uint8_t game_time) {
  uint8_t send_tmp[13];
  uint16_t crc_tmp;
  static uint8_t sn_tmp = 1;
  send_tmp[0] = 0xfa;
  send_tmp[1] = 0x0b;
  send_tmp[2] = sn_tmp++;
  send_tmp[3] = (uint8_t)BSP_GetTick();
  send_tmp[4] = 0x05;
  send_tmp[5] = 0x01;
  send_tmp[6] = coin_num;
  send_tmp[7] = coin_num >> 8;
  send_tmp[8] = price;
  send_tmp[9] = price >> 8;
  send_tmp[10] = game_time;

  crc_tmp = CRC_GetCrc16(send_tmp, 11);
  send_tmp[11] = crc_tmp;
  send_tmp[12] = crc_tmp >> 8;
  serial_heartbeat_time = 20000;
  SERIAL_TX(send_tmp, 13);
}

void SERIAL_APP_Isr(void) {
  if (serial_heartbeat_time) {
    serial_heartbeat_time--;
  }
  if (coin_info.countdown) {
    coin_info.countdown--;
  }
  if (control_mode == 1) {
    if (serial_control_time) {
      serial_control_time--;
      if (serial_control_time == 0) {  // 超时未收到控制指令，释放控制
        control_mode = 0;
        SERIAL_SendStatus(0x01, coinin, machineid, version_code_z);
        while (key_status);
        TIM_Cmd(TIM1, ENABLE);
        LCD_Set_XY(4, 4);
        Write_Char(1, 0x20);
        Write_Char(1, 0x20);
        LCD_Set_XY(3, 1);
        Write_Char(1, 0x20);
        Write_Char(1, 0x21);
        display_refresh_time = 300000;
      }
    }
  }
}

void SERIAL_Task(void) {
  uint16_t crc_tmp;
  SERIAL_PollMachineEvents();
  if (!serial_heartbeat_time) {
    serial_heartbeat_time = 20000;
    if (beginning == 0) {
      if (control_mode == 0) {
        SERIAL_SendHeartbeat(0x01, coinin, machineid, 0x00a1);
      } else {
        SERIAL_SendHeartbeat(0x03, coinin, machineid, 0x00a1);
      }
    } else {
      SERIAL_SendHeartbeat(0x02, coinin, machineid, 0x00a1);
    }
  }
  if (!coin_info.countdown) {
    if (coin_info.send_num) {
      coin_info.send_num--;
      if (coin_info.send_num == 0) {  // 三次重发结束后都没有收到反馈，sn+1，不再重发
        // coin_info.sn++;
      } else {
        SERIAL_SendCoin(&coin_info);
      }
      coin_info.countdown = 1000;
    }
  }
  if (SERIAL_DEV.status == RX_DONE) {
    crc_tmp = SERIAL_DEV.rx_data[SERIAL_DEV.rx_data[1]];
    crc_tmp += SERIAL_DEV.rx_data[SERIAL_DEV.rx_data[1] + 1] << 8;
		if (SERIAL_DEV.rx_data[0] == 0x0a) {
    if (crc_tmp == CRC_GetCrc16(SERIAL_DEV.rx_data, SERIAL_DEV.rx_data[1])) {  // CRC校验成功
                                                                               // if (1) {
      switch (SERIAL_DEV.rx_data[4]) {
        case 0x01:  // 投币反馈
          if (SERIAL_DEV.rx_data[2] == coin_info.sn) {
            if (coin_info.coin >= SERIAL_DEV.rx_data[5]) {
              coin_info.coin -= SERIAL_DEV.rx_data[5];
            }
            if (coin_info.normal_out >= SERIAL_DEV.rx_data[6]) {
              coin_info.normal_out -= SERIAL_DEV.rx_data[6];
            }
            coin_info.send_num = 0;  // 收到反馈，不再重发
          }
          break;

        case 0x03:  // 游戏状态查询
          if (SERIAL_DEV.rx_data[5] == 0x00) {
            if (beginning == 0) {
              if (control_mode == 0) {
                SERIAL_SendStatus(0x01, coinin, machineid, version_code_z);
              } else {
                SERIAL_SendStatus(0x03, coinin, machineid, version_code_z);
              }
            } else {
              SERIAL_SendStatus(0x02, coinin, machineid, version_code_z);
            }
          }
          break;
        case 0x04:
          SERIAL_SendBill(allcoin, alltoy, surprisecount);
          break;
        case 0x05:  // 查询机器参数
          if (SERIAL_DEV.rx_data[5] == 0x01) {
            SERIAL_SendValue(coinbase, outbase, gametimebase);
          }
          break;
        case 0x06:  // 接管
          if (SERIAL_DEV.rx_data[5] == 0x01) {
            if (beginning == 0) {
              serial_control_time = 90000;  // 超过90s没有收到控制指令，释放控制
              control_mode = 1;
              SERIAL_SendControl(0x01);
              TIM_Cmd(TIM1, DISABLE);
              LCD_Set_XY(4, 4);
              Write_Char(1, 0x20);
              Write_Char(1, 0x12);
              LCD_Set_XY(3, 1);
              Write_Char(1, 0x20);
              Write_Char(1, 0x20);
            } else {
              SERIAL_SendControl(0x02);
            }
          } else {
            if (SERIAL_DEV.rx_data[5] == 0x00) {
              control_mode = 0;
              SERIAL_SendControl(0x00);
              while (key_status);
              TIM_Cmd(TIM1, ENABLE);
              LCD_Set_XY(4, 4);
              Write_Char(1, 0x20);
              Write_Char(1, 0x20);
            }
          }
          break;
        case 0x07:  // 设置免费局数
                    // if (beginning == 0) {
          free_play_num = SERIAL_DEV.rx_data[5];
          if ((free_play_num == 0xff) || (free_play_num == 0)) {
            gametime = 0;
            // gametimeflash = 1;
            serial_control_time = 90000;  // 超过90s没有收到控制指令，释放控制
            control_mode = 1;//接管游戏
            gametimeflesh();
          }
          SERIAL_SendFreeNum(free_play_num);
          if (free_play_num == 0xff) {
            free_play_num = 0;
          }
          break;
        case 0x08:
          custom_led_flag = 1;
          if (SERIAL_DEV.rx_data[5] == 5) {
            custom_led_on_time = 500;
            custom_led_off_time = 0;
          } else {
            custom_led_on_time = SERIAL_DEV.rx_data[5] * 100;
            custom_led_off_time = SERIAL_DEV.rx_data[5] * 100;
          }
          break;
        default:
          break;
      }
    }
	}
    SERIAL_DEV.status = RX_IDLE;
  }
}
