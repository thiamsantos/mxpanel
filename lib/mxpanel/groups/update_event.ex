defmodule Mxpanel.Groups.UpdateEvent do
  @moduledoc false

  defstruct [:time, :group_key, :group_id, :operation, :properties]

  def schema do
    [
      time: [
        type: :pos_integer,
        doc: "Specific timestamp in seconds of the event. Defaults to `System.os_time(:second)`."
      ]
    ]
  end

  def new(group_key, group_id, operation, properties, opts) do
    opts = validate_options!(opts)

    %__MODULE__{
      group_key: group_key,
      group_id: group_id,
      operation: operation,
      properties: properties,
      time: Keyword.get(opts, :time, System.os_time(:second))
    }
  end

  def serialize(%__MODULE__{} = update, token) do
    %{
      "$token" => token,
      "$group_key" => update.group_key,
      "$group_id" => update.group_id,
      "$time" => update.time,
      update.operation => update.properties
    }
  end

  defp validate_options!(opts) do
    case NimbleOptions.validate(opts, schema()) do
      {:ok, options} ->
        options

      {:error, %NimbleOptions.ValidationError{message: message}} ->
        raise ArgumentError, message
    end
  end
end
