defmodule Mxpanel.Batcher.Queue do
  @moduledoc false

  defstruct [:items, :size]

  def new do
    %__MODULE__{items: [], size: 0}
  end

  def to_list(%__MODULE__{} = queue) do
    Enum.reverse(queue.items)
  end

  def add(%__MODULE__{} = queue, items) when is_list(items) do
    Enum.reduce(items, queue, fn item, acc -> add(acc, item) end)
  end

  def add(%__MODULE__{} = queue, item) do
    %{queue | items: [item | queue.items], size: queue.size + 1}
  end
end
