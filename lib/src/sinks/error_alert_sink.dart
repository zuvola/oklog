import '../core/log_entry.dart';
import '../core/log_sink.dart';
import '../core/pii_value.dart';
import '../processors/context_buffer_processor.dart';
import 'error_exporter.dart';

/// A [LogSink] that notifies an [ErrorExporter] when a record at or above
/// [minimumLevel] is received.
///
/// Recent context logs are retrieved from [buffer] and forwarded alongside
/// the triggering record so the exporter can include them in the report.
/// The triggering record itself is excluded from the context list.
///
/// Common information such as app name or version can be passed via
/// [metadata] and will be forwarded to the exporter with every report.
///
/// Example:
/// ```dart
/// final buffer = ContextBufferProcessor();
/// final logger = Logger(
///   processors: [LevelFilterProcessor(), buffer],
///   sinks: [
///     ConsoleSink(),
///     ErrorAlertSink(
///       buffer,
///       MyExporter(),
///       minimumLevel: LogLevel.critical,
///       metadata: {'app': 'MyApp', 'version': '1.2.3'},
///     ),
///   ],
/// );
/// ```
class ErrorAlertSink extends LogSink {
  final ContextBufferProcessor buffer;
  final ErrorExporter exporter;

  /// The minimum severity that triggers an error report.
  ///
  /// Defaults to [LogLevel.error] for backwards compatibility.
  final LogLevel minimumLevel;

  /// Additional key-value pairs (e.g. app name, version, environment) that
  /// are forwarded to the [exporter] with every report.
  final Map<String, String> metadata;

  ErrorAlertSink(
    this.buffer,
    this.exporter, {
    this.minimumLevel = LogLevel.error,
    this.metadata = const {},
  });

  @override
  void emit(LogEntry entry) {
    if (entry is! LogRecord || entry.level.index < minimumLevel.index) return;
    exporter.send(
      _redacted(entry),
      buffer
          .getRecent()
          .where((record) => !identical(record, entry))
          .map(_redacted)
          .toList(),
      metadata,
    );
  }

  /// Returns [r] unchanged if it has no PII attrs; otherwise returns a copy
  /// with all [PiiValue] entries replaced by a redaction marker.
  LogRecord _redacted(LogRecord r) {
    if (r.attrs == null || !r.attrs!.values.any((v) => v is PiiValue)) {
      return r;
    }
    return r.copyWithAttrs(maskPiiAttrs(r.attrs));
  }
}
