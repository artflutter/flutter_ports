// Original code, not ported from Chart.js: the index of the skipNull search.
@TestOn('vm')
library;

import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/bar_skip_null.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/option_functions.dart';
import 'package:flutter_test/flutter_test.dart';

const _colors = [
  ChartPaint.solid(ui.Color(0xFF3366AA)),
  ChartPaint.solid(ui.Color(0xFFAA6633)),
  ChartPaint.solid(ui.Color(0xFF33AA66)),
];

/// A bar chart with `skipNull`. [dataset] goes into each dataset, and
/// [each] gives more keys of one dataset.
Map<String, Object?> _config({
  required List<Object?> labels,
  required List<List<Object?>> data,
  bool stacked = false,
  bool horizontal = false,
  String indexType = 'category',
  String valueType = 'linear',
  Map<String, Object?> valueScale = const {},
  Map<String, Object?> dataset = const {},
  Map<String, Object?> Function(int d)? each,
  Map<String, Object?> extraScales = const {},
  bool customMaps = false,
}) {
  final index = <String, Object?>{
    'type': indexType,
    'stacked': stacked ? StackMode.on : StackMode.off,
  };
  final value = <String, Object?>{
    'type': valueType,
    'stacked': stacked ? StackMode.on : StackMode.off,
    'min': valueType == 'linear' ? -10.0 : 1.0,
    'max': 60.0,
    ...valueScale,
  };
  return {
    'type': 'bar',
    'data': <String, Object?>{
      'labels': labels,
      'datasets': <Object?>[
        for (var d = 0; d < data.length; d++)
          _wrap(customMaps, <String, Object?>{
            'data': data[d],
            'backgroundColor': _colors[d % _colors.length],
            'borderWidth': 0.0,
            'skipNull': true,
            ...dataset,
            ...?each?.call(d),
          }),
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'animation': false,
      if (horizontal) 'indexAxis': const YAxis(),
      'plugins': <String, Object?>{'legend': false, 'tooltip': false},
      'scales': <String, Object?>{
        'x': horizontal ? value : index,
        'y': horizontal ? index : value,
        ...extraScales,
      },
    },
  };
}

/// A Map of the app whose reads run code of the app.
final class _CustomMap(final Map<String, Object?> _inner)
    extends MapBase<String, Object?> {
  @override
  Object? operator [](Object? key) => _inner[key];

  @override
  void operator []=(String key, Object? value) => _inner[key] = value;

  @override
  void clear() => _inner.clear();

  @override
  Iterable<String> get keys => _inner.keys;

  @override
  Object? remove(Object? key) => _inner.remove(key);
}

/// A data item of the app whose reads call [onRead] (a review probe).
final class _ReadingMap(
  final Map<String, Object?> _inner,
  final void Function(Object? key) onRead,
) extends MapBase<String, Object?> {
  @override
  Object? operator [](Object? key) {
    onRead(key);
    return _inner[key];
  }

  @override
  void operator []=(String key, Object? value) => _inner[key] = value;

  @override
  void clear() => _inner.clear();

  @override
  Iterable<String> get keys => _inner.keys;

  @override
  Object? remove(Object? key) => _inner.remove(key);
}

/// A value of the app whose text calls [hook] (a review probe).
final class _ReadingValue(final void Function() hook) {
  @override
  String toString() {
    hook();
    return '5';
  }
}

Map<String, Object?> _wrap(bool custom, Map<String, Object?> map) =>
    custom ? _CustomMap(map) : map;

Map<String, Object?> _dataset(Map<String, Object?> cfg, int index) =>
    ((cfg['data']! as Map<String, Object?>)['datasets']!
            as List<Object?>)[index]!
        as Map<String, Object?>;

Chart _chart(Object cfg) {
  final chart = Chart(UiCanvasElement(width: 640, height: 400), cfg);
  addTearDown(chart.destroy);
  return chart;
}

Object? _plain(Object? value) {
  if (value is double) {
    if (!value.isFinite) return value.toString();
    if (value == 0 && value.isNegative) return '-0';
  }
  if (value is JsObjectFace) {
    return {for (final key in value.jsKeys()) key: _plain(value.jsRead(key))};
  }
  return value;
}

/// The geometry of each bar of each dataset.
Object _observe(Chart chart, int datasets) => [
  for (var d = 0; d < datasets; d++)
    [
      for (final e in chart.getDatasetMeta(d).data)
        [
          for (final key in [
            'x',
            'y',
            'base',
            'width',
            'height',
            'horizontal',
            'enableBorderRadius',
            'borderSkipped',
            'inflateAmount',
          ])
            _plain((e as types.ElementPropertyRead)[key]),
        ],
    ],
];

List<String> _labels(int count) => [for (var i = 0; i < count; i++) 'c$i'];

/// Values with null and NaN items, other ones in each dataset and step.
List<Object?> _holes(int d, int step, [int count = 16]) => <Object?>[
  for (var i = 0; i < count; i++)
    if ((i + d * 2 + step) % 5 == 0)
      null
    else if ((i + d + step) % 7 == 0)
      double.nan
    else
      ((i * 7 + d) % 13) + 1.0,
];

/// A chart, then three updates in [mode] with new data Lists, a hidden
/// dataset in the last one. It gives the bars after each step and the count
/// of the visits of parsed items in the three updates.
({List<Object?> seen, int visits}) _run(
  Map<String, Object?> Function(List<Object?> Function(int d, int step) data)
  config,
  int datasets,
  List<Object?> Function(int d, int step) data,
  UpdateMode? mode,
) {
  final cfg = config(data);
  final chart = _chart(cfg);
  final seen = <Object?>[_observe(chart, datasets)];
  final before = BarSkipNullIndex.debugVisits;
  for (var step = 1; step <= 3; step++) {
    for (var d = 0; d < datasets; d++) {
      _dataset(cfg, d)['data'] = data(d, step);
    }
    if (step == 3 && datasets > 1) chart.setDatasetVisibility(1, false);
    if (mode == null) {
      chart.update();
    } else {
      chart.update(mode);
    }
    seen.add(_observe(chart, datasets));
  }
  return (seen: seen, visits: BarSkipNullIndex.debugVisits - before);
}

typedef _Config = Map<String, Object?> Function(
  List<Object?> Function(int d, int step) data,
);

/// The update in the mode `none` takes the index, and the update in the
/// default mode declines it (no direct mode). With `animation: false` both
/// give each bar its final geometry. [indexed] says whether the first run
/// answers its searches from the index.
void _modeTwin(
  String name,
  _Config config, {
  int datasets = 3,
  List<Object?> Function(int d, int step) data = _holes,
  bool indexed = true,
}) {
  test('$name: the mode none equals the default mode', () {
    final fast = _run(config, datasets, data, UpdateMode.none);
    final scan = _run(config, datasets, data, null);
    expect(fast.seen, scan.seen);
    if (indexed) {
      expect(fast.visits, lessThan(scan.visits));
    } else {
      expect(fast.visits, greaterThanOrEqualTo(scan.visits));
    }
  });
}

/// A random bar chart of the review of 2026-11-16: category and linear
/// index scales, labels with repeats, object and array data, named stacks,
/// hidden and line datasets.
Map<String, Object?> _random(math.Random r) {
  final datasets = 1 + r.nextInt(4);
  final count = r.nextInt(11);
  final linearIndex = r.nextInt(10) < 3;
  final horizontal = r.nextInt(10) < 3;
  final labelCount = math.max(0, count + r.nextInt(5) - 2);
  final labels = <Object?>[
    for (var i = 0; i < labelCount; i++)
      if (linearIndex)
        if (r.nextInt(8) == 0) i + 1 else i
      else if (r.nextInt(12) == 0)
        'c0'
      else
        'c$i',
  ];
  Object? value() => switch (r.nextInt(10)) {
    0 || 1 => null,
    2 => double.nan,
    3 => 0.0,
    _ => r.nextInt(40) - 5.0,
  };
  final stackedChoice = r.nextInt(3);
  final sets = <Object?>[];
  for (var d = 0; d < datasets; d++) {
    final len = math.max(0, count + r.nextInt(5) - 3);
    final kind = r.nextInt(10);
    final List<Object?> data;
    if (kind < 5) {
      data = [for (var i = 0; i < len; i++) value()];
    } else if (kind < 9) {
      final xKind = r.nextInt(5);
      data = [
        for (var i = 0; i < len; i++)
          <String, Object?>{
            (horizontal ? 'y' : 'x'): linearIndex
                ? switch (xKind) {
                    0 => i,
                    1 => i * 1.0,
                    2 => i * 2,
                    3 => r.nextInt(len + 1),
                    _ => (r.nextInt(6) == 0 ? null : i),
                  }
                : switch (xKind) {
                    0 || 1 => 'c$i',
                    2 => 'c${r.nextInt(len + 1)}',
                    3 => i,
                    _ => (r.nextInt(6) == 0 ? null : 'c$i'),
                  },
            (horizontal ? 'x' : 'y'): value(),
          },
      ];
    } else {
      data = [
        for (var i = 0; i < len; i++)
          if (r.nextInt(5) == 0) null else <Object?>[r.nextInt(10) * 1.0, 20.0],
      ];
    }
    sets.add(<String, Object?>{
      'data': data,
      'backgroundColor': const ChartPaint.solid(ui.Color(0xFF3366AA)),
      'borderWidth': 0.0,
      if (r.nextInt(10) < 8) 'skipNull': true,
      if (r.nextInt(10) == 0) 'hidden': true,
      if (r.nextInt(10) == 0) 'grouped': false,
      if (r.nextInt(3) == 0) 'stack': r.nextBool() ? 'a' : 'b',
      if (r.nextInt(8) == 0)
        'barThickness': r.nextBool()
            ? BarThickness.flex
            : const BarThickness.pixels(7),
      if (r.nextInt(12) == 0) 'type': 'line',
    });
  }
  final index = <String, Object?>{
    'type': linearIndex ? 'linear' : 'category',
    if (stackedChoice != 2)
      'stacked': stackedChoice == 0 ? StackMode.on : StackMode.off,
    if (r.nextInt(5) == 0) 'reverse': true,
  };
  final valueScale = <String, Object?>{
    'type': 'linear',
    if (stackedChoice != 2)
      'stacked': stackedChoice == 0 ? StackMode.on : StackMode.off,
  };
  return {
    'type': 'bar',
    'data': <String, Object?>{'labels': labels, 'datasets': sets},
    'options': <String, Object?>{
      'responsive': false,
      'animation': false,
      if (horizontal) 'indexAxis': const YAxis(),
      'plugins': <String, Object?>{'legend': false, 'tooltip': false},
      'scales': <String, Object?>{
        'x': horizontal ? valueScale : index,
        'y': horizontal ? index : valueScale,
      },
    },
  };
}

void main() {
  group('twins', () {
    _modeTwin(
      'three datasets with null and NaN values',
      (data) => _config(
        labels: _labels(16),
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
      ),
    );
    _modeTwin(
      'named stacks on a stacked scale',
      (data) => _config(
        labels: _labels(16),
        stacked: true,
        data: [for (var d = 0; d < 4; d++) data(d, 0)],
        each: (d) => {'stack': d < 2 ? 'a' : 'b'},
      ),
      datasets: 4,
    );
    _modeTwin(
      'named stacks on a scale that is not stacked',
      (data) => _config(
        labels: _labels(16),
        data: [for (var d = 0; d < 4; d++) data(d, 0)],
        each: (d) => {if (d != 1) 'stack': d < 2 ? 'a' : 'b'},
      ),
      datasets: 4,
    );
    _modeTwin(
      'a hidden dataset and a dataset with grouped false',
      (data) => _config(
        labels: _labels(16),
        data: [for (var d = 0; d < 4; d++) data(d, 0)],
        each: (d) => {if (d == 0) 'hidden': true, if (d == 2) 'grouped': false},
      ),
      datasets: 4,
    );
    _modeTwin(
      'indexAxis y',
      (data) => _config(
        labels: _labels(16),
        horizontal: true,
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
      ),
    );
    _modeTwin(
      'datasets of other lengths at each step',
      (data) => _config(
        labels: _labels(16),
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
      ),
      data: (d, step) => _holes(d, step, 16 - (d * 3 + step) % 6),
    );
    _modeTwin(
      'barThickness flex and maxBarThickness',
      (data) => _config(
        labels: _labels(16),
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
        dataset: {'barThickness': BarThickness.flex, 'maxBarThickness': 9.0},
      ),
    );
    _modeTwin(
      'fewer labels than items: a search for null keeps the search',
      (data) => _config(
        labels: _labels(7),
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
      ),
    );
    _modeTwin(
      'object data with repeated labels: no positional list',
      (data) => _config(
        labels: _labels(6),
        data: [for (var d = 0; d < 2; d++) data(d, 0)],
      ),
      datasets: 2,
      indexed: false,
      data: (d, step) => <Object?>[
        for (final (i, label) in ['c0', 'c0', 'c3', 'c2', 'c5', 'c1'].indexed)
          <String, Object?>{
            'x': label,
            'y': (i + d + step).isEven ? null : i + 1.0,
          },
      ],
    );
    _modeTwin(
      'object data in the order of the labels',
      (data) => _config(
        labels: _labels(12),
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
      ),
      data: (d, step) => <Object?>[
        for (var i = 0; i < 12; i++)
          <String, Object?>{
            'x': 'c$i',
            'y': (i + d + step) % 4 == 0 ? null : i + 1.0,
          },
      ],
    );
    _modeTwin(
      'a logarithmic value scale has no index',
      (data) => _config(
        labels: _labels(16),
        valueType: 'logarithmic',
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
      ),
      indexed: false,
    );

    for (final mode in [UpdateMode.none, UpdateMode.reset]) {
      test('an option function of each bar keeps the search: $mode', () {
        _Config config(Object? borderWidth) =>
            (data) => _config(
              labels: _labels(16),
              data: [for (var d = 0; d < 3; d++) data(d, 0)],
              dataset: {'borderWidth': borderWidth},
            );
        final fast = _run(config(0.0), 3, _holes, mode);
        final scan = _run(config((Object? context) => 0.0), 3, _holes, mode);
        expect(fast.seen, scan.seen);
        expect(fast.visits, lessThan(scan.visits));
      });
    }
  });

  group('code of the app between two bars', () {
    // A function of the app writes a new object into slot 0 of the parsed
    // List of dataset 1, in place, from its third call in the update. The
    // object has the index value 3: the first item of that list with the
    // index value 3 is then item 0 (a number), not item 3 (null).
    ({Object seen, int visits}) run({
      required String writer,
      required bool writes,
      required UpdateMode? mode,
    }) {
      late final Chart chart;
      var calls = -1;
      Object? write(Object? value) {
        if (calls >= 0 && ++calls > 2 && writes) {
          chart.getDatasetMeta(1).parsed[0] = ParsedItem.of(
            const XAxis(),
            3.0,
            const YAxis(),
            5.0,
          );
        }
        return value;
      }

      List<Object?> data(int d, int step) => <Object?>[
        for (var i = 0; i < 12; i++)
          if ((d == 1 && i == 3) || (d == 0 && i == 0))
            null
          else
            ((i * 7 + d + step) % 13) + 1.0,
      ];
      final cfg = _config(
        labels: _labels(12),
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
        dataset: {
          if (writer == 'borderWidth')
            'borderWidth': (Object? context) => write(0.0),
          if (writer == 'base') 'base': (Object? context) => write(0.0),
          if (writer == 'maxBarThickness')
            'maxBarThickness': (Object? context) => write(40.0),
        },
        valueScale: {
          if (writer == 'grid')
            'grid': <String, Object?>{
              'lineWidth': (Object? context) => write(1.0),
            },
        },
      );
      chart = _chart(cfg);
      for (var d = 0; d < 3; d++) {
        _dataset(cfg, d)['data'] = data(d, 1);
      }
      calls = 0;
      final before = BarSkipNullIndex.debugVisits;
      if (mode == null) {
        chart.update();
      } else {
        chart.update(mode);
      }
      final visits = BarSkipNullIndex.debugVisits - before;
      // The function ran in the update.
      expect(calls, greaterThan(2));
      return (seen: _observe(chart, 3), visits: visits);
    }

    for (final writer in ['grid', 'base', 'borderWidth', 'maxBarThickness']) {
      test('an in-place write of a slot from $writer equals the search', () {
        final fast = run(writer: writer, writes: true, mode: UpdateMode.none);
        // The default mode has no index (no direct mode).
        final scan = run(writer: writer, writes: true, mode: null);
        expect(fast.seen, scan.seen);
        // The write changes the bars: item 0 answers the search for 3.
        final quiet = run(writer: writer, writes: false, mode: UpdateMode.none);
        expect(fast.seen, isNot(quiet.seen));
      });
    }
  });

  group('code of the app inside the search of a list', () {
    // The review probes of 2026-11-17. Dataset 1 has `parsing: false`: its
    // parsed list is the data List of the app. The search of that list runs
    // code of the app, through the `operator []` of a Map of the app or
    // through the `toString` of a value (`jsIsNaN`). That code writes slot 1
    // of the proven list of dataset 0, in place, with the index value 5. The
    // first item of that list with the index value 5 is then item 1 (y 5),
    // not item 5 (y null). The JS function count does not change.
    Object run(String reader, UpdateMode? mode, {required bool writes}) {
      late final Chart chart;
      var armed = false;
      var fired = false;
      void onRead(Object? key, double x) {
        if (!writes || fired || !armed) return;
        if (key == 'x' && x == 3.0) {
          fired = true;
          chart.getDatasetMeta(0).parsed[1] = ParsedItem.of(
            const XAxis(),
            5.0,
            const YAxis(),
            5.0,
          );
        }
      }

      List<Object?> plain(int d) => <Object?>[
        for (var i = 0; i < 12; i++)
          if (d == 0 && i == 5) null else ((i * 7 + d) % 13) + 1.0,
      ];
      Object item(int i) => switch (reader) {
        'map' => _ReadingMap(<String, Object?>{
          'x': i * 1.0,
          'y': i + 2.0,
        }, (key) => onRead(key, i * 1.0)),
        _ => <String, Object?>{
          'x': i * 1.0,
          'y': i == 3 ? _ReadingValue(() => onRead('x', 3)) : i + 2.0,
        },
      };
      final cfg = <String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'labels': _labels(12),
          'datasets': <Object?>[
            <String, Object?>{
              'data': plain(0),
              'skipNull': true,
              'borderWidth': 0.0,
            },
            <String, Object?>{
              'parsing': false,
              'skipNull': true,
              'borderWidth': 0.0,
              'data': <Object?>[for (var i = 0; i < 12; i++) item(i)],
            },
            <String, Object?>{
              'data': plain(2),
              'skipNull': true,
              'borderWidth': 0.0,
            },
          ],
        },
        'options': <String, Object?>{
          'responsive': false,
          'animation': false,
          'plugins': <String, Object?>{'legend': false, 'tooltip': false},
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'category'},
            'y': <String, Object?>{'type': 'linear', 'min': -10.0, 'max': 60.0},
          },
        },
      };
      chart = _chart(cfg);
      armed = true;
      if (mode == null) {
        chart.update();
      } else {
        chart.update(mode);
      }
      expect(fired, writes);
      return _observe(chart, 3);
    }

    for (final reader in ['map', 'toString']) {
      test('a write from the $reader of a parsing:false item equals the '
          'search', () {
        final fast = run(reader, UpdateMode.none, writes: true);
        final scan = run(reader, null, writes: true);
        expect(fast, scan);
        // The write changes the bars.
        final quiet = run(reader, UpdateMode.none, writes: false);
        expect(scan, isNot(quiet));
      });
    }
  });

  group('the test of the chart declines', () {
    /// The visits of three updates in the mode none and in the default mode.
    void declines(String name, _Config config, {int datasets = 3}) {
      test(name, () {
        final fast = _run(config, datasets, _holes, UpdateMode.none);
        final scan = _run(config, datasets, _holes, null);
        expect(fast.seen, scan.seen);
        // No index: the mode none visits each item that the search visits.
        expect(fast.visits, greaterThanOrEqualTo(scan.visits));
      });
    }

    declines(
      'a function in the grid line width of the value scale',
      (data) => _config(
        labels: _labels(16),
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
        valueScale: {
          'grid': <String, Object?>{'lineWidth': (Object? context) => 1.0},
        },
      ),
    );
    declines(
      'a function in the base of the dataset',
      (data) => _config(
        labels: _labels(16),
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
        dataset: {'base': (Object? context) => 0.0},
      ),
    );
    declines(
      'a function in grouped of another bar dataset',
      (data) => _config(
        labels: _labels(16),
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
        each: (d) => {if (d == 2) 'grouped': (Object? context) => true},
      ),
    );
    declines(
      'a custom Map as a dataset object',
      (data) => _config(
        labels: _labels(16),
        customMaps: true,
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
      ),
    );
    declines(
      'a logarithmic scale that the bars do not use',
      (data) => _config(
        labels: _labels(16),
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
        extraScales: {
          'y2': <String, Object?>{
            'type': 'logarithmic',
            'display': ScaleDisplay.off,
          },
        },
      ),
    );
  });

  test('a dataset of another type keeps the index', () {
    Map<String, Object?> config(List<Object?> Function(int d, int step) data) {
      final cfg = _config(
        labels: _labels(16),
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
      );
      _dataset(cfg, 2)['type'] = 'line';
      return cfg;
    }

    final fast = _run(config, 3, _holes, UpdateMode.none);
    final scan = _run(config, 3, _holes, null);
    expect(fast.seen, scan.seen);
    expect(fast.visits, lessThan(scan.visits));
  });

  test('hidden scales, as in the bench window: the index engages', () {
    Map<String, Object?> config(List<Object?> Function(int d, int step) data) {
      final cfg = _config(
        labels: _labels(16),
        data: [for (var d = 0; d < 3; d++) data(d, 0)],
      );
      final scales =
          (cfg['options']! as Map<String, Object?>)['scales']!
              as Map<String, Object?>;
      for (final scale in scales.values) {
        (scale! as Map<String, Object?>)['display'] = ScaleDisplay.off;
      }
      return cfg;
    }

    final fast = _run(config, 3, _holes, UpdateMode.none);
    final scan = _run(config, 3, _holes, null);
    expect(fast.seen, scan.seen);
    expect(fast.visits, lessThan(scan.visits));
  });

  group('visits of the parsed items', () {
    int visits(int bars, UpdateMode? mode) {
      List<Object?> data(int d, int step) => <Object?>[
        for (var i = 0; i < bars; i++)
          if ((i + d + step) % 7 == 0) null else ((i * 7 + d) % 13) + 1.0,
      ];
      return _run(
        (data) => _config(
          labels: _labels(bars),
          data: [for (var d = 0; d < 3; d++) data(d, 0)],
        ),
        3,
        data,
        mode,
      ).visits;
    }

    test('3 x 200 bars: the count grows with the bar count', () {
      // For each of the 3 updates: each of the 3 controllers proves at most
      // 3 lists of 200 items, and each of its 200 bars makes 2 `_getStacks`
      // calls with at most 3 reads.
      const bound = 3 * (3 * 3 * 200 + 3 * 200 * 2 * 3);
      final at200 = visits(200, UpdateMode.none);
      final at400 = visits(400, UpdateMode.none);
      expect(at200, greaterThan(0));
      expect(at200, lessThanOrEqualTo(bound));
      expect(at400, lessThanOrEqualTo(2 * bound));
      // Not the square: two times the bars, two times the visits.
      expect(at400, lessThanOrEqualTo(at200 * 2 + 64));
    });

    test('3 x 200 bars: the search of the default mode grows with the '
        'square', () {
      final at100 = visits(100, null);
      final at200 = visits(200, null);
      expect(at200, greaterThan(200 * 200));
      expect(at200, greaterThan(at100 * 3));
      expect(at200, greaterThan(visits(200, UpdateMode.none) * 20));
    });
  });

  group('BarSkipNullIndex', () {
    const x = XAxis();
    const y = YAxis();

    /// The meta of dataset 0 of a chart, with [items] as its parsed list.
    types.ChartMeta metaOf(List<Object?> items) {
      final chart = _chart(
        _config(
          labels: _labels(3),
          data: [
            <Object?>[1.0, 2.0, 3.0],
          ],
        ),
      );
      return chart.getDatasetMeta(0)..parsed = items;
    }

    List<Object?> positional([int count = 6]) => <Object?>[
      for (var i = 0; i < count; i++)
        ParsedItem.of(x, i == 2 ? null : i * 1.0, y, 1.0),
    ];

    test('find gives the item at the position of a positional list', () {
      final items = positional();
      final meta = metaOf(items);
      final index = BarSkipNullIndex(() => true);
      expect(index.proved, isFalse);
      final before = BarSkipNullIndex.debugVisits;
      expect(index.find(meta, x, 4.0), same(items[4]));
      expect(index.proved, isTrue);
      // One pass of 6 items and one read.
      expect(BarSkipNullIndex.debugVisits - before, 7);
      expect(index.find(meta, x, 4), same(items[4]));
      expect(index.find(meta, x, -0.0), same(items[0]));
      // No item can match: `find` gives `undefined`.
      expect(index.find(meta, x, 6.0), same(undefined));
      expect(index.find(meta, x, -1.0), same(undefined));
      expect(index.find(meta, x, 1.5), same(undefined));
      expect(index.find(meta, x, double.nan), same(undefined));
      expect(index.find(meta, x, double.infinity), same(undefined));
      // The one item that can match has no index value.
      expect(index.find(meta, x, 2.0), same(undefined));
      // 3 reads since the first search: no second pass.
      expect(BarSkipNullIndex.debugVisits - before, 10);
    });

    test('a search value that is no number keeps the search', () {
      final meta = metaOf(positional());
      final index = BarSkipNullIndex(() => true);
      expect(index.find(meta, x, 'c1'), same(BarSkipNullIndex.scan));
      expect(index.find(meta, x, null), same(BarSkipNullIndex.scan));
      expect(index.find(meta, x, undefined), same(BarSkipNullIndex.scan));
      expect(
        index.find(meta, x, DateTime.utc(2026)),
        same(BarSkipNullIndex.scan),
      );
      expect(index.proved, isFalse);
    });

    test('a list that is not positional keeps the search', () {
      for (final items in <List<Object?>>[
        [ParsedItem.of(x, 0.0, y, 1.0), ParsedItem.of(x, 0.0, y, 1.0)],
        [ParsedItem.of(x, 1.0, y, 1.0), ParsedItem.of(x, 0.0, y, 1.0)],
        [ParsedItem.of(x, 0.0, y, 1.0), ParsedItem.of(x, double.nan, y, 1.0)],
        [ParsedItem.of(x, 0.0, y, 1.0), ParsedItem.of(x, '1', y, 1.0)],
        [ParsedItem.of(x, 0.0, y, 1.0), 3.0],
        [ParsedItem.of(x, 0.0, y, 1.0), null],
        [
          ParsedItem.of(x, 0.0, y, 1.0),
          <String, Object?>{'x': 1.0, 'y': 1.0},
        ],
      ]) {
        final index = BarSkipNullIndex(() => true);
        final meta = metaOf(items);
        expect(index.find(meta, x, 0.0), same(BarSkipNullIndex.scan));
        expect(index.find(meta, x, 1.0), same(BarSkipNullIndex.scan));
      }
    });

    test('a List of another class keeps the search', () {
      for (final items in <List<Object?>>[
        UnmodifiableListView(positional()),
        <ParsedItem>[for (final item in positional()) item! as ParsedItem],
      ]) {
        final index = BarSkipNullIndex(() => true);
        expect(
          index.find(metaOf(items), x, 1.0),
          same(BarSkipNullIndex.scan),
          reason: '${items.runtimeType}',
        );
      }
    });

    test('the data List of the app (parsing false) keeps the search', () {
      final chart = _chart(
        _config(
          labels: _labels(3),
          dataset: {'parsing': false},
          data: [
            <Object?>[
              for (var i = 0; i < 3; i++) <String, Object?>{'x': i, 'y': 1.0},
            ],
          ],
        ),
      );
      final meta = chart.getDatasetMeta(0);
      expect(meta.controller!.parsing, isFalse);
      meta.parsed = positional();
      final index = BarSkipNullIndex(() => true);
      expect(index.find(meta, x, 1.0), same(BarSkipNullIndex.scan));
      // The same list with parsing on: a new chart (its creation calls
      // functions), so a new index.
      final other = metaOf(positional());
      expect(
        BarSkipNullIndex(() => true).find(other, x, 1.0),
        isA<ParsedItem>(),
      );
    });

    test('a call of a function value ends the proofs', () {
      final items = positional();
      final meta = metaOf(items);
      final index = BarSkipNullIndex(() => true);
      expect(index.find(meta, x, 4.0), same(items[4]));
      // Each call of an option function counts: a scriptable option of any
      // scope, a descriptor, a fallback.
      final before = appFunctionCalls;
      callScriptable((Object? v) => v, 1.0);
      expect(appFunctionCalls, greaterThan(before));
      expect(index.find(meta, x, 4.0), same(BarSkipNullIndex.scan));
      // Also after it: the search takes the rest of the update.
      expect(index.find(meta, x, 3.0), same(BarSkipNullIndex.scan));
      expect(index.dropped, isTrue);
    });

    test('a descriptor and a fallback count too', () {
      final before = appFunctionCalls;
      callDescriptor((String name) => true, 'a');
      expect(appFunctionCalls, before + 1);
      callFallback((Object? name, Object? value) => name, 'a', 1.0);
      expect(appFunctionCalls, before + 2);
    });

    test('the test of the chart runs one time, at the first proof', () {
      final items = positional();
      final meta = metaOf(items);
      var calls = 0;
      final index = BarSkipNullIndex(() {
        calls++;
        return true;
      });
      // A search value that is no number makes no proof and no test.
      expect(index.find(meta, x, 'c1'), same(BarSkipNullIndex.scan));
      expect(calls, 0);
      expect(index.find(meta, x, 4.0), same(items[4]));
      expect(index.find(meta, x, 3.0), same(items[3]));
      expect(calls, 1);
    });

    test('a failed test of the chart keeps the search', () {
      final meta = metaOf(positional());
      final index = BarSkipNullIndex(() => false);
      expect(index.find(meta, x, 4.0), same(BarSkipNullIndex.scan));
      expect(index.find(meta, x, 3.0), same(BarSkipNullIndex.scan));
      expect(index.proved, isFalse);
      expect(index.dropped, isTrue);
    });

    test('a new length of the list ends the proofs', () {
      final items = positional();
      final meta = metaOf(items);
      final index = BarSkipNullIndex(() => true);
      expect(index.find(meta, x, 4.0), same(items[4]));
      items.insert(0, ParsedItem.of(x, 4.0, y, 1.0));
      expect(index.find(meta, x, 4.0), same(BarSkipNullIndex.scan));
      items.removeAt(0);
      expect(index.find(meta, x, 4.0), same(BarSkipNullIndex.scan));
    });

    test('another item at the position ends the proofs', () {
      for (final other in <Object?>[
        ParsedItem.of(x, 1.0, y, 1.0),
        <String, Object?>{'x': 4.0},
        null,
      ]) {
        final items = positional();
        final meta = metaOf(items);
        final index = BarSkipNullIndex(() => true);
        expect(index.find(meta, x, 3.0), same(items[3]));
        items[4] = other;
        expect(index.find(meta, x, 4.0), same(BarSkipNullIndex.scan));
        expect(index.find(meta, x, 3.0), same(BarSkipNullIndex.scan));
      }
    });

    test('a new parsed list of the meta gets its own proof', () {
      final meta = metaOf(positional());
      final index = BarSkipNullIndex(() => true);
      expect(index.find(meta, x, 1.0), isA<ParsedItem>());
      final repeated = <Object?>[
        ParsedItem.of(x, 1.0, y, 1.0),
        ParsedItem.of(x, 1.0, y, 1.0),
      ];
      meta.parsed = repeated;
      expect(index.find(meta, x, 1.0), same(BarSkipNullIndex.scan));
    });

    test('a list whose search can run code of the app ends the proofs', () {
      for (final unsafe in <List<Object?>>[
        // An object as the value: `jsIsNaN` calls its `toString`.
        [ParsedItem.of(x, 0.0, y, _ReadingValue(() {}))],
        // An object as the index value.
        [ParsedItem.of(x, _ReadingValue(() {}), y, 1.0)],
        // A Map of the app as an item.
        [
          _ReadingMap(<String, Object?>{'x': 0.0, 'y': 1.0}, (_) {}),
        ],
      ]) {
        final items = positional();
        final index = BarSkipNullIndex(() => true);
        expect(index.find(metaOf(items), x, 4.0), same(items[4]));
        final other = metaOf(unsafe);
        expect(index.find(other, x, 0.0), same(BarSkipNullIndex.scan));
        expect(index.dropped, isTrue);
        // No later answer relies on the proof of the first list.
        expect(index.find(metaOf(items), x, 4.0), same(BarSkipNullIndex.scan));
      }
    });

    test('proveAll declines a list whose read can run code of the app', () {
      final clean = metaOf(positional());
      final notPositional = metaOf(<Object?>[
        ParsedItem.of(x, 1.0, y, 1.0),
        ParsedItem.of(x, 1.0, y, 1.0),
      ]);
      expect(
        BarSkipNullIndex(() => true).proveAll([clean, notPositional], x),
        isTrue,
      );
      final foreign = ParsedItem.of(x, 0.0, y, 1.0)..jsWrite('_stacks', 'text');
      expect(foreign.hasForeign, isTrue);
      for (final unsafe in <List<Object?>>[
        [foreign],
        [ParsedItem.of(x, 0.0, y, _ReadingValue(() {}))],
        [
          <String, Object?>{'x': 0.0, 'y': 1.0},
        ],
        UnmodifiableListView(positional()),
      ]) {
        expect(
          BarSkipNullIndex(() => true).proveAll([clean, metaOf(unsafe)], x),
          isFalse,
        );
      }
    });

    test('another index axis ends the proofs', () {
      final meta = metaOf(positional());
      final index = BarSkipNullIndex(() => true);
      expect(index.find(meta, x, 1.0), isA<ParsedItem>());
      expect(index.find(meta, y, 1.0), same(BarSkipNullIndex.scan));
      expect(index.find(meta, x, 1.0), same(BarSkipNullIndex.scan));
    });

    test('an option read ends the proofs, and only after a proof', () {
      final items = positional();
      final meta = metaOf(items);
      final index = BarSkipNullIndex(() => true)..optionRead();
      expect(index.find(meta, x, 4.0), same(items[4]));
      index.optionRead();
      expect(index.find(meta, x, 4.0), same(BarSkipNullIndex.scan));
    });

    test('applies only to a direct mode and the exact category and linear '
        'scales', () {
      final chart = _chart(
        _config(
          labels: _labels(3),
          data: [
            <Object?>[1.0, 2.0, 3.0],
          ],
        ),
      );
      final log = _chart(
        _config(
          labels: _labels(3),
          valueType: 'logarithmic',
          data: [
            <Object?>[1.0, 2.0, 3.0],
          ],
        ),
      );
      final x = chart.scales['x'];
      final y = chart.scales['y'];
      expect(BarSkipNullIndex.applies('none', x, y), isTrue);
      expect(BarSkipNullIndex.applies('reset', x, y), isTrue);
      expect(BarSkipNullIndex.applies('none', y, x), isTrue);
      expect(BarSkipNullIndex.applies('default', x, y), isFalse);
      expect(BarSkipNullIndex.applies('resize', x, y), isFalse);
      expect(BarSkipNullIndex.applies('active', x, y), isFalse);
      expect(BarSkipNullIndex.applies('none', x, null), isFalse);
      expect(BarSkipNullIndex.applies('none', null, y), isFalse);
      expect(BarSkipNullIndex.applies('none', x, log.scales['y']), isFalse);
    });
  });

  group('review cases', () {
    for (final reverse in [false, true]) {
      test('a linear index scale takes the index, reverse $reverse', () {
        final cfg = <String, Object?>{
          'type': 'bar',
          'data': <String, Object?>{
            'datasets': <Object?>[
              for (var d = 0; d < 3; d++)
                <String, Object?>{
                  'data': <Object?>[
                    for (var i = 0; i < 50; i++)
                      <String, Object?>{
                        'x': i,
                        'y': (i + d) % 4 == 0 ? null : i + 1.0,
                      },
                  ],
                  'backgroundColor': _colors[0],
                  'borderWidth': 0.0,
                  'skipNull': true,
                },
            ],
          },
          'options': <String, Object?>{
            'responsive': false,
            'animation': false,
            'plugins': <String, Object?>{'legend': false, 'tooltip': false},
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'linear', 'reverse': reverse},
              'y': <String, Object?>{'type': 'linear'},
            },
          },
        };
        final chart = _chart(cfg);
        final meta = chart.getDatasetMeta(0);
        final controller = meta.controller! as BarController;
        var before = BarSkipNullIndex.debugVisits;
        controller.updateElements(meta.data, 0, meta.data.length, 'none');
        final search = BarSkipNullIndex.debugVisits - before;
        final expected = _observe(chart, 1);
        before = BarSkipNullIndex.debugVisits;
        controller.update('none');
        final fast = BarSkipNullIndex.debugVisits - before;
        expect(_observe(chart, 1), expected);
        expect(fast, lessThan(search));
      });
    }

    test('random charts: the index gives the bars of the search', () {
      var compared = 0;
      var indexVisits = 0;
      var searchVisits = 0;
      for (var seed = 0; seed < 2000; seed++) {
        final cfg = _random(math.Random(seed));
        final Chart chart;
        try {
          chart = Chart(UiCanvasElement(width: 640, height: 400), cfg);
        } on Object {
          // The same config throws in the search: no bars to compare.
          continue;
        }
        final sets =
            (cfg['data']! as Map<String, Object?>)['datasets']!
                as List<Object?>;
        for (var d = 0; d < sets.length; d++) {
          final meta = chart.getDatasetMeta(d);
          final controller = meta.controller;
          if (controller is! BarController) continue;
          for (final mode in ['none', 'reset', 'none']) {
            Object? search;
            Object? searchError;
            var before = BarSkipNullIndex.debugVisits;
            try {
              // No `update` call: no index.
              controller.updateElements(meta.data, 0, meta.data.length, mode);
              search = [
                for (final e in meta.data)
                  _plain((e as types.ElementPropertyRead)['x']),
                _observe(chart, sets.length),
              ];
            } on Object catch (e) {
              searchError = e.runtimeType;
            }
            searchVisits += BarSkipNullIndex.debugVisits - before;
            Object? fast;
            Object? fastError;
            before = BarSkipNullIndex.debugVisits;
            try {
              controller.update(mode);
              fast = [
                for (final e in meta.data)
                  _plain((e as types.ElementPropertyRead)['x']),
                _observe(chart, sets.length),
              ];
            } on Object catch (e) {
              fastError = e.runtimeType;
            }
            indexVisits += BarSkipNullIndex.debugVisits - before;
            expect(fastError, searchError, reason: 'seed $seed dataset $d');
            expect(fast, search, reason: 'seed $seed dataset $d $mode');
            compared++;
          }
        }
        chart.destroy();
      }
      expect(compared, greaterThan(10000));
      expect(indexVisits, lessThan(searchVisits));
    });
  });
}
