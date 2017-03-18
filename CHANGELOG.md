# Changelog

## v0.1.2

Prebuilt port binaries are no longer distributed in hex.pm for Windows users.
You'll need to install MinGW. Feedback was that it didn't work as well as I
thought it would.

  * Bug fixes
    * Fix custom baudrates not working on OSX. Thanks to salzig for identifying
      the problem and helping to debug it.
    * Pass flush request through to framer as well as the serial port
    * Minor code cleanup

## v0.1.1

  * New features
    * Enable experimental feature on Windows to use prebuilt
      port binary. Feedback appreciated.

## v0.1.0

  * New features
    * Add support for adding and removing framing on data
      transferred over the serial port.
    * Add line framing implementation to support receiving
      notifications only for complete lines (lines ending
      in '\n' or '\r\n') or lines that are longer than a set
      length.

  * Bugs fixed
    * Enable RTS when not using it. Keeping it cleared
      was stopping transmission on devices that supported
      flow control when the user wasn't using it.
    * Fix quirks on Windows when using com0com. This should
      improve support with at least one other serial driver
      based on user error reports.

  * Known limitations
    * Framing receive timeouts only work in active mode.
      (I.e., you're waiting for a complete line to be received,
      but if it takes too long, then you want to receive a
      notification of a partial line.) Passive mode support is coming.

## v0.0.7

  * Bugs fixed
    * Force elixir_make v0.3.0 so that it works OTP 19

## v0.0.6

  * New features
    * Use elixir_make

## v0.0.5

  * Bugs fixed
    * Fixed enumeration of ttyACM devices on Linux

## v0.0.4

  * New features
    * Added hardware signal support (rts, cts, dtr, dsr, etc.)
    * Added support for sending breaks
    * Added support for specifying which queue to flush
      (:receive, :transmit, or :both)

  * Bugs fixed
    * Fixed crash in active mode when sending and receiving
      at the same time

## v0.0.3

  * Bugs fixed
    * Crosscompiling on OSX works now

## v0.0.2

  * Bugs fixed
    * Fix hex.pm release by not publishing .o files

## v0.0.1

  * Initial release
