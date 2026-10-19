import 'dart:async';
import 'dart:convert';

import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:flutter/material.dart';

/// The scene of the profiling entry: `--dart-define=MODE=elements` selects
/// the [StressMode] of that name (`primitives`, `elements`, `bars` or
/// `arcs`). Without the define, the mode is `primitives`. An unknown name
/// throws an [ArgumentError] at the start.
final StressMode stressMode = StressMode.values.byName(
  const String.fromEnvironment('MODE', defaultValue: 'primitives'),
);

/// The scenarios of the profiling entry: `--dart-define=SCENARIO=5000x50`
/// gives N = 5000 items and M = 50 labels. A comma separates several
/// scenarios. Without the define, it runs the default scenarios of
/// [stressMode] ([stressDefaultScenarios]).
final List<(int, int)> stressScenarios = _parse(
  const String.fromEnvironment('SCENARIO'),
);

/// The seconds that each scenario runs.
const int stressSeconds = int.fromEnvironment('SECONDS', defaultValue: 7);

/// Whether the labels get a new angle in each frame:
/// `--dart-define=SPIN=true`.
const bool stressSpin = bool.fromEnvironment('SPIN');

/// The default scenarios (N, M) of each mode:
/// - `primitives` and `elements`: the six scenarios of
///   `packages/flutter_chartjs/doc/performance.md`.
/// - `bars`: 1000, 5000 and 20000 bars without labels.
/// - `arcs`: 100, 1000 and 5000 arcs without labels.
List<(int, int)> stressDefaultScenarios(StressMode mode) => switch (mode) {
  StressMode.primitives || StressMode.elements => const [
    (1000, 0),
    (1000, 50),
    (5000, 50),
    (20000, 0),
    (1000, 200),
    (20000, 200),
  ],
  StressMode.bars => const [(1000, 0), (5000, 0), (20000, 0)],
  StressMode.arcs => const [(100, 0), (1000, 0), (5000, 0)],
};

List<(int, int)> _parse(String value) => value.isEmpty
    ? stressDefaultScenarios(stressMode)
    : [
        for (final part in value.split(','))
          (
            int.parse(part.split('x')[0].trim()),
            int.parse(part.split('x')[1].trim()),
          ),
      ];

/// The profiling entry of the stress tab.
///
/// `flutter run --profile -t lib/main_stress.dart` runs each scenario of
/// [stressScenarios] in a fresh `StressDemo` in the mode [stressMode], for
/// [stressSeconds] seconds. It prints one line `STRESS {json}` for each
/// scenario, with the mode, N, M and the means of the published figures
/// after the first 30 frames, and `STRESS done` at the end. Fresh processes
/// give the most stable figures: run one scenario at a time with
/// `--dart-define=MODE=<mode> --dart-define=SCENARIO=<N>x<M>`.
void main() {
  runApp(const StressProfileApp());
}

/// The app of the profiling entry.
class StressProfileApp extends StatefulWidget {
  /// Creates the app.
  const StressProfileApp({super.key});

  @override
  State<StressProfileApp> createState() => _StressProfileAppState();
}

class _StressProfileAppState extends State<StressProfileApp> {
  int _index = 0;
  final List<StressStats> _window = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _next() {
    _timer = Timer(const Duration(seconds: stressSeconds), () {
      final (n, m) = stressScenarios[_index];
      final stats = _window.where((s) => s.frames > 30).toList();
      final last = _window.isEmpty ? null : _window.last;
      String avg(double Function(StressStats) f) =>
          (stats.isEmpty
                  ? 0
                  : stats.map(f).reduce((a, b) => a + b) / stats.length)
              .toStringAsFixed(2);
      debugPrint(
        'STRESS ${jsonEncode({
          'mode': stressMode.name,
          'n': n,
          'm': m,
          'fps': avg((s) => s.fps),
          'drawMs': avg((s) => s.drawMs),
          'buildMs': avg((s) => s.buildMs),
          'buildMaxMs': last?.buildMaxMs.toStringAsFixed(2),
          'rasterMs': avg((s) => s.rasterMs),
          'rasterMaxMs': last?.rasterMaxMs.toStringAsFixed(2),
        })}',
      );
      _window.clear();
      if (_index + 1 < stressScenarios.length) {
        setState(() => _index++);
        _next();
      } else {
        debugPrint('STRESS done');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final (n, m) = stressScenarios[_index];
    return MaterialApp(
      home: Scaffold(
        body: StressDemo(
          key: ValueKey(_index),
          initialMode: stressMode,
          initialN: n,
          initialM: m,
          // The define can be true.
          // ignore: avoid_redundant_argument_values
          initialSpin: stressSpin,
          autoStart: true,
          onStats: _window.add,
        ),
      ),
    );
  }
}
