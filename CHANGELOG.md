# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2021-07-09

### Added

- `Mxpanel.Operation` struct. This struct holds all the information necessary
to one API operation. It can be delivered alone or grouped in batches.
- `Mxpanel.deliver/2` function.
- `Mxpanel.deliver_later/2` function.

### Changed

- All functions were updated to build a `Mxpanel.Operation` instead of
making a API request directly. The generated operation can be piped to
`Mxpanel.deliver/2` or `Mxpanel.deliver_later/2` to provide a single interface
for delivering information to Mixpanel API. This allow all operations to be batched.
- Default `:pool_size` for `Mxpanel.Batcher` changed from `10` to `System.schedulers_online()`.
- Buffers info telemetry event metadata changed to return the buffer sizes by supported endpoint.

### Removed

- `Mxpanel.Event` struct. Now the build of the event can be made directly
in the `Mxpanel.track/4` function.
- `Mxpanel.track_later/2`. Superseded by `Mxpanel.deliver_later/2`

## [0.4.0] - 2021-07-02

### Added

- `Mxpanel.Groups.delete/4`
- `Mxpanel.Groups.remove_item/6`
- `Mxpanel.Groups.set/5`
- `Mxpanel.Groups.set_once/5`
- `Mxpanel.Groups.union/5`
- `Mxpanel.Groups.unset/5`

## [0.3.0] - 2021-06-28

### Added

- Examples section to readme.
- `Mxpanel.create_alias/3`.
- `Mxpanel.People.append_item/5`.
- `Mxpanel.People.delete/3`.
- `Mxpanel.People.increment/5`.
- `Mxpanel.People.remove_item/5`.
- `Mxpanel.People.set/4`.
- `Mxpanel.People.set_once/4`.
- `Mxpanel.People.unset/4`.

## Changed

- Support custom `:ip` and `:time` for track events.
- Simplify issue template.
- Improve `:token` validation, to allow `nil` values when inactive.

## [0.2.0] - 2021-06-21

### Changed

- `retry_max_attempts` options of `Mxpanel.Batcher` increased from `3` to `5`.
- Support batch of events in `Mxpanel.track/2` and `Mxpanel.track_later/2`.

### Added

- `Mxpanel.Batcher.drain_buffers/1`.
- `active` option to `Mxpanel.Batcher`.
- `debug` option to `Mxpanel.Batcher`.

### Removed

- `finch` `Mxpanel.HTTPClient` adapter.
- `Mxpanel.track_many/2`.

## [0.1.0] - 2021-06-16

### Added

- `Mxpanel.track/2`.
- `Mxpanel.track_many/2`.
- `Mxpanel.track_later/2`.

[Unreleased]: https://github.com/thiamsantos/mxpanel/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/thiamsantos/mxpanel/releases/tag/v1.0.0
[0.4.0]: https://github.com/thiamsantos/mxpanel/releases/tag/v0.4.0
[0.3.0]: https://github.com/thiamsantos/mxpanel/releases/tag/v0.3.0
[0.2.0]: https://github.com/thiamsantos/mxpanel/releases/tag/v0.2.0
[0.1.0]: https://github.com/thiamsantos/mxpanel/releases/tag/v0.1.0
