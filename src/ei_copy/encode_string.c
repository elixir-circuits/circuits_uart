// SPDX-FileCopyrightText: Ericsson AB 1998-2011. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include <string.h>
#include <limits.h>
#include "eidef.h"
#include "eiext.h"
#include "putget.h"


int ei_encode_string(char *buf, int *index, const char *p)
{
    size_t len = strlen(p);

    if (len >= INT_MAX) return -1;
    return ei_encode_string_len(buf, index, p, len);
}

int ei_encode_string_len(char *buf, int *index, const char *p, int len)
{
    char *s = buf + *index;
    char *s0 = s;
    int i;

    if (len == 0) {

      if (!buf) {
	s += 1;
      } else {
	put8(s,ERL_NIL_EXT);
      }

    } else if (len <= 0xffff) {

      if (!buf) {
	s += 3;
      } else {
	put8(s,ERL_STRING_EXT);
	put16be(s,len);
	memmove(s,p,len);	/* unterminated string */
      }
      s += len;

    } else {

      if (!buf) {
	s += 5 + (2*len) + 1;
      } else {
	/* strings longer than 65535 are encoded as lists */
	put8(s,ERL_LIST_EXT);
	put32be(s,len);

	for (i=0; i<len; i++) {
	  put8(s,ERL_SMALL_INTEGER_EXT);
	  put8(s,p[i]);
	}
	put8(s,ERL_NIL_EXT);
      }

    }

    *index += s-s0; 

    return 0; 
}

