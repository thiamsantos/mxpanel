defmodule Mxpanel do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias Mxpanel.Batcher
  alias Mxpanel.Client
  alias Mxpanel.Event

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
  @spec track(Client.t(), Event.t() | [Event.t()]) :: :ok | {:error, term()}
  def track(%Client{} = client, event_or_events) do
    data =
      event_or_events
      |> List.wrap()
      |> Enum.map(&Event.serialize(&1, client.token))
      |> json_library().encode!()
      |> Base.encode64()

    track_request(client, %{data: data})
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
  @spec track_later(Batcher.name(), Event.t() | [Event.t()]) :: :ok
  def track_later(batcher_name, event_or_events) when is_atom(batcher_name) do
    Batcher.enqueue(batcher_name, event_or_events)
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

  defp track_request(client, body) do
    {http_mod, http_opts} = client.http_client

    url = client.base_url |> URI.parse() |> Map.put(:path, "/track") |> URI.to_string()
    headers = [{"Accept", "text/plain"}, {"Content-Type", "application/x-www-form-urlencoded"}]
    encoded_body = URI.encode_query(body)

    case apply(http_mod, :request, [:post, url, headers, encoded_body, http_opts]) do
      {:ok, %{status: 200, body: "1"}} ->
        :ok

      {:ok, response} ->
        {:error, response}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
