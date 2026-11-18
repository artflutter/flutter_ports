# Chart.js ADR 0173: Fixed Dart types for the option functions

- Status: accepted (2026-11-18): its code and the tests of section Tests pass.
- Date: 2026-11-18
- Supersedes: of [Chart.js ADR 0024](0024-dates.md) §1, the item "Dispatch"; of
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §2, the item on `jsIsFunction` and the call of a class
  value through `callback`.
- Related: [Chart.js ADR 0130](0130-native-callback-options.md), [Chart.js ADR 0144](0144-native-plugins.md),
  [Chart.js ADR 0153](0153-bar-skip-null-index.md), [Chart.js ADR 0034](0034-no-display-only-js-exactness.md)

## Context

Upstream calls a function value of the options with JavaScript rules. A function takes the arguments that it
declares and ignores the others. A caller can give it `this`. The port had `lib/src/js/js_function.dart` for this:
`jsCall` tested the parameter count of a closure with up to 9 function-type tests, padded or dropped the
arguments, and made a dynamic call or a `Function.apply` call. `JsFunction` wrapped a closure that reads `this`.

Chart.js ADR 0130 gave the callback options fixed types. The other function values still went through `jsCall`:
the scriptable options, the descriptors `_scriptable` and `_indexable`, the function `_fallback`, `callback` and
`each` of `helpers.core`, the date adapter members, the registry hooks, the draw of the dataset element and the
`setContext` of spec options.

## Decision

1. **A scriptable option has one of three types.** It is `ScriptableOption`, `(context) => value`,
   `ScriptableOptionWithResolver`, `(context, options) => value`, or a function with no parameter,
   `() => value`, as many upstream specs write it. `callScriptable` of `lib/src/types/option_functions.dart`
   calls it, with no `this`. The context parameter is `Object?`: a spec or a plugin can give a Map as the
   context.

   ```dart
   'backgroundColor': (ctx) => (ctx! as ScriptableContext).index == 0 ? red : blue,
   ```

2. **The resolver functions have fixed types.** A descriptor `_scriptable` or `_indexable` is a
   `DescriptorPredicate`, `(name) => bool` (`callDescriptor`). A function `_fallback` is a `ResolverFallback`,
   `(name, value) => fallback` (`callFallback`).
3. **Another type stops a debug build.** An option function of another type fails an assert. A release build
   makes no call and gives `undefined`.
4. **`this` becomes a parameter.** A date adapter member takes the arguments of its method, or the adapter first
   and then the arguments. A registry hook takes the component, or no argument.
   `parseObjectDataRadialScale` takes the controller first. The draw of a dataset element gets `start` and
   `count` only when its `draw` takes them.
5. **`callback` and `each` are typed.** `callback(fn, args)` calls a Dart `Function` with the exact arguments
   through `Function.apply`, and has no `thisArg`. `each<T, K>(loopable, fn, [reverse])` takes
   `void Function(T value, K key)` and casts each value and key.
6. **One count of the calls.** `appFunctionCalls` counts each call of an option function and of `callback`. The
   index of the `skipNull` search reads it (Chart.js ADR 0153, item 4).
7. **No JS function runtime.** `lib/src/js/js_function.dart` goes, with `jsCall`, `jsCall1`, `JsFunction`,
   `jsIsFunction` and `jsMaxArity`. `isFunction` of `helpers.core` is `value is Function || value is JsClass`.
   The app library and `chartjs.dart` export the four typedefs. Row `adapt-option-function-types` has the
   difference.

## Rejected

- Keep `jsCall` for raw configs only: the probes ran on each scriptable read of each element.
- A dynamic call for a closure with a narrow parameter type, for example `(ScriptableContext ctx) => ...`: it is
  the `jsCall` path again, and a typed context belongs to the typed API (`ChartScript`).

## Consequences

- A scriptable closure with a narrow parameter type, for example `(ScriptableScaleContext ctx) => ...`, stops a
  debug build. Declare the parameter as `Object?` or with no type, and cast in the body.
- A closure with one parameter where upstream passes more, for example `(value) => ...` as a date adapter
  `parse`, stops a debug build. Declare each parameter.
- No upstream spec case reads `this` of an option function now. The case `should call fn with the given scope`
  of `helpers.core.tests.js` skips with `diverges: adapt-option-function-types`.
- An add-on port that imported `jsCall` from `js_semantics.dart` does not compile. The zoom and sankey ports do
  not import it.

## Tests

- `test/port/helpers/helpers.core_test.dart` (groups `callback`, `each` and `isFunction`)
- `test/port/helpers/helpers.config_test.dart` (group `the descriptor functions`)
- `test/port/core/core.adapters_test.dart`, `test/port/core/varying_color_resolution_test.dart`
- `test/port/controllers/bar_skip_null_test.dart` (the count of the calls)
- The full test list of AGENTS.md before a push.
