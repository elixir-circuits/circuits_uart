// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

int ei_encode_char(char *buf, int *index, char p)
{
  char *s = buf + *index;
  char *s0 = s;

  if (!buf) s += 2;
  else {
    put8(s,ERL_SMALL_INTEGER_EXT);
    put8(s,(p & 0xff));
  }

  *index += s-s0;
  
  return 0;
}

