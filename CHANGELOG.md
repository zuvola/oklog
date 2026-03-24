## 1.6.0
- Add PII support and demo URL functionality.

## 1.5.0
- `SlackErrorExporter`: replaced `extraPayload` with `payloadBuilder` (`Map<String, dynamic> Function()?`) for dynamic per-send payload merging.
- `SlackErrorExporter`: added `headersBuilder` (`Map<String, String> Function()?`) to inject dynamic HTTP headers on every send.
- `HttpErrorExporter`: renamed `payloadTransformer` to `payloadBuilder` for consistency.
- `HttpErrorExporter`: added `headersBuilder` (`Map<String, String> Function()?`) to merge dynamic headers alongside the default `Content-Type`.

## 1.4.0
- Refactor `SlackErrorExporter` to use http package for HTTP requests.
- Add `ErrorFormatter` and `HttpErrorExporter` for flexible error reporting.

## 1.3.0
- `ErrorAlertSink` accepts an optional `metadata` parameter (`Map<String, String>`) for attaching common information such as app name, version, and environment to every error report.
- `SlackErrorExporter` renders metadata as a context block beneath the error header in the Slack notification.

## 1.2.0
**This release contains breaking changes.** The API has been significantly redesigned.
Please refer to the [README](README.md) for updated usage.

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
