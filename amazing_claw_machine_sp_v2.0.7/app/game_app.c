#include "game_app.h"

#include "key_app.h"
#include "serial_app.h"

extern volatile uint16_t key_status;
extern uint8_t g_serial_sn;
extern uint8_t beginning;

uint8_t control_mode = 0;
uint8_t free_play_num = 0;
uint8_t free_mode_flag = 0;

uint8_t GAME_RandomMagicPoint(uint8_t *set_buffer, uint8_t len, uint8_t max_offset, uint16_t random_seed) {
  uint8_t i;
  uint8_t offset;
  if (max_offset > len - 1) {
    max_offset = len - 1;
  }
  for (i = 0; i < len + max_offset; i++) {
    set_buffer[i] = 0;
  }
  offset = random_seed % (max_offset + 1);
  if (random_seed % 2) {
    set_buffer[len + offset - 1] = 1;
    return (len + offset - 1);
  } else {
    set_buffer[len - offset - 1] = 1;
    return (len - offset - 1);
  }
  // return 0;
}

void GEME_Task2(void) {
  static volatile uint16_t key_status_last = 0;
  // if (control_mode || beginning != 0) {
  if (key_status != key_status_last) {
    // if (key_status != 0) {
    SERIAL_SendKey(key_status);
    // }
    key_status_last = key_status;
  }
  // }
}
