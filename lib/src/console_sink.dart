import 'console_formatter.dart';
import 'log_formatter.dart';
import 'log_sink.dart';
import 'logger.dart';

/// A [LogSink] that prints log entries to the console.
///
/// Formatting is delegated to a [LogFormatter]. By default, [ConsoleFormatter]
/// is used for colored, emoji-annotated output. Provide a custom formatter to
/// change the output representation without altering sink behaviour:
/// ```dart
/// log.sinks.add(ConsoleSink(formatter: MyFormatter()));
/// ```
class ConsoleSink extends LogSink<String> {
  ConsoleSink({LogFormatter<String>? formatter})
    : super(formatter ?? ConsoleFormatter());

  @override
  void write(String formatted, LogEntry record) {
    print(formatted);
  }
}
