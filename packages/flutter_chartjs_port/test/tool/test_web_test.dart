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

  group('isPassedSummary', () {
    test('accepts the summary of a run that passed', () {
      expect(isPassedSummary('00:12 +561: All tests passed!'), isTrue);
      expect(isPassedSummary('01:02 +959 ~77: All tests passed!'), isTrue);
      expect(isPassedSummary('00:00 ~3: All tests skipped.'), isTrue);
      expect(
        isPassedSummary('\x1B[32m00:12 +561\x1B[0m: All tests passed!'),
        isTrue,
      );
    });

    test('accepts the summary of the GitHub reporter', () {
      expect(isPassedSummary('🎉 4375 tests passed, 2 skipped.'), isTrue);
      expect(isPassedSummary('🎉 55 tests passed.'), isTrue);
      expect(isPassedSummary('🎉 1 test passed.'), isTrue);
      expect(isPassedSummary('🎉 0 tests passed, 3 skipped.'), isTrue);
      expect(
        isPassedSummary('::error::4370 tests passed, 5 failed, 2 skipped.'),
        isFalse,
      );
      expect(
        isPassedSummary('✅ test/a_test.dart: 🎉 1 test passed.'),
        isFalse,
      );
    });

    test('rejects a failed run, a progress line and other output', () {
      expect(isPassedSummary('00:30 +2 -1: Some tests failed.'), isFalse);
      expect(
        isPassedSummary('00:30 +2 -1: switch over a double [E]'),
        isFalse,
      );
      expect(
        isPassedSummary('00:00 +2: test/a_test.dart: All tests passed!'),
        isFalse,
      );
      expect(isPassedSummary('All tests passed!'), isFalse);
    });
  });

  group('legFailure', () {
    test('passes an exit with 0 after the summary', () {
      expect(legFailure(0, sawSummary: true), isNull);
    });

    test('fails an exit with 0 without the summary', () {
      // `flutter test` exits with 0 when a SIGTERM stops a run that hangs.
      expect(
        legFailure(0, sawSummary: false),
        'exited with 0 without the summary of a run',
      );
    });

    test('fails an exit by a signal and a non-zero exit', () {
      expect(legFailure(-15, sawSummary: false), 'ended by the signal 15');
      expect(legFailure(-9, sawSummary: true), 'ended by the signal 9');
      expect(legFailure(1, sawSummary: false), 'exited with 1');
      expect(legFailure(79, sawSummary: true), 'exited with 79');
    });
  });
}
