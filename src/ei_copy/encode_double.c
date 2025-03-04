// SPDX-FileCopyrightText: Ericsson AB 1998-2010. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

#include <stdio.h>
#include <string.h>
#include "eidef.h"
#include "eiext.h"
#include "putget.h"
#if defined(HAVE_ISFINITE)
#include <math.h>
#endif

int ei_encode_double(char *buf, int *index, double p)
{
  char *s = buf + *index;
  char *s0 = s;

  /* Erlang does not handle Inf and NaN, so we return an error rather
   * than letting the Erlang VM complain about a bad external
   * term. */
#if defined(HAVE_ISFINITE)
  if(!isfinite(p)) {
      return -1;
  }
#endif

  if (!buf)
    s += 9;
  else {
    /* IEEE 754 format */
    put8(s, NEW_FLOAT_EXT);
    put64be(s, ((FloatExt*)&p)->val);
  }

  *index += s-s0; 

  return 0; 
}

