#ifndef _bsp_stm32_flash_H
#define _bsp_stm32_flash_H

#include "stm32f10x_flash.h"
//#include "TypeConfig.h"

//用户根据自己的需要设置
#define STM32_FLASH_SIZE 256 	 //所选STM32的FLASH容量大小(单位为K)

//从指定地址开始写入指定长度的数据
//WriteAddr:起始地址(此地址必须为2的倍数)
//pBuffer:数据指针
//NumToWrite:半字(16位)数(就是要写入的16位数据的个数.)
#if STM32_FLASH_SIZE<256
	#define STM32_SECTOR_SIZE 1024 //字节
#else 
	#define STM32_SECTOR_SIZE	2048
#endif	


//FLASH起始地址
#define STM32_FLASH_BASE 0x08000000 	//STM32 FLASH的起始地址
#define FLASH_APP1_ADDR  0x08008000
#define FLASH_APP2_ADDR  0x08023800
#define FLASH_DATA_ADDR  0x0803F000

typedef  void (*iapfun)(void);				//定义一个函数类型的参数.

typedef enum
{
    FLASH_OK = 0,
    FLASH_ADDR_ERROE,
    FLASH_RW_ERROR
}FLASH_RW_STATUS_ENUM;
 
vu16 STM32_FLASH_ReadHalfWord(u32 faddr); 
void STM32_FLASH_Write(u32 WriteAddr,u16 *pBuffer,u16 NumToWrite);		//从指定地址开始写入指定长度的数据
void STM32_FLASH_Read(u32 ReadAddr,u16 *pBuffer,u16 NumToRead);   		//从指定地址开始读出指定长度的数据

void WriteFlashOneWord(uint32_t WriteAddress, uint32_t WriteData);


void iap_load_app(u32 appxaddr);			//跳转到APP程序执行
u8 iap_write_appbin(u32 WriteAddr,u16 *pBuffer,u32 NumToWrite);

#endif
