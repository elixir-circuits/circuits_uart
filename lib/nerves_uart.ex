defmodule Nerves.UART do
  use GenServer

  # Many calls take timeouts for how long to wait for reading and writing
  # serial ports. This is the additional time added to the GenServer message passing
  # timeout so that the interprocess messaging timers don't hit before the
  # timeouts on the actual operations.
  @genserver_timeout_slack 100

  # There's a timeout when interacting with the port as well. If the port
  # doesn't respond by timeout + @port_timeout_slack, then there's something
  # wrong with it.
  @port_timeout_slack 50

  @moduledoc """
  Find and use UARTs, serial ports, and more.
  """

  defmodule State do
    @moduledoc false
    defstruct [
      port: nil,                   # C port process
      controlling_process: nil,    # where events get sent
      name: nil,                   # port name when opened
      framing: Nerves.UART.Framing.None, # framing behaviour
      framing_state: nil,          # framing behaviour's state
      rx_framing_timeout: 0,       # how long to wait for incomplete frames
      queued_messages: [],         # queued messages when in passive mode
      rx_framing_tref: nil,        # frame completion timer
      is_active: true              # active or passive mode
    ]
  end

  @type uart_option ::
    {:active, boolean} |
    {:speed, non_neg_integer} |
    {:data_bits, 5..8} |
    {:stop_bits, 1..2} |
    {:parity, :none | :even | :odd | :space | :mark} |
    {:flow_control, :none | :hardware | :software} |
    {:framing, module | {module, [term]}} |
    {:rx_framing_timeout, integer}

  # Public API
  @doc """
  Return a map of available ports with information about each one. The map
  looks like this:
  ```
     %{ "ttyS0" -> %{vendor_id: 1234, product_id: 1,
                     manufacturer: "Acme Corporation", serial_number: "000001"},
        "ttyUSB0" -> ${vendor_id: 1234, product_id: 2} }
  ```
  Depending on the port and the operating system, not all fields may be
  returned. Informational fields are:

    * `:vendor_id` - The 16-bit USB vendor ID of the device providing the port. Vendor ID to name lists are managed through usb.org
    * `:product_id` - The 16-bit vendor supplied product ID
    * `:manufacturer` - The manufacturer of the port
    * `:description` - A description or product name
    * `:serial_number` - The device's serial number if it has one
  """
  @spec enumerate() :: map
  def enumerate() do
    Nerves.UART.Enumerator.enumerate
  end

  @doc """
  Start up a UART GenServer.
  """
  @spec start_link([term]) :: {:ok, pid} | {:error, term}
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @doc """
  Stop the UART GenServer.
  """
  @spec stop(pid) :: :ok
  def stop(pid) do
    GenServer.stop(pid)
  end

  @doc """
  Open a serial port.

  The following options are available:

    * `:active` - (`true` or `false`) specifies whether data is received as
       messages or by calling `read/2`. See discussion below.

    * `:speed` - (number) set the initial baudrate (e.g., 115200)

    * `:data_bits` - (5, 6, 7, 8) set the number of data bits (usually 8)

    * `:stop_bits` - (1, 2) set the number of stop bits (usually 1)

    * `:parity` - (`:none`, `:even`, `:odd`, `:space`, or `:mark`) set the
      parity. Usually this is `:none`. Other values:
      * `:space` means that the parity bit is always 0
      * `:mark` means that the parity bit is always 1

    * `:flow_control` - (`:none`, `:hardware`, or `:software`) set the flow control
      strategy.

    * `:framing` - (`module` or `{module, args}`) set the framing for data.
      The `module` must implement the `Nerves.UART.Framing` behaviour. See
      `Nerves.UART.Framing.None` and `Nerves.UART.Framing.Line`. The default
      is `Nerves.UART.Framing.None`.

    * `:rx_framing_timeout` - (milliseconds) this specifies how long incomplete
      frames will wait for the remainder to be received. Timed out partial
      frames are reported as `{:partial, data}`. A timeout of <= 0 means to
      wait forever.

  Active mode defaults to true and means that data received on the
  UART is reported in messages. The messages have the following form:

     `{:nerves_uart, serial_port_name, data}`

  or

     `{:nerves_uart, serial_port_name, {:error, reason}}`

  When in active mode, flow control can not be used to push back on the
  sender and messages will accumulated in the mailbox should data arrive
  fast enough. If this is an issue, set `:active` to false and call
  `read/2` manually when ready for more data.

  On success, `open/3` returns `:ok`. On error, `{:error, reason}` is returned.
  The following are some reasons:

    * `:enoent`  - the specified port couldn't be found
    * `:eagain`  - the port is already open
    * `:eacces`  - permission was denied when opening the port
  """
  @spec open(pid, binary, [uart_option]) :: :ok | {:error, term}
  def open(pid, name, opts \\ []) do
    GenServer.call pid, {:open, name, opts}
  end

  @doc """
  Close the serial port. The GenServer continues to run so that a port can
  be opened again.
  """
  @spec close(pid) :: :ok | {:error, term}
  def close(pid) do
    GenServer.call pid, :close
  end

  @doc """
  Change the serial port configuration after `open/3` has been called. See
  `open/3` for the valid options.
  """
  @spec configure(pid, [uart_option]) :: :ok | {:error, term}
  def configure(pid, opts) do
    GenServer.call pid, {:configure, opts}
  end

  @doc """
  Send a continuous stream of zero bits for a duration in milliseconds.
  By default, the zero bits are transmitted at least 0.25 seconds.

  This is a convenience function for calling `set_break/2` to enable
  the break signal, wait, and then turn it off.
  """
  @spec send_break(pid, integer) :: :ok | {:error, term}
  def send_break(pid, duration \\ 250) do
    :ok = set_break(pid, true)
    :timer.sleep(duration)
    set_break(pid, false)
  end

  @doc """
  Start or stop sending a break signal.
  """
  @spec set_break(pid, boolean) :: :ok | {:error, term}
  def set_break(pid, value) when is_boolean(value) do
    GenServer.call pid, {:set_break, value}
  end

  @doc """
  Write data to the opened UART. It's possible for the write to return before all
  of the data is actually transmitted. To wait for the data, call drain/1.

  This call blocks until all of the data to be written is in the operating
  system's internal buffers. If you're sending a lot of data on a slow link,
  supply a longer timeout to avoid timing out prematurely.

  Returns `:ok` on success or `{:error, reason}` if an error occurs.

  Typical error reasons:

    * `:ebadf` - the UART is closed
  """
  @spec write(pid, binary | [byte], integer) :: :ok | {:error, term}
  def write(pid, data, timeout) when is_binary(data) do
    GenServer.call pid, {:write, data, timeout}, genserver_timeout(timeout)
  end
  def write(pid, data, timeout) when is_list(data) do
    write(pid, :erlang.iolist_to_binary(data), timeout)
  end

  @doc """
  Write data to the opened UART with the default timeout.
  """
  @spec write(pid, binary | [byte]) :: :ok | {:error, term}
  def write(pid, data) do
    write(pid, data, 5000)
  end

  @doc """
  Read data from the UART. This call returns data as soon as it's available or
  after timing out.

  Returns `{:ok, binary}`, where `binary` is a binary data object that contains the
  read data, or `{:error, reason}` if an error occurs.

  Typical error reasons:

    * `:ebadf` - the UART is closed
    * `:einval` - the UART is in active mode
  """
  @spec read(pid, integer) :: binary | {:error, term}
  def read(pid, timeout \\ 5000) do
    GenServer.call pid, {:read, timeout}, genserver_timeout(timeout)
  end

  @doc """
  Waits until all data has been transmitted. See [tcdrain(3)](http://linux.die.net/man/3/tcdrain) for low level
  details on Linux or OSX. This is not implemented on Windows.
  """
  @spec drain(pid) :: :ok | {:error, term}
  def drain(pid) do
    GenServer.call pid, :drain
  end

  @doc """
  Flushes the `:receive` buffer, the `:transmit` buffer, or `:both`.

  See [tcflush(3)](http://linux.die.net/man/3/tcflush) for low level details on
  Linux or OSX. This calls `PurgeComm` on Windows.
  """
  @spec flush(pid) :: :ok | {:error, term}
  def flush(pid, direction \\ :both) do
    GenServer.call pid, {:flush, direction}
  end

  @doc """
  Returns a map of signal names and their current state (true or false).
  Signals include:

    * `:dsr` - Data Set Ready
    * `:dtr` - Data Terminal Ready
    * `:rts` - Request To Send
    * `:st`  - Secondary Transmitted Data
    * `:sr`  - Secondary Received Data
    * `:cts` - Clear To Send
    * `:cd`  - Data Carrier Detect
    * `:rng` - Ring Indicator
  """
  @spec signals(pid) :: map | {:error, term}
  def signals(pid) do
    GenServer.call pid, :signals
  end

  @doc """
  Set or clear the Data Terminal Ready signal.
  """
  @spec set_dtr(pid, boolean) :: :ok | {:error, term}
  def set_dtr(pid, value) when is_boolean(value) do
    GenServer.call pid, {:set_dtr, value}
  end

  @doc """
  Set or clear the Request To Send signal.
  """
  @spec set_rts(pid, boolean) :: :ok | {:error, term}
  def set_rts(pid, value) when is_boolean(value) do
    GenServer.call pid, {:set_rts, value}
  end

  # gen_server callbacks
  def init([]) do
    executable = :code.priv_dir(:nerves_uart) ++ '/nerves_uart'
    port = Port.open({:spawn_executable, executable},
      [{:args, []},
        {:packet, 2},
        :use_stdio,
        :binary,
        :exit_status])
    state = %State{port: port}
    {:ok, state}
  end

  def handle_call({:open, name, opts}, {from_pid, _}, state) do
    new_framing = Keyword.get(opts, :framing, nil)
    new_rx_framing_timeout
      = Keyword.get(opts, :rx_framing_timeout, state.rx_framing_timeout)
    is_active = Keyword.get(opts, :active, true)

    response = call_port(state, :open, {name, opts})
    new_state = %{state | name: name,
              controlling_process: from_pid,
              rx_framing_timeout: new_rx_framing_timeout,
              is_active: is_active} |>
              change_framing(new_framing)

    {:reply, response, new_state}
  end
  def handle_call(:close, _from, state) do
    # Clean up the C side
    response = call_port(state, :close, nil)

    # Clean up the Elixir side
    new_state = %{state | name: nil, framing_state: nil, queued_messages: []}
      |> handle_framing_timer(:ok)

    {:reply, response, new_state}
  end
  def handle_call({:read, _timeout}, _from, %{queued_messages: [message | rest]} = state) do
    # Return the queued response.
    new_state = %{state | queued_messages: rest}
    {:reply, {:ok, message}, new_state}
  end
  def handle_call({:read, timeout}, from, state) do
    # Poll the serial port
    case call_port(state, :read, timeout, port_timeout(timeout)) do
      {:ok, <<>>} ->
        # Timeout
        {:reply, {:ok, <<>>}, state}
      {:ok, buffer} ->
        # More data
        {rc, messages, new_framing_state} =
          apply(state.framing, :remove_framing, [buffer, state.framing_state])
        new_state = %{state | framing_state: new_framing_state} |>
          handle_framing_timer(rc)
        if messages == [] do
          # If nothing, poll some more
          handle_call({:read, timeout}, from, new_state)
        else
          # Return the first message
          [first_message | rest] = messages
          new_state = %{new_state | queued_messages: rest}
          {:reply, {:ok, first_message}, new_state}
        end
      response ->
        # Error
        {:reply, response, state}
    end
  end
  def handle_call({:write, value, timeout}, _from, state) do
    {:ok, framed_data, new_framing_state} =
      apply(state.framing, :add_framing, [value, state.framing_state])

    response = call_port(state, :write, {framed_data, timeout}, port_timeout(timeout))
    new_state = %{state | framing_state: new_framing_state}
    {:reply, response, new_state}
  end
  def handle_call({:configure, opts}, _from, state) do
    new_framing = Keyword.get(opts, :framing, nil)
    new_rx_framing_timeout
      = Keyword.get(opts, :rx_framing_timeout, state.rx_framing_timeout)
    is_active = Keyword.get(opts, :active, state.is_active)
    state = %{state | rx_framing_timeout: new_rx_framing_timeout, is_active: is_active}
     |> change_framing(new_framing)

    response = call_port(state, :configure, opts)
    {:reply, response, state}
  end
  def handle_call(:drain, _from, state) do
    response = call_port(state, :drain, nil)
    {:reply, response, state}
  end
  def handle_call({:flush, direction}, _from, state) do
    fstate = apply(state.framing, :flush, [direction, state.framing_state])
    new_state = %{state | framing_state: fstate}
    response = call_port(new_state, :flush, direction)
    {:reply, response, new_state}
  end
  def handle_call(:signals, _from, state) do
    response = call_port(state, :signals, nil)
    {:reply, response, state}
  end
  def handle_call({:set_dtr, value}, _from, state) do
    response = call_port(state, :set_dtr, value)
    {:reply, response, state}
  end
  def handle_call({:set_rts, value}, _from, state) do
    response = call_port(state, :set_rts, value)
    {:reply, response, state}
  end
  def handle_call({:set_break, value}, _from, state) do
    response = call_port(state, :set_break, value)
    {:reply, response, state}
  end

  def terminate(reason, state) do
    IO.puts "Going to terminate: #{inspect reason}"
    Port.close(state.port)
  end

  def handle_info({_, {:data, <<?n, message::binary>>}}, state) do
    msg = :erlang.binary_to_term(message)
    handle_port(msg, state)
  end
  def handle_info(:rx_framing_timed_out, state) do
    {:ok, messages, new_framing_state} =
      apply(state.framing, :frame_timeout, [state.framing_state])

    new_state = %{state | rx_framing_tref: nil, framing_state: new_framing_state}
      |> notify_timedout_messages(messages)

    {:noreply, new_state}
  end

  defp notify_timedout_messages(%{is_active: true, controlling_process: dest} = state, messages)
    when dest != nil do
    Enum.each(messages, &(report_message(state, &1)))
    state
  end
  defp notify_timedout_messages(%{is_active: false} = state, messages) do
    IO.puts "Queuing... #{inspect messages}"
    new_queued_messages = state.queued_messages ++ messages
    %{state | queued_messages: new_queued_messages}
  end
  defp notify_timedout_messages(state, _messages), do: state

  defp change_framing(state, nil), do: state
  defp change_framing(state, framing_mod) when is_atom(framing_mod) do
    change_framing(state, {framing_mod, []})
  end
  defp change_framing(state, {framing_mod, framing_args}) do
    {:ok, framing_state} = apply(framing_mod, :init, [framing_args])
    %{state | framing: framing_mod, framing_state: framing_state}
  end

  defp call_port(state, command, arguments, timeout \\ 4000) do
    msg = {command, arguments}
    send state.port, {self(), {:command, :erlang.term_to_binary(msg)}}
    # Block until the response comes back since the C side
    # doesn't want to handle any queuing of requests. REVISIT
    receive do
      {_, {:data, <<?r,response::binary>>}} ->
        :erlang.binary_to_term(response)
    after
      timeout ->
        # Not sure how this can be recovered
        exit(:port_timed_out)
    end
  end

  defp handle_port({:notif, data}, state) when is_binary(data) do
    #IO.puts "Received data on port #{state.name}"
    {rc, messages, new_framing_state} =
      apply(state.framing, :remove_framing, [data, state.framing_state])
    new_state = %{state | framing_state: new_framing_state} |>
      handle_framing_timer(rc)

    if state.controlling_process do
      Enum.each(messages, &(report_message(new_state, &1)))
    end
    {:noreply, new_state}
  end
  defp handle_port({:notif, data}, state) do
    # Report an error from the port
    if state.controlling_process do
      report_message(state, data)
    end
    {:noreply, state}
  end

  defp report_message(state, message) do
    event = {:nerves_uart, state.name, message}
    send(state.controlling_process, event)
  end

  defp genserver_timeout(timeout) do
    max(timeout + @genserver_timeout_slack, @genserver_timeout_slack)
  end
  defp port_timeout(timeout) do
    max(timeout + @port_timeout_slack, @port_timeout_slack)
  end

  # Stop the framing timer if active and a frame completed
  defp handle_framing_timer(%{rx_framing_tref: tref} = state, :ok) when tref != nil do
    _ = :timer.cancel(tref)
    %{state | rx_framing_tref: tref}
  end
  # Start the framing timer if ended on an incomplete frame
  defp handle_framing_timer(%{rx_framing_timeout: timeout} = state, :in_frame) when timeout > 0 do
    _ = if state.rx_framing_tref, do: :timer.cancel(state.rx_framing_tref)
    {:ok, tref} = :timer.send_after(timeout, :rx_framing_timed_out)
    %{state | rx_framing_tref: tref}
  end
  # Don't do anything with the framing timer for all other reasons
  defp handle_framing_timer(state, _rc), do: state
end
