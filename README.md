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
    {:mxpanel, "~> 0.4.0"},
    {:jason, "~> 1.2"},
    {:hackney, "~> 1.17"}
  ]
end
```

## Examples

```elixir
# Create a client struct with your project token
client = %Mxpanel.Client{token: "<mixpanel project token>"}

# track an event
"signup"
|> Mxpanel.track("billybob")
|> Mxpanel.deliver(client)

# track an event with optional properties
"signup"
|> Mxpanel.track("billybob", %{"Favourite Color" => "Red"})
|> Mxpanel.deliver(client)

# set an IP address to get automatic geolocation info
"signup"
|> Mxpanel.track("billybob", %{}, ip: "72.229.28.185")
|> Mxpanel.deliver(client)

# track an event with a specific timestamp
"signup"
|> Mxpanel.track("billybob", %{}, time: System.os_time(:second) - 60)
|> Mxpanel.deliver(client)

# track an event in background, the event will be buffered, and later sent in batches
Mxpanel.Batcher.start_link(name: MyApp.Batcher, token: "<mixpanel project token>")

"signup"
|> Mxpanel.track("billybob")
|> Mxpanel.deliver_later(MyApp.MxpanelBatcher)

```

[Checkout the documentation](https://hexdocs.pm/mxpanel) for complete usage and available functions.

## Telemetry

Mxpanel currently exposes following Telemetry events:

  * `[:mxpanel, :batcher, :buffers_info]` - Dispatched periodically by each
  running batcher exposing the size of each running buffer per endpoint in the pool.

    * Measurement: `%{}`
    * Metadata: `%{batcher_name: atom(), buffer_sizes: %{atom() => [integer()]}}`

## Changelog

See the [changelog](CHANGELOG.md).

<!-- MDOC !-->

## Contributing

See the [contributing file](CONTRIBUTING.md).


## License

Copyright 2021 (c) Thiago Santos.

Mxpanel source code is released under Apache 2 License.

Check [LICENSE](https://github.com/thiamsantos/mxpanel/blob/main/LICENSE) file for more information.
