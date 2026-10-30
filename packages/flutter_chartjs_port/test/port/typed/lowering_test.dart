// Original code, not ported from Chart.js: the lowering twins of the typed API.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/typed/datasets.dart' show lowerDataset;
import 'package:flutter_test/flutter_test.dart';

import 'twin.dart';

// Chart.js ADR 0052, sections 2 and 11: the lowering twins. For each typed
// field, a typed object with that field alone lowers to the Map of its raw
// twin, the form of the Chart.js docs, with the same keys in the same order
// (`jsObjectKeys`). A typed object with all its fields lowers to the twin
// with all keys, in parameter order. The chart reads only the Maps, so equal
// Maps give equal charts.
//
// VM only: the typed files import dart:ui and the painting library.

const Color _red = Color(0xFFFF6384);
const Color _blue = Color(0xFF36A2EB);
const String _redValue = 'rgba(255, 99, 132, 1)';
const String _blueValue = 'rgba(54, 162, 235, 1)';

/// A scriptable color: blue at the data index 1, else red.
Color _colorFor(ChartContext context) => context.dataIndex == 1 ? _blue : _red;

/// The 8 dataset classes, each without a parameter, with the chart type of
/// its controller.
const Map<ChartKind, Dataset> _empty = {
  ChartKind.bar: BarDataset(),
  ChartKind.line: LineDataset(),
  ChartKind.scatter: ScatterDataset(),
  ChartKind.bubble: BubbleDataset(),
  ChartKind.pie: PieDataset(),
  ChartKind.doughnut: DoughnutDataset(),
  ChartKind.polarArea: PolarAreaDataset(),
  ChartKind.radar: RadarDataset(),
};

/// The dataset Map of [dataset] in a chart of its own type.
Map<String, Object?> _lower(Dataset dataset) => lowerDataset(
  dataset,
  _empty.entries
      .firstWhere((entry) => entry.value.runtimeType == dataset.runtimeType)
      .key,
);

/// The cases of the parameters of [Dataset]: a function that sets one
/// parameter with `copyWith`, and the raw twin.
final Map<String, (Dataset Function(Dataset), Map<String, Object?>)> _common = {
  'key': ((d) => d.copyWith(key: const ValueKey('a')), {}),
  'label': ((d) => d.copyWith(label: 'A'), {'label': 'A'}),
  'hidden': ((d) => d.copyWith(hidden: true), {'hidden': true}),
  'order': ((d) => d.copyWith(order: 2), {'order': 2}),
  'backgroundColor': (
    (d) => d.copyWith(backgroundColor: _red),
    {'backgroundColor': _redValue},
  ),
  'backgroundColors': (
    (d) => d.copyWith(backgroundColors: [_red, _blue]),
    {
      'backgroundColor': [_redValue, _blueValue],
    },
  ),
  'backgroundColorFor': (
    (d) => d.copyWith(backgroundColorFor: _colorFor),
    {'backgroundColor': (Object? context, Object? options) => _redValue},
  ),
  'borderColor': (
    (d) => d.copyWith(borderColor: _blue),
    {'borderColor': _blueValue},
  ),
  'borderColors': (
    (d) => d.copyWith(borderColors: [_blue, _red]),
    {
      'borderColor': [_blueValue, _redValue],
    },
  ),
  'borderColorFor': (
    (d) => d.copyWith(borderColorFor: _colorFor),
    {'borderColor': (Object? context, Object? options) => _redValue},
  ),
  'borderWidth': ((d) => d.copyWith(borderWidth: 2), {'borderWidth': 2}),
  'hoverBackgroundColor': (
    (d) => d.copyWith(hoverBackgroundColor: _blue),
    {'hoverBackgroundColor': _blueValue},
  ),
  'hoverBorderColor': (
    (d) => d.copyWith(hoverBorderColor: _red),
    {'hoverBorderColor': _redValue},
  ),
  'hoverBorderWidth': (
    (d) => d.copyWith(hoverBorderWidth: 3),
    {'hoverBorderWidth': 3},
  ),
  'extra': (
    (d) => d.copyWith(extra: {'clip': 5}),
    {'clip': 5},
  ),
};

/// A [LineDataset], a [ScatterDataset] and a [RadarDataset] with the same
/// line style parameters.
List<Dataset> _lineStyle({
  ChartFill? fill,
  double? tension,
  List<double>? borderDash,
  bool? spanGaps,
  bool? showLine,
  bool? stepped,
  double? pointRadius,
  double? pointHoverRadius,
  ChartPointStyle? pointStyle,
  Color? pointBackgroundColor,
  Color? pointBorderColor,
  double? pointBorderWidth,
}) => [
  LineDataset(
    fill: fill,
    tension: tension,
    borderDash: borderDash,
    spanGaps: spanGaps,
    showLine: showLine,
    stepped: stepped,
    pointRadius: pointRadius,
    pointHoverRadius: pointHoverRadius,
    pointStyle: pointStyle,
    pointBackgroundColor: pointBackgroundColor,
    pointBorderColor: pointBorderColor,
    pointBorderWidth: pointBorderWidth,
  ),
  ScatterDataset(
    fill: fill,
    tension: tension,
    borderDash: borderDash,
    spanGaps: spanGaps,
    showLine: showLine,
    stepped: stepped,
    pointRadius: pointRadius,
    pointHoverRadius: pointHoverRadius,
    pointStyle: pointStyle,
    pointBackgroundColor: pointBackgroundColor,
    pointBorderColor: pointBorderColor,
    pointBorderWidth: pointBorderWidth,
  ),
  RadarDataset(
    fill: fill,
    tension: tension,
    borderDash: borderDash,
    spanGaps: spanGaps,
    showLine: showLine,
    stepped: stepped,
    pointRadius: pointRadius,
    pointHoverRadius: pointHoverRadius,
    pointStyle: pointStyle,
    pointBackgroundColor: pointBackgroundColor,
    pointBorderColor: pointBorderColor,
    pointBorderWidth: pointBorderWidth,
  ),
];

/// A [PieDataset] and a [DoughnutDataset] with the same arc parameters,
/// and a [PolarAreaDataset] with the parameters that it has.
List<Dataset> _arcs({
  double? offset,
  double? hoverOffset,
  double? spacing,
  double? weight,
  double? circumference,
  double? rotation,
  ChartLength? cutout,
  ChartLength? radius,
}) => [
  PieDataset(
    offset: offset,
    hoverOffset: hoverOffset,
    spacing: spacing,
    weight: weight,
    circumference: circumference,
    rotation: rotation,
    cutout: cutout,
    radius: radius,
  ),
  DoughnutDataset(
    offset: offset,
    hoverOffset: hoverOffset,
    spacing: spacing,
    weight: weight,
    circumference: circumference,
    rotation: rotation,
    cutout: cutout,
    radius: radius,
  ),
  if (weight == null &&
      circumference == null &&
      rotation == null &&
      cutout == null &&
      radius == null)
    PolarAreaDataset(
      offset: offset,
      hoverOffset: hoverOffset,
      spacing: spacing,
    ),
];

/// The cases of the parameters of the dataset classes, without `data` and
/// `points`: the typed datasets with one parameter and the raw twin.
final Map<String, (List<Dataset>, Map<String, Object?>)> _own = {
  'xAxisID': (
    const [
      BarDataset(xAxisID: 'x2'),
      LineDataset(xAxisID: 'x2'),
      ScatterDataset(xAxisID: 'x2'),
      BubbleDataset(xAxisID: 'x2'),
    ],
    {'xAxisID': 'x2'},
  ),
  'yAxisID': (
    const [
      BarDataset(yAxisID: 'y2'),
      LineDataset(yAxisID: 'y2'),
      ScatterDataset(yAxisID: 'y2'),
      BubbleDataset(yAxisID: 'y2'),
    ],
    {'yAxisID': 'y2'},
  ),
  'stack': (
    const [
      BarDataset(stack: 's'),
      LineDataset(stack: 's'),
      ScatterDataset(stack: 's'),
    ],
    {'stack': 's'},
  ),
  'indexAxis': (
    const [BarDataset(indexAxis: .y), LineDataset(indexAxis: .y)],
    {'indexAxis': 'y'},
  ),
  'borderRadius, a number': (
    const [BarDataset(borderRadius: 4)],
    {'borderRadius': 4},
  ),
  'barPercentage': (
    const [BarDataset(barPercentage: 0.5)],
    {'barPercentage': 0.5},
  ),
  'categoryPercentage': (
    const [BarDataset(categoryPercentage: 0.6)],
    {'categoryPercentage': 0.6},
  ),
  'barThickness': (
    const [BarDataset(barThickness: 10)],
    {'barThickness': 10},
  ),
  'maxBarThickness': (
    const [BarDataset(maxBarThickness: 12)],
    {'maxBarThickness': 12},
  ),
  'minBarLength': (
    const [BarDataset(minBarLength: 2)],
    {'minBarLength': 2},
  ),
  'grouped': (
    const [BarDataset(grouped: false)],
    {'grouped': false},
  ),
  'fill, a name': (_lineStyle(fill: .origin), {'fill': 'origin'}),
  'fill, none': (_lineStyle(fill: .none), {'fill': false}),
  'fill, a dataset index': (_lineStyle(fill: const .dataset(1)), {'fill': 1}),
  'fill, a relative index': (
    _lineStyle(fill: const .relative(-1)),
    {'fill': '-1'},
  ),
  'fill, a value': (
    _lineStyle(fill: const .value(25)),
    {
      'fill': {'value': 25},
    },
  ),
  'tension': (_lineStyle(tension: 0.4), {'tension': 0.4}),
  'borderDash': (
    _lineStyle(borderDash: [5, 5]),
    {
      'borderDash': [5, 5],
    },
  ),
  'spanGaps': (_lineStyle(spanGaps: true), {'spanGaps': true}),
  'showLine': (_lineStyle(showLine: false), {'showLine': false}),
  'stepped': (_lineStyle(stepped: true), {'stepped': true}),
  'pointRadius': (_lineStyle(pointRadius: 0), {'pointRadius': 0}),
  'pointHoverRadius': (
    _lineStyle(pointHoverRadius: 6),
    {'pointHoverRadius': 6},
  ),
  'pointStyle': (
    [
      ..._lineStyle(pointStyle: .rectRot),
      const BubbleDataset(pointStyle: .rectRot),
    ],
    {'pointStyle': 'rectRot'},
  ),
  'pointStyle, none': (
    [..._lineStyle(pointStyle: .none), const BubbleDataset(pointStyle: .none)],
    {'pointStyle': false},
  ),
  'pointBackgroundColor': (
    _lineStyle(pointBackgroundColor: _red),
    {'pointBackgroundColor': _redValue},
  ),
  'pointBorderColor': (
    _lineStyle(pointBorderColor: _blue),
    {'pointBorderColor': _blueValue},
  ),
  'pointBorderWidth': (
    _lineStyle(pointBorderWidth: 2),
    {'pointBorderWidth': 2},
  ),
  'radius of a bubble': (const [BubbleDataset(radius: 7)], {'radius': 7}),
  'hoverRadius': (const [BubbleDataset(hoverRadius: 2)], {'hoverRadius': 2}),
  'offset': (_arcs(offset: 4), {'offset': 4}),
  'hoverOffset': (_arcs(hoverOffset: 4), {'hoverOffset': 4}),
  'spacing': (_arcs(spacing: 2), {'spacing': 2}),
  'weight': (_arcs(weight: 2), {'weight': 2}),
  'circumference': (_arcs(circumference: 180), {'circumference': 180}),
  'rotation': (_arcs(rotation: -90), {'rotation': -90}),
  'cutout, a percent': (_arcs(cutout: const .percent(50)), {'cutout': '50%'}),
  'cutout, pixels': (_arcs(cutout: const .pixels(20)), {'cutout': 20}),
  'radius, a percent': (_arcs(radius: const .percent(90)), {'radius': '90%'}),
  'radius, pixels': (_arcs(radius: const .pixels(100)), {'radius': 100}),
};

void main() {
  group('the datasets', () {
    group('each parameter of Dataset, in each dataset class', () {
      for (final MapEntry(key: name, value: (set, twin)) in _common.entries) {
        test(name, () {
          for (final dataset in _empty.values) {
            expectTwin(_lower(set(dataset)), twin);
          }
        });
      }
    });

    test('a scriptable color gives the rgba() string of each context', () {
      for (final dataset in _empty.values) {
        final lowered = _lower(
          dataset.copyWith(
            backgroundColorFor: _colorFor,
            borderColorFor: _colorFor,
          ),
        );
        for (final key in ['backgroundColor', 'borderColor']) {
          final script = lowered[key];
          // The 2 arguments of a scriptable option: the context and the
          // options resolver.
          expect(script, isA<Object? Function(Object?, Object?)>());
          final values = [
            for (final index in [0.0, 1.0, 2.0])
              jsCall(script, [
                <String, Object?>{'type': 'data', 'dataIndex': index},
                undefined,
              ]),
          ];
          expect(values, [_redValue, _blueValue, _redValue], reason: key);
        }
      }
    });

    group('each parameter of the dataset classes', () {
      for (final MapEntry(key: name, value: (datasets, twin)) in _own.entries) {
        test(name, () {
          for (final dataset in datasets) {
            expectTwin(_lower(dataset), twin);
          }
        });
      }
    });

    test('data goes by reference', () {
      final data = <num?>[1, null, 3];
      final datasets = <Dataset>[
        BarDataset(data: data),
        LineDataset(data: data),
        ScatterDataset(data: data),
        PieDataset(data: data),
        DoughnutDataset(data: data),
        PolarAreaDataset(data: data),
        RadarDataset(data: data),
      ];
      for (final dataset in datasets) {
        final lowered = _lower(dataset);
        expectTwin(lowered, {'data': data});
        expect(lowered['data'], same(data));
      }
    });

    test('points go by reference, under the key data', () {
      final points = [DataPoint(1, 2), DataPoint.bubble(3, 4, 5)];
      final datasets = <Dataset>[
        BarDataset(points: points),
        LineDataset(points: points),
        ScatterDataset(points: points),
        BubbleDataset(points: points),
      ];
      for (final dataset in datasets) {
        final lowered = _lower(dataset);
        expect(lowered.keys, ['data']);
        expect(lowered['data'], same(points));
      }
    });

    test('a style List lowers to a new List', () {
      final dash = [4.0, 2.0];
      final colors = [_red];
      final lowered = _lower(
        LineDataset(borderDash: dash, backgroundColors: colors),
      );
      expect(lowered['borderDash'], isNot(same(dash)));
      expect(lowered['borderDash'], isA<List<Object?>>());
      (lowered['borderDash']! as List<Object?>).add('x');
      expect(dash, [4, 2]);
      expect(lowered['backgroundColor'], [_redValue]);
    });

    group('the dataset type', () {
      for (final MapEntry(key: kind, value: dataset) in _empty.entries) {
        test('${kind.name}: no type in a chart of its type, the type first '
            'in another chart', () {
          final labeled = dataset.copyWith(label: 'A');
          expectTwin(lowerDataset(labeled, kind), {'label': 'A'});
          final other = kind == ChartKind.bar ? ChartKind.line : ChartKind.bar;
          expectTwin(lowerDataset(labeled, other), {
            'type': kind.name,
            'label': 'A',
          });
          expectTwin(lowerDataset(labeled, const ChartKind('custom')), {
            'type': kind.name,
            'label': 'A',
          });
        });
      }

      test('a doughnut dataset in a pie chart keeps its type', () {
        expectTwin(lowerDataset(const DoughnutDataset(), .pie), {
          'type': 'doughnut',
        });
        expectTwin(lowerDataset(const PieDataset(), .doughnut), {
          'type': 'pie',
        });
      });
    });

    group('extra', () {
      test('an entry wins over a parameter, in the place of the key', () {
        expectTwin(
          _lower(
            const BarDataset(
              label: 'A',
              borderWidth: 2,
              extra: {'borderWidth': 3, 'clip': 5},
            ),
          ),
          {'label': 'A', 'borderWidth': 3, 'clip': 5},
        );
      });

      test('a CSS string wins over a color', () {
        expectTwin(
          _lower(
            const LineDataset(
              backgroundColor: _red,
              extra: {'backgroundColor': 'red'},
            ),
          ),
          {'backgroundColor': 'red'},
        );
      });

      test('a Map merges into the Map of the key', () {
        expectTwin(
          _lower(
            const LineDataset(
              fill: .value(25),
              extra: {
                'fill': {'above': 'red'},
              },
            ),
          ),
          {
            'fill': {'value': 25, 'above': 'red'},
          },
        );
      });

      test('a Map replaces a value that is not a Map', () {
        expectTwin(
          _lower(
            const BarDataset(
              borderRadius: 4,
              extra: {
                'borderRadius': {'topLeft': 8},
              },
            ),
          ),
          {
            'borderRadius': {'topLeft': 8},
          },
        );
      });

      test('a const Map lowers to new Maps', () {
        const options = {
          'datalabels': {
            'font': {'size': 9},
          },
        };
        final lowered = _lower(const BarDataset(extra: options));
        expectTwin(lowered, {
          'datalabels': {
            'font': {'size': 9},
          },
        });
        expect(lowered['datalabels'], isNot(same(options['datalabels'])));
      });

      test('a List and a function go by reference', () {
        final segment = <String, Object?>{'borderColor': (Object? c) => 'red'};
        final list = <Object?>[1, 2];
        final lowered = _lower(
          LineDataset(extra: {'segment': segment, 'tags': list}),
        );
        expect(lowered['tags'], same(list));
        final copy = lowered['segment']! as Map<String, Object?>;
        expect(copy, isNot(same(segment)));
        expect(copy['borderColor'], same(segment['borderColor']));
      });

      test('an entry with the value null gives the JS null', () {
        expectTwin(_lower(const LineDataset(extra: {'clip': null})), {
          'clip': null,
        });
      });
    });

    group('all parameters, in parameter order', () {
      final data = <num?>[1, 2];
      final points = [DataPoint(1, 2)];

      test('BarDataset', () {
        final lowered = _lower(
          BarDataset(
            key: const ValueKey('a'),
            label: 'A',
            data: data,
            hidden: false,
            order: 1,
            backgroundColor: _red,
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            xAxisID: 'x2',
            yAxisID: 'y2',
            stack: 's',
            indexAxis: .y,
            borderRadius: 4,
            barPercentage: 0.5,
            categoryPercentage: 0.6,
            barThickness: 10,
            maxBarThickness: 12,
            minBarLength: 2,
            grouped: false,
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, {
          'label': 'A',
          'data': data,
          'hidden': false,
          'order': 1,
          'backgroundColor': _redValue,
          'borderColor': _blueValue,
          'borderWidth': 2,
          'hoverBackgroundColor': _blueValue,
          'hoverBorderColor': _redValue,
          'hoverBorderWidth': 3,
          'xAxisID': 'x2',
          'yAxisID': 'y2',
          'stack': 's',
          'indexAxis': 'y',
          'borderRadius': 4,
          'barPercentage': 0.5,
          'categoryPercentage': 0.6,
          'barThickness': 10,
          'maxBarThickness': 12,
          'minBarLength': 2,
          'grouped': false,
          'clip': 5,
        });
      });

      /// The twin keys of the line style parameters of the cases below.
      const lineStyleTwin = <String, Object?>{
        'fill': 'origin',
        'tension': 0.4,
        'borderDash': [5, 5],
        'spanGaps': true,
        'showLine': true,
        'stepped': false,
        'pointRadius': 3,
        'pointHoverRadius': 6,
        'pointStyle': 'star',
        'pointBackgroundColor': _redValue,
        'pointBorderColor': _blueValue,
        'pointBorderWidth': 1,
      };

      test('LineDataset', () {
        final lowered = _lower(
          LineDataset(
            label: 'A',
            points: points,
            hidden: true,
            order: 2,
            backgroundColors: const [_red],
            borderColorFor: _colorFor,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            xAxisID: 'x2',
            yAxisID: 'y2',
            stack: 's',
            indexAxis: .x,
            fill: .origin,
            tension: 0.4,
            borderDash: const [5, 5],
            spanGaps: true,
            showLine: true,
            stepped: false,
            pointRadius: 3,
            pointHoverRadius: 6,
            pointStyle: .star,
            pointBackgroundColor: _red,
            pointBorderColor: _blue,
            pointBorderWidth: 1,
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, {
          'label': 'A',
          'data': points,
          'hidden': true,
          'order': 2,
          'backgroundColor': [_redValue],
          'borderColor': (Object? context, Object? options) => _redValue,
          'borderWidth': 2,
          'hoverBackgroundColor': _blueValue,
          'hoverBorderColor': _redValue,
          'hoverBorderWidth': 3,
          'xAxisID': 'x2',
          'yAxisID': 'y2',
          'stack': 's',
          'indexAxis': 'x',
          ...lineStyleTwin,
          'clip': 5,
        });
      });

      test('ScatterDataset', () {
        final lowered = _lower(
          ScatterDataset(
            label: 'A',
            points: points,
            hidden: true,
            order: 2,
            backgroundColor: _red,
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            xAxisID: 'x2',
            yAxisID: 'y2',
            stack: 's',
            fill: .origin,
            tension: 0.4,
            borderDash: const [5, 5],
            spanGaps: true,
            showLine: true,
            stepped: false,
            pointRadius: 3,
            pointHoverRadius: 6,
            pointStyle: .star,
            pointBackgroundColor: _red,
            pointBorderColor: _blue,
            pointBorderWidth: 1,
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, {
          'label': 'A',
          'data': points,
          'hidden': true,
          'order': 2,
          'backgroundColor': _redValue,
          'borderColor': _blueValue,
          'borderWidth': 2,
          'hoverBackgroundColor': _blueValue,
          'hoverBorderColor': _redValue,
          'hoverBorderWidth': 3,
          'xAxisID': 'x2',
          'yAxisID': 'y2',
          'stack': 's',
          ...lineStyleTwin,
          'clip': 5,
        });
      });

      test('BubbleDataset', () {
        final bubbles = [DataPoint.bubble(1, 2, 3)];
        final lowered = _lower(
          BubbleDataset(
            label: 'A',
            points: bubbles,
            hidden: false,
            order: 1,
            backgroundColor: _red,
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            xAxisID: 'x2',
            yAxisID: 'y2',
            radius: 7,
            hoverRadius: 2,
            pointStyle: .triangle,
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, {
          'label': 'A',
          'data': bubbles,
          'hidden': false,
          'order': 1,
          'backgroundColor': _redValue,
          'borderColor': _blueValue,
          'borderWidth': 2,
          'hoverBackgroundColor': _blueValue,
          'hoverBorderColor': _redValue,
          'hoverBorderWidth': 3,
          'xAxisID': 'x2',
          'yAxisID': 'y2',
          'radius': 7,
          'hoverRadius': 2,
          'pointStyle': 'triangle',
          'clip': 5,
        });
      });

      final arcTwin = <String, Object?>{
        'label': 'A',
        'data': data,
        'hidden': false,
        'order': 1,
        'backgroundColor': [_redValue, _blueValue],
        'borderColor': _blueValue,
        'borderWidth': 2,
        'hoverBackgroundColor': _blueValue,
        'hoverBorderColor': _redValue,
        'hoverBorderWidth': 3,
        'offset': 4,
        'hoverOffset': 8,
        'spacing': 2,
        'weight': 2,
        'circumference': 180,
        'rotation': -90,
        'cutout': '60%',
        'radius': 120,
        'clip': 5,
      };

      test('PieDataset', () {
        final lowered = _lower(
          PieDataset(
            label: 'A',
            data: data,
            hidden: false,
            order: 1,
            backgroundColors: const [_red, _blue],
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            offset: 4,
            hoverOffset: 8,
            spacing: 2,
            weight: 2,
            circumference: 180,
            rotation: -90,
            cutout: const .percent(60),
            radius: const .pixels(120),
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, arcTwin);
      });

      test('DoughnutDataset', () {
        final lowered = _lower(
          DoughnutDataset(
            label: 'A',
            data: data,
            hidden: false,
            order: 1,
            backgroundColors: const [_red, _blue],
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            offset: 4,
            hoverOffset: 8,
            spacing: 2,
            weight: 2,
            circumference: 180,
            rotation: -90,
            cutout: const .percent(60),
            radius: const .pixels(120),
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, arcTwin);
      });

      test('PolarAreaDataset', () {
        final lowered = _lower(
          PolarAreaDataset(
            label: 'A',
            data: data,
            hidden: false,
            order: 1,
            backgroundColor: _red,
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            offset: 4,
            hoverOffset: 8,
            spacing: 2,
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, {
          'label': 'A',
          'data': data,
          'hidden': false,
          'order': 1,
          'backgroundColor': _redValue,
          'borderColor': _blueValue,
          'borderWidth': 2,
          'hoverBackgroundColor': _blueValue,
          'hoverBorderColor': _redValue,
          'hoverBorderWidth': 3,
          'offset': 4,
          'hoverOffset': 8,
          'spacing': 2,
          'clip': 5,
        });
      });

      test('RadarDataset', () {
        final lowered = _lower(
          RadarDataset(
            label: 'A',
            data: data,
            hidden: true,
            order: 2,
            backgroundColor: _red,
            borderColor: _blue,
            borderWidth: 2,
            hoverBackgroundColor: _blue,
            hoverBorderColor: _red,
            hoverBorderWidth: 3,
            fill: .origin,
            tension: 0.4,
            borderDash: const [5, 5],
            spanGaps: true,
            showLine: true,
            stepped: false,
            pointRadius: 3,
            pointHoverRadius: 6,
            pointStyle: .star,
            pointBackgroundColor: _red,
            pointBorderColor: _blue,
            pointBorderWidth: 1,
            extra: const {'clip': 5},
          ),
        );
        expectTwin(lowered, {
          'label': 'A',
          'data': data,
          'hidden': true,
          'order': 2,
          'backgroundColor': _redValue,
          'borderColor': _blueValue,
          'borderWidth': 2,
          'hoverBackgroundColor': _blueValue,
          'hoverBorderColor': _redValue,
          'hoverBorderWidth': 3,
          ...lineStyleTwin,
          'clip': 5,
        });
      });
    });
  });
}
