// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 docs/samples/basic.md (MIT, chartjs-plugin-zoom contributors).

import 'dart:ui' as ui;

import 'package:chartjs_gallery/demo/demo_common.dart' show jsNumberText;
import 'package:chartjs_gallery/docs/zoom/scripts/defaults.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// A sample of the docs of chartjs-plugin-zoom: the `module.exports` of its
/// `chart-editor` block (`{actions, config, output}`).
///
/// - `config`: the typed chart config, new for each call of the sample.
/// - `actions`: the buttons of the docs page under the chart, in their
///   order.
/// - `output`: the first text of the output pane of the docs page, or
///   `null` for a sample without `output`.
typedef ZoomDocsSample = ({
  ChartConfig config,
  List<ZoomDocsAction> actions,
  String? output,
});

/// An action of a sample (`{name, handler(chart)}`).
///
/// The gallery adds `isOn`: for an action that turns an option on and off,
/// it reads that option, so that the segment of the action shows its state.
/// It is `null` for an action that is a command.
typedef ZoomDocsAction = ({
  String name,
  void Function(Chart chart) handler,
  bool Function(Chart chart)? isOn,
});

/// The console of a docs page: `console.log` of a sample writes a line into
/// the output pane.
typedef ZoomDocsLog = void Function(String line);

/// The sample `Basic` of `docs/samples/basic.md:3-132`: a scatter chart that
/// zooms with the wheel and a pinch, and pans with a drag, in the limits of
/// `:55-58`.
///
/// The gallery changes the sample in these items:
/// - The data is the result of `Utils.points` of `:14` and `:22` with the
///   seed 2026 (`docs/scripts/utils.js:12-47`), in place of the seed
///   `Date.now()` (`utils.js:6`), as [zoomSampleData] says.
/// - Each `Utils.randomColor(alpha)` (`utils.js:49-53`) is a fixed color
///   with that alpha: the red and the blue of the Chart.js docs for the
///   datasets. The grid border draws nothing ([zoomSampleScales]). The
///   colors are `Color` values
///   (Chart.js ADR 0061): `'rgba( 0, 0, 0, 0.1)'` of `:35` is
///   `Color.fromRGBO(0, 0, 0, 0.1)`.
/// - The config is a typed `ChartConfig` (Chart.js ADR 0195), and the zoom
///   options are one immutable `ZoomPluginOptions` in its `pluginOptions`
///   (Chart.js ADR 0148). A handler that writes `zoomOptions.pan.enabled`
///   (`:108-118`) makes the merge with the new value and writes it into the
///   options of the chart ([setZoomSampleOptions]) before `chart.update()`.
/// - The config gets the docs defaults (`withZoomDocsDefaults`).
/// - `console.log(e.type)` of `onClick` (`:98-100`) writes into [log].
ZoomDocsSample zoomBasicSample(ZoomDocsLog log) {
  // <block:data:1>
  final data = zoomSampleData();
  // </block:data>

  // <block:scales:2>
  final scales = zoomSampleScales();
  // </block:scales>

  // <block:zoom:0>
  // `zoomOptions` is a local, so that the actions read it and write a new
  // object, as the upstream handlers write into it.
  var zoomOptions = ZoomPluginOptions(
    limits: const LimitOptions(
      x: ScaleLimits(min: ScaleLimit(-200), max: ScaleLimit(200), minRange: 50),
      y: ScaleLimits(min: ScaleLimit(-200), max: ScaleLimit(200), minRange: 50),
    ),
    pan: const PanOptions(enabled: true, mode: Mode.xy),
    zoom: ZoomOptions(
      wheel: const WheelOptions(enabled: true),
      pinch: const PinchOptions(enabled: true),
      mode: Mode.xy,
      onZoomComplete: (context) {
        // This update is needed to display up to date zoom level in the
        // title. Without this, previous zoom level is displayed. The reason
        // is: title uses the same beforeUpdate hook, and is evaluated before
        // zoom.
        context.chart.update(UpdateMode.none);
      },
    ),
  );
  // </block:zoom>

  bool panEnabled() => zoomOptions.pan?.enabled ?? false;
  bool wheelEnabled() => zoomOptions.zoom?.wheel?.enabled ?? false;
  String panStatus() => panEnabled() ? 'enabled' : 'disabled';
  // The zoom level is a number in the text, with no `.0` for a whole number.
  String zoomStatus(Chart chart) =>
      '${wheelEnabled() ? 'enabled' : 'disabled'} '
      '(${jsNumberText(chart.getZoomLevel())}x)';

  // <block:config:1>
  final config = withZoomDocsDefaults(
    ChartConfig(
      datasets: data,
      scales: scales,
      pluginOptions: [
        zoomOptions,
        // The scriptable text is the one function `scripted` (Chart.js ADR
        // 0197).
        TitleOptions(
          display: true,
          position: ChartPosition.bottom,
          scripted: (context, options) {
            final zoom = zoomStatus(context.chart as Chart);
            return TitleOptions(text: ['Zoom: $zoom, Pan: ${panStatus()}']);
          },
        ),
      ],
      // Chart.js ADR 0130: a ChartEventHandler, with all three parameters.
      onClick: (e, elements, chart) {
        log(e.type);
      },
    ),
  );
  // </block:config>

  final actions = <ZoomDocsAction>[
    (
      name: 'Toggle zoom',
      handler: (chart) {
        final pinch = zoomOptions.zoom?.pinch?.enabled ?? false;
        zoomOptions = zoomOptions.merge(
          ZoomPluginOptions(
            zoom: ZoomOptions(
              wheel: WheelOptions(enabled: !wheelEnabled()),
              pinch: PinchOptions(enabled: !pinch),
            ),
          ),
        );
        setZoomSampleOptions(chart, zoomOptions);
        chart.update();
      },
      isOn: (_) => wheelEnabled(),
    ),
    (
      name: 'Toggle pan',
      handler: (chart) {
        zoomOptions = zoomOptions.merge(
          ZoomPluginOptions(pan: PanOptions(enabled: !panEnabled())),
        );
        setZoomSampleOptions(chart, zoomOptions);
        chart.update();
      },
      isOn: (_) => panEnabled(),
    ),
    (name: 'Reset zoom', handler: (chart) => chart.resetZoom(), isOn: null),
  ];

  return (actions: actions, config: config, output: 'Clicks are logged here');
}

/// The data block of `docs/samples/basic.md:4-25`: two scatter datasets of
/// 20 points in -100 to 100.
///
/// `Utils.points(NUMBER_CFG)` with the seed 2026: the probe runs the
/// functions `rand`, `numbers` and `points` of `docs/scripts/utils.js:12-47`
/// at the pin on Node.js v24.22.1 after `srand(2026)`, and the lists below
/// are its values. `Utils.randomColor` does not read the seed (`:49`).
///
/// The samples `drag/linear.md:6-27` and `pan/toggle.md:6-27` have the same
/// block, so they take the same values.
List<Dataset> zoomSampleData() => [
  ScatterDataset(
    label: 'My First dataset',
    borderColor: .constant(.solid(_red(0.4))),
    backgroundColor: .constant(.solid(_red(0.1))),
    pointBorderColor: .constant(.solid(_red(0.7))),
    pointBackgroundColor: .constant(.solid(_red(0.5))),
    pointBorderWidth: 1,
    data: .points([
      DataPoint(97.80778464, 26.85442387),
      DataPoint(-42.30366941, -18.60682442),
      DataPoint(84.04578189, -7.48371056),
      DataPoint(-46.60065158, 10.84104938),
      DataPoint(-31.77383402, -42.64489026),
      DataPoint(12.47685185, -54.36128258),
      DataPoint(-59.52760631, 37.42026749),
      DataPoint(-0.87362826, -68.53480796),
      DataPoint(-16.4994856, -14.20181756),
      DataPoint(-74.30641289, -26.74125514),
      DataPoint(-82.93638546, -29.60991084),
      DataPoint(63.78343621, -20.33864883),
      DataPoint(-24.27040466, 85.02314815),
      DataPoint(-11.29543896, -59.20353224),
      DataPoint(-80.00771605, -6.10510974),
      DataPoint(-42.75291495, 39.38014403),
      DataPoint(80.71587791, -90.64900549),
      DataPoint(18.79372428, 95.16546639),
      DataPoint(-63.08727709, -97.00360082),
      DataPoint(59.76423182, -57.27966392),
    ]),
  ),
  ScatterDataset(
    label: 'My Second dataset',
    borderColor: .constant(.solid(_blue(0.4))),
    backgroundColor: .constant(.solid(_blue(0.1))),
    pointBorderColor: .constant(.solid(_blue(0.7))),
    pointBackgroundColor: .constant(.solid(_blue(0.5))),
    pointBorderWidth: 1,
    data: .points([
      DataPoint(-49.86025377, -8.87945816),
      DataPoint(-57.46141975, 38.66340878),
      DataPoint(-92.42884088, -54.74022634),
      DataPoint(25.48439643, -56.99159808),
      DataPoint(24.67335391, -76.73268176),
      DataPoint(70.57013032, -7.79063786),
      DataPoint(-12.13391632, -40.28892318),
      DataPoint(16.06738683, -38.42506859),
      DataPoint(98.38391632, 15.08487654),
      DataPoint(-96.04852538, -92.1047668),
      DataPoint(-16.61265432, 20.25291495),
      DataPoint(57.67918381, 80.55298354),
      DataPoint(40.40723594, 54.22753772),
      DataPoint(-6.70010288, -34.03206447),
      DataPoint(15.12259945, 55.28034979),
      DataPoint(63.90003429, 65.37465706),
      DataPoint(-87.52829218, 65.38665981),
      DataPoint(37.3808299, 5.93364198),
      DataPoint(41.09653635, 8.00325789),
      DataPoint(7.56944444, -14.82424554),
    ]),
  ),
];

/// The scales block of `docs/samples/basic.md:27-51`: both axes reversed,
/// x on top and y on the right, with no first and last tick label.
///
/// `Object.assign(scales[scale], scaleOpts)` (`:50`) gives both axes the
/// same `ticks` and `grid`, as upstream. The scriptable title text
/// `(ctx) => ctx.scale.axis + ' axis'` (`:39`) is the text of each axis:
/// the typed `AxisTitle` takes the lines ([zoomAxisTitle]). The key
/// `grid.borderColor` (`:34`) is an option of Chart.js 3: Chart.js 4 draws
/// the axis line with `border.color`, so the key draws nothing in the docs,
/// and the typed `AxisGrid` has no such field: the config leaves it out.
/// The sample `drag/linear.md:29-53` has the same block.
List<ChartAxis> zoomSampleScales() {
  final ticks = AxisTicks(
    // A TickCallback: the scale, the value, the index and the ticks.
    callback: (scale, val, index, ticks) =>
        index == 0 || index == ticks.length - 1 ? null : [jsNumberText(val)],
  );
  const grid = AxisGrid(
    color: ChartPaint.solid(ui.Color.fromRGBO(0, 0, 0, 0.1)),
  );
  return [
    LinearAxis(
      .x,
      position: ChartPosition.top,
      reverse: true,
      ticks: ticks,
      grid: grid,
      title: zoomAxisTitle(.x),
    ),
    LinearAxis(
      .y,
      position: ChartPosition.right,
      reverse: true,
      ticks: ticks,
      grid: grid,
      title: zoomAxisTitle(.y),
    ),
  ];
}

/// `zoomOptions.<option> = value` of a handler of a sample: the new zoom
/// options [options] in `chart.options.plugins.zoom`, the options of the
/// user, read by name through their face. The options are immutable
/// (Chart.js ADR 0148), so a handler writes a new object where upstream
/// writes into the object. The write goes into the live options, as the
/// `set` traps of the Proxies of upstream do
/// (src/helpers/helpers.config.ts:189-193 and :101-106 of Chart.js v4.6.1):
/// the config of the page stays the same object, so the zoom range stays.
void setZoomSampleOptions(Chart chart, ZoomPluginOptions options) {
  (chart.options['plugins']! as JsObjectFace)['zoom'] = options;
}

/// `title: {display: true, text: (ctx) => ctx.scale.axis + ' axis'}`, the
/// scale title of the samples: its one line for the axis [axis].
AxisTitle zoomAxisTitle(CartesianAxis axis) =>
    AxisTitle(display: true, text: ['${axis is XAxis ? 'x' : 'y'} axis']);

/// The red of the Chart.js docs, `rgb(255, 99, 132)`, with [alpha].
ui.Color _red(double alpha) => ui.Color.fromRGBO(255, 99, 132, alpha);

/// The blue of the Chart.js docs, `rgb(54, 162, 235)`, with [alpha].
ui.Color _blue(double alpha) => ui.Color.fromRGBO(54, 162, 235, alpha);
