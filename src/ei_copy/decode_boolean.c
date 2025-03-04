// SPDX-FileCopyrightText: Ericsson AB 1998-2013. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include <string.h>
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

/* c non-zero -> erlang "true" atom, otherwise "false" */
int ei_decode_boolean(const char *buf, int *index, int *p)
{
  char tbuf[6];
  int t;

  if (ei_decode_atom_as(buf, index, tbuf, sizeof(tbuf), ERLANG_ASCII, NULL, NULL) < 0)
      return -1;

  if (memcmp(tbuf, "true", 5) == 0)
      t = 1;
  else if (memcmp(tbuf, "false", 6) == 0)
      t = 0;
  else
      return -1;
      
  if (p) *p = t;
  return 0; 
}

