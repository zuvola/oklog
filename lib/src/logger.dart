/// Severity levels for log messages, ordered from least to most severe.
enum LogLevel { trace, debug, info, warn, error }

/// Abstract base class for all loggers.
///
/// Subclasses must implement [write] to define how log entries are output.
/// Filtering by level and class name is handled here before [write] is called.
abstract class Logger {
  /// Minimum log level to output. Messages below this level are ignored.
  LogLevel level;

  /// Class name substrings that should be suppressed.
  /// If a class name contains any entry in this list, the message is dropped.
  List<String> denyList = [];

  /// Class name substrings that are allowed through.
  /// When non-empty, only messages whose class name contains at least one entry
  /// in this list are logged.
  List<String> allowList = [];

  Logger({this.level = LogLevel.debug});

  /// Returns true if [target] level is at or above the configured [level].
  bool _enabled(LogLevel target) {
    return target.index >= level.index;
  }

  /// Returns true if [className] passes the deny/allow list filters.
  bool _filter(String className) {
    if (denyList.isNotEmpty && denyList.any((e) => className.contains(e))) {
      return false;
    }
    if (allowList.isNotEmpty && !allowList.any((f) => className.contains(f))) {
      return false;
    }
    return true;
  }

  /// Resolves a log target to a class name string.
  /// Accepts a [String] (used as-is), a [Type], or any object (uses runtimeType).
  String _className(Object target) {
    if (target is String) {
      return target;
    } else if (target is Type) {
      return target.toString();
    } else {
      return target.runtimeType.toString();
    }
  }

  /// Writes a log entry. Implemented by subclasses.
  void write(
    LogLevel level,
    String className,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]);

  /// Logs a debug-level message for [target].
  void debug(Object target, String message) {
    if (!_enabled(LogLevel.debug)) return;
    final className = _className(target);
    if (!_filter(className)) return;
    write(LogLevel.debug, className, message);
  }

  /// Logs a trace-level message for [target].
  void trace(Object target, String message) {
    if (!_enabled(LogLevel.trace)) return;
    final className = _className(target);
    if (!_filter(className)) return;
    write(LogLevel.trace, className, message);
  }

  /// Logs an info-level message for [target].
  void info(Object target, String message) {
    if (!_enabled(LogLevel.info)) return;
    final className = _className(target);
    if (!_filter(className)) return;
    write(LogLevel.info, className, message);
  }

  /// Logs a warn-level message for [target], with an optional [error] and [stackTrace].
  void warn(
    Object target,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!_enabled(LogLevel.warn)) return;
    final className = _className(target);
    if (!_filter(className)) return;
    write(LogLevel.warn, className, message, error, stackTrace);
  }

  /// Logs an error-level message for [target], with a required [error] and optional [stackTrace].
  void error(
    Object target,
    String message,
    Object? error, [
    StackTrace? stackTrace,
  ]) {
    if (!_enabled(LogLevel.error)) return;
    final className = _className(target);
    if (!_filter(className)) return;
    write(LogLevel.error, className, message, error, stackTrace);
  }
}
