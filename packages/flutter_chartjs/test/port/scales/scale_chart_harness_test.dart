// Original code, not ported from Chart.js: self-test of the scale harness.
@TestOn('vm')
library;

import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scale_chart_harness.dart';
import 'scale_chart_harness_reference.dart';

// The self-test of the method of the phase 6 scale reference tests
// (scale_chart_harness.dart, tool/reference/scale_chart_common.mjs), with
// the cases of tool/reference/scale_chart_harness_reference.mjs. The
// generator builds each chart with a build of the pinned Chart.js in Node.js
// v24.12.0 on x64 (Chart.js ADR 0010). Its mock context measures text in
// Liberation Sans 2.1.5, the test font of the harness.
//
// Each chart comes from acquireChart in a testWidgets case (Chart.js ADR
// 0022). No phase 6 scale is ported yet. Thus main() registers test scales
// and test controllers through their class values: `harnessLinear` on both
// axes of the cartesian test controller `harnessTest`, `harnessMeasure` (a
// measure with no font write, as in the time scale), and `harnessRadial` on
// the axis r of the radial test controller `harnessRadialTest`. The
// registration runs before the snapshot of the defaults restore (Chart.js
// ADR 0020, section 8, and Chart.js ADR 0022, section 8). The generator
// registers the same classes after the six scales and the four elements of
// the dist. The scales of the dist do not change a chart of the test
// scales: a scale registers only its own defaults.
//
// The cases compare the chart area, each scale (ticks, labels, box, label
// rotation, paddings and the pixel mapping), the points and the calls of
// one draw. The group of widths measures each text of the generator on the
// canvas of the harness.

/// The test scale `harnessLinear` of the generator: the range of the data
/// (`getMinMax`), five ticks at equal steps from min to max, and a linear
/// mapping.
final class _HarnessLinearScale extends Scale {
  _HarnessLinearScale(super.cfg);

  @override
  void determineDataLimits() {
    final (:min, :max) = getMinMax(false);
    this.min = min;
    this.max = max;
  }

  @override
  List<Tick>? buildTicks() => [
    for (var i = 0; i <= 4; i++) Tick(value: min + ((max - min) * i) / 4),
  ];

  @override
  double getPixelForValue(Object? value, [double? index]) {
    return getPixelForDecimal((jsToNumber(value) - min) / (max - min));
  }

  @override
  double getValueForPixel(double pixel) {
    return min + getDecimalForPixel(pixel) * (max - min);
  }
}

/// `class HarnessLinearScale extends Scale` of the generator.
final JsClass _harnessLinearScale = JsClass(
  'HarnessLinearScale',
  superclass: Scale.jsClass,
  statics: {'id': 'harnessLinear', 'defaults': <String, Object?>{}},
  construct: (newTarget, args) => _HarnessLinearScale(scaleCfgArg(args)),
);

/// The test scale `harnessMeasure` of the generator: `harnessLinear`, and in
/// `buildTicks` a measure of the text 'January' with no font write, as
/// `_getLabelSize` of the time scale (scale.time.js:591-593). The measure
/// takes the current font of the context: the first font of the canvas, or
/// the last tick font of the layout. Before the measure, a save, a font
/// write and a restore must leave that font. [measures] has the widths of
/// the measures, in order.
final class _HarnessMeasureScale extends _HarnessLinearScale {
  _HarnessMeasureScale(super.cfg);

  /// The width of each measure, in order.
  final List<double> measures = [];

  @override
  List<Tick>? buildTicks() {
    final ctx = this.ctx!
      ..save()
      ..font = 'normal bold 20px Arial'
      ..restore();
    measures.add(ctx.measureText('January').width);
    return super.buildTicks();
  }
}

/// `class HarnessMeasureScale extends HarnessLinearScale` of the generator.
final JsClass _harnessMeasureScale = JsClass(
  'HarnessMeasureScale',
  superclass: _harnessLinearScale,
  statics: {'id': 'harnessMeasure', 'defaults': <String, Object?>{}},
  construct: (newTarget, args) => _HarnessMeasureScale(scaleCfgArg(args)),
);

/// The observation `measures` of a `harnessMeasure` scale: `measures` of the
/// generator.
Map<String, Object?> _measures(Scale scale, Chart chart) =>
    scale is _HarnessMeasureScale
    ? {'measures': List.of(scale.measures)}
    : const {};

/// The test scale `harnessRadial` of the generator, for the axis r: the
/// range of the data, the ticks min and max, and a point position that
/// depends on the box, the index and the value. Its options have
/// `display: false`: the base class has no drawing for the position
/// `chartArea`.
final class _HarnessRadialScale extends Scale {
  _HarnessRadialScale(super.cfg);

  @override
  void determineDataLimits() {
    final (:min, :max) = getMinMax(false);
    this.min = min;
    this.max = max;
  }

  @override
  List<Tick>? buildTicks() => [Tick(value: min), Tick(value: max)];

  /// `getPointPositionForValue(index, value)` of the generator.
  ///
  /// [value] is the parsed value r, unchanged (Chart.js ADR 0025, section
  /// 9). The data of the cases are numbers. For a number, and also for
  /// null, undefined and a boolean, the JS `left + value` is the sum with
  /// ToNumber of [value].
  RadialPointPosition getPointPositionForValue(double index, Object? value) =>
      (x: left + jsToNumber(value), y: top + 10 * index, angle: index / 2);
}

/// `class HarnessRadialScale extends Scale` of the generator.
final JsClass _harnessRadialScale = JsClass(
  'HarnessRadialScale',
  superclass: Scale.jsClass,
  statics: {
    'id': 'harnessRadial',
    'defaults': <String, Object?>{'display': false},
  },
  construct: (newTarget, args) => _HarnessRadialScale(scaleCfgArg(args)),
);

/// The cartesian test controller `harnessTest` of the generator.
final JsClass _harnessTestController = cartesianTestController('harnessTest', {
  'scales': <String, Object?>{
    '_index_': <String, Object?>{'type': 'harnessLinear'},
    '_value_': <String, Object?>{'type': 'harnessLinear'},
  },
});

/// The radial test controller `harnessRadialTest` of the generator.
final JsClass _harnessRadialTestController = radialTestController(
  'harnessRadialTest',
  {
    'aspectRatio': 1.0,
    'scales': <String, Object?>{
      'r': <String, Object?>{'type': 'harnessRadial'},
    },
  },
  (scale, index, value) =>
      (scale as _HarnessRadialScale).getPointPositionForValue(index, value),
);

/// The named functions of the configs of the generator.
final Map<String, Object?> _functions = {
  'withUnit': (Object? value) => '${jsToString(value)} kg',
};

void main() {
  // Before the snapshot of the defaults restore (Chart.js ADR 0022, section
  // 8). The restore does not reset the items of the registry.
  Chart.register([
    _harnessLinearScale,
    _harnessMeasureScale,
    _harnessRadialScale,
    _harnessTestController,
    _harnessRadialTestController,
  ]);

  testReferenceOrigin(
    node: scaleChartHarnessReferenceNode,
    arch: scaleChartHarnessReferenceArch,
    dist: scaleChartHarnessReferenceDist,
    commit: scaleChartHarnessReferenceCommit,
  );

  group('test scale charts against upstream', () {
    testScaleChartCases(
      scaleChartHarnessReference,
      functions: _functions,
      extra: _measures,
    );
  });

  group('Liberation Sans widths of the generator', () {
    testReferenceWidths(scaleChartHarnessReferenceWidths);
  });
}
