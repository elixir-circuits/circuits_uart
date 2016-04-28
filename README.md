# Nerves.UART

Nerves.UART allows you to access UARTs, serial ports, Bluetooth virtual serial
port connections and more in Elixir. Feature highlights:

  * Linux, Mac, and Windows
  * Enumerate serial ports
  * Receive input via messages or by polling (active and passive modes)
  * Unit tests (this is only listed because unit tests seem to be sparse for libraries like this)

** This library is new. Expect API changes and bugs, but we'll get there!! If you try it out, please consider helping out by contributed document improvements, fixes, or more unit tests. **

## Example use

Discover what serial ports are attached:

    iex> Nerves.UART.enumerate
    %{"COM14" => %{description: "USB Serial Port", manufacturer: "FTDI", product_id: 24577,
        vendor_id: 1027},
      "COM5" => %{description: "Prolific USB-to-Serial Comm Port",
        manufacturer: "Prolific", product_id: 8963, vendor_id: 1659},
      "COM16" => %{description: "Arduino Uno",
        manufacturer: "Arduino LLC (www.arduino.cc)", product_id: 67, vendor_id: 9025}}

Start up a UART GenServer:

    iex> {:ok, pid} = Nerves.UART.start_link
    {:ok, #PID<0.132.0>}

Open up the serial port or UART that you want from the list above:

    iex> Nerves.UART.open(pid, "COM14", speed: 115200, active: false)
    :ok

This opens the serial port up at 115200 baud and turns off active mode. This means that
you'll have to manually call `Nerves.UART.read` to receive input. In active mode, input
from the serial port will be sent as messages. See the docs for all options.

Write something to the serial port:

    iex> Nerves.UART.write(pid, "Hello there\r\n")
    :ok

See if anyone responds in the next 60 seconds:

    iex> Nerves.UART.read(pid, 60000)
    {:ok, "Hi"}

Input is reported as soon as it is received, so you may need multiple calls to `read/2`
to get everything you want.

Enough with passive mode, let's switch to active mode:

    iex> Nerves.UART.configure(pid, active: true)
    :ok

    iex> flush
    {:nerves_uart, "COM14", "a"}
    {:nerves_uart, "COM14", "b"}
    {:nerves_uart, "COM14", "c"}
    :ok

It turns out that `COM14` is a USB to serial port. Let's unplug it and see what
happens:

    iex> flush
    {:nerves_uart, "COM14", {:error, :eio}}

Oops. Well, when it appears again, it can be reopened. In passive mode, errors
get reported on the calls to `Nerves.UART.read/2` and `Nerves.UART.write/3`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add nerves_uart to your list of dependencies in `mix.exs`:

        def deps do
          [{:nerves_uart, "~> 0.0.1"}]
        end

  2. Ensure nerves_uart is started before your application:

        def application do
          [applications: [:nerves_uart]]
        end

## System dependencies

Since this library includes C code, `make`, `gcc`, and Erlang header and development
libraries are required.

On Linux systems, this usually requires you to install
the `build-essential` and `erlang-dev` packages. For example:

    sudo apt-get install build-essential erlang-dev

On Macs, you will need `gmake`. If you're using Homebrew, run

    brew install gmake

On Windows, you will need MinGW. Assuming that you installed Erlang and
Elixir via [Chocolatey](https://chocolatey.org/), install MinGW by
running the following in an administrative command prompt:

    choco install mingw

## Building and running the unit tests

The standard Elixir build process applies. Clone `nerves_uart` or
download a source release and run:

    mix deps.get
    mix deps.compile
    mix compile

The unit tests require two serial ports connected via a NULL modem
cable to run. Define the names of the serial ports in the environment
before running the tests. For example,

    export NERVES_UART_PORT1=ttyS0
    export NERVES_UART_PORT2=ttyS0

If you're on Linux, you don't need real serial ports. Download and install
[tty0tty](https://github.com/freemed/tty0tty). Load the kernel module and
specify `tnt0` and `tnt1` for the serial ports.

Then run:

    mix test

## FAQ: ei_copy why????

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
