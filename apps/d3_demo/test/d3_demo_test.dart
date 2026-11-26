// Original code, not ported from D3: widget tests for the combined D3 demo app.

import 'package:d3_demo/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('renders all three D3 demo tabs and interacts cleanly', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const D3DemoApp());

    // Tab 0: Color demo.
    expect(find.text('D3 for Flutter'), findsOneWidget);
    expect(
      find.text('CSS Color Parser, 5 Color Spaces & CIELCh Gamut Slicer'),
      findsOneWidget,
    );
    expect(find.text('In sRGB gamut'), findsOneWidget);

    await tester.tap(find.text('rebeccapurple'));
    await tester.pump();
    expect(find.textContaining('#663399'), findsWidgets);

    // Tab 1: Interpolate demo.
    await tester.tap(find.text('Interpolate'));
    await tester.pump();
    expect(
      find.text('Smooth Pan-and-Zoom, Perceptual Blending & 2D Transforms'),
      findsOneWidget,
    );

    await tester.tap(find.text('Orion Core'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Gray → Steelblue'));
    await tester.pump();
    await tester.tap(find.text('Gray → Steelblue'));
    await tester.pump();

    // Tab 2: Chromatic demo.
    await tester.tap(find.text('Chromatic'));
    await tester.pump();
    expect(
      find.text('Live Scalar Heatmap, Color-Vision Check & 76-Scheme Browser'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cividis'));
    await tester.pump();
    expect(find.text('Interactive Scalar Field — Cividis'), findsOneWidget);

    await tester.ensureVisible(find.text('Diverging (9)'));
    await tester.pump();
    await tester.tap(find.text('Diverging (9)'));
    await tester.pump();
    expect(find.text('ColorBrewer classes k = 7'), findsOneWidget);

    await tester.ensureVisible(find.text('Cyclical (2)'));
    await tester.pump();
    await tester.tap(find.text('Cyclical (2)'));
    await tester.pump();
    expect(find.text('Rainbow (wraps 0 ≡ 1)'), findsOneWidget);
  });
}
