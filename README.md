# oklog

[![pub package](https://img.shields.io/pub/v/oklog.svg)](https://pub.dartlang.org/packages/oklog)

A simple yet capable logging utility for Dart and Flutter. Just log. ok.

## Features

- Six log levels: `trace`, `debug`, `info`, `notice`, `warn`, `error`
- Colored, emoji-decorated console output via `DefaultLogger`
- Filter logs by class name using `allowList` and `denyList`
- Extensible output via `LogSink` — route logs to console, files, remote services, etc.
- Global `log` instance ready to use out of the box
- Observability support: structured events and metrics via `log.obs`

## Getting started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  oklog: ^1.0.0
```

Then import the library:

```dart
import 'package:oklog/oklog.dart';
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
    log.error('main', 'An error occurred.', e, st);
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

### Filtering with allowList and denyList

```dart
// Only log messages from classes whose name contains 'main'
log.allowList = ['main'];

// Suppress log messages from classes whose name contains 'MyClass'
log.denyList = ['MyClass'];

// Clear filters
log.allowList.clear();
log.denyList.clear();
```

### Silencing output

```dart
log.sinks.clear(); // remove all sinks to suppress output
```

### Custom sinks

Adding a sink routes every log entry to that destination. Multiple sinks can be
active at the same time.

Implement `LogSink<T>` to send entries anywhere. Pass a `LogFormatter<T>` to the
super constructor — the base class calls `formatter.format(record)` and forwards
the result to your `write` method:

```dart
class FileSink extends LogSink<String> {
  FileSink({LogFormatter<String>? formatter})
    : super(formatter ?? ConsoleFormatter());

  @override
  void write(String formatted, LogEntry record) {
    // write formatted string to a file, remote service, etc.
  }
}

log.sinks.add(FileSink());
```

The built-in `ConsoleSink` prints colored, emoji-decorated output and is added
automatically by `DefaultLogger`.

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

### Changing the log level

```dart
log.level = LogLevel.warn; // only warn and error are printed
```

## Observability

Access structured observability methods through `log.obs`.
These are separate from severity-level logs and are designed for structured data
that can later be forwarded to an external observability backend without changing call-site code.

### log.obs.event

Logs a named event with an optional payload and metadata tags.

```dart
log.obs.event(
  this,              // source: pass `this`, a Type, or a String
  'user_signed_in',  // event name / message
  data: {'userId': '42', 'plan': 'pro'},
  tags: {'env': 'prod'},
);
```

Console output:
```
[2026-03-13 10:00:00.000] 📡 [EVENT] MyClass: user_signed_in data: {userId: 42, plan: pro} tags: {env: prod}
```

### log.obs.metric

Logs a numeric measurement with an optional unit and metadata tags.

```dart
log.obs.metric(
  this,               // source
  'request_duration', // metric name
  142,                // value
  unit: 'ms',
  tags: {'endpoint': '/api/login'},
);
```

Console output:
```
[2026-03-13 10:00:00.000] 📊 [METRIC] MyClass name: request_duration value: 142 unit: ms tags: {endpoint: /api/login}
```

### Parameter reference

| Parameter | Type                    | Required | Description                                              |
|-----------|-------------------------|----------|----------------------------------------------------------|
| `source`  | `Object` / `String`     | Yes      | Origin class. Pass `this` to resolve the runtime type automatically. |
| `message` | `String`                | Yes (`event` only) | Human-readable event description.              |
| `name`    | `String`                | Yes (`metric` only) | Metric name (e.g. `'request_duration'`).       |
| `value`   | `num`                   | Yes (`metric` only) | Numeric measurement.                           |
| `unit`    | `String?`               | No       | Unit label, e.g. `'ms'`, `'count'` (metric only).       |
| `data`    | `Map<String, dynamic>?` | No       | Arbitrary payload (event only).                          |
| `tags`    | `Map<String, String>?`  | No       | String metadata, e.g. environment or version.            |

## Log levels

| Level    | Description                        |
|----------|---------------------------------|
| `trace`  | Fine-grained diagnostic messages   |
| `debug`  | General debugging information      |
| `info`   | Informational messages             |
| `notice` | Notable events worth highlighting  |
| `warn`   | Warnings with optional error/stack |
| `error`  | Errors with error object and stack |
