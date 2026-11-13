// Native and browser driver: everyday use of a chart at realistic sizes.
//
// The lab matrix measures a data update on each frame. This driver measures
// what a person sees in an app: first paint, animated updates, hover with a
// tooltip, a resize, and charts with several datasets, stacked bars or a time
// axis. Each chart has its default animations, legend, axes and tooltip. Each
// cell prints one `EVERYDAY {json}` line.
//
// Options, as in perf_matrix.dart: EVERYDAY_SCENARIOS, EVERYDAY_TYPES,
// MATRIX_SECONDS, MATRIX_COOL.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/data.dart';
import 'package:chart_benchmark_lab/benchmark/metrics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as cj;
import 'package:material_ui/material_ui.dart';

import 'perf_cpu.dart';
import 'perf_matrix_host.dart';

const Map<String, String> _defines = {
  'EVERYDAY_SCENARIOS': String.fromEnvironment('EVERYDAY_SCENARIOS'),
  'EVERYDAY_TYPES': String.fromEnvironment('EVERYDAY_TYPES'),
  'MATRIX_SECONDS': String.fromEnvironment('MATRIX_SECONDS'),
  'MATRIX_COOL': String.fromEnvironment('MATRIX_COOL'),
};

String? _option(String name) {
  final hosted = hostEnv(name);
  if (hosted != null && hosted.isNotEmpty) return hosted;
  final defined = _defines[name];
  return defined == null || defined.isEmpty ? null : defined;
}

const _colors = [
  Color(0xff4f6bed),
  Color(0xff119988),
  Color(0xffdd6b20),
  Color(0xffb83280),
  Color(0xff718096),
];

const _sizes = <ChartType, List<int>>{
  ChartType.line: [100, 1000, 5000],
  ChartType.bar: [24, 200, 1000],
  ChartType.scatter: [100, 1000, 5000],
  ChartType.bubble: [50, 500, 2000],
  ChartType.pie: [6, 24, 100],
  ChartType.doughnut: [6, 24, 100],
  ChartType.polarArea: [6, 24, 100],
  ChartType.radar: [6, 24, 100],
};

List<Color> _palette(int count) => [
  for (var i = 0; i < count; i++) _colors[i % _colors.length],
];

cj.Dataset _dataset(
  ChartType type,
  List<Sample> values, {
  int series = 0,
  String? stack,
}) {
  final color = _colors[series % _colors.length];
  final fill = cj.ChartValue<ChartPaint>.constant(.solid(color));
  final key = ValueKey('series$series');
  final label = 'Series $series';
  return switch (type) {
    ChartType.line => cj.LineDataset(
      key: key,
      label: label,
      points: [for (final p in values) cj.DataPoint(p.x, p.y)],
      borderColor: fill,
      backgroundColor: fill,
      tension: .35,
    ),
    ChartType.bar => cj.BarDataset(
      key: key,
      label: label,
      data: [for (final p in values) p.y],
      backgroundColor: fill,
      stack: stack,
    ),
    ChartType.scatter => cj.ScatterDataset(
      key: key,
      label: label,
      points: [for (final p in values) cj.DataPoint(p.x, p.y)],
      backgroundColor: fill,
    ),
    ChartType.bubble => cj.BubbleDataset(
      key: key,
      label: label,
      points: [for (final p in values) cj.DataPoint.bubble(p.x, p.y, p.r)],
      backgroundColor: fill,
    ),
    ChartType.pie => cj.PieDataset(
      key: key,
      label: label,
      data: [for (final p in values) p.y],
      backgroundColor: cj.ChartValue<ChartPaint>.indexed(
        _palette(values.length).map(ChartPaint.solid).toList(),
      ),
    ),
    ChartType.doughnut => cj.DoughnutDataset(
      key: key,
      label: label,
      data: [for (final p in values) p.y],
      backgroundColor: cj.ChartValue<ChartPaint>.indexed(
        _palette(values.length).map(ChartPaint.solid).toList(),
      ),
    ),
    ChartType.polarArea => cj.PolarAreaDataset(
      key: key,
      label: label,
      data: [for (final p in values) p.y],
      backgroundColor: cj.ChartValue<ChartPaint>.indexed(
        _palette(values.length).map(ChartPaint.solid).toList(),
      ),
    ),
    ChartType.radar => cj.RadarDataset(
      key: key,
      label: label,
      data: [for (final p in values) p.y],
      borderColor: fill,
      backgroundColor: fill,
    ),
  };
}

const Map<ChartType, cj.ChartKind> _kinds = {
  ChartType.line: cj.ChartKind.line,
  ChartType.bar: cj.ChartKind.bar,
  ChartType.scatter: cj.ChartKind.scatter,
  ChartType.bubble: cj.ChartKind.bubble,
  ChartType.pie: cj.ChartKind.pie,
  ChartType.doughnut: cj.ChartKind.doughnut,
  ChartType.polarArea: cj.ChartKind.polarArea,
  ChartType.radar: cj.ChartKind.radar,
};

/// One chart of a cell.
cj.ChartConfig _config({
  required ChartType type,
  required int count,
  required int step,
  required bool animated,
  int datasets = 1,
  bool stacked = false,
  bool time = false,
}) {
  final values = DatasetGenerator(count, 7).frame(step).values;
  final xy =
      type == ChartType.line ||
      type == ChartType.scatter ||
      type == ChartType.bubble;
  // A time axis reads dates: one point each minute.
  final base = DateTime.utc(2026).millisecondsSinceEpoch.toDouble();
  return cj.ChartConfig(
    type: _kinds[type]!,
    datasets: [
      for (var s = 0; s < datasets; s++)
        if (time)
          cj.LineDataset(
            key: ValueKey('series$s'),
            label: 'Series $s',
            points: [
              for (final p in values)
                cj.DataPoint(base + p.index * 60000, p.y - s * 4),
            ],
            borderColor: cj.ChartValue<ChartPaint>.constant(.solid(_colors[s])),
            backgroundColor: cj.ChartValue<ChartPaint>.constant(
              .solid(_colors[s]),
            ),
          )
        else
          _dataset(
            type,
            s == 0
                ? values
                : [
                    for (final p in values)
                      Sample(p.index, p.x, (p.y + s * 9) % 100),
                  ],
            series: s,
            stack: stacked ? 'all' : null,
          ),
    ],
    labels: xy ? null : [for (var i = 0; i < count; i++) '$i'],
    scales: time
        ? const {'x': cj.TimeAxis(), 'y': cj.LinearAxis()}
        : xy
        ? const {
            'x': cj.LinearAxis(min: 0, max: 100),
            'y': cj.LinearAxis(),
          }
        : stacked
        ? const {
            'x': cj.CategoryAxis(stacked: true),
            'y': cj.LinearAxis(stacked: true),
          }
        : null,
    legend: cj.ChartLegend(display: count <= 60 || xy || datasets > 1),
    animation: animated ? null : cj.ChartAnimation.none,
    responsive: true,
    maintainAspectRatio: false,
    extra: xy || time ? const {'parsing': false} : null,
  );
}

class _Phase {
  final Stopwatch _watch = Stopwatch()..start();
  int total = 0;
  int count = 0;
  int? _start;
  void begin() => _start = _watch.elapsedMicroseconds;
  void end() {
    final start = _start;
    if (start == null) return;
    total += _watch.elapsedMicroseconds - start;
    count++;
    _start = null;
  }

  void reset() {
    total = 0;
    count = 0;
    _start = null;
  }

  double get meanMs => count == 0 ? 0 : total / count / 1000;
}

final _update = _Phase();
final _draw = _Phase();
void Function()? _onDrawn;

Map<String, Object?> _timingPlugin() => <String, Object?>{
  'id': 'labEverydayTiming',
  'beforeUpdate': (Object? c, Object? a, Object? o) => _update.begin(),
  'afterUpdate': (Object? c, Object? a, Object? o) => _update.end(),
  'beforeDraw': (Object? c, Object? a, Object? o) => _draw.begin(),
  'afterDraw': (Object? c, Object? a, Object? o) {
    _draw.end();
    _onDrawn?.call();
  },
};

class _Harness extends StatefulWidget {
  const _Harness({super.key});
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  cj.ChartConfig? config;
  double widthDelta = 0;
  int mount = 0;
  final GlobalKey plotKey = GlobalKey();

  void show(cj.ChartConfig? next, {bool newChart = false}) {
    setState(() {
      config = next;
      if (newChart) mount++;
    });
  }

  void resizeBy(double delta) => setState(() => widthDelta = delta);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - 32).clamp(200.0, 964.0);
    final current = config;
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: SizedBox(
          key: plotKey,
          width: width - widthDelta,
          height: 420,
          child: current == null
              ? null
              : cj.ChartView(
                  key: ValueKey(mount),
                  config: current,
                  theme: const cj.ChartThemeData(),
                  excludeFromSemantics: true,
                ),
        ),
      ),
    );
  }
}

final _harnessKey = GlobalKey<_HarnessState>();

Future<void> _delay(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

/// A window of frames with their timings.
class _Capture {
  final List<FrameSample> frames = [];
  final List<double> busy = [];
  bool _on = false;
  final Stopwatch _watch = Stopwatch()..start();

  void start() {
    SchedulerBinding.instance.addTimingsCallback(_timings);
    late void Function(Duration) onFrame;
    onFrame = (_) {
      final begin = _watch.elapsedMicroseconds;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Timer.run(() {
          if (_on) busy.add((_watch.elapsedMicroseconds - begin) / 1000);
        });
        SchedulerBinding.instance.scheduleFrameCallback(onFrame);
      });
    };
    SchedulerBinding.instance.scheduleFrameCallback(onFrame);
  }

  void _timings(List<FrameTiming> timings) {
    if (!_on) return;
    for (final t in timings) {
      frames.add(
        FrameSample(
          t.timestampInMicroseconds(FramePhase.vsyncStart),
          t.buildDuration.inMicroseconds / 1000,
          t.rasterDuration.inMicroseconds / 1000,
        ),
      );
    }
  }

  void begin() {
    frames.clear();
    busy.clear();
    _update.reset();
    _draw.reset();
    _on = true;
  }

  Future<Map<String, Object?>> end(int seconds) async {
    // Frame timings come in groups.
    SchedulerBinding.instance.scheduleFrame();
    await _delay(400);
    _on = false;
    // Only the frames of the window: the wait above adds frames too.
    final first = frames.isEmpty
        ? 0
        : frames.map((f) => f.vsyncUs).reduce((a, b) => a < b ? a : b);
    final kept = frames
        .where((f) => f.vsyncUs < first + seconds * 1000000)
        .toList();
    final m = FrameMetrics.fromSamples(kept, windowSeconds: seconds * 1.0);
    final sorted = [...busy]..sort();
    double pct(double q) => sorted.isEmpty
        ? 0
        : sorted[(sorted.length * q).floor().clamp(0, sorted.length - 1)];
    double r(double v) => double.parse(v.toStringAsFixed(2));
    return {
      'fps': r(m.fps),
      'intervalP90': r(m.intervalP90),
      'intervalMax': r(m.intervalMax),
      'uiP90': r(m.uiP90),
      'rasterP90': r(m.rasterP90),
      'rasterMax': r(m.rasterMax),
      'updateMs': r(_update.meanMs),
      'drawMs': r(_draw.meanMs),
      'updates': _update.count,
      'draws': _draw.count,
      'busyP50': r(pct(.5)),
      'busyP90': r(pct(.9)),
    };
  }
}

final _capture = _Capture();

_HarnessState get _h => _harnessKey.currentState!;

/// New data each second, with the default animation of one second.
Future<Map<String, Object?>> _animate(
  ChartType type,
  int count,
  int seconds, {
  int datasets = 1,
  bool stacked = false,
  bool time = false,
}) async {
  var step = 0;
  cj.ChartConfig make() => _config(
    type: type,
    count: count,
    step: step += 60,
    animated: true,
    datasets: datasets,
    stacked: stacked,
    time: time,
  );
  _h.show(make(), newChart: true);
  await _delay(1200);
  final timer = Timer.periodic(
    const Duration(seconds: 1),
    (_) => _h.show(make()),
  );
  _capture.begin();
  await _delay(seconds * 1000);
  timer.cancel();
  return _capture.end(seconds);
}

/// A mouse that moves over the chart on each frame, with the tooltip and the
/// hover animations.
Future<Map<String, Object?>> _hover(
  ChartType type,
  int count,
  int seconds,
) async {
  _h.show(
    _config(type: type, count: count, step: 0, animated: true),
    newChart: true,
  );
  await _delay(1500);
  final box = _h.plotKey.currentContext!.findRenderObject()! as RenderBox;
  final origin = box.localToGlobal(Offset.zero);
  final size = box.size;
  const device = 77;
  final view = WidgetsBinding.instance.platformDispatcher.implicitView!.viewId;
  GestureBinding.instance.handlePointerEvent(
    PointerAddedEvent(viewId: view, device: device, position: origin),
  );
  var running = true;
  var tick = 0;
  void move(Duration _) {
    if (!running) return;
    tick++;
    // Across the plot and back in 2 seconds at 120 Hz, in a low wave.
    final t = (tick % 240) / 240;
    final u = t < .5 ? t * 2 : 2 - t * 2;
    final at =
        origin +
        Offset(
          size.width * (.05 + .9 * u),
          size.height * (.5 + .3 * ((tick % 60) / 60 - .5)),
        );
    GestureBinding.instance.handlePointerEvent(
      PointerHoverEvent(viewId: view, device: device, position: at),
    );
    SchedulerBinding.instance.scheduleFrameCallback(move);
  }

  SchedulerBinding.instance.scheduleFrameCallback(move);
  _capture.begin();
  await _delay(seconds * 1000);
  running = false;
  final row = await _capture.end(seconds);
  GestureBinding.instance.handlePointerEvent(
    PointerRemovedEvent(viewId: view, device: device),
  );
  return row;
}

/// A chart whose width changes on each frame: a drag of a split view.
Future<Map<String, Object?>> _resize(
  ChartType type,
  int count,
  int seconds,
) async {
  _h.show(
    _config(type: type, count: count, step: 0, animated: true),
    newChart: true,
  );
  await _delay(1500);
  var running = true;
  var tick = 0;
  void grow(Duration _) {
    if (!running) return;
    tick++;
    final t = (tick % 120) / 120;
    _h.resizeBy((t < .5 ? t * 2 : 2 - t * 2) * 120);
    SchedulerBinding.instance.scheduleFrameCallback(grow);
  }

  SchedulerBinding.instance.scheduleFrameCallback(grow);
  _capture.begin();
  await _delay(seconds * 1000);
  running = false;
  final row = await _capture.end(seconds);
  _h.resizeBy(0);
  return row;
}

/// A new chart again and again: the time to its first draw.
Future<Map<String, Object?>> _mount(
  ChartType type,
  int count,
  int seconds,
) async {
  final times = <double>[];
  final watch = Stopwatch();
  _capture.begin();
  final stop = Stopwatch()..start();
  while (stop.elapsed.inSeconds < seconds) {
    _h.show(null);
    await _delay(120);
    final config = _config(type: type, count: count, step: 0, animated: false);
    final drawn = Completer<void>();
    _onDrawn = () {
      if (!drawn.isCompleted) drawn.complete();
    };
    watch
      ..reset()
      ..start();
    _h.show(config, newChart: true);
    await drawn.future.timeout(const Duration(seconds: 5));
    watch.stop();
    _onDrawn = null;
    times.add(watch.elapsedMicroseconds / 1000);
    await _delay(180);
  }
  final row = await _capture.end(seconds);
  times.sort();
  double r(double v) => double.parse(v.toStringAsFixed(2));
  return row
    ..['mounts'] = times.length
    ..['firstDrawP50'] = r(times[times.length ~/ 2])
    ..['firstDrawP90'] = r(times[(times.length * 9) ~/ 10]);
}

/// Data updates with no animation, on each frame, for a chart of many series.
Future<Map<String, Object?>> _stream(
  ChartType type,
  int count,
  int seconds, {
  int datasets = 1,
  bool stacked = false,
  bool time = false,
}) async {
  var step = 0;
  cj.ChartConfig make() => _config(
    type: type,
    count: count,
    step: step++,
    animated: false,
    datasets: datasets,
    stacked: stacked,
    time: time,
  );
  _h.show(make(), newChart: true);
  await _delay(800);
  var running = true;
  void next(Duration _) {
    if (!running) return;
    _h.show(make());
    SchedulerBinding.instance.scheduleFrameCallback(next);
  }

  SchedulerBinding.instance.scheduleFrameCallback(next);
  _capture.begin();
  await _delay(seconds * 1000);
  running = false;
  return _capture.end(seconds);
}

typedef _Cell = ({
  String scenario,
  ChartType type,
  int count,
  int datasets,
  Future<Map<String, Object?>> Function(int seconds) run,
});

List<_Cell> _cells(List<String> scenarios, List<ChartType> types) {
  final cells = <_Cell>[];
  void add(
    String scenario,
    ChartType type,
    int count,
    Future<Map<String, Object?>> Function(int) run, {
    int datasets = 1,
  }) => cells.add((
    scenario: scenario,
    type: type,
    count: count,
    datasets: datasets,
    run: run,
  ));
  for (final type in types) {
    final sizes = _sizes[type]!;
    if (scenarios.contains('mount')) {
      add('mount', type, sizes[1], (s) => _mount(type, sizes[1], s));
    }
    if (scenarios.contains('animate')) {
      for (final n in sizes) {
        add('animate', type, n, (s) => _animate(type, n, s));
      }
    }
    if (scenarios.contains('hover')) {
      for (final n in sizes) {
        add('hover', type, n, (s) => _hover(type, n, s));
      }
    }
    if (scenarios.contains('resize')) {
      add('resize', type, sizes[1], (s) => _resize(type, sizes[1], s));
    }
  }
  if (scenarios.contains('series')) {
    add(
      'lines5-animate',
      ChartType.line,
      1000,
      (s) => _animate(ChartType.line, 1000, s, datasets: 5),
      datasets: 5,
    );
    add(
      'lines5-stream',
      ChartType.line,
      1000,
      (s) => _stream(ChartType.line, 1000, s, datasets: 5),
      datasets: 5,
    );
    add(
      'stacked-animate',
      ChartType.bar,
      200,
      (s) => _animate(ChartType.bar, 200, s, datasets: 5, stacked: true),
      datasets: 5,
    );
    add(
      'stacked-stream',
      ChartType.bar,
      200,
      (s) => _stream(ChartType.bar, 200, s, datasets: 5, stacked: true),
      datasets: 5,
    );
    add(
      'time-animate',
      ChartType.line,
      1000,
      (s) => _animate(ChartType.line, 1000, s, time: true),
    );
    add(
      'time-stream',
      ChartType.line,
      1000,
      (s) => _stream(ChartType.line, 1000, s, time: true),
    );
  }
  return cells;
}

List<String> _list(String name, String fallback) => (_option(name) ?? fallback)
    .split(',')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

Future<void> _run() async {
  await _delay(2000);
  hostStart();
  _capture.start();
  final seconds = int.parse(_option('MATRIX_SECONDS') ?? '4');
  final cool = _option('MATRIX_COOL') == '1';
  final scenarios = _list(
    'EVERYDAY_SCENARIOS',
    'mount,animate,hover,resize,series',
  );
  final types = _list(
    'EVERYDAY_TYPES',
    ChartType.values.map((t) => t.name).join(','),
  ).map(ChartType.values.byName).toList();
  // One capture with no row: the first capture of a process warms the engine.
  await _animate(ChartType.line, 100, 2);
  final hot = <_Cell>[];
  Future<void> one(_Cell cell, int pass) async {
    final (cal, coolS) = await coolDown(enabled: cool);
    Map<String, Object?> row;
    try {
      row = await cell.run(seconds);
    } on Object catch (error) {
      row = {'error': '$error'};
    }
    await _delay(100);
    final after = cpuTest();
    final size = _h.plotKey.currentContext?.size;
    row = {
      'scenario': cell.scenario,
      'type': cell.type.name,
      'count': cell.count,
      'datasets': cell.datasets,
      ...row,
      'plot': '${size?.width}x${size?.height}',
      'calMs': double.parse(cal.toStringAsFixed(2)),
      'calAfterMs': double.parse(after.toStringAsFixed(2)),
      'coolS': coolS,
      'pass': pass,
      'at': DateTime.now().millisecondsSinceEpoch,
    };
    hostLine('EVERYDAY ${jsonEncode(row)}');
    if (after > cpuTestBest * 1.15) hot.add(cell);
    _h.show(null);
    await _delay(150);
  }

  for (final cell in _cells(scenarios, types)) {
    await one(cell, 1);
  }
  if (cool) {
    for (final cell in List.of(hot)) {
      await one(cell, 2);
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
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _Harness(key: _harnessKey),
    ),
  );
  unawaited(_run());
}
