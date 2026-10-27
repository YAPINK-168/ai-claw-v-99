
#ifndef __SENSOR_H
#define __SENSOR_H

#include "sys.h"
#include "stm32_cpu.h"


extern u8 NoCoin;
extern u8 EyeTime;//光眼检测时长
extern u8 NoCoin;//退币器无币标志
extern  u8 NOTime;//无人检测时间
extern  u8 NoDoor;//开门
extern u8 NoRen;
extern u8 SensorNum;
extern u8 Startime;

void sensor(void);
	
	extern u8 WendS;
	extern u8 Wendchecktime;
	
	#define Keys1  PCout(15)//继电器1
	#define Keys2  PBout(1)//继电器2
	#define Keys3  PBout(0)//继电器3
	
	void wensor(void);

#endif


