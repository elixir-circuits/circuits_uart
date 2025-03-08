// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include <string.h>
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

/* FIXME fix or document that special requirements on 
   the in data.... */

int ei_decode_string(const char *buf, int *index, char *p)
{
  const char *s = buf + *index;
  const char *s0 = s;
  int len;
  int i;
  int etype;

  switch (get8(s)) {
  case ERL_STRING_EXT:
    len = get16be(s);

    if (p) {
      memmove(p,s,len); 
      p[len] = (char)0;
    }
    s += len;
    break;

  case ERL_LIST_EXT:
    /* Really long strings are represented as lists of small integers.
     * We don't know in advance if the whole list is small integers,
     * but we decode as much as we can, exiting early if we run into a
     * non-character in the list.
     */
    len = get32be(s);
    if (p) {
      for (i=0; i<len; i++) {
	if ((etype = get8(s)) != ERL_SMALL_INTEGER_EXT) {
	  p[i] = (char)0;
	  return -1;
	}
	p[i] = get8(s);
      }
      p[i] = (char)0;
    }
    else {
      for (i=0; i<len; i++) {
	if ((etype = get8(s)) != ERL_SMALL_INTEGER_EXT) return -1;
	s++;
      }
    }
    /* Check NIL tail */
    if ((etype = get8(s)) != ERL_NIL_EXT) return -1;
    break;

  case ERL_NIL_EXT:
    if (p) p[0] = (char)0;
    break;
    
  default:
    return -1;
  }


  *index += s-s0; 

  return 0; 
}
