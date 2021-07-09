defmodule Mxpanel do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias Mxpanel.API
  alias Mxpanel.Batcher
  alias Mxpanel.Client
  alias Mxpanel.Operation

  @event_opts_schema [
    time: [
      type: :pos_integer,
      doc: "Specific timestamp in seconds of the event. Defaults to `System.os_time(:second)`."
    ],
    ip: [
      type: :string,
      doc: "IP address to get automatic geolocation info."
    ]
  ]

  @doc """
  Tracks an event.

      "signup"
      |> Mxpanel.track("13793")
      |> Mxpanel.deliver()

      "signup"
      |> Mxpanel.track("13793")
      |> Mxpanel.deliver()

      "signup"
      |> Mxpanel.track("13793", %{"Favourite Color" => "Red"})
      |> Mxpanel.deliver()

      "signup"
      |> Mxpanel.track("13793", %{}, ip: "72.229.28.185")
      |> Mxpanel.deliver()

      "signup"
      |> Mxpanel.track("13793", %{}, time: 1624811298)
      |> Mxpanel.deliver()

  ## Options

  #{NimbleOptions.docs(@event_opts_schema)}

  """
  @spec track(String.t(), String.t(), map(), Keyword.t()) :: Operation.t()
  def track(name, distinct_id, additional_properties \\ %{}, opts \\ [])
      when is_binary(name) and is_binary(distinct_id) and is_map(additional_properties) do
    payload = build_event(name, distinct_id, additional_properties, opts)

    %Operation{endpoint: :track, payload: payload}
  end

  defp build_event(name, distinct_id, additional_properties, opts) do
    opts = validate_options!(opts)

    properties = %{
      "distinct_id" => distinct_id,
      "$insert_id" => unique_insert_id(),
      "time" => Keyword.get(opts, :time, System.os_time(:second))
    }

    %{
      "event" => name,
      "properties" =>
        additional_properties
        |> Map.merge(properties)
        |> maybe_put("ip", Keyword.get(opts, :ip), fn ip -> is_binary(ip) end)
    }
  end

  defp validate_options!(opts) do
    case NimbleOptions.validate(opts, @event_opts_schema) do
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

  @doc """
  Creates an alias for an existing distinct id.

      "distinct_id"
      |> Mxpanel.create_alias("your_alias")
      |> Mxpanel.deliver()

  """
  @spec create_alias(String.t(), String.t()) :: Operation.t()
  def create_alias(distinct_id, alias_id)
      when is_binary(distinct_id) and is_binary(alias_id) do
    payload = %{
      "event" => "$create_alias",
      "properties" => %{
        "distinct_id" => distinct_id,
        "alias" => alias_id
      }
    }

    %Operation{endpoint: :track, payload: payload}
  end

  @doc """
  Delivers an operation to the mixpanel API using the configured HTTP client.

      Mxpanel.deliver(operation, client)
      Mxpanel.deliver([operation_1, operation_2], client)

  """
  @spec deliver(Operation.t() | [Operation.t()], Client.t()) :: :ok | {:error, term()}

  def deliver([], %Client{}), do: :ok

  def deliver(operation_or_operations, %Client{} = client) do
    path = get_path(operation_or_operations)
    data = build_data(operation_or_operations, client)

    API.request(client, path, data)
  end

  defp get_path(operation_or_operations) do
    endpoints =
      operation_or_operations
      |> List.wrap()
      |> Enum.map(& &1.endpoint)
      |> Enum.uniq()

    first_endpoint = List.first(endpoints)

    unless Enum.all?(endpoints, fn e -> e == first_endpoint end) do
      raise ArgumentError,
            "expected all endpoints to be equal, got different endpoints: #{inspect(endpoints)}"
    end

    case first_endpoint do
      :track -> "/track"
      :engage -> "/engage"
      :groups -> "/groups"
    end
  end

  defp build_data(operations, client) when is_list(operations) do
    Enum.map(operations, &build_data(&1, client))
  end

  defp build_data(%Operation{endpoint: :track, payload: payload}, client) when is_map(payload) do
    put_in(payload, ["properties", "token"], client.token)
  end

  defp build_data(%Operation{endpoint: endpoint, payload: payload}, client)
       when endpoint in [:engage, :groups] and is_map(payload) do
    Map.put(payload, "$token", client.token)
  end

  @doc """
  Enqueues an operation. The operation will be stored in a buffer and sent in batches to mixpanel.

      Mxpanel.Batcher.start_link(name: MyApp.MxpanelBatcher, token: "mixpanel project token")

      "signup"
      |> Mxpanel.track("13793")
      |> Mxpanel.deliver_later(MyApp.MxpanelBatcher)

  Sending multiple operations:

      operation_1 = Mxpanel.track("signup", "13793")
      operation_2 = Mxpanel.track("first login", "13793")

      Mxpanel.deliver_later([operation_1, operation_2], MyApp.MxpanelBatcher)

  ## Why use it?

  HTTP requests to the Mixpanel API often take time and may fail. If you are
  tracking events during a web request, you probably, don't want to make your
  users wait the extra time for the mixpanel API call to finish. The batcher will
  enqueue the operations, send them in batches to mixpanel with automatic retries.

  Checkout `Mxpanel.Batcher` for more information.

  """
  @spec deliver_later(Operation.t() | [Operation.t()], Batcher.name()) :: :ok
  def deliver_later(operation_or_operations, batcher_name) when is_atom(batcher_name) do
    Batcher.enqueue(batcher_name, operation_or_operations)
  end

  @doc """
  Returns the configured JSON encoding library for Mxpnale (defaults to Jason).

  To customize the JSON library, including the following in your config/config.exs:

      config :mxpanel, :json_library, Jason

  """
  @spec json_library :: module()
  def json_library do
    Application.get_env(:mxpanel, :json_library, Jason)
  end
end
