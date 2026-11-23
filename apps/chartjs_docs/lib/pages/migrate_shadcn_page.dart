// Original code, not ported from Chart.js: the shadcn/ui line page.
// Each note is one long text, split over lines of the source.

import 'package:chartjs_docs/migrate/shadcn/line_default.dart';
import 'package:chartjs_docs/migrate/shadcn/line_dots.dart';
import 'package:chartjs_docs/migrate/shadcn/line_dots_colors.dart';
import 'package:chartjs_docs/migrate/shadcn/line_dots_custom.dart';
import 'package:chartjs_docs/migrate/shadcn/line_interactive.dart';
import 'package:chartjs_docs/migrate/shadcn/line_label.dart';
import 'package:chartjs_docs/migrate/shadcn/line_label_custom.dart';
import 'package:chartjs_docs/migrate/shadcn/line_linear.dart';
import 'package:chartjs_docs/migrate/shadcn/line_multiple.dart';
import 'package:chartjs_docs/migrate/shadcn/line_step.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:material_ui/material_ui.dart';

/// The commit of shadcn/ui that the replicas follow.
const String shadcnCommit = 'e62c9435';

/// The credit line of the shadcn/ui pages.
const Text shadcnCredit = Text(
  'The demos come from the chart blocks of shadcn/ui at commit $shadcnCommit '
  '(MIT, shadcn). The blocks draw with Recharts 3.8.0. The data of the '
  'interactive demos is a copy of these blocks. The replicas are new code. '
  'They use no shadcn/ui code and no Recharts code.',
);

/// The shadcn/ui frame of the replicas: the white page of the demos.
const ReplicaFrame shadcnFrame = ReplicaFrame(background: Colors.white);

/// The shared code of the shadcn/ui replicas.
const CodeRegion shadcnKit = CodeRegion(
  'lib/migrate/shadcn/shadcn_kit.dart',
  'shadcn-kit',
);

/// The demo `chart-<name>` of shadcn/ui and its replica in
/// `lib/migrate/shadcn/<name>.dart`, with `-` as `_` in the file name.
ReplicaDemo shadcnDemo(
  String name, {
  required Widget title,
  required List<Widget> notes,
  required WidgetBuilder replica,
}) => ReplicaDemo(
  id: 'shadcn-$name',
  title: title,
  original: 'https://ui.shadcn.com/view/new-york-v4/chart-$name',
  region: CodeRegion(
    'lib/migrate/shadcn/${name.replaceAll('-', '_')}.dart',
    'shadcn-$name',
  ),
  notes: notes,
  replica: replica,
);

/// The intro paragraphs of both shadcn/ui pages, after the first one.
const List<Widget> shadcnIntro = [
  DocParagraph(
    DocText(
      '`ChartTooltipContent` is a React element of shadcn/ui. The replicas '
      'keep it as a Flutter widget over the chart. Chart.js draws no tooltip '
      '(`enabled: false`). It gives each change of the tooltip to the option '
      '`external`. '
      'The tooltip follows the pointer, as in Recharts.',
    ),
  ),
  DocParagraph(
    DocText(
      'The colors are the chart colors of the shadcn/ui site, `--chart-1` to '
      '`--chart-5`. The shared code gives them as `Shadcn.chart1` to '
      '`Shadcn.chart5`, next to the card of the demos, the axes and the '
      'labels.',
    ),
  ),
];

/// The page "Migrate line charts from shadcn/ui": the line chart demos of
/// shadcn/ui.
DocPageContent shadcnMigrationPage() => migrationPage(
  chart: 'line',
  library: 'shadcn/ui',
  version: 'at commit $shadcnCommit',
  gallery: 'https://ui.shadcn.com/charts/line#charts',
  icon: Icons.swap_horiz,
  kit: shadcnKit,
  frame: shadcnFrame,
  credit: shadcnCredit,
  intro: const [
    DocParagraph(
      DocText(
        'A shadcn/ui chart is a Recharts chart in a `ChartContainer`, with a '
        '`chartConfig` of labels and colors. The port takes a typed '
        '`ChartConfig` with `datasets` and `scales`. Each `<Line>` becomes a '
        '`LineDataset`. Its key in `chartConfig` gives the `label` and the '
        'colors of the dataset.',
      ),
    ),
    DocParagraph(
      DocText(
        'Recharts draws the curves `natural` and `monotone`. Chart.js has no '
        'such curve. But the option `cubicInterpolationMode` takes a class of '
        'the app. The classes `NaturalCurve` and `MonotoneXCurve` of the '
        'shared code give the curves of Recharts.',
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
      Text('<LineChart data={chartData}>'),
      DocText('`ChartConfig( labels: ...)`'),
    ),
    (
      Text('<Line dataKey="desktop" stroke="var(--color-desktop)" />'),
      DocText('`LineDataset(label: ..., data: ..., borderColor: ...)`'),
    ),
    (Text('strokeWidth={2}'), DocText('`borderWidth: 2`')),
    (
      Text('type="natural", type="monotone"'),
      DocText('`cubicInterpolationMode: NaturalCurve()`, `MonotoneXCurve()`'),
    ),
    (Text('type="linear"'), DocText('no option: the `tension` is 0')),
    (Text('type="step"'), DocText('`stepped: SteppedLine.middle`')),
    (Text('dot={false}'), DocText('`pointRadius: .constant(0)`')),
    (
      Text('dot={{fill}}, activeDot={{r: 6}}'),
      DocText('`pointBackgroundColor`, `pointHoverRadius: .constant(6)`'),
    ),
    (
      Text('dot={(props) => <Icon />}'),
      DocText('`pointStyle`: a subclass of `PointStyle`'),
    ),
    (
      Text('<CartesianGrid vertical={false} />'),
      DocText('the grid of the value axis, no grid on the category axis'),
    ),
    (
      Text('<XAxis dataKey="month" tickFormatter={...} />'),
      DocText('a `CategoryAxis` with a tick `callback`'),
    ),
    (
      Text('margin={{left: 12, right: 12}}'),
      DocText('`padding: EdgeInsets.symmetric(horizontal: 12)`'),
    ),
    (
      Text('<ChartTooltip content={<ChartTooltipContent />} />'),
      DocText('`ChartTooltip(enabled: false, external: ...)` and a widget'),
    ),
    (
      Text('the cursor of ChartTooltip'),
      DocText('an inline plugin that draws before the datasets'),
    ),
    (
      Text('<LabelList position="top" />'),
      DocText('an inline plugin that draws after the datasets'),
    ),
    (Text('aspect-video'), DocText('`aspectRatio: 16 / 9`')),
    (
      Text('className="h-[250px]"'),
      DocText('`maintainAspectRatio: false` in a `SizedBox(height: 250)`'),
    ),
    (Text('React.useState'), DocText('`setState` and a new `ChartConfig`')),
  ],
  demos: [
    shadcnDemo(
      'line-default',
      title: const Text('Line Chart'),
      notes: const [
        DocText(
          '`type="natural"` is `cubicInterpolationMode: NaturalCurve()` of '
          'the shared code: the natural spline of Recharts, with the same '
          'control points.',
        ),
        DocText(
          '`dot={false}` is `pointRadius: .constant(0)`. On a hover, '
          'Recharts draws an active dot of 4 px: '
          '`pointHoverRadius: .constant(4)`.',
        ),
      ],
      replica: (_) => const ShadcnLineDefault(),
    ),
    shadcnDemo(
      'line-linear',
      title: const Text('Line Chart - Linear'),
      notes: const [
        DocText(
          '`type="linear"` needs no option. The `tension` of Chart.js is 0. '
          'Thus the line is straight from one month to the next.',
        ),
      ],
      replica: (_) => const ShadcnLineLinear(),
    ),
    shadcnDemo(
      'line-step',
      title: const Text('Line Chart - Step'),
      notes: const [
        DocText(
          '`type="step"` is `stepped: SteppedLine.middle`: the step is '
          'halfway between two months.',
        ),
      ],
      replica: (_) => const ShadcnLineStep(),
    ),
    shadcnDemo(
      'line-multiple',
      title: const Text('Line Chart - Multiple'),
      notes: const [
        DocText(
          '`type="monotone"` is `cubicInterpolationMode: MonotoneXCurve()` of '
          'the shared code. The `MonotoneCubicInterpolationMode` of Chart.js '
          'also keeps the rise and the fall of the data, but its curve is '
          'not the same.',
        ),
        DocText(
          'Without `hideLabel`, the tooltip shows the month above the rows.',
        ),
      ],
      replica: (_) => const ShadcnLineMultiple(),
    ),
    shadcnDemo(
      'line-dots',
      title: const Text('Line Chart - Dots'),
      notes: const [
        DocText(
          '`dot={{fill: ...}}` keeps the 2 px stroke of the line around a '
          '3 px dot: `pointRadius: .constant(3)` with `pointBorderWidth: 2`.',
        ),
        DocText('`activeDot={{r: 6}}` is `pointHoverRadius: .constant(6)`.'),
      ],
      replica: (_) => const ShadcnLineDots(),
    ),
    shadcnDemo(
      'line-dots-custom',
      title: const Text('Line Chart - Custom Dots'),
      notes: const [
        DocText(
          'The `dot` function draws the lucide icon `GitCommitVertical` at '
          'each point. In the port, the icon is a subclass of `PointStyle` '
          'with a `draw` method.',
        ),
        DocText(
          'The original gives the icon the fill `hsl(var(--background))`. The '
          'v4 theme has no HSL values. Thus the browser fills the circles '
          'black. The replica fills them with the background color, as the '
          'code means.',
        ),
      ],
      replica: (_) => const ShadcnLineDotsCustom(),
    ),
    shadcnDemo(
      'line-dots-colors',
      title: const Text('Line Chart - Dots Colors'),
      notes: const [
        DocText(
          'Each point takes the `fill` of its browser: '
          '`pointBackgroundColor: .indexed(...)`.',
        ),
        DocText(
          'The chart has no `XAxis`: the category axis has `display: false`. '
          '`nameKey="visitors"` gives each row of the tooltip the name '
          '"Visitors".',
        ),
      ],
      replica: (_) => const ShadcnLineDotsColors(),
    ),
    shadcnDemo(
      'line-label',
      title: const Text('Line Chart - Label'),
      notes: const [
        DocText(
          '`<LabelList position="top" offset={12}>` is the inline plugin '
          '`shadcnLabels` of the shared code. It writes each value 12 px '
          'above its point.',
        ),
        DocText(
          '`indicator="line"` with one row puts the month into the row, above '
          'the name.',
        ),
      ],
      replica: (_) => const ShadcnLineLabel(),
    ),
    shadcnDemo(
      'line-label-custom',
      title: const Text('Line Chart - Custom Label'),
      notes: const [
        DocText(
          'The `formatter` of `LabelList` gives the name of the browser. In '
          'the port, it is the `text` function of `shadcnLabels`.',
        ),
      ],
      replica: (_) => const ShadcnLineLabelCustom(),
    ),
    shadcnDemo(
      'line-interactive',
      title: const Text('Line Chart - Interactive'),
      notes: const [
        DocText(
          'A tap on a button changes the active series in `setState`. The new '
          '`ChartConfig` has the data and the color of that series. The '
          '`ChartView` updates the chart with it.',
        ),
        DocText(
          '`minTickGap={32}` is `autoSkipPadding: 32`. The two '
          '`toLocaleDateString` calls are `shortDate` of the shared code.',
        ),
        DocText(
          'The tooltip keeps the cursor of Recharts: an inline plugin draws a '
          'line at the hovered day.',
        ),
      ],
      replica: (_) => const ShadcnLineInteractive(),
    ),
  ],
);
