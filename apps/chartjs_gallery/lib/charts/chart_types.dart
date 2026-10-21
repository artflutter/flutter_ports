// Original code, not ported from Chart.js: the chart types of the gallery.

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The gallery imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:chartjs_gallery/docs/charts/bar.dart';
import 'package:chartjs_gallery/docs/charts/bubble.dart';
import 'package:chartjs_gallery/docs/charts/doughnut.dart';
import 'package:chartjs_gallery/docs/charts/line.dart';
import 'package:chartjs_gallery/docs/charts/mixed.dart';
import 'package:chartjs_gallery/docs/charts/polar.dart';
import 'package:chartjs_gallery/docs/charts/radar.dart';
import 'package:chartjs_gallery/docs/charts/scatter.dart';
import 'package:chartjs_gallery/docs/samples/area/line_boundaries.dart';
import 'package:flutter_chartjs/src/types/basic.dart';

/// One variant of a chart type page: a `chart-editor` block of the docs.
///
/// - `key`: the last part of the key of the variant segment,
///   `type.<stem>.variant.<key>`.
/// - `text`: the short text of the segment.
/// - `source`: the docs file and the lines of the block at the pin.
/// - `config`: makes a new chart config for each call.
typedef ChartTypeVariant = ({
  String key,
  String text,
  String source,
  AnyObject Function() config,
});

/// One entry of the home list: the page of `docs/charts/<stem>.md`.
/// `note` tells what the page lacks until a later phase, or is Dart `null`
/// when the page shows the full chart.
typedef ChartTypeEntry = ({
  String stem,
  String title,
  List<ChartTypeVariant> variants,
  String? note,
});

/// The chart types of the docs, in the order of the docs (Chart.js ADR
/// 0031, sections 1 and 2).
final List<ChartTypeEntry> galleryChartTypes = [
  (
    stem: 'area',
    title: 'Area',
    variants: [
      (
        key: 'origin',
        text: 'origin',
        source: 'docs/samples/area/line-boundaries.md:3-120',
        config: areaOriginConfig,
      ),
    ],
    note: 'Line only: the fill needs plugin.filler (phase 8)',
  ),
  (
    stem: 'bar',
    title: 'Bar',
    variants: [
      (
        key: 'vertical',
        text: 'vertical',
        source: 'docs/charts/bar.md:5-54',
        config: barVerticalConfig,
      ),
      (
        key: 'horizontal',
        text: 'horizontal',
        source: 'docs/charts/bar.md:304-351',
        config: barHorizontalConfig,
      ),
    ],
    note: null,
  ),
  (
    stem: 'bubble',
    title: 'Bubble',
    variants: [
      (
        key: 'bubble',
        text: 'bubble',
        source: 'docs/charts/bubble.md:5-36',
        config: bubbleConfig,
      ),
    ],
    note: null,
  ),
  (
    stem: 'doughnut',
    title: 'Doughnut and Pie',
    variants: [
      (
        key: 'doughnut',
        text: 'doughnut',
        source: 'docs/charts/doughnut.md:15-47',
        config: doughnutConfig,
      ),
      (
        key: 'pie',
        text: 'pie',
        source: 'docs/charts/doughnut.md:53-85',
        config: pieConfig,
      ),
    ],
    note: null,
  ),
  (
    stem: 'line',
    title: 'Line',
    variants: [
      (
        key: 'line',
        text: 'line',
        source: 'docs/charts/line.md:5-31',
        config: lineConfig,
      ),
      (
        key: 'vertical',
        text: 'vertical',
        source: 'docs/charts/line.md:233-285',
        config: lineVerticalConfig,
      ),
    ],
    note: null,
  ),
  (
    stem: 'mixed',
    title: 'Mixed',
    variants: [
      (
        key: 'mixed',
        text: 'mixed',
        source: 'docs/charts/mixed.md:27-70',
        config: mixedConfig,
      ),
    ],
    note: null,
  ),
  (
    stem: 'polar',
    title: 'Polar Area',
    variants: [
      (
        key: 'polar',
        text: 'polar',
        source: 'docs/charts/polar.md:7-43',
        config: polarAreaConfig,
      ),
    ],
    note: null,
  ),
  (
    stem: 'radar',
    title: 'Radar',
    variants: [
      (
        key: 'radar',
        text: 'radar',
        source: 'docs/charts/radar.md:7-61',
        config: radarConfig,
      ),
    ],
    note: null,
  ),
  (
    stem: 'scatter',
    title: 'Scatter',
    variants: [
      (
        key: 'scatter',
        text: 'scatter',
        source: 'docs/charts/scatter.md:5-47',
        config: scatterConfig,
      ),
    ],
    note: null,
  ),
];
