// Original code, not ported from Chart.js: the function types of option values.

/// The function types of the option values that the resolvers call
/// (Chart.js ADR 0173).
///
/// Upstream calls a function value of the options with JavaScript rules: a
/// function takes the arguments that it declares and ignores the others.
/// The port calls each one as a Dart function of a fixed type:
///
/// - A scriptable option is a [ScriptableOption] (`(context) => value`), a
///   [ScriptableOptionWithResolver] (`(context, options) => value`) or a
///   function with no parameter (`() => value`). [callScriptable] calls it.
/// - The descriptors `_scriptable` and `_indexable` are a
///   [DescriptorPredicate] (`(name) => bool`).
/// - A function `_fallback` is a [ResolverFallback] (`(name, value) =>
///   fallback`).
///
/// No function gets `this`. A function of another type stops a debug build,
/// and a release build makes no call: the value is `undefined`.
///
/// This library is a pure layer.
library;

import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:meta/meta.dart';

/// A scriptable option with one parameter: `(context) => value`.
///
/// The context is the context object of the element, the dataset or the
/// chart (`docs/general/options.md`, "Option Context"). Declare the
/// parameter as `Object?` or with no type: a spec or a plugin can give a Map
/// as the context.
typedef ScriptableOption = Object? Function(Object? context);

/// A scriptable option with two parameters: `(context, options) => value`.
///
/// The second parameter gets the options resolver of the scope
/// (helpers.config.ts:264).
typedef ScriptableOptionWithResolver = Object? Function(
  Object? context,
  Object? options,
);

/// A descriptor `_scriptable` or `_indexable` as a function of the option
/// name. The resolver reads the ToBoolean of its result.
typedef DescriptorPredicate = Object? Function(String name);

/// A function `_fallback` of a scope: `(name, value) => fallback`
/// (helpers.config.ts:298).
typedef ResolverFallback = Object? Function(Object? name, Object? value);

/// The count of the calls of a function value of the app or of the options
/// through this library. An equal count at two moments proves that no such
/// call ran between them. The index of the `skipNull` search of a bar update
/// reads it (row `adapt-bar-skip-null-index`).
@internal
int appFunctionCalls = 0;

/// Calls the scriptable option [function] with [context], and with
/// [options] when it takes two parameters (helpers.config.ts:264 and
/// helpers.options.ts:121).
///
/// [options] is `undefined` when the caller has no resolver, as upstream
/// passes no second argument.
Object? callScriptable(
  Object? function,
  Object? context, [
  Object? options = undefined,
]) {
  appFunctionCalls++;
  return switch (function) {
    final ScriptableOptionWithResolver f => f(context, options),
    final ScriptableOption f => f(context),
    final Object? Function() f => f(),
    _ => _foreign(
      function,
      'a scriptable option takes (context), (context, options) or ()',
    ),
  };
}

/// Calls the descriptor [predicate] with [name], or gives [predicate] when it
/// is not a function (helpers.config.ts:209-210).
Object? callDescriptor(Object? predicate, String name) {
  if (predicate is! Function) return predicate;
  appFunctionCalls++;
  if (predicate is DescriptorPredicate) return predicate(name);
  return _foreign(predicate, 'a descriptor takes (name)');
}

/// Calls the fallback [fallback] with [name] and [value], or gives
/// [fallback] when it is not a function (helpers.config.ts:298).
Object? callFallback(Object? fallback, Object? name, Object? value) {
  if (fallback is! Function) return fallback;
  appFunctionCalls++;
  if (fallback is ResolverFallback) return fallback(name, value);
  return _foreign(fallback, 'a _fallback takes (name, value)');
}

/// A function of another type: a debug build stops, a release build gives
/// `undefined`.
Object? _foreign(Object? function, String rule) {
  assert(false, 'The option function $function has another type: $rule.');
  return undefined;
}
