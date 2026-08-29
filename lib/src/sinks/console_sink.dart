import 'dart:developer' as developer;

import '../core/log_entry.dart';
import '../core/log_formatter.dart';
import '../core/log_sink.dart';
import 'console_formatter.dart';

/// A [LogSink] that prints log entries to the console.
///
/// Formatting is delegated to a [LogFormatter]. By default, [ConsoleFormatter]
/// is used for colored, emoji-annotated output. Provide a custom formatter to
/// change the output representation without altering sink behaviour:
/// ```dart
/// log.sinks.add(ConsoleSink(formatter: MyFormatter()));
/// ```
///
/// Standard console output is used by default. Set [useDeveloperLog] to `true`
/// to route entries through `dart:developer.log` instead.
class ConsoleSink extends LogSink {
  final LogFormatter<String> formatter;
  final bool useDeveloperLog;

  ConsoleSink({LogFormatter<String>? formatter, this.useDeveloperLog = false})
    : formatter = formatter ?? ConsoleFormatter();

  // Formatter used for developer.log output: omits level string and error/stackTrace
  // from the message string since those are passed as dedicated parameters.
  late final LogFormatter<String> _devLogFormatter =
      formatter is ConsoleFormatter
      ? ConsoleFormatter(forDeveloperLog: true)
      : formatter;

  @override
  void emit(LogEntry entry) {
    if (useDeveloperLog) {
      _emitWithDeveloperLog(entry);
    } else {
      print(formatter.format(entry));
    }
  }

  // Forwards the log entry to `dart:developer.log` with appropriate parameters.
  void _emitWithDeveloperLog(LogEntry entry) {
    switch (entry) {
      case LogRecord():
        developer.log(
          _devLogFormatter.format(entry),
          time: entry.timestamp,
          level: _toDevLevel(entry.level),
          name: entry.level.name.toUpperCase().padRight(6),
          error: entry.error,
          stackTrace: entry.stackTrace,
        );
      case EventEntry():
        developer.log(
          _devLogFormatter.format(entry),
          time: entry.timestamp,
          level: 800,
          name: 'EVENT ',
        );
      case MetricEntry():
        developer.log(
          _devLogFormatter.format(entry),
          time: entry.timestamp,
          level: 800,
          name: 'METRIC',
        );
    }
  }

  /// Maps [LogLevel] to dart:developer log level integers.
  static int _toDevLevel(LogLevel level) => switch (level) {
    LogLevel.trace => 300,
    LogLevel.debug => 400,
    LogLevel.info => 800,
    LogLevel.notice => 850,
    LogLevel.warn => 900,
    LogLevel.error => 1000,
    LogLevel.critical => 1200,
  };
}
