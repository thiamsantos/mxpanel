defmodule Mxpanel.HTTPClient.HackneyAdapterTest do
  use ExUnit.Case, async: true

  alias Mxpanel.HTTPClient.HackneyAdapter

  describe "request/4" do
    setup do
      bypass = Bypass.open()

      %{bypass: bypass}
    end

    test "success request", %{bypass: bypass} do
      url = "http://localhost:#{bypass.port}/track"
      headers = [{"Content-Type", "application/json"}]
      body = Jason.encode!(%{data: "payload"})

      Bypass.expect_once(bypass, "POST", "/track", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        assert Jason.decode!(body) == %{"data" => "payload"}
        assert Plug.Conn.get_req_header(conn, "content-type") == ["application/json"]

        conn
        |> Plug.Conn.put_resp_header("content-type", "text/plain")
        |> Plug.Conn.resp(200, "1")
      end)

      assert {:ok, result} = HackneyAdapter.request(:post, url, headers, body, [])

      assert result.body == "1"
      assert result.status == 200
      assert get_header(result.headers, "content-type") == ["text/plain"]
    end

    test "error request", %{bypass: bypass} do
      url = "http://localhost:#{bypass.port}/track"
      headers = [{"Content-Type", "application/json"}]
      body = Jason.encode!(%{data: "payload"})

      Bypass.down(bypass)

      assert HackneyAdapter.request(:post, url, headers, body, []) == {:error, :econnrefused}
    end
  end

  defp get_header(headers, key) do
    for {^key, value} <- headers, do: value
  end
end
