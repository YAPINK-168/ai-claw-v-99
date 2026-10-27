#ifdef HARDWARE_V2

#include "irq_hv2.h"

#include <string.h>

#include "basic.h"
#include "bsp.h"
#include "define.h"
#include "extern.h"
#include "lcd.h"
#include "rc04v.h"
#include "serial_app.h"
#include "software_it.h"

extern SERIAL_CoinInfoTypeDef coin_info;
extern uint8_t control_mode;
extern uint8_t g_serial_sn;
extern volatile uint32_t g_sys_tick_count;
extern uint8_t free_play_num;
extern uint8_t free_mode_flag;

float leftrightspeed_f = 0;
u8 Time_100ms_cnt = 0;
u8 readcardbusy = 0;
u8 readcardonly = 0;
u8 coininening = 0;
u8 readcardcount = 0;
u8 readtime = 0;
u8 loselockdelay = 0;
u16 clawlosttime = 0;
u16 timeled = 0;
u8 setlongkeytime = 0;
u16 downdelay = 0;
u8 Time2_trup_cnt = 0;
u8 Time1_trup_cnt = 0;
u16 right_left_point = 0;
u16 front_back_point = 0;
u8 setflag = 0;
u8 inquirebillflag = 0;
u8 inquirecoininflag = 0;
u8 inquireallcoinflag = 0;
u8 inquiresuppriseflag = 0;
u16 inquiresetflagl = 0;
u16 inquiresetflagh = 0;
u16 swingpulltime = 0;
u16 flashled = 0;
__IO u8 clawlosttime_flag = 0;

float test_downtime = 0;

char GsmCq[6] = {"0000\0\0"};
u8 GsmCqconut = 0;

u16 downtime_select = 0;

u16 clawtime = 0;
// u8  upspeed =7;
// u8  downspeed =4;
u16 swingtime = 100;
u16 pulltime = 0;
u16 swingpullflag = 0;
u16 updata_flag[2] = {0};

u16 Crane_delay_front_cnt1 = 0;
u16 Crane_delay_back_cnt1 = 0;
u16 Crane_delay_right_cnt1 = 0;
u16 Crane_delay_left_cnt1 = 0;
u16 Crane_delay_front_cnt2 = 0;
u16 Crane_delay_back_cnt2 = 0;
u16 Crane_delay_right_cnt2 = 0;
u16 Crane_delay_left_cnt2 = 0;

u16 secondclaw_time = 0;
u8 secondclaw_rise_flag = 0;

u8 tim2_down_protection_flag = 0;
int tim2_down_protection_cnt = 0;
u8 tim2_up_protection_flag = 0;
int tim2_up_protection_cnt = 0;
u8 tim2_back_protection_flag = 0;
int tim2_back_protection_cnt = 0;
u8 tim2_backup_protection_flag = 0;
int tim2_backup_protection_cnt = 0;
u8 breakdown = 0;
u8 winflag_tim = 0;

extern u8 gsmcoindatabuff[63];
u8 coin_sign_flag = 0;

// void USART1_IRQHandler(void) {
//   if (USART_GetITStatus(USART1, USART_IT_RXNE) != RESET) {
//     USART_ClearITPendingBit(USART1, USART_IT_RXNE);
//   }
//   if (USART_GetITStatus(USART1, USART_IT_TC) != RESET)  // ???????????????
//   {
//     USART_ClearITPendingBit(USART1, USART_IT_TC);  // ????????????????
//   }
//   // combusy=0;
// }

void RecGsm(void)  // ????????????????????????????????, ???????????????????????
{
  u16 temp = 0;
  //	u8 tmp[20];
  //	u8 datatempbuff6[7]={"000000"};//????
  u8 datatempbuff2[4] = {"00\0"};  // ????
  u16 datatemp = 0;
  // ?????????wifi??????

  if (RX2_buffer[5] == 'P' && RX2_buffer[6] == ':' && RX2_buffer[11] == 'S' && RX2_buffer[12] == 'Q' && RX2_buffer[14] == 'W')  //+CWLAP:(3,"TP-Li",-28,"86:8e:91:33:38:64",1,13,0)
  {
    GsmCq[1] = RX2_buffer[19];  // ????????
    GsmCq[2] = RX2_buffer[20];
    GsmCq[3] = '\0';
    GsmCqconut = ((GsmCq[1] - 0x30) * 10) + (GsmCq[2] - 0x30);  // ?????????
    // if(GsmCqconut<1||GsmCqconut>32)GsmCqconut=1;
    RX2count = 0;
  }
  // ??????????????[r|00001|00|000]
  if (RX2_buffer[0] == '[' && RX2_buffer[1] == 'r' && RX2_buffer[RX2count - 1] == ']')  // ???????+QIURC: "recv",0,4  1111
  {
    neton = 0;
    off_line_time = 0;
    reconnect = 0;
    connecting = 0;
    RX2count = 0;
  }
  // ?????????????[c|?????(5??)|????4???|?????2??|8???????|???]  [e|00001|5|28|00000000|0000000000000000000000000000000000000]
  if (RX2_buffer[0] == '[' && RX2_buffer[1] == 'e' && RX2_buffer[3] == machineidcode[0] && RX2_buffer[4] == machineidcode[1] && RX2_buffer[5] == machineidcode[2] &&
      ((RX2_buffer[6] == machineidcode[3] && RX2_buffer[7] == machineidcode[4]) || (RX2_buffer[6] == '9' && RX2_buffer[7] == '9')) && RX2_buffer[9] == '4' &&
      RX2_buffer[RX2count - 1] == ']')  // ???????+QIURC: "recv",0,4  1111
  {
    mymemecyup(RX2_buffer, gsmcoindatabuff, 56, 5);
    mymemecyup(gsmcoindatabuff, RX2_buffer, 3, 5);
    mymemecyup(gsmcoindatabuff, RX2_buffer, 11, 2);
    mymemecyup(gsmcoindatabuff, RX2_buffer, 14, 8);
    Add_md5_keymark_coin(gsmcoindatabuff);

    if (strcmp((const char *)gsmcoindatabuff, (const char *)RX2_buffer) == 0) {
      temp = mymemext1(RX2_buffer, datatempbuff2, '|', '|', 3, 80);
      if (chr2hex(datatempbuff2[0]) * 10 + chr2hex(datatempbuff2[1]) == 0)
        coinin = 0;
      else
        coinin += chr2hex(datatempbuff2[0]) * 10 + chr2hex(datatempbuff2[1]);  // ????0???????????

      // LCD_Set_XY(2,0);
      // LCD_Write_Number(10);
      // LCD_Write_Number((coinin/coinbase)/10);
      // LCD_Write_Number((coinin/coinbase)%10);

      // LCD_Set_XY(4,2);
      // LCD_Write_Number(coinin/10);
      // LCD_Write_Number(coinin%10);

      buf22[0] = hex2chr(coinin / 10);
      buf22[1] = hex2chr(coinin % 10);
      Write_continuity(coininaddr, coininlen, buf22);

      coin_sign_flag = 1;
    }
    memset(RX2_buffer, 0, sizeof(RX2_buffer));
    RX2count = 0;
  }
  // ??????????????[c|?????(5??)|????5???|00?????01??????02??????|8???????|???]
  if (RX2_buffer[0] == '[' && RX2_buffer[1] == 'c' && RX2_buffer[3] == machineidcode[0] && RX2_buffer[4] == machineidcode[1] && RX2_buffer[5] == machineidcode[2] &&
      ((RX2_buffer[6] == machineidcode[3] && RX2_buffer[7] == machineidcode[4]) || (RX2_buffer[6] == '9' && RX2_buffer[7] == '9')) && RX2_buffer[9] == '5' &&
      RX2_buffer[RX2count - 1] == ']')  // ???????+QIURC: "recv",0,4  1111
  {
    temp = mymemext1(RX2_buffer, datatempbuff2, '|', '|', 3, 80);
    machinedisable = chr2hex(datatempbuff2[1]) * 10 + chr2hex(datatempbuff2[0]);  //
    RX2count = 0;
  }
  // ????????????[q|?????(5??)|????1??????|???1????????????2????????????3?????????????4????????????|8???????|???]#$-$#
  // ????   [g|00001|1|01|12345678|sign]#$-$#   //???????00001?????
  // ???   [g|00001|1|01|000020|12345678|sign]#$-$#   //????00001????????20??   ---000020??????6bit
  else if (RX2_buffer[0] == '[' && RX2_buffer[1] == 'g' && RX2_buffer[3] == machineidcode[0] && RX2_buffer[4] == machineidcode[1] && RX2_buffer[5] == machineidcode[2] &&
           ((RX2_buffer[6] == machineidcode[3] && RX2_buffer[7] == machineidcode[4]) || (RX2_buffer[6] == '9' && RX2_buffer[7] == '9')) && RX2_buffer[9] == '1' &&
           RX2_buffer[RX2count - 1] == ']')  // ?????????[a|00001|0000000001]
  {
    // u8  coinin;            //?????           1
    // u16 surprisecount;     //???????         2
    // u16 allcoin;           //??????         3
    // uu16 alltoy;           //????????       4
    switch (RX2_buffer[12]) {
      case '1': {
        inquirecoininflag = 1;
      } break;
      case '2':
        inquiresuppriseflag = 1;
        break;
      case '3':
        inquireallcoinflag = 1;
        break;
      case '4':
        inquirebillflag = 1;
        break;
      default:
        break;
    }
    RX2count = 0;
  }
  // ???????????????????[q|?????(5??)|????2???????|???2??1-99??????????????|?????5??|8???????|???]#$-$#
  // ????   [q|00001|2|01|12345678|sign]#$-$#          //?????????????
  // ???   [q|00001|2|01|000002|12345678|sign]#$-$#   //???????00001???2???????   ---000002??????6bit
  else if (RX2_buffer[0] == '[' && RX2_buffer[1] == 'q' && RX2_buffer[3] == machineidcode[0] && RX2_buffer[4] == machineidcode[1] && RX2_buffer[5] == machineidcode[2] &&
           ((RX2_buffer[6] == machineidcode[3] && RX2_buffer[7] == machineidcode[4]) || (RX2_buffer[6] == '9' && RX2_buffer[7] == '9')) && RX2_buffer[9] == '2' &&
           RX2_buffer[RX2count - 1] == ']')  // ?????????[a|00001|0000000001]
  {
    //		inquiresetflag=0x10;
    temp = mymemext1(RX2_buffer, datatempbuff2, '|', '|', 3, 80);
    datatemp = chr2hex(datatempbuff2[0]) * 10 + chr2hex(datatempbuff2[1]);
    if (datatemp > 0) datatemp--;
    if (datatemp <= 15)
      inquiresetflagl = inquiresetflagl | (0x01 << datatemp);
    else {
      datatemp = datatemp - 15;
      inquiresetflagh = inquiresetflagh | (0x01 << datatemp);
    }
    RX2count = 0;
  }
  // ????????????????[s|?????(5??)|????3????????|???1-99??????????????|?????6??|8???????|???]#$-$#
  // ????   [s|00001|3|01|000002|12345678|sign]#$-$#
  // ???   [s|00001|3|01|000002|12345678|sign]#$-$#
  else if (RX2_buffer[0] == '[' && RX2_buffer[1] == 's' && RX2_buffer[3] == machineidcode[0] && RX2_buffer[4] == machineidcode[1] && RX2_buffer[5] == machineidcode[2] &&
           ((RX2_buffer[6] == machineidcode[3] && RX2_buffer[7] == machineidcode[4]) || (RX2_buffer[6] == '9' && RX2_buffer[7] == '9')) && RX2_buffer[9] == '3' &&
           RX2_buffer[RX2count - 1] == ']') {
    setflag = 1;
    //		temp = mymemext1(RX2_buffer,datatempbuff2,'|','|',4,80);
    //		datatemp =datatempbuff2[1]*10+datatempbuff2[0];
    //		setflag=setflag|(0x01<<datatemp);
    if (RX2_buffer[11] == '0') {
      switch (RX2_buffer[12]) {
        case '1': {
          mymemecyl(RX2_buffer, coinbasebuff, 18, 2);  // ???coinbasebuff
        } break;
        case '2': {
          mymemecyl(RX2_buffer, roundbasebuff, 18, 2);  // ???roundbasebuff
        } break;
        case '3':
          mymemecyl(RX2_buffer, lostclawbuff, 18, 2);  // ???lostclawbuff
          break;
        case '4':
          mymemecyl(RX2_buffer, groundstongclawbuff, 18, 2);  // ???groundstongclawbuff
          break;
        case '5':
          mymemecyl(RX2_buffer, lightclawbuff, 18, 2);  // ???lightclawbuff
          break;
        case '6':
          mymemecyl(RX2_buffer, strongclawbuff, 18, 2);  // ???strongclawbuff
          break;
        case '7':
          mymemecyl(RX2_buffer, gametimebasebuff, 18, 2);  // ???gametimebasebuff
          break;
        case '8':
          mymemecyl(RX2_buffer, roundoffsetbuff, 18, 2);  // ???roundoffsetbuff
          break;
        case '9':
          mymemecyl(RX2_buffer, swingpullbuff, 18, 2);  // ???swingpullbuff
          break;
        default:
          break;
      }
    } else if (RX2_buffer[11] == '1') {
      switch (RX2_buffer[12]) {
        case '0': {
          mymemecyl(RX2_buffer, factarysetbuff, 18, 2);  // ???factarysetbuff
        } break;
        case '1':                                       //[s|00001|3|01|000002|12345678|sign]#$-$#
          mymemecyl(RX2_buffer, machineidbuff, 15, 5);  // ???machineidbuff
          break;
        case '2':
          mymemecyl(RX2_buffer, upspeedbuff, 18, 2);  // ???upspeedbuff
          break;
        case '3':
          mymemecyl(RX2_buffer, downspeedbuff, 18, 2);  // ???downspeedbuff
          break;
        case '4':
          mymemecyl(RX2_buffer, leftrightspeedbuff, 18, 2);  // ???leftrightspeedbuff
          break;
        case '5':
          mymemecyl(RX2_buffer, fixedpointbuff, 18, 2);  // ???fixedpointbuff
          break;
        case '6':
          mymemecyl(RX2_buffer, front_back_point_fixedpointbuff, 15, 5);  // ???front_back_point_fixedpointbuff
          break;
        case '7':
          mymemecyl(RX2_buffer, right_left_point_fixedpointbuff, 15, 5);  // ???right_left_point_fixedpointbuff
          break;
        case '8':
          mymemecyl(RX2_buffer, clawgetonesteptimebuff, 16, 4);  // ???clawgetonesteptimebuff
          break;
        case '9':
          mymemecyl(RX2_buffer, clawgettwosteptimebuff, 16, 4);  // ???clawgettwosteptimebuff
          break;
        default:
          break;
      }
    } else if (RX2_buffer[11] == '2')  // mymemecys(RX2_buffer,clawgetthreesteptimebuff,18,2);
    {
      switch (RX2_buffer[12]) {
        case '0': {
          mymemecyl(RX2_buffer, clawgetthreesteptimebuff, 16, 4);  // ???clawgetthreesteptimebuff
        } break;
        case '1': {
          mymemecyl(RX2_buffer, pulllengthbuff, 18, 2);  // ???clawgetthreesteptimebuff
        } break;
        case '2': {
          mymemecyl(RX2_buffer, outbasebuff, 16, 4);  // ???clawgetthreesteptimebuff
        } break;
        case '3': {
          mymemecyl(RX2_buffer, clampingnumbuff, 18, 2);  // ???clawgetthreesteptimebuff
        } break;
        case '4': {
          mymemecyl(RX2_buffer, uppulltimebuff, 18, 2);  // ???clawgetthreesteptimebuff
        } break;
        case '5': {
          mymemecyl(RX2_buffer, gamemodebuff, 18, 2);  // ???clawgetthreesteptimebuff
        } break;
        default:
          break;
      }
    }
    RX2count = 0;
  }
}
/////////////////????2?????4G???////////////////////////
void USART3_IRQHandler(void) {
  if (USART_GetFlagStatus(USART3, USART_FLAG_ORE) != RESET) {
    USART_ClearFlag(USART3, USART_FLAG_ORE);  // ??????????
  }
  if (USART_GetITStatus(USART3, USART_IT_RXNE) != RESET) {
    USART_ClearITPendingBit(USART3, USART_IT_RXNE);
    USART_ClearFlag(USART3, USART_FLAG_RXNE);
  }
}
/////////////////????2?????4G???////////////////////////
u8 uart1_rx_status = 0;
u16 uart1_rx_time = 0;
void USART2_IRQHandler(void) {
  u8 S2RxData = 0;  //
  combusy = 1;
  if (USART_GetFlagStatus(USART2, USART_FLAG_ORE) != RESET) {
    USART_ClearFlag(USART2, USART_FLAG_ORE);  // ??????????
  }
  if (USART_GetITStatus(USART2, USART_IT_RXNE) != RESET) {
    USART_ClearITPendingBit(USART2, USART_IT_RXNE);
    USART_ClearFlag(USART2, USART_FLAG_RXNE);
    uart1_rx_time = 100;
    uart1_rx_status = 1;
    S2RxData = USART_ReceiveData(USART2);
    USART2_Rx_time = 1;  //
    if (S2RxData == '+') RX2count = 0;
    if (S2RxData == '[') {
      RX2count = 0;
    }
    RX2_buffer[RX2count++] = S2RxData;
    if (RX2count > 200) {
      reszer = 0;     // ??????
      coininen = 0;   // ??????
      userpayed = 0;  // ??????
      userscan = 0;   // ??????
      resqr = 0;      // ????????
      RX2count = 0;
    }

    if (S2RxData == ']') {
      RecGsm();  // ??????????
    }
    if (S2RxData == ')') {
      RecGsm();  // ??????????
    } else if (RX2count > 200) {
      RX2count = 0;
    }
  }
  if (USART_GetITStatus(USART2, USART_IT_TC) != RESET)  // ???????????????
  {
    USART_ClearITPendingBit(USART2, USART_IT_TC);  // ????????????????
  }
  combusy = 0;
}

///////////////????3????/////////////////////
// 500300010002984A
// ??????1  ??????1  ???????????2   ?????????2  crc????   crc????
// void USART3_IRQHandler(void)
//{
//	u8 S3RxData=0;//
//	vu32 USART3_SR_temp=0;
//	USART3_SR_temp=USART3->SR;
//    if (USART_GetFlagStatus(USART3, USART_FLAG_ORE) != RESET)
//    {
//		 USART_ClearFlag(USART3, USART_FLAG_ORE);
//        USART_ReceiveData(USART3);
//    }
//    if(USART_GetITStatus(USART3, USART_IT_RXNE) != RESET)
//    {
//			USART_ClearITPendingBit(USART3, USART_IT_RXNE);
//         USART_ClearFlag(USART3, USART_FLAG_RXNE);
//			S3RxData=USART_ReceiveData(USART3);
//		}
//	 		if(RX3count>100)
//			{
//				RX3count=0;
//			}
//		if(USART_GetITStatus(USART3, USART_IT_TC) != RESET)	// ???????????????
//     {
//		USART_ClearITPendingBit(USART3, USART_IT_TC); 	// ????????????????
//     }
// }

void TIM1_CC_IRQHandler(void)  // 100us
{
  //	u8 temp=0;
  if (TIM_GetITStatus(TIM1, TIM_IT_CC1) == SET)  //
  {
    TIM_ClearITPendingBit(TIM1, TIM_IT_CC1);  //
    TIM_SetCounter(TIM1, 0x0000);             //
    Time1_trup_cnt++;
    if (Time1_trup_cnt > 100) Time1_trup_cnt = 1;
    Time1_1s_cnt++;
    if (Time1_1s_cnt >= 10000) {
      Time1_1s_cnt = 0;
      Second1++;
      if (Second1 > 100) Second1 = 0;
    }
    // ??????????????????????
    if (setfinishing == 1) {
      if (ENTERKEY() == 0) {
        if (setcursor == 4) {
          if (Time1_trup_cnt <= groundstongclaw) {  // ??????????????,6?????????
            CLAWON();
          } else {
            CLAWOFF();
          }
        } else if (setcursor == 5) {
          if (Time1_trup_cnt <= strongclaw) {  // ??????????????,6?????????
            CLAWON();
          } else {
            CLAWOFF();
          }
        } else if (setcursor == 6) {
          if (Time1_trup_cnt <= lightclaw) {  // ??????????????,6?????????
            CLAWON();
          } else {
            CLAWOFF();
          }
        } else {
          CLAWOFF();
        }
        if (setcursor == 1) {
          DOWNRUN();
        }
        //			  else
        //					DOWNSTOP();
        if (setcursor == 2) {
          UPRUN();
        }
        //				else
        //					UPSTOP();

        if (setcursor == 26) {
          if (FRONTSW() == 0) {
            FRONTSTOP();  // ????
          } else {
            if (Time1_trup_cnt <= leftrightspeed) {
              FRONTRUN();
            } else {
              FRONTSTOP();
            }
          }
        }
        if (setcursor == 27) {
          if (BACKSW() == 0) {
            BACKSTOP();  // ????
          } else {
            if (Time1_trup_cnt <= leftrightspeed) {
              BACKRUN();
            } else {
              BACKSTOP();
            }
          }
        }

        if (setcursor == 28) {
          if (LEFTSW() == 0) {
            LEFTSTOP();  // ?????
          } else {
            if (Time1_trup_cnt <= leftrightspeed) {
              LEFTRUN();
            } else {
              LEFTSTOP();
            }
          }
        }
        if (setcursor == 29) {
          if (Time1_trup_cnt <= leftrightspeed) {
            RIGHTRUN();
          } else {
            RIGHTSTOP();
          }
        }
      } else {
        CLAWOFF();
        UPSTOP();
        DOWNSTOP();
        BACKSTOP();
        FRONTSTOP();
        RIGHTSTOP();
        LEFTSTOP();
      }
    }
    // ?????????????
    if (beginning == 2 || fixedpointing >= 1) {
      if (GAMEINGFLAG == 0) GAMEINGFLAG = 1;
      // ??????????
      if (BACKSW() == 0)  //
      {
        BACKSTOP();  // ?????
      }
      if (FRONTSW() == 0) {
        FRONTSTOP();
      }
      if (DOWNSW() == 1) {
        UPSTOP();
      }
      if (GROUNDSW() == 1) {
        DOWNSTOP();
      }
    }
    // ???  ??????????
    if (beginning == 2 || fixedpointing == 1) {
      if (RIGHTKEY() == 0 && LEFTKEY() != 0)  // ????
      {
        LEFTSTOP();
        //////////////////////////////20250106 1.7.1??????????????????????Bug
        Crane_delay_left_cnt1 = 0;
        Crane_delay_left_cnt2 = 0;
        //////////////////////////////
        if (Crane_delay_right_cnt1 < Crane_delay * 10) {
          Crane_delay_right_cnt1++;
          Crane_delay_right_cnt2++;
        }
        if (Crane_delay_right_cnt2 >= Crane_delay * 10) {
          if (Time1_trup_cnt <= leftrightspeed) {
            RIGHTRUN();
          } else {
            RIGHTSTOP();
          }
        } else {
          RIGHTSTOP();  // ???
        }
      } else {
        if (Crane_delay_right_cnt2 < Crane_delay * 10) {
          Crane_delay_right_cnt2++;
        }
        if (Crane_delay_right_cnt2 >= Crane_delay * 10 && Crane_delay_right_cnt1 > 0) {
          Crane_delay_right_cnt1--;
          if (Time1_trup_cnt <= leftrightspeed) {
            RIGHTRUN();
          } else {
            RIGHTSTOP();
          }
        } else if (Crane_delay_right_cnt1 == 0) {
          Crane_delay_right_cnt2 = 0;
          RIGHTSTOP();  // ???
        }
      }
      if (LEFTKEY() == 0 && RIGHTKEY() != 0) {
        RIGHTSTOP();
        //////////////////////////////20250106 1.7.1??????????????????????Bug
        Crane_delay_right_cnt1 = 0;
        Crane_delay_right_cnt2 = 0;
        //////////////////////////////
        if (Crane_delay_left_cnt1 < Crane_delay * 10) {
          Crane_delay_left_cnt1++;
          Crane_delay_left_cnt2++;
        }
        if (Crane_delay_left_cnt2 >= Crane_delay * 10) {
          if (LEFTSW() == 0) {
            LEFTSTOP();  // ?????
            //						right_left_point =0;
          } else {
            if (Time1_trup_cnt <= leftrightspeed) {
              LEFTRUN();
            } else {
              LEFTSTOP();
            }
          }
        }
      } else {
        if (Crane_delay_left_cnt2 < Crane_delay * 10) {
          Crane_delay_left_cnt2++;
        }
        if (Crane_delay_left_cnt2 >= Crane_delay * 10 && Crane_delay_left_cnt1 > 0) {
          Crane_delay_left_cnt1--;
          if (LEFTSW() == 0) {
            LEFTSTOP();  // ?????
            //						right_left_point =0;
          } else {
            if (Time1_trup_cnt <= leftrightspeed) {
              LEFTRUN();
            } else {
              LEFTSTOP();
            }
          }
        } else if (Crane_delay_left_cnt1 == 0) {
          Crane_delay_left_cnt2 = 0;
          LEFTSTOP();  // ???
        }
      }
    }
    if (beginning == 2 || fixedpointing == 2) {
      if (BACKKEY() == 0 && FRONTKEY() != 0) {
        FRONTSTOP();
        //////////////////////////////20250106 1.7.1??????????????????????Bug
        Crane_delay_front_cnt1 = 0;
        Crane_delay_front_cnt2 = 0;
        //////////////////////////////
        if (Crane_delay_back_cnt1 < Crane_delay * 10) {
          Crane_delay_back_cnt1++;
          Crane_delay_back_cnt2++;
        }
        if (Crane_delay_back_cnt2 >= Crane_delay * 10) {
          if (BACKSW() == 0) {
            BACKSTOP();  // ????
            // front_back_point =0;
          } else {
            if (front_back_point < 50000) front_back_point++;
            if (Time1_trup_cnt <= leftrightspeed) {
              BACKRUN();
            } else {
              BACKSTOP();
            }
          }
        }
      } else {
        if (Crane_delay_back_cnt2 < Crane_delay * 10) {
          Crane_delay_back_cnt2++;
        }
        if (Crane_delay_back_cnt2 >= Crane_delay * 10 && Crane_delay_back_cnt1 > 0) {
          Crane_delay_back_cnt1--;
          if (BACKSW() == 0) {
            BACKSTOP();  // ????
            // front_back_point =0;
          } else {
            if (front_back_point < 50000) front_back_point++;
            if (Time1_trup_cnt <= leftrightspeed) {
              BACKRUN();
            } else {
              BACKSTOP();
            }
          }
        } else if (Crane_delay_back_cnt1 == 0) {
          Crane_delay_back_cnt2 = 0;
          BACKSTOP();
        }
      }
      if (FRONTKEY() == 0 && BACKKEY() != 0)  // ?????
      {
        BACKSTOP();
        //////////////////////////////20250106 1.7.1??????????????????????Bug
        Crane_delay_back_cnt1 = 0;
        Crane_delay_back_cnt2 = 0;
        //////////////////////////////
        if (Crane_delay_front_cnt1 < Crane_delay * 10) {
          Crane_delay_front_cnt1++;
          Crane_delay_front_cnt2++;
        }
        if (Crane_delay_front_cnt2 >= Crane_delay * 10) {
          if (FRONTSW() == 0) {
            FRONTSTOP();  // ?????
            front_back_point = 0;
          } else {
            if (front_back_point > 0) front_back_point--;
            if (Time1_trup_cnt <= leftrightspeed) {
              FRONTRUN();
            } else {
              FRONTSTOP();
            }
          }
        }
      } else {
        if (Crane_delay_front_cnt2 < Crane_delay * 10) {
          Crane_delay_front_cnt2++;
        }
        if (Crane_delay_front_cnt2 >= Crane_delay * 10 && Crane_delay_front_cnt1 > 0) {
          Crane_delay_front_cnt1--;
          if (FRONTSW() == 0) {
            FRONTSTOP();  // ?????
            front_back_point = 0;
          } else {
            if (front_back_point > 0) front_back_point--;
            if (Time1_trup_cnt <= leftrightspeed) {
              FRONTRUN();
            } else {
              FRONTSTOP();
            }
          }
        } else if (Crane_delay_front_cnt1 == 0) {
          Crane_delay_front_cnt2 = 0;
          FRONTSTOP();  // ?
        }
      }
    }
    // ????
    if (((gamestatus == 3 || gamestatus == 4 || gamestatus == 5) && beginning == 5) && breakdown == 0) {
      if (Time1_trup_cnt <= claw) {  // ??????????????,6?????????  1-100??
        CLAWON();
        MACHINE_EventPostOnce(MECH_EVT_CLAW_CATCH);
      }  // ?
      else {
        CLAWOFF();
      }
    } else if (breakdown > 0) {
      CLAWOFF();
      FRONTSTOP();  // ?????????????????????
      BACKSTOP();
      LEFTSTOP();   // ?????
      RIGHTSTOP();  // ???
    }

    if (gamestatus == 1 && beginning < 4) {
      if (enterkeyvalue == 1 || gametime == 0)  // ??????????????????
      {
        enterkeyvalue = 0;
        if (free_play_num > 0) {
          free_mode_flag = 1;
          free_play_num--;
          SERIAL_SendFreeNum(free_play_num);
          LCD_Write_String(3, 2, "Free:");
          LCD_Set_XY(3, 5);
          LCD_Write_Number(free_play_num / 10);
          LCD_Write_Number(free_play_num % 10);
        }
        //				swingpull = 1;
        if (swingpull == 0)  // ?????????????
        {
          gamestatus = 2;  // ?????????????????????2
        } else
          swingpulltime = 1;
        //				gamestatus=2;
        //				downtime_select = downtimeset;
        //				swingpulltime =1;
        beginning = 3;  // ????????????
        FRONTSTOP();    // ?????????????????????
        BACKSTOP();
        LEFTSTOP();   // ?????
        RIGHTSTOP();  // ???
        beginning = 4;
        MACHINE_EventPostOnce(MECH_EVT_GRAB_START);
      }
    }
  }
}
///////////////////1ms????////////////////////////
u16 get_rssi_time = 52000;
u8 rssi_display = 0;
u32 display_refresh_time = 300000;
u32 display_display_time = 5000;
u16 wait_time;
void TIM2_IRQHandler(void) {
  TIM2_SR &= 0xFFFFFFFE;
  CycleTask_Isr();
  if (wait_time) {
    wait_time--;
  }

  if (uart1_rx_time) {
    uart1_rx_time--;
  } else {
    if (uart1_rx_status == 1) {
      uart1_rx_status = 2;
    }
  }

  if (g_sys_tick_count > 20000) {
    if (!GPIO_ReadInputDataBit(GPIOE, GPIO_Pin_4)) {
      LED4ON();
    } else {
      LED4OFF();
    }
  } else {
    LED4OFF();
  }

  if (get_rssi_time) {
    get_rssi_time--;
  }
  if (display_refresh_time) {
    display_refresh_time--;
  }
  if (display_display_time) {
    display_display_time--;
  }
  Time2_trup_cnt++;
  if (Time2_trup_cnt > 10) {
    Time2_trup_cnt = 1;
    if (Time_10ms_cnt > 0) Time_10ms_cnt--;
  }
  if (tim2_down_protection_flag) {
    tim2_down_protection_cnt++;
    if (tim2_down_protection_cnt >= 10000) {
      tim2_down_protection_flag = 0;
      tim2_down_protection_cnt = 10000;
      breakdown = 1;
      CLAWOFF();
      UPSTOP();
      DOWNSTOP();
      FRONTSTOP();
      LEFTSTOP();  // ?????
    }
  }
  if (tim2_up_protection_flag) {
    tim2_up_protection_cnt++;
    if (tim2_up_protection_cnt >= 10000) {
      tim2_up_protection_flag = 0;
      tim2_up_protection_cnt = 10000;
      breakdown = 2;
      CLAWOFF();
      UPSTOP();
      DOWNSTOP();
      FRONTSTOP();
      LEFTSTOP();  // ?????
    }
  }
  if (tim2_back_protection_flag) {
    tim2_back_protection_cnt++;
    if (tim2_back_protection_cnt >= 8000) {
      tim2_back_protection_flag = 0;
      tim2_back_protection_cnt = 8000;
      breakdown = 3;
      CLAWOFF();
      UPSTOP();
      DOWNSTOP();
      FRONTSTOP();
      LEFTSTOP();  // ?????
    }
  }
  if (tim2_backup_protection_flag) {
    tim2_backup_protection_cnt++;
    if (tim2_backup_protection_cnt >= 5000) {
      tim2_backup_protection_flag = 0;
      tim2_backup_protection_cnt = 5000;
      breakdown = 4;
      UPSTOP();
      DOWNSTOP();
      FRONTSTOP();
      LEFTSTOP();  // ?????
    }
  }
  Time_100ms_cnt++;
  //	if(Time_100ms_cnt>100)
  //	{
  //		Time_100ms_cnt=0;
  //		leftrightspeed_f =0;
  //	}
  //	if(leftrightspeed_f <= leftrightspeed && Time_100ms_cnt<=Crane_delay)
  //		leftrightspeed_f += ((float)leftrightspeed)/Crane_delay;

  if (pulllengthtime > 0 && beginning == 7 && downdelay >= 80) pulllengthtime--;
  Time2_1s_cnt++;
  if (clawlosttime > 0)  // ????????
    clawlosttime++;
  if (clawlosttime > 10000) clawlosttime = 0;
  if (downdelay > 0) downdelay++;
  if (downdelay > 2000) downdelay = 0;
  if (clawtime > 0) clawtime++;
  if (clawtime > 6000) clawtime = 6000;
  flashled++;
  if (flashled >= 300) {
    flashled = 0;
    Second3++;
    if (Second3 > 100) Second3 = 0;
  }
  if (Time2_1s_cnt >= 1000) {
    off_line_time++;
    if (winflag_tim > 1) {
      winflag_tim++;
      if (winflag_tim >= 6) winflag_tim = 0;
    }
    if (connecting > 0) connecting++;
    if (connecting > 200) connecting = 0;
    Time2_1s_cnt = 0;
    if (reconnect == 0) neton++;
    // ??????????
    if (neton > 90)  //&&link not
      neton = 90;
    if (Tick_ReqKeep_OnLine_time < 28)
      Tick_ReqKeep_OnLine_time++;
    else
      Tick_ReqKeep_OnLine_time = 0;
    if (gametime > 0) {
      gametime--;
      gametimeflash = 1;
    }
    if (gameruntime > 0) {
      gameruntime--;
    }
    if (M26delaytime > 0) M26delaytime--;
    if (USART1_Rx_time) USART1_Rx_time++;  // ?????????????
    if (USART1_Rx_time > 3)                // 100ms
    {
      M26netflay = 1;
      USART1_Rx_time = 0;  // ???????
    }
    if (USART3_Rx_time) USART3_Rx_time++;  // ?????????????
    if (USART3_Rx_time > 3)                // 100ms
    {
      M26netflay = 1;
      USART3_Rx_time = 0;  // ???????
    }
    Second2++;
    if (Second2 > 100) Second2 = 0;
    if (setlongkeytime > 0) setlongkeytime++;
    if (setlongkeytime > 10) setlongkeytime = 10;
  }
  if (swingpulltime > 0) swingpulltime++;
  // ??????????
  if (gametime == 0 && gameruntime == 0 && setfinishing == 0) {
    FRONTSTOP();  // ?????????????????????
    BACKSTOP();
    LEFTSTOP();   // ?????
    RIGHTSTOP();  // ???
    CLAWOFF();
  }

  if (setfinishing == 1) {
    if (ENTERKEY() == 0) {
      if (setcursor == 11) {
        if (DOWNSW() == 0 || test_downtime <= 0) {
          UPSTOP();
          test_downtime = 0;
        }

        else {
          test_downtime -= (((float)upspeed) / ((float)downspeed)) * 0.5;
          if (Time2_trup_cnt <= upspeed) {
            UPRUN();
          } else {
            UPSTOP();
          }
        }
      }

      if (setcursor == 12) {
        if (test_downtime >= downtimeset) {
          DOWNSTOP();
        }

        else {
          test_downtime++;
          if (Time2_trup_cnt <= downspeed) {
            DOWNRUN();
          } else {
            DOWNSTOP();
          }
        }
      }
    }
  }
  // ??????
  if (beginning >= 4) {
    if (CLAWDOWNFLAG == 0) 
			CLAWDOWNFLAG = 1;
    // ????
    if (swingpulltime > 0 && gamestatus <2) {
      if (swingpulltime < swingpull)  // ??????????????
      {
        UPRUN();
      } else if (swingpulltime > swingpull && swingpulltime < (swingpull + 20))  // ????????????swingpull*100
      {
        UPSTOP();
      } else if (swingpulltime > (swingpull + 150))  //
      {
        //				downtime_select = downtimeset;
        swingpulltime = 0;
        gamestatus = 2;
      }
    }
    if (gamestatus == 2 && breakdown == 0 && secondclaw_rise_flag == 0)  // ???????
    {
      tim2_down_protection_flag = 1;

      //			if(enterkeyvalue ==1&&downdelay==0 &&secondclaw ==1)
      //			{
      //				if(downtime+secondclaw_delay > downtimeset)
      //					downtime_select = downtimeset;
      //				else
      //					downtime_select = downtime+secondclaw_delay;
      //
      //				enterkeyvalue = 0;
      //			}
      if (tim2_down_protection_cnt < 50) {
        enterkeyvalue = 0;
      }

      if ((GROUNDSW() == 1) && OUTSENTOR() == 0 && downdelay == 0) {
        downtime++;
        if (Time2_trup_cnt <= downspeed) {
          DOWNRUN();
          MACHINE_EventPostOnce(MECH_EVT_CLAW_DOWN_START);
        } else {
          DOWNSTOP();
        }
        if (downtime > downtimeset)  // downtime_select)
        {
          downdelay = 1;
          DOWNSTOP();
          claw = groundstongclaw;
          //					downtime =0;
          //					gamestatus =3;//???????
          //					beginning =5;
          //					claw = groundstongclaw;
        }
      } else if (OUTSENTOR() == 1)  // ?????????????????????????
      {
        downtime = 0;
        DOWNSTOP();
        gamestatus = 3;  // ???????
        downdelay = 1;
        beginning = 5;
        claw = groundstongclaw;
        MACHINE_EventPostOnce(MECH_EVT_CLAW_DOWN);
      } else if (GROUNDSW() == 0 && downdelay == 0) {
        downdelay = 1;
        DOWNSTOP();
      }

      if (enterkeyvalue == 1 && downdelay == 0 && secondclaw == 1) {
        downtime = 0;
        downdelay = 1;
        DOWNSTOP();
        if (CLAWTOYFLAG == 0)  // ??????
          CLAWTOYFLAG = 1;
        secondclaw_rise_flag = 1;
        //				gamestatus =3;//???????
        beginning = 5;
        //				claw = groundstongclaw;
        enterkeyvalue = 0;
      }

      if (downdelay >= 50)  // ?????????????????
      {
        DOWNSTOP();
        if (CLAWTOYFLAG == 0)  // ??????
          CLAWTOYFLAG = 1;
        claw = groundstongclaw;
      }
      if (downdelay >= downdelayset)  // ??????
      {
        DOWNSTOP();
        downtime = 0;
        downdelay = 1;
        gamestatus = 3;  // ???????
        beginning = 5;
        claw = groundstongclaw;
        MACHINE_EventPostOnce(MECH_EVT_CLAW_DOWN);
      }
    }
    //		if(secondclaw == 1)
    //		{
    secondclaw_time = (80 > Rise_delay) ? 80 : Rise_delay;
    //		}
    if (secondclaw_rise_flag == 1 && breakdown == 0 && downdelay >= secondclaw_delay && secondclaw == 1) {
      claw = groundstongclaw;
      downdelay = 1;
      secondclaw_rise_flag = 0;
      gamestatus = 3;
      MACHINE_EventPostOnce(MECH_EVT_CLAW_DOWN);
    }
    // ???????
    if (gamestatus == 3 && breakdown == 0 && downdelay >= secondclaw_time) {
      downdelay = secondclaw_time;
      //		if(gamestatus ==3 && breakdown == 0 && downdelay >= 80)
      //		{
      //			downdelay = 80;
      tim2_down_protection_flag = 0;
      tim2_down_protection_cnt = 0;
      tim2_up_protection_flag = 1;
      if (CLAWUPFLAG == 0)  // ??????
      {
        CLAWUPFLAG = 1;
        clawtime = 1;
      }

      // ???????????????
      //			if(clawtime< clawgetonesteptime)
      //			{
      //				claw =groundstongclaw;//??
      //			}
      //			else//???????????????????
      //			{
      //				if(fixedpoint==0||(fixedpoint==1&&(right_left_point<right_left_point_fixedpoint&&front_back_point<front_back_point_fixedpoint)))
      //				{
      //					if(roundnum[roundround-1]==1)
      //							claw =clawpower[0];//??,????
      //					else if(clawtime<clawgettwosteptime)
      //							claw =clawpower[0]-clawtime*clawpower[4]/clawgettwosteptime;//(strongclaw-lightclaw);		//???????
      //				}
      //				//????????
      //				if(fixedpoint==1&&(right_left_point<right_left_point_fixedpoint||front_back_point<front_back_point_fixedpoint))
      //				{
      //					if(clawtime<clawgettwosteptime)
      //						claw =clawpower[0]-clawtime*clawpower[4]/clawgettwosteptime;//(strongclaw-lightclaw);		//???????
      //				}
      //				else if(fixedpoint==1&&(right_left_point>right_left_point_fixedpoint||front_back_point>front_back_point_fixedpoint))
      //					claw =clawpower[0];//??,????
      //			}

      // ????????
      if (DOWNSW() == 1) {
        if (outcount < outbase + clampingnum && outcount >= outbase && gamemode == 1)  // ????
          claw = groundstongclaw;                                                      // ????????????
        else if (roundnum[roundround - 1] == 1 && gamemode == 2)                       // ???
          claw = groundstongclaw;                                                      // ????
        else {
          if (clawtime < clawgetonesteptime)                                                              // 1----500
            claw = groundstongclaw;                                                                       // ??
          if ((clawtime > clawgetonesteptime) && (clawtime < (clawgettwosteptime + clawgetonesteptime)))  // 501-1200
            claw = strongclaw;                                                                            // ???
          if (clawtime > (clawgetonesteptime + clawgettwosteptime))                                       // 1201---??
            claw = lightclaw;                                                                             // ???
        }
        if (Time2_trup_cnt <= upspeed) {
          /////////////////2025-01-06 ?????????????????
          DOWNSTOP();
          // nop
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          __asm__("nop");
          /////////////////
          UPRUN();
          MACHINE_EventPostOnce(MECH_EVT_CLAW_UP_START);
        }

        else {
          UPSTOP();
        }
      }

      // ????????
      else if (DOWNSW() == 0) {
        tim2_up_protection_flag = 0;
        tim2_up_protection_cnt = 0;
        //UPSTOP();
        gamestatus = 4;
        MACHINE_EventPostOnce(MECH_EVT_CLAW_UP);
        clawtime = 1;
        if (outcount < outbase + clampingnum && outcount >= outbase && gamemode == 1)
          claw = groundstongclaw;  // ??
        else if (roundnum[roundround - 1] == 1 && gamemode == 2)
          claw = groundstongclaw;  // ??
        else
          claw = lightclaw;  // ???
        // CLAWOFF();
      }
    }
    if (gamestatus == 4 && breakdown == 0)  // updelaytime???500   uppulltime???      uppulllength    ?100????200????100
    {
      if (clawtime >= uppulllength)  // ????????????   500--1500
      {
        UPSTOP();
      } else
        UPRUN();

      if (clawtime > updelaytime)  // ?????????????1000+500
      {
        gamestatus = 5;
      }
    }

    // ????
    if (gamestatus == 5 && breakdown == 0) {
      tim2_back_protection_flag = 1;
      // ????????????????
      if (clawtime < clawgetthreesteptime) claw = lightclaw - clawtime * (lightclaw - lostclaw) / clawgetthreesteptime;  // clawgetthreesteptime;
      if (outcount < outbase + clampingnum && outcount >= outbase && gamemode == 1)
        claw = groundstongclaw;  // ??
      else if (roundnum[roundround - 1] == 1 && gamemode == 2)
        claw = groundstongclaw;  // ??
      else
        claw = lightclaw;  // ???
      if (GAMEBACKFLAG == 0) GAMEBACKFLAG = 1;
      if (FRONTSW() == 0) {
        FRONTSTOP();  // ?????
      } else {
        if (front_back_point > 0) front_back_point--;
        if (Time2_trup_cnt <= leftrightspeed / 10) {
          FRONTRUN();
        } else {
          FRONTSTOP();
        }
      }
      if (LEFTSW() == 0) {
        LEFTSTOP();  // ?????
      } else {
        if (right_left_point > 0) right_left_point--;
        if (Time2_trup_cnt <= leftrightspeed / 10) {
          LEFTRUN();
        }

        else {
          LEFTSTOP();
        }
      }
      // ???????????
      if (LEFTSW() == 0 && FRONTSW() == 0) {
        tim2_back_protection_flag = 0;
        tim2_back_protection_cnt = 0;
        gamestatus = 6;
        CLAWOFF();
      }
    }
    // ?????????????????????
    if (gamestatus == 6) {
      clawlosttime = 1;
      gamestatus = 7;
    }
    // ??????
    if (gamestatus == 7 && breakdown == 0) {
      if (clawlosttime < 150)  // ???
      {
        UPSTOP();
        if (Time2_trup_cnt <= 2) {
          DOWNSTOP();
        } else {
          DOWNRUN();
        }
      } else {
        DOWNSTOP();
      }

      if (clawlosttime > 70 && beginning == 5)  // ?????
      {
        CLAWOFF();
				DOWNSTOP();
        beginning = 6;
        downdelay = 1;
      }
      if (clawlosttime > 300 && beginning == 6)  // ????
      {
        tim2_backup_protection_flag = 1;
        
        if (DOWNSW() == 0) {
          // ?????????
          tim2_backup_protection_flag = 0;
          tim2_backup_protection_cnt = 0;
          UPSTOP();  // ?????
          beginning = 7;
          downdelay = 1;
          // ??????
          //					if(swingpullflag==0)
          //						swingpullflag =clawlosttime;
        } else if (breakdown == 0) {
          // ????????????????????????????????????????????????????
          UPRUN();
        }
      }
			//?????????
      if (beginning == 7 && downdelay >= 80) {
        downdelay = 80;
        UPSTOP();  // ?????
        if (pulllength > 0) {
          if (pulllengthtime > 0) {
            DOWNRUN();
          } else {
            DOWNSTOP();
            beginning = 8;
          }
        } else
          beginning = 8;
      }
      //			if(swingpull>0&&swingpullflag>0&&(clawlosttime<(swingpullflag+swingtime*swingpull)))//swingpull?????   swingtime???????
      //				UPRUN();
      //			else if(swingpull>0&&swingpullflag>0&&(clawlosttime>(swingpullflag+swingtime*swingpull)))
      //				UPSTOP();
      //				DOWNRUN();
      //			else if(swingpullflag<swingpullflag+swingtime)
      //				DOWNSTOP();
      //			if(swingpull>0&&pulltime)
      //				UPRUN();
      //			else if()
      //				UPSTOP();

      // ???????
      if (clawlosttime > 1500 && beginning == 8) {
        downdelay = 0;
        swingpullflag = 0;
        gameoverflag = 1;
        gamestatus = 0;
        beginning = 0;
        MACHINE_EventRequestRoundEnd();
        SERIAL_SendStatus(0x01, coinin, machineid, version_code_z);
        clawlosttime = 0;
        gametime = 0;
        gameruntime = 0;
        gametimeflash = 1;
        clawtime = 0;
        winflag_tim = 2;
        display_refresh_time = 0;
      }
    }
  }  // ???????

  // COININ()???
  if (COININ() == 0 && coininlock1 == 1 && coininlock2 == 0) {
    coinin++;
    coin_info.coin++;
    coin_info.balance = coinin;
    coin_info.sn++;
    coin_info.send_num = 4;
    COININFLAG = 1;
    MACHINE_EventPost(MECH_EVT_COIN);
    coininlock2 = 1;
  }
  if (COININ() == 0 && coininlock1 == 0) {
    coininlock1 = 1;
  }
  if (COININ() == 1) {
    coininlock1 = 0;
    coininlock2 = 0;
  }
  // ?????
  if (FRONTKEY() == 0 && frontkeylock1 == 1 && frontkeylock2 == 0) {
    frontkeylock2 = 1;
    frontkeyvalue = 1;
  }
  if (FRONTKEY() == 0 && frontkeylock1 == 0) {
    frontkeylock1 = 1;
  }
  if (FRONTKEY() == 1) {
    frontkeylock1 = 0;
    frontkeylock2 = 0;
  }

  if (BACKKEY() == 0 && backkeylock1 == 1 && backkeylock2 == 0) {
    backkeylock2 = 1;
    backkeyvalue = 1;
  }
  if (BACKKEY() == 0 && backkeylock1 == 0) {
    backkeylock1 = 1;
  }
  if (BACKKEY() == 1) {
    backkeylock1 = 0;
    backkeylock2 = 0;
  }

  if (RIGHTKEY() == 0 && rightkeylock1 == 1 && rightkeylock2 == 0) {
    rightkeylock2 = 1;
    rightkeyvalue = 1;
  }
  if (RIGHTKEY() == 0 && rightkeylock1 == 0) {
    rightkeylock1 = 1;
  }
  if (RIGHTKEY() == 1) {
    rightkeylock1 = 0;
    rightkeylock2 = 0;
  }

  if (LEFTKEY() == 0 && leftkeylock1 == 1 && leftkeylock2 == 0) {
    leftkeylock2 = 1;
    leftkeyvalue = 1;
  }
  if (LEFTKEY() == 0 && leftkeylock1 == 0) {
    leftkeylock1 = 1;
  }
  if (LEFTKEY() == 1) {
    leftkeylock1 = 0;
    leftkeylock2 = 0;
  }

  // ???????
  if (ENTERKEY() == 0 && enterkeylock1 == 1 && enterkeylock2 == 0) {
    enterkeylock2 = 1;
    enterkeyvalue = 1;
  }
  if (ENTERKEY() == 0 && enterkeylock1 == 0) {
    enterkeylock1 = 1;
  }
  if (ENTERKEY() == 1) {
    enterkeyvalue = 0;
    enterkeylock1 = 0;
    enterkeylock2 = 0;
  }

  // ?????????????????????????????????????????
  if (SETKEY() == 0 && setlongkeytime >= 5 && ENTERKEY() != 0) {
    setlongkeytime = 0;
    setlongkey = 1;
    coinin--;
  }
  if (SETKEY() == 0 && setkeylock1 == 1 && setkeylock2 == 0 && ENTERKEY() != 0) {
    setkeylock2 = 1;

    // setkey=1;
    //		coinin++;
    COININTESTFLAG = 1;
    setlongkeytime = 1;
  }
  if (SETKEY() == 0 && setkeylock1 == 0 && ENTERKEY() != 0) {
    setkeylock1 = 1;
  }
  if (SETKEY() == 1 && ENTERKEY() != 0) {
    setlongkeytime = 0;
    setkeylock1 = 0;
    setkeylock2 = 0;
  }

  // ????????
  if (OUTSENTOR() == 1 && outsentorlock1 == 1 && outsentorlock2 == 0) {
    outsentorlock2 = 1;
    outsentorflag = 1;
    WINFLAG++;
    MACHINE_EventPostOnce(MECH_EVT_SUCCESS);
  }
  if (OUTSENTOR() == 1 && outsentorlock1 == 0) {
    outsentorlock1 = 1;
  }
  if (OUTSENTOR() == 0) {
    outsentorlock1 = 0;
    outsentorlock2 = 0;
  }

  MACHINE_EventFlushRoundEnd();

  // ????
}

#endif
