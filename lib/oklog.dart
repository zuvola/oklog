/// oklog — a lightweight, extensible logger for Dart.
///
/// Import this library to access [Logger], [OkLogger], [LogProcessor],
/// [LogSink], [ConsoleSink], and the built-in processors.
/// The global [log] instance is an [OkLogger] with the default log level.
library;

import 'src/core/ok_logger.dart';

// Core
export 'src/core/log_entry.dart';
export 'src/core/log_processor.dart';
export 'src/core/log_sink.dart';
export 'src/core/log_formatter.dart';
export 'src/core/logger.dart';
export 'src/core/ok_logger.dart';

// Processors
export 'src/processors/level_filter_processor.dart';
export 'src/processors/name_filter_processor.dart';
export 'src/processors/context_buffer_processor.dart';

// Sinks
export 'src/sinks/console_formatter.dart';
export 'src/sinks/console_sink.dart';
export 'src/sinks/error_exporter.dart';
export 'src/sinks/error_alert_sink.dart';
export 'src/sinks/slack_error_exporter.dart';

/// Global logger instance.
final OkLogger log = OkLogger();
