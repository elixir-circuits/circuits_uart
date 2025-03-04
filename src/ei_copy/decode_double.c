// SPDX-FileCopyrightText: Ericsson AB 1998-2010. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include <stdio.h>
#include "eidef.h"
#include "eiext.h"
#include "putget.h"


int ei_decode_double(const char *buf, int *index, double *p)
{
  const char *s = buf + *index;
  const char *s0 = s;
  FloatExt f;

  switch (get8(s)) {
    case ERL_FLOAT_EXT:
      if (sscanf(s, "%lf", &f.d) != 1) return -1;
      s += 31;
      break;
    case NEW_FLOAT_EXT:
      /* IEEE 754 format */
      f.val = get64be(s);
      break;
    default:
      return -1;
  }

  if (p) *p = f.d;
  *index += s-s0; 
  return 0; 
}
