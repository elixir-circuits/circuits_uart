// SPDX-FileCopyrightText: Ericsson AB 2002-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
#ifndef _EI_MALLOC_H
#define _EI_MALLOC_H

void* ei_malloc (long size);
void* ei_realloc(void* orig, long size);
void ei_free (void *ptr);

#endif /* _EI_MALLOC_H */
