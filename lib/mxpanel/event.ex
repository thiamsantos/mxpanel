defmodule Mxpanel.Event do
  @moduledoc """
  Struct representing a Mixpanel Event
  """

  @opts_schema [
    time: [
      type: :pos_integer,
      doc: "Specific timestamp in seconds of the event. Defaults to `System.os_time(:second)`."
    ],
    ip: [
      type: :string,
      doc: "IP address to get automatic geolocation info."
    ]
  ]

  defstruct [:name, :insert_id, :time, :distinct_id, :additional_properties, :ip]

  @type t :: %__MODULE__{
          name: String.t(),
          insert_id: String.t(),
          time: integer(),
          additional_properties: %{},
          ip: nil | String.t()
        }

  @doc """
  Create a new event.

      Mxpanel.Event.new("signup", "13793")
      Mxpanel.Event.new("signup", "13793", %{"Favourite Color" => "Red"})
      Mxpanel.Event.new("signup", "13793", %{}, ip: "72.229.28.185")
      Mxpanel.Event.new("signup", "13793", %{}, time: 1624811298)


  ## Options

  #{NimbleOptions.docs(@opts_schema)}

  """
  @spec new(String.t(), String.t(), map()) :: t()
  def new(name, distinct_id, additional_properties \\ %{}, opts \\ [])
      when is_binary(name) and is_binary(distinct_id) and is_map(additional_properties) do
    opts = validate_options!(opts)

    %__MODULE__{
      name: name,
      distinct_id: distinct_id,
      insert_id: unique_insert_id(),
      time: Keyword.get(opts, :time, System.os_time(:second)),
      additional_properties: additional_properties,
      ip: Keyword.get(opts, :ip)
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
      "properties" =>
        event.additional_properties
        |> Map.merge(properties)
        |> maybe_put("ip", event.ip, fn ip -> is_binary(ip) end)
    }
  end

  defp validate_options!(opts) do
    case NimbleOptions.validate(opts, @opts_schema) do
      {:ok, opts} ->
        opts

      {:error, %NimbleOptions.ValidationError{message: message}} ->
        raise ArgumentError, message
    end
  end

  defp maybe_put(map, key, value, condition) do
    if condition.(value) do
      Map.put(map, key, value)
    else
      map
    end
  end

  defp unique_insert_id do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.encode64(padding: false)
  end
end
