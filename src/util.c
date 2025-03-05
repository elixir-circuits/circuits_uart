// SPDX-FileCopyrightText: 2016 Frank Hunleth
//
// SPDX-License-Identifier: Apache-2.0
//
#include "util.h"
#ifdef __APPLE__
#include <mach/clock.h>
#include <mach/mach.h>
#else
#include <time.h>
#endif

#ifdef DEBUG
FILE *log_location;
#endif

/**
 * @return a monotonic timestamp in milliseconds
 */
uint64_t current_time()
{
#ifdef __APPLE__
    clock_serv_t cclock;
    mach_timespec_t mts;

    host_get_clock_service(mach_host_self(), SYSTEM_CLOCK, &cclock);
    clock_get_time(cclock, &mts);
    mach_port_deallocate(mach_task_self(), cclock);

    return ((uint64_t) mts.tv_sec) * 1000 + mts.tv_nsec / 1000000;
#else
    // Linux and Windows support clock_gettime()
    struct timespec tp;
    int rc = clock_gettime(CLOCK_MONOTONIC, &tp);
    if (rc < 0)
        errx(EXIT_FAILURE, "clock_gettime failed?");

    return ((uint64_t) tp.tv_sec) * 1000 + tp.tv_nsec / 1000000;
#endif
}

