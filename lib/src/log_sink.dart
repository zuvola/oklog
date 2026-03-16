import 'log_formatter.dart';
import 'logger.dart';

/// Abstract sink responsible for outputting log entries.
///
/// Implement this class to send log entries to any destination
/// (console, files, remote services, etc.).
///
/// Example custom sink:
/// ```dart
/// class FileSink extends LogSink<String> {
///   FileSink() : super(MyFormatter());
///
///   @override
///   void write(String formatted, LogEntry record) { /* write to file */ }
/// }
/// ```
abstract class LogSink<T> {
  final LogFormatter<T> formatter;

  LogSink(this.formatter);

  void log(LogEntry record) {
    final formatted = formatter.format(record);
    write(formatted, record);
  }

  void write(T formatted, LogEntry record);
}
