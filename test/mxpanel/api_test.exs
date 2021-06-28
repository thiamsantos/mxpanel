defmodule Mxpanel.APITest do
  use ExUnit.Case, async: true

  alias Mxpanel.API
  alias Mxpanel.Client

  setup do
    bypass = Bypass.open()

    %{bypass: bypass}
  end

  test "success request", %{bypass: bypass} do
    client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

    Bypass.expect_once(bypass, "POST", "/track", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert %{"data" => payload} = URI.decode_query(body)
      decoded_payload = Base.decode64!(payload)

      assert Jason.decode!(decoded_payload) == %{
               "event" => "signup"
             }

      assert Plug.Conn.get_req_header(conn, "content-type") == [
               "application/x-www-form-urlencoded"
             ]

      assert Plug.Conn.get_req_header(conn, "accept") == ["text/plain"]

      conn
      |> Plug.Conn.put_resp_header("content-type", "text/plain")
      |> Plug.Conn.resp(200, "1")
    end)

    assert API.request(client, "/track", %{"event" => "signup"}) == :ok
  end

  test "failed request", %{bypass: bypass} do
    client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

    Bypass.expect_once(bypass, "POST", "/track", fn conn ->
      Plug.Conn.resp(conn, 500, "Internal server error")
    end)

    assert {:error, %{body: "Internal server error", headers: _, status: 500}} =
             API.request(client, "/track", %{"event" => "signup"})
  end

  test "API down", %{bypass: bypass} do
    client = %Client{base_url: "http://localhost:#{bypass.port}", token: "project_token"}

    Bypass.down(bypass)

    assert API.request(client, "/track", %{"event" => "signup"}) == {:error, :econnrefused}
  end
end
