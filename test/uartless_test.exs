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
end
