// Native profile driver: capture every chart type through the real controller.
//
// Each cell prints one `MATRIX {json}` line with the frame timings of the
// capture and, for the Chart.js port, the chart work that FrameTiming does not
// show, because the chart updates in a post-frame callback.
//
// Environment:
// - MATRIX_ENGINES: library names, default chartjs.
// - MATRIX_TYPES: chart type names, default all.
// - MATRIX_COUNTS: item counts, default 1000,5000,20000.
// - MATRIX_PRESETS: plain, full, or both, default both.
// - MATRIX_SECONDS: the measured seconds of a cell, default 4.
// - MATRIX_HOLD: a cell that keeps running, for a CPU profile. It has the form
//   engine:type:count:preset:seconds.
// - MATRIX_IGNORE_COVER: 1 measures while a lock screen covers the window.
//   Start the app with `-NSAppSleepDisabled YES` too, or the system throttles
//   it.
// - MATRIX_COOL: 1 waits before a cell until the fixed CPU test of the UI
//   thread is within 10% of its best time, and measures again each cell whose
//   test was more than 15% above its best time after the capture: a phone that
//   heats. Do not set it on an iPhone: its test can stay slow on a slower core
//   for minutes, with no heat that the app can read.
//
// A browser takes the options from the page address, and a phone from
// `--dart-define`. Each row has the time of the CPU test before and after the
// capture (`calMs`, `calAfterMs`), the wait (`coolS`) and the wall clock
// (`at`).
import 'dart:async';
import 'dart:convert';

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as cj;

import 'perf_cpu.dart';
import 'perf_matrix_host.dart';

// The options of a build for a target with no process environment: a phone.
// A browser reads them from the page address, and a desktop from the
// environment.
const Map<String, String> _defines = {
  'MATRIX_ENGINES': String.fromEnvironment('MATRIX_ENGINES'),
  'MATRIX_TYPES': String.fromEnvironment('MATRIX_TYPES'),
  'MATRIX_COUNTS': String.fromEnvironment('MATRIX_COUNTS'),
  'MATRIX_PRESETS': String.fromEnvironment('MATRIX_PRESETS'),
  'MATRIX_SECONDS': String.fromEnvironment('MATRIX_SECONDS'),
  'MATRIX_IGNORE_COVER': String.fromEnvironment('MATRIX_IGNORE_COVER'),
  'MATRIX_COOL': String.fromEnvironment('MATRIX_COOL'),
};

String? _option(String name) {
  final hosted = hostEnv(name);
  if (hosted != null && hosted.isNotEmpty) return hosted;
  final defined = _defines[name];
  return defined == null || defined.isEmpty ? null : defined;
}

final _watch = Stopwatch()..start();

class _Phase {
  int totalUs = 0;
  int count = 0;
  int? _start;
  void begin() => _start = _watch.elapsedMicroseconds;
  void end() {
    final start = _start;
    if (start == null) return;
    totalUs += _watch.elapsedMicroseconds - start;
    count++;
    _start = null;
  }

  void reset() {
    totalUs = 0;
    count = 0;
    _start = null;
  }

  double get meanMs => count == 0 ? 0 : totalUs / count / 1000;
}

final _update = _Phase();
final _draw = _Phase();
final _busyMs = <double>[];
var _measuring = false;

Map<String, Object?> _timingPlugin() => <String, Object?>{
  'id': 'labMatrixTiming',
  'supportsDataUpdates': true,
  'beforeUpdate': (Object? c, Object? a, Object? o) => _update.begin(),
  'afterUpdate': (Object? c, Object? a, Object? o) => _update.end(),
  'beforeDraw': (Object? c, Object? a, Object? o) => _draw.begin(),
  'afterDraw': (Object? c, Object? a, Object? o) => _draw.end(),
};

void _measureFrames() {
  late void Function(Duration) onFrame;
  onFrame = (_) {
    final start = _watch.elapsedMicroseconds;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Timer.run(() {
        if (_measuring) {
          _busyMs.add((_watch.elapsedMicroseconds - start) / 1000);
        }
      });
      SchedulerBinding.instance.scheduleFrameCallback(onFrame);
    });
  };
  SchedulerBinding.instance.scheduleFrameCallback(onFrame);
}

BenchmarkConfig _config(ChartType type, int count, String preset) =>
    preset == 'full'
    ? BenchmarkConfig(
        type: type,
        count: count,
        markers: true,
        fill: true,
        curved: true,
        axes: true,
        grid: true,
        alternateColors: true,
      )
    : BenchmarkConfig(type: type, count: count);

Future<void> _delay(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

/// Waits while the window is covered. A covered window cancels a capture.
Future<void> _waitForVisibleWindow(BenchmarkController c) async {
  var waited = false;
  while (!c.windowVisible) {
    if (!waited) hostLine('MATRIX_WAIT window covered');
    waited = true;
    await _delay(500);
  }
}

/// Runs a capture again when a covered window cancelled it.
Future<Map<String, Object?>> _capture(
  BenchmarkController c,
  ChartLibrary engine,
  ChartType type,
  int count,
  String preset,
  int seconds,
) async {
  for (var attempt = 1; ; attempt++) {
    await _waitForVisibleWindow(c);
    final row = await _attempt(c, engine, type, count, preset, seconds);
    if (row['saved'] == true) return row..['attempts'] = attempt;
    hostLine('MATRIX_RETRY $attempt ${row['message']}');
    if (attempt >= 20) return row;
    await _delay(1000);
  }
}

Future<Map<String, Object?>> _attempt(
  BenchmarkController c,
  ChartLibrary engine,
  ChartType type,
  int count,
  String preset,
  int seconds,
) async {
  c
    ..selectLibrary(engine)
    ..configure(_config(type, count, preset))
    ..captureSeconds = seconds;
  await _delay(600);
  _showChart();
  await _delay(200);
  // The controller keeps 24 results. Each cell prints its own result.
  c
    ..clearResults()
    ..start(capture: true);
  // The first two seconds are the warmup of the controller.
  await _delay(2000);
  _update.reset();
  _draw.reset();
  _busyMs.clear();
  _measuring = true;
  final limit = Stopwatch()..start();
  while (c.capturing &&
      !c.finishing &&
      limit.elapsed.inSeconds < seconds + 30) {
    await _delay(50);
  }
  _measuring = false;
  while (c.controlsLocked && limit.elapsed.inSeconds < seconds + 40) {
    await _delay(50);
  }
  final saved = c.results.isNotEmpty;
  final m = saved ? c.results.first.metrics : null;
  final busy = [..._busyMs]..sort();
  double pct(double q) => busy.isEmpty
      ? 0
      : busy[(busy.length * q).floor().clamp(0, busy.length - 1)];
  double r(double v) => double.parse(v.toStringAsFixed(2));
  return {
    'engine': engine.name,
    'type': type.name,
    'count': count,
    'preset': preset,
    'saved': saved,
    'message': c.message,
    if (m != null) ...{
      'fps': r(m.fps),
      'intervalP90': r(m.intervalP90),
      'intervalMax': r(m.intervalMax),
      'uiP90': r(m.uiP90),
      'rasterP90': r(m.rasterP90),
      'rasterMean': r(m.rasterMean),
    },
    'updateMs': r(_update.meanMs),
    'drawMs': r(_draw.meanMs),
    'updates': _update.count,
    'draws': _draw.count,
    'busyP50': r(pct(.5)),
    'busyP90': r(pct(.9)),
    'refreshHz': c.refreshRate,
    'dpr': c.dpr,
    'viewport': '${c.viewport.width}x${c.viewport.height}',
  };
}

List<String> _list(String name, String fallback) => (_option(name) ?? fallback)
    .split(',')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

Future<void> _hold(BenchmarkController c, String spec) async {
  final parts = spec.split(':');
  final engine = ChartLibrary.values.byName(parts[0]);
  final type = ChartType.values.byName(parts[1]);
  c
    ..selectLibrary(engine)
    ..configure(_config(type, int.parse(parts[2]), parts[3]));
  await _delay(600);
  c.start();
  hostLine('MATRIX_HOLD_READY');
  await _delay(int.parse(parts[4]) * 1000);
  c.pause();
  await hostExit();
}

/// Scrolls the chart into view, as a person does on a narrow screen. A capture
/// stops when the plot is not in the viewport.
void _showChart() {
  void visit(Element element) {
    if (element.widget is cj.ChartView) {
      Scrollable.ensureVisible(element);
      return;
    }
    element.visitChildren(visit);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(visit);
}

/// One cell: the wait, the capture and the CPU test around it.
Future<Map<String, Object?>> _cell(
  BenchmarkController c,
  ChartLibrary engine,
  ChartType type,
  int count,
  String preset,
  int seconds,
  int pass,
) async {
  final (cal, coolS) = await coolDown(enabled: _option('MATRIX_COOL') == '1');
  final row = await _capture(c, engine, type, count, preset, seconds);
  await _delay(100);
  final after = cpuTest();
  return row
    ..['calMs'] = double.parse(cal.toStringAsFixed(2))
    ..['calAfterMs'] = double.parse(after.toStringAsFixed(2))
    ..['coolS'] = coolS
    ..['pass'] = pass
    ..['at'] = DateTime.now().millisecondsSinceEpoch;
}

/// Keeps frames on and the capture gate open while the window is covered.
void _ignoreCover(BenchmarkController c) {
  void open() {
    if (c.windowVisible && SchedulerBinding.instance.framesEnabled) {
      return;
    }
    WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    c.windowVisible = true;
  }

  open();
  Timer.periodic(const Duration(milliseconds: 200), (_) => open());
}

Future<void> _run(BenchmarkController c) async {
  await _delay(2500);
  hostStart();
  if (_option('MATRIX_IGNORE_COVER') == '1') _ignoreCover(c);
  _measureFrames();
  final hold = _option('MATRIX_HOLD');
  if (hold != null) return _hold(c, hold);
  final engines = _list('MATRIX_ENGINES', 'chartjs');
  final types = _list(
    'MATRIX_TYPES',
    ChartType.values.map((t) => t.name).join(','),
  );
  final counts = _list('MATRIX_COUNTS', '1000,5000,20000');
  final presets = _list('MATRIX_PRESETS', 'plain,full');
  final seconds = int.parse(_option('MATRIX_SECONDS') ?? '4');
  final hot = <(ChartLibrary, ChartType, int, String)>[];
  // One capture with no row: the first capture of a process warms the engine.
  await _attempt(c, ChartLibrary.chartjs, ChartType.line, 1000, 'plain', 2);
  for (final engineName in engines) {
    final engine = ChartLibrary.values.byName(engineName);
    for (final typeName in types) {
      final type = ChartType.values.byName(typeName);
      if (!engine.supports(type)) continue;
      for (final count in counts) {
        for (final preset in presets) {
          final row = await _cell(
            c,
            engine,
            type,
            int.parse(count),
            preset,
            seconds,
            1,
          );
          hostLine('MATRIX ${jsonEncode(row)}');
          if ((row['calAfterMs']! as double) > cpuTestBest * 1.15) {
            hot.add((engine, type, int.parse(count), preset));
          }
        }
      }
    }
  }
  if (_option('MATRIX_COOL') == '1') {
    for (final (engine, type, count, preset) in hot) {
      final row = await _cell(c, engine, type, count, preset, seconds, 2);
      hostLine('MATRIX ${jsonEncode(row)}');
    }
  }
  hostLine('MATRIX_DONE');
  await hostExit();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cj.Chart.register(cj.registerables);
  cj.Chart.register([_timingPlugin()]);
  FlutterError.onError = (d) =>
      hostLine('MATRIX_ERROR ${d.exceptionAsString()}');
  runApp(ChartBenchmarkApp(onControllerReady: (c) => unawaited(_run(c))));
}
