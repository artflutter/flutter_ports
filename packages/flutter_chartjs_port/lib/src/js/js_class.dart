// Original code, not ported from Chart.js: JS class values.

/// A JavaScript class as a value, for ported code that keeps a class in an
/// object, reads its static properties by name or constructs it later
/// (Chart.js ADR 0020, sections 1 and 2).
///
/// Dart has no class values. A Dart `Type` has no static members, no
/// superclass and no constructor, and a Dart subclass does not inherit
/// static members. Chart.js keeps classes in objects: the registry
/// (`core.registry.js:13-16`), `Object.assign` on a controller class
/// (`core.controller.js:443-447`) and `new this.dataElementType()`
/// (`core.datasetController.js:1009`). A [JsClass] stands for such a value:
///
/// ```dart
/// // class CustomController extends DatasetController {}
/// // CustomController.id = 'custom';
/// final customController = JsClass(
///   'CustomController',
///   superclass: DatasetController.jsClass,
/// )..['id'] = 'custom';
/// ```
///
/// A ported class that upstream registers, keeps as a value or constructs
/// from a value has a static field `jsClass` (Chart.js ADR 0020, section 3).
/// Its `statics` hold the objects of the Dart static fields. Thus
/// `PointElement.defaults` and `PointElement.jsClass['defaults']` are one
/// Map.
///
/// This library is a pure layer. It imports neither `dart:ui` nor
/// `package:flutter`.
library;

import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// The type of [_absent].
final class _Absent {
  const _Absent();
}

/// The value of the slot of `id` when the class value has no own `id`.
const Object _absent = _Absent();

/// The `[[Construct]]` of a class value: `new newTarget(...args)`.
///
/// [newTarget] is `new.target`: the class value that [jsConstruct] got. It
/// differs from the class value that owns the closure when a subclass
/// without a `construct` of its own inherits the closure.
typedef JsConstruct = Object Function(JsClass newTarget, List<Object?> args);

/// A JavaScript class as a value (Chart.js ADR 0020, section 1).
///
/// - A static property is a property of the class value. The own static
///   properties keep their insertion order.
/// - [operator []] gives the own value of a key. Else it gives the value of
///   the nearest superclass that has the key, as the static prototype chain
///   gives. Else it gives [undefined]. Thus a subclass reads the `defaults`,
///   `overrides`, `defaultRoutes`, `descriptors` and register callbacks of
///   its superclass (`core.typedRegistry.js:25-50`, `core.registry.js:151`).
/// - [operator []=] always writes an own static property. It never changes
///   a superclass. `Object.assign(MyLine, {dataElementType})` also leaves
///   `LineController.dataElementType` as it is.
/// - [id] has a typed slot beside the own static properties. [operator []=]
///   writes both.
/// - The function properties `length`, `name` and `prototype` are not static
///   properties. No ported code reads them by name. A class value has no
///   `delete` and no `Object.keys`: no ported code deletes or enumerates a
///   static property.
/// - Equality is identity, as `===` of two class values.
final class JsClass {
  /// `class <name> extends <superclass> { static ... }`.
  ///
  /// `statics` are the static properties of the class body, in their order
  /// of declaration. The constructor writes them through [operator []=].
  /// `construct` is the `[[Construct]]` of the class. A class value without
  /// `construct` uses the closure of its nearest superclass that has one
  /// ([jsConstruct]).
  JsClass(
    this.name, {
    this.superclass,
    this._construct,
    Map<String, Object?>? statics,
  }) {
    if (statics != null) {
      for (final MapEntry(:key, :value) in statics.entries) {
        this[key] = value;
      }
    }
  }

  /// `C.name`, the class name. [toString] reads it.
  final String name;

  /// `Object.getPrototypeOf(C)` when it is a class value.
  ///
  /// Dart `null` for a base class, whose static prototype is
  /// `Function.prototype`.
  final JsClass? superclass;

  /// The `[[Construct]]` of this class value, or Dart `null` for the
  /// implicit constructor.
  final JsConstruct? _construct;

  /// The own static properties, in insertion order.
  final Map<String, Object?> _statics = <String, Object?>{};

  /// The own value of `id`, or [_absent] without an own `id`.
  Object? _id = _absent;

  /// `C.id`: the `id` of the nearest class value with an own `id`, or
  /// [undefined].
  ///
  /// It is the read `C['id']` with a typed slot in place of a Map lookup. The
  /// dataset controller (`core.datasetController.js:789`, `:798`) reads it,
  /// through `_idOf` in `core.datasetController.dart`. The other reads of
  /// `id`, for example in the registry, use `jsGet` and so the operator `[]`.
  Object? get id {
    for (JsClass? c = this; c != null; c = c.superclass) {
      final id = c._id;
      if (!identical(id, _absent)) return id;
    }
    return undefined;
  }

  /// `C[key]`: a `[[Get]]` through the static prototype chain.
  ///
  /// The own value of [key], else the value of the nearest superclass that
  /// has [key], else [undefined]. An own key with the value JS `null` gives
  /// Dart `null`.
  Object? operator [](String key) {
    for (JsClass? c = this; c != null; c = c.superclass) {
      final statics = c._statics;
      final value = statics[key];
      if (value != null || statics.containsKey(key)) return value;
    }
    return undefined;
  }

  /// `C[key] = value`: a write of an own static property.
  ///
  /// A key that the class value has already keeps its position.
  void operator []=(String key, Object? value) {
    _statics[key] = value;
    if (key == 'id') _id = value;
  }

  /// `key in C`: whether this class value or a superclass has the static
  /// property [key].
  bool has(String key) {
    for (JsClass? c = this; c != null; c = c.superclass) {
      if (c._statics.containsKey(key)) return true;
    }
    return false;
  }

  /// `Object.prototype.isPrototypeOf.call(other.prototype, C.prototype)`
  /// (`core.typedRegistry.js:16-18`).
  ///
  /// True when [other] is a superclass of this class value, at any depth.
  /// The class value itself does not count. [jsObjectClass] counts for each
  /// class value other than itself, because each class prototype inherits
  /// from `Object.prototype`.
  bool isSubclassOf(JsClass other) {
    if (identical(other, jsObjectClass)) return !identical(this, other);
    for (var c = superclass; c != null; c = c.superclass) {
      if (identical(c, other)) return true;
    }
    return false;
  }

  /// `String(C)`: `'class <name> {}'`.
  ///
  /// JavaScript gives the source text of the class. The two texts are the
  /// same for a class without a body and without `extends`, for example
  /// `class FaultyPlugin {}` (`core.registry.tests.js:88-92`).
  // DIVERGES(chartjs): js-semantics-class-source, no source text.
  @override
  String toString() => 'class $name {}';
}

/// The JavaScript constructor `Object` as a class value: the type of the
/// plugins registry (`core.registry.js:15`).
///
/// It has no static property and no `construct`. Thus `new Object()` gives a
/// new empty Map ([jsConstruct]).
final JsClass jsObjectClass = JsClass('Object');

/// `new target(...args)`: constructs the class value [target] with [args].
///
/// It calls the `construct` closure of [target] with [target] as
/// `new.target`. A class value without a closure uses the closure of its
/// nearest superclass that has one, with the same `new.target`. This is the
/// implicit constructor of a derived class,
/// `constructor(...args) { super(...args); }`. A class value without a
/// closure in its chain gives a new empty `Map<String, Object?>`, as `new` of
/// a class without a constructor gives a new plain object.
///
/// Throws a [TypeError] for a value that is not a class value, as `new` of a
/// value that is not a constructor does: `null`, [undefined], a Map, a
/// number, an arrow function or a method.
Object jsConstruct(Object? target, List<Object?> args) {
  // A JavaScript TypeError: `new` of a value that is not a constructor.
  if (target is! JsClass) throw TypeError();
  for (JsClass? c = target; c != null; c = c.superclass) {
    final construct = c._construct;
    if (construct != null) return construct(target, args);
  }
  return <String, Object?>{};
}

/// `Object.assign(target, source)` for a class value or a Map [target].
///
/// It writes each key of `Object.keys(source)` ([jsObjectKeys]) with the
/// value `source[key]`, in that order: through [JsClass.operator []=] for a
/// class value, and with a Map write for a Map. A write of a present key
/// keeps the position of the key. It returns [target].
///
/// Throws a [TypeError] for Dart `null` and [undefined], as `Object.assign`
/// does. Throws an [ArgumentError] for another target. No ported code passes
/// one: `Object.assign` on an element is `Element.assign` (Chart.js ADR 0017,
/// section 6).
Object jsAssign(Object? target, Map<String, Object?> source) {
  switch (target) {
    case null || Undefined():
      // A JavaScript TypeError: ToObject of null or undefined.
      throw TypeError();
    case final JsClass value:
      for (final key in jsObjectKeys(source)) {
        value[key] = source[key];
      }
    case final Map<dynamic, dynamic> map:
      for (final key in jsObjectKeys(source)) {
        map[key] = source[key];
      }
    default:
      throw ArgumentError.value(
        target,
        'target',
        'is not a class value or a Map',
      );
  }
  return target;
}
