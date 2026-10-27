#include "usart_driver.h"

// #include "usart.h"

TPYESTR_USART uart1_dev;
TPYESTR_USART uart3_dev;

void USART_AppInit(void) {
  USART1_Configuration();
  // HAL_UART_Receive_IT(&huart4, &uart4_dev.rx_temp, 1);
  // HAL_UART_Receive_IT(&huart2, &rfid_uart2_dev.rx_temp, 1);
  uart1_dev.status = RX_IDLE;
  uart1_dev.rx_buffer_pointer = 0;
  uart3_dev.status = RX_IDLE;
  uart3_dev.rx_buffer_pointer = 0;
}

#if defined(HARDWARE_V0) || defined(HARDWARE_V2)
void USART1_IRQHandler(void) {
  if (USART_GetITStatus(USART1, USART_IT_RXNE) != RESET) {
    uart1_dev.idle_time = USART1_RX_TIMEOUT;
    uart1_dev.rx_buffer[uart1_dev.rx_buffer_pointer] = USART_ReceiveData(USART1);
    uart1_dev.rx_buffer_pointer++;
    if (uart1_dev.rx_buffer_pointer == USART1_BUFFER_MAX) {
      uart1_dev.rx_buffer_pointer = 0;
    }
    USART_ClearITPendingBit(USART1, USART_IT_RXNE);
  }
  if (USART_GetITStatus(USART1, USART_IT_TC) != RESET)  // 如果是发送完成中断
  {
    USART_ClearITPendingBit(USART1, USART_IT_TC);  // 清除发送完成中断标志
  }
  // combusy=0;
}
#endif

#ifdef HARDWARE_V1
void USART3_IRQHandler(void) {
  if (USART_GetITStatus(USART3, USART_IT_RXNE) != RESET) {
    uart3_dev.idle_time = USART3_RX_TIMEOUT;
    uart3_dev.rx_buffer[uart3_dev.rx_buffer_pointer] = USART_ReceiveData(USART3);
    uart3_dev.rx_buffer_pointer++;
    if (uart3_dev.rx_buffer_pointer == USART3_BUFFER_MAX) {
      uart3_dev.rx_buffer_pointer = 0;
    }
    USART_ClearITPendingBit(USART3, USART_IT_RXNE);
  }
  if (USART_GetITStatus(USART3, USART_IT_TC) != RESET)  // 如果是发送完成中断
  {
    USART_ClearITPendingBit(USART3, USART_IT_TC);  // 清除发送完成中断标志
  }
  // combusy=0;
}
#endif

void USART1_Isr(void) {
  uint16_t i;
  if (uart1_dev.idle_time) {
    uart1_dev.idle_time--;
    if (!uart1_dev.idle_time) {
      if (uart1_dev.status != RX_DONE) {
        for (i = 0; i < uart1_dev.rx_buffer_pointer; i++) {
          uart1_dev.rx_data[i] = uart1_dev.rx_buffer[i];
          uart1_dev.rx_data_len = uart1_dev.rx_buffer_pointer;
        }
      }
      uart1_dev.rx_buffer_pointer = 0;
      uart1_dev.status = RX_DONE;
    }
  }
}

void USART3_Isr(void) {
  uint16_t i;
  if (uart3_dev.idle_time) {
    uart3_dev.idle_time--;
    if (!uart3_dev.idle_time) {
      if (uart3_dev.status != RX_DONE) {
        for (i = 0; i < uart3_dev.rx_buffer_pointer; i++) {
          uart3_dev.rx_data[i] = uart3_dev.rx_buffer[i];
          uart3_dev.rx_data_len = uart3_dev.rx_buffer_pointer;
        }
        GPIO_ResetBits(GPIOB, GPIO_Pin_7);
      }
      uart3_dev.rx_buffer_pointer = 0;
      uart3_dev.status = RX_DONE;
    }
  }
}

int fputc(int ch, FILE *f) {
  // HAL_UART_Transmit(&huart4, (uint8_t *)&ch, 1, 0xffff);
  return ch;
}
