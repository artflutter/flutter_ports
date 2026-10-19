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
/// - `toEqualOptions` from `matchers.options.dart`, which matchers.js:229
///   re-exports.
///
/// Not ported yet, or not ported:
/// - `toBeValidChart` (matchers.js:106) and `toBeChartOfSize` (matchers.js:131)
///   test a chart and its canvas. They come with the chart in phase 5
///   (porting-flow.md section 3).
/// - `toEqualImageData` (matchers.js:176), with `toPercent`,
///   `createImageData`, `canvasFromImageData` and `buildPixelMatchPreview`
///   (matchers.js:7-56): `n/a`. The port compares no image (Chart.js ADR
///   0009).
///
/// This library is a pure layer.
library;

// The harness reads the JS runtime of flutter_chartjs, which does not export
// lib/src.
// ignore_for_file: implementation_imports

import 'package:chartjs_test_utils/src/matchers.options.dart';
import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
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
