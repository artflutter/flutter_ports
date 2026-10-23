# Chart.js ADR 0043: Options representation and resolver

- Status: proposed
- Date: 2026-10-23
- Supersedes: [Chart.js ADR 0006](0006-options-representation-and-resolver.md) on acceptance
- Related: [Chart.js ADR 0039](0039-tooltip-model-and-animation.md) §10 (`helpers.merge` with an
  element target),
  [differences.md](../differences.md#adapt-merge-element-target) row
  `adapt-merge-element-target`,
  [Chart.js ADR 0017](0017-element-properties.md) §5 (the access by name of `Element`),
  [Chart.js ADR 0032](0032-js-numeric-semantics.md) (JS numeric semantics, `jsToNumber`),
  [Chart.js ADR 0042](0042-theming.md) (theming, proposed)

This ADR states the complete decision on the options representation and the resolver. It keeps
every decision of Chart.js ADR 0006 and changes one item: the leaf rule for a class instance
(section "Changes from Chart.js ADR 0006"). The citations are at the pin `v4.5.1+7169e651`.

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

### Class instances in JavaScript

- `isObject` is `value !== null && Object.prototype.toString.call(value) === '[object Object]'`
  (`helpers.core.ts:53-55`). It is also true for an instance of a class without
  `Symbol.toStringTag`, for example an element or the tooltip.
- Thus `clone` (`helpers.core.ts:190-209`) copies the own keys of a class instance into an object
  without a prototype. `_merger` (`:220-233`) merges an object into a class instance value.
  `merge` (`:260-286`) writes into a class instance target and copies the own keys of a class
  instance source. `mergeIf` (`:301-304`) calls `merge` with `_mergerIf`, which tests the own
  keys of its target with `hasOwnProperty` (`:310-323`).
- The four text align cases of `test/specs/plugin.tooltip.tests.js` (`:1499`, `:1525`, `:1551`,
  `:1577`) call `Chart.helpers.merge(tooltip, makeView(...))` (`:1501`, `:1527`, `:1553`,
  `:1579`) on one tooltip. `Chart.helpers.merge` is public.
- No upstream module of `src/` calls `merge` or `mergeIf` with a class instance target or source.

### The port before this decision

- Chart.js ADR 0006 decided: "In the port, only a Map is a plain object. A class instance in an
  options tree stays a leaf." `isObject` of `lib/src/helpers/helpers.core.dart` is true only for
  a `Map<String, Object?>`. Thus `merge` gave an element target back with no write.
- `Element` has the access by name of Chart.js ADR 0017 §5: `operator []` and `operator []=`.
  It implements `types.PropertyAccess` of `lib/src/types/index.dart`.
- Phase 8 (Chart.js ADR 0039 §10) changed `merge`, `merger` and `mergeIf`. `merge` writes into a
  `types.PropertyAccess` target by name. This ADR states that change as a part of the complete
  decision.

## Decision

- **Scopes are Maps.** An option scope is a `Map<String, Object?>`. A JS plain object is a
  `Map<String, Object?>`. A JS array is a `List<Object?>`. A scriptable option is a Dart closure.
  Every other Dart object is a leaf value, with the one exception of the item "Merge into an
  element".
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
- **The leaf rule.** `isObject` is true only for a `Map<String, Object?>`. A class instance is
  not a plain object. The rule holds for `clone`, for `mergeIf`, for `mergerIf` and for the
  options trees that the resolver reads:
  - `clone` keeps a class instance as a reference.
  - `mergeIf` gives a target that is not a Map back at once, before its `merge` call. Thus it
    writes nothing into a class instance target. `mergerIf` tests the own keys of its target
    with `containsKey`, and an element has no list of its own keys.
  - `merge` skips a class instance source.
  - In `merger`, a class instance source value replaces the target value, also an element
    target value.
  - The resolver, `Config` and the routed scopes read a class instance in an options tree as a
    leaf value.
- **Merge into an element.** The exception to the leaf rule is the target of `merge` and of
  `merger`:
  - `merge` treats a `types.PropertyAccess` target as an object target. It writes through a
    private Map view of the target (`_PropertyAccessView`). The view has only `operator []`
    (the read by name, with the sentinel for an absent name) and `operator []=` (the write by
    name). `merge` returns the original target, not the view.
  - `merger` also recurses when the target value is a `types.PropertyAccess` and the source
    value is a Map. Thus `merge` writes into an element value of a Map target by name.
  - The view has no keys. Thus `keys`, `remove` and `clear` throw an `UnsupportedError`, and so
    do the Map members that use them, for example `containsKey` and `length`. A custom merger
    that lists the keys of its target, or calls `containsKey`, throws. The default `merger`
    does neither.
  - The reason: upstream `isObject` is true for a class instance (`helpers.core.ts:53-55`), so
    upstream `merge` writes into an element target. The four text align cases of
    `plugin.tooltip.tests.js` call `Chart.helpers.merge(tooltip, view)` and stay unchanged. The
    public `Chart.helpers.merge` writes into each element of the port, as upstream.
  - `isObject` does not change. It runs in each resolver and config path. A class without the
    access by name (no `types.PropertyAccess`) stays a leaf also as a `merge` target: `merge`
    gives it back with no write.
  - Each changed hunk of `merge`, `merger` and `mergeIf` carries
    `// DIVERGES(chartjs): adapt-merge-element-target, ...`. The row
    [`adapt-merge-element-target`](../differences.md#adapt-merge-element-target) records what
    stays different from upstream.
- **Tests.** The null-versus-undefined resolver tests come from the prototype. One test makes sure
  that a stored sentinel blocks `mergeIf`. One test makes sure that a class instance is not an
  object. The group `adapt-merge-element-target` of `test/port/helpers/helpers.core_test.dart`
  pins the upstream results of two `merge` calls into an `Element` and into a `Tooltip`, and the
  `clone`, `mergeIf` and `merge` differences of the row.

## Changes from Chart.js ADR 0006

1. Chart.js ADR 0006 said: "In the port, only a Map is a plain object. A class instance in an
   options tree stays a leaf." This ADR keeps the leaf rule for `clone`, `mergeIf`, a `merge`
   source and the options trees that the resolver reads. It adds one exception: `merge` and
   `merger` write into a `types.PropertyAccess` target, and into a `types.PropertyAccess` value
   of a Map target, by name (Chart.js ADR 0039 §10, row `adapt-merge-element-target`).
2. The item "Scopes are Maps" names this exception. The items "The leaf rule" and "Merge into an
   element" are new. They state the rule that was a consequence of Chart.js ADR 0006, with the
   exception.
3. Current facts: the citation of the JS numeric semantics goes to Chart.js ADR 0032, the current
   successor of Chart.js ADR 0002. The `jsToNumber` and `jsIsNaN` results for the sentinel are
   in `lib/src/js/js_number.dart`. The theme scope cites Chart.js ADR 0001 and its proposed
   successor Chart.js ADR 0042, which states the same scope.

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
- **Keep the leaf rule for the `merge` target too.** Rejected. Then `Chart.helpers.merge` writes
  nothing into an element, a silent difference of a public helper. The spec needs another form:
  - A test helper `mergeByName` in `test/support/jasmine.dart` and a `harness-*` row. It keeps
    the silent difference and changes four spec lines.
  - `tooltip.assign(view)` (`Object.assign`) in the spec and a `js-semantics` row. The spec
    result is equal (37 draw calls in each case), but it keeps the same silent difference and
    changes four spec lines.
- **`isObject` true for a `types.PropertyAccess`.** Rejected. `clone` would need the keys of an
  element, and `isObject` runs in each resolver and config path.

## Consequences

- The specs port 1:1. They read the order of `_scopes` and change configs as upstream does.
- JSON configs and the pure-data fixture configs go to the resolver directly. The fixtures with
  functions need hand-ported Dart closures ([porting-flow.md](../porting-flow.md) §1, step 6).
- `jsonDecode` gives an `int` for an integer literal. Ported code reads a number as a `num` and
  converts it with `jsToNumber` ([Chart.js ADR 0032](0032-js-numeric-semantics.md)).
- In JS, `isObject` is also true for an instance of a class without `Symbol.toStringTag`
  (`helpers.core.ts:53-55`). In the port, only a Map is a plain object. A class instance in an
  options tree stays a leaf. The exception is a `types.PropertyAccess` target of `merge` and a
  `types.PropertyAccess` value of a Map target of `merge`: the port writes into it by name.
- `Chart.helpers.merge` writes into an element target, as upstream. Thus the four text align
  cases of `plugin.tooltip.tests.js` keep `merge(tooltip, view)`.
- Five differences stay, and the row `adapt-merge-element-target` records them:
  - `clone` keeps an element as a reference. Upstream copies its own keys into an object
    without a prototype.
  - `mergeIf` gives an element target back and writes nothing. Upstream writes the keys that the
    element does not own.
  - `merge` skips an element source. Upstream copies its own keys.
  - An element source value replaces the target value, also a Map or an element. Upstream
    merges the own keys of the element into a Map or an element target value.
  - A custom merger that lists the keys of its target or calls `containsKey` throws an
    `UnsupportedError`. No Chart.js merger lists the keys of its target.
- The branch costs nothing measurable on the Map path: a `merge` of a 3-level config takes
  2.38-2.45 µs without the branch and 2.40-2.46 µs with it on AOT, and 2.98-3.03 µs and
  3.02-3.08 µs on dart2wasm (Chart.js ADR 0039, Benchmarks).
- The doc comment of `js_number.dart` waited for this sentinel. The change that added the
  sentinel gave `jsToNumber` and `jsIsNaN` the JS results for `undefined`: NaN and true.
- [Chart.js ADR 0001](0001-theming.md) adds the theme as one more Map scope.
  [Chart.js ADR 0042](0042-theming.md) (proposed) states the same scope.
- Upstream fixes to the option machinery replay as small diffs, because the module split stays the
  same.
- At the acceptance of this ADR, the citations of Chart.js ADR 0006 in docs, code and tests move
  to this ADR. Chart.js ADR 0006 gets the line "Superseded by Chart.js ADR 0043".

## Open

1. **The typed options API.** Its own ADR comes after 0.1.0 ("ADR: Typed options API"). Owner:
   the porting lead. Trigger: the work on the typed theme component styles
   ([theming.md](../theming.md) §5.1).
2. **A class instance as a `merge` source or a `mergeIf` target.** No module of `src/` at the pin
   does this. Owner: the porting lead. Trigger: an upstream change or a spec that needs it. Then
   a new ADR decides how the port gets the own keys of an element.

## Evidence

- **E0, upstream source** at `v4.5.1+7169e651`:
  - `src/helpers/helpers.config.ts:27-108`, `:118-195`, `:38`, `:204`, `:223`, `:399`, `:413`
  - `src/core/core.config.js:296`, `:331`
  - `src/core/core.defaults.js:130-157`
  - `src/elements/element.bar.js:153`
  - `src/core/core.datasetController.js:817`
  - `src/helpers/helpers.core.ts:53-55`, `:190-209`, `:220-233`, `:260-286`, `:301-304`,
    `:310-323`
  - `test/specs/plugin.tooltip.tests.js:1499-1603`
- **E1, the research of 2026-10-16:** the 19 probed `null` cases, the Dart prototype (47 tests),
  the AOT and dart2js figures and the fixture count of the Context
  ([porting-flow.md](../porting-flow.md) §2.1).
- **E2, the phase 8 probes and benchmarks:** the `merge` probes and the `merge` benchmark of
  [Chart.js ADR 0039](0039-tooltip-model-and-animation.md) (Probes, Benchmarks).
- **E3, the port code read:** `lib/src/helpers/helpers.core.dart` (`isObject`, `clone`,
  `merger`, `merge`, `mergeIf`, `mergerIf`, `_PropertyAccessView`), `lib/src/types/index.dart`
  (`PropertyAccess`), `lib/src/core/core.element.dart` (`Element`), `lib/src/js/js_undefined.dart`
  (`Undefined`, `undefined`), `lib/src/js/js_number.dart` (`jsToNumber`, `jsIsNaN`).
- **E4, the rows and tests:** [differences.md](../differences.md) row
  `adapt-merge-element-target`, and `test/port/helpers/helpers.core_test.dart` (the class
  instance test, the sentinel test of `mergeIf` and the group `adapt-merge-element-target`).
