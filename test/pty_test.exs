# SPDX-FileCopyrightText: 2026 Tallak Tveide
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule PtyTest do
  use ExUnit.Case
  alias Circuits.UART

  @moduledoc """
  A pseudo-terminal can't do parity or characters of other than 8 bits. These tests
  make one with socat, so they are skipped where it isn't installed.
  """

  @moduletag skip: if(System.find_executable("socat") == nil, do: "socat is not installed")

  setup do
    socat = System.find_executable("socat")

    port =
      Port.open({:spawn_executable, socat}, [
        :binary,
        :stderr_to_stdout,
        args: ["-d", "-d", "pty,raw,echo=0", "pty,raw,echo=0"]
      ])

    {:os_pid, os_pid} = Port.info(port, :os_pid)
    on_exit(fn -> System.cmd("kill", [to_string(os_pid)]) end)

    {:ok, uart} = UART.start_link()
    %{pty: pty_name(port, ""), uart: uart}
  end

  # socat prints "N PTY is /dev/pts/12" for each end.
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

  test "a pty opens again and again with 8 data bits and no parity", %{pty: pty, uart: uart} do
    for _ <- 1..3 do
      assert :ok = UART.open(uart, pty, speed: 19200, data_bits: 8, parity: :none)
      assert :ok = UART.close(uart)
    end
  end

  test "a pty refuses parity and 7 data bits every time, the first as well", %{
    pty: pty,
    uart: uart
  } do
    for options <- [[parity: :even], [parity: :odd], [parity: :mark], [data_bits: 7]],
        _ <- 1..2 do
      assert {:error, :einval} = UART.open(uart, pty, [speed: 19200] ++ options)
    end

    assert :ok = UART.open(uart, pty, speed: 19200, parity: :none)
  end
end
