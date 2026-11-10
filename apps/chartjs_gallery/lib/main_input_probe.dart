// Original code, not ported from Chart.js: the input probe of Chart.js ADR 0112.
// The header text names the probe and the ADR, and has no URI.
// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:chartjs_gallery/demo/gallery_components.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

/// The point count of the chart: `--dart-define=POINTS=<n>`, 20000 by
/// default.
const int inputProbePoints = int.fromEnvironment(
  'POINTS',
  defaultValue: 20000,
);

/// The input probe of Chart.js ADR 0112 (section "Measurement").
///
/// It shows one `ChartView.raw` line chart of [inputProbePoints] points on a
/// linear x axis, with the plugin of chartjs-plugin-zoom
/// ([registerZoomComponents]): the wheel and the pinch zoom, and the pan in
/// the mode `'xy'`. The chart has `animation: false`, as the zoom cases of
/// the benchmark (`lib/bench/chart_bench.dart`): each update draws at once.
///
/// For each frame, it counts the `PointerMoveEvent`s of each pointer, the
/// `PointerScrollEvent`s, the `PointerPanZoomUpdateEvent`s, the chart
/// updates (`afterUpdate`) and the chart draws (`afterDraw`)
/// ([InputProbeRecorder]). Once per second with work, it shows a summary and
/// prints the line `PROBE {json}` ([inputProbeSummary]). It also appends the
/// line to `probe_lines.txt` in the temporary folder of the app
/// ([inputProbeLinesFile]): on an iPhone, `xcrun devicectl device copy from
/// --domain-type appDataContainer --source tmp/probe_lines.txt` reads it.
///
/// The axes keep their size while the chart zooms and pans
/// ([inputProbeConfig]): no bound ticks, a fixed y-axis width and no x-label
/// rotation. Without these options, the labels of the bounds change in each
/// step, the axis sizes change with them, and the plot area shakes.
///
/// Example: `flutter build apk --profile -t lib/main_input_probe.dart
/// --android-skip-build-dependency-validation`, then install and start the
/// APK, pinch or pan on the chart, and read the lines with
/// `adb logcat -s flutter:I`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InputProbeApp());
}

/// The counts of one frame.
///
/// A frame owns the input and the chart work between the end of the frame
/// before it and its own end (its post-frame callbacks): the input events
/// that come before its vsync, the throttled chart listeners and the
/// animator in its transient callbacks, and the chart updates of its
/// post-frame callbacks.
@immutable
final class InputProbeFrame {
  /// Creates the counts of one frame.
  const InputProbeFrame({
    required this.number,
    required this.movesByPointer,
    required this.scrolls,
    required this.panZooms,
    required this.updates,
    required this.draws,
  });

  /// `FrameData.frameNumber` of the engine, the number of `FrameTiming`;
  /// -1 when the engine gives none.
  final int number;

  /// The `PointerMoveEvent`s of each pointer that was down in the frame, by
  /// the Flutter pointer id: 0 for a pointer that was down and did not move.
  final Map<int, int> movesByPointer;

  /// The `PointerScrollEvent`s of the frame (the `wheel` of the host).
  final int scrolls;

  /// The `PointerPanZoomUpdateEvent`s of the frame (a trackpad; the host
  /// maps none of them, Chart.js ADR 0108 Open 5).
  final int panZooms;

  /// The chart updates of the frame (`afterUpdate`).
  final int updates;

  /// The chart draws of the frame (`afterDraw`).
  final int draws;

  /// The `PointerMoveEvent`s of all pointers.
  int get moves => movesByPointer.values.fold(0, (sum, n) => sum + n);

  /// Whether the frame had input, a pointer down or chart work. The other
  /// frames (a rebuild of the summary) do not count in the statistics.
  bool get active =>
      movesByPointer.isNotEmpty ||
      scrolls > 0 ||
      panZooms > 0 ||
      updates > 0 ||
      draws > 0;
}

/// The counter of the probe: a global pointer route of [GestureBinding], a
/// post-frame callback of each frame, the timings callback of
/// [SchedulerBinding] and the inline chart plugin [plugin].
final class InputProbeRecorder {
  final Set<int> _down = {};
  Set<int> _framePointers = {};
  final Map<int, int> _moves = {};
  int _scrolls = 0;
  int _panZooms = 0;
  int _updates = 0;
  int _draws = 0;
  bool _running = false;
  final List<InputProbeFrame> _frames = [];
  final List<FrameTiming> _timings = [];

  /// The inline plugin of the chart: it counts the updates and the draws.
  late final Map<String, Object?> plugin = <String, Object?>{
    'id': 'inputProbe',
    'afterUpdate': (Object? chart, Object? args, Object? options) {
      _updates++;
    },
    'afterDraw': (Object? chart, Object? args, Object? options) {
      _draws++;
    },
  };

  /// The frames since the last [take].
  List<InputProbeFrame> get frames => List.unmodifiable(_frames);

  /// Starts the counts.
  void start() {
    if (_running) return;
    _running = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _closeAfterNextFrame();
  }

  /// Stops the counts.
  void stop() {
    if (!_running) return;
    _running = false;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  /// The frames and the frame timings since the last call. It starts a new
  /// window.
  ({List<InputProbeFrame> frames, List<FrameTiming> timings}) take() {
    final window = (frames: [..._frames], timings: [..._timings]);
    _frames.clear();
    _timings.clear();
    return window;
  }

  void _onPointer(PointerEvent event) {
    switch (event) {
      case PointerDownEvent():
        _down.add(event.pointer);
        _framePointers.add(event.pointer);
      case PointerMoveEvent():
        _moves.update(event.pointer, (n) => n + 1, ifAbsent: () => 1);
        _framePointers.add(event.pointer);
      case PointerUpEvent() || PointerCancelEvent():
        _down.remove(event.pointer);
      case PointerScrollEvent():
        _scrolls++;
      case PointerPanZoomUpdateEvent():
        _panZooms++;
      default:
        break;
    }
  }

  void _onTimings(List<FrameTiming> timings) => _timings.addAll(timings);

  /// A post-frame callback adds no frame: each frame that runs closes its
  /// counts, and the callback registers again for the next frame.
  void _closeAfterNextFrame() => SchedulerBinding.instance.addPostFrameCallback(
    _closeFrame,
    debugLabel: 'InputProbeRecorder.frame',
  );

  void _closeFrame(Duration _) {
    if (!_running) return;
    _frames.add(
      InputProbeFrame(
        number:
            SchedulerBinding.instance.platformDispatcher.frameData.frameNumber,
        movesByPointer: {
          for (final pointer in _framePointers) pointer: _moves[pointer] ?? 0,
        },
        scrolls: _scrolls,
        panZooms: _panZooms,
        updates: _updates,
        draws: _draws,
      ),
    );
    _framePointers = {..._down};
    _moves.clear();
    _scrolls = 0;
    _panZooms = 0;
    _updates = 0;
    _draws = 0;
    _closeAfterNextFrame();
  }
}

/// The JSON of the line `PROBE` for the [frames] and the [timings] of one
/// window.
///
/// The keys: `frames` (all frames), `active` (the frames with input, a
/// pointer down or chart work, [InputProbeFrame.active]), `frameNumbers`
/// (the first and the last engine frame number), `pointers` (the most
/// pointers in one frame), and the statistics `{mean, max, hist}` of the
/// counts of the active frames: `movesPerPointer` (one value for each
/// pointer that was down in a frame), `moves`, `scrolls`, `panZooms`,
/// `updates` and `draws` (one value for each frame). `hist` has the counts
/// of the values 0, 1, 2 and 3 or more. `buildMs` and `rasterMs` are the
/// `{p50, p90}` of the [timings], or `null` without timings.
Map<String, Object?> inputProbeSummary(
  List<InputProbeFrame> frames,
  List<FrameTiming> timings,
) {
  final active = [
    for (final frame in frames)
      if (frame.active) frame,
  ];
  return {
    'frames': frames.length,
    'active': active.length,
    'frameNumbers': frames.isEmpty
        ? null
        : [frames.first.number, frames.last.number],
    'pointers': active.fold<int>(
      0,
      (most, frame) => math.max(most, frame.movesByPointer.length),
    ),
    'movesPerPointer': _stats([
      for (final frame in active) ...frame.movesByPointer.values,
    ]),
    'moves': _stats([for (final frame in active) frame.moves]),
    'scrolls': _stats([for (final frame in active) frame.scrolls]),
    'panZooms': _stats([for (final frame in active) frame.panZooms]),
    'updates': _stats([for (final frame in active) frame.updates]),
    'draws': _stats([for (final frame in active) frame.draws]),
    'buildMs': _percentiles([
      for (final timing in timings) timing.buildDuration,
    ]),
    'rasterMs': _percentiles([
      for (final timing in timings) timing.rasterDuration,
    ]),
  };
}

/// The text of the summary on the screen for the [summary] of
/// [inputProbeSummary].
String inputProbeText(Map<String, Object?> summary) {
  String stats(String key) {
    final value = summary[key]! as Map<String, Object?>;
    final hist = (value['hist']! as List<int>).join('/');
    return 'mean ${value['mean']}, max ${value['max']}, 0/1/2/3+ $hist';
  }

  String times(String key) {
    final value = summary[key] as Map<String, Object?>?;
    return value == null ? '-' : '${value['p50']} / ${value['p90']}';
  }

  final frames = '${summary['active']} of ${summary['frames']} frames';
  final pointers = '${summary['pointers']} pointers at most';
  final timings =
      'build ms p50 / p90: ${times('buildMs')}, raster: ${times('rasterMs')}';
  return [
    '$frames with work, $pointers',
    'moves per pointer: ${stats('movesPerPointer')}',
    'scrolls: ${stats('scrolls')}',
    'pan-zooms: ${stats('panZooms')}',
    'updates: ${stats('updates')}',
    'draws: ${stats('draws')}',
    timings,
  ].join('\n');
}

Map<String, Object?> _stats(List<int> counts) {
  var sum = 0;
  var max = 0;
  final hist = [0, 0, 0, 0];
  for (final count in counts) {
    sum += count;
    max = math.max(max, count);
    hist[math.min(count, 3)]++;
  }
  return {
    'mean': counts.isEmpty ? 0 : _round2(sum / counts.length),
    'max': max,
    'hist': hist,
  };
}

/// The nearest-rank p50 and p90 of [durations] in milliseconds, or `null`
/// for no durations.
Map<String, Object?>? _percentiles(List<Duration> durations) {
  if (durations.isEmpty) return null;
  final sorted = [for (final d in durations) d.inMicroseconds]..sort();
  double rank(double p) =>
      sorted[math.max(0, (p * sorted.length).ceil() - 1)] / 1000;
  return {'p50': _round2(rank(0.5)), 'p90': _round2(rank(0.9))};
}

double _round2(double value) => (value * 100).roundToDouble() / 100;

/// The data of the chart: [count] points with the x values 0 to
/// `count - 1`, sorted, as `parsing: false` needs.
List<Map<String, Object?>> inputProbeData(int count) => [
  for (var i = 0; i < count; i++)
    <String, Object?>{'x': i.toDouble(), 'y': 50 + 40 * math.sin(i / 400)},
];

/// The fixed width of the y axis in logical pixels: room for a label of
/// six characters, for example `45.25`, with the tick marks and the padding.
const double inputProbeYAxisWidth = 56;

/// The fixed layout padding at the right in logical pixels: room for half of
/// a label of eight characters, for example `19,999.5`.
const double inputProbeRightPadding = 24;

/// The file of the `PROBE` lines: `probe_lines.txt` in the temporary folder
/// of the app.
File get inputProbeLinesFile =>
    File('${Directory.systemTemp.path}/probe_lines.txt');

/// The config of the chart: a line chart of [points] points on linear
/// scales, with the zoom options and the inline [plugin].
Map<String, Object?> inputProbeConfig(
  int points,
  Map<String, Object?> plugin,
) => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Probe',
        'data': inputProbeData(points),
        'borderColor': const Color(0xFF36A2EB),
        'borderWidth': 1.0,
      },
    ],
  },
  'options': <String, Object?>{
    'animation': false,
    'maintainAspectRatio': false,
    'parsing': false,
    'layout': <String, Object?>{
      'padding': <String, Object?>{'right': inputProbeRightPadding},
    },
    // Stable axes for zoom and pan: only round tick values (no bounds),
    // no rotation of the x labels, and a fixed y-axis width. Then a step
    // changes no axis size, and the plot area stays in place.
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'type': 'linear',
        'ticks': <String, Object?>{
          'includeBounds': false,
          'maxRotation': 0,
          'minRotation': 0,
        },
        // The x axis asks for room at the sides for half of its first and
        // last label, from the positions of these ticks. A pan moves them,
        // so the room changes in each step. The fixed layout padding at the
        // right gives the last label its room.
        'afterFit': (Object? scale) {
          (scale! as Scale)
            ..paddingLeft = 0
            ..paddingRight = 0;
        },
      },
      'y': <String, Object?>{
        'type': 'linear',
        'ticks': <String, Object?>{'includeBounds': false},
        'afterFit': (Object? scale) {
          (scale! as Scale).width = inputProbeYAxisWidth;
        },
      },
    },
    'plugins': <String, Object?>{
      'zoom': <String, Object?>{
        'pan': <String, Object?>{'enabled': true, 'mode': 'xy'},
        'zoom': <String, Object?>{
          'wheel': <String, Object?>{'enabled': true},
          'pinch': <String, Object?>{'enabled': true},
          'mode': 'xy',
        },
      },
    },
  },
  'plugins': <Object?>[plugin],
};

/// The app of the probe.
class InputProbeApp extends StatelessWidget {
  /// Creates the app with a chart of [points] points.
  const InputProbeApp({super.key, this.points = inputProbePoints});

  /// The point count of the chart.
  final int points;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Input probe',
    debugShowCheckedModeBanner: false,
    home: InputProbePage(points: points),
  );
}

/// The page of the probe: the summary above the chart.
class InputProbePage extends StatefulWidget {
  /// Creates the page with a chart of [points] points.
  const InputProbePage({required this.points, super.key});

  /// The point count of the chart.
  final int points;

  @override
  State<InputProbePage> createState() => InputProbePageState();
}

/// The state of [InputProbePage].
class InputProbePageState extends State<InputProbePage> {
  /// The counter of the page.
  final InputProbeRecorder recorder = InputProbeRecorder();

  /// The chart, after its creation.
  Chart? chart;

  late final Map<String, Object?> _config = inputProbeConfig(
    widget.points,
    recorder.plugin,
  );
  final ValueNotifier<String> _summary = ValueNotifier(
    'Pinch, pan or scroll on the chart.',
  );
  final Stopwatch _clock = Stopwatch()..start();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    registerZoomComponents();
    recorder.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => report());
  }

  @override
  void dispose() {
    _timer?.cancel();
    recorder.stop();
    _summary.dispose();
    super.dispose();
  }

  /// Prints the line `PROBE {json}` of the frames since the last report and
  /// shows its summary, when a frame had work. The timer calls it once per
  /// second.
  void report() {
    final window = recorder.take();
    if (!window.frames.any((frame) => frame.active)) return;
    final summary = {
      't': _round2(_clock.elapsedMilliseconds / 1000),
      'points': widget.points,
      ...inputProbeSummary(window.frames, window.timings),
    };
    final line = 'PROBE ${jsonEncode(summary)}';
    debugPrint(line);
    // Only on a phone: a test on a desktop leaves no file.
    if (Platform.isIOS || Platform.isAndroid) {
      try {
        inputProbeLinesFile.writeAsStringSync(
          '$line\n',
          mode: FileMode.append,
        );
      } on FileSystemException {
        // The console line stays; a probe needs no file.
      }
    }
    _summary.value = inputProbeText(summary);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A fixed height: a new summary does not resize the chart.
          SizedBox(
            height: 132,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ValueListenableBuilder<String>(
                valueListenable: _summary,
                builder: (context, text, _) => Text(
                  text,
                  key: const ValueKey('probe.summary'),
                  maxLines: 7,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
              ),
            ),
          ),
          Expanded(
            child: ChartView.raw(
              key: const ValueKey('probe.host'),
              config: _config,
              onChartCreated: (chart) => this.chart = chart,
              semanticLabel: 'Input probe chart',
            ),
          ),
        ],
      ),
    ),
  );
}
