// Original code, not ported from Chart.js: the page "Migrate from fl_chart".
// Each note is one long text, split over lines of the source.
// ignore_for_file: no_adjacent_strings_in_list

import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart' show Fl;
import 'package:chartjs_docs/migrate/fl_chart/s01.dart';
import 'package:chartjs_docs/migrate/fl_chart/s02.dart';
import 'package:chartjs_docs/migrate/fl_chart/s03.dart';
import 'package:chartjs_docs/migrate/fl_chart/s04.dart';
import 'package:chartjs_docs/migrate/fl_chart/s05.dart';
import 'package:chartjs_docs/migrate/fl_chart/s06.dart';
import 'package:chartjs_docs/migrate/fl_chart/s07.dart';
import 'package:chartjs_docs/migrate/fl_chart/s08.dart';
import 'package:chartjs_docs/migrate/fl_chart/s09.dart';
import 'package:chartjs_docs/migrate/fl_chart/s10.dart';
import 'package:chartjs_docs/migrate/fl_chart/s11.dart';
import 'package:chartjs_docs/migrate/fl_chart/s12.dart';
import 'package:chartjs_docs/migrate/fl_chart/s13.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:material_ui/material_ui.dart';

const String _gallery = 'https://app.flchart.dev/#/line';

/// The page "Migrate from fl_chart": the 13 line samples of fl_chart 1.3.0.
DocPageContent flChartMigrationPage() => migrationPage(
  library: 'fl_chart',
  version: '1.3.0',
  gallery: _gallery,
  icon: Icons.swap_horiz,
  kit: 'fl_chart-kit',
  frame: const ReplicaFrame(background: Fl.item, dark: true),
  credit:
      'The demos and the data of samples 12 and 13 come from the fl_chart '
      'example app (MIT, Flutter 4 Fun). The replicas are new code.',
  intro: const [
    DocParagraph(
      'fl_chart builds a chart from one data object: `LineChartData` with '
      'its `lineBarsData`. The port takes a `ChartConfig` with its '
      '`datasets`, as Chart.js does. Most parameters have a direct '
      'equivalent. A few fl_chart features, for example the drop lines of '
      'the spots and the extra lines, are small inline plugins.',
    ),
  ],
  mapping: const [
    ('LineChart(LineChartData(...))', '`ChartView(config: ChartConfig(...))`'),
    ('lineBarsData: [LineChartBarData]', '`datasets: [LineDataset]`'),
    (
      'spots: [FlSpot(x, y)]',
      '`points: [DataPoint(x, y)]`, or `data` with '
          '`labels`',
    ),
    ('color, gradient', '`borderColor: ChartValue`, a scriptable gradient'),
    ('isCurved, curveSmoothness', '`tension`'),
    ('isStepLineChart', '`stepped`'),
    ('dotData', '`pointRadius`, `pointStyle`, the point colors'),
    ('belowBarData, aboveBarData', '`fill` and `backgroundColor`'),
    ('betweenBarsData', '`fill: FillTarget.toDataset(i)`'),
    ('shadow', '`shadow: ChartShadow(...)`'),
    ('dashArray', '`borderDash`'),
    ('minX, maxX, minY, maxY', '`min` and `max` of `LinearAxis`'),
    ('titlesData', 'the `ticks` and `title` of each axis'),
    ('gridData', 'the `grid` of each axis'),
    ('borderData', 'the `border` of each axis, in `extra`'),
    ('lineTouchData', '`tooltip`, `interaction`, `onHover` and `onClick`'),
    ('extraLinesData', 'an inline plugin that draws in `afterDatasetsDraw`'),
    ('duration, curve', '`animation`'),
  ],
  demos: [
    for (final (index, (notes, sample)) in _samples.indexed)
      ReplicaDemo(
        id: 'fl-${index + 1}',
        title: 'Line Chart ${index + 1}',
        original: _gallery,
        region: 'fl_chart-${(index + 1).toString().padLeft(2, '0')}',
        notes: notes,
        replica: (_) => sample,
      ),
  ],
);

/// The notes and the replica of each sample, in the order of the gallery.
const List<(List<String>, Widget)> _samples = [
  (
    [
      'Three curved datasets with `tension`, and labels of chosen ticks from '
          'a tick `callback`.',
      'The refresh button gives a new `ChartConfig` in `setState`. The '
          'chart animates to the new values.',
    ],
    Sample1(),
  ),
  (
    [
      'A gradient line and a gradient area: `borderColor` and '
          '`backgroundColor` are scriptable values that build a canvas '
          'gradient over the chart area.',
      'The button switches between the data and the average.',
    ],
    Sample2(),
  ),
  (
    [
      'The drop lines of the spots of fl_chart are an inline plugin.',
      'The switches change `stepped` and the area fill in `setState`.',
    ],
    Sample3(),
  ),
  (
    [
      'One area fill with two colors: `fill` with a `target` value and the '
          'colors `above` and `below`, in `extra`.',
      'A tick `callback` writes the labels of the y axis.',
    ],
    Sample4(),
  ),
  (
    [
      'fl_chart keeps tooltips open on chosen spots. An inline plugin draws '
          'these labels, because the tooltip of Chart.js shows one group.',
      'A gradient line, as in sample 2.',
    ],
    Sample5(),
  ),
  (
    [
      'Large points with `pointRadius`, and a y axis with `reverse: true`.',
      '`clip: ChartClip.none` lets the points overlap the chart edge.',
    ],
    Sample6(),
  ),
  (
    [
      'The fill between two lines of `betweenBarsData` is '
          '`fill: FillTarget.toDataset(i)`.',
    ],
    Sample7(),
  ),
  (
    [
      'The extra lines, their labels and the picture of the sample are an '
          'inline plugin that draws on the canvas.',
      'The dashed lines use `borderDash`.',
    ],
    Sample8(),
  ),
  (
    [
      'A line with many points. The touch of fl_chart finds the spot near '
          'the x of the pointer: `interaction` with the mode `x`.',
    ],
    Sample9(),
  ),
  (
    [
      'Live data: a `Timer` gives new points in `setState`. The port '
          'updates the chart in place.',
    ],
    Sample10(),
  ),
  (
    [
      'Ticks at chosen values around a baseline, set in `afterBuildTicks`.',
      'The sliders change the values in `setState`.',
    ],
    Sample11(),
  ),
  (
    [
      'The price data of the sample, loaded from an asset.',
      'The buttons zoom and pan through `min` and `max` of the x axis.',
    ],
    Sample12(),
  ),
  (
    [
      'The weather data of the sample, loaded from an asset.',
      'The error bars of fl_chart are an inline plugin, because Chart.js '
          'has no error bars.',
    ],
    Sample13(),
  ),
];
