# Chart.js ADR 0054: The typed internal model

- Status: accepted (2026-10-31). The base step, the five lanes and the close step are on `main`,
  and their full gates and CI passed. The lead accepted it by the maintainer's rule of 2026-10-31: a
  record is accepted when its code passes the tests, and no record waits for a measurement night.
- Date: 2026-10-30
- Supersedes (§17 restates what stays of each one):
  - [Chart.js ADR 0043](0043-options-representation-and-resolver.md) (options representation
    and resolver), whole.
  - [Chart.js ADR 0018](0018-typed-element-options.md) (typed element options), whole.
  - [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) (typed options in the resolver),
    whole.
  - [Chart.js ADR 0017](0017-element-properties.md) §3, §4, §5 and §7 (element properties).
  - [Chart.js ADR 0036](0036-parsed-data.md) §1, §2, §6 and §7 (parsed data).
  - [Chart.js ADR 0038](0038-plugin-modules-class-values-and-interfaces.md) §1 (the plugin object
    form), §3 (the hooks and their upstream parameter counts) and §10 (dispatch by `jsCall`).
  - [Chart.js ADR 0050](0050-public-theme-api.md) (accepted, it does not change): the form of the
    compiled theme in "One scope", the memo of `compileThemeData` and steps 1 and 2 of "Runtime
    switch" (§18).
- Decides the artifacts of [Chart.js ADR 0053](0053-resolver-fast-paths.md) (rejected).
- Related: [Chart.js ADR 0020](0020-registry-and-component-classes.md) (class values),
  [Chart.js ADR 0025](0025-scale-value-parameters.md) (`Object?` value methods),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0045](0045-reference-engine-arm64.md) (the reference engine, numbers are
  `double`), [Chart.js ADR 0052](0052-typed-public-api.md) (proposed: the lane L5 edits it in
  place, §16), [Chart.js ADR 0028](0028-controller-interfaces.md) §1 (no element module in a
  controller), [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) §10.10, §13.6, §13.7 and §14.9.

## Context

### The decision of the maintainer

On 2026-10-30 the maintainer rejected the memo and fast-path layers of Chart.js ADR 0053 over the
Map-based option model: "remove all your memo shit, every fucking shit should be typed". The rule
of the maintainer for the new model: "We need to use all possible NATIVE features to speedup,
using shit on top of shit is bullshit." The release of 0.1.0 waits for the typed internal model
and for the typed public API of Chart.js ADR 0052.

### The cost of the Map model

- The option resolution is 84 % of the scriptable update of `chart.c` at N 5000 on the Pixel 8a
  (performance.md §10.10). The port is a median 1.93 times Chart.js in the same browser over 100
  cells (performance.md §14.9, P3).
- The resolver emulates the `Proxy` objects of upstream with `Map` subclasses, the JS objects with
  `Map<String, Object?>`, and each property read with a hash lookup by a `String` key
  (Chart.js ADR 0043). The elements write their properties by name (Chart.js ADR 0017 §5). The
  parsed items are Maps (Chart.js ADR 0036). The plugins are Maps of functions, called through
  `jsCall` (Chart.js ADR 0038).

### What does not change

- The behavior is exactly Chart.js v4.6.1 (Chart.js ADR 0034): the rendered chart, the ticks, the
  hit element, the resolved option values, the order of the user calls and the throws. The proof
  is the existing suites with unchanged expectations: `test:cases` (1036 spec cases),
  `test:fixtures` (667 fixtures), the reference tests of `test/port/**` and the resolver trace D2.
- The controllers, scales, elements, helpers and plugins keep their upstream algorithms. Their code
  reads typed options and typed data in place of Maps.
- `lib/` imports no `material`, `cupertino`, `material_ui` or `forui`. No JS at run time. Every
  Flutter platform and web WebAssembly.
- `ChartView`, `ChartTheme`/`ChartThemeData`, the keyboard, the semantics and the reduced motion
  keep their public behavior (Chart.js ADRs 0049, 0050 and 0051).

## Decision

### 1. The option cell and the three states

- `sealed class Opt<T>` (`lib/src/options/opt.dart`) holds one option value of a scope. Its final
  cases are `OptValue<T>` (a value of the type of the key), `OptFunction<T>` (the original
  function value and a typed invoker that its run-time type selects once: `(ctx, opts)`, `(ctx)`,
  `()`, else `jsCall`), `OptList<T>` (the List as given), `OptScope<T>` (a nested typed scope or a
  raw Map), `OptUndefined` (`const optUndefined`), `OptNull` (`const optNull`) and `OptForeign<T>`
  (any other JS value, kept as given).
- A field of the type `Opt<T>?` is Dart `null` for an absent key. The three JS states of a key stay
  apart: an absent key (Dart `null` field), an own key with the value `undefined` (`OptUndefined`)
  and JS `null` (`OptNull`). The `undefined` sentinel of `lib/src/js/js_undefined.dart` stays the
  JS value `undefined` outside the cells. Ported code tests it with `identical(value, undefined)`.
- The walk skips an absent key and `OptUndefined` (U `helpers.config.ts:413`). `mergeIf`, the key
  order and `Object.keys` see an own `undefined`.

### 2. The schema, the generator and the names

- `tool/options_schema.yaml` (hand-written) lists each scope kind of `src/types/index.d.ts` that a
  scope holds, and for each key its JS name, its value union, its descriptor flags, its default,
  its route and, for the element kinds, its defaults order. It also lists the prefix table of the
  four element types, the props key orders of the controllers and the built-in animated property
  names.
- `tool/options_gen.dart` (port-only) reads the schema and writes `lib/src/options/*.g.dart`. The
  generated files are committed and carry the port-only marker. `dart run melos run options:gen`
  writes them. `options:gen:check` fails when the committed output differs from the output of the
  generator.
- The generated parts: `enum OptionKey` (one entry for each distinct option name, with `jsName`)
  and the `switch` `optionKeyOf(String name)`; one final scope class for each scope kind; the
  resolved classes of the element kinds (the facades of the scale and plugin options are
  hand-written, §4 and §12); the descriptor tables;
  the defaults; the props classes and the `AnimatedProp` constants. A name that is not in the
  schema stays a `String` and goes to the `extras` of its scope. No intern table.
- Names: a resolved class or a facade takes the name of its `index.d.ts` interface
  (`PointOptions`, `LegendOptions`, `TickOptions`). A scope class takes that name plus `Scope`
  (`PointOptionsScope`). A port-only kind takes a port-only name. `Plugin` and the hook argument
  classes are exported by `chartjs.dart` and hidden from the app library in 0.1.0, as `Animation`
  and `Element` are.
- The schema drift test (`test/port/options/schema_test.dart`) compares the generated defaults,
  overrides and descriptors with the defaults inventory of `doc/upstream/manifest.json` (values and
  key order). It also maps each path of the key census (O2, §15) to a schema key or to the extras
  allowlist.

### 3. Scopes, defaults, overrides, descriptors and routes

- Each scope class has the fields of its keys, typed setters, `lookup(key)`, `store(key, cell)`,
  `ownKeys` in insertion order, `extras` (an ordered list of the other names and their cells),
  `mergeIf`, `clone` and the face of §5.
- `defaults`, `overrides` and `descriptors` are typed roots (`ChartOptionsScope`,
  `OverridesByTypeScope`, `DescriptorsScope`). They are built at start from the typed cascades of
  the component files, not from generated `const` values: the `Defaults` constructor, the
  `defaults.set` and `defaults.describe` values of `core.animations.defaults`,
  `core.layouts.defaults` and `core.scale.defaults`, and the statics of the components
  (`defaults`, `overrides` and `descriptors` of the controllers, elements, scales and plugins)
  are typed cascades (`PointOptionsScope()..radius = 3.0 ...`) in the upstream order of the
  declaration. Thus a bump that changes a default changes the same Dart file as upstream, and the
  function defaults stay Dart code of their component. `defaultRoutes` stays a table of route
  strings. `registerDefaults` merges typed into typed. A user component with Map statics merges
  its known keys into fields and the other keys into extras. A `merge` into a typed scope makes
  typed children of the kind of each key.
- The schema drift test (`test/port/options/schema_test.dart`) compares the built typed roots,
  with the components registered, with the defaults inventory of `doc/upstream/manifest.json`
  (335 default paths, 29 override paths, 36 descriptor entries): each inventory path has its
  value (a function default compares by its presence), each leaf of the roots is an inventory
  path, each object of the roots is a typed scope, and the keys of each declaration site keep
  their order.
- A descriptor (`_scriptable`, `_indexable`, `_fallback`, `_allKeys`) is a cell of a descriptor
  scope. `ScriptableSpec` and `IndexableSpec` are sealed: a constant, a built-in predicate (an
  `enum` over a `const` table of the keys: the predicates of U `core.defaults.js:166-167`,
  `core.animations.defaults.js:19`, `core.scale.defaults.js:93-103`, `element.line.js:275`,
  `element.arc.ts:399`, `controller.doughnut.js:81-82`, `plugin.legend.js:715-717` and
  `plugin.tooltip.js:1334` are pure functions of the key), or a user function that the walk calls
  with the JS name in the upstream order. `FallbackSpec` is sealed: a key, self (`true`), none
  (`false`) or a user function.
- `defaults.route` of a typed scope is a typed route of the scope (`OptionScope.addRoute`): a
  read of the local cell that gives `undefined` reads the target cell at each access; a local
  object merges over the target object (U `core.defaults.js:130-157`). A scope object or a
  target scope object of a route that is a raw Map node (a user object in the defaults) becomes a
  typed scope with the same keys, values and key order in the place of the Map in the object that
  owns it (the close step, §19; row `adapt-defaults-route`). `RoutedScope` is gone.
- A change of `Chart.defaults` reaches a chart at its next `update()`: `config.update()` drops the
  scope lists and the resolvers (U `core.config.js:197-206`). The scale options copy the defaults
  at the first init of a scale, as `mergeScaleConfig` does upstream (U `core.config.js:71-113`).

### 4. The resolution at the mapped paths, and the cache rule

- `helpers.config.dart` keeps its header and ports `_createResolver`, `_attachContext`,
  `_resolveWithContext`, `_resolveScriptable`, `_resolveArray`, `_resolveWithPrefixes`,
  `_resolveFallback`, `createSubResolver`, `addScopes`, `addScopesFromKey`, `subGetTarget`,
  `_resolve` and `_getKeysFromAllScopes` function by function, in typed form. A scope list is a
  `List<Object>` of typed scopes and raw Maps, deduplicated by identity (the JS `Set`).
- `OptionResolver` (the target of `_createResolver`) holds the scope list, the prefix set, the
  root scopes, the fallback, the target getter and typed `_cached` slots. `OptionView` (the target
  of `_attachContext`) holds the resolver, the context, the sub view and its own slots. Both carry
  the `JsProxyObject` marker that the resolver trace D2 reads.
- `core.config.dart` ports `getOptionScopes`, `chartOptionScopes`, `createResolver`,
  `getResolver`, `resolveNamedOptions` and `needContext` in typed form.
- The element step (`_resolveElementOptions` with `resolveNamedOptions`, U
  `core.datasetController.js:804-835`, `core.config.js:351-367`) is one typed function,
  `Config.resolveElementNamedOptions`, for the four element types and for a custom element type.
  It reads the own keys of the typed scope `defaults.elements.<type>` at each call (an
  `OptionKey`, or the name of an extra), applies `needContext`, reads each key with the typed read
  `readKey` of the resolver or of the view, and stores it into the typed field of the resolved
  class of the type (`ElementOptions.storeKey`, §9). The sub view (the second argument of a
  scriptable option) is the one of upstream: `createResolver(scopes, context, subPrefixes)` before
  the first read. A sub view that comes at the first user call of the element is Open 3.
- The animation options (`_resolveAnimations`), the chart, scale and plugin options are typed
  views. `setContext` for each tick makes a new view, as upstream. The plugin options keep
  `{scriptable: false, indexable: false, allKeys: true}` (U `core.plugins.js:175-187`).
- The facades of the scale options are hand-written, not generated (lane L2): extension types with
  the `index.d.ts` names over the `OptionView` of a scale, in the port-only
  `lib/src/core/scale_options.dart` (a pure layer through `core.ticks`). `Scale.options` is a
  `CoreScaleOptions`, and each scale class narrows it to the facade of its type. A getter is the
  typed read `readKey` of its `OptionKey` and gives the raw JS value: the readers keep their JS
  operators. A nested facade (`TickOptions`, `FontSpecOptions`, ...) holds any JS value and reads
  with `readOption`. The other lanes read the scale options through them.
- The cache rule: the only caches are the caches of upstream, as typed fields: `_scopeCache`,
  `_resolverCache`, the key lists, the `_cached` slots of each resolver and view,
  `_cachedDataOpts`, `_sharedOptions`, `_cachedMeta`, the plugin descriptor cache, the scale
  caches and the `WeakMap` of the subtitle. No memo or cache of our own. The bar index memo, the
  animations memo of Chart.js ADR 0053 and the theme compile memos are not allowed. The two theme
  memos are gone (lane L5): `compileThemeData` compiles at each call, and the theme switch of
  `ChartView` keeps the compiled scope of its current theme (§18).
- No second (generic) resolver stays. During the migration, the Map resolver of Chart.js ADR 0043
  was the frozen file `test/support/legacy/helpers_config_map.dart`, the reference of O3 (§15).
  The close step deleted it (§19).

### 5. The raw boundary and the face

- `RawScope` is an extension type over `Map<String, Object?>` (zero cost). Its `lookup(key)`
  classifies `map[key.jsName]` when the Map owns the key. The walk reads a raw scope once for each
  key, resolver and update, at the upstream time (the upstream `_cached`), never for each element.
  An eager mirror of the user Map is not exact: the colors plugin writes the dataset colors in
  `beforeLayout`, after `configure()` reads the dataset (U `core.controller.js:478-521`,
  `plugin.colors.ts:102`).
- The objects of the user stay the objects of the user: the root config, `data`, the dataset Maps,
  the inline plugin Maps and the data items. The writes of the port into them stay writes by name,
  as upstream: `initConfig`, the colors plugin, the decimation plugin, `platform.basic`,
  `scale.time`, the position write of `core.controller` and the theme switch.
- `options.scales[id]` becomes a typed `ScaleOptionsScope`: `mergeScaleConfig` makes new objects
  upstream (`mergeIf` clones).
- `abstract interface class JsObjectFace` (`lib/src/js/js_object.dart`): `operator []`,
  `operator []=`, `jsKeys` (the own-key order), `jsHas` and `jsDelete`. The scope classes, the
  resolved classes, the views, the contexts, the props, the parsed items, the plugins and the hook
  arguments implement it. `jsGet`, `jsGetKey`, `jsObjectKeys`, `jsOwnPropertyNames`, `isObject`,
  `merge`, `mergeIf` and `clone` take it. The face is the cold API for user code, the raw boundary
  and the tests. It is never in a hot path.
- `isObject` is true for a raw Map and for a typed scope (the leaf rule of Chart.js ADR 0043 in its
  new form).
- During the migration the same objects also extended `MapBase` (scaffolding). The close step
  removed it (§19): no class of `lib/src` outside `lib/src/js/` is a `Map`, and `operator []` and
  `operator []=` of each face are `jsRead` and `jsWrite`, with the JS rules (`undefined` for an
  absent key). `JsProxyObject` (the resolvers) is a face with `ownKeys` (the `ownKeys` trap) and
  `hasProperty` (the `has` trap). The structural rule of `check:typed-reads` (§15) fails if a Map
  supertype comes back.

- The boundary after B6: the config of the user (`config`, `config.data`, `config.options` and
  the dataset objects) stays raw: the Maps of the user, read through `RawScope` and `jsGet`, with
  their identity (`chart.config.data` is the object of the user). `ChartView.raw` gives the chart
  the root Map of Chart.js ADR 0049 §4, a raw scope. `mergeScaleConfig` writes a typed
  `ScaleOptionsByIdScope` of `ScaleOptionsScope`s into `options.scales`, as upstream writes a new
  object there. `chart.options`, the scale options and the plugin options are typed views
  (`OptionView`) with the face. The lowering of Chart.js ADR 0052 gives raw Maps until L5.

- The boundary after L5: the chart root is a typed `ChartConfigurationScope` for both entries of
  `ChartView` (the lowering root of a typed config, and the top-level values of the app Map of
  `ChartView.raw`). The `data` and `options` of `ChartView.raw` stay the Maps of the app, with
  their identity. The close step made `Config._initConfig`, `_themeOf` and the `isObject` paths
  take a typed root, data and options with no Map scaffolding (§19).

### 6. Values outside the type of a key

- A resolved field has the type of the `index.d.ts` union of its key (`double`, an `enum`, a sealed
  union, `Paint`). A foreign value stores its JS conversion in the field (`ToNumber` for a
  `double`) and its raw value in the foreign slot of the object (one `int` mask and a
  `List<Object?>?`, Dart `null` in the common case).
- A reader that applies a kind-sensitive JS operator (`jsAdd`, `jsOrZero`, the truthiness,
  `isNumber`, `typeof`, a string compare) reads the raw value when the foreign bit is set
  (`isForeign(key)`, `foreignOf(key)`).
- The face gives the raw value: the foreign value when the bit is set, else the field.
- The audit O2 (§15) lists each foreign (key, kind) pair of the suites.

### 7. The typed public API

- Two trees. `ChartConfig` stays `const`, `@immutable` and `==` (Chart.js ADR 0052). The lowering
  of a changed config writes the mutable typed scope classes: `Color` through `colorToRgba` into
  `Paint`, `TextStyle` through `fontSpecOf` into a `FontSpecScope`, `Duration` into milliseconds,
  `EdgeInsets` into a `PaddingScope`, a name type into its value, an `xFor` into an `OptFunction`
  with a 1-argument invoker, the callbacks into trampolines. `extra` classifies into cells and wins
  over a typed key.
- The reconcile keeps the live typed dataset scope (the meta link compares its identity, U
  `core.controller.js:829-853`).
- `DataPoint` is a `final class` that implements `TypedDataItem` (`lib/src/types/`), with
  `Object x` (`double`, `DateTime` or `String`), `double? y` (Dart `null` is JS `null`) and
  `double? r` (Dart `null` is an absent `r`). The parse functions read its fields when the parsing
  key is the default key, else by name.
- `ChartConfig.plugins` stays `List<Map<String, Object?>>?` in 0.1.0 (user Maps through
  `MapPlugin`, §12).
- As built (lane L5): the lowering root is a `ChartConfigurationScope` with a `ChartDataScope` and
  a `ChartOptionsScope`. Each dataset gets the dataset scope of its controller, each axis a
  `ScaleOptionsScope`, and the groups typed scopes. `put(scope, OptionKey, value)` stores the
  cell of the shape of the key; a Map value becomes a typed child scope. `mergeExtra` merges
  `extra` into cells and child scopes (Lists by reference); `extra` still wins over a typed key.
  The reconcile patches the live dataset scope against a shallow copy of the cells of the last
  lowering. `DataPoint` is frozen: a write by name throws a `TypeError`, as for a frozen object.
- A `TypedDataItem` that is not a Map, as the object `data` of a dataset, converts through its
  face (`jsKeys` and `jsRead` in `_convertObjectDataToArray`, lane L1), like upstream object data.
  Nothing throws.

### 8. Parsed items

- `ParsedItem` (`lib/src/options/parsed.dart`, a pure layer) is one object for each parsed item,
  as upstream: `getParsed(index)` gives the same object each time (U
  `core.datasetController.js:579-580`), and a scriptable option can write into `ctx.parsed`.
- The axis fields `x`, `y` and `r` are `Object?`: the type of a parse result is `unknown` upstream
  (U `src/types/index.d.ts:1385`), and the box of `parse` goes to `getPixelForValue(Object?)` with
  no new box (Chart.js ADR 0025). An absent `r` reads as `undefined`.
- `custom` (`_custom`: a number for bubble, a typed `FloatingBar` for a floating bar), `stacks`
  (`ItemStacks`, the typed `_stacks`), the key order and an `extras` list for a key that user code
  writes. The hot read is `item.valueOf(AxisKey axis)` with `enum AxisKey { x, y, r, other }`.
- An item of another class (the user data of `parsing: false`) reads with `jsGetKey`.
- `StackEntry` (the object of `getOrCreateStack`) has typed `datasetValues` by dataset index
  (`IndexValues`: the canonical index names first in ascending order), `top`, `bottom` and
  `visualValues`. `ItemStacks` (the `_stacks` of an item) has the stack objects of `x`, `y` and `r`
  as fields and another axis as an extra. `FloatingBar` is the `_custom` of a floating bar.
- The records of parsed data, of the properties and of the hook arguments extend `TypedRecord`
  (`lib/src/options/typed_record.dart`): typed fields by slot, a present bit and a foreign slot for
  each field, extras, the own-key order (up to 7 keys in 4-bit groups of one `int`, also on the
  web, then a list), the face and, during the migration, the Map scaffolding.
- The private objects (`_stacks`, the stack objects, the `_custom` of a floating bar) keep a
  value of another type that user code wrote into them; such a value reads through the face (lane
  L1).
- `_cachedDataOpts` is two typed Maps with the upstream keys, one for the element options and one
  for the animations. A user element type with the id `animation` and a mode equal to a
  transition name thus does not collide with an animation cache key, where upstream collides in
  its one cache object (a named difference of the row `adapt-typed-parsed`).
- Doughnut and pie keep `_parsed` as the upstream number List.
- A `Float64List` is allowed only for an internal array of numbers that no user code reaches.
  `Float64List` columns of parsed items are rejected: they cannot keep the identity of an item or
  a write of another key.
- The 3-read form of the line and scatter loops (Chart.js ADR 0036 §8) stays.

### 9. Elements and props

- Each numeric property of an element is a `double` field (NaN in the `undefined` state) and a bit
  of `int _undefined`. The typed getter gives the field. The typed setter stores and clears the
  bit. The face gives `undefined` for a set bit. A `double?` store boxes; it is not used.
- `$context` is a typed member of `Element`: a `ContextObject?` with a `covariant` setter. The
  four element classes narrow it to `ScriptableContext?`, and `Scale` to
  `ScriptableScaleContext?`. The face keeps any value; the typed getter gives Dart `null` for a
  value of another type. `getContext` of the dataset controller reads and writes the typed
  member: a value that it does not give, which only user code can write, reads as absent, and a
  new data context takes its place (row `adapt-typed-contexts`).
- `PointProperties`, `BarProperties`, `ArcProperties` and `LineProperties`
  (`lib/src/options/props.dart`: the fields and the key orders of the upstream literals) replace
  the property Map literals of the controllers. The names end in `Properties`, the name of the
  upstream variable, because `PointProps` (U `element.point.ts:18`) and `ArcProps` (U
  `element.arc.ts:365`) are the property types of the element classes and keep their ports.
  `Element.assign(props)` uses the typed setters only for an element of the exact built-in class:
  `Element.typedWrites` is true for the class `PointElement`, `BarElement`, `ArcElement` or
  `LineElement` itself, not for a user subclass. A user element class gets the writes by name, in
  the same key order.
- The direct writes of the line and scatter controllers and the line writes of line, scatter and
  radar test `typedWrites` too. They write through the port-only interfaces
  `types.PointElementWrites` and `types.LineElementWrites` of `lib/src/types/`, which the concrete
  point and line classes implement: the controllers import no element module, and Chart.js ADR
  0028 §1 stays. Each write reaches the element at once, as upstream. `_setStyle` keeps a one-key
  Map `{options}`, because the element can be of any class.
- The typed property API of the elements: the typed setters of today (`set x(double)` and the
  others), `Element.markUndefined(AnimatedProp)` and `Element.isUndefined(AnimatedProp)`. L3
  changes the storage; the signatures stay.
- `getProps` keeps its upstream signature for user code. Ported callers use typed forms that give
  the fields or the `to` of the running animations: the methods `Element.finalNumber` and
  `Element.finalValue`, not a result class. `Element.numberOf` gives the typed current number of a
  property of an element of any class (the angles of `core.interaction`), as
  `Element.writeNumber` writes it: the typed getters of the built-in class, else the read by
  name.

### 10. Animations

- `AnimatedProp` (`name`, `id`, `lib/src/options/animated_prop.dart`) has `const` instances for
  the 22 built-in names (U `core.animations.defaults.js:1-2` and its transitions, and the
  `properties` of the controllers and of the tooltip). A name from a raw `properties` list maps
  through the `switch` of `AnimatedProp.of`. An unknown name gets
  `AnimatedProp.custom(name)` and the path by name.
- Each target class (an element, resolved options) reads and writes a key with a `switch` on `id`,
  and the face for an id that it does not declare.
- `Animations` keeps its properties in a table by key id and a small list for custom keys.
  `configure` keeps the rule of U `core.animations.js:31-35`. `_createAnimations` walks the props
  key order from the last key (U `:76`).
- As built (lane L3), three parts of the plan did not hold:
  1. No `Animation` subclasses by interpolator. `update()` can change the value kinds of a
     running animation (U `core.animation.js:51-65`), so a fixed subclass cannot follow.
     `Animation.typed` keeps the number path in two `double` fields, and the number path writes an
     element through `Element.writeNumber`.
  2. `$animations` stays a `Map<String, Animation>`: the specs, O1 and
     `test/support/jasmine.dart` read it as a plain Map in key order, and `Element.$animations`
     is a public member. The close step keeps it (Open 4).
  3. No easing `enum`: a user can replace a built-in easing in the mutable `effects` Map, so each
     name reads the Map.

### 11. Contexts

- Final classes with the `index.d.ts` names: `ScriptableChartContext`, `ScriptableContext` (the
  dataset and the data contexts), `ScriptableScaleContext`, `ScriptableScalePointLabelContext`,
  `ScriptableTooltipContext` and `ScriptableLineSegmentContext`. They extend `ContextObject`, the
  base class of `createContext` (`lib/src/helpers/helpers.options.dart`), which also stays the
  class of a context of another `type`. `createContext` gives the class of the `type` of its
  object literal. The classes are internal: `lib/helpers.dart` exports `ContextObject` only.
- Each member of the literal is a typed field with a getter that reads the parent when the
  context does not own the member. A child reads the members of its parent through `prototype`
  (the prototype chain of `createContext`). A write by name of another key goes to its own extras
  and shadows the parent. The own-key order is the insertion order (the order of the upstream
  object literal); `Object.keys` gives the array-index keys first. The face (§5) has JS rules.

### 12. Plugins

- `final class Plugin` (`lib/src/types/plugin.dart`, the name of `index.d.ts:856`): `id`,
  `defaults` (a typed scope), `descriptors`, `additionalOptionScopes`, and one nullable typed
  function field for each hook of the `Plugin` interface, with typed argument classes. A hook is a
  property that code reads and writes at run time (U `test/specs/core.plugin.tests.js:3-16`): the
  field is that property. The face reads and writes the hook fields by name.
- `PluginService._notify` takes `enum PluginHook`, reads the field, calls it with
  `(chart, args, options)` and stops on `false` for a cancelable hook (U `core.plugins.js:59-71`).
  The public `chart.notifyPlugins(String hook, Object? args)` maps a built-in name to the enum and
  passes any other name by name. `args` passes through (identity). `Plugin.hookValue(hook)` gives
  the field value; `Plugin.invokeHook` calls a function of the type of the hook
  (`PluginHookFunction<A>` of its argument class) with typed arguments and another function with
  JS arity, `this` the plugin. The public `notifyPlugins` gives the args object of the caller to
  each hook by identity: a Map plugin and a hook function of user code get it unchanged, also for
  a built-in hook name. Only a hook function that is typed for the argument class of its hook (a
  built-in plugin after L4) throws a `TypeError` for an args object of another class.
- The argument classes are `PluginHookArgs` (`{}`), `UpdateHookArgs`, `CancelableHookArgs`,
  `ResizeHookArgs`, `DatasetUpdateHookArgs`, `DatasetDrawHookArgs`, `EventHookArgs` and
  `TooltipDrawHookArgs`, with the keys of the upstream literals in their order. `Plugin` stays
  internal (no public library exports it) until the typed public plugin API (Open 2).
- The seven built-in plugins are `Plugin` instances whose fields hold the private top-level hook
  functions in the upstream key order. Their options are typed facades: hand-written extension
  types in the port-only pure `lib/src/plugins/plugin_options.dart` that read one `OptionKey`
  through `readOption`, not generated. The legend items, the hit boxes and the tooltip items are
  typed classes with extras and the face. They implement the port-only interfaces
  `types.TypedLegendItem`, `types.TypedLegendHitBox` and `types.TypedTooltipItem`, through which
  the views of the typed API and the keyboard of `ChartView` read them with no import of a plugin
  (Chart.js ADR 0052 §8). `Tooltip.positioners` stays a dictionary by name (user positioners).
- A built-in hook is a function of the hook type `(chart, args, options)`. This supersedes Chart.js
  ADR 0038 §3 (the upstream parameter count of each hook): the `length` of a hook function is no
  behavior of Chart.js. The plugin service calls each hook with three arguments, and no upstream
  code reads the `length` of a hook. The dispatch reference test
  (`test/port/plugins/index_test.dart`) compares the hook keys as typed hook functions, and keeps
  the upstream counts of the reference only for the args that its recording closures record. A
  built-in hook that reads no args takes any args object. The `afterEvent` hooks of the legend and
  of the tooltip take `EventHookArgs`, and the `beforeDatasetDraw` of the filler takes
  `DatasetDrawHookArgs`: `notifyPlugins` with a Map args object throws a `TypeError` in these three
  hooks, where upstream reads the Map (row `adapt-typed-plugins`).
- `MapPlugin`, an extension type over the Map, adapts a user Map plugin (inline or registered).
  It reads `map[hook]` at each notify and calls it with `jsCall` (any arity, `this` is the Map), as
  upstream. A user Map plugin's
  `defaults` is a raw scope copy (U `core.typedRegistry.js:86-90`).

### 13. Rule 2 for the typed layers

AGENTS.md gets this text (the close step):

"Rule 2 for the typed layers (Chart.js ADR 0054). A file that ports an upstream module keeps its
mapped path, its line-1 header and the upstream function names and order, also in the config,
resolver and data layers. The data representation of these layers is typed: option scopes,
resolved options, parsed items, element properties, animation keys, contexts and plugin objects
are Dart classes, not emulations of JS objects. A ported file with a typed representation carries
one file marker `// DIVERGES(chartjs): <row id>, the typed representation of Chart.js ADR 0054`
after its header. The files of `lib/src/options/` are port-only; the generated ones come from
`tool/options_schema.yaml` through `tool/options_gen.dart`."

The rows of `differences.md`: `adapt-typed-options` (config, resolver, defaults),
`adapt-typed-parsed`, `adapt-typed-elements` (elements, props, animations), `adapt-typed-plugins`
and `adapt-typed-contexts`.

### 14. The upstream bump process for the typed layers

1. Read the bump diff of `src/helpers/helpers.config.ts`, `src/core/core.config.js`,
   `src/core/core.defaults.js`, `src/core/core.animations*.js`, `src/core/core.plugins.js`, the
   option, parse and stack parts of `src/core/core.datasetController.js`, the statics of each
   component and `src/types/index.d.ts`.
2. Algorithm hunks: replay them into the typed function of the same name at the mapped path.
3. Keys and defaults: run `upstream:manifest` (tool 4). Edit `tool/options_schema.yaml` for a new
   key or kind and run `options:gen`. Edit the typed cascade of the component file for a new or
   changed default value or order (the same file as upstream). The schema drift test fails until
   both equal the new inventory (the keys of the schema, and the values and the key order of the
   built typed roots).
4. Generate D2 and the other reference data again on the reference engine (Chart.js ADR 0045).
5. Run O2: each new foreign (key, kind) pair gets a review of its readers.
6. Run every suite. Write the O1 digests again only after the reviewed behavior diff of the bump
   (`tool/observation_diff.sh`).
7. Do the other steps of rule 6.

### 15. The checks and the oracles

- O1, the observation digests (`test/port/options/observation_test.dart`). 727 configs: the 147
  hand fixtures, the 517 pure data fixtures of `doc/upstream/fixtures.json`, the benchmark and
  focused configs of D1, and the D2 configs, each run twice (as given and with a recorder of each
  user function). The canonical text has JS kinds only: an object as `{k: v}` in `jsObjectKeys`
  order, a number through `jsNumberToString`, no Dart class name of an option object, no `int`
  marker, a function as `<fn>`. It holds the resolved options of each element, the element
  properties, `getProps`, the contexts, the animations, the active-mode options, the active
  elements, the draw calls and the ordered user calls. The test compares the SHA-256 of each text
  on macOS. The digests were made on the Map model (B0). O1 stays after the close step as a
  permanent regression oracle; a bump writes it again after the reviewed diff.
- O2, the foreign-value audit. B0 records the key census of the raw configs on the Map model
  (`test/port/options/key_census_*.tsv`). From B4 on, a debug-only hook (`foreignAudit` of
  `lib/src/options/foreign_audit.dart`, called inside `assert`) gets each (owner, key, kind) of a
  value that lands in a foreign slot: the owner is the Dart name of the scope class or of the
  resolved options class, the kind is the JS kind of the value. `test/flutter_test_config.dart`
  collects the pairs of each test file of the suites and fails the file on a pair that the reviewed
  set does not list. The reviewed set is `reviewedForeignPairs` of
  `test/port/options/foreign_audit.dart`, one TSV line for each pair. It is a Dart file, because the
  test config also runs in Chrome without `dart:io`. A new pair fails until its lane reviews the
  readers of that key and adds the pair. `--dart-define=O2_COLLECT=true` prints the pairs.
- O3, the legacy resolver against the typed resolver (the test `(O3)` of each case of
  `test/port/options/observation_test.dart`, B4 to the close step; the close step removed it with
  the legacy resolver, §19). It shares the corpus of O1. It
  builds the chart of each case twice, once for each implementation, because a walk can write
  empty objects into the first scope (`subGetTarget`). It makes the resolvers of the chart options,
  of each dataset, its animations, its dataset and data element options in the modes `default`
  and `active`, and of each registered plugin from the scope lists of the chart config, and their
  views with the context of the chart code. It writes the keys of `Object.getOwnPropertyNames` (a
  mark for each key that `Object.keys` leaves out) with their values to a depth of 4, and the user
  calls. The two texts are equal. The scale options are in the tree of the chart options, under
  the chart context.
- D2, the resolver trace of Chart.js ADR 0053 against Node.js, stays, with 11 new cases (B0).
- Tool 9, `check:typed-reads` (`tool/check_typed_reads.dart`, in `check:port`): the counts of the
  by-name forms in each file of `lib/src` outside `lib/src/js/` and `lib/src/options/` must not
  grow above the baselines of `tool/typed_reads/` (one file for each source file). Since the close
  step each baseline is an allowlist entry: its `#` lines give the reason of each by-name form
  that stays, and `--update` keeps them. The structural rule (no `Map` supertype on a class, a
  mixin or an extension type of `lib/src` outside `lib/src/js/`, also of `lib/src/options/`)
  fails if the scaffolding comes back; it has no baseline.
- `options:gen:check` (B1).

### 16. The steps, the ownership and the night

- The close step removed the scaffolding (§19): `MapBase` of the typed classes (now
  `operator []` and `operator []=` of each face are `jsRead` and `jsWrite` with the JS rules),
  the legacy Map resolver and O3, `ContextObject` as a Map, `RoutedScope` and the Map protocol of
  the classes of Chart.js ADR 0018.
- The base step (one agent, commits B0-B6, each green with all suites), then five lanes in
  parallel worktrees (L1 controllers and parsed data, L2 scales, L3 elements, props and
  animations, L4 plugins, L5 chart level, raw boundary and the typed public API), then the close
  step (one agent), then one night. Each file has one owner in each phase. A lane that needs a
  change in a file that it does not own sends it to the porting lead, who lands it on `main`.
- L5 edits the proposed Chart.js ADR 0052 in place: §2 (the lowering targets are typed scopes), §3
  (`DataPoint` final class, the reconcile on typed scopes), §6 (views over typed classes), §8 (the
  import allowlist adds `lib/src/options/`), §11 (the lowering test on scope faces) and the
  Consequences. Chart.js ADR 0050 is accepted and does not change: §18 states the part of it that
  this ADR supersedes (the compiled theme is a typed scope; the memo of each instance goes).
- The night rule is the rule of judge-c.md §6.1 (phase 10), written on 2026-10-30 before any run:
  side A is `caf0356`, side B is `main` after the close step; the deciding platforms are macOS AOT
  and the dedicated Chrome with dart2wasm; the cells, the classes (GAIN, REGRESSION, NEUTRAL) and
  the block rules are fixed there. The typed core is the decision of the maintainer. The night
  does not accept or reject it. A REGRESSION of a primary or guard cell blocks 0.1.0 until a fix
  lands and a 6-pair series shows no REGRESSION.

### 17. What stays of the superseded ADRs

- Chart.js ADR 0043: the three states, the `undefined` sentinel, the `identical` test, "values
  outside scopes", raw configs in 0.1.0 (beside the typed configs), the leaf rule (now: `isObject`
  is true for a raw Map and a typed scope), and `helpers.merge` into an element.
- Chart.js ADR 0018: nothing. Resolved options are plain typed classes with a face, not Maps.
- Chart.js ADR 0021: §2 (`GenericElementOptions` for a custom element type), §3 (copies), §4 (the
  key order) and §5 (the frozen state), in typed form.
- Chart.js ADR 0017: §1, §2, §6 and §8-§11.
- Chart.js ADR 0036: §3, §4, §5 and §8 (the 3-read form).
- Chart.js ADR 0038: §2, §4-§9 and §11. §8 (the decimation accessor) gains the typed field pair
  for a typed dataset scope. §3 goes whole: the hooks are typed functions with three parameters
  (§12).
- Chart.js ADR 0050: all of it except the form of the compiled theme in "One scope", the memo
  sentence of the `ChartThemeData` bullet and steps 1 and 2 of "Runtime switch", which §18 states
  again.
- Chart.js ADR 0020: no supersession. The statics of a class value hold typed scopes.
- Chart.js ADR 0025: unchanged (`Object?` value methods).
- Chart.js ADR 0053 (rejected): its artifacts are decided here. The switch
  (`lib/src/js/js_fast_paths.dart`), D1 (`test/port/js/js_fast_paths_test.dart`), the melos
  script `test:nofast` and the CI job `test-nofast` are gone (B0). D2, the bench cells and the P3
  page stay.

### 18. The compiled theme (supersedes a part of Chart.js ADR 0050)

Chart.js ADR 0050 is accepted and does not change. These texts replace its parts on the
acceptance of this ADR (lane L5):

- "One scope", first sentence: a theme compiles to one deep-frozen typed scope, a
  `ChartOptionsScope` (the kind of `Chart.defaults`, §3). Each nested object is a frozen typed
  scope of its kind; an object under a key with no kind is a frozen Map; the palette Lists are
  frozen Lists. The rest of "One scope" stays: the raw config carries it under `$theme`, and the
  resolver and the scale merge read it where Chart.js ADR 0050 states.
- The memo sentence of the `ChartThemeData` bullet ("The compiled map of an instance is memoized
  per instance"): `compileThemeData` compiles at each call, with no memo (§4). The theme switch of
  `ChartView` keeps the compiled scope of its current theme and compiles only a new theme. Thus
  the palette list must not change while it is the theme of a chart.
- "Runtime switch", step 1: "it compiles the theme (memo)" becomes "it compiles the theme once and
  keeps the compiled scope".
- "Runtime switch", step 2: the widget writes the compiled scope under `$theme` of its own root
  config, a typed `ChartConfigurationScope` (§5); `data` and `options` keep the identity of the app
  Maps.

### 19. The close step (done 2026-10-31)

- The scaffolding is gone. `OptionScope`, `TypedRecord` (the parsed items, the stack objects, the
  props, the hook arguments, the legend items, hit boxes and tooltip items), `IndexValues`,
  `ElementOptions` and `GenericElementOptions`, `AnimationSpec`, `ContextObject`,
  `OptionResolver`, `OptionView` and `Plugin` implement only `JsObjectFace`. `JsProxyObject` and
  the types `ResolverProxy` and `ContextProxy` are faces, not Maps. The frozen Map of the
  compiled theme (an object under a key with no option kind) is `JsFrozenMap` of the JS runtime
  (`lib/src/js/js_object.dart`), a plain object of the runtime. `RoutedScope` and its
  replacement table are gone (§3). The legacy resolver and O3 are gone (§15).
- The JS runtime takes faces: `jsGet`, `jsGetKey`, `jsObjectKeys` and `jsOwnPropertyNames` (any
  object, also a List and a String), `jsAssign` (any source), and the new `jsIsObjectLike`,
  `jsSet`, `jsHasOwn`, `jsDeleteKey` and `jsObjectOrNull`. `isObject` is true for a Map and a face;
  `clone`, `merge`, `mergeIf`, `each` and the cell classification take faces as objects, as the
  scaffolding gave them. The config boundary (`initConfig`, `initData`, `initOptions`, `_themeOf`,
  `chartThemeOf`) takes the typed root, data and options of a typed config.
- The scale cache `_cache` is the typed `ScaleCache` (`data`, `labels`, `all`, `$bar` as `bar`;
  §4, the caches of upstream as typed fields). `AnimationSpec` has no `MapBase`.
- The public API (accepted by the lead on 2026-10-31; 0.1.0 is not published):
  `chartjs.dart` and the app library export `JsObjectFace`, the by-name face that raw-API code
  uses for a context, the hook arguments, the options and the other typed objects of a chart.
  `Chart.data`, `ChartConfiguration.data` and `ChartConfiguration.options` are `Object` (a Map of
  the user or a typed scope); `Chart.options` is the view (`ContextResolver`); `getContext()` of
  a chart gives a `ContextObject`; `Chart.overrides` is the typed overrides scope; the `Merger`
  typedef and `InteractionModeFunction` take `Object` targets and options; `Defaults.set`, `get`,
  `describe` and `override` return `Object`; `notifyPlugins` takes any args object;
  `Element.options` and the `options` of the props are `Object?`. The harness adds
  `acquireChartRoot` for a typed root.
- The ratchet: `check:typed-reads` has the structural rule (§15), and each baseline that stays
  is an allowlist entry with its reasons. The by-name forms that stay are in these categories:
  the JS runtime (`lib/src/js/`, not counted), the generated faces, `RawScope` and the
  `optionKeyOf` switch (`lib/src/options/`, not counted); the objects of the user (the config,
  the data and the datasets, the data items of `parsing: false`, the component statics and
  plugin objects of user code, a context or an options object of user code, a legend or tooltip
  item of user code) and the writes into them of §5; the generic walk of the resolvers over a
  scope of any kind and the slots of their cache objects (`helpers.config.dart`); the generic
  helpers over any object (`clone`, `merge`, `each`, `Object.assign` of `Element.assign` and
  `copyOptions`, `toFont`); the functions of the user called with JS arity; and the
  dictionaries by name of upstream (`formatters`, the easing `effects`, the tooltip
  `positioners`, the adapter prototype, the UMD statics, the named colors). Totals after the
  close step: jsGet 239, jsGetKey 22, string index 86, jsCall 31, jsObjectKeys 40 and no Map
  supertype (before: 224, 22, 120, 31, 37, 8 `extends MapBase`, 2 `implements Map`). The
  counts of jsGet and jsObjectKeys rose where an uncounted Map index read became a counted face
  read.
- The tests, the harness and the gallery read typed objects through the face or their typed
  members. The observation digests O1 did not change.

## Alternatives considered

- The Map model of Chart.js ADR 0043. Rejected by the maintainer.
- The fast paths and memos of Chart.js ADR 0053. Rejected by the maintainer.
- An eager mirror of the raw config. Not exact: it misses the writes of the colors plugin and of
  user plugins between `configure()` and the element resolution.
- A generic lane (the Map resolver kept for unknown keys). Rejected: the typed walk resolves an
  unknown key through the extras and `RawScope`; a second resolver is a second model.
- `Float64List` columns for the parsed items. Rejected: they fail the D2 case "a scriptable option
  that writes ctx.parsed" and the `_stacks` writes.
- Plugin hooks as methods with a patch table. Rejected: a hook is a property that specs and tests
  replace; a field gives the replace, the delete and the read-back with no second mechanism.
- One class tree for the public API and the internal model. Rejected: the public classes are
  immutable values; the internal scopes take writes.
- A hand-written schema without a generator. Rejected: about 520 key entries, each with a field, a
  lookup arm, a store arm, a key-order entry, a descriptor entry, a default and a face arm: about
  13,000 lines of regular code and seven edits for each new key on a bump.

## Consequences

- The hot paths read typed fields. The by-name surface after the close step is the runtime of
  `lib/src/js/`, `RawScope`, the generated faces, the `optionKeyOf` switch, `MapPlugin`, the reads
  of user data (`resolveObjectKey`, `parsing: false` items), the writes into user objects of §5 and
  the user `route()` and predicate calls.
- The bump of the typed layers is a hand merge from the upstream diff (§14). The algorithm files
  keep their upstream structure.
- Tests read library objects through the face or through typed members. The access forms of tests
  changed at the close step; their expectations did not change, except where a test pinned the
  removed Map behavior (an absent key reads `undefined`, §19).

## Open

1. The release figure (judge-c.md §8 item 1): the typed core alone ends at a P3 median of about
   1.6. The maintainer chose a sixth agent on the native draw path (`lib/src/canvas/**`), with its
   own A/B in the same night.
2. Typed public plugin API, the `parsing: false` group of Chart.js ADR 0052 Open 4, `Paint` from a
   `Color` with no CSS string, `Float64List` doughnut values and typed theme component styles come
   after 0.1.0.
3. The sub view of the element step at the first user call of the element (§4). B4 keeps the
   upstream form. L3 did not measure the lazy form (it lives in the base file `core.config.dart`),
   and the close step did not change it: a timed measurement decides it. The results, the user
   calls and O1 stay.
4. Left by the close step, each because it changes a public member: a typed table of the running
   animations (`Element.$animations` stays a `Map<String, Animation>`), a typed params record of
   `types.LineElement.pathSegment` (the filler and `simpleArc` read `bounds` and the params by
   name), and a typed `cfg` record of `new Scale(cfg)` (the construct of a class value of user
   code gives a Map).

## Evidence

- `.handover/phase10/core-panel/judge-c.md` (the judge of panel C) and the drafts `c-a.md`,
  `c-b.md` and `c-c.md` with their probes.
- performance.md §10.10, §13.6, §13.7 and §14.9.
- The resolver trace D2 (`test/port/core/resolver_trace_test.dart`, 36 cases) and the oracle O1.
