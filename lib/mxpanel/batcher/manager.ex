defmodule Mxpanel.Batcher.Manager do
  @moduledoc false

  use GenServer

  alias Mxpanel.Batcher.Buffer

  @registry_key :buffers
  @counter_key :index

  defmodule State do
    @moduledoc false
    defstruct [:batcher_name, :telemetry_buffers_info_interval]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    batcher_name = opts[:name]
    telemetry_buffers_info_interval = opts[:telemetry_buffers_info_interval]

    :ets.new(table_name(batcher_name), [:public, :named_table])
    :ets.insert(table_name(batcher_name), {@counter_key, -1})

    state = %State{
      batcher_name: batcher_name,
      telemetry_buffers_info_interval: telemetry_buffers_info_interval
    }

    {:ok, state, {:continue, :schedule_buffers_info}}
  end

  def checkout(batcher_name) do
    buffers = Registry.lookup(registry_name(batcher_name), @registry_key)

    next_index =
      :ets.update_counter(
        table_name(batcher_name),
        @counter_key,
        {2, 1, Enum.count(buffers) - 1, 0}
      )

    {pid, _value} = Enum.at(buffers, next_index)
    pid
  end

  def register(batcher_name) do
    Registry.register(registry_name(batcher_name), @registry_key, nil)
  end

  def buffers(batcher_name) do
    batcher_name
    |> registry_name()
    |> Registry.lookup(@registry_key)
    |> Enum.map(fn {pid, _value} -> pid end)
  end

  def registry_name(batcher_name), do: Module.concat(batcher_name, "Registry")

  def handle_continue(:schedule_buffers_info, %State{} = state) do
    schedule_buffers_info(state.telemetry_buffers_info_interval)

    {:noreply, state}
  end

  def handle_info(:buffers_info, %State{} = state) do
    buffer_sizes =
      state.batcher_name
      |> registry_name()
      |> Registry.lookup(@registry_key)
      |> Enum.map(fn {pid, _value} ->
        Buffer.get_buffer_size(pid)
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
