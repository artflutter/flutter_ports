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
      expect(sources.map((s) => s.header), ['Chart.js', 'chartjs-test-utils']);
      expect(sources.map((s) => s.language), ['js', 'js']);
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
        sources[1].dartPathOf('src/utils.js'),
        'packages/chartjs_test_utils/lib/src/utils.dart',
      );
      // A commit pin links its full commit, a tag pin its tag.
      expect(chartJs.isCommitPin, chartJs.version.contains('+'));
      expect(
        chartJs.treeRef,
        chartJs.isCommitPin ? chartJs.pinCommit : chartJs.version,
      );
      expect(sources[1].treeRef, sources[1].version);
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

  group('parsePortSourcesFile', () {
    const entry = [
      'sources:',
      '  - header: a',
      '    version: "v1.0.0"',
      '    version_source: aVersion in packages/a/lib/src/upstream.dart',
      '    url: https://github.com/o/a-b.c',
      '    language: js',
      '    spdx: MIT',
      '    holder: A',
      '    pin:',
      '      kind: copy',
      '      path: third_party/a',
      '    targets:',
      '      - source: a.js',
      '        dart: packages/a/lib/a.dart',
    ];

    Matcher throwsMessage(String message) => throwsA(
      isA<FormatException>().having((e) => e.message, 'message', message),
    );

    test('reads the marker tag and the host', () {
      final plain = parsePortSourcesFile(entry.join('\n'));
      expect(plain.marker, 'chartjs');
      expect(plain.host, isNull);
      expect(plain.sources.single.header, 'a');
      final addOn = parsePortSourcesFile(
        ['marker: zoom', 'host: flutter_chartjs_port', ...entry].join('\n'),
      );
      expect(addOn.marker, 'zoom');
      expect(addOn.host, 'flutter_chartjs_port');
      expect(parsePortSources([...entry, 'marker: x-1'].join('\n')), [
        isA<PortSource>(),
      ]);
    });

    test('rejects bad top-level keys', () {
      expect(
        () => parsePortSourcesFile(['markers: zoom', ...entry].join('\n')),
        throwsMessage(
          'the top-level key "markers" is not one of sources, marker, host',
        ),
      );
      for (final marker in ['Zoom', '1x', 'a_b', '"a b"']) {
        expect(
          () => parsePortSourcesFile(['marker: $marker', ...entry].join('\n')),
          throwsMessage(
            '"marker" is a tag of lowercase letters, digits and hyphens',
          ),
          reason: marker,
        );
      }
      expect(
        () => parsePortSourcesFile(['host: a-b', ...entry].join('\n')),
        throwsMessage('"host" is the name of a package'),
      );
      expect(
        () => parsePortSourcesFile(['host:', '  - a', ...entry].join('\n')),
        throwsMessage('"host" is the name of a package'),
      );
    });

    test('reads the version constant and the repository of an entry', () {
      final source = parsePortSources(entry.join('\n')).single;
      expect(source.versionSource, startsWith('aVersion in '));
      expect(source.versionConstantIn('packages/a'), 'aVersion');
      expect(source.versionConstantIn('packages'), isNull);
      expect(source.versionConstantIn('packages/b'), isNull);
      expect(source.repository, 'o/a-b.c');
      PortSource other(String versionSource, String url) => parsePortSources(
        [
          for (final line in entry)
            if (line.startsWith('    version_source:'))
              '    version_source: $versionSource'
            else if (line.startsWith('    url:'))
              '    url: $url'
            else
              line,
        ].join('\n'),
      ).single;
      expect(
        other(
          'the a v1 package.json in packages/a/lib/src/upstream.dart',
          'https://www.netlib.org/fdlibm/',
        ).versionConstantIn('packages/a'),
        isNull,
      );
      // A URL with one path segment names no repository.
      expect(other('x', 'https://www.netlib.org/fdlibm/').repository, isNull);
      expect(other('x', 'https://example.com/a/b/c').repository, 'a/b');
    });

    test('reads the source lists of the repository', () {
      final host = parsePortSourcesFile(
        File('tool/port_sources.yaml').readAsStringSync(),
      );
      expect(host.marker, 'chartjs');
      expect(host.host, isNull);
      expect(
        host.sources.map(
          (s) => s.versionConstantIn('packages/flutter_chartjs_port'),
        ),
        ['chartJsVersion', null],
      );
      expect(host.sources.first.repository, 'chartjs/Chart.js');

      const zoomPackage = 'packages/flutter_chartjs_plugin_zoom_port';
      final zoom = parsePortSourcesFile(
        File('../flutter_chartjs_plugin_zoom_port/tool/port_sources.yaml')
            .readAsStringSync(),
      );
      expect(zoom.marker, 'zoom');
      expect(zoom.host, 'flutter_chartjs_port');
      final source = zoom.sources.single;
      expect(source.versionConstantIn(zoomPackage), 'chartjsPluginZoomVersion');
      expect(source.repository, 'chartjs/chartjs-plugin-zoom');
      expect(
        {
          for (final path in [
            'src/utils.ts',
            'src/index.umd.ts',
            'src/utils.test.ts',
            'src/scale.types.test.ts',
            'test/specs/zoom.wheel.spec.js',
            'test/fixtures/zoom/category.js',
            'test/index.js',
          ])
            path: source.dartPathOf(path),
        },
        {
          'src/utils.ts': '$zoomPackage/lib/src/utils.dart',
          'src/index.umd.ts': '$zoomPackage/lib/src/index.umd.dart',
          'src/utils.test.ts': '$zoomPackage/test/specs/utils_test.dart',
          'src/scale.types.test.ts':
              '$zoomPackage/test/specs/scale.types_test.dart',
          'test/specs/zoom.wheel.spec.js':
              '$zoomPackage/test/specs/zoom.wheel_test.dart',
          'test/fixtures/zoom/category.js':
              '$zoomPackage/test/fixtures/hand/zoom/category.dart',
          'test/index.js': '$zoomPackage/test/flutter_test_config.dart',
        },
      );

      const colorPackage = 'packages/flutter_kurkle_color_port';
      final color = parsePortSourcesFile(
        File('../flutter_kurkle_color_port/tool/port_sources.yaml')
            .readAsStringSync(),
      );
      expect(color.marker, 'kurkle');
      expect(color.host, isNull);
      final kurkle = color.sources.single;
      expect(kurkle.header, '@kurkle/color');
      expect(kurkle.versionConstantIn(colorPackage), 'kurkleColorVersion');
      expect(kurkle.dartPathOf('src/hue.js'), '$colorPackage/lib/src/hue.dart');
      expect(
        kurkle.dartPathOf('packed.js'),
        '$colorPackage/lib/src/packed.dart',
      );
      expect(
        kurkle.dartPathOf('test/index.js'),
        '$colorPackage/test/index_test.dart',
      );
    });
  });

  group('targetPackages', () {
    test('lists the packages of the dart targets in order', () {
      final root = posixPath(Directory.systemTemp.createTempSync('pc_').path);
      addTearDown(() => Directory(root).deleteSync(recursive: true));
      for (final package in ['packages/a', 'packages/b', 'packages/a/c']) {
        File('$root/$package/pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('name: x\n');
      }
      final sources = parsePortSources(
        [
          'sources:',
          '  - header: a',
          '    version: "1.0"',
          '    url: https://example.com/a',
          '    language: js',
          '    spdx: MIT',
          '    holder: A',
          '    pin:',
          '      kind: copy',
          '      path: third_party/a',
          '    targets:',
          '      - source: b/',
          '        dart: packages/b/lib/src/',
          '      - source: a.js',
          '        dart: packages/a/lib/missing/a.dart',
          '      - source: c/',
          '        dart: packages/a/c/',
          '      - source: d.js',
          '        dart: packages/b/test/d_test.dart',
          '      - source: e.js',
          '        dart: other/e.dart',
        ].join('\n'),
      );
      expect(targetPackages(root, sources), [
        '$root/packages/b',
        '$root/packages/a',
        '$root/packages/a/c',
      ]);
    });
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
      expect(
        const PortTarget('test/specs/', 't/').map('test/specs/a.b.spec.js'),
        't/a.b_test.dart',
      );
      // A unit test of src/ has a file target: the directory target maps
      // only the extension.
      expect(target.map('src/a.test.ts'), 'packages/p/lib/src/a.test.dart');
      expect(target.map('test/index.js'), isNull);
      expect(const PortTarget('a.c', 'x.dart').map('a.c'), 'x.dart');
      expect(const PortTarget('a.c', 'x.dart').map('b.c'), isNull);
    });

    test('lists the sources of a Dart path', () {
      expect(target.sourcesOf('packages/p/lib/src/types/geometric.dart'), [
        'src/types/geometric.js',
        'src/types/geometric.ts',
        'src/types/geometric.d.ts',
        'src/types/geometric.json',
      ]);
      expect(
        const PortTarget('test/specs/', 't/').sourcesOf('t/a.b_test.dart'),
        containsAll(['test/specs/a.b.tests.js', 'test/specs/a.b.spec.js']),
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
