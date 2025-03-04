// SPDX-FileCopyrightText: Ericsson AB 2001-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

#include "eidef.h"

#include <stddef.h>
#include <stdlib.h>
#include "ei_malloc.h"

void* ei_malloc (long size)
{
  return malloc(size);
}

void* ei_realloc(void* orig, long size)
{
  return realloc(orig, size);
}

void ei_free (void *ptr)
{
  free(ptr);
}
