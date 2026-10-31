import 'package:chartjs_gallery/charts/chart_type_page.dart';
import 'package:chartjs_gallery/charts/chart_types.dart';
import 'package:chartjs_gallery/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
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

/// Opens the page of [stem] and gives its chart.
Future<Chart> _openChart(WidgetTester tester, String stem) async {
  await tester.pumpWidget(const GalleryApp());
  await tester.scrollUntilVisible(_tile(stem), 100);
  await tester.pump();
  await tester.tap(_tile(stem));
  await tester.pumpAndSettle();
  final state = tester.state<ChartTypePageState>(find.byType(ChartTypePage));
  return state.chart!;
}

void main() {
  testWidgets('lists the tracked version and every chart type', (
    tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());

    expect(find.text('Tracking Chart.js $chartJsVersion'), findsOneWidget);
    expect(
      find.text(
        'The chart types render through the ported controllers and '
        'plugins.',
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

  testWidgets('each tile is enabled, with its icon and its docs source', (
    tester,
  ) async {
    _tallView(tester);
    await tester.pumpWidget(const GalleryApp());

    // No type is partial after the filler port: each tile has the icon
    // `check_circle_outline` and its docs source (Chart.js ADR 0031, section
    // 2.1).
    for (final entry in galleryChartTypes) {
      final tile = tester.widget<ListTile>(_tile(entry.stem));
      expect(tile.enabled, isTrue, reason: entry.stem);
      expect(tile.onTap, isNotNull, reason: entry.stem);
      expect(
        find.descendant(
          of: _tile(entry.stem),
          matching: find.byIcon(Icons.check_circle_outline),
        ),
        findsOneWidget,
        reason: entry.stem,
      );
      expect(
        find.descendant(
          of: _tile(entry.stem),
          matching: find.text('docs/charts/${entry.stem}.md'),
        ),
        findsOneWidget,
        reason: entry.stem,
      );
    }
    expect(find.byIcon(Icons.timelapse), findsNothing);
    expect(
      find.textContaining(RegExp('phase 8', caseSensitive: false)),
      findsNothing,
    );
  });

  testWidgets('a dark platform gives the charts the dark preset over the '
      'surface of the dark theme (Chart.js ADR 0050)', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final chart = await _openChart(tester, 'bar');
    expect(
      Theme.of(tester.element(find.byType(ChartTypePage))).brightness,
      Brightness.dark,
    );
    final theme = ChartTheme.maybeOf(tester.element(find.byType(ChartView)));
    expect(theme, galleryDarkChartTheme);
    expect(theme!.surface, galleryDarkTheme.colorScheme.surface);
    // The color token of the dark preset: '#666' mirrored (theming.md §4).
    expect(chart.options['color'], 'rgba(153, 153, 153, 1)');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new platform brightness switches the theme of an open chart', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final chart = await _openChart(tester, 'doughnut');
    final arc = chart.getDatasetMeta(0).data.first;
    // The arc border is the surface of the theme (element.arc.ts:379).
    expect(
      (arc.options! as JsObjectFace)['borderColor'],
      'rgba(255, 255, 255, 1)',
    );
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    // The same chart, with the dark preset after its transition (Chart.js ADR
    // 0050, "Runtime switch").
    final state = tester.state<ChartTypePageState>(find.byType(ChartTypePage));
    expect(state.chart, same(chart));
    expect(chart.options['color'], 'rgba(153, 153, 153, 1)');
    final surface = galleryDarkTheme.colorScheme.surface;
    expect(
      (arc.options! as JsObjectFace)['borderColor'],
      'rgba(${(surface.r * 255).round()}, ${(surface.g * 255).round()}, '
      '${(surface.b * 255).round()}, 1)',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a light platform gives the charts the light preset', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final chart = await _openChart(tester, 'bar');
    expect(
      ChartTheme.maybeOf(tester.element(find.byType(ChartView))),
      const ChartThemeData.light(),
    );
    // The '#666' of core.defaults.js:43 as the light preset gives it.
    expect(chart.options['color'], 'rgba(102, 102, 102, 1)');
    expect(tester.takeException(), isNull);
  });
}
