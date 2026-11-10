// Original code, not ported from Chart.js: the frameless benchmark entry.

import 'dart:async';
import 'dart:convert';
import 'dart:developer' show Timeline;

import 'package:chartjs_gallery/bench/chart_bench.dart';
import 'package:material_ui/material_ui.dart';

/// The cases of the benchmark entry: `--dart-define=CASES=a,c` gives a
/// comma list of selectors. A selector is a mode (`chart` or `axes`), a case
/// name (`b`, `time`, `bar`) or both (`chart.b`, `axes.time`, `chart.bar`).
/// Without the define, it runs all cases of [chartBenchCases]: the cases
/// `chart.a`, `chart.b` and `chart.c` of Chart.js ADR 0021 section 8, the
/// eight `axes` cases, and the twelve cases `chart.<type>` of Chart.js ADR
/// 0031 section 7 (`bar`, `bubble`, `doughnut`, `pie`, `polarArea` and
/// `radar`, each with `draw` and `update`). The selector `chart` selects 16
/// cases. `CASES=a,b,c` selects the cases of Chart.js ADR 0021 section 8.
/// The cases of the plugins of phase 8 follow, then the cases `motion.line`
/// and `motion.bar` of phase 9: `CASES=motion` selects the two cases of the
/// night series A-N3 (an update in the default mode with the default
/// animations). The cases of the mode `theme` of phase 9 come last:
/// `CASES=theme` selects the 11 cases of the night record B-R1,
/// `theme.switch` and `theme.anim` of the types `line`, `bar`, `scatter`,
/// `radar` and `doughnut`, and `theme.equal` of a line chart. `CASES=switch`
/// or `CASES=theme.switch` selects the 5 cases of one name. The explicit
/// cases of the resolver series of phase 10 (Chart.js ADR 0053,
/// `chartBenchExplicitCases`) run only when their full id is in the list:
/// `motion.line.delay`, `chart.c.indexable` and `chart.line.primitive`, for
/// example `CASES=chart,chart.c.indexable`. A mode, a name and a run
/// without the define never select them. The cases of the mode `zoom` come
/// after the mode `theme` (`chartBenchZoomCases`): `CASES=zoom` selects
/// its 16 cases at 1000 and 20000 points, the chart of the plugin of
/// chartjs-plugin-zoom with one input in each step. `zoom.base` and
/// `zoom.idle` (without and with the plugin, `draw` and `update`) and
/// `zoom.wheel` and `zoom.pan` have a linear and a time x axis; `zoom.drag`,
/// `zoom.pinch`, `zoom.api` and `zoom.apiPan` a linear one. A name selects
/// the cases of one input, for example `CASES=wheel,pan`. A selector that
/// selects no case throws an [ArgumentError] at the start.
final List<ChartBenchCase> benchCases = selectChartBenchCases(
  const String.fromEnvironment('CASES'),
);

/// The point counts N of each case: `--dart-define=N=1000,5000` gives a
/// comma list for all cases. Without the define, it is Dart `null`: each
/// case runs its own counts ([ChartBenchCase.counts]), or
/// [chartBenchDefaultCounts] (1000, 5000 and 20000). The radial types of
/// the cases `chart.<type>` have 100, 1000 and 5000.
final List<int>? benchCounts = _counts(const String.fromEnvironment('N'));

List<int>? _counts(String value) =>
    value.isEmpty ? null : parseChartBenchCounts(value);

/// The timing of each case: `--dart-define=BATCHES=<n>` timed batches of
/// `--dart-define=BATCH_MS=<ms>` each, after a warm-up of
/// `--dart-define=WARMUP_MS=<ms>`. The defaults are 15 batches of 200 ms
/// after 1000 ms.
const ChartBenchSettings benchSettings = ChartBenchSettings(
  batches: int.fromEnvironment('BATCHES', defaultValue: 15),
  batchMs: int.fromEnvironment('BATCH_MS', defaultValue: 200),
  warmupMs: int.fromEnvironment('WARMUP_MS', defaultValue: 1000),
);

/// The marks of the timed windows: with `--dart-define=PROFILE_MARKS=true`,
/// the app prints the line `BENCH_MARK {json}` right before and right after
/// the timed window of each case and N, the batches without the
/// construction, the preparation and the warm-up. The keys are `id` (the
/// mode and the name of the case), `n`, `scale` (the key `scale` of the
/// case, `null` for a case without it), `phase` (`start` or `end`) and `t`,
/// `Timeline.now` of `dart:developer` in microseconds: the clock of the CPU
/// samples and the timeline events of the VM service. A profile script cuts
/// the samples of one case with them. Without the define, the app prints no
/// mark.
const bool benchProfileMarks = bool.fromEnvironment('PROFILE_MARKS');

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
/// [benchCounts], or of the counts of the case (`lib/bench/chart_bench.dart`).
/// It prints one line `BENCH {json}` for each case and N, with the times of
/// `update`, `draw` and the end of the recording, and `BENCH done` at the
/// end. Each case also gives the times of the parts `elements`, `layout`,
/// `datasetsUpdate` and `datasetsDraw`. The cases of the mode `chart` give
/// the keys `type`, `sharing` and `scriptable`. The cases of the mode `axes`
/// give the tick count `ticks` and the `labelRotation` `rotation` of the x
/// axis. The cases of the mode `zoom` give the keys `id`, `scale`,
/// `zoomPlugin` and `rangeUpdates` (`--dart-define=ZOOM_RANGE_UPDATES=true`:
/// the input cases opt into the range updates of Chart.js ADR 0111), the
/// count of the timed steps `steps`, and `stepP50Ms`,
/// `stepP90Ms` and `stepMaxMs` of the single steps. With
/// `PROFILE_MARKS=true`, the lines `BENCH_MARK {json}` mark the timed window
/// of each case ([benchProfileMarks]). No frame drives the charts: the cases
/// hold the UI thread. Thus the status shows the case of the last frame.
///
/// Keep the app in front: on a phone, a background app gets slower cores.
/// Do not touch the screen during a run. On Android, the UI thread is also
/// the platform thread, and with the default timing a case holds it for
/// about 4 s. An input event that waits for more than 5 s gives an "App
/// not responding" dialog.
///
/// Example: `flutter build apk --profile -t lib/main_bench.dart
/// --dart-define=CASES=c --dart-define=N=5000`, then install the APK, start
/// it and read the lines with `adb logcat -d -s flutter:I`. A CPU profile of
/// the zoom cases: `--dart-define=CASES=zoom
/// --dart-define=PROFILE_MARKS=true`, then read the samples of the VM
/// service between the two marks of each case.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChartBenchApp());
}

/// The app of the benchmark entry.
class ChartBenchApp extends StatefulWidget {
  /// Creates the app. [cases], [counts], [settings] and [profileMarks]
  /// default to [benchCases], [benchCounts], [benchSettings] and
  /// [benchProfileMarks], the values of the defines. A test gives them.
  /// With no [counts] and no define `N`, each case runs its own counts.
  const ChartBenchApp({
    super.key,
    this.cases,
    this.counts,
    this.settings,
    this.profileMarks,
  });

  /// The cases, or Dart `null` for [benchCases].
  final List<ChartBenchCase>? cases;

  /// The point counts of all cases, or Dart `null` for [benchCounts].
  final List<int>? counts;

  /// The timing, or Dart `null` for [benchSettings].
  final ChartBenchSettings? settings;

  /// Whether the app prints the marks of the timed windows, or Dart `null`
  /// for [benchProfileMarks].
  final bool? profileMarks;

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
    final marks = widget.profileMarks ?? benchProfileMarks;
    final runs = [
      for (final benchCase in cases)
        for (final n in counts ?? benchCase.counts ?? chartBenchDefaultCounts)
          (benchCase, n),
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
      final line = runChartBenchCase(
        benchCase,
        n,
        settings,
        onWindow: marks ? (phase) => _printMark(benchCase, n, phase) : null,
      );
      debugPrint('BENCH ${jsonEncode(line)}');
    }
    debugPrint('BENCH done');
    if (mounted) {
      setState(() => _status = 'Done (${runs.length} of ${runs.length})');
    }
  }

  /// Prints the line `BENCH_MARK {json}` of the [phase] of the timed window
  /// of [benchCase] with [n] points ([benchProfileMarks]). It reads
  /// `Timeline.now` first, so the time is the time of the call.
  static void _printMark(ChartBenchCase benchCase, int n, String phase) {
    final t = Timeline.now;
    final mark = jsonEncode({
      'id': benchCase.id,
      'n': n,
      'scale': benchCase.keys['scale'],
      'phase': phase,
      't': t,
    });
    debugPrint('BENCH_MARK $mark');
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
