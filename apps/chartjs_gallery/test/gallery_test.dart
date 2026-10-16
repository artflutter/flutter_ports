import 'package:chartjs_gallery/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chartjs/flutter_chartjs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lists the tracked version and every chart type', (
    tester,
  ) async {
    await tester.pumpWidget(const GalleryApp());

    expect(find.text('Tracking Chart.js $chartJsVersion'), findsOneWidget);
    for (final type in chartTypes) {
      await tester.scrollUntilVisible(find.text(type), 100);
      expect(find.text(type), findsOneWidget);
    }
  });

  testWidgets('marks unported chart types as disabled', (tester) async {
    await tester.pumpWidget(const GalleryApp());

    final tile = tester.widget<ListTile>(
      find.ancestor(of: find.text('Bar'), matching: find.byType(ListTile)),
    );
    expect(tile.enabled, isFalse);
  });
}
