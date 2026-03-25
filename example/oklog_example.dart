import 'package:oklog/oklog.dart';
import 'package:oklog/oklog_slack.dart';

void main() {
  log.level = LogLevel.trace;

  log.info('main', 'Hello, OkLog!');
  final myClass = MyClass();
  myClass.myMethod();

  // Deny list: exclude logs from MyClass using the built-in nameFilter.
  log.nameFilter.denyList = ['MyClass'];
  myClass.myMethod(); // suppressed — MyClass is denied
  log.info('main', 'This message will still be printed.');
  log.nameFilter.denyList = [];

  // Allow list: only allow logs from 'main'.
  log.nameFilter.allowList = ['main'];
  myClass.myMethod(); // suppressed — MyClass is not in the allow list
  log.info('main', 'This message will be printed because it is from main.');
  log.nameFilter.allowList = [];

  // Silence output by clearing all sinks.
  log.sinks.clear();
  log.debug('main', 'This message will not be printed.');

  // --- ErrorAlertSink + SlackErrorExporter ---
  // ContextBufferProcessor retains recent log records so that they can be
  // forwarded alongside an error notification for added context.
  final buffer = ContextBufferProcessor();
  final slackExporter = SlackErrorExporter(
    'https://hooks.slack.com/services/YOUR/WEBHOOK/URL',
  );
  // Insert the context buffer at the start of the processor pipeline so it
  // captures all subsequent log entries.
  log.processors.insert(0, buffer);
  log.sinks.add(
    ErrorAlertSink(
      buffer,
      slackExporter,
      metadata: {'app': 'MyApp', 'version': '1.0.0', 'env': 'production'},
    ),
  );

  log.info('main', 'Application started.');
  log.warn('main', 'Cache miss — fetching from origin.');
  log.info('main', 'User login attempt', attrs: {'userId': pii('user123')});
  log.debug(
    'main',
    'This is a debug message with attrs.',
    attrs: {
      'userId': 123,
      'action': 'login',
      'nullValue': null,
      'description':
          'User logged in successfully\nwith multiple lines in the message.',
    },
  );
  try {
    throw Exception('Database connection failed');
  } catch (e, st) {
    // ErrorAlertSink detects the error level, then calls
    // SlackErrorExporter.send() with the error record and the buffered
    // context logs (the info + warn above), posting a rich Slack message.
    log.error('main', 'Unhandled error.', error: e, stackTrace: st);
  }
}

class MyClass {
  void myMethod() {
    log.trace(this, 'This is a trace message.');
    log.debug(this, 'This is a debug message.');
    log.info(this, 'This is an info message.');
    log.notice(this, 'This is a notice message.');
    log.warn(this, 'This is a warning message.');
    log.debug(
      this,
      'This is a debug message with attrs.',
      attrs: {
        'userId': 123,
        'action': 'login',
        'nullValue': null,
        'description':
            'User logged in successfully\nwith multiple lines in the message.',
      },
    );

    log.obs.event(
      this,
      'User logged in',
      data: {'userId': 123},
      attrs: {'source': 'mobile'},
    );
    log.obs.metric(
      this,
      'API Response Time',
      250,
      unit: 'ms',
      attrs: {'endpoint': '/login'},
    );
    try {
      throw Exception('Something went wrong!');
    } catch (e, st) {
      log.error(this, 'An error occurred.', error: e, stackTrace: st);
    }
  }
}
