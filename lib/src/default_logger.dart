import 'console_sink.dart';
import 'logger.dart';

/// The default logger. Prints colored, emoji-decorated log entries to the console.
///
/// Output is handled by the [ConsoleSink] added to [Logger.sinks] on
/// construction. You can remove it and add other sinks at any time:
/// ```dart
/// log.sinks.clear();
/// log.sinks.add(MyCustomSink());
/// ```
class DefaultLogger extends Logger {
  DefaultLogger({super.level}) {
    sinks.add(ConsoleSink());
  }
}
