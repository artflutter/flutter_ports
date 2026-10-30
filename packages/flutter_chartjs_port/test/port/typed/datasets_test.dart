// Original code, not ported from Chart.js: tests of the typed data points.
@TestOn('vm')
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/chartjs.dart' as chartjs show Element;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0052, section 3: a `DataPoint` is the Map of the object form
// `{x, y}` or `{x, y, r}` at run time. A chart reads a `List<DataPoint>` as
// the List of its raw twin, with the same elements, and keeps the List of
// the app: the chart does not write into it. A label that is not in
// `data.labels` becomes a new label (row `js-semantics-narrow-labels`).
//
// VM only: the chart cases are `testWidgets` cases of the harness.

/// The Map of [point] at run time.
Map<String, Object?> _map(DataPoint point) => point as Map<String, Object?>;

/// A chart of [type] with one dataset of [data] and the scale config
/// [scales], with no animation.
Map<String, Object?> _config(
  String type,
  List<Object?> data, {
  List<Object?>? labels,
  Map<String, Object?>? scales,
}) => <String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'labels': ?labels,
    'datasets': <Object?>[
      <String, Object?>{'data': data},
    ],
  },
  'options': <String, Object?>{'animation': false, 'scales': ?scales},
};

/// The position, the `skip` state and the radius option of each element of
/// dataset 0 of [chart].
List<List<Object?>> _elements(Chart chart) => [
  for (final element in chart.getDatasetMeta(0).data.cast<chartjs.Element>())
    [element.x, element.y, element['skip'], element.options?['radius']],
];

void main() {
  group('the Map of a data point', () {
    test('each constructor makes the Map of its object form', () {
      expect(_map(DataPoint(1, 2)), {'x': 1, 'y': 2});
      expect(_map(DataPoint(1.5, null)), {'x': 1.5, 'y': null});
      final time = DateTime.utc(2020);
      expect(_map(DataPoint.time(time, 3)), {'x': time, 'y': 3});
      expect(_map(DataPoint.label('b', 4)), {'x': 'b', 'y': 4});
      expect(_map(DataPoint.bubble(1, 2, 5)), {'x': 1, 'y': 2, 'r': 5});
      expect(_map(DataPoint.bubble(1, 2, 5)).keys, ['x', 'y', 'r']);
    });

    test('the getters read the Map', () {
      final point = DataPoint.bubble(1, 2, 5);
      expect([point.x, point.y, point.r], [1, 2, 5]);
      final gap = DataPoint.label('b', null);
      expect([gap.x, gap.y, gap.r], ['b', null, null]);
    });
  });

  group('a chart reads a List<DataPoint>', () {
    testWidgets('a scatter chart gives the elements of the raw twin', (
      tester,
    ) async {
      final points = [DataPoint(1, 2), DataPoint(3, null), DataPoint(5, 4)];
      final typed = acquireChart(_config('scatter', points));
      final twin = acquireChart(
        _config('scatter', <Object?>[
          <String, Object?>{'x': 1, 'y': 2},
          <String, Object?>{'x': 3, 'y': null},
          <String, Object?>{'x': 5, 'y': 4},
        ]),
      );
      expect(_elements(typed), _elements(twin));
      expect(_elements(typed)[1][2], isTrue, reason: 'the gap skips');

      // The chart keeps the List of the app and writes into no data point.
      final dataset =
          (typed.data['datasets']! as List<Object?>).single!
              as Map<String, Object?>;
      expect(dataset['data'], same(points));
      typed.update();
      expect(
        [for (final point in points) _map(point).keys.toList()],
        [
          ['x', 'y'],
          ['x', 'y'],
          ['x', 'y'],
        ],
      );
    });

    testWidgets('a bubble chart gives the radius of the raw twin', (
      tester,
    ) async {
      final typed = acquireChart(
        _config('bubble', [
          DataPoint.bubble(1, 2, 5),
          DataPoint.bubble(2, 3, 9),
        ]),
      );
      final twin = acquireChart(
        _config('bubble', <Object?>[
          <String, Object?>{'x': 1, 'y': 2, 'r': 5},
          <String, Object?>{'x': 2, 'y': 3, 'r': 9},
        ]),
      );
      expect(_elements(typed), _elements(twin));
      expect([for (final e in _elements(typed)) e[3]], [5, 9]);
    });

    testWidgets('a time point gives its time value', (tester) async {
      final chart = acquireChart(
        _config(
          'line',
          [DataPoint.time(DateTime.utc(2020), 1)],
          scales: <String, Object?>{
            'x': <String, Object?>{'type': 'time'},
          },
        ),
      );
      final parsed = chart.getDatasetMeta(0).controller!.getParsed(0)! as Map;
      expect(parsed['x'], DateTime.utc(2020).millisecondsSinceEpoch);
    });

    testWidgets('an unknown label becomes a new label of the chart', (
      tester,
    ) async {
      final labels = <Object?>['a', 'b'];
      final chart = acquireChart(
        _config('line', [
          DataPoint.label('b', 1),
          DataPoint.label('c', 2),
        ], labels: labels),
      );
      expect(labels, ['a', 'b', 'c']);
      expect([for (final e in chart.getDatasetMeta(0).data) e.y], hasLength(2));
    });
  });
}
