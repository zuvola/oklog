import 'package:oklog/oklog.dart';
import 'package:oklog/oklog_slack.dart';
import 'package:test/test.dart';

class _CaptureSink extends LogSink {
  final List<LogEntry> entries = [];

  @override
  void emit(LogEntry entry) => entries.add(entry);
}

void main() {
  test('critical() emits a critical LogRecord with error details', () {
    final sink = _CaptureSink();
    final logger = Logger(sinks: [sink]);
    final error = StateError('unexpected state');
    final stackTrace = StackTrace.current;

    logger.critical(
      'runtime',
      'runtime cannot recover',
      error: error,
      stackTrace: stackTrace,
      attrs: {'generation': 7},
    );

    final record = sink.entries.single as LogRecord;
    expect(record.level, LogLevel.critical);
    expect(record.error, same(error));
    expect(record.stackTrace, same(stackTrace));
    expect(record.attrs, {'generation': 7});
  });

  test('SlackPayloadFormatter supports critical context records', () {
    final formatter = SlackPayloadFormatter();
    final payload = formatter.format(
      LogRecord('runtime', LogLevel.critical, 'runtime failed'),
      [LogRecord('runtime', LogLevel.critical, 'previous critical')],
      const {},
    );

    expect(payload.toString(), contains('[CRITICAL]'));
  });
}
