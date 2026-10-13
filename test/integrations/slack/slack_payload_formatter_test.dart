import 'package:oklog/oklog.dart';
import 'package:oklog/oklog_slack.dart';
import 'package:test/test.dart';

List<Map<String, dynamic>> _blocks(Map<String, dynamic> payload) =>
    (payload['blocks'] as List).cast<Map<String, dynamic>>();

String _blockText(Map<String, dynamic> block) {
  if (block['type'] == 'context') {
    return ((block['elements'] as List).single as Map)['text'] as String;
  }
  return (block['text'] as Map)['text'] as String;
}

String _section(List<Map<String, dynamic>> blocks, String label) => _blockText(
  blocks.firstWhere(
    (block) =>
        block['type'] == 'section' && _blockText(block).startsWith(label),
  ),
);

void main() {
  final formatter = SlackPayloadFormatter();

  test('limits every Block Kit text field and preserves code delimiters', () {
    final long = 'x' * 6000;
    final error = LogRecord(
      'S' * 6000,
      LogLevel.error,
      long,
      StateError(long),
      StackTrace.fromString(long),
      {'attribute': long},
    );
    final blocks = _blocks(
      formatter.format(
        error,
        [LogRecord('ctx', LogLevel.info, long)],
        {'metadata': long},
      ),
    );

    expect(blocks.length, 8);
    expect(_blockText(blocks.first).length, lessThanOrEqualTo(150));
    expect(_blockText(blocks.first), startsWith(':rotating_light: Error: '));
    for (final block in blocks.skip(1)) {
      final text = _blockText(block);
      expect(text, isNotEmpty);
      expect(
        text.length,
        lessThanOrEqualTo(block['type'] == 'context' ? 2000 : 3000),
      );
    }
    expect(_section(blocks, '*Message:* '), endsWith('...'));
    expect(_section(blocks, '*Attrs:* '), endsWith('...'));
    expect(_section(blocks, '*Error:* `'), endsWith('...`'));
    expect(_section(blocks, '*Stack Trace:*'), endsWith('```'));
    expect(_section(blocks, '*Stack Trace:*'), contains('...```'));
    expect(_section(blocks, '*Context Logs:*'), endsWith('```'));
    expect(
      _section(blocks, '*Context Logs:*'),
      contains('[Context truncated]'),
    );
  });

  test('retains text that is exactly at the header and section limits', () {
    const headerPrefix = ':rotating_light: Error: ';
    const messagePrefix = '*Message:* ';
    final error = LogRecord(
      'H' * (150 - headerPrefix.length),
      LogLevel.error,
      'M' * (3000 - messagePrefix.length),
    );
    final blocks = _blocks(formatter.format(error, [], const {}));

    expect(_blockText(blocks.first).length, 150);
    final message = _section(blocks, messagePrefix);
    expect(message.length, 3000);
    expect(message, isNot(endsWith('...')));
  });

  test('does not split a surrogate pair at a truncation boundary', () {
    const prefix = ':rotating_light: Error: ';
    final source = '${'C' * (150 - prefix.length - 4)}😀${'x' * 100}';
    final blocks = _blocks(
      formatter.format(
        LogRecord(source, LogLevel.error, 'failure'),
        [],
        const {},
      ),
    );
    final header = _blockText(blocks.first);

    expect(header, endsWith('...'));
    expect(header.length, 149);
    expect(
      header.codeUnits.any((unit) => unit >= 0xD800 && unit <= 0xDFFF),
      isFalse,
    );
  });

  test('keeps the newest records but displays them oldest first', () {
    final logs = List.generate(
      40,
      (index) => LogRecord(
        'ctx',
        LogLevel.info,
        'entry-${index.toString().padLeft(2, '0')} ${'x' * 150}',
      ),
    );
    final blocks = _blocks(
      formatter.format(
        LogRecord('service', LogLevel.error, 'failure'),
        logs,
        const {},
      ),
    );
    final context = _section(blocks, '*Context Logs:*');

    expect(context.length, lessThanOrEqualTo(3000));
    expect(context, contains('[Context truncated]'));
    expect(context, isNot(contains('entry-00')));
    expect(context, contains('entry-39'));
    expect(context, contains('entry-38'));
    expect(context.indexOf('entry-38'), lessThan(context.indexOf('entry-39')));
  });

  test('uses the full context budget when no logs are omitted', () {
    const prefix = '*Context Logs:*\n```';
    const suffix = '```';
    const omittedMarker = '[Context truncated]\n';
    final error = LogRecord('service', LogLevel.error, 'failure');
    final baseline = _section(
      _blocks(
        formatter.format(error, [
          LogRecord('ctx', LogLevel.info, ''),
        ], const {}),
      ),
      '*Context Logs:*',
    );
    final emptyLineLength = baseline.length - prefix.length - suffix.length;
    final available = 3000 - prefix.length - suffix.length;
    final lineLength = available - omittedMarker.length + 1;
    final message = 'x' * (lineLength - emptyLineLength);
    final context = _section(
      _blocks(
        formatter.format(error, [
          LogRecord('ctx', LogLevel.info, message),
        ], const {}),
      ),
      '*Context Logs:*',
    );

    expect(context.length, prefix.length + lineLength + suffix.length);
    expect(context, isNot(contains('[Context truncated]')));
    expect(context, contains(message));
  });

  test('truncates an oversized newest entry without including stale logs', () {
    final logs = [
      LogRecord('ctx', LogLevel.info, 'stale-entry'),
      LogRecord('ctx', LogLevel.critical, 'newest-entry ${'z' * 5000}'),
    ];
    final blocks = _blocks(
      formatter.format(
        LogRecord('ctx', LogLevel.error, 'failure'),
        logs,
        const {},
      ),
    );
    final context = _section(blocks, '*Context Logs:*');

    expect(context, contains('[Context truncated]'));
    expect(context, contains('newest-entry'));
    expect(context, isNot(contains('stale-entry')));
    expect(context, contains('[CRITICAL]'));
    expect(context.length, lessThanOrEqualTo(3000));
    expect(context, endsWith('...```'));
  });

  test('preserves a short context without an omission marker', () {
    final logs = [
      LogRecord('ctx', LogLevel.debug, 'first'),
      LogRecord('ctx', LogLevel.info, 'second'),
    ];
    final blocks = _blocks(
      formatter.format(
        LogRecord('ctx', LogLevel.error, 'failure'),
        logs,
        const {},
      ),
    );
    final context = _section(blocks, '*Context Logs:*');

    expect(context, isNot(contains('[Context truncated]')));
    expect(context.indexOf('first'), lessThan(context.indexOf('second')));
    expect(context, startsWith('*Context Logs:*\n```'));
    expect(context, endsWith('```'));
  });
}
