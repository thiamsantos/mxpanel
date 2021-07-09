defmodule Mxpanel.GroupsTest do
  use ExUnit.Case, async: true

  alias Mxpanel.Groups

  describe "set/4" do
    test "build operation" do
      properties = %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}

      operation = Groups.set("Company", "Mixpanel", properties)

      assert operation.endpoint == :groups

      assert operation.payload["$group_key"] == "Company"
      assert operation.payload["$group_id"] == "Mixpanel"
      assert operation.payload["$set"] == properties
      assert is_integer(operation.payload["$time"])
    end

    test "custom time" do
      properties = %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}
      time = System.os_time(:second)
      operation = Groups.set("Company", "Mixpanel", properties, time: time)

      assert operation.payload["$time"] == time
    end

    test "invalid time" do
      message = "expected :time to be a positive integer, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        Groups.set("Company", "Mixpanel", %{}, time: :invalid)
      end
    end
  end

  describe "set_once/4" do
    test "build operation" do
      properties = %{"First login date" => "2013-04-01T13:20:00"}

      operation = Groups.set_once("Company", "Mixpanel", properties)

      assert operation.endpoint == :groups
      assert operation.payload["$group_key"] == "Company"
      assert operation.payload["$group_id"] == "Mixpanel"
      assert operation.payload["$set_once"] == properties
      assert is_integer(operation.payload["$time"])
    end

    test "custom time" do
      properties = %{"First login date" => "2013-04-01T13:20:00"}
      time = System.os_time(:second)

      operation = Groups.set_once("Company", "Mixpanel", properties, time: time)

      assert operation.payload["$time"] == time
    end
  end

  describe "union/4" do
    test "build operation" do
      properties = %{"Items purchased" => ["socks", "shirts"], "Browser" => "ie"}

      operation = Groups.union("Company", "Mixpanel", properties)

      assert operation.endpoint == :groups

      assert operation.payload["$group_key"] == "Company"
      assert operation.payload["$group_id"] == "Mixpanel"
      assert operation.payload["$union"] == properties
      assert is_integer(operation.payload["$time"])
    end

    test "custom time" do
      properties = %{"Items purchased" => ["socks", "shirts"], "Browser" => "ie"}
      time = System.os_time(:second)

      operation = Groups.union("Company", "Mixpanel", properties, time: time)

      assert operation.payload["$time"] == time
    end
  end

  describe "unset/4" do
    test "build operation" do
      operation = Groups.unset("Company", "Mixpanel", ["Days Overdue"])

      assert operation.endpoint == :groups
      assert operation.payload["$group_key"] == "Company"
      assert operation.payload["$group_id"] == "Mixpanel"
      assert operation.payload["$unset"] == ["Days Overdue"]
      assert is_integer(operation.payload["$time"])
    end

    test "custom time" do
      time = System.os_time(:second)

      operation = Groups.unset("Company", "Mixpanel", ["Days Overdue"], time: time)

      assert operation.payload["$time"] == time
    end
  end

  describe "remove_item/5" do
    test "build operation" do
      operation = Groups.remove_item("Company", "Mixpanel", "Items purchased", "socks")

      assert operation.endpoint == :groups
      assert operation.payload["$group_key"] == "Company"
      assert operation.payload["$group_id"] == "Mixpanel"
      assert operation.payload["$remove"] == %{"Items purchased" => "socks"}
      assert is_integer(operation.payload["$time"])
    end

    test "custom time" do
      time = System.os_time(:second)

      operation =
        Groups.remove_item("Company", "Mixpanel", "Items purchased", "socks", time: time)

      assert operation.payload["$time"] == time
    end
  end

  describe "delete/3" do
    test "build operation" do
      operation = Groups.delete("Company", "Mixpanel")

      assert operation.endpoint == :groups
      assert operation.payload["$group_key"] == "Company"
      assert operation.payload["$group_id"] == "Mixpanel"
      assert operation.payload["$delete"] == ""
      assert is_integer(operation.payload["$time"])
    end

    test "custom time" do
      time = System.os_time(:second)

      operation = Groups.delete("Company", "Mixpanel", time: time)
      assert operation.payload["$time"] == time
    end
  end
end
