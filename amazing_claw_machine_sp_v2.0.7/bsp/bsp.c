#include "bsp.h"


volatile uint32_t g_sys_tick_count = 0;


uint32_t BSP_GetTick(void) { return g_sys_tick_count; }

