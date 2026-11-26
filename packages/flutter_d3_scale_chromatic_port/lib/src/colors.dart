// Ported from d3-scale-chromatic v3.1.0 src/colors.js (ISC, Mike Bostock).

/// Port of `src/colors.js` of d3-scale-chromatic 3.1.0: parses a concatenated
/// 6-digit hex string into a list of [Rgb] colors.
library;

import 'dart:collection';

import 'package:flutter_d3_color_port/d3_color.dart';

final Rgb _placeholder = Rgb(0, 0, 0);

/// colors.js:1 the default export: parses [specifier], a concatenation of
/// 6-character hexadecimal RGB strings (`rrggbb`), into an unmodifiable list
/// of [Rgb] colors.
///
/// Upstream returns a list of `'#rrggbb'` strings; here each entry is an
/// [Rgb] whose [Color.formatHex] is that string (D3 ADR 0012).
// DIVERGES(d3-scale-chromatic): adapt-chromatic-color-values, returns Rgb list.
// DIVERGES(d3-scale-chromatic): adapt-chromatic-fast-forms, code-unit decode.
List<Rgb> colors(String specifier) {
  final n = specifier.length ~/ 6;
  if (n == 0) return const <Rgb>[];
  final out = List<Rgb>.filled(n, _placeholder);
  for (var i = 0, o = 0; i < n; i++, o += 6) {
    final r =
        (_hexNibble(specifier.codeUnitAt(o)) << 4) |
        _hexNibble(specifier.codeUnitAt(o + 1));
    final g =
        (_hexNibble(specifier.codeUnitAt(o + 2)) << 4) |
        _hexNibble(specifier.codeUnitAt(o + 3));
    final b =
        (_hexNibble(specifier.codeUnitAt(o + 4)) << 4) |
        _hexNibble(specifier.codeUnitAt(o + 5));
    out[i] = Rgb(r.toDouble(), g.toDouble(), b.toDouble());
  }
  return UnmodifiableListView<Rgb>(out);
}

int _hexNibble(int c) {
  final d = c - 0x30;
  if (d >= 0 && d <= 9) return d;
  final l = (c | 0x20) - 0x61;
  if (l >= 0 && l <= 5) return l + 10;
  throw FormatException('Invalid hex digit: ${String.fromCharCode(c)}');
}
