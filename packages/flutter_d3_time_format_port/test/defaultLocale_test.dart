// Ported from d3-time-format v4.1.0 test/defaultLocale-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_time_format_port/d3_time_format.dart';
import 'package:test/test.dart';

// DIVERGES(d3-time-format): adapt-time-format-typed-api, uses const locales
// timeLocaleEnUS / timeLocaleFrFR and checks defaultTimeLocale instead of JS
// mutable export identity.
void main() {
  test('timeFormat(specifier) defaults to en-US', () {
    expect(timeFormat('%c')(DateTime(2000)), '1/1/2000, 12:00:00 AM');
  });

  test('timeParse(specifier) defaults to en-US', () {
    expect(
      timeParse('%c')('1/1/2000, 12:00:00 AM')?.millisecondsSinceEpoch,
      DateTime(2000).millisecondsSinceEpoch,
    );
  });

  test('utcFormat(specifier) defaults to en-US', () {
    expect(utcFormat('%c')(DateTime.utc(2000)), '1/1/2000, 12:00:00 AM');
  });

  test('utcParse(specifier) defaults to en-US', () {
    expect(
      utcParse('%c')('1/1/2000, 12:00:00 AM')?.millisecondsSinceEpoch,
      DateTime.utc(2000).millisecondsSinceEpoch,
    );
  });

  test(
    'timeFormatDefaultLocale(definition) returns the new default locale',
    () {
      final locale = timeFormatDefaultLocale(timeLocaleFrFR);
      try {
        expect(
          locale.format('%c')(DateTime(2000)),
          'samedi  1 janvier 2000 à 00:00:00',
        );
      } finally {
        timeFormatDefaultLocale(timeLocaleEnUS);
      }
    },
  );

  test('timeFormatDefaultLocale(definition) affects timeFormat', () {
    final locale = timeFormatDefaultLocale(timeLocaleFrFR);
    try {
      expect(identical(defaultTimeLocale, locale), isTrue);
      expect(
        timeFormat('%c')(DateTime(2000)),
        'samedi  1 janvier 2000 à 00:00:00',
      );
    } finally {
      timeFormatDefaultLocale(timeLocaleEnUS);
    }
  });

  test('timeFormatDefaultLocale(definition) affects timeParse', () {
    final locale = timeFormatDefaultLocale(timeLocaleFrFR);
    try {
      expect(identical(defaultTimeLocale, locale), isTrue);
      expect(
        timeParse('%c')('samedi  1 janvier 2000 à 00:00:00')
            ?.millisecondsSinceEpoch,
        DateTime(2000).millisecondsSinceEpoch,
      );
    } finally {
      timeFormatDefaultLocale(timeLocaleEnUS);
    }
  });

  test('timeFormatDefaultLocale(definition) affects utcFormat', () {
    final locale = timeFormatDefaultLocale(timeLocaleFrFR);
    try {
      expect(identical(defaultTimeLocale, locale), isTrue);
      expect(
        utcFormat('%c')(DateTime.utc(2000)),
        'samedi  1 janvier 2000 à 00:00:00',
      );
    } finally {
      timeFormatDefaultLocale(timeLocaleEnUS);
    }
  });

  test('timeFormatDefaultLocale(definition) affects utcParse', () {
    final locale = timeFormatDefaultLocale(timeLocaleFrFR);
    try {
      expect(identical(defaultTimeLocale, locale), isTrue);
      expect(
        utcParse('%c')('samedi  1 janvier 2000 à 00:00:00')
            ?.millisecondsSinceEpoch,
        DateTime.utc(2000).millisecondsSinceEpoch,
      );
    } finally {
      timeFormatDefaultLocale(timeLocaleEnUS);
    }
  });
}
