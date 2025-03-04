// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include <string.h>
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

int ei_encode_boolean(char *buf, int *index, int p)
{
  char *s = buf + *index;
  char *s0 = s;
  char *val;
  int len;

  val = p ? "true" : "false";
  len = strlen(val);

  if (!buf) s += 3;
  else {
    put8(s,ERL_ATOM_EXT);
    put16be(s,len);

    memmove(s,val,len); /* unterminated string */
  }
  s += len;

  *index += s-s0; 

  return 0; 
}

