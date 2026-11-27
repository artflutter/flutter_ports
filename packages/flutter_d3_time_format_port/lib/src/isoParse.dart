// Ported from d3-time-format v4.1.0 src/isoParse.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/isoParse.js` of d3-time-format 4.1.0.
library;

// DIVERGES(d3-time-format): adapt-time-format-typed-api, typed String input
// returning DateTime? matching ES2015 ISO 8601 parsing semantics.
// DIVERGES(d3-time-format): adapt-time-format-fast-forms, direct code-unit
// ISO 8601 parser with Hinnant days-from-civil arithmetic avoiding RegExp and
// DateTime.tryParse overhead on canonical timestamps.

const int _msPerDay = 86400000;

@pragma('vm:prefer-inline')
int _readDigit(String s, int i) {
  final c = s.codeUnitAt(i) - 48;
  return (c >= 0 && c <= 9) ? c : -1;
}

@pragma('vm:prefer-inline')
int _read2(String s, int i) {
  final a = s.codeUnitAt(i) - 48;
  final b = s.codeUnitAt(i + 1) - 48;
  if (a < 0 || a > 9 || b < 0 || b > 9) return -1;
  return a * 10 + b;
}

@pragma('vm:prefer-inline')
int _read3(String s, int i) {
  final a = s.codeUnitAt(i) - 48;
  final b = s.codeUnitAt(i + 1) - 48;
  final c = s.codeUnitAt(i + 2) - 48;
  if (a < 0 || a > 9 || b < 0 || b > 9 || c < 0 || c > 9) return -1;
  return a * 100 + b * 10 + c;
}

@pragma('vm:prefer-inline')
int _read4(String s, int i) {
  final a = s.codeUnitAt(i) - 48;
  final b = s.codeUnitAt(i + 1) - 48;
  final c = s.codeUnitAt(i + 2) - 48;
  final d = s.codeUnitAt(i + 3) - 48;
  if (a < 0 || a > 9 || b < 0 || b > 9 || c < 0 || c > 9 || d < 0 || d > 9) {
    return -1;
  }
  return a * 1000 + b * 100 + c * 10 + d;
}

@pragma('vm:prefer-inline')
int _daysFromCivil(int y, int m, int d) {
  final yAdj = m <= 2 ? y - 1 : y;
  final era = (yAdj >= 0 ? yAdj : yAdj - 399) ~/ 400;
  final yoe = yAdj - era * 400;
  final doy = (153 * (m > 2 ? m - 3 : m + 9) + 2) ~/ 5 + d - 1;
  final doe = yoe * 365 + yoe ~/ 4 - yoe ~/ 100 + doy;
  return era * 146097 + doe - 719468;
}

bool _isDateOnlyIso(String s) {
  final n = s.length;
  var pos = 0;
  if (n < 10 || n > 13) return false;
  final c0 = s.codeUnitAt(0);
  if (c0 == 43 || c0 == 45) pos = 1;
  final yLen = n - pos - 6;
  if (yLen < 4 || yLen > 6) return false;
  for (var i = pos; i < pos + yLen; ++i) {
    if (_readDigit(s, i) < 0) return false;
  }
  pos += yLen;
  if (s.codeUnitAt(pos) != 45 || s.codeUnitAt(pos + 3) != 45) return false;
  return _read2(s, pos + 1) >= 0 && _read2(s, pos + 4) >= 0;
}

/// Parses an ISO 8601 string into a [DateTime], or returns `null` if [input]
/// cannot be parsed.
DateTime? isoParse(String input) {
  final n = input.length;

  // Ultra-fast path for canonical 24-char `YYYY-MM-DDTHH:MM:SS.SSSZ`.
  if (n == 24 &&
      input.codeUnitAt(4) == 45 &&
      input.codeUnitAt(7) == 45 &&
      input.codeUnitAt(10) == 84 &&
      input.codeUnitAt(13) == 58 &&
      input.codeUnitAt(16) == 58 &&
      input.codeUnitAt(19) == 46 &&
      input.codeUnitAt(23) == 90) {
    final y = _read4(input, 0);
    final m = _read2(input, 5);
    final d = _read2(input, 8);
    final h = _read2(input, 11);
    final min = _read2(input, 14);
    final sec = _read2(input, 17);
    final ms = _read3(input, 20);
    if (y >= 0 &&
        m >= 1 &&
        m <= 12 &&
        d >= 1 &&
        d <= 31 &&
        h >= 0 &&
        h <= 23 &&
        min >= 0 &&
        min <= 59 &&
        sec >= 0 &&
        sec <= 59 &&
        ms >= 0) {
      final days = _daysFromCivil(y, m, d);
      return DateTime.fromMillisecondsSinceEpoch(
        days * _msPerDay + h * 3600000 + min * 60000 + sec * 1000 + ms,
        isUtc: true,
      );
    }
  }

  // Fast path for `YYYY-MM-DDTHH:MM:SS(.frac)?(Z|±HH:MM|±HHMM)`.
  if (n >= 20 &&
      input.codeUnitAt(4) == 45 &&
      input.codeUnitAt(7) == 45 &&
      (input.codeUnitAt(10) == 84 || input.codeUnitAt(10) == 116) &&
      input.codeUnitAt(13) == 58 &&
      input.codeUnitAt(16) == 58) {
    final y = _read4(input, 0);
    final m = _read2(input, 5);
    final d = _read2(input, 8);
    final h = _read2(input, 11);
    final min = _read2(input, 14);
    final sec = _read2(input, 17);
    if (y >= 0 &&
        m >= 1 &&
        m <= 12 &&
        d >= 1 &&
        d <= 31 &&
        h >= 0 &&
        h <= 23 &&
        min >= 0 &&
        min <= 59 &&
        sec >= 0 &&
        sec <= 59) {
      var pos = 19;
      var ms = 0;
      if (pos < n && input.codeUnitAt(pos) == 46) {
        pos++;
        final fracStart = pos;
        var scale = 100;
        while (pos < n) {
          final dig = _readDigit(input, pos);
          if (dig < 0) break;
          if (scale > 0) {
            ms += dig * scale;
            scale ~/= 10;
          }
          pos++;
        }
        if (pos == fracStart) return null;
      }
      if (pos < n) {
        final tzChar = input.codeUnitAt(pos);
        if ((tzChar == 90 || tzChar == 122) && pos + 1 == n) {
          final days = _daysFromCivil(y, m, d);
          return DateTime.fromMillisecondsSinceEpoch(
            days * _msPerDay + h * 3600000 + min * 60000 + sec * 1000 + ms,
            isUtc: true,
          );
        }
        if (tzChar == 43 || tzChar == 45) {
          final sign = tzChar == 43 ? -1 : 1;
          pos++;
          if (pos + 2 <= n) {
            final oh = _read2(input, pos);
            if (oh >= 0 && oh <= 23) {
              pos += 2;
              var om = 0;
              if (pos < n && input.codeUnitAt(pos) == 58) pos++;
              if (pos + 2 == n) {
                om = _read2(input, pos);
                pos += 2;
              }
              if (pos == n && om >= 0 && om <= 59) {
                final days = _daysFromCivil(y, m, d);
                final offsetMs = sign * (oh * 3600000 + om * 60000);
                return DateTime.fromMillisecondsSinceEpoch(
                  days * _msPerDay +
                      h * 3600000 +
                      min * 60000 +
                      sec * 1000 +
                      ms +
                      offsetMs,
                  isUtc: true,
                );
              }
            }
          }
        }
      }
    }
  }

  // Fast path for date-only `YYYY-MM-DD` (UTC per ES2015).
  if (n == 10 && input.codeUnitAt(4) == 45 && input.codeUnitAt(7) == 45) {
    final y = _read4(input, 0);
    final m = _read2(input, 5);
    final d = _read2(input, 8);
    if (y >= 0 && m >= 1 && m <= 12 && d >= 1 && d <= 31) {
      return DateTime.fromMillisecondsSinceEpoch(
        _daysFromCivil(y, m, d) * _msPerDay,
        isUtc: true,
      );
    }
  }

  final parsed = DateTime.tryParse(input);
  if (parsed == null) return null;
  if (!parsed.isUtc && _isDateOnlyIso(input)) {
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }
  return parsed;
}
