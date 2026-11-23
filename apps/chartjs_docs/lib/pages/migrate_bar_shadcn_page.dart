// Original code, not ported from Chart.js: the shadcn/ui bar page.
// Each note is one long text, split over lines of the source.

import 'package:chartjs_docs/migrate/shadcn/bar_active.dart';
import 'package:chartjs_docs/migrate/shadcn/bar_default.dart';
import 'package:chartjs_docs/migrate/shadcn/bar_horizontal.dart';
import 'package:chartjs_docs/migrate/shadcn/bar_interactive.dart';
import 'package:chartjs_docs/migrate/shadcn/bar_label.dart';
import 'package:chartjs_docs/migrate/shadcn/bar_label_custom.dart';
import 'package:chartjs_docs/migrate/shadcn/bar_mixed.dart';
import 'package:chartjs_docs/migrate/shadcn/bar_multiple.dart';
import 'package:chartjs_docs/migrate/shadcn/bar_negative.dart';
import 'package:chartjs_docs/migrate/shadcn/bar_stacked.dart';
import 'package:chartjs_docs/pages/migrate_shadcn_page.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:material_ui/material_ui.dart';

/// The page "Migrate bar charts from shadcn/ui": the bar chart demos of
/// shadcn/ui.
DocPageContent shadcnBarMigrationPage() => migrationPage(
  chart: 'bar',
  library: 'shadcn/ui',
  version: 'at commit $shadcnCommit',
  gallery: 'https://ui.shadcn.com/charts/bar#charts',
  icon: Icons.swap_horiz,
  kit: shadcnKit,
  frame: shadcnFrame,
  credit: shadcnCredit,
  intro: const [
    DocParagraph(
      DocText(
        'A shadcn/ui bar chart is a Recharts `BarChart` in a '
        '`ChartContainer`, with a `chartConfig` of labels and colors. The '
        'port takes a `ChartConfig` with `type: .bar` and `BarDataset`s. The '
        'corners, the stacks and the direction of the bars are options of '
        'the datasets, of the axes and of the chart.',
      ),
    ),
    ...shadcnIntro,
  ],
  mapping: const [
    (
      Text('<ChartContainer config={chartConfig}>'),
      DocText('`ShadcnChart`: a `ChartView` with the tooltip widget'),
    ),
    (
      Text('<BarChart data={chartData}>'),
      DocText('`ChartConfig( labels: ...)`'),
    ),
    (
      Text('<Bar dataKey="desktop" fill="var(--color-desktop)" />'),
      DocText('`BarDataset(label: ..., data: ..., backgroundColor: ...)`'),
    ),
    (
      Text('radius={8}'),
      DocText('`borderRadius: 8` with `borderSkipped: BorderSkip.none`'),
    ),
    (
      Text('radius={[0, 0, 4, 4]}'),
      DocText("`extra: {'borderRadius': {'bottomLeft': 4, ...}}`"),
    ),
    (
      Text('barCategoryGap="10%"'),
      DocText('`categoryPercentage: 0.8` with `barPercentage: 1`'),
    ),
    (Text('layout="vertical"'), DocText('`indexAxis: const YAxis()`')),
    (Text('stackId="a"'), DocText('`stacked: true` on both axes')),
    (
      Text('<Cell fill={...} />, the fill of each item'),
      DocText('`backgroundColor: .indexed([...])`'),
    ),
    (
      Text('<CartesianGrid vertical={false} />'),
      DocText('the grid of the value axis, no grid on the category axis'),
    ),
    (
      Text('<XAxis hide />, <YAxis hide />'),
      DocText('`display: false` on the axis'),
    ),
    (
      Text('<ChartTooltip content={<ChartTooltipContent />} />'),
      DocText(
        '`TooltipOptions(enabled: false, external: ...)` in '
        '`pluginOptions` and a widget',
      ),
    ),
    (
      Text('<ChartLegend content={<ChartLegendContent />} />'),
      DocText('`legend: ChartLegend(position: .bottom, ...)`'),
    ),
    (
      Text('<LabelList position="top" />'),
      DocText('an inline plugin that draws after the datasets'),
    ),
    (
      Text('shape={(props) => <Rectangle />}'),
      DocText('indexed colors, and an inline plugin for a dash'),
    ),
    (Text('React.useState'), DocText('`setState` and a new `ChartConfig`')),
  ],
  demos: [
    shadcnDemo(
      'bar-default',
      title: const Text('Bar Chart'),
      notes: const [
        DocText(
          '`radius={8}` rounds the four corners: `borderRadius: 8` with '
          '`borderSkipped: BorderSkip.none`. By default, Chart.js keeps the '
          'two corners at the base square.',
        ),
        DocText(
          'Recharts gives a bar 80 % of its band (`barCategoryGap="10%"`): '
          '`categoryPercentage: 0.8` with `barPercentage: 1`.',
        ),
      ],
      replica: (_) => const ShadcnBarDefault(),
    ),
    shadcnDemo(
      'bar-horizontal',
      title: const Text('Bar Chart - Horizontal'),
      notes: const [
        DocText('`layout="vertical"` is `indexAxis: const YAxis()`.'),
        DocText(
          'The `YAxis` of the months is 60 px wide, and '
          '`margin={{left: -20}}` takes 20 px from it. The axis gets 40 px.',
        ),
      ],
      replica: (_) => const ShadcnBarHorizontal(),
    ),
    shadcnDemo(
      'bar-multiple',
      title: const Text('Bar Chart - Multiple'),
      notes: const [
        DocText(
          'Recharts puts 4 px (`barGap`) between the two bars of a month. '
          '`barPercentage: 0.92` gives about 4 px at the width of the card.',
        ),
        DocText('`indicator="dashed"` draws a dashed line before each row.'),
      ],
      replica: (_) => const ShadcnBarMultiple(),
    ),
    shadcnDemo(
      'bar-stacked',
      title: const Text('Bar Chart - Stacked + Legend'),
      notes: const [
        DocText(
          '`stackId="a"` is `stacked: true` on both axes. '
          '`radius={[0, 0, 4, 4]}` is the Chart.js object '
          "`{'bottomLeft': 4, 'bottomRight': 4}` in `extra`.",
        ),
        DocText(
          '`ChartLegendContent` is the legend of Chart.js under the chart, '
          'with 8 px squares. A tap on an item does nothing, as in shadcn/ui.',
        ),
        DocText(
          'The tooltip keeps the cursor of Recharts: an inline plugin draws a '
          'muted band under the hovered month.',
        ),
      ],
      replica: (_) => const ShadcnBarStacked(),
    ),
    shadcnDemo(
      'bar-label',
      title: const Text('Bar Chart - Label'),
      notes: const [
        DocText(
          '`<LabelList position="top" offset={12}>` is the inline plugin '
          '`shadcnLabels` of the shared code. It writes each value 12 px '
          'above its bar.',
        ),
      ],
      replica: (_) => const ShadcnBarLabel(),
    ),
    shadcnDemo(
      'bar-label-custom',
      title: const Text('Bar Chart - Custom Label'),
      notes: const [
        DocText(
          'The two `LabelList`s are two inline plugins: the month inside the '
          'bar in the background color, and the value right of the bar.',
        ),
        DocText(
          '`<CartesianGrid horizontal={false} />` keeps the vertical grid '
          'lines of the value axis.',
        ),
      ],
      replica: (_) => const ShadcnBarLabelCustom(),
    ),
    shadcnDemo(
      'bar-mixed',
      title: const Text('Bar Chart - Mixed'),
      notes: const [
        DocText(
          'Each bar takes the `fill` of its browser: '
          '`backgroundColor: .indexed(...)`. The tooltip shows the same '
          'color.',
        ),
      ],
      replica: (_) => const ShadcnBarMixed(),
    ),
    shadcnDemo(
      'bar-active',
      title: const Text('Bar Chart - Active'),
      notes: const [
        DocText(
          'The `shape` function draws the bar at `ACTIVE_INDEX` with 80 % '
          'opacity and a dashed stroke. The opacity is an indexed '
          '`backgroundColor`.',
        ),
        DocText(
          'Chart.js bars have no dash. Thus an inline plugin draws the dashed '
          'stroke after the bars.',
        ),
      ],
      replica: (_) => const ShadcnBarActive(),
    ),
    shadcnDemo(
      'bar-negative',
      title: const Text('Bar Chart - Negative'),
      notes: const [
        DocText(
          '`<Cell>` gives each bar the color of its sign: an indexed '
          '`backgroundColor`.',
        ),
        DocText(
          'A label of Recharts takes the color of its bar. Under 0, the label '
          'goes under the bar. The `color` function of `shadcnLabels` gives '
          'the color. The plugin puts the label of a bar under 0 under it.',
        ),
      ],
      replica: (_) => const ShadcnBarNegative(),
    ),
    shadcnDemo(
      'bar-interactive',
      title: const Text('Bar Chart - Interactive'),
      notes: const [
        DocText(
          'A tap on a button changes the active series in `setState`. The new '
          '`ChartConfig` has the data and the color of that series. The '
          '`ChartView` updates the chart with it.',
        ),
        DocText(
          'The tooltip keeps the cursor of Recharts: an inline plugin draws a '
          'muted band under the hovered day.',
        ),
      ],
      replica: (_) => const ShadcnBarInteractive(),
    ),
  ],
);
