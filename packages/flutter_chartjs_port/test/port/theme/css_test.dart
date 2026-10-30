// Original code, not ported from Chart.js: tests of the CSS conversions.
@TestOn('vm')
library;

import 'dart:ui' show Color, ColorSpace, FontStyle, FontWeight;

import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/theme/css.dart';
import 'package:flutter_chartjs_port/src/theme/theme_data.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_test/flutter_test.dart';

// The pin of judge-t.md §3.11 (Chart.js ADR 0052): css.dart holds the one
// conversion of a `Color` and of a `TextStyle`. The theme of Chart.js ADR
// 0050 and the typed API give the same option value for the same Flutter
// value. Each case compares the function of css.dart with the value that
// the compiled theme holds for the same token, and pins the strings of
// theme_data_test.dart, so that the move changed no value.
//
// VM only: css.dart imports dart:ui and the painting library.

/// The value at the dotted [path] of the Maps under [root].
Object? _at(Object? root, String path) {
  var node = root;
  for (final key in path.split('.')) {
    node = (node! as Map<String, Object?>)[key];
  }
  return node;
}

/// The colors of the cases, each with the `rgba()` string of the theme.
final Map<String, (Color, String)> _colors = {
  'an sRGB color': (const Color(0xFF36A2EB), 'rgba(54, 162, 235, 1)'),
  'Color.from with the alpha 0.1': (
    const Color.from(alpha: 0.1, red: 0, green: 0, blue: 0),
    'rgba(0, 0, 0, 0.1)',
  ),
  'the 8-bit alpha of Color(0x1A000000)': (
    const Color(0x1A000000),
    'rgba(0, 0, 0, 0.10196078431372549)',
  ),
  'a Display P3 color through extended sRGB': (
    const Color.from(
      alpha: 1,
      red: 0.8,
      green: 0.3,
      blue: 0.2,
      colorSpace: ColorSpace.displayP3,
    ),
    'rgba(221, 64, 37, 1)',
  ),
  'transparent white': (const Color(0x00FFFFFF), 'rgba(255, 255, 255, 0)'),
};

/// The fonts of the cases, each with its `FontSpec` Map.
final Map<String, (TextStyle, Map<String, Object?>)> _fonts = {
  'each field that the theme reads': (
    const TextStyle(
      fontFamily: 'Liberation Sans',
      fontFamilyFallback: ['serif'],
      fontSize: 14,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w700,
      height: 1.5,
    ),
    {
      'family': "'Liberation Sans', serif",
      'size': 14.0,
      'style': 'italic',
      'weight': 700.0,
      'lineHeight': 1.5,
    },
  ),
  'generic families, a quote and an empty name': (
    const TextStyle(
      fontFamily: 'Serif',
      fontFamilyFallback: ["Tom's Font", '', 'ui-monospace'],
    ),
    {'family': 'Serif, "Tom\'s Font", ui-monospace'},
  ),
  'the normal style and a weight of 350': (
    const TextStyle(fontStyle: FontStyle.normal, fontWeight: FontWeight(350)),
    {'style': 'normal', 'weight': 350.0},
  ),
  'a size alone': (const TextStyle(fontSize: 13), {'size': 13.0}),
  'a color and a letter spacing are left out': (
    const TextStyle(color: Color(0xFFFF0000), letterSpacing: 2, height: 1.25),
    {'lineHeight': 1.25},
  ),
};

void main() {
  group('colorToRgba', () {
    for (final MapEntry(key: name, value: (color, rgba)) in _colors.entries) {
      test('$name: the string of the compiled theme', () {
        expect(colorToRgba(color), rgba);
        final compiled = compileThemeData(ChartThemeData(color: color));
        expect(compiled!['color'], colorToRgba(color));
        expect(_at(compiled, 'scale.ticks.color'), colorToRgba(color));
      });
    }

    test('rawColorOf gives the color token of the raw Map theme', () {
      for (final (color, _) in _colors.values) {
        final raw = themeDataToRaw(ChartThemeData(surface: color));
        expect(_at(raw, 'colors.surface'), rawColorOf(color));
      }
      expect(rawColorOf(null), isNull);
    });
  });

  group('fontSpecOf', () {
    for (final MapEntry(key: name, value: (font, spec)) in _fonts.entries) {
      test('$name: the Map of the raw and the compiled theme', () {
        final actual = fontSpecOf(font)!;
        expect(actual, spec);
        expect(actual.keys, spec.keys);
        final raw = themeDataToRaw(ChartThemeData(font: font));
        final rawFont = _at(raw, 'typography.font')! as AnyObject;
        expect(rawFont, actual);
        expect(rawFont.keys, actual.keys);
        final compiled = compileThemeData(ChartThemeData(font: font));
        expect(_at(compiled, 'scale.ticks.font'), actual);
      });
    }

    test('null gives null, and each call gives a new Map', () {
      expect(fontSpecOf(null), isNull);
      const font = TextStyle(fontSize: 12);
      expect(fontSpecOf(font), isNot(same(fontSpecOf(font))));
      expect(fontSpecOf(const TextStyle()), isEmpty);
    });
  });
}
