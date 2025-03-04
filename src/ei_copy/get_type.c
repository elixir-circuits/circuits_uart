// SPDX-FileCopyrightText: Ericsson AB 1998-2013. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

#include "eidef.h"
#include "eiext.h"
#include "putget.h"

/* report type identifier from the start of the buffer */
/* for types with meaningful length attributes, return the length too.
   In other cases, return length 0 */

/* FIXME working on this one.... */

int ei_get_type(const char *buf, const int *index, int *type, int *len)
{
    return ei_get_type_internal(buf, index, type, len);
}

   
int ei_get_type_internal(const char *buf, const int *index,
			 int *type, int *len)
{
  const char *s = buf + *index;

  *type = get8(s);
  
  switch (*type) {
  case ERL_SMALL_ATOM_EXT:
  case ERL_SMALL_ATOM_UTF8_EXT:
    *type = ERL_ATOM_EXT;
  case ERL_SMALL_TUPLE_EXT:
    *len = get8(s);
    break;

  case ERL_ATOM_UTF8_EXT:
    *type = ERL_ATOM_EXT;
  case ERL_ATOM_EXT:
  case ERL_STRING_EXT:
    *len = get16be(s);
    break;

  case ERL_FLOAT_EXT:
  case NEW_FLOAT_EXT:
    *type = ERL_FLOAT_EXT;
    break;

  case ERL_LARGE_TUPLE_EXT:
  case ERL_LIST_EXT:
  case ERL_BINARY_EXT:
    *len = get32be(s);
    break;
    
  case ERL_SMALL_BIG_EXT:
    *len = get8(s); /* #digit_bytes */
    break;

  case ERL_LARGE_BIG_EXT:
    *len = get32be(s); /* #digit_bytes */
    break;

  default:
    *len = 0;
    break;
  }

  /* leave index unchanged */
  return 0;
}


