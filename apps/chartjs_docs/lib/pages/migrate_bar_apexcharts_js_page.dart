// Original code, not ported from Chart.js: the ApexCharts.js bar page.
// Each note is one long text, split over lines of the source.

import 'package:chartjs_docs/migrate/apexcharts_js/bar_basic.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/bar_grouped.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/bar_pyramid.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/bar_stacked.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/column_basic.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/column_distributed.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/column_labels.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/column_negative.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/column_stacked.dart';
import 'package:chartjs_docs/pages/migrate_apexcharts_js_page.dart';
import 'package:chartjs_docs/ui/doc_blocks.dart';
import 'package:chartjs_docs/ui/doc_page.dart';
import 'package:chartjs_docs/ui/replica_block.dart';
import 'package:material_ui/material_ui.dart';

/// The page "Migrate bar charts from ApexCharts.js": the column and bar
/// demos of ApexCharts.js 4.7.0.
DocPageContent apexJsBarMigrationPage() => migrationPage(
  chart: 'bar',
  library: 'ApexCharts.js',
  version: apexJsVersion,
  gallery: '$apexJsDemos/column-charts/',
  icon: Icons.swap_horiz,
  kit: apexJsKit,
  frame: const ReplicaFrame(background: Colors.white),
  credit: apexJsCredit,
  intro: const [
    DocParagraph(
      DocText(
        "ApexCharts.js draws columns and bars with `chart: {type: 'bar'}`, "
        'and `plotOptions.bar.horizontal: true` turns them. The port takes '
        '`BarDataset`s, and `indexAxis: .y` turns the bars. The corners, the '
        'stacks and the width of the bars are options of the datasets and '
        'of the axes.',
      ),
    ),
    ...apexJsIntro,
  ],
  mapping: const [
    (Text("chart: {type: 'bar'}"), DocText('`datasets: [BarDataset(...)]`')),
    (
      Text('plotOptions.bar.horizontal: true'),
      DocText('`indexAxis: .y` of the `ChartConfig`'),
    ),
    (
      Text("columnWidth: '55%', barHeight: '80%'"),
      DocText('`categoryPercentage: 0.55` with `barPercentage: 1`'),
    ),
    (
      Text("borderRadius, borderRadiusApplication: 'end'"),
      DocText('`borderRadius`: Chart.js rounds the end of a bar by default'),
    ),
    (
      Text("borderRadiusApplication: 'around'"),
      DocText('`borderRadius` with `borderSkipped: BorderSkip.none`'),
    ),
    (
      Text("borderRadiusWhenStacked: 'last'"),
      DocText('`borderRadius` on the last dataset of the stack only'),
    ),
    (
      Text('chart.stacked: true'),
      DocText('`stacked: StackMode.on` on both axes'),
    ),
    (
      Text('plotOptions.bar.distributed: true'),
      DocText('`backgroundColor: .indexed([...])`'),
    ),
    (
      Text('plotOptions.bar.colors.ranges'),
      DocText('`.indexed` colors that the code picks from the values'),
    ),
    (
      Text('fill.opacity, stroke: {width, colors}'),
      DocText('the alpha of `backgroundColor`, `borderWidth`, `borderColor`'),
    ),
    (
      Text("xaxis: {position: 'top'}"),
      DocText('`position: .top` of the `CategoryAxis`'),
    ),
    (
      Text('xaxis.labels.style.colors'),
      DocText("a scriptable `'color'` of the ticks"),
    ),
    (Text('xaxis.labels.formatter'), DocText('`callback` of `AxisTicks`')),
    (
      Text('tooltip: {shared: false, intersect: true}'),
      DocText('`NearestInteractionMode` with `intersect: true`'),
    ),
    (
      Text('dataLabels, dataLabels.total'),
      DocText('an inline plugin that draws after the datasets'),
    ),
    (
      Text('xaxis.crosshairs'),
      DocText('an inline plugin that fills a band before the datasets'),
    ),
  ],
  demos: [
    apexJsDemo(
      'apexjs-column-basic',
      folder: 'column-charts',
      file: 'basic-column',
      title: const Text('Basic Column Chart'),
      notes: const [
        DocText(
          "`columnWidth: '55%'` is the part of the band that the group of "
          'bars takes: `categoryPercentage: 0.55` with `barPercentage: 1`.',
        ),
        DocText(
          "`borderRadiusApplication: 'end'` rounds the free end only. This "
          'is the default of Chart.js, so `borderRadius: 5` is enough.',
        ),
        DocText(
          "`stroke: {width: 2, colors: ['transparent']}` is a transparent "
          '`borderWidth: 2`. It leaves a gap of 2 px between two bars.',
        ),
        DocText(
          '`tooltip.y.formatter` is the `value` function of the tooltip '
          'label.',
        ),
      ],
      replica: (_) => const ApexJsColumnBasic(),
    ),
    apexJsDemo(
      'apexjs-column-labels',
      folder: 'column-charts',
      file: 'column-with-data-labels',
      title: const Text('Column with Data Labels'),
      notes: const [
        DocText(
          "`borderRadiusApplication: 'around'` (the default) rounds the "
          'four corners: `borderSkipped: BorderSkip.none`.',
        ),
        DocText(
          "`xaxis: {position: 'top'}` is `position: .top`. "
          '`yaxis.labels.show: false` hides the tick labels of the y axis, '
          'and its grid lines stay.',
        ),
        DocText(
          'The title with `offsetY: 330` sits under the plot: '
          '`TitleOptions(position: .bottom, align: .center)`.',
        ),
      ],
      replica: (_) => const ApexJsColumnLabels(),
    ),
    apexJsDemo(
      'apexjs-column-stacked',
      folder: 'column-charts',
      file: 'stacked-column',
      title: const Text('Stacked Columns'),
      notes: const [
        DocText(
          '`chart.stacked: true` is `stacked: StackMode.on` on both axes.',
        ),
        DocText(
          "`borderRadiusWhenStacked: 'last'` rounds the top of each stack. "
          'Chart.js rounds the end of each bar, thus only the last dataset '
          'gets `borderRadius: 10`.',
        ),
        DocText(
          'A bar chart of ApexCharts.js shows its values by default. The '
          'inline plugin writes each value and, for '
          '`dataLabels.total`, the sum over each stack.',
        ),
        DocText(
          "`xaxis: {type: 'datetime'}` with six days gives the labels "
          "\"Jan '11\", \"02 Jan\" and so on. The replica gives these labels "
          'to a `CategoryAxis`.',
        ),
      ],
      replica: (_) => const ApexJsColumnStacked(),
    ),
    apexJsDemo(
      'apexjs-column-negative',
      folder: 'column-charts',
      file: 'column-with-negative',
      title: const Text('Column with Negative Values'),
      notes: const [
        DocText(
          '`plotOptions.bar.colors.ranges` picks a color from the value. '
          'The replica computes one color for each value and gives the List '
          'to `backgroundColor: .indexed(...)`.',
        ),
        DocText(
          "`xaxis: {type: 'datetime'}` writes the year in January and "
          "\"Jul 'yy\" in July. A tick `callback` writes these labels, and "
          'gives the other columns a tick with no label.',
        ),
        DocText(
          '`yaxis.labels.formatter` is the tick `callback` of the y axis.',
        ),
      ],
      replica: (_) => const ApexJsColumnNegative(),
    ),
    apexJsDemo(
      'apexjs-column-distributed',
      folder: 'column-charts',
      file: 'distributed-columns',
      title: const Text('Distributed Columns'),
      notes: const [
        DocText(
          '`plotOptions.bar.distributed: true` gives each column the next '
          'color of `colors`: `backgroundColor: .indexed([...])`.',
        ),
        DocText(
          "A category `['John', 'Doe']` has two lines. Chart.js reads a "
          'label List in the same way.',
        ),
        DocText(
          '`xaxis.labels.style.colors` is a scriptable tick color that '
          'reads the index of the tick.',
        ),
      ],
      replica: (_) => const ApexJsColumnDistributed(),
    ),
    apexJsDemo(
      'apexjs-bar-basic',
      folder: 'bar-charts',
      file: 'basic-bar',
      title: const Text('Basic Bar Chart'),
      notes: const [
        DocText(
          '`plotOptions.bar.horizontal: true` is `indexAxis: .y`. The '
          'categories go on the y axis, and the values on the x axis.',
        ),
        DocText(
          'ApexCharts.js turns off the zoom of horizontal bars. The replica '
          'has no zoom.',
        ),
      ],
      replica: (_) => const ApexJsBarBasic(),
    ),
    apexJsDemo(
      'apexjs-bar-grouped',
      folder: 'bar-charts',
      file: 'grouped-bar',
      title: const Text('Grouped Bar Chart'),
      notes: const [
        DocText(
          "`stroke: {width: 1, colors: ['#fff']}` is a white `borderWidth: "
          '1` around each bar.',
        ),
        DocText(
          '`tooltip: {shared: true, intersect: false}` shows both series of '
          'the hovered year: `IndexInteractionMode` on the y axis.',
        ),
        DocText(
          "`dataLabels` with `position: 'top'` writes each value inside the "
          'end of its bar, in white.',
        ),
      ],
      replica: (_) => const ApexJsBarGrouped(),
    ),
    apexJsDemo(
      'apexjs-bar-stacked',
      folder: 'bar-charts',
      file: 'stacked-bar',
      title: const Text('Stacked Bar Chart'),
      notes: const [
        DocText(
          '`xaxis.labels.formatter` labels the value axis, which is the x '
          'axis of a horizontal bar chart. Its tick `callback` adds the K.',
        ),
        DocText(
          "`legend: {position: 'top', horizontalAlign: 'left'}` is "
          '`LegendOptions(position: .top, align: .start)`.',
        ),
        DocText(
          '`dataLabels.total` writes the sum of each stack after its end.',
        ),
      ],
      replica: (_) => const ApexJsBarStacked(),
    ),
    apexJsDemo(
      'apexjs-bar-pyramid',
      folder: 'bar-charts',
      file: 'bar-with-negative',
      title: const Text('Bar with Negative Values'),
      notes: const [
        DocText(
          'The pyramid stacks a positive and a negative series: each age '
          'group has one row, with the males on the right and the females '
          'on the left.',
        ),
        DocText(
          "`borderRadiusApplication: 'end'` rounds the end of each bar, on "
          'both sides of zero. Chart.js does the same by default.',
        ),
        DocText(
          'The labels and the tooltip show the value with no sign: '
          '`Math.abs` is `abs()` in the tick `callback` and in the tooltip '
          '`value` function.',
        ),
      ],
      replica: (_) => const ApexJsBarPyramid(),
    ),
  ],
);
