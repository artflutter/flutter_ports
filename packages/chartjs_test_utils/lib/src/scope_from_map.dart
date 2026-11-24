// Original code, not ported from Chart.js: typed scopes from Map configs.

/// The Map path of the tests: a spec that keeps a value form that only
/// JavaScript has (a string number in `data`, a parsing key object, a date
/// text as `min`) gives its options as a Map, and [scopeFromMap] writes them
/// into a typed scope of the port (Chart.js ADR 0054 §7). The library has no
/// Map merge for this: the typed API takes typed values only.
library;

import 'package:flutter_chartjs_port/chartjs_core.dart';

/// Merges [map] into [scope] and gives [scope]. A null [map] merges
/// nothing.
///
/// Each entry becomes a cell of the shape of its key. A Map value merges
/// into the object of the key when [scope] has one (a typed scope or a Map),
/// else it becomes a new typed scope of the kind of the key, or a new
/// `<String, Object?>` Map for a key with no kind. A List or another value
/// replaces the value by reference. Each object of the result is new:
/// Chart.js writes into the option objects. The keys of a Map are Strings,
/// as the keys of a JS object: in debug mode, a key that is not a `String`
/// fails an assert that names the key.
T scopeFromMap<T extends OptionScope>(T scope, Map<String, Object?>? map) {
  if (map != null) _mergeInto(scope, map);
  return scope;
}

/// Merges [source] into [target].
void _mergeInto(OptionScope target, Map<Object?, Object?> source) {
  for (final MapEntry(:key, :value) in source.entries) {
    final name = _key(key);
    if (value is Map<Object?, Object?>) {
      final current = target.ownCell(name)?.raw;
      if (current is OptionScope) {
        _mergeInto(current, value);
        continue;
      }
      if (current is Map<String, Object?>) {
        _merge(current, value);
        continue;
      }
    }
    final previous = target.ownCell(name)?.raw;
    _store(
      target,
      name,
      previous is TooltipCallbacks && value is TooltipCallbacks
          ? previous.merge(value)
          : value,
    );
  }
}

/// Merges [source] into [target], a Map under a key that no kind declares.
void _merge(Map<String, Object?> target, Map<Object?, Object?> source) {
  for (final MapEntry(:key, :value) in source.entries) {
    final name = _key(key);
    if (value is Map<Object?, Object?>) {
      final current = target[name];
      if (current is Map<String, Object?>) {
        _merge(current, value);
      } else {
        target[name] = _copy(value);
      }
    } else {
      target[name] = value;
    }
  }
}

/// Stores the cell of [value] under the name [name] of [scope]: a Map as a
/// typed scope of the kind of the key, or a copy, any other value by
/// reference.
void _store(OptionScope scope, String name, Object? value) {
  final cell = value is Map<Object?, Object?>
      ? scope.classifyName(name, _objectFor(scope, name, value))
      : scope.classifyName(name, value);
  scope.store(name, cell);
}

/// The object of the Map [map] under the name [name] of [scope].
Object _objectFor(OptionScope scope, String name, Map<Object?, Object?> map) {
  final kind = scope.childKindFor(name);
  return kind == null ? _copy(map) : _scopeOf(kind, map);
}

/// A new typed scope of [kind] with the entries of [map] in their order.
OptionScope _scopeOf(ScopeKind kind, Map<Object?, Object?> map) {
  final scope = kind.create();
  for (final MapEntry(:key, :value) in map.entries) {
    _store(scope, _key(key), value);
  }
  return scope;
}

/// A new `<String, Object?>` copy of [map], with a new copy of each Map
/// value and the other values by reference.
Map<String, Object?> _copy(Map<Object?, Object?> map) => <String, Object?>{
  for (final MapEntry(:key, :value) in map.entries)
    _key(key): value is Map<Object?, Object?> ? _copy(value) : value,
};

/// [key], a key of a Map of the config, as a `String`.
String _key(Object? key) {
  assert(
    key is String,
    'The key $key of a config Map is a ${key.runtimeType}, not a String. '
    'Chart.js options are objects with String keys: write the key as '
    "'$key'.",
  );
  return key! as String;
}
