import 'package:oklog/oklog.dart';
import 'package:test/test.dart';

/// A test logger that captures all written entries instead of printing them.
class _CaptureLogger extends Logger {
  final List<LogRecord> entries = [];

  _CaptureLogger();

  @override
  void write(LogEntry entry) {
    if (entry is LogRecord) entries.add(entry);
  }

  void clear() => entries.clear();
}

class _SampleClass {}

void main() {
  late _CaptureLogger logger;

  setUp(() {
    logger = _CaptureLogger();
  });

  // ---------------------------------------------------------------------------
  // LogLevel filtering
  // ---------------------------------------------------------------------------
  group('log level filtering', () {
    test('default level is debug — trace is suppressed', () {
      logger.level = LogLevel.debug;
      logger.trace('ctx', 'trace msg');
      logger.debug('ctx', 'debug msg');
      expect(logger.entries.length, 1);
      expect(logger.entries.first.level, LogLevel.debug);
    });

    test('level warn — only warn and error pass through', () {
      logger.level = LogLevel.warn;
      logger.debug('ctx', 'debug');
      logger.info('ctx', 'info');
      logger.notice('ctx', 'notice');
      logger.warn('ctx', 'warn');
      logger.error('ctx', 'error', null);
      expect(logger.entries.map((e) => e.level).toList(), [
        LogLevel.warn,
        LogLevel.error,
      ]);
    });

    test('level trace — all levels pass through', () {
      logger.level = LogLevel.trace;
      logger.trace('ctx', 't');
      logger.debug('ctx', 'd');
      logger.info('ctx', 'i');
      logger.notice('ctx', 'n');
      logger.warn('ctx', 'w');
      logger.error('ctx', 'e', null);
      expect(logger.entries.length, 6);
    });

    test('level error — only error passes through', () {
      logger.level = LogLevel.error;
      logger.warn('ctx', 'warn');
      logger.error('ctx', 'error', null);
      expect(logger.entries.length, 1);
      expect(logger.entries.first.level, LogLevel.error);
    });
  });

  // ---------------------------------------------------------------------------
  // className resolution
  // ---------------------------------------------------------------------------
  group('className resolution', () {
    test('String target is used as-is', () {
      logger.debug('MyTarget', 'msg');
      expect(logger.entries.first.className, 'MyTarget');
    });

    test('Type target uses type name', () {
      logger.debug(_SampleClass, 'msg');
      expect(logger.entries.first.className, '_SampleClass');
    });

    test('object instance uses runtimeType name', () {
      logger.debug(_SampleClass(), 'msg');
      expect(logger.entries.first.className, '_SampleClass');
    });
  });

  // ---------------------------------------------------------------------------
  // denyList
  // ---------------------------------------------------------------------------
  group('denyList', () {
    test('exact match suppresses message', () {
      logger.denyList = ['MyClass'];
      logger.debug('MyClass', 'msg');
      expect(logger.entries, isEmpty);
    });

    test('substring match suppresses message', () {
      logger.denyList = ['Class'];
      logger.debug('MyClass', 'msg');
      expect(logger.entries, isEmpty);
    });

    test('non-matching entry does not suppress', () {
      logger.denyList = ['Other'];
      logger.debug('MyClass', 'msg');
      expect(logger.entries.length, 1);
    });

    test('empty denyList suppresses nothing', () {
      logger.denyList = [];
      logger.debug('anything', 'msg');
      expect(logger.entries.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // allowList
  // ---------------------------------------------------------------------------
  group('allowList', () {
    test('matching entry allows message', () {
      logger.allowList = ['MyClass'];
      logger.debug('MyClass', 'msg');
      expect(logger.entries.length, 1);
    });

    test('non-matching entry suppresses message', () {
      logger.allowList = ['Other'];
      logger.debug('MyClass', 'msg');
      expect(logger.entries, isEmpty);
    });

    test('substring match allows message', () {
      logger.allowList = ['Class'];
      logger.debug('MyClass', 'msg');
      expect(logger.entries.length, 1);
    });

    test('empty allowList allows everything', () {
      logger.allowList = [];
      logger.debug('anything', 'msg');
      expect(logger.entries.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // denyList + allowList combined
  // ---------------------------------------------------------------------------
  group('denyList and allowList combined', () {
    test('denyList takes precedence over allowList', () {
      logger.denyList = ['MyClass'];
      logger.allowList = ['MyClass'];
      logger.debug('MyClass', 'msg');
      expect(logger.entries, isEmpty);
    });

    test('passes when in allowList and not in denyList', () {
      logger.denyList = ['Other'];
      logger.allowList = ['MyClass'];
      logger.debug('MyClass', 'msg');
      expect(logger.entries.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // error / warn carry error and stackTrace
  // ---------------------------------------------------------------------------
  group('error and stackTrace forwarding', () {
    test('warn forwards error and stackTrace', () {
      final err = Exception('oops');
      final st = StackTrace.current;
      logger.warn('ctx', 'msg', err, st);
      final entry = logger.entries.first;
      expect(entry.error, err);
      expect(entry.stackTrace, st);
    });

    test('error forwards error and stackTrace', () {
      final err = Exception('boom');
      final st = StackTrace.current;
      logger.error('ctx', 'msg', err, st);
      final entry = logger.entries.first;
      expect(entry.error, err);
      expect(entry.stackTrace, st);
    });

    test('error with null error is still written', () {
      logger.error('ctx', 'msg', null);
      expect(logger.entries.length, 1);
      expect(logger.entries.first.error, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // notice
  // ---------------------------------------------------------------------------
  group('notice', () {
    test('notice is logged when level is info', () {
      logger.level = LogLevel.info;
      logger.notice('ctx', 'notice msg');
      expect(logger.entries.length, 1);
      expect(logger.entries.first.level, LogLevel.notice);
      expect(logger.entries.first.message, 'notice msg');
    });

    test('notice is suppressed when level is warn', () {
      logger.level = LogLevel.warn;
      logger.notice('ctx', 'notice msg');
      expect(logger.entries, isEmpty);
    });

    test('notice sits between info and warn in ordering', () {
      logger.level = LogLevel.notice;
      logger.info('ctx', 'info');
      logger.notice('ctx', 'notice');
      logger.warn('ctx', 'warn');
      expect(logger.entries.map((e) => e.level).toList(), [
        LogLevel.notice,
        LogLevel.warn,
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // DummyLogger
  // ---------------------------------------------------------------------------
  group('DummyLogger', () {
    test('never throws regardless of inputs', () {
      final dummy = DummyLogger();
      expect(() {
        dummy.trace('ctx', 'msg');
        dummy.debug('ctx', 'msg');
        dummy.info('ctx', 'msg');
        dummy.notice('ctx', 'msg');
        dummy.warn('ctx', 'msg', Exception('e'), StackTrace.current);
        dummy.error('ctx', 'msg', Exception('e'), StackTrace.current);
      }, returnsNormally);
    });
  });
}
