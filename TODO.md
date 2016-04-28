Todo list

  1. Add support for setting break, cts, rts, etc.
  2. Add tests for different baudrate and parity configs
  3. Add tests for setting baudrate and flow control dynamically
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

