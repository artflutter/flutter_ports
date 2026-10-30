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
- The Chart.js configuration as a Dart `Map`: the same keys, the same defaults and the same
  results. Callbacks and scriptable options are Dart functions.
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

[`example/main.dart`](example/main.dart) is a complete app with a data update and a click
callback. The gallery app of the repository,
[`apps/chartjs_gallery`](https://github.com/artflutter/flutter_ports/tree/main/apps/chartjs_gallery),
shows each chart type of the Chart.js docs.

### The configuration

`ChartView.raw` takes a Chart.js configuration: `type`, `data`, `options`, `plugins` (inline
plugins) and `platform`. The output of `jsonDecode` works too. Write the options as in the
[Chart.js docs](https://www.chartjs.org/docs/4.6.1/), with these rules of Dart:

- **A configuration is never `const`.** Chart.js writes into the `data` and `options` Maps of the
  configuration when it starts the chart (`initConfig` of `core.config.js`). A `const` Map
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

### Updates

- A new `config` Map updates the chart after the frame. The same Map gives no update. The update
  sets `type`, `data` and `options` when they are new objects, and the inline plugins when
  `plugins` is a new List. The chart keeps its hidden datasets and its animations. Only a new
  `platform` makes a new chart. `updateMode` sets the mode of that update.
- Keep the dataset Maps to keep the dataset state. New dataset Maps give new datasets, as in
  Chart.js.
- After a change in place, call `chart.update()` from an event handler or a post-frame callback,
  never from `build`. `onChartCreated` gives you the `Chart`.
- A Dart `List` has no methods that Chart.js can hook, so the chart does not see a `push`, `pop`,
  `shift`, `splice` or `unshift` on a data List. Call `notifyArrayListeners` after the change,
  then `chart.update()`:

  ```dart
  votes.add(7);
  notifyArrayListeners(votes, 'push', [7]);
  chart.update();
  ```

  Without the notification, `update()` still shows the new data, but an insert or a removal at
  the start or in the middle does not animate as in Chart.js.
- A change of `chart.options` in place lasts until the next new `options` object.
- A parent that rebuilds in each frame keeps its configuration in its `State`, or sets
  `updateMode: 'none'`. An `onHover` that calls `setState` compares the value first.

### Size

`ChartView` has no size parameter. The constraints and the options `responsive`,
`maintainAspectRatio` and `aspectRatio` give the size:

| Parent | Options | Size |
|---|---|---|
| `Column` or a scroll view | the defaults | the width, and the height from `aspectRatio` (2, or 1 for doughnut, pie, polar area and radar) |
| `SizedBox(height: ...)` or `Expanded` | `'maintainAspectRatio': false` | the box |

In a `Row`, the width is unbounded: put the chart in an `Expanded` or give it a width.

### Callbacks and `setState`

Each callback of a chart runs in one phase of the Flutter frame, and only some phases allow
`setState`:

| Callback | Phase | `setState` |
|---|---|---|
| `onHover`, `onClick`, and the plugin hooks `beforeEvent` and `afterEvent` of an input | a frame callback after the input | allowed |
| `onResize` and the plugin hook `resize` after a size change | a frame callback | allowed |
| `onProgress` and `onComplete` of an animation, and the plugin hook `afterRender` | a frame callback of the animator | allowed |
| all hooks of an update of the widget (a new `config`, a new theme or a new reduced-motion setting), and the `onHover` that the update replays | a post-frame callback | allowed |
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

## Libraries

| Library | Contents |
|---|---|
| `package:flutter_chartjs_port/flutter_chartjs_port.dart` | The library of an app: `ChartView`, `ChartTheme`, `ChartThemeData`, and the Chart.js API: `Chart`, the controllers, elements, scales and plugin objects, `registerables`, `defaults`, the types of the callbacks, the date zone functions, `notifyArrayListeners` and `undefined`. It leaves out `Animation` and `Element`, two names that Flutter also has, so an app imports it next to `material.dart` with no prefix. |
| `package:flutter_chartjs_port/chartjs.dart` | The `chart.js` entry of npm, for code that extends Chart.js (a plugin, a controller or a scale): the whole Chart.js API with `Animation` and `Element`, the Canvas 2D interface that a plugin draws on (`chart.ctx`), `ChartMeta` and `JsClass` (the class value of a subclass). Next to Flutter, import it with a prefix or with `hide Animation, Element`. |
| `package:flutter_chartjs_port/helpers.dart` | The `chart.js/helpers` entry: the public helpers of Chart.js. An upper case constant has a lowerCamelCase name: `PI` is `pi`. Import it with a prefix. |

`chartJsVersion` gives the version of Chart.js that the package ports.

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
- **Dart collections.** A dataset Map has the type `Map<String, Object?>`, a label List is
  growable and takes a `String` (`<Object?>[...]` for labels that are not strings), and a
  configuration is never `const` ([The configuration](#the-configuration)).
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
