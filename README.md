# Nerves.UART
[![Build Status](https://travis-ci.org/nerves-project/nerves_uart.svg?branch=master)](https://travis-ci.org/nerves-project/nerves_uart)
[![Build Status](https://ci.appveyor.com/api/projects/status/hm6s6269jtbiqxbv/branch/master?svg=true)](https://ci.appveyor.com/project/fhunleth/nerves-uart/branch/master)
[![Hex version](https://img.shields.io/hexpm/v/nerves_uart.svg "Hex version")](https://hex.pm/packages/nerves_uart)
[![Ebert](https://ebertapp.io/github/nerves-project/nerves_uart.svg)](https://ebertapp.io/github/nerves-project/nerves_uart)

Nerves.UART allows you to access UARTs, serial ports, Bluetooth virtual serial
port connections and more in Elixir. Feature highlights:

  * Mac, Windows, and desktop and embedded Linux
  * Enumerate serial ports
  * Receive input via messages or by polling (active and passive modes)
  * Add and remove framing on serial data - line-based framing included for use
    with GPS, cellular, satellite and other modules
  * Unit tests (uses the [tty0tty](https://github.com/freemed/tty0tty) virtual null modem on Travis)

Something doesn't work for you? Check out below and the
[docs](https://hexdocs.pm/nerves_uart/). Chat with other users on the nerves
channel on the [elixir-lang slack](https://elixir-slackin.herokuapp.com/), or
file an issue or PR.

## Example use

Discover what serial ports are attached:

```elixir
iex> Nerves.UART.enumerate
%{"COM14" => %{description: "USB Serial Port", manufacturer: "FTDI", product_id: 24577,
    vendor_id: 1027},
  "COM5" => %{description: "Prolific USB-to-Serial Comm Port",
    manufacturer: "Prolific", product_id: 8963, vendor_id: 1659},
  "COM16" => %{description: "Arduino Uno",
    manufacturer: "Arduino LLC (www.arduino.cc)", product_id: 67, vendor_id: 9025}}
```

Start the UART GenServer:

```elixir
iex> {:ok, pid} = Nerves.UART.start_link
{:ok, #PID<0.132.0>}
```

The GenServer doesn't open a port automatically, so open up a serial port or UART
now. See the results from your call to `Nerves.UART.enumerate/0` for what's
available on your system.

```elixir
iex> Nerves.UART.open(pid, "COM14", speed: 115200, active: false)
:ok
```

This opens the serial port up at 115200 baud and turns off active mode. This means that
you'll have to manually call `Nerves.UART.read` to receive input. In active mode, input
from the serial port will be sent as messages. See the docs for all options.

Write something to the serial port:

```elixir
iex> Nerves.UART.write(pid, "Hello there\r\n")
:ok
```

See if anyone responds in the next 60 seconds:

```elixir
iex> Nerves.UART.read(pid, 60000)
{:ok, "Hi"}
```

Input is reported as soon as it is received, so you may need multiple calls to `read/2`
to get everything you want. If you have flow control enabled and stop calling
`read/2`, the port will push back to the sender when its buffers fill up.

Enough with passive mode, let's switch to active mode:

```elixir
iex> Nerves.UART.configure(pid, active: true)
:ok

iex> flush
{:nerves_uart, "COM14", "a"}
{:nerves_uart, "COM14", "b"}
{:nerves_uart, "COM14", "c"}
{:nerves_uart, "COM14", "\r"}
{:nerves_uart, "COM14", "\n"}
:ok
```

It turns out that `COM14` is a USB to serial port. Let's unplug it and see what
happens:

```elixir
iex> flush
{:nerves_uart, "COM14", {:error, :eio}}
```

Oops. Well, when it appears again, it can be reopened. In passive mode, errors
get reported on the calls to `Nerves.UART.read/2` and `Nerves.UART.write/3`

Back to receiving data, it's a little annoying that characters arrive one by one.
That's because our computer is really fast compared to the serial port, but if
something slows it down, we could receive two or more characters at a time. Rather than
reassemble the characters into lines, we can ask `nerves_uart` to do it for us:

```elixir
iex> Nerves.UART.configure(pid, framing: {Nerves.UART.Framing.Line, separator: "\r\n"})
:ok
```

This tells `nerves_uart` to append a `\r\n` to each call to `write/2` and to report
each line separately in active and passive mode. You can set this configuration
in the call to `open/3` as well. Here's what we get now:

```elixir
iex> flush
{:nerves_uart, "COM14", "abc"}   # Note that the "\r\n" is trimmed
:ok
```

If your serial data is framed differently, check out the `Nerves.UART.Framing` behaviour
and implement your own.

You can also set a timeout so that a partial line doesn't hang around in the receive
buffer forever:

```elixir
iex> Nerves.UART.configure(pid, rx_framing_timeout: 500)
:ok

# Assume that the sender sent the letter "A" without sending anything else
# for 500 ms.

iex> flush
{:nerves_uart, "COM14", {:partial, "A"}}
```


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `nerves_uart` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:nerves_uart, "~> 0.1"}]
  end
  ```

  2. List `:nerves_uart` as an application dependency:

  ```elixir
  def application do
    [applications: [:nerves_uart]]
  end
  ```

  3. Check that the C compiler dependencies are satisified (see below)

  4. Run `mix deps.get` and `mix compile`

### C compiler dependencies

Since this library includes C code, `make`, `gcc`, and Erlang header and development
libraries are required.

On Linux systems, this usually requires you to install
the `build-essential` and `erlang-dev` packages. For example:

```sh
sudo apt-get install build-essential erlang-dev
```

On Macs, run `gcc --version` or `make --version`. If they're not installed, you will
be given instructions.

On Windows, if you're obtaining `nerves_uart` from `hex.pm`, you'll need
MinGW to compile the C code. I use [Chocolatey](https://chocolatey.org/)
and install MinGW by running the following in an administrative command prompt:

```sh
choco install mingw
```

On Nerves, you're set - just add `nerves_uart` to your `mix.exs`. Nerves
contains everything needed by default. If you do use Nerves, though, keep in
mind that the C code is crosscompiled for your target hardware and will
not work on your host (the port will crash when you call `start_link` or
`enumerate`. If you want to try out `nerves_uart` on your host
machine, the easiest way is to either clone the source or add `nerves_uart` as a
dependency to a regular (non-Nerves) Elixir project.

## Building and running the unit tests

The standard Elixir build process applies. Clone `nerves_uart` or
download a source release and run:

```sh
mix deps.get
mix compile
```

The unit tests require two serial ports connected via a NULL modem
cable to run. Define the names of the serial ports in the environment
before running the tests. For example,

```sh
export NERVES_UART_PORT1=ttyS0
export NERVES_UART_PORT2=ttyS1
```

If you're on Windows or Linux, you don't need real serial ports. For linux,
download and install [tty0tty](https://github.com/freemed/tty0tty). Load the
kernel module and specify `tnt0` and `tnt1` for the serial ports. On Windows,
download and install [com0com](https://sourceforge.net/projects/com0com/)
(Look for version 2.2.2.0 if the latest hasn't been signed). The ports on
Windows are `CNCA0` and `CNCB0`.

Then run:

```sh
mix test
```

If you're using `tty0tty`, the tests will run at full speed. Real serial ports
seem to take a fraction of a second to close and re-open. I added a gratuitous
delay to each test to work around this. It likely can be much shorter.

## FAQ

### A feature is missing

Yes, I haven't gotten to a couple really important ones for some use cases.
See `TODO.md` for now. Please ping me if you'd like to help.

### Do I have to use Nerves?

No, this project doesn't have any dependencies on any Nerves components. The
desire for some serial port library features on Nerves drove us to create it,
but we also have host-based use cases. To be useful for us, the library must
remain crossplatform and have few dependencies. We're just developing it under
the Nerves umbrella.

### How can I use the serial port on Linux without sudo?

Serial port files are almost always owned by the `dialout` group. Add yourself
to the `dialout` group by running `sudo adduser yourusername dialout`. Then log
out and back in again, and you should be able to access the serial port.

### Debugging tips

If you're having trouble and suspect the C code, edit the `Makefile` to enable
debug logging. See the `Makefile` for instructions on how to do this. Debug
logging is appended to a file by default, but can be sent to `stderr` or another
location by editing `src/nerves_uart.c`.

If you're on Linux, the `tty0tty` emulated null modem removes the flakiness of
real serial port drivers if that's the problem. The serial port monitor
[jpnevulator](https://jpnevulator.snarl.nl/) is useful for monitoring the
hardware signals and dumping data as hex byte values.

On OSX and Windows, I've found that PL2303-based serial ports can be flakey.
First, make sure that you don't have a counterfeit PL2303. On Windows, they show
up in device manager with a warning symbol. On OSX, they seem to hang when
closing the port. Non-counterfeit PL2303-based serial ports can pass the unit
tests on Windows 10, but I have not been able to get them to pass on OSX.
FTDI-based serial ports appear to work better on both operating systesm.

### ei_copy why????

You may have noticed Erlang's `erl_interface` code copy/pasted into `src/ei_copy`.
This is *only* used on Windows to work around issues linking to the distributed
version of `erl_interface`. That was was compiled with Visual Studio. This project uses MinGW, and
even though the C ABIs are the same between the compilers, Visual Studio adds stack
protection calls that I couldn't figure out how to work around.

## Acknowledgments

When building this library, [node-serialport](https://github.com/voodootikigod/node-serialport)
and [QtSerialPort](http://doc.qt.io/qt-5/qserialport.html) where incredibly helpful in
helping to define APIs and point out subtleties with platform-specific serial port code. Sadly,
I couldn't reuse their code, but I feel indebted to the authors and maintainers of these
libraries, since they undoubtedly saved me hours of time debugging corner cases.
I have tried to acknowledge them in the comments where I have used strategies that I learned
from them.
