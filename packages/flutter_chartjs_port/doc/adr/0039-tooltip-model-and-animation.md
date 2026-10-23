# Chart.js ADR 0039: Tooltip model and animation

- Status: accepted (2026-10-23)
- Date: 2026-10-22
- Related: [Chart.js ADR 0003](0003-type-only-dependencies.md) (records for inline object types),
  [Chart.js ADR 0043](0043-options-representation-and-resolver.md) (plain objects as Maps, the
  `undefined` sentinel),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (underscore names),
  [Chart.js ADR 0017](0017-element-properties.md) §3, §4, §5, §8 and §9 (typed properties, the
  `undefined` state, the access by name, option reads, returned points),
  [Chart.js ADR 0019](0019-animation.md) §2, §6 and §9 (animation targets, the number path,
  `Object.freeze` of an `Animations`),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §3, §7 and §13 (class values,
  plugins, microbenchmark gains),
  [Chart.js ADR 0021](0021-typed-options-in-the-resolver.md) §5 (the frozen state),
  [Chart.js ADR 0022](0022-chart-test-harness.md) §5 (method fields),
  [Chart.js ADR 0028](0028-controller-interfaces.md) §1 and Open 2 (interface members, the
  `Object? label` of the tooltip item),
  [Chart.js ADR 0032](0032-js-numeric-semantics.md) (`ToNumber`, the reference engine),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0036](0036-parsed-data.md) (`jsAdd`, `jsGetIndex`, `jsLessThan`),
  [Chart.js ADR 0037](0037-legend-and-tooltip-input-path.md) (the input path of the legend and
  the tooltip, proposed in the same step),
  [Chart.js ADR 0038](0038-plugin-modules-class-values-and-interfaces.md) (plugin modules, class
  values and interfaces, proposed in the same step),
  [Chart.js ADR 0041](0041-plugin-test-strategy.md) (the plugin test strategy, proposed in the
  same step),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) §11.7 and §11.8,
  [canvas-cuts-plan.md](../canvas-cuts-plan.md),
  [differences.md](../differences.md) rows `harness-method-fields`, `js-semantics-object-freeze`,
  `adapt-rounded-rect-path`, `adapt-animation-number-path`, `adapt-options-typed-results`,
  `harness-mock-optional-args`, `harness-fixture-sources`, `adapt-component-class-role`,
  `adapt-merge-element-target`, `harness-expected-element` and
  `adapt-active-elements-number-index`

## Context

Phase 8 ports `src/plugins/plugin.tooltip.js` (1350 lines). The file has the class
`Tooltip extends Element`, the positioners, the default callbacks and the plugin object. The
tooltip is the only element of Chart.js that a plugin makes, animates and keeps on the chart.
Its spec file has 32 cases (`test/specs/plugin.tooltip.tests.js`). Eleven cases of other spec
files and 2 fixtures wait for it (`blocked: plugin.tooltip`).

The line numbers of upstream files refer to Chart.js `v4.5.1+7169e651` (`third_party/Chart.js`
at `7169e65147a4`). A line without a file name is a line of `src/plugins/plugin.tooltip.js`.
"The spec" is `test/specs/plugin.tooltip.tests.js`.

The decision answers these questions:
1. The Dart form of the model, its type on `Chart`, and its properties.
2. The form of the plain objects that the tooltip makes: the tooltip items, the body items, the
   label styles and the positions.
3. The positioners, the callbacks and their `this`.
4. `update` as a method that a spec replaces.
5. The animations and `Object.freeze`.
6. The text align cases that call `helpers.merge(tooltip, view)`.
7. The draw: the canvas literals, the RTL helpers, the draw order and the cost.

### Upstream facts

**The class.**
- `class Tooltip extends Element` (:457) has the static `positioners` (:462). The plugin object
  keeps the class in `_element` (:1225) and the same `positioners` object (:1226).
- The constructor (:464-496) sets `opacity = 0`, `_active = []`, `_tooltipItems = []`, `chart`
  and `options` from the config, and 22 other properties to `undefined`. With the 5 properties
  of `Element`, the tooltip has 28 own names. `setActiveElements` (:1127) and `handleEvent`
  (:1140) also write `_ignoreReplayEvents`. Only `true` and `false` reach it.
- `index.d.ts:544` declares `readonly tooltip?: TooltipModel`. `index.d.ts:2648-2699` declares
  `TooltipModel extends Element` with `chart`, `dataPoints`, `xAlign`, `yAlign`, `x`, `y`,
  `width`, `height`, `caretX`, `caretY`, `body`, `beforeBody`, `afterBody`, `title`, `footer`,
  `labelColors`, `labelTextColors`, `labelPointStyles`, `opacity`, `options`,
  `getActiveElements()` and `setActiveElements(active, eventPosition)`. `xAlign` and `yAlign`
  are `TooltipXAlignment` and `TooltipYAlignment` (`:2655-2656`), string unions.
- `index.d.ts:2702` declares `TooltipPosition extends Point` with optional `xAlign` and
  `yAlign`. `index.d.ts:515-518` declares `ActiveDataPoint` with `datasetIndex: number` and
  `index: number`.

**Plain objects.**
- A tooltip item is the literal `{chart, label, parsed, raw, formattedValue, dataset, dataIndex,
  datasetIndex, element}` (:127-143). A body item is `{before, lines, after}` (:559-563). A label
  color is `{borderColor, backgroundColor, borderWidth, borderDash, borderDashOffset,
  borderRadius: 0}` (:404-415). A label point style is `{pointStyle, rotation}` (:419-426).
- `update` copies the position with `Object.assign({}, position, size)` (:661). So does
  `_updateAnimationTarget` (:1017). `determineAlignment` reads `size.yAlign` and `size.xAlign`
  first (:269-276). Thus a positioner can give the alignment.
- The alignment helpers read only `x`, `y`, `width`, `height`, `xAlign` and `yAlign` of this
  object (:222-276, :279-328). They use `x` and `y` in `+=`, `-=`, `<` and `_limitValue`.
- `getBackgroundPoint` returns `{x, y}` (:325-328). `_updateAnimationTarget` gives that object to
  `Animations.update` (:1027).
- `drawPoint` gets the literal `{radius, pointStyle, rotation, borderWidth}` (:800-805).
  `addRoundedRectPath` gets `{x, y, w, h, radius}` (:835-841, :848-854).

**Positioners.**
- `positioners` is one module object with `average` and `nearest` (:17-91). `update`,
  `_updateAnimationTarget` and `_positionChanged` call
  `positioners[options.position].call(this, active, eventPosition)` (:651, :1012, :1218).
- `average` reads `items[i].element`, tests `el && el.hasValue()`, and collects `pos.x` in a
  `Set` (:21-52). `Set.prototype.add` stores +0 for -0. `nearest` reads `eventPosition.x` and
  `.y`, calls `getCenterPoint` and `distanceBetweenPoints`, and keeps the raw event coordinates
  when no element has a value (:57-90).
- The spec adds the key `test` to `tooltipPlugin.positioners` and spies on it (:1045-1088). It
  calls `average` with no `this` and a plain item without `element` (:1148-1155).

**Lines of text and callbacks.**
- `pushOrConcat` pushes each truthy value that is not an array (:94-105). `splitNewlines` splits
  only a string (:113-118). The label lines skip `splitNewlines` (:566). Thus a line can be a
  number or another value.
- `invokeCallbackWithFallback` calls `callbacks[name].call(ctx, arg)` with the tooltip as
  `this`. It calls the default for an `undefined` result only (:447-455).
- 9 of the 14 default callbacks are `noop` (:361-436). `title` and `label` read
  `this && this.options && this.options.mode` (:370, :389). `labelTextColor` reads
  `this.options.bodyColor` without a guard (:417).
- The spec calls the default `label` with a plain item and no `this` (:26, :30).
- `overrideCallbacks` calls `callbacks.override(override)` (:356-359).

**Options and the context.**
- `update`, `_resolveAnimations` and `draw` read `this.options.setContext(this.getContext())`
  (:639, :515, :1041). `getContext` caches `$context` until the next `update` (:528-531, :680).
- In the text align cases, `options` is a plain object with `setContext: () => model.options`
  (spec :1391).

**Animations.**
- `_resolveAnimations` gives `options.enabled && chart.options.animation && options.animations`
  to `new Animations(chart, opts)`. It caches and freezes the object only when
  `opts._cacheable` is truthy (:507-523).
- The animated properties are `x`, `y`, `width`, `height`, `caretX` and `caretY` (type
  `number`), and `opacity` (:1314-1323).
- `_updateAnimationTarget` runs in each draw. When `$animations.x` or `$animations.y` exists, it
  calls the positioner and `getTooltipSize` again (:1006-1030). `animX._to` throws a
  `TypeError` when only `y` animates.

**`update` and events.**
- `update(changed, replay)` (:638-689). `setActiveElements` calls `this.update(true)` (:1128).
  `handleEvent` calls `this.update(true, replay)` (:1167). `external` gets `this` = the tooltip
  and `{chart, tooltip, replay}` (:687).
- The spec replaces `tooltip.update` on one tooltip (:964, :1027) and expects
  `toHaveBeenCalledWith(true, undefined)` (:968, :1031, :1039).
- `core.controller.tests.js:1719` and `:1724` read `tooltip._active[0].element`.

**The plugin.**
- `afterInit` writes `chart.tooltip` only for truthy plugin options (:1228-1232). `beforeUpdate`
  and `reset` call `initialize` (:1234-1244). `afterEvent` calls `handleEvent` and sets
  `args.changed = true` for a change (:1264-1273).
- `afterDraw` notifies `beforeTooltipDraw` with `{...args, cancelable: true}`, draws, and then
  notifies `afterTooltipDraw` with `args` (:1246-1262).

**`helpers.merge` with an element.**
- `isObject` is `Object.prototype.toString.call(value) === '[object Object]'`
  (`helpers.core.ts:53-55`). It is true for an instance of a JavaScript class, also for the
  tooltip. `merge` writes into such a target (`helpers.core.ts:220-233`, `:260-286`).
- The four text align cases (spec :1499, :1525, :1551, :1577) call
  `Chart.helpers.merge(tooltip, makeView(...))` (:1501, :1527, :1553, :1579) on one tooltip that
  `new Tooltip({chart: {getContext, options}})` makes (:1486-1497).
- No upstream module of `src/` calls `merge` or `mergeIf` with a class instance target.

### The port before this decision

- `isObject` of `helpers.core.dart` is true only for a `Map<String, Object?>`. Thus `merge` gives
  an element target back with no write. `jsGet` of an instance of a Dart class gives
  `undefined`. No `differences.md` row records these facts.
- `Element` has the access by name of Chart.js ADR 0017 §5. `Animations.update` writes through
  `writeProperty` and `operator []=` (Chart.js ADR 0019 §2).
- `Chart.setActiveElements` reads a Map item with `jsToNumber(jsGet(item, 'datasetIndex'))` and
  `jsToNumber(jsGet(item, 'index'))`.
- `arrayUnique` of `helpers.collection.dart` ports `[...new Set(items)]`. It gives the list
  itself when all items differ, and a `-0` then stays `-0`.
- The canvas layer caches the text metrics (32768 entries) and the paragraph layouts (512
  entries) in `canvas_ui_text.dart`. The key of a paragraph includes the color with the alpha of
  `globalAlpha` (`canvas_ui.dart`, the `fillText` path).
- `PointOptions` of `element_options.dart` implements `DrawPointOptions`. Its getters apply
  `jsToNumber`.

### Probes

A design panel wrote three drafts (fidelity, performance and simplicity first). A judge scored
them with its own probes. The behavior probes ran the Chart.js build at the pin in the x64
Node.js v24.12.0 under Rosetta (Chart.js ADR 0032). Results that this ADR uses:

| Case | Upstream result |
|---|---|
| `isObject(chart.tooltip)`, of a meta and of the chart | `true` for each |
| `merge(tooltip, view)` twice | the first writes a clone of `view.options` and `view.title`. The second merges into the same `options` object. `setContext` then gives the options of the second view. |
| `Object.assign(tooltip, view)` in place of `merge` in the four text align cases | the same 37 draw calls in each case |
| A title callback that returns `5` | `title: [5]`, a number. The width is the width of `'5'`. |
| A scatter chart with `labels: [7, null]` | `item.label === 7` and `title: [7]`. The label `null` gives `''` and `title: []`. |
| The default `label` in the dataset mode | the label `1` gives `'1: 20'`, `null` gives `'null: 20'` |
| `labelTextColor` without `this` | throws a `TypeError` |
| A callback that returns `undefined`, and one that returns `null` | `undefined` takes the default (title `['b']`, height 46.8). `null` does not (title `[]`, height 12). |
| A user `title` callback that is `Chart.helpers.noop` | title `['B']`: the default runs |
| `options._cacheable` of a chart tooltip | `false`, also on `options.animations`. `_cachedAnimations` stays `undefined`. Each `update` makes a new `Animations`. |
| `$animations` after the end of all animations | still has `x`. Each later draw calls the positioner and measures the lines again. |
| `$animations` keys after one animated update | `caretY, caretX, height, width, y, x, opacity` |
| The hook order with an inline plugin | `afterDatasetsDraw`, `beforeTooltipDraw`, `afterTooltipDraw`, `afterDraw` |
| `plugins.tooltip: false` | no `chart.tooltip`, also after a later enable and `update()` |
| `external` | `this` is the tooltip. `replay` is `undefined` for `setActiveElements` and a `mousemove`, `true` for the replay of `chart.update()`. |
| The calls of `update` | `handleEvent` gives `(true, undefined)`, `setActiveElements` gives `(true)`. After `setActiveElements`, the replay of `chart.update()` does not call `update`. |
| `setActiveElements([{datasetIndex: 0, index: 99}])` on a line chart | throws `TypeError` in `getLabelAndValue`, after `_active` changed |
| A positioner result `{x, y, xAlign: 'right', yAlign: 'bottom'}` | `xAlign 'right'`, `yAlign 'bottom'`, `caretX 100`, `caretY 100` |
| A positioner result `{}` | `x` and `y` NaN, `caretX` and `caretY` `undefined` |
| The options `xAlign: 5` and `yAlign: {o: 1}` | both reach the element, and the draw does not throw |
| A positioner result `{x: '100', y: '50'}` | `y` 26.6 and `yAlign 'center'` on the line chart of 512 x 512; with the option `yAlign: 'top'`, `y` 465.2 (`alignY` joins `'50' + 7`). `caretX` the string `'100'`. No throw. |
| A positioner result `{x: null, y: null}` | no throw; `caretX` and `caretY` `null` (with an animation, after the first tick), `x` 0, `y` 7, `xAlign 'left'`, `yAlign 'top'` |
| `average` with the x values `[NaN, NaN, 2]`, `[0, -0, 4]`, `[-0]` | x NaN, x 2, x +0 |
| `average` with a plain item without `element` | `false` |
| `Tooltip.positioners === tooltipPlugin.positioners` | `true` |
| `setActiveElements([{datasetIndex: 0, index: '1'}])`, then the index `1` | `index` and `dataIndex` stay the string `'1'`. The title is `['B']`. The second call counts as a change and calls `update`. `Chart.setActiveElements` also keeps `'2'`. |

The Dart probes ran in a scratch package that imports the package by path:
- `isObject(Element())` is false, `merge(element, {x: 1})` writes nothing, and
  `jsGet(element, 'x')` gives `undefined`, on AOT and on dart2wasm.
- A copy of `merge` with the branch of section 10 gives the six upstream results of the two
  `merge` calls above.
- `clone` of a list literal and a spec list literal are a `List<Object?>`. Neither is a
  `List<Map<String, Object?>>`, on AOT and on dart2wasm.
- A field `late void Function([Object? changed, Object? replay]) update` on an `Element` subclass
  compiles, and a replacement sees `(true, undefined)` from `handleEvent`.
- `jsGet(contextResolver, 'setContext')` is a function, and `jsCall` of it gives a
  `ContextResolver`. The same call works on a plain Map with a closure `setContext`.

### Benchmarks

Apple M3 Max, macOS 26, Dart 3.13.5. Other sessions ran at the same time (load average 7 to
11). AOT is `dart compile exe`. wasm is `dart compile wasm -O2` in the x64 Node.js v24.12.0.
Each figure is the range of 3 processes, or the median of 15 runs, in the unit of the row.

| Case | AOT | wasm | V8 (upstream) |
|---|---:|---:|---:|
| One draw of options: `setContext` and all option reads of the draw, 1 / 3 / 10 items (µs) | 9.98 / 11.71 / 17.81 | 14.61 / 14.50 / 20.63 | 11.67 / 12.29 / 17.54 |
| A typed snapshot of the draw options, reads per frame, 3 items (µs) | 0.004 | 0.004 | - |
| The same snapshot, make per update (µs) | 6.19-6.47 | 7.53-7.64 | - |
| Upstream whole `update(true)`, 1 / 3 / 10 items (µs) | - | - | 29.28 / 36.06 / 53.72 |
| `Object.assign({}, position, size)` as a Map, and 6 reads (ns) | 134-145 | 179-191 | - |
| The same as a record, and 6 reads (ns) | 3.2-4.3 | 0.8-1.4 | - |
| 13 noop callback pairs of one update with 3 items, upstream form (ns) | 568-590 | 1720-1973 | - |
| The same with the noop test of section 8 (ns) | 180-189 | 400-409 | - |
| `update(true)` as a method / as a field that holds a function (ns) | 0.4-0.5 / 1.8-2.0 | 0.4 / 0.4 | - |
| 7 `Animation.tick` on the typed tooltip / in the extra Map / on a plain Map (ns) | 136-145 / 181-201 / 163-177 | 232-265 / 283-309 / 269-304 | - |
| The state reads of one draw (33 reads), typed / by name on the extra Map (ns) | 36-39 / 442-465 | 45-56 / 655-714 | - |
| `merge` of a 3-level config, without / with the branch of section 10 (µs) | 2.38-2.45 / 2.40-2.46 | 2.98-3.03 / 3.02-3.08 | - |
| The `average` positioner through `jsCall`, 3 items, without / with an `identical` fast path (ns) | 228-243 / 213-225 | 340-375 / 262-314 | - |
| `setContext` through `jsCall(jsGet(...))` / with a `ContextResolver` fast path (ns) | 281-297 / 269-283 | 241-263 / 188-218 | - |

A text probe in `flutter_tester` (JIT, indicative only) drew one title line and n body lines.
With alpha 1, the paragraph cache gives 1.0-5.1 µs for each frame for n = 1 to 10. With a new
alpha in each frame (the fade of the opacity animation), each line builds a new paragraph:
9.9-18.2 µs for each line.

## Decision

### 1. The model class and `chart.tooltip`

- `lib/src/plugins/plugin.tooltip.dart` has `class Tooltip extends Element implements
  types.TooltipModel`, with the rule-2 header of `src/plugins/plugin.tooltip.js`. It is not a
  pure layer: it imports `core.animations.dart`.
- `types.TooltipModel` in `lib/src/types/index.dart` is `abstract interface class TooltipModel
  implements Element` with the members of `index.d.ts:2648-2699` as getters (section 14).
  Chart.js ADR 0038 adds the empty interface and `types.Chart.tooltip`
  (`abstract TooltipModel? tooltip`, `index.d.ts:544`). This ADR gives the members.
- `core.controller.dart` does not import the plugin, as `core.controller.js` does not. The plugin
  hooks read `chart.tooltip` and cast it to `Tooltip`, the class of their own library (Chart.js
  ADR 0028 §1).
- The constructor takes the record config of Chart.js ADR 0038:
  `Tooltip(({types.Chart chart, AnyObject? options}) config)`. It sets the start values in the
  upstream order (:464-496). `Tooltip.jsClass` (Chart.js ADR 0020 §3) has
  `superclass: Element.jsClass` and the static `positioners`. Its `construct` reads the
  argument by name (`_tooltipConfig`), as `new Tooltip(config)` reads `config.chart` and
  `config.options`. A `chart` that is not a `types.Chart` throws a `TypeError` there. Upstream
  stores it. The row `adapt-component-class-role` records this.
- `initialize(AnyObject? options)` is the upstream method (:498-502).

### 2. Properties and the access by name

The rules of Chart.js ADR 0017 §3-§5 apply to each of the 28 own names and to
`_ignoreReplayEvents`. `Element` handles `x`, `y`, `active`, `options` and `$animations`. The
`switch` of `operator []` and `operator []=` of `Tooltip` handles the other 24 names:

| Names | Dart field | Getter | Write by name |
|---|---|---|---|
| `opacity` (start 0), `width`, `height`, `caretX`, `caretY` | `double?` | `double`, NaN for `undefined` | `toNumberProp` |
| `xAlign`, `yAlign` | `String?` | `String?` | `toObjectProp<String>` |
| `title`, `beforeBody`, `body`, `afterBody`, `footer`, `dataPoints`, `labelColors`, `labelPointStyles`, `labelTextColors` | `List<Object?>?` | `List<Object?>?` | `toObjectProp<List<Object?>>` |
| `chart` | `types.Chart` | `types.Chart` | a `types.Chart` only. Another value, also `undefined`, throws an `ArgumentError`. |
| `_active` (start `[]`) | `List<types.ActiveElement>` | none | a `List<types.ActiveElement>` only. Another value, also `undefined`, throws an `ArgumentError`. |
| `_eventPosition` | `Object?` | none | any value |
| `_size` | `({double width, double height})?` | none | the record type or `undefined` |
| `_cachedAnimations` | `Animations?` | none | `toObjectProp<Animations>` |
| `_tooltipItems` (start `[]`) | `List<Object?>` | none | a `List<Object?>` only. Another value, also `undefined`, throws an `ArgumentError`. |
| `$context` | `AnyObject?` | none | `toObjectProp<AnyObject>` |
| `_ignoreReplayEvents` | `bool?` | none | `toBoolProp` |

- The private names keep their upstream spelling, because only `plugin.tooltip.dart` reads them
  in Dart (Chart.js ADR 0017 §3). Other code reads and writes them by name, for example
  `tooltip['_active']`, as `core.controller.tests.js:1719` does. The Dart field of `$context` is
  `_context`, because a Dart name with `$` is public. The access by name keeps `$context`.
- A line of text can be any value (Context). Thus every list is `List<Object?>`. `clone` gives a
  `List<Object?>`, and so does a spec list literal (Probes). A narrower type throws at the writes
  of the text align cases.
- `xAlign` and `yAlign` are `String?`, the type of `index.d.ts:2655-2656`. A value outside this
  contract, for example the option `xAlign: 5`, throws an `ArgumentError` at the write. Upstream
  stores it (Probes). This is the rule of Chart.js ADR 0017 §5, not a `DIVERGES` hunk. The
  direct Dart writes in `update` and `_updateAnimationTarget` go through the same conversion.
  Thus the throw is always the `ArgumentError` of the rule, not a `TypeError` of a cast.
- `x` and `y` take the number path of Chart.js ADR 0019 §6. The other five numbers go through
  `writeProperty` and `operator []=`.

### 3. Plain objects

- A tooltip item, a body item, a label color and a label point style are
  `Map<String, Object?>` literals with the upstream keys in the upstream order. The port reads
  them with `jsGet`, as user code does.
- The item keeps the `Object? label` of `getLabelAndValue` (Chart.js ADR 0028 Open 2). `raw` is
  `jsGetIndex(jsGet(jsGetIndex(jsGet(chart.data, 'datasets'), datasetIndex), 'data'), index)`.
  `element` is the element or `undefined`.
- A value in an item that is a typed port object, for example `item.chart`, is read through its
  `types` interface (Chart.js ADR 0028 §1). A plain value is read with `jsGet`.
- The objects exist once for each `update`, not for each frame. A typed class saves less than
  1 µs of an update that costs 29-54 µs in V8 (Benchmarks).

### 4. The positioners

- One top-level `final AnyObject _positioners` Map holds the function values `average` and
  `nearest`. `Tooltip.positioners`, the static `positioners` of `Tooltip.jsClass` and the key
  `positioners` of the plugin Map are this Map. The methods read the top-level Map, as upstream
  reads the module constant (:651, :1012, :1218).
- The call is `jsCall(jsGet(_positioners, jsGet(options, 'position')), [active,
  eventPosition], thisArg: this)`. An absent key gives `undefined`, and `jsCall` throws an
  `ArgumentError` where upstream throws a `TypeError` at `.call` (the rule of `js_function.dart`).
- `average` and `nearest` are the private top-level functions `_average` and `_nearest`, without
  `this`, because the upstream methods do not read `this`.
- An item is a `types.ActiveElement` or a user value. Its element is `item.element` for a
  `types.ActiveElement`, else `jsGet(item, 'element')`. The plain item of spec :1152 gives
  `undefined` and the result `false`.
- `el.hasValue()` and `el.tooltipPosition()` cast the element to `Element` of
  `core.element.dart` at the call, as Chart.js ADR 0038 decides (`plugin.tooltip.js:2` imports
  `Element`). `el.getCenterPoint()` casts to `types.VisualElement`.
- `average` keeps the semantics of `new Set()`: each x value goes into a list through the add
  step of `Set.prototype.add` (`x == 0 ? 0.0 : x`, so -0 becomes +0), then `arrayUnique`
  removes the copies with SameValueZero. The sum keeps the insertion order. The value reaches
  `caretX`, an element property.
- `nearest` reads `eventPosition.x` and `.y` by name: a `Point` (a `types.ChartEvent`) gives its
  members, another value gives `jsGet`. `distanceBetweenPoints` gets a `Point` with the
  `ToNumber` of each coordinate, the conversion of the upstream subtraction.
- A built-in positioner returns `false` or `<String, Object?>{'x': x, 'y': y}`. A result of
  `nearest` keeps the raw event coordinates when no element has a value (:62-63, :86-89). An
  `ElementPoint` result is not used: `jsGet` of a Dart class instance gives `undefined`, and a
  user positioner that wraps a built-in one reads `.x` of its result.
- The positioner contract is `TooltipPosition` (`index.d.ts:2702`): `x` and `y` are numbers.
  Section 5 states the result of other values.

### 5. The position and size record

- `Object.assign({}, position, size)` (:661, :1017) is the record
  `({double x, double y, double width, double height, Object? xAlign, Object? yAlign})`
  (Chart.js ADR 0003: an inline object type that ported code only reads).
- `x` and `y` are the `ToNumber` of a read by name of the position: the members of a `Point`,
  else `jsGet`. `xAlign` and `yAlign` are the raw values of the same read. Thus `false`,
  `undefined` and a Map without the keys give the values that `Object.assign` gives.
- The upstream readers apply `ToNumber` to `x` and `y` in each operator (:222-276, :279-328).
  Thus a number, `undefined`, `null` and a boolean give the same results with the record. A
  string coordinate is outside the contract. It gives other values (Probes: `y` 26.6, or 465.2
  with the option `yAlign: 'top'`) and an `ArgumentError` at a write of `caretX` or `caretY`
  (next item). This is the rule of Chart.js ADR 0017 §5, not a `DIVERGES` hunk.
- `caretX` and `caretY` take the raw `position.x` and `position.y`, not the record values. Thus
  `undefined` stays `undefined` (:674-675, :1025-1026). A JS `null` coordinate is outside the
  type of `caretX`, by the same rule. Upstream stores `null` (Probes). For a string and for JS
  `null`, the site of the `ArgumentError` depends on the animation:
  - Without an animation, `update` writes the properties at once. The write of `caretX` throws
    after the writes of `opacity`, `x`, `y`, `width` and `height`. Thus `setActiveElements`
    throws.
  - With an animation (the default of a chart), `update` does not throw. The next frame of the
    animator throws in `Animation.tick`. The frame callback then keeps `_request` set
    (`core.animator.js:38-52`), so the animator stops for each chart. The animation of the
    tooltip does not end, and `Chart.destroy` throws again in `Animation.cancel`.

  The port test group `positioners` pins both forms for JS `null`. The test of the animated form
  calls `animator.update` and does not pump a frame.
- `getTooltipSize` returns `({double width, double height})`. `determineAlignment` returns
  `({Object? xAlign, Object? yAlign})`. `getBackgroundPoint` and `getCaretPosition` return
  records too.
- `_updateAnimationTarget` gives `<String, Object?>{'x': point.x, 'y': point.y}` to
  `Animations.update`, because `update` reads the keys of the values object.
- The record saves 130-140 ns (AOT) and 178-190 ns (wasm) for each update and each animated draw
  (Benchmarks). It keeps the upstream statements. Thus it takes the gain of a microbenchmark
  (Chart.js ADR 0020 §13).

### 6. `update` as a method field

- `Tooltip.update` is a field that holds a function, as the row `harness-method-fields` gives
  for `Chart.resize`, `Chart.eventHandler` and `Animator.refresh`:

  ```dart
  // DIVERGES(chartjs): harness-method-fields, a spec replaces it per tooltip.
  late void Function([Object? changed, Object? replay]) update = _updateMethod;

  void _updateMethod([
    Object? changed = undefined,
    Object? replay = undefined,
  ]) {
    // The upstream body of :638-689.
  }
  ```

- Both parameters are optional `Object?`, because upstream reads `changed` only with `&&`
  (:686), passes `replay` unchanged to `external` (:687), and accepts `update()` with no
  argument. `setActiveElements` calls `update(true)` and `handleEvent` calls
  `update(true, replay)` through the field.
- `types.TooltipModel` does not declare `update`, as `index.d.ts` does not.
- The cost is 1.8-2.0 ns (AOT) for each call, one call for each event that changes the tooltip.

### 7. `setContext` and the option reads

- `setContext` is `jsCall(jsGet(options, 'setContext'), [getContext()], thisArg: options)` in
  `update`, `_resolveAnimations` and `draw` (the private helper `_resolveOptions`). One form
  serves the resolver of a chart and the plain Map with a closure of the text align cases. A
  cast to `ContextResolver` throws there.
- The draw reads each option of the result with the Map read `options[key]`. Each reader of a
  key that a plain Map can lack (`rtl`, `usePointStyle`, `external`, `filter`, `itemSort`,
  `xAlign`, `yAlign`) applies `ToBoolean` or `||`. Thus Dart `null` and `undefined` give one
  result (Chart.js ADR 0017 §8). A numeric option in arithmetic goes through `jsToNumber`. A
  value for the canvas goes through `canvasStyle`, `canvasNumber`, `canvasKeyword` or
  `canvasLineDash` of `js_webidl.dart`.
- `draw` reads `textDirection` with `jsGet(options, 'textDirection')`. An absent key of a plain
  Map then gives `undefined`, and `restoreTextDirection` does nothing, as upstream. The Map read
  gives Dart `null`, and `restoreTextDirection` then throws the `TypeError` of `null[0]`.
- `handleEvent`, `_getActiveElements` and `_positionChanged` read `this.options` without
  `setContext` (:1145, :1184, :1217), as upstream.
- A typed snapshot of the draw options is not used. It saves 10-21 µs for each frame, below the
  0.1 ms of Chart.js ADR 0020 §13, and it changes the structure. It also resolves a scriptable
  option once for each update in place of once for each frame. That changes a resolved option.

### 8. Callbacks and their `this`

- `_defaultCallbacks` is a private top-level `AnyObject` with the 14 upstream keys in the
  upstream order (:361-436). `title`, `label` and `labelTextColor` read `this`, so they are
  `JsFunction` values. `labelColor`, `labelPointStyle` and the 9 `noop` entries are Dart
  functions. The plugin `defaults` holds the same Map under `callbacks` (:1324).
- The defaults read `this.options` with one helper. A falsy `this` gives itself, so
  `this && this.options` short-circuits. A `types.ElementPropertyRead` gives `self['options']`.
  Another value gives `jsGet(self, 'options')`. `labelTextColor` then reads
  `jsGet(..., 'bodyColor')`, which throws a `TypeError` without `this`, as upstream.
- The `+` of the dataset mode and of the default `label` is `jsAdd`. `labels[item.dataIndex]`
  is `jsGetIndex` for a number index, else `jsGet`. `item.dataIndex < labelCount` is
  `jsLessThan` (Chart.js ADR 0036).
- `invokeCallbackWithFallback` is the upstream helper with one test first. It drops the
  underscore and has `@visibleForTesting`, because the port test reads it (Chart.js ADR 0012):

  ```dart
  @visibleForTesting
  Object? invokeCallbackWithFallback(
    Object? callbacks,
    String name,
    Object? ctx,
    Object? arg,
  ) {
    final callback = jsGet(callbacks, name);
    final fallback = _defaultCallbacks[name];
    // Both upstream calls call noop: no effect, and the result is undefined.
    if (identical(callback, noop) && identical(fallback, noop)) return undefined;
    final result = jsCall1(callback, arg, thisArg: ctx);

    if (identical(result, undefined)) {
      return jsCall1(fallback, arg, thisArg: ctx);
    }

    return result;
  }
  ```

- The test gives the same result for each input. When both values are `noop`, both upstream
  calls call `noop`, which has no effect and returns `undefined`. A user callback that is
  `Chart.helpers.noop` in a slot whose default is not `noop` still gets the default (Probes:
  title `['B']`). The test keeps the structure (one `if` in the ported helper, the same callers).
  It saves 383-405 ns (AOT) and 1320-1564 ns (wasm) for each update with 3 items. Chart.js ADR
  0020 §13 permits such a gain. No `DIVERGES` marker and no row.
- A Dart closure that must give `undefined` returns the sentinel. A closure that returns Dart
  `null` gives JS `null`, and the default does not run (Probes).
- `overrideCallbacks` calls `jsCall(jsGet(callbacks, 'override'), [override], thisArg:
  callbacks)`. `options.filter` is a `jsCall` with 4 arguments and `thisArg: options` (:615, a
  method call). `options.itemSort` goes through `jsSort` (:620) with the `jsToNumber` of the
  comparator result, and its `jsCall` has `thisArg: options`.
- `splitNewlines` tests `str is String`. `pushOrConcat` tests `jsTruthy` and `isArray`.

### 9. Animations and `Object.freeze`

- `_resolveAnimations` keeps the upstream lines (:507-523). `opts` is the JS `&&` chain of the
  raw values `options['enabled']`, `chart.options['animation']` and `options['animations']`.
  `jsTruthy(jsGet(opts, '_cacheable'))` selects the cache. `jsGet(undefined, ...)` throws the
  `TypeError` of `opts._cacheable`.
- `_cachedAnimations = jsObjectFreeze(animations)` stays. `jsObjectFreeze` of an `Animations`
  changes nothing (Chart.js ADR 0019 §9, Chart.js ADR 0021 §5). For a chart, the options are a
  context resolver with `_cacheable` false, so the line runs only for options that a user gives
  to `initialize` without a context (Probes). The row `js-semantics-object-freeze` gets this
  sentence.
- No port-only cache of the `Animations`. A cache keeps the animation options of the first
  update, where upstream reads them in each update. A scriptable animation option then gives
  another duration or easing.
- `_updateAnimationTarget` reads `$animations?['x']` and `['y']`. `animX._to !== point.x` is
  `animX!.to` with a private strict equality. The `!` throws a `TypeError` when only `y`
  animates, as `animX._to` does.
- `core.animation.dart` and `core.animations.dart` do not change.

### 10. `helpers.merge` with an element target

- `merge` of `helpers.core.dart` treats a `types.PropertyAccess` target as an object target. It
  writes through a private Map view of the target (`_PropertyAccessView`) that has only
  `operator []` and `operator []=`. `merger` also recurses when `tval` is a
  `types.PropertyAccess` and `sval` is an object. `merge` returns the original target, not the
  view.
- `isObject`, `clone` and `mergerIf` do not change. `isObject` runs in each resolver and
  config path, and `clone` would need the keys of an element. `mergeIf` returns a target that
  is not an object at once, before its `merge` call. Without this test, `mergeIf` of an
  element goes into the view, and `mergerIf` calls `containsKey`, which the view cannot
  answer: it throws an `UnsupportedError`. For every other target the result does not
  change, because `merge` returns a target that is not an object at once.
- Each changed hunk carries `// DIVERGES(chartjs): adapt-merge-element-target, ...`. The new row
  `adapt-merge-element-target` records what stays different: `clone` keeps an element as a
  reference where upstream copies its own keys, `mergeIf` does not write into an element target,
  `merge` skips an element source where upstream copies its own keys, an element source value
  replaces the target value, also a Map or an element, where upstream merges its own keys into a
  Map or an element target value, and a custom
  `merger` that enumerates the target throws an `UnsupportedError`. No Chart.js merger
  enumerates its target. The markers are in `merge`, `merger` and `mergeIf`.
- Chart.js ADR 0006 said that a class instance in an options tree stays a leaf. This stays true
  for `clone` and `mergeIf`, and for a class instance as a source or as a source value of
  `merge`. `merge` enters a `types.PropertyAccess` target, and a `types.PropertyAccess` value of
  a Map target when the source value is an object. This section states that exception.
  [Chart.js ADR 0043](0043-options-representation-and-resolver.md) restates Chart.js ADR 0006
  with this exception, and supersedes it.
- Thus the four spec lines stay `merge(tooltip, view)`. `Chart.helpers.merge` is public, and
  upstream writes into any class instance target. The branch closes that difference for each
  element of the port at no cost on the Map path (Benchmarks). The spec result does not depend
  on the deep merge: `Object.assign` gives the same 37 draw calls (Probes).
- The change of `helpers.core.dart`, a shared layer, is its own commit.
- `_isObject` of `packages/chartjs_test_utils/lib/src/matchers.options.dart` is also true for a
  `types.ElementPropertyRead`, and `_compareObject` reads it with `object[key]`. This is the
  upstream `isObject` of chartjs-test-utils `src/matchers.options.js:2-4`, which is true for a
  class instance. Thus no row for an actual element. Spec :1350
  (`expect(tooltip).toEqualOptions(...)`) needs it. An expected element compares with `===`,
  because the port has no list of its own keys. Upstream compares its own keys. The marker
  and the row `harness-expected-element` record it.

### 11. The canvas literals, the RTL helpers and the lines

- `drawPoint` gets a `PointOptions` Map with the four keys of :800-805
  (`{'radius': ..., 'pointStyle': ..., 'rotation': ..., 'borderWidth': 1.0}`).
  `PointOptions` implements `DrawPointOptions` and applies `jsToNumber` in its getters. One object
  for each color box with `usePointStyle`, as upstream.
- `addRoundedRectPath` gets a private `_RoundedRect implements RoundedRect` with the keys of
  :835-841 (Chart.js ADR 0017 §8). The row `adapt-rounded-rect-path` names
  `Tooltip._drawColorBox` as a caller. Each `lib/` caller keeps its own private class for the
  literal: `_Rect` of `element.bar.dart`, and `_RoundedRect` of `scale.radialLinear.dart`,
  `plugin.legend.dart` and `plugin.tooltip.dart` (Open 4).
- `Object.values(borderRadius).some(v => v !== 0)` (:832) reads the four members of the
  `TRBLCorners` of `toTRBLCorners` (row `adapt-options-typed-results`).
  `Math.max(...Object.values(labelColor.borderWidth))` (:822) reads the values of a Map
  `borderWidth` in `jsObjectKeys` order with `jsMax` and `jsToNumber`.
- `pt` of `draw` (:1054-1057) is the public mutable class `TooltipPoint` with `double x` and
  `double y`. It is public because `drawTitle` (:756), `drawBody` (:871), `drawFooter` (:935)
  and `drawBackground` (:961) are public upstream methods and take it (rule 2, Chart.js ADR
  0012; the lint `library_private_types_in_public_api`). `drawTitle`, `drawBody` and
  `drawFooter` change it, as upstream changes the literal.
- The RTL calls are the upstream calls of `helpers.rtl.dart`: `getRtlAdapter(options['rtl'],
  x, width)`, `overrideTextDirection(ctx, jsGet(options, 'textDirection'))` and
  `restoreTextDirection(ctx, jsGet(options, 'textDirection'))` (section 7). Upstream gives the
  option value, not the saved value, to `restoreTextDirection` (:1087). The port keeps it.
- `measureText` and `fillText` get `jsToString(line)`, the WebIDL `DOMString` of a line that is
  not a string.

### 12. Events, `external`, `chart.tooltip` and the draw order

- `afterInit` writes `chart.tooltip = Tooltip((chart: chart, options: options))` only for
  `jsTruthy(options)`. No other hook writes `chart.tooltip`. `beforeUpdate` and `reset` call
  `initialize` when `chart.tooltip` is not null.
- `afterDraw` makes `args = {'tooltip': tooltip}`. It notifies `beforeTooltipDraw` with a new Map
  `{...args, 'cancelable': true}`, stops for the result `false`, draws, and
  notifies `afterTooltipDraw` with `args`. The registry order puts `tooltip` last (Chart.js ADR
  0020 §6). Thus the hook order of the Probes needs no change of `core.plugins.dart`.
- `afterEvent` calls `handleEvent(args['event'], args['replay'], args['inChartArea'])` and writes
  `args['changed'] = true` for a true result.
- `handleEvent(types.ChartEvent e, [Object? replay = undefined, Object? inChartArea =
  undefined])` applies the JS default: `undefined` gives `true` for `inChartArea`.
- `_getActiveElements` calls `chart.getElementsAtEventForMode(e, jsGet(options, 'mode'),
  options, useFinalPosition)` through `types.Chart` (Chart.js ADR 0038). The parameter
  `useFinalPosition` is a `bool?`. Thus a `bool` `replay` stays, another truthy value gives
  `true`, and another falsy value gives `null`. The built-in modes read it with `ToBoolean`
  only (`core.element.ts:35`). `active.reverse()` reverses the list in place
  (`_reverseInPlace`). The items come from the same list, so the covariant store of the concrete
  `List<InteractionItem>` accepts them, and the list keeps its identity, as upstream.
- `external` is `jsCall(external, [<String, Object?>{'chart': chart, 'tooltip': this, 'replay':
  replay}], thisArg: this)`, with the key order of the Probes.
- `setActiveElements(List<Object?> activeElements, [Object? eventPosition = undefined])` reads
  each item as `Chart.setActiveElements` does: a `types.ActiveDataPoint` gives its members, a Map
  gives `jsToNumber(jsGet(item, 'datasetIndex'))` and `jsToNumber(jsGet(item, 'index'))`. A
  private `_ActiveElement` holds `{datasetIndex, element, index}`, because `InteractionItem`
  needs a non-null element and `meta.data[index]` can be `undefined`. `getDatasetMeta` always
  gives a meta, so the throw of :1112 cannot occur, as in `core.controller.dart`.
- For a number index, this gives the upstream result. Upstream keeps a raw index of another type
  (Probes: the string `'1'` stays a string, and a later call with `1` counts as a change). The
  port converts it, because `types.ActiveDataPoint` has `double` members. The new row
  `adapt-active-elements-number-index` records this for both sites, `Chart.setActiveElements`
  and `Tooltip.setActiveElements`. `index.d.ts:515-518` declares both members as numbers.

### 13. The draw cost

- The draw keeps the upstream calls: `toFont` in each sub-method, `toPadding` in each
  `getAlignedX`, `each` for each list, `measureText` and `fillText`. The canvas caches serve the
  repeated measures and paragraphs. This ADR adds no text cache in the tooltip.
- Estimate for one visible frame with 3 items and no footer (AOT, from the microbenchmarks): 14
  to 16 µs. One event that changes the tooltip: 12 to 15 µs before the full chart render.
- Two facts go to step 8 of phase 8 as inputs, not as decisions:
  1. The fade frames miss the paragraph cache, because the key has the alpha. Each line of each
     frame of the 200 ms opacity animation builds a paragraph. The options are in
     `canvas_ui.dart`, a file that `canvas-cuts-plan.md` cites: keep, a quantized alpha in the
     key of a text paint (display only, Chart.js ADR 0034), or an opaque cached paragraph in a
     layer with the alpha.
  2. After an animation, `$animations` keeps its entries (Probes). Thus each frame of a still
     tooltip calls the positioner and measures its lines again, as upstream.
- `toFont` costs 705-733 ns (AOT) for each call, 285-336 ns of it in `toLineHeight` of a number.
  A number fast path of the shared helper belongs to the open item of
  [performance.md](../performance.md) §11.8, not to this ADR.

### 14. Interface members

| Interface | Member | Upstream | First reader |
|---|---|---|---|
| `types.TooltipModel` | `Chart get chart` | `index.d.ts:2649` | the spec, user code |
| `types.TooltipModel` | `List<Object?>? get dataPoints` | `index.d.ts:2652` | the spec |
| `types.TooltipModel` | `String? get xAlign`, `String? get yAlign` | `index.d.ts:2655-2656` | the spec |
| `types.TooltipModel` | `double get width`, `height`, `caretX`, `caretY`, `opacity` | `index.d.ts:2661-2665`, `:2693` | the spec |
| `types.TooltipModel` | `List<Object?>? get body`, `beforeBody`, `afterBody`, `title`, `footer`, `labelColors`, `labelTextColors`, `labelPointStyles` | `index.d.ts:2673-2690` | the spec, the 11 skip sites |
| `types.TooltipModel` | `List<ActiveElement> getActiveElements()` | `index.d.ts:2698` | the spec |
| `types.TooltipModel` | `void setActiveElements(List<Object?> activeElements, [Object? eventPosition])` | `index.d.ts:2699` | the spec |

- `x`, `y` and `options` come from `types.Element`.
- Chart.js ADR 0038 adds the members that the tooltip reads on other interfaces:
  `types.Chart.tooltip`, `types.Chart.getElementsAtEventForMode`,
  `types.DatasetController.getLabelAndValue` with `({Object? label, String value})` and
  `types.DatasetController.getDataset`. The casts of section 4 replace `hasValue` and
  `tooltipPosition` on `types.Element`.

### 15. Tests, rows and records

- `test/specs/plugin.tooltip_test.dart`: the 32 cases with the upstream names, `@TestOn('vm')`,
  and `group('auto', fixture.specs('plugin.tooltip'))` at spec :6. Seven cases need the legend
  (spec :36, :219, :329, :537, :615, :691, :1660). The spy of `update` replaces the field with a
  recording closure, as `core.controller_test.dart` does for `chart.resize`. The text align
  cases keep `merge(tooltip, view)` with a spec-local stub that implements `types.Chart`.
- `test/port/plugins/plugin.tooltip_test.dart` (port-only) pins the Probes: the access by name of
  the 24 names of section 2, `harness-method-fields`, the positioners (the shared Map, `this`, a
  result with `xAlign` and `yAlign`, `{}`, NaN, 0, -0 and `[-0]`), the callbacks (`undefined`
  against `null`, the noop test for the 14 names), the animations (the `$animations` keys, the
  empty cache), the number path of Chart.js ADR 0019 §6 on the tooltip, the draw order, the
  options `false`, `external`, `setActiveElements` (the throw of index 99, the number index), a
  write by name of `_active`, the class value and `adapt-component-class-role`, the `this` of
  `filter` and `itemSort`, and the calls of the canvas style for `textDirection`.
- `test/port/helpers/helpers.core_test.dart`, group `adapt-merge-element-target`: the six results
  of the two `merge` calls of the Probes on an `Element` and on a `Tooltip`, and the `clone`,
  `mergeIf` and two `merge` differences of the row.
- `packages/chartjs_test_utils/test/matchers_test.dart`: an element as an actual object of
  `toEqualOptions`, and the group `harness-expected-element`.
- A reference test compares the tooltip model and the draw calls with the build at the pin,
  through the harness of Chart.js ADR 0041.
- Rows: new `adapt-merge-element-target`, `harness-expected-element` and
  `adapt-active-elements-number-index`. Changed `harness-method-fields` (it adds
  `Tooltip.update`), `js-semantics-object-freeze` (it adds the `_cacheable` sentence of section
  9), `adapt-component-class-role` (it adds the constructor of `Tooltip`),
  `harness-fixture-sources` (it adds the raw `mousemove` of the 8 tooltip fixtures) and
  `adapt-rounded-rect-path` (it adds the caller `Tooltip._drawColorBox`). No other row: the
  record of section 5 and the noop test of section 8 give the same result for each input of the
  contract.

## Alternatives considered

A panel wrote three drafts: fidelity (F), performance (P) and simplicity (S). A judge scored them
in the order of the decision protocol and ran its own probes. F won and is the base. The
decision takes the `String?` alignment from P and S, the record of section 5 and the noop test
from P, and the `PointOptions` literal and the `this` helper from S.

**The model.**
- The tooltip as a plain Map. `Animations` and `instanceof Tooltip` (spec :1089) need a class.
- `Tooltip extends Element` with no declared members, each property in the extra Map. 45-56 ns
  slower for each animator frame and 406-426 ns slower for each draw (AOT). It breaks Chart.js
  ADR 0017 §3.
- `Chart.tooltip` with the concrete type `Tooltip`. `core.controller` would import a plugin.
- `Object? tooltip` with a cast at each reader. It drops the declared type of `index.d.ts:544`.
- `List<AnyObject>?` for `body` and `dataPoints` (P). A `clone` of a list literal and a spec list
  literal are `List<Object?>`. The write of `body` throws an `ArgumentError` in each text align
  case.
- `Object?` for `xAlign` and `yAlign` (F). It accepts values outside `index.d.ts:2655-2656`.
  Chart.js ADR 0017 §5 throws for them.
- The private names as Dart fields without access by name (S). A write by name of `_active`
  then goes to the extra Map, and the field does not change. It breaks Chart.js ADR 0017 §3.
- `bool _ignoreReplayEvents = false` (P). A read by name gives `false` where upstream gives
  `undefined` before the first event.

**Plain objects and positioners.**
- Typed classes for the tooltip item, the body item and the label style. `jsGet` gives
  `undefined` for them, and spec :26 calls the default `label` with a plain item. The gain is
  below 0.1 ms.
- A typed `Map<String, TooltipPositioner>`. The spec spy is a `JsFunction`, and a user function
  can need `this`.
- `ElementPoint` results of the built-in positioners (P). A user positioner that wraps a
  built-in one reads `undefined` for `.x`. No figure supports it.
- `Object.assign` as a Map (F). 134-145 ns (AOT) against 3.2-4.3 ns for the record.
- `Object.assign` as `{...position! as AnyObject, ...}` (S). The cast throws for a truthy result
  that is not a Map. Upstream copies the own properties of any object.
- An `identical(fn, _average)` fast path of the positioner call. 15-21 ns (AOT) for a second form.

**`update`.**
- A plain method. A spec cannot replace it on one tooltip, and `handleEvent` calls `this.update`
  on the instance of the plugin.
- `void Function(bool changed, [Object? replay])` (P). It rejects `update()`, a valid JavaScript
  call.
- Skip the two spec cases with a `diverges` reason. It loses two cases for 3 lines of code.

**Options and callbacks.**
- A cast to `ContextResolver` for `setContext`. It throws in the text align cases.
- A `ContextResolver` fast path of `setContext`. 12-21 ns (AOT) for a second form.
- A typed snapshot of the draw options. Below 0.1 ms, and it changes when a scriptable option
  runs.
- Typed default callbacks with direct calls (S, form F). Spec :26 fails, and the gain is below
  0.1 ms.
- The upstream two calls without the noop test (F, S). It keeps 383-405 ns (AOT) and
  1320-1564 ns (wasm) for each update with 3 items, with no gain in structure.

**Animations.**
- Drop the cache and the freeze, because a chart never reaches them. A user resolver without a
  context reaches the line.
- One `Animations` for the life of the tooltip. It changes a resolved option.

**`merge`.**
- A test helper `mergeByName` in `test/support/jasmine.dart` and a `harness-*` row (P). It keeps
  the silent difference of the public `Chart.helpers.merge` and changes four spec lines.
- `tooltip.assign(view)` (`Object.assign`) in the spec and a `js-semantics` row (S). The spec
  result is equal, but it keeps the same silent difference and changes four spec lines.
- `isObject` true for a `types.PropertyAccess`. `clone` would need the keys of an element, and
  `isObject` runs in each resolver and config path.

**The draw.**
- A font memo for each draw. It saves 3.5-4.4 µs for each frame and changes the structure.
- `for` loops in place of `each`. About 0.5 µs for each frame, and it changes the structure.
- A text cache in the tooltip. The canvas caches already serve it.
- A private `DrawPointOptions` class for the `drawPoint` literal (F, P). `PointOptions` exists.

**Raw indices of `setActiveElements`.**
- Keep the raw `Object?` indices. `types.ActiveDataPoint` and `InteractionItem` have `double`
  members, and `elementsEqual` takes `List<ActiveDataPoint>`. Every reader would change.
- Throw an `ArgumentError` for an index that is not a number. Upstream does not throw, and the
  tooltip of a string index shows the same lines (Probes). The conversion is closer.

## Consequences

- The tooltip gives the upstream model, lines, colors, alignment and caret for each input of the
  type contract. The protected throws stay at the upstream sites.
- `chart.tooltip` has the type `types.TooltipModel?`. User code reads the members of
  `index.d.ts:2648-2699` with no cast.
- A spec and a user replace `tooltip.update` on one tooltip. The row `harness-method-fields`
  has four members.
- `Chart.helpers.merge` writes into an element target, as upstream. `clone`, `mergeIf` and an
  element source of `merge` keep the leaf rule of `isObject`, and a row records it. In
  `toEqualOptions`, an expected element compares with `===`, and a row records it.
- An option `xAlign` or `yAlign` that is not a string, and a positioner coordinate that is a
  string or JS `null`, throw an `ArgumentError`. Upstream stores them. For a coordinate, `update`
  throws without an animation. With an animation, a later frame of the animator throws, and the
  animator then stops (section 5).
- A raw index of another type than number becomes a number in `setActiveElements`.
- The update path is about 0.4-1.6 µs faster for each update with 3 items than the upstream form
  of the callbacks, and the alignment record saves about 0.13-0.19 µs for each update and each
  animated draw.
- Three new rows and five changed rows (section 15). New `DIVERGES` markers: one for `update`
  (`harness-method-fields`) and one for `_tooltipConfig` (`adapt-component-class-role`) in
  `plugin.tooltip.dart`, three of `adapt-merge-element-target` in `helpers.core.dart` (`merge`,
  `merger` and `mergeIf`), one of `harness-expected-element` in
  `packages/chartjs_test_utils/lib/src/matchers.options.dart` (`_compareOption`), and one of
  `adapt-active-elements-number-index` in each of `core.controller.dart` and
  `plugin.tooltip.dart`. No skip reason. Chart.js ADRs 0017, 0019, 0020 and 0028 do not change.
  [Chart.js ADR 0043](0043-options-representation-and-resolver.md) restates Chart.js ADR 0006
  with the exception of section 10 for a `merge` target. It keeps the leaf rule for the rest.

## Open

1. **The device figures.** Owner: step 8 of phase 8. Trigger: the frame figures of a hovered
   chart. The frameless benchmark gets a tooltip case (a line chart with 3 and 10 datasets,
   `interaction.mode: 'index'`): (a) a hover change in each frame, (b) a still tooltip after the
   animation, (c) the fade in and out. The primary metric is the whole frame of (a). The guard
   cells are (b) and the same chart without a tooltip. If the draw of the tooltip costs 0.1 ms or
   more for each frame on the Pixel 8a or in the VS Code browser (Chromium, dart2wasm), the typed
   snapshot of section 7 comes back to a design panel.
2. **The fade frames.** Owner: step 8. Trigger: the figures of (c). A change of `canvas_ui.dart`
   updates `canvas-cuts-plan.md` in the same commit.
3. **A shared strict equality.** `core.layouts.dart`, `scale.category.dart`,
   `controller.bar.dart` and `plugin.legend.dart` have private copies of `===`, and the tooltip
   adds a fifth. A shared `jsStrictEquals` in `lib/src/js/` is
   outside this ADR. Owner: the shared JS runtime of ADR 0008.
4. **A public rounded rectangle literal.** Closed in step 7 of phase 8. Four `lib/` files have
   a private class for the literal `{x, y, w, h, radius}`: `_Rect` of `element.bar.dart`, and
   `_RoundedRect` of `scale.radialLinear.dart`, `plugin.legend.dart` and `plugin.tooltip.dart`.
   Each implements the upstream interface `RoundedRect` (`geometric.d.ts:31-37`). Upstream has
   an object literal at each site (`element.bar.js:81-99`, `:132-138`, `plugin.legend.js:347-353`,
   `plugin.tooltip.js:835-841`, `:848-854`, `scale.radialLinear.js:247-253`). Decision: the
   private classes stay. A public class gives the same behavior and no measured gain, and the
   private classes keep the upstream structure of one literal at each site
   ([porting-flow.md](../porting-flow.md) §1.1).
5. **The touch lift (#7738) and the tooltip fixtures.** Chart.js ADR 0037 decides the input path.
   Chart.js ADR 0041 decides the fixture notes. This ADR keeps the upstream event handling of
   :1139-1220.

## Evidence

The behavior probes ran the Chart.js build at the pin in the x64 Node.js v24.12.0 under Rosetta.
The benchmarks ran on an Apple M3 Max, macOS 26, Dart 3.13.5, at a load average of 7 to 11.

- **E0, upstream source** at `v4.5.1+7169e651`:
  - `src/plugins/plugin.tooltip.js:17-91`, `:94-118`, `:127-143`, `:148-221`, `:222-328`,
    `:340-355`, `:356-436`, `:447-455`, `:457-531`, `:533-636`, `:638-689`, `:795-856`,
    `:1006-1091`, `:1097-1220`, `:1223-1349`
  - `src/types/index.d.ts:515-518`, `:544`, `:577`, `:2648-2699`, `:2702`
  - `src/core/core.controller.js:1093-1112`
  - `src/helpers/helpers.core.ts:53-55`, `:190`, `:220-233`, `:249-286`, `:301-304`, `:310`
  - `test/specs/plugin.tooltip.tests.js:1-6`, `:26`, `:30`, `:964-968`, `:1027-1039`,
    `:1045-1088`, `:1148-1155`, `:1350`, `:1378-1497`, `:1499-1603`
  - `test/specs/core.controller.tests.js:1718-1724`
  - chartjs-test-utils `src/matchers.options.js@v0.4.0:2-4`, `:94-105`
- **E1, behavior probes (Node.js):** the Probes table of the Context. They cover the class and
  its keys, `merge` and `Object.assign` with a tooltip target, number lines and labels, the
  default callbacks with and without `this`, `undefined` against `null` results, the noop user
  callback, `_cacheable` and `$animations`, the hook order, the options `false`, `external`, the
  calls of `update`, the throw of `setActiveElements`, positioner results with alignment, `{}`,
  string coordinates, the `average` cases with NaN, 0 and -0, the alignment options of other
  types, and the raw indices of `setActiveElements`.
- **E2, Dart probes:** the port facts of `isObject`, `merge` and `jsGet` with an element, the
  branch of section 10 against the upstream results, the type of `clone` of a list, the method
  field `update`, and `setContext` through `jsCall`, on AOT and on dart2wasm.
- **E3, benchmarks:** the Benchmarks table of the Context, and the text probe in
  `flutter_tester`. The figures go to [performance.md](../performance.md) in step 8 with the
  device figures.
- **E4, the port code read:** `lib/src/helpers/helpers.core.dart` (`isObject`, `merger`,
  `merge`, `mergeIf`, `noop`), `packages/chartjs_test_utils/lib/src/matchers.options.dart`
  (`_isObject`, `_compareObject`, `_compareOption`), `lib/src/helpers/helpers.collection.dart`
  (`arrayUnique`), `lib/src/core/core.element.dart` (`operator []`, `operator []=`, `hasValue`,
  `tooltipPosition`), `lib/src/core/core.controller.dart` (`setActiveElements`),
  `lib/src/elements/element_options.dart` (`PointOptions`), `lib/src/js/js_function.dart`
  (`JsFunction`, `jsCall`, `jsCall1`), `lib/src/canvas/canvas_ui.dart` (the paragraph key of
  `fillText`), `lib/src/canvas/canvas_ui_text.dart` (the cache sizes).
- **E5, the rows:** [differences.md](../differences.md) rows `harness-method-fields`,
  `js-semantics-object-freeze`, `adapt-rounded-rect-path`, `adapt-animation-number-path`,
  `adapt-options-typed-results`, `harness-mock-optional-args`, `harness-fixture-sources` and
  `adapt-component-class-role`. A search of `differences.md` for `isObject` and `merge` found no
  row for the leaf rule of `isObject`. Section 15 gives the rows that this decision adds
  (`adapt-merge-element-target`, `harness-expected-element` and
  `adapt-active-elements-number-index`) and changes.
