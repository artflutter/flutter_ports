# flutter_chartjs_port

A native Dart port of [Chart.js](https://www.chartjs.org) 4.6.1 for Flutter. The Chart.js code
(scales, layout, dataset controllers, elements, plugins, animations) is translated to Dart and
draws with Flutter's own canvas, so a chart is a plain Flutter widget. There is no WebView, no
JavaScript engine and no network access at runtime, and the same code runs on every Flutter
platform.

This is not a wrapper. Packages such as [`chartjs_flutter`](https://pub.dev/packages/chartjs_flutter)
run the JavaScript Chart.js in a WebView on Android and iOS, or in a DOM canvas in an
`HtmlElementView` on the web. The
[prior-art survey](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_port/doc/prior-art/README.md)
compares the existing Chart.js packages.

## Incremental data updates

For frequently changing values, retain the data list used by the dataset, change
its values, and call `chart.updateData()` through the chart supplied to
`onChartCreated`. Keep record implementations, keys and numeric value kinds unchanged within an
existing array. Same-length replacement arrays are checked again. The method
returns true when it selected the incremental lifecycle, or false when it used
`update('none')`. Cancellation by plugins is separate from that return value.

Keep options, labels, dataset structure and visibility unchanged. Use explicit
numeric scale bounds and reusable or native indexed styles; call the normal
`update()` when other inputs change. Native numeric buffers and prepared numeric
points are supported.
Unsupported scales/components/styles or unapproved plugins fall back. Layout,
interaction and plugin details are in
[ADR 0074](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_port/doc/adr/0074-incremental-data-updates.md).
Widget configuration changes still use the normal full update by default. For a
typed `ChartView` that gets a new data List in each frame, `dataOnlyUpdates: true`
calls `updateData` when only the data Lists of a new config changed. It needs
`updateMode: 'none'` and `animation: ChartAnimation.none`, and its doc states
what it does not re-run.

After a change of the `min` and `max` options of the scales only, written
through `setRange` or deleted through `clearRange`
(`chart.scales['x']!.setRange(min: 10, max: 20)`),
`chart.updateRanges()` skips the rebuild of the configuration and gives the
result of `chart.update()`. Change nothing else in place between full updates.
The zoom port uses it with its option `rangeOnlyUpdates`
([Chart.js ADR 0111](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_port/doc/adr/0111-range-updates.md)).

## Features

- The eight chart types of Chart.js: bar, bubble, doughnut, line, pie, polar area, radar and
  scatter, also as mixed and area charts.
- The six scales: category, linear, logarithmic, time, timeseries and radial linear.
- The seven plugins: colors, decimation, filler, legend, subtitle, title and tooltip.
- A typed Dart API: `ChartConfig`, one dataset class for each chart type, typed axes and option
  groups, Flutter values (`Color`, `TextStyle`, `Duration`, `EdgeInsets`) and callbacks with
  `int` indexes.
- Animations, hover, tooltips and legend clicks with a mouse, a touch screen or the keyboard.
- A theme API with light and dark presets, a semantics node for screen readers, and reduced
  motion.
- Plain Dart and Flutter code with no platform code, so it builds for each Flutter platform:
  Android, iOS, web (JavaScript and WebAssembly builds), macOS, Windows and Linux. The CI of the
  repository runs the tests with `flutter test` on Linux, macOS and Windows, and in Chrome with
  dart2js and dart2wasm. It builds the gallery app for the web (WebAssembly), Android and iOS. The
  gallery also runs on macOS. No app build runs on Windows or Linux yet.

Each source file of Chart.js has a row in the
[parity tracker](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_port/doc/parity.md).
The ported Jasmine specs of Chart.js run in the CI of the repository.

## Install

```sh
flutter pub add flutter_chartjs_port
```

The package needs Flutter 3.47 and Dart 3.13 or later.

## Usage

```dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

void main() {
  // Chart.js registers nothing by itself. Register the components first.
  Chart.register(registerables);
  runApp(const MaterialApp(home: Scaffold(body: VotesChart())));
}

class const VotesChart({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const ChartView(
      semanticLabel: 'Bar chart of the votes for six colors',
      config: ChartConfig(
        labels: ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
        datasets: [
          BarDataset(
            label: '# of Votes',
            data: .values([12, 19, 3, 5, 2, 3]),
            borderWidth: 1,
          ),
        ],
        scales: [LinearAxis(.y, beginAtZero: true)],
      ),
    );
  }
}
```

`ChartView(config: ChartConfig(...))` shows one chart. Each parameter of the typed config names
its Chart.js option in its documentation: `scales` is `options.scales`, `legend` is
`options.plugins.legend`, and so on. A parameter that you leave out keeps the Chart.js default.
A typed config can be `const`.

[`example/main.dart`](example/main.dart) is a complete app with a data update and a click
callback. The gallery app of the repository,
[`apps/chartjs_gallery`](https://github.com/artflutter/flutter_ports/tree/main/apps/chartjs_gallery),
shows each chart type of the Chart.js docs.

### Datasets and data

Each chart type has its dataset class. The class of the first dataset gives the chart type, so a
config has no `type`:

| Chart | Dataset class |
|---|---|
| Bar | `BarDataset` |
| Line and area | `LineDataset` |
| Scatter | `ScatterDataset` |
| Bubble | `BubbleDataset` |
| Pie | `PieDataset` |
| Doughnut | `DoughnutDataset` |
| Polar area | `PolarAreaDataset` |
| Radar | `RadarDataset` |

A chart needs one dataset at least. For a chart with no data yet, give a dataset with no data, for
example `LineDataset(data: .values([]))`. A dataset of another class than the first makes a
mixed chart: the first dataset gives the chart-level defaults, for example the default axes:

```dart
ChartConfig(
  labels: const ['Jan', 'Feb', 'Mar', 'Apr'],
  datasets: [
    BarDataset(
      label: 'Orders',
      data: .values(orders),
      backgroundColor: .constant(.solid(Colors.orange)),
    ),
    LineDataset(
      label: 'Visitors',
      data: .values(visitors),
      borderColor: .constant(.solid(Colors.blue)),
      backgroundColor: .constant(.solid(Colors.blue.withValues(alpha: 0.2))),
      fill: .toOrigin,
      tension: 0.3,
      pointStyle: const .constant(RectRotPointStyle()),
    ),
  ],
)
```

The `data` of a bar, line or scatter dataset is a `DatasetData` in one of two forms.
`.values(...)` takes a `List<num?>` with one value for each label, and `null` is a gap.
`.points(...)` takes a `List<DataPoint>` with `x` and `y` values. The `data` of a bubble dataset
is a `List<DataPoint>` with the radius `r` of each bubble. A `DataPoint.time` needs a `TimeAxis` for `x` ([Axes](#axes)):

```dart
ScatterDataset(
  label: 'Readings',
  data: .points([DataPoint(1, 3), DataPoint(2, 5.5), DataPoint(4, 2)]),
)
BubbleDataset(
  label: 'Cities',
  data: [DataPoint.bubble(20, 30, 15), DataPoint.bubble(40, 10, 10)],
)
LineDataset(
  label: 'Temperature',
  data: .points([
    DataPoint.time(DateTime.utc(2026, 3, 2), 3),
    DataPoint.time(DateTime.utc(2026, 3, 3), 5),
  ]),
)
```

The values of the options are Dart and Flutter values:

- Dataset background, border, hover and point-specific colors take
  `ChartValue<ChartPaint>`: `.constant(.solid(color))` for one paint,
  `.indexed(paints)` for a repeating list, or `.resolver(callback)` for a paint
  calculated from each item's context. Scalar paint fields take `ChartPaint`.
  Use `.solid(color)`, `ChartGradient.linear(...)` or `ChartPattern(image)`.
  Shadow colors, theme tokens, palette entries and gradient stops remain `Color`.
- Fonts are `TextStyle` values: the chart lays out each text with the whole style, and the
  line height is `fontSize * height`. A font can be a `ChartTextStyle`, a `TextStyle` with the
  field `lineHeight`. The chart does not read the
  color of a `TextStyle`: each font parameter has a color parameter next to it, for example
  `labelFont` and `labelColor`.
- The legend and tooltip `textDirection` options take `TextDirection` values. Each override is restored after drawing; omitting it keeps the current canvas direction.
- Durations are `Duration` values, and paddings are `EdgeInsets` values.
- A pie or doughnut `cutout` or `radius` is a `RadiusLength`: `const PercentRadius(50)` or
  `const PixelRadius(80)`. A scale `grace` is a `GraceLength`: `const PercentGrace(5)` or
  `const ValueGrace(0.3)`.
- Names are dot shorthands: `position: .bottom`, `fill: .toOrigin`.
- A point style is a class: `pointStyle: const .constant(StarPointStyle())`. An app or a plugin
  can add its own style as a subclass of `PathPointStyle`. The point radius, the hover radius and
  the point style of a line, scatter or radar dataset take a `ChartValue`, as the colors do:
  `pointRadius: .indexed([0, 4, 0])` or `pointStyle: .resolver(styleOf)`. The cubic interpolation mode of a line is a class
  too: `cubicInterpolationMode: const MonotoneCubicInterpolationMode()`.
- A fill is a `FillTarget`: `.none`, `.toOrigin`,
  `.toStart`, `.toEnd`, `.toStacked`, `.shape`, `.toPrevious`, `.toNext`, `.toDataset(0)`,
  `.toRelative(-2)` and `.toValue(10)`. `FillTarget.toOrigin.split(above: green, below: red)`
  gives the fill its own colors above and below the target.
- The `easing` of an animation is a Flutter `Curve`: a constant of `Curves`, or a curve class of
  your app.
- `animations` sets the animation of single properties. Each property has its class:
  `animations: [RadiusAnimation(easing: Curves.elasticOut), YAnimation.off()]`.

Dataset color migration:

| Previous parameter | Replacement |
|---|---|
| `backgroundColor: color` | `backgroundColor: .constant(.solid(color))` |
| `backgroundColors: colors` | `backgroundColor: .indexed(paints)` |
| `backgroundColorFor: callback` | `backgroundColor: .resolver(callback)` |
| `borderColor: color` | `borderColor: .constant(.solid(color))` |
| `borderColors: colors` | `borderColor: .indexed(paints)` |
| `borderColorFor: callback` | `borderColor: .resolver(callback)` |

Omit a dataset color to inherit its default. `copyWith(backgroundColor: ...)`
and `copyWith(borderColor: ...)` independently switch between the three forms;
a `null` copy argument retains the current form. Indexed style lists are copied
when lowered, and callbacks should use a stable tear-off when possible.
Hover and point-specific dataset colors use the same variants. Element-style
colors take `ChartPaint` directly. The scriptable options of an axis take a `ScaleValue`
(`.constant`, `.indexed` or `.resolver` of a `ScriptableScaleContext`).

Each dataset class takes a `shadow`. The lines, the points, the bars and the arcs of the dataset
cast it. The area fill of a line does not. `blur` is the `shadowBlur` of the canvas: the Gaussian
sigma of the blur is half of it.

```dart
LineDataset(
  data: .values([12, 19, 3, 5, 2, 3]),
  shadow: ChartShadow(
    color: Color(0x59000000),
    blur: 8,
    offset: Offset(0, 3),
  ),
)
```

A shadow is not a Chart.js option. `ChartView` draws it.

### Axes

`scales` is the List of the axes. A cartesian axis takes its direction first, `.x` or `.y`. A chart
type has default axes, so give only the axes with other options. The order of the List is the
order of the axes in the layout.

```dart
ChartConfig(
  labels: labels,
  datasets: datasets,
  scales: const [
    CategoryAxis(.x, grid: AxisGrid(display: false)),
    LinearAxis(
      .y,
      beginAtZero: true,
      ticks: AxisTicks(stepSize: 5, callback: formatVotes),
      title: AxisTitle(display: true, text: ['Votes']),
    ),
  ],
)
```

with a top-level function or a method as the tick callback:

```dart
List<String>? formatVotes(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => ['${value.round()} votes'];
```

The result is the lines of the label. A `null` result removes the tick, and an empty list keeps
the tick with no label. The axes are `CategoryAxis`, `LinearAxis`, `LogarithmicAxis`,
`TimeAxis`, `TimeSeriesAxis` and `RadialLinearAxis` (the axis `r` of a radar or polar area chart).
A `TimeAxis` takes `DateTime` limits and a `unit`, for example `TimeAxis(.x, unit: .day)`.

A dataset names its axis by the axis object. Keep the axis in a variable and give it in both
places:

```dart
const right = LinearAxis(.y, position: .right);

ChartConfig(
  labels: labels,
  datasets: [
    LineDataset(label: 'Sales', data: .values(sales)),
    LineDataset(label: 'Margin', data: .values(margin), yAxis: right),
  ],
  scales: const [LinearAxis(.y), right],
)
```

The axes of a List are distinct by `==`. The chart gives the first axis of a direction the scale
id `x`, `y` or `r`, and the next ones `x1`, `y1` and so on. `chart.scaleOf(right)` gives the scale
of an axis.

### Option groups

The option groups are parameters of `ChartConfig`:

```dart
ChartConfig(
  labels: labels,
  datasets: datasets,
  padding: const EdgeInsets.all(8),
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  animation: const ChartAnimation(
    duration: Duration(milliseconds: 400),
    easing: Curves.easeOutQuart,
  ),
  elements: const ChartElements(bar: BarElementStyle(borderRadius: 4)),
  pluginOptions: const [
    TitleOptions(display: true, text: ['Votes']),
    LegendOptions(
      position: ChartPosition.bottom,
      labels: LegendLabelOptions(font: TextStyle(fontSize: 12)),
    ),
    TooltipOptions(
      backgroundColor: .solid(Colors.black87),
      cornerRadius: BorderRadius.all(Radius.circular(4)),
    ),
  ],
)
```

The options of the built-in plugins are one object each in `pluginOptions`, as the options of an
add-on plugin: `TitleOptions`, `SubtitleOptions`, `LegendOptions`, `TooltipOptions`,
`DecimationOptions`, `FillerOptions` and `ColorsPluginOptions`. Each Chart.js option is a field, and
the legend `labels` and `title` are a `LegendLabelOptions` and a `LegendTitleOptions`.
`ChartConfig ==` compares them with `==`, so a new closure in them (a callback or `scripted`)
gives a chart update; give a tear-off of a function or a method. `scripted` gives the options that
depend on the context: `scripted: (context, options) => TooltipOptions(backgroundColor: ...)` with
the tooltip context, and `LegendOptions(scripted: ...)`, `TitleOptions(scripted: ...)` and
`SubtitleOptions(scripted: ...)` with the chart context, once for each update.

`SubtitleOptions(display: true, text: ['2026'])` adds a subtitle under the title, and
`animation: ChartAnimation.none` turns the animations off. `indexAxis: const YAxis()` gives a
horizontal bar chart: the index axis takes `XAxis` or `YAxis` only. `responsive`, `maintainAspectRatio` and `aspectRatio` set the [size](#size).

### Callbacks

The callbacks are typed functions, with `int` indexes:

```dart
class const VotesPage({super.key}) extends StatefulWidget {
  @override
  State<VotesPage> createState() => _VotesPageState();
}

class _VotesPageState() extends State<VotesPage> {
  final List<num> _votes = [12, 19, 3, 5, 2, 3];

  void _onClick(ChartEvent event, List<ActiveElement> hits, Chart chart) {
    final hit = hits.firstOrNull;
    if (hit == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_votes[hit.index]} votes')),
    );
  }

  void _onLegendClick(
    ChartEvent event,
    LegendItem item,
    LegendElement legend,
  ) {
    final index = item.datasetIndex;
    if (index == null) return;
    // The Chart methods take the int index.
    final chart = legend.chart;
    if (chart.isDatasetVisible(index)) {
      chart.hide(index);
    } else {
      chart.show(index);
    }
  }

  List<String> _label(TooltipModel tooltip, TooltipItem item) =>
      ['${item.datasetLabel}: ${item.formattedValue} votes'];

  ChartPaint _barColor(ScriptableContext context) =>
      .solid((context.raw as num? ?? 0) > 10 ? Colors.green : Colors.grey);

  @override
  Widget build(BuildContext context) {
    return ChartView(
      config: ChartConfig(
        labels: const ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
        datasets: [
          BarDataset(
            label: '# of Votes',
            data: .values(_votes),
            backgroundColor: ChartValue.resolver(_barColor),
          ),
        ],
        onClick: _onClick,
        pluginOptions: [
          LegendOptions(onClick: _onLegendClick),
          TooltipOptions(callbacks: TooltipCallbacks(label: _label)),
        ],
      ),
    );
  }
}
```

- `onClick` and `onHover` are a `ChartEventHandler`: they get the chart event, the elements under
  the pointer (a list of `ActiveElement`, each with an `int` `datasetIndex`, an `int` `index` and
  the `element`) and the chart. The chart option `onResize` is a `ChartResizeHandler`: it gets the
  chart and its new `Size`. `chart.setActiveElements` takes the same class:
  `ActiveElement(datasetIndex: 0, index: 2)`.
- The legend `onClick`, `onHover` and `onLeave` are a `LegendEventHandler`: they get the event, the
  item and the legend. A legend `onClick` replaces the default click, which hides or shows the
  dataset. The item is the same mutable
  `LegendItem` used by rendering, with `List<String>` text, native `ChartPaint` styles and nullable
  integer indexes. A custom `labels.generateLabels` is a `LegendLabelsGenerator`, which returns a
  `List<LegendItem>`; `labels.filter` and `labels.sort` are a `LegendItemFilter` and a
  `LegendItemComparator`. Plugins can extend or
  implement the class. Its `copyWith` and `merge` methods are overridable.
  `legend.legendHitBoxes` exposes native `LegendHitBox` objects with mutable geometry, integer
  row/column membership, and overridable `contains`, `center`, `copyWith` and `merge`.
  The `equalsTo` extension compares hit-box fields explicitly; `==` retains identity equality.
- `TooltipOptions.callbacks` takes a `TooltipCallbacks` object. Its text
  hooks return a list of lines: `null` requests the built-in default and `[]` emits no text.
  Each callback receives the tooltip model and its item or item list. Dataset `tooltipCallbacks`
  override the six per-item hooks. Callback objects merge field by field with `merge`.
- `AxisTicks.callback` is a `TickCallback`: it gets the scale, the value, the index and all ticks,
  and gives the lines of the tick label. `ChartAnimation.onProgress` and `onComplete` are an
  `AnimationEventHandler`: they get the `AnimationEvent` of the animator.
- The scale hooks of an axis (`beforeUpdate` to `afterFit`) are a `ScaleHook`, which gets the
  scale; `TimeAxis.parserFunction` is a `TimeParser`; and
  `RadialLinearAxis.pointLabelsCallback` is a `PointLabelCallback`, which gets the label and its
  `int` index.
- A dataset's `backgroundColor: ChartValue.resolver(...)` and `borderColor: .resolver(...)` get a
  `ScriptableContext` (`dataIndex`, `datasetIndex`, `raw`, `parsed`, `active`, `mode`, `chart`)
  for each element, and an axis `.resolver(...)` gets a `ScriptableScaleContext`. A context has
  typed members only: an absent member is `null`.

The chart methods take `int` indexes: `chart.hide(hit.datasetIndex)`,
`chart.isDatasetVisible(index)`, `chart.getDatasetMeta(index)`. The callbacks run in the phases of
[Callbacks and `setState`](#callbacks-and-setstate).

### Updates

Build the config in `build`. A new config that is `==` to the last one gives no update, so a
parent can rebuild as often as it likes. Another config updates the chart after the frame, with
the animations of Chart.js:

```dart
class _ScoresState() extends State<Scores> {
  List<num> _scores = [3, 7, 4];

  void _next() => setState(() {
    _scores = [for (final score in _scores) score + 1];
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChartView(
          config: ChartConfig(
            labels: const ['A', 'B', 'C'],
            datasets: [BarDataset(label: 'Score', data: .values(_scores))],
          ),
        ),
        TextButton(onPressed: _next, child: const Text('Next')),
      ],
    );
  }
}
```

- `==` compares the data Lists by identity, not item by item. For new data, give a new List, as
  `_next` does. Or change the List in place and call `chart.update()` from an event handler
  (`onChartCreated` gives you the `Chart`).
- A Dart `List` has no methods that Chart.js can hook, so the chart does not see a `push`, `pop`,
  `shift`, `splice` or `unshift` on a data List. After a change in place, call
  `notifyArrayListeners` and then `chart.update()`:

  ```dart
  votes.add(7);
  notifyArrayListeners(votes, 'push', [7]);
  chart.update();
  ```

  Without the notification, `update()` still shows the new data, but an insert or a removal at
  the start or in the middle does not animate as in Chart.js.
- A dataset without a `key` keeps its state (its hidden state and its animations) when the next
  config has a dataset of the same class, also without a key, at the same index. When the app
  adds, removes or reorders datasets, give each dataset a `key`, as for the children of a
  `Column`: then the state follows the key.

  ```dart
  datasets: [
    for (final series in visibleSeries)
      LineDataset(
        key: ValueKey(series.id),
        label: series.name,
        data: .values(series.values),
      ),
  ],
  ```
- The event and text callbacks (`onClick`, `onHover`, the legend handlers, the tooltip texts and
  the animation callbacks) can be new closures in each build: the chart calls the callback of the
  newest config. A scriptable color (`ChartValue.resolver(...)`) and a tick callback
  are values of the config: give a method tear-off or a top-level function, because
  a new closure in each build is a new value and updates the chart.
- Change the config, not the Maps of the chart (`chart.data`, `chart.options`): the next config
  writes its options again. A change of `chart.options` in place lasts until a config with other
  options.
- `updateMode` sets the mode of the update, for example `updateMode: 'none'` for no animation.

### The second form of an option

Some Chart.js options take two forms. The typed config gives the second form its own parameter,
and a config gives one of the two:

```dart
ChartConfig(
  labels: labels,
  datasets: [
    BarDataset(
      label: 'Range',
      data: .ranges([(1, 5), (2, 6)]),
      borderRadiusCorners: const BorderRadius.vertical(top: Radius.circular(4)),
    ),
  ],
  datasetDefaults: [const BarDataset(borderWidth: 1)],
  locale: const Locale('de', 'DE'),
)
```

The pairs are `borderRadius` and `borderRadiusCorners`, `borderWidth`, `borderWidths` and
`borderWidthSides`, `spanGaps` and `spanGapsDistance`, the `min` and `max` of a `CategoryAxis` and
`minIndex` and `maxIndex`, `parser` and `parserFunction` of a time axis, and `border` and
`borderFunction` of an axis. The options of all datasets of a type go in
`ChartConfig.datasetDefaults`.

### Registration

As the `chart.js` package of npm, the library registers nothing. Register the components before
the first chart. `Chart.register(registerables)` registers all controllers, elements, scales and
plugins. To keep a web build small, register only the components of your chart types, as the
[integration guide](https://www.chartjs.org/docs/4.6.1/getting-started/integration.html#bundle-optimization)
of Chart.js lists them. A component is its class value (`jsClass`), and a plugin is its plugin
object:

```dart
Chart.register([
  LineController.jsClass,
  LineElement.jsClass,
  PointElement.jsClass,
  CategoryScale.jsClass,
  LinearScale.jsClass,
  legend,
  tooltip,
]);
```

The plugin objects are `colors`, `decimation`, `filler`, `legend`, `subTitle`, `title` and
`tooltip`. A chart of a type that is not registered does not start: `ChartView` reports the
Chart.js error, for example `"line" is not a registered controller.`, to `FlutterError.onError`.
The default dataset colors and the palette of a theme come from the `colors` plugin.

### Size

`ChartView` has no size parameter. The constraints and the options `responsive`,
`maintainAspectRatio` and `aspectRatio` give the size:

| Parent | Options | Size |
|---|---|---|
| `Column` or a scroll view | the defaults | the width, and the height from `aspectRatio` (2, or 1 for doughnut, pie, polar area and radar) |
| `SizedBox(height: ...)` or `Expanded` | `maintainAspectRatio: false` | the box |

In a `Row`, the width is unbounded: put the chart in an `Expanded` or give it a width.

### Callbacks and `setState`

Each callback of a chart runs in one phase of the Flutter frame, and only some phases allow
`setState`. The typed callbacks run where the Chart.js callbacks of the same name run:

| Callback | Phase | `setState` |
|---|---|---|
| `onHover`, `onClick`, the legend handlers, and the plugin hooks `beforeEvent` and `afterEvent` of an input | a frame callback after the input | allowed |
| `onResize` and the plugin hook `resize` after a size change | a frame callback | allowed |
| `onProgress` and `onComplete` of an animation, and the plugin hook `afterRender` | a frame callback of the animator | allowed |
| all hooks of an update of the widget (a new config, a new theme or a new reduced-motion setting), and the `onHover` that the update replays | a post-frame callback | allowed |
| `onChartCreated` | a post-frame callback | allowed |
| the start of the chart: the plugin hooks `install`, `start`, `beforeInit` and `afterInit`, the hooks and the scriptable options of the first update, the first `onResize` and `resize`, and the `onComplete` of a first render with no animation (each first render under [reduced motion](#reduced-motion)) | the first layout of the chart | not allowed |
| the plugin hooks `attach` and `detach` when the chart attaches to or detaches from its host | a layout or a build | not allowed |
| the plugin hooks `beforeDestroy`, `afterDestroy`, `stop` and `uninstall` when the widget leaves the tree | `dispose` | not allowed |

In a phase that does not allow `setState`, call `WidgetsBinding.instance.addPostFrameCallback`
and call `setState` in its callback. In debug mode, a `setState` call in the start fails with
`Build scheduled during frame.`, and the chart does not start.

### Theming

Without a theme, a chart looks as in Chart.js. A theme replaces the default colors and fonts of
Chart.js. It never changes `Chart.defaults`, and the options of the chart beat the theme key by
key.

```dart
MaterialApp(
  builder: (context, child) => ChartTheme(
    data: Theme.of(context).brightness == Brightness.dark
        ? const ChartThemeData.dark()
        : const ChartThemeData.light(),
    child: child!,
  ),
  home: const Scaffold(body: VotesChart()),
);
```

- `ChartTheme` gives a theme to the charts of a subtree. `ChartView.theme` sets the theme of one
  chart, and `theme: const ChartThemeData()` turns theming off for one chart.
- `const ChartThemeData.light()` holds the Chart.js defaults: a chart with it looks as a chart
  without a theme. `const ChartThemeData.dark()` mirrors the light colors. Set `surface` with
  `copyWith` for a background other than black.
- The tokens are 6 colors (`color`, `borderColor`, `backgroundColor`, `surface`,
  `inverseSurface` and `onInverseSurface`), 2 fonts (`font` and `pointLabelsFont`, as
  `TextStyle`) and the `palette` of the `colors` plugin with `paletteBackgroundAlpha`.
- The palette colors only datasets with no colors, and only when the `colors` plugin is
  registered. The defaults of a chart type (`overrides`) beat the theme.
- A new theme switches the chart after the frame. The element colors animate for 200 ms, and the
  scales, the legend, the title and the tooltip switch at once. The chart keeps its datasets and
  hidden datasets. It loses a change in place of `chart.options.scales`.

### Keyboard, focus and semantics

The chart is one focus stop. With the focus, the arrow keys move a virtual mouse over the legend
items and the data elements: Right and Left move in a group, Down and Up move to the next or the
previous group (the legend, then each visible dataset), and Home and End move to the ends of the
group. Enter and Space click at the target, and Escape clears the hover. Thus the tooltip, the
hover mode, `onHover`, `onClick` and the legend callbacks give the results of a mouse at that
point. A focus ring in the color of `options.color` shows the focus in the traditional
highlight mode. Use `focusNode` and `autofocus` as for other focusable widgets, and wrap the
chart in `ExcludeFocus` to remove the focus stop.

For screen readers, the chart is one node with the image flag and the text of `semanticLabel`,
as a Chart.js canvas with `role="img"` and `aria-label`. Give each chart a label.
`excludeFromSemantics: true` removes the node. The node does not change at a data update.

### Reduced motion

When `MediaQuery.disableAnimations` is true (for example when the platform setting to reduce
motion is on), the chart animates nothing: each update, hover, tooltip and theme switch goes to
its end values at once, and `onComplete` runs once for each render. The `onComplete` of the
first render then runs in the start of the chart, where it must not call `setState`
([Callbacks and `setState`](#callbacks-and-setstate)). For motion under the setting, wrap the
chart in a `MediaQuery` with `disableAnimations: false`.

## Canvas drawing and paints

Custom canvas drawing uses `CanvasCompositeOperation` for
`chart.ctx.globalCompositeOperation`, for example
`CanvasCompositeOperation.destinationOver` instead of `'destination-over'`.
The enum is available from both public chart libraries and needs no `dart:ui`
import. A null assignment leaves the native canvas operation unchanged.

Paint options use `ChartPaint` in the typed API. CSS color strings such as
`'red'`, `'#36A2EB'` and `'rgba(54, 162, 235, 0.5)'`, and bare Flutter colors,
are rejected. Use `const ChartPaint.solid(Color(0xFF36A2EB))` instead.
Lists contain paints and scriptable callbacks return paints. Gradient stops,
shadow colors and theme tokens remain Flutter `Color` values.

## Libraries

| Library | Contents |
|---|---|
| `package:flutter_chartjs_port/flutter_chartjs_port.dart` | The library of an app: `ChartView`, the typed API (`ChartConfig`, the dataset classes, the axes and the option groups), `ChartTheme`, `ChartThemeData`, and the Chart.js API: `Chart`, the controllers, elements, scales and plugin objects, `registerables`, `defaults`, the types of the callbacks, the date zone functions, `notifyArrayListeners` and `undefined`. It leaves out `Animation` and `Element`, two names that Flutter also has, so an app imports it next to `material.dart` with no prefix. |
| `package:flutter_chartjs_port/chartjs.dart` | The `chart.js` entry of npm, for code that extends Chart.js (a plugin, a controller or a scale): the whole Chart.js API with `Animation` and `Element`, the Canvas 2D interface that a plugin draws on (`chart.ctx`), `ChartMeta`, `JsClass` (the class value of a subclass) and `JsObjectFace` (the read by name of an object of the chart). It has no typed API. Next to Flutter, import it with a prefix or with `hide Animation, Element`. |
| `package:flutter_chartjs_port/helpers.dart` | The `chart.js/helpers` entry: the public helpers of Chart.js. An upper case constant has a lowerCamelCase name: `PI` is `pi`. Import it with a prefix. |

`ChartConfig` is the typed config of a `ChartView`. `ChartConfiguration` is another type: the
interface of `chart.config`, the configuration of a live chart. `chartJsVersion` gives the version
of Chart.js that the package ports.

## Differences from Chart.js

The port gives the results of Chart.js 4.6.1 where they change what a user sees or what an
app reads. These differences are visible to an app:

- **Dates.** Chart.js needs a date adapter package for the time scales. The port has a built-in
  adapter with the rules of chartjs-adapter-moment 1.0.1 on moment 2.29.4. Its format strings
  (`time.displayFormats`, `time.tooltipFormat`, `time.parser`) are ICU patterns of
  `DateFormat` of package:intl, not moment tokens: write `'MMM d, yyyy'`, not `'MMM D, YYYY'`.
  The adapter uses local time. `setDefaultDateZone('Etc/UTC')` selects UTC for all charts, and
  `setDefaultDateZone(null)` selects local time again. The package has no other zones. A string
  that is not an ISO 8601, RFC 2822 or ASP.NET JSON date parses as an invalid date. The dates
  use the locale of package:intl (`Intl.defaultLocale`). A locale other than `en_US` needs
  `initializeDateFormatting` of package:intl first; else the dates use `en_US`. In local time,
  dates before 1901 and after 2038 can have other offsets than in a browser on native platforms
  and in WebAssembly builds.
- **Numbers.** Tick labels and tooltips format numbers with `NumberFormat` of package:intl. A few
  strings differ from `Intl.NumberFormat` of a browser, for example in compact notation.
- **Data changes.** A `push`, `pop`, `shift`, `splice` or `unshift` on a data List needs
  `notifyArrayListeners` ([Updates](#updates)).
- **No DOM and no CSS.** The CSS of the canvas and of its container (margins, paddings, borders,
  `max-width`, `max-height`) does not exist: use Flutter layout, for example `Padding` and
  `ConstrainedBox`. The canvas has only the members of the Canvas 2D API that Chart.js uses: a
  plugin cannot read or set the shadow attributes. `chart.toBase64Image()` returns a
  `Future<String>` with a PNG data URL. The input events have the names of the DOM events of
  Chrome (`mousemove`, `click`, `mouseout` and the touch events) for `options.events`, and a tap
  also gives the mouse events of a browser.
- **No global object.** The library has no `window.Chart` and no UMD bundle. Import the helpers
  from `helpers.dart`.

The [full list](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_port/doc/differences.md)
gives each difference with its reason and its test, for example the rows
[`js-semantics-narrow-datasets`](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_port/doc/differences.md#js-semantics-narrow-datasets),
[`platform-array-events`](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_port/doc/differences.md#platform-array-events)
and
[`adapt-date-moment-format`](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_chartjs_port/doc/differences.md#adapt-date-moment-format).

## Upstream and license

The package ports Chart.js **4.6.1** (`chartJsVersion`). The upstream sources are a git
submodule of the [repository](https://github.com/artflutter/flutter_ports), for reference only.
Chart.js is MIT-licensed by the Chart.js Contributors. The colors go through the package
[flutter_kurkle_color_port](https://pub.dev/packages/flutter_kurkle_color_port), a port of
[@kurkle/color](https://github.com/kurkle/color) 0.3.2 (MIT, Jukka Kurkela) with its own LICENSE.
All notices of this package are in [LICENSE](LICENSE). This project is not affiliated
with the Chart.js project.
