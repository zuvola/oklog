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
  String toString() => 'pii(${value.toString()})';
}

/// Marks [value] as PII so sinks can handle it appropriately.
///
/// ```dart
/// log.info(this, 'login', attrs: {'email': pii(email)});
/// ```
PiiValue<T> pii<T extends Object>(T value) => PiiValue(value);

/// Returns a copy of [attrs] with nested [PiiValue] entries replaced.
///
/// Traverses maps and iterables, including nested combinations. Cyclic
/// containers are redacted to prevent unbounded recursion.
/// Returns `null` when [attrs] is `null`.
Map<String, Object?>? maskPiiAttrs(
  Map<String, Object?>? attrs, [
  String mask = '[REDACTED]',
]) {
  if (attrs == null) return null;
  final ancestors = <Object>{};
  return {
    for (final entry in attrs.entries)
      entry.key: _maskValue(entry.value, mask, ancestors),
  };
}

Object? _maskValue(Object? value, String mask, Set<Object> ancestors) {
  if (value is PiiValue) return mask;
  if (value is Map) {
    if (!ancestors.add(value)) return mask;
    try {
      return {
        for (final entry in value.entries)
          entry.key: _maskValue(entry.value, mask, ancestors),
      };
    } finally {
      ancestors.remove(value);
    }
  }
  if (value is Iterable) {
    if (!ancestors.add(value)) return mask;
    try {
      return [
        for (final item in value) _maskValue(item, mask, ancestors),
      ];
    } finally {
      ancestors.remove(value);
    }
  }
  return value;
}

/// Whether a map or nested iterable contains a marked PII value.
bool containsPiiAttrs(Map<String, Object?>? attrs) {
  if (attrs == null) return false;
  return _containsPii(attrs, <Object>{});
}

bool _containsPii(Object? value, Set<Object> ancestors) {
  if (value is PiiValue) return true;
  if (value is Map) {
    if (!ancestors.add(value)) return false;
    try {
      return value.values.any((item) => _containsPii(item, ancestors));
    } finally {
      ancestors.remove(value);
    }
  }
  if (value is Iterable) {
    if (!ancestors.add(value)) return false;
    try {
      return value.any((item) => _containsPii(item, ancestors));
    } finally {
      ancestors.remove(value);
    }
  }
  return false;
}
