defmodule Mxpanel.Client do
  @moduledoc """
  Struct representing a Mxpanel Client.

  ## Default Usage

      %Mxpanel.Client{token: "project_token"}

  ## EU API

      %Mxpanel.Client{token: "project_token", base_url: "api-eu.mixpanel.com"}

  ## Custom HTTP client

      %Mxpanel.Client{token: "project_token", http_client: {MyCustomHTTPClient, []}}

  """
  defstruct token: nil,
            base_url: "https://api.mixpanel.com",
            http_client: {Mxpanel.HTTPClient, [name: Mxpanel.HTTPClient]}

  @type t :: %__MODULE__{
    token: String.t(),
    base_url: String.t(),
    http_client: {module(), Keyword.t()}
  }
end
