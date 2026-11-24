## Unreleased

- BREAKING: the date adapter has typed members (Chart.js ADR 0203): a timestamp is a `double`, a format a
  `String?` and an ISO weekday an `int`. `DateAdapterBase.override`, `DateAdapterBase.prototype` and
  `dateAdapterMembers` are gone. An app gives its adapter as a subclass of `DefaultDateAdapter` and writes its
  constructor into `adapters.date`: `adapters.date = MyDateAdapter.new`.
- BREAKING: no class of the typed API has `extra` (Chart.js ADR 0201). Each option is a typed parameter:
  write `LinearAxis(.y, stack: '1', offset: true)` in place of `extra: {'stack': '1', 'offset': true}`.
  New parameters: the axis parts (`precision`, `count`, `maxTicksLimit`, `circular`, `tickColor` and more),
  the axes (`offset`, `stack`, `stackWeight`, `grace`, `clip`, the 14 scale hooks, `borderFunction`, the time
  options `parser`, `parserFunction`, `round`, `minUnit` and `isoWeekday`), the element styles, the datasets
  (`base`, `inflateAmount`, `skipNull`, `pointRotation`, `parsing`, `normalized`, `animation` and more) and
  `ChartConfig` (`locale`, `normalized`, `color`, `autoPadding`, `onResize` and `datasetDefaults`, the options
  of all datasets of a type). The second form of an option is a parameter of its own: `borderRadiusCorners`,
  `borderWidths`, `borderWidthSides`, `spanGapsDistance`, `minIndex` and `maxIndex`, and floating bars are
  `data: .ranges([(1, 5), (2, 6)])`. The scriptable colors, widths and fonts of `AxisGrid` and `AxisTicks` are
  a `ScaleValue`: write `color: .constant(paint)` or `color: .resolver(colorOfTick)`.
- BREAKING: the canvas has typed members in place of its CSS style (Chart.js ADR 0200): `HTMLCanvasElement`
  has `displayWidth` and `displayHeight` (`double?`, the display size in logical pixels; `null` is the render
  size), `touchAction` (the enum `CanvasTouchAction`: `auto` or `none`), `userSelect` (`bool`) and
  `textDirection` (`TextDirection?`, the direction that a context with a `null` `direction` inherits).
  `retinaScale` writes the display size as doubles, the chart host reads `touchAction` at the start of a touch
  sequence, and `initCanvas` writes no `display` and no `box-sizing`. `getStyle` of `helpers.dart` is gone, and
  `readUsedSize` takes an `Axis` (`readUsedSize(canvas, Axis.horizontal)`).
- BREAKING: the canvas has no CSS style (Chart.js ADR 0200). `CssStyleProperties` and
  `UiCssStyleDeclaration` are gone: write `canvas.touchAction = CanvasTouchAction.none` and
  `canvas.userSelect = false` in place of `canvas.style.touchAction = 'none'` and
  `canvas.style.userSelect = 'none'`, and `canvas.displayWidth = 400` in place of
  `canvas.style.width = '400px'`. `HTMLCanvasElement.style` and `CSSStyleDeclaration` are gone: read
  `canvas.displayWidth` in place of `canvas.style.getPropertyValue('width')`, and `canvas.textDirection` in
  place of `canvas.style.getPropertyValue('direction')`. `setAttribute('style', ...)` of a canvas throws an
  `ArgumentError`.
- BREAKING: `ChartView.raw` and the raw Map config of `ChartView` are gone (Chart.js ADR 0198). `ChartView` takes
  only `ChartConfig`, and `ChartView.rawConfig` is gone: write `ChartView(config: ChartConfig(...))`, with
  `extra` for a Chart.js option that has no parameter. `new Chart(canvas, config)` still takes a Map config.
- BREAKING: the title and the subtitle options are one immutable object each, `TitleOptions` and
  `SubtitleOptions` (Chart.js ADR 0197). `ChartTitle` and the parameters `title` and `subtitle` of `ChartConfig`
  are gone: give `pluginOptions: [TitleOptions(display: true, text: ['Sales']), SubtitleOptions(...)]`, with each
  Chart.js title option as a field (`weight` too, where `ChartTitle` needed `extra`). A raw config holds the
  object in `options.plugins.title` or `options.plugins.subtitle`; a Map there stops a debug build. The
  scriptable form of the options is one function, `scripted: (context, options) => TitleOptions(...)`, which the
  plugin calls with the chart context once for each update. `TitleOptions.of` and `TitleOptionsScope` are gone,
  and the fields of `TitleOptions` are nullable. `ChartConfig ==` compares the objects with `==`: a new closure
  in `scripted` gives a chart update; give a tear-off.
- BREAKING: the legend options are one immutable object, `LegendOptions` (Chart.js ADR 0193). `ChartLegend`
  and `ChartConfig.legend` are gone: give `pluginOptions: [LegendOptions(...)]`, with each Chart.js legend
  option as a field; `labels` and `title` are a `LegendLabelOptions` and a `LegendTitleOptions`
  (`ChartLegend.labelColor`, `labelFont`, `labelPadding`, `boxWidth`, `boxHeight` and `usePointStyle` are
  `labels: LegendLabelOptions(color:, font:, padding:, boxWidth:, boxHeight:, usePointStyle:)`; the label
  `borderRadius` is a `BorderRadius`). A raw config holds the object in `options.plugins.legend`; a Map there
  stops a debug build. The scriptable form of the options is one function, `scripted: (context, options) =>
  LegendOptions(...)`, which the legend calls with the chart context once for each update. `LegendOptions.of`,
  `LegendOptions.view`, `LegendOptionsScope`, `LegendLabelOptionsScope` and `LegendTitleOptionsScope` are
  gone. `ChartConfig ==` compares the object with `==`: a new closure in it (a handler, a filter) gives a chart
  update, where `ChartLegend` compared its handlers by presence; give a tear-off.
- `ChartView.raw` is deprecated (Chart.js ADR 0195): use `ChartView(config: ChartConfig(...))`. The 0.1.0 release
  removes `ChartView.raw` and the raw Map config. Its behavior does not change in the beta.
- BREAKING: the tooltip options are one immutable object, `TooltipOptions` (Chart.js ADR 0192). `ChartTooltip`
  and `ChartConfig.tooltip` are gone: give `pluginOptions: [TooltipOptions(...)]`, with each Chart.js tooltip
  option as a field (`titleAlign`, `usePointStyle`, `boxPadding`, ...; `cornerRadius` is a `BorderRadius`). A
  raw config holds the object in `options.plugins.tooltip`; a Map there stops a debug build. The scriptable form
  of the options is one function, `scripted: (context, options) => TooltipOptions(...)`. `animation` takes a
  `TooltipAnimation` (`TooltipAnimation.off` for `false`) and `animations` the property items, with the new
  `CaretXAnimation`, `CaretYAnimation` and `OpacityAnimation`. `TooltipOptions.of` and `TooltipOptions.view`
  are gone. `ChartConfig ==` compares the object with `==`: a new closure in it gives a chart update, and
  `TooltipCallbacks` compare their functions.
- BREAKING: the decimation options are one immutable object, `DecimationOptions` (Chart.js ADR 0194): give
  `pluginOptions: [DecimationOptions(enabled: true, algorithm: LttbDecimationAlgorithm(), samples: 100)]`
  with `parsing: false`. A raw config holds the object in `options.plugins.decimation`; a Map there stops a
  debug build. `DecimationOptions.of`, `DecimationOptionsScope` and `DecimationAlgorithm.of` are gone, and
  `algorithm` takes only a `DecimationAlgorithm`.
- `ChartConfig` has `parsing` and `devicePixelRatio`.
- BREAKING: the filler and colors options are one immutable object each, `FillerOptions` and
  `ColorsPluginOptions` (Chart.js ADR 0196). `ChartFiller`, `ChartColors`, `ChartConfig.filler` and
  `ChartConfig.colors` are gone: give `pluginOptions: [FillerOptions(propagate: false),
  ColorsPluginOptions(forceOverride: true)]`. A raw config holds the objects in `options.plugins.filler` and
  `options.plugins.colors`; a Map there stops a debug build. `FillerOptions.of`, `ColorsPluginOptions.of`,
  `FillerOptionsScope`, `ColorsOptionsScope`, `themeBorderColorsKey` and `themeBackgroundColorsKey` are gone.
  The palette of a theme is the fields `borderColors` and `backgroundColors` of the `ColorsPluginOptions` that
  the theme writes; a palette in the options of a chart now comes over it.

## 0.1.0-beta.4

- The typed axes have no ids (Chart.js ADR 0191). `ChartConfig.scales` is a `List<ChartAxis>`, and
  a cartesian axis takes its direction first: `scales: [CategoryAxis(.x), LinearAxis(.y)]`. The
  chart gives the first axis of a direction the scale id `x`, `y` or `r`, and the next ones `x1`,
  `y1` and so on. A dataset names its axis by the axis object: `yAxis: right` replaces
  `yAxisID: 'right'`. `chart.scaleOf(axis)` and `chart.scaleIdOf(axis)` give the scale and the
  id of an axis.
- `ChartConfig` has no `type` (Chart.js ADR 0190): the class of the first dataset gives the chart
  type. A config needs one dataset at least; for a chart with no data yet, give a dataset with no
  data, for example `LineDataset(data: [])`.
- `Dataset` is an open base class (Chart.js ADR 0189): a package gives the typed dataset of its
  own chart type. `Dataset.copyWith` is gone; each dataset class keeps its own `copyWith`.
- Each built-in plugin is an instance of its own class, and `registry.getPlugin<T>()` finds a
  plugin by its class. The options of the built-in plugins and of the scales are typed classes
  (`TitleOptions`, `LegendOptions`, `TooltipOptions`, `CoreScaleOptions` and the scale classes).
- `Scale.setRange` and `Scale.clearRange` write and delete the range of a scale.
- The corner options hold a Flutter `BorderRadius`.
- Faster bar, scatter and line updates, and a faster hover search.
- The animation options have typed values: `duration` and `delay` a number of milliseconds,
  `loop` a `bool` and `fn` an `Interpolator`. A value of another type, for example a text
  duration, stops a debug build. The animation option `type` is gone: the Dart type of the value
  selects the interpolator, and `fn` gives another one.
- The scale option `display` and the radial `pointLabels.display` take a `ScaleDisplay`:
  `on` (the default), `off` or `auto`. The scale option `stacked` takes a `StackMode`: `on`,
  `off` or `single`, and null stacks only the datasets with a `stack`. The typed axes take the
  same enums: `LinearAxis(.y, display: ScaleDisplay.off, stacked: StackMode.on)`. A `bool` or a text
  stops a debug build.
- The bar option `inflateAmount` is a number. A bar with no value has the upstream `'auto'`.
- The `text` of the chart title, the subtitle, a scale title and the legend title is a
  `List<String>` of its lines: `ChartTitle(text: ['Sales'])`. A `String` stops a debug build.
- The options `borderDash`, `hoverBorderDash` and `tickBorderDash` hold a `List<double>`, also in a
  raw config: `'borderDash': <double>[5, 5]`.
- The bar option `barThickness` holds a `BarThickness`: `BarThickness.pixels(12)` or
  `BarThickness.flex`, also in a raw config. A number or a text stops a debug build.
- A scriptable option gets a typed context: `ScriptableContext` for a dataset option (`active`,
  `dataIndex`, `datasetIndex`, `parsed`, `raw`, `element`, `index`, `mode`, `chart`),
  `ScriptableScaleContext` for a scale or a tick (`scale`, `tick`, `index`), and
  `ScriptableChartContext`, `ScriptableScalePointLabelContext`, `ScriptableTooltipContext` and
  `ScriptableLineSegmentContext`. Declare the parameter with the class:
  `(ScriptableContext context) => (context.dataIndex ?? 1).isEven ? a : b`. A context has no
  access by name, and an absent member is `null`. `ChartContext` and `createContext` are gone:
  `ChartScript` takes a `ScriptableContext`.

## 0.1.0-beta.3

- A scale removes the ticks with no label in one pass. Before, the removal took a time
  quadratic in the tick count: a time axis of 30,000 ticks whose `ticks.callback` kept 6 of them
  took 1,259 ms for each update, and now takes 11 ms. The ticks and their order do not change.

## 0.1.0-beta.2

- The update mode is the extension type `UpdateMode`: `chart.update(UpdateMode.none)`, a custom
  mode `const UpdateMode('zoom')`, and `chart.updateDatasets((i) => ...)` for the function form.
  `ChartView.updateMode` takes an `UpdateMode` (Chart.js ADR 0148).

- `ChartPlugin<O>` gives the hooks the public `Chart`, with no cast. An add-on gives its options
  as one immutable `PluginOptions` object, and `ChartConfig.pluginOptions` sets the options of a
  chart: `ChartConfig(pluginOptions: [ZoomPluginOptions(...)])`. `Plugin.defaults` is a
  `PluginDefaults`, and the inline plugins of a raw config are a `List<Plugin<Object?>>`.

## 0.1.0-beta.1

- The first beta release. The API can still change before 0.1.0.

- A plugin is a native `Plugin<O>` with one typed field for each hook (Chart.js
  ADR 0144). A plugin Map is no longer a plugin: a Map in `plugins` or in
  `Chart.register` stops a debug build. A cancelable hook (`beforeUpdate`,
  `beforeDatasetsUpdate`, `beforeDatasetUpdate`, `beforeLayout`,
  `beforeRender`, `beforeDraw`, `beforeDatasetsDraw`, `beforeDatasetDraw`,
  `beforeEvent` and `beforeTooltipDraw`) returns `bool`, and `false` cancels.
  The hook arguments have typed fields and no `cancelable`.
  `chart.notifyPlugins` takes a `PluginHook`, and `ChartConfig.plugins` takes
  `List<Plugin<Object?>>`. `CancelableHookArgs`, `MapPlugin` and
  `isHookFunction` are removed:
  `Plugin<Object?>(id: 'probe', afterDraw: (chart, args, options) => draws++)`.

- The JS runtime of `js_semantics.dart` has no `canvasKeyword`, `jsTypeof` and
  `jsObjectIsFrozen`: no library code called them. Read the frozen state with
  the `isFrozen` getter of a `JsFreezable`, and test a type with `is`.

- `jsDateNow` is removed from `js_semantics.dart` and the app library. Read
  the time with `clock.now()` of package:clock, as the port does
  (`clock.now().millisecondsSinceEpoch`): the fake clock of `testWidgets` and
  `withClock` moves it.

- `jsMapForEach` and `js_map.dart` are removed from `js_semantics.dart` and the
  app library. The animator walks a copy of its chart list: a chart that an
  `onProgress` or `onComplete` callback creates gets its first animation frame
  one frame later, and a chart that a callback destroys gets no further tick.

- The port of @kurkle/color 0.3.2 is the package `flutter_kurkle_color_port`,
  with no JS runtime. The app library exports its public library with
  `hide Color, color`; `simpleColor`, `unpack` and the `interpolate` of
  `srgb.js` are no longer exported. `Color(null)` gives a color that is not
  valid.

- The scale option `border` holds one object, also in a raw configuration: an
  `AxisBorder` (`display`, `color`, `width`, `dash`, `dashOffset`, `z`) for a
  cartesian axis and a `RadialAxisBorder` (`dash`, `dashOffset`) for the radial
  linear axis. The scopes merge it field by field. The typed axes take it as
  `border`: `LinearAxis(border: const AxisBorder(display: false))`. A Map
  `border` stops a debug build.

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

- The line option `segment` holds a `LineSegmentStyle` of typed functions, in
  typed and raw configurations: `LineDataset(segment: LineSegmentStyle(
  borderColor: (s) => values[s.p1DataIndex] < values[s.p0DataIndex] ? red :
  null))`. Each function takes a `ScriptableLineSegmentContext` with typed
  `p0`, `p1`, `p0DataIndex`, `p1DataIndex` and `datasetIndex`, and `null`
  keeps the line style. `LineDataset`, `ScatterDataset`, `RadarDataset` and
  `LineElementStyle` have `segment`. A `segment` Map stops a debug build.

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
  an object by name through `JsObjectFace` (for example `(context as JsObjectFace)['dataIndex']`):
  a missing key reads `undefined`. A plugin hook reads its arguments through their typed fields
  (`args.event`).
  `Chart.data`, `Chart.config.data` and `Chart.config.options` are `Object` (the `Map` of a raw
  configuration, or a typed object), `Chart.options` is the options resolver, and the
  `Merger` and `InteractionModeFunction` types take `Object` targets and options.
- **Differences.** The README lists the differences from Chart.js that an app can see: the date
  formats, the Dart collection types of a raw configuration, the data array changes and the
  missing DOM.

## 0.0.1

- Initial scaffold. Tracks Chart.js 4.5.1. Nothing renders yet.
