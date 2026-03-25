import '../../core/log_entry.dart';
import '../../sinks/error_formatter.dart';

/// An [ErrorFormatter] that produces a Slack Block Kit message payload.
///
/// Formats the error record and recent context logs into structured blocks
/// suitable for delivery via a Slack Incoming Webhook.
///
/// To obtain a webhook URL, create an Incoming Webhook in your Slack app
/// settings: https://api.slack.com/messaging/webhooks
///
/// Example:
/// ```dart
/// final exporter = HttpErrorExporter(
///   'https://hooks.slack.com/services/...',
///   SlackPayloadFormatter(),
/// );
/// ```
class SlackPayloadFormatter implements ErrorFormatter {
  @override
  Map<String, dynamic> format(
    LogRecord error,
    List<LogRecord> contextLogs,
    Map<String, String> metadata,
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

    // App metadata (e.g. app name, version, environment)
    if (metadata.isNotEmpty) {
      final metaText = metadata.entries
          .map((e) => '*${e.key}:* ${e.value}')
          .join('  |  ');
      blocks.add({
        'type': 'context',
        'elements': [
          {'type': 'mrkdwn', 'text': metaText},
        ],
      });
    }

    // Error message
    blocks.add({
      'type': 'section',
      'text': {'type': 'mrkdwn', 'text': '*Message:* ${error.message}'},
    });

    // Attrs
    if (error.attrs != null && error.attrs!.isNotEmpty) {
      final attrsText = error.attrs!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('  |  ')
          .replaceAll('\n', ' ');
      blocks.add({
        'type': 'section',
        'text': {'type': 'mrkdwn', 'text': '*Attrs:* $attrsText'},
      });
    }

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
            final base =
                '[${r.timestamp.toIso8601String()}]'
                ' ${_icons[r.level.index]}'
                ' [${r.level.name.toUpperCase()}]'
                ' ${r.className}: ${r.message}';
            if (r.attrs == null || r.attrs!.isEmpty) return base;
            final attrsText = r.attrs!.entries
                .map((e) => '${e.key}: ${e.value}')
                .join(', ');
            return '$base  {$attrsText}'.replaceAll('\n', ' ');
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

  /// Emoji icons corresponding to each [LogLevel] (trace, debug, info, notice, warn, error).
  static const _icons = ['🐾', '🛠️', '💬', '🔔', '⚠️', '❌'];
}
