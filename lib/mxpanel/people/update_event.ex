defmodule Mxpanel.People.UpdateEvent do
  @moduledoc false

  defstruct [:time, :distinct_id, :operation, :properties, :modifiers]

  def shared_options_schema do
    [
      ip: [
        type: :string,
        doc: "IP address to get automatic geolocation info."
      ],
      ignore_time: [
        type: :boolean,
        doc:
          "Prevent the `$last_seen` property from incorrectly updating user profile properties with misleading timestamps in server-side Mixpanel implementations."
      ],
      time: [
        type: :pos_integer,
        doc: "Specific timestamp in seconds of the event. Defaults to `System.os_time(:second)`."
      ]
    ]
  end

  def delete_schema do
    [
      ignore_alias: [
        type: :boolean,
        doc: "If you have duplicate profiles, set `ignore_alias` to true so that you
      don't delete the original profile when trying to delete the duplicate."
      ]
    ]
  end

  def new(distinct_id, operation, properties, opts) do
    opts = validate_options!(operation, opts)

    %__MODULE__{
      distinct_id: distinct_id,
      operation: operation,
      properties: properties,
      time: Keyword.get(opts, :time, System.os_time(:second)),
      modifiers: build_modifiers(opts)
    }
  end

  def serialize(%__MODULE__{} = update, token) do
    Map.merge(
      %{
        "$token" => token,
        "$distinct_id" => update.distinct_id,
        "$time" => update.time,
        update.operation => update.properties
      },
      update.modifiers
    )
  end

  defp validate_options!(operation, opts) do
    case NimbleOptions.validate(opts, schema(operation)) do
      {:ok, options} ->
        options

      {:error, %NimbleOptions.ValidationError{message: message}} ->
        raise ArgumentError, message
    end
  end

  defp build_modifiers(opts) do
    opts
    |> Keyword.take([:ignore_time, :ignore_alias, :ip])
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new(fn {k, v} -> {"$#{k}", v} end)
  end

  defp schema("$delete"), do: Keyword.merge(shared_options_schema(), delete_schema())
  defp schema(_), do: shared_options_schema()
end
