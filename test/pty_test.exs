# SPDX-FileCopyrightText: 2026 Tallak Tveide
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule PtyTest do
  use ExUnit.Case
  alias Circuits.UART

  @skip_reason (cond do
                  :os.type() != {:unix, :linux} -> "These tests require Linux pseudo-terminals"
                  System.find_executable("socat") == nil -> "socat is not installed"
                  true -> false
                end)
  @moduletag skip: @skip_reason

  setup do
    port =
      Port.open({:spawn_executable, System.find_executable("socat")}, [
        :binary,
        :stderr_to_stdout,
        args: ["-d", "-d", "pty,raw,echo=0", "pty,raw,echo=0"]
      ])

    {:os_pid, os_pid} = Port.info(port, :os_pid)
    on_exit(fn -> System.cmd("kill", [to_string(os_pid)]) end)

    uart = start_supervised!(UART)
    %{pty: pty_name(port, ""), uart: uart}
  end

  defp pty_name(port, output) do
    case Regex.run(~r/PTY is (\S+)/, output, capture: :all_but_first) do
      [name] ->
        name

      nil ->
        receive do
          {^port, {:data, data}} -> pty_name(port, output <> data)
        after
          2000 -> flunk("socat did not open a pty: #{output}")
        end
    end
  end

  test "supported settings work on repeated opens and reconfiguration", %{pty: pty, uart: uart} do
    for _ <- 1..3 do
      assert :ok = UART.open(uart, pty, speed: 19200, data_bits: 8, parity: :none)
      assert :ok = UART.configure(uart, stop_bits: 2)
      assert :ok = UART.configure(uart, stop_bits: 1)
      assert :ok = UART.close(uart)
    end
  end

  for options <- [
        [parity: :even],
        [parity: :odd],
        [parity: :mark],
        [parity: :space],
        [data_bits: 5],
        [data_bits: 6],
        [data_bits: 7]
      ] do
    test "unsupported settings #{inspect(options)} fail on every open", %{pty: pty, uart: uart} do
      for _ <- 1..2 do
        assert {:error, :einval} =
                 UART.open(uart, pty, [speed: 19200] ++ unquote(options))
      end

      assert :ok = UART.open(uart, pty, data_bits: 8, parity: :none)
    end

    test "unsupported settings #{inspect(options)} fail on reconfiguration", %{
      pty: pty,
      uart: uart
    } do
      assert :ok = UART.open(uart, pty)
      assert {:error, :einval} = UART.configure(uart, unquote(options))
      assert :ok = UART.configure(uart, data_bits: 8, parity: :none)
    end
  end
end
