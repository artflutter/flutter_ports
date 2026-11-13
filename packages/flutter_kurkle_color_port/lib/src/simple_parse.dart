// Original code, not ported from @kurkle/color: guarded comma-color parsing.

import 'package:flutter_kurkle_color_port/src/index.esm.dart' show RGBA;

/// Parses only unsigned integral channels in canonical comma notation.
/// Other forms return null so the upstream regular expressions decide them.
///
/// The caller validates the function prefix and gives [start] just after `(`.
/// Each channel has one to three digits; [percentages] requires `%` after the
/// second and third channels. Alpha is an optional unsigned decimal, default 1.
/// The caller applies the RGB or hue module's channel and alpha conversions
/// to this fresh RGBA, which does not escape before those conversions finish.
RGBA? simpleColor(String text, int start, {required bool percentages}) {
  final end = text.length - 1;
  if (end < start || text.codeUnitAt(end) != 41) return null;
  var i = start;
  var first = 0;
  var second = 0;
  var third = 0;
  for (var channel = 0; channel < 3; channel++) {
    while (i < end && text.codeUnitAt(i) == 32) {
      i++;
    }
    var value = 0;
    var count = 0;
    while (i < end) {
      final c = text.codeUnitAt(i);
      if (c < 48 || c > 57) break;
      if (++count > 3) return null;
      value = value * 10 + c - 48;
      i++;
    }
    if (count == 0) return null;
    if (percentages && channel > 0) {
      if (i >= end || text.codeUnitAt(i) != 37) return null;
      i++;
    }
    if (channel == 0) {
      first = value;
    } else if (channel == 1) {
      second = value;
    } else {
      third = value;
    }
    while (i < end && text.codeUnitAt(i) == 32) {
      i++;
    }
    if (channel < 2) {
      if (i >= end || text.codeUnitAt(i) != 44) return null;
      i++;
    }
  }
  double? alpha;
  if (i < end) {
    if (text.codeUnitAt(i) != 44) return null;
    i++;
    while (i < end && text.codeUnitAt(i) == 32) {
      i++;
    }
    final from = i;
    while (i < end) {
      final c = text.codeUnitAt(i);
      if ((c < 48 || c > 57) && c != 46) break;
      i++;
    }
    if (i == from) return null;
    final count = i - from;
    final head = text.codeUnitAt(from);
    if (count == 1 && head >= 48 && head <= 57) {
      alpha = (head - 48).toDouble();
    } else {
      final fraction = head == 46
          ? from + 1
          : head == 48 && count > 1 && text.codeUnitAt(from + 1) == 46
          ? from + 2
          : -1;
      final digits = i - fraction;
      if (fraction >= 0 && (digits == 1 || digits == 2)) {
        final d1 = text.codeUnitAt(fraction) - 48;
        final d2 = digits == 2 ? text.codeUnitAt(fraction + 1) - 48 : 0;
        if (d1 >= 0 && d1 <= 9 && d2 >= 0 && d2 <= 9) {
          // One correctly rounded division of exact integers gives the same
          // double as parsing these one- or two-place decimal fractions.
          alpha = digits == 1 ? d1 / 10 : (d1 * 10 + d2) / 100;
        }
      }
      alpha ??= double.tryParse(text.substring(from, i));
    }
    if (alpha == null) return null;
    while (i < end && text.codeUnitAt(i) == 32) {
      i++;
    }
    if (i != end) return null;
  }
  return RGBA(
    r: first.toDouble(),
    g: second.toDouble(),
    b: third.toDouble(),
    a: alpha ?? 1,
  );
}
