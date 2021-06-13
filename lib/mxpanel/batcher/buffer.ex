defmodule Mxpanel.Batcher.Buffer do
  @moduledoc false

  use GenServer

  alias Mxpanel.Batcher.Manager
  alias Mxpanel.Client

  require Logger

  defmodule State do
    @moduledoc false

    defstruct [
      :events,
      :client,
      :flush_interval,
      :flush_jitter,
      :retry_max_attempts,
      :retry_base_backoff,
      :import_timeout,
      :buffer_size
    ]
  end

  @batch_size 50

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    batcher_name = opts[:name]
    client = %Client{token: opts[:token], base_url: opts[:base_url], http_client: opts[:http_client]}

    state = %State{
      events: [],
      buffer_size: 0,
      client: client,
      flush_interval: opts[:flush_interval],
      flush_jitter: opts[:flush_jitter],
      retry_max_attempts: opts[:retry_max_attempts],
      retry_base_backoff: opts[:retry_base_backoff],
      import_timeout: opts[:import_timeout]
    }

    Manager.register(batcher_name)

    {:ok, state, {:continue, :schedule_flush}}
  end

  def enqueue(pid, event) do
    GenServer.cast(pid, {:enqueue, event})
  end

  def get_buffer_size(pid) do
    GenServer.call(pid, :get_buffer_size)
  end

  def handle_continue(:schedule_flush, state) do
    schedule_flush(state)

    {:noreply, state}
  end

  def handle_call(:get_buffer_size, _from, state) do
    if Enum.count(state.events) != state.buffer_size do
      raise "size mismatch #{Enum.count(state.events)} != #{state.buffer_size}"
    end

    {:reply, state.buffer_size, state}
  end

  def handle_cast({:enqueue, event}, state) do
    {:noreply, %{state | events: [event | state.events], buffer_size: state.buffer_size + 1}}
  end

  def handle_info(:flush, state) do
    state.events
    |> Enum.chunk_every(@batch_size)
    |> Task.async_stream(
      fn batch ->
        track_many(state, batch)
      end,
      timeout: state.import_timeout
    )
    |> Stream.run()

    schedule_flush(state)

    {:noreply, %{state | events: [], buffer_size: 0}}
  end

  defp track_many(state, batch, attempts \\ 1) do
    case Mxpanel.track_many(state.client, batch) do
      :ok ->
        :ok

      {:error, _reason} ->
        if attempts >= state.retry_max_attempts do
          # TODO notify telemetry
          # TODO read telemetry best practices
          Logger.error(
            "[mxpanel] Failed to import a batch of events after #{state.retry_max_attempts} attempts"
          )

          :ok
        else
          sleep_time =
            attempts * state.retry_base_backoff + :rand.uniform(state.retry_base_backoff)

          Process.sleep(sleep_time)
          track_many(state, batch, attempts + 1)
        end
    end
  end

  defp schedule_flush(%State{flush_interval: flush_interval, flush_jitter: flush_jitter}) do
    jitter = :rand.uniform(flush_jitter)

    Process.send_after(self(), :flush, flush_interval + jitter)
  end
end
