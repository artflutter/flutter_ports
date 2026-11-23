// Original code, not ported from Chart.js: the ApexCharts.js line page.
// Each note is one long text, split over lines of the source.

import 'package:chartjs_docs/migrate/apexcharts_js/area_spline.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/line_basic.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/line_dashed.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/line_forecast.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/line_labels.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/line_stepline.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:material_ui/material_ui.dart';

/// The version of ApexCharts.js of the demos: the last release under the
/// MIT license.
const String apexJsVersion = '4.7.0';

/// The demo pages of ApexCharts.js.
const String apexJsDemos = 'https://apexcharts.com/javascript-chart-demos';

/// The shared code of the ApexCharts.js replicas.
const CodeRegion apexJsKit = CodeRegion(
  'lib/migrate/apexcharts_js/apexjs_kit.dart',
  'apexjs-kit',
);

/// The credit line of the ApexCharts.js pages.
const Text apexJsCredit = Text(
  'The demos come from samples/vanilla-js of ApexCharts.js 4.7.0 (MIT, '
  'ApexCharts), the last release under the MIT license. The replicas are '
  'new code, and they use no ApexCharts.js code.',
);

/// The introduction of both ApexCharts.js pages, after the first paragraph.
const List<Widget> apexJsIntro = [
  DocParagraph(
    DocText(
      'The replicas copy the defaults of ApexCharts.js: the five colors of '
      '`palette1`, the gray grid, the shared tooltip with its title bar, and '
      'the legend under the chart for more than one series. The look is in '
      'the shared code at the end of the page.',
    ),
  ),
  DocParagraph(
    DocText(
      'Where the original demo shows the zoom tools, the replica gets the '
      'zoom of the port of chartjs-plugin-zoom and the same toolbar. The '
      'wheel zooms only with the Ctrl key, so that the wheel still scrolls '
      'the page. The replicas have no menu to download an image or a CSV '
      'file.',
    ),
  ),
];

/// The section of the ApexCharts.js demo [file] in [folder] of the demo
/// site, for example `line-charts`.
ReplicaDemo apexJsDemo(
  String region, {
  required String folder,
  required String file,
  required Widget title,
  required List<Widget> notes,
  required WidgetBuilder replica,
}) => ReplicaDemo(
  id: region,
  title: title,
  original: '$apexJsDemos/$folder/$file/',
  region: CodeRegion(
    'lib/migrate/apexcharts_js/${region.substring('apexjs-'.length).replaceAll('-', '_')}.dart',
    region,
  ),
  notes: notes,
  replica: replica,
);

/// The page "Migrate line charts from ApexCharts.js": the line and area
/// demos of ApexCharts.js 4.7.0.
DocPageContent apexJsMigrationPage() => migrationPage(
  chart: 'line',
  library: 'ApexCharts.js',
  version: apexJsVersion,
  gallery: '$apexJsDemos/line-charts/',
  icon: Icons.swap_horiz,
  kit: apexJsKit,
  frame: const ReplicaFrame(background: Colors.white),
  credit: apexJsCredit,
  intro: const [
    DocParagraph(
      DocText(
        'ApexCharts.js takes one options object: `new ApexCharts(element, '
        'options)` with `chart`, `series`, `xaxis`, `stroke` and the other '
        'keys. The port takes a typed `ChartConfig` in a `ChartView`, with '
        '`datasets` and `scales`, as Chart.js does. Most keys have a direct '
        'equivalent. The data labels and the grid bands are small inline '
        'plugins.',
      ),
    ),
    ...apexJsIntro,
  ],
  mapping: const [
    (
      Text('new ApexCharts(el, options).render()'),
      DocText('`ChartView(config: ChartConfig(...))`'),
    ),
    (
      Text("chart: {type: 'line'}, {type: 'area'}"),
      DocText('`LineDataset`, and `fill: .toStart` for an area'),
    ),
    (
      Text('series: [{name, data}]'),
      DocText('`datasets: [LineDataset(label: ..., data: ...)]`'),
    ),
    (Text('xaxis.categories'), DocText('`labels`')),
    (
      Text("xaxis: {type: 'datetime'}"),
      DocText('`TimeAxis`, and `data: .points([DataPoint.time(date, y)])`'),
    ),
    (Text('colors'), DocText('`borderColor` and `backgroundColor`')),
    (
      Text("stroke: {curve: 'smooth'}"),
      DocText('`tension: 0.4`. The default of a line is `straight`.'),
    ),
    (
      Text("stroke: {curve: 'stepline'}"),
      DocText('`stepped: SteppedLine.before`'),
    ),
    (
      Text('stroke.width, stroke.dashArray'),
      DocText('`borderWidth`, `borderDash` of each dataset'),
    ),
    (Text('markers.size'), DocText('`pointRadius`')),
    (Text('chart.dropShadow'), DocText('`shadow: ChartShadow(...)`')),
    (
      Text("fill: {type: 'gradient'}"),
      DocText('`ChartGradient.linear` in a `ChartValue.resolver`'),
    ),
    (
      Text('forecastDataPoints: {count: 7}'),
      DocText('`segment: LineSegmentStyle(borderDash: ...)`'),
    ),
    (Text('title: {text, align}'), DocText('`title: ChartTitle(...)`')),
    (
      Text('xaxis.title, yaxis.title'),
      DocText('the `title` of each axis: `AxisTitle`'),
    ),
    (
      Text('yaxis: {min, max}'),
      DocText('`min`, `max` and `stepSize` of `LinearAxis`'),
    ),
    (
      Text('legend: {position, horizontalAlign}'),
      DocText('`LegendOptions(position: ..., align: ...)`'),
    ),
    (
      Text('tooltip: {shared: true}'),
      DocText('`IndexInteractionMode` with `intersect: false`'),
    ),
    (
      Text('tooltip.y.title.formatter'),
      DocText('`tooltipCallbacks: TooltipCallbacks(label: ...)` of a dataset'),
    ),
    (
      Text('dataLabels: {enabled: true}'),
      DocText('an inline plugin that draws after the datasets'),
    ),
    (
      Text('grid.row.colors'),
      DocText('an inline plugin that fills the bands before the datasets'),
    ),
    (
      Text('chart.zoom, the toolbar'),
      DocText('`zoomPlugin` of flutter_chartjs_plugin_zoom_port'),
    ),
  ],
  demos: [
    apexJsDemo(
      'apexjs-line-basic',
      folder: 'line-charts',
      file: 'basic-line',
      title: const Text('Basic Line Chart'),
      notes: const [
        DocText(
          "`stroke: {curve: 'straight'}` is the default of Chart.js: "
          '`tension: 0`. A line of ApexCharts.js is 5 px wide, with 0.85 '
          'alpha.',
        ),
        DocText(
          "`grid.row: {colors: ['#f3f3f3', 'transparent']}` fills every "
          'second band between the grid lines. Chart.js has no such option. '
          'An inline plugin fills the bands before the datasets.',
        ),
        DocText(
          'ApexCharts.js shows no legend for one series. The replica sets '
          '`LegendOptions(display: false)`.',
        ),
      ],
      replica: (_) => const ApexJsLineBasic(),
    ),
    apexJsDemo(
      'apexjs-line-labels',
      folder: 'line-charts',
      file: 'line-with-data-labels',
      title: const Text('Line with Data Labels'),
      notes: const [
        DocText(
          '`chart.dropShadow` is the `shadow` of each dataset: '
          '`ChartShadow(color: ..., blur: 10, offset: Offset(7, 18))`.',
        ),
        DocText(
          'The data labels are an inline plugin. It draws each value in a '
          'box of the series color after the datasets.',
        ),
        DocText(
          "`legend: {position: 'top', horizontalAlign: 'right'}` is "
          '`LegendOptions(position: .top, align: .end)`. Chart.js has no '
          'floating legend: the legend takes its own row.',
        ),
      ],
      replica: (_) => const ApexJsLineLabels(),
    ),
    apexJsDemo(
      'apexjs-line-dashed',
      folder: 'line-charts',
      file: 'dashed-line',
      title: const Text('Dashed Line Chart'),
      notes: const [
        DocText(
          '`stroke.width` and `stroke.dashArray` take one value for each '
          'series. In the port, each dataset has its own `borderWidth` and '
          '`borderDash`: `dashArray: 8` is `borderDash: [8, 8]`.',
        ),
        DocText(
          '`tooltip.y` with one `title.formatter` for each series is the '
          '`tooltipCallbacks` of each dataset.',
        ),
        DocText(
          '`legend.tooltipHoverFormatter` writes the hovered value into the '
          'legend. The port has no such option: the tooltip shows the '
          'values.',
        ),
      ],
      replica: (_) => const ApexJsLineDashed(),
    ),
    apexJsDemo(
      'apexjs-line-stepline',
      folder: 'line-charts',
      file: 'stepline',
      title: const Text('Stepline Chart'),
      notes: const [
        DocText(
          "`stroke: {curve: 'stepline'}` is `stepped: SteppedLine.before`: "
          'the line goes across to the next point, then up or down.',
        ),
        DocText(
          'A series with no name and no categories: ApexCharts.js numbers '
          "the points from 1 and calls the series 'series-1'. The replica "
          'gives these labels.',
        ),
        DocText(
          'The zoom is on by default in ApexCharts.js. A drag selects a '
          'range, and the toolbar zooms, pans and resets.',
        ),
      ],
      replica: (_) => const ApexJsLineStepline(),
    ),
    apexJsDemo(
      'apexjs-line-forecast',
      folder: 'line-charts',
      file: 'gradient-line',
      title: const Text('Gradient Line Chart'),
      notes: const [
        DocText(
          "`fill: {type: 'gradient', gradient: {type: 'horizontal'}}` on a "
          'line colors the line across the plot. The replica gives '
          '`borderColor` a `ChartGradient.linear` from the left to the right '
          'of the chart area.',
        ),
        DocText(
          '`forecastDataPoints: {count: 7}` dashes the line to the last 7 '
          'points. A `LineSegmentStyle` gives those segments a '
          '`borderDash`.',
        ),
        DocText(
          '`xaxis: {tickAmount: 10}` makes 10 even ticks. The `TimeAxis` of '
          'the replica puts a tick at each point and skips the ticks that '
          'do not fit.',
        ),
      ],
      replica: (_) => const ApexJsLineForecast(),
    ),
    apexJsDemo(
      'apexjs-area-spline',
      folder: 'area-charts',
      file: 'area-spline',
      title: const Text('Spline Area'),
      notes: const [
        DocText(
          "`chart: {type: 'area'}` is a `LineDataset` with `fill: .toStart`. "
          'The default area fill of ApexCharts.js is a vertical gradient '
          'from the series color at 0.65 alpha to a lighter color at 0.5 '
          'alpha: `apexAreaFill` of the apexcharts_flutter kit.',
        ),
        DocText(
          "`xaxis: {type: 'datetime'}` with ISO times is a `TimeAxis` with "
          "`unit: .hour`. `tooltip.x.format: 'dd/MM/yy HH:mm'` is its "
          '`tooltipFormat`. ApexCharts.js writes the times in UTC. The '
          'replica gives local times, so the labels are the same in each '
          'time zone.',
        ),
        DocText(
          'ApexCharts.js draws the areas under all lines. '
          '`FillerOptions(drawTime: .beforeDatasetsDraw)` in `pluginOptions` '
          'does the same. With the default, the area of the first series '
          'covers the line of the second.',
        ),
      ],
      replica: (_) => const ApexJsAreaSpline(),
    ),
  ],
);
