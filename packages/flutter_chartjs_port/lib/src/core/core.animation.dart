// Ported from Chart.js v4.6.1 src/core/core.animation.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-elements, typed keys of Chart.js ADR 0054.

/// Port of `src/core/core.animation.js` (Chart.js ADR 0019).
///
/// An [Animation] animates one property of one target. A target is a Map or
/// a `types.PropertyAccess`, for example an `Element` (Chart.js ADR 0019,
/// section 2). [readProperty] and [writeProperty] are the JS property read
/// and write by name.
///
/// The `cfg` of an animation is a Map. `configure` of `core.animations`
/// makes an [AnimationSpec], a typed Map. The constructor reads each value of
/// an [AnimationSpec] with a field read, and the value of another Map with
/// `jsGet` (Chart.js ADR 0019, section 3).
///
/// The property of an animation is an [AnimatedProp] (Chart.js ADR 0054
/// §10): `Animations` gives the key of its typed table, and the public
/// constructor maps the name with [AnimatedProp.of].
///
/// The port has three hunks for performance (Chart.js ADR 0019, sections 5
/// and 6, with Chart.js ADR 0054 §10):
/// - An animation with the built-in `number` interpolator and two `double`
///   values ticks on two `double` fields (`adapt-animation-number-path`).
///   It writes an `Element` through `Element.writeNumber`, the typed setter
///   of the property.
/// - A color animation keeps the parsed colors of its last call
///   (`adapt-animation-color-cache`).
/// - The constructor resolves the interpolator one time, with no list and
///   no lookup by name. A user `fn` gets one closure that calls it with
///   [jsCall].
///
/// The promises of [Animation.wait] settle in a job of `js_promise.dart`
/// (`platform-animation-promise-checkpoint`, Chart.js ADR 0019, section 7).
///
/// `Animation` is also a class of `package:flutter/animation.dart`. A file
/// that needs both classes imports one library with a prefix.
///
/// This library is a pure layer (Chart.js ADR 0019, section 1). It imports
/// neither `dart:ui` nor `package:flutter`.
library;

import 'dart:async';

import 'package:flutter_chartjs_port/src/core/animation_spec.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart' show Element;
import 'package:flutter_chartjs_port/src/helpers/helpers.color.dart' show color;
import 'package:flutter_chartjs_port/src/helpers/helpers.easing.dart'
    show effects;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_date.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_promise.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart'
    show Color;
import 'package:flutter_chartjs_port/src/options/animated_prop.dart'
    show AnimatedProp;
import 'package:flutter_chartjs_port/src/types/animation.dart' as types;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// core.animation.js:5 `transparent`.
const String _transparent = 'transparent';

/// core.animation.js:6-25 the type of a member of `interpolators`: the value
/// at [factor] between [from] and [to].
typedef Interpolator = Object? Function(
  Object? from,
  Object? to,
  double factor,
);

/// core.animation.js:7 `interpolators.boolean`.
Object? _boolean(Object? from, Object? to, double factor) {
  return factor > 0.5 ? to : from;
}

/// core.animation.js:15 `interpolators.color`.
///
/// @param {string} from
/// @param {string} to
/// @param {number} factor
///
/// `helpers.color` returns a `CanvasGradient` or a `CanvasPattern`
/// unchanged. Such an object has no `valid` property in JavaScript. Thus
/// `c0.valid` is `c0 is Color && c0.valid`.
Object? _color(Object? from, Object? to, double factor) {
  final c0 = color(jsTruthy(from) ? from : _transparent);
  final c1 = c0 is Color && c0.valid
      ? color(jsTruthy(to) ? to : _transparent)
      : false;
  return c1 is Color && c1.valid ? c1.mix(c0 as Color, factor).hexString() : to;
}

/// core.animation.js:22 `interpolators.number`.
///
/// JavaScript applies `ToNumber` to a number, a boolean, `null` and
/// `undefined` in `-` and `*`, and to the left operand of `+` here. For an
/// object or a String operand, the JS `+` appends text. The port gives NaN
/// or a number (Chart.js ADR 0019, section 5): that case is outside the type
/// contract or display-only.
Object? _number(Object? from, Object? to, double factor) {
  return jsToNumber(from) + (jsToNumber(to) - jsToNumber(from)) * factor;
}

/// core.animation.js:6 `interpolators[name]`: the interpolator of the
/// property type [name], or Dart `null` where upstream gives `undefined`.
Interpolator? _interpolatorNamed(String name) => switch (name) {
  'boolean' => _boolean,
  'color' => _color,
  'number' => _number,
  _ => null,
};

/// core.animation.js:35 `interpolators[typeof from]`: `typeof` gives
/// `'number'` for a number and `'boolean'` for a boolean ([jsTypeof]). No
/// other `typeof` names an interpolator.
Interpolator? _interpolatorOf(Object? from) => switch (from) {
  num() => _number,
  bool() => _boolean,
  _ => null,
};

/// core.animation.js:15-21 `interpolators.color` with one parse of each
/// color (Chart.js ADR 0019, section 5).
///
/// Each color animation gets its own object. It keeps the parsed `from` and
/// `to` of its last call, and it compares the next values with `identical`.
/// A new value, for example after `update` or after a write of
/// [Animation.from], gives a new parse. `mix` changes its receiver, so the
/// call mixes a `clone()` of the cached target color. `mix` does not change
/// its argument. A `from` or a `to` that is not a String takes [_color]. The
/// results are the results of [_color].
// DIVERGES(chartjs): adapt-animation-color-cache, one parse of each color.
final class _ColorInterpolator {
  /// The `from || transparent` of the last parse of [_c0].
  Object? _fromKey;

  /// The parse of [_fromKey]. Dart `null` before the first parse.
  Color? _c0;

  /// The `to || transparent` of the last parse of [_c1].
  Object? _toKey;

  /// The parse of [_toKey]. Dart `null` before the first parse.
  Color? _c1;

  /// The color at [factor] between [from] and [to], as [_color] gives.
  Object? call(Object? from, Object? to, double factor) {
    final f = jsTruthy(from) ? from : _transparent;
    final t = jsTruthy(to) ? to : _transparent;
    if (f is! String || t is! String) return _color(from, to, factor);
    var c0 = _c0;
    if (c0 == null || !identical(f, _fromKey)) {
      _fromKey = f;
      _c0 = c0 = Color(f);
    }
    if (!c0.valid) return to;
    var c1 = _c1;
    if (c1 == null || !identical(t, _toKey)) {
      _toKey = t;
      _c1 = c1 = Color(t);
    }
    return c1.valid ? c1.clone().mix(c0, factor).hexString() : to;
  }
}

/// core.animation.js:27 `Animation`, the animation of the property [_prop]
/// of the target [_target].
class Animation implements types.Animation {
  /// core.animation.js:28 `constructor(cfg, target, prop, to)`.
  ///
  /// [cfg] is the animation configuration: an [AnimationSpec] or another
  /// Map. [to] is the [undefined] sentinel when the caller passes no target
  /// value. [prop] is the property name: [Animation.typed] with its
  /// [AnimatedProp].
  Animation(
    AnyObject cfg,
    Object target,
    String prop, [
    Object? to = undefined,
  ]) : this.typed(cfg, target, AnimatedProp.of(prop), to);

  /// core.animation.js:28 `constructor(cfg, target, prop, to)` for the key
  /// [prop] of the typed table of `Animations` (Chart.js ADR 0054 §10).
  ///
  /// The constructor resolves the interpolator one time (Chart.js ADR 0019,
  /// section 5). A truthy `cfg.fn` gets a closure that calls it through
  /// [jsCall], with the animation as `this`. Else the interpolator of
  /// `cfg.type || typeof from` is the built-in function, or Dart `null`
  /// where upstream gives `undefined`. Then the first interpolation throws a
  /// [TypeError], as in JavaScript. `resolve([...])` of upstream is the
  /// first value that is not [undefined], with no list (helpers.options.ts:
  /// 154 without a context and an index).
  @internal
  Animation.typed(
    AnyObject cfg,
    Object target,
    AnimatedProp prop, [
    Object? to = undefined,
  ]) : _target = target,
       _key = prop,
       _element = target is Element ? target : null {
    final currentValue = readProperty(target, prop.name);

    // `resolve([cfg.to, to, currentValue, cfg.from])`.
    final cfgTo = _cfgTo(cfg);
    final cfgFrom = _cfgFrom(cfg);
    // Upstream assigns the parameter `to` (core.animation.js:31).
    // ignore: parameter_assignments
    to = _firstDefined(cfgTo, to, currentValue, cfgFrom);
    // `resolve([cfg.from, currentValue, to])`.
    final from = _firstDefined(_cfgFrom(cfg), currentValue, to);

    _active = true;
    final fn = _cfgFn(cfg);
    if (jsTruthy(fn)) {
      _fn = (f, t, x) => jsCall(fn, [f, t, x], thisArg: this);
    } else {
      final type = _cfgType(cfg);
      _fn = jsTruthy(type)
          ? _interpolatorNamed(jsToString(type))
          : _interpolatorOf(from);
    }
    // DIVERGES(chartjs): adapt-animation-color-cache, one parse of each color.
    if (identical(_fn, _color)) _fn = _ColorInterpolator().call;
    // `effects` is a mutable object: a user can add or replace an easing.
    _easing = effects[_cfgEasing(cfg)] ?? effects['linear']!;
    _start = (jsDateNow() + jsOrZero(_cfgDelay(cfg))).floorToDouble();
    _duration = _total = jsToNumber(_cfgDuration(cfg)).floorToDouble();
    _loop = jsTruthy(_cfgLoop(cfg));
    _from = from;
    _to = to;
    _promises = null;
    // DIVERGES(chartjs): adapt-animation-number-path, two double fields.
    _retarget();
  }

  /// core.animation.js:27 `class Animation` as a value (Chart.js ADR 0020,
  /// section 3, and Chart.js ADR 0048, section 2).
  ///
  /// It has no statics. Its `construct` gives `Animation(cfg, target, prop,
  /// to)`, with [undefined] for an absent argument. An argument of another
  /// type throws a [TypeError] at the cast. `src/index.umd.ts:32` keeps the
  /// class as `Chart.Animation`.
  static final JsClass jsClass = JsClass(
    'Animation',
    construct: (newTarget, args) {
      Object? argument(int i) => i < args.length ? args[i] : undefined;
      return Animation(
        argument(0)! as AnyObject,
        argument(1)!,
        argument(2)! as String,
        argument(3),
      );
    },
  );

  /// core.animation.js:34 `_active`.
  bool _active = false;

  /// core.animation.js:35 `_fn`, the interpolator. Dart `null` stands for
  /// `undefined`.
  Interpolator? _fn;

  /// core.animation.js:36 `_easing`.
  late double Function(double t) _easing;

  /// core.animation.js:37 `_start`.
  double _start = 0;

  /// core.animation.js:38 `_duration`.
  double _duration = 0;

  /// core.animation.js:38 `_total`.
  double _total = 0;

  /// core.animation.js:39 `_loop`.
  bool _loop = false;

  /// core.animation.js:40 `_target`.
  final Object _target;

  /// core.animation.js:41 `_prop`, as its key (Chart.js ADR 0054 §10).
  final AnimatedProp _key;

  /// core.animation.js:41 `_prop`: the property name.
  String get _prop => _key.name;

  /// core.animation.js:42 `_from`.
  Object? _from;

  /// core.animation.js:43 `_to`.
  Object? _to;

  /// core.animation.js:44 `_promises`. Dart `null` stands for `undefined`.
  List<Completer<void>>? _promises;

  /// Whether [tick] runs on [_fromNumber] and [_toNumber]: the built-in
  /// `number` interpolator with two `double` values (Chart.js ADR 0019,
  /// section 6).
  bool _numberPath = false;

  /// [_from] on the number path.
  double _fromNumber = 0;

  /// [_to] on the number path.
  double _toNumber = 0;

  /// [_target] when it is an [Element], else Dart `null`. The number path
  /// writes it through `Element.writeNumber`, the typed setter of [_key]
  /// (Chart.js ADR 0054 §10). The typed field spares the number path a cast
  /// in each write: 20000 points x 2 tick 0.03 to 0.07 ms faster on AOT and
  /// 0.02 to 0.04 ms on wasm.
  final Element? _element;

  /// core.animation.js:37 `_start`, the start time in milliseconds. The
  /// specs and the animator read it.
  @internal
  double get start => _start;

  /// core.animation.js:38 `_duration`, in milliseconds. The specs and the
  /// animator read it (core.animator.js:170).
  @internal
  double get duration => _duration;

  /// core.animation.js:38 `_total`, the duration since the first start. The
  /// animator reads it (core.animator.js:73).
  @internal
  double get total => _total;

  /// core.animation.js:39 `_loop`. The differential test of the fast paths
  /// reads it (Chart.js ADR 0053).
  @internal
  bool get loop => _loop;

  /// core.animation.js:36 `_easing`, the easing function of `effects`. The
  /// differential test of the fast paths reads it (Chart.js ADR 0053).
  @internal
  double Function(double t) get easing => _easing;

  /// core.animation.js:42 `_from`, the start value.
  @internal
  Object? get from => _from;

  /// core.animation.js:42 `_from`: the specs write it
  /// (core.animation.tests.js:28, :32).
  @internal
  set from(Object? value) {
    _from = value;
    // DIVERGES(chartjs): adapt-animation-number-path, two double fields.
    _retarget();
  }

  /// core.animation.js:43 `_to`, the target value (animation.d.ts:10).
  @internal
  @override
  Object? get to => _to;

  /// core.animation.js:43 `_to`: the specs write it
  /// (core.animation.tests.js:33).
  @internal
  set to(Object? value) {
    _to = value;
    // DIVERGES(chartjs): adapt-animation-number-path, two double fields.
    _retarget();
  }

  /// core.animation.js:47 `active()`.
  @override
  bool active() {
    return _active;
  }

  /// core.animation.js:51 `update(cfg, to, date)`: gives an active animation
  /// the new target value [to] from the time [date].
  void update(AnyObject cfg, Object? to, double date) {
    if (_active) {
      _notify(false);

      final currentValue = readProperty(_target, _prop);
      final elapsed = date - _start;
      final remain = _duration - elapsed;
      _start = date;
      _duration = jsMax(remain, jsToNumber(_cfgDuration(cfg))).floorToDouble();
      _total += elapsed;
      _loop = jsTruthy(_cfgLoop(cfg));
      // `resolve([cfg.to, to, currentValue, cfg.from])` and
      // `resolve([cfg.from, currentValue, to])`.
      final cfgTo = _cfgTo(cfg);
      final cfgFrom = _cfgFrom(cfg);
      _to = _firstDefined(cfgTo, to, currentValue, cfgFrom);
      _from = _firstDefined(_cfgFrom(cfg), currentValue, to);
      // DIVERGES(chartjs): adapt-animation-number-path, two double fields.
      _retarget();
    }
  }

  /// core.animation.js:67 `cancel()`.
  void cancel() {
    if (_active) {
      // update current evaluated value, for smoother animations
      tick(jsDateNow());
      _active = false;
      _notify(false);
    }
  }

  /// core.animation.js:76 `tick(date)`: writes the value of the property at
  /// the time [date].
  ///
  /// An animation on the number path runs the same lines on two `double`
  /// fields (Chart.js ADR 0019, section 6).
  void tick(double date) {
    // DIVERGES(chartjs): adapt-animation-number-path, two double fields.
    if (_numberPath) {
      _tickNumber(date);
      return;
    }
    final elapsed = date - _start;
    final duration = _duration;
    final prop = _prop;
    final from = _from;
    final loop = _loop;
    final to = _to;
    double factor;

    // `from !== to`: the Dart `==` gives the JS result for these values. NaN
    // differs from NaN, 0 equals -0, and Maps compare by identity.
    _active = from != to && (loop || (elapsed < duration));

    if (!_active) {
      writeProperty(_target, prop, to);
      _notify(true);
      return;
    }

    if (elapsed < 0) {
      writeProperty(_target, prop, from);
      return;
    }

    factor = (elapsed / duration).remainder(2);
    factor = loop && factor > 1 ? 2 - factor : factor;
    factor = _easing(jsMin(1, jsMax(0, factor)));

    writeProperty(_target, prop, _fn!(from, to, factor));
  }

  /// core.animation.js:105 `wait()`: a future that completes when the
  /// animation ends, and fails when it is updated or cancelled.
  ///
  /// The future is the future of a `Completer.sync()`. [_notify] settles it
  /// in a promise job (Chart.js ADR 0019, section 7). The error of a failed
  /// future is the [undefined] sentinel, because `rej()` passes no reason.
  Future<void> wait() {
    final promises = _promises ??= [];
    // DIVERGES(chartjs): platform-animation-promise-checkpoint, a sync job.
    final completer = Completer<void>.sync();
    promises.add(completer);
    return completer.future;
  }

  /// core.animation.js:112 `_notify(resolved)`: resolves or rejects each
  /// promise of [wait].
  ///
  /// Each promise gets one job of [jsEnqueuePromiseJob]. The job does
  /// nothing for a completed completer, as a settled promise ignores a later
  /// `res()` or `rej()`. `update` can reject a promise. The end of the
  /// animation then resolves the same list again (core.animation.js:53, :89).
  void _notify(bool resolved) {
    final promises = _promises ?? const <Completer<void>>[];
    for (var i = 0; i < promises.length; i++) {
      final completer = promises[i];
      // DIVERGES(chartjs): platform-animation-promise-checkpoint, a job.
      jsEnqueuePromiseJob(() {
        if (completer.isCompleted) return;
        if (resolved) {
          completer.complete();
        } else {
          completer.completeError(undefined);
        }
      });
    }
  }

  /// Sets [_numberPath] for the current [_fn], [_from] and [_to], and copies
  /// the two values into [_fromNumber] and [_toNumber] on the number path
  /// (Chart.js ADR 0019, section 6). The constructor, [update] and the
  /// setters of [from] and [to] call it. No other code changes these
  /// fields.
  // DIVERGES(chartjs): adapt-animation-number-path, two double fields.
  void _retarget() {
    final from = _from;
    final to = _to;
    if (identical(_fn, _number) && from is double && to is double) {
      _numberPath = true;
      _fromNumber = from;
      _toNumber = to;
    } else {
      _numberPath = false;
    }
  }

  /// core.animation.js:76-102 `tick(date)` on the number path: the upstream
  /// lines on [_fromNumber] and [_toNumber].
  ///
  /// For two `double` values, `from != to` is the JS `!==`, and
  /// `from + (to - from) * factor` is the result of the `number`
  /// interpolator. The write of `x` or `y` of an [Element] calls its setter,
  /// which stores the state of the write by name (Chart.js ADR 0017, section
  /// 5). Every other write calls [writeProperty].
  // DIVERGES(chartjs): adapt-animation-number-path, two double fields.
  void _tickNumber(double date) {
    final elapsed = date - _start;
    final duration = _duration;
    final from = _fromNumber;
    final loop = _loop;
    final to = _toNumber;
    double factor;

    _active = from != to && (loop || (elapsed < duration));

    if (!_active) {
      _writeNumber(to);
      _notify(true);
      return;
    }

    if (elapsed < 0) {
      _writeNumber(from);
      return;
    }

    factor = (elapsed / duration).remainder(2);
    factor = loop && factor > 1 ? 2 - factor : factor;
    factor = _easing(jsMin(1, jsMax(0, factor)));

    _writeNumber(from + (to - from) * factor);
  }

  /// `this._target[prop] = value` on the number path: the typed setter of
  /// an [Element] (`Element.writeNumber`), else the write by name.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:prefer-inline')
  @pragma('wasm:prefer-inline')
  void _writeNumber(double value) {
    final element = _element;
    if (element != null) {
      element.writeNumber(_key, value);
    } else {
      writeProperty(_target, _prop, value);
    }
  }
}

/// `resolve(inputs)` (helpers.options.ts:154) of three or four values with
/// no context and no index: the first value that is not [undefined], else
/// [undefined].
Object? _firstDefined(
  Object? a,
  Object? b,
  Object? c, [
  Object? d = undefined,
]) {
  if (!identical(a, undefined)) return a;
  if (!identical(b, undefined)) return b;
  if (!identical(c, undefined)) return c;
  return d;
}

/// `cfg[name]` of a `cfg` that is not an [AnimationSpec]: the read by name
/// of a plain object, the `cfg` of `new Chart.Animation(cfg, ...)` of user
/// code and of the specs. It gives [undefined] for an absent key.
Object? _cfgRead(AnyObject cfg, String name) => jsGet(cfg, name);

/// `cfg.delay` (core.animation.js:37): the field of an [AnimationSpec], else
/// [_cfgRead]. Both give [undefined] for an absent key.
Object? _cfgDelay(AnyObject cfg) =>
    cfg is AnimationSpec ? cfg.delayValue : _cfgRead(cfg, 'delay');

/// `cfg.duration` (core.animation.js:38, :59).
Object? _cfgDuration(AnyObject cfg) =>
    cfg is AnimationSpec ? cfg.durationValue : _cfgRead(cfg, 'duration');

/// `cfg.easing` (core.animation.js:36).
Object? _cfgEasing(AnyObject cfg) =>
    cfg is AnimationSpec ? cfg.easingValue : _cfgRead(cfg, 'easing');

/// `cfg.fn` (core.animation.js:35).
Object? _cfgFn(AnyObject cfg) =>
    cfg is AnimationSpec ? cfg.fnValue : _cfgRead(cfg, 'fn');

/// `cfg.from` (core.animation.js:31-32, :62-63).
Object? _cfgFrom(AnyObject cfg) =>
    cfg is AnimationSpec ? cfg.fromValue : _cfgRead(cfg, 'from');

/// `cfg.loop` (core.animation.js:39, :61).
Object? _cfgLoop(AnyObject cfg) =>
    cfg is AnimationSpec ? cfg.loopValue : _cfgRead(cfg, 'loop');

/// `cfg.to` (core.animation.js:31, :62).
Object? _cfgTo(AnyObject cfg) =>
    cfg is AnimationSpec ? cfg.toValue : _cfgRead(cfg, 'to');

/// `cfg.type` (core.animation.js:35).
Object? _cfgType(AnyObject cfg) =>
    cfg is AnimationSpec ? cfg.typeValue : _cfgRead(cfg, 'type');

/// The JS property read `target[prop]` of an animation target (Chart.js ADR
/// 0019, section 2).
///
/// A `types.PropertyAccess`, for example an `Element`, gives its
/// `operator []`. A Map gives `jsGet(target, prop)`. Thus an absent key gives
/// [undefined]. Another target throws an [ArgumentError]: upstream declares
/// `target: AnyObject` (animation.d.ts:5). `core.animation.js` and
/// `core.animations.js` read their targets through this function.
@internal
Object? readProperty(Object target, String prop) => switch (target) {
  final types.PropertyAccess access => access[prop],
  // `<dynamic, dynamic>` matches every Map, as in `jsGet`.
  final Map<dynamic, dynamic> map => jsGet(map, prop),
  _ => throw ArgumentError.value(target, 'target', 'is not an object'),
};

/// The JS property write `target[prop] = value` of an animation target
/// (Chart.js ADR 0019, section 2).
///
/// A `types.PropertyAccess`, for example an `Element`, uses its
/// `operator []=`. A Map stores [value] under [prop]. Another target throws
/// an [ArgumentError]. `core.animation.js` and `core.animations.js` write
/// their targets through this function.
@internal
void writeProperty(Object target, String prop, Object? value) {
  switch (target) {
    case final types.PropertyAccess access:
      access[prop] = value;
    case final Map<dynamic, dynamic> map:
      map[prop] = value;
    default:
      throw ArgumentError.value(target, 'target', 'is not an object');
  }
}
