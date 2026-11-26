// Ported from d3-format v3.1.2 src/formatGroup.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/formatGroup.js` of d3-format 3.1.2.
library;

import 'dart:math' as math;
import 'dart:typed_data';

// DIVERGES(d3-format): adapt-format-fast-forms, direct buffer & JS grouping

const bool _isWasm = bool.fromEnvironment('dart.tool.dart2wasm');
const bool _isJs = bool.fromEnvironment('dart.library.js_interop') && !_isWasm;

final Uint16List _groupScratch = Uint16List(256);

/// Returns a grouping function that inserts [thousands] between digit groups
/// according to [grouping], truncating leading groups when `width` is finite.
String Function(String value, int? width) formatGroup(
  List<int> grouping,
  String thousands,
) {
  if (grouping.isEmpty) return (_, _) => '';
  final singleGroup3 = grouping.length == 1 && grouping[0] == 3;
  final singleCharSep = thousands.length == 1;
  final sepCode = singleCharSep ? thousands.codeUnitAt(0) : 0;

  // On dart2js, native JS string slicing + rope concatenation outperforms
  // Uint16List + String.fromCharCodes.
  if (_isJs && singleGroup3) {
    return (String value, int? width) {
      final n = value.length;
      if (n <= 3 && (width == null || width >= n)) return value;
      if (n == 0) return '';
      if (width == null) {
        var i = n - 3;
        var out = value.substring(i, n);
        while (i > 3) {
          out = '${value.substring(i - 3, i)}$thousands$out';
          i -= 3;
        }
        return '${value.substring(0, i)}$thousands$out';
      }
      var i = n;
      var g = 3;
      var length = 0;
      var out = '';
      var first = true;
      while (i > 0 && g > 0) {
        if (length + g + 1 > width) g = math.max(1, width - length);
        final end = i;
        i -= g;
        final seg = value.substring(i < 0 ? 0 : i, end);
        out = first ? seg : '$seg$thousands$out';
        first = false;
        length += g + 1;
        if (length > width) break;
        g = 3;
      }
      return out;
    };
  }

  if (!_isJs && singleGroup3 && singleCharSep) {
    return (String value, int? width) {
      final n = value.length;
      if (n <= 3 && (width == null || width >= n)) return value;
      if (n == 0) return '';

      if (width == null) {
        final seps = (n - 1) ~/ 3;
        final outLen = n + seps;
        final buf = outLen <= _groupScratch.length
            ? _groupScratch
            : Uint16List(outLen);
        var pos = outLen;
        var count = 0;
        for (var i = n - 1; i >= 0; --i) {
          if (count == 3) {
            buf[--pos] = sepCode;
            count = 0;
          }
          buf[--pos] = value.codeUnitAt(i);
          count++;
        }
        return String.fromCharCodes(buf, 0, outLen);
      }

      final maxOut = n + (n ~/ 3) + 2;
      final buf = maxOut <= _groupScratch.length
          ? _groupScratch
          : Uint16List(maxOut);
      var pos = buf.length;
      var i = n;
      var length = 0;
      var g = 3;
      var first = true;
      while (i > 0 && g > 0) {
        if (length + g + 1 > width) {
          g = math.max(1, width - length);
        }
        if (!first) buf[--pos] = sepCode;
        first = false;
        final start = i - g < 0 ? 0 : i - g;
        for (var k = i - 1; k >= start; --k) {
          buf[--pos] = value.codeUnitAt(k);
        }
        i -= g;
        length += g + 1;
        if (length > width) break;
        g = 3;
      }
      return String.fromCharCodes(buf, pos, buf.length);
    };
  }

  if (!_isJs && singleCharSep) {
    final gLen = grouping.length;
    return (String value, int? width) {
      final n = value.length;
      if (n == 0) return '';
      final maxOut = n * 2 + 2;
      final buf = maxOut <= _groupScratch.length
          ? _groupScratch
          : Uint16List(maxOut);
      var pos = buf.length;
      var i = n;
      var j = 0;
      var g = grouping[0];
      var length = 0;
      var first = true;
      while (i > 0 && g > 0) {
        if (width != null && length + g + 1 > width) {
          g = math.max(1, width - length);
        }
        if (!first) buf[--pos] = sepCode;
        first = false;
        final start = i - g < 0 ? 0 : i - g;
        for (var k = i - 1; k >= start; --k) {
          buf[--pos] = value.codeUnitAt(k);
        }
        i -= g;
        length += g + 1;
        if (width != null && length > width) break;
        j++;
        if (j == gLen) j = 0;
        g = grouping[j];
      }
      return String.fromCharCodes(buf, pos, buf.length);
    };
  }

  final gLen = grouping.length;
  return (String value, int? width) {
    var i = value.length;
    var j = 0;
    var g = grouping[0];
    var length = 0;
    var out = '';
    var first = true;

    while (i > 0 && g > 0) {
      if (width != null && length + g + 1 > width) {
        g = math.max(1, width - length);
      }
      final end = i;
      i -= g;
      final seg = value.substring(i < 0 ? 0 : i, end);
      out = first ? seg : '$seg$thousands$out';
      first = false;
      length += g + 1;
      if (width != null && length > width) break;
      j++;
      if (j == gLen) j = 0;
      g = grouping[j];
    }

    return out;
  };
}
