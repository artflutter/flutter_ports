// Ported from Chart.js v4.5.1+7169e651 test/specs/core.element.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/types/animation.dart';
import 'package:test/test.dart';

// The spec constructs Chart.Element. Here it is the Element of
// core.element.dart (Chart.js ADR 0017).

/// `jasmine.objectContaining(expected)` over the [ElementProps] of
/// `getProps`: each key of [expected] reads as an equal value.
Matcher _objectContaining(Map<String, Object?> expected) {
  var matcher = isA<ElementProps>();
  for (final MapEntry(:key, :value) in expected.entries) {
    matcher = matcher.having((props) => props[key], key, value);
  }
  return matcher;
}

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
          _objectContaining({'x': 10, 'y': 1.5}),
        );
        expect(
          elem.getProps(['x', 'y'], true),
          _objectContaining({'x': 10, 'y': 1.5}),
        );

        elem.$animations = {'x': _Animation(active: () => true, to: 20)};
        expect(
          elem.getProps(['x', 'y']),
          _objectContaining({'x': 10, 'y': 1.5}),
        );
        expect(
          elem.getProps(['x', 'y'], true),
          _objectContaining({'x': 20, 'y': 1.5}),
        );
      });
    });
  });
}
