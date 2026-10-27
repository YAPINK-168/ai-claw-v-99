#include "bsp_stm32_flash.h"
#include "sys.h"

iapfun jump2app;
u16 STM32_FLASH_ReadBUF[STM32_SECTOR_SIZE];//最多是2K字节
u16 STM32_FLASH_WriteBUF[STM32_SECTOR_SIZE];//最多是2K字节

//读取指定地址的半字(16位数据)
//faddr:读地址(此地址必须为2的倍数!!)
//返回值:对应数据.
vu16 STM32_FLASH_ReadHalfWord(u32 faddr)
{
	return *(vu16*)faddr; 
} 

//从指定地址开始读出指定长度的数据
//ReadAddr:起始地址
//pBuffer:数据指针
//NumToWrite:半字(16位)数
void STM32_FLASH_Read(u32 ReadAddr,u16 *pBuffer,u16 NumToRead)   	
{
	u16 i;
	
	for( i = 0; i < NumToRead; i++ )
	{
		pBuffer[i] = STM32_FLASH_ReadHalfWord(ReadAddr+i*2);//读取2个字节.	
	}
}

void STM32_FLASH_Write(u32 WriteAddr,u16 *pBuffer,u16 NumToWrite)	
{
	u16 i;
	
	if(WriteAddr<FLASH_APP1_ADDR||
		(WriteAddr>=(FLASH_APP1_ADDR+1024*STM32_FLASH_SIZE)))
		return ;//非法地址 地址不能超出范围
	
	FLASH_Unlock();						//解锁  
	
	FLASH_ErasePage(WriteAddr);

	for(i=0;i<NumToWrite;i++)
	{
		FLASH_ProgramHalfWord(WriteAddr+i*2,pBuffer[i]);
	}
	
	FLASH_Lock();//上锁
}

//WriteAddr:应用程序的起始地址，必须为某扇区的起始地址
//pBuffer:应用程序CODE.
//NumToWrite:应用程序大小(字节).
u8 iap_write_appbin(u32 WriteAddr,u16 *pBuffer,u32 NumToWrite)
{
	u16 i = 0;

	//地址检查
    if (WriteAddr < STM32_FLASH_BASE || (WriteAddr >= (STM32_FLASH_BASE + 1024 * STM32_FLASH_SIZE)))
    {
        return FLASH_ADDR_ERROE;   
    }

    //非扇区首地址
    if(WriteAddr % STM32_SECTOR_SIZE)
    {     
        return FLASH_ADDR_ERROE;
    }

//	for ( i = 0; i < WordLen; i++ )
//	{
//	    STM32_FLASH_WriteBUF[i] = *pbuf++;
//	}
	
    STM32_FLASH_Write(WriteAddr,pBuffer,NumToWrite);
    
    STM32_FLASH_Read(WriteAddr,STM32_FLASH_ReadBUF,NumToWrite);

	for ( i = 0 ; i < NumToWrite; i++ )
	{
	    if ( STM32_FLASH_ReadBUF[i] !=  pBuffer[i] )
		{
		    return FLASH_RW_ERROR;
		}
	}

	return FLASH_OK;
        
}

//跳转到应用程序段
//appxaddr:用户代码起始地址
void iap_load_app(u32 appxaddr)
{
    unsigned char i = 0;
	if(((*(vu32*)appxaddr)&0x2FFE0000)==0x20000000)	//检查栈顶地址是否合法
	{ 
        /* 首地址是MSP，地址+4是复位中断服务程序地址 */
		jump2app=(iapfun)*(vu32*)(appxaddr+4);
            
         /* 关闭全局中断 */
        __set_PRIMASK(1); 
                 
        /* 关闭滴答定时器，复位到默认值 */
        SysTick->CTRL = 0;
        SysTick->LOAD = 0;
        SysTick->VAL = 0;
        
        /* 设置所有时钟到默认状态 */
        RCC_DeInit();
        
        /* 关闭所有中断，清除所有中断挂起标志 */  
        for (i = 0; i < 8; i++)
        {
            NVIC->ICER[i]=0xFFFFFFFF;
            NVIC->ICPR[i]=0xFFFFFFFF;
        }
        
        /* 使能全局中断 */ 
        __set_PRIMASK(0);
        
        /* 在RTOS工程，这条语句很重要，设置为特权级模式，使用MSP指针 */
        __set_CONTROL(0);
        		
        MSR_MSP(*(vu32*)appxaddr);					//初始化APP堆栈指针(用户代码区的第一个字用于存放栈顶地址)
		jump2app();									//跳转到APP.
        
        /* 跳转成功的话，不会执行到这里，用户可以在这里添加代码 */
        while (1)
        {

        }
	}
}		 

