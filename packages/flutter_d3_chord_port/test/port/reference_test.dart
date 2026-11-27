// Original code, not ported from d3-chord: Node.js v3.0.1 reference tests.

import 'package:flutter_d3_chord_port/d3_chord.dart';
import 'package:test/test.dart';

import '../asserts.dart';
import 'd3_chord_reference.dart';

final RegExp _svgNumber = RegExp(r'-?\d+(?:\.\d+)?(?:e[+-]?\d+)?');

/// Compares two SVG path strings structurally, allowing 1e-11 numeric delta
/// for platform `sin`/`cos` last-bit differences between V8 and Dart libm.
void _expectSvgClose(String actual, String expected, {double tol = 1e-11}) {
  final actualStruct = actual.replaceAll(_svgNumber, '#');
  final expectedStruct = expected.replaceAll(_svgNumber, '#');
  expect(actualStruct, expectedStruct);
  final aNums = _svgNumber
      .allMatches(actual)
      .map((m) => double.parse(m.group(0)!))
      .toList();
  final eNums = _svgNumber
      .allMatches(expected)
      .map((m) => double.parse(m.group(0)!))
      .toList();
  expect(aNums.length, eNums.length);
  for (var i = 0; i < eNums.length; ++i) {
    expect(aNums[i], closeTo(eNums[i], tol), reason: 'coord[$i]');
  }
}

void _verifyCase(
  Chords actual,
  RibbonGenerator<Chord, ChordSubgroup> rib,
  RefChordCase expected,
) {
  assertGroupsInDelta(actual.groups, expected.groups, 1e-12);
  assertChordsInDelta(actual, expected.chords, 1e-12);
  expect(actual.length, expected.ribbons.length);
  for (var i = 0; i < actual.length; ++i) {
    _expectSvgClose(rib(actual[i])!, expected.ribbons[i]);
  }
}

void main() {
  double asc(double a, double b) => a - b;
  double desc(double a, double b) => b - a;

  test('undirectedDefault matches Node.js d3-chord v3.0.1', () {
    final res = chord()(refCircosMatrix);
    final rib = ribbon(radius: 240);
    _verifyCase(res, rib, refUndirectedDefault);
  });

  test('undirectedSortedPadded matches Node.js d3-chord v3.0.1', () {
    final res = chord(
      padAngle: 0.06,
      sortGroups: desc,
      sortSubgroups: desc,
      sortChords: desc,
    )(refCircosMatrix);
    final rib = ribbon(sourceRadius: 220, targetRadius: 200, padAngle: 0.01);
    _verifyCase(res, rib, refUndirectedSortedPadded);
  });

  test('directedSparse6 matches Node.js d3-chord v3.0.1', () {
    final res = chordDirected(
      padAngle: 0.04,
      sortGroups: asc,
      sortSubgroups: desc,
      sortChords: asc,
    )(refSparse6Matrix);
    final rib = ribbonArrow(
      sourceRadius: 180,
      targetRadius: 170,
      headRadius: 12,
      padAngle: 0.005,
    );
    _verifyCase(res, rib, refDirectedSparse6);
  });

  test('transposeSparse6 matches Node.js d3-chord v3.0.1', () {
    final res = chordTranspose(padAngle: 0.05, sortSubgroups: asc)(
      refSparse6Matrix,
    );
    final rib = ribbon(radius: 150);
    _verifyCase(res, rib, refTransposeSparse6);
  });
}
