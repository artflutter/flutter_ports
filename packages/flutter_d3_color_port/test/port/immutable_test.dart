// Original code, not ported from d3-color: immutability and const tests.

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

void main() {
  test('all color classes support const construction and canonicalization', () {
    const r1 = Rgb(70, 130, 180);
    const r2 = Rgb(70, 130, 180);
    const h1 = Hsl(210, 0.5, 0.5);
    const h2 = Hsl(210, 0.5, 0.5);
    const l1 = Lab(50, 10, -20);
    const l2 = Lab(50, 10, -20);
    const c1 = Hcl(120, 30, 50);
    const c2 = Hcl(120, 30, 50);
    const ch1 = Cubehelix(300, 0.5, 0.5);
    const ch2 = Cubehelix(300, 0.5, 0.5);

    expect(identical(r1, r2), isTrue);
    expect(identical(h1, h2), isTrue);
    expect(identical(l1, l2), isTrue);
    expect(identical(c1, c2), isTrue);
    expect(identical(ch1, ch2), isTrue);
  });

  test(
    'same-space conversions and named lookups reuse immutable instances',
    () {
      const r = Rgb(70, 130, 180);
      const h = Hsl(210, 0.5, 0.5);
      const l = Lab(50, 10, -20);
      const c = Hcl(120, 30, 50);
      const ch = Cubehelix(300, 0.5, 0.5);

      expect(identical(Rgb.from(r), r), isTrue);
      expect(identical(Hsl.from(h), h), isTrue);
      expect(identical(Lab.from(l), l), isTrue);
      expect(identical(Hcl.from(c), c), isTrue);
      expect(identical(Cubehelix.from(ch), ch), isTrue);

      expect(identical(color('steelblue'), color('SteelBlue')), isTrue);
      expect(identical(color('transparent'), color('TRANSPARENT')), isTrue);
    },
  );

  test('null conversions return shared const NaN colors', () {
    expect(identical(rgbConvert(null), rgbConvert(null)), isTrue);
    expect(identical(hslConvert(null), hslConvert(null)), isTrue);
    expect(identical(labConvert(null), labConvert(null)), isTrue);
    expect(identical(hclConvert(null), hclConvert(null)), isTrue);
    expect(identical(cubehelixConvert(null), cubehelixConvert(null)), isTrue);
  });

  test('copyWith derives new immutable instances in every color space', () {
    expect(const Rgb(1, 2, 3).copyWith(g: 20, opacity: 0.5).g, 20);
    expect(const Hsl(10, 0.2, 0.3).copyWith(s: 0.8).s, 0.8);
    expect(const Lab(50, 10, -20).copyWith(a: 5).a, 5);
    expect(const Hcl(120, 30, 50).copyWith(c: 40).c, 40);
    expect(const Cubehelix(300, 0.5, 0.5).copyWith(l: 0.7).l, 0.7);
  });
}
