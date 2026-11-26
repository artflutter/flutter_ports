// Original code, not ported from d3-color: the twin test of a faster form.

/// The twin test of the row `adapt-color-format-locals`: `Hsl.formatRgb()`
/// and `Hcl.formatRgb()` (and `toString()`) keep the RGB channels in locals
/// and write their text with no `Rgb` object. The test keeps the plain form
/// of color.js:181 `formatRgb()`, `this.rgb().formatRgb()`, with the plain
/// translation of color.js:283 `rgb_formatRgb`, and compares the texts on
/// colors of each kind: edges, NaN, -0, the infinities, random bits, and
/// colors whose channels fall next to a half, where one bit of a channel
/// changes the text.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

/// color.js:288 `clampa(opacity)`.
double _clampa(double opacity) => opacity.isNaN ? 1 : max(0, min(1, opacity));

/// color.js:292 `clampi(value)`.
int _clampi(double value) {
  final v = value.roundToDouble();
  return v > 0 ? (v < 255 ? v.toInt() : 255) : 0;
}

/// The text of a number in a template literal of color.js.
String _numberText(double x) =>
    x == x.truncateToDouble() ? x.toInt().toString() : x.toString();

/// color.js:283 `rgb_formatRgb`.
String _formatRgb(Rgb c) {
  final a = _clampa(c.opacity);
  return '${a == 1 ? 'rgb(' : 'rgba('}${_clampi(c.r)}, ${_clampi(c.g)}, '
      '${_clampi(c.b)}${a == 1 ? ')' : ', ${_numberText(a)})'}';
}

/// color.js:181 `formatRgb()` and color.js:182 `toString()`, the plain
/// form: `this.rgb().formatRgb()`.
String _plain(Color c) => _formatRgb(c.rgb());

/// A double of random bits: each sign, exponent and fraction.
double _randomBits(Random r, ByteData bytes) {
  bytes
    ..setUint32(0, r.nextInt(1 << 16) << 16 | r.nextInt(1 << 16))
    ..setUint32(4, r.nextInt(1 << 16) << 16 | r.nextInt(1 << 16));
  return bytes.getFloat64(0);
}

/// The special values of a channel.
const List<double> _specials = [
  double.nan,
  0,
  -0.0,
  double.infinity,
  double.negativeInfinity,
  double.maxFinite,
  -double.maxFinite,
  double.minPositive,
  1e-300,
  0.5,
  1,
  -1,
  360,
  -360,
  720,
  100,
  1e16,
];

/// An opacity: 1, k / 100, a random value or a special value.
double _opacity(Random r) => switch (r.nextInt(6)) {
  0 || 1 => 1,
  2 => r.nextInt(101) / 100,
  3 => r.nextDouble() * 1.4 - 0.2,
  4 => _specials[r.nextInt(_specials.length)],
  _ => r.nextDouble(),
};

/// Two colors of [make] with lightnesses [lo] and [hi] next to each other,
/// where the red channel crosses the half [target]: the red channel of the
/// first is below [target] and the one of the second is not. Thus the two
/// texts differ in the red channel, and one bit of that channel decides it.
/// Gives no color when the red channels at [lo] and [hi] do not span
/// [target].
List<T> _crossing<T extends Color>(
  T Function(double l) make,
  double lo,
  double hi,
  double target,
) {
  var below = lo;
  var above = hi;
  if (!(make(below).rgb().r < target) || !(make(above).rgb().r >= target)) {
    return [];
  }
  for (;;) {
    final mid = below + (above - below) / 2;
    if (mid <= below || mid >= above) break;
    if (make(mid).rgb().r < target) {
      below = mid;
    } else {
      above = mid;
    }
  }
  return [make(below), make(above)];
}

/// The [_crossing] of an HSL color of a random hue and saturation.
List<Hsl> _hslCrossing(Random r) {
  final h = r.nextDouble() * 360;
  final s = r.nextDouble();
  return _crossing((l) => Hsl(h, s, l), 0, 1, r.nextInt(255) + 0.5);
}

/// The [_crossing] of an HCL color of a random hue and chroma.
List<Hcl> _hclCrossing(Random r) {
  final h = r.nextDouble() * 360;
  final c = r.nextDouble() * 40;
  return _crossing((l) => Hcl(h, c, l), 0, 100, r.nextInt(255) + 0.5);
}

/// The HSL colors of the test.
List<Hsl> _hslColors() {
  final r = Random(20261115);
  final bytes = ByteData(8);
  double pick(double Function() random) => switch (r.nextInt(5)) {
    0 => _specials[r.nextInt(_specials.length)],
    1 => _randomBits(r, bytes),
    _ => random(),
  };
  return [
    for (var i = 0; i < 6000; i++)
      Hsl(
        pick(() => r.nextDouble() * 1000 - 500),
        pick(r.nextDouble),
        pick(() => r.nextDouble() * 1.2 - 0.1),
        _opacity(r),
      ),
    for (var i = 0; i < 2000; i++) ..._hslCrossing(r),
    for (var i = 0; i < 2000; i++)
      Hsl(
        r.nextInt(36000) / 100,
        r.nextInt(1000) / 1000,
        r.nextInt(1000) / 1000,
      ),
  ];
}

/// The HCL colors of the test.
List<Hcl> _hclColors() {
  final r = Random(1115);
  final bytes = ByteData(8);
  double pick(double Function() random) => switch (r.nextInt(5)) {
    0 => _specials[r.nextInt(_specials.length)],
    1 => _randomBits(r, bytes),
    _ => random(),
  };
  return [
    for (var i = 0; i < 6000; i++)
      Hcl(
        pick(() => r.nextDouble() * 1000 - 500),
        pick(() => r.nextDouble() * 150),
        pick(() => r.nextDouble() * 120 - 10),
        _opacity(r),
      ),
    for (var i = 0; i < 2000; i++) ..._hclCrossing(r),
    for (var i = 0; i < 2000; i++)
      Hcl(
        r.nextInt(36000) / 100,
        r.nextInt(10000) / 100,
        r.nextInt(10000) / 100,
      ),
  ];
}

/// The colors of [colors] whose `formatRgb()` or `toString()` differs from
/// the plain form, or from `rgb().formatRgb()`.
List<String> _mismatches(List<Color> colors) => [
  for (final c in colors)
    if (c.formatRgb() != _plain(c) ||
        c.toString() != _plain(c) ||
        c.formatRgb() != c.rgb().formatRgb())
      '$c: ${c.formatRgb()} != ${_plain(c)}',
];

void main() {
  test('Hsl.formatRgb() gives the text of rgb().formatRgb()', () {
    final colors = _hslColors();
    expect(colors.length, greaterThan(10000));
    expect(_mismatches(colors).take(20), isEmpty);
  });

  test('Hcl.formatRgb() gives the text of rgb().formatRgb()', () {
    final colors = _hclColors();
    expect(colors.length, greaterThan(10000));
    expect(_mismatches(colors).take(20), isEmpty);
  });

  test('the pairs of colors on each side of a half give two texts', () {
    // The texts of these colors depend on the last bit of the red channel.
    final r = Random(1);
    final pairs = [
      for (var i = 0; i < 200; i++) _hslCrossing(r),
      for (var i = 0; i < 200; i++) _hclCrossing(r),
    ].where((pair) => pair.isNotEmpty).toList();
    expect(pairs.length, greaterThan(300));
    for (final [below, above] in pairs) {
      expect(_clampi(below.rgb().r) + 1, _clampi(above.rgb().r));
      expect(below.formatRgb(), _plain(below));
      expect(above.formatRgb(), _plain(above));
    }
  });

  test('a subclass formats the result of its own rgb()', () {
    // Upstream formatRgb() is this.rgb().formatRgb(): an override of rgb()
    // decides the text.
    expect(_GrayHsl(120, 0.5, 0.5).toString(), 'rgb(7, 7, 7)');
    expect(_GrayHcl(120, 30, 50).toString(), 'rgb(7, 7, 7)');
  });
}

/// An [Hsl] whose rgb() gives a fixed gray.
final class _GrayHsl(super.h, super.s, super.l) extends Hsl {
  @override
  Rgb rgb() => const Rgb(7, 7, 7);
}

/// An [Hcl] whose rgb() gives a fixed gray.
final class _GrayHcl(super.h, super.c, super.l) extends Hcl {
  @override
  Rgb rgb() => const Rgb(7, 7, 7);
}
