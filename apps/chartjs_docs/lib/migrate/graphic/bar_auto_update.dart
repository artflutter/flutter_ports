// Original code, not ported from Chart.js: a replica of the Graphic demo "Auto update".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-bar-auto-update
import 'dart:async';
import 'dart:math';

import 'package:chartjs_docs/migrate/graphic/graphic_bar_kit.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const List<String> _genres = [
  'Sports',
  'Strategy',
  'Action',
  'Shooter',
  'Other',
];

/// `TooltipGuide(backgroundColor: Colors.black, elevation: 5, textStyle:
/// Defaults.textStyle, variables: ['genre', 'sold'])`.
final TooltipOptions _tooltip =
    graphicTooltip(
      position: const CenterPositioner(),
      title: (items) => 'genre: ${_genres[items.first.dataIndex]}',
      label: (item) => 'sold: ${item.raw}',
    ).merge(
      const TooltipOptions(
        backgroundColor: .solid(Color(0xFF000000)),
        titleColor: .solid(Gx.text),
        titleFont: TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
        bodyColor: .solid(Gx.text),
        bodyFont: TextStyle(fontSize: 10),
      ),
    );

final List<Plugin<Object?>> _plugins = [
  barCrosshair,
  tooltipElevation(color: const Color(0xFF000000), elevation: 5),
  tapSelection(),
];

/// The replica of the Graphic demo "Auto update".
class const GraphicBarAutoUpdate({super.key}) extends StatefulWidget {
  /// Creates the replica.
  this;

  @override
  State<GraphicBarAutoUpdate> createState() => _GraphicBarAutoUpdateState();
}

class _GraphicBarAutoUpdateState() extends State<GraphicBarAutoUpdate> {
  final Random _random = Random();

  late List<int> _sold = _next();

  late final Timer _timer;

  List<int> _next() => [for (final _ in _genres) _random.nextInt(300)];

  @override
  void initState() {
    super.initState();
    // New data every second.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _sold = _next());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  ChartConfig get _config {
    final range = graphicRange(_sold);
    return ChartConfig(
      labels: _genres,
      datasets: [
        BarDataset(
          data: .values(_sold),
          backgroundColor: const .constant(.solid(Gx.primary)),
          hoverBackgroundColor: const .constant(.solid(Gx.primary)),
          barThickness: const BarThickness.pixels(barSize),
          // The bars start at 0, or at the bottom of the axis when 0 is
          // below it.
          extra: {'base': max(range.min, 0)},
        ),
      ],
      scales: [
        CategoryAxis(
          .x,
          grid: noGrid,
          ticks: graphicTicks(),
          border: bottomBorder,
          extra: bottomAxis,
        ),
        LinearAxis(
          .y,
          min: range.min,
          max: range.max,
          grid: lineGrid,
          ticks: graphicTicks(
            callback: numberLabel,
            extra: const {'maxTicksLimit': 5},
          ),
          border: leftBorder,
          extra: leftAxis,
        ),
      ],
      padding: regionPadding,
      maintainAspectRatio: false,
      // `rebuild: false` with no transition: the bars change at once.
      animation: ChartAnimation.none,
      legend: const ChartLegend(display: false),
      // `PointSelection(on: {GestureType.hover, GestureType.tap}, dim:
      // Dim.x)`.
      interaction: const ChartInteraction(
        mode: IndexInteractionMode(),
        intersect: false,
      ),
      pluginOptions: [_tooltip],
      plugins: _plugins,
      // No `mouseout`: the selection stays when the pointer leaves.
      events: const ['mousemove', 'click', 'touchstart', 'touchmove'],
    );
  }

  @override
  Widget build(BuildContext context) => GraphicBox(
    width: 650,
    child: ChartView(
      config: _config,
      semanticLabel: 'Bar chart of random sales of five game genres',
    ),
  );
}
// #enddocregion graphic-bar-auto-update

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: GraphicBarAutoUpdate(),
        ),
      ),
    ),
  );
}
