#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "adc.h"
#include "bsp_stm32_flash.h"
#include "define.h"
#include "extern.h"
#include "game_app.h"
#include "key_app.h"
#include "lcd.h"
#include "led_app.h"
#include "net_app.h"
#include "rc04v.h"
#include "serial_app.h"
#include "setgame.h"
#include "wifi.h"

extern uint8_t g_serial_sn;
extern uint8_t control_mode;
extern uint8_t free_play_num;
extern uint8_t free_mode_flag;
extern SERIAL_CoinInfoTypeDef coin_info;

__IO u8 reconnect_flag = 0;

u8 Second1 = 0;
u8 Second2 = 0;
u8 Second3 = 0;
u8 connecting = 0;
u8 sendbusy = 0;
u8 nowififlag = 0;

u8 enterkeyvalue = 0;
u8 setkeyvalue = 0;
u8 frontkeyvalue = 0;
u8 rightkeyvalue = 0;
u8 leftkeyvalue = 0;
u8 backkeyvalue = 0;

u8 fixedpointing = 0;

u8 setlongkey = 0;
u8 gamestatus = 0;
u8 beginning = 0;
u8 gametime = 0;
u8 machinedisable = 1;

u8 gameruntime = 0;
u16 pulllengthtime = 0;

u8 gamenum = 0;

u8 claw = 0;
u8 setfinishing = 0;
u8 setcursor = 0;
u8 gametimeflash = 0;
u8 twonull[4] = {"00\0"};
u8 fournull[6] = {"0000\0"};
u8 fivenull[7] = {"00000\0"};

u8 gsmupdatabuff[67] = {"[u|00001|0|000002|12345678|00000000000000000000000000000000]#$-$#\0"};
u8 gsmcoindatabuff[63] = {"[e|00001|4|01|12345678|00000000000000000000000000000000]#$-$#\0"};
u8 gsmsetdatabuff[70] = {"[q|00001|2|01|000002|12345678|00000000000000000000000000000000]#$-$#\0"};
u8 gsmsetyoudatabuff[70] = {"[s|00001|3|01|000002|12345678|00000000000000000000000000000000]#$-$#\0"};
u8 gsmgetdatabuff[70] = {"[g|00001|1|01|000020|12345678|00000000000000000000000000000000]#$-$#\0"};
//[n|00001|7|01|12345678|sign]#$-$#
u8 gsmrealtimecoinindatabuff[66] = {"[m|00001|6|00001|12345678|00000000000000000000000000000000]#$-$#\0"};
u8 gsmrealtimetoyoutdatabuff[66] = {"[n|00001|7|00001|12345678|00000000000000000000000000000000]#$-$#\0"};
u8 gsmrealtimefreeoutdatabuff[66] = {"[f|00001|8|00001|12345678|00000000000000000000000000000000]#$-$#\0"};
//////////////////?��??????/////////////////

u8 coinin;  // ?????
u8 coininaddr = 0;
u8 coininlen = 2;

u8 coinbase;  // ?????????
u8 coinbaseaddr = 6;
u8 coinbaselen = 2;
u8 coinbasevalue = 25;

u8 roundbase;  // ???????
u8 roundbaseaddr = 12;
u8 roundbaselen = 2;
u8 roundbasevalue = 7;

u8 lightclaw;  // ???????
u8 lightclawaddr = 18;
u8 lightclawlen = 2;

u8 strongclaw;  // ??????
u8 strongclawaddr = 24;
u8 strongclawlen = 2;

u8 gametimebase;  // ???
u8 gametimebaseaddr = 30;
u8 gametimebaselen = 2;

u8 roundoffset;  // ?????
u8 roundoffsetaddr = 36;
u8 roundoffsetlen = 2;

u16 surprisecount;  // ???????
u8 surprisecountaddr = 42;
u8 surprisecountlen = 5;

u16 allcoin;  // ??????
u8 allcoinaddr = 48;
u8 allcoinlen = 5;

u16 alltoy;  // ????????
u8 alltoyaddr = 54;
u8 alltoylen = 5;

u16 swingpull = 0;  // ?????
u8 swingpulladdr = 60;
u8 swingpulllen = 4;

u8 fixedpoint;  // ??????????
u8 fixedpointaddr = 66;
u8 fixedpointlen = 2;

u8 upspeed;  // ???????
u8 upspeedaddr = 72;
u8 upspeedlen = 2;

u8 downspeed;  // ??????
u8 downspeedaddr = 78;
u8 downspeedlen = 2;

u16 front_back_point_fixedpoint;          // ???????????????
u8 front_back_point_fixedpointaddr = 84;  // ???????????????????????
u8 front_back_point_fixedpointlen = 5;    // ???????????????????????

u16 right_left_point_fixedpoint;          // ????????????????
u8 right_left_point_fixedpointaddr = 90;  // ???????????????????????
u8 right_left_point_fixedpointlen = 5;    // ???????????????????????

u16 clawgettwosteptime;  // ??????????
u8 clawgettwosteptimeaddr = 96;
u8 clawgettwosteptimelen = 4;
u16 clawgettwosteptimevalue = 957;

u8 factaryset;  // ??????????
u8 factarysetaddr = 102;
u8 factarysetlen = 2;

u16 machineid;        // ???????
u8 machineidcode[5];  //={"10055"};
u8 machineidaddr = 108;
u8 machineidlen = 5;

u16 clawgetonesteptime;  // ?????????????  ??????
u8 clawgetonesteptimeaddr = 114;
u8 clawgetonesteptimelen = 4;
u16 clawgetonesteptimevalue = 1000;

u16 clawgetthreesteptime;  // ??????????????
u8 clawgetthreesteptimeaddr = 120;
u8 clawgetthreesteptimelen = 4;
u16 clawgetthreesteptimevalue = 1000;

u8 lostclaw;  // ???????
u8 lostclawaddr = 126;
u8 lostclawlen = 2;

u8 groundstongclaw;  // ?????????
u8 groundstongclawaddr = 132;
u8 groundstongclawlen = 2;

u8 leftrightspeed;  // ???????
u8 leftrightspeedaddr = 138;
u8 leftrightspeedlen = 2;

u16 downtimeset;  // ???????
u8 downtimesetaddr = 144;
u8 downtimesetlen = 5;

u16 downdelayset;  // ??????
u8 downdelaysetaddr = 150;
u8 downdelaysetlen = 4;

u8 difficultset;  // ???
u8 difficultsetaddr = 156;
u8 difficultsetlen = 2;

u8 pulllength;  // ???????????????????
u8 pulllengthsetaddr = 162;
u8 pulllengthsetlen = 2;

// ??????????????????????????��??????????
u16 updelaytime;  // ??????
u8 updelaytimeaddr = 168;
u8 updelaytimelen = 5;

u16 uppulllength;  // ????
u8 uppulllengthaddr = 174;
u8 uppulllengthlen = 4;

u16 uppulltime;  //
u8 uppulltimeaddr = 180;
u8 uppulltimelen = 2;

u8 outbase;  //
u8 outbaseaddr = 186;
u8 outbaselen = 4;

u8 outcount;  //
u8 outcountaddr = 192;
u8 outcountlen = 4;

u8 clampingdate = 0;
u8 clampingnum;
u8 clampingnumaddr = 198;
u8 clampingnumlen = 2;

u8 secondclaw;
u8 secondclawaddr = 204;
u8 secondclawlen = 2;

u8 gamemode;
u8 gamemodeaddr = 210;
u8 gamemodelen = 2;

u16 version_code;
u8 version_codeaddr = 216;
u8 version_codelen = 4;

u16 version_code_z;
u8 version_code_zaddr = 222;
u8 version_code_zlen = 4;

u16 secondclaw_delay;
u16 secondclaw_delay_addr = 228;
u8 secondclaw_delay_len = 4;

u16 Crane_delay;
u16 Crane_delay_addr = 234;
u8 Crane_delay_len = 4;

u16 Rise_delay;
u16 Rise_delay_addr = 240;
u8 Rise_delay_len = 4;

u8 wifi_config_flag;
u8 wifi_config_flag_addr = 246;
u8 wifi_config_flag_len = 1;

u16 free_mode_toy;
u8 free_mode_toy_addr = 248;
u8 free_mode_toy_len = 4;

u16 wifi_ssid_len = 8;
u16 wifi_password_len = 10;
uint8_t wifi_ssid[128] = {"AMAZING\0"};
uint8_t wifi_password[128] = {"789789789\0"};

u8 pulllengthbuff[4] = {"00\0"};       // ?????????1-30    1
u8 coinbasebuff[4] = {"00\0"};         // ?????????1-30    1
u8 roundbasebuff[4] = {"00\0"};        // ???????1-99      2
u8 lostclawbuff[4] = {"00\0"};         // ???????10-99       3
u8 groundstongclawbuff[4] = {"00\0"};  // ?????????10-99   4
u8 lightclawbuff[4] = {"00\0"};        // ?????????10-99     5
u8 strongclawbuff[4] = {"00\0"};       // ??????10-99       6

u8 gametimebasebuff[4] = {"00\0"};  // ??????10-60        7
u8 roundoffsetbuff[4] = {"00\0"};   // ?????0-10           8
u8 swingpullbuff[4] = {"00\0"};     // ?????0/1            9
u8 factarysetbuff[4] = {"00\0"};    // ??????????0/1      10
u8 machineidbuff[7] = {"00000\0"};  // ???????00000-99999        11

u8 upspeedbuff[4] = {"00\0"};         // ???????10-99       12
u8 downspeedbuff[4] = {"00\0"};       // ??????10-99       13
u8 leftrightspeedbuff[4] = {"00\0"};  // ???????10-99       14

u8 fixedpointbuff[4] = {"00\0"};                      // ??????????0/1       15
u8 front_back_point_fixedpointbuff[7] = {"00000\0"};  // ???????????????1000-50000   16
u8 right_left_point_fixedpointbuff[7] = {"00000\0"};  // ????????????????1000-50000   17

u8 clawgetonesteptimebuff[7] = {"00000\0"};    // ?????????????  ??????100-3000    18
u8 clawgettwosteptimebuff[7] = {"00000\0"};    // ??????????100-5000                    19
u8 clawgetthreesteptimebuff[7] = {"00000\0"};  // ??????????????100-5000                20

u8 difficultsetbuff[4] = {"00\0"};  // ??????????????100-5000                20
// u8 downbuff[7] ={"00000\0"};    //??????????????100-5000                20

u8 gamemodebuff[4] = {"00\0"};  // ?????????1-2

u8 outbasebuff[7] = {"00000\0"};

u8 clampingnumbuff[4] = {"00\0"};

u8 uppulltimebuff[4] = {"00\0"};

u8 outsentorflag = 0;
u8 gameoverflag = 0;

u16 downtime = 0;
u8 teststatue = 0;

// u8 buf[17] = { 0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x10,0x11,0x12,0x13,0x14,0x15,0x16};

u8 buf2[14] = {"000000000000\0"};
u8 buf44[6] = {"0000\0"};
u8 buf55[7] = {"00000\0"};
u8 buf22[4] = {"00\0"};

u8 linkloop = 1;
u8 switchstatus[4] = {"9999"};

u8 linkflash = 0;

u8 reszer = 0;
u8 screen = 0;
u8 counten = 0;
u8 coininen = 0;
u8 coinined = 0;
u8 userscan = 0;
u8 userpayed = 0;

u8 keysun = 100;
u8 neton = 0;
u8 resqr = 0;

u16 off_line_time = 0;

u8 combusy = 0;

u8 nettime = 0;
u8 netenable = 0;
u8 testflag = 0;
u8 clawpower[6] = {0};

u8 custom_led_flag = 0;
uint16_t custom_led_on_time = 0;
uint16_t custom_led_off_time = 0;

u8 RX_buffer2[8] = {0x7E, 0xFF, 0x06, 0x06, 0x00, 0x00, 0x02, 0xEF};  //
u8 RX_buffer1[8] = {0x7E, 0xFF, 0x06, 0x09, 0x00, 0x00, 0x03, 0xEF};  //

// ???????
u8 POWERONMUSIC[8] = {0x7E, 0xFF, 0x06, 0x03, 0x00, 0x00, 0x01, 0xEF};
u8 CLAWDOWNMUSIC[8] = {0x7E, 0xFF, 0x06, 0x03, 0x00, 0x00, 0x02, 0xEF};
u8 CLAWMUSIC[8] = {0x7E, 0xFF, 0x06, 0x03, 0x00, 0x00, 0x03, 0xEF};
u8 CLAWUPMUSIC[8] = {0x7E, 0xFF, 0x06, 0x03, 0x00, 0x00, 0x04, 0xEF};
u8 COININMUSIC[8] = {0x7E, 0xFF, 0x06, 0x03, 0x00, 0x00, 0x05, 0xEF};
u8 WARMMUSIC[8] = {0x7E, 0xFF, 0x06, 0x03, 0x00, 0x00, 0x06, 0xEF};
u8 WINNINGMUSIC[8] = {0x7E, 0xFF, 0x06, 0x03, 0x00, 0x00, 0x07, 0xEF};
u8 LIGHTMUSIC[8] = {0x7E, 0xFF, 0x06, 0x03, 0x00, 0x00, 0x08, 0xEF};
u8 HEAVYMUSIC[8] = {0x7E, 0xFF, 0x06, 0x03, 0x00, 0x00, 0x09, 0xEF};
// u8  HEAVYMUSIC[] =   {0x7E,0xFF, 0x06, 0x03, 0x00, 0x00, 0x09, 0xEF};

// ?????????????????????
u8 POWERONFLAG = 0;
u8 CLAWDOWNFLAG = 0;
u8 CLAWUPFLAG = 0;
u8 CLAWTOYFLAG = 0;
u8 COININFLAG = 0;
u8 COININTESTFLAG = 0;
u8 GAMEWAITFLAG = 0;
u8 WARMFLAG = 0;
u8 WINFLAG = 0;
u8 GAMEINGFLAG = 0;
u8 GAMEBACKFLAG = 0;

volatile u8 cointime = 0;

u8 reconnect = 1;

u8 gift_pulse_flag = 0;

u8 wifiseten = 0;

// u8 Cardsend[18] = {0x00,0x00,0xAF,0x00,0x06,0x00,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01,0x01};

u8 dispdelay = 0;
volatile u8 cointimeH = 12;
volatile u8 cointimeL = 6;

u8 qrok = 0;
u8 disp_QR = 0;

u8 roundnum[120] = {0};  //
u8 roundadd[120] = {0};  // ??????????????????3??
u8 random_mod_point;

u8 toynum[120] = {0};
u8 roundround = 0;
u8 creatgameroundlock = 0;  // ????????????
u8 outsentortemp = 0;

u16 delaytime1 = 500;
u16 delaytime2 = 730;

u16 upstoptime = 0;
u16 downstoptime = 0;
u16 linelength = 0;

u8 buf3[10] = {"0000000000"};
u8 buf200[200] = {"0000000000"};

u8 rssi_value[3] = {'L', 'F', '\0'};

extern u16 get_rssi_time;
extern u8 rssi_display;
extern u32 display_refresh_time;
extern u32 display_display_time;
extern u16 wait_time;
extern u8 uart1_rx_status;

int main(void) {
  u8 tmp;
  //////////////???????//////////////////
  // SCB->VTOR = FLASH_APP1_ADDR;
  Platform_Init();
  LED_App_Init();
  LEDON1();
  LEDON2();
  coinpoweroff();
  LED_App_SetLed1FlashOn(500, 300, 5000, 1);
  LED_App_SetLed2Flash(500, 300, 5000, 1);
  Delay1ms(300);
  gameround();

  Lcd_Init();
  Delay1ms(500);
  Clr_Scr();
  Delay1ms(1000);
  //	????????
  // Write_continuity(version_code_zaddr,version_code_zlen,"0152");
  Read_continuity(machineidaddr, machineidlen, buf55);
  machineid = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);

  // LCD_Write_String(1, 2, "??????");
  // LCD_Write_String(4, 5, "v");
  // while (1) {
  //   /* code */
  // }

  Read_continuity(factarysetaddr, factarysetlen, buf22);
  factaryset = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
  Read_continuity(machineidaddr, machineidlen, machineidcode);
  mymemcpy(machineidcode, (u8 *)&tickinfo[3], 5);
  mymemcpy(machineidcode, (u8 *)&gsmsetdatabuff[3], 5);
  mymemecys(gsmgetdatabuff, machineidcode, 3, 5);  //[g|00001|1|01|000020|12345678|sign]#$-$#gsmrealtimecoinindatabuff
  mymemecys(gsmupdatabuff, machineidcode, 3, 5);
  mymemecys(gsmsetdatabuff, machineidcode, 3, 5);
  mymemecys(gsmsetyoudatabuff, machineidcode, 3, 5);
  mymemecys(gsmrealtimecoinindatabuff, machineidcode, 3, 5);
  mymemecys(gsmrealtimetoyoutdatabuff, machineidcode, 3, 5);
  Read_continuity(machineidaddr, machineidlen, buf55);  // ??????
  machineid = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);

  Read_continuity(updelaytimeaddr, updelaytimelen, buf55);  // ????//updelaytime???500   uppulltime???      uppulllength
  updelaytime = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);
  Read_continuity(uppulllengthaddr, uppulllengthlen, buf55);
  uppulllength = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);
  if (BACKKEY() == 0 && LEFTKEY() == 0 && ENTERKEY() == 0) {
    LCD_Write_String(1, 0, "????????");
    //		Write_continuity(0,200,buf200);//???
    // ??????��
    Write_continuity(machineidaddr, machineidlen, "21023");  // ��?????
    // Write_continuity(coininaddr,coininlen,"50");//???       0
    Write_continuity(coinbaseaddr, coinbaselen, "02");    // ????????  6
    Write_continuity(roundbaseaddr, roundbaselen, "12");  // ??????12

    Write_continuity(lightclawaddr, lightclawlen, "02");        // ???18
    Write_continuity(strongclawaddr, strongclawlen, "05");      // ??24
    Write_continuity(gametimebaseaddr, gametimebaselen, "19");  // ???30
    Write_continuity(roundoffsetaddr, roundoffsetlen, "04");    // ??????36

    Write_continuity(swingpulladdr, swingpulllen, "01");    // ???60
    Write_continuity(fixedpointaddr, fixedpointlen, "01");  // ??????66
    Write_continuity(upspeedaddr, upspeedlen, "04");        // ????????72
    Write_continuity(downspeedaddr, downspeedlen, "05");    // ??????78

    Write_continuity(front_back_point_fixedpointaddr, front_back_point_fixedpointlen, "33000");  // ???????84
    Write_continuity(right_left_point_fixedpointaddr, right_left_point_fixedpointlen, "33000");  // ????????90
    Write_continuity(clawgettwosteptimeaddr, clawgettwosteptimelen, "1000");                     // ??????????96
    Write_continuity(factarysetaddr, factarysetlen, "99");                                       // ??????????  102
                                                                                                 // 108???
    Write_continuity(clawgetonesteptimeaddr, clawgetonesteptimelen, "1000");                     // ??????????114
    Write_continuity(clawgetthreesteptimeaddr, clawgetthreesteptimelen, "0100");                 // ?????????????120
    Write_continuity(lostclawaddr, lostclawlen, "20");                                           // ??126
    Write_continuity(groundstongclawaddr, groundstongclawlen, "70");                             // ?????132
    Write_continuity(leftrightspeedaddr, leftrightspeedlen, "35");                               // ???????138
    Write_continuity(downtimesetaddr, downtimesetlen, "01400");                                  // ???????144
    Write_continuity(downdelaysetaddr, downdelaysetlen, "0100");                                 // ?????????150
    Write_continuity(difficultsetaddr, difficultsetlen, "00");                                   // ????156

    Write_continuity(pulllengthsetaddr, pulllengthsetlen, "01");  // ��??????162

    Write_continuity(updelaytimeaddr, updelaytimelen, "00070");    // 168  ????//updelaytime???500   uppulltime???      uppulllength
    Write_continuity(uppulllengthaddr, uppulllengthlen, "00060");  // 174
    Write_continuity(uppulltimeaddr, uppulltimelen, "00001");      // 180

    Write_continuity(outbaseaddr, outbaselen, "0016");        // 186
    Write_continuity(outcountaddr, outcountlen, "0000");      // 192
    Write_continuity(clampingnumaddr, clampingnumlen, "03");  // 198
    Write_continuity(secondclawaddr, secondclawlen, "00");    // ��???????204
    Write_continuity(gamemodeaddr, gamemodelen, "01");        // 210
  }

  if (FRONTKEY() == 0 && LEFTKEY() == 0 && ENTERKEY() == 0)  // ?????????99????????????��??????
  // if(1)
  {
    LCD_Write_String(1, 0, "????????????");

    // Write_continuity(roundbaseaddr,roundbaselen,"15");//??????
    Write_continuity(alltoyaddr, alltoylen, "00000");                // ????   54
    Write_continuity(allcoinaddr, allcoinlen, "00000");              // ?????48
    Write_continuity(surprisecountaddr, surprisecountlen, "00000");  // ???????  42
    Write_continuity(coininaddr, coininlen, "00");                   // ??? 0
    Write_continuity(wifi_config_flag_addr, 1, 0);
  }
  // ????��???????????
  outcount = Single_Read_Device(outcountaddr);

  Read_continuity(secondclawaddr, secondclawlen, buf22);
  secondclaw = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

  Read_continuity(clampingnumaddr, clampingnumlen, buf22);
  clampingnum = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

  Read_continuity(updelaytimeaddr, updelaytimelen, buf55);  // ????//updelaytime???500   uppulltime???      uppulllength
  updelaytime = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);

  Read_continuity(uppulltimeaddr, uppulltimelen, buf22);
  uppulltime = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

  Read_continuity(uppulllengthaddr, uppulllengthlen, buf55);
  uppulllength = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);

  Read_continuity(downtimesetaddr, downtimesetlen, buf55);  // ??????
  downtimeset = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);
  //		LCD_Write_String1(3,3,5,buf55);//????????
  Read_continuity(coininaddr, coininlen, buf22);
  coinin = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

  Read_continuity(outbaseaddr, outbaselen, buf44);
  outbase = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);

  Read_continuity(coinbaseaddr, coinbaselen, buf22);
  coinbase = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
  Read_continuity(roundbaseaddr, roundbaselen, buf22);
  roundbase = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
  Read_continuity(lightclawaddr, lightclawlen, buf22);
  lightclaw = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

  Read_continuity(groundstongclawaddr, groundstongclawlen, buf22);
  groundstongclaw = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

  Read_continuity(pulllengthsetaddr, pulllengthsetlen, buf22);  // ????????
  pulllength = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

  Read_continuity(strongclawaddr, strongclawlen, buf22);
  strongclaw = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
  Read_continuity(gametimebaseaddr, gametimebaselen, buf22);
  gametimebase = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
  Read_continuity(roundoffsetaddr, roundoffsetlen, buf22);
  roundoffset = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);
  Read_continuity(swingpulladdr, swingpulllen, buf44);
  swingpull = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);
  ;  // 8
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

  Read_continuity(gamemodeaddr, gamemodelen, buf22);
  gamemode = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

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
  //		Write_continuity(downdelaysetaddr,downdelaysetlen,"0500");//??????
  //	}
  Read_continuity(downtimesetaddr, downtimesetlen, buf55);
  downtimeset = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);

  Read_continuity(difficultsetaddr, difficultsetlen, buf22);  // ????
  difficultset = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

  Read_continuity(version_code_zaddr, version_code_zlen, buf44);
  version_code_z = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);

  Read_continuity(secondclaw_delay_addr, secondclaw_delay_len, buf44);
  secondclaw_delay = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);

  Read_continuity(Crane_delay_addr, Crane_delay_len, buf44);
  Crane_delay = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);

  Read_continuity(Rise_delay_addr, Rise_delay_len, buf44);
  Rise_delay = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);

  Read_continuity(free_mode_toy_addr, free_mode_toy_len, buf55);
  free_mode_toy = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);

  //	if(downtimeset<1000||downtimeset>5000)
  //	{
  //		Write_continuity(downtimesetaddr,downtimesetlen,"01000");//???????
  //	}
  //	downtimeset =2000;

  //	??????????
  while (ENTERKEY() == 0) {
    LCD_Set_XY(2, 1);
    LCD_Write_Number(FRONTKEY());
    LCD_Set_XY(4, 1);
    LCD_Write_Number(BACKKEY());
    LCD_Set_XY(3, 0);
    LCD_Write_Number(LEFTKEY());
    LCD_Set_XY(3, 2);
    LCD_Write_Number(RIGHTKEY());
    LCD_Set_XY(4, 7);
    LCD_Write_Number(ENTERKEY());
    LCD_Set_XY(1, 3);
    LCD_Write_Number(SETKEY());
    LCD_Set_XY(1, 1);
    LCD_Write_Number(OUTSENTOR());
    LCD_Set_XY(1, 2);
    LCD_Write_Number(COININ());
    LCD_Set_XY(2, 6);
    LCD_Write_Number(GROUNDSW());
    LCD_Set_XY(4, 6);
    LCD_Write_Number(DOWNSW());
    LCD_Set_XY(2, 4);
    LCD_Write_Number(LEFTSW());
    LCD_Set_XY(1, 5);
    LCD_Write_Number(FRONTSW());
    LCD_Set_XY(3, 5);
    LCD_Write_Number(BACKSW());
  }
  while (SETKEY2() == 0) {
    LCD_Set_XY(2, 1);
    LCD_Write_Number(FRONTKEY());
    if (FRONTKEY() == 0) {
      FRONTRUN();
    } else {
      FRONTSTOP();
    }
    if (DOWNSW() == 0) {
      DOWNRUN();
    } else {
      DOWNSTOP();
    }
    if (LEFTSW() == 0) {
      LEFTRUN();
    } else {
      LEFTSTOP();
    }
    if (GROUNDSW() == 0) {
      UPRUN();
    } else {
      UPSTOP();
    }
    if (BACKSW() == 0) {
      BACKRUN();
    } else {
      BACKSTOP();
    }
    if (OUTSENTOR() == 0) {
      RIGHTRUN();
    } else {
      RIGHTSTOP();
    }

    LCD_Set_XY(4, 1);
    LCD_Write_Number(BACKKEY());
    LCD_Set_XY(3, 0);
    LCD_Write_Number(LEFTKEY());
    LCD_Set_XY(3, 2);
    LCD_Write_Number(RIGHTKEY());
    LCD_Set_XY(4, 7);
    LCD_Write_Number(ENTERKEY());
    LCD_Set_XY(1, 3);
    LCD_Write_Number(SETKEY());
    LCD_Set_XY(1, 1);
    LCD_Write_Number(OUTSENTOR());
    LCD_Set_XY(1, 2);
    LCD_Write_Number(COININ());
    LCD_Set_XY(2, 6);
    LCD_Write_Number(GROUNDSW());
    LCD_Set_XY(4, 6);
    LCD_Write_Number(DOWNSW());
    LCD_Set_XY(2, 4);
    LCD_Write_Number(LEFTSW());
    LCD_Set_XY(1, 5);
    LCD_Write_Number(FRONTSW());
    LCD_Set_XY(3, 5);
    LCD_Write_Number(BACKSW());
  }
  if (!SETKEY()) {
    NET_ConfigurationTask();
  }
  setlongkey = 0;
  if (version_code_z != 207) {
    Write_continuity(version_code_zaddr, version_code_zlen, "0207");
    Read_continuity(version_code_zaddr, version_code_zlen, buf44);
    version_code_z = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);
    // Write_continuity(wifi_config_flag_addr,1,"0");
  }
  LCD_Write_String(1, 2, "??????");
  LCD_Write_String(4, 5, "v");
  LCD_Write_Number(version_code_z % 1000 / 100);
  Write_Char(1, 0x2e);
  LCD_Write_Number(version_code_z % 100 / 10);
  Write_Char(1, 0x2e);
  LCD_Write_Number(version_code_z % 10);
  //	WIFI?????��
  WIFIEN();      // ???
  WIFIRSTOFF();  // ??????????
  Time_10ms_cnt = 100;
  while (Time_10ms_cnt);
  WIFIRSTON();  // ??????????
  // while(1);
  Time_10ms_cnt = 500;
  while (Time_10ms_cnt);
  // Read_continuity(wifi_ssid_addr,8,wifi_ssid);
  // Read_continuity(wifi_password_addr,10,wifi_password);

  Read_continuity(wifi_config_flag_addr, 1, &wifi_config_flag);
  if (wifi_config_flag != 'e') {
    /* code */

#ifdef HARDWARE_V1
    // UART1_SendString("AT+CWMODE?\r\n");
    // Delay1ms(1000);
    UART1_SendString("AT+CWMODE=1\r\n");
    Delay1ms(1000);
    // UART1_SendString("AT+CWJAP=\"AMAZING\",\"789789789\"\r\n");//???
    // UART1_SendString("AT+CWJAP=\"SQJ_DW1\",\"sqjdw12345678\"\r\n");//??????��??
    // UART1_SendString("AT+CWJAP=\"SQWW\",\"18178280203\"\r\n");  // ????
    UART1_SendString("AT+CWJAP=\"HAOTER1\",\"281508888\"\r\n");  // ????
                                                                 // UART1_SendString("AT+CWJAP=\"HAOTER\",\"888888888\"\r\n");  // ????
#endif
#ifdef HARDWARE_V0
    // UART3_SendString("AT+CWMODE?\r\n");
    // Delay1ms(1000);
    UART3_SendString("AT+CWMODE=1\r\n");
    Delay1ms(1000);
    // UART3_SendString("AT+CWJAP=\"AMAZING\",\"789789789\"\r\n");//???
    // UART3_SendString("AT+CWJAP=\"SQJ_DW1\",\"sqjdw12345678\"\r\n");//??????��??
    // UART3_SendString("AT+CWJAP=\"SQWW\",\"18178280203\"\r\n");  // ????
    UART3_SendString("AT+CWJAP=\"HAOTER1\",\"281508888\"\r\n");  // ????
                                                                 // UART3_SendString("AT+CWJAP=\"HAOTER\",\"888888888\"\r\n");  // ????
#endif
#ifdef HARDWARE_V2
    // UART2_SendString("AT+CWMODE?\r\n");
    // Delay1ms(1000);
    UART2_SendString("AT+CWMODE=1\r\n");
    Delay1ms(1000);
    // UART2_SendString("AT+CWJAP=\"AMAZING\",\"789789789\"\r\n");//???
    // UART2_SendString("AT+CWJAP=\"SQJ_DW1\",\"sqjdw12345678\"\r\n");//??????��??
    // UART2_SendString("AT+CWJAP=\"SQWW\",\"18178280203\"\r\n");  // ????
    UART2_SendString("AT+CWJAP=\"HAOTER1\",\"281508888\"\r\n");  // ????
                                                                 // UART2_SendString("AT+CWJAP=\"HAOTER\",\"888888888\"\r\n");  // ????
#endif
  }

  /////////?????????/////////
  // reconnect = 1;
  neton = 88;

  Tick_ReqKeep_OnLine_time = 1;
  //	????	GPIO12	?????	GPIO	??

  //	????	GPIO12	?????
  //	UART3_SendString("AT+SYSIOSETCFG=12,3,1\r\n");//at+wiow
  //	Time_10ms_cnt=100;
  //	while(Time_10ms_cnt);

  //	UART3_SendString("AT+SYSGPIODIR=12,0\r\n");//at+wiow
  //	Time_10ms_cnt=100;
  //	while(Time_10ms_cnt);
  //	UART3_SendString("AT+SYSGPIOREAD=12\r\n");//at+wiow
  //
  //	while(1);

  //	Write_continuity(machineidaddr,machineidlen,"03017");//��????
  //	????????��?????????��???????????????��  coinbaseaddr  coinbasevalue clawgettwosteptimeaddr    clawgettwosteptimevalue
  displayinit(0);

  //	????????
  WINFLAG = 0;
  COININFLAG = 0;
  coinpoweron();
  outsentorflag = 0;
  KEY_Init();

  while (1) {
    // GAME1_GO:
    SERIAL_Task();
    if (custom_led_flag) {
      custom_led_flag = 0;
      LED_App_SetLed1FlashOn(custom_led_on_time, custom_led_off_time, 5000, 1);
      LED_App_SetLed2Flash(custom_led_on_time, custom_led_off_time, 5000, 1);
    }
    GEME_Task2();
    // if (control_mode) {
    //   goto GAME1_GO;
    // }
    if (!control_mode) {
      /////////////////////////????///////////////////////////
      if (breakdown > 0 && breakdown <= 4) {
        breakdown = 5;
        coinpoweroff();
        Clr_Scr();
        Delay1ms(50);
        if (breakdown == 1)
          LCD_Write_String(2, 2, (uc8 *)"???????");
        else if (breakdown == 2)
          LCD_Write_String(2, 2, (uc8 *)"????????");
        else if (breakdown == 3)
          LCD_Write_String(2, 2, (uc8 *)"??��????");
        else if (breakdown == 4)
          LCD_Write_String(2, 0, (uc8 *)"??��????????");
        //			breakdown = 0;
        //			return 0;
        gameoverflag = 1;
        gamestatus = 0;
        beginning = 0;
        gametime = 0;
        gameruntime = 0;
        gametimeflash = 1;
        winflag_tim = 2;
        machinedisable = 0;
      }
      // 		if(updata_flag[0] == 1)
      // 		{

      // 			mymemecyup(gsmupdatabuff, RX1_buffer, 11, 6);
      // 			mymemecyup(gsmupdatabuff, RX1_buffer, 27, 32);
      // 			mymemecyl(RX1_buffer, buf44, 13, 4);

      // 			UART1_SendString("AT+CIPSEND=65\r\n");//??????gsmupdatabuff[68]={"[u|00001|0|000002|12345678|00000000000000000000000000000000]#$-$#"};
      // 			Time_10ms_cnt=10;
      // 			while(Time_10ms_cnt);
      // 			GsmSend((char *)gsmupdatabuff);

      // 			UART1_SendString("AT+CIPCLOSE\r\n");
      // 			Time_10ms_cnt=10;
      // 			while(Time_10ms_cnt);

      // //			buf44[0]= hex2chr(version_code/1000);
      // //			buf44[1]= hex2chr(version_code%1000/100);
      // //			buf44[2]= hex2chr(version_code%100/10);
      // //			buf44[3]= hex2chr(version_code%10);
      // 			Write_continuity(version_codeaddr,version_codelen,buf44);

      // 			STM32_FLASH_Read(FLASH_DATA_ADDR, updata_flag, 4);
      // 			updata_flag[0] = 1;
      // 			iap_write_appbin(FLASH_DATA_ADDR, updata_flag, 4);
      // 			iap_write_appbin(FLASH_DATA_ADDR+2048,(u16 *)gsmupdatabuff, sizeof(gsmupdatabuff));

      // 			updata_flag[0] = 0;

      // 			if(((*(vu32*)(STM32_FLASH_BASE+4))&0xFF000000)==0x08000000)//?��?????0X08XXXXXX.
      // 			{
      // 				iap_load_app(STM32_FLASH_BASE);//???FLASH APP????
      // 			}
      // 		}

      if (beginning == 0 && setlongkey == 1) {
        setgame();
      }
      if (machinedisable == 0)
        coinpoweroff();
      else
        coinpoweron();

      ///////////////////////////????///////////////////////////
      if (((coinin >= coinbase && coinin > 0) || (free_play_num > 0)) && beginning == 0 && (RIGHTKEY() == 0 || BACKKEY() == 0) && machinedisable >= 1 &&
          !control_mode)  // 1?��???��??????
      {
        winflag_tim = 1;
        // Platform_Init();
        // ?????

        // ?????????????

        // ??????AI???????????????????????????????????????????AI????

        // ????

        // ???????????????????��???????????????????----??????????
        if (gameoverflag == 1 && roundround > clampingnum && roundround >= 3) {
          gameoverflag = 0;
          if (roundnum[roundround - 1] == 1 && toynum[roundround - 1] == 0)  // ??
          {
            if (!(roundadd[roundround - 1] == 1 && roundadd[roundround - 2] == 1 && roundadd[roundround - 3] == 1)) {
              roundadd[roundround] = 1;
              roundnum[roundround] = 1;
            }
          } else
            roundadd[roundround - 1] = 0;
        }
        right_left_point = 0;
        front_back_point = 0;
        enterkeyvalue = 0;
        CLAWDOWNFLAG = 0;
        CLAWUPFLAG = 0;
        CLAWTOYFLAG = 0;
        GAMEWAITFLAG = 0;
        WINFLAG = 0;
        GAMEINGFLAG = 0;
        GAMEBACKFLAG = 0;
        clawpower[0] = strongclaw;                                   // ?
        clawpower[1] = (strongclaw + lightclaw) / 2;                 // ??
        clawpower[2] = lightclaw;                                    // ??
        clawpower[3] = (strongclaw - (strongclaw + lightclaw) / 2);  // ?????
        clawpower[4] = (strongclaw - lightclaw);                     // ?????
        clawpower[5] = ((strongclaw + lightclaw) / 2 - lightclaw);   // ?��???
        //			if(machinedisable ==2)
        //			{
        //				if(Second1%10 <1)  //0
        //					clawgettwosteptime =clawgettwosteptime +200;
        //				else if( Second1%10 <4 &&Second1%10 >=1)  //123
        //					clawgettwosteptime =clawgettwosteptime +100;
        //				else if( Second1%10 <7 &&Second1%10 >=4)//456
        //					clawgettwosteptime =clawgettwosteptime -100;
        //			}
        if (creatgameroundlock == 0) {
          creatgameroundlock = 1;
          gameround();
        }
        beginning = 1;  // ?????????
        gamenum += coinbase;
        if (gamenum > outbase + (clampingnum - 1) * coinbase) {
          gamenum = coinbase;
        }
        roundround++;
        // if(roundround>105)//105??????????????????????
        // {
        // 	roundround =1;
        // 	gameround();//?????????
        // }
        if (roundround > roundbase + roundoffset) {  // 20240115
          gameround();
        }
        if (free_play_num > 0) {
          free_mode_flag = 1;
          // free_play_num--;
          // SERIAL_SendFreeNum(free_play_num);
          // LCD_Write_String(3, 2, "Free:");
          // LCD_Set_XY(3, 5);
          // LCD_Write_Number(free_play_num / 10);
          // LCD_Write_Number(free_play_num % 10);
        } else {
          free_mode_flag = 0;
          coinin = coinin - coinbase;
          buf22[0] = hex2chr(coinin / 10);
          buf22[1] = hex2chr(coinin % 10);
          Write_continuity(coininaddr, coininlen, buf22);
        }
        SERIAL_SendStatus(0x02, coinin, machineid, version_code_z);
        if (gamemode == 2) {
          outcount = 0;
          // Single_Write_Device(outcountaddr,outcount);
          // LEDON2();
          // Delay1ms(200);
          // LEDOFF2();
        }

        if (outcount <= outbase && gamemode == 1) {
          outcount += coinbase;
          Single_Write_Device(outcountaddr, outcount);
          // LEDON2();
          // Delay1ms(200);
          // LEDOFF2();
        }

        if (outcount > outbase) {
          clampingdate++;
          outcount = outbase;
          Single_Write_Device(outcountaddr, outcount);
          // LEDON2();
          // Delay1ms(200);
          // LEDOFF2();
        }
        if (clampingdate == clampingnum) {
          clampingdate = 0;
          outcount = coinbase;
          Single_Write_Device(outcountaddr, outcount);
          // LEDON2();
          // Delay1ms(200);
          // LEDOFF2();
        }

        if (uppulltime == 2 && outcount <= outbase && gamemode == 1) {
          LCD_Set_XY(3, 7);
          LCD_Set_XY(3, 7);
          LCD_Write_Number(outcount / 10);  // 4 4
          LCD_Write_Number(outcount % 10);
        }
        // allcoin=allcoin+coinbase;
        // ??????
        SendCMD(0x30);
        SendCMD(0x30);  // 8 ��???��???????
        LCD_Set_XY(2, 0);
        LCD_Set_XY(2, 0);
        LCD_Write_Number(10);
        LCD_Write_Number((coinin / coinbase) / 10);
        LCD_Write_Number((coinin / coinbase) % 10);
        LCD_Set_XY(4, 2);
        LCD_Set_XY(4, 2);
        LCD_Write_Number(coinin / 10);
        LCD_Write_Number(coinin % 10);
        // ????????
        CLAWDOWNFLAG = 0;
        // UART2_len(HEAVYMUSIC, 8);
      }
      if (beginning == 1) {
        gametime = gametimebase;          // ????????
        pulllengthtime = pulllength;  // 20240327 ????????????
        gameruntime = gametime + 10;
        beginning = 2;
        gamestatus = 1;
#ifdef HARDWARE_V2
        MACHINE_EventResetRound();
        MACHINE_EventPost(MECH_EVT_CONTROL_START);
#endif
      }
      //		if(gamestatus ==1)
      //		{
      //			if(enterkey == 1 ||gametime ==0)//?��???????????????
      //			{
      //				enterkey =0;
      //				gamestatus=2;  //?????????????????????2
      //				beginning =3;  //????????????
      //			}
      //		}
      // ?????????
      if (gametimeflash == 1) {
        gametimeflesh();
      }

      // ???????
      if (outsentorflag == 1) {
        outsentorflag = 0;
        if (roundround == 0) roundround = 1;
        toynum[roundround - 1] = 1;                                                       // ????????????????��???????????��????????????????????----
        if ((random_mod_point > (roundround - 1)) && gamemode == 2 && teststatue == 0) {  // 20240521
          surprisecount++;
          // coin_info.abnormal_out++;
          // coin_info.send_num = 4;
          buf55[0] = hex2chr(surprisecount / 10000);
          buf55[1] = hex2chr(surprisecount % 10000 / 1000);
          buf55[2] = hex2chr(surprisecount % 1000 / 100);
          buf55[3] = hex2chr(surprisecount % 100 / 10);
          buf55[4] = hex2chr(surprisecount % 10);
          Write_continuity(surprisecountaddr, surprisecountlen, buf55);
        }
        gameround();
        //			if(gamenum < outbase && gamemode == 1 && teststatue ==0)
        //			{
        //				surprisecount++;
        //				buf55[0]= hex2chr(surprisecount/10000);
        //				buf55[1]= hex2chr(surprisecount%10000/1000);
        //				buf55[2]= hex2chr(surprisecount%1000/100);
        //				buf55[3]= hex2chr(surprisecount%100/10);
        //				buf55[4]= hex2chr(surprisecount%10);
        //				Write_continuity(surprisecountaddr,surprisecountlen,buf55);
        //			}
        //			gamenum = 0;
        //			if(roundnum[roundround-1]==0 && gamemode == 1)
        //			{
        //				surprisecount++;
        //				buf55[0]= hex2chr(surprisecount/10000);
        //				buf55[1]= hex2chr(surprisecount%10000/1000);
        //				buf55[2]= hex2chr(surprisecount%1000/100);
        //				buf55[3]= hex2chr(surprisecount%100/10);
        //				buf55[4]= hex2chr(surprisecount%10);
        //				Write_continuity(surprisecountaddr,surprisecountlen,buf55);
        //				gameround();//?????????
        ////				for(outsentortemp=0;outsentortemp<8;outsentortemp++)
        ////				{
        ////					if(roundnum[roundround+outsentortemp]==1)
        ////					{
        ////						roundnum[roundround+outsentortemp] =0;
        ////						break;
        ////					}
        ////				}
        //			}
      }

      ///////////////////////////???????????///////////////////////////
      if (WINFLAG >= 1 && winflag_tim >= 1 && gift_pulse_flag == 0)  // ??????
      {
        WINFLAG--;
        outcount = 0;
        // LEDON2();
        // Delay1ms(200);
        // LEDOFF2();
        Single_Write_Device(outcountaddr, outcount);
        if (uppulltime == 2 && gamemode == 1) {
          LCD_Set_XY(3, 7);
          LCD_Set_XY(3, 7);
          LCD_Write_Number(outcount / 10);  // 4 4
          LCD_Write_Number(outcount % 10);
        }
        if (gamenum < outbase && gamemode == 1 && teststatue == 0) {
          surprisecount++;
          // coin_info.abnormal_out++;
          // coin_info.send_num = 4;
          buf55[0] = hex2chr(surprisecount / 10000);
          buf55[1] = hex2chr(surprisecount % 10000 / 1000);
          buf55[2] = hex2chr(surprisecount % 1000 / 100);
          buf55[3] = hex2chr(surprisecount % 100 / 10);
          buf55[4] = hex2chr(surprisecount % 10);
          Write_continuity(surprisecountaddr, surprisecountlen, buf55);
        }
        if (WINFLAG == 0) {
          gamenum = 0;
          clampingdate = 0;
        }
        if (teststatue == 0)  // ??????????????????????????????
        {
          toycounton();

          if (!custom_led_flag) {
            LED_App_SetLed1FlashOn(300, 200, 5000, 1);
            LED_App_SetLed2Flash(300, 200, 5000, 1);
          }
  
          alltoy = alltoy + 1;
          coin_info.normal_out++;
          coin_info.sn++;
          coin_info.balance = coinin;
          coin_info.send_num = 4;
          if (free_mode_flag) {
            free_mode_toy++;
            free_mode_flag = 0;
            buf55[0] = hex2chr(free_mode_toy / 10000);
            buf55[1] = hex2chr(free_mode_toy % 10000 / 1000);
            buf55[2] = hex2chr(free_mode_toy % 1000 / 100);
            buf55[3] = hex2chr(free_mode_toy % 100 / 10);
            buf55[4] = hex2chr(free_mode_toy % 10);
            Write_continuity(free_mode_toy_addr, free_mode_toy_len, buf55);
          }
          // ?????????????[n|00001|7|01|12345678|sign]#$-$#
          // u8  gsmrealtimetoyoutdatabuff[61]={"[n|00001|7|01|12345678|00000000000000000000000000000000]#$-$#"};
          //				UART1_SendString("AT+CIPSEND=61\r\n");
          //				Time_10ms_cnt=10;
          //				while(Time_10ms_cnt);
          //				mymemecys(gsmrealtimetoyoutdatabuff,"01",11,2);
          //				Add_md5_keymark_gsmtoyoutdatabuff(gsmrealtimetoyoutdatabuff);
          //				GsmSend((char *)gsmrealtimetoyoutdatabuff);

          buf55[0] = hex2chr(alltoy / 10000);
          buf55[1] = hex2chr(alltoy % 10000 / 1000);
          buf55[2] = hex2chr(alltoy % 1000 / 100);
          buf55[3] = hex2chr(alltoy % 100 / 10);
          buf55[4] = hex2chr(alltoy % 10);
          Write_continuity(alltoyaddr, alltoylen, buf55);
          sendbusy = 1;
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=64\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=64\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=64\r\n");
#endif
          Time_10ms_cnt = 50;
          while (Time_10ms_cnt);
          // mymemecys(gsmrealtimetoyoutdatabuff,"01",11,2);
          Read_continuity(alltoyaddr, alltoylen, buf55);
          mymemcpy((u8 *)buf55, (u8 *)&gsmrealtimetoyoutdatabuff[11], 5);  // ????????
          Add_md5_keymark_gsmtoyoutdatabuff(gsmrealtimetoyoutdatabuff);
          GsmSend((char *)gsmrealtimetoyoutdatabuff);
          sendbusy = 0;
          gift_pulse_flag = 1;
          TIM_Cmd(TIM3, ENABLE);
        }
        // UART2_len(WINNINGMUSIC, 8);/
      }
      if (CLAWDOWNFLAG == 1)  // ???
      {
        CLAWDOWNFLAG = 2;
        // UART2_len(CLAWDOWNMUSIC, 8);
        Delay1ms(100);
      }
      if (CLAWUPFLAG == 1)  // ????
      {
        CLAWUPFLAG = 2;
        // UART2_len(CLAWUPMUSIC, 8);
        Delay1ms(100);
      }
      if (CLAWTOYFLAG == 1)  // ?
      {
        CLAWTOYFLAG = 2;
        // UART2_len(CLAWMUSIC, 8);
        Delay1ms(100);
      }
      if (GAMEINGFLAG == 1)  // ???
      {
        GAMEINGFLAG = 2;
        // UART2_len(HEAVYMUSIC, 8);
        Delay1ms(100);
      }
    }
    // ?????????????????
    if (COININTESTFLAG == 1)  // ?????????,??????
    {
      COININTESTFLAG = 0;
      teststatue = 1;
      coinin++;
      // UART2_len(COININMUSIC, 8);
      SendCMD(0x30);
      SendCMD(0x30);  // 8 ��???��???????
      LCD_Set_XY(2, 0);
      LCD_Set_XY(2, 0);
      LCD_Write_Number(10);
      LCD_Write_Number((coinin / coinbase) / 10);
      LCD_Write_Number((coinin / coinbase) % 10);
      LCD_Set_XY(4, 2);
      LCD_Set_XY(4, 2);
      LCD_Write_Number(coinin / 10);
      LCD_Write_Number(coinin % 10);
      if (uppulltime == 2 && outcount <= outbase && gamemode == 1) {
        LCD_Set_XY(3, 7);
        LCD_Set_XY(3, 7);
        LCD_Write_Number(outcount / 10);  // 4 4
        LCD_Write_Number(outcount % 10);
      }
      CLAWDOWNFLAG = 0;
    }

    if (COININFLAG == 1)  // ???
    {
      COININFLAG = 0;
      teststatue = 0;
      coincounton();
      // ?????????????
      //			u8  gsmrealtimecoinindatabuff[61]={"[m|00001|6|01|12345678|00000000000000000000000000000000]#$-$#"};
      //			UART1_SendString("AT+CIPSEND=61\r\n");
      //			mymemecys(gsmrealtimecoinindatabuff,"01",11,2);
      //			Time_10ms_cnt=10;
      //			while(Time_10ms_cnt);
      //			Add_md5_keymark_gsmcoinindatabuff(gsmrealtimecoinindatabuff);
      //			GsmSend((char *)gsmrealtimecoinindatabuff);

      buf22[0] = hex2chr(coinin / 10);
      buf22[1] = hex2chr(coinin % 10);
      Write_continuity(coininaddr, coininlen, buf22);  // ??????
      allcoin = allcoin + 1;
      buf55[0] = hex2chr(allcoin / 10000);
      buf55[1] = hex2chr(allcoin % 10000 / 1000);
      buf55[2] = hex2chr(allcoin % 1000 / 100);
      buf55[3] = hex2chr(allcoin % 100 / 10);
      buf55[4] = hex2chr(allcoin % 10);
      Write_continuity(allcoinaddr, allcoinlen, buf55);  // ???????
      sendbusy = 1;
#ifdef HARDWARE_V1
      UART1_SendString("AT+CIPSEND=64\r\n");
#endif
#ifdef HARDWARE_V0
      UART3_SendString("AT+CIPSEND=64\r\n");
#endif
#ifdef HARDWARE_V2
      UART2_SendString("AT+CIPSEND=64\r\n");
#endif
      Read_continuity(allcoinaddr, allcoinlen, buf55);
      mymemcpy((u8 *)buf55, (u8 *)&gsmrealtimecoinindatabuff[11], 5);  // ????????
      Time_10ms_cnt = 30;
      while (Time_10ms_cnt);
      Add_md5_keymark_gsmcoinindatabuff(gsmrealtimecoinindatabuff);
      GsmSend((char *)gsmrealtimecoinindatabuff);
      sendbusy = 0;
      // UART2_len(COININMUSIC, 8);
      SendCMD(0x30);
      SendCMD(0x30);  // 8 ��???��???????
      LCD_Set_XY(2, 0);
      LCD_Set_XY(2, 0);
      LCD_Write_Number(10);
      LCD_Write_Number((coinin / coinbase) / 10);
      LCD_Write_Number((coinin / coinbase) % 10);
      LCD_Set_XY(4, 2);
      LCD_Set_XY(4, 2);
      LCD_Write_Number(coinin / 10);
      LCD_Write_Number(coinin % 10);

      if (uppulltime == 2 && outcount <= outbase && gamemode == 1) {
        LCD_Set_XY(3, 7);
        LCD_Set_XY(3, 7);
        LCD_Write_Number(outcount / 10);  // 4 4
        LCD_Write_Number(outcount % 10);
      }
      CLAWDOWNFLAG = 0;
      coincountoff();
    }
    if (!control_mode) {
      if (MUSICBUSY() == 1) {
        //			GAMEWAITFLAG =0;
        // UART2_len(LIGHTMUSIC, 8);
        Delay1ms(100);
      }
      if (WARMFLAG == 1 && MUSICBUSY() == 1) {
        WARMFLAG = 0;
        // UART2_len(WARMMUSIC, 8);
        Delay1ms(100);
      }
      if (OUTSENTOR() == 1)
        LEDON1();
      else
        LEDOFF1();

      // ???????????????
      if (coin_sign_flag) {
        coin_sign_flag = 0;
        sendbusy = 1;
#ifdef HARDWARE_V1
        UART1_SendString("AT+CIPSEND=61\r\n");
#endif
#ifdef HARDWARE_V0
        UART3_SendString("AT+CIPSEND=61\r\n");
#endif
#ifdef HARDWARE_V2
        UART2_SendString("AT+CIPSEND=61\r\n");
#endif
        Time_10ms_cnt = 10;
        while (Time_10ms_cnt);
        GsmSend((char *)gsmcoindatabuff);
        sendbusy = 0;

        //////////////
        teststatue = 0;
        coincounton();

        // ?????????????
        //			u8  gsmrealtimecoinindatabuff[61]={"[m|00001|6|01|12345678|00000000000000000000000000000000]#$-$#"};
        //			UART1_SendString("AT+CIPSEND=61\r\n");
        //			mymemecys(gsmrealtimecoinindatabuff,"01",11,2);
        //			Time_10ms_cnt=10;
        //			while(Time_10ms_cnt);
        //			Add_md5_keymark_gsmcoinindatabuff(gsmrealtimecoinindatabuff);
        //			GsmSend((char *)gsmrealtimecoinindatabuff);

        buf22[0] = hex2chr(coinin / 10);
        buf22[1] = hex2chr(coinin % 10);
        Write_continuity(coininaddr, coininlen, buf22);  // ??????
        allcoin = allcoin + coinbase;
        buf55[0] = hex2chr(allcoin / 10000);
        buf55[1] = hex2chr(allcoin % 10000 / 1000);
        buf55[2] = hex2chr(allcoin % 1000 / 100);
        buf55[3] = hex2chr(allcoin % 100 / 10);
        buf55[4] = hex2chr(allcoin % 10);
        Write_continuity(allcoinaddr, allcoinlen, buf55);  // ???????
        sendbusy = 1;
#ifdef HARDWARE_V1
        UART1_SendString("AT+CIPSEND=64\r\n");
#endif
#ifdef HARDWARE_V0
        UART3_SendString("AT+CIPSEND=64\r\n");
#endif
#ifdef HARDWARE_V2
        UART2_SendString("AT+CIPSEND=64\r\n");
#endif
        Read_continuity(allcoinaddr, allcoinlen, buf55);
        mymemcpy((u8 *)buf55, (u8 *)&gsmrealtimecoinindatabuff[11], 5);  // ????????
        Time_10ms_cnt = 30;
        while (Time_10ms_cnt);
        Add_md5_keymark_gsmcoinindatabuff(gsmrealtimecoinindatabuff);
        GsmSend((char *)gsmrealtimecoinindatabuff);
        sendbusy = 0;
        // UART2_len(COININMUSIC, 8);
        SendCMD(0x30);
        SendCMD(0x30);  // 8 ��???��???????
        LCD_Set_XY(2, 0);
        LCD_Set_XY(2, 0);
        LCD_Write_Number(10);
        LCD_Write_Number((coinin / coinbase) / 10);
        LCD_Write_Number((coinin / coinbase) % 10);
        LCD_Set_XY(4, 2);
        LCD_Set_XY(4, 2);
        LCD_Write_Number(coinin / 10);
        LCD_Write_Number(coinin % 10);

        if (uppulltime == 2 && outcount <= outbase && gamemode == 1) {
          LCD_Set_XY(3, 7);
          LCD_Set_XY(3, 7);
          LCD_Write_Number(outcount / 10);  // 4 4
          LCD_Write_Number(outcount % 10);
        }
        CLAWDOWNFLAG = 0;
        coincountoff();
      }
      if (inquirecoininflag == 1 && beginning == 0 && reconnect == 0 && combusy == 0)  // 1
      {
        inquirecoininflag = 0;
        Read_continuity(coininaddr, coininlen, buf22);
        sendbusy = 1;
#ifdef HARDWARE_V1
        UART1_SendString("AT+CIPSEND=68\r\n");  // ??????gsmsetdatabuff[68]={"[g|00001|1|01|000020|12345678|sign]#$-$# "};
#endif
#ifdef HARDWARE_V0
        UART3_SendString("AT+CIPSEND=68\r\n");  // ??????gsmsetdatabuff[68]={"[g|00001|1|01|000020|12345678|sign]#$-$# "};
#endif
#ifdef HARDWARE_V2
        UART2_SendString("AT+CIPSEND=68\r\n");  // ??????gsmsetdatabuff[68]={"[g|00001|1|01|000020|12345678|sign]#$-$# "};
#endif
        Time_10ms_cnt = 10;
        while (Time_10ms_cnt);
        mymemecys(gsmgetdatabuff, "01", 11, 2);
        mymemecys(gsmgetdatabuff, "1", 9, 1);
        mymemecys(gsmgetdatabuff, "0000", 14, 4);
        mymemcpy((u8 *)buf22, (u8 *)&gsmgetdatabuff[18], 2);  // ????????
        Add_md5_keymark_gsmgetdatabuff(gsmgetdatabuff);
        GsmSend((char *)gsmgetdatabuff);
        sendbusy = 0;
      }
      if (inquiresuppriseflag == 1 && beginning == 0 && reconnect == 0 && combusy == 0)  // 2
      {
        inquiresuppriseflag = 0;
        Read_continuity(surprisecountaddr, surprisecountlen, buf55);
        sendbusy = 1;
#ifdef HARDWARE_V1
        UART1_SendString("AT+CIPSEND=68\r\n");  // ??????gsmsetdatabuff[68]={"[g|00001|1|01|000020|12345678|sign]#$-$# "};
#endif
#ifdef HARDWARE_V0
        UART3_SendString("AT+CIPSEND=68\r\n");  // ??????gsmsetdatabuff[68]={"[g|00001|1|01|000020|12345678|sign]#$-$# "};
#endif
#ifdef HARDWARE_V2
        UART2_SendString("AT+CIPSEND=68\r\n");  // ??????gsmsetdatabuff[68]={"[g|00001|1|01|000020|12345678|sign]#$-$# "};
#endif
        Time_10ms_cnt = 10;
        while (Time_10ms_cnt);
        mymemecys(gsmgetdatabuff, "02", 11, 2);
        mymemecys(gsmgetdatabuff, "1", 9, 1);
        mymemecys(gsmgetdatabuff, "0", 14, 1);
        mymemcpy((u8 *)buf55, (u8 *)&gsmgetdatabuff[15], 5);  // ????????
        Add_md5_keymark_gsmgetdatabuff(gsmgetdatabuff);
        GsmSend((char *)gsmgetdatabuff);
        sendbusy = 0;
      }
      if (inquireallcoinflag == 1 && beginning == 0 && reconnect == 0 && combusy == 0)  // 3
      {
        inquireallcoinflag = 0;
        Read_continuity(allcoinaddr, allcoinlen, buf55);
        sendbusy = 1;
#ifdef HARDWARE_V1
        UART1_SendString("AT+CIPSEND=68\r\n");  // ??????gsmsetdatabuff[68]={"[g|00001|1|01|000020|12345678|sign]#$-$# "};
#endif
#ifdef HARDWARE_V0
        UART3_SendString("AT+CIPSEND=68\r\n");  // ??????gsmsetdatabuff[68]={"[g|00001|1|01|000020|12345678|sign]#$-$# "};
#endif
#ifdef HARDWARE_V2
        UART2_SendString("AT+CIPSEND=68\r\n");  // ??????gsmsetdatabuff[68]={"[g|00001|1|01|000020|12345678|sign]#$-$# "};
#endif
        Time_10ms_cnt = 10;
        while (Time_10ms_cnt);
        mymemecys(gsmgetdatabuff, "03", 11, 2);
        mymemecys(gsmgetdatabuff, "1", 9, 1);
        mymemecys(gsmgetdatabuff, "0", 14, 1);
        mymemcpy((u8 *)buf55, (u8 *)&gsmgetdatabuff[15], 5);  // ????????
        Add_md5_keymark_gsmgetdatabuff(gsmgetdatabuff);
        GsmSend((char *)gsmgetdatabuff);
        sendbusy = 0;
      }
      if (inquirebillflag == 1 && beginning == 0 && reconnect == 0 && combusy == 0) {
        inquirebillflag = 0;  // 4
        Read_continuity(alltoyaddr, alltoylen, buf55);
        sendbusy = 1;
#ifdef HARDWARE_V1
        UART1_SendString("AT+CIPSEND=68\r\n");  // ??????gsmsetdatabuff[68]={"[g|00001|1|01|000020|12345678|sign]#$-$# "};
#endif
#ifdef HARDWARE_V0
        UART3_SendString("AT+CIPSEND=68\r\n");  // ??????gsmsetdatabuff[68]={"[g|00001|1|01|000020|12345678|sign]#$-$# "};
#endif
#ifdef HARDWARE_V2
        UART2_SendString("AT+CIPSEND=68\r\n");  // ??????gsmsetdatabuff[68]={"[g|00001|1|01|000020|12345678|sign]#$-$# "};
#endif
        Time_10ms_cnt = 10;
        while (Time_10ms_cnt);
        mymemecys(gsmgetdatabuff, "04", 11, 2);  //
        mymemecys(gsmgetdatabuff, "1", 9, 1);
        mymemecys(gsmgetdatabuff, "0", 14, 1);
        mymemcpy((u8 *)buf55, (u8 *)&gsmgetdatabuff[15], 5);  // ????????
        Add_md5_keymark_gsmgetdatabuff(gsmgetdatabuff);
        GsmSend((char *)gsmgetdatabuff);
        sendbusy = 0;
      }

      // u8  coinin;            //?????           1
      // u16 surprisecount;     //???????         2
      // u16 allcoin;           //??????         3
      // u16 alltoy;           //????????       4

      //		inquiresetflag??????????????????????
      if ((inquiresetflagl != 0 || inquiresetflagh != 0) && beginning == 0 && reconnect == 0 && combusy == 0) {
        //			mymemecys(gsmsetdatabuff,"01",12,2);
        //			mymemecys(gsmsetdatabuff,"2",12,1);
        sendbusy = 1;
        if ((inquiresetflagh >> 1) & 0x01)  // u16 right_left_point_fixedpoint;  //????????????????1000-50000   17
        {
          Read_continuity(right_left_point_fixedpointaddr, right_left_point_fixedpointlen, buf55);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0", 14, 1);
          mymemecys(gsmsetdatabuff, "17", 11, 2);
          mymemcpy((u8 *)buf55, (u8 *)&gsmsetdatabuff[15], 5);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagh >> 2) & 0x01)  // u16 clawgetonesteptime;      //?????????????  ??????100-3000    18
        {
          Read_continuity(clawgetonesteptimeaddr, clawgetonesteptimelen, buf44);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "00", 14, 2);
          mymemecys(gsmsetdatabuff, "18", 11, 2);
          mymemcpy((u8 *)buf44, (u8 *)&gsmsetdatabuff[16], 4);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagh >> 3) & 0x01)  // u16 clawgettwosteptime;      //??????????100-5000                    19
        {
          Read_continuity(clawgettwosteptimeaddr, clawgettwosteptimelen, buf44);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "00", 14, 2);
          mymemecys(gsmsetdatabuff, "19", 11, 2);
          mymemcpy((u8 *)buf44, (u8 *)&gsmsetdatabuff[16], 4);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagh >> 4) & 0x01)  // u16 clawgetthreesteptime;    //??????????????100-5000                20
        {
          Read_continuity(clawgetthreesteptimeaddr, clawgetthreesteptimelen, buf44);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "00", 14, 2);
          mymemecys(gsmsetdatabuff, "20", 11, 2);
          mymemcpy((u8 *)buf44, (u8 *)&gsmsetdatabuff[16], 4);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagh >> 5) & 0x01)  // u16 clawgetthreesteptime;    //??????????????100-5000                21
        {
          Read_continuity(pulllengthsetaddr, pulllengthsetlen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "21", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagh >> 6) & 0x01)  // u16 clawgetthreesteptime;    //?????                22
        {
          Read_continuity(outbaseaddr, outbaselen, buf44);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "00", 14, 2);
          mymemecys(gsmsetdatabuff, "22", 11, 2);
          mymemcpy((u8 *)buf44, (u8 *)&gsmsetdatabuff[16], 4);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagh >> 7) & 0x01)  // u16 clawgetthreesteptime;    //???????                23
        {
          Read_continuity(clampingnumaddr, clampingnumlen, buf22);
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "23", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagh >> 8) & 0x01)  // u16 clawgetthreesteptime;    //??????              24
        {
          Read_continuity(uppulltimeaddr, uppulltimelen, buf22);
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "24", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagh >> 9) & 0x01)  // u16 clawgetthreesteptime;    //?????              25
        {
          Read_continuity(gamemodeaddr, gamemodelen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "25", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagh >> 14) & 0x01)  // u16 clawgetthreesteptime;    //????��             30
        {
          Read_continuity(version_code_zaddr, version_code_zlen, buf44);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "00", 14, 2);
          mymemecys(gsmsetdatabuff, "30", 11, 2);
          mymemcpy((u8 *)buf44, (u8 *)&gsmsetdatabuff[16], 4);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }

        if (inquiresetflagl & 0x01)  // ?????????//u8  coinbase;           //?????????1-30    1
        {
          Read_continuity(coinbaseaddr, coinbaselen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "01", 11, 2);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 0x01) & 0x01)  // u8  roundbase;          //???????1-99      2
        {
          Read_continuity(roundbaseaddr, roundbaselen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "02", 11, 2);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 0x02) & 0x01)  // u8  lostclaw;           //???????10-99       3
        {
          Read_continuity(lostclawaddr, lostclawlen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "03", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 0x03) & 0x01)  // u8  groundstongclaw;    //?????????10-99   4
        {
          Read_continuity(groundstongclawaddr, groundstongclawlen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "04", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 0x04) & 0x01)  // u8  lightclaw;          //?????????10-99     5
        {
          Read_continuity(lightclawaddr, lightclawlen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "05", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 0x05) & 0x01)  // u8  strongclaw;         //??????10-99       6
        {
          Read_continuity(strongclawaddr, strongclawlen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "06", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 0x06) & 0x01)  // u8  gametimebase;      //??????10-60        7
        {
          Read_continuity(gametimebaseaddr, gametimebaselen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "07", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 0x07) & 0x01)  // u8  roundoffset;       //?????0-10           8
        {
          Read_continuity(roundoffsetaddr, roundoffsetlen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "08", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 0x08) & 0x01)  // u8  swingpull;         //?????0/1            9
        {
          Read_continuity(swingpulladdr, swingpulllen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "09", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 11) & 0x01)  // u8  upspeed;            //???????10-99       12
        {
          Read_continuity(upspeedaddr, upspeedlen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "12", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 12) & 0x01)  // u8  downspeed;          //??????10-99       13
        {
          Read_continuity(downspeedaddr, downspeedlen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "13", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 13) & 0x01)  // u8  leftrightspeed;     //???????10-99       14
        {
          Read_continuity(leftrightspeedaddr, leftrightspeedlen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "14", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 14) & 0x01)  // u8  fixedpoint;                   //??????????0/1       15
        {
          Read_continuity(fixedpointaddr, fixedpointlen, buf22);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0000", 14, 4);
          mymemecys(gsmsetdatabuff, "15", 11, 2);
          mymemcpy((u8 *)buf22, (u8 *)&gsmsetdatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }
        if ((inquiresetflagl >> 15) & 0x01)  // u16 front_back_point_fixedpoint;  //???????????????1000-50000   16
        {
          Read_continuity(front_back_point_fixedpointaddr, front_back_point_fixedpointlen, buf55);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetdatabuff, "0", 14, 1);
          mymemecys(gsmsetdatabuff, "16", 11, 2);
          mymemcpy((u8 *)buf55, (u8 *)&gsmsetdatabuff[15], 5);  // ????????
          Add_md5_keymark_gsmsetdatabuff(gsmsetdatabuff);
          GsmSend((char *)gsmsetdatabuff);
        }

        inquiresetflagl = 0;
        inquiresetflagh = 0;
        sendbusy = 0;
      }
      ////------------------------------???????????---------->????????????????
      ////		coinbase;    //?????????
      ////		roundbase;     //???????
      ////		gametimebase;   //???
      ////    upspeed;     //???????
      ////    downspeed;     //??????
      ////    leftrightspeed;     //???????
      ////		roundbase;     //???????
      ////    roundoffset;     //?????
      ////
      ////    lostclaw;    //???????
      ////    groundstongclaw;    //?????????
      ////    lightclaw;    //???????
      ////    strongclaw;    //??????

      ////    swingpull;     //?????
      ////    fixedpoint;     //??????????
      ////    front_back_point_fixedpoint;  //???????????????
      ////    right_left_point_fixedpoint;  //????????????????

      ////    clawgetonesteptime; //?????????????  ??????
      ////    clawgettwosteptime; //??????????
      ////    clawgetthreesteptime; //??????????????

      if (setflag == 1 && beginning == 0 && reconnect == 0 && combusy == 0)  // ????????????????????????????????????��?????????????????
      {
        setflag = 0;
        if (mymemcpm(coinbasebuff, twonull, 2) == 0) {
          Write_continuity(coinbaseaddr, coinbaselen, coinbasebuff);  // ��??????

          // Read_continuity(clawgettwosteptimeaddr,clawgettwosteptimelen,buf44);
#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "01", 11, 2);
          mymemcpy((u8 *)coinbasebuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(coinbasebuff, 2);  // ="00";
        }
        if (mymemcpm(roundbasebuff, twonull, 2) == 0) {
          Write_continuity(roundbaseaddr, roundbaselen, roundbasebuff);  // ��???

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "02", 11, 2);
          mymemcpy((u8 *)roundbasebuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(roundbasebuff, 2);  // ="00";
        }
        if (mymemcpm(lightclawbuff, twonull, 2) == 0) {
          Write_continuity(lightclawaddr, lightclawlen, lightclawbuff);  // ��???????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "05", 11, 2);
          mymemcpy((u8 *)lightclawbuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(lightclawbuff, 2);  // ="00";
        }
        if (mymemcpm(strongclawbuff, twonull, 2) == 0) {
          Write_continuity(strongclawaddr, strongclawlen, strongclawbuff);  // ��????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "06", 11, 2);
          mymemcpy((u8 *)strongclawbuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(strongclawbuff, 2);  // ="00";
        }
        if (mymemcpm(lostclawbuff, twonull, 2) == 0) {
          Write_continuity(lostclawaddr, lostclawlen, lostclawbuff);  // ��???????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "03", 11, 2);
          mymemcpy((u8 *)lostclawbuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(lostclawbuff, 2);  // ="00";
        }
        if (mymemcpm(groundstongclawbuff, twonull, 2) == 0) {
          Write_continuity(groundstongclawaddr, groundstongclawlen, groundstongclawbuff);  // ��??????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "04", 11, 2);
          mymemcpy((u8 *)groundstongclawbuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(groundstongclawbuff, 2);  // ="00";
        }
        if (mymemcpm(gametimebasebuff, twonull, 2) == 0) {
          Write_continuity(gametimebaseaddr, gametimebaselen, gametimebasebuff);  // ��???

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "07", 11, 2);
          mymemcpy((u8 *)gametimebasebuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(gametimebasebuff, 2);  // ="00";
        }
        if (mymemcpm(roundoffsetbuff, twonull, 2) == 0) {
          Write_continuity(roundoffsetaddr, roundoffsetlen, roundoffsetbuff);  // ��??????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "08", 11, 2);
          mymemcpy((u8 *)roundoffsetbuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(roundoffsetbuff, 2);  // ="00";
        }
        if (mymemcpm(swingpullbuff, twonull, 2) == 0) {
          Write_continuity(swingpulladdr, swingpulllen, swingpullbuff);  // ��???

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "09", 11, 2);
          mymemcpy((u8 *)swingpullbuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(swingpullbuff, 2);  // ="00";
        }
        if (mymemcpm(fixedpointbuff, twonull, 2) == 0) {
          Write_continuity(fixedpointaddr, fixedpointlen, fixedpointbuff);  // ��??????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "15", 11, 2);
          mymemcpy((u8 *)fixedpointbuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(fixedpointbuff, 2);  // ="00";
        }
        if (mymemcpm(upspeedbuff, twonull, 2) == 0) {
          Write_continuity(upspeedaddr, upspeedlen, upspeedbuff);  // ��???????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "12", 11, 2);
          mymemcpy((u8 *)upspeedbuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(upspeedbuff, 2);  // ="00";
        }
        if (mymemcpm(downspeedbuff, twonull, 2) == 0) {
          Write_continuity(downspeedaddr, downspeedlen, downspeedbuff);  // ��??????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "13", 11, 2);
          mymemcpy((u8 *)downspeedbuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(downspeedbuff, 2);  // ="00";
        }
        if (mymemcpm(leftrightspeedbuff, twonull, 2) == 0) {
          Write_continuity(leftrightspeedaddr, leftrightspeedlen, leftrightspeedbuff);  // ��???????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "14", 11, 2);
          mymemcpy((u8 *)leftrightspeedbuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(leftrightspeedbuff, 2);  // ="00";
        }
        if (mymemcpm(front_back_point_fixedpointbuff, fivenull, 5) == 0) {
          Write_continuity(front_back_point_fixedpointaddr, front_back_point_fixedpointlen, front_back_point_fixedpointbuff);  // ????????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0", 14, 1);
          mymemecys(gsmsetyoudatabuff, "16", 11, 2);
          mymemcpy((u8 *)front_back_point_fixedpointbuff, (u8 *)&gsmsetyoudatabuff[15], 5);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(front_back_point_fixedpointbuff, 5);  // ="00";
        }
        if (mymemcpm(right_left_point_fixedpointbuff, fivenull, 5) == 0) {
          Write_continuity(right_left_point_fixedpointaddr, right_left_point_fixedpointlen, right_left_point_fixedpointbuff);  // ???????????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0", 14, 1);
          mymemecys(gsmsetyoudatabuff, "17", 11, 2);
          mymemcpy((u8 *)right_left_point_fixedpointbuff, (u8 *)&gsmsetyoudatabuff[15], 5);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(right_left_point_fixedpointbuff, 5);  // ="00";
        }
        if (mymemcpm(clawgettwosteptimebuff, fournull, 4) == 0) {
          Write_continuity(clawgettwosteptimeaddr, clawgettwosteptimelen, clawgettwosteptimebuff);  // ???????????????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "00", 14, 2);
          mymemecys(gsmsetyoudatabuff, "19", 11, 2);
          mymemcpy((u8 *)clawgettwosteptimebuff, (u8 *)&gsmsetyoudatabuff[16], 4);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(clawgettwosteptimebuff, 4);  // ="00";
        }
        if (mymemcpm(clawgetonesteptimebuff, fournull, 4) == 0) {
          Write_continuity(clawgetonesteptimeaddr, clawgetonesteptimelen, clawgetonesteptimebuff);  // ???????????????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "00", 14, 2);
          mymemecys(gsmsetyoudatabuff, "18", 11, 2);
          mymemcpy((u8 *)clawgetonesteptimebuff, (u8 *)&gsmsetyoudatabuff[16], 4);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(clawgetonesteptimebuff, 4);  // ="00";
        }
        if (mymemcpm(clawgetthreesteptimebuff, fournull, 4) == 0) {
          Write_continuity(clawgetthreesteptimeaddr, clawgetthreesteptimelen, clawgetthreesteptimebuff);  // ????????????????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "00", 14, 2);
          mymemecys(gsmsetyoudatabuff, "20", 11, 2);
          mymemcpy((u8 *)clawgetthreesteptimebuff, (u8 *)&gsmsetyoudatabuff[16], 4);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(clawgetthreesteptimebuff, 4);  // ="00";
        }
        if (mymemcpm(pulllengthbuff, twonull, 2) == 0) {
          Write_continuity(pulllengthsetaddr, pulllengthsetlen, pulllengthbuff);  // ��???????

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "21", 11, 2);
          mymemcpy((u8 *)pulllengthbuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(pulllengthbuff, 2);  // ="00";
        }
        if (mymemcpm(gamemodebuff, twonull, 2) == 0) {
          Write_continuity(gamemodeaddr, gamemodelen, gamemodebuff);  //

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "25", 11, 2);
          mymemcpy((u8 *)gamemodebuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(gamemodebuff, 2);  // ="00";
        }
        if (mymemcpm(uppulltimebuff, twonull, 2) == 0) {
          Write_continuity(uppulltimeaddr, uppulltimelen, uppulltimebuff);  //

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "24", 11, 2);
          mymemcpy((u8 *)uppulltimebuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(uppulltimebuff, 2);  // ="00";
        }
        if (mymemcpm(clampingnumbuff, twonull, 2) == 0) {
          Write_continuity(clampingnumaddr, clampingnumlen, clampingnumbuff);  //

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "0000", 14, 4);
          mymemecys(gsmsetyoudatabuff, "23", 11, 2);
          mymemcpy((u8 *)clampingnumbuff, (u8 *)&gsmsetyoudatabuff[18], 2);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(clampingnumbuff, 2);  // ="00";
        }
        if (mymemcpm(outbasebuff, fournull, 4) == 0) {
          Write_continuity(outbaseaddr, outbaselen, outbasebuff);  //

#ifdef HARDWARE_V1
          UART1_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CIPSEND=68\r\n");
#endif
#ifdef HARDWARE_V2
          UART2_SendString("AT+CIPSEND=68\r\n");
#endif
          Time_10ms_cnt = 10;
          while (Time_10ms_cnt);
          mymemecys(gsmsetyoudatabuff, "00", 14, 2);
          mymemecys(gsmsetyoudatabuff, "22", 11, 2);
          mymemcpy((u8 *)outbasebuff, (u8 *)&gsmsetyoudatabuff[16], 4);  // ????????
          Add_md5_keymark_gsmsetyoudatabuff(gsmsetyoudatabuff);
          GsmSend((char *)gsmsetyoudatabuff);

          mymemclr0(outbasebuff, 4);  // ="00";
        }
        // ��?????????????
        Read_continuity(machineidaddr, machineidlen, buf55);  // ?????????
        machineid = chr2hex(buf55[0]) * 10000 + chr2hex(buf55[1]) * 1000 + chr2hex(buf55[2]) * 100 + chr2hex(buf55[3]) * 10 + chr2hex(buf55[4]);
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
        Read_continuity(swingpulladdr, swingpulllen, buf22);
        swingpull = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);  // 8
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
        //			Read_continuity(surprisecountaddr,surprisecountlen,buf55);
        //			surprisecount =chr2hex(buf55[0])*10000+chr2hex(buf55[1])*1000+chr2hex(buf55[2])*100+chr2hex(buf55[3])*10+chr2hex(buf55[4]);
        //			Read_continuity(allcoinaddr,allcoinlen,buf55);
        //			allcoin =chr2hex(buf55[0])*10000+chr2hex(buf55[1])*1000+chr2hex(buf55[2])*100+chr2hex(buf55[3])*10+chr2hex(buf55[4]);
        //			Read_continuity(alltoyaddr,alltoylen,buf55);
        //			alltoy =chr2hex(buf55[0])*10000+chr2hex(buf55[1])*1000+chr2hex(buf55[2])*100+chr2hex(buf55[3])*10+chr2hex(buf55[4]);
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
        Read_continuity(pulllengthsetaddr, pulllengthsetlen, buf22);
        pulllength = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

        Read_continuity(uppulltimeaddr, uppulltimelen, buf22);
        uppulltime = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

        Read_continuity(gamemodeaddr, gamemodelen, buf22);
        gamemode = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

        Read_continuity(clampingnumaddr, clampingnumlen, buf22);
        clampingnum = chr2hex(buf22[0]) * 10 + chr2hex(buf22[1]);

        Read_continuity(outbaseaddr, outbaselen, buf44);
        outbase = chr2hex(buf44[0]) * 1000 + chr2hex(buf44[1]) * 100 + chr2hex(buf44[2]) * 10 + chr2hex(buf44[3]);
      }

      // factarysetbuff
      // machineidbuff
      // ???��???------------------??????????????��?????????--------------------------

      // ?��????????????????????????��???
      //		coinbase;    //?????????
      //		gametimebase;   //???
      //    upspeed;     //???????
      //    downspeed;     //??????
      //    leftrightspeed;     //???????

      // ??????????????????????��???
      //		roundbase;     //???????
      //    roundoffset;     //?????
      //
      //    lostclaw;    //???????
      //    groundstongclaw;    //?????????
      //    lightclaw;    //???????
      //    strongclaw;    //??????

      //    swingpull;     //?????
      //    fixedpoint;     //??????????
      //    front_back_point_fixedpoint;  //???????????????
      //    right_left_point_fixedpoint;  //????????????????

      //    clawgetonesteptime; //?????????????  ??????
      //    clawgettwosteptime; //??????????
      //    clawgetthreesteptime; //??????????????

      //    factaryset;
      //    machineid;
      // if (!control_mode) {
      KEY_Task();

      if (!display_refresh_time && beginning == 0) {
        display_refresh_time = 300000;
        // displayinit(rssi_display);
        displayinit(0);
        rssi_display = !rssi_display;
      }
      if (!display_display_time && beginning == 0) {
        if (rssi_display) {
          display_display_time = 1500;
        } else {
          display_display_time = 10000;
        }

        // display_id_rssi(rssi_display);
        display_id_rssi(0);
        rssi_display = !rssi_display;
      }

      if (!get_rssi_time) {
        get_rssi_time = 52000;
        uart1_rx_status = 0;
        RX1count = 0;
#ifdef HARDWARE_V1
        UART1_SendString("AT+CWJAP?\r\n");
        wait_time = 300;
        while (uart1_rx_status != 2 && wait_time);
        if (uart1_rx_status == 2) {
          uart1_rx_status = 0;
          rssi_value[0] = 0;
          rssi_value[1] = 0;
          for (tmp = 0; tmp < RX1count; tmp++) {
            if (RX1_buffer[tmp] == '-') {
              rssi_value[0] = RX1_buffer[tmp + 1];
              rssi_value[1] = RX1_buffer[tmp + 2];
              break;
            }
          }
#endif
#ifdef HARDWARE_V0
          UART3_SendString("AT+CWJAP?\r\n");
          wait_time = 300;
          while (uart1_rx_status != 2 && wait_time);
          if (uart1_rx_status == 2) {
            uart1_rx_status = 0;
            rssi_value[0] = 0;
            rssi_value[1] = 0;
            for (tmp = 0; tmp < RX3count; tmp++) {
              if (RX3_buffer[tmp] == '-') {
                rssi_value[0] = RX3_buffer[tmp + 1];
                rssi_value[1] = RX3_buffer[tmp + 2];
                break;
              }
            }
#endif
#ifdef HARDWARE_V2
            UART2_SendString("AT+CWJAP?\r\n");
            wait_time = 300;
            while (uart1_rx_status != 2 && wait_time);
            if (uart1_rx_status == 2) {
              uart1_rx_status = 0;
              rssi_value[0] = 0;
              rssi_value[1] = 0;
              for (tmp = 0; tmp < RX2count; tmp++) {
                if (RX2_buffer[tmp] == '-') {
                  rssi_value[0] = RX2_buffer[tmp + 1];
                  rssi_value[1] = RX2_buffer[tmp + 2];
                  break;
                }
              }
#endif

              SendCMD(0x30);
              SendCMD(0x30);
              RX1count = 0;
            }
          }

          if (off_line_time > 300) {
            off_line_time = 0;
            WIFIEN();      // ???
            WIFIRSTOFF();  // ??????????
            Time_10ms_cnt = 100;
            while (Time_10ms_cnt);
            WIFIRSTON();  // ??????????
            neton = 65;
          }
          /////////////////////////???��????///////////////////////////
          if (reconnect == 0) {
            if (Second2 % 5 == 0)
              LEDON2();
            else
              LEDOFF2();
          } else {
            if (Second2 % 2 == 0)
              LEDON2();
            else
              LEDOFF2();
          }

          // ????????
          if (neton > 80 && beginning == 0)  //&&link not
          {
            neton = 0;
            reconnect = 1;
            connecting = 1;
          }
          if (reconnect == 1 && beginning == 0) {
            if (connecting == 5) {
              connecting = 6;
#ifdef HARDWARE_V1
              UART1_SendString("AT+CIPCLOSE\r\n");
#endif
#ifdef HARDWARE_V0
              UART3_SendString("AT+CIPCLOSE\r\n");
#endif
#ifdef HARDWARE_V2
              UART2_SendString("AT+CIPCLOSE\r\n");
#endif
            } else {
              if (connecting == 15) {
                connecting = 16;
#ifdef HARDWARE_V1
                UART1_SendString("AT+CIPSTART=\"TCP\",\"114.132.175.69\",8032\r\n");  // ???????
                                                                                      // UART1_SendString("AT+CIPSTART=\"TCP\",\"159.75.153.108\",8032\r\n");//?????????
                                                                                      // UART1_SendString("AT+CIPSTART=\"TCP\",\"192.168.5.109\",8032\r\n");//?????????
#endif
#ifdef HARDWARE_V0
                UART3_SendString("AT+CIPSTART=\"TCP\",\"114.132.175.69\",8032\r\n");  // ???????
                                                                                      // UART3_SendString("AT+CIPSTART=\"TCP\",\"159.75.153.108\",8032\r\n");//?????????
                                                                                      // UART3_SendString("AT+CIPSTART=\"TCP\",\"192.168.5.109\",8032\r\n");//?????????
#endif
#ifdef HARDWARE_V2
                UART2_SendString("AT+CIPSTART=\"TCP\",\"114.132.175.69\",8032\r\n");  // ???????
                                                                                      // UART3_SendString("AT+CIPSTART=\"TCP\",\"159.75.153.108\",8032\r\n");//?????????
                                                                                      // UART3_SendString("AT+CIPSTART=\"TCP\",\"192.168.5.109\",8032\r\n");//?????????
#endif
              } else {
                if (connecting == 20) {
                  connecting = 21;
                  get_rssi_time = 52000;
                  Send_Tick();
                } else {
                  if (connecting > 30) {
                    connecting = 1;
                  }
                }
              }
            }
          }
        }
        Tick();
      }
    }
