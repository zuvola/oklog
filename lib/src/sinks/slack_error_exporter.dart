import 'dart:convert';
import 'dart:io';

import '../core/log_entry.dart';
import 'error_exporter.dart';

/// An [ErrorExporter] that sends error reports to a Slack channel via an
/// Incoming Webhook URL.
///
/// Formats the error record and recent context logs into a Slack Block Kit
/// message and delivers it via HTTP POST.
///
/// To obtain a webhook URL, create an Incoming Webhook in your Slack app
/// settings: https://api.slack.com/messaging/webhooks
///
/// Example:
/// ```dart
/// final buffer = ContextBufferProcessor();
/// final exporter = SlackErrorExporter('https://hooks.slack.com/services/...');
/// final logger = Logger(
///   processors: [LevelFilterProcessor(), buffer],
///   sinks: [ConsoleSink(), ErrorAlertSink(buffer, exporter)],
/// );
/// ```
class SlackErrorExporter implements ErrorExporter {
  /// The Slack Incoming Webhook URL.
  final String webhookUrl;

  SlackErrorExporter(this.webhookUrl);

  @override
  Future<void> send(LogRecord error, List<LogRecord> contextLogs) async {
    final payload = _buildPayload(error, contextLogs);
    final uri = Uri.parse(webhookUrl);
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response = await request.close();
      await response.drain<void>();
    } catch (e) {
      // Handle any errors that occur during the HTTP request.
      print('Failed to send error report to Slack: $e');
    } finally {
      client.close();
    }
  }

  Map<String, dynamic> _buildPayload(
    LogRecord error,
    List<LogRecord> contextLogs,
  ) {
    final blocks = <Map<String, dynamic>>[];

    // Header
    blocks.add({
      'type': 'header',
      'text': {
        'type': 'plain_text',
        'text': ':rotating_light: Error: ${error.className}',
      },
    });

    // Error message
    blocks.add({
      'type': 'section',
      'text': {'type': 'mrkdwn', 'text': '*Message:* ${error.message}'},
    });

    // Error object
    if (error.error != null) {
      blocks.add({
        'type': 'section',
        'text': {'type': 'mrkdwn', 'text': '*Error:* `${error.error}`'},
      });
    }

    // Stack trace
    if (error.stackTrace != null) {
      final st = error.stackTrace.toString();
      final truncated = st.length > 2000 ? '${st.substring(0, 2000)}...' : st;
      blocks.add({
        'type': 'section',
        'text': {'type': 'mrkdwn', 'text': '*Stack Trace:*\n```$truncated```'},
      });
    }

    // Context logs
    if (contextLogs.isNotEmpty) {
      final contextText = contextLogs
          .map((r) {
            return '[${r.timestamp.toIso8601String()}]'
                ' [${r.level.name.toUpperCase()}]'
                ' ${r.className}: ${r.message}';
          })
          .join('\n');
      final truncated = contextText.length > 2000
          ? '${contextText.substring(0, 2000)}...'
          : contextText;
      blocks.add({
        'type': 'section',
        'text': {'type': 'mrkdwn', 'text': '*Context Logs:*\n```$truncated```'},
      });
    }

    // Timestamp
    blocks.add({
      'type': 'context',
      'elements': [
        {
          'type': 'mrkdwn',
          'text': 'Occurred at: ${error.timestamp.toIso8601String()}',
        },
      ],
    });

    return {'blocks': blocks};
  }
}
