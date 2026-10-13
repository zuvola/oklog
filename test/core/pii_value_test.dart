import 'package:oklog/oklog.dart';
import 'package:test/test.dart';

void main() {
  // ---------------------------------------------------------------------------
  // PiiValue
  // ---------------------------------------------------------------------------
  group('PiiValue', () {
    test('wraps the original value', () {
      final p = PiiValue('user@example.com');
      expect(p.value, 'user@example.com');
    });

    test('toString returns the raw value string', () {
      expect(PiiValue('secret').toString(), 'pii(secret)');
      expect(PiiValue(42).toString(), 'pii(42)');
    });

    test('pii() factory produces a PiiValue', () {
      final p = pii('test@test.com');
      expect(p, isA<PiiValue<String>>());
      expect(p.value, 'test@test.com');
    });
  });

  // ---------------------------------------------------------------------------
  // maskPiiAttrs
  // ---------------------------------------------------------------------------
  group('maskPiiAttrs', () {
    test('returns null when attrs is null', () {
      expect(maskPiiAttrs(null), isNull);
    });

    test('replaces PiiValue entries with [REDACTED]', () {
      final attrs = <String, Object>{
        'email': pii('user@example.com'),
        'session_id': 'abc123',
      };
      final masked = maskPiiAttrs(attrs)!;
      expect(masked['email'], '[REDACTED]');
      expect(masked['session_id'], 'abc123');
    });

    test('accepts a custom mask string', () {
      final attrs = <String, Object>{'name': pii('Alice')};
      final masked = maskPiiAttrs(attrs, '***')!;
      expect(masked['name'], '***');
    });

    test('returns copy with all non-PII values unchanged', () {
      final attrs = <String, Object>{'count': 5, 'flag': true};
      final masked = maskPiiAttrs(attrs)!;
      expect(masked['count'], 5);
      expect(masked['flag'], true);
    });

    test('returns an empty map when attrs is empty', () {
      expect(maskPiiAttrs({}), isEmpty);
    });

    test('does not mutate the original map', () {
      final attrs = <String, Object>{'email': pii('a@b.com')};
      maskPiiAttrs(attrs);
      expect(attrs['email'], isA<PiiValue>());
    });

    test('redacts values nested in maps and lists', () {
      final attrs = <String, Object?>{
        'user': {
          'contacts': [pii('secret@example.com'), 'public'],
        },
      };

      expect(containsPiiAttrs(attrs), isTrue);
      final masked = maskPiiAttrs(attrs)!;
      final contacts = (masked['user'] as Map)['contacts'] as List;
      expect(contacts, ['[REDACTED]', 'public']);
      expect(
        ((attrs['user'] as Map)['contacts'] as List).first,
        isA<PiiValue>(),
      );
    });

    test('redacts PII used as nested map keys', () {
      const secretKey = 'secret-token';
      const secretValue = 'private-value';
      final attrs = <String, Object?>{
        'nested': {
          pii(secretKey): 'ordinary value',
          'visible': pii(secretValue),
        },
      };

      expect(containsPiiAttrs(attrs), isTrue);
      final masked = maskPiiAttrs(attrs)!;
      final nested = masked['nested'] as Map;
      expect(nested['[REDACTED]'], 'ordinary value');
      expect(nested['visible'], '[REDACTED]');
      expect(masked.toString(), isNot(contains(secretKey)));
      expect(masked.toString(), isNot(contains(secretValue)));
      expect((attrs['nested'] as Map).keys.first, isA<PiiValue>());
    });

    test('detects sensitive map keys inside iterable values', () {
      const secret = 'private-key';
      final attrs = <String, Object?>{
        'items': [
          {pii(secret): 'visible value'},
        ],
      };

      expect(containsPiiAttrs(attrs), isTrue);
      final masked = maskPiiAttrs(attrs)!;
      final nested = (masked['items'] as List).single as Map;
      expect(nested.keys.single, '[REDACTED]');
      expect(masked.toString(), isNot(contains(secret)));
    });

    test('leaves non-PII nested values intact', () {
      final attrs = <String, Object?>{
        'nested': {
          'numbers': [1, 2, 3],
        },
      };
      expect(containsPiiAttrs(attrs), isFalse);
      expect(maskPiiAttrs(attrs), attrs);
    });

    test('redacts circular container references', () {
      final cycle = <String, Object?>{};
      cycle['self'] = cycle;
      final attrs = <String, Object?>{'nested': cycle};
      final masked = maskPiiAttrs(attrs)!;
      expect((masked['nested'] as Map)['self'], '[REDACTED]');
    });
  });
}
