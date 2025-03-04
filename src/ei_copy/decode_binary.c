// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include <string.h>
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

int ei_decode_binary(const char *buf, int *index, void *p, long *lenp)
{
  const char *s = buf + *index;
  const char *s0 = s;
  long len;

  if (get8(s) != ERL_BINARY_EXT) return -1;

  len = get32be(s);
  if (p) memmove(p,s,len);
  s += len;

  if (lenp) *lenp = len;
  *index += s-s0; 

  return 0; 
}


