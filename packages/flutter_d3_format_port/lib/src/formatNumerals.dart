// Ported from d3-format v3.1.2 src/formatNumerals.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/formatNumerals.js` of d3-format 3.1.2.
library;

import 'dart:typed_data';

// DIVERGES(d3-format): adapt-format-fast-forms, code-unit map without RegExp

const bool _isWasm = bool.fromEnvironment('dart.tool.dart2wasm');
const bool _isJs = bool.fromEnvironment('dart.library.js_interop') && !_isWasm;

final Uint16List _numeralScratch = Uint16List(256);

/// Returns a function that replaces ASCII digits `'0'`–`'9'` with the
/// corresponding entries of [numerals].
String Function(String value) formatNumerals(List<String> numerals) {
  final singleUnit =
      numerals.length >= 10 && numerals.take(10).every((s) => s.length == 1);

  if (!_isJs && singleUnit) {
    final codes = Uint16List(10);
    for (var i = 0; i < 10; ++i) {
      codes[i] = numerals[i].codeUnitAt(0);
    }
    return (String value) {
      final n = value.length;
      if (n == 0) return value;
      final buf = n <= _numeralScratch.length ? _numeralScratch : Uint16List(n);
      var changed = false;
      for (var i = 0; i < n; ++i) {
        final c = value.codeUnitAt(i);
        if (c >= 48 && c <= 57) {
          final mapped = codes[c - 48];
          buf[i] = mapped;
          if (mapped != c) changed = true;
        } else {
          buf[i] = c;
        }
      }
      return changed ? String.fromCharCodes(buf, 0, n) : value;
    };
  }

  return (String value) {
    final n = value.length;
    StringBuffer? out;
    var last = 0;
    for (var i = 0; i < n; ++i) {
      final c = value.codeUnitAt(i);
      if (c >= 48 && c <= 57) {
        out ??= StringBuffer();
        if (i > last) out.write(value.substring(last, i));
        out.write(numerals[c - 48]);
        last = i + 1;
      }
    }
    if (out == null) return value;
    if (last < n) out.write(value.substring(last));
    return out.toString();
  };
}
