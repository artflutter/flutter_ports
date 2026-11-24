// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/dataset/clip-bounds-y-off.js (MIT, Chart.js Contributors).
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
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        data: .values(<num?>[55, 49, 70, 71, 46, 45, 30]),
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(255, 0, 0, 0.25)),
        ),
        extra: <String, Object?>{
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': const FillTarget.toDataset(1),
          'yAxisID': 'y1',
        },
      ),
      LineDataset(
        data: .values(<num?>[65, 59, 80, 81, 56, 55, 40]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        extra: <String, Object?>{'yAxisID': 'y1'},
      ),
      LineDataset(
        data: .values(<num?>[65, 59, 80, 81, 56, 55, 40]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.none,
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        extra: <String, Object?>{'yAxisID': 'y2'},
      ),
      LineDataset(
        data: .values(<num?>[75, 69, 90, 91, 66, 65, 50]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toPrevious,
        borderColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(0, 0, 255, 0.25)),
        ),
        extra: <String, Object?>{'yAxisID': 'y2'},
      ),
    ],
    labels: <Object>[1, 2, 3, 4, 5, 6, 7],
    animation: ChartAnimation.none,
    responsive: false,
    elements: ChartElements(
      point: PointElementStyle(radius: 0),
      line: LineElementStyle(
        // DIVERGES(chartjs): adapt-cubic-interpolation-mode-objects, the mode
        // class.
        cubicInterpolationMode: const MonotoneCubicInterpolationMode(),
        borderColor: ChartPaint.solid(Color(0x00000000)),
        tension: 0,
      ),
    ),
    disabledPlugins: [
      PluginOff<LegendPlugin>(),
      PluginOff<TitlePlugin>(),
      PluginOff<TooltipPlugin>(),
    ],
    extra: <String, Object?>{
      // DIVERGES(chartjs): adapt-chart-clip-option, the clip class.
      'clip': ChartClip.none,
      'scales': <String, Object?>{
        'y2': <String, Object?>{
          // DIVERGES(chartjs): adapt-axis-objects, the axis
          // class.
          'axis': const YAxis(),
          'stack': 'stack',
          'max': 80,
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'display': ScaleDisplay.off,
        },
        'y1': <String, Object?>{
          'min': 50,
          // DIVERGES(chartjs): adapt-axis-objects, the axis
          // class.
          'axis': const YAxis(),
          'stack': 'stack',
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'display': ScaleDisplay.off,
        },
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'x': <String, Object?>{'display': ScaleDisplay.off},
      },
    },
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/12052',
);
