// SPDX-FileCopyrightText: Ericsson AB 1998-2013. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include <string.h>
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

int ei_decode_port(const char *buf, int *index, erlang_port *p)
{
  const char *s = buf + *index;
  const char *s0 = s;
  
  if (get8(s) != ERL_PORT_EXT) return -1;

  if (p) {
    if (get_atom(&s, p->node, NULL) < 0) return -1;
    p->id = get32be(s) & 0x0fffffff /* 28 bits */;
    p->creation = get8(s) & 0x03;
  }
  else {
      if (get_atom(&s, NULL, NULL) < 0) return -1;
      s += 5;
  }
  
  *index += s-s0;
  
  return 0;
}
