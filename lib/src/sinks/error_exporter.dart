import '../core/log_entry.dart';

/// Sends error reports to an external service.
///
/// Implement this interface to deliver error notifications (e.g. to Slack,
/// New Relic, Sentry, etc.).
abstract class ErrorExporter {
  Future<void> send(LogRecord error, List<LogRecord> contextLogs);
}
