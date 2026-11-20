// Ported from chartjs-chart-sankey v0.19.1 src/content/docs/samples/vertical.md (MIT, Jukka Kurkela).

import 'package:chartjs_gallery/docs/sankey/scripts/utils.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The sample `Vertical` of `src/content/docs/samples/vertical.md:8-38`.
ChartConfig sankeyVerticalSample() {
  final utils = SankeyDocsColors();
  // <block:data:1>
  final datasets = [
    SankeyDataset(
      label: 'Customer journey',
      orientation: .vertical,
      data: const [
        SankeyDataPoint(from: 'Visits', to: 'Product views', flow: 80),
        SankeyDataPoint(from: 'Visits', to: 'Exit', flow: 20),
        SankeyDataPoint(from: 'Product views', to: 'Cart', flow: 32),
        SankeyDataPoint(from: 'Product views', to: 'Exit', flow: 48),
        SankeyDataPoint(from: 'Cart', to: 'Purchase', flow: 18),
        SankeyDataPoint(from: 'Cart', to: 'Abandoned', flow: 14),
      ],
      colorFrom: .byNode(utils.getColor),
      colorTo: .byNode(utils.getColor),
      colorMode: .gradient,
    ),
  ];
  // </block:data>

  // <block:config:0>
  final config = ChartConfig(datasets: datasets);
  // </block:config>

  return config;
}
