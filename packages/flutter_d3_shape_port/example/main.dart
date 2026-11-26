// Original code, not ported from d3-shape: package example.

// Example prints SVG path outputs.
// ignore_for_file: avoid_print

import 'package:flutter_d3_shape_port/d3_shape.dart';

void main() {
  // 1. Smooth monotone line.
  final pts = [(0.0, 40.0), (50.0, 10.0), (100.0, 60.0), (150.0, 20.0)];
  final curveGen = line<(double, double)>()
    ..x = ((p, _, _) => p.$1)
    ..y = ((p, _, _) => p.$2)
    ..curve = curveMonotoneX;
  print('Line: ${curveGen(pts)}');

  // 2. Donut chart via pie() + arc().
  final slices = (pie<double>()..padAngleConst(0.03))([30, 20, 15, 35]);
  final donut = arc<PieArc<double>>()
    ..innerRadiusConst(40)
    ..outerRadiusConst(100)
    ..cornerRadiusConst(8);
  for (final s in slices) {
    final (cx, cy) = donut.centroid(s);
    print(
      'Slice ${s.data} centroid=(${cx.toStringAsFixed(1)}, '
      '${cy.toStringAsFixed(1)}) d=${donut(s)}',
    );
  }

  // 3. Streamgraph stack.
  final rows = [
    {'a': 10.0, 'b': 25.0, 'c': 15.0},
    {'a': 20.0, 'b': 15.0, 'c': 30.0},
    {'a': 15.0, 'b': 30.0, 'c': 20.0},
  ];
  final stacked = (stack<Map<String, double>, String>()
    ..keysConst(['a', 'b', 'c'])
    ..order = stackOrderInsideOut
    ..offset = stackOffsetWiggle)(rows);
  print('Stacked series count: ${stacked.length}');
}
