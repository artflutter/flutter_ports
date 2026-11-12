// Original code, not ported from Chart.js: drawPointLegend of the circle class.
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';
import 'package:test/test.dart';

final class _Options implements DrawPointOptions {
  const _Options(this.pointStyle, this.borderWidth);

  @override
  final Object? pointStyle;

  @override
  double? get rotation => 0;

  @override
  double get radius => 4;

  @override
  final double borderWidth;
}

/// The mock context of upstream has no `ellipse`.
final class _Context extends MockContext {
  final List<List<double>> ellipses = [];

  @override
  void ellipse(
    double x,
    double y,
    double radiusX,
    double radiusY,
    double rotation,
    double startAngle,
    double endAngle, [
    bool counterclockwise = false,
  ]) => ellipses.add([x, y, radiusX, radiusY, rotation, startAngle, endAngle]);
}

/// The calls of [style] on a recording context.
List<Object?> _calls(Object? style, {double? w, double borderWidth = 1}) {
  final ctx = _Context();
  drawPointLegend(ctx, _Options(style, borderWidth), 10, 20, w);
  return [...ctx.getCalls(), ...ctx.ellipses];
}

void main() {
  setUpSpecs();

  group('the circle class and the default branch', () {
    // A value that is no style (Dart `null`, a number, an object) takes the
    // default branch of upstream, which draws the circle: the calls of
    // CirclePointStyle (row adapt-point-style-objects).
    for (final w in const [null, 12.0]) {
      for (final borderWidth in const [0.0, 2.0]) {
        test('w $w, border $borderWidth', () {
          final expected = _calls(
            const CirclePointStyle(),
            w: w,
            borderWidth: borderWidth,
          );
          expect(_calls(null, w: w, borderWidth: borderWidth), expected);
          expect(_calls(7, w: w, borderWidth: borderWidth), expected);
          expect(
            _calls(<String, Object?>{}, w: w, borderWidth: borderWidth),
            expected,
          );
        });
      }
    }

    test('other styles keep their case', () {
      expect(
        _calls(const RectPointStyle()),
        isNot(_calls(const CirclePointStyle())),
      );
      expect(_calls(false), isNot(_calls(const CirclePointStyle())));
    });
  });
}
