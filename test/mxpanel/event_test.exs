defmodule Mxpanel.EventTest do
  use ExUnit.Case, async: true

  alias Mxpanel.Event

  describe "new/4" do
    test "create new event" do
      event = Event.new("signup", "13793")

      assert event.name == "signup"
      assert event.distinct_id == "13793"
      assert event.ip == nil
      assert is_integer(event.time)
      assert String.length(event.insert_id) == 43
      assert event.additional_properties == %{}
    end

    test "optional additional properties" do
      event = Event.new("signup", "13793", %{"Favourite Color" => "Red"})

      assert event.additional_properties == %{"Favourite Color" => "Red"}
    end

    test "custom time" do
      time = 1234
      event = Event.new("signup", "13793", %{}, time: time)

      assert event.time == time
      assert event.additional_properties == %{}
    end

    test "invalid time" do
      message = "expected :time to be a positive integer, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        Event.new("signup", "13793", %{}, time: :invalid)
      end
    end

    test "custom ip" do
      event = Event.new("signup", "13793", %{}, ip: "123.123.123.123")

      assert event.ip == "123.123.123.123"
      assert event.additional_properties == %{}
    end

    test "invalid ip" do
      message = "expected :ip to be a string, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        Event.new("signup", "13793", %{}, ip: :invalid)
      end
    end
  end

  describe "serialize/2" do
    test "serialize event" do
      event = Event.new("signup", "13793", %{"Favourite Color" => "Red"})

      actual = Event.serialize(event)

      assert actual == %{
               "event" => "signup",
               "properties" => %{
                 "distinct_id" => "13793",
                 "$insert_id" => event.insert_id,
                 "time" => event.time,
                 "Favourite Color" => "Red"
               }
             }
    end

    test "serialize with custom ip" do
      event = Event.new("signup", "13793", %{"Favourite Color" => "Red"}, ip: "72.229.28.185")

      actual = Event.serialize(event)

      assert actual == %{
               "event" => "signup",
               "properties" => %{
                 "distinct_id" => "13793",
                 "$insert_id" => event.insert_id,
                 "time" => event.time,
                 "Favourite Color" => "Red",
                 "ip" => "72.229.28.185"
               }
             }
    end
  end
end
