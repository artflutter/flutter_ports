// Original code, not ported from Chart.js: the bar page "From Syncfusion".
// Each note is one long text, split over lines of the source.
// ignore_for_file: no_adjacent_strings_in_list

import 'package:chartjs_docs/migrate/syncfusion/animation_bar.dart';
import 'package:chartjs_docs/migrate/syncfusion/animation_column.dart';
import 'package:chartjs_docs/migrate/syncfusion/axis_base_column.dart';
import 'package:chartjs_docs/migrate/syncfusion/back_to_back_column.dart';
import 'package:chartjs_docs/migrate/syncfusion/customized_bar.dart';
import 'package:chartjs_docs/migrate/syncfusion/customized_column.dart';
import 'package:chartjs_docs/migrate/syncfusion/default_bar.dart';
import 'package:chartjs_docs/migrate/syncfusion/default_column.dart';
import 'package:chartjs_docs/migrate/syncfusion/rounded_bar.dart';
import 'package:chartjs_docs/migrate/syncfusion/rounded_column.dart';
import 'package:chartjs_docs/migrate/syncfusion/spacing_bar.dart';
import 'package:chartjs_docs/migrate/syncfusion/spacing_column.dart';
import 'package:chartjs_docs/migrate/syncfusion/track_bar.dart';
import 'package:chartjs_docs/migrate/syncfusion/track_column.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:material_ui/material_ui.dart';

const String _demos =
    'https://flutter.syncfusion.com/#/cartesian-charts/chart-types/';
const String _columns = '${_demos}column/';
const String _bars = '${_demos}bar/';

/// The page "Migrate bar charts from Syncfusion": the column and bar chart
/// demos of the Syncfusion Flutter gallery.
DocPageContent syncfusionBarMigrationPage() => migrationPage(
  chart: 'bar',
  library: 'Syncfusion',
  version: '35.1.43',
  gallery: '${_columns}default-column-chart',
  icon: Icons.swap_horiz,
  frame: const ReplicaFrame(background: Colors.white),
  kit: const CodeRegion('lib/migrate/syncfusion/sf_bar_kit.dart', 'sf-bar-kit'),
  credit:
      'The demos come from the Syncfusion Flutter gallery. The replicas are '
      'new code, and they use no Syncfusion code.',
  intro: const [
    DocParagraph(
      '`SfCartesianChart` takes a `ColumnSeries` for vertical bars and a '
      '`BarSeries` for horizontal bars. The port has one bar chart for both: '
      'a `BarDataset` draws vertical bars, and `indexAxis: YAxis()` turns '
      'them. The replicas set the colors of the Syncfusion light Material 3 '
      'theme. The track, the data labels, the frame of the plot area and the '
      'custom shapes are small inline plugins. The shared parts are in one '
      'file, `sf_bar_kit.dart`, at the end of the page.',
    ),
  ],
  mapping: const [
    ('SfCartesianChart', '`ChartView(config: ChartConfig(type: .bar))`'),
    ('ColumnSeries', '`BarDataset`'),
    ('BarSeries', '`BarDataset` and `indexAxis: YAxis()` of the chart'),
    (
      'StackedColumnSeries, StackedBarSeries',
      '`BarDataset` and `stacked: true` of both axes',
    ),
    (
      'dataSource, xValueMapper, yValueMapper',
      '`labels` and `data`, or `points`',
    ),
    ('CategoryAxis, NumericAxis', '`CategoryAxis`, `LinearAxis`'),
    (
      'the first category of a BarSeries at the bottom',
      '`reverse: true` of the y `CategoryAxis`',
    ),
    ('minimum, maximum, interval', '`min`, `max` and `ticks.stepSize`'),
    ('labelFormat, numberFormat', 'a tick `callback`'),
    (
      'majorGridLines, majorTickLines, axisLine',
      'the `grid`, `grid.drawTicks` and the `border` of each axis',
    ),
    ('width', '`categoryPercentage`, with `barPercentage: 1`'),
    ('spacing', '`barPercentage: 1 - spacing`'),
    ('enableSideBySideSeriesPlacement: false', '`grouped: false`'),
    (
      'borderRadius',
      '`borderRadius`, and `borderSkipped: false` in `extra` for the corners '
          'on the base',
    ),
    ('color, pointColorMapper', '`backgroundColor`: `.constant` or `.indexed`'),
    ('crossesAt of the x axis', '`base` in `extra` of the dataset'),
    (
      'isTrackVisible, trackColor',
      'an inline plugin that draws before the datasets',
    ),
    (
      'dataLabelSettings, labelAlignment',
      'an inline plugin that draws after the datasets',
    ),
    ('ChartTitle, AxisTitle', '`title: ChartTitle(...)`, `AxisTitle`'),
    ('Legend', '`legend: ChartLegend(...)`, a `PointStyle` for the icon'),
    ('TooltipBehavior', '`tooltip: ChartTooltip(...)`'),
    ('format, header of TooltipBehavior', 'the `label` and `title` callbacks'),
    (
      'SelectionBehavior',
      '`onClick`, and new colors for the selected bar in `setState`',
    ),
    ('onPointTap', '`onClick`: the event, the elements and the chart'),
    (
      'onCreateRenderer',
      'an inline plugin: `beforeDatasetDraw` draws the shapes and returns '
          '`false`',
    ),
    ('plotAreaBorderWidth', 'an inline plugin that draws the frame'),
    ('animationDuration', '`animation`'),
  ],
  demos: [
    ReplicaDemo(
      id: 'sf-column-default',
      title: 'Default Column chart',
      original: '${_columns}default-column-chart',
      region: const CodeRegion(
        'lib/migrate/syncfusion/default_column.dart',
        'sf-default-column',
      ),
      notes: const [
        '`ColumnSeries` is a `BarDataset`. Its default `width: 0.7` is '
            '`categoryPercentage: 0.7` with `barPercentage: 1`.',
        '`DataLabelSettings` is an inline plugin. It writes each value above '
            'its column when the animation stops, as Syncfusion does.',
        "`labelFormat: '{value}%'` is a tick `callback`. Syncfusion picks the "
            'range 0 to 2.5 by itself. The replica sets `min`, `max` and '
            '`stepSize`.',
      ],
      replica: (_) => const SfDefaultColumn(),
    ),
    ReplicaDemo(
      id: 'sf-column-axis-base',
      title: 'Modified axis base',
      original: '${_columns}modified-axis-base',
      region: const CodeRegion(
        'lib/migrate/syncfusion/axis_base_column.dart',
        'sf-axis-base-column',
      ),
      notes: const [
        '`crossesAt` of the x axis sets where the columns start. In the port, '
            'this is `base` in `extra` of the dataset. The x axis stays at the '
            'bottom, as with `placeLabelsNearAxisLine: false`.',
        '`pointColorMapper` is an indexed `backgroundColor`. Each label in the '
            'middle takes black or white, whichever stands out from its '
            'column.',
        'The dropdown of the property panel is a `SegmentedButton`. '
            '`labelIntersectAction: wrap` is a tick `callback` that splits a '
            'long label into words.',
      ],
      replica: (_) => const SfAxisBaseColumn(),
    ),
    ReplicaDemo(
      id: 'sf-column-rounded',
      title: 'Column with rounded corners',
      original: '${_columns}column-with-rounded-corners',
      region: const CodeRegion(
        'lib/migrate/syncfusion/rounded_column.dart',
        'sf-rounded-column',
      ),
      notes: const [
        '`borderRadius: BorderRadius.circular(10)` is `borderRadius: 10`. '
            '`borderSkipped: false` in `extra` also rounds the corners on the '
            'base.',
        'Chart.js has no `labelPosition: inside`. The replica hides the x '
            'axis, and the labels plugin writes the city names in white '
            'inside the columns.',
        "`format: 'point.x : point.y sq.km'` is the `label` callback of the "
            'tooltip.',
      ],
      replica: (_) => const SfRoundedColumn(),
    ),
    ReplicaDemo(
      id: 'sf-column-back-to-back',
      title: 'Back to back column',
      original: '${_columns}back-to-back-column',
      region: const CodeRegion(
        'lib/migrate/syncfusion/back_to_back_column.dart',
        'sf-back-to-back-column',
      ),
      notes: const [
        '`enableSideBySideSeriesPlacement: false` is `grouped: false`. The '
            '`width` of each series is its `categoryPercentage`.',
        '`order` draws the widest column first. The tooltip uses '
            '`PointInteractionMode`, and its `filter` keeps the front column '
            'under the pointer.',
        '`NumberFormat.compact()` is a tick `callback` that writes 56M, 58M '
            'and so on.',
      ],
      replica: (_) => const SfBackToBackColumn(),
    ),
    ReplicaDemo(
      id: 'sf-column-track',
      title: 'Column with track',
      original: '${_columns}column-with-track',
      region: const CodeRegion(
        'lib/migrate/syncfusion/track_column.dart',
        'sf-track-column',
      ),
      notes: const [
        'Chart.js has no track. An inline plugin draws a rounded gray bar '
            'behind each column, from the bottom to the top of the plot area.',
        'The legend icon of a column series is `SfColumnIcon`, a `PointStyle` '
            'in `labels.pointStyle` of the legend.',
        "`format: 'point.y marks in point.x'` is the `label` callback of the "
            'tooltip.',
      ],
      replica: (_) => const SfTrackColumn(),
    ),
    ReplicaDemo(
      id: 'sf-column-spacing',
      title: 'Column width and spacing',
      original: '${_columns}column-width-and-spacing',
      region: const CodeRegion(
        'lib/migrate/syncfusion/spacing_column.dart',
        'sf-spacing-column',
      ),
      notes: const [
        '`width` is `categoryPercentage`: the part of the category that the '
            'group of columns takes. `spacing` is the gap in the place of each '
            'column: `barPercentage: 1 - spacing`.',
        'The buttons below the chart change the two values in steps of 0.1, '
            'as the property panel of the original does.',
      ],
      replica: (_) => const SfSpacingColumn(),
    ),
    ReplicaDemo(
      id: 'sf-column-customized',
      title: 'Customized column chart',
      original: '${_columns}customized-column-chart',
      region: const CodeRegion(
        'lib/migrate/syncfusion/customized_column.dart',
        'sf-customized-column',
      ),
      notes: const [
        'The custom `ColumnSegment` is an inline plugin. Its '
            '`beforeDatasetDraw` hook draws each column with a point of 20 px '
            'on top, and returns `false`: Chart.js then draws no rectangle.',
        'The shapes follow the animated bar elements, so they grow at the '
            'start as in the original.',
        'This demo keeps the default `plotAreaBorderWidth`. An inline plugin '
            'draws the frame of the plot area.',
      ],
      replica: (_) => const SfCustomizedColumn(),
    ),
    ReplicaDemo(
      id: 'sf-column-animation',
      title: 'Dynamic update animation (column)',
      original: '${_columns}dynamic-update-animation',
      region: const CodeRegion(
        'lib/migrate/syncfusion/animation_column.dart',
        'sf-animation-column',
      ),
      notes: const [
        'A `Timer` gives a new data List every 2 seconds in `setState`. The '
            'columns move to the new values in 1.5 seconds, the default '
            '`animationDuration` of a series.',
        'The original has no tooltip, so the replica sets `events` to an '
            'empty List.',
      ],
      replica: (_) => const SfAnimationColumn(),
    ),
    ReplicaDemo(
      id: 'sf-bar-default',
      title: 'Default bar chart',
      original: '${_bars}default-bar-chart',
      region: const CodeRegion(
        'lib/migrate/syncfusion/default_bar.dart',
        'sf-default-bar',
      ),
      notes: const [
        '`BarSeries` is a `BarDataset` in a chart with `indexAxis: YAxis()`. '
            'Syncfusion puts the first category at the bottom, so the y '
            '`CategoryAxis` has `reverse: true`.',
        'Syncfusion also puts the first series at the bottom of each '
            'category. `order` gives the last series the top place, and '
            '`reverse: true` of the legend keeps the order 2015, 2016, 2017.',
        'The tooltip of Syncfusion points at the middle of a bar. '
            '`SfTipPositioner`, a `TooltipPositioner`, gives that position.',
      ],
      replica: (_) => const SfDefaultBar(),
    ),
    ReplicaDemo(
      id: 'sf-bar-rounded',
      title: 'Bar with rounded corners',
      original: '${_bars}bar-with-rounded-corners',
      region: const CodeRegion(
        'lib/migrate/syncfusion/rounded_bar.dart',
        'sf-rounded-bar',
      ),
      notes: const [
        '`borderRadius: 10` with `borderSkipped: false` rounds the four '
            'corners of each bar, also of a negative bar.',
        'The value axis keeps its grid lines and its axis line: the `grid` '
            'and the `border` of the `LinearAxis`.',
      ],
      replica: (_) => const SfRoundedBar(),
    ),
    ReplicaDemo(
      id: 'sf-bar-spacing',
      title: 'Bar width and spacing',
      original: '${_bars}bar-width-and-spacing',
      region: const CodeRegion(
        'lib/migrate/syncfusion/spacing_bar.dart',
        'sf-spacing-bar',
      ),
      notes: const [
        'The years are on a `NumericAxis`. The replica gives `points` with the '
            'value as `x` and the year as `y`, and a `LinearAxis` as the index '
            'axis. `offset: false` puts 2005 and 2011 at the ends.',
        '`width` and `spacing` map as in the column demo: '
            '`categoryPercentage` and `barPercentage: 1 - spacing`.',
      ],
      replica: (_) => const SfSpacingBar(),
    ),
    ReplicaDemo(
      id: 'sf-bar-track',
      title: 'Bar with track',
      original: '${_bars}bar-with-track',
      region: const CodeRegion(
        'lib/migrate/syncfusion/track_bar.dart',
        'sf-track-bar',
      ),
      notes: const [
        'The track plugin draws a gray bar behind each bar, over the full '
            'value axis. Chart.js limits the corner radius to half of the bar '
            'height, as Syncfusion does.',
        '`labelAlignment: top` puts each label inside the end of its bar.',
      ],
      replica: (_) => const SfTrackBar(),
    ),
    ReplicaDemo(
      id: 'sf-bar-customized',
      title: 'Customized bar chart',
      original: '${_bars}customized-bar-chart',
      region: const CodeRegion(
        'lib/migrate/syncfusion/customized_bar.dart',
        'sf-customized-bar',
      ),
      notes: const [
        'The custom `BarSegment` paints an image of orange dashes over each '
            'bar. The replica draws the dashes as lines in '
            '`afterDatasetDraw`, clipped to each bar. A `ChartPattern` of an '
            'image also works as a `backgroundColor`.',
        'The data of the original has a `pointColor` for each app, but the '
            'series has no `pointColorMapper`. Thus all bars take the first '
            'color of the palette.',
      ],
      replica: (_) => const SfCustomizedBar(),
    ),
    ReplicaDemo(
      id: 'sf-bar-animation',
      title: 'Dynamic update animation (bar)',
      original: '${_bars}dynamic-update-animation',
      region: const CodeRegion(
        'lib/migrate/syncfusion/animation_bar.dart',
        'sf-animation-bar',
      ),
      notes: const [
        'The same `Timer` as in the column demo gives 7 values from 10 to 94 '
            'every 2 seconds.',
        'Syncfusion grows the bars from the axis at the start, and Chart.js '
            'does the same.',
      ],
      replica: (_) => const SfAnimationBar(),
    ),
  ],
);
