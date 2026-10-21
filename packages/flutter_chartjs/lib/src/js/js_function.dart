// Original code, not ported from Chart.js: JS calls of user functions.

/// The JavaScript call of a function value, for ported code that calls a
/// function from the user or from options (Chart.js ADR 0006: "A scriptable
/// option is a Dart closure").
///
/// ## The convention
///
/// A JavaScript function value is one of these Dart values:
/// - a Dart [Function], for a function that does not read `this`. Its
///   parameters receive the arguments.
/// - a [JsFunction], for a function that reads `this`. Its closure receives
///   `this` as its first parameter, and the arguments after it.
///
/// [jsIsFunction] is `typeof value === 'function'` for these values, and for
/// a class value ([JsClass], Chart.js ADR 0020). A class value is a function
/// that needs `new`: [jsConstruct] constructs it, and [jsCall] throws for it.
/// Ported code calls a function value from the user or from options through
/// [jsCall], or through [jsCall1] for one argument. A direct call of a Dart
/// closure skips the rules below. Thus
/// ported code calls a closure directly only if the port itself made it and
/// it needs neither `this` nor the argument rules.
///
/// **Arguments.** A JavaScript call ignores the arguments that the function
/// does not declare. It gives `undefined` to the parameters that get no
/// argument. [jsCall] does the same with a Dart closure:
/// - It passes as many arguments as the closure takes. It drops the others.
/// - It pads the arguments to the count of the required positional
///   parameters with the [undefined] sentinel of `js_undefined.dart`.
/// - An optional positional parameter that gets no argument takes its Dart
///   default value.
///
/// For example, `each(['a', 'b'], (Object? item) { ... })` calls the closure
/// with the item only, although `each` passes the item and its index.
///
/// **`this`.** A JavaScript function reads `this` when a caller gives one,
/// for example through `callback(fn, args, thisArg)` or `each(loopable, fn,
/// thisArg)` of `helpers.core`, or as `this.chart` in a tick callback. Wrap
/// such a closure in a [JsFunction]:
///
/// ```dart
/// final scopes = <Object?>[];
/// each(
///   ['a', 'b'],
///   JsFunction((Object? self, Object? item, double index) {
///     scopes.add(self);
///   }),
///   scope,
/// );
/// ```
///
/// A [JsFunction] gets `this` exactly as the caller gives it, as a
/// strict-mode JavaScript function does. A call without a `this` value gives
/// [undefined]. Dart has no global object, so `null` and [undefined] do not
/// become `globalThis`, as they do for a sloppy-mode function.
///
/// **Results.** [jsCall] returns the result of the closure. A Dart closure
/// that returns nothing returns Dart `null`, which is JavaScript `null`. A
/// closure that must return JavaScript `undefined` returns the [undefined]
/// sentinel. For example, `noop` of `helpers.core` returns [undefined], and
/// the tooltip uses its default callback only for an `undefined` result
/// (`plugin.tooltip.js`, `invokeCallbackWithFallback`).
///
/// **Numbers.** Ported code passes each number as a `double` (Chart.js ADR
/// 0032). Declare a numeric parameter as `double`, `num` or `Object?`. An
/// `int` parameter throws a [TypeError] when it gets a `double`.
///
/// **Limits.**
/// - [jsCall] reads the parameter counts with function-type tests, such as
///   `function is Object? Function(Never, Never)`. It tests up to [jsMaxArity]
///   positional parameters.
/// - A closure with a required named parameter, a generic closure such as
///   `<T>(T value) => value`, and an object with a `call` method are not
///   function values for [jsCall]. Instantiate a generic closure first, for
///   example as `id<Object?>`.
/// - On the VM, [jsCall] calls a closure that takes 0 to 4 arguments with a
///   dynamic call, because `Function.apply` is about 10 times slower there. It
///   calls a closure that takes 5 to [jsMaxArity] arguments with
///   `Function.apply`. On the web (dart2js and dart2wasm), it always uses
///   `Function.apply`, which is as fast as a dynamic call there or faster.
///   The two calls give the same results and throw the same [TypeError] for
///   an argument of a wrong type.
library;

import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';

/// A JavaScript function that reads `this`.
///
/// The first parameter of [function] receives `this`. The other parameters
/// receive the arguments, with the rules of [jsCall].
final class JsFunction {
  /// Wraps [function], whose first parameter receives `this`.
  const JsFunction(this.function);

  /// The closure. Its first parameter is `this`.
  final Function function;
}

/// The largest count of positional parameters that [jsCall] tests: 8.
const int jsMaxArity = 8;

/// `typeof value === 'function'`: whether [value] is a Dart [Function], a
/// [JsFunction] or a class value ([JsClass]).
///
/// `typeof C` is `'function'` for a class `C` (Chart.js ADR 0020, section 2).
/// Thus `isFunction` of `helpers.core` gives true for a class value, and
/// `callback` calls [jsCall] for it, as upstream calls the class.
bool jsIsFunction(Object? value) =>
    value is Function || value is JsFunction || value is JsClass;

/// `function.apply(thisArg, args)`, `function.call(thisArg, ...args)` and
/// `function(...args)`: calls [function] with [args] and returns its result.
///
/// [function] is a Dart [Function] or a [JsFunction] (see the library
/// documentation). A [JsFunction] gets [thisArg] as its first argument. A
/// Dart [Function] does not get [thisArg].
///
/// The call passes as many of [args] as the closure takes, and pads them with
/// [undefined] to the count of its required positional parameters. It does
/// not change [args].
///
/// Throws an [ArgumentError] if [function] is not a function value, where
/// JavaScript throws a `TypeError`. Also throws an [ArgumentError] for a
/// class value ([JsClass]), where JavaScript throws a `TypeError`, because a
/// class constructor needs `new` (Chart.js ADR 0020, section 2). `callback`
/// and the resolver reach this throw where upstream reaches its throw. Also
/// throws an [ArgumentError] if the closure takes no count of positional
/// arguments up to [jsMaxArity] (for example, a closure with a required named
/// parameter).
Object? jsCall(
  Object? function,
  List<Object?> args, {
  Object? thisArg = undefined,
}) {
  return switch (function) {
    final JsFunction f =>
      _web
          ? _apply(f.function, [thisArg, ...args])
          : _applyThis(f.function, args, thisArg),
    final Function f => _apply(f, args),
    _ => throw ArgumentError.value(function, 'function', 'is not a function'),
  };
}

/// `function(arg)` and `function.call(thisArg, arg)`: [jsCall] with the one
/// argument [arg].
///
/// The result is the result of `jsCall(function, [arg], thisArg: thisArg)`,
/// and it throws the same errors. On the VM, a Dart [Function] that takes
/// one argument gets [arg] with a dynamic call and no argument list. Each
/// other call goes through [jsCall]. On the web, it is that [jsCall] call:
/// a list costs no more there.
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
Object? jsCall1(Object? function, Object? arg, {Object? thisArg = undefined}) {
  if (!_web && function is Function && _takes(function, 1)) {
    // The dynamic call of [_invoke] for one argument: [_apply] gives this
    // closure [arg] alone.
    return (function as dynamic)(arg);
  }
  return jsCall(function, [arg], thisArg: thisArg);
}

/// Calls [function] with the first arguments of [args] that it takes, padded
/// with [undefined] to its required positional parameters.
///
/// On the web, this is the plain `Function.apply` call, for a [JsFunction]
/// too. On the VM, a closure that takes 0 to 4 arguments gets a dynamic call
/// ([_invoke]).
Object? _apply(Function function, List<Object?> args) {
  final count = args.length;
  // The counts that a closure takes are one range: from its required
  // positional parameters to all its positional parameters. The first loop
  // finds the largest count up to [count]: [count] itself, or the count after
  // the extra arguments are dropped.
  for (var k = count < jsMaxArity ? count : jsMaxArity; k >= 0; k--) {
    if (_takes(function, k)) {
      if (_web || k > 4) {
        return Function.apply(function, k == count ? args : args.sublist(0, k));
      }
      return _invoke(function, args, 0, undefined, k);
    }
  }
  // Else the closure needs more arguments: pad them with undefined.
  for (var k = count + 1; k <= jsMaxArity; k++) {
    if (_takes(function, k)) {
      if (_web || k > 4) {
        return Function.apply(function, [
          ...args,
          for (var i = count; i < k; i++) undefined,
        ]);
      }
      return _invoke(function, args, 0, undefined, k);
    }
  }
  throw ArgumentError.value(
    function,
    'function',
    'takes no positional argument count up to $jsMaxArity',
  );
}

/// [_apply] for a [JsFunction] on the VM: the arguments are [thisArg], then
/// [args].
///
/// It does not make the list `[thisArg, ...args]`. A closure that takes 0 to
/// 4 arguments gets them with no list. Else `Function.apply` gets one list of
/// the arguments that the closure takes. The web calls [_apply] with
/// `[thisArg, ...args]` instead, so the web compilers drop this function.
Object? _applyThis(Function function, List<Object?> args, Object? thisArg) {
  final count = 1 + args.length;
  // The two loops of [_apply].
  for (var k = count < jsMaxArity ? count : jsMaxArity; k >= 0; k--) {
    if (_takes(function, k)) {
      if (k > 4) return Function.apply(function, _list(args, 1, thisArg, k));
      return _invoke(function, args, 1, thisArg, k);
    }
  }
  for (var k = count + 1; k <= jsMaxArity; k++) {
    if (_takes(function, k)) {
      if (k > 4) return Function.apply(function, _list(args, 1, thisArg, k));
      return _invoke(function, args, 1, thisArg, k);
    }
  }
  throw ArgumentError.value(
    function,
    'function',
    'takes no positional argument count up to $jsMaxArity',
  );
}

/// Whether [function] can take [count] positional arguments and no named
/// argument.
///
/// A parameter of type `Never` accepts every parameter type, because
/// parameter types are contravariant. A return type of `Object?` accepts
/// every return type, `void` included.
bool _takes(Function function, int count) => switch (count) {
  0 => function is Object? Function(),
  1 => function is Object? Function(Never),
  2 => function is Object? Function(Never, Never),
  3 => function is Object? Function(Never, Never, Never),
  4 => function is Object? Function(Never, Never, Never, Never),
  5 => function is Object? Function(Never, Never, Never, Never, Never),
  6 => function is Object? Function(Never, Never, Never, Never, Never, Never),
  7 =>
    function
        is Object? Function(Never, Never, Never, Never, Never, Never, Never),
  8 =>
    function
        is Object? Function(
          Never,
          Never,
          Never,
          Never,
          Never,
          Never,
          Never,
          Never,
        ),
  _ => false,
};

/// Whether the compiler is dart2js or dart2wasm.
///
/// `dart:js_interop` is available on both web compilers and not on the VM.
/// On the web, `Function.apply` is as fast as a dynamic call or faster. On
/// the VM, it is about 10 times slower.
const bool _web = bool.fromEnvironment('dart.library.js_interop');

/// The first [k] arguments as a list: [thisArg] before [offset], then the
/// items of [args], then [undefined]. For `Function.apply`.
List<Object?> _list(List<Object?> args, int offset, Object? thisArg, int k) => [
  for (var i = 0; i < k; i++) _arg(args, offset, thisArg, i),
];

/// Calls [function] with its first [k] arguments, with a dynamic call and no
/// argument list. The arguments are [thisArg] before [offset], then the items
/// of [args], then [undefined]. [_takes] has already checked that [function]
/// takes [k] positional arguments, and [k] is 0 to 4.
///
/// [_apply] and [_applyThis] call it on the VM only. Else they call
/// `Function.apply`. The closure checks the types of its arguments in both
/// calls, and throws the same [TypeError].
Object? _invoke(
  Function function,
  List<Object?> args,
  int offset,
  Object? thisArg,
  int k,
) {
  final f = function as dynamic;
  // The dynamic calls below are the point of this function: a cast to a
  // function type cannot replace them, because a closure that declares a
  // `double` parameter is not an `Object? Function(Object?)`.
  return switch (k) {
    // A closure call by arity (see above).
    // ignore: avoid_dynamic_calls
    0 => f(),
    // A closure call by arity (see above).
    // ignore: avoid_dynamic_calls
    1 => f(_arg(args, offset, thisArg, 0)),
    // A closure call by arity (see above).
    // ignore: avoid_dynamic_calls
    2 => f(_arg(args, offset, thisArg, 0), _arg(args, offset, thisArg, 1)),
    // A closure call by arity (see above).
    // ignore: avoid_dynamic_calls
    3 => f(
      _arg(args, offset, thisArg, 0),
      _arg(args, offset, thisArg, 1),
      _arg(args, offset, thisArg, 2),
    ),
    // A closure call by arity (see above).
    // ignore: avoid_dynamic_calls
    _ => f(
      _arg(args, offset, thisArg, 0),
      _arg(args, offset, thisArg, 1),
      _arg(args, offset, thisArg, 2),
      _arg(args, offset, thisArg, 3),
    ),
  };
}

/// The argument at [index]: [thisArg] before [offset], then the items of
/// [args], then [undefined].
@pragma('vm:prefer-inline')
Object? _arg(List<Object?> args, int offset, Object? thisArg, int index) {
  if (index < offset) return thisArg;
  final i = index - offset;
  return i < args.length ? args[i] : undefined;
}
