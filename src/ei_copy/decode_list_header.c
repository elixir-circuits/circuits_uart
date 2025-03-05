// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

int ei_decode_list_header(const char *buf, int *index, int *arity)
{
  const char *s = buf + *index;
  const char *s0 = s;

  switch (get8(s)) {
  case ERL_NIL_EXT:
    if (arity) *arity = 0;
    break;
    
  case ERL_LIST_EXT:
    if (arity) *arity = get32be(s);
    else s+= 4;
    break;

  default:
    return -1;
  }
  
  *index += s-s0; 

  return 0;
}
