// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/maxWidth/undefined.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADRs 0115
/// and 0193).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it, with the
/// legend options as one object. Each call makes new objects.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        label: '# of Votes',
        data: .values(<num?>[12, 19, 3, 5, 2, 3]),
        borderWidth: 1,
      ),
      LineDataset(
        label: '# of Points',
        data: .values(<num?>[7, 11, 5, 8, 3, 7]),
        borderWidth: 1,
      ),
    ],
    labels: <Object>['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
    scales: [
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    disabledPlugins: [
      PluginOff<TitlePlugin>(),
      PluginOff<TooltipPlugin>(),
      PluginOff<FillerPlugin>(),
    ],
    extra: <String, Object?>{
      'plugins': <String, Object?>{
        // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
        'legend': const LegendOptions(position: ChartPosition.left),
      },
    },
  ),
  options: <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 150, 'height': 75},
  },
);
