## 1.1.0
- Added `notice` log level between `info` and `warn`.
- Added `log.obs.event` for logging structured observability events.
- Added `log.obs.metric` for logging numeric observability metrics.
- `Logger` is no longer abstract — instantiate it directly and attach sinks.
- Renamed `ConsoleLogger` to `DefaultLogger`.
- Removed `DummyLogger`; use `log.sinks.clear()` to silence output.
- Global `log` variable is now `final`.

## 1.0.0
- Initial version.
