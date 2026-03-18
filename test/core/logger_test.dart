import 'package:oklog/oklog.dart';
import 'package:test/test.dart';

/// Captures every [LogEntry] emitted through the pipeline.
class _CaptureSink extends LogSink {
  final List<LogEntry> entries = [];

  @override
  void emit(LogEntry entry) => entries.add(entry);
}

/// A processor that always allows entries through.
class _PassProcessor implements LogProcessor {
  int callCount = 0;

  @override
  bool process(LogEntry entry) {
    callCount++;
    return true;
  }
}

/// A processor that always drops entries.
class _DropProcessor implements LogProcessor {
  int callCount = 0;

  @override
  bool process(LogEntry entry) {
    callCount++;
    return false;
  }
}

void main() {
  // ---------------------------------------------------------------------------
  // Logger pipeline
  // ---------------------------------------------------------------------------
  group('Logger pipeline', () {
    test('entry reaches sink when no processors are configured', () {
      final sink = _CaptureSink();
      final logger = Logger(sinks: [sink]);
      final record = LogRecord('ctx', LogLevel.info, 'hello');

      logger.emit(record);

      expect(sink.entries, [record]);
    });

    test('entry reaches all sinks when multiple sinks are configured', () {
      final sink1 = _CaptureSink();
      final sink2 = _CaptureSink();
      final logger = Logger(sinks: [sink1, sink2]);
      final record = LogRecord('ctx', LogLevel.info, 'msg');

      logger.emit(record);

      expect(sink1.entries, [record]);
      expect(sink2.entries, [record]);
    });

    test('entry is dropped when a processor returns false', () {
      final sink = _CaptureSink();
      final logger = Logger(processors: [_DropProcessor()], sinks: [sink]);

      logger.emit(LogRecord('ctx', LogLevel.info, 'msg'));

      expect(sink.entries, isEmpty);
    });

    test('entry reaches sink when all processors return true', () {
      final sink = _CaptureSink();
      final logger = Logger(
        processors: [_PassProcessor(), _PassProcessor()],
        sinks: [sink],
      );
      final record = LogRecord('ctx', LogLevel.info, 'msg');

      logger.emit(record);

      expect(sink.entries, [record]);
    });

    test('pipeline stops after first processor that returns false', () {
      final drop = _DropProcessor();
      final pass = _PassProcessor();
      final sink = _CaptureSink();
      final logger = Logger(processors: [drop, pass], sinks: [sink]);

      logger.emit(LogRecord('ctx', LogLevel.info, 'msg'));

      expect(drop.callCount, 1);
      expect(pass.callCount, 0); // second processor never reached
      expect(sink.entries, isEmpty);
    });

    test('no error when no sinks are configured', () {
      final logger = Logger();
      expect(
        () => logger.emit(LogRecord('ctx', LogLevel.info, 'msg')),
        returnsNormally,
      );
    });

    test('processors list is empty by default', () {
      expect(Logger().processors, isEmpty);
    });

    test('sinks list is empty by default', () {
      expect(Logger().sinks, isEmpty);
    });

    test('processors and sinks can be mutated after construction', () {
      final logger = Logger();
      final sink = _CaptureSink();
      final pass = _PassProcessor();

      logger.processors.add(pass);
      logger.sinks.add(sink);

      logger.emit(LogRecord('ctx', LogLevel.debug, 'msg'));

      expect(pass.callCount, 1);
      expect(sink.entries.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Logger convenience log methods
  // ---------------------------------------------------------------------------
  group('Logger log methods', () {
    late _CaptureSink sink;
    late Logger logger;

    setUp(() {
      sink = _CaptureSink();
      logger = Logger(sinks: [sink]);
    });

    test('trace() emits LogRecord with trace level', () {
      logger.trace('ctx', 'msg');
      final r = sink.entries.first as LogRecord;
      expect(r.level, LogLevel.trace);
      expect(r.message, 'msg');
    });

    test('debug() emits LogRecord with debug level', () {
      logger.debug('ctx', 'msg');
      expect((sink.entries.first as LogRecord).level, LogLevel.debug);
    });

    test('info() emits LogRecord with info level', () {
      logger.info('ctx', 'msg');
      expect((sink.entries.first as LogRecord).level, LogLevel.info);
    });

    test('notice() emits LogRecord with notice level', () {
      logger.notice('ctx', 'msg');
      expect((sink.entries.first as LogRecord).level, LogLevel.notice);
    });

    test('warn() emits LogRecord with warn level', () {
      logger.warn('ctx', 'msg');
      expect((sink.entries.first as LogRecord).level, LogLevel.warn);
    });

    test('error() emits LogRecord with error level', () {
      logger.error('ctx', 'msg');
      expect((sink.entries.first as LogRecord).level, LogLevel.error);
    });

    test('warn() forwards error and stackTrace', () {
      final err = Exception('oops');
      final st = StackTrace.current;
      logger.warn('ctx', 'msg', error: err, stackTrace: st);
      final r = sink.entries.first as LogRecord;
      expect(r.error, err);
      expect(r.stackTrace, st);
    });

    test('error() forwards error and stackTrace', () {
      final err = Exception('boom');
      final st = StackTrace.current;
      logger.error('ctx', 'msg', error: err, stackTrace: st);
      final r = sink.entries.first as LogRecord;
      expect(r.error, err);
      expect(r.stackTrace, st);
    });

    test('attrs are stored on emitted LogRecord', () {
      logger.info('ctx', 'msg', attrs: {'k': 'v'});
      expect((sink.entries.first as LogRecord).attrs, {'k': 'v'});
    });
  });

  // ---------------------------------------------------------------------------
  // ObservabilityLogger (obs)
  // ---------------------------------------------------------------------------
  group('ObservabilityLogger', () {
    late _CaptureSink sink;
    late Logger logger;

    setUp(() {
      sink = _CaptureSink();
      logger = Logger(sinks: [sink]);
    });

    test('obs getter returns the same instance on repeated access', () {
      expect(logger.obs, same(logger.obs));
    });

    test('obs.event emits an EventEntry through the pipeline', () {
      logger.obs.event('ctx', 'user_login');

      expect(sink.entries.length, 1);
      expect(sink.entries.first, isA<EventEntry>());
    });

    test('obs.event stores message and className', () {
      logger.obs.event('MyService', 'purchase_completed');
      final e = sink.entries.first as EventEntry;
      expect(e.className, 'MyService');
      expect(e.message, 'purchase_completed');
    });

    test('obs.event stores data when provided', () {
      logger.obs.event('ctx', 'buy', data: {'amount': 50});
      final e = sink.entries.first as EventEntry;
      expect(e.data, {'amount': 50});
    });

    test('obs.event stores attrs when provided', () {
      logger.obs.event('ctx', 'click', attrs: {'env': 'prod'});
      final e = sink.entries.first as EventEntry;
      expect(e.attrs, {'env': 'prod'});
    });

    test('obs.event data defaults to null when not provided', () {
      logger.obs.event('ctx', 'event');
      expect((sink.entries.first as EventEntry).data, isNull);
    });

    test('obs.metric emits a MetricEntry through the pipeline', () {
      logger.obs.metric('ctx', 'latency', 42);

      expect(sink.entries.length, 1);
      expect(sink.entries.first, isA<MetricEntry>());
    });

    test('obs.metric stores name and value', () {
      logger.obs.metric('MyService', 'response_time', 120);
      final m = sink.entries.first as MetricEntry;
      expect(m.className, 'MyService');
      expect(m.name, 'response_time');
      expect(m.value, 120);
    });

    test('obs.metric stores unit when provided', () {
      logger.obs.metric('ctx', 'latency', 42, unit: 'ms');
      expect((sink.entries.first as MetricEntry).unit, 'ms');
    });

    test('obs.metric stores attrs when provided', () {
      logger.obs.metric('ctx', 'count', 1, attrs: {'region': 'eu'});
      expect((sink.entries.first as MetricEntry).attrs, {'region': 'eu'});
    });

    test('obs.metric unit defaults to null when not provided', () {
      logger.obs.metric('ctx', 'count', 3);
      expect((sink.entries.first as MetricEntry).unit, isNull);
    });

    test('obs entries pass through processors', () {
      final drop = _DropProcessor();
      final filteredLogger = Logger(processors: [drop], sinks: [sink]);

      filteredLogger.obs.event('ctx', 'click');
      filteredLogger.obs.metric('ctx', 'cpu', 0.5);

      expect(sink.entries, isEmpty);
      expect(drop.callCount, 2);
    });
  });
}
