// SPDX-FileCopyrightText: Ericsson AB 1998-2013. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

/* since Erlang sends int-lists as either lists or strings, this
 * function can be used when the caller needs an array but doesn't
 * know which type to decode
 */
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

int ei_decode_intlist(const char *buf, int *index, long *a, int *count)
{
  const unsigned char *s = (const unsigned char *)(buf + *index);
  const unsigned char *s0 = s;
  int idx;
  int len;
  int i;

  switch (get8(s)) {
  case ERL_STRING_EXT:
    len = get16be(s);

    /* transfer and cast chars one at a time into array */
    if (a) {
      for (i=0; i<len; i++) {
	a[i] = (long)(s[i]);
      }
    }
    if (count) *count = len;
    s += len;
    break;

  case ERL_LIST_EXT:
    len = get32be(s);
    idx = 0;
    
    if (a) {
      for (i=0; i<len; i++) {
	if (ei_decode_long((char*)s,&idx,a+i) < 0) {
	  if (count) *count = i;
	  return -1;
	}
      }
    }
    else {
      for (i=0; i<len; i++) {
	if (ei_decode_long((char*)s,&idx,NULL) < 0) {
	  if (count) *count = i;
	  return -1;
	}
      }
    }

    if (count) *count = len;
    s += idx;
    break;

  default:
    return -1;
  }


  *index += s-s0; 

  return 0; 
}
