import 'dart:async';
import 'dart:convert';

import 'package:chartjs_gallery/demo/stress_axes.dart';
import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:flutter/material.dart';

/// The scene of the profiling entry: `--dart-define=MODE=elements` selects
/// the [StressMode] of that name (`primitives`, `elements`, `bars`, `arcs`,
/// `chart` or `axes`). Without the define, the mode is `primitives`. An
/// unknown name throws an [ArgumentError] at the start.
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

/// Whether the modes `primitives` and `elements` draw their line of N
/// points: `--dart-define=LINE=1` (the default) or `--dart-define=LINE=0`.
/// The mode `chart` has no line. Thus `LINE=0` gives the `elements` scene
/// that compares with it (Chart.js ADR 0021, section 8, the acceptance).
final bool stressLine = _flag(
  'LINE',
  const String.fromEnvironment(
    'LINE',
    defaultValue: '1',
  ),
);

/// The call of each frame in the modes `chart` and `axes` (Chart.js ADR
/// 0021, section 8): `--dart-define=CALL=draw` (the default) gives case
/// (a), `chart.draw()`. `--dart-define=CALL=update` gives case (b),
/// `chart.update('none')` after new positions in the data objects.
/// `--dart-define=CALL=animate` gives the animation cost: a looping
/// animation of the N points, which the animator ticks in each frame. An
/// unknown name, or `animate` in the mode `axes`, throws an [ArgumentError]
/// at the start.
final StressChartCall stressCall = _call(
  const String.fromEnvironment('CALL', defaultValue: 'draw'),
);

StressChartCall _call(String name) {
  final call = StressChartCall.values.byName(name);
  if (stressMode == StressMode.axes && call == StressChartCall.animate) {
    throw ArgumentError.value(name, 'CALL', 'Not draw or update (MODE=axes)');
  }
  return call;
}

/// The scale type of the x axis in the mode `axes`:
/// `--dart-define=SCALE=linear` (the default), `logarithmic`, `category` or
/// `time`. An unknown name throws an [ArgumentError] at the start.
final StressAxisType stressScale = StressAxisType.values.byName(
  const String.fromEnvironment('SCALE', defaultValue: 'linear'),
);

/// The scale type of the y axis in the mode `axes`:
/// `--dart-define=YSCALE=linear` (the default) or `logarithmic`. Another
/// name throws an [ArgumentError] at the start.
final StressAxisType stressYScale = _valueScale(
  const String.fromEnvironment('YSCALE', defaultValue: 'linear'),
);

StressAxisType _valueScale(String name) {
  final type = StressAxisType.values.byName(name);
  if (!stressAxesValueTypes.contains(type)) {
    throw ArgumentError.value(name, 'YSCALE', 'Not linear or logarithmic');
  }
  return type;
}

/// The option `ticks.autoSkip` of the x axis in the mode `axes`:
/// `--dart-define=AUTOSKIP=1` (the default) or `--dart-define=AUTOSKIP=0`.
final bool stressAutoSkip = _flag(
  'AUTOSKIP',
  const String.fromEnvironment(
    'AUTOSKIP',
    defaultValue: '1',
  ),
);

/// `enableOptionSharing` of the chart points in the mode `chart`:
/// `--dart-define=SHARING=1` (the default) as in a line chart,
/// `--dart-define=SHARING=0` as in a scatter chart.
final bool stressSharing = _flag(
  'SHARING',
  const String.fromEnvironment(
    'SHARING',
    defaultValue: '1',
  ),
);

/// Whether the chart points have a scriptable `backgroundColor` in the mode
/// `chart`: `--dart-define=SCRIPTABLE=1`. With `CALL=update`, this is case
/// (c). The default is 0.
final bool stressScriptable = _flag(
  'SCRIPTABLE',
  const String.fromEnvironment(
    'SCRIPTABLE',
    defaultValue: '0',
  ),
);

/// The value of a define that is `0` or `1`. Another value throws an
/// [ArgumentError] at the start.
bool _flag(String name, String value) => switch (value) {
  '0' => false,
  '1' => true,
  _ => throw ArgumentError.value(value, name, 'Not 0 or 1'),
};

/// The default scenarios (N, M) of each mode:
/// - `primitives` and `elements`: the six scenarios of
///   `packages/flutter_chartjs/doc/performance.md`.
/// - `bars`: 1000, 5000 and 20000 bars without labels.
/// - `arcs`: 100, 1000 and 5000 arcs without labels.
/// - `chart` and `axes`: 1000, 5000 and 20000 chart points without labels.
List<(int, int)> stressDefaultScenarios(StressMode mode) => switch (mode) {
  StressMode.primitives || StressMode.elements => const [
    (1000, 0),
    (1000, 50),
    (5000, 50),
    (20000, 0),
    (1000, 200),
    (20000, 200),
  ],
  StressMode.bars || StressMode.chart || StressMode.axes => const [
    (1000, 0),
    (5000, 0),
    (20000, 0),
  ],
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
/// after the first 30 frames, and `STRESS done` at the end. `updateMs` is the
/// time of `chart.update()` without its draw. In the mode `chart`, the line
/// also has `animatorMs`, the time of the animator tick without its draw
/// (`CALL=animate`), and the keys `call`, `sharing` and `scriptable` of the
/// defines.
/// In the mode `axes`, the line has the keys `call`, `scale`, `yScale` and
/// `autoSkip` of the defines, the tick count `ticks` (after the auto skip)
/// and the `labelRotation` `rotation` of the x axis at the end, and the
/// means `layoutMs`, `datasetsUpdateMs` and `datasetsDrawMs` of the parts of
/// `StressAxesTiming` (`lib/demo/stress_axes.dart`).
/// With `LINE=0`, it has the key `line` with the value false.
/// Fresh processes give the most stable figures: run one scenario at a time
/// with `--dart-define=MODE=<mode> --dart-define=SCENARIO=<N>x<M>`.
void main() {
  runApp(const StressProfileApp());
}

/// The app of the profiling entry.
class StressProfileApp extends StatefulWidget {
  /// Creates the app. [mode], [scenarios], [scale], [yScale] and [autoSkip]
  /// default to [stressMode], [stressScenarios], [stressScale],
  /// [stressYScale] and [stressAutoSkip], the values of the defines. A test
  /// gives them.
  const StressProfileApp({
    super.key,
    this.mode,
    this.scenarios,
    this.scale,
    this.yScale,
    this.autoSkip,
  });

  /// The mode of the scenarios, or Dart `null` for [stressMode].
  final StressMode? mode;

  /// The scenarios (N, M), or Dart `null` for [stressScenarios].
  final List<(int, int)>? scenarios;

  /// The x scale type of the mode `axes`, or Dart `null` for [stressScale].
  final StressAxisType? scale;

  /// The y scale type of the mode `axes`, or Dart `null` for
  /// [stressYScale].
  final StressAxisType? yScale;

  /// `ticks.autoSkip` of the mode `axes`, or Dart `null` for
  /// [stressAutoSkip].
  final bool? autoSkip;

  @override
  State<StressProfileApp> createState() => _StressProfileAppState();
}

class _StressProfileAppState extends State<StressProfileApp> {
  int _index = 0;
  final List<StressStats> _window = [];
  Timer? _timer;

  StressMode get _mode => widget.mode ?? stressMode;

  List<(int, int)> get _scenarios => widget.scenarios ?? stressScenarios;

  StressAxisType get _scale => widget.scale ?? stressScale;

  StressAxisType get _yScale => widget.yScale ?? stressYScale;

  bool get _autoSkip => widget.autoSkip ?? stressAutoSkip;

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
      final (n, m) = _scenarios[_index];
      final stats = _window.where((s) => s.frames > 30).toList();
      final last = _window.isEmpty ? null : _window.last;
      String avg(double Function(StressStats) f) =>
          (stats.isEmpty
                  ? 0
                  : stats.map(f).reduce((a, b) => a + b) / stats.length)
              .toStringAsFixed(2);
      debugPrint(
        'STRESS ${jsonEncode({
          'mode': _mode.name,
          'n': n,
          'm': m,
          'fps': avg((s) => s.fps),
          'drawMs': avg((s) => s.drawMs),
          'updateMs': avg((s) => s.updateMs),
          if (!stressLine) 'line': false,
          if (_mode == StressMode.chart) ...{
            'animatorMs': avg((s) => s.animatorMs),
            'call': stressCall.name,
            'sharing': stressSharing,
            'scriptable': stressScriptable,
          },
          if (_mode == StressMode.axes) ...{
            'call': stressCall.name,
            'scale': _scale.name,
            'yScale': _yScale.name,
            'autoSkip': _autoSkip,
            'ticks': last?.ticks,
            'rotation': last?.rotation.toStringAsFixed(2),
            'layoutMs': avg((s) => s.layoutMs),
            'datasetsUpdateMs': avg((s) => s.datasetsUpdateMs),
            'datasetsDrawMs': avg((s) => s.datasetsDrawMs),
          },
          'buildMs': avg((s) => s.buildMs),
          'buildMaxMs': last?.buildMaxMs.toStringAsFixed(2),
          'rasterMs': avg((s) => s.rasterMs),
          'rasterMaxMs': last?.rasterMaxMs.toStringAsFixed(2),
        })}',
      );
      _window.clear();
      if (_index + 1 < _scenarios.length) {
        setState(() => _index++);
        _next();
      } else {
        debugPrint('STRESS done');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = _index;
    final (n, m) = _scenarios[index];
    return MaterialApp(
      home: Scaffold(
        body: StressDemo(
          key: ValueKey(index),
          initialMode: _mode,
          initialN: n,
          initialM: m,
          // The define can be true.
          // ignore: avoid_redundant_argument_values
          initialSpin: stressSpin,
          initialLine: stressLine,
          initialCall: stressCall,
          initialSharing: stressSharing,
          initialScriptable: stressScriptable,
          initialScale: _scale,
          initialYScale: _yScale,
          initialAutoSkip: _autoSkip,
          autoStart: true,
          // The frame after the timer of a scenario runs the old StressDemo
          // once more, before the build that disposes it. Its last figures
          // belong to its own scenario: they must not reach the window of
          // the next one. N and M cannot tell two scenarios apart.
          onStats: (stats) {
            if (index == _index) _window.add(stats);
          },
        ),
      ),
    );
  }
}
