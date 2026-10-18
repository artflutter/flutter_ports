// Original code, not ported from Chart.js: helpers.dataset cases with no spec.
import 'package:flutter_chartjs/src/helpers/helpers.dataset.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/index.dart';
import 'package:test/test.dart';

// Upstream has no spec for helpers.dataset.ts (AGENTS.md rule 3). The
// expected values come from src/helpers/helpers.dataset.ts of Chart.js
// v4.5.1, run with the same inputs in Node.js v24.12.0 on x64.

/// A JavaScript object literal `{left, top, right, bottom, width, height}`,
/// passed as a [ChartArea].
final class _ChartArea implements ChartArea {
  const _ChartArea(this.left, this.top, this.right, this.bottom);

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  @override
  double get width => right - left;

  @override
  double get height => bottom - top;
}

/// A JavaScript object `{width, height, chartArea}`, passed as a [Chart].
final class _Chart implements Chart {
  const _Chart(this.width, this.height, this.chartArea);

  @override
  final double width;

  @override
  final double height;

  @override
  final ChartArea chartArea;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A JavaScript object `{left, top, right, bottom, options: {clip}}`,
/// passed as a [Scale]. The `clip` argument is the option value, and
/// [undefined] leaves the key out.
final class _Scale implements Scale {
  _Scale(this.left, this.top, this.right, this.bottom, Object? clip)
    : options = {if (!identical(clip, undefined)) 'clip': clip};

  @override
  final double left;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  @override
  final Map<String, Object?> options;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The `_clip` object of `toClip` (core.datasetController.js:38).
final class _Clip implements ChartMetaClip {
  const _Clip(
    this.left,
    this.top,
    this.right,
    this.bottom, {
    this.disabled = false,
  });

  @override
  final Object? left;

  @override
  final Object? top;

  @override
  final Object? right;

  @override
  final Object? bottom;

  @override
  final bool disabled;
}

/// A JavaScript object `{_clip, xScale, yScale}`, passed as a [ChartMeta].
final class _Meta implements ChartMeta {
  _Meta(this.clip, [this.xScale, this.yScale]);

  @override
  final ChartMetaClip clip;

  @override
  final Scale? xScale;

  @override
  final Scale? yScale;

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Negative zero, spelled out.
// ignore: prefer_int_literals
const double _negativeZero = -0.0;

/// Matches a double with the same value as [expected], where -0 differs from
/// +0 and NaN matches NaN, as `Object.is` does.
Matcher _isSameNumber(double expected) => predicate<double>(
  (actual) => expected.isNaN
      ? actual.isNaN
      : actual == expected && actual.isNegative == expected.isNegative,
  'Object.is($expected)',
);

/// Matches a [TRBL] with the edges of the upstream result `{left, right,
/// top, bottom}`, compared as `Object.is` does.
Matcher _isArea(double left, double top, double right, double bottom) =>
    isA<TRBL>()
        .having((a) => a.left, 'left', _isSameNumber(left))
        .having((a) => a.top, 'top', _isSameNumber(top))
        .having((a) => a.right, 'right', _isSameNumber(right))
        .having((a) => a.bottom, 'bottom', _isSameNumber(bottom));

void main() {
  const area = _ChartArea(10, 20, 300, 200);
  const chart = _Chart(320, 240, area);
  _Scale xScale(Object? clip) => _Scale(15, 0, 290, 0, clip);
  _Scale yScale(Object? clip) => _Scale(0, 25, 0, 190, clip);

  group('getDatasetClipArea', () {
    test('returns false (null) when the clip is disabled', () {
      const clip = _Clip(false, false, false, false, disabled: true);
      expect(
        getDatasetClipArea(chart, _Meta(clip, xScale(true), yScale(true))),
        isNull,
      );
    });

    test('uses the chart area without both scales', () {
      const clip = _Clip(5, 5, 5, 5);
      expect(getDatasetClipArea(chart, _Meta(clip)), _isArea(5, 15, 305, 205));
      expect(
        getDatasetClipArea(chart, _Meta(clip, xScale(true))),
        _isArea(5, 15, 305, 205),
      );
      expect(
        getDatasetClipArea(chart, _Meta(clip, null, yScale(true))),
        _isArea(5, 15, 305, 205),
      );
    });

    test('uses the chart area edges of a scale whose clip is falsy', () {
      const clip = _Clip(5, 5, 5, 5);
      expect(
        getDatasetClipArea(chart, _Meta(clip, xScale(false), yScale(null))),
        _isArea(5, 15, 305, 205),
      );
      expect(
        getDatasetClipArea(
          chart,
          _Meta(clip, xScale(undefined), yScale(double.nan)),
        ),
        _isArea(5, 15, 305, 205),
      );
      expect(
        getDatasetClipArea(
          chart,
          _Meta(clip, xScale(''), yScale(_negativeZero)),
        ),
        _isArea(5, 15, 305, 205),
      );
    });

    test('uses the scale edges of a scale whose clip is truthy', () {
      expect(
        getDatasetClipArea(
          chart,
          _Meta(const _Clip(5, 5, 5, 5), xScale(true), yScale(1)),
        ),
        _isArea(10, 20, 295, 195),
      );
      // The x scale clips with 0 (falsy), the y scale with 'yes' (truthy).
      expect(
        getDatasetClipArea(
          chart,
          _Meta(const _Clip(1, 2, 3, 4), xScale(0), yScale('yes')),
        ),
        _isArea(9, 23, 303, 194),
      );
      expect(
        getDatasetClipArea(
          chart,
          _Meta(const _Clip(1, 2, 3, 4), xScale(<Object?>[]), yScale({})),
        ),
        _isArea(14, 23, 293, 194),
      );
    });

    test('uses the chart edges for false', () {
      const clip = _Clip(false, false, false, false);
      expect(
        getDatasetClipArea(chart, _Meta(clip, xScale(true), yScale(true))),
        _isArea(0, 0, 320, 240),
      );
    });

    test('uses the dataset area edges for true', () {
      const clip = _Clip(true, true, true, true);
      expect(
        getDatasetClipArea(chart, _Meta(clip, xScale(true), yScale(true))),
        _isArea(15, 25, 290, 190),
      );
    });

    test('mixes false, true and numbers per edge', () {
      const clip = _Clip(false, true, 7, false);
      expect(getDatasetClipArea(chart, _Meta(clip)), _isArea(0, 20, 307, 240));
    });

    test('moves the edges by negative and fractional numbers', () {
      expect(
        getDatasetClipArea(chart, _Meta(const _Clip(-5, -2.5, -0.5, -100))),
        _isArea(15, 22.5, 299.5, 100),
      );
      expect(
        getDatasetClipArea(chart, _Meta(const _Clip(0.1, 0.2, 0.1, 0.2))),
        _isArea(9.9, 19.8, 300.1, 200.2),
      );
      // jsonDecode gives int values.
      expect(
        getDatasetClipArea(chart, _Meta(const _Clip(1, 1, 1, 1))),
        _isArea(9, 19, 301, 201),
      );
    });

    test('takes null as 0 and undefined as NaN', () {
      expect(
        getDatasetClipArea(
          chart,
          _Meta(const _Clip(null, null, undefined, undefined)),
        ),
        _isArea(10, 20, double.nan, double.nan),
      );
      expect(
        getDatasetClipArea(
          chart,
          _Meta(const _Clip(undefined, undefined, null, null)),
        ),
        _isArea(double.nan, double.nan, 300, 200),
      );
    });

    test('keeps NaN and infinite edges', () {
      expect(
        getDatasetClipArea(
          chart,
          _Meta(
            const _Clip(
              double.nan,
              double.infinity,
              double.negativeInfinity,
              double.nan,
            ),
          ),
        ),
        _isArea(
          double.nan,
          double.negativeInfinity,
          double.negativeInfinity,
          double.nan,
        ),
      );
    });

    test('keeps the sign of zero as JavaScript does', () {
      const negativeZeroArea = _ChartArea(
        _negativeZero,
        _negativeZero,
        _negativeZero,
        _negativeZero,
      );
      const zeroChart = _Chart(1, 1, negativeZeroArea);
      // -0 - 0 is -0, and -0 + -0 is -0.
      expect(
        getDatasetClipArea(
          zeroChart,
          _Meta(const _Clip(0, 0, _negativeZero, _negativeZero)),
        ),
        _isArea(_negativeZero, _negativeZero, _negativeZero, _negativeZero),
      );
      // true subtracts or adds 0: -0 + 0 is +0.
      expect(
        getDatasetClipArea(
          zeroChart,
          _Meta(const _Clip(true, true, true, true)),
        ),
        _isArea(_negativeZero, _negativeZero, 0, 0),
      );
      // false gives +0 for left and top.
      expect(
        getDatasetClipArea(
          zeroChart,
          _Meta(const _Clip(false, false, true, true)),
        ),
        _isArea(0, 0, 0, 0),
      );
    });

    test('subtracts strings as numbers and adds them as strings', () {
      // Upstream returns the strings '3005' and '200x' for right and bottom.
      // The port returns their ToNumber.
      expect(
        getDatasetClipArea(chart, _Meta(const _Clip('5', ' 7 ', '5', 'x'))),
        _isArea(5, 13, 3005, double.nan),
      );
    });

    test('converts arrays and objects as JavaScript does', () {
      // Upstream returns '3005' and '200' for right and bottom.
      expect(
        getDatasetClipArea(
          chart,
          _Meta(const _Clip([5], <Object?>[], [5], <Object?>[])),
        ),
        _isArea(5, 20, 3005, 200),
      );
      // Upstream returns '300[object Object]' and '200[object Object]'.
      expect(
        getDatasetClipArea(
          chart,
          _Meta(
            const _Clip(
              <String, Object?>{},
              <String, Object?>{},
              <String, Object?>{},
              <String, Object?>{},
            ),
          ),
        ),
        _isArea(double.nan, double.nan, double.nan, double.nan),
      );
    });
  });
}
