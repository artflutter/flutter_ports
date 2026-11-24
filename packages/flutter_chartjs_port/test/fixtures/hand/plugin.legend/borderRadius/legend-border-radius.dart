// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/borderRadius/legend-border-radius.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-native-legend-item, native item access.
// ignore_for_file: file_names
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/chartjs.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      LineDataset(
        label: '# of Votes',
        data: .values(<num?>[12, 19, 3, 5, 2, 3]),
        borderWidth: 1,
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF0000))),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF00FF00))),
      ),
      LineDataset(
        label: '# of Points',
        data: .values(<num?>[7, 11, 5, 8, 3, 7]),
        borderWidth: 2,
        borderColor: .constant(ChartPaint.solid(Color(0xFFFF00FF))),
        backgroundColor: .constant(ChartPaint.solid(Color(0xFF0000FF))),
      ),
    ],
    labels: <Object>['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
    scales: [
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      CategoryAxis(CartesianAxis.x, display: ScaleDisplay.off),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    pluginOptions: [
      // DIVERGES(chartjs): adapt-native-plugin-options, one options object.
      LegendOptions(
        labels: LegendLabelOptions(
          generateLabels: (Chart chart) {
            // Chart.defaults.plugins.legend.labels.generateLabels(chart)
            final legendDefaults =
                jsGet(jsGet(Chart.defaults, 'plugins'), 'legend')!
                    as LegendOptions;
            final generateLabels =
                legendDefaults.labels!.generateLabels! as LegendLabelsGenerator;
            final items = generateLabels(chart);

            for (final item in items) {
              item.borderRadius = const BorderRadius.all(Radius.circular(5));
            }

            return items;
          },
        ),
      ),
    ],
    disabledPlugins: [
      PluginOff<TitlePlugin>(),
      PluginOff<TooltipPlugin>(),
      PluginOff<FillerPlugin>(),
    ],
  ),
  options: AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
