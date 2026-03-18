import '../core/log_entry.dart';
import '../core/log_formatter.dart';

/// A [LogFormatter] that produces colored, emoji-annotated console output.
///
/// This is the default formatter used by [ConsoleSink]. Override or replace it
/// to customize how entries are rendered:
/// ```dart
/// log.sinks.add(ConsoleSink(formatter: MyFormatter()));
/// ```
class ConsoleFormatter extends LogFormatter<String> {
  @override
  String format(LogEntry entry) {
    final dateString = _colorString('[${entry.timestamp}]', 7, false);
    switch (entry) {
      case LogRecord():
        return _formatRecord(dateString, entry);
      case EventEntry():
        return _formatEvent(dateString, entry);
      case MetricEntry():
        return _formatMetric(dateString, entry);
    }
  }

  String _formatRecord(String dateString, LogRecord entry) {
    final msg = entry.message.replaceAll('\n', ' ');
    final messageString = _colorString(
      '${entry.className}: $msg',
      _colors[entry.level.index],
      false,
    );
    final buffer = StringBuffer(
      '$dateString ${_icons[entry.level.index]} $messageString',
    );
    if (entry.attrs != null && entry.attrs!.isNotEmpty) {
      buffer.write(
        '\n${_colorString('attrs: ${entry.attrs}', _colors[entry.level.index], false)}',
      );
    }
    if (entry.error != null || entry.stackTrace != null) {
      buffer.write('\n${_colorString('Error: ${entry.error}', 166, false)}');
      if (entry.stackTrace != null) buffer.write('\n${entry.stackTrace}');
    }
    return buffer.toString();
  }

  String _formatEvent(String dateString, EventEntry entry) {
    final buffer = StringBuffer('[EVENT] ${entry.className}: ${entry.message}');
    if (entry.data != null && entry.data!.isNotEmpty) {
      buffer.write(' : ${entry.data}');
    }
    if (entry.attrs != null && entry.attrs!.isNotEmpty) {
      buffer.write(' attrs: ${entry.attrs}');
    }
    return '$dateString 📡 ${_colorString(buffer.toString(), 13, false)}';
  }

  String _formatMetric(String dateString, MetricEntry entry) {
    final buffer = StringBuffer(
      '[METRIC] ${entry.className}: ${entry.name} : ${entry.value}',
    );
    if (entry.unit != null && entry.unit!.isNotEmpty) {
      buffer.write(' [${entry.unit}]');
    }
    if (entry.attrs != null && entry.attrs!.isNotEmpty) {
      buffer.write(' attrs: ${entry.attrs}');
    }
    return '$dateString 📊 ${_colorString(buffer.toString(), 45, false)}';
  }

  /// Emoji icons corresponding to each [LogLevel] (trace, debug, info, notice, warn, error).
  final _icons = ['🐾', '🛠️', '💬', '🔔', '⚠️', '❌'];

  /// ANSI 256-color codes for each [LogLevel].
  final _colors = [30, 245, 15, 14, 3, 9];

  /// Wraps [text] in an ANSI 256-color escape sequence.
  String _colorString(String text, int? color, bool bg) {
    final typestr = bg ? '48' : '38';
    return color != null ? '\x1B[$typestr;5;${color}m$text\x1B[0m' : text;
  }
}
