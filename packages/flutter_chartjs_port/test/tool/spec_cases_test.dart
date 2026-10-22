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

/// A spec of the fixture manifest with one fixture group.
Map<String, Object?> _fixtureSpec(String file, String name, int fixtures) => {
  'file': file,
  'lines': 9,
  'fixtureGroups': [
    {
      'describe': [name, 'auto'],
      'prefix': file.substring(0, file.indexOf('.')),
      'line': 2,
      'fixtures': fixtures,
    },
  ],
  'cases': [
    {
      'describe': [name],
      'it': 'works',
      'test': 'works',
      'line': 4,
      'loop': false,
      'kind': 'non-chart',
    },
  ],
};

/// A manifest for the fixture mode: `a.tests.js` (3 fixtures), `c.tests.js`
/// (1 fixture, no Dart file in the tests), `d.tests.js` (1 fixture) and
/// `h.tests.js` (a fixture group without fixtures).
Map<String, Object?> _fixtureManifestJson() => {
  'schema': 1,
  'source': {'project': 'Chart.js', 'version': '4.5.1', 'commit': null},
  'specs': [
    _fixtureSpec('a.tests.js', 'A', 3),
    _fixtureSpec('c.tests.js', 'C', 1),
    _fixtureSpec('d.tests.js', 'D', 1),
    _fixtureSpec('h.tests.js', 'H', 0),
  ],
  'fixtures': {
    'items': [
      for (final (path, spec) in [
        ('a/one.json', 'a.tests.js'),
        ('a/two.js', 'a.tests.js'),
        ('a/three.js', 'a.tests.js'),
        ('c/x.json', 'c.tests.js'),
        ('d/y.json', 'd.tests.js'),
      ])
        {
          'path': path,
          'specs': [spec],
        },
    ],
    'orphans': <Object?>[],
  },
};

Manifest _fixtureManifest() =>
    Manifest.parse(jsonEncode(_fixtureManifestJson()));

/// JSON reporter lines for one suite of `test/specs/<file>`.
final class _Reporter {
  final List<String> lines = [
    'Resolving dependencies...',
    jsonEncode({'type': 'start', 'protocolVersion': '0.1.1'}),
  ];
  var _id = 0;
  var _suite = -1;
  var _time = 0;

  void suite(String file, {String folder = 'test/specs'}) {
    _suite = _id++;
    lines.add(
      jsonEncode({
        'type': 'suite',
        'suite': {'id': _suite, 'path': '/repo/pkg/$folder/$file'},
      }),
    );
    final loading = _id++;
    _start(loading, 'loading /repo/pkg/$folder/$file', [], null);
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
    int? ms,
  }) {
    final id = _id++;
    _start(
      id,
      fullName,
      groups,
      skip,
      line: line,
      time: ms == null ? null : _time,
    );
    if (result == 'error') {
      lines.add(jsonEncode({'type': 'error', 'testID': id, 'error': 'boom'}));
    }
    if (ms != null) _time += ms;
    _done(id, result, skipped: skip != null, time: ms == null ? null : _time);
  }

  void _start(
    int id,
    String name,
    List<int> groups,
    String? skip, {
    int? line,
    int? time,
  }) => lines.add(
    jsonEncode({
      'type': 'testStart',
      'time': ?time,
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
    int? time,
  }) => lines.add(
    jsonEncode({
      'type': 'testDone',
      'time': ?time,
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
      // The status `verified` does not exist (Chart.js ADR 0034).
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

  group('stale blocked skips', () {
    // Chart.js ADR 0041, section 8.
    String row(String path, String status) =>
        '| [`$path`](x) | 1 | | $status |';
    const inProgress =
        'in progress: ported, registered in wave 4 (Chart.js ADR 0041 §8)';
    const fillerFiles = [
      'index.js',
      'filler.drawing.js',
      'filler.helper.js',
      'filler.options.js',
      'filler.segment.js',
      'filler.target.js',
      'filler.target.stack.js',
      'simpleArc.js',
    ];
    Map<String, String> parity({String fillerSimpleArc = inProgress}) =>
        parseParityStatuses(
          [
            row('src/plugins/plugin.title.js', 'ported'),
            row('src/plugins/plugin.colors.ts', 'ported'),
            row('src/plugins/plugin.legend.js', inProgress),
            for (final file in fillerFiles)
              row(
                'src/plugins/plugin.filler/$file',
                file == 'simpleArc.js' ? fillerSimpleArc : 'ported',
              ),
            row('src/index.umd.ts', 'not started'),
            row('test/specs/plugin.title.tests.js', 'not started'),
          ].join('\n'),
        );
    String stale(String module) =>
        "stale skip 'blocked: $module': each src/ row of $module is ported "
        '(Chart.js ADR 0041 §8)';
    final title = stale('plugin.title');
    String unknown(String module) =>
        "unknown module in 'blocked: $module': no src/ row in parity.md";
    String error(String at, String message) => 'error: $at: $message';

    test('(1) a module with each src/ row ported: a finding with the line', () {
      final findings = staleBlockedSkips(parity(), {
        'test/specs/plugin.title_test.dart': [
          "import 'package:test/test.dart';",
          'void main() {',
          "  test('a', () {}, skip: 'blocked: plugin.title');",
          '  test("b", () {}, skip: "blocked: plugin.title");',
          "  test('c', () {}, skip: r'blocked: plugin.title');",
          '}',
        ].join('\n'),
        'test/fixtures/index.dart': [
          'const fixtureSkips = {',
          "  'plugin.colors/a.js': 'blocked: plugin.colors',",
          '};',
        ].join('\r\n'),
      }, displayPrefix: 'pkg/');
      expect(describeFindings(findings), [
        for (final line in [3, 4, 5])
          error('pkg/test/specs/plugin.title_test.dart:$line', title),
        error('pkg/test/fixtures/index.dart:2', stale('plugin.colors')),
      ]);
    });

    test('(2) a module in progress: no finding', () {
      expect(
        staleBlockedSkips(parity(), {
          'test/specs/plugin.legend_test.dart':
              "test('a', () {}, skip: 'blocked: plugin.legend');",
        }),
        isEmpty,
      );
    });

    test('(3) a folder module with one row in progress: no finding', () {
      const sources = {
        'test/specs/plugin.filler_test.dart':
            "test('a', () {}, skip: 'blocked: plugin.filler');",
      };
      expect(moduleRows('plugin.filler', parity()), [
        for (final file in fillerFiles) 'src/plugins/plugin.filler/$file',
      ]);
      expect(staleBlockedSkips(parity(), sources), isEmpty);
      // When the last row is ported, the skip is stale.
      expect(
        describeFindings(
          staleBlockedSkips(parity(fillerSimpleArc: 'ported'), sources),
        ),
        [
          error(
            'test/specs/plugin.filler_test.dart:1',
            stale('plugin.filler'),
          ),
        ],
      );
    });

    test('(4) blocked: index.umd with the row not started: no finding', () {
      expect(moduleRows('index.umd', parity()), ['src/index.umd.ts']);
      expect(
        staleBlockedSkips(parity(), {
          'test/specs/global.namespace_test.dart':
              "test('a', () {}, skip: 'blocked: index.umd');",
        }),
        isEmpty,
      );
    });

    test('(5) an unknown module: a finding', () {
      expect(moduleRows('plugin.legnd', parity()), isEmpty);
      expect(
        describeFindings(
          staleBlockedSkips(parity(), {
            'test/port/a_test.dart': [
              '',
              "const skip = 'blocked: plugin.legnd';",
            ].join('\n'),
          }),
        ),
        [
          error('test/port/a_test.dart:2', unknown('plugin.legnd')),
        ],
      );
    });

    test('(6) comments and interpolations do not count', () {
      expect(
        staleBlockedSkips(parity(), {
          'test/specs/plugin.title_test.dart': [
            "/// A skipped case has `skip: 'blocked: plugin.title'`.",
            "// skip: 'blocked: plugin.title'",
            "/* skip: 'blocked: plugin.title' */",
            "/** 'blocked: plugin.unknown' */",
            r"final a = 'blocked: $module';",
            r"final b = 'blocked: ${module}';",
            r"final c = '${'blocked: plugin.title'}';",
            "final d = 'n/a: blocked: plugin.title';",
            r"final e = 'blocked: $module and more';",
          ].join('\n'),
        }),
        isEmpty,
      );
      // An escaped `$` is not an interpolation.
      expect(
        describeFindings(
          staleBlockedSkips(parity(), {
            'test/a_test.dart': r"final a = 'blocked: plugin.\$x';",
          }),
        ),
        [
          error('test/a_test.dart:1', unknown(r'plugin.\$x')),
        ],
      );
    });

    test('(6b) a blocked: literal in another form: a finding', () {
      // Review finding R1: tool 5 accepts only `blocked: <module>`
      // (isValidSkipReason), so each other form is an error. Else a stale
      // skip in that form stays.
      String form(String content) =>
          "skip reason '$content' is not 'blocked: <module>' "
          '(Chart.js ADR 0041 §8)';
      final findings = staleBlockedSkips(parity(), {
        'test/specs/plugin.title_test.dart': [
          "test('a', () {}, skip: 'blocked: ' 'plugin.title');",
          "test('b', () {}, skip: 'blocked: plugin.title (wave 4)');",
          "test('c', () {}, skip: 'blocked: plugin.title ');",
          "test('d', () {}, skip: 'blocked:plugin.title');",
          "test('e', () {}, skip: r'blocked: plugin.legend and more');",
          "test('f', () {}, skip: 'blocked: plugin.legend');",
        ].join('\n'),
      });
      expect(describeFindings(findings), [
        error('test/specs/plugin.title_test.dart:1', form('blocked: ')),
        error(
          'test/specs/plugin.title_test.dart:2',
          form('blocked: plugin.title (wave 4)'),
        ),
        error(
          'test/specs/plugin.title_test.dart:3',
          form('blocked: plugin.title '),
        ),
        error(
          'test/specs/plugin.title_test.dart:4',
          form('blocked:plugin.title'),
        ),
        error(
          'test/specs/plugin.title_test.dart:5',
          form('blocked: plugin.legend and more'),
        ),
      ]);
    });

    test('(7) a literal in test/tool/ is not read', () {
      const literal = "const skip = 'blocked: plugin.title';";
      final tree = FileTree()
        ..write('test/tool/spec_cases_test.dart', [literal])
        ..write('test/specs/plugin.title_test.dart', [literal])
        ..write('test/build/a_test.dart', [literal])
        ..write('test/.hidden/a_test.dart', [literal])
        ..write('test/specs/notes.txt', [literal])
        ..write('tool/a.dart', [literal]);
      final sources = readStaleScanSources(tree.root);
      expect(sources.keys, ['test/specs/plugin.title_test.dart']);
      expect(isStaleScanPath('test/tool/spec_cases_test.dart'), isFalse);
      expect(
        describeFindings(staleBlockedSkips(parity(), sources)),
        [error('test/specs/plugin.title_test.dart:1', title)],
      );
    });

    test('(8) a generated *_reference*.dart file is not read', () {
      const literal = "const skip = 'blocked: plugin.title';";
      final tree = FileTree()
        ..write('test/port/plugins/plugin_title_reference.dart', [literal])
        ..write('test/port/scales/scale_time_reference_2.dart', [literal])
        ..write('test/port/reference/a_test.dart', [literal]);
      final sources = readStaleScanSources(tree.root);
      expect(sources.keys, ['test/port/reference/a_test.dart']);
      expect(
        isStaleScanPath('test/port/plugins/plugin_title_reference.dart'),
        isFalse,
      );
      expect(isStaleScanPath('test/port/plugins/plugin_harness.dart'), isTrue);
    });

    test('(9) requiredBy gives the same results as before', () {
      // The form of requiredBy before moduleRows.
      ({String? status, bool required}) before(
        String spec,
        Map<String, String> parity,
      ) {
        final done = RegExp(r'^ported\b');
        final base = spec.substring(0, spec.length - '.tests.js'.length);
        final specStatus = parity['test/specs/$spec'];
        if (specStatus != null && done.hasMatch(specStatus)) {
          return (status: specStatus, required: true);
        }
        final modules = [
          for (final MapEntry(:key, :value) in parity.entries)
            if (key.startsWith('src/') &&
                (key.contains('/$base/') ||
                    key.split('/').last.replaceFirst(RegExp(r'\.[^.]+$'), '') ==
                        base))
              value,
        ];
        if (modules.isNotEmpty && modules.every(done.hasMatch)) {
          return (status: modules.first, required: true);
        }
        return (
          status: specStatus ?? (modules.isEmpty ? null : modules.first),
          required: false,
        );
      }

      for (final statuses in [
        parity(),
        parity(fillerSimpleArc: 'ported'),
        parseParityStatuses(
          [
            row('src/helpers/helpers.math.ts', 'ported'),
            row('src/helpers/helpers.core.ts', 'partial: `isFinite`'),
            row('src/core/core.ticks.js', 'not started'),
            row('test/specs/core.ticks.tests.js', 'ported (4/4 cases)'),
            row('src/plugins/plugin.decimation/minmax.js', 'partial'),
            row('src/plugins/plugin.decimation/index.js', 'ported'),
          ].join('\n'),
        ),
      ]) {
        for (final spec in [
          'plugin.title.tests.js',
          'plugin.colors.tests.js',
          'plugin.legend.tests.js',
          'plugin.filler.tests.js',
          'plugin.decimation.tests.js',
          'helpers.math.tests.js',
          'helpers.core.tests.js',
          'core.ticks.tests.js',
          'index.umd.tests.js',
          'mixed.tests.js',
        ]) {
          expect(
            requiredBy(spec, statuses),
            before(spec, statuses),
            reason: spec,
          );
        }
      }
    });

    test('both modes of the command fail on a stale skip', () async {
      final tree = FileTree()
        ..writeText('doc/upstream/manifest.json', jsonEncode(_manifestJson()))
        ..writeText(
          'fixtures.json',
          jsonEncode(_fixtureManifestJson()),
        )
        ..write('doc/parity.md', [row('src/plugins/plugin.title.js', 'ported')])
        ..write('test/port/a_test.dart', [
          '// A port-only test.',
          "const skip = 'blocked: plugin.title';",
        ])
        ..writeText('results.json', '');
      final out = StringBuffer();
      final caseArgs = ['--results', tree.path('results.json'), tree.root];
      final fixtureArgs = [
        '--fixtures',
        '--manifest',
        tree.path('fixtures.json'),
        ...caseArgs,
      ];
      for (final (args, name) in [
        (caseArgs, 'test:cases'),
        (fixtureArgs, 'test:fixtures'),
      ]) {
        out.clear();
        expect(await command.run(args, out: out), 1, reason: '$out');
        expect(
          out.toString(),
          contains('$name: the stale-block check read 1 Dart files of test/'),
        );
        expect(
          out.toString(),
          contains('/test/port/a_test.dart:2: ${stale('plugin.title')}'),
        );
        expect(out.toString(), contains('$name: failed'));
      }

      tree.write('doc/parity.md', [
        row('src/plugins/plugin.title.js', inProgress),
      ]);
      for (final args in [caseArgs, fixtureArgs]) {
        out.clear();
        expect(await command.run(args, out: out), 0, reason: '$out');
      }

      // Both modes need parity.md.
      tree.delete('doc/parity.md');
      for (final args in [caseArgs, fixtureArgs]) {
        out.clear();
        expect(await command.run(args, out: out), 2, reason: '$out');
        expect(out.toString(), contains('parity.md does not exist.'));
      }
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
    // Only the form `blocked: <module>` (review finding R1).
    expect(isValidSkipReason('blocked: plugin.title (wave 4)'), isFalse);
    expect(isValidSkipReason('blocked: plugin.title '), isFalse);
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

  group('fixture mode', () {
    String inA(String message) => 'error: pkg/test/specs/a_test.dart$message';
    String inTwins(String message) =>
        'error: pkg/test/port/fixtures/twins_test.dart$message';
    String inX(String message) => 'error: pkg/test/specs/x_test.dart$message';

    test('the case mode and tool 6 exclude the fixture tests', () {
      expect(caseTestArguments, [
        'test',
        '--exclude-tags',
        'fixtures',
        '--reporter',
        'json',
        'test/specs',
      ]);
    });

    test('selects the spec files with fixtures and test/port/fixtures', () {
      final manifest = _fixtureManifest();
      final present = {'test/specs/a_test.dart', 'test/specs/d_test.dart'};
      var selection = selectFixtureFiles(manifest, present.contains);
      expect(selection.specs, ['a.tests.js', 'd.tests.js']);
      expect(selection.absent, ['c.tests.js']);
      expect(selection.files, [
        'test/specs/a_test.dart',
        'test/specs/d_test.dart',
      ]);
      present.add(portFixtureTests);
      selection = selectFixtureFiles(manifest, present.contains);
      expect(selection.files, [
        'test/specs/a_test.dart',
        'test/specs/d_test.dart',
        'test/port/fixtures',
      ]);
      expect(fixtureTestArguments(selection.files), [
        'test',
        '--tags',
        'fixtures',
        '--reporter',
        'json',
        'test/specs/a_test.dart',
        'test/specs/d_test.dart',
        'test/port/fixtures',
      ]);
      expect(manifest.specs['a.tests.js']!.fixtureGroups.single.fixtures, 3);
      expect(manifest.specs['a.tests.js']!.fixtureGroups.single.line, 2);
    });

    test('a prefix is a regular expression source', () {
      const group = FixtureGroup(['T', 'auto'], 'scale.time');
      expect(group.matches('scale.timeseries/a.json'), isTrue);
      expect(group.matches('scaleXtime/a.js'), isTrue);
      expect(group.matches('scale.time.json'), isFalse);
      expect(group.matches('scale.time/a.png'), isFalse);
    });

    const noSubmodule =
        'n/a: the submodule third_party/Chart.js is not checked out';
    late _Reporter r;
    late int aRoot;
    late int aGroup;
    late int aAuto;

    void suiteA() {
      r = _Reporter()..suite('a_test.dart');
      aRoot = r.group('', null);
      aGroup = r.group('A', aRoot);
      aAuto = r.group('A auto', aGroup);
    }

    FixturesResult compare() => compareFixtures(
      _fixtureManifest(),
      parseReporterOutput(r.output),
      ['a.tests.js'],
      displayPrefix: 'pkg/',
    );

    test('reports passed, failed, skipped and missing fixtures', () {
      suiteA();
      r
        ..test('A auto a/one.json', [aRoot, aGroup, aAuto], ms: 30)
        ..test(
          'A auto a/two.js',
          [aRoot, aGroup, aAuto],
          result: 'error',
          line: 5,
          ms: 70,
        )
        ..suite('index_test.dart', folder: 'test/port/fixtures');
      final portRoot = r.group('', null);
      r.test('twin', [portRoot], ms: 50);
      final result = compare();
      final report = result.reports.single;
      expect(report.spec, 'a.tests.js');
      expect(report.fixtures, 3);
      expect(report.passed, 1);
      expect(report.failed, 1);
      expect(report.skippedCount, 0);
      expect(report.missing, 1);
      expect(result.portPassed, 1);
      expect(result.portFailed, 0);
      expect(describeFindings(result.findings), [
        inA(':5: "A auto a/two.js" failed.'),
        inA(
          ': missing fixture "a/three.js" of '
          'the group "A auto".',
        ),
      ]);
      expect([for (final t in result.slowest) t.milliseconds], [70, 50, 30]);
      final table = renderFixtureTable(result);
      expect(table, contains('a.tests.js'));
      expect(table, contains('port-only tests'));
      expect(table, contains('The 3 slowest tests (not a gate):'));
      expect(table, contains('70 ms  test/specs/a_test.dart: A auto a/two.js'));
    });

    test('counts the skips by reason and fails on a bad reason', () {
      suiteA();
      r
        ..test(
          'A auto a/one.json',
          [aRoot, aGroup, aAuto],
          skip: 'blocked: plugin.filler',
        )
        ..test('A auto a/two.js', [aRoot, aGroup, aAuto], skip: noSubmodule)
        ..test(
          'A auto a/three.js',
          [aRoot, aGroup, aAuto],
          skip: 'later',
          line: 9,
        );
      final result = compare();
      expect(result.reports.single.skipped, {
        'blocked: plugin.filler': 1,
        noSubmodule: 1,
        'later': 1,
      });
      expect(describeFindings(result.findings), [
        inA(
          ':9: "A auto a/three.js" has the skip reason "later". '
          "Use 'blocked: <module>', 'n/a: <reason>' or 'diverges: <row id>'.",
        ),
      ]);
      expect(
        renderFixtureTable(result),
        contains('  skipped 1: blocked: plugin.filler'),
      );
    });

    test('fails on unknown, repeated and ungrouped tests', () {
      suiteA();
      r
        ..test('A auto a/one.json', [aRoot, aGroup, aAuto])
        ..test('A auto /base/test/fixtures/a/one.json', [
          aRoot,
          aGroup,
          aAuto,
        ], line: 3)
        ..test('A auto b/z.json', [aRoot, aGroup, aAuto], line: 4)
        ..test('A auto a/two.js', [aRoot, aGroup, aAuto])
        ..test('A auto a/three.js', [aRoot, aGroup, aAuto])
        ..test('A works', [aRoot, aGroup], line: 6);
      expect(describeFindings(compare().findings), [
        inA(
          ':3: '
          '"A auto /base/test/fixtures/a/one.json" repeats a fixture test.',
        ),
        inA(
          ':4: "A auto b/z.json" is not a '
          'fixture of the prefix "a".',
        ),
        inA(
          ':6: "A works" has the tag fixtures '
          'but is not in a fixture group of test/specs/a.tests.js.',
        ),
      ]);
    });

    test('fails on a fixture group that is not called', () {
      suiteA();
      final result = compare();
      expect(result.reports.single.missing, 3);
      expect(describeFindings(result.findings), [
        inA(
          ': the fixture group "A auto" is not '
          "called: add group('auto', fixture.specs('a')) "
          '(test/specs/a.tests.js:2).',
        ),
      ]);
    });

    test('fails on a failed port-only test, a repeat and a hook', () {
      r = _Reporter()..suite('twins_test.dart', folder: 'test/port/fixtures');
      final root = r.group('', null);
      final twins = r.group('twins', root);
      r
        ..test('twins x', [root, twins], result: 'failure', line: 7)
        ..test('twins y', [root, twins], line: 8)
        ..test('twins y', [root, twins], line: 9)
        ..test('twins (setUpAll)', [root, twins], result: 'error', line: 2)
        ..suite('x_test.dart');
      final xRoot = r.group('', null);
      r.test('X works', [xRoot], line: 3);
      final result = compare();
      expect(result.portPassed, 1);
      expect(result.portFailed, 1);
      expect(describeFindings(result.findings), [
        inTwins(
          ':2: setUpAll of '
          '"twins" failed: boom',
        ),
        inTwins(':7: "twins x" failed.'),
        inTwins(
          ':9: "twins y" repeats '
          'the name of line 8.',
        ),
        inX(
          ': is not a spec file with a fixture '
          'group of the manifest.',
        ),
        inA(
          ': the fixture group "A auto" is not '
          "called: add group('auto', fixture.specs('a')) "
          '(test/specs/a.tests.js:2).',
        ),
      ]);
    });

    test('the command reports the fixtures of a results file', () async {
      final tree = FileTree()
        ..writeText(
          'doc/upstream/manifest.json',
          jsonEncode(_fixtureManifestJson()),
        )
        ..write('doc/parity.md', [
          '| [`src/plugins/plugin.title.js`](x) | 1 | | not started |',
        ])
        ..write('test/specs/a_test.dart', ['//'])
        ..write('test/port/fixtures/index_test.dart', [
          '//',
          "const skip = 'blocked: plugin.title';",
        ]);
      suiteA();
      r
        ..test('A auto a/one.json', [aRoot, aGroup, aAuto])
        ..test('A auto a/two.js', [aRoot, aGroup, aAuto], skip: 'n/a: probe')
        ..test('A auto a/three.js', [aRoot, aGroup, aAuto]);
      tree.writeText('results.json', r.output);
      final out = StringBuffer();
      final args = [
        '--fixtures',
        '--results',
        tree.path('results.json'),
        tree.root,
      ];
      expect(await command.run(args, out: out), 0, reason: '$out');
      expect(
        out.toString(),
        contains('test:fixtures: 3 Dart tests with the tag fixtures'),
      );
      expect(
        out.toString(),
        contains(
          'test:fixtures: no Dart spec file for c.tests.js, d.tests.js.',
        ),
      );
      expect(out.toString(), contains('test:fixtures: passed, 2 files'));

      tree.writeText(
        'results.json',
        r.output.replaceAll('a/three.js', 'a/3.js'),
      );
      out.clear();
      expect(await command.run(args, out: out), 1);
      expect(out.toString(), contains('missing fixture "a/three.js"'));
      expect(out.toString(), contains('test:fixtures: failed'));
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
