#include "stm32_cpu.h"


#define SlaveAddress  0xA0 
#define PIN_SCL    GPIO_Pin_10  
#define PIN_SDA    GPIO_Pin_11 
#define I2C_PORT   GPIOB  




void Write_continuity(u16 REG_Address,u16 len,u8* table);//连续写
void Read_continuity(u16 REG_Address,u16 len,u8* table);//连续读	
void Single_Write_Device(u16 REG_Address,u8 REG_data);
u8 Single_Read_Device(u8 REG_Address);

