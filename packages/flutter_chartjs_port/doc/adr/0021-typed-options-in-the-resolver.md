# Chart.js ADR 0021: Typed options in the resolver

- Status: accepted (2026-10-21)
- Date: 2026-10-19
- Related: [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (options and the
  `undefined` sentinel), [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) (the protected
  behavior), [Chart.js ADR 0012](0012-dart-file-naming.md) (names),
  [Chart.js ADR 0017](0017-element-properties.md) (element properties),
  [Chart.js ADR 0018](0018-typed-element-options.md) (typed element options: this ADR decides its
  two Open items and the phase 5 part of its section 5), [Chart.js ADR 0019](0019-animation.md)
  (animation), [Chart.js ADR 0020](0020-registry-and-component-classes.md) (registry and component
  classes), [Chart.js ADR 0022](0022-chart-test-harness.md) (chart test harness),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule) and §4,
  [performance.md](../performance.md) §6 and §8

## Context

[Chart.js ADR 0018](0018-typed-element-options.md) declares the typed classes `PointOptions`,
`LineOptions`, `BarOptions` and `ArcOptions` in `lib/src/elements/element_options.dart`. Each typed
class is a `Map<String, Object?>` with one field for each known key. An element reads a known key
of a typed class through a getter, with no Map lookup. In phase 4, only the gallery demos make
typed classes. The stress demo measured the gain at 20000 points
([performance.md](../performance.md) §8.4). The draw time was 20 % lower on the Pixel 8a and 21 %
lower on macOS. It was 28 % lower on the iPhone and 30 % lower in Chrome.

In this ADR, an options object is a result of `resolveNamedOptions` for an element, or a copy of
such a result. Chart.js ADR 0018 leaves two items open for phase 5:
- The way in which `resolveNamedOptions` finds the typed class.
- `Object.freeze` of the cached options: a frozen state, or no freeze.

**The producer.**
- `resolveDatasetElementOptions` passes `this.datasetElementType.id` to `_resolveElementOptions`
  (`core.datasetController.js:789`). `resolveDataElementOptions` passes `this.dataElementType.id`
  and the data index (`:798`).
- `_resolveElementOptions(elementType, mode, index)` (`:804-835`) reads a cache with the key
  `elementType + '-' + mode` (`:806-808`). A cache hit returns `cloneIfNotShared(cached, sharing)`
  (`:810-812`). `sharing` is `this.enableOptionSharing && defined(index)` (`:809`).
- A cache miss passes the names `Object.keys(defaults.elements[elementType])` to
  `resolveNamedOptions` (`:817`, `:821`). This call is the only call of `resolveNamedOptions` in
  `src/`.
- `resolveNamedOptions` (`core.config.js:351-367`) makes the object `{$shared: true}` (`:352`). It
  writes `$shared = false` when an option needs the context (`:355-356`). Then it writes one key
  for each name, in the order of the names (`:363-365`).
- When `values.$shared` is true, `_resolveElementOptions` writes `values.$shared = sharing`
  (`core.datasetController.js:826`). Then it caches this frozen object:
  `Object.freeze(cloneIfNotShared(values, sharing))` (`:831`).
- `cloneIfNotShared` is `shared ? cached : Object.assign({}, cached)` (`:230`).

Thus each cache entry is frozen. With `sharing` true, a result with `$shared` true is the frozen
cache entry itself. With `sharing` false, each call returns an object that is not frozen (probe E1,
P2 and P3).

**The names.** `registerDefaults` merges three sources into `defaults.elements[id]`
(`core.typedRegistry.js:84-92`). The sources are the defaults of the parent class, the current
`defaults.get(scope)` and the `defaults` of the class (`:86-90`). Then `routeDefaults` adds the
keys of `defaultRoutes` (`:94-96`, `:103-113`). Thus the names of an element type are normally the
keys of its `defaults`, then the keys of its `defaultRoutes` (probe F1). A default that a program
writes before the registration comes first (probe E1, P6). A subclass with its own id gets the
names of its parent first (probe E1, P7).

**The copies.**
- `getSharedOptions` returns this copy (`core.datasetController.js:867-872`):
  `this._sharedOptions || (this._sharedOptions = Object.assign({}, options))`. The line, bar and
  doughnut controllers give this copy to each data element (`controller.line.js:111`,
  `controller.bar.js:418`, `controller.doughnut.js:285`). In a line chart, the points hold this
  copy, not the frozen cache entry (probe E1, P1).
- `resolveTargetOptions` copies shared options before an animation writes into them. The copy is
  `Object.assign({}, options, {$shared: false, $animations: {}})` (`core.animations.js:147-162`).
- `BubbleController.resolveDataElementOptions` copies the options before it writes `radius`. The
  copy is `Object.assign({}, values, {$shared: false})` (`controller.bubble.js:155-158`). The
  upstream comment at `:155` says: "In case values were cached (and thus frozen), we need to clone
  the values".

**The counts.** Probe S1 ran the pinned sources with 1000 data points for each built-in chart
type. It counted the calls of `resolveNamedOptions` and the option copies in one
`chart.update()`:

| Chart type | Calls of `resolveNamedOptions` | Option copies |
|---|---|---|
| `line` | 2 to 4 | 4 |
| `line`, scriptable `backgroundColor` | 1009 | 0 |
| `scatter` | 1 to 2 | 3004 |
| `bar` | 1 to 2 | 0 |
| `bubble` | 1 to 2 | 4004 |
| `doughnut` | 6001 | 0 |
| `pie` | 6001 | 0 |
| `polarArea` | 5000 | 0 |
| `radar` | 2 to 3 | 1004 |

Thus in seven of the nine rows, each update makes one resolution or one copy for each element.

**The frozen state.** An ES module runs in strict mode. In strict mode, a write into a frozen
object throws a `TypeError` (probe E1, P1). A write of the same value also throws. A `delete` of an
absent key does not throw. Three specs read the frozen state
(`core.datasetController.tests.js:956-1019`):
- The shared options of a line chart are frozen (`:975`).
- The options of a radar chart are not frozen (`:997`).
- Scriptable options are not frozen (`:1018`).

`Object.freeze` occurs at four sites of `src/`: `core.datasetController.js:831` and `:858`,
`core.layouts.js:395` and `plugin.tooltip.js:519`. Only `:831` freezes options objects.

The test fixtures of the port model `Object.freeze` with `Map.unmodifiable`
(`test/specs/helpers.config_test.dart:22`, and `test/port/helpers/helpers.config_test.dart`, group
`delete on a frozen scope`). A write into such a Map throws an `UnsupportedError`. `lib/` throws
`TypeError()` at 13 sites for a JavaScript `TypeError`.

**The cost.** [performance.md](../performance.md) §8.2 measured the Map lookups of the option reads
at 20000 points. They took about 18 % of the draw samples on macOS. They took 25.7 % of the main
thread with dart2wasm. In a chart, the elements get typed classes only under two conditions:
- `resolveNamedOptions` makes them.
- Each copy keeps the class.

## Decision

This ADR states the complete phase 5 decision for the typed classes. Chart.js ADR 0018 §5 gives
the typed class "when the names are the names of an element type". This ADR selects the class by
the element type id instead. The other decisions of Chart.js ADR 0018 stay valid.

### 1. The typed class of an element type

- `lib/src/elements/element_options.dart` gets a function that maps an element type id to a new,
  empty options object:

  ```dart
  /// The new, empty options object of the element type [elementType]
  /// (Chart.js ADR 0021).
  // DIVERGES(chartjs): adapt-typed-element-options, the class of the id.
  ElementOptions createElementOptions(Object? elementType) =>
      switch (elementType) {
        'point' => PointOptions(),
        'line' => LineOptions(),
        'bar' => BarOptions(),
        'arc' => ArcOptions(),
        _ => GenericElementOptions(),
      };
  ```

- The four strings are the `id` values of the four element classes (`element.point.ts:22`,
  `element.line.js:245`, `element.bar.js:143`, `element.arc.ts:302`). The element files import
  `element_options.dart`. Thus the table uses string literals. A test compares them with
  `PointElement.id`, `LineElement.id`, `BarElement.id` and `ArcElement.id`.
- The parameter is an `Object?`. The `id` read of
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §4 gives an `Object?`, because a
  class value can have an `id` that is not a string. `_resolveElementOptions` passes its
  `elementType` as it is. A value other than the four strings gives `GenericElementOptions`.
- `Config.resolveNamedOptions` in `lib/src/core/core.config.dart` gets an optional fifth parameter
  `into`:

  ```dart
  /// core.config.js:351 `resolveNamedOptions`.
  ///
  /// [into] is the empty object that receives the options. Dart `null`
  /// gives a new plain Map, as the object literal of upstream gives.
  AnyObject resolveNamedOptions(
    List<Object?> scopes,
    List<String> names,
    Object? context, [
    List<String> prefixes = const [''],
    AnyObject? into,
  ]) {
    assert(into == null || into.isEmpty, 'into must be empty');
    // DIVERGES(chartjs): adapt-typed-element-options, the caller gives result.
    final result = (into ?? <String, Object?>{})..[r'$shared'] = true;
    // core.config.js:353-366 as upstream.
  }
  ```

- `core.config.dart` does not import `element_options.dart`. In the same way, `core.config.js`
  imports no element module.
- `_resolveElementOptions` in `lib/src/core/core.datasetController.dart` passes
  `createElementOptions(elementType)` as `into` (`core.datasetController.js:821`). This hunk carries
  the same marker:

  ```dart
  // DIVERGES(chartjs): adapt-typed-element-options, a typed result object.
  final values = config.resolveNamedOptions(
    scopes, names, context, prefixes, createElementOptions(elementType));
  ```

- Thus each cache miss makes the class of its element type. The class follows the element type
  id, not the names.
- The names stay `Object.keys(defaults.elements[elementType])` (`:817`), as a call of
  `jsObjectKeys`. A name that is not a known key goes to the Map of extra keys (Chart.js ADR 0018
  §2). A known key that is not a name stays absent. Thus the entries are the upstream entries for
  each list of names.
- A user element class with the id `point` also gets `PointOptions`. Its other names go to the
  extra keys. Thus each read gives the upstream value.
- An element type id without a typed class gets `GenericElementOptions` (section 2). Examples are a
  custom element type and a subclass of a built-in element class with its own id (probe E1, P7).
  The draw code of such a subclass reads Map entries (Chart.js ADR 0018 §4). Open lists the two
  options for the subclass.
- A caller that passes no `into` gets a plain Map. Upstream has no other caller
  (`core.datasetController.js:821`). A plugin or user code can call the method.
- The class depends only on the `id` of the element class value. Chart.js ADR 0020 §3 puts the
  static `id` of [Chart.js ADR 0017](0017-element-properties.md) §2 into the class value. A
  subclass value without an own `id` reads the `id` of its superclass (Chart.js ADR 0020 §1). The
  class does not depend on the key order of `defaults.elements`. It does not depend on the time of
  the registration.
- The hunk at `core.config.js:352` is not one of the theme hunks H0-H3 of
  [Chart.js ADR 0001](0001-theming.md). These hunks add code before `:158` and change `:106-110`,
  `:312-313` and `:336-337` ([theming.md](../theming.md)).

### 2. `GenericElementOptions`

- `element_options.dart` gets a fifth final subclass of `ElementOptions`:

  ```dart
  /// The resolved options of an element type without a typed class
  /// (Chart.js ADR 0021).
  final class GenericElementOptions extends ElementOptions {
    /// Options with the entries of [source], in its key order.
    GenericElementOptions([super.source]);

    /// Each key, also `$shared` and `$animations`, in insertion order.
    final AnyObject _map = <String, Object?>{};

    @override
    GenericElementOptions clone() => ...;
  }
  ```

- It has no known keys. It keeps each key in one `LinkedHashMap`. Thus its key order is the
  JavaScript insertion order, also for `$shared` and `$animations`.
- It overrides the Map protocol of Chart.js ADR 0018 §3 with that Map: `operator []`,
  `operator []=`, `containsKey`, `remove`, `keys`, `length` and `clear`. It also overrides the
  getters `$sharedValue` and `$animationsValue`.
- It has the frozen state of section 5 and the `clone` method of section 3.
- Ten `jsGet` reads at a polymorphic site cost 82.4 to 82.5 ns on AOT. A plain Map costs 75.4 to
  75.7 ns (+9 %). On dart2wasm, the reads cost 149 to 152 ns against 129 to 138 ns (up to +15 %,
  probe J).
- Eleven writes and ten reads cost 378 to 389 ns on AOT. A plain Map costs 394 to 403 ns (probe
  E4, G8).

### 3. The copies

- `ElementOptions` gets the abstract method `ElementOptions clone()`. Each subclass implements it
  with a private copy constructor that copies each field. The copy gets a new Map of extra keys
  with the same entries in the same order. The copy is not frozen. The copy is shallow, as
  `Object.assign` is.
- `element_options.dart` gets the copy function:

  ```dart
  /// `Object.assign({}, options)` for an options object (Chart.js ADR 0021).
  ///
  /// An [ElementOptions] gives its [ElementOptions.clone]. Another Map
  /// gives a new plain Map with the keys of [jsObjectKeys], in that order.
  // DIVERGES(chartjs): adapt-typed-element-options, the copy keeps the class.
  AnyObject copyOptions(AnyObject options) => options is ElementOptions
      ? options.clone()
      : {for (final key in jsObjectKeys(options)) key: options[key]};
  ```

- The second branch is the ported form of `Object.assign` (`_assign` of
  `lib/src/core/core.defaults.dart`). It gives the upstream result for each Map, also for a
  resolver. `jsObjectKeys` of a resolver is `JsProxyObject.objectKeys()`.
- In a chart, each options object is an `ElementOptions` (section 1). Thus no chart path reaches the
  second branch. Plain options come only from the specs (`core.animations.tests.js:54-62`) and from
  user code.
- The four upstream copies of an options object call `copyOptions`. Each hunk carries
  `// DIVERGES(chartjs): adapt-typed-element-options, the copy keeps the class.`:

  | Upstream | Dart |
  |---|---|
  | `cloneIfNotShared` (`core.datasetController.js:230`) | `_cloneIfNotShared`: `shared ? cached : copyOptions(cached)` |
  | `getSharedOptions` (`core.datasetController.js:871`) | `return sharedOptions ??= copyOptions(options);` |
  | `resolveTargetOptions` (`core.animations.js:159`) | `_resolveTargetOptions`: `copyOptions(options)..[r'$shared'] = false..[r'$animations'] = <String, Animation>{}` |
  | `BubbleController.resolveDataElementOptions` (`controller.bubble.js:157`, phase 7) | `copyOptions(values)..[r'$shared'] = false` |

- `sharedOptions` is the port of the field `_sharedOptions`. It drops the underscore and carries
  `@internal`, because `core.interaction.js:49` reads it
  ([Chart.js ADR 0012](0012-dart-file-naming.md)). Dart `null` stands for its `undefined` start
  value (`core.datasetController.js:267`).
- `Object.assign` with a second source writes the keys of that source after the copy. A write of a
  present key keeps its position. The cascade writes the same keys in the same order. Thus the
  entries are the upstream entries.
- The empty `$animations` object is `<String, Animation>{}`, the value that
  [Chart.js ADR 0019](0019-animation.md) §2 gives to `running` (`core.animations.js:71`). Each copy
  gets a new object. Chart.js ADR 0019 owns the other lines of `_resolveTargetOptions`.
- The producers do not call the constructor `XOptions(source)` of Chart.js ADR 0018 §5. It stays
  for the gallery demos and the tests.

### 4. Key order

- A typed class gives the order of Chart.js ADR 0018 §3. The present known keys come in the order
  of `knownKeys`. The extra keys follow in insertion order. `GenericElementOptions` gives the
  insertion order.
- Probes F2 and S1 compared the order with Chart.js in Node.js. For each object that the upstream
  producers make for the four built-in element types, the typed order is the JavaScript order. This
  result covers the cached objects, the shared copies, the copies of `resolveTargetOptions` and the
  line options with `segment` and `$animations`.
- Two cases give another order:
  1. A program writes a default before the registration of its element type. The names then start
     with that key (probe E1, P6). The typed class puts the key at the place of its known key.
  2. An options object with extra keys gets `$animations`, or `segment` for the line. The typed
     class puts the known key before the extra keys. JavaScript puts it after them (probe E1, P5,
     and probe E3).
- These readers read the key order of an options object:
  - `_createAnimations` reads `Object.keys(values)` of the new options (`core.animations.js:72`).
    It starts at the last key (`:76`). It skips each key that starts with `$` (`:78-80`). Thus the
    order changes only the creation order of the option animations (probe E1, P9). Each animation
    writes only its own property.
  - `awaitAll` reads the keys of the new options (`core.animations.js:134-145`). It does not skip
    the `$` keys. Its result does not depend on the order. `running` holds no `$` key (`:78-80`).
    `Promise.all` waits for all promises. Their order does not change the result.
  - The `Object.assign` copies keep the order of their source.
- [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) does not protect the creation order of
  the animations. Thus these differences get no row of their own. The row
  `adapt-typed-element-options` records them.

### 5. The frozen state

- `lib/src/js/js_object.dart` gets the JavaScript part:

  ```dart
  /// A Dart object that `Object.freeze` can freeze (Chart.js ADR 0021).
  abstract interface class JsFreezable {
    /// `Object.isFrozen(this)`.
    bool get isFrozen;

    /// `Object.freeze(this)`. A later write throws a [TypeError].
    void freeze();
  }

  /// `Object.freeze(value)`: freezes a [JsFreezable], then returns [value].
  /// Another value returns with no change.
  // DIVERGES(chartjs): js-semantics-object-freeze, only a JsFreezable freezes.
  T jsObjectFreeze<T>(T value) {
    if (value is JsFreezable) value.freeze();
    return value;
  }

  /// `Object.isFrozen(value)`.
  // DIVERGES(chartjs): js-semantics-object-freeze, only a JsFreezable freezes.
  bool jsObjectIsFrozen(Object? value) => switch (value) {
    final JsFreezable object => object.isFrozen,
    null || Undefined() || num() || String() || bool() => true,
    _ => false,
  };
  ```

- The names parallel `jsObjectKeys`. `jsObjectIsFrozen` gives true for Dart `null`, `undefined`, a
  number, a string and a boolean, as `Object.isFrozen` gives for a primitive. It gives false for
  each other value that is not a `JsFreezable`. An example is the `Map.unmodifiable` of a spec
  fixture.
- `ElementOptions` implements `JsFreezable`. A new options object is not frozen. `freeze` sets the
  frozen state. No member clears it.
- In the frozen state, an options object behaves as a frozen object in strict mode (probe E3
  against probe E1, P1):
  - `operator []=` throws a `TypeError` for each key, also for a write of the same value.
  - `remove` throws a `TypeError` for a present key. It returns Dart `null` for an absent key, as a
    `delete` of an absent property returns true.
  - `clear` throws a `TypeError` when the options contain a key.
  - `addAll`, `putIfAbsent`, `update`, `updateAll` and `removeWhere` of `MapBase` write through
    these three members. Thus a write through them throws too. `putIfAbsent` of a present key
    writes nothing. It returns the value with no throw.
  - The reads, `keys`, `length`, `containsKey`, `jsGet` and the getters do not change.
- The error is a Dart `TypeError`, the class that `lib/` throws at 13 sites for a JavaScript
  `TypeError`. [Chart.js ADR 0009](0009-no-display-only-js-exactness.md) protects the throw, not
  its class. Open records the choice of the maintainer.
- `clone` and `copyOptions` give an options object that is not frozen. `Object.assign({}, x)` also
  gives a new object that is not frozen (probe E1, P1).
- The freeze is shallow, as `Object.freeze` is. A Map value of a frozen options object stays
  writable. An example is `$animations`.
- The port of `core.datasetController.js:831` is a line-by-line port. It carries no marker:

  ```dart
  cache[cacheKey] = jsObjectFreeze(_cloneIfNotShared(values, sharing));
  ```

- It calls the JS runtime for a JS builtin, as ported code calls `jsObjectKeys`.
- `values` is always an `ElementOptions` (section 1). With `sharing` true, the cache entry is
  `values` itself. Thus two calls return the same frozen object, as
  `core.datasetController.tests.js:973-975` expects.
- The ported specs write `Object.isFrozen(opts0)` as `jsObjectIsFrozen(opts0)`.

**The upstream writes into options objects** (probes E2 and F5):
- `core.config.js:352`, `:356` and `:364` write into the new result. The result is not frozen yet.
- `core.datasetController.js:826` writes `$shared` before the freeze at `:831`.
- `controller.line.js:64` and `:66`, `controller.scatter.js:86` and `controller.radar.js:65` write
  into the result of `resolveDatasetElementOptions`. That call passes no index. Thus `sharing` is
  false. The result is a new object or a copy of the cache entry.
- `controller.bubble.js:138` writes into `sharedOptions` or into the result of the bubble override.
  `sharedOptions` is a copy (`core.datasetController.js:871`). The result of the override is the
  copy of `controller.bubble.js:157` or a new result. `:163` and `:165` write into the same result.
- `core.animations.js:71` writes `$animations`. `core.animations.js:101` and `core.animation.js:88`,
  `:94` and `:102` write option values. Their target is an element, the copy of
  `resolveTargetOptions`, element options without `$shared` (`core.animations.js:151-161`), or
  `sharedOptions` (`core.datasetController.js:912`).
- `core.animations.js:121` (`Object.assign(target, values)`) writes into an element or into
  `sharedOptions`.
- `core.animations.js:55` reads `target.options.$animations`. It writes nothing.
- No code in `src/` deletes a key of an options object.

**The results.**
- With the built-in controllers, no upstream write reaches a frozen object. Probe S1 ran updates,
  hovers, animations and a resize of the nine chart types with no throw.
- An element can hold a frozen cache entry with `$shared` true, for example after a hover
  (`core.animations.js:51-56`). Each write path copies such an object first.
  `resolveTargetOptions` copies options with `$shared` true before an animation writes into them
  (`core.animations.js:156-160`).
- The default hover colors are scriptable (`core.defaults.js:62-63`). Thus the default active
  options are not shared. `_resolveElementOptions` does not cache them.
- A frozen object with `$shared` false reaches an element when one cache key gets both values of
  `sharing`. An example is a custom controller whose dataset element and data element have the same
  type (probe F2, case 6):
  - The dataset call passes no index. It caches a frozen copy with `$shared` false.
  - The data call with `sharing` true returns this cache entry.
  - The reset assigns this cache entry to each element.
  - The first animated update writes `$animations` into it at `core.animations.js:71`.
  - Chart.js throws `TypeError: Cannot add property $animations, object is not extensible` when it
    builds the chart. The port throws a `TypeError` at the same write.
- A write by user code into the frozen cache entry throws in both. A write into the options of an
  element with shared options throws in neither (probe E1, P1).
- Thus the frozen state changes no result of a built-in controller. It keeps three upstream
  results:
  - The throw of a write into the cache entry.
  - The throw of case 6.
  - The `Object.isFrozen` results of the specs.

**The other `Object.freeze` sites.** They call `jsObjectFreeze`. Their objects are not
`JsFreezable` in this decision. No upstream code writes into them after the freeze:
- `Animations` (`core.datasetController.js:858`, `plugin.tooltip.js:519`) writes `_chart` and
  `_properties` only in its constructor (`core.animations.js:7-11`). Only the constructor calls
  `configure` (`:10`). `configure` changes the entries of the `Map` in `_properties`. A freeze of
  the `Animations` object does not stop these changes in JavaScript either.
- `params` of `core.layouts.js:395` gets no write. `setLayoutDims`, `updateDims`, `fitBoxes` and
  `placeBoxes` only read it (`core.layouts.js:65-79`, `:116-137`, `:179-206`, `:218-247`).
- Thus these three sites keep the upstream behavior. [Chart.js ADR 0019](0019-animation.md) §9
  keeps `Animations` without `JsFreezable`. The port of `core.layouts` can make its `params` a
  `JsFreezable`, or not. This decision stays valid with either form.

### 6. `DIVERGES` markers and `differences.md` rows

This decision adds two rows. Each item below gives the columns of `differences.md`. The links are
relative to this file.

**`adapt-typed-element-options`**
- Dart file and symbol:
  - `lib/src/core/core.config.dart` `Config.resolveNamedOptions` (`into`)
  - `lib/src/core/core.datasetController.dart` `DatasetController._resolveElementOptions`,
    `_cloneIfNotShared` and `DatasetController.getSharedOptions`
  - `lib/src/core/core.animations.dart` `_resolveTargetOptions`
  - `lib/src/elements/element_options.dart` `createElementOptions` and `copyOptions`
  - phase 7: `lib/src/controllers/controller.bubble.dart`
    `BubbleController.resolveDataElementOptions`
- Upstream: `src/core/core.config.js`@v4.5.1:351-352,
  `src/core/core.datasetController.js`@v4.5.1:230, 821, 871,
  `src/core/core.animations.js`@v4.5.1:159 and `src/controllers/controller.bubble.js`@v4.5.1:157.
- Category: `adapt`.
- Reason: Upstream makes each options object as a plain object. It copies an options object with
  `Object.assign`. The port makes the typed class of the element type id: `PointOptions`,
  `LineOptions`, `BarOptions` or `ArcOptions` (Chart.js ADR 0021). Another id gets
  `GenericElementOptions`. A copy keeps the class of its source. The reason is performance
  ([porting-flow.md](../porting-flow.md) §1.1). [performance.md](../performance.md) §9 has the
  figures. Each instance gives the Map results of a plain object with the same entries. For the
  objects of the built-in charts, the key order is the JavaScript order. Two cases differ. A
  default that a program writes before the registration comes first in the names. The typed class
  puts it at the place of its known key. In a typed copy with extra keys, `$animations` comes
  before the extra keys. Only the creation order of the option animations reads this order.
- Upstream reference: none.
- Test: `test/port/elements/element_options_test.dart`, groups `createElementOptions`, `clone` and
  `copyOptions`. `test/port/core/core.config_test.dart`,
  `test/port/core/core.datasetController_test.dart`,
  `test/port/core/core.datasetController_chart_test.dart` and
  `test/port/core/core.animations_test.dart`, group `adapt-typed-element-options`.
- On a bump: compare `resolveNamedOptions`, `_resolveElementOptions`, the element ids, the names of
  `defaults.elements` and each `Object.assign({}, …)` of an options object.

**`js-semantics-object-freeze`**
- Dart file and symbol: `lib/src/js/js_object.dart` `JsFreezable`, `jsObjectFreeze` and
  `jsObjectIsFrozen`.
- Upstream: `src/core/core.datasetController.js`@v4.5.1:831, 858,
  `src/core/core.layouts.js`@v4.5.1:395, `src/plugins/plugin.tooltip.js`@v4.5.1:519 and
  `test/specs/core.datasetController.tests.js`@v4.5.1:975, 997, 1018.
- Category: `js-semantics`.
- Reason: A Dart object has a frozen state only when it implements `JsFreezable`. `jsObjectFreeze`
  leaves another object writable. Examples are a plain Map, a `List` and an `Animations`.
  `jsObjectIsFrozen` gives false for such an object, also for a `Map.unmodifiable`. No upstream
  code writes into the objects of the other three `Object.freeze` sites after the freeze (Chart.js
  ADR 0021 §5).
- Upstream reference: none.
- Test: `test/port/js/js_object_test.dart`.
- On a bump: compare each `Object.freeze` and `Object.isFrozen` in `src/` and `test/specs/`.

- The markers are line comments of at most 80 columns, of the form
  `// DIVERGES(chartjs): <row id>, <reason>`:
  1. `Config.resolveNamedOptions`, at the line of `core.config.js:352`.
  2. `DatasetController._resolveElementOptions`, at the call of `core.datasetController.js:821`.
  3. `_cloneIfNotShared` (`core.datasetController.js:230`).
  4. `DatasetController.getSharedOptions` (`core.datasetController.js:871`).
  5. `_resolveTargetOptions` (`core.animations.js:159`).
  6. Phase 7: `BubbleController.resolveDataElementOptions` (`controller.bubble.js:157`).
  7. `createElementOptions` and `copyOptions` of the port-only file `element_options.dart`.
  8. `jsObjectFreeze` and `jsObjectIsFrozen` of the port-only file `js_object.dart`, with the row
     `js-semantics-object-freeze`.
- Markers 1 to 7 name the row `adapt-typed-element-options`. A hunk of a port-only file that gives
  the difference of a row carries the marker of that row ([differences.md](../differences.md)).
- `core.datasetController.js:831` gets no marker (section 5). The class of the error gets no row
  (section 5). The key order gets no row of its own (section 4).
- [porting-flow.md](../porting-flow.md) §1.1 asks for a port-only test that pins the upstream
  behavior of both forms. Section 7 lists these tests.

### 7. Tests

- `test/port/elements/element_options_test.dart` (pure layer, `package:test`):
  - Group `createElementOptions`: `PointElement.id`, `LineElement.id`, `BarElement.id` and
    `ArcElement.id` give the four typed classes. Another id gives `GenericElementOptions`. Each call
    gives a new, empty object that is not frozen.
  - Group `clone`, for each of the five classes: the source gets known keys, extra keys, the
    `undefined` sentinel and `null`. The copy has the same class. It has the same entries in the
    same `jsObjectKeys` order. It is not frozen. A write into the copy does not change the source.
    The Map of extra keys is a new Map. The copy of a frozen object is not frozen.
  - Group `clone`, one test for each known key: a source with only that key gives a copy with the
    identical value (`same`). Thus the test fails when `clone` does not copy a field.
  - Group `copyOptions`: an `ElementOptions` gives its `clone`. A plain Map gives a plain Map in the
    `jsObjectKeys` order. For example, `{'b': 1, '10': 2}` gives the keys `['10', 'b']`.
  - Group `frozen state`, for each of the five classes: after `freeze`, `isFrozen` is true. A write
    of a known key, of an extra key, of `$animations` and of the same value throws a `TypeError`.
    `remove` of a present key, `clear`, `addAll` and `update` throw a `TypeError`. `remove` of an
    absent key returns Dart `null`. `putIfAbsent` of a present key returns the value. The getters
    and `operator []` give the values from before the freeze.
  - Group `GenericElementOptions`: the random sequence test of Chart.js ADR 0018 §6 against a plain
    Map. The key lists are equal, also for `$shared` and `$animations`.
- `test/port/js/js_object_test.dart`: `jsObjectFreeze` returns its argument. It freezes a
  `JsFreezable`. It leaves a plain Map writable (the pin of `js-semantics-object-freeze`).
  `jsObjectIsFrozen` gives true for `null`, `undefined`, a number, a string and a boolean. It gives
  false for a plain Map, a `Map.unmodifiable`, a `List` and a function.
- `test/port/core/core.config_test.dart`, group `adapt-typed-element-options`. It uses
  `package:test`. Its `main()` registers the four element classes through a new
  `TypedRegistry(Element.jsClass, 'elements')`
  ([Chart.js ADR 0020](0020-registry-and-component-classes.md) §5). `core.typedRegistry.dart` is a
  pure layer. The registration runs before the snapshot of the restore. Thus each test finds the
  four entries of `defaults.elements` ([Chart.js ADR 0022](0022-chart-test-harness.md) §8). The
  cases:
  - The registry pin: for each of the four ids, `jsObjectKeys(defaults.elements[id])` equals the
    `knownKeys` of its class without `$shared`, `$animations` and `segment`. This order is the only
    property of Chart.js ADR 0020 that the key order needs.
  - For each id, `resolveNamedOptions` runs with the names `jsObjectKeys(defaults.elements[id])`.
    It runs once with `into: createElementOptions(id)` and once with `into: null`. The typed result
    is `into`. `$shared` is true. The keys are `[r'$shared', ...names]`. Both results have the same
    entries in the same `jsObjectKeys` order.
  - The cases of both runs are static scopes, a scriptable option, an indexable array, JS `null`
    and the `undefined` sentinel. A scriptable option gives `$shared` false in both runs.
  - A default key that a program adds after the registration is the last key in both runs.
  - A default that a program writes before the registration (probe E1, P6). The test removes the
    entry `point` of `defaults.elements`. Then it writes the default. Then it registers
    `PointElement.jsClass` through a second new `TypedRegistry`. The plain run gives the order of
    the names. The typed run gives the order of the known keys. This test pins
    `adapt-typed-element-options`. The restore puts back `defaults` after the test.
  - Names that are not the names of an element type, with `into: null`, give a plain Map.
- `test/port/core/core.datasetController_chart_test.dart`, with the `acquireChart` of Chart.js ADR
  0022. Phase 5 has no concrete controller. Thus the file registers a port-only test controller
  with the data element type `point` and the dataset element type `line`. The test controller
  follows the option calls of `controller.line.js:41-120`. `enableOptionSharing` is true, unless a
  case states false.
  - The file registers its test controllers, its test scale and its test element class as class
    values (Chart.js ADR 0020 §8). Its `main()` registers them before the snapshot of the restore
    (Chart.js ADR 0022 §8).
  - The file has `@TestOn('vm')`. Its chart cases are `testWidgets` cases (Chart.js ADR 0022 §1
    and §2).
  - The chart cases are in a file of their own. `test/port/core/core.datasetController_test.dart`
    calls `setUpSpecs()`, and `setUpSpecs()` removes the built-in components. That file keeps its
    fake chart. Its group `adapt-typed-element-options` runs a part of these cases on the fake
    chart.
  - Group `adapt-typed-element-options`:
    - The shared data options are a frozen `PointOptions` with `$shared` true. The indices 0 and
      1 give the same object. This case is the typed form of
      `core.datasetController.tests.js:956-976`.
    - With `enableOptionSharing` false, each call gives a new `PointOptions` that is not frozen.
      The cache entry is frozen, with `$shared` false (probe E1, P2).
    - A scriptable option gives a `PointOptions` that is not frozen, with `$shared` false
      (`core.datasetController.tests.js:1000-1019`).
    - The dataset options are a new `LineOptions` for each call, not frozen. The cache entry is
      frozen (probe E1, P3). The line element holds `LineOptions` with the keys
      `[r'$shared', ...names, 'segment']`.
    - `getSharedOptions` gives a `PointOptions` that is not frozen, with the key order of its
      source. After an update in the mode `'none'`, the data elements hold it (probe E1, P1).
    - A write into the frozen shared options throws a `TypeError`. A write into the options of a
      point does not throw.
    - After `setHoverStyle` and the end of its animation, the point holds a `PointOptions` with
      `$shared` false.
    - The element type ids `bar` and `arc` give `BarOptions` and `ArcOptions`. A registered test
      element class with the id `custom` gives a frozen `GenericElementOptions` with the key order
      of the names.
    - Case 6: a test controller with the element type `point` for the dataset and for the data.
      The controller sets `enableOptionSharing` to true. The config gives an `animation` with a
      duration. The build of the chart throws a `TypeError` at the write of `$animations`
      (`core.animations.js:71`). `acquireChart` sets `animation: false` only when the config gives
      no `animation` (`chartjs-test-utils` `src/utils.js:60`).
- `test/port/core/core.animations_test.dart`, group `adapt-typed-element-options`, through
  `Animations.update(target, {'options': newOptions})`:
  - From frozen shared `PointOptions`, the target gets a new `PointOptions`. It is not frozen. Its
    `$shared` is false. Its `$animations` is empty. The source does not change.
  - From a plain Map, the target gets a plain Map with the upstream key order. The spec at
    `core.animations.tests.js:54-62` also covers this case.
  - Typed options with an extra key put `$animations` before the extra key (the pin of
    `adapt-typed-element-options`). `GenericElementOptions` puts it last, as upstream does.
  - The write level of case 6: the target holds frozen `PointOptions` with `$shared` false. An
    animated update throws a `TypeError` at the write of `$animations`.
- A test file that imports `acquireChart` has `@TestOn('vm')` (Chart.js ADR 0022 §1).
- A ported spec that only expects a throw (`toThrow()`) uses `throwsA(anything)`, as
  `test/specs/helpers.config_test.dart:630` does. Thus it accepts a `TypeError` and an
  `UnsupportedError`. The port-only tests above pin the `TypeError`.
- `test/specs/core.datasetController_test.dart` ports the three `Object.isFrozen` assertions with
  `jsObjectIsFrozen`. The three cases skip as `'blocked: controller.line'` and
  `'blocked: controller.radar'` until phase 7.
- Phase 7 adds a port-only test for each built-in chart type. It compares the class and the key
  order of each options object with lists from `jsObjectKeys(defaults.elements[type])`. Thus it
  needs no reference data.
- The element tests of Chart.js ADR 0018 §6 do not change. They still run with plain Map options
  and with typed options.

### 8. Cost and the measurement in phase 5

- The microbenchmarks E4 and J measured the producers and the copies on AOT and on dart2wasm -O2.
  The Evidence has each probe. The figures are in ns for each operation, AOT / dart2wasm.
- `resolveNamedOptions` with the typed class is not slower than with a plain Map:
  - Without a scriptable option: 721 to 922 against 896 to 1060 on AOT. On dart2wasm: 1352 to
    1511 against 1585 to 1749 (E4, G1).
  - With a scriptable option: 2717 to 2753 against 2780 to 2924 on AOT. On dart2wasm: 3060 to 3227
    against 3246 to 3559 (E4, G2).
  - The typed object needs fewer writes into a hash table: 121 to 123 against 286 to 295 on AOT
    for the writes alone (E4, G7).
- The class lookup with the allocation: the id table costs 5.0 to 5.5 / 5.5 to 6.9. The names
  lookup of the fidelity draft costs 23.6 to 24.2 / 28.5 for the point names (J).
- The copies:
  - `clone` costs 11.8 to 14.4 / 11.6 to 13.2. The ported `Object.assign` loop over a plain Map
    costs 477 to 575 / 551 to 608. `Map.of` costs 56.7 to 65.7 / 63.7 to 70.4. The constructor of
    Chart.js ADR 0018 §5 costs 510 to 640 / 606 to 667 (E4, G4).
  - The copy of `resolveTargetOptions` (clone and cascade) costs 47.3 to 49.1 / 39.5. The
    two-source copy of the fidelity draft costs 152.8 to 158.2 / 147.5 (J).
  - The bubble copy (clone and one write) costs 23.5 to 23.7 / 19.4. The two-source copy costs 96.4
    to 100.6 / 92.2 (J). The bubble copy runs for each element at each update.
  - At 1000 scatter points, one update makes 3004 copies (S1). `clone` then costs about 35 µs on
    AOT. The `Object.assign` loop costs about 1.4 ms.
- The draw reads: the 11 option reads of a point draw cost 4.7 to 5.2 / 3.3 to 4.0 through the
  getters. Through `jsGet` on a plain Map, they cost 81.5 to 87.6 / 158 to 182 (E4, G6).
- The frozen state adds no measured cost on AOT (E4, G1, G2, G4, G6 and G7). On dart2wasm, the 11
  reads of G6 took 0.4 ns more in both runs. At 20000 points, this cost is 8 µs for each frame.
- Record these figures in a new section 9 of [performance.md](../performance.md), "Typed options in
  the chart".
- Phase 5 measures the element draw cost through the real chart path:
  - `apps/chartjs_gallery/lib/demo/stress_demo.dart` gets the `StressMode` value `chart`
    (`--dart-define=MODE=chart`). It draws N points through a `Chart` of phase 5: `core.controller`,
    `core.config`, the producers of `DatasetController` and `PointElement`.
  - No concrete controller exists before phase 7. Thus the gallery registers a port-only
    `StressPointController extends DatasetController` in `apps/chartjs_gallery/lib/demo/`. Its data
    element type is `PointElement`. It has no dataset element. The gallery registers it through its
    class value ([Chart.js ADR 0020](0020-registry-and-component-classes.md) §3 and §8).
  - Its `updateElements` follows `controller.line.js:76-120`: the port of `_getSharedOptions`,
    `resolveDataElementOptions` and `updateElement`. It computes the pixel positions itself, because
    the scales come in phase 6.
  - `--dart-define=SHARING=0` sets `enableOptionSharing` to false. The default is true. With true,
    each point holds the copy of `getSharedOptions`, as in a line chart. With false, each point gets
    a copy of the cache entry at each update, as in a scatter chart.
  - Three cases, each with `animation: false`: (a) `chart.draw()` in each frame, (b)
    `chart.update('none')` in each frame, (c) case (b) with a scriptable `backgroundColor`
    (`--dart-define=SCRIPTABLE=1`). The `STRESS` line adds the time of `chart.update()`.
  - The scenarios are N = 1000, 5000 and 20000, each with `SHARING` on and off.
  - The A/B variant changes one line: `_resolveElementOptions` passes `null` as `into`. Then each
    options object is a plain Map. The copies keep the plain Map.
  - Measure on the Pixel 8a, on macOS, in Chrome with dart2wasm and on the iPhone 17 Pro. Use the
    protocol of [performance.md](../performance.md) §6, with fresh processes and 7 seconds for each
    scenario. Record the FPS, the draw time and the raster time.
  - Acceptance: in case (a) with typed classes, the draw time for each point must equal the
    `elements` mode with typed options of [performance.md](../performance.md) §8.4. The tolerance
    is the spread of the fresh processes of §6.
  - A scenario that is slower with the typed build blocks the change
    ([porting-flow.md](../porting-flow.md) §1.1).
  - Phase 7 runs the same scenarios again with the ported `LineController` and `ScatterController`.
    Then it removes `StressPointController`.

### 9. Interfaces from the other phase 5 ADRs

- [Chart.js ADR 0019](0019-animation.md) (animation):
  - The Dart value of the empty `$animations` object (`running`, `core.animations.js:71`). Chart.js
    ADR 0019 §2 gives `<String, Animation>{}`. This ADR needs a new object for each copy.
  - The animations write into an options object through `operator []=`. They read it through
    `operator []` or `jsGet` (`core.animations.js:71`, `:101`, `:121`, `core.animation.js:29`,
    `:88`, `:94`, `:102`). Chart.js ADR 0019 §2 gives these accesses as `readProperty` and
    `writeProperty`.
  - `_resolveTargetOptions` copies through `copyOptions` (section 3).
  - Chart.js ADR 0019 §9 keeps `Animations` without `JsFreezable` (section 5).
- [Chart.js ADR 0020](0020-registry-and-component-classes.md) (registry and component classes):
  - The element type ids only. The `id` read of `datasetElementType` and `dataElementType` gives
    them (Chart.js ADR 0020 §4). The class value of each element class holds its
    `static const String id` ([Chart.js ADR 0017](0017-element-properties.md) §2, Chart.js ADR 0020
    §3).
  - For the tests and the key order: `defaults.elements[id]` gets the keys of the element
    `defaults`, then the keys of its `defaultRoutes`. `registerDefaults` and `routeDefaults` give
    this order upstream (`core.typedRegistry.js:84-113`). The class does not depend on this order.
  - A test registers a test element class or a test controller class as a class value (Chart.js
    ADR 0020 §8).
- [Chart.js ADR 0022](0022-chart-test-harness.md) (chart test harness): `acquireChart(config)`
  returns a `Chart` (§4). `chart.getDatasetMeta(i).controller` returns its controller. The release
  at the unmount ends each chart (§8). A test file registers its own controller and element
  classes before the snapshot of the restore (§8).

## Alternatives considered

Each option has a score for the four priorities of [porting-flow.md](../porting-flow.md) §1.1. The
priorities are (1) the protected behavior, (2) performance, (3) the upstream structure and (4) less
code of our own.

**The three drafts.** A design panel wrote three drafts. A judge scored them and chose the
performance draft:

| Draft | Behavior | Performance | Structure | Less code |
|---|---|---|---|---|
| fidelity | 9 | 7 | 8.5 | 6 |
| performance (this ADR) | 9 | 9 | 7 | 6 |
| simplicity | 8 | 8 | 6 | 8 |

- The three drafts tie on behavior. Each keeps the resolved values and the identity of the frozen
  shared result (`core.datasetController.tests.js:973`). Each gives the three `Object.isFrozen`
  results (`:975`, `:997`, `:1018`). Each throws on a write into frozen options, also in case 6.
- The performance draft is the fastest (probe J). It also avoids the silent loss of the typed class
  in probe E1, P6.
- The fidelity draft has the best structure: one hunk, with no new parameter. Priority 2 outranks
  priority 3.
- The simplicity draft adds a reshaped freeze hunk at `core.datasetController.js:823-834`, a second
  `adapt` row and a platform-dependent `isFrozenOptions`.

**The class lookup.**
- **Plain Maps from the producers (the upstream form).** (1) Equal. (2) Worse. The elements lose
  the typed reads, 20 % to 30 % of the draw time at 20000 points
  ([performance.md](../performance.md) §8.4). A resolution costs 896 to 1060 ns, not 721 to 922 ns
  (E4, G1). (3) Best. Rejected on (2).
- **The class from the names: a switch on the first name, then a prefix compare (the fidelity
  draft).** (1) Equal. (2) Worse. The lookup costs 23.6 to 24.2 / 28.5 ns against 5.0 to 5.5 / 5.5
  to 6.9 ns (J). A default that a program writes before the registration puts its key first (E1,
  P6). `registerDefaults` merges `defaults.get(scope)` before `item.defaults`
  (`core.typedRegistry.js:86-90`). The names lookup then gives no typed class. The elements lose
  20 % to 30 % of the draw time with no signal. (3) Better. The signature of `resolveNamedOptions`
  stays. The call at `:821` does not change. The lookup depends on the key order of the registry
  (Chart.js ADR 0020 §5). Rejected on (2).
- **The class from the first name only.** (1) Equal. (2) The lookup costs 9.3 to 9.9 / 8.2 to
  9.6 ns (E4, G3). It gives no typed class in probe E1, P6. Then the draw loses the typed reads.
  (3) Better: the signature stays. Rejected on (2).
- **The class from a compare of all names.** (1) Equal. An unoptimized full compare costs 157 to
  228 ns (E4, G3). A first-name switch with a prefix compare costs 24 / 29 ns (J). The cost is not
  the reason to reject it. Each order-sensitive compare fails in probe E1, P6. It also depends on
  the key order of the registry (Chart.js ADR 0020 §5). Rejected on (2) and on that dependency.
- **A factory member of the element class through the registry.** (1) Equal. (2) The Map lookup
  of a factory adds about 30 ns on AOT (S2: 980.0 ns against 950.3 ns). It gives no gain for the
  four built-in types. (3) Worse: it adds a static property to each element class value (Chart.js
  ADR 0020 §3). Rejected for phase 5. Open keeps it for custom element types.
- **A factory parameter `AnyObject Function()? create` in place of `into`.** (1) and (2) Equal.
  (4) Worse: it adds a function type to the signature. Rejected on (4).
- **The element type id as a parameter of `resolveNamedOptions`.** (1) and (2) Equal. (3) Worse:
  `core.config.dart` then imports `element_options.dart`. `core.config.js` imports no element
  module. Rejected on (3).
- **A conversion after the resolution with the constructor of Chart.js ADR 0018 §5.** (1) Equal.
  (2) Worse: the conversion adds 501.5 ns on AOT to each resolution (S2). Rejected on (2).

**The element types without a typed class.**
- **A plain Map with no frozen state.** (1) Worse. The shared options of a custom element type stay
  writable. Upstream throws a `TypeError` for a write into them. Case 6 does not throw. Rejected on
  (1).
- **A plain Map, frozen as an `UnmodifiableMapView` copy (the simplicity draft).** (1) Equal for
  the specs. In the shared case, `_resolveElementOptions` returns the copy in place of `values`.
  `isFrozenOptions` tests `is UnmodifiableMapView`. On dart2js, `Map.unmodifiable` gives a
  `ConstantMap`, not an `UnmodifiableMapView` (dart-sdk js_runtime `core_patch.dart:412`). Thus the
  result for a Map that user code froze depends on the platform. (2) Equal: reads of
  `Map.unmodifiable` cost 82.3 to 83.3 / 151.3 ns (J). (3) Worse: a reshaped hunk at
  `core.datasetController.js:823-834` and a second `adapt` row. Rejected on (3).
- **`ObjectOptions`: all keys in the Map of extra keys of the base class (the fidelity draft).**
  (1) Equal. (2) Worse. Ten `jsGet` reads at a polymorphic site cost 100.9 / 194.0 ns. A plain
  Map costs 75.4 to 75.7 / 129 to 138 ns (+33 % / +40 % to +50 %, J). The fidelity draft
  measured a smaller cost at a monomorphic site (F4). Rejected on (2).
- **`GenericElementOptions` with the base fields for `$shared` and `$animations`.** (1) Equal,
  except the position of `$animations`. (2) Worse: ten reads cost 131.2 to 132.5 / 223.4 ns (J).
  Eleven writes and ten reads cost 491 to 516 ns against 394 to 403 ns for a plain Map (E4, G8).
  The simplicity draft measured this form as its "generic subclass" (118.0 ns on AOT, S2). Rejected
  on (2).

**The copies.**
- **A two-source `copyOptions(source, values)` (the fidelity draft).** (1) Equal. (2) Worse. The
  copy of `resolveTargetOptions` costs 152.8 to 158.2 / 147.5 ns against 47.3 to 49.1 / 39.5 ns.
  The bubble copy costs 96.4 to 100.6 / 92.2 ns against 23.5 to 23.7 / 19.4 ns (J). (3) Better:
  one call for one `Object.assign`. Rejected on (2).
- **The constructor of Chart.js ADR 0018 §5.** (2) Worse. It costs 510 to 640 / 606 to 667 ns.
  `clone` costs 11.8 to 14.4 / 11.6 to 13.2 ns (E4, G4). (4) Better: no copy constructors.
  Rejected on (2).
- **A loop over the known keys.** (2) Worse: 215.8 ns on AOT against 12.3 ns for the field copy
  (S2). Rejected on (2).
- **Plain Map copies.** (2) Worse. A copy loses the typed class. The points of a line chart hold
  the copy of `getSharedOptions` (E1, P1). Their draw then reads Map entries (E4, G6). Rejected on
  (2).
- **`Map.of` for the plain branch of `copyOptions`.** (1) Worse for a resolver. `Map.of` reads
  `keys`, the `ownKeys` of the resolver. `Object.assign` reads only the enumerable keys, the
  `jsObjectKeys` of the port (`test/specs/helpers.config_test.dart:15-21`). (2) It costs 56.7 to
  65.7 / 63.7 to 70.4 ns. The `jsObjectKeys` loop costs 477 to 575 / 551 to 608 ns (E4, G4). No
  chart path reaches the branch (section 3). Thus the gain does not reach a frame. Rejected on (1).

**The frozen state.**
- **No frozen state.** (1) Worse. The spec at `core.datasetController.tests.js:975` fails. Case 6
  does not throw. A write into the cache entry changes the result of each later call. (2) Equal:
  the frozen state has no measured cost (E4). Rejected on (1).
- **A frozen copy through `Map.unmodifiable` at `:831`, with no other change.** (1) Worse. The cache
  entry is then not the returned `values`. Thus `opts0 === opts1` of
  `core.datasetController.tests.js:973` fails. (2) Worse: the cache entry loses its typed class.
  Rejected on (1).
- **An `UnsupportedError` in place of a `TypeError` (the fidelity and simplicity drafts).** (1)
  Equal: Chart.js ADR 0009 protects the throw, not its class. The ported specs accept both classes.
  (2) and (4) Equal. (3) The `TypeError` has the name of the JavaScript error. `lib/` throws
  `TypeError()` at 13 sites for a JavaScript `TypeError`. The Open item of Chart.js ADR 0018 names a
  `TypeError`. The `UnsupportedError` matches only the `Map.unmodifiable` fixtures of the tests.
  Rejected on (3). Open records the choice of the maintainer.
- **`remove` of an absent key throws, as `Map.unmodifiable` does (the simplicity draft).** (1)
  Worse than strict mode. A `delete` of an absent key succeeds in JavaScript (E1, P1). Rejected
  on (1).

## Consequences

- In a chart, each element gets a typed class or `GenericElementOptions`. The typed reads of
  Chart.js ADR 0018 §4 apply in a chart, not only in the gallery demos.
- `resolveNamedOptions` has a fifth optional parameter. A caller with four arguments gets a plain
  Map, as upstream gives a plain object.
- Six ported hunks and two port-only functions carry the marker of `adapt-typed-element-options`.
  Phase 5 adds five of the ported hunks. Phase 7 adds the bubble hunk. `jsObjectFreeze` and
  `jsObjectIsFrozen` carry the marker of `js-semantics-object-freeze`.
- A write into a frozen options object throws a `TypeError`. User code that changes the options of
  an element must copy them first, as `controller.bubble.js:157` does.
- `element_options.dart` gets about 150 more lines: `clone` in five classes, the frozen state,
  `GenericElementOptions`, `createElementOptions` and `copyOptions`. It stays a pure layer.
- `js_object.dart` gets `JsFreezable`, `jsObjectFreeze` and `jsObjectIsFrozen`.
  [Chart.js ADR 0019](0019-animation.md) §1 adds `jsTypeof` to the same file. Its port-only header
  names the JS property read, `typeof` and the frozen state.
- `core.config.dart` does not import `element_options.dart`. `core.datasetController.dart` and
  `core.animations.dart` import it. `element_options.dart` is a pure layer.
- A new known key after an upstream bump needs a field, a getter, the two switches and one line of
  `clone`. The copy test for each known key fails when that line is absent.
- A derived element class with its own id gets `GenericElementOptions`. Its draw reads Map entries.
- In two cases, the key order differs from JavaScript (section 4). Only the creation order of the
  option animations reads it.
- The `runtimeType` of an options object is visible to Dart code. JavaScript code has no such read.
- [performance.md](../performance.md) gets section 9. Its section 7 item "Typed element options"
  closes when section 9 has the figures of `MODE=chart` on the four platforms.
- The two Open items of Chart.js ADR 0018 have their decision here.

## Open

- **The class of the error.** This ADR chooses `TypeError`. The maintainer can choose
  `UnsupportedError`. The change is the `throw` of the frozen state and the pin tests. The ported
  specs accept both classes.
- **A derived element class with its own id** (probe E1, P7). It gets `GenericElementOptions` now.
  No chart of Chart.js uses such a class. Two options give it the class of its parent:
  - A second lookup by names in `createElementOptions` for an id with no typed class: a switch on
    the first name, then a prefix compare. It needs the names as a second argument. It costs 23.6 to
    24.2 / 28.5 ns for a match and 8.1 to 8.2 / 9.1 ns for no match (J). It runs only after the id
    table misses. A default that a program writes before the registration (P6) defeats it.
  - A lookup through the parent class value. The class value of the subclass gives its parent as
    `superclass`, and the `id` of the parent as `superclass.id`
    ([Chart.js ADR 0020](0020-registry-and-component-classes.md) §1 and §14).
    `_resolveElementOptions` gets only the `id`. Thus this option needs the class value at the
    call: `this.dataElementType` or `this.datasetElementType`. P6 does not defeat it.
  - The maintainer selects one of the two options, or keeps `GenericElementOptions`.
- **A typed class for a custom element type that does not extend a built-in type.** It needs a
  static property of the element class value. An example is a factory. Chart.js ADR 0020 §14 puts
  such a property into the `statics` of the class value. No element of Chart.js needs it.
- **The names of `_resolveElementOptions`.** `jsObjectKeys(defaults.elements[elementType])`
  (`core.datasetController.js:817`) costs 117 to 126 / 156 to 172 ns for each resolution (E4, G3b).
  A cache of the names needs a change signal from `defaults`. Phase 5 keeps the upstream form.
- **The doughnut and the pie.** They make 6001 calls of `resolveNamedOptions` in one update at
  1000 arcs (S1). Phase 7 measures this path.
- **The figures of `MODE=chart`** (phase 5) and of the ported controllers (phase 7).

## Evidence

The probes are in subfolders of
`/private/tmp/claude-501/-Users-vasilich-IdeaProjects-flutter-ports/42473ad1-0196-429c-8b17-c32d881d14b9/scratchpad/design/typedopts/`.
The paths below are relative to that folder.

The machine is an Apple M3 Max with macOS. The Dart SDK is 3.12.2 of Flutter 3.44.9. AOT is
`dart compile exe`. dart2wasm is `dart compile wasm -O2`, unless a probe states another level.
Flutter uses -O2 for the profile and release builds of the web
(`packages/flutter_tools/lib/src/web/compiler_config.dart:178` of Flutter 3.44.9). Node.js v24.12.0
runs the Wasm modules. The JavaScript probes ran Node.js v24.12.0 on arm64. They record key orders,
counts and throws, not numbers. Thus the x64 rule of
[Chart.js ADR 0010](0010-js-numeric-semantics.md) does not apply to them.

**E1. Upstream probe of the performance draft** (`performance/probe_upstream.mjs`, output
`performance/probe_upstream.txt`). It runs the pinned `third_party/Chart.js` v4.5.1 with the mock
context of chartjs-test-utils. Its labels are P1 to P9. It has no P4.
- P1, line chart: `enableOptionSharing` true, `opts0 === opts1` true, `$shared` true,
  `Object.isFrozen` true. The keys are `$shared`, then the nine point names. The element options are
  `_sharedOptions`, not `opts0`. `_sharedOptions` is not frozen. It has the same keys.
- P1, strict mode: `opts0.radius = 9`, `opts0.radius = opts0.radius`, `opts0.newKey = 1` and
  `delete opts0.radius` throw a `TypeError`. `delete opts0.absentKey` does not throw.
  `Object.assign({}, opts0)` is not frozen. It has the same key order.
- P2, radar chart: `r0 === r1` false, `$shared` false, not frozen. The cache entry is frozen.
- P3, the dataset options of the line: `ds0 === ds1` false, `$shared` false, not frozen. The cache
  entry is frozen, with `$shared` false. The line element options end with `segment`.
- P5, a default key `myKey` that a program adds after the registration: the names end with
  `myKey`. The copy of `resolveTargetOptions` has the keys `…, borderColor, myKey, $animations`.
- P6, `defaults.set('elements.point', {radius: 5})` before the registration: the names are
  `radius`, then the other eight point names.
- P7, `class MyPoint extends PointElement` with `id = 'myPoint'`: its names are the point names.
- P8, bubble chart: the result is not frozen, with `$shared` false. The cache entry is frozen.
- P9, the creation order of the option animations for the keys `backgroundColor`, `borderColor`,
  `radius` and `borderWidth`: `borderColor, backgroundColor, radius, borderWidth`.

**E2. Upstream search of the performance draft** (`performance/grep_upstream.txt`). It lists these
sites:
- Each write into an options object in `src/`.
- The four `Object.assign` copies of an options object.
- The four `Object.freeze` sites and the three `Object.isFrozen` assertions.
- The callers of the producers.

Section 5 gives the results. This ADR read each cited line again at v4.5.1.

**E3. Dart probe of the frozen state** (`performance/bench/probe_frozen.dart`, output
`performance/probe_frozen.txt`). It uses the scratch class of E4 with the frozen state.
- Frozen `PointOptions`: `o['radius'] = 9.0`, the write of the same value, `o['newKey'] = 1.0`,
  `remove('radius')`, `addAll` and `clear` throw a `TypeError`. `remove('absentKey')` does not
  throw. These are the results of P1.
- `clone` gives a `PointOptions` that is not frozen, with the same keys. A write into the clone does
  not change the source.
- The copy of P5: `PointOptions` gives `…, borderColor, $animations, myKey`.
  `GenericElementOptions` gives `…, borderColor, myKey, $animations`, the order of P5.

**E4. Microbenchmark of the performance draft** (`performance/bench/bench.dart`, generator
`performance/gen.py`, runner `performance/bench/run_wasm.mjs`, outputs
`performance/bench/aot_run2.txt`, `aot_run3.txt`, `wasm_O2_run1.txt` and `wasm_O2_run2.txt`).
- It uses the real `createResolver`, `attachContext` and `descriptors` of `helpers.config.dart` and
  the real `defaults` of `core.defaults.dart`. The scopes are the seven scopes of a point of a line
  dataset. The benchmark ports `resolveNamedOptions` and `needContext`.
- Each group runs its forms interleaved, in 9 rounds. A cell gives the range of the medians of two
  processes. The four typed classes, `GenericElementOptions` and plain Maps pass through the same
  call sites. Thus the calls are polymorphic, as in a chart.

| Group | Form | AOT (ns) | dart2wasm (ns) |
|---|---|---|---|
| G1 `resolveNamedOptions`, no scriptable option | plain Map (upstream) | 896-1060 | 1585-1749 |
| | typed, id table | 721-922 | 1352-1511 |
| | typed, id table, frozen state | 722-879 | 1402-1528 |
| | typed, first name | 717-875 | 1361-1456 |
| G2 `resolveNamedOptions`, scriptable `backgroundColor` | plain Map (upstream) | 2780-2924 | 3246-3559 |
| | typed, id table | 2717-2753 | 3060-3227 |
| | typed, id table, frozen state | 2775-2831 | 3031-3106 |
| G3 class lookup with the allocation and a call | id table | 13.9-14.8 | 11.7-13.8 |
| | first name | 9.3-9.9 | 8.2-9.6 |
| | compare of all names, unoptimized | 221-228 | 157-181 |
| | plain Map literal `{$shared: true}` | 34.2-36.3 | 23.2-27.0 |
| G3b `jsObjectKeys(defaults.elements.point)` | | 117-126 | 156-172 |
| G4 `Object.assign({}, cached)` | `Map.of` | 56.7-65.7 | 63.7-70.4 |
| | `jsObjectKeys` loop on a plain Map | 477-575 | 551-608 |
| | constructor of Chart.js ADR 0018 §5 | 510-640 | 606-667 |
| | `clone` | 11.8-14.4 | 11.6-13.2 |
| | `clone`, frozen state | 12.0-14.9 | 9.9-10.6 |
| G5 `resolveTargetOptions` copy | plain Map, a spread `{...o}`, not the `jsObjectKeys` loop | 74.1-87.8 | 82.1-117 |
| | `clone` and 2 writes | 51.9-62.9 | 49.6-68.6 |
| G6 the 11 option reads of a point draw | `jsGet` on a plain Map | 81.5-87.6 | 158-182 |
| | typed getters | 4.7-5.2 | 3.3-4.0 |
| | typed getters, frozen state | 4.8-5.2 | 3.7-4.4 |
| G7 the writes of `resolveNamedOptions` alone | plain Map | 286-295 | 218-298 |
| | typed | 121-123 | 132-171 |
| | typed, frozen state | 121-123 | 133-168 |
| G8 custom element type, 11 writes and 10 reads | plain Map | 394-403 | 525-673 |
| | `GenericElementOptions`, base fields | 491-516 | 612-773 |
| | `GenericElementOptions`, one Map | 378-389 | 497-630 |
| | `GenericElementOptions`, one Map, frozen state | 383-403 | 486-636 |

- The plain baseline of G5 is a spread. The plain branch of `copyOptions` is the `jsObjectKeys`
  loop. Its copy alone costs about 480 ns (G4).

**F1. Names of the element types, fidelity draft** (`fidelity/js/upstream_probe.mjs`, output
`fidelity/js/upstream_probe.out`). It runs the pinned `third_party/Chart.js/src` in Node.js with a
resolve hook from the `.js` imports to the `.ts` files. It registers all components. The four lists
`Object.keys(defaults.elements[type])` equal the known keys of Chart.js ADR 0018 without `$shared`,
`$animations` and `segment`. `MyPoint`, `MyLine`, `MyBar` and `MyArc` give the names of their
parents first.
A key that a program adds to `defaults.elements.point` comes last.

**F2. Producers, key order and frozen state, fidelity draft** (same files).
- Line chart: the shared result is the same object for the indices 0 and 1, frozen, with `$shared`
  true. The point options are the shared copy, not frozen. The line options end with `segment`. A
  write into the frozen object throws `TypeError: Cannot assign to read only property 'radius'`.
- Hover with animations: the copy of `resolveTargetOptions` has the point names, then
  `$animations`, with `$shared` false. The animated shared copy has `$animations` last.
- Bar, doughnut, bubble and scatter: `$shared`, then the names of their element type.
- Case 6 (keys `sameType.*` of the output): a controller with `point` for the dataset and the data
  element types, with `enableOptionSharing` true. The construction of the chart throws
  `TypeError: Cannot add property $animations, object is not extensible`. With `animation: false`,
  the data options are frozen, with `$shared` false. The point options are the same frozen object.
  A later animated update throws the same `TypeError`.
- `Object.assign({}, a, {$shared: false, $animations: {}})` keeps an `$animations` key of `a` at
  its place. Without such a key, it puts `$animations` last.

**F3. Microbenchmark of the fidelity draft** (`fidelity/dart/bin/bench.dart`, outputs
`fidelity/dart/run1.txt`, `run2.txt`, `resolve_runs.txt` and `build_runs3.txt`). The result part of
`resolveNamedOptions` with 9 names costs 334 / 326 ns as a plain Map and 147 / 154 ns as a typed
class. The full call costs 872 / 1431 ns as a plain Map and 707 / 1280 ns as a typed class. The
processes of one variant differ by up to 76 % for a full call.

**F4. Reads of `ObjectOptions`, fidelity draft** (`fidelity/dart/bin/read_bench.dart`, output
`fidelity/dart/read_runs.txt`). Ten `jsGet` reads at a monomorphic site, 3 processes: 86.7 to
94.6 ns against 78.6 to 79.6 ns on AOT. On dart2wasm: 141.3 to 145.9 ns against 130.5 to
152.6 ns.

**F5. Searches of the pinned sources, fidelity draft.** `Object.freeze` occurs at
`core.datasetController.js:831` and `:858`, `plugin.tooltip.js:519` and `core.layouts.js:395`.
`resolveNamedOptions` has one caller (`core.datasetController.js:821`). `Object.isFrozen` occurs in
the specs only at `core.datasetController.tests.js:975`, `:997` and `:1018`. No code in `src/`
deletes a key of options. This ADR repeated the searches at v4.5.1 with the same results.

**S1. Upstream probe of the simplicity draft** (`simplicity/probe_upstream.mjs`, output
`simplicity/probe_upstream.out.json`). It runs each of the nine built-in chart types with 1000
points. A platform class gives the mock context. The animations run with a 16 ms timer.
- The counts of the Context table, for the modes `'none'` and default of `chart.update()`.
- The key orders of each type equal the `knownKeys` lists of Chart.js ADR 0018. `$animations` is
  the last key of each type. For the line, `segment` comes before it.
- No run threw a `TypeError` for a write into a frozen object. The runs covered updates, hovers,
  animations and a resize.
- A custom controller that writes into the shared options throws
  `TypeError: Cannot assign to read only property 'radius' of object '#<Object>'`.

**S2. Microbenchmark of the simplicity draft** (`simplicity/bench/bench.dart`, outputs
`simplicity/bench/final_aot_1.txt` to `final_aot_3.txt`). AOT figures, medians of three processes:
- A static resolution: 961.6 ns with `PointOptions`, 950.3 ns with the id table, 980.0 ns with the
  factory Map of a registry.
- A conversion with the constructor of Chart.js ADR 0018: 501.5 ns. A loop over the known keys:
  215.8 ns. The field copy: 12.3 ns.
- Nine `jsGet` reads of a custom element: 78.7 ns for a plain Map, 118.0 ns for the "generic
  subclass" with the base fields.
- The dart2wasm figures of S2 do not state the level. `dart compile wasm` uses -O1 when no level is
  given. This ADR does not use them.

**S3. `Object.freeze` in V8, simplicity draft** (`simplicity/probe_freeze.cjs`, output
`simplicity/probe_freeze.out.json`). Strict mode throws a `TypeError` for a write, also of the same
value, for an added key and for a `delete` of a present key. A `delete` of an absent key returns
true. A class body is strict. `Object.assign({}, frozen)` gives an object that is not frozen.

**J. Probe of the judge** (`judge/bench.dart`, `judge/opts.dart` and `judge/forms.dart`, outputs
`judge/aot_run1.txt`, `judge/aot_run2.txt` and `judge/wasm_run2.txt`). AOT and dart2wasm -O2. Each
form runs 9 rounds. A figure is the median, in ns, AOT run 1 and run 2 / dart2wasm.
- The forms compile (`judge/forms.dart`).
- The class lookup with the allocation:
  - The names lookup costs 23.6 and 24.2 / 28.5 for the point names.
  - The names lookup costs 8.1 and 8.2 / 9.1 for other names.
  - The id table costs 5.4 and 5.5 / 6.9 for `point`, and 5.0 / 5.5 for another id.
  - A plain literal costs 31.8 and 31.9 / 19.9.
- The names lookup gives no typed class for the P6 order (`forNames(P6 order)`).
- Ten `jsGet` reads at a polymorphic site:

| Form | AOT run 1 | AOT run 2 | dart2wasm |
|---|---|---|---|
| plain Map | 75.4 | 75.7 | 138.0 |
| `GenericElementOptions`, one Map | 82.5 | 82.4 | 151.7 |
| `ObjectOptions` of the fidelity draft | 100.9 | 100.9 | 194.0 |
| `GenericElementOptions`, base fields | 131.2 | 132.5 | 223.4 |
| `Map.unmodifiable` | 82.3 | 83.3 | 151.3 |
| `PointOptions` through `jsGet` | 129.1 | 129.5 | 141.9 |

- Over its dart2wasm runs, the judge reports 149 to 152 ns for the one-Map form. It reports 129 to
  138 ns for the plain Map. `judge/wasm_run2.txt` holds the second run.
- The copy of `resolveTargetOptions` for `PointOptions`: the two-source copy costs 152.8 and
  158.2 / 147.5. Clone and cascade cost 47.3 and 49.1 / 39.5. Both give the same keys.
- The bubble copy: the two-source copy costs 100.6 and 96.4 / 92.2. Clone and one write cost 23.7
  and 23.5 / 19.4.
