// Original code, not ported from Chart.js: tests of the check command line.
@TestOn('vm')
library;

import 'package:test/test.dart';

import '../../tool/src/check_support.dart';
import 'file_tree.dart';

void main() {
  group('runCheck', () {
    late FileTree tree;
    late StringBuffer out;
    List<String>? checked;

    setUp(() {
      tree = FileTree()..write('pubspec.yaml', ['name: p']);
      out = StringBuffer();
      checked = null;
    });

    Future<int> run(List<String> args, List<Finding> findings) => runCheck(
      args,
      name: 'check:x',
      usage: 'Usage: x',
      out: out,
      check: (packages) {
        checked = packages;
        return (findings: findings, files: 3);
      },
    );

    test('passes with warnings only', () async {
      final code = await run(
        [tree.root],
        [const Finding.warning('a.dart', 2, 'a warning.')],
      );
      expect(code, 0);
      expect(checked, [tree.root]);
      expect(out.toString().split('\n'), [
        'warning: a.dart:2: a warning.',
        'check:x: passed, 3 files, 0 errors, 1 warnings.',
        '',
      ]);
    });

    test('fails with an error', () async {
      final code = await run(
        [tree.root],
        [const Finding('a.dart', null, 'an error.')],
      );
      expect(code, 1);
      expect(out.toString(), startsWith('error: a.dart: an error.\n'));
      expect(out.toString(), contains('check:x: failed, 3 files, 1 errors'));
    });

    test('prints the usage', () async {
      expect(await run(['--help'], const []), 0);
      expect(out.toString(), 'Usage: x\n');
      expect(checked, isNull);
    });

    test('rejects unknown options and folders without a pubspec', () async {
      expect(await run(['--fix'], const []), 2);
      expect(out.toString(), startsWith('check:x: unknown option --fix\n'));
      tree.mkdir('empty');
      expect(await run([tree.path('empty')], const []), 2);
      expect(checked, isNull);
    });
  });

  group('paths', () {
    test('use / separators and normalize relative paths', () {
      expect(posixPath(r'C:\a\b\'), 'C:/a/b');
      expect(relativePath('/r', '/r/a/b.dart'), 'a/b.dart');
      expect(relativePath('/r', '/other/b.dart'), '/other/b.dart');
      expect(normalizeRelative('a/./b/../c.dart'), 'a/c.dart');
      expect(normalizeRelative('../a.dart'), isNull);
    });

    test('list Dart files without hidden and build folders', () {
      final tree = FileTree()
        ..write('lib/b.dart', [''])
        ..write('lib/a/a.dart', [''])
        ..write('lib/a/a.txt', [''])
        ..write('lib/.hidden/c.dart', [''])
        ..write('lib/build/d.dart', ['']);
      expect(
        dartFilesUnder(tree.path('lib')).map((f) => relativePath(tree.root, f)),
        ['lib/a/a.dart', 'lib/b.dart'],
      );
      expect(dartFilesUnder(tree.path('missing')), isEmpty);
    });

    test('find the closest folder with a marker file', () {
      final tree = FileTree()
        ..write('REUSE.toml', [''])
        ..mkdir('packages/p/lib');
      expect(
        findAncestorWith(tree.path('packages/p/lib'), 'REUSE.toml'),
        tree.root,
      );
      expect(
        findAncestorWith(tree.path('packages/p'), 'no-such-marker-file'),
        isNull,
      );
    });
  });
}
