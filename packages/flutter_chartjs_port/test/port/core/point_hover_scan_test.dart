// Original code, not ported from Chart.js: the typed hover scan of points.
@TestOn('vm')
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/flutter.dart';
// The test reads the elements, the modes and the scan of
// flutter_chartjs_port, which does not export lib/src.
import 'package:flutter_chartjs_port/chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

/// A chart event at a position, as the spec of the interaction makes it.
final class _Event(
  @override final IChart? chart,
  @override final double? x,
  @override final double? y,
) implements ChartEvent {
  @override
  String get type => 'mousemove';

  @override
  NativeEvent? get native => null;
}

/// A chart event whose position code of a program changes during a search.
final class _MovingEvent(
  @override final IChart? chart,
  @override var double? x,
  @override var double? y,
) implements ChartEvent {
  @override
  String get type => 'mousemove';

  @override
  NativeEvent? get native => null;
}

/// An element of a program: the scan gives it the calls of the public loop.
class _PlainPoint() extends PointElement {
  /// The arguments of each `inRange` call.
  final List<(double?, double?, bool?)> inRangeCalls = [];

  /// Code of a program that runs in each `inRange` call, after the read of
  /// the arguments.
  void Function()? onInRange;

  @override
  bool inRange(double? mouseX, double? mouseY, [bool? useFinalPosition]) {
    inRangeCalls.add((mouseX, mouseY, useFinalPosition));
    onInRange?.call();
    return super.inRange(mouseX, mouseY, useFinalPosition);
  }
}

/// An element of a program with the properties of [point].
_PlainPoint _plainCopy(PointElement point) {
  final plain = _PlainPoint()
    ..x = point.x
    ..y = point.y
    ..options = point.options;
  final skip = point.skip;
  if (skip != null) plain.skip = skip;
  return plain;
}

/// The searches of a case: the mode and its options. The typed scan serves
/// each of them.
final List<(String, InteractionMode, Map<String, Object?>)> _searches = [
  ('point', const PointInteractionMode(), {}),
  ('point x', const PointInteractionMode(), {'axis': InteractionAxis.x}),
  ('point y', const PointInteractionMode(), {'axis': InteractionAxis.y}),
  ('point invisible', const PointInteractionMode(), {'includeInvisible': true}),
  ('nearest', const NearestInteractionMode(), {'intersect': true}),
  (
    'nearest x',
    const NearestInteractionMode(),
    {'intersect': true, 'axis': InteractionAxis.x},
  ),
  (
    'nearest invisible',
    const NearestInteractionMode(),
    {'intersect': true, 'includeInvisible': true},
  ),
  ('index', const IndexInteractionMode(), {'intersect': true}),
  ('dataset', const DatasetInteractionMode(), {'intersect': true}),
];

ActiveElement _item(Element element, int datasetIndex, int index) =>
    ActiveElement(element: element, datasetIndex: datasetIndex, index: index);

/// `getIntersectItems` (core.interaction.js:114) over the public loop
/// `Interaction.evaluateInteractionItems`, which the typed scan does not
/// change: it visits each point that `binarySearch` gives.
List<ActiveElement> _intersectItems(
  Chart chart,
  ChartEvent position,
  InteractionAxis axis,
  bool? useFinalPosition, {
  required bool includeInvisible,
}) {
  final items = <ActiveElement>[];
  if (!includeInvisible && !chart.isPointInArea(position)) return items;
  Interaction.evaluateInteractionItems(chart, axis, position, (
    element,
    datasetIndex,
    index,
  ) {
    if (!includeInvisible && !isPointInArea(element, chart.chartArea, 0)) {
      return;
    }
    if ((element as VisualElement).inRange(
      position.x,
      position.y,
      useFinalPosition,
    )) {
      items.add(_item(element, datasetIndex, index));
    }
  }, true);
  return items;
}

/// The distance of `getDistanceMetricForAxis` (core.interaction.js:94).
double _distance(Point a, Point b, InteractionAxis axis) {
  final dx = axis.usesX ? ((a.x ?? 0) - (b.x ?? 0)).abs() : 0.0;
  final dy = axis.usesY ? ((a.y ?? 0) - (b.y ?? 0)).abs() : 0.0;
  return math.sqrt(math.pow(dx, 2.0) + math.pow(dy, 2.0));
}

/// `getNearestItems` with `intersect` (core.interaction.js:168, :209) over
/// the public loop.
List<ActiveElement> _nearestItems(
  Chart chart,
  ChartEvent position,
  InteractionAxis axis,
  bool? useFinalPosition, {
  required bool includeInvisible,
}) {
  if (!includeInvisible && !chart.isPointInArea(position)) return [];
  var items = <ActiveElement>[];
  var minDistance = double.infinity;
  Interaction.evaluateInteractionItems(chart, axis, position, (
    element,
    datasetIndex,
    index,
  ) {
    final visual = element as VisualElement;
    if (!visual.inRange(position.x, position.y, useFinalPosition)) return;
    final center = visual.getCenterPoint(useFinalPosition);
    final distance = _distance(position, center, axis);
    if (distance < minDistance) {
      items = [_item(element, datasetIndex, index)];
      minDistance = distance;
    } else if (distance == minDistance) {
      items.add(_item(element, datasetIndex, index));
    }
  });
  return items;
}

/// The items of [mode] with [options] at [e], from the public loop.
List<ActiveElement> _expected(
  Chart chart,
  InteractionMode mode,
  Map<String, Object?> options,
  ChartEvent e,
  bool? useFinalPosition,
) {
  final includeInvisible = options['includeInvisible'] == true;
  final axis = options['axis'] as InteractionAxis?;
  switch (mode) {
    case NearestInteractionMode():
      return _nearestItems(
        chart,
        e,
        axis ?? InteractionAxis.xy,
        useFinalPosition,
        includeInvisible: includeInvisible,
      );
    case PointInteractionMode():
      return _intersectItems(
        chart,
        e,
        axis ?? InteractionAxis.xy,
        useFinalPosition,
        includeInvisible: includeInvisible,
      );
    case IndexInteractionMode():
      final items = _intersectItems(
        chart,
        e,
        axis ?? InteractionAxis.x,
        useFinalPosition,
        includeInvisible: includeInvisible,
      );
      if (items.isEmpty) return [];
      final index = items[0].index;
      return [
        for (final meta in chart.getSortedVisibleDatasetMetas())
          if (index < meta.data.length)
            if (meta.data[index] case final Element element
                when element['skip'] != true)
              _item(element, meta.index, index),
      ];
    case DatasetInteractionMode():
      final items = _intersectItems(
        chart,
        e,
        axis ?? InteractionAxis.xy,
        useFinalPosition,
        includeInvisible: includeInvisible,
      );
      if (items.isEmpty) return [];
      final datasetIndex = items[0].datasetIndex;
      final data = chart.getDatasetMeta(datasetIndex).data;
      return [
        for (var i = 0; i < data.length; i++)
          _item(data[i] as Element, datasetIndex, i),
      ];
    default:
      throw StateError('No reference for $mode');
  }
}

/// The items of one search as text, with the identity of each element.
String _items(Chart chart, List<ActiveElement> items) => [
  for (final item in items)
    '${item.datasetIndex}:${item.index}${_same(chart, item) ? '' : '!'}',
].join(' ');

bool _same(Chart chart, ActiveElement item) => identical(
  item.element,
  chart.getDatasetMeta(item.datasetIndex).data[item.index],
);

/// The reach `hitRadius + radius` of the typed options of [point], or 0.
double _reach(PointElement point) => switch (point.options) {
  final PointOptions options => options.hitRadius + options.radius,
  _ => 0,
};

/// The positions of a case: a grid over the canvas, and the edge of the
/// reach of some points with offsets around the margin of the scan.
List<(double?, double?)> _positions(Chart chart) {
  final area = chart.chartArea!;
  final points = <(double?, double?)>[];
  for (var x = area.left - 6; x <= area.right + 6; x += 9.37) {
    for (var y = area.top - 6; y <= area.bottom + 6; y += 11.13) {
      points.add((x, y));
    }
  }
  for (final meta in chart.getSortedVisibleDatasetMetas()) {
    final data = meta.data;
    for (var j = 0; j < data.length; j += (data.length ~/ 12) + 1) {
      final point = data[j] as PointElement;
      final x = point.x;
      final y = point.y;
      if (!x.isFinite || !y.isFinite) continue;
      final r = _reach(point);
      for (final side in [-1.0, 1.0]) {
        for (final d in [
          0.0,
          1e-9,
          -1e-9,
          r * 1e-6,
          r * 1e-6 + 1e-6,
          r * 1e-6 + 2e-6,
          -1e-6,
          -r * 1e-13,
          -r * 1e-2,
          1e-3,
          -1e-3,
        ]) {
          final edge = side * (r + d);
          points
            ..add((x + edge, y))
            ..add((x, y + edge))
            ..add((x + edge * math.sqrt1_2, y + edge * math.sqrt1_2));
        }
      }
      points
        ..add((x, y))
        ..add((x, null))
        ..add((null, y));
    }
  }
  points
    ..add((null, null))
    ..add((double.nan, 100))
    ..add((100, double.nan));
  return points;
}

/// Each search of [_searches] at each position of [_positions] gives the
/// items of the public loop, in their order. Returns the count of the
/// searches with an item.
int _expectItemsOfPublicLoop(Chart chart, {bool? useFinalPosition}) {
  var hits = 0;
  final positions = _positions(chart);
  for (final (name, mode, options) in _searches) {
    for (final (x, y) in positions) {
      final e = _Event(chart, x, y);
      final actual = _items(
        chart,
        mode.itemsAt(chart, e, options, useFinalPosition),
      );
      final expected = _items(
        chart,
        _expected(chart, mode, options, e, useFinalPosition),
      );
      if (actual != expected) {
        fail(
          '$name at $x,$y (final: $useFinalPosition): "$actual", not '
          '"$expected"',
        );
      }
      if (expected.isNotEmpty) hits++;
    }
  }
  return hits;
}

/// The points of a dataset: [count] items with x from 0 and y from 10 to
/// 90.
List<Object?> _values(int count, int seed) => <Object?>[
  for (var i = 0; i < count; i++)
    <String, Object?>{'x': i * 3 + seed, 'y': 10 + ((i * 37 + seed * 11) % 81)},
];

Chart _scatterChart({
  required int count,
  int datasets = 1,
  String type = 'scatter',
  Map<String, Object?> options = const {},
  Map<String, Object?> Function(int dataset)? datasetOptions,
  List<Object?> Function(int dataset)? values,
  Object? animation = false,
}) => acquireChart(<String, Object?>{
  'type': type,
  'data': <String, Object?>{
    'datasets': <Object?>[
      for (var k = 0; k < datasets; k++)
        <String, Object?>{
          'label': 'series $k',
          'data': values?.call(k) ?? _values(count, k),
          ...?datasetOptions?.call(k),
        },
    ],
  },
  'options': <String, Object?>{'animation': animation, ...options},
});

void _setData(Chart chart, int count, int seed) {
  final data = chart.data as Map<String, Object?>;
  ((data['datasets']! as List<Object?>)[0]! as Map<String, Object?>)['data'] =
      _values(count, seed);
}

void main() {
  tearDown(releaseCharts);

  group('the typed scan gives the items of the public loop', () {
    testWidgets('one dataset of points', (tester) async {
      final chart = _scatterChart(count: 300);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
      expect(
        _expectItemsOfPublicLoop(chart, useFinalPosition: true),
        greaterThan(300),
      );
    });

    testWidgets('datasets with other radii and hit radii', (tester) async {
      final chart = _scatterChart(
        count: 120,
        datasets: 4,
        datasetOptions: (k) => <String, Object?>{
          // A point with a hit radius only, a large point with no hit
          // radius, a negative sum and the defaults.
          'pointRadius': const [0, 9, 2, 3][k],
          'pointHitRadius': const [6, 0, -5, 1][k],
        },
      );
      final first = chart.getDatasetMeta(0).data[10] as PointElement;
      expect((first.options! as PointOptions).radius, 0);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
    });

    testWidgets('a scriptable radius gives each point its own reach', (
      tester,
    ) async {
      final chart = _scatterChart(
        count: 150,
        datasets: 2,
        datasetOptions: (k) => <String, Object?>{
          'pointRadius': (Object? ctx) => switch (jsGet(ctx, 'dataIndex')) {
            final int i => i % 7 + k,
            _ => 3,
          },
        },
      );
      final data = chart.getDatasetMeta(0).data;
      expect(
        ((data[3] as PointElement).options! as PointOptions).radius,
        isNot(((data[4] as PointElement).options! as PointOptions).radius),
      );
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
    });

    testWidgets('a line chart whose points share their options', (
      tester,
    ) async {
      final chart = _scatterChart(
        count: 200,
        datasets: 2,
        type: 'line',
        options: <String, Object?>{
          'interaction': <String, Object?>{
            'mode': const PointInteractionMode(),
          },
          'scales': <String, Object?>{
            'x': <String, Object?>{'type': 'linear'},
          },
        },
      );
      final data = chart.getDatasetMeta(0).data;
      expect((data[0] as Element).options, same((data[1] as Element).options));
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
    });

    testWidgets('a hovered point with its hover radius', (tester) async {
      final chart = _scatterChart(count: 100, datasets: 2)
        ..setActiveElements(const [
          ActiveElement(datasetIndex: 0, index: 40),
          ActiveElement(datasetIndex: 1, index: 41),
        ])
        ..update(UpdateMode.none);
      final hovered = chart.getDatasetMeta(0).data[40] as PointElement;
      expect((hovered.options! as PointOptions).radius, 4);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
    });

    testWidgets('null values give skipped points', (tester) async {
      final chart = _scatterChart(
        count: 100,
        datasets: 2,
        options: <String, Object?>{'spanGaps': false},
        values: (k) => <Object?>[
          for (var i = 0; i < 100; i++)
            <String, Object?>{
              'x': i * 3 + k,
              'y': (i + k) % 4 == 0 ? null : 10 + ((i * 37 + k * 11) % 81),
            },
        ],
      );
      final data = chart.getDatasetMeta(0).data;
      expect((data[0] as PointElement).skip, isTrue);
      expect((data[1] as PointElement).skip, isFalse);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
    });

    testWidgets('20,000 points', (tester) async {
      final chart = _scatterChart(count: 20000);
      final points = chart.getDatasetMeta(0).data;
      var hits = 0;
      for (final (_, mode, options) in _searches) {
        for (var k = 0; k < 40; k++) {
          final point = points[(k * 977) % points.length] as PointElement;
          final r = _reach(point);
          final d = const [0.0, 0.5, 0.999, 1.0, 1.5][k % 5] * r;
          final e = _Event(chart, point.x + d, point.y - d / 2);
          final expected = _items(
            chart,
            _expected(chart, mode, options, e, null),
          );
          expect(_items(chart, mode.itemsAt(chart, e, options)), expected);
          if (expected.isNotEmpty) hits++;
        }
      }
      expect(hits, greaterThan(150));
    });

    testWidgets('an update, new values and a resize', (tester) async {
      final chart = _scatterChart(count: 240);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
      _setData(chart, 80, 3);
      chart.update(UpdateMode.none);
      expect(chart.getDatasetMeta(0).data, hasLength(80));
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
      chart.resize(500, 300);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
    });

    testWidgets('points that animate: the current and the final positions', (
      tester,
    ) async {
      final chart = _scatterChart(
        count: 200,
        animation: <String, Object?>{'duration': 400},
      );
      expect(animator.has(chart), isTrue);
      await pumpFrame();
      await pumpFrame();
      final first = chart.getDatasetMeta(0).data[5] as PointElement;
      expect(first.$animations!['y']!.active(), isTrue);
      final moving = _expectItemsOfPublicLoop(chart);
      final movingFinal = _expectItemsOfPublicLoop(
        chart,
        useFinalPosition: true,
      );
      expect(moving, greaterThan(100));
      expect(movingFinal, greaterThan(100));
      await pumpFrames(() => !animator.has(chart));
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
      expect(
        _expectItemsOfPublicLoop(chart, useFinalPosition: true),
        greaterThan(300),
      );

      // A new animated update moves each point.
      _setData(chart, 200, 7);
      chart.update();
      await pumpFrame();
      expect(animator.has(chart), isTrue);
      expect(first.$animations!['y']!.active(), isTrue);
      _expectItemsOfPublicLoop(chart);
      expect(
        _expectItemsOfPublicLoop(chart, useFinalPosition: true),
        greaterThan(300),
      );
      await pumpFrames(() => !animator.has(chart));
    });
  });

  group('each guard declines to the calls of the public loop', () {
    testWidgets('a point with a center that is not a number', (tester) async {
      final chart = _scatterChart(count: 100);
      final data = chart.getDatasetMeta(0).data;
      (data[10] as PointElement).x = double.nan;
      (data[20] as PointElement)['y'] = undefined;
      (data[30] as PointElement).y = double.infinity;
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
    });

    testWidgets('a point with options of a program', (tester) async {
      final chart = _scatterChart(count: 100);
      final data = chart.getDatasetMeta(0).data;
      final point = data[50] as PointElement
        ..options = PointOptions({'radius': 30, 'hitRadius': 2});
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
      // The large radius of the Map hits at 20 pixels.
      final items = const PointInteractionMode().itemsAt(
        chart,
        _Event(chart, point.x + 20, point.y),
        <String, Object?>{},
      );
      expect(_items(chart, items), contains('0:50'));
    });

    testWidgets('an element of a program among the points', (tester) async {
      final chart = _scatterChart(count: 200);
      final data = chart.getDatasetMeta(0).data;
      final plain = _plainCopy(data[40] as PointElement);
      data[40] = plain;
      expect(plain.typedWrites, isFalse);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
      final e = _Event(chart, plain.x, plain.y);
      final items = const PointInteractionMode().itemsAt(
        chart,
        e,
        <String, Object?>{},
      );
      expect(items.first.element, same(plain));
      expect(plain.inRangeCalls.last, (e.x, e.y, null));
    });

    testWidgets('a dataset that starts with an element of a program', (
      tester,
    ) async {
      final chart = _scatterChart(count: 80, datasets: 2);
      final data = chart.getDatasetMeta(0).data;
      final plain = _plainCopy(data[0] as PointElement);
      data[0] = plain;
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
      // The upstream loop serves the dataset: the element gets one call for
      // each search.
      final point = data[50] as PointElement;
      final before = plain.inRangeCalls.length;
      const PointInteractionMode().itemsAt(
        chart,
        _Event(chart, point.x, point.y),
        <String, Object?>{},
      );
      expect(plain.inRangeCalls, hasLength(before + 1));
    });

    // The position is the live event, and the handler of upstream reads it
    // for each element. So a point after an element of a program is tested
    // against the position that the element left.
    testWidgets('an element of a program moves the event', (tester) async {
      final chart = _scatterChart(count: 200, datasets: 2);
      final data = chart.getDatasetMeta(0).data;
      final plain = _plainCopy(data[40] as PointElement);
      data[40] = plain;
      final later = data[150] as PointElement;
      final next = chart.getDatasetMeta(1).data[60] as PointElement;
      for (final target in [later, next]) {
        List<ActiveElement> search(
          List<ActiveElement> Function(_MovingEvent e) items,
        ) {
          final e = _MovingEvent(chart, plain.x, plain.y);
          plain.onInRange = () {
            e
              ..x = target.x
              ..y = target.y;
          };
          try {
            return items(e);
          } finally {
            plain.onInRange = null;
          }
        }

        for (final (name, mode, options) in _searches) {
          final actual = search((e) => mode.itemsAt(chart, e, options));
          final expected = search(
            (e) => _expected(chart, mode, options, e, null),
          );
          expect(_items(chart, actual), _items(chart, expected), reason: name);
        }
        final items = _items(
          chart,
          search(
            (e) => const PointInteractionMode().itemsAt(
              chart,
              e,
              <String, Object?>{},
            ),
          ),
        );
        expect(items, startsWith('0:40'));
        expect(items, contains(identical(target, later) ? '0:150' : '1:60'));
      }
    });

    testWidgets('a program moves a point, and an update widens the reach, '
        'between two searches', (tester) async {
      final chart = _scatterChart(count: 200);
      final data = chart.getDatasetMeta(0).data;
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
      // The scan keeps no result of a search.
      final moved = data[10] as PointElement;
      final target = data[150] as PointElement;
      final wide = data[60] as PointElement;
      final dataset =
          ((chart.data as Map<String, Object?>)['datasets']!
                  as List<Object?>)[0]!
              as Map<String, Object?>;
      dataset['pointHitRadius'] = 40;
      chart.update(UpdateMode.none);
      expect(_reach(wide), 43);
      moved
        ..x = target.x
        ..y = target.y;
      expect(_expectItemsOfPublicLoop(chart), greaterThan(300));
      const mode = PointInteractionMode();
      expect(
        _items(
          chart,
          mode.itemsAt(
            chart,
            _Event(chart, target.x, target.y),
            <String, Object?>{},
          ),
        ),
        contains('0:10'),
      );
      expect(
        _items(
          chart,
          mode.itemsAt(
            chart,
            _Event(chart, wide.x + 35, wide.y),
            <String, Object?>{},
          ),
        ),
        contains('0:60'),
      );
    });
  });

  group('the callers of the search', () {
    testWidgets('the public loop still visits each point', (tester) async {
      final chart = _scatterChart(count: 300);
      final point = chart.getDatasetMeta(0).data[150] as PointElement;
      final visited = <int>[];
      Interaction.evaluateInteractionItems(
        chart,
        InteractionAxis.xy,
        _Event(chart, point.x, point.y),
        (element, datasetIndex, index) => visited.add(index),
        true,
      );
      expect(visited, [for (var i = 0; i < 300; i++) i]);
    });

    testWidgets('the hover and the tooltip of mouse moves', (tester) async {
      final chart = _scatterChart(count: 150, datasets: 2);
      final area = chart.chartArea!;
      final points = chart.getDatasetMeta(0).data;
      final positions = <(double, double)>[
        for (var j = 0; j < points.length; j += (points.length ~/ 9) + 1)
          ((points[j] as PointElement).x, (points[j] as PointElement).y + 2),
        (area.left + 1, area.top + 1),
        ((area.left + area.right) / 2, area.bottom - 1),
      ];
      const mode = PointInteractionMode();
      final search = <String, Object?>{};
      var hits = 0;
      for (final (x, y) in positions) {
        await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
          'x': x,
          'y': y,
        });
        // The host rounds the position of the event.
        final e = _Event(chart, x.roundToDouble(), y.roundToDouble());
        final expected = _items(chart, _expected(chart, mode, search, e, null));
        if (expected.isNotEmpty) hits++;
        final tooltip = chart.tooltip!;
        expect(_items(chart, chart.getActiveElements()), expected);
        expect(_items(chart, tooltip.getActiveElements()), expected);
        expect(tooltip.opacity, expected.isEmpty ? 0 : 1);
        // An update replays the move with the final positions.
        chart.update(UpdateMode.none);
        final replay = _items(chart, _expected(chart, mode, search, e, true));
        expect(_items(chart, chart.getActiveElements()), replay);
        expect(_items(chart, tooltip.getActiveElements()), replay);
      }
      expect(hits, greaterThan(5));
    });
  });
}
