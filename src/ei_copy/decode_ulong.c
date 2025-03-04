// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

#ifndef EI_64BIT
int ei_decode_ulong(const char *buf, int *index, unsigned long *p)
{
  const char *s = buf + *index;
  const char *s0 = s;
  unsigned long n;
  long sn;
  int arity;

  switch (get8(s)) {
  case ERL_SMALL_INTEGER_EXT:
    n = get8(s);
    break;
    
  case ERL_INTEGER_EXT:
    sn = get32be(s);
    if (sn < 0) return -1;
    n = (unsigned long)sn;
    break;
    
  case ERL_SMALL_BIG_EXT:
    arity = get8(s);
    goto decode_big;

  case ERL_LARGE_BIG_EXT:
    arity = get32be(s);

  decode_big:
    {
      int sign = get8(s);
      int i;
      n = 0;

      if (sign) return -1;

      /* Little Endian, up to four bytes always fit into unsigned long */
      for (i = 0; i < arity; i++) {
	if (i < 4) {
	  n |= get8(s) << (i * 8);
	} else if (get8(s) != 0) {
	  return -1; /* All but first byte have to be 0 */
	}
      }
    }
    break;
    
  default:
    return -1;
  }

  if (p) *p = (unsigned long)n;
  *index += s-s0;
  
  return 0; 
}
#endif /* EI_64BIT */
