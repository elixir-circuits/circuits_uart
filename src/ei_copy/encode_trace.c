// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"
#include "putget.h"

int ei_encode_trace(char *buf, int *index, const erlang_trace *p)
{
  /* { Flags, Label, Serial, FromPid, Prev } */
  ei_encode_tuple_header(buf,index,5);
  ei_encode_long(buf,index,p->flags);
  ei_encode_long(buf,index,p->label);
  ei_encode_long(buf,index,p->serial);
  ei_encode_pid(buf,index,&p->from);
  ei_encode_long(buf,index,p->prev);

  /* index is updated by the functions we called */
  
  return 0;
}

