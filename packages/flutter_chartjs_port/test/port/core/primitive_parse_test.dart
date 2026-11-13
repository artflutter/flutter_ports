// Original code, not ported from Chart.js: numeric category parsing twins.
@TestOn('vm')
library;

import 'dart:collection';

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show scaleCfgArg;
import 'package:flutter_chartjs_port/src/core/primitive_parse.dart';
import 'package:flutter_chartjs_port/src/options/parsed.dart';
import 'package:flutter_test/flutter_test.dart';

class _ReferenceChart(super.item, super.userConfig) extends Chart {
  @override
  bool get supportsNativeCategoryLabels => false;
}

class _ObservedNumber(final void Function() onConvert) {
  @override
  String toString() {
    onConvert();
    return '2';
  }
}

class _ObservedList(final List<Object?> values) extends ListBase<Object?> {
  int reads = 0;
  @override
  int get length {
    reads++;
    return values.length;
  }

  @override
  set length(int value) => values.length = value;
  @override
  Object? operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, Object? value) => values[index] = value;
}

class _CustomLinear(super.cfg) extends LinearScale {
  int calls = 0;
  static final value = JsClass(
    'ParseObservedLinear',
    superclass: LinearScale.jsClass,
    statics: {'id': 'parse-observed-linear'},
    construct: (_, args) => _CustomLinear(scaleCfgArg(args)),
  );
  @override
  Object? parse(Object? raw, [double? index]) {
    calls++;
    return super.parse(raw, index);
  }
}

class _CustomCategory(super.cfg) extends CategoryScale {
  int calls = 0;
  static final value = JsClass(
    'ParseObservedCategory',
    superclass: CategoryScale.jsClass,
    statics: {'id': 'parse-observed-category'},
    construct: (_, args) => _CustomCategory(scaleCfgArg(args)),
  );
  @override
  double? parse(Object? raw, [double? index]) {
    calls++;
    return super.parse(raw, index);
  }
}

Map<String, Object?> _config({
  String type = 'bar',
  bool horizontal = false,
  List<Object?>? labels,
  List<Object?>? values,
  String category = 'category',
  String linear = 'linear',
  bool stacked = false,
}) => {
  'type': type,
  'data': <String, Object?>{
    'labels': labels ?? <String>['a', 'a', 'c', 'd'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': values ?? <Object?>[1, -0.0, -2.0, 4],
      },
      if (stacked)
        <String, Object?>{
          'data': <Object?>[2, 3, 4, 5],
        },
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'animation': false,
    'indexAxis': horizontal ? const YAxis() : const XAxis(),
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'type': horizontal ? linear : category,
        'stacked': stacked,
      },
      'y': <String, Object?>{
        'type': horizontal ? category : linear,
        'stacked': stacked,
      },
    },
  },
};

Chart _chart(Map<String, Object?> cfg, {bool reference = false}) {
  final canvas = UiCanvasElement(width: 640, height: 400);
  final chart = reference ? _ReferenceChart(canvas, cfg) : Chart(canvas, cfg);
  addTearDown(chart.destroy);
  return chart;
}

List<ParsedItem>? _fast(
  Chart chart,
  List<Object?> values, {
  double start = 0,
  double? count,
}) {
  final meta = chart.getDatasetMeta(0);
  return tryParseNumericCategories(
    meta.iScale!,
    meta.vScale,
    meta.iScale!.getLabels(),
    values,
    start,
    count ?? values.length.toDouble(),
  );
}

Object? _plain(Object? value) {
  if (value is double && value == 0 && value.isNegative) return '-0';
  if (value is JsObjectFace) {
    return [
      for (final key in value.jsKeys()) [key, _plain(value.jsRead(key))],
    ];
  }
  return value;
}

Object _observe(Chart chart) => [
  for (
    var index = 0;
    index < chart.getSortedVisibleDatasetMetas().length;
    index++
  )
    [
      chart.getDatasetMeta(index).sorted,
      for (final item in chart.getDatasetMeta(index).parsed) _plain(item),
      for (final item in chart.getDatasetMeta(index).data) [item.x, item.y],
    ],
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([
    BarController.jsClass,
    LineController.jsClass,
    BarElement.jsClass,
    LineElement.jsClass,
    PointElement.jsClass,
    CategoryScale.jsClass,
    LinearScale.jsClass,
    _CustomLinear.value,
    _CustomCategory.value,
  ]);

  for (final type in ['bar', 'line']) {
    for (final horizontal in [false, true]) {
      test(
        '$type/$horizontal activates and preserves records and geometry',
        () {
          final a = _chart(_config(type: type, horizontal: horizontal));
          final b = _chart(
            _config(type: type, horizontal: horizontal),
            reference: true,
          );
          expect(_fast(a, [1, -0.0, -2, 4]), isNotNull);
          expect(_fast(b, [1, -0.0, -2, 4]), isNull);
          expect(_observe(a), _observe(b));
          final old = List<Object?>.of(a.getDatasetMeta(0).parsed);
          a.update('none');
          b.update('none');
          expect(_observe(a), _observe(b));
          for (var i = 0; i < old.length; i++) {
            expect(identical(old[i], a.getDatasetMeta(0).parsed[i]), isFalse);
          }
        },
      );
    }
  }

  test('null, missing labels and nonfinite values retain null semantics', () {
    Map<String, Object?> cfg() => _config(
      labels: ['a', null, undefined, 'd'],
      values: [
        null,
        undefined,
        double.nan,
        double.infinity,
        -double.infinity,
        2,
      ],
    );
    final a = _chart(cfg());
    final b = _chart(cfg(), reference: true);
    final values = <Object?>[
      null,
      undefined,
      double.nan,
      double.infinity,
      -double.infinity,
      2,
    ];
    final result = _fast(a, values)!;
    expect(result.map((p) => p.x), [0.0, null, null, 3.0, null, null]);
    expect(result.map((p) => p.y), [null, null, null, null, null, 2.0]);
    expect(_observe(a), _observe(b));
  });

  test('partial ranges and native fixed/const numeric lists match', () {
    final chart = _chart(_config());
    for (final values in <List<Object?>>[
      <int>[1, 2, 3, 4],
      // Signed zero is part of the numeric parsing contract.
      // ignore: prefer_int_literals
      List<double>.filled(4, -0.0),
      const <num>[1, 2.5, 3, 4],
    ]) {
      final parsed = _fast(chart, values, start: 1, count: 2)!;
      expect(parsed.map((p) => p.x), [1.0, 2.0]);
      expect(parsed.map((p) => p.y), values.sublist(1, 3));
      expect(_fast(chart, values, start: -1), isNull);
      expect(_fast(chart, values, start: 0.5, count: 1), isNull);
      expect(_fast(chart, values, count: 5), isNull);
      expect(_fast(chart, values, count: 0), isNull);
    }
  });

  test('late unsupported data declines before parsing any item', () {
    final chart = _chart(_config());
    for (final last in <Object?>[
      '4',
      [1, 4],
      {'y': 4},
      true,
    ]) {
      expect(_fast(chart, [1, 2, 3, last]), isNull);
    }
    final observed = _ObservedList([1, 2, 3, 4]);
    expect(_fast(chart, observed, count: 4), isNull);
    expect(observed.reads, 0);
  });

  test('unusual labels retain ordinary category parsing', () {
    for (final label in <Object?>[
      2,
      double.nan,
      ['multiline'],
      true,
    ]) {
      final chart = _chart(_config(labels: ['a', 'b', 'c', label]));
      expect(_fast(chart, [1, 2, 3, 4]), isNull);
    }
  });

  test('floating and coercible values retain the complete ordinary result', () {
    final a = _chart(_config());
    final b = _chart(_config(), reference: true);
    for (final values in <List<Object?>>[
      [
        1,
        '2.5',
        false,
        [3, 7],
      ],
      [1, 2, 3, 'not a number'],
    ]) {
      List<Object?> parse(Chart chart) {
        final meta = chart.getDatasetMeta(0);
        return meta.controller!.parsePrimitiveData(meta, values, 0, 4);
      }

      expect(parse(a).map(_plain), parse(b).map(_plain));
    }
  });

  test('custom label containers keep the ordinary number of reads', () {
    final la = _ObservedList(['a', 'b', 'c', 'd']);
    final lb = _ObservedList(['a', 'b', 'c', 'd']);
    final a = _chart(_config(labels: la));
    final b = _chart(_config(labels: lb), reference: true);
    la.reads = lb.reads = 0;
    a.getDatasetMeta(0).controller!.parse(0, 4);
    b.getDatasetMeta(0).controller!.parse(0, 4);
    expect(la.reads, lb.reads);
    expect(_observe(a), _observe(b));
  });

  test('qualification does not convert a late object or move its mutation', () {
    final labels = <Object?>['a', 'b', 'c', 'd'];
    final chart = _chart(_config(labels: labels));
    var conversions = 0;
    final values = <Object?>[
      1,
      _ObservedNumber(() {
        conversions++;
        labels[2] = null;
      }),
      3,
      4,
    ];
    expect(_fast(chart, values), isNull);
    expect(conversions, 0);
    final meta = chart.getDatasetMeta(0);
    final parsed = meta.controller!.parsePrimitiveData(meta, values, 0, 4);
    expect(conversions, 1);
    expect(parsed.map((p) => p.x), [0.0, 1.0, null, 3.0]);
    expect(parsed.map((p) => p.y), [1.0, 2.0, 3.0, 4.0]);
  });

  test('explicit and axis labels retain source precedence', () {
    for (final explicit in [false, true]) {
      final cfg = _config();
      final data = cfg['data']! as Map<String, Object?>;
      data['xLabels'] = <Object?>['axis', null, 'axis', 'axis'];
      if (explicit) {
        final options = cfg['options']! as Map<String, Object?>;
        final scales = options['scales']! as Map<String, Object?>;
        (scales['x']! as Map<String, Object?>)['labels'] = <Object?>[
          null,
          'explicit',
          'explicit',
          'explicit',
        ];
      }
      final result = _fast(_chart(cfg), [1, 2, 3, 4])!;
      expect(
        result.map((p) => p.x),
        explicit ? [null, 1.0, 2.0, 3.0] : [0.0, null, 2.0, 3.0],
      );
    }
  });

  test('custom numeric and category scales retain all parse calls', () {
    for (final category in [false, true]) {
      final chart = _chart(
        _config(
          category: category ? 'parse-observed-category' : 'category',
          linear: category ? 'linear' : 'parse-observed-linear',
        ),
      );
      final meta = chart.getDatasetMeta(0);
      expect(_fast(chart, [1, 2, 3, 4]), isNull);
      if (category) {
        final scale = meta.iScale! as _CustomCategory..calls = 0;
        meta.controller!.parse(0, 4);
        expect(scale.calls, 4);
      } else {
        final scale = meta.vScale! as _CustomLinear..calls = 0;
        meta.controller!.parse(0, 4);
        expect(scale.calls, 4);
      }
    }
  });

  test('live label and value changes are reparsed on every update', () {
    final ca = _config();
    final cb = _config();
    final a = _chart(ca);
    final b = _chart(cb, reference: true);
    for (final cfg in [ca, cb]) {
      final data = cfg['data']! as Map<String, Object?>;
      data['labels'] = <Object?>['new', null, 'new'];
      final dataset = (data['datasets']! as List).first as Map;
      dataset['data'] = <Object?>[9, 8, 7, 6];
    }
    a.update('none');
    b.update('none');
    expect(_observe(a), _observe(b));
    expect(_fast(a, [9, 8, 7, 6])!.last.x, isNull);
  });

  test('stacked datasets preserve parsed stacks and element geometry', () {
    final a = _chart(_config(stacked: true));
    final b = _chart(_config(stacked: true), reference: true);
    expect(_observe(a), _observe(b));
    a.update('none');
    b.update('none');
    expect(_observe(a), _observe(b));
  });
}
