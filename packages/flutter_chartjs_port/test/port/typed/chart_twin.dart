// Original code, not ported from Chart.js: the chart twins of the typed API.

/// The chart twin of the typed API (Chart.js ADR 0052, section 11): a typed
/// config and its raw twin give the same chart.
///
/// [expectChartTwin] shows the raw twin in a `ChartView.raw` and then the
/// typed config in a `ChartView`, each alone in the same box, and runs the
/// same steps on each chart:
/// 1. the first state, at the end of the start animations;
/// 2. the hover state: a mouse at the center of the data element 1 of the
///    dataset 0, at the end of the hover animations. The step expects an
///    active element on both sides.
///
/// Each state has the observation of `observeControllers` of the
/// controller harness (the chart area, the scales with their options, the
/// stacks, the datasets with the element properties, the resolved element
/// options, the active options and the labels and values, and the hit
/// queries of [hitQueries] on a grid of [hitColumns] x [hitRows] points
/// over the canvas) and the draw calls of one `chart.draw()` (`drawCalls`
/// of the scale harness, with the element draws). The check compares the
/// two sides value by value, with these rules:
/// - Each color compares in its parsed form (`rgbString()` of
///   `@kurkle/color`): a `Color` lowers to an `rgba()` string, and the
///   docs write `rgb()`, hex and named colors. The colors are the values
///   of the option keys `color` and `...Color`, and the arguments of
///   `setFillStyle` and `setStrokeStyle`.
/// - A Map compares as a Map: the key order does not count, because the
///   observation reads the keys of each object in its own order. The key
///   order of the lowered Maps is the subject of `lowering_test.dart`.
/// - NaN equals NaN. Each other value compares with `==`.
///
/// A helper library of the typed tests, not a test file. It is not a pure
/// layer. A test that imports it needs `@TestOn('vm')`.
library;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/kurkle_color/color.dart' as kurkle;
import 'package:flutter_chartjs_port/src/platform/chart_host.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

import '../controllers/controller_chart_harness.dart' show observeControllers;
import '../scales/scale_chart_harness.dart' show drawCalls;

/// The hit queries of each state: `[mode, intersect, axis,
/// includeInvisible]` for `getElementsAtEventForMode`.
const List<List<Object?>> hitQueries = [
  ['index', true, 'x', false],
  ['index', false, 'xy', false],
  ['dataset', true, 'xy', false],
  ['dataset', false, 'y', false],
  ['point', true, 'xy', false],
  ['point', false, 'xy', true],
  ['nearest', true, 'xy', false],
  ['nearest', false, 'x', false],
  ['nearest', false, 'r', false],
  ['x', true, 'x', false],
  ['y', false, 'y', false],
];

/// The columns of the grid of the hit points.
const int hitColumns = 9;

/// The rows of the grid of the hit points.
const int hitRows = 7;

/// The width of the box of each view. The height comes from the aspect
/// ratio of the chart: the box is in a `Column`.
const double boxWidth = 400;

/// One state of a chart: the observation and the draw calls, each with the
/// colors in parsed form.
typedef ChartState = ({Object? observation, Object? calls});

/// [view] at the top left of the test view, in a `Column` of the width
/// [boxWidth]: the aspect ratio of the chart gives its height.
Widget _box(Widget view) => Directionality(
  textDirection: TextDirection.ltr,
  child: Align(
    alignment: Alignment.topLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [SizedBox(width: boxWidth, child: view)],
    ),
  ),
);

/// The chart of the one chart host of the tree.
Chart _chart(WidgetTester tester) {
  final host = tester.renderObject<RenderChartHost>(find.byType(ChartHost));
  return Chart.getChart(host.canvas)!;
}

/// Pumps frames of 16 ms until the animations of [chart] end, for at most
/// 5 seconds of frames.
Future<void> _settle(WidgetTester tester, Chart chart) async {
  await tester.pump();
  for (var i = 0; i < 5000 ~/ 16 && animator.running(chart); i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  await tester.pump();
  expect(animator.running(chart), isFalse, reason: 'the animations end');
}

/// The grid of the hit points over the canvas of [chart]: `[x, y]` in
/// chart pixels.
List<Object?> _hitPoints(Chart chart) => [
  for (var row = 0; row < hitRows; row++)
    for (var column = 0; column < hitColumns; column++)
      [
        chart.width * (column + 0.5) / hitColumns,
        chart.height * (row + 0.5) / hitRows,
      ],
];

/// The state of [chart]: its observation with the hit queries on the grid,
/// and its draw calls.
ChartState _state(Chart chart) => (
  observation: _parseColors(
    observeControllers(
      chart,
      expectedHits: <String, Object?>{
        'points': _hitPoints(chart),
        'queries': hitQueries,
      },
      scaleOptions: true,
    ),
  ),
  calls: _parseCallColors(drawCalls(chart)),
);

/// Shows [view] alone, runs the steps of [expectChartTwin] and gives the
/// state after each step. The tree is empty at the end: the chart is gone.
Future<List<ChartState>> _run(WidgetTester tester, Widget view) async {
  await tester.pumpWidget(_box(view));
  final chart = _chart(tester);
  await _settle(tester, chart);
  final initial = _state(chart);

  final element = chart.getDatasetMeta(0).data[1] as types.VisualElement;
  final center = element.getCenterPoint(true);
  final target = Offset(center.x!, center.y!);
  final origin = tester.getTopLeft(find.byType(ChartHost));
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: origin + target / 2);
  await mouse.moveTo(origin + target);
  await _settle(tester, chart);
  expect(chart.getActiveElements(), isNotEmpty, reason: 'the hover');
  final hovered = _state(chart);
  await mouse.removePointer();

  await tester.pumpWidget(const SizedBox());
  return [initial, hovered];
}

/// The names of the steps of [expectChartTwin].
const List<String> _stepNames = ['initial', 'hover'];

/// Expects the typed [config] in a `ChartView` to give the chart of its raw
/// twin [raw] in a `ChartView.raw`, both with [theme]: the same
/// observations and draw calls in each step (the library doc).
///
/// [rawObservation] maps the observation of the raw chart before the
/// compare, for a value that the typed API writes in another form of the
/// same behavior. A twin that uses it states the reason.
Future<void> expectChartTwin(
  WidgetTester tester, {
  required ChartConfig config,
  required Map<String, Object?> Function() raw,
  ChartThemeData? theme,
  Object? Function(Object? observation)? rawObservation,
}) async {
  final expected = await _run(
    tester,
    ChartView.raw(config: raw(), theme: theme),
  );
  final actual = await _run(tester, ChartView(config: config, theme: theme));
  for (var k = 0; k < _stepNames.length; k++) {
    final step = _stepNames[k];
    final observation = expected[k].observation;
    expectSame(
      actual[k].observation,
      rawObservation == null ? observation : rawObservation(observation),
      '$step: observation',
    );
    expectSame(actual[k].calls, expected[k].calls, '$step: draw calls');
  }
}

/// Expects [actual] to be [expected], value by value (the rules of the
/// library doc). [path] names the value in each reason.
void expectSame(Object? actual, Object? expected, String path) {
  switch (expected) {
    case final Map<String, Object?> map:
      expect(actual, isA<Map<String, Object?>>(), reason: path);
      final other = actual! as Map<String, Object?>;
      expect(
        other.keys.toSet(),
        map.keys.toSet(),
        reason: '$path: the keys',
      );
      for (final MapEntry(:key, :value) in map.entries) {
        expectSame(other[key], value, '$path.$key');
      }
    case final List<Object?> list:
      expect(actual, isA<List<Object?>>(), reason: path);
      final other = actual! as List<Object?>;
      final length = other.length < list.length ? other.length : list.length;
      for (var i = 0; i < length; i++) {
        expectSame(other[i], list[i], '$path[$i]');
      }
      expect(other, hasLength(list.length), reason: '$path: the length');
    case final double value when value.isNaN:
      expect(
        actual,
        isA<double>().having((d) => d.isNaN, 'NaN', isTrue),
        reason: path,
      );
    default:
      expect(actual, expected, reason: path);
  }
}

/// Whether [key] names a color option: `color` or a key that ends in
/// `Color`.
bool _isColorKey(String key) => key == 'color' || key.endsWith('Color');

/// [value] with each color in its parsed form. A value that does not parse
/// stays as it is. A List gets the parse of each item.
Object? _parseColor(Object? value) => switch (value) {
  final String s => kurkle.Color(s).rgbString() ?? s,
  final List<Object?> list => [for (final item in list) _parseColor(item)],
  _ => value,
};

/// [value] with the parsed form of the value of each color key at any
/// depth, and without the key `$animations`: the animations of an element
/// (core.animations.js:71, :159). Both sides end with no running animation.
Object? _parseColors(Object? value) => switch (value) {
  final Map<String, Object?> map => <String, Object?>{
    for (final MapEntry(:key, :value) in map.entries)
      if (key != r'$animations')
        key: _isColorKey(key) ? _parseColor(value) : _parseColors(value),
  },
  final List<Object?> list => [for (final item in list) _parseColors(item)],
  _ => value,
};

/// The calls with a color argument.
const Set<String> _colorCalls = {'setFillStyle', 'setStrokeStyle'};

/// The recorded [calls] with the parsed form of the argument of
/// `setFillStyle` and `setStrokeStyle`.
List<Object?> _parseCallColors(List<Object?> calls) => [
  for (final call in calls.cast<Map<String, Object?>>())
    if (_colorCalls.contains(call['name']))
      <String, Object?>{
        'name': call['name'],
        'args': [
          for (final arg in call['args']! as List<Object?>) _parseColor(arg),
        ],
      }
    else
      call,
];
