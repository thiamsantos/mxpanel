# Mxpanel

<!-- MDOC !-->

Client for Mixpanel Ingestion API.

[![Hex.pm Version](http://img.shields.io/hexpm/v/mxpanel.svg?style=flat)](https://hex.pm/packages/mxpanel)
[![CI](https://github.com/thiamsantos/mxpanel/workflows/CI/badge.svg?branch=main)](https://github.com/thiamsantos/mxpanel/actions?query=branch%3Amain)
[![Coverage Status](https://coveralls.io/repos/github/thiamsantos/mxpanel/badge.svg?branch=main)](https://coveralls.io/github/thiamsantos/mxpanel?branch=main)

It provides a sync API that makes HTTP request to the Mixpanel API. And also a
async API that buffers and delivers the buffered events to Mixpanel in background.

[Checkout the documentation](https://hexdocs.pm/mxpanel) for more information.

## Installation

The package can be installed by adding `mxpanel` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mxpanel, "~> 0.1.0"},
    {:jason, "~> 1.2"},
    {:finch, "~> 0.5"}
  ]
end
```

## Usage

### Track event

1. Add to your supervision tree:

```elixir
{Finch, name: Mxpanel.HTTPClient}
```

2. Call `track/2`:

```elixir
client = %Mxpanel.Client{token: "mixpanel project token"}
event = Mxpanel.Event.new("signup", "123")

Mxpanel.track(client, event)
```

### Enqueue an event

1. Add to your supervision tree:

```elixir
{Finch, name: Mxpanel.HTTPClient},
{Mxpanel.Batcher, name: MyApp.Batcher, token: "mixpanel project token"}
```

2. Call `track_later/2`:

```elixir
event = Mxpanel.Event.new("signup", "123")

Mxpanel.track_later(MyApp.MxpanelBatcher, event)
```

3. The event will be buffered, and later sent in batch to the Mixpanel API.

## Telemetry

Mxpanel currently exposes following Telemetry events:

  * `[:mxpanel, :batcher, :buffers_info]` - Dispatched periodically by each
  running batcher exposing the size of each running buffer in the pool.

    * Measurement: `%{}`
    * Metadata: `%{batcher_name: atom(), buffer_sizes: [integer()]}`

## Changelog

See the [changelog](CHANGELOG.md).

<!-- MDOC !-->

## Contributing

See the [contributing file](CONTRIBUTING.md).


## License

Copyright 2021 (c) Thiago Santos.

Mxpanel source code is released under Apache 2 License.

Check [LICENSE](https://github.com/thiamsantos/mxpanel/blob/main/LICENSE) file for more information.
