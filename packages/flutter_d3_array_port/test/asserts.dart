// Ported from d3-array v3.2.4 test/asserts.js (ISC, Mike Bostock).

/// Port of `test/asserts.js` of d3-array 3.2.4.
library;

import 'package:test/test.dart';

/// Asserts that [actual] is a [Set] containing exactly the same elements as
/// [expected] (with `SameValueZero` `NaN` handling).
void assertSetEqual<T>(Set<T> actual, Iterable<T> expected) {
  final expList = expected.toList();
  final expSet = <T>{};
  var expHasNaN = false;
  for (final e in expList) {
    if (e is num && e.isNaN) {
      expHasNaN = true;
    } else {
      expSet.add(e);
    }
  }
  var actHasNaN = false;
  for (final a in actual) {
    if (a is num && a.isNaN) {
      actHasNaN = true;
      expect(expHasNaN, isTrue, reason: 'unexpected NaN');
    } else {
      expect(expSet.contains(a), isTrue, reason: 'unexpected $a');
    }
  }
  expect(actHasNaN, expHasNaN, reason: 'expected NaN=$expHasNaN');
  for (final e in expSet) {
    expect(actual.contains(e), isTrue, reason: 'expected $e');
  }
}
