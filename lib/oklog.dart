/// oklog — a lightweight, filterable logger for Dart.
///
/// Import this library to access [Logger], [ConsoleLogger], and [DummyLogger].
/// The global [log] instance is a [ConsoleLogger] with the default log level.
library;

import 'src/logger.dart';
import 'src/console_logger.dart';

export 'src/logger.dart';
export 'src/console_logger.dart';
export 'src/dummy_logger.dart';

/// Global logger instance. Replace with a [DummyLogger] or custom logger as needed.
Logger log = ConsoleLogger();
