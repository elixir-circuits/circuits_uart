// SPDX-FileCopyrightText: Ericsson AB 1998-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

#ifndef _EIEXT_H
#define _EIEXT_H

/* FIXME maybe put into eidef.h */

#define ERL_VERSION_MAGIC 131   /* 130 in erlang 4.2 */

/* from erl_eterm.h */
#define ERL_MAX ((1 << 27)-1)
#define ERL_MIN -(1 << 27)

/* FIXME we removed lots of defines, maybe some C files don't need to include
   this header any longer? */

#endif /* _EIEXT_H */
