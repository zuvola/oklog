import '../core/log_entry.dart';
import '../core/log_processor.dart';

/// Filters log entries whose [LogRecord.level] is below [minLevel].
///
/// Non-[LogRecord] entries (e.g. [EventEntry], [MetricEntry]) always pass through.
class LevelFilterProcessor implements LogProcessor {
  LogLevel minLevel;

  LevelFilterProcessor({this.minLevel = LogLevel.debug});

  @override
  bool process(LogEntry entry) {
    if (entry is! LogRecord) return true;
    return entry.level.index >= minLevel.index;
  }
}
