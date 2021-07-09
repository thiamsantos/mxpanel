defmodule Mxpanel.Batcher.Manager do
  @moduledoc false

  use GenServer

  alias Mxpanel.Batcher.Buffer

  defmodule State do
    @moduledoc false
    defstruct [:batcher_name, :telemetry_buffers_info_interval, :supported_endpoints]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    batcher_name = opts[:name]
    telemetry_buffers_info_interval = opts[:telemetry_buffers_info_interval]
    supported_endpoints = opts[:supported_endpoints]

    :ets.new(table_name(batcher_name), [:public, :named_table])

    for endpoint <- supported_endpoints do
      :ets.insert(table_name(batcher_name), {endpoint, -1})
    end

    state = %State{
      batcher_name: batcher_name,
      telemetry_buffers_info_interval: telemetry_buffers_info_interval,
      supported_endpoints: supported_endpoints
    }

    {:ok, state, {:continue, :schedule_buffers_info}}
  end

  def checkout(batcher_name, operation) do
    buffers = buffers(batcher_name, operation.endpoint)

    next_index =
      :ets.update_counter(
        table_name(batcher_name),
        operation.endpoint,
        {2, 1, Enum.count(buffers) - 1, 0}
      )

    Enum.at(buffers, next_index)
  end

  def register(batcher_name, endpoint) do
    Registry.register(registry_name(batcher_name), endpoint, nil)
  end

  def buffers(batcher_name, key) do
    batcher_name
    |> registry_name()
    |> Registry.lookup(key)
    |> Enum.map(fn {pid, _} -> pid end)
  end

  def registry_name(batcher_name), do: Module.concat(batcher_name, "Registry")

  def handle_continue(:schedule_buffers_info, %State{} = state) do
    schedule_buffers_info(state.telemetry_buffers_info_interval)

    {:noreply, state}
  end

  def handle_info(:buffers_info, %State{} = state) do
    buffer_sizes =
      Map.new(state.supported_endpoints, fn endpoint ->
        sizes =
          state.batcher_name
          |> registry_name()
          |> Registry.lookup(endpoint)
          |> Enum.map(fn {pid, _value} ->
            Buffer.get_buffer_size(pid)
          end)

        {endpoint, sizes}
      end)

    :telemetry.execute(
      [:mxpanel, :batcher, :buffers_info],
      %{},
      %{batcher_name: state.batcher_name, buffer_sizes: buffer_sizes}
    )

    schedule_buffers_info(state.telemetry_buffers_info_interval)

    {:noreply, state}
  end

  defp schedule_buffers_info(interval) do
    Process.send_after(self(), :buffers_info, interval)
  end

  defp table_name(batcher_name), do: Module.concat(batcher_name, "Batcher.Manager")
end
