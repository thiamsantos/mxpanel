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
    {:mxpanel, "~> 0.3.0"},
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
event = Mxpanel.Event.new("signup", "billybob")
Mxpanel.track(client, event)

# track an event with optional properties
event = Mxpanel.Event.new("signup", "billybob", %{"Favourite Color" => "Red"})
Mxpanel.track(client, event)

# set an IP address to get automatic geolocation info
event = Mxpanel.Event.new("signup", "billybob", %{}, ip: "72.229.28.185")
Mxpanel.track(client, event)

# track an event with a specific timestamp
event = Mxpanel.Event.new("signup", "billybob", %{}, time: System.os_time(:second) - 60)
Mxpanel.track(client, event)

# track an event in background, the event will be buffered, and later sent in batches
Mxpanel.Batcher.start_link(name: MyApp.Batcher, token: "<mixpanel project token>")
event = Mxpanel.Event.new("signup", "billybob")
Mxpanel.track_later(MyApp.MxpanelBatcher, event)

# Create an alias for an existing distinct id
Mxpanel.create_alias(client, "distinct_id", "your_alias")

# create or update a user in Mixpanel Engage
properties = %{"Address" => "1313 Mockingbird Lane", "Birthday" => "1948-01-01"}
Mxpanel.People.set(client, "billybob", properties)

# create or update a user in Mixpanel Engage without altering $last_seen
Mxpanel.People.set(client, "billybob", %{plan: "premium"}, ignore_time: true)

# set a user profile's IP address to get automatic geolocation info
Mxpanel.People.set(client, "billybob", %{plan: "premium"}, ip: "72.229.28.185")

# set properties on a user, don't override
properties = %{"First login date" => "2013-04-01T13:20:00"}
Mxpanel.People.set_once(client, "billybob", properties)

# removes the properties
Mxpanel.People.unset(client, "billybob", ["Address", "Birthday"])

# increment a numeric property
Mxpanel.People.increment(client, "billybob", "Number of Logins", 12)

# append value to a list
Mxpanel.People.append_item(client, "billybob", "Items purchased", "socks")

# remove value from a list
Mxpanel.People.remove_item(client, "billybob", "Items purchased", "t-shirt")

# delete a user
Mxpanel.People.delete(client, "billybob")

```

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
