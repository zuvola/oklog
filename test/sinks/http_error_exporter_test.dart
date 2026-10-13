import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:oklog/oklog.dart';
import 'package:test/test.dart' hide ErrorFormatter;

class _TestFormatter implements ErrorFormatter {
  @override
  Map<String, dynamic> format(
    LogRecord error,
    List<LogRecord> contextLogs,
    Map<String, String> metadata,
  ) => {'message': error.message};
}

class _FailingFormatter implements ErrorFormatter {
  @override
  Map<String, dynamic> format(
    LogRecord error,
    List<LogRecord> contextLogs,
    Map<String, String> metadata,
  ) => throw StateError('formatter failed');
}

Future<List<String>> _capturePrints(Future<void> Function() action) async {
  final lines = <String>[];
  await runZoned<Future<void>>(
    action,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  final record = LogRecord('ctx', LogLevel.error, 'failure');
  const webhook = 'https://hooks.slack.com/services/SECRET/WEBHOOK/TOKEN';

  test('accepts successful HTTP responses without diagnostics', () async {
    final exporter = HttpErrorExporter(
      webhook,
      _TestFormatter(),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.body, contains('failure'));
        return http.Response('ok', 200);
      }),
    );

    final lines = await _capturePrints(
      () => exporter.send(record, [], const {}),
    );

    expect(lines, isEmpty);
  });

  test('reports non-2xx HTTP responses without revealing the URL', () async {
    final exporter = HttpErrorExporter(
      webhook,
      _TestFormatter(),
      client: MockClient((_) async => http.Response('unavailable', 503)),
    );

    final lines = await _capturePrints(
      () => exporter.send(record, [], const {}),
    );

    expect(lines.single, contains('HTTP 503'));
    expect(lines.join(), isNot(contains('SECRET')));
  });

  test('reports HTTP request timeouts', () async {
    final pending = Completer<http.Response>();
    final exporter = HttpErrorExporter(
      webhook,
      _TestFormatter(),
      client: MockClient((_) => pending.future),
      requestTimeout: const Duration(milliseconds: 10),
    );

    final lines = await _capturePrints(
      () => exporter.send(record, [], const {}),
    );

    expect(lines.single, contains('timed out'));
  });

  test('does not expose URLs embedded in network exceptions', () async {
    final exporter = HttpErrorExporter(
      webhook,
      _TestFormatter(),
      client: MockClient((_) async => throw StateError(webhook)),
    );

    final lines = await _capturePrints(
      () => exporter.send(record, [], const {}),
    );

    expect(lines.single, contains('StateError'));
    expect(lines.join(), isNot(contains('SECRET')));
  });

  test('contains formatter failures without throwing', () async {
    final exporter = HttpErrorExporter(webhook, _FailingFormatter());

    final lines = await _capturePrints(
      () => exporter.send(record, [], const {}),
    );

    expect(lines.single, contains('StateError'));
    expect(lines.join(), isNot(contains('SECRET')));
  });
}
