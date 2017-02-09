defmodule Nerves.UART.Framing do
  @moduledoc """
  A behaviour for implementing framers for data received over a UART.
  """

  @doc """
  Initialize the state of the framer based on options passed to
  `Nerves.UART.open/3`.

  This function should return the initial state for the framer or
  an error.
  """
  @callback init(args :: term) ::
    {:ok, state} |
    {:error, reason} when state: term, reason: term

  @doc """
  Add framing to the passed in data.

  The returned `frame_data` will be sent out the UART.
  """
  @callback add_framing(data :: term, state :: term) ::
    {:ok, framed_data, new_state} |
    {:error, reason, new_state} when new_state: term, framed_data: binary, reason: term

  @doc """
  Remove the framing off received data. If a partial frame is left over at the
  end, then `:in_frame` should be returned. All of the frames received should
  be returned in the second tuple.
  """
  @callback remove_framing(new_data :: binary, state :: term) ::
    {:in_frame, [term], new_state} |
    {:ok, [term], new_state} when new_state: term

  @doc """
  If `remove_framing/2` returned `:in_frame` and a user-specified timeout for
  reassembling frames has elapsed, then this function is called. Depending on
  the semantics of the framing, a partial frame may be returned or the
  incomplete frame may be dropped.
  """
  @callback frame_timeout(state :: term) ::
    {:ok, [term], new_state} when new_state: term

  @doc """
  This is called when the user invokes `Nerves.UART.flush/2`. Any partially
  received frames should be dropped.
  """
  @callback flush(direction :: :receive | :transmit | :both, state :: term) ::
    new_state when new_state: term

end
