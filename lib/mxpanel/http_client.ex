defmodule Mxpanel.HTTPClient do
  @moduledoc """
  Specifies the behaviour of a HTTP Client.

  You can switch the default HTTP client which uses [finch](https://github.com/keathley/finch) underneath
  by defining a different implementation by setting the `:http_client`
  configuration in `Mxpanel.Client`:

      client = %Mxpanel.Client{http_client: {MyCustomHTTPClient, []}, token: "token"}
      Mxpanel.track(client, Mxpanel.new("signup"))

  """

  @doc """
  Sends an HTTP request.
  """
  @callback request(
              method :: atom(),
              url :: binary(),
              headers :: list(),
              body :: iodata(),
              opts :: Keyword.t()
            ) ::
              {:ok, %{status: integer(), headers: [{binary(), binary()}], body: binary()}}
              | {:error, term()}

  if Code.ensure_loaded?(Finch) do
    def request(method, url, headers, body, opts) do
      {name, opts} = Keyword.pop!(opts, :name)

      method
      |> Finch.build(url, headers, body)
      |> Finch.request(name, opts)
      |> to_response()
    end

    defp to_response({:ok, response}) do
      {:ok, %{status: response.status, headers: response.headers, body: response.body}}
    end

    defp to_response({:error, reason}), do: {:error, reason}
  else
    def request(_, _, _, _, _) do
      raise ArgumentError, """
      Could not find finch dependency.

      Please add :finch to your dependencies:
          {:finch, "~> 0.5"}

      Or provide your own #{inspect(__MODULE__)} implementation:

          %Mxpanel.Client{http_client: {MyCustomHTTPClient, []}}
      """
    end
  end
end
