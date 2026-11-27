// Original code, not ported from D3: widget tests for the combined D3 demo app.

import 'package:d3_demo/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('renders all eleven D3 demo tabs and interacts cleanly', (
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

    // Tab 3: Path demo.
    await tester.tap(find.text('Path'));
    await tester.pump();
    expect(
      find.text('CanvasPath Studio, Live SVG Serializer & Native dart:ui.Path'),
      findsOneWidget,
    );

    await tester.tap(find.text('Gauge Arc (arc)'));
    await tester.pump();
    expect(find.text('Sweep angle'), findsOneWidget);

    await tester.ensureVisible(find.text('pathRound(0)'));
    await tester.pump();
    await tester.tap(find.text('pathRound(0)'));
    await tester.pump();
    expect(find.textContaining('M'), findsWidgets);

    // Tab 4: Shape demo.
    await tester.tap(find.text('Shape'));
    await tester.pump();
    expect(
      find.text('Curves, Arcs, Streamgraph Stacks, Symbols & Links'),
      findsOneWidget,
    );

    await tester.tap(find.text('Arc & Pie'));
    await tester.pump();
    expect(find.text('Inner radius'), findsOneWidget);

    await tester.tap(find.text('Streamgraph Stack'));
    await tester.pump();
    expect(find.text('Stack offset'), findsOneWidget);

    await tester.tap(find.text('Symbols & Links'));
    await tester.pump();
    expect(
      find.text('All 13 Built-In Symbols (7 Fill + 7 Stroke)'),
      findsOneWidget,
    );

    // Tab 5: Format demo.
    await tester.tap(find.text('Format'));
    await tester.pump();
    expect(
      find.text(
        'Number Formatting, Specifier Playground & 59 Built-In Locales',
      ),
      findsOneWidget,
    );
    expect(find.text(r'+$1,234,567.89'), findsOneWidget);

    final decorators = find.byType(InputDecorator);
    expect(decorators, findsNWidgets(3));
    final specHeight = tester.getSize(decorators.at(0)).height;
    final valueHeight = tester.getSize(decorators.at(1)).height;
    final localeHeight = tester.getSize(decorators.at(2)).height;
    expect(valueHeight, closeTo(specHeight, 1.0));
    expect(localeHeight, closeTo(specHeight, 1.0));

    await tester.tap(find.text('SI prefix (.3s)'));
    await tester.pump();
    expect(find.text('1.23M'), findsWidgets);

    await tester.ensureVisible(find.text('fr-FR'));
    await tester.pump();
    await tester.tap(find.text('fr-FR'));
    await tester.pump();
    expect(find.text('1,23M'), findsWidgets);

    // Tab 6: Array demo.
    await tester.tap(find.text('Array'));
    await tester.pump();
    expect(
      find.text('Histograms, Quantile Statistics, Axis Ticks & Gaussian Blur'),
      findsOneWidget,
    );
    expect(find.text('Histogram & Binning Explorer'), findsOneWidget);

    await tester.tap(find.text('Sturges'));
    await tester.pump();
    await tester.tap(find.text('Custom'));
    await tester.pump();
    expect(find.textContaining('Target bins:'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('2D blur2'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
    await tester.tap(find.text('2D blur2'));
    await tester.pump();
    expect(find.textContaining('24×16 scalar field'), findsOneWidget);

    // Tab 7: Contour demo.
    await tester.tap(find.text('Contour'));
    await tester.pump();
    expect(
      find.text('Marching-Squares Contours & 2D Kernel Density'),
      findsOneWidget,
    );
    expect(find.text('Scalar Field Contours'), findsOneWidget);
    expect(find.text('Volcano & Caldera'), findsOneWidget);

    await tester.tap(find.text('Turbo'));
    await tester.pump();
    await tester.tap(find.text('Twin Peaks'));
    await tester.pump();

    await tester.tap(find.text('2D Kernel Density'));
    await tester.pump();
    expect(find.textContaining('Bandwidth:'), findsOneWidget);
    expect(find.textContaining('Cell size:'), findsOneWidget);
    expect(find.text('Peak density'), findsOneWidget);

    // Tab 8: Quadtree demo.
    await tester.tap(find.text('Quadtree'));
    await tester.pump();
    expect(
      find.text(
        '2D Spatial Subdivision, Nearest-Neighbor & Pruned Range Queries',
      ),
      findsOneWidget,
    );
    expect(find.text('Points: 1200'), findsOneWidget);
    expect(find.textContaining('visited ·'), findsOneWidget);

    await tester.tap(find.text('Spiral'));
    await tester.pump();
    await tester.tap(find.text('Unbounded radius'));
    await tester.pump();
    expect(find.text('Radius: ∞'), findsOneWidget);

    // Tab 9: Hierarchy demo.
    await tester.tap(find.text('Hierarchy'));
    await tester.pump();
    expect(
      find.text('Treemap, Sunburst, Circle Packing & Tidy Tree Layouts'),
      findsOneWidget,
    );
    expect(find.text('Tiling algorithm'), findsOneWidget);

    await tester.tap(find.text('Binary'));
    await tester.pump();
    await tester.tap(find.text('Resquarify'));
    await tester.pump();

    await tester.tap(find.text('Sunburst'));
    await tester.pump();
    expect(find.text('Center hole'), findsOneWidget);

    await tester.tap(find.text('Circle Packing'));
    await tester.pump();
    expect(find.text('Depth highlight'), findsOneWidget);
    await tester.tap(find.text('Leaves'));
    await tester.pump();

    await tester.tap(find.text('Tidy Tree / Dendrogram'));
    await tester.pump();
    expect(find.text('Layout algorithm'), findsOneWidget);
    await tester.tap(find.text('Dendrogram (cluster)'));
    await tester.pump();
    await tester.tap(find.text('Radial (linkRadial)'));
    await tester.pump();

    // Tab 10: Chord demo.
    await tester.tap(find.text('Chord'));
    await tester.pump();
    expect(
      find.text('Circular Flow Diagrams & Directed Ribbons'),
      findsOneWidget,
    );
    expect(find.text('Undirected (chord)'), findsOneWidget);

    await tester.tap(find.text('Directed (ribbonArrow)'));
    await tester.pump();
    expect(find.textContaining('Arrowhead radius:'), findsOneWidget);

    await tester.tap(find.text('Transpose (chordTranspose)'));
    await tester.pump();

    await tester.tap(find.text('Circos (4)'));
    await tester.pump();
    await tester.ensureVisible(find.text('Black'));
    await tester.pump();
    expect(find.text('Black'), findsOneWidget);

    await tester.tap(find.text('Black'));
    await tester.pump();
    expect(find.textContaining('Black:'), findsOneWidget);
  });
}
