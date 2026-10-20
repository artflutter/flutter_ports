// Original code, not ported from Chart.js: the frameless benchmark entry.

import 'dart:async';
import 'dart:convert';

import 'package:chartjs_gallery/bench/chart_bench.dart';
import 'package:flutter/material.dart';

/// The cases of the benchmark entry: `--dart-define=CASES=a,c` gives a
/// comma list of selectors. A selector is a mode (`chart` or `axes`), a case
/// name (`b`, `time`) or both (`chart.b`, `axes.time`). Without the define,
/// it runs all cases of [chartBenchCases]. A selector that selects no case
/// throws an [ArgumentError] at the start.
final List<ChartBenchCase> benchCases = selectChartBenchCases(
  const String.fromEnvironment('CASES'),
);

/// The point counts N of each case: `--dart-define=N=1000,5000` gives a
/// comma list. Without the define, the counts are 1000, 5000 and 20000.
final List<int> benchCounts = parseChartBenchCounts(
  const String.fromEnvironment('N', defaultValue: '1000,5000,20000'),
);

/// The timing of each case: `--dart-define=BATCHES=<n>` timed batches of
/// `--dart-define=BATCH_MS=<ms>` each, after a warm-up of
/// `--dart-define=WARMUP_MS=<ms>`. The defaults are 15 batches of 200 ms
/// after 1000 ms.
const ChartBenchSettings benchSettings = ChartBenchSettings(
  batches: int.fromEnvironment('BATCHES', defaultValue: 15),
  batchMs: int.fromEnvironment('BATCH_MS', defaultValue: 200),
  warmupMs: int.fromEnvironment('WARMUP_MS', defaultValue: 1000),
);

/// The point counts of [value], a comma list of integers above 0. Another
/// value throws a [FormatException] or an [ArgumentError] at the start.
List<int> parseChartBenchCounts(String value) => [
  for (final part in value.split(','))
    if (part.trim().isNotEmpty)
      switch (int.parse(part.trim())) {
        final n when n > 0 => n,
        final n => throw ArgumentError.value(n, 'N', 'Not above 0'),
      },
];

/// The frameless benchmark of the chart path.
///
/// `flutter run --profile -t lib/main_bench.dart` shows a status text. After
/// the first frame, it runs each case of [benchCases] for each N of
/// [benchCounts] (`lib/bench/chart_bench.dart`). It prints one line
/// `BENCH {json}` for each case and N, with the times of `update`, `draw`
/// and the end of the recording, and `BENCH done` at the end. The cases of
/// the mode `axes` also give the times of `layout`, `datasetsUpdate` and
/// `datasetsDraw`, and the tick count `ticks` and the `labelRotation`
/// `rotation` of the x axis. No frame drives the charts: the cases hold the
/// UI thread. Thus the status shows the case of the last frame.
///
/// Keep the app in front: on a phone, a background app gets slower cores.
/// Do not touch the screen during a run. On Android, the UI thread is also
/// the platform thread, and with the default timing a case holds it for
/// about 4 s. An input event that waits for more than 5 s gives an "App
/// not responding" dialog.
///
/// Example: `flutter build apk --profile -t lib/main_bench.dart
/// --dart-define=CASES=c --dart-define=N=5000`, then install the APK, start
/// it and read the lines with `adb logcat -d -s flutter:I`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChartBenchApp());
}

/// The app of the benchmark entry.
class ChartBenchApp extends StatefulWidget {
  /// Creates the app. [cases], [counts] and [settings] default to
  /// [benchCases], [benchCounts] and [benchSettings], the values of the
  /// defines. A test gives them.
  const ChartBenchApp({super.key, this.cases, this.counts, this.settings});

  /// The cases, or Dart `null` for [benchCases].
  final List<ChartBenchCase>? cases;

  /// The point counts, or Dart `null` for [benchCounts].
  final List<int>? counts;

  /// The timing, or Dart `null` for [benchSettings].
  final ChartBenchSettings? settings;

  @override
  State<ChartBenchApp> createState() => _ChartBenchAppState();
}

class _ChartBenchAppState extends State<ChartBenchApp> {
  String _status = 'Waiting for the first frame';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_run()),
      debugLabel: 'ChartBenchApp.run',
    );
  }

  Future<void> _run() async {
    final cases = widget.cases ?? benchCases;
    final counts = widget.counts ?? benchCounts;
    final settings = widget.settings ?? benchSettings;
    final runs = [
      for (final benchCase in cases)
        for (final n in counts) (benchCase, n),
    ];
    for (var i = 0; i < runs.length; i++) {
      final (benchCase, n) = runs[i];
      if (!mounted) return;
      setState(
        () => _status =
            'Case ${benchCase.id} ${benchCase.keys}, N $n '
            '(${i + 1} of ${runs.length})',
      );
      // The status shows before the case holds the UI thread.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final line = runChartBenchCase(benchCase, n, settings);
      debugPrint('BENCH ${jsonEncode(line)}');
    }
    debugPrint('BENCH done');
    if (mounted) {
      setState(() => _status = 'Done (${runs.length} of ${runs.length})');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            _status,
            key: const ValueKey('bench.status'),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
