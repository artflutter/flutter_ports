// Ported from Chart.js v4.6.1 test/fixtures/scale.category/max-ticks-limit-b.js (MIT, Chart.js Contributors).
// Each call runs the module body again and gives new objects
// (fixture.js:24): the chart keeps the Lists of its config and writes
// into some of them.
// ignore_for_file: prefer_const_constructors
// ignore_for_file: prefer_const_literals_to_create_immutables
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
// Upstream fixture paths determine the file names.
// ignore_for_file: file_names
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
FixtureConfig fixture() => FixtureConfig.typed(
  ChartConfig(
    datasets: [
      BarDataset(
        data: .values(<num?>[
          1.0,
          2.0,
          3.0,
          4.0,
          5.0,
          6.0,
          7.0,
          8.0,
          9.0,
          10.0,
          11.0,
          12.0,
          13.0,
          14.0,
          15.0,
          16.0,
          17.0,
          18.0,
          19.0,
          20.0,
          21.0,
          22.0,
          23.0,
          24.0,
          25.0,
          26.0,
          27.0,
          28.0,
          29.0,
          30.0,
          31.0,
          32.0,
          33.0,
          34.0,
          35.0,
          36.0,
          37.0,
          38.0,
          39.0,
          40.0,
          41.0,
          42.0,
        ]),
      ),
    ],
    labels: <Object>[
      'tick1',
      'tick2',
      'tick3',
      'tick4',
      'tick5',
      'tick6',
      'tick7',
      'tick8',
      'tick9',
      'tick10',
      'tick11',
      'tick12',
      'tick13',
      'tick14',
      'tick15',
      'tick16',
      'tick17',
      'tick18',
      'tick19',
      'tick20',
      'tick21',
      'tick22',
      'tick23',
      'tick24',
      'tick25',
      'tick26',
      'tick27',
      'tick28',
      'tick29',
      'tick30',
      'tick31',
      'tick32',
      'tick33',
      'tick34',
      'tick35',
      'tick36',
      'tick37',
      'tick38',
      'tick39',
      'tick40',
      'tick41',
      'tick42',
    ],
    scales: [
      CategoryAxis(
        CartesianAxis.x,
        ticks: AxisTicks(display: false, maxTicksLimit: 6),
        grid: AxisGrid(color: ChartPaint.solid(Color(0xFFFF0000))),
      ),
      // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
      LinearAxis(CartesianAxis.y, display: ScaleDisplay.off),
    ],
    padding: const EdgeInsets.fromLTRB(0, 0, 2, 0),
  ),
  description: 'https://github.com/chartjs/Chart.js/issues/7302',
);
