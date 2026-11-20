// Original code, not ported from Chart.js: the typed hover scan of bars.
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
class _PlainBar() extends BarElement {
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

/// An element of a program with the properties of [bar].
_PlainBar _plainCopy(BarElement bar) {
  final plain = _PlainBar();
  for (final key in const [
    'horizontal',
    'base',
    'enableBorderRadius',
    'x',
    'y',
    'height',
    'width',
    'options',
    'borderSkipped',
    'inflateAmount',
  ]) {
    plain[key] = bar[key];
  }
  return plain;
}

/// A mode of a program over a built-in mode.
final class const _FirstItemMode() extends InteractionMode {
  @override
  List<ActiveElement> itemsAt(
    Chart chart,
    Object e,
    Object options, [
    bool? useFinalPosition,
  ]) => const NearestInteractionMode()
      .itemsAt(chart, e, options, useFinalPosition)
      .take(1)
      .toList();
}

/// The searches of a case: the mode and its options. The typed scan serves
/// each of them.
final List<(String, InteractionMode, Map<String, Object?>)> _searches = [
  ('nearest', const NearestInteractionMode(), {'intersect': true}),
  (
    'nearest x',
    const NearestInteractionMode(),
    {'intersect': true, 'axis': InteractionAxis.x},
  ),
  (
    'nearest y',
    const NearestInteractionMode(),
    {'intersect': true, 'axis': InteractionAxis.y},
  ),
  (
    'nearest invisible',
    const NearestInteractionMode(),
    {'intersect': true, 'includeInvisible': true},
  ),
  ('point', const PointInteractionMode(), {}),
  ('point x', const PointInteractionMode(), {'axis': InteractionAxis.x}),
  ('index', const IndexInteractionMode(), {'intersect': true}),
  (
    'index xy',
    const IndexInteractionMode(),
    {'intersect': true, 'axis': InteractionAxis.xy},
  ),
  (
    'index y',
    const IndexInteractionMode(),
    {'intersect': true, 'axis': InteractionAxis.y},
  ),
  ('dataset', const DatasetInteractionMode(), {'intersect': true}),
];

ActiveElement _item(Element element, int datasetIndex, int index) =>
    ActiveElement(element: element, datasetIndex: datasetIndex, index: index);

/// `getIntersectItems` (core.interaction.js:114) over the public loop
/// `Interaction.evaluateInteractionItems`, which the typed scan does not
/// change: it visits each bar that `binarySearch` gives.
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
  return math.sqrt(dx * dx + dy * dy);
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
    final distance = _distance(
      position,
      visual.getCenterPoint(useFinalPosition),
      axis,
    );
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

/// The positions of a case: a grid over the canvas, and the edges of some
/// bars with offsets around the epsilon of `isBetween`.
List<(double?, double?)> _positions(Chart chart) {
  final area = chart.chartArea!;
  final points = <(double?, double?)>[];
  final ys = [
    area.top - 4,
    area.top + 1,
    (area.top + area.bottom) / 2,
    area.bottom - 3,
    area.bottom - 0.5,
    area.bottom + 4,
  ];
  for (var x = area.left - 6; x <= area.right + 6; x += 6.37) {
    for (final y in ys) {
      points.add((x, y));
    }
  }
  for (final meta in chart.getSortedVisibleDatasetMetas()) {
    final data = meta.data;
    for (var j = 0; j < data.length; j += (data.length ~/ 12) + 1) {
      final bar = data[j] as BarElement;
      if (!bar.x.isFinite || !bar.y.isFinite) continue;
      final horizontal = bar.horizontal == true;
      final half = (horizontal ? bar.height : bar.width) / 2;
      final center = horizontal ? bar.y : bar.x;
      final mid = horizontal ? (bar.x + bar.base) / 2 : (bar.y + bar.base) / 2;
      for (final side in [-1.0, 1.0]) {
        for (final d in [0.0, 5e-7, 1e-6, 1.5e-6, 1e-3, -1e-6, -1e-3]) {
          final edge = center + side * (half + d);
          points.add(horizontal ? (mid, edge) : (edge, mid));
        }
      }
      points
        ..add(horizontal ? (bar.x, center) : (center, bar.y))
        ..add(horizontal ? (bar.base, center) : (center, bar.base))
        ..add(horizontal ? (null, center) : (center, null))
        ..add(horizontal ? (mid, null) : (null, mid));
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

/// The values of a dataset: [count] numbers from 10 to 90.
List<num?> _values(int count, int seed) => <num?>[
  for (var i = 0; i < count; i++) 10 + ((i * 37 + seed * 11) % 81),
];

Chart _barChart({
  required int count,
  int datasets = 1,
  Map<String, Object?> options = const {},
  List<Object?> Function(int dataset)? values,
  ChartAnimation animation = ChartAnimation.none,
}) => acquireChartRoot(
  ChartConfigLowering(
    ChartConfig(
      type: ChartKind.bar,
      labels: [for (var i = 0; i < count; i++) 'c$i'],
      datasets: [
        for (var k = 0; k < datasets; k++)
          BarDataset(
            label: 'series $k',
            data: values == null ? _values(count, k) : null,
            extra: values == null ? null : {'data': values(k)},
          ),
      ],
      animation: animation,
      extra: options,
    ),
  ).lower(),
);

void _setData(Chart chart, int count, int seed) {
  final data = chart.data;
  data['labels'] = <Object?>[for (var i = 0; i < count; i++) 'd$i'];
  ((data['datasets']! as List<Object?>)[0]! as JsObjectFace)['data'] = _values(
    count,
    seed,
  );
}

void main() {
  tearDown(releaseCharts);

  group('the typed scan gives the items of the public loop', () {
    testWidgets('one dataset of vertical bars', (tester) async {
      final chart = _barChart(count: 300);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
      expect(
        _expectItemsOfPublicLoop(chart, useFinalPosition: true),
        greaterThan(100),
      );
    });

    testWidgets('grouped bars', (tester) async {
      final chart = _barChart(count: 120, datasets: 3);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
    });

    testWidgets('stacked bars', (tester) async {
      final chart = _barChart(
        count: 90,
        datasets: 3,
        options: <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'stacked': StackMode.on},
            'y': <String, Object?>{'stacked': StackMode.on},
          },
        },
      );
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
    });

    testWidgets('horizontal bars', (tester) async {
      final chart = _barChart(
        count: 150,
        datasets: 2,
        options: <String, Object?>{'indexAxis': const YAxis()},
      );
      final bar = chart.getDatasetMeta(0).data[75] as BarElement;
      expect(bar.horizontal, true);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
    });

    testWidgets('a reversed index scale', (tester) async {
      final chart = _barChart(
        count: 200,
        options: <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{'reverse': true},
          },
        },
      );
      final data = chart.getDatasetMeta(0).data;
      expect((data[0] as Element).x, greaterThan((data[1] as Element).x));
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
    });

    testWidgets('bars of several widths and null values (skipNull)', (
      tester,
    ) async {
      final chart = _barChart(
        count: 100,
        datasets: 2,
        options: <String, Object?>{'skipNull': true},
        values: (k) => <Object?>[
          for (var i = 0; i < 100; i++)
            if ((i + k) % 3 == 0) null else 10 + ((i * 37 + k * 11) % 81),
        ],
      );
      final widths = {
        for (final bar in chart.getDatasetMeta(0).data)
          (bar as BarElement).width.toStringAsFixed(3),
      };
      expect(widths.length, greaterThan(1));
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
    });

    testWidgets('a small dataset', (tester) async {
      final chart = _barChart(count: 12, datasets: 2);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
    });

    testWidgets('a hidden dataset gives no item', (tester) async {
      final chart = _barChart(count: 120, datasets: 3)
        ..setDatasetVisibility(1, false)
        ..update(UpdateMode.none);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
      final bar = chart.getDatasetMeta(1).data[60] as BarElement;
      final items = const PointInteractionMode().itemsAt(
        chart,
        _Event(chart, bar.x, chart.chartArea!.bottom - 1),
        <String, Object?>{'axis': InteractionAxis.x},
      );
      expect(items.where((item) => item.datasetIndex == 1), isEmpty);
    });

    testWidgets('20,000 bars', (tester) async {
      final chart = _barChart(count: 20000);
      final bars = chart.getDatasetMeta(0).data;
      const mode = NearestInteractionMode();
      final options = <String, Object?>{'intersect': true};
      var hits = 0;
      // Inside a bar, at its two edges, and between two bars.
      for (var k = 0; k < 60; k++) {
        final bar = bars[(k * 331) % bars.length] as BarElement;
        final x = bar.x + const [0.0, -0.45, 0.45, 0.7][k % 4] * bar.width;
        final e = _Event(chart, x, (bar.y + bar.base) / 2);
        final expected = _items(
          chart,
          _expected(chart, mode, options, e, null),
        );
        expect(_items(chart, mode.itemsAt(chart, e, options)), expected);
        if (expected.isNotEmpty) hits++;
      }
      expect(hits, 45);
    });

    testWidgets('an update, new values and a resize', (tester) async {
      final chart = _barChart(count: 240);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));

      // Fewer bars: each bar is wider and at another pixel.
      _setData(chart, 80, 3);
      chart.update(UpdateMode.none);
      expect(chart.getDatasetMeta(0).data, hasLength(80));
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));

      // The same count with other values: the index pixels stay.
      _setData(chart, 80, 5);
      chart.update(UpdateMode.none);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));

      // A resize moves each bar.
      chart.resize(500, 300);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
    });

    testWidgets('bars that animate: the current and the final positions', (
      tester,
    ) async {
      final chart = _barChart(
        count: 200,
        animation: const ChartAnimation(duration: Duration(milliseconds: 400)),
      );
      expect(animator.has(chart), isTrue);
      // Before the first tick each animation is active.
      final first = chart.getDatasetMeta(0).data[0] as BarElement;
      expect(first.$animations!['y']!.active(), isTrue);
      expect(first.$animations!['x']!.active(), isTrue);
      expect(
        _expectItemsOfPublicLoop(chart, useFinalPosition: true),
        greaterThan(100),
      );
      _expectItemsOfPublicLoop(chart);
      // The first frames: each bar is between its base and its end on the
      // value axis.
      await pumpFrame();
      await pumpFrame();
      expect(animator.has(chart), isTrue);
      expect(first.$animations!['y']!.active(), isTrue);
      final moving = _expectItemsOfPublicLoop(chart);
      final movingFinal = _expectItemsOfPublicLoop(
        chart,
        useFinalPosition: true,
      );
      // The bars are short now, and their targets are tall.
      expect(movingFinal, greaterThan(moving));

      await pumpFrames(() => !animator.has(chart));
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
      expect(
        _expectItemsOfPublicLoop(chart, useFinalPosition: true),
        greaterThan(100),
      );

      // A new animated update with fewer bars: the index pixels move.
      _setData(chart, 90, 7);
      chart.update();
      await pumpFrame();
      expect(animator.has(chart), isTrue);
      expect(first.$animations!['x']!.active(), isTrue);
      _expectItemsOfPublicLoop(chart);
      expect(
        _expectItemsOfPublicLoop(chart, useFinalPosition: true),
        greaterThan(100),
      );
      await pumpFrames(() => !animator.has(chart));
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
    });
  });

  group('each guard declines to the calls of the public loop', () {
    testWidgets('a bar with skip as an extra property', (tester) async {
      final chart = _barChart(count: 200);
      final data = chart.getDatasetMeta(0).data;
      for (var j = 0; j < data.length; j += 3) {
        (data[j] as Element)['skip'] = j.isEven;
      }
      expect((data[0] as Element).hasExtras, isTrue);
      expect((data[1] as Element).hasExtras, isFalse);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(50));
      // Bar 0 is skipped, bar 3 is not.
      const mode = NearestInteractionMode();
      final options = <String, Object?>{'intersect': true};
      List<ActiveElement> at(int j) {
        final bar = data[j] as BarElement;
        final y = (bar.y + bar.base) / 2;
        return mode.itemsAt(chart, _Event(chart, bar.x, y), options);
      }

      expect(at(0), isEmpty);
      expect(_items(chart, at(3)), '0:3');
    });

    testWidgets('an element of a program among the bars', (tester) async {
      final chart = _barChart(count: 200);
      final data = chart.getDatasetMeta(0).data;
      final plain = _plainCopy(data[40] as BarElement);
      data[40] = plain;
      expect(plain.typedWrites, isFalse);
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
      final e = _Event(chart, plain.x, (plain.y + plain.base) / 2);
      final items = const NearestInteractionMode().itemsAt(
        chart,
        e,
        <String, Object?>{'intersect': true},
      );
      expect(items.single.element, same(plain));
      // The element takes `inRange` with the position of the event.
      expect(plain.inRangeCalls.last, (e.x, e.y, null));
    });

    testWidgets('a dataset that starts with an element of a program', (
      tester,
    ) async {
      final chart = _barChart(count: 80, datasets: 2);
      final data = chart.getDatasetMeta(0).data;
      final plain = _plainCopy(data[0] as BarElement);
      data[0] = plain;
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
      // The upstream loop serves the dataset: each bar after the element is
      // found, and the element gets one call for each search.
      final bar = data[50] as BarElement;
      final before = plain.inRangeCalls.length;
      final items = const NearestInteractionMode().itemsAt(
        chart,
        _Event(chart, bar.x, (bar.y + bar.base) / 2),
        <String, Object?>{'intersect': true},
      );
      expect(_items(chart, items), '0:50');
      expect(plain.inRangeCalls, hasLength(before + 1));
    });

    // The position is the live event (`getRelativePosition`), and the
    // handler of upstream reads it for each element. So a bar after an
    // element of a program is tested against the position that the element
    // left.
    testWidgets('an element of a program moves the event: the later bars of '
        'its dataset', (tester) async {
      final chart = _barChart(count: 200);
      final data = chart.getDatasetMeta(0).data;
      final plain = _plainCopy(data[40] as BarElement);
      data[40] = plain;
      final target = data[150] as BarElement;
      final y = chart.chartArea!.bottom - 1;
      List<ActiveElement> search(
        List<ActiveElement> Function(_MovingEvent e) items,
      ) {
        final e = _MovingEvent(chart, plain.x, y);
        plain.onInRange = () => e.x = target.x;
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
      // Bar 40 at the first position, and bar 150 at the moved one.
      expect(
        _items(
          chart,
          search(
            (e) => const PointInteractionMode().itemsAt(
              chart,
              e,
              <String, Object?>{},
            ),
          ),
        ),
        '0:40 0:150',
      );
    });

    testWidgets('an element of a program moves the event: the bars of the '
        'next dataset', (tester) async {
      final chart = _barChart(count: 80, datasets: 2);
      final data = chart.getDatasetMeta(0).data;
      // The first dataset starts with an element of a program, so it takes
      // the loop of upstream. The second dataset takes the typed scan.
      final plain = _plainCopy(data[0] as BarElement);
      data[0] = plain;
      final target = chart.getDatasetMeta(1).data[50] as BarElement;
      final y = chart.chartArea!.bottom - 1;
      List<ActiveElement> search(
        List<ActiveElement> Function(_MovingEvent e) items,
      ) {
        final e = _MovingEvent(chart, plain.x, y);
        plain.onInRange = () => e.x = target.x;
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
      expect(
        _items(
          chart,
          search(
            (e) => const PointInteractionMode().itemsAt(
              chart,
              e,
              <String, Object?>{},
            ),
          ),
        ),
        '0:0 1:50',
      );
    });

    testWidgets('a bar with a pixel that is not a number', (tester) async {
      final chart = _barChart(count: 100);
      final data = chart.getDatasetMeta(0).data;
      (data[10] as BarElement).width = double.nan;
      (data[20] as BarElement).base = double.nan;
      (data[30] as BarElement)['x'] = undefined;
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
    });

    testWidgets('a program moves and widens a bar between two searches', (
      tester,
    ) async {
      final chart = _barChart(count: 200);
      final data = chart.getDatasetMeta(0).data;
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
      // The scan keeps no result of a search: it reads the pixels of each
      // bar at each search.
      final moved = data[10] as BarElement;
      final target = data[150] as BarElement;
      moved.x = target.x;
      final wide = data[60] as BarElement;
      final far = data[80] as BarElement;
      wide.width = (far.x - wide.x) * 2 + 2;
      expect(_expectItemsOfPublicLoop(chart), greaterThan(100));
      const mode = PointInteractionMode();
      final y = chart.chartArea!.bottom - 1;
      expect(
        _items(
          chart,
          mode.itemsAt(chart, _Event(chart, target.x, y), <String, Object?>{}),
        ),
        '0:10 0:150',
      );
      expect(
        _items(
          chart,
          mode.itemsAt(chart, _Event(chart, far.x, y), <String, Object?>{}),
        ),
        '0:60 0:80',
      );
    });
  });

  group('the callers of the search', () {
    testWidgets('the public loop still visits each bar', (tester) async {
      final chart = _barChart(count: 300);
      final bar = chart.getDatasetMeta(0).data[150] as BarElement;
      final visited = <int>[];
      Interaction.evaluateInteractionItems(
        chart,
        InteractionAxis.xy,
        _Event(chart, bar.x, bar.y + 1),
        (element, datasetIndex, index) => visited.add(index),
        true,
      );
      expect(visited, [for (var i = 0; i < 300; i++) i]);
    });

    testWidgets('a mode of a program over a built-in mode', (tester) async {
      final chart = _barChart(count: 150, datasets: 2);
      final bar = chart.getDatasetMeta(1).data[70] as BarElement;
      final e = _Event(chart, bar.x, (bar.y + bar.base) / 2);
      final options = <String, Object?>{'intersect': true};
      final items = const _FirstItemMode().itemsAt(chart, e, options);
      expect(_items(chart, items), '1:70');
      expect(
        _items(chart, items),
        _items(
          chart,
          _expected(chart, const NearestInteractionMode(), options, e, null),
        ),
      );
    });

    for (final (name, mode, options)
        in <(String, InteractionMode, Map<String, Object?>)>[
          ('the default interaction', const NearestInteractionMode(), {}),
          (
            'mode index',
            const IndexInteractionMode(),
            {
              'interaction': <String, Object?>{
                'mode': const IndexInteractionMode(),
                'intersect': true,
              },
            },
          ),
        ]) {
      testWidgets('the hover and the tooltip of mouse moves: $name', (
        tester,
      ) async {
        final chart = _barChart(count: 150, datasets: 2, options: options);
        final area = chart.chartArea!;
        final bars = chart.getDatasetMeta(0).data;
        final points = <(double, double)>[
          for (var j = 0; j < bars.length; j += (bars.length ~/ 9) + 1)
            ((bars[j] as BarElement).x, (bars[j] as BarElement).y + 2),
          (area.left + 1, area.top + 1),
          ((area.left + area.right) / 2, area.bottom - 1),
          (area.right - 1, area.bottom - 1),
        ];
        final search = <String, Object?>{'intersect': true};
        var hits = 0;
        for (final (x, y) in points) {
          await triggerMouseEvent(chart, 'mousemove', <String, Object?>{
            'x': x,
            'y': y,
          });
          // The host rounds the position of the event.
          final e = _Event(chart, x.roundToDouble(), y.roundToDouble());
          final expected = _items(
            chart,
            _expected(chart, mode, search, e, null),
          );
          if (expected.isNotEmpty) hits++;
          final tooltip = chart.tooltip!;
          expect(_items(chart, chart.getActiveElements()), expected);
          expect(_items(chart, tooltip.getActiveElements()), expected);
          expect(tooltip.opacity, expected.isEmpty ? 0 : 1);
          // An update replays the move with the final positions.
          chart.update(UpdateMode.none);
          expect(_items(chart, chart.getActiveElements()), expected);
          expect(_items(chart, tooltip.getActiveElements()), expected);
        }
        expect(hits, greaterThan(5));
      });
    }
  });
}
