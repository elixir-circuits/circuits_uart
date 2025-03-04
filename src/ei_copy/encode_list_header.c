// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

int ei_encode_list_header(char *buf, int *index, int arity)
{
  char *s = buf + *index;
  char *s0 = s;

  if (arity < 0) return -1;
  else if (arity > 0) {
    if (!buf) s += 5;
    else {
      put8(s,ERL_LIST_EXT);
      put32be(s,arity);
    }
  }
  else {
    /* empty list */
    if (!buf) s++;
    else put8(s,ERL_NIL_EXT);
  }

  *index += s-s0; 

  return 0;
}
