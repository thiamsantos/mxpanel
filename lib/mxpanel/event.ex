defmodule Mxpanel.Event do
  @moduledoc """
  Struct representing a Mixpanel Event
  """

  defstruct [:name, :insert_id, :time, :distinct_id, :additional_properties]

  @type t :: %__MODULE__{
          name: String.t(),
          insert_id: String.t(),
          time: integer(),
          additional_properties: %{}
        }

  @doc """
  Create a new event.

      Mxpanel.Event.new("signup", "13793", %{"Favourite Color" => "Red"})

  """
  @spec new(String.t(), String.t(), map()) :: t()
  def new(name, distinct_id, additional_properties \\ %{})
      when is_binary(name) and is_binary(distinct_id) do
    %__MODULE__{
      name: name,
      distinct_id: distinct_id,
      insert_id: unique_insert_id(),
      time: System.os_time(:second),
      additional_properties: additional_properties
    }
  end

  @doc """
  Serialize a event into the format expected by the Mixpanel API.
  """
  @spec serialize(t(), String.t()) :: map()
  def serialize(%__MODULE__{} = event, token) when is_binary(token) do
    properties = %{
      "distinct_id" => event.distinct_id,
      "token" => token,
      "$insert_id" => event.insert_id,
      "time" => event.time
    }

    %{
      "event" => event.name,
      "properties" => Map.merge(event.additional_properties, properties)
    }
  end

  defp unique_insert_id do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.encode64(padding: false)
  end
end
