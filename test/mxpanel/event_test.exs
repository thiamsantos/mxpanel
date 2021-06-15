defmodule Mxpanel.EventTest do
  use ExUnit.Case, async: true

  alias Mxpanel.Event

  describe "new/3" do
    test "create new event" do
      event = Event.new("signup", "13793")

      assert event.name == "signup"
      assert event.distinct_id == "13793"
      assert is_integer(event.time)
      assert String.length(event.insert_id) == 43
      assert event.additional_properties == %{}
    end
    test "optional additional properties" do
      event = Event.new("signup", "13793", %{"Favourite Color" => "Red"})

      assert event.additional_properties == %{"Favourite Color" => "Red"}
    end
  end

  describe "serialize/2" do
    test "serialize event" do
      event = Event.new("signup", "13793", %{"Favourite Color" => "Red"})

      actual = Event.serialize(event, "project_token")

      assert actual == %{
        "event" => "signup",
        "properties" => %{
          "distinct_id" => "13793",
          "token" => "project_token",
          "$insert_id" => event.insert_id,
          "time" => event.time,
          "Favourite Color" => "Red"
        }
      }
    end
  end
end
