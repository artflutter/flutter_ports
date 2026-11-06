import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/benchmark/metrics.dart';
import 'package:chart_benchmark_lab/benchmark/ranking.dart';
import 'package:chart_benchmark_lab/ui/results_table.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

BenchmarkResult _result(
  ChartLibrary library,
  double fps, {
  double frame = 16,
  double ui = 1,
  double raster = 1,
  double over = 0,
  int count = 20000,
  double refreshRate = 60,
}) => BenchmarkResult(
  library: library,
  config: BenchmarkConfig(count: count),
  viewport: const Size(600, 400),
  dpr: 2,
  refreshRate: refreshRate,
  metrics: FrameMetrics(
    samples: 100,
    fps: fps,
    intervalP90: frame,
    uiP90: ui,
    rasterP90: raster,
    overBudgetPercent: over,
  ),
  durationSeconds: 10,
  createdAt: DateTime.utc(2026),
);

/// The four rows of a real capture, in the order that they were saved.
final List<BenchmarkResult> _capture = [
  _result(
    ChartLibrary.graphic,
    6.8,
    frame: 158,
    ui: 15.59,
    raster: 150.68,
    over: 100,
  ),
  _result(ChartLibrary.chartjs, 60, frame: 17.11, ui: 1.24, raster: 2.99),
  _result(
    ChartLibrary.flChart,
    7.2,
    frame: 150.01,
    ui: 14.54,
    raster: 143.19,
    over: 100,
  ),
  _result(
    ChartLibrary.syncfusion,
    21,
    frame: 53.44,
    ui: 15.04,
    raster: 53.47,
    over: 100,
  ),
];

void main() {
  test('the rows come best first, with one winner and the factor', () {
    final rows = rankResults(_capture);
    expect(rows.map((r) => r.result.library), [
      ChartLibrary.chartjs,
      ChartLibrary.syncfusion,
      ChartLibrary.flChart,
      ChartLibrary.graphic,
    ]);
    expect(rows.map((r) => r.rank), [1, 2, 3, 4]);
    expect(rows.map((r) => r.winner), [true, false, false, false]);
    expect(rows.first.slowerBy, isNull);
    expect(rows[1].slowerBy, closeTo(60 / 21, 1e-9));
    expect(rows.last.fpsShare, closeTo(6.8 / 60, 1e-9));
    expect(
      rows.first.best,
      containsAll(RankMetric.values.where((m) => m != RankMetric.work)),
    );
    expect(rows[1].best, isEmpty);
    expect(
      winnerSummary(rows),
      'Chart.js port wins: 60.0 FPS, 2.9× the FPS of Syncfusion.',
    );
  });

  test('a tie of FPS at the display rate goes to the next metric', () {
    final rows = rankResults([
      _result(ChartLibrary.flChart, 60, frame: 18, over: 4),
      _result(ChartLibrary.chartjs, 60, frame: 17, over: 1),
    ]);
    expect(rows.first.result.library, ChartLibrary.chartjs);
    expect(rows.first.winner, isTrue);
    expect(rows.first.slowerBy, isNull);
    expect(rows.last.slowerBy, isNull);
    expect(rows.first.best, isNot(contains(RankMetric.fps)));
    expect(rows.first.best, contains(RankMetric.overBudget));
    expect(
      winnerSummary(rows),
      'Chart.js port wins: both reach about 60.0 FPS, and over budget decides '
      '(1.0% against 4.0%).',
    );
  });

  test('noise in the frame interval is no win, and the work decides', () {
    // The figures of a real capture at the 60 Hz display rate.
    final rows = rankResults([
      _result(
        ChartLibrary.flChart,
        60.1,
        frame: 17.1,
        ui: 0.8,
        raster: 6.6,
        over: 0.3,
      ),
      _result(
        ChartLibrary.chartjs,
        60.1,
        frame: 17.2,
        ui: 1,
        raster: 1.4,
        over: 0.3,
      ),
    ]);
    expect(rows.first.result.library, ChartLibrary.chartjs);
    expect(rows.first.winner, isTrue);
    // A best value is still a fact of its column.
    expect(rows.last.best, contains(RankMetric.frame));
    expect(rows.first.best, contains(RankMetric.raster));
    expect(
      winnerSummary(rows),
      'Chart.js port wins: both reach about 60.1 FPS, and UI + raster p90 '
      'decides (2.40 ms against 7.40 ms).',
    );
  });

  test('jitter below one display frame does not outrank the work', () {
    // The figures of a real capture at 120 Hz.
    BenchmarkResult row(
      ChartLibrary library,
      double fps,
      double frame,
      double ui,
      double raster,
    ) => _result(
      library,
      fps,
      frame: frame,
      ui: ui,
      raster: raster,
      refreshRate: 120,
    );
    final rows = rankResults([
      row(ChartLibrary.graphic, 120, 8.72, 0.82, 5.61),
      row(ChartLibrary.flChart, 120, 8.62, 1.18, 5.53),
      row(ChartLibrary.chartjs, 120.1, 9.19, 0.79, 1.29),
      row(ChartLibrary.syncfusion, 120.1, 9.31, 3.47, 8.29),
    ]);
    expect(rows.map((r) => r.result.library), [
      ChartLibrary.chartjs,
      ChartLibrary.graphic,
      ChartLibrary.flChart,
      ChartLibrary.syncfusion,
    ]);
    expect(
      winnerSummary(rows),
      'Chart.js port wins: both reach about 120.1 FPS, and UI + raster p90 '
      'decides (2.08 ms against 6.43 ms).',
    );
  });

  test('one missed display frame in the frame interval decides', () {
    final rows = rankResults([
      _result(ChartLibrary.flChart, 60, frame: 34, raster: 0.5),
      _result(ChartLibrary.chartjs, 60, frame: 17, raster: 5),
    ]);
    expect(rows.first.result.library, ChartLibrary.chartjs);
    expect(
      winnerSummary(rows),
      'Chart.js port wins: both reach about 60.0 FPS, and frame p90 decides '
      '(17.00 ms against 34.00 ms).',
    );
  });

  test('a small FPS difference is a tie, not a slower row', () {
    final rows = rankResults([
      _result(ChartLibrary.flChart, 59.8, raster: 5),
      _result(ChartLibrary.chartjs, 60.1, raster: 1),
    ]);
    expect(rows.first.result.library, ChartLibrary.chartjs);
    expect(rows.last.slowerBy, isNull);
    expect(rows.first.best, contains(RankMetric.fps));
  });

  test('differences inside each margin give no winner', () {
    final rows = rankResults([
      _result(ChartLibrary.flChart, 60.04, frame: 16.5),
      _result(ChartLibrary.chartjs, 60.01, frame: 16.4),
    ]);
    expect(rows.map((r) => r.rank), [1, 1]);
    expect(rows.map((r) => r.winner), [false, false]);
    expect(
      winnerSummary(rows),
      'No clear winner: each difference is inside the margin of a tie.',
    );
  });

  test('the order stays transitive across a chain of small steps', () {
    final rows = rankResults([
      _result(ChartLibrary.flChart, 58.9),
      _result(ChartLibrary.graphic, 59.5),
      _result(ChartLibrary.chartjs, 60),
    ]);
    expect(rows.map((r) => r.result.metrics.fps), [60, 59.5, 58.9]);
    expect(rows.map((r) => r.rank), [1, 1, 3]);
  });

  test('one library has no winner', () {
    final rows = rankResults([
      _result(ChartLibrary.chartjs, 50),
      _result(ChartLibrary.chartjs, 60),
    ]);
    expect(rows.first.result.metrics.fps, 60);
    expect(rows.any((r) => r.winner), isFalse);
    expect(winnerSummary(rows), isNull);
  });

  test('setups rank apart, and only one setup has a summary', () {
    final rows = rankResults([
      _result(ChartLibrary.flChart, 10),
      _result(ChartLibrary.flChart, 90, count: 100),
      _result(ChartLibrary.chartjs, 60),
      _result(ChartLibrary.chartjs, 80, count: 100),
    ]);
    expect(rows.map((r) => r.result.metrics.fps), [60, 10, 90, 80]);
    expect(rows.map((r) => r.rank), [1, 2, 1, 2]);
    expect(rows.map((r) => r.winner), [true, false, true, false]);
    expect(winnerSummary(rows), isNull);
  });

  testWidgets('the table marks the winner, sorts and shows the best first', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ResultsTable(
              results: _capture,
              currentKey: _capture.first.comparisonKey,
            ),
          ),
        ),
      ),
    );
    double top(String label) => tester.getTopLeft(find.text(label)).dy;
    expect(find.byKey(const ValueKey('results.winner')), findsOneWidget);
    expect(find.byKey(const ValueKey('results.summary')), findsOneWidget);
    expect(find.text('2.9× slower'), findsOneWidget);
    expect(top('Chart.js port'), lessThan(top('Syncfusion')));
    expect(top('Syncfusion'), lessThan(top('Graphic')));

    // A first click on Library sorts by name.
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(top('Chart.js port'), lessThan(top('Graphic')));
    expect(top('Graphic'), lessThan(top('Syncfusion')));

    // A first click on Over budget puts the best value first, a second click
    // the worst.
    await tester.tap(find.text('Over budget'));
    await tester.pumpAndSettle();
    expect(top('Chart.js port'), lessThan(top('Graphic')));
    await tester.tap(find.text('Over budget'));
    await tester.pumpAndSettle();
    expect(top('Graphic'), lessThan(top('Chart.js port')));

    // A first click on FPS puts the highest value first.
    await tester.tap(find.text('FPS'));
    await tester.pumpAndSettle();
    expect(top('Chart.js port'), lessThan(top('Graphic')));
    expect(tester.takeException(), isNull);
  });
}
