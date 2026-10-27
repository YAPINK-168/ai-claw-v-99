//****************************************************************************

//****************************************************************************
/* Define to prevent recursive inclusion -----------------------------*/
#ifndef __IIC_H
#define __IIC_H
#include "sys.h"
#include "stm32_cpu.h"
 
extern u16 IIC_Delay_Cnt;

#define AT24LOAD_ADD_DATA 0x68

#define enumer AT2404

//extern u8 ee[];
//extern u8 Save_Flag;
//extern u8 AT24_Data[];
#define  ERROR_Cnt 10     //允许ERROR的最大次数 
#if Yiputen==0
	#define  SDA_Set_1   GPIOD_BSRR|=GPIO_Pin_15          //PC7    7
	#define  SDA_Res_0   GPIOD_BRR|=GPIO_Pin_15     
	
	#define  SCL_Set_1   GPIOC_BSRR|=GPIO_Pin_9          //PC8    2
	#define  SCL_Res_0   GPIOC_BRR|=GPIO_Pin_9 

	#define  SDA_Read    (GPIOD_IDR>>15)&0x01
	#define  SCL_Read    (GPIOC_IDR>>9)&0x01
#endif

#define  RW_Write			0xa0 /* 写操作 */
#define  RW_Read			0xa1 /* 读操作 */

//#define  RW8025_Write			0x64 /* 写操作 */
//#define  RW8025_Read			0x65 /* 读操作 */

//#define EEPROM_Flag 0xa55a//	
//#define EEPROM_Flag_Addr_Start1  0  

//#define EEPROM_Blank  5	

//#define EEPROM_IP_Addr_Start1  10  
//#define EEPROM_IP_Addr_Lenth   9  //8+1  *2=16+10余量
//#define EEPROM_IP_Addr_Start2  EEPROM_IP_Addr_Start1+EEPROM_IP_Addr_Lenth+EEPROM_Blank  

//#define EEPROM_Keys_Addr_Start1  32  
//#define EEPROM_Keys_Addr_Lenth   64  //64*2=128+10余量
////#define EEPROM_Keys_Addr_Start2  EEPROM_Keys_Addr_Start1+EEPROM_Keys_Addr_Lenth

//#define EEPROM_Enable_Addr_Start1  128  					  
//#define EEPROM_Enable_Addr_Lenth   32  //  余量
//// #define EEPROM_Enable_Addr_Start2  EEPROM_IP_Addr_Start1+EEPROM_IP_Addr_Lenth+EEPROM_Blank  

//#define EEPROM_Para_Addr_Start1  160  
//#define EEPROM_Para_Addr_Lenth   32  //160+32*2    余量
//#define EEPROM_Para_Addr_Start2  EEPROM_Para_Addr_Start1+EEPROM_Para_Addr_Lenth  

//#define EEPROM_Data_PC_Start1  256  
//#define EEPROM_Data_PC_Lenth   32  //256+32*4  余量


enum  eepromtype {AT2401,AT2402,AT2404,AT2408,AT2416,AT2432,AT2464,AT24128,AT24256,};/*器件的型号*/

void Start(void);  /*   启动总线   */
void Stop(void);   /*   停止IIC总线   */
unsigned char  RecAck(void); /*   检查应答位   */
void NoAck(void);  /*   不对IIC总线产生应答   */
void Ack(void);    /*   对IIC总线产生应答   */
unsigned char Receive(void); /*   从IIC总线上读数据子程序  */
void Send(unsigned char sendbyte); /*   向IIC总线写数据   */
unsigned char   RW24xx(unsigned char *DataBuff,unsigned int Length,unsigned int Addr,
                     unsigned char Control,enum eepromtype enumer);
unsigned char   RW8025(unsigned char *DataBuff,unsigned char Length,unsigned int Addr,
                     unsigned char Control);
void AT24_Write(u8 *iData,u8 Hadd,u8 Ladd,u8 Num);
void AT24_Read(u8 *ERbuf,u8 Hadd,u8 Ladd,u8 Num);
void IIC_Test(void);
void Delay(u32 cnt);
#endif /* __IIC_H */
/************************ (C) COPYRIGHT 2012 Linsir ******END OF FILE****/
