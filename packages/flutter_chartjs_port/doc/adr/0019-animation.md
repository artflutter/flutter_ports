# Chart.js ADR 0019: Animation

- Status: accepted (2026-10-21)
- Date: 2026-10-19
- Related: [Chart.js ADR 0001](0001-theming.md) (theming),
  [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (options and the `undefined`
  sentinel), [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (no display-only JS
  exactness), [Chart.js ADR 0010](0010-js-numeric-semantics.md) (JS numeric
  semantics and the clock), [Chart.js ADR 0012](0012-dart-file-naming.md) (names),
  [Chart.js ADR 0016](0016-frame-scheduling.md) (frame scheduling),
  [Chart.js ADR 0017](0017-element-properties.md) (element properties),
  [Chart.js ADR 0018](0018-typed-element-options.md) (typed element options),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) (registry and component classes),
  [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) (typed options in the resolver),
  [Chart.js ADR 0022](0022-chart-test-harness.md) (chart test harness on Flutter),
  [theming.md](../theming.md) §3.3, §3.7, §3.8 and §11,
  [porting-flow.md](../porting-flow.md) §1.1 and §2.9, [performance.md](../performance.md) §8.4

## Context

Phase 5 ports three upstream files: `src/core/core.animation.js` (119 lines),
`src/core/core.animations.js` (162 lines) and `src/core/core.animator.js` (214 lines). Phases 2 to
4 ported their dependencies: `core.animations.defaults`, `helpers.easing`, `helpers.color`,
`@kurkle/color`, `resolve` of `helpers.options` and `requestAnimFrame` of `helpers.extras`.
[porting-flow.md](../porting-flow.md) §2.9 calls the evidence for this decision thin. It asks for
the tests of `core.animator.tests.js` and of the 400 ms hover transitions. It leaves reduced motion
and the theme modes open.

**`Animation`** (`core.animation.js:27-119`) animates one property of one target.
- The constructor reads the current value `target[prop]` (`:29`). It resolves the target value with
  `resolve([cfg.to, to, currentValue, cfg.from])` and the start value with
  `resolve([cfg.from, currentValue, to])` (`:31-32`).
- It selects the interpolator with `cfg.fn || interpolators[cfg.type || typeof from]` (`:35`).
  `interpolators` has the keys `boolean`, `color` and `number` (`:6-25`). Another `typeof` result
  gives `undefined`. The next interpolation then throws a `TypeError` (`:102`).
- It reads `Date.now()` for `_start` (`:37`).
- `update` (`:51-65`) gives an active animation a new target value. `cancel` (`:67-74`) ticks one
  more time at `Date.now()` (`:70`) and stops the animation.
- `tick(date)` (`:76-103`) writes `target[prop]` one time: the target value at the end (`:88`), the
  start value before the start (`:94`), or the interpolated value (`:102`). It tests `from !== to`
  (`:85`).
- The color interpolator parses `from` and `to` with `helpers.color` in each call (`:16-17`). It
  mixes the two colors with `@kurkle/color` and returns a hex string (`:18-20`).
- `wait()` (`:105-110`) returns a new `Promise`. `_notify` (`:112-118`) calls `res` or `rej` of each
  promise. The list of promises stays after a call. Thus `update` can reject a promise (`:53`).
  The end of the animation can later resolve the same promise again (`:89`). JavaScript ignores
  the second call.

**`Animations`** (`core.animations.js:6-162`) makes the animations of one update.
- `configure` (`:13-37`) reads `Object.keys(defaults.animation)` (`:18`) and
  `Object.getOwnPropertyNames(config)` (`:21`). It copies the keys of `defaults.animation` into a
  new plain object for each config entry (`:26-29`). All properties of that entry share this object
  (`:31-35`).
- For a resolver, `Object.getOwnPropertyNames` gives the result of the `ownKeys` trap: the keys of
  all scopes (`helpers.config.ts:94-96`). `Object.keys` filters these keys through the
  `getOwnPropertyDescriptor` trap. That trap reads only the first scope (`helpers.config.ts:73-75`).
  Thus `Object.keys` drops each key that only a later scope holds, for example a key of the
  defaults.
- `_createAnimations` (`:68-109`) reads `Date.now()` one time (`:73`). It walks the keys from the
  last to the first (`:76`). A key with a cfg and an active animation updates that animation
  (`:90-94`). Another key with an animation cancels it (`:96`). A key without a cfg or without a
  duration gets its value at once (`:99-103`). Else the key gets a new `Animation` (`:105`).
- `_animateOptions` (`:43-63`) animates the options object of a target. For new shared options, it
  gives the target these options after all its option animations end:
  `awaitAll(...).then(...)` (`:51-60`). `awaitAll` (`:134-145`) calls `Promise.all` (`:144`).
- `resolveTargetOptions` (`:147-162`) copies shared old options into a new object before the
  animation (`:159`).
- `update` (`:118-131`) calls `Object.assign(target, values)` when no property animates (`:121`).
  It returns `true` or `undefined`.
- The promises of `src` are in these two files only (`core.animation.js:107`,
  `core.animations.js:55`, `:144`).

**`Animator`** (`core.animator.js:12-214`) is one module-level object (`:214`).
- `_refresh` (`:38-52`) registers one `requestAnimFrame` callback. The callback calls `_update`
  and clears `_request`. It registers again while `_running` is true.
- `_update(date = Date.now())` (`:57-107`) walks `this._charts` with `Map.prototype.forEach`
  (`:60`). It ticks each active item from the last to the first. It removes an inactive item with
  a swap (`:69-86`). Then it calls `chart.draw()` and the `progress` listeners (`:88-91`). When no
  item stays, it calls the `complete` listeners (`:93-97`). `remaining` counts the items of the
  local list (`:99`).
- `_notify` (`:23-33`) makes a new event object `{chart, initial, numSteps, currentStep}` for each
  listener.
- `listen`, `add`, `has`, `start`, `running`, `stop` and `remove` (`:135-210`) are the API that
  `core.controller.js` calls (`:188-189`, `:260`, `:270`, `:688-694`, `:930`). `stop` gives the
  chart a new empty list (`:200`).

**Targets.** Three kinds of objects get animations:
- elements: `updateElement` (`core.datasetController.js:902`) and `_setStyle` (`:919-927`)
- options objects: `updateSharedOptions` (`:910-914`) and `_animateOptions`
- the dataset meta: `anims.update(meta, {visible})` (`core.controller.js:903`). The `hide`
  transition writes the result of `fn: v => v | 0` (`core.animations.defaults.js:67`), the number
  1, into `meta.visible`.

The specs also animate plain objects, for example `{prop: false}` (`core.animation.tests.js:3`).

**The 400 ms hover transition.** `setHoverStyle` and `removeHoverStyle` call `_setStyle` with the
mode `'active'` (`core.datasetController.js:929-935`). `_resolveAnimations` resolves
`transitions.active` with `duration: 400` (`core.animations.defaults.js:38-42`). Thus the colors
and the numbers of the hovered element animate for 400 ms. An un-hover (`removeHoverStyle`) passes
the shared options (`core.datasetController.js:925`). After 400 ms, `awaitAll` gives the element
the shared object again (`core.animations.js:51-60`).

**Frame order.** [Chart.js ADR 0016](0016-frame-scheduling.md) decision 1 puts `requestAnimFrame`
on `SchedulerBinding.scheduleFrameCallback`. Decision 9 makes each input event a throttled frame
callback. The frame callbacks of one frame run in registration order. The animator registers its
next callback inside its callback of the frame before. An event arrives after that frame. Thus, in
each frame of an animation, the animator callback runs before the event callbacks. Flutter runs the
microtasks of a frame after all frame callbacks of that frame. A browser runs them after each
callback. The Consequences of Chart.js ADR 0016 record this difference.

**Specs.** The three spec files have 16 cases: 6 in `core.animation.tests.js`, 8 in
`core.animations.tests.js` and 2 in `core.animator.tests.js`. 15 cases make no chart.
`core.animator.tests.js:2-39` makes a bar chart. `controller.bar` is a phase 7 module
([porting-flow.md](../porting-flow.md) §5). `acquireChart` sets `animation: false`
(chartjs-test-utils `src/utils.js:58-60`). Thus the hover specs test end states only. No upstream
spec covers the 400 ms path. Six fixtures drive the animator through `_getAnims`, `_refresh` and
`_update`:
`controller.bar/bar-animation-hide-show.js`, `controller.doughnut/doughnut-animation-hide-last.js`,
`controller.doughnut/doughnut-animation.js`, `controller.polarArea/last-slice-animate.js`,
`controller.polarArea/polar-area-animation-rotate.js` and
`controller.polarArea/polar-area-animation-scale.js` (for example `:60-78`).

**Reduced motion.** `src` contains no `prefers-reduced-motion` and no `matchMedia` (a search at
v4.5.1). Thus Chart.js animates under the reduced-motion preference of the browser.

**Port.** These decisions give the base:
- [Chart.js ADR 0016](0016-frame-scheduling.md): the animator stays one module-level object on
  `requestAnimFrame` (decision 6). The chart host mutes a chart under `TickerMode(enabled: false)`
  through `mute` and `unmute` (decision 7). Decision 12 gives three items to this ADR. They are
  reduced motion, the `'themeFrame'` and `'default'` modes of a theme change, and the tests of
  `core.animator.tests.js` and of the 400 ms hover transitions.
- [Chart.js ADR 0010](0010-js-numeric-semantics.md) §6: `jsDateNow()` reads `clock.now()`. The
  `FakeAsync` zone of `testWidgets` moves that clock. §6 lists the call sites, also
  `core.animation.js:37`.
- [Chart.js ADR 0017](0017-element-properties.md) §5: `Element` has `operator []` and
  `operator []=` by the JS name. §7: `$animations` is a `Map<String, types.Animation>?`.
- [Chart.js ADR 0018](0018-typed-element-options.md): the resolved element options are Maps with a
  field for each known key. `resolveTargetOptions` copies into the same class (§5).
  [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) §3 gives the copy function.
- `jsCall` (`lib/src/js/js_function.dart`) calls a JS function value with the JS arity.

[performance.md](../performance.md) §8.4 measured the draw of 20000 point elements. It took 6.6 ms
on macOS and 14.7 ms on the Pixel 8a. It took 25.4 ms in Chrome with dart2wasm and 4.9 ms on the
iPhone. During an animated data update, the animator ticks 40000 properties in each frame before
that draw.

## Decision

### 1. Files, layers and names

- `lib/src/core/core.animation.dart` ports `core.animation.js`. It is a pure layer. Tool 1 adds it
  to the pure-layer roots of `tool/src/lib_imports.dart`.
- `lib/src/core/core.animations.dart` and `lib/src/core/core.animator.dart` port the other two
  files. They are not pure layers, because `core.animator.dart` imports `helpers.extras.dart`
  ([Chart.js ADR 0016](0016-frame-scheduling.md), decision 10).
- The port-only file `lib/src/core/animation_spec.dart` declares `AnimationSpec` (section 4). It is
  a pure layer and a root of tool 1.
- The JS runtime gets these port-only parts. Each part is a pure layer.
  - `lib/src/js/js_date.dart`: `double jsDateNow()`
    ([Chart.js ADR 0010](0010-js-numeric-semantics.md) §1 and §6).
  - `lib/src/js/js_object.dart`: `String jsTypeof(Object? value)`. It gives `'undefined'` for the
    sentinel, `'boolean'` for a `bool`, `'number'` for a `num` and `'string'` for a `String`. A
    value for which `jsIsFunction` is true gives `'function'`. These values are a `Function`, a
    `JsFunction` and a class value of
    [Chart.js ADR 0020](0020-registry-and-component-classes.md) §2. Dart `null` and every other
    value give `'object'`.
  - `lib/src/js/js_array.dart`: `List<String> jsOwnPropertyNames(Map<String, Object?> object)`. A
    `JsProxyObject` gives its `keys`, the `ownKeys` trap. Another Map gives `jsObjectKeys`.
  - `lib/src/js/js_map.dart`:
    `void jsMapForEach<K, V>(Map<K, V> map, void Function(V value, K key) callback)` (section 8).
  - `lib/src/js/js_promise.dart`: `jsEnqueuePromiseJob`, `jsRunWithMicrotaskCheckpoint` and
    `jsPromiseAll` (section 7).
- `lib/src/types/index.dart` gets two declarations:
  - the port-only interface `PropertyAccess implements ElementPropertyRead`, with
    `void operator []=(String prop, Object? value)`. `Element` adds it to its `implements` list.
    `Element` already has both operators ([Chart.js ADR 0017](0017-element-properties.md) §5).
  - `void draw()` in `Chart` (`index.d.ts:531`). The animator calls it (`core.animator.js:89`).
- `lib/src/types/animation.dart` gets the interface `AnimationEvent` (`animation.d.ts:13-18`), with
  the getters `chart`, `initial`, `numSteps` and `currentStep`.
- Names follow [Chart.js ADR 0012](0012-dart-file-naming.md). The specs and the animator read some
  `_` members. These members drop the underscore and carry `@internal`:
  - `Animation`: `start` (`_start`), `duration` (`_duration`), `total` (`_total`), `from`
    (`_from`) and `to` (`_to`, also the getter `types.Animation.to`). `from` and `to` have
    `@internal` setters, because the specs write them (`core.animation.tests.js:28`, `:32-33`).
  - `Animations`: `properties` (`_properties`).
- `_active` keeps the underscore, because the method `active()` has the name `active`. The animator
  reads `item._active` (`core.animator.js:72`) through `item.active()`. That method returns the
  field (`core.animation.js:47-49`). This is a name change only. It needs no `DIVERGES` hunk.
- All other `_` members keep the underscore. Examples are `_fn`, `_easing`, `_loop`, `_target`,
  `_prop`, `_promises` and `_notify` of `Animation`, and `_refresh`, `_update`, `_getAnims` and
  `_lastDate` of `Animator`.
- `core.animations.js` does not export `awaitAll` and `resolveTargetOptions` (`:134`, `:147`). Thus
  they are the private functions `_awaitAll` and `_resolveTargetOptions` of
  `core.animations.dart`.
- `Animation` is also a class of `package:flutter/animation.dart`. A file that needs both classes
  imports one library with a prefix.

The signatures:

```dart
// lib/src/core/core.animation.dart
typedef Interpolator =
    Object? Function(Object? from, Object? to, double factor);

class Animation implements types.Animation {
  Animation(AnyObject cfg, Object target, String prop, [Object? to = undefined]);
  @override
  bool active();
  void update(AnyObject cfg, Object? to, double date);
  void cancel();
  void tick(double date);
  Future<void> wait();

  @internal
  double get start;
  @internal
  double get duration;
  @internal
  double get total;
  @internal
  Object? get from;
  @internal
  set from(Object? value); // calls _retarget (section 6)
  @override
  Object? get to;
  @internal
  set to(Object? value); // calls _retarget (section 6)
}

@internal
Object? readProperty(Object target, String prop);
@internal
void writeProperty(Object target, String prop, Object? value);

// lib/src/core/animation_spec.dart
final class AnimationSpec extends MapBase<String, Object?> {
  Object? get delayValue; // also durationValue, easingValue, fnValue,
  // fromValue, loopValue, toValue and typeValue
}

// lib/src/core/core.animations.dart
class Animations {
  Animations(types.Chart chart, Object? config);
  void configure(Object? config);
  bool? update(Object target, AnyObject values);
  @internal
  Map<Object?, AnimationSpec> get properties;
}

// lib/src/core/core.animator.dart
typedef AnimationListener = void Function(AnimationEvent event);

final class AnimationEvent implements types.AnimationEvent {
  AnimationEvent({required this.chart, this.initial, this.numSteps, this.currentStep});
}

class Animator {
  void listen(types.Chart chart, String event, AnimationListener cb);
  void add(types.Chart chart, List<Animation>? items);
  bool has(types.Chart chart);
  void start(types.Chart chart);
  bool running(types.Chart chart);
  void stop(types.Chart chart);
  bool remove(types.Chart chart);
  void mute(types.Chart chart); // Chart.js ADR 0016, decision 7
  void unmute(types.Chart chart); // Chart.js ADR 0016, decision 7
}

final Animator animator = Animator();

// lib/src/js/js_promise.dart
void jsEnqueuePromiseJob(void Function() job);
void jsRunWithMicrotaskCheckpoint(void Function() callback);
Future<List<T>> jsPromiseAll<T>(List<Future<T>> futures);
```

### 2. Targets: the read and the write by name

- A target is an `Object`: an `Element`, another `types.PropertyAccess`, or a
  `Map<String, Object?>`. Upstream declares `target: AnyObject` (`animation.d.ts:5`).
- `readProperty` and `writeProperty` are the Dart form of the JS property access on a target.
  - `readProperty(target, prop)` is `target[prop]`. A `types.PropertyAccess` gives its
    `operator []`. A Map gives `jsGet(target, prop)`. Thus an absent key gives `undefined`.
  - `writeProperty(target, prop, value)` is `target[prop] = value`. A `types.PropertyAccess` uses
    its `operator []=`. A Map stores the value under the key.
  - Another target throws an `ArgumentError`. JavaScript reads `undefined` from a primitive. A
    write to a primitive throws a `TypeError` in strict mode.
- The ported lines call these two functions at each upstream read and write of a target. In
  `core.animation.js`, the lines are `:29`, `:55`, `:88`, `:94` and `:102`. In
  `core.animations.js`, the lines are `:55`, `:56`, `:71`, `:101`, `:151`, `:153` and `:159`. The
  number path of section 6 is the one exception.
- The reads have no fast path. An animation reads its target in the constructor and in `update`
  only. Thus each read keeps the `undefined` state, NaN and JS `null`
  ([Chart.js ADR 0017](0017-element-properties.md) §4).
- The empty `$animations` object is `<String, Animation>{}`. `_createAnimations` makes it at
  `core.animations.js:71`. `_resolveTargetOptions` makes it at `:159`, in the copy of
  [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) §3. `_createAnimations` reads an
  entry with a cast to `Animation?`. The field type `Map<String, types.Animation>?` of `Element`
  accepts this Map.
- `Object.assign(target, values)` (`core.animations.js:121`) writes each key of
  `jsObjectKeys(values)` through `writeProperty`, in that order. For an `Element`, this is the
  behavior of `Element.assign`.
- The write order does not change. Each tick writes one time. The animator ticks the items from the
  last to the first (`core.animator.js:69-86`). `_createAnimations` walks the keys from the last to
  the first (`core.animations.js:76`).
- `undefined` and NaN keep the upstream results:
  - `resolve` gives `undefined` when every input is `undefined` (`core.animation.js:31`). The
    last tick writes it with `operator []=`. An element property then returns to its `undefined`
    state ([Chart.js ADR 0017](0017-element-properties.md) §4).
  - The number interpolator gives NaN for an `undefined` operand. The write by name stores NaN.

### 3. Configuration values

- `cfg` is an `AnyObject` (`animation.d.ts:5`). `configure` makes an `AnimationSpec` for each
  config entry (section 4). The specs pass Map literals.
- Each upstream read `cfg.<key>` goes through one small private function of `core.animation.dart`,
  for example `cfg is AnimationSpec ? cfg.durationValue : jsGet(cfg, 'duration')`. Both forms give
  `undefined` for an absent key. `resolve` (`helpers.options.ts:154-180`) needs this, because it
  skips `undefined`. Dart `null` is JS `null`, a defined value.
- The conversions follow [Chart.js ADR 0010](0010-js-numeric-semantics.md) §7:

| Upstream | Dart |
|---|---|
| `Math.floor(Date.now() + (cfg.delay \|\| 0))` (`core.animation.js:37`) | `(jsDateNow() + jsOrZero(delay)).floorToDouble()` |
| `Math.floor(cfg.duration)` (`:38`) | `jsToNumber(duration).floorToDouble()` |
| `Math.floor(Math.max(remain, cfg.duration))` (`:59`) | `jsMax(remain, jsToNumber(duration)).floorToDouble()` |
| `!!cfg.loop` (`:39`, `:61`) | `jsTruthy(loop)` |
| `effects[cfg.easing] \|\| effects.linear` (`:36`) | `effects[easing] ?? effects['linear']!` |
| `Date.now()` (`:70`) | `jsDateNow()` |
| `(elapsed / duration) % 2` (`:98`) | `(elapsed / duration).remainder(2)` |
| `Math.min(1, Math.max(0, factor))` (`:100`) | `jsMin(1, jsMax(0, factor))` |
| `!cfg.duration` (`core.animations.js:99`) | `!jsTruthy(duration)` |

- A String `delay` is outside the type contract (`delay?: number`, `index.d.ts:1727`). JavaScript
  appends the String to the text of `Date.now()`. The port adds the `ToNumber` of the String.
  [Chart.js ADR 0017](0017-element-properties.md) §5 states the rule for such a value: it is not a
  `DIVERGES` hunk.
- `Object.keys(defaults.animation)` (`core.animations.js:18`) reads `defaults.animation`. A Map
  gives `jsObjectKeys`. The value `false` gives no keys, as `Object.keys(false)` gives `[]`. Dart
  `null` and `undefined` throw a `TypeError`, as in JavaScript.
- `Object.getOwnPropertyNames(config)` (`:21`) is `jsOwnPropertyNames(config)`. `jsObjectKeys` is
  not correct here. On a resolver, it gives only the keys of the first scope (Context).
- `cfg.properties` (`:31`) is `jsGet(cfg, 'properties')`. A `List` gives its items. Another value
  gives `[key]`. An empty `List` gives no items. JavaScript tests `isArray` first. An empty array is
  truthy.
- `_properties` is a `Map<Object?, AnimationSpec>`, because a JS `Map` takes a key of any type.
  `_createAnimations` reads it with the String keys of `values` (`:88`).
- Each `Animation` constructor reads `jsDateNow()` (`:37`), as upstream reads `Date.now()`.
  [Chart.js ADR 0010](0010-js-numeric-semantics.md) §6 lists this call site. One clock read for
  each `_createAnimations` call is an open question (Open).

### 4. `AnimationSpec`

- `configure` makes an `AnimationSpec` where upstream makes `{}` (`core.animations.js:26`). It
  writes the keys of `Object.keys(defaults.animation)` in their order (`:18`, `:27-29`).
- `AnimationSpec` is a final Map. It has one field for each key of `defaults.animation`
  (`core.animations.defaults.js:5-14`), in this order: `delay`, `duration`, `easing`, `fn`,
  `from`, `loop`, `to` and `type`. Another key goes to a Map of extra keys. A user can add such a
  key to `defaults.animation`.
- It follows the Map protocol of [Chart.js ADR 0018](0018-typed-element-options.md) §3. A private
  sentinel marks an absent key. The getter `<key>Value` gives the raw value, or `undefined` for an
  absent key. This is the result of `jsGet(spec, key)`.
- `AnimationSpec` extends `MapBase<String, Object?>`.
  [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) declares no common base class for
  typed Maps outside the element options. `ElementOptions` of
  [Chart.js ADR 0018](0018-typed-element-options.md) has fields for `$shared` and `$animations`.
  Thus it is not a base for `AnimationSpec`. If a later decision adds a common base, `AnimationSpec`
  extends it.
- An `AnimationSpec` is not a product of the resolver. `configure` makes it from the resolved
  values of one config entry. Thus Chart.js ADR 0021 does not decide it.
- The reason is the cost of the constructor. With a Map cfg, one `Animation` constructor costs
  168 ns (AOT) and 229 ns (wasm). With a typed cfg, it costs 105 ns and 141 ns (Evidence, F5). The
  performance probe gave 210-219 ns against 89-93 ns (AOT), and 275-289 ns against 132-140 ns
  (wasm) (Evidence, P5). An update of 20000 points makes 40000 animations. Thus the typed cfg saves
  2.5 to 5.2 ms (AOT) in each such update.
- The hunk at `core.animations.js:26` carries
  `// DIVERGES(chartjs): adapt-animation-spec, a typed copy of the animation options.`

### 5. Interpolators and `_fn`

- `_interpolators` is a `Map<String, Interpolator>` with the upstream keys in the upstream order
  (`core.animation.js:6-25`):
  - `boolean`: `factor > 0.5 ? to : from` (`:7-9`).
  - `number`: `jsToNumber(from) + (jsToNumber(to) - jsToNumber(from)) * factor` (`:22-24`).
    JavaScript applies the same `ToNumber` to a number, a boolean, `null` and `undefined`.
  - `color`: a line-by-line port (`:15-21`). `from || transparent` is
    `jsTruthy(from) ? from : _transparent`. `c0.valid` is `c0 is Color && c0.valid`, because
    `helpers.color` returns a `CanvasGradient` or a `CanvasPattern` unchanged. In JavaScript, such
    an object has no `valid` property.
- For an object or a String operand, the JS `+` of the number interpolator appends text. The port
  gives NaN or a number. Two cases occur:
  - The object form of the bar `borderWidth` is in the type contract (`index.d.ts:2132`). It
    reaches the number interpolator through the `numbers` property list
    (`core.animations.defaults.js:1`, `:27-30`). Upstream writes `'[object Object]NaN'`. The port
    writes NaN. The bar reads the value only through `toTRBL` (`element.bar.js:42-44`). There,
    `numberOrZero` gives 0 for both values (`helpers.options.ts:43`, `:62`). Thus the difference
    is display-only ([Chart.js ADR 0009](0009-no-display-only-js-exactness.md)). The port does not
    emulate it. It is not a `DIVERGES` hunk.
  - A String `from` is outside the type contract (`from: Color | number | boolean`,
    `index.d.ts:1750`). From `'2'` to `3`, the factor 0.5 gives `'20.5'` in JavaScript (Evidence,
    F8). It is not a `DIVERGES` hunk ([Chart.js ADR 0017](0017-element-properties.md) §5).
- **`_fn` resolved one time.** `_fn` is an `Interpolator?`. The constructor resolves it from line
  `:35`:

  ```dart
  final fn = _cfgFn(cfg);
  final type = _cfgType(cfg);
  _fn = jsTruthy(fn)
      ? (f, t, x) => jsCall(fn, [f, t, x], thisArg: this)
      : _interpolators[jsTruthy(type) ? jsToString(type) : jsTypeof(from)];
  ```

  - A built-in interpolator is the `_fn` itself.
  - A user `fn` gets one closure. The closure calls it through `jsCall` with the JS arity. Thus the
    `hide` function with one parameter gets `from` only, as in JavaScript. A `JsFunction` gets the
    animation as `this`, as `this._fn(...)` gives in JavaScript.
  - A key without an interpolator gives Dart `null`, where upstream gives `undefined`. `tick` calls
    `_fn!(from, to, factor)` at `:102`. Thus the port throws a `TypeError` at the same tick as
    JavaScript.
  - A truthy `fn` that is not a function throws an `ArgumentError` in `jsCall` at the same tick.
    JavaScript throws a `TypeError` there. `jsCall` documents this rule.
  - The reason is the cost of a type test of `_fn` in each tick. At 20000 x 2, it costs 0.06 to
    0.13 ms (AOT) and 0.29 to 0.38 ms (wasm) in each frame (section 11). The resolved closure gives
    the same calls.
- `type` and `easing` names of `Object.prototype` members, for example `'toString'`, are outside the
  type contract (`index.d.ts:1721`, `:1743`). The two Dart Maps give no interpolator and the
  `linear` effect for them. Upstream finds the inherited members. This is not a `DIVERGES` hunk
  ([Chart.js ADR 0017](0017-element-properties.md) §5).
- **Color cache.** When `_fn` is the color interpolator, the constructor gives the animation its own
  color interpolator object (`_ColorInterpolator`).
  - That object keeps the parsed `from` and `to` of its last call. It compares the next values with
    `identical`. It parses again after a change, also after `update` and after a spec writes
    `from` or `to`.
  - It calls `clone()` on the cached target color before `mix`, because `mix` changes its receiver.
    `mix` does not change its argument.
  - A `from` or a `to` that is not a String uses the line-by-line interpolator.
  - The results are the results of the line-by-line interpolator. Probe F4 found 0 differences in
    40590 cases. Probe S7 found 0 differences in 9801 cases.
  - A color tick costs 1832 to 1943 ns (AOT) and 1460 to 1732 ns (wasm) line by line. With the
    cache, it costs 437 to 489 ns (AOT) and 250 to 310 ns (wasm) (Evidence, F1).
  - The hunk carries `// DIVERGES(chartjs): adapt-animation-color-cache, one parse of each color.`
- `from !== to` (`:85`) is `from != to`. Dart `==` gives the JS result for the values of an
  animation. NaN differs from NaN. 0 equals -0. Two Maps compare by identity. `identical` gives a
  wrong result: `identical(double.nan, double.nan)` is true on the VM and on dart2wasm (Evidence,
  F1).

### 6. The number path

- An animation with the built-in `number` interpolator and two `double` values ticks on two
  `double` fields. All other animations take the generic path, the upstream lines of `tick`.
- `Animation` gets four private members: `bool _numberPath`, `double _fromNumber`,
  `double _toNumber` and `int _xy`.
- `_retarget()` sets `_numberPath` to
  `identical(_fn, _number) && _from is double && _to is double`. On the number path, it copies
  `_from` and `_to` into the two fields. The constructor, `update` and the `@internal` setters of
  `from` and `to` call it. No other code changes `_fn`, `_from` or `_to`.
- The constructor resolves `_xy` one time. It is 1 for the property `x` of an `Element`, 2 for `y`
  of an `Element`, and 0 else. The target and the property of an animation never change
  (`core.animation.js:40-41`).
- `tick` starts with `if (_numberPath) { _tickNumber(date); return; }`. `_tickNumber` runs the
  upstream lines of `tick` (`:77-102`) on the two fields.
  - For two `double` values, Dart `from != to` is the JS `!==`.
  - `from + (to - from) * factor` is the result of the number interpolator.
  - A write with `_xy` 1 or 2 calls the setter `Element.x` or `Element.y`
    (`core.element.ts:11-12`). For a `double`, the setter stores the state of the write by name
    (`toNumberProp`, [Chart.js ADR 0017](0017-element-properties.md) §5). No element class handles
    `x` or `y` in its own `operator []=`. Every other write calls `writeProperty`.
- The generic path has no fast path for `x` and `y`. After the number path, the generic path
  writes `x` or `y` only when one value is not a `double`, or when a user `fn` exists. No measured
  scenario has such writes.
- The writes, their order, their values and their types are the upstream ones. The `undefined`
  state, JS `null`, strings and booleans keep the generic path, because the test needs two `double`
  values. NaN, -0 and the infinities are `double` values. The number path gives the upstream
  results for them (Evidence, P3).
- An `int` from a Dart literal also takes the generic path on the VM and on dart2wasm. The result
  is the same.
- `tick`, `_tickNumber`, `_retarget` and its four calls carry
  `// DIVERGES(chartjs): adapt-animation-number-path, numbers on two double fields.`
- The reason: at 20000 points x 2, the number path takes 0.28 to 0.37 ms off each frame on wasm
  (616-670 µs against 954-985 µs). At 1000 arcs x 6, it saves 0.02 to 0.03 ms (AOT) and 0.04 to
  0.05 ms (wasm). On AOT, the 20000 x 2 figures are equal (section 11).

### 7. Promises

- `wait()` (`core.animation.js:105-110`) returns a `Future<void>`. `_promises` is a
  `List<Completer<void>>?`. Each call adds one `Completer<void>.sync()`.
- `_notify(resolved)` (`:112-118`) gives one job for each completer to `jsEnqueuePromiseJob`.
  - The job does nothing for a completed completer, as a settled promise ignores `res()` and
    `rej()`. `Completer.complete` throws a `StateError` on a completed completer (Evidence, F7).
  - Else the job calls `complete()` or `completeError(undefined)`. `rej()` passes no reason. Thus
    the error object is the `undefined` sentinel.
- `jsPromiseAll(futures)` is `Promise.all`.
  - A list with items gives `Future.wait(futures, eagerError: true)`. `Promise.all` also rejects at
    the first rejection (Evidence, F8).
  - For a list with items, the result is the future of a `Completer.sync()`. `Future.wait`
    completes or fails in the job that settles the last item or the first rejected item. Then a
    new job of `jsEnqueuePromiseJob` settles the result. `Promise.all` also settles in the reaction
    job of that item, and its `then` runs in a later job. Thus a continuation of the result runs
    one job after that item, as in JavaScript.
  - An empty list gives the future of a `Completer.sync()`. A job of `jsEnqueuePromiseJob`
    completes it with an empty list (Evidence, J3). `Future.wait([])` completes in a Dart
    microtask, also inside a checkpoint (Evidence, J2). `Promise.all([])` settles in a promise
    job.
  - `awaitAll` passes only the futures of active animations. These futures are not complete yet.
    Thus `Future.wait` registers its listeners before the jobs settle the futures.
- `awaitAll` (`core.animations.js:134-145`) returns `jsPromiseAll(running)` (`:144`). This is the
  translation of a JS builtin. It needs no `DIVERGES` hunk.
- `.then(onFulfilled, onRejected)` (`:55-59`) is `.then(onFulfilled, onError: onRejected)`. The
  rejection handler does nothing, as upstream.
- `jsRunWithMicrotaskCheckpoint(callback)` runs `callback`. Then it runs the queued jobs in their
  order, also the jobs that these jobs queue, until the queue is empty. A nested call runs its
  callback inside the outer checkpoint. The jobs also run when `callback` throws. This is the
  microtask checkpoint that a browser runs after each animation frame callback.
- `jsEnqueuePromiseJob(job)` adds `job` to the queue while a checkpoint runs. Else it calls
  `scheduleMicrotask(job)`.
- The animator frame callback (`core.animator.js:44-51`) runs inside
  `jsRunWithMicrotaskCheckpoint`. Thus a promise chain that the animator callback starts finishes
  at the end of that callback, before the next frame callback of the same frame. With the sync
  completers, `Future.wait` completes inside the job that settles the last future. The `then`
  callback of `awaitAll` runs in the later job that `jsPromiseAll` adds to the same checkpoint
  (Evidence, J2 and J3).
- Outside the animator callback, a job runs as a Dart microtask, after the synchronous code.
  Examples are `update()` from a throttled event callback, `chart.stop()` and user code. A browser
  runs these jobs at the end of the current task or frame callback. Thus one difference stays. The
  jobs that a throttled event callback queues run after all frame callbacks of the frame, not at
  the end of that callback.
- Two hunks carry
  `// DIVERGES(chartjs): platform-animation-promise-checkpoint, jobs settle at the checkpoint.`:
  `wait` and `_notify` in `core.animation.dart`, and the callback of `_refresh` in
  `core.animator.dart`.
- The reason is the resolved option on the element.
  - Without the checkpoint, a throttled event callback in the frame that ends an un-hover sees the
    copy of the options. A re-hover of the same element then animates that copy.
  - The microtask after the frame then gives the element the shared options. The element keeps the
    color without hover while the pointer is on it (Evidence, F7 and F8).
  - With the checkpoint, the port gives the browser result: a new copy with the hover color.
- **The row `platform-request-anim-frame`.** Its reason states that "the promise chain of
  `core.animations.js:55-59` finishes after a throttled callback of the same frame". The checkpoint
  makes this statement false for the chain that the animator callback starts.
  - The phase 5 change edits that row. The new text: the promise jobs of the animator callback run
    at its checkpoint (row `platform-animation-promise-checkpoint`). Other microtasks, also the
    promise jobs that a throttled callback queues, run after all frame callbacks of the frame.
  - This decision overrides one Consequences line of [Chart.js ADR 0016](0016-frame-scheduling.md)
    (proposed) for the jobs of the animator callback. The line is: "The microtasks of a frame run
    after all its transient callbacks. Thus the promise chain of `core.animations.js:55-59`
    finishes after a throttled callback of the same frame. In a browser, it finishes before that
    callback." The first sentence stays true for all other microtasks.

### 8. Animator

- `class Animator` ports `core.animator.js:12`. `final Animator animator = Animator();` ports
  `:214`.
- The fields are `int? _request`, `final Map<types.Chart, _Anims> _charts`, `bool _running` and
  `double? _lastDate` (`:13-18`). Upstream writes `_lastDate` and never reads it (`:17`, `:102`).
  The field stays, with `// ignore: unused_field` and the reason. A Dart `Map` keeps the insertion
  order, as a JS `Map` does. A `types.Chart` does not override `==`. Thus `_charts` compares keys by
  identity, as a JS `Map` compares objects.
- The private class `_Anims` stands for the object literal of `:116-124`. Its fields are
  `bool running`, `bool initial`, `List<Animation> items`,
  `Map<String, List<AnimationListener>> listeners` with the keys `'complete'` and `'progress'`,
  `double? start` and `double? duration`. Dart `null` stands for `undefined` in `start` and
  `duration` before the first `start(chart)`.
- `_notify` (`:23-33`) makes a new `AnimationEvent` for each listener. It walks the listeners by
  index up to the length at the start, as `Array.prototype.forEach` does. `numSteps` is
  `anims.duration`. `currentStep` is
  `jsMin(date - (anims.start ?? double.nan), anims.duration ?? double.nan)`.
- `AnimationEvent` has the fields `types.Chart chart`, `bool? initial`, `double? numSteps` and
  `double? currentStep`. Dart `null` stands for `undefined`, because `core.controller.js:694`
  passes `{chart: this}` only. JS `null` never reaches these fields.
- `_refresh()` (`:38-52`) calls `requestAnimFrame` with a plain call
  ([Chart.js ADR 0016](0016-frame-scheduling.md), decision 1). Its callback runs inside the
  checkpoint of section 7. The ids of `scheduleFrameCallback` start at 1. Thus
  `_request != null` is the upstream test of truthiness.
- `_update([double? date])` (`:57-107`) starts with `date ??= jsDateNow()`. Dart `null` stands for
  the omitted argument, as for the JS default parameter.
- `this._charts.forEach(...)` (`:60`) is `jsMapForEach(_charts, ...)`.
  - It visits an entry that a listener adds during the walk. It skips an entry that a listener
    deletes before its visit. ECMAScript `Map.prototype.forEach` does the same (Evidence, F8 and
    P8).
  - A listener can delete or add a chart. `onComplete` can call `chart.destroy()` or start a new
    chart. A Dart `Map.forEach` throws a `ConcurrentModificationError` for both changes (Evidence,
    F7, P8 and S1).
  - A chart that starts inside a listener of the last animated chart gets its ticks in the same
    frame. `remaining` counts its items. Thus the loop continues (Evidence, F7 and F8).
- `jsMapForEach` takes the list of keys. It calls `callback` with the current value of each key
  that the Map still contains. Then it repeats with the keys that it did not visit, until no such
  key exists. A key that the callback deletes and adds again after its visit gets no second visit.
  ECMAScript gives it a second visit. No Chart.js code does this. The `///` line of `jsMapForEach`
  states it. `jsMapForEach` translates a JS builtin. It needs no `DIVERGES` hunk.
- `_update` keeps the local list `items` (`:64`). A listener that calls `stop()` gives the chart a
  new list (`:200`). `_update` then counts the old list (`:99`). The port keeps this upstream
  behavior.
- `_update` swaps and removes an inactive item as upstream does (`:83-84`):
  `items[i] = items.last` and `items.removeLast()`.
- The API (`:135-210`) keeps the upstream behavior:
  - `listen` throws for an event name other than `'complete'` and `'progress'`, as the
    `undefined.push` of JavaScript throws. `listeners[event]!` throws a `TypeError`.
  - `add` takes Dart `null` for `undefined` (`core.animator.tests.js:43`).
  - `has` creates the record of the chart, as `_getAnims` does (`:156`).
  - `start` sets `duration` to `items.fold(0.0, (acc, cur) => jsMax(acc, cur.duration))` (`:170`).
  - `stop` reads `jsDateNow()` (`:201`).
  - `remove` returns true when the Map contained the chart (`:208-210`).
- `mute`, `unmute`, the `Expando` and the test in `_update` follow
  [Chart.js ADR 0016](0016-frame-scheduling.md) decision 7. They carry the rows
  `platform-animator-mute` and `platform-animator-skip-muted`.

### 9. Interfaces with other decisions

This decision needs these parts from other phase 5 decisions. Each part has the smallest form that
the animations need. Any reasonable form of the other decision that gives this part keeps this
decision valid.
- **`core.controller`:** `types.Chart.draw()`. The controller calls `listen`, `stop`, `running`,
  `has`, `start` and `remove` as upstream. It passes `AnimationEvent(chart: this)` at
  `core.controller.js:694`.
- **The dataset meta** (`core.controller.js:903`): the meta is a Map or a `types.PropertyAccess`.
  Its write by name of `visible` accepts the `double` 1 of the `hide` function. Its readers apply
  `ToBoolean`, for example `core.controller.js:744`. Its write by name of `$animations` accepts a
  `Map<String, Animation>`.
- **[Chart.js ADR 0021](0021-typed-options-in-the-resolver.md)** (typed options in the resolver):
  - `_resolveTargetOptions` copies `options` into a new Map of the same class
    ([Chart.js ADR 0018](0018-typed-element-options.md) §5). It needs one function that makes this
    copy in the key order of `Object.assign`. Chart.js ADR 0021 §3 gives `copyOptions`
    (`lib/src/elements/element_options.dart`). Its section 6 gives the row
    `adapt-typed-element-options` for this hunk. Chart.js ADR 0021 owns the hunk and the row.
  - Chart.js ADR 0021 declares no common base class for typed Maps (section 4).
  - Chart.js ADR 0021 §5 makes `Object.freeze` the function `jsObjectFreeze`. `Animations` does not
    implement `JsFreezable`. Thus `Object.freeze` of a cached `Animations`
    (`core.datasetController.js:858`, `plugin.tooltip.js:519`) changes nothing. No upstream code
    writes to an `Animations` after its constructor.
- **[Chart.js ADR 0022](0022-chart-test-harness.md)** (chart test harness):
  - a function that moves the fake time in frames of 16 ms until a given time passes
  - a function that pumps frames of 16 ms until a condition is true, with a limit of fake time
  - `acquireChart` keeps `animation: false` as its default.
  - Chart.js ADR 0022 §7 gives `setTimeout` (a harness task), `pumpFrames` and `waitForDone`.
    They satisfy this need. Chart.js ADR 0022 §4 keeps the default of `acquireChart`.
- **[Chart.js ADR 0020](0020-registry-and-component-classes.md)** (registry):
  - `src/core/index.ts:3-5` exports `Animation`, `Animations` and `animator`. The phase 5 port of
    that file exports them (Chart.js ADR 0020 §6).
  - `jsIsFunction` gives true for a class value (Chart.js ADR 0020 §2). `jsTypeof` follows it
    (section 1).

### 10. Theme modes and reduced motion

- **Theme modes: no code in the three files.** `'theme'` and `'themeFrame'` are transition keys.
  The theme compiler emits `transitions.theme.animation.{duration,easing}` and
  `transitions.themeFrame.animation.duration: 0` ([theming.md](../theming.md) §3.3). The resolver
  reads them through `datasetAnimationScopeKeys` (`core.config.js:229-242`).
  - `'theme'` animates the colors for 200 ms with `'linear'` ([theming.md](../theming.md) §3.8).
  - `'themeFrame'` has the duration 0. `_createAnimations` then writes each value at once
    (`core.animations.js:99-103`). An active animation gets a new target value (`:90-94`). It keeps
    its end time, because `update` takes `Math.max(remain, cfg.duration)` (`core.animation.js:59`).
    [theming.md](../theming.md) §11 lists this effect.
  - Theme removal uses `'default'`, as any upstream option change does.
- **Reduced motion: no code in the core. The phase 9 widget selects the policy.** The core, the
  animator and the chart host contain no reduced-motion code. The reasons, in the order of
  [porting-flow.md](../porting-flow.md) §1.1:
  - Behavior: upstream contains no reduced-motion code. Each form of reduced motion is port-only
    behavior. The upstream-faithful core has no such code.
  - The preference comes from `MediaQuery.maybeDisableAnimationsOf(context)`
    (`widgets/media_query.dart:1961`, Flutter 3.44.9). Ported code has no `BuildContext`.
  - The policy is part of the public widget API: no animation, or a shorter animation, or the theme
    switch only. Flutter scales an `AnimationBehavior.normal` animation by 0.05 under
    `disableAnimations` (`animation/animation_controller.dart:651`). Phase 9 decides that API.
  - Each candidate of phase 9 (Open) fits into one hunk of `core.animations.dart` or into the
    options of the widget. Thus a later decision needs no change to this decision.
- The phase 9 decision must not write `defaults.animation`. `defaults` is global.
  [Chart.js ADR 0001](0001-theming.md) gives the same reason for its third invariant.
- Until phase 9, theme removal under reduced motion animates for 1000 ms
  ([theming.md](../theming.md) §11).

### 11. Cost

The figures of the table come from the judge probe J1 (Evidence). Each variant is one executable or
one wasm module. Thus the tick call site is monomorphic. "AOT" is `dart compile exe` with Dart
3.12.2. "wasm" is `dart compile wasm -O2`, run in Node.js v24.12.0 (arm64). A cell gives the time of
one animator frame in microseconds, with all items active, as the lowest and the highest of the
runs.

| Form | 20000 points x 2, AOT | 20000 points x 2, wasm | 1000 arcs x 6, AOT | 1000 arcs x 6, wasm |
|---|---|---|---|---|
| U: the upstream literal (`jsCall` for each `_fn`, write by name) | 1892-1937 | 2846-2888 | 244-249 | 393-394 |
| F: the fidelity draft (`fn is Interpolator` in each tick, an `x` and `y` fast path in `writeProperty`) | 852-876 | 1271-1329 | 158-163 | 234-240 |
| F2: F with `_fn` resolved one time | 744-793 | 954-985 | 139-147 | 184-189 |
| S: the simplicity draft (`_fn` and a write closure resolved one time) | 738-823 | 895-1007 | 146-153 | 190-201 |
| N: F2 with the number path (decided). All items of this probe take the number path. | 738-784 | 616-670 | 120 | 139-145 |
| P: N with `NumberSlots` for each numeric property (Open) | 713-760 | 568-590 | 91-96 | 75-80 |

- The decided form N costs 18 to 20 ns (AOT) and 15 to 17 ns (wasm) for each tick at 20000 points.
  That is 11 to 12 % of the macOS draw time and 2.4 to 2.6 % of the Chrome draw time of
  [performance.md](../performance.md) §8.4. The wasm figure comes from Node.js, not from Chrome.
- A color tick costs 1832 to 1943 ns (AOT) and 1460 to 1732 ns (wasm) line by line. With the cache,
  it costs 437 to 489 ns (AOT) and 250 to 310 ns (wasm) (Evidence, F1).
- A write by name of `PointElement['x']` costs 6.7 to 7.2 ns (AOT). The setter costs 4.4 ns. For
  `ArcElement['startAngle']`, the costs are 12.1 to 12.2 ns and 3.3 to 3.4 ns. On wasm, the four
  costs are 22.2 to 34.1 ns, 14.4 to 17.1 ns, 16.5 to 17.4 ns and 9.7 ns (Evidence, F2).
- One `Animation` constructor costs 105 ns (AOT) and 141 ns (wasm) with an `AnimationSpec`
  (Evidence, F5). One `jsDateNow()` call costs 33 to 47 ns (AOT) and 38 to 55 ns (wasm) (Evidence,
  F1 and P5).
- `jsMapForEach` costs 91 ns (AOT) and 152 ns (wasm) in each frame with one chart. `Map.forEach`
  costs 6.4 ns and 7.3 ns (Evidence, F6).
- [performance.md](../performance.md) §10.1 "Animations" has these figures and the figures of the
  port. The rows `adapt-animation-number-path`, `adapt-animation-color-cache` and
  `adapt-animation-spec` name that section. Phase 5 adds the case `CALL=animate` to the stress
  mode `chart` of the gallery ([performance.md](../performance.md) §6 and §10.4). It loops an
  animation of `x` and `y` of each point. The key `animatorMs` gives the time of the animator tick
  without its draw. The performance step of phase 5 records the frame figures of this case on the
  Pixel 8a, macOS, Chrome with dart2wasm and the iPhone.

### 12. Tests

**Specs.**
- `test/specs/core.animation_test.dart` ports the 6 cases of `core.animation.tests.js`. It is a
  pure-layer spec with `package:test`. It calls `setUpSpecs()` first. It runs on the VM, with
  dart2js and with dart2wasm. It reads the real clock. Its dates are relative to `anim.start`. Thus
  its results do not depend on the clock. `Date.now()` in the spec is `jsDateNow()`.
- `test/specs/core.animations_test.dart` ports the 8 cases of `core.animations.tests.js`. It has
  `@TestOn('vm')` and uses `flutter_test`. Cases 1 to 5 are `test()` cases. They never start the
  animator. Cases 6 to 8 wait with `setTimeout` and `done` (`:64-174`). They are `testWidgets`
  cases with `waitForDone` ([Chart.js ADR 0022](0022-chart-test-harness.md) §2 and §7).
- `test/specs/core.animator_test.dart` ports the 2 cases of `core.animator.tests.js`. It has
  `@TestOn('vm')`.
  - `'should not fail when adding no items'` is a `test()` case. It passes in phase 5.
  - `'should fire onProgress for each draw'` skips with `'blocked: controller.bar'` until phase 7.
    Then it runs with `acquireChart` and `waitForDone` (Chart.js ADR 0022 §4 and §7).
- Thus phase 5 ports 16 cases. 15 cases pass and 1 case skips.
- The spec chart objects `{}` and `{draw() {}, options: {}}` become one port-only fake class of the
  test files. The fake implements `types.Chart` with `draw()` and `options`. Its other members
  throw.

**Fake time.**
- `jsDateNow()` reads `clock.now()`. Inside `testWidgets`, the fake clock moves only by the pumped
  durations.
- `tester.pump(d)` moves the clock by `d`. Then it runs one frame. The animator callback of that
  frame reads the new time.
- One pump gives one animator frame. A finished item leaves `items` one frame after its last tick
  (`core.animator.js:72-85`). Thus `running(chart)` stays true for one frame after the end.
- `setTimeout(fn, ms)` in a spec keeps its text. It is a harness task of
  [Chart.js ADR 0022](0022-chart-test-harness.md) §7. The pumps of `waitForDone` move the fake time
  in frames of 16 ms. The task runs at the first pump boundary at or after `ms`.
- One `tester.pump(const Duration(milliseconds: 300))` is not a port of `setTimeout`. After it,
  `running(chart)` is still true. One more `tester.pump()` makes it false (Evidence, F7 and P9).
- `done` is the callback of `waitForDone` (Chart.js ADR 0022 §7). Its limit is `specTimeout`, 5000
  ms of fake time.
- `pumpAndSettle` stops one frame after the end of the last animation. It returned after 26 pumps
  for a 400 ms animation (Evidence, S3). An animation with `loop: true` never ends. Its test pumps
  a fixed count of frames.
- A test removes its fake charts from the animator. Else it lets the loop end. At teardown,
  flutter_test runs two frames. A longer chain of frame callbacks fails the test
  ([Chart.js ADR 0016](0016-frame-scheduling.md)). The harness releases each chart of
  `acquireChart` when the body unmounts. `destroy()` then removes the chart from the animator
  (Chart.js ADR 0022 §8).
- A test does not start an animation in `setUp`, because `setUp` runs outside the `FakeAsync` zone.
  A plain `test()` case does not start the animator. Its frame callback then runs in the next
  `testWidgets` case ([Chart.js ADR 0016](0016-frame-scheduling.md)).

**Port-only tests.**
- `test/port/core/core.animation_test.dart` (pure, VM, dart2js and dart2wasm):
  - Group `adapt-animation-number-path`: a randomized equivalence test in the form of probe P3. It
    compares the number path with the generic path. The targets are a plain Map, `PointOptions` and
    the four element classes: `PointElement`, `LineElement`, `BarElement` and `ArcElement`. The
    values are doubles, `undefined`, JS `null`, NaN, -0, the infinities, booleans and strings. The
    cfg values have loops, delays and easings. Spec writes of `from` and `to` and calls of `update`
    occur between the ticks. After each tick, the test compares the active state, the target value,
    its type and the thrown error type.
  - The same group: for each of the four element classes, the setter and the write by name of `x`
    and `y` store the same state. The values are 1.5, NaN, -0, 3 and the infinities.
  - Group `adapt-animation-color-cache`: the two color interpolators. The inputs are:
    - the 256 alpha bytes of a hex color and the `rgba()` alphas from 0 to 1
    - color names, invalid strings and `''`
    - `null`, `undefined`, a `CanvasGradient` and numbers

    Each pair of the color list runs in both directions, and so does each `rgba()` alpha. Each alpha
    byte runs from `'#336699xx'` to `'#FF0000'`. Every eighth byte also runs from `'#FF0000'` back
    to `'#336699xx'`. Each pair runs at 11 factors. A second test changes `from` and `to` between
    the calls.
  - Group `adapt-animation-spec`: the same animation writes for a plain Map cfg and for an
    `AnimationSpec`.
  - Other tests:
    - `from != to` with NaN and -0
    - a `typeof` key without an interpolator: a `TypeError` at the first interpolation
    - a user `fn` with one parameter: it gets `from` only
    - a `JsFunction` `fn`: it gets the animation as `this`
    - the number interpolator with `null`, `undefined` and booleans
- `test/port/core/core.animation_cancel_test.dart` (VM), group `Animation.cancel`. `cancel()`
  ticks at `Date.now()` before it stops (`core.animation.js:67-74`). The test checks the value of
  that tick and the order of the write and of the rejection. The expected values come from the x64
  reference engine, with a fake `Date.now`. The targets are a plain Map, `PointElement.x` and
  `BarElement.y`, on the number path and on the generic path. The file imports `package:clock`.
  `check:lib-imports` does not let a web test import it. Thus the file has `@TestOn('vm')`.
- `test/port/core/animation_spec_test.dart` (pure, VM, dart2js and dart2wasm), group
  `adapt-animation-spec`: the Map protocol of `AnimationSpec` against a plain Map.
- `test/port/core/core.animations_test.dart` (VM):
  - Group `active transition`: the 400 ms hover path at the level of `Animations`. The test
    resolves `transitions.active` from the real `defaults` through the phase 5 `Config` and
    resolver, as `_resolveAnimations` does. A `PointElement` with shared options gets hover options.
    Then the test starts the animator and pumps frames of 16 ms. It asserts these results:
    - At each frame, the radius equals `3 + (4 - 3) * easeOutQuart(elapsed / 400)`.
    - At 200 ms, the background color is the mix at `easeOutQuart(0.5)`, 0.9375. At 400 ms, it is
      the hover color.
    - Frame 25 (400 ms) ends the animations. The `progress` listener runs 25 times.
    - Frame 26 removes the items. The `complete` listener gets `currentStep` 400.
    - After the un-hover and 400 ms more, `identical(point.options, shared)` is true.
  - The expected color strings come from the x64 reference engine
    ([Chart.js ADR 0010](0010-js-numeric-semantics.md)). The arm64 probes gave `'#3AA1E9F7'` and
    `'#36A2EB'` in Dart and in Node.js (Evidence, F7 and F8).
  - A `'themeFrame'` test: an `Animations` with the duration 0 writes the values at once and returns
    `null`. It gives an active animation a new target value. That animation keeps its end time.
- `test/port/core/core.animator_test.dart` (VM):
  - Group `platform-animation-promise-checkpoint`:
    - A frame callback after the animator callback, in the frame that ends an animation, sees the
      shared options.
    - A re-hover in that frame keeps the hover options.
    - An update inside the animator callback with no active animation (an empty `jsPromiseAll`)
      assigns the shared options at the checkpoint.
    - An update with the duration 0 in the `progress` listener of the frame that ends a `$shared`
      options chain keeps the options of that chain, as upstream.
    - `update()` outside a frame rejects in a microtask, after the synchronous code.
  - Group `jsMapForEach in _update`: `chart.destroy()` in `onComplete` throws nothing. A chart that
    starts in `onComplete` gets its ticks in the same frame.
  - `stop()` inside a `progress` listener: the frame counts the old list, as upstream does.
  - One `pump(300 ms)` leaves `running(chart)` true. One more `pump()` makes it false.
  - The tests of [Chart.js ADR 0016](0016-frame-scheduling.md) decision 11 for
    `platform-animator-mute` and `platform-animator-skip-muted`.
  - `listen` with an unknown event name throws.
- `test/port/js/`:
  - `jsTypeof`, also for a class value
  - `jsOwnPropertyNames` on a resolver and on a Map
  - `jsMapForEach`: additions, deletions and the documented case of a second add
  - `jsDateNow` under `withClock` and under `testWidgets`
  - the job order of `js_promise.dart`: nested checkpoints, a throw in the callback, an empty
    `jsPromiseAll`, an eager rejection, and the continuation of a list with items one job after
    its last item
- Phase 7 adds a hover test at the chart level. A bar chart with animations gets a `mousemove`
  through the harness. The test examines the colors at 0, 200 and 400 ms. It also examines the
  identity of the shared options after `mouseout`.

**Rows of `differences.md`.** This decision adds four rows:

| ID | Dart file and symbol | Upstream | Category | Pinning test |
|---|---|---|---|---|
| `adapt-animation-number-path` | `lib/src/core/core.animation.dart` `tick`, `_tickNumber`, `_retarget` and its calls in the constructor, `update` and the setters of `from` and `to` | `src/core/core.animation.js`@v4.5.1:28-45, 51-65, 76-103 | adapt | `test/port/core/core.animation_test.dart`, group `adapt-animation-number-path` |
| `adapt-animation-color-cache` | `lib/src/core/core.animation.dart` `_ColorInterpolator`, the `Animation` constructor | `src/core/core.animation.js`@v4.5.1:15-21, 35 | adapt | `test/port/core/core.animation_test.dart`, group `adapt-animation-color-cache` |
| `adapt-animation-spec` | `lib/src/core/animation_spec.dart` `AnimationSpec`, `lib/src/core/core.animations.dart` `configure` | `src/core/core.animations.js`@v4.5.1:26-29 | adapt | `test/port/core/animation_spec_test.dart` and `test/port/core/core.animation_test.dart`, group `adapt-animation-spec` |
| `platform-animation-promise-checkpoint` | `lib/src/core/core.animation.dart` `wait` and `_notify`, `lib/src/core/core.animator.dart` `_refresh`, `lib/src/js/js_promise.dart` | `src/core/core.animation.js`@v4.5.1:105-118, `src/core/core.animator.js`@v4.5.1:44-51 | platform | `test/port/core/core.animator_test.dart`, group `platform-animation-promise-checkpoint` |

- Two rows of other ADRs mark hunks in these files:
  - `platform-animator-mute` and `platform-animator-skip-muted` mark the two mute hunks of
    `core.animator.dart` (`core.animator.js:57-107`). [Chart.js ADR 0016](0016-frame-scheduling.md)
    decisions 7 and 11 own these rows and their tests.
  - `adapt-typed-element-options` marks the copy in `_resolveTargetOptions`
    (`core.animations.js:159`). [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) §6 and
    §7 own this row and its tests.
- The reasons of the three `adapt` rows of this decision name the figures of section 11 in
  [performance.md](../performance.md).
- The reason of `platform-animation-promise-checkpoint` names the re-hover case of section 7. It
  also names the difference that stays for the jobs of a throttled callback.
- The phase 5 change edits the row `platform-request-anim-frame` (section 7).

## Alternatives considered

The scores follow the order of [porting-flow.md](../porting-flow.md) §1.1: (1) upstream behavior,
(2) performance, (3) upstream structure, (4) less code.

**The three drafts.** A design panel wrote three drafts. A judge scored them from 0 to 10 for each
criterion:

| Draft | Behavior | Performance | Structure | Less code |
|---|---|---|---|---|
| fidelity (chosen) | 9 | 6 | 8 | 5 |
| performance | 6 | 9 | 4 | 3 |
| simplicity | 5 | 7 | 7 | 8 |

- Behavior has the first priority. Only the fidelity draft keeps the resolved option on the element
  in one reachable case. The case is a re-hover in the frame that ends an un-hover (section 7). The
  other two drafts accept the difference of `platform-request-anim-frame`. They miss this effect.
- The fidelity draft also keeps the semantics of `Map.prototype.forEach` at a negligible cost. It
  counts the specs correctly and skips the bar chart case correctly.
- Its weakness was performance. This decision takes three parts of the other drafts, because they
  keep the behavior equal. The parts are the resolved `_fn` (simplicity and performance), the
  conditional number path (performance, without the slots) and the typed cfg (performance).
- The performance draft: (1) it missed the re-hover case. It said that the next frame draws the
  shared options in both orders. (3) Its slots touch four element classes and four option classes.
  Its inline mix copies `@kurkle/color` arithmetic into a file with a Chart.js header. It also
  changed `jsGet` for elements. That change is outside this topic.
- The simplicity draft: (1) it missed the re-hover case. Its copy of the chart keys drops the visit
  of a chart that a listener adds (alternative 23). Its plan ran the bar chart case and the
  chart-level hover test in phase 5. `controller.bar` is a phase 7 module.

**Target access and the tick.**
1. **A `jsCall` call for each `_fn` in each tick** (form U). (1) Equal. (2) The slowest form:
   1892-1937 µs (AOT) and 2846-2888 µs (wasm) at 20000 x 2. Rejected for performance.
2. **A type test of `_fn` in each tick** (form F, the fidelity draft). (1) Equal. (2) F2 takes
   0.06 to 0.13 ms (AOT) and 0.29 to 0.38 ms (wasm) off each frame at 20000 x 2. Rejected for
   performance.
3. **A write closure resolved one time for each animation** (form S, and `A3r` of probe F1). (1)
   Equal. (2) No gain over the decided form. At 20000 x 2, S gives 738-823 µs against N 738-784 µs
   (AOT), and 895-1007 µs against 616-670 µs (wasm). At 1000 arcs x 6, S gives 146-153 µs against
   120 µs (AOT), and 190-201 µs against 139-145 µs (wasm). In probe F1, `A3r` gave 1104-1125 µs
   against 971 µs for the direct call with the `x` and `y` fast path (AOT). (3) One closure for
   each animation. Rejected: no measured gain.
4. **`NumberSlots` for each numeric property** (form P, the performance draft). (1) Equal: 0
   differences in the 60000 cases of probe P3. (2) Against N at 20000 x 2, the AOT ranges
   overlap. On wasm, P saves 0.03 to 0.10 ms in each frame. At 1000 arcs x 6, P saves 0.02 to
   0.03 ms (AOT) and 0.06 to 0.07 ms (wasm) (section 11). (3) New members in four element
   classes and four option classes. They extend [Chart.js ADR 0017](0017-element-properties.md)
   and [Chart.js ADR 0018](0018-typed-element-options.md). The gain is at most 0.1 ms in each
   frame in the measured scenarios. [porting-flow.md](../porting-flow.md) §1.1 states no
   threshold. [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13 applies §1.1 with a
   threshold. A form that changes the upstream structure needs a gain of 0.1 ms or more in the
   frame figures. Under that rule, this gain does not count. Not chosen (Open).
5. **A typed number animation without the `undefined` state** (`A4` of probe F1). (2) Up to 45 %
   faster than the direct call with the `x` and `y` fast path (probe F1, run 3). (1) An animation
   to `undefined` then stores NaN, where upstream restores the `undefined` state. `getProps` and
   `valueOrDefault(circumference, ...)` (`element.arc.ts:364`) then read NaN. Rejected for
   behavior. The decided number path applies only to two `double` values. Thus it keeps the
   `undefined` state.
6. **An `x` and `y` fast path in `writeProperty` for the generic path** (the fidelity draft). (1)
   Equal. (2) With the number path, the generic path writes `x` or `y` only in two cases. One
   value is not a `double`, or a user `fn` exists. No measured scenario has such writes. Rejected:
   no measured gain, more code.
7. **Typed reads at the start** (slots or typed getters for the reads). (1) A typed getter gives
   NaN for `undefined`. A new element then animates from NaN
   ([Chart.js ADR 0017](0017-element-properties.md), Alternatives). The reads run one time for
   each animation. Rejected.

**Interpolators and the cfg.**

8. **The color interpolator line by line.** (1) Equal. (2) 3.7 to 4.4 times slower on AOT and 4.7
   to 6.9 times slower on wasm for each color tick (Evidence, F1). Theme switches, `show` and
   `hide` animate the colors of each element with options that are not shared, for example bars
   with a color list. Rejected for performance.
9. **A global memo of parsed color strings** (in `helpers.color` or `@kurkle/color`). (1) Equal.
   (2) 391 ns against 1202 ns on AOT. No gain on wasm: 1264 ns against 1231 ns, because a String
   hash costs more there (Evidence, F3). A chart with more distinct colors than the memo holds gets
   no hit. (3) It changes a ported file. Rejected.
10. **An inline mix** (the arithmetic of `Color.mix` on cached `RGBA` copies, the performance
    draft). (1) Equal: 0 differences in 1,572,704 cases (Evidence, P4). (2) At 1000 x 2 colors on
    AOT, 660-752 µs against 754-944 µs for `Color.mix` on the parsed colors. In Node.js with wasm,
    515-568 µs against 534-578 µs: within the spread. The one Chrome figure (572 µs against
    678 µs) is one run of a polymorphic program (Evidence, P2). (3) It copies `@kurkle/color` code
    into a file with a Chart.js header. AGENTS.md rule 2 and its Licensing section then need a
    second source header and a review at each bump of `@kurkle/color`. Rejected: no gain outside
    the spread on the web. A form with no measured gain keeps the upstream structure
    ([porting-flow.md](../porting-flow.md) §1.1).
11. **The exact JS `+` in the number interpolator** (a String result for a String or an object
    operand, the performance draft). (1) The only case inside the type contract is display-only
    (section 5). A String result also reaches a number property of an element, where the write by
    name throws ([Chart.js ADR 0017](0017-element-properties.md) §5). (4) More code. Rejected
    ([Chart.js ADR 0009](0009-no-display-only-js-exactness.md)).
12. **A row `adapt-animation-lookup-proto` for the `Object.prototype` names of `type` and
    `easing`** (the performance draft). The rows `adapt-kurkle-names-proto` and
    `adapt-measure-text-proto` cover inputs inside the type contract. These names are outside it
    (section 5). Rejected: [Chart.js ADR 0017](0017-element-properties.md) §5 gives the rule.
13. **A plain Map cfg**, as upstream (`{}` at `core.animations.js:26`). (1) Equal. (2) The typed
    cfg takes 37 to 59 % less time for each constructor (Evidence, F5 and P5). Rejected for
    performance.
14. **One clock read for each `_createAnimations` call** (`adapt-animation-start-date`, the
    performance draft). (1) The start moves by less than 1 ms in real time. This is display-only
    ([Chart.js ADR 0009](0009-no-display-only-js-exactness.md)). Fake time gives no difference. (2)
    23 to 55 ns less for each constructor (Evidence, F5 and P5). (3) It changes the constructor
    signature. It also changes a call site that accepted
    [Chart.js ADR 0010](0010-js-numeric-semantics.md) §6 lists (`core.animation.js:37`). An
    accepted ADR does not change. Not chosen (Open).

**Promises.**

15. **An async `Completer` with no checkpoint** (the performance and simplicity drafts). (3) No
    hunk. (1) A re-hover in the frame that ends an un-hover keeps the shared options. A browser
    keeps the hover options (Evidence, F7 and F8). This changes the resolved option. Rejected for
    behavior.
16. **A `Completer.sync()` that completes inside `tick`.** (1) The swap of the options then runs
    before `chart.draw()` of the last frame. That frame draws the shared options, not the animated
    copy. The two differ when `cfg.to` sets the end value, for example `to: 'transparent'` of
    `hide` (`core.animations.defaults.js:62`). A user continuation of `wait()` also runs inside the
    animator loop (Evidence, P10). Rejected for behavior.
17. **The checkpoint in `requestAnimFrame`.** (1) More exact: the jobs of a throttled event callback
    then settle at the end of that callback too. (3) No hunk in `core.animator.dart`. It changes
    decision 1 of [Chart.js ADR 0016](0016-frame-scheduling.md). That decision owns
    `requestAnimFrame`. This ADR does not change it. Not chosen now (Open). The API of
    `js_promise.dart` lets a later decision move the call into `requestAnimFrame`. Then the hunk in
    `_refresh` goes away.
18. **`Future.wait([])` for an empty list** (the fidelity draft). (1) The empty list then completes
    in a Dart microtask, after all frame callbacks (Evidence, J2). The judge found this gap.
    Rejected for behavior: `jsPromiseAll` routes it through the job queue.
19. **A microtask hop in each `throttled` callback.** (1) Correct only for a chain of one microtask.
    [Chart.js ADR 0016](0016-frame-scheduling.md) owns `throttled`. Rejected.
20. **A port-only promise type for `wait()`.** (1) Equal. (4) More code. `wait()` then returns no
    `Future`. Rejected.
21. **`Future.wait` without `eagerError`.** (1) Equal, because the rejection handler does nothing.
    `eagerError: true` gives the order of `Promise.all` with the same code. Not chosen.

**Animator.**

22. **`Map.forEach` for `_charts`.** (1) It throws a `ConcurrentModificationError` when a listener
    destroys or starts a chart (Evidence, F7 and S1). Upstream continues. The exception also leaves
    `_request` set (`core.animator.js:44-46`). Thus `_refresh` returns at once for all later calls.
    Every chart then stops its animations (Evidence, S3). Rejected for behavior: a throw.
23. **One copy of the keys before the walk** (`js-semantics-animator-chart-loop`, the simplicity
    draft). (1) A chart that starts inside the last `onComplete` gets no visit. `remaining` is then
    0. Thus the loop stops. That chart does not animate until the next start. (2) `jsMapForEach`
    costs 0.09 µs (AOT) and 0.15 µs (wasm) in each frame with one chart. (3) A `DIVERGES` hunk.
    Rejected for behavior.
24. **A `Ticker` or an `AnimationController`.** [Chart.js ADR 0016](0016-frame-scheduling.md)
    rejects both.
25. **`AnimationEvent` as a Map.** [Chart.js ADR 0006](0006-options-representation-and-resolver.md)
    makes a JS plain object a Map in the option scopes. The event reaches user callbacks only.
    [Chart.js ADR 0003](0003-type-only-dependencies.md) makes a declared interface a Dart
    interface. [Chart.js ADR 0017](0017-element-properties.md) §9 makes the literal `{x, y}` a
    class. Rejected.

**Reduced motion.**

26. **A flag for each chart in the animator, read in `_createAnimations`** (`cfg = null`, the
    performance draft). (1) The resolved options do not change. `onComplete` and `onProgress`
    still run. Theme removal under reduced motion stops its animation. (3) A hunk in
    `core.animations.dart` and two port-only methods of the animator, before the widget API
    exists. Not chosen now. It is
    a phase 9 candidate (Open).
27. **`animation: false` from the widget.** It changes the resolved option `animation`. It also
    silences the user `onComplete` and `onProgress`: `render()` then calls `onAnimationsComplete`
    (`core.controller.js:692-694`). That function reads `animationOptions && ...`
    (`core.controller.js:33-45`). It is a phase 9 candidate (Open).
28. **A global flag that sets each duration to 0, or a `MediaQuery` read in the chart host.** A
    global flag acts on every chart, also in the specs. A change of the preference needs
    `chart.update()`. The host does not own the updates. Rejected.
29. **A mute under `disableAnimations`, or the end of all animations in the animator.** A mute
    stops the elements between their start and end values. `chart.stop()` also leaves the values at
    an intermediate point (`core.animation.js:67-74`). Rejected.

## Consequences

- The three files keep the upstream names, order and line structure. This decision gives them
  these `DIVERGES` hunks: the number path, the color cache, `AnimationSpec` at
  `core.animations.js:26` and the two hunks of the checkpoint. They also get the two hunks of
  [Chart.js ADR 0016](0016-frame-scheduling.md) for the mute. They also get the hunk of
  [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) for the typed copy of
  `resolveTargetOptions`.
- A promise chain that the animator callback starts finishes inside that callback. Other microtasks
  still run after all frame callbacks of a frame. Thus the jobs of a throttled event callback still
  run after the later frame callbacks of the same frame (Open).
- Inside one checkpoint, the continuation of a `wait()` future runs in the job that settles that
  future. `jsPromiseAll` settles its result one job after its last item, as `Promise.all` does.
  Thus the `then` of `awaitAll` runs in a later job, as in JavaScript. `_animateOptions` reads that
  order (`core.animations.js:55-59`). An example is an update with an empty `awaitAll` in the
  `progress` listener of the frame that ends a `$shared` options chain. The target keeps the
  options of the earlier chain, as upstream.
- `Animation.wait()` returns a `Future<void>`. It completes at the checkpoint or in a microtask,
  never inside the call that settles it.
- A user `wait()` without an error handler gives an uncaught async error when the animation is
  updated or cancelled. flutter_test fails such a test. JavaScript only logs an unhandled
  rejection.
- An exception in `_update` leaves `_request` set, as upstream does. The animator then registers no
  more frames. The jobs of the checkpoint still run.
- `Element` implements `types.PropertyAccess`. The dataset meta of phase 5 follows section 9.
- `types.Chart` gets `draw()`. Test fakes of `types.Chart` implement it.
- `Element.x` and `Element.y` have a contract: for a `double`, their setter and their write by name
  store the same state. A later element class that changes one of them changes both. The test of
  the row `adapt-animation-number-path` examines each element class.
- Each `Animation` keeps two more `double` fields, a `bool` and an `int`. Each color animation keeps
  two parsed colors.
- `Object.freeze` of a cached `Animations` (`core.datasetController.js:858`,
  `plugin.tooltip.js:519`) is `jsObjectFreeze` of Chart.js ADR 0021 §5. `Animations` does not
  implement `JsFreezable`. Thus the call changes nothing. No upstream code writes to an
  `Animations` after its constructor.
- A spec that waits with `setTimeout` pumps frames of 16 ms through `waitForDone`. A port with one
  long pump fails.
- The `core.animation` spec runs on the web legs. The other two specs run on the VM only.
- The phase 5 change updates `parity.md` for the three files and the three specs. It updates
  `performance.md` (section 11) and `differences.md` (section 12).
- Reduced motion stays open until phase 9. Until then, theme removal under reduced motion animates
  for 1000 ms ([theming.md](../theming.md) §11).
- Phase 5 adds `clock: ^1.1.2` ([Chart.js ADR 0010](0010-js-numeric-semantics.md) §6).

## Open

- **`NumberSlots`** (alternative 4). The gain is at most 0.1 ms in each frame in the measured
  scenarios (section 11). The cost is new members in eight classes. These members extend Chart.js
  ADRs 0017 and 0018. [porting-flow.md](../porting-flow.md) §1.1 states no threshold. The
  threshold of [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13 rejects this gain.
  The maintainer decides that rule of §1.1. The decided `_xy` field can become a slot later
  with no change to the number path.
- **One clock read for each `_createAnimations` call** (alternative 14). It saves 23 to 55 ns for
  each constructor, about 0.9 to 2.2 ms for an update of 40000 animations. The difference is
  display-only. The maintainer decides whether an `adapt` row is enough, or whether the change
  needs an ADR that supersedes [Chart.js ADR 0010](0010-js-numeric-semantics.md) §6.
- **Reduced motion** (phase 9). The widget maps `MediaQuery.maybeDisableAnimationsOf` to a policy.
  The candidates:
  - `animation: false` in a port-only scope of the widget while the preference is on. It silences
    the user `onComplete` and `onProgress` (alternative 27).
  - A flag for each chart, read one time in `_createAnimations` (`cfg = null`). It keeps the user
    callbacks. It also stops the animation of a theme removal (alternative 26).
  - `'themeFrame'` for theme switches only. Theme removal then needs a mode with the duration 0
    without the theme scope.
- **The checkpoint in `requestAnimFrame`** (alternative 17). It closes the difference that stays
  for the jobs of a throttled event callback. An example is a frame with two event types for one
  element and an `'active'` transition with the duration 0. A successor of
  [Chart.js ADR 0016](0016-frame-scheduling.md) can move the call.
- **The six fixtures that drive the animator** through `_getAnims`, `_refresh` and `_update`
  (phase 7, tool 7). Their hand ports either read `getAnims` and `update` as `@internal` members,
  with a test switch for `_refresh`, or drive the frames with pumps.
- **The cost of `jsObjectKeys(values)` in `_createAnimations`.** It makes a list for each call. A
  data update of 20000 points makes 20000 calls. No probe measured it.
- **Device figures** on the Pixel 8a, the iPhone, macOS and Chrome, from the case `CALL=animate`
  of the gallery (section 11). The performance step of phase 5 measures them.
  [performance.md](../performance.md) §7 lists them as not recorded yet.

## Evidence

The probes ran on 2026-10-19 on an Apple M3 Max with macOS 26.5.1. AOT is `dart compile exe` with
Dart 3.12.2 (Flutter 3.44.9). wasm is `dart compile wasm -O2`, run in Node.js v24.12.0 (arm64). The
Node.js runs give time figures and behavior only, no reference values
([Chart.js ADR 0010](0010-js-numeric-semantics.md)). The probes are in the scratchpad folder
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/42473ad1-0196-429c-8b17-c32d881d14b9/scratchpad/design/animation/`
(below: `animation/`). The benchmarks import the real pure layers of `packages/flutter_chartjs_port`.

**Judge probes** (`animation/judge/`).
- **J1. Write forms, monomorphic** (`bench_write.dart`, executables `bw_<V>.exe`, modules
  `wasm/bw_<V>.mjs`, outputs `aot_write_forms.txt`, `aot_write_forms2.txt`, `wasm_write_forms.txt`
  and `wasm_write_forms2.txt`). One variant for each executable (`-DV=U|F|F2|S|N|P`). The duration
  is 1e12 ms. Thus all items stay active. Each figure is the median of 9 runs of 40 frames (points)
  or 200 frames (arcs), after 50 warm-up frames. The table of section 11 gives the lowest and the
  highest of 3 to 6 such figures for each variant. All variants wrote the same last values.
- **J2. The checkpoint gap** (`checkpoint_gap.dart`). It printed
  `[then (a), event callback, then (b), after frame]`. Case (a) is a sync completer that a queued
  job settles inside the checkpoint. Case (b) is `Future.wait([])` inside the checkpoint. Thus the
  empty list settles after the next frame callback.
- **J3. The fix of the gap** (`animation/final/promise_all_probe.dart`, output
  `promise_all_probe.txt`). It printed `[then (a), then (c) rejected undefined, then (b), nested
  job, event callback, sync after (d), then (d) outside, after frame, job after throw, caught]`.
  `jsPromiseAll` settles the empty list (b) and the eager rejection (c) at the checkpoint. A nested
  checkpoint runs its job inside the outer one. Outside a checkpoint, the empty list settles in a
  microtask after the synchronous code (d). The jobs run when the callback throws.

**Fidelity probes** (`animation/fidelity/`).
- **F1. Tick cost** (`bench/bench_tick.dart`, outputs `bench/aot_run1.txt` to `aot_run3.txt` and
  `bench/wasm_run1.txt` to `wasm_run3.txt`). One executable holds all variants. Thus the tick call
  site is polymorphic. J1 replaces its tick figures. Its color figures: 1000 x 2 color
  properties on a Map target took 3663-3885 µs (AOT) and 2920-3463 µs (wasm) line by line (`A1`,
  `A2`). With the cache (`A2c`), they took 875-977 µs and 500-619 µs. `A3r` (a writer for each
  animation) gave 1104-1125 µs (AOT) at 20000 x 2. `A4` (the typed bound) gave 795-912 µs (AOT).
  The first line of each output gives `identical(NaN, NaN): true`, on AOT and on wasm. `jsDateNow()`
  cost 33.4 to 46.4 ns (AOT) and 37.9 to 47.6 ns (wasm).
- **F2. Write cost** (`bench/bench_write.dart`, `bench/aot_write.txt`, `bench/wasm_write.txt`). 2
  million writes on 1000 objects, median of 7, two rounds. The figures are in section 11.
- **F3. Global color memo** (`bench/bench_color.dart`, `bench/aot_color.txt`,
  `bench/wasm_color.txt`). 0 differences in 707 cases. A parse costs 429 to 435 ns. AOT: 1202 ns
  line by line, 391 ns with the memo. wasm: 1231 ns and 1264 ns.
- **F4. Color cache equivalence** (`probes/color_cache_equivalence.dart`, output
  `probes/color_cache_equivalence.txt`). The cache against the line-by-line interpolator: 0
  differences in 40590 cases, throws included.
- **F5. Constructor cost** (`bench/bench_create.dart`, `bench/aot_create.txt`,
  `bench/wasm_create.txt`). 40000 constructors on 20000 `PointElement` objects. `K0` (Map cfg, a
  clock read in each constructor): 168 ns (AOT), 229 ns (wasm). `K1` (one clock read): 145 ns,
  206 ns. `K2` (typed cfg): 105 ns, 141 ns.
- **F6. `jsMapForEach` cost** (`bench/bench_mapforeach.dart`, `bench/aot_mapforeach.txt`,
  `bench/wasm_mapforeach.txt`). One chart: 90.6 ns against 6.4 ns for `Map.forEach` (AOT), 152.3 ns
  against 7.3 ns (wasm). Ten charts: 582.1 ns against 29.7 ns, 1023.9 ns against 31.3 ns.
- **F7. Flutter probe** (`probes/animation_probe_test.dart` and
  `probes/animation_probe_checkpoint_test.dart`, prototypes in `proto/`, outputs
  `probes/animation_probe_test.txt` and `probes/animation_probe_checkpoint_test.txt`).
  `flutter test` from `packages/flutter_chartjs_port`. Results:
  - The 15 ports of the non-chart spec cases pass, with and without the checkpoint, with frames of
    16 ms.
  - With one pump of 300 ms, `'should assign shared options to target after animations complete'`
    fails: `running(chart)` is still true. This is the intended failure in the outputs.
  - The probe adds a frame callback after the animator callback. It logs the frame that ends a
    200 ms option animation. Without the checkpoint, the log is `[draw clone, draw clone, event
    clone, after frame shared]`. With the checkpoint, it is `[draw clone, draw clone, event shared,
    after frame shared]`.
  - A re-hover in the frame that ends a 400 ms un-hover: without the checkpoint, the options are
    the shared object with `#0000FF`. With the checkpoint, they are a new copy with `#FF0000`.
  - The 400 ms hover at the level of `Animations`: `#3AA1E9F7` at 200 ms, `#36A2EB` at 400 ms, and
    the shared object again after the un-hover.
  - `jsMapForEach` in `_update`: a removal of another chart and a new chart in `onComplete` throw
    nothing. The new chart drew 8 frames and reached its target value.
  - A Dart `Map.forEach` throws a `ConcurrentModificationError` for a removal and for an addition.
  - `update()` and then the end of the animation settle one completer two times. The result is one
    rejection with `undefined` and no `StateError`.
  - From NaN to NaN: active at 50 ms, inactive at 100 ms.
  - A second `complete()` of a completed `Completer` throws a `StateError`
    (`probes/completer_probe.dart`, output `probes/completer_probe.txt`).
- **F8. Upstream probe** (`probes/upstream_probe.mjs`, output `probes/upstream_probe.txt`). It
  loads the pinned `core.animation.js`, `core.animations.js` and `core.animator.js` with a fake
  `requestAnimationFrame` and a fake `Date.now`. "browser" runs the microtasks after each frame
  callback. "flutter" runs them after all frame callbacks of a frame. Results:
  - order: browser `["draw clone","draw clone","event shared","after frame shared"]`, flutter
    `["draw clone","draw clone","event clone","after frame shared"]`
  - re-hover: browser, a copy with `#FF0000`. Flutter order, the shared object with `#0000FF`.
  - the 400 ms hover: `#3AA1E9F7` at 200 ms, `#36A2EB` at 400 ms, then the shared object
  - `Map.forEach` of the animator: no throw, the new chart drew 8 frames
  - `Promise.all` rejects at once with `undefined` while the second animation is still active
  - the number interpolator from `'2'` to `3` at 0.5 gives `"20.5"`
  - a String start value without `type` throws `TypeError: this._fn is not a function`

**Performance probes** (`animation/performance/`).
- **P3. Equal writes** (`probe/bin/equiv.dart`). 60000 random cases, each with up to 12 ticks. The
  targets were a `PointElement`, `PointOptions` and a plain Map. The values were doubles, NaN, -0,
  the infinities, `undefined`, JS `null`, booleans, valid and invalid colors, `''` and `'5'`. The
  cfg had random types, loops, delays, easings and `from` and `to` values. Writes of `from` and `to`
  in the form of the specs occurred between the ticks. After each tick, the probe compared the
  active state, the target value, its type and the thrown error types of the forms A to G. Result:
  0 differences on the VM, with dart2js and with dart2wasm. 11399 cases started on the number path.
- **P4. Mix grid** (`probe/bin/mix_grid.dart`). 784 color pairs and 2006 factors: 1,572,704 cases,
  0 differences on the VM, with dart2js and with dart2wasm.
- **P5. Constructor cost** (`probe/bin/bench_construct.dart`). 40000 constructors, median of 10.
  Map cfg: 210-219 ns (AOT), 275-289 ns (wasm). Typed cfg: 89-93 ns, 132-140 ns. Typed cfg with one
  date for each call: 71-84 ns, 79-94 ns. `jsDateNow()` costs 44-47 ns (AOT) and 49-55 ns (wasm).
- **P8. `Map.forEach` with a change in the loop** (`probe/bin/map_foreach.dart`, `map_foreach.js`).
  In Dart, a removal and an addition inside `forEach` both threw a `ConcurrentModificationError`. In
  Node.js, a delete of `c` at `a` visited `a,b`. An add of `d` at `a` visited `a,b,c,d`.
- **P9. Flutter prototype** (`fprobe/lib/anim_proto.dart`, `fprobe/test/anim_proto_test.dart`).
  `flutter test` passed 22 tests:
  - One pump of 300 ms gave one draw. After it, `running(chart)` was still true. One more `pump()`
    gave `running(chart)` false.
  - The frame callbacks read the fake clock: `t0 + 16` and `t0 + 32`.
  - The 400 ms hover transition took 26 frames of 16 ms. At each frame, the radius was the
    `easeOutQuart` value. The hover options arrived after frame 25. `complete` had `currentStep`
    400. `progress` ran 25 times.
- **P10. The order of `Completer` listeners** (`probe/bin/completer_order.dart`). With
  `Completer()`, the listener of `Future.wait(...).then` ran in a microtask. With
  `Completer.sync()`, it ran inside `complete()`.
- **P2. The color path of this draft** (`probe/bin/bench_tick.dart`, outputs
  `probe/out/aot_tick*.txt`, `probe/out/aot_final.txt` and `probe/out/wasm_final.txt`). The probe
  compares the inline mix with `Color.mix` on the parsed colors at 1000 x 2 colors. On AOT, it
  gave 660-752 µs against 754-944 µs. In Node.js with wasm, it gave 515-568 µs against
  534-578 µs. Chrome with dart2wasm gave 572 µs against 678 µs in one run of a polymorphic test
  program (`probe/test/tick_E_test.dart`, `tick_F_test.dart`).

**Simplicity probes** (`animation/simplicity/`).
- **S1. Dart semantics** (`probe_pkg/bin/semantics_probe.dart`). `LinkedHashMap.forEach` threw a
  `ConcurrentModificationError` for a delete and for an insert. `Future.wait` handled the errors of
  all its futures. `Future.wait([])` completed in a microtask. An error without a listener reached
  the zone handler. `!=` gave true for NaN and NaN and false for 0 and -0.
- **S2. Upstream in Node.js** (`probe_js/upstream_probe.mjs`). The number interpolator gave
  `'[object Object]NaN'` for an object operand. `Map.forEach` skipped a deleted chart and visited an
  added chart: the draws were `B,D`.
- **S3. Spec ports on a draft port** (`probe_pkg/test/core_animation_test.dart`,
  `probe_pkg/test/core_animations_test.dart`). `pumpAndSettle` with a step of 16 ms returned after
  26 pumps for a 400 ms animation. Chart A destroyed itself in `onComplete`. With `Map.forEach`,
  the frame threw a `ConcurrentModificationError`. `_request` stayed set. Chart B drew once in
  20 frames and never ended.
- **S7. Pinning tests of a draft** (`probe_pkg/test/pinning_test.dart`). The cached color
  interpolator equaled the upstream form in 9801 cases. The setter write equaled the write by name
  for `x` and `y` of `PointElement`, `BarElement`, `ArcElement` and `LineElement`, for 1.5, NaN, -0,
  3 and `undefined`.

**Sources read** (v4.5.1, `third_party/Chart.js`): `src/core/core.animation.js:1-119`,
`src/core/core.animations.js:1-162`, `src/core/core.animator.js:1-214`,
`src/core/core.animations.defaults.js:1-72`, `src/core/core.datasetController.js:836-960`,
`src/core/core.controller.js:28-48`, `:180-192`, `:255-300`, `:680-710`, `:740-748` and
`:885-940`, `src/core/core.config.js:225-245`, `src/core/index.ts:1-10`,
`src/helpers/helpers.config.ts:60-100`, `src/helpers/helpers.options.ts:43-66` and `:154-180`,
`src/helpers/helpers.extras.ts:10-25`, `src/elements/element.bar.js:36-72`,
`src/plugins/plugin.tooltip.js:516-519`, `src/types/animation.d.ts:1-34`,
`src/types/index.d.ts:525-535`, `:1705-1780` and `:2132`, the three spec files, chartjs-test-utils
`src/utils.js:36-62` (v0.4.0) and the six fixtures of the Context. Flutter 3.44.9:
`widgets/media_query.dart:1961` and `animation/animation_controller.dart:651`.
