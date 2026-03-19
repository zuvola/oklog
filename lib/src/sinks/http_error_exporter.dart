import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/log_entry.dart';
import 'error_exporter.dart';
import 'error_formatter.dart';

/// A generic [ErrorExporter] that serialises a payload via [ErrorFormatter]
/// and delivers it to a remote endpoint using an HTTP POST request.
///
/// Inject any [ErrorFormatter] implementation to target different services:
///
/// ```dart
/// final exporter = HttpErrorExporter(
///   'https://hooks.slack.com/services/...',
///   SlackPayloadFormatter(),
/// );
/// ```
class HttpErrorExporter implements ErrorExporter {
  /// The URL to POST the formatted payload to.
  final String url;

  /// The formatter that converts log records into the request body.
  final ErrorFormatter formatter;

  /// Optional callback to transform the formatted payload before delivery.
  ///
  /// Receives the map produced by [formatter] and must return the final map
  /// to be JSON-encoded and sent. Use this to merge extra fields or reshape
  /// the payload without subclassing.
  final Map<String, dynamic> Function(Map<String, dynamic>)? payloadTransformer;

  HttpErrorExporter(this.url, this.formatter, {this.payloadTransformer});

  @override
  Future<void> send(
    LogRecord error,
    List<LogRecord> contextLogs,
    Map<String, String> metadata,
  ) async {
    var payload = formatter.format(error, contextLogs, metadata);
    if (payloadTransformer != null) payload = payloadTransformer!(payload);
    final uri = Uri.parse(url);
    try {
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (e) {
      // Errors during delivery must not propagate and crash the application.
      print('Failed to send error report to $url: $e');
    }
  }
}
