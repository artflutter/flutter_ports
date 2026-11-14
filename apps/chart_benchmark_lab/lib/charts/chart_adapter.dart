import 'dart:async';
import 'dart:math' as math;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart'
    show chartJsDataOnlyUpdates;
import 'package:chart_benchmark_lab/benchmark/data.dart';
// The three libraries other than the Chart.js port are deferred: a web build
// with deferred loading fetches the code of each one only when a person
// selects it or a run needs it (BenchmarkChart.load).
import 'package:chart_benchmark_lab/charts/fl_chart_adapter.dart'
    deferred as fl_chart_adapter;
import 'package:chart_benchmark_lab/charts/graphic_adapter.dart'
    deferred as graphic_adapter;
import 'package:chart_benchmark_lab/charts/syncfusion_adapter.dart'
    deferred as syncfusion_adapter;
import 'package:flutter/gestures.dart';
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    as sk;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    as zp;
import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as cj;
import 'package:material_ui/material_ui.dart';

/// One active public-widget adapter; inactive engines are never mounted.
class const BenchmarkChart({
  /// Selected engine.
  required final ChartLibrary library,

  /// Common effective features.
  required final BenchmarkConfig config,

  /// Shared input snapshot.
  required final DatasetFrame frame,

  /// Identical outer viewport for every engine.
  required final Size size,
  super.key,
}) extends StatelessWidget {
  /// All engines receive the same immutable source values and feature settings.
  this;

  /// The libraries whose code is ready. The Chart.js port is part of the main
  /// module of the app.
  static final Set<ChartLibrary> _ready = {ChartLibrary.chartjs};

  /// The loads in progress, one for each library.
  static final Map<ChartLibrary, Future<void>> _loads = {};

  /// Whether the code of [library] is ready.
  static bool isReady(ChartLibrary library) => _ready.contains(library);

  /// Loads the code of [library]. It gives `null` when the code is ready, else
  /// a future that completes when the code is ready. A failed load can start
  /// again.
  static Future<void>? load(ChartLibrary library) => _ready.contains(library)
      ? null
      : _loads[library] ??= _load(library).whenComplete(() {
          // The caller holds this future. Its entry goes, so that a failed
          // load can start again.
          unawaited(_loads.remove(library));
        });

  static Future<void> _load(ChartLibrary library) async {
    await switch (library) {
      ChartLibrary.chartjs => Future<void>.value(),
      ChartLibrary.flChart => fl_chart_adapter.loadLibrary(),
      ChartLibrary.graphic => graphic_adapter.loadLibrary(),
      ChartLibrary.syncfusion => syncfusion_adapter.loadLibrary(),
    };
    _ready.add(library);
  }

  /// Loads the code of each library. The tests and a native app use it: a
  /// native build has no deferred module, so the load costs nothing there.
  static Future<void> loadAll() =>
      Future.wait([for (final library in ChartLibrary.values) ?load(library)]);

  /// The outer radius of a pie, doughnut or polar area, as a share of half of
  /// the short side.
  static const sliceExtent = .9;

  /// The outer radius of a radar. fl_chart fixes its radar radius at this
  /// share, so the other engines take the same share.
  static const radarExtent = .8;

  /// The space that the point labels of a Chart.js radar take from its radius,
  /// in logical pixels, with the 10 px label font.
  static const _radarLabelRoom = 24.0;

  /// The inner radius of a doughnut, as a share of its outer radius.
  static const doughnutCutout = .5;

  /// The number of labels around a radar stays controlled, as on an x axis. A
  /// radar still has one spoke per item.
  int get radarLabelStep => math.max(1, (config.count / 8).ceil());

  /// One label List per item count. An app with stable labels keeps its List,
  /// so a new data List does not also replace the labels of the chart.
  static final Map<int, List<String>> _chartJsLabels = {};

  static List<String> _chartJsLabelsFor(int count) => _chartJsLabels
      .putIfAbsent(count, () => [for (var i = 0; i < count; i++) '$i']);

  /// One point-label callback per label step: a new closure is a new option
  /// value for `ChartConfig ==`. A label between two steps is one empty line,
  /// so it keeps its place and its height.
  static final Map<int, cj.PointLabelCallback> _radarLabelCallbacks = {};

  static cj.PointLabelCallback _radarLabelCallback(int step) =>
      _radarLabelCallbacks.putIfAbsent(
        step,
        () =>
            (scale, label, index) => index % step == 0 ? label : const [''],
      );

  // Zoom and pan (BenchmarkConfig.zoom). Each library zooms and pans only the
  // x axis, inside the full range of the data, down to 1/chartMaxZoom of it.
  // A pinch zooms on touch and a drag pans a zoomed chart, on each library.
  // The mouse wheel zooms on each library too. The listener of the zoom port
  // prevents the default of the wheel, and its host then claims the pointer
  // signal; fl_chart, Graphic and Syncfusion read the wheel and claim nothing.
  // Thus [_claimWheel] claims each wheel over a chart with zoom: the page does
  // not scroll under a wheel zoom, and that scroll does not stop a test.
  //
  // A desktop trackpad sends its pinch and its two-finger scroll as pan-zoom
  // events (PointerPanZoomStartEvent and the next ones), not as a wheel:
  // - fl_chart: a pinch zooms, and a horizontal scroll pans a zoomed chart
  //   (its scale gesture, trackpadScrollCausesScale false);
  // - Graphic: a pinch zooms; a scroll does nothing (the scale gesture
  //   counts a pan-zoom as two pointers, so the range event reads a scroll as
  //   a pinch of scale 1);
  // - Syncfusion: its behavior reads each pan-zoom update as a wheel step by
  //   the sign of the vertical pan (zooming.dart:429, :666): a vertical scroll
  //   zooms, and a pinch, which has no vertical pan, only zooms out;
  // - the Chart.js port: its host gives a trackpad scroll and pinch as
  //   `wheel` events, as Chrome does (Chart.js ADR 0137), while
  //   BenchmarkConfig.trackpad is on: a scroll and a pinch zoom it, and the
  //   zoom plugin keeps the page from scrolling.
  //
  // Each test starts with a new chart, at the full range: the key of the
  // chart has the revision of the controller.

  /// Claims a mouse wheel over a chart with zoom, so that no scroll view
  /// above the chart scrolls. Each library still reads the wheel: the
  /// listeners below this one get the event before it, and the first claim
  /// wins (the host of the Chart.js port claims first). This only arbitrates
  /// the input; it draws nothing.
  static void _claimWheel(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      GestureBinding.instance.pointerSignalResolver.register(
        event,
        (event) => event.respond(allowPlatformDefault: false),
      );
    }
  }

  /// The zoom options of the Chart.js port, for `plugins.zoom` of the port of
  /// chartjs-plugin-zoom: pan with a drag, zoom with the wheel and a pinch,
  /// both on x. The limits keep the original range, as the other libraries
  /// do, and `minRange` gives the largest zoom. The drag zoom (a box) stays
  /// off: fl_chart and Graphic have none.
  Map<String, Object?> get _chartJsZoom => {
    'pan': <String, Object?>{'enabled': true, 'mode': zp.Mode.x},
    'zoom': <String, Object?>{
      'wheel': <String, Object?>{'enabled': true},
      'pinch': <String, Object?>{'enabled': true},
      'mode': zp.Mode.x,
    },
    'limits': <String, Object?>{
      'x': <String, Object?>{
        'min': 'original',
        'max': 'original',
        // A category axis counts the bars from 0, a linear axis goes to 100,
        // and the hidden x scale of the sankey chart has its three columns
        // at 0, 1 and 2.
        'minRange':
            switch (config.type) {
              ChartType.bar => config.count - 1,
              ChartType.sankey => 2,
              _ => 100,
            } /
            chartMaxZoom,
      },
    },
  };

  @override
  Widget build(BuildContext context) {
    if (!library.runs(config)) {
      return Center(
        key: const ValueKey('chart.unsupported'),
        child: Text(
          library.reasonFor(config),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xff64748b)),
        ),
      );
    }
    if (!isReady(library)) {
      return Center(
        key: const ValueKey('chart.loading'),
        child: Text(
          'Loading ${library.label}…',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xff64748b)),
        ),
      );
    }
    final chart = switch (library) {
      ChartLibrary.chartjs => _chartJs(),
      ChartLibrary.flChart => fl_chart_adapter.flChart(this),
      ChartLibrary.graphic => graphic_adapter.graphicChart(this),
      ChartLibrary.syncfusion => syncfusion_adapter.syncfusionChart(this),
    };
    return config.zooms
        ? Listener(onPointerSignal: _claimWheel, child: chart)
        : chart;
  }

  /// The color of the item at [index].
  Color itemColor(int index) =>
      config.alternateColors && config.type.hasItemColors && index.isOdd
      ? chartTeal
      : chartBlue;

  /// Registers the controller and the element of the sankey chart of the
  /// Chart.js port (the port of chartjs-chart-sankey) once, before the first
  /// sankey chart. They add the chart type `sankey` to the registry and run
  /// no code in a chart of another type.
  static void _registerSankey() {
    if (cj.registry.controllers.get(sk.SankeyController.id) == null) {
      cj.Chart.register(sk.sankeyRegisterables);
    }
  }

  /// One node order per item count: the nodes of a count do not change with
  /// the step.
  static final Map<int, Map<String, int>> _sankeyOrders = {};

  static Map<String, int> _sankeyOrderFor(List<SankeyFlow> flows) =>
      _sankeyOrders.putIfAbsent(flows.length, () => sankeyNodeOrder(flows));

  /// The sankey chart of the Chart.js port: one flow for each item
  /// ([sankeyFlows]). The typed config has no dataset class of another
  /// package (seam S9 of the sankey port), so the chart takes the raw config,
  /// and each tick of new data is a full update. The flows have a gradient
  /// from the first to the second item color, or one color.
  ///
  /// The option `priority` gives each node a fixed place in its column
  /// ([sankeyNodeOrder]). The default layout sorts the nodes by their sizes:
  /// with live data, the order then changes on most ticks, and the nodes
  /// jump across the chart.
  Widget _chartJsSankey() {
    _registerSankey();
    const blue = ChartPaint.solid(chartBlue);
    final flows = sankeyFlows(frame.values);
    final view = cj.ChartView.raw(
      config: <String, Object?>{
        'type': sk.SankeyController.id,
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'Values',
              'data': <Object?>[
                for (final f in flows)
                  sk.SankeyDataPoint(from: f.from, to: f.to, flow: f.flow),
              ],
              'priority': _sankeyOrderFor(flows),
              'colorFrom': blue,
              'colorTo': config.alternateColors
                  ? const ChartPaint.solid(chartTeal)
                  : blue,
              'borderWidth': 0,
            },
          ],
        },
        'options': <String, Object?>{
          'animation': false,
          'responsive': true,
          'maintainAspectRatio': false,
          'plugins': <String, Object?>{
            'tooltip': <String, Object?>{'enabled': config.tooltips},
            if (config.zooms) 'zoom': _chartJsZoom,
          },
          'events': config.tooltips
              ? <String>[
                  'mousemove',
                  'mouseout',
                  'click',
                  'touchstart',
                  'touchmove',
                ]
              : <String>[],
        },
      },
      updateMode: 'none',
      theme: const cj.ChartThemeData(),
      excludeFromSemantics: true,
      trackpadGestures: config.trackpad,
    );
    return config.zooms ? _ChartJsZoomPlugin(child: view) : view;
  }

  /// A sankey chart runs only on the Chart.js port, through
  /// [_chartJsSankey]: [ChartLibrary.supports] keeps it from each other
  /// branch.
  static Never noSankey() =>
      throw StateError('A sankey chart runs only on the Chart.js port.');

  Widget _chartJs() {
    if (config.type == ChartType.sankey) return _chartJsSankey();
    final values = frame.values;
    final color = config.alternateColors && config.type.hasItemColors
        ? const cj.ChartValue<ChartPaint>.indexed([
            ChartPaint.solid(chartBlue),
            ChartPaint.solid(chartTeal),
          ])
        : const cj.ChartValue<ChartPaint>.constant(.solid(chartBlue));
    final points =
        config.type == ChartType.line || config.type == ChartType.scatter
        ? [for (final p in values) cj.DataPoint(p.x, p.y)]
        : null;
    // The canvas blur is twice the Gaussian sigma.
    final shadow = config.shadow
        ? cj.ChartShadow(
            color: chartShadow,
            blur: config.shadowBlur ? chartShadowSigma * 2 : 0,
            offset: chartShadowOffset,
          )
        : null;
    final dataset = switch (config.type) {
      ChartType.line => cj.LineDataset(
        key: const ValueKey('series'),
        label: 'Values',
        shadow: shadow,
        points: points,
        borderColor: const cj.ChartValue.constant(.solid(chartBlue)),
        borderWidth: 2,
        backgroundColor: const cj.ChartValue.constant(
          .solid(Color(0x264f6bed)),
        ),
        pointBackgroundColor: const .constant(.solid(chartBlue)),
        pointBorderWidth: 0,
        pointRadius: config.markers ? 3 : 0,
        pointHoverRadius: 3,
        tension: config.curved ? .35 : 0,
        fill: config.fill ? cj.FillTarget.toOrigin : cj.FillTarget.none,
      ),
      ChartType.bar => cj.BarDataset(
        key: const ValueKey('series'),
        label: 'Values',
        shadow: shadow,
        data: [for (final p in values) p.y],
        backgroundColor: color,
        borderWidth: 0,
        barPercentage: .8,
        categoryPercentage: 1,
      ),
      ChartType.scatter => cj.ScatterDataset(
        key: const ValueKey('series'),
        label: 'Values',
        shadow: shadow,
        points: points,
        backgroundColor: color,
        pointRadius: 3,
        pointBorderWidth: 0,
        showLine: false,
      ),
      ChartType.bubble => cj.BubbleDataset(
        key: const ValueKey('series'),
        label: 'Values',
        shadow: shadow,
        points: [for (final p in values) cj.DataPoint.bubble(p.x, p.y, p.r)],
        backgroundColor: color,
        borderWidth: 0,
      ),
      ChartType.pie => cj.PieDataset(
        key: const ValueKey('series'),
        label: 'Values',
        shadow: shadow,
        data: [for (final p in values) p.y],
        backgroundColor: color,
        borderWidth: 0,
        radius: const cj.PercentRadius(sliceExtent * 100),
      ),
      ChartType.doughnut => cj.DoughnutDataset(
        key: const ValueKey('series'),
        label: 'Values',
        shadow: shadow,
        data: [for (final p in values) p.y],
        backgroundColor: color,
        borderWidth: 0,
        radius: const cj.PercentRadius(sliceExtent * 100),
        cutout: const cj.PercentRadius(doughnutCutout * 100),
      ),
      ChartType.polarArea => cj.PolarAreaDataset(
        key: const ValueKey('series'),
        label: 'Values',
        shadow: shadow,
        data: [for (final p in values) p.y],
        backgroundColor: color,
        borderWidth: 0,
      ),
      ChartType.radar => cj.RadarDataset(
        key: const ValueKey('series'),
        label: 'Values',
        shadow: shadow,
        data: [for (final p in values) p.y],
        borderColor: const cj.ChartValue.constant(.solid(chartBlue)),
        borderWidth: 2,
        backgroundColor: const cj.ChartValue.constant(
          .solid(Color(0x264f6bed)),
        ),
        pointBackgroundColor: const .constant(.solid(chartBlue)),
        pointBorderWidth: 0,
        pointRadius: config.markers ? 3 : 0,
        pointHoverRadius: 3,
        fill: config.fill ? cj.FillTarget.toStart : cj.FillTarget.none,
      ),
      ChartType.sankey => noSankey(),
    };
    final grid = cj.AxisGrid(
      display: config.grid,
      color: const ChartPaint.solid(chartGrid),
      drawTicks: false,
    );
    final ticks = cj.AxisTicks(
      display: config.axes,
      stepSize: 25,
      font: const TextStyle(fontSize: 10),
      maxRotation: 0,
      autoSkip: true,
      extra: const {'maxTicksLimit': 5},
    );
    final view = cj.ChartView(
      config: cj.ChartConfig(
        type: switch (config.type) {
          ChartType.line => cj.ChartKind.line,
          ChartType.bar => cj.ChartKind.bar,
          ChartType.scatter => cj.ChartKind.scatter,
          ChartType.bubble => cj.ChartKind.bubble,
          ChartType.pie => cj.ChartKind.pie,
          ChartType.doughnut => cj.ChartKind.doughnut,
          ChartType.polarArea => cj.ChartKind.polarArea,
          ChartType.radar => cj.ChartKind.radar,
          ChartType.sankey => noSankey(),
        },
        datasets: [dataset],
        labels: switch (config.type) {
          ChartType.line || ChartType.scatter || ChartType.bubble => null,
          _ => _chartJsLabelsFor(values.length),
        },
        scales: switch (config.type) {
          ChartType.pie || ChartType.doughnut => null,
          ChartType.polarArea => const {
            'r': cj.RadialLinearAxis(
              min: 0,
              max: 100,
              display: false,
              pointLabelsDisplay: false,
              angleLinesDisplay: false,
            ),
          },
          ChartType.radar => {
            'r': cj.RadialLinearAxis(
              min: 0,
              max: 100,
              display: config.axes || config.grid,
              pointLabelsDisplay: config.axes,
              pointLabelsFont: const TextStyle(fontSize: 10),
              pointLabelsCallback: _radarLabelCallback(radarLabelStep),
              angleLinesDisplay: config.grid,
              angleLinesColor: const ChartPaint.solid(chartGrid),
              angleLinesLineWidth: 1,
              grid: grid.copyWith(extra: const {'circular': true}),
              ticks: ticks,
            ),
          },
          _ => {
            'x': config.type == ChartType.bar
                ? cj.CategoryAxis(
                    display: config.axes || config.grid,
                    grid: grid,
                    ticks: ticks,
                  )
                : cj.LinearAxis(
                    min: 0,
                    max: 100,
                    display: config.axes || config.grid,
                    grid: grid,
                    ticks: ticks,
                  ),
            'y': cj.LinearAxis(
              min: 0,
              max: 100,
              display: config.axes || config.grid,
              grid: grid,
              ticks: ticks,
            ),
          },
        },
        animation: cj.ChartAnimation.none,
        legend: const cj.ChartLegend(display: false),
        tooltip: cj.ChartTooltip(enabled: config.tooltips),
        responsive: true,
        maintainAspectRatio: false,
        // A radial scale has no radius option: the padding gives its share.
        padding: switch (config.type) {
          ChartType.polarArea => EdgeInsets.all(
            size.shortestSide * (1 - sliceExtent) / 2,
          ),
          ChartType.radar => EdgeInsets.all(
            math.max(
              0,
              size.shortestSide * (1 - radarExtent) / 2 -
                  (config.axes ? _radarLabelRoom : 0),
            ),
          ),
          _ => EdgeInsets.zero,
        },
        extra: {
          // The generator supplies sorted, finite numeric XY points, and a
          // DataPoint.bubble gives its radius with no parse step.
          if (config.type == ChartType.line ||
              config.type == ChartType.scatter ||
              config.type == ChartType.bubble)
            'parsing': false,
          if (config.zooms) 'plugins': {'zoom': _chartJsZoom},
          'events': config.tooltips
              ? const [
                  'mousemove',
                  'mouseout',
                  'click',
                  'touchstart',
                  'touchmove',
                ]
              : const <String>[],
        },
      ),
      updateMode: 'none',
      dataOnlyUpdates: chartJsDataOnlyUpdates,
      theme: const cj.ChartThemeData(),
      excludeFromSemantics: true,
      trackpadGestures: config.trackpad,
    );
    // A chart without zoom is the bare view, as before the toggle. A change
    // of the toggle changes the widget above the view, so it mounts a new
    // chart, which reads the registry at its first layout.
    return config.zooms ? _ChartJsZoomPlugin(child: view) : view;
  }
}

/// Registers the zoom plugin of the Chart.js port for the chart below it, and
/// removes it when the chart leaves the tree, so that a chart without zoom
/// runs no hook of the plugin. The registry holds it, as `Chart.register`
/// of the docs of the plugin does.
///
/// One engine is mounted at a time. A chart reads the registry at its first
/// layout. A build deactivates the widget of the chart before it, before
/// that layout, and the next chart registers in its `initState`. Thus a chart
/// without zoom finds no plugin, and a chart with zoom finds it. When an old
/// chart leaves the tree after a new one registered, the old one keeps the
/// plugin of the new one: only the last widget that registered removes it.
class const _ChartJsZoomPlugin({
  /// The chart, with zoom.
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<_ChartJsZoomPlugin> createState() => _ChartJsZoomPluginState();
}

class _ChartJsZoomPluginState() extends State<_ChartJsZoomPlugin> {
  /// The state that registered the plugin last, or `null`.
  static _ChartJsZoomPluginState? _owner;

  static bool get _registered =>
      cj.registry.plugins.get(zp.zoomPlugin.id) != null;

  void _register() {
    if (!_registered) cj.Chart.register([zp.zoomPlugin]);
    _owner = this;
  }

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void activate() {
    super.activate();
    _register();
  }

  @override
  void deactivate() {
    if (identical(_owner, this)) {
      _owner = null;
      if (_registered) cj.Chart.unregister([zp.zoomPlugin]);
    }
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
