// SPDX-FileCopyrightText: 2016 Frank Hunleth
// SPDX-FileCopyrightText: 2018 Jon Carstens
// SPDX-FileCopyrightText: 2023 Jon Ringle
//
// SPDX-License-Identifier: Apache-2.0
//
#ifndef UTIL_H
#define UTIL_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

//#define DEBUG
#ifdef DEBUG
extern FILE *log_location;
#define LOG_LOCATION log_location
#define debug(...) do { fprintf(LOG_LOCATION, "%llu: ", current_time()); fprintf(LOG_LOCATION, __VA_ARGS__); fprintf(LOG_LOCATION, "\r\n"); fflush(LOG_LOCATION); } while(0)
#else
#define LOG_LOCATION stderr
#define debug(...)
#endif

#ifndef __WIN32__
#include <err.h>
#else
// If err.h doesn't exist, define substitutes.
#define err(STATUS, MSG, ...) do { fprintf(LOG_LOCATION, "circuits_uart: " MSG "\n", ## __VA_ARGS__); fflush(LOG_LOCATION); exit(STATUS); } while (0)
#define errx(STATUS, MSG, ...) do { fprintf(LOG_LOCATION, "circuits_uart: " MSG "\n", ## __VA_ARGS__); fflush(LOG_LOCATION); exit(STATUS); } while (0)
#define warn(MSG, ...) do { fprintf(LOG_LOCATION, "circuits_uart: " MSG "\n", ## __VA_ARGS__); fflush(LOG_LOCATION); } while (0)
#define warnx(MSG, ...) do { fprintf(LOG_LOCATION, "circuits_uart: " MSG "\n", ## __VA_ARGS__); fflush(LOG_LOCATION); } while (0)
#endif

#define ONE_YEAR_MILLIS (1000ULL * 60 * 60 * 24 * 365)
uint64_t current_time();

#endif // UTIL_H
