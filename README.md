# oklog

[![pub package](https://img.shields.io/pub/v/oklog.svg)](https://pub.dartlang.org/packages/oklog)

A simple yet capable logging utility for Dart and Flutter. Just log. ok.

## Features

- Six log levels: `trace`, `debug`, `info`, `notice`, `warn`, `error`
- Colored, emoji-decorated console output via `ConsoleLogger`
- Filter logs by class name using `allowList` and `denyList`
- Silent no-op logging via `DummyLogger`
- Global `log` instance ready to use out of the box

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

### Silencing output with DummyLogger

```dart
log = DummyLogger(); // all log calls become no-ops
```

### Changing the log level

```dart
log.level = LogLevel.warn; // only warn and error are printed
```

## Log levels

| Level    | Description                        |
|----------|---------------------------------|
| `trace`  | Fine-grained diagnostic messages   |
| `debug`  | General debugging information      |
| `info`   | Informational messages             |
| `notice` | Notable events worth highlighting  |
| `warn`   | Warnings with optional error/stack |
| `error`  | Errors with error object and stack |
