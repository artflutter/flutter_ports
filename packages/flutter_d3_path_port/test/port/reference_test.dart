// Original code, not ported from d3-path: Node.js reference comparison tests.

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:test/test.dart';

import '../asserts.dart';
import 'd3_path_reference.dart';

Map<String, String> _runScript(Path Function() makePath) {
  final results = <String, String>{};

  // 1. Negative-zero, integers, fractions, negative halves.
  {
    final p = makePath()
      // Negative zero must be a double literal on VM.
      // ignore: prefer_int_literals
      ..moveTo(-0.0, 0)
      ..lineTo(-0.5, -1.5)
      ..lineTo(0.5, 1.5)
      ..lineTo(-0.0005, -0.0015)
      ..lineTo(123.456789, -987.654321)
      ..closePath();
    results['roundingAndNegatives'] = '$p';
  }

  // 2. Polyline + curves + rect.
  {
    final p = makePath()
      ..moveTo(10.25, -20.75)
      ..lineTo(100.125, 50.5)
      ..quadraticCurveTo(150.3333, 25.6666, 200.9999, 80.0001)
      ..bezierCurveTo(210.5, 120.5, 180.25, 190.75, 120, 200)
      ..rect(5.5, 15.25, 40.75, 30.125)
      ..closePath();
    results['curvesAndRect'] = '$p';
  }

  // 3. Arcs (CW, CCW, full circles, negative sweep, empty start, zero radius).
  {
    final p = makePath()
      ..arc(100, 100, 50, 0, math.pi / 2)
      ..arc(100, 100, 50, math.pi / 2, math.pi * 1.75)
      ..arc(200, 100, 30, 0, -math.pi * 1.5, true)
      ..arc(300, 100, 25, 0.3, 0.3 + 2 * math.pi)
      ..arc(400, 100, 25, 0.3, 0.3 - 2 * math.pi, true)
      ..arc(500, 100, 0, 0, math.pi)
      ..closePath();
    results['arcs'] = '$p';
  }

  // 4. arcTo (empty, coincident, collinear, zero radius, CW & CCW corners).
  {
    final p = makePath()
      ..arcTo(10, 20, 30, 40, 5)
      ..arcTo(10, 20, 50, 60, 5)
      ..arcTo(20, 30, 30, 40, 5)
      ..arcTo(100, 30, 100, 120, 0)
      ..arcTo(270, 39, 163, 100, 53)
      ..arcTo(270, 39, 363, 100, 53)
      ..arcTo(100, 100, 200, 200, 25);
    results['arcTo'] = '$p';
  }

  // 5. Edge values: sub-epsilon, huge coordinates, closePath without moveTo.
  {
    final p = makePath()
      ..lineTo(1e-7, 1e-6)
      ..lineTo(1000000, -1000000)
      ..closePath()
      ..closePath()
      ..moveTo(0, 0)
      ..arc(0, 0, 10, 0, 1e-16)
      ..arc(0, 0, 10, 0, 1e-16, true);
    results['edges'] = '$p';
  }

  return results;
}

void main() {
  test('full-precision path() matches Node.js reference', () {
    final actual = _runScript(path);
    for (final entry in referenceFull.entries) {
      if (entry.key == 'arcs' || entry.key == 'arcTo' || entry.key == 'edges') {
        assertPathEqual(actual[entry.key]!, entry.value);
      } else {
        expect(actual[entry.key], entry.value, reason: entry.key);
      }
    }
  });

  for (final (digits, expected) in [
    (0, referenceRound0),
    (1, referenceRound1),
    (3, referenceRound3),
    (6, referenceRound6),
  ]) {
    test('pathRound($digits) matches Node.js reference byte-for-byte', () {
      final actual = _runScript(() => pathRound(digits));
      for (final entry in expected.entries) {
        expect(actual[entry.key], entry.value, reason: entry.key);
      }
    });
  }

  test('pathRound(16) matches Node.js full-precision reference', () {
    final actual = _runScript(() => pathRound(16));
    for (final entry in referenceRound16.entries) {
      if (entry.key == 'arcs' || entry.key == 'arcTo' || entry.key == 'edges') {
        assertPathEqual(actual[entry.key]!, entry.value);
      } else {
        expect(actual[entry.key], entry.value, reason: entry.key);
      }
    }
  });

  test('number formatting matches Node.js across precisions', () {
    for (final entry in referenceNumberBatches.entries) {
      final digits = entry.key;
      final p = digits == null ? path() : pathRound(digits);
      for (var i = 0; i < referenceNumbers.length; i += 2) {
        p.moveTo(referenceNumbers[i], referenceNumbers[i + 1]);
      }
      expect('$p', entry.value, reason: 'digits=$digits');
    }
  });
}
