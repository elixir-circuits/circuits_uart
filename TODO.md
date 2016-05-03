Todo list

  1. Add support for setting break, cts, rts, etc.
  1. Add protocol parser support so that receive events can be chopped up by
     line or by some other marker. This needs a slight amount of thought, since
     we also need to slice by timeouts (e.g., read in 32 byte chunks unless a
     partial one hangs around for too long). If we support returning things
     other than binaries, then it seems reasonable to expect the send side
     to translate. Also need to handle flush and drain.
  2. Add tests for different baudrate and parity configs
  3. Add tests for setting baudrate and flow control dynamically
  4. Add a read_exact call to block until exactly n bytes are read
     or there's a timeout.
  5. Fix the error code on Windows when you unplug the USB cable to
     be :eio. The error code that comes from ReadFile, etc. seems
     useless.
  5. It seems like a use case would be to have one Erlang process writing continuously
     and another one reading continuously on the same uart. Currently each one can block the other. It seems desirable to have separate read and write queues and allow
     one read and one write to be pending simultaneously in the C code.
  6. Clean up error reporting code. Pass back errno values and convert in platform independent code?
  7. Active mode could support flow control if we add pause and resume calls. This could be emulated by
     turning the active mode off for pause and back on for resume. This feels really manual, but
     node-serialport does it this way.
  8. The options get passed through to C code untouched. Consider return {:error, :einval} rather than
     crashing the process, since without debug on, it's hard to figure out what happened.
  9. See if undefining UNICODE on Windows is safe. Maybe a lot of sketchy UTF-16 to UTF-8 code
     can be removed? ** Basic tests suggest that this will work**
  10. What should be done if `open` is called multiple times. Currently, it re-opens, but
      it could fail, or it could check if the port is the same and just do a configure.
      Be sure to add
  11. Should start_link let you open a port automatically? This is nice on Nerves where
      you're guaranteed that the port exists usually, but not so much on the Desktop where
      ports are fickle.

