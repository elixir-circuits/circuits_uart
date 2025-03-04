// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include "eidef.h"
#include "eiext.h"
#include "putget.h"

/* add the version identifier to the start of the buffer */
int ei_encode_version(char *buf, int *index)
{
  char *s = buf + *index;
  char *s0 = s;

  if (!buf) s ++;
  else put8(s,(unsigned char)ERL_VERSION_MAGIC);
  *index += s-s0;
  
  return 0;
}

