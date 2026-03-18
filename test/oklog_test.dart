import 'package:oklog/oklog.dart';
import 'package:test/test.dart';

/// A [LogSink] that captures [LogRecord] entries written through the pipeline.
class _CaptureSink extends LogSink {
  final List<LogRecord> records = [];

  @override
  void emit(LogEntry entry) {
    if (entry is LogRecord) records.add(entry);
  }

  void clear() => records.clear();
}

/// A [LogSink] that captures every [LogEntry] type.
class _CaptureAllSink extends LogSink {
  final List<LogEntry> entries = [];

  @override
  void emit(LogEntry entry) => entries.add(entry);
}

class _SampleClass {}

void main() {
  late _CaptureSink capture;
  late LevelFilterProcessor levelFilter;
  late NameFilterProcessor nameFilter;
  late Logger logger;

  setUp(() {
    capture = _CaptureSink();
    levelFilter = LevelFilterProcessor(minLevel: LogLevel.debug);
    nameFilter = NameFilterProcessor();
    logger = Logger(processors: [levelFilter, nameFilter], sinks: [capture]);
  });

  // ---------------------------------------------------------------------------
  // LogLevel filtering
  // ---------------------------------------------------------------------------
  group('log level filtering', () {
    test('default level is debug — trace is suppressed', () {
      logger.trace('ctx', 'trace msg');
      logger.debug('ctx', 'debug msg');
      expect(capture.records.length, 1);
      expect(capture.records.first.level, LogLevel.debug);
    });

    test('level warn — only warn and error pass through', () {
      levelFilter.minLevel = LogLevel.warn;
      logger.debug('ctx', 'debug');
      logger.info('ctx', 'info');
      logger.notice('ctx', 'notice');
      logger.warn('ctx', 'warn');
      logger.error('ctx', 'error');
      expect(capture.records.map((e) => e.level).toList(), [
        LogLevel.warn,
        LogLevel.error,
      ]);
    });

    test('level trace — all levels pass through', () {
      levelFilter.minLevel = LogLevel.trace;
      logger.trace('ctx', 't');
      logger.debug('ctx', 'd');
      logger.info('ctx', 'i');
      logger.notice('ctx', 'n');
      logger.warn('ctx', 'w');
      logger.error('ctx', 'e');
      expect(capture.records.length, 6);
    });

    test('level error — only error passes through', () {
      levelFilter.minLevel = LogLevel.error;
      logger.warn('ctx', 'warn');
      logger.error('ctx', 'error');
      expect(capture.records.length, 1);
      expect(capture.records.first.level, LogLevel.error);
    });
  });

  // ---------------------------------------------------------------------------
  // className resolution
  // ---------------------------------------------------------------------------
  group('className resolution', () {
    test('String target is used as-is', () {
      logger.debug('MyTarget', 'msg');
      expect(capture.records.first.className, 'MyTarget');
    });

    test('Type target uses type name', () {
      logger.debug(_SampleClass, 'msg');
      expect(capture.records.first.className, '_SampleClass');
    });

    test('object instance uses runtimeType name', () {
      logger.debug(_SampleClass(), 'msg');
      expect(capture.records.first.className, '_SampleClass');
    });
  });

  // ---------------------------------------------------------------------------
  // denyList (NameFilterProcessor)
  // ---------------------------------------------------------------------------
  group('denyList', () {
    test('exact match suppresses message', () {
      nameFilter.denyList = ['MyClass'];
      logger.debug('MyClass', 'msg');
      expect(capture.records, isEmpty);
    });

    test('substring match suppresses message', () {
      nameFilter.denyList = ['Class'];
      logger.debug('MyClass', 'msg');
      expect(capture.records, isEmpty);
    });

    test('non-matching entry does not suppress', () {
      nameFilter.denyList = ['Other'];
      logger.debug('MyClass', 'msg');
      expect(capture.records.length, 1);
    });

    test('empty denyList suppresses nothing', () {
      nameFilter.denyList = [];
      logger.debug('anything', 'msg');
      expect(capture.records.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // allowList (NameFilterProcessor)
  // ---------------------------------------------------------------------------
  group('allowList', () {
    test('matching entry allows message', () {
      nameFilter.allowList = ['MyClass'];
      logger.debug('MyClass', 'msg');
      expect(capture.records.length, 1);
    });

    test('non-matching entry suppresses message', () {
      nameFilter.allowList = ['Other'];
      logger.debug('MyClass', 'msg');
      expect(capture.records, isEmpty);
    });

    test('substring match allows message', () {
      nameFilter.allowList = ['Class'];
      logger.debug('MyClass', 'msg');
      expect(capture.records.length, 1);
    });

    test('empty allowList allows everything', () {
      nameFilter.allowList = [];
      logger.debug('anything', 'msg');
      expect(capture.records.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // denyList + allowList combined
  // ---------------------------------------------------------------------------
  group('denyList and allowList combined', () {
    test('denyList takes precedence over allowList', () {
      nameFilter.denyList = ['MyClass'];
      nameFilter.allowList = ['MyClass'];
      logger.debug('MyClass', 'msg');
      expect(capture.records, isEmpty);
    });

    test('passes when in allowList and not in denyList', () {
      nameFilter.denyList = ['Other'];
      nameFilter.allowList = ['MyClass'];
      logger.debug('MyClass', 'msg');
      expect(capture.records.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // error / warn carry error and stackTrace
  // ---------------------------------------------------------------------------
  group('error and stackTrace forwarding', () {
    test('warn forwards error and stackTrace', () {
      final err = Exception('oops');
      final st = StackTrace.current;
      logger.warn('ctx', 'msg', error: err, stackTrace: st);
      final entry = capture.records.first;
      expect(entry.error, err);
      expect(entry.stackTrace, st);
    });

    test('error forwards error and stackTrace', () {
      final err = Exception('boom');
      final st = StackTrace.current;
      logger.error('ctx', 'msg', error: err, stackTrace: st);
      final entry = capture.records.first;
      expect(entry.error, err);
      expect(entry.stackTrace, st);
    });

    test('error with null error is still written', () {
      logger.error('ctx', 'msg');
      expect(capture.records.length, 1);
      expect(capture.records.first.error, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // notice
  // ---------------------------------------------------------------------------
  group('notice', () {
    test('notice is logged when level is info', () {
      levelFilter.minLevel = LogLevel.info;
      logger.notice('ctx', 'notice msg');
      expect(capture.records.length, 1);
      expect(capture.records.first.level, LogLevel.notice);
      expect(capture.records.first.message, 'notice msg');
    });

    test('notice is suppressed when level is warn', () {
      levelFilter.minLevel = LogLevel.warn;
      logger.notice('ctx', 'notice msg');
      expect(capture.records, isEmpty);
    });

    test('notice sits between info and warn in ordering', () {
      levelFilter.minLevel = LogLevel.notice;
      logger.info('ctx', 'info');
      logger.notice('ctx', 'notice');
      logger.warn('ctx', 'warn');
      expect(capture.records.map((e) => e.level).toList(), [
        LogLevel.notice,
        LogLevel.warn,
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  // attributes
  // ---------------------------------------------------------------------------
  group('attrs', () {
    test('attrs are stored on LogRecord', () {
      logger.debug('ctx', 'msg', attrs: {'userId': 123, 'env': 'prod'});
      expect(capture.records.first.attrs, {'userId': 123, 'env': 'prod'});
    });

    test('attrs default to null when not provided', () {
      logger.info('ctx', 'msg');
      expect(capture.records.first.attrs, isNull);
    });

    test('attrs are forwarded for all log levels', () {
      final attrs = {'key': 'value'};
      levelFilter.minLevel = LogLevel.trace;
      logger.trace('ctx', 'msg', attrs: attrs);
      logger.debug('ctx', 'msg', attrs: attrs);
      logger.info('ctx', 'msg', attrs: attrs);
      logger.notice('ctx', 'msg', attrs: attrs);
      for (final entry in capture.records) {
        expect(entry.attrs, attrs);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // ContextBufferProcessor
  // ---------------------------------------------------------------------------
  group('ContextBufferProcessor', () {
    test('stores records up to capacity', () {
      final buffer = ContextBufferProcessor(3);
      final bufLogger = Logger(processors: [buffer], sinks: [capture]);
      bufLogger.info('ctx', 'a');
      bufLogger.info('ctx', 'b');
      bufLogger.info('ctx', 'c');
      expect(buffer.getRecent().map((r) => r.message).toList(), [
        'a',
        'b',
        'c',
      ]);
    });

    test('ring buffer overwrites oldest when full', () {
      final buffer = ContextBufferProcessor(3);
      final bufLogger = Logger(processors: [buffer], sinks: [capture]);
      bufLogger.info('ctx', 'a');
      bufLogger.info('ctx', 'b');
      bufLogger.info('ctx', 'c');
      bufLogger.info('ctx', 'd');
      expect(buffer.getRecent().map((r) => r.message).toList(), [
        'b',
        'c',
        'd',
      ]);
    });

    test('getRecent returns empty list when no records written', () {
      final buffer = ContextBufferProcessor();
      expect(buffer.getRecent(), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // ErrorAlertSink
  // ---------------------------------------------------------------------------
  group('ErrorAlertSink', () {
    test('notifies exporter only on error level', () {
      final exportedErrors = <LogRecord>[];
      final exportedContexts = <List<LogRecord>>[];

      final buffer = ContextBufferProcessor();
      final errorSink = ErrorAlertSink(
        buffer,
        _TestExporter(exportedErrors, exportedContexts),
      );
      final alertLogger = Logger(processors: [buffer], sinks: [errorSink]);

      alertLogger.info('ctx', 'info msg');
      alertLogger.warn('ctx', 'warn msg');
      expect(exportedErrors, isEmpty);

      alertLogger.error('ctx', 'error msg', error: Exception('boom'));
      expect(exportedErrors.length, 1);
      expect(exportedErrors.first.level, LogLevel.error);
    });

    test('passes context buffer records to exporter', () {
      final exportedContexts = <List<LogRecord>>[];

      final buffer = ContextBufferProcessor();
      final errorSink = ErrorAlertSink(
        buffer,
        _TestExporter([], exportedContexts),
      );
      final alertLogger = Logger(processors: [buffer], sinks: [errorSink]);

      alertLogger.info('ctx', 'msg1');
      alertLogger.info('ctx', 'msg2');
      alertLogger.error('ctx', 'error', error: Exception());

      expect(exportedContexts.length, 1);
      final ctx = exportedContexts.first;
      // buffer holds all 3 records (including the error itself)
      expect(ctx.map((r) => r.message), containsAll(['msg1', 'msg2', 'error']));
    });
  });

  // ---------------------------------------------------------------------------
  // ObservabilityLogger (obs) integration
  // ---------------------------------------------------------------------------
  group('obs integration', () {
    late _CaptureAllSink capture;
    late Logger logger;

    setUp(() {
      capture = _CaptureAllSink();
      logger = Logger(sinks: [capture]);
    });

    test('obs.event emits EventEntry through the full pipeline', () {
      logger.obs.event('ctx', 'user_login');
      expect(capture.entries.length, 1);
      expect(capture.entries.first, isA<EventEntry>());
    });

    test('obs.event stores className, message, data, and attrs', () {
      logger.obs.event(
        'MyService',
        'purchase',
        data: {'amount': 99},
        attrs: {'env': 'prod'},
      );
      final e = capture.entries.first as EventEntry;
      expect(e.className, 'MyService');
      expect(e.message, 'purchase');
      expect(e.data, {'amount': 99});
      expect(e.attrs, {'env': 'prod'});
    });

    test('obs.metric emits MetricEntry through the full pipeline', () {
      logger.obs.metric('ctx', 'latency', 42);
      expect(capture.entries.length, 1);
      expect(capture.entries.first, isA<MetricEntry>());
    });

    test('obs.metric stores className, name, value, unit, and attrs', () {
      logger.obs.metric(
        'MyService',
        'response_time',
        120,
        unit: 'ms',
        attrs: {'region': 'us-east'},
      );
      final m = capture.entries.first as MetricEntry;
      expect(m.className, 'MyService');
      expect(m.name, 'response_time');
      expect(m.value, 120);
      expect(m.unit, 'ms');
      expect(m.attrs, {'region': 'us-east'});
    });

    test('obs entries are blocked by a processor returning false', () {
      final logger = Logger(
        processors: [LevelFilterProcessor(minLevel: LogLevel.error)],
        sinks: [capture],
      );
      // EventEntry and MetricEntry always pass LevelFilterProcessor
      logger.obs.event('ctx', 'click');
      logger.obs.metric('ctx', 'cpu', 0.5);
      expect(capture.entries.length, 2);
    });

    test('obs and log entries flow through the same pipeline', () {
      logger.debug('ctx', 'log msg');
      logger.obs.event('ctx', 'event');
      logger.obs.metric('ctx', 'count', 1);

      expect(capture.entries.length, 3);
      expect(capture.entries[0], isA<LogRecord>());
      expect(capture.entries[1], isA<EventEntry>());
      expect(capture.entries[2], isA<MetricEntry>());
    });
  });
}

class _TestExporter implements ErrorExporter {
  final List<LogRecord> errors;
  final List<List<LogRecord>> contexts;

  _TestExporter(this.errors, this.contexts);

  @override
  Future<void> send(
    LogRecord error,
    List<LogRecord> contextLogs,
    Map<String, String> metadata,
  ) async {
    errors.add(error);
    contexts.add(contextLogs);
  }
}
