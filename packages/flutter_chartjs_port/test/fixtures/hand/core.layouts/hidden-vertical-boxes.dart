// Ported from Chart.js v4.6.1 test/fixtures/core.layouts/hidden-vertical-boxes.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  raw(
    ChartConfig(
      datasets: [
        LineDataset(data: .values(<num?>[10, 5, 0, 25, 78, -10])),
      ],
      labels: <Object>['tick1', 'tick2', 'tick3', 'tick4', 'tick5', ''],
      disabledPlugins: [PluginOff<LegendPlugin>()],
    ),
    <String, Object?>{
      'scales': <String, Object?>{
        // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
        'x': <String, Object?>{'display': ScaleDisplay.off},
        'y': <String, Object?>{
          'type': 'linear',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          'ticks': <String, Object?>{
            // A TickCallback (row adapt-native-tick).
            'callback':
                (Object? scale, double value, int index, Object? ticks) {
                  return <String>['${jsToString(value)} very long unit!'];
                },
          },
        },
        'y1': <String, Object?>{
          'type': 'linear',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'display': ScaleDisplay.off,
        },
        'y2': <String, Object?>{
          'type': 'linear',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'display': ScaleDisplay.off,
        },
        'y3': <String, Object?>{
          'type': 'linear',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'display': ScaleDisplay.off,
        },
        'y4': <String, Object?>{
          'type': 'linear',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'display': ScaleDisplay.off,
        },
        'y5': <String, Object?>{
          'type': 'linear',
          // DIVERGES(chartjs): adapt-chart-position-enum, the enum value.
          'position': ChartPosition.left,
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'display': ScaleDisplay.off,
        },
      },
    },
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 256, height: 256)),
);
