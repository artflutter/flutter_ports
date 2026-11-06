import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/benchmark/metrics.dart';

/// The metrics of a comparison. The metrics with a margin decide the rank, in
/// this order.
///
/// FPS and the frame interval are the end-to-end figures, because a library can
/// defer work outside the UI and raster timings. A difference inside a margin
/// is noise between two runs, not a win. Among charts that all reach the
/// display rate, the UI and raster work shows which chart has more time left.
enum RankMetric {
  /// Frames for each second. A higher value is better.
  fps('FPS', 1, '', higherIsBetter: true, relativeMargin: 0.01),

  /// The share of frames over the budget.
  overBudget('over budget', 1, '%', absoluteMargin: 1),

  /// The 90th percentile of the frame interval. Its margin is one display
  /// frame: a smaller difference is jitter and not a missed frame.
  frame('frame p90', 2, ' ms', displayFrameMargin: true),

  /// The sum of the 90th percentiles of the UI and raster times.
  work('UI + raster p90', 2, ' ms', relativeMargin: 0.1),

  /// The 90th percentile of the raster time.
  raster('raster p90', 2, ' ms'),

  /// The 90th percentile of the UI time.
  ui('UI p90', 2, ' ms');

  const RankMetric(
    this.label,
    this.decimals,
    this.unit, {
    this.higherIsBetter = false,
    this.relativeMargin,
    this.absoluteMargin,
    this.displayFrameMargin = false,
  });

  /// The name of the metric, in lower case except for an acronym.
  final String label;

  /// The decimals that the table shows.
  final int decimals;

  /// The unit after the value.
  final String unit;

  /// Whether a higher value is better.
  final bool higherIsBetter;

  /// The margin of a tie, as a share of the best value.
  final double? relativeMargin;

  /// The margin of a tie, in the unit of the metric.
  final double? absoluteMargin;

  /// Whether the margin of a tie is one frame of the display.
  final bool displayFrameMargin;

  /// Whether this metric decides the rank.
  bool get decides =>
      relativeMargin != null || absoluteMargin != null || displayFrameMargin;

  /// The value of this metric.
  double of(FrameMetrics metrics) => switch (this) {
    RankMetric.fps => metrics.fps,
    RankMetric.overBudget => metrics.overBudgetPercent,
    RankMetric.frame => metrics.intervalP90,
    RankMetric.work => metrics.uiP90 + metrics.rasterP90,
    RankMetric.raster => metrics.rasterP90,
    RankMetric.ui => metrics.uiP90,
  };

  /// The value as the table shows it, with its unit.
  String shown(FrameMetrics metrics) =>
      '${of(metrics).toStringAsFixed(decimals)}$unit';

  /// Negative when [a] shows a better value than [b], zero when the table shows
  /// no difference.
  int compare(FrameMetrics a, FrameMetrics b) {
    final x = double.parse(of(a).toStringAsFixed(decimals));
    final y = double.parse(of(b).toStringAsFixed(decimals));
    return higherIsBetter ? y.compareTo(x) : x.compareTo(y);
  }

  /// How many margins [metrics] is behind the [best] value of its setup, on a
  /// display of [refreshRate]. Steps from the best value keep the order of the
  /// rows transitive.
  int steps(FrameMetrics metrics, FrameMetrics best, double refreshRate) {
    final gap = higherIsBetter
        ? of(best) - of(metrics)
        : of(metrics) - of(best);
    final margin = displayFrameMargin
        ? 1000 / refreshRate
        : absoluteMargin ?? of(best) * (relativeMargin ?? 0);
    return margin > 0 ? (gap / margin).floor() : 0;
  }
}

/// The metrics that decide the rank, in their order.
final List<RankMetric> _deciding = [
  for (final metric in RankMetric.values)
    if (metric.decides) metric,
];

/// One saved result with its place among the results of its setup.
class RankedResult {
  /// Creates a row.
  const RankedResult({
    required this.result,
    required this.rank,
    required this.winner,
    required this.fpsShare,
    required this.slowerBy,
    required this.best,
    required this.steps,
  });

  /// The saved capture.
  final BenchmarkResult result;

  /// The place in its setup, from 1. A tie shares one place.
  final int rank;

  /// Whether this row leads a real comparison: at least two libraries of one
  /// setup, and at least one row with a worse rank.
  final bool winner;

  /// The FPS as a share of the best FPS of the setup, from 0 to 1.
  final double fpsShare;

  /// How many times the best FPS of the setup is higher, or null when this row
  /// is inside the FPS margin.
  final double? slowerBy;

  /// The metrics where this row has the best value of its setup. A metric where
  /// each row shows the same value has no best value.
  final Set<RankMetric> best;

  /// The margins behind the best value, for each metric that decides the rank.
  final List<int> steps;
}

/// Ranks [results] for each setup, because the results of different setups do
/// not compare. The rows come best first in each setup, and the setups keep the
/// order of their first result.
List<RankedResult> rankResults(List<BenchmarkResult> results) {
  final groups = <String, List<BenchmarkResult>>{};
  for (final result in results) {
    (groups[result.comparisonKey] ??= []).add(result);
  }
  return [for (final group in groups.values) ..._rankGroup(group)];
}

int _compareSteps(List<int> a, List<int> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return a[i].compareTo(b[i]);
  }
  return 0;
}

List<RankedResult> _rankGroup(List<BenchmarkResult> group) {
  final bestOf = <RankMetric, FrameMetrics>{
    for (final metric in RankMetric.values)
      metric:
          (group.map((r) => r.metrics).toList()..sort(metric.compare)).first,
  };
  List<int> stepsOf(BenchmarkResult r) => [
    for (final metric in _deciding)
      metric.steps(r.metrics, bestOf[metric]!, r.refreshRate),
  ];
  final steps = {for (final r in group) r: stepsOf(r)};
  // List.sort is not stable, so the index keeps the order of a tie.
  final index = {for (final (i, r) in group.indexed) r: i};
  final ordered = List<BenchmarkResult>.of(group)
    ..sort((a, b) {
      var order = _compareSteps(steps[a]!, steps[b]!);
      // Inside one rank, the rows still show the better values first.
      for (final metric in _deciding) {
        if (order != 0) break;
        order = metric.compare(a.metrics, b.metrics);
      }
      return order != 0 ? order : index[a]!.compareTo(index[b]!);
    });
  final lead =
      ordered.map((r) => r.library).toSet().length > 1 &&
      _compareSteps(steps[ordered.first]!, steps[ordered.last]!) != 0;
  final bestFps = RankMetric.fps.of(bestOf[RankMetric.fps]!);
  final rows = <RankedResult>[];
  var rank = 0;
  for (final (i, result) in ordered.indexed) {
    final metrics = result.metrics;
    final own = steps[result]!;
    if (i == 0 || _compareSteps(steps[ordered[i - 1]]!, own) != 0) {
      rank = i + 1;
    }
    rows.add(
      RankedResult(
        result: result,
        rank: rank,
        winner: lead && rank == 1,
        fpsShare: bestFps > 0 ? (metrics.fps / bestFps).clamp(0, 1) : 0,
        slowerBy: own.first > 0 && metrics.fps > 0
            ? bestFps / metrics.fps
            : null,
        best: {
          for (final metric in RankMetric.values)
            if (metric != RankMetric.work &&
                group.any(
                  (r) => metric.compare(r.metrics, bestOf[metric]!) != 0,
                ) &&
                metric.compare(metrics, bestOf[metric]!) == 0)
              metric,
        },
        steps: own,
      ),
    );
  }
  return rows;
}

/// One sentence about the result of [rows], or null when the rows do not
/// compare at least two libraries of one setup, or when several rows share the
/// lead.
String? winnerSummary(List<RankedResult> rows) {
  if (rows.map((r) => r.result.comparisonKey).toSet().length != 1) return null;
  if (rows.map((r) => r.result.library).toSet().length < 2) return null;
  final winners = rows.where((r) => r.winner).toList();
  if (winners.isEmpty) {
    return 'No clear winner: each difference is inside the margin of a tie.';
  }
  if (winners.length != 1) return null;
  final first = winners.single;
  final next = rows.firstWhere(
    (r) => r.result.library != first.result.library,
  );
  final a = first.result.metrics;
  final b = next.result.metrics;
  final name = first.result.library.label;
  final other = next.result.library.label;
  if (first.steps.first != next.steps.first) {
    final times = (b.fps > 0 ? a.fps / b.fps : 0).toStringAsFixed(1);
    return '$name wins: ${RankMetric.fps.shown(a)} FPS, '
        '$times× the FPS of $other.';
  }
  final at = [
    for (var i = 0; i < first.steps.length; i++)
      if (first.steps[i] != next.steps[i]) i,
  ];
  if (at.isEmpty) {
    return '$name wins: $other shares this rank.';
  }
  final decider = _deciding[at.first];
  return '$name wins: both reach about ${RankMetric.fps.shown(a)} FPS, and '
      '${decider.label} decides (${decider.shown(a)} against '
      '${decider.shown(b)}).';
}
