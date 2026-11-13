// Original code, not ported from Chart.js: the gap reads of Chart.js ADR 0109.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show scaleCfgArg;
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show registerDataUpdateTypes;
import 'package:flutter_chartjs_port/src/core/point_option_preparation.dart'
    show prepareNativeGapReads;
import 'package:flutter_chartjs_port/src/core/point_options.dart'
    show NativeGapReads, nativeGapReadsEnabled, nativeGapReadsTaken;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/options/parsed.dart' show ParsedItem;
import 'package:flutter_chartjs_port/src/typed/datasets.dart' show DataPoint;
import 'package:flutter_test/flutter_test.dart';

/// The x values of `gapData` of tool/reference/controller_line_reference.mjs:
/// the steps 1, 3, 1, 1, 3 and 1, with the value `null` at the index 3.
const List<(num, num?)> _points = [
  (0, 3),
  (1, 5),
  (4, 2),
  (5, null),
  (6, 4),
  (9, 1),
  (10, 6),
];

/// A data item of the [form] `parsed` (a plain Map that the parse turns into
/// a [ParsedItem]), `map` (a plain Map with `parsing: false`), `int` (as
/// `map` with `int` x values) or `point` (a [DataPoint]).
Object? _item(String form, (num, num?) point) {
  final (x, y) = point;
  return switch (form) {
    'point' => DataPoint(x, y),
    'int' => <String, Object?>{'x': x.toInt(), 'y': y},
    _ => <String, Object?>{'x': x.toDouble(), 'y': y?.toDouble()},
  };
}

Map<String, Object?> _config(
  String type, {
  String form = 'parsed',
  Object? spanGaps = undefined,
  List<Object?>? data,
  Map<String, Object?> dataset = const {},
  Map<String, Object?> x = const {'type': 'linear'},
  Map<String, Object?> y = const {'type': 'linear'},
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    if (x['type'] == 'category')
      'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f', 'g'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': data ?? <Object?>[for (final p in _points) _item(form, p)],
        if (!identical(spanGaps, undefined)) 'spanGaps': spanGaps,
        ...dataset,
      },
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'animation': false,
    'events': <String>[],
    if (form != 'parsed') 'parsing': false,
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
    'scales': <String, Object?>{
      'x': <String, Object?>{...x},
      'y': <String, Object?>{...y},
    },
  },
};

/// The point properties that the loop writes: x, y, skip and stop.
List<Object?> _observe(Chart chart) => [
  for (final p in chart.getDatasetMeta(0).data.cast<PointElement>())
    ['${p.x}', '${p.y}', p.skip, p.stop],
];

/// The stop flags of the points of [chart].
List<bool?> _stops(Chart chart) => [
  for (final p in chart.getDatasetMeta(0).data.cast<PointElement>()) p.stop,
];

/// The twins of a config: one chart with the gap reads and one with each
/// read of `prevParsed[iAxis]`. [config] makes new objects at each call.
/// Each chart runs its construction and one `update('none')`; [before]
/// runs before that update. The result has the observations of the chart
/// with the gap reads, and the number of gap tests that took a held x in
/// its update.
({List<Object?> observed, int takes, Chart chart}) _twins(
  Map<String, Object?> Function() config, {
  void Function(Chart chart)? before,
}) {
  final observed = <List<Object?>>[];
  final charts = <Chart>[];
  var takes = 0;
  final saved = nativeGapReadsEnabled;
  addTearDown(() => nativeGapReadsEnabled = saved);
  for (final enabled in [true, false]) {
    nativeGapReadsEnabled = enabled;
    final chart = Chart(UiCanvasElement(width: 640, height: 400), config());
    addTearDown(chart.destroy);
    before?.call(chart);
    final start = nativeGapReadsTaken;
    chart.update('none');
    if (enabled) {
      takes = nativeGapReadsTaken - start;
    } else {
      expect(nativeGapReadsTaken, start, reason: 'the switch is off');
    }
    observed.add(_observe(chart));
    charts.add(chart);
  }
  nativeGapReadsEnabled = saved;
  expect(observed[0], observed[1], reason: 'the twins differ');
  return (observed: observed[0], takes: takes, chart: charts[0]);
}

/// A map item whose reads are user code: it logs each key that it gives.
class _LoggedMap extends MapBase<String, Object?> {
  _LoggedMap(this.fields, this.log);
  final Map<String, Object?> fields;
  final List<Object?> log;
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

/// A linear scale of a user class: once [armed], at the pass of the index 2,
/// its `getPixelForValue` writes the x 100 into the item 1 of [data].
class _WritingScale extends LinearScale {
  _WritingScale(super.cfg);

  static List<Object?> data = const [];
  static bool armed = false;

  static final value = JsClass(
    'GapWritingScale',
    superclass: LinearScale.jsClass,
    statics: {'id': 'gap-writing-scale'},
    construct: (_, args) => _WritingScale(scaleCfgArg(args)),
  );

  @override
  double getPixelForValue(Object? value, [double? index]) {
    if (armed && index == 2) {
      armed = false;
      (data[1]! as Map<String, Object?>)['x'] = 100.0;
    }
    return super.getPixelForValue(value, index);
  }
}

/// A y value of a user class: its `ToNumber` (`toString`) is user code that
/// writes the x 1 and 100 in turn into the item 1 of [data].
class _WritingValue {
  _WritingValue(this.data);
  final List<Object?> data;
  var _calls = 0;
  @override
  String toString() {
    (data[1]! as Map<String, Object?>)['x'] = _calls.isEven ? 100.0 : 1.0;
    _calls++;
    return '5';
  }
}

/// A point of a user class: its writes go by name, and its write of `y`
/// calls [onY], user code.
class _UserPoint extends PointElement {
  _UserPoint([this.onY]);
  final void Function()? onY;
  @override
  bool get typedWrites => false;
  @override
  void operator []=(String prop, Object? value) {
    if (prop == 'y') onY?.call();
    super[prop] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerDataUpdateTypes([<DataPoint>[].runtimeType], [DataPoint]);

  const stopsOf1_5 = [false, false, true, false, false, true, false];
  const noStops = [false, false, false, false, false, false, false];

  // Indexed colors: the options of the prepared native plan.
  final indexedColors = <String, Object?>{
    'backgroundColor': <ChartPaint>[
      const ChartPaint.solid(ui.Color(0xffff0000)),
      const ChartPaint.solid(ui.Color(0xff0000ff)),
    ],
  };

  for (final type in ['line', 'scatter']) {
    group('$type:', () {
      // The options that run no user code: the shared options of the line,
      // and the prepared plan of indexed colors of the scatter, whose options
      // are not shared (`enableOptionSharing` is false). The plan comes at
      // the end of the pass 1 of a loop: the passes 0 and 1 resolve each
      // option and hold no x, and the pass 2 takes none.
      final line = type == 'line';
      final options = line ? const <String, Object?>{} : indexedColors;
      int takes(int passes) => line ? passes - 1 : passes - 3;

      // controller.line.js:104 and controller.scatter.js:133. Each item class
      // of the proof and each kind of `spanGaps`: the held x gives the stops
      // of the reads.
      for (final form in ['parsed', 'map', 'int', 'point']) {
        for (final (name, spanGaps, stops) in <(String, Object?, List<bool>)>[
          ('absent', undefined, noStops),
          ('true', true, noStops),
          ('false', false, noStops),
          ('1.5', 1.5, stopsOf1_5),
          ('3', 3, noStops),
          ('2.5', 2.5, stopsOf1_5),
          ("'2'", '2', stopsOf1_5),
        ]) {
          test('$form items, spanGaps $name: the held x', () {
            final twins = _twins(
              () => _config(
                type,
                form: form,
                spanGaps: spanGaps,
                dataset: options,
              ),
            );
            expect(_stops(twins.chart), stops);
            expect(twins.takes, takes(_points.length));
          });
        }
      }

      test('NaN and infinite x values keep the stops of the reads', () {
        final data = [
          (0, 1),
          (double.nan, 2),
          (3, 3),
          (double.infinity, 4),
          (double.negativeInfinity, 5),
          (6, 6),
        ];
        for (final spanGaps in [undefined, 1.5]) {
          final twins = _twins(
            () => _config(
              type,
              form: 'map',
              spanGaps: spanGaps,
              data: [for (final p in data) _item('map', p)],
              dataset: options,
            ),
          );
          expect(twins.takes, takes(data.length));
        }
      });

      test('indexed colors: the passes of the prepared plan hold x', () {
        final twins = _twins(
          () => _config(type, spanGaps: 1.5, dataset: indexedColors),
        );
        expect(_stops(twins.chart), stopsOf1_5);
        // The passes 0 and 1 resolve ordinarily, and the plan comes at the end
        // of the pass 1: the passes 3 to 6 take the x of the pass before.
        expect(twins.takes, _points.length - 3);
      });

      test('options resolved for each point keep the reads', () {
        // A scatter does not share its options; a line with a scriptable
        // radius resolves each point.
        final twins = _twins(
          () => _config(
            type,
            form: 'map',
            spanGaps: 1.5,
            dataset: <String, Object?>{'pointRadius': (Object? ctx) => 3},
          ),
        );
        expect(_stops(twins.chart), stopsOf1_5);
        expect(twins.takes, 0);
        if (!line) {
          expect(_twins(() => _config(type, spanGaps: 1.5)).takes, 0);
        }
      });

      // Chart.js ADR 0036 §8: the pin case `parsed: a scriptable option
      // writes ctx.parsed` of the controller references. Upstream reads the
      // x that the option wrote: the point 2 gets `stop`.
      test('a scriptable option that writes ctx.parsed keeps the read', () {
        double radius(Object? ctx) {
          if (jsGet(ctx, 'dataIndex') == 1) {
            (jsGet(ctx, 'parsed')! as ParsedItem).x = 10.0;
          }
          return 3;
        }

        final twins = _twins(
          () => _config(
            type,
            spanGaps: 1.5,
            data: <Object?>[
              for (var i = 0; i < 4; i++)
                <String, Object?>{'x': i * 1.0, 'y': i + 1.0},
            ],
            dataset: <String, Object?>{'pointRadius': radius},
          ),
        );
        expect(twins.takes, 0);
        expect(_stops(twins.chart)[2], isTrue);
      });

      test('a user scale that writes the previous item keeps the read', () {
        Chart.register([_WritingScale.value]);
        addTearDown(() => Chart.unregister([_WritingScale.value]));
        final twins = _twins(() {
          final cfg = _config(
            type,
            form: 'map',
            spanGaps: 50,
            x: const {'type': 'gap-writing-scale', 'min': 0.0, 'max': 10.0},
          );
          _WritingScale.data =
              ((cfg['data']! as Map<String, Object?>)['datasets']!
                          as List<Object?>)
                      .cast<Map<String, Object?>>()
                      .first['data']!
                  as List<Object?>;
          return cfg;
        }, before: (chart) => _WritingScale.armed = true);
        expect(twins.takes, 0);
        // The read gives the x 100 that the scale wrote in the pass 2 before
        // its gap test: |4 - 100| > 50. The x of the pass 1 gives |4 - 1|.
        expect(_stops(twins.chart), [
          false,
          false,
          true,
          false,
          false,
          false,
          false,
        ]);
      });

      test('a value whose ToNumber runs user code keeps the read', () {
        final twins = _twins(() {
          final data = <Object?>[for (final p in _points) _item('map', p)];
          (data[2]! as Map<String, Object?>)['y'] = _WritingValue(data);
          return _config(
            type,
            form: 'map',
            spanGaps: 50,
            data: data,
            dataset: options,
          );
        });
        // The pass 2 and the pass 3 after it read `prevParsed[iAxis]`. The
        // plan of the scatter ends at the pass 2.
        expect(twins.takes, line ? 4 : 0);
      });

      test('a user map item keeps each of its reads', () {
        final logs = <List<Object?>>[];
        for (final enabled in [true, false]) {
          final saved = nativeGapReadsEnabled;
          nativeGapReadsEnabled = enabled;
          addTearDown(() => nativeGapReadsEnabled = saved);
          final log = <Object?>[];
          final cfg = _config(
            type,
            form: 'map',
            spanGaps: 1.5,
            data: <Object?>[
              for (final (x, y) in _points)
                _LoggedMap({'x': x.toDouble(), 'y': y?.toDouble()}, log),
            ],
          );
          final chart = Chart(UiCanvasElement(width: 640, height: 400), cfg);
          addTearDown(chart.destroy);
          log.clear();
          final start = nativeGapReadsTaken;
          chart.update('none');
          expect(nativeGapReadsTaken, start);
          expect(_stops(chart), stopsOf1_5);
          logs.add(List.of(log));
          nativeGapReadsEnabled = saved;
        }
        expect(logs[0], isNotEmpty);
        expect(logs[0], logs[1]);
      });

      test('a map with user equality keeps each of its calls', () {
        final counts = <int>[];
        for (final enabled in [true, false]) {
          final saved = nativeGapReadsEnabled;
          nativeGapReadsEnabled = enabled;
          addTearDown(() => nativeGapReadsEnabled = saved);
          var calls = 0;
          final cfg = _config(
            type,
            form: 'map',
            spanGaps: 1.5,
            data: <Object?>[
              for (final (x, y) in _points)
                LinkedHashMap<String, Object?>(
                    equals: (a, b) {
                      calls++;
                      return a == b;
                    },
                    hashCode: (k) {
                      calls++;
                      return k.hashCode;
                    },
                  )
                  ..['x'] = x.toDouble()
                  ..['y'] = y?.toDouble(),
            ],
          );
          final chart = Chart(UiCanvasElement(width: 640, height: 400), cfg);
          addTearDown(chart.destroy);
          calls = 0;
          final start = nativeGapReadsTaken;
          chart.update('none');
          expect(nativeGapReadsTaken, start);
          expect(_stops(chart), stopsOf1_5);
          counts.add(calls);
          nativeGapReadsEnabled = saved;
        }
        expect(counts[0], greaterThan(0));
        expect(counts[0], counts[1]);
      });

      test('a point of a user class ends the proof at its pass', () {
        final twins = _twins(
          () => _config(type, form: 'map', spanGaps: 1.5, dataset: options),
          before: (chart) {
            final meta = chart.getDatasetMeta(0);
            final item = meta.parsed[4]! as Map<String, Object?>;
            // The write of y of the point 5 writes the x 8.5 into the item 4
            // before the gap test of the pass 5: |9 - 8.5| is not above 1.5.
            meta.data[5] = _UserPoint(() => item['x'] = 8.5);
          },
        );
        expect(_stops(twins.chart), [
          false,
          false,
          true,
          false,
          false,
          false,
          false,
        ]);
        // The passes 5 (a user point) and 6 (after it) read. A user point ends
        // the plan of the scatter for the rest of the loop.
        expect(twins.takes, line ? 4 : 2);
      });

      test('a category x axis, a stack or a segment keeps the reads', () {
        for (final config in [
          () => _config(type, x: const {'type': 'category'}, spanGaps: 1.5),
          () => _config(
            type,
            spanGaps: 1.5,
            y: const {'type': 'linear', 'stacked': true},
          ),
          () => _config(
            type,
            spanGaps: 1.5,
            dataset: <String, Object?>{
              'segment': <String, Object?>{
                'borderColor': (Object? ctx) => null,
              },
            },
          ),
        ]) {
          expect(_twins(config).takes, 0);
        }
      });

      test('a partial update reads at its first pass', () {
        final twins = _twins(
          () => _config(type, form: 'map', spanGaps: 1.5, dataset: options),
          before: (chart) {
            final meta = chart.getDatasetMeta(0);
            final start = nativeGapReadsTaken;
            meta.controller!.updateElements(meta.data, 2, 4, 'none');
            final partial = nativeGapReadsTaken - start;
            // The pass 2 reads `getParsed(1)`. The line takes the x of the
            // pass before at the passes 3 to 5, the scatter at the pass 5.
            expect(partial, nativeGapReadsEnabled ? takes(4) : 0);
          },
        );
        expect(_stops(twins.chart), stopsOf1_5);
      });
    });
  }

  group('NativeGapReads', () {
    late Chart chart;

    setUp(() {
      chart = Chart(
        UiCanvasElement(width: 640, height: 400),
        _config('line', form: 'map'),
      );
      addTearDown(chart.destroy);
    });

    test('qualifies the native item classes with a number x', () {
      final meta = chart.getDatasetMeta(0);
      final gaps = NativeGapReads.of(meta, double.infinity)!;
      final parsed = ParsedItem.of(const XAxis(), 1.0, const YAxis(), 2.0);
      expect(gaps.qualify(parsed, 1.0, 2.0), 1.0);
      expect(gaps.qualify(<String, Object?>{'x': 1}, 1, null), 1.0);
      expect(gaps.qualify(<String, double>{'x': 1}, 1.0, undefined), 1.0);
      expect(gaps.qualify(DataPoint(1, 2), 1.0, 2.0), 1.0);
      // An x or a value that is not a number, `null` or `undefined`.
      expect(gaps.qualify(parsed, '1', 2.0), isNull);
      expect(gaps.qualify(parsed, null, 2.0), isNull);
      expect(gaps.qualify(parsed, 1.0, '2'), isNull);
      // Items whose reads can run user code, or of no native class.
      expect(gaps.qualify(_LoggedMap({}, []), 1.0, 2.0), isNull);
      expect(
        gaps.qualify(
          LinkedHashMap<String, Object?>(equals: (a, b) => a == b),
          1.0,
          2.0,
        ),
        isNull,
      );
      expect(
        gaps.qualify(LinkedHashMap<String, Object?>.identity(), 1.0, 2.0),
        isNull,
      );
      expect(gaps.qualify(HashMap<String, Object?>(), 1.0, 2.0), isNull);
      expect(gaps.qualify(<Object?>[1.0, 2.0], 1.0, 2.0), isNull);
      expect(gaps.qualify(null, 1.0, 2.0), isNull);
      // A native map after a user one, and the reverse.
      expect(gaps.qualify(<String, Object?>{}, 1.0, 2.0), 1.0);
      // A new parsed list of the meta ends the proof.
      meta.parsed = <Object?>[...meta.parsed];
      expect(gaps.qualify(parsed, 1.0, 2.0), isNull);
    });

    test('a parsed list of a user class gives no gap reads', () {
      final meta = chart.getDatasetMeta(0);
      meta.parsed = _UserList(meta.parsed);
      expect(NativeGapReads.of(meta, double.infinity), isNull);
    });

    test('the gap test from the held x', () {
      final meta = chart.getDatasetMeta(0);
      for (final (max, results) in [
        (double.infinity, [false, false, false, false]),
        // NaN > max is false.
        (1.5, [false, true, false, false]),
      ]) {
        final gaps = NativeGapReads.of(meta, max)!;
        expect(gaps.stopOf(0), isNull, reason: 'no held x');
        final out = <bool?>[];
        for (final (held, x) in [
          (0.0, 1.0),
          (1.0, 4.0),
          (4.0, double.nan),
          (-0.0, 0.0),
        ]) {
          gaps.held = held;
          out.add(gaps.stopOf(x));
        }
        expect(out, results);
      }
    });

    test('the loop-wide guards', () {
      final meta = chart.getDatasetMeta(0);
      final controller = meta.controller!;
      NativeGapReads? prepare({
        bool directUpdate = true,
        bool hasStack = false,
        bool hasSegment = false,
        bool userPoints = false,
      }) => prepareNativeGapReads(
        controller,
        userPoints ? _UserList(meta.data) : meta.data,
        directUpdate: directUpdate,
        hasStack: hasStack,
        hasSegment: hasSegment,
        iScale: meta.iScale!,
        vScale: meta.vScale!,
        maxGapLength: double.infinity,
      );
      expect(prepare(), isNotNull);
      expect(prepare(directUpdate: false), isNull);
      expect(prepare(hasStack: true), isNull);
      expect(prepare(hasSegment: true), isNull);
      expect(prepare(userPoints: true), isNull);
    });
  });
}

/// A list of a user class: its reads are user code.
class _UserList<T> extends ListBase<T> {
  _UserList(this.items);
  final List<T> items;
  @override
  int get length => items.length;
  @override
  set length(int value) => items.length = value;
  @override
  T operator [](int index) => items[index];
  @override
  void operator []=(int index, T value) => items[index] = value;
}
