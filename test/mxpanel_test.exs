defmodule MxpanelTest do
  use ExUnit.Case, async: true

  alias Mxpanel.Batcher
  alias Mxpanel.Client
  alias Mxpanel.Event

  setup do
    bypass = Bypass.open()

    %{bypass: bypass}
  end

  describe "track/2" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      event = Event.new("signup", "13793", %{"Favourite Color" => "Red"})

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = Base.decode64!(payload)

        assert Jason.decode!(decoded_payload) == [
                 %{
                   "event" => "signup",
                   "properties" => %{
                     "$insert_id" => event.insert_id,
                     "Favourite Color" => "Red",
                     "distinct_id" => "13793",
                     "time" => event.time,
                     "token" => "project_token"
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

      assert Mxpanel.track(client, event) == :ok
    end

    test "multiple events", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      event_1 = Event.new("signup", "1234")
      event_2 = Event.new("signup", "5678")

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = Base.decode64!(payload)

        assert Jason.decode!(decoded_payload) == [
                 %{
                   "event" => "signup",
                   "properties" => %{
                     "$insert_id" => event_1.insert_id,
                     "distinct_id" => "1234",
                     "time" => event_1.time,
                     "token" => "project_token"
                   }
                 },
                 %{
                   "event" => "signup",
                   "properties" => %{
                     "$insert_id" => event_2.insert_id,
                     "distinct_id" => "5678",
                     "time" => event_2.time,
                     "token" => "project_token"
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

      assert Mxpanel.track(client, [event_1, event_2]) == :ok
    end
  end

  describe "track_later/2" do
    setup %{bypass: bypass} do
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

      %{batcher_name: batcher_name, token: token}
    end

    test "deliver in background event", %{
      bypass: bypass,
      batcher_name: batcher_name,
      token: token
    } do
      event = Event.new("signup", "13793", %{"Favourite Color" => "Red"})

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = Base.decode64!(payload)

        assert Jason.decode!(decoded_payload) == [
                 %{
                   "event" => "signup",
                   "properties" => %{
                     "$insert_id" => event.insert_id,
                     "Favourite Color" => "Red",
                     "distinct_id" => "13793",
                     "time" => event.time,
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

      assert Mxpanel.track_later(batcher_name, event) == :ok

      Batcher.drain_buffers(batcher_name)
    end

    test "multiple events", %{
      bypass: bypass,
      batcher_name: batcher_name,
      token: token
    } do
      event_1 = Event.new("signup", "1234")
      event_2 = Event.new("signup", "5678")

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = Base.decode64!(payload)

        assert Jason.decode!(decoded_payload) == [
                 %{
                   "event" => "signup",
                   "properties" => %{
                     "$insert_id" => event_1.insert_id,
                     "distinct_id" => "1234",
                     "time" => event_1.time,
                     "token" => token
                   }
                 },
                 %{
                   "event" => "signup",
                   "properties" => %{
                     "$insert_id" => event_2.insert_id,
                     "distinct_id" => "5678",
                     "time" => event_2.time,
                     "token" => token
                   }
                 }
               ]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Mxpanel.track_later(batcher_name, [event_1, event_2]) == :ok

      Batcher.drain_buffers(batcher_name)
    end
  end

  describe "create_alias/3" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = Base.decode64!(payload)

        assert Jason.decode!(decoded_payload) == %{
                 "event" => "$create_alias",
                 "properties" => %{
                   "distinct_id" => "other_distinct_id",
                   "alias" => "your_id",
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

      assert Mxpanel.create_alias(client, "other_distinct_id", "your_id") == :ok
    end
  end
end
