defmodule Mxpanel.Client do
  @moduledoc """
  Struct representing a Mxpanel Client.

  ## Default Usage

      %Mxpanel.Client{token: "project_token"}

  ## EU API

      %Mxpanel.Client{token: "project_token", base_url: "api-eu.mixpanel.com"}

  ## Custom HTTP client

  You can switch the default HTTP client which uses [finch](https://github.com/keathley/finch) underneath
  by defining a different implementation by setting the `:http_client` option:

      %Mxpanel.Client{http_client: {MyCustomHTTPClient, []}, token: "token"}

  """
  defstruct token: nil,
            base_url: "https://api.mixpanel.com",
            http_client: {Mxpanel.HTTPClient.FinchAdapter, [name: Mxpanel.HTTPClient]}

  @type t :: %__MODULE__{
          token: String.t(),
          base_url: String.t(),
          http_client: {module(), Keyword.t()}
        }
end
