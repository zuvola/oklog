import 'package:oklog/oklog.dart';
import 'package:test/test.dart';

void main() {
  group('LevelFilterProcessor', () {
    // -------------------------------------------------------------------------
    // Default value
    // -------------------------------------------------------------------------
    test('default minLevel is debug', () {
      final processor = LevelFilterProcessor();
      expect(processor.minLevel, LogLevel.debug);
    });

    // -------------------------------------------------------------------------
    // Per-level filtering
    // -------------------------------------------------------------------------
    group('minLevel=debug', () {
      late LevelFilterProcessor processor;
      setUp(() => processor = LevelFilterProcessor(minLevel: LogLevel.debug));

      test('trace is blocked', () {
        expect(
          processor.process(LogRecord('ctx', LogLevel.trace, 'msg')),
          isFalse,
        );
      });

      test('debug passes through', () {
        expect(
          processor.process(LogRecord('ctx', LogLevel.debug, 'msg')),
          isTrue,
        );
      });

      test('info passes through', () {
        expect(
          processor.process(LogRecord('ctx', LogLevel.info, 'msg')),
          isTrue,
        );
      });
    });

    group('minLevel=warn', () {
      late LevelFilterProcessor processor;
      setUp(() => processor = LevelFilterProcessor(minLevel: LogLevel.warn));

      test('trace is blocked', () {
        expect(
          processor.process(LogRecord('ctx', LogLevel.trace, 'msg')),
          isFalse,
        );
      });

      test('debug is blocked', () {
        expect(
          processor.process(LogRecord('ctx', LogLevel.debug, 'msg')),
          isFalse,
        );
      });

      test('info is blocked', () {
        expect(
          processor.process(LogRecord('ctx', LogLevel.info, 'msg')),
          isFalse,
        );
      });

      test('notice is blocked', () {
        expect(
          processor.process(LogRecord('ctx', LogLevel.notice, 'msg')),
          isFalse,
        );
      });

      test('warn passes through', () {
        expect(
          processor.process(LogRecord('ctx', LogLevel.warn, 'msg')),
          isTrue,
        );
      });

      test('error passes through', () {
        expect(
          processor.process(LogRecord('ctx', LogLevel.error, 'msg')),
          isTrue,
        );
      });
    });

    group('minLevel=trace', () {
      late LevelFilterProcessor processor;
      setUp(() => processor = LevelFilterProcessor(minLevel: LogLevel.trace));

      test('all levels pass through', () {
        for (final level in LogLevel.values) {
          expect(
            processor.process(LogRecord('ctx', level, 'msg')),
            isTrue,
            reason: '$level should pass',
          );
        }
      });
    });

    group('minLevel=error', () {
      late LevelFilterProcessor processor;
      setUp(() => processor = LevelFilterProcessor(minLevel: LogLevel.error));

      test('only error passes through', () {
        for (final level in LogLevel.values) {
          final result = processor.process(LogRecord('ctx', level, 'msg'));
          if (level == LogLevel.error) {
            expect(result, isTrue, reason: 'error should pass');
          } else {
            expect(result, isFalse, reason: '$level should be blocked');
          }
        }
      });
    });

    // -------------------------------------------------------------------------
    // Non-LogRecord entries always pass through
    // -------------------------------------------------------------------------
    test('EventEntry always passes through regardless of minLevel', () {
      final processor = LevelFilterProcessor(minLevel: LogLevel.error);
      expect(processor.process(EventEntry('ctx', 'click')), isTrue);
    });

    test('MetricEntry always passes through regardless of minLevel', () {
      final processor = LevelFilterProcessor(minLevel: LogLevel.error);
      expect(
        processor.process(MetricEntry('ctx', 'response_time', 100)),
        isTrue,
      );
    });

    // -------------------------------------------------------------------------
    // Dynamic minLevel change
    // -------------------------------------------------------------------------
    test('minLevel can be changed at runtime', () {
      final processor = LevelFilterProcessor(minLevel: LogLevel.error);
      final record = LogRecord('ctx', LogLevel.debug, 'msg');

      expect(processor.process(record), isFalse);

      processor.minLevel = LogLevel.trace;
      expect(processor.process(record), isTrue);
    });
  });
}
