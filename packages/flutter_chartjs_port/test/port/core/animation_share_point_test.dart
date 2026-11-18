// Original code, not ported from Chart.js: shared point animation options.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:clock/clock.dart';
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/core/animation_share.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart' as core;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

// `ScatterController.update` with one resolution of the animation options
// for its points (`lib/src/core/animation_share.dart`, row
// `adapt-shared-point-animations`, Chart.js ADR 0160). The twin of each run
// has the same config with a function at `animation.delay` that gives the
// default value `undefined`: the guard declines it, so each point of the twin
// takes the ordinary resolution of upstream. Both runs must give the same
// positions and options in each frame, the same animation events, the same
// `$animations` entries of the points and of their options, the same
// contexts and the same count of animator items.

/// The count of the points of each dataset of this file.
const int _count = 40;

List<Object?> _data(int seed) => [
  for (var i = 0; i < _count; i++)
    <String, Object?>{
      'x': (i * 2.5 + seed) % 100,
      'y': 5.0 + ((i * 37 + seed * 11) % 90),
    },
];

/// The option `animation.delay` of a twin: a function that gives the
/// default value, `undefined`.
Object? _twinDelay(Object? context, Object? options) => undefined;

/// A chart config. [twin] puts the function of [_twinDelay] at
/// `animation.delay`.
typedef _Config = Map<String, Object?> Function(
  List<String> log, {
  required bool twin,
});

/// A scatter chart of [datasets] datasets with the default animations and
/// fixed value ranges. [animation] adds keys to the `animation` options, and
/// [dataset] adds dataset keys.
_Config _scatter({
  Map<String, Object?>? animation,
  Map<String, Object?>? dataset,
  int datasets = 1,
  String type = 'scatter',
}) =>
    (log, {required twin}) => <String, Object?>{
      'type': type,
      'data': <String, Object?>{
        'datasets': <Object?>[
          for (var d = 0; d < datasets; d++)
            <String, Object?>{'data': _data(1 + d * 4), ...?dataset},
        ],
      },
      'options': <String, Object?>{
        'animation': <String, Object?>{
          'onProgress': (AnimationEvent event) =>
              log.add('progress ${event.currentStep} of ${event.numSteps}'),
          'onComplete': (AnimationEvent event) =>
              log.add('complete ${event.currentStep} of ${event.numSteps}'),
          if (twin) 'delay': _twinDelay,
          ...?animation,
        },
        'scales': <String, Object?>{
          'x': <String, Object?>{'min': 0.0, 'max': 100.0},
          'y': <String, Object?>{'min': 0.0, 'max': 100.0},
        },
      },
    };

List<core.Element> _points(Chart chart) => [
  for (
    var i = 0;
    i < (jsGet(chart.data, 'datasets')! as List<Object?>).length;
    i++
  )
    ...chart.getDatasetMeta(i).data.cast<core.Element>(),
];

const List<String> _optionNames = [
  'radius',
  'borderWidth',
  'backgroundColor',
  'borderColor',
];

/// The position, `skip` and the animated options of each point.
String _geometry(Chart chart) => [
  for (final point in _points(chart))
    [
      for (final name in const ['x', 'y', 'skip']) point[name],
      for (final name in _optionNames) jsGet(point['options'], name),
    ].join(','),
].join(';');

String _entries(Map<String, Object?>? animations, double date) => [
  for (final MapEntry(:key, :value)
      in (animations ?? const <String, Object?>{}).entries)
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
].join(',');

/// The `$animations` entries of each point and of its options, with the
/// start relative to [date].
String _running(Chart chart, double date) => [
  for (final point in _points(chart))
    [
      _entries(point.$animations, date),
      if (jsGet(point['options'], r'$animations')
          case final Map<String, Object?> options)
        _entries(options, date),
    ].join('|'),
].join(';');

/// The context of each point: the keys that the shared path writes.
String _contexts(Chart chart) => [
  for (final point in _points(chart))
    if (point.$context case final Object context)
      [
        for (final name in const ['index', 'dataIndex', 'active', 'mode'])
          jsGet(context, name),
        jsGet(jsGet(context, 'parsed'), 'y'),
      ].join(','),
].join(';');

typedef _Run = ({
  List<String> frames,
  String running,
  String contexts,
  int items,
  int hits,
});

/// Makes the chart of [config], waits for the end of its first animations,
/// applies [change] and pumps frames until the animations end. [live] runs
/// at the frames 3 and 5 and updates the chart again while the animations
/// run.
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
  expect(twin.hits, 0, reason: 'the guard declines each point of the twin');
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
    (datasets[i]! as Map<String, Object?>)['data'] = _data(seed + i * 4);
  }
  chart.update(mode);
}

void Function(Chart chart) _liveData() {
  var seed = 2;
  return (chart) => _setData(chart, ++seed);
}

void main() {
  group('the shared path and its twin', () {
    testWidgets('new data: one resolution for the points of an update', (
      tester,
    ) async {
      final run = await _twins(_scatter());
      expect(run.hits, _count - 1);
      expect(run.frames.length, greaterThan(10));
      expect(run.frames.join(), contains('complete'));
    });

    testWidgets('two datasets', (tester) async {
      final run = await _twins(_scatter(datasets: 2));
      expect(run.hits, 2 * (_count - 1));
    });

    testWidgets('a live chart: updates while the animations run', (
      tester,
    ) async {
      final run = await _twins(_scatter(), live: _liveData);
      expect(run.hits, 3 * (_count - 1));
      expect(run.frames.where((line) => line.startsWith('live')).length, 2);
    });

    testWidgets('new options: the point options animate', (tester) async {
      final run = await _twins(
        _scatter(),
        change: (chart) {
          (jsGet(chart.data, 'datasets')! as List<Object?>)[0]!
                as Map<String, Object?>
            ..['radius'] = 9.0
            ..['borderWidth'] = 3.0
            ..['backgroundColor'] = const ChartPaint.solid(Color(0xff3366cc));
          _setData(chart, 2);
        },
      );
      expect(run.hits, _count - 1);
      expect(run.running, contains('radius'));
    });

    testWidgets('a line with the points (showLine)', (tester) async {
      final run = await _twins(
        _scatter(dataset: <String, Object?>{'showLine': true}),
      );
      expect(run.hits, _count - 1);
    });

    testWidgets('an update with equal data and the mode resize', (
      tester,
    ) async {
      final equal = await _twins(_scatter(), change: (chart) => chart.update());
      expect(equal.hits, _count - 1);
      final resize = await _twins(
        _scatter(),
        change: (chart) => _setData(chart, 2, UpdateMode.resize),
      );
      expect(resize.hits, _count - 1);
    });

    testWidgets('a hovered point', (tester) async {
      final run = await _twins(
        _scatter(),
        change: (chart) {
          chart.setActiveElements([
            const ActiveElement(datasetIndex: 0, index: 3),
          ]);
          _setData(chart, 2);
        },
      );
      // The hovered point resolves its options in the mode active, whose
      // default hover colors are functions: it and the next point take the
      // ordinary resolution.
      expect(run.hits, greaterThan(_count - 4));
    });

    testWidgets('a dataset that hides and shows', (tester) async {
      final hide = await _twins(
        _scatter(datasets: 2),
        change: (chart) => chart.hide(1),
      );
      expect(hide.hits, greaterThan(0));
      final show = await _twins(
        _scatter(datasets: 2),
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
        _scatter(
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
    testWidgets('a function at an animation option that reads the point', (
      tester,
    ) async {
      final run = await _run(
        _scatter(
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
      final starts = {
        for (final point in run.running.split(';'))
          point.split(',').first.split(':')[4],
      };
      expect(starts.length, greaterThan(_count ~/ 2));
    });

    testWidgets('a scriptable radius that changes the animation options', (
      tester,
    ) async {
      // App code in the loop: in the second update, the radius of point 10
      // writes the animation option `duration` of the dataset. Each call of
      // the function adds one to the count, so each point takes the ordinary
      // resolution. The resolver of the config caches the first read of an
      // update (config.js `createResolver`), so upstream and the twin keep
      // the old duration for each point of that update.
      var armed = false;
      var updates = 0;
      Map<String, Object?> config(List<String> log, {required bool twin}) {
        final config = _scatter()(log, twin: twin);
        final animation = <String, Object?>{'delay': 0.0};
        final dataset = <String, Object?>{
          'data': _data(1),
          'animation': animation,
          'radius': (Object? context, Object? options) {
            if (armed && jsGet(context, 'dataIndex') == 10) {
              animation['duration'] = 300.0;
            }
            return 3.0;
          },
        };
        (config['data']! as Map<String, Object?>)['datasets'] = <Object?>[
          dataset,
        ];
        // The loop of the dataset update only: `getMaxOverflow` resolves the
        // options of each point before it.
        config['plugins'] = <Plugin<Object?>>[
          Plugin<Object?>(
            id: 'arm',
            beforeDatasetUpdate: (_, _, _) {
              armed = updates == 1;
              return true;
            },
            afterDatasetUpdate: (_, _, _) => armed = false,
          ),
        ];
        return config;
      }

      final run = await _twins(
        config,
        change: (chart) {
          updates = 1;
          _newData(chart);
          updates = 0;
        },
      );
      expect(run.hits, 0);
      final durations = [
        for (final point in run.running.split(';'))
          point.split('|').first.split(',').first.split(':')[5],
      ];
      expect(durations.toSet(), {'1000.0'});
    });

    testWidgets('a subclass of the controller', (tester) async {
      Chart.register([_SubScatterController.jsClass]);
      addTearDown(() => Chart.unregister([_SubScatterController.jsClass]));
      final run = await _run(
        _scatter(type: _SubScatterController.id),
        twin: false,
      );
      expect(run.hits, 0);
    });

    testWidgets('a logarithmic axis', (tester) async {
      final run = await _twins((log, {required twin}) {
        final config = _scatter()(log, twin: twin);
        final scales =
            (config['options']! as Map<String, Object?>)['scales']!
                as Map<String, Object?>;
        scales['y'] = <String, Object?>{'type': 'logarithmic'};
        return config;
      });
      expect(run.hits, 0);
    });
  });
}

/// A subclass of [ScatterController] with its own id.
final class _SubScatterController(
  super.chart,
  super.datasetIndex, [
  super.newTarget,
]) extends ScatterController {
  static const String id = 'subscatter';

  static final JsClass jsClass = JsClass(
    'SubScatterController',
    superclass: ScatterController.jsClass,
    statics: {
      'id': id,
      'defaults': ScatterController.defaults,
      'overrides': ScatterController.overrides,
    },
    construct: (newTarget, args) => _SubScatterController(
      args[0]! as types.Chart,
      args[1]! as int,
      newTarget,
    ),
  );
}
