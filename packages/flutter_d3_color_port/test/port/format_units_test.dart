// Original code, not ported from d3-color: the twin of the format buffer.

/// The twin test of the row `adapt-color-format-units`: `formatHex`,
/// `formatHex8`, `formatRgb`, `formatHsl` and `toString` write the code
/// units of the text into one buffer (on the VM and in WebAssembly) or join
/// the strings with tables (in JavaScript, and `formatRgb` in WebAssembly),
/// and give the text of the plain translations of color.js on a large set
/// of generated colors.
library;

import 'dart:math' as math;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

// The plain translations of color.js, as the port had them before the rows
// of the format path.

/// color.js:288 `clampa(opacity)`.
double _clampa(double opacity) =>
    opacity.isNaN ? 1 : math.max(0, math.min(1, opacity));

/// color.js:292 `clampi(value)`.
int _clampi(double value) {
  final v = value.roundToDouble();
  return v > 0 ? (v < 255 ? v.toInt() : 255) : 0;
}

/// color.js:296 `hex(value)`.
String _hex(double value) {
  final v = _clampi(value);
  return (v < 16 ? '0' : '') + v.toRadixString(16);
}

/// The text of a number in a template literal of color.js.
String _numberText(double x) =>
    x == x.truncateToDouble() ? x.toInt().toString() : x.toString();

/// color.js:381 `clamph(value)`.
double _clamph(double value) {
  final v = (value.isNaN || value == 0 ? 0.0 : value).remainder(360);
  return v < 0 ? v + 360 : v;
}

/// color.js:386 `clampt(value)`.
double _clampt(double value) =>
    math.max(0, math.min(1, value.isNaN ? 0 : value));

/// color.js:275 `rgb_formatHex`.
String _formatHex(Rgb c) => '#${_hex(c.r)}${_hex(c.g)}${_hex(c.b)}';

/// color.js:279 `rgb_formatHex8`.
String _formatHex8(Rgb c) =>
    '#${_hex(c.r)}${_hex(c.g)}${_hex(c.b)}'
    '${_hex((c.opacity.isNaN ? 1 : c.opacity) * 255)}';

/// color.js:283 `rgb_formatRgb`.
String _formatRgb(Rgb c) {
  final a = _clampa(c.opacity);
  return '${a == 1 ? 'rgb(' : 'rgba('}${_clampi(c.r)}, ${_clampi(c.g)}, '
      '${_clampi(c.b)}${a == 1 ? ')' : ', ${_numberText(a)})'}';
}

/// color.js:375 `formatHsl()`.
String _formatHsl(Hsl c) {
  final a = _clampa(c.opacity);
  return '${a == 1 ? 'hsl(' : 'hsla('}${_numberText(_clamph(c.h))}, '
      '${_numberText(_clampt(c.s) * 100)}%, ${_numberText(_clampt(c.l) * 100)}%'
      '${a == 1 ? ')' : ', ${_numberText(a)})'}';
}

/// An [Rgb] whose `r` formats other colors at each read: the formats read
/// each channel before they write into their buffer.
final class _NestedRgb() extends Rgb {
  /// The color `rgb(12.5, 34, 56, 0.25)` with the nested formats.
  this : super(12.5, 34, 56, 0.25);

  @override
  double get r {
    Rgb(200, 100, 50, 0.5).formatRgb();
    Rgb(1, 2, 3).formatHex8();
    Hsl(120.25, 0.123456789, 0.5, 0.75).formatHsl();
    return 12.5;
  }
}

/// The edge values of a channel.
const List<double> _edges = [
  double.nan,
  0,
  -0.0,
  double.infinity,
  double.negativeInfinity,
  double.maxFinite,
  -double.maxFinite,
  double.minPositive,
  1e-300,
  0.49999999999999994,
  0.5,
  15.5,
  16,
  254.49999999999997,
  254.5,
  255,
  255.5,
  -0.5,
  -0.49999999999999994,
  9007199254740992,
  1e21,
];

/// The edge values of an opacity, a saturation and a lightness.
const List<double> _unitEdges = [
  double.nan,
  0,
  -0.0,
  1,
  0.99999999999999989,
  1.0000000000000002,
  double.infinity,
  double.negativeInfinity,
  double.minPositive,
  1e-9,
  1e-300,
  0.005,
  0.5,
  -0.25,
  1.5,
];

/// A channel of an RGB color: an edge, a random value in [-20, 280], a
/// value k / 100 or a whole number.
double _channel(math.Random random) => switch (random.nextInt(8)) {
  0 => _edges[random.nextInt(_edges.length)],
  1 || 2 => random.nextDouble() * 300 - 20,
  3 || 4 => random.nextInt(25600) / 100,
  5 => random.nextInt(256).toDouble(),
  6 => random.nextInt(512) / 2,
  _ => random.nextDouble() * 255,
};

/// An opacity, a saturation or a lightness.
double _unit(math.Random random) => switch (random.nextInt(8)) {
  0 => _unitEdges[random.nextInt(_unitEdges.length)],
  1 => 1,
  2 => random.nextInt(100) / 100,
  3 => random.nextInt(1000) / 1000,
  4 => random.nextDouble() * 1.4 - 0.2,
  5 => math.pow(10, -random.nextInt(12) - random.nextDouble()).toDouble(),
  _ => random.nextDouble(),
};

/// A hue.
double _hue(math.Random random) => switch (random.nextInt(8)) {
  0 => _edges[random.nextInt(_edges.length)],
  1 => random.nextInt(36000) / 100,
  2 => random.nextInt(8) * 360.0,
  3 => random.nextDouble() * 2000 - 1000,
  4 => random.nextInt(361).toDouble(),
  5 => -random.nextInt(36000) / 100,
  _ => random.nextDouble() * 360,
};

void main() {
  test('the RGB formats give the texts of the plain translations', () {
    final random = math.Random(3);
    final mismatches = <String>[];
    for (var i = 0; i < 30000; i++) {
      final c = Rgb(
        _channel(random),
        _channel(random),
        _channel(random),
        _unit(random),
      );
      void check(String name, String actual, String expected) {
        if (actual != expected) {
          mismatches.add(
            '${c.r}, ${c.g}, ${c.b}, ${c.opacity} $name: $actual, $expected',
          );
        }
      }

      check('formatHex', c.formatHex(), _formatHex(c));
      check('formatHex8', c.formatHex8(), _formatHex8(c));
      check('formatRgb', c.formatRgb(), _formatRgb(c));
      check('toString', c.toString(), _formatRgb(c));
    }
    expect(mismatches, isEmpty);
  });

  test('formatHsl gives the text of the plain translation', () {
    final random = math.Random(5);
    final mismatches = <String>[];
    for (var i = 0; i < 30000; i++) {
      final c = Hsl(_hue(random), _unit(random), _unit(random), _unit(random));
      final actual = c.formatHsl();
      final expected = _formatHsl(c);
      if (actual != expected) {
        mismatches.add(
          '${c.h}, ${c.s}, ${c.l}, ${c.opacity}: $actual, $expected',
        );
      }
    }
    expect(mismatches, isEmpty);
  });

  test('the formats of other spaces go through the same path', () {
    final random = math.Random(9);
    final mismatches = <String>[];
    for (var i = 0; i < 3000; i++) {
      final colors = <Color>[
        Lab(
          random.nextDouble() * 100,
          random.nextDouble() * 160 - 80,
          random.nextDouble() * 160 - 80,
          _unit(random),
        ),
        Hcl(
          random.nextDouble() * 360,
          random.nextDouble() * 100,
          random.nextDouble() * 100,
        ),
        Cubehelix(_hue(random), random.nextDouble(), random.nextDouble()),
      ];
      for (final c in colors) {
        final rgb = c.rgb();
        if (c.toString() != _formatRgb(rgb) ||
            c.formatHex() != _formatHex(rgb) ||
            c.formatHsl() != _formatHsl(Hsl.from(c))) {
          mismatches.add('$c');
        }
      }
    }
    expect(mismatches, isEmpty);
  });

  test('a channel read that formats other colors keeps the text', () {
    final c = _NestedRgb();
    expect(c.formatRgb(), 'rgba(13, 34, 56, 0.25)');
    expect(c.formatHex(), '#0d2238');
    expect(c.formatHex8(), '#0d223840');
    expect(c.formatHsl(), _formatHsl(Hsl.from(c)));
  });
}
