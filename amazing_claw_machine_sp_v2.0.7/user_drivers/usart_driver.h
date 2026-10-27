#ifndef __USART_DRIVER_H
#define __USART_DRIVER_H

#include "bsp.h"

enum USART_STATUS{
RX_IDLE,RX_DONE
};

// #define UART2_FRAME_MODE

#define USART_BUFFER_MAX 256
#define USART_RX_TIMEOUT 100
#define USART_FRAME_HEADER 0x0a

#define USART1_BUFFER_MAX 256
#define USART1_RX_TIMEOUT 100
#define USART1_FRAME_HEADER 0x0a

#define USART3_BUFFER_MAX 256
#define USART3_RX_TIMEOUT 100
#define USART3_FRAME_HEADER 0x0a

typedef struct usart_dev {
  uint8_t rx_temp;
  volatile uint8_t rx_buffer[USART_BUFFER_MAX];
  volatile uint16_t rx_buffer_pointer;
  volatile uint16_t rx_buffer_len;
  volatile uint8_t rx_data[USART_BUFFER_MAX];
  volatile uint16_t rx_data_len;
  volatile uint16_t idle_time;
  // enum USART_STATUS status;
  volatile uint8_t status;
} TPYESTR_USART;

void USART1_IRQHandler(void);
void USART3_IRQHandler(void);
void USART1_Isr(void);
void USART3_Isr(void);

#endif
