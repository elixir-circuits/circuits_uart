defmodule UARTlessTest do
  use ExUnit.Case
  alias Nerves.UART

  # These tests all run with or without a serial port

  test "enumerate returns a map" do
    ports = UART.enumerate
    assert is_map(ports)
  end

  test "start_link without arguments works" do
    {:ok, pid} = UART.start_link
    assert is_pid(pid)
  end

  test "open bogus serial port" do
    {:ok, pid} = UART.start_link
    assert {:error, :enoent} = UART.open(pid, "bogustty")
  end

  test "using a port without opening it" do
    {:ok, pid} = UART.start_link
    assert {:error, :ebadf} = UART.write(pid, "hello")
    assert {:error, :ebadf} = UART.read(pid)
    assert {:error, :ebadf} = UART.flush(pid)
    assert {:error, :ebadf} = UART.drain(pid)
  end
end
