// Original code, not ported from d3-path: package example.

// Example prints SVG path strings.
// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:flutter_d3_path_port/d3_path.dart';

void draw(CanvasPath context) {
  context
    ..moveTo(0, 0)
    ..lineTo(100, 0)
    ..arc(100, 50, 50, -math.pi / 2, math.pi / 2)
    ..closePath();
}

void main() {
  final svg = path();
  draw(svg);
  print('SVG path: $svg');

  final rounded = pathRound(2)..moveTo(math.pi, math.e);
  print('Rounded:  $rounded');
}
