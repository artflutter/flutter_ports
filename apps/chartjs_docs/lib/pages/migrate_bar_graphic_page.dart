// Original code, not ported from Chart.js: the page "Migrate bar charts from Graphic".
// Each note is one long text, split over lines of the source.
// ignore_for_file: no_adjacent_strings_in_list, lines_longer_than_80_chars

import 'package:chartjs_docs/migrate/graphic/bar_auto_update.dart';
import 'package:chartjs_docs/migrate/graphic/bar_custom_legend.dart';
import 'package:chartjs_docs/migrate/graphic/bar_custom_modifier.dart';
import 'package:chartjs_docs/migrate/graphic/bar_interactive.dart';
import 'package:chartjs_docs/migrate/graphic/bar_interval.dart';
import 'package:chartjs_docs/migrate/graphic/bar_ranking.dart';
import 'package:chartjs_docs/migrate/graphic/bar_stacked.dart';
import 'package:chartjs_docs/migrate/graphic/bar_transposed.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:material_ui/material_ui.dart';

const String _pages =
    'https://github.com/entronad/graphic/blob/v2.7.0/example/lib/pages';

const String _interval = '$_pages/interval.dart';
const String _animation = '$_pages/animation.dart';
const String _dynamic = '$_pages/interaction_stream_dynamic.dart';
const String _custom = '$_pages/polygon_custom.dart';

/// The page "Migrate bar charts from Graphic": the bar charts of the Graphic
/// demos.
DocPageContent graphicBarMigrationPage() => migrationPage(
  chart: 'bar',
  library: 'Graphic',
  version: '2.7.0',
  gallery: _interval,
  icon: Icons.swap_horiz,
  kit: const CodeRegion(
    'lib/migrate/graphic/graphic_bar_kit.dart',
    'graphic-bar-kit',
  ),
  frame: const ReplicaFrame(background: Colors.white),
  credit:
      'The demos and their data come from the Graphic example app (MIT, '
      'LIN Chen). The replicas are new code.',
  intro: const [
    DocParagraph(
      'Graphic draws a bar with an `IntervalMark`: each datum is an interval '
      'from a start value to an end value. The port takes a `ChartConfig` of '
      'the type `bar` with `BarDataset`s, as Chart.js does. A Graphic group '
      '(`Varset` with `/`) is one dataset for each group. The modifiers of a '
      'group, `StackModifier` and `DodgeModifier`, are options of the axes '
      'and of the datasets.',
    ),
    DocParagraph(
      'The guides of Graphic that Chart.js does not have, the labels on the '
      'bars, the crosshair and the elevation, are small inline plugins in '
      '`graphic_bar_kit.dart`. The replicas also use the Graphic defaults of '
      'the line replicas, `graphic_kit.dart`. The zoom and the pan of the x '
      'axis come from the port of chartjs-plugin-zoom, '
      '`flutter_chartjs_plugin_zoom_port`.',
    ),
  ],
  mapping: const [
    (
      'Chart(data:, variables:, marks: [IntervalMark()])',
      '`ChartView(config: ChartConfig(type: .bar, ...))`',
    ),
    ('IntervalMark', '`BarDataset`'),
    ("Varset('genre') * Varset('sold')", '`labels` and `data`'),
    (
      "Varset('id') * (Varset('min') + Varset('max'))",
      'a floating bar: a pair `[start, end]` for each item of `data`',
    ),
    ("Varset(...) / Varset('type')", 'one `BarDataset` for each group'),
    ('StackModifier', '`stacked: true` of the x axis and of the y axis'),
    (
      'DodgeModifier, a custom Modifier',
      '`categoryPercentage` and `barPercentage`',
    ),
    ('SizeEncode(value: ...)', '`barThickness` or `maxBarThickness`'),
    ('RectCoord(transposed: true)', '`indexAxis: YAxis()`'),
    (
      'RectShape(borderRadius: ...)',
      '`borderRadius`, and `borderSkipped: false` for all four corners',
    ),
    (
      'LabelEncode and RectShape(labelPosition: ...)',
      'an inline plugin that draws in `afterDatasetsDraw`',
    ),
    (
      "ColorEncode(variable: 'type', values: ...)",
      'the `backgroundColor` of each dataset',
    ),
    (
      'GradientEncode(value: LinearGradient(...))',
      '`ChartGradient.linear` in a `ChartValue.resolver`',
    ),
    (
      'updaters of an encode',
      '`hoverBackgroundColor`, or a `ChartValue.resolver` that reads '
          '`getActiveElements()`',
    ),
    ('ElevationEncode', 'an inline plugin that sets the canvas shadow'),
    (
      'PointSelection(dim: Dim.x)',
      '`interaction` with `IndexInteractionMode()` and `intersect: false`',
    ),
    (
      "PointSelection(variable: 'index')",
      '`IndexInteractionMode()`: the bars of all the datasets at an index',
    ),
    (
      'on: {GestureType.tap}, clear: {GestureType.doubleTap}',
      "`'events': ['click']` in `extra`, and an inline plugin for the double "
          'tap',
    ),
    (
      'TooltipGuide()',
      '`tooltip` with a `TooltipPositioner` at the end of the bars',
    ),
    (
      'TooltipGuide(multiTuples: true)',
      'a `title` callback with the index and a `label` for each item',
    ),
    ('CrosshairGuide', 'an inline plugin that draws in `afterDatasetsDraw`'),
    (
      'RectCoord(horizontalRangeUpdater: ...)',
      '`zoomPlugin` of `flutter_chartjs_plugin_zoom_port`',
    ),
    (
      'Transition(duration: ...)',
      '`ChartAnimation(duration: ..., easing: Curves.linear)`',
    ),
    (
      'CustomAnnotation and TagAnnotation as a legend',
      '`ChartLegend(usePointStyle: true)`',
    ),
    (
      'AxisGuide(tickLine: TickLine())',
      '`AxisGrid(drawOnChartArea: false)` with `tickLength`',
    ),
  ],
  demos: [
    ReplicaDemo(
      id: 'graphic-bar-interactive',
      title: 'Interactive Bar Chart',
      original: _interval,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_interactive.dart',
        'graphic-bar-interactive',
      ),
      notes: const [
        'A tap selects the bar nearest in x: the chart takes only the event '
            "`'click'`, and the `interaction` has the mode "
            '`IndexInteractionMode()` with `intersect: false`. A double tap '
            'clears the selection.',
        'The `updaters` of the color are a `ChartValue.resolver` that reads '
            '`getActiveElements()`: the other bars fade. The selected bar '
            'keeps its color with `hoverBackgroundColor`. An inline plugin '
            'gives it the shadow of the elevation 5.',
        'The bars of Graphic start at 0, below the axis. The `base` of the '
            'dataset starts them at the bottom of the axis, so that a tap '
            'also selects a short bar.',
      ],
      replica: (_) => const GraphicBarInteractive(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-transposed',
      title: 'Transposed Bar Chart',
      original: _interval,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_transposed.dart',
        'graphic-bar-transposed',
      ),
      notes: const [
        '`RectCoord(transposed: true)` is `indexAxis: YAxis()`. Graphic puts '
            'the first genre at the bottom: the y axis has `reverse: true`.',
        'A `GradientEncode` is a `ChartGradient.linear` in a '
            '`ChartValue.resolver`. The gradient goes over the chart area, '
            'as it goes over the region in Graphic. The gradient of the '
            '`tap` updater is the `hoverBackgroundColor`.',
        'The `interaction` has `axis: InteractionAxis.y`: a tap selects the '
            'bar nearest along the axis of the genres.',
      ],
      replica: (_) => const GraphicBarTransposed(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-interval',
      title: 'Interval Bar Chart',
      original: _interval,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_interval.dart',
        'graphic-bar-interval',
      ),
      notes: const [
        "`Varset('min') + Varset('max')` makes a floating bar: the pair "
            '`[min, max]` of each item. The typed `data` takes numbers, so '
            'the pairs go through `extra`.',
        '`RectShape(borderRadius: BorderRadius.circular(2))` is '
            '`borderRadius: 2` with `borderSkipped: false`: Chart.js then '
            'rounds all four corners.',
      ],
      replica: (_) => const GraphicBarInterval(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-stacked',
      title: 'Stacked Bar Chart',
      original: _interval,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_stacked.dart',
        'graphic-bar-stacked',
      ),
      notes: const [
        '`StackModifier()` is `stacked: true` on both axes. Each type is a '
            'dataset in its color of `Defaults.colors10`. An inline plugin '
            'draws the labels in the middle of the bars.',
        "`PointSelection(variable: 'index')` is the mode "
            '`IndexInteractionMode()`: a tap selects the bars of all the '
            'types at an index. The tooltip shows the index and one line for '
            'each type.',
        'The port of chartjs-plugin-zoom zooms and pans the x axis, by '
            'whole labels on a category axis. The wheel zooms with the Ctrl '
            'key, so that the wheel still scrolls this page. A double tap '
            'puts back the range.',
      ],
      replica: (_) => const GraphicBarStacked(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-ranking',
      title: 'Auto Animated Ranking',
      original: _animation,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_ranking.dart',
        'graphic-bar-ranking',
      ),
      notes: const [
        'A `Timer` gives new random data every 2 seconds. The `Sort` '
            'transform is a sort in Dart.',
        'The `tag` of Graphic moves each bar to its new place. The replica '
            'puts each genre at its rank on a linear x axis, so that Chart.js '
            'also animates the x of each bar.',
        '`Transition(duration: const Duration(seconds: 1))` is a '
            '`ChartAnimation` with `easing: Curves.linear`. Chart.js grows '
            'the bars from 0 at the first draw, as `MarkEntrance.y` does.',
      ],
      replica: (_) => const GraphicBarRanking(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-auto-update',
      title: 'Auto update',
      original: _dynamic,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_auto_update.dart',
        'graphic-bar-auto-update',
      ),
      notes: const [
        'A `Timer` gives new data every second. `rebuild: false` with no '
            'transition is `ChartAnimation.none`: the bars change at once.',
        'A hover and a tap select a bar. The `events` of the chart have no '
            "`'mouseout'`: the selection stays when the pointer leaves the "
            'chart, as in Graphic.',
        'The black tooltip is `graphicTooltip` with the colors and the font '
            'of the demo. An inline plugin draws its shadow.',
      ],
      replica: (_) => const GraphicBarAutoUpdate(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-custom-legend',
      title: 'Custom Legend',
      original: _custom,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_custom_legend.dart',
        'graphic-bar-custom-legend',
      ),
      notes: const [
        'Graphic draws this legend with annotations. Chart.js has a legend: '
            '`ChartLegend` at the bottom with `usePointStyle: true`. A tap on '
            'an item also hides its type.',
        '`DodgeModifier(ratio: 0.1)` with bars of 2 px: the group takes '
            '`categoryPercentage: 0.5` of the band, and `maxBarThickness: 2` '
            'sets the width of the bars.',
        '`tickLine = TickLine()` is the grid of the x axis with '
            '`drawOnChartArea: false` and a `tickLength` of 5.',
      ],
      replica: (_) => const GraphicBarCustomLegend(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-custom-modifier',
      title: 'Custom Modifier',
      original: _custom,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_custom_modifier.dart',
        'graphic-bar-custom-modifier',
      ),
      notes: const [
        'The `DodgeSizeModifier` of the demo fits the bars of a group in '
            'their band. Chart.js fits grouped bars this way by default: '
            '`categoryPercentage: 0.7` and `barPercentage: 0.67` give the '
            'bars and the spaces of the demo.',
        'The zoom and the pan work as in the stacked bar chart.',
      ],
      replica: (_) => const GraphicBarCustomModifier(),
    ),
  ],
);
