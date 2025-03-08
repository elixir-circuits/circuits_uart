# SPDX-FileCopyrightText: 2016 Frank Hunleth
# SPDX-FileCopyrightText: 2018 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Circuits.UART.Enumerator do
  @moduledoc false

  def enumerate() do
    executable = :code.priv_dir(:circuits_uart) ++ ~c"/circuits_uart"

    port =
      Port.open({:spawn_executable, executable}, [
        {:args, ["enumerate"]},
        {:packet, 2},
        :use_stdio,
        :binary
      ])

    result =
      receive do
        {^port, {:data, <<?r, message::binary>>}} ->
          :erlang.binary_to_term(message)
      after
        5000 ->
          Port.close(port)
          %{}
      end

    result
  end
end
