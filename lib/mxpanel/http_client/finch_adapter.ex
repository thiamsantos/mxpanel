defmodule Mxpanel.HTTPClient.FinchAdapter do
  @moduledoc """
  Adapter for [finch](https://github.com/keathley/finch).

  Remember to add `{:finch, "~> 0.5"}` to dependencies. Also, you need to
  recompile mxpanel after adding the `:finch` dependency:

  ```
  mix deps.clean mxpanel
  mix compile
  ```

  ## Usage

  1. Add to your supervision tree:

  ```elixir
  {Finch, name: Mxpanel.HTTPClient}
  ```

  2. Finch is already the default adapter:

  ```elixir
  %Mxpanel.Client{token: "token"}
  ```

  """
  @behaviour Mxpanel.HTTPClient

  if Code.ensure_loaded?(Finch) do
    @impl Mxpanel.HTTPClient
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
    @impl Mxpanel.HTTPClient
    def request(_, _, _, _, _) do
      raise ArgumentError, """
      Could not find finch dependency.

      Please add :finch to your dependencies:
          {:finch, "~> 0.5"}

      """
    end
  end
end
