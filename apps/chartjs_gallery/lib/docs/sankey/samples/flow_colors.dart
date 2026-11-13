// Ported from chartjs-chart-sankey v0.19.1 src/content/docs/samples/flow-colors.md (MIT, Jukka Kurkela).

import 'dart:ui' show Color;

import 'package:chartjs_gallery/docs/sankey/scripts/utils.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' show ChartPaint;

/// The sample `Flow Colors` of
/// `src/content/docs/samples/flow-colors.md:8-43`.
Map<String, Object?> sankeyFlowColorsSample() {
  final utils = SankeyDocsColors();
  // <block:data:1>
  final data = <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Flow colors',
        'data': <Object?>[
          <String, Object?>{'from': 'Direct', 'to': 'Converted', 'flow': 16},
          <String, Object?>{'from': 'Referral', 'to': 'Converted', 'flow': 9},
          <String, Object?>{'from': 'Direct', 'to': 'Dropped', 'flow': 5},
          <String, Object?>{'from': 'Referral', 'to': 'Dropped', 'flow': 7},
        ],
        'colorFrom': (Object? context) =>
            utils.getColor(sankeyDataItemOf(context)['from']! as String),
        'colorTo': (Object? context) =>
            utils.getColor(sankeyDataItemOf(context)['to']! as String),
        'flowColor': (Object? context) =>
            sankeyDataItemOf(context)['to'] == 'Converted'
            ? const ChartPaint.solid(Color.fromRGBO(46, 160, 67, 0.55))
            : const ChartPaint.solid(Color.fromRGBO(218, 54, 51, 0.55)),
        'hoverFlowColor': (Object? context) =>
            sankeyDataItemOf(context)['to'] == 'Converted'
            ? const ChartPaint.solid(Color.fromRGBO(46, 160, 67, 1))
            : const ChartPaint.solid(Color.fromRGBO(218, 54, 51, 1)),
      },
    ],
  };
  // </block:data>

  // <block:config:0>
  final config = <String, Object?>{'type': 'sankey', 'data': data};
  // </block:config>

  return config;
}
