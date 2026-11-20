// Ported from chartjs-chart-sankey v0.19.1 src/content/docs/samples/flow-colors.md (MIT, Jukka Kurkela).

import 'dart:ui' show Color;

import 'package:chartjs_gallery/docs/sankey/scripts/utils.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The sample `Flow Colors` of
/// `src/content/docs/samples/flow-colors.md:8-43`.
ChartConfig sankeyFlowColorsSample() {
  final utils = SankeyDocsColors();
  // <block:data:1>
  final datasets = [
    SankeyDataset(
      label: 'Flow colors',
      data: const [
        SankeyDataPoint(from: 'Direct', to: 'Converted', flow: 16),
        SankeyDataPoint(from: 'Referral', to: 'Converted', flow: 9),
        SankeyDataPoint(from: 'Direct', to: 'Dropped', flow: 5),
        SankeyDataPoint(from: 'Referral', to: 'Dropped', flow: 7),
      ],
      colorFrom: .byNode(utils.getColor),
      colorTo: .byNode(utils.getColor),
      flowColor: .byFlow(
        (flow) => flow.to == 'Converted'
            ? const .solid(Color.fromRGBO(46, 160, 67, 0.55))
            : const .solid(Color.fromRGBO(218, 54, 51, 0.55)),
      ),
      hoverFlowColor: .byFlow(
        (flow) => flow.to == 'Converted'
            ? const .solid(Color.fromRGBO(46, 160, 67, 1))
            : const .solid(Color.fromRGBO(218, 54, 51, 1)),
      ),
    ),
  ];
  // </block:data>

  // <block:config:0>
  final config = ChartConfig(
    type: const ChartKind(SankeyController.id),
    datasets: datasets,
  );
  // </block:config>

  return config;
}
