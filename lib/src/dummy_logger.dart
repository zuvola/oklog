import 'logger.dart';

/// A no-op logger that discards all log messages.
///
/// Useful in tests or environments where logging should be silenced entirely.
class DummyLogger extends Logger {
  @override
  void write(LogEntry entry) {}
}
