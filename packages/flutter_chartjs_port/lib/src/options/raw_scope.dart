// Original code, not ported from Chart.js: the raw scope of the typed model.

/// The raw boundary of the typed internal model (Chart.js ADR 0054 §5).
///
/// A user Map stays the object of the user: the root config, its `data` and
/// `options`, the dataset Maps, the inline plugin Maps. [RawScope] is a view
/// of such a Map with no cost (an extension type). The resolver reads a raw
/// scope by name once for each key, resolver and update, at the time that
/// upstream reads it (the `_cached` of `helpers.config.ts:218-231`), never
/// for each element.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/opt.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/scope_kinds.g.dart';

/// A user Map read as an option scope.
extension type const RawScope(Map<String, Object?> map) implements Object {
  /// Whether the Map owns the key [name] (`hasOwnProperty`). A key with the
  /// value `undefined` is owned.
  bool owns(String name) => map.containsKey(name);

  /// The cell of the key [name] by the shape bits [shape] (`ShapeBits`), or
  /// Dart `null` when the Map does not own it.
  Opt<Object?>? lookupName(String name, [int shape = ShapeBits.any]) {
    final value = map[name];
    if (value == null && !map.containsKey(name)) return null;
    return classifyMask(value, shape);
  }

  /// The cell of [key], by its shape in [kind] when it is given (the shape
  /// `others` for a key that [kind] does not declare), else by `any`.
  Opt<Object?>? lookup(OptionKey key, [ScopeKind? kind]) {
    if (kind == null) return lookupName(key.jsName);
    final shape = kind.shapeOf(key);
    return lookupName(key.jsName, shape == 0 ? kind.othersShape : shape);
  }

  /// `map[name]` (`[[Get]]`): the value, or [undefined] when absent.
  Object? jsRead(String name) {
    final value = map[name];
    return value == null && !map.containsKey(name) ? undefined : value;
  }

  /// `map[name] = value` (`[[Set]]`): a write into the object of the user,
  /// as upstream writes it.
  void jsWrite(String name, Object? value) {
    map[name] = value;
  }

  /// `Object.keys(map)`.
  List<String> jsKeys() => jsObjectKeys(map);
}
