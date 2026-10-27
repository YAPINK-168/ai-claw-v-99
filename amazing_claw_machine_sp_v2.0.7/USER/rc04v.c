
#include "rc04v.h"
#include "extern.h"

void delay8US(u8 x)
{
	u16 k;
	for(k=0;k<500;k++);
}

void IIC_Init(void)  
{            
   GPIO_InitTypeDef GPIO_InitStructure;  
   RCC_APB2PeriphClockCmd( RCC_APB2Periph_GPIOB, ENABLE ); //使能A口时钟  
      
   GPIO_InitStructure.GPIO_Pin = PIN_SCL | PIN_SDA;  
   GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP ;       //推挽输出  
   GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;  
   GPIO_Init(I2C_PORT, &GPIO_InitStructure); 
	 GPIO_SetBits(I2C_PORT,PIN_SDA);  //SDA =1  
	 GPIO_SetBits(I2C_PORT,PIN_SCL);  //SCL=1  
}  
void SDA_IN(void)  
{  
   GPIO_InitTypeDef GPIO_InitStruct;  
   GPIO_InitStruct.GPIO_Mode = GPIO_Mode_IPU;    //上拉输入  
   GPIO_InitStruct.GPIO_Speed = GPIO_Speed_50MHz;  
   GPIO_InitStruct.GPIO_Pin = PIN_SDA;  
   GPIO_Init(I2C_PORT, &GPIO_InitStruct );  
}  
void SDA_OUT(void)  
{  
   GPIO_InitTypeDef GPIO_InitStruct;  
   GPIO_InitStruct.GPIO_Mode = GPIO_Mode_Out_PP;   
   GPIO_InitStruct.GPIO_Speed = GPIO_Speed_50MHz;  
   GPIO_InitStruct.GPIO_Pin = PIN_SDA;  
   GPIO_Init(I2C_PORT, &GPIO_InitStruct );  
} 
//产生I2C开始信号  
void Device_Start(void)  
{  
   SDA_OUT();                    //sda线输出  
   GPIO_SetBits(I2C_PORT,PIN_SDA);  //SDA =1  
   delay8US(10);  
   GPIO_SetBits(I2C_PORT,PIN_SCL);  //SCL=1  
   delay8US(10);  
   GPIO_ResetBits(I2C_PORT,PIN_SDA);//SDA=0  
   delay8US(10);  
   GPIO_ResetBits(I2C_PORT,PIN_SCL);//SCL=0  
}    
   
//产生I2C停止信号  
void Device_Stop(void)  
{  
   SDA_OUT();  //sda线输出  
   GPIO_ResetBits(I2C_PORT,PIN_SDA);     
   delay8US(10);  
   GPIO_SetBits(I2C_PORT,PIN_SCL);   
   delay8US(10);  
   GPIO_SetBits(I2C_PORT,PIN_SDA);   
   delay8US(10);  
   GPIO_ResetBits(I2C_PORT, PIN_SCL);//SCL=0;   
   delay8US(10);            
}  
//等待应答信号到来  
//返回值：1，接收应答失败  
//        0，接收应答成功  
u8 I2C_Wait_Ack(void)  
{  
   u8 ucErrTime=0;  
   SDA_IN();      //SDA设置为输入    
   GPIO_SetBits(I2C_PORT,PIN_SDA);  
   delay8US(5);      
   GPIO_SetBits(I2C_PORT,PIN_SCL);   
   delay8US(5);    
   while(GPIO_ReadInputDataBit(I2C_PORT,PIN_SDA))  
   {  
      ucErrTime++;  
      if(ucErrTime>250)  
      {  
         Device_Stop();     
         return 1;  
      }  
   }  
   GPIO_ResetBits(I2C_PORT, PIN_SCL);      
   return 0;    
}  
  
//产生ACK应答  
void I2C_Ack(void)  
{  
   GPIO_ResetBits(I2C_PORT,PIN_SCL);  
   SDA_OUT();  
   GPIO_ResetBits(I2C_PORT,PIN_SDA);  
   delay8US(5);  
   GPIO_SetBits(I2C_PORT,PIN_SCL);  
   delay8US(5);  
   GPIO_ResetBits(I2C_PORT,PIN_SCL);  
}  
  
//不产生ACK应答        
void I2C_NAck(void)  
{  
   GPIO_ResetBits(I2C_PORT,PIN_SCL);  
   SDA_OUT();  
   GPIO_SetBits(I2C_PORT,PIN_SDA);  
   delay8US(5);  
   GPIO_SetBits(I2C_PORT,PIN_SCL);   
   delay8US(5);  
   GPIO_ResetBits(I2C_PORT,PIN_SCL);  
}    
               
//I2C发送一个字节  
//返回从机有无应答  
//1，有应答  
//0，无应答       
void Device_SendByte(u8 txd)  
{                          
    u8 t;     
    SDA_OUT();  
		delay8US(5); 	
    GPIO_ResetBits(I2C_PORT,PIN_SCL);//拉低时钟开始数据传输  
    for(t=0;t<8;t++)  
    {                
        if((txd&0x80)==0x80)     
          {GPIO_SetBits(I2C_PORT, PIN_SDA);}//SDA=1，写 1                  
        else    
          {GPIO_ResetBits(I2C_PORT, PIN_SDA);}//SDA=0，写 0   
        txd<<=1;      
       delay8US(5);   //对TEA5767这三个延时都是必须的    
       GPIO_SetBits(I2C_PORT,PIN_SCL);   
       delay8US(5);   
       GPIO_ResetBits(I2C_PORT,PIN_SCL);  
       delay8US(5);  
    }    
}       
  
//读1个字节，ack=1时，发送ACK，ack=0，发送nACK     
u8 Device_RecvByte(unsigned char ack)  
{  
    unsigned char i,receive=0;  
    SDA_IN();//SDA设置为输入  
    for(i=0;i<8;i++ )  
 {  
        GPIO_ResetBits(I2C_PORT,PIN_SCL);  
        delay8US(5);  
        GPIO_SetBits(I2C_PORT,PIN_SCL);  
        receive<<=1;  
        if(GPIO_ReadInputDataBit(I2C_PORT,PIN_SDA))receive++;     
        delay8US(5);   
    }        
    if (!ack)  
        I2C_NAck();//发送nACK  
    else  
        I2C_Ack(); //发送ACK     
    return receive;  
}  
 
//******单字节写入*******************************************
void Single_Write_Device(u16 REG_Address,u8 REG_data)
{
    Device_Start();                  //起始信号
    Device_SendByte(SlaveAddress);   //发送设备地址+写信号
	  I2C_Wait_Ack();       
//    Device_SendByte(REG_Address/256);    //内部寄存器地址，H
//		I2C_Wait_Ack();   
		Device_SendByte(REG_Address%256);    //内部寄存器地址，L
		I2C_Wait_Ack();  	
    Device_SendByte(REG_data);       //内部寄存器数据，请参考中文pdf22页 
	  I2C_Wait_Ack(); 
    Device_Stop();                   //发送停止信号
}
//********单字节读取*****************************************
u8 Single_Read_Device(u8 REG_Address)
{  
		u8 REG_data;
    Device_Start();                  //起始信号
    Device_SendByte(SlaveAddress);   //发送设备地址+写信号
	  I2C_Wait_Ack();       
//    Device_SendByte(REG_Address/256);    //内部寄存器地址，H
//		I2C_Wait_Ack();   
		Device_SendByte(REG_Address%256);    //内部寄存器地址，L
		I2C_Wait_Ack();  	
    Device_Start();                          //起始信号
    Device_SendByte(SlaveAddress+1);         //发送设备地址+读信号
	  I2C_Wait_Ack(); 
    REG_data=Device_RecvByte(0);              //读出寄存器数据
    Device_Stop();                           //停止信号
    return REG_data; 
}
void Write_continuity(u16 REG_Address,u16 len,u8* table)//连续写
{
		u16 i;
		Device_Start();                  //起始信号
    Device_SendByte(SlaveAddress);   //发送设备地址+写信号
	  I2C_Wait_Ack();       
    Device_SendByte(REG_Address%256);    //内部寄存器地址，H
		I2C_Wait_Ack();   
		Device_SendByte(REG_Address/256);    //内部寄存器地址，L
		I2C_Wait_Ack();  	
		for(i=0;i<len;i++)
		{
			Device_SendByte(*table++);       //内部寄存器数据，请参考中文pdf22页 
			I2C_Wait_Ack();  	
		}
    Device_Stop();                   //发送停止信号
		delay8US(5);
}
void Read_continuity(u16 REG_Address,u16 len,u8* table)//连续读
{
		u16 i;
    Device_Start();                  //起始信号
    Device_SendByte(SlaveAddress);   //发送设备地址+写信号
	  I2C_Wait_Ack();       
    Device_SendByte(REG_Address%256);    //内部寄存器地址，H
		I2C_Wait_Ack();   
		Device_SendByte(REG_Address/256);    //内部寄存器地址，L
		I2C_Wait_Ack();  	
    Device_Start();                          //起始信号
    Device_SendByte(SlaveAddress+1);         //发送设备地址+读信号
	  I2C_Wait_Ack(); 
		for(i=0;i<len-1;i++)
		{
			*table++=Device_RecvByte(1);              //读出寄存器数据
		}
		*table++=Device_RecvByte(0);              //读出寄存器数据
    Device_Stop();      
		delay8US(5);
}
