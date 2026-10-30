// Original code, not ported from Chart.js: the theme coverage snapshot.
@TestOn('vm')
library;

// dart:io reads the manifest and the snapshot, so the web legs
// (`dart test -p chrome`) cannot compile this file.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_chartjs_port/src/kurkle_color/color.dart' show Color;
import 'package:flutter_chartjs_port/src/theme/compile.dart';
import 'package:flutter_chartjs_port/src/theme/presets.dart';
import 'package:test/test.dart';

// theming.md §8 test 4, the coverage snapshot (Chart.js ADR 0050,
// Consequences). The test compares the compiled light preset with the
// defaults inventory that tool 4 records in doc/upstream/manifest.json
// (`defaults.values.defaults`, porting-flow.md §4).
//
// 1. The snapshot: light_snapshot.json holds the leaves of
//    `compileChartTheme(ChartThemes.light)` by dot path, without the
//    port-only `transitions` keys (theming.md §3.8). A change of the
//    compiler or of the preset changes the snapshot. With the environment
//    variable THEME_SNAPSHOT_UPDATE=1, the test writes the snapshot again:
//
//      THEME_SNAPSHOT_UPDATE=1 flutter test test/port/theme/coverage_test.dart
//
// 2. The upstream value of each emitted path: the same path in the
//    manifest, with the value of a route (`{"route": v}` gives v). A
//    manifest route leaf `<slot>.<key>` with a Map value is not a leaf of
//    the report. Each field of its Map is a leaf `<slot>.<key>.<field>` with
//    the route of that field: the tooltip fonts route to the global font
//    (plugin.tooltip.js:1327-1331), and tool 4 records the merged route
//    value. An emitted field that the route Map does not have compares with
//    null. A font field `<slot>.font.<field>` that the manifest does not
//    have restates `font.<field>`, the global font that `toFont` reads for
//    an absent field (helpers.options.ts:115-117), if the manifest has the
//    slot.
// 3. The report. The test fails on each entry of these lists:
//    - ADDED: a visual leaf of the manifest that the preset does not emit
//      and that [_notThemed] does not list. A visual leaf has a last key
//      `color`, a last key that ends with `Color`, `Colors` or
//      `Background`, or a key `font` or a key that ends with `Font`.
//    - REMOVED: an emitted path that the manifest does not have and that
//      [_moduleConstants] does not list.
//    - CHANGED: an emitted value that differs from the upstream value, with
//      the new literal. Colors compare after the parse of the ported
//      @kurkle/color, as the canvas layer parses them.
//    - STALE: a [_notThemed] key that the manifest does not have, that
//      the preset emits, or whose upstream value differs from its value in
//      [_notThemedValues]. A [_moduleConstants] key that the manifest has,
//      or that the preset does not emit.
//    - DOLLAR: a `$` key in the inventory. It can collide with the theme
//      key `$theme` and the palette keys (theming.md §11).
//
// The bump report (upstream-tracking.md §6) reads these lists from the
// output of the bump PR. The test reads the manifest of the repository,
// found through the `.gitmodules` file at its root, as upstream_test.dart
// finds it.

/// The visual leaves of the manifest that the light preset does not emit,
/// each with the reason (theming.md §3.3, §3.4 and §4).
const Map<String, String> _notThemed = {
  'backgroundColor':
      'a root backgroundColor beats the element defaults (theming.md §3.3); '
      'the token backgroundColor writes the element keys',
  'borderColor':
      'a root borderColor beats the element defaults (theming.md §3.3); '
      'the token borderColor writes the scale and element keys',
  'font.family':
      'no root font (theming.md §3.4): the token font writes each font slot',
  'font.lineHeight':
      'no root font (theming.md §3.4): the token font writes each font slot',
  'font.size':
      'no root font (theming.md §3.4): the token font writes each font slot',
  'font.style':
      'no root font (theming.md §3.4): the token font writes each font slot',
  'font.weight':
      'no root font (theming.md §3.4); the light preset has no weight',
  'hoverBackgroundColor':
      'a function: getHoverColor derives it from the themed base color '
      '(core.defaults.js:62); no static hover colors (theming.md §3.2)',
  'hoverBorderColor':
      'a function: getHoverColor derives it from the themed base color '
      '(core.defaults.js:63); no static hover colors (theming.md §3.2)',
  'hoverColor':
      'a function: getHoverColor derives it from the themed base color '
      '(core.defaults.js:64); no static hover colors (theming.md §3.2)',
  'scale.grid.tickColor':
      'a function that gives the themed grid.color '
      '(core.scale.defaults.js:35)',
  'scale.ticks.textStrokeColor':
      "'': no text stroke by default (core.scale.defaults.js:67); "
      'an app sets it in the chart options (Chart.js ADR 0050)',
  'scales.radialLinear.pointLabels.backdropColor':
      'undefined: no point-label backdrop by default '
      '(scale.radialLinear.js:374)',
  'scales.radialLinear.ticks.color':
      'a route to Defaults.color; hunk H1 fills it from scale.ticks.color '
      'first (precedence_test.dart, radial tick color)',
  'plugins.legend.labels.color':
      'a function that reads chart.options.color (plugin.legend.js:661), '
      'which the token color emits',
  'plugins.legend.title.color':
      'a function that reads chart.options.color (plugin.legend.js:707), '
      'which the token color emits',
  'plugins.subtitle.font.weight':
      "the local weight 'normal' (plugin.subtitle.js:35-37); the token font "
      'has no weight there (theming.md §3.4)',
  'plugins.title.font.weight':
      "the local weight 'bold' (plugin.title.js:148-150); the token font has "
      'no weight there (theming.md §3.4)',
  'plugins.tooltip.bodyFont.weight':
      'no local weight (plugin.tooltip.js:1289-1290): the route gives the '
      'global font.weight; the light preset has no weight',
  'plugins.tooltip.borderColor':
      "'rgba(0,0,0,0)': no tooltip border by default "
      '(plugin.tooltip.js:1308); an app sets it in the chart options '
      '(Chart.js ADR 0050)',
  'plugins.tooltip.callbacks.labelColor':
      'a function that reads the style of the element '
      '(plugin.tooltip.js:404-415)',
  'plugins.tooltip.callbacks.labelTextColor':
      'a function that reads bodyColor (plugin.tooltip.js:416-418)',
  'plugins.tooltip.displayColors':
      'a bool that shows the color boxes, not a color '
      '(plugin.tooltip.js:1306)',
  'plugins.tooltip.footerFont.weight':
      "the local weight 'bold' (plugin.tooltip.js:1295-1297); the token font "
      'has no weight there (theming.md §3.4)',
  'plugins.tooltip.titleFont.weight':
      "the local weight 'bold' (plugin.tooltip.js:1281-1283); the token font "
      'has no weight there (theming.md §3.4)',
};

/// The upstream values that the reasons of some [_notThemed] keys use, by
/// path. The compiler leaves a weight out of a font slot with a local
/// weight, and it puts the whole token font into a slot without one
/// (theming.md §3.4). A bump that changes, removes or adds a local weight
/// changes the value here, and the report gives STALE.
const Map<String, Object?> _notThemedValues = {
  'font.weight': null,
  'plugins.subtitle.font.weight': 'normal',
  'plugins.title.font.weight': 'bold',
  'plugins.tooltip.bodyFont.weight': null,
  'plugins.tooltip.footerFont.weight': 'bold',
  'plugins.tooltip.titleFont.weight': 'bold',
};

/// The emitted paths that restate a module constant, not a default, each
/// with the reason (Chart.js ADR 0050, Consequences). The manifest does not
/// have them. Test 3 compares their values.
const Map<String, String> _moduleConstants = {
  r'plugins.colors.$borderColors':
      'a module constant of plugin.colors.ts:14-25, not a default. Test 3 '
      'compares its values',
  r'plugins.colors.$backgroundColors':
      'a module constant of plugin.colors.ts:14-25, not a default. Test 3 '
      'compares its values',
};

/// The environment variable that makes the test write the snapshot.
const String _updateVariable = 'THEME_SNAPSHOT_UPDATE';

/// The path of the package in the repository.
const String _package = 'packages/flutter_chartjs_port';

/// The closest ancestor of the working directory that has a `.gitmodules`
/// file, i.e. the repository root, or null outside the repository.
Directory? _repositoryRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File('${dir.path}/.gitmodules').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

/// The leaves of [value] by dot path, in key order. A List is a leaf.
Map<String, Object?> _leaves(Object? value, [String prefix = '']) {
  if (value is! Map<String, Object?>) return {prefix: value};
  return {
    for (final key in value.keys)
      ..._leaves(value[key], prefix.isEmpty ? key : '$prefix.$key'),
  };
}

/// The leaves of the compiled light preset without the `transitions` keys:
/// the content of the snapshot.
Map<String, Object?> _lightLeaves() => {
  for (final MapEntry(:key, :value) in _leaves(
    compileChartTheme(ChartThemes.light),
  ).entries)
    if (!key.startsWith('transitions.')) key: value,
};

/// Whether the last key of [path] names a color.
bool _isColorKey(String path) {
  final last = path.split('.').last;
  return last == 'color' ||
      last.endsWith('Color') ||
      last.endsWith('Colors') ||
      last.endsWith('Background');
}

/// Whether [path] is a visual leaf: a color key, or a font.
bool _isVisual(String path) =>
    _isColorKey(path) ||
    path.split('.').any((key) => key == 'font' || key.endsWith('Font'));

/// The value of a manifest leaf: the value of a route for `{"route": v}`,
/// else the leaf. A function and `undefined` stay in their tagged form.
Object? _unwrap(Object? leaf) =>
    leaf is Map<String, Object?> &&
        leaf.length == 1 &&
        leaf.containsKey('route')
    ? leaf['route']
    : leaf;

/// Whether [leaf] is a manifest route leaf with a Map value.
bool _isRouteMap(Object? leaf) =>
    leaf is Map<String, Object?> &&
    leaf.length == 1 &&
    leaf.containsKey('route') &&
    leaf['route'] is Map<String, Object?>;

/// The leaves of [manifest] for the report, in manifest order. A route leaf
/// `<slot>.<key>` with a Map value gives one leaf `<slot>.<key>.<field>` for
/// each field of its Map, with the route of that field as its value
/// (`{"route": v}`).
Map<String, Object?> _reportLeaves(Map<String, Object?> manifest) => {
  for (final MapEntry(key: path, :value) in manifest.entries)
    if (_isRouteMap(value))
      for (final MapEntry(key: field, value: route)
          in ((value! as Map<String, Object?>)['route']!
                  as Map<String, Object?>)
              .entries)
        '$path.$field': <String, Object?>{'route': route}
    else
      path: value,
};

/// The upstream value of the field [path] `<slot>.<key>.<field>` whose
/// parent `<slot>.<key>` is a manifest route leaf with a Map value, as a
/// record, else Dart `null`. An absent field gives the record of Dart
/// `null`.
///
/// For example, `plugins.tooltip.bodyFont.family` takes the `family` of the
/// manifest leaf `plugins.tooltip.bodyFont`, `{"route": {"family": ...}}`.
(Object?,)? _routeField(String path, Map<String, Object?> manifest) {
  final dot = path.lastIndexOf('.');
  if (dot < 0) return null;
  final parent = manifest[path.substring(0, dot)];
  if (parent is! Map<String, Object?> ||
      parent.length != 1 ||
      !parent.containsKey('route')) {
    return null;
  }
  final route = parent['route'];
  return route is Map<String, Object?>
      ? (route[path.substring(dot + 1)],)
      : null;
}

/// Whether the emitted [value] at [path] equals the upstream [upstream].
bool _same(String path, Object? value, Object? upstream) {
  if (_isColorKey(path) && value is String && upstream is String) {
    final a = Color(value).rgbString();
    final b = Color(upstream).rgbString();
    if (a != null && b != null) return a == b;
  }
  if (value is num && upstream is num) return value == upstream;
  return jsonEncode(value) == jsonEncode(upstream);
}

/// The report lists of theming.md §8 test 4 for the emitted [emitted], the
/// manifest leaves [manifest], the keys [notThemed] that the preset does not
/// emit, the emitted module constants [moduleConstants] and the upstream
/// values [notThemedValues] of some [notThemed] keys, by list name. A list
/// without entries is left out.
Map<String, List<String>> _report(
  Map<String, Object?> emitted,
  Map<String, Object?> manifest, [
  Map<String, String> notThemed = _notThemed,
  Map<String, String> moduleConstants = _moduleConstants,
  Map<String, Object?> notThemedValues = _notThemedValues,
]) {
  final added = <String>[];
  final removed = <String>[];
  final changed = <String>[];
  final stale = <String>[];
  final dollar = <String>[];

  final leaves = _reportLeaves(manifest);
  bool hasSlot(String slot) => manifest.keys.any((p) => p.startsWith('$slot.'));
  bool isEmitted(String path) =>
      emitted.containsKey(path) ||
      emitted.keys.any((p) => p.startsWith('$path.'));

  for (final MapEntry(key: path, :value) in emitted.entries) {
    if (moduleConstants.containsKey(path)) continue;
    final Object? upstream;
    final font = RegExp(r'^(.+)\.font\.([^.]+)$').firstMatch(path);
    final route = _routeField(path, manifest);
    if (leaves.containsKey(path)) {
      upstream = _unwrap(leaves[path]);
    } else if (route != null) {
      upstream = route.$1;
    } else if (font != null &&
        hasSlot(font[1]!) &&
        manifest.containsKey('font.${font[2]}')) {
      upstream = _unwrap(manifest['font.${font[2]}']);
    } else {
      removed.add(path);
      continue;
    }
    if (!_same(path, value, upstream)) {
      changed.add(
        '$path: emitted ${jsonEncode(value)}, upstream ${jsonEncode(upstream)}',
      );
    }
  }
  for (final path in manifest.keys) {
    if (path.split('.').any((key) => key.startsWith(r'$'))) dollar.add(path);
  }
  for (final MapEntry(key: path, :value) in leaves.entries) {
    if (_isVisual(path) && !isEmitted(path) && !notThemed.containsKey(path)) {
      added.add('$path: ${jsonEncode(value)}');
    }
  }
  for (final path in notThemed.keys) {
    if (!leaves.containsKey(path)) {
      stale.add('$path: not in the manifest');
    } else if (isEmitted(path)) {
      stale.add('$path: the preset emits it');
    } else if (notThemedValues.containsKey(path)) {
      final upstream = _unwrap(leaves[path]);
      final recorded = notThemedValues[path];
      if (!_same(path, recorded, upstream)) {
        stale.add(
          '$path: upstream ${jsonEncode(upstream)}, '
          'recorded ${jsonEncode(recorded)}',
        );
      }
    }
  }
  for (final path in moduleConstants.keys) {
    if (manifest.containsKey(path)) {
      stale.add('$path: a module constant in the manifest');
    } else if (!emitted.containsKey(path)) {
      stale.add('$path: the preset does not emit it');
    }
  }
  return {
    if (added.isNotEmpty) 'ADDED': added,
    if (removed.isNotEmpty) 'REMOVED': removed,
    if (changed.isNotEmpty) 'CHANGED': changed,
    if (stale.isNotEmpty) 'STALE': stale,
    if (dollar.isNotEmpty) 'DOLLAR': dollar,
  };
}

/// The text of the report [lists], one entry on each line.
String _text(Map<String, List<String>> lists) => [
  for (final MapEntry(:key, :value) in lists.entries) ...[
    '$key:',
    for (final entry in value) '  $entry',
  ],
].join('\n');

void main() {
  final root = _repositoryRoot();
  final manifestFile = root == null
      ? null
      : File('${root.path}/$_package/doc/upstream/manifest.json');
  final snapshotFile = root == null
      ? null
      : File('${root.path}/$_package/test/port/theme/light_snapshot.json');
  final skip = manifestFile == null
      ? 'not inside the flutter_ports repository'
      : manifestFile.existsSync()
      ? false
      : '${manifestFile.path} is missing';

  /// The leaves of `defaults.values.defaults` of the manifest.
  Map<String, Object?> manifestDefaults() {
    final manifest =
        jsonDecode(manifestFile!.readAsStringSync()) as Map<String, Object?>;
    final defaults = manifest['defaults']! as Map<String, Object?>;
    final values = defaults['values']! as Map<String, Object?>;
    return values['defaults']! as Map<String, Object?>;
  }

  group('theming.md §8 test 4: the coverage snapshot', () {
    test('the snapshot holds the compiled light preset', () {
      final leaves = _lightLeaves();
      if (Platform.environment[_updateVariable] == '1') {
        snapshotFile!.writeAsStringSync(
          '${const JsonEncoder.withIndent('  ').convert(leaves)}\n',
        );
      }
      final snapshot =
          jsonDecode(snapshotFile!.readAsStringSync()) as Map<String, Object?>;
      const hint = 'Run with $_updateVariable=1 to write the snapshot again.';
      expect(leaves.keys.toList(), snapshot.keys.toList(), reason: hint);
      for (final MapEntry(key: path, :value) in leaves.entries) {
        expect(
          jsonEncode(value),
          jsonEncode(snapshot[path]),
          reason: '$path. $hint',
        );
      }
    }, skip: skip);

    test('the snapshot covers the defaults inventory of the manifest', () {
      final snapshot =
          jsonDecode(snapshotFile!.readAsStringSync()) as Map<String, Object?>;
      final lists = _report(snapshot, manifestDefaults());
      expect(lists, isEmpty, reason: 'The coverage report:\n${_text(lists)}');
    }, skip: skip);
  });

  group('the report', () {
    // The report on changed inventories: a bump that adds, removes or
    // changes a key gives an entry in the list of the change.
    const emitted = <String, Object?>{
      'color': 'rgba(102, 102, 102, 1)',
      'scale.ticks.font.family': 'serif',
      'scale.ticks.font.size': 12.0,
    };
    const manifest = <String, Object?>{
      'color': '#666',
      'font.family': 'serif',
      'font.size': 12,
      'scale.ticks.color': <String, Object?>{'route': '#666'},
    };
    const notThemed = {
      'font.family': 'test',
      'font.size': 'test',
      'scale.ticks.color': 'test',
    };

    /// The report of [emitted] and [manifest] with the test keys
    /// [notThemed].
    Map<String, List<String>> report(
      Map<String, Object?> emitted,
      Map<String, Object?> manifest,
    ) => _report(emitted, manifest, notThemed, const {});

    test('an equal inventory gives no entry', () {
      expect(report(emitted, manifest), isEmpty);
    });

    test('a new visual key is ADDED', () {
      // The example of theming.md §9: #12130 adds the scale title keys
      // strokeColor and strokeWidth without defaults. A key with a default
      // shows here. A key that is not visual does not.
      final lists = report(emitted, {
        ...manifest,
        'scale.title.strokeColor': '#000',
        'scale.title.strokeWidth': 0,
        'plugins.legend.labels.font': <String, Object?>{'size': 12},
      });
      expect(lists, {
        'ADDED': [
          'scale.title.strokeColor: "#000"',
          'plugins.legend.labels.font: {"size":12}',
        ],
      });
    });

    test('a removed key is REMOVED', () {
      final lists = report(emitted, {
        'font.family': 'serif',
        'font.size': 12,
        'scale.ticks.color': '#000',
        'scale.grid.color': '#000',
      });
      expect(lists['REMOVED'], ['color']);
      // A font slot without any leaf in the manifest is REMOVED too.
      expect(
        report(emitted, {
          'color': '#666',
          'font.family': 'serif',
          'font.size': 12,
        })['REMOVED'],
        ['scale.ticks.font.family', 'scale.ticks.font.size'],
      );
    });

    test('a changed value is CHANGED with the new literal', () {
      final lists = report(emitted, {
        ...manifest,
        'color': {'route': '#555'},
        'font.size': 13,
        'scale.ticks.font.family': 'mono',
      });
      expect(lists['CHANGED'], [
        'color: emitted "rgba(102, 102, 102, 1)", upstream "#555"',
        'scale.ticks.font.family: emitted "serif", upstream "mono"',
        'scale.ticks.font.size: emitted 12.0, upstream 13',
      ]);
    });

    test('colors compare after the parse', () {
      expect(_same('color', 'rgba(102, 102, 102, 1)', '#666'), isTrue);
      expect(
        _same('a.backdropColor', 'rgba(0, 0, 0, 0.75)', '#000000bf'),
        isTrue,
      );
      expect(_same('color', 'rgba(0, 0, 0, 0.1)', 'rgba(0,0,0,0.1)'), isTrue);
      expect(_same('color', 'rgba(0, 0, 0, 0.1)', 'rgba(0,0,0,0.2)'), isFalse);
      // A function is not a color.
      expect(
        _same('color', 'rgba(0, 0, 0, 0.1)', {'function': '0123456789ab'}),
        isFalse,
      );
      // A string that is not a color key compares as a string.
      expect(_same('font.family', '#666', 'rgba(102, 102, 102, 1)'), isFalse);
    });

    test(r'a $ key of the inventory is DOLLAR', () {
      final lists = report(emitted, {
        ...manifest,
        r'plugins.colors.$palette': <Object?>[],
      });
      expect(lists, {
        'DOLLAR': [r'plugins.colors.$palette'],
      });
    });

    test(
      'a notThemed key that upstream removed or the preset emits is STALE',
      () {
        expect(
          _report(emitted, manifest, {
            ...notThemed,
            'gone.color': 'test',
          }, const {}),
          {
            'STALE': ['gone.color: not in the manifest'],
          },
        );
        expect(
          _report(emitted, manifest, {...notThemed, 'color': 'test'}, const {}),
          {
            'STALE': ['color: the preset emits it'],
          },
        );
      },
    );

    test('a field of a route Map takes the field of the route value', () {
      // plugin.tooltip.js:1327-1331: the tooltip fonts route to the global
      // font. Tool 4 records the route leaf with the merged Map.
      const title = 'plugins.tooltip.titleFont';
      const fontRoute = <String, Object?>{
        'route': <String, Object?>{
          'family': 'serif',
          'size': 12,
          'weight': 'bold',
        },
      };
      final withRoute = <String, Object?>{
        ...manifest,
        title: fontRoute,
      };
      expect(
        report({
          ...emitted,
          '$title.family': 'serif',
          '$title.size': 12.0,
          '$title.weight': 'bold',
        }, withRoute),
        isEmpty,
      );
      // A changed field is CHANGED, and a field that the route Map does not
      // have compares with null.
      expect(
        report({
          ...emitted,
          '$title.family': 'mono',
          '$title.size': 12.0,
          '$title.style': 'italic',
          '$title.weight': 'bold',
        }, withRoute),
        {
          'CHANGED': [
            '$title.family: emitted "mono", upstream "serif"',
            '$title.style: emitted "italic", upstream null',
          ],
        },
      );
      // Each field of the route Map is a leaf. Without its emitted
      // fields, each visual field is ADDED.
      expect(report(emitted, withRoute), {
        'ADDED': [
          '$title.family: {"route":"serif"}',
          '$title.size: {"route":12}',
          '$title.weight: {"route":"bold"}',
        ],
      });
      // A route leaf with a value that is not a Map gives no field. The
      // emitted path is REMOVED.
      expect(
        report(
          {...emitted, 'plugins.title.color.alpha': 1.0},
          {
            ...manifest,
            'plugins.title.color': {'route': '#666'},
          },
        ),
        {
          'REMOVED': ['plugins.title.color.alpha'],
        },
      );
    });

    test('a changed local weight of a route font is STALE', () {
      // plugin.tooltip.js:1281-1283, 1289-1290 and 1295-1297: the title and
      // footer fonts have the local weight 'bold', the body font has none.
      // The compiler leaves the weight out of the title and footer fonts,
      // and it puts the whole token font into the body font (theming.md
      // §3.4). The route Map records the merged weight.
      const title = 'plugins.tooltip.titleFont';
      const body = 'plugins.tooltip.bodyFont';
      Map<String, Object?> fonts(Object? titleWeight, Object? bodyWeight) => {
        ...manifest,
        title: <String, Object?>{
          'route': <String, Object?>{'family': 'serif', 'weight': titleWeight},
        },
        body: <String, Object?>{
          'route': <String, Object?>{'family': 'serif', 'weight': bodyWeight},
        },
      };
      final fontsEmitted = <String, Object?>{
        ...emitted,
        '$title.family': 'serif',
        '$body.family': 'serif',
      };
      final weights = {
        ...notThemed,
        '$title.weight': 'test',
        '$body.weight': 'test',
      };
      const values = <String, Object?>{
        '$title.weight': 'bold',
        '$body.weight': null,
      };
      Map<String, List<String>> weightReport(Map<String, Object?> manifest) =>
          _report(fontsEmitted, manifest, weights, const {}, values);

      expect(weightReport(fonts('bold', null)), isEmpty);
      // Upstream removes the local title weight: the route gives the
      // global weight null. Upstream adds a local body weight.
      expect(weightReport(fonts(null, 'normal')), {
        'STALE': [
          '$title.weight: upstream null, recorded "bold"',
          '$body.weight: upstream "normal", recorded null',
        ],
      });
      // A route Map without the field is not in the manifest.
      expect(
        weightReport({
          ...fonts('bold', null),
          body: <String, Object?>{
            'route': <String, Object?>{'family': 'serif'},
          },
        }),
        {
          'STALE': ['$body.weight: not in the manifest'],
        },
      );
      // Without the notThemed keys, the route fields are ADDED.
      expect(
        _report(fontsEmitted, fonts('bold', null), notThemed, const {}),
        {
          'ADDED': [
            '$title.weight: {"route":"bold"}',
            '$body.weight: {"route":null}',
          ],
        },
      );
      // A leaf that is not a route field compares its value too.
      expect(
        _report(
          emitted,
          {...manifest, 'plugins.title.font.weight': 'normal'},
          {...notThemed, 'plugins.title.font.weight': 'test'},
          const {},
          const {'plugins.title.font.weight': 'bold'},
        ),
        {
          'STALE': [
            'plugins.title.font.weight: upstream "normal", recorded "bold"',
          ],
        },
      );
    });

    test('a module constant is not REMOVED', () {
      // plugin.colors.ts:14-25: the palette is a module constant, not a
      // default. The manifest does not have it (Chart.js ADR 0050).
      const palette = r'plugins.colors.$borderColors';
      final withPalette = <String, Object?>{
        ...emitted,
        palette: ['rgba(54, 162, 235, 1)'],
      };
      expect(report(withPalette, manifest), {
        'REMOVED': [palette],
      });
      const constants = {palette: 'test'};
      expect(_report(withPalette, manifest, notThemed, constants), isEmpty);
      // A module constant that the manifest has, or that the preset does
      // not emit, is STALE.
      expect(
        _report(
          withPalette,
          {
            ...manifest,
            palette: <Object?>['rgb(54, 162, 235)'],
          },
          notThemed,
          constants,
        ),
        {
          'STALE': ['$palette: a module constant in the manifest'],
          'DOLLAR': [palette],
        },
      );
      expect(_report(emitted, manifest, notThemed, constants), {
        'STALE': ['$palette: the preset does not emit it'],
      });
    });

    test('each notThemed key has a reason', () {
      for (final MapEntry(key: path, value: reason) in _notThemed.entries) {
        expect(reason, isNotEmpty, reason: path);
        expect(_isVisual(path), isTrue, reason: path);
      }
      for (final MapEntry(key: path, value: reason)
          in _moduleConstants.entries) {
        expect(reason, isNotEmpty, reason: path);
        expect(_notThemed.containsKey(path), isFalse, reason: path);
      }
      for (final path in _notThemedValues.keys) {
        expect(_notThemed.containsKey(path), isTrue, reason: path);
      }
    });
  });
}
