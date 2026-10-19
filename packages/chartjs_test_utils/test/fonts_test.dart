// Original code, not ported from Chart.js: tests of the harness test font.
@TestOn('vm')
library;

import 'dart:ui' as ui;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_test/flutter_test.dart';

// The expected widths are the sums of the advance widths in the hmtx table
// of the Liberation Sans 2.1.5 files (2048 units per em), times the font
// size over 2048. They are the advance widths of Arial: Liberation Sans is
// metric-compatible with it. 'Hello' has no kerning pair.

/// 'Hello' at 12px, regular: 4667 units.
const double _helloRegular = 4667 * 12 / 2048;

/// 'Hello' at 12px, bold: 5007 units.
const double _helloBold = 5007 * 12 / 2048;

/// The width of [text] in a paragraph of [family] (with [fallback]) at
/// [size] logical pixels.
double _width(
  String text, {
  String? family,
  List<String>? fallback,
  double size = 12,
  ui.FontWeight weight = ui.FontWeight.w400,
  ui.FontStyle style = ui.FontStyle.normal,
}) {
  final builder = ui.ParagraphBuilder(ui.ParagraphStyle())
    ..pushStyle(
      ui.TextStyle(
        fontFamily: family,
        fontFamilyFallback: fallback,
        fontSize: size,
        fontWeight: weight,
        fontStyle: style,
      ),
    )
    ..addText(text);
  final paragraph = builder.build()
    ..layout(const ui.ParagraphConstraints(width: double.infinity));
  final width = paragraph.maxIntrinsicWidth;
  paragraph.dispose();
  return width;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the flutter tester measures every family with its square font', () {
    // Each glyph of the FlutterTest font is one em wide. This test runs
    // before the install, and shows what the install changes.
    expect(_width('Hello', family: 'Arial'), 5 * 12);
  });

  group('installTestFont', () {
    setUpAll(installTestFont);

    test('Arial 12px measures with the Liberation Sans metrics', () {
      expect(_width('Hello', family: 'Arial'), closeTo(_helloRegular, 0.01));
    });

    test('registers each family name of the Chart.js default font', () {
      expect(testFontFamilies, [
        'Helvetica Neue',
        'Helvetica',
        'Arial',
        'Liberation Sans',
        'sans-serif',
      ]);
      for (final family in testFontFamilies) {
        expect(
          _width('Hello', family: family),
          closeTo(_helloRegular, 0.01),
          reason: family,
        );
      }
      // toFontString of the default font gives
      // "'Helvetica Neue', 'Helvetica', 'Arial', sans-serif".
      expect(
        _width(
          'Hello',
          family: 'Helvetica Neue',
          fallback: ['Helvetica', 'Arial', 'sans-serif'],
        ),
        closeTo(_helloRegular, 0.01),
      );
    });

    test('picks the bold and italic faces', () {
      expect(
        _width('Hello', family: 'Arial', weight: ui.FontWeight.w700),
        closeTo(_helloBold, 0.01),
      );
      // The italic faces have the advances of the upright faces.
      expect(
        _width('Hello', family: 'Arial', style: ui.FontStyle.italic),
        closeTo(_helloRegular, 0.01),
      );
      expect(
        _width(
          'Hello',
          family: 'Arial',
          weight: ui.FontWeight.w700,
          style: ui.FontStyle.italic,
        ),
        closeTo(_helloBold, 0.01),
      );
    });

    test('scales with the font size', () {
      expect(
        _width('Hello', family: 'Arial', size: 24),
        closeTo(_helloRegular * 2, 0.02),
      );
    });

    test('applies the kerning of the font', () {
      // 'Hello World' is 10584 units without kerning. The pair 'Wo' has a
      // kerning of -37 units, as in Arial, and Chrome applies it too.
      expect(
        _width('Hello World', family: 'Arial'),
        closeTo(10547 * 12 / 2048, 0.01),
      );
    });

    test('a text with no family keeps the square font', () {
      // The flutter tester resolves a text style with no family to its own
      // test font. A registered font cannot replace it.
      expect(_width('Hello'), 5 * 12);
    });

    test('a second call returns the same future', () {
      expect(identical(installTestFont(), installTestFont()), isTrue);
    });
  });
}
