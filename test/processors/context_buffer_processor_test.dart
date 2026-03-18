import 'package:oklog/oklog.dart';
import 'package:test/test.dart';

void main() {
  group('ContextBufferProcessor', () {
    // -------------------------------------------------------------------------
    // Default behavior
    // -------------------------------------------------------------------------
    test('default capacity is 20', () {
      final processor = ContextBufferProcessor();
      expect(processor.capacity, 20);
    });

    test('empty buffer returns empty list', () {
      final processor = ContextBufferProcessor(5);
      expect(processor.getRecent(), isEmpty);
    });

    // -------------------------------------------------------------------------
    // Ring buffer
    // -------------------------------------------------------------------------
    test('stores entries up to capacity in chronological order', () {
      final processor = ContextBufferProcessor(3);
      final r1 = LogRecord('ctx', LogLevel.info, 'msg1');
      final r2 = LogRecord('ctx', LogLevel.info, 'msg2');
      final r3 = LogRecord('ctx', LogLevel.info, 'msg3');

      processor.process(r1);
      processor.process(r2);
      processor.process(r3);

      expect(processor.getRecent(), [r1, r2, r3]);
    });

    test('oldest entry is overwritten when capacity is exceeded', () {
      final processor = ContextBufferProcessor(3);
      final r1 = LogRecord('ctx', LogLevel.info, 'msg1');
      final r2 = LogRecord('ctx', LogLevel.info, 'msg2');
      final r3 = LogRecord('ctx', LogLevel.info, 'msg3');
      final r4 = LogRecord('ctx', LogLevel.info, 'msg4');

      processor.process(r1);
      processor.process(r2);
      processor.process(r3);
      processor.process(r4); // r1 should be dropped

      final recent = processor.getRecent();
      expect(recent, [r2, r3, r4]);
    });

    test('getRecent returns entries in chronological order after wrap', () {
      final processor = ContextBufferProcessor(3);
      final entries = List.generate(
        6,
        (i) => LogRecord('ctx', LogLevel.info, 'msg$i'),
      );
      for (final e in entries) {
        processor.process(e);
      }

      // capacity=3, 6 entries added → last 3 should remain
      final recent = processor.getRecent();
      expect(recent.map((r) => r.message).toList(), ['msg3', 'msg4', 'msg5']);
    });

    test('single entry buffer retains only the latest entry', () {
      final processor = ContextBufferProcessor(1);
      final r1 = LogRecord('ctx', LogLevel.info, 'first');
      final r2 = LogRecord('ctx', LogLevel.info, 'second');

      processor.process(r1);
      processor.process(r2);

      expect(processor.getRecent(), [r2]);
    });

    // -------------------------------------------------------------------------
    // Non-LogRecord entries are not buffered
    // -------------------------------------------------------------------------
    test('EventEntry passes through without being stored', () {
      final processor = ContextBufferProcessor(5);
      final event = EventEntry('ctx', 'user_login');

      final result = processor.process(event);

      expect(result, isTrue);
      expect(processor.getRecent(), isEmpty);
    });

    test('MetricEntry passes through without being stored', () {
      final processor = ContextBufferProcessor(5);
      final metric = MetricEntry('ctx', 'response_time', 42);

      final result = processor.process(metric);

      expect(result, isTrue);
      expect(processor.getRecent(), isEmpty);
    });

    test('non-LogRecord entries do not affect buffer position', () {
      final processor = ContextBufferProcessor(3);
      final r1 = LogRecord('ctx', LogLevel.info, 'log1');
      final event = EventEntry('ctx', 'click');
      final r2 = LogRecord('ctx', LogLevel.info, 'log2');

      processor.process(r1);
      processor.process(event);
      processor.process(r2);

      expect(processor.getRecent(), [r1, r2]);
    });

    // -------------------------------------------------------------------------
    // Return value of process()
    // -------------------------------------------------------------------------
    test('process() always returns true for LogRecord', () {
      final processor = ContextBufferProcessor(3);
      final result = processor.process(LogRecord('ctx', LogLevel.debug, 'msg'));
      expect(result, isTrue);
    });

    // -------------------------------------------------------------------------
    // Edge case: capacity=1
    // -------------------------------------------------------------------------
    test('capacity 1 with multiple entries only keeps the last', () {
      final processor = ContextBufferProcessor(1);
      for (var i = 0; i < 5; i++) {
        processor.process(LogRecord('ctx', LogLevel.info, 'msg$i'));
      }
      final recent = processor.getRecent();
      expect(recent.length, 1);
      expect(recent.first.message, 'msg4');
    });
  });
}
