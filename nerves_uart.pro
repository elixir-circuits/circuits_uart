#-------------------------------------------------
#
# Project created by QtCreator 2016-04-18T09:27:30
#
#-------------------------------------------------

QT       -= core

QT       -= gui

TARGET = nerves_uart
CONFIG   += console
CONFIG   -= app_bundle

TEMPLATE = app


SOURCES += \
    src/erlcmd.c \
    src/nerves_uart.c \
    src/uart_enum_linux.c \
    src/uart_enum_win.c \
    src/uart_enum.c \
    src/util.c \
    src/uart_comm_win.c \
    src/uart_comm.c \
    src/uart_enum_osx.c \
    src/uart_comm_unix.c \
    src/debug_tests.c

HEADERS += \
    src/erlcmd.h \
    src/uart_enum.h \
    src/util.h \
    src/uart_comm.h

DISTFILES += \
    lib/nerves_uart.ex \
    TODO.md \
    mix.exs \
    Makefile \
    README.md \
    test/nerves_uart_test.exs

win32 {
    SOURCES += \
        src/ei_copy/decode_atom.c \
        src/ei_copy/decode_big.c \
        src/ei_copy/decode_bignum.c \
        src/ei_copy/decode_binary.c \
        src/ei_copy/decode_boolean.c \
        src/ei_copy/decode_char.c \
        src/ei_copy/decode_double.c \
        src/ei_copy/decode_fun.c \
        src/ei_copy/decode_intlist.c \
        src/ei_copy/decode_list_header.c \
        src/ei_copy/decode_long.c \
        src/ei_copy/decode_longlong.c \
        src/ei_copy/decode_pid.c \
        src/ei_copy/decode_port.c \
        src/ei_copy/decode_ref.c \
        src/ei_copy/decode_skip.c \
        src/ei_copy/decode_string.c \
        src/ei_copy/decode_trace.c \
        src/ei_copy/decode_tuple_header.c \
        src/ei_copy/decode_ulong.c \
        src/ei_copy/decode_ulonglong.c \
        src/ei_copy/decode_version.c \
        src/ei_copy/ei_decode_term.c \
        src/ei_copy/ei_malloc.c \
        src/ei_copy/ei_printterm.c \
        src/ei_copy/ei_x_encode.c \
        src/ei_copy/encode_atom.c \
        src/ei_copy/encode_big.c \
        src/ei_copy/encode_bignum.c \
        src/ei_copy/encode_binary.c \
        src/ei_copy/encode_boolean.c \
        src/ei_copy/encode_char.c \
        src/ei_copy/encode_double.c \
        src/ei_copy/encode_fun.c \
        src/ei_copy/encode_list_header.c \
        src/ei_copy/encode_long.c \
        src/ei_copy/encode_longlong.c \
        src/ei_copy/encode_pid.c \
        src/ei_copy/encode_port.c \
        src/ei_copy/encode_ref.c \
        src/ei_copy/encode_string.c \
        src/ei_copy/encode_trace.c \
        src/ei_copy/encode_tuple_header.c \
        src/ei_copy/encode_ulong.c \
        src/ei_copy/encode_ulonglong.c \
        src/ei_copy/encode_version.c \
        src/ei_copy/get_type.c

    HEADERS += \
        src/ei_copy/ei.h \
        src/ei_copy/decode_skip.h \
        src/ei_copy/ei_decode_term.h \
        src/ei_copy/ei_malloc.h \
        src/ei_copy/ei_printterm.h \
        src/ei_copy/ei_x_encode.h \
        src/ei_copy/eicode.h \
        src/ei_copy/eidef.h \
        src/ei_copy/eiext.h \
        src/ei_copy/putget.h

    INCLUDEPATH += src/ei_copy src/ei_copy/misc
    LIBS += -lSetupapi -lCfgmgr32
}
unix {
    QMAKE_CFLAGS += -D_GNU_SOURCE
    INCLUDEPATH += /usr/lib/erlang/usr/include
    LIBS += -L/usr/lib/erlang/usr/lib -lei
}
osx {
    INCLUDEPATH += /usr/local/Cellar/erlang/18.3/lib/erlang/usr/include
    LIBS += -framework CoreFoundation
}

QMAKE_CFLAGS += -std=c99
