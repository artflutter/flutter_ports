// Original code, not ported from Chart.js: tests of tool 3, the JS check.
@TestOn('vm')
library;

import 'package:test/test.dart';

import '../../tool/src/check_support.dart';
import '../../tool/src/js_semantics.dart';
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
        '3 .roundToDouble()',
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
        'final a = jsRound(x) + x.floorToDouble() + x.ceilToDouble();',
        'final b = x.remainder(2) + math.sqrt(x) + math.pi + jsLog10(x);',
        'final c = jsAtan2(y, x) + isInt + x.sortKey + power(2) + sinh(x);',
        'jsSort(list, compare);',
      ]),
      isEmpty,
    );
  });

  test('flags the transcendental dart:math functions', () {
    expect(
      _sites([
        "import 'dart:math' as math;",
        'final a = math.sin(t) + math.cos(t) + math . tan(t);',
        'final b = math.asin(t) + math.acos(t) + math.atan(t);',
        'final c = math.atan2(t, 1) + math.exp(t) + math.log(t);',
        'final d = other.sin(t) + jsAtan2(t, 1) + mathx.log(t);',
      ]),
      [
        '3 math.sin(',
        '3 math.cos(',
        '3 math.tan(',
        '4 math.asin(',
        '4 math.acos(',
        '4 math.atan(',
        '5 math.atan2(',
        '5 math.exp(',
        '5 math.log(',
      ],
    );
    expect(
      _sites([
        "import 'dart:math';",
        'final a = sin(t) + x.cos(t) + log(t);',
      ]),
      ['3 sin(', '3 log('],
    );
    expect(_sites(['final a = math.sin(t) + log(t);']), isEmpty);
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
    final sites = await numberInterpolationSites([tree.path('lib/a.dart')]);
    expect(
      [for (final site in sites[tree.path('lib/a.dart')]!) site.line],
      [2, 3, 4, 4],
    );
    expect(sites.values.first.first.name, 'number interpolation');
    expect(await numberInterpolationSites(const []), isEmpty);
  });

  test('examines lib/ and test/ of a package', () async {
    final tree = FileTree()
      ..write('pubspec.yaml', ['name: flutter_chartjs'])
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
}
