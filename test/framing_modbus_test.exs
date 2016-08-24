defmodule FramingLineTest do
  use ExUnit.Case
  alias Nerves.UART.Framing.Modbus

  test "adds framing (does nothing)" do
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)
    assert {:ok, "", ^line} = Modbus.add_framing("", line)
    assert {:ok, "ABC\n", ^line} = Modbus.add_framing("ABC\n", line)
  end

  test "handles broken up lines" do
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:in_frame, [], line} = Modbus.remove_framing(<<1, 3, 4, 0, 13>>, line)
    assert {:ok, [<<1, 3, 4, 0, 13, 0, 54, 235, 230>>], line} = Modbus.remove_framing(<<0, 54, 235, 230>>, line)

    assert Modbus.buffer_empty?(line) == true
  end

  test "handles everything in one line" do
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:ok, [<<1, 3, 4, 0, 13, 0, 54, 235, 230>>], line} = Modbus.remove_framing(<<1, 3, 4, 0, 13, 0, 54, 235, 230>>, line)
    assert Modbus.buffer_empty?(line) == true
  end

  test "deals with extra junk data across multiple frames" do
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)

    assert {:in_frame, [], line} = Modbus.remove_framing(<<1, 3, 4, 0, 13>>, line)
    assert {:ok, [<<1, 3, 4, 0, 13, 0, 54, 235, 230>>], line} = Modbus.remove_framing(<<0, 54, 235, 230, 5, 5, 5>>, line)
    assert Modbus.buffer_empty?(line) == true
  end

  test "deals with extra junk data in one frame" do
    {:ok, line} = Modbus.init(max_length: 255, slave_id: 1)
    assert {:ok, [<<1, 3, 4, 0, 13, 0, 54, 235, 230>>], line} = Modbus.remove_framing(<<1, 3, 4, 0, 13, 0, 54, 235, 230, 5, 5, 5, 5>>, line)
    assert Modbus.buffer_empty?(line) == true
  end

end
