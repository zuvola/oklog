import 'package:oklog/oklog.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // LogLevel
  // ---------------------------------------------------------------------------
  group('LogLevel', () {
    test(
      'has six values in order: trace, debug, info, notice, warn, error',
      () {
        expect(LogLevel.values, [
          LogLevel.trace,
          LogLevel.debug,
          LogLevel.info,
          LogLevel.notice,
          LogLevel.warn,
          LogLevel.error,
        ]);
      },
    );

    test('trace is less severe than debug', () {
      expect(LogLevel.trace.index, lessThan(LogLevel.debug.index));
    });

    test('debug is less severe than info', () {
      expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
    });

    test('info is less severe than notice', () {
      expect(LogLevel.info.index, lessThan(LogLevel.notice.index));
    });

    test('notice is less severe than warn', () {
      expect(LogLevel.notice.index, lessThan(LogLevel.warn.index));
    });

    test('warn is less severe than error', () {
      expect(LogLevel.warn.index, lessThan(LogLevel.error.index));
    });
  });

  // ---------------------------------------------------------------------------
  // LogEntry.resolveClassName
  // ---------------------------------------------------------------------------
  group('LogEntry.resolveClassName', () {
    test('String is used as-is', () {
      expect(LogEntry.resolveClassName('MyService'), 'MyService');
    });

    test('empty string is preserved', () {
      expect(LogEntry.resolveClassName(''), '');
    });

    test('Type literal resolves to type name string', () {
      expect(LogEntry.resolveClassName(String), 'String');
      expect(LogEntry.resolveClassName(int), 'int');
    });

    test('object instance resolves to runtimeType name', () {
      expect(LogEntry.resolveClassName(42), 'int');
      expect(LogEntry.resolveClassName([1, 2, 3]), 'List<int>');
    });
  });

  // ---------------------------------------------------------------------------
  // LogRecord
  // ---------------------------------------------------------------------------
  group('LogRecord', () {
    test('stores className resolved from source', () {
      final r = LogRecord('MyClass', LogLevel.info, 'msg');
      expect(r.className, 'MyClass');
    });

    test('stores level', () {
      final r = LogRecord('ctx', LogLevel.warn, 'msg');
      expect(r.level, LogLevel.warn);
    });

    test('stores message', () {
      final r = LogRecord('ctx', LogLevel.debug, 'hello');
      expect(r.message, 'hello');
    });

    test('error defaults to null', () {
      final r = LogRecord('ctx', LogLevel.info, 'msg');
      expect(r.error, isNull);
    });

    test('stackTrace defaults to null', () {
      final r = LogRecord('ctx', LogLevel.info, 'msg');
      expect(r.stackTrace, isNull);
    });

    test('attrs defaults to null', () {
      final r = LogRecord('ctx', LogLevel.info, 'msg');
      expect(r.attrs, isNull);
    });

    test('stores error when provided', () {
      final err = Exception('oops');
      final r = LogRecord('ctx', LogLevel.error, 'msg', err);
      expect(r.error, err);
    });

    test('stores stackTrace when provided', () {
      final st = StackTrace.current;
      final r = LogRecord('ctx', LogLevel.error, 'msg', null, st);
      expect(r.stackTrace, st);
    });

    test('stores attrs when provided', () {
      final attrs = {'key': 'value', 'count': 1};
      final r = LogRecord('ctx', LogLevel.info, 'msg', null, null, attrs);
      expect(r.attrs, attrs);
    });

    test('timestamp is set at construction time', () {
      final before = DateTime.now();
      final r = LogRecord('ctx', LogLevel.info, 'msg');
      final after = DateTime.now();
      expect(
        r.timestamp.isAfter(before) || r.timestamp.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        r.timestamp.isBefore(after) || r.timestamp.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('resolves Type source to type name', () {
      final r = LogRecord(String, LogLevel.info, 'msg');
      expect(r.className, 'String');
    });

    test('resolves object instance source to runtimeType name', () {
      final r = LogRecord(42, LogLevel.info, 'msg');
      expect(r.className, 'int');
    });
  });

  // ---------------------------------------------------------------------------
  // EventEntry
  // ---------------------------------------------------------------------------
  group('EventEntry', () {
    test('stores className resolved from source', () {
      final e = EventEntry('MyService', 'user_login');
      expect(e.className, 'MyService');
    });

    test('stores message', () {
      final e = EventEntry('ctx', 'purchase_completed');
      expect(e.message, 'purchase_completed');
    });

    test('data defaults to null', () {
      final e = EventEntry('ctx', 'event');
      expect(e.data, isNull);
    });

    test('attrs defaults to null', () {
      final e = EventEntry('ctx', 'event');
      expect(e.attrs, isNull);
    });

    test('stores data when provided', () {
      final e = EventEntry('ctx', 'purchase', data: {'amount': 100});
      expect(e.data, {'amount': 100});
    });

    test('stores attrs when provided', () {
      final e = EventEntry('ctx', 'event', attrs: {'env': 'prod'});
      expect(e.attrs, {'env': 'prod'});
    });

    test('timestamp is set at construction time', () {
      final before = DateTime.now();
      final e = EventEntry('ctx', 'event');
      final after = DateTime.now();
      expect(
        e.timestamp.isAfter(before) || e.timestamp.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        e.timestamp.isBefore(after) || e.timestamp.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // MetricEntry
  // ---------------------------------------------------------------------------
  group('MetricEntry', () {
    test('stores className resolved from source', () {
      final m = MetricEntry('MyService', 'latency', 42);
      expect(m.className, 'MyService');
    });

    test('stores name', () {
      final m = MetricEntry('ctx', 'response_time', 120);
      expect(m.name, 'response_time');
    });

    test('stores integer value', () {
      final m = MetricEntry('ctx', 'count', 5);
      expect(m.value, 5);
    });

    test('stores double value', () {
      final m = MetricEntry('ctx', 'cpu', 0.75);
      expect(m.value, 0.75);
    });

    test('unit defaults to null', () {
      final m = MetricEntry('ctx', 'count', 5);
      expect(m.unit, isNull);
    });

    test('attrs defaults to null', () {
      final m = MetricEntry('ctx', 'count', 5);
      expect(m.attrs, isNull);
    });

    test('stores unit when provided', () {
      final m = MetricEntry('ctx', 'latency', 42, unit: 'ms');
      expect(m.unit, 'ms');
    });

    test('stores attrs when provided', () {
      final m = MetricEntry('ctx', 'latency', 42, attrs: {'region': 'us-east'});
      expect(m.attrs, {'region': 'us-east'});
    });

    test('timestamp is set at construction time', () {
      final before = DateTime.now();
      final m = MetricEntry('ctx', 'count', 1);
      final after = DateTime.now();
      expect(
        m.timestamp.isAfter(before) || m.timestamp.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        m.timestamp.isBefore(after) || m.timestamp.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });
}
