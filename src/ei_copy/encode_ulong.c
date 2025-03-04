// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

#ifndef EI_64BIT
int ei_encode_ulong(char *buf, int *index, unsigned long p)
{
  char *s = buf + *index;
  char *s0 = s;

  if (p > ERL_MAX) {
    if (!buf) s += 7;
    else {
      put8(s,ERL_SMALL_BIG_EXT);
      put8(s,4);	             /* len = four bytes */
      put8(s, 0);                 /* save sign separately */
      put32le(s,p);               /* OBS: Little Endian, and p now positive */
    }
  }
  else if ((p < 256) && (p >= 0)) {
    if (!buf) s += 2;
    else {
      put8(s,ERL_SMALL_INTEGER_EXT);
      put8(s,(p & 0xff));
    }
  }
  else {
    if (!buf) s += 5;
    else {
      put8(s,ERL_INTEGER_EXT);
      put32be(s,p);
    }
  }

  *index += s-s0; 

  return 0; 
}
#endif /* EI_64BIT */
