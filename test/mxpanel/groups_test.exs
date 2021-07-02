defmodule Mxpanel.GroupsTest do
  use ExUnit.Case, async: true

  alias Mxpanel.Client
  alias Mxpanel.Groups

  setup do
    bypass = Bypass.open()

    %{bypass: bypass}
  end

  describe "set/5" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      properties = %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$group_key"] == "Company"
        assert decoded_payload["$group_id"] == "Mixpanel"
        assert decoded_payload["$set"] == properties
        assert is_integer(decoded_payload["$time"])

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Groups.set(client, "Company", "Mixpanel", properties) == :ok
    end

    test "custom time", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      properties = %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Groups.set(client, "Company", "Mixpanel", properties, time: time) == :ok
    end

    test "invalid time" do
      message = "expected :time to be a positive integer, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        Groups.set(%Client{}, "Company", "Mixpanel", %{}, time: :invalid)
      end
    end
  end

  describe "set_once/5" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      properties = %{"First login date" => "2013-04-01T13:20:00"}

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$group_key"] == "Company"
        assert decoded_payload["$group_id"] == "Mixpanel"
        assert decoded_payload["$set_once"] == properties
        assert is_integer(decoded_payload["$time"])

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Groups.set_once(client, "Company", "Mixpanel", properties) == :ok
    end

    test "custom time", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      properties = %{"First login date" => "2013-04-01T13:20:00"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Groups.set_once(client, "Company", "Mixpanel", properties, time: time) == :ok
    end
  end

  describe "union/5" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      properties = %{"Items purchased" => ["socks", "shirts"], "Browser" => "ie"}

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$group_key"] == "Company"
        assert decoded_payload["$group_id"] == "Mixpanel"
        assert decoded_payload["$union"] == properties
        assert is_integer(decoded_payload["$time"])

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Groups.union(client, "Company", "Mixpanel", properties) == :ok
    end

    test "custom time", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      properties = %{"Items purchased" => ["socks", "shirts"], "Browser" => "ie"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Groups.union(client, "Company", "Mixpanel", properties, time: time) == :ok
    end
  end

  describe "unset/5" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$group_key"] == "Company"
        assert decoded_payload["$group_id"] == "Mixpanel"
        assert decoded_payload["$unset"] == ["Days Overdue"]
        assert is_integer(decoded_payload["$time"])

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Groups.unset(client, "Company", "Mixpanel", ["Days Overdue"]) == :ok
    end

    test "custom time", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Groups.unset(client, "Company", "Mixpanel", ["Days Overdue"], time: time) == :ok
    end
  end

  describe "remove_item/6" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$group_key"] == "Company"
        assert decoded_payload["$group_id"] == "Mixpanel"
        assert decoded_payload["$remove"] == %{"Items purchased" => "socks"}
        assert is_integer(decoded_payload["$time"])

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Groups.remove_item(client, "Company", "Mixpanel", "Items purchased", "socks") == :ok
    end

    test "custom time", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Groups.remove_item(client, "Company", "Mixpanel", "Items purchased", "socks",
               time: time
             ) == :ok
    end
  end

  # describe "union/4" do
  #   test "success request", %{bypass: bypass} do

  #   end
  # end

  describe "delete/4" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$group_key"] == "Company"
        assert decoded_payload["$group_id"] == "Mixpanel"
        assert decoded_payload["$delete"] == ""
        assert is_integer(decoded_payload["$time"])

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Groups.delete(client, "Company", "Mixpanel") == :ok
    end

    test "custom time", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/groups", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert Groups.delete(client, "Company", "Mixpanel", time: time) == :ok
    end
  end

  defp decode_body(conn) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)

    assert %{"data" => payload} = URI.decode_query(body)
    payload |> Base.decode64!() |> Jason.decode!()
  end
end
