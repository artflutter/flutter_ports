// Original code, not ported from Chart.js: the fl_chart bar migration page.
// Each note is one long text, split over lines of the source.

import 'package:chartjs_docs/migrate/fl_chart/bar_s01.dart';
import 'package:chartjs_docs/migrate/fl_chart/bar_s02.dart';
import 'package:chartjs_docs/migrate/fl_chart/bar_s03.dart';
import 'package:chartjs_docs/migrate/fl_chart/bar_s04.dart';
import 'package:chartjs_docs/migrate/fl_chart/bar_s05.dart';
import 'package:chartjs_docs/migrate/fl_chart/bar_s06.dart';
import 'package:chartjs_docs/migrate/fl_chart/bar_s07.dart';
import 'package:chartjs_docs/migrate/fl_chart/bar_s08.dart';
import 'package:chartjs_docs/migrate/fl_chart/fl_kit.dart' show Fl;
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:material_ui/material_ui.dart';

const String _gallery = 'https://app.flchart.dev/#/bar';

/// The page "Migrate bar charts from fl_chart": the 8 bar samples of
/// fl_chart 1.3.0.
DocPageContent flChartBarMigrationPage() => migrationPage(
  chart: 'bar',
  library: 'fl_chart',
  version: '1.3.0',
  gallery: _gallery,
  icon: Icons.swap_horiz,
  kit: const CodeRegion(
    'lib/migrate/fl_chart/fl_bar_kit.dart',
    'fl_chart-bar-kit',
  ),
  frame: const ReplicaFrame(background: Fl.item, dark: true),
  credit: const Text(
    'The demos come from the fl_chart example app (MIT, Flutter 4 Fun). '
    'The replicas are new code.',
  ),
  intro: const [
    DocParagraph(
      DocText(
        'fl_chart builds a bar chart from one data object: `BarChartData` '
        'with its `barGroups`. Each group has one or more rods. The port takes '
        'a `ChartConfig` of the type `bar` with its `datasets`: each rod of a '
        'group is an item of one dataset.',
      ),
    ),
    DocParagraph(
      DocText(
        'fl_chart gives the rods and the spaces in pixels and places the '
        'groups with `alignment`. The shared code below has a scale hook that '
        'places the groups in the same way. A few fl_chart features, for '
        'example the background rods and the labels at the ends of the rods, '
        'are small inline plugins.',
      ),
    ),
  ],
  mapping: const [
    (
      Text('BarChart(BarChartData(...))'),
      DocText('`ChartView(config: ChartConfig(...))`'),
    ),
    (
      Text('barGroups: [BarChartGroupData]'),
      DocText('`datasets`: rod j of each group is an item of dataset j'),
    ),
    (
      Text('BarChartRodData(toY: y)'),
      DocText('`data` with `labels`, or `points: [DataPoint(i, y)]`'),
    ),
    (Text('fromY'), DocText('a floating bar: a pair `[from, to]` in `extra`')),
    (
      Text('color, gradient'),
      DocText(
        '`backgroundColor: ChartValue`, a resolver that gives a '
        '`ChartGradient`',
      ),
    ),
    (Text('width'), DocText('`barThickness`')),
    (
      Text('barsSpace'),
      DocText('`barThickness` with the space, `maxBarThickness`'),
    ),
    (Text('alignment, groupsSpace'), DocText('`groupAxis` of the shared code')),
    (
      Text('borderRadius'),
      DocText('`borderRadius` and `borderSkipped: false`'),
    ),
    (Text('borderSide'), DocText('`borderColor` and `borderWidth`')),
    (
      Text('rodStackItems'),
      DocText(
        'one dataset for each item, with one `stack`, on a `stacked` axis',
      ),
    ),
    (Text('groupVertically'), DocText('`grouped: false`')),
    (
      Text('backDrawRodData'),
      DocText('an inline plugin that draws before the datasets'),
    ),
    (
      Text('BarChartRodLabel'),
      DocText('the plugin `rodLabels` of the shared code'),
    ),
    (Text('minY, maxY'), DocText('`min` and `max` of the value axis')),
    (
      Text('titlesData'),
      DocText('the `ticks` of each axis, and the hook `reserve`'),
    ),
    (Text('gridData'), DocText('the `grid` of each axis')),
    (
      Text('extraLinesData'),
      DocText('an inline plugin that draws after the datasets'),
    ),
    (
      Text('barTouchData'),
      DocText('`tooltip`, and the plugin `flTouch` of the shared code'),
    ),
    (
      Text('rotationQuarterTurns'),
      DocText('`indexAxis`, and `position` and `reverse`'),
    ),
    (Text('toYErrorRange'), DocText('an inline plugin')),
    (Text('duration, curve'), DocText('`animation`')),
  ],
  demos: [
    for (final (index, (notes, sample)) in _samples.indexed)
      ReplicaDemo(
        id: 'fl-bar-${index + 1}',
        title: Text('Bar Chart ${index + 1}'),
        original: _gallery,
        region: CodeRegion(
          'lib/migrate/fl_chart/bar_s${_number(index)}.dart',
          'fl_chart-bar-${_number(index)}',
        ),
        notes: notes,
        replica: (_) => _Card(child: sample),
      ),
  ],
);

/// The fl_chart gallery shows each sample in a card of at most 600 pixels.
class const _Card({required final Widget child}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: child,
    ),
  );
}

/// The number of the sample [index] with two digits, as in the names of its
/// file and its code region.
String _number(int index) => (index + 1).toString().padLeft(2, '0');

/// The notes and the replica of each sample, in the order of the gallery.
const List<(List<Widget>, Widget)> _samples = [
  (
    [
      DocText(
        'The background rods of `backDrawRodData` are an inline plugin that '
        'draws before the datasets.',
      ),
      DocText(
        'The touched bar grows by 1 and turns green: the plugin `flTouch` '
        'sets the state, and the chart animates to the new config.',
      ),
      DocText('The play button gives random values and colors from a `Timer`.'),
    ],
    BarSample1(),
  ),
  (
    [
      DocText(
        'Each rod of a group is an item of one `BarDataset`. `barThickness` '
        'is the width and the space of a rod, and `maxBarThickness` is '
        'its width.',
      ),
      DocText(
        'The labels at the ends of the rods are the plugin `rodLabels`. The '
        'touched group shows the average with labels that turn by -90 '
        'degrees.',
      ),
    ],
    BarSample2(),
  ),
  (
    [
      DocText(
        'A `CategoryAxis` places the groups as '
        '`BarChartAlignment.spaceAround`.',
      ),
      DocText(
        'A resolver of `backgroundColor` gives a `ChartGradient` from the '
        'base to the end of each bar.',
      ),
      DocText(
        'The label of the touched bar grows at once: the plugin does not '
        'animate it.',
      ),
    ],
    BarSample3(),
  ),
  (
    [
      DocText(
        'A rod with three stack items is three datasets with one `stack` id, '
        'on a `stacked` value axis.',
      ),
      DocText(
        'The rods and the spaces scale with the width of the chart, as in the '
        'sample. The titles use the interval and the number format of '
        'fl_chart.',
      ),
    ],
    BarSample4(),
  ),
  (
    [
      DocText(
        'The rod and its mirror image are two stacks with `grouped: false`: '
        'they share the place of the day. fl_chart paints the rod in cyan '
        'under its items, so the resolver blends the item colors over '
        'cyan.',
      ),
      DocText(
        'A `TooltipPositioner` puts the tooltip at the end of the touched '
        'rod.',
      ),
      DocText(
        'Chart.js turns all the labels of an axis by one angle: the negative '
        'labels turn by 45 degrees, not by -45 degrees.',
      ),
    ],
    BarSample5(),
  ),
  (
    [
      DocText(
        'A rod from `fromY` to `toY` is a floating bar: a pair `[from, to]` in '
        '`extra`, because `BarDataset.data` takes numbers.',
      ),
      DocText(
        'Without `offset`, the category axis places the groups as '
        '`BarChartAlignment.spaceBetween`. The extra lines are an inline '
        'plugin.',
      ),
    ],
    BarSample6(),
  ),
  (
    [
      DocText(
        'The rotate button sets `indexAxis`, and the `position` and the '
        '`reverse` of each axis.',
      ),
      DocText(
        'The faces are tick labels in the `MaterialIcons` font. Chart.js clips '
        'the tick labels to the axis: the face of the touched group '
        'changes, but it does not grow or turn.',
      ),
    ],
    BarSample7(),
  ),
  (
    [
      DocText(
        'The error ranges are an inline plugin, because Chart.js has no error '
        'bars.',
      ),
      DocText(
        'The bars of Chart.js have no dashed border: a plugin draws the '
        'outline of the forecast bars. The data is random, as in the '
        'sample.',
      ),
    ],
    BarSample8(),
  ),
];
