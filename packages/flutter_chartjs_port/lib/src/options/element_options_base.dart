// Original code, not ported from Chart.js: the base of the element options.

/// The base of the resolved options of an element (Chart.js ADR 0054 §9):
/// [ElementOptions], the face by name over the fields of a subclass, and
/// [GenericElementOptions], the options of an element type without a
/// generated class (a custom element type).
///
/// The generated subclasses (`resolved.g.dart`: `PointOptions`,
/// `LineOptions`, `BarOptions` and `ArcOptions`) keep each declared key in a
/// typed field (a `double`, a `bool`, a `String?` or an `Object?`), with a
/// bit for a present key and a foreign slot for a value outside the type of
/// the field (Chart.js ADR 0054 §6). The face of [ElementOptions] (Chart.js
/// ADR 0054 §5) gives the raw value of each key and keeps the key order of
/// Chart.js ADR 0021 §4: the known keys in the order of `knownKeys`, then
/// the extras in insertion order. The options are not a `Map`.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsArrayIndex;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show JsFreezable, JsObjectFace;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The type of [_absent].
final class _Absent {
  const _Absent();
}

/// The value of the field of a known key that the options do not contain.
///
/// No member gives this value to other code. A read of the field gives
/// [undefined] for it ([readElementOption]).
const Object elementOptionAbsent = _Absent();

const Object _absent = elementOptionAbsent;

/// The getter result for the field value [raw]: [undefined] for [_absent],
/// else [raw]. This is the result of `jsGet(options, key)`.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
Object? readElementOption(Object? raw) =>
    identical(raw, _absent) ? undefined : raw;

Object? _read(Object? raw) => readElementOption(raw);

/// The resolved options of an element: a JS object with a field for each
/// known key (Chart.js ADR 0054 §9).
///
/// ## Keys
///
/// The known keys of a subclass are in its static `knownKeys` list, in this
/// order: `$shared`, the keys of the `defaults` of its element class, the
/// keys of its `defaultRoutes`, and the keys that other code writes into the
/// options of that element type:
/// - `$shared`: `resolveNamedOptions` writes it first (core.config.js:352,
///   :356), and `_resolveElementOptions` writes it again
///   (core.datasetController.js:826).
/// - `$animations`: the animations write it into the options that they
///   animate (core.animations.js:71, :159).
/// - `segment` of `LineOptions`: the line and scatter controllers write it
///   (controller.line.js:66, controller.scatter.js:86).
///
/// Every other key goes to a Map of extra keys. The options create this Map
/// at the first write of such a key.
///
/// ## The face
///
/// The options implement [JsObjectFace] with the JS rules (Chart.js ADR 0054
/// §5): [jsRead] and [operator []] give the raw value of a key, or
/// [undefined] for an absent key; [jsWrite] and [operator []=] write a key;
/// [jsDelete] deletes it; [jsKeys] gives the own keys in the order of
/// `Object.keys`. The options are not a `Map`.
///
/// [jsKeys] gives the present known keys in the order of the list, and then
/// the extra keys in their insertion order (an extra key that is an array
/// index comes first, as `Object.keys` orders it). `resolveNamedOptions`
/// writes `$shared` first and then the names of `defaults.elements[type]` in
/// their order (core.config.js:352-366). Thus the key order of the options
/// that the resolver makes is the upstream insertion order. A write of the
/// known keys in another order gives another key order than JavaScript
/// (Chart.js ADR 0021, section 4).
///
/// ## Typed reads
///
/// Each known key has a typed getter and a getter `<key>Value`, for example
/// `PointOptions.radiusValue`. `<key>Value` gives the raw value, or
/// [undefined] for an absent key, as `jsGet(options, key)` gives.
///
/// ## Copies and the frozen state
///
/// [clone] is the copy `Object.assign({}, options)` in the same class
/// (Chart.js ADR 0021, section 3). [freeze] is `Object.freeze(options)`
/// (core.datasetController.js:831). In the frozen state, the options behave
/// as a frozen object in strict mode (Chart.js ADR 0021, section 5):
/// - [jsWrite] throws a [TypeError] for each key, also for a write of the
///   same value.
/// - [jsDelete] throws a [TypeError] for a present key. It returns false for
///   an absent key, as a `delete` of an absent property succeeds.
/// - The reads do not change.
///
/// The freeze is shallow, as `Object.freeze` is. An object value of frozen
/// options stays writable, for example `$animations`.
abstract class ElementOptions implements JsFreezable, JsObjectFace {
  /// Options with the entries of [source], in the key order of [source].
  ///
  /// Each entry goes through [jsWrite]. Dart `null` for [source] gives
  /// options with no key.
  ElementOptions([AnyObject? source]) {
    if (source != null) {
      for (final MapEntry(:key, :value) in source.entries) {
        jsWrite(key, value);
      }
    }
  }

  /// The copy of the base fields of [source] for [clone]: `$shared`,
  /// `$animations` and a new Map of extra keys with the same entries in the
  /// same order. The copy is not frozen.
  ElementOptions.copyFrom(ElementOptions source)
    : _shared = source._shared,
      _animations = source._animations,
      _extra = switch (source._extra) {
        null => null,
        final extra => Map<String, Object?>.of(extra),
      };

  Object? _shared = _absent;
  Object? _animations = _absent;

  /// The extra keys: the keys that are not known. Dart `null` before the
  /// first write of an extra key.
  AnyObject? _extra;

  /// Whether [freeze] has run.
  bool _frozen = false;

  /// `Object.isFrozen(options)`: whether [freeze] has run.
  @override
  bool get isFrozen => _frozen;

  /// `Object.freeze(options)` (core.datasetController.js:831): a later write
  /// throws a [TypeError]. No member clears the frozen state.
  @override
  void freeze() {
    _frozen = true;
  }

  /// `Object.assign({}, options)`: new options of the same class with the
  /// same entries in the same order (Chart.js ADR 0021, section 3).
  ///
  /// The copy is shallow, as `Object.assign` is: the values are the same
  /// objects. The copy has a new Map of extra keys. It is not frozen, also
  /// when these options are frozen.
  ElementOptions clone();

  /// The known keys of the subclass, in their order: its static `knownKeys`.
  List<String> get knownKeyList;

  /// core.config.js:352 `$shared`: the raw value, or [undefined] for an
  /// absent key.
  Object? get $sharedValue => _read(_shared);

  /// core.animations.js:71 `$animations`: the raw value, or [undefined] for
  /// an absent key.
  Object? get $animationsValue => _read(_animations);

  /// The field value of the known key [key], or [_absent]. A key that is not
  /// known also gives [_absent].
  ///
  /// A subclass handles its own keys in a `switch` and passes the other keys
  /// to this method.
  Object? rawOf(String key) => switch (key) {
    r'$shared' => _shared,
    r'$animations' => _animations,
    _ => _absent,
  };

  /// Writes [raw] to the field of the known key [key]. [_absent] removes the
  /// key. Gives false for a key that is not known.
  ///
  /// A subclass handles its own keys in a `switch` and passes the other keys
  /// to this method.
  bool storeRaw(String key, Object? raw) {
    switch (key) {
      case r'$shared':
        _shared = raw;
      case r'$animations':
        _animations = raw;
      default:
        return false;
    }
    return true;
  }

  /// `options[name]`: the value of [name], or [undefined] for an absent key.
  @override
  Object? jsRead(String name) {
    final raw = rawOf(name);
    if (!identical(raw, _absent)) return raw;
    // A known key is never an extra key.
    final extra = _extra;
    return extra != null && extra.containsKey(name) ? extra[name] : undefined;
  }

  /// `options[name] = value`: writes the field of a known key, else the Map
  /// of extra keys.
  ///
  /// Throws a [TypeError] in the frozen state, as a write into a frozen
  /// object in strict mode does.
  @override
  void jsWrite(String name, Object? value) {
    // A JavaScript TypeError: a write into a frozen object.
    if (_frozen) throw TypeError();
    if (!storeRaw(name, value)) {
      (_extra ??= <String, Object?>{})[name] = value;
    }
  }

  /// `options[name]`: [jsRead].
  @override
  Object? operator [](String name) => jsRead(name);

  /// `options[name] = value`: [jsWrite].
  @override
  void operator []=(String name, Object? value) => jsWrite(name, value);

  /// `Object.prototype.hasOwnProperty.call(options, name)`.
  @override
  bool jsHas(String name) =>
      !identical(rawOf(name), _absent) || (_extra?.containsKey(name) ?? false);

  /// `delete options[name]`: returns whether the options owned [name].
  ///
  /// Throws a [TypeError] for a present key in the frozen state, as a
  /// `delete` of a property of a frozen object in strict mode does.
  @override
  bool jsDelete(String name) {
    final raw = rawOf(name);
    if (identical(raw, _absent)) {
      final extra = _extra;
      if (extra == null || !extra.containsKey(name)) return false;
      // A JavaScript TypeError: a delete of a property of a frozen object.
      if (_frozen) throw TypeError();
      extra.remove(name);
      return true;
    }
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen) throw TypeError();
    storeRaw(name, _absent);
    return true;
  }

  /// `Object.keys(options)`: the present known keys in the order of the
  /// list, then the extra keys in their insertion order, with the extra
  /// keys that are array indices first.
  @override
  List<String> jsKeys() => _orderKeys(_keyList());

  /// The present keys at this time: the known keys in the order of the
  /// list, then the extra keys.
  List<String> _keyList() => [
    for (final key in knownKeyList)
      if (!identical(rawOf(key), _absent)) key,
    ...?_extra?.keys,
  ];

  /// The count of the own keys.
  int get ownKeyCount {
    var count = _extra?.length ?? 0;
    for (final key in knownKeyList) {
      if (!identical(rawOf(key), _absent)) count++;
    }
    return count;
  }

  /// Stores the resolved raw value [raw] of [key], an `OptionKey` or a
  /// name: the typed store of the element step (Chart.js ADR 0054 §4). A
  /// generated subclass stores a declared key in its typed field. Throws a
  /// [TypeError] in the frozen state.
  void storeKey(Object key, Object? raw) {
    jsWrite(key is OptionKey ? key.jsName : key as String, raw);
  }

  /// Whether the options own the declared key [key]. A typed field gives
  /// 0, Dart `null` or false for an absent key, where upstream reads
  /// `undefined` (for example after a user `delete` of a default). A reader
  /// that must see `undefined` tests this bit first. Here `$shared` and
  /// `$animations` are present when they have a value; every other key gives
  /// false. A generated subclass gives the bits of its fields.
  bool isPresent(OptionKey key) => switch (key) {
    OptionKey.dollarShared => !identical(_shared, _absent),
    OptionKey.dollarAnimations => !identical(_animations, _absent),
    _ => false,
  };

  /// The raw resolved value of [key]: the foreign value when the foreign bit
  /// is set, and [undefined] when the options do not own the key. It is the
  /// result of `jsGet(options, key.jsName)`. A generated subclass reads its
  /// fields; this base, and thus [GenericElementOptions], reads the face.
  Object? valueOf(OptionKey key) => jsRead(key.jsName);

  /// Whether the value of the declared key [key] is outside the type of its
  /// field (Chart.js ADR 0054 §6): the field holds the JS conversion, and
  /// [foreignOf] gives the raw value.
  bool isForeign(OptionKey key) => false;

  /// The raw value of the foreign key [key], or Dart `null`.
  Object? foreignOf(OptionKey key) => null;
}

/// [keys] in the order of `Object.keys`: the keys that are array indices
/// first, in ascending order, then the other keys in their order.
List<String> _orderKeys(List<String> keys) {
  if (!keys.any((key) => jsArrayIndex(key) != null)) return keys;
  // The indices are distinct integers: an unstable sort gives one order.
  final indices =
      [
          for (final key in keys)
            if (jsArrayIndex(key) case final int index) (index, key),
        ]
        // js-ok: distinct keys, as jsObjectKeys sorts them
        ..sort((a, b) => a.$1.compareTo(b.$1));
  return [
    for (final (_, key) in indices) key,
    for (final key in keys)
      if (jsArrayIndex(key) == null) key,
  ];
}

/// The resolved options of an element type without a typed class (Chart.js
/// ADR 0021, section 2): a custom element type, or a subclass of an element
/// class with its own id.
///
/// It has no known keys. It keeps each key, also `$shared` and
/// `$animations`, in one `LinkedHashMap`. Thus its key order is the
/// insertion order of JavaScript. It has the frozen state and [clone] of
/// [ElementOptions].
final class GenericElementOptions extends ElementOptions {
  /// Options with the entries of [source], in its key order (see
  /// [ElementOptions.new]).
  GenericElementOptions([super.source]) : _map = <String, Object?>{};

  /// The copy of [source] for [clone]: a new Map with the same entries in the
  /// same order.
  GenericElementOptions._copy(GenericElementOptions super.source)
    : _map = Map<String, Object?>.of(source._map),
      super.copyFrom();

  /// Each key, also `$shared` and `$animations`, in insertion order.
  final AnyObject _map;

  @override
  List<String> get knownKeyList => const [];

  /// `Object.assign({}, options)`: a new [GenericElementOptions] with the
  /// entries of these options in their order (Chart.js ADR 0021, section 3).
  /// It is not frozen.
  @override
  GenericElementOptions clone() => GenericElementOptions._copy(this);

  /// core.config.js:352 `$shared`: the raw value, or [undefined] for an
  /// absent key.
  @override
  Object? get $sharedValue => _mapValue(r'$shared');

  /// core.animations.js:71 `$animations`: the raw value, or [undefined] for
  /// an absent key.
  @override
  Object? get $animationsValue => _mapValue(r'$animations');

  /// The value of [key], or [undefined] for an absent key, as
  /// `jsGet(options, key)` gives.
  Object? _mapValue(String key) {
    final value = _map[key];
    return value == null && !_map.containsKey(key) ? undefined : value;
  }

  @override
  Object? jsRead(String name) => _mapValue(name);

  /// Writes [value] for [name].
  ///
  /// Throws a [TypeError] in the frozen state, as a write into a frozen
  /// object in strict mode does.
  @override
  void jsWrite(String name, Object? value) {
    // A JavaScript TypeError: a write into a frozen object.
    if (_frozen) throw TypeError();
    _map[name] = value;
  }

  @override
  bool jsHas(String name) => _map.containsKey(name);

  /// Deletes [name] and returns whether the options owned it.
  ///
  /// Throws a [TypeError] for a present key in the frozen state, as a
  /// `delete` of a property of a frozen object in strict mode does.
  @override
  bool jsDelete(String name) {
    if (!_map.containsKey(name)) return false;
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen) throw TypeError();
    _map.remove(name);
    return true;
  }

  /// The keys in the order of `Object.keys`: the keys of a `LinkedHashMap`,
  /// with the array-index keys first.
  @override
  List<String> jsKeys() => _orderKeys(_map.keys.toList());

  @override
  int get ownKeyCount => _map.length;
}
