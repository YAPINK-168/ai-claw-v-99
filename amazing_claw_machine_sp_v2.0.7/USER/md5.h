#ifndef _MD5_H_
#define _MD5_H_	

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#include "stm32f10x.h"

typedef   unsigned   long   int   UINT4; 
void   MD5Digest(char   *pszInput,   unsigned   long   nInputSize,   char   *pszOutPut)  ;
void   Decode(UINT4   *output,   unsigned   char   *input,   unsigned   int   len)  ;


#endif 



