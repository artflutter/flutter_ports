// Original code, not ported from Chart.js: the bulk point loop of ADR 0166.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

const _red = ChartPaint.solid(ui.Color(0xffff0000));
const _blue = ChartPaint.solid(ui.Color(0xff0000ff));

/// A subclass of the scatter controller: its loop takes no bulk run.
class _SubScatter(super.chart, super.datasetIndex, [super.newTarget])
    extends ScatterController {
  static final JsClass value = JsClass(
    'BulkSubScatter',
    superclass: ScatterController.jsClass,
    statics: {
      'id': 'bulkSubScatter',
      'defaults': ScatterController.defaults,
      'overrides': ScatterController.overrides,
    },
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _SubScatter(chart, datasetIndex, newTarget);
    },
  );
}

/// A map item whose reads are user code: it logs each key that it gives.
class _LoggedMap(final Map<String, Object?> fields, final List<Object?> log)
    extends MapBase<String, Object?> {
  @override
  Object? operator [](Object? key) {
    log.add(key);
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

/// The values of the points: steps of 1 and 3, a null value, a NaN, values
/// out of the axis range and int values.
const List<(num, num?)> _values = [
  (0, 3),
  (1, 5),
  (4, 2),
  (5, null),
  (6, 4),
  (9, 1),
  (10, 6),
  (11, double.nan),
  (12, 40),
  (13, -9),
  (14, 7.25),
  (15.5, 3),
  (16, 2),
  (17, 8),
];

Object? _item(String form, (num, num?) point, {double shift = 0}) {
  final (x, y) = point;
  return switch (form) {
    'point' => DataPoint(x + shift, y),
    'int' => <String, Object?>{'x': x.toInt(), 'y': y?.toInt()},
    _ => <String, Object?>{'x': x.toDouble() + shift, 'y': y?.toDouble()},
  };
}

List<Object?> _data(String form, {double shift = 0}) => <Object?>[
  for (final p in _values)
    if (!(form == 'int' && p.$2 is double && p.$2!.isNaN))
      _item(form, p, shift: shift),
];

Map<String, Object?> _config({
  String type = 'scatter',
  String form = 'parsed',
  Object? spanGaps,
  Map<String, Object?> dataset = const {},
  Map<String, Object?> x = const {},
  Map<String, Object?> y = const {},
  Object animation = false,
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'data': _data(form),
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
    if (form != 'parsed') 'parsing': false,
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
    'scales': <String, Object?>{
      'x': <String, Object?>{'type': 'linear', 'min': -1, 'max': 18, ...x},
      'y': <String, Object?>{'type': 'linear', 'min': -1, 'max': 10, ...y},
    },
  },
};

Map<String, Object?> _dataset(Map<String, Object?> cfg) =>
    (jsGet(cfg['data'], 'datasets')! as List<Object?>)[0]!
        as Map<String, Object?>;

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
  final objects = <int>{};
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

/// One chart with the bulk runs and one without. [config] makes new objects
/// at each call. [steps] runs on each chart after its construction. The
/// result has the observations and the counts of the chart with the bulk
/// runs.
({int bulk, int gaps, List<Object?> observed}) _twins(
  Map<String, Object?> Function() config, [
  void Function(Chart chart, Map<String, Object?> cfg)? steps,
]) {
  final observed = <List<Object?>>[];
  final gapCounts = <int>[];
  final saved = bulkPointUpdatesEnabled;
  addTearDown(() => bulkPointUpdatesEnabled = saved);
  var bulk = 0;
  for (final enabled in [true, false]) {
    bulkPointUpdatesEnabled = enabled;
    final bulkBefore = bulkPointUpdatesTaken;
    final gapsBefore = nativeGapReadsTaken;
    final cfg = config();
    final chart = Chart(UiCanvasElement(width: 400, height: 300), cfg);
    addTearDown(chart.destroy);
    (steps ?? _newData)(chart, cfg);
    if (enabled) {
      bulk = bulkPointUpdatesTaken - bulkBefore;
    } else {
      expect(bulkPointUpdatesTaken, bulkBefore, reason: 'the switch is off');
    }
    gapCounts.add(nativeGapReadsTaken - gapsBefore);
    observed.add(_observe(chart));
  }
  bulkPointUpdatesEnabled = saved;
  expect(observed[0], observed[1], reason: 'the twins differ');
  expect(gapCounts[0], gapCounts[1], reason: 'the gap tests differ');
  return (bulk: bulk, gaps: gapCounts[0], observed: observed[0]);
}

void _newData(Chart chart, Map<String, Object?> cfg) {
  final form = cfg['options']! as Map<String, Object?>;
  final parsing = form['parsing'];
  final data = _dataset(cfg)['data']! as List<Object?>;
  final kind = parsing == false
      ? (data.first is DataPoint
            ? 'point'
            : ((data.first! as Map)['x'] is int ? 'int' : 'map'))
      : 'parsed';
  _dataset(cfg)['data'] = _data(kind, shift: kind == 'int' ? 0 : 0.5);
  chart.update(UpdateMode.none);
}

void main() {
  Chart.register([_SubScatter.value]);
  registerDataUpdateTypes([<DataPoint>[].runtimeType], [DataPoint]);

  group('the bulk run and its twin', () {
    for (final form in ['parsed', 'map', 'int', 'point']) {
      testWidgets('$form items: NaN, null and values out of range', (
        tester,
      ) async {
        final counts = _twins(() => _config(form: form));
        expect(counts.bulk, greaterThan(0));
      });
    }

    testWidgets('a finite spanGaps gives the same stops', (tester) async {
      final counts = _twins(() => _config(spanGaps: 2));
      expect(counts.bulk, greaterThan(0));
      final stops = [for (final p in counts.observed) (p! as List)[3]];
      expect(stops, contains(true));
    });

    testWidgets('reversed and offset scales', (tester) async {
      final counts = _twins(
        () => _config(
          x: <String, Object?>{'reverse': true, 'offset': true},
          y: <String, Object?>{'reverse': true, 'min': 2.5, 'max': 7},
        ),
      );
      expect(counts.bulk, greaterThan(0));
    });

    testWidgets('pixels aligned to the device pixels', (tester) async {
      final counts = _twins(
        () => _config(
          x: <String, Object?>{'alignToPixels': true},
          y: <String, Object?>{'alignToPixels': true},
        ),
      );
      expect(counts.bulk, greaterThan(0));
    });

    testWidgets('an active point in the middle', (tester) async {
      final counts = _twins(_config, (chart, cfg) {
        chart
          ..setActiveElements([const ActiveElement(datasetIndex: 0, index: 6)])
          ..update(UpdateMode.none);
        _newData(chart, cfg);
      });
      expect(counts.bulk, greaterThan(0));
      expect((counts.observed[6]! as List)[4], isTrue);
    });

    testWidgets('a subclass takes no bulk run', (tester) async {
      final counts = _twins(() => _config(type: 'bulkSubScatter'));
      expect(counts.bulk, 0);
    });

    testWidgets('a scriptable option takes no bulk run', (tester) async {
      final counts = _twins(
        () => _config(
          dataset: <String, Object?>{
            'pointRadius': (Object? ctx, Object? _) =>
                3.0 + (jsGet(ctx, 'dataIndex')! as int) % 3,
          },
        ),
      );
      expect(counts.bulk, 0);
    });

    testWidgets('an update with the option animation', (tester) async {
      // A chart with no host disables its animations: each loop is direct.
      final counts = _twins(
        () => _config(animation: <String, Object?>{'duration': 100}),
        (chart, cfg) {
          _dataset(cfg)['data'] = _data('parsed', shift: 0.5);
          chart
            ..update()
            ..stop();
        },
      );
      expect(counts.bulk, greaterThan(0));
    });

    testWidgets('a value that is not a number ends the run', (tester) async {
      // Map items of one class: the item test of the run passes them by their
      // class, so the run tests each value. A string y is not `null`: upstream
      // takes the pixel of its number, not the base pixel.
      final counts = _twins(() {
        final cfg = _config(form: 'map', spanGaps: 2);
        final data = _dataset(cfg)['data']! as List<Object?>;
        data[8] = <String, Object?>{'x': 12.0, 'y': '5'};
        data[10] = <String, Object?>{'x': '14', 'y': 7.25};
        return cfg;
      }, (chart, cfg) => chart.update(UpdateMode.none));
      expect(counts.bulk, greaterThan(0));
      final skip8 = (counts.observed[8]! as List)[2];
      expect(skip8, isFalse, reason: 'the string y is not null data');
    });

    testWidgets('a user map item keeps each of its reads', (tester) async {
      final logs = <List<Object?>>[];
      final counts = _twins(
        () {
          final log = <Object?>[];
          logs.add(log);
          final cfg = _config(form: 'map');
          final data = _dataset(cfg)['data']! as List<Object?>;
          data[8] = _LoggedMap({...data[8]! as Map<String, Object?>}, log);
          return cfg;
        },
        (chart, cfg) {
          logs.last.clear();
          chart.update(UpdateMode.none);
        },
      );
      expect(counts.bulk, greaterThan(0));
      expect(logs[0], logs[1]);
      expect(logs[0], isNotEmpty);
    });
  });
}
