// Original code, not ported from Chart.js: the page "Migrate from fl_chart".
// Each note is one long text, split over lines of the source.

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
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:material_ui/material_ui.dart';

const String _gallery = 'https://app.flchart.dev/#/line';

/// The page "Migrate from fl_chart": the 13 line samples of fl_chart 1.3.0.
DocPageContent flChartMigrationPage() => migrationPage(
  chart: 'line',
  library: 'fl_chart',
  version: '1.3.0',
  gallery: _gallery,
  icon: Icons.swap_horiz,
  kit: const CodeRegion('lib/migrate/fl_chart/fl_kit.dart', 'fl_chart-kit'),
  frame: const ReplicaFrame(background: Fl.item, dark: true),
  credit: const Text(
    'The demos and the data of samples 12 and 13 come from the fl_chart '
    'example app (MIT, Flutter 4 Fun). The replicas are new code.',
  ),
  intro: const [
    DocParagraph(
      DocText(
        'fl_chart builds a chart from one data object: `LineChartData` with '
        'its `lineBarsData`. The port takes a `ChartConfig` with its '
        '`datasets`, as Chart.js does. Most parameters have a direct '
        'equivalent. A few fl_chart features, for example the drop lines of '
        'the spots and the extra lines, are small inline plugins.',
      ),
    ),
  ],
  mapping: const [
    (
      Text('LineChart(LineChartData(...))'),
      DocText('`ChartView(config: ChartConfig(...))`'),
    ),
    (
      Text('lineBarsData: [LineChartBarData]'),
      DocText('`datasets: [LineDataset]`'),
    ),
    (
      Text('spots: [FlSpot(x, y)]'),
      DocText(
        '`data: .points([DataPoint(x, y)])`, or `data: .values(...)` '
        'with `labels`',
      ),
    ),
    (
      Text('color, gradient'),
      DocText('`borderColor: ChartValue`, a scriptable gradient'),
    ),
    (Text('isCurved, curveSmoothness'), DocText('`tension`')),
    (Text('isStepLineChart'), DocText('`stepped`')),
    (Text('dotData'), DocText('`pointRadius`, `pointStyle`, the point colors')),
    (
      Text('belowBarData, aboveBarData'),
      DocText('`fill` and `backgroundColor`'),
    ),
    (Text('betweenBarsData'), DocText('`fill: FillTarget.toDataset(i)`')),
    (Text('shadow'), DocText('`shadow: ChartShadow(...)`')),
    (Text('dashArray'), DocText('`borderDash`')),
    (
      Text('minX, maxX, minY, maxY'),
      DocText('`min` and `max` of `LinearAxis`'),
    ),
    (Text('titlesData'), DocText('the `ticks` and `title` of each axis')),
    (Text('gridData'), DocText('the `grid` of each axis')),
    (Text('borderData'), DocText('the `border` of each axis, an `AxisBorder`')),
    (
      Text('lineTouchData'),
      DocText('`tooltip`, `interaction`, `onHover` and `onClick`'),
    ),
    (
      Text('extraLinesData'),
      DocText('an inline plugin that draws in `afterDatasetsDraw`'),
    ),
    (Text('duration, curve'), DocText('`animation`')),
  ],
  demos: [
    for (final (index, (notes, sample)) in _samples.indexed)
      ReplicaDemo(
        id: 'fl-${index + 1}',
        title: Text('Line Chart ${index + 1}'),
        original: _gallery,
        region: CodeRegion(
          'lib/migrate/fl_chart/s${_number(index)}.dart',
          'fl_chart-${_number(index)}',
        ),
        notes: notes,
        replica: (_) => sample,
      ),
  ],
);

/// The number of the sample [index] with two digits, as in the names of its
/// file and its code region.
String _number(int index) => (index + 1).toString().padLeft(2, '0');

/// The notes and the replica of each sample, in the order of the gallery.
const List<(List<Widget>, Widget)> _samples = [
  (
    [
      DocText(
        'Three curved datasets with `tension`, and labels of chosen ticks from '
        'a tick `callback`.',
      ),
      DocText(
        'The refresh button gives a new `ChartConfig` in `setState`. The '
        'chart animates to the new values.',
      ),
    ],
    Sample1(),
  ),
  (
    [
      DocText(
        'A gradient line and a gradient area: `borderColor` and '
        '`backgroundColor` are scriptable values that build a canvas '
        'gradient over the chart area.',
      ),
      DocText('The button switches between the data and the average.'),
    ],
    Sample2(),
  ),
  (
    [
      DocText('The drop lines of the spots of fl_chart are an inline plugin.'),
      DocText('The switches change `stepped` and the area fill in `setState`.'),
    ],
    Sample3(),
  ),
  (
    [
      DocText(
        'One area fill with two colors: `fill` with a target split into the '
        'colors `above` and `below` (`FillTarget.split`).',
      ),
      DocText('A tick `callback` writes the labels of the y axis.'),
    ],
    Sample4(),
  ),
  (
    [
      DocText(
        'fl_chart keeps tooltips open on chosen spots. An inline plugin draws '
        'these labels, because the tooltip of Chart.js shows one group.',
      ),
      DocText('A gradient line, as in sample 2.'),
    ],
    Sample5(),
  ),
  (
    [
      DocText(
        'Large points with `pointRadius`, and a y axis with `reverse: true`.',
      ),
      DocText('`clip: ChartClip.none` lets the points overlap the chart edge.'),
    ],
    Sample6(),
  ),
  (
    [
      DocText(
        'The fill between two lines of `betweenBarsData` is '
        '`fill: FillTarget.toDataset(i)`.',
      ),
    ],
    Sample7(),
  ),
  (
    [
      DocText(
        'The extra lines, their labels and the picture of the sample are an '
        'inline plugin that draws on the canvas.',
      ),
      DocText('The dashed lines use `borderDash`.'),
    ],
    Sample8(),
  ),
  (
    [
      DocText(
        'A line with many points. The touch of fl_chart finds the spot near '
        'the x of the pointer: `interaction` with the mode `x`.',
      ),
    ],
    Sample9(),
  ),
  (
    [
      DocText(
        'Live data: a `Timer` gives new points in `setState`. The port '
        'updates the chart in place.',
      ),
    ],
    Sample10(),
  ),
  (
    [
      DocText(
        'Ticks at chosen values around a baseline, set in `afterBuildTicks`.',
      ),
      DocText('The sliders change the values in `setState`.'),
    ],
    Sample11(),
  ),
  (
    [
      DocText('The price data of the sample, loaded from an asset.'),
      DocText(
        'The buttons zoom and pan through `min` and `max` of the x axis.',
      ),
    ],
    Sample12(),
  ),
  (
    [
      DocText('The weather data of the sample, loaded from an asset.'),
      DocText(
        'The error bars of fl_chart are an inline plugin, because Chart.js '
        'has no error bars.',
      ),
    ],
    Sample13(),
  ),
];
