// Ported from d3-chord v3.0.1 test/asserts.js (ISC, Mike Bostock).

/// Port of `test/asserts.js` of d3-chord 3.0.1: numeric delta assertions for
/// chord groups, subgroups, and chords.
library;

import 'package:flutter_d3_chord_port/d3_chord.dart';
import 'package:test/test.dart';

/// Asserts that two [ChordGroup] lists match within [delta].
void assertGroupsInDelta(
  List<ChordGroup> actual,
  List<ChordGroup> expected, [
  double delta = 1e-6,
]) {
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    final a = actual[i];
    final e = expected[i];
    expect(a.index, e.index, reason: 'group[$i].index');
    expect(
      a.startAngle,
      closeTo(e.startAngle, delta),
      reason: 'group[$i].startAngle',
    );
    expect(
      a.endAngle,
      closeTo(e.endAngle, delta),
      reason: 'group[$i].endAngle',
    );
    expect(a.value, closeTo(e.value, delta), reason: 'group[$i].value');
  }
}

/// Asserts that two [ChordSubgroup] values match within [delta].
void assertSubgroupInDelta(
  ChordSubgroup actual,
  ChordSubgroup expected, [
  double delta = 1e-6,
  String prefix = 'subgroup',
]) {
  expect(actual.index, expected.index, reason: '$prefix.index');
  expect(
    actual.startAngle,
    closeTo(expected.startAngle, delta),
    reason: '$prefix.startAngle',
  );
  expect(
    actual.endAngle,
    closeTo(expected.endAngle, delta),
    reason: '$prefix.endAngle',
  );
  expect(actual.value, closeTo(expected.value, delta), reason: '$prefix.value');
}

/// Asserts that two [Chord] lists match within [delta].
void assertChordsInDelta(
  List<Chord> actual,
  List<Chord> expected, [
  double delta = 1e-6,
]) {
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    assertSubgroupInDelta(
      actual[i].source,
      expected[i].source,
      delta,
      'chord[$i].source',
    );
    assertSubgroupInDelta(
      actual[i].target,
      expected[i].target,
      delta,
      'chord[$i].target',
    );
  }
}
