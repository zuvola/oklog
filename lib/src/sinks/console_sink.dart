import '../core/log_entry.dart';
import '../core/log_formatter.dart';
import '../core/log_sink.dart';
import 'console_formatter.dart';

/// A [LogSink] that prints log entries to the console.
///
/// Formatting is delegated to a [LogFormatter]. By default, [ConsoleFormatter]
/// is used for colored, emoji-annotated output. Provide a custom formatter to
/// change the output representation without altering sink behaviour:
/// ```dart
/// log.sinks.add(ConsoleSink(formatter: MyFormatter()));
/// ```
class ConsoleSink extends LogSink {
  final LogFormatter<String> formatter;

  ConsoleSink({LogFormatter<String>? formatter})
    : formatter = formatter ?? ConsoleFormatter();

  @override
  void emit(LogEntry entry) {
    print(formatter.format(entry));
  }
}
