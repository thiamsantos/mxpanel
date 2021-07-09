defmodule Mxpanel.PeopleTest do
  use ExUnit.Case, async: true

  alias Mxpanel.People

  describe "set/3" do
    test "build operation" do
      properties = %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}
      operation = People.set("123", properties)

      assert operation.endpoint == :engage
      assert operation.payload["$distinct_id"] == "123"
      assert operation.payload["$set"] == properties
      assert is_integer(operation.payload["$time"])

      assert Map.has_key?(operation.payload, "$ignore_time") == false
      assert Map.has_key?(operation.payload, "$ip") == false
    end

    test "accept options" do
      properties = %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}
      time = System.os_time(:second)

      operation =
        People.set("123", properties,
          time: time,
          ip: "123.123.123.123",
          ignore_time: true
        )

      assert operation.payload["$time"] == time
      assert operation.payload["$ip"] == "123.123.123.123"
      assert operation.payload["$ignore_time"] == true
    end

    test "invalid time" do
      message = "expected :time to be a positive integer, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        People.set("123", %{}, time: :invalid)
      end
    end

    test "invalid ip" do
      message = "expected :ip to be a string, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        People.set("123", %{}, ip: :invalid)
      end
    end

    test "invalid ignore_time" do
      message = "expected :ignore_time to be a boolean, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        People.set("123", %{}, ignore_time: :invalid)
      end
    end
  end

  describe "unset/3" do
    test "build operation" do
      operation = People.unset("123", ["Days Overdue"])

      assert operation.endpoint == :engage
      assert operation.payload["$distinct_id"] == "123"
      assert operation.payload["$unset"] == ["Days Overdue"]
      assert is_integer(operation.payload["$time"])

      assert Map.has_key?(operation.payload, "$ignore_time") == false
      assert Map.has_key?(operation.payload, "$ip") == false
    end

    test "accepts options" do
      time = System.os_time(:second)

      operation =
        People.unset("123", ["Days Overdue"],
          time: time,
          ip: "123.123.123.123",
          ignore_time: true
        )

      assert operation.payload["$time"] == time
      assert operation.payload["$ignore_time"] == true
      assert operation.payload["$ip"] == "123.123.123.123"
    end
  end

  describe "set_once/3" do
    test "build operation" do
      properties = %{"First login date" => "2013-04-01T13:20:00"}

      operation = People.set_once("123", properties)

      assert operation.endpoint == :engage
      assert operation.payload["$distinct_id"] == "123"
      assert operation.payload["$set_once"] == properties
      assert is_integer(operation.payload["$time"])

      assert Map.has_key?(operation.payload, "$ignore_time") == false
      assert Map.has_key?(operation.payload, "$ip") == false
    end

    test "accepts options" do
      properties = %{"First login date" => "2013-04-01T13:20:00"}
      time = System.os_time(:second)

      operation =
        People.set_once("123", properties,
          time: time,
          ip: "123.123.123.123",
          ignore_time: true
        )

      assert operation.payload["$time"] == time
      assert operation.payload["$ignore_time"] == true
      assert operation.payload["$ip"] == "123.123.123.123"
    end
  end

  describe "increment/4" do
    test "build operation" do
      operation = People.increment("123", "Coins Gathered", 12)

      assert operation.endpoint == :engage

      assert operation.payload["$distinct_id"] == "123"
      assert operation.payload["$add"] == %{"Coins Gathered" => 12}
      assert is_integer(operation.payload["$time"])

      assert Map.has_key?(operation.payload, "$ignore_time") == false
      assert Map.has_key?(operation.payload, "$ip") == false
    end

    test "accepts options" do
      time = System.os_time(:second)

      operation =
        People.increment("123", "Coins Gathered", 12,
          time: time,
          ip: "123.123.123.123",
          ignore_time: true
        )

      assert operation.payload["$time"] == time
      assert operation.payload["$ignore_time"] == true
      assert operation.payload["$ip"] == "123.123.123.123"
    end
  end

  describe "append_item/4" do
    test "build operation" do
      operation = People.append_item("123", "Power Ups", "Bubble Lead")

      assert operation.endpoint == :engage
      assert operation.payload["$distinct_id"] == "123"
      assert operation.payload["$append"] == %{"Power Ups" => "Bubble Lead"}
      assert is_integer(operation.payload["$time"])

      assert Map.has_key?(operation.payload, "$ignore_time") == false
      assert Map.has_key?(operation.payload, "$ip") == false
    end

    test "accepts options" do
      time = System.os_time(:second)

      operation =
        People.append_item("123", "Power Ups", "Bubble Lead",
          time: time,
          ip: "123.123.123.123",
          ignore_time: true
        )

      assert operation.payload["$time"] == time
      assert operation.payload["$ignore_time"] == true
      assert operation.payload["$ip"] == "123.123.123.123"
    end
  end

  describe "remove_item/4" do
    test "build operation" do
      operation = People.remove_item("123", "Items purchased", "socks")

      assert operation.endpoint == :engage

      assert operation.payload["$distinct_id"] == "123"
      assert operation.payload["$remove"] == %{"Items purchased" => "socks"}
      assert is_integer(operation.payload["$time"])

      assert Map.has_key?(operation.payload, "$ignore_time") == false
      assert Map.has_key?(operation.payload, "$ip") == false
    end

    test "accepts options" do
      time = System.os_time(:second)

      operation =
        People.remove_item("123", "Items purchased", "socks",
          time: time,
          ip: "123.123.123.123",
          ignore_time: true
        )

      assert operation.endpoint == :engage
      assert operation.payload["$time"] == time
      assert operation.payload["$ignore_time"] == true
      assert operation.payload["$ip"] == "123.123.123.123"
    end
  end

  describe "delete/2" do
    test "build operation" do
      operation = People.delete("123")

      assert operation.endpoint == :engage
      assert operation.payload["$distinct_id"] == "123"
      assert operation.payload["$delete"] == ""
      assert is_integer(operation.payload["$time"])

      assert Map.has_key?(operation.payload, "$ignore_time") == false
      assert Map.has_key?(operation.payload, "$ip") == false
      assert Map.has_key?(operation.payload, "$ignore_alias") == false
    end

    test "accept options" do
      time = System.os_time(:second)

      operation =
        People.delete("123",
          time: time,
          ignore_time: true,
          ip: "123.123.123.123",
          ignore_alias: true
        )

      assert operation.payload["$time"] == time
      assert operation.payload["$ignore_time"] == true
      assert operation.payload["$ip"] == "123.123.123.123"
      assert operation.payload["$ignore_alias"] == true
    end

    test "invalid ignore_alias" do
      message = "expected :ignore_alias to be a boolean, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        People.delete("123", ignore_alias: :invalid)
      end
    end
  end
end
