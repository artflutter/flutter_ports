// Original code, not ported from chartjs-chart-sankey: the sankey page tests.

import 'package:chartjs_gallery/main.dart';
import 'package:chartjs_gallery/plugins/sankey_page.dart';
// `Flow` is also a Flutter widget name: the element has the prefix.
import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    as sankey;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A Pixel 8a: 412 x 915 logical pixels at DPR 2.625.
const Size _pixel8a = Size(412, 915);

/// Sets the test view to [size] logical pixels at [dpr].
void _setView(WidgetTester tester, Size size, double dpr) {
  tester.view
    ..physicalSize = size * dpr
    ..devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
}

/// The host of the chart.
final Finder _host = find.byKey(const ValueKey('sankey.host'));

/// Pumps the gallery, opens the page from its tile, selects [variant] and
/// waits for its chart and the end of its first animation.
Future<SankeyPageState> _open(
  WidgetTester tester, [
  String variant = 'basic',
]) async {
  await tester.pumpWidget(const GalleryApp());
  final tile = find.byKey(const ValueKey('gallery.chart.sankey'));
  await tester.scrollUntilVisible(tile, 100);
  await tester.pump();
  await tester.tap(tile);
  await tester.pumpAndSettle();
  if (variant != sankeyPageVariants.first.key) {
    await tester.tap(find.byKey(ValueKey('sankey.variant.$variant')));
    await tester.pumpAndSettle();
  }
  final state = tester.state<SankeyPageState>(find.byType(SankeyPage));
  expect(state.chart, isNotNull, reason: variant);
  expect(tester.takeException(), isNull, reason: variant);
  return state;
}

void main() {
  for (final variant in sankeyPageVariants) {
    testWidgets('the variant ${variant.key} draws its flows, with the chart '
        'in view at 412 x 915', (tester) async {
      _setView(tester, _pixel8a, 2.625);
      final state = await _open(tester, variant.key);
      final chart = state.chart!;

      expect(chart.config.type, 'sankey');
      final meta = chart.getDatasetMeta(0);
      final controller = meta.controller! as sankey.SankeyController;
      final flows = meta.data.cast<sankey.Flow>();
      expect(flows, isNotEmpty);
      expect(controller.nodes.length, greaterThan(2));
      // The first animation ended: each flow is drawn in full.
      for (final flow in flows) {
        expect(flow.progress, 1, reason: variant.key);
      }

      // The layout rule of the gallery: the chart host is fully in view.
      final host = tester.getRect(_host);
      expect(host.top, greaterThanOrEqualTo(0));
      expect(host.bottom, lessThanOrEqualTo(_pixel8a.height));
      expect(host.left, greaterThanOrEqualTo(0));
      expect(host.right, lessThanOrEqualTo(_pixel8a.width));

      expect(tester.getSemantics(_host).label, 'Sankey chart: ${variant.text}');
    });
  }

  testWidgets('a tap on a flow shows its tooltip and the hover readout', (
    tester,
  ) async {
    _setView(tester, _pixel8a, 2.625);
    final state = await _open(tester);
    final chart = state.chart!;
    final flow = chart.getDatasetMeta(0).data.first as sankey.Flow;
    final center = flow.getCenterPoint();

    await tester.tapAt(tester.getTopLeft(_host) + Offset(center.x, center.y));
    await tester.pumpAndSettle();

    expect(chart.getActiveElements(), isNotEmpty);
    expect(chart.tooltip!.body!.single.lines, ['A -> B: 10']);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('sankey.readout')),
        matching: find.textContaining('hover A -> B: 10'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the vertical variant lays out from top to bottom', (
    tester,
  ) async {
    _setView(tester, _pixel8a, 2.625);
    final state = await _open(tester, 'vertical');
    final flow = state.chart!.getDatasetMeta(0).data.first as sankey.Flow;
    expect(flow.y, lessThan(flow.y2));
    expect(flow.width, greaterThan(0));
    expect(flow.height, 0);
  });
}
