import '../core/log_entry.dart';

/// Converts a [LogRecord] and its context into an HTTP request payload.
///
/// Implement this interface to support different notification services
/// (e.g. Slack, Discord, PagerDuty) while reusing [HttpErrorExporter]
/// for the transport layer.
abstract class ErrorFormatter {
  /// Builds the JSON-encodable payload to deliver to the remote endpoint.
  ///
  /// [error] is the log record that triggered the alert.
  /// [contextLogs] are recently buffered log records that preceded the error.
  /// [metadata] contains arbitrary key-value pairs (e.g. app name, version).
  Map<String, dynamic> format(
    LogRecord error,
    List<LogRecord> contextLogs,
    Map<String, String> metadata,
  );
}
