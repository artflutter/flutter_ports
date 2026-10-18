# Chart.js ADR 0006: Options representation and resolver

- Status: accepted (2026-10-18)
- Date: 2026-10-17

## Context

Chart.js resolves options through `Proxy` objects. `_createResolver` (`helpers.config.ts:27-108`)
and `_attachContext` (`:118-195`) each define seven traps: `deleteProperty`, `get`,
`getOwnPropertyDescriptor`, `getPrototypeOf`, `has`, `ownKeys` and `set`. `Config` builds ordered
scope lists over the dataset, the options, `overrides[type]`, `defaults` and `descriptors`
(`getOptionScopes` and `chartOptionScopes`, `core.config.js:296`, `:331`). Dart has no `Proxy`.
[porting-flow.md](../porting-flow.md) §2.1 proposed this decision. Its gate is phase 2, because
phase 2 ports `helpers.config`, `mergeIf` and the `core.defaults` closure.

JavaScript has two empty values. The resolver goes to the next scope only on `undefined`
(`helpers.config.ts:38`, `:204`, `:399`, `:413`). `null` is a value. Three other places test
own-key presence:
- `_mergerIf` merges a key only if the target does not own it (`helpers.core.ts:310-323`).
- `_cached` returns an owned value, also an owned `undefined` (`helpers.config.ts:223`).
- Defaults store `undefined` as a declared-key marker, for example `pointStyle: undefined`
  (`element.bar.js:153`). `Object.keys` enumerates that marker (`core.datasetController.js:817`).

The research of 2026-10-16 measured these facts:
- In 16 of 19 probed cases, `null` and an absent key give different results in chart.js 4.5.1.
  For example, `plugins.legend: null` disables the plugin. `dataset.stack: null` stacks the
  datasets.
- A Dart prototype with `Map<String, Object?>` scopes passed 47 tests. 17 of them port
  `helpers.config.tests.js` cases line by line.
- With AOT, the prototype costs 60 ns per bar element with static options and 1,330 ns with
  scriptable options. chart.js in Node.js takes 37 ns and 1,760 ns.
- On dart2js, the Map resolver is about 1.6× slower than V8 on the scriptable path.
- Between 529 (verifier count) and 549 fixture configs are pure data. `jsonDecode` output enters a
  Map scope unchanged.
- The typed models of other Chart.js packages give the resolution to the real Chart.js. All of
  them treat `null` as "not set".

## Decision

- **Scopes are Maps.** An option scope is a `Map<String, Object?>`. A JS plain object is a
  `Map<String, Object?>`. A JS array is a `List<Object?>`. A scriptable option is a Dart closure.
  Every other Dart object is a leaf value.
- **Three states.** The port keeps three JS states apart:
  - an absent key: no own property in JS
  - a stored const `undefined` sentinel: an own property with the value `undefined`
  - Dart `null`: JS `null`
- **The sentinel.** The sentinel is the const object `undefined` of a final class `Undefined` in
  `lib/src/js/`, as in the prototype. Ported code compares a value with it through `identical`.
- **Resolver rule.** The resolver reads an absent key and the sentinel alike. `mergeIf`, `_cached`
  and key enumeration test own-key presence. Thus they keep the two states apart.
- **Resolver classes.** `Resolver` and `ContextResolver` replace the `Proxy` traps of
  `_createResolver` and `_attachContext`. They are line-by-line ports of `helpers.config.ts` and
  of the scope part of `core.config.js`.
- **Global scopes.** `defaults`, `overrides` and `descriptors` are Maps. `defaults.route`
  (`core.defaults.js:130-157`) makes a routed scope. A routed scope is a `MapBase` that reads the
  route target when the local value is `undefined`. It merges a local object over the target
  object, as upstream does.
- **Raw configs in 0.1.0.** Release 0.1.0 accepts raw Map configs, `jsonDecode` output included.
  A typed options API comes after 0.1.0, with its own ADR ("ADR: Typed options API"). That API
  compiles to the same scope Maps. Typed theme component styles depend on it
  ([theming.md](../theming.md) §5.1).
- **Values outside scopes.** Outside option scopes, Dart `null` can represent `undefined` if JS
  `null` never reaches that value. The `///` line of the symbol says so. An example is
  `decimalPlaces` in `helpers.math.dart`.
- **Tests.** The null-versus-undefined resolver tests come from the prototype. One test makes sure
  that a stored sentinel blocks `mergeIf`.

## Alternatives considered

- **One Dart `null` for both JS values.** Rejected. 16 of 19 probed cases give different results.
- **Typed option classes as the core** (approach b of the research). Rejected for the core. In the
  prototype, they could not express the `helpers.config.tests.js` cases without their raw `extra`
  Maps. The bar cases needed immutable rebuilds. The typed options API comes later as a front end
  over the Maps.
- **Typed resolvers for each element type** (approach c). Not now. In the prototype, they were 10
  to 17 times faster on dynamic paths. But they omit prefixed keys, descriptors and raw keys.
  They come only after parity, behind the same specs ([porting-flow.md](../porting-flow.md) §7,
  risk 3).

## Consequences

- The specs port 1:1. They read the order of `_scopes` and change configs as upstream does.
- JSON configs and the pure-data fixture configs go to the resolver directly. The fixtures with
  functions need hand-ported Dart closures ([porting-flow.md](../porting-flow.md) §1, step 6).
- `jsonDecode` gives an `int` for an integer literal. Ported code reads a number as a `num` and
  converts it with `jsToNumber` ([Chart.js ADR 0002](0002-js-numeric-semantics.md)).
- In JS, `isObject` is also true for an instance of a class without `Symbol.toStringTag`
  (`helpers.core.ts:53-55`). In the port, only a Map is a plain object. A class instance in an
  options tree stays a leaf.
- The doc comment of `js_number.dart` waits for this sentinel. The PR that adds the sentinel gives
  `jsToNumber` and `jsIsNaN` the JS results for `undefined`: NaN and true.
- [Chart.js ADR 0001](0001-theming.md) adds the theme as one more Map scope.
- Upstream fixes to the option machinery replay as small diffs, because the module split stays the
  same.
