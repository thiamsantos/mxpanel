defmodule Mxpanel.BufferHelpers do
  def wait_for_drain(name, timeout \\ 20_000) do
    start_time = System.monotonic_time(:millisecond)

    do_wait_for_drain(name, timeout, start_time)
  end

  defp do_wait_for_drain(name, timeout, start_time) do
    buffer_size =
      name
      |> Module.concat("Registry")
      |> Registry.lookup(:buffers)
      |> Enum.map(fn {pid, _value} ->
        GenServer.call(pid, :get_buffer_size)
      end)
      |> Enum.sum()

    if buffer_size == 0 do
      :ok
    else
      now = System.monotonic_time(:millisecond)

      if now - start_time > timeout do
        raise ExUnit.TimeoutError, "took too long to dain queue"
      else
        Process.sleep(10)
        do_wait_for_drain(name, timeout, start_time)
      end
    end
  end
end
