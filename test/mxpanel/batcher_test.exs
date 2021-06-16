defmodule Mxpanel.BatcherTest do
  use ExUnit.Case, async: true

  import Mox
  import ExUnit.CaptureLog
  import Mxpanel.BufferHelpers
  alias Mxpanel.Batcher
  alias Mxpanel.Event
  alias Mxpanel.HTTPClientMock

  @one_year 86_400_000 * 365

  setup :verify_on_exit!

  describe "start_link/1" do
    test "start batcher" do
      name = gen_name()
      assert {:ok, _pid} = Batcher.start_link(name: name, token: "token")

      buffers = Registry.lookup(Module.concat(name, "Registry"), :buffers)
      assert Enum.count(buffers) == 10
    end

    test "required name" do
      assert_raise ArgumentError, ~r/required option :name not found/, fn ->
        Batcher.start_link(token: "token")
      end
    end

    test "required token" do
      assert_raise ArgumentError, ~r/required option :token not found/, fn ->
        Batcher.start_link(name: gen_name())
      end
    end

    test "invalid http_client" do
      assert_raise ArgumentError,
                   ~r/expected :http_client to be an {mod, opts} tuple, got: :invalid/,
                   fn ->
                     Batcher.start_link(name: gen_name(), token: "token", http_client: :invalid)
                   end
    end
  end

  describe "enqueue/2" do
    test "enqueue event in round robin" do
      name = gen_name()

      start_supervised!(
        {Batcher,
         name: name,
         token: "token",
         pool_size: 5,
         flush_interval: @one_year,
         http_client: {HTTPClientMock, []}}
      )

      for i <- 1..50 do
        Batcher.enqueue(name, Event.new("signup", "#{i}"))
      end

      buffer_sizes =
        name
        |> Module.concat("Registry")
        |> Registry.lookup(:buffers)
        |> Enum.map(fn {pid, _value} ->
          GenServer.call(pid, :get_buffer_size)
        end)

      assert buffer_sizes == [10, 10, 10, 10, 10]
    end
  end

  describe "telemetry" do
    setup context do
      pid = self()
      handler_id = {context.module, context.test}

      :telemetry.attach(
        handler_id,
        [:mxpanel, :batcher, :buffers_info],
        fn event, measurements, metadata, config ->
          send(pid, {:telemetry, event, measurements, metadata, config})
        end,
        nil
      )

      on_exit(fn ->
        :telemetry.detach(handler_id)
      end)
    end

    test "publishes [:mxpanel, :batcher, :buffers_info]" do
      name = gen_name()

      start_supervised!(
        {Batcher,
         name: name,
         token: "token",
         telemetry_buffers_info_interval: 1,
         flush_interval: @one_year,
         http_client: {HTTPClientMock, []}}
      )

      for i <- 1..200 do
        Batcher.enqueue(name, Event.new("signup", "#{i}"))
      end

      assert_receive {:telemetry, [:mxpanel, :batcher, :buffers_info], %{},
                      %{
                        batcher_name: ^name,
                        buffer_sizes: [20, 20, 20, 20, 20, 20, 20, 20, 20, 20]
                      }, _config}
    end
  end

  describe "flush" do
    test "group messages batches of 50" do
      name = gen_name()

      start_supervised!(
        {Batcher,
         name: name,
         token: "token",
         pool_size: 1,
         telemetry_buffers_info_interval: 1,
         http_client: {HTTPClientMock, []},
         flush_interval: 100,
         flush_jitter: 100}
      )

      name
      |> Module.concat("Registry")
      |> Registry.lookup(:buffers)
      |> Enum.map(fn {pid, _value} ->
        allow(HTTPClientMock, self(), pid)
      end)

      expect(HTTPClientMock, :request, 2, fn :post, url, headers, body, opts ->
        assert url == "https://api.mixpanel.com/track"

        assert headers == [
                 {"Accept", "text/plain"},
                 {"Content-Type", "application/x-www-form-urlencoded"}
               ]

        assert opts == []

        events =
          body
          |> URI.decode_query()
          |> Map.fetch!("data")
          |> Base.decode64!()
          |> Jason.decode!()

        assert Enum.count(events) == 50

        {:ok, %{body: "1", headers: [], status: 200}}
      end)

      for i <- 1..100 do
        Batcher.enqueue(name, Event.new("signup", "#{i}"))
      end

      wait_for_drain(name)
    end

    test "retries" do
      name = gen_name()

      start_supervised!(
        {Batcher,
         name: name,
         token: "token",
         pool_size: 1,
         telemetry_buffers_info_interval: 1,
         http_client: {HTTPClientMock, []},
         flush_interval: 100,
         flush_jitter: 100}
      )

      name
      |> Module.concat("Registry")
      |> Registry.lookup(:buffers)
      |> Enum.map(fn {pid, _value} ->
        allow(HTTPClientMock, self(), pid)
      end)

      expect(HTTPClientMock, :request, 3, fn :post, _url, _headers, _body, _opts ->
        {:ok, %{body: "0", headers: [], status: 500}}
      end)

      assert capture_log(fn ->
               Batcher.enqueue(name, Event.new("signup", "1"))

               wait_for_drain(name)
             end) =~ "[mxpanel] Failed to import a batch of events after 3 attempts"
    end
  end

  def gen_name do
    Module.concat(__MODULE__, "Batcher#{System.unique_integer([:positive, :monotonic])}")
  end
end
