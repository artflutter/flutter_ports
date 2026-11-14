// Ported from d3-color v3.1.0 test/cubehelix-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

void main() {
  test('cubehelix(…) returns an instance of cubehelix and color', () {
    final c = Cubehelix.parse('steelblue');
    expect(c, isA<Cubehelix>());
    expect(c, isA<Color>());
  });
}
