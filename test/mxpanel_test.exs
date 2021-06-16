defmodule MxpanelTest do
  use ExUnit.Case, async: true

  import Mxpanel.BufferHelpers
  alias Mxpanel.Batcher
  alias Mxpanel.Client
  alias Mxpanel.Event

  describe "track/2" do
    setup do
      bypass = Bypass.open()

      %{bypass: bypass}
    end

    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      event = Event.new("signup", "13793", %{"Favourite Color" => "Red"})

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert %{"data" => payload} = URI.decode_query(body)
        decoded_payload = Base.decode64!(payload)

        assert Jason.decode!(decoded_payload) == %{
                 "event" => "signup",
                 "properties" => %{
                   "$insert_id" => event.insert_id,
                   "Favourite Color" => "Red",
                   "distinct_id" => "13793",
                   "time" => event.time,
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

      assert Mxpanel.track(client, event) == :ok
    end

    test "failed request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      event = Event.new("signup", "13793", %{"Favourite Color" => "Red"})

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        Plug.Conn.resp(conn, 500, "Internal server error")
      end)

      assert {:error, %{body: "Internal server error", headers: _, status: 500}} =
               Mxpanel.track(client, event)
    end

    test "API down", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      event = Event.new("signup", "13793", %{"Favourite Color" => "Red"})

      Bypass.down(bypass)

      assert Mxpanel.track(client, event) == {:error, :econnrefused}
    end
  end

  describe "track_many/2" do
    setup do
      bypass = Bypass.open()

      %{bypass: bypass}
    end

    test "success request", %{bypass: bypass} do
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

      assert Mxpanel.track_many(client, [event_1, event_2]) == :ok
    end

    test "failed request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      event_1 = Event.new("signup", "1234")
      event_2 = Event.new("signup", "5679")

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        Plug.Conn.resp(conn, 500, "Internal server error")
      end)

      assert {:error, %{body: "Internal server error", headers: _, status: 500}} =
               Mxpanel.track_many(client, [event_1, event_2])
    end

    test "API down", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      event_1 = Event.new("signup", "1234")
      event_2 = Event.new("signup", "5679")

      Bypass.down(bypass)

      assert Mxpanel.track_many(client, [event_1, event_2]) ==
               {:error, :econnrefused}
    end
  end

  describe "track_later/2" do
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

      wait_for_drain(batcher_name)
    end
  end
end
