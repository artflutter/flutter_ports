// Original code, not ported from Chart.js: theme precedence on charts.
@TestOn('vm')
library;

import 'dart:convert';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:chartjs_test_utils/pure.dart' show createMockContext;
import 'package:flutter_chartjs_port/src/core/core.config.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/elements/element.point.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show resolveObjectKey;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show toFont;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/color.dart' as kurkle;
import 'package:flutter_chartjs_port/src/plugins/plugin.colors.dart';
import 'package:flutter_chartjs_port/src/scales/scale.category.dart';
import 'package:flutter_chartjs_port/src/scales/scale.linear.dart';
import 'package:flutter_chartjs_port/src/scales/scale.radialLinear.dart';
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import 'precedence_reference.dart';

// theming.md §8 test 1 at the chart level and the rows of §8 test 2 that
// need no palette, with test-registered components (theming.md §10, the
// phase 5 row). The test file core.config_test.dart has the same tests at
// the Config level, with raw Map themes and direct writes.
//
// The phase 6 row of theming.md §10 adds the hunk H1 with real scales: the
// precedence tables of the category, linear and radial linear scales, the
// options of a radial scale under a compiled theme and under the values that
// the tokens replace in `defaults` (theming.md §4), the part of §8 test 5
// that needs no controller of phase 7 (a theme key `scales.<scale type>`
// creates no axis), and the singleton read at scale.radialLinear.js:14
// (theming.md §9).
//
// The phase 7 row of theming.md §10 adds §8 test 5 on the real bar and
// doughnut controllers, and the group `hover` on the 8 chart types
// (Chart.js ADR 0030, sections 9 and 10). flutter_test_config.dart
// registers the 8 controllers with the built-in components.
//
// main() registers two dataset controllers with a point element
// (`themeTest` and `themeTest2`), the scale `themeLinear` and the plugin
// `themeProbe` through their class values and Maps, before the snapshot of
// the defaults restore (Chart.js ADR 0020, section 8, and Chart.js ADR 0022,
// section 8). For the real scales, it also registers the category, linear
// and radial linear scales, two dataset controllers `themeReal` and
// `themeReal2` with these scales, and the radial test controller
// `themeRadial`. The scales are built-in components now, and the second
// registration changes nothing. The built-in elements and the 8 controllers
// come from flutter_test_config.dart. Each chart comes from acquireChart of the
// harness (Chart.js ADR 0022). The theme Map goes into the raw configuration
// under `$theme`, as the chart widget of phase 9 puts it there (theming.md
// §3.1).
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
// Phase 8 adds the palette of plugin.colors (Chart.js ADR 0042, the hunks
// H4a, H4b, H4c and H5). The group 'palette' of test 2 has the palette rows:
// the palette beats the theme element colors, user colors disable the
// palette, a theme without a palette keeps the upstream palette, two
// interleaved charts keep their own palettes, a palette key outside the
// theme has no effect, an empty or non-List theme palette keeps the upstream
// palette, the palette keys equal the keys of the compiler, and a removed
// theme gives the upstream palette. The group 'test 3: the light palette'
// compares the 8 chart types with the light preset and without a theme
// (theming.md §8 test 3). For these scenarios, the generator also runs the
// pinned src/plugins/plugin.colors.ts, with a JavaScript prototype of the
// hunks H4a-H5 in the prototype run.
//
// flutter_test_config.dart registers the plugins with the built-in
// components and sets `defaults.plugins.colors.enabled = false`, as
// test/index.js:25-28 does (Chart.js ADR 0041, sections 1 and 6). Each
// palette chart sets `plugins.colors.enabled: true`.

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
        'x': iScale.getPixelForValue(jsGet(parsed, 'x'), i),
        'y': vScale.getPixelForValue(jsGet(parsed, 'y'), i),
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
/// scales `_index_` and `_value_` of the types [indexType] and [valueType]
/// in its overrides.
JsClass _themeController(
  String id, [
  String indexType = 'themeLinear',
  String valueType = 'themeLinear',
]) => JsClass(
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
        '_index_': <String, Object?>{'type': indexType},
        '_value_': <String, Object?>{'type': valueType},
      },
    },
  },
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return _ThemeController(chart, datasetIndex, newTarget);
  },
);

/// The radial test controller of the generator: a point for each value, at
/// the position of `getPointPositionForValue` of the scale r
/// (controller.radar.js:81-103 without the line).
final class _RadialThemeController extends DatasetController {
  _RadialThemeController(super.chart, super.datasetIndex, [super.newTarget]);

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
    final scale = cachedMeta.rScale! as RadialLinearScale;
    for (var i = start; i < start + count; i++) {
      final position = scale.getPointPositionForValue(
        i,
        jsGet(getParsed(i), 'r'),
      );
      updateElement(points[i.toInt()] as Element, i, {
        'x': position.x,
        'y': position.y,
        'angle': position.angle,
        'options': resolveDataElementOptions(i, mode),
      }, mode);
    }
  }
}

/// The class value of the radial test controller `themeRadial`: a point
/// element, the index axis `r` and the scale `r` of the type `radialLinear`
/// in its overrides, as controller.radar.js:11-34 has them.
final JsClass _radialThemeController = JsClass(
  'RadialController',
  superclass: DatasetController.jsClass,
  statics: {
    'id': 'themeRadial',
    'defaults': <String, Object?>{
      'datasetElementType': false,
      'dataElementType': 'point',
      'indexAxis': 'r',
    },
    'overrides': <String, Object?>{
      'scales': <String, Object?>{
        'r': <String, Object?>{'type': 'radialLinear'},
      },
    },
  },
  construct: (newTarget, args) {
    final (:chart, :datasetIndex) = controllerArgs(args);
    return _RadialThemeController(chart, datasetIndex, newTarget);
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
  double getPixelForValue(Object? value, [double? index]) {
    return getPixelForDecimal((jsToNumber(value) - min) / (max - min));
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
///
/// The name of a test gives the highest level of its row. That level does
/// not always win: a radial table shows the levels that a route or a
/// copy-in hides.
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
    testWidgets('${subset.isEmpty ? 'no level' : 'from ${subset.first}'}: '
        '$label gives $expected', (tester) async {
      final observed = _text(body(subset));
      expect(observed, expected);
      if (!themed) expect(observed, _upstream(scenario, label));
    });
  }
}

/// The raw Map theme of the scenarios 'a compiled theme': each color token
/// and the two font tokens of phase 6 (theming.md §4).
const AnyObject _tokenTheme = <String, Object?>{
  'colors': <String, Object?>{
    'color': (alpha: 1.0, red: 0.2, green: 0.4, blue: 0.6),
    'borderColor': (alpha: 0.5, red: 0.0, green: 0.5, blue: 0.0),
    'backgroundColor': (alpha: 1.0, red: 200 / 255, green: 0.0, blue: 0.0),
    'surface': (alpha: 1.0, red: 0.0, green: 0.0, blue: 0.0),
  },
  'typography': <String, Object?>{
    'font': <String, Object?>{'family': 'Arial', 'size': 14.0},
    'pointLabels': <String, Object?>{'style': 'italic', 'size': 11.0},
  },
};

/// The raw Map theme of the scenario 'a radial chart with a theme font
/// without size': the font token without the token `pointLabels`.
const AnyObject _fontTheme = <String, Object?>{
  'typography': <String, Object?>{
    'font': <String, Object?>{'family': 'serif', 'size': 14.0},
  },
};

/// The values that the tokens of [_tokenTheme] replace (theming.md §4, the
/// column "Replaces"), by the dot path in `defaults`, as the generator
/// writes them.
const Map<String, Object?> _tokenReplaced = {
  'color': 'rgba(51, 102, 153, 1)',
  'borderColor': 'rgba(0, 128, 0, 0.5)',
  'scale.ticks.backdropColor': 'rgba(0, 0, 0, 0.75)',
  'font.family': 'Arial',
  'font.size': 14.0,
  'scales.radialLinear.pointLabels.font.style': 'italic',
  'scales.radialLinear.pointLabels.font.size': 11.0,
};

/// The values that the token `font` of [_fontTheme] replaces, by the dot
/// path in `defaults`, as the generator writes them.
const Map<String, Object?> _fontReplaced = {
  'font.family': 'serif',
  'font.size': 14.0,
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

/// The data of a chart with the real scales: two labels and two values, in
/// a dataset of the type [type] (no key for Dart `null`).
AnyObject _realData([String? type]) => <String, Object?>{
  'labels': <Object?>['a', 'b'],
  'datasets': [
    <String, Object?>{
      'type': ?type,
      'data': <Object?>[2, 8],
    },
  ],
};

/// The data of a radial chart: three labels and three values.
AnyObject _radialData() => <String, Object?>{
  'labels': <Object?>['a', 'b', 'c'],
  'datasets': [
    <String, Object?>{
      'data': <Object?>[1, 2, 3],
    },
  ],
};

/// A radial chart of the type `themeRadial` with the user scale options [r]
/// and the theme [theme] (no key for Dart `null`).
Chart _radialChart(AnyObject r, [Object? theme]) => acquireChart(
  <String, Object?>{
    'type': 'themeRadial',
    'data': _radialData(),
    'options': <String, Object?>{
      'scales': <String, Object?>{'r': r},
    },
    themeConfigKey: ?theme,
  },
);

/// The radial scale `r` of [chart].
RadialLinearScale _r(Chart chart) => chart.scales['r']! as RadialLinearScale;

/// The observations of a radial snapshot scenario of the generator: the
/// options of the radial scale of a chart with the theme [theme] (no key
/// for Dart `null`).
List<String> _radialSnapshot(Object? theme) {
  final lines = <String>[];
  void observe(String label, Object? value) =>
      lines.add('$label: ${_text(value)}');

  if (theme != null) observe('theme', theme);
  final chart = _radialChart(<String, Object?>{}, theme);
  final r = _r(chart);
  final o = r.options;
  observe('scales', jsObjectKeys(chart.scales).join(','));
  observe('colors', [
    _at(o, 'pointLabels.color'),
    _at(o, 'angleLines.color'),
    _at(o, 'ticks.color'),
    _at(o, 'ticks.backdropColor'),
    _at(o, 'grid.color'),
    _at(o, 'pointLabels.backdropColor'),
  ]);
  // The fonts of fitWithPointLabels (scale.radialLinear.js:96-97) and of
  // _resolveTickFontOptions (core.scale.js:1700-1703).
  final pointLabelFont = toFont(_at(o, 'pointLabels.font'));
  final tickFont = r.resolveTickFontOptions(0);
  observe('fonts', [
    pointLabelFont.family,
    pointLabelFont.size,
    pointLabelFont.string,
    tickFont.family,
    tickFont.size,
    tickFont.string,
  ]);
  observe('size', [r.width, r.height]);
  return lines;
}

/// The observations of an axes scenario of the generator (theming.md §8
/// test 5): the scales of a chart of the type [type] with the theme [theme]
/// (no key for Dart `null`).
List<String> _axes(String type, Object? theme) {
  final lines = <String>[];
  void observe(String label, Object? value) =>
      lines.add('$label: ${_text(value)}');

  if (theme != null) observe('theme', theme);
  final chart = acquireChart(<String, Object?>{
    'type': type,
    'data': type == 'themeRadial' ? _radialData() : _realData(),
    'options': <String, Object?>{},
    themeConfigKey: ?theme,
  });
  observe('scales', jsObjectKeys(chart.scales).join(','));
  observe(
    'option scales',
    jsObjectKeys(chart.options['scales']! as AnyObject).join(','),
  );
  observe('config scales', chart.config.options['scales']);
  return lines;
}

/// The raw Map theme of the group `hover` (Chart.js ADR 0030, section 10):
/// the color tokens `color`, `borderColor` and `backgroundColor`. The
/// generator writes the values that they replace into `defaults` for its
/// upstream run (theming.md §4).
const AnyObject _hoverTheme = <String, Object?>{
  'colors': <String, Object?>{
    'color': (alpha: 1.0, red: 0.2, green: 0.4, blue: 0.6),
    'borderColor': (alpha: 0.5, red: 0.0, green: 0.5, blue: 0.0),
    'backgroundColor': (alpha: 1.0, red: 200 / 255, green: 0.0, blue: 0.0),
  },
};

/// The 8 chart types of phase 7, in code unit order.
const List<String> _chartTypes = [
  'bar',
  'bubble',
  'doughnut',
  'line',
  'pie',
  'polarArea',
  'radar',
  'scatter',
];

/// The data of the hover chart of the type [type] in the generator: one
/// dataset with three values.
AnyObject _hoverData(String type) => switch (type) {
  'scatter' || 'bubble' => <String, Object?>{
    'datasets': [
      <String, Object?>{
        'data': <Object?>[
          for (final (x, y) in [(1, 2), (5, 8), (9, 4)])
            <String, Object?>{'x': x, 'y': y, if (type == 'bubble') 'r': 5},
        ],
      },
    ],
  },
  _ => <String, Object?>{
    'labels': <Object?>['a', 'b', 'c'],
    'datasets': [
      <String, Object?>{
        'data': <Object?>[3, 5, 2],
      },
    ],
  },
};

/// The observed options of [element] in the hover scenarios: the keys of
/// `hoverOptions` of the generator, in its order.
AnyObject _hoverOptions(Element element) {
  final o = element.options;
  return <String, Object?>{
    for (final key in [
      'backgroundColor',
      'borderColor',
      'borderWidth',
      'hoverBackgroundColor',
      'hoverBorderColor',
      if (element is PointElement) 'radius',
    ])
      key: jsGet(o, key),
  };
}

/// The rounded center of the element [index] of the dataset 0 of [chart]:
/// `Math.round` of each coordinate of `getCenterPoint()`, as the generator
/// gives it to `_eventHandler`.
AnyObject _hoverPoint(Chart chart, int index) {
  final center = (_point(chart, index) as types.VisualElement).getCenterPoint();
  // Math.round: floor(x + 0.5).
  double round(Object? value) => (jsToNumber(value) + 0.5).floorToDouble();
  return <String, Object?>{'x': round(center.x), 'y': round(center.y)};
}

/// The observations of the scenario `hover <type>` of the generator: the
/// chart of the type [type] with the compiled [_hoverTheme], a `mousemove`
/// at the element 0, a `mousemove` at the element 1 and a `mouseout`. After
/// each step, the active elements of `getActiveElements()` and the options
/// of both elements.
Future<List<String>> _hover(String type) async {
  final lines = <String>[];
  void observe(String label, Object? value) =>
      lines.add('$label: ${_text(value)}');

  final chart = acquireChart(<String, Object?>{
    'type': type,
    'data': _hoverData(type),
    'options': <String, Object?>{},
    themeConfigKey: compileChartTheme(_hoverTheme),
  });
  Future<void> step(String eventType, AnyObject point) async {
    await triggerMouseEvent(chart, eventType, point);
    final active = chart.getActiveElements();
    for (final item in active) {
      // The active element is the element of its index in the meta.
      expect(
        item.element,
        same(chart.getDatasetMeta(item.datasetIndex).data[item.index.toInt()]),
      );
    }
    observe('active', [
      for (final item in active) [item.datasetIndex, item.index],
    ]);
    observe('element 0', _hoverOptions(_point(chart)));
    observe('element 1', _hoverOptions(_point(chart, 1)));
  }

  await step('mousemove', _hoverPoint(chart, 0));
  final second = _hoverPoint(chart, 1);
  await step('mousemove', second);
  await step('mouseout', second);
  return lines;
}

// ---------------------------------------------------------------------------
// The palette of plugin.colors (Chart.js ADR 0042).

/// The type of `observe` of a scenario: one line `<label>: <value>`.
typedef _Observe = void Function(String label, Object? value);

/// The theme palette P1 of the generator: three border and three background
/// sentinels.
AnyObject _paletteP1() => <String, Object?>{
  themeBorderColorsKey: <Object?>['P1-b0', 'P1-b1', 'P1-b2'],
  themeBackgroundColorsKey: <Object?>['P1-g0', 'P1-g1', 'P1-g2'],
};

/// The theme palette P2 of the generator: two border and two background
/// sentinels.
AnyObject _paletteP2() => <String, Object?>{
  themeBorderColorsKey: <Object?>['P2-b0', 'P2-b1'],
  themeBackgroundColorsKey: <Object?>['P2-g0', 'P2-g1'],
};

/// A raw theme Map with the element colors of the generator (if [elements])
/// and the palette [palette] under `plugins.colors` (no key for Dart
/// `null`).
AnyObject _paletteTheme({bool elements = false, AnyObject? palette}) =>
    <String, Object?>{
      if (elements)
        'elements': <String, Object?>{
          for (final element in ['bar', 'arc'])
            element: <String, Object?>{
              'backgroundColor': 'T-bg',
              'borderColor': 'T-bc',
            },
        },
      if (palette != null) 'plugins': <String, Object?>{'colors': palette},
    };

/// The data of a palette chart of the type [type] in the generator: [count]
/// datasets with three values each, or three points for bubble and scatter.
AnyObject _paletteData(String type, int count) {
  const values = [
    [3, 5, 2],
    [4, 1, 6],
  ];
  final points = type == 'bubble' || type == 'scatter';
  return <String, Object?>{
    if (!points) 'labels': <Object?>['a', 'b', 'c'],
    'datasets': <Object?>[
      for (var d = 0; d < count; d++)
        <String, Object?>{
          'data': <Object?>[
            for (final (i, y) in values[d % 2].indexed)
              if (points)
                <String, Object?>{
                  'x': i * 4 + 1,
                  'y': y,
                  if (type == 'bubble') 'r': 5,
                }
              else
                y,
          ],
        },
    ],
  };
}

/// A palette chart of the generator: the type [type], [count] datasets, the
/// colors plugin on with the plugin options [colorOptions], the other user
/// options [options], the dataset values [datasets] (merged into the first
/// datasets) and the theme [theme] (no key for Dart `null`). It returns the
/// raw configuration too: a test removes its theme.
(Chart, AnyObject) _paletteChart(
  String type, {
  int count = 2,
  Object? theme,
  AnyObject? options,
  AnyObject? colorOptions,
  List<AnyObject> datasets = const [],
}) {
  final data = _paletteData(type, count);
  final dataDatasets = data['datasets']! as List<Object?>;
  for (final (d, values) in datasets.indexed) {
    (dataDatasets[d]! as AnyObject).addAll(values);
  }
  final config = <String, Object?>{
    'type': type,
    'data': data,
    'options': <String, Object?>{
      ...?options,
      'plugins': <String, Object?>{
        'colors': <String, Object?>{'enabled': true, ...?colorOptions},
      },
    },
    themeConfigKey: ?theme,
  };
  return (acquireChart(config), config);
}

/// The colors `[borderColor, backgroundColor]` of the options [options].
List<Object?> _colorPair(Object? options) => [
  jsGet(options, 'borderColor'),
  jsGet(options, 'backgroundColor'),
];

/// The raw datasets of [chart].
List<Object?> _datasets(Chart chart) =>
    jsGet(chart.data, 'datasets')! as List<Object?>;

/// `observePalette` of the generator: for each dataset of [chart], its raw
/// colors and the colors of the options of its data elements 0 and 1, with
/// the label prefix [prefix].
void _observePalette(_Observe observe, String prefix, Chart chart) {
  for (final (d, dataset) in _datasets(chart).indexed) {
    observe('${prefix}dataset $d', _colorPair(dataset));
    final meta = chart.getDatasetMeta(d.toDouble());
    for (final i in [0, 1]) {
      observe(
        '${prefix}element $d.$i',
        _colorPair((meta.data[i] as Element).options),
      );
    }
  }
}

/// The observations of the palette scenario [body] as one text.
String _palette(void Function(_Observe observe) body) {
  final lines = <String>[];
  body((label, value) => lines.add('$label: ${_text(value)}'));
  return lines.join('\n');
}

/// `styleSetters` of the generator: the style setters `fillStyle` and
/// `strokeStyle` of one draw of each dataset controller of [chart], in the
/// dataset order, as `[name, value]`. The draw goes to a mock context in
/// place of the context of the controller (Chart.js ADR 0030), as the
/// generator draws into the mock context of its chart.
List<Object?> _styleSetters(Chart chart) {
  final setters = <Object?>[];
  for (var d = 0; d < _datasets(chart).length; d++) {
    final controller = chart.getDatasetMeta(d.toDouble()).controller!;
    final target = controller.ctx;
    final mock = createMockContext();
    controller.ctx = mock;
    try {
      controller.draw();
    } finally {
      controller.ctx = target;
    }
    for (final call in mock.getCalls()) {
      final name = call['name'];
      if (name == 'setFillStyle' || name == 'setStrokeStyle') {
        setters.add([name, (call['args']! as List<Object?>).first]);
      }
    }
  }
  return setters;
}

/// The lines of the scenario `light palette <type>` of the generator: a
/// chart of the type [type] with two datasets, the colors plugin on, no user
/// color and the theme [theme] (no key for Dart `null`). For each dataset:
/// the raw colors, the colors of the dataset element (line and radar), and
/// the colors of the data elements 0 and 1 in the modes `default` and
/// `active`. Then the style setters of one draw of the datasets.
List<String> _lightPalette(String type, Object? theme) {
  final lines = <String>[];
  void observe(String label, Object? value) =>
      lines.add('$label: ${_text(value)}');

  final (chart, _) = _paletteChart(type, theme: theme);
  for (final (d, dataset) in _datasets(chart).indexed) {
    observe('dataset $d', _colorPair(dataset));
    final meta = chart.getDatasetMeta(d.toDouble());
    if (meta.dataset case final Element line) {
      observe('dataset $d line', _colorPair(line.options));
    }
    for (final i in [0, 1]) {
      observe('element $d.$i', _colorPair((meta.data[i] as Element).options));
      observe(
        'element $d.$i active',
        _colorPair(
          meta.controller!.resolveDataElementOptions(i.toDouble(), 'active'),
        ),
      );
    }
  }
  observe('draw', _styleSetters(chart));
  return lines;
}

/// [value] with each color string in its parsed form (`rgbString` of
/// @kurkle/color), in Lists too. Another value stays.
Object? _parsedColors(Object? value) => switch (value) {
  final String s when kurkle.Color(s).valid => kurkle.Color(s).rgbString(),
  final List<Object?> list => [for (final item in list) _parsedColors(item)],
  _ => value,
};

/// The lines [lines] as `[label, value]`, with the colors of each value in
/// their parsed form.
List<Object?> _parsedLines(Iterable<String> lines) => [
  for (final line in lines)
    [
      line.substring(0, line.indexOf(': ')),
      _parsedColors(jsonDecode(line.substring(line.indexOf(': ') + 2))),
    ],
];

void main() {
  Chart.register([
    _themeController('themeTest'),
    _themeController('themeTest2'),
    _themeScale,
    _themeProbe,
  ]);
  Chart.register([
    CategoryScale.jsClass,
    LinearScale.jsClass,
    RadialLinearScale.jsClass,
  ]);
  Chart.register([
    _themeController('themeReal', 'category', 'linear'),
    _themeController('themeReal2', 'category', 'linear'),
    _radialThemeController,
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

    group('H1 with the category and linear scales', () {
      // theming.md §10, the phase 6 row: the category scale `x` and the
      // linear scale `y`. Each level sets a sentinel for both axes. Each
      // scale type reads its own theme key `scales.<type>`.
      _rows(
        'real scales',
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
          // The user scales are always there: the chart-type overrides
          // merge only into a scale of the user options
          // (core.config.js:76-89).
          final x = <String, Object?>{};
          final y = <String, Object?>{};
          final theme = <String, Object?>{};
          if (levels.contains('user')) {
            x['ticks'] = <String, Object?>{'color': 'S1-user-x'};
            y['ticks'] = <String, Object?>{'color': 'S1-user-y'};
          }
          if (levels.contains('chartOverrides')) {
            _put(
              overrides,
              'themeReal.scales._index_.ticks.color',
              'S2-chart-x',
            );
            _put(
              overrides,
              'themeReal.scales._value_.ticks.color',
              'S2-chart-y',
            );
          }
          if (levels.contains('datasetOverrides')) {
            _put(
              overrides,
              'themeReal2.scales._index_.ticks.color',
              'S3-dataset-x',
            );
            _put(
              overrides,
              'themeReal2.scales._value_.ticks.color',
              'S3-dataset-y',
            );
          }
          if (levels.contains('themeType')) {
            theme['scales'] = <String, Object?>{
              'category': <String, Object?>{
                'ticks': <String, Object?>{'color': 'S4-theme-category'},
              },
              'linear': <String, Object?>{
                'ticks': <String, Object?>{'color': 'S4-theme-linear'},
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
              'scales.category.ticks.color',
              'S6-category-defaults',
            );
            _put(defaults, 'scales.linear.ticks.color', 'S6-linear-defaults');
          }
          if (levels.contains('scaleBase')) {
            _put(defaults, 'scale.ticks.color', 'S7-scale-base');
          }
          if (levels.contains('rootColor')) {
            _put(defaults, 'color', 'S8-root-color');
          }
          final chart = acquireChart(<String, Object?>{
            'type': 'themeReal',
            'data': _realData('themeReal2'),
            'options': <String, Object?>{
              'scales': <String, Object?>{'x': x, 'y': y},
            },
            if (levels.contains('themeType') || levels.contains('themeScale'))
              themeConfigKey: theme,
          });
          return [
            _at(chart.scales['x']!.options, 'ticks.color'),
            _at(chart.scales['y']!.options, 'ticks.color'),
            jsObjectKeys(chart.scales).join(','),
          ];
        },
      );
    });

    group('H1 with the radial linear scale: point label color', () {
      // The route of scale.radialLinear.js:400-404 reads Defaults.color.
      _rows(
        'radial point labels',
        const [
          'user',
          'chartOverrides',
          'themeType',
          'themeScale',
          'scaleDefaults',
          'rootColor',
        ],
        const ['themeType', 'themeScale'],
        (levels) {
          final r = <String, Object?>{};
          final theme = <String, Object?>{};
          if (levels.contains('user')) {
            r['pointLabels'] = <String, Object?>{'color': 'R1-user'};
          }
          if (levels.contains('chartOverrides')) {
            _put(
              overrides,
              'themeRadial.scales.r.pointLabels.color',
              'R2-chart',
            );
          }
          if (levels.contains('themeType')) {
            theme['scales'] = <String, Object?>{
              'radialLinear': <String, Object?>{
                'pointLabels': <String, Object?>{'color': 'R3-theme-type'},
              },
            };
          }
          if (levels.contains('themeScale')) {
            theme['scale'] = <String, Object?>{
              'pointLabels': <String, Object?>{'color': 'R4-theme-scale'},
            };
          }
          if (levels.contains('scaleDefaults')) {
            _put(
              defaults,
              'scales.radialLinear.pointLabels.color',
              'R5-scale-defaults',
            );
          }
          if (levels.contains('rootColor')) {
            _put(defaults, 'color', 'R6-root-color');
          }
          final themed =
              levels.contains('themeType') || levels.contains('themeScale');
          final chart = _radialChart(r, themed ? theme : null);
          return [
            _at(_r(chart).options, 'pointLabels.color'),
            jsObjectKeys(chart.scales).join(','),
          ];
        },
      );
    });

    group('H1 with the radial linear scale: angle line color', () {
      // The route of scale.radialLinear.js:400-404 reads
      // Defaults.borderColor. The descriptor `_fallback: 'grid'`
      // (scale.radialLinear.js:406-410) adds the grid scopes after the angle
      // line scopes. The scale copy-in always has angleLines.color. Thus a
      // grid color never reaches the angle lines, and the theme needs the
      // key scales.radialLinear.angleLines.color (theming.md §4).
      _rows(
        'radial angle lines',
        const [
          'user',
          'userGrid',
          'themeType',
          'themeGrid',
          'scaleDefaults',
          'rootBorderColor',
        ],
        const ['themeType', 'themeGrid'],
        (levels) {
          final r = <String, Object?>{};
          final theme = <String, Object?>{};
          if (levels.contains('user')) {
            r['angleLines'] = <String, Object?>{'color': 'A1-user'};
          }
          if (levels.contains('userGrid')) {
            r['grid'] = <String, Object?>{'color': 'A2-user-grid'};
          }
          if (levels.contains('themeType')) {
            theme['scales'] = <String, Object?>{
              'radialLinear': <String, Object?>{
                'angleLines': <String, Object?>{'color': 'A3-theme-type'},
              },
            };
          }
          if (levels.contains('themeGrid')) {
            theme['scale'] = <String, Object?>{
              'grid': <String, Object?>{'color': 'A4-theme-grid'},
            };
          }
          if (levels.contains('scaleDefaults')) {
            _put(
              defaults,
              'scales.radialLinear.angleLines.color',
              'A5-scale-defaults',
            );
          }
          if (levels.contains('rootBorderColor')) {
            _put(defaults, 'borderColor', 'A6-root-border-color');
          }
          final themed =
              levels.contains('themeType') || levels.contains('themeGrid');
          final options = _r(_radialChart(r, themed ? theme : null)).options;
          return [
            _at(options, 'angleLines.color'),
            _at(options, 'grid.color'),
          ];
        },
      );
    });

    group('H1 with the radial linear scale: point label font', () {
      // The size 10 of scale.radialLinear.js:383-385, and the toFont
      // fallback to Defaults.font (helpers.options.ts:115-117). A font
      // merges per key across the scopes.
      _rows(
        'radial point label fonts',
        const ['user', 'themeType', 'themeScale', 'scaleDefaults', 'rootFont'],
        const ['themeType', 'themeScale'],
        (levels) {
          final r = <String, Object?>{};
          final theme = <String, Object?>{};
          if (levels.contains('user')) {
            r['pointLabels'] = <String, Object?>{
              'font': <String, Object?>{'family': 'F1-user', 'size': 31},
            };
          }
          if (levels.contains('themeType')) {
            theme['scales'] = <String, Object?>{
              'radialLinear': <String, Object?>{
                'pointLabels': <String, Object?>{
                  'font': <String, Object?>{
                    'family': 'F2-theme-type',
                    'size': 32,
                  },
                },
              },
            };
          }
          if (levels.contains('themeScale')) {
            theme['scale'] = <String, Object?>{
              'pointLabels': <String, Object?>{
                'font': <String, Object?>{
                  'family': 'F3-theme-scale',
                  'size': 33,
                },
              },
            };
          }
          if (levels.contains('scaleDefaults')) {
            _put(
              defaults,
              'scales.radialLinear.pointLabels.font.family',
              'F4-scale-defaults',
            );
            _put(defaults, 'scales.radialLinear.pointLabels.font.size', 34.0);
          }
          if (levels.contains('rootFont')) {
            _put(defaults, 'font.family', 'F5-root-font');
            _put(defaults, 'font.size', 35.0);
          }
          final themed =
              levels.contains('themeType') || levels.contains('themeScale');
          final options = _r(_radialChart(r, themed ? theme : null)).options;
          final font = toFont(_at(options, 'pointLabels.font'));
          return [font.family, font.size, font.string];
        },
      );
    });

    group('H1 with the radial linear scale: tick color', () {
      // The route of scale.radialLinear.js:400-404 reads Defaults.color. H1
      // merges the theme key scale.ticks.color before
      // defaults.scales.radialLinear. Thus the theme needs no key
      // scales.radialLinear.ticks.color (theming.md §4).
      _rows(
        'radial ticks',
        const [
          'user',
          'themeType',
          'themeScale',
          'scaleDefaults',
          'scaleBase',
          'rootColor',
        ],
        const ['themeType', 'themeScale'],
        (levels) {
          final r = <String, Object?>{};
          final theme = <String, Object?>{};
          if (levels.contains('user')) {
            r['ticks'] = <String, Object?>{'color': 'T1-user'};
          }
          if (levels.contains('themeType')) {
            theme['scales'] = <String, Object?>{
              'radialLinear': <String, Object?>{
                'ticks': <String, Object?>{'color': 'T2-theme-type'},
              },
            };
          }
          if (levels.contains('themeScale')) {
            theme['scale'] = <String, Object?>{
              'ticks': <String, Object?>{'color': 'T3-theme-scale'},
            };
          }
          if (levels.contains('scaleDefaults')) {
            _put(
              defaults,
              'scales.radialLinear.ticks.color',
              'T4-scale-defaults',
            );
          }
          if (levels.contains('scaleBase')) {
            _put(defaults, 'scale.ticks.color', 'T5-scale-base');
          }
          if (levels.contains('rootColor')) {
            _put(defaults, 'color', 'T6-root-color');
          }
          final themed =
              levels.contains('themeType') || levels.contains('themeScale');
          return _at(
            _r(_radialChart(r, themed ? theme : null)).options,
            'ticks.color',
          );
        },
      );
    });

    group('palette', () {
      // The palette rows of theming.md §8 test 2 and the pins of the hunks
      // H4a-H4c and H5 (Chart.js ADR 0042). The expected lines come from the
      // prototype run of the generator. A row without a theme also equals
      // the upstream run.
      testWidgets('the theme palette beats the theme element colors', (
        tester,
      ) async {
        final observed = _palette((observe) {
          for (final (type, count) in [
            ('bar', 4),
            ('doughnut', 2),
            ('polarArea', 2),
          ]) {
            final theme = _paletteTheme(elements: true, palette: _paletteP1());
            final (chart, _) = _paletteChart(type, count: count, theme: theme);
            _observePalette(observe, '$type ', chart);
          }
        });
        expect(observed, themePrecedencePrototype['palette 1']);
      });

      testWidgets('user colors disable the theme palette', (tester) async {
        // A dataset color, a root option color and an `elements` color.
        // Then the dataset color with `forceOverride: true`: the theme
        // palette writes over it.
        AnyObject theme() =>
            _paletteTheme(elements: true, palette: _paletteP1());
        final observed = _palette((observe) {
          _observePalette(
            observe,
            'dataset color ',
            _paletteChart(
              'bar',
              theme: theme(),
              datasets: [
                <String, Object?>{'borderColor': 'U'},
              ],
            ).$1,
          );
          _observePalette(
            observe,
            'root color ',
            _paletteChart(
              'bar',
              theme: theme(),
              options: <String, Object?>{'backgroundColor': 'U'},
            ).$1,
          );
          _observePalette(
            observe,
            'elements color ',
            _paletteChart(
              'bar',
              theme: theme(),
              options: <String, Object?>{
                'elements': <String, Object?>{
                  'bar': <String, Object?>{'borderColor': 'U'},
                },
              },
            ).$1,
          );
          _observePalette(
            observe,
            'forceOverride ',
            _paletteChart(
              'bar',
              theme: theme(),
              datasets: [
                <String, Object?>{'borderColor': 'U'},
              ],
              colorOptions: <String, Object?>{'forceOverride': true},
            ).$1,
          );
        });
        expect(observed, themePrecedencePrototype['palette 2']);
      });

      testWidgets('a theme without a palette keeps the upstream palette', (
        tester,
      ) async {
        // The bar chart has 8 datasets: the palette of 7 colors wraps.
        final observed = _palette((observe) {
          _observePalette(
            observe,
            'bar ',
            _paletteChart(
              'bar',
              count: 8,
              theme: _paletteTheme(elements: true),
            ).$1,
          );
          _observePalette(
            observe,
            'doughnut ',
            _paletteChart('doughnut', theme: _paletteTheme(elements: true)).$1,
          );
        });
        expect(observed, themePrecedencePrototype['palette 3']);
        // The dataset colors are the upstream colors. The element options
        // of the doughnut keep the theme border color.
        Iterable<String> datasetLines(String text) =>
            text.split('\n').where((line) => line.contains(' dataset '));
        expect(
          datasetLines(observed),
          datasetLines(themePrecedenceUpstream['palette 3']!),
        );
      });

      testWidgets('two interleaved charts keep their own palettes', (
        tester,
      ) async {
        // Charts A (palette P1), B (palette P2) and C (no theme), all with
        // `forceOverride: true`: each update colorizes again.
        const force = <String, Object?>{'forceOverride': true};
        final observed = _palette((observe) {
          final (a, _) = _paletteChart(
            'bar',
            theme: _paletteTheme(palette: _paletteP1()),
            colorOptions: force,
          );
          final (b, _) = _paletteChart(
            'bar',
            theme: _paletteTheme(palette: _paletteP2()),
            colorOptions: force,
          );
          final (c, _) = _paletteChart('bar', colorOptions: force);
          _observePalette(observe, 'A ', a);
          _observePalette(observe, 'B ', b);
          _observePalette(observe, 'C ', c);
          a.update();
          _observePalette(observe, 'A after A.update ', a);
          c.update();
          _observePalette(observe, 'C after C.update ', c);
          b.update();
          _observePalette(observe, 'B after B.update ', b);
        });
        expect(observed, themePrecedencePrototype['palette 4']);
      });

      testWidgets('no theme: a user or defaults palette key has no effect', (
        tester,
      ) async {
        // A palette key in the user options, in `defaults` and in
        // `overrides.bar`. Upstream ignores the keys. The restore of the
        // harness removes the writes into `defaults` and `overrides` after
        // the test (`harness-defaults-restore`).
        final observed = _palette((observe) {
          _observePalette(
            observe,
            'user ',
            _paletteChart('bar', colorOptions: _paletteP2()).$1,
          );
          _put(defaults, 'plugins.colors.$themeBorderColorsKey', <Object?>[
            'D-b0',
          ]);
          _put(defaults, 'plugins.colors.$themeBackgroundColorsKey', <Object?>[
            'D-g0',
          ]);
          _observePalette(observe, 'defaults ', _paletteChart('bar').$1);
          _put(overrides, 'bar.plugins.colors.$themeBorderColorsKey', <Object?>[
            'O-b0',
          ]);
          _put(
            overrides,
            'bar.plugins.colors.$themeBackgroundColorsKey',
            <Object?>['O-g0'],
          );
          _observePalette(observe, 'overrides ', _paletteChart('bar').$1);
        });
        expect(observed, themePrecedencePrototype['palette 5']);
        expect(observed, themePrecedenceUpstream['palette 5']);
      });

      testWidgets(
        'an empty or non-List theme palette keeps the upstream palette',
        (tester) async {
          // A raw theme Map, not a theme of the compiler: its guard rejects
          // these values (rule 9).
          final observed = _palette((observe) {
            for (final (name, value) in <(String, Object?)>[
              ('empty', <Object?>[]),
              ('string', 'red'),
              ('map', <String, Object?>{'a': 'P1-b0'}),
            ]) {
              final theme = _paletteTheme(
                palette: <String, Object?>{
                  themeBorderColorsKey: value,
                  themeBackgroundColorsKey: value,
                },
              );
              _observePalette(
                observe,
                '$name ',
                _paletteChart('bar', theme: theme).$1,
              );
            }
          });
          expect(observed, themePrecedencePrototype['palette 6']);
          expect(observed, themePrecedenceUpstream['palette 6']);
        },
      );

      test(
        'the palette keys of plugin.colors equal the keys of the compiler',
        () {
          final compiled = compileChartTheme(ChartThemes.light);
          final colorsOptions = _at(compiled, 'plugins.colors')! as AnyObject;
          expect(
            jsObjectKeys(colorsOptions).where((key) => key.startsWith(r'$')),
            [themeBorderColorsKey, themeBackgroundColorsKey],
          );
        },
      );

      testWidgets(
        'a removed theme gives the upstream palette at the next colorize',
        (tester) async {
          // Hunk H5 sets both variables at each run, Dart null included.
          final observed = _palette((observe) {
            final (chart, config) = _paletteChart(
              'bar',
              theme: _paletteTheme(palette: _paletteP1()),
              colorOptions: const <String, Object?>{'forceOverride': true},
            );
            _observePalette(observe, 'themed ', chart);
            // The raw configuration is the configuration of the chart
            // (core.config.js:129-136 `initConfig` returns it).
            config.remove(themeConfigKey);
            chart.update();
            _observePalette(observe, 'theme removed ', chart);
          });
          expect(observed, themePrecedencePrototype['palette 8']);
        },
      );
    });
  });

  group('test 3: the light palette', () {
    // theming.md §8 test 3 with the colors plugin on and no user colors:
    // with the light preset, the lines equal the prototype lines. Without a
    // theme, they equal the upstream lines. Across the two runs, the colors
    // are equal after the parse. The run with the colors plugin off is in
    // the controller test files (Chart.js ADR 0030, section 8).
    for (final type in _chartTypes) {
      testWidgets('$type: the light palette equals the upstream palette', (
        tester,
      ) async {
        final name = 'light palette $type';
        final themed = _lightPalette(
          type,
          compileChartTheme(ChartThemes.light),
        );
        expect(themed.join('\n'), themePrecedencePrototype[name]);
        final unthemed = _lightPalette(type, null);
        expect(unthemed.join('\n'), themePrecedenceUpstream[name]);
        expect(_parsedLines(themed), _parsedLines(unthemed));
      });
    }
  });

  group('a compiled theme on a radial chart', () {
    // theming.md §4: the tokens reach the radial linear scale through the
    // keys scales.radialLinear.pointLabels.color,
    // scales.radialLinear.angleLines.color and
    // scales.radialLinear.pointLabels.font, and through the scale keys.
    testWidgets(
      'a radial chart without a theme resolves the upstream options',
      (
        tester,
      ) async {
        expect(
          _radialSnapshot(null).join('\n'),
          themePrecedenceUpstream['a radial chart without a theme'],
        );
        expect(
          themePrecedencePrototype['a radial chart without a theme'],
          themePrecedenceUpstream['a radial chart without a theme'],
        );
      },
    );

    testWidgets('the tokens reach the point labels and the angle lines', (
      tester,
    ) async {
      expect(
        _radialSnapshot(compileChartTheme(_tokenTheme)).join('\n'),
        themePrecedencePrototype['a radial chart with a compiled theme'],
      );
    });

    testWidgets('the light preset gives the upstream options', (tester) async {
      // theming.md §8 test 3 on a real radial chart: equal colors after the
      // parse, equal fonts and an equal scale size.
      final themed = _radialSnapshot(compileChartTheme(ChartThemes.light));
      expect(
        themed.join('\n'),
        themePrecedencePrototype['a radial chart with the light preset'],
      );
      const upstream = 'a radial chart without a theme';
      final lines = {
        for (final line in themed)
          line.substring(0, line.indexOf(': ')): line.substring(
            line.indexOf(': ') + 2,
          ),
      };
      List<Object?> parsed(String json) => [
        for (final color in jsonDecode(json) as List<Object?>)
          if (color == '<undefined>')
            color
          else
            kurkle.Color(color).rgbString(),
      ];
      expect(parsed(lines['colors']!), parsed(_upstream(upstream, 'colors')));
      for (final label in ['scales', 'fonts', 'size']) {
        expect(lines[label], _upstream(upstream, label), reason: label);
      }
    });

    testWidgets('a theme font without size keeps the point-label size 10', (
      tester,
    ) async {
      // theming.md §3.4: the point-label font of the theme has no size.
      // Hunk H1 merges the theme font into the scale copy-in first. Then
      // mergeIf adds the size 10 of defaults.scales.radialLinear to that
      // font (core.config.js:109, helpers.core.ts:310-323).
      expect(
        _radialSnapshot(compileChartTheme(_fontTheme)).join('\n'),
        themePrecedencePrototype['a radial chart with a theme font without '
            'size'],
      );
    });

    // theming.md §4, the column "Replaces": a theme gives the options of an
    // upstream chart without a theme that has the replaced values in
    // `defaults`.
    for (final (name, theme, replaced, values) in [
      (
        'the tokens',
        _tokenTheme,
        'a radial chart with the values that the tokens replace',
        _tokenReplaced,
      ),
      (
        'a theme font without size',
        _fontTheme,
        'a radial chart with the font that the theme font replaces',
        _fontReplaced,
      ),
    ]) {
      testWidgets('$name give the options of the replaced values', (
        tester,
      ) async {
        // The first line is the compiled theme.
        final themed = _radialSnapshot(compileChartTheme(theme)).sublist(1);
        expect(themed.join('\n'), themePrecedenceUpstream[replaced]);
        expect(
          themePrecedencePrototype[replaced],
          themePrecedenceUpstream[replaced],
        );
      });

      testWidgets('the values that $name replace give the upstream options', (
        tester,
      ) async {
        for (final MapEntry(key: path, :value) in values.entries) {
          _put(defaults, path, value);
        }
        expect(
          _radialSnapshot(null).join('\n'),
          themePrecedenceUpstream[replaced],
        );
      });
    }
  });

  group('the singleton read at scale.radialLinear.js:14', () {
    // theming.md §9: getTickBackdropHeight reads defaults.font.size when the
    // tick font has no size. The backdrop height is the padding of the scale
    // in setDimensions (scale.radialLinear.js:426-434). The width and the
    // height of the scale show it, without a text measurement.
    List<Object?> backdrop(Object? theme, [double? fontSize]) {
      if (fontSize != null) _put(defaults, 'font.size', fontSize);
      final scale = _r(_radialChart(<String, Object?>{}, theme));
      final font = _at(scale.options, 'ticks.font');
      return [
        if (jsTruthy(font)) jsGet(font, 'size') else font,
        scale.width,
        scale.height,
      ];
    }

    testWidgets('without a theme, the read gives the backdrop height', (
      tester,
    ) async {
      expect(
        _text(backdrop(null)),
        _upstream('radial tick backdrop', 'no theme'),
      );
    });

    testWidgets('without a theme, the read follows defaults.font.size', (
      tester,
    ) async {
      expect(
        _text(backdrop(null, 30)),
        _upstream('radial tick backdrop', 'no theme, defaults.font.size 30'),
      );
    });

    testWidgets('a theme tick font with a size hides the read', (
      tester,
    ) async {
      expect(
        _text(
          backdrop(<String, Object?>{
            'scale': <String, Object?>{
              'ticks': <String, Object?>{
                'font': <String, Object?>{'size': 20.0},
              },
            },
          }, 30),
        ),
        _prototype('radial tick backdrop', 'a theme tick font with a size'),
      );
    });

    testWidgets('a theme tick font without a size keeps the read', (
      tester,
    ) async {
      // The theme cannot reach the read: the font resolver falls back to the
      // global defaults.font, as a user tick font without a size does.
      final observed = _text(
        backdrop(<String, Object?>{
          'scale': <String, Object?>{
            'ticks': <String, Object?>{
              'font': <String, Object?>{'family': 'serif'},
            },
          },
        }, 30),
      );
      expect(
        observed,
        _prototype('radial tick backdrop', 'a theme tick font without a size'),
      );
      // The same scale size as the unthemed chart with the same defaults.
      expect(
        jsonDecode(observed) as List<Object?>,
        containsAllInOrder(
          (jsonDecode(
            _upstream(
              'radial tick backdrop',
              'no theme, defaults.font.size 30',
            ),
          ) as List<Object?>).skip(1),
        ),
      );
    });
  });

  group('test 5: a theme scale type creates no axis', () {
    // theming.md §3.3 and §8 test 5. Key enumeration of a resolver reads
    // only its first scope (helpers.config.ts:73-75). The first cases use
    // the test controllers: the cartesian test controller and the radial
    // test controller pin the generic path. The cases of Chart.js ADR 0030,
    // section 9, use the real bar and doughnut controllers.
    for (final (name, type, theme) in <(String, String, Object?)>[
      ('axes of a cartesian chart without a theme', 'themeReal', null),
      (
        'axes of a cartesian chart with a radialLinear theme key',
        'themeReal',
        <String, Object?>{
          'scales': <String, Object?>{
            'radialLinear': <String, Object?>{
              'pointLabels': <String, Object?>{'color': 'red'},
              'angleLines': <String, Object?>{'color': 'red'},
            },
          },
        },
      ),
      ('axes of a radial chart without a theme', 'themeRadial', null),
      (
        'axes of a radial chart with cartesian theme keys',
        'themeRadial',
        <String, Object?>{
          'scales': <String, Object?>{
            'category': <String, Object?>{
              'ticks': <String, Object?>{'color': 'red'},
            },
            'linear': <String, Object?>{
              'ticks': <String, Object?>{'color': 'red'},
            },
          },
        },
      ),
    ]) {
      testWidgets(name, (tester) async {
        final observed = _axes(type, theme).join('\n');
        expect(observed, themePrecedencePrototype[name]);
        if (theme == null) expect(observed, themePrecedenceUpstream[name]);
      });
    }

    testWidgets(
      'the light preset creates no radial axis on a cartesian chart',
      (
        tester,
      ) async {
        const name = 'axes of a cartesian chart with the light preset';
        final observed = _axes(
          'themeReal',
          compileChartTheme(ChartThemes.light),
        ).join('\n');
        expect(observed, themePrecedencePrototype[name]);
        expect(_prototype(name, 'scales'), 'x,y');
      },
    );

    // Chart.js ADR 0030, section 9: the bar chart keeps the axes x and y of
    // its overrides, and the doughnut chart gets no axis.
    const redTicks = <String, Object?>{
      'ticks': <String, Object?>{'color': 'red'},
    };
    for (final (name, type, theme) in <(String, String, Object?)>[
      ('axes of a bar chart without a theme', 'bar', null),
      (
        'axes of a bar chart with a radialLinear theme key',
        'bar',
        <String, Object?>{
          'scales': <String, Object?>{
            'radialLinear': <String, Object?>{
              'pointLabels': <String, Object?>{'color': 'red'},
              'angleLines': <String, Object?>{'color': 'red'},
            },
          },
        },
      ),
      (
        'axes of a bar chart with the light preset',
        'bar',
        compileChartTheme(ChartThemes.light),
      ),
      ('axes of a doughnut chart without a theme', 'doughnut', null),
      (
        'axes of a doughnut chart with cartesian theme keys',
        'doughnut',
        <String, Object?>{
          'scale': redTicks,
          'scales': <String, Object?>{'category': redTicks, 'linear': redTicks},
        },
      ),
      (
        'axes of a doughnut chart with the light preset',
        'doughnut',
        compileChartTheme(ChartThemes.light),
      ),
    ]) {
      testWidgets(name, (tester) async {
        final observed = _axes(type, theme).join('\n');
        expect(observed, themePrecedencePrototype[name]);
        if (theme == null) expect(observed, themePrecedenceUpstream[name]);
        expect(_prototype(name, 'scales'), type == 'bar' ? 'x,y' : isEmpty);
      });
    }
  });

  group('hover', () {
    // Chart.js ADR 0030, section 10. The oracle is upstream with the values
    // that the hover theme replaces in `defaults`, the method of the group
    // 'a compiled theme on a radial chart'. The generator stops when the
    // prototype with the compiled theme gives other lines. The positions
    // come from the mock measureText of the generator. Thus each side hovers
    // the center of its own elements, and the lines have no position.
    test('the hover theme compiles to the theme of the generator', () {
      expect(
        _json(compileChartTheme(_hoverTheme)),
        _prototype('hover theme', 'theme'),
      );
    });

    for (final type in _chartTypes) {
      testWidgets('hover $type gives the options of the replaced values', (
        tester,
      ) async {
        expect(
          (await _hover(type)).join('\n'),
          themePrecedenceUpstream['hover $type'],
        );
        expect(
          themePrecedencePrototype['hover $type'],
          themePrecedenceUpstream['hover $type'],
        );
      });
    }

    testWidgets('the active bar background is #B40000', (tester) async {
      // theming.md §3.2: getHoverColor of rgb(200, 0, 0)
      // (core.defaults.js:62-64).
      final chart = acquireChart(<String, Object?>{
        'type': 'bar',
        'data': _hoverData('bar'),
        'options': <String, Object?>{},
        themeConfigKey: compileChartTheme(_hoverTheme),
      });
      await triggerMouseEvent(chart, 'mousemove', _hoverPoint(chart, 0));
      expect(jsGet(_point(chart).options, 'backgroundColor'), '#B40000');
    });
  });
}
