// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

/* remove version identifier from the start of the buffer */
int ei_decode_version(const char *buf, int *index, int *version)
{
  const char *s = buf + *index;
  const char *s0 = s;
  int v;
  
  v = get8(s);
  if (version) *version = v;
  if (v != ERL_VERSION_MAGIC)
    return -1;
  
  *index += s-s0;
  
  return 0;
}
