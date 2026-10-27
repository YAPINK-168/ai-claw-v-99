#include "net_app.h"

#include "basic.h"
#include "define.h"
#include "extern.h"
#include "lcd.h"
#include "rc04v.h"
#include "setgame.h"

extern u8 uart1_rx_status;
extern u16 uart1_rx_time;
extern u16 wait_time;
extern u16 wifi_ssid_len;
extern u16 wifi_password_len;
extern uint8_t wifi_ssid[128];
extern uint8_t wifi_password[128];
extern u8 wifi_config_flag_addr;

#ifdef HARDWARE_V1
void NET_ConfigurationTask(void) {
  uint8_t i, j;
  while (1) {
    Clr_Scr();
    LCD_Write_String(1, 2, "loading");
    WIFIEN();      // 使能
    WIFIRSTOFF();  // 从低到高重启
    Delay1ms(500);
    WIFIRSTON();  // 从低到高重启
    Delay1ms(5000);
    UART1_SendString("AT+CWMODE=1\r\n");
    Delay1ms(3000);
    UART1_SendString("AT+CWSTARTSMART=2\r\n");
    Delay1ms(3000);
    LCD_Write_String(1, 2, "配网模式");
    uart1_rx_status = 0;
    RX1count = 0;
    while (uart1_rx_status != 2);
    j = 0;
    for (i = 0; i < RX1count; i++) {
      if ((RX1_buffer[i] == ':') && (RX1_buffer[i + 1] == 'A')) {
        break;
      }
    }
    if (i < RX1count) {
      uart1_rx_status = 0;
      RX1count = 0;
      while (uart1_rx_status != 2);
      for (i = 0; i < RX1count; i++) {
        if ((RX1_buffer[i] == ':') && (RX1_buffer[i - 2] == 'i')) {
          i++;
          break;
        }
      }
      for (j = 0; j < 128; j++) {
        if (RX1_buffer[i] == '\r') {
          j++;
          wifi_ssid[j] = '\0';
          for (; i < RX1count; i++) {
            if ((RX1_buffer[i] == ':') && (RX1_buffer[i - 2] == 'r')) {
              i++;
              break;
            }
          }
          for (j = 0; j < 128; j++) {
            if (RX1_buffer[i] == '\r') {
              j++;
              i++;
              wifi_password[j] = '\0';
              for (i = 0; i < 128; i++) {
                if (wifi_password[i] == '\0') {
                  wifi_password_len = i + 1;
                  break;
                }
              }
              for (i = 0; i < 128; i++) {
                if (wifi_ssid[i] == '\0') {
                  wifi_ssid_len = i + 1;
                  break;
                }
              }
              Clr_Scr();
              LCD_Write_String(1, 2, "配网成功");
              LCD_Write_String(2, 0, "s:");
              LCD_Write_String(2, 1, wifi_ssid);
              LCD_Write_String(3, 0, "p:");
              LCD_Write_String(3, 1, wifi_password);
              LCD_Set_XY(4, 1);
              Write_continuity(wifi_config_flag_addr, 1, "e");
              // Write_continuity(wifi_ssid_addr,wifi_ssid_len,wifi_ssid);
              // Delay1ms(1000);
              // Write_continuity(wifi_password_addr,wifi_password_len,wifi_password);
              Delay1ms(20000);
              Clr_Scr();
              return;
            }
            wifi_password[j] = RX1_buffer[i];
            i++;
          }
        }
        wifi_ssid[j] = RX1_buffer[i];
        i++;
      }
    } else {
      for (i = 0; i < RX1count; i++) {
        if ((RX1_buffer[i] == ':') && (RX1_buffer[i - 2] == 'i')) {
          i++;
          break;
        }
      }
      for (j = 0; j < 128; j++) {
        if (RX1_buffer[i] == '\r') {
          j++;
          wifi_ssid[j] = '\0';
          for (; i < RX1count; i++) {
            if ((RX1_buffer[i] == ':') && (RX1_buffer[i - 2] == 'r')) {
              i++;
              break;
            }
          }
          for (j = 0; j < 128; j++) {
            if (RX1_buffer[i] == '\r') {
              j++;
              i++;
              wifi_password[j] = '\0';
              for (i = 0; i < 128; i++) {
                if (wifi_password[i] == '\0') {
                  wifi_password_len = i + 1;
                  break;
                }
              }
              for (i = 0; i < 128; i++) {
                if (wifi_ssid[i] == '\0') {
                  wifi_ssid_len = i + 1;
                  break;
                }
              }
              Clr_Scr();
              LCD_Write_String(1, 2, "配网成功");
              LCD_Write_String(2, 0, "s:");
              LCD_Write_String(2, 1, wifi_ssid);
              LCD_Write_String(3, 0, "p:");
              LCD_Write_String(3, 1, wifi_password);
              LCD_Set_XY(4, 1);
              Write_continuity(wifi_config_flag_addr, 1, "e");
              // Write_continuity(wifi_ssid_addr,wifi_ssid_len,wifi_ssid);
              // Delay1ms(1000);
              // Write_continuity(wifi_password_addr,wifi_password_len,wifi_password);
              Delay1ms(20000);
              Clr_Scr();
              return;
            }
            wifi_password[j] = RX1_buffer[i];
            i++;
          }
        }
        wifi_ssid[j] = RX1_buffer[i];
        i++;
      }
    }
  }
}

#endif

#ifdef HARDWARE_V0
void NET_ConfigurationTask(void) {
  uint8_t i, j;
  while (1) {
    Clr_Scr();
    LCD_Write_String(1, 2, "loading");
    WIFIEN();      // 使能
    WIFIRSTOFF();  // 从低到高重启
    Delay1ms(500);
    WIFIRSTON();  // 从低到高重启
    Delay1ms(5000);
    UART3_SendString("AT+CWMODE=1\r\n");
    Delay1ms(500);
    UART3_SendString("AT+CWSTARTSMART=3\r\n");
    Delay1ms(1000);
    LCD_Write_String(1, 2, "配网模式");
    uart1_rx_status = 0;
    RX3count = 0;
    while (uart1_rx_status != 2);
    for (i = 0; i < RX3count; i++) {
      if ((RX3_buffer[i] == ':') && (RX3_buffer[i + 1] == 'A')) {
        break;
      }
    }
    if (i < RX3count) {
      uart1_rx_status = 0;
      RX3count = 0;
      while (uart1_rx_status != 2);
      for (i = 0; i < RX3count; i++) {
        if ((RX3_buffer[i] == ':') && (RX3_buffer[i - 2] == 'i')) {
          i++;
          break;
        }
      }
      for (j = 0; j < 128; j++) {
        if (RX3_buffer[i] == '\r') {
          j++;
          wifi_ssid[j] = '\0';
          for (; i < RX3count; i++) {
            if ((RX3_buffer[i] == ':') && (RX3_buffer[i - 2] == 'r')) {
              i++;
              break;
            }
          }
          for (j = 0; j < 128; j++) {
            if (RX3_buffer[i] == '\r') {
              j++;
              i++;
              wifi_password[j] = '\0';
              for (i = 0; i < 128; i++) {
                if (wifi_password[i] == '\0') {
                  wifi_password_len = i + 1;
                  break;
                }
              }
              for (i = 0; i < 128; i++) {
                if (wifi_ssid[i] == '\0') {
                  wifi_ssid_len = i + 1;
                  break;
                }
              }
              Clr_Scr();
              LCD_Write_String(1, 2, "配网成功");
              LCD_Write_String(2, 0, "s:");
              LCD_Write_String(2, 1, wifi_ssid);
              LCD_Write_String(3, 0, "p:");
              LCD_Write_String(3, 1, wifi_password);
              LCD_Set_XY(4, 1);
              Write_continuity(wifi_config_flag_addr, 1, "e");
              // Write_continuity(wifi_ssid_addr,wifi_ssid_len,wifi_ssid);
              // Delay1ms(1000);
              // Write_continuity(wifi_password_addr,wifi_password_len,wifi_password);
              Delay1ms(10000);
              Clr_Scr();
              return;
            }
            wifi_password[j] = RX3_buffer[i];
            i++;
          }
        }
        wifi_ssid[j] = RX3_buffer[i];
        i++;
      }
    }
  }
}

#endif
#ifdef HARDWARE_V2
void NET_ConfigurationTask(void) {
  uint8_t i, j;
  while (1) {
    Clr_Scr();
    LCD_Write_String(1, 2, "loading");
    WIFIEN();      // 使能
    WIFIRSTOFF();  // 从低到高重启
    Delay1ms(500);
    WIFIRSTON();  // 从低到高重启
    Delay1ms(5000);
    UART2_SendString("AT+CWMODE=1\r\n");
    Delay1ms(500);
    UART2_SendString("AT+CWSTARTSMART=3\r\n");
    Delay1ms(1000);
    LCD_Write_String(1, 2, "配网模式");
    uart1_rx_status = 0;
    RX2count = 0;
    while (uart1_rx_status != 2);
    for (i = 0; i < RX2count; i++) {
      if ((RX2_buffer[i] == ':') && (RX2_buffer[i + 1] == 'A')) {
        break;
      }
    }
    if (i < RX2count) {
      uart1_rx_status = 0;
      RX2count = 0;
      while (uart1_rx_status != 2);
      for (i = 0; i < RX2count; i++) {
        if ((RX2_buffer[i] == ':') && (RX2_buffer[i - 2] == 'i')) {
          i++;
          break;
        }
      }
      for (j = 0; j < 128; j++) {
        if (RX2_buffer[i] == '\r') {
          j++;
          wifi_ssid[j] = '\0';
          for (; i < RX2count; i++) {
            if ((RX2_buffer[i] == ':') && (RX2_buffer[i - 2] == 'r')) {
              i++;
              break;
            }
          }
          for (j = 0; j < 128; j++) {
            if (RX2_buffer[i] == '\r') {
              j++;
              i++;
              wifi_password[j] = '\0';
              for (i = 0; i < 128; i++) {
                if (wifi_password[i] == '\0') {
                  wifi_password_len = i + 1;
                  break;
                }
              }
              for (i = 0; i < 128; i++) {
                if (wifi_ssid[i] == '\0') {
                  wifi_ssid_len = i + 1;
                  break;
                }
              }
              Clr_Scr();
              LCD_Write_String(1, 2, "配网成功");
              LCD_Write_String(2, 0, "s:");
              LCD_Write_String(2, 1, wifi_ssid);
              LCD_Write_String(3, 0, "p:");
              LCD_Write_String(3, 1, wifi_password);
              LCD_Set_XY(4, 1);
              Write_continuity(wifi_config_flag_addr, 1, "e");
              // Write_continuity(wifi_ssid_addr,wifi_ssid_len,wifi_ssid);
              // Delay1ms(1000);
              // Write_continuity(wifi_password_addr,wifi_password_len,wifi_password);
              Delay1ms(10000);
              Clr_Scr();
              return;
            }
            wifi_password[j] = RX2_buffer[i];
            i++;
          }
        }
        wifi_ssid[j] = RX2_buffer[i];
        i++;
      }
    }
  }
}

#endif
