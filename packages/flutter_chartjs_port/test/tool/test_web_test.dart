// Original code, not ported from Chart.js: browser test discovery regression.
@TestOn('vm')
library;

import 'package:test/test.dart';

import '../../tool/test_web.dart';
import 'file_tree.dart';

void main() {
  test('selects browser tests before Flutter compiles VM-only imports', () {
    final tree = FileTree()
      ..write('test/core_test.dart', ["import 'dart:ui';"])
      ..write('test/tool_test.dart', [
        "@TestOn('vm')",
        'library;',
        "import 'dart:io';",
      ])
      ..write('test/data.dart', ['const data = 1;'])
      ..write('test/other_test.dart', ["// @TestOn('vm') is only a comment"]);
    expect(browserTestFiles(tree.root), [
      'test/core_test.dart',
      'test/other_test.dart',
    ]);
  });
}
