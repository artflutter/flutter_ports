// Original code, not ported from Chart.js: tests of the reduced-motion flag.
import 'package:flutter_chartjs_port/src/core/reduced_motion.dart';
import 'package:test/test.dart';

// The reduced-motion flag of Chart.js ADR 0049, section 7 (row
// platform-reduced-motion). The flag is keyed by the canvas. Any object
// stands for a canvas: the file is a pure layer.

void main() {
  group('platform-reduced-motion', () {
    test('a canvas has no flag by default', () {
      expect(isReducedMotion(Object()), isFalse);
    });

    test('setReducedMotion sets and clears the flag', () {
      final canvas = Object();
      setReducedMotion(canvas, enabled: true);
      expect(isReducedMotion(canvas), isTrue);
      setReducedMotion(canvas, enabled: true);
      expect(isReducedMotion(canvas), isTrue);
      setReducedMotion(canvas, enabled: false);
      expect(isReducedMotion(canvas), isFalse);
      setReducedMotion(canvas, enabled: false);
      expect(isReducedMotion(canvas), isFalse);
    });

    test('Dart null, the canvas of a destroyed chart, gives false', () {
      expect(isReducedMotion(null), isFalse);
    });

    test('two canvases have their own flags', () {
      final a = Object();
      final b = Object();
      setReducedMotion(a, enabled: true);
      expect(isReducedMotion(a), isTrue);
      expect(isReducedMotion(b), isFalse);
      setReducedMotion(b, enabled: true);
      setReducedMotion(a, enabled: false);
      expect(isReducedMotion(a), isFalse);
      expect(isReducedMotion(b), isTrue);
    });
  });
}
