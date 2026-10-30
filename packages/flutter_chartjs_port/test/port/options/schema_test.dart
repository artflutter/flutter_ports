// Original code, not ported from Chart.js: the drift test of the option schema.
@TestOn('vm')
library;

// The schema drift test of Chart.js ADR 0054 §2 and §15. It walks the
// generated scope kinds (`lib/src/options/scope_kinds.g.dart`, the output of
// `tool/options_schema.yaml`):
// - each path of the defaults inventory of `doc/upstream/manifest.json`
//   (`Chart.defaults`, `Chart.overrides` and the descriptors) maps to a
//   declared key, and its value fits the shape of the key;
// - each key of each static declaration site of the inventory is a key of
//   its scope kind;
// - each path of the key census of the raw configs (O2,
//   `key_census_suite.tsv` and `key_census_fixtures.tsv`) maps to a declared
//   key or to a reviewed extra of `census_review.tsv`, and each recorded
//   kind fits the shape or is a reviewed foreign pair. A review entry that no
//   census row needs fails as stale.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:test/test.dart';

/// The dataset kinds: a census path under `data.datasets[]` maps when one
/// of them maps it.
const List<ScopeKind> _datasetKinds = [
  ScopeKind.barControllerDatasetOptions,
  ScopeKind.lineControllerDatasetOptions,
  ScopeKind.bubbleControllerDatasetOptions,
  ScopeKind.doughnutControllerDatasetOptions,
  ScopeKind.polarAreaControllerDatasetOptions,
  ScopeKind.radarControllerDatasetOptions,
  ScopeKind.genericDatasetOptions,
];

/// The result of a walk: the shape bits of the last segment, or Dart
/// `null` when a segment maps to no declared key.
typedef _Walk = ({int? shape, int depth});

/// One step from [kind] by the key [name]: the shape bits and the kind of
/// the nested scope, or Dart `null` when the kind does not declare [name]
/// and has no typed `others`.
(int, ScopeKind?)? _step(ScopeKind kind, String name) {
  final key = optionKeyOf(name);
  if (key != null) {
    final shape = kind.shapeOf(key);
    if (shape != 0) return (shape, kind.childKind(key));
  }
  final others = kind.othersShape;
  if (kind.othersKind != null || others != ShapeBits.any) {
    return (others, kind.othersKind);
  }
  return null;
}

/// Walks the dot path [segments] from [root]. A segment `name[]` is the
/// item of an array: the item of an indexable key has the shape of the key.
_Walk _walk(ScopeKind root, List<String> segments) {
  ScopeKind? kind = root;
  int? shape;
  for (final (i, segment) in segments.indexed) {
    final current = kind;
    if (current == null) {
      // A plain object under an `any` key (for example `adapters`) is a
      // value, not an option scope.
      final previous = shape;
      return previous != null && previous & ShapeBits.any != 0
          ? (shape: ShapeBits.any, depth: segments.length)
          : (shape: null, depth: i);
    }
    final name = segment.endsWith('[]')
        ? segment.substring(0, segment.length - 2)
        : segment;
    final step = _step(current, name);
    if (step == null) return (shape: null, depth: i);
    (shape, kind) = step;
    // The item of a plain array (`list`) is any value.
    if (segment.endsWith('[]') && shape & ShapeBits.list != 0) {
      shape = ShapeBits.any;
    }
  }
  return (shape: shape, depth: segments.length);
}

/// Whether a value of the census kind [kind] fits the shape bits [shape].
/// A function (scriptable), an array (indexable), `null` and `undefined`
/// fit each key.
bool _fits(String kind, int shape) {
  if (shape & ShapeBits.any != 0) return true;
  return switch (kind) {
    'fn' || 'obj:JsFunction' || 'obj:JsClass' => true,
    'List' || 'null' || 'undefined' => true,
    'double' || 'int' => shape & ShapeBits.number != 0,
    'String' => shape & ShapeBits.string != 0,
    'bool' => shape & ShapeBits.boolean != 0,
    'Map' => shape & ShapeBits.scope != 0,
    _ when kind.startsWith('NarrowMap') => shape & ShapeBits.scope != 0,
    _ => false,
  };
}

/// Whether an inventory value [value] fits the shape bits [shape].
bool _fitsInventory(Object? value, int shape) => switch (value) {
  null => true,
  {'undefined': true} || {'function': _} || {'route': _} => true,
  final num _ => _fits('double', shape),
  final String _ => _fits('String', shape),
  final bool _ => _fits('bool', shape),
  final List<Object?> _ => true,
  final Map<String, Object?> map when map.isEmpty => _fits('Map', shape),
  _ => false,
};

/// The census rows of [file]: `(when, path, kind)`.
List<(String, String, String)> _census(String file) => [
  for (final line in File(file).readAsLinesSync())
    if (line.isNotEmpty)
      switch (line.split('\t')) {
        [final label, final path, final kind] => (label, path, kind),
        _ => throw FormatException('$file: bad line "$line"'),
      },
];

/// Whether the census path [path] is under the reviewed path [entry].
bool _under(String path, String entry) =>
    path == entry || path.startsWith('$entry.') || path.startsWith('$entry[]');

/// The census paths that are not option keys of a scope: data items, inline
/// plugins, labels, the compiled theme and the scale ids.
bool _skipped(String path) =>
    path.startsWith('data.datasets[].data[]') ||
    path.startsWith('plugins[]') ||
    path.startsWith('data.labels[]') ||
    path.startsWith(r'$theme') ||
    // The census writes each scale id of `options.scales` as a kind.
    path == 'options.scales.<id>';

void main() {
  final manifest = jsonDecode(
    File('doc/upstream/manifest.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final inventory = manifest['defaults']! as Map<String, Object?>;
  final values = inventory['values']! as Map<String, Object?>;

  group('the defaults inventory', () {
    for (final (group, root) in [
      ('defaults', ScopeKind.chartOptions),
      ('overrides', ScopeKind.overridesByType),
      ('descriptors', ScopeKind.descriptors),
    ]) {
      test('each $group path maps to a key and fits its shape', () {
        final paths = values[group]! as Map<String, Object?>;
        final problems = <String>[];
        for (final MapEntry(key: path, :value) in paths.entries) {
          final walk = _walk(root, path.split('.'));
          final shape = walk.shape;
          if (walk.depth != path.split('.').length || shape == null) {
            problems.add('$path: no key at segment ${walk.depth}');
          } else if (!_fitsInventory(value, shape)) {
            problems.add('$path: ${jsonEncode(value)} does not fit $shape');
          }
        }
        expect(problems, isEmpty);
      });
    }

    test('each key of each static declaration site is a key of its kind', () {
      final sites = inventory['sites']! as List<Object?>;
      final problems = <String>[];
      for (final site in sites.cast<Map<String, Object?>>()) {
        final kind = site['kind']! as String;
        final id = site['id'] as String?;
        if (site['keys'] is! List<Object?>) continue;
        final ScopeKind? scope;
        if ((kind == 'static defaults' || kind == 'field defaults') &&
            id != null) {
          final file = site['file']! as String;
          scope = file.contains('/elements/')
              ? ScopeKind.elementOptionsByType.childKind(optionKeyOf(id)!)
              : file.contains('/controllers/')
              ? ScopeKind.datasetOptionsByType.childKind(optionKeyOf(id)!)
              : file.contains('/scales/')
              ? ScopeKind.scaleOptions
              : file.contains('/plugins/')
              ? ScopeKind.pluginOptionsByType.childKind(
                  optionKeyOf(id == 'subtitle' ? 'subtitle' : id)!,
                )
              : null;
        } else if (kind == 'static overrides') {
          scope = ScopeKind.chartOptions;
        } else {
          scope = null;
        }
        if (scope == null) continue;
        for (final key in (site['keys']! as List<Object?>).cast<String>()) {
          if (_step(scope, key) == null) {
            problems.add('${site['file']}:${site['line']} $key');
          }
        }
      }
      expect(problems, isEmpty);
    });
  });

  group('the key census', () {
    final review = [
      for (final line in File(
        'test/port/options/census_review.tsv',
      ).readAsLinesSync())
        if (line.isNotEmpty && !line.startsWith('#')) line.split('\t'),
    ];
    final extras = [
      for (final entry in review)
        if (entry[0] == 'extra') entry[1],
    ];
    final foreign = {
      for (final entry in review)
        if (entry[0] == 'foreign') '${entry[1]}\t${entry[2]}',
    };
    final writes = {
      for (final entry in review)
        if (entry[0] == 'write') entry[1],
    };
    final rows = [
      ..._census('test/port/options/key_census_suite.tsv'),
      ..._census('test/port/options/key_census_fixtures.tsv'),
    ];
    final usedExtras = <String>{};
    final usedForeign = <String>{};
    final usedWrites = <String>{};

    test('each census path maps to a key or to a reviewed extra', () {
      final problems = <String>{};
      for (final (label, path, kind) in rows) {
        if (label == 'write') {
          final key = path.substring(path.indexOf('.') + 1);
          if (optionKeyOf(key) == null) {
            if (writes.contains(key)) {
              usedWrites.add(key);
            } else {
              problems.add('write $key');
            }
          }
          continue;
        }
        if (_skipped(path)) continue;
        final segments = path.split('.');
        final walks = path.startsWith('data.datasets[].')
            ? [
                for (final kind in _datasetKinds)
                  _walk(kind, segments.sublist(2)),
              ]
            : [_walk(ScopeKind.chartConfiguration, segments)];
        final extra = extras.where((e) => _under(path, e)).firstOrNull;
        if (extra != null) {
          usedExtras.add(extra);
          continue;
        }
        final mapped = walks.where((w) => w.shape != null).toList();
        if (mapped.isEmpty) {
          problems.add('$path ($kind)');
          continue;
        }
        if (!mapped.any((w) => _fits(kind, w.shape!))) {
          final pair = '$path\t$kind';
          if (foreign.contains(pair)) {
            usedForeign.add(pair);
          } else {
            problems.add('foreign $path $kind');
          }
        }
      }
      expect(problems.toList()..sort(), isEmpty);
    });

    test('each review entry has a census row', () {
      // The paths of the census test fill the used sets.
      for (final (label, path, kind) in rows) {
        if (label == 'write') {
          usedWrites.add(path.substring(path.indexOf('.') + 1));
          continue;
        }
        for (final extra in extras) {
          if (_under(path, extra)) usedExtras.add(extra);
        }
        if (foreign.contains('$path\t$kind')) usedForeign.add('$path\t$kind');
      }
      expect(extras.where((e) => !usedExtras.contains(e)), isEmpty);
      expect(foreign.difference(usedForeign), isEmpty);
      expect(writes.difference(usedWrites), isEmpty);
    });
  });
}
