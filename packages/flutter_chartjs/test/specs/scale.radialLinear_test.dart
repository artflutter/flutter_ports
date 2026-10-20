// Ported from Chart.js v4.5.1 test/specs/scale.radialLinear.tests.js (MIT, Chart.js Contributors).
@TestOn('vm')
library;

// The spec reads the registry and the defaults of flutter_chartjs, which
// does not export lib/src yet.
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_test/flutter_test.dart';

// `Chart.registry` and `Chart.defaults` are the statics of Chart of
// core.controller.dart. The two cases without a chart read only the
// registry and `Chart.defaults.scales.radialLinear`. They need the built-in
// scales that flutter_test_config.dart registers. Thus the file does not
// call `setUpSpecs()`. It runs on the VM, because core.controller.dart
// reaches the platform layer.
//
// Each chart case has the type `radar` or `polarArea`. The scale `r` gets
// the type `radialLinear` from the overrides of the controller. Thus each
// chart case waits for its controller of phase 7. The case "Should ensure
// that the scale has a max and min that are not equal" has no dataset, but
// it needs the radar overrides too: without them, the scale has no
// radialLinear defaults, and `fit` throws a TypeError. Three cases also
// need the legend plugin of phase 8. The legend makes the chart area
// smaller, and the cases compare `drawingArea` (215), `yCenter` (280) and
// the values that come from them. Without the legend, these are 231 and
// 264. A case that needs a module of a later phase skips with the missing
// module of the latest phase.
//
// The spec forms:
// - A property chain of the spec, for example `Chart.defaults.scales`, is a
//   chain of `jsGet`.
// - `typeof x` is `jsTypeof(x)`. The class value of a scale is a `JsClass`,
//   and its `typeof` is `'function'` (Chart.js ADR 0020).
// - `toEqual` of an object compares the keys and the values with `equals`.
//   A routed key, for example `ticks.color`, is a key of the RoutedScope
//   and reads its route target. The key `backdropColor` holds the
//   `undefined` sentinel. Functions compare by identity.
// - `jasmine.any(Function)` is [_anyFunction], which uses `jsIsFunction`. A
//   value with `typeof` `'function'` is a Dart `Function`, a `JsFunction`
//   or a `JsClass`. `ticks.callback` is the JsFunction `formatters.numeric`,
//   which reads `this`. Thus `isA<Function>()` does not match it.
//
// The helper `getLabels(scale)` (scale.radialLinear.tests.js:1-3) comes
// with the bodies of the chart cases. These bodies read `_pointLabels` and
// `_pointLabelItems` as `pointLabels` and `pointLabelItems` (Chart.js ADR
// 0012, Underscore members, and Chart.js ADR 0025, section 6).

/// `jasmine.any(Function)`: a value with `typeof` `'function'`.
final Matcher _anyFunction = predicate(jsIsFunction, 'any Function');

void main() {
  // Tests for the radial linear scale used by the polar area and radar charts
  group('Test the radial linear scale', () {
    // describe('auto', jasmine.fixture.specs('scale.radialLinear')): a
    // fixture group of phase 7, not a case.

    test('Should register the constructor with the registry', () {
      final constructor = Chart.registry.getScale('radialLinear');
      expect(constructor, isNot(same(undefined)));
      expect(jsTypeof(constructor), 'function');
    });

    test('Should have the correct default config', () {
      final defaultConfig = jsGet(
        jsGet(Chart.defaults, 'scales'),
        'radialLinear',
      );
      expect(
        defaultConfig,
        equals(<String, Object?>{
          'display': true,
          'animate': true,
          'position': 'chartArea',

          'angleLines': <String, Object?>{
            'display': true,
            'color': 'rgba(0,0,0,0.1)',
            'lineWidth': 1,
            'borderDash': <Object?>[],
            'borderDashOffset': 0.0,
          },

          'grid': <String, Object?>{'circular': false},

          'startAngle': 0,

          'ticks': <String, Object?>{
            'color': jsGet(Chart.defaults, 'color'),
            'showLabelBackdrop': true,
            'callback': jsGet(jsGet(defaultConfig, 'ticks'), 'callback'),
          },

          'pointLabels': <String, Object?>{
            'backdropColor': undefined,
            'backdropPadding': 2,
            'color': jsGet(Chart.defaults, 'color'),
            'display': true,
            'font': <String, Object?>{'size': 10},
            'callback': jsGet(jsGet(defaultConfig, 'pointLabels'), 'callback'),
            'padding': 5,
            'centerPointLabels': false,
          },
        }),
      );

      // Is this actually a function
      expect(jsGet(jsGet(defaultConfig, 'ticks'), 'callback'), _anyFunction);
      expect(
        jsGet(jsGet(defaultConfig, 'pointLabels'), 'callback'),
        _anyFunction,
      );
    });

    test(
      'Should correctly determine the max & min data values',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'Should correctly determine the max & min of string data values',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'Should correctly determine the max & min data values when there are '
      'hidden datasets',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'Should correctly determine the max & min data values when there is '
      'NaN data',
      () {},
      skip: 'blocked: controller.radar',
    );

    // :142-160 has `datasets: []`, but its scale `rScale` gets the type and
    // the defaults of radialLinear only from the radar overrides.
    test(
      'Should ensure that the scale has a max and min that are not equal',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'Should use the suggestedMin and suggestedMax options',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'Should use the min and max options',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'should forcibly include 0 in the range if the beginAtZero option is '
      'used',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'Should generate tick marks in the correct order in reversed mode',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'Should correctly limit the maximum number of ticks',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'Should build labels using the user supplied callback',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'Should build point labels using the user supplied callback',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'Should build point labels from falsy values',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'Should build point labels considering hidden data',
      () {},
      skip: 'blocked: controller.polarArea',
    );

    // :388-413 also needs controller.radar. Without the legend, drawingArea
    // is 231 and yCenter is 264, not 215 and 280.
    test(
      'should correctly set the center point',
      () {},
      skip: 'blocked: plugin.legend',
    );

    test(
      'should correctly get the label for a given data index',
      () {},
      skip: 'blocked: controller.radar',
    );

    // :439-473 also needs controller.radar. Without the legend, the distance
    // of the max is 231, not 215.
    test(
      'should get the correct distance from the center point',
      () {},
      skip: 'blocked: plugin.legend',
    );

    // :475-508 also needs controller.radar. Without the legend, the value
    // for the distance 215 is not the max.
    test(
      'should get the correct value for a distance from the center point',
      () {},
      skip: 'blocked: plugin.legend',
    );

    test(
      'should correctly get angles for all points',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'should correctly get the correct label alignment for all points',
      () {},
      skip: 'blocked: controller.radar',
    );

    test(
      'should correctly get the point positions in center',
      () {},
      skip: 'blocked: controller.polarArea',
    );
  });
}
