import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show FramePhase;

import 'package:chartjs_gallery/demo/stress_axes.dart';
import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

/// The scene of the profiling entry: `--dart-define=MODE=elements` selects
/// the [StressMode] of that name (`primitives`, `elements`, `bars`, `arcs`,
/// `chart`, `axes` or `plugins`). Without the define, the mode is
/// `primitives`. An unknown name throws an [ArgumentError] at the start.
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

/// The batches of the frame percentiles of each scenario:
/// `--dart-define=BATCHES=<n>`, 15 by default. See [stressBatchFigures].
const int stressBatches = int.fromEnvironment('BATCHES', defaultValue: 15);

/// The semantics of the profiling entry (the night series B-N1 of phase 9,
/// Chart.js ADR 0051 section 10): `--dart-define=SEMANTICS=1` turns the
/// semantics on before the app starts
/// (`SemanticsBinding.instance.ensureSemantics()`, [stressSemanticsHandle]),
/// and `--dart-define=SEMANTICS=0` does not. Without the define, it is Dart
/// `null`: the entry does not turn the semantics on, as before the define.
/// With the define, each `STRESS` line has the key `semantics`. See
/// [parseStressSemantics].
final bool? stressSemantics = parseStressSemantics(
  const String.fromEnvironment('SEMANTICS'),
);

/// The value of the define `SEMANTICS` [value]: see [stressSemantics]. An
/// empty string is a define that is not given. A value that is not 0 or 1
/// throws an [ArgumentError] at the start.
bool? parseStressSemantics(String value) =>
    value.isEmpty ? null : _flag('SEMANTICS', value);

/// The handle of the semantics of `SEMANTICS=1`. The entry keeps it for the
/// life of the process: the semantics stay on.
SemanticsHandle? stressSemanticsHandle;

/// Whether each scenario also prints its windows of 1 second:
/// `--dart-define=WINDOWS=1`. The default is 0. See [stressWindows].
final bool stressWindowsOn = _flag(
  'WINDOWS',
  const String.fromEnvironment(
    'WINDOWS',
    defaultValue: '0',
  ),
);

/// The widget that hosts the chart of the modes `chart`, `axes` and
/// `plugins`: `--dart-define=HOST=canvas` (the gallery `ChartCanvas`, the
/// default) or `--dart-define=HOST=view` (the public `ChartView`, Chart.js
/// ADR 0049). See [parseStressHost].
final StressHost stressHost = parseStressHost(
  const String.fromEnvironment('HOST'),
  stressMode,
);

/// The host of the define `HOST` [name] in the mode [mode]: see
/// [stressHost]. An empty string is a define that is not given. `HOST` in a
/// mode without a chart, or an unknown name, throws an [ArgumentError] at
/// the start.
StressHost parseStressHost(String name, StressMode mode) {
  if (name.isEmpty) return StressHost.canvas;
  if (!mode.runsChart) {
    throw ArgumentError.value(
      name,
      'HOST',
      'Not in MODE=chart, MODE=axes or MODE=plugins',
    );
  }
  return StressHost.values.byName(name);
}

/// One frame of `SchedulerBinding.addTimingsCallback`: the vsync start, and
/// the build and raster durations, in microseconds.
typedef StressFrame = ({int vsync, int build, int raster});

/// The batch percentiles of the frames of a timed window: `batches` (the
/// batches with frames), `frames` (the frames of the window), and the
/// medians of the batch p50 and p90 of the build and raster durations, in
/// ms.
typedef StressBatchFigures = ({
  int batches,
  int frames,
  double buildP50Ms,
  double buildP90Ms,
  double rasterP50Ms,
  double rasterP90Ms,
});

/// The batch percentiles of the [frames] with a vsync start from [start] to
/// [end] (microseconds): the window splits into [batches] batches of equal
/// time. The p50 (or p90) of a batch is the nearest-rank percentile of the
/// build (or raster) durations of its frames. A figure is the nearest-rank
/// median of the values of the batches with frames, as the batch figures
/// of the frameless benchmark. Dart `null` when the window has no frame.
StressBatchFigures? stressBatchFigures(
  List<StressFrame> frames, {
  required int start,
  required int end,
  required int batches,
}) {
  final span = math.max(1, end - start);
  final byBatch = [for (var b = 0; b < batches; b++) <StressFrame>[]];
  var count = 0;
  for (final frame in frames) {
    if (frame.vsync < start || frame.vsync > end) continue;
    final b = ((frame.vsync - start) * batches ~/ span).clamp(0, batches - 1);
    byBatch[b].add(frame);
    count++;
  }
  final full = [
    for (final batch in byBatch)
      if (batch.isNotEmpty) batch,
  ];
  if (full.isEmpty) return null;
  double rank(List<double> sorted, double p) =>
      sorted[((p * sorted.length).ceil() - 1).clamp(0, sorted.length - 1)];
  double median(double Function(List<StressFrame> batch) value) =>
      rank([for (final batch in full) value(batch)]..sort(), 0.5);
  double percentile(
    List<StressFrame> batch,
    int Function(StressFrame) of,
    double p,
  ) => rank([for (final frame in batch) of(frame) / 1000]..sort(), p);
  return (
    batches: full.length,
    frames: count,
    buildP50Ms: median((b) => percentile(b, (f) => f.build, 0.5)),
    buildP90Ms: median((b) => percentile(b, (f) => f.build, 0.9)),
    rasterP50Ms: median((b) => percentile(b, (f) => f.raster, 0.5)),
    rasterP90Ms: median((b) => percentile(b, (f) => f.raster, 0.9)),
  );
}

/// The length of a window of [stressWindows]: 1 second, in microseconds.
const int stressWindowMicros = 1000000;

/// One window of [stressWindows]: its number `window` (from 1), the count
/// of its `frames`, and the means of the build and raster durations of its
/// frames in ms (Dart `null` for a window with no frame).
typedef StressWindow = ({
  int window,
  int frames,
  double? buildMs,
  double? rasterMs,
});

/// The windows of 1 second of the [frames] of a scenario: window k (from
/// 1) has the frames with a vsync start from `start + (k - 1)` seconds to
/// `start + k` seconds, the end not included. [start] and [end] are
/// microseconds of the frame clock. Only the whole windows count: the last
/// window ends at [end] or before it. A frame before [start] or in no
/// whole window does not count. Each window counts, also with no frame or
/// with fewer than 30 frames.
List<StressWindow> stressWindows(
  List<StressFrame> frames, {
  required int start,
  required int end,
}) {
  final count = math.max(0, (end - start) ~/ stressWindowMicros);
  final counts = List<int>.filled(count, 0);
  final build = List<int>.filled(count, 0);
  final raster = List<int>.filled(count, 0);
  for (final frame in frames) {
    if (frame.vsync < start) continue;
    final k = (frame.vsync - start) ~/ stressWindowMicros;
    if (k >= count) continue;
    counts[k]++;
    build[k] += frame.build;
    raster[k] += frame.raster;
  }
  return [
    for (var k = 0; k < count; k++)
      (
        window: k + 1,
        frames: counts[k],
        buildMs: counts[k] == 0 ? null : build[k] / counts[k] / 1000,
        rasterMs: counts[k] == 0 ? null : raster[k] / counts[k] / 1000,
      ),
  ];
}

/// Whether the labels get a new angle in each frame:
/// `--dart-define=SPIN=true`.
const bool stressSpin = bool.fromEnvironment('SPIN');

/// Whether the modes `primitives` and `elements` draw their line of N
/// points: `--dart-define=LINE=1` (the default) or `--dart-define=LINE=0`.
/// The mode `chart` of `line` without `SHOWLINE=1` draws no line
/// (Chart.js ADR 0031, section 3). Thus `LINE=0` gives the `elements` scene
/// that compares with it (Chart.js ADR 0021, section 8, the acceptance).
final bool stressLine = _flag(
  'LINE',
  const String.fromEnvironment(
    'LINE',
    defaultValue: '1',
  ),
);

/// The call of each frame in the modes `chart`, `axes` and `plugins`
/// (Chart.js ADR 0021, section 8): `--dart-define=CALL=draw` (the default
/// of the modes chart and axes) gives case (a), `chart.draw()`.
/// `--dart-define=CALL=update` gives case (b), `chart.update('none')` after
/// new positions in the data objects. `--dart-define=CALL=animate` gives
/// the animation cost: a looping animation of the N points, which the
/// animator ticks in each frame. `--dart-define=CALL=frame` is the call of
/// the tooltip scenes `hover` and `fade` of the mode `plugins`. Without the
/// define, the call is the first call of the mode or of the scene
/// ([stressCallsOf]). See [parseStressCall].
final StressChartCall stressCall = parseStressCall(
  const String.fromEnvironment('CALL'),
  stressMode,
  stressPluginCase.scene,
);

/// The call of the define `CALL` [name] in the mode [mode] with the plugin
/// scene [scene]: see [stressCall]. An empty string is a define that is not
/// given. An unknown name, or a call that the mode or the scene does not
/// have ([stressCallsOf]), throws an [ArgumentError]: `animate` in the mode
/// `axes`, `frame` outside the mode `plugins`, or a call that is not a call
/// of the scene. The element modes accept `draw`, `update` and `animate`,
/// and do not use them.
StressChartCall parseStressCall(
  String name,
  StressMode mode, [
  StressPluginScene scene = StressPluginScene.legend,
]) {
  final calls = stressCallsOf(mode, scene);
  if (name.isEmpty) return calls.first;
  final call = StressChartCall.values.byName(name);
  if (!calls.contains(call)) {
    final names = [for (final c in calls) c.name];
    final list = names.length == 1
        ? names.single
        : '${names.sublist(0, names.length - 1).join(', ')} or ${names.last}';
    throw ArgumentError.value(
      name,
      'CALL',
      mode == StressMode.plugins
          ? 'Not $list (SCENE=${scene.name})'
          : 'Not $list (MODE=${mode.name})',
    );
  }
  return call;
}

/// The case of the mode `plugins` (performance.md section 6):
/// - `--dart-define=SCENE=<name>` selects the [StressPluginScene]:
///   `legend` (the default), `title`, `hover`, `still`, `fade`, `gaps`,
///   `stack` or `radar`. Each scene runs the chart of the benchmark case
///   [StressPluginScene.benchId].
/// - `--dart-define=LEGEND=0` gives the scene `legend` without the legend:
///   the base of the legend and the title. The default is 1.
/// - `--dart-define=TOOLTIP=0` gives the scenes `hover` and `still` without
///   the tooltip plugin: the base of the tooltip. The default is 1.
/// - `--dart-define=DATASETS=<3|10>` gives the datasets of the scenes
///   `hover`, `still` and `fade`. The default is 10.
///
/// See [parseStressPluginCase] for the errors.
final StressPluginCase stressPluginCase = parseStressPluginCase(
  scene: const String.fromEnvironment('SCENE'),
  legend: const String.fromEnvironment('LEGEND'),
  tooltip: const String.fromEnvironment('TOOLTIP'),
  datasets: const String.fromEnvironment('DATASETS'),
  mode: stressMode,
);

/// The plugin case of the defines [scene] (`SCENE`), [legend] (`LEGEND`),
/// [tooltip] (`TOOLTIP`) and [datasets] (`DATASETS`) in the mode [mode]: see
/// [stressPluginCase]. An empty string is a define that is not given. Each
/// of the four defines in another mode than `plugins`, an unknown scene,
/// `LEGEND` in another scene than `legend`, `TOOLTIP` in another scene than
/// `hover` and `still`, `DATASETS` in another scene than `hover`, `still`
/// and `fade`, a value of `LEGEND` or `TOOLTIP` that is not 0 or 1, or a
/// value of `DATASETS` that is not 3 or 10 throws an [ArgumentError] at the
/// start.
StressPluginCase parseStressPluginCase({
  required String scene,
  required String legend,
  required String tooltip,
  required String datasets,
  required StressMode mode,
}) {
  if (mode != StressMode.plugins) {
    for (final (name, value) in [
      ('SCENE', scene),
      ('LEGEND', legend),
      ('TOOLTIP', tooltip),
      ('DATASETS', datasets),
    ]) {
      if (value.isNotEmpty) {
        throw ArgumentError.value(value, name, 'Not in MODE=plugins');
      }
    }
    return const StressPluginCase(StressPluginScene.legend);
  }
  final pluginScene = scene.isEmpty
      ? StressPluginScene.legend
      : StressPluginScene.values.byName(scene);
  if (legend.isNotEmpty && pluginScene != StressPluginScene.legend) {
    throw ArgumentError.value(legend, 'LEGEND', 'Not in SCENE=legend');
  }
  if (tooltip.isNotEmpty &&
      pluginScene != StressPluginScene.hover &&
      pluginScene != StressPluginScene.still) {
    throw ArgumentError.value(
      tooltip,
      'TOOLTIP',
      'Not in SCENE=hover or SCENE=still',
    );
  }
  if (datasets.isNotEmpty && !pluginScene.tooltip) {
    throw ArgumentError.value(
      datasets,
      'DATASETS',
      'Not in SCENE=hover, SCENE=still or SCENE=fade',
    );
  }
  final count = datasets.isEmpty ? 10 : int.tryParse(datasets);
  if (count == null || !stressPluginDatasets.contains(count)) {
    throw ArgumentError.value(datasets, 'DATASETS', 'Not 3 or 10');
  }
  return StressPluginCase(
    pluginScene,
    legend: legend.isEmpty || _flag('LEGEND', legend),
    tooltip: tooltip.isEmpty || _flag('TOOLTIP', tooltip),
    datasets: count,
  );
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

/// The chart type of the mode `chart`: `--dart-define=TYPE=<name>` of
/// [StressChartType]. `SHARING` is an alias: without `TYPE`, `SHARING=0`
/// gives `scatter`, and `SHARING=1` or no `SHARING` gives `line`. With both
/// defines, `SHARING=1` needs `TYPE=line` and `SHARING=0` needs
/// `TYPE=scatter`. `TYPE` in another mode, an unknown name, or another pair
/// throws an [ArgumentError] at the start (Chart.js ADR 0031, section 5).
final StressChartType stressType = parseStressType(
  const String.fromEnvironment('TYPE'),
  const String.fromEnvironment('SHARING'),
  stressMode,
);

/// The chart type of the defines [type] (`TYPE`) and [sharing] (`SHARING`)
/// in the mode [mode]: see [stressType]. An empty string is a define that
/// is not given. `SHARING` in another mode than `chart` has no effect, as
/// before Chart.js ADR 0031.
StressChartType parseStressType(String type, String sharing, StressMode mode) {
  if (type.isNotEmpty && mode != StressMode.chart) {
    throw ArgumentError.value(type, 'TYPE', 'Not in MODE=chart');
  }
  final shared = sharing.isEmpty ? null : _flag('SHARING', sharing);
  if (type.isEmpty) {
    return shared == false ? StressChartType.scatter : StressChartType.line;
  }
  final chartType = StressChartType.values.byName(type);
  if (shared != null &&
      chartType != (shared ? StressChartType.line : StressChartType.scatter)) {
    throw ArgumentError.value(
      type,
      'TYPE',
      'Not ${shared ? 'line' : 'scatter'} (SHARING=$sharing)',
    );
  }
  return chartType;
}

/// Whether line and scatter show their line: `--dart-define=SHOWLINE=1`.
/// The default is 0. `SHOWLINE=1` with another type or in another mode
/// throws an [ArgumentError] at the start.
final bool stressShowLine = parseStressShowLine(
  const String.fromEnvironment('SHOWLINE', defaultValue: '0'),
  stressType,
  stressMode,
);

/// The value of the define `SHOWLINE` [value] for the chart type [type] in
/// the mode [mode]: see [stressShowLine].
bool parseStressShowLine(
  String value,
  StressChartType type,
  StressMode mode,
) {
  final showLine = _flag('SHOWLINE', value);
  if (showLine && (mode != StressMode.chart || !type.points)) {
    throw ArgumentError.value(
      value,
      'SHOWLINE',
      'Not MODE=chart with TYPE=line or TYPE=scatter',
    );
  }
  return showLine;
}

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
///   `packages/flutter_chartjs_port/doc/performance.md`.
/// - `bars`: 1000, 5000 and 20000 bars without labels.
/// - `arcs`: 100, 1000 and 5000 arcs without labels.
/// - `chart`: the counts of [type] (default [stressType]) without labels:
///   1000, 5000 and 20000 points, bars or bubbles, or 100, 1000 and 5000
///   arcs or radar points.
/// - `axes`: 1000, 5000 and 20000 chart points without labels.
/// - `plugins`: 100 and 1000 points in each dataset without labels, the
///   counts of the plugin cases of the benchmark.
List<(int, int)> stressDefaultScenarios(
  StressMode mode, [
  StressChartType? type,
]) => switch (mode) {
  StressMode.primitives || StressMode.elements => const [
    (1000, 0),
    (1000, 50),
    (5000, 50),
    (20000, 0),
    (1000, 200),
    (20000, 200),
  ],
  StressMode.chart => [for (final n in (type ?? stressType).counts) (n, 0)],
  StressMode.bars || StressMode.axes => const [
    (1000, 0),
    (5000, 0),
    (20000, 0),
  ],
  StressMode.arcs => const [(100, 0), (1000, 0), (5000, 0)],
  StressMode.plugins => [for (final n in mode.counts) (n, 0)],
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
/// (`CALL=animate`), the keys `call`, `type` and `scriptable` of the
/// defines, `showLine` (only when true), `sharing` (the
/// `enableOptionSharing` of the controller of dataset 0), and the means
/// `elementsMs`, `layoutMs`, `datasetsUpdateMs` and `datasetsDrawMs` of the
/// parts of `StressChartTiming` (`lib/demo/stress_timing.dart`).
/// In the mode `axes`, the line has the keys `call`, `scale`, `yScale` and
/// `autoSkip` of the defines, the tick count `ticks` (after the auto skip)
/// and the `labelRotation` `rotation` of the x axis at the end, and the
/// means of the four parts.
/// In the mode `plugins`, the line has the keys `animatorMs`, `call`,
/// `scene`, `benchCase` (the id of the benchmark case, for example
/// `tooltip.hover`), the keys of the benchmark case ([StressPluginCase.
/// benchKeys]: `datasets`, and `legend` and `title`, or `tooltip`), the
/// means of the four parts, and in the tooltip scenes `tooltipDrawMs`.
/// With `LINE=0`, it has the key `line` with the value false.
/// In the modes `chart`, `axes` and `plugins`, the line has the key `host`
/// of the define `HOST`.
/// Each line also has the batch percentiles of the frames
/// ([stressBatchFigures]): the timed window runs from the first published
/// figures after the first 30 frames to the last published figures of the
/// scenario, and it splits into `BATCHES` batches. The keys are `batches`
/// (the batches with frames), `batchFrames`, `buildP50Ms`, `buildP90Ms`,
/// `rasterP50Ms` and `rasterP90Ms`, Dart `null` for a window with no frame.
/// The engine of a profile or release build reports the frame timings in
/// groups (each second or each 100 frames). Thus a scenario of such a build
/// waits for the timings of its window, at most 3 seconds, before its line.
/// A debug build (also a widget test) prints the line at once.
/// With `SEMANTICS` (0 or 1), the line also has the key `semantics`, at its
/// end: whether the semantics are on at the end of the scenario
/// (`SemanticsBinding.semanticsEnabled`). It is true for `SEMANTICS=1`, and
/// for `SEMANTICS=0` when a screen reader of the platform turns them on.
/// With `WINDOWS=1`, the line also has the key `windows`, at its end: the
/// count of the whole windows of 1 second ([stressWindows]). Before the
/// line, the scenario then prints one line `STRESS_WINDOW {json}` for each
/// window, with the keys `mode`, `n`, `m`, `window` (the number of the
/// window, from 1), `frames`, `fps` (the frames of the window in 1 second),
/// `buildMs` and `rasterMs` (the means of the build and raster durations of
/// the frame timings of the window, in ms with 3 decimals, Dart `null` for
/// a window with no frame). Window 1 starts at the vsync of the first frame
/// timing of the scenario, and the last window ends at the vsync of its
/// last frame timing, or before it. The line waits for the timings of the
/// timed window of the batch percentiles, which ends less than 1 second
/// before the end of the scenario. Thus `SECONDS=17` gives 16 or 17
/// windows, and window 1 is the warm-up.
/// Fresh processes give the most stable figures: run one scenario at a time
/// with `--dart-define=MODE=<mode> --dart-define=SCENARIO=<N>x<M>`.
void main() {
  if (stressSemantics ?? false) {
    WidgetsFlutterBinding.ensureInitialized();
    stressSemanticsHandle = SemanticsBinding.instance.ensureSemantics();
  }
  runApp(const StressProfileApp());
}

/// The app of the profiling entry.
class StressProfileApp extends StatefulWidget {
  /// Creates the app. [mode], [scenarios], [scale], [yScale], [autoSkip],
  /// [type], [showLine], [call], [pluginCase] and [host] default to
  /// [stressMode], [stressScenarios], [stressScale], [stressYScale],
  /// [stressAutoSkip], [stressType], [stressShowLine], [stressCall],
  /// [stressPluginCase] and [stressHost], the values of the defines. A test
  /// gives them. [semantics] and [windows] default to [stressSemantics] and
  /// [stressWindowsOn].
  const StressProfileApp({
    super.key,
    this.mode,
    this.scenarios,
    this.scale,
    this.yScale,
    this.autoSkip,
    this.type,
    this.showLine,
    this.call,
    this.pluginCase,
    this.host,
    this.semantics,
    this.windows,
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

  /// The chart type of the mode `chart`, or Dart `null` for [stressType].
  final StressChartType? type;

  /// `showLine` of the mode `chart`, or Dart `null` for [stressShowLine].
  final bool? showLine;

  /// The call, or Dart `null` for [stressCall]. The mode takes the first of
  /// its calls for a call that it does not have ([stressCallOf]).
  final StressChartCall? call;

  /// The case of the mode `plugins`, or Dart `null` for
  /// [stressPluginCase].
  final StressPluginCase? pluginCase;

  /// The host of the chart, or Dart `null` for [stressHost].
  final StressHost? host;

  /// The value of the define `SEMANTICS`, or Dart `null` for
  /// [stressSemantics]. A value gives the `STRESS` lines the key
  /// `semantics`. Only `main` turns the semantics on.
  final bool? semantics;

  /// Whether each scenario prints its windows, or Dart `null` for
  /// [stressWindowsOn].
  final bool? windows;

  @override
  State<StressProfileApp> createState() => _StressProfileAppState();
}

class _StressProfileAppState extends State<StressProfileApp> {
  int _index = 0;
  final List<StressStats> _window = [];
  Timer? _timer;

  /// The frames of the timings callback since the last line.
  final List<StressFrame> _frames = [];

  /// Whether the engine reported any frame timing.
  bool _timed = false;

  /// The frame time stamps of the first published figures after the first
  /// 30 frames, and of the last published figures, of the scenario.
  int? _windowStart;
  int? _windowEnd;

  /// The line of the scenario whose timer fired, while it waits for the
  /// timings of its window.
  Map<String, Object?>? _pending;
  Timer? _pendingTimer;

  StressHost get _host => widget.host ?? stressHost;

  StressMode get _mode => widget.mode ?? stressMode;

  List<(int, int)> get _scenarios => widget.scenarios ?? stressScenarios;

  StressAxisType get _scale => widget.scale ?? stressScale;

  StressAxisType get _yScale => widget.yScale ?? stressYScale;

  bool get _autoSkip => widget.autoSkip ?? stressAutoSkip;

  StressChartType get _type => widget.type ?? stressType;

  bool get _showLine => widget.showLine ?? stressShowLine;

  StressPluginCase get _pluginCase => widget.pluginCase ?? stressPluginCase;

  StressChartCall get _call =>
      stressCallOf(_mode, widget.call ?? stressCall, _pluginCase.scene);

  bool? get _semantics => widget.semantics ?? stressSemantics;

  bool get _windows => widget.windows ?? stressWindowsOn;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _next();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pendingTimer?.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    _timed = true;
    for (final timing in timings) {
      _frames.add((
        vsync: timing.timestampInMicroseconds(FramePhase.vsyncStart),
        build: timing.buildDuration.inMicroseconds,
        raster: timing.rasterDuration.inMicroseconds,
      ));
    }
    final end = _windowEnd;
    if (_pending != null &&
        (end == null || _frames.any((frame) => frame.vsync >= end))) {
      _finish();
    }
  }

  /// Records the frame of the published [stats] of the scenario [index].
  void _onStats(int index, StressStats stats) {
    if (index != _index || _pending != null) return;
    _window.add(stats);
    if (stats.frames > 30) {
      final now = SchedulerBinding.instance.currentSystemFrameTimeStamp;
      _windowStart ??= now.inMicroseconds;
      _windowEnd = now.inMicroseconds;
    }
  }

  /// Prints the [_pending] line with the batch percentiles of its window,
  /// then starts the next scenario.
  void _finish() {
    final line = _pending!;
    _pending = null;
    _pendingTimer?.cancel();
    _pendingTimer = null;
    final start = _windowStart;
    final end = _windowEnd;
    final batches = start == null || end == null
        ? null
        : stressBatchFigures(
            _frames,
            start: start,
            end: end,
            batches: stressBatches,
          );
    String? ms(double? value) => value?.toStringAsFixed(2);
    line.addAll({
      'batches': batches?.batches,
      'batchFrames': batches?.frames ?? 0,
      'buildP50Ms': ms(batches?.buildP50Ms),
      'buildP90Ms': ms(batches?.buildP90Ms),
      'rasterP50Ms': ms(batches?.rasterP50Ms),
      'rasterP90Ms': ms(batches?.rasterP90Ms),
    });
    if (_semantics != null) {
      line['semantics'] = SemanticsBinding.instance.semanticsEnabled;
    }
    if (_windows) line['windows'] = _printWindows(line);
    debugPrint('STRESS ${jsonEncode(line)}');
    _window.clear();
    _frames.clear();
    _windowStart = null;
    _windowEnd = null;
    if (!mounted) return;
    if (_index + 1 < _scenarios.length) {
      setState(() => _index++);
      _next();
    } else {
      debugPrint('STRESS done');
    }
  }

  /// Prints one line `STRESS_WINDOW {json}` for each window of 1 second of
  /// the frame timings of the scenario of [line] ([stressWindows]), from its
  /// first frame timing to its last one. Gives the count of the windows.
  ///
  /// The windows read only the vsync starts of the timings: no time of
  /// another clock.
  int _printWindows(Map<String, Object?> line) {
    if (_frames.isEmpty) return 0;
    final windows = stressWindows(
      _frames,
      start: _frames.first.vsync,
      end: _frames.last.vsync,
    );
    String? ms(double? value) => value?.toStringAsFixed(3);
    for (final window in windows) {
      final fps = window.frames * 1e6 / stressWindowMicros;
      final json = jsonEncode({
        'mode': line['mode'],
        'n': line['n'],
        'm': line['m'],
        'window': window.window,
        'frames': window.frames,
        'fps': fps.toStringAsFixed(2),
        'buildMs': ms(window.buildMs),
        'rasterMs': ms(window.rasterMs),
      });
      debugPrint('STRESS_WINDOW $json');
    }
    return windows.length;
  }

  void _next() {
    _timer = Timer(const Duration(seconds: stressSeconds), () {
      final (n, m) = _scenarios[_index];
      final stats = _window.where((s) => s.frames > 30).toList();
      final last = _window.isEmpty ? null : _window.last;
      final tooltip = _mode == StressMode.plugins && _pluginCase.scene.tooltip;
      String avg(double Function(StressStats) f) =>
          (stats.isEmpty
                  ? 0
                  : stats.map(f).reduce((a, b) => a + b) / stats.length)
              .toStringAsFixed(2);
      _pending = {
        'mode': _mode.name,
        'n': n,
        'm': m,
        'fps': avg((s) => s.fps),
        'drawMs': avg((s) => s.drawMs),
        'updateMs': avg((s) => s.updateMs),
        if (!stressLine) 'line': false,
        if (_mode == StressMode.chart) ...{
          'animatorMs': avg((s) => s.animatorMs),
          'call': _call.name,
          'type': _type.name,
          'sharing': last?.sharing ?? _type.sharing,
          'scriptable': stressScriptable,
          if (_showLine) 'showLine': true,
          'elementsMs': avg((s) => s.elementsMs),
          'layoutMs': avg((s) => s.layoutMs),
          'datasetsUpdateMs': avg((s) => s.datasetsUpdateMs),
          'datasetsDrawMs': avg((s) => s.datasetsDrawMs),
        },
        if (_mode == StressMode.axes) ...{
          'call': _call.name,
          'scale': _scale.name,
          'yScale': _yScale.name,
          'autoSkip': _autoSkip,
          'ticks': last?.ticks,
          'rotation': last?.rotation.toStringAsFixed(2),
          'elementsMs': avg((s) => s.elementsMs),
          'layoutMs': avg((s) => s.layoutMs),
          'datasetsUpdateMs': avg((s) => s.datasetsUpdateMs),
          'datasetsDrawMs': avg((s) => s.datasetsDrawMs),
        },
        if (_mode == StressMode.plugins) ...{
          'animatorMs': avg((s) => s.animatorMs),
          'call': _call.name,
          'scene': _pluginCase.scene.name,
          'benchCase': _pluginCase.scene.benchId,
          ..._pluginCase.benchKeys,
          'elementsMs': avg((s) => s.elementsMs),
          'layoutMs': avg((s) => s.layoutMs),
          'datasetsUpdateMs': avg((s) => s.datasetsUpdateMs),
          'datasetsDrawMs': avg((s) => s.datasetsDrawMs),
          if (tooltip) 'tooltipDrawMs': avg((s) => s.tooltipDrawMs),
        },
        if (_mode.runsChart) 'host': _host.name,
        'buildMs': avg((s) => s.buildMs),
        'buildMaxMs': last?.buildMaxMs.toStringAsFixed(2),
        'rasterMs': avg((s) => s.rasterMs),
        'rasterMaxMs': last?.rasterMaxMs.toStringAsFixed(2),
      };
      // A profile or release build reports the timings in groups: wait for
      // the group of the last frame of the window, at most 3 seconds. A
      // debug build reports each frame at once, and a run without timings
      // goes on.
      if (!_timed || kDebugMode) {
        _finish();
        return;
      }
      final end = _windowEnd;
      if (end == null || _frames.any((frame) => frame.vsync >= end)) {
        _finish();
        return;
      }
      _pendingTimer = Timer(const Duration(seconds: 3), () {
        if (_pending != null) _finish();
      });
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
          initialCall: _call,
          initialType: _type,
          initialShowLine: _showLine,
          initialScriptable: stressScriptable,
          initialScale: _scale,
          initialYScale: _yScale,
          initialAutoSkip: _autoSkip,
          initialPluginCase: _pluginCase,
          autoStart: true,
          host: _host,
          // The frame after the timer of a scenario runs the old StressDemo
          // once more, before the build that disposes it. Its last figures
          // belong to its own scenario: they must not reach the window of
          // the next one. N and M cannot tell two scenarios apart. The
          // figures after the timer do not reach the window either.
          onStats: (stats) => _onStats(index, stats),
          // Protocol B-N1: with the define SEMANTICS (0 or 1), only the chart
          // and the static text give semantics nodes.
          chartSemanticsOnly: _semantics != null,
        ),
      ),
    );
  }
}
