defmodule Mxpanel.PeopleTest do
  use ExUnit.Case, async: true

  alias Mxpanel.Client
  alias Mxpanel.People

  setup do
    bypass = Bypass.open()

    %{bypass: bypass}
  end

  # TODO simplify tests to validate on operation

  describe "set/3" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      properties = %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$distinct_id"] == "123"
        assert decoded_payload["$set"] == properties
        assert is_integer(decoded_payload["$time"])

        assert Map.has_key?(decoded_payload, "$ignore_time") == false
        assert Map.has_key?(decoded_payload, "$ip") == false

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.set(properties)
             |> Mxpanel.deliver(client) == :ok
    end

    test "accept options", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      properties = %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time
        assert decoded_payload["$ip"] == "123.123.123.123"
        assert decoded_payload["$ignore_time"] == true

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.set(properties,
               time: time,
               ip: "123.123.123.123",
               ignore_time: true
             )
             |> Mxpanel.deliver(client) == :ok
    end

    test "invalid time" do
      message = "expected :time to be a positive integer, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        People.set("123", %{}, time: :invalid)
      end
    end

    test "invalid ip" do
      message = "expected :ip to be a string, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        People.set("123", %{}, ip: :invalid)
      end
    end

    test "invalid ignore_time" do
      message = "expected :ignore_time to be a boolean, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        People.set("123", %{}, ignore_time: :invalid)
      end
    end
  end

  describe "unset/3" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$distinct_id"] == "123"
        assert decoded_payload["$unset"] == ["Days Overdue"]
        assert is_integer(decoded_payload["$time"])

        assert Map.has_key?(decoded_payload, "$ignore_time") == false
        assert Map.has_key?(decoded_payload, "$ip") == false

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.unset(["Days Overdue"])
             |> Mxpanel.deliver(client) == :ok
    end

    test "accepts options", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time
        assert decoded_payload["$ignore_time"] == true
        assert decoded_payload["$ip"] == "123.123.123.123"

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.unset(["Days Overdue"],
               time: time,
               ip: "123.123.123.123",
               ignore_time: true
             )
             |> Mxpanel.deliver(client) == :ok
    end
  end

  describe "set_once/3" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      properties = %{"First login date" => "2013-04-01T13:20:00"}

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$distinct_id"] == "123"
        assert decoded_payload["$set_once"] == properties
        assert is_integer(decoded_payload["$time"])

        assert Map.has_key?(decoded_payload, "$ignore_time") == false
        assert Map.has_key?(decoded_payload, "$ip") == false

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.set_once(properties)
             |> Mxpanel.deliver(client) == :ok
    end

    test "accepts options", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      properties = %{"First login date" => "2013-04-01T13:20:00"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time
        assert decoded_payload["$ignore_time"] == true
        assert decoded_payload["$ip"] == "123.123.123.123"

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.set_once(properties,
               time: time,
               ip: "123.123.123.123",
               ignore_time: true
             )
             |> Mxpanel.deliver(client) == :ok
    end
  end

  describe "increment/4" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$distinct_id"] == "123"
        assert decoded_payload["$add"] == %{"Coins Gathered" => 12}
        assert is_integer(decoded_payload["$time"])

        assert Map.has_key?(decoded_payload, "$ignore_time") == false
        assert Map.has_key?(decoded_payload, "$ip") == false

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.increment("Coins Gathered", 12)
             |> Mxpanel.deliver(client) == :ok
    end

    test "accepts options", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time
        assert decoded_payload["$ignore_time"] == true
        assert decoded_payload["$ip"] == "123.123.123.123"

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.increment("Coins Gathered", 12,
               time: time,
               ip: "123.123.123.123",
               ignore_time: true
             )
             |> Mxpanel.deliver(client) == :ok
    end
  end

  describe "append_item/4" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$distinct_id"] == "123"
        assert decoded_payload["$append"] == %{"Power Ups" => "Bubble Lead"}
        assert is_integer(decoded_payload["$time"])

        assert Map.has_key?(decoded_payload, "$ignore_time") == false
        assert Map.has_key?(decoded_payload, "$ip") == false

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.append_item("Power Ups", "Bubble Lead")
             |> Mxpanel.deliver(client) == :ok
    end

    test "accepts options", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time
        assert decoded_payload["$ignore_time"] == true
        assert decoded_payload["$ip"] == "123.123.123.123"

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.append_item("Power Ups", "Bubble Lead",
               time: time,
               ip: "123.123.123.123",
               ignore_time: true
             )
             |> Mxpanel.deliver(client) == :ok
    end
  end

  describe "remove_item/4" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$distinct_id"] == "123"
        assert decoded_payload["$remove"] == %{"Items purchased" => "socks"}
        assert is_integer(decoded_payload["$time"])

        assert Map.has_key?(decoded_payload, "$ignore_time") == false
        assert Map.has_key?(decoded_payload, "$ip") == false

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.remove_item("Items purchased", "socks")
             |> Mxpanel.deliver(client) == :ok
    end

    test "accepts options", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time
        assert decoded_payload["$ignore_time"] == true
        assert decoded_payload["$ip"] == "123.123.123.123"

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.remove_item("Items purchased", "socks",
               time: time,
               ip: "123.123.123.123",
               ignore_time: true
             )
             |> Mxpanel.deliver(client) == :ok
    end
  end

  describe "delete/2" do
    test "success request", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$token"] == "project_token"
        assert decoded_payload["$distinct_id"] == "123"
        assert decoded_payload["$delete"] == ""
        assert is_integer(decoded_payload["$time"])

        assert Map.has_key?(decoded_payload, "$ignore_time") == false
        assert Map.has_key?(decoded_payload, "$ip") == false
        assert Map.has_key?(decoded_payload, "$ignore_alias") == false

        assert Plug.Conn.get_req_header(conn, "content-type") == [
                 "application/x-www-form-urlencoded"
               ]

        assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.delete()
             |> Mxpanel.deliver(client) == :ok
    end

    test "accept options", %{bypass: bypass} do
      client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}
      time = System.os_time(:second)

      Bypass.expect_once(bypass, "POST", "/engage", fn conn ->
        decoded_payload = decode_body(conn)

        assert decoded_payload["$time"] == time
        assert decoded_payload["$ignore_time"] == true
        assert decoded_payload["$ip"] == "123.123.123.123"
        assert decoded_payload["$ignore_alias"] == true

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert "123"
             |> People.delete(
               time: time,
               ignore_time: true,
               ip: "123.123.123.123",
               ignore_alias: true
             )
             |> Mxpanel.deliver(client) == :ok
    end

    test "invalid ignore_alias" do
      message = "expected :ignore_alias to be a boolean, got: :invalid"

      assert_raise ArgumentError, message, fn ->
        People.delete("123", ignore_alias: :invalid)
      end
    end
  end

  defp decode_body(conn) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)

    assert %{"data" => payload} = URI.decode_query(body)
    payload |> Base.decode64!() |> Jason.decode!()
  end
end
