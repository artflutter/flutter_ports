import 'dart:async';
import 'dart:convert';
import 'dart:math' show Random;
import 'dart:ui' show FramePhase, FrameTiming, Size;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/benchmark/metrics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show FlutterVersion;

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

/// Low-frequency UI readout; the chart has its own per-frame notifier.
class RunReadout {
  /// Current timings and session progress.
  const RunReadout(this.timings, this.seconds, this.steps);

  /// Recent timings, or the complete finished capture.
  final FrameMetrics timings;

  /// Time since starting, including warmup.
  final double seconds;

  /// Dataset update count.
  final int steps;
}

/// Completed, immutable benchmark evidence.
class BenchmarkResult {
  /// Settings and environment are frozen when the capture starts.
  const BenchmarkResult({
    required this.library,
    required this.config,
    required this.viewport,
    required this.dpr,
    required this.refreshRate,
    required this.metrics,
    required this.durationSeconds,
    required this.createdAt,
  });

  /// Engine tested.
  final ChartLibrary library;

  /// Effective feature settings.
  final BenchmarkConfig config;

  /// Shared widget viewport in logical pixels.
  final Size viewport;

  /// Pixel ratio during measurement.
  final double dpr;

  /// Display refresh rate, independent of the 60-FPS budget.
  final double refreshRate;

  /// Warmup-filtered engine metrics.
  final FrameMetrics metrics;

  /// Requested measured duration, excluding the two-second warmup.
  final int durationSeconds;

  /// Capture completion time for export.
  final DateTime createdAt;

  /// Comparison identity excludes the engine but includes effective workload.
  String get comparisonKey =>
      _comparisonKey(config, viewport, dpr, refreshRate, durationSeconds);

  /// Exportable evidence, including limitations of the measurement.
  Map<String, Object?> toJson() => {
    'library': library.name,
    'version': library.version,
    'sdk': benchmarkSdk,
    'engineOptions': {
      if (library == ChartLibrary.chartjs)
        'dataOnlyUpdates': chartJsDataOnlyUpdates,
      if (library == ChartLibrary.chartjs &&
          (config.type == ChartType.line || config.type == ChartType.scatter))
        'parsing': false,
      if (library == ChartLibrary.chartjs && config.type == ChartType.line)
        'partitionedBaselineFillEnabled': const bool.fromEnvironment(
          'CHARTJS_PARTITIONED_BASELINE_FILL',
          defaultValue: true,
        ),
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
    'sourceRevision': const String.fromEnvironment(
      'SOURCE_REVISION',
      defaultValue: 'worktree',
    ),
    'fpsSource':
        'Flutter FrameTiming vsync timestamps; not presentation feedback',
  };
}

/// Owns one active library and one isolated measurement session.
class BenchmarkController extends ChangeNotifier {
  /// Register the engine timing observer and a display-driven workload ticker.
  /// [random] orders each bulk capture pass; tests give it a fixed seed.
  BenchmarkController(TickerProvider vsync, {Random? random})
    : _random = random ?? Random() {
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
  final Random _random;
  List<ChartLibrary> _batchOrder = const [];
  int? _batchIndex;
  bool _disposed = false;

  /// Whether a sequential capture of all engines is in progress.
  bool get batchCapturing => _batchIndex != null;

  /// One-based progress within the active batch.
  int get batchPosition => (_batchIndex ?? 0) + 1;

  /// Number of engines in the active or the last batch.
  int get batchTotal => _batchOrder.length;

  /// Whether the selected library can draw the selected chart type.
  bool get canRun => library.supports(config.type);

  /// Settings stay fixed through warmup, capture and timing-batch draining.
  bool get controlsLocked => capturing || finishing || batchCapturing;

  /// Capture every library that has the selected chart type, using the current
  /// duration and unchanged settings.
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
    _batchOrder = ChartLibrary.values.where(_supportsType).toList()
      ..shuffle(_random);
    _batchIndex = 0;
    library = _batchOrder.first;
    _begin(capture: true);
  }

  bool _supportsType(ChartLibrary value) => value.supports(config.type);

  /// Current comparable workload identifier.
  String get comparisonKey =>
      _comparisonKey(config, viewport, dpr, refreshRate, captureSeconds);

  /// Preserve configuration while replacing the single active engine.
  void selectLibrary(ChartLibrary value) {
    if (controlsLocked || library == value) return;
    final resume = running;
    pause();
    library = value;
    _reset();
    if (resume) start();
    notifyListeners();
  }

  /// Editing a setting starts an entirely new data/timing session.
  void configure(BenchmarkConfig value) {
    if (controlsLocked) return;
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
    message = canRun
        ? 'Ready. Measurements exclude the first 2 seconds.'
        : library.unsupportedReason(config.type);
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
      message = library.unsupportedReason(config.type);
      notifyListeners();
      return;
    }
    _reset();
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
    if (running || finishing) {
      pause('Viewport changed. Run again to measure this size.');
    }
    viewport = size;
    dpr = pixelRatio;
    refreshRate = rate;
    _reset();
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
