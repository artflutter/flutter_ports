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
import 'package:flutter_chartjs_port/src/types/basic.dart';

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
///
/// Each page shows the full chart of its docs blocks, with the plugins of
/// `registerables`. Phase 8 removes the field `note`, the static note of a
/// partial type (Chart.js ADR 0031, section 2.1).
typedef ChartTypeEntry = ({
  String stem,
  String title,
  List<ChartTypeVariant> variants,
});

/// The chart types of the docs, in the order of the docs (Chart.js ADR
/// 0031, sections 1 and 2).
///
/// The Area page has the fill actions of
/// `docs/samples/area/line-boundaries.md:39-74` as its variants (Chart.js
/// ADR 0031, Open "The Area `fill` control"). The first variant is
/// `origin`, the state of the page of phase 7 (section 1.2): the page opens
/// with the fill. The other variants follow in the order of the actions,
/// and `false`, the first state of the sample (`:29`), is last.
final List<ChartTypeEntry> galleryChartTypes = [
  (
    stem: 'area',
    title: 'Area',
    variants: [
      (
        key: 'origin',
        text: 'origin',
        source: 'docs/samples/area/line-boundaries.md:3-120 and :48-56',
        config: areaOriginConfig,
      ),
      (
        key: 'start',
        text: 'start',
        source: 'docs/samples/area/line-boundaries.md:3-120 and :57-65',
        config: areaStartConfig,
      ),
      (
        key: 'end',
        text: 'end',
        source: 'docs/samples/area/line-boundaries.md:3-120 and :66-74',
        config: areaEndConfig,
      ),
      (
        key: 'false',
        text: 'false',
        source: 'docs/samples/area/line-boundaries.md:3-120 and :39-47',
        config: areaFalseConfig,
      ),
    ],
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
  ),
];
