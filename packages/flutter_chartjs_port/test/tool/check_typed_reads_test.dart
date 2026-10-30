// Original code, not ported from Chart.js: tests of tool 9, the read ratchet.
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

import '../../tool/check_typed_reads.dart' as command;
import '../../tool/src/typed_reads.dart';
import 'file_tree.dart';

/// The sites of the Dart [lines] as `<line> <form>`.
List<String> _sites(List<String> lines) => [
  for (final site in findByNameSites(lines.join('\n'))) site.toString(),
];

/// Counts with the [forms] by name.
FormCounts _counts(Map<String, int> forms) {
  final counts = FormCounts();
  for (final MapEntry(key: name, value: count) in forms.entries) {
    counts[ByNameForm.values.byName(name)] = count;
  }
  return counts;
}

void main() {
  group('findByNameSites', () {
    test('counts the calls by their whole names', () {
      expect(
        _sites([
          "final a = jsGet(o, 'k');",
          'final b = js.jsGet (o, k);',
          'final c = jsGetKey(item, axis);',
          'final d = jsGetIndex(list, 0);',
          'final e = jsCall(f, [a]) ?? jsCall1(f, a);',
          'final f = jsObjectKeys(map);',
          r'final g = myjsGet(o) ?? jsGetter(o) ?? $jsGet(o) ?? jsGet_(o);',
          'final h = jsGet;',
          'final i = jsGet(jsGet(o, a), b);',
          'Object? jsGet(Object? object, Object? key) => null;',
        ]),
        [
          '1 jsGet',
          '2 jsGet',
          '3 jsGetKey',
          '5 jsCall',
          '5 jsCall',
          '6 jsObjectKeys',
          '9 jsGet',
          '9 jsGet',
          '10 jsGet',
        ],
      );
    });

    test('skips comments and string contents, not interpolated code', () {
      expect(
        _sites([
          "// jsGet(o, k) and x['a']",
          '/* jsCall(f) */ /// jsObjectKeys(m)',
          '''final s = "jsGet(o, k) x['a']";''',
          r"final t = '$jsGet(o) ${jsGet(o, 'k')} ${x['a']}';",
          'final u = """',
          'jsGetKey(a, b)',
          '""";',
        ]),
        ['4 jsGet', '4 stringIndex'],
      );
    });

    test('counts an index whose content is one string literal', () {
      expect(
        _sites([
          "a['x'];",
          'a["x"] = 1;',
          r"a[r'$shared'];",
          "a['x']['y'];",
          "a?['x'];",
          "a!['x'];",
          "f()['x'];",
          "this['x'];",
          "a[ 'x' ];",
          "a['x' 'y'];",
          r"a['$k'] ?? a['k${i + 1}'];",
          'a',
          "  ..['x'] = 1",
          "  ?..['y'] = 2;",
          "list[0]['x'];",
        ]),
        [
          '1 stringIndex',
          '2 stringIndex',
          '3 stringIndex',
          '4 stringIndex',
          '4 stringIndex',
          '5 stringIndex',
          '6 stringIndex',
          '7 stringIndex',
          '8 stringIndex',
          '9 stringIndex',
          '10 stringIndex',
          '11 stringIndex',
          '11 stringIndex',
          '13 stringIndex',
          '14 stringIndex',
          '15 stringIndex',
        ],
      );
    });

    test('skips list literals, spreads, map keys and other indexes', () {
      expect(
        _sites([
          "final a = ['x'];",
          "final b = <String>['x'];",
          "final c = [...['x'], ...?['y']];",
          "if (!['x'].contains(k)) {}",
          "final d = flag ? ['x'] : ['y'];",
          "final e = {'x': 1};",
          "final f = a[key] ?? a[0] ?? a['x' + y] ?? a[k('x')];",
          "return['x'];",
          "for (final k in['x']) {}",
          "final g = [['x']];",
          "final h = ['x', 'y'];",
          'Object? operator [](Object? key) => null;',
        ]),
        isEmpty,
      );
    });

    test('counts MapBase, MapMixin and Map in the class clauses', () {
      expect(
        _sites([
          'class A extends MapBase<String, Object?> {}',
          'class B extends collection.MapBase<String, Object?> implements C {}',
          'class D with MapMixin<String, Object?> {}',
          'class E extends Object',
          '    with F, MapMixin<String, Object?>',
          '    implements G<int, int>, Map<String, Object?> {}',
          'abstract class H implements Map {}',
          'class I implements HashMap<int, int>, MapBase<int, int>, Mapper {}',
          'class J extends MapBaseX with MapMixinX implements MapX {}',
          'class K = L with MapMixin<int, int> implements Map<int, int>;',
          '// class M extends MapBase implements Map {}',
        ]),
        [
          '1 extendsMapBase',
          '2 extendsMapBase',
          '3 withMapMixin',
          '5 withMapMixin',
          '6 implementsMap',
          '7 implementsMap',
          '10 withMapMixin',
          '10 implementsMap',
        ],
      );
    });

    test('sums the sites by form', () {
      final counts = countByNameForms(
        "final a = jsGet(o, 'k') ?? o['k'] ?? jsGet(o, 'j');",
      );
      expect(counts.nonZero, {'jsGet': 2, 'stringIndex': 1});
      expect(counts.isZero, isFalse);
      expect(countByNameForms('const a = 1;').isZero, isTrue);
      expect(
        counts.toString(),
        'jsGet 2, jsGetKey 0, stringIndex 1, jsCall 0, jsObjectKeys 0, '
        'extendsMapBase 0, withMapMixin 0, implementsMap 0',
      );
    });
  });

  group('baselines', () {
    test('list the counts above 0 in the form order', () {
      final counts = _counts({
        'implementsMap': 1,
        'jsGet': 12,
        'stringIndex': 3,
      });
      expect(
        formatBaseline(counts),
        'jsGet 12\nstringIndex 3\nimplementsMap 1\n',
      );
      expect(parseBaseline(formatBaseline(counts)).nonZero, counts.nonZero);
      expect(formatBaseline(FormCounts()), '');
      expect(parseBaseline('').isZero, isTrue);
      expect(parseBaseline('# a note\r\n\r\njsCall 2\r\n').nonZero, {
        'jsCall': 2,
      });
    });

    test('reject lines that do not parse', () {
      for (final (text, message) in [
        ('jsGet 1\njsGet x\n', 'line 2: the line is not "<form> <count>".'),
        ('jsGet  1\n', 'line 1: the line is not "<form> <count>".'),
        ('jsget 1\n', startsWith('line 1: unknown form "jsget"; the forms')),
        ('jsGet 1\njsGet 2\n', 'line 2: a second line of jsGet.'),
        ('jsGet 0\n', startsWith('line 1: the count of jsGet is 0')),
      ]) {
        expect(
          () => parseBaseline(text),
          throwsA(
            isA<BaselineFormatException>().having(
              (e) => e.toString(),
              'toString',
              message,
            ),
          ),
          reason: text,
        );
      }
    });
  });

  group('compareTypedReads', () {
    test('fails above a baseline and on a bad or stale baseline', () {
      final report = compareTypedReads(
        {
          'z.dart': _counts({'jsGet': 1}),
          'a.dart': _counts({'jsGet': 2, 'stringIndex': 1}),
          'b/c.dart': _counts({'jsCall': 1}),
          'd.dart': FormCounts(),
        },
        {
          'a.dart.txt': 'jsGet 1\nstringIndex 3\n',
          'z.dart.txt': 'jsGet 1\nbad\n',
          'gone.dart.txt': 'jsGet 1\n',
          'js/js_object.dart.txt': 'jsGet 1\n',
          'notes.md': 'x\n',
        },
        sourcePrefix: 'p/lib/src/',
        baselinePrefix: 'p/tool/typed_reads/',
      );
      expect(describeFindings(report.findings), [
        'error: p/lib/src/a.dart: jsGet 2 > baseline 1',
        equals(
          'warning: p/lib/src/a.dart: stringIndex 1 < baseline 3; run with '
          '--update to lower it',
        ),
        'error: p/lib/src/b/c.dart: jsCall 1 > baseline 0',
        equals(
          'error: p/tool/typed_reads/z.dart.txt:2: the line is not '
          '"<form> <count>".',
        ),
        equals(
          'error: p/tool/typed_reads/gone.dart.txt: stale baseline: '
          'p/lib/src/gone.dart is not a counted file (it does not exist, or '
          'it is under p/lib/src/js/ or p/lib/src/options/); run with '
          '--update to delete it',
        ),
        equals(
          'error: p/tool/typed_reads/js/js_object.dart.txt: stale baseline: '
          'p/lib/src/js/js_object.dart is not a counted file (it does not '
          'exist, or it is under p/lib/src/js/ or p/lib/src/options/); run '
          'with --update to delete it',
        ),
        equals(
          'error: p/tool/typed_reads/notes.md: not a baseline: the name does '
          'not end with .txt; run with --update to delete it',
        ),
      ]);
      expect(report.errors, 6);
      expect(report.passed, isFalse);
      expect(report.files, 4);
      expect(report.totals.nonZero, {
        'jsGet': 3,
        'stringIndex': 1,
        'jsCall': 1,
      });
    });

    test('passes at or below the baselines', () {
      final report = compareTypedReads(
        {
          'a.dart': _counts({'jsGet': 2}),
          'b.dart': FormCounts(),
        },
        {'a.dart.txt': 'jsGet 2\n', 'b.dart.txt': 'jsGetKey 1\n'},
      );
      expect(describeFindings(report.findings), [
        equals(
          'warning: lib/src/b.dart: jsGetKey 0 < baseline 1; run with --update '
          'to lower it',
        ),
      ]);
      expect(report.passed, isTrue);
    });

    test('names the baseline of each file with a form', () {
      expect(
        baselineFiles({
          'b.dart': _counts({'jsCall': 1}),
          'a/a.dart': _counts({'jsGet': 2, 'implementsMap': 1}),
          'c.dart': FormCounts(),
        }),
        {
          'a/a.dart.txt': 'jsGet 2\nimplementsMap 1\n',
          'b.dart.txt': 'jsCall 1\n',
        },
      );
    });
  });

  group('files', () {
    late FileTree tree;

    setUp(() {
      tree = FileTree()
        ..write('pubspec.yaml', ['name: p'])
        ..write('lib/src/core/a.dart', ["final x = jsGet(o, 'k');"])
        ..write('lib/src/b.dart', ['const b = 1;'])
        ..write('lib/src/c.txt', ["o['k']"])
        ..write('lib/src/js/js_object.dart', ["final y = jsGet(o, 'k');"])
        ..write('lib/src/options/o.dart', ["final z = o['k'];"])
        ..write('lib/flutter_chartjs_port.dart', ["final w = o['k'];"]);
    });

    test('count the Dart files of lib/src without js/ and options/', () {
      final counts = scanPackage(tree.root);
      expect(counts.keys, ['b.dart', 'core/a.dart']);
      expect(counts['core/a.dart']!.nonZero, {'jsGet': 1});
      expect(counts['b.dart']!.isZero, isTrue);
      expect(isCountedSource('js/js_object.dart'), isFalse);
      expect(isCountedSource('options/a.dart'), isFalse);
      expect(isCountedSource('core/jsx/a.dart'), isTrue);
    });

    test('write, keep and delete the baselines', () {
      tree
        ..write('tool/typed_reads/gone.dart.txt', ['jsGet 1'])
        ..write('tool/typed_reads/old/old.dart.txt', ['jsGet 1'])
        ..write('tool/typed_reads/b.dart.txt', ['jsGet 1']);
      var result = writeBaselines(tree.root, scanPackage(tree.root));
      expect(result, (written: 1, deleted: 3, unchanged: 0));
      expect(readBaselines(tree.root), {'core/a.dart.txt': 'jsGet 1\n'});
      expect(Directory(tree.path('tool/typed_reads/old')).existsSync(), false);

      result = writeBaselines(tree.root, scanPackage(tree.root));
      expect(result, (written: 0, deleted: 0, unchanged: 1));

      tree.write('lib/src/core/a.dart', ["final x = jsGet(o, 'k') ?? o['k'];"]);
      result = writeBaselines(tree.root, scanPackage(tree.root));
      expect(result, (written: 1, deleted: 0, unchanged: 0));
      expect(readBaselines(tree.root), {
        'core/a.dart.txt': 'jsGet 1\nstringIndex 1\n',
      });

      tree.write('lib/src/core/a.dart', ['const a = 1;']);
      result = writeBaselines(tree.root, scanPackage(tree.root));
      expect(result, (written: 0, deleted: 1, unchanged: 0));
      expect(readBaselines(tree.root), isEmpty);
      expect(Directory(tree.path('tool/typed_reads/core')).existsSync(), false);
    });
  });

  group('command', () {
    late FileTree tree;
    late String package;
    late StringBuffer out;

    setUp(() {
      tree = FileTree()
        ..write('packages/p/pubspec.yaml', ['name: p'])
        ..write('packages/p/lib/src/core/a.dart', [
          "final x = jsGet(o, 'k');",
          "final y = o['k'];",
        ])
        ..write('packages/p/lib/src/b.dart', ['const b = 1;'])
        ..write('packages/p/lib/src/js/js_object.dart', [
          'Object? jsGet(Object? o, Object? k) => null;',
        ]);
      package = tree.path('packages/p');
      out = StringBuffer();
    });

    /// Runs the command with [args] from the root of the tree, and returns
    /// the exit code. The output is in [out].
    int run(List<String> args) {
      out.clear();
      return command.run(args, out: out, base: tree.root);
    }

    test('ratchets the counts', () {
      expect(run([package]), 1);
      expect(
        out.toString(),
        'packages/p/lib/src/core/a.dart: jsGet 1 > baseline 0\n'
        'packages/p/lib/src/core/a.dart: stringIndex 1 > baseline 0\n'
        'check:typed-reads: failed, 2 files, 2 errors, 0 below the baseline; '
        'jsGet 1, jsGetKey 0, stringIndex 1, jsCall 0, jsObjectKeys 0, '
        'extendsMapBase 0, withMapMixin 0, implementsMap 0.\n',
      );

      expect(run(['--update', package]), 0);
      expect(
        out.toString(),
        'check:typed-reads --update: 2 files, 1 baselines written, 0 deleted, '
        '0 unchanged in packages/p/tool/typed_reads; jsGet 1, jsGetKey 0, '
        'stringIndex 1, jsCall 0, jsObjectKeys 0, extendsMapBase 0, '
        'withMapMixin 0, implementsMap 0.\n',
      );
      expect(
        File('$package/tool/typed_reads/core/a.dart.txt').readAsStringSync(),
        'jsGet 1\nstringIndex 1\n',
      );
      expect(run([package]), 0);
      expect(
        out.toString(),
        'check:typed-reads: passed, 2 files, 0 errors, 0 below the baseline; '
        'jsGet 1, jsGetKey 0, stringIndex 1, jsCall 0, jsObjectKeys 0, '
        'extendsMapBase 0, withMapMixin 0, implementsMap 0.\n',
      );

      tree.write('packages/p/lib/src/core/a.dart', [
        "final x = jsGet(o, 'k') ?? jsGet(o, 'j');",
      ]);
      expect(run([package]), 1);
      expect(
        out.toString(),
        'packages/p/lib/src/core/a.dart: jsGet 2 > baseline 1\n'
        'packages/p/lib/src/core/a.dart: stringIndex 0 < baseline 1; run with '
        '--update to lower it\n'
        'check:typed-reads: failed, 2 files, 1 errors, 1 below the baseline; '
        'jsGet 2, jsGetKey 0, stringIndex 0, jsCall 0, jsObjectKeys 0, '
        'extendsMapBase 0, withMapMixin 0, implementsMap 0.\n',
      );

      tree.delete('packages/p/lib/src/core/a.dart');
      expect(run([package]), 1);
      expect(
        out.toString(),
        'packages/p/tool/typed_reads/core/a.dart.txt: stale baseline: '
        'packages/p/lib/src/core/a.dart is not a counted file (it does not '
        'exist, or it is under packages/p/lib/src/js/ or '
        'packages/p/lib/src/options/); run with --update to delete it\n'
        'check:typed-reads: failed, 1 files, 1 errors, 0 below the baseline; '
        'jsGet 0, jsGetKey 0, stringIndex 0, jsCall 0, jsObjectKeys 0, '
        'extendsMapBase 0, withMapMixin 0, implementsMap 0.\n',
      );

      expect(run(['--update', package]), 0);
      expect(out.toString(), contains('0 baselines written, 1 deleted, 0 '));
      expect(run([package]), 0);
    });

    test('rejects bad arguments', () {
      expect(run(['--help']), 0);
      expect(out.toString(), startsWith('Usage: dart run tool/'));
      expect(run(['--fix']), 2);
      expect(
        out.toString(),
        startsWith(
          'check:typed-reads: unexpected argument --fix\n',
        ),
      );
      expect(run([package, package]), 2);
      expect(run([tree.path('packages')]), 2);
      expect(out.toString(), endsWith('has no pubspec.yaml\n'));
    });

    test('prints the paths relative to the base folder', () {
      out.clear();
      expect(command.run([package], out: out, base: package), 1);
      expect(
        out.toString(),
        startsWith('lib/src/core/a.dart: jsGet 1 > baseline 0\n'),
      );
    });
  });
}
