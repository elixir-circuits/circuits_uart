// SPDX-FileCopyrightText: Ericsson AB 1998-2013. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include <string.h>
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

int ei_encode_pid(char *buf, int *index, const erlang_pid *p)
{
  char *s = buf + *index;

  ++(*index); /* skip ERL_PID_EXT */
  if (ei_encode_atom_len_as(buf, index, p->node, strlen(p->node),
			    ERLANG_UTF8, ERLANG_LATIN1|ERLANG_UTF8) < 0)
      return -1;

  if (buf) {
    put8(s,ERL_PID_EXT);

    s = buf + *index;

    /* now the integers */
    put32be(s,p->num & 0x7fff); /* 15 bits */
    put32be(s,p->serial & 0x1fff); /* 13 bits */
    put8(s,(p->creation & 0x03)); /* 2 bits */
  }

  *index += 4 + 4 + 1;  
  return 0;
}

