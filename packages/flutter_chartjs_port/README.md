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

## Features

- The eight chart types of Chart.js: bar, bubble, doughnut, line, pie, polar area, radar and
  scatter, also as mixed and area charts.
- The six scales: category, linear, logarithmic, time, timeseries and radial linear.
- The seven plugins: colors, decimation, filler, legend, subtitle, title and tooltip.
- A typed Dart API: `ChartConfig`, one dataset class for each chart type, typed axes and option
  groups, Flutter values (`Color`, `TextStyle`, `Duration`, `EdgeInsets`) and callbacks with
  `int` indexes.
- The raw Chart.js configuration as a Dart `Map` (`ChartView.raw`), for a copy of the Chart.js
  docs or `jsonDecode` output: the same keys, the same defaults and the same results.
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
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

void main() {
  // Chart.js registers nothing by itself. Register the components first.
  Chart.register(registerables);
  runApp(const MaterialApp(home: Scaffold(body: VotesChart())));
}

class VotesChart extends StatelessWidget {
  const VotesChart({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChartView(
      semanticLabel: 'Bar chart of the votes for six colors',
      config: ChartConfig(
        type: .bar,
        labels: ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
        datasets: [
          BarDataset(
            label: '# of Votes',
            data: [12, 19, 3, 5, 2, 3],
            borderWidth: 1,
          ),
        ],
        scales: {'y': LinearAxis(beginAtZero: true)},
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

`type` names the chart type, and each chart type has its dataset class:

| Chart | `type` | Dataset class |
|---|---|---|
| Bar | `.bar` | `BarDataset` |
| Line and area | `.line` | `LineDataset` |
| Scatter | `.scatter` | `ScatterDataset` |
| Bubble | `.bubble` | `BubbleDataset` |
| Pie | `.pie` | `PieDataset` |
| Doughnut | `.doughnut` | `DoughnutDataset` |
| Polar area | `.polarArea` | `PolarAreaDataset` |
| Radar | `.radar` | `RadarDataset` |

A dataset of another class than the chart type makes a mixed chart, as the `type` of a Chart.js
dataset does:

```dart
ChartConfig(
  type: .bar,
  labels: const ['Jan', 'Feb', 'Mar', 'Apr'],
  datasets: [
    BarDataset(label: 'Orders', data: orders, backgroundColor: Colors.orange),
    LineDataset(
      label: 'Visitors',
      data: visitors,
      borderColor: Colors.blue,
      backgroundColor: Colors.blue.withValues(alpha: 0.2),
      fill: .origin,
      tension: 0.3,
      pointStyle: .rectRot,
    ),
  ],
)
```

`data` is a `List<num?>` with one value for each label, and `null` is a gap. A bar, line,
scatter or bubble dataset takes `points` instead: a `List<DataPoint>` with `x` and `y` values,
and the radius `r` of a bubble. A `DataPoint.time` needs a `TimeAxis` for `x` ([Axes](#axes)):

```dart
ScatterDataset(
  label: 'Readings',
  points: [DataPoint(1, 3), DataPoint(2, 5.5), DataPoint(4, 2)],
)
BubbleDataset(
  label: 'Cities',
  points: [DataPoint.bubble(20, 30, 15), DataPoint.bubble(40, 10, 10)],
)
LineDataset(
  label: 'Temperature',
  points: [
    DataPoint.time(DateTime.utc(2026, 3, 2), 3),
    DataPoint.time(DateTime.utc(2026, 3, 3), 5),
  ],
)
```

The values of the options are Dart and Flutter values:

- Colors are `Color` values. A dataset also takes one color for each data item
  (`backgroundColors: [...]`) or a function of the context (`backgroundColorFor`), and the same
  for the border.
- Fonts are `TextStyle` values: the chart reads the family, the size, the style, the weight and
  the height. It does not read the color of a `TextStyle`: each font parameter has a color
  parameter next to it, for example `labelFont` and `labelColor`.
- Durations are `Duration` values, and paddings are `EdgeInsets` values.
- A pie or doughnut `cutout` or `radius` is a `ChartLength`: `ChartLength.percent(50)` or
  `ChartLength.pixels(80)`.
- Names are dot shorthands: `position: .bottom`, `easing: .easeOutQuart`, `pointStyle: .star`,
  `fill: .origin`. `ChartFill.dataset(0)`, `ChartFill.relative(-1)` and `ChartFill.value(10)` give
  the other fill targets.

### Axes

`scales` maps an axis id to an axis. A chart type has default axes, so give only the axes with
other options. The order of the entries is the order of the axes in the layout.

```dart
ChartConfig(
  type: .bar,
  labels: labels,
  datasets: datasets,
  scales: const {
    'x': CategoryAxis(grid: AxisGrid(display: false)),
    'y': LinearAxis(
      beginAtZero: true,
      ticks: AxisTicks(stepSize: 5, format: formatVotes),
      title: AxisTitle(display: true, text: 'Votes'),
    ),
  },
)
```

with a top-level function or a method as the tick format:

```dart
String? formatVotes(AxisTickInfo tick) => '${tick.value.round()} votes';
```

A `null` result hides the label. The axes are `CategoryAxis`, `LinearAxis`, `LogarithmicAxis`,
`TimeAxis`, `TimeSeriesAxis` and `RadialLinearAxis` (the axis `r` of a radar or polar area chart).
A `TimeAxis` takes `DateTime` limits and a `unit`, for example `TimeAxis(unit: .day)`.

### Option groups

The option groups are parameters of `ChartConfig`:

```dart
ChartConfig(
  type: .bar,
  labels: labels,
  datasets: datasets,
  padding: const EdgeInsets.all(8),
  legend: const ChartLegend(
    position: .bottom,
    labelFont: TextStyle(fontSize: 12),
  ),
  title: const ChartTitle(display: true, text: 'Votes'),
  tooltip: const ChartTooltip(backgroundColor: Colors.black87, cornerRadius: 4),
  interaction: const ChartInteraction(mode: .index, intersect: false),
  animation: const ChartAnimation(
    duration: Duration(milliseconds: 400),
    easing: .easeOutQuart,
  ),
  elements: const ChartElements(bar: BarElementStyle(borderRadius: 4)),
)
```

`subtitle` takes a `ChartTitle` too, `filler` sets the filler plugin, and
`animation: ChartAnimation.none` turns the animations off. `indexAxis: .y` gives a horizontal bar
chart. `responsive`, `maintainAspectRatio` and `aspectRatio` set the [size](#size).

### Callbacks

The callbacks get a details object with `int` indexes:

```dart
class VotesPage extends StatefulWidget {
  const VotesPage({super.key});

  @override
  State<VotesPage> createState() => _VotesPageState();
}

class _VotesPageState extends State<VotesPage> {
  final List<num> _votes = [12, 19, 3, 5, 2, 3];

  void _onClick(ChartEventDetails details) {
    final hit = details.hits.firstOrNull;
    if (hit == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_votes[hit.index]} votes')),
    );
  }

  void _onLegendClick(ChartLegendEventDetails details) {
    final index = details.item.datasetIndex;
    if (index == null) return;
    // The Chart methods take the int index.
    final chart = details.legend.chart;
    if (chart.isDatasetVisible(index)) {
      chart.hide(index);
    } else {
      chart.show(index);
    }
  }

  String? _label(ChartTooltipItem item) =>
      '${item.datasetLabel}: ${item.formattedValue} votes';

  Color _barColor(ChartContext context) =>
      (context.raw as num? ?? 0) > 10 ? Colors.green : Colors.grey;

  @override
  Widget build(BuildContext context) {
    return ChartView(
      config: ChartConfig(
        type: .bar,
        labels: const ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
        datasets: [
          BarDataset(
            label: '# of Votes',
            data: _votes,
            backgroundColorFor: _barColor,
          ),
        ],
        onClick: _onClick,
        legend: ChartLegend(onClick: _onLegendClick),
        tooltip: ChartTooltip(labelText: _label),
      ),
    );
  }
}
```

- `onClick` and `onHover` get `ChartEventDetails`: the chart event, the elements under the
  pointer (`hits`, each with `datasetIndex`, `index` and `element`) and the chart.
- The legend `onClick`, `onHover` and `onLeave` get `ChartLegendEventDetails`. A legend `onClick`
  replaces the default click, which hides or shows the dataset.
- The tooltip `titleText`, `labelText` and `footerText` give the text. A `null` result gives the
  default text.
- `AxisTicks.format` gives the tick label, and `ChartAnimation.onProgress` and `onComplete` get
  `ChartAnimationDetails`.
- `backgroundColorFor` and `borderColorFor` get a `ChartContext` (`dataIndex`, `datasetIndex`,
  `raw`, `parsed`, `active`, `chart`) for each element.

The chart methods take `int` indexes: `chart.hide(hit.datasetIndex)`,
`chart.isDatasetVisible(index)`, `chart.getDatasetMeta(index)`. The callbacks run in the phases of
[Callbacks and `setState`](#callbacks-and-setstate).

### Updates

Build the config in `build`. A new config that is `==` to the last one gives no update, so a
parent can rebuild as often as it likes. Another config updates the chart after the frame, with
the animations of Chart.js:

```dart
class _ScoresState extends State<Scores> {
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
            type: .bar,
            labels: const ['A', 'B', 'C'],
            datasets: [BarDataset(label: 'Score', data: _scores)],
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
        data: series.values,
      ),
  ],
  ```
- The event and text callbacks (`onClick`, `onHover`, the legend handlers, the tooltip texts and
  the animation callbacks) can be new closures in each build: the chart calls the callback of the
  newest config. A scriptable color (`backgroundColorFor`) and a tick format are values of the
  config: give a method tear-off or a top-level function, because a new closure in each build is
  a new value and updates the chart.
- Change the config, not the Maps of the chart (`chart.data`, `chart.options`): the next config
  writes its options again. A change of `chart.options` in place lasts until a config with other
  options.
- `updateMode` sets the mode of the update, for example `updateMode: 'none'` for no animation.

### Options without a parameter

The typed config has the common options of the Chart.js docs. Each class has `extra`, a Map of
Chart.js options that go into the Map of that class last:

```dart
ChartConfig(
  type: .line,
  labels: labels,
  datasets: [
    LineDataset(
      label: 'Visitors',
      data: visitors,
      extra: const {
        'borderCapStyle': 'round',
        'cubicInterpolationMode': 'monotone',
      },
    ),
  ],
  interaction: const ChartInteraction(intersect: false, extra: {'axis': 'x'}),
  extra: const {'locale': 'de-DE'},
)
```

`ChartConfig.extra` goes into `options`. A key of `extra` wins over a parameter with the same
key, and a Map value merges into the Map of the key. Thus `extra` also takes a CSS color string,
a gradient function or the JavaScript `null` (Dart `null` in a parameter means "not set"). For a
config that the typed API does not fit, use [`ChartView.raw`](#raw-chartjs-configs).

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

## Raw Chart.js configs

`ChartView.raw` takes a Chart.js configuration as a Dart `Map`: `type`, `data`, `options`,
`plugins` (inline plugins) and `platform`, with every option of Chart.js. Use it for a copy of the
[Chart.js docs](https://www.chartjs.org/docs/4.6.1/) or for the output of `jsonDecode`:

```dart
class VotesChart extends StatefulWidget {
  const VotesChart({super.key});

  @override
  State<VotesChart> createState() => _VotesChartState();
}

class _VotesChartState extends State<VotesChart> {
  // The configuration of `new Chart(canvas, config)`. Keep it in the State:
  // the same Map in the next build gives no update.
  final Map<String, Object?> _config = {
    'type': 'bar',
    'data': <String, Object?>{
      'labels': ['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
      'datasets': [
        <String, Object?>{
          'label': '# of Votes',
          'data': [12, 19, 3, 5, 2, 3],
          'borderWidth': 1,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'y': <String, Object?>{'beginAtZero': true},
      },
    },
  };

  @override
  Widget build(BuildContext context) {
    return ChartView.raw(
      config: _config,
      semanticLabel: 'Bar chart of the votes for six colors',
    );
  }
}
```

A JSON configuration works as it is:

```dart
final config = jsonDecode(json) as Map<String, Object?>;
// ...
ChartView.raw(config: config)
```

Write the options as in the Chart.js docs, with these rules of Dart:

- **A raw configuration is never `const`.** Chart.js writes into the `data` and `options` Maps of
  the configuration when it starts the chart (`initConfig` of `core.config.js`). A `const` Map
  cannot change, so the chart fails to start with `Unsupported operation: Cannot modify
  unmodifiable map`. If your lint set enables `prefer_const_literals_to_create_immutables` (for
  example `very_good_analysis`), the lint asks for `const` when you write the Map literal straight
  into `ChartView.raw(config: {...})`. Build the Map in a variable, a field of the `State` or a
  function instead.
- **A nested Map has the type `Map<String, Object?>`.** Chart.js also writes into the dataset
  Maps: the `colors` plugin writes `borderColor` and `backgroundColor`, and the `decimation`
  plugin writes `data`. A Map literal with a narrower inferred type, for example
  `{'data': [1, 2, 3]}` (a `Map<String, List<int>>`), throws a `TypeError` at that write. Write
  `<String, Object?>{...}` for each nested Map.
- **A label List is growable and takes a `String`.** Chart.js adds a string label to it when a
  data value or a `min` or `max` option names a new category. A growable list of strings works.
  For labels that are not strings, for example numbers or multi-line labels, write
  `<Object?>[...]`: a `List<int>` or a `List<List<String>>` throws a `TypeError` at the add, and a
  `const`, unmodifiable or fixed-length List throws an `UnsupportedError`.
- **Callbacks are Dart functions.** Give `onClick`, `onHover`, `onResize`, the animation
  callbacks, the tick callbacks and the scriptable options as functions in the options. A
  function can declare fewer parameters than Chart.js passes, as in JavaScript:

  ```dart
  'onClick': (ChartEvent event, List<ActiveElement> elements, Chart chart) {
    // A Chart.js index is a JavaScript number: a double.
    final index = elements.isEmpty ? null : elements.first.index.toInt();
  },
  ```
- **`undefined` is a value.** Chart.js tells an absent key, `undefined` and `null` apart. Dart
  `null` is the JavaScript `null`. The library exports `undefined` for the third state.

The updates of a raw configuration:

- A new `config` Map updates the chart after the frame. The same Map gives no update. The update
  sets `type`, `data` and `options` when they are new objects, and the inline plugins when
  `plugins` is a new List. The chart keeps its hidden datasets and its animations. Only a new
  `platform` makes a new chart. `updateMode` sets the mode of that update.
- Keep the dataset Maps to keep the dataset state. New dataset Maps give new datasets, as in
  Chart.js.
- After a change in place, call `chart.update()` from an event handler or a post-frame callback,
  never from `build`, with `notifyArrayListeners` for a change of the length of a data List
  ([Updates](#updates)).
- A change of `chart.options` in place lasts until the next new `options` object.
- A parent that rebuilds in each frame keeps its configuration in its `State`, or sets
  `updateMode: 'none'`. An `onHover` that calls `setState` compares the value first.

## Libraries

| Library | Contents |
|---|---|
| `package:flutter_chartjs_port/flutter_chartjs_port.dart` | The library of an app: `ChartView`, the typed API (`ChartConfig`, the dataset classes, the axes, the option groups and the callback details), `ChartTheme`, `ChartThemeData`, and the Chart.js API: `Chart`, the controllers, elements, scales and plugin objects, `registerables`, `defaults`, the types of the callbacks, the date zone functions, `notifyArrayListeners` and `undefined`. It leaves out `Animation` and `Element`, two names that Flutter also has, so an app imports it next to `material.dart` with no prefix. |
| `package:flutter_chartjs_port/chartjs.dart` | The `chart.js` entry of npm, for code that extends Chart.js (a plugin, a controller or a scale): the whole Chart.js API with `Animation` and `Element`, the Canvas 2D interface that a plugin draws on (`chart.ctx`), `ChartMeta` and `JsClass` (the class value of a subclass). It has no typed API. Next to Flutter, import it with a prefix or with `hide Animation, Element`. |
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
- **Dart collections.** In a raw configuration, a dataset Map has the type
  `Map<String, Object?>`, a label List is growable and takes a `String` (`<Object?>[...]` for
  labels that are not strings), and the configuration is never `const`
  ([Raw Chart.js configs](#raw-chartjs-configs)). The typed config makes its own Maps.
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
Chart.js is MIT-licensed by the Chart.js Contributors. The color parser is a port of
[@kurkle/color](https://github.com/kurkle/color) 0.3.2 (MIT, Jukka Kurkela). The functions that
match JavaScript `Math.log10`, `Math.atan2`, `Math.sin` and `Math.cos` are ported from fdlibm 5.3
(Sun Microsystems, Inc.). All notices are in [LICENSE](LICENSE). This project is not affiliated
with the Chart.js project.
