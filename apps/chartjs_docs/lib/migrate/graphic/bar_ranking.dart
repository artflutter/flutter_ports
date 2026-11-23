// Original code, not ported from Chart.js: a replica of the Graphic demo "Auto Animated Ranking".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-bar-ranking
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

/// The replica of the Graphic demo "Auto Animated Ranking".
class const GraphicBarRanking({super.key}) extends StatefulWidget {
  /// Creates the replica.
  this;

  @override
  State<GraphicBarRanking> createState() => _GraphicBarRankingState();
}

class _GraphicBarRankingState() extends State<GraphicBarRanking> {
  final Random _random = Random();

  /// The sales of each genre, in the order of [_genres].
  late List<int> _sold = _next();

  /// The rank of each genre: `Sort` by the sales, from low to high.
  late List<int> _ranks = _rank(_sold);

  late final Timer _timer;

  /// The label of each bar: the sales of its genre.
  late final Plugin<Object?> _labels = barLabels(
    (dataset, index) => '${_sold[index]}',
  );

  List<int> _next() => [for (final _ in _genres) _random.nextInt(300)];

  static List<int> _rank(List<int> sold) {
    final order = List.generate(sold.length, (i) => i)
      ..sort((a, b) => sold[a] != sold[b] ? sold[a] - sold[b] : a - b);
    return [for (var i = 0; i < sold.length; i++) order.indexOf(i)];
  }

  @override
  void initState() {
    super.initState();
    // New data every 2 seconds.
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        _sold = _next();
        _ranks = _rank(_sold);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  /// The genre at a rank of the x axis.
  List<String>? _genreAt(
    Scale scale,
    double value,
    int index,
    List<Tick> ticks,
  ) => [_genres[_ranks.indexOf(value.round())]];

  ChartConfig get _config {
    final low = _sold.reduce(min);
    final high = _sold.reduce(max);
    return ChartConfig(
      datasets: [
        // `tag: (tuple) => tuple['genre']`: each genre keeps its bar. The
        // bar of a genre stands at its rank, so it moves to its new rank.
        BarDataset(
          data: .points([
            for (var i = 0; i < _genres.length; i++)
              DataPoint(_ranks[i], _sold[i]),
          ]),
          backgroundColor: const .constant(.solid(Gx.primary)),
          barThickness: const BarThickness.pixels(barSize),
        ),
      ],
      scales: [
        LinearAxis(
          .x,
          min: -0.5,
          max: _genres.length - 0.5,
          grid: noGrid,
          ticks: graphicTicks(callback: _genreAt),
          border: bottomBorder,
          extra: {
            ...bottomAxis,
            'offset': false,
            // One tick for each rank.
            'afterBuildTicks': tickValues(const [0, 1, 2, 3, 4]),
          },
        ),
        // `LinearScale(min: 0)`: 10% of the range of the data above it.
        LinearAxis(
          .y,
          min: 0,
          max: high + (high - low) * 0.1,
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
      // `Transition(duration: const Duration(seconds: 1))` with no curve,
      // and `MarkEntrance.y`: the bars grow from 0 first.
      animation: const ChartAnimation(
        duration: Duration(seconds: 1),
        easing: Curves.linear,
      ),
      legend: const ChartLegend(display: false),
      tooltip: const ChartTooltip(enabled: false),
      plugins: [_labels],
      // The demo has no selection.
      events: const [],
    );
  }

  @override
  Widget build(BuildContext context) => GraphicBox(
    child: ChartView(
      config: _config,
      semanticLabel: 'Bar chart of random sales of five game genres, by rank',
    ),
  );
}
// #enddocregion graphic-bar-ranking

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: GraphicBarRanking(),
        ),
      ),
    ),
  );
}
