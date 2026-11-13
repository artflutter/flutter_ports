// Original code, not ported from Chart.js: the drift test of the option schema.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show FontWeight;

import 'package:flutter/animation.dart' show Curve;
import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.interaction.dart'
    show InteractionMode;
import 'package:flutter_chartjs_port/src/helpers/cubic_interpolation_mode.dart'
    show CubicInterpolationMode;
import 'package:flutter_chartjs_port/src/helpers/grace_length.dart'
    show GraceLength;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isObject;
import 'package:flutter_chartjs_port/src/helpers/point_style.dart'
    show PointStyle;
import 'package:flutter_chartjs_port/src/helpers/radius_length.dart'
    show RadiusLength;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsIsFunction;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show JsObjectFace, jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/plugins/decimation_algorithm.dart'
    show DecimationAlgorithm;
import 'package:flutter_chartjs_port/src/plugins/tooltip_position.dart'
    show TooltipPositioner;
import 'package:flutter_chartjs_port/src/types/chart_axis.dart' show ScaleAxis;
import 'package:flutter_chartjs_port/src/types/tooltip_callbacks.dart';
import 'package:test/test.dart';

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
//   census row needs fails as stale;
// - the built typed roots `defaults`, `overrides` and `descriptors` (with the
//   components of `flutter_test_config.dart` registered) equal the defaults
//   inventory in values and key order: each inventory path has its value
//   (a function default compares by its presence), each leaf of the roots
//   is an inventory path, each object of the roots is a typed scope, and the
//   keys of each declaration site keep their order in their object.

import '../../support/color_json.dart';
import '../../support/keyword_enum_json.dart';

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

// The pinned inventory still names callback fields inside its JS object.
// Read the corresponding native fields directly in this test.
const _callbackFields = <String>{
  'beforeTitle',
  'title',
  'afterTitle',
  'beforeBody',
  'beforeLabel',
  'label',
  'labelColor',
  'labelTextColor',
  'labelPointStyle',
  'afterLabel',
  'afterBody',
  'beforeFooter',
  'footer',
  'afterFooter',
};
Object? _field(Object? value, String key) => value is TooltipCallbacks
    ? switch (key) {
        'beforeTitle' => value.beforeTitle,
        'title' => value.title,
        'afterTitle' => value.afterTitle,
        'beforeBody' => value.beforeBody,
        'beforeLabel' => value.beforeLabel,
        'label' => value.label,
        'labelColor' => value.labelColor,
        'labelTextColor' => value.labelTextColor,
        'labelPointStyle' => value.labelPointStyle,
        'afterLabel' => value.afterLabel,
        'afterBody' => value.afterBody,
        'beforeFooter' => value.beforeFooter,
        'footer' => value.footer,
        'afterFooter' => value.afterFooter,
        _ => undefined,
      }
    : jsGet(value, key);

bool _isCallbackField(ScopeKind root, String path) {
  final parts = path.split('.');
  if (parts.length < 2 ||
      !_callbackFields.contains(parts.last) ||
      parts[parts.length - 2] != 'callbacks') {
    return false;
  }
  if (root == ScopeKind.chartConfiguration &&
      path.startsWith('data.datasets[].tooltip.callbacks.')) {
    return true;
  }
  final walk = _walk(root, parts.sublist(0, parts.length - 1));
  return walk.shape != null &&
      walk.shape! & ShapeBits.typed == ShapeBits.tooltipCallbacks;
}

/// Whether a value of the census kind [kind] fits the shape bits [shape].
/// A function (scriptable), an array (indexable), `null` and `undefined`
/// fit each key.
bool _fits(String kind, int shape) {
  if (shape & ShapeBits.any != 0) return true;
  return switch (kind) {
    'fn' || 'obj:JsFunction' || 'obj:JsClass' => true,
    'List' || 'null' || 'undefined' => true,
    // Upstream data hold a number where the port has a length.
    'double' || 'int' =>
      shape & ShapeBits.number != 0 ||
          shape & ShapeBits.typed == ShapeBits.radiusLength ||
          shape & ShapeBits.typed == ShapeBits.graceLength ||
          shape & ShapeBits.typed == ShapeBits.edgeInsets,
    // Upstream data hold a name where the port has a typed atom: a curve, an
    // enum or a class of the port (`ShapeBits.typed`).
    'String' => shape & (ShapeBits.string | ShapeBits.typed) != 0,
    // Upstream data hold an image where the port has an `ImagePointStyle`.
    'obj:UiCanvasGradient' ||
    'obj:UiCanvasPattern' => shape & ShapeBits.typed == ShapeBits.chartPaint,
    'obj:UiImageSource' => shape & ShapeBits.typed == ShapeBits.pointStyle,
    // A font is a `ChartTextStyle` (Chart.js ADR 0116).
    'obj:TooltipCallbacks' =>
      shape & ShapeBits.typed == ShapeBits.tooltipCallbacks,
    'obj:EdgeInsets' => shape & ShapeBits.typed == ShapeBits.edgeInsets,
    'obj:ChartTextStyle' => shape & ShapeBits.typed == ShapeBits.textStyle,
    'bool' => shape & ShapeBits.boolean != 0,
    'Map' =>
      shape & ShapeBits.scope != 0 ||
          shape & ShapeBits.typed == ShapeBits.edgeInsets ||
          shape & ShapeBits.typed == ShapeBits.tooltipCallbacks,
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

/// A path of a field of an upstream font object: `<font path>.<field>`
/// (Chart.js ADR 0116). The port holds the font as one `TextStyle` at the
/// font path.
final RegExp _fontField = RegExp(
  r'^(.+)\.(family|size|style|weight|lineHeight)$',
);

/// Whether the walk of the font path [fontPath] from [root] gives a font.
bool _isFontPath(ScopeKind root, String fontPath) {
  final walk = _walk(root, fontPath.split('.'));
  final shape = walk.shape;
  return walk.depth == fontPath.split('.').length &&
      shape != null &&
      shape & ShapeBits.typed == ShapeBits.textStyle;
}

// Upstream padding fields belong to one native atom in the port.
final RegExp _paddingField = RegExp(
  r'^(.+\.(?:padding|backdropPadding))\.(top|right|bottom|left|x|y)$',
);
bool _isPaddingField(ScopeKind root, String path) {
  final match = _paddingField.firstMatch(path);
  if (match == null) return false;
  final walk = _walk(root, match[1]!.split('.'));
  return walk.shape != null &&
      walk.shape! & ShapeBits.typed == ShapeBits.edgeInsets;
}

Map<String, double> _paddingSides(EdgeInsets p) => {
  'top': p.top,
  'right': p.right,
  'bottom': p.bottom,
  'left': p.left,
};

/// The families of the upstream family list [text] of a font object,
/// without quotes: the rule of `families` of
/// `tool/reference/font_record.mjs`.
List<String> _families(String text) => [
  for (final name in text.split(','))
    if (name.trim().isNotEmpty)
      name.trim().replaceAllMapped(RegExp(r'''^(['"])(.*)\1$'''), (m) => m[2]!),
];

/// The mismatch of the field [field] of the font [font] with the value
/// [expected] of the upstream font object, or Dart `null`. The weight
/// keywords `bold` and `normal` of CSS are the weights 700 and 400.
String? _fontFieldMismatch(TextStyle font, String field, Object? expected) {
  final actual = switch (field) {
    'family' => [?font.fontFamily, ...?font.fontFamilyFallback],
    'size' => font.fontSize,
    'style' => font.fontStyle?.name,
    'weight' => font.fontWeight?.value,
    'lineHeight' => font.height,
    _ => throw ArgumentError.value(field, 'field'),
  };
  final upstream = switch ((field, expected)) {
    ('family', final String text) => _families(text),
    ('weight', 'bold') => FontWeight.bold.value,
    ('weight', 'normal') => FontWeight.normal.value,
    _ => expected,
  };
  final same = actual is num && upstream is num
      ? actual == upstream
      : jsonEncode(actual) == jsonEncode(upstream);
  return same ? null : '$field: $actual != $upstream';
}

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

/// The value at the dot [path] under [root], read key by key with [jsGet].
Object? _read(Object? root, String path) {
  var value = root;
  for (final key in path.split('.')) {
    value = _field(value, key);
  }
  return value;
}

/// The keys of the object [value], or Dart `null` for another value.
List<String>? _keysOf(Object? value) => value is TooltipCallbacks
    ? _callbackFields.where((key) => _field(value, key) != null).toList()
    : isObject(value)
    ? jsObjectKeys(value)
    : null;

/// Whether [key] of the object [object] is routed (`Defaults.route`).
bool _routed(Object? object, String key) => switch (object) {
  final OptionScope scope => scope.routeOf(key) != null,
  _ => false,
};

/// The mismatch of the runtime value [actual] with the inventory value
/// [expected], or Dart `null` when they are equal. A function compares by
/// its presence; a route compares the value read through the route.
String? _mismatch(Object? actual, Object? expected) {
  if (expected is String && nativeColorBytes(actual) != null) {
    return referenceColorOrString(expected).matches(actual, {})
        ? null
        : '$actual != $expected';
  }
  // Upstream has an easing name where the port has a curve: no compare.
  if (expected is String && actual is Curve) return null;
  // Upstream has a mode name where the port has a mode object: no compare.
  if (expected is String && actual is InteractionMode) return null;
  // The same for a positioner name and a positioner object.
  if (expected is String && actual is TooltipPositioner) return null;
  // The same for an algorithm name and an algorithm object.
  if (expected is String && actual is DecimationAlgorithm) return null;
  // The same for a cubic interpolation mode and a point style.
  if (expected is String && actual is CubicInterpolationMode) return null;
  if (expected is String && actual is PointStyle) return null;
  // The same for an axis letter and an axis class (row adapt-axis-objects).
  if (expected is String && actual is ScaleAxis) return null;
  // The same for a length: upstream has a number or a percent text.
  if ((expected is String || expected is num) &&
      (actual is RadiusLength || actual is GraceLength)) {
    return null;
  }
  // Upstream has the keyword of a line cap, a line join or an interaction
  // axis where the port has the enum: the name of the enum value is the
  // keyword.
  if (expected is String && isKeywordEnum(actual)) {
    return (actual! as Enum).name == expected ? null : '$actual != $expected';
  }
  if (actual is EdgeInsets) {
    if (expected is num) {
      return actual == EdgeInsets.all(expected.toDouble())
          ? null
          : '$actual != $expected';
    }
    if (expected is Map<String, Object?>) {
      for (final entry in expected.entries) {
        final mismatch = _mismatch(
          _paddingSides(actual)[entry.key],
          entry.value,
        );
        if (mismatch != null) return mismatch;
      }
      return null;
    }
  }
  switch (expected) {
    case null:
      return actual == null ? null : 'not null: $actual';
    case {'undefined': true}:
      return identical(actual, undefined) ? null : 'not undefined: $actual';
    case {'function': _}:
      return jsIsFunction(actual) ? null : 'not a function: $actual';
    case {'route': final Object? routed}:
      return _mismatch(actual, routed);
    case final num n:
      return actual is num && actual == n ? null : '$actual != $n';
    case final String _ || final bool _:
      return actual == expected ? null : '$actual != $expected';
    case final List<Object?> list:
      if (actual is! List<Object?> || actual.length != list.length) {
        return '$actual != $list';
      }
      for (var i = 0; i < list.length; i++) {
        final item = _mismatch(actual[i], list[i]);
        if (item != null) return '[$i] $item';
      }
      return null;
    // An upstream font object and the font of the port (Chart.js ADR 0116):
    // field by field.
    case final Map<String, Object?> map when actual is TextStyle:
      for (final MapEntry(:key, :value) in map.entries) {
        final item = _fontFieldMismatch(actual, key, value);
        if (item != null) return item;
      }
      return null;
    case final Map<String, Object?> map:
      final keys = _keysOf(actual);
      if (keys == null) return 'not an object: $actual';
      if ((keys.toList()..sort()).join(',') !=
          (map.keys.toList()..sort()).join(',')) {
        return 'keys $keys != ${map.keys.toList()}';
      }
      for (final MapEntry(:key, :value) in map.entries) {
        final item = _mismatch(_field(actual, key), value);
        if (item != null) return '.$key $item';
      }
      return null;
  }
  return 'unknown inventory value $expected';
}

/// The leaf paths under [object] with the prefix [prefix]: a value that is
/// not an object, an empty object, an array, or a routed key.
void _leaves(Object? object, String prefix, List<String> out) {
  for (final key in _keysOf(object)!) {
    final path = prefix.isEmpty ? key : '$prefix.$key';
    final value = _field(object, key);
    final keys = _keysOf(value);
    if (_routed(object, key) || keys == null || keys.isEmpty) {
      out.add(path);
    } else {
      _leaves(value, path, out);
    }
  }
}

/// Each object under [object] that is not a typed scope, by path. A routed
/// value is a new object of each read, as upstream: it is skipped.
void _rawObjects(Object? object, String prefix, List<String> out) {
  for (final key in _keysOf(object)!) {
    if (_routed(object, key)) continue;
    final path = prefix.isEmpty ? key : '$prefix.$key';
    final value = _field(object, key);
    if (!isObject(value)) continue;
    if (value is! OptionScope) out.add(path);
    _rawObjects(value, path, out);
  }
}

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
          // A field of a font object: the font path holds a TextStyle.
          final font = _fontField.firstMatch(path);
          if (font != null && _isFontPath(root, font[1]!)) continue;
          if (_isPaddingField(root, path) || _isCallbackField(root, path)) {
            continue;
          }
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

  group('the typed roots against the defaults inventory', () {
    // flutter_test_config.dart turns off the colors plugin (test/index.js:25-28);
    // the inventory has the upstream value. The defaults restore of the
    // harness puts the test value back after each test.
    void upstreamColors() {
      final colors = _read(defaults, 'plugins.colors')! as JsObjectFace;
      final enabled = colors['enabled'];
      colors['enabled'] = true;
      addTearDown(() => colors['enabled'] = enabled);
    }

    final roots = <(String, Object)>[
      ('defaults', defaults),
      ('overrides', overrides),
      ('descriptors', descriptors),
    ];

    for (final (name, root) in roots) {
      test('each $name path has its value', () {
        upstreamColors();
        final paths = values[name]! as Map<String, Object?>;
        final problems = <String>[];
        for (final MapEntry(key: path, value: expected) in paths.entries) {
          // A field of a font object: the field of the TextStyle.
          final font = _fontField.firstMatch(path);
          final fontValue = font == null ? null : _read(root, font[1]!);
          if (font != null && fontValue is TextStyle) {
            final mismatch = _fontFieldMismatch(fontValue, font[2]!, expected);
            if (mismatch != null) problems.add('$path: $mismatch');
            continue;
          }
          final padding = _paddingField.firstMatch(path);
          final paddingValue = padding == null
              ? null
              : _read(root, padding[1]!);
          if (padding != null && paddingValue is EdgeInsets) {
            final mismatch = _mismatch(
              _paddingSides(paddingValue)[padding[2]],
              expected,
            );
            if (mismatch != null) problems.add('$path: $mismatch');
            continue;
          }
          final Object? actual;
          try {
            actual = _read(root, path);
          } on Object catch (e) {
            problems.add('$path: $e');
            continue;
          }
          final mismatch = _mismatch(actual, expected);
          if (mismatch != null) problems.add('$path: $mismatch');
        }
        expect(problems, isEmpty);
      });

      test('each leaf of $name is an inventory path', () {
        final paths = (values[name]! as Map<String, Object?>).keys.toSet();
        final leaves = <String>[];
        _leaves(root, '', leaves);
        // A font is one leaf: the inventory has its fields.
        bool hasFields(String leaf) =>
            (_read(root, leaf) is TextStyle ||
                _read(root, leaf) is EdgeInsets) &&
            paths.any((path) => path.startsWith('$leaf.'));
        expect(
          leaves.where((leaf) => !paths.contains(leaf) && !hasFields(leaf)),
          isEmpty,
        );
      });

      test('each object of $name is a typed scope', () {
        expect(root, isA<OptionScope>());
        final raw = <String>[];
        _rawObjects(root, '', raw);
        // `adapters` has the shape `any` (helpers.config.ts:215).
        expect(raw.where((path) => !path.endsWith('.adapters')), isEmpty);
      });
    }

    // A defaultRoutes site routes keys that the defaults already own: they
    // keep their places (core.defaults.js:136-157), so it is not an order
    // site. The values of its routes are inventory values (`{route}`).
    test('the keys of each declaration site keep their order', () {
      final sites = inventory['sites']! as List<Object?>;
      const scopes = {
        'elements': 'elements',
        'controllers': 'datasets',
        'scales': 'scales',
        'plugins': 'plugins',
      };
      final problems = <String>[];
      var checked = 0;
      for (final site in sites.cast<Map<String, Object?>>()) {
        final kind = site['kind']! as String;
        final file = site['file']! as String;
        final id = site['id'] as String?;
        final folder = file.split('/')[1];
        var keys = site['keys'] as List<Object?>?;
        Object? object;
        final args = site['args'];
        if (args is List<Object?> &&
            args.length == 2 &&
            args[0] is String &&
            args[1] is Map<String, Object?>) {
          final path = args[0]! as String;
          keys = (args[1]! as Map<String, Object?>)['keys'] as List<Object?>?;
          object = switch (kind) {
            'defaults.set' => _read(defaults, path),
            'defaults.describe' => _read(descriptors, path),
            _ => null,
          };
        } else if (kind == 'new Defaults' && args is List<Object?>) {
          keys = (args[0]! as Map<String, Object?>)['keys'] as List<Object?>?;
          object = descriptors;
        } else if (kind == 'Defaults constructor') {
          object = defaults;
        } else if (id != null && scopes.containsKey(folder)) {
          final scope = scopes[folder]!;
          object = switch (kind) {
            'static defaults' ||
            'field defaults' => _read(defaults, '$scope.$id'),
            'static descriptors' ||
            'field descriptors' => _read(descriptors, '$scope.$id'),
            'static overrides' => _read(overrides, id),
            _ => null,
          };
        }
        if (object == null || keys == null) continue;
        final siteKeys = keys.cast<String>();
        final actual = _keysOf(object);
        if (actual == null) {
          problems.add('$file:${site['line']} not an object');
          continue;
        }
        checked++;
        final ordered = actual.where(siteKeys.contains).toList();
        if (ordered.join(',') != siteKeys.join(',')) {
          problems.add('$file:${site['line']} $ordered != $siteKeys');
        }
      }
      expect(problems, isEmpty);
      expect(checked, greaterThan(40));
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
          if (optionKeyOf(key) == null && !_callbackFields.contains(key)) {
            if (writes.contains(key)) {
              usedWrites.add(key);
            } else {
              problems.add('write $key');
            }
          }
          continue;
        }
        if (_skipped(path) ||
            _isPaddingField(ScopeKind.chartConfiguration, path) ||
            _isCallbackField(ScopeKind.chartConfiguration, path)) {
          continue;
        }
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
