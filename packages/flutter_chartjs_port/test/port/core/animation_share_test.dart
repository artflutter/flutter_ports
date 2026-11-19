// Original code, not ported from Chart.js: shared bar animation options.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:clock/clock.dart';
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/core/animation_share.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart' as core;
import 'package:flutter_chartjs_port/src/core/option_call_epoch.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../../support/animation_spec_input.dart';

// `BarController.update` with one resolution of the animation options for
// its bars (`lib/src/core/animation_share.dart`, row
// `adapt-shared-bar-animations`, Chart.js ADR 0151). The twin of each run has
// the same config with a function at `animation.delay` that gives the
// default value `undefined`: the guard declines it, so each bar of the twin
// takes the ordinary resolution of upstream. Both runs must give the same
// geometry in each frame, the same animation events, the same `$animations`
// entries, the same contexts and the same count of animator items.

/// The count of the bars of each dataset of this file.
const int _count = 40;

List<double> _data(int seed) => [
  for (var i = 0; i < _count; i++) 5.0 + ((i * 37 + seed * 11) % 90),
];

/// The option `animation.delay` of a twin: a function that gives the
/// default value, `undefined`. No transition of the defaults sets `delay`,
/// so each entry of each mode calls it.
Object? _twinDelay(Object? context, Object? options) => undefined;

/// The `animation` options of each chart: a log line for each event, and
/// [extra].
Map<String, Object?> _animation(
  List<String> log,
  Map<String, Object?>? extra, {
  required bool twin,
}) => <String, Object?>{
  'onProgress': (AnimationEvent event) =>
      log.add('progress ${event.currentStep} of ${event.numSteps}'),
  'onComplete': (AnimationEvent event) =>
      log.add('complete ${event.currentStep} of ${event.numSteps}'),
  if (twin) 'delay': _twinDelay,
  ...?extra,
};

/// A chart config. [twin] puts the function of [_twinDelay] at
/// `animation.delay`.
typedef _Config = Map<String, Object?> Function(
  List<String> log, {
  required bool twin,
});

/// A bar chart of one dataset with the default animations and a fixed value
/// range. [animation] adds keys to the `animation` options, and [dataset]
/// adds dataset keys.
_Config _bar({
  Map<String, Object?>? animation,
  Map<String, Object?>? dataset,
}) =>
    (log, {required twin}) => <String, Object?>{
      'type': 'bar',
      'data': <String, Object?>{
        'labels': [for (var i = 0; i < _count; i++) 'l$i'],
        'datasets': <Object?>[
          <String, Object?>{'data': _data(1), ...?dataset},
        ],
      },
      'options': <String, Object?>{
        'animation': _animation(log, animation, twin: twin),
        'scales': <String, Object?>{
          'y': <String, Object?>{'min': 0.0, 'max': 100.0},
        },
      },
    };

/// A horizontal bar chart of two stacked datasets with the default
/// animations.
Map<String, Object?> _stacked(List<String> log, {required bool twin}) =>
    <String, Object?>{
      'type': 'bar',
      'data': <String, Object?>{
        'labels': [for (var i = 0; i < _count; i++) 'l$i'],
        'datasets': <Object?>[
          <String, Object?>{'data': _data(1)},
          <String, Object?>{'data': _data(5)},
        ],
      },
      'options': <String, Object?>{
        'indexAxis': const YAxis(),
        'animation': _animation(log, null, twin: twin),
        'scales': <String, Object?>{
          'x': <String, Object?>{'stacked': true, 'min': 0.0, 'max': 200.0},
          'y': <String, Object?>{'stacked': true},
        },
      },
    };

List<core.Element> _bars(Chart chart) => [
  for (
    var i = 0;
    i < (jsGet(chart.data, 'datasets')! as List<Object?>).length;
    i++
  )
    ...chart.getDatasetMeta(i).data.cast<core.Element>(),
];

/// The geometry of each bar.
String _geometry(Chart chart) => [
  for (final bar in _bars(chart))
    [
      for (final name in const ['x', 'y', 'base', 'width', 'height']) bar[name],
    ].join(','),
].join(';');

/// The `$animations` entries of each bar: the key order and the state of
/// each animation, with the start relative to [date].
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

/// The context of each bar: the keys that the shared path writes.
String _contexts(Chart chart) => [
  for (final bar in _bars(chart))
    if (bar.$context case final Object context)
      [
        for (final name in const ['index', 'dataIndex', 'active', 'mode'])
          jsGet(context, name),
        jsGet(jsGet(context, 'parsed'), 'y'),
        jsGet(context, 'raw'),
      ].join(','),
].join(';');

/// The observations of one run.
typedef _Run = ({
  List<String> frames,
  String running,
  String contexts,
  int items,
  int hits,
});

/// Makes the chart of [config], waits for the end of its first animations,
/// applies [change] and pumps frames until the animations end. [change]
/// updates the chart. [live] runs at the frames 3 and 5 and updates the
/// chart again while the animations run.
Future<_Run> _run(
  _Config config, {
  required bool twin,
  void Function(Chart chart)? change,
  void Function(Chart chart)? live,
}) async {
  final log = <String>[];
  final chart = acquireChart(config(log, twin: twin));
  await pumpFrames(() => !animator.running(chart));
  log.clear();
  final hits = debugSharedBarAnimationHits;
  final date = clock.now().millisecondsSinceEpoch.toDouble();
  (change ?? _newData)(chart);
  final running = _running(chart, date);
  final contexts = _contexts(chart);
  final items = animator.getAnims(chart).items.length;
  final frames = <String>['update ${_geometry(chart)} $log'];
  log.clear();
  for (var frame = 1; animator.running(chart) && frame < 200; frame++) {
    await pumpFrame();
    frames.add('frame $frame ${_geometry(chart)} $log');
    log.clear();
    if (live != null && (frame == 3 || frame == 5)) {
      live(chart);
      frames.add('live ${_geometry(chart)} $log ${_running(chart, date)}');
      log.clear();
    }
  }
  return (
    frames: frames,
    running: running,
    contexts: contexts,
    items: items,
    hits: debugSharedBarAnimationHits - hits,
  );
}

/// Runs [config] and its twin, and compares them. The result is the run
/// with the shared path.
Future<_Run> _twins(
  _Config config, {
  void Function(Chart chart)? change,
  void Function(Chart chart)? Function()? live,
}) async {
  final shared = await _run(
    config,
    twin: false,
    change: change,
    live: live?.call(),
  );
  final twin = await _run(
    config,
    twin: true,
    change: change,
    live: live?.call(),
  );
  expect(twin.hits, 0, reason: 'the guard declines each bar of the twin');
  expect(shared.items, twin.items);
  expect(shared.running, twin.running);
  expect(shared.contexts, twin.contexts);
  expect(shared.frames, twin.frames);
  return shared;
}

void _newData(Chart chart) => _setData(chart, 2);

void _setData(Chart chart, int seed, [UpdateMode? mode]) {
  final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
  for (var i = 0; i < datasets.length; i++) {
    (datasets[i]! as Map<String, Object?>)['data'] = _data(seed + i);
  }
  chart.update(mode);
}

/// New data at each call, from the same seeds in each run.
void Function(Chart chart) _liveData() {
  var seed = 2;
  return (chart) => _setData(chart, ++seed);
}

void main() {
  group('the shared path and its twin', () {
    testWidgets('new data: one resolution for the bars of an update', (
      tester,
    ) async {
      final run = await _twins(_bar());
      expect(run.hits, _count - 1);
      expect(run.frames.length, greaterThan(10));
      expect(run.frames.join(), contains('complete'));
    });

    testWidgets('two stacked datasets of horizontal bars', (tester) async {
      final run = await _twins(_stacked);
      expect(run.hits, 2 * (_count - 1));
    });

    testWidgets('a live chart: updates while the animations run', (
      tester,
    ) async {
      final run = await _twins(_bar(), live: _liveData);
      expect(run.hits, 3 * (_count - 1));
      expect(run.frames.where((line) => line.startsWith('live')).length, 2);
    });

    testWidgets('an update with equal data', (tester) async {
      final run = await _twins(_bar(), change: (chart) => chart.update());
      expect(run.hits, _count - 1);
    });

    testWidgets('the mode resize', (tester) async {
      final run = await _twins(
        _bar(),
        change: (chart) => _setData(chart, 2, UpdateMode.resize),
      );
      expect(run.hits, _count - 1);
    });

    testWidgets('the mode active', (tester) async {
      final run = await _twins(
        _bar(),
        change: (chart) => _setData(chart, 2, UpdateMode.active),
      );
      // The default hover colors of the mode active are functions
      // (core.defaults.js), so each bar resolves element options of its own
      // (core.datasetController.js:823) and keeps its own resolution.
      expect(run.hits, 0);
    });

    testWidgets('a hovered bar', (tester) async {
      final run = await _twins(
        _bar(),
        change: (chart) {
          chart.setActiveElements([
            const ActiveElement(datasetIndex: 0, index: 3),
          ]);
          _setData(chart, 2);
        },
      );
      // The shared options serve the hovered bar too
      // (controller.bar.js:418), and its context has `active: false` in
      // `updateElement`.
      expect(run.hits, _count - 1);
    });

    testWidgets('a dataset that hides and shows (the hide transition)', (
      tester,
    ) async {
      final hide = await _twins(_stacked, change: (chart) => chart.hide(1));
      expect(hide.hits, greaterThan(0));
      final show = await _twins(
        _stacked,
        change: (chart) {
          chart
            ..setDatasetVisibility(1, false)
            ..update(UpdateMode.none)
            ..show(1);
        },
      );
      expect(show.hits, greaterThan(0));
    });

    testWidgets('dataset animation options for the property y', (tester) async {
      final run = await _twins(
        _bar(
          animation: <String, Object?>{'easing': Curves.linear},
          dataset: <String, Object?>{
            'animations': <String, Object?>{
              'y': <String, Object?>{'duration': 400.0, 'delay': 30.0},
            },
          },
        ),
      );
      expect(run.hits, _count - 1);
    });
  });

  group('the guard declines', () {
    testWidgets('a function at an animation option that reads the bar', (
      tester,
    ) async {
      final run = await _run(
        _bar(
          animation: <String, Object?>{
            'delay': (Object? context, Object? options) =>
                switch (jsGet(context, 'dataIndex')) {
                  final num index => index * 3.0,
                  _ => 0.0,
                },
          },
        ),
        twin: false,
      );
      expect(run.hits, 0);
      // The delay differs by bar: the start times are not all equal.
      expect(run.running.split(';').toSet().length, greaterThan(1));
      final starts = {
        for (final bar in run.running.split(';'))
          bar.split(',').first.split(':')[4],
      };
      expect(starts.length, greaterThan(_count ~/ 2));
    });

    testWidgets('a color for each bar (element options of each bar)', (
      tester,
    ) async {
      final run = await _twins(
        _bar(
          dataset: <String, Object?>{
            'backgroundColor': <Object?>[
              const ChartPaint.solid(Color(0xffff0000)),
              const ChartPaint.solid(Color(0xff00ff00)),
              const ChartPaint.solid(Color(0xff0000ff)),
            ],
          },
        ),
      );
      expect(run.hits, 0);
    });

    testWidgets('a subclass of the controller', (tester) async {
      Chart.register([_SubBarController.jsClass]);
      addTearDown(() => Chart.unregister([_SubBarController.jsClass]));
      final run = await _run(
        (log, {required twin}) =>
            _bar()(log, twin: twin)..['type'] = _SubBarController.id,
        twin: false,
      );
      expect(run.hits, 0);
    });

    testWidgets('animation false: one Animations object with no options', (
      tester,
    ) async {
      final log = <String>[];
      final config = _bar()(log, twin: false);
      (config['options']! as Map<String, Object?>)['animation'] = false;
      final chart = acquireChart(config);
      final hits = debugSharedBarAnimationHits;
      _newData(chart);
      // With `animation: false`, the fast loop of Chart.js ADR 0152 writes
      // each bar after the first one, so the shared plan gives no bar.
      expect(debugSharedBarAnimationHits - hits, 0);
      expect(animator.running(chart), isFalse);
      final twin = acquireChart(_bar()(log, twin: false))
        ..update(UpdateMode.none);
      _setData(twin, 2, UpdateMode.none);
      expect(_geometry(chart), _geometry(twin));
      // Upstream makes no context when the option `animation` is false
      // (core.datasetController.js:849), and the shared path makes none.
      expect(_contexts(chart), isEmpty);
    });
  });

  group('the count of the guard', () {
    testWidgets('a scriptable option adds one, a plain option adds none', (
      tester,
    ) async {
      final chart = acquireChart(
        _bar(
          animation: <String, Object?>{
            'delay': (Object? context, Object? options) => 0.0,
          },
        )(<String>[], twin: false),
      );
      final controller = chart.getDatasetMeta(0).controller!;
      final before = optionCallEpoch;
      final animations = controller.resolveAnimations(2, 'default');
      expect(optionCallEpoch, greaterThan(before));
      expect(animations.holdsPlainValues, isTrue);
      final plain = acquireChart(_bar()(<String>[], twin: false));
      final plainController = plain.getDatasetMeta(0).controller!;
      final start = optionCallEpoch;
      plainController.resolveAnimations(2, 'default');
      expect(optionCallEpoch, start);
    });

    testWidgets('the cancel of an active animation adds one', (tester) async {
      final target = <String, Object?>{'value': 0.0};
      final animation = Animation(
        animationSpecOf(<String, Object?>{'duration': 1000.0}),
        target,
        'value',
        10.0,
      );
      final before = optionCallEpoch;
      animation.cancel();
      expect(optionCallEpoch, before + 1);
      // An animation that does not run adds none.
      animation.cancel();
      expect(optionCallEpoch, before + 1);
    });

    test('an option value that is an object is not plain', () {
      final chart = _FakeChart();
      final plain = Animations(chart, <String, Object?>{
        'y': <String, Object?>{'duration': 100.0, 'from': 0.0},
      });
      expect(plain.holdsPlainValues, isTrue);
      final object = Animations(chart, <String, Object?>{
        'y': <String, Object?>{
          'duration': 100.0,
          'to': <String, Object?>{'a': 1.0},
        },
      });
      expect(object.holdsPlainValues, isFalse);
      final list = Animations(chart, <String, Object?>{
        'y': <String, Object?>{
          'duration': 100.0,
          'from': <Object?>[
            <String, Object?>{'a': 1.0},
          ],
        },
      });
      expect(list.holdsPlainValues, isFalse);
      final key = Animations(chart, <String, Object?>{
        'y': <String, Object?>{
          'duration': 100.0,
          'properties': <Object?>[1.0],
        },
      });
      expect(key.holdsPlainValues, isFalse);
    });
  });
}

/// A subclass of [BarController] with its own id.
final class _SubBarController(
  super.chart,
  super.datasetIndex, [
  super.newTarget,
]) extends BarController {
  static const String id = 'subbar';

  static final JsClass jsClass = JsClass(
    'SubBarController',
    superclass: BarController.jsClass,
    statics: {
      'id': id,
      'defaults': BarController.defaults,
      'overrides': BarController.overrides,
    },
    construct: (newTarget, args) =>
        _SubBarController(args[0]! as types.Chart, args[1]! as int, newTarget),
  );
}

/// A chart for [Animations]: its members throw.
final class _FakeChart() implements types.Chart {
  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
