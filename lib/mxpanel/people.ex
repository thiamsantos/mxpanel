defmodule Mxpanel.People do
  @moduledoc """
  Functions to manipulate user profiles.

  ## Shared Options

  All of the functions in this module accept the following options:

  #{NimbleOptions.docs(Mxpanel.People.UpdateEvent.shared_options_schema())}

  """

  alias Mxpanel.API
  alias Mxpanel.Client
  alias Mxpanel.People.UpdateEvent

  @doc """
  Sets properties for a profile identified by its `distinct_id`.
  If the profile does not exist, it creates it with these properties.
  If it does exist, it sets the properties to these values, overwriting existing values.

      properties = %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}
      Mxpanel.People.set(client, "13793", properties)

  """
  @spec set(Client.t(), String.t(), map(), Keyword.t()) :: :ok | {:error, term()}
  def set(%Client{} = client, distinct_id, properties, opts \\ [])
      when is_binary(distinct_id) and is_map(properties) and is_list(opts) do
    data =
      distinct_id
      |> UpdateEvent.new("$set", properties, opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/engage", data)
  end

  @doc """
  Works just like `set/4` except it will not overwrite existing property values. This is useful for properties like "First login date".

      properties = %{"First login date" => "2013-04-01T13:20:00"}
      Mxpanel.People.set_once(client, "13793", properties)

  """
  @spec set_once(Client.t(), String.t(), map(), Keyword.t()) :: :ok | {:error, term()}
  def set_once(%Client{} = client, distinct_id, properties, opts \\ [])
      when is_binary(distinct_id) and is_map(properties) and is_list(opts) do
    data =
      distinct_id
      |> UpdateEvent.new("$set_once", properties, opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/engage", data)
  end

  @doc """
  Takes a list of property names, and permanently removes the properties and their values from a profile.

      property_names = ["Address", "Birthday"]
      Mxpanel.People.unset(client, "13793", property_names)

  """
  @spec unset(Client.t(), String.t(), [String.t()], Keyword.t()) :: :ok | {:error, term()}
  def unset(%Client{} = client, distinct_id, property_names, opts \\ [])
      when is_binary(distinct_id) and is_list(property_names) do
    data =
      distinct_id
      |> UpdateEvent.new("$unset", property_names, opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/engage", data)
  end

  @doc """
  Increment the value of a user profile property. When processed, the property
  values are added to the existing values of the properties on the profile.
  If the property is not present on the profile, the value will be added to 0.
  It is possible to decrement by calling with negative values.

      Mxpanel.People.increment(client, "13793", "Number of Logins", 12)

  """
  @spec increment(Client.t(), String.t(), String.t(), String.t(), Keyword.t()) ::
          :ok | {:error, term()}
  def increment(%Client{} = client, distinct_id, property, amount, opts \\ [])
      when is_binary(distinct_id) and is_binary(property) and is_integer(amount) and
             is_list(opts) do
    data =
      distinct_id
      |> UpdateEvent.new("$add", %{property => amount}, opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/engage", data)
  end

  @doc """
  Appends the item to a list associated with the corresponding property name.
  Appending to a property that doesn't exist will result in assigning a list with one element to that property.

      Mxpanel.People.append_item(client, "13793", "Items purchased", "socks")

  """
  @spec append_item(Client.t(), String.t(), String.t(), String.t(), Keyword.t()) ::
          :ok | {:error, term()}
  def append_item(%Client{} = client, distinct_id, property, item, opts \\ [])
      when is_binary(distinct_id) and is_binary(property) and is_binary(item) and is_list(opts) do
    data =
      distinct_id
      |> UpdateEvent.new("$append", %{property => item}, opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/engage", data)
  end

  @doc """
  Removes an item from a existing list on the user profile.
  If it does not exist, no updates are made.

      Mxpanel.People.remove_item(client, "13793", "Items purchased", "t-shirt")

  """
  @spec remove_item(Client.t(), String.t(), String.t(), String.t(), Keyword.t()) ::
          :ok | {:error, term()}
  def remove_item(%Client{} = client, distinct_id, property, item, opts \\ [])
      when is_binary(distinct_id) and is_binary(property) and is_binary(item) and is_list(opts) do
    data =
      distinct_id
      |> UpdateEvent.new("$remove", %{property => item}, opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/engage", data)
  end

  @doc """
  Permanently delete the profile from Mixpanel, along with all of its properties.

      Mxpanel.People.delete(client, "13793")

  If you have duplicate profiles, set `ignore_alias` to true so that you
  don't delete the original profile when trying to delete the duplicate.

      Mxpanel.People.delete(client, "user@mail.com", ignore_alias: true)

  """
  @spec delete(Client.t(), String.t(), Keyword.t()) :: :ok | {:error, term()}
  def delete(%Client{} = client, distinct_id, opts \\ [])
      when is_binary(distinct_id) and is_list(opts) do
    data =
      distinct_id
      |> UpdateEvent.new("$delete", "", opts)
      |> UpdateEvent.serialize(client.token)

    API.request(client, "/engage", data)
  end
end
