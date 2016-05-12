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

    * `vendor_id` - The 16-bit USB vendor ID of the device providing the port. Vendor ID to name lists are managed through usb.org
    * `product_id` - The 16-bit vendor supplied product ID
    * `manufacturer` - The manufacturer of the port
    * `description` - A description or product name
    * `serial_number` - The device's serial number if it has one
  """
  def enumerate() do
    Nerves.UART.Enumerator.enumerate
  end

  @doc """
  Start up a UART GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  @doc """
  Stop the UART GenServer.
  """
  def stop(pid) do
    GenServer.stop(pid)
  end

  @doc """
  Open a serial port. Pass one
  or more of the following options to configure the port:

    * `:active n`       - where n is true or false (see discussion below)
    * `:speed n`        - n is the baudrate of the board (e.g., 115200)
    * `:data_bits n`    - n is the number of data bits (e.g., 5, 6, 7, or 8)
    * `:stop_bits n`    - n is the number of stop bits (e.g., 1 or 2)
    * `:parity n`       - n is `:none`, `:even`, `:odd`, `:space`, or `:mark`
      * `:space` means that the parity bit is always 0
      * `:mark` means that the parity bit is always 1
    * `:flow_control n` - n is :none, :hardware, or :software

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
  def open(pid, name, opts \\ []) do
    GenServer.call pid, {:open, name, opts}
  end

  @doc """
  Close the serial port. The GenServer continues to run so that a port can
  be opened again.
  """
  def close(pid) do
    GenServer.call pid, :close
  end

  @doc """
  Change the serial port configuration after `open/3` has been called. See
  `open/3` for the valid options.
  """
  def configure(pid, opts) do
    GenServer.call pid, {:configure, opts}
  end

  @doc """
  Send a continuous stream of zero bits for a duration in milliseconds.
  If the duration is zero, then zero bits are transmitted by at least 0.25
  seconds, but no more than 0.5 seconds. If non-zero, then zero bits are
  transmitted for about that many milliseconds depending on the implementation.
  """
  def send_break(pid, duration \\ 0) do
    GenServer.call pid, {:send_break, duration}
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
  def write(pid, data, timeout) when is_binary(data) do
    GenServer.call pid, {:write, data, timeout}, genserver_timeout(timeout)
  end
  def write(pid, data, timeout) when is_list(data) do
    write(pid, :erlang.iolist_to_binary(data), timeout)
  end

  @doc """
  Write data to the opened UART with the default timeout.
  """
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
  def read(pid, timeout \\ 5000) do
    GenServer.call pid, {:read, timeout}, genserver_timeout(timeout)
  end

  @doc """
  Waits until all data has been transmitted. See [tcdrain(3)](http://linux.die.net/man/3/tcdrain) for low level
  details on Linux or OSX. This is not implemented on Windows.
  """
  def drain(pid) do
    GenServer.call pid, :drain
  end

  @doc """
  Flushes the receive buffer. See [tcflush(3)](http://linux.die.net/man/3/tcflush) for low level details on
  Linux or OSX. This calls `PurgeComm` on Windows.
  """
  def flush(pid) do
    GenServer.call pid, :flush
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
    state = %{port: port, controlling_process: nil, name: nil}
    {:ok, state}
  end

  def handle_call({:open, name, opts}, {from_pid, _}, state) do
    response = call_port(state, :open, {name, opts})
    state = %{state | name: name, controlling_process: from_pid}
    {:reply, response, state}
  end
  def handle_call(:close, _from, state) do
    response = call_port(state, :close, [])
    {:reply, response, state}
  end
  def handle_call({:read, timeout}, _from, state) do
    response = call_port(state, :read, timeout, port_timeout(timeout))
    {:reply, response, state}
  end
  def handle_call({:write, value, timeout}, _from, state) do
    response = call_port(state, :write, {value, timeout}, port_timeout(timeout))
    {:reply, response, state}
  end
  def handle_call({:configure, opts}, _from, state) do
    response = call_port(state, :configure, opts)
    {:reply, response, state}
  end
  def handle_call(:drain, _from, state) do
    response = call_port(state, :drain, [])
    {:reply, response, state}
  end
  def handle_call(:flush, _from, state) do
    response = call_port(state, :flush, [])
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

  defp call_port(state, command, arguments, timeout \\ 4000) do
    msg = {command, arguments}
    send state.port, {self, {:command, :erlang.term_to_binary(msg)}}
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

  defp handle_port({:notif, data}, state) do
    #IO.puts "Received data on port #{state.name}"
    msg = {:nerves_uart, state.name, data}
    if state.controlling_process do
      send state.controlling_process, msg
    end
    {:noreply, state}
  end

  defp genserver_timeout(timeout) do
    max(timeout + @genserver_timeout_slack, @genserver_timeout_slack)
  end
  defp port_timeout(timeout) do
    max(timeout + @port_timeout_slack, @port_timeout_slack)
  end
end
