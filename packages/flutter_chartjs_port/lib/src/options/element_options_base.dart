// Original code, not ported from Chart.js: the base of the element options.

/// The base of the resolved options of an element (Chart.js ADR 0054 §9):
/// [ElementOptions], the Map protocol over the fields of a subclass, and
/// [GenericElementOptions], the options of an element type without a
/// generated class (a custom element type).
///
/// The generated subclasses (`resolved.g.dart`: `PointOptions`,
/// `LineOptions`, `BarOptions` and `ArcOptions`) keep each declared key in a
/// typed field (a `double`, a `bool`, a `String?` or an `Object?`), with a
/// bit for a present key and a foreign slot for a value outside the type of
/// the field (Chart.js ADR 0054 §6). The Map protocol of [ElementOptions]
/// (the scaffolding of Chart.js ADR 0054 §5) gives the raw value of each key
/// and keeps the key order of Chart.js ADR 0018 §3: the known keys in the
/// order of `knownKeys`, then the extras in insertion order.
///
/// This library is a pure layer.
library;

import 'dart:collection';

import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsFreezable;
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
/// [undefined] ([readElementOption]) or Dart `null` (the Map read) for it.
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

/// The resolved options of an element: a Map with a field for each known key
/// (Chart.js ADR 0018).
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
/// ## Map protocol
///
/// [operator []], [operator []=], [containsKey], [remove], [keys], [length]
/// and [clear] give the same results as the same operations on a
/// `Map<String, Object?>` with the same entries. A read of an absent key
/// gives Dart `null`. Thus `jsGet` gives [undefined] for it. The other
/// members of `Map` come from [MapBase], which uses these members.
///
/// [keys] gives the present known keys in the order of the list, and then
/// the extra keys in their insertion order. `resolveNamedOptions` writes
/// `$shared` first and then the names of `defaults.elements[type]` in their
/// order (core.config.js:352-366). Thus the key order of the options that
/// the resolver makes is the upstream insertion order. A write of the known
/// keys in another order gives another key order than JavaScript (Chart.js
/// ADR 0018, section 3).
///
/// ## Typed reads
///
/// Each known key has a getter `<key>Value`, for example
/// `PointOptions.radiusValue`. It gives the raw value, or [undefined] for an
/// absent key, as `jsGet(options, key)` gives. The element code reads each
/// option through one small function that also takes a plain Map (Chart.js
/// ADR 0018, section 4).
///
/// ## Copies and the frozen state
///
/// [clone] is the copy `Object.assign({}, options)` in the same class
/// (Chart.js ADR 0021, section 3). [freeze] is `Object.freeze(options)`
/// (core.datasetController.js:831). In the frozen state, the options behave
/// as a frozen object in strict mode (Chart.js ADR 0021, section 5):
/// - [operator []=] throws a [TypeError] for each key, also for a write of
///   the same value.
/// - [remove] throws a [TypeError] for a present key. It returns Dart `null`
///   for an absent key, as a `delete` of an absent property succeeds.
/// - [clear] throws a [TypeError] when the options contain a key.
/// - The members of [MapBase] that write, for example `addAll` and `update`,
///   write through these three members. Thus they throw too.
/// - The reads do not change.
///
/// The freeze is shallow, as `Object.freeze` is. A Map value of frozen
/// options stays writable, for example `$animations`.
abstract class ElementOptions extends MapBase<String, Object?>
    implements JsFreezable {
  /// Options with the entries of [source], in the key order of [source].
  ///
  /// Each entry goes through [operator []=]. Dart `null` for [source] gives
  /// options with no key.
  ElementOptions([AnyObject? source]) {
    if (source != null) {
      for (final MapEntry(:key, :value) in source.entries) {
        this[key] = value;
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

  /// The value of [key], or Dart `null` for an absent key, as the read of a
  /// `Map<String, Object?>` gives.
  @override
  Object? operator [](Object? key) {
    if (key is! String) return null;
    final raw = rawOf(key);
    if (!identical(raw, _absent)) return raw;
    // A known key is never an extra key, so the extra Map gives null for an
    // absent known key.
    return _extra?[key];
  }

  /// Writes [value] for [key]: to the field of a known key, else to the Map
  /// of extra keys.
  ///
  /// Throws a [TypeError] in the frozen state, as a write into a frozen
  /// object in strict mode does.
  @override
  void operator []=(String key, Object? value) {
    // A JavaScript TypeError: a write into a frozen object.
    if (_frozen) throw TypeError();
    if (!storeRaw(key, value)) {
      (_extra ??= <String, Object?>{})[key] = value;
    }
  }

  @override
  bool containsKey(Object? key) {
    if (key is! String) return false;
    return !identical(rawOf(key), _absent) ||
        (_extra?.containsKey(key) ?? false);
  }

  /// Removes [key] and returns its value, or Dart `null` for an absent key.
  ///
  /// Throws a [TypeError] for a present key in the frozen state, as a
  /// `delete` of a property of a frozen object in strict mode does.
  @override
  Object? remove(Object? key) {
    if (key is! String) return null;
    final raw = rawOf(key);
    if (identical(raw, _absent)) {
      final extra = _extra;
      if (extra == null || !extra.containsKey(key)) return null;
      // A JavaScript TypeError: a delete of a property of a frozen object.
      if (_frozen) throw TypeError();
      return extra.remove(key);
    }
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen) throw TypeError();
    storeRaw(key, _absent);
    return raw;
  }

  /// The present known keys in the order of the list, then the extra keys in
  /// their insertion order.
  ///
  /// The result is a view, as the keys of a Map are: its length and its
  /// items follow the later changes of the options. Each iteration reads the
  /// keys when it starts. Thus a change during an iteration does not throw a
  /// `ConcurrentModificationError`, as it does for a Map.
  @override
  Iterable<String> get keys => _ElementOptionsKeys(this);

  /// The present keys at this time, in the order of [keys].
  List<String> _keyList() => [
    for (final key in knownKeyList)
      if (!identical(rawOf(key), _absent)) key,
    ...?_extra?.keys,
  ];

  @override
  int get length {
    var count = _extra?.length ?? 0;
    for (final key in knownKeyList) {
      if (!identical(rawOf(key), _absent)) count++;
    }
    return count;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length != 0;

  /// Removes each key.
  ///
  /// Throws a [TypeError] in the frozen state when the options contain a key,
  /// as the `delete` of each property does.
  @override
  void clear() {
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen && isNotEmpty) throw TypeError();
    for (final key in knownKeyList) {
      storeRaw(key, _absent);
    }
    _extra = null;
  }

  /// Stores the resolved raw value [raw] of [key], an `OptionKey` or a
  /// name: the typed store of the element step (Chart.js ADR 0054 §4). A
  /// generated subclass stores a declared key in its typed field. Throws a
  /// [TypeError] in the frozen state.
  void storeKey(Object key, Object? raw) {
    this[key is OptionKey ? key.jsName : key as String] = raw;
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

  /// Whether the value of the declared key [key] is outside the type of its
  /// field (Chart.js ADR 0054 §6): the field holds the JS conversion, and
  /// [foreignOf] gives the raw value.
  bool isForeign(OptionKey key) => false;

  /// The raw value of the foreign key [key], or Dart `null`.
  Object? foreignOf(OptionKey key) => null;
}

/// The view of [ElementOptions.keys].
final class _ElementOptionsKeys extends Iterable<String> {
  _ElementOptionsKeys(this._options);

  final ElementOptions _options;

  @override
  Iterator<String> get iterator => _options._keyList().iterator;

  @override
  int get length => _options.length;

  @override
  bool get isEmpty => _options.isEmpty;

  @override
  bool get isNotEmpty => _options.isNotEmpty;

  @override
  bool contains(Object? element) => _options.containsKey(element);
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
  Object? operator [](Object? key) => _map[key];

  /// Writes [value] for [key].
  ///
  /// Throws a [TypeError] in the frozen state, as a write into a frozen
  /// object in strict mode does.
  @override
  void operator []=(String key, Object? value) {
    // A JavaScript TypeError: a write into a frozen object.
    if (_frozen) throw TypeError();
    _map[key] = value;
  }

  @override
  bool containsKey(Object? key) => _map.containsKey(key);

  /// Removes [key] and returns its value, or Dart `null` for an absent key.
  ///
  /// Throws a [TypeError] for a present key in the frozen state, as a
  /// `delete` of a property of a frozen object in strict mode does.
  @override
  Object? remove(Object? key) {
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen && _map.containsKey(key)) throw TypeError();
    return _map.remove(key);
  }

  /// The keys in insertion order: the keys of a `LinkedHashMap`.
  @override
  Iterable<String> get keys => _map.keys;

  @override
  int get length => _map.length;

  /// Removes each key.
  ///
  /// Throws a [TypeError] in the frozen state when the options contain a key,
  /// as the `delete` of each property does.
  @override
  void clear() {
    // A JavaScript TypeError: a delete of a property of a frozen object.
    if (_frozen && _map.isNotEmpty) throw TypeError();
    _map.clear();
  }
}
