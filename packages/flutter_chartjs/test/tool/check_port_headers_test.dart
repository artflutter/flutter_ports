// Original code, not ported from Chart.js: tests of tool 2, the header check.
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

import '../../tool/src/check_support.dart';
import '../../tool/src/port_headers.dart';
import 'file_tree.dart';

const String _package = 'packages/flutter_chartjs';
const String _portOnly = '// Original code, not ported from Chart.js: a test.';
const String _chartJsCommit = '9c5cf9fac7ec04a71b516e2aff3f7d76876be369';

/// The commit pin of upstream-tracking.md 2.4.
const String _pinCommit = '7169e65147a47f3720957a6f156a33c838ab9f57';
const String _pinVersion = 'v4.5.1+7169e651';

String _chartJs(String path, {String version = 'v4.5.1'}) =>
    '// Ported from Chart.js $version $path (MIT, Chart.js Contributors).';

String _fdlibm(String path) =>
    '// Ported from fdlibm 5.3 $path (SunPro, Sun Microsystems, Inc.).';

String _header(String project, String version, String path, String rest) =>
    '// Ported from $project $version $path ($rest).';

String _parityRow(String path, {String tree = 'v4.5.1'}) =>
    '| [`$path`](https://github.com/chartjs/Chart.js/blob/$tree/$path) | 1 |';

/// An error in [message], which starts with a path in the package.
String _error(String message) => 'error: $_package/$message';

/// A warning in [message], which starts with a path in the package.
String _warning(String message) => 'warning: $_package/$message';

const String _chartJsCopyright =
    'SPDX-FileCopyrightText = ["2014-2024 Chart.js Contributors", "2026 A"]';

const String _testUtilsCopyright =
    'SPDX-FileCopyrightText = '
    '["2020 chartjs-test-utils Contributors", "2026 A"]';

const List<String> _portSources = [
  'sources:',
  '  - header: Chart.js',
  '    version: "v4.5.1"',
  '    url: https://github.com/chartjs/Chart.js',
  '    language: js',
  '    spdx: MIT',
  '    holder: Chart.js Contributors',
  '    pin:',
  '      kind: submodule',
  '      path: third_party/Chart.js',
  '      ref: "v4.5.1"',
  '      commit: $_chartJsCommit',
  '    targets:',
  '      - source: src/',
  '        dart: $_package/lib/src/',
  '      - source: test/specs/',
  '        dart: $_package/test/specs/',
  '      - source: test/index.js',
  '        dart: $_package/test/flutter_test_config.dart',
  '    files:',
  '      - test/index.js',
  '    file_index: $_package/doc/parity.md',
  '  - header: fdlibm',
  '    version: "5.3"',
  '    url: https://www.netlib.org/fdlibm/',
  '    language: c',
  '    spdx: SunPro',
  '    holder: Sun Microsystems, Inc.',
  '    pin:',
  '      kind: copy',
  '      path: third_party/fdlibm',
  '    targets:',
  '      - source: e_log.c',
  '        dart: $_package/lib/src/js/fdlibm_log.dart',
  '      - source: e_log10.c',
  '        dart: $_package/lib/src/js/fdlibm_log.dart',
  '    files:',
  '      - e_log.c',
];

/// [_portSources] with the Chart.js [version], [ref] and [commit].
List<String> _chartJsPin({
  required String version,
  required String ref,
  required String commit,
}) => [
  for (final line in _portSources)
    switch (line) {
      '    version: "v4.5.1"' => '    version: "$version"',
      '      ref: "v4.5.1"' => '      ref: "$ref"',
      '      commit: $_chartJsCommit' => '      commit: $commit',
      _ => line,
    },
];

void main() {
  late FileTree tree;
  String? gitlink;
  String? head;

  setUp(() {
    gitlink = null;
    head = null;
    tree = FileTree()
      ..write('REUSE.toml', [
        'version = 1',
        '[[annotations]]',
        'path = "$_package/**"',
        _chartJsCopyright,
        'SPDX-License-Identifier = "MIT"',
        '[[annotations]]',
        'path = "$_package/lib/src/js/fdlibm_*.dart"',
        'SPDX-FileCopyrightText = ["1993 Sun Microsystems, Inc.", "2026 A"]',
        'SPDX-License-Identifier = "SunPro AND MIT"',
      ])
      ..write('third_party/Chart.js/src/helpers/helpers.math.ts', ['//'])
      ..write('third_party/Chart.js/src/types/geometric.d.ts', ['//'])
      ..write('third_party/Chart.js/test/specs/helpers.math.tests.js', ['//'])
      ..write('third_party/Chart.js/test/index.js', ['//'])
      ..write('third_party/fdlibm/e_log.c', ['/* */'])
      ..write('third_party/fdlibm/e_log10.c', ['/* */'])
      ..write('$_package/pubspec.yaml', ['name: flutter_chartjs'])
      ..write('$_package/LICENSE', [
        'Copyright (c) 2014-2024 Chart.js Contributors',
        'Copyright (C) 1993 by Sun Microsystems, Inc.',
      ])
      ..write('$_package/tool/port_sources.yaml', _portSources)
      ..write('$_package/doc/parity.md', [
        _parityRow('src/helpers/helpers.math.ts'),
        _parityRow('test/specs/helpers.math.tests.js'),
      ])
      ..write('$_package/lib/src/upstream.dart', [
        _portOnly,
        "const String chartJsVersion = '4.5.1';",
      ])
      ..write('$_package/lib/src/helpers/helpers.math.dart', [
        _chartJs('src/helpers/helpers.math.ts'),
        '// Upstream backport: chartjs/Chart.js@2898a6d1 (#12142).',
        '',
        '// A comment, not a header line: Ported from here on.',
        "const s = '''",
        _chartJs('src/a.ts'),
        "''';",
      ])
      ..write('$_package/lib/src/types/geometric.dart', [
        _chartJs('src/types/geometric.d.ts'),
      ])
      ..write('$_package/lib/src/js/fdlibm_log.dart', [
        _fdlibm('e_log.c'),
        _fdlibm('e_log10.c'),
      ])
      ..write('$_package/test/specs/helpers.math_test.dart', [
        _chartJs('test/specs/helpers.math.tests.js'),
      ])
      ..write('$_package/test/flutter_test_config.dart', [
        _chartJs('test/index.js'),
      ])
      ..write('$_package/test/port/a_test.dart', [_portOnly])
      ..write('$_package/tool/check.dart', [_portOnly]);
  });

  ({List<Finding> findings, int files}) check() => checkPortHeaders(
    HeaderCheckInput(
      repository: tree.root,
      home: tree.path(_package),
      packages: [tree.path(_package)],
      gitlink: (_, path) => path == 'third_party/Chart.js' ? gitlink : null,
      checkoutHead: (directory) =>
          directory.endsWith('/third_party/Chart.js') ? head : null,
    ),
  );

  List<String> run() => describeFindings(check().findings);

  void replaceFile(String path, List<String> lines) =>
      tree.write('$_package/$path', lines);

  test('passes a tree that keeps the rules', () {
    expect(run(), isEmpty);
    expect(check().files, 8);
  });

  group('line 1', () {
    test('is a header or the port-only marker', () {
      replaceFile('lib/a.dart', ['/// Docs.']);
      replaceFile('lib/b.dart', [
        '// Original code, not ported from Chart.js: no full stop',
      ]);
      expect(run(), [
        startsWith(_error('lib/a.dart:1: line 1 is neither')),
        startsWith(_error('lib/b.dart:1: line 1 is neither')),
      ]);
    });

    test('is not the port-only marker at the Dart path of a source', () {
      replaceFile('lib/src/types/geometric.dart', [_portOnly]);
      replaceFile('test/flutter_test_config.dart', [_portOnly]);
      replaceFile('test/specs/helpers.math_test.dart', [_portOnly]);
      // No source exists at the pin for these paths.
      replaceFile('lib/src/helpers/helpers.color.dart', [_portOnly]);
      replaceFile('lib/flutter_chartjs.dart', [_portOnly]);
      const message =
          ': start it with its "// Ported from" header, not the port-only '
          'marker.';
      expect(run(), [
        _error(
          'lib/src/types/geometric.dart:1: the file is at the Dart path of '
          'Chart.js src/types/geometric.d.ts$message',
        ),
        _error(
          'test/flutter_test_config.dart:1: the file is at the Dart path of '
          'Chart.js test/index.js$message',
        ),
        _error(
          'test/specs/helpers.math_test.dart:1: the file is at the Dart path '
          'of Chart.js test/specs/helpers.math.tests.js$message',
        ),
      ]);
    });

    test('is port-only under test/port/ and tool/', () {
      replaceFile('test/port/a_test.dart', [
        _chartJs('src/helpers/helpers.math.ts'),
      ]);
      replaceFile('tool/check.dart', [_chartJs('src/helpers/helpers.math.ts')]);
      const message =
          ':1: files under test/port/ and tool/ are port-only: start the '
          'file with the port-only marker.';
      expect(
        run(),
        containsAll([
          _error('test/port/a_test.dart$message'),
          _error('tool/check.dart$message'),
        ]),
      );
    });
  });

  group('header block', () {
    test('rejects malformed and misplaced header lines', () {
      replaceFile('lib/src/types/geometric.dart', [
        _chartJs('src/types/geometric.d.ts'),
        '// Upstream backport: chartjs/Chart.js@2898a6d (#12142).',
        '',
        _chartJs('src/types/geometric.d.ts'),
        'void f() {} // Upstream backport: chartjs/Chart.js@2898a6d1 (#1).',
      ]);
      const misplaced =
          ': a header line outside the header block: header lines come '
          'directly after line 1.';
      expect(run(), [
        _error(
          'lib/src/types/geometric.dart:2: the header line does not match '
          'the grammar of porting-flow.md 4, tool 2.',
        ),
        _error('lib/src/types/geometric.dart:4$misplaced'),
        _error('lib/src/types/geometric.dart:5$misplaced'),
      ]);
    });

    test('reports a malformed line 1 once', () {
      replaceFile('lib/src/types/geometric.dart', [
        '// Ported from Chart.js v4.5.1 src/types/geometric.d.ts (MIT).',
      ]);
      expect(run(), [
        _error(
          'lib/src/types/geometric.dart:1: the header line does not match '
          'the grammar of porting-flow.md 4, tool 2.',
        ),
        startsWith(_error('lib/src/types/geometric.dart:1: line 1 is neither')),
      ]);
    });

    test('needs a Chart.js line for a backport line', () {
      replaceFile('lib/src/js/fdlibm_log.dart', [
        _fdlibm('e_log.c'),
        '// Upstream backport: chartjs/Chart.js@2898a6d1 (#12142).',
      ]);
      expect(run(), [
        _error(
          'lib/src/js/fdlibm_log.dart:2: a backport line needs a '
          '"// Ported from Chart.js" line.',
        ),
      ]);
    });
  });

  group('project, license and holder', () {
    test('agree with port_sources.yaml', () {
      replaceFile('lib/src/types/geometric.dart', [
        _header('Chart.js', 'v4.5.1', 'src/types/geometric.d.ts', 'ISC, A'),
        _header('moment', '2.29.4', 'src/moment.js', 'MIT, JS Foundation'),
      ]);
      expect(run(), [
        _error(
          'lib/src/types/geometric.dart:1: the license is ISC, but '
          'tool/port_sources.yaml names MIT.',
        ),
        _error(
          'lib/src/types/geometric.dart:1: the holder is "A", but '
          'tool/port_sources.yaml names "Chart.js Contributors".',
        ),
        _error(
          'lib/src/types/geometric.dart:2: "moment" is not in '
          'tool/port_sources.yaml.',
        ),
      ]);
    });

    test('appear in the package LICENSE', () {
      tree.write('$_package/LICENSE', [
        'Copyright (c) 2014-2024 Chart.js Contributors',
      ]);
      const message =
          ': $_package/LICENSE does not name "Sun Microsystems, Inc.".';
      expect(run(), [
        _error('lib/src/js/fdlibm_log.dart:1$message'),
        _error('lib/src/js/fdlibm_log.dart:2$message'),
      ]);
    });

    test('appear in the last matching REUSE.toml annotation', () {
      tree.write('REUSE.toml', [
        '[[annotations]]',
        'path = "$_package/**"',
        _chartJsCopyright,
        'SPDX-License-Identifier = "MIT"',
        '[[annotations]]',
        'path = "$_package/lib/src/js/*.dart"',
        'SPDX-FileCopyrightText = "2026 A"',
        'SPDX-License-Identifier = "MIT"',
      ]);
      const annotation =
          ': the last REUSE.toml annotation that matches the file (line 5) '
          'does not list';
      expect(run(), [
        _error(
          'lib/src/js/fdlibm_log.dart:1$annotation "Sun '
          'Microsystems, Inc.".',
        ),
        _error('lib/src/js/fdlibm_log.dart:1$annotation SunPro.'),
        _error(
          'lib/src/js/fdlibm_log.dart:2$annotation "Sun '
          'Microsystems, Inc.".',
        ),
        _error('lib/src/js/fdlibm_log.dart:2$annotation SunPro.'),
      ]);

      tree.write('REUSE.toml', ['version = 1']);
      expect(
        run(),
        everyElement(endsWith('no REUSE.toml annotation matches the file.')),
      );
    });
  });

  group('source path', () {
    test('exists in the checked-out submodule', () {
      replaceFile('lib/src/helpers/helpers.color.dart', [
        _chartJs('src/helpers/helpers.color.ts'),
      ]);
      expect(run(), [
        _error(
          'lib/src/helpers/helpers.color.dart:1: '
          'src/helpers/helpers.color.ts does not exist in '
          'third_party/Chart.js.',
        ),
      ]);
    });

    test('is listed when the submodule is not checked out', () {
      // An uninitialized submodule is an empty directory.
      tree
        ..deleteDirectory('third_party/Chart.js')
        ..mkdir('third_party/Chart.js');
      expect(run(), [
        _error(
          'lib/src/types/geometric.dart:1: src/types/geometric.d.ts is not '
          'in the files of tool/port_sources.yaml or its file_index, and '
          'third_party/Chart.js is not checked out (dart run melos run '
          'upstream).',
        ),
      ]);
    });

    test('exists in a copy', () {
      tree.delete('third_party/fdlibm/e_log10.c');
      expect(run(), [
        _error(
          'lib/src/js/fdlibm_log.dart:2: e_log10.c does not exist in '
          'third_party/fdlibm.',
        ),
      ]);
    });

    test('is normalized', () {
      replaceFile('lib/src/types/geometric.dart', [
        _chartJs('src/types/../types/geometric.d.ts'),
      ]);
      expect(
        run(),
        contains(
          _error(
            'lib/src/types/geometric.dart:1: the source path '
            'src/types/../types/geometric.d.ts is not normalized.',
          ),
        ),
      );
    });
  });

  group('Dart path', () {
    test('equals the mapped path', () {
      replaceFile('lib/src/helpers/geometric.dart', [
        _chartJs('src/types/geometric.d.ts'),
      ]);
      replaceFile('test/specs/helpers_math_test.dart', [
        _chartJs('test/specs/helpers.math.tests.js'),
      ]);
      replaceFile('lib/src/js/fdlibm_x.dart', [_fdlibm('e_log.c')]);
      replaceFile('lib/src/js/js.dart', [_chartJs('docs/index.md')]);
      tree.write('third_party/Chart.js/docs/index.md', ['#']);
      const notThisFile = '(porting-flow.md 2.5), not this file.';
      expect(run(), [
        _error(
          'lib/src/helpers/geometric.dart:1: the Dart path of '
          'src/types/geometric.d.ts is '
          '$_package/lib/src/types/geometric.dart $notThisFile',
        ),
        _error(
          'lib/src/js/fdlibm_x.dart:1: the Dart path of e_log.c is '
          '$_package/lib/src/js/fdlibm_log.dart $notThisFile',
        ),
        _error(
          'lib/src/js/js.dart:1: no target of tool/port_sources.yaml maps '
          'docs/index.md.',
        ),
        _error(
          'test/specs/helpers_math_test.dart:1: the Dart path of '
          'test/specs/helpers.math.tests.js is '
          '$_package/test/specs/helpers.math_test.dart $notThisFile',
        ),
      ]);
    });
  });

  group('fixture configs', () {
    const fixture = 'test/fixtures/controller.bar/baseLine/mid-x.js';
    const hand =
        '$_package/test/fixtures/hand/controller.bar/baseLine/mid-x.dart';

    test('map to test/fixtures/hand/ in tool/port_sources.yaml', () {
      final chartJs = parsePortSources(
        File('tool/port_sources.yaml').readAsStringSync(),
      ).firstWhere((source) => source.header == 'Chart.js');
      expect(chartJs.dartPathOf(fixture), hand);
      final target = chartJs.targets.singleWhere(
        (target) => target.source == 'test/fixtures/',
      );
      expect(target.dart, '$_package/test/fixtures/hand/');
      // The candidates of a directory target: `.js` first, then `.ts` and
      // `.d.ts`. The check takes the one that exists at the pin.
      expect(target.sourcesOf(hand).first, fixture);
      expect(target.sourcesOf('$_package/test/fixtures/index.dart'), isEmpty);
    });

    test('pass the header check at the mapped path only', () {
      tree
        ..write('$_package/tool/port_sources.yaml', [
          for (final line in _portSources) ...[
            if (line == '      - source: test/index.js') ...[
              '      - source: test/fixtures/',
              '        dart: $_package/test/fixtures/hand/',
            ],
            line,
          ],
        ])
        ..write('third_party/Chart.js/$fixture', ['//']);
      replaceFile('test/fixtures/hand/controller.bar/baseLine/mid-x.dart', [
        _chartJs(fixture),
        '// ignore_for_file: file_names',
      ]);
      replaceFile('test/fixtures/index.dart', [_portOnly]);
      expect(run(), isEmpty);
      replaceFile('test/fixtures/hand/controller.bar/mid-x.dart', [
        _chartJs(fixture),
      ]);
      expect(run(), [
        _error(
          'test/fixtures/hand/controller.bar/mid-x.dart:1: the Dart path of '
          '$fixture is $hand (porting-flow.md 2.5), not this file.',
        ),
      ]);
    });
  });

  group('versions', () {
    const restamp = 'Restamp it (upstream-tracking.md 4.8).';

    test('report an older Chart.js header as stale', () {
      replaceFile('lib/src/types/geometric.dart', [
        _chartJs('src/types/geometric.d.ts', version: 'v4.4.9'),
      ]);
      final result = check();
      expect(describeFindings(result.findings), [
        _warning(
          'lib/src/types/geometric.dart:1: stale header: Chart.js v4.4.9 is '
          'older than v4.5.1 (chartJsVersion). $restamp',
        ),
      ]);
      expect(result.findings.single.isError, isFalse);
    });

    test('reject a newer or differently written version', () {
      replaceFile('lib/src/types/geometric.dart', [
        _chartJs('src/types/geometric.d.ts', version: 'v4.6.0'),
      ]);
      replaceFile('test/specs/helpers.math_test.dart', [
        _chartJs('test/specs/helpers.math.tests.js', version: '4.5.1'),
      ]);
      replaceFile('lib/src/js/fdlibm_log.dart', [
        _header('fdlibm', '5.2', 'e_log.c', 'SunPro, Sun Microsystems, Inc.'),
      ]);
      expect(run(), [
        _warning(
          'lib/src/js/fdlibm_log.dart:1: stale header: fdlibm 5.2 is older '
          'than 5.3. $restamp',
        ),
        _error(
          'lib/src/types/geometric.dart:1: Chart.js v4.6.0 is newer than '
          'the pin v4.5.1.',
        ),
        _error(
          'test/specs/helpers.math_test.dart:1: write the version as '
          'v4.5.1.',
        ),
      ]);
    });

    test('of port_sources.yaml follow chartJsVersion', () {
      replaceFile('lib/src/upstream.dart', [
        _portOnly,
        "const String chartJsVersion = '4.6.0';",
      ]);
      const stale =
          ':1: stale header: Chart.js v4.5.1 is older than v4.6.0 '
          '(chartJsVersion). $restamp';
      expect(run(), [
        _error(
          'tool/port_sources.yaml: Chart.js version is v4.5.1, but '
          'chartJsVersion is 4.6.0: write v4.6.0.',
        ),
        _warning('lib/src/helpers/helpers.math.dart$stale'),
        _warning('lib/src/types/geometric.dart$stale'),
        _warning('test/flutter_test_config.dart$stale'),
        _warning('test/specs/helpers.math_test.dart$stale'),
      ]);
    });
  });

  group('commit pin', () {
    const restamp = 'Restamp it (upstream-tracking.md 4.8).';
    const chartJsFiles = [
      'lib/src/helpers/helpers.math.dart',
      'lib/src/types/geometric.dart',
      'test/flutter_test_config.dart',
      'test/specs/helpers.math_test.dart',
    ];

    setUp(() {
      gitlink = _pinCommit;
      head = _pinCommit;
      tree
        ..write(
          '$_package/tool/port_sources.yaml',
          _chartJsPin(
            version: _pinVersion,
            ref: _pinCommit,
            commit: _pinCommit,
          ),
        )
        ..write('$_package/doc/parity.md', [
          _parityRow('src/helpers/helpers.math.ts', tree: _pinCommit),
          _parityRow('test/specs/helpers.math.tests.js', tree: _pinCommit),
        ])
        ..write('$_package/lib/src/upstream.dart', [
          _portOnly,
          "const String chartJsVersion = '4.5.1+7169e651';",
        ]);
    });

    /// The command of upstream-tracking.md 4.8 for the commit pin.
    void restampHeaders() {
      for (final path in chartJsFiles) {
        final file = File(tree.path('$_package/$path'));
        file.writeAsStringSync(
          file.readAsStringSync().replaceAll(
            RegExp(r'^// Ported from Chart\.js v4\.5\.1 ', multiLine: true),
            '// Ported from Chart.js $_pinVersion ',
          ),
        );
      }
    }

    test('passes restamped headers', () {
      restampHeaders();
      expect(run(), isEmpty);
    });

    test('reports a header of the release as stale, not as an error', () {
      final result = check();
      const stale =
          ':1: stale header: Chart.js v4.5.1 is older than $_pinVersion '
          '(chartJsVersion). $restamp';
      expect(describeFindings(result.findings), [
        for (final path in chartJsFiles) _warning('$path$stale'),
      ]);
      expect(result.findings.any((finding) => finding.isError), isFalse);
    });

    test('rejects another commit, a short commit and a newer release', () {
      restampHeaders();
      replaceFile('lib/src/types/geometric.dart', [
        _chartJs('src/types/geometric.d.ts', version: 'v4.5.1+2898a6d1'),
      ]);
      replaceFile('test/flutter_test_config.dart', [
        _chartJs('test/index.js', version: 'v4.5.1+7169e65'),
      ]);
      replaceFile('test/specs/helpers.math_test.dart', [
        _chartJs('test/specs/helpers.math.tests.js', version: 'v4.6.0'),
      ]);
      expect(run(), [
        _error(
          'lib/src/types/geometric.dart:1: Chart.js v4.5.1+2898a6d1 names '
          'another commit than the pin $_pinVersion. $restamp',
        ),
        _error(
          'test/flutter_test_config.dart:1: the header line does not match '
          'the grammar of porting-flow.md 4, tool 2.',
        ),
        startsWith(
          _error('test/flutter_test_config.dart:1: line 1 is neither'),
        ),
        _error(
          'test/specs/helpers.math_test.dart:1: Chart.js v4.6.0 is newer '
          'than the pin $_pinVersion.',
        ),
      ]);
    });

    test('needs the full pin commit as commit and ref', () {
      restampHeaders();
      gitlink = _chartJsCommit;
      head = _chartJsCommit;
      tree.write(
        '$_package/tool/port_sources.yaml',
        _chartJsPin(
          version: _pinVersion,
          ref: 'master',
          commit: _chartJsCommit,
        ),
      );
      expect(run(), [
        _error(
          'tool/port_sources.yaml: Chart.js version $_pinVersion names the '
          'commit 7169e651, but the pin commit is $_chartJsCommit.',
        ),
        _error(
          'tool/port_sources.yaml: Chart.js pin ref master differs from the '
          'pin commit $_chartJsCommit. The ref of a commit pin is its full '
          'commit (upstream-tracking.md 2.4).',
        ),
      ]);
    });

    test('needs a submodule', () {
      tree.write('$_package/tool/port_sources.yaml', [
        for (final line in _chartJsPin(
          version: _pinVersion,
          ref: _pinCommit,
          commit: _pinCommit,
        ))
          if (line == '    version: "5.3"')
            '    version: "5.3+7169e651"'
          else
            line,
      ]);
      restampHeaders();
      const stale =
          'stale header: fdlibm 5.3 is older than 5.3+7169e651. $restamp';
      expect(run(), [
        _error(
          'tool/port_sources.yaml: fdlibm version 5.3+7169e651 is a commit '
          'pin, but the pin kind is "copy", not "submodule".',
        ),
        _warning('lib/src/js/fdlibm_log.dart:1: $stale'),
        _warning('lib/src/js/fdlibm_log.dart:2: $stale'),
      ]);
    });

    test('reads the links of the pin commit without a checkout', () {
      restampHeaders();
      head = null;
      tree
        ..deleteDirectory('third_party/Chart.js')
        ..mkdir('third_party/Chart.js');
      String notListed(String path, String source) => _error(
        '$path:1: $source is not in the files of tool/port_sources.yaml or '
        'its file_index, and third_party/Chart.js is not checked out (dart '
        'run melos run upstream).',
      );
      expect(run(), [
        notListed('lib/src/types/geometric.dart', 'src/types/geometric.d.ts'),
      ]);

      // A git host has no tree with the name of the version.
      tree.write('$_package/doc/parity.md', [
        _parityRow('src/helpers/helpers.math.ts', tree: _pinVersion),
        _parityRow('test/specs/helpers.math.tests.js', tree: _pinVersion),
      ]);
      expect(run(), [
        notListed(
          'lib/src/helpers/helpers.math.dart',
          'src/helpers/helpers.math.ts',
        ),
        notListed('lib/src/types/geometric.dart', 'src/types/geometric.d.ts'),
        notListed(
          'test/specs/helpers.math_test.dart',
          'test/specs/helpers.math.tests.js',
        ),
      ]);
    });

    test('needs the checkout at the pin commit', () {
      restampHeaders();
      head = _chartJsCommit;
      expect(run(), [
        _error(
          'tool/port_sources.yaml: third_party/Chart.js has the commit '
          '$_chartJsCommit checked out, but the Chart.js pin commit is '
          '$_pinCommit. The check reads the source paths from the '
          'checked-out files: check out the pin (dart run melos run '
          'upstream).',
        ),
      ]);
    });
  });

  group('port_sources.yaml', () {
    test('agrees with the gitlink', () {
      gitlink = _chartJsCommit;
      expect(run(), isEmpty);
      gitlink = '0' * 40;
      expect(run(), [
        _error(
          'tool/port_sources.yaml: Chart.js pin commit is $_chartJsCommit, '
          'but the gitlink of third_party/Chart.js is ${'0' * 40}.',
        ),
      ]);
    });

    test('lists files that exist at the pin', () {
      tree.write('$_package/tool/port_sources.yaml', [
        ..._portSources,
        '      - e_exp.c',
      ]);
      expect(run(), [
        _error(
          'tool/port_sources.yaml: fdlibm file e_exp.c does not exist in '
          'third_party/fdlibm.',
        ),
      ]);
    });

    test('is reported when it cannot be read', () {
      tree.write('$_package/tool/port_sources.yaml', ['sources: [a]']);
      expect(run(), [
        _error(
          'tool/port_sources.yaml: line 1: unsupported YAML syntax: [a]',
        ),
      ]);
      tree.delete('$_package/tool/port_sources.yaml');
      expect(run(), [
        startsWith(_error('tool/port_sources.yaml: Cannot open')),
      ]);
    });
  });

  group('DIVERGES(chartjs) markers', () {
    const marker = '// DIVERGES(chartjs): theme-H1, the theme scope.';
    const category =
        'start with a category (adapt, platform, theme, js-semantics, '
        'harness, not-followed) and a hyphen.';
    const malformed =
        ': a malformed DIVERGES marker: write the line comment '
        '"DIVERGES(chartjs): <row id>, <reason>" (porting-flow.md 4).';

    void writeDifferences(List<String> ids) =>
        tree.write('$_package/doc/differences.md', [
          '# Differences',
          '',
          '| ID | Dart file and symbol | Reason |',
          '|---|---|---|',
          for (final id in ids) '| <a id="$id"></a>`$id` | x | y |',
          '',
          '| Other | table |',
          '|---|---|',
          '| theme-H9 | ignored |',
        ]);

    test('name a row, and each row has a marker', () {
      replaceFile('lib/src/types/geometric.dart', [
        _chartJs('src/types/geometric.d.ts'),
        marker,
        "const s = '// DIVERGES(chartjs): theme-H8, in a string.';",
      ]);
      expect(run(), [
        _error(
          'lib/src/types/geometric.dart:2: the DIVERGES(chartjs) marker '
          'names "theme-H1", which is not a row of '
          '$_package/doc/differences.md.',
        ),
      ]);

      writeDifferences(['theme-H1']);
      expect(run(), isEmpty);

      writeDifferences(['theme-H1', 'theme-H2']);
      expect(run(), [
        _error(
          'doc/differences.md:6: row theme-H2 has no DIVERGES(chartjs) '
          'marker in the code.',
        ),
      ]);
    });

    test('follow the marker grammar', () {
      writeDifferences(['theme-H1', 'bad-H1']);
      replaceFile('lib/src/types/geometric.dart', [
        _chartJs('src/types/geometric.d.ts'),
        marker,
        "    // DIVERGES(chartjs): bad-H1, a long reason ${'x' * 40}.",
        '// DIVERGES: theme-H1, no project.',
        '/// DIVERGES(chartjs): theme-H1, a doc comment.',
        '/* DIVERGES(chartjs): theme-H1, a block comment. */',
        '/** DIVERGES(chartjs): theme-H1, a doc block. */',
        '/* Not a marker: DIVERGES(chartjs): theme-H1, x. */',
      ]);
      expect(run(), [
        _error('doc/differences.md:6: row ID "bad-H1" does not $category'),
        _error(
          'lib/src/types/geometric.dart:3: the DIVERGES(chartjs) row ID '
          '"bad-H1" does not $category',
        ),
        _error(
          'lib/src/types/geometric.dart:3: the DIVERGES(chartjs) marker '
          'line is longer than 80 columns.',
        ),
        _error('lib/src/types/geometric.dart:4$malformed'),
        _error('lib/src/types/geometric.dart:5$malformed'),
        _error('lib/src/types/geometric.dart:6$malformed'),
        _error('lib/src/types/geometric.dart:7$malformed'),
      ]);
    });
  });

  group('harness package', () {
    const harness = 'packages/chartjs_test_utils';
    const testUtilsHeader =
        '// Ported from chartjs-test-utils v0.4.0 src/context.js '
        '(MIT, chartjs-test-utils Contributors).';

    setUp(() {
      tree
        ..write('$_package/tool/port_sources.yaml', [
          ..._portSources,
          '  - header: chartjs-test-utils',
          '    version: "v0.4.0"',
          '    url: https://github.com/chartjs/chartjs-test-utils',
          '    language: js',
          '    spdx: MIT',
          '    holder: chartjs-test-utils Contributors',
          '    pin:',
          '      kind: copy',
          '      path: third_party/chartjs-test-utils',
          '    targets:',
          '      - source: src/',
          '        dart: $harness/lib/src/',
        ])
        ..write('third_party/chartjs-test-utils/src/context.js', ['//'])
        ..write('REUSE.toml', [
          'version = 1',
          '[[annotations]]',
          'path = "$_package/**"',
          _chartJsCopyright,
          'SPDX-License-Identifier = "MIT"',
          '[[annotations]]',
          'path = "$harness/**"',
          _testUtilsCopyright,
          'SPDX-License-Identifier = "MIT"',
          '[[annotations]]',
          'path = "$_package/lib/src/js/fdlibm_*.dart"',
          'SPDX-FileCopyrightText = ["1993 Sun Microsystems, Inc.", "2026 A"]',
          'SPDX-License-Identifier = "SunPro AND MIT"',
        ])
        ..write('$harness/pubspec.yaml', ['name: chartjs_test_utils'])
        ..write('$harness/LICENSE', [
          'Copyright (c) 2020 chartjs-test-utils Contributors',
        ])
        ..write('$harness/lib/pure.dart', [_portOnly])
        ..write('$harness/lib/src/context.dart', [testUtilsHeader])
        ..write('$harness/tool/a.dart', [_portOnly]);
    });

    List<String> runWithHarness() => describeFindings(
      checkPortHeaders(
        HeaderCheckInput(
          repository: tree.root,
          home: tree.path(_package),
          packages: withHarnessPackage([tree.path(_package)]),
          gitlink: (_, _) => null,
          checkoutHead: (_) => null,
        ),
      ).findings,
    );

    test('is added next to the home package when it exists', () {
      final home = tree.path(_package);
      expect(withHarnessPackage([home]), [home, tree.path(harness)]);
      expect(withHarnessPackage([home, tree.path(harness)]), [
        home,
        tree.path(harness),
      ]);
      tree.delete('$harness/pubspec.yaml');
      expect(withHarnessPackage([home]), [home]);
      expect(withHarnessPackage([tree.path(harness)]), [tree.path(harness)]);
    });

    test('passes a harness that keeps the rules', () {
      expect(runWithHarness(), isEmpty);
    });

    test('has its headers checked', () {
      tree
        ..write('$harness/lib/a.dart', ['/// Docs.'])
        ..write('$harness/lib/src/context.dart', [_portOnly])
        ..write('$harness/tool/a.dart', [testUtilsHeader])
        ..write('$harness/test/a_test.dart', [
          _header(
            'chartjs-test-utils',
            'v0.4.0',
            'src/utils.js',
            'MIT, chartjs-test-utils Contributors',
          ),
        ]);
      expect(runWithHarness(), [
        startsWith('error: $harness/lib/a.dart:1: line 1 is neither'),
        equals(
          'error: $harness/lib/src/context.dart:1: the file is at the Dart '
          'path of chartjs-test-utils src/context.js: start it with its '
          '"// Ported from" header, not the port-only marker.',
        ),
        equals(
          'error: $harness/test/a_test.dart:1: src/utils.js does not exist '
          'in third_party/chartjs-test-utils.',
        ),
        equals(
          'error: $harness/test/a_test.dart:1: the Dart path of src/utils.js '
          'is $harness/lib/src/utils.dart (porting-flow.md 2.5), not this '
          'file.',
        ),
        startsWith(
          'error: $harness/tool/a.dart:1: files under test/port/ and tool/ '
          'are port-only',
        ),
        startsWith(
          'error: $harness/tool/a.dart:1: the Dart path of src/context.js is '
          '$harness/lib/src/context.dart',
        ),
      ]);
    });

    test('reads the LICENSE of the harness, not of the home package', () {
      tree
        ..write('$harness/LICENSE', ['Copyright (c) 2026 A'])
        ..write('$_package/LICENSE', [
          'Copyright (c) 2014-2024 Chart.js Contributors',
          'Copyright (C) 1993 by Sun Microsystems, Inc.',
          'Copyright (c) 2020 chartjs-test-utils Contributors',
        ]);
      expect(runWithHarness(), [
        equals(
          'error: $harness/lib/src/context.dart:1: $harness/LICENSE does not '
          'name "chartjs-test-utils Contributors".',
        ),
      ]);
      tree.delete('$harness/LICENSE');
      expect(runWithHarness(), [
        equals(
          'error: $harness/lib/src/context.dart:1: $harness/LICENSE does not '
          'exist.',
        ),
      ]);
    });

    test('needs its own REUSE.toml annotation', () {
      tree.write('REUSE.toml', [
        'version = 1',
        '[[annotations]]',
        'path = "packages/**"',
        _chartJsCopyright,
        'SPDX-License-Identifier = "MIT"',
        '[[annotations]]',
        'path = "$_package/lib/src/js/fdlibm_*.dart"',
        'SPDX-FileCopyrightText = ["1993 Sun Microsystems, Inc.", "2026 A"]',
        'SPDX-License-Identifier = "SunPro AND MIT"',
      ]);
      expect(runWithHarness(), [
        equals(
          'error: $harness/lib/src/context.dart:1: the last REUSE.toml '
          'annotation that matches the file (line 2) does not list '
          '"chartjs-test-utils Contributors".',
        ),
      ]);
    });
  });

  test('parseDifferences reads the ID column', () {
    final rows = parseDifferences(
      [
        '| ID | Reason |',
        '| :-- | --- |',
        '| <a id="adapt-x"></a>adapt-x | a |',
        '| `harness-y` | b |',
        '',
        '| Name | ID |',
        '|---|---|',
        '| no | theme-z |',
      ].join('\n'),
    );
    expect(
      [for (final r in rows) '${r.id}:${r.line}'],
      [
        'adapt-x:3',
        'harness-y:4',
      ],
    );
    expect(isDifferenceId('js-semantics-sort'), isTrue);
    expect(isDifferenceId('not-followed-12238'), isTrue);
    expect(isDifferenceId('theme-'), isFalse);
    expect(isDifferenceId('themes-H1'), isFalse);
  });
}
