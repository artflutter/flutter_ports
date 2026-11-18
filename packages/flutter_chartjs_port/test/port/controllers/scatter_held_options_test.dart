// Original code, not ported from Chart.js: the held options of ADR 0165.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show heldElementOptionsEnabled, heldElementOptionsTaken;
import 'package:flutter_chartjs_port/src/core/point_options.dart'
    show nativeGapReadsTaken;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/options/element_options_base.dart';
import 'package:flutter_test/flutter_test.dart';

const _red = ChartPaint.solid(ui.Color(0xffff0000));
const _blue = ChartPaint.solid(ui.Color(0xff0000ff));

/// A subclass of the scatter controller: its loop keeps the ordinary call.
class _SubScatter(super.chart, super.datasetIndex, [super.newTarget])
    extends ScatterController {
  static final JsClass value = JsClass(
    'HeldSubScatter',
    superclass: ScatterController.jsClass,
    statics: {
      'id': 'heldSubScatter',
      'defaults': ScatterController.defaults,
      'overrides': ScatterController.overrides,
    },
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _SubScatter(chart, datasetIndex, newTarget);
    },
  );
}

List<Object?> _data(int n, {double shift = 0}) => <Object?>[
  for (var i = 0; i < n; i++)
    <String, Object?>{
      'x': i * 1.0 + shift,
      'y': i.isEven ? (i * 7 % 13) * 1.0 : null,
    },
];

Map<String, Object?> _config({
  String type = 'scatter',
  Object animation = false,
  Map<String, Object?> dataset = const {},
  Object? spanGaps,
  int n = 12,
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': _data(n),
        'pointRadius': 3,
        'pointBackgroundColor': _red,
        'pointHoverBackgroundColor': _blue,
        'spanGaps': ?spanGaps,
        ...dataset,
      },
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'animation': animation,
    'events': <String>[],
    'parsing': false,
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
    'scales': <String, Object?>{
      'x': <String, Object?>{'type': 'linear', 'min': -1, 'max': 20},
      'y': <String, Object?>{'type': 'linear', 'min': -1, 'max': 20},
    },
  },
};

/// Each option key and value of [options], as text.
List<String> _options(Object? options) {
  final face = options! as ElementOptions;
  return [for (final key in face.jsKeys()) '$key=${jsGet(face, key)}'];
}

/// The written properties of each point: x, y, skip, stop, active, the
/// options and the context; and whether each point has an options object of
/// its own.
List<Object?> _observe(Chart chart) {
  final points = chart.getDatasetMeta(0).data.cast<PointElement>();
  final objects = <Object?>{};
  for (final p in points) {
    expect(
      objects.add(identityHashCode(p.options)),
      isTrue,
      reason: 'a shared options object',
    );
  }
  return [
    for (final p in points)
      [
        '${p.x}',
        '${p.y}',
        p.skip,
        p.stop,
        p.active,
        ..._options(p.options),
        p.$context?.jsKeys(),
        for (final key in ['index', 'dataIndex', 'mode', 'active'])
          p.$context?.jsRead(key),
      ],
  ];
}

Map<String, Object?> _dataset(Map<String, Object?> cfg) =>
    ((cfg['data']! as Map<String, Object?>)['datasets']! as List<Object?>)[0]!
        as Map<String, Object?>;

/// One chart with the held entry and one without. [config] makes new objects
/// at each call. [steps] runs on each chart after its construction. The result
/// has the observations and the counts of the chart with the held entry.
({int held, int gaps}) _twins(
  Map<String, Object?> Function() config,
  void Function(Chart chart, Map<String, Object?> cfg) steps, {
  void Function(Chart chart)? end,
}) {
  final observed = <List<Object?>>[];
  final saved = heldElementOptionsEnabled;
  addTearDown(() => heldElementOptionsEnabled = saved);
  var held = 0;
  var gaps = 0;
  for (final enabled in [true, false]) {
    heldElementOptionsEnabled = enabled;
    final heldBefore = heldElementOptionsTaken;
    final gapsBefore = nativeGapReadsTaken;
    final cfg = config();
    final chart = Chart(UiCanvasElement(width: 400, height: 300), cfg);
    addTearDown(chart.destroy);
    steps(chart, cfg);
    end?.call(chart);
    if (enabled) {
      held = heldElementOptionsTaken - heldBefore;
      gaps = nativeGapReadsTaken - gapsBefore;
    } else {
      expect(heldElementOptionsTaken, heldBefore, reason: 'the switch is off');
    }
    observed.add(_observe(chart));
  }
  heldElementOptionsEnabled = saved;
  expect(observed[0], observed[1], reason: 'the twins differ');
  return (held: held, gaps: gaps);
}

/// A map item whose read of `x` runs [onX]: user code between two option
/// calls of the loop.
class _HookItem(final Map<String, Object?> fields, final void Function() onX)
    extends MapBase<String, Object?> {
  @override
  Object? operator [](Object? key) {
    if (key == 'x') onX();
    return fields[key];
  }

  @override
  void operator []=(String key, Object? value) => fields[key] = value;
  @override
  Iterable<String> get keys => fields.keys;
  @override
  Object? remove(Object? key) => fields.remove(key);
  @override
  void clear() => fields.clear();
}

/// The data of [_data] as [_HookItem]s: the read of `x` of the item [at] runs
/// [onX] while [armed] gives true.
List<Object?> _hookData(int at, bool Function() armed, void Function() onX) => [
  for (final (i, item) in _data(12).indexed)
    _HookItem(item! as Map<String, Object?>, () {
      if (i == at && armed()) onX();
    }),
];

void _newData(Chart chart, Map<String, Object?> cfg) {
  _dataset(cfg)['data'] = _data(12, shift: 0.5);
  chart.update(UpdateMode.none);
}

void main() {
  Chart.register([_SubScatter.value]);

  group('the held entry and its twin', () {
    testWidgets('mode none: each point after the first takes the entry', (
      tester,
    ) async {
      final counts = _twins(_config, _newData);
      // The construction (mode default) and the update: 11 points each.
      expect(counts.held, 22);
    });

    testWidgets('the gap test takes the x of the previous point', (
      tester,
    ) async {
      final counts = _twins(() => _config(spanGaps: 2), _newData);
      expect(counts.held, 22);
      expect(counts.gaps, greaterThan(0));
    });

    testWidgets('a hovered point in the middle reads the active entry', (
      tester,
    ) async {
      final counts = _twins(_config, (chart, cfg) {
        chart
          ..setActiveElements([const ActiveElement(datasetIndex: 0, index: 5)])
          ..update(UpdateMode.none);
        _newData(chart, cfg);
      });
      // The active point and the point after it read the cache again; the
      // first active read writes the entry of `active`.
      expect(counts.held, greaterThan(0));
    });

    testWidgets('an animated update takes the entry of its mode', (
      tester,
    ) async {
      final counts = _twins(
        () => _config(animation: <String, Object?>{'duration': 100}),
        (chart, cfg) {
          _dataset(cfg)['data'] = _data(12, shift: 0.5);
          chart.update();
        },
        end: (chart) => chart.stop(),
      );
      expect(counts.held, greaterThan(0));
    });

    testWidgets('a scriptable option makes no entry', (tester) async {
      var calls = 0;
      final counts = _twins(
        () => _config(
          dataset: <String, Object?>{
            'pointRadius': (Object? ctx, Object? _) {
              calls++;
              return 3.0 + (jsGet(ctx, 'dataIndex')! as int) % 3;
            },
          },
        ),
        _newData,
      );
      expect(counts.held, 0);
      expect(calls, greaterThan(0));
    });

    testWidgets('a subclass keeps the ordinary call', (tester) async {
      final counts = _twins(() => _config(type: 'heldSubScatter'), _newData);
      expect(counts.held, 0);
    });

    testWidgets('a new entry inside the loop ends the hold', (tester) async {
      // The options of the dataset change between two updates: the
      // configure of the update clears the cache, and the first point of the
      // next loop reads it again.
      final counts = _twins(_config, (chart, cfg) {
        chart.update(UpdateMode.none);
        _dataset(cfg)['pointRadius'] = 5;
        chart.update(UpdateMode.none);
      });
      expect(counts.held, 33);
    });
  });

  group('user code between two calls of the loop', () {
    // Each case arms a hook in the read of `x` of one item for one update in
    // the mode `none`. The hook runs inside the loop, between the option calls
    // of two points: each later point must read the cache as upstream does.
    late Chart chart;
    var armed = false;
    void update(Chart c, Map<String, Object?> cfg) {
      chart = c;
      armed = true;
      c.update(UpdateMode.none);
      armed = false;
    }

    testWidgets('a clear of the cache ends the hold', (tester) async {
      late Map<String, Object?> dataset;
      final counts = _twins(() {
        final cfg = _config(
          dataset: <String, Object?>{
            'data': _hookData(6, () => armed, () {
              armed = false;
              dataset['pointRadius'] = 6;
              chart.getDatasetMeta(0).controller!.configure();
            }),
          },
        );
        dataset = _dataset(cfg);
        return cfg;
      }, update);
      expect(counts.held, greaterThan(0));
    });

    testWidgets('a new data element type ends the hold', (tester) async {
      final counts = _twins(
        () => _config(
          dataset: <String, Object?>{
            'data': _hookData(6, () => armed, () {
              armed = false;
              chart.getDatasetMeta(0).controller!.dataElementType =
                  ArcElement.jsClass;
            }),
          },
        ),
        update,
      );
      expect(counts.held, greaterThan(0));
    });

    testWidgets('an active point reads the entry of its mode', (tester) async {
      // The hook reads the options of the active point inside the loop,
      // before the hover styles of the update write them again: the reads of
      // each twin.
      final seen = <List<Object?>>[];
      final counts = _twins(
        () => _config(
          dataset: <String, Object?>{
            'data': _hookData(8, () => armed, () {
              final options = chart.getDatasetMeta(0).data[5].options;
              seen.last.add(_options(options));
            }),
          },
        ),
        (c, cfg) {
          seen.add([]);
          c.setActiveElements([const ActiveElement(datasetIndex: 0, index: 5)]);
          update(c, cfg);
        },
      );
      expect(counts.held, greaterThan(0));
      expect(seen, hasLength(2));
      expect(seen[0], isNotEmpty);
      expect(seen[0], seen[1]);
    });
  });
}
