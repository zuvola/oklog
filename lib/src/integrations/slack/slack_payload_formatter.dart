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
  // Block Kit text limits. Context elements use a conservative lower limit.
  static const _maxHeaderLength = 150;
  static const _maxSectionLength = 3000;
  static const _maxContextLength = 2000;
  static const _omittedMarker = '[Context truncated]\n';

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
        'text': _truncate(
          ':rotating_light: Error: ${error.className}',
          _maxHeaderLength,
        ),
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
          {'type': 'mrkdwn', 'text': _truncate(metaText, _maxContextLength)},
        ],
      });
    }

    // Error message
    blocks.add({
      'type': 'section',
      'text': {
        'type': 'mrkdwn',
        'text': _truncate('*Message:* ${error.message}', _maxSectionLength),
      },
    });

    // Attrs
    if (error.attrs != null && error.attrs!.isNotEmpty) {
      final attrsText = error.attrs!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join('  |  ')
          .replaceAll('\n', ' ');
      blocks.add({
        'type': 'section',
        'text': {
          'type': 'mrkdwn',
          'text': _truncate('*Attrs:* $attrsText', _maxSectionLength),
        },
      });
    }

    // Error object
    if (error.error != null) {
      blocks.add({
        'type': 'section',
        'text': {
          'type': 'mrkdwn',
          'text': _wrappedText('*Error:* `', error.error.toString(), '`'),
        },
      });
    }

    // Stack trace
    if (error.stackTrace != null) {
      blocks.add({
        'type': 'section',
        'text': {
          'type': 'mrkdwn',
          'text': _wrappedText(
            '*Stack Trace:*\n```',
            error.stackTrace.toString(),
            '```',
          ),
        },
      });
    }

    // Context logs
    if (contextLogs.isNotEmpty) {
      blocks.add({
        'type': 'section',
        'text': {
          'type': 'mrkdwn',
          'text': _contextText(contextLogs),
        },
      });
    }

    // Timestamp
    blocks.add({
      'type': 'context',
      'elements': [
        {
          'type': 'mrkdwn',
          'text': _truncate(
            'Occurred at: ${error.timestamp.toIso8601String()}',
            _maxContextLength,
          ),
        },
      ],
    });

    return {'blocks': blocks};
  }

  /// Keeps the code markup intact even when the contents must be shortened.
  static String _wrappedText(String prefix, String content, String suffix) {
    final available = _maxSectionLength - prefix.length - suffix.length;
    return '$prefix${_truncate(content, available)}$suffix';
  }

  /// Preserves the most recent records while displaying the selected ones
  /// chronologically. Reserve room for the marker only when truncating.
  static String _contextText(List<LogRecord> contextLogs) {
    const prefix = '*Context Logs:*\n```';
    const suffix = '```';
    final available = _maxSectionLength - prefix.length - suffix.length;

    var selection = _retainRecentContextLines(contextLogs, available);
    if (selection.truncated) {
      selection = _retainRecentContextLines(
        contextLogs,
        available - _omittedMarker.length,
      );
    }

    final text = selection.lines.reversed.join('\n');
    return '$prefix${selection.truncated ? _omittedMarker : ''}$text$suffix';
  }

  static ({List<String> lines, bool truncated}) _retainRecentContextLines(
    List<LogRecord> contextLogs,
    int available,
  ) {
    final retained = <String>[];
    var used = 0;

    for (final record in contextLogs.reversed) {
      final line = _contextLine(record);
      final separatorLength = retained.isEmpty ? 0 : 1;
      if (used + separatorLength + line.length <= available) {
        retained.add(line);
        used += separatorLength + line.length;
        continue;
      }
      if (retained.isEmpty) retained.add(_truncate(line, available));
      return (lines: retained, truncated: true);
    }

    return (lines: retained, truncated: false);
  }

  static String _contextLine(LogRecord record) {
    final base =
        '[${record.timestamp.toIso8601String()}]'
        ' ${_icons[record.level.index]}'
        ' [${record.level.name.toUpperCase()}]'
        ' ${record.className}: ${record.message}';
    if (record.attrs == null || record.attrs!.isEmpty) {
      return base.replaceAll('\n', ' ');
    }
    final attrs = record.attrs!.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
    return '$base  {$attrs}'.replaceAll('\n', ' ');
  }

  /// Truncates by UTF-16 code units without splitting a surrogate pair.
  static String _truncate(String text, int limit) {
    if (text.length <= limit) return text;
    const marker = '...';
    var end = limit - marker.length;
    if (end > 0 && end < text.length) {
      final last = text.codeUnitAt(end - 1);
      final next = text.codeUnitAt(end);
      if (last >= 0xD800 &&
          last <= 0xDBFF &&
          next >= 0xDC00 &&
          next <= 0xDFFF) {
        end--;
      }
    }
    return '${text.substring(0, end)}$marker';
  }

  /// Emoji icons corresponding to each [LogLevel].
  static const _icons = ['🐾', '🛠️', '💬', '🔔', '⚠️', '❌', '🚨'];
}
