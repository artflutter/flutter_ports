import 'package:chartjs_gallery/charts/chart_types.dart';
import 'package:chartjs_gallery/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/flutter_chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

/// The stems of the docs files, in the order of the docs.
const List<String> _stems = [
  'area',
  'bar',
  'bubble',
  'doughnut',
  'line',
  'mixed',
  'polar',
  'radar',
  'scatter',
];

/// A view that is tall enough for each tile of the home list.
void _tallView(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The tile of [stem].
Finder _tile(String stem) => find.byKey(ValueKey('gallery.type.$stem'));

void main() {
  testWidgets('lists the tracked version and every chart type', (
    tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());

    expect(find.text('Tracking Chart.js $chartJsVersion'), findsOneWidget);
    expect(
      find.text(
        'The chart types render through the ported controllers, '
        'without the plugins of phase 8.',
      ),
      findsOneWidget,
    );
    for (final entry in galleryChartTypes) {
      await tester.scrollUntilVisible(find.text(entry.title), 100);
      expect(find.text(entry.title), findsOneWidget);
    }
  });

  testWidgets('the nine tiles have their keys in the order of the docs', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(const GalleryApp());

    expect([for (final entry in galleryChartTypes) entry.stem], _stems);
    var top = double.negativeInfinity;
    for (final stem in _stems) {
      expect(_tile(stem), findsOneWidget, reason: stem);
      final y = tester.getTopLeft(_tile(stem)).dy;
      expect(y, greaterThan(top), reason: stem);
      top = y;
    }
  });

  testWidgets('each tile is enabled; only Area is partial, with its note', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(const GalleryApp());

    var done = 0;
    for (final entry in galleryChartTypes) {
      final tile = tester.widget<ListTile>(_tile(entry.stem));
      expect(tile.enabled, isTrue, reason: entry.stem);
      expect(tile.onTap, isNotNull, reason: entry.stem);
      final icon = entry.stem == 'area'
          ? Icons.timelapse
          : Icons.check_circle_outline;
      expect(
        find.descendant(of: _tile(entry.stem), matching: find.byIcon(icon)),
        findsOneWidget,
        reason: entry.stem,
      );
      final subtitle = entry.stem == 'area'
          ? 'Line only: the fill needs plugin.filler (phase 8)'
          : 'docs/charts/${entry.stem}.md';
      expect(
        find.descendant(of: _tile(entry.stem), matching: find.text(subtitle)),
        findsOneWidget,
        reason: entry.stem,
      );
      if (entry.note == null) done++;
    }
    expect(done, 8);
    expect(galleryChartTypes.first.note, isNotNull);
  });
}
