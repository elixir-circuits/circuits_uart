// SPDX-FileCopyrightText: Ericsson AB 1998-2014. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

int ei_decode_tuple_header(const char *buf, int *index, int *arity)
{
  const char *s = buf + *index;
  const char *s0 = s;
  int i;

  switch ((i=get8(s))) {
  case ERL_SMALL_TUPLE_EXT:
    if (arity) *arity = get8(s);
    else s++;
    break;
    
  case ERL_LARGE_TUPLE_EXT:
    if (arity) *arity = get32be(s);
    else s += 4;
    break;
    
  default:
    return -1;
  }
  
  *index += s-s0; 

  return 0;
}

int ei_decode_map_header(const char *buf, int *index, int *arity)
{
  const char *s = buf + *index;
  const char *s0 = s;
  int i;

  switch ((i=get8(s))) {
  case ERL_MAP_EXT:
    if (arity) *arity = get32be(s);
    else s += 4;
    break;

  default:
    return -1;
  }

  *index += s-s0;

  return 0;
}
