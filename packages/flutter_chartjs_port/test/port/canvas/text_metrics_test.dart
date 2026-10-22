// Original code, not ported from Chart.js: the text-metric probe.
@TestOn('vm')
library;

// flutter_test, dart:io and dart:ui: the web legs cannot compile this file.
import 'dart:io';

import 'package:chartjs_test_utils/pure.dart' show toBeCloseToPixel;
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'text_metrics_reference.dart';

// The text-metric probe (Chart.js ADR 0015, doc/text-metrics.md). The test
// measures the cases of tool/reference/text_metrics/text_metrics.html with
// UiCanvasContext.measureText and compares them with the Chrome values of
// text_metrics_reference.dart. flutter_test_config.dart installs Liberation
// Sans 2.1.5, the font files that the Chrome page loads.
//
// With the environment variable TEXT_METRICS_REPORT set to a file path, the
// test also writes the comparison tables of doc/text-metrics.md to that
// file:
//
//   TEXT_METRICS_REPORT=/tmp/text-metrics.md \
//     flutter test test/port/canvas/text_metrics_test.dart

/// The measureText values of one case on the canvas layer.
typedef _Measured = ({
  double width,
  double left,
  double right,
  double ascent,
  double descent,
});

/// The canvas layer metrics of [text] in [font] with [baseline].
_Measured _measure(String font, String text, {String baseline = 'alphabetic'}) {
  final ctx = UiCanvasElement().getContext2d()
    ..font = font
    ..textAlign = 'start'
    ..textBaseline = baseline
    ..direction = 'ltr';
  final m = ctx.measureText(text);
  return (
    width: m.width,
    left: m.actualBoundingBoxLeft,
    right: m.actualBoundingBoxRight,
    ascent: m.actualBoundingBoxAscent,
    descent: m.actualBoundingBoxDescent,
  );
}

/// The position of the alphabetic baseline below the anchor of
/// [baseline], from the `actualBoundingBoxAscent` values: the ink box is
/// fixed to the alphabetic baseline.
double _shift(Map<String, double> ascents, String baseline) =>
    ascents['alphabetic']! - ascents[baseline]!;

/// Whether [actual] is within the toBeCloseToPixel tolerance of [expected].
bool _closeToPixel(double actual, double expected) =>
    toBeCloseToPixel(expected).matches(actual, {});

/// The short name of a probe font in the tables.
String _fontName(String font) =>
    font.replaceFirst(textMetricsFamily, '').replaceFirst('normal ', '').trim();

/// [text] as a table cell.
String _textCell(String text) {
  final hebrew = text.runes.any((r) => r >= 0x590 && r <= 0x5FF);
  return '`$text`${hebrew ? ' (Hebrew)' : ''}';
}

/// [v] with 3 decimals, without the sign of a value that rounds to 0.
String _px(double v) {
  final text = v.toStringAsFixed(3);
  return text == '-0.000' ? '0.000' : text;
}

const List<String> _baselines = [
  'top',
  'hanging',
  'middle',
  'alphabetic',
  'ideographic',
  'bottom',
];

void main() {
  late List<_Measured> measured;
  late List<Map<String, double>> flutterAscents;

  setUpAll(() {
    measured = [
      for (final c in textMetricsCases)
        _measure(textMetricsFonts[c.font].font, c.text),
    ];
    flutterAscents = [
      for (final f in textMetricsFonts)
        {
          for (final b in _baselines)
            b: _measure(f.font, textMetricsBaselineText, baseline: b).ascent,
        },
    ];
  });

  group('text-metric probe against $textMetricsChrome', () {
    test('has the cases of text_metrics.html', () {
      expect(textMetricsFonts, hasLength(5));
      expect(textMetricsCases, hasLength(80));
    });

    for (final (i, f) in textMetricsFonts.indexed) {
      test('gives widths within toBeCloseToPixel of Chrome in '
          '${_fontName(f.font)}', () {
        final misses = <String>[];
        for (final (j, c) in textMetricsCases.indexed) {
          if (c.font != i) continue;
          if (!_closeToPixel(measured[j].width, c.width)) {
            misses.add('${c.text}: ${measured[j].width} vs ${c.width}');
          }
        }
        expect(misses, isEmpty);
      });
    }

    test('gives a box that holds the Chrome ink box, to 0.5 px', () {
      final misses = <String>[];
      for (final (j, c) in textMetricsCases.indexed) {
        final f = measured[j];
        if (f.left < c.left - 0.5 ||
            f.right < c.right - 0.5 ||
            f.ascent < c.ascent - 0.5 ||
            f.descent < c.descent - 0.5) {
          misses.add('${textMetricsFonts[c.font].font} ${c.text}: $f vs $c');
        }
      }
      expect(misses, isEmpty);
    });

    for (final (i, f) in textMetricsFonts.indexed) {
      test('places each textBaseline within 1 px of Chrome in '
          '${_fontName(f.font)}', () {
        for (final b in _baselines) {
          expect(
            _shift(flutterAscents[i], b),
            closeTo(_shift(f.baselines, b), 1),
            reason: b,
          );
        }
      });
    }

    tearDownAll(() {
      final path = Platform.environment['TEXT_METRICS_REPORT'];
      if (path == null || path.isEmpty) return;
      File(path).writeAsStringSync(
        _report(measured, flutterAscents),
      );
    });
  });
}

/// The comparison tables of doc/text-metrics.md.
String _report(List<_Measured> measured, List<Map<String, double>> ascents) {
  final out = StringBuffer()
    ..writeln('Widths:')
    ..writeln()
    ..writeln(
      '| Font | Text | Chrome (px) | Flutter (px) | Difference (px) '
      '| Difference (%) | toBeCloseToPixel |',
    )
    ..writeln('| --- | --- | ---: | ---: | ---: | ---: | --- |');
  var worstPx = 0.0;
  var worstPercent = 0.0;
  for (final (j, c) in textMetricsCases.indexed) {
    final f = measured[j];
    final diff = f.width - c.width;
    final percent = c.width == 0 ? 0.0 : diff / c.width * 100;
    if (diff.abs() > worstPx) worstPx = diff.abs();
    if (percent.abs() > worstPercent) worstPercent = percent.abs();
    out.writeln(
      '| ${_fontName(textMetricsFonts[c.font].font)} | ${_textCell(c.text)} '
      '| ${_px(c.width)} | ${_px(f.width)} | ${_px(diff)} '
      '| ${_px(percent)} '
      '| ${_closeToPixel(f.width, c.width) ? 'yes' : 'no'} |',
    );
  }
  out
    ..writeln()
    ..writeln(
      'Largest difference: ${worstPx.toStringAsExponential(2)} px, '
      '${worstPercent.toStringAsExponential(2)} %.',
    )
    ..writeln()
    ..writeln('Bounding boxes (left, right, ascent, descent):')
    ..writeln()
    ..writeln('| Font | Text | Chrome (px) | Flutter (px) |')
    ..writeln('| --- | --- | --- | --- |');
  for (final (j, c) in textMetricsCases.indexed) {
    final f = measured[j];
    out.writeln(
      '| ${_fontName(textMetricsFonts[c.font].font)} | ${_textCell(c.text)} '
      '| ${_px(c.left)}, ${_px(c.right)}, ${_px(c.ascent)}, '
      '${_px(c.descent)} '
      '| ${_px(f.left)}, ${_px(f.right)}, ${_px(f.ascent)}, '
      '${_px(f.descent)} |',
    );
  }
  out
    ..writeln()
    ..writeln(
      'Baseline offsets (the alphabetic baseline below the anchor, '
      'from `$textMetricsBaselineText`):',
    )
    ..writeln()
    ..writeln(
      '| Font | textBaseline | Chrome (px) | Flutter (px) '
      '| Difference (px) |',
    )
    ..writeln('| --- | --- | ---: | ---: | ---: |');
  for (final (i, font) in textMetricsFonts.indexed) {
    for (final b in _baselines) {
      final chrome = _shift(font.baselines, b);
      final flutter = _shift(ascents[i], b);
      out.writeln(
        '| ${_fontName(font.font)} | `$b` | ${_px(chrome)} '
        '| ${_px(flutter)} | ${_px(flutter - chrome)} |',
      );
    }
  }
  out
    ..writeln()
    ..writeln('Font box (fontBoundingBoxAscent, fontBoundingBoxDescent):')
    ..writeln()
    ..writeln('| Font | Chrome (px) | Flutter ascent, descent (px) |')
    ..writeln('| --- | --- | --- |');
  for (final font in textMetricsFonts) {
    final f = _measure(font.font, textMetricsBaselineText);
    out.writeln(
      '| ${_fontName(font.font)} | ${_px(font.fontAscent)}, '
      '${_px(font.fontDescent)} | ${_px(f.ascent)}, ${_px(f.descent)} |',
    );
  }
  return out.toString();
}
