import '../core/log_entry.dart';

/// Sends error reports to an external service.
///
/// Implement this interface to deliver error notifications (e.g. to Slack,
/// New Relic, Sentry, etc.).
///
/// [metadata] contains arbitrary key-value pairs (e.g. app name, version)
/// supplied by [ErrorAlertSink].
abstract class ErrorExporter {
  Future<void> send(
    LogRecord error,
    List<LogRecord> contextLogs,
    Map<String, String> metadata,
  );
}
