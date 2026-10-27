#ifndef __BSP_H
#define __BSP_H

#include <stdint.h>
#include <stdio.h>
#include "stm32_cpu.h"

#define TRUE 1
#define FALSE 0
#define OK 1
#define FAIL 0


uint32_t BSP_GetTick(void);

#endif
