import 'log_entry.dart';

/// Abstract sink responsible for outputting log entries.
///
/// Implement [emit] to send any [LogEntry] (including [LogRecord],
/// [EventEntry], [MetricEntry]) to any destination
/// (console, files, remote services, etc.).
///
/// Example:
/// ```dart
/// class FileSink extends LogSink {
///   @override
///   void emit(LogEntry entry) { /* write to file */ }
/// }
/// ```
abstract class LogSink {
  void emit(LogEntry entry);
}
