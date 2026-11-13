// Original code, not ported from chartjs-chart-sankey: the observation of a fixture chart.
// The header text is longer than 80 columns and has no URI.
// ignore_for_file: lines_longer_than_80_chars

/// The observation of a sankey fixture chart (row
/// `harness-fixture-observations` of `doc/differences.md`).
///
/// Upstream compares each fixture with a PNG image. The port compares no
/// image (Chart.js ADR 0034, section 4). `index.dart` records one
/// observation of each fixture chart after its `run` hook and compares it
/// with the data of `tool/reference/fixtures_reference.mjs`
/// (`fixtures_reference.dart`): the same observation of the pinned sources
/// in Node.js.
///
/// This file is not a test entry. Only VM test files import it.
library;

import 'dart:ui' show Color;

import 'package:chartjs_test_utils/pure.dart' show RecordingContext;
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show Flow, SankeyController;
import 'package:flutter_chartjs_port/chartjs.dart'
    show Chart, LinearChartGradient;

/// The style [style] of a recorded `setFillStyle` or `setStrokeStyle`: a
/// color as `#rrggbbaa`, the gradient of a flow as `['linearGradient', x0,
/// y0, x1, y1, [offset, color], ...]`, or null for another style. The mock
/// context records the [Color] of a solid paint, and any other paint as it
/// is. A gradient without stops has its colors at equal distances.
Object? _hex(Object? style) {
  if (style is LinearChartGradient) {
    final LinearChartGradient(:from, :to, :colors, :stops) = style;
    return <Object?>[
      'linearGradient',
      from.dx,
      from.dy,
      to.dx,
      to.dy,
      for (var i = 0; i < colors.length; i++)
        <Object?>[
          stops?[i] ?? (colors.length == 1 ? 0.0 : i / (colors.length - 1)),
          _hex(colors[i]),
        ],
    ];
  }
  if (style is! Color) return null;
  String byte(double value) =>
      (value * 255).round().toRadixString(16).padLeft(2, '0');
  return '#${byte(style.r)}${byte(style.g)}${byte(style.b)}${byte(style.a)}';
}

/// The rectangle, text and fill calls of one `chart.draw()`: `drawCalls` of
/// `tool/reference/fixtures_reference.mjs`.
///
/// The function puts a recording context in place of `chart.ctx`, draws
/// once and puts back the context of the chart. The controller and the
/// flows draw on `chart.ctx` (controller.ts:487, :540 and :588). It follows
/// `save` and `restore` for the fill style, the stroke style and the text
/// align, as the generator does.
List<Object?> drawCalls(Chart chart) {
  final target = chart.ctx!;
  final recording = RecordingContext(target);
  chart.ctx = recording;
  try {
    chart.draw();
  } finally {
    chart.ctx = target;
  }

  // A canvas starts with black styles and the text align `start`.
  const black = Color(0xFF000000);
  var state = (
    fill: black as Object?,
    stroke: black as Object?,
    align: 'start',
  );
  final stack = <({Object? fill, Object? stroke, String align})>[];
  final draw = <Object?>[];
  for (final call in recording.getCalls()) {
    final args = call['args']! as List<Object?>;
    switch (call['name']) {
      case 'save':
        stack.add(state);
      case 'restore':
        if (stack.isNotEmpty) state = stack.removeLast();
      case 'setFillStyle':
        state = (fill: args[0], stroke: state.stroke, align: state.align);
      case 'setStrokeStyle':
        state = (fill: state.fill, stroke: args[0], align: state.align);
      case 'setTextAlign':
        state = (
          fill: state.fill,
          stroke: state.stroke,
          align: args[0]! as String,
        );
      case 'fillRect':
        draw.add(<Object?>['fillRect', ...args.take(4), _hex(state.fill)]);
      case 'strokeRect':
        draw.add(<Object?>['strokeRect', ...args.take(4), _hex(state.stroke)]);
      case 'fillText':
        draw.add(<Object?>[
          'fillText',
          ...args.take(3),
          state.align,
          _hex(state.fill),
        ]);
      case 'fill':
        draw.add(<Object?>['fill', _hex(state.fill)]);
    }
  }
  return draw;
}

/// The observation of [chart]: the keys of `observe` of
/// `tool/reference/fixtures_reference.mjs`.
///
/// - `chartArea`: `[left, top, right, bottom]`;
/// - `width` and `height`: the size of the chart;
/// - `nodes`: `[key, x, y, in, out, size]` for each node of the controller
///   of dataset 0, in the order of its node Map;
/// - `flows`: `[x, y, x2, y2, height, width]` for each flow of dataset 0;
/// - `draw`: [drawCalls].
Map<String, Object?> observe(Chart chart) {
  final area = chart.chartArea!;
  final meta = chart.getDatasetMeta(0);
  final controller = meta.controller! as SankeyController;
  return <String, Object?>{
    'chartArea': <Object?>[area.left, area.top, area.right, area.bottom],
    'width': chart.width,
    'height': chart.height,
    'nodes': <Object?>[
      for (final node in controller.nodes.values)
        <Object?>[
          node.key,
          node.x,
          node.y,
          node.inFlow,
          node.outFlow,
          node.size,
        ],
    ],
    'flows': <Object?>[
      for (final flow in meta.data.cast<Flow>())
        <Object?>[flow.x, flow.y, flow.x2, flow.y2, flow.height, flow.width],
    ],
    'draw': drawCalls(chart),
  };
}
