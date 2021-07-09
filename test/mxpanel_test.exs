defmodule MxpanelTest do
  use ExUnit.Case, async: true

  alias Mxpanel.Batcher
  alias Mxpanel.Client
  alias Mxpanel.Operation

  describe "track/2" do
    test "build operation" do
      operation = Mxpanel.track("signup", "13793")

      assert operation.endpoint == :track

      assert operation.payload["event"] == "signup"
      assert operation.payload["properties"]["distinct_id"] == "13793"

      assert String.length(operation.payload["properties"]["$insert_id"]) == 43
      assert is_integer(operation.payload["properties"]["time"])
      assert Map.has_key?(operation.payload["properties"], "ip") == false
    end

    test "additional properties" do
      operation = Mxpanel.track("signup", "13793", %{"Favourite Color" => "Red"})

      assert operation.payload["event"] == "signup"
      assert operation.payload["properties"]["distinct_id"] == "13793"
      assert operation.payload["properties"]["Favourite Color"] == "Red"
    end

    test "custom time" do
      time = 1234

      operation = Mxpanel.track("signup", "13793", %{}, time: time)
      assert operation.payload["properties"]["time"] == time
    end

    test "custom ip" do
      operation = Mxpanel.track("signup", "13793", %{}, ip: "123.123.123.123")

      assert operation.payload["properties"]["ip"] == "123.123.123.123"
    end

    test "invalid time" do
      message = "expected :time to be a positive integer, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        Mxpanel.track("signup", "13793", %{}, time: :invalid)
      end
    end

    test "invalid ip" do
      message = "expected :ip to be a string, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        Mxpanel.track("signup", "13793", %{}, ip: :invalid)
      end
    end
  end

  describe "create_alias/2" do
    test "build operation" do
      operation = Mxpanel.create_alias("other_distinct_id", "your_id")

      assert operation.endpoint == :track

      assert operation.payload == %{
               "event" => "$create_alias",
               "properties" => %{
                 "distinct_id" => "other_distinct_id",
                 "alias" => "your_id"
               }
             }
    end
  end

  describe "deliver_later/2" do
    setup do
      bypass = Bypass.open()

      batcher_name =
        Module.concat(__MODULE__, "Batcher#{System.unique_integer([:positive, :monotonic])}")

      token = "project_token"

      start_supervised!(
        {Batcher,
         name: batcher_name,
         token: token,
         base_url: "http://localhost:#{bypass.port}",
         pool_size: 1,
         flush_interval: 1_000,
         flush_jitter: 1_000}
      )

      %{bypass: bypass, batcher_name: batcher_name, token: token}
    end

    test "track in background", %{
      bypass: bypass,
      batcher_name: batcher_name,
      token: token
    } do
      time = System.os_time(:second)

      payload = %{
        "event" => "signup",
        "properties" => %{
          "$insert_id" => "insert_id",
          "distinct_id" => "1234",
          "time" => time
        }
      }

      operation = %Operation{endpoint: :track, payload: payload}

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = payload |> Base.decode64!() |> Jason.decode!()

        assert decoded_payload == [
                 %{
                   "event" => "signup",
                   "properties" => %{
                     "$insert_id" => "insert_id",
                     "distinct_id" => "1234",
                     "time" => time,
                     "token" => token
                   }
                 }
               ]

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Mxpanel.deliver_later(operation, batcher_name) == :ok

      Batcher.drain_buffers(batcher_name)
    end

    test "engage in background", %{
      bypass: bypass,
      batcher_name: batcher_name,
      token: token
    } do
      time = System.os_time(:second)

      payload = %{
        "$distinct_id" => "123",
        "$set" => %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"},
        "$time" => time
      }

      operation = %Operation{endpoint: :engage, payload: payload}

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = payload |> Base.decode64!() |> Jason.decode!()

        assert decoded_payload == [
                 %{
                   "$distinct_id" => "123",
                   "$set" => %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"},
                   "$time" => time,
                   "$token" => token
                 }
               ]

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Mxpanel.deliver_later(operation, batcher_name) == :ok
      Batcher.drain_buffers(batcher_name)
    end

    test "groups in background", %{
      bypass: bypass,
      batcher_name: batcher_name,
      token: token
    } do
      time = System.os_time(:second)

      payload = %{
        "$group_id" => "Mixpanel",
        "$group_key" => "Company",
        "$set" => %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"},
        "$time" => time
      }

      operation = %Operation{endpoint: :groups, payload: payload}

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = payload |> Base.decode64!() |> Jason.decode!()

        assert decoded_payload == [
                 %{
                   "$group_id" => "Mixpanel",
                   "$group_key" => "Company",
                   "$set" => %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"},
                   "$time" => time,
                   "$token" => token
                 }
               ]

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Mxpanel.deliver_later(operation, batcher_name) == :ok
      Batcher.drain_buffers(batcher_name)
    end

    test "multiple events", %{
      bypass: bypass,
      batcher_name: batcher_name,
      token: token
    } do
      time_1 = System.os_time(:second)
      time_2 = System.os_time(:second)

      payload_1 = %{
        "event" => "signup",
        "properties" => %{
          "$insert_id" => "insert_id_1",
          "distinct_id" => "1234",
          "time" => time_1
        }
      }

      payload_2 = %{
        "event" => "signup",
        "properties" => %{
          "$insert_id" => "insert_id_2",
          "distinct_id" => "5678",
          "time" => time_2
        }
      }

      operation_1 = %Operation{endpoint: :track, payload: payload_1}
      operation_2 = %Operation{endpoint: :track, payload: payload_2}

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = payload |> Base.decode64!() |> Jason.decode!()

        assert decoded_payload == [
                 %{
                   "event" => "signup",
                   "properties" => %{
                     "$insert_id" => "insert_id_1",
                     "distinct_id" => "1234",
                     "time" => time_1,
                     "token" => token
                   }
                 },
                 %{
                   "event" => "signup",
                   "properties" => %{
                     "$insert_id" => "insert_id_2",
                     "distinct_id" => "5678",
                     "time" => time_2,
                     "token" => token
                   }
                 }
               ]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Mxpanel.deliver_later([operation_1, operation_2], batcher_name) == :ok

      Batcher.drain_buffers(batcher_name)
    end
  end

  describe "deliver/2" do
    setup do
      bypass = Bypass.open()

      %{bypass: bypass}
    end

    test "track", %{bypass: bypass} do
      time = System.os_time(:second)

      payload = %{
        "event" => "signup",
        "properties" => %{
          "$insert_id" => "insert_id",
          "distinct_id" => "1234",
          "time" => time
        }
      }

      operation = %Operation{endpoint: :track, payload: payload}
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = payload |> Base.decode64!() |> Jason.decode!()

        assert decoded_payload == %{
                 "event" => "signup",
                 "properties" => %{
                   "$insert_id" => "insert_id",
                   "distinct_id" => "1234",
                   "time" => time,
                   "token" => "project_token"
                 }
               }

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Mxpanel.deliver(operation, client) == :ok
    end

    test "engage", %{bypass: bypass} do
      time = System.os_time(:second)

      payload = %{
        "$distinct_id" => "123",
        "$set" => %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"},
        "$time" => time
      }

      operation = %Operation{endpoint: :engage, payload: payload}
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = payload |> Base.decode64!() |> Jason.decode!()

        assert decoded_payload == %{
                 "$distinct_id" => "123",
                 "$set" => %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"},
                 "$time" => time,
                 "$token" => "project_token"
               }

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Mxpanel.deliver(operation, client) == :ok
    end

    test "groups", %{bypass: bypass} do
      time = System.os_time(:second)

      payload = %{
        "$group_id" => "Mixpanel",
        "$group_key" => "Company",
        "$set" => %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"},
        "$time" => time
      }

      operation = %Operation{endpoint: :groups, payload: payload}
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = payload |> Base.decode64!() |> Jason.decode!()

        assert decoded_payload == %{
                 "$group_id" => "Mixpanel",
                 "$group_key" => "Company",
                 "$set" => %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"},
                 "$time" => time,
                 "$token" => "project_token"
               }

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Mxpanel.deliver(operation, client) == :ok
    end

    test "multiple operations", %{bypass: bypass} do
      time_1 = System.os_time(:second)
      time_2 = System.os_time(:second)

      payload_1 = %{
        "event" => "signup",
        "properties" => %{
          "$insert_id" => "insert_id_1",
          "distinct_id" => "1234",
          "time" => time_1
        }
      }

      payload_2 = %{
        "event" => "signup",
        "properties" => %{
          "$insert_id" => "insert_id_2",
          "distinct_id" => "5678",
          "time" => time_2
        }
      }

      operation_1 = %Operation{endpoint: :track, payload: payload_1}
      operation_2 = %Operation{endpoint: :track, payload: payload_2}
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = payload |> Base.decode64!() |> Jason.decode!()

        assert decoded_payload == [
                 %{
                   "event" => "signup",
                   "properties" => %{
                     "$insert_id" => "insert_id_1",
                     "distinct_id" => "1234",
                     "time" => time_1,
                     "token" => "project_token"
                   }
                 },
                 %{
                   "event" => "signup",
                   "properties" => %{
                     "$insert_id" => "insert_id_2",
                     "distinct_id" => "5678",
                     "time" => time_2,
                     "token" => "project_token"
                   }
                 }
               ]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Mxpanel.deliver([operation_1, operation_2], client) == :ok
    end

    test "fails when operations are for different endpoints" do
      operation_1 = %Operation{endpoint: :track, payload: %{}}
      operation_2 = %Operation{endpoint: :engage, payload: %{}}
      client = %Client{}

      message = "expected all endpoints to be equal, got different endpoints: [:track, :engage]"

      assert_raise ArgumentError, message, fn ->
        Mxpanel.deliver([operation_1, operation_2], client)
      end
    end

    test "do nothing when there is no operations" do
      assert Mxpanel.deliver([], %Client{}) == :ok
    end
  end
end
