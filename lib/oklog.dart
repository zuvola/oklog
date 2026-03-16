/// oklog — a lightweight, filterable logger for Dart.
///
/// Import this library to access [Logger], [DefaultLogger],
/// [LogSink], and [ConsoleSink].
/// The global [log] instance is a [DefaultLogger] with the default log level.
library;

import 'src/logger.dart';
import 'src/default_logger.dart';

export 'src/logger.dart';
export 'src/log_sink.dart';
export 'src/log_formatter.dart';
export 'src/console_formatter.dart';
export 'src/console_sink.dart';
export 'src/default_logger.dart';

/// Global logger instance.
final Logger log = DefaultLogger();
