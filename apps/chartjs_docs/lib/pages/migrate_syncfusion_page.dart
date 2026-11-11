// Original code, not ported from Chart.js: the page "Migrate from Syncfusion".
// Each note is one long text, split over lines of the source.
// ignore_for_file: no_adjacent_strings_in_list

import 'package:chartjs_docs/migrate/syncfusion/animation_line.dart';
import 'package:chartjs_docs/migrate/syncfusion/customized_line.dart';
import 'package:chartjs_docs/migrate/syncfusion/default_line.dart';
import 'package:chartjs_docs/migrate/syncfusion/line_dashes.dart';
import 'package:chartjs_docs/migrate/syncfusion/line_zone.dart';
import 'package:chartjs_docs/migrate/syncfusion/multi_colored_line.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:material_ui/material_ui.dart';

const String _demos =
    'https://flutter.syncfusion.com/#/cartesian-charts/chart-types/line/';
const String _gallery = '${_demos}default-line-chart';

/// The page "Migrate from Syncfusion": the line chart demos of the
/// Syncfusion Flutter gallery.
DocPageContent syncfusionMigrationPage() => migrationPage(
  library: 'Syncfusion',
  version: '35.1.43',
  gallery: _gallery,
  icon: Icons.swap_horiz,
  frame: const ReplicaFrame(background: Colors.white),
  credit:
      'The demos come from the Syncfusion Flutter gallery. The replicas are '
      'new code, and they use no Syncfusion code.',
  intro: const [
    DocParagraph(
      '`SfCartesianChart` takes its series, its axes and its behaviors as '
      'widgets. The port takes a `ChartConfig` with `datasets` and '
      '`scales`, as Chart.js does. The replicas set the colors of the '
      'Syncfusion light Material 3 theme: the series palette, the gray axis '
      'labels and the dark tooltip. A custom renderer, a trackball line and '
      'an annotation become small inline plugins that draw on the canvas.',
    ),
  ],
  mapping: const [
    ('SfCartesianChart', '`ChartView(config: ChartConfig(...))`'),
    ('LineSeries', '`LineDataset`'),
    (
      'dataSource, xValueMapper, yValueMapper',
      '`labels` and `data`, or `points`',
    ),
    (
      'CategoryAxis, NumericAxis, DateTimeAxis',
      '`CategoryAxis`, `LinearAxis`, `TimeAxis`',
    ),
    ('minimum, maximum, interval', '`min`, `max` and `ticks.stepSize`'),
    ('labelFormat', 'a tick `format` callback'),
    ('edgeLabelPlacement: shift', '`align: .inner` of `AxisTicks`'),
    ('majorGridLines, axisLine', 'the `grid` and the `border` of each axis'),
    ('ChartTitle', '`title: ChartTitle(...)`'),
    ('Legend', '`legend: ChartLegend(...)`'),
    ('TooltipBehavior', '`tooltip: ChartTooltip(...)`'),
    (
      'TrackballBehavior',
      '`interaction` with `intersect: false`, and an inline plugin for the '
          'line',
    ),
    ('MarkerSettings', '`pointRadius`, `pointStyle` and the point colors'),
    ('width, dashArray', '`borderWidth`, `borderDash`'),
    ('pointColorMapper', "a scriptable `'segment'` color in `extra`"),
    ('onCreateShader', 'a scriptable `borderColor` that returns a gradient'),
    (
      'onCreateRenderer, annotations',
      'an inline plugin that draws after the datasets',
    ),
    ('animationDuration', '`animation`'),
  ],
  demos: [
    ReplicaDemo(
      id: 'sf-default-line',
      title: 'Default line chart',
      original: _gallery,
      region: 'sf-default-line',
      notes: const [
        '`MarkerSettings(isVisible: true)` is `pointRadius` with a white '
            '`pointBackgroundColor` and the series color as '
            '`pointBorderColor`.',
        'The tooltip shows the series name as the title and `x : y` as the '
            'label. A `labelColor` callback fills its marker with the series '
            'color. The tooltip of Chart.js has no line under the title.',
        'Syncfusion picks the range 0 to 100 by itself. The replica sets '
            '`min`, `max` and `stepSize`. The legend shows a circle, not a '
            'line through a circle.',
      ],
      replica: (_) => const SfDefaultLine(),
    ),
    ReplicaDemo(
      id: 'sf-line-dashes',
      title: 'Line with dashes',
      original: '${_demos}line-with-dashes',
      region: 'sf-line-dashes',
      notes: const [
        '`dashArray: [15, 3, 3, 3]` is `borderDash: [15, 3, 3, 3]`.',
        'The y axis keeps `minimum: 3`, `maximum: 21` and `interval: 3` as '
            '`min`, `max` and `stepSize`.',
        'The legend of Chart.js fits the four items in one row. Syncfusion '
            'wraps them to two rows.',
      ],
      replica: (_) => const SfLineDashes(),
    ),
    ReplicaDemo(
      id: 'sf-multi-colored-line',
      title: 'Multi-colored line',
      original: '${_demos}multi-colored-line',
      region: 'sf-multi-colored-line',
      notes: const [
        '`pointColorMapper` is a scriptable `borderColor` in the `segment` '
            'Map. Each segment takes the color of its end point.',
        'The trackball is `interaction` with `mode: NearestInteractionMode()`, '
            '`intersect: false` and `axis: .x`. An inline plugin draws '
            'its vertical line.',
        '`DateTimeAxis` is `TimeAxis(unit: .year)`, and `tooltipFormat` '
            'gives the year in the tooltip.',
      ],
      replica: (_) => const SfMultiColoredLine(),
    ),
    ReplicaDemo(
      id: 'sf-line-zone',
      title: 'Line zone',
      original: '${_demos}line-zone',
      region: 'sf-line-zone',
      notes: const [
        '`onCreateShader` is a scriptable `borderColor`. It returns a canvas '
            'gradient with hard stops between the highest and the lowest '
            'value.',
        'The annotation widget is an inline plugin that draws the key of the '
            'three zones in the plot area.',
        'The trackball has no line here, so the replica only shows the '
            'tooltip at the nearest year.',
      ],
      replica: (_) => const SfLineZone(),
    ),
    ReplicaDemo(
      id: 'sf-customized-line',
      title: 'Customized line chart',
      original: '${_demos}customized-line-chart',
      region: 'sf-customized-line',
      notes: const [
        'The custom series renderer is an inline plugin. It draws the dashed '
            'high and low lines and their labels in `afterDatasetsDraw`.',
        'The black series on the top and the right edges is a dataset with '
            "`pointRadius: 0` and `'clip': 0`. It gets no tooltip.",
        "`TooltipBehavior(header: '')` is a `title` callback that returns "
            'no lines.',
      ],
      replica: (_) => const SfCustomizedLine(),
    ),
    ReplicaDemo(
      id: 'sf-animation-line',
      title: 'Dynamic update animation',
      original: '${_demos}dynamic-update-animation',
      region: 'sf-animation-line',
      notes: const [
        'A `Timer` gives a new data List every 2 seconds in `setState`. The '
            'chart animates each point to its new value.',
        'Syncfusion grows the series from left to right at the start. '
            'Chart.js raises the points from the axis instead.',
      ],
      replica: (_) => const SfAnimationLine(),
    ),
  ],
);
