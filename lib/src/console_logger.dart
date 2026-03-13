import 'logger.dart';

/// A logger that prints colored, emoji-decorated log entries to the console.
class ConsoleLogger extends Logger {
  ConsoleLogger({super.level});

  /// Formats and prints [entry] to stdout using colored, emoji-decorated output.
  @override
  void write(LogEntry entry) {
    final dateString = _colorString('[${entry.timestamp}]', 7, false);
    switch (entry) {
      case LogRecord():
        _writeRecord(dateString, entry);
      case EventEntry():
        _writeEvent(dateString, entry);
      case MetricEntry():
        _writeMetric(dateString, entry);
    }
  }

  void _writeRecord(String dateString, LogRecord entry) {
    final msg = entry.message.replaceAll('\n', ' ');
    final messageString = _colorString(
      '${entry.className}: $msg',
      _colors[entry.level.index],
      false,
    );
    print('$dateString ${_icons[entry.level.index]} $messageString');
    if (entry.error != null || entry.stackTrace != null) {
      print(_colorString('Error: ${entry.error}', 166, false));
      if (entry.stackTrace != null) print(entry.stackTrace);
    }
  }

  void _writeEvent(String dateString, EventEntry entry) {
    final buffer = StringBuffer('[EVENT] ${entry.className}: ${entry.message}');
    if (entry.data != null && entry.data!.isNotEmpty) {
      buffer.write(' : ${entry.data}');
    }
    if (entry.tags != null && entry.tags!.isNotEmpty) {
      buffer.write(' tags: ${entry.tags}');
    }
    print('$dateString 📡 ${_colorString(buffer.toString(), 13, false)}');
  }

  void _writeMetric(String dateString, MetricEntry entry) {
    final buffer = StringBuffer(
      '[METRIC] ${entry.className}: ${entry.name} : ${entry.value}',
    );
    if (entry.unit != null && entry.unit!.isNotEmpty) {
      buffer.write(' [${entry.unit}]');
    }
    if (entry.tags != null && entry.tags!.isNotEmpty) {
      buffer.write(' tags: ${entry.tags}');
    }
    print('$dateString 📊 ${_colorString(buffer.toString(), 45, false)}');
  }

  /// Emoji icons corresponding to each [LogLevel] (trace, debug, info, notice, warn, error).
  final _icons = ['🐾', '🛠️', '💬', '🔔', '⚠️', '❌'];

  /// ANSI 256-color codes for each [LogLevel].
  final _colors = [30, 245, 15, 14, 3, 9];

  /// Wraps [text] in an ANSI 256-color escape sequence.
  /// [color] is the 256-color palette index; [bg] selects background vs foreground.
  String _colorString(String text, int? color, bool bg) {
    final typestr = bg ? '48' : '38';
    return color != null ? '\x1B[$typestr;5;${color}m$text\x1B[0m' : text;
  }
}
