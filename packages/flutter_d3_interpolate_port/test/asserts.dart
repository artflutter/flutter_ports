// Ported from d3-interpolate v3.0.1 test/asserts.js (ISC, Mike Bostock).

/// Port of `test/asserts.js` of d3-interpolate 3.0.1: the assertion that a
/// number, a list or a record is within a delta of the expected value, with
/// the matchers of `package:test` (D3 ADR 0009 §2).
library;

import 'package:test/test.dart';

/// asserts.js:3 `assertInDelta(actual, expected, delta)`: [actual] is within
/// [delta] of [expected].
///
/// [expected] is a number, a list (also a typed-data list) of expected
/// values, or a record with positional fields of expected values, such as
/// the `(double, double, double)` view of `interpolateZoom`. A list or a
/// record compares item by item, and [actual] must have the same length or
/// shape. A NaN is within no delta of anything, as upstream.
void assertInDelta(Object? actual, Object? expected, [double delta = 1e-6]) {
  expect(
    _inDelta(actual, expected, delta),
    isTrue,
    reason: '$actual should be within $delta of $expected',
  );
}

/// asserts.js:7 `inDelta(actual, expected, delta)`.
///
/// Upstream takes the object branch for a typed array (`Array.isArray` is
/// false for it), whose `for...in` reads the same indices as the array
/// branch. Here each [List] takes the array branch, and a record takes the
/// object branch.
bool _inDelta(Object? actual, Object? expected, double delta) =>
    expected is List
    ? _inDeltaArray(actual, expected, delta)
    : _fields(expected) != null
    ? _inDeltaObject(actual, expected, delta)
    : _inDeltaNumber(actual, expected, delta);

/// asserts.js:13 `inDeltaArray(actual, expected, delta)`.
bool _inDeltaArray(Object? actual, List<Object?> expected, double delta) {
  final n = expected.length;
  if (actual is! List || actual.length != n) return false;
  for (var i = 0; i < n; ++i) {
    if (!_inDelta(actual[i], expected[i], delta)) return false;
  }
  return true;
}

/// asserts.js:20 `inDeltaObject(actual, expected, delta)`: the fields of a
/// record. Both loops of upstream hold when [actual] has the fields of
/// [expected] and no other field: the same shape.
bool _inDeltaObject(Object? actual, Object? expected, double delta) {
  final e = _fields(expected)!;
  final a = _fields(actual);
  if (a == null || a.length != e.length) return false;
  for (var i = 0; i < e.length; ++i) {
    if (!_inDelta(a[i], e[i], delta)) return false;
  }
  return true;
}

/// asserts.js:26 `inDeltaNumber(actual, expected, delta)`.
bool _inDeltaNumber(Object? actual, Object? expected, double delta) =>
    actual is num &&
    expected is num &&
    actual >= expected - delta &&
    actual <= expected + delta;

/// The positional fields of a record of one to six fields with no named
/// field, or null for another value.
List<Object?>? _fields(Object? x) => switch (x) {
  (final Object? a,) => [a],
  (final Object? a, final Object? b) => [a, b],
  (final Object? a, final Object? b, final Object? c) => [a, b, c],
  (final Object? a, final Object? b, final Object? c, final Object? d) => [
    a,
    b,
    c,
    d,
  ],
  (
    final Object? a,
    final Object? b,
    final Object? c,
    final Object? d,
    final Object? e,
  ) =>
    [a, b, c, d, e],
  (
    final Object? a,
    final Object? b,
    final Object? c,
    final Object? d,
    final Object? e,
    final Object? f,
  ) =>
    [a, b, c, d, e, f],
  _ => null,
};
