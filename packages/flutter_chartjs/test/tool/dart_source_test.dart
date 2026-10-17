// Original code, not ported from Chart.js: tests of tool/src/dart_source.dart.
@TestOn('vm')
library;

import 'package:test/test.dart';

import '../../tool/src/dart_source.dart';
import '../../tool/src/headers.dart';

void main() {
  group('DartSource', () {
    test('blanks comments and keeps offsets and lines', () {
      const text =
          'var a = 1; // one\n'
          '/* two /* nested */ still */ var b = 2;\n'
          '/// three\n';
      final source = DartSource(text);
      expect(source.code.length, text.length);
      expect(source.code.split('\n'), [
        'var a = 1;       ',
        '                             var b = 2;',
        '         ',
        '',
      ]);
      expect(
        [for (final c in source.comments) (c.line, c.text)],
        [
          (1, '// one'),
          (2, '/* two /* nested */ still */'),
          (3, '/// three'),
        ],
      );
      expect(source.comments.map((c) => c.isLineComment), [true, false, true]);
    });

    test('blanks string contents and keeps interpolated code', () {
      final source = DartSource(
        r"f('a % b ${x.round()} $y', "
        '"c // d");',
      );
      expect(source.code, contains('.round()'));
      expect(source.code, contains(r'$y'));
      expect(source.code, isNot(contains('%')));
      expect(source.code, isNot(contains('//')));
      expect(source.comments, isEmpty);
    });

    test('reads raw strings, escapes and triple quotes', () {
      final source = DartSource(
        "a(r'\\'); b('\\''); c('''\n"
        '// Ported from x\n'
        "'''); d.round();\n",
      );
      expect(source.comments, isEmpty);
      expect(source.code, contains('d.round()'));
      expect(source.code, isNot(contains('Ported')));
      expect(source.strings.map(source.contentOf), [
        r'\',
        r"\'",
        '\n// Ported from x\n',
      ]);
    });

    test('reads nested strings in interpolations', () {
      final source = DartSource(r"""x = 'a ${m['k'] /* c */} b';""");
      expect(source.comments.single.text, '/* c */');
      expect([for (final s in source.strings) s.nested], [true, false]);
    });

    test('ends an unterminated string at the line end', () {
      final source = DartSource("x = 'open\ny.round(); // c\n");
      expect(source.code, contains('y.round()'));
      expect(source.comments.single.line, 2);
    });

    test('gives 1-based lines and strips carriage returns', () {
      final source = DartSource('a\r\nb // c\r\n\r\nd');
      expect(source.lines, ['a', 'b // c', '', 'd']);
      expect(source.lineOf(0), 1);
      expect(source.lineOf(3), 2);
      expect(source.lineOf(source.text.length - 1), 4);
      expect(source.comments.single.text, '// c');
    });
  });

  group('DartSource.directives', () {
    test('reads imports, exports and configurations', () {
      final source = DartSource(
        "// import 'dart:io';\n"
        "import 'dart:math' as math;\n"
        "import 'package:a/a.dart' show A;\n"
        "import 'package:b/b.dart' deferred as b_alias show B;\n"
        "export 'src/b.dart'\n"
        "    if (dart.library.io == 'true') 'src/b_io.dart'\n"
        "    if (dart.library.js_interop) 'src/b_web.dart';\n"
        "final s = '''\n"
        "import 'dart:html';\n"
        "''';\n",
      );
      expect(
        [
          for (final d in source.directives)
            '${d.keyword} ${d.uris.join(' ')} ${d.line} ${d.prefix}',
        ],
        [
          'import dart:math 2 math',
          'import package:a/a.dart 3 null',
          'import package:b/b.dart 4 b_alias',
          'export src/b.dart src/b_io.dart src/b_web.dart 5 null',
        ],
      );
    });

    test("reads the @TestOn('vm') annotation", () {
      expect(DartSource("@TestOn('vm')\nlibrary;\n").isVmOnly, isTrue);
      expect(DartSource('@TestOn("vm")\nlibrary;\n').isVmOnly, isTrue);
      expect(DartSource("@TestOn('browser')\nlibrary;\n").isVmOnly, isFalse);
      expect(DartSource("// @TestOn('vm')\nlibrary;\n").isVmOnly, isFalse);
      expect(DartSource('library;\n').testOn, isNull);
    });
  });

  group('Header.parse', () {
    const chartJs =
        '// Ported from Chart.js v4.5.1 src/helpers/helpers.dom.ts '
        '(MIT, Chart.js Contributors).';
    const backport =
        '// Upstream backport: chartjs/Chart.js@2898a6d1 (#12142).';

    test('reads a Chart.js header block', () {
      final header = Header.parse([chartJs, backport, '', 'code']);
      expect(header.kind, HeaderKind.ported);
      expect(header.isChartJsPort, isTrue);
      expect(header.lastLine, 2);
      final portedFrom = header.portedFrom.single;
      expect(
        [
          portedFrom.project,
          portedFrom.version,
          portedFrom.path,
          portedFrom.license,
          portedFrom.holder,
        ],
        [
          'Chart.js',
          'v4.5.1',
          'src/helpers/helpers.dom.ts',
          'MIT',
          'Chart.js Contributors',
        ],
      );
      expect(header.backports.single.sha, '2898a6d1');
      expect(header.backports.single.pr, 12142);
    });

    test('reads a holder with a comma', () {
      final header = Header.parse([
        '// Ported from fdlibm 5.3 e_log.c (SunPro, Sun Microsystems, Inc.).',
        '// Ported from fdlibm 5.3 e_log10.c (SunPro, Sun Microsystems, Inc.).',
      ]);
      expect(header.portedFrom.map((p) => p.holder), [
        'Sun Microsystems, Inc.',
        'Sun Microsystems, Inc.',
      ]);
      expect(header.isChartJsPort, isFalse);
    });

    test('reports malformed lines of the block', () {
      final header = Header.parse([
        chartJs,
        '// Ported from Chart.js 4.5 helpers.ts',
        '// Upstream backport: chartjs/Chart.js@2898a6d (#12142).',
        '// Upstream backport: chartjs/Chart.js@2898a6d1 (#12142).',
      ]);
      expect(header.malformed, [2, 3]);
      expect(header.lastLine, 4);
    });

    test('reads the port-only marker', () {
      final header = Header.parse([
        '// Original code, not ported from Chart.js: a reason.',
        chartJs,
      ]);
      expect(header.kind, HeaderKind.portOnly);
      expect(header.portOnlyReason, 'a reason');
      expect(header.lastLine, 1);
    });

    test('rejects other first lines', () {
      for (final first in [
        '',
        '/// Docs.',
        '// Original code, not ported from Chart.js: .',
        '// Original code, not ported from Chart.js: no full stop',
        '// Ported from Chart.js v4.5.1 src/a.ts (MIT).',
      ]) {
        expect(Header.parse([first]).kind, HeaderKind.missing, reason: first);
      }
    });
  });
}
