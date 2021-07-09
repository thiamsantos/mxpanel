defmodule Mxpanel.Batcher do
  @moduledoc """
  Manages a pool of buffers that accumulate the events and sends them to the
  Mixpanel API in batches in background. It implements a registry-based routing
  pool with round-robing as routing strategy.

  Checkout `start_link/1` for all supported options.

  ## Usage

  1. Add to your supervision tree:

  ```elixir
  {Mxpanel.Batcher, name: MyApp.Batcher, token: "mixpanel project token"}
  ```

  2. Enqueue an event:

  ```elixir
  Mxpanel.track_later(MyApp.MxpanelBatcher, event)
  ```

  3. The event will be buffered, and later sent in batch to the Mixpanel API.

  """
  use Supervisor

  alias Mxpanel.Batcher.Buffer
  alias Mxpanel.Batcher.Manager

  @type name :: atom()

  @opts_schema [
    name: [
      type: :atom,
      doc: "Name of the batcher instance.",
      required: true
    ],
    token: [
      type: :any,
      doc: "Required if active. The Mixpanel token associated with your project."
    ],
    active: [
      type: :boolean,
      doc:
        "Configure Batcher to be active or not. Useful for disabling requests in certain environments.",
      default: true
    ],
    base_url: [
      type: :string,
      doc: "Mixpanel API URL.",
      default: "https://api.mixpanel.com"
    ],
    http_client: [
      type: {:custom, __MODULE__, :validate_http_client, []},
      doc: "HTTP client used by the Batcher.",
      default: {Mxpanel.HTTPClient.HackneyAdapter, []}
    ],
    pool_size: [
      type: :pos_integer,
      doc: "The size of the pool of event buffers. Defaults to `System.schedulers_online()`."
    ],
    flush_interval: [
      type: :pos_integer,
      doc: "Interval in milliseconds which the event buffer are processed.",
      default: 5_000
    ],
    flush_jitter: [
      type: :pos_integer,
      doc:
        "Jitter the flush interval by a random amount. Value in milliseconds. This is primarily to avoid large write spikes. For example, a `flush_jitter` of 1s and `flush_interval` of 1s means flushes will happen every 5-6s.",
      default: 1_000
    ],
    retry_max_attempts: [
      type: :pos_integer,
      doc: "Max attempts that a batch of events should be tried before giving up.",
      default: 5
    ],
    retry_base_backoff: [
      type: :pos_integer,
      doc:
        "Base time in milliseconds to calculate the wait time between retry attempts. Formula: `(attempt * retry_base_backoff) + random(1..retry_base_backoff)`.",
      default: 100
    ],
    import_timeout: [
      type: :timeout,
      doc:
        "The maximum amount of time in milliseconds each batch of events is allowed to execute for.",
      default: 30_000
    ],
    telemetry_buffers_info_interval: [
      type: :pos_integer,
      doc: "Interval in milliseconds the `telemetry` with the buffers info is published.",
      default: 30_000
    ],
    debug: [
      type: :boolean,
      doc: "Enable debug logging.",
      default: false
    ]
  ]

  @supported_endpoints [:track, :engage, :groups]

  @doc """
  Starts a `#{inspect(__MODULE__)}` linked to the current process.

  ## Supported options

  #{NimbleOptions.docs(@opts_schema)}
  """
  def start_link(opts) do
    opts = validate_options!(opts, @opts_schema)

    Supervisor.start_link(__MODULE__, opts)
  end

  @impl Supervisor
  def init(opts) do
    name = opts[:name]
    pool_size = opts[:pool_size]

    buffers_specs =
      @supported_endpoints
      |> Enum.flat_map(fn endpoint ->
        for index <- 1..pool_size do
          Supervisor.child_spec({Buffer, Keyword.put(opts, :endpoint, endpoint)},
            id: {Buffer, endpoint, index}
          )
        end
      end)

    children = [
      {Registry, name: Manager.registry_name(name), keys: :duplicate},
      {Manager, Keyword.put(opts, :supported_endpoints, @supported_endpoints)},
      %{
        id: :buffers_supervisor,
        type: :supervisor,
        start: {Supervisor, :start_link, [buffers_specs, [strategy: :one_for_one]]}
      }
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  @doc """
  Synchronously drain all buffers in the batcher.
  Returns a list containing all the processed events.

      Mxpanel.Batcher.drain_buffers(MyApp.Batcher)

  """
  @spec drain_buffers(name()) :: :ok
  def drain_buffers(batcher_name) do
    Enum.each(@supported_endpoints, fn endpoint ->
      batcher_name
      |> Manager.buffers(endpoint)
      |> Enum.each(fn pid -> GenServer.call(pid, :drain) end)
    end)
  end

  @doc false
  def enqueue(batcher_name, operation_or_operations) do
    operation_or_operations
    |> List.wrap()
    |> Enum.each(fn operation ->
      batcher_name
      |> Manager.checkout(operation)
      |> Buffer.enqueue(operation)
    end)
  end

  @doc false
  def validate_http_client({mod, opts}) when is_atom(mod) and is_list(opts) do
    {:ok, {mod, opts}}
  end

  def validate_http_client(value) do
    {:error, "expected :http_client to be an {mod, opts} tuple, got: #{inspect(value)}"}
  end

  defp validate_options!(opts, schema) do
    opts = Keyword.put_new(opts, :pool_size, System.schedulers_online())

    with {:ok, opts} <- NimbleOptions.validate(opts, schema),
         {:ok, opts} <- validate_token(opts) do
      opts
    else
      {:error, %NimbleOptions.ValidationError{message: message}} ->
        raise ArgumentError,
              "invalid configuration given to #{inspect(__MODULE__)}.start_link/1, " <> message
    end
  end

  defp validate_token(opts) do
    case {opts[:active] == true, Keyword.has_key?(opts, :token), is_binary(opts[:token])} do
      {true, true, true} ->
        {:ok, opts}

      {true, true, false} ->
        {:error,
         %NimbleOptions.ValidationError{
           message: "expected :token to be a string, got: #{inspect(opts[:token])}"
         }}

      {true, false, _} ->
        {:error, %NimbleOptions.ValidationError{message: "required option :token not found"}}

      {false, _, _} ->
        {:ok, opts}
    end
  end
end
