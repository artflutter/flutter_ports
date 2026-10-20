// Original code, not ported from Chart.js: theme precedence on charts.
@TestOn('vm')
library;

import 'dart:convert';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs/src/core/core.config.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/core/core.datasetController.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show resolveObjectKey;
import 'package:flutter_chartjs/src/helpers/helpers.options.dart' show toFont;
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/theme/compile.dart';
import 'package:flutter_chartjs/src/theme/presets.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import 'precedence_reference.dart';

// theming.md §8 test 1 at the chart level and the rows of §8 test 2 that
// need no palette, with test-registered components (theming.md §10, the
// phase 5 row). The test file core.config_test.dart has the same tests at
// the Config level, with raw Map themes and direct writes.
//
// main() registers two dataset controllers with a point element
// (`themeTest` and `themeTest2`), the scale `themeLinear` and the plugin
// `themeProbe` through their class values and Maps, before the snapshot of
// the defaults restore (Chart.js ADR 0020, section 8, and Chart.js ADR 0022,
// section 8). The built-in elements come from flutter_test_config.dart. Each
// chart comes from acquireChart of the harness (Chart.js ADR 0022). The
// theme Map goes into the raw configuration under `$theme`, as the chart
// widget of phase 9 puts it there (theming.md §3.1).
//
// A row of a precedence table sets one sentinel at each level of theming.md
// §3.2 from its level down. Its expected value is the sentinel of the
// highest level. A row writes into `defaults` and `overrides`. The restore of
// the harness removes these writes after the test (`harness-defaults-restore`).
//
// The expected values are in precedence_reference.dart. The generator
// tool/reference/theme_precedence_reference.mjs runs each case in Node.js
// v24.12.0 on x64 twice: with the upstream src/core/core.config.js, which
// ignores the theme, and with a JavaScript prototype of the hunks H0-H3. A
// case without a theme must give the upstream result. A case with a theme
// must give the result of the prototype.
//
// These rows wait for plugin.colors (phase 8), with the hunks H4a-H4c and H5
// (the group 'waits for phase 8'): the palette beats the theme element
// colors, user colors disable the palette, a theme without a palette keeps
// the upstream palette, and two interleaved charts keep their own palettes.

// ---------------------------------------------------------------------------
// The registered components.

/// The dataset controller of the generator: it places each point at its
/// parsed x and y.
final class _ThemeController extends DatasetController {
  _ThemeController(super.chart, super.datasetIndex, [super.newTarget]);

  @override
  void update(String mode) {
    final meta = cachedMeta;
    updateElements(meta.data, 0, meta.data.length.toDouble(), mode);
  }

  @override
  void updateElements(
    List<types.Element> points,
    double start,
    double count,
    String mode,
  ) {
    final meta = cachedMeta;
    final iScale = meta.iScale!;
    final vScale = meta.vScale!;
    final (:sharedOptions, :includeOptions) = getSharedOptions_(start, mode);
    for (var i = start; i < start + count; ++i) {
      final point = points[i.toInt()] as Element;
      final parsed = getParsed(i);
      final properties = <String, Object?>{
        'x': iScale.getPixelForValue(jsToNumber(jsGet(parsed, 'x')), i),
        'y': vScale.getPixelForValue(jsToNumber(jsGet(parsed, 'y')), i),
      };
      if (includeOptions) {
        properties['options'] =
            sharedOptions ??
            resolveDataElementOptions(i, point.active ? 'active' : mode);
      }
      updateElement(point, i, properties, mode);
    }
  }
}

/// The class value of the dataset controller [id]: a point element, and the
/// scales `_index_` and `_value_` of the type `themeLinear` in its
/// overrides.
JsClass _themeController(String id) => JsClass(
  'ThemeController',
  superclass: DatasetController.jsClass,
  statics: {
    'id': id,
    'defaults': <String, Object?>{
      'datasetElementType': false,
      'dataElementType': 'point',
    },
    'overrides': <String, Object?>{
      'scales': <String, Object?>{
        '_index_': <String, Object?>{'type': 'themeLinear'},
        '_value_': <String, Object?>{'type': 'themeLinear'},
      },
    },
  },
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return _ThemeController(chart, datasetIndex, newTarget);
  },
);

/// The scale `themeLinear` of the generator: the range 0 to 10, with the
/// ticks 0, 5 and 10.
final class _ThemeScale extends Scale {
  _ThemeScale(super.cfg);

  @override
  void determineDataLimits() {
    min = 0;
    max = 10;
  }

  @override
  List<Tick>? buildTicks() => [Tick(value: 0), Tick(value: 5), Tick(value: 10)];

  @override
  double getPixelForValue(double value, [double? index]) {
    return getPixelForDecimal((value - min) / (max - min));
  }
}

/// The class value of the scale `themeLinear`.
final JsClass _themeScale = JsClass(
  'ThemeScale',
  superclass: Scale.jsClass,
  statics: {'id': 'themeLinear', 'defaults': <String, Object?>{}},
  construct: (newTarget, args) => _ThemeScale(scaleCfgArg(args)),
);

/// The option `k` that the plugin `themeProbe` saw last.
Object? _probeK = 'unset';

/// The plugin `themeProbe`: it keeps its option `k` in `afterUpdate`.
final AnyObject _themeProbe = <String, Object?>{
  'id': 'themeProbe',
  'afterUpdate': (Object? chart, Object? args, Object? options) {
    _probeK = jsGet(options, 'k');
  },
};

// ---------------------------------------------------------------------------
// The observations.

/// `JSON.stringify(value, replacer)` with the replacer of the generator:
/// `undefined` is `"<undefined>"` and a function is `"<fn>"`. A Map gives its
/// keys in the `Object.keys` order.
String _json(Object? value) => switch (value) {
  null => 'null',
  Undefined() => '"<undefined>"',
  final bool b => b ? 'true' : 'false',
  final num n => jsNumberToString(n),
  final String s => jsonEncode(s),
  _ when jsIsFunction(value) => '"<fn>"',
  final List<Object?> list => '[${list.map(_json).join(',')}]',
  final Map<String, Object?> map =>
    '{${jsObjectKeys(map).map((k) => _entry(map, k)).join(',')}}',
  _ => throw ArgumentError.value(value, 'value', 'has no JSON form'),
};

/// The JSON member `"key":value` of [key] in [map].
String _entry(Map<String, Object?> map, String key) =>
    '${jsonEncode(key)}:${_json(map[key])}';

/// The text of the observed [value]: a string is the string, another value
/// is its JSON.
String _text(Object? value) => value is String ? value : _json(value);

/// The lines `<label>: <value>` of the scenario [name] of [reference], by
/// label.
Map<String, String> _lines(Map<String, String> reference, String name) {
  final text = reference[name];
  if (text == null) throw ArgumentError.value(name, 'name', 'no scenario');
  return {
    for (final line in text.split('\n'))
      line.substring(0, line.indexOf(': ')): line.substring(
        line.indexOf(': ') + 2,
      ),
  };
}

/// The value of [label] in the scenario [name] with the upstream
/// core.config.js.
String _upstream(String name, String label) =>
    _lines(themePrecedenceUpstream, name)[label]!;

/// The value of [label] in the scenario [name] with the prototype of the
/// hunks H0-H3.
String _prototype(String name, String label) =>
    _lines(themePrecedencePrototype, name)[label]!;

// ---------------------------------------------------------------------------
// The fixtures.

/// The data of a dataset: two points.
List<Object?> _points() => <Object?>[
  <String, Object?>{'x': 1, 'y': 2},
  <String, Object?>{'x': 5, 'y': 8},
];

/// Writes [value] at the dot path [path] of the global scope [root], and
/// creates the missing objects. The restore of the harness removes the write
/// after the test.
void _put(Map<String, Object?> root, String path, Object? value) {
  final keys = path.split('.');
  var node = root;
  for (final key in keys.sublist(0, keys.length - 1)) {
    final next = node[key];
    if (next is Map<String, Object?>) {
      node = next;
    } else {
      final created = <String, Object?>{};
      node[key] = created;
      node = created;
    }
  }
  node[keys.last] = value;
}

/// The value at the dot path [path] of [root].
Object? _at(Object? root, String path) {
  var node = root;
  for (final key in path.split('.')) {
    node = jsGet(node, key);
  }
  return node;
}

/// The first data element of the dataset 0 of [chart].
Element _point(Chart chart, [int index = 0]) =>
    chart.getDatasetMeta(0).data[index] as Element;

/// The label of a row of [levels].
String _rowLabel(List<String> levels) =>
    levels.isEmpty ? 'none' : levels.join('+');

/// One test for each row of the table [levels] of the scenario [scenario]:
/// the levels from the level `i` down. [body] builds the chart of a row and
/// gives the observed value. [themeLevels] are the levels of the theme. A row
/// without them is an unthemed chart: it also gives the upstream value.
void _rows(
  String scenario,
  List<String> levels,
  List<String> themeLevels,
  Object? Function(List<String> levels) body,
) {
  for (var i = 0; i <= levels.length; i++) {
    final subset = levels.sublist(i);
    final label = _rowLabel(subset);
    final expected = _prototype(scenario, label);
    final themed = subset.any(themeLevels.contains);
    testWidgets('${subset.isEmpty ? 'no level' : subset.first} wins: '
        '$label gives $expected', (tester) async {
      final observed = _text(body(subset));
      expect(observed, expected);
      if (!themed) expect(observed, _upstream(scenario, label));
    });
  }
}

/// The raw Map theme of the scenarios 'a compiled theme': each color token
/// and the font token of phase 5 (theming.md §4).
const AnyObject _tokenTheme = <String, Object?>{
  'colors': <String, Object?>{
    'color': (alpha: 1.0, red: 0.2, green: 0.4, blue: 0.6),
    'borderColor': (alpha: 0.5, red: 0.0, green: 0.5, blue: 0.0),
    'backgroundColor': (alpha: 1.0, red: 200 / 255, green: 0.0, blue: 0.0),
    'surface': (alpha: 1.0, red: 0.0, green: 0.0, blue: 0.0),
  },
  'typography': <String, Object?>{
    'font': <String, Object?>{'family': 'Arial', 'size': 14.0},
  },
};

/// The no-theme marker of [_snapshot] and [_scopes]: no `$theme` key.
const Object _absent = Object();

/// The observations of a snapshot scenario of the generator: the options of
/// a chart with the `$theme` value [theme] ([_absent] for no key). [user]
/// adds user values.
List<String> _snapshot(Object? theme, {bool user = false}) {
  final lines = <String>[];
  void observe(String label, Object? value) =>
      lines.add('$label: ${_text(value)}');

  final dataset = <String, Object?>{'data': _points()};
  final options = <String, Object?>{};
  if (user) {
    dataset['backgroundColor'] = 'rgb(0, 0, 255)';
    options['scales'] = <String, Object?>{
      'x': <String, Object?>{
        'ticks': <String, Object?>{'color': 'user-ticks'},
      },
    };
    options['color'] = 'user-color';
  }
  if (theme != null && !identical(theme, _absent) && theme is! String) {
    observe('theme', theme);
  }
  _probeK = 'unset';
  final chart = acquireChart(<String, Object?>{
    'type': 'themeTest',
    'data': <String, Object?>{
      'datasets': [dataset],
    },
    'options': options,
    if (!identical(theme, _absent)) themeConfigKey: theme,
  });
  final meta = chart.getDatasetMeta(0);
  observe('element', _point(chart).options);
  observe(
    'same options',
    identical(_point(chart).options, _point(chart, 1).options),
  );
  observe('active', meta.controller!.resolveDataElementOptions(0, 'active'));
  observe('scales', chart.config.options['scales']);
  final x = chart.scales['x']!;
  observe('scale x', [
    _at(x.options, 'ticks.color'),
    _at(x.options, 'ticks.backdropColor'),
    _at(x.options, 'grid.color'),
    _at(x.options, 'border.color'),
    _at(x.options, 'title.color'),
  ]);
  final tickFont = x.resolveTickFontOptions(0);
  final titleFont = toFont(_at(x.options, 'title.font'));
  observe('scale x fonts', [
    tickFont.family,
    tickFont.size,
    tickFont.string,
    titleFont.family,
    titleFont.size,
    titleFont.string,
  ]);
  final o = chart.options;
  observe('chart', [
    o['color'],
    o['backgroundColor'],
    o['borderColor'],
    _at(o, 'font.family'),
    _at(o, 'font.size'),
    _at(o, 'font.style'),
    _at(o, 'font.weight'),
    _at(o, 'font.lineHeight'),
  ]);
  observe('plugin', _probeK);
  return lines;
}

/// The label of each scope: a known object by name, a new empty object as
/// `{}#<n>`, another object as `?` and its JSON.
String Function(Object?) _labeller(List<(Object?, String)> named) {
  final names = Map<Object?, String>.identity();
  for (final (value, name) in named) {
    if (!identical(value, undefined)) names[value] = name;
  }
  final seen = Map<Object?, String>.identity();
  var fresh = 0;
  return (scope) {
    final name = names[scope] ?? seen[scope];
    if (name != null) return name;
    final label = scope is Map<String, Object?> && jsObjectKeys(scope).isEmpty
        ? '{}#${fresh++}'
        : '?${_json(scope)}';
    seen[scope] = label;
    return label;
  };
}

/// The observations of the scope lists of a chart with the `$theme` value
/// [theme] ([_absent] for no key, Dart `true` for the theme of the
/// scenario).
List<String> _scopes(Object? theme) {
  final lines = <String>[];
  _put(overrides, 'themeTest.elements.point.radius', 4.0);
  _put(overrides, 'themeTest.plugins.themeProbe.k', 'o');
  final dataset = <String, Object?>{'data': _points()};
  final options = <String, Object?>{
    'datasets': <String, Object?>{'themeTest': <String, Object?>{}},
    'elements': <String, Object?>{'point': <String, Object?>{}},
    'plugins': <String, Object?>{'themeProbe': <String, Object?>{}},
  };
  final scenarioTheme = <String, Object?>{
    'datasets': <String, Object?>{
      'themeTest': <String, Object?>{
        'elements': <String, Object?>{'point': <String, Object?>{}},
      },
    },
    'elements': <String, Object?>{'point': <String, Object?>{}},
    'plugins': <String, Object?>{'themeProbe': <String, Object?>{}},
    'transitions': <String, Object?>{'theme': <String, Object?>{}},
  };
  final c = acquireChart(<String, Object?>{
    'type': 'themeTest',
    'data': <String, Object?>{
      'datasets': [dataset],
    },
    'options': options,
    if (!identical(theme, _absent))
      themeConfigKey: theme == true ? scenarioTheme : theme,
  }).config;
  Object? at(Object? root, String path) => resolveObjectKey(root, path);
  final label = _labeller([
    (dataset, 'dataset'),
    (c.options, 'options'),
    (at(c.options, 'datasets.themeTest'), 'options.datasets.themeTest'),
    (at(c.options, 'elements.point'), 'options.elements.point'),
    (at(c.options, 'plugins.themeProbe'), 'options.plugins.themeProbe'),
    (overrides['themeTest'], 'overrides.themeTest'),
    (
      at(overrides, 'themeTest.elements.point'),
      'overrides.themeTest.elements.point',
    ),
    (
      at(overrides, 'themeTest.plugins.themeProbe'),
      'overrides.themeTest.plugins.themeProbe',
    ),
    (scenarioTheme, 'theme'),
    (at(scenarioTheme, 'datasets.themeTest'), 'theme.datasets.themeTest'),
    (
      at(scenarioTheme, 'datasets.themeTest.elements.point'),
      'theme.datasets.themeTest.elements.point',
    ),
    (at(scenarioTheme, 'elements.point'), 'theme.elements.point'),
    (at(scenarioTheme, 'plugins.themeProbe'), 'theme.plugins.themeProbe'),
    (at(scenarioTheme, 'transitions.theme'), 'theme.transitions.theme'),
    (defaults, 'defaults'),
    (at(defaults, 'datasets.themeTest'), 'defaults.datasets.themeTest'),
    (at(defaults, 'elements.point'), 'defaults.elements.point'),
    (at(defaults, 'plugins.themeProbe'), 'defaults.plugins.themeProbe'),
    (descriptors, 'descriptors'),
  ]);
  void observe(String what, List<Object?> scopes) =>
      lines.add('$what: ${scopes.map(label).join(' ')}');
  observe(
    'element',
    c.getOptionScopes(dataset, c.datasetElementScopeKeys('themeTest', 'point')),
  );
  observe(
    'dataset',
    c.getOptionScopes(dataset, c.datasetScopeKeys('themeTest')),
  );
  observe(
    'animation',
    c.getOptionScopes(
      dataset,
      c.datasetAnimationScopeKeys('themeTest', 'theme'),
    ),
  );
  observe(
    'plugin',
    c.getOptionScopes(
      at(c.options, 'plugins.themeProbe'),
      c.pluginScopeKeys(_themeProbe),
    ),
  );
  observe('chart', c.chartOptionScopes());
  return lines;
}

void main() {
  Chart.register([
    _themeController('themeTest'),
    _themeController('themeTest2'),
    _themeScale,
    _themeProbe,
  ]);

  test('the reference comes from Node.js v24.12.0 on x64', () {
    expect(themePrecedenceReferenceNode, 'v24.12.0');
    expect(themePrecedenceReferenceArch, 'x64');
  });

  group('test 1: no theme equals upstream', () {
    // theming.md §8 test 1 at the chart level (hunks H0, H2 and H3).
    testWidgets('a chart without a theme resolves the upstream options', (
      tester,
    ) async {
      expect(
        _snapshot(_absent).join('\n'),
        themePrecedenceUpstream['no theme'],
      );
    });

    testWidgets('a chart with user values resolves the upstream options', (
      tester,
    ) async {
      expect(
        _snapshot(_absent, user: true).join('\n'),
        themePrecedenceUpstream['user values'],
      );
    });

    testWidgets('a theme that is null or not a Map is no theme', (
      tester,
    ) async {
      expect(
        _snapshot(null).join('\n'),
        themePrecedenceUpstream['a null theme'],
      );
      expect(
        _snapshot('not a map').join('\n'),
        themePrecedenceUpstream['a string theme'],
      );
      // The upstream resolver ignores the key `$theme`: all three equal the
      // chart without the key.
      expect(
        themePrecedenceUpstream['a null theme'],
        themePrecedenceUpstream['no theme'],
      );
      expect(
        themePrecedenceUpstream['a string theme'],
        themePrecedenceUpstream['no theme'],
      );
    });

    testWidgets('ChartThemes.none compiles to null and changes no option', (
      tester,
    ) async {
      final none = compileChartTheme(ChartThemes.none);
      expect(none, isNull);
      expect(_snapshot(none).join('\n'), themePrecedenceUpstream['no theme']);
    });

    testWidgets('no theme adds no scope', (tester) async {
      expect(
        _scopes(_absent).join('\n'),
        themePrecedenceUpstream['scopes without a theme'],
      );
    });

    testWidgets('a theme that is null or not a Map adds no scope', (
      tester,
    ) async {
      expect(
        _scopes(null).join('\n'),
        themePrecedenceUpstream['scopes with a null theme'],
      );
      expect(
        _scopes('not a map').join('\n'),
        themePrecedenceUpstream['scopes with a string theme'],
      );
      expect(
        _scopes(compileChartTheme(ChartThemes.none)).join('\n'),
        themePrecedenceUpstream['scopes without a theme'],
      );
    });

    testWidgets('the theme scopes take the position of theming.md §3.2', (
      tester,
    ) async {
      // Between the type overrides and the defaults for the dataset, element,
      // animation and plugin options (H2), and after the type overrides for
      // the chart options (H3).
      expect(
        _scopes(true).join('\n'),
        themePrecedencePrototype['scopes with a theme'],
      );
    });

    testWidgets('the unthemed cases give the same result with the hunks', (
      tester,
    ) async {
      // The prototype of the hunks equals upstream when no theme is there.
      for (final name in [
        'no theme',
        'a null theme',
        'a string theme',
        'user values',
        'scopes without a theme',
        'scopes with a null theme',
        'scopes with a string theme',
      ]) {
        expect(
          themePrecedencePrototype[name],
          themePrecedenceUpstream[name],
          reason: name,
        );
      }
    });

    testWidgets('a compiled theme fills the options below the user options', (
      tester,
    ) async {
      final compiled = compileChartTheme(_tokenTheme);
      expect(
        _snapshot(compiled).join('\n'),
        themePrecedencePrototype['a compiled theme'],
      );
      expect(
        _snapshot(compiled, user: true).join('\n'),
        themePrecedencePrototype['a compiled theme and user values'],
      );
    });
  });

  group('test 2: precedence', () {
    // theming.md §8 test 2, the rows without the palette (hunks H1, H2 and
    // H3). User colors beat the theme in each table.
    group('elements', () {
      _rows(
        'elements',
        const [
          'dataset',
          'options',
          'overrides',
          'theme',
          'controllerDefaults',
          'elementDefaults',
          'rootDefaults',
        ],
        const ['theme'],
        (levels) {
          final dataset = <String, Object?>{'data': _points()};
          final options = <String, Object?>{};
          final theme = <String, Object?>{};
          if (levels.contains('dataset')) {
            dataset['backgroundColor'] = 'E1-dataset';
          }
          if (levels.contains('options')) {
            options['elements'] = <String, Object?>{
              'point': <String, Object?>{'backgroundColor': 'E2-options'},
            };
          }
          if (levels.contains('overrides')) {
            _put(
              overrides,
              'themeTest.elements.point.backgroundColor',
              'E3-overrides',
            );
          }
          if (levels.contains('theme')) {
            theme['elements'] = <String, Object?>{
              'point': <String, Object?>{'backgroundColor': 'E4-theme'},
            };
          }
          if (levels.contains('controllerDefaults')) {
            _put(
              defaults,
              'datasets.themeTest.backgroundColor',
              'E5-controller-defaults',
            );
          }
          if (levels.contains('elementDefaults')) {
            _put(
              defaults,
              'elements.point.backgroundColor',
              'E6-element-defaults',
            );
          }
          if (levels.contains('rootDefaults')) {
            _put(defaults, 'backgroundColor', 'E7-root-defaults');
          }
          final chart = acquireChart(<String, Object?>{
            'type': 'themeTest',
            'data': <String, Object?>{
              'datasets': [dataset],
            },
            'options': options,
            if (levels.contains('theme')) themeConfigKey: theme,
          });
          return _point(chart).options!['backgroundColor'];
        },
      );

      /// The active and the default `backgroundColor` of a chart with the
      /// theme color `rgb(200, 0, 0)` ([themed]) and a user hover color
      /// ([userHover]).
      List<Object?> active({required bool themed, bool userHover = false}) {
        final dataset = <String, Object?>{'data': _points()};
        if (userHover) dataset['hoverBackgroundColor'] = 'E1-dataset-hover';
        final chart = acquireChart(<String, Object?>{
          'type': 'themeTest',
          'data': <String, Object?>{
            'datasets': [dataset],
          },
          'options': <String, Object?>{},
          if (themed)
            themeConfigKey: <String, Object?>{
              'elements': <String, Object?>{
                'point': <String, Object?>{'backgroundColor': 'rgb(200, 0, 0)'},
              },
            },
        });
        final meta = chart.getDatasetMeta(0);
        return [
          meta.controller!.resolveDataElementOptions(
            0,
            'active',
          )['backgroundColor'],
          _point(chart).options!['backgroundColor'],
        ];
      }

      testWidgets('the defaults derive the hover color of an unthemed chart', (
        tester,
      ) async {
        final observed = _text(active(themed: false));
        expect(observed, _upstream('active', 'unthemed'));
        expect(observed, _prototype('active', 'unthemed'));
      });

      testWidgets('the defaults derive the hover color from the theme color', (
        tester,
      ) async {
        expect(_text(active(themed: true)), _prototype('active', 'themed'));
      });

      testWidgets('a user hover color beats the derived hover color', (
        tester,
      ) async {
        expect(
          _text(active(themed: true, userHover: true)),
          _prototype('active', 'themed with a user hover color'),
        );
      });
    });

    group('scales', () {
      _rows(
        'scales',
        const [
          'user',
          'chartOverrides',
          'datasetOverrides',
          'themeType',
          'themeScale',
          'scaleDefaults',
          'scaleBase',
          'rootColor',
        ],
        const ['themeType', 'themeScale'],
        (levels) {
          // The user scale `x` is always there: the chart-type overrides
          // merge only into a scale of the user options
          // (core.config.js:76-89).
          final x = <String, Object?>{};
          final theme = <String, Object?>{};
          if (levels.contains('user')) {
            x['ticks'] = <String, Object?>{'color': 'S1-user'};
          }
          if (levels.contains('chartOverrides')) {
            _put(
              overrides,
              'themeTest.scales._index_.ticks.color',
              'S2-chart-overrides',
            );
          }
          if (levels.contains('datasetOverrides')) {
            _put(
              overrides,
              'themeTest2.scales._index_.ticks.color',
              'S3-dataset-overrides',
            );
          }
          if (levels.contains('themeType')) {
            theme['scales'] = <String, Object?>{
              'themeLinear': <String, Object?>{
                'ticks': <String, Object?>{'color': 'S4-theme-type'},
              },
            };
          }
          if (levels.contains('themeScale')) {
            theme['scale'] = <String, Object?>{
              'ticks': <String, Object?>{'color': 'S5-theme-scale'},
            };
          }
          if (levels.contains('scaleDefaults')) {
            _put(
              defaults,
              'scales.themeLinear.ticks.color',
              'S6-scale-defaults',
            );
          }
          if (levels.contains('scaleBase')) {
            _put(defaults, 'scale.ticks.color', 'S7-scale-base');
          }
          if (levels.contains('rootColor')) {
            _put(defaults, 'color', 'S8-root-color');
          }
          final chart = acquireChart(<String, Object?>{
            'type': 'themeTest',
            'data': <String, Object?>{
              'datasets': [
                <String, Object?>{'type': 'themeTest2', 'data': _points()},
              ],
            },
            'options': <String, Object?>{
              'scales': <String, Object?>{'x': x},
            },
            if (levels.contains('themeType') || levels.contains('themeScale'))
              themeConfigKey: theme,
          });
          return [
            _at(chart.scales['x']!.options, 'ticks.color'),
            jsObjectKeys(chart.scales).join(','),
          ];
        },
      );
    });

    group('plugins', () {
      _rows(
        'plugins',
        const ['user', 'overrides', 'theme', 'defaults'],
        const ['theme'],
        (levels) {
          final options = <String, Object?>{};
          final theme = <String, Object?>{};
          if (levels.contains('user')) {
            options['plugins'] = <String, Object?>{
              'themeProbe': <String, Object?>{'k': 'P1-user'},
            };
          }
          if (levels.contains('overrides')) {
            _put(overrides, 'themeTest.plugins.themeProbe.k', 'P2-overrides');
          }
          if (levels.contains('theme')) {
            theme['plugins'] = <String, Object?>{
              'themeProbe': <String, Object?>{'k': 'P3-theme'},
            };
          }
          if (levels.contains('defaults')) {
            _put(defaults, 'plugins.themeProbe.k', 'P4-defaults');
          }
          _probeK = 'unset';
          acquireChart(<String, Object?>{
            'type': 'themeTest',
            'data': <String, Object?>{
              'datasets': [
                <String, Object?>{'data': _points()},
              ],
            },
            'options': options,
            if (levels.contains('theme')) themeConfigKey: theme,
          });
          return _probeK;
        },
      );
    });

    group('chart level', () {
      _rows(
        'chart level',
        const ['user', 'overrides', 'theme', 'datasetDefaults', 'defaults'],
        const ['theme'],
        (levels) {
          final options = <String, Object?>{};
          final theme = <String, Object?>{};
          if (levels.contains('user')) options['color'] = 'C1-user';
          if (levels.contains('overrides')) {
            _put(overrides, 'themeTest.color', 'C2-overrides');
          }
          if (levels.contains('theme')) theme['color'] = 'C3-theme';
          if (levels.contains('datasetDefaults')) {
            _put(defaults, 'datasets.themeTest.color', 'C4-dataset-defaults');
          }
          if (levels.contains('defaults')) {
            _put(defaults, 'color', 'C5-defaults');
          }
          final chart = acquireChart(<String, Object?>{
            'type': 'themeTest',
            'data': <String, Object?>{
              'datasets': [
                <String, Object?>{'data': _points()},
              ],
            },
            'options': options,
            if (levels.contains('theme')) themeConfigKey: theme,
          });
          return chart.options['color'];
        },
      );
    });

    group('waits for phase 8', () {
      // The palette rows of theming.md §8 test 2 and the pins of the hunks
      // H4a-H4c and H5 need the port of plugin.colors.
      for (final name in [
        'the theme palette beats the theme element colors',
        'user colors disable the theme palette',
        'a theme without a palette keeps the upstream palette',
        'two interleaved charts keep their own palettes',
      ]) {
        test(name, () {}, skip: 'blocked: plugin.colors');
      }
    });
  });
}
