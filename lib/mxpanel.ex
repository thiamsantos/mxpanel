defmodule Mxpanel do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias Mxpanel.API
  alias Mxpanel.Batcher
  alias Mxpanel.Client
  alias Mxpanel.Event
  alias Mxpanel.Operation

  # TODO validate and update all docs, moduledocs and examples readme

  # TODO doc
  # TODO typespec
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

  # TODO refactor
  defp build_data(%Operation{endpoint: :track, payload: payload}, client) when is_map(payload) do
    put_in(payload, ["properties", "token"], client.token)
  end

  defp build_data(%Operation{endpoint: :track, payload: payload}, client) when is_list(payload) do
    Enum.map(payload, &put_in(&1, ["properties", "token"], client.token))
  end

  defp build_data(%Operation{endpoint: endpoint, payload: payload}, client)
       when endpoint in [:engage, :groups] and is_map(payload) do
    Map.put(payload, "$token", client.token)
  end

  defp build_data(%Operation{endpoint: endpoint, payload: payload}, client)
       when endpoint in [:engage, :groups] and is_list(payload) do
    Enum.map(payload, &Map.put(&1, "$token", client.token))
  end

  @doc """
  Send a single event into Mixpanel.

      client = %Mxpanel.Client{token: "mixpanel project token"}
      event = Mxpanel.Event.new("signup", "123")
      Mxpanel.track(client, event)

  Import a batch of events into Mixpanel.

      client = %Mxpanel.Client{token: "mixpanel project token"}
      event_1 = Mxpanel.Event.new("signup", "123")
      event_2 = Mxpanel.Event.new("signup", "456")

      Mxpanel.track(client, [event_1, event_2])

  """
  # TODO how to support multiple events?
  # TODO move logic of event to here
  @spec track(Event.t()) :: Operation.t()
  def track(%Event{} = event) do
    payload = Event.serialize(event)

    %Operation{endpoint: :track, payload: payload}
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
  Enqueues the event. The event will be store in a buffer and sent in batches to mixpanel.

      Mxpanel.Batcher.start_link(name: MyApp.MxpanelBatcher, token: "mixpanel project token")
      event = Mxpanel.Event.new("signup", "123")

      Mxpanel.track_later(MyApp.MxpanelBatcher, event)


  ## Why use it?

  HTTP requests to the Mixpanel API often take time and may fail. If you are
  tracking events during a web request, you probably, don't want to make your
  users wait the extra time for the mixpanel API call to finish.

  Checkout `Mxpanel.Batcher` for more information.

  """
  # TODO update docs
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
