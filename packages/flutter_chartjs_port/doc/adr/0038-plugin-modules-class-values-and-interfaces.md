# Chart.js ADR 0038: Plugin modules, class values and interfaces

- Status: proposed
- Date: 2026-10-22
- Related: [Chart.js ADR 0003](0003-type-only-dependencies.md) (type libraries, a member with its
  first ported reader, records for inline object types),
  [Chart.js ADR 0006](0006-options-representation-and-resolver.md) (plain objects as Maps, the
  `undefined` sentinel),
  [Chart.js ADR 0012](0012-dart-file-naming.md) (names of default exports and of `_` members),
  [Chart.js ADR 0017](0017-element-properties.md) §4 and §5 (the `undefined` state of the element
  classes, the access by name),
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §3, §6, §7, §10, §13 and Open (class
  values, namespaces, plugins and the hook dispatch, pure layers, a gain that only a
  microbenchmark measures, the frame figures of the dispatch),
  [Chart.js ADR 0028](0028-controller-interfaces.md) §1 and Open 2 (interface members and casts,
  the members of phase 8),
  [Chart.js ADR 0030](0030-controller-test-strategy.md) §3 (the registration in the test files of
  a unit),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0036](0036-parsed-data.md) (the `Expando` precedent of `stacksOf`),
  [Chart.js ADR 0039](0039-tooltip-model-and-animation.md) (the tooltip model, proposed),
  [Chart.js ADR 0040](0040-filler-targets-and-plain-points.md) (the filler targets, proposed),
  [Chart.js ADR 0041](0041-plugin-test-strategy.md) (the plugin test strategy, proposed),
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [performance.md](../performance.md) §6 (how to measure),
  [differences.md](../differences.md) rows `adapt-decimation-data-accessor` (new),
  `js-semantics-decimation-data` (new), `js-semantics-narrow-datasets` (changed) and
  `adapt-component-class-role` (changed)

## Context

Phase 8 ports the 15 files of `src/plugins/` (3518 lines): `index.js`, `plugin.colors.ts`,
`plugin.decimation.js`, `plugin.legend.js`, `plugin.subtitle.js`, `plugin.title.js`,
`plugin.tooltip.js` and the 8 files of `plugin.filler/`.

The accepted ADRs already give these parts:
- A plugin is a JavaScript object in the forms of Chart.js ADR 0006. A built-in plugin is a
  `Map<String, Object?>`. `_notify` reads `plugin[hook]` at each call (Chart.js ADR 0020 §7).
- A class that upstream keeps as a value gets a static `jsClass` (Chart.js ADR 0020 §3). The
  section names `Title`, `Legend` and `Tooltip`.
- A member that a ported module reads through a type interface becomes a member of that
  interface, with its first ported reader (Chart.js ADR 0003, Chart.js ADR 0028 §1).
- The typed hook slots "CT" wait for the frame figures with the real plugins (Chart.js ADR 0020
  Open, §13).
- Chart.js ADR 0028 Open 2 lists the first members of phase 8: `getLabelAndValue`,
  `getBaseValue`, `types.LegendElement` and `chart.legend`.

These questions stay open:
1. The Dart names of the seven plugin objects, the port of `plugins/index.js`, and the
   `plugins` namespace.
2. The parameter types of the hook closures.
3. The constructor parameter of `Title`, `Legend` and `Tooltip`, and the type of their `chart`.
4. The chart state that the plugins write: `chart.legend`, `chart.tooltip`, `chart.titleBlock`,
   and the `WeakMap` of `plugin.subtitle.js`.
5. For each member that a plugin reads: an interface member or a cast.
6. The `LayoutItem` fields of `Title` and `Legend` that start `undefined`, `draw()` without an
   argument, and `layouts.removeBox` with no box.
7. The accessor property `data` of `plugin.decimation.js:249-265`. A Dart `Map` has no accessor
   for one key.
8. The pure layers of `check:lib-imports`.
9. How step 8 of phase 8 measures the dispatch with the real plugins, and when CT comes back.

A design panel answered these questions with three drafts (fidelity, performance, simplicity),
one judge and one synthesis. The simplicity draft is the base. The other drafts give the
decimation sync, the pure roots, the `update` signature, the `differences.md` row text and the
second stage of the CT measurement.

### Upstream facts

Checked at `v4.5.1+7169e651` (`third_party/Chart.js` at `7169e65147a4`):
- `src/plugins/index.js:1-7` exports seven default exports as `Colors`, `Decimation`, `Filler`,
  `Legend`, `SubTitle`, `Title` and `Tooltip`. The source order is also the code unit order.
- Each plugin is an object literal, the default export of its file: `plugin.title.js:120`,
  `plugin.subtitle.js:6`, `plugin.legend.js:592`, `plugin.tooltip.js:1223`,
  `plugin.decimation.js:197`, `plugin.filler/index.js:12`, `plugin.colors.ts:102`.
- No built-in hook reads `this`. `stop`, `afterUpdate`, `afterDraw` and `destroy` take one
  parameter. `afterEvent` takes two. Each other hook takes three.
- `plugin.title.js:7`, `plugin.legend.js:41` and `plugin.tooltip.js:457` declare the classes.
  `_element` holds the class (`plugin.title.js:127`, `plugin.legend.js:599`,
  `plugin.tooltip.js:1225`). `Tooltip` has one static, `positioners` (`:462`). The plugin object
  has the same object (`:1226`).
- The constructors read `config.chart`, `config.options` and `config.ctx` only
  (`plugin.title.js:14-16`, `plugin.legend.js:62-64`, `plugin.tooltip.js:475-476`). The title spec
  passes `chart: {options: ...}`, a plain object, and `Title` never reads `chart`.
- The constructors set the box fields to `undefined` (`plugin.title.js:17-26`,
  `plugin.legend.js:65-79`). `Title.draw()` (`:84`) and `Legend.draw()` (`:269`) take no
  argument. `Title.update(maxWidth, maxHeight)` (`:29`) takes two arguments.
- The plugins write the chart: `chart.legend = new Legend(...)` (`plugin.legend.js:602`),
  `delete chart.legend` (`:609`), `chart.tooltip = new Tooltip(...)` (`plugin.tooltip.js:1230`),
  `chart.titleBlock = title` (`plugin.title.js:117`), `delete chart.titleBlock` (`:136`).
  `index.d.ts:543-544` declares `legend` and `tooltip`. It does not declare `titleBlock`.
- `plugin.subtitle.js:4` keeps its titles in `new WeakMap()`.
- `core.layouts.js:318-323` `removeBox` compares identities only.
- `plugin.decimation.js:249-265` replaces the own property `data` with an accessor. The getter
  gives `_decimated`. The setter writes `_data`. `:156-168` puts a data property back.
  `:216-218` reads `_data || dataset.data` before the early returns of `:220-238`. `:277` throws
  for an unknown algorithm after the accessor exists.
- Imports: no plugin imports `core.controller`, `core.datasetController` or `core.scale`.
  `plugin.title.js:4` and `plugin.legend.js` import `helpers.extras`. `plugin.subtitle.js:1`
  imports `Title`. `plugin.tooltip.js:1` imports `core.animations`. `plugin.colors.ts:1` imports
  the controllers through `../index.js`. `plugin.decimation.js:1` imports four helpers.
  `filler.drawing.js:1-3` imports helpers and filler files only. `plugin.filler/index.js:7`,
  `filler.helper.js:7` and `filler.target.stack.js:7` import `LineElement`.

### The port before this ADR

- `lib/src/index.dart:92` declares `plugins` as an empty unmodifiable Map. `registerables` is
  `[controllers, elements, plugins, scales]` (`:117`).
- `core.plugins.dart` (`_notify` at `:135-158`) and `core.registry.dart` take plugin Maps. They
  need no change.
- `types.Chart` has `LegendElement? get legend` (`lib/src/types/index.dart:443`).
  `Chart.legend` is a field (`core.controller.dart:861`). `types.LegendElement` has `chart` and
  `options` (`lib/src/types/index.dart:1039-1046`).
- `Scale` keeps its `LayoutItem` edges as NaN start values (`core.scale.dart:698-722`) and has
  `draw([ChartArea?])` (`:640`). `Scale` has no access by name for these fields.
- `layouts.removeBox` takes a `LayoutItem` (`core.layouts.dart:804`, `:1009`).
- `tool/src/lib_imports.dart:119-140` lists the pure roots. No file of `lib/src/plugins/`
  exists.

## Decision

### 1. Plugin modules and their names

Each plugin is a mutable top-level `Map<String, Object?>` with the upstream keys in the upstream
order. The Dart name is the export name of `plugins/index.js` in lowerCamelCase: `colors`,
`decimation`, `filler`, `legend`, `subTitle`, `title`, `tooltip`. This is the precedent of
`layouts`, `animator`, `ticks` and `registry`, which take the name of their re-export
(Chart.js ADR 0012).

```dart
// lib/src/plugins/plugin.title.dart
/// plugin.title.js:120 the default export, `Title` of plugins/index.js:6.
final AnyObject title = <String, Object?>{
  'id': 'title',
  '_element': Title.jsClass,
  'start': (types.Chart chart, AnyObject _, AnyObject options) {
    _createTitle(chart, options);
  },
  'stop': (types.Chart chart) {
    final titleBlock = chart.titleBlock;
    layouts.removeBox(chart, titleBlock);
    chart.titleBlock = null;
  },
  'beforeUpdate': (types.Chart chart, AnyObject _, AnyObject options) {
    final title = chart.titleBlock! as Title;
    layouts.configure(chart, title, options);
    title.options = options;
  },
  'defaults': <String, Object?>{/* plugin.title.js:145-156 */},
  'defaultRoutes': <String, Object?>{'color': 'color'},
  'descriptors': <String, Object?>{'_scriptable': true, '_indexable': false},
};
```

- The Map is mutable. Specs and user code write into it, for example
  `tooltipPlugin.positioners.test = ...` (`plugin.tooltip.tests.js:1045`) and the hook spies.
- The keys keep the upstream order. A test compares `jsObjectKeys` of each Map with the keys of
  the pinned build (section 11).
- A local variable `legend`, `title` or `tooltip` in a hook shadows the top-level Map. Upstream
  uses the same local names (`plugin.legend.js:602`, `plugin.tooltip.js:1247`).
- The example of Chart.js ADR 0020 §7 names the Map `plugin`. That name is an illustration. This
  section gives the names.

### 2. `plugins/index.dart`, the namespace and `registerables`

`lib/src/plugins/index.dart` ports `plugins/index.js` with seven `export ... show` lines.
`lib/src/index.dart` exports it and fills `plugins` in code unit order:

```dart
// lib/src/index.dart (index.ts:5 and :10)
export 'package:flutter_chartjs_port/src/plugins/index.dart';

final AnyObject plugins = Map<String, Object?>.unmodifiable(<String, Object?>{
  'Colors': colors,
  'Decimation': decimation,
  'Filler': filler,
  'Legend': legend,
  'SubTitle': subTitle,
  'Title': title,
  'Tooltip': tooltip,
});
```

- `registerables` does not change. `Chart.register(registerables)` registers the plugin ids in
  the order `colors`, `decimation`, `filler`, `legend`, `subtitle`, `title`, `tooltip`, as the
  pinned build does.
- The namespace is unmodifiable, as the frozen namespace of the bundle (Chart.js ADR 0020 §6).
- No name collides with an export of `lib/src/index.dart` (a probe with the seven names next to
  the library gives no analyzer issue).

### 3. Hooks

Each hook is a Dart closure in the Map literal. It keeps the upstream parameter count. Its
parameters are typed: `types.Chart chart`, `AnyObject args`, `AnyObject options`.

- `_notify` gives `[chart, args, descriptor.options]`. `args` is an `AnyObject` (`args ??= {}`),
  and `descriptor.options` is an `AnyObject` (the record `PluginDescriptor`). Thus the typed
  parameters accept each call of the plugin service.
- `jsCall` drops the extra arguments of a hook with fewer parameters by its arity test.
- No hook is a `JsFunction`, because no built-in hook reads `this`. The option functions of the
  defaults (for example the legend `onClick` and `labels.generateLabels`) are not hooks. The
  units of the legend and the tooltip decide their form by Chart.js ADR 0020 §7.

### 4. Class values of `Title`, `Legend` and `Tooltip`

Each class has a static `jsClass` with `superclass: Element.jsClass`. `Tooltip.jsClass` has the
static `positioners`. The constructor takes the upstream `config` object as a record (Chart.js
ADR 0003: an inline object type that ported code only reads).

```dart
// lib/src/plugins/plugin.title.dart
class Title extends Element implements LayoutItem {
  /// plugin.title.js:11 `constructor(config)`.
  Title(({Object? chart, AnyObject? options, CanvasRenderingContext2D? ctx}) config)
    : chart = config.chart,
      ctx = config.ctx {
    options = config.options;
  }

  /// plugin.title.js:7 `class Title` as a value (Chart.js ADR 0020, section 3).
  static final JsClass jsClass = JsClass(
    'Title',
    superclass: Element.jsClass,
    construct: (newTarget, args) => Title(_titleConfig(args)),
  );

  /// plugin.title.js:14 `chart`. Upstream stores it and never reads it.
  final Object? chart;
}

// lib/src/plugins/plugin.tooltip.dart
/// plugin.tooltip.js:17 `const positioners`.
final AnyObject _positioners = {'average': _average, 'nearest': _nearest};

class Tooltip extends Element implements types.TooltipModel {
  /// plugin.tooltip.js:462 `static positioners = positioners`.
  static final AnyObject positioners = _positioners;

  static final JsClass jsClass = JsClass(
    'Tooltip',
    superclass: Element.jsClass,
    statics: {'positioners': positioners},
    construct: (newTarget, args) => Tooltip(_tooltipConfig(args)),
  );
}
```

- The `construct` closure reads `chart`, `options` and `ctx` of `args[0]` with `jsGet`. An absent
  argument, `undefined` or `null` throws a `TypeError`, as `config.chart` throws upstream
  (`new Title()` throws in the pinned build). The `undefined` sentinel of an absent member
  becomes Dart `null`.
- `Title.chart` is `Object?`, because `Title` never reads it. `Legend.chart` is `types.Chart`,
  because `types.LegendElement.chart` is a `Chart`. `Tooltip.chart` is `types.Chart`, because
  the tooltip calls `chart.getContext()` and reads `chart.options`. The record of `Tooltip` has
  no `ctx` (`plugin.tooltip.js:475-476`). `Tooltip.chart` is not `final`: the access by name of
  [Chart.js ADR 0039](0039-tooltip-model-and-animation.md) §2 writes it. `Title.chart` and
  `Legend.chart` are `final`, because no code writes them by name.
- The plugin entry `positioners`, the static field `Tooltip.positioners` and the class static
  `positioners` are one Map (in the pinned build, `Tooltip.positioners === plugin.positioners`).
- The subtitle plugin has no `_element`.
- The row `adapt-component-class-role` gets the three `construct` closures (section 11).

### 5. Chart state

`types.Chart` gets these members, and `Chart` and the gallery `DemoChart` implement them as
fields:

```dart
// lib/src/types/index.dart, interface Chart
/// index.d.ts:543 `legend?: LegendElement`. Dart null stands for JS
/// `undefined`. The legend plugin writes it (plugin.legend.js:602) and
/// deletes it (:609).
abstract LegendElement? legend;

/// index.d.ts:544 `tooltip?: TooltipModel`. The tooltip plugin writes it
/// (plugin.tooltip.js:1230).
abstract TooltipModel? tooltip;

/// plugin.title.js:117 `chart.titleBlock`. index.d.ts does not declare it.
/// Dart null stands for JS `undefined` and for the `delete` of :136.
abstract LayoutItem? titleBlock;

/// index.d.ts:2648 `TooltipModel`. `Tooltip` implements it. Chart.js ADR
/// 0039 §14 gives its members.
abstract interface class TooltipModel implements Element {/* ADR 0039 §14 */}
```

- `legend` changes from a getter to a field. `Chart.legend` exists (`core.controller.dart:861`).
- `titleBlock` is a field, not an `Expando`. A field keeps the spec reads `chart.titleBlock`
  (`plugin.title.tests.js:282-355`, `core.layouts.tests.js:412`) and needs no row. Its read costs
  less than 1 ns on AOT and on dart2wasm.
- The plugins cast `chart.legend`, `chart.tooltip` and `chart.titleBlock` only to their own class
  (Chart.js ADR 0028 §1 item 2). An absent value throws a `TypeError` at the null check, in the
  same hook call as upstream. Upstream throws at the first member read of the value
  (`afterUpdate` and `afterEvent` of the legend). In `beforeUpdate` of the title, the subtitle
  and the legend, upstream throws at the write `item.fullSize` of `layouts.configure`
  (`core.layouts.js:332`), after the read of `options.fullSize`. The port does not do this read.
  The read has no visible effect, because the plugin options are a resolver that is not
  scriptable (`core.plugins.js:183-187`). The tooltip hooks test `chart.tooltip` first
  (`plugin.tooltip.js:1235-1268`) and do not throw.
- The subtitle `WeakMap` is a file-private `Expando<Title>`. `map.set` is `_map[chart] = title`.
  `map.get` is `_map[chart]`. `map.delete` is `_map[chart] = null`. An `Expando` holds its key
  weakly, as a `WeakMap` does. No row.

### 6. Interface members and casts

The rule of Chart.js ADR 0028 §1 applies to each ported plugin module ("controller" reads "ported
module"). When the upstream file of the reader imports the class of the value, the plugin uses
that class: a type test, a typed value of its own code, or a cast at the upstream read. Else the
member goes onto the `types` interface with its first reader.

| Interface | Dart member | Upstream | First ported reader |
|---|---|---|---|
| `types.Chart` | `abstract LegendElement? legend` | `index.d.ts:543` | `plugin.legend.js:602`, `:609` |
| `types.Chart` | `abstract TooltipModel? tooltip` | `index.d.ts:544` | `plugin.tooltip.js:1230` |
| `types.Chart` | `abstract LayoutItem? titleBlock` | `plugin.title.js:117` | `plugin.title.js:134`, `:140` |
| `types.Chart` | `void hide(double datasetIndex, [double? dataIndex])` | `index.d.ts:573` | `plugin.legend.js:649` |
| `types.Chart` | `void show(double datasetIndex, [double? dataIndex])` | `index.d.ts:574` | `plugin.legend.js:652` |
| `types.Chart` | `List<ActiveElement> getElementsAtEventForMode(Object e, Object? mode, Object? options, [bool? useFinalPosition])` | `index.d.ts:564` | `plugin.tooltip.js:1200` |
| `types.ChartMeta` | `Object? get visible` | `index.d.ts:478` | `plugin.legend.js:687` |
| `types.DatasetController` | `({Object? label, String value}) getLabelAndValue(double index)` | `index.d.ts:641` | `plugin.tooltip.js:130` |
| `types.DatasetController` | `Object? getDataset()` | `index.d.ts:648` | `plugin.tooltip.js:138` |
| `types.DatasetController` | `bool get supportsDecimation` | `index.d.ts:637` | `plugin.decimation.js:225` |
| `types.Scale` | `double getBaseValue()` | `index.d.ts:1376` | `filler.options.js:112` |
| `types.Scale` | `String get type` | `index.d.ts:1305` | `plugin.decimation.js:231` |
| `types.LineElement` | `PointElement? first()` | `index.d.ts:2028` | `filler.drawing.js:93`, `:123` |
| `types.LineElement` | `Object? interpolate(Point point, String property)` | `index.d.ts:2030` | `filler.drawing.js:201` |
| `types.LineElement` | `bool? pathSegment(CanvasPath ctx, Segment segment, [Map<String, Object?>? params])` | `index.d.ts:2031` | `filler.drawing.js:85`, `:115`, `:143`, `:153` |
| `types.ChartConfiguration` | `Map<String, Object?> get data` | `core.config.js:177` | `plugin.colors.ts:107-110` |
| `types.LegendElement` | `List<Object?>? get legendItems` | `index.d.ts:2417` | `global.defaults.tests.js:46` and the legend specs |

- The concrete members exist with these signatures. Each gets `@override`:
  - `Chart.getElementsAtEventForMode`, `Chart.hide`, `Chart.show` and `Chart.visible`
  - `DatasetController.supportsDecimation`, `getDataset` and `getLabelAndValue`
  - `Scale.type` and `Scale.getBaseValue`
  - `LineElement.first`, `interpolate` and `pathSegment`
  - `Config.data`
- `getLabelAndValue` gives `({Object? label, String value})`. The tooltip item keeps the raw
  label (Chart.js ADR 0028 Open 2).
- `getElementsAtEventForMode` keeps its concrete return type `List<InteractionItem>`, a valid
  covariant override. A `List<InteractionItem>` seen as a `List<ActiveElement>` throws a
  `TypeError` at an `add` of another `ActiveElement`. The tooltip never adds an item to that list.
  It copies the list, or reverses it in place.
- `first()` gives Dart `null` where upstream gives `0` for a line without segments
  (`element.line.dart:869-880`). The filler unit ports each reader of `first()` with this null.
- `first`, `pathSegment` and `interpolate` go onto `types.LineElement`, because
  `filler.drawing.js` imports no element module. A concrete `LineElement` type in
  `filler.drawing.dart` needs an import that upstream does not have (Chart.js ADR 0028 §1).
- Casts, not members:
  - `hasValue()` and `tooltipPosition()` (`plugin.tooltip.js:33-34`, `:69`, `:81`):
    `(el as Element).hasValue()` in `plugin.tooltip.dart`. `plugin.tooltip.js:2` imports
    `Element`. Each element of a chart is an `Element` (row `adapt-component-class-role`). Thus
    the cast throws nowhere where upstream does not throw. Nine test fakes of `types.Element`
    need no change.
  - `legendHitBoxes` is not in `index.d.ts`. No ported module reads it through the interface. The
    specs read `(chart.legend! as Legend).legendHitBoxes`.
- `types.LegendElement` does not implement `Element` or `LayoutItem`. Chart.js ADR 0028 Open 2
  names `implements Element, LayoutItem` (`index.d.ts:2414`). No ported module reads a member of
  these interfaces through `types.LegendElement`. The three `_TestLegend` fakes would need about
  17 members each. `Legend` implements `LayoutItem` itself. The legend `stop` hook keeps the
  upstream result with a type test:

```dart
'stop': (types.Chart chart) {
  final legend = chart.legend;
  // core.layouts.js:318-323 compares identities only. A value that is not a
  // LayoutItem is never in chart.boxes.
  layouts.removeBox(chart, legend is LayoutItem ? legend : null);
  chart.legend = null;
},
```

- A foreign object in `chart.legend` throws a `TypeError` at the cast to `Legend` in
  `beforeUpdate`. Upstream throws `TypeError: legend.buildLabels is not a function` in
  `afterUpdate`. Both throw in the same `update()` call (the cast rule of Chart.js ADR 0028 §1).
- `hide` and `show` take `double`. The default legend `onClick` passes the raw
  `legendItem.datasetIndex` (`plugin.legend.js:646-652`). The legend unit decides the conversion
  (Open 2).

### 7. Layout boxes

`Title` and `Legend` use the start values of `Scale` (`core.scale.dart:698-722`): NaN for `top`,
`bottom`, `left`, `right`, `width`, `height` (and `maxWidth`, `maxHeight` of the legend), the
`undefined` sentinel for `position` and `weight`, and `false` for `fullSize`.

- `ToNumber(undefined)` is NaN. Thus each arithmetic read and each comparison gives the upstream
  result. `fullSize` has only truthiness readers, so `false` gives the result of `undefined`.
- Chart.js ADR 0017 §4 is the rule of the element classes of `src/elements/` and of
  `core.element`. Its reason is the write by name of the animations. `Title` and `Legend` have no
  animation, and no `merge` writes their fields. `Scale` already follows this form. Thus `Title`
  and `Legend` need no `operator []` override for these fields.
- `void draw([ChartArea? chartArea])`. Upstream takes no argument. The default layer of
  `layouts.addBox` passes the chart area (`core.layouts.js:305`), and the specs call `draw()`.
- `Title.update(double maxWidth, double maxHeight, [TRBL? margins])` ignores `margins`, as
  `plugin.title.js:29` has two parameters. `Legend.update` uses `margins` (`plugin.legend.js:82`).
- `Legend.options` is `Map<String, Object?> get options => super.options!`, because
  `types.LegendElement.options` is not nullable. Only the getter changes.
- `layouts.removeBox` takes `LayoutItem?` (`core.layouts.dart:804` and the record field at
  `:1009`). `boxes.indexOf(null)` gives -1, as `indexOf(undefined)` does upstream. Thus the
  `stop` hooks of the title and the subtitle keep the upstream line with no branch.
- `Title.draw()` reads `_padding!`. Before `update` with `display: true`, it throws a
  `TypeError`, as upstream throws at `this._padding.top`.

### 8. The decimation data accessor

`data` stays a plain Map entry that holds the value of the upstream getter. An `Expando` marks
each dataset that has the accessor, and it holds the last value that the plugin wrote into `data`.
A sync turns a user write of `data` into the setter write. The row
`adapt-decimation-data-accessor` records the difference.

```dart
/// The accessor of plugin.decimation.js:255-264 on one dataset: [written] is
/// the last value that the plugin wrote into the plain entry `data`.
final class _DataAccessor {
  _DataAccessor(this.written);

  /// The last getter value that the plugin wrote into `data`.
  Object? written;
}

/// The accessor state of plugin.decimation.js:255-264: present while `data`
/// of the dataset is the accessor property.
final Expando<_DataAccessor> _dataAccessor = Expando<_DataAccessor>(
  'decimation data accessor',
);

// DIVERGES(chartjs): adapt-decimation-data-accessor, a Map has no accessor.
/// The setter of plugin.decimation.js:261-263, applied before each use of
/// the dataset.
///
/// A `data` value that is not identical to the last value that the plugin
/// wrote is a user write since the last hook: it goes to `_data`. Then
/// `data` gets the getter value (`_decimated`, :258-260). Thus a user write
/// or delete of `_decimated` changes `data` and not `_data`, as the getter
/// does. The getter value comes from [jsGet], so an absent `_decimated`
/// gives [undefined]. A `delete dataset.data` of the user removes the
/// accessor upstream: an absent key `data` clears the mark. A dataset that
/// is not a Map never has the accessor.
void _syncDataAccessor(Object? dataset) {
  if (dataset is! AnyObject) return;
  final accessor = _dataAccessor[dataset];
  if (accessor == null) return;
  if (!dataset.containsKey('data')) {
    _dataAccessor[dataset] = null;
    return;
  }
  final data = dataset['data'];
  if (!identical(data, accessor.written)) {
    // DIVERGES(chartjs): js-semantics-narrow-datasets, a narrow or fixed Map.
    dataset['_data'] = data;
  }
  final getterValue = jsGet(dataset, '_decimated');
  if (!identical(data, getterValue)) {
    dataset['data'] = getterValue;
  }
  accessor.written = getterValue;
}
```

- `beforeElementsUpdate` calls `_syncDataAccessor` first in the callback of each dataset, before
  `plugin.decimation.js:216`. Thus the early returns of `:220-238` keep the old decimated array,
  as upstream does.
- `cleanDecimatedDataset` calls it first, before `:157`. Thus the disabled path (`:206-209`) and
  the threshold path (`:243-246`) see the setter write.
- The sync compares `data` with the last value that the plugin wrote, not with the current
  `_decimated`. Thus a user write or delete of `_decimated` changes `data` and not `_data`, as
  the upstream getter does.
- An absent key `data` clears the mark: a `delete dataset.data` of the user removes the accessor
  upstream. Then `_data` is set, `:249` sees no first time, and `_dataCheck` writes a new empty
  array into a plain `data`, as upstream.
- The first time (`:249-265`): `dataset['_data'] = data`, `dataset.remove('data')`,
  `dataset['data'] = jsGet(dataset, '_decimated')`, and the `Expando` gets a `_DataAccessor`
  with that value. The key `data` moves to the end, as `delete` and `defineProperty` move it.
- `:280`: `dataset['_decimated'] = decimated`. Only for a marked dataset, the port also writes
  `dataset['data'] = decimated` and records it in the `Expando`. A dataset with its own `_data`
  key before the first decimation gets no accessor (`:249`), and its `data` stays the raw data.
- The clean (`:156-168`): it removes `_decimated` and `_data`, writes `data` and clears the mark.
  The key `data` keeps its position, as `defineProperty` on an own key keeps it.
- The getter value comes from `jsGet`, not from a Map read: an absent `_decimated` gives the
  `undefined` sentinel, as the upstream getter does. After an unknown algorithm (`:277`), `data`
  holds `undefined` and `_decimated` is absent, also at the second update in a row.
- A theme leaves `data`, `_data` and `_decimated` unchanged (theming.md §10, the phase 8 row).
- Cost: one sync for each dataset and each update, 15.9 ns on AOT and 29.9 ns on dart2wasm for
  the form with an `Expando<bool>`. The form above does the same reads and one more field write.
  No draw cost.

### 9. Pure layers

- `lib/src/plugins/plugin.decimation.dart` and `lib/src/plugins/plugin.filler/**` become pure
  roots of `tool/src/lib_imports.dart`, with a doc paragraph as for the other roots.
  `plugin.decimation.js:1` imports `_limitValue`, `_lookupByKey`, `isNullOrUndef` and `resolve`:
  their Dart files are pure roots. The 8 filler files import `helpers.core`, `helpers.math`,
  `helpers.segment`, `helpers.canvas`, `helpers.dataset`, `elements/` and each other: all pure.
- Their port-only tests of the pure parts (for example `lttbDecimation`, `minMaxDecimation`,
  `_decodeFill`, `_getTargetPixel`) use `package:test` and run on the VM, with dart2js and with
  dart2wasm. Their spec files stay `@TestOn('vm')`, because each case makes a chart.
- `plugin.title`, `plugin.legend`, `plugin.subtitle`, `plugin.tooltip`, `plugin.colors` and
  `plugins/index` are not pure. Each imports `helpers.extras`, `core.animations` or the
  controllers, or imports such a file.
- No plugin imports an external library outside the allowlists. Thus the external allowlists do
  not change.
- If a unit must import a non-pure file into a pure root, it removes the root in the same change
  and records the reason in the doc paragraph of `pureRoots`.

### 10. The hook dispatch and the measurement of CT

Chart.js ADR 0020 §7 stands. `_notify` reads `plugin[hook]` from the Map at each call and calls
it through `callback`. The plugin Maps of section 1 and the closures of section 3 need no change
of `core.plugins.dart`.

Step 8 of phase 8 measures the dispatch with the real plugins. The protocol is fixed here, before
any data:
1. **Stage 1, no code variant.** The frameless benchmark (`apps/chartjs_gallery/lib/main_bench.dart`)
   runs one chart in two configs. A: `registerables`, each plugin with its least work
   (`legend.display: false`, `title.display: false`, `subtitle.display: false`,
   `colors.enabled: false`, `decimation.enabled: false`, no `fill`, no event). B: the same chart
   with `options.plugins: false`. Then `_createDescriptors` gives no descriptor
   (`core.plugins.dart:209-211`). A minus B is an upper bound of the gain of CT: it holds the
   whole dispatch, the hook bodies and three empty boxes.
2. **Cells.** A line chart with 3 datasets of 1000 points, and a line chart with 100 datasets of
   100 points (204 notifies for each draw), each with `CALL=draw` and `CALL=update`. The gain of
   CT grows with the dataset count (Chart.js ADR 0020 §13). Thus the 100-dataset cells are
   primary.
3. **Platforms.** The Pixel 8a, the iPhone, macOS and the VS Code browser (Chromium, dart2wasm).
4. **Statistics.** ABBA, 6 pairs, 6 more pairs when an interval includes 0.1 ms. The mean of the
   pair differences of the run medians, with a 95 % bootstrap interval of 20000 resamples and a
   fixed seed. Each `BENCH` line records the notify count of one iteration (a counter in a timing
   plugin of the benchmark, not in `lib/`).
5. **Rule 1.** If the upper end of the interval of A minus B is below 0.1 ms in each cell and on
   each platform, CT stays closed. `performance.md` records the figures, and Chart.js ADR 0020
   Open 1 (the frame figures of the dispatch) closes.
6. **Stage 2, only for a cell that fails rule 1.** Variant B: a worktree in which `PluginService`
   keeps a precomputed descriptor list for each hook, and `_notify` visits only that list. B is
   not a valid port (a hook that a plugin gets later does not reach it), but it gives the largest
   gain that any CT form can give. A/B of B against the Map form on that cell, on the Pixel 8a and
   in the VS Code browser. Primary metric: the whole frame. Guard cells, named now:
   `chart.line` 1000 `CALL=draw` and the 3-dataset `CALL=draw` cell.
7. **Rule 2.** A new Chart.js ADR adopts CT only when the lower end of the gain interval is 0.1 ms
   or more and no guard interval lies wholly above 0. CT then keeps a Map branch with the read at
   each call for user plugins. An independent agent computes the figures again from the raw data.

Expected result (a calculation, not a decision): 51 ns for each notify on the M3 Max gives about
10 µs for each draw of 100 datasets. A phone factor of 3 to 8 gives 30 to 80 µs.

### 11. Tests, rows and records

- `test/port/index_test.dart`: `plugins` has the seven keys in code unit order, each value is the
  Map of its file (`same`), and `Chart.register(registerables)` gives the plugin ids in the order
  of section 2.
- `test/port/plugins/index_test.dart`: the generator `tool/reference/plugin_dispatch_reference.mjs`
  writes the call sequence of the real plugin hooks and the notify sequence for the construction,
  `draw()`, `render()`, `update('none')`, `update()`, `mousemove` and `mouseout` of a line chart
  with 3 datasets, the title on and a fill on dataset 0. It also writes the keys of each plugin
  object. The Dart test wraps each hook of the seven Maps with a recording closure of the same
  parameter count, builds the same chart with `acquireChart`, and compares both lists and the
  keys.
- `test/port/plugins/plugin.title_test.dart`, `plugin.subtitle_test.dart`,
  `plugin.legend_test.dart` and `plugin.tooltip_test.dart`: the class values (`superclass`,
  `_element`, the one `positioners` Map, `jsConstruct` with no argument throws), the start state
  of the boxes, `draw()` with no argument, `stop` with no box, `stop` with a foreign legend, two
  charts with one subtitle each, and the group `adapt-component-class-role`.
- `test/port/plugins/plugin.decimation_test.dart`, group `adapt-decimation-data-accessor`: the
  cases of the Evidence (the first decimation, the user write and the update, the identical
  write, the threshold, `enabled: false`, `plugins.decimation: false`, the three early returns,
  a write and a delete of `_decimated`, a delete and a new write of `data`, a user `_data` key,
  the unknown algorithm twice, the key position). Each difference of the row pins the Dart result,
  with the upstream value in a comment.
- `test/port/core/core.layouts_test.dart`: `removeBox(chart, null)` removes nothing.
- `test/tool/check_lib_imports_test.dart`: a decimation or filler file that imports
  `helpers.extras` fails the check.
- The analyzer of the package and of `apps/chartjs_gallery` proves each interface member and its
  implementers.
- `differences.md`: two new rows. `adapt-decimation-data-accessor` has four `DIVERGES` markers in
  `plugin.decimation.dart` (the sync, the sync call in the hook, the first-time block and the
  `data` write after `:280`). `js-semantics-decimation-data` has one marker (the cast of the data
  to a `List` in `getStartAndCountOfVisiblePointsSimplified`). The row
  `js-semantics-narrow-datasets` gets four markers in `plugin.decimation.dart` (the writes into
  the dataset Map). The row `adapt-component-class-role` gets the three `construct` closures. No
  other row: the plugin Maps, the namespace, the hooks, the class values, the interface members,
  the casts, the start values, `titleBlock`, the subtitle `Expando`, the pure roots and the
  dispatch give the upstream result for each input that a chart gives.
- `performance.md` gets the figures of section 10.

## Alternatives considered

**Plugin names.**
- A top-level `plugin` in each file, as the example of Chart.js ADR 0020 §7. `plugins/index.dart`
  then cannot export seven libraries that each declare `plugin`. It needs seven prefixed imports
  and seven aliases: two names for each object and more code. The same behavior and speed.
- A plugin class with typed hook slots (CT). See section 10.

**Hook parameters.** `Object?` parameters with casts in each body. The same behavior and the
same arity test. More code.

**Constructor parameter.** A Map `config` with casts in the constructor, or named parameters.
Equal on behavior and cost. The record mirrors the one upstream parameter and follows Chart.js
ADR 0003.

**`titleBlock`.**
- An `Expando` in `plugin.title.dart`. It needs a reader for the specs and a row
  (`adapt-chart-title-block`), and gives no `chart.titleBlock` to user code. An `Expando` read
  costs 7 to 9 ns on AOT and 22 to 29 ns on dart2wasm, against less than 1.1 ns for a field.
- An extras Map on `Chart`. A new access by name on `Chart`.

**Interface members for `hasValue` and `tooltipPosition`.** Exact, but nine test fakes of
`types.Element` need two members each. The cast gives the same result for each chart element,
because `plugin.tooltip.js` imports `Element`.

**A concrete `LineElement` type in `filler.drawing.dart`.** The type test of
`plugin.filler/index.js:25` promotes the line only inside that file. `filler.drawing.js` imports
no element module. Rejected by Chart.js ADR 0028 §1.

**`types.LegendElement` with `Element` and `LayoutItem`.** It follows `index.d.ts:2414`, but no
ported reader needs it, and three fakes grow by about 17 members each.

**A cast of `chart.legend` to `Legend` in `stop`.** A foreign `chart.legend` then throws in `stop`.
Upstream throws nothing there, removes no box and deletes the property. Rejected (a throw is
protected behavior).

**Box fields.**
- The `undefined` state of Chart.js ADR 0017 §4 (a nullable private field, a NaN getter,
  `undefined` by name). Exact for a read by name before the first layout. No spec and no ported
  module makes such a read. It costs about 12 lines and an `operator []` override for each class,
  and 0.45 ns more for each edge read on AOT.
- `late double top`. A read before the write throws a `LateError`. Upstream gives NaN in
  arithmetic, and `_getLegendItemAt` before a layout gives `null` with no throw.
- Nullable members on `LayoutItem`. Every reader of `core.layouts.dart` changes.

**Decimation accessor.**
- A plain write with no sync. A user write replaces the decimated array, and the next update
  decimates the old `_data`. The chart shows the old data: the drawn elements, the scale and the
  hit elements change.
- The sync without the restore of `data`. After a user write, an early return of `:220-238`
  leaves the user array in `data`. Upstream keeps the old decimated array (34 items against 200
  in the judge probe). The elements, the scale and the hit elements change.
- A sync that compares `data` with a plain Map read of `_decimated`. After an unknown algorithm
  (`:277`), `_decimated` is absent and `data` holds the `undefined` sentinel. The Map read gives
  Dart `null`, which is not identical to `undefined`. Thus the sync sees a user write, and it
  writes `undefined` into `_data` and `null` into `data`. The next update throws a null check
  `TypeError` in place of the upstream `Error` of `:277` (E4).
- A Map class with an accessor for `data`, in place of the user dataset. It breaks the identity
  of the dataset: `getDatasetMeta` finds the meta by identity (`core.controller.js:829-832`), and
  later user writes go to the old Map.
- An accessor registry that `jsGet` reads. The direct reads `dataset['data']` of `_dataCheck` and
  of user code miss it. It adds 13 to 14 ns on AOT and 18 to 23 ns on dart2wasm to each `jsGet`
  of a Map.

**Pure roots.** No plugin as a root. Then the web legs do not test the JS number forms of the
decimation algorithms and the target choice of the filler, and the layer does not follow the
upstream imports.

**CT measurement.**
- A device microbenchmark entry that gives the dispatch cost for each notify, times the notify
  count. It measures the dispatch alone, not the frame. Stage 1 of section 10 measures an upper
  bound in the frame with no code variant.
- Variant B as the first stage. It needs a worktree and code before any figure shows a need.

## Consequences

- Each plugin is a Map with the upstream keys, and the hook order is the upstream order. A user
  or a spec can replace a hook or a positioner at run time, as upstream.
- `types.Chart` gets six members, `types.ChartMeta` one, `types.DatasetController` three,
  `types.Scale` two, `types.LineElement` three, `types.ChartConfiguration` one and
  `types.LegendElement` one. `types.TooltipModel` is new. Chart.js ADR 0039 §14 gives its
  members. The full implementers change:
  `Chart`, `DemoChart`, `ChartMeta`, `Config`, `_DemoConfiguration`, the `_Meta` fake of
  `core.datasetController_test.dart`, the `_Config` fakes of `platform.base_test.dart` and
  `platform.basic_test.dart`, and the three `_TestLegend` fakes. `DatasetController`, `Scale` and
  `LineElement` get `@override` only. Fakes with `noSuchMethod` need no code.
- `layouts.removeBox` accepts `null`.
- A read by name of a box field of `Title` or `Legend` (`title['top']`) gives the extra property,
  `undefined`, also after the layout. No ported module and no spec makes such a read. A later read
  by name gets an `operator []` case for its field in the same change.
- The decimation plugin keeps the upstream state after each hook. Four results differ between
  hooks (the row `adapt-decimation-data-accessor`).
- Two plugin parts run in the web legs.
- Two new rows (`adapt-decimation-data-accessor`, `js-semantics-decimation-data`) and two changed
  rows (`js-semantics-narrow-datasets`, `adapt-component-class-role`), as section 11 gives. This
  ADR puts `DIVERGES` markers in `plugin.decimation.dart` (the three decimation rows) and in
  `plugin.title.dart` and `plugin.legend.dart` (the row `adapt-component-class-role`, at the
  config reader of each `construct` closure). `plugin.tooltip.dart` gets the third
  `construct` marker when the tooltip unit ports it. Chart.js ADRs 0017, 0020 and 0028 do not
  change. This ADR closes Chart.js ADR 0028 Open 2.

## Open

1. **CT.** Owner: step 8 of phase 8. Trigger: the frame figures of section 10. A gain that meets
   rule 2 goes to a new ADR that restates Chart.js ADR 0020 with CT.
2. **The index of `hide` and `show` from the default legend `onClick`.** Closed. The legend port
   gives `hide` and `show` the number of the property key `ToString(index)` (`_datasetIndexKey`).
   The row `adapt-legend-dataset-index` records the update mode of an index that is not a number.
3. **The filler target type.** Owner: [Chart.js ADR 0040](0040-filler-targets-and-plain-points.md)
   (the filler, proposed). `_getTarget` gives a `LineElement`, a `simpleArc`
   (`filler.target.js:30-31`), `true` or the `meta.dataset` of another dataset (`:41-44`).
   `filler.drawing.js:153` and `:201` call `pathSegment` and `interpolate` on a `simpleArc` too
   (`simpleArc.js:11-26`). The members of section 6 cover the line only. Chart.js ADR 0040 §4
   adds the port-only interface `types.SimpleArc` and the dispatch. It closes this item when it
   is accepted.
4. **`meta.$filler`.** Owner: [Chart.js ADR 0040](0040-filler-targets-and-plain-points.md). A
   typed field reads in 0.6 to 0.7 ns, the extras Map of `ChartMeta` in 6 to 19 ns. Chart.js ADR
   0040 §6 keeps the extra property of `ChartMeta` and the class `FillerSource`. It closes this
   item when it is accepted.
5. **The members of `types.TooltipModel` and the access by name of `Tooltip`.** Owner: the
   tooltip decision, [Chart.js ADR 0039](0039-tooltip-model-and-animation.md) (proposed).
   `Tooltip` animates, so its fields follow its own rule. Chart.js ADR 0039 §2 and §14 give
   them. They close this item when that ADR is accepted.
6. **The `_TestLegend` fakes.** Closed. Wave 4 removed the three fakes
   ([Chart.js ADR 0041](0041-plugin-test-strategy.md) §5).

## Evidence

The behavior probes ran the Chart.js build at the pin in the x64 Node.js v24.12.0 under Rosetta.
The benchmarks ran on an Apple M3 Max with Dart 3.13.5, AOT (`dart compile exe`) and dart2wasm
(`dart compile wasm -O2`) in Node.js v24.12.0. The Mac was shared (1-minute load 7 to 11). Thus
the absolute figures are high, and the ratios between the forms are stable over the processes.

- **E0, upstream source** at `v4.5.1+7169e651`:
  - `src/plugins/index.js:1-7` and the `import` lines of the 15 plugin files
  - `src/plugins/plugin.title.js:1-35`, `:110-145`
  - `src/plugins/plugin.subtitle.js:1-30`
  - `src/plugins/plugin.legend.js:41-105`, `:269`, `:592-656`, `:676-690`
  - `src/plugins/plugin.tooltip.js:17`, `:25-36`, `:125-140`, `:457-500`, `:1195-1202`,
    `:1223-1271`
  - `src/plugins/plugin.decimation.js:150-287`
  - `src/plugins/plugin.filler/index.js:7-40`, `filler.drawing.js:1-206`, `filler.target.js:1-60`,
    `simpleArc.js:1-27`
  - `src/plugins/plugin.colors.ts:1-2`, `:102-115`
  - `src/core/core.plugins.js:146-176`, `src/core/core.layouts.js:291-323`,
    `src/core/core.controller.js:486-500`, `:820`, `:829-832`,
    `src/core/core.datasetController.js:380-412`
  - `src/types/index.d.ts:478`, `:543-574`, `:637-648`, `:1305`, `:1376`, `:2028-2031`,
    `:2414-2420`, `:2648`
  - the spec reads of `titleBlock` (`plugin.title.tests.js:282-355`, `core.layouts.tests.js:412`),
    of `legendItems` and of `legendHitBoxes` (`plugin.legend.tests.js`, `global.defaults.tests.js`)
- **E1, the namespace, the keys and the hooks (Node.js).**
  - `Object.keys(plugins)` is `Colors`, `Decimation`, `Filler`, `Legend`, `SubTitle`, `Title`,
    `Tooltip`, and the namespace is frozen. `Chart.register(...registerables)` gives the plugin
    ids `colors`, `decimation`, `filler`, `legend`, `subtitle`, `title`, `tooltip`.
  - The keys of the plugin objects, in order:
    - colors: `id`, `defaults`, `beforeLayout`
    - decimation: `id`, `defaults`, `beforeElementsUpdate`, `destroy`
    - filler: `id`, `afterDatasetsUpdate`, `beforeDraw`, `beforeDatasetsDraw`,
      `beforeDatasetDraw`, `defaults`
    - legend: `id`, `_element`, `start`, `stop`, `beforeUpdate`, `afterUpdate`, `afterEvent`,
      `defaults`, `descriptors`
    - subtitle: `id`, `start`, `stop`, `beforeUpdate`, `defaults`, `defaultRoutes`,
      `descriptors`
    - title: `id`, `_element`, `start`, `stop`, `beforeUpdate`, `defaults`, `defaultRoutes`,
      `descriptors`
    - tooltip: `id`, `_element`, `positioners`, `afterInit`, `beforeUpdate`, `reset`,
      `afterDraw`, `afterEvent`, `defaults`, `defaultRoutes`, `descriptors`,
      `additionalOptionScopes`
  - `Function.length` of the hooks: 3, except `stop`, `afterUpdate`, `afterDraw` and `destroy`
    (1) and `afterEvent` (2).
  - `Object.keys(Tooltip)` is `['positioners']`, and `Tooltip.positioners === plugin.positioners`.
    `Title` and `Legend` have no own static key. `new Title()` throws `TypeError: Cannot read
    properties of undefined (reading 'chart')`.
  - The hook order of one `update()` of a line chart with title, subtitle and fill:
    `legend.beforeUpdate`, `subtitle.beforeUpdate`, `title.beforeUpdate`,
    `tooltip.beforeUpdate`, `decimation.beforeElementsUpdate`, `colors.beforeLayout`,
    `filler.afterDatasetsUpdate`, `legend.afterUpdate`, `filler.beforeDraw`,
    `filler.beforeDatasetsDraw`, `filler.beforeDatasetDraw`, `tooltip.afterDraw`.
  - Notify counts: a `draw()` makes 4 + 2N notifies for N visible datasets, an `update()` with its
    render 23 + 4N. With N = 3: 10 and 35. With N = 50: 104 and 223. A `mousemove` that shows the
    tooltip makes 16 (N = 3) and 110 (N = 50) notifies with its render. A `mousemove` with no
    change makes 2.
  - A new `Title` and a new `Legend` read `undefined` for each box field.
    `legend._getLegendItemAt(0, 0)` before a layout gives `null` with no throw. `title.draw()`
    with `display: true` before `update` throws a `TypeError` at `top` of `_padding`.
  - `titleBlock`, `legend` and `tooltip` are own properties of the chart. After
    `plugins.title: false` and `plugins.legend: false`, `titleBlock` and `legend` are absent.
    `tooltip` stays (the tooltip plugin has no `stop`).
- **E2, the stop hooks (Node.js).** `layouts.removeBox(chart, undefined)` does nothing. The stop
  hooks of the title, the subtitle and the legend do not throw without a box. With a foreign
  object in `chart.legend`, `stop` removes no box and deletes the property. `beforeUpdate` passes,
  and `afterUpdate` throws `TypeError: legend.buildLabels is not a function`.
- **E3, the decimation accessor (Node.js).**
  - 2000 points, `threshold: 100`, a canvas of 100 x 100. Keys before: `label`, `borderWidth`,
    `data`, `pointRadius`. Keys after the first decimation: `label`, `borderWidth`,
    `pointRadius`, `_data`, `data`, `_decimated`, with 386 decimated points.
  - A user write of 3000 points: a read of `data` gives the old decimated array, and `_data` is
    the new array. A tooltip item at index 1 before the next update has the raw value
    `{x: 19, y: 97}` of the old decimated array, not `{x: 1, y: 1}`. After the next update: 372
    points, the same key order.
  - The identical write `dataset.data = dataset.data` puts the decimated array into `_data`. The
    next update decimates the decimated array.
  - Below the threshold: keys `label`, `borderWidth`, `pointRadius`, `data`. `data` keeps its key
    position. A clean of `[_data, data, _decimated, foo]` gives `[data, foo]`.
  - A write, then `enabled: false`: `data` is the written array.
  - `plugins.decimation: false` after a decimation, a write and an update: a read gives the old
    decimated array, and the meta keeps 386 elements. The same for an early return
    (`indexAxis: 'y'`, `supportsDecimation` false, `parsing: true`).
  - An unknown algorithm throws `Error: Unsupported decimation algorithm 'nope'` at each update.
    The keys stay `_data`, `data`, and `data` reads `undefined`.
- **E4, the Dart forms of the sync.** The first form of the sync (an `Expando<bool>` and a compare
  of `data` with `jsGet` of `_decimated`), with the control flow of
  `plugin.decimation.js:205-282`, gives the upstream keys, lengths and identities for the early
  returns after a user write, for the unknown algorithm twice and for the key position. The group
  `adapt-decimation-data-accessor` of `plugin.decimation_test.dart` pins the form of section 8
  on these cases and on a write and a delete of `_decimated`. The sync
  with a Map read of `_decimated` throws a null check `TypeError` at the second update of the
  unknown algorithm. The sync without the restore of `data` gives 200 items in place of 34 after
  an early return. Each form differs from upstream when no hook runs.
- **E5, the Dart shapes.** `dart analyze --fatal-infos` accepts: the abstract fields `legend`,
  `tooltip` and `titleBlock` on an interface that `Chart` implements, the covariant override of
  `getElementsAtEventForMode`, an empty `TooltipModel`, `draw([ChartArea?])` over
  `draw(ChartArea)`, the getter override of `options`, typed hook closures through `callback` and
  `jsCall`, and `jsConstruct` of a class value with a record constructor. An `Expando<Title>`
  gives `null` before the write and after `expando[chart] = null`. Seven top-level Maps with the
  names of section 1 next to `lib/src/index.dart` give no issue. A `List<B>` seen as a `List<A>`
  accepts an in-place reverse and throws a `TypeError` at an `add` of another subtype.
- **E6, the dispatch (benchmark).** ns for one whole sequence, the median of 3 processes:

  | Sequence | Notifies | Map AOT | CT AOT | Map wasm | CT wasm |
  |---|---:|---:|---:|---:|---:|
  | draw, N = 3 | 10 | 718 | 165 | 1040 | 220 |
  | update, N = 3 | 35 | 2568 | 546 | 3258 | 698 |
  | event with render, N = 3 | 16 | 1180 | 250 | 1620 | 332 |
  | draw, N = 50 | 104 | 6861 | 1532 | 8878 | 1920 |
  | update, N = 50 | 223 | 14742 | 3285 | 17666 | 4077 |

  The Map form costs 66 to 80 ns for each notify on AOT and 79 to 147 ns on dart2wasm. CT saves
  51 to 60 ns and 61 to 119 ns. The largest gain on the Mac is 11.5 µs (AOT) and 13.6 µs
  (dart2wasm) for each update of 50 datasets. A second AOT process gave 65 ns (Map) and 14 ns (CT)
  for each notify, within 3 % of these figures. A form with three parameters for each hook and a
  direct call saves -2 to 19 % on AOT and keeps the Map reads.
- **E7, the state reads (benchmark).** For each read: a typed field 0.62 to 0.73 ns on AOT and
  0.89 to 1.58 ns on dart2wasm, an `Expando` 6.8 to 8.6 ns and 22 to 29 ns, an extras Map 5.9 ns
  and 10 to 12 ns. Thirty edge reads of five boxes cost 0.45 ns more for each read with the
  `undefined` state of Chart.js ADR 0017 §4 on AOT, with no stable difference on dart2wasm. The
  decimation sync costs 15.9 ns on AOT and 29.9 ns on dart2wasm for each dataset. An accessor
  registry in `jsGet` adds 13 to 14 ns and 18 to 23 ns to each `jsGet` of a Map.
- **E8, the census.** 71 classes implement an interface of section 6. 23 of them have no
  `noSuchMethod`. Section 6 changes 14 of these 23 classes (the Consequences list).
- **E9, the rows:** [differences.md](../differences.md) rows `adapt-decimation-data-accessor`,
  `js-semantics-decimation-data`, `js-semantics-narrow-datasets` and `adapt-component-class-role`.
