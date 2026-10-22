// Original code, not ported from Chart.js: the exports of elements/index.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/index.dart';
import 'package:test/test.dart';

// src/elements/index.js exports the four element classes, and no spec tests
// it. These tests check that each class comes through
// lib/src/elements/index.dart with its upstream id, and that each class is
// an Element.

void main() {
  setUpSpecs();

  test('exports the four element classes with their ids', () {
    expect(ArcElement.id, 'arc');
    expect(LineElement.id, 'line');
    expect(PointElement.id, 'point');
    expect(BarElement.id, 'bar');
  });

  test('each exported class is an Element', () {
    expect(ArcElement(), isA<Element>());
    expect(LineElement(), isA<Element>());
    expect(PointElement(), isA<Element>());
    expect(BarElement(), isA<Element>());
  });
}
