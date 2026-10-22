// Original code, not ported from Chart.js: tests of the YAML and TOML readers.
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

import '../../tool/src/check_support.dart';
import '../../tool/src/mini_yaml.dart';
import '../../tool/src/port_headers.dart';
import '../../tool/src/reuse_toml.dart';

void main() {
  group('parseYamlSubset', () {
    test('reads mappings, sequences and scalars', () {
      final document = parseYamlSubset(r'''
# A comment.
sources:
  - header: "@kurkle/color" # A trailing comment.
    version: "5.3"
    holder: Sun Microsystems, Inc.
    url: https://example.com/a#b
    pin:
      kind: copy
    files:
      - a.c
      - 'it''s.c'
    empty:
  - plain
list:
- one
- "two\tthree"
''');
      expect(document, {
        'sources': [
          {
            'header': '@kurkle/color',
            'version': '5.3',
            'holder': 'Sun Microsystems, Inc.',
            'url': 'https://example.com/a#b',
            'pin': {'kind': 'copy'},
            'files': ['a.c', "it's.c"],
            'empty': null,
          },
          'plain',
        ],
        'list': ['one', 'two\tthree'],
      });
    });

    test('reads an empty document', () {
      expect(parseYamlSubset('# only a comment\n'), isNull);
    });

    test('rejects YAML outside the subset', () {
      for (final text in [
        'a: [1, 2]\n',
        'a: >-\n  folded\n',
        'a: 1\na: 2\n',
        'a:\n  b: 1\n   c: 2\n',
        'a:\n\t- b\n',
        'a: b: c\n',
        '---\na: 1\n',
        'a: "open\n',
      ]) {
        expect(
          () => parseYamlSubset(text),
          throwsFormatException,
          reason: text,
        );
      }
    });

    test('reads tool/port_sources.yaml', () {
      final sources = parsePortSources(
        File('tool/port_sources.yaml').readAsStringSync(),
      );
      expect(sources.map((s) => s.header), [
        'Chart.js',
        'fdlibm',
        '@kurkle/color',
        'chartjs-test-utils',
      ]);
      expect(sources.map((s) => s.language), ['js', 'c', 'js', 'js']);
      final chartJs = sources.first;
      expect(
        chartJs.dartPathOf('src/helpers/helpers.math.ts'),
        'packages/flutter_chartjs_port/lib/src/helpers/helpers.math.dart',
      );
      expect(
        chartJs.dartPathOf('test/specs/helpers.math.tests.js'),
        'packages/flutter_chartjs_port/test/specs/helpers.math_test.dart',
      );
      expect(
        chartJs.dartPathOf('test/index.js'),
        'packages/flutter_chartjs_port/test/flutter_test_config.dart',
      );
      expect(
        sources[1].dartPathOf('e_atan2.c'),
        'packages/flutter_chartjs_port/lib/src/js/fdlibm_atan.dart',
      );
      expect(
        sources[1].dartPathOf('s_sin.c'),
        'packages/flutter_chartjs_port/lib/src/js/fdlibm_trig.dart',
      );
      expect(
        sources[3].dartPathOf('src/utils.js'),
        'packages/chartjs_test_utils/lib/src/utils.dart',
      );
      // A commit pin links its full commit, a tag pin its tag.
      expect(chartJs.isCommitPin, chartJs.version.contains('+'));
      expect(
        chartJs.treeRef,
        chartJs.isCommitPin ? chartJs.pinCommit : chartJs.version,
      );
      expect(sources[2].treeRef, sources[2].version);
    });
  });

  test('parsePortSources needs a known language', () {
    String source(String language) => [
      'sources:',
      '  - header: a',
      '    version: "1.0"',
      '    url: https://example.com/a',
      if (language.isNotEmpty) '    language: $language',
      '    spdx: MIT',
      '    holder: A',
      '    pin:',
      '      kind: copy',
      '      path: third_party/a',
      '    targets:',
      '      - source: a.js',
      '        dart: lib/a.dart',
    ].join('\n');
    expect(parsePortSources(source('js')).single.isJs, isTrue);
    expect(parsePortSources(source('c')).single.isJs, isFalse);
    expect(
      () => parsePortSources(source('ts')),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'a: language is "js" or "c"',
        ),
      ),
    );
    expect(
      () => parsePortSources(source('')),
      throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          'a: "language" is missing',
        ),
      ),
    );
  });

  group('PortTarget', () {
    const target = PortTarget('src/', 'packages/p/lib/src/');

    test('maps the upstream file names of porting-flow.md 2.5', () {
      expect(
        target.map('src/types/geometric.d.ts'),
        endsWith('/geometric.dart'),
      );
      expect(
        target.map('src/controllers/controller.polarArea.js'),
        'packages/p/lib/src/controllers/controller.polarArea.dart',
      );
      expect(
        target.map('src/plugins/plugin.filler/filler.drawing.js'),
        'packages/p/lib/src/plugins/plugin.filler/filler.drawing.dart',
      );
      expect(
        const PortTarget('test/specs/', 't/').map('test/specs/a.b.tests.js'),
        't/a.b_test.dart',
      );
      expect(target.map('test/index.js'), isNull);
      expect(const PortTarget('a.c', 'x.dart').map('a.c'), 'x.dart');
      expect(const PortTarget('a.c', 'x.dart').map('b.c'), isNull);
    });

    test('lists the sources of a Dart path', () {
      expect(target.sourcesOf('packages/p/lib/src/types/geometric.dart'), [
        'src/types/geometric.js',
        'src/types/geometric.ts',
        'src/types/geometric.d.ts',
      ]);
      expect(
        const PortTarget('test/specs/', 't/').sourcesOf('t/a.b_test.dart'),
        contains('test/specs/a.b.tests.js'),
      );
      expect(target.sourcesOf('packages/p/lib/a.dart'), isEmpty);
      expect(target.sourcesOf('packages/p/lib/src/a.txt'), isEmpty);
      expect(const PortTarget('a.c', 'x.dart').sourcesOf('x.dart'), ['a.c']);
      expect(const PortTarget('a.c', 'x.dart').sourcesOf('y.dart'), isEmpty);
    });
  });

  group('versions', () {
    test('compare as numbers', () {
      expect(parseVersion('v4.5.1'), [4, 5, 1]);
      expect(parseVersion('5.3'), [5, 3]);
      expect(parseVersion('4.5.1+7169e651'), isNull);
      expect(compareVersions([4, 5, 0], [4, 5, 1]), isNegative);
      expect(compareVersions([4, 10], [4, 9, 9]), isPositive);
      expect(compareVersions([5, 3], [5, 3, 0]), 0);
    });

    test('read a commit pin as a release and a commit', () {
      final pin = parsePortVersion('v4.5.1+7169e651')!;
      expect(pin.release, [4, 5, 1]);
      expect(pin.commit, '7169e651');
      expect(parsePortVersion('4.5.1')!.commit, isNull);
      expect(parsePortVersion('5.3')!.release, [5, 3]);
      for (final bad in [
        'v4.5.1+7169e65',
        'v4.5.1+7169e6510',
        'v4.5.1+7169E651',
        'v4.5.1+',
        '+7169e651',
        'v4.5.1-beta',
      ]) {
        expect(parsePortVersion(bad), isNull, reason: bad);
      }
    });

    test('put a commit pin after its release', () {
      int? compare(String a, String b) =>
          comparePortVersions(parsePortVersion(a)!, parsePortVersion(b)!);
      expect(compare('v4.5.1', 'v4.5.1+7169e651'), isNegative);
      expect(compare('v4.5.1+7169e651', 'v4.5.1'), isPositive);
      expect(compare('v4.5.1+7169e651', 'v4.5.1+7169e651'), 0);
      expect(compare('v4.5.1+7169e651', 'v4.6.0'), isNegative);
      expect(compare('v4.4.9', 'v4.5.1+7169e651'), isNegative);
      expect(compare('v4.6.0', 'v4.5.1+7169e651'), isPositive);
      // Two commits of one release have no order without the history.
      expect(compare('v4.5.1+2898a6d1', 'v4.5.1+7169e651'), isNull);
    });
  });

  group('parseReuseToml', () {
    const text = '''
version = 1
SPDX-PackageName = "p" # comment

# A comment.
[[annotations]]
path = "**"
SPDX-FileCopyrightText = "2026 A"
SPDX-License-Identifier = "MIT"

[[annotations]]
path = [
  "lib/*.dart", # comment
  'lib/src/**',
]
precedence = "aggregate"
SPDX-FileCopyrightText = ["1993 Sun Microsystems, Inc.", "2026 A"]
SPDX-License-Identifier = "SunPro AND (MIT OR ISC)"
''';

    test('reads the annotations', () {
      final annotations = parseReuseToml(text);
      expect(annotations.map((a) => a.line), [5, 10]);
      expect(annotations.last.paths, ['lib/*.dart', 'lib/src/**']);
      expect(annotations.last.copyrights, [
        '1993 Sun Microsystems, Inc.',
        '2026 A',
      ]);
      expect(annotations.last.licenseIds, {'SunPro', 'MIT', 'ISC'});
    });

    test('applies the last annotation that matches', () {
      final annotations = parseReuseToml(text);
      expect(annotationFor(annotations, 'lib/a.dart')?.line, 10);
      expect(annotationFor(annotations, 'lib/src/x/y.dart')?.line, 10);
      expect(annotationFor(annotations, 'lib/x/y.dart')?.line, 5);
      expect(annotationFor(const [], 'a'), isNull);
    });

    test('rejects TOML outside the subset', () {
      expect(() => parseReuseToml('a = "open\n'), throwsFormatException);
      expect(() => parseReuseToml('a = [1 2]\n'), throwsFormatException);
      expect(() => parseReuseToml('a = """x"""\n'), throwsFormatException);
    });

    test('reads the repository REUSE.toml', () {
      final annotations = parseReuseToml(
        File('../../REUSE.toml').readAsStringSync(),
      );
      final ported = annotationFor(
        annotations,
        'packages/flutter_chartjs_port/lib/src/helpers/helpers.math.dart',
      );
      expect(ported?.copyrights, contains(contains('Chart.js Contributors')));
      final fdlibm = annotationFor(
        annotations,
        'packages/flutter_chartjs_port/lib/src/js/fdlibm_log.dart',
      );
      expect(fdlibm?.licenseIds, containsAll(['SunPro', 'MIT']));
      final harness = annotationFor(
        annotations,
        'packages/chartjs_test_utils/lib/pure.dart',
      );
      expect(
        harness?.copyrights,
        containsAll([
          contains('chartjs-test-utils Contributors'),
          contains('Vasiliy Ditsyak'),
        ]),
      );
      expect(harness?.licenseIds, ['MIT']);
    });
  });

  group('globToRegExp', () {
    test('follows the REUSE glob rules', () {
      expect(globToRegExp('a/*.dart').hasMatch('a/b.dart'), isTrue);
      expect(globToRegExp('a/*.dart').hasMatch('a/b/c.dart'), isFalse);
      expect(globToRegExp('a/**').hasMatch('a/b/c.dart'), isTrue);
      expect(globToRegExp(r'a\*.c').hasMatch('a*.c'), isTrue);
      expect(globToRegExp(r'a\*.c').hasMatch('ab.c'), isFalse);
      expect(globToRegExp('a.c').hasMatch('abc'), isFalse);
    });
  });
}
