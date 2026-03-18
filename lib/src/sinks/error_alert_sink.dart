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
/// Example:
/// ```dart
/// final buffer = ContextBufferProcessor();
/// final logger = Logger(
///   processors: [LevelFilterProcessor(), buffer],
///   sinks: [ConsoleSink(), ErrorAlertSink(buffer, MyExporter())],
/// );
/// ```
class ErrorAlertSink extends LogSink {
  final ContextBufferProcessor buffer;
  final ErrorExporter exporter;

  ErrorAlertSink(this.buffer, this.exporter);

  @override
  void emit(LogEntry entry) {
    if (entry is! LogRecord || entry.level != LogLevel.error) return;
    exporter.send(entry, buffer.getRecent());
  }
}
