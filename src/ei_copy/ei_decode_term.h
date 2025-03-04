// SPDX-FileCopyrightText: Ericsson AB 2001-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

#ifndef _EI_DECODE_TERM_H
#define _EI_DECODE_TERM_H

/* Returns 1 if term is decoded, 0 if term is OK, but not decoded here
   and -1 if something is wrong.
   ONLY changes index if term is decoded (return value 1)! */

int ei_decode_ei_term(const char* buf, int* index, ei_term* term);

#endif /* _EI_DECODE_TERM_H */
