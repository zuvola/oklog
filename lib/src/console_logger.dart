import 'logger.dart';

/// A logger that prints colored, emoji-decorated log entries to the console.
class ConsoleLogger extends Logger {
  ConsoleLogger({super.level});

  /// Formats and prints the log entry to stdout.
  /// Newlines in [message] are collapsed to spaces for single-line output.
  /// If [error] or [stackTrace] is provided, they are printed on separate lines.
  @override
  void write(
    LogLevel level,
    String className,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    message = message.replaceAll('\n', ' ');
    final dateString = _colorString('[${DateTime.now().toString()}]', 7, false);
    final messageString = _colorString(
      '$className: $message',
      _colors[level.index],
      false,
    );
    final icon = _icons[level.index];
    print('$dateString $icon $messageString');

    if (error != null || stackTrace != null) {
      print(_colorString('Error: $error', 166, false));
      if (stackTrace != null) {
        print(stackTrace);
      }
    }
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
