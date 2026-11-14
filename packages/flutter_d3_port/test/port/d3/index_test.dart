// Original code, not ported from D3: tests of the bundle index.
import 'package:flutter_d3_port/d3.dart' as d3;
import 'package:test/test.dart';

void main() {
  test('the bundle exports the names of d3-color', () {
    final c = d3.color('steelblue')!;
    expect(c, isA<d3.Rgb>());
    expect(d3.Hcl.from(c).rgb().formatHex(), '#4682b4');
    expect(d3.gray(50).formatHex(), '#777777');
    expect(d3.lch(50, 0, 0).formatHex(), '#777777');
    expect(d3.Cubehelix.parse('white').formatHex(), '#ffffff');
    expect(d3.d3Version, '7.9.0');
  });
}
