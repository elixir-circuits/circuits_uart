// SPDX-FileCopyrightText: 2016 Frank Hunleth
//
// SPDX-License-Identifier: Apache-2.0
//
#ifndef UART_ENUM_H
#define UART_ENUM_H

struct serial_info {
    char *name;
    char *description;
    char *manufacturer;
    char *serial_number;
    int vid;
    int pid;

    struct serial_info *next;
};

// Common code
struct serial_info *serial_info_alloc();
void serial_info_free(struct serial_info *info);
void serial_info_free_list(struct serial_info *info);

// Prototypes for device-specific code
struct serial_info *find_serialports();

#endif // UART_ENUM_H
