// Original code, not ported from Chart.js: the tests of the dashboard page.

import 'package:chartjs_supabase_dashboard/src/dashboard_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/memory_metric_source.dart';

/// Pumps [count] frames of 16 ms: the chart eases its ranges in each frame.
Future<void> frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  setUpAll(() => Chart.register(registerables));

  Future<void> showPage(WidgetTester tester, MemoryMetricSource source) async {
    tester.view
      ..physicalSize = const Size(1200, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(DashboardApp(source: source, pump: false));
    await frames(tester, 10);
  }

  testWidgets('the page shows the newest page and the realtime state', (
    tester,
  ) async {
    final source = MemoryMetricSource(rows: 2500);
    await showPage(tester, source);

    expect(find.byKey(const ValueKey('dashboard.chart')), findsOneWidget);
    expect(find.text('Realtime on'), findsOneWidget);
    expect(find.text('1000 rows · 1 page'), findsOneWidget);
    expect(find.text('0 sent · paused'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard.live')), findsNothing);
  });

  testWidgets('the pump button starts and stops the inserts', (tester) async {
    final source = MemoryMetricSource(rows: 100);
    await showPage(tester, source);

    await tester.tap(find.byKey(const ValueKey('dashboard.pump')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('2 sent · every 500 ms'), findsOneWidget);
    expect(find.text('2 received'), findsOneWidget);
    expect(find.text('102 rows · 1 page'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dashboard.pump')));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('2 sent · paused'), findsOneWidget);
  });

  testWidgets('a scroll back in time loads the older pages', (tester) async {
    final source = MemoryMetricSource(rows: 2500);
    await showPage(tester, source);
    expect(source.pageCalls, 1);

    final chart = tester.getCenter(
      find.byKey(const ValueKey('dashboard.chart')),
    );
    // Each scroll down pans the x range 1500 pixels back in time.
    for (var i = 0; i < 8; i++) {
      tester.binding.handlePointerEvent(
        PointerScrollEvent(position: chart, scrollDelta: const Offset(0, 1500)),
      );
      await frames(tester, 2);
    }
    await frames(tester, 30);

    expect(find.byKey(const ValueKey('dashboard.live')), findsOneWidget);
    expect(source.pageCalls, greaterThan(1));
    expect(find.textContaining('2000 rows · 2 pages'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dashboard.live')));
    await frames(tester, 30);
    expect(find.byKey(const ValueKey('dashboard.live')), findsNothing);
  });
}
