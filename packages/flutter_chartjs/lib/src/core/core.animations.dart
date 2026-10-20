// Ported from Chart.js v4.5.1 src/core/core.animations.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.animations.js` (Chart.js ADR 0019).
///
/// [Animations] makes the animations of one update of a target: an element,
/// an options object or the dataset meta. A target is a Map or a
/// `types.PropertyAccess`. The ported lines read and write it by name with
/// [readProperty] and [writeProperty] (Chart.js ADR 0019, section 2).
///
/// - `configure` makes an [AnimationSpec] for each config entry, where
///   upstream makes a plain object (`adapt-animation-spec`).
/// - `_resolveTargetOptions` copies shared options with `copyOptions`. The
///   copy keeps the class of the options (`adapt-typed-element-options`,
///   Chart.js ADR 0021, section 3).
/// - `Promise.all` is [jsPromiseAll], and `.then(f, r)` is
///   `.then(f, onError: r)`.
///
/// This file imports `core.animator.dart`. Thus it is not a pure layer.
library;

import 'dart:async';

import 'package:flutter_chartjs/src/core/animation_spec.dart';
import 'package:flutter_chartjs/src/core/core.animation.dart';
import 'package:flutter_chartjs/src/core/core.animator.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart'
    show copyOptions;
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show isArray, isObject;
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_date.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_promise.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// core.animations.js:6 `Animations`.
class Animations {
  /// core.animations.js:7 `constructor(chart, config)`.
  Animations(types.Chart chart, Object? config) : _chart = chart {
    configure(config);
  }

  /// core.animations.js:8 `_chart`.
  final types.Chart _chart;

  /// core.animations.js:9 `_properties`, a JS `Map` from each property name
  /// to its animation options. A JS `Map` takes a key of any type, so the
  /// keys are `Object?`. The specs read it (core.animations.tests.js:13).
  @internal
  final Map<Object?, AnimationSpec> properties = <Object?, AnimationSpec>{};

  /// core.animations.js:13 `configure(config)`.
  ///
  /// `Object.keys(defaults.animation)` gives the keys of a Map, and no key
  /// for `false` or another primitive. It throws a [TypeError] for Dart
  /// `null` and `undefined`, as in JavaScript.
  /// `Object.getOwnPropertyNames(config)` is [jsOwnPropertyNames]: for a
  /// resolver, the keys of all its scopes (Chart.js ADR 0019, section 3).
  void configure(Object? config) {
    if (!isObject(config)) {
      return;
    }
    final configObject = config! as AnyObject;

    final animationOptions = _objectKeys(defaults['animation']);
    final animatedProps = properties;

    for (final key in jsOwnPropertyNames(configObject)) {
      final cfg = configObject[key];
      if (!isObject(cfg)) {
        continue;
      }
      final cfgObject = cfg! as AnyObject;
      // DIVERGES(chartjs): adapt-animation-spec, a typed copy of the options.
      final resolved = AnimationSpec();
      for (final option in animationOptions) {
        resolved[option] = jsGet(cfgObject, option);
      }

      final cfgProperties = jsGet(cfgObject, 'properties');
      // An empty array is truthy: `isArray(p) && p || [key]` gives it.
      final props = isArray(cfgProperties)
          ? cfgProperties! as List<Object?>
          : <Object?>[key];
      for (final prop in props) {
        if (prop == key || !animatedProps.containsKey(prop)) {
          animatedProps[prop] = resolved;
        }
      }
    }
  }

  /// core.animations.js:43 `_animateOptions(target, values)`: Utility to
  /// handle animation of `options`.
  List<Animation> _animateOptions(Object target, AnyObject values) {
    final newOptions = values['options'];
    final options = _resolveTargetOptions(target, newOptions);
    if (options == null) {
      return [];
    }

    final newOptionsObject = newOptions! as AnyObject;
    final animations = _createAnimations(options, newOptionsObject);
    if (jsTruthy(jsGet(newOptionsObject, r'$shared'))) {
      // Going to shared options:
      // After all animations are done, assign the shared options object to
      // the element
      // So any new updates to the shared options are observed
      unawaited(
        _awaitAll(
          jsGet(readProperty(target, 'options'), r'$animations'),
          newOptionsObject,
        ).then(
          (_) {
            writeProperty(target, 'options', newOptions);
          },
          onError: (Object _) {
            // rejected, noop
          },
        ),
      );
    }

    return animations;
  }

  /// core.animations.js:68 `_createAnimations(target, values)`.
  ///
  /// It walks the keys of [values] from the last to the first. The running
  /// animations of [target] are a Map in `target.$animations`. A new Map is
  /// `<String, Animation>{}` (Chart.js ADR 0019, section 2).
  List<Animation> _createAnimations(Object target, AnyObject values) {
    final animatedProps = properties;
    final animations = <Animation>[];
    var running = readProperty(target, r'$animations');
    if (!jsTruthy(running)) {
      writeProperty(target, r'$animations', running = <String, Animation>{});
    }
    final runningObject = running! as Map<String, Object?>;
    final props = jsObjectKeys(values);
    final date = jsDateNow();
    int i;

    for (i = props.length - 1; i >= 0; --i) {
      final prop = props[i];
      if (prop.startsWith(r'$')) {
        continue;
      }

      if (prop == 'options') {
        animations.addAll(_animateOptions(target, values));
        continue;
      }
      final value = values[prop];
      var animation = runningObject[prop] as Animation?;
      final cfg = animatedProps[prop];

      if (animation != null) {
        if (cfg != null && animation.active()) {
          // There is an existing active animation, let's update that
          animation.update(cfg, value, date);
          continue;
        } else {
          animation.cancel();
        }
      }
      if (cfg == null || !jsTruthy(cfg.durationValue)) {
        // not animated, set directly to new value
        writeProperty(target, prop, value);
        continue;
      }

      runningObject[prop] = animation = Animation(cfg, target, prop, value);
      animations.add(animation);
    }
    return animations;
  }

  /// core.animations.js:118 `update(target, values)`: Update `target`
  /// properties to new values, using configured animations
  ///
  /// @param {object} target - object to update
  /// @param {object} values - new target properties
  /// @returns {boolean|undefined} - `true` if animations were started
  ///
  /// Dart `null` stands for the `undefined` result. `Object.assign(target,
  /// values)` writes each key of `Object.keys(values)` through
  /// [writeProperty], in that order.
  bool? update(Object target, AnyObject values) {
    if (properties.isEmpty) {
      // Nothing is animated, just apply the new values.
      for (final key in jsObjectKeys(values)) {
        writeProperty(target, key, values[key]);
      }
      return null;
    }

    final animations = _createAnimations(target, values);

    if (animations.isNotEmpty) {
      animator.add(_chart, animations);
      return true;
    }
    return null;
  }
}

/// core.animations.js:134 `awaitAll(animations, properties)`: a future of
/// the end of each active animation of [animations] under a key of
/// [properties].
///
/// `animations[key]` is `jsGet`. Thus `undefined` animations throw a
/// [TypeError], as in JavaScript. `Promise.all` is [jsPromiseAll].
Future<List<void>> _awaitAll(Object? animations, AnyObject properties) {
  final running = <Future<void>>[];
  final keys = jsObjectKeys(properties);
  for (var i = 0; i < keys.length; i++) {
    final anim = jsGet(animations, keys[i]);
    if (jsTruthy(anim) && (anim! as Animation).active()) {
      running.add((anim as Animation).wait());
    }
  }
  return jsPromiseAll(running);
}

/// core.animations.js:147 `resolveTargetOptions(target, newOptions)`: the
/// options object of [target] that the animations of [newOptions] change.
///
/// Dart `null` stands for the `undefined` result. Shared options get a copy
/// with `$shared: false` and a new `$animations` Map. The copy keeps the
/// class of the options ([copyOptions], Chart.js ADR 0021, section 3).
AnyObject? _resolveTargetOptions(Object target, Object? newOptions) {
  if (!jsTruthy(newOptions)) {
    return null;
  }
  var options = readProperty(target, 'options');
  if (!jsTruthy(options)) {
    writeProperty(target, 'options', newOptions);
    return null;
  }
  if (jsTruthy(jsGet(options, r'$shared'))) {
    // Going from shared options to distinct one:
    // Create new options object containing the old shared values and start
    // updating that.
    // DIVERGES(chartjs): adapt-typed-element-options, the copy keeps the class.
    options = copyOptions(options! as AnyObject)
      ..[r'$shared'] = false
      ..[r'$animations'] = <String, Animation>{};
    writeProperty(target, 'options', options);
  }
  return options! as AnyObject;
}

/// `Object.keys(value)` for `defaults.animation` (core.animations.js:18): a
/// Map gives [jsObjectKeys], a List or a String gives its indices, and
/// another value gives no key. Throws a [TypeError] for Dart `null` and
/// [undefined], as JavaScript does.
List<String> _objectKeys(Object? value) {
  switch (value) {
    case null || Undefined():
      // A JavaScript TypeError: Object.keys of null or undefined.
      throw TypeError();
    case final AnyObject object:
      return jsObjectKeys(object);
    case final List<Object?> list:
      return [for (var i = 0; i < list.length; i++) jsNumberToString(i)];
    case final String string:
      return [for (var i = 0; i < string.length; i++) jsNumberToString(i)];
  }
  return const [];
}
