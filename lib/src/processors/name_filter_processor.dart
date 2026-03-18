import '../core/log_entry.dart';
import '../core/log_processor.dart';

/// Filters log entries based on [LogEntry.className] using allow/deny lists.
///
/// When [denyList] is non-empty, entries whose [className] contains
/// any entry are dropped.
/// When [allowList] is non-empty, only entries whose [className] contains
/// at least one entry pass through.
/// Applies to all entry types ([LogRecord], [EventEntry], [MetricEntry]).
class NameFilterProcessor implements LogProcessor {
  List<String> denyList;
  List<String> allowList;

  NameFilterProcessor({List<String>? denyList, List<String>? allowList})
    : denyList = denyList ?? [],
      allowList = allowList ?? [];

  @override
  bool process(LogEntry entry) {
    final className = entry.className;
    if (denyList.isNotEmpty && denyList.any((e) => className.contains(e))) {
      return false;
    }
    if (allowList.isNotEmpty && !allowList.any((f) => className.contains(f))) {
      return false;
    }
    return true;
  }
}
