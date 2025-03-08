# SPDX-FileCopyrightText: 2016 Frank Hunleth
# SPDX-FileCopyrightText: 2018 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Circuits.UART.Framing.None do
  @behaviour Circuits.UART.Framing

  @moduledoc """
  Don't apply or removing any framing.
  """

  def init(_args), do: {:ok, nil}

  def add_framing(data, _state), do: {:ok, data, nil}

  def remove_framing(data, _state), do: {:ok, [data], nil}

  def frame_timeout(_state), do: {:ok, [], nil}

  def flush(_direction, _state), do: nil
end
