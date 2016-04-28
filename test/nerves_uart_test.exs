defmodule NervesUARTTest do
  use ExUnit.Case
  alias Nerves.UART

  @xoff  <<19>>
  @xon   <<17>>

  # Define the following environment variables for your environment:
  #
  #   NERVES_UART_PORT1 - e.g., COM1 or ttyS0
  #   NERVES_UART_PORT2
  #
  # The unit tests expect those ports to exist, be different ports,
  # and be connected to each other through a null modem cable.
  #
  # On Linux, it's possible to use tty0tty. See
  # https://github.com/freemed/tty0tty.
  defp port1() do
    System.get_env("NERVES_UART_PORT1")
  end
  defp port2() do
    System.get_env("NERVES_UART_PORT2")
  end

  setup do
    assert !is_nil(port1) && !is_nil(port2),
      "Please define NERVES_UART_PORT1 and NERVES_UART_PORT2 in your
environment (e.g. to ttyS0 or COM1) and connect them via a null
modem cable."

    if !String.starts_with?(port1, "tnt") do
        # Let things settle between tests for real serial ports
        :timer.sleep(500)
    end

    {:ok, uart1} = UART.start_link
    {:ok, uart2} = UART.start_link
    {:ok, uart1: uart1, uart2: uart2}
  end

  test "serial ports exist" do
    ports = UART.enumerate
    assert is_map(ports)
    assert Map.has_key?(ports, port1), "Can't find #{port1}"
    assert Map.has_key?(ports, port2), "Can't find #{port2}"
  end

  test "simple open and close", %{uart1: uart1} do
    assert :ok = UART.open(uart1, port1, speed: 9600)
    assert :ok = UART.close(uart1)

    assert :ok = UART.open(uart1, port2)
    assert :ok = UART.close(uart1)

    UART.close(uart1)
  end

  test "open bogus serial port", %{uart1: uart1} do
    assert {:error, :enoent} = UART.open(uart1, "bogustty")
  end

  test "open same port twice", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, port1)
    assert {:error, _} = UART.open(uart2, port1)

    UART.close(uart1)
  end

  test "using a port without opening it", %{uart1: uart1} do
    assert {:error, :ebadf} = UART.write(uart1, "hello")
    assert {:error, :ebadf} = UART.read(uart1)
    assert {:error, :ebadf} = UART.flush(uart1)
    assert {:error, :ebadf} = UART.drain(uart1)

    UART.close(uart1)
  end

  test "write and read", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, port1, active: false)
    assert :ok = UART.open(uart2, port2, active: false)

    # uart1 -> uart2
    assert :ok = UART.write(uart1, "A")
    assert {:ok, "A"} = UART.read(uart2)

    # uart2 -> uart1
    assert :ok = UART.write(uart2, "B")
    assert {:ok, "B"} = UART.read(uart1)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "write iodata", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, port1, active: false)
    assert :ok = UART.open(uart2, port2, active: false)

    assert :ok = UART.write(uart1, 'B')
    assert {:ok, "B"} = UART.read(uart2)

    assert :ok = UART.write(uart1, ['AB', ?C, 'D', "EFG"])

    # Wait for everything to be received in one call
    :timer.sleep(100)
    assert {:ok, "ABCDEFG"} = UART.read(uart2)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "no cr and lf translations", %{uart1: uart1, uart2: uart2} do
    # It is very common for CR and NL characters to
    # be translated through ttys and serial ports, so
    # check this explicitly.
    assert :ok = UART.open(uart1, port1, active: false)
    assert :ok = UART.open(uart2, port2, active: false)

    assert :ok = UART.write(uart1, "\n")
    assert {:ok, "\n"} = UART.read(uart2)

    assert :ok = UART.write(uart1, "\r")
    assert {:ok, "\r"} = UART.read(uart2)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "all characters pass unharmed", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, port1, active: false)
    assert :ok = UART.open(uart2, port2, active: false)

    # The default is 8-N-1, so this should all work
    for char <- 0..255 do
        assert :ok = UART.write(uart1, <<char>>)
        assert {:ok, <<^char>>} = UART.read(uart2)
    end

    UART.close(uart1)
    UART.close(uart2)
  end

  test "send and flush", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, port1, active: false)
    assert :ok = UART.open(uart2, port2, active: false)

    assert :ok = UART.write(uart1, "hello")

    assert :ok = UART.flush(uart2)
    assert {:ok, ""} = UART.read(uart2, 0)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "send more than can be done synchronously", %{uart1: uart1, uart2: uart2} do
    # Note: When using the tty0tty driver, both endpoints need to be
    #       opened or writes will fail with :einval. This is different
    #       than most regular uarts where writes to nothing just twiddle
    #       output bits.
    assert :ok = UART.open(uart1, port1)
    assert :ok = UART.open(uart2, port2)

    # Try a big size to trigger a write that can't complete
    # immediately. This doesn't always work.
    lots_o_data = :binary.copy("a", 5000)

    # Allow 10 seconds for write to give it time to complete
    assert :ok = UART.write(uart1, lots_o_data, 10000)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "send timeout", %{uart1: uart1} do
    # Don't run against tty0tty since it sends data almost
    # instantaneously. Also, Windows appears to have a deep
    # send buffer. Need to investigate the Windows failure more.
    if !String.starts_with?(port1, "tnt") && !:os.type == {:windows, :nt} do
      assert :ok = UART.open(uart1, port1, speed: 1200)

      # Send more than can be sent on a 1200 baud link
      # in 10 milliseconds
      lots_o_data = :binary.copy("a", 5000)
      assert {:error, :eagain} = UART.write(uart1, lots_o_data, 10)

      UART.close(uart1)
    end
  end

  test "sends coalesce into one read", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, port1, active: false)
    assert :ok = UART.open(uart2, port2, active: false)

    assert :ok = UART.write(uart1, "a")
    assert :ok = UART.write(uart1, "b")
    assert :ok = UART.write(uart1, "c")

    :timer.sleep(100)

    assert {:ok, "abc"} = UART.read(uart2)

    UART.close(uart1)
    UART.close(uart2)
  end

  test "active mode receive", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, port1, active: false)
    assert :ok = UART.open(uart2, port2, active: true)

    # First write
    assert :ok = UART.write(uart1, "a")
    assert_receive {:nerves_uart, port2, "a"}

    # Only one message should be sent
    refute_receive {:nerves_uart, _}

    # Try another write
    assert :ok = UART.write(uart1, "b")
    assert_receive {:nerves_uart, port2, "b"}

    UART.close(uart1)
    UART.close(uart2)
  end

  test "error when calling read in active mode", %{uart1: uart1} do
    assert :ok = UART.open(uart1, port1, active: true)
    assert {:error, :einval} = UART.read(uart1)
    UART.close(uart1)
  end

  test "active mode on then off", %{uart1: uart1, uart2: uart2} do
    assert :ok = UART.open(uart1, port1, active: false)
    assert :ok = UART.open(uart2, port2, active: false)

    assert :ok = UART.write(uart1, "a")
    assert {:ok, "a"} = UART.read(uart2, 100)

    assert :ok = UART.configure(uart2, active: true)
    assert :ok = UART.write(uart1, "b")
    assert_receive {:nerves_uart, port2, "b"}

    assert :ok = UART.configure(uart2, active: false)
    assert :ok = UART.write(uart1, "c")
    assert {:ok, "c"} = UART.read(uart2, 100)
    refute_receive {:nerves_uart, _}

    assert :ok = UART.configure(uart2, active: true)
    assert :ok = UART.write(uart1, "d")
    assert_receive {:nerves_uart, port2, "d"}

    refute_receive {:nerves_uart, _}

    UART.close(uart1)
    UART.close(uart2)
  end

  test "active mode gets event when write fails", %{uart1: uart1} do
    # This only works with tty0tty since it fails write operations if no
    # receiver.

    if String.starts_with?(port1, "tnt") do
      assert :ok = UART.open(uart1, port1, active: true)

      assert {:error, :einval} = UART.write(uart1, "a")
      assert_receive {:nerves_uart, port1, {:error, :einval}}

      UART.close(uart1)
    end
  end

  test "read timeout works", %{uart1: uart1} do
    assert :ok = UART.open(uart1, port1, active: false)

    # 0 duration timeout
    start = System.monotonic_time(:milli_seconds)
    assert {:ok, <<>>} = UART.read(uart1, 0)
    elapsed_time = System.monotonic_time(:milli_seconds) - start
    assert_in_delta elapsed_time, 0, 100

    # 500 ms timeout
    start = System.monotonic_time(:milli_seconds)
    assert {:ok, <<>>} = UART.read(uart1, 500)
    elapsed_time = System.monotonic_time(:milli_seconds) - start
    assert_in_delta elapsed_time, 400, 600

    UART.close(uart1)
  end

# Software flow control doesn't work and I'm not sure what the deal is
if false do
  test "xoff filtered with software flow control", %{uart1: uart1, uart2: uart2} do
    if !String.starts_with?(port1, "tnt") do
      assert :ok = UART.open(uart1, port1, flow_control: :softare, active: false)
      assert :ok = UART.open(uart2, port2, active: false)

      # Test that uart1 filters xoff
      assert :ok = UART.write(uart2, @xoff)
      assert {:ok, ""} = UART.read(uart1, 100)

      # Test that uart1 filters xon
      assert :ok = UART.write(uart2, @xon)
      assert {:ok, ""} = UART.read(uart1, 100)

      # Test that uart1 doesn't filter other things
      assert :ok = UART.write(uart2, "Z")
      assert {:ok, "Z"} = UART.read(uart1, 100)

      UART.close(uart1)
      UART.close(uart2)
    end
  end

  test "software flow control pausing", %{uart1: uart1, uart2: uart2} do
    if !String.starts_with?(port1, "tnt") do
      assert :ok = UART.open(uart1, port1, flow_control: :softare, active: false)
      assert :ok = UART.open(uart2, port2, active: false)

      # send XOFF to uart1 so that it doesn't transmit
      assert :ok = UART.write(uart2, @xoff)
      assert :ok = UART.write(uart1, "a")
      assert {:ok, ""} = UART.read(uart2, 100)

      # send XON to see if we get the "a"
      assert :ok = UART.write(uart2, @xon)
      assert {:ok, "a"} = UART.read(uart2, 100)

      UART.close(uart1)
      UART.close(uart2)
    end
  end
end

  test "changing config on open port" do
    # Implement me.
  end
end
