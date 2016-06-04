# Variables to override
#
# CC            C compiler
# CROSSCOMPILE	crosscompiler prefix, if any
# CFLAGS	compiler flags for compiling all C files
# ERL_CFLAGS	additional compiler flags for files using Erlang header files
# ERL_EI_LIBDIR path to libei.a
# LDFLAGS	linker flags for linking all binaries
# ERL_LDFLAGS	additional linker flags for projects referencing Erlang libraries
# MIX		path to mix

LDFLAGS +=
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
  LdFLAGS += -lrt
endif
CFLAGS ?= -O2 -Wall -Wextra -Wno-unused-parameter
CFLAGS += -std=c99 -D_GNU_SOURCE
CC ?= $(CROSSCOMPILER)gcc
MIX ?= mix

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

# To avoid linking issues, use copy/pasted version of ei.
# YES, this is unfortunate, but it was easier than
# battling mingw/visual c++ differences.
ERL_CFLAGS = -I"$(CURDIR)/src/ei_copy"
SRC += $(wildcard src/ei_copy/*.c)
CFLAGS += -DUNICODE

EXEEXT=.exe

else
# Non-Windows

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

all: priv/nerves_uart$(EXEEXT)

%.o: %.c
	$(CC) -c $(ERL_CFLAGS) $(CFLAGS) -o $@ $<

priv/nerves_uart$(EXEEXT): $(OBJ)
	@mkdir -p priv
	$(CC) $^ $(ERL_LDFLAGS) $(LDFLAGS) -o $@

clean:
	$(MIX) clean
	rm -f priv/nerves_uart$(EXEEXT) src/*.o

realclean:
	rm -fr _build priv/nerves_uart$(EXEEXT) src/*.o
