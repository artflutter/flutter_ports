import 'dart:async';
import 'dart:convert';

import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:flutter/material.dart';

/// The scenarios of the profiling entry: `--dart-define=SCENARIO=5000x50`
/// gives N = 5000 points and M = 50 labels. A comma separates several
/// scenarios. Without the define, it runs the six scenarios of
/// `packages/flutter_chartjs/doc/performance.md`.
final List<(int, int)> stressScenarios = _parse(
  const String.fromEnvironment('SCENARIO'),
);

/// The seconds that each scenario runs.
const int stressSeconds = int.fromEnvironment('SECONDS', defaultValue: 7);

/// Whether the labels get a new angle in each frame:
/// `--dart-define=SPIN=true`.
const bool stressSpin = bool.fromEnvironment('SPIN');

List<(int, int)> _parse(String value) => value.isEmpty
    ? const [
        (1000, 0),
        (1000, 50),
        (5000, 50),
        (20000, 0),
        (1000, 200),
        (20000, 200),
      ]
    : [
        for (final part in value.split(','))
          (
            int.parse(part.split('x')[0].trim()),
            int.parse(part.split('x')[1].trim()),
          ),
      ];

/// The profiling entry of the stress tab.
///
/// `flutter run --profile -t lib/main_stress.dart` runs each scenario in a
/// fresh `StressDemo` for [stressSeconds] seconds. It prints one line
/// `STRESS {json}` for each scenario, with the means of the published
/// figures after the first 30 frames, and `STRESS done` at the end. Fresh
/// processes give the most stable figures: run one scenario at a time with
/// `--dart-define=SCENARIO=<N>x<M>`.
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
