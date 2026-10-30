// Original code, not ported from Chart.js: the option cell of the typed model.

/// The option cell of the typed internal model (Chart.js ADR 0054 §1).
///
/// A typed option scope holds one [Opt] cell for each key that it owns. A
/// field of the type `Opt<T>?` is Dart `null` for an absent key. The three
/// JS states of a key stay apart:
/// - an absent key: the field is Dart `null`;
/// - an own key with the value `undefined`: [optUndefined];
/// - an own key with the value JS `null`: [optNull].
///
/// The other cases keep the value as the user gave it:
/// - [OptValue]: a value of the type of the key (a number as a `double`);
/// - [OptFunction]: a function value (a scriptable option, or a callback);
/// - [OptList]: an array (an indexable option, or a plain array);
/// - [OptScope]: a nested option object: a typed scope or a raw Map;
/// - [OptForeign]: any other JS value, outside the type of the key.
///
/// The type parameter `T` is the type of the key. The classification
/// functions ([classifyNumber], [classifyBool], [classifyString],
/// [classifyScope] and [classifyUnion]) give the cell of a raw JS value for a
/// key of a given shape. The order of their tests is the order of the
/// resolver: `undefined`, `null`, a function, an array, an object, then the
/// plain value.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsIsFunction;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// One option value of a typed scope (Chart.js ADR 0054 §1).
sealed class Opt<T> {
  const Opt();

  /// The JS value of the cell, as the user gave it: [undefined] for
  /// [OptUndefined] and Dart `null` (JS `null`) for [OptNull].
  Object? get raw;
}

/// A value of the type of the key.
final class OptValue<T> extends Opt<T> {
  /// The cell of [value].
  const OptValue(this.value);

  /// The value. A JS number is a `double`.
  final T value;

  @override
  Object? get raw => value;

  @override
  String toString() => 'OptValue($value)';
}

/// A function value: a Dart `Function`, a `JsFunction` or a class value
/// (`jsIsFunction`).
final class OptFunction<T> extends Opt<T> {
  /// The cell of [function].
  const OptFunction(this.function);

  /// The function value, as the user gave it.
  final Object function;

  @override
  Object? get raw => function;

  @override
  String toString() => 'OptFunction($function)';
}

/// An array, as the user gave it (the same List).
final class OptList<T> extends Opt<T> {
  /// The cell of [items].
  const OptList(this.items);

  /// The array.
  final List<Object?> items;

  @override
  Object? get raw => items;

  @override
  String toString() => 'OptList($items)';
}

/// A nested option object: a typed scope or a raw `Map<String, Object?>`
/// (the same object).
final class OptScope<T> extends Opt<T> {
  /// The cell of [scope].
  const OptScope(this.scope);

  /// The nested object.
  final Object scope;

  @override
  Object? get raw => scope;

  @override
  String toString() => 'OptScope(${scope.runtimeType})';
}

/// An own key with the value `undefined`.
final class OptUndefined extends Opt<Never> {
  const OptUndefined._();

  @override
  Object? get raw => undefined;

  @override
  String toString() => 'OptUndefined';
}

/// An own key with the value JS `null`.
final class OptNull extends Opt<Never> {
  const OptNull._();

  @override
  Object? get raw => null;

  @override
  String toString() => 'OptNull';
}

/// A JS value outside the type of the key, kept as given (Chart.js ADR 0054
/// §6), for example the string `'5'` of a number key.
final class OptForeign<T> extends Opt<T> {
  /// The cell of [value].
  const OptForeign(this.value);

  /// The value, as the user gave it.
  final Object value;

  @override
  Object? get raw => value;

  @override
  String toString() => 'OptForeign($value)';
}

/// The cell of an own key with the value `undefined`.
const Opt<Never> optUndefined = OptUndefined._();

/// The cell of an own key with the value JS `null`.
const Opt<Never> optNull = OptNull._();

/// The atoms of a shape of the schema (`tool/options_schema.yaml`), as bits
/// of an `int` mask for [classifyUnion].
abstract final class ShapeBits {
  /// `number`: a JS number.
  static const int number = 1;

  /// `bool`.
  static const int boolean = 2;

  /// `string`.
  static const int string = 4;

  /// `fn`: a plain function value.
  static const int function = 8;

  /// `list`: a plain array value.
  static const int list = 16;

  /// `scope <Kind>`: a nested option object.
  static const int scope = 32;

  /// `any`: any JS value.
  static const int any = 64;
}

/// The cell of [raw] for the special values, or Dart `null` for a plain
/// value: `undefined`, `null`, a function, an array and an object.
Opt<T>? _special<T>(Object? raw) {
  if (raw == null) return optNull;
  if (raw is Undefined) return optUndefined;
  if (jsIsFunction(raw)) return OptFunction<T>(raw);
  if (raw is List<Object?>) return OptList<T>(raw);
  if (raw is Map<String, Object?> || raw is OptionObject) {
    return OptScope<T>(raw);
  }
  return null;
}

/// A typed option object that a cell can hold as a nested scope: the base
/// of the typed scope classes (`option_scope.dart`).
abstract interface class OptionObject {}

/// The cell of [raw] for a key of the shape `number`.
Opt<double> classifyNumber(Object? raw) =>
    _special<double>(raw) ??
    (raw is num ? OptValue<double>(raw.toDouble()) : OptForeign<double>(raw!));

/// The cell of [raw] for a key of the shape `bool`.
Opt<bool> classifyBool(Object? raw) =>
    _special<bool>(raw) ??
    (raw is bool ? OptValue<bool>(raw) : OptForeign<bool>(raw!));

/// The cell of [raw] for a key of the shape `string`.
Opt<String> classifyString(Object? raw) =>
    _special<String>(raw) ??
    (raw is String ? OptValue<String>(raw) : OptForeign<String>(raw!));

/// The cell of [raw] for a key of the shape `scope <Kind>`: an object is an
/// [OptScope], another plain value is foreign.
Opt<S> classifyScope<S>(Object? raw) => _special<S>(raw) ?? OptForeign<S>(raw!);

/// The cell of [raw] for a key whose shape is a union of the atoms of
/// [mask] ([ShapeBits]), or `any`. A JS number is a `double`.
Opt<Object> classifyUnion(Object? raw, int mask) {
  final special = _special<Object>(raw);
  if (special != null) return special;
  final value = raw!;
  if (mask & ShapeBits.any != 0) {
    return OptValue<Object>(value is num ? value.toDouble() : value);
  }
  return switch (value) {
    final num n when mask & ShapeBits.number != 0 => OptValue<Object>(
      n.toDouble(),
    ),
    bool() when mask & ShapeBits.boolean != 0 => OptValue<Object>(value),
    String() when mask & ShapeBits.string != 0 => OptValue<Object>(value),
    _ => OptForeign<Object>(value),
  };
}

/// The cell of [raw] for a key of the shape bits [mask] ([ShapeBits]): the
/// classification of [classifyNumber], [classifyBool], [classifyString] or
/// [classifyScope] for a shape of one atom, else [classifyUnion].
Opt<Object?> classifyMask(Object? raw, int mask) => switch (mask) {
  ShapeBits.number => classifyNumber(raw),
  ShapeBits.boolean => classifyBool(raw),
  ShapeBits.string => classifyString(raw),
  ShapeBits.scope => classifyScope<Object>(raw),
  _ => classifyUnion(raw, mask),
};
