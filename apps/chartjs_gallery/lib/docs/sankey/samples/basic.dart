// Ported from chartjs-chart-sankey v0.19.1 src/content/docs/samples/basic.md (MIT, Jukka Kurkela).

import 'package:chartjs_gallery/docs/sankey/scripts/utils.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The sample `Basic` of `src/content/docs/samples/basic.md:6-36`.
ChartConfig sankeyBasicSample() {
  final utils = SankeyDocsColors();
  // <block:data:1>
  final datasets = [
    SankeyDataset(
      label: 'Basic sankey',
      colorFrom: .byNode(utils.getColor),
      colorTo: .byNode(utils.getColor),
      colorMode: .gradient,
      data: const [
        SankeyDataPoint(from: 'A', to: 'B', flow: 10),
        SankeyDataPoint(from: 'A', to: 'C', flow: 5),
        SankeyDataPoint(from: 'B', to: 'D', flow: 6),
        SankeyDataPoint(from: 'C', to: 'D', flow: 4),
        SankeyDataPoint(from: 'C', to: 'E', flow: 1),
      ],
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
