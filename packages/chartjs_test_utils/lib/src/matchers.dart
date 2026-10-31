// Ported from chartjs-test-utils v0.4.0 src/matchers.js (MIT, chartjs-test-utils Contributors).

/// Port of `src/matchers.js`: the custom Jasmine matchers of the specs.
///
/// A Jasmine matcher `{compare(actual, expected)}` is a `package:matcher`
/// [Matcher] here. `expect(actual).toBeCloseToPixel(expected)` is
/// `expect(actual, toBeCloseToPixel(expected))`. `jasmine.addMatchers`
/// (`addMatchers`, index.js:50) has no counterpart: a spec imports the
/// matchers from `package:chartjs_test_utils/pure.dart`.
///
/// The port has:
/// - [toBeCloseToPixel] (matchers.js:58), [toBeCloseToPoint]
///   (matchers.js:76) and [toEqualOneOf] (matchers.js:89);
/// - [toBeValidChart] (matchers.js:106) and [toBeChartOfSize]
///   (matchers.js:131). They test a chart and its canvas through the pure
///   interfaces `types.Chart`, `HTMLCanvasElement`,
///   `CanvasRenderingContext2D` and `CSSStyleDeclaration` (Chart.js ADR
///   0022, section 9, `harness-chart-matchers`);
/// - `toEqualOptions` from `matchers.options.dart`, which matchers.js:229
///   re-exports.
///
/// Not ported:
/// - `toEqualImageData` (matchers.js:176), with `toPercent`,
///   `createImageData`, `canvasFromImageData` and `buildPixelMatchPreview`
///   (matchers.js:7-56): `n/a`. The port compares no image (Chart.js ADR
///   0034).
///
/// This library is a pure layer.
library;

// The harness reads the JS runtime of flutter_chartjs_port, which does not
// export lib/src.
// ignore_for_file: implementation_imports

import 'package:chartjs_test_utils/src/matchers.options.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

export 'package:chartjs_test_utils/src/matchers.options.dart'
    show toEqualOptions;

/// matchers.js:58 `toBeCloseToPixel`: whether the actual value is within
/// 0.5% of [expected], or less than 2 pixels from it.
///
/// The actual value and [expected] go through `ToNumber`, as `isNaN` and
/// `-` do in JS. A NaN on either side fails.
Matcher toBeCloseToPixel(Object? expected) => _ToBeCloseToPixel(expected);

final class _ToBeCloseToPixel extends Matcher {
  const _ToBeCloseToPixel(this.expected);

  final Object? expected;

  @override
  bool matches(Object? actual, Map<Object?, Object?> matchState) {
    var result = false;

    if (!jsIsNaN(actual) && !jsIsNaN(expected)) {
      final diff = (jsToNumber(actual) - jsToNumber(expected)).abs();
      // Upstream names these two `A` and `B`.
      final a = jsToNumber(actual).abs();
      final b = jsToNumber(expected).abs();
      const percentDiff = 0.005; // 0.5% diff
      result =
          (diff <= (a > b ? a : b) * percentDiff) ||
          diff < 2; // 2 pixels is fine
    }

    return result;
  }

  @override
  Description describe(Description description) => description
      .add('close to pixel ')
      .add(jsToString(expected))
      .add(' (0.5% or less than 2 px)');
}

/// matchers.js:76 `toBeCloseToPoint`: whether `x` and `y` of the actual
/// value equal `x` and `y` of [expected] after `Math.round(v * 100) / 100`.
///
/// The `x` and `y` reads are the members of a [Point], or [jsGet] of any
/// other value: a Map `{'x': ..., 'y': ...}` stands for an object literal.
Matcher toBeCloseToPoint(Object expected) => _ToBeCloseToPoint(expected);

final class _ToBeCloseToPoint extends Matcher {
  const _ToBeCloseToPoint(this.expected);

  final Object expected;

  static double _rnd(Object? v) {
    return jsRound(jsToNumber(v) * 100) / 100;
  }

  /// The property read `object.x` or `object.y`.
  static Object? _read(Object? object, String key) => switch (object) {
    final Point point => key == 'x' ? point.x : point.y,
    _ => jsGet(object, key),
  };

  @override
  bool matches(Object? actual, Map<Object?, Object?> matchState) {
    return _rnd(_read(actual, 'x')) == _rnd(_read(expected, 'x')) &&
        _rnd(_read(actual, 'y')) == _rnd(_read(expected, 'y'));
  }

  @override
  Description describe(Description description) => description
      .add('close to the point (')
      .add(jsToString(_read(expected, 'x')))
      .add(', ')
      .add(jsToString(_read(expected, 'y')))
      .add(') to 2 decimal places');
}

/// matchers.js:89 `toEqualOneOf`: whether the actual value is `===` to one
/// of [expecteds] ([strictEquals]).
Matcher toEqualOneOf(List<Object?> expecteds) => _ToEqualOneOf(expecteds);

final class _ToEqualOneOf extends Matcher {
  const _ToEqualOneOf(this.expecteds);

  final List<Object?> expecteds;

  @override
  bool matches(Object? actual, Map<Object?, Object?> matchState) {
    var result = false;
    for (var i = 0, l = expecteds.length; i < l; i++) {
      if (strictEquals(actual, expecteds[i])) {
        result = true;
        break;
      }
    }
    return result;
  }

  @override
  Description describe(Description description) =>
      description.add('one of ').addDescriptionOf(expecteds);
}

/// matchers.js:106 `toBeValidChart()`: whether the actual value is a chart
/// with a canvas, a context and a finite size.
///
/// The messages and their order are the upstream messages of :111-121.
/// `actual instanceof Chart` is a test for `types.Chart`. The two
/// `Object.prototype.toString` tags are tests for [HTMLCanvasElement] and
/// [CanvasRenderingContext2D]. `typeof actual.height !== 'number'` is always
/// false for the `double` of `types.Chart`.
Matcher toBeValidChart() => const _ToBeValidChart();

final class _ToBeValidChart extends Matcher {
  const _ToBeValidChart();

  /// The `message` of `compare` (matchers.js:108-121): Dart `null` for a
  /// pass.
  static String? messageOf(Object? actual) {
    String? message;

    // DIVERGES(chartjs): harness-chart-matchers, Dart types for the tags.
    if (actual is! types.Chart) {
      message = 'Expected ${jsToString(actual)} to be an instance of Chart';
    } else if (actual.canvas is! HTMLCanvasElement) {
      message = 'Expected canvas to be an instance of HTMLCanvasElement';
    } else if (actual.ctx is! CanvasRenderingContext2D) {
      message =
          'Expected context to be an instance of CanvasRenderingContext2D';
    } else if (!actual.height.isFinite) {
      message = 'Expected height to be a strict finite number';
    } else if (!actual.width.isFinite) {
      message = 'Expected width to be a strict finite number';
    }

    return message;
  }

  @override
  bool matches(Object? actual, Map<Object?, Object?> matchState) {
    final message = messageOf(actual);
    if (message != null) matchState['message'] = message;
    return message == null;
  }

  @override
  Description describe(Description description) =>
      description.add('a valid chart');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) => mismatchDescription.add('${matchState['message']}');
}

/// matchers.js:131 `toBeChartOfSize()`: whether the actual value is a valid
/// chart with the display size `dw` x `dh` and the render size `rw` x `rh`.
///
/// [expected] is the spec object with the keys `dw`, `dh`, `rw` and `rh`.
/// The messages and their order are the upstream messages of :150-166. The
/// row `harness-chart-matchers` covers two hunks:
/// - `getComputedStyle(canvas)` (:141) is the display size rule of the
///   harness ([computedCanvasSize]).
/// - `window.devicePixelRatio` (:142) is `actual.platform
///   .getDevicePixelRatio()`. For a chart on the Flutter platform, it is the
///   device pixel ratio of the view of its host.
Matcher toBeChartOfSize(Map<String, Object?> expected) =>
    _ToBeChartOfSize(expected);

final class _ToBeChartOfSize extends Matcher {
  const _ToBeChartOfSize(this.expected);

  final Map<String, Object?> expected;

  @override
  bool matches(Object? actual, Map<Object?, Object?> matchState) {
    final res = _ToBeValidChart.messageOf(actual);
    if (res != null) {
      matchState['message'] = res;
      return false;
    }

    final chart = actual! as types.Chart;
    String? message;
    final canvas = chart.ctx!.canvas;
    // DIVERGES(chartjs): harness-chart-matchers, the display size rule.
    final style = computedCanvasSize(canvas);
    final devicePixelRatio = jsGet(chart.options, 'devicePixelRatio');
    // DIVERGES(chartjs): harness-chart-matchers, the ratio of the platform.
    final pixelRatio = jsTruthy(devicePixelRatio)
        ? jsToNumber(devicePixelRatio)
        : chart.platform.getDevicePixelRatio();
    final dh = _parseInt(style.height);
    final dw = _parseInt(style.width);
    final rh = canvas.height;
    final rw = canvas.width;
    final orh = rh / pixelRatio;
    final orw = rw / pixelRatio;

    // sanity checks
    if (chart.height != orh) {
      message =
          'Expected chart height ${jsNumberToString(chart.height)} to be '
          'equal to original render height ${jsNumberToString(orh)}';
    } else if (chart.width != orw) {
      message =
          'Expected chart width ${jsNumberToString(chart.width)} to be '
          'equal to original render width ${jsNumberToString(orw)}';
    }

    // validity checks
    if (dh != expected['dh']) {
      message =
          'Expected display height $dh to be equal to '
          '${jsToString(expected['dh'])}';
    } else if (dw != expected['dw']) {
      message =
          'Expected display width $dw to be equal to '
          '${jsToString(expected['dw'])}';
    } else if (rh != expected['rh']) {
      message =
          'Expected render height $rh to be equal to '
          '${jsToString(expected['rh'])}';
    } else if (rw != expected['rw']) {
      message =
          'Expected render width $rw to be equal to '
          '${jsToString(expected['rw'])}';
    }

    if (message != null) matchState['message'] = message;
    return message == null;
  }

  @override
  Description describe(Description description) =>
      description.add('a chart of size ').addDescriptionOf(expected);

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) => mismatchDescription.add('${matchState['message']}');
}

/// `getComputedStyle(canvas)` of `toBeChartOfSize` (matchers.js:141): the
/// display width and height of [canvas], in px, or Dart `null` for `auto`
/// (Chart.js ADR 0022, section 9).
///
/// - A side with an inline px style has that value.
/// - With one px style only, the other side keeps the aspect ratio of the
///   render size: the CSS rule for a replaced element. A render width or
///   height of 0 gives no ratio: the side has its render size.
/// - Without a px style, a side has the render size.
/// - A canvas with its own `display: none` gives `auto` for a side without
///   a px style.
({double? width, double? height}) computedCanvasSize(HTMLCanvasElement canvas) {
  final style = canvas.style;
  final styleWidth = _px(style.getPropertyValue('width'));
  final styleHeight = _px(style.getPropertyValue('height'));
  final rw = canvas.width.toDouble();
  final rh = canvas.height.toDouble();
  if (style.getPropertyValue('display') == 'none') {
    return (width: styleWidth, height: styleHeight);
  }
  return (
    width:
        styleWidth ??
        (styleHeight != null && rh != 0 ? styleHeight * rw / rh : rw),
    height:
        styleHeight ??
        (styleWidth != null && rw != 0 ? styleWidth * rh / rw : rh),
  );
}

/// The number of a px length, for example `'455px'`, or Dart `null` for
/// another value.
double? _px(String value) {
  final text = value.trim();
  if (!text.endsWith('px')) return null;
  return double.tryParse(text.substring(0, text.length - 2).trim());
}

/// `parseInt(value, 10) || 0` of a px value: the integer part, toward zero.
/// `auto` (Dart `null`) gives NaN, and `|| 0` gives 0.
int _parseInt(double? value) {
  if (value == null || !value.isFinite) return 0;
  // js-ok: parseInt keeps the integer part, which truncates toward zero.
  return value.truncate();
}
