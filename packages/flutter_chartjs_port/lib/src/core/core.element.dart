// Ported from Chart.js v4.6.1 src/core/core.element.ts (MIT, Chart.js Contributors).

/// Port of `src/core/core.element.ts`.
///
/// Chart.js ADR 0017 decides the representation of an element. A Chart.js
/// element is an open JavaScript object. The port gives it typed members for
/// the hot paths, and the access by name of [Element.operator []] and
/// [Element.operator []=] for the code that reads and writes a property by
/// its name (phase 5).
///
/// - [Element] is the base class of the element classes of
///   `lib/src/elements/`. It is concrete, because `core.element.tests.js:4`
///   constructs it.
/// - [ElementProps] is the result of [Element.getProps]. [Element]
///   implements it. Thus the branch that returns the element allocates
///   nothing.
/// - [Element] also implements `types.PropertyAccess`, the read and the
///   write by name of `lib/src/types/index.dart`, and thus
///   `types.ElementPropertyRead`. A ported helper that must tell `undefined`
///   from NaN reads a point through it, without an import of this library
///   (Chart.js ADR 0017, section 5). The animations read and write their
///   targets through it (Chart.js ADR 0019, section 2).
/// - [ElementPoint] is the object literal `{x, y}` of
///   [Element.tooltipPosition] and of `getCenterPoint`.
///
/// The element classes convert an option value for a canvas setter with the
/// functions of `lib/src/js/js_webidl.dart`, and read `value || 0` with
/// `jsOrZero` of `lib/src/js/js_number.dart` (Chart.js ADR 0017, section 8).
///
/// This library is a pure layer (Chart.js ADR 0017, section 10). It imports
/// neither `dart:ui` nor `package:flutter`.
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show isNumber;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ContextObject;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/animated_prop.dart'
    show AnimatedProp;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show GenericElementOptionsScope;
import 'package:flutter_chartjs_port/src/options/typed_record.dart'
    show TypedRecord;
import 'package:flutter_chartjs_port/src/types/animation.dart' as types;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// core.element.ts:6 `Element<T = AnyObject, O = AnyObject>`.
///
/// The base class of the chart elements (Chart.js ADR 0017, with the
/// storage of Chart.js ADR 0054 §9). The type parameters have no Dart form.
/// `T`, the animated properties, are typed members and the access by name.
/// `O`, the options, is the Map [options].
///
/// ## Properties
///
/// Each upstream property is a typed member with the upstream name. A
/// number is a `double` (Chart.js ADR 0045).
///
/// - A numeric property is a `double` field and a bit of an `int` mask of
///   the `undefined` state (Chart.js ADR 0054 §9). The field holds NaN, the
///   `ToNumber` of `undefined`, while the bit is set. Thus the getter gives
///   the field, and a store makes no box.
/// - A boolean or object property that starts JS `undefined` has a
///   nullable private field. Dart `null` stands for `undefined`. JS `null`
///   never reaches these properties.
/// - The typed setter takes the non-null type: it stores the value and
///   clears the bit. [markUndefined] and a write by name of [undefined] set
///   the `undefined` state again.
/// - A reader that must tell `undefined` from NaN reads the property by name,
///   through [isUndefined] or through [getProps].
/// - [hidden] is not an upstream property of the class. Upstream code adds
///   it to a data element, and the types give it no type. Thus it holds any
///   value, as an extra property does.
/// - `$context`, the context that a dataset controller adds to a data
///   element (core.datasetController.js:767-768), is a typed member too: the
///   typed read [$context] gives the [ContextObject], and the access by name
///   keeps any value. The data element classes narrow it to the
///   `ScriptableContext` of a data context.
///
/// ## Access by name
///
/// [operator []] is the JS property read `element[prop]`. [operator []=] is
/// the JS write `element[prop] = value`. It is the cold face of user code,
/// of the specs and of the elements of user classes (Chart.js ADR 0054 §5).
///
/// - The read gives the stored value. It gives the [undefined] sentinel for
///   a property in the `undefined` state and for an unknown name.
/// - A JS object accepts any property. Thus a write of an unknown name goes
///   to a Map of extra properties. The element creates the Map at the first
///   such write. A read of an unknown name reads it.
/// - A numeric property accepts a `num`, which becomes a `double`, or
///   [undefined]. A boolean property accepts a `bool` or [undefined]. An
///   object property accepts its type or [undefined]. Another value is
///   outside the upstream type contract. The write throws an
///   [ArgumentError].
///
/// ## Subclasses
///
/// An element class of `lib/src/elements/` extends [Element] and implements
/// `types.VisualElement`. It follows this protocol:
///
/// - It declares each numeric property as a `double` field with NaN as its
///   start value and a bit of its own `int` mask, and each other property as
///   a nullable private field, with a public getter and setter, as [x] and
///   [y] do.
/// - It overrides [operator []] with a `switch` over its own names, and
///   passes the other names to `super`. The names are the upstream
///   JavaScript names, also for a member whose Dart name drops the
///   underscore (Chart.js ADR 0012).
/// - It overrides [operator []=] in the same way. It converts the value with
///   [toNumberProp], [toBoolProp], [toDefinedBoolProp] or [toObjectProp],
///   which also throw the [ArgumentError].
/// - It overrides [markUndefined] and [isUndefined] for the [AnimatedProp]
///   ids of its numeric properties, and passes the other ids to `super`.
/// - Its constructor takes `[AnyObject? cfg]` and calls [assign] with it, as
///   upstream calls `Object.assign(this, cfg)` (element.point.ts:57-59).
///   The fields start in the `undefined` state. Thus the constructor sets
///   only the start values that are not `undefined`, in the upstream order,
///   before [assign].
/// - Its static members `id`, `defaults`, `defaultRoutes` and `descriptors`
///   are static fields (Chart.js ADR 0017, section 2).
/// - Its static field `jsClass` is the class as a value (Chart.js ADR 0020,
///   section 3). Its `superclass` is [Element.jsClass]. Its `statics` hold
///   the static fields in the upstream order of declaration. Its `construct`
///   calls the constructor with [elementCfgArg].
///
/// ```dart
/// class BoxElement extends Element implements types.VisualElement {
///   BoxElement([AnyObject? cfg]) {
///     if (cfg != null) assign(cfg);
///   }
///
///   double _width = double.nan;
///   int _undefinedBits = 1;
///   bool? _horizontal;
///
///   double get width => _width;
///   set width(double value) {
///     _width = value;
///     _undefinedBits &= ~1;
///   }
///
///   bool? get horizontal => _horizontal;
///   set horizontal(bool value) => _horizontal = value;
///
///   @override
///   Object? operator [](String prop) => switch (prop) {
///     'width' => _undefinedBits & 1 != 0 ? undefined : _width,
///     'horizontal' => _horizontal ?? undefined,
///     _ => super[prop],
///   };
///
///   @override
///   void operator []=(String prop, Object? value) {
///     switch (prop) {
///       case 'width':
///         final number = toNumberProp(prop, value);
///         _width = number ?? double.nan;
///         _undefinedBits = number == null
///             ? _undefinedBits | 1
///             : _undefinedBits & ~1;
///       case 'horizontal':
///         _horizontal = toBoolProp(prop, value);
///       default:
///         super[prop] = value;
///     }
///   }
///
///   // draw, inRange, inXRange, inYRange and getCenterPoint.
/// }
/// ```
class Element implements types.Element, types.PropertyAccess, ElementProps {
  /// core.element.ts:6 the implicit constructor of `Element`.
  ///
  /// [x], [y], [options] and [$animations] start in the `undefined` state.
  /// [active] starts false.
  Element();

  /// core.element.ts:8 `static defaults = {}`, an empty typed scope of the
  /// kind `GenericElementOptions` (Chart.js ADR 0054 §3).
  static final GenericElementOptionsScope defaults =
      GenericElementOptionsScope();

  /// core.element.ts:9 `static defaultRoutes = undefined`: the [undefined]
  /// sentinel.
  static const Object defaultRoutes = undefined;

  /// core.element.ts:6 `class Element` as a value (Chart.js ADR 0020,
  /// section 3).
  ///
  /// Its statics are [defaults] and [defaultRoutes], with the [undefined]
  /// sentinel as an own value (core.element.ts:8-9). It has no `id`. Its
  /// `construct` ignores the arguments, as the implicit constructor of
  /// `Element` does. A class value that extends it without a `construct` of
  /// its own constructs an [Element].
  static final JsClass jsClass = JsClass(
    'Element',
    statics: {'defaults': defaults, 'defaultRoutes': defaultRoutes},
    construct: (newTarget, args) => Element(),
  );

  /// The bit of [x] in [_undefinedXY].
  static const int _xBit = 1;

  /// The bit of [y] in [_undefinedXY].
  static const int _yBit = 2;

  /// The value of [x]: NaN in the `undefined` state.
  double _x = double.nan;

  /// The value of [y]: NaN in the `undefined` state.
  double _y = double.nan;

  /// The bits of [x] and [y] in the `undefined` state (Chart.js ADR 0054
  /// §9). Both start set.
  int _undefinedXY = _xBit | _yBit;

  /// The value of `$context` by name: any value, [undefined] at the start.
  Object? _context = undefined;

  /// The extra properties of the access by name: the properties that the
  /// element class does not declare. Dart `null` until the first write of
  /// such a property.
  Map<String, Object?>? _extras;

  /// core.element.ts:11 `x: number`.
  ///
  /// NaN in the `undefined` state, the start value. JS `null` never reaches
  /// it. `this['x']` gives [undefined] in that state.
  @override
  double get x => _x;

  set x(double value) {
    _x = value;
    _undefinedXY &= ~_xBit;
  }

  /// core.element.ts:12 `y: number`. NaN in the `undefined` state, as [x].
  @override
  double get y => _y;

  set y(double value) {
    _y = value;
    _undefinedXY &= ~_yBit;
  }

  /// `this.$context`, the scriptable context of the element, as a typed
  /// member (Chart.js ADR 0054 §9): the data context of a data element
  /// (core.datasetController.js:767-768), the context of a scale
  /// (core.scale.js:249) or of the tooltip (plugin.tooltip.js:528).
  ///
  /// core.element.ts does not declare it. The getter gives the context when
  /// the property holds a [ContextObject], else Dart `null`: the `undefined`
  /// start state, or another value that a write by name stored.
  /// `this[r'$context']` gives the stored value as it is. A subclass narrows
  /// the type of its context: the setter is `covariant`. Dart `null` for the
  /// setter writes `undefined`.
  ContextObject? get $context => switch (_context) {
    final ContextObject context => context,
    _ => null,
  };

  set $context(covariant ContextObject? value) => _context = value ?? undefined;

  /// core.element.ts:13 `active = false`.
  ///
  /// It is not optional. Thus a write by name accepts only a `bool`.
  @override
  bool active = false;

  /// core.element.ts:14 `options: O`, the resolved options of the element
  /// (Chart.js ADR 0043, ADR 0017 section 8).
  ///
  /// Dart `null` stands for JS `undefined`, the start value. JS `null` never
  /// reaches it.
  @override
  Map<String, Object?>? options;

  /// core.element.ts:15 `$animations: Record<keyof T, Animation>`, the
  /// running animation of each property name.
  ///
  /// Dart `null` stands for JS `undefined`, the start value.
  /// `core.animations.js` creates the Map. JS `null` never reaches it.
  Map<String, types.Animation>? $animations;

  /// core.datasetController.js:730 `element.hidden`: a truthy value hides
  /// the data element in the draw of its dataset.
  ///
  /// core.element.ts does not declare it, and the types give it no type.
  /// `_updateVisibility` writes a boolean (core.controller.js:898), and user
  /// code can write any value. `DatasetController.draw` reads it for each
  /// element in each draw (core.datasetController.js:730). Thus the class
  /// declares it, as Chart.js ADR 0017 (Consequences) permits for a property
  /// that a ported caller reads often (performance.md §10.6).
  ///
  /// It keeps any value, as the Map of extra properties does: the
  /// [undefined] sentinel in the start state, and Dart `null` for JS `null`.
  @override
  Object? hidden = undefined;

  /// core.element.ts:17 `tooltipPosition(useFinalPosition: boolean):
  /// Point`.
  ///
  /// Upstream copies `x` and `y` into the literal `{x, y}`. The port gives
  /// their `ToNumber`. Thus a property in the `undefined` state gives NaN,
  /// as the [Point] rules of `geometric.dart` state for a copied
  /// `undefined`. Dart `null` for [useFinalPosition] stands for JS
  /// `undefined`: `plugin.tooltip.js:34` calls it with no argument.
  ElementPoint tooltipPosition([
    // The upstream signature has a positional `useFinalPosition`.
    // ignore: avoid_positional_boolean_parameters
    bool? useFinalPosition,
  ]) {
    // `getProps(['x', 'y'], useFinalPosition)` in the typed form.
    return ElementPoint(
      finalNumber(AnimatedProp.x, x, useFinalPosition),
      finalNumber(AnimatedProp.y, y, useFinalPosition),
    );
  }

  /// core.element.ts:22 `hasValue()`.
  ///
  /// [x] and [y] give NaN in the `undefined` state, and `isNumber` is false
  /// for both NaN and `undefined`.
  bool hasValue() {
    return isNumber(x) && isNumber(y);
  }

  /// Puts the property [prop] into the `undefined` state: the typed
  /// property API of Chart.js ADR 0054 §9, with the typed setters of the
  /// element classes (`x`, `y` and the others).
  ///
  /// A numeric property gets NaN and its bit. A subclass handles the ids of
  /// its own numeric properties and passes the other ids to `super`. Another
  /// property is the write by name `this[prop] = undefined`.
  @internal
  void markUndefined(AnimatedProp prop) {
    switch (prop.id) {
      case animatedPropX:
        _x = double.nan;
        _undefinedXY |= _xBit;
      case animatedPropY:
        _y = double.nan;
        _undefinedXY |= _yBit;
      default:
        this[prop.name] = undefined;
    }
  }

  /// Whether the property [prop] is in the `undefined` state, or the element
  /// does not have it: `this[prop] === undefined`.
  ///
  /// A numeric property gives its bit. A subclass handles the ids of its own
  /// numeric properties and passes the other ids to `super`. Another
  /// property is the read by name.
  @internal
  bool isUndefined(AnimatedProp prop) => switch (prop.id) {
    animatedPropX => _undefinedXY & _xBit != 0,
    animatedPropY => _undefinedXY & _yBit != 0,
    _ => identical(this[prop.name], undefined),
  };

  /// `getProps([prop], useFinalPosition)[prop]` for the numeric property
  /// [prop] with the current value [current], through `ToNumber`: the typed
  /// form of the ported callers of [getProps] (Chart.js ADR 0054 §9).
  ///
  /// When [useFinalPosition] is true and the element has `$animations`, an
  /// active animation of [prop] gives the `ToNumber` of its target value
  /// (core.element.ts:41). Else the result is [current], the typed getter
  /// of [prop]: NaN in the `undefined` state is the `ToNumber` of the
  /// `undefined` that upstream reads.
  @internal
  double finalNumber(
    AnimatedProp prop,
    double current,
    // The upstream signature has a positional `useFinalPosition`.
    // ignore: avoid_positional_boolean_parameters
    bool? useFinalPosition,
  ) {
    if (useFinalPosition != true) return current;
    final anim = $animations?[prop.name];
    return anim != null && anim.active() ? jsToNumber(anim.to) : current;
  }

  /// `getProps([prop], useFinalPosition)[prop]` for the property [prop] with
  /// the current value [current] (the value by name): as [finalNumber], with
  /// the target value as it is.
  @internal
  Object? finalValue(
    AnimatedProp prop,
    Object? current,
    // The upstream signature has a positional `useFinalPosition`.
    // ignore: avoid_positional_boolean_parameters
    bool? useFinalPosition,
  ) {
    if (useFinalPosition != true) return current;
    final anim = $animations?[prop.name];
    return anim != null && anim.active() ? anim.to : current;
  }

  /// core.element.ts:31-44 `getProps(props, final?)`.
  ///
  /// Gets the current or final value of each prop. Can return extra
  /// properties (whole object).
  /// @param props - properties to get
  /// @param [final] - get the final value (animation target)
  ///
  /// `final` is a reserved word in Dart. Thus the parameter is [isFinal].
  /// Dart `null` stands for JS `undefined`. The result is the element
  /// itself, or an [ElementProps] over a new Map with an own key for each
  /// name of [props]. A caller reads a number from it with `jsToNumber` and
  /// a boolean with `jsTruthy`.
  ElementProps getProps(
    List<String> props, [
    // The upstream signature has a positional `final`.
    // ignore: avoid_positional_boolean_parameters
    bool? isFinal,
  ]) {
    final anims = $animations;
    if (isFinal != true || anims == null) {
      // let's not create an object, if not needed
      return this;
    }
    final ret = <String, Object?>{};
    for (final prop in props) {
      final anim = anims[prop];
      ret[prop] = anim != null && anim.active() ? anim.to : this[prop];
    }
    return _PlainProps(ret);
  }

  /// The JS property read `element[prop]` (Chart.js ADR 0017, section 5).
  ///
  /// It gives the stored value of [prop]: a `double` for a number, a `bool`,
  /// or the object. It gives the [undefined] sentinel for a property in the
  /// `undefined` state and for a name that the element does not have. A
  /// subclass handles its own names first and passes the other names to
  /// `super`.
  @override
  Object? operator [](String prop) => switch (prop) {
    'x' => _undefinedXY & _xBit != 0 ? undefined : _x,
    'y' => _undefinedXY & _yBit != 0 ? undefined : _y,
    'active' => active,
    'options' => options ?? undefined,
    r'$animations' => $animations ?? undefined,
    'hidden' => hidden,
    r'$context' => _context,
    _ => _extra(prop),
  };

  /// The JS property write `element[prop] = value` (Chart.js ADR 0017,
  /// section 5).
  ///
  /// - `x` and `y` accept a `num` or [undefined] ([toNumberProp]).
  /// - `active` accepts a `bool`. It is not optional, so [undefined] is
  ///   outside its type.
  /// - `options` accepts a `Map<String, Object?>` or [undefined].
  /// - `$animations` accepts a `Map<String, types.Animation>` or
  ///   [undefined].
  /// - `hidden` and `$context` accept any value, as an extra property does
  ///   ([hidden], [$context]).
  /// - Another name stores [value] as it is in the Map of extra properties:
  ///   also Dart `null` for JS `null` and the [undefined] sentinel.
  ///
  /// Throws an [ArgumentError] for a value outside the type of a declared
  /// property. A subclass handles its own names first and passes the other
  /// names to `super`.
  @override
  void operator []=(String prop, Object? value) {
    switch (prop) {
      case 'x':
        final number = toNumberProp(prop, value);
        _x = number ?? double.nan;
        _undefinedXY = number == null
            ? _undefinedXY | _xBit
            : _undefinedXY & ~_xBit;
      case 'y':
        final number = toNumberProp(prop, value);
        _y = number ?? double.nan;
        _undefinedXY = number == null
            ? _undefinedXY | _yBit
            : _undefinedXY & ~_yBit;
      case r'$context':
        _context = value;
      case 'active':
        active = toDefinedBoolProp(prop, value);
      case 'options':
        options = toObjectProp<Map<String, Object?>>(prop, value);
      case r'$animations':
        $animations = toObjectProp<Map<String, types.Animation>>(prop, value);
      case 'hidden':
        hidden = value;
      default:
        (_extras ??= <String, Object?>{})[prop] = value;
    }
  }

  /// `Object.assign(this, source)`, the copy of a plain object into the
  /// element. The element constructors call it with their `cfg`
  /// (element.point.ts:58, element.arc.ts:425, element.bar.js:175,
  /// element.line.js:295). `updateElement` calls it with the new properties
  /// (core.datasetController.js:900).
  ///
  /// A property object of a controller (a [TypedRecord] of
  /// `lib/src/options/props.dart`) that the element [takesProperties] goes
  /// through the typed writes of [writePropertyAt], in its key order
  /// (Chart.js ADR 0054 §9). Another object writes each own key of [source]
  /// through [operator []=], in the `Object.keys` order ([jsObjectKeys]).
  /// Thus an `int` becomes a `double`, and a value outside the type of a
  /// declared property throws an [ArgumentError] after the writes of the
  /// keys before it.
  void assign(AnyObject source) {
    if (source is TypedRecord && takesProperties(source)) {
      for (var i = 0, n = source.length; i < n; i++) {
        writePropertyAt(source, i);
      }
      return;
    }
    // The face: `Object.assign` of a plain object reads each own key by
    // name, in the `Object.keys` order.
    for (final key in jsObjectKeys(source)) {
      this[key] = source[key];
    }
  }

  /// Whether the element takes the typed writes of [writePropertyAt] for
  /// the property object [props] of a controller (Chart.js ADR 0054 §9).
  ///
  /// It is false when the element takes the writes by name: an element of
  /// another class than the built-in class of [props] (a user class, so
  /// that its `operator []=` sees each write, judge-r §2.5). [Element] has
  /// no property object: it gives false. An element class gives true for
  /// its own object. [writePropertyAt] writes an extra key and a foreign
  /// value by name, at its position of the `Object.keys` order.
  @internal
  bool takesProperties(TypedRecord props) => false;

  /// The typed write of the own key at [position] of [props], an object
  /// that the element [takesProperties]: `this[key] = props[key]`
  /// (Chart.js ADR 0054 §9). A key that the element class does not type
  /// goes through [assignKey].
  @internal
  void writePropertyAt(TypedRecord props, int position) =>
      assignKey(props, position);

  /// The write by name of the own key at [position] of [props]:
  /// `this[key] = props[key]`, for a key that [writePropertyAt] does not
  /// type (an extra property of the element, or a value that the typed
  /// setter does not take). It throws the [ArgumentError] of
  /// [operator []=].
  @protected
  void assignKey(TypedRecord props, int position) {
    final key = props.keyAt(position);
    this[key] = props.jsRead(key);
  }

  /// The typed write `this[prop] = value` of the number [value]: the number
  /// path of `core.animation` (Chart.js ADR 0054 §10).
  ///
  /// [x] and [y] take their setters. An element class handles the ids of its
  /// own numeric properties and passes the other ids to `super`. Another
  /// property is the write by name.
  @internal
  void writeNumber(AnimatedProp prop, double value) {
    switch (prop.id) {
      case animatedPropX:
        x = value;
      case animatedPropY:
        y = value;
      default:
        this[prop.name] = value;
    }
  }

  /// The value that a write by name of [value] stores in the numeric
  /// property [prop] (Chart.js ADR 0017, section 5).
  ///
  /// A `num` gives its `double`. The [undefined] sentinel gives Dart `null`,
  /// the `undefined` state. Throws an [ArgumentError] for another value, also
  /// for Dart `null` (JS `null`) and for a `String`.
  @protected
  double? toNumberProp(String prop, Object? value) => switch (value) {
    final num number => number.toDouble(),
    Undefined() => null,
    _ => throw ArgumentError.value(value, prop, 'Not a number or undefined'),
  };

  /// The value that a write by name of [value] stores in the boolean
  /// property [prop] (Chart.js ADR 0017, section 5).
  ///
  /// A `bool` gives itself. The [undefined] sentinel gives Dart `null`, the
  /// `undefined` state. Throws an [ArgumentError] for another value, also
  /// for Dart `null` (JS `null`).
  @protected
  bool? toBoolProp(String prop, Object? value) => toObjectProp<bool>(
    prop,
    value,
  );

  /// The value that a write by name of [value] stores in the boolean
  /// property [prop] that upstream never sets to `undefined`, for example
  /// [active] (Chart.js ADR 0017, section 5).
  ///
  /// The property has a start value, and every upstream write gives a
  /// boolean. Thus a `bool` gives itself, and [undefined] is outside the
  /// type of the property. Throws an [ArgumentError] for another value, also
  /// for [undefined] and for Dart `null` (JS `null`).
  @protected
  bool toDefinedBoolProp(String prop, Object? value) => switch (value) {
    final bool flag => flag,
    _ => throw ArgumentError.value(value, prop, 'Not a bool'),
  };

  /// The value that a write by name of [value] stores in the property [prop]
  /// of the type [T] (Chart.js ADR 0017, section 5).
  ///
  /// The [undefined] sentinel gives Dart `null`, the `undefined` state. A
  /// [T] gives itself. Throws an [ArgumentError] for another value, also for
  /// Dart `null` (JS `null`). A property that also takes JS `null` handles
  /// its write itself.
  @protected
  T? toObjectProp<T extends Object>(String prop, Object? value) =>
      switch (value) {
        Undefined() => null,
        final T object => object,
        _ => throw ArgumentError.value(value, prop, 'Not a $T or undefined'),
      };

  /// The read of the extra property [prop]: its value, or [undefined] when
  /// the element does not have it.
  Object? _extra(String prop) {
    final extras = _extras;
    if (extras == null) return undefined;
    final value = extras[prop];
    return value == null && !extras.containsKey(prop) ? undefined : value;
  }
}

/// The `cfg` of `new XElement(cfg)` from the arguments [args] of the
/// `construct` closure of an element class value (Chart.js ADR 0020, section
/// 3): the first item of [args].
///
/// The element constructors copy `cfg` with `if (cfg) Object.assign(this,
/// cfg)` (element.point.ts:57-59, element.line.js:294-296,
/// element.bar.js:174-176, element.arc.ts:424-426). Thus an absent argument,
/// [undefined], JS `null` and the other falsy values give Dart `null`, the
/// default of the Dart constructor. A Map gives itself. Another value throws
/// a [TypeError]. Upstream copies the own enumerable properties of such a
/// value, for example the characters of a string.
// DIVERGES(chartjs): adapt-component-class-role, a non-Map cfg throws.
@internal
AnyObject? elementCfgArg(List<Object?> args) {
  final cfg = args.isEmpty ? undefined : args[0];
  return switch (cfg) {
    final AnyObject map => map,
    _ when !jsTruthy(cfg) => null,
    // A JavaScript value that the port does not copy into an element.
    _ => throw TypeError(),
  };
}

// The ids of the built-in names of `AnimatedProp` (animated_prop.dart) that
// the element classes declare as numeric properties, for the `switch` of
// `markUndefined`, `isUndefined` and the typed writes. A constant pattern
// needs a constant, and `AnimatedProp.x.id` is not one.
// test/port/core/core.element_test.dart checks each value.

/// The id of [AnimatedProp.x].
@internal
const int animatedPropX = 0;

/// The id of [AnimatedProp.y].
@internal
const int animatedPropY = 1;

/// The id of [AnimatedProp.base].
@internal
const int animatedPropBase = 9;

/// The id of [AnimatedProp.width].
@internal
const int animatedPropWidth = 10;

/// The id of [AnimatedProp.height].
@internal
const int animatedPropHeight = 11;

/// The id of [AnimatedProp.circumference].
@internal
const int animatedPropCircumference = 12;

/// The id of [AnimatedProp.endAngle].
@internal
const int animatedPropEndAngle = 13;

/// The id of [AnimatedProp.innerRadius].
@internal
const int animatedPropInnerRadius = 14;

/// The id of [AnimatedProp.outerRadius].
@internal
const int animatedPropOuterRadius = 15;

/// The id of [AnimatedProp.startAngle].
@internal
const int animatedPropStartAngle = 16;

/// core.element.ts:31-33 the result type of `getProps`: `Pick<T, P[number]>`
/// or `Partial<Record<P, unknown>>`, an object that the caller destructures.
///
/// [Element] implements it, because `getProps` can return the element
/// itself (core.element.ts:35-37). The other result is a new plain object
/// (core.element.ts:39).
// The result object of getProps has one member, the property read.
// ignore: one_member_abstracts
abstract interface class ElementProps {
  /// The JS property read `props[prop]`.
  ///
  /// It gives the [undefined] sentinel for a property that the object does
  /// not have, or that is in the `undefined` state. A caller reads a number
  /// with `jsToNumber` and a boolean with `jsTruthy` (Chart.js ADR 0017,
  /// section 7).
  Object? operator [](String prop);
}

/// core.element.ts:39 `const ret = {}`, the new plain object of
/// [Element.getProps].
final class _PlainProps implements ElementProps {
  _PlainProps(this._values);

  /// The own properties. A value can be the [undefined] sentinel or Dart
  /// `null` for JS `null`.
  final Map<String, Object?> _values;

  @override
  Object? operator [](String prop) {
    final value = _values[prop];
    return value == null && !_values.containsKey(prop) ? undefined : value;
  }
}

/// core.element.ts:19 the object literal `{x, y}` of
/// [Element.tooltipPosition], also the result of `getCenterPoint` of the
/// element classes (Chart.js ADR 0017, section 9).
///
/// Two points are equal when their coordinates are equal, as the `toEqual`
/// of a spec compares two object literals. Thus a spec compares a point
/// with `equals`. NaN equals NaN, as in `toEqual`. 0 equals -0, as the Dart
/// `==` of two numbers gives.
@immutable
final class ElementPoint implements Point {
  /// The object literal `{x, y}`.
  const ElementPoint(this.x, this.y);

  /// The `x` of the literal. NaN stands for a copied JS `undefined`
  /// ([Point.x]).
  @override
  final double x;

  /// The `y` of the literal. NaN stands for a copied JS `undefined`
  /// ([Point.y]).
  @override
  final double y;

  @override
  bool operator ==(Object other) =>
      other is ElementPoint && _same(x, other.x) && _same(y, other.y);

  @override
  int get hashCode => Object.hash(_hash(x), _hash(y));

  /// The literal as JavaScript prints it, for test messages.
  @override
  String toString() => '{x: ${jsNumberToString(x)}, y: ${jsNumberToString(y)}}';
}

/// Whether [a] and [b] are equal coordinates of an [ElementPoint]. NaN is
/// equal to NaN.
bool _same(double a, double b) => a == b || (a.isNaN && b.isNaN);

/// The hash of a coordinate of an [ElementPoint]: one value for all NaN
/// values, and one value for 0 and -0.
int _hash(double value) => value.isNaN || value == 0 ? 0 : value.hashCode;
