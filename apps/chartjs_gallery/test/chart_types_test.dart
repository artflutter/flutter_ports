// Original code, not ported from Chart.js: tests of the chart type pages.

import 'dart:async';

import 'package:chartjs_gallery/charts/chart_type_page.dart';
import 'package:chartjs_gallery/charts/chart_types.dart';
import 'package:chartjs_gallery/demo/demo_controls.dart';
import 'package:chartjs_gallery/main.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/controllers/index.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/elements/index.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Pixel 8a: 412 x 915 logical pixels at DPR 2.625.
const Size _pixel8a = Size(412, 915);

/// A small phone: 360 x 640 logical pixels at DPR 3.
const Size _smallPhone = Size(360, 640);

/// The expected chart of one variant (GA spec section 5.1).
typedef _Expected = ({
  String type,
  List<Type> controllers,
  List<int> counts,
  double aspectRatio,
});

/// The expected charts, by `<stem>.<variant key>`.
const Map<String, _Expected> _expected = {
  'area.origin': (
    type: 'line',
    controllers: [LineController],
    counts: [8],
    aspectRatio: 2,
  ),
  'bar.vertical': (
    type: 'bar',
    controllers: [BarController],
    counts: [7],
    aspectRatio: 2,
  ),
  'bar.horizontal': (
    type: 'bar',
    controllers: [BarController],
    counts: [7],
    aspectRatio: 2,
  ),
  'bubble.bubble': (
    type: 'bubble',
    controllers: [BubbleController],
    counts: [2],
    aspectRatio: 2,
  ),
  'doughnut.doughnut': (
    type: 'doughnut',
    controllers: [DoughnutController],
    counts: [3],
    aspectRatio: 1,
  ),
  'doughnut.pie': (
    type: 'pie',
    controllers: [PieController],
    counts: [3],
    aspectRatio: 1,
  ),
  'line.line': (
    type: 'line',
    controllers: [LineController],
    counts: [7],
    aspectRatio: 2,
  ),
  'line.vertical': (
    type: 'line',
    controllers: [LineController],
    counts: [7],
    aspectRatio: 2,
  ),
  'mixed.mixed': (
    type: 'scatter',
    controllers: [BarController, LineController],
    counts: [4, 4],
    aspectRatio: 2,
  ),
  'polar.polar': (
    type: 'polarArea',
    controllers: [PolarAreaController],
    counts: [5],
    aspectRatio: 1,
  ),
  'radar.radar': (
    type: 'radar',
    controllers: [RadarController, RadarController],
    counts: [7, 7],
    aspectRatio: 1,
  ),
  'scatter.scatter': (
    type: 'scatter',
    controllers: [ScatterController],
    counts: [4],
    aspectRatio: 2,
  ),
};

/// The `fill` warning of core.datasetController.js:285-289.
const String _fillWarning = "Tried to use the 'fill' option";

/// Sets the test view to [size] logical pixels at [dpr].
void _setView(WidgetTester tester, Size size, double dpr) {
  tester.view
    ..physicalSize = size * dpr
    ..devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
}

/// The host of the page of [stem].
Finder _host(String stem) => find.byKey(ValueKey('type.$stem.host'));

/// Pumps the gallery, taps the tile of [stem] and waits for the page and
/// the first update of its chart (the default animation of 1000 ms).
Future<ChartTypePageState> _open(WidgetTester tester, String stem) async {
  await tester.pumpWidget(const GalleryApp());
  final tile = find.byKey(ValueKey('gallery.type.$stem'));
  await tester.scrollUntilVisible(tile, 100);
  await tester.pump();
  await tester.tap(tile);
  await tester.pumpAndSettle();
  final state = tester.state<ChartTypePageState>(find.byType(ChartTypePage));
  expect(state.chart, isNotNull, reason: stem);
  return state;
}

/// Taps the variant [variant] of the page of [stem], and waits for its
/// chart.
Future<void> _selectVariant(
  WidgetTester tester,
  String stem,
  String variant,
) async {
  await tester.tap(find.byKey(ValueKey('type.$stem.variant.$variant')));
  await tester.pumpAndSettle();
}

/// The rect of the host of [stem] lies inside the view of [size].
void _expectInView(WidgetTester tester, String stem, Size size) {
  final view = Offset.zero & size;
  final host = tester.getRect(_host(stem));
  expect(host.height, greaterThan(0), reason: '$stem $host');
  expect(view.contains(host.topLeft), isTrue, reason: '$stem $host in $size');
  expect(
    view.contains(host.bottomRight - const Offset(0.01, 0.01)),
    isTrue,
    reason: '$stem $host in $size',
  );
}

/// Runs [body] and gives the lines that it prints.
Future<List<String>> _printed(Future<void> Function() body) async {
  final lines = <String>[];
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

/// The chart of [state] matches the expected chart of [id].
void _expectChart(WidgetTester tester, ChartTypePageState state, String id) {
  final expected = _expected[id]!;
  final chart = state.chart!;
  final stem = id.split('.').first;
  expect(chart.config.type, expected.type, reason: id);
  final datasets = chart.data['datasets']! as List<Object?>;
  expect(datasets, hasLength(expected.controllers.length), reason: id);
  for (var i = 0; i < datasets.length; i++) {
    final meta = chart.getDatasetMeta(i.toDouble());
    expect(
      meta.controller.runtimeType,
      expected.controllers[i],
      reason: '$id dataset $i',
    );
    expect(meta.data, hasLength(expected.counts[i]), reason: '$id $i');
  }
  final size = tester.getSize(_host(stem));
  expect(
    size.height,
    closeTo(size.width / expected.aspectRatio, 1),
    reason: '$id $size',
  );
  expect(chart.width, size.width, reason: id);
  expect(
    state.datasetsLabel,
    [
      for (var i = 0; i < datasets.length; i++)
        '${chart.getDatasetMeta(i.toDouble()).type} ${expected.counts[i]}',
    ].join(', '),
    reason: id,
  );
  expect(
    find.descendant(
      of: find.byKey(ValueKey('type.$stem.readout')),
      matching: find.textContaining(state.datasetsLabel),
    ),
    findsOneWidget,
    reason: id,
  );
}

/// The page has none of the controls that the layout rule forbids
/// (Chart.js ADR 0031, section 10.2).
void _expectNoForbiddenControls(String stem) {
  expect(find.byType(ChoiceChip), findsNothing, reason: stem);
  expect(find.byType(FilterChip), findsNothing, reason: stem);
  expect(find.byType(ToggleChips), findsNothing, reason: stem);
  expect(find.byType(SliderControl), findsNothing, reason: stem);
  expect(
    find.byWidgetPredicate((w) => w is PopupMenuButton),
    findsNothing,
    reason: stem,
  );
  expect(
    find.byWidgetPredicate((w) => w is DropdownButton),
    findsNothing,
    reason: stem,
  );
  expect(
    find.byWidgetPredicate(
      (w) =>
          w is Scrollable &&
          axisDirectionToAxis(w.axisDirection) == .horizontal,
    ),
    findsNothing,
    reason: stem,
  );
}

/// The point of element [index] of dataset 0 that a hover hits.
Offset _elementCenter(Chart chart, int index) {
  final element = chart.getDatasetMeta(0).data[index];
  final center = switch (element) {
    final BarElement bar => bar.getCenterPoint(true),
    final ArcElement arc => arc.getCenterPoint(true),
    final PointElement point => point.getCenterPoint(true),
    _ => throw StateError('$element'),
  };
  return Offset(center.x, center.y);
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final entry in galleryChartTypes) {
    final stem = entry.stem;
    for (final variant in entry.variants) {
      final id = '$stem.${variant.key}';

      testWidgets('$id: the chart of the docs block at 412 x 915', (
        tester,
      ) async {
        _setView(tester, _pixel8a, 2.625);
        await tester.pumpWidget(const GalleryApp());
        final tile = find.byKey(ValueKey('gallery.type.$stem'));
        await tester.scrollUntilVisible(tile, 100);
        await tester.pump();
        await tester.tap(tile);
        // The route, then the first frame of the page: the host makes the
        // chart in a post-frame callback.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: id);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: id);
        final state = tester.state<ChartTypePageState>(
          find.byType(ChartTypePage),
        );
        expect(state.chart, isNotNull, reason: id);
        if (variant != entry.variants.first) {
          await _selectVariant(tester, stem, variant.key);
          expect(tester.takeException(), isNull, reason: id);
        }
        _expectChart(tester, state, id);
        _expectInView(tester, stem, _pixel8a);
        _expectNoForbiddenControls(stem);
        expect(state.hoverLabel, 'none', reason: id);
      });

      testWidgets('$id: the chart is in view at 360 x 640', (tester) async {
        _setView(tester, _smallPhone, 3);
        final state = await _open(tester, stem);
        if (variant != entry.variants.first) {
          await _selectVariant(tester, stem, variant.key);
        }
        _expectChart(tester, state, id);
        _expectInView(tester, stem, _smallPhone);
        expect(tester.takeException(), isNull, reason: id);
      });
    }
  }

  testWidgets('the page caps its width at 600 logical pixels', (tester) async {
    _setView(tester, const Size(1200, 1600), 1);
    final state = await _open(tester, 'bar');
    // 600 less the padding of 12 on each side.
    expect(tester.getSize(_host('bar')), const Size(576, 288));
    expect(state.chart!.width, 576);
    expect(tester.takeException(), isNull);
  });

  for (final (stem, second) in [
    ('bar', 'horizontal'),
    ('doughnut', 'pie'),
    ('line', 'vertical'),
  ]) {
    testWidgets('$stem: a tap on $second makes a new chart and destroys the '
        'old chart', (tester) async {
      _setView(tester, _pixel8a, 2.625);
      final state = await _open(tester, stem);
      final old = state.chart!;
      await _selectVariant(tester, stem, second);
      final chart = state.chart!;
      expect(identical(chart, old), isFalse);
      expect(chart.config.type, _expected['$stem.$second']!.type);
      expect(chart.attached, isTrue);
      expect(old.canvas, isNull);
      expect(Chart.instances.values, isNot(contains(old)));
      expect(Chart.instances.values, contains(chart));
      final segments = tester.widget<SegmentChoice<int>>(
        find.byType(SegmentChoice<int>),
      );
      expect(segments.value, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('area: the fill origin, no filler, the data of the seed 2026', (
    tester,
  ) async {
    _setView(tester, _pixel8a, 2.625);
    late ChartTypePageState state;
    final lines = await _printed(() async {
      state = await _open(tester, 'area');
    });
    final chart = state.chart!;
    final dataset =
        (chart.data['datasets']! as List<Object?>).single!
            as Map<Object?, Object?>;
    expect(dataset['fill'], 'origin');
    expect(dataset['data'], [
      97.81,
      -42.3,
      84.05,
      -46.6,
      -31.77,
      12.48,
      -59.53,
      -0.87,
    ]);
    expect(chart.isPluginEnabled('filler'), isFalse);
    // core.datasetController.js:285: one warning for the one dataset.
    expect(lines.where((l) => l.startsWith(_fillWarning)), hasLength(1));
    final note = galleryChartTypes.first.note!;
    expect(find.textContaining(note), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('radar: one fill warning for each dataset', (tester) async {
    _setView(tester, _pixel8a, 2.625);
    final lines = await _printed(() => _open(tester, 'radar'));
    expect(lines.where((l) => l.startsWith(_fillWarning)), hasLength(2));
    expect(tester.takeException(), isNull);
  });

  for (final (stem, type) in [
    ('bar', 'bar'),
    ('line', 'line'),
    ('scatter', 'scatter'),
    ('doughnut', 'doughnut'),
  ]) {
    testWidgets('$stem: a mouse hover over element 2 writes the readout', (
      tester,
    ) async {
      _setView(tester, _pixel8a, 2.625);
      final state = await _open(tester, stem);
      final chart = state.chart!;
      expect(chart.config.type, type);
      final origin = tester.getTopLeft(_host(stem));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: origin - const Offset(0, 4));
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(origin + _elementCenter(chart, 2));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final (:label, :value) = chart
          .getDatasetMeta(0)
          .controller!
          .getLabelAndValue(2);
      final text = 'd0#2 $label: $value';
      expect(state.hoverLabel, text);
      expect(
        find.descendant(
          of: find.byKey(ValueKey('type.$stem.readout')),
          matching: find.textContaining(text),
        ),
        findsOneWidget,
      );
      await mouse.moveTo(origin - const Offset(0, 4));
      await tester.pumpAndSettle();
      expect(state.hoverLabel, 'none');
      // The mouseout event rebuilds the readout (the plugin typeReadout).
      expect(
        find.descendant(
          of: find.byKey(ValueKey('type.$stem.readout')),
          matching: find.textContaining('d0#2'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(ValueKey('type.$stem.readout')),
          matching: find.text('hover none'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
