# Variables to override
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# ERL_CFLAGS	additional compiler flags for files using Erlang header files
# ERL_EI_LIBDIR path to libei.a
# LDFLAGS	linker flags for linking all binaries
# ERL_LDFLAGS	additional linker flags for projects referencing Erlang libraries

LDFLAGS +=
CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter
CFLAGS += -std=c99 -D_GNU_SOURCE
CC ?= $(CROSSCOMPILER)gcc

###################
# If you're having trouble with the serial port, commenting in the following line
# may give some more hints. By default, log messages are appended to nerves_uart.log.
# See src/nerves_uart.c to change this. Be sure to rebuild everything by invoking
# "mix clean" and then "mix compile", so that the flag takes effect.
#CFLAGS += -DDEBUG

SRC=$(wildcard src/*.c)

# Windows-specific updates
ifeq ($(OS),Windows_NT)

# Libraries needed to enumerate serial ports
LDFLAGS += -lSetupapi -lCfgmgr32

# On Windows, make defaults CC=cc and
# cc doesn't exist with mingw
ifeq ($(CC),cc)
CC = gcc
endif

# Statically link on Windows to simplify distribution of pre-built version
LDFLAGS += -static

# To avoid linking issues, use copy/pasted version of ei.
# YES, this is unfortunate, but it was easier than
# battling mingw/visual c++ differences.
ERL_CFLAGS = -I"$(CURDIR)/src/ei_copy"
SRC += $(wildcard src/ei_copy/*.c)
CFLAGS += -DUNICODE

EXEEXT=.exe

else
# Non-Windows

# -lrt is needed for clock_gettime() on linux with glibc before version 2.17
# (for example raspbian wheezy)
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
  LDFLAGS += -lrt
endif

# Look for the EI library and header files
# For crosscompiled builds, ERL_EI_INCLUDE_DIR and ERL_EI_LIBDIR must be
# passed into the Makefile.
ifeq ($(ERL_EI_INCLUDE_DIR),)
ERL_ROOT_DIR = $(shell erl -eval "io:format(\"~s~n\", [code:root_dir()])" -s init stop -noshell)
ifeq ($(ERL_ROOT_DIR),)
   $(error Could not find the Erlang installation. Check to see that 'erl' is in your PATH)
endif
ERL_EI_INCLUDE_DIR = "$(ERL_ROOT_DIR)/usr/include"
ERL_EI_LIBDIR = "$(ERL_ROOT_DIR)/usr/lib"
endif

# Set Erlang-specific compile and linker flags
ERL_CFLAGS ?= -I$(ERL_EI_INCLUDE_DIR)
ERL_LDFLAGS ?= -L$(ERL_EI_LIBDIR) -lei

# If compiling on OSX and not crosscompiling, include CoreFoundation and IOKit
ifeq ($(CROSSCOMPILE),)
ifeq ($(shell uname),Darwin)
LDFLAGS += -framework CoreFoundation -framework IOKit
endif
endif

endif

OBJ=$(SRC:.c=.o)

.PHONY: all clean

all: priv priv/nerves_uart$(EXEEXT)

%.o: %.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) -o $@ $<

priv:
	mkdir -p priv

priv/nerves_uart$(EXEEXT): $(OBJ)
	$(CC) $^ $(ERL_LDFLAGS) $(LDFLAGS) -o $@

clean:
	rm -f priv/nerves_uart$(EXEEXT) src/*.o src/ei_copy/*.o
