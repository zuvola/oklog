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
  });
}
