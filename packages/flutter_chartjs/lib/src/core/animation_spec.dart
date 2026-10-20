// Original code, not ported from Chart.js: the typed animation options.

/// The typed copy of the animation options of one config entry (Chart.js ADR
/// 0019, section 4).
///
/// `Animations.configure` copies the keys of `defaults.animation` of each
/// config entry into a new object (core.animations.js:26-29). All the
/// properties of the entry share that object (:31-35). Each `new Animation`
/// reads eight of its values (core.animation.js:31-39). A Map read with a
/// `String` key is a hash lookup. [AnimationSpec] is a Map with one field for
/// each key of `defaults.animation`. Thus the constructor of `Animation`
/// reads a value with a field read, and every reader of a Map still works.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'dart:collection';

import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';

/// The type of [_absent].
final class _Absent {
  const _Absent();
}

/// The value of the field of a known key that the spec does not contain.
///
/// No member gives this value to other code. A read of the field gives
/// [undefined] ([_read]) or Dart `null` ([AnimationSpec.operator []]) for
/// it.
const Object _absent = _Absent();

/// The getter result for the field value [raw]: [undefined] for [_absent],
/// else [raw]. This is the result of `jsGet(spec, key)`.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
Object? _read(Object? raw) => identical(raw, _absent) ? undefined : raw;

/// The resolved animation options of one config entry: a Map with a field
/// for each key of `defaults.animation` (Chart.js ADR 0019, section 4).
///
/// `configure` makes it where upstream makes the object literal `{}`
/// (core.animations.js:26). It writes the keys of
/// `Object.keys(defaults.animation)` in their order (:18, :27-29).
///
/// ## Keys
///
/// The known keys are [knownKeys], the keys of `defaults.animation`
/// (core.animations.defaults.js:5-14) in their order. Every other key goes
/// to a Map of extra keys. A program can add such a key to
/// `defaults.animation`. The spec creates this Map at the first write of
/// such a key.
///
/// ## Map protocol
///
/// [operator []], [operator []=], [containsKey], [remove], [keys], [length]
/// and [clear] give the same results as the same operations on a
/// `Map<String, Object?>` with the same entries, as the Map protocol of the
/// element options (Chart.js ADR 0018, section 3). A read of an absent key
/// gives Dart `null`. Thus `jsGet` gives [undefined] for it. The other
/// members of `Map` come from [MapBase], which uses these members.
///
/// [keys] gives the present known keys in the order of [knownKeys], and then
/// the extra keys in their insertion order. `configure` writes the keys in
/// the order of `defaults.animation`. Thus the key order is the upstream
/// insertion order while `defaults.animation` keeps the known keys in their
/// order.
///
/// ## Typed reads
///
/// Each known key has a getter `<key>Value`, for example [durationValue].
/// It gives the raw value, or [undefined] for an absent key, as
/// `jsGet(spec, key)` gives. It does no Map lookup.
// DIVERGES(chartjs): adapt-animation-spec, a typed copy of the options.
final class AnimationSpec extends MapBase<String, Object?> {
  /// A spec with no key.
  AnimationSpec();

  /// The known keys, in their order: the keys of `defaults.animation`
  /// (core.animations.defaults.js:5-14).
  static const List<String> knownKeys = [
    'delay',
    'duration',
    'easing',
    'fn',
    'from',
    'loop',
    'to',
    'type',
  ];

  Object? _delay = _absent;
  Object? _duration = _absent;
  Object? _easing = _absent;
  Object? _fn = _absent;
  Object? _from = _absent;
  Object? _loop = _absent;
  Object? _to = _absent;
  Object? _type = _absent;

  /// The extra keys: the keys that are not known. Dart `null` before the
  /// first write of an extra key.
  AnyObject? _extra;

  /// core.animations.defaults.js:6 `delay`: the raw value, or [undefined]
  /// for an absent key.
  Object? get delayValue => _read(_delay);

  /// core.animations.defaults.js:7 `duration`: the raw value, or
  /// [undefined] for an absent key.
  Object? get durationValue => _read(_duration);

  /// core.animations.defaults.js:8 `easing`: the raw value, or [undefined]
  /// for an absent key.
  Object? get easingValue => _read(_easing);

  /// core.animations.defaults.js:9 `fn`: the raw value, or [undefined] for
  /// an absent key.
  Object? get fnValue => _read(_fn);

  /// core.animations.defaults.js:10 `from`: the raw value, or [undefined]
  /// for an absent key.
  Object? get fromValue => _read(_from);

  /// core.animations.defaults.js:11 `loop`: the raw value, or [undefined]
  /// for an absent key.
  Object? get loopValue => _read(_loop);

  /// core.animations.defaults.js:12 `to`: the raw value, or [undefined] for
  /// an absent key.
  Object? get toValue => _read(_to);

  /// core.animations.defaults.js:13 `type`: the raw value, or [undefined]
  /// for an absent key.
  Object? get typeValue => _read(_type);

  /// The field value of the known key [key], or [_absent]. A key that is not
  /// known also gives [_absent].
  Object? _rawOf(String key) => switch (key) {
    'delay' => _delay,
    'duration' => _duration,
    'easing' => _easing,
    'fn' => _fn,
    'from' => _from,
    'loop' => _loop,
    'to' => _to,
    'type' => _type,
    _ => _absent,
  };

  /// Writes [raw] to the field of the known key [key]. [_absent] removes the
  /// key. Gives false for a key that is not known.
  bool _store(String key, Object? raw) {
    switch (key) {
      case 'delay':
        _delay = raw;
      case 'duration':
        _duration = raw;
      case 'easing':
        _easing = raw;
      case 'fn':
        _fn = raw;
      case 'from':
        _from = raw;
      case 'loop':
        _loop = raw;
      case 'to':
        _to = raw;
      case 'type':
        _type = raw;
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
    final raw = _rawOf(key);
    if (!identical(raw, _absent)) return raw;
    // A known key is never an extra key, so the extra Map gives null for an
    // absent known key.
    return _extra?[key];
  }

  /// Writes [value] for [key]: to the field of a known key, else to the Map
  /// of extra keys.
  @override
  void operator []=(String key, Object? value) {
    if (!_store(key, value)) {
      (_extra ??= <String, Object?>{})[key] = value;
    }
  }

  @override
  bool containsKey(Object? key) {
    if (key is! String) return false;
    return !identical(_rawOf(key), _absent) ||
        (_extra?.containsKey(key) ?? false);
  }

  /// Removes [key] and returns its value, or Dart `null` for an absent key.
  @override
  Object? remove(Object? key) {
    if (key is! String) return null;
    final raw = _rawOf(key);
    if (identical(raw, _absent)) return _extra?.remove(key);
    _store(key, _absent);
    return raw;
  }

  /// The present known keys in the order of [knownKeys], then the extra keys
  /// in their insertion order.
  ///
  /// The result is a view, as the keys of a Map are: its length and its
  /// items follow the later changes of the spec. Each iteration reads the
  /// keys when it starts. Thus a change during an iteration does not throw a
  /// `ConcurrentModificationError`, as it does for a Map.
  @override
  Iterable<String> get keys => _AnimationSpecKeys(this);

  /// The present keys at this time, in the order of [keys].
  List<String> _keyList() => [
    for (final key in knownKeys)
      if (!identical(_rawOf(key), _absent)) key,
    ...?_extra?.keys,
  ];

  @override
  int get length {
    var count = _extra?.length ?? 0;
    for (final key in knownKeys) {
      if (!identical(_rawOf(key), _absent)) count++;
    }
    return count;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length != 0;

  /// Removes each key.
  @override
  void clear() {
    for (final key in knownKeys) {
      _store(key, _absent);
    }
    _extra = null;
  }
}

/// The view of [AnimationSpec.keys].
final class _AnimationSpecKeys extends Iterable<String> {
  _AnimationSpecKeys(this._spec);

  final AnimationSpec _spec;

  @override
  Iterator<String> get iterator => _spec._keyList().iterator;

  @override
  int get length => _spec.length;

  @override
  bool get isEmpty => _spec.isEmpty;

  @override
  bool get isNotEmpty => _spec.isNotEmpty;

  @override
  bool contains(Object? element) => _spec.containsKey(element);
}
