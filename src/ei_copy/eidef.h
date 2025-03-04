// SPDX-FileCopyrightText: Ericsson AB 2002-2009. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

#ifndef _EIDEF_H
#define _EIDEF_H

/* Common definitions used in ei user interface */

#include <stddef.h>		/* We want to get definition of NULL */

#include "ei.h"			/* Want the API function declarations */

#define EISMALLBUF 2048

#ifdef USE_ISINF_ISNAN		/* simulate finite() */
#  define isfinite(f) (!isinf(f) && !isnan(f))
#  define HAVE_ISFINITE
#elif defined(__GNUC__) && defined(HAVE_FINITE)
/* We use finite in gcc as it emits assembler instead of
   the function call that isfinite emits. The assembler is
   significantly faster. */
#  ifdef isfinite
#     undef isfinite
#  endif
#  define isfinite finite
#  ifndef HAVE_ISFINITE
#    define HAVE_ISFINITE
#  endif
#elif defined(isfinite) && !defined(HAVE_ISFINITE)
#  define HAVE_ISFINITE
#elif !defined(HAVE_ISFINITE) && defined(HAVE_FINITE)
#  define isfinite finite
#  define HAVE_ISFINITE
#endif

#endif /* _EIDEF_H */
