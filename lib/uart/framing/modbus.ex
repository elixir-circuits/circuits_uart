defmodule Nerves.UART.Framing.Modbus do
  @behaviour Nerves.UART.Framing

  @moduledoc """
    Modbus docs here!
  """

  defmodule State do
    @moduledoc false
    defstruct [
      max_length: nil,
      expected_length: nil,
      line_index: 0,
      processed: <<>>,
      in_process: <<>>,
      slave_id: nil,
      lines: []
    ]
  end

  def init(args) do
    max_length = Keyword.get(args, :max_length, 255) # modbus standard max length
    slave_id = Keyword.get(args, :slave_id, 1) # modbus slave ID

    state = %State{max_length: max_length, slave_id: slave_id}
    {:ok, state}
  end

  # do nothing, we assume this is already in the right form
  # I could put the CRC & packet size compilation here, but seems like a lot
  # and an implementation detail that ought be handled upstream with my other
  # Modbus function
  def add_framing(data, state) do
    {:ok, data, state}
  end

  def remove_framing(data, state) do
    new_state = process_data(data, state.expected_length, state.in_process, state)
    rc = if buffer_empty?(new_state), do: :ok, else: :in_frame
    {rc, new_state.lines, new_state}
  end

  def frame_timeout(state) do
    partial_line = {:partial, state.processed <> state.in_process}
    new_state = %{state | processed: <<>>, in_process: <<>>}
    {:ok, [partial_line], new_state}
  end

  def flush(direction, state) when direction == :receive or direction == :both do
    new_state = %{state | processed: <<>>, in_process: <<>>, lines: [], expected_length: nil}
    new_state
  end
  def flush(_direction, state) do
    state
  end

  def buffer_empty?(state) do
    state.processed == <<>> and state.in_process == <<>>
  end

  # if we don't know our expected length, but we have enough data in this packet to find it
  defp process_data(data, nil, in_process, state) when byte_size(data) >= 3 do
    <<_slave_id, _cmd, length, _other::binary>> = data
    new_state = %{state | expected_length: length}
    process_data(data, length, in_process, new_state)
  end

  # deal with data that's too long 
  defp process_data(data, expected_length, in_process, state) when (byte_size(in_process <> data) > (expected_length+5)) do
    combined_data = in_process <> data
    relevant_data = Kernel.binary_part(combined_data, 0, expected_length+5) # +5 for the 5 control bytes
    new_lines = state.lines ++ [relevant_data]
    %{state | in_process: <<>>, processed: <<>>, line_index: 0, lines: new_lines}
  end

  defp process_data(data, length, in_process, state) when byte_size(data) >= 3 do
    data_length = byte_size(in_process <> data) - 5 # remove the 5 control bytes to get how many bytes of payload we have
    {lines, state_in_process, line_idx} = case (length == data_length) do
      true -> {state.lines++[in_process<>data], <<>>, 0} # we got the whole thing in 1 pass, so we're done
      _ -> {[], in_process<>data, byte_size(data)-1} # need to keep reading
    end

    new_state = %{state | expected_length: length, lines: lines, in_process: state_in_process, line_index: line_idx, processed: <<>>}
    new_state
  end

  # @TODO we can put pattern-matchers in the length=nil process_data methods to check that byte 1 is our slave ID?

  # we don't know our expected length, and it's probably not in this packet
  # happens if we only get the first 1 or 2 bytes of Modbus return (length is in byte 3)
  defp process_data(data, nil, in_process, state) do
    new_state = %{state | in_process: in_process <> data, line_index: byte_size(data)-1}
    new_state
  end

  defp process_data(data, expected_length, in_process, state) when (byte_size(in_process <> data) == (expected_length+5)) do
    new_lines = state.lines ++ [in_process <> data]
    %{state | in_process: <<>>, processed: <<>>, line_index: 0, lines: new_lines}
  end

  defp process_data(data, _expected_length, in_process, state) do
    new_state = %{state | in_process: in_process <> data, line_index: byte_size(data)}
    new_state
  end

end
