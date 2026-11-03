// Original code, not ported from Chart.js: stress-screen information hierarchy.
import 'package:chartjs_gallery/demo/stress_demo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stress_controls.dart';

void main() {
  testWidgets('readable controls, optional settings and diagnostics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StressDemo(
            autoStart: false,
            initialMode: StressMode.chart,
            initialType: StressChartType.bar,
            initialN: 12,
            initialM: 0,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Test target'), findsOneWidget);
    expect(find.text('Chart type'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('Overlay labels'), findsOneWidget);
    expect(find.text('Full update'), findsOneWidget);
    expect(find.text('Polar area'), findsOneWidget);
    expect(find.text('Run test'), findsOneWidget);
    expect(find.textContaining('helpers.extras:'), findsNothing);
    expect(find.byKey(const ValueKey('stress.spin')), findsOneWidget);
    await stressTap(tester, 'stress.spin');
    await tester.pump();
    expect(find.text('Rotate labels'), findsNothing);
    final rotate = find.byKey(const ValueKey('stress.spin'));
    expect(await stressSelected(tester, 'stress.spin'), isTrue);
    final counts = find.byKey(const ValueKey('stress.m.200'));
    expect(
      tester.getCenter(rotate).dy,
      closeTo(tester.getCenter(counts).dy, 1),
    );
    expect(
      tester.getRect(rotate).left,
      greaterThan(tester.getRect(counts).right),
    );
    expect(tester.getSize(rotate).width, lessThanOrEqualTo(48));
    final rotateButton = find.ancestor(
      of: rotate,
      matching: find.byType(SegmentedButton<String>),
    );
    final countButtons = find.ancestor(
      of: counts,
      matching: find.byType(SegmentedButton<int>),
    );
    expect(
      tester.getSize(rotateButton).height,
      tester.getSize(countButtons).height,
    );
    expect(
      tester.widget<SegmentedButton<String>>(rotateButton).style,
      tester.widget<SegmentedButton<int>>(countButtons).style,
    );
    await stressTap(tester, 'stress.mode.arcs');
    await tester.pump();
    expect(find.text('Drawing test'), findsOneWidget);
    expect(find.text('Chart type'), findsNothing);
    expect(await stressSelected(tester, 'stress.mode.arcs'), isTrue);
    await stressTap(tester, 'stress.mode.chart');
    await tester.pump();
    expect(find.text('Chart type'), findsOneWidget);
    await stressTap(tester, 'stress.target.drawing');
    await tester.pump();
    expect(await stressSelected(tester, 'stress.mode.arcs'), isTrue);
    await tester.ensureVisible(
      find.byKey(const ValueKey('stress.diagnostics')),
    );
    await tester.tap(find.text('Diagnostics'));
    await tester.pumpAndSettle();
    expect(find.textContaining('helpers.extras:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large text wraps choices without horizontal overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: StressDemo(
              autoStart: false,
              initialMode: StressMode.chart,
              initialType: StressChartType.bar,
              initialN: 12,
              initialM: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    for (final type in StressChartType.values) {
      final rect = tester.getRect(
        find.byKey(ValueKey('stress.chart.type.${type.name}')),
      );
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360));
    }
    await stressTap(tester, 'stress.chart.indexed');
    await tester.pumpAndSettle();
    expect(find.text('Indexed colors'), findsOneWidget);
    expect(await stressSelected(tester, 'stress.chart.indexed'), isTrue);
    final indexed = tester.getRect(
      find.byKey(const ValueKey('stress.chart.indexed')),
    );
    expect(indexed.left, greaterThanOrEqualTo(0));
    expect(indexed.right, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });
}
