// SPDX-FileCopyrightText: 2016 Frank Hunleth
//
// SPDX-License-Identifier: Apache-2.0
//
#ifndef ERLCMD_H
#define ERLCMD_H

#include <ei.h>

#ifdef __WIN32__
#include <windows.h>
#endif

/*
 * Erlang request/response processing
 */
#define ERLCMD_BUF_SIZE 32768 + 30 // Large size is to support large UART writes
struct erlcmd
{
    char buffer[ERLCMD_BUF_SIZE];
    size_t index;

    void (*request_handler)(const char *emsg, void *cookie);
    void *cookie;

#ifdef __WIN32__
    HANDLE h;
    OVERLAPPED overlapped;

    HANDLE stdin_reader_thread;
    HANDLE stdin_read_pipe;
    HANDLE stdin_write_pipe;
    BOOL running;
#endif
};

void erlcmd_init(struct erlcmd *handler,
		 void (*request_handler)(const char *req, void *cookie),
		 void *cookie);
void erlcmd_send(char *response, size_t len);
int erlcmd_process(struct erlcmd *handler);

#ifdef __WIN32__
HANDLE erlcmd_wfmo_event(struct erlcmd *handler);
#endif

#endif
