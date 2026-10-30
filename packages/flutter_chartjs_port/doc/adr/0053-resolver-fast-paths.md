# Chart.js ADR 0053: The resolver fast paths

- Status: proposed
- Date: 2026-10-30
- Related: [Chart.js ADR 0043](0043-options-representation-and-resolver.md) (the options
  representation and the resolver; the resolver classes stay line-by-line ports),
  Chart.js ADR 0052 (the typed API; its own gate), [Chart.js ADR 0017](0017-element-properties.md)
  §5 (the access by name), [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13 (a gain
  that only a microbenchmark measures), [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md)
  (the typed element options), [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the
  protected behavior), [Chart.js ADR 0036](0036-parsed-data.md) §8 (the 3-read line loop),
  [Chart.js ADR 0044](0044-stack-fill-search.md) and
  [Chart.js ADR 0046](0046-stack-fill-search-result.md) (a code A/B that decides a change, the
  ratio 1.5), [Chart.js ADR 0045](0045-reference-engine-arm64.md) (the reference engine),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule) and §5.1 (deferred plans),
  [performance.md](../performance.md) §10.10, §13.6, §13.7, §14.9 and §15,
  [canvas-cuts-plan.md](../canvas-cuts-plan.md) (cut 1)

## Context

### The decision of the maintainer

On 2026-10-30 the maintainer stopped the upload of 0.1.0. The update of the port is a median 1.93
times Chart.js in the same browser ([performance.md](../performance.md) §14.9, P3), and the option
resolution is the largest cost. The release waits for two items: a typed Dart API (Chart.js ADR
0052) and a faster option resolver and hot paths (this ADR). The phase 10 design panel R wrote
three drafts and one verdict. The porting lead then decided the open points. This ADR states the
result. The upstream citations are at the pin `v4.6.1` (`76d8cf89`). The port citations are at
`c8058a7`.

### The figures

- §14.9, P3: Chart.js in V8 against the port in dart2wasm, in the same browser. The median ratio of
  the frame is 1.93 over 100 cells (controller cells 2.08, plugin cells 1.82). The largest excess is
  `chart.c` update at N 20000: +49.771 ms for each frame, 2.07 times upstream. The port is faster
  only in the `chart.bar` draw.
- §10.10, the CPU profile of `chart.c` (line, scriptable `backgroundColor`, no sharing) on the
  Pixel 8a: `resolveDataElementOptions` 97 % of the update, `Config.resolveNamedOptions` 84 %,
  `ContextResolver.[]` 39 %, `_cached` 36 %, `jsGet` 18 %, `attachContext` 15 % (its Map literal
  10 %), `createResolver` 12 %, `_getResolver` 9 % (`List.join` 7 %).
- §13.6: on the Pixel 8a at N 5000 the `chart.c` update is 36.389 ms in the port and 26.079 ms
  in V8. V8 spends 70 % of its own update in the resolution. §13.7: the writes by name are 32 % of
  the `chart.b` line update with sharing, `jsGetKey` 16 %, the bubble option copy about 15 %; the
  bar memo of step 7 measured -37 to -43 % of the bar update, and its guard cells rejected it.
- §15.3: the default animated update on macOS: `motion.line` N 1000 7.8 ms, N 20000 158 ms;
  `motion.bar` N 20000 236 ms. No profile of it exists.

### Where the cost is

- The hot path of `chart.c` is the context machinery for each point, not the scope chain. The
  scope reads (`_resolve`) do not grow with N: 1085 reads in one update at N 100 and at N 1000.
  For each point the port makes 2.06 `attachContext` calls, 9.49 cache inserts and 67.8 `jsGet`
  calls. 41 of these `jsGet` calls read the slots of the cache objects (`_proxy`, `_context`,
  `_subProxy`, `_descriptors`, `_stack`), which V8 reads as plain properties.
- Each statement of that path exists upstream. The cost is in the Dart form of each statement:
  Map literals for the cache objects, slot reads through `jsGet`, `List.join` for the cache keys,
  `jsCall1` for the descriptor predicates, `jsObjectKeys`. These forms sum to about 35 % of the
  `chart.c` update, more than the excess of 28 % over V8 on the Pixel 8a, because V8 also pays for
  its `Proxy` work. Thus the port can go below upstream when it removes them.
- An update in the default mode resolves the animation options again for each element
  (`src/core/core.datasetController.js@v4.6.1:841-862`; the cache object of a context resolver
  has `_cacheable: false`, `src/helpers/helpers.config.ts@v4.6.1:128`). One default update of 50
  line points makes 52 `Animations` objects with 1 distinct content. The estimate of its share of
  the motion update is 65-80 % (no profile yet).
- dart2wasm against macOS AOT, update at N 1000 (night 1 of phase 9, the same port): 0.92-1.02
  in each cell except `chart.c` (1.18) and `chart.bar` (1.11). The likely causes are
  `Function.apply` in `jsCall` (about 19 calls for each point of `chart.c`) and the scan of
  `jsObjectKeys`. The figures show no general dart2wasm penalty of string `==` and hash.

### Scope

Chart.js ADR 0043 keeps the resolver classes as line-by-line ports of `helpers.config.ts` and
`core.config.js`. This ADR does not change that. It adds fast paths and `adapt` rows under the
rule of [porting-flow.md](../porting-flow.md) §1.1: a faster form that changes the upstream
structure gets a `DIVERGES` marker, an `adapt` row and a measured gain. This ADR supersedes no
ADR. Chart.js ADR 0052 decides the typed API. The two ADRs have separate gates: tests for Chart.js
ADR 0052, the night A/Bs for this ADR (the decision of the porting lead, 2026-10-30).

## Decision

### 1. The exactness contract

- **User code** is a function value of the config (a scriptable option, a callback, a descriptor
  function such as a user `_scriptable` or `_indexable`, a `_fallback` function) and an override
  of a ported class (controller, element, scale, plugin).
- A read of a plain Map is not user code. `jsGet` reads a Map with `[]` and then `containsKey`
  (`lib/src/js/js_object.dart:48-50`). The port does not model a Map subclass as a JS getter.
- A fast path keeps each call of user code with the same arguments, the same `this` and in the
  same order. It keeps each value that ported code reads, each throw, the cache states that code
  can reach, and the key order of the result objects. Else it takes the ported form.
- The general path stays the fallback of each fast path. A fast path gives the result of the
  general path for the same input.

### 2. The switch and the test leg

- `lib/src/js/js_fast_paths.dart` (port-only, a pure layer) has:
  - `const bool _allowed = bool.fromEnvironment('PORT_FAST_PATHS', defaultValue: true);`
  - `@visibleForTesting bool debugFastPaths = true;`
  - `bool get portFastPaths`: false when `_allowed` is false. Else it reads `debugFastPaths`
    inside an `assert` closure. A run without assertions removes the closure, so the getter gives
    the constant `_allowed`.
- Each fast path of Z, K, F3, C7, M and R2 tests `portFastPaths` at its entry. When it is false,
  the fast path takes the ported form. C1 has no second form: D1, D2 and D3 cover it (section 3).
- Each fast branch also calls `assert(debugFastPathHit('<id>'), ...)`. `debugFastPathHit` counts
  the run in the Map `debugFastPathHits` (`@visibleForTesting`). A D3 group reads the counts to
  show that its cases take the fast path. A run without assertions removes the call.
- The check of the cost (2026-10-30, Dart 3.13.5). A probe program calls a never-inline function
  `fastForm` when `portFastPaths` is true, else a never-inline function `slowForm`. Each function
  returns a string with its own marker. The probe compiles against the package with
  `dart compile exe`, `dart compile wasm -O2` and `dart compile js -O2`. Without the define, each
  output holds the marker of `fastForm` only: the marker of `slowForm`, the id string of an
  `assert(debugFastPathHit(...))` and the name `debugFastPaths` are absent. With `-DPORT_FAST_PATHS=false`, the exe holds the marker of
  `slowForm` only. A JIT run with `--enable-asserts` reads the switch. A Flutter profile or
  release build has no assertions, so it takes the same constant. Thus the switch costs nothing in
  a timed build.
- The test leg `test:nofast` is a melos script:
  `flutter test --exclude-tags golden --dart-define=PORT_FAST_PATHS=false` in
  `packages/flutter_chartjs_port`. It runs the spec, fixture and reference suites with every fast
  path off. AGENTS.md puts it in the list of the gates before a push.

### 3. The exactness tests

- **D1, the differential test** (`test/port/js/js_fast_paths_test.dart`, `@TestOn('vm')`,
  `testWidgets`). For each config of the corpus, the test builds the chart with the switch off and
  with the switch on (it restores the switch with `addTearDown`). It runs the steps `update()`,
  `update('none')`, a hover, `reset()`, `hide(0)` and `show(0)` at a fixed `Date.now()`
  (`withClock`). Then it compares, for each element: the options (the `jsObjectKeys` order, the
  values, the runtime class), the properties, `$shared`, the keys of `_cachedDataOpts`, the keys of
  `$context`, and the `$animations` (the keys; `from`, `to`, `duration`, the start, `loop` and the
  easing of each `Animation`). It also compares the draw calls of a recording context and the
  trace of the user calls: each function value of the config goes into a recorder of the option
  name, `context.type`, `index`, `dataIndex`, `mode`, `active` and the class of the second
  argument. The corpus: the 147 hand fixtures of `test/fixtures/hand/`, the bench configs at N 50
  (`chart.a`, `chart.b`, `chart.c`, bar, bubble, the arcs, radar, `motion.line`, `motion.bar` and
  the cells of section 9), and the focused configs of D2 and D3. A difference fails.
- **D2, the reference trace** (`tool/reference/resolver_trace_reference.mjs` writes
  `test/port/core/resolver_trace_reference.dart`; the test is
  `test/port/core/resolver_trace_test.dart`). The generator runs on the reference engine of
  Chart.js ADR 0045. Its cases: a scriptable option on each level; indexable arrays; hover
  prefixes; an object option; an array of objects; `_fallback` as a string, as `true` and as a
  counted function; counted user `_scriptable` and `_indexable`; recursion; a write of
  `ctx.parsed`; a write through the sub-resolver; a new key in `Chart.defaults.elements.point`
  during an update; repeated names; a slot name; and the animation cases (default, scriptable
  `delay` and `duration`, `hide` and `show`, `animation: false`, a scriptable entry of
  `animations`, a `properties` override, a counted `_fallback` function on `animation`, a delete
  of `Chart.defaults.animation.easing` inside a scriptable data option). The data: the options of
  each element with the key order, the ordered trace of the user calls, and the `$animations` of
  each element at a fixed `Date.now()`.
- **D3, the pin tests**: one group for each change, with the names of section 4 and 5.
- The reference tests compare the options of an element with no key order, and the fixture
  tests are smoke tests (Chart.js ADR 0029). D1, D2 and D3 close that gap. The spec cases, the
  fixtures and the reference tests stay unchanged and pass with each change.

### 4. The adopted changes

Gains are estimates of the panel unless "measured". "Hunks" counts the changed places in ported
functions. Port-only code (`lib/src/js/`, the access by name of Chart.js ADR 0017 §5, port-only
helpers and classes) has no hunk.

| Id | Change | Hunks | Row | Expected gain |
|---|---|---|---|---|
| Z | Z1 typed calls in `jsCall` and `jsCall1`; Z2 a lean `jsObjectKeys`; Z3 identity-first access by name; Z4 one read in `ContextObject` | 0 | none | `chart.c` update -4 to -5 % (macOS), -13 to -20 % (Chrome); `chart.b` line -10 to -12 %; bar -6 to -8 %; bubble -4 to -6 % |
| K | memos of the three cache-key strings; identity Maps for `_scopeCache` and `_resolverCache` | 4 one-line call sites, 2 Map constructors | none (section 6) | scatter update -26.6 / -33.8 / -36.4 %, bubble -17.7 / -15.0 % (measured, §13.6, the key memo alone); `chart.c` -7 to -9 %; doughnut and pie -30 to -40 % |
| C1 | a typed cache object of the context resolver | 4 | `adapt-resolver-context-cache` | `chart.c` -15 to -18 %; `motion.line` -15 to -25 % before C7 |
| F3 | the named options without the unreachable `options` proxy | 1, plus a port-only function | `adapt-resolve-named-inline` | `chart.c` -15 to -18 % of today |
| M | the bar index memo with two more guard conditions | 5 | `adapt-bar-index-memo` | bar update -31 to -43 %, frame -14 to -25 % (measured on three platforms, §13.6) |
| R2 | typed writes in the port-only `_setProperty` of line and scatter | 0 | none (section 6) | `chart.b` line -5 to -8 % after Z3 |

The expected `chart.c` update after Z, K, C1 and F3 is about 0.55 of today on the VM (a ratio of
about 0.76 against upstream on the Pixel 8a) and about 1.0 times upstream in Chrome (estimate).

**Z: fast paths of the JS runtime and the access by name.**
- Z1: `jsCall` and `jsCall1` (`lib/src/js/js_function.dart`) test the function types in the order
  of `_apply`, before `_apply`: `Object? Function(Object?, Object?)` for 2 arguments,
  `Object? Function(Object?)` and `Object? Function(String)` for 1 argument, `Object? Function()`
  for none. A hit calls the closure directly. A `JsFunction`, a class value and each other closure
  keep the present path and its errors.
- Z2: `jsObjectKeys` (`lib/src/js/js_array.dart`) makes one pass. When no key starts with a code
  unit `0`-`9`, it returns the insertion order. Else it runs the present algorithm.
- Z3: the `operator []` and `operator []=` of `Element` and of the four elements, and `_rawOf` and
  `_store` of the typed element options, test `identical` keys in the order of use before the
  present `switch`. The `switch` stays the fallback.
- Z4: `ContextObject.operator []` (`lib/src/helpers/helpers.options.dart`) reads its own Map once.
  It calls `containsKey` only for a `null` value.
- Exactness: a typed call calls the same closure with the same arguments; `jsObjectKeys` returns
  the insertion order when no key can be an array index; an `identical` test maps a key to the case
  that the `switch` maps it to. D3 group `fast-paths-runtime`.

**K: memos of the option cache keys.**
- A port-only file `lib/src/js/js_key_memo.dart` has a memo of `a + sep + b` and a memo of
  `list.join(',')` for 1 to 4 items. A memo keeps the parts and the result of its last call.
  Identical parts give the last `String`; else the upstream operator builds a new string. One memo
  object stands at each call site.
- Call sites (one line each): `_resolveElementOptions` of `core.datasetController.dart`
  (`core.datasetController.js:807`), `_getResolver` (`core.config.js:389`), and the two key
  templates of `datasetAnimationScopeKeys` and `datasetElementScopeKeys` (`core.config.js:230`,
  `:253`). `_scopeCache` (outer and inner) and the outer Map of `_resolverCache` become
  `Map.identity()`.
- Exactness: a key is a pure function of its parts, so an identical part list gives a string equal
  to a new one. A JS `Map` keys an object by identity (SameValueZero), so `Map.identity()` is the
  upstream semantics. D3 group `fast-paths-keys`.

**C1: a typed cache object of the context resolver.**
- A port-only class `_ContextCache` in `helpers.config.dart` (the port of the cache object of
  `src/helpers/helpers.config.types.ts`) has one field for each own key of
  `helpers.config.ts:127-136`, in that order (`_cacheable`, `_proxy`, `_context`, `_subProxy`,
  `_stack`, `_descriptors`, `setContext`, `override`), each with a deleted state. `_stack` and the
  two closures come at their first read and keep their identity. `_descriptors` stays eager
  (`helpers.config.ts:133`). The cached option values go into a second Map, made at the first
  write. `keys` gives the present slot keys in the literal order, then the cached names in their
  insertion order. A slot name goes to its field through each trap; each other name goes to the
  Map.
- Hunks: `attachContext` builds the object; `_resolveWithContext`, `_resolveScriptable` and
  `_resolveArray` read the fields when the target is a `_ContextCache`, else `jsGet`.
- Exactness: the object gives the Map results of the upstream cache object. Each slot is readable,
  writable and deletable through each trap. A read through a deleted slot throws the upstream
  `TypeError`.
- Row `adapt-resolver-context-cache`: `src/helpers/helpers.config.ts@v4.6.1:118-136, 233-296`. A
  bump compares `_attachContext` and the three readers. D3 group `adapt-resolver-context-cache`.

**F3: the named options without the options proxy.**
- In `resolveNamedOptions`, upstream builds `options = _attachContext(resolver, context,
  subResolver)` (`src/core/core.config.js@v4.6.1:360`). No code reaches that object: a scriptable
  option gets the sub-resolver (`_subProxy || receiver`, `helpers.config.ts:266`), and the
  sub-resolvers get the context, `subResolver[prop]` and the descriptors.
- A port-only `@internal` function runs the body of `_resolveWithContext` for each name with the
  slots as values: the descriptors once before the loop, `jsGet(resolver, prop)`, the scriptable
  test as a method call, the scriptable core with the sub-resolver as the second argument, the
  array core with the detached `isIndexable`, `attachContext` for an object value, and the write
  into the result in the name order.
- A repeated name, a slot name or `constructor` takes the ported loop.
- Exactness: each read of the resolver, each user call and each write stays in the name order.
  The only skipped work is the cache, the `_stack` and the closures of an object that no code can
  read. A probe ran the form against the whole suite of the package: 7852 tests passed (the one
  failure was a public-name list of the probe itself).
- Row `adapt-resolve-named-inline`: `src/core/core.config.js@v4.6.1:351-367`,
  `src/helpers/helpers.config.ts@v4.6.1:233-296`. A change of what a scriptable option gets
  re-opens the row. D3 group `adapt-resolve-named-inline`, with the hazard of section 5 (the radii
  `[3, 3, 9, 9, 9]`).

**M: the bar index memo.**
- The step 7 patch (5 hunks in `controller.bar.dart`) computes the axis count, the axis number
  and the stack index once for each `updateElements` call when `_canShareIndexValues` holds: not a
  subclass of `BarController`, a direct mode, options that do not resolve for each bar, no function
  `grid.lineWidth` of the value scale, and no `skipNull`.
- Two more conditions: the runtime types of `vScale` and `iScale` are scale classes of
  `lib/src/scales/index.dart`, and each bar of the range has the runtime type `BarElement`. Thus no
  user scale method and no user element `[]=` runs between two bars.
- Row `adapt-bar-index-memo`: `src/controllers/controller.bar.js@v4.6.1:393-432, 434-508,
  636-680`. A bump compares `updateElements`, `_calculateBarIndexPixels`, `_getStacks` and
  `_getAxisCount`. D3 group `adapt-bar-index-memo`.

**R2: typed writes of the line and scatter direct update.**
- `_setProperty` of `controller.line.dart` and `controller.scatter.dart` is a port-only helper.
  Its new first branch runs when `portFastPaths` holds and the element has the exact runtime type
  `PointElement`. For an identical key of `skip`, `stop`, `parsed`, `raw`, `options`, `x` or `y`,
  it calls the converter of the write by name of that key and stores the field. Each other key and
  each other element keep the write by name.
- Exactness: a subclass keeps the write by name, so its `[]=` sees each write, as upstream sees
  each property set. D3 group `fast-paths-point-writes`.

### 5. C7, after the motion profile

C7 keeps one `Animations` object for each transition of one update pass. It goes to its A/B only
when the motion profile P-M (section 8) gives `DatasetController.resolveAnimations` (inclusive)
40 % or more of the `motion.line` update at N 20000 on macOS (the mean of 3 profiles). Else the
porting lead writes a new candidate from the top 5 frames of P-M, with its own protocol.

C7 is exact only with this guard set:
- G1. The first resolution of the pass is context-free: a port-only counter does not change during
  `createResolver` and `Animations(...)`. It counts each `_resolveScriptable` call, each call of a
  descriptor function value, each `_resolveArray` call with an undefined index, the indexable
  branch or the objects branch, and each `_resolveFallback` call of a function.
- G2. The global write epoch of the resolvers is unchanged. The set, delete and clear traps of
  `Resolver` and `ContextResolver` increment it.
- G3. The cache generation of `Config` is unchanged (`clearCache` increments it).
- G4. `getOptionScopes` gives the identical scope list for each element. It still runs.
- G5. `Object.keys(defaults.animation)` gives the same keys, item by item, for each element.
- G6. `chart.options.animation !== false` is read for each element.
- G7. The memo key is the transition. The memo lives in one `update_` pass. A re-entrant pass
  saves and restores it.

Each element still runs the scope keys, `getOptionScopes`, `getContext(index, active,
transition)` (its writes are visible) and `_createAnimations`. The `Animations` object only feeds
`update(target, values)` (`core.datasetController.js:902`, `:922`); nothing stores it. Thus the
shared object is not observable when G1-G7 hold. Row `adapt-animations-memo`:
`src/core/core.datasetController.js@v4.6.1:841-862`, `src/core/core.animations.js@v4.6.1:13-37`,
`src/helpers/helpers.config.ts@v4.6.1:255-304`. D3 group `adapt-animations-memo`. Expected gain:
`motion.line` -60 to -75 %, `motion.bar` -45 to -60 % (estimate).

The C6 hazard shows why the guards run after each user call. A scriptable `pointBorderWidth`
that writes `radius` through its second argument at `dataIndex` 2 gives the radii
`[3, 3, 9, 9, 9]`: the write reaches a later name of the same element.

### 6. The marker ruling and the rows

- C1, F3, M and C7 change ported functions. Each hunk carries
  `// DIVERGES(chartjs): <row id>, <reason>.`, and `doc/differences.md` gets the `adapt` row of
  section 4 or 5.
- K and R2 carry no `DIVERGES` marker. K is a one-line runtime call in place of an upstream
  operator (`+`, a template literal, `Array.prototype.join`), as `jsAdd` is for `+`. The memo is
  internal to the runtime function. R2 changes a port-only helper. Z changes only port-only code.
  Each of Z, K and R2 still gets a subsection with its figures in the performance record.
- The docs of each landed change: its row (where section 4 or 5 names one), a subsection of
  [performance.md](../performance.md) §16 "The resolver and the hot paths (phase 10)", the status
  texts in `doc/status.yaml` with a `parity` run, and the line references of
  [canvas-cuts-plan.md](../canvas-cuts-plan.md) when the change edits a file that the plan cites.
  A rejected change leaves the tree, and §16 records its figures.

### 7. The gate of each change

Each change lands only after its night A/B. The method is that of performance.md §14.9 and §15.1:
profile builds of `lib/main_bench.dart`, one at a time, in worktrees outside the main checkout;
side B is side A with one frozen patch (`git apply --check`; the SHA-256 of `git diff` equals that
of the patch); one fresh process, or one fresh page load after `about:blank`, for each run; the run
value is the median of 15 batches; the SHA-256 of each binary before each run. Side A of a night is
`main` with the changes that earlier nights landed.

Platforms: macOS AOT (the gate of the quiet Mac) and the dedicated Chrome with dart2wasm decide.
The Pixel 8a and the iPhone 17 Pro are added platforms. A confirmed slowdown on an added platform
blocks the change.

The rules (written on 2026-10-30, before any run):
- ABBA: pair i runs A then B when i is odd, else B then A. Stage 1 is pairs 1-6. Stage 2 is pairs
  7-12 when a primary interval includes 0 (class H: or includes -0.1 ms) or a primary cell has
  fewer than 6 valid pairs.
- The cell value is the mean of the pair differences B - A of the run values, with a 95 %
  percentile bootstrap interval (20000 resamples, seed 20261023).
- The primary metric is the frame sum `update + draw + end` of the call of the cell; for a motion
  cell it is `update` (it holds the render). The guard metric is named in the series table.
- The control screen: K is the count of control cells (fixed in the protocol of each series), and
  h is the count of control cells whose interval lies wholly above 0. The screen passes when h is
  below h*, the smallest h with P(X >= h) <= 0.05 for X ~ Bin(K, 0.025) (K 25 gives 3, K 37 gives
  4). A large control hit (a lower end of 0.1 ms or more and of 5 % or more of the A mean) starts
  a confirmation series of 6 pairs with the selector of that cell.
- A run that starts after a gate wait of more than 300 s comes after one warm-up run of the same
  build that does not count.
- Stage 0, where section 4 names stage-0 cases: `tool/bench/bench.dart` on VM AOT
  (`dart compile exe`) and dart2wasm (`dart compile wasm -O2`, in Node.js), A and B, 5 runs each
  in the order A B A B A B A B A B. It passes when on both compilers each target case has a B
  median below the A median, and the ranges of the 5 run medians do not overlap. A change that
  fails stage 0 gets no app series.
- **Class Z** (no `DIVERGES` hunk: Z, K, R2). LAND when stage 0 passes and, on each deciding
  platform after its last stage, no primary and no guard interval lies wholly above 0, h < h*, and
  no large control hit is confirmed. Else REJECT.
- **Class H** (a `DIVERGES` hunk: C1, F3, C7, M). ACCEPT when stage 0 passes (where it applies)
  and, on each deciding platform after its last stage: each primary interval lies wholly below 0;
  at least one primary upper end is at -0.1 ms or below (Chart.js ADR 0020 §13); no guard
  interval lies wholly above 0; h < h*; no large control hit is confirmed. REJECT when a primary
  or a guard interval lies wholly above 0, h >= h*, or a large control hit is confirmed. Else
  INCONCLUSIVE: the change does not land, and the porting lead decides on a new series with the
  same rule.
- Added platforms decide nothing alone. A primary or guard interval wholly above 0 starts a
  confirmation series of 6 pairs on that platform. A confirmation interval wholly above 0 blocks
  the change.
- A change lands only with LAND or ACCEPT on both deciding platforms and no block. No rule changes
  after the first run of its series. In the morning an independent agent computes each figure and
  each decision again from the raw files.
- Before each night series: D1, D2, D3 and the gates of AGENTS.md (with `test:web` and
  `test:nofast`) are green on side B, and the reference data files are byte-equal.

### 8. The profiles, the series and the calendar

- **P-M** (macOS motion profile): the method of §10.10 on a macOS profile build
  (`CASES=motion,chart.c`, `N=5000,20000`); 3 profiles each of `motion.line` 20000, `motion.bar`
  20000 and `chart.c` 5000; the samples under `Chart.update` and not under `Chart.draw`. It decides
  C7 (section 5).
- **P-W** (dart2wasm profile): CDP `Profiler` in the dedicated Chrome around the timed part of the
  bench page (`CASES=chart.c,chart.bar,motion.line`), 3 loads each; the fallback is Node.js
  `--cpu-prof` of `bench.dart` compiled with `dart compile wasm -O2`. Figures only. If
  `Function.apply` or `_apply` has 5 % or more of the `chart.c` update and Z did not land, Z1 gets
  its own series the next night.
- **P-post**: the P-M method on the tree with the landed changes (`chart.c` 5000, `chart.b` line
  5000, `chart.bar` update 5000, `motion.line` 20000, `chart.line.primitive` 5000). It checks the
  triggers of the alternatives.
- **P3-base** and **P3-final**: the P3 method of §14.9 in the dedicated Chrome, the upstream page of
  section 10 and the port in the same night and tab: the 100 cells of §14.9, plus `motion.line` and
  `motion.bar` (N 1000, 20000) and the three cells of section 9, with the update and the draw
  recorded apart.

The series (selectors at `N=1000,5000,20000` unless named; the controls are the other cells of
the selector):

| Series | Class | Selector | Primary cells (frame) | Guard cells |
|---|---|---|---|---|
| Z | Z | `CASES=chart,motion` | `chart.c` update 5000, 20000; `chart.b` line update 5000; `chart.bar` update 5000 | `chart.a` draw 1000; `chart.doughnut` draw 1000 |
| K | Z | `CASES=chart` | `chart.b` scatter update 5000, 20000; `chart.bubble` update 5000; `chart.doughnut` update 1000 | `chart.b` line update 5000; `chart.a` draw 1000 |
| C1 | H | `CASES=chart,motion,tooltip` | `chart.c` update 1000, 5000, 20000; `motion.line` 1000 | `chart.b` line update 5000; `tooltip` N 1000 |
| F3 | H | `CASES=chart,chart.c.indexable` | `chart.c` update 5000, 20000; `chart.c.indexable` update 5000 | `chart.bubble` update 5000; `chart.polarArea` update 1000 |
| C7 | H | `CASES=motion,motion.line.delay,chart.b` | `motion.line` 1000, 20000; `motion.bar` 1000, 20000 | `motion.line.delay` 1000, 20000; `chart.b` line update 5000 |
| M | H | `CASES=chart.bar,chart.a,motion` | `chart.bar` update 1000, 5000, 20000 | `chart.bar` draw call 5000, 20000; `motion.bar` 1000 |
| R2 | Z | `CASES=chart` | `chart.b` line update 5000, 20000; `chart.b` scatter update 5000 | `chart.c` update 5000; `chart.radar` update 1000 |

The calendar (each night from 22:00 to 08:00; the inputs freeze by 21:30 of the day before; a
series that does not fit moves to the next night):

| Night | Earliest date | Work |
|---|---|---|
| N-R1 | 2026-10-31 | P-M, P-W, P3-base; the A/B of Z |
| N-R2 | 2026-11-01 | the A/Bs of K and C1 |
| N-R3 | 2026-11-02 | the A/B of F3; the A/B of C7 when the P-M rule passed |
| N-R4 | 2026-11-03 | the A/Bs of M and R2; P-post |
| N-R5 | 2026-11-04 | P3-final; open stage 2 runs and confirmations |

The changes with no hunk come first, so that each hunk is judged on the gain that remains. C1
comes before F3 and C7, the changes that build on it.

### 9. The bench cells

`apps/chartjs_gallery/lib/bench/chart_bench.dart` gets three cells for the series and the
profiles: `motion.line.delay` (`motion.line` with
`animation.delay: (ctx) => ctx.type == 'data' ? ctx.dataIndex : 0`), `chart.c.indexable`
(`chart.c` with a 2-item `backgroundColor` array in place of the scriptable), and
`chart.line.primitive` (a line of numbers with category labels, parsing on, `update('none')` with
new values). A selector selects them only by their id, so the selectors of the earlier records
select the same cells as before.

### 10. The upstream page of P3

The upstream page of P3 (the pinned build of Chart.js with the plugins, the cells of §14.9, the
motion cells and the cells of section 9, with the same data and the same steps) is committed under
`tool/reference/p3_page/`, with the steps to build the dist from the pin and to serve the page.
P3-base and P3-final use this page. Thus P3 can run again from the repository.

### 11. The release target

0.1.0 needs a median P3 frame ratio of **1.5 or below** over the 100 cells of §14.9 (the port
frame over the upstream frame, dart2wasm against V8, in the dedicated Chrome, P3-final of N-R5).
The reasons:
- The maintainer judged the port on this figure (median 1.93).
- 1.5 is the threshold that the port already uses for a path that is too slow (Chart.js ADR 0044
  Context; Chart.js ADR 0046).
- A ratio of 1.5 keeps 60 frames a second wherever upstream needs 11.1 ms or less for a frame.
- The panel projects the `chart.c` update near 1.0 with exact changes only. The draw cells of the
  arcs (2.0-2.3 times) and of the circles with several colors do not change with this ADR.

If P3-final gives a median above 1.5, the porting lead lists the cells above 1.5 by cost group
(update or draw). For the draw groups, the porting lead asks the maintainer for a §5.1 decision of
[porting-flow.md](../porting-flow.md) that brings forward cut 1 of
[canvas-cuts-plan.md](../canvas-cuts-plan.md) and a new form of `circle-batch-instance-colors`.
The porting lead asks only then, not before. For the update groups, the alternatives whose
triggers fired get their A/Bs. Then P3 runs again. 0.1.0 waits until the median is 1.5 or below,
or until the maintainer changes the target.

### 12. The interface with Chart.js ADR 0052

The resolver reads plain Maps. The typed API compiles to the scope Maps of Chart.js ADR 0043 once
for each config change, or its typed objects are the Maps. No typed scope, typed resolver or
second resolver enters the port. The requirements on the typed API:
- RT1. No work for each frame or each element: a compile runs once for each new config object.
- RT2. A dataset that stays keeps its dataset Map across a config change.
- RT3. No O(N) conversion when the data List is the same object. A typed data point is a number, a
  List, or a `Map<String, Object?>` record with the Map protocol of a plain object.
- RT4. One closure for each scriptable option for each compile, with the static type
  `Object? Function(Object?, Object?)` or `Object? Function(Object?)`, so that Z1 calls it with no
  `Function.apply` on the web. A typed context is a view over the `ContextObject` of `getContext`,
  with no copy of its keys.
- RT5. An unset typed field is an absent key, not Dart `null`. The key order of the Maps that
  upstream enumerates is the order of the user.
- RT6. No `const` Map reaches the port.

The acceptance of this ADR: the switch, D1, D2, D3 and `test:nofast` are in the tree and green;
each change of sections 4 and 5 landed or left the tree by its night rule, with its figures in
performance.md §16; and P3-final recorded the release figure.

## Alternatives considered

Rejected for 0.1.0, each with its trigger:

| Form | Reason | Trigger |
|---|---|---|
| C6, a plan of the options for each element | Not exact as written: a scriptable option can write through the sub-resolver and change a later name of the same element (the radii `[3, 3, 9, 9, 9]`). A corrected plan needs an epoch check after each user call. Its gain over F3 is about -12 to -16 % of today's `chart.c` update. No work before P3-final (the decision of the porting lead). | P3-final gives a `chart.c` update above 1.25 at any N |
| F4, the built-in descriptor predicates without a call | Z1 removes the `Function.apply` of these calls | P-post: `_needContext` at 5 % or more of the `chart.c` update after Z, K, C1, F3 |
| F5, a names memo with a version of `RoutedScope` | Z2 removes most of `jsObjectKeys`; the version needs a harness bump | P-post: `jsObjectKeys` in `_resolveElementOptions` at 2 % or more of the `chart.c` or scatter update |
| C5, typed properties records | 5 controllers change their properties literals; the split of its cost is not verified | P3-final bar update above 1.5, or P-post: `Element.assign`, the literal and `_setBorderSkipped` at 15 % or more of the bar update |
| C8 and R3-B, typed parsed records | The bench cells with the largest `jsGetKey` share have `parsing: false` | P-post: the parse and `jsGetKey` at 10 % or more of `chart.line.primitive` |
| Typed data and dataset contexts | The public shape of a typed context is a decision of Chart.js ADR 0052; `getContext` is 6.2 % of `chart.c` | after Chart.js ADR 0052, `getContext` at 5 % or more of the `chart.c` update |
| R2-D, a slot index of the animated bar and arc properties | A draw-frame cost of the animator, not in an update figure | the motion frame series after C7 |

Rejected:
- **A typed cache object of `Resolver`.** The port makes these objects once for each scope list
  (26 for each update at N 100 and at N 1000).
- **Typed scopes, typed resolvers, a resolver over the typed objects of Chart.js ADR 0052.** The
  scope reads do not grow with N. Chart.js ADR 0043, Alternatives: typed resolvers omit prefixed
  keys, descriptors and raw keys.
- **A cacheable context resolver.** It changes `_cacheable`, which a scriptable animation option
  reads. **A memo of `needContext`.** A user descriptor function is user code, and upstream calls
  it for each element.
- **Identity-keyed caches of the prefix lists.** The prefix lists are new for each call
  (`core.datasetController.js:815`). **A 2-read line loop.** Chart.js ADR 0036 §8 keeps the 3-read
  form. **Slot ids on `Element`.** A new API on each element class for the gain of R2.
- **`element-assign-no-key-list` of step 7.** Z2 replaces it. **Typed option writes of the
  bubble.** Merged into Z3; the copy stays (upstream work, `controller.bubble.js:151-168`).

## Consequences

- The resolver classes, the controllers and the elements stay line-by-line ports. Four rows record
  the changes of structure (C1, F3, M and, after its profile, C7).
- Each fast path keeps a second form in the tree. The switch, D1 and `test:nofast` keep both forms
  tested. The switch costs nothing in a timed build (section 2).
- An upstream bump compares the upstream lines that each row names. C7 depends on the shapes of
  `_resolveAnimations`, `configure`, the animation defaults and the G1 sites. F3 depends on what a
  scriptable option gets.
- The night calendar decides the release date. A series that does not fit a night moves the
  calendar.
- A hot-path change can move an untouched draw through the code layout of AOT (+1.1 to +2.3 % in
  step 7, §13.6), and less allocation can move a scavenge into the draw. The guard cells, the
  control screen and the frame-sum metric catch both.

## Open

1. **C6.** No work before P3-final. A corrected design (the epoch check after each user call, a
   fresh read of the later names) comes only when its trigger fires.
2. **C7.** It waits for P-M of N-R1 (section 5).
3. **The upstream motion figures.** §14.9 has no motion cell upstream. P3-base measures them.
4. The points that the porting lead decided on 2026-10-30 (closed): the deciding platforms are
   macOS and the dedicated Chrome, and the Pixel 8a and the iPhone 17 Pro are added platforms with
   a blocking confirmation; K and R2 carry no marker; the resolver decision is this ADR, apart from
   Chart.js ADR 0052; the test leg `test:nofast` exists; the upstream P3 page is committed; the
   canvas fallback is asked only when P3-final misses 1.5.

## Evidence

The working files of phase 10 in `.handover/phase10/panel/` (not committed):
- `brief.md`; the drafts `r-a.md` (exact upstream semantics), `r-b.md` (the largest gain) and
  `r-c.md` (the gain for each hunk); the verdict `judge-r.md`; `lead-decisions.md` ("Panel R").
- `probes/r-a/` (the call counts for each point; the F3 probe patch, 7852 tests passed),
  `probes/r-b/` (the counts of the motion and bar paths), `probes/r-c/` (the Dart 3.13.5 SDK
  sources of the dart2wasm string and the VM hash Map), `probes/judge-r/` (`probe_output.json`: 52
  `Animations` objects with 1 distinct content, the C6 hazard radii, the 4 resolver writes of
  `Chart.ensureScalesHaveIDs`; `cells_mac_vs_web.out`: macOS AOT against dart2wasm at N 1000).
- [performance.md](../performance.md) §10.10, §13.6, §13.7, §14.9 and §15.3.
- The check of the switch (section 2): a probe program with the builds `dart compile exe`, `dart
  compile wasm -O2` and `dart compile js -O2` of Dart 3.13.5 (a working file of phase 10).
- `.handover/phase7/perf/step7/patches/bar-index-memo.patch` (M) and the step 7 figures of §13.6.
