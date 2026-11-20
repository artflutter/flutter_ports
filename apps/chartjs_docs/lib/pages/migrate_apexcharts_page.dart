// Original code, not ported from Chart.js: the apexcharts_flutter line page.
// Each note is one long text, split over lines of the source.

import 'package:chartjs_docs/migrate/apexcharts/area_datetime.dart';
import 'package:chartjs_docs/migrate/apexcharts/area_labels.dart';
import 'package:chartjs_docs/migrate/apexcharts/line_markers.dart';
import 'package:chartjs_docs/migrate/apexcharts/line_multi.dart';
import 'package:chartjs_docs/migrate/apexcharts/line_timeseries.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:material_ui/material_ui.dart';

/// The live gallery of the example app of apexcharts_flutter.
const String apexGallery = 'https://eduardoh89.github.io/apexcharts_flutter/';

/// The credit line of the apexcharts_flutter pages.
const Text apexCredit = Text(
  'The demos come from the example app of apexcharts_flutter 0.1.2 (MIT, '
  'Eduardo H), a port of ApexCharts 4.7.0 (MIT, ApexCharts). The data of the '
  'datetime area demo is a copy of that app. The replicas are new code, and '
  'they use no apexcharts_flutter code.',
);

/// The page "Migrate line charts from apexcharts_flutter": the line and
/// area demos of the example app of apexcharts_flutter 0.1.2.
DocPageContent apexChartsMigrationPage() => migrationPage(
  chart: 'line',
  library: 'apexcharts_flutter',
  version: '0.1.2',
  gallery: apexGallery,
  icon: Icons.swap_horiz,
  kit: const CodeRegion('lib/migrate/apexcharts/apex_kit.dart', 'apex-kit'),
  frame: const ReplicaFrame(background: Colors.white),
  credit: apexCredit,
  intro: const [
    DocParagraph(
      DocText(
        'apexcharts_flutter takes one ApexCharts options Map in '
        '`ApexOptions.fromJson`: `chart`, `series`, `xaxis`, `stroke` and the '
        'other keys of ApexCharts. The port takes a typed `ChartConfig` with '
        '`datasets` and `scales`, as Chart.js does. Most keys have a direct '
        'equivalent. The data labels and the annotations are small inline '
        'plugins.',
      ),
    ),
    DocParagraph(
      DocText(
        'apexcharts_flutter turns on the zoom of each line and area chart, '
        'with a toolbar. The replicas get the zoom from the port of '
        'chartjs-plugin-zoom, and the toolbar from the shared code. The wheel '
        'zooms with the Ctrl key, so that the wheel still scrolls the page.',
      ),
    ),
  ],
  mapping: const [
    (
      Text('ApexChart(options: ApexOptions.fromJson({...}))'),
      DocText('`ChartView(config: ChartConfig(...))`'),
    ),
    (
      Text("chart: {type: 'line'}, {type: 'area'}"),
      DocText('`type: .line`, and `fill: .toStart` for an area'),
    ),
    (
      Text('series: [{name, data}]'),
      DocText('`datasets: [LineDataset(label: ..., data: ...)]`'),
    ),
    (Text('xaxis.categories'), DocText('`labels`')),
    (
      Text("xaxis: {type: 'datetime'}, data: [[ms, y]]"),
      DocText('`TimeAxis`, and `points: [DataPoint.time(date, y)]`'),
    ),
    (Text('xaxis.min, xaxis.max'), DocText('`min` and `max` of the axis')),
    (Text('colors'), DocText('`borderColor` and `backgroundColor`')),
    (
      Text("stroke: {curve: 'smooth'}, {curve: 'stepline'}"),
      DocText('`tension: 0.4`, `stepped`'),
    ),
    (
      Text('stroke.width, stroke.dashArray'),
      DocText('`borderWidth`, `borderDash`'),
    ),
    (Text('markers.size'), DocText('`pointRadius` and the point colors')),
    (
      Text('fill.gradient'),
      DocText('a scriptable `backgroundColor` that returns a `ChartGradient`'),
    ),
    (Text('xaxis.title, yaxis.title'), DocText('the `title` of each axis')),
    (
      Text('tooltip.y.prefix, tooltip.y.suffix'),
      DocText('a tick `callback` and a tooltip `label` callback'),
    ),
    (Text('tooltip.x.format'), DocText('`tooltipFormat` of `TimeAxis`')),
    (Text('legend'), DocText('`legend: ChartLegend(...)`')),
    (
      Text('dataLabels, annotations'),
      DocText('an inline plugin that draws after the datasets'),
    ),
    (
      Text('chart.zoom, the toolbar'),
      DocText('`zoomPlugin` of flutter_chartjs_plugin_zoom_port'),
    ),
    (
      Text('ApexChartController.zoomX(min, max)'),
      DocText("`chart.zoomScale('x', (min: min, max: max))`"),
    ),
    (Text('chart.animations'), DocText('`animation: ChartAnimation(...)`')),
  ],
  demos: [
    ReplicaDemo(
      id: 'apex-area-datetime',
      title: const Text('Area — Datetime (zoom / pan · range buttons)'),
      original: apexGallery,
      region: const CodeRegion(
        'lib/migrate/apexcharts/area_datetime.dart',
        'apex-area-datetime',
      ),
      notes: const [
        DocText(
          'The range buttons call `zoomScale` of the zoom port, in place of '
          '`ApexChartController.zoomX`.',
        ),
        DocText(
          '`xaxis.min` is the `min` of the `TimeAxis`. The zoom limits keep '
          'the range inside the data, as in apexcharts_flutter.',
        ),
        DocText(
          'Chart.js fits the y axis to the points in the range of the x axis. '
          'This is `zoom.autoScaleYaxis` of ApexCharts.',
        ),
        DocText(
          'The annotations "Support" and "Rally" are an inline plugin that '
          'draws the dashed lines and their labels after the datasets.',
        ),
      ],
      replica: (_) => const ApexAreaDatetime(),
    ),
    ReplicaDemo(
      id: 'apex-line-markers',
      title: const Text(r'Line — markers + axis titles + $ format'),
      original: apexGallery,
      region: const CodeRegion(
        'lib/migrate/apexcharts/line_markers.dart',
        'apex-line-markers',
      ),
      notes: const [
        DocText(
          '`markers.size` is `pointRadius`, with the series color as '
          '`pointBackgroundColor` and a white `pointBorderColor`.',
        ),
        DocText(
          'apexcharts_flutter puts the prefix and the suffix of `tooltip.y` on '
          'the tooltip and on the y labels. The port writes them in a tick '
          '`callback` and in a tooltip `label` callback.',
        ),
        DocText(
          '`xaxis.title` and `yaxis.title` are the `title` of each axis.',
        ),
      ],
      replica: (_) => const ApexLineMarkers(),
    ),
    ReplicaDemo(
      id: 'apex-line-multi',
      title: const Text('Line — multi-series'),
      original: apexGallery,
      region: const CodeRegion(
        'lib/migrate/apexcharts/line_multi.dart',
        'apex-line-multi',
      ),
      notes: const [
        DocText(
          'Each series is a `LineDataset`. apexcharts_flutter shows the legend '
          'only for more than one series: the replicas with one dataset set '
          '`display: false`.',
        ),
        DocText(
          'A tap on a legend item hides its line, as in ApexCharts. The legend '
          'of apexcharts_flutter 0.1.2 does not react to a tap.',
        ),
      ],
      replica: (_) => const ApexLineMulti(),
    ),
    ReplicaDemo(
      id: 'apex-line-timeseries',
      title: const Text('Line — zoomable timeseries (drag / wheel to zoom)'),
      original: apexGallery,
      region: const CodeRegion(
        'lib/migrate/apexcharts/line_timeseries.dart',
        'apex-line-timeseries',
      ),
      notes: const [
        DocText(
          "`xaxis: {type: 'datetime'}` is a `TimeAxis`, and each `[ms, y]` "
          'pair is a `DataPoint.time`.',
        ),
        DocText("`stroke: {curve: 'smooth'}` is `tension: 0.4`."),
        DocText(
          'A drag selects a range of days. The pan button of the toolbar '
          'changes the drag to a pan.',
        ),
      ],
      replica: (_) => const ApexLineTimeseries(),
    ),
    ReplicaDemo(
      id: 'apex-area-labels',
      title: const Text('Area — with data labels'),
      original: apexGallery,
      region: const CodeRegion(
        'lib/migrate/apexcharts/area_labels.dart',
        'apex-area-labels',
      ),
      notes: const [
        DocText(
          "`chart: {type: 'area'}` is a `LineDataset` with `fill: .toStart`. "
          'A scriptable `backgroundColor` gives the gradient of the area.',
        ),
        DocText(
          'The data labels are an inline plugin that writes each value over '
          'its point.',
        ),
      ],
      replica: (_) => const ApexAreaLabels(),
    ),
  ],
);
