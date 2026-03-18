import 'log_entry.dart';

/// Abstract formatter responsible for converting a [LogEntry] to type [T].
///
/// Implement this class to customize how log entries are rendered.
///
/// Example:
/// ```dart
/// class JsonFormatter extends LogFormatter<String> {
///   @override
///   String format(LogEntry entry) => jsonEncode({'msg': entry.toString()});
/// }
/// ```
abstract class LogFormatter<T> {
  T format(LogEntry entry);
}
