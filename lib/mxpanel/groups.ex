defmodule Mxpanel.Groups do
  @options_schema [
    time: [
      type: :pos_integer,
      doc: "Specific timestamp in seconds of the event. Defaults to `System.os_time(:second)`."
    ]
  ]

  @moduledoc """
  Functions to manipulate group profiles.

  ## Shared Options

  All of the functions in this module accept the following options:

  #{NimbleOptions.docs(@options_schema)}

  """

  alias Mxpanel.Operation

  @doc """
  Updates or adds properties to a group profile.
  The profile is created if it does not exist.

      properties = %{"Address" => "1313 Mockingbird Lane"}
      Mxpanel.Groups.set(client, "Company", "Mixpanel", properties)

  """
  @spec set(String.t(), String.t(), map(), Keyword.t()) :: Operation.t()
  def set(group_key, group_id, properties, opts \\ [])
      when is_binary(group_key) and is_binary(group_id) and is_map(properties) and is_list(opts) do
    payload = build_payload(group_key, group_id, "$set", properties, opts)

    %Operation{endpoint: :groups, payload: payload}
  end

  @doc """
  Adds properties to a group only if the property is not already set.
  The profile is created if it does not exist.

      properties = %{"Address" => "1313 Mockingbird Lane"}
      Mxpanel.Groups.set_once(client, "Company", "Mixpanel", properties)

  """
  @spec set_once(String.t(), String.t(), map(), Keyword.t()) :: Operation.t()
  def set_once(group_key, group_id, properties, opts \\ [])
      when is_binary(group_key) and is_binary(group_id) and is_map(properties) and is_list(opts) do
    payload = build_payload(group_key, group_id, "$set_once", properties, opts)

    %Operation{endpoint: :groups, payload: payload}
  end

  @doc """
  Unsets specific properties on the group profile.

      property_names = ["Items purchased"]
      Mxpanel.Groups.unset(client, "Company", "Mixpanel", property_names)

  """
  @spec unset(String.t(), String.t(), [String.t()], Keyword.t()) ::
          Operation.t()
  def unset(group_key, group_id, property_names, opts \\ [])
      when is_binary(group_key) and is_binary(group_id) and is_list(property_names) do
    payload = build_payload(group_key, group_id, "$unset", property_names, opts)

    %Operation{endpoint: :groups, payload: payload}
  end

  @doc """
  Removes a specific value in a list property.

      Mxpanel.Groups.remove_item(client, "Company", "Mixpanel", "Items purchased", "t-shirt")

  """
  # TODO support pass map of properties
  @spec remove_item(String.t(), String.t(), String.t(), String.t(), Keyword.t()) ::
          Operation.t()
  def remove_item(group_key, group_id, property, item, opts \\ [])
      when is_binary(group_key) and is_binary(group_id) and is_binary(property) and
             is_binary(item) and is_list(opts) do
    payload = build_payload(group_key, group_id, "$remove", %{property => item}, opts)

    %Operation{endpoint: :groups, payload: payload}
  end

  @doc """
  Deletes a group profile from Mixpanel.

      Mxpanel.Groups.delete(client, "Company", "Mixpanel")

  """
  @spec delete(String.t(), String.t(), Keyword.t()) :: Operation.t()
  def delete(group_key, group_id, opts \\ [])
      when is_binary(group_key) and is_binary(group_id) and is_list(opts) do
    payload = build_payload(group_key, group_id, "$delete", "", opts)

    %Operation{endpoint: :groups, payload: payload}
  end

  @doc """
  Adds the specified values to a list property on a group profile and ensures
  that those values only appear once.

      properties = %{"Items purchased" => ["socks", "shirts"], "Browser" => "ie"}
      Mxpanel.Groups.union(client, "Company", "Mixpanel", properties)

  """
  @spec union(String.t(), String.t(), map(), Keyword.t()) :: Operation.t()
  def union(group_key, group_id, properties, opts \\ [])
      when is_binary(group_key) and is_binary(group_id) and is_map(properties) and is_list(opts) do
    payload = build_payload(group_key, group_id, "$union", properties, opts)

    %Operation{endpoint: :groups, payload: payload}
  end

  defp build_payload(group_key, group_id, operation, properties, opts) do
    opts = validate_options!(opts)

    %{
      "$group_key" => group_key,
      "$group_id" => group_id,
      "$time" => Keyword.get(opts, :time, System.os_time(:second)),
      operation => properties
    }
  end

  defp validate_options!(opts) do
    case NimbleOptions.validate(opts, @options_schema) do
      {:ok, options} ->
        options

      {:error, %NimbleOptions.ValidationError{message: message}} ->
        raise ArgumentError, message
    end
  end
end
