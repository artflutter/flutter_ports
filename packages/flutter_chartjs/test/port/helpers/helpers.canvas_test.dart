// Original code, not ported from Chart.js: helpers.canvas cases with no spec.
import 'package:flutter_chartjs/src/helpers/helpers.canvas.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/types/index.dart';
import 'package:test/test.dart';

// Upstream behaviour that test/specs/helpers.canvas.tests.js does not check
// (AGENTS.md rule 3). The expected values come from the helpers of the
// chart.js 4.5.1 npm package (dist/chart.umd.js) in Node.js v24.12.0 on x64.

/// A JavaScript font object literal, passed as a [FontSpec]. A null member
/// is an absent key or JS `null`.
final class _Font implements FontSpec {
  const _Font({this.style, this.weight, this.size, this.family});

  @override
  final String? style;

  @override
  final Object? weight;

  @override
  final double? size;

  @override
  final String? family;
}

/// A JavaScript object literal `{x, y}`, passed as a [Point].
final class _Point implements Point {
  const _Point(this.x, this.y);

  @override
  final double? x;

  @override
  final double? y;
}

/// A JavaScript object literal `{left, top, right, bottom}`, passed as a
/// [TRBL].
final class _Area implements TRBL {
  const _Area({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;
}

/// Point coordinates for the tests that compare a function with its earlier
/// `jsToNumber` form: JS `null`, the signed zeros, NaN (a copied
/// `undefined`), the infinities, a subnormal, large values and finites.
const List<double?> _coordinates = [
  null,
  0,
  -0,
  double.nan,
  double.infinity,
  double.negativeInfinity,
  double.minPositive,
  -double.minPositive,
  1.4e154,
  -1.4e154,
  -0.6,
  -0.4,
  1,
  255.75,
  512.4,
  512.5,
];

void main() {
  group('toFontString', () {
    test('returns null without a font, a size or a family', () {
      expect(toFontString(null), isNull);
      expect(toFontString(const _Font(family: 'Arial')), isNull);
      expect(toFontString(const _Font(size: 12)), isNull);
    });

    test('joins style, weight, size and family', () {
      expect(
        toFontString(const _Font(size: 12, family: 'Arial')),
        '12px Arial',
      );
      expect(
        toFontString(
          const _Font(
            style: 'italic',
            weight: 'bold',
            size: 12,
            family: 'Arial',
          ),
        ),
        'italic bold 12px Arial',
      );
      expect(
        toFontString(
          const _Font(
            style: 'normal',
            weight: 300.5,
            size: 1 / 3,
            family: "'Helvetica Neue', sans-serif",
          ),
        ),
        "normal 300.5 0.3333333333333333px 'Helvetica Neue', sans-serif",
      );
    });

    test('leaves out a falsy style or weight', () {
      expect(
        toFontString(
          const _Font(style: '', weight: 0, size: 12, family: 'Arial'),
        ),
        '12px Arial',
      );
      expect(
        toFontString(
          const _Font(weight: double.nan, size: 1e21, family: 'Arial'),
        ),
        '1e+21px Arial',
      );
    });

    test('writes the weight and the size with Number::toString', () {
      expect(
        toFontString(const _Font(weight: 600, size: 12.5, family: 'Arial')),
        '600 12.5px Arial',
      );
      expect(
        toFontString(const _Font(size: -0, family: 'Arial')),
        '0px Arial',
      );
      expect(
        toFontString(const _Font(size: double.nan, family: 'Arial')),
        'NaNpx Arial',
      );
      expect(
        toFontString(const _Font(size: 1e-7, family: 'Arial')),
        '1e-7px Arial',
      );
    });

    test('keeps an empty family', () {
      expect(toFontString(const _Font(size: 12, family: '')), '12px ');
    });
  });

  group('isPointInArea', () {
    const area = _Area(left: 0, top: 0, right: 512, bottom: 256);

    test('uses a margin of 0.5 for a falsy margin', () {
      expect(isPointInArea(const _Point(-0.4, 0), area, 0), true);
      expect(isPointInArea(const _Point(-0.4, 0), area, double.nan), true);
      expect(isPointInArea(const _Point(-0.4, 0), area), true);
      expect(isPointInArea(const _Point(-0.6, 0), area), false);
      expect(isPointInArea(const _Point(512.4, 256.4), area), true);
      expect(isPointInArea(const _Point(512.5, 0), area), false);
      expect(isPointInArea(const _Point(0, -0.5), area), false);
    });

    test('uses a given margin', () {
      expect(isPointInArea(const _Point(-1.5, 0), area, 2), true);
      expect(isPointInArea(const _Point(-2, 0), area, 2), false);
      expect(isPointInArea(const _Point(0, 0), area, 0.1), true);
      expect(isPointInArea(const _Point(-0.1, 0), area, 0.1), false);
    });

    test('reads a null coordinate as 0 and a NaN coordinate as outside', () {
      expect(isPointInArea(const _Point(null, 0), area), true);
      expect(
        isPointInArea(
          const _Point(null, 0),
          const _Area(left: 1, top: 0, right: 512, bottom: 256),
        ),
        false,
      );
      expect(isPointInArea(const _Point(double.nan, 0), area), false);
      expect(isPointInArea(const _Point(0, double.nan), area), false);
    });

    test('gives the result of the jsToNumber form', () {
      // The form before Chart.js ADR 0010: ToNumber through jsToNumber.
      bool before(Point point, TRBL area, double margin) =>
          jsToNumber(point.x) > area.left - margin &&
          jsToNumber(point.x) < area.right + margin &&
          jsToNumber(point.y) > area.top - margin &&
          jsToNumber(point.y) < area.bottom + margin;
      const areas = [
        area,
        _Area(left: -0, top: 0, right: 0, bottom: -0),
        _Area(left: 1, top: 1, right: 2, bottom: 2),
      ];
      for (final testArea in areas) {
        for (final margin in const [0.5, 2.0, double.infinity]) {
          for (final x in _coordinates) {
            for (final y in _coordinates) {
              final point = _Point(x, y);
              expect(
                isPointInArea(point, testArea, margin),
                before(point, testArea, margin),
                reason: '($x, $y), margin $margin',
              );
            }
          }
        }
      }
    });

    group('adapt-point-in-area-bool', () {
      test('is false without a point and true without an area', () {
        // Upstream returns the falsy point itself: `undefined` or `null`.
        expect(isPointInArea(null, area), false);
        expect(isPointInArea(null, null), true);
        expect(isPointInArea(const _Point(600, 600), null), true);
      });
    });
  });
}
