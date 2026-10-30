# Chart.js ADR 0052: The typed public API

- Status: proposed
- Date: 2026-10-30
- Supersedes, on acceptance, these parts only (the section "Superseded parts" restates each one in
  full):
  - [Chart.js ADR 0043](0043-options-representation-and-resolver.md), the item "Raw configs in
    0.1.0" (0043:97-100) and Open 1 (0043:218-220). The rest of Chart.js ADR 0043 stays.
  - [Chart.js ADR 0048](0048-entry-points-and-public-library.md) §5, the export list of
    `lib/flutter_chartjs_port.dart` (0048:189-192).
  - [Chart.js ADR 0049](0049-chart-view-widget.md) §1, the constructor and the type of `config`
    (0049:78-108); §4, the bullet "The change test is identity" (0049:151-152) and the docs bullet
    "a config is never `const`" (0049:180-184), both for the typed path only; Open 2 (0049:374-375),
    the half "typed widget callbacks". §2, §3 and §5-§9 of Chart.js ADR 0049 stay.
- Related: [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) (the protected behavior),
  [Chart.js ADR 0045](0045-reference-engine-arm64.md) §7 (numbers are `double`),
  [Chart.js ADR 0050](0050-public-theme-api.md) (the conversion of `Color` and `TextStyle`, Open 2
  typed component styles), [Chart.js ADR 0051](0051-input-events-and-interaction-state.md) (input
  events, proposed), [theming.md](../theming.md) §5.1,
  [porting-flow.md](../porting-flow.md) §1.1 (the performance rule),
  [differences.md](../differences.md) rows `js-semantics-narrow-datasets` and
  `js-semantics-narrow-labels`, [prior-art/chartjs-packages.md](../prior-art/chartjs-packages.md)

## Context

On 2026-10-30 the maintainer stopped the upload of 0.1.0. The maintainer called the Map-only API
unusable. Before the release, the package gets a typed Dart API over the port: a typed config,
chart types, datasets, data, options and callbacks. The raw Map config stays as the escape hatch
for Chart.js compatibility: a copy of the Chart.js docs and `jsonDecode` output. The README then
shows the typed API first.

This changes the scope line of Chart.js ADR 0043: "A typed options API comes after 0.1.0, with its
own ADR" (0043:97-100, :218-220). This ADR is that ADR. The upstream citations are at the pin
`v4.6.1` (`U/` is `third_party/Chart.js/`, `P/` is `packages/flutter_chartjs_port/`). I checked each
cited line at `v4.6.1` and in the tree at `c8058a7`.

### The API before this ADR

- `ChartView(config: Map<String, Object?>)` (`P/lib/src/widgets/chart_view.dart:160`). A `const`
  config fails the start: `initConfig` writes into `data` and `options`
  (`U/src/core/core.config.js:115-136`).
- A nested Map literal needs the type `<String, Object?>`. A narrower Map throws a `TypeError` when
  the chart or the colors plugin writes into it (rows `js-semantics-narrow-datasets` and
  `js-semantics-narrow-labels`; `U/src/plugins/plugin.colors.ts:35-52`).
- Callbacks are function values in the options, read by name, with `Object?` parameters. An index
  is a JS number, a `double`: the example calls `elements.first.index.toInt()`
  (`P/example/main.dart:74-76`).
- Colors, fonts, paddings and durations are CSS strings, Maps and numbers (`'rgba(...)'`,
  `{size: 12}`, milliseconds).
- A data change in place needs `chart.update()`. `ChartView` updates the chart for a new config
  object (Chart.js ADR 0049 §4).

Thus the common path has no autocomplete and no type check. It has the `TypeError` traps of narrow
Maps and of `const`, `double` indexes and CSS strings. These are the six complaints that this ADR
answers.

### The design panel

The phase 10 design panel T (2026-10-30) had three drafts and one judge. Draft t-a generated
extension types from `U/src/types/index.d.ts`. Draft t-b gave a sealed config class for each chart
type and a second widget `TypedChartView`. Draft t-c gave one `ChartConfig` with about 150 typed
keys. The judge scored the options in the order of `porting-flow.md` §1.1, with the Dart and
Flutter conventions and the cost of a later change after 0.1.0. The porting lead then decided three
open points: the widget entry (W2, section 9), the `num` indexes of `Chart` (section 10) and the
coverage set (section 4).

### Facts of the probes

| Probe | Result |
|---|---|
| J1a | An extension type over a Map has no run-time type: a `switch` over two dataset views takes the wrong case, and a plain Map `is` each view. |
| J1b | An extension type config is `const` only over a `const` Map, and the first write of Chart.js then throws an `UnsupportedError`. |
| J2a | After a removal at index 0, a reconcile by index gives the hidden state of dataset B to the wrong Map (`visible=[B]` where B was hidden). |
| J2b | A reconcile by key keeps the Map of B, its meta and its hidden state (`sameMeta=true`). |
| J3a | A plain value keeps option sharing (`$shared` true, one options object). A function and a List turn it off (two objects), for a raw config. |
| J3b | A scriptable that gives `undefined` gives `undefined`, `null` gives `null`, and only an absent key gives the root value: a scriptable has no fallback scope. |
| J5 | The 43 names of section 8 are free in `dart:ui`, `widgets`, `material`, `cupertino` and the 3 port libraries, and none is one of the 219 names of `U/src/types/*.d.ts`. `Easing` is a `material` name. |
| t-b P2 | A typed mixed config and its raw twin give 608 equal draw calls (colors compared in parsed form). |
| t-b P4 | A tooltip label callback that gives Dart `null` shows no line. One that gives `undefined` shows the default text (`invokeCallbackWithFallback`, `U/src/plugins/plugin.tooltip.js:447-455`). |
| t-b P5 | A bar `borderRadius` object gives 420 draw calls, the number gives 406: an object turns on all corners (`U/src/elements/element.bar.js:54-71`). |
| t-b P7 | An `EdgeInsets` padding Map gives the draw calls of the number form. |
| t-c P5 | A patch of the live dataset Map keeps the meta: the first frame of a new value starts at the old value (y 36.4 from 32.0). A new dataset Map starts from the base (y 167.2). |
| t-c P6 | A `const` typed config lowers to fresh Maps, and the chart starts. |

## Decision

### 1. The shape

One root class and one dataset class for each chart type. A mixed chart is a dataset list of two
classes.

```dart
@immutable
final class ChartConfig with Diagnosticable {
  const ChartConfig({
    required this.type,       // ChartKind: 'type'
    required this.datasets,   // List<Dataset>: 'data.datasets'
    this.labels,              // List<Object>?: 'data.labels', by reference
    this.scales,              // Map<String, ChartAxis>?: 'options.scales', key order kept
    this.indexAxis,           // IndexAxis?: 'options.indexAxis'
    this.responsive, this.maintainAspectRatio, this.aspectRatio,
    this.padding,             // EdgeInsets?: 'options.layout.padding'
    this.legend, this.title, this.subtitle, this.tooltip,  // 'options.plugins.*'
    this.interaction,         // ChartInteraction?: 'options.interaction'
    this.animation,           // ChartAnimation?: 'options.animation'
    this.onClick, this.onHover,  // ValueChanged<ChartEventDetails>?
    this.plugins,             // List<Map<String, Object?>>?: inline plugins, by identity
    this.extra,               // Map<String, Object?>?: deep-merged last into 'options'
  });
}

abstract final class Dataset with Diagnosticable {
  const Dataset({
    this.key,                 // Key?: the reconcile only, never lowered
    this.label, this.hidden, this.order,
    this.backgroundColor, this.backgroundColors, this.backgroundColorFor,
    this.borderColor, this.borderColors, this.borderColorFor,
    this.borderWidth,         // double?
    this.hoverBackgroundColor, this.hoverBorderColor, this.hoverBorderWidth,
    this.extra,
  });
}

final class BarDataset extends Dataset {
  const BarDataset({
    /* the parameters of Dataset */
    this.data,                // List<num?>?, by reference
    this.points,              // List<DataPoint>?, by reference
    this.xAxisID, this.yAxisID, this.stack, this.indexAxis,
    this.borderRadius,        // double?: the number form of the docs
    this.barPercentage, this.categoryPercentage, this.barThickness,
    this.maxBarThickness, this.minBarLength, this.grouped,
  }) : assert(data == null || points == null);
}
```

- `ChartKind` names the controller (section 7). `IndexAxis` is `enum IndexAxis { x, y }`.
- `Dataset` is `abstract final`, not `sealed`. Thus a user `switch` over datasets needs a
  wildcard now, and a later dataset class does not break it. The 8 classes are `BarDataset`,
  `LineDataset`, `ScatterDataset`, `BubbleDataset`, `PieDataset`, `DoughnutDataset`,
  `PolarAreaDataset` and `RadarDataset`. `PieDataset` and `DoughnutDataset` are two classes: a
  `DoughnutDataset` in a `pie` chart lowers with `type: 'doughnut'` and gets the doughnut cutout.
- A dataset writes `type` only when its controller id differs from the root `type`, as upstream
  reads `dataset.type || config.type` (`U/src/core/core.config.js:93-95`). Thus a bar chart
  lowers to the docs form, and a bar chart with one `LineDataset` lowers to the form of
  `U/docs/charts/mixed.md` (its `chart-editor` block).
- The chart-type options that upstream also reads in the dataset scope are dataset parameters:
  `cutout`, `radius`, `circumference`, `rotation`, `spanGaps`, `showLine` and `indexAxis`
  (`configure` resolves `this.options` over `datasetScopeKeys`,
  `U/src/core/core.datasetController.js:438-442`). `indexAxis` is also a root parameter, because
  `getIndexAxis` reads `options.indexAxis` for the scale defaults (`U/src/core/core.config.js:8`,
  `:73`).
- The option groups are flat on `ChartConfig` (`legend:`, `tooltip:`, `scales:`), not in an
  options class. The dartdoc of each parameter names its Chart.js path.
- The other classes, one line each:
  - `LineDataset`, `ScatterDataset`: `data`, `points`, the axis ids, `stack`, `indexAxis` (line),
    `fill` (`ChartFill`), `tension`, `borderDash` (`List<double>`, compared by value), `spanGaps`,
    `showLine`, `stepped` (`bool`), `pointRadius`, `pointHoverRadius`, `pointStyle`,
    `pointBackgroundColor`, `pointBorderColor`, `pointBorderWidth`.
  - `RadarDataset`: `data` and the line style keys without the axis ids.
  - `BubbleDataset`: `points`, the axis ids, `radius`, `hoverRadius`, `pointStyle`.
  - `PieDataset`, `DoughnutDataset`: `data`, `offset`, `hoverOffset`, `spacing`, `weight`,
    `circumference`, `rotation` (degrees), `cutout` and `radius` (`ChartLength`).
  - `PolarAreaDataset`: `data`, `offset`, `hoverOffset`, `spacing`.
  - `ChartAxis` (`abstract final`): `display`, `position`, `reverse`, `stacked`, `ticks`, `grid`,
    `title`, `extra`. Each subclass lowers its `type`. `LinearAxis`: `min`, `max`,
    `suggestedMin`, `suggestedMax`, `beginAtZero`. `LogarithmicAxis`: `min`, `max`,
    `suggestedMin`, `suggestedMax`. `CategoryAxis`: `labels`, `min`, `max` (`String?`).
    `TimeAxis`, `TimeSeriesAxis`: `min`, `max` (`DateTime?`), `unit` (`TimeUnit?`),
    `tooltipFormat`. `RadialLinearAxis`: `min`, `max`, `beginAtZero`, `startAngle`,
    `pointLabelsDisplay`, `pointLabelsFont`, `angleLinesColor`.
  - `AxisTicks`: `display`, `color`, `font`, `padding`, `stepSize`, `maxRotation`, `autoSkip`,
    `format` (`String? Function(AxisTickInfo)`). `AxisGrid`: `display`, `color`, `lineWidth`,
    `drawOnChartArea`, `drawTicks`, `offset`. `AxisTitle`: `display`, `text`, `color`, `font`,
    `align`, `padding`.
  - `ChartLegend`: `display`, `position`, `align`, `reverse`, `labelColor`, `labelFont`,
    `boxWidth`, `boxHeight`, `labelPadding`, `usePointStyle`, `onClick`, `onHover`, `onLeave`
    (`ValueChanged<ChartLegendEventDetails>?`), `extra`.
  - `ChartTitle` (the title and the subtitle): `display`, `text`, `color`, `font`, `align`,
    `position`, `padding`, `fullSize`, `extra`.
  - `ChartTooltip`: `enabled`, `mode`, `intersect`, `backgroundColor`, `titleColor`, `titleFont`,
    `bodyColor`, `bodyFont`, `footerColor`, `footerFont`, `padding`, `cornerRadius`,
    `displayColors`, `titleText` and `footerText` (`String? Function(List<ChartTooltipItem>)`),
    `labelText` (`String? Function(ChartTooltipItem)`), `extra`.
  - `ChartInteraction`: `mode`, `intersect`, `includeInvisible`.
  - `ChartAnimation`: `duration`, `delay` (`Duration`), `easing`, `loop`, `onProgress`,
    `onComplete` (`ValueChanged<Chart>?`). `static const none` lowers to `false`.
- Every config class is `@immutable` and `final`, with a `const` constructor and named parameters.
  `==`, `hashCode` and `debugFillProperties` come from one private `_props` list of each class, so
  no `build_runner` runs. Each class has `copyWith`.
- Dart `null` in a parameter means "not set": the lowering writes no key (Chart.js ADR
  0043:47-48). The JS `null` of a key goes through `extra`.

The files, all port-only (`// Original code, not ported from Chart.js: <reason>.`):

| File | Content |
|---|---|
| `lib/src/typed/typed.dart` | the export list of the typed API: `show` the names of section 8 |
| `lib/src/typed/config.dart` | `ChartConfig`, `ChartKind`, `IndexAxis` |
| `lib/src/typed/datasets.dart` | `Dataset`, the 8 dataset classes and `DataPoint`, in one library, because `abstract final` needs it |
| `lib/src/typed/axes.dart` | `ChartAxis`, the 6 axes, `AxisTicks`, `AxisGrid`, `AxisTitle` |
| `lib/src/typed/groups.dart` | `ChartLegend`, `ChartTitle`, `ChartTooltip`, `ChartInteraction`, `ChartAnimation` |
| `lib/src/typed/values.dart` | `ChartPosition`, `ChartAlign`, `ChartInteractionMode`, `ChartEasing`, `ChartPointStyle`, `ChartFill`, `ChartLength` |
| `lib/src/typed/callbacks.dart` | `ChartEventDetails`, `ChartLegendEventDetails`, `AxisTickInfo`, `ChartHit`, `ChartContext`, `ChartTooltipItem`, `ChartLegendItem`, `ChartScript` |
| `lib/src/typed/lower.dart` | internal: the lowering, the `extra` merge, the reconcile (`ChartConfigLowering`), the trampolines |
| `lib/src/theme/css.dart` | internal: `rawColorOf`, `colorToRgba` and `fontSpecOf`, moved from `theme_data.dart` with no change |
| `lib/src/widgets/chart_view.dart` | the typed entry of section 9 |

### 2. The lowering

The typed config lowers to the scope Maps of Chart.js ADR 0043, once for each changed config, never
in a frame. The resolver does not change, and no ported file changes for the lowering. The rules:

1. Each class lowers to a new `<String, Object?>` Map with the keys in parameter order. The order
   of `scales` is the Map order of the app: the box order is behavior.
2. Lists go by reference: `data`, `points`, `labels`, `CategoryAxis.labels` and `plugins`. The
   small style Lists (`backgroundColors`, `borderColors`, `borderDash`) lower to a new List.
3. A `Color` lowers through `colorToRgba` and a `TextStyle` through `fontSpecOf` of `css.dart`, the
   conversions of the theme (Chart.js ADR 0050). A `Duration` lowers to `inMicroseconds / 1000`.
   An `EdgeInsets` lowers to `{top, right, bottom, left}`. A name type lowers to its option value
   (section 7). `IndexAxis` lowers to its `name`.
4. A plain value never lowers to a closure. Only a function parameter does (`...For` and the
   callbacks).
5. `xFor` lowers to the 2-argument closure
   `(Object? c, Object? o) => colorToRgba(f(c as ChartContext))`. `jsCall` calls it with JS arity
   (`P/lib/src/js/js_function.dart:242-243`). The night cell T3 (section 12) decides a one-entry
   memo of the last `Color`.
6. The event callbacks (`onClick`, `onHover`, the 3 legend handlers, `onProgress`, `onComplete`)
   and the tooltip text callbacks lower to trampolines. A trampoline reads the newest
   `ChartConfig` of the `State` at the call. A trampoline is present only when the newest config
   has that callback.
7. A tooltip text callback that gives Dart `null` lowers to `undefined`: the tooltip then shows the
   default text (`U/src/plugins/plugin.tooltip.js:447-455`). `AxisTicks.format` lowers to a
   `JsFunction`, so the scale is the `this` of `U/src/core/core.scale.js:574`.
8. A dataset writes `type` only when its controller id differs from the root `type`.
9. `extra` merges last, as a deep merge of Maps into new `<String, Object?>` Maps. Other values,
   Lists included, go by reference. A key of `extra` beats a typed key of the same name, the rule
   of the `raw` Map of a theme (`P/lib/src/theme/compile.dart:24-26`). This is the escape for a
   gradient closure or a CSS string. `ChartConfig.extra` merges into `options`.

### 3. Data and update

Data:
- `data: List<num?>`, `points: List<DataPoint>` and `labels: List<Object>` go to the chart by
  reference. The docs idiom "push to `labels` and to each `data`, then `chart.update()`"
  (`U/docs/developers/updates.md:11-15`) thus works for a typed config too, with no copy.
- `DataPoint` is an extension type over `Map<String, Object?>`. It does not implement `Map`. Its
  public members are 4 constructors and the getters `x`, `y` and `r`:
  `DataPoint(num x, num? y)`, `DataPoint.time(DateTime x, num? y)`,
  `DataPoint.label(String x, num? y)` and `DataPoint.bubble(num x, num y, num r)`. Each makes one
  Map, as the raw `{x, y}` does. The chart reads it with `jsGetKey`. A data point is a leaf with
  no hierarchy, so J1a does not apply.
- **Lists are yours, Maps are ours.** The lowering passes each List by reference and makes each
  Map. Thus a `const` typed config works (t-c P6). The chart does not write into a data List. The
  category scale writes into `labels` for a string value that is not a label (row
  `js-semantics-narrow-labels`, `U/src/scales/scale.category.js:4-12`), and a `const` labels List
  then throws. The typed `data: List<num?>` never adds a label. `DataPoint.label` and
  `CategoryAxis(min: 'x')` with an unknown label do. The dartdoc of `labels` states this.

Update. A new `ChartConfig` that is not `==` to the last one reconciles with the live chart:
- The change test is `ChartConfig ==` (section 9). Lists compare by identity, so the cost is
  O(fields + datasets).
- The match rule: a new dataset with a `key` takes the live Map of the old dataset with an equal
  key and the same class. A new dataset without a key takes the live Map at its index when the old
  dataset there has no key and the same class. This is the rule of `Widget.canUpdate`. Each old Map
  serves at most one new dataset. Else the dataset gets a new Map, as upstream: a new meta
  (`U/src/core/core.controller.js:829-853`).
- The patch writes only the keys of the lowering. A key that the last lowering wrote and the new
  one does not write goes. The keys of plugins stay, for example the colors of
  `U/src/plugins/plugin.colors.ts:35-52` and the keys of the decimation plugin.
- A kept meta animates from the old values (t-c P5): the data animations are the upstream
  animations. `ChartView.updateMode` stays the way to turn them off.
- The in-place idiom stays: change a List in place and call `chart.update()` through
  `onChartCreated`.

### 4. Coverage and `extra`

- The typed set of 0.1.0 has about 155 key paths: the keys of section 1. The rule: a key is typed
  when (R1) its value is a CSS value or an index, or (R2) 2 or more of the 91 upstream doc files
  use it, or (R3) the 9 chart types of the gallery need it. Four corrections of the judge apply:
  1. The bar `borderRadius` is a `double`, not a `BorderRadius` (t-b P5). The docs sample uses the
     number (`U/docs/samples/bar/border-radius.md:32`, `:41`).
  2. The `cutout` and `radius` of pie and doughnut take `ChartLength` (`U/src/types/index.d.ts:319`).
     A doughnut API without its cutout fails the doughnut docs config of the gallery.
  3. `labels` is `List<Object>`: strings, numbers, `DateTime` values and multi-line `List<String>`
     items.
  4. Each dataset has `Key? key` (section 3). It does not lower.
- Each typed class has `final Map<String, Object?>? extra`, with the merge of section 2 rule 9.
  `ChartView.raw` stays the full escape hatch (section 9).
- Out of 0.1.0, through `extra` or `ChartView.raw`: `elements` defaults (each docs use has a
  form for each dataset), `segment`, `animations`, `transitions`, tooltip `external`, gradients and
  patterns, floating bars, custom parsing keys.
- `parsing: false`, `normalized` and the decimation plugin come as one group, the first additive
  change after 0.1.0: the decimation plugin needs `parsing: false`.
- Each later key is an additive named parameter on a `final` class.

### 5. The scriptable form

- A plain value stays plain. A typed plain value never lowers to a closure, so it never turns off
  option sharing (J3a).
- In 0.1.0, only the dataset `backgroundColor` and `borderColor` get the indexable and the
  scriptable form: the companion parameters `backgroundColors` (`List<Color>`) and
  `backgroundColorFor` (`ChartScript<Color>`), and `borderColors` and `borderColorFor`. A closure
  needs the conversion of a `Color` to its `rgba()` string. A debug assert allows at most one of
  each three.
- The List and the function turn off option sharing for that dataset, as the raw twin does: the
  resolver sees an array or a function (`needContext`, `U/src/core/core.config.js:351-366`,
  `:405-418`). Thus the typed API never turns off sharing where the raw twin keeps it.
- `ChartScript<T>` gives a non-null `T`. A scriptable has no fallback scope (J3b,
  `U/src/helpers/helpers.config.ts:255-273` gives the value of the function as is), so a `null`
  color has no use.
- Each later companion (`pointRadiusFor`, `pointBackgroundColors`, `radiusFor`) is additive.

### 6. Callbacks and views

The event callbacks take one details object, the Flutter form (`TapDownDetails`). A new field of a
details object is additive. A new upstream argument does not break a callback.

- `ChartConfig.onClick` and `onHover` are `ValueChanged<ChartEventDetails>?`.
  `ChartEventDetails` has `event` (`ChartEvent`), `hits` (`List<ChartHit>`) and `chart`
  (`Chart`). The port passes a `List<ActiveElement>` (`P/lib/src/core/core.controller.dart:2342`,
  `:2345`). `ChartHit` erases to `ActiveElement`, so `hits` is that List, with no copy.
- `ChartLegend.onClick`, `onHover` and `onLeave` are `ValueChanged<ChartLegendEventDetails>?`.
  `ChartLegendEventDetails` has `event` (`ChartEvent`), `item` (`ChartLegendItem`) and `legend`
  (`LegendElement`), the 3 arguments of the legend handlers
  (`P/lib/src/plugins/plugin.legend.dart:1053-1062`). A legend `onClick` replaces the default
  toggle, as upstream.
- `ChartTooltip.titleText` and `footerText` are `String? Function(List<ChartTooltipItem>)`, and
  `labelText` is `String? Function(ChartTooltipItem)`. Dart `null` gives the default text (section
  2 rule 7).
- `AxisTicks.format` is `String? Function(AxisTickInfo tick)`. `AxisTickInfo` has the 3 arguments
  and the `this` of the upstream tick callback (`U/src/core/core.scale.js:574`): `value`
  (`double`), `index` (`int`), `ticks` (`List<Tick>`) and `scale` (`Scale`). `null` hides the
  label, as upstream.
- `ChartAnimation.onProgress` and `onComplete` are `ValueChanged<Chart>?`.
- `ChartEventDetails`, `ChartLegendEventDetails` and `AxisTickInfo` are `@immutable` `final`
  classes with `const` constructors.
- The views are extension types over the port objects, with zero allocation:
  - `ChartHit` over `ActiveElement`, and it implements `ActiveElement`. It redeclares
    `datasetIndex` and `index` as `int`. `element` comes from `ActiveElement`. A `List<ChartHit>`
    is thus a `List<ActiveElement>`, for example for `chart.setActiveElements`.
  - `ChartContext` over the context Map (`P/lib/src/helpers/helpers.options.dart:524`): `chart`,
    `type`, `datasetIndex` (`int?`), `dataIndex` (`int?`, null in a dataset context), `active`,
    `raw` and `parsed`.
  - `ChartTooltipItem` over the item Map (`P/lib/src/plugins/plugin.tooltip.dart:232-251`):
    `chart`, `label`, `parsed`, `raw`, `formattedValue`, `datasetIndex`, `dataIndex` and
    `datasetLabel` (the `label` of the dataset).
  - `ChartLegendItem` over the legend item Map: `text`, `datasetIndex` (`int?`), `index` (`int?`)
    and `hidden`.
  - Each `int` getter is `toInt()` of the JS number. A getter gives Dart `null` for the
    `undefined` sentinel, for an absent key and for a value of another type. A view does not
    implement `Map`: no `Map` member is on its autocomplete list.
  - A view has no public constructor. The lowering casts the port object to the view
    (`context as ChartContext`): a view is its port object at run time. A new getter is additive.
- `ChartScript<T>` is `T Function(ChartContext context)`.
- The phases and the `setState` table of Chart.js ADR 0049 §6 apply unchanged: the lowered
  closures run where the raw closures run.
- The raw forms stay exported for code that extends Chart.js: `ActiveElement` with `double`
  indexes mirrors `U/src/types/index.d.ts:516-521`.

### 7. Value types

| Value | Dart type | Option value |
|---|---|---|
| Color | `Color` | `colorToRgba` of `css.dart`: the extended sRGB components, 8-bit channels, the exact alpha (Chart.js ADR 0050) |
| Font | `TextStyle` | `fontSpecOf` of `css.dart`: `family`, `size`, `style`, `weight`, `lineHeight`. `TextStyle.color` is not read, as in `ChartThemeData`; the dartdoc names the sibling color parameter |
| Duration | `Duration` | `inMicroseconds / 1000` (milliseconds) |
| Padding | `EdgeInsets` | `{top, right, bottom, left}` (t-b P7). The legend label padding is a `double` (row `adapt-legend-number-options`) |
| Bar radius | `double` | the number (t-b P5) |
| `cutout`, `radius` | `ChartLength` | `ChartLength.pixels(double)` gives the number; `ChartLength.percent(double)` gives `'<n>%'` through `jsNumberToString` |
| Easing | `ChartEasing` | the name: the 31 names of `U/src/helpers/helpers.easing.ts:12-122`. A `Curve` needs a `DIVERGES` hunk in `core.animation`, because upstream reads a name (`P/lib/src/core/core.animation.dart:189`) |
| Chart type | `ChartKind` | the controller id: `bar`, `line`, `scatter`, `bubble`, `pie`, `doughnut`, `polarArea`, `radar` |
| Position | `ChartPosition` | `top`, `left`, `bottom`, `right`, `center`, `chartArea` (`U/src/types/layout.d.ts:3`); the object form goes through `extra` |
| Align | `ChartAlign` | `start`, `center`, `end` (`U/src/types/index.d.ts:1844`) |
| Interaction mode | `ChartInteractionMode` | `index`, `dataset`, `point`, `nearest`, `x`, `y` (`U/src/types/index.d.ts:770-799`) |
| Point style | `ChartPointStyle` | the 10 names of `U/src/types/index.d.ts:2040-2050`, and `none` for `false` |
| Fill | `ChartFill` | `origin`, `start`, `end`, `stack`, `shape`, `none` (`false`), `ChartFill.dataset(int)` (the index), `ChartFill.relative(int)` (`'+1'`, `'-1'`), `ChartFill.value(num)` (`{value: n}`) (`U/src/types/index.d.ts:2300`, `U/src/plugins/plugin.filler/filler.options.js:120-137`) |
| Index axis | `enum IndexAxis { x, y }` | the `name` |

- The name sets are extension types with `const` constants, so a dot shorthand works
  (`type: .bar`, `easing: .easeOutQuart`) and a new constant is additive. `ChartKind`,
  `ChartPosition`, `ChartAlign`, `ChartInteractionMode` and `ChartEasing` are over `String` and
  give their `name`. `ChartPointStyle`, `ChartFill` and `ChartLength` are over `Object`: they also
  hold `false`, numbers and records. Their `@internal` getter `optionValue` gives the option value.
  A record holds `ChartFill.value` and `ChartLength.percent`, so these constructors are `const`
  and two equal values are `==`.
- `ChartKind`, `ChartInteractionMode` and `ChartEasing` have a public constructor: a registered
  controller, a mode of `Interaction.modes` and an entry of the mutable `effects` Map
  (`P/lib/src/helpers/helpers.easing.dart:41`) have custom names. The other name types have
  private constructors: upstream has no registry for them. A later public constructor is additive.
- A Flutter `Color` cannot hold a CSS string, a gradient or a pattern. These go through `extra`.

### 8. Names and libraries

The typed API adds 43 public names, all exported by `lib/flutter_chartjs_port.dart`:
- Config (3): `ChartConfig`, `ChartKind`, `IndexAxis`.
- Datasets (10): `Dataset`, `BarDataset`, `LineDataset`, `ScatterDataset`, `BubbleDataset`,
  `PieDataset`, `DoughnutDataset`, `PolarAreaDataset`, `RadarDataset`, `DataPoint`.
- Axes (10): `ChartAxis`, `CategoryAxis`, `LinearAxis`, `LogarithmicAxis`, `TimeAxis`,
  `TimeSeriesAxis`, `RadialLinearAxis`, `AxisTicks`, `AxisGrid`, `AxisTitle`.
- Groups (5): `ChartLegend`, `ChartTitle`, `ChartTooltip`, `ChartInteraction`, `ChartAnimation`.
- Values (7): `ChartPosition`, `ChartAlign`, `ChartInteractionMode`, `ChartEasing`,
  `ChartPointStyle`, `ChartFill`, `ChartLength`.
- Callbacks and views (8): `ChartEventDetails`, `ChartLegendEventDetails`, `AxisTickInfo`,
  `ChartHit`, `ChartContext`, `ChartTooltipItem`, `ChartLegendItem`, `ChartScript`.

`ChartView` changes (section 9). Every name of `doc/public_api.txt` stays.

The name rules:
1. No typed name is a name of `U/src/types/*.d.ts`. The port declares such names over time
   (`lib/src/types/*.dart`), and `chartjs.dart` exports them (Chart.js ADR 0048 §4). A typed class
   of the same name then gives `ambiguous_export` in the app library. Thus `ChartKind`, not
   `ChartType`.
2. No typed name is a name of `package:flutter/widgets.dart`, `material.dart`, `cupertino.dart` or
   `dart:ui`. Thus `ChartEasing`, not `Easing`.
3. No typed name is a name that the 3 port libraries export without the typed API.
4. A group has the prefix `Chart`, a dataset the suffix `Dataset`, a scale config the suffix
   `Axis` and an axis part the prefix `Axis`. "Axis" follows the docs (`U/docs/axes/`: "Linear
   Axis") and keeps clear of the public classes `LinearScale`, `CategoryScale`, `TimeScale` and
   `RadialLinearScale`. `RadialLinearAxis` mirrors the id `radialLinear`.

The libraries:
- `lib/flutter_chartjs_port.dart` gets one more line, `export 'src/typed/typed.dart';` (the
  restated list of Chart.js ADR 0048 §5 is in "Superseded parts").
- `lib/chartjs.dart` does not export the typed API: it mirrors the `chart.js` entry (Chart.js ADR
  0048 §5). A plugin author imports the app library for the typed API.
- `ChartConfig` and `ChartConfiguration` (the interface of `chart.config`) are close names. The
  analyzer rejects the wrong type at `ChartView`, and the dartdoc of each names the other.
- `check:lib-imports` gets an allowlist for `lib/src/typed/`: `dart:ui`,
  `package:flutter/foundation.dart`, `package:flutter/painting.dart`, `package:meta/meta.dart`,
  `lib/src/types/`, `lib/src/core/core.controller.dart` (`Chart`), `lib/src/core/core.scale.dart`
  (`Scale`, `Tick`), `lib/src/js/js_function.dart`, `lib/src/js/js_number.dart`
  (`jsNumberToString`), `lib/src/js/js_undefined.dart` and `lib/src/theme/css.dart`. No file of
  `lib/src/typed/` imports `controllers/`, `scales/`, `elements/` or `plugins/`: the typed API
  writes keys, not components, so the tree shaking of Chart.js ADR 0048 §3 stays. Ported files
  never import `lib/src/typed/`.

### 9. `ChartView`

```dart
const ChartView({required ChartConfig this.config, /* the 7 other parameters */})
  : rawConfig = null;
const ChartView.raw({required Map<String, Object?> config, /* the same */})
  : rawConfig = config, this.config = null;
final ChartConfig? config;              // the typed config
final Map<String, Object?>? rawConfig;  // the raw config, every rule of Chart.js ADR 0049
```

- `ChartView(config: ChartConfig)` is the typed entry. `ChartView.raw(config: Map)` is the escape
  hatch. This is the Flutter form of `Text` and `Text.rich`. A second widget name
  (`TypedChartView`) keeps the Map widget as the default name.
- The raw path is unchanged: the identity test and steps 1-6 of Chart.js ADR 0049 §4, and its docs
  list.
- The typed path, in `didUpdateWidget`: the `State` stores the newest typed config for the
  trampolines. It schedules the post-frame update of Chart.js ADR 0049 §4 only when
  `oldWidget.config != widget.config`, or when the form changed (typed or raw).
- `ChartConfig ==` compares each field by `==`; `data`, `points`, `labels` and `plugins` by
  identity; the small style Lists by value; `...For` and `AxisTicks.format` by identity; the
  trampoline callbacks by presence (null or not). Thus a parent that rebuilds with an equal
  config gives no update. Chart.js ADR 0049 rejected an O(points) equality (0049:325-326).
- The post-frame update lowers through `ChartConfigLowering.apply(newConfig)` and gives the app
  Map to the unchanged steps 1-6:
  1. a new root Map, and a new `data` Map with `labels` (by reference) and a new `datasets` List;
  2. each new dataset takes a live Map by the match rule of section 3, else a new Map;
  3. a matched Map with an `==` dataset stays as it is; else the patch removes the keys that the
     last lowering wrote and the new one does not write, and writes the new entries;
  4. the `options` Map stays the same object when the option fields are `==` (then an imperative
     `chart.options` edit stays, Chart.js ADR 0049 §4); else a new `options` Map;
  5. `type` and `plugins` as on the raw path.
- Two `ChartView`s with one `const` config each lower their own Maps.
- The theme switch of Chart.js ADR 0050 runs after the reconcile, in the same callback.
- The 62 call sites of `ChartView(` in 13 files change to `ChartView.raw(`: 7 test files under
  `test/port/`, the 4 gallery files, the example and the dartdoc of `chart_view.dart`.
- The dartdoc and the README state these rules: an `==` config gives no update; give a new List
  for new data, or change the List in place and call `chart.update()`; give a `key` to each
  dataset when the app adds, removes or reorders datasets; use a method tear-off or a field for an
  `xFor` function; change the config, not the live Maps.

### 10. The index parameters of `Chart`

A user who gets `hit.datasetIndex` (an `int`) cannot call `chart.hide(hit.datasetIndex)` with a
`double` parameter. The gallery shows the friction: `apps/chartjs_gallery/lib/demo/core_demo.dart:435`
(`chart.isDatasetVisible(d * 1.0)`) and `lib/charts/chart_type_page.dart:81`
(`getDatasetMeta(i.toDouble())`).

- In 0.1.0, these 6 methods of `Chart` take `num` at the public boundary: `getDatasetMeta(num)`,
  `isDatasetVisible(num)`, `setDatasetVisibility(num, bool)`, `getDataVisibility(num)`,
  `hide(num, [num?])` and `show(num, [num?])`. The 5 of them that `types.Chart` declares
  (`P/lib/src/types/index.dart:431`, `:445`, `:491`, `:503`, `:507`) take `num` too.
- Each body converts with `toDouble()` at the entry. Inside, the rule of Chart.js ADR 0045 §7
  ("Numbers are `double`") stays. No other line changes. Each `double` caller compiles.
- Each changed ported file gets a `DIVERGES` marker and an `adapt` row in `differences.md`:
  `adapt-chart-index-parameters` (`lib/src/core/core.controller.dart`) and
  `adapt-types-chart-index-parameters` (`lib/src/types/index.dart`).
- The existing tests pass unchanged. One new test calls each method with an `int` variable.

### 11. Tests

All tests of the typed API are port tests with `@TestOn('vm')`: the typed files import `dart:ui`
and the painting library. Thus `test:web` does not run them. The CI job `gallery-web` compiles the
typed path with dart2wasm through the example and one gallery page (section 13).

| File | Content |
|---|---|
| `test/port/typed/values_test.dart` | the constants and the option value of each value type, `==` of equal values, the dot shorthands |
| `test/port/typed/config_test.dart` | `ChartKind` and `IndexAxis`; later the `ChartConfig` lowering |
| `test/port/typed/datasets_test.dart` | `DataPoint` (its Map, its getters, a chart reads it); later the dataset lowering |
| `test/port/typed/callbacks_test.dart` | the views and the details over the objects of a real chart: `int` indexes, the `undefined` rule, `List<ActiveElement>` as `List<ChartHit>`; later `onClick`, `onHover` and the legend handlers through `triggerMouseEvent`, tooltip `labelText` null gives the default text, `AxisTicks.format` gets the scale, `backgroundColorFor` gives the element colors of a raw closure with the same strings |
| `test/port/typed/names_test.dart` | the name rules of section 8 over the 43 names and the exports of `typed.dart`: the upstream names from the `exports` of `doc/upstream/manifest.json`, the Flutter and port names through an analyzer resolve |
| `test/port/typed/lowering_test.dart` | for each typed field, a config with that field alone lowers to the expected key path and value form, with the key order (`jsObjectKeys`). It covers `borderRadius`, `ChartLength`, `Duration`, `EdgeInsets`, `TextStyle`, `Color`, the name types, `extra` (deep merge, wins) and the dataset `type` rule |
| `test/port/typed/docs_twins_test.dart` | the 11 docs configs of `apps/chartjs_gallery/lib/docs/charts/` and `lib/docs/samples/area/line_boundaries.dart`, and one chart of each of the 8 types, written typed: equal draw calls (`drawCalls`, colors in parsed form), equal resolved options and element properties, equal hits on a grid. Also under `ChartThemeData.light()` |
| `test/port/typed/reconcile_test.dart` | J2a and J2b as `ChartView` tests; the hidden state, the meta and the elements kept, the first frame near the old value; a removed typed key leaves the live Map; a colors-plugin key stays; a class change at an index gives a new meta; append and remove; a theme switch and a data change in one frame; the decimation plugin (through `extra`) with a new `data` List |
| `test/port/typed/change_test.dart` | an `==` config gives no `beforeUpdate`; a new `data` List gives one; a new inline `onClick` closure gives none, and the next click calls it; a new `xFor` closure gives one; `ChartView.raw` keeps the identity rule |
| `test/port/typed/value_semantics_test.dart` | `==`, `hashCode`, `copyWith`, `debugFillProperties` and the `const` constructors of the config classes |
| `test/port/typed/key_check_test.dart` | section 13 |
| `test/port/widgets/*` | the 62 call sites to `ChartView.raw(`, no other change |
| `test/port/core/core.controller_index_test.dart` | section 10 |
| `test/tool/public_api_test.dart` | `doc/public_api.txt` with the new names |

`test:cases`, `test:fixtures` and the reference tests do not change: they feed raw Maps. Equal Maps
give equal charts, because the chart reads only the Map. Thus the main test is the lowering twin
with the key order.

### 12. The night protocol

The porting lead runs it at night (22:00-08:00), by the method of `performance.md` §15.1: ABBA, a
fresh process for each run, the battery and temperature gates and an A/A control. Side A is the raw
config of today. Side B is the same chart, typed (the define `TYPED=1` in `lib/main_stress.dart`
and `lib/main_bench.dart` of the gallery). The deciding platforms are macOS (AOT) and the VS Code
browser (dart2wasm), with the Pixel 8a added. The rules are fixed before the first run:

| Cell | What | Rule |
|---|---|---|
| T1 | `chart.b` and `chart.c` (line, N 1000 and 20000), bar N 20000, a new config with a new data List in each step | PASS when the 95 % interval of B − A of `updateMs` p50 lies below +2 % of A, or below +0.1 ms when A is below 5 ms |
| T2 | a parent that rebuilds in each frame with an `==` typed config | PASS when B makes 0 `chart.update` calls after the first frame. This is a count, and it can run by day as a unit test |
| T3 | `chart.c` with `backgroundColorFor` against a raw closure that gives the same strings | PASS when B − A lies below +3 % of A. A FAIL adds the one-entry `Color` memo of section 2 rule 5, and the cell runs again the next night |
| T4 | the release size of the example, raw against typed, dart2js and dart2wasm (a build, by day) | Report only. A typed form above +20 kB opens a split of `typed.dart` |

A FAIL of T1 blocks the typed path of 0.1.0 until a profile of that cell names the cost.

### 13. The source, the drift checks and the README

- The typed classes are hand-written. A generator from `U/src/types/index.d.ts` is not in 0.1.0.
  Each key needs a Dart decision that a generator cannot take (t-b P4 and P5). The d.ts changes
  10-66 code lines in each minor release from v4.2.0 to v4.6.1, and a generator alone is larger
  than the 0.1.0 set.
- The trigger for a generator: the typed set passes about half of the 373 properties of the d.ts
  option tree. Then a new ADR decides it. The class shape is regular, so a generator can emit the
  same public API.
- The key check (`key_check_test.dart`): each lowered path is in `defaults.values.defaults` or
  `.overrides` of `doc/upstream/manifest.json`, or in an allowlist row with its `index.d.ts` line
  (the keys with no default: `data`, `label`, `labels`, `stack`, the axis ids, the callbacks). A
  `@TestOn('vm')` test reads `U/src/types/index.d.ts` when the submodule is checked out and checks
  that each allowlist line names its key. It prints the share of the defaults inventory that the
  typed set covers.
- Rule 6 (a bump) gets one step: read the `src/types/index.d.ts` hunk of the bump diff for the
  typed keys, and run the key check.
- The README "Usage" starts with a typed bar chart. "Updates" gives the rules of section 9.
  "Chart.js configs" gives `ChartView.raw` for a copy of the docs and `jsonDecode` output, with the
  Map rules of today. "Untyped keys" gives `extra`. The example becomes typed: a new `_votes` List
  in `setState` and an `onClick` tear-off with `int` indexes, with no `late final`, no
  `<String, Object?>`, no `toInt()` and no `chart.update()`.
- The docs pages of the gallery stay raw: they are docs ports with rule-2 headers. The Core tab of
  the "Phase 3" page (port-only code) gets a typed config, so that `gallery-web` compiles the typed
  path.

### 14. The gate

The porting lead accepts this ADR when:
- the tests of section 11 pass;
- the 7 pre-push gates of AGENTS.md pass (`format:check`, `analyze`, `test --no-select`,
  `test:web`, `test:cases`, `test:fixtures`, `check:port`);
- the night cells of section 12 pass.

## Superseded parts

Each part below replaces the cited text on acceptance.

1. **Chart.js ADR 0043, "Raw configs in 0.1.0"** (0043:97-100) becomes: "**Typed and raw configs
   in 0.1.0.** Release 0.1.0 accepts typed configs (`ChartConfig`, Chart.js ADR 0052) and raw Map
   configs, `jsonDecode` output included (`ChartView.raw`). The typed API lowers to the same scope
   Maps. Typed theme component styles depend on it ([theming.md](../theming.md) §5.1)."
2. **Chart.js ADR 0043, Open 1** ("The typed options API", 0043:218-220) closes: this ADR decides
   the typed options API. Typed theme component styles move to Open 5 of this ADR.
3. **Chart.js ADR 0048 §5, the app library** (0048:189-192) becomes:

   ```dart
   // lib/flutter_chartjs_port.dart: the app library.
   export 'chartjs.dart' hide Animation, Element;
   export 'src/theme/...' show /* Chart.js ADR 0050 */;
   export 'src/typed/typed.dart';
   export 'src/widgets/chart_view.dart' show ChartView;
   ```

4. **Chart.js ADR 0049 §1, the widget** (0049:78-108): `ChartView` has two constructors, as section
   9 gives. `ChartView(config: ChartConfig)` is the typed entry, and `ChartView.raw(config: Map)`
   takes the raw configuration `{type, data, options, plugins, platform}`, with the dartdoc of
   Chart.js ADR 0049 §1 for that Map. `updateMode` and `onChartCreated` stay as Chart.js ADR 0049
   §1 gives them.
5. **Chart.js ADR 0049 §4, "The change test is identity"** (0049:151-152): it holds for
   `ChartView.raw`. For a typed config, the change test is `ChartConfig ==` (section 9).
6. **Chart.js ADR 0049 §4, the docs bullet "a config is never `const`"** (0049:180-184): it holds
   for `ChartView.raw`. A typed config can be `const`: the lowering makes fresh `<String, Object?>`
   Maps.
7. **Chart.js ADR 0049, Open 2** (0049:374-375), "A controller object and typed widget callbacks":
   the typed callbacks of section 6 close the half "typed widget callbacks". The controller object
   stays open as Open 1 of this ADR.

## Alternatives considered

- **Extension types over the Maps** (t-a). A `switch` over two dataset views takes the wrong case
  (J1a). A config is `const` only over a `const` Map, which then throws at the first write (J1b).
  Each typed object carries the 21 members of `Map` on its autocomplete list. A wrapper
  `.value(1)` on each primitive option makes the common case noisy, and each upstream widening to
  scriptable breaks callers. Rejected on criteria 1, 5 and 6.
- **Sealed configs for each chart type and a widget `TypedChartView`** (t-b). 13 more classes for
  a family check that the d.ts does not give for mixed datasets either
  (`ChartConfigurationCustomTypesPerDataset`, `U/src/types/index.d.ts:3926-3931`). A second widget
  keeps the Map widget as the default name. Rejected on criteria 4, 5 and 6.
- **A resolver that reads typed objects** (t-a T2-d, t-b T2-C, joint point with panel R). It
  needs `DIVERGES` hunks in `helpers.config` and `core.config`. The per-element cost is the
  context machinery, not the scope reads. Rejected on criteria 2 and 3.
- **A generator from the d.ts.** 1,000-1,900 lines of tool, a 250-600 line table, 8,600-13,000
  generated lines and a TypeScript dependency in the CI job `port-checks`. Each upstream type
  change becomes a public change. Rejected for 0.1.0 on criteria 4 and 6 (section 13 gives the
  trigger).
- **Records converted to Maps for the data.** O(N) for each new List, and a change in place of the
  app List does not reach the chart. Rejected on criteria 1 and 2.
- **A `WidgetStateProperty`-style wrapper for each scriptable option.** Verbose for the 90 % case,
  and a later change of a field type breaks callers. Rejected on criteria 5 and 6.
- **Positional callbacks with the upstream signatures.** A new upstream argument breaks each
  callback. Rejected on criterion 6.
- **Deep equality of configs with item hashes.** O(points) in each rebuild; Chart.js ADR 0049
  rejected it. Rejected on criteria 2 and 4.
- **A reconcile by index only.** It gives the hidden state to the wrong dataset after a removal
  (J2a). Rejected on criterion 1.
- **A new Map for each change, with no reconcile.** Each change replays the entry animation and
  drops the hidden state (t-c P5). Rejected on criterion 1.
- **A `ChartColor` wrapper** (t-a). One call on each color for the CSS-string case only, and the
  CSS string stays available through `extra`. Rejected on criteria 4 and 5.
- **A Flutter `Curve` for the easing.** Upstream reads a name, and a `Curve` needs a `DIVERGES`
  hunk in `core.animation`. Rejected on criteria 1 and 3.
- **A `BorderRadius` for the bar radius.** It gives other draw calls than the docs number (t-b P5).
  Rejected on criterion 1.
- **An assert on an `extra` key that shadows a typed key** (t-b). It blocks the escape for a
  gradient closure or a CSS string. Rejected on criterion 5.
- **`ChartView.typed` with the raw constructor as the default.** The raw form stays the default
  for good. Rejected on criteria 5 and 6.
- **Extension methods with new names for the `int` indexes** (`hideDataset(int)`). 6 more names
  and a double API. Rejected on criteria 5 and 6.
- **Upstream type names for the typed classes** (`ChartType`, `ChartData`, `TooltipItem`,
  `LegendItem`). Each one is a later `ambiguous_export` (J5). Rejected on criterion 6.

## Consequences

- No ported file changes for the typed API, except the index parameters of section 10. The raw
  path keeps every rule of Chart.js ADRs 0043 and 0049.
- The app library gets 43 new names. After 0.1.0, each one is a commitment (Chart.js ADR 0048).
  The `final` classes, the named parameters, the open name sets and the details objects make each
  later change additive.
- The README and the example show the typed API first.
- An inline `xFor` or `format` closure in `build` gives an update at each rebuild. The dartdoc and
  the README ask for a tear-off. The event and tooltip text callbacks are trampolines, so an
  inline closure there gives no update.
- A `const` labels List throws when the category scale adds a label. A test pins the throw and
  its message.
- A typed key that lowers to a path that upstream does not read has no effect. The key check, the
  lowering twins and the docs twins find it.
- The change of `chart_view.dart` and of the 62 call sites is mechanical.
- The size is about 10,000-12,000 lines with the tests and the docs.

## Open

1. **A controller object** (Chart.js ADR 0049 Open 2, the controller half). Trigger: an app
   request.
2. **Typed gradients and patterns.** Today they go through `extra`. Trigger: an app request.
3. **`callDefault` of the legend handlers** (t-b): the handler that the chart has without the
   callback. Trigger: an app request.
4. **The performance group**: `parsing: false`, `normalized` and decimation, the first additive
   change after 0.1.0 (section 4).
5. **Typed theme component styles** (Chart.js ADR 0050 Open 2). Trigger: the work on the theme
   component styles ([theming.md](../theming.md) §5.1).
6. **The generator.** Trigger: the typed set passes about half of the d.ts option tree
   (section 13).
7. **Public constructors of the views.** A unit test of a `ChartScript` in an app needs a
   `ChartContext`. Today the test casts a Map (`map as ChartContext`). Trigger: an app request.

## Evidence

The working files of the phase 10 design panel in `.handover/phase10/panel/` (not committed):
- `brief.md` (the maintainer decision, the facts and the questions T1-T9), the drafts `t-a.md`,
  `t-b.md` and `t-c.md`, the verdicts `judge-t.md` and the decisions of the porting lead
  `lead-decisions.md` (W2, the `num` indexes, the coverage set).
- `probes/t-judge/j1_j3_probe_test.dart.txt` and `j1_j3.out` (J1a, J1b, J2a, J2b, J3a, J3b: 6 of 6
  pass), `name_probe.sh` and `name_probe.out` (J5).
- `probes/t-b/typed_probe_test.dart` and `typed_probe_out.txt` (P2 to P8).
- `probes/t-c/p5_p6_probe_test.dart.txt` and `p5_p6.out` (P5, P6), `p1_extension_types.out`,
  `p2_name_ext.out`, `p3_modifiers.out`, `doc_keys.out` (the rule R2), `upstream_type_names.txt`
  (the 219 names) and `name_collisions.out`.
- `probes/t-a/dts_churn.out` (the d.ts churn from v4.2.0 to v4.6.1), `option_tree_size.out` (373
  properties), `ts_flatten/flatten.out`, `p2_shorthand_probe.out` and `p3_const_probe.out`.
- Upstream at `v4.6.1`: `src/core/core.config.js:8`, `:73`, `:93-95`, `:115-136`, `:351-366`,
  `:405-418`; `src/core/core.datasetController.js:438-442`; `src/core/core.controller.js:829-853`;
  `src/core/core.scale.js:574`; `src/plugins/plugin.tooltip.js:447-455`;
  `src/plugins/plugin.colors.ts:35-52`; `src/plugins/plugin.filler/filler.options.js:120-137`;
  `src/elements/element.bar.js:54-71`; `src/scales/scale.category.js:4-12`;
  `src/helpers/helpers.easing.ts:12-122`; `src/types/index.d.ts:319`, `:516-521`, `:770-799`,
  `:1844`, `:2040-2053`, `:2300`, `:3926-3931`; `src/types/layout.d.ts:3`;
  `docs/developers/updates.md:11-15`; `docs/samples/bar/border-radius.md:32`, `:41`;
  `docs/charts/mixed.md`.
