defmodule Mxpanel.HTTPClient.HackneyAdapter do
  @moduledoc """
  Adapter for [hackney](https://github.com/benoitc/hackney).

  Remember to add `{:hackney, "~> 1.17"}` to dependencies. Also, you need to
  recompile mxpanel after adding the `:hackney` dependency:

  ```
  mix deps.clean mxpanel
  mix compile
  ```

  ## Usage

  %Mxpanel.Client{http_client: {Mxpanel.HTTPClient.HackneyAdapter, []}, token: "token"}

  """
  @behaviour Mxpanel.HTTPClient

  if Code.ensure_loaded?(:hackney) do
    @impl Mxpanel.HTTPClient
    def request(method, url, headers, body, opts) do
      method
      |> :hackney.request(url, headers, body, [:with_body | opts])
      |> to_response()
    end

    defp to_response({:ok, status, headers, body}) do
      {:ok, %{status: status, headers: headers, body: body}}
    end

    defp to_response({:error, reason}), do: {:error, reason}
  else
    @impl Mxpanel.HTTPClient
    def request(_, _, _, _, _) do
      raise ArgumentError, """
      Could not find hackney dependency.

      Please add :hackney to your dependencies:
        {:hackney, "~> 1.17"}

      """
    end
  end
end
