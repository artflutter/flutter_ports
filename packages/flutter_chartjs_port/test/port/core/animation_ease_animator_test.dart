// Original code, not ported from Chart.js: the ease table of Animator.update.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:clock/clock.dart';
import 'package:flutter/animation.dart' show Cubic, Curve, Curves;
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show
        BarDataset,
        CategoryAxis,
        ChartAnimation,
        ChartConfig,
        ChartKind,
        LinearAxis;
import 'package:flutter_chartjs_port/src/core/animation_ease.dart';
import 'package:flutter_chartjs_port/src/core/animation_spec.dart';
import 'package:flutter_chartjs_port/src/core/core.animator.dart' show Animator;
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// `Animator.update` with the table of `lib/src/core/animation_ease.dart`
// (row `adapt-animation-ease-table`). The twin of a run has a curve of a
// subclass of `Cubic` with the same fields: the class guard declines it, so
// each of its ticks calls the curve. Both runs must give the same doubles in
// each frame.

/// The count of the solves of each [_TwinCubic] object. A curve class is
/// immutable, so the count is not a field. Each test starts it at 0.
int _twinSolves = 0;

/// A subclass of [Cubic] with the fields of [Cubic]: it gives the values of
/// the SDK class and counts its solves in [_twinSolves].
final class const _TwinCubic(super.a, super.b, super.c, super.d) extends Cubic {
  factory of(Cubic curve) => _TwinCubic(curve.a, curve.b, curve.c, curve.d);

  @override
  double transformInternal(double t) {
    _twinSolves++;
    return super.transformInternal(t);
  }
}

/// A chart for the animator: [onDraw] runs in its draw, inside
/// `Animator.update`. Its other members throw.
final class _Chart() implements types.Chart {
  void Function()? onDraw;

  @override
  HTMLCanvasElement? get canvas => null;

  @override
  final Map<String, Object?> options = {};

  @override
  void draw() => onDraw?.call();

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The start of the animations of the animator tests, in milliseconds.
const double _base = 1000000;

/// Makes [count] targets with one number animation each. The animations
/// have seven start times, two durations, some delays and some loops, as
/// the animations of several chart updates have.
({List<Map<String, Object?>> targets, List<Animation> animations}) _mixed(
  Curve curve, {
  int count = 70,
}) {
  final targets = [
    for (var i = 0; i < count; i++) <String, Object?>{'value': 0.0},
  ];
  final animations = [
    for (var i = 0; i < count; i++)
      withClock(
        Clock.fixed(DateTime.fromMillisecondsSinceEpoch(_base.toInt() + i % 7)),
        () => Animation(
          AnimationSpec()
            ..duration = i % 3 == 0 ? 400.0 : 1000.0
            ..delay = i % 5 == 4 ? 48.0 : 0.0
            ..loop = i % 10 == 9
            ..easing = curve,
          targets[i],
          'value',
          10.0 + i,
        ),
      ),
  ];
  return (targets: targets, animations: animations);
}

/// Adds [animations] to [chart] in [animator] as a running chart, with no
/// frame callback.
void _run(Animator animator, _Chart chart, List<Animation> animations) {
  animator
    ..add(chart, animations)
    ..getAnims(chart).running = true;
}

/// The values of [targets] after each of [frames] `Animator.update` calls,
/// 16 ms apart.
List<List<double>> _frames(
  Animator animator,
  List<Map<String, Object?>> targets, {
  int frames = 90,
}) => [
  for (var frame = 0; frame < frames; frame++)
    () {
      animator.update(_base + frame * 16);
      return [for (final target in targets) target['value']! as double];
    }(),
];

/// Expects the same doubles, bit for bit, in [a] and [b].
void _expectSameBits(List<List<double>> a, List<List<double>> b) {
  expect(a.length, b.length);
  for (var i = 0; i < a.length; i++) {
    for (var j = 0; j < a[i].length; j++) {
      // `identical` of two doubles compares their bits on the VM.
      expect(
        identical(a[i][j], b[i][j]),
        isTrue,
        reason: 'frame $i target $j: ${a[i][j]} and ${b[i][j]}',
      );
    }
  }
}

/// The count of the bars of each chart of this file.
const int _count = 40;

List<double> _data(int seed) => [
  for (var i = 0; i < _count; i++) 5.0 + ((i * 37 + seed * 11) % 90),
];

/// A bar chart of one dataset with the data of [seed], the default
/// animations and a fixed value range. [easing] is the curve of the chart,
/// or Dart `null` for the default. [log] gets a line for each animation
/// event.
ChartConfig _config(List<String> log, Curve? easing, int seed) => ChartConfig(
  type: ChartKind.bar,
  labels: [for (var i = 0; i < _count; i++) 'l$i'],
  datasets: [BarDataset(data: _data(seed))],
  scales: const {'y': LinearAxis(min: 0, max: 100)},
  animation: _animation(log, easing),
);

/// A horizontal bar chart of two stacked datasets, as [_config]. [seed] is
/// the data of the first dataset.
ChartConfig _stackedConfig(List<String> log, Curve? easing, int seed) =>
    ChartConfig(
      type: ChartKind.bar,
      labels: [for (var i = 0; i < _count; i++) 'l$i'],
      datasets: [
        BarDataset(data: _data(seed)),
        BarDataset(data: _data(5)),
      ],
      indexAxis: const YAxis(),
      scales: const {
        'x': LinearAxis(stacked: StackMode.on, min: 0, max: 200),
        'y': CategoryAxis(stacked: StackMode.on),
      },
      animation: _animation(log, easing),
    );

/// The chart animation: the curve [easing], and a line in [log] for each
/// animation event.
ChartAnimation _animation(List<String> log, Curve? easing) => ChartAnimation(
  easing: easing,
  onProgress: (event) =>
      log.add('progress ${event.currentStep} of ${event.numSteps}'),
  onComplete: (event) =>
      log.add('complete ${event.currentStep} of ${event.numSteps}'),
);

/// The bars of each dataset of [chart].
List<BarElement> _bars(Chart chart) => [
  for (final meta in chart.getSortedVisibleDatasetMetas())
    ...meta.data.cast<BarElement>(),
];

/// The geometry of each bar. The text of a double names one double, with
/// the sign of a zero.
String _geometry(Chart chart) => [
  for (final bar in _bars(chart))
    [bar.x, bar.y, bar.base, bar.width, bar.height].join(','),
].join(';');

/// The `$animations` entries of each bar: the key order and the state of
/// each animation, without its curve object.
String _running(Chart chart, double date) => [
  for (final bar in _bars(chart))
    [
      for (final MapEntry(:key, :value)
          in (bar.$animations ?? const <String, Object?>{}).entries)
        if (value case final Animation animation)
          [
            key,
            animation.active(),
            animation.from,
            animation.to,
            animation.start - date,
            animation.duration,
            animation.total,
            animation.loop,
          ].join(':'),
    ].join(','),
].join(';');

/// The observations of one animated update of a chart.
typedef _ChartRun = ({
  List<String> frames,
  String running,
  int hits,
  int misses,
});

/// Makes the chart of [config] with the curve [easing], waits for the end
/// of its first animations, gives it new data, updates it and pumps frames
/// until the animations end. With [live], the chart gets new data and an
/// update after the frames 3 and 5, while the animations run. A new config
/// reaches the live scopes of the chart through [ChartConfigLowering.apply],
/// as in `ChartView`.
Future<_ChartRun> _chartRun(
  ChartConfig Function(List<String> log, Curve? easing, int seed) config,
  Curve? easing, {
  bool live = false,
}) async {
  final log = <String>[];
  final lowering = ChartConfigLowering(config(log, easing, 1));
  final chart = acquireChartRoot(lowering.lower());
  await pumpFrames(() => !animator.running(chart));
  log.clear();
  final hits = debugEaseTableHits;
  final misses = debugEaseTableMisses;
  var seed = 2;
  void setData() => lowering.apply(config(log, easing, seed++));

  setData();
  final date = clock.now().millisecondsSinceEpoch.toDouble();
  chart.update();
  final running = _running(chart, date);
  final frames = <String>['update ${_geometry(chart)} $log'];
  log.clear();
  for (var frame = 1; animator.running(chart) && frame < 200; frame++) {
    await pumpFrame();
    frames.add('frame $frame ${_geometry(chart)} $log');
    log.clear();
    if (live && (frame == 3 || frame == 5)) {
      setData();
      chart.update();
      frames.add('live ${_geometry(chart)} $log');
      log.clear();
    }
  }
  return (
    frames: frames,
    running: running,
    hits: debugEaseTableHits - hits,
    misses: debugEaseTableMisses - misses,
  );
}

void main() {
  setUp(() => _twinSolves = 0);

  group('Animator.update', () {
    test('gives the values of its twin for mixed starts, durations, delays '
        'and loops', () {
      final animator = Animator();
      final table = _mixed(Curves.easeOutQuart);
      _run(animator, _Chart(), table.animations);
      final hits = debugEaseTableHits;
      final misses = debugEaseTableMisses;
      final tableFrames = _frames(animator, table.targets);
      final tableHits = debugEaseTableHits - hits;
      final tableMisses = debugEaseTableMisses - misses;

      final curve = _TwinCubic.of(Curves.easeOutQuart);
      final twin = _mixed(curve);
      final twinAnimator = Animator();
      _run(twinAnimator, _Chart(), twin.animations);
      final twinFrames = _frames(twinAnimator, twin.targets);

      _expectSameBits(tableFrames, twinFrames);
      // The twin took no table.
      expect(debugEaseTableHits - hits, tableHits);
      expect(debugEaseTableMisses - misses, tableMisses);
      // Each solve of the twin is a hit or a miss of the table, and most
      // of them are hits.
      expect(tableHits + tableMisses, _twinSolves);
      expect(tableHits, greaterThan(_twinSolves ~/ 2));
      expect(tableMisses, greaterThan(90));
    });

    test('the table lives while the call runs', () {
      final animator = Animator();
      final chart = _Chart();
      final mixed = _mixed(Curves.easeOutQuart);
      _run(animator, chart, mixed.animations);
      final seen = <String>[];
      chart.onDraw = () =>
          seen.add('$easeTableActive ${debugEaseTableEntries > 0}');

      expect(easeTableActive, isFalse);
      animator.update(_base + 160);
      expect(seen, ['true true']);
      expect(easeTableActive, isFalse);
      expect(debugEaseTableEntries, 0);
    });

    test('a call inside another call keeps the table of the outer call', () {
      List<List<double>> framesOf(Curve curve) {
        final animator = Animator();
        final chart = _Chart();
        final other = _Chart();
        final mixed = _mixed(curve);
        // A second chart of the same animator, after the first one: the
        // outer call ticks it after the inner calls.
        final later = _mixed(curve, count: 20);
        _run(animator, chart, mixed.animations);
        _run(animator, other, later.animations);
        var inner = false;
        chart.onDraw = () {
          if (inner) return;
          inner = true;
          final entries = debugEaseTableEntries;
          // Another animator with no chart, and the same animator again.
          Animator().update(_base + 160);
          expect(easeTableActive, isTrue);
          expect(debugEaseTableEntries, entries);
          animator.update(_base + 160);
          expect(easeTableActive, isTrue);
          inner = false;
        };
        final frames = _frames(animator, [
          ...mixed.targets,
          ...later.targets,
        ], frames: 30);
        expect(easeTableActive, isFalse);
        expect(debugEaseTableEntries, 0);
        return frames;
      }

      _expectSameBits(
        framesOf(Curves.easeOutQuart),
        framesOf(_TwinCubic.of(Curves.easeOutQuart)),
      );
    });

    test('a throw in a tick ends the table', () {
      final animator = Animator();
      final chart = _Chart();
      final target = <String, Object?>{'value': 0.0, 'other': 0.0};
      Object? fail(Object? from, Object? to, double factor) =>
          throw StateError('fn');
      final (throwing, plain) = withClock(
        Clock.fixed(DateTime.fromMillisecondsSinceEpoch(_base.toInt())),
        () => (
          Animation(
            AnimationSpec()
              ..duration = 1000.0
              ..fn = fail,
            target,
            'other',
            10.0,
          ),
          Animation(
            AnimationSpec()
              ..duration = 1000.0
              ..easing = Curves.easeOutQuart,
            target,
            'value',
            10.0,
          ),
        ),
      );
      // The loop ticks the last item first.
      _run(animator, chart, [throwing, plain]);

      expect(() => animator.update(_base + 300), throwsStateError);
      expect(target['value'], 10 * Curves.easeOutQuart.transform(0.3));
      expect(easeTableActive, isFalse);
      expect(debugEaseTableEntries, 0);
    });

    test('a cancel outside the call calls the curve', () {
      final animator = Animator();
      final chart = _Chart();
      final target = <String, Object?>{'value': 0.0};
      final animation = withClock(
        Clock.fixed(DateTime.fromMillisecondsSinceEpoch(_base.toInt())),
        () => Animation(
          AnimationSpec()
            ..duration = 1000.0
            ..easing = Curves.easeOutQuart,
          target,
          'value',
          10.0,
        ),
      );
      _run(animator, chart, [animation]);
      final hits = debugEaseTableHits;
      final misses = debugEaseTableMisses;

      withClock(
        Clock.fixed(DateTime.fromMillisecondsSinceEpoch(_base.toInt() + 300)),
        () => animator.stop(chart),
      );
      expect(target['value'], 10 * Curves.easeOutQuart.transform(0.3));
      expect(debugEaseTableHits, hits);
      expect(debugEaseTableMisses, misses);
      expect(debugEaseTableEntries, 0);
    });
  });

  group('a bar chart', () {
    testWidgets('the default curve gives the frames of its twin', (
      tester,
    ) async {
      final table = await _chartRun(_config, null);
      final curve = _TwinCubic.of(Curves.easeOutQuart);
      final twin = await _chartRun(_config, curve);

      expect(table.frames.length, greaterThan(30));
      expect(table.frames, twin.frames);
      expect(table.running, twin.running);
      // One curve call for the equal inputs of a frame.
      expect(table.hits, greaterThan(table.frames.length * _count));
      expect(table.misses, lessThan(table.frames.length * 2));
      // The twin took no table.
      expect(twin.hits, 0);
      expect(twin.misses, 0);
      expect(_twinSolves, greaterThan(table.hits));
    });

    testWidgets('stacked bars with updates while the animations run', (
      tester,
    ) async {
      final table = await _chartRun(_stackedConfig, null, live: true);
      final curve = _TwinCubic.of(Curves.easeOutQuart);
      final twin = await _chartRun(_stackedConfig, curve, live: true);

      expect(table.frames.where((line) => line.startsWith('live')).length, 2);
      expect(table.frames, twin.frames);
      expect(table.running, twin.running);
      expect(table.hits, greaterThan(table.frames.length * _count));
      expect(twin.hits, 0);
      expect(twin.misses, 0);
    });

    testWidgets('a curve object of the chart options takes the table', (
      tester,
    ) async {
      final table = await _chartRun(_config, Curves.easeInOutCubic);
      final curve = _TwinCubic.of(Curves.easeInOutCubic);
      final twin = await _chartRun(_config, curve);

      expect(table.frames, twin.frames);
      expect(table.hits, greaterThan(table.frames.length * _count));
      expect(twin.hits, 0);
    });
  });
}
