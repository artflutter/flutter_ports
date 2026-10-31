// Original code, not ported from Chart.js: the typed animation options.

/// The typed copy of the animation options of one config entry (Chart.js ADR
/// 0019, section 4).
///
/// `Animations.configure` copies the keys of `defaults.animation` of each
/// config entry into a new object (core.animations.js:26-29). All the
/// properties of the entry share that object (:31-35). Each `new Animation`
/// reads eight of its values (core.animation.js:31-39). [AnimationSpec] is a
/// typed object with one field for each key of `defaults.animation` and the
/// face by name of Chart.js ADR 0054 §5. Thus the constructor of `Animation`
/// reads a value with a field read.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsArrayIndex;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The type of [_absent].
final class _Absent {
  const _Absent();
}

/// The value of the field of a known key that the spec does not contain.
///
/// No member gives this value to other code. A read of the field gives
/// [undefined] for it ([_read]).
const Object _absent = _Absent();

/// The getter result for the field value [raw]: [undefined] for [_absent],
/// else [raw]. This is the result of `jsGet(spec, key)`.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
Object? _read(Object? raw) => identical(raw, _absent) ? undefined : raw;

/// The resolved animation options of one config entry: a typed object with a
/// field for each key of `defaults.animation` (Chart.js ADR 0019, section 4).
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
/// ## The face
///
/// The spec implements [JsObjectFace] with the JS rules (Chart.js ADR 0054
/// §5), as the element options do: [jsRead] and [operator []] give
/// [undefined] for an absent key. It is not a `Map`.
///
/// [jsKeys] gives the present known keys in the order of [knownKeys], and
/// then the extra keys in their insertion order. `configure` writes the keys in
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
final class AnimationSpec implements JsObjectFace {
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

  /// Writes [value] for [key], an [OptionKey] or a name: the typed write of
  /// `Animations.configure` (core.animations.js:28, Chart.js ADR 0054 §10).
  ///
  /// The [OptionKey] of a known key writes its field with no name lookup.
  /// Another key writes through [jsWrite]: an extra key.
  void storeKey(Object key, Object? value) {
    switch (key) {
      case OptionKey.delay:
        _delay = value;
      case OptionKey.duration:
        _duration = value;
      case OptionKey.easing:
        _easing = value;
      case OptionKey.fn:
        _fn = value;
      case OptionKey.from:
        _from = value;
      case OptionKey.loop:
        _loop = value;
      case OptionKey.to:
        _to = value;
      case OptionKey.type:
        _type = value;
      case final OptionKey other:
        jsWrite(other.jsName, value);
      default:
        jsWrite(key as String, value);
    }
  }

  @override
  Object? jsRead(String name) {
    final raw = _rawOf(name);
    if (!identical(raw, _absent)) return raw;
    // A known key is never an extra key.
    final extra = _extra;
    return extra != null && extra.containsKey(name) ? extra[name] : undefined;
  }

  /// Writes [value] for [name]: to the field of a known key, else to the Map
  /// of extra keys.
  @override
  void jsWrite(String name, Object? value) {
    if (!_store(name, value)) {
      (_extra ??= <String, Object?>{})[name] = value;
    }
  }

  @override
  Object? operator [](String name) => jsRead(name);

  @override
  void operator []=(String name, Object? value) => jsWrite(name, value);

  @override
  bool jsHas(String name) =>
      !identical(_rawOf(name), _absent) || (_extra?.containsKey(name) ?? false);

  @override
  bool jsDelete(String name) {
    if (!jsHas(name)) return false;
    if (!_store(name, _absent)) _extra!.remove(name);
    return true;
  }

  /// The present known keys in the order of [knownKeys], then the extra keys
  /// in their insertion order (the extra keys that are array indices first,
  /// as `Object.keys` orders them).
  @override
  List<String> jsKeys() {
    final keys = [
      for (final key in knownKeys)
        if (!identical(_rawOf(key), _absent)) key,
      ...?_extra?.keys,
    ];
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
}
