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
final ChartTooltip _tooltip =
    graphicTooltip(
      position: const CenterPositioner(),
      title: (items) => 'genre: ${_genres[items.first.dataIndex]}',
      label: (item) => 'sold: ${item.raw}',
    ).copyWith(
      backgroundColor: const .solid(Color(0xFF000000)),
      titleColor: const .solid(Gx.text),
      titleFont: const TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
      bodyColor: const .solid(Gx.text),
      bodyFont: const TextStyle(fontSize: 10),
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
      type: .bar,
      labels: _genres,
      datasets: [
        BarDataset(
          data: _sold,
          backgroundColor: const .constant(.solid(Gx.primary)),
          hoverBackgroundColor: const .constant(.solid(Gx.primary)),
          barThickness: barSize,
          // The bars start at 0, or at the bottom of the axis when 0 is
          // below it.
          extra: {'base': max(range.min, 0)},
        ),
      ],
      scales: {
        'x': CategoryAxis(
          grid: noGrid,
          ticks: graphicTicks(),
          border: bottomBorder,
          extra: bottomAxis,
        ),
        'y': LinearAxis(
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
      },
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
      tooltip: _tooltip,
      plugins: _plugins,
      // No `mouseout`: the selection stays when the pointer leaves.
      extra: const {
        'events': ['mousemove', 'click', 'touchstart', 'touchmove'],
      },
    );
  }

  @override
  Widget build(BuildContext context) => graphicSizedBox(
    ChartView(
      config: _config,
      semanticLabel: 'Bar chart of random sales of five game genres',
    ),
    width: 650,
  );
}
// #enddocregion graphic-bar-auto-update
