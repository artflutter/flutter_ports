// Native and browser driver: the page around the chart.
//
// The lab matrix measures charts. This driver measures what a person feels
// outside the chart: the first frames, an idle page, scrolling, the readout of
// a run, hover, taps on controls, a dialog and a window resize. The chart stays
// small, so that the figures show the page. Each scenario prints one
// `PAGE {json}` line, and the last line is `MATRIX_DONE`.
//
// Option PAGE_ONLY: the names of the scenarios to run, with commas.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show FramePhase;

import 'package:chart_benchmark_lab/benchmark/config.dart';
import 'package:chart_benchmark_lab/benchmark/controller.dart';
import 'package:chart_benchmark_lab/benchmark/metrics.dart';
import 'package:chart_benchmark_lab/charts/chart_adapter.dart';
import 'package:chart_benchmark_lab/ui/benchmark_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as cj;
import 'package:material_ui/material_ui.dart';

import 'perf_matrix_host.dart';

const _lightCount = 100;
const _heavyCount = 5000;

const _onlyDefine = String.fromEnvironment('PAGE_ONLY');

final Set<String>? _only = () {
  final value = hostEnv('PAGE_ONLY') ?? _onlyDefine;
  return value.isEmpty ? null : value.split(',').toSet();
}();

Future<void> _delay(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

double _round(double value) => double.parse(value.toStringAsFixed(2));

/// A window of frames, with their engine timings.
class _Capture {
  final List<FrameSample> _timings = [];
  final List<int> _stamps = [];
  bool _on = false;

  void install() {
    SchedulerBinding.instance
      ..addTimingsCallback((timings) {
        for (final t in timings) {
          _timings.add(
            FrameSample(
              t.timestampInMicroseconds(FramePhase.vsyncStart),
              t.buildDuration.inMicroseconds / 1000,
              t.rasterDuration.inMicroseconds / 1000,
            ),
          );
        }
      })
      ..addPersistentFrameCallback((_) {
        if (_on) {
          _stamps.add(
            SchedulerBinding
                .instance
                .currentSystemFrameTimeStamp
                .inMicroseconds,
          );
        }
      });
  }

  Future<Map<String, Object?>> measure(Future<void> Function() body) async {
    _timings.clear();
    _stamps.clear();
    _on = true;
    await body();
    _on = false;
    // Frame timings come in groups, after the frame.
    for (var i = 0; i < 3; i++) {
      SchedulerBinding.instance.scheduleFrame();
      await _delay(200);
    }
    return _summary();
  }

  Map<String, Object?> _summary() {
    final stamps = [..._stamps];
    if (stamps.isEmpty) return {'frames': 0};
    // A web timing can stand a little before the time stamp of its frame.
    final first = stamps.first - 30000;
    final frames = _timings
        .where((f) => f.vsyncUs >= first)
        .take(stamps.length)
        .toList();
    final refresh = _display();
    final budget = 1000 / refresh;
    final ui = frames.map((f) => f.uiMs).toList()..sort();
    final raster = frames.map((f) => f.rasterMs).toList()..sort();
    double at(List<double> values, double q) => values.isEmpty
        ? 0
        : _round(
            values[(values.length * q).ceil().clamp(1, values.length) - 1],
          );
    final gaps = <double>[
      for (var i = 1; i < stamps.length; i++)
        (stamps[i] - stamps[i - 1]) / 1000,
    ]..sort();
    return {
      'frames': stamps.length,
      'timed': frames.length,
      'uiP50': at(ui, .5),
      'uiP90': at(ui, .9),
      'uiP99': at(ui, .99),
      'uiMax': ui.isEmpty ? 0 : _round(ui.last),
      'rasterP50': at(raster, .5),
      'rasterP90': at(raster, .9),
      'rasterP99': at(raster, .99),
      'rasterMax': raster.isEmpty ? 0 : _round(raster.last),
      'overBudget': frames
          .where((f) => math.max(f.uiMs, f.rasterMs) > budget)
          .length,
      'gapP90': at(gaps, .9),
      'gapMax': gaps.isEmpty ? 0 : _round(gaps.last),
      'lateGaps': gaps.where((gap) => gap > budget * 1.5).length,
    };
  }
}

double _display() {
  final view = WidgetsBinding.instance.platformDispatcher.implicitView!;
  try {
    final rate = view.display.refreshRate;
    return rate > 0 ? rate : 60;
    // A display can arrive after its view.
    // ignore: avoid_catching_errors
  } on Error {
    return 60;
  }
}

/// Gives the page a smaller window, as a person who drags the edge of the
/// window does.
class _WindowHost extends StatefulWidget {
  const _WindowHost({required this.child, super.key});
  final Widget child;
  @override
  State<_WindowHost> createState() => _WindowHostState();
}

class _WindowHostState extends State<_WindowHost> {
  double _shrink = 0;

  // The driver sets the width on each frame.
  void shrink(double value) => setState(() => _shrink = value);

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final size = Size(data.size.width - _shrink, data.size.height);
    return MediaQuery(
      data: data.copyWith(size: size),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox.fromSize(size: size, child: widget.child),
      ),
    );
  }
}

final _windowKey = GlobalKey<_WindowHostState>();

Iterable<Element> _walk(Element root) sync* {
  final children = <Element>[];
  root.visitChildElements(children.add);
  for (final child in children) {
    yield child;
    yield* _walk(child);
  }
}

Iterable<Element> get _elements => _walk(WidgetsBinding.instance.rootElement!);

Element? _byKey(String key) {
  final wanted = ValueKey(key);
  for (final element in _elements) {
    if (element.widget.key == wanted) return element;
  }
  return null;
}

Element? _ofType<T extends Widget>() {
  for (final element in _elements) {
    if (element.widget is T) return element;
  }
  return null;
}

Offset _center(Element element) {
  final box = element.findRenderObject()! as RenderBox;
  return box.localToGlobal(box.size.center(Offset.zero));
}

int get _view =>
    WidgetsBinding.instance.platformDispatcher.implicitView!.viewId;

int _nextPointer = 1000;

Future<void> _tap(Offset position) async {
  final pointer = _nextPointer++;
  GestureBinding.instance.handlePointerEvent(
    PointerDownEvent(
      viewId: _view,
      pointer: pointer,
      device: 91,
      position: position,
    ),
  );
  await _delay(50);
  GestureBinding.instance.handlePointerEvent(
    PointerUpEvent(
      viewId: _view,
      pointer: pointer,
      device: 91,
      position: position,
    ),
  );
}

/// Calls [step] with the time in seconds on each frame, for [seconds].
Future<void> _onEachFrame(int seconds, void Function(double t) step) {
  final done = Completer<void>();
  final watch = Stopwatch()..start();
  void frame(Duration _) {
    final t = watch.elapsedMicroseconds / 1000000;
    if (t >= seconds) {
      done.complete();
      return;
    }
    step(t);
    SchedulerBinding.instance.scheduleFrameCallback(frame);
  }

  SchedulerBinding.instance.scheduleFrameCallback(frame);
  return done.future;
}

/// Brings [element] to the middle of its scroll view.
Future<void> _reveal(Element element) async {
  await Scrollable.ensureVisible(element, alignment: .5);
  await _delay(300);
}

/// Scrolls the scroll view of [element] down and up, for about [seconds].
Future<void> _scroll(Element element, int seconds) async {
  final position = Scrollable.of(element).position;
  final half = Duration(milliseconds: seconds * 500);
  final end = position.maxScrollExtent;
  await position.animateTo(end, duration: half, curve: Curves.linear);
  await position.animateTo(0, duration: half, curve: Curves.linear);
}

BenchmarkResult _result(
  BenchmarkController c,
  int i, {
  BenchmarkConfig? config,
}) {
  const libraries = ChartLibrary.values;
  final fps = 20.0 + i * 4;
  return BenchmarkResult(
    library: libraries[i % libraries.length],
    config: config ?? c.config,
    viewport: c.viewport,
    dpr: c.dpr,
    refreshRate: c.refreshRate,
    metrics: FrameMetrics(
      samples: 600,
      fps: fps,
      intervalP90: 1000 / fps,
      uiP90: 3.0 + i * .2,
      rasterP90: 4.0 + i * .3,
      overBudgetPercent: i * 1.5,
    ),
    durationSeconds: c.captureSeconds,
    createdAt: DateTime.utc(2026),
  );
}

Future<void> _driver(BenchmarkController c, Stopwatch sinceMain) async {
  hostStart();
  final capture = _Capture()..install();
  // This function starts during the first build. The figure is the end of that
  // frame on the UI thread: a browser reports no timing for an idle page.
  await WidgetsBinding.instance.endOfFrame;
  final firstFrameMs = sinceMain.elapsedMilliseconds;
  // A window reaches its size some time after the first frame.
  await _delay(1500);
  final view = WidgetsBinding.instance.platformDispatcher.implicitView!;
  final size = view.physicalSize / view.devicePixelRatio;
  final narrow = size.width < 1000;

  Future<void> scenario(
    String name,
    Future<void> Function() body, {
    Map<String, Object?> extra = const {},
    bool continuous = false,
  }) async {
    if (_only != null && !_only!.contains(name)) return;
    final figures = await capture.measure(body);
    // A wait of the script between two actions is no late frame.
    if (!continuous) {
      figures
        ..remove('gapP90')
        ..remove('gapMax')
        ..remove('lateGaps');
    }
    final page = {
      'scenario': name,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'width': size.width,
      'height': size.height,
      'refreshHz': _display(),
      ...figures,
      ...extra,
    };
    hostLine('PAGE ${jsonEncode(page)}');
  }

  hostLine(
    'PAGE ${jsonEncode({'scenario': 'startup', 'firstFrameMs': firstFrameMs})}',
  );

  await scenario('idle', () => _delay(3000));

  c.configure(const BenchmarkConfig(count: _lightCount));
  await _delay(500);
  Element content() => _byKey('library.chartjs')!;

  await scenario('scroll.empty', () => _scroll(content(), 6), continuous: true);

  // A tap on a setting, with no saved rows to rebuild.
  if (!narrow) {
    await _reveal(_byKey('feature.tooltips')!);
    await scenario('toggle.empty', () async {
      for (var i = 0; i < 6; i++) {
        await _tap(_center(_byKey('feature.tooltips')!));
        await _delay(400);
      }
    });
  }

  c.results.addAll([for (var i = 0; i < 24; i++) _result(c, i)]);
  c.clearStopReason();
  await _delay(500);
  await scenario('scroll.table', () => _scroll(content(), 6), continuous: true);

  await _reveal(_ofType<BenchmarkChart>()!);
  await scenario('run.readout', () async {
    c.start();
    await _delay(6000);
    c.pause();
  }, continuous: true);
  await _delay(500);

  await _reveal(_ofType<FilterChip>()!);
  // Rows of another workload, so that each tap changes the rows of the table.
  final hidden = [
    for (var i = 0; i < 4; i++)
      _result(c, i, config: c.config.copyWith(markers: true)),
  ];
  c.results.addAll(hidden);
  c.clearStopReason();
  await _delay(300);
  await scenario('filter.chip', () async {
    for (var i = 0; i < 6; i++) {
      await _tap(_center(_ofType<FilterChip>()!));
      await _delay(400);
    }
  });
  c.results.removeWhere(hidden.contains);
  c.clearStopReason();
  await _delay(300);

  await scenario('sort.table', () async {
    for (var i = 0; i < 6; i++) {
      final table = _ofType<DataTable>()!.widget as DataTable;
      table.columns[3 + i % 3].onSort!(3 + i % 3, true);
      await _delay(400);
    }
  });

  // The settings of a phone stay closed until a person opens them.
  Future<void> tapSettingsTile() async {
    final tile = _walk(_ofType<ExpansionTile>()!)
        .firstWhere((e) => e.widget is ListTile);
    await _reveal(tile);
    await _tap(_center(tile));
    await _delay(500);
  }

  if (narrow) {
    await scenario('settings.expand', () async {
      for (var i = 0; i < 4; i++) {
        await tapSettingsTile();
      }
    });
    await tapSettingsTile();
  }

  await _reveal(_byKey('feature.tooltips')!);
  await scenario('toggle.feature', () async {
    for (var i = 0; i < 6; i++) {
      await _tap(_center(_byKey('feature.tooltips')!));
      await _delay(400);
    }
  });

  await _reveal(_byKey('dataset.slider')!);
  final sliderStart = _center(_byKey('dataset.slider')!);
  final sliderPointer = _nextPointer++;
  var sliderLast = sliderStart;
  await scenario('slider.drag', () async {
    GestureBinding.instance.handlePointerEvent(
      PointerDownEvent(
        viewId: _view,
        pointer: sliderPointer,
        device: 91,
        position: sliderStart,
      ),
    );
    await _onEachFrame(3, (t) {
      final next = sliderStart + Offset(60 * math.sin(t * 3), 0);
      GestureBinding.instance.handlePointerEvent(
        PointerMoveEvent(
          viewId: _view,
          pointer: sliderPointer,
          device: 91,
          position: next,
          delta: next - sliderLast,
        ),
      );
      sliderLast = next;
    });
  }, continuous: true);
  // The release commits the size and mounts another chart, outside the window.
  GestureBinding.instance.handlePointerEvent(
    PointerUpEvent(
      viewId: _view,
      pointer: sliderPointer,
      device: 91,
      position: sliderLast,
    ),
  );
  await _delay(500);
  c.configure(const BenchmarkConfig(count: _lightCount));
  await _delay(500);

  if (narrow) await tapSettingsTile();

  await _reveal(content());
  await scenario('library.switch', () async {
    const names = ['flChart', 'chartjs', 'syncfusion', 'chartjs'];
    for (final name in names) {
      await _tap(_center(_byKey('library.$name')!));
      await _delay(500);
    }
  });

  await scenario('dialog.open', () async {
    for (var i = 0; i < 3; i++) {
      await _tap(_center(_byKey('changelog')!));
      await _delay(500);
      await _tap(_center(_byKey('changelog.close')!));
      await _delay(500);
    }
  });

  if (!narrow) {
    await scenario('hover.controls', () async {
      const device = 92;
      final settings = _center(_byKey('feature.grid')!);
      var last = settings;
      GestureBinding.instance.handlePointerEvent(
        PointerAddedEvent(
          viewId: _view,
          device: device,
          kind: PointerDeviceKind.mouse,
          position: last,
        ),
      );
      await _onEachFrame(4, (t) {
        final next =
            settings + Offset(100 * math.sin(t * 2.3), 300 * math.sin(t * 1.1));
        GestureBinding.instance.handlePointerEvent(
          PointerHoverEvent(
            viewId: _view,
            device: device,
            kind: PointerDeviceKind.mouse,
            position: next,
            delta: next - last,
          ),
        );
        last = next;
      });
      GestureBinding.instance.handlePointerEvent(
        PointerRemovedEvent(
          viewId: _view,
          device: device,
          kind: PointerDeviceKind.mouse,
          position: last,
        ),
      );
    }, continuous: true);
  }

  await _reveal(_ofType<BenchmarkChart>()!);
  await scenario('run.pause', () async {
    for (var i = 0; i < 3; i++) {
      await _tap(_center(_byKey('run')!));
      await _delay(500);
      await _tap(_center(_byKey('run')!));
      await _delay(500);
    }
  });

  // A person who drags the edge of a window changes the width on each frame.
  Future<void> resize() {
    var frame = 0;
    return _onEachFrame(5, (_) {
      final phase = frame++ % 60;
      _windowKey.currentState!.shrink((phase < 30 ? phase : 60 - phase) * 2);
    });
  }

  await scenario('resize.light', resize, continuous: true);
  _windowKey.currentState!.shrink(0);
  await _delay(500);

  c.configure(const BenchmarkConfig(count: _heavyCount));
  await _delay(1000);
  await scenario('resize.heavy', resize, continuous: true);
  _windowKey.currentState!.shrink(0);
  await _delay(500);

  hostLine('MATRIX_DONE');
  await hostExit();
}

/// A fault of the driver ends the run at once, with its text.
Future<void> _guarded(BenchmarkController c, Stopwatch sinceMain) async {
  try {
    await _driver(c, sinceMain);
  } on Object catch (error, stack) {
    hostLine('PAGE_ERROR $error $stack');
    hostLine('MATRIX_DONE');
  }
}

void main() {
  final sinceMain = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  cj.Chart.register(cj.registerables);
  runApp(
    MaterialApp(
      title: 'Chart benchmark lab',
      debugShowCheckedModeBanner: false,
      // The theme of ChartBenchmarkApp.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff4f46e5)),
        scaffoldBackgroundColor: const Color(0xfff4f6fa),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xffe1e6ef)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          border: OutlineInputBorder(),
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xff17243b),
          displayColor: const Color(0xff17243b),
        ),
      ),
      // fl_chart and Syncfusion still read the old Material theme.
      // ignore: deprecated_member_use
      builder: (context, child) => MaterialUiCompatibilityBridge(
        // The test of a resize changes the window of the page.
        child: _WindowHost(key: _windowKey, child: child!),
      ),
      home: BenchmarkPage(
        onControllerReady: (c) => unawaited(_guarded(c, sinceMain)),
      ),
    ),
  );
}
