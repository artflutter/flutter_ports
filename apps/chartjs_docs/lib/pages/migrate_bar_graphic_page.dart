// Original code, not ported from Chart.js: the page "Migrate bar charts from Graphic".
// Each note is one long text, split over lines of the source.
// ignore_for_file: lines_longer_than_80_chars

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
  credit: const Text(
    'The demos and their data come from the Graphic example app (MIT, '
    'LIN Chen). The replicas are new code.',
  ),
  intro: const [
    DocParagraph(
      DocText(
        'Graphic draws a bar with an `IntervalMark`: each datum is an interval '
        'from a start value to an end value. The port takes a `ChartConfig` of '
        'the type `bar` with `BarDataset`s, as Chart.js does. A Graphic group '
        '(`Varset` with `/`) is one dataset for each group. The modifiers of a '
        'group, `StackModifier` and `DodgeModifier`, are options of the axes '
        'and of the datasets.',
      ),
    ),
    DocParagraph(
      DocText(
        'The guides of Graphic that Chart.js does not have, the labels on the '
        'bars, the crosshair and the elevation, are small inline plugins in '
        '`graphic_bar_kit.dart`. The replicas also use the Graphic defaults of '
        'the line replicas, `graphic_kit.dart`. The zoom and the pan of the x '
        'axis come from the port of chartjs-plugin-zoom, '
        '`flutter_chartjs_plugin_zoom_port`.',
      ),
    ),
  ],
  mapping: const [
    (
      Text('Chart(data:, variables:, marks: [IntervalMark()])'),
      DocText('`ChartView(config: ChartConfig( ...))`'),
    ),
    (Text('IntervalMark'), DocText('`BarDataset`')),
    (Text("Varset('genre') * Varset('sold')"), DocText('`labels` and `data`')),
    (
      Text("Varset('id') * (Varset('min') + Varset('max'))"),
      DocText('a floating bar: a pair `[start, end]` for each item of `data`'),
    ),
    (
      Text("Varset(...) / Varset('type')"),
      DocText('one `BarDataset` for each group'),
    ),
    (
      Text('StackModifier'),
      DocText('`stacked: true` of the x axis and of the y axis'),
    ),
    (
      Text('DodgeModifier, a custom Modifier'),
      DocText('`categoryPercentage` and `barPercentage`'),
    ),
    (
      Text('SizeEncode(value: ...)'),
      DocText('`barThickness` or `maxBarThickness`'),
    ),
    (Text('RectCoord(transposed: true)'), DocText('`indexAxis: YAxis()`')),
    (
      Text('RectShape(borderRadius: ...)'),
      DocText(
        '`borderRadius`, and `borderSkipped: BorderSkip.none` for all four '
        'corners',
      ),
    ),
    (
      Text('LabelEncode and RectShape(labelPosition: ...)'),
      DocText('an inline plugin that draws in `afterDatasetsDraw`'),
    ),
    (
      Text("ColorEncode(variable: 'type', values: ...)"),
      DocText('the `backgroundColor` of each dataset'),
    ),
    (
      Text('GradientEncode(value: LinearGradient(...))'),
      DocText('`ChartGradient.linear` in a `ChartValue.resolver`'),
    ),
    (
      Text('updaters of an encode'),
      DocText(
        '`hoverBackgroundColor`, or a `ChartValue.resolver` that reads '
        '`getActiveElements()`',
      ),
    ),
    (
      Text('ElevationEncode'),
      DocText('an inline plugin that sets the canvas shadow'),
    ),
    (
      Text('PointSelection(dim: Dim.x)'),
      DocText(
        '`interaction` with `IndexInteractionMode()` and `intersect: false`',
      ),
    ),
    (
      Text("PointSelection(variable: 'index')"),
      DocText(
        '`IndexInteractionMode()`: the bars of all the datasets at an index',
      ),
    ),
    (
      Text('on: {GestureType.tap}, clear: {GestureType.doubleTap}'),
      DocText("`events: ['click']`, and an inline plugin for the double tap"),
    ),
    (
      Text('TooltipGuide()'),
      DocText(
        '`TooltipOptions` with a `TooltipPositioner` at the end of the bars',
      ),
    ),
    (
      Text('TooltipGuide(multiTuples: true)'),
      DocText('a `title` callback with the index and a `label` for each item'),
    ),
    (
      Text('CrosshairGuide'),
      DocText('an inline plugin that draws in `afterDatasetsDraw`'),
    ),
    (
      Text('RectCoord(horizontalRangeUpdater: ...)'),
      DocText('`zoomPlugin` of `flutter_chartjs_plugin_zoom_port`'),
    ),
    (
      Text('Transition(duration: ...)'),
      DocText('`ChartAnimation(duration: ..., easing: Curves.linear)`'),
    ),
    (
      Text('CustomAnnotation and TagAnnotation as a legend'),
      DocText('`ChartLegend(usePointStyle: true)`'),
    ),
    (
      Text('AxisGuide(tickLine: TickLine())'),
      DocText('`AxisGrid(drawOnChartArea: false, tickLength: 5)`'),
    ),
  ],
  demos: [
    ReplicaDemo(
      id: 'graphic-bar-interactive',
      title: const Text('Interactive Bar Chart'),
      original: _interval,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_interactive.dart',
        'graphic-bar-interactive',
      ),
      notes: const [
        DocText(
          'A tap selects the bar nearest in x: the chart takes only the event '
          "`'click'`, and the `interaction` has the mode "
          '`IndexInteractionMode()` with `intersect: false`. A double tap '
          'clears the selection.',
        ),
        DocText(
          'The `updaters` of the color are a `ChartValue.resolver` that reads '
          '`getActiveElements()`: the other bars fade. The selected bar '
          'keeps its color with `hoverBackgroundColor`. An inline plugin '
          'gives it the shadow of the elevation 5.',
        ),
        DocText(
          'The bars of Graphic start at 0, below the axis. The `base` of the '
          'dataset starts them at the bottom of the axis, so that a tap '
          'also selects a short bar.',
        ),
      ],
      replica: (_) => const GraphicBarInteractive(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-transposed',
      title: const Text('Transposed Bar Chart'),
      original: _interval,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_transposed.dart',
        'graphic-bar-transposed',
      ),
      notes: const [
        DocText(
          '`RectCoord(transposed: true)` is `indexAxis: YAxis()`. Graphic puts '
          'the first genre at the bottom: the y axis has `reverse: true`.',
        ),
        DocText(
          'A `GradientEncode` is a `ChartGradient.linear` in a '
          '`ChartValue.resolver`. The gradient goes over the chart area, '
          'as it goes over the region in Graphic. The gradient of the '
          '`tap` updater is the `hoverBackgroundColor`.',
        ),
        DocText(
          'The `interaction` has `axis: InteractionAxis.y`: a tap selects the '
          'bar nearest along the axis of the genres.',
        ),
      ],
      replica: (_) => const GraphicBarTransposed(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-interval',
      title: const Text('Interval Bar Chart'),
      original: _interval,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_interval.dart',
        'graphic-bar-interval',
      ),
      notes: const [
        DocText(
          "`Varset('min') + Varset('max')` makes a floating bar: the pair "
          '`[min, max]` of each item. The typed `data` takes numbers, so '
          'the pairs go through `extra`.',
        ),
        DocText(
          '`RectShape(borderRadius: BorderRadius.circular(2))` is '
          '`borderRadius: 2` with `borderSkipped: BorderSkip.none`: Chart.js '
          'then rounds all four corners.',
        ),
      ],
      replica: (_) => const GraphicBarInterval(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-stacked',
      title: const Text('Stacked Bar Chart'),
      original: _interval,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_stacked.dart',
        'graphic-bar-stacked',
      ),
      notes: const [
        DocText(
          '`StackModifier()` is `stacked: true` on both axes. Each type is a '
          'dataset in its color of `Defaults.colors10`. An inline plugin '
          'draws the labels in the middle of the bars.',
        ),
        DocText(
          "`PointSelection(variable: 'index')` is the mode "
          '`IndexInteractionMode()`: a tap selects the bars of all the '
          'types at an index. The tooltip shows the index and one line for '
          'each type.',
        ),
        DocText(
          'The port of chartjs-plugin-zoom zooms and pans the x axis, by '
          'whole labels on a category axis. The wheel zooms with the Ctrl '
          'key, so that the wheel still scrolls this page. A double tap '
          'puts back the range.',
        ),
      ],
      replica: (_) => const GraphicBarStacked(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-ranking',
      title: const Text('Auto Animated Ranking'),
      original: _animation,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_ranking.dart',
        'graphic-bar-ranking',
      ),
      notes: const [
        DocText(
          'A `Timer` gives new random data every 2 seconds. The `Sort` '
          'transform is a sort in Dart.',
        ),
        DocText(
          'The `tag` of Graphic moves each bar to its new place. The replica '
          'puts each genre at its rank on a linear x axis, so that Chart.js '
          'also animates the x of each bar.',
        ),
        DocText(
          '`Transition(duration: const Duration(seconds: 1))` is a '
          '`ChartAnimation` with `easing: Curves.linear`. Chart.js grows '
          'the bars from 0 at the first draw, as `MarkEntrance.y` does.',
        ),
      ],
      replica: (_) => const GraphicBarRanking(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-auto-update',
      title: const Text('Auto update'),
      original: _dynamic,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_auto_update.dart',
        'graphic-bar-auto-update',
      ),
      notes: const [
        DocText(
          'A `Timer` gives new data every second. `rebuild: false` with no '
          'transition is `ChartAnimation.none`: the bars change at once.',
        ),
        DocText(
          'A hover and a tap select a bar. The `events` of the chart have no '
          "`'mouseout'`: the selection stays when the pointer leaves the "
          'chart, as in Graphic.',
        ),
        DocText(
          'The black tooltip is `graphicTooltip` with the colors and the font '
          'of the demo. An inline plugin draws its shadow.',
        ),
      ],
      replica: (_) => const GraphicBarAutoUpdate(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-custom-legend',
      title: const Text('Custom Legend'),
      original: _custom,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_custom_legend.dart',
        'graphic-bar-custom-legend',
      ),
      notes: const [
        DocText(
          'Graphic draws this legend with annotations. Chart.js has a legend: '
          '`ChartLegend` at the bottom with `usePointStyle: true`. A tap on '
          'an item also hides its type.',
        ),
        DocText(
          '`DodgeModifier(ratio: 0.1)` with bars of 2 px: the group takes '
          '`categoryPercentage: 0.5` of the band, and `maxBarThickness: 2` '
          'sets the width of the bars.',
        ),
        DocText(
          '`tickLine = TickLine()` is the grid of the x axis with '
          '`drawOnChartArea: false` and a `tickLength` of 5.',
        ),
      ],
      replica: (_) => const GraphicBarCustomLegend(),
    ),
    ReplicaDemo(
      id: 'graphic-bar-custom-modifier',
      title: const Text('Custom Modifier'),
      original: _custom,
      region: const CodeRegion(
        'lib/migrate/graphic/bar_custom_modifier.dart',
        'graphic-bar-custom-modifier',
      ),
      notes: const [
        DocText(
          'The `DodgeSizeModifier` of the demo fits the bars of a group in '
          'their band. Chart.js fits grouped bars this way by default: '
          '`categoryPercentage: 0.7` and `barPercentage: 0.67` give the '
          'bars and the spaces of the demo.',
        ),
        DocText('The zoom and the pan work as in the stacked bar chart.'),
      ],
      replica: (_) => const GraphicBarCustomModifier(),
    ),
  ],
);
