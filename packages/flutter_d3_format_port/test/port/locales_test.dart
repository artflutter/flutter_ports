// Original code, not ported from d3-format: verifies all 59 const locales.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_d3_format_port/d3_format.dart';
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
      : Directory('${root.path}/third_party/d3-format/locale');

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
      expect(formatLocales.length, files.length);
      for (final file in files) {
        final name = file.uri.pathSegments.last;
        final tag = name.substring(0, name.length - 5);
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
        final fromJson = FormatLocaleDefinition.fromJson(json);
        final actual = formatLocales[tag];
        expect(actual, isNotNull, reason: 'missing $tag');
        expect(actual!.decimal, fromJson.decimal, reason: '$tag.decimal');
        expect(actual.thousands, fromJson.thousands, reason: '$tag.thousands');
        expect(actual.grouping, fromJson.grouping, reason: '$tag.grouping');
        expect(actual.currency, fromJson.currency, reason: '$tag.currency');
        expect(actual.numerals, fromJson.numerals, reason: '$tag.numerals');
        expect(actual.percent, fromJson.percent, reason: '$tag.percent');
        expect(actual.minus, fromJson.minus, reason: '$tag.minus');
        expect(actual.nan, fromJson.nan, reason: '$tag.nan');
      }
    },
    skip: localeDir == null
        ? 'not inside the flutter_ports repository'
        : localeDir.existsSync()
        ? false
        : '${localeDir.path} is missing.',
  );
}
