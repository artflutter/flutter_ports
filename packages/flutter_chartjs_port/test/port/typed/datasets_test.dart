// Original code, not ported from Chart.js: tests of the typed data points.
@TestOn('vm')
library;

import 'dart:ui' show Color;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/chartjs.dart' as chartjs show Element;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0052, section 3, and Chart.js ADR 0054 §7: a `DataPoint` is a
// typed data item with the face of the object form `{x, y}` or `{x, y, r}`.
// A chart reads a `List<DataPoint>` and keeps the List of the app: the
// chart does not write into it. A label that is not in `data.labels`
// becomes a new label (row `js-semantics-narrow-labels`).
//
// Sections 1, 2 and 5: a lowered dataset drives the chart. A plain color
// keeps the option sharing of the data elements, and a List or a function
// turns it off, as a raw dataset does (probe J3a). A dataset of another
// class than the chart type gets its own controller. Each chart has a typed
// config (Chart.js ADR 0195). The lowering of each field is in
// lowering_test.dart.
//
// VM only: the chart cases are `testWidgets` cases of the harness.

const Color _red = Color(0xFFFF6384);
const Color _blue = Color(0xFF36A2EB);
const ChartPaint _redValue = ChartPaint.solid(_red);
const ChartPaint _blueValue = ChartPaint.solid(_blue);

/// A scriptable color: blue at the data index 1, else red.
ChartPaint _colorFor(ScriptableContext context) =>
    ChartPaint.solid(context.dataIndex == 1 ? _blue : _red);

/// The chart of the typed config with the datasets [datasets], the labels
/// [labels] (three by default) and the axes [scales], with no animation.
Chart _acquire(
  List<Dataset> datasets, {
  List<Object> labels = const ['a', 'b', 'c'],
  List<ChartAxis>? scales,
}) => acquireChartRoot(
  ChartConfigLowering(
    ChartConfig(
      labels: labels,
      datasets: datasets,
      scales: scales,
      animation: ChartAnimation.none,
    ),
  ).lower(),
);

/// The option sharing of the data elements of dataset 0 of [chart]: the
/// `$shared` flag of element 0, whether elements 0 and 1 have one options
/// object, and the background color of each element.
List<Object?> _sharing(Chart chart) {
  final elements = chart.getDatasetMeta(0).data.cast<chartjs.Element>();
  return [
    _byName(elements[0].options, r'$shared'),
    identical(elements[0].options, elements[1].options),
    [
      for (final element in elements)
        _byName(element.options, 'backgroundColor'),
    ],
  ];
}

/// The object of [point] through its face (Chart.js ADR 0054 §5): its keys
/// in their order, with their values.
Map<String, Object?> _map(DataPoint point) => {
  for (final key in point.jsKeys()) key: point.jsRead(key),
};

/// The position, the `skip` state and the radius option of each element of
/// dataset 0 of [chart].
List<List<Object?>> _elements(Chart chart) => [
  for (final element in chart.getDatasetMeta(0).data.cast<chartjs.Element>())
    [element.x, element.y, element['skip'], _byName(element.options, 'radius')],
];

void main() {
  group('the object of a data point', () {
    test('each constructor makes the face of its object form', () {
      expect(_map(DataPoint(1, 2)), {'x': 1, 'y': 2});
      expect(_map(DataPoint(1.5, null)), {'x': 1.5, 'y': null});
      final time = DateTime.utc(2020);
      // A time point stores the time value (Chart.js ADR 0205).
      expect(_map(DataPoint.time(time, 3)), {
        'x': time.millisecondsSinceEpoch.toDouble(),
        'y': 3,
      });
      // A bubble keeps its radius in `_custom` too (row
      // adapt-bubble-typed-radius).
      expect(_map(DataPoint.bubble(1, 2, 5)), {
        'x': 1,
        'y': 2,
        'r': 5,
        '_custom': 5,
      });
      expect(_map(DataPoint.bubble(1, 2, 5)).keys, ['x', 'y', 'r', '_custom']);
    });

    test('the fields are the typed values', () {
      final point = DataPoint.bubble(1, 2, 5);
      expect([point.x, point.y, point.r], [1.0, 2.0, 5.0]);
      expect(point.x, isA<double>());
      final gap = DataPoint(1, null);
      expect([gap.x, gap.y, gap.r], [1.0, null, null]);
    });

    test('a label point holds its text and its value', () {
      // A label point is no parsed item (Chart.js ADR 0205).
      const point = LabelPoint('b', 4);
      expect([point.x, point.y], ['b', 4.0]);
      expect(point, isNot(isA<ParsedItem>()));
      expect(point, const LabelPoint('b', 4));
    });

    test('an absent r reads as undefined, and a write by name writes', () {
      // A data point is a parsed item (row adapt-parsed-data-items): the
      // chart writes its stacks into it, as into the object of upstream.
      final point = DataPoint(1, 2);
      expect(point, isA<ParsedItem>());
      expect(point.jsRead('r'), same(undefined));
      expect(point.jsHas('r'), isFalse);
      expect(point, isNot(isA<Map<Object?, Object?>>()));
      point.jsWrite('y', 3.0);
      expect(point.y, 3.0);
      expect(point.jsDelete('x'), isTrue);
      expect(point.x, isNull);
    });
  });

  group('a chart reads a List<DataPoint>', () {
    testWidgets('a scatter chart skips the gap and keeps the points', (
      tester,
    ) async {
      final points = [DataPoint(1, 2), DataPoint(3, null), DataPoint(5, 4)];
      final typed = _acquire([ScatterDataset(data: .points(points))]);
      expect(_elements(typed)[1][2], isTrue, reason: 'the gap skips');

      // The chart keeps the List of the app and writes into no data point.
      final dataset =
          (_byName(typed.data, 'datasets')! as List<Object?>).single;
      expect(_byName(dataset, 'data'), same(points));
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

    testWidgets('a bubble chart gives the radius of each point', (
      tester,
    ) async {
      final typed = _acquire([
        BubbleDataset(
          data: [DataPoint.bubble(1, 2, 5), DataPoint.bubble(2, 3, 9)],
        ),
      ]);
      expect([for (final e in _elements(typed)) e[3]], [5, 9]);
    });

    testWidgets('a time point gives its time value', (tester) async {
      final chart = _acquire(
        [
          LineDataset(data: .points([DataPoint.time(DateTime.utc(2020), 1)])),
        ],
        scales: [const TimeAxis(.x)],
      );
      final parsed =
          chart.getDatasetMeta(0).controller!.getParsed(0)! as JsObjectFace;
      expect(parsed['x'], DateTime.utc(2020).millisecondsSinceEpoch);
    });

    testWidgets('an unknown label throws for a const labels List', (
      tester,
    ) async {
      // Chart.js ADR 0052, section 3: the category scale adds the label to
      // `data.labels` (row `js-semantics-narrow-labels`), and a `const`
      // List cannot grow.
      final config = ChartConfigLowering(
        const ChartConfig(
          labels: ['a', 'b'],
          datasets: [
            LineDataset(data: .labelPoints([LabelPoint('c', 2)])),
          ],
          animation: ChartAnimation.none,
        ),
      ).lower();
      expect(
        () => acquireChartRoot(config),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            'Cannot add to an unmodifiable list',
          ),
        ),
      );
    });

    testWidgets('an unknown label becomes a new label of the chart', (
      tester,
    ) async {
      final labels = <Object>['a', 'b'];
      final chart = _acquire([
        const LineDataset(
          data: .labelPoints([LabelPoint('b', 1), LabelPoint('c', 2)]),
        ),
      ], labels: labels);
      expect(labels, ['a', 'b', 'c']);
      expect([for (final e in chart.getDatasetMeta(0).data) e.y], hasLength(2));
    });
  });

  group('a lowered dataset in a chart', () {
    testWidgets('a plain color shares the options', (tester) async {
      final typed = _acquire([
        const BarDataset(
          data: .values([1, 2, 3]),
          backgroundColor: ChartValue.constant(.solid(_red)),
        ),
      ]);
      expect(_sharing(typed), [
        true,
        true,
        [_redValue, _redValue, _redValue],
      ]);
    });

    testWidgets('a List of colors does not share', (tester) async {
      final typed = _acquire([
        const BarDataset(
          data: .values([1, 2, 3]),
          backgroundColor: ChartValue.indexed([
            ChartPaint.solid(_red),
            ChartPaint.solid(_blue),
          ]),
        ),
      ]);
      expect(_sharing(typed), [
        false,
        false,
        [_redValue, _blueValue, _redValue],
      ]);
    });

    testWidgets('a scriptable color does not share', (tester) async {
      final typed = _acquire([
        const BarDataset(
          data: .values([1, 2, 3]),
          backgroundColor: ChartValue.resolver(_colorFor),
        ),
      ]);
      expect(_sharing(typed), [
        false,
        false,
        [_redValue, _blueValue, _redValue],
      ]);
    });

    testWidgets('a line dataset in a bar chart gets the line controller', (
      tester,
    ) async {
      final chart = _acquire(const [
        BarDataset(data: .values([1, 2, 3])),
        LineDataset(data: .values([3, 2, 1])),
      ]);
      expect(chart.getDatasetMeta(0).type, 'bar');
      expect(chart.getDatasetMeta(1).type, 'line');
      expect(chart.getDatasetMeta(1).controller, isA<LineController>());
    });

    testWidgets('a doughnut dataset in a pie chart has the doughnut cutout', (
      tester,
    ) async {
      /// The inner radius of element 0 of dataset [index] of [chart].
      Object? innerRadius(Chart chart, int index) =>
          (chart.getDatasetMeta(index).data[0]
              as chartjs.Element)['innerRadius'];

      final pie = _acquire(const [
        PieDataset(data: [1, 2, 3]),
      ]);
      // The first dataset gives the chart type (Chart.js ADR 0190): a hidden
      // pie dataset makes a pie chart, and the doughnut dataset after it
      // has the whole radius.
      final doughnut = _acquire(const [
        PieDataset(data: [1, 2, 3], hidden: true),
        DoughnutDataset(data: [1, 2, 3]),
      ]);
      expect(innerRadius(pie, 0), 0);
      expect(doughnut.config.type, 'pie');
      expect(doughnut.getDatasetMeta(1).type, 'doughnut');
      expect(innerRadius(doughnut, 1), greaterThan(0));
    });
  });
}

/// The read by name `object[key]` of an object of a chart: a Map of a raw
/// config, or a typed object through its face (Chart.js ADR 0054 §5).
Object? _byName(Object? object, String key) => switch (object) {
  final Map<Object?, Object?> map => map[key],
  final JsObjectFace face => face[key],
  _ => null,
};
