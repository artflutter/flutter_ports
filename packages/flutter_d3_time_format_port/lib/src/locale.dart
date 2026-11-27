// Ported from d3-time-format v4.1.0 src/locale.js (ISC, Mike Bostock).

/// Port of `src/locale.js` of d3-time-format 4.1.0.
library;

import 'dart:typed_data';

import 'package:flutter_d3_time_port/d3_time.dart';

// DIVERGES(d3-time-format): adapt-time-format-typed-api, typed
// TimeLocaleDefinition, TimeLocale, TimeFormat, and TimeParse over native Dart
// DateTime.
// DIVERGES(d3-time-format): adapt-time-format-fast-forms, precompiled flat
// directive instruction lists, direct UTF-16/Latin-1 code-unit formatting and
// parsing with zero per-directive RegExp allocations, O(1) Hinnant civil
// calendar math, and pre-indexed case-insensitive locale lookup tables.

const int _msPerDay = 86400000;

const bool _isWasm = bool.fromEnvironment('dart.tool.dart2wasm');
const bool _isJs = bool.fromEnvironment('dart.library.js_interop') && !_isWasm;

const List<String> _d2Zero = [
  '00',
  '01',
  '02',
  '03',
  '04',
  '05',
  '06',
  '07',
  '08',
  '09',
  '10',
  '11',
  '12',
  '13',
  '14',
  '15',
  '16',
  '17',
  '18',
  '19',
  '20',
  '21',
  '22',
  '23',
  '24',
  '25',
  '26',
  '27',
  '28',
  '29',
  '30',
  '31',
  '32',
  '33',
  '34',
  '35',
  '36',
  '37',
  '38',
  '39',
  '40',
  '41',
  '42',
  '43',
  '44',
  '45',
  '46',
  '47',
  '48',
  '49',
  '50',
  '51',
  '52',
  '53',
  '54',
  '55',
  '56',
  '57',
  '58',
  '59',
  '60',
  '61',
  '62',
  '63',
  '64',
  '65',
  '66',
  '67',
  '68',
  '69',
  '70',
  '71',
  '72',
  '73',
  '74',
  '75',
  '76',
  '77',
  '78',
  '79',
  '80',
  '81',
  '82',
  '83',
  '84',
  '85',
  '86',
  '87',
  '88',
  '89',
  '90',
  '91',
  '92',
  '93',
  '94',
  '95',
  '96',
  '97',
  '98',
  '99',
];

const List<String> _d2Space = [
  ' 0',
  ' 1',
  ' 2',
  ' 3',
  ' 4',
  ' 5',
  ' 6',
  ' 7',
  ' 8',
  ' 9',
];

const List<String> _d1 = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

String _jsPad2(int value, int padCode) {
  if (value >= 0 && value < 100) {
    if (value >= 10) return _d2Zero[value];
    if (padCode == _padZero) return _d2Zero[value];
    if (padCode == _padSpace) return _d2Space[value];
    return _d1[value];
  }
  final sign = value < 0 ? '-' : '';
  final v = value < 0 ? -value : value;
  if (v < 10) {
    if (padCode == _padZero) return '$sign${_d2Zero[v]}';
    if (padCode == _padSpace) return '$sign${_d2Space[v]}';
    return '$sign${_d1[v]}';
  }
  return '$sign$v';
}

String _jsPad3(int value, int padCode) {
  if (value >= 0 && value < 1000) {
    final h = value ~/ 100;
    final rem = value - h * 100;
    if (h > 0) return '${_d1[h]}${_d2Zero[rem]}';
    if (padCode == _padZero) return '0${_d2Zero[rem]}';
    if (padCode == _padSpace) {
      return rem >= 10 ? ' ${_d2Zero[rem]}' : '  ${_d1[rem]}';
    }
    return rem >= 10 ? _d2Zero[rem] : _d1[rem];
  }
  final sign = value < 0 ? '-' : '';
  final s = (value < 0 ? -value : value).toString();
  if (s.length < 3 && padCode != _padNone) {
    final fill = padCode == _padZero ? '0' : ' ';
    return '$sign${fill * (3 - s.length)}$s';
  }
  return '$sign$s';
}

String _jsPad4(int value, int padCode) {
  if (value >= 1000 && value < 10000) {
    final hi = value ~/ 100;
    return '${_d2Zero[hi]}${_d2Zero[value - hi * 100]}';
  }
  final sign = value < 0 ? '-' : '';
  final v = value < 0 ? -value : value;
  final s = v.toString();
  if (s.length < 4 && padCode != _padNone) {
    final fill = padCode == _padZero ? '0' : ' ';
    return '$sign${fill * (4 - s.length)}$s';
  }
  return '$sign$s';
}

String _jsZone(int offsetMinutes) {
  var z = offsetMinutes;
  final sign = z < 0 ? '-' : '+';
  if (z < 0) z = -z;
  return '$sign${_d2Zero[z ~/ 60]}${_d2Zero[z % 60]}';
}

// Pad codes stored per compiled format op.
const int _padNone = 0; // '-' -> ''
const int _padZero = 48; // '0' -> '0'
const int _padSpace = 32; // '_' -> ' '

// Compiled format opcodes.
const int _fLit = 0;
const int _fShortWeekday = 1; // %a
const int _fWeekday = 2; // %A
const int _fShortMonth = 3; // %b
const int _fMonth = 4; // %B
const int _fDay = 5; // %d, %e
const int _fMicroseconds = 6; // %f
const int _fYearISO = 7; // %g
const int _fFullYearISO = 8; // %G
const int _fHour24 = 9; // %H
const int _fHour12 = 10; // %I
const int _fDayOfYear = 11; // %j
const int _fMilliseconds = 12; // %L
const int _fMonthNum = 13; // %m
const int _fMinutes = 14; // %M
const int _fPeriod = 15; // %p
const int _fQuarter = 16; // %q
const int _fUnixMs = 17; // %Q
const int _fUnixSec = 18; // %s
const int _fSeconds = 19; // %S
const int _fWeekdayMon = 20; // %u
const int _fWeekSun = 21; // %U
const int _fWeekISO = 22; // %V
const int _fWeekdaySun = 23; // %w
const int _fWeekMon = 24; // %W
const int _fYear = 25; // %y
const int _fFullYear = 26; // %Y
const int _fZone = 27; // %Z

// Bitmask flags for which calendar groups a compiled format needs.
const int _needDate = 1;
const int _needTime = 2;
const int _needWeek = 4;
const int _needIsoWeek = 8;
const int _needZone = 16;

// Compiled parse opcodes.
const int _pLitChar = 0;
const int _pLitStr = 1;
const int _pShortWeekday = 2; // %a
const int _pWeekday = 3; // %A
const int _pShortMonth = 4; // %b
const int _pMonth = 5; // %B
const int _pDay = 6; // %d, %e
const int _pMicroseconds = 7; // %f
const int _pYear = 8; // %y, %g
const int _pFullYear = 9; // %Y, %G
const int _pHour = 10; // %H, %I
const int _pDayOfYear = 11; // %j
const int _pMilliseconds = 12; // %L
const int _pMonthNum = 13; // %m
const int _pMinutes = 14; // %M
const int _pPeriod = 15; // %p
const int _pQuarter = 16; // %q
const int _pUnixMs = 17; // %Q
const int _pUnixSec = 18; // %s
const int _pSeconds = 19; // %S
const int _pWeekdayMon = 20; // %u
const int _pWeekSun = 21; // %U
const int _pWeekISO = 22; // %V
const int _pWeekdaySun = 23; // %w
const int _pWeekMon = 24; // %W
const int _pZone = 25; // %Z

const List<int> _monthDayOffsets = [
  0,
  31,
  59,
  90,
  120,
  151,
  181,
  212,
  243,
  273,
  304,
  334,
];

/// Reusable single-isolate Latin-1 output scratch buffer.
Uint8List _buf8 = Uint8List(256);

/// Reusable single-isolate UTF-16 output scratch buffer.
Uint16List _buf16 = Uint16List(256);

@pragma('vm:prefer-inline')
bool _isLeapYear(int y) => (y % 4 == 0) && (y % 100 != 0 || y % 400 == 0);

@pragma('vm:prefer-inline')
int _daysFromCivil(int y, int m, int d) {
  final yAdj = m <= 2 ? y - 1 : y;
  final era = (yAdj >= 0 ? yAdj : yAdj - 399) ~/ 400;
  final yoe = yAdj - era * 400;
  final doy = (153 * (m > 2 ? m - 3 : m + 9) + 2) ~/ 5 + d - 1;
  final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
  return era * 146097 + doe - 719468;
}

@pragma('vm:prefer-inline')
bool _isAsciiOnly(String s) {
  for (var i = 0; i < s.length; ++i) {
    if (s.codeUnitAt(i) > 255) return false;
  }
  return true;
}

bool _allLatin1(List<String> list) {
  for (var i = 0; i < list.length; ++i) {
    if (!_isAsciiOnly(list[i])) return false;
  }
  return true;
}

@pragma('vm:prefer-inline')
void _ensureBuf8(int needed) {
  if (needed > _buf8.length) {
    var next = _buf8.length * 2;
    while (next < needed) {
      next *= 2;
    }
    final grown = Uint8List(next)..setRange(0, _buf8.length, _buf8);
    _buf8 = grown;
  }
}

@pragma('vm:prefer-inline')
void _ensureBuf16(int needed) {
  if (needed > _buf16.length) {
    var next = _buf16.length * 2;
    while (next < needed) {
      next *= 2;
    }
    final grown = Uint16List(next)..setRange(0, _buf16.length, _buf16);
    _buf16 = grown;
  }
}

@pragma('vm:prefer-inline')
int _writeStr8(int pos, String s) {
  final n = s.length;
  _ensureBuf8(pos + n);
  final b = _buf8;
  for (var i = 0; i < n; ++i) {
    b[pos++] = s.codeUnitAt(i);
  }
  return pos;
}

@pragma('vm:prefer-inline')
int _writeStr16(int pos, String s) {
  final n = s.length;
  _ensureBuf16(pos + n);
  final b = _buf16;
  for (var i = 0; i < n; ++i) {
    b[pos++] = s.codeUnitAt(i);
  }
  return pos;
}

@pragma('vm:prefer-inline')
int _writePad2_8(int pos, int value, int padCode) {
  _ensureBuf8(pos + 4);
  final b = _buf8;
  var v = value;
  if (v < 0) {
    b[pos++] = 45; // '-'
    v = -v;
  }
  if (v < 10) {
    if (padCode != _padNone) b[pos++] = padCode;
    b[pos++] = 48 + v;
    return pos;
  }
  if (v < 100) {
    b[pos++] = 48 + v ~/ 10;
    b[pos++] = 48 + v % 10;
    return pos;
  }
  return _writeUnsignedInt8(pos, v, padCode, 2);
}

@pragma('vm:prefer-inline')
int _writePad3_8(int pos, int value, int padCode) {
  _ensureBuf8(pos + 5);
  final b = _buf8;
  var v = value;
  if (v < 0) {
    b[pos++] = 45;
    v = -v;
  }
  if (v < 10) {
    if (padCode != _padNone) {
      b[pos++] = padCode;
      b[pos++] = padCode;
    }
    b[pos++] = 48 + v;
    return pos;
  }
  if (v < 100) {
    if (padCode != _padNone) b[pos++] = padCode;
    b[pos++] = 48 + v ~/ 10;
    b[pos++] = 48 + v % 10;
    return pos;
  }
  if (v < 1000) {
    b[pos++] = 48 + v ~/ 100;
    final rem = v % 100;
    b[pos++] = 48 + rem ~/ 10;
    b[pos++] = 48 + rem % 10;
    return pos;
  }
  return _writeUnsignedInt8(pos, v, padCode, 3);
}

@pragma('vm:prefer-inline')
int _writePad4_8(int pos, int value, int padCode) {
  _ensureBuf8(pos + 6);
  final b = _buf8;
  var v = value;
  if (v < 0) {
    b[pos++] = 45;
    v = -v;
  }
  if (v >= 1000 && v < 10000) {
    final hi = v ~/ 100;
    final lo = v - hi * 100;
    b[pos++] = 48 + hi ~/ 10;
    b[pos++] = 48 + hi % 10;
    b[pos++] = 48 + lo ~/ 10;
    b[pos++] = 48 + lo % 10;
    return pos;
  }
  return _writeUnsignedInt8(pos, v, padCode, 4);
}

int _writeUnsignedInt8(int pos, int v, int padCode, int width) {
  final s = v.toString();
  final len = s.length;
  final padCount = (padCode != _padNone && len < width) ? width - len : 0;
  _ensureBuf8(pos + padCount + len);
  final b = _buf8;
  for (var i = 0; i < padCount; ++i) {
    b[pos++] = padCode;
  }
  for (var i = 0; i < len; ++i) {
    b[pos++] = s.codeUnitAt(i);
  }
  return pos;
}

@pragma('vm:prefer-inline')
int _writePad2_16(int pos, int value, int padCode) {
  _ensureBuf16(pos + 4);
  final b = _buf16;
  var v = value;
  if (v < 0) {
    b[pos++] = 45;
    v = -v;
  }
  if (v < 10) {
    if (padCode != _padNone) b[pos++] = padCode;
    b[pos++] = 48 + v;
    return pos;
  }
  if (v < 100) {
    b[pos++] = 48 + v ~/ 10;
    b[pos++] = 48 + v % 10;
    return pos;
  }
  return _writeUnsignedInt16(pos, v, padCode, 2);
}

@pragma('vm:prefer-inline')
int _writePad3_16(int pos, int value, int padCode) {
  _ensureBuf16(pos + 5);
  final b = _buf16;
  var v = value;
  if (v < 0) {
    b[pos++] = 45;
    v = -v;
  }
  if (v < 10) {
    if (padCode != _padNone) {
      b[pos++] = padCode;
      b[pos++] = padCode;
    }
    b[pos++] = 48 + v;
    return pos;
  }
  if (v < 100) {
    if (padCode != _padNone) b[pos++] = padCode;
    b[pos++] = 48 + v ~/ 10;
    b[pos++] = 48 + v % 10;
    return pos;
  }
  if (v < 1000) {
    b[pos++] = 48 + v ~/ 100;
    final rem = v % 100;
    b[pos++] = 48 + rem ~/ 10;
    b[pos++] = 48 + rem % 10;
    return pos;
  }
  return _writeUnsignedInt16(pos, v, padCode, 3);
}

@pragma('vm:prefer-inline')
int _writePad4_16(int pos, int value, int padCode) {
  _ensureBuf16(pos + 6);
  final b = _buf16;
  var v = value;
  if (v < 0) {
    b[pos++] = 45;
    v = -v;
  }
  if (v >= 1000 && v < 10000) {
    final hi = v ~/ 100;
    final lo = v - hi * 100;
    b[pos++] = 48 + hi ~/ 10;
    b[pos++] = 48 + hi % 10;
    b[pos++] = 48 + lo ~/ 10;
    b[pos++] = 48 + lo % 10;
    return pos;
  }
  return _writeUnsignedInt16(pos, v, padCode, 4);
}

int _writeUnsignedInt16(int pos, int v, int padCode, int width) {
  final s = v.toString();
  final len = s.length;
  final padCount = (padCode != _padNone && len < width) ? width - len : 0;
  _ensureBuf16(pos + padCount + len);
  final b = _buf16;
  for (var i = 0; i < padCount; ++i) {
    b[pos++] = padCode;
  }
  for (var i = 0; i < len; ++i) {
    b[pos++] = s.codeUnitAt(i);
  }
  return pos;
}

@pragma('vm:prefer-inline')
int _writeZone8(int pos, int offsetMinutes) {
  _ensureBuf8(pos + 5);
  final b = _buf8;
  var z = offsetMinutes;
  if (z < 0) {
    b[pos++] = 45; // '-'
    z = -z;
  } else {
    b[pos++] = 43; // '+'
  }
  final hh = z ~/ 60;
  final mm = z % 60;
  b[pos++] = 48 + hh ~/ 10;
  b[pos++] = 48 + hh % 10;
  b[pos++] = 48 + mm ~/ 10;
  b[pos++] = 48 + mm % 10;
  return pos;
}

@pragma('vm:prefer-inline')
int _writeZone16(int pos, int offsetMinutes) {
  _ensureBuf16(pos + 5);
  final b = _buf16;
  var z = offsetMinutes;
  if (z < 0) {
    b[pos++] = 45;
    z = -z;
  } else {
    b[pos++] = 43;
  }
  final hh = z ~/ 60;
  final mm = z % 60;
  b[pos++] = 48 + hh ~/ 10;
  b[pos++] = 48 + hh % 10;
  b[pos++] = 48 + mm ~/ 10;
  b[pos++] = 48 + mm % 10;
  return pos;
}

/// Checks whether UTF-16 code unit [c] matches JavaScript RegExp `\s`.
@pragma('vm:prefer-inline')
bool _isJsWhitespace(int c) {
  if (c == 32) return true;
  if (c >= 9 && c <= 13) return true;
  if (c < 0xA0) return false;
  return c == 0xA0 ||
      c == 0x1680 ||
      (c >= 0x2000 && c <= 0x200A) ||
      c == 0x2028 ||
      c == 0x2029 ||
      c == 0x202F ||
      c == 0x205F ||
      c == 0x3000 ||
      c == 0xFEFF;
}

/// Pre-indexed case-insensitive locale name matcher preserving exact upstream
/// left-to-right alternation precedence and last-index duplicate resolution.
final class _NameMatcher(List<String> names) {
  this {
    final lookup = <String, int>{};
    for (var i = 0; i < names.length; ++i) {
      lookup[names[i].toLowerCase()] = i;
    }

    final n = names.length;
    final lowers = List<String>.filled(n, '');
    final lowerUnits = List<Uint16List>.filled(n, Uint16List(0));
    final origUnits = List<Uint16List>.filled(n, Uint16List(0));
    final isAsciiName = Uint8List(n);
    final resolved = Int32List(n);
    var firstEmpty = -1;
    var emptyResolved = -1;

    final asciiLists = List<List<int>?>.filled(128, null);
    final unicodeLists = <int, List<int>>{};

    for (var i = 0; i < n; ++i) {
      final orig = names[i];
      final lower = orig.toLowerCase();
      lowers[i] = lower;
      resolved[i] = lookup[lower]!;
      if (lower.isEmpty) {
        if (firstEmpty < 0) {
          firstEmpty = i;
          emptyResolved = resolved[i];
        }
        continue;
      }
      if (firstEmpty >= 0) {
        // An earlier empty alternation always matches before later entries.
        continue;
      }
      final lu = Uint16List(lower.length);
      final ou = Uint16List(orig.length);
      var ascii = lower.length == orig.length;
      for (var j = 0; j < lower.length; ++j) {
        final cu = lower.codeUnitAt(j);
        lu[j] = cu;
        if (cu >= 128) ascii = false;
      }
      for (var j = 0; j < orig.length; ++j) {
        final cu = orig.codeUnitAt(j);
        ou[j] = cu;
        if (cu >= 128) ascii = false;
      }
      lowerUnits[i] = lu;
      origUnits[i] = ou;
      isAsciiName[i] = ascii ? 1 : 0;

      final firstLower = lower.codeUnitAt(0);
      if (firstLower < 128) {
        (asciiLists[firstLower] ??= <int>[]).add(i);
      } else {
        (unicodeLists[firstLower] ??= <int>[]).add(i);
        final firstOrig = orig.codeUnitAt(0);
        if (firstOrig != firstLower) {
          (unicodeLists[firstOrig] ??= <int>[]).add(i);
        }
        final firstUpper = orig[0].toUpperCase().codeUnitAt(0);
        if (firstUpper != firstLower && firstUpper != firstOrig) {
          (unicodeLists[firstUpper] ??= <int>[]).add(i);
        }
      }
    }

    _lowers = lowers;
    _lowerUnits = lowerUnits;
    _origUnits = origUnits;
    _isAscii = isAsciiName;
    _resolved = resolved;
    _firstEmpty = firstEmpty;
    _emptyResolved = emptyResolved;
    _asciiBuckets = List<Int32List?>.generate(
      128,
      (c) => asciiLists[c] == null ? null : Int32List.fromList(asciiLists[c]!),
      growable: false,
    );
    _unicodeBuckets = {
      for (final e in unicodeLists.entries) e.key: Int32List.fromList(e.value),
    };
  }

  late final List<String> _lowers;
  late final List<Uint16List> _lowerUnits;
  late final List<Uint16List> _origUnits;
  late final Uint8List _isAscii;
  late final Int32List _resolved;
  late final int _firstEmpty;
  late final int _emptyResolved;
  late final List<Int32List?> _asciiBuckets;
  late final Map<int, Int32List> _unicodeBuckets;

  /// Last matched resolved index (valid when [match] returns `>= 0`).
  int matchedIndex = 0;

  /// Matches a locale name at [pos] in [s] and returns the new position,
  /// setting [matchedIndex], or returns `-1` on mismatch.
  @pragma('vm:prefer-inline')
  int match(String s, int pos) {
    final len = s.length;
    if (pos >= len) {
      if (_firstEmpty >= 0) {
        matchedIndex = _emptyResolved;
        return pos;
      }
      return -1;
    }

    final c0 = s.codeUnitAt(pos);
    Int32List? bucket;
    if (c0 < 128) {
      final folded = (c0 >= 65 && c0 <= 90) ? c0 + 32 : c0;
      bucket = _asciiBuckets[folded];
    } else {
      bucket = _unicodeBuckets[c0];
      if (bucket == null && _unicodeBuckets.isNotEmpty) {
        final folded = s[pos].toLowerCase().codeUnitAt(0);
        bucket = _unicodeBuckets[folded];
      }
    }

    if (bucket != null) {
      for (var bi = 0; bi < bucket.length; ++bi) {
        final idx = bucket[bi];
        final lower = _lowers[idx];
        final mLen = lower.length;
        if (pos + mLen > len) continue;
        if (_isAscii[idx] == 1) {
          final lu = _lowerUnits[idx];
          var ok = true;
          for (var j = 1; j < mLen; ++j) {
            var ch = s.codeUnitAt(pos + j);
            if (ch >= 65 && ch <= 90) ch += 32;
            if (ch != lu[j]) {
              ok = false;
              break;
            }
          }
          if (ok) {
            matchedIndex = _resolved[idx];
            return pos + mLen;
          }
        } else {
          // Fast exact code-unit check against original or lowercase spelling
          // before allocating a substring for Unicode case folding.
          final ou = _origUnits[idx];
          final lu = _lowerUnits[idx];
          var exact = ou.length == mLen;
          if (exact) {
            for (var j = 0; j < mLen; ++j) {
              final ch = s.codeUnitAt(pos + j);
              if (ch != ou[j] && ch != lu[j]) {
                exact = false;
                break;
              }
            }
          }
          if (exact || s.substring(pos, pos + mLen).toLowerCase() == lower) {
            matchedIndex = _resolved[idx];
            return pos + mLen;
          }
        }
      }
    }

    if (_firstEmpty >= 0) {
      matchedIndex = _emptyResolved;
      return pos;
    }
    return -1;
  }
}

/// Immutable definition of a `d3-time-format` locale (D3 ADR 0025).
class const TimeLocaleDefinition({
  /// The date and time (`%c`) format specifier.
  required final String dateTime,

  /// The date (`%x`) format specifier.
  required final String date,

  /// The time (`%X`) format specifier.
  required final String time,

  /// The A.M. and P.M. equivalents (length 2).
  required final List<String> periods,

  /// The full names of the weekdays, starting with Sunday (length 7).
  required final List<String> days,

  /// The abbreviated names of the weekdays, starting with Sunday (length 7).
  required final List<String> shortDays,

  /// The full names of the months, starting with January (length 12).
  required final List<String> months,

  /// The abbreviated names of the months, starting with January (length 12).
  required final List<String> shortMonths,
}) {
  /// Creates a [TimeLocaleDefinition].
  this;

  /// Creates a [TimeLocaleDefinition] from an upstream `locale/*.json` map.
  factory fromJson(Map<String, Object?> json) {
    List<String> stringList(String key) => [
      for (final item in json[key]! as List<Object?>) item! as String,
    ];
    return TimeLocaleDefinition(
      dateTime: json['dateTime']! as String,
      date: json['date']! as String,
      time: json['time']! as String,
      periods: stringList('periods'),
      days: stringList('days'),
      shortDays: stringList('shortDays'),
      months: stringList('months'),
      shortMonths: stringList('shortMonths'),
    );
  }
}

/// A compiled date/time formatter returned by [TimeLocale.format] or
/// [TimeLocale.utcFormat].
///
/// Implements [call] taking [DateTime] (tearing off to
/// `String Function(DateTime)`) and [toString] returning [specifier].
final class TimeFormat._(
  /// The format specifier used to construct this formatter.
  final String specifier,
  final TimeLocale _locale,
  final bool _isUtc,
  final Uint8List _ops,
  final Uint8List _pads,
  final List<String> _literals,
  final int _fieldMask,
  final bool _latin1Only,
) {
  /// Formats [date] according to [specifier].
  String call(DateTime date) {
    final ops = _ops;
    final opCount = ops.length;
    if (opCount == 0) return '';
    if (opCount == 1 && ops[0] == _fLit) return _literals[0];

    final mask = _fieldMask;
    final ms = date.millisecondsSinceEpoch;

    var localMs = ms;
    var offsetMinutes = 0;
    if (!_isUtc && (mask != 0)) {
      final localDate = date.isUtc ? date.toLocal() : date;
      final offset = localDate.timeZoneOffset;
      offsetMinutes = offset.inMinutes;
      localMs = ms + offset.inMilliseconds;
    }

    var year = 0;
    var month = 0;
    var day = 0;
    var weekday0 = 0;
    var hour = 0;
    var minute = 0;
    var second = 0;
    var msPart = 0;
    var doy = 0;
    var isoYear = 0;
    var isoWeek = 0;

    if ((mask & (_needDate | _needTime | _needWeek | _needIsoWeek)) != 0) {
      final int dayCount;
      if (localMs >= 0) {
        dayCount = localMs ~/ _msPerDay;
      } else {
        dayCount = -((-localMs + _msPerDay - 1) ~/ _msPerDay);
      }

      if ((mask & _needTime) != 0) {
        final msOfDay = localMs - dayCount * _msPerDay;
        final secOfDay = msOfDay ~/ 1000;
        msPart = msOfDay - secOfDay * 1000;
        hour = secOfDay ~/ 3600;
        final remSec = secOfDay - hour * 3600;
        minute = remSec ~/ 60;
        second = remSec - minute * 60;
      }

      if ((mask & (_needDate | _needWeek | _needIsoWeek)) != 0) {
        weekday0 = (dayCount + 4) % 7;
        final z = dayCount + 719468;
        final era = (z >= 0 ? z : z - 146096) ~/ 146097;
        final doe = z - era * 146097;
        final yoe = (doe - doe ~/ 1460 + doe ~/ 36524 - doe ~/ 146096) ~/ 365;
        year = yoe + era * 400;
        final doyMar = doe - (365 * yoe + yoe ~/ 4 - yoe ~/ 100);
        final mp = (5 * doyMar + 2) ~/ 153;
        day = doyMar - (153 * mp + 2) ~/ 5 + 1;
        month = mp < 10 ? mp + 3 : mp - 9;
        if (month <= 2) year += 1;

        if ((mask & (_needWeek | _needIsoWeek)) != 0) {
          final leap = _isLeapYear(year);
          doy =
              _monthDayOffsets[month - 1] +
              (month > 2 && leap ? 1 : 0) +
              day -
              1;

          if ((mask & _needIsoWeek) != 0) {
            final isoDow = weekday0 == 0 ? 7 : weekday0;
            final thursdayDoy = doy + (4 - isoDow);
            final yearDays = leap ? 366 : 365;
            if (thursdayDoy < 0) {
              isoYear = year - 1;
              final prevDays = _isLeapYear(isoYear) ? 366 : 365;
              isoWeek = (thursdayDoy + prevDays) ~/ 7 + 1;
            } else if (thursdayDoy >= yearDays) {
              isoYear = year + 1;
              isoWeek = 1;
            } else {
              isoYear = year;
              isoWeek = thursdayDoy ~/ 7 + 1;
            }
          }
        }
      }
    }

    final def = _locale.definition;
    final pads = _pads;
    final lits = _literals;

    if (_isJs) {
      final sb = StringBuffer();
      for (var i = 0; i < opCount; ++i) {
        final pad = pads[i];
        switch (ops[i]) {
          case _fLit:
            sb.write(lits[i]);
          case _fShortWeekday:
            sb.write(def.shortDays[weekday0]);
          case _fWeekday:
            sb.write(def.days[weekday0]);
          case _fShortMonth:
            sb.write(def.shortMonths[month - 1]);
          case _fMonth:
            sb.write(def.months[month - 1]);
          case _fDay:
            sb.write(_jsPad2(day, pad));
          case _fMicroseconds:
            sb
              ..write(_jsPad3(msPart, pad))
              ..write('000');
          case _fYearISO:
            sb.write(_jsPad2(isoYear.remainder(100), pad));
          case _fFullYearISO:
            sb.write(_jsPad4(isoYear.remainder(10000), pad));
          case _fHour24:
            sb.write(_jsPad2(hour, pad));
          case _fHour12:
            final h12 = hour % 12;
            sb.write(_jsPad2(h12 == 0 ? 12 : h12, pad));
          case _fDayOfYear:
            sb.write(_jsPad3(doy + 1, pad));
          case _fMilliseconds:
            sb.write(_jsPad3(msPart, pad));
          case _fMonthNum:
            sb.write(_jsPad2(month, pad));
          case _fMinutes:
            sb.write(_jsPad2(minute, pad));
          case _fPeriod:
            sb.write(def.periods[hour >= 12 ? 1 : 0]);
          case _fQuarter:
            sb.write(_d1[1 + (month - 1) ~/ 3]);
          case _fUnixMs:
            sb.write(ms);
          case _fUnixSec:
            sb.write(ms >= 0 ? ms ~/ 1000 : -((-ms + 999) ~/ 1000));
          case _fSeconds:
            sb.write(_jsPad2(second, pad));
          case _fWeekdayMon:
            sb.write(_d1[weekday0 == 0 ? 7 : weekday0]);
          case _fWeekSun:
            sb.write(_jsPad2((doy + 7 - weekday0) ~/ 7, pad));
          case _fWeekISO:
            sb.write(_jsPad2(isoWeek, pad));
          case _fWeekdaySun:
            sb.write(_d1[weekday0]);
          case _fWeekMon:
            final monDow = weekday0 == 0 ? 6 : weekday0 - 1;
            sb.write(_jsPad2((doy + 7 - monDow) ~/ 7, pad));
          case _fYear:
            sb.write(_jsPad2(year.remainder(100), pad));
          case _fFullYear:
            sb.write(_jsPad4(year.remainder(10000), pad));
          case _fZone:
            sb.write(_jsZone(offsetMinutes));
        }
      }
      return sb.toString();
    }

    if (_latin1Only) {
      var pos = 0;
      for (var i = 0; i < opCount; ++i) {
        final pad = pads[i];
        switch (ops[i]) {
          case _fLit:
            pos = _writeStr8(pos, lits[i]);
          case _fShortWeekday:
            pos = _writeStr8(pos, def.shortDays[weekday0]);
          case _fWeekday:
            pos = _writeStr8(pos, def.days[weekday0]);
          case _fShortMonth:
            pos = _writeStr8(pos, def.shortMonths[month - 1]);
          case _fMonth:
            pos = _writeStr8(pos, def.months[month - 1]);
          case _fDay:
            pos = _writePad2_8(pos, day, pad);
          case _fMicroseconds:
            pos = _writePad3_8(pos, msPart, pad);
            _ensureBuf8(pos + 3);
            _buf8[pos++] = 48;
            _buf8[pos++] = 48;
            _buf8[pos++] = 48;
          case _fYearISO:
            pos = _writePad2_8(pos, isoYear.remainder(100), pad);
          case _fFullYearISO:
            pos = _writePad4_8(pos, isoYear.remainder(10000), pad);
          case _fHour24:
            pos = _writePad2_8(pos, hour, pad);
          case _fHour12:
            final h12 = hour % 12;
            pos = _writePad2_8(pos, h12 == 0 ? 12 : h12, pad);
          case _fDayOfYear:
            pos = _writePad3_8(pos, doy + 1, pad);
          case _fMilliseconds:
            pos = _writePad3_8(pos, msPart, pad);
          case _fMonthNum:
            pos = _writePad2_8(pos, month, pad);
          case _fMinutes:
            pos = _writePad2_8(pos, minute, pad);
          case _fPeriod:
            pos = _writeStr8(pos, def.periods[hour >= 12 ? 1 : 0]);
          case _fQuarter:
            _ensureBuf8(pos + 1);
            _buf8[pos++] = 49 + (month - 1) ~/ 3;
          case _fUnixMs:
            pos = _writeStr8(pos, ms.toString());
          case _fUnixSec:
            final sec = ms >= 0 ? ms ~/ 1000 : -((-ms + 999) ~/ 1000);
            pos = _writeStr8(pos, sec.toString());
          case _fSeconds:
            pos = _writePad2_8(pos, second, pad);
          case _fWeekdayMon:
            _ensureBuf8(pos + 1);
            _buf8[pos++] = 48 + (weekday0 == 0 ? 7 : weekday0);
          case _fWeekSun:
            pos = _writePad2_8(pos, (doy + 7 - weekday0) ~/ 7, pad);
          case _fWeekISO:
            pos = _writePad2_8(pos, isoWeek, pad);
          case _fWeekdaySun:
            _ensureBuf8(pos + 1);
            _buf8[pos++] = 48 + weekday0;
          case _fWeekMon:
            final monDow = weekday0 == 0 ? 6 : weekday0 - 1;
            pos = _writePad2_8(pos, (doy + 7 - monDow) ~/ 7, pad);
          case _fYear:
            pos = _writePad2_8(pos, year.remainder(100), pad);
          case _fFullYear:
            pos = _writePad4_8(pos, year.remainder(10000), pad);
          case _fZone:
            pos = _writeZone8(pos, offsetMinutes);
        }
      }
      return String.fromCharCodes(_buf8, 0, pos);
    }

    var pos = 0;
    for (var i = 0; i < opCount; ++i) {
      final pad = pads[i];
      switch (ops[i]) {
        case _fLit:
          pos = _writeStr16(pos, lits[i]);
        case _fShortWeekday:
          pos = _writeStr16(pos, def.shortDays[weekday0]);
        case _fWeekday:
          pos = _writeStr16(pos, def.days[weekday0]);
        case _fShortMonth:
          pos = _writeStr16(pos, def.shortMonths[month - 1]);
        case _fMonth:
          pos = _writeStr16(pos, def.months[month - 1]);
        case _fDay:
          pos = _writePad2_16(pos, day, pad);
        case _fMicroseconds:
          pos = _writePad3_16(pos, msPart, pad);
          _ensureBuf16(pos + 3);
          _buf16[pos++] = 48;
          _buf16[pos++] = 48;
          _buf16[pos++] = 48;
        case _fYearISO:
          pos = _writePad2_16(pos, isoYear.remainder(100), pad);
        case _fFullYearISO:
          pos = _writePad4_16(pos, isoYear.remainder(10000), pad);
        case _fHour24:
          pos = _writePad2_16(pos, hour, pad);
        case _fHour12:
          final h12 = hour % 12;
          pos = _writePad2_16(pos, h12 == 0 ? 12 : h12, pad);
        case _fDayOfYear:
          pos = _writePad3_16(pos, doy + 1, pad);
        case _fMilliseconds:
          pos = _writePad3_16(pos, msPart, pad);
        case _fMonthNum:
          pos = _writePad2_16(pos, month, pad);
        case _fMinutes:
          pos = _writePad2_16(pos, minute, pad);
        case _fPeriod:
          pos = _writeStr16(pos, def.periods[hour >= 12 ? 1 : 0]);
        case _fQuarter:
          _ensureBuf16(pos + 1);
          _buf16[pos++] = 49 + (month - 1) ~/ 3;
        case _fUnixMs:
          pos = _writeStr16(pos, ms.toString());
        case _fUnixSec:
          final sec = ms >= 0 ? ms ~/ 1000 : -((-ms + 999) ~/ 1000);
          pos = _writeStr16(pos, sec.toString());
        case _fSeconds:
          pos = _writePad2_16(pos, second, pad);
        case _fWeekdayMon:
          _ensureBuf16(pos + 1);
          _buf16[pos++] = 48 + (weekday0 == 0 ? 7 : weekday0);
        case _fWeekSun:
          pos = _writePad2_16(pos, (doy + 7 - weekday0) ~/ 7, pad);
        case _fWeekISO:
          pos = _writePad2_16(pos, isoWeek, pad);
        case _fWeekdaySun:
          _ensureBuf16(pos + 1);
          _buf16[pos++] = 48 + weekday0;
        case _fWeekMon:
          final monDow = weekday0 == 0 ? 6 : weekday0 - 1;
          pos = _writePad2_16(pos, (doy + 7 - monDow) ~/ 7, pad);
        case _fYear:
          pos = _writePad2_16(pos, year.remainder(100), pad);
        case _fFullYear:
          pos = _writePad4_16(pos, year.remainder(10000), pad);
        case _fZone:
          pos = _writeZone16(pos, offsetMinutes);
      }
    }
    return String.fromCharCodes(_buf16, 0, pos);
  }

  @override
  String toString() => specifier;
}

/// A compiled date/time parser returned by [TimeLocale.parse] or
/// [TimeLocale.utcParse].
///
/// Implements [call] taking [String] (tearing off to
/// `DateTime? Function(String)`) and [toString] returning [specifier].
final class TimeParse._(
  /// The format specifier used to construct this parser.
  final String specifier,
  final TimeLocale _locale,
  final bool _isUtc,
  final bool _invalid,
  final Uint8List _ops,
  final Int32List _litChars,
  final List<String> _litStrings,
) {
  /// Parses [input] according to [specifier], returning `null` if [input]
  /// does not match.
  DateTime? call(String input) {
    if (_invalid) return null;

    var y = 1900;
    var m = -1; // -1 = unset
    var d = 1;
    var h = 0;
    var min = 0;
    var sec = 0;
    var ms = 0;
    var period = -1;
    var quarter = -1;
    var hasQ = false;
    var unixQ = 0;
    var hasS = false;
    var unixS = 0;
    var hasU = false;
    var weekU = 0;
    var hasV = false;
    var weekV = 0;
    var hasW = false;
    var weekW = 0;
    var hasWeekday = false;
    var weekday = 0;
    var hasWeekdayMon = false;
    var weekdayMon = 0;
    var hasZ = false;
    var zone = 0;

    final ops = _ops;
    final opCount = ops.length;
    final litChars = _litChars;
    final litStrings = _litStrings;
    final len = input.length;
    var pos = 0;

    for (var i = 0; i < opCount; ++i) {
      if (pos >= len) return null;
      switch (ops[i]) {
        case _pLitChar:
          if (input.codeUnitAt(pos++) != litChars[i]) return null;
        case _pLitStr:
          final lit = litStrings[i];
          final litLen = lit.length;
          if (pos + litLen > len) return null;
          for (var j = 0; j < litLen; ++j) {
            if (input.codeUnitAt(pos + j) != lit.codeUnitAt(j)) return null;
          }
          pos += litLen;
        case _pFullYear:
          final end = pos + 4 < len ? pos + 4 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          y = v;
          pos = p;
        case _pYear:
          final end = pos + 2 < len ? pos + 2 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          y = v + (v > 68 ? 1900 : 2000);
          pos = p;
        case _pMonthNum:
          final end = pos + 2 < len ? pos + 2 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          m = v - 1;
          pos = p;
        case _pDay:
          final end = pos + 2 < len ? pos + 2 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          d = v;
          pos = p;
        case _pHour:
          final end = pos + 2 < len ? pos + 2 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          h = v;
          pos = p;
        case _pMinutes:
          final end = pos + 2 < len ? pos + 2 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          min = v;
          pos = p;
        case _pSeconds:
          final end = pos + 2 < len ? pos + 2 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          sec = v;
          pos = p;
        case _pMilliseconds:
          final end = pos + 3 < len ? pos + 3 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          ms = v;
          pos = p;
        case _pMicroseconds:
          final end = pos + 6 < len ? pos + 6 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          ms = v ~/ 1000;
          pos = p;
        case _pDayOfYear:
          final end = pos + 3 < len ? pos + 3 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          m = 0;
          d = v;
          pos = p;
        case _pQuarter:
          final c = input.codeUnitAt(pos) - 48;
          if (c < 0 || c > 9) return null;
          quarter = c * 3 - 3;
          pos++;
        case _pWeekdaySun:
          final c = input.codeUnitAt(pos) - 48;
          if (c < 0 || c > 9) return null;
          weekday = c;
          hasWeekday = true;
          pos++;
        case _pWeekdayMon:
          final c = input.codeUnitAt(pos) - 48;
          if (c < 0 || c > 9) return null;
          weekdayMon = c;
          hasWeekdayMon = true;
          pos++;
        case _pWeekSun:
          final end = pos + 2 < len ? pos + 2 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          weekU = v;
          hasU = true;
          pos = p;
        case _pWeekISO:
          final end = pos + 2 < len ? pos + 2 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          weekV = v;
          hasV = true;
          pos = p;
        case _pWeekMon:
          final end = pos + 2 < len ? pos + 2 : len;
          var p = pos;
          while (p < end && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < end) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          weekW = v;
          hasW = true;
          pos = p;
        case _pUnixMs:
          var p = pos;
          while (p < len && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < len) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          unixQ = v;
          hasQ = true;
          pos = p;
        case _pUnixSec:
          var p = pos;
          while (p < len && _isJsWhitespace(input.codeUnitAt(p))) {
            p++;
          }
          final ds = p;
          var v = 0;
          while (p < len) {
            final c = input.codeUnitAt(p) - 48;
            if (c < 0 || c > 9) break;
            v = v * 10 + c;
            p++;
          }
          if (p == ds) return null;
          unixS = v;
          hasS = true;
          pos = p;
        case _pZone:
          final c0 = input.codeUnitAt(pos);
          if (c0 == 90) {
            zone = 0;
            hasZ = true;
            pos++;
          } else if (c0 == 43 || c0 == 45) {
            final end = pos + 6 < len ? pos + 6 : len;
            if (pos + 3 > end) return null;
            final h1 = input.codeUnitAt(pos + 1) - 48;
            final h2 = input.codeUnitAt(pos + 2) - 48;
            if (h1 < 0 || h1 > 9 || h2 < 0 || h2 > 9) return null;
            final hh = h1 * 10 + h2;
            var mm = 0;
            var p = pos + 3;
            if (p < end) {
              final next = input.codeUnitAt(p);
              if (next == 58) {
                if (p + 3 <= end) {
                  final m1 = input.codeUnitAt(p + 1) - 48;
                  final m2 = input.codeUnitAt(p + 2) - 48;
                  if (m1 >= 0 && m1 <= 9 && m2 >= 0 && m2 <= 9) {
                    mm = m1 * 10 + m2;
                    p += 3;
                  }
                }
              } else if (p + 2 <= end) {
                final m1 = next - 48;
                final m2 = input.codeUnitAt(p + 1) - 48;
                if (m1 >= 0 && m1 <= 9 && m2 >= 0 && m2 <= 9) {
                  mm = m1 * 10 + m2;
                  p += 2;
                }
              }
            }
            zone = (c0 == 43 ? -1 : 1) * (hh * 100 + mm);
            hasZ = true;
            pos = p;
          } else {
            return null;
          }
        case _pPeriod:
          final next = _locale._periodMatcher.match(input, pos);
          if (next < 0) return null;
          period = _locale._periodMatcher.matchedIndex;
          pos = next;
        case _pShortWeekday:
          final next = _locale._shortWeekdayMatcher.match(input, pos);
          if (next < 0) return null;
          weekday = _locale._shortWeekdayMatcher.matchedIndex;
          hasWeekday = true;
          pos = next;
        case _pWeekday:
          final next = _locale._weekdayMatcher.match(input, pos);
          if (next < 0) return null;
          weekday = _locale._weekdayMatcher.matchedIndex;
          hasWeekday = true;
          pos = next;
        case _pShortMonth:
          final next = _locale._shortMonthMatcher.match(input, pos);
          if (next < 0) return null;
          m = _locale._shortMonthMatcher.matchedIndex;
          pos = next;
        case _pMonth:
          final next = _locale._monthMatcher.match(input, pos);
          if (next < 0) return null;
          m = _locale._monthMatcher.matchedIndex;
          pos = next;
      }
    }

    if (pos != len) return null;

    if (hasQ) {
      return DateTime.fromMillisecondsSinceEpoch(unixQ, isUtc: _isUtc);
    }
    if (hasS) {
      return DateTime.fromMillisecondsSinceEpoch(
        unixS * 1000 + ms,
        isUtc: _isUtc,
      );
    }

    if (_isUtc && !hasZ) {
      hasZ = true;
      zone = 0;
    }

    if (period >= 0) {
      h = h % 12 + period * 12;
    }

    if (m < 0) {
      m = quarter >= 0 ? quarter : 0;
    }

    if (hasV) {
      if (weekV < 1 || weekV > 53) return null;
      if (!hasWeekday) weekday = 1;
      if (hasZ) {
        var week = DateTime.utc(y);
        final day0 = week.weekday % 7;
        week = day0 > 4 || day0 == 0 ? utcMonday.ceil(week) : utcMonday(week);
        week = utcDay.offset(week, (weekV - 1) * 7);
        y = week.year;
        m = week.month - 1;
        d = week.day + (weekday + 6) % 7;
      } else {
        var week = DateTime(y);
        final day0 = week.weekday % 7;
        week = day0 > 4 || day0 == 0 ? timeMonday.ceil(week) : timeMonday(week);
        week = timeDay.offset(week, (weekV - 1) * 7);
        y = week.year;
        m = week.month - 1;
        d = week.day + (weekday + 6) % 7;
      }
    } else if (hasW || hasU) {
      if (!hasWeekday) {
        weekday = hasWeekdayMon ? weekdayMon % 7 : (hasW ? 1 : 0);
      }
      final day0 = hasZ
          ? (_daysFromCivil(y, 1, 1) + 4) % 7
          : DateTime(y).weekday % 7;
      m = 0;
      d = hasW
          ? (weekday + 6) % 7 + weekW * 7 - (day0 + 5) % 7
          : weekday + weekU * 7 - (day0 + 6) % 7;
    }

    if (hasZ) {
      h += zone ~/ 100;
      min += zone.remainder(100);
      if (m >= 0 && m <= 11) {
        final days = _daysFromCivil(y, m + 1, d);
        final epochMs =
            days * _msPerDay + h * 3600000 + min * 60000 + sec * 1000 + ms;
        return DateTime.fromMillisecondsSinceEpoch(epochMs, isUtc: _isUtc);
      }
      final result = DateTime.utc(y, m + 1, d, h, min, sec, ms);
      return _isUtc ? result : result.toLocal();
    }

    return DateTime(y, m + 1, d, h, min, sec, ms);
  }

  @override
  String toString() => specifier;
}

/// A time formatting and parsing locale returned by [timeFormatLocale].
final class TimeLocale(
  /// The [TimeLocaleDefinition] used to create this locale.
  final TimeLocaleDefinition definition,
) {
  /// Creates a [TimeLocale] from [definition].
  this;

  final _NameMatcher _periodMatcher = _NameMatcher(definition.periods);
  final _NameMatcher _weekdayMatcher = _NameMatcher(definition.days);
  final _NameMatcher _shortWeekdayMatcher = _NameMatcher(definition.shortDays);
  final _NameMatcher _monthMatcher = _NameMatcher(definition.months);
  final _NameMatcher _shortMonthMatcher = _NameMatcher(definition.shortMonths);

  final bool _periodsLatin1 = _allLatin1(definition.periods);
  final bool _daysLatin1 = _allLatin1(definition.days);
  final bool _shortDaysLatin1 = _allLatin1(definition.shortDays);
  final bool _monthsLatin1 = _allLatin1(definition.months);
  final bool _shortMonthsLatin1 = _allLatin1(definition.shortMonths);

  /// Returns a new local-time [TimeFormat] for [specifier].
  TimeFormat format(String specifier) =>
      _compileFormat(specifier, isUtc: false);

  /// Returns a new local-time [TimeParse] for [specifier].
  TimeParse parse(String specifier) => _compileParse(specifier, isUtc: false);

  /// Returns a new UTC [TimeFormat] for [specifier].
  TimeFormat utcFormat(String specifier) =>
      _compileFormat(specifier, isUtc: true);

  /// Returns a new UTC [TimeParse] for [specifier].
  TimeParse utcParse(String specifier) => _compileParse(specifier, isUtc: true);

  TimeFormat _compileFormat(String specifier, {required bool isUtc}) {
    final ops = <int>[];
    final pads = <int>[];
    final lits = <String>[];
    final litBuf = StringBuffer();
    var mask = 0;
    var latin1 = true;

    void flushLit() {
      if (litBuf.isNotEmpty) {
        final s = litBuf.toString();
        litBuf.clear();
        if (latin1 && !_isAsciiOnly(s)) latin1 = false;
        ops.add(_fLit);
        pads.add(0);
        lits.add(s);
      }
    }

    void emit(String spec, int depth) {
      final n = spec.length;
      var i = 0;
      while (i < n) {
        final ch = spec.codeUnitAt(i++);
        if (ch != 37) {
          litBuf.writeCharCode(ch);
          continue;
        }
        if (i >= n) {
          // Trailing '%' emits empty string in upstream.
          break;
        }
        var dChar = spec.codeUnitAt(i++);
        int pad;
        if (dChar == 45) {
          // '-'
          pad = _padNone;
          if (i >= n) break;
          dChar = spec.codeUnitAt(i++);
        } else if (dChar == 95) {
          // '_'
          pad = _padSpace;
          if (i >= n) break;
          dChar = spec.codeUnitAt(i++);
        } else if (dChar == 48) {
          // '0'
          pad = _padZero;
          if (i >= n) break;
          dChar = spec.codeUnitAt(i++);
        } else {
          pad = dChar == 101 ? _padSpace : _padZero; // 'e' defaults to space
        }

        if (dChar == 37) {
          // '%%'
          litBuf.writeCharCode(37);
          continue;
        }
        if (depth < 8) {
          if (dChar == 99) {
            // '%c'
            emit(definition.dateTime, depth + 1);
            continue;
          }
          if (dChar == 120) {
            // '%x'
            emit(definition.date, depth + 1);
            continue;
          }
          if (dChar == 88) {
            // '%X'
            emit(definition.time, depth + 1);
            continue;
          }
        }

        final int op;
        switch (dChar) {
          case 97: // 'a'
            op = _fShortWeekday;
            mask |= _needDate;
            if (!_shortDaysLatin1) latin1 = false;
          case 65: // 'A'
            op = _fWeekday;
            mask |= _needDate;
            if (!_daysLatin1) latin1 = false;
          case 98: // 'b'
            op = _fShortMonth;
            mask |= _needDate;
            if (!_shortMonthsLatin1) latin1 = false;
          case 66: // 'B'
            op = _fMonth;
            mask |= _needDate;
            if (!_monthsLatin1) latin1 = false;
          case 100: // 'd'
          case 101: // 'e'
            op = _fDay;
            mask |= _needDate;
          case 102: // 'f'
            op = _fMicroseconds;
            mask |= _needTime;
          case 103: // 'g'
            op = _fYearISO;
            mask |= _needIsoWeek;
          case 71: // 'G'
            op = _fFullYearISO;
            mask |= _needIsoWeek;
          case 72: // 'H'
            op = _fHour24;
            mask |= _needTime;
          case 73: // 'I'
            op = _fHour12;
            mask |= _needTime;
          case 106: // 'j'
            op = _fDayOfYear;
            mask |= _needWeek;
          case 76: // 'L'
            op = _fMilliseconds;
            mask |= _needTime;
          case 109: // 'm'
            op = _fMonthNum;
            mask |= _needDate;
          case 77: // 'M'
            op = _fMinutes;
            mask |= _needTime;
          case 112: // 'p'
            op = _fPeriod;
            mask |= _needTime;
            if (!_periodsLatin1) latin1 = false;
          case 113: // 'q'
            op = _fQuarter;
            mask |= _needDate;
          case 81: // 'Q'
            op = _fUnixMs;
          case 115: // 's'
            op = _fUnixSec;
          case 83: // 'S'
            op = _fSeconds;
            mask |= _needTime;
          case 117: // 'u'
            op = _fWeekdayMon;
            mask |= _needDate;
          case 85: // 'U'
            op = _fWeekSun;
            mask |= _needWeek;
          case 86: // 'V'
            op = _fWeekISO;
            mask |= _needIsoWeek;
          case 119: // 'w'
            op = _fWeekdaySun;
            mask |= _needDate;
          case 87: // 'W'
            op = _fWeekMon;
            mask |= _needWeek;
          case 121: // 'y'
            op = _fYear;
            mask |= _needDate;
          case 89: // 'Y'
            op = _fFullYear;
            mask |= _needDate;
          case 90: // 'Z'
            if (isUtc) {
              litBuf.write('+0000');
              continue;
            }
            op = _fZone;
            mask |= _needZone;
          default:
            // Unknown directive outputs character verbatim.
            litBuf.writeCharCode(dChar);
            continue;
        }

        flushLit();
        ops.add(op);
        pads.add(pad);
        lits.add('');
      }
    }

    emit(specifier, 0);
    flushLit();

    return TimeFormat._(
      specifier,
      this,
      isUtc,
      Uint8List.fromList(ops),
      Uint8List.fromList(pads),
      List<String>.of(lits, growable: false),
      mask,
      latin1,
    );
  }

  TimeParse _compileParse(String specifier, {required bool isUtc}) {
    final ops = <int>[];
    final litChars = <int>[];
    final litStrings = <String>[];
    final litBuf = StringBuffer();
    var invalid = false;

    void flushLit() {
      if (litBuf.isEmpty) return;
      final s = litBuf.toString();
      litBuf.clear();
      if (s.length == 1) {
        ops.add(_pLitChar);
        litChars.add(s.codeUnitAt(0));
        litStrings.add('');
      } else {
        ops.add(_pLitStr);
        litChars.add(0);
        litStrings.add(s);
      }
    }

    void emit(String spec, int depth) {
      final n = spec.length;
      var i = 0;
      while (i < n && !invalid) {
        final ch = spec.codeUnitAt(i++);
        if (ch != 37) {
          litBuf.writeCharCode(ch);
          continue;
        }
        if (i >= n) {
          invalid = true;
          return;
        }
        var dChar = spec.codeUnitAt(i++);
        if (dChar == 45 || dChar == 95 || dChar == 48) {
          if (i >= n) {
            invalid = true;
            return;
          }
          dChar = spec.codeUnitAt(i++);
        }

        if (dChar == 37) {
          litBuf.writeCharCode(37);
          continue;
        }
        if (depth < 8) {
          if (dChar == 99) {
            emit(definition.dateTime, depth + 1);
            continue;
          }
          if (dChar == 120) {
            emit(definition.date, depth + 1);
            continue;
          }
          if (dChar == 88) {
            emit(definition.time, depth + 1);
            continue;
          }
        }

        final int op;
        switch (dChar) {
          case 97:
            op = _pShortWeekday;
          case 65:
            op = _pWeekday;
          case 98:
            op = _pShortMonth;
          case 66:
            op = _pMonth;
          case 100:
          case 101:
            op = _pDay;
          case 102:
            op = _pMicroseconds;
          case 103:
          case 121:
            op = _pYear;
          case 71:
          case 89:
            op = _pFullYear;
          case 72:
          case 73:
            op = _pHour;
          case 106:
            op = _pDayOfYear;
          case 76:
            op = _pMilliseconds;
          case 109:
            op = _pMonthNum;
          case 77:
            op = _pMinutes;
          case 112:
            op = _pPeriod;
          case 113:
            op = _pQuarter;
          case 81:
            op = _pUnixMs;
          case 115:
            op = _pUnixSec;
          case 83:
            op = _pSeconds;
          case 117:
            op = _pWeekdayMon;
          case 85:
            op = _pWeekSun;
          case 86:
            op = _pWeekISO;
          case 119:
            op = _pWeekdaySun;
          case 87:
            op = _pWeekMon;
          case 90:
            op = _pZone;
          default:
            invalid = true;
            return;
        }

        flushLit();
        ops.add(op);
        litChars.add(0);
        litStrings.add('');
      }
    }

    emit(specifier, 0);
    flushLit();

    return TimeParse._(
      specifier,
      this,
      isUtc,
      invalid,
      Uint8List.fromList(ops),
      Int32List.fromList(litChars),
      List<String>.of(litStrings, growable: false),
    );
  }
}

/// Returns a [TimeLocale] object for the specified [definition].
TimeLocale timeFormatLocale(TimeLocaleDefinition definition) =>
    TimeLocale(definition);
