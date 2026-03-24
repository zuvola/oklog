# oklog

[![pub package](https://img.shields.io/pub/v/oklog.svg)](https://pub.dartlang.org/packages/oklog)

A simple yet capable logging utility for Dart and Flutter. Just log. ok.

## Features

- Six log levels: `trace`, `debug`, `info`, `notice`, `warn`, `error`
- Colored, emoji-decorated console output via `ConsoleSink` and `ConsoleFormatter`
- Filter logs by level via `LevelFilterProcessor` and by class name via `NameFilterProcessor`
- Extensible pipeline: add `LogProcessor` instances to transform/filter, and `LogSink` instances to route output
- Global `log` instance (`OkLogger`) ready to use out of the box
- Observability support: structured events and metrics via `log.obs`
- Error alerting with context: `ContextBufferProcessor` + `ErrorAlertSink` + `ErrorExporter`; composable HTTP transport via `HttpErrorExporter` + `ErrorFormatter`
- Slack integration: `SlackPayloadFormatter` and `SlackErrorExporter` available via `package:oklog/oklog_slack.dart`
- PII (Personally Identifiable Information) support: mark sensitive values with `pii()` at the call site; each sink handles masking independently

## Getting started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  oklog: ^1.1.0
```

Then import the library:

```dart
import 'package:oklog/oklog.dart';
```

For Slack integration, add the additional import:

```dart
import 'package:oklog/oklog_slack.dart';
```

## Usage

### Basic logging

```dart
import 'package:oklog/oklog.dart';

void main() {
  log.level = LogLevel.trace; // show all levels

  log.trace('main', 'Trace message');
  log.debug('main', 'Debug message');
  log.info('main', 'Info message');
  log.notice('main', 'Notice message');
  log.warn('main', 'Warning message');

  try {
    throw Exception('Something went wrong!');
  } catch (e, st) {
    log.error('main', 'An error occurred.', error: e, stackTrace: st);
  }
}
```

### Using with a class instance

Pass `this` as the first argument and the class name is resolved automatically:

```dart
class MyClass {
  void myMethod() {
    log.info(this, 'Hello from MyClass');
  }
}
```

### Attaching structured attributes

All log methods accept an optional `attrs` map for structured key-value metadata:

```dart
log.debug(this, 'User action', attrs: {'userId': 123, 'action': 'login'});
```

### PII (Personally Identifiable Information)

Wrap sensitive values with `pii()` to mark them as personally identifiable
information. Each sink decides independently how to handle `PiiValue` entries:

- **`ConsoleSink`** — reveals the raw value (safe for local development).
- **`ErrorAlertSink`** — replaces every `PiiValue` with `[REDACTED]` before
  forwarding to the `ErrorExporter`, so sensitive data never leaves the device
  in error reports.

```dart
log.info(
  this,
  'login',
  attrs: {
    'email': pii(email),       // PII — masked in error exports
    'session_id': sessionId,   // non-PII — forwarded as-is
  },
);
```

`Logger` itself is PII-agnostic. Masking is a per-sink concern, so you can add
your own custom sinks that call `maskPiiAttrs(entry.attrs)` (or ignore `PiiValue`
entirely) depending on the destination.

### Filtering by class name

Use `log.nameFilter` (a `NameFilterProcessor`) to restrict which classes are logged:

```dart
// Only log messages from classes whose name contains 'main'
log.nameFilter.allowList = ['main'];

// Suppress log messages from classes whose name contains 'MyClass'
log.nameFilter.denyList = ['MyClass'];

// Clear filters
log.nameFilter.allowList = [];
log.nameFilter.denyList = [];
```

### Silencing output

```dart
log.sinks.clear(); // remove all sinks to suppress output
```

### Changing the log level

```dart
log.level = LogLevel.warn; // only warn and error are printed
```

### Custom sinks

Implement `LogSink` and override `emit` to route entries anywhere:

```dart
class FileSink extends LogSink {
  @override
  void emit(LogEntry entry) {
    if (entry is LogRecord) {
      // write to a file, remote service, etc.
    }
  }
}

log.sinks.add(FileSink());
```

Multiple sinks can be active at the same time. The built-in `ConsoleSink` is
added automatically by `OkLogger`.

### Custom formatters

`ConsoleSink` accepts a `LogFormatter<String>` that converts a `LogEntry` to a
string. Replace the default `ConsoleFormatter` to change how entries are rendered
without touching sink behaviour:

```dart
class JsonFormatter extends LogFormatter<String> {
  @override
  String format(LogEntry entry) {
    if (entry is LogRecord) {
      return jsonEncode({
        'level': entry.level.name,
        'class': entry.className,
        'message': entry.message,
      });
    }
    return entry.toString();
  }
}

log.sinks
  ..clear()
  ..add(ConsoleSink(formatter: JsonFormatter()));
```

### Custom processors

Implement `LogProcessor` and return `false` to drop an entry from the pipeline:

```dart
class SamplingProcessor implements LogProcessor {
  @override
  bool process(LogEntry entry) => Random().nextDouble() > 0.9; // keep 10%
}

log.processors.add(SamplingProcessor());
```

### Error alerting with context

`ContextBufferProcessor` keeps a ring buffer of recent `LogRecord` entries.
`ErrorAlertSink` detects error-level records and forwards them — together with
that buffer — to an `ErrorExporter`, giving the recipient rich context about
what happened before the error.

#### SlackErrorExporter

`SlackErrorExporter` is available via `package:oklog/oklog_slack.dart`.
It sends a formatted [Block Kit](https://api.slack.com/block-kit)
message to a Slack channel via an [Incoming Webhook](https://api.slack.com/messaging/webhooks).
The notification includes the error message, error object, stack trace, and the
recent context logs captured by `ContextBufferProcessor`.

```dart
import 'package:oklog/oklog.dart';
import 'package:oklog/oklog_slack.dart';

final buffer = ContextBufferProcessor();
final exporter = SlackErrorExporter(
  'https://hooks.slack.com/services/YOUR/WEBHOOK/URL',
);

log.processors.add(buffer);
log.sinks.add(
  ErrorAlertSink(
    buffer,
    exporter,
    metadata: {
      'app': 'MyApp',
      'version': '1.0.0',
      'env': 'production',
    },
  ),
);

log.info('main', 'Application started.');
log.warn('main', 'Cache miss — fetching from origin.');
try {
  throw Exception('Database connection failed');
} catch (e, st) {
  // Sends a Slack message that includes the error plus the info/warn above.
  log.error('main', 'Unhandled error.', error: e, stackTrace: st);
}
```

Use `payloadBuilder` to merge dynamic top-level fields into the payload on
every send, or `headersBuilder` to inject dynamic HTTP headers (e.g. auth
tokens, routing keys) when going through a proxy:

```dart
final exporter = SlackErrorExporter(
  'https://proxy.example.com/slack',
  payloadBuilder: () => {
    'channel': '#alerts',
    'username': 'ErrorBot',
  },
  headersBuilder: () => {
    'Authorization': 'Bearer ${tokenProvider.current}',
    'X-Routing-Key': 'my-service',
  },
);
```

#### HttpErrorExporter + custom ErrorFormatter

`HttpErrorExporter` is a generic HTTP transport that accepts any `ErrorFormatter`
implementation. Use it to send structured payloads to any webhook-based service
without duplicating transport logic.

An optional `payloadBuilder` callback lets you merge extra fields or reshape
the payload before delivery without subclassing. An optional `headersBuilder`
callback lets you inject dynamic HTTP headers (e.g. auth tokens) on every send:

```dart
final exporter = HttpErrorExporter(
  'https://discord.com/api/webhooks/YOUR/WEBHOOK',
  DiscordFormatter(),
  payloadBuilder: (payload) => {...payload, 'username': 'ErrorBot'},
  headersBuilder: () => {'Authorization': 'Bearer $token'},
);
```

Implement `ErrorFormatter` to control the request body:

```dart
class DiscordFormatter implements ErrorFormatter {
  @override
  Map<String, dynamic> format(
    LogRecord error,
    List<LogRecord> contextLogs,
    Map<String, String> metadata,
  ) {
    return {
      'content': '**${error.className}**: ${error.message}',
    };
  }
}

final exporter = HttpErrorExporter(
  'https://discord.com/api/webhooks/YOUR/WEBHOOK',
  DiscordFormatter(),
);

final buffer = ContextBufferProcessor();
log.processors.add(buffer);
log.sinks.add(
  ErrorAlertSink(
    buffer,
    exporter,
    metadata: {'app': 'MyApp', 'version': '1.0.0'},
  ),
);
```

#### Custom ErrorExporter

For full control over the transport (non-HTTP, batching, etc.), implement
`ErrorExporter` directly:

```dart
class MyExporter implements ErrorExporter {
  @override
  Future<void> send(
    LogRecord error,
    List<LogRecord> contextLogs,
    Map<String, String> metadata,
  ) async {
    // `error`       — the error-level LogRecord that triggered the alert
    // `contextLogs` — recent records from ContextBufferProcessor
    // `metadata`    — key-value pairs set on ErrorAlertSink (e.g. app name, version)
    await myService.report(
      message: error.message,
      context: contextLogs.map((r) => r.message).toList(),
      metadata: metadata,
    );
  }
}

final buffer = ContextBufferProcessor();
log.processors.add(buffer);
log.sinks.add(
  ErrorAlertSink(
    buffer,
    MyExporter(),
    metadata: {'app': 'MyApp', 'version': '1.0.0'},
  ),
);
```

## Observability

Access structured observability methods through `log.obs`.
These are separate from severity-level logs and are designed for structured data
that can later be forwarded to an external observability backend without changing call-site code.

### log.obs.event

Logs a named event with an optional payload and metadata attributes.

```dart
log.obs.event(
  this,              // source: pass `this`, a Type, or a String
  'user_signed_in',  // event name / message
  data: {'userId': '42', 'plan': 'pro'},
  attrs: {'env': 'prod'},
);
```

Console output:
```
[2026-03-13 10:00:00.000] 📡 [EVENT] MyClass: user_signed_in : {userId: 42, plan: pro} attrs: {env: prod}
```

### log.obs.metric

Logs a numeric measurement with an optional unit and metadata attributes.

```dart
log.obs.metric(
  this,               // source
  'request_duration', // metric name
  142,                // value
  unit: 'ms',
  attrs: {'endpoint': '/api/login'},
);
```

Console output:
```
[2026-03-13 10:00:00.000] 📊 [METRIC] MyClass: request_duration : 142 [ms] attrs: {endpoint: /api/login}
```

### Parameter reference

| Parameter | Type                    | Required | Description                                              |
|-----------|-------------------------|----------|----------------------------------------------------------|
| `source`  | `Object`                | Yes      | Origin class. Pass `this` to resolve the runtime type automatically, or a `Type` or `String`. |
| `message` | `String`                | Yes (`event` only) | Human-readable event description.              |
| `name`    | `String`                | Yes (`metric` only) | Metric name (e.g. `'request_duration'`).       |
| `value`   | `num`                   | Yes (`metric` only) | Numeric measurement.                           |
| `unit`    | `String?`               | No       | Unit label, e.g. `'ms'`, `'count'` (metric only).       |
| `data`    | `Map<String, dynamic>?` | No       | Arbitrary payload (event only).                          |
| `attrs`   | `Map<String, Object>?`  | No       | Structured metadata, e.g. environment or version.        |

## Log levels

| Level    | Description                        |
|----------|------------------------------------|
| `trace`  | Fine-grained diagnostic messages   |
| `debug`  | General debugging information      |
| `info`   | Informational messages             |
| `notice` | Notable events worth highlighting  |
| `warn`   | Warnings with optional error/stack |
| `error`  | Errors with error object and stack |
