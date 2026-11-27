// Original code, not ported from d3-time-format: verifies all 34 const locales.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_d3_time_format_port/d3_time_format.dart';
import 'package:test/test.dart';

Directory? _repositoryRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File('${dir.path}/.gitmodules').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) return null;
    dir = parent;
  }
}

void main() {
  final root = _repositoryRoot();
  final localeDir = root == null
      ? null
      : Directory('${root.path}/third_party/d3-time-format/locale');

  test(
    'every const locale matches its upstream JSON definition field-for-field',
    () {
      final files =
          localeDir!
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.json'))
              .toList()
            ..sort(
              (a, b) =>
                  a.uri.pathSegments.last.compareTo(b.uri.pathSegments.last),
            );
      expect(timeFormatLocales.length, files.length);
      for (final file in files) {
        final name = file.uri.pathSegments.last;
        final tag = name.substring(0, name.length - 5);
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
        final fromJson = TimeLocaleDefinition.fromJson(json);
        final actual = timeFormatLocales[tag];
        expect(actual, isNotNull, reason: 'missing $tag');
        expect(actual!.dateTime, fromJson.dateTime, reason: '$tag.dateTime');
        expect(actual.date, fromJson.date, reason: '$tag.date');
        expect(actual.time, fromJson.time, reason: '$tag.time');
        expect(actual.periods, fromJson.periods, reason: '$tag.periods');
        expect(actual.days, fromJson.days, reason: '$tag.days');
        expect(actual.shortDays, fromJson.shortDays, reason: '$tag.shortDays');
        expect(actual.months, fromJson.months, reason: '$tag.months');
        expect(
          actual.shortMonths,
          fromJson.shortMonths,
          reason: '$tag.shortMonths',
        );
      }
    },
    skip: localeDir == null
        ? 'not inside the flutter_ports repository'
        : localeDir.existsSync()
        ? false
        : '${localeDir.path} is missing.',
  );
}
