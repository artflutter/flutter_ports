// Original code, not ported from Chart.js: the apexcharts_flutter bar page.
// Each note is one long text, split over lines of the source.

import 'package:chartjs_docs/migrate/apexcharts/bar_grouped.dart';
import 'package:chartjs_docs/migrate/apexcharts/bar_horizontal.dart';
import 'package:chartjs_docs/migrate/apexcharts/bar_stacked.dart';
import 'package:chartjs_docs/pages/migrate_apexcharts_page.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:chartjs_docs/ui/snippets.dart';
import 'package:material_ui/material_ui.dart';

/// The page "Migrate bar charts from apexcharts_flutter": the bar demos of
/// the example app of apexcharts_flutter 0.1.2.
DocPageContent apexChartsBarMigrationPage() => migrationPage(
  chart: 'bar',
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
        "apexcharts_flutter draws a bar chart from `chart: {type: 'bar'}` and "
        '`plotOptions.bar`. The port takes a `ChartConfig` with `type: .bar` '
        'and `BarDataset`s. The column width, the stack and the direction of '
        'the bars are options of the datasets, of the axes and of the chart. '
        'The data labels are a small inline plugin.',
      ),
    ),
  ],
  mapping: const [
    (
      Text('ApexChart(options: ApexOptions.fromJson({...}))'),
      DocText('`ChartView(config: ChartConfig(...))`'),
    ),
    (Text("chart: {type: 'bar'}"), DocText('`type: .bar`')),
    (
      Text('series: [{name, data}]'),
      DocText('`datasets: [BarDataset(label: ..., data: ...)]`'),
    ),
    (Text('xaxis.categories'), DocText('`labels`')),
    (Text('colors'), DocText('`backgroundColor` of each dataset')),
    (
      Text('plotOptions.bar.horizontal: true'),
      DocText('`indexAxis: const YAxis()`'),
    ),
    (
      Text("plotOptions.bar.columnWidth: '70%'"),
      DocText('`categoryPercentage: 0.7` with `barPercentage: 1`'),
    ),
    (Text('plotOptions.bar.borderRadius'), DocText('`borderRadius`')),
    (Text('chart.stacked: true'), DocText('`stacked: true` on both axes')),
    (
      Text('dataLabels'),
      DocText('an inline plugin that draws after the datasets'),
    ),
    (Text('legend'), DocText('`legend: ChartLegend(...)`')),
    (
      Text('tooltip'),
      DocText('`tooltip: ChartTooltip(...)` with the mode `index`'),
    ),
    (Text('chart.animations'), DocText('`animation: ChartAnimation(...)`')),
  ],
  demos: [
    ReplicaDemo(
      id: 'apex-bar-grouped',
      title: const Text('Bar — grouped (data labels)'),
      original: apexGallery,
      region: const CodeRegion(
        'lib/migrate/apexcharts/bar_grouped.dart',
        'apex-bar-grouped',
      ),
      notes: const [
        DocText(
          "`plotOptions.bar.columnWidth: '70%'` is `categoryPercentage: 0.7` "
          'with `barPercentage: 1`: the group takes 70 % of its band, and its '
          'columns touch.',
        ),
        DocText(
          'The data labels are an inline plugin that writes each value 2 px '
          'above its column.',
        ),
      ],
      replica: (_) => const ApexBarGrouped(),
    ),
    ReplicaDemo(
      id: 'apex-bar-stacked',
      title: const Text('Bar — stacked'),
      original: apexGallery,
      region: const CodeRegion(
        'lib/migrate/apexcharts/bar_stacked.dart',
        'apex-bar-stacked',
      ),
      notes: const [
        DocText('`chart.stacked: true` is `stacked: true` on both axes.'),
        DocText(
          'The value axis goes to 80, the largest sum. apexcharts_flutter '
          '0.1.2 scales the axis to the largest single value, 40, and cuts the '
          'columns at the top of the plot.',
        ),
      ],
      replica: (_) => const ApexBarStacked(),
    ),
    ReplicaDemo(
      id: 'apex-bar-horizontal',
      title: const Text('Bar — horizontal'),
      original: apexGallery,
      region: const CodeRegion(
        'lib/migrate/apexcharts/bar_horizontal.dart',
        'apex-bar-horizontal',
      ),
      notes: const [
        DocText(
          '`plotOptions.bar.horizontal: true` is `indexAxis: const YAxis()`.',
        ),
        DocText(
          'The categories are on the left and the values under the plot, as in '
          'ApexCharts. apexcharts_flutter 0.1.2 keeps the values on the left '
          'and the categories under the plot.',
        ),
      ],
      replica: (_) => const ApexBarHorizontal(),
    ),
  ],
);
