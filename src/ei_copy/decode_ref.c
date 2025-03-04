// SPDX-FileCopyrightText: Ericsson AB 1998-2013. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#include <string.h>
#include "eidef.h"
#include "eiext.h"
#include "putget.h"


int ei_decode_ref(const char *buf, int *index, erlang_ref *p)
{
  const char *s = buf + *index;
  const char *s0 = s;
  int count, i;
  
  switch (get8(s)) {
    case ERL_REFERENCE_EXT:
      if (p) {
	  if (get_atom(&s, p->node, NULL) < 0) return -1;
	  p->n[0] = get32be(s);
	  p->len = 1;
	  p->creation = get8(s) & 0x03;
      }
      else {
	  if (get_atom(&s, NULL, NULL) < 0) return -1;
	  s += 5;
      }
  
      *index += s-s0;
  
      return 0;
      break;
      
    case ERL_NEW_REFERENCE_EXT:
      /* first the integer count */
      count = get16be(s);

      if (p) {
	  p->len = count;
	  if (get_atom(&s, p->node, NULL) < 0) return -1;
	  p->creation = get8(s) & 0x03;
      }
      else {
	  if (get_atom(&s, NULL, NULL) < 0) return -1;
	  s += 1;
      }

      /* finally the id integers */
      if (p) {
	for (i = 0; (i<count) && (i<3); i++) {
	  p->n[i] = get32be(s);
	}
      }
      else s += 4 * count;
  
      *index += s-s0;
  
      return 0;
      break;
      
    default:
      return -1;
  }
}

