defmodule Mxpanel.People do
  @shared_options_schema [
    ip: [
      type: :string,
      doc: "IP address to get automatic geolocation info."
    ],
    ignore_time: [
      type: :boolean,
      doc:
        "Prevent the `$last_seen` property from incorrectly updating user profile properties with misleading timestamps in server-side Mixpanel implementations."
    ],
    time: [
      type: :pos_integer,
      doc: "Specific timestamp in seconds of the event. Defaults to `System.os_time(:second)`."
    ]
  ]

  @delete_schema [
    ignore_alias: [
      type: :boolean,
      doc: "If you have duplicate profiles, set `ignore_alias` to true so that you
    don't delete the original profile when trying to delete the duplicate."
    ]
  ]

  @moduledoc """
  Functions to manipulate user profiles.

  ## Shared Options

  All of the functions in this module accept the following options:

  #{NimbleOptions.docs(@shared_options_schema)}

  """

  alias Mxpanel.Operation

  @doc """
  Sets properties for a profile identified by its `distinct_id`.
  If the profile does not exist, it creates it with these properties.
  If it does exist, it sets the properties to these values, overwriting existing values.

      properties = %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}
      Mxpanel.People.set(client, "13793", properties)

  """
  @spec set(String.t(), map(), Keyword.t()) :: Operation.t()
  def set(distinct_id, properties, opts \\ [])
      when is_binary(distinct_id) and is_map(properties) and is_list(opts) do
    payload =
      distinct_id
      |> build_payload("$set", properties, opts)

    %Operation{endpoint: :engage, payload: payload}
  end

  @doc """
  Works just like `set/4` except it will not overwrite existing property values. This is useful for properties like "First login date".

      properties = %{"First login date" => "2013-04-01T13:20:00"}
      Mxpanel.People.set_once(client, "13793", properties)

  """
  @spec set_once(String.t(), map(), Keyword.t()) :: Operation.t()
  def set_once(distinct_id, properties, opts \\ [])
      when is_binary(distinct_id) and is_map(properties) and is_list(opts) do
    payload =
      distinct_id
      |> build_payload("$set_once", properties, opts)

    %Operation{endpoint: :engage, payload: payload}
  end

  @doc """
  Takes a list of property names, and permanently removes the properties and their values from a profile.

      property_names = ["Address", "Birthday"]
      Mxpanel.People.unset(client, "13793", property_names)

  """
  @spec unset(String.t(), [String.t()], Keyword.t()) :: Operation.t()
  def unset(distinct_id, property_names, opts \\ [])
      when is_binary(distinct_id) and is_list(property_names) do
    payload =
      distinct_id
      |> build_payload("$unset", property_names, opts)

    %Operation{endpoint: :engage, payload: payload}
  end

  @doc """
  Increment the value of a user profile property. When processed, the property
  values are added to the existing values of the properties on the profile.
  If the property is not present on the profile, the value will be added to 0.
  It is possible to decrement by calling with negative values.

      Mxpanel.People.increment(client, "13793", "Number of Logins", 12)

  """
  @spec increment(String.t(), String.t(), String.t(), Keyword.t()) ::
          Operation.t()
  def increment(distinct_id, property, amount, opts \\ [])
      when is_binary(distinct_id) and is_binary(property) and is_integer(amount) and
             is_list(opts) do
    payload =
      distinct_id
      |> build_payload("$add", %{property => amount}, opts)

    %Operation{endpoint: :engage, payload: payload}
  end

  @doc """
  Appends the item to a list associated with the corresponding property name.
  Appending to a property that doesn't exist will result in assigning a list with one element to that property.

      Mxpanel.People.append_item(client, "13793", "Items purchased", "socks")

  """
  @spec append_item(String.t(), String.t(), String.t(), Keyword.t()) ::
          Operation.t()
  def append_item(distinct_id, property, item, opts \\ [])
      when is_binary(distinct_id) and is_binary(property) and is_binary(item) and is_list(opts) do
    payload =
      distinct_id
      |> build_payload("$append", %{property => item}, opts)

    %Operation{endpoint: :engage, payload: payload}
  end

  @doc """
  Removes an item from a existing list on the user profile.
  If it does not exist, no updates are made.

      Mxpanel.People.remove_item(client, "13793", "Items purchased", "t-shirt")

  """
  @spec remove_item(String.t(), String.t(), String.t(), Keyword.t()) ::
          Operation.t()
  def remove_item(distinct_id, property, item, opts \\ [])
      when is_binary(distinct_id) and is_binary(property) and is_binary(item) and is_list(opts) do
    payload =
      distinct_id
      |> build_payload("$remove", %{property => item}, opts)

    %Operation{endpoint: :engage, payload: payload}
  end

  @doc """
  Permanently delete the profile from Mixpanel, along with all of its properties.

      Mxpanel.People.delete(client, "13793")

  If you have duplicate profiles, set `ignore_alias` to true so that you
  don't delete the original profile when trying to delete the duplicate.

      Mxpanel.People.delete(client, "user@mail.com", ignore_alias: true)

  """
  @spec delete(String.t(), Keyword.t()) :: Operation.t()
  def delete(distinct_id, opts \\ [])
      when is_binary(distinct_id) and is_list(opts) do
    payload =
      distinct_id
      |> build_payload("$delete", "", opts)

    %Operation{endpoint: :engage, payload: payload}
  end

  defp build_payload(distinct_id, operation, properties, opts) do
    opts = validate_options!(operation, opts)
    modifiers = build_modifiers(opts)

    Map.merge(
      %{
        "$distinct_id" => distinct_id,
        "$time" => Keyword.get(opts, :time, System.os_time(:second)),
        operation => properties
      },
      modifiers
    )
  end

  defp validate_options!(operation, opts) do
    case NimbleOptions.validate(opts, schema(operation)) do
      {:ok, options} ->
        options

      {:error, %NimbleOptions.ValidationError{message: message}} ->
        raise ArgumentError, message
    end
  end

  defp build_modifiers(opts) do
    opts
    |> Keyword.take([:ignore_time, :ignore_alias, :ip])
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new(fn {k, v} -> {"$#{k}", v} end)
  end

  defp schema("$delete"), do: Keyword.merge(@shared_options_schema, @delete_schema)
  defp schema(_), do: @shared_options_schema
end
