// Original code, not ported from d3-time-format: Node.js reference parity.

import 'package:flutter_d3_time_format_port/flutter_d3_time_format_port.dart';
import 'package:test/test.dart';

import 'd3_time_format_reference.dart';

void main() {
  test(
    'utcFormat matches Node.js d3-time-format v4.1.0 across all directives',
    () {
      for (final (spec, ms, expected) in refUtcFormat) {
        final f = utcFormat(spec);
        expect('$f', spec);
        final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
        expect(f(d), expected, reason: 'utcFormat("$spec")($ms)');
      }
    },
  );

  test('isoFormat matches Node.js d3-time-format v4.1.0', () {
    for (final (ms, expected) in refIsoFormat) {
      final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      expect(isoFormat(d), expected, reason: 'isoFormat($ms)');
    }
  });

  test(
    'utcParse matches Node.js d3-time-format v4.1.0 across all directives',
    () {
      for (final (spec, input, expectedMs) in refUtcParse) {
        final p = utcParse(spec);
        expect('$p', spec);
        final actual = p(input);
        expect(
          actual?.millisecondsSinceEpoch,
          expectedMs,
          reason: 'utcParse("$spec")("$input")',
        );
        if (actual != null) {
          expect(actual.isUtc, isTrue);
        }
      }
    },
  );

  test('isoParse matches Node.js d3-time-format v4.1.0', () {
    for (final (input, expectedMs) in refIsoParse) {
      final actual = isoParse(input);
      expect(
        actual?.millisecondsSinceEpoch,
        expectedMs,
        reason: 'isoParse("$input")',
      );
    }
  });

  test(
    'all 34 locales match Node.js d3-time-format v4.1.0 for format and parse',
    () {
      for (final (tag, ms, cOut, xOut, timeOut, abOut, parsedCMs, parsedFullMs)
          in refLocales) {
        final def = timeFormatLocales[tag]!;
        final loc = timeFormatLocale(def);
        final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
        expect(loc.utcFormat('%c')(d), cOut, reason: '$tag %c ($ms)');
        expect(loc.utcFormat('%x')(d), xOut, reason: '$tag %x ($ms)');
        expect(loc.utcFormat('%X')(d), timeOut, reason: '$tag %X ($ms)');
        expect(
          loc.utcFormat('%A %a %B %b %p')(d),
          abOut,
          reason: '$tag %A %a %B %b %p ($ms)',
        );
        expect(
          loc.utcParse('%c')(cOut)?.millisecondsSinceEpoch,
          parsedCMs,
          reason: '$tag parse %c ($cOut)',
        );
        final fullStr = loc.utcFormat('%B %d, %Y')(d);
        expect(
          loc.utcParse('%B %d, %Y')(fullStr)?.millisecondsSinceEpoch,
          parsedFullMs,
          reason: '$tag parse %B %d, %Y ($fullStr)',
        );
      }
    },
  );
}
