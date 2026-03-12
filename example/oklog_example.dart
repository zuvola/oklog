import 'package:oklog/oklog.dart';

void main() {
  log.level = LogLevel.trace; // Set log level to trace to see all messages
  log.info('main', 'Hello, OkLog!');
  final myClass = MyClass();
  myClass.myMethod();

  // Deny list example
  log.denyList = ['MyClass']; // Exclude logs from MyClass
  myClass
      .myMethod(); // This will not be printed because MyClass is in the deny list
  log.info('main', 'This message will still be printed.');
  log.denyList.clear(); // Clear deny list

  // Allow list example
  log.allowList = ['main']; // Only include logs from 'main'
  myClass
      .myMethod(); // This will not be printed because MyClass is not in the allow list
  log.info('main', 'This message will be printed because it is from main.');

  // Dummy logger example
  log = DummyLogger(); // Switch to dummy logger to suppress output
  log.debug('main', 'This message will not be printed.');
}

class MyClass {
  void myMethod() {
    log.trace(this, 'This is a trace message.');
    log.debug(this, 'This is a debug message.');
    log.info(this, 'This is an info message.');
    log.notice(this, 'This is a notice message.');
    log.warn(this, 'This is a warning message.');
    try {
      throw Exception('Something went wrong!');
    } catch (e, st) {
      log.error(this, 'An error occurred.', e, st);
    }
  }
}
