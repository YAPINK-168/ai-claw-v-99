#ifdef HARDWARE_V1

#include "irq.h"

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

// void USART3_IRQHandler(void)  // 串口中断，接本地////串口1接card
// {
//   u8 S3RxData = 0;  //
//   vu32 USART3_SR_temp;
//   //	combusy=1;
//   if (USART_GetITStatus(USART3, USART_IT_RXNE) != RESET) {
//     USART_ClearITPendingBit(USART3, USART_IT_RXNE);
//     S3RxData = USART_ReceiveData(USART3);  // 读取收到的数据
//     // USART1->DR = (S1RxData & (uint16_t)0x01FF);//转发
//     // USART3->DR = (S3RxData & (uint16_t)0x01FF);//转发
//     RX3_buffer[RX3count] = S3RxData;
//     if (RX3count > 90) {
//       RX3count = 0;
//     }
//   }
//   if (USART_GetITStatus(USART3, USART_IT_TC) != RESET)  // 如果是发送完成中断
//   {
//     USART_ClearITPendingBit(USART3, USART_IT_TC);  // 清除发送完成中断标志
//   }
//   //	combusy=0;
// }

void RecGsm(void)  // 心跳，当前参数请求，当前账单，下发设置, 警告上传，远程停机，远程投币
{
  u16 temp = 0;
  //	u8 tmp[20];
  u8 datatempbuff6[7] = {"000000"};  // 卡号
  u8 datatempbuff2[4] = {"00\0"};    // 卡号
  u16 datatemp = 0;
  // 服务器读取wifi信号强度

  if (RX1_buffer[5] == 'P' && RX1_buffer[6] == ':' && RX1_buffer[11] == 'S' && RX1_buffer[12] == 'Q' && RX1_buffer[14] == 'W')  //+CWLAP:(3,"TP-Li",-28,"86:8e:91:33:38:64",1,13,0)
  {
    GsmCq[1] = RX1_buffer[19];  // 字符信号表示
    GsmCq[2] = RX1_buffer[20];
    GsmCq[3] = '\0';
    GsmCqconut = ((GsmCq[1] - 0x30) * 10) + (GsmCq[2] - 0x30);  // 数字信号表示
    // if(GsmCqconut<1||GsmCqconut>32)GsmCqconut=1;
    RX1count = 0;
  }
  // 服务器下发心跳[r|00001|00|000]
  if (RX1_buffer[0] == '[' && RX1_buffer[1] == 'r' && RX1_buffer[3] == machineidcode[0] && RX1_buffer[4] == machineidcode[1] && RX1_buffer[5] == machineidcode[2] &&
      RX1_buffer[6] == machineidcode[3] && RX1_buffer[7] == machineidcode[4] && RX1_buffer[RX1count - 1] == ']')  // 收到心跳+QIURC: "recv",0,4  1111
  {
    neton = 0;
    off_line_time = 0;
    reconnect = 0;
    connecting = 0;
    RX1count = 0;
  }
  // u8  gsmupdatabuff[67]    ={"[u|00001|0|000002|12345678|00000000000000000000000000000000]#$-$#\0"};
  if (RX1_buffer[0] == '[' && RX1_buffer[1] == 'u' && RX1_buffer[3] == machineidcode[0] && RX1_buffer[4] == machineidcode[1] && RX1_buffer[5] == machineidcode[2] &&
      ((RX1_buffer[6] == machineidcode[3] && RX1_buffer[7] == machineidcode[4]) || (RX1_buffer[6] == '9' && RX1_buffer[7] == '9')) && RX1_buffer[9] == '0' &&
      RX1_buffer[RX1count - 1] == ']')  // 收到心跳+QIURC: "recv",0,4  1111
  {
    temp = mymemext1(RX1_buffer, datatempbuff6, '|', '|', 3, 80);
    version_code = chr2hex(datatempbuff6[3]) * 1000 + chr2hex(datatempbuff6[2]) * 100 + chr2hex(datatempbuff6[1]) * 10 + chr2hex(datatempbuff6[0]);  // 下发0的时候就是清除
    RX1count = 0;
    updata_flag[0] = 1;
  }

  // 服务器下发投币[c|机台号(5位)|命令4投币|投币量2位|8位随机数|签名]  [c|00001|5|28|00000000|0000000000000000000000000000000000000]
  if (RX1_buffer[0] == '[' && RX1_buffer[1] == 'e' && RX1_buffer[3] == machineidcode[0] && RX1_buffer[4] == machineidcode[1] && RX1_buffer[5] == machineidcode[2] &&
      ((RX1_buffer[6] == machineidcode[3] && RX1_buffer[7] == machineidcode[4]) || (RX1_buffer[6] == '9' && RX1_buffer[7] == '9')) && RX1_buffer[9] == '4' &&
      RX1_buffer[RX1count - 1] == ']')  // 收到心跳+QIURC: "recv",0,4  1111
  {
    mymemecyup(RX1_buffer, gsmcoindatabuff, 56, 5);
    mymemecyup(gsmcoindatabuff, RX1_buffer, 3, 5);
    mymemecyup(gsmcoindatabuff, RX1_buffer, 11, 2);
    mymemecyup(gsmcoindatabuff, RX1_buffer, 14, 8);
    Add_md5_keymark_coin(gsmcoindatabuff);

    if (strcmp((const char *)gsmcoindatabuff, (const char *)RX1_buffer) == 0) {
      temp = mymemext1(RX1_buffer, datatempbuff2, '|', '|', 3, 80);
      if (chr2hex(datatempbuff2[0]) * 10 + chr2hex(datatempbuff2[1]) == 0)
        coinin = 0;
      else
        coinin += chr2hex(datatempbuff2[0]) * 10 + chr2hex(datatempbuff2[1]);  // 下发0的时候就是清除

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
    memset(RX1_buffer, 0, sizeof(RX1_buffer));
    RX1count = 0;
  }
  // 服务器下发禁用[c|机台号(5位)|命令5停机|00停机，01开机，02高度随机|8位随机数|签名]
  if (RX1_buffer[0] == '[' && RX1_buffer[1] == 'c' && RX1_buffer[3] == machineidcode[0] && RX1_buffer[4] == machineidcode[1] && RX1_buffer[5] == machineidcode[2] &&
      ((RX1_buffer[6] == machineidcode[3] && RX1_buffer[7] == machineidcode[4]) || (RX1_buffer[6] == '9' && RX1_buffer[7] == '9')) && RX1_buffer[9] == '5' &&
      RX1_buffer[RX1count - 1] == ']')  // 收到心跳+QIURC: "recv",0,4  1111
  {
    temp = mymemext1(RX1_buffer, datatempbuff2, '|', '|', 3, 80);
    machinedisable = chr2hex(datatempbuff2[1]) * 10 + chr2hex(datatempbuff2[0]);  //
    RX1count = 0;
  }
  // 服务器查询账单[q|机台号(5位)|命令1读取账单|条目1读取总投币量，2读取总礼品数，3读取当前投币数，4读取意外礼品数|8位随机数|签名]#$-$#
  // 下发   [g|00001|1|01|12345678|sign]#$-$#   //读取机器00001余币量
  // 回复   [g|00001|1|01|000020|12345678|sign]#$-$#   //机器00001回复余币量20个   ---000020参数值为6bit
  else if (RX1_buffer[0] == '[' && RX1_buffer[1] == 'g' && RX1_buffer[3] == machineidcode[0] && RX1_buffer[4] == machineidcode[1] && RX1_buffer[5] == machineidcode[2] &&
           ((RX1_buffer[6] == machineidcode[3] && RX1_buffer[7] == machineidcode[4]) || (RX1_buffer[6] == '9' && RX1_buffer[7] == '9')) && RX1_buffer[9] == '1' &&
           RX1_buffer[RX1count - 1] == ']')  // 收到订单号[a|00001|0000000001]
  {
    // u8  coinin;            //余币数           1
    // u16 surprisecount;     //意外统计         2
    // u16 allcoin;           //投币统计         3
    // uu16 alltoy;           //出礼品统计       4
    switch (RX1_buffer[12]) {
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
    RX1count = 0;
  }
  // 服务器查询机器参数：[q|机台号(5位)|命令2读取参数|条目2位1-99分别对于相应的参数|参数值5位|8位随机数|签名]#$-$#
  // 下发   [q|00001|2|01|12345678|sign]#$-$#          //读取多少个币一次
  // 回复   [q|00001|2|01|000002|12345678|sign]#$-$#   //机器编号00001回复2币玩一次   ---000002参数值为6bit

  else if (RX1_buffer[0] == '[' && RX1_buffer[1] == 'q' && RX1_buffer[3] == machineidcode[0] && RX1_buffer[4] == machineidcode[1] && RX1_buffer[5] == machineidcode[2] &&
           ((RX1_buffer[6] == machineidcode[3] && RX1_buffer[7] == machineidcode[4]) || (RX1_buffer[6] == '9' && RX1_buffer[7] == '9')) && RX1_buffer[9] == '2' &&
           RX1_buffer[RX1count - 1] == ']')  // 收到订单号[a|00001|0000000001]
  {
    //		inquiresetflag=0x10;
    temp = mymemext1(RX1_buffer, datatempbuff2, '|', '|', 3, 80);
    datatemp = chr2hex(datatempbuff2[0]) * 10 + chr2hex(datatempbuff2[1]);
    if (datatemp > 0) datatemp--;
    if (datatemp <= 15)
      inquiresetflagl = inquiresetflagl | (0x01 << datatemp);
    else {
      datatemp = datatemp - 15;
      inquiresetflagh = inquiresetflagh | (0x01 << datatemp);
    }
    RX1count = 0;
  }
  // 服务器设置参数：[s|机台号(5位)|命令3设置参数|条目1-99分别对于相应的参数|参数值6位|8位随机数|签名]#$-$#
  // 下发   [s|00001|3|01|000002|12345678|sign]#$-$#
  // 回复   [s|00001|3|01|000002|12345678|sign]#$-$#
  else if (RX1_buffer[0] == '[' && RX1_buffer[1] == 's' && RX1_buffer[3] == machineidcode[0] && RX1_buffer[4] == machineidcode[1] && RX1_buffer[5] == machineidcode[2] &&
           ((RX1_buffer[6] == machineidcode[3] && RX1_buffer[7] == machineidcode[4]) || (RX1_buffer[6] == '9' && RX1_buffer[7] == '9')) && RX1_buffer[9] == '3' &&
           RX1_buffer[RX1count - 1] == ']') {
    setflag = 1;
    //		temp = mymemext1(RX3_buffer,datatempbuff2,'|','|',4,80);
    //		datatemp =datatempbuff2[1]*10+datatempbuff2[0];
    //		setflag=setflag|(0x01<<datatemp);
    if (RX1_buffer[11] == '0') {
      switch (RX1_buffer[12]) {
        case '1': {
          mymemecyl(RX1_buffer, coinbasebuff, 18, 2);  // 语句coinbasebuff
        } break;
        case '2': {
          mymemecyl(RX1_buffer, roundbasebuff, 18, 2);  // 语句roundbasebuff
        } break;
        case '3':
          mymemecyl(RX1_buffer, lostclawbuff, 18, 2);  // 语句lostclawbuff
          break;
        case '4':
          mymemecyl(RX1_buffer, groundstongclawbuff, 18, 2);  // 语句groundstongclawbuff
          break;
        case '5':
          mymemecyl(RX1_buffer, lightclawbuff, 18, 2);  // 语句lightclawbuff
          break;
        case '6':
          mymemecyl(RX1_buffer, strongclawbuff, 18, 2);  // 语句strongclawbuff
          break;
        case '7':
          mymemecyl(RX1_buffer, gametimebasebuff, 18, 2);  // 语句gametimebasebuff
          break;
        case '8':
          mymemecyl(RX1_buffer, roundoffsetbuff, 18, 2);  // 语句roundoffsetbuff
          break;
        case '9':
          mymemecyl(RX1_buffer, swingpullbuff, 18, 2);  // 语句swingpullbuff
          break;
        default:
          break;
      }
    } else if (RX1_buffer[11] == '1') {
      switch (RX1_buffer[12]) {
        case '0': {
          mymemecyl(RX1_buffer, factarysetbuff, 18, 2);  // 语句factarysetbuff
        } break;
        case '1':                                       //[s|00001|3|01|000002|12345678|sign]#$-$#
          mymemecyl(RX1_buffer, machineidbuff, 15, 5);  // 语句machineidbuff
          break;
        case '2':
          mymemecyl(RX1_buffer, upspeedbuff, 18, 2);  // 语句upspeedbuff
          break;
        case '3':
          mymemecyl(RX1_buffer, downspeedbuff, 18, 2);  // 语句downspeedbuff
          break;
        case '4':
          mymemecyl(RX1_buffer, leftrightspeedbuff, 18, 2);  // 语句leftrightspeedbuff
          break;
        case '5':
          mymemecyl(RX1_buffer, fixedpointbuff, 18, 2);  // 语句fixedpointbuff
          break;
        case '6':
          mymemecyl(RX1_buffer, front_back_point_fixedpointbuff, 15, 5);  // 语句front_back_point_fixedpointbuff
          break;
        case '7':
          mymemecyl(RX1_buffer, right_left_point_fixedpointbuff, 15, 5);  // 语句right_left_point_fixedpointbuff
          break;
        case '8':
          mymemecyl(RX1_buffer, clawgetonesteptimebuff, 16, 4);  // 语句clawgetonesteptimebuff
          break;
        case '9':
          mymemecyl(RX1_buffer, clawgettwosteptimebuff, 16, 4);  // 语句clawgettwosteptimebuff
          break;
        default:
          break;
      }
    } else if (RX1_buffer[11] == '2')  // mymemecys(RX3_buffer,clawgetthreesteptimebuff,18,2);
    {
      switch (RX1_buffer[12]) {
        case '0': {
          mymemecyl(RX1_buffer, clawgetthreesteptimebuff, 16, 4);  // 语句clawgetthreesteptimebuff
        } break;
        case '1': {
          mymemecyl(RX1_buffer, pulllengthbuff, 18, 2);  // 语句clawgetthreesteptimebuff
        } break;
        case '2': {
          mymemecyl(RX1_buffer, outbasebuff, 16, 4);  // 语句clawgetthreesteptimebuff
        } break;
        case '3': {
          mymemecyl(RX1_buffer, clampingnumbuff, 18, 2);  // 语句clawgetthreesteptimebuff
        } break;
        case '4': {
          mymemecyl(RX1_buffer, uppulltimebuff, 18, 2);  // 语句clawgetthreesteptimebuff
        } break;
        case '5': {
          mymemecyl(RX1_buffer, gamemodebuff, 18, 2);  // 语句clawgetthreesteptimebuff
        } break;
        default:
          break;
      }
    }
    RX1count = 0;
  }
}
/////////////////串口2中断接4G模块////////////////////////
void USART2_IRQHandler(void) {
  if (USART_GetFlagStatus(USART2, USART_FLAG_ORE) != RESET) {
    USART_ClearFlag(USART2, USART_FLAG_ORE);  // 清除溢出中断
  }
}
/////////////////串口2中断接4G模块////////////////////////
u8 uart1_rx_status = 0;
u16 uart1_rx_time = 0;
void USART1_IRQHandler(void) {
  u8 S1RxData = 0;  //
  combusy = 1;
  if (USART_GetFlagStatus(USART1, USART_FLAG_ORE) != RESET) {
    USART_ClearFlag(USART1, USART_FLAG_ORE);  // 清除溢出中断
  }
  if (USART_GetITStatus(USART1, USART_IT_RXNE) != RESET) {
    USART_ClearITPendingBit(USART1, USART_IT_RXNE);
    USART_ClearFlag(USART1, USART_FLAG_RXNE);
    uart1_rx_time = 100;
    uart1_rx_status = 1;
    S1RxData = USART_ReceiveData(USART1);
    // USART3->DR = (S1RxData & (uint16_t)0x01FF);  // 转发
    USART1_Rx_time = 1;  //
    if (S1RxData == '+') RX1count = 0;
    if (S1RxData == '[') {
      RX1count = 0;
    }
    RX1_buffer[RX1count++] = S1RxData;
    // 		if(RX1count >=5)//ERROR     +CWJAP:3
    // 		{
    // 			if(RX1_buffer[RX1count-5]=='J'&&RX1_buffer[RX1count-4]=='A'&&RX1_buffer[RX1count-3]=='P'&&RX1_buffer[RX1count-2]==':'&&RX1_buffer[RX1count-1]=='3')//CLOSED
    // tDow
    // 			{
    // 				//reconnect=1;
    // 				nowififlag=1;
    // 				RX1count=0;
    // 			}
    // 			else
    // if(RX1_buffer[RX1count-5]=='E'&&RX1_buffer[RX1count-4]=='R'&&RX1_buffer[RX1count-3]=='R'&&RX1_buffer[RX1count-2]=='O'&&RX1_buffer[RX1count-1]=='R')//CLOSED   ERROR
    // 			{
    // 				reconnect=1;
    // 				connecting =1;
    // 				RX1count=0;
    // 			}//ERROR  valid
    // //
    // //if(RX3_buffer[RX3count-4]=='E'&&RX3_buffer[RX3count-3]=='R'&&RX3_buffer[RX3count-2]=='R'&&RX3_buffer[RX3count-1]=='O'&&RX3_buffer[RX3count]=='R')//CLOSED

    // 		}//etDown
    //		if(RX1count>=6)
    //		{
    //			if(RX1_buffer[RX1count-6]=='D'&&RX1_buffer[RX1count-5]=='i'&&RX1_buffer[RX1count-4]=='s'&&RX1_buffer[RX1count-3]=='c'&&RX1_buffer[RX1count-2]=='o'&&RX1_buffer[RX1count-1]=='n'&&RX1_buffer[RX1count]=='n')//Disconn
    //			{
    //				reconnect=1;
    //				RX1count=0;
    //			}
    //		}
    if (RX1count > 200) {
      reszer = 0;     // 收到密钥
      coininen = 0;   // 收到余额
      userpayed = 0;  // 收到支付
      userscan = 0;   // 收到扫描
      resqr = 0;      // 收到二维码
      RX1count = 0;
    }

    if (S1RxData == ']') {
      RecGsm();  // 接收信号解析
    }
    if (S1RxData == ')') {
      RecGsm();  // 接收信号解析
    } else if (RX1count > 200) {
      RX1count = 0;
    }
  }
  if (USART_GetITStatus(USART1, USART_IT_TC) != RESET)  // 如果是发送完成中断
  {
    USART_ClearITPendingBit(USART1, USART_IT_TC);  // 清除发送完成中断标志
  }
  combusy = 0;
}

///////////////串口3中断/////////////////////
// 500300010002984A
// 设备地址1  功能码1  寄存器起始地址2   寄存器个数2  crc低位   crc高位
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
//		if(USART_GetITStatus(USART3, USART_IT_TC) != RESET)	// 如果是发送完成中断
//     {
//		USART_ClearITPendingBit(USART3, USART_IT_TC); 	// 清除发送完成中断标志
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
    // 设置的时候，测试抓力
    if (setfinishing == 1) {
      if (ENTERKEY() == 0) {
        if (setcursor == 4) {
          if (Time1_trup_cnt <= groundstongclaw)  // 数值越小，抓力越小,6大尺寸抓不起
            CLAWON();
          else
            CLAWOFF();
        } else if (setcursor == 5) {
          if (Time1_trup_cnt <= strongclaw)  // 数值越小，抓力越小,6大尺寸抓不起
            CLAWON();
          else
            CLAWOFF();
        } else if (setcursor == 6) {
          if (Time1_trup_cnt <= lightclaw)  // 数值越小，抓力越小,6大尺寸抓不起
            CLAWON();
          else
            CLAWOFF();
        } else
          CLAWOFF();
        if (setcursor == 1) DOWNRUN();
        //			  else
        //					DOWNSTOP();
        if (setcursor == 2) UPRUN();
        //				else
        //					UPSTOP();

        if (setcursor == 26) {
          if (FRONTSW() == 0) {
            FRONTSTOP();  // 电机停
          } else {
            if (Time1_trup_cnt <= leftrightspeed)
              FRONTRUN();
            else
              FRONTSTOP();
          }
        }
        if (setcursor == 27) {
          if (BACKSW() == 0) {
            BACKSTOP();  // 电机停
          } else {
            if (Time1_trup_cnt <= leftrightspeed)
              BACKRUN();
            else
              BACKSTOP();
          }
        }

        if (setcursor == 28) {
          if (LEFTSW() == 0) {
            LEFTSTOP();  // 左电机停
          } else {
            if (Time1_trup_cnt <= leftrightspeed)
              LEFTRUN();
            else
              LEFTSTOP();
          }
        }
        if (setcursor == 29) {
          if (Time1_trup_cnt <= leftrightspeed)
            RIGHTRUN();
          else
            RIGHTSTOP();
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
    // 开始可以操作摇杆
    if (beginning == 2 || fixedpointing >= 1) {
      if (GAMEINGFLAG == 0) GAMEINGFLAG = 1;
      // 到边了自动停
      if (BACKSW() == 0)  //
      {
        BACKSTOP();  // 往后停
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
    // 摇杆  左右前后移动
    if (beginning == 2 || fixedpointing == 1) {
      if (RIGHTKEY() == 0 && LEFTKEY() != 0)  // 向右
      {
        LEFTSTOP();
        //////////////////////////////20250106 1.7.1版本修改，解决上下管同时导通的Bug
        Crane_delay_left_cnt1 = 0;
        Crane_delay_left_cnt2 = 0;
        //////////////////////////////
        if (Crane_delay_right_cnt1 < Crane_delay * 10) {
          Crane_delay_right_cnt1++;
          Crane_delay_right_cnt2++;
        }
        if (Crane_delay_right_cnt2 >= Crane_delay * 10) {
          if (Time1_trup_cnt <= leftrightspeed)
            RIGHTRUN();
          else
            RIGHTSTOP();
        } else {
          RIGHTSTOP();  // 右停
        }
      } else {
        if (Crane_delay_right_cnt2 < Crane_delay * 10) {
          Crane_delay_right_cnt2++;
        }
        if (Crane_delay_right_cnt2 >= Crane_delay * 10 && Crane_delay_right_cnt1 > 0) {
          Crane_delay_right_cnt1--;
          if (Time1_trup_cnt <= leftrightspeed)
            RIGHTRUN();
          else
            RIGHTSTOP();
        } else if (Crane_delay_right_cnt1 == 0) {
          Crane_delay_right_cnt2 = 0;
          RIGHTSTOP();  // 右停
        }
      }
      if (LEFTKEY() == 0 && RIGHTKEY() != 0) {
        RIGHTSTOP();
        //////////////////////////////20250106 1.7.1版本修改，解决上下管同时导通的Bug
        Crane_delay_right_cnt1 = 0;
        Crane_delay_right_cnt2 = 0;
        //////////////////////////////
        if (Crane_delay_left_cnt1 < Crane_delay * 10) {
          Crane_delay_left_cnt1++;
          Crane_delay_left_cnt2++;
        }
        if (Crane_delay_left_cnt2 >= Crane_delay * 10) {
          if (LEFTSW() == 0) {
            LEFTSTOP();  // 左电机停
            //						right_left_point =0;
          } else {
            if (Time1_trup_cnt <= leftrightspeed)
              LEFTRUN();
            else
              LEFTSTOP();
          }
        }
      } else {
        if (Crane_delay_left_cnt2 < Crane_delay * 10) {
          Crane_delay_left_cnt2++;
        }
        if (Crane_delay_left_cnt2 >= Crane_delay * 10 && Crane_delay_left_cnt1 > 0) {
          Crane_delay_left_cnt1--;
          if (LEFTSW() == 0) {
            LEFTSTOP();  // 左电机停
            //						right_left_point =0;
          } else {
            if (Time1_trup_cnt <= leftrightspeed)
              LEFTRUN();
            else
              LEFTSTOP();
          }
        } else if (Crane_delay_left_cnt1 == 0) {
          Crane_delay_left_cnt2 = 0;
          LEFTSTOP();  // 左停
        }
      }
    }
    if (beginning == 2 || fixedpointing == 2) {
      if (BACKKEY() == 0 && FRONTKEY() != 0) {
        FRONTSTOP();
        //////////////////////////////20250106 1.7.1版本修改，解决上下管同时导通的Bug
        Crane_delay_front_cnt1 = 0;
        Crane_delay_front_cnt2 = 0;
        //////////////////////////////
        if (Crane_delay_back_cnt1 < Crane_delay * 10) {
          Crane_delay_back_cnt1++;
          Crane_delay_back_cnt2++;
        }
        if (Crane_delay_back_cnt2 >= Crane_delay * 10) {
          if (BACKSW() == 0) {
            BACKSTOP();  // 电机停
            // front_back_point =0;
          } else {
            if (front_back_point < 50000) front_back_point++;
            if (Time1_trup_cnt <= leftrightspeed)
              BACKRUN();
            else
              BACKSTOP();
          }
        }
      } else {
        if (Crane_delay_back_cnt2 < Crane_delay * 10) {
          Crane_delay_back_cnt2++;
        }
        if (Crane_delay_back_cnt2 >= Crane_delay * 10 && Crane_delay_back_cnt1 > 0) {
          Crane_delay_back_cnt1--;
          if (BACKSW() == 0) {
            BACKSTOP();  // 电机停
            // front_back_point =0;
          } else {
            if (front_back_point < 50000) front_back_point++;
            if (Time1_trup_cnt <= leftrightspeed)
              BACKRUN();
            else
              BACKSTOP();
          }
        } else if (Crane_delay_back_cnt1 == 0) {
          Crane_delay_back_cnt2 = 0;
          BACKSTOP();
        }
      }
      if (FRONTKEY() == 0 && BACKKEY() != 0)  // 往自己
      {
        BACKSTOP();
        //////////////////////////////20250106 1.7.1版本修改，解决上下管同时导通的Bug
        Crane_delay_back_cnt1 = 0;
        Crane_delay_back_cnt2 = 0;
        //////////////////////////////
        if (Crane_delay_front_cnt1 < Crane_delay * 10) {
          Crane_delay_front_cnt1++;
          Crane_delay_front_cnt2++;
        }
        if (Crane_delay_front_cnt2 >= Crane_delay * 10) {
          if (FRONTSW() == 0) {
            FRONTSTOP();  // 左电机停
            front_back_point = 0;
          } else {
            if (front_back_point > 0) front_back_point--;
            if (Time1_trup_cnt <= leftrightspeed)
              FRONTRUN();
            else
              FRONTSTOP();
          }
        }
      } else {
        if (Crane_delay_front_cnt2 < Crane_delay * 10) {
          Crane_delay_front_cnt2++;
        }
        if (Crane_delay_front_cnt2 >= Crane_delay * 10 && Crane_delay_front_cnt1 > 0) {
          Crane_delay_front_cnt1--;
          if (FRONTSW() == 0) {
            FRONTSTOP();  // 左电机停
            front_back_point = 0;
          } else {
            if (front_back_point > 0) front_back_point--;
            if (Time1_trup_cnt <= leftrightspeed)
              FRONTRUN();
            else
              FRONTSTOP();
          }
        } else if (Crane_delay_front_cnt1 == 0) {
          Crane_delay_front_cnt2 = 0;
          FRONTSTOP();  // 停
        }
      }
    }
    // 开始抓
    if (((gamestatus == 3 || gamestatus == 4 || gamestatus == 5) && beginning == 5) && breakdown == 0) {
      if (Time1_trup_cnt <= claw)  // 数值越小，抓力越小,6大尺寸抓不起  1-100，
        CLAWON();                  // 抓
      else
        CLAWOFF();
    } else if (breakdown > 0) {
      CLAWOFF();
      FRONTSTOP();  // 这里放这个地方是为了及时刹车
      BACKSTOP();
      LEFTSTOP();   // 左电机停
      RIGHTSTOP();  // 右停
    }

    if (gamestatus == 1 && beginning < 4) {
      if (enterkeyvalue == 1 || gametime == 0)  // 有按键，或者时间到下爪
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
        if (swingpull == 0)  // 防甩关闭，则不用拉
        {
          gamestatus = 2;  // 开始下爪，下爪动作在定时器2
        } else
          swingpulltime = 1;
        //				gamestatus=2;
        //				downtime_select = downtimeset;
        //				swingpulltime =1;
        beginning = 3;  // 不能再操作遥感
        FRONTSTOP();    // 这里放这个地方是为了及时刹车
        BACKSTOP();
        LEFTSTOP();   // 左电机停
        RIGHTSTOP();  // 右停
        beginning = 4;
      }
    }
  }
}
///////////////////1ms中断////////////////////////
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
    if (!GPIO_ReadInputDataBit(GPIOA, GPIO_Pin_12)) {
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
      LEFTSTOP();  // 左电机停
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
      LEFTSTOP();  // 左电机停
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
      LEFTSTOP();  // 左电机停
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
      LEFTSTOP();  // 左电机停
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
  if (clawlosttime > 0)  // 放爪子时间
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
    // 网络连接超时
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
    if (USART1_Rx_time) USART1_Rx_time++;  // 接收中断开始累计
    if (USART1_Rx_time > 3)                // 100ms
    {
      M26netflay = 1;
      USART1_Rx_time = 0;  // 计时清零
    }
    Second2++;
    if (Second2 > 100) Second2 = 0;
    if (setlongkeytime > 0) setlongkeytime++;
    if (setlongkeytime > 10) setlongkeytime = 10;
  }
  if (swingpulltime > 0) swingpulltime++;
  // 防止超时保护
  if (gametime == 0 && gameruntime == 0 && setfinishing == 0) {
    FRONTSTOP();  // 这里放这个地方是为了及时刹车
    BACKSTOP();
    LEFTSTOP();   // 左电机停
    RIGHTSTOP();  // 右停
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
          if (Time2_trup_cnt <= upspeed)
            UPRUN();
          else
            UPSTOP();
        }
      }

      if (setcursor == 12) {
        if (test_downtime >= downtimeset)
          DOWNSTOP();

        else {
          test_downtime++;
          if (Time2_trup_cnt <= downspeed)
            DOWNRUN();
          else
            DOWNSTOP();
        }
      }
    }
  }
  // 开始下爪
  if (beginning >= 4) {
    if (CLAWDOWNFLAG == 0) CLAWDOWNFLAG = 1;
    // 拉紧
    if (swingpulltime > 0) {
      if (swingpulltime < swingpull)  // 小于一个时间，拉紧
      {
        UPRUN();
      } else if (swingpulltime > swingpull && swingpulltime < (swingpull + 20))  // 大于这个时间停止swingpull*100
      {
        UPSTOP();
      } else if (swingpulltime > (swingpull + 150))  //
      {
        //				downtime_select = downtimeset;
        swingpulltime = 0;
        gamestatus = 2;
      }
    }
    if (gamestatus == 2 && breakdown == 0 && secondclaw_rise_flag == 0)  // 下爪动作
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
        if (Time2_trup_cnt <= downspeed)
          DOWNRUN();
        else
          DOWNSTOP();
        if (downtime > downtimeset)  // downtime_select)
        {
          downdelay = 1;
          DOWNSTOP();
          claw = groundstongclaw;
          //					downtime =0;
          //					gamestatus =3;//爪到底了
          //					beginning =5;
          //					claw = groundstongclaw;
        }
      } else if (OUTSENTOR() == 1)  // 这个是在洞口下爪，防止线放完反卷
      {
        downtime = 0;
        DOWNSTOP();
        gamestatus = 3;  // 爪到底了
        downdelay = 1;
        beginning = 5;
        claw = groundstongclaw;
      } else if (GROUNDSW() == 0 && downdelay == 0) {
        downdelay = 1;
        DOWNSTOP();
      }

      if (enterkeyvalue == 1 && downdelay == 0 && secondclaw == 1) {
        downtime = 0;
        downdelay = 1;
        DOWNSTOP();
        if (CLAWTOYFLAG == 0)  // 播声音
          CLAWTOYFLAG = 1;
        secondclaw_rise_flag = 1;
        //				gamestatus =3;//爪到底了
        beginning = 5;
        //				claw = groundstongclaw;
        enterkeyvalue = 0;
      }

      if (downdelay >= 50)  // 到了底部还要放一点点线
      {
        DOWNSTOP();
        if (CLAWTOYFLAG == 0)  // 播声音
          CLAWTOYFLAG = 1;
        claw = groundstongclaw;
      }
      if (downdelay >= downdelayset)  // 停留时间
      {
        DOWNSTOP();
        downtime = 0;
        downdelay = 1;
        gamestatus = 3;  // 爪到底了
        beginning = 5;
        claw = groundstongclaw;
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
    }
    // 开始上升
    if (gamestatus == 3 && breakdown == 0 && downdelay >= secondclaw_time) {
      downdelay = secondclaw_time;
      //		if(gamestatus ==3 && breakdown == 0 && downdelay >= 80)
      //		{
      //			downdelay = 80;
      tim2_down_protection_flag = 0;
      tim2_down_protection_cnt = 0;
      tim2_up_protection_flag = 1;
      if (CLAWUPFLAG == 0)  // 播声音
      {
        CLAWUPFLAG = 1;
        clawtime = 1;
      }

      // 上升过程，抓力情况
      //			if(clawtime< clawgetonesteptime)
      //			{
      //				claw =groundstongclaw;//强抓
      //			}
      //			else//什么时候需要拖拽？什么条件
      //			{
      //				if(fixedpoint==0||(fixedpoint==1&&(right_left_point<right_left_point_fixedpoint&&front_back_point<front_back_point_fixedpoint)))
      //				{
      //					if(roundnum[roundround-1]==1)
      //							claw =clawpower[0];//强抓,保夹
      //					else if(clawtime<clawgettwosteptime)
      //							claw =clawpower[0]-clawtime*clawpower[4]/clawgettwosteptime;//(strongclaw-lightclaw);		//强到弱变
      //				}
      //				//定点落物
      //				if(fixedpoint==1&&(right_left_point<right_left_point_fixedpoint||front_back_point<front_back_point_fixedpoint))
      //				{
      //					if(clawtime<clawgettwosteptime)
      //						claw =clawpower[0]-clawtime*clawpower[4]/clawgettwosteptime;//(strongclaw-lightclaw);		//强到弱变
      //				}
      //				else if(fixedpoint==1&&(right_left_point>right_left_point_fixedpoint||front_back_point>front_back_point_fixedpoint))
      //					claw =clawpower[0];//强抓,保夹
      //			}

      // 上升过程
      if (DOWNSW() == 1) {
        if (outcount < outbase + clampingnum && outcount >= outbase && gamemode == 1)  // 贩卖
          claw = groundstongclaw;                                                      // 保夹不得，加的
        else if (roundnum[roundround - 1] == 1 && gamemode == 2)                       // 随机
          claw = groundstongclaw;                                                      // 保夹
        else {
          if (clawtime < clawgetonesteptime)                                                              // 1----500
            claw = groundstongclaw;                                                                       // 强抓
          if ((clawtime > clawgetonesteptime) && (clawtime < (clawgettwosteptime + clawgetonesteptime)))  // 501-1200
            claw = strongclaw;                                                                            // 中抓
          if (clawtime > (clawgetonesteptime + clawgettwosteptime))                                       // 1201---顶
            claw = lightclaw;                                                                             // 弱抓
        }
        if (Time2_trup_cnt <= upspeed) {
          /////////////////2025-01-06 修改，防止上下管同时导通
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
        }

        else {
          UPSTOP();
        }

      }

      // 升到顶部
      else if (DOWNSW() == 0) {
        tim2_up_protection_flag = 0;
        tim2_up_protection_cnt = 0;
        UPSTOP();
        gamestatus = 4;
        clawtime = 1;
        if (outcount < outbase + clampingnum && outcount >= outbase && gamemode == 1)
          claw = groundstongclaw;  // 强抓
        else if (roundnum[roundround - 1] == 1 && gamemode == 2)
          claw = groundstongclaw;  // 强抓
        else
          claw = lightclaw;  // 弱抓
        // CLAWOFF();
      }
    }
    if (gamestatus == 4 && breakdown == 0)  // updelaytime上停500   uppulltime上放      uppulllength    停100，拉200，放100
    {
      if (clawtime < uppulllength)  // 停了之后，开始上拉   500--1500
      {
        UPRUN();
      } else
        UPSTOP();

      if (clawtime > updelaytime)  // 停够了，准备回位1000+500
      {
        gamestatus = 5;
      }
    }

    // 回位
    if (gamestatus == 5 && breakdown == 0) {
      tim2_back_protection_flag = 1;
      // 回位过程中抓力情况
      if (clawtime < clawgetthreesteptime) claw = lightclaw - clawtime * (lightclaw - lostclaw) / clawgetthreesteptime;  // clawgetthreesteptime;
      if (outcount < outbase + clampingnum && outcount >= outbase && gamemode == 1)
        claw = groundstongclaw;  // 强抓
      else if (roundnum[roundround - 1] == 1 && gamemode == 2)
        claw = groundstongclaw;  // 强抓
      else
        claw = lightclaw;  // 弱抓
      if (GAMEBACKFLAG == 0) GAMEBACKFLAG = 1;
      if (FRONTSW() == 0) {
        FRONTSTOP();  // 前电机停
      } else {
        if (front_back_point > 0) front_back_point--;
        if (Time2_trup_cnt <= leftrightspeed / 10)
          FRONTRUN();
        else
          FRONTSTOP();
      }
      if (LEFTSW() == 0) {
        LEFTSTOP();  // 左电机停
      } else {
        if (right_left_point > 0) right_left_point--;
        if (Time2_trup_cnt <= leftrightspeed / 10)
          LEFTRUN();

        else
          LEFTSTOP();
      }
      // 回到洞口上面
      if (LEFTSW() == 0 && FRONTSW() == 0) {
        tim2_back_protection_flag = 0;
        tim2_back_protection_cnt = 0;
        gamestatus = 6;
        CLAWOFF();
      }
    }
    // 回到洞口上面，开始放开爪子
    if (gamestatus == 6) {
      clawlosttime = 1;
      gamestatus = 7;
    }
    // 放开爪子
    if (gamestatus == 7 && breakdown == 0) {
      if (clawlosttime < 150)  // 下降
      {
        UPSTOP();
        if (Time2_trup_cnt <= 2)
          DOWNSTOP();
        else
          DOWNRUN();
      } else
        DOWNSTOP();

      if (clawlosttime > 70 && beginning == 5)  // 放爪子
      {
        CLAWOFF();
        beginning = 6;
        downdelay = 1;
      }
      if (clawlosttime > 500 && beginning == 6)  // 上升
      {
        tim2_backup_protection_flag = 1;
        DOWNSTOP();
        if (downdelay < 150 && breakdown == 0) {
          UPRUN();
        } else {
          if (DOWNSW() == 1 && breakdown == 0) {
            UPRUN();
          } else if (DOWNSW() == 0) {
            tim2_backup_protection_flag = 0;
            tim2_backup_protection_cnt = 0;
            UPSTOP();  // 上升停
            beginning = 7;
            downdelay = 1;
            // 开始计时
            //					if(swingpullflag==0)
            //						swingpullflag =clawlosttime;
          }
        }
      }
      if (beginning == 7 && downdelay >= 80) {
        downdelay = 80;
        UPSTOP();  // 上升停
        if (pulllength > 0) {
          if (pulllengthtime > 0)
            DOWNRUN();
          else {
            DOWNSTOP();
            beginning = 8;
          }
        } else
          beginning = 8;
      }
      //			if(swingpull>0&&swingpullflag>0&&(clawlosttime<(swingpullflag+swingtime*swingpull)))//swingpull甩力度   swingtime拉的时间
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

      // 游戏结束
      if (clawlosttime > 1500 && beginning == 8) {
        downdelay = 0;
        swingpullflag = 0;
        gameoverflag = 1;
        gamestatus = 0;
        beginning = 0;
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
  }  // 游戏结束

  // COININ()投币
  if (COININ() == 0 && coininlock1 == 1 && coininlock2 == 0) {
    coinin++;
    coin_info.coin++;
    coin_info.balance = coinin;
    coin_info.sn++;
    coin_info.send_num = 4;
    COININFLAG = 1;
    coininlock2 = 1;
  }
  if (COININ() == 0 && coininlock1 == 0) {
    coininlock1 = 1;
  }
  if (COININ() == 1) {
    coininlock1 = 0;
    coininlock2 = 0;
  }
  // 摇杆检测
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

  // 确定按键
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

  // 设置按键，有长按和短按，长按进入设置，短按为投币
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

  // 出礼品检测
  if (OUTSENTOR() == 1 && outsentorlock1 == 1 && outsentorlock2 == 0) {
    outsentorlock2 = 1;
    outsentorflag = 1;
    WINFLAG++;
  }
  if (OUTSENTOR() == 1 && outsentorlock1 == 0) {
    outsentorlock1 = 1;
  }
  if (OUTSENTOR() == 0) {
    outsentorlock1 = 0;
    outsentorlock2 = 0;
  }

  // 闪灯
}

// 外部中断0服务程序
// void EXTI15_10_IRQHandler(void)
//{
//	//delay_ms(10);//消抖
//	if(((GPIOB_IDR>>12)&0x01)==0)CionReadTime=1;	 	 //硬币检测
//	if(((GPIOA_IDR>>15)&0x01)==0)
//	{
//		 Com.Res.Bits.B13=1;
//		 SensorNum=4;      //IN1
//		 NetCom.Res.Bits.B1=1;
//	}
//	EXTI_ClearITPendingBit(EXTI_Line15); //清除LINE15上的中断标志位
//
//	EXTI_ClearITPendingBit(EXTI_Line12); //清除LINE1上的中断标志位
// }
// void EXTI0_IRQHandler(void)
//{
//	//delay_ms(10);//消抖
//	if(((GPIOA_IDR>>0)&0x01)==0)
//	{
//		 Com.Res.Bits.B13=1;
//		 SensorNum=4;      //IN1
//		 NetCom.Res.Bits.B1=1;
//	}
//	EXTI_ClearITPendingBit(EXTI_Line0); //清除LINE15上的中断标志位
// }
// void EXTI9_5_IRQHandler(void)
//{
//    //delay_ms(20);//消抖
//	 if(((GPIOC_IDR>>6)&0x01)==0)
//	 {
//		  Com.Res.Bits.B23=1;
//
//	 }
//    EXTI_ClearITPendingBit(EXTI_Line6); //清除LINE15上的中断标志位

//}

#endif
