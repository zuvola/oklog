import 'log_sink.dart';

/// Severity levels for log messages, ordered from least to most severe.
enum LogLevel { trace, debug, info, notice, warn, error }

/// Base class for all log entries passed to [Logger.write].
sealed class LogEntry {
  /// The resolved class or component name of the log source.
  final String className;

  /// The time at which this entry was created.
  final DateTime timestamp;

  LogEntry(this.className) : timestamp = DateTime.now();
}

/// A standard severity-level log message.
final class LogRecord extends LogEntry {
  final LogLevel level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, Object>? tags;

  LogRecord(
    super.className,
    this.level,
    this.message, [
    this.error,
    this.stackTrace,
    this.tags,
  ]);
}

/// A structured observability event.
final class EventEntry extends LogEntry {
  final String message;
  final Map<String, dynamic>? data;
  final Map<String, Object>? tags;

  EventEntry(super.className, this.message, {this.data, this.tags});
}

/// A structured observability metric.
final class MetricEntry extends LogEntry {
  final String name;
  final num value;
  final String? unit;
  final Map<String, Object>? tags;

  MetricEntry(super.className, this.name, this.value, {this.unit, this.tags});
}

/// Base class for all loggers.
///
/// Can be used directly by adding [LogSink] instances to [sinks].
/// Filtering by level and class name is handled here before [write] is called.
class Logger {
  /// Minimum log level to output. Messages below this level are ignored.
  LogLevel level;

  /// Class name substrings that should be suppressed.
  /// If a class name contains any entry in this list, the message is dropped.
  List<String> denyList = [];

  /// Class name substrings that are allowed through.
  /// When non-empty, only messages whose class name contains at least one entry
  /// in this list are logged.
  List<String> allowList = [];

  Logger({this.level = LogLevel.debug});

  /// Returns true if [target] level is at or above the configured [level].
  bool _enabled(LogLevel target) {
    return target.index >= level.index;
  }

  /// Returns true if [className] passes the deny/allow list filters.
  bool _filter(String className) {
    if (denyList.isNotEmpty && denyList.any((e) => className.contains(e))) {
      return false;
    }
    if (allowList.isNotEmpty && !allowList.any((f) => className.contains(f))) {
      return false;
    }
    return true;
  }

  /// Resolves a log target to a class name string.
  /// Accepts a [String] (used as-is), a [Type], or any object (uses runtimeType).
  String _className(Object target) {
    if (target is String) {
      return target;
    } else if (target is Type) {
      return target.toString();
    } else {
      return target.runtimeType.toString();
    }
  }

  /// Sinks that receive every log entry. Add sinks to route output to
  /// multiple destinations (console, files, remote services, etc.).
  final List<LogSink<dynamic>> sinks = [];

  /// Forwards [record] to every registered [LogSink].
  void _emit(LogEntry record) {
    for (final sink in sinks) {
      sink.log(record);
    }
  }

  /// Writes a [LogEntry] to the output.
  ///
  /// The default implementation forwards the entry to all registered [sinks]
  /// via [_emit]. Subclasses may override this to add custom behaviour, but
  /// should call `super.write(entry)` or `_emit(entry)` to preserve sink
  /// routing.
  void write(LogEntry entry) => _emit(entry);

  ObsLogger? _obs;

  /// Entry-point for observability methods (e.g. [ObsLogger.event], [ObsLogger.metric]).
  ObsLogger get obs => _obs ??= ObsLogger(this);

  /// Logs a debug-level message for [target].
  void debug(Object target, String message, {Map<String, Object>? tags}) {
    if (!_enabled(LogLevel.debug)) return;
    final className = _className(target);
    if (!_filter(className)) return;
    write(LogRecord(className, LogLevel.debug, message, null, null, tags));
  }

  /// Logs a trace-level message for [target].
  void trace(Object target, String message, {Map<String, Object>? tags}) {
    if (!_enabled(LogLevel.trace)) return;
    final className = _className(target);
    if (!_filter(className)) return;
    write(LogRecord(className, LogLevel.trace, message, null, null, tags));
  }

  /// Logs an info-level message for [target].
  void info(Object target, String message, {Map<String, Object>? tags}) {
    if (!_enabled(LogLevel.info)) return;
    final className = _className(target);
    if (!_filter(className)) return;
    write(LogRecord(className, LogLevel.info, message, null, null, tags));
  }

  /// Logs a notice-level message for [target].
  void notice(Object target, String message, {Map<String, Object>? tags}) {
    if (!_enabled(LogLevel.notice)) return;
    final className = _className(target);
    if (!_filter(className)) return;
    write(LogRecord(className, LogLevel.notice, message, null, null, tags));
  }

  /// Logs a warn-level message for [target], with an optional [error] and [stackTrace].
  void warn(
    Object target,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_enabled(LogLevel.warn)) return;
    final className = _className(target);
    if (!_filter(className)) return;
    write(LogRecord(className, LogLevel.warn, message, error, stackTrace));
  }

  /// Logs an error-level message for [target], with a required [error] and optional [stackTrace].
  void error(
    Object target,
    String message,
    Object? error, [
    StackTrace? stackTrace,
  ]) {
    if (!_enabled(LogLevel.error)) return;
    final className = _className(target);
    if (!_filter(className)) return;
    write(LogRecord(className, LogLevel.error, message, error, stackTrace));
  }
}

/// Provides observability-oriented log methods (e.g. structured events).
///
/// Accessed via [Logger.obs] — do not instantiate directly.
class ObsLogger {
  final Logger _logger;

  ObsLogger(this._logger);

  /// Logs a structured event via the parent [Logger].
  ///
  /// [source] identifies the originating class or component: pass `this` to
  /// use the runtime type, a [Type] literal, or a plain [String].
  /// [message] is the human-readable event description.
  /// [data] carries an optional arbitrary payload.
  /// [tags] carries optional string metadata (e.g. environment, version).
  void event(
    Object source,
    String message, {
    Map<String, dynamic>? data,
    Map<String, Object>? tags,
  }) {
    final className = _logger._className(source);
    if (!_logger._filter(className)) return;
    _logger.write(EventEntry(className, message, data: data, tags: tags));
  }

  /// Logs a structured metric via the parent [Logger].
  ///
  /// [source] identifies the originating class or component: pass `this` to
  /// use the runtime type, a [Type] literal, or a plain [String].
  /// [name] is the metric name (e.g. `'request_duration'`).
  /// [value] is the numeric measurement.
  /// [unit] is the optional unit label (e.g. `'ms'`, `'count'`).
  /// [tags] carries optional string metadata (e.g. environment, version).
  void metric(
    Object source,
    String name,
    num value, {
    String? unit,
    Map<String, Object>? tags,
  }) {
    final className = _logger._className(source);
    if (!_logger._filter(className)) return;
    _logger.write(MetricEntry(className, name, value, unit: unit, tags: tags));
  }
}
