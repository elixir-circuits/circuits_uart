// SPDX-FileCopyrightText: Ericsson AB 2002-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"

#if defined(HAVE_GMP_H) && defined(HAVE_LIBGMP)

#include <gmp.h>

#include "eidef.h"
#include "eiext.h"
#include "putget.h"


int ei_decode_bignum(const char *buf, int *index, mpz_t obj)
{
    const char *s = buf + *index;
    const char *s0 = s;
    int arity;
    int sign;
    unsigned long n;

    switch (get8(s)) {
    case ERL_SMALL_INTEGER_EXT:
	n = get8(s);
	mpz_set_ui(obj, n);
	break;
    
    case ERL_INTEGER_EXT:
	n = get32be(s);
	mpz_set_ui(obj, n);
	break;
    
    case ERL_SMALL_BIG_EXT:
	arity = get8(s);
	goto decode_bytes;

    case ERL_LARGE_BIG_EXT:
	arity = get32be(s);
    decode_bytes:
	sign = get8(s);
	mpz_import(obj, arity, -1, 1, 0, 0, s);
	s += arity;
	if (sign) {
	    mpz_neg(obj, obj);
	}
    
	break;
    
    default:
	return -1;
    }

    *index += s-s0;
  
    return 0; 
}

#endif /* HAVE_GMP_H && HAVE_LIBGMP */
