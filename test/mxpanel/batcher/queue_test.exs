defmodule Mxpanel.Batcher.QueueTest do
  use ExUnit.Case, async: true

  alias Mxpanel.Batcher.Queue

  describe "new/0" do
    test "create and empty queue" do
      queue = Queue.new()

      assert queue.size == 0
      assert queue.items == []
    end
  end

  describe "to_list/1" do
    test "returns all items" do
      queue =
        Queue.new()
        |> Queue.add(1)
        |> Queue.add(2)

      assert Queue.to_list(queue) == [1, 2]
    end
  end

  describe "add/2" do
    test "add items to the front" do
      queue =
        Queue.new()
        |> Queue.add(1)
        |> Queue.add(2)

      assert queue.items == [2, 1]
    end

    test "support adding many items" do
      queue =
        Queue.new()
        |> Queue.add(1)
        |> Queue.add([2, 3])

      assert queue.items == [3, 2, 1]
    end
  end
end
