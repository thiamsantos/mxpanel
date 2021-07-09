defmodule Mxpanel.BatcherTest do
  use ExUnit.Case, async: false

  import Mox
  import ExUnit.CaptureLog
  alias Mxpanel.Batcher
  alias Mxpanel.Batcher.Manager
  alias Mxpanel.Operation
  alias Mxpanel.HTTPClientMock

  @one_year 86_400_000 * 365

  setup :verify_on_exit!
  setup :set_mox_global

  describe "start_link/1" do
    test "start batcher one buffer per scheduler per supported endpoint" do
      name = gen_name()
      assert {:ok, _pid} = Batcher.start_link(name: name, token: "token")

      track_buffers = Registry.lookup(Module.concat(name, "Registry"), :track)
      engage_buffers = Registry.lookup(Module.concat(name, "Registry"), :engage)
      groups_buffers = Registry.lookup(Module.concat(name, "Registry"), :groups)

      assert Enum.count(track_buffers) == System.schedulers_online()
      assert Enum.count(engage_buffers) == System.schedulers_online()
      assert Enum.count(groups_buffers) == System.schedulers_online()
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

    test "token optional when inactive" do
      assert {:ok, _} = Batcher.start_link(name: gen_name(), active: false)
    end

    test "supports token nil when active" do
      assert {:ok, _} = Batcher.start_link(name: gen_name(), token: nil, active: false)
    end

    test "token string when active" do
      assert_raise ArgumentError, ~r/expected :token to be a string, got: nil/, fn ->
        Batcher.start_link(name: gen_name(), token: nil, active: true)
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
        Batcher.enqueue(name, build_track_operation("signup", "#{i}"))
      end

      for i <- 1..40 do
        Batcher.enqueue(name, build_engage_operation("#{i}"))
      end

      for i <- 1..30 do
        Batcher.enqueue(name, build_groups_operation("Company", "#{i}"))
      end

      track_sizes =
        name
        |> Manager.buffers(:track)
        |> Enum.map(fn pid -> GenServer.call(pid, :get_buffer_size) end)

      engage_sizes =
        name
        |> Manager.buffers(:engage)
        |> Enum.map(fn pid -> GenServer.call(pid, :get_buffer_size) end)

      groups_sizes =
        name
        |> Manager.buffers(:groups)
        |> Enum.map(fn pid -> GenServer.call(pid, :get_buffer_size) end)

      assert track_sizes == [10, 10, 10, 10, 10]
      assert engage_sizes == [8, 8, 8, 8, 8]
      assert groups_sizes == [6, 6, 6, 6, 6]
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
         pool_size: 10,
         http_client: {HTTPClientMock, []}}
      )

      for i <- 1..200 do
        Batcher.enqueue(name, build_track_operation("signup", "#{i}"))
      end

      for i <- 1..200 do
        Batcher.enqueue(name, build_engage_operation("#{i}"))
      end

      for i <- 1..200 do
        Batcher.enqueue(name, build_groups_operation("Company", "#{i}"))
      end

      buffer_sizes = %{
        track: [20, 20, 20, 20, 20, 20, 20, 20, 20, 20],
        engage: [20, 20, 20, 20, 20, 20, 20, 20, 20, 20],
        groups: [20, 20, 20, 20, 20, 20, 20, 20, 20, 20]
      }

      assert_receive {:telemetry, [:mxpanel, :batcher, :buffers_info], %{},
                      %{
                        batcher_name: ^name,
                        buffer_sizes: ^buffer_sizes
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
        Batcher.enqueue(name, build_track_operation("signup", "#{i}"))
      end

      Batcher.drain_buffers(name)
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
         retry_base_backoff: 1,
         flush_interval: 100,
         flush_jitter: 100}
      )

      expect(HTTPClientMock, :request, 5, fn :post, _url, _headers, _body, _opts ->
        {:ok, %{body: "0", headers: [], status: 500}}
      end)

      Batcher.enqueue(name, build_track_operation("signup", "1"))

      Batcher.drain_buffers(name)
    end

    test "debug logs" do
      name = gen_name()

      start_supervised!(
        {Batcher,
         name: name,
         token: "token",
         pool_size: 1,
         telemetry_buffers_info_interval: 1,
         http_client: {HTTPClientMock, []},
         flush_interval: 100,
         flush_jitter: 100,
         debug: true}
      )

      stub(HTTPClientMock, :request, fn :post, _url, _headers, _body, _opts ->
        {:ok, %{body: "0", headers: [], status: 500}}
      end)

      logs =
        capture_log(fn ->
          Batcher.enqueue(name, build_track_operation("signup", "1"))

          Batcher.drain_buffers(name)
        end)

      assert logs =~
               "[debug] [mxpanel] [#{inspect(name)}] Attempt 1 to import batch of 1 operations"

      assert logs =~
               "[debug] [mxpanel] [#{inspect(name)}] Attempt 2 to import batch of 1 operations"

      assert logs =~
               "[debug] [mxpanel] [#{inspect(name)}] Attempt 3 to import batch of 1 operations"

      assert logs =~
               "[debug] [mxpanel] [#{inspect(name)}] Attempt 4 to import batch of 1 operations"

      assert logs =~
               "[debug] [mxpanel] [#{inspect(name)}] Attempt 5 to import batch of 1 operations"

      assert logs =~
               "[debug] [mxpanel] [#{inspect(name)}] Failed to import a batch of 1 operations after 5 attempts"
    end

    test "do not call api when inactive" do
      name = gen_name()

      start_supervised!(
        {Batcher,
         name: name,
         token: "token",
         pool_size: 1,
         telemetry_buffers_info_interval: 1,
         http_client: {HTTPClientMock, []},
         flush_interval: 1,
         flush_jitter: 1,
         active: false}
      )

      Batcher.enqueue(name, build_track_operation("signup", "1"))

      Batcher.drain_buffers(name)
    end

    test "publishes engage endpoint operations" do
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

      expect(HTTPClientMock, :request, 2, fn :post, url, headers, body, opts ->
        assert url == "https://api.mixpanel.com/engage"

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
        Batcher.enqueue(name, build_engage_operation("#{i}"))
      end

      Batcher.drain_buffers(name)
    end

    test "publishes groups endpoint operations" do
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

      expect(HTTPClientMock, :request, 2, fn :post, url, headers, body, opts ->
        assert url == "https://api.mixpanel.com/groups"

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
        Batcher.enqueue(name, build_groups_operation("Company", "#{i}"))
      end

      Batcher.drain_buffers(name)
    end
  end

  defp build_track_operation(event, distinct_id) do
    payload = %{
      "event" => event,
      "properties" => %{
        "$insert_id" => "insert_id",
        "distinct_id" => distinct_id,
        "time" => System.os_time(:second)
      }
    }

    %Operation{endpoint: :track, payload: payload}
  end

  defp build_engage_operation(distinct_id) do
    payload = %{
      "$distinct_id" => distinct_id,
      "$set" => %{
        "Address" => "1313 Mockingbird Lane"
      },
      "$time" => System.os_time(:second)
    }

    %Operation{endpoint: :engage, payload: payload}
  end

  defp build_groups_operation(group_id, group_key) do
    payload = %{
      "$group_id" => group_id,
      "$group_key" => group_key,
      "$set" => %{
        "Address" => "1313 Mockingbird Lane"
      },
      "$time" => System.os_time(:second)
    }

    %Operation{endpoint: :groups, payload: payload}
  end

  def gen_name do
    Module.concat(__MODULE__, "Batcher#{System.unique_integer([:positive, :monotonic])}")
  end
end
