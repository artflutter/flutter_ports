import 'package:chartjs_gallery/demo/demo_chart.dart';
import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart'
    as element_options;
import 'package:flutter_chartjs/src/elements/index.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:flutter_test/flutter_test.dart';

/// The item count of each mode in these tests: small, so that a frame is
/// fast.
const Map<StressMode, int> _counts = {
  StressMode.primitives: 300,
  StressMode.elements: 300,
  StressMode.bars: 300,
  StressMode.arcs: 100,
};

/// Pumps [count] frames of 20 ms. The loop runs, so pumpAndSettle would not
/// return.
Future<void> _frames(WidgetTester tester, [int count = 4]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Pumps a stress tab in [mode] with the item count of [_counts] and 10
/// labels. It gives the list that receives the published figures.
Future<List<StressStats>> _pumpStress(
  WidgetTester tester,
  StressMode mode, {
  bool autoStart = true,
}) async {
  final stats = <StressStats>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StressDemo(
          initialMode: mode,
          initialN: _counts[mode],
          initialM: 10,
          autoStart: autoStart,
          onStats: stats.add,
        ),
      ),
    ),
  );
  return stats;
}

/// The state of the stress tab.
StressDemoState _state(WidgetTester tester) =>
    tester.state<StressDemoState>(find.byType(StressDemo));

/// The count of draws of the stress chart.
int _renders(WidgetTester tester) => tester
    .state<DemoCanvasState>(find.byKey(const ValueKey('stress.host')))
    .chart!
    .renders;

/// Scrolls the widget of [key] into view and taps it.
Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _frames(tester);
}

/// Whether the chip of [key] is selected.
bool _selected(WidgetTester tester, String key) =>
    tester.widget<ChoiceChip>(find.byKey(ValueKey(key))).selected;

/// A property of [element] that each frame writes, as a number.
double _moving(types.VisualElement element) => switch (element) {
  final PointElement point => point.x + point.y,
  final BarElement bar => bar.y,
  final ArcElement arc => arc.endAngle,
  _ => throw ArgumentError.value(element, 'element'),
};

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  // stress_chart_test.dart tests the mode chart, which has its own host.
  for (final mode in StressMode.values.where((m) => m != StressMode.chart)) {
    testWidgets('${mode.name}: the loop draws and publishes the figures', (
      tester,
    ) async {
      final stats = await _pumpStress(tester, mode);
      await _frames(tester, 10);
      final renders = _renders(tester);
      expect(renders, greaterThan(0));
      await _frames(tester, 5);
      expect(_renders(tester), greaterThan(renders));

      // Stopping publishes the figures.
      await _tap(tester, 'stress.start');
      expect(stats, isNotEmpty);
      expect(stats.last.mode, mode);
      expect(stats.last.points, _counts[mode]);
      expect(stats.last.labels, 10);
      expect(stats.last.frames, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the mode chips select the mode and its N choices', (
    tester,
  ) async {
    await _pumpStress(tester, StressMode.primitives, autoStart: false);
    for (final mode in StressMode.values) {
      expect(
        find.byKey(ValueKey('stress.mode.${mode.name}')),
        findsOneWidget,
      );
    }
    expect(_selected(tester, 'stress.mode.primitives'), isTrue);
    expect(find.byKey(const ValueKey('stress.n.20000')), findsOneWidget);
    expect(find.byKey(const ValueKey('stress.n.100')), findsNothing);
    expect(find.byKey(const ValueKey('stress.layer.points')), findsOneWidget);

    await _tap(tester, 'stress.mode.bars');
    expect(_selected(tester, 'stress.mode.bars'), isTrue);
    expect(_selected(tester, 'stress.mode.primitives'), isFalse);
    // The layer switches of the points and the line go.
    expect(find.byKey(const ValueKey('stress.layer.points')), findsNothing);
    expect(find.byKey(const ValueKey('stress.layer.line')), findsNothing);
    expect(find.byKey(const ValueKey('stress.spin')), findsOneWidget);
    await _tap(tester, 'stress.n.20000');
    expect(_selected(tester, 'stress.n.20000'), isTrue);
    expect(_state(tester).debugElements, hasLength(20000));

    // The arcs go up to 5000: N becomes 5000.
    await _tap(tester, 'stress.mode.arcs');
    expect(_selected(tester, 'stress.mode.arcs'), isTrue);
    expect(find.byKey(const ValueKey('stress.n.100')), findsOneWidget);
    expect(find.byKey(const ValueKey('stress.n.20000')), findsNothing);
    expect(_selected(tester, 'stress.n.5000'), isTrue);
    expect(_state(tester).debugElements, hasLength(5000));

    await _tap(tester, 'stress.mode.elements');
    expect(_selected(tester, 'stress.n.5000'), isTrue);
    expect(find.byKey(const ValueKey('stress.layer.line')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final mode in [StressMode.elements, StressMode.bars, StressMode.arcs]) {
    testWidgets('${mode.name}: the frames write the elements of one build', (
      tester,
    ) async {
      await _pumpStress(tester, mode);
      await _frames(tester, 5);
      final state = _state(tester);
      final n = _counts[mode]!;
      final elements = state.debugElements;
      expect(state.debugSceneBuilds, 1);
      // The point elements and the line, or N bars, or N arcs.
      expect(elements, hasLength(mode == StressMode.elements ? n + 1 : n));
      final before = _moving(elements.first);
      final renders = _renders(tester);

      await _frames(tester, 10);
      expect(_renders(tester), greaterThan(renders));
      expect(state.debugSceneBuilds, 1);
      final after = state.debugElements;
      expect(after, hasLength(elements.length));
      for (var i = 0; i < after.length; i++) {
        expect(identical(after[i], elements[i]), isTrue, reason: '$i');
      }
      // The frames moved the element.
      expect(_moving(after.first), isNot(before));

      if (mode == StressMode.elements) {
        final line = after.last as LineElement;
        expect(line.points, hasLength(n));
        expect(line.animated, isTrue);
        // An animated line keeps no path between two frames
        // (element.line.js:439-443).
        expect(identical(line['_path'], undefined), isTrue);
        // The points share one typed options object, and the line has typed
        // options (Chart.js ADR 0018).
        final options = (after.first as PointElement).options;
        expect(options, isA<element_options.PointOptions>());
        expect(identical((after[1] as PointElement).options, options), isTrue);
        expect(line.options, isA<element_options.LineOptions>());
      }
      if (mode == StressMode.bars) {
        // The bars share one typed options object (Chart.js ADR 0018).
        final options = (after.first as BarElement).options;
        expect(options, isA<element_options.BarOptions>());
        expect(identical((after[1] as BarElement).options, options), isTrue);
      }
      if (mode == StressMode.arcs) {
        expect(
          (after.first as ArcElement).options,
          isA<element_options.ArcOptions>(),
        );
      }

      await _tap(tester, 'stress.start');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a change of N or of the mode makes the elements again', (
    tester,
  ) async {
    await _pumpStress(tester, StressMode.elements, autoStart: false);
    final state = _state(tester);
    expect(state.debugSceneBuilds, 1);
    final first = state.debugElements.first;

    await _tap(tester, 'stress.n.1000');
    expect(state.debugSceneBuilds, 2);
    expect(state.debugElements, hasLength(1001));
    expect(identical(state.debugElements.first, first), isFalse);

    // The same N again changes nothing.
    await _tap(tester, 'stress.n.1000');
    expect(state.debugSceneBuilds, 2);

    await _tap(tester, 'stress.mode.bars');
    expect(state.debugSceneBuilds, 3);
    expect(state.debugElements, everyElement(isA<BarElement>()));

    // The primitives have no elements.
    await _tap(tester, 'stress.mode.primitives');
    expect(state.debugSceneBuilds, 3);
    expect(state.debugElements, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('initialLine false starts without the line layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StressDemo(
            initialMode: StressMode.elements,
            initialLine: false,
          ),
        ),
      ),
    );
    bool selected(String key) =>
        tester.widget<FilterChip>(find.byKey(ValueKey(key))).selected;
    expect(selected('stress.layer.line'), isFalse);
    expect(selected('stress.layer.points'), isTrue);
    await _tap(tester, 'stress.layer.line');
    expect(selected('stress.layer.line'), isTrue);
    expect(tester.takeException(), isNull);
  });
}
