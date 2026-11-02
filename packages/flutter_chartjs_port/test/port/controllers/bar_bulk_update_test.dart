// Original code, not ported from Chart.js: numeric bulk bar update twins.
@TestOn('vm')
library;

import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/bar_bulk_update.dart';
import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show controllerArgs;
import 'package:flutter_chartjs_port/src/core/core.scale.dart' show scaleCfgArg;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/options/props.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

class _ReferenceChart extends Chart {
  _ReferenceChart(super.item, super.userConfig);
  @override
  bool get supportsNativeBarIndexReads => true;
  @override
  bool get supportsBulkBarUpdate => false;
}

// Test-only opt-in: the counter invokes no callbacks and changes no chart
// state. The writes still use the ordinary native implementation.
class _ProbeBar extends BarElement {
  int bulkWrites = 0;
  @override
  bool get supportsBulkBarWrites => true;
  @override
  void writeBulkBar({
    required bool horizontal,
    required double base,
    required double x,
    required double y,
    required double height,
    required double width,
    required Object options,
    required BorderSkipped skipped,
    required double inflate,
  }) {
    bulkWrites++;
    super.writeBulkBar(
      horizontal: horizontal,
      base: base,
      x: x,
      y: y,
      height: height,
      width: width,
      options: options,
      skipped: skipped,
      inflate: inflate,
    );
  }
}

class _CustomBar extends BarElement {
  final List<String> writes = [];
  @override
  void operator []=(String key, Object? value) {
    writes.add(key);
    super[key] = value;
  }
}

class _CustomLinear extends LinearScale {
  _CustomLinear(super.cfg);
  int projections = 0;
  static final value = JsClass(
    'BulkCustomLinear',
    superclass: LinearScale.jsClass,
    statics: {'id': 'bulk-custom-linear'},
    construct: (_, args) => _CustomLinear(scaleCfgArg(args)),
  );
  @override
  double getPixelForValue(Object? value, [double? index]) {
    projections++;
    return super.getPixelForValue(value, index);
  }
}

class _CustomController extends BarController {
  _CustomController(super.chart, super.datasetIndex, super.newTarget);
  int writes = 0;
  static final value = JsClass(
    'BulkCustomController',
    superclass: BarController.jsClass,
    statics: {'id': 'bulk-custom-controller'},
    construct: (target, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return _CustomController(chart, datasetIndex, target);
    },
  );
  @override
  void updateElement(
    types.Element element,
    double? index,
    Object properties,
    String mode,
  ) {
    writes++;
    super.updateElement(element, index, properties, mode);
  }
}

class _MutationBar extends BarElement {
  void Function()? afterWrite;
  @override
  void operator []=(String key, Object? value) {
    super[key] = value;
    if (key == 'inflateAmount') afterWrite?.call();
  }
}

Map<String, Object?> _config({
  bool horizontal = false,
  bool visible = false,
  List<Object?>? values,
  Map<String, Object?> extra = const {},
}) => {
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <String>['a', 'b', 'c', 'd', 'e', 'f'],
    'datasets': <Object?>[
      <String, Object?>{
        'data': values ?? <Object?>[1.0, 0.0, -0.0, -2.0, 3.0, 4.0],
        'backgroundColor': const ui.Color(0x803366AA),
        'borderWidth': 1.0,
        ...extra,
      },
    ],
  },
  'options': <String, Object?>{
    'responsive': false,
    'animation': false,
    'indexAxis': horizontal ? 'y' : 'x',
    'plugins': <String, Object?>{'legend': false, 'tooltip': false},
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'type': horizontal ? 'linear' : 'category',
        'display': visible,
        if (horizontal) ...{'min': -4.0, 'max': 10.0},
      },
      'y': <String, Object?>{
        'type': horizontal ? 'category' : 'linear',
        'display': visible,
        if (!horizontal) ...{'min': -4.0, 'max': 10.0},
      },
    },
  },
};
Map<String, Object?> _dataset(Map<String, Object?> cfg) =>
    ((cfg['data']! as Map<String, Object?>)['datasets']! as List<Object?>)[0]!
        as Map<String, Object?>;
Map<String, Object?> _axis(Map<String, Object?> cfg, String key) =>
    ((cfg['options']! as Map<String, Object?>)['scales']!
            as Map<String, Object?>)[key]!
        as Map<String, Object?>;
Chart _chart(Object cfg, {bool reference = false}) {
  final canvas = UiCanvasElement(width: 640, height: 400);
  final chart = reference ? _ReferenceChart(canvas, cfg) : Chart(canvas, cfg);
  addTearDown(chart.destroy);
  return chart;
}

List<_ProbeBar> _probes(Chart chart) {
  final data = chart.getDatasetMeta(0).data;
  final result = <_ProbeBar>[];
  for (var i = 0; i < data.length; i++) {
    final bar = _ProbeBar();
    data[i] = bar;
    result.add(bar);
  }
  return result;
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

Object _observe(Chart chart) => [
  for (final e in chart.getDatasetMeta(0).data)
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
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([
    BarController.jsClass,
    BarElement.jsClass,
    CategoryScale.jsClass,
    LinearScale.jsClass,
  ]);

  for (final horizontal in [false, true]) {
    for (final visible in [false, true]) {
      test('numeric bulk writes and exact geometry $horizontal/$visible', () {
        final ca = _config(horizontal: horizontal, visible: visible);
        final cb = _config(horizontal: horizontal, visible: visible);
        final a = _chart(ca);
        final b = _chart(cb, reference: true);
        final probes = _probes(a);
        for (var step = 0; step < 3; step++) {
          if (step == 1) {
            a.toggleDataVisibility(2);
            b.toggleDataVisibility(2);
          }
          if (step == 2) {
            a.resize(420, 320);
            b.resize(420, 320);
          }
          a.update('none');
          b.update('none');
          expect(_observe(a), _observe(b));
        }
        expect(probes.first.bulkWrites, 0);
        expect(probes.skip(1).every((p) => p.bulkWrites == 3), isTrue);
        expect(
          identical(probes[1].borderSkipped, probes[2].borderSkipped),
          isFalse,
        );
      });
    }
  }

  test('numeric bases, border edges, dimensions and reversal match', () {
    for (final horizontal in [false, true]) {
      for (final edge in <Object?>[
        false,
        true,
        'start',
        'end',
        'left',
        'right',
        'top',
        'bottom',
        'middle',
        'odd',
      ]) {
        for (final base in [-0.0, 0.0, 2.0]) {
          final extra = <String, Object?>{
            'base': base,
            'borderSkipped': edge,
            'barThickness': 7.0,
            'maxBarThickness': 5.0,
            'inflateAmount': 0.33,
          };
          final ca = _config(
            horizontal: horizontal,
            visible: true,
            extra: extra,
          );
          final cb = _config(
            horizontal: horizontal,
            visible: true,
            extra: extra,
          );
          _axis(ca, horizontal ? 'x' : 'y')['reverse'] = true;
          _axis(cb, horizontal ? 'x' : 'y')['reverse'] = true;
          final a = _chart(ca);
          final b = _chart(cb, reference: true);
          a.update('none');
          b.update('none');
          expect(_observe(a), _observe(b));
        }
      }
    }
  });

  test(
    'preflight rejects late null/NaN/floating values without bulk writes',
    () {
      for (final bad in <Object?>[
        null,
        double.nan,
        double.infinity,
        <double>[1, 3],
      ]) {
        final values = <Object?>[1.0, 2.0, 3.0, 4.0, 5.0, bad];
        final a = _chart(_config(values: values));
        final b = _chart(
          _config(values: List<Object?>.of(values)),
          reference: true,
        );
        final probes = _probes(a);
        a.update('none');
        b.update('none');
        expect(probes.every((p) => p.bulkWrites == 0), isTrue);
        expect(_observe(a), _observe(b));
      }
    },
  );

  test('late custom element keeps all ordinary property interceptions', () {
    final a = _chart(_config());
    final b = _chart(_config(), reference: true);
    final probes = _probes(a);
    final customA = _CustomBar();
    final customB = _CustomBar();
    a.getDatasetMeta(0).data.last = customA;
    b.getDatasetMeta(0).data.last = customB;
    a.update('none');
    b.update('none');
    expect(probes.every((p) => p.bulkWrites == 0), isTrue);
    expect(customA.writes, customB.writes);
    expect(customA.writes, isNotEmpty);
    expect(_observe(a), _observe(b));
  });

  test('scriptable colors and grid widths keep every callback', () {
    for (final grid in [false, true]) {
      final charts = <Chart>[];
      final logs = <List<Object?>>[];
      List<_ProbeBar>? probes;
      for (final reference in [false, true]) {
        final cfg = _config(visible: grid);
        final calls = <Object?>[];
        if (grid) {
          double lineWidth(Object? context) {
            calls.add(jsGet(context, 'index'));
            return 1;
          }

          _axis(cfg, 'y')['grid'] = <String, Object?>{'lineWidth': lineWidth};
        } else {
          ui.Color color(Object? context) {
            calls.add(jsGet(context, 'dataIndex'));
            return const ui.Color(0xFF3366AA);
          }

          _dataset(cfg)['backgroundColor'] = color;
        }
        final chart = _chart(cfg, reference: reference);
        if (!reference) probes = _probes(chart);
        calls.clear();
        chart.update('none');
        charts.add(chart);
        logs.add(calls);
      }
      expect(probes!.every((p) => p.bulkWrites == 0), isTrue);
      expect(logs[0], logs[1]);
      expect(logs[0], isNotEmpty);
      expect(_observe(charts[0]), _observe(charts[1]));
    }
  });

  test('partial ranges and reset retain untouched elements and state', () {
    final a = _chart(_config());
    final b = _chart(_config(), reference: true);
    final ma = a.getDatasetMeta(0);
    final mb = b.getDatasetMeta(0);
    final probes = _probes(a);
    ma.controller!.updateElements(ma.data, 1, 3, 'none');
    mb.controller!.updateElements(mb.data, 1, 3, 'none');
    expect(probes.map((p) => p.bulkWrites).toList(), [0, 0, 1, 1, 0, 0]);
    for (var i = 1; i < 4; i++) {
      expect((_observe(a) as List)[i], (_observe(b) as List)[i]);
    }
    ma.controller!.update('reset');
    mb.controller!.update('reset');
    expect(_observe(a), _observe(b));
    expect(probes.map((p) => p.bulkWrites).toList(), [0, 0, 1, 1, 0, 0]);
  });

  test('unsupported scalar modes retain the ordinary update', () {
    for (final extra in <Map<String, Object?>>[
      {'minBarLength': 4.0},
      {'barThickness': 'flex'},
      {'skipNull': true},
      {'base': '0'},
      {'categoryPercentage': -1.0},
      {'inflateAmount': null},
    ]) {
      final a = _chart(_config(extra: extra));
      final b = _chart(_config(extra: extra), reference: true);
      final probes = _probes(a);
      a.update('none');
      b.update('none');
      expect(probes.every((p) => p.bulkWrites == 0), isTrue, reason: '$extra');
      expect(_observe(a), _observe(b));
    }
  });

  test('a scale owned by another chart cannot prove native topology', () {
    final a = _chart(_config());
    final b = _chart(_config());
    final meta = a.getDatasetMeta(0);
    final foreign = b.scales['x']!;
    meta.iScale = foreign;
    expect(a.hasSingleBarIndexLayout(meta.controller!, foreign), isFalse);
    expect((a.scales['y']! as BulkBarScale).hasStaticBulkBarGrid, isTrue);
  });
  test('custom scale projection and controller updates keep their calls', () {
    Chart.register([_CustomLinear.value, _CustomController.value]);
    addTearDown(
      () => Chart.unregister([_CustomLinear.value, _CustomController.value]),
    );
    for (final customController in [false, true]) {
      final ca = _config();
      final cb = _config();
      for (final cfg in [ca, cb]) {
        if (customController) {
          cfg['type'] = 'bulk-custom-controller';
        } else {
          _axis(cfg, 'y')['type'] = 'bulk-custom-linear';
        }
      }
      final a = _chart(ca);
      final b = _chart(cb, reference: true);
      final probes = _probes(a);
      if (customController) {
        (a.getDatasetMeta(0).controller! as _CustomController).writes = 0;
        (b.getDatasetMeta(0).controller! as _CustomController).writes = 0;
      } else {
        (a.scales['y']! as _CustomLinear).projections = 0;
        (b.scales['y']! as _CustomLinear).projections = 0;
      }
      a.update('none');
      b.update('none');
      expect(probes.every((p) => p.bulkWrites == 0), isTrue);
      expect(_observe(a), _observe(b));
      if (customController) {
        expect(
          (a.getDatasetMeta(0).controller! as _CustomController).writes,
          6,
        );
        expect(
          (b.getDatasetMeta(0).controller! as _CustomController).writes,
          6,
        );
      } else {
        expect(
          (a.scales['y']! as _CustomLinear).projections,
          (b.scales['y']! as _CustomLinear).projections,
        );
      }
    }
  });

  test(
    'mutation in the first ordinary item is observed without resolving a guard',
    () {
      final charts = <Chart>[];
      final counts = <int>[];
      for (final reference in [false, true]) {
        final cfg = _config();
        final chart = _chart(cfg, reference: reference);
        final probes = _probes(chart);
        var calls = 0;
        double percentage(Object? _) {
          calls++;
          return 0.5;
        }

        final first = _MutationBar()
          ..afterWrite = () {
            chart
                .getDatasetMeta(0)
                .controller!
                .options
                .jsDelete('categoryPercentage');
            _dataset(cfg)['categoryPercentage'] = percentage;
          };
        chart.getDatasetMeta(0).data[0] = first;
        chart.update('none');
        expect(probes.every((p) => p.bulkWrites == 0), isTrue);
        charts.add(chart);
        counts.add(calls);
      }
      expect(counts[0], greaterThan(0));
      expect(counts[0], counts[1]);
      expect(_observe(charts[0]), _observe(charts[1]));
    },
  );
}
