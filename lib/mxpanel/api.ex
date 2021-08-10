defmodule Mxpanel.API do
  @moduledoc false

  alias Mxpanel.Operation

  defmodule Request do
    defstruct [:client, :endpoint, :headers, :body]
  end

  def request(client, operation_or_operations) do
    %Request{client: client, body: operation_or_operations}
    |> find_endpoint()
    |> build_data()
    |> encode()
    |> execute()
  end

  defp find_endpoint(%Request{body: body} = request) do
    endpoints =
      body
      |> List.wrap()
      |> Enum.map(& &1.endpoint)
      |> Enum.uniq()

    first_endpoint = List.first(endpoints)

    unless Enum.all?(endpoints, fn e -> e == first_endpoint end) do
      raise ArgumentError,
            "expected all endpoints to be equal, got different endpoints: #{inspect(endpoints)}"
    end

    %{request | endpoint: first_endpoint}
  end

  defp build_data(%Request{body: body, client: client} = request) do
    %{request | body: serialize_operations(body, client)}
  end

  defp serialize_operations(operations, client) when is_list(operations) do
    Enum.map(operations, &serialize_operations(&1, client))
  end

  defp serialize_operations(%Operation{endpoint: :track, payload: payload}, _client) when is_map(payload) do
    payload
  end

  defp serialize_operations(%Operation{endpoint: :track, payload: payload}, client) when is_map(payload) do
    put_in(payload, ["properties", "token"], client.token)
  end

  defp serialize_operations(%Operation{endpoint: endpoint, payload: payload}, client)
       when endpoint in [:engage, :groups] and is_map(payload) do
    Map.put(payload, "$token", client.token)
  end

  defp encode(%Request{endpoint: :import, body: body} = request) do
    headers = [{"Accept", "application/json"}, {"Content-Type", "application/json"}, {"Content-Encoding", "gzip"}]

    encoded_body = body
    |> Mxpanel.json_library().encode!()
    |> :zlib.gzip()

    %{request | body: encoded_body, headers: headers}
  end

  defp encode(%Request{body: body} = request) do
    headers = [{"Accept", "text/plain"}, {"Content-Type", "application/x-www-form-urlencoded"}]

    encoded_data =
      body
      |> Mxpanel.json_library().encode!()
      |> Base.encode64()

    encoded_body = URI.encode_query(%{data: encoded_data})

    %{request | body: encoded_body, headers: headers}
  end

  defp execute(%Request{client: client, endpoint: endpoint, body: body, headers: headers}) do
    {http_mod, http_opts} = client.http_client

    path = case endpoint do
      :track -> "/track"
      :engage -> "/engage"
      :groups -> "/groups"
    end

    url = client.base_url |> URI.parse() |> Map.put(:path, path) |> URI.to_string()

    # when :import
    # ?strict=1&project_id=<YOUR_PROJECT_ID>

    case apply(http_mod, :request, [:post, url, headers, body, http_opts]) do
      {:ok, %{status: 200, body: "1"}} ->
        :ok

      {:ok, response} ->
        {:error, response}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
