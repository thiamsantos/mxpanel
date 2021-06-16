# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- `pool_size` options of `Mxpanel.Batcher` increased from `3` to `5`.

### Added

- `debug` option to `Mxpanel.Batcher`.

### Removed

- `finch` `Mxpanel.HTTPClient` adapter.

## [0.1.0] - 2021-06-16

### Added

- `Mxpanel.track/2`.
- `Mxpanel.track_many/2`.
- `Mxpanel.track_later/2`.

[Unreleased]: https://github.com/thiamsantos/mxpanel/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/thiamsantos/mxpanel/releases/tag/v0.1.0
