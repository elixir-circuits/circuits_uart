defmodule UARTTest do
  use ExUnit.Case
  alias Nerves.UART

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
  def port1() do
    System.get_env("NERVES_UART_PORT1")
  end
  def port2() do
    System.get_env("NERVES_UART_PORT2")
  end

  def common_setup() do
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
end
