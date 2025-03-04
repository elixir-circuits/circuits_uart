// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

#define abs(p) (((p)<0) ? -(p) : p)

/* long -> erl_integer */
/* note that this is the only place where data is stored Little Endian */

#ifndef EI_64BIT
int ei_encode_long(char *buf, int *index, long p)
{
  char *s = buf + *index;
  char *s0 = s;

  if ((p < 256) && (p >= 0)) {
    if (!buf) s += 2;
    else {
      put8(s,ERL_SMALL_INTEGER_EXT);
      put8(s,(p & 0xff));
    }
  }
  else if ((p <= ERL_MAX) && (p >= ERL_MIN)) {
    /* FIXME: Non optimal, could use (p <= LONG_MAX) && (p >= LONG_MIN)
       and skip next case */
    if (!buf) s += 5;
    else {
      put8(s,ERL_INTEGER_EXT);
      put32be(s,p);
    }
  }
  else {
    if (!buf) s += 7;
    else {
      put8(s,ERL_SMALL_BIG_EXT);
      put8(s,4);	         /* len = four bytes */
      put8(s, p < 0);            /* save sign separately */
      put32le(s, abs(p));        /* OBS: Little Endian, and p now positive */
    }
  }
  
  *index += s-s0; 

  return 0; 
}
#endif /* EI_64BIT */
