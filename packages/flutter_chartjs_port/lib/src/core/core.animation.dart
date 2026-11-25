// Ported from Chart.js v4.6.1 src/core/core.animation.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-elements, typed keys of Chart.js ADR 0054.
// DIVERGES(chartjs): adapt-direct-colors, preserve the color animation cache.

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
/// and 6, with Chart.js ADR 0054 §10; the last one is of Chart.js ADR
/// 0149):
/// - An animation with the built-in `number` interpolator and two `double`
///   values ticks on two `double` fields (`adapt-animation-number-path`).
///   It writes an `Element` through `Element.writeNumber`, the typed setter
///   of the property.
/// - The constructor resolves the interpolator one time, with no list and
///   no lookup by name. A user `fn` is an [Interpolator], called directly
///   (Chart.js ADR 0130).
/// - While `Animator.update` runs, the ticks with the same `Cubic` object
///   and the same factor share one curve call (Chart.js ADR 0149,
///   `adapt-animation-ease-table`, `animation_ease.dart`).
///
/// The end of an animation calls the functions of [Animation.onSettle] in a
/// frame job: [Animation.runFrame] runs the jobs at the end of the animator
/// frame callback, as a browser runs the promise jobs after each
/// `requestAnimationFrame` callback (`platform-animation-promise-checkpoint`,
/// Chart.js ADR 0172).
///
/// `Animation` is also a class of `package:flutter/animation.dart`. A file
/// that needs both classes imports one library with a prefix.
///
/// This library is a pure layer (Chart.js ADR 0019, section 1). It imports
/// neither `dart:ui` nor `package:flutter`.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/animation.dart' show Curve, Curves;
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:flutter_kurkle_color_port/flutter_kurkle_color_port.dart'
    hide color;

/// core.animation.js:5 `transparent`.
const ui.Color _transparent = ui.Color.fromRGBO(0, 0, 0, 0);

/// core.animation.js:6-25 the type of a member of `interpolators`: the value
/// at [factor] between [from] and [to]. The animation option `fn`
/// (index.d.ts:1775) holds a function of this type (Chart.js ADR 0130).
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
/// `helpers.color` returns a `ChartGradient` or a `ChartPattern`
/// unchanged. Such an object has no `valid` property in JavaScript. A
/// Flutter color is always valid (Chart.js ADR 0171). Thus `c0.valid` is
/// `c0 is ui.Color`.
Object? _color(Object? from, Object? to, double factor) {
  final c0 = color(jsTruthy(from) ? from : _transparent);
  final c1 = c0 is ui.Color ? color(jsTruthy(to) ? to : _transparent) : false;
  return c1 is ui.Color ? ChartPaint.solid(c1.mix(c0 as ui.Color, factor)) : to;
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

/// core.animation.js:35 `interpolators[cfg.type || typeof from]`: `typeof`
/// gives `'number'` for a number and `'boolean'` for a boolean. No
/// other `typeof` names an interpolator.
///
/// A color of the port is a `dart:ui` `Color`, not a String. Thus the value
/// also names the color interpolator. The port has no option `type`: the
/// Dart type of the value selects each built-in interpolator (row
/// `adapt-animation-option-types`).
Interpolator? _interpolatorOf(Object? from) => switch (from) {
  num() => _number,
  bool() => _boolean,
  // DIVERGES(chartjs): adapt-color-animation-by-value, a native color. A
  // gradient or a pattern also takes the color interpolator, as the
  // `type: 'color'` of the upstream colors defaults: `_color` gives `to`.
  ChartPaint() => _color,
  _ => null,
};

/// core.animation.js:27 `Animation`, the animation of the property [_key]
/// of the target [_target].
class Animation.typed(
  AnimationSpec cfg,

  /// core.animation.js:40 `_target`.
  final Object _target,
  AnimatedProp prop, [
  // The setter `to` stores a resolved value: no field to declare.
  // ignore: use_declaring_parameters
  Object? to = undefined,
  PropertyAnimation? item,
]) implements IAnimation {
  /// core.animation.js:28 `constructor(cfg, target, prop, to)`.
  ///
  /// [cfg] is the animation configuration, an [AnimationSpec]. [to] is the
  /// [undefined] sentinel when the caller passes no target value. [prop] is
  /// the property name: [Animation.typed] with its [AnimatedProp].
  new(AnimationSpec cfg, Object target, String prop, [Object? to = undefined])
    : this.typed(cfg, target, AnimatedProp.of(prop), to);

  /// core.animation.js:28 `constructor(cfg, target, prop, to)` for the key
  /// [prop] of the typed table of `Animations` (Chart.js ADR 0054 §10).
  ///
  /// The constructor resolves the interpolator one time (Chart.js ADR 0019,
  /// section 5). An [Interpolator] in `cfg.fn` is the interpolator, with no
  /// `this` (Chart.js ADR 0130). Else the interpolator of the Dart type of
  /// `from` is the built-in function, or Dart `null`
  /// where upstream gives `undefined`. Then the first interpolation throws a
  /// [TypeError], as in JavaScript. `resolve([...])` of upstream is the
  /// first value that is not [undefined], with no list (helpers.options.ts:
  /// 154 without a context and an index).
  ///
  /// [item] is the item of `ChartConfig.animations` for [prop], or Dart
  /// `null`. A parameter of the item that is not `null` goes before the
  /// value of [cfg]. The animation reads the item itself: no object holds a
  /// copy of its parameters.
  this {
    final currentValue = prop.valueOf(_target);

    // `resolve([cfg.to, to, currentValue, cfg.from])`.
    final cfgTo = cfg.to ?? undefined;
    final cfgFrom = cfg.from ?? undefined;
    // Upstream assigns the parameter `to` (core.animation.js:31).
    // ignore: parameter_assignments
    to = _firstDefined(cfgTo, to, currentValue, cfgFrom);
    // `resolve([cfg.from, currentValue, to])`.
    final from = _firstDefined(cfgFrom, currentValue, to);

    _active = true;
    // DIVERGES(chartjs): adapt-native-callbacks, the typed function.
    // DIVERGES(chartjs): adapt-animation-option-types, no `type`.
    _fn = cfg.fn ?? _interpolatorOf(from);
    // DIVERGES(chartjs): adapt-flutter-curves, the curve of the config.
    // DIVERGES(chartjs): adapt-property-animations, the item of the app.
    _easing = item?.easing ?? cfg.easing ?? Curves.linear;
    // DIVERGES(chartjs): adapt-animation-option-types, a Duration.
    _start =
        (clock.now().millisecondsSinceEpoch +
                (_milliseconds(item?.delay) ?? cfg.delay ?? 0))
            .floorToDouble();
    _duration = _total = _durationOf(item, cfg);
    _loop = item?.loop ?? cfg.loop ?? false;
    _from = from;
    _to = to;
    _promises = null;
    // DIVERGES(chartjs): adapt-animation-number-path, two double fields.
    _retarget();
  }

  /// core.animation.js:34 `_active`.
  bool _active = false;

  /// core.animation.js:35 `_fn`, the interpolator. Dart `null` stands for
  /// `undefined`.
  Interpolator? _fn;

  /// core.animation.js:36 `_easing`: the Flutter curve of `cfg.easing`.
  late Curve _easing;

  /// core.animation.js:37 `_start`.
  double _start = 0;

  /// core.animation.js:38 `_duration`.
  double _duration = 0;

  /// core.animation.js:38 `_total`.
  double _total = 0;

  /// core.animation.js:39 `_loop`.
  bool _loop = false;

  /// core.animation.js:41 `_prop`, as its key (Chart.js ADR 0054 §10): the
  /// property reads and writes the target (`AnimatedProp.valueOf`,
  /// `AnimatedProp.store`). The animation has no name of the property.
  final AnimatedProp _key = prop;

  /// core.animation.js:42 `_from`.
  Object? _from;

  /// core.animation.js:43 `_to`.
  Object? _to;

  /// core.animation.js:44 `_promises`: the functions of [onSettle] that
  /// [_notify] did not call yet. Dart `null` stands for `undefined`.
  List<void Function(bool resolved)>? _promises;

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
  final Element? _element = _target is Element ? _target : null;

  /// core.animation.js:37 `_start`, the start time in milliseconds. The
  /// specs and the animator read it.
  double get start => _start;

  /// core.animation.js:38 `_duration`, in milliseconds. The specs and the
  /// animator read it (core.animator.js:170).
  double get duration => _duration;

  /// core.animation.js:38 `_total`, the duration since the first start. The
  /// animator reads it (core.animator.js:73).
  double get total => _total;

  /// core.animation.js:39 `_loop`. The differential test of the fast paths
  /// reads it (Chart.js ADR 0053).
  bool get loop => _loop;

  /// core.animation.js:36 `_easing`, the curve of the animation. The
  /// differential test of the fast paths reads it (Chart.js ADR 0053).
  Curve get easing => _easing;

  /// `this._easing(factor)` (core.animation.js:84): the curve at [factor].
  ///
  /// [factor] is in the range 0 to 1, or NaN for a loop with the duration
  /// 0. `Curve.transform` takes only the range, so NaN stays NaN, as each
  /// formula of `helpers.easing.ts` gives.
  ///
  /// While `Animator.update` runs, the ticks with the same curve object and
  /// the same factor share one curve call: [easeTableAt] gives the result of
  /// `Curve.transform`, bit for bit, and only for a `Cubic`.
  double _ease(double factor) => factor >= 0
      // DIVERGES(chartjs): adapt-animation-ease-table, one solve for an input.
      ? (easeTableActive
            ? easeTableAt(_easing, factor)
            : _easing.transform(factor))
      : factor;

  /// core.animation.js:42 `_from`, the start value.
  Object? get from => _from;

  /// core.animation.js:42 `_from`: the specs write it
  /// (core.animation.tests.js:28, :32).
  set from(Object? value) {
    _from = value;
    // DIVERGES(chartjs): adapt-animation-number-path, two double fields.
    _retarget();
  }

  /// core.animation.js:43 `_to`, the target value (animation.d.ts:10).
  @override
  Object? get to => _to;

  /// core.animation.js:43 `_to`: the specs write it
  /// (core.animation.tests.js:33).
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
  ///
  /// [item] is the item of `ChartConfig.animations` for the property, as in
  /// [Animation.typed].
  void update(
    AnimationSpec cfg,
    Object? to,
    double date, [
    PropertyAnimation? item,
  ]) {
    if (_active) {
      _notify(false);

      final currentValue = _key.valueOf(_target);
      final elapsed = date - _start;
      final remain = _duration - elapsed;
      _start = date;
      // DIVERGES(chartjs): adapt-property-animations, the item of the app.
      _duration = math.max(remain, _durationOf(item, cfg)).floorToDouble();
      _total += elapsed;
      _loop = item?.loop ?? cfg.loop ?? false;
      // `resolve([cfg.to, to, currentValue, cfg.from])` and
      // `resolve([cfg.from, currentValue, to])`.
      final cfgFrom = cfg.from ?? undefined;
      _to = _firstDefined(cfg.to ?? undefined, to, currentValue, cfgFrom);
      _from = _firstDefined(cfgFrom, currentValue, to);
      // DIVERGES(chartjs): adapt-animation-number-path, two double fields.
      _retarget();
    }
  }

  /// core.animation.js:67 `cancel()`.
  void cancel() {
    if (_active) {
      // DIVERGES(chartjs): adapt-shared-bar-animations, the tick runs app code.
      optionCallEpoch++;
      // update current evaluated value, for smoother animations
      tick(clock.now().millisecondsSinceEpoch.toDouble());
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
    final from = _from;
    final loop = _loop;
    final to = _to;
    double factor;

    // `from !== to`: the Dart `==` gives the JS result for these values. NaN
    // differs from NaN, 0 equals -0, and Maps compare by identity.
    _active = from != to && (loop || (elapsed < duration));

    if (!_active) {
      _key.store(_target, to);
      _notify(true);
      return;
    }

    if (elapsed < 0) {
      _key.store(_target, from);
      return;
    }

    factor = (elapsed / duration).remainder(2);
    factor = loop && factor > 1 ? 2 - factor : factor;
    factor = _ease(math.min(1, math.max(0, factor)));

    _key.store(_target, _fn!(from, to, factor));
  }

  /// core.animation.js:105 `wait()`: a future that completes when the
  /// animation ends, and fails when it is updated or cancelled.
  ///
  /// The error of a failed future is the [undefined] sentinel, because
  /// `rej()` passes no reason. The port itself does not call it: it uses
  /// [onSettle].
  Future<void> wait() {
    final completer = Completer<void>();
    onSettle((resolved) {
      if (resolved) {
        completer.complete();
      } else {
        completer.completeError(undefined);
      }
    });
    return completer.future;
  }

  /// The native form of [wait]: [listener] gets `true` when the animation
  /// ends, or `false` when it is updated or cancelled. It gets one call, in
  /// a frame job (Chart.js ADR 0172).
  // DIVERGES(chartjs): platform-animation-promise-checkpoint, a function.
  void onSettle(void Function(bool resolved) listener) {
    (_promises ??= []).add(listener);
  }

  /// core.animation.js:112 `_notify(resolved)`: resolves or rejects each
  /// promise of [wait].
  ///
  /// Each function of [onSettle] gets one frame job, as each promise
  /// reaction is one job. A settled promise ignores a later `res()` or
  /// `rej()`. Thus [_notify] removes the functions that it calls: `update`
  /// can reject them, and the end of the animation then resolves only the
  /// functions of later [onSettle] calls (core.animation.js:53, :89).
  void _notify(bool resolved) {
    final promises = _promises;
    if (promises == null) return;
    _promises = null;
    for (var i = 0; i < promises.length; i++) {
      final listener = promises[i];
      // DIVERGES(chartjs): platform-animation-promise-checkpoint, a job.
      _queueFrameJob(() => listener(resolved));
    }
  }

  /// `Promise.all(running).then(onEnd, () => {})` of `awaitAll` and
  /// `_animateOptions` (core.animations.js:51-55, :144): calls [onEnd] when
  /// each animation of [running] ends, and never when one of them is
  /// updated or cancelled.
  ///
  /// [onEnd] runs in the frame job after the job of the last end, as the
  /// `.then` of `Promise.all` runs one job after the reaction of its last
  /// item. For an empty [running], it runs in the next job, as
  /// `Promise.all([])` is already settled. Two chains on one target read
  /// that order (Chart.js ADR 0172).
  // DIVERGES(chartjs): platform-animation-promise-checkpoint, no promise.
  static void whenAllEnd(List<Animation> running, void Function() onEnd) {
    if (running.isEmpty) {
      _queueFrameJob(onEnd);
      return;
    }
    var pending = running.length;
    var failed = false;
    for (var i = 0; i < running.length; i++) {
      running[i].onSettle((resolved) {
        if (failed) return;
        if (!resolved) {
          failed = true;
        } else if (--pending == 0) {
          _queueFrameJob(onEnd);
        }
      });
    }
  }

  /// Runs [callback], then the frame jobs that [callback] and these jobs
  /// queue, in their order, until no job is left: the microtask checkpoint
  /// that a browser runs after each `requestAnimationFrame` callback.
  ///
  /// Flutter runs the microtasks of a frame after all its frame callbacks
  /// (Chart.js ADR 0016). Without this step, the shared options of a
  /// `_animateOptions` chain would reach the element after a re-hover of the
  /// same frame.
  ///
  /// - A nested call runs its [callback] in the outer frame. Its jobs run at
  ///   the end of the outer frame.
  /// - The jobs also run when [callback] throws. Then the error of
  ///   [callback] continues after the jobs.
  /// - A job that throws does not stop the others. Its error goes to the
  ///   uncaught-error handler of the current zone.
  // DIVERGES(chartjs): platform-animation-promise-checkpoint, the frame jobs.
  static void runFrame(void Function() callback) {
    if (_frameJobs != null) {
      callback();
      return;
    }
    final jobs = _frameJobs = <void Function()>[];
    try {
      callback();
    } finally {
      try {
        // A job can queue more jobs: the length grows during the loop.
        for (var i = 0; i < jobs.length; i++) {
          try {
            jobs[i]();
            // A job error goes to the zone, and the next job runs.
            // ignore: avoid_catches_without_on_clauses
          } catch (error, stackTrace) {
            Zone.current.handleUncaughtError(error, stackTrace);
          }
        }
      } finally {
        _frameJobs = null;
      }
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
    factor = _ease(math.min(1, math.max(0, factor)));

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
      _key.store(_target, value);
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

/// The duration of an animation in milliseconds, floored: the duration of
/// [item], else `cfg.duration` (core.animation.js:38, :59). An absent
/// duration gives NaN, the `+undefined` of upstream.
// DIVERGES(chartjs): adapt-animation-option-types, typed milliseconds.
double _durationOf(PropertyAnimation? item, AnimationSpec cfg) =>
    (_milliseconds(item?.duration) ?? cfg.duration ?? double.nan)
        .floorToDouble();

/// Whether an animation with the options [cfg] has a duration:
/// `cfg.duration` is truthy (core.animations.js:99).
bool animationHasDuration(AnimationSpec cfg) {
  final duration = cfg.duration;
  return duration != null && duration != 0 && !duration.isNaN;
}

/// [duration] in milliseconds, the unit of the animation clock, or Dart
/// `null`.
double? _milliseconds(Duration? duration) =>
    duration == null ? null : duration.inMicroseconds / 1000;

/// The JS property read `target[prop]` of an animation target (Chart.js ADR
/// 0019, section 2).
///
/// A `types.PropertyAccess`, for example an `Element`, gives its
/// `operator []`. A typed object gives its face (Chart.js ADR 0054 §5), and a
/// Map gives `jsGet(target, prop)`. Thus an absent key gives
/// [undefined]. Another target throws an [ArgumentError]: upstream declares
/// `target: AnyObject` (animation.d.ts:5). `core.animation.js` and
/// `core.animations.js` read their targets through this function.
Object? readProperty(Object target, String prop) => switch (target) {
  final PropertyAccess access => access[prop],
  final ChartMeta meta => _metaRead(meta, prop),
  final JsObjectFace face => face.jsRead(prop),
  // `<dynamic, dynamic>` matches every Map, as in `jsGet`.
  final Map<dynamic, dynamic> map => jsGet(map, prop),
  _ => throw ArgumentError.value(target, 'target', 'is not an object'),
};

/// The read `meta[prop]` of the `visible` animation of a dataset
/// (core.controller.js:903): the typed fields of the meta. Another name gives
/// [undefined], as the meta has no such property (row
/// `adapt-native-chart-meta`).
Object? _metaRead(ChartMeta meta, String prop) => switch (prop) {
  'visible' => meta.visible,
  r'$animations' => meta.animations ?? undefined,
  _ => undefined,
};

/// The write `meta[prop] = value` of the `visible` animation of a dataset.
/// [ChartMeta.visible] takes the ToBoolean of the value: the `hide`
/// animation writes `v | 0` (core.animations.defaults.js:67), and each
/// reader applies ToBoolean. Another name throws an [ArgumentError]: the
/// meta has only the typed fields.
void _metaWrite(ChartMeta meta, String prop, Object? value) {
  switch (prop) {
    case 'visible':
      meta.visible = jsTruthy(value);
    case r'$animations':
      meta.animations = value as Map<String, Object?>?;
    default:
      throw ArgumentError.value(prop, 'prop', 'is not a property of the meta');
  }
}

/// The JS property write `target[prop] = value` of an animation target
/// (Chart.js ADR 0019, section 2).
///
/// A `types.PropertyAccess`, for example an `Element`, uses its
/// `operator []=`. A typed object writes through its face, and a Map stores
/// [value] under [prop]. Another target throws
/// an [ArgumentError]. `core.animation.js` and `core.animations.js` write
/// their targets through this function.
void writeProperty(Object target, String prop, Object? value) {
  switch (target) {
    case final PropertyAccess access:
      access[prop] = value;
    case final ChartMeta meta:
      _metaWrite(meta, prop, value);
    case final JsObjectFace face:
      face.jsWrite(prop, value);
    case final Map<dynamic, dynamic> map:
      map[prop] = value;
    default:
      throw ArgumentError.value(target, 'target', 'is not an object');
  }
}

/// The jobs of the running [Animation.runFrame], or Dart `null` outside a
/// frame.
List<void Function()>? _frameJobs;

/// Queues [job] for the running [Animation.runFrame]. Outside a frame, [job]
/// runs as a Dart microtask, after the synchronous code.
void _queueFrameJob(void Function() job) {
  final jobs = _frameJobs;
  if (jobs != null) {
    jobs.add(job);
  } else {
    scheduleMicrotask(job);
  }
}
