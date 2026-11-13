// Original code, not ported from Chart.js: tests of the public theme data.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:ui' as native_ui;
import 'dart:ui' show Color, ColorSpace, FontStyle, FontWeight;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter/animation.dart' show Curve;
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/core/core.config.dart'
    show themeConfigKey;
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show PointInteractionMode;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/platform/native_event.dart';
import 'package:flutter_chartjs_port/src/theme/theme_data.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show SolidChartPaint;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart'
    show ChartPaint;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../../support/color_json.dart';
import '../../support/font_record.dart';
import '../../support/light_theme.dart';

// theming.md §8 test 7 (Chart.js ADR 0050, "The public classes"): the value
// equality, `copyWith`, `lerp` and the diagnostics of `ChartThemeData`, the
// compile of its tokens (Chart.js ADR 0117), the oracle of test 3 and of
// coverage_test.dart (the light preset compiles to the theme of the tokens
// of `LightThemeTokens`), the presets (the mirror rule of the dark preset and
// the contrast of the text pairs), the token allowlist of Chart.js ADR 0050
// ("No public `raw` in 0.1.0", B3 of the design panel) and the hit element
// of a theme ("No touch sizes", B11). The inherited `ChartTheme` is in
// chart_theme_test.dart.
//
// VM only: theme_data.dart imports dart:ui and the painting library, and
// the hit test of B11 runs on charts of `acquireChart`.

/// The red of the tests: `rgb(200, 0, 0)`.
const Color _red = Color.from(alpha: 1, red: 200 / 255, green: 0, blue: 0);

/// The green of the tests: `rgba(0, 128, 0, 0.5)`.
const Color _green = Color.from(alpha: 0.5, red: 0, green: 128 / 255, blue: 0);

/// A new instance of [color], equal to it.
Color _copy(Color color) =>
    Color.from(alpha: color.a, red: color.r, green: color.g, blue: color.b);

/// A font with each of the six fields that the theme reads.
const TextStyle _font = TextStyle(
  fontFamily: 'Liberation Sans',
  fontFamilyFallback: ['serif'],
  fontSize: 14,
  fontStyle: FontStyle.italic,
  fontWeight: FontWeight.w700,
  height: 1.5,
);

/// A theme with a value for each field, none of them the value of a preset.
const ChartThemeData _full = ChartThemeData(
  color: _red,
  borderColor: _green,
  backgroundColor: _red,
  surface: _green,
  inverseSurface: _red,
  onInverseSurface: _green,
  font: _font,
  pointLabelsFont: TextStyle(fontSize: 9),
  palette: [_red, _green],
  paletteBackgroundAlpha: 0.25,
);

/// A second theme with a value for each field, each field other than the
/// field of [_full].
const ChartThemeData _other = ChartThemeData(
  color: _green,
  borderColor: _red,
  backgroundColor: _green,
  surface: _red,
  inverseSurface: _green,
  onInverseSurface: _red,
  font: TextStyle(
    fontFamily: 'serif',
    fontSize: 10,
    fontWeight: FontWeight.w300,
    height: 1,
  ),
  pointLabelsFont: TextStyle(fontSize: 11),
  palette: [_green, _red],
  paletteBackgroundAlpha: 0.75,
);

/// The ten fields of [ChartThemeData] with their readers.
final Map<String, Object? Function(ChartThemeData)> _fields = {
  'color': (t) => t.color,
  'borderColor': (t) => t.borderColor,
  'backgroundColor': (t) => t.backgroundColor,
  'surface': (t) => t.surface,
  'inverseSurface': (t) => t.inverseSurface,
  'onInverseSurface': (t) => t.onInverseSurface,
  'font': (t) => t.font,
  'pointLabelsFont': (t) => t.pointLabelsFont,
  'palette': (t) => t.palette,
  'paletteBackgroundAlpha': (t) => t.paletteBackgroundAlpha,
};

/// [source] with the field [name] taken from [from], through `copyWith`.
ChartThemeData _copyField(
  ChartThemeData source,
  String name,
  ChartThemeData from,
) => switch (name) {
  'color' => source.copyWith(color: from.color),
  'borderColor' => source.copyWith(borderColor: from.borderColor),
  'backgroundColor' => source.copyWith(backgroundColor: from.backgroundColor),
  'surface' => source.copyWith(surface: from.surface),
  'inverseSurface' => source.copyWith(inverseSurface: from.inverseSurface),
  'onInverseSurface' => source.copyWith(
    onInverseSurface: from.onInverseSurface,
  ),
  'font' => source.copyWith(font: from.font),
  'pointLabelsFont' => source.copyWith(pointLabelsFont: from.pointLabelsFont),
  'palette' => source.copyWith(palette: from.palette),
  'paletteBackgroundAlpha' => source.copyWith(
    paletteBackgroundAlpha: from.paletteBackgroundAlpha,
  ),
  _ => throw ArgumentError.value(name, 'name'),
};

/// A theme with only the field [name] of [from].
ChartThemeData _only(String name, ChartThemeData from) =>
    _copyField(const ChartThemeData(), name, from);

/// The token slots of a compiled theme by dot path: each leaf, with a font
/// Map (a key `font` or `<name>Font`) and a List as one slot. The
/// `transitions` keys are left out.
Map<String, Object?> _slots(Object? value, [String prefix = '']) {
  if (value == null && prefix.isEmpty) return const {};
  if (!_isObject(value) ||
      prefix.endsWith('.font') ||
      prefix.endsWith('Font')) {
    return {prefix: value is Curve ? '$value' : value};
  }
  return {
    for (final key in jsObjectKeys(value))
      if (prefix.isNotEmpty || key != 'transitions')
        ..._slots(jsGet(value, key), prefix.isEmpty ? key : '$prefix.$key'),
  };
}

/// Whether [value] is an object of a compiled theme: a Map, or a typed scope
/// with its face (Chart.js ADR 0054 §5).
bool _isObject(Object? value) =>
    value is Map<String, Object?> || value is JsObjectFace;

/// [value] as plain Dart values for a compare with a Map literal: an object
/// gives a new Map of its own keys in the `Object.keys` order, each value
/// read through its face; another value is itself.
Object? _plain(Object? value) => _isObject(value)
    ? <String, Object?>{
        for (final key in jsObjectKeys(value)) key: _plain(jsGet(value, key)),
      }
    : value is Curve
    ? '$value'
    : value;

/// The value of the dot path [path] in [root].
Object? _at(Object? root, String path) {
  var node = root;
  for (final key in path.split('.')) {
    node = jsGet(node, key);
  }
  return node;
}

/// The WCAG 2 contrast ratio of [a] and [b].
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

/// The paths of theming.md §4 for each public token alone (Chart.js ADR
/// 0050, "No public `raw` in 0.1.0"). A font path names the font Map.
const Map<String, Set<String>> _tokenPaths = {
  'color': {
    'color',
    'scale.ticks.color',
    'scale.title.color',
    'scales.radialLinear.pointLabels.color',
    'plugins.title.color',
    'plugins.subtitle.color',
  },
  'borderColor': {
    'scale.grid.color',
    'scale.border.color',
    'scales.radialLinear.angleLines.color',
    'elements.point.borderColor',
    'elements.line.borderColor',
    'elements.bar.borderColor',
  },
  'backgroundColor': {
    'elements.point.backgroundColor',
    'elements.line.backgroundColor',
    'elements.bar.backgroundColor',
    'elements.arc.backgroundColor',
  },
  'surface': {'elements.arc.borderColor', 'scale.ticks.backdropColor'},
  'inverseSurface': {'plugins.tooltip.backgroundColor'},
  'onInverseSurface': {
    'plugins.tooltip.titleColor',
    'plugins.tooltip.bodyColor',
    'plugins.tooltip.footerColor',
    'plugins.tooltip.multiKeyBackground',
  },
  'font': {
    'scale.ticks.font',
    'scale.title.font',
    'plugins.legend.labels.font',
    'plugins.legend.title.font',
    'plugins.tooltip.bodyFont',
    'plugins.title.font',
    'plugins.subtitle.font',
    'plugins.tooltip.titleFont',
    'plugins.tooltip.footerFont',
    'scales.radialLinear.pointLabels.font',
  },
  'pointLabelsFont': {'scales.radialLinear.pointLabels.font'},
  'palette': {
    r'plugins.colors.$borderColors',
    r'plugins.colors.$backgroundColors',
  },
  'paletteBackgroundAlpha': {},
};

/// A chart event at ([x], [y]) for `getElementsAtEventForMode`.
final class _Event(
  @override final types.Chart? chart,
  @override final double? x,
  @override final double? y,
) implements types.ChartEvent {
  @override
  String get type => 'mousemove';

  @override
  NativeEvent? get native => null;
}

/// The scatter chart of the probe F-P1b of Chart.js ADR 0050: 3 points,
/// with the compiled [theme] under `themeConfigKey`.
AnyObject _scatter(Object? theme) => <String, Object?>{
  'type': 'scatter',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': <Object?>[
          <String, Object?>{'x': 0, 'y': 0},
          <String, Object?>{'x': 5, 'y': 5},
          <String, Object?>{'x': 10, 'y': 10},
        ],
      },
    ],
  },
  themeConfigKey: ?theme,
};

/// The `point` hits of [chart] at 6 px right of the point 1 of the dataset
/// 0, as `datasetIndex:index`. The point radius is 3 and the hit radius 1
/// (`element.point.ts:31-50`). Thus the event is outside the point, and
/// inside it with a hit radius of 8 (`element.point.ts:62-66`).
List<String> _hits(Chart chart) {
  final point = chart.getDatasetMeta(0).data[1] as Element;
  final x = point['x']! as double;
  final y = point['y']! as double;
  return [
    for (final item in chart.getElementsAtEventForMode(
      _Event(chart, x + 6, y),
      const PointInteractionMode(),
      <String, Object?>{'intersect': true},
      false,
    ))
      '${item.datasetIndex}:${item.index}',
  ];
}

void main() {
  group('==, hashCode and copyWith', () {
    test('equal themes are == with equal hashes', () {
      final copy = _full.copyWith();
      expect(identical(copy, _full), isFalse);
      expect(copy, _full);
      expect(copy.hashCode, _full.hashCode);
      expect(
        const ChartThemeData.light().copyWith(),
        const ChartThemeData.light(),
      );
      expect(
        const ChartThemeData.light().copyWith().hashCode,
        const ChartThemeData.light().hashCode,
      );
      final a = ChartThemeData(color: _copy(_red), font: _font.copyWith());
      final b = ChartThemeData(color: _copy(_red), font: _font.copyWith());
      expect(identical(a.color, b.color), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    for (final name in _fields.keys) {
      test('the field $name alone breaks ==', () {
        final changed = _copyField(_full, name, _other);
        expect(_fields[name]!(changed), isNot(_fields[name]!(_full)));
        expect(changed, isNot(_full));
        expect(_only(name, _full), isNot(const ChartThemeData()));
      });
    }

    test('two palettes with equal colors in new lists are ==', () {
      const a = ChartThemeData(palette: [_red, _green]);
      final b = ChartThemeData(palette: [_copy(_red), _copy(_green)]);
      expect(identical(a.palette, b.palette), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ChartThemeData(palette: [_green, _red])));
      expect(a, isNot(const ChartThemeData(palette: [_red])));
      expect(a, isNot(const ChartThemeData()));
    });

    test('copyWith() equals the source', () {
      expect(_full.copyWith(), _full);
      expect(const ChartThemeData().copyWith(), const ChartThemeData());
      expect(
        const ChartThemeData.dark().copyWith(),
        const ChartThemeData.dark(),
      );
    });

    for (final name in _fields.keys) {
      test('copyWith($name:) changes only $name', () {
        final changed = _copyField(_full, name, _other);
        for (final MapEntry(key: field, value: read) in _fields.entries) {
          expect(
            read(changed),
            field == name ? read(_other) : read(_full),
            reason: field,
          );
        }
      });
    }
  });

  group('lerp', () {
    test('t = 0 and t = 1 give the ends', () {
      expect(ChartThemeData.lerp(_full, _other, 0), _full);
      expect(ChartThemeData.lerp(_full, _other, 1), _other);
      expect(
        ChartThemeData.lerp(
          const ChartThemeData.light(),
          const ChartThemeData.dark(),
          0,
        ),
        const ChartThemeData.light(),
      );
      expect(
        ChartThemeData.lerp(
          const ChartThemeData.light(),
          const ChartThemeData.dark(),
          1,
        ),
        const ChartThemeData.dark(),
      );
    });

    test('lerp of a theme with itself gives the theme', () {
      // Color.lerp(a, a, 0.3) is not always a (theming.md §5.1).
      expect(identical(ChartThemeData.lerp(_full, _full, 0.3), _full), isTrue);
      const light = ChartThemeData.light();
      expect(identical(ChartThemeData.lerp(light, light, 0.3), light), isTrue);
    });

    test('the colors lerp with Color.lerp', () {
      final mid = ChartThemeData.lerp(_full, _other, 0.3);
      expect(mid.color, Color.lerp(_red, _green, 0.3));
      expect(mid.borderColor, Color.lerp(_green, _red, 0.3));
      expect(mid.onInverseSurface, Color.lerp(_green, _red, 0.3));
    });

    test('a token with one null end switches at 0.5', () {
      const a = ChartThemeData(color: _red, font: _font, palette: [_red]);
      const b = ChartThemeData(
        borderColor: _green,
        pointLabelsFont: TextStyle(fontSize: 9),
      );
      for (final (t, expected) in [(0.0, a), (0.49, a), (0.5, b), (1.0, b)]) {
        final mid = ChartThemeData.lerp(a, b, t);
        expect(mid.color, expected.color, reason: 'color at $t');
        expect(mid.borderColor, expected.borderColor, reason: 'border at $t');
        expect(mid.font, expected.font, reason: 'font at $t');
        expect(
          mid.pointLabelsFont,
          expected.pointLabelsFont,
          reason: 'pointLabelsFont at $t',
        );
        expect(mid.palette, expected.palette, reason: 'palette at $t');
      }
    });

    test('palettes of one length lerp pairwise', () {
      final mid = ChartThemeData.lerp(_full, _other, 0.5);
      expect(mid.palette, [
        Color.lerp(_red, _green, 0.5),
        Color.lerp(_green, _red, 0.5),
      ]);
    });

    test('palettes of two lengths switch at 0.5', () {
      const a = ChartThemeData(palette: [_red]);
      const b = ChartThemeData(palette: [_green, _red]);
      expect(ChartThemeData.lerp(a, b, 0.49).palette, [_red]);
      expect(ChartThemeData.lerp(a, b, 0.5).palette, [_green, _red]);
    });

    test('paletteBackgroundAlpha lerps', () {
      expect(
        ChartThemeData.lerp(_full, _other, 0.5).paletteBackgroundAlpha,
        closeTo(0.5, 1e-12),
      );
      // A curve beyond the ends gives an alpha in the range.
      expect(ChartThemeData.lerp(_full, _other, 2).paletteBackgroundAlpha, 1);
      expect(ChartThemeData.lerp(_full, _other, -1).paletteBackgroundAlpha, 0);
    });

    test('the fonts lerp with TextStyle.lerp', () {
      final mid = ChartThemeData.lerp(_full, _other, 0.5);
      expect(mid.font, TextStyle.lerp(_full.font, _other.font, 0.5));
      expect(mid.font!.fontSize, 12);
      expect(mid.font!.fontWeight, FontWeight.w500);
      expect(mid.font!.height, 1.25);
      expect(
        mid.pointLabelsFont,
        TextStyle.lerp(_full.pointLabelsFont, _other.pointLabelsFont, 0.5),
      );
      expect(mid.pointLabelsFont!.fontSize, 10);
    });

    test('two fonts with a size, a weight or a height at one end only '
        'switch at 0.5', () {
      // TextStyle.lerp gives the missing size from the other end and the
      // missing weight as FontWeight.normal: lerp(a, b, 1) would not be b.
      for (final other in const [
        TextStyle(fontWeight: FontWeight.w700, height: 1.5),
        TextStyle(fontSize: 14, height: 1.5),
        TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ]) {
        final a = ChartThemeData(font: _font.copyWith());
        final b = ChartThemeData(font: other);
        expect(ChartThemeData.lerp(a, b, 0.49).font, _font, reason: '$other');
        expect(ChartThemeData.lerp(a, b, 0.5).font, other, reason: '$other');
        expect(ChartThemeData.lerp(a, b, 1), b, reason: '$other');
      }
    });
  });

  group('diagnostics', () {
    /// The diagnostics text of [theme] without the identity hash.
    String text(ChartThemeData theme) => theme
        .toDiagnosticsNode()
        .toStringDeep()
        .replaceFirst(RegExp('^ChartThemeData#[0-9a-f]{5}'), 'ChartThemeData');

    test('the dark preset', () {
      expect(text(const ChartThemeData.dark()), _darkDiagnostics);
    });

    test('the default values are left out', () {
      expect(text(const ChartThemeData()), 'ChartThemeData\n');
      expect(
        text(const ChartThemeData(paletteBackgroundAlpha: 0.25)),
        'ChartThemeData\n   paletteBackgroundAlpha: 0.3\n',
      );
    });
  });

  group('the tokens reach the compiled theme as they are', () {
    // Chart.js ADR 0117: compileThemeData gives the fields to
    // compileChartTheme, with no conversion.
    Color? colorOf(Color color) =>
        (compileThemeData(ChartThemeData(color: color))!['color']!
                as SolidChartPaint)
            .color;

    test('an sRGB color', () {
      expect(colorOf(const Color(0xFF36A2EB)), const Color(0xFF36A2EB));
    });

    test('Color.from keeps the alpha 0.1', () {
      expect(
        colorOf(const Color.from(alpha: 0.1, red: 0, green: 0, blue: 0)),
        const native_ui.Color.fromRGBO(0, 0, 0, 0.1),
      );
      // The 8-bit alpha of Color(0x1A000000) is not 0.1 (theming.md §4).
      expect(colorOf(const Color(0x1A000000)), const Color(0x1A000000));
    });

    test('a Display P3 color stays a Display P3 color', () {
      const p3 = Color.from(
        alpha: 1,
        red: 0.8,
        green: 0.3,
        blue: 0.2,
        colorSpace: ColorSpace.displayP3,
      );
      expect(colorOf(p3), p3);
    });

    test('the font token is the TextStyle itself', () {
      // A font is a TextStyle from the option to the canvas (Chart.js ADR
      // 0116): no conversion.
      final compiled = compileThemeData(const ChartThemeData(font: _font));
      expect(_at(compiled, 'scale.ticks.font'), same(_font));
    });

    test('null tokens theme nothing', () {
      expect(compileThemeData(const ChartThemeData()), isNull);
      expect(
        compileThemeData(const ChartThemeData(paletteBackgroundAlpha: 1)),
        isNull,
      );
      expect(compileThemeData(const ChartThemeData(font: TextStyle())), isNull);
    });

    test('a TextStyle with color and letterSpacing reaches each slot as it '
        'is', () {
      const font = TextStyle(color: _red, letterSpacing: 2, fontSize: 13);
      final compiled = compileThemeData(const ChartThemeData(font: font));
      expect(_at(compiled, 'scale.ticks.font'), same(font));
      expect(_at(compiled, 'plugins.legend.labels.font'), same(font));
    });

    test('the palette', () {
      final compiled = compileThemeData(
        const ChartThemeData(
          palette: [_red, _green],
          paletteBackgroundAlpha: 1,
        ),
      );
      expect(_at(compiled, r'plugins.colors.$borderColors'), [_red, _green]);
      expect(_at(compiled, r'plugins.colors.$backgroundColors'), [
        const native_ui.Color.fromRGBO(200, 0, 0, 1),
        const native_ui.Color.fromRGBO(0, 128, 0, 1),
      ]);
      final half = compileThemeData(const ChartThemeData(palette: [_green]));
      expect(_at(half, r'plugins.colors.$borderColors'), [
        const native_ui.Color.fromRGBO(0, 128, 0, 0.5),
      ]);
      expect(_at(half, r'plugins.colors.$backgroundColors'), [
        const native_ui.Color.fromRGBO(0, 128, 0, 0.5),
      ]);
    });
  });

  group('the oracle of test 3', () {
    test('the light preset compiles to the light tokens', () {
      final compiled = compileThemeData(const ChartThemeData.light());
      final oracle = compileLightTheme();
      expect(_plain(compiled), _plain(oracle));
      // The key order too: the compiled objects keep the insertion order.
      // A font is its record (font_record.dart).
      Object? font(Object? v) =>
          v is TextStyle ? fontObjectRecordOf(v) : throw ArgumentError(v);
      expect(
        jsonEncode(canonicalColors(_plain(compiled)), toEncodable: font),
        jsonEncode(canonicalColors(_plain(oracle)), toEncodable: font),
      );
    });

    test('each call compiles again (no memo, Chart.js ADR 0054 §4)', () {
      expect(
        identical(
          compileThemeData(const ChartThemeData.light()),
          compileThemeData(const ChartThemeData.light()),
        ),
        isFalse,
      );
      expect(
        _plain(compileThemeData(const ChartThemeData.light())),
        _plain(compileThemeData(const ChartThemeData.light())),
      );
      final theme = ChartThemeData(color: _copy(_red));
      expect(
        identical(compileThemeData(theme), compileThemeData(theme)),
        isFalse,
      );
      // An equal instance compiles to an equal Map of its own.
      final equal = theme.copyWith();
      expect(
        identical(compileThemeData(equal), compileThemeData(theme)),
        isFalse,
      );
      expect(_plain(compileThemeData(equal)), _plain(compileThemeData(theme)));
      expect(compileThemeData(null), isNull);
      expect(compileThemeData(const ChartThemeData()), isNull);
      expect(compileThemeData(const ChartThemeData()), isNull);
    });

    test('the compiled theme is frozen', () {
      final compiled = compileThemeData(_full)!;
      expect(
        () => compiled['color'] = const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 0, 0, 1),
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('the presets', () {
    const light = ChartThemeData.light();
    const dark = ChartThemeData.dark();

    test('each dark color token is the mirror of the light token', () {
      final pairs = [
        ('color', light.color, dark.color),
        ('borderColor', light.borderColor, dark.borderColor),
        ('backgroundColor', light.backgroundColor, dark.backgroundColor),
        ('surface', light.surface, dark.surface),
        ('inverseSurface', light.inverseSurface, dark.inverseSurface),
        ('onInverseSurface', light.onInverseSurface, dark.onInverseSurface),
      ];
      int channel(double x) => (x * 255).round();
      for (final (name, l, d) in pairs) {
        expect(
          (channel(d!.r), channel(d.g), channel(d.b), d.a),
          (255 - channel(l!.r), 255 - channel(l.g), 255 - channel(l.b), l.a),
          reason: name,
        );
      }
      expect(
        compileThemeData(dark)!['color'],
        const ChartPaint.solid(native_ui.Color.fromRGBO(153, 153, 153, 1)),
      );
      expect(
        _at(compileThemeData(dark), 'plugins.tooltip.backgroundColor'),
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 255, 255, 0.8)),
      );
    });

    test('dark keeps the fonts and the palette of light', () {
      expect(dark.font, light.font);
      expect(dark.pointLabelsFont, light.pointLabelsFont);
      expect(dark.palette, light.palette);
      expect(dark.paletteBackgroundAlpha, 0.5);
    });

    test('dark emits the key paths of light', () {
      final lightPaths = _slots(compileThemeData(light)).keys.toList();
      expect(_slots(compileThemeData(dark)).keys.toList(), lightPaths);
      expect(lightPaths, isNotEmpty);
    });

    test('the text pairs have a contrast of 4.5:1 or more', () {
      for (final preset in [light, dark]) {
        final surface = preset.surface!;
        expect(
          _contrast(preset.color!, surface),
          greaterThanOrEqualTo(4.5),
          reason: 'color on surface',
        );
        expect(
          _contrast(
            preset.onInverseSurface!,
            Color.alphaBlend(preset.inverseSurface!, surface),
          ),
          greaterThanOrEqualTo(4.5),
          reason: 'onInverseSurface on inverseSurface over surface',
        );
      }
      // The figures of S-contrast (Chart.js ADR 0050, Context).
      expect(_contrast(light.color!, light.surface!), closeTo(5.74, 0.01));
      expect(_contrast(dark.color!, dark.surface!), closeTo(7.37, 0.01));
    });

    test('const ChartThemeData() compiles to null', () {
      expect(compileThemeData(const ChartThemeData()), isNull);
    });

    test('an empty palette emits no palette key', () {
      expect(compileThemeData(const ChartThemeData(palette: [])), isNull);
      final compiled = compileThemeData(
        const ChartThemeData(color: _red, palette: []),
      )!;
      expect((compiled['plugins']! as JsObjectFace).jsHas('colors'), false);
    });

    test('a paletteBackgroundAlpha outside 0 to 1 fails a debug assert', () {
      for (final alpha in [1.5, -0.1, double.nan]) {
        expect(
          () => ChartThemeData(paletteBackgroundAlpha: alpha),
          throwsAssertionError,
          reason: '$alpha',
        );
      }
      for (final alpha in [0.0, 1.0]) {
        expect(
          ChartThemeData(paletteBackgroundAlpha: alpha).paletteBackgroundAlpha,
          alpha,
        );
      }
    });
  });

  group('B3: the token allowlist', () {
    // Chart.js ADR 0050, "No public `raw` in 0.1.0": the token emission is
    // the allowlist. Each public token alone emits exactly its paths of
    // theming.md §4 (Chart.js ADR 0118: the compiler has no guard).
    for (final MapEntry(key: name, value: paths) in _tokenPaths.entries) {
      test('the token $name alone emits its paths of theming.md §4', () {
        final compiled = compileThemeData(_only(name, _full));
        final slots = _slots(compiled);
        expect(slots.keys.toSet(), paths);
        if (paths.isEmpty) expect(compiled, isNull);
      });
    }

    test('all tokens emit the union of the paths', () {
      final slots = _slots(compileThemeData(_full));
      expect(slots.keys.toSet(), {
        for (final paths in _tokenPaths.values) ...paths,
      });
    });

    test('the presets emit only the paths of the tokens', () {
      final allowed = {for (final paths in _tokenPaths.values) ...paths};
      for (final preset in [
        const ChartThemeData.light(),
        const ChartThemeData.dark(),
      ]) {
        expect(allowed, containsAll(_slots(compileThemeData(preset)).keys));
      }
    });
  });

  group('B11: no touch sizes', () {
    // Chart.js ADR 0050, "No touch sizes": the probe F-P1b. The theme never
    // carries `hitRadius` or `hoverRadius`, so a theme leaves the hit
    // element unchanged. The control: a theme scope with the key
    // `elements.point.hitRadius: 8` changes the hit element (the guard
    // passes it, F-P1), so the event position is 6 px from a hit.
    testWidgets('the unthemed chart has no hit', (tester) async {
      final chart = acquireChart(_scatter(null));
      await tester.pump();
      expect(_hits(chart), isEmpty);
    });

    for (final (name, theme) in [
      ('the light preset', const ChartThemeData.light()),
      ('the dark preset', const ChartThemeData.dark()),
      ('a theme of every token', _full),
    ]) {
      testWidgets('a chart with $name has no hit', (tester) async {
        final compiled = compileThemeData(theme);
        expect(compiled, isNotNull);
        final chart = acquireChart(_scatter(compiled));
        await tester.pump();
        expect(_hits(chart), isEmpty);
      });
    }

    testWidgets('the control: a raw hitRadius of 8 gives a hit', (
      tester,
    ) async {
      final chart = acquireChart(
        _scatter(
          // No token gives hitRadius: the theme scope of the raw config.
          <String, Object?>{
            'elements': <String, Object?>{
              'point': <String, Object?>{'hitRadius': 8.0},
            },
          },
        ),
      );
      await tester.pump();
      expect(_hits(chart), ['0:1']);
    });
  });
}

/// The diagnostics text of `const ChartThemeData.dark()`, without the
/// identity hash of `describeIdentity` after the class name. The default
/// `paletteBackgroundAlpha` 0.5 is left out.
const String _darkDiagnostics = '''
ChartThemeData
   color: Color(alpha: 1.0000, red: 0.6000, green: 0.6000, blue:
     0.6000, colorSpace: ColorSpace.sRGB)
   borderColor: Color(alpha: 0.1000, red: 1.0000, green: 1.0000,
     blue: 1.0000, colorSpace: ColorSpace.sRGB)
   backgroundColor: Color(alpha: 0.1000, red: 1.0000, green: 1.0000,
     blue: 1.0000, colorSpace: ColorSpace.sRGB)
   surface: Color(alpha: 1.0000, red: 0.0000, green: 0.0000, blue:
     0.0000, colorSpace: ColorSpace.sRGB)
   inverseSurface: Color(alpha: 0.8000, red: 1.0000, green: 1.0000,
     blue: 1.0000, colorSpace: ColorSpace.sRGB)
   onInverseSurface: Color(alpha: 1.0000, red: 0.0000, green:
     0.0000, blue: 0.0000, colorSpace: ColorSpace.sRGB)
   font: ChartTextStyle(inherit: true, family: Helvetica Neue,
     familyFallback: [Helvetica, Arial, sans-serif], size: 12.0,
     style: normal, height: 1.2x)
   pointLabelsFont: ChartTextStyle(inherit: true, size: 10.0)
   palette: Color(alpha: 1.0000, red: 0.2118, green: 0.6353, blue:
     0.9216, colorSpace: ColorSpace.sRGB), Color(alpha: 1.0000, red:
     1.0000, green: 0.3882, blue: 0.5176, colorSpace:
     ColorSpace.sRGB), Color(alpha: 1.0000, red: 1.0000, green:
     0.6235, blue: 0.2510, colorSpace: ColorSpace.sRGB),
     Color(alpha: 1.0000, red: 1.0000, green: 0.8039, blue: 0.3373,
     colorSpace: ColorSpace.sRGB), Color(alpha: 1.0000, red: 0.2941,
     green: 0.7529, blue: 0.7529, colorSpace: ColorSpace.sRGB),
     Color(alpha: 1.0000, red: 0.6000, green: 0.4000, blue: 1.0000,
     colorSpace: ColorSpace.sRGB), Color(alpha: 1.0000, red: 0.7882,
     green: 0.7961, blue: 0.8118, colorSpace: ColorSpace.sRGB)
''';
