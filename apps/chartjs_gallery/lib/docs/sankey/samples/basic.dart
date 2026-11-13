// Ported from chartjs-chart-sankey v0.19.1 src/content/docs/samples/basic.md (MIT, Jukka Kurkela).

import 'package:chartjs_gallery/docs/sankey/scripts/utils.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show SankeyColorMode;

/// The sample `Basic` of `src/content/docs/samples/basic.md:6-36`.
Map<String, Object?> sankeyBasicSample() {
  final utils = SankeyDocsColors();
  // <block:data:1>
  final data = <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Basic sankey',
        'colorFrom': (Object? context) =>
            utils.getColor(sankeyDataItemOf(context)['from']! as String),
        'colorTo': (Object? context) =>
            utils.getColor(sankeyDataItemOf(context)['to']! as String),
        'colorMode': SankeyColorMode.gradient,
        'data': <Object?>[
          <String, Object?>{'from': 'A', 'to': 'B', 'flow': 10},
          <String, Object?>{'from': 'A', 'to': 'C', 'flow': 5},
          <String, Object?>{'from': 'B', 'to': 'D', 'flow': 6},
          <String, Object?>{'from': 'C', 'to': 'D', 'flow': 4},
          <String, Object?>{'from': 'C', 'to': 'E', 'flow': 1},
        ],
      },
    ],
  };
  // </block:data>

  // <block:config:0>
  final config = <String, Object?>{'type': 'sankey', 'data': data};
  // </block:config>

  return config;
}
