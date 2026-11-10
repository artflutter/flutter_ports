// Original code, not ported from Chart.js: the page "Migrate from Graphic".
// Each note is one long text, split over lines of the source.
// ignore_for_file: no_adjacent_strings_in_list

import 'package:chartjs_docs/migrate/graphic/area.dart';
import 'package:chartjs_docs/migrate/graphic/group_interactions.dart';
import 'package:chartjs_docs/migrate/graphic/river.dart';
import 'package:chartjs_docs/migrate/graphic/spider_net.dart';
import 'package:chartjs_docs/migrate/graphic/time_series.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:material_ui/material_ui.dart';

const String _gallery =
    'https://github.com/entronad/graphic/blob/main/example/lib/pages/line_area_point.dart';

/// The page "Migrate from Graphic": the line charts of the Graphic demos.
DocPageContent graphicMigrationPage() => migrationPage(
  library: 'Graphic',
  version: '2.7.0',
  gallery: _gallery,
  icon: Icons.swap_horiz,
  kit: 'graphic-kit',
  frame: const ReplicaFrame(background: Colors.white),
  credit:
      'The demos and their data come from the Graphic example app (MIT, '
      'LIN Chen). The replicas are new code.',
  intro: const [
    DocParagraph(
      'Graphic describes a chart as a grammar of graphics: `variables` read '
      'each datum, `marks` draw them, and `coord`, `axes` and `selections` '
      'complete the chart. The port takes a `ChartConfig` with `datasets` '
      'and `scales`, as Chart.js does. A Graphic group (`Varset` with `/`) '
      'is one dataset for each group. The guides of Graphic that Chart.js '
      'does not have, the crosshair and the region color, are small inline '
      'plugins. The replicas share the Graphic defaults (the colors, the '
      'axes and the tooltip window) in one file, `graphic_kit.dart`.',
    ),
  ],
  mapping: const [
    (
      'Chart(data:, variables:, marks:)',
      '`ChartView(config: ChartConfig(...))`',
    ),
    ('LineMark', '`LineDataset`'),
    ('AreaMark', '`fill` and `backgroundColor` of a `LineDataset`'),
    ('PointMark', '`pointRadius` and the point colors'),
    ('BasicLineShape(smooth: true)', '`tension`'),
    ('BasicLineShape(dash: [...])', '`borderDash`'),
    ('PolarCoord with a loop line', 'a `RadarDataset`'),
    (
      'LinearScale, TimeScale, OrdinalScale',
      '`LinearAxis`, `TimeAxis`, `CategoryAxis`',
    ),
    ('AxisGuide', 'the `ticks` and `grid` of each axis'),
    (
      'ColorEncode(encoder: ...)',
      'a `ChartValue.resolver` or one dataset for each group',
    ),
    ('PointSelection and TooltipGuide', '`tooltip` and `interaction`'),
    (
      'TooltipGuide(anchor:, align:, offset:)',
      'a custom `position` of `Tooltip.positioners`',
    ),
    ('CrosshairGuide', 'an inline plugin that draws in `afterDatasetsDraw`'),
    ('RectCoord(color: ...)', 'an inline plugin that fills the chart area'),
    ('StackModifier', '`stacked: true` of the y axis'),
    (
      'SymmetricModifier',
      'datasets of the computed edges with `fill: ChartFill.relative(-1)`',
    ),
    ('selected: {...}', '`setActiveElements` in `onChartCreated`'),
  ],
  demos: [
    ReplicaDemo(
      id: 'graphic-time-series',
      title: 'Time series line chart',
      original: _gallery,
      region: 'graphic-time-series',
      notes: const [
        'A `TimeScale` is a `TimeAxis` with `DataPoint.time` points. Graphic '
            'puts 5 ticks at equal steps from the min to the max. The '
            'replica gives these dates in `labels`, with the tick source '
            '`labels`.',
        'The pre-selected point is a call of `setActiveElements` on the '
            'chart and on its tooltip in `onChartCreated`.',
        'The dash is `borderDash`. The region color and the crosshair are '
            'inline plugins.',
      ],
      replica: (_) => const GraphicTimeSeries(),
    ),
    ReplicaDemo(
      id: 'graphic-area',
      title: 'Area chart',
      original: _gallery,
      region: 'graphic-area',
      notes: const [
        'The `AreaMark` and the `LineMark` are one `LineDataset` with '
            '`fill: .start`: the area goes down to the bottom of the axis.',
        'A `null` or a `double.nan` value breaks the line and the area, as '
            'in Graphic.',
        'An `OrdinalScale` is a `CategoryAxis` with `offset: true`. The '
            'tick `format` shows 5 labels at the steps of Graphic.',
      ],
      replica: (_) => const GraphicArea(),
    ),
    ReplicaDemo(
      id: 'graphic-group-interactions',
      title: 'Group interactions',
      original: _gallery,
      region: 'graphic-group-interactions',
      notes: const [
        'Each name is one dataset. A name has no value on some dates: '
            '`spanGaps: true` joins its points.',
        'The `updaters` of the group selection are an inline plugin: it '
            'sets `globalAlpha` for the other datasets in '
            '`beforeDatasetDraw`.',
        'The mouse and the touch selections of Graphic are one '
            '`interaction` with the mode `nearest`. Both devices get the same '
            'behavior.',
      ],
      replica: (_) => const GraphicGroupInteractions(),
    ),
    ReplicaDemo(
      id: 'graphic-river',
      title: 'River chart',
      original: _gallery,
      region: 'graphic-river',
      notes: const [
        'Chart.js stacks negative and positive values apart. Thus the '
            'replica computes the edges of the stack, centered on 0, and '
            'each band fills to the edge below it.',
        'The smooth area of Graphic is a Catmull-Rom spline: `tension: 0.5` '
            'gives the same curve.',
        'The tooltip `filter` leaves out the dataset of the bottom edge.',
      ],
      replica: (_) => const GraphicRiver(),
    ),
    ReplicaDemo(
      id: 'graphic-spider-net',
      title: 'Spider Net Chart',
      original: _gallery,
      region: 'graphic-spider-net',
      notes: const [
        'A loop line in a `PolarCoord` is a `RadarDataset`. `startAngle` '
            'puts the first index in the middle of its band, as Graphic '
            'does.',
        'Chart.js draws its tick labels along the start angle. An inline '
            'plugin draws the radial axis of Graphic: a line up from the '
            'center and its labels.',
        'Graphic selects the index nearest in angle. The replica selects '
            'the index of the nearest point. Chart.js also keeps the point '
            'labels inside the chart, so the net is a little smaller.',
      ],
      replica: (_) => const GraphicSpiderNet(),
    ),
  ],
);
