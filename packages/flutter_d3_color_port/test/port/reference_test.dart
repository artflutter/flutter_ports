// Original code, not ported from d3-color: the port against Node.js data.

/// Compares the d3-color port with upstream d3-color v3.1.0 in Node.js
/// v24.22.1 on arm64, the reference engine of the repository (Chart.js ADR
/// 0146). The data comes from `tool/reference/d3_color_reference.mjs`.
///
/// Each test collects every difference of its part and fails with the whole
/// list. The comparisons:
///
/// - A channel of a path with only `+ - * /`, rounding, `%`, `min` and
///   `max` (the RGB and HSL paths, `clamp()`, the lightness steps of Lab and
///   HCL) compares exactly.
/// - A channel of a path with `pow`, `atan2`, `sin` or `cos` (Lab, HCL and
///   Cubehelix) compares within a relative 1e-12, or an absolute 1e-9 near
///   0: `dart:math` and V8 can differ in the last bit there (Chart.js ADR
///   0146 §3).
/// - The HSL channels and `formatHsl()` of a Lab, HCL or Cubehelix color
///   compare exactly when the port gives the RGB channels of Node.js
///   exactly, because the rest of the path has only `+ - * /`. Else they
///   compare the numbers of the text within the tolerance above.
/// - Each other string compares exactly.
/// - NaN equals NaN, and -0 equals +0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

import 'd3_color_reference.dart';

void main() {
  test('the data comes from the reference engine', () {
    expect(d3ColorReferenceNode, 'v24.22.1');
    expect(d3ColorReferenceArch, 'arm64');
  });

  group('a) CSS texts:', () {
    test('color(text) gives the class and the channels of Node.js', () {
      final mismatches = <String>[];
      for (final c in parseCases) {
        final label = 'color(${_quote(c.input)})';
        final actual = color(c.input);
        if (c.space == null || actual == null) {
          if (c.space != null || actual != null) {
            mismatches.add(
              '$label: expected ${_colorText(c.space, c.channels)}, '
              'actual ${_describe(actual)}',
            );
          }
          continue;
        }
        if (_space(actual) != c.space) {
          mismatches.add(
            '$label: expected ${_colorText(c.space, c.channels)}, '
            'actual ${_describe(actual)}',
          );
          continue;
        }
        _compare(mismatches, label, _channels(actual), c.channels, _same);
      }
      _expectNone(mismatches);
    });

    test('rgb(text) and hsl(text) give the channels of Node.js', () {
      final mismatches = <String>[];
      for (final c in parseCases) {
        final text = _quote(c.input);
        _compare(
          mismatches,
          'Rgb.parse($text)',
          _channels(Rgb.parse(c.input)),
          c.rgb,
          _same,
        );
        _compare(
          mismatches,
          'Hsl.parse($text)',
          _channels(Hsl.parse(c.input)),
          c.hsl,
          _same,
        );
      }
      _expectNone(mismatches);
    });

    test('the formats of color(text) are the texts of Node.js', () {
      final mismatches = <String>[];
      for (final c in parseCases) {
        final actual = color(c.input);
        // A null on one side is a difference of the test above.
        if (c.space == null || actual == null) continue;
        final label = 'color(${_quote(c.input)})';
        _compareFormats(mismatches, label, _formats(actual), c.formats);
        if (actual.displayable() != c.displayable) {
          mismatches.add(
            '$label.displayable(): expected ${c.displayable}, '
            'actual ${actual.displayable()}',
          );
        }
      }
      _expectNone(mismatches);
    });
  });

  group('b) numeric colors:', () {
    test('the conversions give the channels of Node.js', () {
      final mismatches = <String>[];
      for (final c in colorCases) {
        final source = _make(c.space, c.channels);
        final label = _colorText(c.space, c.channels);
        final exactRgb = c.space == 'rgb' || c.space == 'hsl';
        final rgb = Rgb.from(source);
        _compare(
          mismatches,
          'Rgb.from($label)',
          _channels(rgb),
          c.rgb,
          exactRgb ? _same : _near,
        );
        _compare(
          mismatches,
          'Hsl.from($label)',
          _channels(Hsl.from(source)),
          c.hsl,
          exactRgb || _sameList(_channels(rgb), c.rgb) ? _same : _near,
        );
        _compare(
          mismatches,
          'Lab.from($label)',
          _channels(Lab.from(source)),
          c.lab,
          c.space == 'lab' ? _same : _near,
        );
        _compare(
          mismatches,
          'Hcl.from($label)',
          _channels(Hcl.from(source)),
          c.hcl,
          c.space == 'hcl' ? _same : _near,
        );
        _compare(
          mismatches,
          'Cubehelix.from($label)',
          _channels(Cubehelix.from(source)),
          c.cubehelix,
          c.space == 'cubehelix' ? _same : _near,
        );
      }
      _expectNone(mismatches);
    });

    test('brighter and darker give the channels of Node.js', () {
      final mismatches = <String>[];
      for (final c in colorCases) {
        final source = _make(c.space, c.channels);
        final label = _colorText(c.space, c.channels);
        for (var i = 0; i < _ks.length; i++) {
          final k = _ks[i];
          final kText = k == null ? '' : _number(k);
          _compare(
            mismatches,
            '$label.brighter($kText)',
            _channels(source.brighter(k)),
            c.brighter[i],
            _same,
          );
          _compare(
            mismatches,
            '$label.darker($kText)',
            _channels(source.darker(k)),
            c.darker[i],
            _same,
          );
        }
      }
      _expectNone(mismatches);
    });

    test('clamp and displayable give the results of Node.js', () {
      final mismatches = <String>[];
      for (final c in colorCases) {
        final source = _make(c.space, c.channels);
        final label = _colorText(c.space, c.channels);
        final clamp = c.clamp;
        if (clamp != null) {
          final actual = switch (source) {
            final Rgb rgb => rgb.clamp(),
            final Hsl hsl => hsl.clamp(),
            _ => throw StateError('no clamp() for $label'),
          };
          _compare(
            mismatches,
            '$label.clamp()',
            _channels(actual),
            clamp,
            _same,
          );
        }
        if (source.displayable() != c.displayable) {
          mismatches.add(
            '$label.displayable(): expected ${c.displayable}, '
            'actual ${source.displayable()}',
          );
        }
      }
      _expectNone(mismatches);
    });

    test('the formats are the texts of Node.js', () {
      final mismatches = <String>[];
      for (final c in colorCases) {
        final source = _make(c.space, c.channels);
        final label = _colorText(c.space, c.channels);
        // The HSL text of a Lab, HCL or Cubehelix color is exact when the
        // RGB channels are exact: hslConvert has only + - * /.
        final exactHsl =
            c.space == 'rgb' ||
            c.space == 'hsl' ||
            _sameList(_channels(source.rgb()), c.rgb);
        _compareFormats(
          mismatches,
          label,
          _formats(source),
          c.formats,
          exactHsl: exactHsl,
        );
      }
      _expectNone(mismatches);
    });
  });

  group('c) number texts:', () {
    test('formatHsl prints a number as JavaScript String(x)', () {
      final mismatches = <String>[];
      for (final c in numberTextCases) {
        final actual = Hsl(c.h, 0.5, 0.5, c.opacity).formatHsl();
        if (actual != c.text) {
          final call = 'Hsl(${_number(c.h)}, 0.5, 0.5, ${_number(c.opacity)})';
          mismatches.add(
            '$call.formatHsl(): expected ${_quote(c.text)}, '
            'actual ${_quote(actual)} (String(h) ${c.hText}, '
            'String(opacity) ${c.opacityText})',
          );
        }
      }
      _expectNone(mismatches);
    });
  });
}

/// The k of `brighter(k)` and `darker(k)` in the data: none, 0.5, 1, 2 and
/// -1.5.
const List<double?> _ks = [null, 0.5, 1, 2, -1.5];

/// Fails with each line of [mismatches].
void _expectNone(List<String> mismatches) {
  if (mismatches.isEmpty) return;
  fail(
    '${mismatches.length} differences from Node.js:\n'
    '${mismatches.join('\n')}',
  );
}

/// The color of [space] with the channels [c] of the data.
Color _make(String space, List<double> c) => switch (space) {
  'rgb' => Rgb(c[0], c[1], c[2], c[3]),
  'hsl' => Hsl(c[0], c[1], c[2], c[3]),
  'lab' => Lab(c[0], c[1], c[2], c[3]),
  'hcl' => Hcl(c[0], c[1], c[2], c[3]),
  'cubehelix' => Cubehelix(c[0], c[1], c[2], c[3]),
  _ => throw ArgumentError.value(space, 'space'),
};

/// The space name of [c], as the generator writes it.
String _space(Color c) => switch (c) {
  Rgb() => 'rgb',
  Hsl() => 'hsl',
  Lab() => 'lab',
  Hcl() => 'hcl',
  Cubehelix() => 'cubehelix',
  _ => throw ArgumentError.value(c, 'c'),
};

/// The channels of [c] in its own space, in the order of the generator.
List<double> _channels(Color c) => switch (c) {
  Rgb(:final r, :final g, :final b) => [r, g, b, c.opacity],
  Hsl(:final h, :final s, :final l) => [h, s, l, c.opacity],
  Lab(:final l, :final a, :final b) => [l, a, b, c.opacity],
  Hcl(:final h, c: final chroma, :final l) => [h, chroma, l, c.opacity],
  Cubehelix(:final h, :final s, :final l) => [h, s, l, c.opacity],
  _ => throw ArgumentError.value(c, 'c'),
};

/// `formatHex()`, `formatHex8()`, `formatRgb()`, `formatHsl()` and
/// `toString()` of [c], in the order of the generator.
List<String> _formats(Color c) => [
  c.formatHex(),
  c.formatHex8(),
  c.formatRgb(),
  c.formatHsl(),
  c.toString(),
];

/// The names of the formats of [_formats].
const List<String> _formatNames = [
  'formatHex()',
  'formatHex8()',
  'formatRgb()',
  'formatHsl()',
  'toString()',
];

/// The index of `formatHsl()` in [_formats].
const int _formatHslIndex = 3;

/// Adds a line to [mismatches] for each format of [actual] that differs from
/// [expected]. With [exactHsl] false, `formatHsl()` compares its numbers by
/// [_near].
void _compareFormats(
  List<String> mismatches,
  String label,
  List<String> actual,
  List<String> expected, {
  bool exactHsl = true,
}) {
  for (var i = 0; i < _formatNames.length; i++) {
    final same = i == _formatHslIndex && !exactHsl
        ? _sameTextNear(actual[i], expected[i])
        : actual[i] == expected[i];
    if (!same) {
      mismatches.add(
        '$label.${_formatNames[i]}: expected ${_quote(expected[i])}, '
        'actual ${_quote(actual[i])}',
      );
    }
  }
}

/// Adds a line to [mismatches] when [actual] and [expected] differ by
/// [same].
void _compare(
  List<String> mismatches,
  String label,
  List<double> actual,
  List<double> expected,
  bool Function(double actual, double expected) same,
) {
  var equal = actual.length == expected.length;
  for (var i = 0; equal && i < actual.length; i++) {
    equal = same(actual[i], expected[i]);
  }
  if (!equal) {
    mismatches.add(
      '$label: expected ${_numbers(expected)}, actual ${_numbers(actual)}',
    );
  }
}

/// Whether the two lists hold the same channels by [_same].
bool _sameList(List<double> actual, List<double> expected) {
  if (actual.length != expected.length) return false;
  for (var i = 0; i < actual.length; i++) {
    if (!_same(actual[i], expected[i])) return false;
  }
  return true;
}

/// The exact test: NaN equals NaN, and -0 equals +0.
bool _same(double actual, double expected) =>
    expected.isNaN ? actual.isNaN : actual == expected;

/// The test of a `pow`, `atan2`, `sin` or `cos` path: a relative 1e-12, or
/// an absolute 1e-9 near 0. NaN and the infinities compare exactly.
bool _near(double actual, double expected) {
  if (expected.isNaN) return actual.isNaN;
  if (expected.isInfinite || actual.isInfinite) return actual == expected;
  return (actual - expected).abs() <= math.max(1e-12 * expected.abs(), 1e-9);
}

/// A number of a CSS text of d3-color.
final RegExp _cssNumber = RegExp(r'NaN|-?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?');

/// Whether the two CSS texts are equal, with their numbers compared by
/// [_near]. `formatHsl()` of a Lab, HCL or Cubehelix color prints numbers
/// of `pow`, `atan2`, `sin` and `cos`, whose last digit can differ.
bool _sameTextNear(String actual, String expected) {
  if (actual == expected) return true;
  if (actual.replaceAll(_cssNumber, '#') !=
      expected.replaceAll(_cssNumber, '#')) {
    return false;
  }
  final a = _cssNumber.allMatches(actual).toList();
  final e = _cssNumber.allMatches(expected).toList();
  for (var i = 0; i < a.length; i++) {
    if (!_near(double.parse(a[i][0]!), double.parse(e[i][0]!))) return false;
  }
  return true;
}

/// The text of a color for a report: its class and its channels.
String _colorText(String? space, List<double> channels) {
  if (space == null) return 'null';
  final name = switch (space) {
    'rgb' => 'Rgb',
    'hsl' => 'Hsl',
    'lab' => 'Lab',
    'hcl' => 'Hcl',
    'cubehelix' => 'Cubehelix',
    _ => space,
  };
  return '$name(${channels.map(_number).join(', ')})';
}

/// The text of a color of the port for a report.
String _describe(Color? c) =>
    c == null ? 'null' : _colorText(_space(c), _channels(c));

/// The text of a list of numbers for a report.
String _numbers(List<double> list) => '[${list.map(_number).join(', ')}]';

/// The text of a number for a report: -0 keeps its sign.
String _number(double x) => x == 0 && x.isNegative ? '-0.0' : '$x';

/// A text in quotes for a report, with its control and non-ASCII
/// characters as escapes.
String _quote(String s) {
  final out = StringBuffer("'");
  for (final rune in s.runes) {
    if (rune < 0x20 || rune > 0x7e) {
      out.write('\\u{${rune.toRadixString(16)}}');
    } else {
      out.writeCharCode(rune);
    }
  }
  out.write("'");
  return out.toString();
}
