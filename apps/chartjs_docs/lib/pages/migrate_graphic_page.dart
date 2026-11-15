// Original code, not ported from Chart.js: the page "Migrate from Graphic".
// Each note is one long text, split over lines of the source.

import 'package:chartjs_docs/migrate/graphic/area.dart';
import 'package:chartjs_docs/migrate/graphic/group_interactions.dart';
import 'package:chartjs_docs/migrate/graphic/river.dart';
import 'package:chartjs_docs/migrate/graphic/spider_net.dart';
import 'package:chartjs_docs/migrate/graphic/time_series.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:material_ui/material_ui.dart';

const String _gallery =
    'https://github.com/entronad/graphic/blob/main/example/lib/pages/line_area_point.dart';

/// The page "Migrate from Graphic": the line charts of the Graphic demos.
DocPageContent graphicMigrationPage() => migrationPage(
  chart: 'line',
  library: 'Graphic',
  version: '2.7.0',
  gallery: _gallery,
  icon: Icons.swap_horiz,
  kit: const CodeRegion('lib/migrate/graphic/graphic_kit.dart', 'graphic-kit'),
  frame: const ReplicaFrame(background: Colors.white),
  credit: const Text(
    'The demos and their data come from the Graphic example app (MIT, '
    'LIN Chen). The replicas are new code.',
  ),
  intro: const [
    DocParagraph(
      DocText(
        'Graphic describes a chart as a grammar of graphics: `variables` read '
        'each datum, `marks` draw them, and `coord`, `axes` and `selections` '
        'complete the chart. The port takes a `ChartConfig` with `datasets` '
        'and `scales`, as Chart.js does. A Graphic group (`Varset` with `/`) '
        'is one dataset for each group. The guides of Graphic that Chart.js '
        'does not have, the crosshair and the region color, are small inline '
        'plugins. The replicas share the Graphic defaults (the colors, the '
        'axes and the tooltip window) in one file, `graphic_kit.dart`.',
      ),
    ),
  ],
  mapping: const [
    (
      Text('Chart(data:, variables:, marks:)'),
      DocText('`ChartView(config: ChartConfig(...))`'),
    ),
    (Text('LineMark'), DocText('`LineDataset`')),
    (
      Text('AreaMark'),
      DocText('`fill` and `backgroundColor` of a `LineDataset`'),
    ),
    (Text('PointMark'), DocText('`pointRadius` and the point colors')),
    (Text('BasicLineShape(smooth: true)'), DocText('`tension`')),
    (Text('BasicLineShape(dash: [...])'), DocText('`borderDash`')),
    (Text('PolarCoord with a loop line'), DocText('a `RadarDataset`')),
    (
      Text('LinearScale, TimeScale, OrdinalScale'),
      DocText('`LinearAxis`, `TimeAxis`, `CategoryAxis`'),
    ),
    (Text('AxisGuide'), DocText('the `ticks` and `grid` of each axis')),
    (
      Text('ColorEncode(encoder: ...)'),
      DocText('a `ChartValue.resolver` or one dataset for each group'),
    ),
    (
      Text('PointSelection and TooltipGuide'),
      DocText('`tooltip` and `interaction`'),
    ),
    (
      Text('TooltipGuide(anchor:, align:, offset:)'),
      DocText('a subclass of `TooltipPositioner` in `ChartTooltip.position`'),
    ),
    (
      Text('CrosshairGuide'),
      DocText('an inline plugin that draws in `afterDatasetsDraw`'),
    ),
    (
      Text('RectCoord(color: ...)'),
      DocText('an inline plugin that fills the chart area'),
    ),
    (Text('StackModifier'), DocText('`stacked: true` of the y axis')),
    (
      Text('SymmetricModifier'),
      DocText(
        'datasets of the computed edges with `fill: FillTarget.toPrevious`',
      ),
    ),
    (
      Text('selected: {...}'),
      DocText('`setActiveElements` in `onChartCreated`'),
    ),
  ],
  demos: [
    ReplicaDemo(
      id: 'graphic-time-series',
      title: const Text('Time series line chart'),
      original: _gallery,
      region: const CodeRegion(
        'lib/migrate/graphic/time_series.dart',
        'graphic-time-series',
      ),
      notes: const [
        DocText(
          'A `TimeScale` is a `TimeAxis` with `DataPoint.time` points. Graphic '
          'puts 5 ticks at equal steps from the min to the max. The '
          'replica gives these dates in `labels`, with the tick source '
          '`labels`.',
        ),
        DocText(
          'The pre-selected point is a call of `setActiveElements` on the '
          'chart and on its tooltip in `onChartCreated`.',
        ),
        DocText(
          'The dash is `borderDash`. The region color and the crosshair are '
          'inline plugins.',
        ),
      ],
      replica: (_) => const GraphicTimeSeries(),
    ),
    ReplicaDemo(
      id: 'graphic-area',
      title: const Text('Area chart'),
      original: _gallery,
      region: const CodeRegion('lib/migrate/graphic/area.dart', 'graphic-area'),
      notes: const [
        DocText(
          'The `AreaMark` and the `LineMark` are one `LineDataset` with '
          '`fill: .toStart`: the area goes down to the bottom of the axis.',
        ),
        DocText(
          'A `null` or a `double.nan` value breaks the line and the area, as '
          'in Graphic.',
        ),
        DocText(
          'An `OrdinalScale` is a `CategoryAxis` with `offset: true`. The '
          'tick `callback` shows 5 labels at the steps of Graphic.',
        ),
      ],
      replica: (_) => const GraphicArea(),
    ),
    ReplicaDemo(
      id: 'graphic-group-interactions',
      title: const Text('Group interactions'),
      original: _gallery,
      region: const CodeRegion(
        'lib/migrate/graphic/group_interactions.dart',
        'graphic-group-interactions',
      ),
      notes: const [
        DocText(
          'Each name is one dataset. A name has no value on some dates: '
          '`spanGaps: true` joins its points.',
        ),
        DocText(
          'The `updaters` of the group selection are an inline plugin: it '
          'sets `globalAlpha` for the other datasets in '
          '`beforeDatasetDraw`.',
        ),
        DocText(
          'The mouse and the touch selections of Graphic are one '
          '`interaction` with the mode `nearest`. Both devices get the same '
          'behavior.',
        ),
      ],
      replica: (_) => const GraphicGroupInteractions(),
    ),
    ReplicaDemo(
      id: 'graphic-river',
      title: const Text('River chart'),
      original: _gallery,
      region: const CodeRegion(
        'lib/migrate/graphic/river.dart',
        'graphic-river',
      ),
      notes: const [
        DocText(
          'Chart.js stacks negative and positive values apart. Thus the '
          'replica computes the edges of the stack, centered on 0, and '
          'each band fills to the edge below it.',
        ),
        DocText(
          'The smooth area of Graphic is a Catmull-Rom spline: `tension: 0.5` '
          'gives the same curve.',
        ),
        DocText(
          'The tooltip `filter` leaves out the dataset of the bottom edge.',
        ),
      ],
      replica: (_) => const GraphicRiver(),
    ),
    ReplicaDemo(
      id: 'graphic-spider-net',
      title: const Text('Spider Net Chart'),
      original: _gallery,
      region: const CodeRegion(
        'lib/migrate/graphic/spider_net.dart',
        'graphic-spider-net',
      ),
      notes: const [
        DocText(
          'A loop line in a `PolarCoord` is a `RadarDataset`. `startAngle` '
          'puts the first index in the middle of its band, as Graphic '
          'does.',
        ),
        DocText(
          'Chart.js draws its tick labels along the start angle. An inline '
          'plugin draws the radial axis of Graphic: a line up from the '
          'center and its labels.',
        ),
        DocText(
          'Graphic selects the index nearest in angle. The replica selects '
          'the index of the nearest point. Chart.js also keeps the point '
          'labels inside the chart, so the net is a little smaller.',
        ),
      ],
      replica: (_) => const GraphicSpiderNet(),
    ),
  ],
);
