// Original code, not ported from Chart.js: the tests of the DartPad archives.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/dartpad_archives.dart' as archives;

void main() {
  final docs = Directory.current;

  test('each sample becomes one file with its main function', () {
    final versions = archives.PackageVersions.read(docs);
    final paths = archives.samplePaths(docs);
    expect(
      paths.where((path) => path.startsWith('lib/examples/')),
      hasLength(53),
    );
    expect(
      paths.where((path) => path.startsWith('lib/migrate/')),
      hasLength(82),
    );
    for (final path in paths) {
      final source = archives.bundle(docs, path);
      expect(source, isNot(contains('package:chartjs_docs/')), reason: path);
      expect(source, isNot(contains('#docregion')), reason: path);
      expect(source, contains('\nvoid main() {'), reason: path);
      expect(
        archives.pubspec(source, versions),
        contains('  flutter_chartjs_port: ^${versions.port}\n'),
        reason: path,
      );
    }
  });

  test('a replica gets the declarations of its kit that it uses', () {
    final source = archives.bundle(docs, 'lib/migrate/fl_chart/s03.dart');
    expect(
      source,
      contains(
        '// The code that this sample uses from '
        'lib/migrate/fl_chart/fl_kit.dart.',
      ),
    );
    expect(source, contains('abstract final class Fl('));
  });

  test('a replica that reads an asset reads it from the docs site', () {
    final source = archives.bundle(docs, 'lib/migrate/fl_chart/s12.dart');
    expect(source, isNot(contains('rootBundle')));
    expect(source, contains("import 'package:http/http.dart' as http;"));
    expect(source, contains("Uri.parse('${archives.docsSite}/assets/\$key')"));
  });

  test('a unit ends at its semicolon or at the brace of its body', () {
    const source = r'''
import 'a.dart';

/// A doc comment with a { brace.
const a = {'x': '}'};
ScaleHook reserve(double size) => (scale) {
  scale.height = size;
};
class const B() {
  String get s => '${a.length} }';
}
typedef F = void Function();
''';
    expect(
      [
        for (final unit in archives.splitUnits(source))
          archives.Unit(unit).name,
      ],
      [null, 'a', 'reserve', 'B', 'F'],
    );
  });
}
