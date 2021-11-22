defmodule Mxpanel.API do
  @moduledoc false

  def request(client, endpoint, data) do
    encoded_data =
      data
      |> Mxpanel.json_library().encode!()
      |> Base.encode64()

    {http_mod, http_opts} = client.http_client

    url = client.base_url |> URI.parse() |> Map.put(:path, endpoint) |> URI.to_string()
    headers = [{"Accept", "text/plain"}, {"Content-Type", "application/x-www-form-urlencoded"}]
    encoded_body = URI.encode_query(%{data: encoded_data})

    case http_mod.request(:post, url, headers, encoded_body, http_opts) do
      {:ok, %{status: 200, body: "1"}} ->
        :ok

      {:ok, response} ->
        {:error, response}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
