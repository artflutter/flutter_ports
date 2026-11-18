// Original code, not ported from Chart.js: a test call with JS arity.

/// The call of a function of a spec port with the arguments that it takes,
/// as JavaScript drops the extra arguments (Chart.js ADR 0173).
///
/// The library has no such call: an option function has a fixed Dart type.
/// A spec port uses [callDroppingExtraArgs] only where the upstream spec
/// gives one function more arguments than it declares, for example a
/// Jasmine spy that calls through, or a plugin hook of the reference data.
library;

/// Calls [function] with the first arguments of [args] that it takes, up to
/// four. Throws an [ArgumentError] when [function] is not a function or
/// needs more arguments.
Object? callDroppingExtraArgs(Object? function, List<Object?> args) {
  if (function is! Function) {
    throw ArgumentError.value(function, 'function', 'is not a function');
  }
  for (var count = args.length < 4 ? args.length : 4; count >= 0; count--) {
    final takes = switch (count) {
      0 => function is Object? Function(),
      1 => function is Object? Function(Never),
      2 => function is Object? Function(Never, Never),
      3 => function is Object? Function(Never, Never, Never),
      _ => function is Object? Function(Never, Never, Never, Never),
    };
    if (takes) return Function.apply(function, args.sublist(0, count));
  }
  throw ArgumentError.value(function, 'function', 'takes more arguments');
}
