## 0.1.0

- The option `fill` holds a `FillTarget`, also in a raw configuration:
  `FillTarget.none` for `false`, `.toOrigin` for `true` and `'origin'`,
  `.toStart`, `.toEnd`, `.toStacked`, `.shape`, `.toDataset(i)` for a number,
  `.toPrevious`, `.toNext` and `.toRelative(n)` for `'-1'`, `'+1'` and
  `'+n'`, `.toValue(v)` for `{value: v}`, and
  `FillTarget.toOrigin.split(above: green, below: red)` for
  `{target, above, below}`. A boolean, a number, a Map or a text stops a debug
  build. `ChartFill`, `FillBoundary` and the typed `values.dart` are removed:
  `LineDataset(fill: .toOrigin)`.

- Use `ChartPaint` for paint-capable color options, including raw configurations.
  Solids use `.solid(color)`; `ChartGradient` and `ChartPattern` replace canvas
  gradient/pattern factories. Theme tokens, palette entries, shadow colors and
  gradient stops remain Flutter `Color` values.
- Make all dataset point and hover color fields `ChartValue<ChartPaint>?`,
  matching background and border fields: `.constant(.solid(teal))`,
  `.indexed([...])` or `.resolver(callback)`. Callbacks stay lazy and indexed
  values repeat by data index.

- `RenderTextOpts` and `BackdropOptions` are classes with a `const` constructor
  and named parameters. A caller of `renderText` makes the options with the
  constructor and no longer implements an interface. Their `color` and
  `strokeColor` are a `ChartPaint`, not an `Object?`:
  `RenderTextOpts(color: ChartPaint.solid(Color(0xFF666666)))`.

- Make each index an `int`: a dataset index, a data index, and the start and
  the count of a range of data elements. `getDatasetMeta`, `hide`, `show` and
  `toggleDataVisibility` of `Chart`, `getParsed`, `getLabelAndValue`,
  `getContext` and `updateElements` of a controller, the index parameter of
  `getPixelForValue` and `parse` of a scale, and the context keys `index`,
  `dataIndex` and `datasetIndex` take or hold an `int`. A subclass of a
  controller or a scale changes its overrides from `double` to `int`.

- Migrate active elements to the public extensible `ActiveElement` class with
  `int` `datasetIndex` and `index` and a nullable `element`. The interaction
  modes make it, `getActiveElements` gives it, and `setActiveElements` of the
  chart and of the tooltip take it:
  `chart.setActiveElements(const [ActiveElement(datasetIndex: 0, index: 2)])`.
  `InteractionItem`, `ActiveDataPoint` and `ChartHit` are removed, and a Map
  item is no longer an item.

- Migrate ticks to the public extensible `Tick` class: `label` is the list of
  its lines (`List<String>?`), and `major` is a `bool`. The option
  `ticks.callback` holds a `TickCallback`, also in a raw configuration:
  `(scale, value, index, ticks) => ['${value.round()} kg']`. The scale is the
  first argument, `null` removes the tick and `[]` keeps it with no label.
  `AxisTicks.callback` replaces `AxisTicks.format` and `AxisTickInfo`. The
  three tick formatters are functions of the same type.

- Migrate legend hit boxes to the public extensible `LegendHitBox` class.
  Layout, pointer and keyboard handling share native mutable geometry and
  integer row/column membership. Hit testing, centers, copying and merging
  are overridable; record slots and by-name hit-box access are removed.

- Migrate legend entries to the public extensible `LegendItem` class with native
  mutable fields and overridable `copyWith` and `merge`. Custom generators return
  these objects instead of Maps; legend events expose the same object instead of
  `ChartLegendItem`. Text is a list of lines, paints use `ChartPaint`, and indexes
  are nullable integers. A missing index has no default visibility action.

- Add `shadow: ChartShadow(...)` to each typed dataset. `ChartView` draws the
  shadow under the lines, points, bars and arcs of the dataset, but not under
  the area fill. A raw dataset sets the key `shadow` to the same
  `ChartShadow`. The canvas also has the four shadow attributes for plugins.

- Use sealed `ChartValue<ChartPaint>` for typed dataset `backgroundColor` and
  `borderColor`. Migrate plain colors to `.constant(...)`, the plural color
  companions to `.indexed(...)`, and `*ColorFor` callbacks to `.resolver(...)`.
  Point-specific and hover fields now use the same variants (ADR 0128).

- Add `Chart.updateData()` for incremental native data updates across all eight
  chart types, with metadata/interaction refresh and conservative full fallback.

- Add `Chart.updateRanges([mode])`, an opt-in update after a change of the
  `min` and `max` options of the scales only: it keeps the configuration of the
  last full update and runs each hook, the layout and the draw as `update`
  does, with a full update when a check fails (Chart.js ADR 0111).

- Reduce bar spacing preparation overhead with a linear duplicate scan for
  finite sorted indexes, preserving list identity and signed-zero behavior.

- Reduce numeric category parsing overhead for bars and base-controller primitive
  data while preserving live labels, fresh parsed records and custom fallbacks.

- Draw supported rectangular bars through a guarded native canvas operation,
  preserving pixels, canvas state, callbacks and the existing fallback.

- Add a guarded bulk numeric bar update path that reuses scalar settings and
  directly writes native elements while preserving callbacks and fallbacks.

- Reduce ordinary single-dataset bar update overhead with live topology checks,
  ordered-value handling and compact property construction; preserve callbacks
  and fallback behavior.

- Reduce ordinary bar drawing allocations with guarded scalar geometry while
  preserving the canvas calls and custom/rounded/inflated behavior.

- Improve dense bar updates and animation by splitting large native canvas
  recordings while preserving drawing order, compositing and circle batching.

- Fix blinking doughnut centers when rounded corners consume a small arc span.

- Speed up aligned stacked fills with a per-build exact-point search; unsupported
  inputs retain the original interpolation path.

- Canvas `globalCompositeOperation` now takes `CanvasCompositeOperation` enum
  values instead of strings. The canvas keeps only the native blend state.

- Color inputs now require Flutter `Color`, including raw configuration maps,
  callbacks, lists and gradient stops. CSS strings throw `ArgumentError`.

The first release: a native Dart port of Chart.js v4.6.1 for Flutter.

- **Upstream.** The package ports the Chart.js tag `v4.6.1` (commit `76d8cf89`) with no backport:
  no file of `lib/` has an upstream backport line, and the
  [upstream ledger](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_port/doc/upstream-ledger.md)
  has no backport row. The changes of chartjs/Chart.js#12130, #12142, #12155, #12238 and #12283,
  which the earlier commit pin `4.5.1+7169e651` ported, are part of v4.6.1.
- **Chart.js.** The eight chart types with their dataset controllers (bar, bubble, doughnut,
  line, pie, polar area, radar and scatter), the four elements (arc, bar, line and point), the six
  scales (category, linear, logarithmic, time, timeseries and radial linear), the seven plugins
  (colors, decimation, filler, legend, subtitle, title and tooltip), the core (the configuration
  and the option resolver, the registry, the animations, the interaction modes, the layout and the
  events) and the public helpers. Color arithmetic is based on @kurkle/color 0.3.2; chart inputs use Flutter Color.
- **`ChartView`.** The widget of one chart. `ChartView(config: ChartConfig(...))` takes the typed
  config, and `ChartView.raw(config: {...})` takes the Chart.js configuration as a Dart `Map`
  (also `jsonDecode` output). The widget starts the chart in its first layout, applies a new
  configuration after the frame, and takes its size from the constraints and the options
  `responsive`, `maintainAspectRatio` and `aspectRatio`.
- **Typed API.** `ChartConfig` with the chart type (`ChartKind`), one dataset class for each
  chart type (`BarDataset`, `LineDataset`, `ScatterDataset`, `BubbleDataset`, `PieDataset`,
  `DoughnutDataset`, `PolarAreaDataset` and `RadarDataset`), `DataPoint`, the axes
  (`CategoryAxis`, `LinearAxis`, `LogarithmicAxis`, `TimeAxis`, `TimeSeriesAxis` and
  `RadialLinearAxis`), the option groups (`ChartLegend`, `ChartTitle`, `ChartTooltip`,
  `ChartFiller`, `ChartInteraction`, `ChartAnimation` and `ChartElements`), Flutter values for
  the options (`Color`, `TextStyle`, `Duration` and `EdgeInsets`), and callbacks that get a
  details object with `int` indexes. A typed config can be `const`. An equal config gives no
  update. A new config updates the chart with the animations of Chart.js, and each dataset keeps
  its state by its `key` or by its index. The `extra` Map of each class takes the Chart.js options
  that have no parameter.
- **`int` indexes.** `Chart.getDatasetMeta`, `isDatasetVisible`, `setDatasetVisibility`,
  `getDataVisibility`, `hide` and `show` take a `num` index, so the `int` index of a callback
  works.
- **Theming.** `ChartTheme` and `ChartThemeData`, with the presets `ChartThemeData.light()` (the
  Chart.js defaults) and `ChartThemeData.dark()`, and a theme switch at run time. A theme never
  changes `Chart.defaults`.
- **Accessibility.** The chart is one focus stop: the keyboard moves a virtual mouse over the
  legend items and the data elements. It is one semantics node with the text of `semanticLabel`.
  Under the reduced-motion setting of the platform (`MediaQuery.disableAnimations`), it animates
  nothing.
- **Dates.** A built-in date adapter with the rules of chartjs-adapter-moment 1.0.1 and ICU
  format patterns, in local time or in UTC (`setDefaultDateZone`).
- **Libraries.** `flutter_chartjs_port.dart` for apps, with the typed API, `chartjs.dart` for
  code that extends Chart.js (plugins, controllers and scales), and `helpers.dart` for the
  Chart.js helpers.
- **Typed internals.** The options, the resolvers, the parsed data, the element properties, the
  contexts and the plugins are typed Dart objects, not Maps. Code that extends Chart.js reads such
  an object by name through `JsObjectFace` (for example `(context as JsObjectFace)['dataIndex']`
  or `(args as JsObjectFace)['event']` in a plugin hook): a missing key reads `undefined`.
  `Chart.data`, `Chart.config.data` and `Chart.config.options` are `Object` (the `Map` of a raw
  configuration, or a typed object), `Chart.options` is the options resolver, and the
  `Merger` and `InteractionModeFunction` types take `Object` targets and options.
- **Differences.** The README lists the differences from Chart.js that an app can see: the date
  formats, the Dart collection types of a raw configuration, the data array changes and the
  missing DOM.

## 0.0.1

- Initial scaffold. Tracks Chart.js 4.5.1. Nothing renders yet.
