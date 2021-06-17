defmodule Mxpanel.Batcher.Buffer do
  @moduledoc false

  use GenServer

  alias Mxpanel.Batcher.Manager
  alias Mxpanel.Batcher.Queue
  alias Mxpanel.Client

  require Logger

  defmodule State do
    @moduledoc false

    defstruct [
      :batcher_name,
      :events,
      :client,
      :flush_interval,
      :flush_jitter,
      :retry_max_attempts,
      :retry_base_backoff,
      :import_timeout,
      :debug
    ]
  end

  @batch_size 50

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    batcher_name = opts[:name]

    client = %Client{
      token: opts[:token],
      base_url: opts[:base_url],
      http_client: opts[:http_client]
    }

    state = %State{
      batcher_name: batcher_name,
      events: Queue.new(),
      client: client,
      flush_interval: opts[:flush_interval],
      flush_jitter: opts[:flush_jitter],
      retry_max_attempts: opts[:retry_max_attempts],
      retry_base_backoff: opts[:retry_base_backoff],
      import_timeout: opts[:import_timeout],
      debug: opts[:debug]
    }

    Manager.register(batcher_name)

    {:ok, state, {:continue, :schedule_flush}}
  end

  def enqueue(pid, event_or_events) do
    GenServer.cast(pid, {:enqueue, event_or_events})
  end

  def get_buffer_size(pid) do
    GenServer.call(pid, :get_buffer_size)
  end

  def handle_continue(:schedule_flush, state) do
    schedule_flush(state)

    {:noreply, state}
  end

  def handle_call(:get_buffer_size, _from, state) do
    {:reply, state.events.size, state}
  end

  def handle_cast({:enqueue, event_or_events}, state) do
    {:noreply, %{state | events: Queue.add(state.events, event_or_events)}}
  end

  def handle_info(:flush, state) do
    state.events
    |> Queue.to_list()
    |> Enum.chunk_every(@batch_size)
    |> Task.async_stream(
      fn batch ->
        track_many(state, batch)
      end,
      timeout: state.import_timeout
    )
    |> Stream.run()

    schedule_flush(state)

    {:noreply, %{state | events: Queue.new()}}
  end

  defp track_many(state, batch, attempts \\ 1) do
    if state.debug == true do
      Logger.debug(
        "[mxpanel] [#{inspect(state.batcher_name)}] Attempt #{attempts} to import batch of #{Enum.count(batch)} events"
      )
    end

    case Mxpanel.track(state.client, batch) do
      :ok ->
        :ok

      {:error, _reason} ->
        if attempts >= state.retry_max_attempts do
          if state.debug == true do
            Logger.debug(
              "[mxpanel] [#{inspect(state.batcher_name)}] Failed to import a batch " <>
                "of #{Enum.count(batch)} events after #{state.retry_max_attempts} attempts"
            )
          end

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
