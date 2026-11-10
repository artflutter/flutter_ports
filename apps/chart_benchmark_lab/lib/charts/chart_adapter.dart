import 'dart:math' as math;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart'
    show chartJsDataOnlyUpdates;
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:flutter/gestures.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    as zp;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as cj;
import 'package:graphic/graphic.dart' as gr;
import 'package:material_ui/material_ui.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as sf;

/// One active public-widget adapter; inactive engines are never mounted.
class BenchmarkChart extends StatelessWidget {
  /// All engines receive the same immutable source values and feature settings.
  const BenchmarkChart({
    required this.library,
    required this.config,
    required this.frame,
    required this.size,
    super.key,
  });

  /// Selected engine.
  final ChartLibrary library;

  /// Common effective features.
  final BenchmarkConfig config;

  /// Shared input snapshot.
  final DatasetFrame frame;

  /// Identical outer viewport for every engine.
  final Size size;

  /// The outer radius of a pie, doughnut or polar area, as a share of half of
  /// the short side.
  static const _sliceExtent = .9;

  /// The outer radius of a radar. fl_chart fixes its radar radius at this
  /// share, so the other engines take the same share.
  static const _radarExtent = .8;

  /// The space that the point labels of a Chart.js radar take from its radius,
  /// in logical pixels, with the 10 px label font.
  static const _radarLabelRoom = 24.0;

  /// The inner radius of a doughnut, as a share of its outer radius.
  static const _doughnutCutout = .5;

  /// The number of labels around a radar stays controlled, as on an x axis. A
  /// radar still has one spoke per item.
  int get _radarLabelStep => math.max(1, (config.count / 8).ceil());

  /// One label List per item count. An app with stable labels keeps its List,
  /// so a new data List does not also replace the labels of the chart.
  static final Map<int, List<String>> _chartJsLabels = {};

  static List<String> _chartJsLabelsFor(int count) =>
      _chartJsLabels.putIfAbsent(
        count,
        () => [for (var i = 0; i < count; i++) '$i'],
      );

  /// One point-label callback per label step: a new closure is a new option
  /// value for `ChartConfig ==`.
  static final Map<int, Object? Function(Object?, num)> _radarLabelCallbacks =
      {};

  static Object? Function(Object?, num) _radarLabelCallback(int step) =>
      _radarLabelCallbacks.putIfAbsent(
        step,
        () =>
            (label, index) => index % step == 0 ? label : '',
      );

  /// The fl_chart line shadow. fl_chart converts the radius to a sigma with
  /// `radius * 0.57735 + 0.5`.
  Shadow get _flShadow => config.shadow
      ? Shadow(
          color: chartShadow,
          offset: chartShadowOffset,
          blurRadius: config.shadowBlur ? (chartShadowSigma - .5) / .57735 : 0,
        )
      : const Shadow(color: Colors.transparent);

  /// The Graphic shadow: Material elevation, the only shadow of its API.
  gr.ElevationEncode? get _graphicElevation =>
      config.shadow ? gr.ElevationEncode(value: 4) : null;

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
  // - the Chart.js port: its host maps no pan-zoom event to a DOM event
  //   (Chart.js ADR 0108 Open 5, seam H27 of the zoom port), so a trackpad
  //   does not zoom or pan it.
  // A trackpad scroll over the chart also scrolls the page, as anywhere else.
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
        // A category axis counts the bars from 0, a linear axis goes to 100.
        'minRange':
            (config.type == ChartType.bar ? config.count - 1 : 100) /
            chartMaxZoom,
      },
    },
  };

  /// The zoom of fl_chart: `FlScaleAxis.horizontal` zooms and pans only x.
  /// fl_chart zooms with a pinch and with the mouse wheel, and pans with a
  /// drag. A trackpad scroll pans, its default
  /// (`trackpadScrollCausesScale: false`). Its `minScale` 1 keeps the full
  /// range, and its viewer stops a pan at the edge of the data.
  fl.FlTransformationConfig get _flZoom => config.zooms
      ? const fl.FlTransformationConfig(
          scaleAxis: fl.FlScaleAxis.horizontal,
          maxScale: chartMaxZoom,
        )
      : const fl.FlTransformationConfig();

  /// The default range event of Graphic: a one-pointer drag pans, a pinch
  /// zooms by the horizontal spread of the fingers (a vertical pinch does
  /// nothing), and the mouse wheel zooms by 10%. A pinch and the wheel grow
  /// or shrink the range on both sides alike, around the middle of the data,
  /// not at the fingers or the cursor. Its double tap, which goes back to
  /// the full range, is off (see [_graphicRange]). A bar keeps its width in
  /// pixels, the size of its mark, as an fl_chart rod does.
  static final gr.EventUpdater<List<double>> _graphicRangeEvent =
      gr.Defaults.horizontalRangeEvent;

  /// The horizontal range updater of Graphic: [_graphicRangeEvent], kept
  /// inside the full range and at most [chartMaxZoom] times, as the other
  /// libraries are. Without the bounds, a Graphic pan moves the data out of
  /// view, and a zoom out makes it smaller than the plot. A double tap keeps
  /// the range: the other libraries have no double-tap reset (the double-tap
  /// zoom of Syncfusion is off).
  static List<double> _graphicRange(
    List<double> init,
    List<double> pre,
    gr.Event event,
  ) {
    if (event is gr.GestureEvent &&
        event.gesture.type == gr.GestureType.doubleTap) {
      return pre;
    }
    final next = _graphicRangeEvent(init, pre, event);
    // The range is the width of the data as a share of the plot: [0, 1] is
    // the full range, and a zoom makes it wider.
    final width = (next.last - next.first).clamp(1.0, chartMaxZoom);
    final start = ((next.first + next.last - width) / 2).clamp(1 - width, 0.0);
    return start == next.first && start + width == next.last
        ? next
        : [start, start + width];
  }

  /// The zoom of Syncfusion: pinch, pan and wheel zoom, with `ZoomMode.x`.
  /// `maximumZoomLevel` 1/[chartMaxZoom] is its default 0.01. A zoom out stops
  /// at the full range, and a pan stays inside it. The selection zoom (a box)
  /// and the double-tap zoom stay off: fl_chart and Graphic have neither.
  sf.ZoomPanBehavior? get _sfZoom => config.zooms
      ? sf.ZoomPanBehavior(
          enablePinching: true,
          enablePanning: true,
          enableMouseWheelZooming: true,
          zoomMode: sf.ZoomMode.x,
          // The default, given so that a change of chartMaxZoom reaches it.
          // ignore: avoid_redundant_argument_values
          maximumZoomLevel: 1 / chartMaxZoom,
        )
      : null;

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
    final chart = switch (library) {
      ChartLibrary.chartjs => _chartJs(),
      ChartLibrary.flChart => _flChart(),
      ChartLibrary.graphic => _graphic(),
      ChartLibrary.syncfusion => _syncfusion(),
    };
    return config.zooms
        ? Listener(onPointerSignal: _claimWheel, child: chart)
        : chart;
  }

  Color _color(int index) =>
      config.alternateColors && config.type.hasItemColors && index.isOdd
      ? chartTeal
      : chartBlue;

  Widget _chartJs() {
    final values = frame.values;
    final color = config.alternateColors && config.type.hasItemColors
        ? const cj.ChartValue<Color>.indexed([chartBlue, chartTeal])
        : const cj.ChartValue<Color>.constant(chartBlue);
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
        borderColor: const cj.ChartValue.constant(chartBlue),
        borderWidth: 2,
        backgroundColor: const cj.ChartValue.constant(Color(0x264f6bed)),
        pointBackgroundColor: chartBlue,
        pointBorderWidth: 0,
        pointRadius: config.markers ? 3 : 0,
        pointHoverRadius: 3,
        tension: config.curved ? .35 : 0,
        fill: config.fill ? cj.ChartFill.origin : cj.ChartFill.none,
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
        radius: const cj.ChartLength.percent(_sliceExtent * 100),
      ),
      ChartType.doughnut => cj.DoughnutDataset(
        key: const ValueKey('series'),
        label: 'Values',
        shadow: shadow,
        data: [for (final p in values) p.y],
        backgroundColor: color,
        borderWidth: 0,
        radius: const cj.ChartLength.percent(_sliceExtent * 100),
        cutout: const cj.ChartLength.percent(_doughnutCutout * 100),
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
        borderColor: const cj.ChartValue.constant(chartBlue),
        borderWidth: 2,
        backgroundColor: const cj.ChartValue.constant(Color(0x264f6bed)),
        pointBackgroundColor: chartBlue,
        pointBorderWidth: 0,
        pointRadius: config.markers ? 3 : 0,
        pointHoverRadius: 3,
        fill: config.fill ? cj.ChartFill.start : cj.ChartFill.none,
      ),
    };
    final grid = cj.AxisGrid(
      display: config.grid,
      color: chartGrid,
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
              angleLinesDisplay: config.grid,
              angleLinesColor: chartGrid,
              angleLinesLineWidth: 1,
              grid: grid.copyWith(extra: const {'circular': true}),
              ticks: ticks,
              extra: {
                'pointLabels': {
                  'callback': _radarLabelCallback(_radarLabelStep),
                },
              },
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
            size.shortestSide * (1 - _sliceExtent) / 2,
          ),
          ChartType.radar => EdgeInsets.all(
            math.max(
              0,
              size.shortestSide * (1 - _radarExtent) / 2 -
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
    );
    // A chart without zoom is the bare view, as before the toggle. A change
    // of the toggle changes the widget above the view, so it mounts a new
    // chart, which reads the registry at its first layout.
    return config.zooms ? _ChartJsZoomPlugin(child: view) : view;
  }

  fl.FlTitlesData get _titles => fl.FlTitlesData(
    show: config.axes,
    topTitles: const fl.AxisTitles(),
    rightTitles: const fl.AxisTitles(),
    leftTitles: fl.AxisTitles(
      sideTitles: fl.SideTitles(
        showTitles: config.axes,
        reservedSize: 30,
        interval: 25,
        getTitlesWidget: (value, meta) => Text(
          value.toInt().toString(),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    ),
    bottomTitles: fl.AxisTitles(
      sideTitles: fl.SideTitles(
        showTitles: config.axes,
        interval: config.type == ChartType.bar
            ? math.max(1, config.count / 4)
            : 25,
        getTitlesWidget: (value, meta) => Text(
          value.toInt().toString(),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    ),
  );
  fl.FlGridData get _grid => fl.FlGridData(
    show: config.grid,
    horizontalInterval: 25,
    verticalInterval: config.type == ChartType.bar
        ? math.max(1, config.count / 4)
        : 25,
    getDrawingHorizontalLine: (_) =>
        const fl.FlLine(color: chartGrid, strokeWidth: 1),
    getDrawingVerticalLine: (_) =>
        const fl.FlLine(color: chartGrid, strokeWidth: 1),
  );

  // The default of fl_chart takes the text color from the line color, which
  // has low contrast on its blue-grey tooltip background.
  static List<fl.LineTooltipItem> _flLineTooltipItems(
    List<fl.LineBarSpot> spots,
  ) => [
    for (final spot in spots)
      fl.LineTooltipItem(
        spot.y.toString(),
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
  ];

  Widget _flChart() {
    final values = frame.values;
    switch (config.type) {
      case ChartType.line:
        return fl.LineChart(
          fl.LineChartData(
            minX: 0,
            maxX: 100,
            minY: 0,
            maxY: 100,
            titlesData: _titles,
            gridData: _grid,
            borderData: fl.FlBorderData(show: false),
            clipData: const fl.FlClipData.all(),
            lineTouchData: fl.LineTouchData(
              enabled: config.tooltips,
              touchTooltipData: const fl.LineTouchTooltipData(
                getTooltipItems: _flLineTooltipItems,
              ),
            ),
            lineBarsData: [
              fl.LineChartBarData(
                spots: [for (final p in values) fl.FlSpot(p.x, p.y)],
                color: chartBlue,
                isCurved: config.curved,
                shadow: _flShadow,
                dotData: fl.FlDotData(
                  show: config.markers,
                  getDotPainter: (_, _, _, _) => fl.FlDotCirclePainter(
                    radius: 3,
                    color: chartBlue,
                  ),
                ),
                belowBarData: fl.BarAreaData(
                  show: config.fill,
                  color: const Color(0x264f6bed),
                ),
              ),
            ],
          ),
          duration: Duration.zero,
          transformationConfig: _flZoom,
        );
      case ChartType.bar:
        return fl.BarChart(
          fl.BarChartData(
            minY: 0,
            maxY: 100,
            alignment: fl.BarChartAlignment.spaceAround,
            titlesData: _titles,
            gridData: _grid,
            borderData: fl.FlBorderData(show: false),
            barTouchData: fl.BarTouchData(enabled: config.tooltips),
            barGroups: [
              for (final p in values)
                fl.BarChartGroupData(
                  x: p.index,
                  barRods: [
                    fl.BarChartRodData(
                      toY: p.y,
                      color: _color(p.index),
                      width: math.max(
                        .01,
                        (size.width - (config.axes ? 30 : 0)) /
                            config.count *
                            .8,
                      ),
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                ),
            ],
          ),
          duration: Duration.zero,
          transformationConfig: _flZoom,
        );
      case ChartType.scatter:
      case ChartType.bubble:
        return fl.ScatterChart(
          fl.ScatterChartData(
            minX: 0,
            maxX: 100,
            minY: 0,
            maxY: 100,
            titlesData: _titles,
            gridData: _grid,
            borderData: fl.FlBorderData(show: false),
            scatterTouchData: fl.ScatterTouchData(enabled: config.tooltips),
            scatterSpots: [
              for (final p in values)
                fl.ScatterSpot(
                  p.x,
                  p.y,
                  dotPainter: fl.FlDotCirclePainter(
                    radius: config.type == ChartType.bubble ? p.r : 3,
                    color: _color(p.index),
                  ),
                ),
            ],
          ),
          duration: Duration.zero,
          transformationConfig: _flZoom,
        );
      case ChartType.pie:
      case ChartType.doughnut:
      case ChartType.polarArea:
        final outer = size.shortestSide / 2 * _sliceExtent;
        final hole = config.type == ChartType.doughnut
            ? outer * _doughnutCutout
            : 0.0;
        final polar = config.type == ChartType.polarArea;
        return fl.PieChart(
          fl.PieChartData(
            centerSpaceRadius: hole,
            sectionsSpace: 0,
            startDegreeOffset: -90,
            pieTouchData: fl.PieTouchData(enabled: config.tooltips),
            sections: [
              for (final p in values)
                fl.PieChartSectionData(
                  value: polar ? 1 : p.y,
                  color: _color(p.index),
                  radius: polar ? outer * p.y / 100 : outer - hole,
                  showTitle: false,
                ),
            ],
          ),
          duration: Duration.zero,
        );
      case ChartType.radar:
        final side = config.grid
            ? const BorderSide(color: chartGrid)
            : const BorderSide(color: Colors.transparent, width: 0);
        final step = _radarLabelStep;
        const label = TextStyle(fontSize: 10, color: Color(0xff677489));
        return fl.RadarChart(
          fl.RadarChartData(
            radarBorderData: side,
            tickBorderData: side,
            gridBorderData: side,
            tickCount: 4,
            // The default offset puts the top and bottom labels outside a plot
            // that fills its height.
            titlePositionPercentageOffset: .1,
            ticksTextStyle: config.axes
                ? label
                : const TextStyle(fontSize: 10, color: Colors.transparent),
            titleTextStyle: label,
            getTitle: config.axes
                ? (index, _) => fl.RadarChartTitle(
                    text: index % step == 0 ? '$index' : '',
                  )
                : null,
            radarTouchData: fl.RadarTouchData(enabled: config.tooltips),
            dataSets: [
              fl.RadarDataSet(
                dataEntries: [
                  for (final p in values) fl.RadarEntry(value: p.y),
                ],
                fillColor: config.fill
                    ? const Color(0x264f6bed)
                    : Colors.transparent,
                borderColor: chartBlue,
                borderWidth: 2,
                entryRadius: config.markers ? 3 : 0,
              ),
            ],
          ),
          duration: Duration.zero,
        );
    }
  }

  Widget _graphic() {
    final slices =
        config.type == ChartType.pie || config.type == ChartType.doughnut;
    final radial =
        slices ||
        config.type == ChartType.polarArea ||
        config.type == ChartType.radar;
    final variables = <String, gr.Variable<Sample, dynamic>>{
      if (!radial)
        'x': gr.Variable(
          accessor: (p) => p.x,
          scale: gr.LinearScale(min: 0, max: 100, ticks: [0, 25, 50, 75, 100]),
        ),
      'y': gr.Variable(
        accessor: (p) => p.y,
        scale: gr.LinearScale(min: 0, max: 100, ticks: [0, 25, 50, 75, 100]),
      ),
      if (config.type == ChartType.bar || radial)
        'item': gr.Variable(
          accessor: (p) => '${p.index}',
          // A radar has one spoke per item, so one tick per item.
          scale: gr.OrdinalScale(
            tickCount: config.type == ChartType.radar ? null : 5,
          ),
        ),
      if (config.alternateColors && config.type.hasItemColors)
        'index': gr.Variable(accessor: (p) => p.index),
    };
    gr.ColorEncode color() => config.alternateColors
        ? gr.ColorEncode(encoder: (tuple) => _color(tuple['index'] as int))
        : gr.ColorEncode(value: chartBlue);
    final marks = <gr.Mark>[];
    switch (config.type) {
      case ChartType.line:
        if (config.fill) {
          marks.add(
            gr.AreaMark(
              color: gr.ColorEncode(value: const Color(0x264f6bed)),
              shape: gr.ShapeEncode(
                value: gr.BasicAreaShape(smooth: config.curved),
              ),
            ),
          );
        }
        marks.add(
          gr.LineMark(
            color: gr.ColorEncode(value: chartBlue),
            size: gr.SizeEncode(value: 2),
            shape: gr.ShapeEncode(
              value: gr.BasicLineShape(smooth: config.curved),
            ),
          ),
        );
        if (config.markers) {
          marks.add(
            gr.PointMark(
              color: gr.ColorEncode(value: chartBlue),
              size: gr.SizeEncode(value: 6),
            ),
          );
        }
      case ChartType.bar:
        marks.add(
          gr.IntervalMark(
            position: gr.Varset('item') * gr.Varset('y'),
            color: color(),
            size: gr.SizeEncode(
              value: math.max(
                .01,
                (size.width - (config.axes ? 30 : 0)) / config.count * .8,
              ),
            ),
          ),
        );
      case ChartType.scatter:
        marks.add(gr.PointMark(color: color(), size: gr.SizeEncode(value: 6)));
      case ChartType.bubble:
        marks.add(
          gr.PointMark(
            color: color(),
            size: gr.SizeEncode(
              encoder: (tuple) => bubbleRadius(tuple['y'] as double) * 2,
            ),
          ),
        );
      case ChartType.pie:
      case ChartType.doughnut:
        marks.add(
          gr.IntervalMark(
            position: gr.Varset('share') / gr.Varset('item'),
            color: color(),
            modifiers: [gr.StackModifier()],
          ),
        );
      case ChartType.polarArea:
        marks.add(
          gr.IntervalMark(
            position: gr.Varset('item') * gr.Varset('y'),
            color: color(),
          ),
        );
      case ChartType.radar:
        gr.Varset position() => gr.Varset('item') * gr.Varset('y');
        if (config.fill) {
          marks.add(
            gr.AreaMark(
              position: position(),
              color: gr.ColorEncode(value: const Color(0x264f6bed)),
              shape: gr.ShapeEncode(value: gr.BasicAreaShape(loop: true)),
            ),
          );
        }
        marks.add(
          gr.LineMark(
            position: position(),
            color: gr.ColorEncode(value: chartBlue),
            size: gr.SizeEncode(value: 2),
            shape: gr.ShapeEncode(value: gr.BasicLineShape(loop: true)),
          ),
        );
        if (config.markers) {
          marks.add(
            gr.PointMark(
              position: position(),
              color: gr.ColorEncode(value: chartBlue),
              size: gr.SizeEncode(value: 6),
            ),
          );
        }
    }
    // Only the filled marks: on a line, the elevation shadows a polygon.
    if (!config.type.drawsLine) {
      for (final mark in marks) {
        mark.elevation = _graphicElevation;
      }
    }
    final axes = <gr.AxisGuide<dynamic>>[];
    if (config.type.hasAxes && (config.axes || config.grid)) {
      final labelStyle = config.axes
          ? gr.LabelStyle(
              textStyle: const TextStyle(
                fontSize: 10,
                color: Color(0xff677489),
              ),
            )
          : null;
      final gridStyle = config.grid
          ? gr.PaintStyle(strokeColor: chartGrid, strokeWidth: 1)
          : null;
      if (config.type == ChartType.radar) {
        final step = _radarLabelStep;
        axes
          ..add(
            gr.AxisGuide(
              variable: 'item',
              position: 1,
              labelMapper: config.axes
                  ? (_, index, _) => index % step == 0 ? labelStyle : null
                  : null,
              grid: gridStyle,
            ),
          )
          ..add(
            gr.AxisGuide(variable: 'y', label: labelStyle, grid: gridStyle),
          );
      } else {
        for (final variable in [
          if (config.type == ChartType.bar) 'item' else 'x',
          'y',
        ]) {
          axes.add(
            gr.AxisGuide(
              variable: variable,
              label: labelStyle,
              grid: gridStyle,
            ),
          );
        }
      }
    }
    return gr.Chart<Sample>(
      data: frame.values,
      variables: variables,
      marks: marks,
      // Configuration changes remount the adapter; normal ticks only
      // change data.
      rebuild: false,
      changeData: config.workload == Workload.live,
      transforms: slices ? [gr.Proportion(variable: 'y', as: 'share')] : null,
      coord: switch (config.type) {
        ChartType.pie => gr.PolarCoord(
          transposed: true,
          dimCount: 1,
          radiusRange: [0, _sliceExtent],
        ),
        ChartType.doughnut => gr.PolarCoord(
          transposed: true,
          dimCount: 1,
          radiusRange: [_sliceExtent * _doughnutCutout, _sliceExtent],
        ),
        ChartType.polarArea => gr.PolarCoord(radiusRange: [0, _sliceExtent]),
        // Unlike a radius range, this also limits the spokes and the labels.
        ChartType.radar => gr.PolarCoord(endRadius: _radarExtent),
        _ when config.zooms => gr.RectCoord(
          horizontalRangeUpdater: _graphicRange,
        ),
        _ => null,
      },
      padding: (_) =>
          config.axes && config.type.hasAxes && config.type != ChartType.radar
          ? const EdgeInsets.fromLTRB(30, 0, 0, 22)
          : EdgeInsets.zero,
      axes: axes,
      selections: config.tooltips
          ? {
              'tap': gr.PointSelection(
                on: {gr.GestureType.tap, gr.GestureType.hover},
              ),
            }
          : {},
      tooltip: config.tooltips ? gr.TooltipGuide() : null,
    );
  }

  Widget _syncfusion() {
    final marker = sf.MarkerSettings(
      isVisible: config.markers,
      width: 6,
      height: 6,
      borderWidth: 0,
      color: chartBlue,
    );
    if (!config.type.hasAxes) {
      const radius = '${_sliceExtent * 100}%';
      return sf.SfCircularChart(
        margin: EdgeInsets.zero,
        tooltipBehavior: sf.TooltipBehavior(enable: config.tooltips),
        series: <sf.CircularSeries<Sample, int>>[
          switch (config.type) {
            ChartType.doughnut => sf.DoughnutSeries<Sample, int>(
              dataSource: frame.values,
              xValueMapper: (p, _) => p.index,
              yValueMapper: (p, _) => p.y,
              pointColorMapper: (p, _) => _color(p.index),
              animationDuration: 0,
              radius: radius,
              innerRadius: '${_doughnutCutout * 100}%',
            ),
            // The public form of a polar area: equal slices, a radius for each.
            ChartType.polarArea => sf.PieSeries<Sample, int>(
              dataSource: frame.values,
              xValueMapper: (p, _) => p.index,
              yValueMapper: (_, _) => 1,
              pointColorMapper: (p, _) => _color(p.index),
              pointRadiusMapper: (p, _) => '${p.y * _sliceExtent}%',
              animationDuration: 0,
              radius: radius,
            ),
            _ => sf.PieSeries<Sample, int>(
              dataSource: frame.values,
              xValueMapper: (p, _) => p.index,
              yValueMapper: (p, _) => p.y,
              pointColorMapper: (p, _) => _color(p.index),
              animationDuration: 0,
              radius: radius,
            ),
          },
        ],
      );
    }
    final series = <sf.CartesianSeries<Sample, num>>[];
    if (config.type == ChartType.line) {
      if (config.fill) {
        if (config.curved) {
          series.add(
            sf.SplineAreaSeries<Sample, num>(
              dataSource: frame.values,
              xValueMapper: (p, _) => p.x,
              yValueMapper: (p, _) => p.y,
              color: const Color(0x264f6bed),
              borderColor: chartBlue,
              markerSettings: marker,
              animationDuration: 0,
            ),
          );
        } else {
          series.add(
            sf.AreaSeries<Sample, num>(
              dataSource: frame.values,
              xValueMapper: (p, _) => p.x,
              yValueMapper: (p, _) => p.y,
              color: const Color(0x264f6bed),
              borderColor: chartBlue,
              markerSettings: marker,
              animationDuration: 0,
            ),
          );
        }
      } else if (config.curved) {
        series.add(
          sf.SplineSeries<Sample, num>(
            dataSource: frame.values,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            color: chartBlue,
            markerSettings: marker,
            animationDuration: 0,
          ),
        );
      } else {
        series.add(
          sf.LineSeries<Sample, num>(
            dataSource: frame.values,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            color: chartBlue,
            markerSettings: marker,
            animationDuration: 0,
          ),
        );
      }
    } else if (config.type == ChartType.bar) {
      series.add(
        sf.ColumnSeries<Sample, num>(
          dataSource: frame.values,
          xValueMapper: (p, _) => p.index,
          yValueMapper: (p, _) => p.y,
          pointColorMapper: (p, _) => _color(p.index),
          color: chartBlue,
          width: .8,
          animationDuration: 0,
        ),
      );
    } else if (config.type == ChartType.bubble) {
      series.add(
        sf.BubbleSeries<Sample, num>(
          dataSource: frame.values,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          // The series divides each size by the largest size, then scales it
          // into the range below, so y gives the shared radius formula. A
          // segment draws at twice its radius, so the range is half of it.
          sizeValueMapper: (p, _) => p.y,
          minimumRadius: bubbleRadius(0) / 2,
          maximumRadius: bubbleRadius(100) / 2,
          pointColorMapper: (p, _) => _color(p.index),
          color: chartBlue,
          animationDuration: 0,
        ),
      );
    } else {
      series.add(
        sf.ScatterSeries<Sample, num>(
          dataSource: frame.values,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          pointColorMapper: (p, _) => _color(p.index),
          color: chartBlue,
          markerSettings: const sf.MarkerSettings(
            width: 6,
            height: 6,
            borderWidth: 0,
          ),
          animationDuration: 0,
        ),
      );
    }
    sf.NumericAxis axis({required bool x}) => sf.NumericAxis(
      minimum: 0,
      maximum: x && config.type == ChartType.bar
          ? (config.count - 1).toDouble()
          : 100,
      interval: x && config.type == ChartType.bar
          ? math.max(1, config.count / 4)
          : 25,
      isVisible: config.axes || config.grid,
      labelStyle: TextStyle(
        fontSize: 10,
        color: config.axes ? const Color(0xff677489) : Colors.transparent,
      ),
      axisLine: const sf.AxisLine(width: 0),
      majorTickLines: const sf.MajorTickLines(size: 0),
      majorGridLines: sf.MajorGridLines(
        width: config.grid ? 1 : 0,
        color: chartGrid,
      ),
    );
    return sf.SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      primaryXAxis: axis(x: true),
      primaryYAxis: axis(x: false),
      tooltipBehavior: sf.TooltipBehavior(enable: config.tooltips),
      zoomPanBehavior: _sfZoom,
      series: series,
    );
  }
}

/// Registers the zoom plugin of the Chart.js port for the chart below it, and
/// removes it when the chart leaves the tree, so that a chart without zoom
/// runs no hook of the plugin. The typed plugin `zoomPlugin` cannot be an
/// inline plugin of one typed chart: `ChartConfig.plugins` takes only plugin
/// Maps (seam H18 of the zoom port). Thus the registry holds it, as
/// `Chart.register` of the docs of the plugin does.
///
/// One engine is mounted at a time. A chart reads the registry at its first
/// layout. A build deactivates the widget of the chart before it, before
/// that layout, and the next chart registers in its `initState`. Thus a chart
/// without zoom finds no plugin, and a chart with zoom finds it. When an old
/// chart leaves the tree after a new one registered, the old one keeps the
/// plugin of the new one: only the last widget that registered removes it.
class _ChartJsZoomPlugin extends StatefulWidget {
  const _ChartJsZoomPlugin({required this.child});

  /// The chart, with zoom.
  final Widget child;

  @override
  State<_ChartJsZoomPlugin> createState() => _ChartJsZoomPluginState();
}

class _ChartJsZoomPluginState extends State<_ChartJsZoomPlugin> {
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
