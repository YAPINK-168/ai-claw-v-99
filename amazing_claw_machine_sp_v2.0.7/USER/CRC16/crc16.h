#ifndef _CRC_16_H_
#define _CRC_16_H_
#include "sys.h"
typedef unsigned char	uint8;
typedef signed char		int8;
typedef unsigned int	uint16;
typedef signed int		int16;
typedef unsigned long	uint32;
typedef signed long		int32;

#define false	0
#define true    1

enum {
    CMD_START_FLAG_INDEX = 0,
    CMD_LENGTH_INDEX,   //1
    CMD_CMD_INDEX,      //2
    CMD_PARA_INDEX      //3
};
#define CMD_END_FLAG_LEN        1
#define CRC16_LENGTH            2

/************************************************************
**compute_crc_16 计算CRC
**check_crc16 检查CRC结果是否正确
************************************************************/
//uint16 compute_crc_16(const uint8 *data, uint32 length);
int8 check_crc16( uint8 *data, uint32 length);
uint16 compute_crc_16( uint8 *data, uint32 length);
#endif

