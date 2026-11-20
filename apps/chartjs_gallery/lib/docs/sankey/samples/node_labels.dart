// Ported from chartjs-chart-sankey v0.19.1 src/content/docs/samples/node-labels.md (MIT, Jukka Kurkela).

import 'dart:ui' show Color, FontWeight;

import 'package:chartjs_gallery/docs/sankey/scripts/utils.dart';
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The sample `Node Labels` of
/// `src/content/docs/samples/node-labels.md:8-52`.
ChartConfig sankeyNodeLabelsSample() {
  final utils = SankeyDocsColors();
  // <block:data:1>
  final datasets = [
    SankeyDataset(
      label: 'Node labels',
      data: const [
        SankeyDataPoint(from: 'Solar', to: 'Grid', flow: 12),
        SankeyDataPoint(from: 'Wind', to: 'Grid', flow: 18),
        SankeyDataPoint(from: 'Grid', to: 'Homes', flow: 17),
        SankeyDataPoint(from: 'Grid', to: 'Industry', flow: 13),
      ],
      colorFrom: .byNode(utils.getColor),
      colorTo: .byNode(utils.getColor),
      nodeLabels: SankeyNodeLabels(
        position: const .byKey({
          'Grid': SankeyLabelPosition.center,
          'Homes': SankeyLabelPosition.left,
          'Industry': SankeyLabelPosition.left,
        }),
        color: .byNode(
          (node) => node.key == 'Grid'
              ? const .solid(Color(0xFFFFFFFF))
              : const .solid(Color(0xFF222222)),
        ),
        backgroundColor: const .byKey({
          'Grid': ChartPaint.solid(Color(0xFF333333)),
        }),
        borderRadius: 4,
        padding: 5,
        font: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    ),
  ];
  // </block:data>

  // <block:config:0>
  final config = ChartConfig(datasets: datasets);
  // </block:config>

  return config;
}
