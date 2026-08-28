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
  /// When true, the level string (e.g. `[INFO]`) is omitted and error/stackTrace
  /// are excluded from the formatted string. Use this when writing to
  /// `dart:developer.log`, which accepts those values as dedicated parameters.
  final bool forDeveloperLog;

  ConsoleFormatter({this.forDeveloperLog = false});

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
    final levelString = _colorString(
      '[${entry.level.name.toUpperCase().padRight(6)}]',
      _colors[entry.level.index],
      false,
    );
    final messageString = _colorString(
      '${entry.className}: ${entry.message.replaceAll('\n', ' ')}',
      _colors[entry.level.index],
      false,
    );
    final buffer = StringBuffer(
      forDeveloperLog
          ? '$dateString ${_icons[entry.level.index]} $messageString'
          : '$dateString ${_icons[entry.level.index]} $levelString $messageString',
    );
    if (entry.attrs != null && entry.attrs!.isNotEmpty) {
      buffer.write(
        _colorString(
          ' : ${entry.attrs}',
          _colors[entry.level.index],
          false,
        ).replaceAll('\n', ' '),
      );
    }
    if (!forDeveloperLog && (entry.error != null || entry.stackTrace != null)) {
      buffer.write('\n${_colorString('Error: ${entry.error}', 166, false)}');
      if (entry.stackTrace != null) buffer.write('\n${entry.stackTrace}');
    }
    return buffer.toString();
  }

  String _formatEvent(String dateString, EventEntry entry) {
    final buffer = StringBuffer(
      forDeveloperLog
          ? '${entry.className}: ${entry.message}'
          : '[EVENT ] ${entry.className}: ${entry.message}',
    );
    if (entry.data != null && entry.data!.isNotEmpty) {
      buffer.write(' : ${entry.data}');
    }
    if (entry.attrs != null && entry.attrs!.isNotEmpty) {
      buffer.write(' : ${entry.attrs}');
    }
    return forDeveloperLog
        ? '$dateString ${_colorString(buffer.toString(), 13, false)}'
        : '$dateString 📡 ${_colorString(buffer.toString(), 13, false)}';
  }

  String _formatMetric(String dateString, MetricEntry entry) {
    final buffer = StringBuffer(
      forDeveloperLog
          ? '${entry.className}: ${entry.name} : ${entry.value}'
          : '[METRIC] ${entry.className}: ${entry.name} : ${entry.value}',
    );
    if (entry.unit != null && entry.unit!.isNotEmpty) {
      buffer.write(' [${entry.unit}]');
    }
    if (entry.attrs != null && entry.attrs!.isNotEmpty) {
      buffer.write(' : ${entry.attrs}');
    }
    return forDeveloperLog
        ? '$dateString ${_colorString(buffer.toString(), 45, false)}'
        : '$dateString 📊 ${_colorString(buffer.toString(), 45, false)}';
  }

  /// Emoji icons corresponding to each [LogLevel].
  final _icons = ['🐾', '🛠️', '💬', '🔔', '⚠️', '❌', '🚨'];

  /// ANSI 256-color codes for each [LogLevel].
  final _colors = [30, 245, 15, 14, 3, 9, 196];

  /// Wraps [text] in an ANSI 256-color escape sequence.
  String _colorString(String text, int? color, bool bg) {
    final typestr = bg ? '48' : '38';
    return color != null ? '\x1B[$typestr;5;${color}m$text\x1B[0m' : text;
  }
}
