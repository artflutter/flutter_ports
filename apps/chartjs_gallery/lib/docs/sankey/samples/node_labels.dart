// Ported from chartjs-chart-sankey v0.19.1 src/content/docs/samples/node-labels.md (MIT, Jukka Kurkela).

import 'dart:ui' show Color, FontWeight;

import 'package:chartjs_gallery/docs/sankey/scripts/utils.dart';
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show SankeyLabelPosition, SankeyNode;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' show ChartPaint;

/// The sample `Node Labels` of
/// `src/content/docs/samples/node-labels.md:8-52`.
Map<String, Object?> sankeyNodeLabelsSample() {
  final utils = SankeyDocsColors();
  // <block:data:1>
  final data = <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Node labels',
        'data': <Object?>[
          <String, Object?>{'from': 'Solar', 'to': 'Grid', 'flow': 12},
          <String, Object?>{'from': 'Wind', 'to': 'Grid', 'flow': 18},
          <String, Object?>{'from': 'Grid', 'to': 'Homes', 'flow': 17},
          <String, Object?>{'from': 'Grid', 'to': 'Industry', 'flow': 13},
        ],
        'colorFrom': (Object? context) =>
            utils.getColor(sankeyDataItemOf(context)['from']! as String),
        'colorTo': (Object? context) =>
            utils.getColor(sankeyDataItemOf(context)['to']! as String),
        'nodeLabels': <String, Object?>{
          'position': <String, Object?>{
            'Grid': SankeyLabelPosition.center,
            'Homes': SankeyLabelPosition.left,
            'Industry': SankeyLabelPosition.left,
          },
          'color': (SankeyNode node) => node.key == 'Grid'
              ? const ChartPaint.solid(Color(0xFFFFFFFF))
              : const ChartPaint.solid(Color(0xFF222222)),
          'backgroundColor': <String, Object?>{
            'Grid': const ChartPaint.solid(Color(0xFF333333)),
          },
          'borderRadius': 4,
          'padding': 5,
          'font': const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        },
      },
    ],
  };
  // </block:data>

  // <block:config:0>
  final config = <String, Object?>{'type': 'sankey', 'data': data};
  // </block:config>

  return config;
}
