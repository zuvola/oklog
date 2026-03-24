/// Wraps a value to mark it as Personally Identifiable Information (PII).
///
/// Use [pii] to create instances. Sinks can inspect attrs for [PiiValue]
/// entries and decide how to handle them (e.g. redact before exporting).
///
/// Console output reveals the raw value via [toString]; error exporters
/// should call [maskPiiAttrs] to replace PII with a redaction marker.
class PiiValue<T extends Object> {
  final T value;

  const PiiValue(this.value);

  /// Returns the raw string representation of the wrapped value.
  @override
  String toString() => value.toString();
}

/// Marks [value] as PII so sinks can handle it appropriately.
///
/// ```dart
/// log.info(this, 'login', attrs: {'email': pii(email)});
/// ```
PiiValue<T> pii<T extends Object>(T value) => PiiValue(value);

/// Returns a copy of [attrs] with every [PiiValue] replaced by [mask].
///
/// Returns `null` when [attrs] is `null`.
Map<String, Object>? maskPiiAttrs(
  Map<String, Object>? attrs, [
  String mask = '[REDACTED]',
]) {
  if (attrs == null) return null;
  return {
    for (final e in attrs.entries) e.key: e.value is PiiValue ? mask : e.value,
  };
}
