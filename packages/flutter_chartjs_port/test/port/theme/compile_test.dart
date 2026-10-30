// Original code, not ported from Chart.js: tests of the theme compiler.
import 'dart:convert';

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/color.dart' show Color;
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:test/test.dart';

// The theme compiler has no upstream counterpart (Chart.js ADR 0050). These
// tests cover theming.md §3.3 (the emitted keys, the never-emitted list as
// the emission guard, the rgba() form, the deep freeze and the memo), §3.4
// and §4 (the token keys, the point-label font, the title, subtitle, legend
// and tooltip keys and the palette of Chart.js ADR 0050), §8
// test 1 (no theme equals upstream: ChartThemes.none, no extra scope, the
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
/// `"<undefined>"`, a function gives `"<fn>"` and a [RawThemeColor] gives
/// its rgba() string in angle brackets. The form is the same on every
/// platform.
String _json(Object? value) => switch (value) {
  null => 'null',
  Undefined() => '"<undefined>"',
  final bool b => b ? 'true' : 'false',
  final num n => jsNumberToString(n),
  final String s => jsonEncode(s),
  _ when jsIsFunction(value) => '"<fn>"',
  final RawThemeColor color => '"<${themeColorToRgba(color)}>"',
  final List<Object?> list => '[${list.map(_json).join(',')}]',
  final Map<String, Object?> map =>
    '{${jsObjectKeys(map).map((k) => _entry(map, k)).join(',')}}',
  _ => throw ArgumentError.value(value, 'value', 'has no JSON form'),
};

/// The JSON member `"key":value` of [key] in [map].
String _entry(Map<String, Object?> map, String key) =>
    '${jsonEncode(key)}:${_json(map[key])}';

/// The leaves of [value] by dot path, in key order. A List is a leaf.
Map<String, Object?> _leaves(Object? value, [String prefix = '']) {
  if (value is! Map<String, Object?>) return {prefix: value};
  return {
    for (final key in value.keys)
      ..._leaves(value[key], prefix.isEmpty ? key : '$prefix.$key'),
  };
}

/// Every Map and List node of [value] with its dot path, the root first.
Iterable<(String, Object)> _nodes(Object? value, [String path = '']) sync* {
  if (value is Map<String, Object?>) {
    yield (path, value);
    for (final key in value.keys) {
      yield* _nodes(value[key], path.isEmpty ? key : '$path.$key');
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
  'transitions.theme.animation.easing': 'linear',
  'transitions.themeFrame.animation.duration': 0.0,
};

/// A raw theme with the color token [token] only.
Map<String, Object?> _colorTheme(String token, RawThemeColor color) => {
  'colors': <String, Object?>{token: color},
};

/// The color `rgb(200, 0, 0)` of the hover test of theming.md §3.2.
const RawThemeColor _red = (alpha: 1.0, red: 200 / 255, green: 0.0, blue: 0.0);

/// The color `rgba(0, 0, 255, 0.8)`, a second palette color.
const RawThemeColor _blue = (alpha: 0.8, red: 0.0, green: 0.0, blue: 1.0);

/// `BORDER_COLORS` (`plugin.colors.ts:14-22`).
const List<String> _upstreamBorderColors = [
  'rgb(54, 162, 235)',
  'rgb(255, 99, 132)',
  'rgb(255, 159, 64)',
  'rgb(255, 205, 86)',
  'rgb(75, 192, 192)',
  'rgb(153, 102, 255)',
  'rgb(201, 203, 207)',
];

/// `BACKGROUND_COLORS` (`plugin.colors.ts:25`): each border color with
/// `replace('rgb(', 'rgba(')` and then `replace(')', ', 0.5)')`.
final List<String> _upstreamBackgroundColors = [
  for (final color in _upstreamBorderColors)
    color.replaceFirst('rgb(', 'rgba(').replaceFirst(')', ', 0.5)'),
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
    final label = scope is Map<String, Object?> && scope.isEmpty
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

/// Whether asserts run: `dart test` and `flutter test` enable them on each
/// platform.
bool get _asserts {
  var enabled = false;
  assert(enabled = true, 'asserts run');
  return enabled;
}

/// The test themes of theming.md §8 test 5: each one compiles only to
/// allowed paths.
final Map<String, Map<String, Object?>> _testThemes = {
  'light': ChartThemes.light,
  for (final token in [
    'color',
    'borderColor',
    'backgroundColor',
    'surface',
    'inverseSurface',
    'onInverseSurface',
  ])
    'colors.$token': _colorTheme(token, _red),
  'typography.font': {
    'typography': <String, Object?>{
      'font': <String, Object?>{'family': 'serif', 'size': 14.0},
    },
  },
  'palette': {
    'palette': <String, Object?>{
      'colors': <Object?>[_red, _blue],
      'backgroundAlpha': 0.25,
    },
  },
  'typography.pointLabels': {
    'typography': <String, Object?>{
      'font': <String, Object?>{'family': 'serif', 'size': 14.0},
      'pointLabels': <String, Object?>{'size': 9.0, 'weight': 'bold'},
    },
  },
  'raw': {
    'raw': <String, Object?>{
      'scale': <String, Object?>{
        'ticks': <String, Object?>{'textStrokeColor': 'blue'},
      },
      'plugins': <String, Object?>{
        'tooltip': <String, Object?>{'borderColor': 'red'},
        'colors': <String, Object?>{
          r'$borderColors': <Object?>['red', 'blue'],
          r'$backgroundColors': <Object?>['pink', 'cyan'],
        },
      },
      'scales': <String, Object?>{
        'radialLinear': <String, Object?>{
          'pointLabels': <String, Object?>{'color': 'green'},
        },
        'linear': <String, Object?>{
          'grid': <String, Object?>{'color': _red},
        },
      },
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderDash': <Object?>[4.0, 2.0],
        },
      },
    },
  },
};

void main() {
  setUpSpecs();

  group('compileChartTheme', () {
    test('a theme without keys compiles to null', () {
      expect(compileChartTheme(null), isNull);
      for (final theme in <Map<String, Object?>>[
        ChartThemes.none,
        {},
        {'colors': <String, Object?>{}},
        {
          'colors': <String, Object?>{'color': null, 'surface': null},
        },
        {'colors': null, 'typography': null, 'raw': null},
        {
          'typography': <String, Object?>{'font': <String, Object?>{}},
        },
        {
          'typography': <String, Object?>{
            'font': <String, Object?>{'weight': null, 'size': undefined},
          },
        },
        {'raw': <String, Object?>{}},
        {
          'raw': <String, Object?>{
            'elements': <String, Object?>{'bar': <String, Object?>{}},
            'scale': <String, Object?>{},
          },
        },
      ]) {
        expect(compileChartTheme(theme), isNull, reason: _json(theme));
      }
    });

    test('the light preset', () {
      // The same leaves, in the same order, on the VM, dart2js and dart2wasm.
      const font = "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif";
      const gray = 'rgba(102, 102, 102, 1)';
      const tenth = 'rgba(0, 0, 0, 0.1)';
      const white = 'rgba(255, 255, 255, 1)';
      final leaves = _leaves(compileChartTheme(ChartThemes.light));
      expect(leaves, {
        'color': gray,
        'scale.ticks.color': gray,
        'scale.ticks.backdropColor': 'rgba(255, 255, 255, 0.75)',
        'scale.ticks.font.family': font,
        'scale.ticks.font.size': 12.0,
        'scale.ticks.font.style': 'normal',
        'scale.ticks.font.lineHeight': 1.2,
        'scale.title.color': gray,
        'scale.title.font.family': font,
        'scale.title.font.size': 12.0,
        'scale.title.font.style': 'normal',
        'scale.title.font.lineHeight': 1.2,
        'scale.grid.color': tenth,
        'scale.border.color': tenth,
        'scales.radialLinear.pointLabels.color': gray,
        'scales.radialLinear.pointLabels.font.family': font,
        'scales.radialLinear.pointLabels.font.style': 'normal',
        'scales.radialLinear.pointLabels.font.lineHeight': 1.2,
        'scales.radialLinear.pointLabels.font.size': 10.0,
        'scales.radialLinear.angleLines.color': tenth,
        'plugins.title.color': gray,
        'plugins.title.font.family': font,
        'plugins.title.font.size': 12.0,
        'plugins.title.font.style': 'normal',
        'plugins.title.font.lineHeight': 1.2,
        'plugins.subtitle.color': gray,
        'plugins.subtitle.font.family': font,
        'plugins.subtitle.font.size': 12.0,
        'plugins.subtitle.font.style': 'normal',
        'plugins.subtitle.font.lineHeight': 1.2,
        'plugins.legend.labels.font.family': font,
        'plugins.legend.labels.font.size': 12.0,
        'plugins.legend.labels.font.style': 'normal',
        'plugins.legend.labels.font.lineHeight': 1.2,
        'plugins.legend.title.font.family': font,
        'plugins.legend.title.font.size': 12.0,
        'plugins.legend.title.font.style': 'normal',
        'plugins.legend.title.font.lineHeight': 1.2,
        'plugins.tooltip.backgroundColor': 'rgba(0, 0, 0, 0.8)',
        'plugins.tooltip.titleColor': white,
        'plugins.tooltip.bodyColor': white,
        'plugins.tooltip.footerColor': white,
        'plugins.tooltip.multiKeyBackground': white,
        'plugins.tooltip.titleFont.family': font,
        'plugins.tooltip.titleFont.size': 12.0,
        'plugins.tooltip.titleFont.style': 'normal',
        'plugins.tooltip.titleFont.lineHeight': 1.2,
        'plugins.tooltip.bodyFont.family': font,
        'plugins.tooltip.bodyFont.size': 12.0,
        'plugins.tooltip.bodyFont.style': 'normal',
        'plugins.tooltip.bodyFont.lineHeight': 1.2,
        'plugins.tooltip.footerFont.family': font,
        'plugins.tooltip.footerFont.size': 12.0,
        'plugins.tooltip.footerFont.style': 'normal',
        'plugins.tooltip.footerFont.lineHeight': 1.2,
        r'plugins.colors.$borderColors': [
          'rgba(54, 162, 235, 1)',
          'rgba(255, 99, 132, 1)',
          'rgba(255, 159, 64, 1)',
          'rgba(255, 205, 86, 1)',
          'rgba(75, 192, 192, 1)',
          'rgba(153, 102, 255, 1)',
          'rgba(201, 203, 207, 1)',
        ],
        r'plugins.colors.$backgroundColors': _upstreamBackgroundColors,
        'elements.point.borderColor': tenth,
        'elements.point.backgroundColor': tenth,
        'elements.line.borderColor': tenth,
        'elements.line.backgroundColor': tenth,
        'elements.bar.borderColor': tenth,
        'elements.bar.backgroundColor': tenth,
        'elements.arc.backgroundColor': tenth,
        'elements.arc.borderColor': 'rgba(255, 255, 255, 1)',
        ..._transitionLeaves,
      });
      expect(leaves.keys, [
        'color',
        'scale.ticks.color',
        'scale.ticks.backdropColor',
        'scale.ticks.font.family',
        'scale.ticks.font.size',
        'scale.ticks.font.style',
        'scale.ticks.font.lineHeight',
        'scale.title.color',
        'scale.title.font.family',
        'scale.title.font.size',
        'scale.title.font.style',
        'scale.title.font.lineHeight',
        'scale.grid.color',
        'scale.border.color',
        'scales.radialLinear.pointLabels.color',
        'scales.radialLinear.pointLabels.font.family',
        'scales.radialLinear.pointLabels.font.style',
        'scales.radialLinear.pointLabels.font.lineHeight',
        'scales.radialLinear.pointLabels.font.size',
        'scales.radialLinear.angleLines.color',
        'plugins.title.color',
        'plugins.title.font.family',
        'plugins.title.font.size',
        'plugins.title.font.style',
        'plugins.title.font.lineHeight',
        'plugins.subtitle.color',
        'plugins.subtitle.font.family',
        'plugins.subtitle.font.size',
        'plugins.subtitle.font.style',
        'plugins.subtitle.font.lineHeight',
        'plugins.legend.labels.font.family',
        'plugins.legend.labels.font.size',
        'plugins.legend.labels.font.style',
        'plugins.legend.labels.font.lineHeight',
        'plugins.legend.title.font.family',
        'plugins.legend.title.font.size',
        'plugins.legend.title.font.style',
        'plugins.legend.title.font.lineHeight',
        'plugins.tooltip.backgroundColor',
        'plugins.tooltip.titleColor',
        'plugins.tooltip.bodyColor',
        'plugins.tooltip.footerColor',
        'plugins.tooltip.multiKeyBackground',
        'plugins.tooltip.titleFont.family',
        'plugins.tooltip.titleFont.size',
        'plugins.tooltip.titleFont.style',
        'plugins.tooltip.titleFont.lineHeight',
        'plugins.tooltip.bodyFont.family',
        'plugins.tooltip.bodyFont.size',
        'plugins.tooltip.bodyFont.style',
        'plugins.tooltip.bodyFont.lineHeight',
        'plugins.tooltip.footerFont.family',
        'plugins.tooltip.footerFont.size',
        'plugins.tooltip.footerFont.style',
        'plugins.tooltip.footerFont.lineHeight',
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
      const red = 'rgba(200, 0, 0, 1)';
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
          'scale.ticks.backdropColor': 'rgba(200, 0, 0, 0.75)',
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
      for (final MapEntry(key: token, value: keys) in expected.entries) {
        expect(
          _leaves(compileChartTheme(_colorTheme(token, _red))),
          {...keys, ..._transitionLeaves},
          reason: token,
        );
      }
    });

    test('the backdrop replaces the alpha of the surface with 0.75', () {
      final leaves = _leaves(
        compileChartTheme(
          _colorTheme('surface', (
            alpha: 0.5,
            red: 0.0,
            green: 0.0,
            blue: 1.0,
          )),
        ),
      );
      expect(leaves['elements.arc.borderColor'], 'rgba(0, 0, 255, 0.5)');
      expect(leaves['scale.ticks.backdropColor'], 'rgba(0, 0, 255, 0.75)');
    });

    test('a font emits its fields that are not null into each slot', () {
      final compiled = compileChartTheme({
        'typography': <String, Object?>{
          'font': <String, Object?>{
            'family': 'serif',
            'size': null,
            'style': 'italic',
            'weight': 'bold',
            'lineHeight': undefined,
          },
        },
      });
      expect(_leaves(compiled), {
        'scale.ticks.font.family': 'serif',
        'scale.ticks.font.style': 'italic',
        'scale.ticks.font.weight': 'bold',
        'scale.title.font.family': 'serif',
        'scale.title.font.style': 'italic',
        'scale.title.font.weight': 'bold',
        'scales.radialLinear.pointLabels.font.family': 'serif',
        'scales.radialLinear.pointLabels.font.style': 'italic',
        'scales.radialLinear.pointLabels.font.weight': 'bold',
        // No weight: the title keeps its local 'bold'
        // (plugin.title.js:148-150) and the subtitle its local 'normal'
        // (plugin.subtitle.js:35-37, theming.md §3.4).
        'plugins.title.font.family': 'serif',
        'plugins.title.font.style': 'italic',
        'plugins.subtitle.font.family': 'serif',
        'plugins.subtitle.font.style': 'italic',
        // The legend has no font defaults (plugin.legend.js:636-712): the
        // whole font, with the weight.
        'plugins.legend.labels.font.family': 'serif',
        'plugins.legend.labels.font.style': 'italic',
        'plugins.legend.labels.font.weight': 'bold',
        'plugins.legend.title.font.family': 'serif',
        'plugins.legend.title.font.style': 'italic',
        'plugins.legend.title.font.weight': 'bold',
        // The tooltip title and footer keep their local 'bold'
        // (plugin.tooltip.js:1281-1283, 1295-1297). The body font is the
        // whole font.
        'plugins.tooltip.titleFont.family': 'serif',
        'plugins.tooltip.titleFont.style': 'italic',
        'plugins.tooltip.bodyFont.family': 'serif',
        'plugins.tooltip.bodyFont.style': 'italic',
        'plugins.tooltip.bodyFont.weight': 'bold',
        'plugins.tooltip.footerFont.family': 'serif',
        'plugins.tooltip.footerFont.style': 'italic',
        ..._transitionLeaves,
      });
      // No root font (theming.md §3.4), and one Map for each slot.
      expect(compiled!.containsKey('font'), isFalse);
      expect(
        _at(compiled, 'scale.ticks.font'),
        isNot(same(_at(compiled, 'scale.title.font'))),
      );
    });

    test('the point-label font is the base font without size, then its '
        'token', () {
      // theming.md §3.4 and §4, the last row: upstream sets the point-label
      // size 10 locally (scale.radialLinear.js:383-385).
      Object? pointLabels(Map<String, Object?> typography) => _at(
        compileChartTheme({'typography': typography}),
        'scales.radialLinear.pointLabels.font',
      );

      // The token wins field by field. The base size never reaches it.
      expect(
        pointLabels(<String, Object?>{
          'font': <String, Object?>{
            'family': 'serif',
            'size': 14.0,
            'style': 'italic',
          },
          'pointLabels': <String, Object?>{'style': 'normal', 'size': 9.0},
        }),
        <String, Object?>{'family': 'serif', 'style': 'normal', 'size': 9.0},
      );
      // The base font without the token: its fields without size. The size
      // 10 of defaults.scales.radialLinear then stays.
      expect(
        pointLabels(<String, Object?>{
          'font': <String, Object?>{'family': 'serif', 'size': 14.0},
        }),
        <String, Object?>{'family': 'serif'},
      );
      // The token without the base font.
      expect(
        pointLabels(<String, Object?>{
          'pointLabels': <String, Object?>{'size': 9.0},
        }),
        <String, Object?>{'size': 9.0},
      );
      // A null token field themes nothing, also over a base field.
      expect(
        pointLabels(<String, Object?>{
          'font': <String, Object?>{'family': 'serif', 'weight': 'bold'},
          'pointLabels': <String, Object?>{
            'family': null,
            'weight': undefined,
            'lineHeight': 1.5,
          },
        }),
        <String, Object?>{
          'family': 'serif',
          'weight': 'bold',
          'lineHeight': 1.5,
        },
      );
      // A base font with a size only gives no point-label font.
      final sizeOnly = compileChartTheme({
        'typography': <String, Object?>{
          'font': <String, Object?>{'size': 14.0},
        },
      });
      expect(_at(sizeOnly, 'scales'), same(undefined));
      expect(_at(sizeOnly, 'scale.ticks.font.size'), 14.0);
      // A token without fields themes nothing.
      expect(
        compileChartTheme({
          'typography': <String, Object?>{
            'pointLabels': <String, Object?>{'size': null},
          },
        }),
        isNull,
      );
    });

    test('the point-label font keeps the field order', () {
      // The base fields in their order without size, then the new token
      // fields in their order. A token field over a base field keeps the
      // position of the base field.
      final compiled = compileChartTheme({
        'typography': <String, Object?>{
          'font': <String, Object?>{
            'lineHeight': 1.2,
            'size': 14.0,
            'family': 'serif',
          },
          'pointLabels': <String, Object?>{'weight': 'bold', 'family': 'mono'},
        },
      });
      final font =
          _at(compiled, 'scales.radialLinear.pointLabels.font')!
              as Map<String, Object?>;
      expect(font.keys, ['lineHeight', 'family', 'weight']);
      expect(font['family'], 'mono');
      // One Map for each slot.
      expect(font, isNot(same(_at(compiled, 'scale.ticks.font'))));
    });

    test('the raw keys beat the token keys, key by key', () {
      final compiled = compileChartTheme({
        'colors': <String, Object?>{'color': _red},
        'typography': <String, Object?>{
          'font': <String, Object?>{'family': 'serif', 'size': 14.0},
        },
        'raw': <String, Object?>{
          'color': 'raw-color',
          'scale': <String, Object?>{
            'ticks': <String, Object?>{
              'color': 'raw-ticks',
              'textStrokeColor': 'raw-stroke',
              'font': <String, Object?>{'size': 10.0},
            },
            'title': 'raw-title',
          },
        },
      });
      expect(_leaves(compiled), {
        'color': 'raw-color',
        'scale.ticks.color': 'raw-ticks',
        'scale.ticks.font.family': 'serif',
        'scale.ticks.font.size': 10.0,
        'scale.ticks.textStrokeColor': 'raw-stroke',
        'scale.title': 'raw-title',
        'scales.radialLinear.pointLabels.color': 'rgba(200, 0, 0, 1)',
        'scales.radialLinear.pointLabels.font.family': 'serif',
        'plugins.title.color': 'rgba(200, 0, 0, 1)',
        'plugins.subtitle.color': 'rgba(200, 0, 0, 1)',
        'plugins.title.font.family': 'serif',
        'plugins.title.font.size': 14.0,
        'plugins.subtitle.font.family': 'serif',
        'plugins.subtitle.font.size': 14.0,
        'plugins.legend.labels.font.family': 'serif',
        'plugins.legend.labels.font.size': 14.0,
        'plugins.legend.title.font.family': 'serif',
        'plugins.legend.title.font.size': 14.0,
        'plugins.tooltip.titleFont.family': 'serif',
        'plugins.tooltip.titleFont.size': 14.0,
        'plugins.tooltip.bodyFont.family': 'serif',
        'plugins.tooltip.bodyFont.size': 14.0,
        'plugins.tooltip.footerFont.family': 'serif',
        'plugins.tooltip.footerFont.size': 14.0,
        ..._transitionLeaves,
      });
    });

    test('the raw radial keys beat the radial token keys', () {
      final compiled = compileChartTheme({
        'colors': <String, Object?>{'color': _red, 'borderColor': _red},
        'typography': <String, Object?>{
          'pointLabels': <String, Object?>{'size': 9.0, 'style': 'italic'},
        },
        'raw': <String, Object?>{
          'scales': <String, Object?>{
            'radialLinear': <String, Object?>{
              'pointLabels': <String, Object?>{
                'color': 'raw-point-labels',
                'font': <String, Object?>{'size': 11.0},
              },
              'angleLines': <String, Object?>{'lineWidth': 2.0},
            },
          },
        },
      });
      expect(_leaves(_at(compiled, 'scales')), {
        'radialLinear.pointLabels.color': 'raw-point-labels',
        'radialLinear.pointLabels.font.size': 11.0,
        'radialLinear.pointLabels.font.style': 'italic',
        'radialLinear.angleLines.color': 'rgba(200, 0, 0, 1)',
        'radialLinear.angleLines.lineWidth': 2.0,
      });
    });

    test('a raw color token is an rgba() string at any depth', () {
      final compiled = compileChartTheme({
        'raw': <String, Object?>{
          'scale': <String, Object?>{
            'ticks': <String, Object?>{'textStrokeColor': _red},
          },
          'plugins': <String, Object?>{
            'colors': <String, Object?>{
              r'$borderColors': <Object?>[_red, 'blue'],
            },
          },
        },
      });
      expect(
        _at(compiled, 'scale.ticks.textStrokeColor'),
        'rgba(200, 0, 0, 1)',
      );
      expect(_at(compiled, r'plugins.colors.$borderColors'), [
        'rgba(200, 0, 0, 1)',
        'blue',
      ]);
    });

    test('the raw keys come in the Object.keys order', () {
      final compiled = compileChartTheme({
        'raw': <String, Object?>{
          'elements': <String, Object?>{
            'b': <String, Object?>{'x': 1.0},
            '2': <String, Object?>{'x': 1.0},
            'a': <String, Object?>{'x': 1.0},
            '1': <String, Object?>{'x': 1.0},
          },
        },
      });
      expect((compiled!['elements']! as Map<String, Object?>).keys, [
        '1',
        '2',
        'b',
        'a',
      ]);
      expect(compiled.keys, ['elements', 'transitions']);
    });

    test('the transitions come only beside other keys', () {
      // theming.md §3.3: the transitions keys alone are no theme.
      expect(compileChartTheme({'raw': <String, Object?>{}}), isNull);
      expect(
        compileChartTheme({
          'raw': <String, Object?>{
            'transitions': <String, Object?>{
              'theme': <String, Object?>{'note': 'raw'},
            },
          },
        }),
        isNull,
      );
      final compiled = compileChartTheme({
        'raw': <String, Object?>{
          'color': 'c',
          'transitions': <String, Object?>{
            'theme': <String, Object?>{'note': 'raw'},
          },
        },
      });
      expect(_leaves(compiled), {
        'color': 'c',
        'transitions.theme.note': 'raw',
        ..._transitionLeaves,
      });
    });

    test('the compiler does not change the theme', () {
      final raw = <String, Object?>{
        'scale': <String, Object?>{
          'ticks': <String, Object?>{'color': 'raw'},
        },
        'elements': <String, Object?>{'bar': <String, Object?>{}},
      };
      final theme = <String, Object?>{
        'colors': <String, Object?>{'color': _red},
        'raw': raw,
      };
      final before = _json(theme);
      final compiled = compileChartTheme(theme)!;
      expect(_json(theme), before);
      expect(jsObjectIsFrozen(theme), isFalse);
      expect(jsObjectIsFrozen(raw), isFalse);
      expect(compiled['scale'], isNot(same(raw['scale'])));
    });

    test('the compiler does not change defaults', () {
      // theming.md §6: the theme never writes Chart.defaults.
      final before = _json(defaults);
      final overridesBefore = _json(overrides);
      for (final theme in _testThemes.values) {
        final compiled = compileChartTheme(theme);
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

    /// The theme with the palette field [palette] only.
    Map<String, Object?> paletteTheme(Map<String, Object?> palette) => {
      'palette': palette,
    };

    test('the border colors keep their alpha, the background alpha is 0.5', () {
      final compiled = compileChartTheme(
        paletteTheme(<String, Object?>{
          'colors': <Object?>[_red, _blue],
        }),
      );
      expect(_at(compiled, border), [
        'rgba(200, 0, 0, 1)',
        'rgba(0, 0, 255, 0.8)',
      ]);
      // The alpha 0.5 of BACKGROUND_COLORS (plugin.colors.ts:25) replaces
      // the alpha of each color.
      expect(_at(compiled, background), [
        'rgba(200, 0, 0, 0.5)',
        'rgba(0, 0, 255, 0.5)',
      ]);
    });

    test('backgroundAlpha replaces the alpha of the background colors', () {
      Object? backgroundAt(num alpha) => _at(
        compileChartTheme(
          paletteTheme(<String, Object?>{
            'colors': <Object?>[_red, _blue],
            'backgroundAlpha': alpha,
          }),
        ),
        background,
      );
      // The blue screen of theming.md §8 test 6 needs alpha 1 without a
      // raw key.
      expect(backgroundAt(1.0), ['rgba(200, 0, 0, 1)', 'rgba(0, 0, 255, 1)']);
      expect(backgroundAt(0.25), [
        'rgba(200, 0, 0, 0.25)',
        'rgba(0, 0, 255, 0.25)',
      ]);
      // An int is a number too, and the alpha clamps.
      expect(backgroundAt(0), ['rgba(200, 0, 0, 0)', 'rgba(0, 0, 255, 0)']);
      expect(backgroundAt(2.0), ['rgba(200, 0, 0, 1)', 'rgba(0, 0, 255, 1)']);
    });

    test('the key order and the item order', () {
      final compiled = compileChartTheme(
        paletteTheme(<String, Object?>{
          'backgroundAlpha': 0.5,
          'colors': <Object?>[_blue, _red, _blue],
        }),
      )!;
      expect(compiled.keys, ['plugins', 'transitions']);
      expect((_at(compiled, 'plugins.colors')! as Map<String, Object?>).keys, [
        r'$borderColors',
        r'$backgroundColors',
      ]);
      expect(_at(compiled, border), [
        'rgba(0, 0, 255, 0.8)',
        'rgba(200, 0, 0, 1)',
        'rgba(0, 0, 255, 0.8)',
      ]);
      // With the other tokens, the palette comes after the title, subtitle,
      // legend and tooltip keys of plugins.
      final light = compileChartTheme(ChartThemes.light)!;
      expect(light.keys, [
        'color',
        'scale',
        'scales',
        'plugins',
        'elements',
        'transitions',
      ]);
      expect((light['plugins']! as Map<String, Object?>).keys, [
        'title',
        'subtitle',
        'legend',
        'tooltip',
        'colors',
      ]);
    });

    test('the palette Lists are frozen', () {
      final compiled = compileChartTheme(ChartThemes.light);
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

    test('an empty or absent colors List emits nothing', () {
      for (final palette in <Map<String, Object?>?>[
        null,
        {},
        {'colors': null},
        {'colors': <Object?>[]},
        {'backgroundAlpha': 0.3},
        {'colors': <Object?>[], 'backgroundAlpha': 1.0},
      ]) {
        expect(
          compileChartTheme(<String, Object?>{'palette': palette}),
          isNull,
          reason: _json(palette),
        );
        // Beside another token, no plugins.colors key.
        final compiled = compileChartTheme(<String, Object?>{
          'colors': <String, Object?>{'surface': _red},
          'palette': palette,
        });
        expect(_at(compiled, 'plugins'), same(undefined));
      }
    });

    test('a palette alone also emits the transitions', () {
      final leaves = _leaves(
        compileChartTheme(
          paletteTheme(<String, Object?>{
            'colors': <Object?>[_red],
          }),
        ),
      );
      expect(leaves, {
        border: ['rgba(200, 0, 0, 1)'],
        background: ['rgba(200, 0, 0, 0.5)'],
        ..._transitionLeaves,
      });
    });

    test('the raw palette keys beat the token', () {
      final compiled = compileChartTheme({
        'palette': <String, Object?>{
          'colors': <Object?>[_red, _blue],
        },
        'raw': <String, Object?>{
          'plugins': <String, Object?>{
            'colors': <String, Object?>{
              r'$borderColors': <Object?>['red'],
            },
          },
        },
      });
      // The raw List replaces the token List as a whole.
      expect(_at(compiled, border), ['red']);
      expect(_at(compiled, background), [
        'rgba(200, 0, 0, 0.5)',
        'rgba(0, 0, 255, 0.5)',
      ]);
      expect((_at(compiled, 'plugins.colors')! as Map<String, Object?>).keys, [
        r'$borderColors',
        r'$backgroundColors',
      ]);
    });

    test('the light palette restates BORDER_COLORS and BACKGROUND_COLORS', () {
      // plugin.colors.ts:14-25. The border strings parse to the upstream
      // strings. The background strings are equal.
      final compiled = compileChartTheme(ChartThemes.light);
      final borders = _at(compiled, border)! as List<Object?>;
      expect(borders, hasLength(_upstreamBorderColors.length));
      for (var i = 0; i < borders.length; i++) {
        expect(
          Color(borders[i]).rgbString(),
          Color(_upstreamBorderColors[i]).rgbString(),
          reason: '$i',
        );
        expect(
          Color(borders[i]).rgbString(),
          _upstreamBorderColors[i],
          reason: '$i',
        );
      }
      expect(_at(compiled, background), _upstreamBackgroundColors);
      expect(_upstreamBackgroundColors.first, 'rgba(54, 162, 235, 0.5)');
    });

    test(
      'an unknown palette field or a bad value fails an assert',
      () {
        final palettes = <Object?>[
          <String, Object?>{
            'colors': <Object?>[_red],
            'borders': <Object?>[_red],
          },
          <String, Object?>{
            'colors': <Object?>[_red, 'red'],
          },
          <String, Object?>{
            'colors': <String, Object?>{'0': _red},
          },
          <String, Object?>{'colors': _red},
          <String, Object?>{
            'colors': <Object?>[_red],
            'backgroundAlpha': '0.5',
          },
          <Object?>[_red],
        ];
        for (final palette in palettes) {
          expect(
            () => compileChartTheme(<String, Object?>{'palette': palette}),
            throwsA(isA<AssertionError>()),
            reason: _json(palette),
          );
        }
      },
      skip: _asserts ? false : 'n/a: the asserts do not run',
    );

    test(
      'without asserts, an item that is not a RawThemeColor is left out',
      () {
        final compiled = compileChartTheme({
          'palette': <String, Object?>{
            'colors': <Object?>[_red, 'red', _blue],
            'backgroundAlpha': '1',
          },
        });
        expect(_at(compiled, border), [
          'rgba(200, 0, 0, 1)',
          'rgba(0, 0, 255, 0.8)',
        ]);
        expect(_at(compiled, background), [
          'rgba(200, 0, 0, 0.5)',
          'rgba(0, 0, 255, 0.5)',
        ]);
        expect(
          compileChartTheme({
            'palette': <String, Object?>{
              'colors': <Object?>['red'],
            },
          }),
          isNull,
        );
      },
      skip: _asserts ? 'n/a: the asserts run' : false,
    );
  });

  group('the title keys', () {
    test('the title font has no weight', () {
      // theming.md §3.4: the title keeps its local weight 'bold'
      // (plugin.title.js:148-150).
      final compiled = compileChartTheme({
        'typography': <String, Object?>{
          'font': <String, Object?>{
            'weight': 'bold',
            'family': 'serif',
            'size': 14.0,
          },
        },
      });
      expect(_at(compiled, 'scale.ticks.font.weight'), 'bold');
      final font = _at(compiled, 'plugins.title.font')! as Map<String, Object?>;
      expect(font.keys, ['family', 'size']);
      // One Map for each slot.
      expect(font, isNot(same(_at(compiled, 'scale.ticks.font'))));
      // A font with a weight only gives no title font. The legend fonts and
      // the tooltip body font keep the weight (the groups `the subtitle and
      // legend keys` and `the tooltip keys`).
      final weightOnly = compileChartTheme({
        'typography': <String, Object?>{
          'font': <String, Object?>{'weight': 'bold'},
        },
      });
      expect(_at(weightOnly, 'scale.ticks.font.weight'), 'bold');
      expect(_at(weightOnly, 'plugins.title'), same(undefined));
      expect((_at(weightOnly, 'plugins')! as Map<String, Object?>).keys, [
        'legend',
        'tooltip',
      ]);
    });

    test('the title color is the color token', () {
      // The route of the title color (plugin.title.js:158-160).
      final compiled = compileChartTheme(_colorTheme('color', _blue));
      expect(_at(compiled, 'plugins.title.color'), 'rgba(0, 0, 255, 0.8)');
      expect(
        (_at(compiled, 'plugins.title')! as Map<String, Object?>).keys,
        ['color'],
      );
      // The legend reads the root color (plugin.legend.js:661, 707).
      expect(_at(compiled, 'plugins.legend'), same(undefined));
      expect((_at(compiled, 'plugins')! as Map<String, Object?>).keys, [
        'title',
        'subtitle',
      ]);
    });

    test('a raw title text fails the guard, a raw title color passes', () {
      final theme = <String, Object?>{
        'raw': <String, Object?>{
          'plugins': <String, Object?>{
            'title': <String, Object?>{'text': 'Title'},
          },
        },
      };
      if (_asserts) {
        expect(() => compileChartTheme(theme), throwsA(isA<AssertionError>()));
      } else {
        expect(compileChartTheme(theme), isNull);
      }
      final compiled = compileChartTheme({
        'colors': <String, Object?>{'color': _red},
        'raw': <String, Object?>{
          'plugins': <String, Object?>{
            'title': <String, Object?>{'color': 'blue', 'position': 'bottom'},
          },
        },
      });
      expect(_at(compiled, 'plugins.title.color'), 'blue');
      expect(_at(compiled, 'plugins.title.position'), 'bottom');
    });
  });

  group('the subtitle and legend keys', () {
    // theming.md §4 (Chart.js ADR 0050): the subtitle takes the color token
    // and the font token without weight, as the title. The legend takes the
    // whole font token into its two fonts and no color key.
    final serifBold = <String, Object?>{
      'typography': <String, Object?>{
        'font': <String, Object?>{
          'family': 'serif',
          'weight': 'bold',
          'size': 14.0,
          'lineHeight': 1.5,
        },
      },
    };

    test('the subtitle color is the color token', () {
      // The route of the subtitle color (plugin.subtitle.js:45-47).
      final compiled = compileChartTheme(_colorTheme('color', _blue));
      expect(_at(compiled, 'plugins.subtitle.color'), 'rgba(0, 0, 255, 0.8)');
      expect(
        (_at(compiled, 'plugins.subtitle')! as Map<String, Object?>).keys,
        ['color'],
      );
      // The other color tokens give no subtitle key.
      for (final token in ['borderColor', 'backgroundColor', 'surface']) {
        expect(
          _at(compileChartTheme(_colorTheme(token, _blue)), 'plugins'),
          same(undefined),
          reason: token,
        );
      }
    });

    test('the subtitle font has no weight', () {
      // theming.md §3.4: the subtitle keeps its local weight 'normal'
      // (plugin.subtitle.js:35-37).
      final compiled = compileChartTheme(serifBold);
      final font =
          _at(compiled, 'plugins.subtitle.font')! as Map<String, Object?>;
      expect(font, <String, Object?>{
        'family': 'serif',
        'size': 14.0,
        'lineHeight': 1.5,
      });
      expect(font.keys, ['family', 'size', 'lineHeight']);
      // One Map for each slot.
      expect(font, isNot(same(_at(compiled, 'plugins.title.font'))));
      // A font with a weight only gives no subtitle font.
      final weightOnly = compileChartTheme({
        'typography': <String, Object?>{
          'font': <String, Object?>{'weight': 'bold'},
        },
      });
      expect(_at(weightOnly, 'plugins.subtitle'), same(undefined));
    });

    test('the two legend fonts are the whole font token', () {
      // The legend has no font defaults (plugin.legend.js:636-712). toFont
      // fills an absent field from defaults.font (helpers.options.ts:115-117)
      // for the label font (plugin.legend.js:136, 288) and the title font
      // (:446, 495).
      final compiled = compileChartTheme(serifBold);
      const whole = <String, Object?>{
        'family': 'serif',
        'weight': 'bold',
        'size': 14.0,
        'lineHeight': 1.5,
      };
      final labels =
          _at(compiled, 'plugins.legend.labels.font')! as Map<String, Object?>;
      final title =
          _at(compiled, 'plugins.legend.title.font')! as Map<String, Object?>;
      expect(labels, whole);
      expect(title, whole);
      expect(labels.keys, ['family', 'weight', 'size', 'lineHeight']);
      expect(title.keys, ['family', 'weight', 'size', 'lineHeight']);
      // The legend gets no other key: no color (plugin.legend.js:661, 707
      // read the root color) and no point-label size rule.
      expect(_leaves(_at(compiled, 'plugins.legend')).keys, [
        'labels.font.family',
        'labels.font.weight',
        'labels.font.size',
        'labels.font.lineHeight',
        'title.font.family',
        'title.font.weight',
        'title.font.size',
        'title.font.lineHeight',
      ]);
      // One Map for each slot.
      expect(labels, isNot(same(title)));
      expect(labels, isNot(same(_at(compiled, 'scale.ticks.font'))));
      // The legend fonts are frozen with the rest.
      expect(jsObjectIsFrozen(labels), isTrue);
      expect(jsObjectIsFrozen(title), isTrue);
    });

    test('the plugins keys come after scales, in one order', () {
      // A font-only theme also puts the root key plugins after scales.
      final font = compileChartTheme(serifBold)!;
      expect(font.keys, ['scale', 'scales', 'plugins', 'transitions']);
      expect((font['plugins']! as Map<String, Object?>).keys, [
        'title',
        'subtitle',
        'legend',
        'tooltip',
      ]);
      final both = compileChartTheme({
        'colors': <String, Object?>{'color': _red},
        ...serifBold,
      })!;
      expect(both.keys, ['color', 'scale', 'scales', 'plugins', 'transitions']);
      expect((both['plugins']! as Map<String, Object?>).keys, [
        'title',
        'subtitle',
        'legend',
        'tooltip',
      ]);
      expect((_at(both, 'plugins.subtitle')! as Map<String, Object?>).keys, [
        'color',
        'font',
      ]);
    });

    test('the raw keys beat the subtitle and legend token keys', () {
      final compiled = compileChartTheme({
        'colors': <String, Object?>{'color': _red},
        ...serifBold,
        'raw': <String, Object?>{
          'plugins': <String, Object?>{
            'subtitle': <String, Object?>{
              'color': 'raw-subtitle',
              'font': <String, Object?>{'weight': 'lighter'},
            },
            'legend': <String, Object?>{
              'labels': <String, Object?>{
                'font': <String, Object?>{'size': 10.0},
                'color': 'raw-labels',
              },
              'title': <String, Object?>{'color': 'raw-legend-title'},
            },
          },
        },
      });
      expect(_leaves(_at(compiled, 'plugins.subtitle')), {
        'color': 'raw-subtitle',
        'font.family': 'serif',
        'font.size': 14.0,
        'font.lineHeight': 1.5,
        'font.weight': 'lighter',
      });
      expect(_leaves(_at(compiled, 'plugins.legend')), {
        'labels.font.family': 'serif',
        'labels.font.weight': 'bold',
        'labels.font.size': 10.0,
        'labels.font.lineHeight': 1.5,
        'labels.color': 'raw-labels',
        'title.font.family': 'serif',
        'title.font.weight': 'bold',
        'title.font.size': 14.0,
        'title.font.lineHeight': 1.5,
        'title.color': 'raw-legend-title',
      });
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
      final light = compileChartTheme(ChartThemes.light);
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
    final serifBold = <String, Object?>{
      'typography': <String, Object?>{
        'font': <String, Object?>{
          'family': 'serif',
          'weight': 'bold',
          'size': 14.0,
          'lineHeight': 1.5,
        },
      },
    };

    test('inverseSurface is the tooltip background', () {
      // plugin.tooltip.js:1279.
      final compiled = compileChartTheme(_colorTheme('inverseSurface', _blue));
      expect(_leaves(compiled), {
        'plugins.tooltip.backgroundColor': 'rgba(0, 0, 255, 0.8)',
        ..._transitionLeaves,
      });
      expect(compiled!.keys, ['plugins', 'transitions']);
    });

    test('onInverseSurface is the tooltip text and key color', () {
      // plugin.tooltip.js:1280, 1287, 1292, 1305.
      final compiled = compileChartTheme(
        _colorTheme('onInverseSurface', _blue),
      );
      expect(_leaves(compiled), {
        'plugins.tooltip.titleColor': 'rgba(0, 0, 255, 0.8)',
        'plugins.tooltip.bodyColor': 'rgba(0, 0, 255, 0.8)',
        'plugins.tooltip.footerColor': 'rgba(0, 0, 255, 0.8)',
        'plugins.tooltip.multiKeyBackground': 'rgba(0, 0, 255, 0.8)',
        ..._transitionLeaves,
      });
      // The other color tokens give no tooltip key. The tooltip border
      // color 'rgba(0,0,0,0)' (plugin.tooltip.js:1308) has no token.
      for (final token in [
        'color',
        'borderColor',
        'backgroundColor',
        'surface',
      ]) {
        expect(
          _leaves(
            compileChartTheme(_colorTheme(token, _blue)),
          ).keys.where((path) => path.startsWith('plugins.tooltip.')),
          isEmpty,
          reason: token,
        );
      }
    });

    test('the light preset gives the upstream tooltip colors', () {
      // 'rgba(0,0,0,0.8)' and '#fff' (plugin.tooltip.js:1279, 1280, 1287,
      // 1292, 1305) after the parse of the ported @kurkle/color.
      final compiled = compileChartTheme(ChartThemes.light);
      expect(
        _at(compiled, 'plugins.tooltip.backgroundColor'),
        'rgba(0, 0, 0, 0.8)',
      );
      expect(
        Color(_at(compiled, 'plugins.tooltip.backgroundColor')).rgbString(),
        Color('rgba(0,0,0,0.8)').rgbString(),
      );
      for (final key in tooltipColors.skip(1)) {
        expect(
          Color(_at(compiled, 'plugins.tooltip.$key')).rgbString(),
          Color('#fff').rgbString(),
          reason: key,
        );
      }
      expect(_at(compiled, 'plugins.tooltip.borderColor'), same(undefined));
    });

    test('the body font is the whole font token', () {
      // plugin.tooltip.js:1289-1290: no local field.
      final compiled = compileChartTheme(serifBold);
      final font =
          _at(compiled, 'plugins.tooltip.bodyFont')! as Map<String, Object?>;
      expect(font, <String, Object?>{
        'family': 'serif',
        'weight': 'bold',
        'size': 14.0,
        'lineHeight': 1.5,
      });
      expect(font.keys, ['family', 'weight', 'size', 'lineHeight']);
      expect(font, isNot(same(_at(compiled, 'scale.ticks.font'))));
      expect(jsObjectIsFrozen(font), isTrue);
    });

    test('the title and footer fonts have no weight', () {
      // theming.md §3.4: the tooltip title and footer keep their local
      // weight 'bold' (plugin.tooltip.js:1281-1283, 1295-1297).
      final compiled = compileChartTheme(serifBold);
      for (final key in ['titleFont', 'footerFont']) {
        final font =
            _at(compiled, 'plugins.tooltip.$key')! as Map<String, Object?>;
        expect(font, <String, Object?>{
          'family': 'serif',
          'size': 14.0,
          'lineHeight': 1.5,
        }, reason: key);
        expect(font.keys, ['family', 'size', 'lineHeight'], reason: key);
        expect(jsObjectIsFrozen(font), isTrue, reason: key);
      }
      // One Map for each slot.
      expect(
        _at(compiled, 'plugins.tooltip.titleFont'),
        isNot(same(_at(compiled, 'plugins.tooltip.footerFont'))),
      );
      expect(
        _at(compiled, 'plugins.tooltip.titleFont'),
        isNot(same(_at(compiled, 'plugins.title.font'))),
      );
      // A font with a weight only gives the body font only.
      final weightOnly = compileChartTheme({
        'typography': <String, Object?>{
          'font': <String, Object?>{'weight': 'bold'},
        },
      });
      expect(_leaves(_at(weightOnly, 'plugins.tooltip')), {
        'bodyFont.weight': 'bold',
      });
    });

    test('the tooltip keys come after the legend keys, in one order', () {
      // The colors and then the fonts, in each theme.
      final compiled = compileChartTheme({
        'colors': <String, Object?>{
          'onInverseSurface': _red,
          'color': _red,
          'inverseSurface': _blue,
        },
        ...serifBold,
        'palette': <String, Object?>{
          'colors': <Object?>[_red],
        },
      })!;
      expect((compiled['plugins']! as Map<String, Object?>).keys, [
        'title',
        'subtitle',
        'legend',
        'tooltip',
        'colors',
      ]);
      expect((_at(compiled, 'plugins.tooltip')! as Map<String, Object?>).keys, [
        ...tooltipColors,
        'titleFont',
        'bodyFont',
        'footerFont',
      ]);
      // The same order without the other tokens.
      final tooltipOnly = compileChartTheme({
        'colors': <String, Object?>{'onInverseSurface': _red},
        ...serifBold,
      })!;
      expect((tooltipOnly['plugins']! as Map<String, Object?>).keys, [
        'title',
        'subtitle',
        'legend',
        'tooltip',
      ]);
      expect(
        (_at(tooltipOnly, 'plugins.tooltip')! as Map<String, Object?>).keys,
        [...tooltipColors.skip(1), 'titleFont', 'bodyFont', 'footerFont'],
      );
    });

    test('the raw keys beat the tooltip token keys', () {
      final compiled = compileChartTheme({
        'colors': <String, Object?>{
          'inverseSurface': _blue,
          'onInverseSurface': _red,
        },
        ...serifBold,
        'raw': <String, Object?>{
          'plugins': <String, Object?>{
            'tooltip': <String, Object?>{
              'backgroundColor': 'raw-background',
              'titleFont': <String, Object?>{'weight': 'lighter'},
              'bodyFont': <String, Object?>{'size': 10.0},
              'borderColor': 'raw-border',
            },
          },
        },
      });
      expect(_leaves(_at(compiled, 'plugins.tooltip')), {
        'backgroundColor': 'raw-background',
        'titleColor': 'rgba(200, 0, 0, 1)',
        'bodyColor': 'rgba(200, 0, 0, 1)',
        'footerColor': 'rgba(200, 0, 0, 1)',
        'multiKeyBackground': 'rgba(200, 0, 0, 1)',
        'titleFont.family': 'serif',
        'titleFont.size': 14.0,
        'titleFont.lineHeight': 1.5,
        'titleFont.weight': 'lighter',
        'bodyFont.family': 'serif',
        'bodyFont.weight': 'bold',
        'bodyFont.size': 10.0,
        'bodyFont.lineHeight': 1.5,
        'footerFont.family': 'serif',
        'footerFont.size': 14.0,
        'footerFont.lineHeight': 1.5,
        'borderColor': 'raw-border',
      });
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

  group('themeColorToRgba', () {
    test('8-bit channels and the alpha of jsNumberToString', () {
      expect(
        themeColorToRgba((alpha: 0.1, red: 0.0, green: 0.0, blue: 0.0)),
        'rgba(0, 0, 0, 0.1)',
      );
      // The alpha of Color(0x1A000000) (theming.md §4).
      expect(
        themeColorToRgba((alpha: 26 / 255, red: 0.0, green: 0.0, blue: 0.0)),
        'rgba(0, 0, 0, 0.10196078431372549)',
      );
      expect(
        themeColorToRgba((
          alpha: 1.0,
          red: 102 / 255,
          green: 102 / 255,
          blue: 102 / 255,
        )),
        'rgba(102, 102, 102, 1)',
      );
      expect(
        themeColorToRgba((alpha: 0.0, red: 1.0, green: 1.0, blue: 1.0)),
        'rgba(255, 255, 255, 0)',
      );
    });

    test('a channel rounds half up, as Color._floatToInt8', () {
      // (x * 255.0).round(): 0.5 / 255 * 255 rounds to 1.
      expect(
        themeColorToRgba((
          alpha: 1.0,
          red: 0.5 / 255,
          green: 1.49 / 255,
          blue: 254.5 / 255,
        )),
        'rgba(1, 1, 255, 1)',
      );
    });

    test('extended sRGB components clamp', () {
      expect(
        themeColorToRgba((alpha: 1.5, red: -0.2, green: 1.2, blue: 0.5)),
        'rgba(0, 255, 128, 1)',
      );
      expect(
        themeColorToRgba((alpha: -0.5, red: 0.0, green: 0.0, blue: 0.0)),
        'rgba(0, 0, 0, 0)',
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
        ('scale.bounds', 'data', 'bounds'),
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
        ('plugins.title.position', 'bottom'),
        ('plugins.title.align', 'start'),
        ('plugins.legend.position', 'left'),
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

    test('a raw key that breaks the guard fails an assert', () {
      final themes = <Map<String, Object?>>[
        {
          'raw': <String, Object?>{'backgroundColor': 'red'},
        },
        {
          'raw': <String, Object?>{
            'elements': <String, Object?>{
              'bar': <String, Object?>{'hoverBackgroundColor': 'red'},
            },
          },
        },
        {
          'raw': <String, Object?>{
            'interaction': <String, Object?>{'mode': 'index'},
          },
        },
        {
          'raw': <String, Object?>{
            'hover': <String, Object?>{'mode': 'dataset', 'intersect': false},
          },
        },
        {
          'raw': <String, Object?>{
            'plugins': <String, Object?>{
              'tooltip': <String, Object?>{'mode': 'dataset'},
            },
          },
        },
        {
          'raw': <String, Object?>{
            'plugins': <String, Object?>{'legend': false},
          },
        },
        {
          'raw': <String, Object?>{
            'scales': <String, Object?>{
              'x': <String, Object?>{
                'grid': <String, Object?>{'color': 'red'},
              },
            },
          },
        },
        {
          'raw': <String, Object?>{
            'elements': <String, Object?>{
              'line': <String, Object?>{
                'borderDash': <Object?>[4.0, null],
              },
            },
          },
        },
        {
          'raw': <String, Object?>{'color': null},
        },
      ];
      for (final theme in themes) {
        if (_asserts) {
          expect(
            () => compileChartTheme(theme),
            throwsA(isA<AssertionError>()),
            reason: _json(theme),
          );
        } else {
          // Without asserts, the key is left out and nothing remains.
          expect(compileChartTheme(theme), isNull, reason: _json(theme));
        }
      }
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

    test('a raw plugin behavior path fails an assert', () {
      // Rule 2b. Each path, also inside its plugin Map. A sibling key of
      // the same plugin stays.
      for (final path in themePluginBehaviorPaths) {
        final parts = path.split('.');
        Object? value = 1.0;
        for (final key in parts.reversed) {
          value = <String, Object?>{key: value};
        }
        final theme = <String, Object?>{'raw': value};
        if (_asserts) {
          expect(
            () => compileChartTheme(theme),
            throwsA(isA<AssertionError>()),
            reason: path,
          );
        } else {
          expect(compileChartTheme(theme), isNull, reason: path);
        }
      }
      // A scale path also fails under a scale type.
      final scaleTitle = <String, Object?>{
        'raw': <String, Object?>{
          'scales': <String, Object?>{
            'linear': <String, Object?>{
              'title': <String, Object?>{'text': 'x'},
            },
          },
        },
      };
      if (_asserts) {
        expect(
          () => compileChartTheme(scaleTitle),
          throwsA(isA<AssertionError>()),
          reason: 'scales.linear.title.text',
        );
      } else {
        expect(
          compileChartTheme(scaleTitle),
          isNull,
          reason: 'scales.linear.title.text',
        );
      }
      // The layout keys and the colors of the boxes pass. They move only the
      // layout, and no public input reaches the layout keys (Chart.js ADR
      // 0050, "No public `raw` in 0.1.0").
      final compiled = compileChartTheme({
        'raw': <String, Object?>{
          'plugins': <String, Object?>{
            'legend': <String, Object?>{
              'position': 'left',
              'title': <String, Object?>{'color': 'red'},
            },
            'tooltip': <String, Object?>{'borderColor': 'red'},
          },
        },
      });
      expect(_at(compiled, 'plugins.legend.position'), 'left');
      expect(_at(compiled, 'plugins.legend.title.color'), 'red');
      expect(_at(compiled, 'plugins.tooltip.borderColor'), 'red');
    });

    test('a raw palette that is not a List with items fails an assert', () {
      // Rule 9: an empty List would give i % 0 in hunk H4b, a throw in
      // Dart, and a string one character for each dataset in JavaScript.
      for (final value in <Object?>[
        <Object?>[],
        'red',
        <String, Object?>{'0': 'red'},
        1.0,
      ]) {
        for (final key in [r'$borderColors', r'$backgroundColors']) {
          final theme = <String, Object?>{
            'raw': <String, Object?>{
              'plugins': <String, Object?>{
                'colors': <String, Object?>{key: value},
              },
            },
          };
          if (_asserts) {
            expect(
              () => compileChartTheme(theme),
              throwsA(isA<AssertionError>()),
              reason: '$key ${_json(value)}',
            );
          } else {
            expect(compileChartTheme(theme), isNull, reason: _json(value));
          }
        }
      }
      // A List with a rejected item is left out as a whole.
      final theme = <String, Object?>{
        'raw': <String, Object?>{
          'plugins': <String, Object?>{
            'colors': <String, Object?>{
              r'$borderColors': <Object?>['red', null],
            },
          },
        },
      };
      if (_asserts) {
        expect(() => compileChartTheme(theme), throwsA(isA<AssertionError>()));
      } else {
        expect(compileChartTheme(theme), isNull);
      }
    });

    test(
      'an unknown field or token fails an assert',
      () {
        final themes = <Map<String, Object?>>[
          {'palette2': <String, Object?>{}},
          {
            'colors': <String, Object?>{'outline': _red},
          },
          {
            'colors': <String, Object?>{'color': 'red'},
          },
          {
            'typography': <String, Object?>{'title': <String, Object?>{}},
          },
          {
            'typography': <String, Object?>{
              'pointLabels': <String, Object?>{'variant': 'small-caps'},
            },
          },
          {
            'typography': <String, Object?>{'pointLabels': 10.0},
          },
          {
            'typography': <String, Object?>{
              'font': <String, Object?>{'variant': 'small-caps'},
            },
          },
          {'raw': 'not a map'},
        ];
        for (final theme in themes) {
          if (_asserts) {
            expect(
              () => compileChartTheme(theme),
              throwsA(isA<AssertionError>()),
              reason: _json(theme),
            );
          }
        }
      },
      skip: _asserts ? false : 'n/a: the asserts do not run',
    );
  });

  group('the deep freeze', () {
    test('each Map and List of the result is frozen', () {
      final compiled = compileChartTheme(_testThemes['raw'])!;
      final nodes = _nodes(compiled).toList();
      expect(nodes.length, greaterThan(10));
      for (final (path, node) in nodes) {
        expect(node, isA<JsFreezable>(), reason: path);
        expect(jsObjectIsFrozen(node), isTrue, reason: path);
      }
    });

    test('a write throws a TypeError', () {
      final compiled = compileChartTheme(ChartThemes.light)!;
      final ticks = _at(compiled, 'scale.ticks')! as Map<String, Object?>;
      expect(() => compiled['color'] = 'x', throwsA(isA<TypeError>()));
      expect(() => compiled['other'] = 'x', throwsA(isA<TypeError>()));
      expect(() => ticks['color'] = 'x', throwsA(isA<TypeError>()));
      expect(() => ticks.remove('color'), throwsA(isA<TypeError>()));
      expect(ticks.remove('absent'), isNull);
      expect(ticks.clear, throwsA(isA<TypeError>()));
      expect(
        () => ticks.addAll(<String, Object?>{'a': 1.0}),
        throwsA(isA<TypeError>()),
      );
      expect(ticks.putIfAbsent('color', () => 'x'), 'rgba(102, 102, 102, 1)');
      expect(_at(compiled, 'scale.ticks.color'), 'rgba(102, 102, 102, 1)');

      final dash =
          _at(
                compileChartTheme(_testThemes['raw']),
                'elements.line.borderDash',
              )!
              as List<Object?>;
      expect(() => dash[0] = 1.0, throwsA(isA<TypeError>()));
      expect(() => dash.add(1.0), throwsA(isA<TypeError>()));
      expect(() => dash.length = 0, throwsA(isA<TypeError>()));
      expect(dash, [4.0, 2.0]);
    });

    test('a resolver write into a theme scope throws', () {
      // theming.md §3.3: without plugins.<id> in the options and the
      // overrides, the theme map is scopes[0], the target of the set trap.
      final compiled = compileChartTheme(_testThemes['raw']);
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
      expect(resolver['borderColor'], 'red');
      expect(() => resolver['borderColor'] = 'x', throwsA(isA<TypeError>()));
    });
  });

  group('the memo', () {
    test('the same theme gives the same result', () {
      final theme = <String, Object?>{
        'colors': <String, Object?>{'color': _red},
      };
      final first = compileChartTheme(theme);
      expect(compileChartTheme(theme), same(first));
      expect(
        compileChartTheme(ChartThemes.light),
        same(compileChartTheme(ChartThemes.light)),
      );
    });

    test('an equal theme compiles again', () {
      Map<String, Object?> theme() => {
        'colors': <String, Object?>{'color': _red},
      };
      final a = compileChartTheme(theme());
      final b = compileChartTheme(theme());
      expect(b, isNot(same(a)));
      expect(_json(b), _json(a));
    });

    test('a theme that compiles to null stays null', () {
      final theme = <String, Object?>{'colors': <String, Object?>{}};
      expect(compileChartTheme(theme), isNull);
      expect(compileChartTheme(theme), isNull);
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

    test('ChartThemes.none compiles to null', () {
      expect(compileChartTheme(ChartThemes.none), isNull);
    });

    test('ChartThemes.none adds no scope', () {
      final c = config(compileChartTheme(ChartThemes.none));
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
      final theme = compileChartTheme(ChartThemes.light);
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

      final theme = compileChartTheme(ChartThemes.light);
      expect(animation(theme, 'theme', 'animation.duration'), 200.0);
      expect(animation(theme, 'theme', 'animation.easing'), 'linear');
      expect(animation(theme, 'themeFrame', 'animation.duration'), 0.0);
      expect(
        animation(theme, 'themeFrame', 'animation.easing'),
        'easeOutQuart',
      );
      // The other modes keep the upstream values.
      expect(animation(theme, 'active', 'animation.duration'), 400.0);
      expect(animation(theme, 'default', 'animation.duration'), 1000.0);
      // No theme: the upstream defaults (core.animations.defaults.js:4-5).
      expect(animation(null, 'theme', 'animation.duration'), 1000.0);
      expect(animation(null, 'theme', 'animation.easing'), 'easeOutQuart');
    });
  });

  group('theming.md §8 test 5, without a chart', () {
    test('the presets and the test themes compile only to allowed paths', () {
      for (final name in _testThemes.keys) {
        final compiled = compileChartTheme(_testThemes[name])!;
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
      final theme = <String, Object?>{
        'raw': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'ticks': <String, Object?>{'color': 'red'},
            },
          },
        },
      };
      if (_asserts) {
        expect(() => compileChartTheme(theme), throwsA(isA<AssertionError>()));
      } else {
        expect(compileChartTheme(theme), isNull);
      }
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
      final theme = compileChartTheme({
        'raw': <String, Object?>{
          'scales': <String, Object?>{
            'radialLinear': <String, Object?>{
              'pointLabels': <String, Object?>{'color': 'red'},
            },
          },
        },
      });
      Object? scales(String type) => Config(<String, Object?>{
        'type': type,
        'data': <String, Object?>{
          'datasets': [<String, Object?>{}],
        },
        'options': <String, Object?>{},
        themeConfigKey: theme,
      }).options['scales'];

      expect(jsObjectKeys(scales('tbar')! as Map<String, Object?>), ['x', 'y']);
      expect(scales('tdough'), <String, Object?>{});
    });
  });
}
