// Original code, not ported from Chart.js: the typed animation options.

/// The typed copy of the animation options of one config entry (Chart.js ADR
/// 0019, section 4).
///
/// `Animations.configure` copies the keys of `defaults.animation` of each
/// config entry into a new object (core.animations.js:26-29). All the
/// properties of the entry share that object (:31-35). Each `new Animation`
/// reads seven of its values (core.animation.js:31-39). [AnimationSpec] is a
/// typed object with one typed field for each key of `defaults.animation`
/// and the face by name of Chart.js ADR 0054 §5. Thus the constructor of
/// `Animation` reads a value with a field read.
///
/// This library is a pure layer. Of Flutter, it imports only the curve
/// classes of `package:flutter/animation.dart`.
library;

import 'package:flutter/animation.dart' show Curve;
import 'package:flutter_chartjs_port/src/core/core.animation.dart'
    show Interpolator;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsArrayIndex;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show JsObjectFace;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The resolved animation options of one config entry: a typed object with a
/// typed field for each key of `defaults.animation` (Chart.js ADR 0019,
/// section 4).
///
/// `configure` makes it where upstream makes the object literal `{}`
/// (core.animations.js:26). It writes the keys of
/// `Object.keys(defaults.animation)` in their order (:18, :27-29).
///
/// ## Keys
///
/// The known keys are [knownKeys], the keys of `defaults.animation`
/// (core.animations.defaults.js:5-14) in their order, without `type` (row
/// `adapt-animation-option-types`). Every other key goes to a Map of extra
/// keys. A program can add such a key to `defaults.animation`. The spec
/// creates this Map at the first write of such a key.
///
/// ## Values
///
/// [delay] and [duration] are `double` milliseconds, the unit of the
/// animation clock: each `Animation` reads them with no conversion. [easing]
/// is a [Curve], [fn] an [Interpolator] and [loop] a `bool`. [from] and [to]
/// hold a value of the app. Dart `null` is an absent value and the JS
/// `undefined`. A write of a value of another type stops a debug build: a
/// text is no number, and an easing name is no curve. A release build stores
/// `null`.
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
/// order. A key that `configure` writes with the value `undefined` is
/// present, as in JavaScript.
// DIVERGES(chartjs): adapt-animation-spec, a typed copy of the options.
// DIVERGES(chartjs): adapt-animation-option-types, typed values.
final class AnimationSpec() implements JsObjectFace {
  /// A spec with no key.
  this;

  /// The known keys, in their order: the keys of `defaults.animation`
  /// (core.animations.defaults.js:5-14) without `type`.
  static const List<String> knownKeys = [
    'delay',
    'duration',
    'easing',
    'fn',
    'from',
    'loop',
    'to',
  ];

  /// The bit of each known key in [_present], by its index in [knownKeys].
  static const int _delayBit = 1;
  static const int _durationBit = 2;
  static const int _easingBit = 4;
  static const int _fnBit = 8;
  static const int _fromBit = 16;
  static const int _loopBit = 32;
  static const int _toBit = 64;

  /// The present known keys: one bit for each key of [knownKeys].
  int _present = 0;

  double? _delay;
  double? _duration;
  Curve? _easing;
  Interpolator? _fn;
  Object? _from;
  bool? _loop;
  Object? _to;

  /// The extra keys: the keys that are not known. Dart `null` before the
  /// first write of an extra key.
  AnyObject? _extra;

  /// core.animations.defaults.js:6 `delay` in milliseconds, or Dart `null`.
  double? get delay => _delay;

  set delay(double? value) {
    _present |= _delayBit;
    _delay = value;
  }

  /// core.animations.defaults.js:7 `duration` in milliseconds, or Dart
  /// `null`.
  double? get duration => _duration;

  set duration(double? value) {
    _present |= _durationBit;
    _duration = value;
  }

  /// core.animations.defaults.js:8 `easing`, or Dart `null`.
  Curve? get easing => _easing;

  set easing(Curve? value) {
    _present |= _easingBit;
    _easing = value;
  }

  /// core.animations.defaults.js:9 `fn`, or Dart `null`.
  Interpolator? get fn => _fn;

  set fn(Interpolator? value) {
    _present |= _fnBit;
    _fn = value;
  }

  /// core.animations.defaults.js:10 `from`, or Dart `null`.
  Object? get from => _from;

  set from(Object? value) {
    _present |= _fromBit;
    _from = value;
  }

  /// core.animations.defaults.js:11 `loop`, or Dart `null`.
  bool? get loop => _loop;

  set loop(bool? value) {
    _present |= _loopBit;
    _loop = value;
  }

  /// core.animations.defaults.js:12 `to`, or Dart `null`.
  Object? get to => _to;

  set to(Object? value) {
    _present |= _toBit;
    _to = value;
  }

  /// The bit of the known key [key], or 0 for a key that is not known.
  static int _bitOf(String key) => switch (key) {
    'delay' => _delayBit,
    'duration' => _durationBit,
    'easing' => _easingBit,
    'fn' => _fnBit,
    'from' => _fromBit,
    'loop' => _loopBit,
    'to' => _toBit,
    _ => 0,
  };

  /// The value of the present known key with the bit [bit], with the JS
  /// [undefined] for Dart `null`.
  Object? _valueOf(int bit) {
    final value = switch (bit) {
      _delayBit => _delay,
      _durationBit => _duration,
      _easingBit => _easing,
      _fnBit => _fn,
      _fromBit => _from,
      _loopBit => _loop,
      _ => _to,
    };
    return value ?? undefined;
  }

  /// Writes [raw] to the field of the known key with the bit [bit]: the
  /// typed value of [raw] ([_typed]).
  void _store(int bit, Object? raw) {
    switch (bit) {
      case _delayBit:
        delay = _typed<num>('delay', raw)?.toDouble();
      case _durationBit:
        duration = _typed<num>('duration', raw)?.toDouble();
      case _easingBit:
        easing = _typed<Curve>('easing', raw);
      case _fnBit:
        fn = _typed<Interpolator>('fn', raw);
      case _fromBit:
        from = identical(raw, undefined) ? null : raw;
      case _loopBit:
        loop = _typed<bool>('loop', raw);
      case _toBit:
        to = identical(raw, undefined) ? null : raw;
    }
  }

  /// [raw] as a [T], or Dart `null` for `null` and [undefined]. A value of
  /// another type stops a debug build, and a release build gives `null`.
  static T? _typed<T extends Object>(String key, Object? raw) {
    if (raw is T) return raw;
    assert(
      raw == null || raw is Undefined,
      'The animation option $key takes a $T, not $raw.',
    );
    return null;
  }

  /// Writes [value] for [key], an [OptionKey] or a name: the typed write of
  /// `Animations.configure` (core.animations.js:28, Chart.js ADR 0054 §10).
  ///
  /// The [OptionKey] of a known key writes its field with no name lookup.
  /// Another key writes through [jsWrite]: an extra key.
  void storeKey(Object key, Object? value) {
    switch (key) {
      case OptionKey.delay:
        _store(_delayBit, value);
      case OptionKey.duration:
        _store(_durationBit, value);
      case OptionKey.easing:
        _store(_easingBit, value);
      case OptionKey.fn:
        _store(_fnBit, value);
      case OptionKey.from:
        _store(_fromBit, value);
      case OptionKey.loop:
        _store(_loopBit, value);
      case OptionKey.to:
        _store(_toBit, value);
      case final OptionKey other:
        jsWrite(other.jsName, value);
      default:
        jsWrite(key as String, value);
    }
  }

  /// Whether [test] is true for each present value: the known keys, then
  /// the extra keys (Chart.js ADR 0151).
  bool everyValue(bool Function(Object? value) test) {
    for (var bit = _delayBit; bit <= _toBit; bit <<= 1) {
      if (_present & bit != 0 && !test(_valueOf(bit))) return false;
    }
    final extra = _extra;
    return extra == null || extra.values.every(test);
  }

  @override
  Object? jsRead(String name) {
    final bit = _bitOf(name);
    if (bit != 0) return _present & bit != 0 ? _valueOf(bit) : undefined;
    final extra = _extra;
    return extra != null && extra.containsKey(name) ? extra[name] : undefined;
  }

  /// Writes [value] for [name]: to the field of a known key, else to the Map
  /// of extra keys.
  @override
  void jsWrite(String name, Object? value) {
    final bit = _bitOf(name);
    if (bit != 0) {
      _store(bit, value);
    } else {
      (_extra ??= <String, Object?>{})[name] = value;
    }
  }

  @override
  Object? operator [](String name) => jsRead(name);

  @override
  void operator []=(String name, Object? value) => jsWrite(name, value);

  @override
  bool jsHas(String name) {
    final bit = _bitOf(name);
    if (bit != 0) return _present & bit != 0;
    return _extra?.containsKey(name) ?? false;
  }

  @override
  bool jsDelete(String name) {
    if (!jsHas(name)) return false;
    final bit = _bitOf(name);
    if (bit == 0) {
      _extra!.remove(name);
      return true;
    }
    _store(bit, null);
    _present &= ~bit;
    return true;
  }

  /// The present known keys in the order of [knownKeys], then the extra keys
  /// in their insertion order (the extra keys that are array indices first,
  /// as `Object.keys` orders them).
  @override
  List<String> jsKeys() {
    final keys = [
      for (final key in knownKeys)
        if (_present & _bitOf(key) != 0) key,
      ...?_extra?.keys,
    ];
    if (!keys.any((key) => jsArrayIndex(key) != null)) return keys;
    // The indices are distinct integers: an unstable sort gives one order.
    final indices = [
      for (final key in keys)
        if (jsArrayIndex(key) case final int index) (index, key),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    return [
      for (final (_, key) in indices) key,
      for (final key in keys)
        if (jsArrayIndex(key) == null) key,
    ];
  }
}
