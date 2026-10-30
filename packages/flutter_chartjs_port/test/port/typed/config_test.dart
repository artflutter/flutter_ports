// Original code, not ported from Chart.js: tests of the typed config.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/chartjs.dart' as chartjs show Element;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_test/flutter_test.dart';

import 'twin.dart';

// Chart.js ADR 0052, sections 1 and 7: the chart type `ChartKind` names the
// 8 controllers of Chart.js, and `IndexAxis` gives the names of the
// `indexAxis` option.
//
// Sections 2 and 11, the whole-config twins: a typed bar chart (the docs
// config of docs/charts/bar.md), a typed mixed chart (docs/charts/mixed.md)
// and a typed scatter chart with a tooltip label callback lower to the Map
// of their raw twins, with the key order. The charts of the two Maps have
// equal elements and equal tooltip lines. The lowering of each field is in
// lowering_test.dart.
//
// flutter_test_config.dart registers the built-in components before
// main() (harness-register-builtins), so the registry has the controllers.
//
// VM only: the test imports the app library, which imports dart:ui.

/// [value], as a value that is not a constant.
T _runtime<T>(T value) => value;

/// The colors of the docs bar chart, as RGB channels.
const List<(int, int, int)> _rainbow = [
  (255, 99, 132),
  (255, 159, 64),
  (255, 205, 86),
  (75, 192, 192),
  (54, 162, 235),
  (153, 102, 255),
  (201, 203, 207),
];

/// The position, the size and the colors of each element of each dataset
/// of [chart].
List<List<Object?>> _elements(Chart chart) => [
  for (var i = 0; i < (chart.data['datasets']! as List<Object?>).length; i++)
    for (final element
        in chart.getDatasetMeta(i.toDouble()).data.cast<chartjs.Element>())
      [
        i,
        element.x,
        element.y,
        element['width'],
        element['height'],
        element.options?['backgroundColor'],
        element.options?['borderColor'],
      ],
];

/// The label line of a scatter point: `(x, y)`.
String? _pointLabel(ChartTooltipItem item) {
  final parsed = item.parsed! as Map<String, Object?>;
  return '(${(parsed['x']! as num).toInt()}, ${(parsed['y']! as num).toInt()})';
}

void main() {
  group('ChartKind', () {
    const kinds = <ChartKind>[
      .bar,
      .line,
      .scatter,
      .bubble,
      .pie,
      .doughnut,
      .polarArea,
      .radar,
    ];

    test('each constant is the id of a registered controller', () {
      for (final kind in kinds) {
        expect((registry.getController(kind.name) as JsClass)['id'], kind.name);
      }
    });

    test('the constants are the 8 controllers of Chart.js', () {
      expect(
        [for (final kind in kinds) kind.name]..sort(),
        [
          for (final controller in controllers.values)
            (controller! as JsClass)['id']! as String,
        ]..sort(),
      );
    });

    test('a custom kind has its name, and equal names are ==', () {
      expect(const ChartKind('myType').name, 'myType');
      expect(ChartKind(_runtime('bar')), ChartKind.bar);
    });
  });

  group('IndexAxis', () {
    test('the names of the indexAxis option', () {
      expect([for (final axis in IndexAxis.values) axis.name], ['x', 'y']);
    });
  });

  group('whole configs and their raw twins', () {
    testWidgets('a bar chart, the docs config of docs/charts/bar.md', (
      tester,
    ) async {
      final data = <num?>[65, 59, 80, 81, 56, 55, 40];
      final labels = <Object>[
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
      ];
      final typed = ChartConfigLowering(
        ChartConfig(
          type: .bar,
          labels: labels,
          datasets: [
            BarDataset(
              label: 'My First Dataset',
              data: data,
              backgroundColors: [
                for (final (r, g, b) in _rainbow) Color.fromRGBO(r, g, b, 0.2),
              ],
              borderColors: [
                for (final (r, g, b) in _rainbow) Color.fromRGBO(r, g, b, 1),
              ],
              borderWidth: 1,
            ),
          ],
          scales: const {'y': LinearAxis(beginAtZero: true)},
          animation: ChartAnimation.none,
        ),
      ).lower();
      final twin = <String, Object?>{
        'type': 'bar',
        'data': <String, Object?>{
          'labels': labels,
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'My First Dataset',
              'data': data,
              'backgroundColor': <Object?>[
                for (final (r, g, b) in _rainbow) 'rgba($r, $g, $b, 0.2)',
              ],
              'borderColor': <Object?>[
                for (final (r, g, b) in _rainbow) 'rgba($r, $g, $b, 1)',
              ],
              'borderWidth': 1,
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{'type': 'linear', 'beginAtZero': true},
          },
          'animation': false,
        },
      };
      expectTwin(typed, twin);
      expect(_elements(acquireChart(typed)), _elements(acquireChart(twin)));
    });

    testWidgets('a mixed chart, the docs config of docs/charts/mixed.md', (
      tester,
    ) async {
      final typed = ChartConfigLowering(
        const ChartConfig(
          type: .scatter,
          labels: ['January', 'February', 'March', 'April'],
          datasets: [
            BarDataset(
              label: 'Bar Dataset',
              data: [10, 20, 30, 40],
              borderColor: Color.fromRGBO(255, 99, 132, 1),
              backgroundColor: Color.fromRGBO(255, 99, 132, 0.2),
            ),
            LineDataset(
              label: 'Line Dataset',
              data: [50, 50, 50, 50],
              borderColor: Color.fromRGBO(54, 162, 235, 1),
              fill: .none,
            ),
          ],
          scales: {'y': LinearAxis(beginAtZero: true)},
          animation: ChartAnimation.none,
        ),
      ).lower();
      final twin = <String, Object?>{
        'type': 'scatter',
        'data': <String, Object?>{
          'labels': <Object?>['January', 'February', 'March', 'April'],
          'datasets': <Object?>[
            <String, Object?>{
              'type': 'bar',
              'label': 'Bar Dataset',
              'data': <Object?>[10, 20, 30, 40],
              'backgroundColor': 'rgba(255, 99, 132, 0.2)',
              'borderColor': 'rgba(255, 99, 132, 1)',
            },
            <String, Object?>{
              'type': 'line',
              'label': 'Line Dataset',
              'data': <Object?>[50, 50, 50, 50],
              'borderColor': 'rgba(54, 162, 235, 1)',
              'fill': false,
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'y': <String, Object?>{'type': 'linear', 'beginAtZero': true},
          },
          'animation': false,
        },
      };
      expectTwin(typed, twin);
      final typedChart = acquireChart(typed);
      final twinChart = acquireChart(twin);
      expect(_elements(typedChart), _elements(twinChart));
      expect(
        [
          for (final i in [0.0, 1.0]) typedChart.getDatasetMeta(i).type,
        ],
        ['bar', 'line'],
      );
    });

    testWidgets('a scatter chart with a tooltip label callback', (
      tester,
    ) async {
      final points = [DataPoint(-10, 0), DataPoint(0, 10), DataPoint(10, 5)];
      final typed = ChartConfigLowering(
        ChartConfig(
          type: .scatter,
          datasets: [
            ScatterDataset(
              label: 'Scatter Dataset',
              points: points,
              backgroundColor: const Color.fromRGBO(255, 99, 132, 1),
            ),
          ],
          scales: const {'x': LinearAxis(position: .bottom)},
          tooltip: const ChartTooltip(labelText: _pointLabel),
          animation: ChartAnimation.none,
        ),
      ).lower();
      final twin = <String, Object?>{
        'type': 'scatter',
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'label': 'Scatter Dataset',
              'data': points,
              'backgroundColor': 'rgba(255, 99, 132, 1)',
            },
          ],
        },
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear', 'position': 'bottom'},
          },
          'plugins': <String, Object?>{
            'tooltip': <String, Object?>{
              'callbacks': <String, Object?>{
                'label': (Object? item) {
                  final parsed =
                      (item! as Map<String, Object?>)['parsed']!
                          as Map<String, Object?>;
                  return '(${(parsed['x']! as num).toInt()}, '
                      '${(parsed['y']! as num).toInt()})';
                },
              },
            },
          },
          'animation': false,
        },
      };
      expectTwin(typed, twin);

      /// The label lines of the tooltip of a hover on point 1 of [config].
      Future<List<Object?>> labelsOf(Map<String, Object?> config) async {
        final chart = acquireChart(config);
        await triggerMouseEvent(
          chart,
          'mousemove',
          chart.getDatasetMeta(0).data[1],
        );
        return [
          for (final item in chart.tooltip!.body!)
            (item! as Map<String, Object?>)['lines'],
        ];
      }

      final typedLines = await labelsOf(typed);
      expect(typedLines, await labelsOf(twin));
      expect(typedLines, [
        ['(0, 10)'],
      ]);
    });
  });
}
