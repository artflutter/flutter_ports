// Original code, not ported from Chart.js: tests of the theme compiler.
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show InteractionMode;
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleBounds;
import 'package:flutter_chartjs_port/src/helpers/grace_length.dart'
    show GraceLength;
import 'package:flutter_chartjs_port/src/helpers/radius_length.dart'
    show RadiusLength;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show ChartOptionsScope;
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;
import 'package:test/test.dart';

import '../../support/axis_json.dart';
import '../../support/color_json.dart';
import '../../support/easing_json.dart';
import '../../support/font_record.dart';
import '../../support/keyword_enum_json.dart';
import '../../support/length_json.dart';
import '../../support/light_theme.dart';
import '../../support/mode_json.dart';

// The theme compiler has no upstream counterpart (Chart.js ADR 0050). These
// tests cover theming.md §3.3 (the emitted keys, the never-emitted list as
// the emission guard, the deep freeze and no memo), §3.4 and §4 (the token
// keys, the point-label font, the title, subtitle, legend and tooltip keys
// and the palette of Chart.js ADR 0050, from typed tokens, Chart.js ADR
// 0117), §8 test 1 (no token equals upstream, no extra scope, the
// scope position of a compiled theme, no dependence on the platform) and
// the parts of §8 test 5 that need no chart. The expected scope lists follow
// the hunks H0-H3 of core.config.dart and their tests in
// test/port/core/core.config_test.dart.
//
// The tests run on the VM, dart2js and dart2wasm. The snapshot of the light
// preset is the same literal on each of them: the compiler reads no
// platform. test/port/theme/target_platform_test.dart checks the same
// snapshot under each TargetPlatform of Flutter.

/// The JSON form of [value]: a Map gives its keys in the `Object.keys`
/// order, a number gives [jsNumberToString], `undefined` gives
/// `"<undefined>"` and a function gives `"<fn>"`. The form is the same on
/// every platform.
String _json(Object? value) => referenceColorTokens(_jsonRaw(value));

String _jsonRaw(Object? value) => switch (value) {
  _ when nativeColorBytes(value) != null => jsonEncode(nativeColorBytes(value)),
  null => 'null',
  Undefined() => '"<undefined>"',
  final bool b => b ? 'true' : 'false',
  final num n => jsNumberToString(n),
  final String s => jsonEncode(s),
  final TextStyle font => _jsonRaw(fontObjectRecordOf(font)),
  _ when jsIsFunction(value) => '"<fn>"',
  Curve() => curveJson,
  final Object keyword when isKeywordEnum(keyword) => keywordJson(keyword),
  RadiusLength() || GraceLength() => lengthJson,
  ScaleAxis() => axisJson,
  InteractionMode() => modeJson,
  final List<Object?> list => '[${list.map(_json).join(',')}]',
  final Object map when _isObject(map) =>
    '{${jsObjectKeys(map).map((k) => _entry(map, k)).join(',')}}',
  _ => throw ArgumentError.value(value, 'value', 'has no JSON form'),
};

/// Whether [value] is an object of a compiled theme: a Map, or a typed
/// scope with its face (Chart.js ADR 0054 §5).
bool _isObject(Object? value) =>
    value is Map<String, Object?> || value is JsObjectFace;

/// The own keys of the object [value] in the `Object.keys` order.
List<String> _keys(Object? value) => jsObjectKeys(value);

/// [value] as plain Dart values for a compare with a Map literal: an
/// object gives a new Map of its own keys in the `Object.keys` order, each
/// value read through its face; another value is itself.
Object? _plain(Object? value) => _isObject(value)
    ? <String, Object?>{
        for (final key in _keys(value)) key: _plain(jsGet(value, key)),
      }
    : value;

/// The JSON member `"key":value` of [key] in [map].
String _entry(Object map, String key) =>
    '${jsonEncode(key)}:${_json(jsGet(map, key))}';

/// The leaves of [value] by dot path, in key order. A List is a leaf.
Map<String, Object?> _leaves(Object? value, [String prefix = '']) {
  if (!_isObject(value)) return {prefix: value};
  return {
    for (final key in _keys(value))
      ..._leaves(jsGet(value, key), prefix.isEmpty ? key : '$prefix.$key'),
  };
}

/// Every object and List node of [value] with its dot path, the root first.
Iterable<(String, Object)> _nodes(Object? value, [String path = '']) sync* {
  if (_isObject(value)) {
    yield (path, value!);
    for (final key in _keys(value)) {
      yield* _nodes(jsGet(value, key), path.isEmpty ? key : '$path.$key');
    }
  } else if (value is List<Object?>) {
    yield (path, value);
    for (var i = 0; i < value.length; i++) {
      yield* _nodes(value[i], '$path.$i');
    }
  }
}

/// The dot path of a node or a leaf as the key list of the guard.
List<String> _path(String dotPath) => dotPath.split('.');

/// The three `transitions` leaves that the compiler adds (theming.md §3.8).
const Map<String, Object?> _transitionLeaves = {
  'transitions.theme.animation.duration': 200.0,
  'transitions.theme.animation.easing': Curves.linear,
  'transitions.themeFrame.animation.duration': 0.0,
};

/// The six color tokens, each with the compiled theme of that token alone
/// (Chart.js ADR 0117).
final List<(String, ChartOptionsScope? Function(ui.Color))> _colorTokens = [
  ('color', (c) => compileChartTheme(color: c)),
  ('borderColor', (c) => compileChartTheme(borderColor: c)),
  ('backgroundColor', (c) => compileChartTheme(backgroundColor: c)),
  ('surface', (c) => compileChartTheme(surface: c)),
  ('inverseSurface', (c) => compileChartTheme(inverseSurface: c)),
  ('onInverseSurface', (c) => compileChartTheme(onInverseSurface: c)),
];

/// The color `rgb(200, 0, 0)` of the hover test of theming.md §3.2.
const ui.Color _red = ui.Color.fromRGBO(200, 0, 0, 1);

/// The color `rgba(0, 0, 255, 0.8)`, a second palette color.
const ui.Color _blue = ui.Color.fromRGBO(0, 0, 255, 0.8);

/// `BORDER_COLORS` (`plugin.colors.ts:14-22`).
const List<ui.Color> _upstreamBorderColors = [
  ui.Color.fromRGBO(54, 162, 235, 1),
  ui.Color.fromRGBO(255, 99, 132, 1),
  ui.Color.fromRGBO(255, 159, 64, 1),
  ui.Color.fromRGBO(255, 205, 86, 1),
  ui.Color.fromRGBO(75, 192, 192, 1),
  ui.Color.fromRGBO(153, 102, 255, 1),
  ui.Color.fromRGBO(201, 203, 207, 1),
];

/// `BACKGROUND_COLORS` (`plugin.colors.ts:25`): each border color with
/// `replace('rgb(', 'rgba(')` and then `replace(')', ', 0.5)')`.
final List<ui.Color> _upstreamBackgroundColors = [
  for (final color in _upstreamBorderColors) color.withValues(alpha: 0.5),
];

/// The labels of the scope objects of a scope list: the name of a known
/// object, `{}#n` for the n-th other empty object, or `?<json>` for another
/// value.
String Function(Object?) _labeller(List<(Object?, String)> named) {
  final names = Map<Object?, String>.identity();
  for (final (scope, name) in named) {
    names[scope] = name;
  }
  final seen = Map<Object?, String>.identity();
  var fresh = 0;
  return (scope) {
    final name = names[scope] ?? seen[scope];
    if (name != null) return name;
    final label = _isObject(scope) && _keys(scope).isEmpty
        ? '{}#${fresh++}'
        : '?${_json(scope)}';
    seen[scope] = label;
    return label;
  };
}

/// The value of the dot path [path] in [root].
Object? _at(Object? root, String path) {
  var node = root;
  for (final key in path.split('.')) {
    node = jsGet(node, key);
  }
  return node;
}

/// The test themes of theming.md §8 test 5: each one compiles only to
/// allowed paths.
final Map<String, ChartOptionsScope? Function()> _testThemes = {
  'light': compileLightTheme,
  for (final (token, compile) in _colorTokens) token: () => compile(_red),
  'font': () => compileChartTheme(
    font: const ChartTextStyle(
      fontFamily: 'serif',
      fontFamilyFallback: [],
      fontSize: 14,
    ),
  ),
  'palette': () =>
      compileChartTheme(palette: [_red, _blue], paletteBackgroundAlpha: 0.25),
  'pointLabelsFont': () => compileChartTheme(
    font: const ChartTextStyle(
      fontFamily: 'serif',
      fontFamilyFallback: [],
      fontSize: 14,
    ),
    pointLabelsFont: const ChartTextStyle(
      fontSize: 9,
      fontWeight: ui.FontWeight.bold,
    ),
  ),
};

void main() {
  setUpSpecs();

  group('compileChartTheme', () {
    test('tokens that emit no key compile to null', () {
      expect(compileChartTheme(), isNull);
      expect(compileChartTheme(font: const ChartTextStyle()), isNull);
      expect(
        compileChartTheme(
          font: const ChartTextStyle(color: ui.Color(0xFFFF0000)),
        ),
        isNull,
      );
      expect(
        compileChartTheme(pointLabelsFont: const ChartTextStyle()),
        isNull,
      );
      expect(compileChartTheme(palette: const []), isNull);
      expect(compileChartTheme(paletteBackgroundAlpha: 1), isNull);
    });

    test('the light preset', () {
      // The same leaves, in the same order, on the VM, dart2js and dart2wasm.
      const gray = ui.Color.fromRGBO(102, 102, 102, 1);
      const tenth = ui.Color.fromRGBO(0, 0, 0, 0.1);
      const white = ui.Color.fromRGBO(255, 255, 255, 1);
      final leaves = _leaves(compileLightTheme());
      expect(leaves, {
        'color': gray,
        'scale.ticks.color': gray,
        'scale.ticks.backdropColor': const ui.Color.fromRGBO(
          255,
          255,
          255,
          0.75,
        ),
        'scale.ticks.font': const ChartTextStyle(
          fontFamily: 'Helvetica Neue',
          fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
          fontSize: 12,
          fontStyle: ui.FontStyle.normal,
          height: 1.2,
        ),
        'scale.title.color': gray,
        'scale.title.font': const ChartTextStyle(
          fontFamily: 'Helvetica Neue',
          fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
          fontSize: 12,
          fontStyle: ui.FontStyle.normal,
          height: 1.2,
        ),
        'scale.grid.color': tenth,
        'scale.border.color': tenth,
        'scales.radialLinear.pointLabels.color': gray,
        'scales.radialLinear.pointLabels.font': const ChartTextStyle(
          fontFamily: 'Helvetica Neue',
          fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
          fontStyle: ui.FontStyle.normal,
          height: 1.2,
          fontSize: 10,
        ),
        'scales.radialLinear.angleLines.color': tenth,
        'plugins.title.color': gray,
        'plugins.title.font': const ChartTextStyle(
          fontFamily: 'Helvetica Neue',
          fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
          fontSize: 12,
          fontStyle: ui.FontStyle.normal,
          height: 1.2,
        ),
        'plugins.subtitle.color': gray,
        'plugins.subtitle.font': const ChartTextStyle(
          fontFamily: 'Helvetica Neue',
          fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
          fontSize: 12,
          fontStyle: ui.FontStyle.normal,
          height: 1.2,
        ),
        'plugins.legend.labels.font': const ChartTextStyle(
          fontFamily: 'Helvetica Neue',
          fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
          fontSize: 12,
          fontStyle: ui.FontStyle.normal,
          height: 1.2,
        ),
        'plugins.legend.title.font': const ChartTextStyle(
          fontFamily: 'Helvetica Neue',
          fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
          fontSize: 12,
          fontStyle: ui.FontStyle.normal,
          height: 1.2,
        ),
        'plugins.tooltip.backgroundColor': const ui.Color.fromRGBO(
          0,
          0,
          0,
          0.8,
        ),
        'plugins.tooltip.titleColor': white,
        'plugins.tooltip.bodyColor': white,
        'plugins.tooltip.footerColor': white,
        'plugins.tooltip.multiKeyBackground': white,
        'plugins.tooltip.titleFont': const ChartTextStyle(
          fontFamily: 'Helvetica Neue',
          fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
          fontSize: 12,
          fontStyle: ui.FontStyle.normal,
          height: 1.2,
        ),
        'plugins.tooltip.bodyFont': const ChartTextStyle(
          fontFamily: 'Helvetica Neue',
          fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
          fontSize: 12,
          fontStyle: ui.FontStyle.normal,
          height: 1.2,
        ),
        'plugins.tooltip.footerFont': const ChartTextStyle(
          fontFamily: 'Helvetica Neue',
          fontFamilyFallback: ['Helvetica', 'Arial', 'sans-serif'],
          fontSize: 12,
          fontStyle: ui.FontStyle.normal,
          height: 1.2,
        ),
        r'plugins.colors.$borderColors': [
          const ui.Color.fromRGBO(54, 162, 235, 1),
          const ui.Color.fromRGBO(255, 99, 132, 1),
          const ui.Color.fromRGBO(255, 159, 64, 1),
          const ui.Color.fromRGBO(255, 205, 86, 1),
          const ui.Color.fromRGBO(75, 192, 192, 1),
          const ui.Color.fromRGBO(153, 102, 255, 1),
          const ui.Color.fromRGBO(201, 203, 207, 1),
        ],
        r'plugins.colors.$backgroundColors': _upstreamBackgroundColors,
        'elements.point.borderColor': tenth,
        'elements.point.backgroundColor': tenth,
        'elements.line.borderColor': tenth,
        'elements.line.backgroundColor': tenth,
        'elements.bar.borderColor': tenth,
        'elements.bar.backgroundColor': tenth,
        'elements.arc.backgroundColor': tenth,
        'elements.arc.borderColor': const ui.Color.fromRGBO(
          255,
          255,
          255,
          1,
        ),
        ..._transitionLeaves,
      });
      expect(leaves.keys, [
        'color',
        'scale.ticks.color',
        'scale.ticks.backdropColor',
        'scale.ticks.font',
        'scale.title.color',
        'scale.title.font',
        'scale.grid.color',
        'scale.border.color',
        'scales.radialLinear.pointLabels.color',
        'scales.radialLinear.pointLabels.font',
        'scales.radialLinear.angleLines.color',
        'plugins.title.color',
        'plugins.title.font',
        'plugins.subtitle.color',
        'plugins.subtitle.font',
        'plugins.legend.labels.font',
        'plugins.legend.title.font',
        'plugins.tooltip.backgroundColor',
        'plugins.tooltip.titleColor',
        'plugins.tooltip.bodyColor',
        'plugins.tooltip.footerColor',
        'plugins.tooltip.multiKeyBackground',
        'plugins.tooltip.titleFont',
        'plugins.tooltip.bodyFont',
        'plugins.tooltip.footerFont',
        r'plugins.colors.$borderColors',
        r'plugins.colors.$backgroundColors',
        'elements.point.borderColor',
        'elements.point.backgroundColor',
        'elements.line.borderColor',
        'elements.line.backgroundColor',
        'elements.bar.borderColor',
        'elements.bar.backgroundColor',
        'elements.arc.backgroundColor',
        'elements.arc.borderColor',
        ..._transitionLeaves.keys,
      ]);
    });

    test('each color token emits its keys of theming.md §4', () {
      const red = ui.Color.fromRGBO(200, 0, 0, 1);
      final expected = <String, Map<String, Object?>>{
        'color': {
          'color': red,
          'scale.ticks.color': red,
          'scale.title.color': red,
          'scales.radialLinear.pointLabels.color': red,
          // The routes of the title color (plugin.title.js:158-160) and of
          // the subtitle color (plugin.subtitle.js:45-47).
          'plugins.title.color': red,
          'plugins.subtitle.color': red,
        },
        'borderColor': {
          'scale.grid.color': red,
          'scale.border.color': red,
          'scales.radialLinear.angleLines.color': red,
          'elements.point.borderColor': red,
          'elements.line.borderColor': red,
          'elements.bar.borderColor': red,
        },
        'backgroundColor': {
          'elements.point.backgroundColor': red,
          'elements.line.backgroundColor': red,
          'elements.bar.backgroundColor': red,
          'elements.arc.backgroundColor': red,
        },
        'surface': {
          'elements.arc.borderColor': red,
          'scale.ticks.backdropColor': const ui.Color.fromRGBO(
            200,
            0,
            0,
            0.75,
          ),
        },
        // The tooltip colors (plugin.tooltip.js:1279, 1280, 1287, 1292,
        // 1305).
        'inverseSurface': {'plugins.tooltip.backgroundColor': red},
        'onInverseSurface': {
          'plugins.tooltip.titleColor': red,
          'plugins.tooltip.bodyColor': red,
          'plugins.tooltip.footerColor': red,
          'plugins.tooltip.multiKeyBackground': red,
        },
      };
      for (final (token, compile) in _colorTokens) {
        expect(
          _leaves(compile(_red)),
          {...expected[token]!, ..._transitionLeaves},
          reason: token,
        );
      }
    });

    test('the backdrop replaces the alpha of the surface with 0.75', () {
      final leaves = _leaves(
        compileChartTheme(surface: const ui.Color.fromRGBO(0, 0, 255, 0.5)),
      );
      expect(
        leaves['elements.arc.borderColor'],
        const ui.Color.fromRGBO(0, 0, 255, 0.5),
      );
      expect(
        leaves['scale.ticks.backdropColor'],
        const ui.Color.fromRGBO(0, 0, 255, 0.75),
      );
    });

    test('a font emits its fields that are not null into each slot', () {
      final compiled = compileChartTheme(
        font: const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontStyle: ui.FontStyle.italic,
          fontWeight: ui.FontWeight.bold,
        ),
      );
      expect(_leaves(compiled), {
        'scale.ticks.font': const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontStyle: ui.FontStyle.italic,
          fontWeight: ui.FontWeight.bold,
        ),
        'scale.title.font': const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontStyle: ui.FontStyle.italic,
          fontWeight: ui.FontWeight.bold,
        ),
        'scales.radialLinear.pointLabels.font': const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontStyle: ui.FontStyle.italic,
          fontWeight: ui.FontWeight.bold,
        ),
        // No weight: the title keeps its local 'bold'
        // (plugin.title.js:148-150) and the subtitle its local 'normal'
        // (plugin.subtitle.js:35-37, theming.md §3.4).
        'plugins.title.font': const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontStyle: ui.FontStyle.italic,
        ),
        'plugins.subtitle.font': const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontStyle: ui.FontStyle.italic,
        ),
        // The legend has no font defaults (plugin.legend.js:636-712): the
        // whole font, with the weight.
        'plugins.legend.labels.font': const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontStyle: ui.FontStyle.italic,
          fontWeight: ui.FontWeight.bold,
        ),
        'plugins.legend.title.font': const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontStyle: ui.FontStyle.italic,
          fontWeight: ui.FontWeight.bold,
        ),
        // The tooltip title and footer keep their local 'bold'
        // (plugin.tooltip.js:1281-1283, 1295-1297). The body font is the
        // whole font.
        'plugins.tooltip.titleFont': const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontStyle: ui.FontStyle.italic,
        ),
        'plugins.tooltip.bodyFont': const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontStyle: ui.FontStyle.italic,
          fontWeight: ui.FontWeight.bold,
        ),
        'plugins.tooltip.footerFont': const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontStyle: ui.FontStyle.italic,
        ),
        ..._transitionLeaves,
      });
      // No root font (theming.md §3.4). A font is immutable (Chart.js ADR
      // 0116): the slots of the whole font share the token.
      expect(compiled!.jsHas('font'), isFalse);
      expect(
        _at(compiled, 'scale.ticks.font'),
        same(_at(compiled, 'scale.title.font')),
      );
    });

    test('the point-label font is the base font without size, then its '
        'token', () {
      // theming.md §3.4 and §4, the last row: upstream sets the point-label
      // size 10 locally (scale.radialLinear.js:383-385).
      Object? pointLabels({TextStyle? font, TextStyle? pointLabelsFont}) => _at(
        compileChartTheme(font: font, pointLabelsFont: pointLabelsFont),
        'scales.radialLinear.pointLabels.font',
      );

      // The token wins field by field. The base size never reaches it.
      expect(
        pointLabels(
          font: const ChartTextStyle(
            fontFamily: 'serif',
            fontFamilyFallback: [],
            fontSize: 14,
            fontStyle: ui.FontStyle.italic,
          ),
          pointLabelsFont: const ChartTextStyle(
            fontStyle: ui.FontStyle.normal,
            fontSize: 9,
          ),
        ),
        const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontStyle: ui.FontStyle.normal,
          fontSize: 9,
        ),
      );
      // The base font without the token: its fields without size. The size
      // 10 of defaults.scales.radialLinear then stays.
      expect(
        pointLabels(
          font: const ChartTextStyle(
            fontFamily: 'serif',
            fontFamilyFallback: [],
            fontSize: 14,
          ),
        ),
        const ChartTextStyle(fontFamily: 'serif', fontFamilyFallback: []),
      );
      // The token without the base font.
      expect(
        pointLabels(pointLabelsFont: const ChartTextStyle(fontSize: 9)),
        const ChartTextStyle(fontSize: 9),
      );
      // A null token field themes nothing, also over a base field.
      expect(
        pointLabels(
          font: const ChartTextStyle(
            fontFamily: 'serif',
            fontFamilyFallback: [],
            fontWeight: ui.FontWeight.bold,
          ),
          pointLabelsFont: const ChartTextStyle(height: 1.5),
        ),
        const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontWeight: ui.FontWeight.bold,
          height: 1.5,
        ),
      );
      // A base font with a size only gives no point-label font.
      final sizeOnly = compileChartTheme(
        font: const ChartTextStyle(fontSize: 14),
      );
      expect(_at(sizeOnly, 'scales'), same(undefined));
      expect((_at(sizeOnly, 'scale.ticks.font')! as TextStyle).fontSize, 14.0);
      // A token without fields themes nothing.
      expect(
        compileChartTheme(pointLabelsFont: const ChartTextStyle()),
        isNull,
      );
    });

    test('the point-label token wins over the base font', () {
      // The base fields without size, then each field of the token over
      // them (TextStyle.merge, Chart.js ADR 0116).
      final compiled = compileChartTheme(
        font: const ChartTextStyle(
          height: 1.2,
          fontSize: 14,
          fontFamily: 'serif',
          fontFamilyFallback: [],
        ),
        pointLabelsFont: const ChartTextStyle(
          fontWeight: ui.FontWeight.bold,
          fontFamily: 'mono',
          fontFamilyFallback: [],
        ),
      );
      expect(
        _at(compiled, 'scales.radialLinear.pointLabels.font'),
        const ChartTextStyle(
          height: 1.2,
          fontFamily: 'mono',
          fontFamilyFallback: [],
          fontWeight: ui.FontWeight.bold,
        ),
      );
    });

    test('the transitions come only beside other keys', () {
      // theming.md §3.3: the transitions keys alone are no theme.
      expect(compileChartTheme(), isNull);
      expect(
        _leaves(compileChartTheme(surface: _red)).keys,
        containsAll(_transitionLeaves.keys),
      );
    });

    test('the compiler does not change defaults', () {
      // theming.md §6: the theme never writes Chart.defaults.
      final before = _json(defaults);
      final overridesBefore = _json(overrides);
      for (final theme in _testThemes.values) {
        final compiled = theme();
        Config(<String, Object?>{
          'type': 'tthm',
          'data': <String, Object?>{
            'datasets': [<String, Object?>{}],
          },
          'options': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear'},
            },
          },
          themeConfigKey: compiled,
        });
      }
      expect(_json(defaults), before);
      expect(_json(overrides), overridesBefore);
    });
  });

  group('the palette', () {
    // Chart.js ADR 0050 and theming.md §4: the palette token emits the two
    // palette keys of plugins.colors. Hunk H5 of plugin.colors reads them
    // from the theme map of the chart.
    const border = r'plugins.colors.$borderColors';
    const background = r'plugins.colors.$backgroundColors';

    test('the border colors keep their alpha, the background alpha is 0.5', () {
      final compiled = compileChartTheme(palette: [_red, _blue]);
      expect(_at(compiled, border), [
        const ui.Color.fromRGBO(200, 0, 0, 1),
        const ui.Color.fromRGBO(0, 0, 255, 0.8),
      ]);
      // The alpha 0.5 of BACKGROUND_COLORS (plugin.colors.ts:25) replaces
      // the alpha of each color.
      expect(_at(compiled, background), [
        const ui.Color.fromRGBO(200, 0, 0, 0.5),
        const ui.Color.fromRGBO(0, 0, 255, 0.5),
      ]);
    });

    test('paletteBackgroundAlpha replaces the alpha of the background '
        'colors', () {
      Object? backgroundAt(double alpha) => _at(
        compileChartTheme(
          palette: [_red, _blue],
          paletteBackgroundAlpha: alpha,
        ),
        background,
      );
      // The blue screen of theming.md §8 test 6 needs alpha 1.
      expect(backgroundAt(1), [
        const ui.Color.fromRGBO(200, 0, 0, 1),
        const ui.Color.fromRGBO(0, 0, 255, 1),
      ]);
      expect(backgroundAt(0.25), [
        const ui.Color.fromRGBO(200, 0, 0, 0.25),
        const ui.Color.fromRGBO(0, 0, 255, 0.25),
      ]);
      expect(backgroundAt(0), [
        const ui.Color.fromRGBO(200, 0, 0, 0),
        const ui.Color.fromRGBO(0, 0, 255, 0),
      ]);
    });

    test('the key order and the item order', () {
      final compiled = compileChartTheme(palette: [_blue, _red, _blue])!;
      expect(_keys(compiled), ['plugins', 'transitions']);
      expect(_keys(_at(compiled, 'plugins.colors')), [
        r'$borderColors',
        r'$backgroundColors',
      ]);
      expect(_at(compiled, border), [
        const ui.Color.fromRGBO(0, 0, 255, 0.8),
        const ui.Color.fromRGBO(200, 0, 0, 1),
        const ui.Color.fromRGBO(0, 0, 255, 0.8),
      ]);
      // With the other tokens, the palette comes after the title, subtitle,
      // legend and tooltip keys of plugins.
      final light = compileLightTheme()!;
      expect(_keys(light), [
        'color',
        'scale',
        'scales',
        'plugins',
        'elements',
        'transitions',
      ]);
      expect(_keys(light['plugins']), [
        'title',
        'subtitle',
        'legend',
        'tooltip',
        'colors',
      ]);
    });

    test('the palette Lists are frozen', () {
      final compiled = compileLightTheme();
      for (final path in [border, background]) {
        final list = _at(compiled, path)! as List<Object?>;
        expect(list, isA<JsFreezable>(), reason: path);
        expect(jsObjectIsFrozen(list), isTrue, reason: path);
        expect(() => list[0] = 'red', throwsA(isA<TypeError>()));
        expect(() => list.add('red'), throwsA(isA<TypeError>()));
        expect(() => list.length = 0, throwsA(isA<TypeError>()));
        expect(list, hasLength(7), reason: path);
      }
      expect(
        _at(compiled, 'plugins.colors'),
        isA<JsFreezable>().having(jsObjectIsFrozen, 'frozen', isTrue),
      );
    });

    test('a null or empty palette emits nothing', () {
      for (final palette in [null, <ui.Color>[]]) {
        for (final alpha in [0.5, 0.3, 1.0]) {
          expect(
            compileChartTheme(palette: palette, paletteBackgroundAlpha: alpha),
            isNull,
          );
          // Beside another token, no plugins.colors key.
          final compiled = compileChartTheme(
            surface: _red,
            palette: palette,
            paletteBackgroundAlpha: alpha,
          );
          expect(_at(compiled, 'plugins'), same(undefined));
        }
      }
    });

    test('a palette alone also emits the transitions', () {
      final leaves = _leaves(compileChartTheme(palette: [_red]));
      expect(leaves, {
        border: [const ui.Color.fromRGBO(200, 0, 0, 1)],
        background: [const ui.Color.fromRGBO(200, 0, 0, 0.5)],
        ..._transitionLeaves,
      });
    });

    test('the light palette restates BORDER_COLORS and BACKGROUND_COLORS', () {
      // plugin.colors.ts:14-25. The border strings parse to the upstream
      // strings. The background strings are equal.
      final compiled = compileLightTheme();
      final borders = _at(compiled, border)! as List<Object?>;
      expect(borders, hasLength(_upstreamBorderColors.length));
      for (var i = 0; i < borders.length; i++) {
        expect(
          referenceParsedColor(borders[i]).rgbString(),
          referenceParsedColor(_upstreamBorderColors[i]).rgbString(),
          reason: '$i',
        );
        expect(
          referenceParsedColor(borders[i]).rgbString(),
          referenceParsedColor(_upstreamBorderColors[i]).rgbString(),
          reason: '$i',
        );
      }
      expect(_at(compiled, background), _upstreamBackgroundColors);
      expect(
        _upstreamBackgroundColors.first,
        const ui.Color.fromRGBO(54, 162, 235, 0.5),
      );
    });
  });

  group('the title keys', () {
    test('the title font has no weight', () {
      // theming.md §3.4: the title keeps its local weight 'bold'
      // (plugin.title.js:148-150).
      final compiled = compileChartTheme(
        font: const ChartTextStyle(
          fontWeight: ui.FontWeight.bold,
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontSize: 14,
        ),
      );
      expect(
        (_at(compiled, 'scale.ticks.font')! as TextStyle).fontWeight,
        ui.FontWeight.bold,
      );
      final font = _at(compiled, 'plugins.title.font')! as TextStyle;
      expect(
        font,
        const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontSize: 14,
        ),
      );
      // A font with a weight only gives no title font. The legend fonts and
      // the tooltip body font keep the weight (the groups `the subtitle and
      // legend keys` and `the tooltip keys`).
      final weightOnly = compileChartTheme(
        font: const ChartTextStyle(fontWeight: ui.FontWeight.bold),
      );
      expect(
        (_at(weightOnly, 'scale.ticks.font')! as TextStyle).fontWeight,
        ui.FontWeight.bold,
      );
      expect(_at(weightOnly, 'plugins.title'), same(undefined));
      expect(_keys(_at(weightOnly, 'plugins')), [
        'legend',
        'tooltip',
      ]);
    });

    test('the title color is the color token', () {
      // The route of the title color (plugin.title.js:158-160).
      final compiled = compileChartTheme(color: _blue);
      expect(
        _at(compiled, 'plugins.title.color'),
        const ui.Color.fromRGBO(0, 0, 255, 0.8),
      );
      expect(
        _keys(_at(compiled, 'plugins.title')),
        ['color'],
      );
      // The legend reads the root color (plugin.legend.js:661, 707).
      expect(_at(compiled, 'plugins.legend'), same(undefined));
      expect(_keys(_at(compiled, 'plugins')), [
        'title',
        'subtitle',
      ]);
    });

    test('a title text fails the guard, a title color and position pass', () {
      // Rule 2b (plugin.title.js:43, 97).
      expect(
        themeNeverEmittedReason(_path('plugins.title.text'), 'Title'),
        'plugins.title.text is a behavior key',
      );
      for (final (path, value) in [
        ('plugins.title.color', const ui.Color.fromRGBO(0, 0, 255, 1)),
        ('plugins.title.position', ChartPosition.bottom),
      ]) {
        expect(themeNeverEmittedReason(_path(path), value), isNull);
      }
    });
  });

  group('the subtitle and legend keys', () {
    // theming.md §4 (Chart.js ADR 0050): the subtitle takes the color token
    // and the font token without weight, as the title. The legend takes the
    // whole font token into its two fonts and no color key.
    const serifBold = ChartTextStyle(
      fontFamily: 'serif',
      fontFamilyFallback: [],
      fontWeight: ui.FontWeight.bold,
      fontSize: 14,
      height: 1.5,
    );

    test('the subtitle color is the color token', () {
      // The route of the subtitle color (plugin.subtitle.js:45-47).
      final compiled = compileChartTheme(color: _blue);
      expect(
        _at(compiled, 'plugins.subtitle.color'),
        const ui.Color.fromRGBO(0, 0, 255, 0.8),
      );
      expect(
        _keys(_at(compiled, 'plugins.subtitle')),
        ['color'],
      );
      // The other color tokens give no subtitle key.
      for (final (token, compile) in _colorTokens) {
        if (!['borderColor', 'backgroundColor', 'surface'].contains(token)) {
          continue;
        }
        expect(_at(compile(_blue), 'plugins'), same(undefined), reason: token);
      }
    });

    test('the subtitle font has no weight', () {
      // theming.md §3.4: the subtitle keeps its local weight 'normal'
      // (plugin.subtitle.js:35-37).
      final compiled = compileChartTheme(font: serifBold);
      final font = _at(compiled, 'plugins.subtitle.font')!;
      expect(
        font,
        const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontSize: 14,
          height: 1.5,
        ),
      );
      // A font with a weight only gives no subtitle font.
      final weightOnly = compileChartTheme(
        font: const ChartTextStyle(fontWeight: ui.FontWeight.bold),
      );
      expect(_at(weightOnly, 'plugins.subtitle'), same(undefined));
    });

    test('the two legend fonts are the whole font token', () {
      // The legend has no font defaults (plugin.legend.js:636-712). toFont
      // fills an absent field from defaults.font (helpers.options.ts:115-117)
      // for the label font (plugin.legend.js:136, 288) and the title font
      // (:446, 495).
      final compiled = compileChartTheme(font: serifBold);
      final labels = _at(compiled, 'plugins.legend.labels.font')!;
      final title = _at(compiled, 'plugins.legend.title.font')!;
      expect(
        labels,
        const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontWeight: ui.FontWeight.bold,
          fontSize: 14,
          height: 1.5,
        ),
      );
      expect(title, same(labels));
      // The legend gets no other key: no color (plugin.legend.js:661, 707
      // read the root color) and no point-label size rule.
      expect(_leaves(_at(compiled, 'plugins.legend')).keys, [
        'labels.font',
        'title.font',
      ]);
      // A font is immutable (Chart.js ADR 0116): the slots share the token.
      expect(labels, same(_at(compiled, 'scale.ticks.font')));
    });

    test('the plugins keys come after scales, in one order', () {
      // A font-only theme also puts the root key plugins after scales.
      final font = compileChartTheme(font: serifBold)!;
      expect(_keys(font), ['scale', 'scales', 'plugins', 'transitions']);
      expect(_keys(jsGet(font, 'plugins')), [
        'title',
        'subtitle',
        'legend',
        'tooltip',
      ]);
      final both = compileChartTheme(color: _red, font: serifBold)!;
      expect(_keys(both), [
        'color',
        'scale',
        'scales',
        'plugins',
        'transitions',
      ]);
      expect(_keys(both['plugins']), [
        'title',
        'subtitle',
        'legend',
        'tooltip',
      ]);
      expect(_keys(_at(both, 'plugins.subtitle')), [
        'color',
        'font',
      ]);
    });

    test('a raw subtitle text fails the guard, the token keys pass', () {
      // Rule 2b (plugin.title.js:43, 97 for the Title of the subtitle).
      expect(
        themeNeverEmittedReason(_path('plugins.subtitle.text'), 'Subtitle'),
        'plugins.subtitle.text is a behavior key',
      );
      for (final path in [
        'plugins.subtitle.color',
        'plugins.subtitle.font',
        'plugins.legend.labels.font',
        'plugins.legend.title.font',
      ]) {
        expect(
          themeNeverEmittedReason(_path(path), <String, Object?>{}),
          isNull,
          reason: path,
        );
      }
      // Each emitted key of the light preset passes the guard.
      final light = compileLightTheme();
      for (final MapEntry(key: path, :value) in _leaves(
        _at(light, 'plugins'),
      ).entries) {
        expect(
          themeNeverEmittedReason(_path('plugins.$path'), value),
          isNull,
          reason: path,
        );
      }
    });
  });

  group('the tooltip keys', () {
    // theming.md §4 (Chart.js ADR 0050): the token inverseSurface gives the
    // tooltip background, the token onInverseSurface the four tooltip text
    // and key colors. The tooltip body font is the whole font token. The
    // title and footer fonts are the font token without weight.
    const tooltipColors = [
      'backgroundColor',
      'titleColor',
      'bodyColor',
      'footerColor',
      'multiKeyBackground',
    ];
    const serifBold = ChartTextStyle(
      fontFamily: 'serif',
      fontFamilyFallback: [],
      fontWeight: ui.FontWeight.bold,
      fontSize: 14,
      height: 1.5,
    );

    test('inverseSurface is the tooltip background', () {
      // plugin.tooltip.js:1279.
      final compiled = compileChartTheme(inverseSurface: _blue);
      expect(_leaves(compiled), {
        'plugins.tooltip.backgroundColor': const ui.Color.fromRGBO(
          0,
          0,
          255,
          0.8,
        ),
        ..._transitionLeaves,
      });
      expect(_keys(compiled), ['plugins', 'transitions']);
    });

    test('onInverseSurface is the tooltip text and key color', () {
      // plugin.tooltip.js:1280, 1287, 1292, 1305.
      final compiled = compileChartTheme(onInverseSurface: _blue);
      expect(_leaves(compiled), {
        'plugins.tooltip.titleColor': const ui.Color.fromRGBO(
          0,
          0,
          255,
          0.8,
        ),
        'plugins.tooltip.bodyColor': const ui.Color.fromRGBO(
          0,
          0,
          255,
          0.8,
        ),
        'plugins.tooltip.footerColor': const ui.Color.fromRGBO(
          0,
          0,
          255,
          0.8,
        ),
        'plugins.tooltip.multiKeyBackground': const ui.Color.fromRGBO(
          0,
          0,
          255,
          0.8,
        ),
        ..._transitionLeaves,
      });
      // The other color tokens give no tooltip key. The tooltip border
      // color 'rgba(0,0,0,0)' (plugin.tooltip.js:1308) has no token.
      for (final (token, compile) in _colorTokens.take(4)) {
        expect(
          _leaves(
            compile(_blue),
          ).keys.where((path) => path.startsWith('plugins.tooltip.')),
          isEmpty,
          reason: token,
        );
      }
    });

    test('the light preset gives the upstream tooltip colors', () {
      // 'rgba(0,0,0,0.8)' and '#fff' (plugin.tooltip.js:1279, 1280, 1287,
      // 1292, 1305) after the parse of the ported @kurkle/color.
      final compiled = compileLightTheme();
      expect(
        _at(compiled, 'plugins.tooltip.backgroundColor'),
        const ui.Color.fromRGBO(0, 0, 0, 0.8),
      );
      expect(
        referenceParsedColor(_at(compiled, 'plugins.tooltip.backgroundColor'))
            .rgbString(),
        referenceParsedColor('rgba(0,0,0,0.8)').rgbString(),
      );
      for (final key in tooltipColors.skip(1)) {
        expect(
          referenceParsedColor(_at(compiled, 'plugins.tooltip.$key'))
              .rgbString(),
          referenceParsedColor('#fff').rgbString(),
          reason: key,
        );
      }
      expect(_at(compiled, 'plugins.tooltip.borderColor'), same(undefined));
    });

    test('the body font is the whole font token', () {
      // plugin.tooltip.js:1289-1290: no local field.
      final compiled = compileChartTheme(font: serifBold);
      final font = _at(compiled, 'plugins.tooltip.bodyFont')!;
      expect(
        font,
        const ChartTextStyle(
          fontFamily: 'serif',
          fontFamilyFallback: [],
          fontWeight: ui.FontWeight.bold,
          fontSize: 14,
          height: 1.5,
        ),
      );
      expect(font, same(_at(compiled, 'scale.ticks.font')));
    });

    test('the title and footer fonts have no weight', () {
      // theming.md §3.4: the tooltip title and footer keep their local
      // weight 'bold' (plugin.tooltip.js:1281-1283, 1295-1297).
      final compiled = compileChartTheme(font: serifBold);
      for (final key in ['titleFont', 'footerFont']) {
        final font = _at(compiled, 'plugins.tooltip.$key')!;
        expect(
          font,
          const ChartTextStyle(
            fontFamily: 'serif',
            fontFamilyFallback: [],
            fontSize: 14,
            height: 1.5,
          ),
          reason: key,
        );
      }
      // A font with a weight only gives the body font only.
      final weightOnly = compileChartTheme(
        font: const ChartTextStyle(fontWeight: ui.FontWeight.bold),
      );
      expect(_leaves(_at(weightOnly, 'plugins.tooltip')), {
        'bodyFont': const ChartTextStyle(fontWeight: ui.FontWeight.bold),
      });
    });

    test('the tooltip keys come after the legend keys, in one order', () {
      // The colors and then the fonts, in each theme.
      final compiled = compileChartTheme(
        onInverseSurface: _red,
        color: _red,
        inverseSurface: _blue,
        font: serifBold,
        palette: [_red],
      )!;
      expect(_keys(compiled['plugins']), [
        'title',
        'subtitle',
        'legend',
        'tooltip',
        'colors',
      ]);
      expect(_keys(_at(compiled, 'plugins.tooltip')), [
        ...tooltipColors,
        'titleFont',
        'bodyFont',
        'footerFont',
      ]);
      // The same order without the other tokens.
      final tooltipOnly = compileChartTheme(
        onInverseSurface: _red,
        font: serifBold,
      )!;
      expect(_keys(tooltipOnly['plugins']), [
        'title',
        'subtitle',
        'legend',
        'tooltip',
      ]);
      expect(
        _keys(_at(tooltipOnly, 'plugins.tooltip')),
        [...tooltipColors.skip(1), 'titleFont', 'bodyFont', 'footerFont'],
      );
    });

    test('the tooltip token keys pass the guard, the position fails', () {
      for (final key in [...tooltipColors, 'titleFont', 'bodyFont']) {
        expect(
          themeNeverEmittedReason(_path('plugins.tooltip.$key'), 'x'),
          isNull,
          reason: key,
        );
      }
      expect(
        themeNeverEmittedReason(_path('plugins.tooltip.footerFont.size'), 9.0),
        isNull,
      );
      // Rule 2b (plugin.tooltip.js:651, 1012, 1218) and rule 2.
      expect(
        themeNeverEmittedReason(_path('plugins.tooltip.position'), 'nearest'),
        'plugins.tooltip.position is a behavior key',
      );
      expect(
        themeNeverEmittedReason(_path('plugins.tooltip.mode'), 'index'),
        'plugins.tooltip.mode is a behavior key',
      );
    });
  });

  group('the emission guard', () {
    test('each rule of the never-emitted list of theming.md §3.3', () {
      final rejected = <(String, Object?, String)>[
        ('backgroundColor', 'red', 'a root backgroundColor'),
        ('borderColor', 'red', 'a root borderColor'),
        ('font', <String, Object?>{}, 'a root font'),
        ('elements.bar.hoverBackgroundColor', 'red', 'static hover color'),
        ('elements.point.hoverBorderColor', 'red', 'static hover color'),
        ('hoverColor', 'red', 'static hover color'),
        ('elements.line.pointHoverBackgroundColor', 'red', 'hover color'),
        ('barHoverBorderColor', 'red', 'static hover color'),
        for (final key in themeBehaviorKeys) (key, 1.0, 'behavior key'),
        // The hover scopes resolve before every interaction scope.
        ('hover', <String, Object?>{}, 'hover is a behavior key'),
        ('hover.mode', 'dataset', 'hover is a behavior key'),
        ('hover.intersect', false, 'hover is a behavior key'),
        // The tooltip resolves the interaction keys from plugins.tooltip
        // first.
        ('plugins.tooltip.mode', 'dataset', 'tooltip.mode is a behavior key'),
        for (final key in themeTooltipInteractionKeys)
          ('plugins.tooltip.$key', 1.0, 'tooltip.$key is a behavior key'),
        ('plugins.tooltip.interaction', <String, Object?>{}, 'behavior'),
        ('plugins.tooltip.enabled', false, 'enabled is a behavior key'),
        ('plugins.colors.forceOverride', true, 'behavior key'),
        ('scale.grid.display', false, 'display is a behavior key'),
        ('transitions.theme.animation.duration', 1.0, 'behavior key'),
        ('datasets.bar.backgroundColor', 'red', 'behavior key'),
        ('layout.padding', 4.0, 'layout is a behavior key'),
        ('plugins.legend', false, 'plugins.legend: bool'),
        ('plugins.legend', true, 'plugins.legend: bool'),
        ('scales.x', <String, Object?>{}, 'scales.x is not a scale type'),
        ('scales.y.grid.color', 'red', 'scales.y is not a scale type'),
        ('scales.myScale', <String, Object?>{}, 'not a scale type'),
        // A scale id, not a scale type: the radial scale of a radar chart.
        ('scales.r.pointLabels.color', 'red', 'scales.r is not a scale type'),
        ('scales.radial.angleLines.color', 'red', 'not a scale type'),
        // The fill, line, bar and scale keys change the fill target, the
        // segments, the dataset element, the bar geometry, the data range or
        // the ticks (Chart.js ADR 0050).
        ('elements.line.fill', 'origin', 'fill is a behavior key'),
        ('fill', 'origin', 'fill is a behavior key'),
        ('spanGaps', true, 'spanGaps is a behavior key'),
        ('elements.line.spanGaps', true, 'spanGaps'),
        ('showLine', true, 'showLine is a behavior key'),
        ('scale.stacked', true, 'stacked is a behavior key'),
        ('scales.linear.reverse', true, 'reverse is a behavior key'),
        ('scale.min', 0.0, 'min is a behavior key'),
        ('scale.beginAtZero', true, 'beginAtZero is a behavior key'),
        ('scale.grace', '50%', 'grace is a behavior key'),
        ('scale.bounds', ScaleBounds.data, 'bounds'),
        ('base', 2.0, 'base'),
        ('skipNull', true, 'skipNull'),
        ('grouped', false, 'grouped'),
        // The behavior paths of the tooltip, the legend and the scales.
        (
          'plugins.tooltip.xAlign',
          'right',
          'plugins.tooltip.xAlign is a behavior key',
        ),
        (
          'plugins.tooltip.yAlign',
          'top',
          'plugins.tooltip.yAlign is a behavior key',
        ),
        ('plugins.legend.rtl', true, 'plugins.legend.rtl is a behavior key'),
        ('scale.title.text', 'x', 'scale.title.text is a behavior key'),
        (
          'scales.category.title.text',
          'x',
          'scale.title.text is a behavior key',
        ),
        (
          'scales.category.labels',
          <Object?>['p'],
          'scale.labels is a behavior key',
        ),
        ('scale.ticks.stepSize', 0.25, 'scale.ticks.stepSize'),
        (
          'scales.linear.ticks.maxTicksLimit',
          3.0,
          'scale.ticks.maxTicksLimit',
        ),
        ('scales.radialLinear.pointLabels.hoverColor', 'red', 'hover color'),
        ('scales.radialLinear.angleLines._fallback', 'grid', 'descriptor'),
        ('elements.bar._fallback', 'x', 'read as a descriptor'),
        ('_scriptable', false, 'read as a descriptor'),
        (r'$theme', <String, Object?>{}, r'a $ key other than the palette'),
        (r'plugins.colors.$palette', <Object?>[], r'a $ key'),
        (r'plugins.legend.$borderColors', <Object?>[], r'a $ key'),
        (r'elements.bar.$shared', true, r'a $ key'),
        ('elements.bar.backgroundColor', null, 'null is a JS value'),
        ('color', undefined, 'undefined is no value'),
        ('scale.ticks.callback', (Object? v) => v, 'a function'),
        // Rule 2b: the plugin behavior paths and the paths below them
        // (Chart.js ADR 0050).
        for (final path in themePluginBehaviorPaths)
          (path, 1.0, '$path is a behavior key'),
        ('plugins.title.text.0', 'a line', 'title.text is a behavior key'),
        (
          'plugins.legend.title.text',
          'x',
          'plugins.legend.title.text is a behavior key',
        ),
        // Rule 9: a palette is a List with at least one item.
        (r'plugins.colors.$borderColors', <Object?>[], 'a palette is a List'),
        (r'plugins.colors.$backgroundColors', <Object?>[], 'a palette'),
        (r'plugins.colors.$borderColors', 'red', 'a palette is a List'),
        (
          r'plugins.colors.$backgroundColors',
          <String, Object?>{'0': 'red'},
          'a palette is a List with at least one item',
        ),
        (r'plugins.colors.$borderColors', 1.0, 'a palette is a List'),
      ];
      for (final (path, value, reason) in rejected) {
        expect(
          themeNeverEmittedReason(_path(path), value),
          contains(reason),
          reason: path,
        );
      }
    });

    test('the keys that the guard accepts', () {
      final accepted = <(String, Object?)>[
        ('color', 'red'),
        ('elements.arc.borderColor', 'red'),
        ('elements.bar.borderWidth', 2.0),
        ('elements.bar', <String, Object?>{}),
        ('scale.ticks.backdropColor', 'red'),
        ('scale.ticks.textStrokeColor', 'red'),
        ('plugins.tooltip.borderColor', 'red'),
        ('plugins.tooltip', <String, Object?>{}),
        // Only a key `hover` is a behavior key, not a key with a hover
        // prefix. Only plugins.tooltip resolves the interaction scopes.
        ('elements.point.hoverRadius', 4.0),
        ('elements.bar.hoverBorderWidth', 2.0),
        ('plugins.legend.labels.mode', 'x'),
        ('plugins.legend.labels.font', <String, Object?>{}),
        (r'plugins.colors.$borderColors', <Object?>['red']),
        (r'plugins.colors.$backgroundColors', <Object?>['red']),
        (r'plugins.colors.$backgroundColors.0', 'red'),
        // Rule 2b holds paths, not flat names. The layout keys of a plugin
        // box, its colors and the fonts move only the layout, and the draw
        // order of the filler pass changes only the draw. The guard passes
        // them, and no public input reaches the box layout keys or the draw
        // order (Chart.js ADR 0050, "No public `raw` in 0.1.0"). The labels
        // key of the legend holds its colors and fonts: `labels` is not a
        // flat behavior key.
        ('plugins.title', <String, Object?>{}),
        ('plugins.title.color', 'red'),
        ('plugins.title.font', <String, Object?>{}),
        ('plugins.title.position', ChartPosition.bottom),
        ('plugins.title.align', 'start'),
        ('plugins.legend.position', ChartPosition.left),
        ('plugins.legend.title', <String, Object?>{}),
        ('plugins.legend.title.color', 'red'),
        ('plugins.legend.labels.color', 'red'),
        ('plugins.decimation', <String, Object?>{}),
        ('plugins.filler.drawTime', 'beforeDraw'),
        ('plugins.tooltip.backgroundColor', 'red'),
        // The text direction of the tooltip changes only the draw
        // (plugin.tooltip.js:762-776, Chart.js ADR 0034).
        ('plugins.tooltip.rtl', true),
        // A scale font moves only the layout: the data range and the ticks
        // stay.
        ('scale.ticks.font', <String, Object?>{}),
        ('position', 'x'),
        ('elements.text', 'x'),
        for (final type in themeScaleTypes) ('scales.$type.grid.color', 'red'),
        ('scales.radialLinear.pointLabels.color', 'red'),
        ('scales.radialLinear.angleLines.color', 'red'),
        ('scales.radialLinear.pointLabels.font', <String, Object?>{}),
        ('scales.radialLinear.pointLabels.font.size', 10.0),
        ('scales', <String, Object?>{}),
        ('elements.line.borderDash', <Object?>[4.0, 2.0]),
        ('elements.line.borderDash.0', 4.0),
        ('transitions.theme.note', 'x'),
      ];
      for (final (path, value) in accepted) {
        expect(
          themeNeverEmittedReason(_path(path), value),
          isNull,
          reason: path,
        );
      }
    });

    test('the scale types are those of v4.5.1', () {
      expect(themeScaleTypes, {
        'category',
        'linear',
        'logarithmic',
        'radialLinear',
        'time',
        'timeseries',
      });
    });

    test('the plugin behavior paths of Chart.js ADR 0050', () {
      expect(themePluginBehaviorPaths, {
        'plugins.decimation.algorithm',
        'plugins.decimation.samples',
        'plugins.decimation.threshold',
        'plugins.filler.propagate',
        'plugins.legend.reverse',
        'plugins.tooltip.position',
        'plugins.title.text',
        'plugins.subtitle.text',
        'plugins.legend.title.text',
        'plugins.tooltip.xAlign',
        'plugins.tooltip.yAlign',
        'plugins.legend.rtl',
        'scale.title.text',
        'scale.labels',
        'scale.ticks.stepSize',
        'scale.ticks.count',
        'scale.ticks.precision',
        'scale.ticks.maxTicksLimit',
      });
    });
  });

  group('the deep freeze', () {
    test('each scope and List of the result is frozen', () {
      final compiled = compileLightTheme()!;
      final nodes = _nodes(compiled).toList();
      expect(nodes.length, greaterThan(10));
      for (final (path, node) in nodes) {
        expect(node, isA<JsFreezable>(), reason: path);
        expect(jsObjectIsFrozen(node), isTrue, reason: path);
      }
    });

    test('a write throws a TypeError', () {
      final compiled = compileLightTheme()!;
      final ticks = _at(compiled, 'scale.ticks')! as JsObjectFace;
      expect(() => compiled['color'] = 'x', throwsA(isA<TypeError>()));
      expect(() => compiled['other'] = 'x', throwsA(isA<TypeError>()));
      expect(() => ticks['color'] = 'x', throwsA(isA<TypeError>()));
      expect(() => ticks.jsDelete('color'), throwsA(isA<TypeError>()));
      expect(ticks.jsDelete('absent'), isFalse);
      expect(
        _at(compiled, 'scale.ticks.color'),
        const ui.Color.fromRGBO(102, 102, 102, 1),
      );

      final palette =
          _at(compiled, r'plugins.colors.$borderColors')! as List<Object?>;
      expect(() => palette[0] = _red, throwsA(isA<TypeError>()));
      expect(() => palette.add(_red), throwsA(isA<TypeError>()));
      expect(() => palette.length = 0, throwsA(isA<TypeError>()));
      expect(palette, _upstreamBorderColors);
    });

    test('a resolver write into a theme scope throws', () {
      // theming.md §3.3: without plugins.<id> in the options and the
      // overrides, the theme map is scopes[0], the target of the set trap.
      final compiled = compileLightTheme();
      final config = Config(<String, Object?>{
        'type': 'tthm',
        'options': <String, Object?>{},
        themeConfigKey: compiled,
      });
      final scopes = config.getOptionScopes(
        undefined,
        config.pluginScopeKeys(<String, Object?>{'id': 'tooltip'}),
      );
      expect(scopes.first, same(_at(compiled, 'plugins.tooltip')));
      final resolver = config.createResolver(scopes, <String, Object?>{});
      expect(
        resolver['backgroundColor'],
        const ui.Color.fromRGBO(0, 0, 0, 0.8),
      );
      expect(
        () => resolver['backgroundColor'] = 'x',
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('no memo (Chart.js ADR 0054 §4)', () {
    test('the same tokens compile again to an equal result', () {
      final first = compileChartTheme(color: _red);
      final second = compileChartTheme(color: _red);
      expect(second, isNot(same(first)));
      expect(_json(second), _json(first));
      expect(
        _json(compileLightTheme()),
        _json(compileLightTheme()),
      );
    });

    test('tokens that compile to null stay null', () {
      expect(compileChartTheme(), isNull);
      expect(compileChartTheme(), isNull);
    });
  });

  group('theming.md §8 test 1', () {
    late Map<String, Object?> dataset;
    late Map<String, Object?> options;

    setUp(() {
      defaults.override('tthm', <String, Object?>{
        'elements': <String, Object?>{
          'point': <String, Object?>{'o': 1.0},
        },
      });
      dataset = <String, Object?>{'data': <Object?>[]};
      options = <String, Object?>{};
    });

    Config config(Object? theme) => Config(<String, Object?>{
      'type': 'tthm',
      'data': <String, Object?>{
        'datasets': [dataset],
      },
      'options': options,
      themeConfigKey: theme,
    });

    String Function(Object?) labels(Config c, Object? theme) => _labeller([
      (dataset, 'dataset'),
      (options, 'options'),
      (overrides['tthm'], 'overrides.tthm'),
      (_at(overrides, 'tthm.elements.point'), 'overrides.tthm.elements.point'),
      (theme, 'theme'),
      if (theme != null) ...[
        (_at(theme, 'elements.point'), 'theme.elements.point'),
        (_at(theme, 'transitions.theme'), 'theme.transitions.theme'),
        (_at(theme, 'transitions.themeFrame'), 'theme.transitions.themeFrame'),
      ],
      (defaults, 'defaults'),
      (_at(defaults, 'transitions'), 'defaults.transitions'),
      (descriptors, 'descriptors'),
    ]);

    test('no token compiles to null', () {
      expect(compileChartTheme(), isNull);
    });

    test('no token adds no scope', () {
      final c = config(compileChartTheme());
      final label = labels(c, null);
      expect(
        c
            .getOptionScopes(
              dataset,
              c.datasetElementScopeKeys('tthm', 'point'),
            )
            .map(label),
        [
          'dataset',
          'options',
          'overrides.tthm.elements.point',
          'overrides.tthm',
          'defaults',
          'descriptors',
        ],
      );
      expect(c.chartOptionScopes().map(label), [
        'options',
        'overrides.tthm',
        '{}#0',
        '?{"type":"tthm"}',
        'defaults',
        'descriptors',
      ]);
    });

    test('a compiled theme comes between the overrides and the defaults', () {
      final theme = compileLightTheme();
      final c = config(theme);
      final label = labels(c, theme);
      expect(
        c
            .getOptionScopes(
              dataset,
              c.datasetElementScopeKeys('tthm', 'point'),
            )
            .map(label),
        [
          'dataset',
          'options',
          'overrides.tthm.elements.point',
          'overrides.tthm',
          'theme.elements.point',
          'theme',
          'defaults',
          'descriptors',
        ],
      );
      expect(c.chartOptionScopes().map(label), [
        'options',
        'overrides.tthm',
        'theme',
        '{}#0',
        '?{"type":"tthm"}',
        'defaults',
        'descriptors',
      ]);
      expect(
        c
            .getOptionScopes(
              dataset,
              c.datasetAnimationScopeKeys('tthm', 'theme'),
            )
            .map(label),
        [
          'dataset',
          'theme.transitions.theme',
          'options',
          'overrides.tthm',
          'theme',
          'defaults',
          'descriptors',
        ],
      );
    });

    test('the theme transitions reach the animation options', () {
      // theming.md §3.8 and Chart.js ADR 0019 §10: the resolver reads
      // transitions.theme through datasetAnimationScopeKeys.
      Object? animation(Object? theme, String mode, String key) {
        final c = config(theme);
        final scopes = c.getOptionScopes(
          dataset,
          c.datasetAnimationScopeKeys('tthm', mode),
        );
        return _at(c.createResolver(scopes, <String, Object?>{}), key);
      }

      final theme = compileLightTheme();
      expect(animation(theme, 'theme', 'animation.duration'), 200.0);
      expect(animation(theme, 'theme', 'animation.easing'), Curves.linear);
      expect(animation(theme, 'themeFrame', 'animation.duration'), 0.0);
      expect(
        animation(theme, 'themeFrame', 'animation.easing'),
        Curves.easeOutQuart,
      );
      // The other modes keep the upstream values.
      expect(animation(theme, 'active', 'animation.duration'), 400.0);
      expect(animation(theme, 'default', 'animation.duration'), 1000.0);
      // No theme: the upstream defaults (core.animations.defaults.js:4-5).
      expect(animation(null, 'theme', 'animation.duration'), 1000.0);
      expect(
        animation(null, 'theme', 'animation.easing'),
        Curves.easeOutQuart,
      );
    });
  });

  group('theming.md §8 test 5, without a chart', () {
    test('the presets and the test themes compile only to allowed paths', () {
      for (final name in _testThemes.keys) {
        final compiled = _testThemes[name]!()!;
        final leaves = _leaves(compiled);
        for (final MapEntry(key: path, :value) in leaves.entries) {
          if (_transitionLeaves.containsKey(path)) {
            expect(value, _transitionLeaves[path], reason: '$name: $path');
            continue;
          }
          expect(
            themeNeverEmittedReason(_path(path), value),
            isNull,
            reason: '$name: $path',
          );
        }
        for (final (path, node) in _nodes(compiled)) {
          if (path.isEmpty || path.startsWith('transitions')) continue;
          expect(
            themeNeverEmittedReason(_path(path), node),
            isNull,
            reason: '$name: $path',
          );
        }
        expect(
          leaves.keys.where((path) => path.startsWith('transitions')),
          _transitionLeaves.keys,
          reason: name,
        );
      }
    });

    test('a themed scales.<id> fails the emission guard', () {
      expect(
        themeNeverEmittedReason(['scales', 'x'], <String, Object?>{}),
        'scales.x is not a scale type',
      );
    });

    test('a themed scales.radialLinear creates no axis', () {
      // On a chart type with an index and a value scale, as a bar chart,
      // and on a chart type without scales, as a doughnut chart.
      defaults
        ..override('tbar', <String, Object?>{
          'scales': <String, Object?>{
            '_index_': <String, Object?>{'type': 'tcat'},
            '_value_': <String, Object?>{'type': 'tlin'},
          },
        })
        ..override('tdough', <String, Object?>{});
      // The light preset themes scales.radialLinear.
      final theme = compileLightTheme();
      expect(_at(theme, 'scales.radialLinear'), isNotNull);
      Object? scales(String type) => Config(<String, Object?>{
        'type': type,
        'data': <String, Object?>{
          'datasets': [<String, Object?>{}],
        },
        'options': <String, Object?>{},
        themeConfigKey: theme,
      }).options;

      expect(jsObjectKeys(jsGet(scales('tbar'), 'scales')), ['x', 'y']);
      expect(_plain(jsGet(scales('tdough'), 'scales')), <String, Object?>{});
    });
  });
}
