// Ported from d3-format v3.1.2 src/formatSpecifier.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/formatSpecifier.js` of d3-format 3.1.2.
library;

import 'dart:math' as math;

// DIVERGES(d3-format): adapt-format-typed-api, typed fields and FormatException
// DIVERGES(d3-format): adapt-format-fast-forms, single-pass code-unit parser

@pragma('vm:prefer-inline')
bool _isAlign(int c) => c == 60 || c == 62 || c == 61 || c == 94; // < > = ^

@pragma('vm:prefer-inline')
bool _isLineTerminator(int c) =>
    c == 10 || c == 13 || c == 0x2028 || c == 0x2029;

/// Parses the specified [specifier], returning a [FormatSpecifier] exposing
/// its fields.
///
/// Throws a [FormatException] if [specifier] is not a valid format specifier.
FormatSpecifier formatSpecifier(String specifier) {
  final n = specifier.length;
  var i = 0;

  var fill = ' ';
  var align = '>';
  if (n >= 2 && _isAlign(specifier.codeUnitAt(1))) {
    final c0 = specifier.codeUnitAt(0);
    if (!_isLineTerminator(c0)) {
      fill = specifier[0];
      align = specifier[1];
      i = 2;
    }
  } else if (n >= 1 && _isAlign(specifier.codeUnitAt(0))) {
    align = specifier[0];
    i = 1;
  }

  var sign = '-';
  if (i < n) {
    final c = specifier.codeUnitAt(i);
    if (c == 43 || c == 45 || c == 40 || c == 32) {
      // + - ( ' '
      sign = specifier[i];
      i++;
    }
  }

  var symbol = '';
  if (i < n) {
    final c = specifier.codeUnitAt(i);
    if (c == 36 || c == 35) {
      // $ #
      symbol = specifier[i];
      i++;
    }
  }

  var zero = false;
  if (i < n && specifier.codeUnitAt(i) == 48) {
    // '0'
    zero = true;
    i++;
  }

  int? width;
  if (i < n) {
    var c = specifier.codeUnitAt(i);
    if (c >= 48 && c <= 57) {
      var w = c - 48;
      i++;
      while (i < n) {
        c = specifier.codeUnitAt(i);
        if (c < 48 || c > 57) break;
        w = w * 10 + (c - 48);
        i++;
      }
      width = w;
    }
  }

  var comma = false;
  if (i < n && specifier.codeUnitAt(i) == 44) {
    // ','
    comma = true;
    i++;
  }

  int? precision;
  if (i < n && specifier.codeUnitAt(i) == 46) {
    // '.'
    i++;
    if (i >= n) throw FormatException('invalid format: $specifier');
    var c = specifier.codeUnitAt(i);
    if (c < 48 || c > 57) {
      throw FormatException('invalid format: $specifier');
    }
    var p = c - 48;
    i++;
    while (i < n) {
      c = specifier.codeUnitAt(i);
      if (c < 48 || c > 57) break;
      p = p * 10 + (c - 48);
      i++;
    }
    precision = p;
  }

  var trim = false;
  if (i < n && specifier.codeUnitAt(i) == 126) {
    // '~'
    trim = true;
    i++;
  }

  var type = '';
  if (i < n) {
    final c = specifier.codeUnitAt(i);
    if ((c >= 97 && c <= 122) || (c >= 65 && c <= 90) || c == 37) {
      // [a-zA-Z%]
      type = specifier[i];
      i++;
    }
  }

  if (i != n) {
    throw FormatException('invalid format: $specifier');
  }

  return FormatSpecifier(
    fill: fill,
    align: align,
    sign: sign,
    symbol: symbol,
    zero: zero,
    width: width,
    comma: comma,
    precision: precision,
    trim: trim,
    type: type,
  );
}

/// Parsed fields of a `d3-format` specifier string.
final class FormatSpecifier({
  /// Fill character for padding (default `' '`).
  var String fill = ' ',

  /// Alignment (`'<'`, `'>'`, `'='`, or `'^'`; default `'>'`).
  var String align = '>',

  /// Sign option (`'-'`, `'+'`, `'('`, or `' '`; default `'-'`).
  var String sign = '-',

  /// Symbol prefix (`'$'`, `'#'`, or `''`; default `''`).
  var String symbol = '',

  /// Whether zero-padding is enabled (default `false`).
  var bool zero = false,

  /// Minimum field width, or `null` if unspecified.
  var int? width,

  /// Whether thousands grouping is enabled (default `false`).
  var bool comma = false,

  /// Precision, or `null` if unspecified.
  var int? precision,

  /// Whether insignificant trailing zeros are trimmed (default `false`).
  var bool trim = false,

  /// Format type (`'e'`, `'f'`, `'g'`, `'r'`, `'s'`, `'%'`, `'p'`, `'b'`,
  /// `'o'`, `'d'`, `'x'`, `'X'`, `'c'`, `'n'`, or `''`).
  var String type = '',
}) {
  /// Creates a [FormatSpecifier] with the given field values.
  this;

  /// Creates a normalized copy of [other], clamping [width] to `>= 1` and
  /// [precision] to `>= 0`.
  new normalized(FormatSpecifier other)
    : this(
        fill: other.fill,
        align: other.align,
        sign: other.sign,
        symbol: other.symbol,
        zero: other.zero,
        width: other.width == null ? null : math.max(1, other.width!),
        comma: other.comma,
        precision: other.precision == null
            ? null
            : math.max(0, other.precision!),
        trim: other.trim,
        type: other.type,
      );

  @override
  String toString() {
    final w = width;
    final p = precision;
    return '$fill$align$sign$symbol'
        '${zero ? '0' : ''}'
        '${w == null ? '' : math.max(1, w)}'
        '${comma ? ',' : ''}'
        '${p == null ? '' : '.${math.max(0, p)}'}'
        '${trim ? '~' : ''}'
        '$type';
  }
}
