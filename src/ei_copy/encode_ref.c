// SPDX-FileCopyrightText: Ericsson AB 1998-2013. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include <string.h>
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

int ei_encode_ref(char *buf, int *index, const erlang_ref *p)
{
  char *s = buf + *index;
  int i;

  (*index) += 1 + 2; /* skip to node atom */
  if (ei_encode_atom_len_as(buf, index, p->node, strlen(p->node), ERLANG_UTF8,
			    ERLANG_LATIN1|ERLANG_UTF8) < 0) {
      return -1;
  }

  /* Always encode as an extended reference; all participating parties
     are now expected to be able to decode extended references. */
  if (buf) {
	  put8(s,ERL_NEW_REFERENCE_EXT);

	  /* first, number of integers */
	  put16be(s, p->len);

	  /* then the nodename */
	  s = buf + *index;

	  /* now the integers */
	  put8(s,(p->creation & 0x03));
	  for (i = 0; i < p->len; i++)
	      put32be(s,p->n[i]);
  }
  
  *index += p->len*4 + 1;  
  return 0;
}

