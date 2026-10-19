import 'package:chartjs_gallery/demo/color_demo.dart';
import 'package:chartjs_gallery/demo/ticks_demo.dart';
import 'package:chartjs_gallery/helpers_demo.dart';
import 'package:chartjs_gallery/main.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the demo page at [size] logical pixels.
Future<void> _pumpDemo(WidgetTester tester, {Size? size}) async {
  if (size != null) {
    tester.view
      ..physicalSize = size * tester.view.devicePixelRatio
      ..devicePixelRatio = tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(colorSchemeSeed: const Color(0xFFFF6384)),
      home: const HelpersDemoPage(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  final tab = find.widgetWithText(Tab, label);
  await tester.ensureVisible(tab);
  await tester.pumpAndSettle();
  await tester.tap(tab);
  await tester.pumpAndSettle();
}

/// The vertical scrollable of the open tab.
final Finder _page = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

/// The text of the spline readout.
String _readout(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('spline.readout')),
        matching: find.byType(Text),
      ),
    )
    .data!;

/// The canvas position of the last dragged point, from the readout.
Offset _readPoint(WidgetTester tester) {
  final m = RegExp(
    r'^point \d+ \(([-\d.]+), ([-\d.]+)\)',
  ).firstMatch(_readout(tester))!;
  return Offset(double.parse(m[1]!), double.parse(m[2]!));
}

Future<void> _scrollTo(WidgetTester tester, Finder finder, [double dy = 200]) =>
    tester.scrollUntilVisible(finder, dy, scrollable: _page.first);

void main() {
  testWidgets('the gallery opens the demo from its first entry', (
    tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());
    expect(
      find.text('Phase 2: ported helpers — live demo'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('gallery.helpersDemo')));
    await tester.pumpAndSettle();
    expect(find.byType(HelpersDemoPage), findsOneWidget);
    expect(find.text('Phase 2: ported helpers'), findsOneWidget);
  });

  testWidgets('easing: plots every effect and plays a tapped one', (
    tester,
  ) async {
    await _pumpDemo(tester, size: const Size(1280, 900));
    expect(find.text('Now playing: easeOutBounce'), findsOneWidget);
    expect(find.text('linear'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('easing.easeInOutQuad')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    // Halfway: easeInOutQuad(0.5) is 0.5.
    expect(find.textContaining('effect(t) = 0.5000'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Now playing: easeInOutQuad'), findsOneWidget);
    expect(find.textContaining('effect(t) = 1.0000'), findsOneWidget);

    await _scrollTo(tester, find.text('easeInOutBounce'));
    expect(find.text('easeInOutBounce'), findsOneWidget);
  });

  testWidgets('colors: parses the samples, a typed color and mixes', (
    tester,
  ) async {
    await _pumpDemo(tester);
    await _openTab(tester, 'Colors');

    await tester.enterText(find.byKey(const ValueKey('color.input')), 'orange');
    await tester.pump();
    expect(find.text('rgb(255, 165, 0)'), findsOneWidget);
    expect(find.text('#FFA500'), findsOneWidget);

    // rgb.js keeps alpha 127.5 unrounded; hexString truncates it to 7F.
    await _scrollTo(tester, find.text('#FF63847F'));
    expect(find.text('rgba(255, 99, 132, 0.5)'), findsOneWidget);

    await _scrollTo(tester, find.text("'red'"));
    expect(find.text('rgb(255, 0, 0)'), findsOneWidget);
    expect(find.text('hsl(0, 100%, 50%)'), findsOneWidget);
    await _scrollTo(tester, find.text("'${sampleColors.last}'"));
    expect(find.textContaining('valid: false'), findsOneWidget);

    await _scrollTo(tester, find.byKey(const ValueKey('color.weight')));
    Finder mixed(String text) => find.descendant(
      of: find.byKey(const ValueKey('color.mixed')),
      matching: find.text(text),
    );
    // weight 0.5 of #FF6384 and #36A2EB.
    expect(mixed('rgb(155, 131, 184)'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('color.weight')),
      const Offset(-1000, 0),
    );
    await tester.pump();
    // weight 0: the second color.
    expect(mixed('rgb(54, 162, 235)'), findsOneWidget);
    expect(mixed('#36A2EB'), findsOneWidget);
  });

  testWidgets('tick labels: formats the ranges and follows the locale', (
    tester,
  ) async {
    await _pumpDemo(tester);
    await _openTab(tester, 'Ticks');
    // The value line and the label of the tick 0.5.
    expect(find.text('0.5'), findsWidgets);

    // The page builds all its cards: two cards have the label 1,000,000.
    await _scrollTo(tester, find.text('1,000,000').first);
    expect(find.text('1,000,000'), findsNWidgets(2));

    await _scrollTo(
      tester,
      find.byKey(const ValueKey('ticks.locale')),
      -200,
    );
    await tester.tap(find.byKey(const ValueKey('ticks.locale')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tickLocales[1]).last);
    await tester.pumpAndSettle();
    expect(find.text('0,5'), findsOneWidget);
    await _scrollTo(tester, find.text('1.000.000').first);
    expect(find.text('1.000.000'), findsNWidgets(2));

    // delta 0.05: two decimals, with the de-DE decimal comma.
    await _scrollTo(tester, find.text('-0,45'));
    expect(find.text('-0,45'), findsOneWidget);

    await _scrollTo(tester, find.text('Logarithmic 1 … 1e9'));
    expect(find.text("''"), findsWidgets);

    // The tab keeps its state: the locale survives a tab switch.
    await _openTab(tester, 'Colors');
    await _openTab(tester, 'Ticks');
    expect(find.text("''"), findsWidgets);
    await _scrollTo(tester, find.text('-0,45'), -200);
    expect(find.text('-0,45'), findsOneWidget);
  });

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('splines: a ${kind.name} drag moves a point', (tester) async {
      await _pumpDemo(tester, size: const Size(412, 915));
      await _openTab(tester, 'Splines');
      final box = tester.getRect(find.byKey(const ValueKey('spline.canvas')));
      final scroll = tester.state<ScrollableState>(_page.first).position;
      final scrolled = scroll.pixels;

      // The second point starts at (0.18, 0.30) of the canvas. A vertical
      // touch drag must move the point, not scroll the page.
      final before = Offset(box.width * 0.18, box.height * 0.30);
      for (final delta in const [Offset(0, 60), Offset(0, -40), Offset(8, 0)]) {
        final from = _readPoint(tester);
        await tester.dragFrom(box.topLeft + from, delta, kind: kind);
        await tester.pump();
        final to = _readPoint(tester);
        expect(to.dx, closeTo(from.dx + delta.dx, 0.11), reason: '$delta');
        expect(to.dy, closeTo(from.dy + delta.dy, 0.11), reason: '$delta');
      }
      expect(scroll.pixels, scrolled);
      final moved = _readPoint(tester) - before;
      expect(moved.dx, closeTo(8, 0.2));
      expect(moved.dy, closeTo(20, 0.2));
    });
  }

  testWidgets('splines: a drag off the points scrolls the page', (
    tester,
  ) async {
    await _pumpDemo(tester, size: const Size(412, 915));
    await _openTab(tester, 'Splines');
    final box = tester.getRect(find.byKey(const ValueKey('spline.canvas')));
    final before = _readPoint(tester);
    final scroll = tester.state<ScrollableState>(_page.first).position;
    expect(scroll.pixels, 0);
    // (0.25, 0.95) of the canvas is far from every point.
    await tester.dragFrom(
      Offset(box.left + box.width * 0.25, box.top + box.height * 0.95),
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    expect(scroll.pixels, greaterThan(0));
    expect(_readPoint(tester), before);
  });

  testWidgets('splines: switches the mode and the options', (tester) async {
    await _pumpDemo(tester, size: const Size(412, 915));
    await _openTab(tester, 'Splines');
    await tester.drag(
      find.byKey(const ValueKey('spline.tension')),
      const Offset(-500, 0),
    );
    await tester.pump();
    // Tension 0: the control points are the point itself.
    final p = _readPoint(tester);
    final xy = '(${p.dx.toStringAsFixed(1)}, ${p.dy.toStringAsFixed(1)})';
    expect(_readout(tester), contains('cp1 $xy   cp2 $xy'));

    await tester.tap(find.text('Monotone'));
    await tester.pump();
    expect(find.byKey(const ValueKey('spline.tension')), findsNothing);
    expect(find.textContaining('splineCurveMonotone'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('spline.cap')));
    await tester.tap(find.byKey(const ValueKey('spline.controls')));
    await tester.tap(find.byKey(const ValueKey('spline.reset')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('options: shows the three states and the option helpers', (
    tester,
  ) async {
    await _pumpDemo(tester);
    await _openTab(tester, 'Options');
    // Absent and undefined go to defaults; null is a value.
    expect(find.text("'rgba(0,0,0,0.1)'"), findsNWidgets(2));
    expect(find.text('null'), findsOneWidget);
    expect(find.text("'#36A2EB'"), findsOneWidget);

    await _scrollTo(tester, find.text("'#059BFF'"));
    expect(find.text("'#059BFF'"), findsOneWidget);

    await _scrollTo(tester, find.text('italic 600 16px Georgia, serif'));
    await _scrollTo(tester, find.text('{top: 1, left: 2}'));
    expect(find.text('{x: 5, y: 10}'), findsOneWidget);
  });

  testWidgets('every tab builds at phone width', (tester) async {
    await _pumpDemo(tester, size: const Size(360, 740));
    for (final tab in helpersDemoTabs) {
      await _openTab(tester, tab.label);
      expect(tester.takeException(), isNull, reason: tab.label);
      // Build every card of the tab: an overflow fails the test.
      for (var i = 0; i < 8; i++) {
        await tester.fling(_page.first, const Offset(0, -600), 3000);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull, reason: tab.label);
    }
  });
}
