// Original code, not ported from Chart.js: tests of tool 5, spec-case tracking.
@TestOn('vm')
library;

import 'dart:convert';

import 'package:test/test.dart';

import '../../tool/spec_cases.dart' as command;
import '../../tool/src/spec_cases.dart';
import 'file_tree.dart';

/// A manifest with `a.tests.js` (three cases, one repeated full name and a
/// fixture group) and `b.tests.js` (one case).
Map<String, Object?> _manifestJson() => {
  'schema': 1,
  'source': {'project': 'Chart.js', 'version': '4.5.1', 'commit': null},
  'specs': [
    {
      'file': 'a.tests.js',
      'lines': 40,
      'fixtureGroups': [
        {
          'describe': ['A', 'auto'],
          'prefix': 'a',
          'line': 2,
          'fixtures': 1,
        },
      ],
      'cases': [
        {
          'describe': ['A'],
          'it': 'works',
          'test': 'works',
          'line': 4,
          'loop': false,
          'kind': 'non-chart',
        },
        {
          'describe': ['A', 'inner'],
          'it': 'draws',
          'test': 'draws',
          'line': 10,
          'loop': true,
          'kind': 'chart',
          'chartVia': 'beforeEach',
        },
        {
          'describe': ['A', 'inner'],
          'it': 'draws',
          'test': 'draws #2',
          'line': 10,
          'loop': true,
          'kind': 'chart',
          'chartVia': 'beforeEach',
        },
      ],
    },
    {
      'file': 'b.tests.js',
      'lines': 9,
      'fixtureGroups': <Object?>[],
      'cases': [
        {
          'describe': ['B'],
          'it': 'is pending',
          'test': 'is pending',
          'line': 3,
          'loop': false,
          'kind': 'non-chart',
          'pending': true,
        },
      ],
    },
  ],
  'fixtures': {
    'items': [
      {
        'path': 'a/one.json',
        'specs': ['a.tests.js'],
      },
    ],
    'orphans': <Object?>[],
  },
};

Manifest _manifest() => Manifest.parse(jsonEncode(_manifestJson()));

/// JSON reporter lines for one suite of `test/specs/<file>`.
final class _Reporter {
  final List<String> lines = [
    'Resolving dependencies...',
    jsonEncode({'type': 'start', 'protocolVersion': '0.1.1'}),
  ];
  var _id = 0;
  var _suite = -1;

  void suite(String file) {
    _suite = _id++;
    lines.add(
      jsonEncode({
        'type': 'suite',
        'suite': {'id': _suite, 'path': '/repo/pkg/test/specs/$file'},
      }),
    );
    final loading = _id++;
    _start(loading, 'loading /repo/pkg/test/specs/$file', [], null);
    _done(loading, 'success', hidden: true);
  }

  int group(String fullName, int? parent) {
    final id = _id++;
    lines.add(
      jsonEncode({
        'type': 'group',
        'group': {
          'id': id,
          'suiteID': _suite,
          'parentID': parent,
          'name': fullName,
        },
      }),
    );
    return id;
  }

  void test(
    String fullName,
    List<int> groups, {
    String result = 'success',
    String? skip,
    int? line,
  }) {
    final id = _id++;
    _start(id, fullName, groups, skip, line: line);
    if (result == 'error') {
      lines.add(jsonEncode({'type': 'error', 'testID': id, 'error': 'boom'}));
    }
    _done(id, result, skipped: skip != null);
  }

  void _start(
    int id,
    String name,
    List<int> groups,
    String? skip, {
    int? line,
  }) => lines.add(
    jsonEncode({
      'type': 'testStart',
      'test': {
        'id': id,
        'name': name,
        'suiteID': _suite,
        'groupIDs': groups,
        'metadata': {'skip': skip != null, 'skipReason': skip},
        'line': line,
      },
    }),
  );

  void _done(
    int id,
    String result, {
    bool hidden = false,
    bool skipped = false,
  }) => lines.add(
    jsonEncode({
      'type': 'testDone',
      'testID': id,
      'result': result,
      'skipped': skipped,
      'hidden': hidden,
    }),
  );

  String get output => '${lines.join('\n')}\n';
}

void main() {
  group('paths', () {
    test('map Dart spec files to upstream spec files and back', () {
      expect(
        upstreamSpecOf('/p/test/specs/helpers.math_test.dart'),
        'helpers.math.tests.js',
      );
      expect(
        upstreamSpecOf(r'C:\p\test\specs\core.ticks_test.dart'),
        'core.ticks.tests.js',
      );
      expect(upstreamSpecOf('test/port/js/js_math_test.dart'), isNull);
      expect(
        dartSpecOf('plugin.filler.tests.js'),
        'test/specs/plugin.filler_test.dart',
      );
    });
  });

  group('Manifest.parse', () {
    test('reads the cases, fixture groups and fixtures', () {
      final manifest = _manifest();
      expect(manifest.version, '4.5.1');
      final a = manifest.specs['a.tests.js']!;
      expect(a.cases.map((c) => c.fullName), [
        'A works',
        'A inner draws',
        'A inner draws #2',
      ]);
      expect(a.cases[1].chart, isTrue);
      expect(a.cases[1].loop, isTrue);
      expect(a.cases[0].chart, isFalse);
      expect(a.caseAt(['A', 'inner'], 'draws #2'), same(a.cases[2]));
      expect(a.caseAt(['A'], 'inner draws'), isNull);
      expect(a.isFixtureTest(['A', 'auto'], 'a/one.json'), isTrue);
      expect(a.isFixtureTest(['A'], 'a/one.json'), isFalse);
      expect(
        a.isFixtureTest(['A', 'auto'], '/base/test/fixtures/a/one.json'),
        isTrue,
      );
      expect(a.isFixtureTest(['A', 'auto'], '/base/a/one.json'), isFalse);
      expect(manifest.specs['b.tests.js']!.cases.single.pending, isTrue);
    });

    test('rejects another schema', () {
      final json = _manifestJson()..['schema'] = 2;
      expect(
        () => Manifest.parse(jsonEncode(json)),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a field of another type with a FormatException', () {
      final json = _manifestJson();
      ((json['specs']! as List<Object?>).first!
              as Map<String, Object?>)['cases'] =
          'none';
      expect(
        () => Manifest.parse(jsonEncode(json)),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            'a.tests.js cases is String, expected List<Object?>',
          ),
        ),
      );
      final noVersion = _manifestJson()..['source'] = {'project': 'Chart.js'};
      expect(
        () => Manifest.parse(jsonEncode(noVersion)),
        throwsA(isA<FormatException>()),
      );
      expect(() => Manifest.parse('[]'), throwsA(isA<FormatException>()));
    });
  });

  group('parseReporterOutput', () {
    test('splits group names and skips the loading tests', () {
      final r = _Reporter()..suite('a_test.dart');
      final root = r.group('', null);
      final a = r.group('A', root);
      final inner = r.group('A inner', a);
      r
        ..test('A works', [root, a], line: 7)
        ..test('A inner draws', [root, a, inner], result: 'error')
        ..test(
          'A inner draws #2',
          [root, a, inner],
          skip: 'blocked: core.controller',
        );
      final output = parseReporterOutput(r.output);
      expect(output.loadErrors, isEmpty);
      expect(output.tests.map((t) => t.file).toSet(), {
        'test/specs/a_test.dart',
      });
      expect(output.tests.map((t) => [...t.groups, t.name]), [
        ['A', 'works'],
        ['A', 'inner', 'draws'],
        ['A', 'inner', 'draws #2'],
      ]);
      expect(output.tests.map((t) => t.result), [
        TestResult.success,
        TestResult.failure,
        TestResult.skipped,
      ]);
      expect(output.tests.first.line, 7);
      expect(output.tests.last.skipReason, 'blocked: core.controller');
    });

    test('keeps a group name that does not start with its parent name', () {
      final r = _Reporter()..suite('a_test.dart');
      final root = r.group('', null);
      final top = r.group('Top', root);
      r.test('works', [root, top]);
      final test = parseReporterOutput(r.output).tests.single;
      expect(test.groups, ['Top']);
      expect(test.name, 'works');
    });

    test('reads a failed setUpAll or tearDownAll as a hook failure', () {
      final r = _Reporter()..suite('a_test.dart');
      final root = r.group('', null);
      final a = r.group('A', root);
      r
        ..test('A (setUpAll)', [root, a], result: 'error', line: 2)
        ..test('(tearDownAll)', [root], result: 'failure');
      final output = parseReporterOutput(r.output);
      expect(output.tests, isEmpty);
      expect(output.loadErrors, isEmpty);
      expect(
        output.hookFailures.map((h) => [h.file, h.groups, h.hook, h.line]),
        [
          [
            'test/specs/a_test.dart',
            ['A'],
            'setUpAll',
            2,
          ],
          ['test/specs/a_test.dart', <String>[], 'tearDownAll', null],
        ],
      );
      expect(output.hookFailures.first.error, 'boom');
      expect(output.hookFailures.last.error, 'failure');
    });

    test('reports a file that does not load', () {
      final r = _Reporter()..suite('a_test.dart');
      r.lines.removeLast();
      r.lines.add(
        jsonEncode({'type': 'error', 'testID': 1, 'error': 'compile error'}),
      );
      r.lines.add(
        jsonEncode({
          'type': 'testDone',
          'testID': 1,
          'result': 'error',
          'skipped': false,
          'hidden': false,
        }),
      );
      final output = parseReporterOutput(r.output);
      expect(output.tests, isEmpty);
      expect(output.loadErrors, {'test/specs/a_test.dart': 'compile error'});
    });
  });

  group('parity.md', () {
    const parity = '''
| Upstream file | Lines | Dart target | Status |
|---|---:|---|---|
| [`src/helpers/helpers.math.ts`](https://x/helpers.math.ts) | 207 | `lib/x.dart` | ported |
| [`src/helpers/helpers.core.ts`](https://x/helpers.core.ts) | 416 | `lib/y.dart` | partial: `isFinite` |
| [`src/plugins/plugin.filler/index.js`](https://x/index.js) | 97 | | ported |
| [`src/core/core.legacy.js`](https://x/core.legacy.js) | 10 | | verified |
| [`src/plugins/plugin.filler/simpleArc.js`](https://x/simpleArc.js) | 27 | | ported |
| [`src/plugins/plugin.decimation/minmax.js`](https://x/minmax.js) | 40 | | partial: `minMax` |
| [`src/plugins/plugin.decimation/index.js`](https://x/index.js) | 90 | | ported |
| [`src/core/core.ticks.js`](https://x/core.ticks.js) | 102 | | not started |
| [`test/specs/core.ticks.tests.js`](https://x/core.ticks.tests.js) | 110 | | ported (4/4 cases) |
| [`test/specs/helpers.core.tests.js`](https://x/helpers.core.tests.js) | 509 | | not started |
''';

    test('reads the status of each row', () {
      final statuses = parseParityStatuses(parity);
      expect(statuses['src/helpers/helpers.core.ts'], 'partial: `isFinite`');
      expect(statuses['test/specs/core.ticks.tests.js'], 'ported (4/4 cases)');
      expect(statuses, hasLength(10));
    });

    test('requires the cases of ported modules only', () {
      final statuses = parseParityStatuses(parity);
      expect(requiredBy('helpers.math.tests.js', statuses), (
        status: 'ported',
        required: true,
      ));
      expect(requiredBy('plugin.filler.tests.js', statuses), (
        status: 'ported',
        required: true,
      ));
      // One module of the directory is not ported.
      expect(requiredBy('plugin.decimation.tests.js', statuses), (
        status: 'partial: `minMax`',
        required: false,
      ));
      // Chart.js ADR 0009 removes the status `verified`.
      expect(requiredBy('core.legacy.tests.js', statuses), (
        status: 'verified',
        required: false,
      ));
      expect(requiredBy('core.ticks.tests.js', statuses), (
        status: 'ported (4/4 cases)',
        required: true,
      ));
      expect(requiredBy('helpers.core.tests.js', statuses), (
        status: 'not started',
        required: false,
      ));
      expect(requiredBy('mixed.tests.js', statuses), (
        status: null,
        required: false,
      ));
    });
  });

  test('skip reasons follow porting-flow.md section 1 step 5', () {
    expect(isValidSkipReason('blocked: core.controller'), isTrue);
    expect(
      isValidSkipReason('n/a: the DOM has no Flutter counterpart'),
      isTrue,
    );
    expect(isValidSkipReason('diverges: theme-H1'), isTrue);
    expect(isValidSkipReason('diverges: H1'), isFalse);
    expect(isValidSkipReason('blocked:'), isFalse);
    expect(isValidSkipReason('todo'), isFalse);
    expect(isValidSkipReason(null), isFalse);
  });

  group('compareCases', () {
    late _Reporter r;
    late int root;
    late int a;
    late int inner;

    setUp(() {
      r = _Reporter()..suite('a_test.dart');
      root = r.group('', null);
      a = r.group('A', root);
      inner = r.group('A inner', a);
    });

    SpecCasesResult compare([Map<String, String> parity = const {}]) =>
        compareCases(
          _manifest(),
          parseReporterOutput(r.output),
          parity,
          displayPrefix: 'pkg/',
        );

    test('gives each case a status', () {
      r
        ..test('A works', [root, a])
        ..test('A inner draws', [root, a, inner], result: 'failure', line: 9)
        ..test('A inner draws #2', [root, a, inner], skip: 'n/a: no DOM');
      final result = compare();
      final report = result.reports.first;
      expect(report.results.map((c) => c.label), [
        'passed',
        'failed',
        'skipped(n/a: no DOM)',
      ]);
      expect(report.hasDartFile, isTrue);
      expect(result.reports.last.results.single.status, CaseStatus.missing);
      expect(result.findings.map((f) => f.toString()), [
        'error: pkg/test/specs/a_test.dart:9: "A inner draws" failed.',
      ]);
    });

    test('fails on unknown names, repeats and bad skip reasons', () {
      r
        ..test('A works', [root, a], line: 3)
        ..test('A works', [root, a], line: 5)
        ..test('A inner draw', [root, a, inner], line: 6)
        ..test('A inner draws', [root, a, inner], skip: 'later', line: 7);
      expect(compare().findings.map((f) => f.toString()), [
        equals(
          'error: pkg/test/specs/a_test.dart:5: "A works" repeats the case '
          'of line 3.',
        ),
        equals(
          'error: pkg/test/specs/a_test.dart:6: "A inner draw" is not a case '
          'of test/specs/a.tests.js.',
        ),
        equals(
          'error: pkg/test/specs/a_test.dart:7: "A inner draws" has the skip '
          "reason \"later\". Use 'blocked: <module>', 'n/a: <reason>' or "
          "'diverges: <row id>'.",
        ),
      ]);
    });

    test('counts fixture tests', () {
      final auto = r.group('A auto', a);
      r
        ..test('A auto a/one.json', [root, a, auto])
        ..test('A auto /base/test/fixtures/a/one.json', [root, a, auto]);
      final result = compare();
      expect(result.findings, isEmpty);
      expect(result.reports.first.fixtureTests, 2);
    });

    test('names a failed setUpAll, not an unknown test', () {
      r.test('A inner (setUpAll)', [root, a, inner], result: 'error', line: 8);
      expect(compare().findings.map((f) => f.toString()), [
        equals(
          'error: pkg/test/specs/a_test.dart:8: setUpAll of "A inner" '
          'failed: boom',
        ),
      ]);
    });

    test('names the test() form for a skip without a reason', () {
      r.lines.add(
        jsonEncode({
          'type': 'testStart',
          'test': {
            'id': 99,
            'name': 'A works',
            'suiteID': 0,
            'groupIDs': [root, a],
            'metadata': {'skip': true, 'skipReason': null},
            'line': 4,
          },
        }),
      );
      r.lines.add(
        jsonEncode({
          'type': 'testDone',
          'testID': 99,
          'result': 'success',
          'skipped': true,
          'hidden': false,
        }),
      );
      expect(compare().findings.map((f) => f.toString()), [
        equals(
          'error: pkg/test/specs/a_test.dart:4: "A works" is skipped without '
          'a skip reason. testWidgets takes only `skip: true`, so write a '
          "skipped case as a test() with `skip: 'blocked: <module>'`, "
          "`'n/a: <reason>'` or `'diverges: <row id>'`.",
        ),
      ]);
    });

    test('fails on a Dart spec file without an upstream spec', () {
      r.suite('c_test.dart');
      final rootC = r.group('', null);
      r.test('C works', [rootC]);
      expect(compare().findings.map((f) => f.toString()), [
        equals(
          'error: pkg/test/specs/c_test.dart: no upstream spec file '
          'test/specs/c.tests.js in the manifest.',
        ),
      ]);
    });

    test('fails on missing cases of ported modules only', () {
      r.test('A works', [root, a]);
      expect(compare().findings, isEmpty);
      final result = compare({
        'test/specs/a.tests.js': 'ported (1/3 cases)',
        'src/b.js': 'ported',
      });
      expect(result.findings.map((f) => f.toString()), [
        equals(
          'error: pkg/test/specs/a_test.dart: missing "A inner draws" '
          '(test/specs/a.tests.js:10). parity.md says "ported (1/3 cases)".',
        ),
        equals(
          'error: pkg/test/specs/a_test.dart: missing "A inner draws #2" '
          '(test/specs/a.tests.js:10). parity.md says "ported (1/3 cases)".',
        ),
      ]);
      // b.tests.js is required too, but its only case is pending upstream.
      expect(result.reports.last.required, isTrue);
    });

    test('renders one row for each file with Dart tests', () {
      r.test('A works', [root, a]);
      final table = renderTable(compare().reports, verbose: true);
      expect(table.split('\n'), [
        equals(
          'upstream spec            cases  passed  failed  skipped  missing  '
          'parity.md',
        ),
        'a.tests.js                   3       1       0        0        2  -',
        '  passed               A works',
        '  missing              A inner draws',
        '  missing              A inner draws #2',
        '1 files, no Dart tests       1       0       0        0        1',
        'total                        4       1       0        0        3',
        '',
      ]);
    });
  });

  group('command', () {
    test('passes, fails and reports usage errors', () async {
      final tree = FileTree()
        ..writeText('doc/upstream/manifest.json', jsonEncode(_manifestJson()))
        ..write('doc/parity.md', [
          '| [`test/specs/a.tests.js`](x) | 1 | | ported |',
        ]);
      final r = _Reporter()..suite('a_test.dart');
      final root = r.group('', null);
      final a = r.group('A', root);
      final inner = r.group('A inner', a);
      r
        ..test('A works', [root, a])
        ..test('A inner draws', [root, a, inner])
        ..test('A inner draws #2', [root, a, inner], skip: 'blocked: x');
      tree.writeText('results.json', r.output);
      final out = StringBuffer();
      final args = ['--results', tree.path('results.json'), tree.root];
      expect(await command.run(args, out: out), 0, reason: '$out');
      expect(out.toString(), contains('test:cases: 3 Dart tests in'));
      expect(out.toString(), contains('test:cases: passed, 1 files'));

      tree.writeText('results.json', r.output.replaceAll('#2', '#3'));
      out.clear();
      expect(await command.run(args, out: out), 1);
      expect(out.toString(), contains('"A inner draws #3" is not a case'));
      expect(out.toString(), contains('missing "A inner draws #2"'));

      out.clear();
      expect(await command.run(['--bad'], out: out), 2);
      expect(out.toString(), startsWith('test:cases: unexpected argument'));
      out.clear();
      expect(
        await command.run([
          '--manifest',
          tree.path('none.json'),
          tree.root,
        ], out: out),
        2,
      );
      tree.writeText('bad.json', jsonEncode({'schema': 1, 'source': 1}));
      out.clear();
      expect(
        await command.run([
          '--manifest',
          tree.path('bad.json'),
          tree.root,
        ], out: out),
        2,
      );
      expect(out.toString(), startsWith('test:cases: '));
      expect(out.toString(), contains('field "source"'));
      out.clear();
      expect(await command.run(['--help'], out: out), 0);
      expect(out.toString(), startsWith('Usage:'));
    });
  });
}
