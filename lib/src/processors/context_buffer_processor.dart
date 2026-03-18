import '../core/log_entry.dart';
import '../core/log_processor.dart';

/// Retains the most recent [capacity] [LogRecord] entries in a ring buffer.
///
/// Non-[LogRecord] entries (e.g. [EventEntry], [MetricEntry]) pass through
/// without being buffered.
/// Use [getRecent] to retrieve stored records in chronological order
/// (oldest first). Typically used alongside [ErrorAlertSink] to attach
/// context logs to error reports.
class ContextBufferProcessor implements LogProcessor {
  final int capacity;
  final List<LogRecord?> _buffer;
  int _index = 0;

  ContextBufferProcessor([this.capacity = 20])
    : _buffer = List.filled(capacity, null);

  @override
  bool process(LogEntry entry) {
    if (entry is LogRecord) {
      _buffer[_index] = entry;
      _index = (_index + 1) % capacity;
    }
    return true;
  }

  /// Returns buffered records in chronological order (oldest first).
  List<LogRecord> getRecent() {
    final result = <LogRecord>[];
    for (var i = 0; i < capacity; i++) {
      final entry = _buffer[(_index + i) % capacity];
      if (entry != null) result.add(entry);
    }
    return result;
  }
}
