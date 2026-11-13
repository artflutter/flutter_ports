// Ported from Chart.js v4.6.1 src/core/core.animations.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-elements, typed keys of Chart.js ADR 0054.

/// Port of `src/core/core.animations.js` (Chart.js ADR 0019, with the typed
/// keys of Chart.js ADR 0054 §10).
///
/// [Animations] makes the animations of one update of a target: an element,
/// an options object or the dataset meta. A target is a Map or a
/// `types.PropertyAccess`. The ported lines read and write it by name with
/// [readProperty] and [writeProperty] (Chart.js ADR 0019, section 2).
///
/// - `configure` makes an [AnimationSpec] for each config entry, where
///   upstream makes a plain object (`adapt-animation-spec`). It reads each
///   option of a resolver with its [OptionKey] (`OptionView.readKey`).
/// - `_properties`, the JS `Map` from a property to its animation options,
///   is one Map by the [AnimatedProp] of a name, with
///   the other keys and the key order of the JS `Map` (Chart.js ADR 0054
///   §10). [Animations.properties] gives it as a Map for the specs.
/// - `_createAnimations` walks a property object of a controller (a
///   [TypedRecord] of `lib/src/options/props.dart`) by its typed keys, and
///   writes an element of the built-in class of the object through
///   `Element.writePropertyAt` (Chart.js ADR 0054 §9). Another object goes
///   by name, in the `Object.keys` order.
/// - `_resolveTargetOptions` copies shared options with `copyOptions`. The
///   copy keeps the class of the options (`adapt-typed-element-options`,
///   Chart.js ADR 0021, section 3).
/// - `Promise.all` is [jsPromiseAll], and `.then(f, r)` is
///   `.then(f, onError: r)`.
///
/// This file imports `core.animator.dart`. Thus it is not a pure layer.
library;

import 'dart:async';

import 'package:flutter_chartjs_port/src/core/animation_spec.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart' show Element;
import 'package:flutter_chartjs_port/src/core/reduced_motion.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show ElementOptions, copyOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isArray, isObject;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_date.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_promise.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/animated_prop.dart';
import 'package:flutter_chartjs_port/src/options/option_scope.dart'
    show OptionKey, OptionScope;
import 'package:flutter_chartjs_port/src/options/property_animation.dart'
    show PropertyAnimation;
import 'package:flutter_chartjs_port/src/options/props.dart'
    show ArcProperties, BarProperties, LineProperties, PointProperties;
import 'package:flutter_chartjs_port/src/options/typed_record.dart'
    show TypedRecord;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// core.animations.js:6 `Animations`.
class Animations(
  /// core.animations.js:8 `_chart`.
  final types.Chart _chart,
  Object? config, {
  List<PropertyAnimation>? items,
  List<PropertyAnimation>? modeItems,
  Object? base,
}) {
  /// core.animations.js:7 `constructor(chart, config)`.
  ///
  /// [items] are the items of `ChartConfig.animations` of the chart, or Dart
  /// `null`. [modeItems] are the items of the transition of the update mode
  /// (`ChartTransition.animations`): they go before [items]. [base] is the
  /// `animation` options of the resolver of [config]: the options of a
  /// property that has an item and no options of its own.
  // DIVERGES(chartjs): adapt-property-animations, the items of the app.
  this {
    configure(config);
    if (modeItems != null && modeItems.isNotEmpty) _modeItems = modeItems;
    if (items != null && items.isNotEmpty) _chartItems = items;
    if (_modeItems != null || _chartItems != null) _addBaseOptions(base);
  }

  /// core.animations.js:6 `class Animations` as a value (Chart.js ADR 0020,
  /// section 3, and Chart.js ADR 0048, section 2).
  ///
  /// It has no statics. Its `construct` gives `Animations(chart, config)`,
  /// with [undefined] for an absent argument. A chart that is not a
  /// `types.Chart` throws a [TypeError] at the cast. `src/index.umd.ts:33`
  /// keeps the class as `Chart.Animations`.
  static final JsClass jsClass = JsClass(
    'Animations',
    construct: (newTarget, args) => Animations(
      (args.isNotEmpty ? args[0] : undefined)! as types.Chart,
      args.length > 1 ? args[1] : undefined,
    ),
  );

  /// core.animations.js:9 `_properties`, a JS `Map` from each property to
  /// its animation options, in the insertion order. The key of a name is
  /// its [AnimatedProp]: the object of a built-in property, or a property
  /// with that name. A JS `Map` takes a key of any type: a key that is not
  /// a `String` is the key itself.
  final Map<Object?, AnimationSpec> _properties = <Object?, AnimationSpec>{};

  /// core.animations.js:9 `_properties`, a JS `Map` from each property to
  /// its animation options, as a new Map in the key order of the JS `Map`.
  /// The specs read it (core.animations.tests.js:13).
  @internal
  Map<Object?, AnimationSpec> get properties => {
    for (final MapEntry(:key, :value) in _properties.entries)
      key is AnimatedProp ? key.name : key: value,
  };

  /// The items of the transition of the update mode
  /// (`ChartTransition.animations`), or Dart `null`.
  List<PropertyAnimation>? _modeItems;

  /// The items of `ChartConfig.animations`, or Dart `null`.
  List<PropertyAnimation>? _chartItems;

  /// The item of the app for the property [prop], or Dart `null`: the object
  /// that the app made. The type of an item selects its property
  /// ([AnimatedProp.itemIn]). An item of the update mode goes before an item
  /// of the chart.
  @internal
  PropertyAnimation? itemOf(AnimatedProp prop) =>
      prop.itemIn(_modeItems) ?? prop.itemIn(_chartItems);

  /// Gives the options of [base], the `animation` options, to each property
  /// that has an item and no options of its own: upstream gives them to an
  /// entry of `animations` through `_fallback`.
  void _addBaseOptions(Object? base) {
    assert(
      _oneItemForEachClass(_modeItems),
      'ChartTransition.animations has two items of one class. Give one item '
      'for each class.',
    );
    assert(
      _oneItemForEachClass(_chartItems),
      'ChartConfig.animations has two items of one class. Give one item for '
      'each class.',
    );
    AnimationSpec? baseSpec;
    for (final prop in AnimatedProp.builtIns) {
      if (_get(prop) == null && itemOf(prop) != null) {
        _properties[prop] = baseSpec ??= _specOf(base);
      }
    }
  }

  /// Whether [items] has no two items of one class.
  static bool _oneItemForEachClass(List<PropertyAnimation>? items) {
    if (items == null) return true;
    final classes = <Type>{};
    for (final item in items) {
      if (!classes.add(item.runtimeType)) return false;
    }
    return true;
  }

  /// The options of the object [cfg] as an [AnimationSpec]: each key of
  /// `defaults.animation` (core.animations.js:28-30). An empty spec for a
  /// value that is not an object.
  AnimationSpec _specOf(Object? cfg) {
    final resolved = AnimationSpec();
    if (!isObject(cfg)) return resolved;
    final animationOptions = _objectKeys(
      defaults.lookup(OptionKey.animation)?.raw ?? undefined,
    );
    for (final option in animationOptions) {
      resolved.storeKey(option, _read(cfg!, option));
    }
    return resolved;
  }

  /// Whether a change of a property with the options [cfg] and the item
  /// [item] animates: `cfg.duration` is truthy (core.animations.js:99), or
  /// the duration of the item is not 0.
  static bool _animates(AnimationSpec cfg, PropertyAnimation? item) =>
      switch (item?.duration) {
        final Duration duration => duration > Duration.zero,
        null => animationHasDuration(cfg),
      };

  /// `this._properties.get(key)` for the property [prop].
  AnimationSpec? _get(AnimatedProp prop) => _properties[prop];

  /// The key of `_properties` for the JS value [key]: the [AnimatedProp] of
  /// a name, else [key] itself.
  static Object? _keyOf(Object? key) =>
      key is String ? AnimatedProp.of(key) : key;

  /// `this._properties.get(key)` for any JS value [key].
  AnimationSpec? _getKey(Object? key) => _properties[_keyOf(key)];

  /// `this._properties.set(key, value)` for any JS value [key]: a new key
  /// goes to the end of the key order.
  void _setKey(Object? key, AnimationSpec value) {
    _properties[_keyOf(key)] = value;
  }

  /// core.animations.js:13 `configure(config)`.
  ///
  /// `Object.keys(defaults.animation)` gives the own keys of the typed scope
  /// (an [OptionKey] for a declared key, Chart.js ADR 0054 §3), the keys of
  /// a Map, and no key for `false` or another primitive. It throws a
  /// [TypeError] for Dart `null` and `undefined`, as in JavaScript.
  /// `Object.getOwnPropertyNames(config)` is [jsOwnPropertyNames]: for a
  /// resolver, the keys of all its scopes (Chart.js ADR 0019, section 3).
  /// Each read of a resolver takes the typed read of its key ([_read]).
  void configure(Object? config) {
    if (!isObject(config)) {
      return;
    }
    final configObject = config!;

    final animationOptions = _objectKeys(
      defaults.lookup(OptionKey.animation)?.raw ?? undefined,
    );

    for (final key in jsOwnPropertyNames(configObject)) {
      final cfg = _read(configObject, key);
      if (!isObject(cfg)) {
        continue;
      }
      final cfgObject = cfg!;
      // DIVERGES(chartjs): adapt-animation-spec, a typed copy of the options.
      final resolved = AnimationSpec();
      for (final option in animationOptions) {
        resolved.storeKey(option, _read(cfgObject, option));
      }

      final cfgProperties = _read(cfgObject, OptionKey.properties);
      // An empty array is truthy: `isArray(p) && p || [key]` gives it.
      final props = isArray(cfgProperties)
          ? cfgProperties! as List<Object?>
          : <Object?>[key];
      for (final prop in props) {
        if (prop == key || _getKey(prop) == null) {
          _setKey(prop, resolved);
        }
      }
    }
  }

  /// core.animations.js:43 `_animateOptions(target, values)`: Utility to
  /// handle animation of `options`.
  ///
  /// [newOptions] is `values.options`, which the caller reads: the typed
  /// field of a property object, or the read by name of another object.
  List<Animation> _animateOptions(Object target, Object? newOptions) {
    final options = _resolveTargetOptions(target, newOptions);
    if (options == null) {
      return [];
    }

    final newOptionsObject = newOptions!;
    final animations = _createAnimations(options, newOptionsObject);
    if (jsTruthy(_shared(newOptionsObject))) {
      // Going to shared options:
      // After all animations are done, assign the shared options object to
      // the element
      // So any new updates to the shared options are observed
      unawaited(
        _awaitAll(
          _animationsOf(readProperty(target, 'options')),
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
  ///
  /// A property object of a controller goes through
  /// [_createTypedAnimations]: its typed keys in the `Object.keys` order
  /// (Chart.js ADR 0054 §10).
  List<Animation> _createAnimations(Object target, Object values) {
    final running = _runningOf(target);
    final date = jsDateNow();
    // DIVERGES(chartjs): platform-reduced-motion, no animation config.
    final reduced = isReducedMotion(_chart.canvas);
    if (values is TypedRecord) {
      return _createTypedAnimations(target, values, running, date, reduced);
    }
    final animations = <Animation>[];
    // The face: a plain object of the caller, read by name in the
    // `Object.keys` order.
    final props = jsObjectKeys(values);
    int i;

    for (i = props.length - 1; i >= 0; --i) {
      final prop = props[i];
      if (prop.startsWith(r'$')) {
        continue;
      }

      if (prop == 'options') {
        animations.addAll(_animateOptions(target, _readName(values, prop)));
        continue;
      }
      final value = _readName(values, prop);
      var animation = running[prop] as Animation?;
      final key = AnimatedProp.of(prop);
      final cfg = reduced ? null : _get(key);
      // DIVERGES(chartjs): adapt-property-animations, the item of the app.
      final item = cfg == null ? null : itemOf(key);

      if (animation != null) {
        if (cfg != null && animation.active()) {
          // There is an existing active animation, let's update that
          animation.update(cfg, value, date, item);
          continue;
        } else {
          animation.cancel();
        }
      }
      if (cfg == null || !_animates(cfg, item)) {
        // not animated, set directly to new value
        key.store(target, value);
        continue;
      }

      running[prop] = animation = Animation.typed(
        cfg,
        target,
        key,
        value,
        item,
      );
      animations.add(animation);
    }
    return animations;
  }

  /// core.animations.js:68-116, the loop of `_createAnimations` on the typed
  /// keys of the property object [values] (Chart.js ADR 0054 §10).
  ///
  /// The keys are the own keys of [values] in the `Object.keys` order
  /// ([TypedRecord.keyAt], [animatedPropOf]). A write that is not animated
  /// takes the typed setter of an element of the built-in class of [values]
  /// (`Element.writePropertyAt`), else the write by name. A value of an
  /// animation is the value by name of [values] (`TypedRecord.jsRead`): the
  /// raw value, also a foreign one.
  List<Animation> _createTypedAnimations(
    Object target,
    TypedRecord values,
    Map<String, Object?> running,
    double date,
    bool reduced,
  ) {
    final animations = <Animation>[];
    final element = target is Element && target.takesProperties(values)
        ? target
        : null;

    for (var i = values.ownKeyCount - 1; i >= 0; --i) {
      final key = animatedPropOf(values, i);
      final prop = key.name;
      if (prop.startsWith(r'$')) {
        continue;
      }

      if (prop == 'options') {
        animations.addAll(_animateOptions(target, _optionsOf(values)));
        continue;
      }
      var animation = running[prop] as Animation?;
      final cfg = reduced ? null : _get(key);
      // DIVERGES(chartjs): adapt-property-animations, the item of the app.
      final item = cfg == null ? null : itemOf(key);

      if (animation != null) {
        if (cfg != null && animation.active()) {
          // There is an existing active animation, let's update that
          animation.update(cfg, values.jsRead(prop), date, item);
          continue;
        } else {
          animation.cancel();
        }
      }
      if (cfg == null || !_animates(cfg, item)) {
        // not animated, set directly to new value
        if (element != null) {
          element.writePropertyAt(values, i);
        } else {
          key.store(target, values.jsRead(prop));
        }
        continue;
      }

      running[prop] = animation = Animation.typed(
        cfg,
        target,
        key,
        values.jsRead(prop),
        item,
      );
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
  /// values)` is `Element.assign` for an element, which takes the typed
  /// writes of a property object (Chart.js ADR 0054 §9). For another target
  /// it writes each key of `Object.keys(values)` through [writeProperty], in
  /// that order.
  bool? update(Object target, Object values) {
    if (_properties.isEmpty) {
      // Nothing is animated, just apply the new values.
      if (target is Element) {
        target.assign(values);
      } else {
        // The face: `Object.assign` of a plain object.
        for (final key in jsObjectKeys(values)) {
          writeProperty(target, key, _readName(values, key));
        }
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

/// The [AnimatedProp] of the own key at [position] of the property object
/// [values]: the constant of its field (Chart.js ADR 0054 §10), or
/// [AnimatedProp.of] of the name of another key.
///
/// The tables follow the field slots of `lib/src/options/props.dart`.
/// `test/port/core/core.animations_test.dart` checks each name against
/// [TypedRecord.keyAt].
@internal
AnimatedProp animatedPropOf(TypedRecord values, int position) {
  final slot = values.slotAt(position);
  if (slot >= 0) {
    final table = switch (values) {
      PointProperties() => _pointProps,
      BarProperties() => _barProps,
      ArcProperties() => _arcProps,
      LineProperties() => _lineProps,
      _ => null,
    };
    if (table != null) return table[slot];
  }
  return AnimatedProp.of(values.keyAt(position));
}

/// The keys of the fields of [PointProperties], by slot.
const List<AnimatedProp> _pointProps = [
  AnimatedProp.x,
  AnimatedProp.y,
  AnimatedProp.custom('skip'),
  AnimatedProp.custom('stop'),
  AnimatedProp.custom('parsed'),
  AnimatedProp.custom('raw'),
  AnimatedProp.custom('options'),
  AnimatedProp.custom('angle'),
];

/// The keys of the fields of [BarProperties], by slot.
const List<AnimatedProp> _barProps = [
  AnimatedProp.custom('horizontal'),
  AnimatedProp.base,
  AnimatedProp.custom('enableBorderRadius'),
  AnimatedProp.x,
  AnimatedProp.y,
  AnimatedProp.height,
  AnimatedProp.width,
  AnimatedProp.custom('options'),
  AnimatedProp.custom('borderSkipped'),
  AnimatedProp.custom('inflateAmount'),
];

/// The keys of the fields of [ArcProperties], by slot.
const List<AnimatedProp> _arcProps = [
  AnimatedProp.x,
  AnimatedProp.y,
  AnimatedProp.startAngle,
  AnimatedProp.endAngle,
  AnimatedProp.circumference,
  AnimatedProp.outerRadius,
  AnimatedProp.innerRadius,
  AnimatedProp.custom('options'),
];

/// The keys of the fields of [LineProperties], by slot.
const List<AnimatedProp> _lineProps = [
  AnimatedProp.custom('animated'),
  AnimatedProp.custom('options'),
  AnimatedProp.custom('_loop'),
  AnimatedProp.custom('_fullLoop'),
];

/// `values.options` of the property object [values]: its typed field, or
/// the read by name of a record of another class or with a foreign value
/// (the raw value, which the typed field does not hold).
Object? _optionsOf(TypedRecord values) => switch (values) {
  _ when values.hasForeign => values.jsRead('options'),
  final PointProperties props => props.options,
  final BarProperties props => props.options,
  final ArcProperties props => props.options,
  final LineProperties props => props.options,
  _ => values.jsRead('options'),
};

/// `target.$animations || (target.$animations = {})` (core.animations.js:
/// 71): the running animations of [target]. An [Element] keeps them in its
/// typed member. Another target reads and writes them by name.
Map<String, Object?> _runningOf(Object target) {
  if (target is Element) {
    return target.$animations ??= <String, Animation>{};
  }
  var running = readProperty(target, r'$animations');
  if (!jsTruthy(running)) {
    writeProperty(target, r'$animations', running = <String, Animation>{});
  }
  return running! as Map<String, Object?>;
}

/// `options.$shared` of the options object [options]: the field of
/// [ElementOptions], else the read by name.
Object? _shared(Object options) => options is ElementOptions
    ? options.$sharedValue
    : _readName(options, r'$shared');

/// `options.$animations` of the options object [options]: the field of
/// [ElementOptions], else the read by name. Throws a [TypeError] for Dart
/// `null` and [undefined], as the JS property read does.
Object? _animationsOf(Object? options) => options is ElementOptions
    ? options.$animationsValue
    : _readName(options, r'$animations');

/// `object[name]`: the read by name of an object of the caller (the face,
/// Chart.js ADR 0054 §5). It gives [undefined] for an absent key, and
/// throws a [TypeError] for Dart `null` and [undefined].
Object? _readName(Object? object, String name) => jsGet(object, name);

/// `object[key]` of a config object (core.animations.js:23, :28, :31): the
/// typed read of a resolver for an [OptionKey] ([readOption], Chart.js ADR
/// 0054 §4), else the read by name.
Object? _read(Object object, Object key) => key is OptionKey
    ? readOption(object, key)
    : _readName(object, key as String);

/// core.animations.js:134 `awaitAll(animations, properties)`: a future of
/// the end of each active animation of [animations] under a key of
/// [properties].
///
/// `animations[key]` is a read by name. Thus `undefined` animations throw a
/// [TypeError], as in JavaScript. `Promise.all` is [jsPromiseAll].
Future<List<void>> _awaitAll(Object? animations, Object properties) {
  final running = <Future<void>>[];
  // The face: `Object.keys` of the options object.
  final keys = jsObjectKeys(properties);
  for (var i = 0; i < keys.length; i++) {
    final anim = _readName(animations, keys[i]);
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
Object? _resolveTargetOptions(Object target, Object? newOptions) {
  if (!jsTruthy(newOptions)) {
    return null;
  }
  var options = readProperty(target, 'options');
  if (!jsTruthy(options)) {
    writeProperty(target, 'options', newOptions);
    return null;
  }
  if (jsTruthy(_shared(options!))) {
    // Going from shared options to distinct one:
    // Create new options object containing the old shared values and start
    // updating that.
    // DIVERGES(chartjs): adapt-typed-element-options, the copy keeps the class.
    final copy = copyOptions(options);
    if (copy is ElementOptions) {
      copy
        ..storeKey(OptionKey.dollarShared, false)
        ..storeKey(OptionKey.dollarAnimations, <String, Animation>{});
    } else {
      // The face: the copy of a plain options object.
      writeProperty(copy, r'$shared', false);
      writeProperty(copy, r'$animations', <String, Animation>{});
    }
    options = copy;
    writeProperty(target, 'options', options);
  }
  return options;
}

/// `Object.keys(value)` for `defaults.animation` (core.animations.js:18):
/// the own keys of a typed scope (an [OptionKey] for a declared key, a name
/// for an extra, in the `Object.keys` order), the names of [jsObjectKeys]
/// for a Map, the indices of a List or a String, and no key for another
/// value. Throws a [TypeError] for Dart `null` and [undefined], as
/// JavaScript does.
List<Object> _objectKeys(Object? value) {
  switch (value) {
    case null || Undefined():
      // A JavaScript TypeError: Object.keys of null or undefined.
      throw TypeError();
    case final OptionScope scope:
      return scope.jsOwnKeys();
    case final AnyObject object:
      // The face: the keys of a plain object of user code.
      return jsObjectKeys(object);
    case final JsObjectFace object:
      // The face: the keys of a typed object.
      return jsObjectKeys(object);
    case final List<Object?> list:
      return [for (var i = 0; i < list.length; i++) jsNumberToString(i)];
    case final String string:
      return [for (var i = 0; i < string.length; i++) jsNumberToString(i)];
  }
  return const [];
}
