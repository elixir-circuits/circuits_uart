defmodule Nerves.UART.Enumerator do
  @moduledoc false

  def enumerate() do
    executable = :code.priv_dir(:nerves_uart) ++ '/nerves_uart'
    port = Port.open({:spawn_executable, executable},
      [{:args, ["enumerate"]},
        {:packet, 2},
        :use_stdio,
        :binary])
    result =
      receive do
        {^port, {:data, <<?r, message::binary>>}} ->
          :erlang.binary_to_term(message)
      after
          5_000 ->
            Port.close(port)
            %{}
      end
    result
  end

end
