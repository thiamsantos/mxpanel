defmodule Mxpanel.HTTPClient do
  @moduledoc """
  Specifies the behaviour of a HTTP Client.
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
end
