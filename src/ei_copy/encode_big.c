// SPDX-FileCopyrightText: Ericsson AB 2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

#include <string.h>
#include "eidef.h"
#include "eiext.h"
#include "putget.h"
#include "ei_x_encode.h"

int ei_encode_big(char *buf, int *index, erlang_big* big) {
    unsigned char *s = (unsigned char *)buf + *index;
    unsigned char *s0 = s;
    unsigned int digit_bytes = big->arity;
    unsigned int n = (digit_bytes+1)/2;

    if (digit_bytes < 256) {
	if (buf) {
	    put8(s, ERL_SMALL_BIG_EXT);
	    put8(s, digit_bytes);
	} else {
	    s += 2;
	}
    } else {
	if (buf) {
	    put8(s, ERL_LARGE_BIG_EXT);
	    put32be(s, digit_bytes);
	} else {
	    s += 5;
	}
    }
      
    if (buf) {
	int i;
	unsigned char hi, lo;
	unsigned short *dt = big->digits;
	put8(s, big->is_neg);

	for (i = 0; i < n; ++i) {
	    
	    hi = (unsigned char) (dt[i] >> 8);
	    lo = (unsigned char) (dt[i]);

	    s[i*2] = lo;
	    if ((i*2 + 1) < digit_bytes) {
		s[i*2 + 1] = hi;
	    }
	}
 
    } else {
	s ++; /* skip sign bit */
    }

    s += digit_bytes;

    *index += s-s0;

    return 0;
}

int ei_x_encode_big(ei_x_buff* x, erlang_big* big) {
     int i = x->index;

     ei_encode_big(NULL, &i, big);
     if (!x_fix_buff(x, i))
        return -1;
     return ei_encode_big(x->buff, &x->index, big);
}

