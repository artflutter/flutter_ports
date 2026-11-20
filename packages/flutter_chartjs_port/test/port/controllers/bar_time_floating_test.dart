// Original code, not ported from Chart.js: time axis and floating bar twins.
@TestOn('vm')
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/parsed_items.dart';

// The ordinary path of Chart.js ADR 0157: a subclass of Chart takes neither
// the native label source, nor the index proof, nor the bulk update.
class _ReferenceChart(super.item, super.userConfig) extends Chart {
  @override
  bool get supportsNativeBarIndexReads => false;
  @override
  bool get supportsBulkBarUpdate => false;
}

class _ProbeBar() extends BarElement {
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
    required ElementOptions options,
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

class _SubTime(super.cfg) extends TimeScale;

Chart _chart(Object cfg, {bool reference = false}) {
  final canvas = UiCanvasElement(width: 640, height: 400);
  final chart = reference
      ? _ReferenceChart(canvas, withParsedDataItems(cfg))
      : Chart(canvas, withParsedDataItems(cfg));
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
  if (identical(value, undefined)) return 'undefined';
  if (value is JsObjectFace) {
    return [
      for (final key in value.jsKeys()) [key, _plain(value.jsRead(key))],
    ];
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
        _plain((e as ElementPropertyRead)[key]),
      _plain((e as BarElement).options),
    ],
];

Object _parsed(Chart chart) => [
  for (final item in chart.getDatasetMeta(0).parsed) _plain(item),
];

Object _scales(Chart chart) => [
  for (final scale in chart.scales.values)
    [scale.min, scale.max, for (final tick in scale.ticks!) tick.value],
];

final int _t0 = DateTime.utc(2026).millisecondsSinceEpoch;

Map<String, Object?> _timeConfig({
  required String type,
  required bool horizontal,
  required bool visible,
  required int step,
  Map<String, Object?> extra = const {},
}) {
  final index = horizontal ? 'y' : 'x';
  final value = horizontal ? 'x' : 'y';
  return {
    'type': 'bar',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            for (var i = 0; i < 12; i++)
              <String, Object?>{
                index: DateTime.fromMillisecondsSinceEpoch(
                  // Uneven gaps, so that the smallest gap decides the size.
                  _t0 + i * 60000 + (i.isOdd ? 20000 : 0),
                  isUtc: true,
                ),
                value: i == 4 ? -2.0 : (i * 7 + step * 3) % 11 - 0.0,
              },
          ],
          'backgroundColor': const ChartPaint.solid(ui.Color(0x803366AA)),
          'borderWidth': 1.0,
          'borderSkipped': BorderSkippedEdge.start,
          ...extra,
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'animation': false,
      'indexAxis': horizontal ? const YAxis() : const XAxis(),
      'plugins': <String, Object?>{'legend': false, 'tooltip': false},
      'scales': <String, Object?>{
        index: <String, Object?>{
          'type': type,
          'display': visible ? ScaleDisplay.on : ScaleDisplay.off,
        },
        value: <String, Object?>{
          'type': 'linear',
          'display': visible ? ScaleDisplay.on : ScaleDisplay.off,
          'min': -4.0,
          'max': 12.0,
        },
      },
    },
  };
}

List<String> _labels(int n) => [for (var i = 0; i < n; i++) 'L$i'];

/// Floating pairs among plain values: reversed pairs, pairs that cross zero,
/// pairs at zero, non-finite ends, ints, three items, typed data and items
/// past the labels. The first bar starts at 0: its ordinary update reads the
/// grid line width first, as a visible grid needs before the bulk loop. With
/// [gaps], also a null and an undefined value: then the
/// bulk loop declines, and only the native parse runs.
List<Object?> _floatingData(int step, {bool gaps = false}) => <Object?>[
  <double>[0, 2.0 + step],
  <double>[1.0 + step, 5],
  <double>[5, -3.0 - step],
  <double>[-2, 4],
  <double>[0, 3.0 + step],
  <double>[-0, -2],
  3.0 + step,
  if (gaps) null else 1.5,
  <double>[double.nan, 2],
  <double>[double.infinity, -1],
  <num>[2, 7],
  <int>[-1, -4],
  <Object?>[1.0, 6.0, 9.0],
  Float64List.fromList([2.5, -2.5]),
  -0.0,
  <double>[4, 4],
  if (gaps) undefined else 2,
  <double>[-3, -1.0 - step],
  7,
];

Map<String, Object?> _floatingConfig({
  required bool horizontal,
  required bool visible,
  required int step,
  required List<Object?> data,
  int labels = 16,
  Map<String, Object?> extra = const {},
}) {
  final index = horizontal ? 'y' : 'x';
  final value = horizontal ? 'x' : 'y';
  return {
    'type': 'bar',
    'data': <String, Object?>{
      'labels': _labels(labels),
      'datasets': <Object?>[
        <String, Object?>{
          'data': data,
          'backgroundColor': const ChartPaint.solid(ui.Color(0x803366AA)),
          'borderWidth': 1.0,
          ...extra,
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'animation': false,
      'indexAxis': horizontal ? const YAxis() : const XAxis(),
      'plugins': <String, Object?>{'legend': false, 'tooltip': false},
      'scales': <String, Object?>{
        index: <String, Object?>{
          'type': 'category',
          'display': visible ? ScaleDisplay.on : ScaleDisplay.off,
        },
        value: <String, Object?>{
          'type': 'linear',
          'display': visible ? ScaleDisplay.on : ScaleDisplay.off,
          'min': -6.0,
          'max': 10.0,
        },
      },
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Chart.register([
    BarController.jsClass,
    BarElement.jsClass,
    CategoryScale.jsClass,
    LinearScale.jsClass,
    TimeScale.jsClass,
    TimeSeriesScale.jsClass,
  ]);

  group('time index axis', () {
    for (final type in ['time', 'timeseries']) {
      for (final horizontal in [false, true]) {
        for (final visible in [false, true]) {
          test(
            'bulk bars equal the ordinary loop $type/$horizontal/$visible',
            () {
              Map<String, Object?> config(int step) => _timeConfig(
                type: type,
                horizontal: horizontal,
                visible: visible,
                step: step,
              );
              final ca = config(0);
              final cb = config(0);
              final a = _chart(ca);
              final b = _chart(cb, reference: true);
              final probes = _probes(a);
              for (var step = 0; step < 4; step++) {
                for (final cfg in [ca, cb]) {
                  final dataset =
                      (jsGet(cfg['data'], 'datasets')! as List<Object?>)[0]!
                          as Map<String, Object?>;
                  dataset['data'] =
                      (((config(step)['data']!
                                  as Map<String, Object?>)['datasets']!
                              as List<Object?>)[0]!
                          as Map<String, Object?>)['data'];
                }
                if (step == 2) {
                  a.toggleDataVisibility(3);
                  b.toggleDataVisibility(3);
                }
                if (step == 3) {
                  a.resize(420, 320);
                  b.resize(420, 320);
                }
                a.update(UpdateMode.none);
                b.update(UpdateMode.none);
                expect(_parsed(a), _parsed(b));
                expect(_scales(a), _scales(b));
                expect(_observe(a), _observe(b));
              }
              // Four updates in the mode `none` and the update of the resize
              // in the mode `resize`: with `animation: false` each takes the
              // fast loop (Chart.js ADR 0152).
              expect(probes.first.bulkWrites, 0);
              expect(probes.skip(1).every((p) => p.bulkWrites == 5), isTrue);
            },
          );
        }
      }
    }

    test('options that leave the bulk loop keep equal bars', () {
      for (final extra in <Map<String, Object?>>[
        {'barThickness': BarThickness.flex},
        {'barThickness': const BarThickness.pixels(6), 'base': 1.0},
        {'minBarLength': 4.0},
        {'grouped': false},
        {
          'backgroundColor': <ChartPaint>[
            const ChartPaint.solid(ui.Color(0xffff0000)),
            const ChartPaint.solid(ui.Color(0xff0000ff)),
          ],
        },
      ]) {
        final a = _chart(
          _timeConfig(
            type: 'time',
            horizontal: false,
            visible: true,
            step: 1,
            extra: extra,
          ),
        );
        final b = _chart(
          _timeConfig(
            type: 'time',
            horizontal: false,
            visible: true,
            step: 1,
            extra: extra,
          ),
          reference: true,
        );
        a.update(UpdateMode.none);
        b.update(UpdateMode.none);
        expect(_observe(a), _observe(b), reason: '$extra');
      }
    });

    test('floating bars on a time axis equal the ordinary loop', () {
      Map<String, Object?> config() {
        final cfg = _timeConfig(
          type: 'time',
          horizontal: false,
          visible: true,
          step: 2,
        );
        final dataset =
            (jsGet(cfg['data'], 'datasets')! as List<Object?>)[0]!
                as Map<String, Object?>;
        final points = dataset['data']! as List<Object?>;
        for (var i = 1; i < points.length; i++) {
          final point = points[i]! as Map<String, Object?>;
          final y = point['y']! as double;
          point['y'] = <double>[y - 3, if (i.isOdd) -y else y + 1];
        }
        return cfg;
      }

      final a = _chart(config());
      final b = _chart(config(), reference: true);
      final probes = _probes(a);
      a.update(UpdateMode.none);
      b.update(UpdateMode.none);
      expect(_parsed(a), _parsed(b));
      expect(_scales(a), _scales(b));
      expect(_observe(a), _observe(b));
      expect(probes.skip(1).every((p) => p.bulkWrites == 1), isTrue);
    });

    test('only the exact time scales opt in', () {
      final chart = _chart(
        _timeConfig(type: 'time', horizontal: false, visible: false, step: 0),
      );
      final scale = chart.scales['x']!;
      expect(scale.supportsNativeBarIndexReads, isTrue);
      final sub = _SubTime({
        'id': 'x',
        'type': 'time',
        'ctx': chart.ctx,
        'chart': chart,
      });
      expect(sub.supportsNativeBarIndexReads, isFalse);
    });
  });

  group('floating bars', () {
    for (final gaps in [false, true]) {
      for (final horizontal in [false, true]) {
        for (final visible in [false, true]) {
          test(
            'native parse and bulk bars equal upstream $gaps/$horizontal/$visible',
            () {
              final ca = _floatingConfig(
                horizontal: horizontal,
                visible: visible,
                step: 0,
                data: _floatingData(0, gaps: gaps),
              );
              final cb = _floatingConfig(
                horizontal: horizontal,
                visible: visible,
                step: 0,
                data: _floatingData(0, gaps: gaps),
              );
              final a = _chart(ca);
              final b = _chart(cb, reference: true);
              final probes = _probes(a);
              for (var step = 0; step < 4; step++) {
                for (final cfg in [ca, cb]) {
                  final dataset =
                      (jsGet(cfg['data'], 'datasets')! as List<Object?>)[0]!
                          as Map<String, Object?>;
                  dataset['data'] = _floatingData(step, gaps: gaps);
                }
                if (step == 2) {
                  a.toggleDataVisibility(2);
                  b.toggleDataVisibility(2);
                }
                if (step == 3) {
                  a.resize(420, 320);
                  b.resize(420, 320);
                }
                a.update(UpdateMode.none);
                b.update(UpdateMode.none);
                expect(_parsed(a), _parsed(b));
                expect(_scales(a), _scales(b));
                expect(_observe(a), _observe(b));
                for (var i = 0; i < 19; i++) {
                  final la = a
                      .getDatasetMeta(0)
                      .controller!
                      .getLabelAndValue(i);
                  final lb = b
                      .getDatasetMeta(0)
                      .controller!
                      .getLabelAndValue(i);
                  expect([la.label, la.value], [lb.label, lb.value]);
                }
              }
              expect(probes.first.bulkWrites, 0);
              // A null value declines the whole bulk range (Chart.js ADR 0069).
              // The update of the resize also takes the fast loop (Chart.js
              // ADR 0152).
              expect(
                probes.skip(1).every((p) => p.bulkWrites == (gaps ? 0 : 5)),
                isTrue,
              );
            },
          );
        }
      }
    }

    test('the native parse qualifies pairs only with a floating bar maker', () {
      final data = <List<double>>[
        for (var i = 0; i < 4; i++) <double>[i - 1.0, i + 2.0],
      ];
      final chart = _chart(
        _floatingConfig(
          horizontal: false,
          visible: false,
          step: 0,
          data: data,
          labels: 4,
        ),
      );
      final meta = chart.getDatasetMeta(0);
      final labels = meta.iScale!.getLabels();
      FloatingBar maker(double? start, double? end) => FloatingBar(
        barStart: start ?? 0,
        barEnd: end ?? 0,
        start: start,
        end: end,
        min: 0,
        max: 0,
      );
      expect(
        tryParseNumericCategories(
          meta.iScale!,
          meta.vScale,
          labels,
          data,
          0,
          4,
        ),
        isNull,
      );
      final parsed = tryParseNumericCategories(
        meta.iScale!,
        meta.vScale,
        labels,
        data,
        0,
        4,
        floatingBar: maker,
      )!;
      expect(_plain(parsed[1]), [
        ['x', 1.0],
        ['y', 3.0],
        [
          '_custom',
          [
            ['barStart', 0.0],
            ['barEnd', 3.0],
            ['start', 0.0],
            ['end', 3.0],
            ['min', 0.0],
            ['max', 0.0],
          ],
        ],
      ]);
    });

    test('a typed outer List of pairs takes the native parse', () {
      List<List<double>> data(int step) => [
        for (var i = 0; i < 8; i++) <double>[i - 3.0, step + i - 1.0],
      ];
      final a = _chart(
        _floatingConfig(
          horizontal: false,
          visible: false,
          step: 0,
          data: data(0),
          labels: 8,
          extra: {'base': 2.0},
        ),
      );
      final b = _chart(
        _floatingConfig(
          horizontal: false,
          visible: false,
          step: 0,
          data: data(0),
          labels: 8,
          extra: {'base': 2.0},
        ),
        reference: true,
      );
      final probes = _probes(a);
      a.update(UpdateMode.none);
      b.update(UpdateMode.none);
      expect(_parsed(a), _parsed(b));
      expect(_observe(a), _observe(b));
      expect(probes.skip(1).every((p) => p.bulkWrites == 1), isTrue);
    });

    test('items that are not native pairs keep the ordinary parse', () {
      for (final item in <Object?>[
        <Object?>[1.0, '4'],
        <Object?>[1.0],
        <Object?>[],
        <Object?>[null, 2.0],
        'x',
      ]) {
        final data = <Object?>[
          <double>[1, 3],
          item,
          2.0,
        ];
        final a = _chart(
          _floatingConfig(
            horizontal: false,
            visible: false,
            step: 0,
            data: List.of(data),
            labels: 3,
          ),
        );
        final b = _chart(
          _floatingConfig(
            horizontal: false,
            visible: false,
            step: 0,
            data: List.of(data),
            labels: 3,
          ),
          reference: true,
        );
        a.update(UpdateMode.none);
        b.update(UpdateMode.none);
        expect(_parsed(a), _parsed(b), reason: '$item');
        expect(_observe(a), _observe(b), reason: '$item');
      }
    });

    test('a key that user code wrote into _custom leaves the bulk loop', () {
      final a = _chart(
        _floatingConfig(
          horizontal: false,
          visible: false,
          step: 0,
          data: _floatingData(0),
        ),
      );
      final b = _chart(
        _floatingConfig(
          horizontal: false,
          visible: false,
          step: 0,
          data: _floatingData(0),
        ),
        reference: true,
      );
      final probes = _probes(a);
      a.update(UpdateMode.none);
      b.update(UpdateMode.none);
      expect(probes.skip(1).every((p) => p.bulkWrites == 1), isTrue);
      for (final chart in [a, b]) {
        final item = chart.getDatasetMeta(0).parsed[3]!;
        (item.custom! as JsObjectFace).jsWrite('barStart', '1');
      }
      for (final chart in [a, b]) {
        final meta = chart.getDatasetMeta(0);
        meta.controller!.updateElements(meta.data, 0, meta.data.length, 'none');
      }
      expect(probes.skip(1).every((p) => p.bulkWrites == 1), isTrue);
      expect(_observe(a), _observe(b));
    });

    test('indexed colors on floating bars equal the ordinary loop', () {
      Map<String, Object?> config() => _floatingConfig(
        horizontal: false,
        visible: true,
        step: 1,
        data: _floatingData(1),
        extra: {
          'backgroundColor': <ChartPaint>[
            const ChartPaint.solid(ui.Color(0xffff0000)),
            const ChartPaint.solid(ui.Color(0xff0000ff)),
          ],
        },
      );
      final a = _chart(config());
      final b = _chart(config(), reference: true);
      final probes = _probes(a);
      a.update(UpdateMode.none);
      b.update(UpdateMode.none);
      expect(_parsed(a), _parsed(b));
      expect(_observe(a), _observe(b));
      expect(probes.skip(1).every((p) => p.bulkWrites == 1), isTrue);
    });
  });
}
