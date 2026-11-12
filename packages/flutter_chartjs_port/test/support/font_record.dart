// Original code, not ported from Chart.js: the font in a data compare.

/// The font of the tests (row `adapt-text-style-fonts`).
///
/// The port holds a font as a `ChartTextStyle`, a Flutter `TextStyle`
/// (Chart.js ADR 0116). Upstream data hold the CSS font text of
/// `toFontString`. The generators write the values of that text as a record
/// (`tool/reference/font_record.mjs`), and a test compares the record with
/// the fields of the `TextStyle`:
/// - [fontRecordOf] is the record of a `TextStyle`.
/// - [fontRecordMatcher] matches a `TextStyle` with a record.
/// - [fontObjectRecordOf] is the record of a font option, and
///   [resolvedFontRecordOf] the record of a `toFont` result, for a compare
///   with the JSON of the upstream font objects.
library;

import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:test/test.dart';

/// The record of [font]: `{font: {family, fallback, size, weight, style}}`,
/// the family, the fallback families, the size, the weight value and the
/// style name.
Map<String, Object?> fontRecordOf(TextStyle font) => <String, Object?>{
  'font': <String, Object?>{
    'family': font.fontFamily,
    'fallback': font.fontFamilyFallback ?? const <String>[],
    'size': font.fontSize,
    'weight': font.fontWeight?.value,
    'style': font.fontStyle?.name,
  },
};

/// A matcher of a `TextStyle` whose record ([fontRecordOf]) equals
/// [record].
Matcher fontRecordMatcher(Object? record) =>
    isA<TextStyle>().having(fontRecordOf, 'font record', equals(record));

/// The record of the font option [font], for a compare with the JSON of an
/// upstream font object: `{family, fallback, size, weight, style, height}`.
/// `height` is the `lineHeight` of the upstream object, a multiple of the
/// size.
Map<String, Object?> fontObjectRecordOf(TextStyle font) => <String, Object?>{
  'family': font.fontFamily,
  'fallback': font.fontFamilyFallback ?? const <String>[],
  'size': font.fontSize,
  'weight': font.fontWeight?.value,
  'style': font.fontStyle?.name,
  'height': font.height,
};

/// The record of the result [font] of `toFont`, for a compare with the JSON
/// of an upstream `toFont` result without `string`:
/// `{family, fallback, size, weight, style, lineHeight}`. `lineHeight` is in
/// pixels.
Map<String, Object?> resolvedFontRecordOf(ChartTextStyle font) =>
    <String, Object?>{
      'family': font.fontFamily,
      'fallback': font.fontFamilyFallback ?? const <String>[],
      'size': font.fontSize,
      'weight': font.fontWeight?.value,
      'style': font.fontStyle?.name,
      'lineHeight': font.lineHeight,
    };
