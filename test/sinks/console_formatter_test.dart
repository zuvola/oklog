import 'package:oklog/oklog.dart';
import 'package:test/test.dart';

void main() {
  late ConsoleFormatter formatter;

  setUp(() => formatter = ConsoleFormatter());

  // -------------------------------------------------------------------------
  // LogRecord formatting
  // -------------------------------------------------------------------------
  group('LogRecord formatting', () {
    test('output contains className and message', () {
      final entry = LogRecord('MyService', LogLevel.info, 'hello world');
      final result = formatter.format(entry);
      expect(result, contains('MyService'));
      expect(result, contains('hello world'));
    });

    test('output contains the log level icon for each level', () {
      final icons = ['🐾', '🛠️', '💬', '🔔', '⚠️', '❌'];
      for (var i = 0; i < LogLevel.values.length; i++) {
        final entry = LogRecord('ctx', LogLevel.values[i], 'msg');
        expect(
          formatter.format(entry),
          contains(icons[i]),
          reason: 'Expected icon for ${LogLevel.values[i]}',
        );
      }
    });

    test('multiline message has newlines replaced with spaces', () {
      final entry = LogRecord('ctx', LogLevel.info, 'line1\nline2\nline3');
      final result = formatter.format(entry);
      expect(result, contains('line1 line2 line3'));
      expect(result, isNot(contains('\n')));
    });

    test('output contains attrs when provided', () {
      final entry = LogRecord('ctx', LogLevel.info, 'msg', null, null, {
        'userId': 'u1',
        'env': 'prod',
      });
      final result = formatter.format(entry);
      expect(result, contains('userId'));
      expect(result, contains('env'));
    });

    test('attrs section is absent when attrs is null', () {
      final entry = LogRecord('ctx', LogLevel.info, 'msg');
      final result = formatter.format(entry);
      expect(result, isNot(contains('attrs:')));
    });

    test('attrs section is absent when attrs is empty', () {
      final entry = LogRecord('ctx', LogLevel.info, 'msg', null, null, {});
      final result = formatter.format(entry);
      expect(result, isNot(contains('attrs:')));
    });

    test('error info is included when error is provided', () {
      final err = Exception('something broke');
      final entry = LogRecord('ctx', LogLevel.error, 'msg', err);
      final result = formatter.format(entry);
      expect(result, contains('Error:'));
      expect(result, contains('something broke'));
    });

    test('stackTrace is included when stackTrace is provided', () {
      final st = StackTrace.current;
      final entry = LogRecord('ctx', LogLevel.error, 'msg', null, st);
      final result = formatter.format(entry);
      expect(result, contains(st.toString()));
    });

    test('error section is absent when error and stackTrace are null', () {
      final entry = LogRecord('ctx', LogLevel.warn, 'msg');
      final result = formatter.format(entry);
      expect(result, isNot(contains('Error:')));
    });

    test('output contains timestamp in brackets', () {
      final entry = LogRecord('ctx', LogLevel.debug, 'msg');
      final result = formatter.format(entry);
      // Timestamp is wrapped in brackets
      expect(result, contains('['));
      expect(result, contains(']'));
    });
  });

  // -------------------------------------------------------------------------
  // EventEntry formatting
  // -------------------------------------------------------------------------
  group('EventEntry formatting', () {
    test('output contains [EVENT] prefix', () {
      final entry = EventEntry('MyService', 'user_login');
      expect(formatter.format(entry), contains('[EVENT]'));
    });

    test('output contains className and message', () {
      final entry = EventEntry('MyService', 'user_login');
      final result = formatter.format(entry);
      expect(result, contains('MyService'));
      expect(result, contains('user_login'));
    });

    test('output contains 📡 emoji', () {
      final entry = EventEntry('ctx', 'event');
      expect(formatter.format(entry), contains('📡'));
    });

    test('data is included in output when provided', () {
      final entry = EventEntry(
        'ctx',
        'purchase',
        data: {'amount': 100, 'currency': 'USD'},
      );
      final result = formatter.format(entry);
      expect(result, contains('amount'));
      expect(result, contains('USD'));
    });

    test('data section is absent when data is null', () {
      final entry = EventEntry('ctx', 'event');
      final result = formatter.format(entry);
      // Verify that ' : {data}' is not appended when data is null
      expect(result, isNot(contains(' : {')));
    });

    test('attrs are included in output when provided', () {
      final entry = EventEntry('ctx', 'event', attrs: {'requestId': 'req-1'});
      final result = formatter.format(entry);
      expect(result, contains('requestId'));
    });
  });

  // -------------------------------------------------------------------------
  // MetricEntry formatting
  // -------------------------------------------------------------------------
  group('MetricEntry formatting', () {
    test('output contains [METRIC] prefix', () {
      final entry = MetricEntry('MyService', 'response_time', 120);
      expect(formatter.format(entry), contains('[METRIC]'));
    });

    test('output contains className, name, and value', () {
      final entry = MetricEntry('MyService', 'response_time', 120);
      final result = formatter.format(entry);
      expect(result, contains('MyService'));
      expect(result, contains('response_time'));
      expect(result, contains('120'));
    });

    test('output contains 📊 emoji', () {
      final entry = MetricEntry('ctx', 'cpu', 0.75);
      expect(formatter.format(entry), contains('📊'));
    });

    test('unit is included in output when provided', () {
      final entry = MetricEntry('ctx', 'response_time', 120, unit: 'ms');
      final result = formatter.format(entry);
      expect(result, contains('[ms]'));
    });

    test('unit section is absent when unit is null', () {
      final entry = MetricEntry('ctx', 'count', 5);
      final result = formatter.format(entry);
      // Verify that no [unit] block is appended when unit is null
      expect(result, isNot(contains('[count]')));
      expect(result, isNot(contains('[null]')));
    });

    test('unit section is absent when unit is empty string', () {
      final entry = MetricEntry('ctx', 'count', 5, unit: '');
      final result = formatter.format(entry);
      expect(result, isNot(contains('[]')));
    });

    test('attrs are included in output when provided', () {
      final entry = MetricEntry(
        'ctx',
        'latency',
        42,
        attrs: {'region': 'us-east'},
      );
      final result = formatter.format(entry);
      expect(result, contains('region'));
    });
  });
}
