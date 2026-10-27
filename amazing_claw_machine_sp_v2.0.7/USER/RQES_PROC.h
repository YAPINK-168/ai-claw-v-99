
#ifndef __RQES_PROC_H
#define __RQES_PROC_H

#include "sys.h"
#include "stm32_cpu.h"

extern u8 Vest;
extern u8 Out_sflay;

typedef struct{

Mybit Req;
Mybit Res;


}COMSEND_Type;

extern COMSEND_Type Com;
extern COMSEND_Type Enable;
extern COMSEND_Type Sout;
extern u8 Res_delay;
extern u8 Eensendflay;
extern u8 Sensortimesend; 
extern u8 billtime;
extern u8 rcetime;
extern u8 vesttimeflay;

void Res_proc(void);
void Req_proc(void);


#endif


