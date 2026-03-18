import 'log_entry.dart';
import 'log_processor.dart';
import 'log_sink.dart';

/// Log processing pipeline: processors → sinks.
///
/// Add [LogProcessor] instances to [processors] to filter or transform entries
/// before they reach the sinks. Add [LogSink] instances to [sinks] to route
/// output to any destination.
///
/// All entry types ([LogRecord], [EventEntry], [MetricEntry]) flow through the
/// same pipeline, so processors and sinks receive every kind of entry.
class Logger {
  /// Processors run in order before each entry reaches the sinks.
  /// A processor that returns `false` drops the entry from the pipeline.
  final List<LogProcessor> processors;

  /// Sinks that receive every entry that passes all processors.
  final List<LogSink> sinks;

  Logger({List<LogProcessor>? processors, List<LogSink>? sinks})
    : processors = processors ?? [],
      sinks = sinks ?? [];

  /// Runs every entry through processors then sinks.
  ///
  /// If any processor returns `false`, the entry is dropped and no further
  /// processors or sinks are invoked.
  Future<void> emit(LogEntry entry) async {
    for (final processor in processors) {
      if (!processor.process(entry)) return;
    }
    for (final sink in sinks) {
      sink.emit(entry);
    }
  }

  ObservabilityLogger? _obs;

  /// Entry-point for observability methods (e.g. [ObservabilityLogger.event], [ObservabilityLogger.metric]).
  ObservabilityLogger get obs => _obs ??= ObservabilityLogger(this);

  /// Logs a trace-level message for [source].
  void trace(Object source, String message, {Map<String, Object>? attrs}) {
    emit(LogRecord(source, LogLevel.trace, message, null, null, attrs));
  }

  /// Logs a debug-level message for [source].
  void debug(Object source, String message, {Map<String, Object>? attrs}) {
    emit(LogRecord(source, LogLevel.debug, message, null, null, attrs));
  }

  /// Logs an info-level message for [source].
  void info(Object source, String message, {Map<String, Object>? attrs}) {
    emit(LogRecord(source, LogLevel.info, message, null, null, attrs));
  }

  /// Logs a notice-level message for [source].
  void notice(Object source, String message, {Map<String, Object>? attrs}) {
    emit(LogRecord(source, LogLevel.notice, message, null, null, attrs));
  }

  /// Logs a warn-level message for [source], with an optional [error] and [stackTrace].
  void warn(
    Object source,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object>? attrs,
  }) {
    emit(LogRecord(source, LogLevel.warn, message, error, stackTrace, attrs));
  }

  /// Logs an error-level message for [source], with an optional [error] and [stackTrace].
  void error(
    Object source,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object>? attrs,
  }) {
    emit(LogRecord(source, LogLevel.error, message, error, stackTrace, attrs));
  }
}

/// Provides observability-oriented log methods (structured events and metrics).
///
/// Accessed via [Logger.obs] — do not instantiate directly.
/// Both [event] and [metric] flow through the same processor → sink pipeline
/// as regular log records.
class ObservabilityLogger {
  final Logger _logger;

  ObservabilityLogger(this._logger);

  /// Logs a structured event via the parent [Logger].
  ///
  /// [source] identifies the originating class or component: pass `this` to
  /// use the runtime type, a [Type] literal, or a plain [String].
  /// [message] is the human-readable event description.
  /// [data] carries an optional arbitrary payload.
  /// [attrs] carries optional string metadata (e.g. environment, version).
  void event(
    Object source,
    String message, {
    Map<String, dynamic>? data,
    Map<String, Object>? attrs,
  }) {
    _logger.emit(EventEntry(source, message, data: data, attrs: attrs));
  }

  /// Logs a structured metric via the parent [Logger].
  ///
  /// [source] identifies the originating class or component: pass `this` to
  /// use the runtime type, a [Type] literal, or a plain [String].
  /// [name] is the metric name (e.g. `'request_duration'`).
  /// [value] is the numeric measurement.
  /// [unit] is the optional unit label (e.g. `'ms'`, `'count'`).
  /// [attrs] carries optional string metadata (e.g. environment, version).
  void metric(
    Object source,
    String name,
    num value, {
    String? unit,
    Map<String, Object>? attrs,
  }) {
    _logger.emit(MetricEntry(source, name, value, unit: unit, attrs: attrs));
  }
}
