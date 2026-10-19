// Ported from Chart.js v4.5.1 src/core/core.element.ts (MIT, Chart.js Contributors).

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
/// - [Element] also implements `types.ElementPropertyRead`, the read by
///   name of `lib/src/types/index.dart`. A ported helper that must tell
///   `undefined` from NaN reads a point through it, without an import of
///   this library (Chart.js ADR 0017, section 5).
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

import 'package:flutter_chartjs/src/helpers/helpers.math.dart' show isNumber;
import 'package:flutter_chartjs/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/animation.dart' as types;
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// core.element.ts:6 `Element<T = AnyObject, O = AnyObject>`.
///
/// The base class of the chart elements (Chart.js ADR 0017). The type
/// parameters have no Dart form. `T`, the animated properties, are typed
/// members and the access by name. `O`, the options, is the Map [options].
///
/// ## Properties
///
/// Each upstream property is a typed member with the upstream name. A
/// number is a `double` (Chart.js ADR 0010).
///
/// - A property that starts JS `undefined` has a nullable private field.
///   Dart `null` stands for `undefined`. JS `null` never reaches these
///   properties.
/// - The getter of a numeric property returns `double`. It gives NaN, the
///   `ToNumber` of `undefined`, in the `undefined` state. The getter of a
///   boolean or object property returns the nullable type.
/// - The setter takes the non-null type. Only a write by name stores
///   `undefined` again.
/// - A reader that must tell `undefined` from NaN reads the property by name
///   or through [getProps].
///
/// ## Access by name
///
/// [operator []] is the JS property read `element[prop]`. [operator []=] is
/// the JS write `element[prop] = value`.
///
/// - The read gives the stored value. It gives the [undefined] sentinel for
///   a property in the `undefined` state and for an unknown name.
/// - A JS object accepts any property. Thus a write of an unknown name goes
///   to a Map of extra properties, for example the `$context` that a dataset
///   controller adds (core.datasetController.js:767-768). The element
///   creates the Map at the first such write. A read of an unknown name
///   reads it.
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
/// - It declares each property as a nullable private field with a public
///   getter and setter, as [x] and [y] do.
/// - It overrides [operator []] with a `switch` over its own names, and
///   passes the other names to `super`. The names are the upstream
///   JavaScript names, also for a member whose Dart name drops the
///   underscore (Chart.js ADR 0012).
/// - It overrides [operator []=] in the same way. It converts the value with
///   [toNumberProp], [toBoolProp], [toDefinedBoolProp] or [toObjectProp],
///   which also throw the [ArgumentError].
/// - Its constructor takes `[AnyObject? cfg]` and calls [assign] with it, as
///   upstream calls `Object.assign(this, cfg)` (element.point.ts:57-59).
///   The fields start in the `undefined` state. Thus the constructor sets
///   only the start values that are not `undefined`, in the upstream order,
///   before [assign].
/// - Its static members `id`, `defaults`, `defaultRoutes` and `descriptors`
///   are static fields (Chart.js ADR 0017, section 2).
///
/// ```dart
/// class BoxElement extends Element implements types.VisualElement {
///   BoxElement([AnyObject? cfg]) {
///     if (cfg != null) assign(cfg);
///   }
///
///   double? _width;
///   bool? _horizontal;
///
///   double get width => _width ?? double.nan;
///   set width(double value) => _width = value;
///
///   bool? get horizontal => _horizontal;
///   set horizontal(bool value) => _horizontal = value;
///
///   @override
///   Object? operator [](String prop) => switch (prop) {
///     'width' => _width ?? undefined,
///     'horizontal' => _horizontal ?? undefined,
///     _ => super[prop],
///   };
///
///   @override
///   void operator []=(String prop, Object? value) {
///     switch (prop) {
///       case 'width':
///         _width = toNumberProp(prop, value);
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
class Element
    implements types.Element, types.ElementPropertyRead, ElementProps {
  /// core.element.ts:6 the implicit constructor of `Element`.
  ///
  /// [x], [y], [options] and [$animations] start in the `undefined` state.
  /// [active] starts false.
  Element();

  /// core.element.ts:8 `static defaults = {}`.
  static final AnyObject defaults = {};

  /// core.element.ts:9 `static defaultRoutes = undefined`: the [undefined]
  /// sentinel.
  static const Object defaultRoutes = undefined;

  /// The value of [x]. Dart `null` stands for JS `undefined`.
  double? _x;

  /// The value of [y]. Dart `null` stands for JS `undefined`.
  double? _y;

  /// The extra properties of the access by name: the properties that the
  /// element class does not declare. Dart `null` until the first write of
  /// such a property.
  Map<String, Object?>? _extras;

  /// core.element.ts:11 `x: number`.
  ///
  /// NaN in the `undefined` state, the start value. JS `null` never reaches
  /// it. `this['x']` gives [undefined] in that state.
  @override
  double get x => _x ?? double.nan;

  set x(double value) => _x = value;

  /// core.element.ts:12 `y: number`. NaN in the `undefined` state, as [x].
  @override
  double get y => _y ?? double.nan;

  set y(double value) => _y = value;

  /// core.element.ts:13 `active = false`.
  ///
  /// It is not optional. Thus a write by name accepts only a `bool`.
  bool active = false;

  /// core.element.ts:14 `options: O`, the resolved options of the element
  /// (Chart.js ADR 0006, ADR 0017 section 8).
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
    final props = getProps(const ['x', 'y'], useFinalPosition);
    return ElementPoint(jsToNumber(props['x']), jsToNumber(props['y']));
  }

  /// core.element.ts:22 `hasValue()`.
  ///
  /// [x] and [y] give NaN in the `undefined` state, and `isNumber` is false
  /// for both NaN and `undefined`.
  bool hasValue() {
    return isNumber(x) && isNumber(y);
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
    'x' => _x ?? undefined,
    'y' => _y ?? undefined,
    'active' => active,
    'options' => options ?? undefined,
    r'$animations' => $animations ?? undefined,
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
  /// - Another name stores [value] as it is in the Map of extra properties:
  ///   also Dart `null` for JS `null` and the [undefined] sentinel.
  ///
  /// Throws an [ArgumentError] for a value outside the type of a declared
  /// property. A subclass handles its own names first and passes the other
  /// names to `super`.
  void operator []=(String prop, Object? value) {
    switch (prop) {
      case 'x':
        _x = toNumberProp(prop, value);
      case 'y':
        _y = toNumberProp(prop, value);
      case 'active':
        active = toDefinedBoolProp(prop, value);
      case 'options':
        options = toObjectProp<Map<String, Object?>>(prop, value);
      case r'$animations':
        $animations = toObjectProp<Map<String, types.Animation>>(prop, value);
      default:
        (_extras ??= <String, Object?>{})[prop] = value;
    }
  }

  /// `Object.assign(this, source)`, the copy of a plain object into the
  /// element. The element constructors call it with their `cfg`
  /// (element.point.ts:58, element.arc.ts:349, element.bar.js:175,
  /// element.line.js:295). `updateElement` calls it with the new properties
  /// (core.datasetController.js:900).
  ///
  /// It writes each own key of [source] through [operator []=], in the
  /// `Object.keys` order ([jsObjectKeys]). Thus an `int` becomes a `double`,
  /// and a value outside the type of a declared property throws an
  /// [ArgumentError] after the writes of the keys before it.
  void assign(AnyObject source) {
    for (final key in jsObjectKeys(source)) {
      this[key] = source[key];
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
