import '../sinks/console_sink.dart';
import '../processors/level_filter_processor.dart';
import '../processors/name_filter_processor.dart';
import 'log_entry.dart';
import 'logger.dart';

/// The default logger. Prints colored, emoji-decorated log entries to the console.
///
/// A [LevelFilterProcessor] and a [NameFilterProcessor] are added automatically
/// and exposed as fields for easy configuration:
/// ```dart
/// log.level = LogLevel.info;
/// log.nameFilter.allowList = ['MyClass'];
/// ```
/// Additional processors and sinks can be added via [processors] and [sinks]:
/// ```dart
/// log.sinks.add(MyFileSink());
/// ```
class OkLogger extends Logger {
  late final LevelFilterProcessor _levelFilter;

  /// The name filter processor. Modify [NameFilterProcessor.allowList] or
  /// [NameFilterProcessor.denyList] to restrict which classes are logged.
  late final NameFilterProcessor nameFilter;

  OkLogger({LogLevel level = LogLevel.debug}) : super() {
    _levelFilter = LevelFilterProcessor(minLevel: level);
    nameFilter = NameFilterProcessor();
    processors.addAll([_levelFilter, nameFilter]);
    sinks.add(ConsoleSink());
  }

  /// The minimum log level. Entries below this level are dropped.
  LogLevel get level => _levelFilter.minLevel;
  set level(LogLevel value) => _levelFilter.minLevel = value;
}
