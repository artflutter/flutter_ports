// Ported from d3-format v3.1.2 src/formatTrim.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/formatTrim.js` of d3-format 3.1.2.
library;

// DIVERGES(d3-format): adapt-format-fast-forms, code-unit scan without slicing

/// Trims insignificant trailing zeros after the decimal point (and the decimal
/// point itself if no fractional digits remain), e.g., `'1.2000k'` -> `'1.2k'`
/// and `'1.0000e+6'` -> `'1e+6'`.
@pragma('vm:prefer-inline')
String formatTrim(String s) {
  final n = s.length;
  var i0 = -1;
  var i1 = 0;
  for (var i = 1; i < n; ++i) {
    final c = s.codeUnitAt(i);
    if (c == 46) {
      // '.'
      i0 = i1 = i;
    } else if (c == 48) {
      // '0'
      if (i0 == 0) i0 = i;
      i1 = i;
    } else if (c >= 49 && c <= 57) {
      // '1'..'9'
      if (i0 > 0) i0 = 0;
    } else {
      break;
    }
  }
  if (i0 <= 0) return s;
  if (i1 + 1 == n) return s.substring(0, i0);
  return '${s.substring(0, i0)}${s.substring(i1 + 1)}';
}
