import 'package:oklog/oklog.dart';
import 'package:test/test.dart';

void main() {
  group('OkLogger', () {
    // -------------------------------------------------------------------------
    // Default configuration
    // -------------------------------------------------------------------------
    group('default configuration', () {
      test('default log level is debug', () {
        final logger = OkLogger();
        expect(logger.level, LogLevel.debug);
      });

      test('processors contains LevelFilterProcessor', () {
        final logger = OkLogger();
        expect(logger.processors.whereType<LevelFilterProcessor>(), isNotEmpty);
      });

      test('processors contains NameFilterProcessor', () {
        final logger = OkLogger();
        expect(logger.processors.whereType<NameFilterProcessor>(), isNotEmpty);
      });

      test('nameFilter is the same instance added to processors', () {
        final logger = OkLogger();
        final nameFilters = logger.processors.whereType<NameFilterProcessor>();
        expect(nameFilters, contains(logger.nameFilter));
      });

      test('sinks contains ConsoleSink', () {
        final logger = OkLogger();
        expect(logger.sinks.whereType<ConsoleSink>(), isNotEmpty);
      });
    });

    group('pipeline error callbacks', () {
      test('forwards onPipelineError to the base Logger', () async {
        final errors = <Object>[];
        final logger = OkLogger(
          onPipelineError: (error, stackTrace) => errors.add(error),
        );
        logger.sinks
          ..clear()
          ..add(_FailingSink());

        await logger.emit(LogRecord('ctx', LogLevel.error, 'failure'));

        expect(errors.single, isA<StateError>());
      });

      test('allows configuring the global logger after creation', () {
        final previous = log.onPipelineError;
        try {
          void callback(Object error, StackTrace stackTrace) {}
          log.onPipelineError = callback;
          expect(log.onPipelineError, same(callback));
        } finally {
          log.onPipelineError = previous;
        }
      });
    });

    // -------------------------------------------------------------------------
    // level getter and setter
    // -------------------------------------------------------------------------
    group('level getter and setter', () {
      test('level getter reads from the internal LevelFilterProcessor', () {
        final logger = OkLogger(level: LogLevel.warn);
        expect(logger.level, LogLevel.warn);
      });

      test('level setter updates the internal LevelFilterProcessor', () {
        final logger = OkLogger();
        logger.level = LogLevel.error;
        expect(logger.level, LogLevel.error);
      });

      test('level setter affects what entries pass through', () {
        final sink = _CaptureSink();
        final logger = OkLogger();
        logger.sinks.add(sink);

        logger.level = LogLevel.warn;
        logger.info('ctx', 'should be dropped');
        logger.warn('ctx', 'should pass');

        final levels = sink.entries.map((e) => (e as LogRecord).level);
        expect(levels, [LogLevel.warn]);
      });

      test('custom initial level filters below that level', () {
        final sink = _CaptureSink();
        final logger = OkLogger(level: LogLevel.error);
        logger.sinks.add(sink);

        logger.warn('ctx', 'warn');
        logger.error('ctx', 'error');

        expect(sink.entries.length, 1);
        expect((sink.entries.first as LogRecord).level, LogLevel.error);
      });
    });

    // -------------------------------------------------------------------------
    // nameFilter integration
    // -------------------------------------------------------------------------
    group('nameFilter integration', () {
      test('nameFilter.denyList suppresses matching entries', () {
        final sink = _CaptureSink();
        final logger = OkLogger();
        logger.sinks.add(sink);
        logger.nameFilter.denyList = ['BlockedClass'];

        logger.debug('BlockedClass', 'msg');
        logger.debug('AllowedClass', 'msg');

        expect(sink.entries.length, 1);
        expect((sink.entries.first as LogRecord).className, 'AllowedClass');
      });

      test('nameFilter.allowList restricts to matching entries', () {
        final sink = _CaptureSink();
        final logger = OkLogger();
        logger.sinks.add(sink);
        logger.nameFilter.allowList = ['OnlyThis'];

        logger.debug('OnlyThis', 'pass');
        logger.debug('Other', 'drop');

        expect(sink.entries.length, 1);
        expect((sink.entries.first as LogRecord).className, 'OnlyThis');
      });
    });
  });
}

class _FailingSink extends LogSink {
  @override
  void emit(LogEntry entry) => throw StateError('sink failed');
}

/// Captures [LogRecord] entries emitted through the pipeline.
class _CaptureSink extends LogSink {
  final List<LogEntry> entries = [];

  @override
  void emit(LogEntry entry) => entries.add(entry);
}
