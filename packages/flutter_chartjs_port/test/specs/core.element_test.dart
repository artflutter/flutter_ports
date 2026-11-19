// Ported from Chart.js v4.6.1 test/specs/core.element.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

// The spec constructs Chart.Element. Here it is the Element of
// core.element.dart (Chart.js ADR 0017).
//
// `jasmine.objectContaining({x, y})` is `equals` on the record of the two
// reads `props['x']` and `props['y']`: an [ElementProps] has only the
// property read. A missing property reads `undefined`, which equals no
// number.

/// The properties `x` and `y` of [props].
({Object? x, Object? y}) _xy(ElementProps props) =>
    (x: props['x'], y: props['y']);

/// The object literal `{active: () => true, _to: 20}`. A
/// `Map<String, Animation>` does not accept an object literal, so the spec
/// passes a test [IAnimation] with the same members.
final class _Animation({
  required final bool Function() _active,
  @override required final double to,
}) implements IAnimation {
  @override
  bool active() => _active();
}

void main() {
  setUpSpecs();

  group('Chart.element', () {
    group('getProps', () {
      test('should return requested properties', () {
        final elem = Element()
          ..x = 10
          ..y = 1.5;

        expect(_xy(elem.getProps(['x', 'y'])), equals((x: 10, y: 1.5)));
        expect(_xy(elem.getProps(['x', 'y'], true)), equals((x: 10, y: 1.5)));

        elem.$animations = {'x': _Animation(active: () => true, to: 20)};
        expect(_xy(elem.getProps(['x', 'y'])), equals((x: 10, y: 1.5)));
        expect(_xy(elem.getProps(['x', 'y'], true)), equals((x: 20, y: 1.5)));
      });
    });
  });
}
