#ifdef HARDWARE_V2

#include "basic.h"
#include "extern.h"
#include "net.h"
#include "string.h"

/*******************************************************************************
 *   AT+QIOPEN    建立TCP连接或注册UDP端口号		   AT+QIOPEN="TCP","120.25.246.186",9989
 *  	AT+QISEND    发送TCP或UDP数据
 *	  AT+QICLOSE   关闭TCP或UDP连接
 *	  AT+QIDEACT   关闭GPRS/CSD PDP场景
 *	  AT+QIACT     激活移动场景（或发起GPRS/CSD无线连接）
 *   AT+QILOCIP   获取本地IP
 *   AT+QISTAT    查询当前连接状态
 *   AT+QIDNSGIP  域名解析	   AT+QIDNSGIP=<domain name>	  domain name 域名
 *	AT+QIDNSIP   配置使用IP连接还是域名连接		AT+QIDNSIP=0  0 IP  1 域名
 *	AT+QIHEAD    配置接收数据是否显示IP头       AT+QIHEAD=0   0 不显示  1 显示
 *	AT+QIPROMPT  设置发送数据时是否显示“>”和"SEND OK"	  AT+QIPROMPT=0 发送成功时
 *	AT+QISCON    保存TCPIP应用场景配置
 *
 *	AT+QIMODE    配置TCPIP应用模式     	AT+QIMODE=0 非透传  AT+QIMODE=1 透传
 *	AT+QITCFG	 配置透明传输模式       AT+QITCFG=2,2,200	 一个IP包重发2次，间隔200ms ， 每次发送200字节
 *	AT+QINDI     配置是否缓存接收到的数据   	 AT+QINDI=0 不缓存 直接输出到串口 AT+QINDI=1  缓存 通过AT+QIRD读取
 *
 *  1、退出透传 +++    2、关闭TCP或UDP连接  AT+QICLOSE   	3、关闭GPRS/CSD PDP场景	AT+QIDEACT   4、激活移动场景 AT+QIACT	  5, 配置TCPIP应用模式 AT+QIMODE=1
 *******************************************************************************/

void BUF_CLR(void)  // 清零
{
  mymemclr((u8*)RX2_buffer, 80);
  RX2count = 0;
  M26netflay = 0;
}
////hoid("POWERED DOWN",RX3_buffer)?
// hoid("CONNECT",5)
u8 chakzha(char* p, char* s) {
  u8 i, j = 0;
  for (i = 0; i < strlen(s); i++)  // strlen(p)
  {
    if (s[i] == p[0]) {
      for (j = 0; j < strlen(p); j++) {
        if (s[i + j] != p[j]) {
          j = 0;
          break;
        }
      }
      if (j >= strlen(p)) {
        j += i;
        return j;
      }
    }
  }
  return 0;
}

////////////////////////////////////////////////////////////////////////
// hoid("POWERED DOWN",5)?
// 开机
// UART2_SendString("AT\r\n\0");//发送命令AT回复OK
// hoid("OK",2)开机
u8 hoid(char* ss, u8 tm) {
  M26delaytime = tm;
  while (M26delaytime) {
    IWDG_KR = 0xaaaa;
    if (M26netflay) {
      if (chakzha(ss, (char*)RX2_buffer)) {
        M26netflay = 0;
        M26delaytime = 0;
        return 1;
      }
      // else return 0;
    }
  }
  return 0;
}

////////////////////////////////////////////////////////////////////////
u8 hoidser(char* ss, char* sa, char* sb, u8 tm) {
  M26delaytime = tm;
  while (M26delaytime) {
    // IWDG_KR=0xaaaa;
    if (M26netflay) {
      if (chakzha(ss, (char*)RX2_buffer)) {
        M26netflay = 0;
        M26delaytime = 0;
        return 1;
      }
      if (chakzha(sa, (char*)RX2_buffer)) {
        M26netflay = 0;
        M26delaytime = 0;
        return 2;
      }
      if (chakzha(sb, (char*)RX2_buffer)) {
        M26netflay = 0;
        M26delaytime = 0;
        return 3;
      }
      // else return 0;
    }
  }
  return 0;
}

#endif
