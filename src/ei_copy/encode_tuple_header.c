// SPDX-FileCopyrightText: Ericsson AB 1998-2014. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

int ei_encode_tuple_header(char *buf, int *index, int arity)
{
  char *s = buf + *index;
  char *s0 = s;
  
  if (arity < 0) return -1;

  if (arity <= 0xff) {
    if (!buf) s += 2;
    else {
      put8(s,ERL_SMALL_TUPLE_EXT);
      put8(s,arity);
    }
  }
  else {
    if (!buf) s += 5;
    else {
      put8(s,ERL_LARGE_TUPLE_EXT);
      put32be(s,arity);
    }
  }

  *index += s-s0; 

  return 0;
}

int ei_encode_map_header(char *buf, int *index, int arity)
{
  char *s = buf + *index;
  char *s0 = s;

  if (arity < 0) return -1;

  if (!buf) s += 5;
  else {
      put8(s,ERL_MAP_EXT);
      put32be(s,arity);
  }

  *index += s-s0;

  return 0;
}
