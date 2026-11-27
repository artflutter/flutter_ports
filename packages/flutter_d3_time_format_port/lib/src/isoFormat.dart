// Ported from d3-time-format v4.1.0 src/isoFormat.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/isoFormat.js` of d3-time-format 4.1.0.
library;

import 'dart:typed_data';

// DIVERGES(d3-time-format): adapt-time-format-typed-api, typed DateTime input
// with millisecond precision and 6-digit expanded years matching JS
// Date.prototype.toISOString().
// DIVERGES(d3-time-format): adapt-time-format-fast-forms, direct Hinnant civil
// calendar breakdown and fixed-length Uint8List / 2-digit table formatting.

const bool _isWasm = bool.fromEnvironment('dart.tool.dart2wasm');
const bool _isJs = bool.fromEnvironment('dart.library.js_interop') && !_isWasm;

/// The ISO 8601 UTC format specifier (`'%Y-%m-%dT%H:%M:%S.%LZ'`).
const String isoSpecifier = '%Y-%m-%dT%H:%M:%S.%LZ';

final Uint8List _isoBuf24 = Uint8List(24)
  ..[4] =
      45 // -
  ..[7] =
      45 // -
  ..[10] =
      84 // T
  ..[13] =
      58 // :
  ..[16] =
      58 // :
  ..[19] =
      46 // .
  ..[23] = 90; // Z

final Uint8List _isoBuf27 = Uint8List(27)
  ..[7] =
      45 // -
  ..[10] =
      45 // -
  ..[13] =
      84 // T
  ..[16] =
      58 // :
  ..[19] =
      58 // :
  ..[22] =
      46 // .
  ..[26] = 90; // Z

const List<String> _d2 = [
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

const int _msPerDay = 86400000;

/// Formats [date] as an ISO 8601 UTC string (`YYYY-MM-DDTHH:mm:ss.SSSZ`).
String isoFormat(DateTime date) {
  final ms = date.millisecondsSinceEpoch;
  final int dayCount;
  if (ms >= 0) {
    dayCount = ms ~/ _msPerDay;
  } else {
    dayCount = -((-ms + _msPerDay - 1) ~/ _msPerDay);
  }
  final msOfDay = ms - dayCount * _msPerDay;
  final secOfDay = msOfDay ~/ 1000;
  final msPart = msOfDay - secOfDay * 1000;
  final hour = secOfDay ~/ 3600;
  final remSec = secOfDay - hour * 3600;
  final minute = remSec ~/ 60;
  final second = remSec - minute * 60;

  final z = dayCount + 719468;
  final era = (z >= 0 ? z : z - 146096) ~/ 146097;
  final doe = z - era * 146097;
  final yoe = (doe - doe ~/ 1460 + doe ~/ 36524 - doe ~/ 146096) ~/ 365;
  var year = yoe + era * 400;
  final doyMar = doe - (365 * yoe + yoe ~/ 4 - yoe ~/ 100);
  final mp = (5 * doyMar + 2) ~/ 153;
  final day = doyMar - (153 * mp + 2) ~/ 5 + 1;
  final month = mp < 10 ? mp + 3 : mp - 9;
  if (month <= 2) year += 1;

  if (_isJs) {
    final String yStr;
    if (year >= 0 && year <= 9999) {
      final yHi = year ~/ 100;
      yStr = '${_d2[yHi]}${_d2[year - yHi * 100]}';
    } else {
      final absY = year < 0 ? -year : year;
      final sign = year < 0 ? '-' : '+';
      yStr = '$sign${absY.toString().padLeft(6, '0')}';
    }
    final msH = msPart ~/ 100;
    return '$yStr-${_d2[month]}-${_d2[day]}T'
        '${_d2[hour]}:${_d2[minute]}:${_d2[second]}.'
        '$msH${_d2[msPart - msH * 100]}Z';
  }

  if (year >= 0 && year <= 9999) {
    final b = _isoBuf24;
    final yHi = year ~/ 100;
    final yLo = year - yHi * 100;
    b[0] = 48 + yHi ~/ 10;
    b[1] = 48 + yHi % 10;
    b[2] = 48 + yLo ~/ 10;
    b[3] = 48 + yLo % 10;
    b[5] = 48 + month ~/ 10;
    b[6] = 48 + month % 10;
    b[8] = 48 + day ~/ 10;
    b[9] = 48 + day % 10;
    b[11] = 48 + hour ~/ 10;
    b[12] = 48 + hour % 10;
    b[14] = 48 + minute ~/ 10;
    b[15] = 48 + minute % 10;
    b[17] = 48 + second ~/ 10;
    b[18] = 48 + second % 10;
    b[20] = 48 + msPart ~/ 100;
    final msRem = msPart % 100;
    b[21] = 48 + msRem ~/ 10;
    b[22] = 48 + msRem % 10;
    return String.fromCharCodes(b);
  }

  final b = _isoBuf27;
  final absY = year < 0 ? -year : year;
  b[0] = year < 0 ? 45 : 43; // '-' or '+'
  b[1] = 48 + (absY ~/ 100000) % 10;
  b[2] = 48 + (absY ~/ 10000) % 10;
  b[3] = 48 + (absY ~/ 1000) % 10;
  b[4] = 48 + (absY ~/ 100) % 10;
  b[5] = 48 + (absY ~/ 10) % 10;
  b[6] = 48 + absY % 10;
  b[8] = 48 + month ~/ 10;
  b[9] = 48 + month % 10;
  b[11] = 48 + day ~/ 10;
  b[12] = 48 + day % 10;
  b[14] = 48 + hour ~/ 10;
  b[15] = 48 + hour % 10;
  b[17] = 48 + minute ~/ 10;
  b[18] = 48 + minute % 10;
  b[20] = 48 + second ~/ 10;
  b[21] = 48 + second % 10;
  b[23] = 48 + msPart ~/ 100;
  final msRem = msPart % 100;
  b[24] = 48 + msRem ~/ 10;
  b[25] = 48 + msRem % 10;
  return String.fromCharCodes(b);
}
