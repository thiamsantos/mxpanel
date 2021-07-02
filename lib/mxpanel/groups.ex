defmodule Mxpanel.Groups do
  @moduledoc """
  Functions to manipulate group profiles.

  ## Shared Options

  All of the functions in this module accept the following options:

  #{NimbleOptions.docs(Mxpanel.Groups.UpdateEvent.schema())}

  """

  alias Mxpanel.API
  alias Mxpanel.Client
  alias Mxpanel.Groups.UpdateEvent

  @doc """
  Updates or adds properties to a group profile.
  The profile is created if it does not exist.

      properties = %{"Address" => "1313 Mockingbird Lane"}
      Mxpanel.Groups.set(client, "Company", "Mixpanel", properties)

  """
  @spec set(Client.t(), String.t(), String.t(), map(), Keyword.t()) :: :ok | {:error, term()}
  def set(%Client{} = client, group_key, group_id, properties, opts \\ [])
      when is_binary(group_key) and is_binary(group_id) and is_map(properties) and is_list(opts) do
    data =
      group_key
      |> UpdateEvent.new(group_id, "$set", properties, opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/groups", data)
  end

  @doc """
  Adds properties to a group only if the property is not already set.
  The profile is created if it does not exist.

      properties = %{"Address" => "1313 Mockingbird Lane"}
      Mxpanel.Groups.set_once(client, "Company", "Mixpanel", properties)

  """
  @spec set_once(Client.t(), String.t(), String.t(), map(), Keyword.t()) :: :ok | {:error, term()}
  def set_once(%Client{} = client, group_key, group_id, properties, opts \\ [])
      when is_binary(group_key) and is_binary(group_id) and is_map(properties) and is_list(opts) do
    data =
      group_key
      |> UpdateEvent.new(group_id, "$set_once", properties, opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/groups", data)
  end

  @doc """
  Unsets specific properties on the group profile.

      property_names = ["Items purchased"]
      Mxpanel.Groups.unset(client, "Company", "Mixpanel", property_names)

  """
  @spec unset(Client.t(), String.t(), String.t(), [String.t()], Keyword.t()) ::
          :ok | {:error, term()}
  def unset(%Client{} = client, group_key, group_id, property_names, opts \\ [])
      when is_binary(group_key) and is_binary(group_id) and is_list(property_names) do
    data =
      group_key
      |> UpdateEvent.new(group_id, "$unset", property_names, opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/groups", data)
  end

  @doc """
  Removes a specific value in a list property.

      Mxpanel.Groups.remove_item(client, "Company", "Mixpanel", "Items purchased", "t-shirt")

  """
  @spec remove_item(Client.t(), String.t(), String.t(), String.t(), String.t(), Keyword.t()) ::
          :ok | {:error, term()}
  def remove_item(%Client{} = client, group_key, group_id, property, item, opts \\ [])
      when is_binary(group_key) and is_binary(group_id) and is_binary(property) and
             is_binary(item) and is_list(opts) do
    data =
      group_key
      |> UpdateEvent.new(group_id, "$remove", %{property => item}, opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/groups", data)
  end

  @doc """
  Deletes a group profile from Mixpanel.

      Mxpanel.Groups.delete(client, "Company", "Mixpanel")

  """
  @spec delete(Client.t(), String.t(), String.t(), Keyword.t()) :: :ok | {:error, term()}
  def delete(%Client{} = client, group_key, group_id, opts \\ [])
      when is_binary(group_key) and is_binary(group_id) and is_list(opts) do
    data =
      group_key
      |> UpdateEvent.new(group_id, "$delete", "", opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/groups", data)
  end

  @doc """
  Adds the specified values to a list property on a group profile and ensures
  that those values only appear once.

      properties = %{"Items purchased" => ["socks", "shirts"], "Browser" => "ie"}
      Mxpanel.Groups.union(client, "Company", "Mixpanel", properties)

  """
  def union(%Client{} = client, group_key, group_id, properties, opts \\ [])
      when is_binary(group_key) and is_binary(group_id) and is_map(properties) and is_list(opts) do
    data =
      group_key
      |> UpdateEvent.new(group_id, "$union", properties, opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/groups", data)
  end
end
