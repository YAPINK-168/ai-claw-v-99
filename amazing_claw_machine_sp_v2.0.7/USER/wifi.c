#include "basic.h"
#include "string.h"
#include "wifi.h"
#include "extern.h"

void Clear_buf(void)
{
	usart1_cnt=0;  //清空USART2的接收个数
	memset((char *)usart1_buf,0,sizeof(usart1_buf)); //清空USART2的接收数组
}

