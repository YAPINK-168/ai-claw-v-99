#include "stm32f10x_type.h"

extern u8 M26netflay;
extern u8 M26delaytime;
extern u8 Errcode;  // 1:开机不成功  2：  3：静态设置 4：单路设置 5：设置wifi 6：连接服务器
extern u16 Tick_ReqKeep_OnLine_time;
extern u16 Time_10ms_cnt;

extern u8 neton;
extern u16 off_line_time;
extern u8 dispdelay;
extern u8 sendbusy;
extern u8 nowififlag;
// extern u8 keylockpc13;

extern u8 coinin;
extern u8 enterkeyvalue;
extern u8 setkeyvalue;
extern u8 frontkeyvalue;
extern u8 rightkeyvalue;
extern u8 leftkeyvalue;
extern u8 backkeyvalue;
extern u16 front_back_point;
extern u16 right_left_point;
extern u16 front_back_point_fixedpoint;
extern u16 right_left_point_fixedpoint;
extern u8 clawpower[6];
extern u8 roundoffset;
extern u16 surprisecount;
extern u8 machinedisable;

extern u8 coininaddr;
extern u8 coininlen;
extern u8 coinbaseaddr;
extern u8 coinbaselen;
extern u8 roundbaseaddr;
extern u8 roundbaselen;
extern u8 lightclawaddr;
extern u8 lightclawlen;
extern u8 strongclawaddr;
extern u8 strongclawlen;
extern u8 gametimebaseaddr;
extern u8 gametimebaselen;
extern u8 roundoffsetaddr;
extern u8 roundoffsetlen;
extern u8 surprisecountaddr;
extern u8 surprisecountlen;
extern u8 allcoinaddr;
extern u8 allcoinlen;
extern u8 alltoyaddr;
extern u8 alltoylen;
extern u8 swingpulladdr;
extern u8 swingpulllen;
extern u8 fixedpointaddr;
extern u8 fixedpointlen;
extern u8 upspeedaddr;
extern u8 upspeedlen;
extern u8 downspeedaddr;
extern u8 downspeedlen;
extern u8 front_back_point_fixedpointaddr;
extern u8 front_back_point_fixedpointlen;
extern u8 right_left_point_fixedpointaddr;
extern u8 right_left_point_fixedpointlen;
extern u8 clawgettwosteptimeaddr;
extern u8 clawgettwosteptimelen;

extern u8 factaryset;
extern u8 factarysetaddr;
extern u8 factarysetlen;

extern u8 setcursor;
extern u8 setfinishing;
extern u8 gametimeflash;
extern u8 setlongkeytime;
extern u8 setlongkey;
extern u8 gamestatus;
extern u8 beginning;
extern u8 gametime;
extern u8 gametimebase;

extern u8 gameruntime;

extern u8 claw;
extern u8 POWERONFLAG;
extern u8 CLAWDOWNFLAG;
extern u8 CLAWUPFLAG;
extern u8 CLAWTOYFLAG;
extern u8 COININFLAG;
extern u8 COININTESTFLAG;
extern u8 GAMEWAITFLAG;
extern u8 WARMFLAG;
extern u8 WINFLAG;
extern u8 GAMEINGFLAG;
extern u8 GAMEBACKFLAG;

extern u8 strongclaw;
extern u8 lightclaw;
extern u8 roundnum[120];
extern u8 random_mod_point;
extern u8 toynum[120];
extern u8 roundadd[120];

extern u8 roundround;
extern u8 outsentorflag;
extern u8 gameoverflag;
extern u16 clawgettwosteptime;
extern u16 swingpull;
extern u16 upstoptime;
extern u16 downstoptime;
extern u16 linelength;
extern u8 fixedpoint;
extern u8 fixedpointing;
extern u16 machineid;

extern u16 pulllengthtime;

extern u8 machineidcode[5];  //={"10055"};
extern u8 machineidaddr;
extern u8 machineidlen;

extern u8 gsmsetdatabuff[70];
extern u8 gsmgetdatabuff[70];
//[n|00001|7|01|12345678|sign]#$-$#
extern u8 gsmrealtimecoinindatabuff[66];
extern u8 gsmrealtimetoyoutdatabuff[66];

extern u8 difficultset;
extern u8 difficultsetaddr;
extern u8 difficultsetlen;

extern u16 clawgetonesteptime;  // 第一段最开始抓取高度
extern u8 clawgetonesteptimeaddr;
extern u8 clawgetonesteptimelen;
extern u16 clawgetonesteptimevalue;

extern u16 clawgetthreesteptime;  // 第三段拖拽抓取时间
extern u8 clawgetthreesteptimeaddr;
extern u8 clawgetthreesteptimelen;
extern u16 clawgetthreesteptimevalue;

extern u8 lostclaw;  // 强抓力度
extern u8 lostclawaddr;
extern u8 lostclawlen;

extern u8 leftrightspeed;  // 上升时间
extern u8 leftrightspeedaddr;
extern u8 leftrightspeedlen;

extern u8 groundstongclaw;  // 弱抓力度
extern u8 groundstongclawaddr;
extern u8 groundstongclawlen;

extern u16 downtimeset;
extern u8 downtimesetaddr;
extern u8 downtimesetlen;

extern u16 downdelayset;
extern u8 downdelaysetaddr;
extern u8 downdelaysetlen;

extern u8 pulllength;
extern u8 pulllengthsetaddr;
extern u8 pulllengthsetlen;

extern u16 updelaytime;  // 上停时间
extern u8 updelaytimeaddr;
extern u8 updelaytimelen;

extern u16 uppulllength;  // 上拉
extern u8 uppulllengthaddr;
extern u8 uppulllengthlen;

extern u16 uppulltime;  // 上放
extern u8 uppulltimeaddr;
extern u8 uppulltimelen;

extern u8 outbase;  // 上放   到顶就放，这里不暂时不用停留
extern u8 outbaseaddr;
extern u8 outbaselen;

extern u8 outcount;  // 上放   到顶就放，这里不暂时不用停留
extern u8 outcountaddr;
extern u8 outcountlen;

extern u8 clampingdate;
extern u8 clampingnum;  // 保夹次数
extern u8 clampingnumaddr;
extern u8 clampingnumlen;

extern u8 secondclaw;
extern u8 secondclawaddr;
extern u8 secondclawlen;

extern u8 gamemode;
extern u8 gamemodeaddr;
extern u8 gamemodelen;

extern u16 version_code;
extern u8 version_codeaddr;
extern u8 version_codelen;

extern u16 version_code_z;
extern u8 version_code_zaddr;
extern u8 version_code_zlen;

extern u16 secondclaw_delay;
extern u16 secondclaw_delay_addr;
extern u8 secondclaw_delay_len;

extern u16 Crane_delay;
extern u16 Crane_delay_addr;
extern u8 Crane_delay_len;

extern u16 Rise_delay;
extern u16 Rise_delay_addr;
extern u8 Rise_delay_len;

extern u8 pulllengthbuff[4];
extern u8 coinbasebuff[4];         // 多少币抓一次1-30    1
extern u8 roundbasebuff[4];        // 多少局得到1-99      2
extern u8 lostclawbuff[4];         // 释放力度10-99       3
extern u8 groundstongclawbuff[4];  // 底部抓取力度10-99   4
extern u8 lightclawbuff[4];        // 保持抓力度10-99     5
extern u8 strongclawbuff[4];       // 强抓力度10-99       6

extern u8 gametimebasebuff[4];  // 每局时间10-60        7
extern u8 roundoffsetbuff[4];   // 偏移量0-10           8
extern u8 swingpullbuff[4];     // 甩开关0/1            9
extern u8 factarysetbuff[4];    // 出厂设置标记0/1      10
extern u8 machineidbuff[7];     // 机器编号00000-99999        11

extern u8 upspeedbuff[4];         // 上升时间10-99       12
extern u8 downspeedbuff[4];       // 下爪时间10-99       13
extern u8 leftrightspeedbuff[4];  // 左右速度10-99       14

extern u8 fixedpointbuff[4];                   // 定点落物开关0/1       15
extern u8 front_back_point_fixedpointbuff[7];  // 定点落物前后坐标1000-50000   16
extern u8 right_left_point_fixedpointbuff[7];  // 定点落物左右坐标1000-50000   17

extern u8 clawgetonesteptimebuff[7];    // 第一段最开始抓取高度  底部高度100-3000    18
extern u8 clawgettwosteptimebuff[7];    // 第二段抓取高度100-5000                    19
extern u8 clawgetthreesteptimebuff[7];  // 第三段拖拽抓取时间100-5000                20

extern u8 gamemodebuff[4];     // 游戏模式               20
extern u8 clampingnumbuff[4];  //               20
extern u8 uppulltimebuff[4];   //               20
extern u8 outbasebuff[7];      //               20

extern u8 setflag;
extern u8 inquirebillflag;
extern u16 inquiresetflagl;
extern u16 inquiresetflagh;
extern u8 inquirecoininflag;
extern u8 inquireallcoinflag;
extern u8 inquiresuppriseflag;

extern u8 gsmupdatabuff[67];

extern u16 downtime;

extern u8 buf3[10];
extern u8 buf2[14];
extern u8 buf44[6];
extern u8 buf55[7];
extern u8 buf22[4];
extern u8 machineidcode[5];

extern u8 losesqr;
extern u8 Second1;
extern u8 Second2;
extern u8 Second3;
extern u8 connecting;
extern volatile u8 cointime;
extern volatile u8 cointimeH;
extern volatile u8 cointimeL;
extern volatile u8 losetimeH;
extern volatile u8 losetimeL;
extern u8 keysun;
extern u8 wifiseten;
// IRQ
// extern u8  RX1_buffer[300];

#if defined(HARDWARE_V0) || defined(HARDWARE_V1)
extern u8 RX1_buffer[300];
extern u8 RX3_buffer[300];
#endif

#ifdef HARDWARE_V2
extern u8 RX1_buffer[300];
extern u8 RX2_buffer[300];
#endif

// extern u8 wifi[100];
extern u8 RX1count;
extern u8 RX16count;
extern u8 RX2count;
extern u8 RX3count;

extern char GsmCq[6];
extern u8 GsmCqconut;

extern u8 USART2_Rx_time;
extern u8 USART1_Rx_time;

extern u8 screen;
extern u8 counten;
extern u8 coininen;
extern u8 reszer;
extern u8 coinined;

extern u8 reconnect;

extern const char *McNoZ;

// extern u8 Cartnum[9];//卡号
// extern u8 Count[6];//余额
////extern u8 Screnub[17];//密钥
// extern u8 Coinnum[4];//投币金额
// extern u8 Qrnum[10];//Qr码
// extern u8 QrCH[10];//充值Qr码

// extern u8 Userid[12];//用户id
// extern u8 UsrCH[12];//用户id

// extern u8 Userid0[12];//用户id
// extern u8 paymoney[4];//支付金额

// extern u8 strcoinin[63];//投币
// extern u8 strrequkey[69];//请求卡密钥

// extern u8 strrequcoinpay[61];//请求卡扣款
// extern u8 strrequqr[63];//请求二维码
// extern u8 strrequrech[60];//充值

// extern u8  changesq[68];

extern u8 tickinfo[25];  // 心跳

// extern volatile u8 Qrnumdisp[110];
// extern volatile u8 Qrnumdisp[86];

extern u8 readcardbusy;
extern u8 readcardonly;
extern u8 coininening;
extern u8 readcardcount;
extern u8 Time2_trup_cnt;

extern u8 roundbase;
extern u8 coinbase;
extern u16 allcoin;
extern u16 alltoy;

extern u8 upspeed;
extern u8 downspeed;

extern u8 readtime;

// main
extern u8 nettime;
extern u8 netenable;
extern u8 combusy;

extern u8 disp_QR;
extern u8 resqr;

extern u8 userscan;
extern u8 userpayed;

extern __IO u8 reconnect_flag;
extern u16 updata_flag[2];
extern u8 breakdown;
extern u8 winflag_tim;

extern u8 coin_sign_flag;

extern u8 custom_led_flag;
extern uint16_t custom_led_on_time;
extern uint16_t custom_led_off_time;

extern void GsmSend(char *p);
extern void Add_md5_keymark_coin(u8 *str);
extern void Add_md5_keymark_coinin(u8 *str);
extern void Add_md5_keymark_gsmupdatabuff(u8 *str);
extern void Add_md5_keymark_gsmsetdatabuff(u8 *str);
extern void Add_md5_keymark_gsmgetdatabuff(u8 *str);
extern void Add_md5_keymark_gsmsetyoudatabuff(u8 *str);
extern void Add_md5_keymark_gsmcoinindatabuff(u8 *str);
extern void Add_md5_keymark_gsmtoyoutdatabuff(u8 *str);
extern void Add_md5_keymark_COU(u8 *str);
extern void Add_md5_keymark_rech(u8 *str);
extern void Add_md5_keymark_Pay(u8 *str);
extern void Add_md5_keymark_QR(u8 *str);
extern void Add_md5_keymark_CHSQ(u8 *str);
extern void UART1_len(u8 *data, u8 length);
extern void UART1_Send(u8 dat);

extern void BUF_CLR(void);

extern void LCDdisplay(u8 dispcode);
extern void Tick(void);
extern void Send_Tick(void);
extern u8 hoid(char *ss, u8 tm);
