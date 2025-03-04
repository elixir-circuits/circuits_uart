// SPDX-FileCopyrightText: Ericsson AB 1998-2013. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"
#include "putget.h"

int ei_decode_trace(const char *buf, int *index, erlang_trace *p)
{
  int arity = 0;
  int tindex = *index; /* use a temporary index if any function should fail */
  long *p_flags, *p_label, *p_serial, *p_prev;
  erlang_pid *p_from;

  if (p != NULL) {
      p_flags = &p->flags;
      p_label = &p->label;
      p_serial = &p->serial;
      p_prev = &p->prev;
      p_from = &p->from;
  }
  else {
      p_flags = p_label = p_serial = p_prev = NULL;
      p_from = NULL;
  }

  /* { Flags, Label, Serial, FromPid, Prev } */
  if (ei_decode_tuple_header(buf, &tindex, &arity)
      || (arity != 5)
      || ei_decode_long(buf, &tindex, p_flags)
      || ei_decode_long(buf, &tindex, p_label)
      || ei_decode_long(buf, &tindex, p_serial)
      || ei_decode_pid( buf, &tindex, p_from)
      || ei_decode_long(buf, &tindex, p_prev)) return -1;

  /* index is updated by the functions we called */
  
  *index = tindex;

  return 0;
}
