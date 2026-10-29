// Ported from Chart.js v4.6.1 test/specs/core.element.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/types/animation.dart';
import 'package:test/test.dart';

import '../support/jasmine.dart';

// The spec constructs Chart.Element. Here it is the Element of
// core.element.dart (Chart.js ADR 0017).

/// The object literal `{active: () => true, _to: 20}`. A
/// `Map<String, Animation>` does not accept an object literal, so the spec
/// passes a test [Animation] with the same members.
final class _Animation implements Animation {
  _Animation({required this._active, required this.to});

  final bool Function() _active;

  @override
  bool active() => _active();

  @override
  final double to;
}

void main() {
  setUpSpecs();

  group('Chart.element', () {
    group('getProps', () {
      test('should return requested properties', () {
        final elem = Element()
          ..x = 10
          ..y = 1.5;

        expect(
          elem.getProps(['x', 'y']),
          objectContaining({'x': 10, 'y': 1.5}),
        );
        expect(
          elem.getProps(['x', 'y'], true),
          objectContaining({'x': 10, 'y': 1.5}),
        );

        elem.$animations = {'x': _Animation(active: () => true, to: 20)};
        expect(
          elem.getProps(['x', 'y']),
          objectContaining({'x': 10, 'y': 1.5}),
        );
        expect(
          elem.getProps(['x', 'y'], true),
          objectContaining({'x': 20, 'y': 1.5}),
        );
      });
    });
  });
}
