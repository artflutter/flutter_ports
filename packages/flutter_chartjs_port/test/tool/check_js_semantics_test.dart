// Original code, not ported from Chart.js: tests of tool 3, the JS check.
@TestOn('vm')
library;

import 'package:test/test.dart';

import '../../tool/src/check_support.dart';
import '../../tool/src/js_semantics.dart';
import '../../tool/src/port_headers.dart' show withHarnessPackage;
import 'file_tree.dart';

const String _ported =
    '// Ported from Chart.js v4.5.1 src/helpers/helpers.math.ts '
    '(MIT, Chart.js Contributors).';

const String _fdlibm =
    '// Ported from fdlibm 5.3 e_log.c (SunPro, Sun Microsystems, Inc.).';

const String _kurkle =
    '// Ported from @kurkle/color v0.3.2 src/hue.js (MIT, Jukka Kurkela).';

const Map<String, String> _languages = {
  'Chart.js': 'js',
  'fdlibm': 'c',
  '@kurkle/color': 'js',
};

/// The findings for a ported file with the [body] lines after the header.
List<String> _check(List<String> body, {String header = _ported}) {
  final findings = <Finding>[];
  checkJsSemanticsText(
    [header, ...body].join('\n'),
    'a.dart',
    findings,
    languages: _languages,
  );
  return describeFindings(findings);
}

/// The rule names that [_check] reports, with their lines.
List<String> _sites(List<String> body) => [
  for (final finding in _check(body))
    finding.replaceFirstMapped(
      RegExp(r'^error: a\.dart:(\d+): ([^:]+):.*$'),
      (match) => '${match[1]} ${match[2]}',
    ),
];

/// A `tool/port_sources.yaml` with a Chart.js and an fdlibm entry.
const List<String> _portSources = [
  'sources:',
  '  - header: Chart.js',
  '    version: "v4.5.1"',
  '    url: https://github.com/chartjs/Chart.js',
  '    language: js',
  '    spdx: MIT',
  '    holder: Chart.js Contributors',
  '    pin:',
  '      kind: copy',
  '      path: third_party/Chart.js',
  '    targets:',
  '      - source: src/',
  '        dart: lib/src/',
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
  '        dart: lib/src/js/fdlibm_log.dart',
];

void main() {
  test('flags each construct of the lexical rules', () {
    expect(
      _sites([
        'final a = x.round();',
        'final b = x.roundToDouble();',
        'final c = x.floor() + y.ceil();',
        'final d = x.truncate();',
        'final e = x.clamp(0, 1);',
        'final f = x % 2;',
        'g %= 3;',
        'final h = math.pow(10.0, n) + pow(2, n);',
        'final i = pow(',
        '  x,',
        '  0.5,',
        ');',
        'final j = x.toString();',
        'final k = x is int || y is! int;',
        'list.sort();',
        'list..sort((a, b) => a - b);',
      ]),
      [
        '2 .round()',
        '4 .floor()',
        '4 .ceil()',
        '5 .truncate()',
        '6 .clamp(',
        '7 %',
        '8 %',
        '9 pow(',
        '10 pow(',
        '14 .toString()',
        '15 is int',
        '16 .sort(',
        '17 .sort(',
      ],
    );
  });

  test('keeps to the JS-compatible forms', () {
    expect(
      _check([
        "import 'dart:math' as math;",
        'final a = x.roundToDouble() + x.floorToDouble() + x.ceilToDouble();',
        'final b = x.remainder(2) + math.sqrt(x) + math.pi + math.log(x);',
        'final c = math.atan2(y, x) + math.sin(x) + isInt + sinh(x);',
        'jsSort(list, compare);',
        'final d = math.sqrt((p.x ?? 0) * (q.x ?? 0));',
      ]),
      isEmpty,
    );
  });

  test('flags the sorts of package:collection', () {
    expect(
      _sites([
        "import 'package:collection/collection.dart' as c;",
        'mergeSort(list, compare: compare);',
        'c.mergeSort<double>(list, start: 1);',
        'insertionSort(list);',
        'final a = list.sorted(compare);',
        'final b = list.sortedBy((e) => e.x) + list.sortedBy<num>(key);',
        'final d = list.sortedByCompare(key, compare);',
        'list',
        '  ..sortBy((e) => e.x)',
        '  ..sortByCompare(key, compare)',
        '  ..sortRange(0, 2, compare);',
        'list.sortRange (0, 2, compare); // js-ok: two distinct values.',
        'final e = list.sortedBy<int Function()>(key);',
        'final f = list.sortedByCompare<Map<String, int>>(key, compare);',
      ]),
      [
        '3 mergeSort(',
        '4 mergeSort(',
        '5 insertionSort(',
        '6 .sorted(',
        '7 .sortedBy(',
        '14 .sortedBy(',
        '8 .sortedByCompare(',
        '15 .sortedByCompare(',
        '10 .sortBy(',
        '11 .sortByCompare(',
        '12 .sortRange(',
      ],
    );
    expect(
      _check(['final a = list.sorted(compare);']).single,
      endsWith(
        'Array.prototype.sort is (Chart.js ADR 0146, Sort). Use jsSort.',
      ),
    );
    expect(
      _check([
        'jsSort(list, compare);',
        'final a = jsMergeSort(list) + list.isSorted(compare);',
        'final b = x.sortedKeys + x.sortByName + sortRangeOf(list);',
        '_mergeSort(list);',
        'mergeSortLength(list);',
      ]),
      isEmpty,
    );
  });

  test('flags DateTime.now( (Chart.js ADR 0146 §6)', () {
    expect(
      _sites([
        'final a = DateTime.now();',
        'final b = DateTime . now ( ).millisecondsSinceEpoch;',
        'final c = clock.now().millisecondsSinceEpoch;',
        "final d = 'DateTime.now()'; // DateTime.now()",
        'final e = MyDateTime.now() + DateTime.nowUtc + x.now();',
        'final f = DateTime.now(); // js-ok: a log time stamp only.',
      ]),
      ['2 DateTime.now(', '3 DateTime.now('],
    );
    expect(
      _check(['final a = DateTime.now();']).single,
      endsWith('Use clock.now() of package:clock (Chart.js ADR 0146 §6).'),
    );
  });

  test('ignores comments and string contents, not interpolations', () {
    expect(
      _sites([
        '// x.round() and 50 %',
        '/* list.sort() */',
        "final s = '50 % of x.round()';",
        r"final t = '${x.round()}';",
        "final u = r'pow(10, 2)';",
      ]),
      ['5 .round()'],
    );
  });

  test('accepts a js-ok reason on the line or alone on the line before', () {
    expect(
      _check([
        'list.sort(); // js-ok: distinct finite numbers.',
        '// js-ok: an integer exponent.',
        'final a = pow(10, n);',
        '// js-ok: two lines up does not count.',
        '',
        'final b = x.round();',
        'final c = x.remainder(y); // js-ok: no site here.',
        'final d = x % y;',
      ]),
      [
        startsWith('error: a.dart:7: .round():'),
        startsWith('error: a.dart:9: %:'),
        equals(
          'warning: a.dart:5: js-ok with no flagged site on the next line.',
        ),
        equals('warning: a.dart:8: js-ok with no flagged site on this line.'),
      ],
    );
  });

  test('needs a js-ok reason', () {
    expect(_check(['list.sort(); // js-ok:', '// js-ok']), [
      'error: a.dart:2: write the site as "// js-ok: <reason>".',
      'error: a.dart:3: write the site as "// js-ok: <reason>".',
      startsWith('error: a.dart:2: .sort(:'),
    ]);
  });

  test('examines the files whose header block names a js project', () {
    const portOnly = '// Original code, not ported from Chart.js: a test.';
    const unknown =
        '// Ported from moment 2.29.4 src/moment.js (MIT, JS Foundation).';
    expect(_check(['x.round();'], header: portOnly), isEmpty);
    expect(_check(['x.round();'], header: _fdlibm), isEmpty);
    expect(_check(['x.round();'], header: '// Other.'), isEmpty);
    expect(_check(['x.round();'], header: _kurkle), hasLength(1));
    expect(_check(['x.round();'], header: unknown), hasLength(1));
    expect(_check([_ported, 'x.round();'], header: _fdlibm), [
      startsWith('error: a.dart:3: .round():'),
    ]);
    expect(
      checkJsSemanticsText(
        '$_fdlibm\nx.round();',
        'a.dart',
        [],
        languages: _languages,
      ),
      isFalse,
    );
  });

  test('flags the interpolation of double and num values', () async {
    final tree = FileTree()
      ..write('lib/a.dart', [
        _ported,
        r"String a(double size, String family) => '${size}px $family';",
        r"String b(num n, int i, String s) => 'n $n i $i s $s';",
        r"String c(double? v) => 'v $v ${v ?? 0}';",
        r"String d(List<double> l) => '${l.length} ${l.first.isNaN}';",
      ]);
    final sites = await resolvedSites([tree.path('lib/a.dart')]);
    expect(
      [for (final site in sites[tree.path('lib/a.dart')]!) site.line],
      [2, 3, 4, 4],
    );
    expect(sites.values.first.first.name, 'number interpolation');
    expect(await resolvedSites(const []), isEmpty);
  });

  test('flags dart:math max and min with num operands', () async {
    final tree = FileTree()
      ..write('lib/a.dart', [
        _ported,
        "import 'dart:math' as math;",
        "import 'dart:math' show max, min;",
        'double a(double x, double y) => math.max(x, y);',
        'num b(int i, double y) => math.min(i, y);',
        'double c(double x) => min<double>(x, 1);',
        'double d(List<double> l) => l.fold(double.infinity, math.min);',
        'int e(int i, int j) => math.max(i, j) + max<int>(0, j);',
        'int f(List<int> l) => l.fold(0, math.max);',
        'double g(double x, double y) => max(x, y);',
        'num h(double x) => max(0, x);',
        'num i(List<num> l) => l.fold(0, math.max);',
        'double j(double x) => math.max(0.0, x);',
      ]);
    final sites = await resolvedSites([tree.path('lib/a.dart')]);
    expect(
      [
        for (final site in sites[tree.path('lib/a.dart')]!)
          '${site.line} ${site.name}',
      ],
      ['5 min(', '11 max(', '12 max('],
    );
    expect(
      sites.values.first.first.message,
      contains('Call min<double> or give it double operands'),
    );
  });

  test('examines lib/ and test/ of a package', () async {
    final tree = FileTree()
      ..write('pubspec.yaml', ['name: flutter_chartjs_port'])
      ..write('tool/port_sources.yaml', _portSources)
      ..write('lib/src/a.dart', [_ported, 'final a = x.round();'])
      ..write('lib/src/b.dart', ['// Original code, not ported: x.', 'x % 2;'])
      ..write('lib/src/js/fdlibm_log.dart', [_fdlibm, 'final c = 1 % 2;'])
      ..write('lib/src/c.dart', [_ported, r"String c(double x) => '$x';"])
      ..write('test/specs/a_test.dart', [_ported, 'list.sort();'])
      ..write('tool/a.dart', [_ported, 'list.sort();']);
    final result = await checkJsSemantics([tree.root], base: tree.root);
    expect(result.files, 3);
    expect(result.findings.map((f) => '${f.path}:${f.line}'), [
      'lib/src/a.dart:2',
      'lib/src/c.dart:2',
      'test/specs/a_test.dart:2',
    ]);
    expect(result.findings[1].message, startsWith('number interpolation:'));

    tree.delete('tool/port_sources.yaml');
    final missing = await checkJsSemantics([tree.root], base: tree.root);
    expect(missing.files, 4);
    expect(
      describeFindings(missing.findings),
      contains(startsWith('error: tool/port_sources.yaml: Cannot open')),
    );
  });

  test('merges the languages of the source lists of the packages', () async {
    const home = 'packages/flutter_chartjs_port';
    const zoom = 'packages/flutter_chartjs_plugin_zoom_port';
    const zoomHeader =
        '// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/utils.ts '
        '(MIT, chartjs-plugin-zoom contributors).';
    const cHeader = '// Ported from zoom-c 1.0 a.c (MIT, A).';
    final tree = FileTree()
      ..write('$home/pubspec.yaml', ['name: flutter_chartjs_port'])
      ..write('$home/tool/port_sources.yaml', _portSources)
      ..write('$home/lib/src/a.dart', [_ported, 'final a = 1.5.round();'])
      ..write('$zoom/pubspec.yaml', ['name: flutter_chartjs_plugin_zoom_port'])
      ..write('$zoom/tool/port_sources.yaml', [
        'marker: zoom',
        'host: flutter_chartjs_port',
        'sources:',
        '  - header: chartjs-plugin-zoom',
        '    version: "v2.2.0+fb81d331"',
        '    url: https://github.com/chartjs/chartjs-plugin-zoom',
        '    language: js',
        '    spdx: MIT',
        '    holder: chartjs-plugin-zoom contributors',
        '    pin:',
        '      kind: copy',
        '      path: third_party/chartjs-plugin-zoom',
        '    targets:',
        '      - source: src/',
        '        dart: $zoom/lib/src/',
        // The first source list of a project counts: fdlibm stays c.
        '  - header: fdlibm',
        '    version: "5.3"',
        '    url: https://www.netlib.org/fdlibm/',
        '    language: js',
        '    spdx: SunPro',
        '    holder: Sun Microsystems, Inc.',
        '    pin:',
        '      kind: copy',
        '      path: third_party/fdlibm',
        '    targets:',
        '      - source: e_log.c',
        '        dart: $zoom/lib/src/fdlibm.dart',
        '  - header: zoom-c',
        '    version: "1.0"',
        '    url: https://example.com/zoom-c',
        '    language: c',
        '    spdx: MIT',
        '    holder: A',
        '    pin:',
        '      kind: copy',
        '      path: third_party/zoom-c',
        '    targets:',
        '      - source: a.c',
        '        dart: $zoom/lib/src/c.dart',
      ])
      ..write('$zoom/lib/src/utils.dart', [zoomHeader, 'final b = 1 % 2;'])
      ..write('$zoom/lib/src/fdlibm.dart', [_fdlibm, 'final c = 1 % 2;'])
      ..write('$zoom/lib/src/c.dart', [cHeader, 'final d = 1 % 2;'])
      ..write('$zoom/test/specs/utils_test.dart', [
        zoomHeader,
        r"String e(double x) => '$x';",
      ]);
    final result = await checkJsSemantics([
      tree.path(home),
      tree.path(zoom),
    ], base: tree.root);
    expect(result.files, 3);
    // The findings are in path order.
    expect(describeFindings(result.findings), [
      startsWith('error: $zoom/lib/src/utils.dart:2: %:'),
      allOf(
        startsWith('error: $zoom/test/specs/utils_test.dart:2: number '),
        contains('Use jsNumberToString of $jsRuntime'),
        contains('package:flutter_chartjs_port/js_semantics.dart'),
      ),
      startsWith('error: $home/lib/src/a.dart:2: .round():'),
    ]);

    // Without its source list, the add-on is no finding: its projects count
    // as js.
    tree.delete('$zoom/tool/port_sources.yaml');
    final unlisted = await checkJsSemantics([
      tree.path(home),
      tree.path(zoom),
    ], base: tree.root);
    expect(unlisted.findings, hasLength(4));
    expect(unlisted.files, 4);
  });

  test('examines the harness package next to the home package', () async {
    const home = 'packages/flutter_chartjs_port';
    const harness = 'packages/chartjs_test_utils';
    const testUtils =
        '// Ported from chartjs-test-utils v0.4.0 src/matchers.js '
        '(MIT, chartjs-test-utils Contributors).';
    final tree = FileTree()
      ..write('$home/pubspec.yaml', ['name: flutter_chartjs_port'])
      ..write('$home/tool/port_sources.yaml', [
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
      ..write('$home/lib/src/a.dart', [_ported, 'final a = 1.0;'])
      ..write('$harness/pubspec.yaml', ['name: chartjs_test_utils'])
      ..write('$harness/lib/pure.dart', [
        '// Original code, not ported from Chart.js: x.',
        'final b = 3 % 2;',
      ])
      ..write('$harness/lib/src/matchers.dart', [
        testUtils,
        'final c = (1.5 - 0.5).abs().round();',
        'final d = 3 % 2;',
      ]);
    final packages = withHarnessPackage([tree.path(home)]);
    expect(packages, [tree.path(home), tree.path(harness)]);
    final result = await checkJsSemantics(packages, base: tree.root);
    expect(result.files, 2);
    expect(result.findings.map((f) => '${f.path}:${f.line}'), [
      '$harness/lib/src/matchers.dart:2',
      '$harness/lib/src/matchers.dart:3',
    ]);
  });
}
