#include <math.h>
#include <stdio.h>
#include <string.h>

#include "bmp.h"
#include "define.h"
#include "extern.h"
#include "game_app.h"
#include "lcd.h"
#include "rc04v.h"
#include "setgame.h"

char show_data[6] = {0};

u16 secretcode = 0;
u8 secretnum[4] = {0};
u8 secretcodeflag = 0;
u8 secretcodepoint = 0;
u8 displayselect = 0;

extern float test_downtime;
extern uint8_t control_mode;
extern uint8_t free_play_num;

void Delay1ms(u16 di) {
  u16 da, db;
  for (da = 0; da < di; da++)
    for (db = 0; db < 7300; db++);
}

void delay_us(u16 us_time) {
  u16 i = 0;
  while (us_time--) {
    i = 7;
    while (i--);
  }
}

void gametimeflesh() {
  gametimeflash = 0;
  SendCMD(0x30);
  SendCMD(0x30);  // 8 位介面，基本指令集
  LCD_Set_XY(2, 3);
  LCD_Set_XY(2, 3);
  LCD_Write_Number(10);
  LCD_Write_Number(gametime / 10);
  LCD_Write_Number(gametime % 10);
}

// void displayinit(void)
//{
////	Delay1ms(100);
//	LcmClearTXT();
//	Delay1ms(100);
//	LcmClearBMP();
//	Delay1ms(100);
//	//SendCMD(0x3e);
//	SendCMD(0x36);
//	Delay1ms(200);
////显示图形结构，布局以图形方式显示
//	Put(IBM);
//	Delay1ms(200);
//	SendCMD(0x30);  //8 位介面，基本指令集
//	SendCMD(0x30);  //8 位介面，基本指令集
//	LCD_Set_XY(4,0);
//	LCD_Set_XY(4,0);
//	Delay1ms(50);
//	LCD_Write_Number(10);
//	LCD_Write_Number(coinbase/10);
//	LCD_Write_Number(coinbase%10);
//	LCD_Set_XY(4,6);
//	LCD_Set_XY(4,6);
////	LCD_Write_Number(10);
//	LCD_Write_Number(coinin/10);
//	LCD_Write_Number(coinin%10);
//	LCD_Set_XY(3,1);
//	LCD_Set_XY(3,1);
//	LCD_Write_Number(10);
//	LCD_Write_Number((coinin/coinbase)/10);
//	LCD_Write_Number((coinin/coinbase)%10);
//	LCD_Set_XY(3,5);
//	LCD_Set_XY(3,5);
//	LCD_Write_Number(10);
//	LCD_Write_Number(gametime/10);
//	LCD_Write_Number(gametime%10);
//	LCD_Write_String1(1,5,5,machineidcode);
//}

extern u8 rssi_value[3];
void display_id_rssi(u8 rssi_sw) {
  if (breakdown == 0) {
    if (control_mode) {
      LCD_Set_XY(4, 4);
      Write_Char(1, 0x20);
      Write_Char(1, 0x12);
    } else {
      if (!reconnect) {
        LCD_Set_XY(4, 4);
        Write_Char(1, 0x20);
        Write_Char(1, 0x10);
        // Write_Char(1, 0x11);
      } else {
        LCD_Set_XY(4, 4);
        Write_Char(1, 0x20);
        Write_Char(1, 0x20);
      }
    }

    if (rssi_sw) {
      LCD_Write_String1(4, 4, 7, "              ");
      LCD_Write_String1(4, 6, 2, rssi_value);
    } else {
      LCD_Write_String1(4, 5, 6, "            ");
      LCD_Write_String1(4, 5, 5, machineidcode);
    }
  }
}

void displayinit(u8 rssi_sw) {
  Clr_Scr();
  SendCMD(0x30);  // 8 位介面，基本指令集
  SendCMD(0x30);  // 8 位介面，基本指令集
  //	LCD_Set_XY(4,0);
  LCD_Set_XY(4, 0);
  // Delay1ms(50);
  //	LCD_Write_Number(coinbase/10);
  //	LCD_Write_Number(coinbase%10);
  LCD_Write_String(4, 0, "已投");
  LCD_Set_XY(4, 2);
  LCD_Set_XY(4, 2);
  //	LCD_Write_Number(10);
  LCD_Write_Number(coinin / 10);  // 4 4
  LCD_Write_Number(coinin % 10);
  LCD_Write_String(4, 3, "币    ");
  LCD_Write_String(1, 0, "局数  时间  每局");
  LCD_Set_XY(2, 0);
  LCD_Set_XY(2, 0);
  LCD_Write_Number(10);
  LCD_Write_Number((coinin / coinbase) / 10);  // 2  1
  LCD_Write_Number((coinin / coinbase) % 10);
  LCD_Set_XY(2, 6);
  LCD_Set_XY(2, 6);
  LCD_Write_Number((coinbase) / 10);  // 2  1
  LCD_Write_Number((coinbase) % 10);
  LCD_Write_String(2, 7, "币");

  if (uppulltime == 2 && gamemode == 1) {
    LCD_Write_String(3, 0, "售价    已累加  ");
    LCD_Set_XY(3, 2);
    LCD_Set_XY(3, 2);
    LCD_Write_Number(outbase / 10);  // 4 4
    LCD_Write_Number(outbase % 10);
    LCD_Set_XY(3, 7);
    LCD_Set_XY(3, 7);
    LCD_Write_Number(outcount / 10);  // 4 4
    LCD_Write_Number(outcount % 10);
  }
  LCD_Set_XY(2, 3);
  LCD_Write_Number(10);
  LCD_Write_Number(gametime / 10);  // 2  5
  LCD_Write_Number(gametime % 10);
  LCD_Write_Number(10);
  LCD_Write_Number(10);
  LCD_Write_Number(10);
  if (breakdown == 0) {
    if (rssi_sw) {
      LCD_Write_String1(4, 7, 2, rssi_value);
    } else {
      LCD_Write_String1(4, 5, 5, machineidcode);
    }
  } else {
    LCD_Set_XY(4, 5);
    LCD_Write_Number(breakdown % 10);
  }
  if (free_play_num) {
    LCD_Write_String(3, 2, "Free:");
    LCD_Set_XY(3, 5);
    LCD_Write_Number(free_play_num / 10);
    LCD_Write_Number(free_play_num % 10);
  }
}

// 临时补丁代码，后期结构优化掉
void gameround(void) {
  uint8_t i;
  srand(Second2);
  roundround = 1;
  for (i = 0; i < 120; i++) {
    roundnum[i] = 0;
    roundadd[i] = 0;
    toynum[i] = 0;
  }
  random_mod_point = GAME_RandomMagicPoint(roundnum, roundbase, roundoffset, rand());
}

// void gameround(void)
// {
// 	u8 i=0,j=0;//,k=0,temp=0;

// 	for(i=0;i <120;i++)
// 	{
// 		roundnum [i]=0;
// 		roundadd [i]=0;
// 		toynum [i]=0;
// 	}
// 	if(roundbase<=5)
// 		roundbase =5;
// 	for(i = 0; i < 105/roundbase; i++)
// 	{
// 		srand(i+Second2);
// 		j = rand() % 100;
// 		if(roundoffset ==2)
// 		{
// 			if(j<=33)
// 				j=0;
// 			else if(j>33&&j<66)
// 				j=1;
// 			else if(j>=66)
// 				j=2;
// 		}
// 		else if(roundoffset ==3)
// 		{
// 			if(j<=25)
// 				j=0;
// 			else if(j>25&&j<50)
// 				j=1;
// 			else if(j>=50&&j<75)
// 				j=2;
// 			else if(j>=75)
// 				j=3;
// 		}
// 		else if(roundoffset ==4)
// 		{
// 			if(j<=20)
// 				j=0;
// 			else if(j>20&&j<40)
// 				j=1;
// 			else if(j>=40&&j<60)
// 				j=2;
// 			else if(j>=60&&j<80)
// 				j=3;
// 			else if(j>=80)
// 				j=4;
// 		}
// 		else if(roundoffset ==5)
// 		{
// 			if(j<=17)
// 				j=0;
// 			else if(j>17&&j<34)
// 				j=1;
// 			else if(j>=34&&j<51)
// 				j=2;
// 			else if(j>=51&&j<68)
// 				j=3;
// 			else if(j>=68&&j<85)
// 				j=4;
// 			else if(j>=85)
// 				j=5;
// 		}
// 		//UART1_Send(Second2);
// 		UART1_Send(j);
// 		roundnum[(i+1)*roundbase-1-j]=1;
// 	}
// //		for(i = 0; i < 105; i++)
// //    {
// //			UART1_Send(roundnum[i]);
// //		}
// 	//在不等于强抓的位置加上随机数，以增加中抓到弱抓即摸摸抓
// //	for(i = 0; i < 105; i++)
// //	{
// //		srand(i+Second2);
// //		j = rand() % 10;
// //		if(j==1)
// //			j=7;
// //		if(roundnum[i] != 1)
// //			roundnum[i] = j;  //0 1 2 3 4 5 6 7 8 9
// //		UART1_Send(roundnum[i]);
// //	}
// }

void toycount(void) {
  u8 temp = 0;
  alltoy = 0;
  for (temp = 0; temp < 105; temp++) alltoy = alltoy + toynum[temp];
}

void set_light() {
  // if(setcursor==1||setcursor==4||setcursor==7||setcursor==10||setcursor==13||setcursor==16||setcursor==19||setcursor==22||setcursor==25||setcursor==28)

  if (setcursor % 3 == 1) {
    SendCMD(0x36);
    Set_White(1, 1, 8, 1);  // 第一行取消反白
    Set_White(1, 3, 8, 1);  // 第一行取消反白
    Set_White(1, 4, 8, 1);  // 第一行取消反白
    Set_White(1, 2, 5, 0);  // 第一行反白
    SendCMD(0x30);
  }
  // if(setcursor==2||setcursor==5||setcursor==8||setcursor==11||setcursor==14||setcursor==17||setcursor==20||setcursor==23||setcursor==26||setcursor==29)
  if (setcursor % 3 == 2) {
    SendCMD(0x36);
    Set_White(1, 1, 8, 1);  // 第一行取消反白
    Set_White(1, 2, 8, 1);  // 第一行取消反白
    Set_White(1, 4, 8, 1);  // 第一行取消反白
    Set_White(1, 3, 5, 0);  // 第一行反白
    SendCMD(0x30);
  }
  // if(setcursor==3||setcursor==6||setcursor==9||setcursor==12||setcursor==15||setcursor==18||setcursor==21||setcursor==24||setcursor==27||setcursor==30)
  if (setcursor % 3 == 0) {
    SendCMD(0x36);
    Set_White(1, 1, 8, 1);  // 第一行取消反白
    Set_White(1, 3, 8, 1);  // 第一行取消反白
    Set_White(1, 2, 8, 1);  // 第一行取消反白
    Set_White(1, 4, 5, 0);  // 第一行反白
    SendCMD(0x30);
  }
}

void setgame(void) {
  setlongkey = 0;
  setlongkeytime = 0;
  setfinishing = 1;
  Clr_Scr();
  LCD_Set_XY(1, 1);
  LCD_Write_String(1, 0, "----输入密码----");
  setcursor = 0;
  frontkeyvalue = 1;
  rightkeyvalue = 0;
  backkeyvalue = 0;
  leftkeyvalue = 0;
  enterkeyvalue = 0;
  secretcodeflag = 1;
  secretcodepoint = 0;
  secretnum[0] = 0;
  secretnum[1] = 0;
  secretnum[2] = 0;
  secretnum[3] = 0;
  while (secretcodeflag) {
    if (frontkeyvalue == 1) {
      frontkeyvalue = 0;
      secretcode++;
      if (secretcode == 10) secretcode = 0;
      LCD_Write_String(2, 0, "按键输入");
      LCD_Set_XY(2, 5);
      LCD_Write_Number(secretcode % 10);
    }
    if (backkeyvalue == 1) {
      backkeyvalue = 0;
      if (secretcode == 0) secretcode = 10;
      secretcode--;
      LCD_Write_String(2, 0, "按键输入");
      LCD_Set_XY(2, 5);
      LCD_Write_Number(secretcode % 10);
    }
    if (enterkeyvalue == 1) {
      Delay1ms(300);
      while (!ENTERKEY());
      enterkeyvalue = 0;
      if (secretcodepoint == 4) {
        secretcodepoint = 0;
        LCD_Write_String(4, 0, "                ");
      }
      secretnum[secretcodepoint] = secretcode;
      LCD_Write_String(4, secretcodepoint + 1, "*");
      secretcodepoint++;

      //			Set_White(0,4,7,0); //第一行反白
    }
    if (secretnum[0] * 1000 + secretnum[1] * 100 == 5600)  //+secretnum[2]*10+secretnum[3] == 5976)
    {
      secretcodeflag = 0;
      displayselect = 0;
    } else if (secretnum[0] * 1000 + secretnum[1] * 100 == 9300)  //+secretnum[2]*10+secretnum[3] == 5976)
    {
      displayselect = 1;
      secretcodeflag = 0;
    }
  }
  // setcursor =1;
  while (setfinishing) {
    if (frontkeyvalue == 1) {
      frontkeyvalue = 0;
      if (ENTERKEY() == 1) {
        setcursor++;
        if (setcursor == 36) setcursor = 1;
      }
      if (setcursor == 1) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "----设置参数----");
        LCD_Write_String(2, 0, "01几币一局      ");
        LCD_Set_XY(2, 7);
        LCD_Write_Number(coinbase / 10);
        LCD_Write_Number(coinbase % 10);
        LCD_Write_String(3, 0, "02售价金额      ");
        LCD_Set_XY(3, 7);
        LCD_Write_Number(outbase / 10);  // 4 4
        LCD_Write_Number(outbase % 10);
        if (displayselect == 1) {
          LCD_Write_String(4, 0, "03号码          ");
          LCD_Set_XY(4, 5);
          LCD_Write_Number(machineid / 10000);
          LCD_Write_Number(machineid % 10000 / 1000);
          LCD_Write_Number(machineid % 1000 / 100);
          LCD_Write_Number(machineid % 100 / 10);
          LCD_Write_Number(machineid % 10);
        } else {
          LCD_Write_String(4, 0, "03保夹次数      ");
          LCD_Set_XY(4, 7);
          LCD_Write_Number(clampingnum % 100 / 10);
          LCD_Write_Number(clampingnum % 10);
        }
      }
      if (setcursor == 3) {
        if (displayselect == 1) {
          if (ENTERKEY() == 0) {
            machineid = machineid + 10;
            LCD_Write_String(4, 0, "03号码          ");
            LCD_Set_XY(4, 5);
            LCD_Write_Number(machineid / 10000);
            LCD_Write_Number(machineid % 10000 / 1000);
            LCD_Write_Number(machineid % 1000 / 100);
            LCD_Write_Number(machineid % 100 / 10);
            LCD_Write_Number(machineid % 10);
          }
        }
      }
      if (setcursor == 4) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "----谨慎操作----");
        LCD_Write_String(2, 0, "04强抓          ");
        LCD_Set_XY(2, 7);
        LCD_Write_Number(groundstongclaw / 10);
        LCD_Write_Number(groundstongclaw % 10);
        LCD_Write_String(3, 0, "05中抓力        ");
        LCD_Set_XY(3, 7);
        LCD_Write_Number(strongclaw / 10);
        LCD_Write_Number(strongclaw % 10);
        LCD_Write_String(4, 0, "06弱抓力        ");
        LCD_Set_XY(4, 7);
        LCD_Write_Number(lightclaw / 10);
        LCD_Write_Number(lightclaw % 10);
      }
      if (setcursor == 7) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "----设置距离----");
        LCD_Write_String(2, 0, "07强抓时间      ");
        LCD_Set_XY(2, 6);
        LCD_Write_Number(clawgetonesteptime / 1000);
        LCD_Write_Number(clawgetonesteptime % 1000 / 100);
        LCD_Write_Number(clawgetonesteptime % 100 / 10);
        LCD_Write_Number(clawgetonesteptime % 10);
        LCD_Write_String(3, 0, "08中抓时间      ");
        LCD_Set_XY(3, 6);
        LCD_Write_Number(clawgettwosteptime / 1000);
        LCD_Write_Number(clawgettwosteptime % 1000 / 100);
        LCD_Write_Number(clawgettwosteptime % 100 / 10);
        LCD_Write_Number(clawgettwosteptime % 10);
        LCD_Write_String(4, 0, "09放线长度      ");  // 加按键
        LCD_Set_XY(4, 5);
        LCD_Write_Number(downtimeset / 10000);
        LCD_Write_Number(downtimeset % 10000 / 1000);
        LCD_Write_Number(downtimeset % 1000 / 100);
        LCD_Write_Number(downtimeset % 100 / 10);
        LCD_Write_Number(downtimeset % 10);
      }
      if (setcursor == 10) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "----设置速度----");
        LCD_Write_String(2, 0, "10左右速度      ");
        LCD_Set_XY(2, 7);
        LCD_Write_Number(leftrightspeed / 10);
        LCD_Write_Number(leftrightspeed % 10);
        LCD_Write_String(3, 0, "11上升速度      ");
        LCD_Set_XY(3, 7);
        LCD_Write_Number(upspeed / 10);
        LCD_Write_Number(upspeed % 10);
        LCD_Write_String(4, 0, "12下降速度      ");
        LCD_Set_XY(4, 7);
        LCD_Write_Number(downspeed / 10);
        LCD_Write_Number(downspeed % 10);
      }
      if (setcursor == 13) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "----谨慎操作----");
        LCD_Write_String(2, 0, "13游戏时间      ");
        LCD_Set_XY(2, 7);
        LCD_Write_Number(gametimebase / 10);
        LCD_Write_Number(gametimebase % 10);
        LCD_Write_String(3, 0, "14下停时间      ");
        LCD_Set_XY(3, 6);
        LCD_Write_Number(downdelayset / 1000);
        LCD_Write_Number(downdelayset % 1000 / 100);
        LCD_Write_Number(downdelayset % 100 / 10);
        LCD_Write_Number(downdelayset % 10);
        LCD_Write_String(4, 0, "15给甩绳长      ");
        LCD_Set_XY(4, 7);
        LCD_Write_Number(pulllength / 10);
        LCD_Write_Number(pulllength % 10);
      }
      if (setcursor == 16) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "----谨慎操作----");
        LCD_Write_String(2, 0, "16上拉          ");
        LCD_Set_XY(2, 5);
        LCD_Write_Number(uppulllength / 10000);
        LCD_Write_Number(uppulllength % 10000 / 1000);
        LCD_Write_Number(uppulllength % 1000 / 100);
        LCD_Write_Number(uppulllength % 100 / 10);
        LCD_Write_Number(uppulllength % 10);
        LCD_Write_String(3, 0, "17售价显示      ");
        LCD_Set_XY(3, 7);
        LCD_Write_Number(uppulltime / 10);
        LCD_Write_Number(uppulltime % 10);
        LCD_Write_String(4, 0, "18上停          ");
        LCD_Set_XY(4, 5);
        LCD_Write_Number(updelaytime / 10000);
        LCD_Write_Number(updelaytime % 10000 / 1000);
        LCD_Write_Number(updelaytime % 1000 / 100);
        LCD_Write_Number(updelaytime % 100 / 10);
        LCD_Write_Number(updelaytime % 10);
      }
      if (setcursor == 19) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "------统计------");
        LCD_Write_String(2, 0, "19总收入        ");
        LCD_Set_XY(2, 5);
        LCD_Write_Number(allcoin / 10000);
        LCD_Write_Number(allcoin % 10000 / 1000);
        LCD_Write_Number(allcoin % 1000 / 100);
        LCD_Write_Number(allcoin % 100 / 10);
        LCD_Write_Number(allcoin % 10);
        LCD_Write_String(3, 0, "20礼品数        ");
        LCD_Set_XY(3, 5);
        LCD_Write_Number(alltoy / 10000);
        LCD_Write_Number(alltoy % 10000 / 1000);
        LCD_Write_Number(alltoy % 1000 / 100);
        LCD_Write_Number(alltoy % 100 / 10);
        LCD_Write_Number(alltoy % 10);
        LCD_Write_String(4, 0, "21保存退出      ");
        LCD_Set_XY(4, 5);
        LCD_Write_Number(10);
        LCD_Write_Number(10);
      }
      if (setcursor == 22) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "------设置------");
        LCD_Write_String(2, 0, "22二抓开关      ");
        LCD_Set_XY(2, 7);
        LCD_Write_Number(secondclaw % 100 / 10);
        LCD_Write_Number(secondclaw % 10);
        LCD_Set_XY(3, 7);
        LCD_Write_Number(coinbase / 10);
        LCD_Write_Number(coinbase % 10);
        LCD_Write_String(3, 0, "23几局          ");
        LCD_Set_XY(3, 7);
        LCD_Write_Number(roundbase / 10);
        LCD_Write_Number(roundbase % 10);
        LCD_Write_String(4, 0, "24偏移          ");
        LCD_Set_XY(4, 7);
        LCD_Write_Number(roundoffset / 10);
        LCD_Write_Number(roundoffset % 10);
      }
      if (setcursor == 25) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "------设置------");
        LCD_Write_String(2, 0, "25游戏模式      ");

        if (gamemode == 1)
          LCD_Write_String(2, 6, "贩卖");
        else if (gamemode == 2)
          LCD_Write_String(2, 6, "随机");

        LCD_Write_String(3, 0, "26前            ");
        LCD_Write_String(4, 0, "27后            ");
      }
      if (setcursor == 28) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "------设置------");
        LCD_Write_String(2, 0, "28左            ");
        LCD_Write_String(3, 0, "29右            ");

        LCD_Write_String(4, 0, "30程序版本      ");

        LCD_Set_XY(4, 6);
        LCD_Write_Number(version_code_z / 1000);
        LCD_Write_Number(version_code_z % 1000 / 100);
        LCD_Write_Number(version_code_z % 100 / 10);
        LCD_Write_Number(version_code_z % 10);
      }
      if (setcursor == 31) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "------设置------");
        LCD_Write_String(2, 0, "31收爪延时      ");

        sprintf(show_data, "%d", secondclaw_delay);
        LCD_Write_String(2, 6, (uc8 *)show_data);
        LCD_Write_String(3, 0, "32天车延时      ");

        sprintf(show_data, "%d", Crane_delay);
        LCD_Write_String(3, 6, (uc8 *)show_data);

        LCD_Write_String(4, 0, "33上升延时      ");
        sprintf(show_data, "%d", Rise_delay);
        LCD_Write_String(4, 6, (uc8 *)show_data);
      }
      if (setcursor == 34) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "------设置------");
        LCD_Write_String(2, 0, "34意外统计      ");

        sprintf(show_data, "%d", surprisecount);
        LCD_Write_String(2, 6, (uc8 *)show_data);
        LCD_Write_String(3, 0, "35拉甩时间      ");
        sprintf(show_data, "%d", swingpull);
        LCD_Write_String(3, 6, (uc8 *)show_data);

        LCD_Write_String(4, 0, "                ");
      }
      set_light();
    }
    if (backkeyvalue == 1) {
      backkeyvalue = 0;
      if (ENTERKEY() == 1) {
        setcursor--;
        if (setcursor == 0) setcursor = 35;
      }
      //			Clr_Scr();
      if (setcursor == 3) {
        if (ENTERKEY() == 1) {
          // delay_us(100);
          // SendCMD(0x30);
          // SendCMD(0x30);
          Clr_Scr();
          LCD_Set_XY(1, 1);
          LCD_Write_String(1, 0, "----设置参数----");
          LCD_Write_String(2, 0, "01几币一局      ");
          LCD_Set_XY(2, 7);
          LCD_Write_Number(coinbase / 10);
          LCD_Write_Number(coinbase % 10);
          LCD_Write_String(3, 0, "02售价金额      ");
          LCD_Set_XY(3, 7);
          LCD_Write_Number(outbase / 10);  // 4 4
          LCD_Write_Number(outbase % 10);
          if (displayselect == 1) {
            LCD_Write_String(4, 0, "03号码          ");
            LCD_Set_XY(4, 5);
            LCD_Write_Number(machineid / 10000);
            LCD_Write_Number(machineid % 10000 / 1000);
            LCD_Write_Number(machineid % 1000 / 100);
            LCD_Write_Number(machineid % 100 / 10);
            LCD_Write_Number(machineid % 10);
          } else {
            LCD_Write_String(4, 0, "03保夹次数      ");
            LCD_Set_XY(4, 7);
            LCD_Write_Number(clampingnum % 100 / 10);
            LCD_Write_Number(clampingnum % 10);
          }
        } else {
          if (displayselect == 1) {
            machineid = machineid - 10;
            LCD_Write_String(4, 0, "03号码          ");
            LCD_Set_XY(4, 5);
            LCD_Write_Number(machineid / 10000);
            LCD_Write_Number(machineid % 10000 / 1000);
            LCD_Write_Number(machineid % 1000 / 100);
            LCD_Write_Number(machineid % 100 / 10);
            LCD_Write_Number(machineid % 10);
          }
        }
      }
      if (setcursor == 6) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "----谨慎操作----");
        LCD_Write_String(2, 0, "04强抓          ");
        LCD_Set_XY(2, 7);
        LCD_Write_Number(groundstongclaw / 10);
        LCD_Write_Number(groundstongclaw % 10);
        LCD_Write_String(3, 0, "05中抓力        ");
        LCD_Set_XY(3, 7);
        LCD_Write_Number(strongclaw / 10);
        LCD_Write_Number(strongclaw % 10);
        LCD_Write_String(4, 0, "06弱抓力        ");
        LCD_Set_XY(4, 7);
        LCD_Write_Number(lightclaw / 10);
        LCD_Write_Number(lightclaw % 10);
      }
      if (setcursor == 9) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "----设置距离----");
        LCD_Write_String(2, 0, "07强抓时间      ");
        LCD_Set_XY(2, 6);
        LCD_Write_Number(clawgetonesteptime / 1000);
        LCD_Write_Number(clawgetonesteptime % 1000 / 100);
        LCD_Write_Number(clawgetonesteptime % 100 / 10);
        LCD_Write_Number(clawgetonesteptime % 10);
        LCD_Write_String(3, 0, "08中抓时间      ");
        LCD_Set_XY(3, 6);
        LCD_Write_Number(clawgettwosteptime / 1000);
        LCD_Write_Number(clawgettwosteptime % 1000 / 100);
        LCD_Write_Number(clawgettwosteptime % 100 / 10);
        LCD_Write_Number(clawgettwosteptime % 10);
        LCD_Write_String(4, 0, "09放线长度      ");  // 加按键
        LCD_Set_XY(4, 5);
        LCD_Write_Number(downtimeset / 10000);
        LCD_Write_Number(downtimeset % 10000 / 1000);
        LCD_Write_Number(downtimeset % 1000 / 100);
        LCD_Write_Number(downtimeset % 100 / 10);
        LCD_Write_Number(downtimeset % 10);
      }
      if (setcursor == 12) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "----设置速度----");
        LCD_Write_String(2, 0, "10左右速度      ");
        LCD_Set_XY(2, 7);
        LCD_Write_Number(leftrightspeed / 10);
        LCD_Write_Number(leftrightspeed % 10);
        LCD_Write_String(3, 0, "11上升速度      ");
        LCD_Set_XY(3, 7);
        LCD_Write_Number(upspeed / 10);
        LCD_Write_Number(upspeed % 10);
        LCD_Write_String(4, 0, "12下降速度      ");
        LCD_Set_XY(4, 7);
        LCD_Write_Number(downspeed / 10);
        LCD_Write_Number(downspeed % 10);
      }
      if (setcursor == 15) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "----谨慎操作----");
        LCD_Write_String(2, 0, "13游戏时间      ");
        LCD_Set_XY(2, 7);
        LCD_Write_Number(gametimebase / 10);
        LCD_Write_Number(gametimebase % 10);
        LCD_Write_String(3, 0, "14下停时间      ");
        LCD_Set_XY(3, 6);
        LCD_Write_Number(downdelayset / 1000);
        LCD_Write_Number(downdelayset % 1000 / 100);
        LCD_Write_Number(downdelayset % 100 / 10);
        LCD_Write_Number(downdelayset % 10);
        LCD_Write_String(4, 0, "15给甩绳长      ");
        LCD_Set_XY(4, 7);
        LCD_Write_Number(pulllength / 10);
        LCD_Write_Number(pulllength % 10);
      }
      if (setcursor == 18) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "----谨慎操作----");
        LCD_Write_String(2, 0, "16上拉          ");
        LCD_Set_XY(2, 5);
        LCD_Write_Number(uppulllength / 10000);
        LCD_Write_Number(uppulllength % 10000 / 1000);
        LCD_Write_Number(uppulllength % 1000 / 100);
        LCD_Write_Number(uppulllength % 100 / 10);
        LCD_Write_Number(uppulllength % 10);
        LCD_Write_String(3, 0, "17售价显示      ");
        LCD_Set_XY(3, 7);
        LCD_Write_Number(uppulltime / 10);
        LCD_Write_Number(uppulltime % 10);
        LCD_Write_String(4, 0, "18上停          ");
        LCD_Set_XY(4, 5);
        LCD_Write_Number(updelaytime / 10000);
        LCD_Write_Number(updelaytime % 10000 / 1000);
        LCD_Write_Number(updelaytime % 1000 / 100);
        LCD_Write_Number(updelaytime % 100 / 10);
        LCD_Write_Number(updelaytime % 10);
      }
      if (setcursor == 21) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "------统计------");
        LCD_Write_String(2, 0, "19总收入        ");
        LCD_Set_XY(2, 5);
        LCD_Write_Number(allcoin / 10000);
        LCD_Write_Number(allcoin % 10000 / 1000);
        LCD_Write_Number(allcoin % 1000 / 100);
        LCD_Write_Number(allcoin % 100 / 10);
        LCD_Write_Number(allcoin % 10);
        LCD_Write_String(3, 0, "20礼品数        ");
        LCD_Set_XY(3, 5);
        LCD_Write_Number(alltoy / 10000);
        LCD_Write_Number(alltoy % 10000 / 1000);
        LCD_Write_Number(alltoy % 1000 / 100);
        LCD_Write_Number(alltoy % 100 / 10);
        LCD_Write_Number(alltoy % 10);
        LCD_Write_String(4, 0, "21保存退出      ");
        LCD_Set_XY(4, 5);
        LCD_Write_Number(10);
        LCD_Write_Number(10);
      }
      if (setcursor == 24) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "------设置------");
        LCD_Write_String(2, 0, "22二抓开关      ");
        LCD_Set_XY(2, 7);
        LCD_Write_Number(secondclaw % 100 / 10);
        LCD_Write_Number(secondclaw % 10);
        LCD_Set_XY(3, 7);
        LCD_Write_Number(coinbase / 10);
        LCD_Write_Number(coinbase % 10);
        LCD_Write_String(3, 0, "23几局          ");
        LCD_Set_XY(3, 7);
        LCD_Write_Number(roundbase / 10);
        LCD_Write_Number(roundbase % 10);
        LCD_Write_String(4, 0, "24偏移          ");
        LCD_Set_XY(4, 7);
        LCD_Write_Number(roundoffset / 10);
        LCD_Write_Number(roundoffset % 10);
      }
      if (setcursor == 27) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "------设置------");
        LCD_Write_String(2, 0, "25游戏模式      ");

        if (gamemode == 1)
          LCD_Write_String(2, 6, "贩卖");
        else if (gamemode == 2)
          LCD_Write_String(2, 6, "随机");

        LCD_Write_String(3, 0, "26前            ");
        LCD_Write_String(4, 0, "27后            ");
      }
      if (setcursor == 30) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "------设置------");
        LCD_Write_String(2, 0, "28左            ");
        LCD_Write_String(3, 0, "29右            ");

        LCD_Write_String(4, 0, "30程序版本      ");
        LCD_Set_XY(4, 6);
        LCD_Write_Number(version_code_z / 1000);
        LCD_Write_Number(version_code_z % 1000 / 100);
        LCD_Write_Number(version_code_z % 100 / 10);
        LCD_Write_Number(version_code_z % 10);
      }
      if (setcursor == 33) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "------设置------");
        LCD_Write_String(2, 0, "31收爪延时      ");

        sprintf(show_data, "%d", secondclaw_delay);
        LCD_Write_String(2, 6, (uc8 *)show_data);
        LCD_Write_String(3, 0, "32天车延时      ");

        sprintf(show_data, "%d", Crane_delay);
        LCD_Write_String(3, 6, (uc8 *)show_data);

        LCD_Write_String(4, 0, "33上升延时      ");
        sprintf(show_data, "%d", Rise_delay);
        LCD_Write_String(4, 6, (uc8 *)show_data);
      }
      if (setcursor == 35) {
        // delay_us(100);
        // SendCMD(0x30);
        // SendCMD(0x30);
        Clr_Scr();
        LCD_Set_XY(1, 1);
        LCD_Write_String(1, 0, "------设置------");
        LCD_Write_String(2, 0, "34意外统计      ");

        sprintf(show_data, "%d", surprisecount);
        LCD_Write_String(2, 6, (uc8 *)show_data);
        LCD_Write_String(3, 0, "35拉甩时间      ");
        sprintf(show_data, "%d", swingpull);
        LCD_Write_String(3, 6, (uc8 *)show_data);

        LCD_Write_String(4, 0, "                ");
      }
      set_light();
    }

    if (rightkeyvalue == 1) {
      rightkeyvalue = 0;
      if (setcursor == 1) {
        coinbase++;
        if (coinbase > 10) coinbase = 1;
        LCD_Set_XY(2, 7);
        LCD_Set_XY(2, 7);
        LCD_Write_Number(coinbase / 10);
        LCD_Write_Number(coinbase % 10);
      }
      if (setcursor == 2) {
        outbase++;
        if (outbase > 100)  // 0,1,2,3,4
          outbase = 0;
        LCD_Set_XY(3, 7);
        LCD_Write_Number(outbase / 10);
        LCD_Write_Number(outbase % 10);
      }
      if (setcursor == 3) {
        if (displayselect == 1) {
          if (ENTERKEY() == 1)
            machineid++;
          else
            machineid = machineid + 100;
          LCD_Set_XY(4, 5);
          LCD_Write_Number(machineid / 10000);
          LCD_Write_Number(machineid % 10000 / 1000);
          LCD_Write_Number(machineid % 1000 / 100);
          LCD_Write_Number(machineid % 100 / 10);
          LCD_Write_Number(machineid % 10);
        } else {
          clampingnum++;
          LCD_Set_XY(4, 7);
          LCD_Write_Number(clampingnum % 100 / 10);
          LCD_Write_Number(clampingnum % 10);
        }
      }
      if (setcursor == 4) {
        groundstongclaw = groundstongclaw + 5;
        if (groundstongclaw > 95)  // 30-95
          groundstongclaw = 30;
        LCD_Set_XY(2, 7);
        LCD_Write_Number(groundstongclaw / 10);
        LCD_Write_Number(groundstongclaw % 10);
      }
      if (setcursor == 5) {
        strongclaw++;
        if (strongclaw > 95) strongclaw = 0;
        LCD_Set_XY(3, 7);
        LCD_Write_Number(strongclaw / 10);
        LCD_Write_Number(strongclaw % 10);
      }
      if (setcursor == 6) {
        lightclaw++;
        if (lightclaw > 90)  // 20-90
          lightclaw = 0;
        LCD_Set_XY(4, 7);
        LCD_Write_Number(lightclaw / 10);
        LCD_Write_Number(lightclaw % 10);
      }
      if (setcursor == 7)  // 底部抓取高度
      {
        fixedpointing = 0;
        clawgetonesteptime = clawgetonesteptime + 50;
        if (clawgetonesteptime > 3000)  // 100-1000ms
          clawgetonesteptime = 100;
        LCD_Set_XY(2, 6);
        LCD_Write_Number(clawgetonesteptime / 1000);
        LCD_Write_Number(clawgetonesteptime % 1000 / 100);
        LCD_Write_Number(clawgetonesteptime % 100 / 10);
        LCD_Write_Number(clawgetonesteptime % 10);
      }
      if (setcursor == 8)  // 抓取高度
      {
        fixedpointing = 0;
        clawgettwosteptime = clawgettwosteptime + 50;
        if (clawgettwosteptime > 4500)  // 600-4400ms
          clawgettwosteptime = 600;
        LCD_Set_XY(3, 6);
        LCD_Write_Number(clawgettwosteptime / 1000);
        LCD_Write_Number(clawgettwosteptime % 1000 / 100);
        LCD_Write_Number(clawgettwosteptime % 100 / 10);
        LCD_Write_Number(clawgettwosteptime % 10);
      }
      if (setcursor == 9)  // 拖拽时间
      {
        downtimeset = downtimeset + 100;
        if (downtimeset > 2000) downtimeset = 2000;
        LCD_Set_XY(4, 5);
        LCD_Write_Number(downtimeset / 10000);
        LCD_Write_Number(downtimeset % 10000 / 1000);
        LCD_Write_Number(downtimeset % 1000 / 100);
        LCD_Write_Number(downtimeset % 100 / 10);
        LCD_Write_Number(downtimeset % 10);
      }

      // 增加
      if (setcursor == 10) {
        leftrightspeed = leftrightspeed + 5;
        if (leftrightspeed > 95)  // 10-90
          leftrightspeed = 10;
        LCD_Set_XY(2, 7);
        LCD_Write_Number(leftrightspeed / 10);
        LCD_Write_Number(leftrightspeed % 10);
      }

      if (setcursor == 11)  // 上升速度
      {
        upspeed++;
        if (upspeed > 9)  // 2-9
          upspeed = 2;
        LCD_Set_XY(3, 7);
        LCD_Write_Number(upspeed / 10);
        LCD_Write_Number(upspeed % 10);
      }
      if (setcursor == 12)  // 下降速度
      {
        downspeed++;
        if (downspeed > 10)  // 2-9
          downspeed = 2;
        LCD_Set_XY(4, 7);
        LCD_Write_Number(downspeed / 10);
        LCD_Write_Number(downspeed % 10);
      }

      if (setcursor == 13)  // 游戏时间
      {
        gametimebase++;
        if (gametimebase > 40)  // 16-30秒
          gametimebase = 16;
        LCD_Set_XY(2, 7);
        LCD_Write_Number(gametimebase / 10);
        LCD_Write_Number(gametimebase % 10);
      }
      if (setcursor == 14) {
        downdelayset = downdelayset + 50;
        if (downdelayset > 2000) downdelayset = 2000;
        LCD_Set_XY(3, 6);
        LCD_Write_Number(downdelayset / 1000);
        LCD_Write_Number(downdelayset % 1000 / 100);
        LCD_Write_Number(downdelayset % 100 / 10);
        LCD_Write_Number(downdelayset % 10);
      }
      if (setcursor == 15) {
        pulllength++;
        if (pulllength > 10)  // 0,1,2,3,4
          pulllength = 0;
        LCD_Set_XY(4, 7);
        LCD_Write_Number(pulllength / 10);
        LCD_Write_Number(pulllength % 10);
      }

      if (setcursor == 16) {
        uppulllength = uppulllength + 10;
        if (uppulllength > 2000) uppulllength = 0;
        LCD_Set_XY(2, 5);
        LCD_Write_Number(uppulllength / 10000);
        LCD_Write_Number(uppulllength % 10000 / 1000);
        LCD_Write_Number(uppulllength % 1000 / 100);
        LCD_Write_Number(uppulllength % 100 / 10);
        LCD_Write_Number(uppulllength % 10);
      }
      if (setcursor == 17) {
        uppulltime = uppulltime + 1;
        if (uppulltime == 3) uppulltime = 1;
        LCD_Set_XY(3, 7);
        LCD_Write_Number(uppulltime / 10);
        LCD_Write_Number(uppulltime % 10);
      }
      if (setcursor == 18) {
        updelaytime = updelaytime + 10;
        if (updelaytime > 2000) updelaytime = 0;
        LCD_Set_XY(4, 5);
        LCD_Write_Number(updelaytime / 10000);
        LCD_Write_Number(updelaytime % 10000 / 1000);
        LCD_Write_Number(updelaytime % 1000 / 100);
        LCD_Write_Number(updelaytime % 100 / 10);
        LCD_Write_Number(updelaytime % 10);
      }
      if (setcursor == 22) {
        secondclaw = secondclaw + 1;
        if (secondclaw == 2) secondclaw = 0;
        LCD_Set_XY(2, 7);
        LCD_Write_Number(secondclaw / 10);
        LCD_Write_Number(secondclaw % 10);
      }
      if (setcursor == 23) {
        roundbase++;  // 1-10
        if (roundbase > 30) roundbase = 5;
        LCD_Set_XY(3, 7);
        LCD_Set_XY(3, 7);
        LCD_Write_Number(roundbase / 10);
        LCD_Write_Number(roundbase % 10);
      }
      if (setcursor == 24) {
        roundoffset++;
        if (roundoffset > 5)  // 2,3,4
          roundoffset = 2;
        LCD_Set_XY(4, 7);
        LCD_Write_Number(roundoffset / 10);
        LCD_Write_Number(roundoffset % 10);
      }
      if (setcursor == 25) {
        gamemode++;
        if (gamemode >= 3)  // 2,3,4
          gamemode = 1;
        if (gamemode == 1)
          LCD_Write_String(2, 6, "贩卖");
        else if (gamemode == 2)
          LCD_Write_String(2, 6, "随机");
      }
      if (setcursor == 26) {
        LCD_Write_String(3, 0, "26前            ");
      }
      if (setcursor == 27) {
        LCD_Write_String(4, 0, "27后            ");
      }
      if (setcursor == 28) {
        LCD_Write_String(2, 0, "28左            ");
      }
      if (setcursor == 29) {
        LCD_Write_String(3, 0, "29右            ");
      }
      if (setcursor == 30) {
        LCD_Write_String(4, 0, "30程序版本      ");
      }

      if (setcursor == 31) {
        secondclaw_delay += 10;
        if (secondclaw_delay > 1000) secondclaw_delay = 0;

        LCD_Write_String(2, 0, "31收爪延时      ");
        sprintf(show_data, "%d", secondclaw_delay);
        LCD_Write_String(2, 6, (uc8 *)show_data);
      }
      if (setcursor == 32) {
        Crane_delay += 10;
        if (Crane_delay > 500) Crane_delay = 0;

        LCD_Write_String(3, 0, "32天车延时      ");
        sprintf(show_data, "%d", Crane_delay);
        LCD_Write_String(3, 6, (uc8 *)show_data);
      }
      if (setcursor == 33) {
        Rise_delay += 10;
        if (Rise_delay > 1000) Rise_delay = 0;

        LCD_Write_String(4, 0, "33上升延时      ");
        sprintf(show_data, "%d", Rise_delay);
        LCD_Write_String(4, 6, (uc8 *)show_data);
      }
      if (setcursor == 35) {
        swingpull += 50;
        if (swingpull > 500) swingpull = 0;

        LCD_Write_String(3, 0, "35拉甩时间      ");
        sprintf(show_data, "%d", swingpull);
        LCD_Write_String(3, 6, (uc8 *)show_data);
      }
    }
    if (leftkeyvalue == 1) {
      leftkeyvalue = 0;
      if (setcursor == 1) {
        coinbase--;
        if (coinbase < 1) coinbase = 10;
        LCD_Set_XY(2, 7);
        LCD_Set_XY(2, 7);
        LCD_Write_Number(coinbase / 10);
        LCD_Write_Number(coinbase % 10);
      }
      if (setcursor == 2) {
        outbase--;
        if (outbase == 0)  // 0,1,2,3,4
          outbase = 100;
        LCD_Set_XY(3, 7);
        LCD_Write_Number(outbase / 10);
        LCD_Write_Number(outbase % 10);
      }
      if (setcursor == 3) {
        if (displayselect == 1) {
          if (ENTERKEY() == 1)
            machineid--;
          else
            machineid = machineid - 100;
          LCD_Set_XY(4, 5);
          LCD_Write_Number(machineid / 10000);
          LCD_Write_Number(machineid % 10000 / 1000);
          LCD_Write_Number(machineid % 1000 / 100);
          LCD_Write_Number(machineid % 100 / 10);
          LCD_Write_Number(machineid % 10);
        } else {
          clampingnum--;
          LCD_Set_XY(4, 7);
          LCD_Write_Number(clampingnum % 100 / 10);
          LCD_Write_Number(clampingnum % 10);
        }
      }
      if (setcursor == 4) {
        groundstongclaw = groundstongclaw - 5;
        if (groundstongclaw <= 0)  // 30-95
          groundstongclaw = 95;
        LCD_Set_XY(2, 7);
        LCD_Write_Number(groundstongclaw / 10);
        LCD_Write_Number(groundstongclaw % 10);
      }
      if (setcursor == 5) {
        strongclaw--;
        if (strongclaw < 1) strongclaw = 95;
        LCD_Set_XY(3, 7);
        LCD_Write_Number(strongclaw / 10);
        LCD_Write_Number(strongclaw % 10);
      }
      if (setcursor == 6) {
        lightclaw--;
        if (lightclaw < 1)  // 20-90
          lightclaw = 95;
        LCD_Set_XY(4, 7);
        LCD_Write_Number(lightclaw / 10);
        LCD_Write_Number(lightclaw % 10);
      }
      if (setcursor == 7)  // 底部抓取高度
      {
        fixedpointing = 0;
        clawgetonesteptime = clawgetonesteptime - 50;
        if (clawgetonesteptime < 100)  // 100-1000ms
          clawgetonesteptime = 3000;
        LCD_Set_XY(2, 6);
        LCD_Write_Number(clawgetonesteptime / 1000);
        LCD_Write_Number(clawgetonesteptime % 1000 / 100);
        LCD_Write_Number(clawgetonesteptime % 100 / 10);
        LCD_Write_Number(clawgetonesteptime % 10);
      }
      if (setcursor == 8)  // 抓取高度
      {
        fixedpointing = 0;
        clawgettwosteptime = clawgettwosteptime - 50;
        if (clawgettwosteptime > 4500)  // 600-4400ms
          clawgettwosteptime = 600;
        LCD_Set_XY(3, 6);
        LCD_Write_Number(clawgettwosteptime / 1000);
        LCD_Write_Number(clawgettwosteptime % 1000 / 100);
        LCD_Write_Number(clawgettwosteptime % 100 / 10);
        LCD_Write_Number(clawgettwosteptime % 10);
      }
      if (setcursor == 9) {
        downtimeset = downtimeset - 100;
        if (downtimeset < 50) downtimeset = 50;
        LCD_Set_XY(4, 5);
        LCD_Write_Number(downtimeset / 10000);
        LCD_Write_Number(downtimeset % 10000 / 1000);
        LCD_Write_Number(downtimeset % 1000 / 100);
        LCD_Write_Number(downtimeset % 100 / 10);
        LCD_Write_Number(downtimeset % 10);
      }

      // 增加
      if (setcursor == 10) {
        leftrightspeed = leftrightspeed - 5;
        if (leftrightspeed < 10)  // 10-90
          leftrightspeed = 90;
        LCD_Set_XY(2, 7);
        LCD_Write_Number(leftrightspeed / 10);
        LCD_Write_Number(leftrightspeed % 10);
      }
      if (setcursor == 11)  // 上升速度
      {
        upspeed--;
        if (upspeed < 2)  // 2-9
          upspeed = 9;
        LCD_Set_XY(3, 7);
        LCD_Write_Number(upspeed / 10);
        LCD_Write_Number(upspeed % 10);
      }
      if (setcursor == 12)  // 下降速度
      {
        downspeed--;
        if (downspeed == 0)  // 2-9
          downspeed = 10;
        LCD_Set_XY(4, 7);
        LCD_Write_Number(downspeed / 10);
        LCD_Write_Number(downspeed % 10);
      }

      if (setcursor == 13)  // 游戏时间
      {
        gametimebase--;
        if (gametimebase < 10)  // 16-30秒
          gametimebase = 41;
        LCD_Set_XY(2, 7);
        LCD_Write_Number(gametimebase / 10);
        LCD_Write_Number(gametimebase % 10);
      }
      if (setcursor == 14) {
        downdelayset = downdelayset - 50;
        if (downdelayset > 2000) downdelayset = 0;
        LCD_Set_XY(3, 6);
        LCD_Write_Number(downdelayset / 1000);
        LCD_Write_Number(downdelayset % 1000 / 100);
        LCD_Write_Number(downdelayset % 100 / 10);
        LCD_Write_Number(downdelayset % 10);
      }
      if (setcursor == 15) {
        pulllength--;
        if (pulllength == 0)  // 0,1,2,3,4
          pulllength = 10;
        LCD_Set_XY(4, 7);
        LCD_Write_Number(pulllength / 10);
        LCD_Write_Number(pulllength % 10);
      }

      if (setcursor == 16) {
        if (uppulllength <= 0) uppulllength = 2000;
        uppulllength = uppulllength - 10;
        if (uppulllength) LCD_Set_XY(2, 5);
        LCD_Write_Number(uppulllength / 10000);
        LCD_Write_Number(uppulllength % 10000 / 1000);
        LCD_Write_Number(uppulllength % 1000 / 100);
        LCD_Write_Number(uppulllength % 100 / 10);
        LCD_Write_Number(uppulllength % 10);
      }
      if (setcursor == 17) {
        if (uppulltime == 0) uppulltime = 2;
        uppulltime = uppulltime - 1;
        LCD_Set_XY(3, 7);
        LCD_Write_Number(uppulltime / 10);
        LCD_Write_Number(uppulltime % 10);
      }
      if (setcursor == 18) {
        if (updelaytime <= 0) updelaytime = 2000;
        updelaytime = updelaytime - 10;
        LCD_Set_XY(4, 5);
        LCD_Write_Number(updelaytime / 10000);
        LCD_Write_Number(updelaytime % 10000 / 1000);
        LCD_Write_Number(updelaytime % 1000 / 100);
        LCD_Write_Number(updelaytime % 100 / 10);
        LCD_Write_Number(updelaytime % 10);
      }
      if (setcursor == 22) {
        if (secondclaw <= 0) secondclaw = 2;
        secondclaw = secondclaw - 1;

        LCD_Set_XY(2, 7);
        LCD_Write_Number(secondclaw / 10);
        LCD_Write_Number(secondclaw % 10);
      }
      if (setcursor == 23) {
        roundbase--;  // 1-10
        if (roundbase == 0) roundbase = 20;
        LCD_Set_XY(3, 7);
        LCD_Set_XY(3, 7);
        LCD_Write_Number(roundbase / 10);
        LCD_Write_Number(roundbase % 10);
      }
      if (setcursor == 24) {
        roundoffset--;
        if (roundoffset < 2)  // 2,3,4
          roundoffset = 4;
        LCD_Set_XY(4, 7);
        LCD_Write_Number(roundoffset / 10);
        LCD_Write_Number(roundoffset % 10);
      }
      if (setcursor == 25) {
        gamemode--;
        if (gamemode == 0)  // 2,3,4
          gamemode = 2;
        if (gamemode == 1)
          LCD_Write_String(2, 6, "贩卖");
        else if (gamemode == 2)
          LCD_Write_String(2, 6, "随机");
      }
      if (setcursor == 26) {
        LCD_Write_String(3, 0, "26前            ");
      }
      if (setcursor == 27) {
        LCD_Write_String(4, 0, "27后            ");
      }
      if (setcursor == 28) {
        LCD_Write_String(2, 0, "28左            ");
      }
      if (setcursor == 29) {
        LCD_Write_String(3, 0, "29右            ");
      }
      if (setcursor == 30) {
        LCD_Write_String(4, 0, "30程序版本      ");
      }
      if (setcursor == 31) {
        secondclaw_delay -= 10;
        if (secondclaw_delay == 0 || secondclaw_delay >= 1000) secondclaw_delay = 1000;

        LCD_Write_String(2, 0, "31收爪延时      ");
        sprintf(show_data, "%d", secondclaw_delay);
        LCD_Write_String(2, 6, (uc8 *)show_data);
      }
      if (setcursor == 32) {
        Crane_delay -= 10;
        if (Crane_delay == 0 || Crane_delay >= 500) Crane_delay = 500;

        LCD_Write_String(3, 0, "32天车延时      ");
        sprintf(show_data, "%d", Crane_delay);
        LCD_Write_String(3, 6, (uc8 *)show_data);
      }
      if (setcursor == 33) {
        Rise_delay -= 10;
        if (Rise_delay == 0 || Rise_delay >= 1000) Rise_delay = 1000;

        LCD_Write_String(4, 0, "33上升延时      ");
        sprintf(show_data, "%d", Rise_delay);
        LCD_Write_String(4, 6, (uc8 *)show_data);
      }
      if (setcursor == 35) {
        swingpull -= 50;
        if (swingpull == 0 || swingpull > 500) swingpull = 500;

        LCD_Write_String(3, 0, "35拉甩时间      ");
        sprintf(show_data, "%d", swingpull);
        LCD_Write_String(3, 6, (uc8 *)show_data);
      }
    }

    if (setcursor == 1 || setcursor == 2 || setcursor == 3 || setcursor == 7 || setcursor == 8 || setcursor == 9) CLAWOFF();
    //					if(backkey ==1)
    //					{
    //						backkey =0;
    //						setcursor--;
    //						if(setcursor ==0)
    //							setcursor =9;
    //						if(setcursor==3)
    //						{
    //							SendCMD(0x30);
    //							SendCMD(0x30);
    //							LCD_Set_XY(1,1);
    //							LCD_Write_String(1,0,"------设置------");
    //							LCD_Write_String(2,0,"A.几币一局->");//
    //							LCD_Write_String(3,0,"B.几局中--->");//
    //							LCD_Write_String(4,0,"C.强抓力度->");//
    //						}
    //						if(setcursor ==6)
    //						{
    //							SendCMD(0x30);
    //							SendCMD(0x30);
    //							LCD_Set_XY(1,1);
    //							LCD_Write_String(1,0,"------设置------");
    //							LCD_Write_String(2,0,"D.弱抓力度->");//
    //							LCD_Write_String(3,0,"E.抓取高度->");//
    //							LCD_Write_String(4,0,"F.甩抓拉抓->");//
    //						}
    //						if(setcursor ==9)
    //						{
    //							SendCMD(0x30);
    //							SendCMD(0x30);
    //							LCD_Set_XY(1,1);
    //							LCD_Write_String(1,0,"------设置------");
    //							LCD_Write_String(2,0,"G.总收入->  ");
    //							LCD_Write_String(3,0,"H.出礼数->  ");
    //							LCD_Write_String(4,0,"I.保存退出");
    //						}
    //						set_light();
    //					}
    // 参数读写
    if ((setcursor == 21) && (ENTERKEY() == 0)) {
      // SendCMD(0x3e);
      // delay_us(100);
      // SendCMD(0x05);
      // LcmClearBMP();
      // delay_us(100);
      // SendCMD(0x30);  // 8 位介面，基本指令集
      // delay_us(100);
      // SendCMD(0x30);  // 8 位介面，基本指令集
      // LcmClearTXT();  // 8 位介面，基本指令集
      // delay_us(100);
      // delay_us(100);
      // SendCMD(0x30);  // 8 位介面，基本指令集
      // delay_us(100);
      // SendCMD(0x30);  // 8 位介面，基本指令集
      // delay_us(100);
      // SendCMD(0x30);
      // SendCMD(0x30);
      // Clr_Scr();
      Lcd_Init();
      LCD_Set_XY(1, 0);
      LCD_Write_String(1, 0, "正在保存退出");

      buf22[0] = hex2chr(secondclaw / 10);
      buf22[1] = hex2chr(secondclaw % 10);
      Write_continuity(secondclawaddr, secondclawlen, buf22);  // 写二抓开关

      buf22[0] = hex2chr(clampingnum / 10);
      buf22[1] = hex2chr(clampingnum % 10);
      Write_continuity(clampingnumaddr, clampingnumlen, buf22);  // 写保夹次数

      buf22[0] = hex2chr(coinbase / 10);
      buf22[1] = hex2chr(coinbase % 10);
      Write_continuity(coinbaseaddr, coinbaselen, buf22);  // 写投币基数
      buf22[0] = hex2chr(roundbase / 10);
      buf22[1] = hex2chr(roundbase % 10);
      Write_continuity(roundbaseaddr, roundbaselen, buf22);  // 写圈轮
      buf22[0] = hex2chr(lightclaw / 10);
      buf22[1] = hex2chr(lightclaw % 10);
      Write_continuity(lightclawaddr, lightclawlen, buf22);  // 写中抓
      buf22[0] = hex2chr(strongclaw / 10);
      buf22[1] = hex2chr(strongclaw % 10);
      Write_continuity(strongclawaddr, strongclawlen, buf22);  // 写强抓

      buf22[0] = hex2chr(lostclaw / 10);
      buf22[1] = hex2chr(lostclaw % 10);
      Write_continuity(lostclawaddr, lostclawlen, buf22);  // 写弱抓
      buf22[0] = hex2chr(groundstongclaw / 10);
      buf22[1] = hex2chr(groundstongclaw % 10);
      Write_continuity(groundstongclawaddr, groundstongclawlen, buf22);  // 写底部强抓

      buf22[0] = hex2chr(gametimebase / 10);
      buf22[1] = hex2chr(gametimebase % 10);
      Write_continuity(gametimebaseaddr, gametimebaselen, buf22);  // 写时间
      buf22[0] = hex2chr(roundoffset / 10);
      buf22[1] = hex2chr(roundoffset % 10);
      Write_continuity(roundoffsetaddr, roundoffsetlen, buf22);  // 写编译量

      buf44[0] = hex2chr(swingpull / 1000);
      buf44[1] = hex2chr(swingpull % 1000 / 100);
      buf44[2] = hex2chr(swingpull % 100 / 10);
      buf44[3] = hex2chr(swingpull % 10);
      Write_continuity(swingpulladdr, swingpulllen, buf44);  // 写甩拉

      buf22[0] = hex2chr(fixedpoint / 10);
      buf22[1] = hex2chr(fixedpoint % 10);
      Write_continuity(fixedpointaddr, fixedpointlen, buf22);  // 写定点标志
      buf22[0] = hex2chr(upspeed / 10);
      buf22[1] = hex2chr(upspeed % 10);
      Write_continuity(upspeedaddr, upspeedlen, buf22);  // 写上升速度

      buf22[0] = hex2chr(pulllength / 10);
      buf22[1] = hex2chr(pulllength % 10);
      Write_continuity(pulllengthsetaddr, pulllengthsetlen, buf22);  // 写放绳子

      buf22[0] = hex2chr(downspeed / 10);
      buf22[1] = hex2chr(downspeed % 10);
      Write_continuity(downspeedaddr, downspeedlen, buf22);  // 写下降速度

      buf44[0] = hex2chr(outbase / 1000);
      buf44[1] = hex2chr(outbase % 1000 / 100);
      buf44[2] = hex2chr(outbase % 100 / 10);
      buf44[3] = hex2chr(outbase % 10);
      Write_continuity(outbaseaddr, outbaselen, buf44);

      buf22[0] = hex2chr(leftrightspeed / 10);
      buf22[1] = hex2chr(leftrightspeed % 10);
      Write_continuity(leftrightspeedaddr, leftrightspeedlen, buf22);  // 写数据

      buf22[0] = hex2chr(gamemode / 10);
      buf22[1] = hex2chr(gamemode % 10);
      Write_continuity(gamemodeaddr, gamemodelen, buf22);  // 写游戏模式

      buf55[0] = hex2chr(front_back_point_fixedpoint / 10000);
      buf55[1] = hex2chr(front_back_point_fixedpoint % 10000 / 1000);
      buf55[2] = hex2chr(front_back_point_fixedpoint % 1000 / 100);
      buf55[3] = hex2chr(front_back_point_fixedpoint % 100 / 10);
      buf55[4] = hex2chr(front_back_point_fixedpoint % 10);
      Write_continuity(front_back_point_fixedpointaddr, front_back_point_fixedpointlen, buf55);  // 前后坐标

      buf55[0] = hex2chr(right_left_point_fixedpoint / 10000);
      buf55[1] = hex2chr(right_left_point_fixedpoint % 10000 / 1000);
      buf55[2] = hex2chr(right_left_point_fixedpoint % 1000 / 100);
      buf55[3] = hex2chr(right_left_point_fixedpoint % 100 / 10);
      buf55[4] = hex2chr(right_left_point_fixedpoint % 10);
      Write_continuity(right_left_point_fixedpointaddr, right_left_point_fixedpointlen, buf55);  // 左右坐标

      buf44[0] = hex2chr(clawgettwosteptime / 1000);
      buf44[1] = hex2chr(clawgettwosteptime % 1000 / 100);
      buf44[2] = hex2chr(clawgettwosteptime % 100 / 10);
      buf44[3] = hex2chr(clawgettwosteptime % 10);
      Write_continuity(clawgettwosteptimeaddr, clawgettwosteptimelen, buf44);  // 渐变时间

      buf44[0] = hex2chr(clawgetonesteptime / 1000);
      buf44[1] = hex2chr(clawgetonesteptime % 1000 / 100);
      buf44[2] = hex2chr(clawgetonesteptime % 100 / 10);
      buf44[3] = hex2chr(clawgetonesteptime % 10);
      Write_continuity(clawgetonesteptimeaddr, clawgetonesteptimelen, buf44);  // 强抓时间

      buf44[0] = hex2chr(clawgetthreesteptime / 1000);
      buf44[1] = hex2chr(clawgetthreesteptime % 1000 / 100);
      buf44[2] = hex2chr(clawgetthreesteptime % 100 / 10);
      buf44[3] = hex2chr(clawgetthreesteptime % 10);
      Write_continuity(clawgetthreesteptimeaddr, clawgetthreesteptimelen, buf44);  // 拖拽时间

      buf44[0] = hex2chr(downdelayset / 1000);
      buf44[1] = hex2chr(downdelayset % 1000 / 100);
      buf44[2] = hex2chr(downdelayset % 100 / 10);
      buf44[3] = hex2chr(downdelayset % 10);
      Write_continuity(downdelaysetaddr, downdelaysetlen, buf44);

      buf55[0] = hex2chr(downtimeset / 10000);
      buf55[1] = hex2chr(downtimeset % 10000 / 1000);
      buf55[2] = hex2chr(downtimeset % 1000 / 100);
      buf55[3] = hex2chr(downtimeset % 100 / 10);
      buf55[4] = hex2chr(downtimeset % 10);
      Write_continuity(downtimesetaddr, downtimesetlen, buf55);

      buf55[0] = hex2chr(machineid / 10000);
      buf55[1] = hex2chr(machineid % 10000 / 1000);
      buf55[2] = hex2chr(machineid % 1000 / 100);
      buf55[3] = hex2chr(machineid % 100 / 10);
      buf55[4] = hex2chr(machineid % 10);
      Write_continuity(machineidaddr, machineidlen, buf55);  // 机台编号

      buf55[0] = hex2chr(updelaytime / 10000);
      buf55[1] = hex2chr(updelaytime % 10000 / 1000);
      buf55[2] = hex2chr(updelaytime % 1000 / 100);
      buf55[3] = hex2chr(updelaytime % 100 / 10);
      buf55[4] = hex2chr(updelaytime % 10);
      Write_continuity(updelaytimeaddr, updelaytimelen, buf55);  // 出奖//updelaytime上停500   uppulltime上放      uppulllength

      buf22[0] = hex2chr(uppulltime / 10);
      buf22[1] = hex2chr(uppulltime % 10);
      Write_continuity(uppulltimeaddr, uppulltimelen, buf22);

      buf55[0] = hex2chr(uppulllength / 10000);
      buf55[1] = hex2chr(uppulllength % 10000 / 1000);
      buf55[2] = hex2chr(uppulllength % 1000 / 100);
      buf55[3] = hex2chr(uppulllength % 100 / 10);
      buf55[4] = hex2chr(uppulllength % 10);
      Write_continuity(uppulllengthaddr, uppulllengthlen, buf55);

      buf44[0] = hex2chr(secondclaw_delay / 1000);
      buf44[1] = hex2chr(secondclaw_delay % 1000 / 100);
      buf44[2] = hex2chr(secondclaw_delay % 100 / 10);
      buf44[3] = hex2chr(secondclaw_delay % 10);
      Write_continuity(secondclaw_delay_addr, secondclaw_delay_len, buf44);

      buf44[0] = hex2chr(Crane_delay / 1000);
      buf44[1] = hex2chr(Crane_delay % 1000 / 100);
      buf44[2] = hex2chr(Crane_delay % 100 / 10);
      buf44[3] = hex2chr(Crane_delay % 10);
      Write_continuity(Crane_delay_addr, Crane_delay_len, buf44);

      buf44[0] = hex2chr(Rise_delay / 1000);
      buf44[1] = hex2chr(Rise_delay % 1000 / 100);
      buf44[2] = hex2chr(Rise_delay % 100 / 10);
      buf44[3] = hex2chr(Rise_delay % 10);
      Write_continuity(Rise_delay_addr, Rise_delay_len, buf44);

      //			sprintf(show_data, "%d", secondclaw_delay);
      //			Write_continuity(secondclaw_delay_zaddr,secondclaw_delay_zlen,(u8 *)show_data);
      //
      //			sprintf(show_data, "%d", Crane_delay);
      //			Write_continuity(Crane_delay_zaddr,Crane_delay_zlen,(u8 *)show_data);

      Read_continuity(machineidaddr, machineidlen, machineidcode);
      mymemcpy(machineidcode, (u8 *)&tickinfo[3], 5);        // 机器编号	{"[t|80002|000|F0]#$-$#"};
      mymemcpy(machineidcode, (u8 *)&gsmsetdatabuff[3], 5);  // 拷贝数据
      mymemecys(gsmgetdatabuff, machineidcode, 3, 5);        //[g|00001|1|01|000020|12345678|sign]#$-$#gsmrealtimecoinindatabuff
      mymemecys(gsmsetdatabuff, machineidcode, 3, 5);
      mymemecys(gsmrealtimecoinindatabuff, machineidcode, 3, 5);
      mymemecys(gsmrealtimetoyoutdatabuff, machineidcode, 3, 5);

      Read_continuity(downtimesetaddr, downtimesetlen, buf55);  // 下降时间
      downtimeset = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);
      //	LCD_Write_String1(3,3,5,buf55);//显示机台号
      Read_continuity(coininaddr, coininlen, buf22);
      coinin = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
      Read_continuity(coinbaseaddr, coinbaselen, buf22);
      coinbase = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
      Read_continuity(roundbaseaddr, roundbaselen, buf22);
      roundbase = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
      Read_continuity(lightclawaddr, lightclawlen, buf22);
      lightclaw = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

      Read_continuity(groundstongclawaddr, groundstongclawlen, buf22);
      groundstongclaw = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

      Read_continuity(strongclawaddr, strongclawlen, buf22);
      strongclaw = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
      Read_continuity(gametimebaseaddr, gametimebaselen, buf22);
      gametimebase = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
      Read_continuity(roundoffsetaddr, roundoffsetlen, buf22);
      roundoffset = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
      Read_continuity(swingpulladdr, swingpulllen, buf44);
      swingpull = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);
      ;
      Read_continuity(fixedpointaddr, fixedpointlen, buf22);
      fixedpoint = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
      Read_continuity(upspeedaddr, upspeedlen, buf22);
      upspeed = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

      Read_continuity(leftrightspeedaddr, leftrightspeedlen, buf22);
      leftrightspeed = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

      Read_continuity(downspeedaddr, downspeedlen, buf22);
      downspeed = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

      Read_continuity(lostclawaddr, lostclawlen, buf22);
      lostclaw = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

      Read_continuity(surprisecountaddr, surprisecountlen, buf55);
      surprisecount = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);

      Read_continuity(allcoinaddr, allcoinlen, buf55);
      allcoin = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);

      Read_continuity(alltoyaddr, alltoylen, buf55);
      alltoy = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);

      Read_continuity(front_back_point_fixedpointaddr, front_back_point_fixedpointlen, buf55);
      front_back_point_fixedpoint = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);
      Read_continuity(right_left_point_fixedpointaddr, right_left_point_fixedpointlen, buf55);
      right_left_point_fixedpoint = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);

      Read_continuity(clawgettwosteptimeaddr, clawgettwosteptimelen, buf44);
      clawgettwosteptime = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);

      Read_continuity(clawgetonesteptimeaddr, clawgetonesteptimelen, buf44);
      clawgetonesteptime = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);

      Read_continuity(clawgetthreesteptimeaddr, clawgetthreesteptimelen, buf44);
      clawgetthreesteptime = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);

      Read_continuity(downdelaysetaddr, downdelaysetlen, buf44);
      downdelayset = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);
      //	if(downdelayset<100||downdelayset>3000)
      //	{
      //		Write_continuity(downdelaysetaddr,downdelaysetlen,"0500");//底部延迟
      //	}
      Read_continuity(downtimesetaddr, downtimesetlen, buf55);
      downtimeset = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);

      Read_continuity(difficultsetaddr, difficultsetlen, buf22);  // 出奖
      difficultset = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

      Read_continuity(gamemodeaddr, gamemodelen, buf22);
      gamemode = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

      Read_continuity(outbaseaddr, outbaselen, buf44);
      outbase = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);

      Read_continuity(uppulltimeaddr, uppulltimelen, buf22);
      uppulltime = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

      Read_continuity(clampingnumaddr, clampingnumlen, buf22);
      clampingnum = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

      Read_continuity(Crane_delay_addr, Crane_delay_len, buf44);
      Crane_delay = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);

      Read_continuity(secondclaw_delay_addr, secondclaw_delay_len, buf44);
      secondclaw_delay = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);

      Read_continuity(Rise_delay_addr, Rise_delay_len, buf44);
      Rise_delay = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);

      // while (LEFTSW() == 1) {
      //   if (Time2_trup_cnt <= 6)
      //     LEFTSTOP();
      //   else
      //     LEFTRUN();
      // }
      // LEFTSTOP();
      // // FRONTRUN();//回行
      // while (FRONTSW() == 1) {
      //   if (Time2_trup_cnt <= 6)
      //     FRONTSTOP();
      //   else
      //     FRONTRUN();
      // }
      // FRONTSTOP();

      test_downtime = 0;
      setfinishing = 0;  // 保存退出
      Delay1ms(1000);
      setcursor = 0;
      enterkeyvalue = 0;
    }
  }
  // 返回显示
  Lcd_Init();
  gameround();
  displayinit(0);
  // SendCMD(0x30);
  // SendCMD(0x30);  // 8 位介面，基本指令集
}
