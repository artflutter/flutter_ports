// Original code, not ported from Chart.js: tests of the parity generator.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/parity.dart' as command;
import '../../tool/src/check_support.dart';
import '../../tool/src/parity.dart';
import '../../tool/src/spec_cases.dart';
import 'file_tree.dart';

const String _package = 'packages/flutter_chartjs_port';
const String _harness = 'packages/chartjs_test_utils';
const String _blob = 'https://github.com/chartjs/Chart.js/blob/v4.5.1';
const String _utilsBlob =
    '[`src/utils.js`](https://github.com/chartjs/chartjs-test-utils/blob/'
    'v0.4.0/src/utils.js)';

List<String> _source(
  String header,
  String version,
  String url,
  String holder,
  String path,
  List<String> targets, {
  String? ref,
  String commit = '0000000000000000000000000000000000000000',
}) => [
  '  - header: "$header"',
  '    version: "$version"',
  '    url: $url',
  '    language: js',
  '    spdx: MIT',
  '    holder: $holder',
  '    pin:',
  '      kind: submodule',
  '      path: $path',
  '      ref: "${ref ?? version}"',
  '      commit: $commit',
  '    targets:',
  ...targets,
];

/// The `tool/port_sources.yaml` of the fixture repository. A [commitPin]
/// (upstream-tracking.md 2.4) is the Chart.js pin
/// `v4.5.1+<the first 8 digits>`, with the full commit as its ref.
List<String> _portSourcesOf({String? commitPin}) => [
  'sources:',
  ..._source(
    'Chart.js',
    commitPin == null ? 'v4.5.1' : 'v4.5.1+${commitPin.substring(0, 8)}',
    'https://github.com/chartjs/Chart.js',
    'Chart.js Contributors',
    'third_party/Chart.js',
    [
      '      - source: src/',
      '        dart: $_package/lib/src/',
      '      - source: test/specs/',
      '        dart: $_package/test/specs/',
      '      - source: test/index.js',
      '        dart: $_package/test/flutter_test_config.dart',
    ],
    ref: commitPin,
    commit: commitPin ?? '0000000000000000000000000000000000000000',
  ),
  ..._source(
    '@kurkle/color',
    'v0.3.2',
    'https://github.com/kurkle/color',
    'Jukka Kurkela',
    'third_party/kurkle-color',
    [
      '      - source: src/',
      '        dart: $_package/lib/src/kurkle_color/',
      '      - source: packed.js',
      '        dart: $_package/lib/src/kurkle_color/packed.dart',
    ],
  ),
  ..._source(
    'chartjs-test-utils',
    'v0.4.0',
    'https://github.com/chartjs/chartjs-test-utils',
    'chartjs-test-utils Contributors',
    'third_party/chartjs-test-utils',
    ['      - source: src/', '        dart: $_harness/lib/src/'],
  ),
];

final List<String> _portSources = _portSourcesOf();

String _header(String path) =>
    '// Ported from Chart.js v4.5.1 $path (MIT, Chart.js Contributors).';

const String _portOnly = '// Original code, not ported from Chart.js: a test.';

const String _harnessHeader =
    '// Ported from chartjs-test-utils v0.4.0 src/context.js (MIT, '
    'chartjs-test-utils Contributors).';

String _marker(String id) => '// DIVERGES(chartjs): $id, a reason.';

/// A manifest with `helpers.math.tests.js` (two cases) and
/// `core.scale.tests.js` (three cases and a fixture group of two fixtures).
Map<String, Object?> _manifest() {
  Map<String, Object?> spec(
    String file,
    List<List<String>> cases, {
    int fixtures = 0,
  }) => {
    'file': file,
    'lines': 1,
    'fixtureGroups': [
      if (fixtures > 0)
        {
          'describe': ['scale', 'auto'],
          'prefix': 'core.scale',
          'line': 2,
          'fixtures': fixtures,
        },
    ],
    'cases': [
      for (final c in cases)
        {
          'describe': c.sublist(0, c.length - 1),
          'it': c.last,
          'test': c.last,
          'line': 1,
          'loop': false,
          'kind': 'non-chart',
        },
    ],
  };
  return {
    'schema': 1,
    'source': {'project': 'Chart.js', 'version': '4.5.1', 'commit': null},
    'specs': [
      spec('helpers.math.tests.js', [
        ['math', 'adds'],
        ['math', 'skips'],
      ]),
      spec('core.scale.tests.js', [
        ['scale', 'works'],
        ['scale', 'needs a chart'],
        ['scale', 'differs'],
      ], fixtures: 2),
    ],
    'fixtures': {
      'items': [
        for (final name in ['a', 'b'])
          {
            'path': 'core.scale/$name.json',
            'specs': ['core.scale.tests.js'],
          },
      ],
      'orphans': <Object?>[],
    },
  };
}

/// One Dart spec test for [_reporter] and [_results].
typedef _Test = ({String file, List<String> path, String? skip});

/// The tests of the fixture spec files: `helpers.math` passes one case and
/// skips one, `core.scale` passes one case and skips two.
const List<_Test> _tests = [
  (file: 'helpers.math_test.dart', path: ['math', 'adds'], skip: null),
  (file: 'helpers.math_test.dart', path: ['math', 'skips'], skip: 'n/a: x'),
  (file: 'core.scale_test.dart', path: ['scale', 'works'], skip: null),
  (
    file: 'core.scale_test.dart',
    path: ['scale', 'needs a chart'],
    skip: 'blocked: harness',
  ),
  (
    file: 'core.scale_test.dart',
    path: ['scale', 'differs'],
    skip: 'diverges: platform-d',
  ),
];

ReporterOutput _results([List<_Test> tests = _tests]) => ReporterOutput([
  for (final t in tests)
    DartTest(
      file: 'test/specs/${t.file}',
      groups: t.path.sublist(0, t.path.length - 1),
      name: t.path.last,
      result: t.skip == null ? TestResult.success : TestResult.skipped,
      skipReason: t.skip,
    ),
], const {});

/// The JSON reporter output of [tests], as `flutter test --reporter json`
/// writes it.
String _reporter([List<_Test> tests = _tests]) {
  final lines = [
    jsonEncode({'type': 'start', 'protocolVersion': '0.1.1'}),
  ];
  var id = 0;
  final suites = <String, int>{};
  final groups = <String, int>{};
  for (final t in tests) {
    final suite = suites.putIfAbsent(t.file, () {
      final suite = id++;
      lines.add(
        jsonEncode({
          'type': 'suite',
          'suite': {'id': suite, 'path': '/r/$_package/test/specs/${t.file}'},
        }),
      );
      return suite;
    });
    final ids = <int>[];
    for (var depth = 0; depth < t.path.length; depth++) {
      final name = t.path.sublist(0, depth).join(' ');
      final parent = ids.isEmpty ? null : ids.last;
      ids.add(
        groups.putIfAbsent('${t.file} $name', () {
          final group = id++;
          lines.add(
            jsonEncode({
              'type': 'group',
              'group': {
                'id': group,
                'suiteID': suite,
                'parentID': parent,
                'name': name,
              },
            }),
          );
          return group;
        }),
      );
    }
    final test = id++;
    lines
      ..add(
        jsonEncode({
          'type': 'testStart',
          'test': {
            'id': test,
            'name': t.path.join(' '),
            'suiteID': suite,
            'groupIDs': ids,
            'metadata': {'skip': t.skip != null, 'skipReason': t.skip},
          },
        }),
      )
      ..add(
        jsonEncode({
          'type': 'testDone',
          'testID': test,
          'result': 'success',
          'skipped': t.skip != null,
          'hidden': false,
        }),
      );
  }
  return '${lines.join('\n')}\n';
}

/// A repository with the three pins, the two packages and the inputs of
/// tool 6.
final class _Repo {
  _Repo() : tree = FileTree() {
    tree
      ..write('REUSE.toml', ['version = 1'])
      ..write('$_package/pubspec.yaml', ['name: flutter_chartjs_port'])
      ..write('$_harness/pubspec.yaml', ['name: chartjs_test_utils'])
      ..write('$_package/tool/port_sources.yaml', _portSources)
      ..writeText(
        '$_package/doc/upstream/manifest.json',
        jsonEncode(_manifest()),
      )
      ..write('$_package/doc/differences.md', [
        '# Differences',
        '',
        '| ID | Category |',
        '|---|---|',
        for (final id in [
          'platform-a',
          'adapt-b',
          'adapt-a',
          'harness-c',
          'platform-d',
        ])
          '| <a id="$id"></a>`$id` | x |',
      ])
      ..write('third_party/Chart.js/src/helpers/helpers.math.ts', [
        'a',
        'b',
        'c',
      ])
      ..write('third_party/Chart.js/src/helpers/helpers.core.ts', ['a', 'b'])
      ..write('third_party/Chart.js/src/core/core.scale.js', ['a'])
      ..write('third_party/Chart.js/src/index.ts', ['a', 'b', 'c', 'd'])
      ..write('third_party/Chart.js/test/specs/helpers.math.tests.js', ['a'])
      ..write('third_party/Chart.js/test/specs/core.scale.tests.js', [
        'a',
        'b',
      ])
      ..write('third_party/Chart.js/test/index.js', ['a'])
      ..write('third_party/kurkle-color/src/byte.js', ['a'])
      ..write('third_party/kurkle-color/packed.js', ['a', 'b'])
      ..write('third_party/chartjs-test-utils/src/utils.js', ['a'])
      ..write('third_party/chartjs-test-utils/src/context.js', ['a', 'b'])
      ..write('$_package/lib/src/helpers/helpers.math.dart', [
        _header('src/helpers/helpers.math.ts'),
        _marker('adapt-b'),
        'const a = 1;',
        _marker('platform-a'),
        _marker('adapt-a'),
      ])
      ..write('$_package/lib/src/core/core.scale.dart', [
        _header('src/core/core.scale.js'),
      ])
      ..write('$_package/test/specs/helpers.math_test.dart', [
        _header('test/specs/helpers.math.tests.js'),
      ])
      ..write('$_package/test/specs/core.scale_test.dart', [
        _header('test/specs/core.scale.tests.js'),
        "@TestOn('vm')",
        'library;',
      ])
      ..write('$_package/lib/src/js/js_math.dart', [_portOnly])
      ..write('$_package/tool/x.dart', [_portOnly])
      ..write('$_harness/lib/src/context.dart', [
        _harnessHeader,
        _marker('harness-c'),
      ]);
  }

  final FileTree tree;

  String get repository => tree.root;

  String get package => tree.path(_package);

  ParityModel model([ReporterOutput? results]) => computeParity(
    ParityInput(
      repository: repository,
      package: package,
      results: results ?? _results(),
    ),
  );

  void status(List<String> lines) => tree.write('$_package/$statusPath', lines);
}

/// A status file for the fixture repository.
StatusFile _status() => StatusFile(
  prose: {
    'intro': ['Intro.', '', 'More.'],
    'summary': ['The types area has {{rows:core:ported}} rows.'],
    'specs': ['Specs.'],
    'specs.after': ['After the specs.'],
  },
  rows: {
    'Chart.js': {
      'src/helpers/helpers.math.ts': 'ported ({{differences}})',
      'src/core/core.scale.js':
          'ported (the spec has {{passed}}/{{cases}} cases that pass)',
      'src/index.ts': 'partial: `a` (phase 9)',
      'test/specs/core.scale.tests.js':
          'in progress ({{passed}}/{{cases}} cases pass on {{platforms}}; '
          '{{skipped|case}} skipped: {{skipped:blocked: harness}} '
          '`blocked: harness` and {{skipped:diverges}} `diverges`; '
          '{{differences}})',
      'test/specs/helpers.math.tests.js':
          'ported ({{passed}}/{{cases}} cases pass on {{platforms}}; '
          '{{skipped:n/a|case}} skipped, `n/a`: x)',
    },
    'chartjs-test-utils': {
      'src/context.js': 'ported ({{differences}}). A | B.',
    },
  },
  dart: {
    'Chart.js': {'src/index.ts': 'lib/src/entry.dart'},
  },
  portOnly: [
    const PortOnlyEntry(
      '`lib/src/js/js_math.dart`',
      'JS math',
      '`test/port/js/js_math_test.dart`',
    ),
    const PortOnlyEntry(
      '`tool/*.dart` ({{files:tool/*.dart}} files)',
      'x',
      '—',
    ),
  ],
);

/// The output of [_status] for the fixture repository.
const String _document =
    '''
# Chart.js parity tracker

Intro.

More.

## Summary

The types area has 1 rows.

| Area | Files | Lines | Ported |
|---|---:|---:|---:|
| helpers | 2 | 5 | 1 |
| core | 1 | 1 | 1 |
| elements | 0 | 0 | 0 |
| scales | 0 | 0 | 0 |
| controllers | 0 | 0 | 0 |
| plugins | 0 | 0 | 0 |
| platform | 0 | 0 | 0 |
| types | 0 | 0 | 0 |
| entry points | 1 | 4 | 0 |
| upstream specs | 2 | 3 | 1 |
| test set-up | 1 | 1 | 0 |
| @kurkle/color | 2 | 3 | 0 |
| chartjs-test-utils | 2 | 3 | 1 |

## Helpers (`src/helpers`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/helpers/helpers.core.ts`]($_blob/src/helpers/helpers.core.ts) | 2 | | not started |
| [`src/helpers/helpers.math.ts`]($_blob/src/helpers/helpers.math.ts) | 3 | `lib/src/helpers/helpers.math.dart` | ported (differences: 2 `adapt`, 1 `platform`, [differences.md](differences.md#adapt-b), [differences.md](differences.md#adapt-a), [differences.md](differences.md#platform-a)) |

## Core (`src/core`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/core/core.scale.js`]($_blob/src/core/core.scale.js) | 1 | `lib/src/core/core.scale.dart` | ported (the spec has 1/3 cases that pass) |

## Elements (`src/elements`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|

## Scales (`src/scales`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|

## Dataset controllers (`src/controllers`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|

## Plugins (`src/plugins`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|

## Platform (`src/platform`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|

## Type declarations (`src/types`)

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|

## Entry points

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/index.ts`]($_blob/src/index.ts) | 4 | `lib/src/entry.dart` | partial: `a` (phase 9) |

## Upstream tests

Specs.

| Upstream spec | Lines | Cases | Fixtures | Dart test | Status |
|---|---:|---:|---:|---|---|
| [`test/specs/core.scale.tests.js`]($_blob/test/specs/core.scale.tests.js) | 2 | 3 | 2 | `test/specs/core.scale_test.dart` | in progress (1/3 cases pass on the VM; 2 cases skipped: 1 `blocked: harness` and 1 `diverges`; differences: 1 `platform`, [differences.md](differences.md#platform-d)) |
| [`test/specs/helpers.math.tests.js`]($_blob/test/specs/helpers.math.tests.js) | 1 | 2 | 0 | `test/specs/helpers.math_test.dart` | ported (1/2 cases pass on the VM, dart2js and dart2wasm; 1 case skipped, `n/a`: x) |

After the specs.

### Test set-up

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`test/index.js`]($_blob/test/index.js) | 1 | | not started |

## @kurkle/color 0.3.2

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/byte.js`](https://github.com/kurkle/color/blob/v0.3.2/src/byte.js) | 1 | | not started |
| [`packed.js`](https://github.com/kurkle/color/blob/v0.3.2/packed.js) | 2 | | not started |

## chartjs-test-utils 0.4.0

| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/context.js`](https://github.com/chartjs/chartjs-test-utils/blob/v0.4.0/src/context.js) | 2 | `lib/src/context.dart` | ported (differences: 1 `harness`, [differences.md](differences.md#harness-c)). A \\| B. |
| [`src/utils.js`](https://github.com/chartjs/chartjs-test-utils/blob/v0.4.0/src/utils.js) | 1 | | not started |

## Port-only files

| File | Contents | Tests |
|---|---|---|
| `lib/src/js/js_math.dart` | JS math | `test/port/js/js_math_test.dart` |
| `tool/*.dart` (1 files) | x | — |
''';

const String _statusFile = '$_package/doc/status.yaml';

String _error(String message) => 'error: $_statusFile: $message';

String _warning(String message) => 'warning: $_statusFile: $message';

String _parityWarning(int? line, String message) =>
    'warning: doc/parity.md${line == null ? '' : ':$line'}: $message';

void main() {
  group('statusValueOf', () {
    test('reads the values of porting-flow.md section 1 step 7', () {
      expect(statusValueOf('not started'), 'not started');
      expect(statusValueOf('in progress: DPR 1'), 'in progress');
      expect(statusValueOf('partial: `a`'), 'partial');
      expect(statusValueOf('ported (3/3 cases)'), 'ported');
      expect(statusValueOf('replaced (x)'), 'replaced');
      expect(statusValueOf('distributed'), 'distributed');
      expect(statusValueOf('n/a: the UMD entry'), 'n/a');
      expect(statusValueOf('portedly'), isNull);
      expect(statusValueOf('n/abc'), isNull);
      expect(statusValueOf('verified'), isNull);
      expect(statusValueOf(''), isNull);
    });
  });

  group('status.yaml', () {
    test('writes and reads back each part', () {
      final status = StatusFile(
        prose: {
          'intro': [r'A "quoted" line: with # and \ and `code`', '', 'Ünï'],
        },
        rows: {
          'Chart.js': {'src/a.js': "ported ({{differences}}; it's #12155)"},
          '@kurkle/color': {'src/b.js': 'n/a: x | y\ttab'},
        },
        dart: {
          'Chart.js': {'src/c.js': 'lib/src/c.dart'},
        },
        portOnly: [const PortOnlyEntry('`a`', 'b: c', '')],
      );
      final text = writeStatusFile(status);
      expect(text, startsWith(statusFileComment));
      expect(text, contains('  "@kurkle/color":\n'));
      expect(text, contains(r'"A \"quoted\" line: with # and \\ and'));
      expect(text, contains(r'x | y\ttab'));
      final read = parseStatusFile(text);
      expect(read.prose, status.prose);
      expect(read.rows, status.rows);
      expect(read.dart, status.dart);
      expect(
        [for (final row in read.portOnly) row.cells],
        [
          ['`a`', 'b: c', ''],
        ],
      );
      expect(writeStatusFile(read), text);
      expect(parseStatusFile('').rows, isEmpty);
    });

    test('rejects other shapes', () {
      for (final text in [
        '- a',
        'other: x',
        'prose:\n  intro: x',
        'rows: x',
        'rows:\n  Chart.js:\n    src/a.js:\n      - x',
        'port-only: x',
        'port-only:\n  - file: x\n    other: y',
      ]) {
        expect(
          () => parseStatusFile(text),
          throwsFormatException,
          reason: text,
        );
      }
    });
  });

  group('computeParity', () {
    test('lists the files of each area with their targets', () {
      final model = _Repo().model();
      String rowsOf(String id) => [
        for (final row in model.rowsOf(
          parityAreas.firstWhere((a) => a.id == id),
        ))
          '${row.path} ${row.lines} ${row.targets.join(',')}',
      ].join('; ');
      expect(
        rowsOf('helpers'),
        'src/helpers/helpers.core.ts 2 ; '
        'src/helpers/helpers.math.ts 3 lib/src/helpers/helpers.math.dart',
      );
      expect(rowsOf('elements'), '');
      expect(rowsOf('entry'), 'src/index.ts 4 ');
      expect(rowsOf('setup'), 'test/index.js 1 ');
      // The order of the selectors: src/, then packed.js.
      expect(rowsOf('kurkle'), 'src/byte.js 1 ; packed.js 2 ');
      // The harness target is relative to its own package.
      expect(
        rowsOf('test-utils'),
        'src/context.js 2 lib/src/context.dart; src/utils.js 1 ',
      );
      expect(model.portOnlyFiles, [
        '$_package/lib/src/js/js_math.dart',
        '$_package/tool/x.dart',
      ]);
    });

    test('orders the differences by category, then by differences.md', () {
      final model = _Repo().model();
      expect(
        model.rowOf('Chart.js', 'src/helpers/helpers.math.ts')!.differences,
        ['adapt-b', 'adapt-a', 'platform-a'],
      );
      expect(
        model.rowOf('chartjs-test-utils', 'src/context.js')!.differences,
        ['harness-c'],
      );
      // A spec row also has the rows of its `diverges:` skip reasons.
      final scale = model.rowOf('Chart.js', 'test/specs/core.scale.tests.js')!;
      expect(scale.differences, ['platform-d']);
      expect(scale.fixtures, 2);
      expect(scale.vmOnly, isTrue);
      expect(scale.spec!.count(CaseStatus.passed), 1);
      final math = model.rowOf('Chart.js', 'test/specs/helpers.math.tests.js')!;
      expect(math.vmOnly, isFalse);
      expect(math.fixtures, 0);
      // A src/ row has the spec of its base name.
      expect(
        model.rowOf('Chart.js', 'src/core/core.scale.js')!.specFile,
        'core.scale.tests.js',
      );
      expect(
        model.rowOf('Chart.js', 'src/helpers/helpers.core.ts')!.specFile,
        isNull,
      );
      expect(categoryOf('js-semantics-x'), 'js-semantics');
      expect(categoryOf('other'), 'not-followed');
    });

    test('links the full commit of a commit pin', () {
      const commit = '7169e65147a47f3720957a6f156a33c838ab9f57';
      final repo = _Repo();
      repo.tree.write(
        '$_package/tool/port_sources.yaml',
        _portSourcesOf(commitPin: commit),
      );
      final model = repo.model();
      // A git host has no tree with the name v4.5.1+7169e651.
      expect(
        model.rowOf('Chart.js', 'src/helpers/helpers.math.ts')!.link,
        '[`src/helpers/helpers.math.ts`](https://github.com/chartjs/Chart.js/'
        'blob/$commit/src/helpers/helpers.math.ts)',
      );
      expect(
        model.rowOf('@kurkle/color', 'packed.js')!.url,
        'https://github.com/kurkle/color/blob/v0.3.2/packed.js',
      );
      final text = renderParity(model, _status()).text;
      expect(text, isNot(contains('/blob/v4.5.1')));
      expect(
        text,
        _document.replaceAll('Chart.js/blob/v4.5.1/', 'Chart.js/blob/$commit/'),
      );
    });

    test('throws on a missing input', () {
      final repo = _Repo();
      repo.tree.deleteDirectory('third_party/kurkle-color');
      expect(
        repo.model,
        throwsA(
          isA<ParityInputError>().having(
            (e) => e.message,
            'message',
            contains('third_party/kurkle-color is not checked out'),
          ),
        ),
      );
      repo.tree.delete('$_package/doc/upstream/manifest.json');
      expect(repo.model, throwsA(isA<ParityInputError>()));
    });
  });

  group('renderParity', () {
    test('writes the document', () {
      final repo = _Repo();
      final output = renderParity(repo.model(), _status());
      expect(describeFindings(output.findings), isEmpty);
      expect(output.text, _document);
    });

    test('reports the errors of status.yaml', () {
      final repo = _Repo();
      final status = _status();
      status.rows['Chart.js']!
        ..['src/helpers/helpers.math.ts'] = 'ported'
        ..['src/helpers/helpers.core.ts'] = 'done ({{differences}})'
        ..['src/core/core.scale.js'] = 'ported ({{bogus}}, {{platforms}})'
        ..['test/index.js'] = 'ported ({{passed}}, {{files}}, {{rows:x}}'
        ..['src/missing.js'] = 'ported';
      status.dart['Chart.js']!['src/helpers/helpers.math.ts'] = 'x.dart';
      status.prose['other'] = ['x'];
      status.prose['intro'] = ['{{cases|case}} {{platforms|case}} }}'];
      final output = renderParity(repo.model(), status);
      expect(describeFindings(output.findings), [
        _error(
          'Chart.js src/missing.js is not a file of a table of parity.md.',
        ),
        _error('prose key "other" is not a section of parity.md.'),
        _error(
          'Chart.js src/helpers/helpers.core.ts: {{differences}}: the Dart '
          'files of the row have no DIVERGES hunk. Remove the placeholder.',
        ),
        _error(
          'Chart.js src/helpers/helpers.core.ts: the status "done '
          '(differences: none)" does not start with a value of '
          'porting-flow.md section 1 step 7 (not started, in progress, '
          'partial, ported, replaced, distributed, n/a).',
        ),
        _error(
          'Chart.js src/helpers/helpers.math.ts: the Dart files of the row '
          'have DIVERGES hunks (adapt-b, adapt-a, platform-a). Add '
          '{{differences}} to its status.',
        ),
        _error(
          'Chart.js src/helpers/helpers.math.ts: the headers give the Dart '
          'target lib/src/helpers/helpers.math.dart. Remove its "dart" entry.',
        ),
        // A src/ row has the platforms of the Dart file of its spec.
        _error(
          'Chart.js src/core/core.scale.js: unknown placeholder {{bogus}}.',
        ),
        _error(
          'Chart.js test/index.js: {{passed}} needs a row with an upstream '
          'spec.',
        ),
        _error('Chart.js test/index.js: unknown placeholder {{files}}.'),
        _error(
          'Chart.js test/index.js: {{rows:x}} names no Summary area and '
          'status.',
        ),
        _error('prose intro: an unclosed "{{" or a lone "}}".'),
        _error(
          'prose intro: {{cases|case}} needs a row with an upstream spec.',
        ),
        _error(
          'prose intro: {{platforms|case}} needs a row with a Dart spec file.',
        ),
      ]);
    });

    test('counts the skip reasons and the files', () {
      final repo = _Repo();
      final status = _status();
      status.rows['Chart.js']!['test/specs/core.scale.tests.js'] =
          'ported ({{skipped:blocked|case}}, {{skipped:blocked: harness}}, '
          '{{skipped:blocked: harnes}}, {{skipped:n/a}}, {{missing}}, '
          '{{failed}}, {{cases|case}}; {{differences}})';
      status.portOnly.add(
        const PortOnlyEntry(
          '`$_harness/lib/*.dart` ({{files:$_harness/lib/**.dart}} files), '
              '`lib/**`, {{files:lib/src/**|file}}',
          '',
          '',
        ),
      );
      final output = renderParity(repo.model(), status);
      expect(describeFindings(output.findings), [
        _warning(
          'the port-only row of $_harness/lib/*.dart names a path that does '
          'not exist.',
        ),
      ]);
      expect(
        output.text,
        contains(
          '| ported (1 case, 1, 0, 0, 0, 0, 3 cases; differences: 1 '
          '`platform`, [differences.md](differences.md#platform-d)) |',
        ),
      );
      expect(
        output.text,
        contains('| `$_harness/lib/*.dart` (1 files), `lib/**`, 3 files | | |'),
      );
    });

    test('warns about the port-only rows and the started rows', () {
      final repo = _Repo();
      repo.tree.write('$_package/test/port/a_test.dart', [_portOnly]);
      final status = _status();
      status.rows['Chart.js']!.remove('src/core/core.scale.js');
      status.portOnly.add(const PortOnlyEntry('`lib/none.dart`', '', ''));
      final output = renderParity(repo.model(), status);
      expect(describeFindings(output.findings), [
        _warning(
          'Chart.js src/core/core.scale.js: lib/src/core/core.scale.dart '
          'exists, but the status is "not started".',
        ),
        _warning(
          'the port-only row of lib/none.dart names a path that does not '
          'exist.',
        ),
        _warning('no port-only row names $_package/test/port/a_test.dart.'),
      ]);
    });
  });

  group('importParity', () {
    test('reads the hand-written parts back with placeholders', () {
      final repo = _Repo();
      final model = repo.model();
      // A document with a stale count, as a person writes parity.md.
      final markdown = _document.replaceFirst(
        '| ported (the spec has 1/3 cases that pass) |',
        '| ported (the spec has 2/3 cases that pass) |',
      );
      final result = importParity(markdown, model, StatusFile());
      final status = result.status;
      expect(status.rows, _status().rows);
      expect(status.dart, _status().dart);
      expect(status.prose, {
        ..._status().prose,
        'summary': [
          'The types area has 1 rows.',
        ],
      });
      expect(
        [for (final row in status.portOnly) row.cells],
        [
          for (final row in _status().portOnly) row.cells,
        ],
      );
      expect(describeFindings(result.findings), [
        _parityWarning(
          38,
          'src/core/core.scale.js: the derived status differs from the cell: '
          '"...orted (the spec has 2/3 cases that pass)" becomes "...orted '
          '(the spec has 1/3 cases that pass)".',
        ),
      ]);
      // The new status file gives the document with the counts of tool 5.
      expect(renderParity(model, status).text, _document);
    });

    test('keeps the entries whose output equals the cell', () {
      final repo = _Repo();
      final previous = _status();
      final result = importParity(_document, repo.model(), previous);
      expect(describeFindings(result.findings), isEmpty);
      expect(writeStatusFile(result.status), writeStatusFile(previous));
    });

    test('adds the differences and reports the stale cells', () {
      final repo = _Repo();
      final model = repo.model();
      final markdown = _document
          .replaceFirst(
            '| ported (differences: 2 `adapt`, 1 `platform`, '
                '[differences.md](differences.md#adapt-b), '
                '[differences.md](differences.md#adapt-a), '
                '[differences.md](differences.md#platform-a)) |',
            '| ported (note) |',
          )
          .replaceFirst('| 3 | `lib/src/helpers', '| 9 | `lib/src/helpers')
          .replaceFirst('| helpers | 2 | 5 | 1 |', '| helpers | 2 | 6 | 1 |')
          .replaceFirst('(1 files)', '(4 files)')
          .replaceFirst(
            '| $_utilsBlob | 1 | | not started |',
            '| $_utilsBlob | 1 | `a.dart`, `b.dart` | '
                'ported (differences: '
                '[differences.md](differences.md#harness-c)) |\n'
                '| [`src/none.js`](https://x/none.js) | 1 | | ported |',
          )
          .replaceFirst('## Entry points', '## Other')
          .replaceFirst(
            '| `lib/src/js/js_math.dart` | JS math |',
            '| `lib/src/js/js_math.dart` | JS math | x |',
          );
      final previous = _status()
        ..portOnly.add(const PortOnlyEntry('`kept.dart`', '', ''))
        ..prose['entry'] = ['Entry.'];
      final result = importParity(markdown, model, previous);
      final rows = result.status.rows['Chart.js']!;
      expect(
        rows['src/helpers/helpers.math.ts'],
        'ported ({{differences}}; note)',
      );
      // The row and the prose of the unknown section stay as they were.
      expect(rows['src/index.ts'], 'partial: `a` (phase 9)');
      expect(result.status.dart['Chart.js'], {
        'src/index.ts': 'lib/src/entry.dart',
      });
      expect(result.status.prose['entry'], ['Entry.']);
      // A row that only status.yaml has stays at its place.
      expect(result.status.portOnly.map((row) => row.file), [
        '`lib/src/js/js_math.dart`',
        '`tool/*.dart` ({{files:tool/*.dart}} files)',
        '`kept.dart`',
      ]);
      expect(describeFindings(result.findings), [
        _parityWarning(
          32,
          'src/helpers/helpers.math.ts: Lines is 9, the file '
          'has 3 lines.',
        ),
        _parityWarning(
          32,
          'src/helpers/helpers.math.ts: the text of doc/status.yaml '
          'differs. The cell replaces it.',
        ),
        _parityWarning(
          32,
          'src/helpers/helpers.math.ts: the Dart files of '
          'the row have DIVERGES hunks, and the cell has no differences. '
          'Tool 6 adds them.',
        ),
        _parityWarning(
          32,
          'src/helpers/helpers.math.ts: the derived status '
          'differs from the cell: "ported (note)" becomes "ported '
          '(differences: 2 `adapt`, 1 `platform`, '
          '[differences.md](differences.md#adapt-b), '
          '[differences.md](differences.md#adapt-a), '
          '[differences.md](differences.md#platform-a); note)".',
        ),
        _parityWarning(
          70,
          'the section "## Other" is not a section of tool '
          '6. Its text is not imported.',
        ),
        _parityWarning(
          105,
          'src/utils.js: the cell names differences.md '
          'rows, but the Dart files of the row have no DIVERGES hunk. The '
          'text stays.',
        ),
        _parityWarning(
          105,
          'src/utils.js: the Dart target is "`a.dart`, '
          '`b.dart`", the headers give "".',
        ),
        _parityWarning(
          106,
          'the row "[`src/none.js`](https://x/none.js)" is '
          'not a file of chartjs-test-utils in ## chartjs-test-utils '
          '0.4.0.',
        ),
        _parityWarning(112, 'a port-only row has 4 cells, not 3.'),
        _parityWarning(
          113,
          'port-only row `tool/*.dart` (4 files): the row of '
          'doc/status.yaml differs. The cells replace it.',
        ),
        _parityWarning(
          113,
          'port-only row `tool/*.dart` (4 files): the '
          'derived file count differs: "`tool/*.dart` (4 files)" becomes '
          '"`tool/*.dart` (1 files)".',
        ),
        _parityWarning(
          110,
          'doc/status.yaml keeps the port-only row '
          '`lib/src/js/js_math.dart`, which parity.md does not have.',
        ),
        _parityWarning(
          110,
          'doc/status.yaml keeps the port-only row '
          '`kept.dart`, which parity.md does not have.',
        ),
        _parityWarning(
          null,
          'Chart.js src/index.ts has no row in '
          'doc/parity.md.',
        ),
        _parityWarning(13, 'Summary helpers: Lines is 6, tool 6 derives 5.'),
        _parityWarning(
          25,
          'Summary chartjs-test-utils: Ported is 1, tool 6 '
          'derives 2.',
        ),
      ]);
    });

    test('keeps the edits of both files with a base', () {
      final repo = _Repo();
      final model = repo.model();
      // status.yaml changed a row, the intro, and the port-only rows after
      // the import of _document.
      final previous = _status();
      previous.rows['Chart.js']!['src/index.ts'] = 'partial: `a` (edited)';
      previous.rows['Chart.js']!['src/core/core.scale.js'] = 'ported (both)';
      previous.prose['intro'] = ['Intro of status.yaml.'];
      previous.portOnly
        ..insert(1, const PortOnlyEntry('`tool/x.dart`', 'new', ''))
        ..removeAt(0);
      // parity.md changed two other cells, one cell that status.yaml
      // changed too, and added a port-only row.
      final markdown = _document
          .replaceFirst(
            '1 case skipped, `n/a`: x)',
            '1 case skipped, `n/a`: x. Edited)',
          )
          .replaceFirst('After the specs.', 'After the specs, edited.')
          .replaceFirst(
            'ported (the spec has 1/3 cases that pass)',
            'ported (cell)',
          )
          .replaceFirst(
            '| `tool/*.dart` (1 files) | x | — |',
            '| `tool/*.dart` (1 files) | x | — |\n| `lib/a.dart` | a | |',
          );
      final result = importParity(markdown, model, previous, base: _document);
      final rows = result.status.rows['Chart.js']!;
      expect(rows['src/index.ts'], 'partial: `a` (edited)');
      expect(rows['src/core/core.scale.js'], 'ported (cell)');
      expect(
        rows['test/specs/helpers.math.tests.js'],
        'ported ({{passed}}/{{cases}} cases pass on {{platforms}}; '
        '{{skipped:n/a|case}} skipped, `n/a`: x. Edited)',
      );
      expect(result.status.prose['intro'], ['Intro of status.yaml.']);
      expect(result.status.prose['specs.after'], ['After the specs, edited.']);
      expect(
        [for (final row in result.status.portOnly) row.file],
        [
          '`tool/x.dart`',
          '`tool/*.dart` ({{files:tool/*.dart}} files)',
          '`lib/a.dart`',
        ],
      );
      expect(describeFindings(result.findings), [
        _parityWarning(
          38,
          'src/core/core.scale.js: the text of doc/status.yaml differs. The '
          'cell replaces it.',
        ),
        _parityWarning(
          109,
          'doc/status.yaml keeps the port-only row `tool/x.dart`, which '
          'parity.md does not have.',
        ),
      ]);
    });

    test('recognizes the count forms of the spec rows', () {
      final repo = _Repo();
      final model = repo.model();
      const fragment =
          'differences: 1 `platform`, '
          '[differences.md](differences.md#platform-d)';
      String recognize(String cell) {
        final markdown = _document.replaceFirst(
          RegExp(r'\| in progress \(1/3 cases[^\n]*'),
          '| $cell |',
        );
        final result = importParity(markdown, model, StatusFile());
        return result
            .status
            .rows['Chart.js']!['test/specs/core.scale.tests.js']!;
      }

      expect(
        recognize(
          'ported (9/9 cases pass on the VM, dart2js and dart2wasm; 7 cases '
          'skipped: 3 `blocked: harness`, 2 `n/a` (a, b) and 2 '
          '`blocked: x`; 1 case skipped, `n/a`: y; $fragment)',
        ),
        'ported ({{passed}}/{{cases}} cases pass on {{platforms}}; '
        '{{skipped|case}} skipped: {{skipped:blocked: harness}} '
        '`blocked: harness`, {{skipped:n/a}} `n/a` (a, b) and '
        '{{skipped:blocked: x}} `blocked: x`; {{skipped:n/a|case}} skipped, '
        '`n/a`: y; {{differences}})',
      );
      expect(
        recognize(
          'ported (0/3 cases pass on the VM; 2 cases skipped: 1 `blocked: '
          'harness` and 1 `blocked: y`. 3 cases skipped: `blocked: harness`; '
          '1 case skipped; $fragment)',
        ),
        'ported ({{passed}}/{{cases}} cases pass on {{platforms}}; '
        '{{skipped:blocked|case}} skipped: {{skipped:blocked: harness}} '
        '`blocked: harness` and {{skipped:blocked: y}} `blocked: y`. '
        '{{skipped:blocked: harness|case}} skipped: `blocked: harness`; '
        '{{skipped|case}} skipped; {{differences}})',
      );
    });

    test('reads the Summary counts into placeholders', () {
      final repo = _Repo();
      final markdown = _document.replaceFirst(
        'The types area has 1 rows.',
        'It counts. The core area has 1 `ported` row. The\n'
            'entry points area has 0 `partial` rows.',
      );
      final result = importParity(markdown, repo.model(), StatusFile());
      expect(result.status.prose['summary'], [
        'It counts. The core area has {{rows:core:ported}} `ported` row. The',
        'entry points area has {{rows:entry points:partial}} `partial` rows.',
      ]);
      expect(
        renderParity(repo.model(), result.status).text,
        contains('The\nentry points area has 1 `partial` rows.'),
      );
    });
  });

  group('compareText', () {
    test('names the lines that differ', () {
      const summary =
          'lines differ from the output of tool 6. Run "dart run melos run '
          'parity". Edit doc/status.yaml, not doc/parity.md.';
      expect(compareText('a\nb\nc\n', 'a\nb\nc\n', 'p.md'), isEmpty);
      expect(describeFindings(compareText('a\nb\nc', 'a\nx', 'p.md')), [
        'error: p.md:2: the file differs from tool 6: "x" becomes "b".',
        'error: p.md:3: the file ends before this line of tool 6: "c".',
        'error: p.md: 2 $summary',
      ]);
      expect(
        describeFindings(compareText('a', 'a\nb\nc\nd', 'p.md', limit: 1)),
        [
          'error: p.md:2: the file has a line that tool 6 does not write.',
          'error: p.md: 3 $summary',
        ],
      );
    });
  });

  group('command', () {
    test('imports, writes, checks and reports usage errors', () async {
      final repo = _Repo();
      final package = repo.package;
      final results = repo.tree.path('results.json');
      repo.tree.writeText('results.json', _reporter());
      final parity = File('$package/$parityPath');
      final status = File('$package/$statusPath');
      final out = StringBuffer();
      final err = StringBuffer();
      Future<int> run(List<String> args) {
        out.clear();
        err.clear();
        return command.run([...args, package], out: out, err: err);
      }

      // Without status.yaml, only --import runs.
      expect(await run(['--results', results]), 2);
      expect(out.toString(), contains('Make it with --import.'));
      expect(await run(['--import', '--results', results]), 2);
      expect(out.toString(), contains('doc/parity.md does not exist.'));

      parity.writeAsStringSync(_document);
      expect(await run(['--import', '--dry-run', '--results', results]), 0);
      expect(out.toString(), startsWith(statusFileComment));
      expect(
        err.toString(),
        'parity --import: passed, 11 files, 0 errors, 0 warnings.\n',
      );
      expect(status.existsSync(), isFalse);
      expect(await run(['--import', '--results', results]), 0);
      // The Summary prose has no `status` value, so its count stays text.
      final imported = _status()
        ..prose['summary'] = ['The types area has 1 rows.'];
      expect(status.readAsStringSync(), writeStatusFile(imported));
      expect(out.toString(), startsWith('parity: wrote '));

      expect(await run(['--check', '--results', results]), 0);
      expect(
        out.toString(),
        'parity --check: passed, 11 files, 0 errors, 0 warnings.\n',
      );
      expect(await run(['--dry-run', '--results', results]), 0);
      expect(out.toString(), _document);
      expect(
        err.toString(),
        'parity: passed, 11 files, 0 errors, 0 warnings.\n',
      );
      expect(await run(['--results', results]), 0);
      expect(out.toString(), contains('doc/parity.md is up to date.'));

      // A case that passes now changes the output.
      repo.tree.writeText(
        'results.json',
        _reporter([
          ..._tests.where((t) => t.path.last != 'skips'),
          (file: 'helpers.math_test.dart', path: ['math', 'skips'], skip: null),
        ]),
      );
      expect(await run(['--check', '--results', results]), 1);
      expect(out.toString(), contains('lines differ from the output'));
      expect(await run(['--results', results]), 0);
      expect(out.toString(), contains('wrote'));
      expect(parity.readAsStringSync(), contains('2/2 cases pass'));
      expect(await run(['--check', '--results', results]), 0);

      // An error stops the write.
      status.writeAsStringSync(
        status.readAsStringSync().replaceFirst('"partial:', '"done:'),
      );
      expect(await run(['--results', results]), 1);
      expect(out.toString(), contains('doc/parity.md is not written.'));
      status.writeAsStringSync('rows: x\n');
      expect(await run(['--results', results]), 2);
      expect(out.toString(), contains('rows is a mapping'));

      // No spec results.
      repo.tree.writeText('results.json', '');
      expect(await run(['--results', results]), 2);
      expect(out.toString(), contains('no results of the spec tests'));
      expect(await run(['--results', repo.tree.path('none.json')]), 2);

      expect(await run(['--check', '--dry-run']), 2);
      expect(await run(['--base', results]), 2);
      expect(out.toString(), contains('--base needs --import'));
      expect(
        await run(['--import', '--base', 'none.md', '--results', results]),
        2,
      );
      expect(await run(['--bad']), 2);
      expect(out.toString(), startsWith('parity: unexpected argument --bad'));
      out.clear();
      expect(await command.run(['--help'], out: out), 0);
      expect(out.toString(), startsWith('Usage:'));
      out.clear();
      expect(await command.run([repo.tree.path('none')], out: out), 2);
      expect(out.toString(), contains('has no pubspec.yaml'));

      repo.tree.writeText('results.json', _reporter());
      repo.tree.deleteDirectory('third_party/Chart.js');
      expect(await run(['--check', '--results', results]), 2);
      expect(out.toString(), contains('is not checked out'));
    });
  });

  group('the repository', () {
    final repository = findAncestorWith(Directory.current.path, 'REUSE.toml');
    final pin = repository == null
        ? null
        : Directory('$repository/third_party/Chart.js/src');
    final skip = pin == null
        ? 'not inside the flutter_ports repository'
        : pin.existsSync() && pin.listSync().isNotEmpty
        ? false
        : '${pin.path} is missing: run `dart run melos run upstream`';

    test('lists every file of the pins and reads status.yaml', () {
      final model = computeParity(
        ParityInput(
          repository: repository!,
          package: '$repository/$_package',
          results: const ReporterOutput([], {}),
        ),
      );
      final files = pin!.listSync(recursive: true).whereType<File>().length;
      final src = model.rows.where(
        (row) => row.source.header == 'Chart.js' && row.path.startsWith('src/'),
      );
      expect(src, hasLength(files));
      final status = File('$repository/$_package/$statusPath');
      final output = renderParity(
        model,
        parseStatusFile(status.readAsStringSync()),
      );
      expect(output.text, startsWith('$parityTitle\n'));
    }, skip: skip);
  });
}
