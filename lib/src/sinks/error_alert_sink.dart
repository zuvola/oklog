import '../core/log_entry.dart';
import '../core/log_sink.dart';
import '../processors/context_buffer_processor.dart';
import 'error_exporter.dart';

/// A [LogSink] that notifies an [ErrorExporter] when an error-level record
/// is received.
///
/// Recent context logs are retrieved from [buffer] and forwarded alongside
/// the error record so the exporter can include them in the report.
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
///       metadata: {'app': 'MyApp', 'version': '1.2.3'},
///     ),
///   ],
/// );
/// ```
class ErrorAlertSink extends LogSink {
  final ContextBufferProcessor buffer;
  final ErrorExporter exporter;

  /// Additional key-value pairs (e.g. app name, version, environment) that
  /// are forwarded to the [exporter] with every error report.
  final Map<String, String> metadata;

  ErrorAlertSink(this.buffer, this.exporter, {this.metadata = const {}});

  @override
  void emit(LogEntry entry) {
    if (entry is! LogRecord || entry.level != LogLevel.error) return;
    exporter.send(entry, buffer.getRecent(), metadata);
  }
}
