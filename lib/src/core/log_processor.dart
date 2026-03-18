import 'log_entry.dart';

/// Processes a [LogEntry] in the log pipeline.
///
/// Return `true` to allow the entry to continue to the next processor and
/// eventually to the sinks. Return `false` to drop the entry.
abstract class LogProcessor {
  bool process(LogEntry entry);
}
