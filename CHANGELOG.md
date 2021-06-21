# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2021-06-21

### Changed

- `pool_size` options of `Mxpanel.Batcher` increased from `3` to `5`.
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

[Unreleased]: https://github.com/thiamsantos/mxpanel/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/thiamsantos/mxpanel/releases/tag/v0.2.0
[0.1.0]: https://github.com/thiamsantos/mxpanel/releases/tag/v0.1.0
