// Original code, not ported from Chart.js: twins of the per-item reads.
@TestOn('vm')
library;

// Chart.js ADR 0096: the typed reads of the data and the datasets, the data
// items of `parsing: false`, the walk of `clearStacks` and the presized parse
// lists. Each group compares a chart on the short path with its twin on the
// ordinary path: a Map where the short path needs a typed scope or a typed
// item, or a custom List where it needs a native one.

import 'dart:collection';

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart' as typed;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show axisStackOf, controllerArgs, dataItemValue, parsedValueOf, stacksOf;
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show scaleCfgArg;
import 'package:flutter_chartjs_port/src/core/data_update.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGetKey;
import 'package:flutter_chartjs_port/src/options/option_scope.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_chartjs_port/src/options/scopes.g.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

/// A value of a parsed item whose `toString` is user code.
final class _Logged {
  _Logged(this.text, this.onRead);
  final String text;
  final void Function() onRead;
  @override
  String toString() {
    onRead();
    return text;
  }
}

/// A scale whose `parse` gives a value that runs user code in a comparison.
final class _ObjectLinear extends LinearScale {
  _ObjectLinear(super.cfg);
  static void Function()? onRead;
  static final value = JsClass(
    'PlumbingObjectLinear',
    superclass: LinearScale.jsClass,
    statics: {'id': 'plumbing-object-linear'},
    construct: (_, args) => _ObjectLinear(scaleCfgArg(args)),
  );

  // An item value runs user code. The bounds of `Scale.init` have no index.
  @override
  Object? parse(Object? raw, [double? index]) => index == null
      ? super.parse(raw, index)
      : _Logged('$index', () => onRead?.call());
}

/// A scale that logs the order of its `parse` calls.
final class _OrderLinear extends LinearScale {
  _OrderLinear(super.cfg);
  static final List<String> log = [];
  static final value = JsClass(
    'PlumbingOrderLinear',
    superclass: LinearScale.jsClass,
    statics: {'id': 'plumbing-order-linear'},
    construct: (_, args) => _OrderLinear(scaleCfgArg(args)),
  );

  @override
  Object? parse(Object? raw, [double? index]) {
    log.add('$id$index');
    return super.parse(raw, index);
  }
}

/// A custom List of parsed items: its reads are user code.
final class _ObservedItems extends ListBase<ParsedItem> {
  _ObservedItems(this.items, this.onRead);
  final List<ParsedItem> items;
  final void Function() onRead;
  @override
  int get length => items.length;
  @override
  set length(int value) => items.length = value;
  @override
  ParsedItem operator [](int index) {
    onRead();
    return items[index];
  }

  @override
  void operator []=(int index, ParsedItem value) => items[index] = value;
}

/// A line controller whose `parsePrimitiveData` gives fewer items than the
/// count, with [short], or a custom List, with [onItemRead].
final class _ShortController extends LineController {
  _ShortController(super.chart, super.datasetIndex, [super.newTarget]);
  static bool short = false;
  static void Function()? onItemRead;
  static final value = JsClass(
    'PlumbingShortController',
    superclass: LineController.jsClass,
    statics: {'id': 'plumbing-short'},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _ShortController(chart, datasetIndex, newTarget);
    },
  );

  @override
  List<ParsedItem> parsePrimitiveData(
    covariant types.ChartMeta meta,
    List<Object?> data,
    double start,
    double count,
  ) {
    final parsed = super.parsePrimitiveData(meta, data, start, count);
    final onRead = onItemRead;
    if (onRead != null) return _ObservedItems(parsed, onRead);
    return short ? parsed.sublist(0, 1) : parsed;
  }
}

/// A controller with its own `getDataset`, a subclass of the user.
final class _DatasetCountController extends LineController {
  _DatasetCountController(super.chart, super.datasetIndex, [super.newTarget]);
  int reads = 0;
  static final value = JsClass(
    'PlumbingDatasetController',
    superclass: LineController.jsClass,
    statics: {'id': 'plumbing-dataset'},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _DatasetCountController(chart, datasetIndex, newTarget);
    },
  );

  @override
  Object? getDataset() {
    reads++;
    return super.getDataset();
  }
}

/// A chart whose `data` is a value of the user.
final class _DataChart extends Chart {
  _DataChart(super.item, super.userConfig);
  Object? replacement;
  int reads = 0;
  @override
  Object get data {
    reads++;
    return replacement ?? super.data;
  }
}

/// A custom List of numbers whose reads are user code.
final class _ObservedNumbers extends ListBase<double> {
  _ObservedNumbers(this.values);
  final List<double> values;
  void Function()? onRead;
  @override
  int get length => values.length;
  @override
  set length(int value) => values.length = value;
  @override
  double operator [](int index) {
    onRead?.call();
    return values[index];
  }

  @override
  void operator []=(int index, double value) => values[index] = value;
}

Chart _chart(Object cfg) {
  final canvas = UiCanvasElement(width: 320, height: 200);
  final chart = Chart(canvas, cfg);
  addTearDown(() {
    chart.destroy();
    canvas.getContext2d().dispose();
  });
  return chart;
}

Map<String, Object?> _options({
  bool parsing = true,
  bool stacked = false,
  Object? xType = 'linear',
  Object? yType = 'linear',
}) => <String, Object?>{
  'responsive': false,
  'animation': false,
  if (!parsing) 'parsing': false,
  'plugins': <String, Object?>{
    'legend': false,
    'tooltip': false,
    'colors': false,
    'filler': false,
  },
  'scales': <String, Object?>{
    'x': <String, Object?>{'type': xType, 'min': 0, 'max': 10},
    'y': <String, Object?>{
      'type': yType,
      'min': 0,
      'max': 30,
      'stacked': stacked,
    },
  },
};

Map<String, Object?> _rawConfig(
  List<Object?> data, {
  String type = 'scatter',
  bool parsing = false,
  Map<String, Object?>? dataset,
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{'data': data, ...?dataset},
    ],
  },
  'options': _options(parsing: parsing),
};

/// The twin of a list of data points, as the Maps of the user.
List<Object?> _maps(List<typed.DataPoint> points) => <Object?>[
  for (final point in points) <String, Object?>{'x': point.x, 'y': point.y},
];

typed.ChartConfig _typedConfig(List<typed.DataPoint> points) =>
    typed.ChartConfig(
      type: typed.ChartKind.scatter,
      datasets: [
        typed.ScatterDataset(points: points, showLine: false, pointRadius: 3),
      ],
      scales: const {
        'x': typed.LinearAxis(min: 0, max: 10),
        'y': typed.LinearAxis(min: 0, max: 30),
      },
      responsive: false,
      animation: typed.ChartAnimation.none,
      extra: const {
        'parsing': false,
        'plugins': {
          'legend': false,
          'tooltip': false,
          'colors': false,
          'filler': false,
        },
      },
    );

List<typed.DataPoint> _points() => [
  typed.DataPoint(1, 2),
  typed.DataPoint(2, null),
  typed.DataPoint(3, 4),
];

/// The geometry and the validity of the elements of the dataset 0.
Object _geometry(Chart chart) => [
  for (final element in chart.getDatasetMeta(0).data)
    [element.x, element.y, (element as Element)['skip']],
];

Object? _plain(Object? value) {
  if (value is JsObjectFace && value is! typed.DataPoint) {
    return [
      for (final key in value.jsKeys()) [key, _plain(value.jsRead(key))],
    ];
  }
  return value;
}

/// The parsed items as plain lists of their keys and values, and `sorted`.
Object _parsedOf(types.ChartMeta meta) => [
  meta.sorted,
  [for (final item in meta.parsed) _plain(item)],
];

DatasetController _controllerOf(Chart chart, [num index = 0]) =>
    chart.getDatasetMeta(index).controller!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([
    _ObjectLinear.value,
    _OrderLinear.value,
    _ShortController.value,
    _DatasetCountController.value,
  ]);

  group('the typed read of the data and the datasets', () {
    test('a typed config and its Map twin give the same results', () {
      final points = _points();
      final lowering = ChartConfigLowering(_typedConfig(points));
      final a = _chart(lowering.lower());
      final b = _chart(
        _rawConfig(
          _maps(points),
          dataset: {'showLine': false, 'pointRadius': 3},
        ),
      );
      expect(a.data, isA<OptionScope>());
      expect(b.data, isA<Map<String, Object?>>());
      expect(_geometry(a), _geometry(b));
      for (final chart in [a, b]) {
        final controller = _controllerOf(chart);
        final datasets = readOption(chart.data, OptionKey.datasets)! as List;
        expect(controller.getDataset(), same(datasets[0]));
        controller.index = 7;
        expect(controller.getDataset(), same(undefined));
        controller.index = 0;
      }
    });

    test('a context reads the live data of its dataset in both forms', () {
      final points = _points();
      final a = _chart(ChartConfigLowering(_typedConfig(points)).lower());
      final maps = _maps(points);
      final b = _chart(_rawConfig(maps));
      final items = [points, maps];
      for (final (form, chart) in [a, b].indexed) {
        final context = _controllerOf(chart).getContext(1, true, 'mode');
        expect(context['raw'], same(items[form][1]));
        expect(context['parsed'], same(items[form][1]));
        expect(context['dataIndex'], 1);
        expect(context['index'], 1);
        expect(context['active'], isTrue);
        expect(context['mode'], 'mode');
        // A write of the dataset is visible at the next read.
        final datasets =
            readOption(chart.data, OptionKey.datasets)! as List<Object?>;
        final dataset = JsObjectLike(datasets[0]!);
        final other = <Object?>['a', 'b'];
        dataset['data'] = other;
        expect(_controllerOf(chart).getContext(1)['raw'], 'b');
        expect(_controllerOf(chart).getContext(1)['active'], isFalse);
        dataset['data'] = items[form];
      }
    });

    test('an absent datasets key throws the same error in both forms', () {
      final a = _chart(ChartConfigLowering(_typedConfig(_points())).lower());
      final b = _chart(_rawConfig(_maps(_points())));
      for (final chart in [a, b]) {
        final data = JsObjectLike(chart.data);
        final datasets = data['datasets'];
        data.remove('datasets');
        expect(
          readOption(chart.data, OptionKey.datasets),
          same(undefined),
        );
        expect(
          () => _controllerOf(chart).getDataset(),
          throwsA(isA<TypeError>()),
        );
        data['datasets'] = datasets;
      }
    });

    test('a Map dataset in a typed data scope reads by name', () {
      final dataset = <String, Object?>{
        'type': 'line',
        'data': <Object?>[1.0, 2.0],
        'label': 'user',
      };
      final data = ChartDataScope()
        ..jsWrite('labels', <Object?>['a', 'b'])
        ..jsWrite('datasets', <Object?>[dataset]);
      final root = ChartConfigurationScope()
        ..jsWrite('type', 'line')
        ..jsWrite('data', data)
        ..jsWrite('options', <String, Object?>{'responsive': false});
      final chart = _chart(root);
      expect(_controllerOf(chart).getDataset(), same(dataset));
      expect(_controllerOf(chart).getContext(1)['raw'], 2.0);
    });

    test('a chart subclass keeps its data getter', () {
      final canvas = UiCanvasElement(width: 320, height: 200);
      final chart = _DataChart(canvas, _rawConfig(_maps(_points())));
      addTearDown(() {
        chart
          ..replacement = null
          ..destroy();
        canvas.getContext2d().dispose();
      });
      final controller = _controllerOf(chart);
      final mine = <String, Object?>{'data': <Object?>[]};
      final before = chart.reads;
      chart.replacement = <String, Object?>{
        'datasets': <Object?>[mine],
      };
      expect(controller.getDataset(), same(mine));
      expect(chart.reads, greaterThan(before));
    });

    test('a controller subclass keeps its getDataset in a context', () {
      final chart = _chart(
        _rawConfig(<Object?>[1, 2], type: 'plumbing-dataset', parsing: true)
          ..['options'] = <String, Object?>{
            'responsive': false,
            'animation': false,
            'scales': <String, Object?>{
              'x': <String, Object?>{'type': 'category'},
              'y': <String, Object?>{'type': 'linear'},
            },
          },
      );
      final controller = _controllerOf(chart) as _DatasetCountController
        ..getContext(0);
      final before = controller.reads;
      controller.getContext(0);
      expect(controller.reads, before + 1);
    });
  });

  group('parsedValueOf', () {
    test('a data point and a Map give the name read', () {
      final items = <typed.DataPoint>[
        typed.DataPoint(1, 2),
        typed.DataPoint(1, null),
        typed.DataPoint.time(DateTime.utc(2026), 2),
        typed.DataPoint.label('a', 2),
        typed.DataPoint.bubble(1, 2, 3),
      ];
      for (final item in items) {
        for (final (axis, key) in const <(ScaleAxis, String)>[
          (XAxis(), 'x'),
          (YAxis(), 'y'),
          (RAxis(), 'r'),
        ]) {
          final value = parsedValueOf(item, axis);
          expect(value, same(jsGetKey(item, key)), reason: '$item $key');
        }
      }
      expect(parsedValueOf(items[1], const YAxis()), isNull);
      expect(parsedValueOf(items[0], const RAxis()), same(undefined));
      expect(parsedValueOf(items[4], const RAxis()), 3);
    });

    test('another item reads by name', () {
      final map = <String, Object?>{'x': 1.0, 'y': null, 'extra': 'e'};
      expect(parsedValueOf(map, const XAxis()), 1.0);
      expect(parsedValueOf(map, const YAxis()), isNull);
      expect(parsedValueOf(map, const RAxis()), same(undefined));
      // An axis of another class has no key (row adapt-axis-objects).
      expect(parsedValueOf(map, _OtherAxis()), same(undefined));
      expect(parsedValueOf(4.0, const XAxis()), same(undefined));
      expect(parsedValueOf(false, const YAxis()), same(undefined));
      expect(
        () => parsedValueOf(null, const XAxis()),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => parsedValueOf(undefined, const XAxis()),
        throwsA(isA<TypeError>()),
      );
      final parsed = ParsedItem.of(const XAxis(), 1.0, const YAxis(), null);
      expect(parsedValueOf(parsed, const XAxis()), 1.0);
      expect(parsedValueOf(parsed, const YAxis()), isNull);
      expect(parsedValueOf(parsed, const RAxis()), same(undefined));
    });

    test('a chart of points and of Maps with extra keys draw the same', () {
      final points = _points();
      final extras = <Object?>[
        for (final point in points)
          <String, Object?>{'x': point.x, 'y': point.y, 'extra': 'e'},
      ];
      final a = _chart(_rawConfig(points));
      final b = _chart(_rawConfig(extras));
      expect(_geometry(a), _geometry(b));
    });

    test('parsing keys read the same from a point and from a Map', () {
      final points = [typed.DataPoint(1, 5), typed.DataPoint(2, 6)];
      Map<String, Object?> parsingConfig(List<Object?> data) => _rawConfig(
        data,
        parsing: true,
        dataset: {
          'parsing': <String, Object?>{'xAxisKey': 'y', 'yAxisKey': 'x'},
        },
      );
      final a = _chart(parsingConfig(points));
      final b = _chart(parsingConfig(_maps(points)));
      expect(_geometry(a), _geometry(b));
      expect(_parsedOf(a.getDatasetMeta(0)), _parsedOf(b.getDatasetMeta(0)));
      expect(dataItemValue(points[0], 'x'), 1.0);
      expect(dataItemValue(points[0], 'y'), 5.0);
      expect(dataItemValue(points[0], 'r'), same(undefined));
    });
  });

  group('clearStacks', () {
    Map<String, Object?> stackedConfig(
      List<Object?> first,
      List<Object?> second,
    ) => <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{'data': first},
          <String, Object?>{'data': second},
        ],
      },
      'options': _options(parsing: false, stacked: true),
    };

    List<typed.DataPoint> pointsOf(double y, [double x = 1]) => [
      typed.DataPoint(x, y),
      typed.DataPoint(x + 1, y + 1),
    ];

    /// The stack entry of the axis `y` of [item].
    StackEntry entryOf(Object? item) =>
        axisStackOf(stacksOf(item), const YAxis())! as StackEntry;

    final forms = <String, List<Object?> Function(List<typed.DataPoint>)>{
      'a List of points': (points) => points,
      'a plain List of points': (points) => <Object?>[...points],
      'a List of Maps': _maps,
    };

    for (final MapEntry(key: name, value: form) in forms.entries) {
      test('$name: a replaced List leaves its stack values', () {
        final first = form(pointsOf(1));
        final chart = _chart(stackedConfig(first, form(pointsOf(5))));
        final before = _geometry(chart);
        expect(entryOf(first[0]).datasetValues.hasIndex(0), isTrue);
        final dataset =
            (chart.data as Map<String, Object?>)['datasets']! as List<Object?>;
        // Other x values: a stack entry belongs to its index value.
        (dataset[0]! as Map<String, Object?>)['data'] = form(pointsOf(2, 5));
        chart.update();
        expect(_geometry(chart), isNot(before));
        expect(entryOf(first[0]).datasetValues.hasIndex(0), isFalse);
        expect(entryOf(first[0]).datasetValues.hasIndex(1), isTrue);
      });
    }

    test('the forms give the same stacked geometry', () {
      final results = [
        for (final form in forms.values)
          _geometry(
            _chart(stackedConfig(form(pointsOf(1)), form(pointsOf(5)))),
          ),
      ];
      expect(results[1], results[0]);
      expect(results[2], results[0]);
    });

    test('points of an unstacked chart are unaffected by a new List', () {
      final points = _points();
      final chart = _chart(_rawConfig(points));
      final next = _points();
      final datasets =
          (chart.data as Map<String, Object?>)['datasets']! as List<Object?>;
      final before = _geometry(chart);
      (datasets[0]! as Map<String, Object?>)['data'] = next;
      chart.update();
      expect(chart.getDatasetMeta(0).parsed, same(next));
      expect(_geometry(chart), before);
      expect(stacksOf(points[0]), isNull);
      expect(stacksOf(next[0]), isNull);
    });
  });

  group('stacksOf', () {
    test('a parsed item without stacks gives undefined', () {
      final item = ParsedItem.of(const XAxis(), 1.0, const YAxis(), 2.0);
      expect(stacksOf(item), same(undefined));
      expect(item['_stacks'], same(undefined));
    });

    test('a parsed item with stacks gives them, also after a delete', () {
      final stacks = ItemStacks();
      final item = ParsedItem()..stacks = stacks;
      expect(stacksOf(item), same(stacks));
      item.jsDelete('_stacks');
      expect(stacksOf(item), same(undefined));
      item.stacks = null;
      expect(stacksOf(item), isNull);
    });

    test('a value of another class that user code wrote reads by name', () {
      final map = <String, Object?>{};
      final item = ParsedItem()..['_stacks'] = map;
      expect(stacksOf(item), same(map));
      item['_stacks'] = 5.0;
      expect(stacksOf(item), 5.0);
      item['_stacks'] = null;
      expect(stacksOf(item), isNull);
      item['_stacks'] = undefined;
      expect(stacksOf(item), same(undefined));
    });

    test('a data item keeps the reads of its class', () {
      final map = <String, Object?>{'_stacks': 1};
      expect(stacksOf(map), 1);
      expect(stacksOf(<String, Object?>{}), isNull);
      expect(stacksOf(<Object?>[]), isNull);
      expect(stacksOf(4.0), same(undefined));
      expect(stacksOf('text'), same(undefined));
      expect(() => stacksOf(null), throwsA(isA<TypeError>()));
    });
  });

  group('the presized parse lists', () {
    Map<String, Object?> lineConfig(
      List<Object?> data, {
      Object? xType = 'linear',
      Object? yType = 'linear',
      String type = 'line',
    }) => <String, Object?>{
      'type': type,
      'data': <String, Object?>{
        'labels': <Object?>['a', 'b', 'c', 'd'],
        'datasets': <Object?>[
          <String, Object?>{'data': data},
        ],
      },
      'options': _options(xType: xType, yType: yType),
    };

    /// `parse(0, count)` of [meta] into [parsed].
    Object parseInto(Chart chart, List<Object?> parsed, double count) {
      final meta = chart.getDatasetMeta(0)..parsed = parsed;
      _controllerOf(chart).parse(0, count);
      return _parsedOf(meta);
    }

    test('a plain List, another class and a custom List give one result', () {
      for (final data in <List<Object?>>[
        <Object?>[1.0, 2.0, 3.0, 4.0],
        <Object?>[4.0, 3.0, 2.0, 1.0],
        <Object?>[1.0, null, -0.0, 4.0],
        <double>[1, 2, 3, 4],
      ]) {
        final chart = _chart(
          lineConfig(<Object?>[...data], xType: 'category'),
        );
        final plain = parseInto(chart, <Object?>[], 4);
        expect(chart.getDatasetMeta(0).parsed.length, 4);
        expect(
          chart.getDatasetMeta(0).parsed.runtimeType,
          <Object?>[].runtimeType,
        );
        chart.getDatasetMeta(0).sorted = false;
        // The growth of a List that is not the plain one.
        final typedList = parseInto(chart, <ParsedItem>[], 4);
        expect(chart.getDatasetMeta(0).parsed, isA<List<ParsedItem>>());
        final custom = parseInto(chart, _CustomObjects(), 4);
        expect(chart.getDatasetMeta(0).parsed, isA<_CustomObjects>());
        // A List with old items: writes by index.
        final over = parseInto(chart, chart.getDatasetMeta(0).parsed, 4);
        expect(typedList, plain);
        expect(custom, plain);
        expect(over, plain);
      }
    });

    test('a part of the range keeps the items around it', () {
      final chart = _chart(
        lineConfig(<Object?>[1.0, 2.0, 3.0, 4.0], xType: 'category'),
      );
      final meta = chart.getDatasetMeta(0);
      final before = List<Object?>.of(meta.parsed);
      _controllerOf(chart).parse(1, 2);
      expect(meta.parsed.length, 4);
      expect(meta.parsed[0], same(before[0]));
      expect(meta.parsed[3], same(before[3]));
      expect(meta.parsed[1], isNot(same(before[1])));
      meta.parsed = <Object?>[before[0]];
      _controllerOf(chart).parse(1, 2);
      expect(meta.parsed.length, 3);
      expect(meta.parsed[0], same(before[0]));
    });

    test('a start past the end of an empty List throws', () {
      final chart = _chart(
        lineConfig(<Object?>[1.0, 2.0, 3.0, 4.0], xType: 'category'),
      );
      final meta = chart.getDatasetMeta(0)..parsed = <Object?>[];
      expect(
        () => _controllerOf(chart).parse(1, 2),
        throwsA(isA<RangeError>()),
      );
      expect(meta.parsed, isEmpty);
    });

    test('a shorter range keeps the items after it', () {
      final chart = _chart(
        lineConfig(<Object?>[1.0, 2.0, 3.0, 4.0], xType: 'category'),
      );
      final meta = chart.getDatasetMeta(0);
      final before = List<Object?>.of(meta.parsed);
      expect(meta.parsed.runtimeType, <Object?>[].runtimeType);
      _controllerOf(chart).parse(0, 2);
      expect(meta.parsed.length, 4);
      expect(meta.parsed[0], isNot(same(before[0])));
      expect(meta.parsed[2], same(before[2]));
      expect(meta.parsed[3], same(before[3]));
    });

    test('a value that can run user code sees the List of upstream', () {
      final chart = _chart(
        lineConfig(<Object?>[1.0, 2.0, 3.0], xType: 'plumbing-object-linear'),
      );
      final meta = chart.getDatasetMeta(0);
      final log = <int>[];
      _ObjectLinear.onRead = () => log.add(meta.parsed.length);
      addTearDown(() => _ObjectLinear.onRead = null);

      // Two reads at each comparison, from the second item on.
      meta.parsed = <Object?>[];
      _controllerOf(chart).parse(0, 3);
      expect(log, [2, 2, 3, 3]);
      expect(meta.parsed.length, 3);
      final plain = [for (final item in meta.parsed) (item! as ParsedItem).y];

      log.clear();
      meta.parsed = _CustomObjects();
      _controllerOf(chart).parse(0, 3);
      expect(log, [2, 2, 3, 3]);
      expect([for (final item in meta.parsed) (item! as ParsedItem).y], plain);
    });

    test('a user parse with fewer items leaves the same List', () {
      final chart = _chart(
        lineConfig(<Object?>[1.0, 2.0, 3.0], type: 'plumbing-short'),
      );
      final meta = chart.getDatasetMeta(0);
      _ShortController.short = true;
      addTearDown(() => _ShortController.short = false);
      meta.parsed = <Object?>[];
      expect(
        () => _controllerOf(chart).parse(0, 3),
        throwsA(isA<RangeError>()),
      );
      expect(meta.parsed.length, 1);
      _ShortController.short = false;
      _controllerOf(chart).parse(0, 3);
    });

    test('a user parse with a custom List sees the List of upstream', () {
      final chart = _chart(
        lineConfig(<Object?>[1.0, 2.0, 3.0], type: 'plumbing-short'),
      );
      final meta = chart.getDatasetMeta(0)..parsed = <Object?>[];
      final log = <int>[];
      _ShortController.onItemRead = () => log.add(meta.parsed.length);
      addTearDown(() => _ShortController.onItemRead = null);
      _controllerOf(chart).parse(0, 3);
      expect(log, [0, 1, 2]);
      expect(meta.parsed.length, 3);
    });

    test('the parse functions give fresh growable Lists', () {
      final data = <Object?>[1.0, 2.0];
      final chart = _chart(lineConfig(data, xType: 'category'));
      final meta = chart.getDatasetMeta(0);
      final controller = _controllerOf(chart);
      final rows = <Object?>[
        <Object?>[1.0, 2.0],
      ];
      final objects = <Object?>[
        <String, Object?>{'x': 1.0, 'y': 2.0},
      ];
      final parsed = [
        controller.parsePrimitiveData(meta, data, 0, 2),
        controller.parseArrayData(meta, rows, 0, 1),
        controller.parseObjectData(meta, objects, 0, 1),
      ];
      for (final list in parsed) {
        expect(nativeDataUpdateList(list), isTrue);
        list.add(ParsedItem());
      }
      expect(jsKeys(parsed[1][0]), ['x', 'y']);
      expect(jsKeys(parsed[2][0]), ['x', 'y']);
      final again = controller.parsePrimitiveData(meta, data, 0, 2);
      expect(again[0], isNot(same(parsed[0][0])));
    });

    test('a count below 0 is an empty range, and NaN throws', () {
      final data = <Object?>[1.0, 2.0];
      final chart = _chart(lineConfig(data, xType: 'category'));
      final meta = chart.getDatasetMeta(0);
      final controller = _controllerOf(chart);
      final rows = <Object?>[
        <Object?>[1.0, 2.0],
      ];
      final objects = <Object?>[
        <String, Object?>{'x': 1.0, 'y': 2.0},
      ];
      expect(controller.parsePrimitiveData(meta, data, 0, -1), isEmpty);
      expect(controller.parseArrayData(meta, rows, 0, -1), isEmpty);
      expect(controller.parseObjectData(meta, objects, 0, -1), isEmpty);
      expect(
        () => controller.parsePrimitiveData(meta, data, 0, double.nan),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => controller.parseArrayData(meta, rows, 0, double.nan),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => controller.parseObjectData(meta, objects, 0, double.nan),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('the scales parse in the order of upstream', () {
      final chart = _chart(
        lineConfig(
          <Object?>[1.0, 2.0],
          xType: 'plumbing-order-linear',
          yType: 'plumbing-order-linear',
        ),
      );
      final meta = chart.getDatasetMeta(0);
      final controller = _controllerOf(chart);
      _OrderLinear.log.clear();
      controller.parsePrimitiveData(meta, <Object?>[1.0, 2.0], 0, 2);
      expect(_OrderLinear.log, ['x0.0', 'y0.0', 'x1.0', 'y1.0']);
      _OrderLinear.log.clear();
      controller.parseArrayData(
        meta,
        <Object?>[
          <Object?>[0.0, 0.0],
          <Object?>[1.0, 2.0],
        ],
        1,
        1,
      );
      expect(_OrderLinear.log, ['x1.0', 'y1.0']);
      _OrderLinear.log.clear();
      controller.parseObjectData(
        meta,
        <Object?>[
          <String, Object?>{'x': 1.0, 'y': 2.0},
          <String, Object?>{'x': 3.0, 'y': 4.0},
        ],
        0,
        2,
      );
      expect(_OrderLinear.log, ['x0.0', 'y0.0', 'x1.0', 'y1.0']);
    });

    test('a key that is not a string throws in the loop', () {
      final data = <Object?>[1.0];
      final chart = _chart(lineConfig(data, xType: 'category'));
      final meta = chart.getDatasetMeta(0);
      final controller = _controllerOf(chart)
        ..parsing = <String, Object?>{'xAxisKey': 5};
      addTearDown(() => controller.parsing = false);
      expect(
        controller.parseObjectData(meta, const <Object?>[], 0, 0),
        isEmpty,
      );
      expect(
        () => controller.parseObjectData(
          meta,
          <Object?>[
            <String, Object?>{'x': 1.0, 'y': 2.0},
          ],
          0,
          1,
        ),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('the doughnut parse', () {
    Map<String, Object?> doughnutConfig(List<Object?> data) =>
        <String, Object?>{
          'type': 'doughnut',
          'data': <String, Object?>{
            'labels': <Object?>['a', 'b', 'c'],
            'datasets': <Object?>[
              <String, Object?>{'data': data},
            ],
          },
          'options': <String, Object?>{'responsive': false, 'animation': false},
        };

    test('numbers in a typed List and in a plain List give one result', () {
      final a = _chart(doughnutConfig(<double>[1, 2, 3]));
      final b = _chart(doughnutConfig(<Object?>[1.0, 2.0, 3.0]));
      expect(nativeDataUpdateList(<double>[]), isTrue);
      for (final chart in [a, b]) {
        final meta = chart.getDatasetMeta(0);
        expect(meta.parsed, <Object?>[1.0, 2.0, 3.0]);
        expect(meta.parsed.runtimeType, <Object?>[].runtimeType);
        meta.parsed = <Object?>[];
        _controllerOf(chart).parse(0, 3);
        expect(meta.parsed, <Object?>[1.0, 2.0, 3.0]);
        meta.parsed = <Object?>[];
        _controllerOf(chart).parse(1, 0);
        expect(meta.parsed, isEmpty);
      }
    });

    test('a value that can run user code sees the List of upstream', () {
      final log = <int>[];
      final data = <Object?>[
        for (final text in ['1', '2', '3'])
          _Logged(text, () => _ObjectLinear.onRead?.call()),
      ];
      final chart = _chart(doughnutConfig(data));
      final meta = chart.getDatasetMeta(0);
      _ObjectLinear.onRead = () => log.add(meta.parsed.length);
      addTearDown(() => _ObjectLinear.onRead = null);
      meta.parsed = <Object?>[];
      _controllerOf(chart).parse(0, 3);
      expect(log, [0, 1, 2]);
      expect(meta.parsed, <Object?>[1.0, 2.0, 3.0]);
    });

    test('a custom List of numbers sees the List of upstream', () {
      final log = <int>[];
      final data = _ObservedNumbers([1, 2, 3]);
      final chart = _chart(doughnutConfig(data));
      final meta = chart.getDatasetMeta(0);
      expect(data, isA<List<num?>>());
      data.onRead = () => log.add(meta.parsed.length);
      meta.parsed = <Object?>[];
      _controllerOf(chart).parse(0, 3);
      // The first read is the `isObject` test of the first item.
      expect(log, [0, 0, 1, 2]);
      data.onRead = null;
    });
  });
}

/// A custom List of the parsed items: not the plain List of `_dataCheck`.
final class _CustomObjects extends ListBase<Object?> {
  final List<Object?> items = [];
  @override
  int get length => items.length;
  @override
  set length(int value) => items.length = value;
  @override
  Object? operator [](int index) => items[index];
  @override
  void operator []=(int index, Object? value) => items[index] = value;
}

/// The own keys of the parsed item [item].
List<String> jsKeys(ParsedItem item) => item.jsKeys();

/// The write and the delete of a property of a typed scope or of a Map.
extension type JsObjectLike(Object object) {
  Object? operator [](String name) => object is OptionScope
      ? (object as OptionScope).jsRead(name)
      : (object as Map<String, Object?>)[name];

  void operator []=(String name, Object? value) {
    if (object is OptionScope) {
      (object as OptionScope).jsWrite(name, value);
    } else {
      (object as Map<String, Object?>)[name] = value;
    }
  }

  void remove(String name) {
    if (object is OptionScope) {
      (object as OptionScope).jsDelete(name);
    } else {
      (object as Map<String, Object?>).remove(name);
    }
  }
}

/// An axis of a class that the core does not know.
final class _OtherAxis implements ScaleAxis {}
