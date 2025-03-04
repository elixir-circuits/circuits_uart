// SPDX-FileCopyrightText: 2016 Frank Hunleth
//
// SPDX-License-Identifier: Apache-2.0
//
#include "uart_enum.h"

#include <stdlib.h>
#include <string.h>

struct serial_info *serial_info_alloc()
{
    struct serial_info *info = (struct serial_info *) malloc(sizeof(struct serial_info));
    memset(info, 0, sizeof(struct serial_info));
    return info;
}

void serial_info_free(struct serial_info *info)
{
    // Free any data
    if (info->name)
        free(info->name);
    if (info->description)
        free(info->description);
    if (info->serial_number)
        free(info->serial_number);
    if (info->manufacturer)
        free(info->manufacturer);

    // Reset the fields
    memset(info, 0, sizeof(struct serial_info));
}

void serial_info_free_list(struct serial_info *info)
{
    while (info) {
        struct serial_info *next = info->next;
        serial_info_free(info);
        free(info);
        info = next;
    }
}

