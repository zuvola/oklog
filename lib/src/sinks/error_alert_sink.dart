import 'dart:async';

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

  /// Optional handler for failures propagated by an exporter. The built-in
  /// `HttpErrorExporter` handles and logs its own HTTP delivery failures.
  /// Do not log through this exporter from the handler to avoid recursion.
  final void Function(Object error, StackTrace stackTrace)? onExportError;

  ErrorAlertSink(
    this.buffer,
    this.exporter, {
    this.minimumLevel = LogLevel.error,
    this.metadata = const {},
    this.onExportError,
  });

  @override
  void emit(LogEntry entry) {
    if (entry is! LogRecord || entry.level.index < minimumLevel.index) return;
    final context = buffer
        .getRecent()
        .where((record) => !identical(record, entry))
        .map(_redacted)
        .toList();
    unawaited(_sendSafely(_redacted(entry), context));
  }

  Future<void> _sendSafely(LogRecord error, List<LogRecord> context) async {
    try {
      await exporter.send(error, context, metadata);
    } catch (failure, stackTrace) {
      if (onExportError != null) {
        try {
          onExportError!(failure, stackTrace);
          return;
        } catch (handlerError) {
          print(
            'Error report failure handler failed (${handlerError.runtimeType}).',
          );
        }
      }
      // Arbitrary exporter exceptions may contain webhook credentials.
      print('Error report export failed (${failure.runtimeType}).');
    }
  }

  /// Returns [r] unchanged when no nested attribute is marked as PII.
  LogRecord _redacted(LogRecord r) {
    if (!containsPiiAttrs(r.attrs)) return r;
    return r.copyWithAttrs(maskPiiAttrs(r.attrs));
  }
}
