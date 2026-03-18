import 'package:oklog/oklog.dart';
import 'package:test/test.dart';

void main() {
  group('NameFilterProcessor', () {
    // -------------------------------------------------------------------------
    // Default values
    // -------------------------------------------------------------------------
    test('default denyList and allowList are empty', () {
      final processor = NameFilterProcessor();
      expect(processor.denyList, isEmpty);
      expect(processor.allowList, isEmpty);
    });

    test('empty lists: all entries pass through', () {
      final processor = NameFilterProcessor();
      expect(
        processor.process(LogRecord('AnyClass', LogLevel.info, 'msg')),
        isTrue,
      );
    });

    // -------------------------------------------------------------------------
    // denyList
    // -------------------------------------------------------------------------
    group('denyList', () {
      test('exact match blocks entry', () {
        final processor = NameFilterProcessor(denyList: ['MyClass']);
        expect(
          processor.process(LogRecord('MyClass', LogLevel.info, 'msg')),
          isFalse,
        );
      });

      test('substring match blocks entry', () {
        final processor = NameFilterProcessor(denyList: ['Class']);
        expect(
          processor.process(LogRecord('MyClass', LogLevel.info, 'msg')),
          isFalse,
        );
      });

      test('non-matching entry passes through', () {
        final processor = NameFilterProcessor(denyList: ['Other']);
        expect(
          processor.process(LogRecord('MyClass', LogLevel.info, 'msg')),
          isTrue,
        );
      });

      test('multiple deny patterns: any match blocks entry', () {
        final processor = NameFilterProcessor(denyList: ['Alpha', 'Beta']);
        expect(
          processor.process(LogRecord('AlphaService', LogLevel.info, 'msg')),
          isFalse,
        );
        expect(
          processor.process(LogRecord('BetaService', LogLevel.info, 'msg')),
          isFalse,
        );
        expect(
          processor.process(LogRecord('GammaService', LogLevel.info, 'msg')),
          isTrue,
        );
      });

      test('denyList filters EventEntry', () {
        final processor = NameFilterProcessor(denyList: ['MyClass']);
        expect(processor.process(EventEntry('MyClass', 'click')), isFalse);
      });

      test('denyList filters MetricEntry', () {
        final processor = NameFilterProcessor(denyList: ['MyClass']);
        expect(
          processor.process(MetricEntry('MyClass', 'latency', 42)),
          isFalse,
        );
      });
    });

    // -------------------------------------------------------------------------
    // allowList
    // -------------------------------------------------------------------------
    group('allowList', () {
      test('matching entry passes through', () {
        final processor = NameFilterProcessor(allowList: ['MyClass']);
        expect(
          processor.process(LogRecord('MyClass', LogLevel.info, 'msg')),
          isTrue,
        );
      });

      test('substring match allows entry', () {
        final processor = NameFilterProcessor(allowList: ['Class']);
        expect(
          processor.process(LogRecord('MyClass', LogLevel.info, 'msg')),
          isTrue,
        );
      });

      test('non-matching entry is blocked', () {
        final processor = NameFilterProcessor(allowList: ['Other']);
        expect(
          processor.process(LogRecord('MyClass', LogLevel.info, 'msg')),
          isFalse,
        );
      });

      test('multiple allow patterns: any match allows entry', () {
        final processor = NameFilterProcessor(allowList: ['Alpha', 'Beta']);
        expect(
          processor.process(LogRecord('AlphaService', LogLevel.info, 'msg')),
          isTrue,
        );
        expect(
          processor.process(LogRecord('BetaService', LogLevel.info, 'msg')),
          isTrue,
        );
        expect(
          processor.process(LogRecord('GammaService', LogLevel.info, 'msg')),
          isFalse,
        );
      });

      test('allowList filters EventEntry', () {
        final processor = NameFilterProcessor(allowList: ['Allowed']);
        expect(processor.process(EventEntry('Allowed', 'click')), isTrue);
        expect(processor.process(EventEntry('Other', 'click')), isFalse);
      });

      test('allowList filters MetricEntry', () {
        final processor = NameFilterProcessor(allowList: ['Allowed']);
        expect(
          processor.process(MetricEntry('Allowed', 'latency', 42)),
          isTrue,
        );
        expect(processor.process(MetricEntry('Other', 'latency', 42)), isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // denyList + allowList combined
    // -------------------------------------------------------------------------
    group('denyList and allowList combined', () {
      test('denyList takes precedence over allowList', () {
        final processor = NameFilterProcessor(
          denyList: ['MyClass'],
          allowList: ['MyClass'],
        );
        expect(
          processor.process(LogRecord('MyClass', LogLevel.info, 'msg')),
          isFalse,
        );
      });

      test('passes when in allowList and not in denyList', () {
        final processor = NameFilterProcessor(
          denyList: ['BadClass'],
          allowList: ['GoodClass'],
        );
        expect(
          processor.process(LogRecord('GoodClass', LogLevel.info, 'msg')),
          isTrue,
        );
      });

      test('blocked when not in allowList even if not in denyList', () {
        final processor = NameFilterProcessor(
          denyList: ['BadClass'],
          allowList: ['GoodClass'],
        );
        expect(
          processor.process(LogRecord('OtherClass', LogLevel.info, 'msg')),
          isFalse,
        );
      });
    });

    // -------------------------------------------------------------------------
    // Dynamic list changes
    // -------------------------------------------------------------------------
    test('denyList and allowList can be changed at runtime', () {
      final processor = NameFilterProcessor();
      final record = LogRecord('MyClass', LogLevel.info, 'msg');

      expect(processor.process(record), isTrue);

      processor.denyList = ['MyClass'];
      expect(processor.process(record), isFalse);

      processor.denyList = [];
      processor.allowList = ['Other'];
      expect(processor.process(record), isFalse);

      processor.allowList = ['MyClass'];
      expect(processor.process(record), isTrue);
    });
  });
}
