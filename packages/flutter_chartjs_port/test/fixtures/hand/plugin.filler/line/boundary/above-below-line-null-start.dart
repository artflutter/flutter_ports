// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/boundary/above-below-line-null-start.json (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart' show nativeFixturePaint;
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        borderColor: .constant(ChartPaint.solid(Color(0xFF2A5A91))),
        data: .values(<num?>[
          null,
          12,
          30,
          36,
          45,
          53,
          68,
          79,
          null,
          95,
          18,
          18,
          180,
        ]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toNext.split(
          above: nativeFixturePaint('rgba(4, 142, 43, 0.5)'),
          below: nativeFixturePaint('rgba(241, 49, 34, 0.5)'),
        ),
      ),
      LineDataset(
        borderColor: .constant(ChartPaint.solid(Color(0xFF00ADEE))),
        data: .values(<num?>[
          null,
          0,
          0,
          0,
          0,
          0,
          20,
          108,
          null,
          72,
          72,
          72,
          72,
        ]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
      ),
    ],
    labels: <Object>[
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
      '13',
    ],
    responsive: false,
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    elements: ChartElements(
      point: PointElementStyle(radius: 0),
      line: LineElementStyle(
        // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
        // class.
        cubicInterpolationMode: const MonotoneCubicInterpolationMode(),
        borderColor: ChartPaint.solid(Color(0x00000000)),
      ),
    ),
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<TitlePlugin>(),
      PluginOff<TooltipPlugin>(),
    ],
    extra: <String, Object?>{'spanGaps': false},
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
