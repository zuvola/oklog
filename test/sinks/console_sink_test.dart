import 'package:oklog/oklog.dart';
import 'package:test/test.dart';

/// A [LogFormatter] that records every entry passed to [format].
class _RecordingFormatter extends LogFormatter<String> {
  final List<LogEntry> entries = [];

  @override
  String format(LogEntry entry) {
    entries.add(entry);
    return 'formatted:${entry.className}';
  }
}

void main() {
  group('ConsoleSink', () {
    // -------------------------------------------------------------------------
    // Default formatter
    // -------------------------------------------------------------------------
    test('default formatter is ConsoleFormatter', () {
      final sink = ConsoleSink();
      expect(sink.formatter, isA<ConsoleFormatter>());
    });

    // -------------------------------------------------------------------------
    // Custom formatter
    // -------------------------------------------------------------------------
    test('custom formatter is used when provided', () {
      final customFormatter = _RecordingFormatter();
      final sink = ConsoleSink(formatter: customFormatter);

      final entry = LogRecord('MyService', LogLevel.info, 'hello');
      sink.emit(entry);

      expect(customFormatter.entries, contains(entry));
    });

    test('emit calls formatter for LogRecord', () {
      final customFormatter = _RecordingFormatter();
      final sink = ConsoleSink(formatter: customFormatter);

      final record = LogRecord('ctx', LogLevel.debug, 'msg');
      sink.emit(record);

      expect(customFormatter.entries.length, 1);
      expect(customFormatter.entries.first, record);
    });

    test('emit calls formatter for EventEntry', () {
      final customFormatter = _RecordingFormatter();
      final sink = ConsoleSink(formatter: customFormatter);

      final event = EventEntry('ctx', 'user_click');
      sink.emit(event);

      expect(customFormatter.entries.length, 1);
      expect(customFormatter.entries.first, event);
    });

    test('emit calls formatter for MetricEntry', () {
      final customFormatter = _RecordingFormatter();
      final sink = ConsoleSink(formatter: customFormatter);

      final metric = MetricEntry('ctx', 'latency', 42, unit: 'ms');
      sink.emit(metric);

      expect(customFormatter.entries.length, 1);
      expect(customFormatter.entries.first, metric);
    });

    test('formatter is called once per emit', () {
      final customFormatter = _RecordingFormatter();
      final sink = ConsoleSink(formatter: customFormatter);

      sink.emit(LogRecord('ctx', LogLevel.info, 'first'));
      sink.emit(LogRecord('ctx', LogLevel.info, 'second'));
      sink.emit(LogRecord('ctx', LogLevel.info, 'third'));

      expect(customFormatter.entries.length, 3);
    });
  });
}
