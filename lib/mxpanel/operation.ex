defmodule Mxpanel.Operation do
  @moduledoc """
  An operation to run on mixpanel.
  """
  defstruct [:endpoint, :payload]

  @type t :: %__MODULE__{
          endpoint: :track | :engage | :groups,
          payload: map()
        }
end
