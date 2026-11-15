// Original code, not ported from Chart.js: the tests of the shadcn/ui replicas.
@TestOn('vm')
library;

import 'package:chartjs_docs/examples/line_examples.dart';
import 'package:chartjs_docs/migrate/shadcn/line_default.dart';
import 'package:chartjs_docs/migrate/shadcn/line_interactive.dart';
import 'package:chartjs_docs/migrate/shadcn/shadcn_data.dart';
import 'package:chartjs_docs/migrate/shadcn/shadcn_kit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<TestGesture> _mount(WidgetTester tester, Widget replica) async {
  tester.view
    ..physicalSize = const Size(800, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: replica)));
  await tester.pump(const Duration(seconds: 2));
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

Future<void> _move(WidgetTester tester, TestGesture mouse, Offset to) async {
  await mouse.moveTo(to);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

ShadcnTipState _tip(WidgetTester tester) =>
    tester.widget<ShadcnTooltipBox>(find.byType(ShadcnTooltipBox)).tip;

void main() {
  setUpAll(registerCharts);

  test('the value axis has the 5 ticks of Recharts', () {
    expect(rechartsRange([186, 305, 237, 73, 209, 214]), (0, 320, 80));
    expect(rechartsRange([275, 200, 187, 173, 90]), (0, 280, 70));
    expect(rechartsRange([266, 505, 357, 263, 339, 354]), (0, 600, 150));
    expect(rechartsRange([186, 205, -207, 173, -209, 214]), (-300, 300, 150));
  });

  test('the texts of the numbers and the dates are those of en-US', () {
    expect(thousands(24828), '24,828');
    expect(thousands(999), '999');
    expect(shortDate('2024-04-01'), 'Apr 1');
    expect(shortDate('2024-06-30', year: true), 'Jun 30, 2024');
  });

  testWidgets('the tooltip widget shows the hovered month', (tester) async {
    final mouse = await _mount(tester, const ShadcnLineDefault());
    final chart = tester.getRect(find.byType(ChartView));
    await _move(tester, mouse, chart.center);
    expect(find.byType(ShadcnTooltipBox), findsOneWidget);
    final tip = _tip(tester);
    expect(tip.label, isNull, reason: 'hideLabel');
    expect(tip.rows.single.name, 'Desktop');
    expect(tip.rows.single.color, Shadcn.chart1);
    expect(tester.takeException(), isNull);
    await _move(tester, mouse, Offset.zero);
    expect(find.byType(ShadcnTooltipBox), findsNothing);
  });

  testWidgets('a series button shows the other series', (tester) async {
    final mouse = await _mount(tester, const ShadcnLineInteractive());
    final chart = tester.getRect(find.byType(ChartView));
    final at = Offset(chart.left + chart.width / 3, chart.center.dy);
    await _move(tester, mouse, at);
    final label = _tip(tester).label;
    final (_, desktop, mobile) = visitorsByDay.firstWhere(
      (day) => shortDate(day.$1, year: true) == label,
    );
    expect(_tip(tester).rows.single.name, 'Page Views');
    expect(_tip(tester).rows.single.value, '$desktop');
    expect(_tip(tester).rows.single.color, Shadcn.chart1);
    await _move(tester, mouse, Offset.zero);
    await tester.tap(find.byKey(const ValueKey('shadcn-line-interactive.1')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await _move(tester, mouse, at);
    expect(_tip(tester).label, label);
    expect(_tip(tester).rows.single.value, '$mobile');
    expect(_tip(tester).rows.single.color, Shadcn.chart2);
    expect(tester.takeException(), isNull);
  });
}
