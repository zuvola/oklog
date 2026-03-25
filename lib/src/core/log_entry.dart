/// Severity levels for log messages, ordered from least to most severe.
enum LogLevel { trace, debug, info, notice, warn, error }

/// Base class for all log entries.
sealed class LogEntry {
  /// The resolved class or component name of the log source.
  final String className;

  /// The time at which this entry was created.
  final DateTime timestamp;

  LogEntry(Object source)
    : className = resolveClassName(source),
      timestamp = DateTime.now();

  /// Internal constructor that preserves an existing [className] and [timestamp].
  LogEntry._copy(this.className, this.timestamp);

  /// Resolves a log source to a class name string.
  /// Accepts a [String] (used as-is), a [Type], or any object (uses runtimeType).
  static String resolveClassName(Object source) {
    if (source is String) {
      return source;
    } else if (source is Type) {
      return source.toString();
    } else {
      return source.runtimeType.toString();
    }
  }
}

/// A standard severity-level log message.
final class LogRecord extends LogEntry {
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, Object?>? attrs;

  LogRecord(
    super.className,
    this.level,
    this.message, [
    this.error,
    this.stackTrace,
    this.attrs,
  ]);

  /// Returns a copy of this record with [attrs] replaced, preserving all
  /// other fields including [timestamp].
  LogRecord copyWithAttrs(Map<String, Object?>? attrs) =>
      LogRecord._copy(this, attrs);

  LogRecord._copy(LogRecord original, this.attrs)
    : level = original.level,
      message = original.message,
      error = original.error,
      stackTrace = original.stackTrace,
      super._copy(original.className, original.timestamp);
}

/// A structured observability event.
final class EventEntry extends LogEntry {
  final String message;
  final Map<String, dynamic>? data;
  final Map<String, Object?>? attrs;

  EventEntry(super.className, this.message, {this.data, this.attrs});
}

/// A structured observability metric.
final class MetricEntry extends LogEntry {
  final String name;
  final num value;
  final String? unit;
  final Map<String, Object?>? attrs;

  MetricEntry(super.className, this.name, this.value, {this.unit, this.attrs});
}
