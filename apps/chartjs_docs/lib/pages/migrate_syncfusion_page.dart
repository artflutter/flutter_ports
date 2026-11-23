// Original code, not ported from Chart.js: the page "Migrate from Syncfusion".
// Each note is one long text, split over lines of the source.

import 'package:chartjs_docs/migrate/syncfusion/animation_line.dart';
import 'package:chartjs_docs/migrate/syncfusion/customized_line.dart';
import 'package:chartjs_docs/migrate/syncfusion/default_line.dart';
import 'package:chartjs_docs/migrate/syncfusion/line_dashes.dart';
import 'package:chartjs_docs/migrate/syncfusion/line_zone.dart';
import 'package:chartjs_docs/migrate/syncfusion/multi_colored_line.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:material_ui/material_ui.dart';

const String _demos =
    'https://flutter.syncfusion.com/#/cartesian-charts/chart-types/line/';
const String _gallery = '${_demos}default-line-chart';

/// The page "Migrate from Syncfusion": the line chart demos of the
/// Syncfusion Flutter gallery.
DocPageContent syncfusionMigrationPage() => migrationPage(
  chart: 'line',
  library: 'Syncfusion',
  version: '35.1.43',
  gallery: _gallery,
  icon: Icons.swap_horiz,
  frame: const ReplicaFrame(background: Colors.white),
  credit: const Text(
    'The demos come from the Syncfusion Flutter gallery. The replicas are '
    'new code, and they use no Syncfusion code.',
  ),
  intro: const [
    DocParagraph(
      DocText(
        '`SfCartesianChart` takes its series, its axes and its behaviors as '
        'widgets. The port takes a `ChartConfig` with `datasets` and '
        '`scales`, as Chart.js does. The replicas set the colors of the '
        'Syncfusion light Material 3 theme: the series palette, the gray axis '
        'labels and the dark tooltip. A custom renderer, a trackball line and '
        'an annotation become small inline plugins that draw on the canvas.',
      ),
    ),
  ],
  mapping: const [
    (
      Text('SfCartesianChart'),
      DocText('`ChartView(config: ChartConfig(...))`'),
    ),
    (Text('LineSeries'), DocText('`LineDataset`')),
    (
      Text('dataSource, xValueMapper, yValueMapper'),
      DocText('`labels` and `data: .values(...)`, or `data: .points(...)`'),
    ),
    (
      Text('CategoryAxis, NumericAxis, DateTimeAxis'),
      DocText('`CategoryAxis`, `LinearAxis`, `TimeAxis`'),
    ),
    (
      Text('minimum, maximum, interval'),
      DocText('`min`, `max` and `ticks.stepSize`'),
    ),
    (Text('labelFormat'), DocText('a tick `callback`')),
    (
      Text('edgeLabelPlacement: shift'),
      DocText('`align: .inner` of `AxisTicks`'),
    ),
    (
      Text('majorGridLines, axisLine'),
      DocText('the `grid` and the `border` of each axis'),
    ),
    (Text('ChartTitle'), DocText('`TitleOptions(...)` in `pluginOptions`')),
    (Text('Legend'), DocText('`LegendOptions(...)` in `pluginOptions`')),
    (
      Text('TooltipBehavior'),
      DocText('`TooltipOptions(...)` in `pluginOptions`'),
    ),
    (
      Text('TrackballBehavior'),
      DocText(
        '`interaction` with `intersect: false`, and an inline plugin for the '
        'line',
      ),
    ),
    (
      Text('MarkerSettings'),
      DocText('`pointRadius`, `pointStyle` and the point colors'),
    ),
    (Text('width, dashArray'), DocText('`borderWidth`, `borderDash`')),
    (
      Text('pointColorMapper'),
      DocText('the `borderColor` function of `segment`'),
    ),
    (
      Text('onCreateShader'),
      DocText('a scriptable `borderColor` that returns a gradient'),
    ),
    (
      Text('onCreateRenderer, annotations'),
      DocText('an inline plugin that draws after the datasets'),
    ),
    (Text('animationDuration'), DocText('`animation`')),
  ],
  demos: [
    ReplicaDemo(
      id: 'sf-default-line',
      title: const Text('Default line chart'),
      original: _gallery,
      region: const CodeRegion(
        'lib/migrate/syncfusion/default_line.dart',
        'sf-default-line',
      ),
      notes: const [
        DocText(
          '`MarkerSettings(isVisible: true)` is `pointRadius` with a white '
          '`pointBackgroundColor` and the series color as '
          '`pointBorderColor`.',
        ),
        DocText(
          'The tooltip shows the series name as the title and `x : y` as the '
          'label. A `labelColor` callback fills its marker with the series '
          'color. The tooltip of Chart.js has no line under the title.',
        ),
        DocText(
          'Syncfusion picks the range 0 to 100 by itself. The replica sets '
          '`min`, `max` and `stepSize`. The legend shows a circle, not a '
          'line through a circle.',
        ),
      ],
      replica: (_) => const SfDefaultLine(),
    ),
    ReplicaDemo(
      id: 'sf-line-dashes',
      title: const Text('Line with dashes'),
      original: '${_demos}line-with-dashes',
      region: const CodeRegion(
        'lib/migrate/syncfusion/line_dashes.dart',
        'sf-line-dashes',
      ),
      notes: const [
        DocText('`dashArray: [15, 3, 3, 3]` is `borderDash: [15, 3, 3, 3]`.'),
        DocText(
          'The y axis keeps `minimum: 3`, `maximum: 21` and `interval: 3` as '
          '`min`, `max` and `stepSize`.',
        ),
        DocText(
          'The legend of Chart.js fits the four items in one row. Syncfusion '
          'wraps them to two rows.',
        ),
      ],
      replica: (_) => const SfLineDashes(),
    ),
    ReplicaDemo(
      id: 'sf-multi-colored-line',
      title: const Text('Multi-colored line'),
      original: '${_demos}multi-colored-line',
      region: const CodeRegion(
        'lib/migrate/syncfusion/multi_colored_line.dart',
        'sf-multi-colored-line',
      ),
      notes: const [
        DocText(
          '`pointColorMapper` is the `borderColor` function of a '
          '`LineSegmentStyle` in `segment`. Each segment takes the color of '
          'its end point.',
        ),
        DocText(
          'The trackball is `interaction` with '
          '`mode: NearestInteractionMode()`, `intersect: false` and '
          '`axis: .x`. An inline plugin draws its vertical line.',
        ),
        DocText(
          '`DateTimeAxis` is `TimeAxis(unit: .year)`, and `tooltipFormat` '
          'gives the year in the tooltip.',
        ),
      ],
      replica: (_) => const SfMultiColoredLine(),
    ),
    ReplicaDemo(
      id: 'sf-line-zone',
      title: const Text('Line zone'),
      original: '${_demos}line-zone',
      region: const CodeRegion(
        'lib/migrate/syncfusion/line_zone.dart',
        'sf-line-zone',
      ),
      notes: const [
        DocText(
          '`onCreateShader` is a scriptable `borderColor`. It returns a canvas '
          'gradient with hard stops between the highest and the lowest '
          'value.',
        ),
        DocText(
          'The annotation widget is an inline plugin that draws the key of the '
          'three zones in the plot area.',
        ),
        DocText(
          'The trackball has no line here, so the replica only shows the '
          'tooltip at the nearest year.',
        ),
      ],
      replica: (_) => const SfLineZone(),
    ),
    ReplicaDemo(
      id: 'sf-customized-line',
      title: const Text('Customized line chart'),
      original: '${_demos}customized-line-chart',
      region: const CodeRegion(
        'lib/migrate/syncfusion/customized_line.dart',
        'sf-customized-line',
      ),
      notes: const [
        DocText(
          'The custom series renderer is an inline plugin. It draws the dashed '
          'high and low lines and their labels in `afterDatasetsDraw`.',
        ),
        DocText(
          'The black series on the top and the right edges is a dataset with '
          '`pointRadius: .constant(0)` and `clip: ChartClip.all(0)`. It gets '
          'no tooltip.',
        ),
        DocText(
          "`TooltipBehavior(header: '')` is a `title` callback that returns "
          'no lines.',
        ),
      ],
      replica: (_) => const SfCustomizedLine(),
    ),
    ReplicaDemo(
      id: 'sf-animation-line',
      title: const Text('Dynamic update animation'),
      original: '${_demos}dynamic-update-animation',
      region: const CodeRegion(
        'lib/migrate/syncfusion/animation_line.dart',
        'sf-animation-line',
      ),
      notes: const [
        DocText(
          'A `Timer` gives a new data List every 2 seconds in `setState`. The '
          'chart animates each point to its new value.',
        ),
        DocText(
          'Syncfusion grows the series from left to right at the start. '
          'Chart.js raises the points from the axis instead.',
        ),
      ],
      replica: (_) => const SfAnimationLine(),
    ),
  ],
);
