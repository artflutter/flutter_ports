// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/stack-multiple-scales.js (MIT, Chart.js Contributors).
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
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(255, 0, 0, 0.5)),
        ),
        data: .values(<num?>[null, 1, 1, 1]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toStacked,
      ),
      LineDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(0, 255, 0, 0.5)),
        ),
        data: .values(<num?>[null, 2, 2, 2]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toStacked,
      ),
      LineDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(0, 0, 255, 0.5)),
        ),
        data: .values(<num?>[null, 3, 3, 3]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toStacked,
      ),
      LineDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(255, 0, 255, 0.5)),
        ),
        data: .values(<num?>[0.5, 0.5, 0.5, null]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toStacked,
        extra: <String, Object?>{'yAxisID': 'y2'},
      ),
      LineDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(0, 0, 0, 0.5)),
        ),
        data: .values(<num?>[1.5, 1.5, 1.5, null]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toStacked,
        extra: <String, Object?>{'yAxisID': 'y2'},
      ),
      LineDataset(
        backgroundColor: .constant(
          ChartPaint.solid(Color.fromRGBO(255, 255, 0, 0.5)),
        ),
        data: .values(<num?>[2.5, 2.5, 2.5, null]),
        // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
        fill: FillTarget.toStacked,
        extra: <String, Object?>{'yAxisID': 'y2'},
      ),
    ],
    labels: <Object>['0', '1', '2', '3'],
    responsive: false,
    elements: ChartElements(
      point: PointElementStyle(radius: 0),
      line: LineElementStyle(
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
      'spanGaps': false,
      'scales': <String, Object?>{
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'x': <String, Object?>{'display': ScaleDisplay.off},
        // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
        'y': <String, Object?>{
          'position': ChartPosition.right,
          'stacked': StackMode.on,
          'min': 0,
        },
        // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
        'y2': <String, Object?>{
          'position': ChartPosition.left,
          'stacked': StackMode.on,
          'min': 0,
        },
      },
    },
  ),
  options: <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
);
