import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;
import 'dart:ui' show FramePhase, FrameTiming, Size;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/benchmark/metrics.dart';
import 'package:chart_benchmark_lab/benchmark/web_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show FlutterVersion;
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show chartjsChartSankeyVersion;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show chartjsPluginZoomVersion;

/// SDK identity injected by the Flutter build tool; never inferred from a pin.
const benchmarkSdk = <String, String?>{
  'flutterVersion': FlutterVersion.version,
  'channel': FlutterVersion.channel,
  'frameworkRevision': FlutterVersion.frameworkRevision,
  'engineRevision': FlutterVersion.engineRevision,
  'dartVersion': FlutterVersion.dartVersion,
};

/// Whether the Chart.js adapter gives each tick of new data to the data-only
/// path of its `ChartView` (Chart.js ADR 0098). The one switch of this choice:
/// `--dart-define=CHARTJS_DATA_ONLY_UPDATES=false` runs a full update per tick.
const chartJsDataOnlyUpdates = bool.fromEnvironment(
  'CHARTJS_DATA_ONLY_UPDATES',
  defaultValue: true,
);

/// One comparison identity for saved results and the current setup. It excludes
/// the engine but includes the effective workload.
String _comparisonKey(
  BenchmarkConfig config,
  Size viewport,
  double dpr,
  double refreshRate,
  int durationSeconds,
) => jsonEncode([
  config.toJson(),
  viewport.width,
  viewport.height,
  dpr,
  refreshRate,
  durationSeconds,
  benchmarkSdk,
]);

/// The workload of a result, without the size of the chart, its pixel ratio and
/// the display rate. Results of one workload stay in view after a resize. They
/// rank together only with one [_comparisonKey].
String _workloadKey(BenchmarkConfig config, int durationSeconds) =>
    jsonEncode([config.toJson(), durationSeconds, benchmarkSdk]);

/// Low-frequency UI readout; the chart has its own per-frame notifier.
class const RunReadout(
  /// Recent timings, or the complete finished capture.
  final FrameMetrics timings,

  /// Time since starting, including warmup.
  final double seconds,

  /// Dataset update count.
  final int steps,
) {
  /// Current timings and session progress.
  this;
}

/// Completed, immutable benchmark evidence.
class BenchmarkResult({
  /// Engine tested.
  required final ChartLibrary library,

  /// Effective feature settings.
  required final BenchmarkConfig config,

  /// Shared widget viewport in logical pixels.
  required final Size viewport,

  /// Pixel ratio during measurement.
  required final double dpr,

  /// Display refresh rate, independent of the 60-FPS budget.
  required final double refreshRate,

  /// Warmup-filtered engine metrics.
  required final FrameMetrics metrics,

  /// Requested measured duration, excluding the two-second warmup.
  required final int durationSeconds,

  /// Capture completion time for export.
  required final DateTime createdAt,
}) {
  /// Settings and environment are frozen when the capture starts.
  this;

  /// Comparison identity excludes the engine but includes effective workload.
  late final String comparisonKey = _comparisonKey(
    config,
    viewport,
    dpr,
    refreshRate,
    durationSeconds,
  );

  /// The identity of the workload, for the filter of the saved results.
  late final String workloadKey = _workloadKey(config, durationSeconds);

  /// Exportable evidence, including limitations of the measurement.
  Map<String, Object?> toJson() => {
    'library': library.name,
    'version': library.version,
    'sdk': benchmarkSdk,
    'engineOptions': {
      if (library == ChartLibrary.chartjs)
        'dataOnlyUpdates': chartJsDataOnlyUpdates,
      if (library == ChartLibrary.chartjs &&
          (config.type == ChartType.line ||
              config.type == ChartType.scatter ||
              config.type == ChartType.bubble))
        'parsing': false,
      if (library == ChartLibrary.chartjs && config.type == ChartType.line)
        'partitionedBaselineFillEnabled': const bool.fromEnvironment(
          'CHARTJS_PARTITIONED_BASELINE_FILL',
          defaultValue: true,
        ),
      // The pin of the port of chartjs-chart-sankey, which draws this chart
      // through the raw config of the Chart.js port.
      if (library == ChartLibrary.chartjs && config.type == ChartType.sankey)
        'sankeyChart': chartjsChartSankeyVersion,
      // The pin of the port of chartjs-plugin-zoom, which zooms this chart.
      if (library == ChartLibrary.chartjs && config.zooms)
        'zoomPlugin': chartjsPluginZoomVersion,
    },
    'settings': config.toJson(),
    'viewport': {'width': viewport.width, 'height': viewport.height},
    'dpr': dpr,
    'refreshHz': refreshRate,
    'warmupSeconds': 2,
    'measurementSeconds': durationSeconds,
    'metrics': metrics.toJson(),
    'completedAt': createdAt.toUtc().toIso8601String(),
    'buildMode': kDebugMode
        ? 'debug'
        : kProfileMode
        ? 'profile'
        : 'release',
    'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    'webMode': ?webMode(),
    'sourceRevision': const String.fromEnvironment(
      'SOURCE_REVISION',
      defaultValue: 'worktree',
    ),
    'fpsSource':
        'Flutter FrameTiming vsync timestamps; not presentation feedback',
  };
}

/// Loads the code of a chart library on demand. It gives `null` when the code
/// is ready, else a future that completes when the code is ready.
typedef LibraryLoader = Future<void>? Function(ChartLibrary library);

Future<void>? _codeReady(ChartLibrary library) => null;

/// Owns one active library and one isolated measurement session.
class BenchmarkController(
  TickerProvider vsync, {
  Random? random,
  LibraryLoader? loadCode,
}) extends ChangeNotifier {
  /// Register the engine timing observer and a display-driven workload ticker.
  /// [random] orders each bulk capture pass; tests give it a fixed seed.
  /// [loadCode] loads the code of a library before its chart shows or a run
  /// starts; without it, the code of each library is ready.
  this {
    _generator = DatasetGenerator(config.count, config.seed);
    frames = ValueNotifier(_generator.frame(0));
    _ticker = vsync.createTicker(_tick);
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _publisher = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _publish(),
    );
  }

  /// Current feature selection.
  BenchmarkConfig config = const BenchmarkConfig();

  /// The only mounted chart engine.
  ChartLibrary library = ChartLibrary.chartjs;

  /// The library whose code loads now, or `null`. The page shows a note in
  /// place of the chart until the code is ready, and a run waits for it.
  ChartLibrary? loadingLibrary;

  /// Changing data updates only the chart subtree.
  late final ValueNotifier<DatasetFrame> frames;

  /// Metrics update twice per second, not once per chart item/frame.
  final ValueNotifier<RunReadout> readout = ValueNotifier(
    const RunReadout(FrameMetrics(), 0, 0),
  );

  /// Completed runs remain available while switching engines.
  final List<BenchmarkResult> results = [];

  /// Reset identity for adapter disposal and initialization.
  int revision = 0;

  /// Whether the workload ticker is active.
  bool running = false;

  /// Latest platform visibility state; a hidden window cannot start a run.
  bool windowVisible = true;

  /// Whether a timed capture owns the controls.
  bool capturing = false;

  /// Drain delayed engine timing batches after stopping the workload.
  bool finishing = false;

  /// Message explaining a paused or cancelled run.
  String message = 'Configure a workload, then run or capture it.';

  /// Why a cause outside the controls stopped the last test, until the person
  /// closes the note or starts a new test.
  String? stopReason;

  /// Current chart viewport.
  Size viewport = Size.zero;

  /// Device pixel ratio.
  double dpr = 1;

  /// Reported display maximum/cadence, not an FPS guarantee.
  double refreshRate = 60;

  /// Recorded duration without warmup.
  int captureSeconds = 10;
  late final Ticker _ticker;
  late final Timer _publisher;
  Timer? _drainTimer;
  late DatasetGenerator _generator;
  TimingWindow _window = TimingWindow();
  double _seconds = 0;
  int _step = 0;
  int _session = 0;
  final Random _random = random ?? Random();
  final LibraryLoader _loadCode = loadCode ?? _codeReady;
  List<ChartLibrary> _batchOrder = const [];
  int? _batchIndex;
  bool _disposed = false;

  /// Whether a sequential capture of all engines is in progress.
  bool get batchCapturing => _batchIndex != null;

  /// One-based progress within the active batch.
  int get batchPosition => (_batchIndex ?? 0) + 1;

  /// Number of engines in the active or the last batch.
  int get batchTotal => _batchOrder.length;

  /// Whether the selected library can draw the selected chart type and
  /// features.
  bool get canRun => library.runs(config);

  /// Settings stay fixed through warmup, capture and timing-batch draining.
  bool get controlsLocked => capturing || finishing || batchCapturing;

  /// Capture every library that can draw the selected chart type and features,
  /// using the current duration and unchanged settings.
  /// Each pass takes a new random engine order, so no engine always runs first.
  /// Each engine gets its own reset, two-second warmup and timing window.
  void captureAll() {
    if (controlsLocked || viewport.isEmpty) return;
    pause();
    if (!windowVisible) {
      message = 'Make the chart window visible before running.';
      notifyListeners();
      return;
    }
    _batchOrder = ChartLibrary.values.where(_runsConfig).toList()
      ..shuffle(_random);
    _batchIndex = 0;
    library = _batchOrder.first;
    _begin(capture: true);
  }

  bool _runsConfig(ChartLibrary value) => value.runs(config);

  /// Current comparable workload identifier.
  String get comparisonKey =>
      _comparisonKey(config, viewport, dpr, refreshRate, captureSeconds);

  /// The identity of the current workload, for the filter of the saved results.
  String get workloadKey => _workloadKey(config, captureSeconds);

  /// Preserve configuration while replacing the single active engine.
  void selectLibrary(ChartLibrary value) {
    if (controlsLocked || library == value) return;
    final resume = running;
    pause();
    library = value;
    _reset();
    if (!_awaitCode(resume ? start : null) && resume) start();
    notifyListeners();
  }

  /// Starts to load the code of [library] when it is not ready, and gives
  /// whether the load goes on. After the load, [then] runs if the session did
  /// not change in the meantime. A load starts only between runs, so that no
  /// download or compile falls in a timed window.
  bool _awaitCode([VoidCallback? then]) {
    final pending = _loadCode(library);
    if (pending == null) {
      loadingLibrary = null;
      return false;
    }
    final target = library;
    final session = _session;
    loadingLibrary = target;
    message = _readyMessage;
    unawaited(
      pending.then(
        (_) {
          if (_disposed || library != target) return;
          loadingLibrary = null;
          final waiting = message == _loadingMessage(target);
          if (session == _session && then != null) {
            then();
          } else if (waiting) {
            message = _readyMessage;
          }
          notifyListeners();
        },
        onError: (Object _) {
          if (_disposed || library != target) return;
          loadingLibrary = null;
          _batchIndex = null;
          message = 'Could not load ${target.label}. Reload the page.';
          notifyListeners();
        },
      ),
    );
    return true;
  }

  static String _loadingMessage(ChartLibrary library) =>
      'Loading ${library.label}…';

  /// Editing a setting starts an entirely new data/timing session.
  void configure(BenchmarkConfig value) {
    if (controlsLocked || value == config) return;
    final resume = running;
    pause();
    config = value;
    _reset();
    if (resume) start();
    notifyListeners();
  }

  void _reset() {
    _session++;
    revision++;
    _step = 0;
    _seconds = 0;
    _window = TimingWindow();
    _generator = DatasetGenerator(config.count, config.seed);
    frames.value = _generator.frame(0);
    readout.value = const RunReadout(FrameMetrics(), 0, 0);
    message = _readyMessage;
  }

  String get _readyMessage => loadingLibrary == library
      ? _loadingMessage(library)
      : canRun
      ? 'Ready. Measurements exclude the first 2 seconds.'
      : library.reasonFor(config);

  /// Changes the length of the next capture.
  void setCaptureSeconds(int seconds) {
    captureSeconds = seconds;
    notifyListeners();
  }

  /// Start a fresh live or timed measurement, always from the same seed/step.
  void start({bool capture = false}) {
    if (batchCapturing) return;
    _begin(capture: capture);
  }

  void _begin({required bool capture}) {
    if (running || finishing || viewport.isEmpty) return;
    if (!windowVisible) {
      message = 'Make the chart window visible before running.';
      notifyListeners();
      return;
    }
    if (!canRun) {
      message = library.reasonFor(config);
      notifyListeners();
      return;
    }
    if (_awaitCode(() => _begin(capture: capture))) {
      notifyListeners();
      return;
    }
    _reset();
    stopReason = null;
    capturing = capture;
    running = true;
    message = capture ? 'Warming up for capture…' : 'Running · 2-second warmup';
    _ticker.start();
    notifyListeners();
  }

  /// Pause, cancelling an incomplete capture rather than saving biased data.
  void pause([String? reason]) {
    _session++;
    _drainTimer?.cancel();
    _drainTimer = null;
    if (_ticker.isActive) _ticker.stop();
    if (reason != null && (running || finishing)) stopReason = reason;
    if (batchCapturing) {
      message = 'Batch cancelled. Completed captures are kept.';
    } else if (capturing || finishing) {
      message = 'Capture cancelled; no result saved.';
    } else if (running) {
      message = 'Paused';
    }
    running = false;
    capturing = false;
    finishing = false;
    _batchIndex = null;
    if (reason != null) message = reason;
    notifyListeners();
  }

  /// Removes the explanation of a stopped test.
  void clearStopReason() {
    stopReason = null;
    notifyListeners();
  }

  /// Visibility loss cancels captures, including pending timing delivery.
  void setWindowVisible({required bool visible}) {
    windowVisible = visible;
    if (!visible && (running || finishing)) {
      pause('Window hidden or covered. Capture discarded.');
    }
  }

  /// Resize, scale and display changes invalidate comparison measurements.
  void setViewport(Size size, double pixelRatio, double hz) {
    final rate = hz > 0 ? hz : 60.0;
    if (size == viewport && pixelRatio == dpr && rate == refreshRate) return;
    final active = running || finishing;
    if (active) pause('Viewport changed. Run again to measure this size.');
    viewport = size;
    dpr = pixelRatio;
    refreshRate = rate;
    // An idle chart follows its size and stays mounted, so that a resize and
    // the first layout mount no chart. Each test starts with a new chart in
    // `_begin`. Graphic reads the width of its bars only when it mounts.
    if (active ||
        (library == ChartLibrary.graphic && config.type == ChartType.bar)) {
      _reset();
    } else {
      readout.value = const RunReadout(FrameMetrics(), 0, 0);
      message = _readyMessage;
    }
    notifyListeners();
  }

  void _tick(Duration elapsed) {
    final now =
        SchedulerBinding.instance.currentSystemFrameTimeStamp.inMicroseconds;
    _window.startUs ??= now;
    _seconds = (now - _window.startUs!) / 1000000;
    if (capturing && _seconds >= captureSeconds + 2) {
      _finish();
      return;
    }
    _step++;
    frames.value = config.workload == Workload.live
        ? _generator.frame(_step)
        : DatasetFrame(frames.value.values, _step);
  }

  void _onTimings(List<FrameTiming> timings) {
    if (!running && !finishing) return;
    for (final t in timings) {
      _window.add(
        FrameSample(
          t.timestampInMicroseconds(FramePhase.vsyncStart),
          t.buildDuration.inMicroseconds / 1000,
          t.rasterDuration.inMicroseconds / 1000,
        ),
      );
    }
    if (!capturing && !finishing) _window.trimLive();
  }

  void _publish() {
    if (_disposed || (!running && !finishing)) return;
    readout.value = RunReadout(_window.recent, _seconds, _step);
  }

  void _finish() {
    final session = _session;
    _ticker.stop();
    running = false;
    finishing = true;
    _window.endUs = _window.startUs! + (captureSeconds + 2) * 1000000;
    message = 'Collecting final frame timings…';
    notifyListeners();
    // FrameTiming batches may arrive after the last workload frame.
    _drainTimer = Timer(const Duration(milliseconds: 1100), () {
      if (_disposed || session != _session) return;
      final metrics = _window.summary;
      if (metrics.samples >= 2) {
        results.insert(
          0,
          BenchmarkResult(
            library: library,
            config: config,
            viewport: viewport,
            dpr: dpr,
            refreshRate: refreshRate,
            metrics: metrics,
            durationSeconds: captureSeconds,
            createdAt: DateTime.now(),
          ),
        );
        if (results.length > 24) results.removeLast();
        message = 'Capture saved · ${metrics.samples} engine frames';
      } else {
        message =
            'No usable engine timings. '
            'Use native profile mode for measurements.';
      }
      capturing = false;
      finishing = false;
      readout.value = RunReadout(metrics, _seconds, _step);
      final batch = _batchIndex;
      if (batch != null) {
        if (metrics.samples < 2) {
          _batchIndex = null;
          message = 'Batch stopped. $message';
        } else if (batch + 1 < _batchOrder.length) {
          _batchIndex = batch + 1;
          library = _batchOrder[batch + 1];
          _begin(capture: true);
          return;
        } else {
          _batchIndex = null;
          message = 'Batch complete · ${_batchOrder.length} captures saved';
        }
      }
      notifyListeners();
    });
  }

  /// JSON export does not mix unlike workloads or silently average captures.
  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'app': 'chart_benchmark_lab',
    'results': results.map((r) => r.toJson()).toList(),
  });

  /// Clear saved evidence on explicit user request.
  void clearResults() {
    results.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _session++;
    _publisher.cancel();
    _drainTimer?.cancel();
    _ticker.dispose();
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    frames.dispose();
    readout.dispose();
    super.dispose();
  }
}
