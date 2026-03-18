import 'package:oklog/oklog.dart';
import 'package:test/test.dart';

/// Mock [ErrorExporter] that records all [send] invocations.
class _MockExporter implements ErrorExporter {
  final List<({LogRecord error, List<LogRecord> context})> calls = [];

  @override
  Future<void> send(LogRecord error, List<LogRecord> contextLogs) async {
    calls.add((error: error, context: contextLogs));
  }

  bool get wasCalled => calls.isNotEmpty;
  int get callCount => calls.length;
}

void main() {
  late _MockExporter exporter;
  late ContextBufferProcessor buffer;
  late ErrorAlertSink sink;

  setUp(() {
    exporter = _MockExporter();
    buffer = ContextBufferProcessor(5);
    sink = ErrorAlertSink(buffer, exporter);
  });

  group('ErrorAlertSink', () {
    // -------------------------------------------------------------------------
    // Only fires on error-level entries
    // -------------------------------------------------------------------------
    test('fires exporter on error-level LogRecord', () async {
      final record = LogRecord('ctx', LogLevel.error, 'critical failure');
      sink.emit(record);
      await Future.microtask(() {});

      expect(exporter.wasCalled, isTrue);
      expect(exporter.calls.first.error, record);
    });

    test('does not fire exporter on warn-level LogRecord', () {
      sink.emit(LogRecord('ctx', LogLevel.warn, 'just a warning'));
      expect(exporter.wasCalled, isFalse);
    });

    test('does not fire exporter on info-level LogRecord', () {
      sink.emit(LogRecord('ctx', LogLevel.info, 'info'));
      expect(exporter.wasCalled, isFalse);
    });

    test('does not fire exporter on debug-level LogRecord', () {
      sink.emit(LogRecord('ctx', LogLevel.debug, 'debug'));
      expect(exporter.wasCalled, isFalse);
    });

    test('does not fire exporter on trace-level LogRecord', () {
      sink.emit(LogRecord('ctx', LogLevel.trace, 'trace'));
      expect(exporter.wasCalled, isFalse);
    });

    test('does not fire exporter on notice-level LogRecord', () {
      sink.emit(LogRecord('ctx', LogLevel.notice, 'notice'));
      expect(exporter.wasCalled, isFalse);
    });

    // -------------------------------------------------------------------------
    // Non-LogRecord entries are ignored
    // -------------------------------------------------------------------------
    test('does not fire exporter for EventEntry', () {
      sink.emit(EventEntry('ctx', 'user_click'));
      expect(exporter.wasCalled, isFalse);
    });

    test('does not fire exporter for MetricEntry', () {
      sink.emit(MetricEntry('ctx', 'latency', 100));
      expect(exporter.wasCalled, isFalse);
    });

    // -------------------------------------------------------------------------
    // Context logs are forwarded correctly
    // -------------------------------------------------------------------------
    test('passes context logs from buffer to exporter', () async {
      final r1 = LogRecord('ctx', LogLevel.debug, 'step 1');
      final r2 = LogRecord('ctx', LogLevel.info, 'step 2');
      buffer.process(r1);
      buffer.process(r2);

      final error = LogRecord('ctx', LogLevel.error, 'boom');
      sink.emit(error);
      await Future.microtask(() {});

      expect(exporter.calls.first.context, containsAll([r1, r2]));
    });

    test('passes empty context when buffer is empty', () async {
      final error = LogRecord('ctx', LogLevel.error, 'boom');
      sink.emit(error);
      await Future.microtask(() {});

      expect(exporter.calls.first.context, isEmpty);
    });

    test('exporter receives the exact error record', () async {
      final err = Exception('disk full');
      final st = StackTrace.current;
      final error = LogRecord(
        'DiskService',
        LogLevel.error,
        'disk error',
        err,
        st,
      );

      sink.emit(error);
      await Future.microtask(() {});

      final received = exporter.calls.first.error;
      expect(received.message, 'disk error');
      expect(received.error, err);
      expect(received.stackTrace, st);
      expect(received.className, 'DiskService');
    });

    // -------------------------------------------------------------------------
    // Multiple errors trigger multiple calls
    // -------------------------------------------------------------------------
    test('exporter is called once per error entry', () async {
      sink.emit(LogRecord('ctx', LogLevel.error, 'error 1'));
      sink.emit(LogRecord('ctx', LogLevel.error, 'error 2'));
      sink.emit(LogRecord('ctx', LogLevel.error, 'error 3'));
      await Future.microtask(() {});

      expect(exporter.callCount, 3);
    });
  });
}
