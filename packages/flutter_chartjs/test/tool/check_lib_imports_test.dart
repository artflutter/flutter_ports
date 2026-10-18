// Original code, not ported from Chart.js: tests of tool 1, the import guard.
@TestOn('vm')
library;

import 'package:test/test.dart';

import '../../tool/src/lib_imports.dart';
import 'file_tree.dart';

const String _ported =
    '// Ported from Chart.js v4.5.1 src/helpers/helpers.math.ts '
    '(MIT, Chart.js Contributors).';
const String _portOnly = '// Original code, not ported from Chart.js: a test.';

void main() {
  late FileTree tree;

  setUp(() {
    tree = FileTree()
      ..write('pubspec.yaml', ['name: flutter_chartjs'])
      ..write('lib/flutter_chartjs.dart', [
        _portOnly,
        'library;',
        "export 'src/upstream.dart';",
        "export 'package:flutter_chartjs/src/widget.dart';",
      ])
      ..write('lib/src/upstream.dart', [_portOnly, "const v = '4.5.1';"])
      ..write('lib/src/widget.dart', [
        _portOnly,
        "import 'dart:ui' as ui;",
        "import 'package:flutter/widgets.dart';",
        "import 'package:meta/meta.dart';",
      ])
      ..write('lib/src/js/js_math.dart', [
        _portOnly,
        "import 'dart:math' as math;",
        "import 'package:intl/intl.dart';",
      ])
      ..write('lib/src/helpers/helpers.math.dart', [
        _ported,
        "import 'package:flutter_chartjs/src/js/js_math.dart';",
        "import '../types/geometric.dart';",
      ])
      ..write('lib/src/types/geometric.dart', [_portOnly])
      ..write('test/specs/helpers.math_test.dart', [
        _ported,
        "import 'dart:typed_data';",
        "import 'package:flutter_chartjs/src/helpers/helpers.math.dart';",
        "import 'package:test/test.dart';",
        "import 'data.dart';",
      ])
      ..write('test/specs/data.dart', [_portOnly, "import 'dart:convert';"])
      ..write('test/vm_test.dart', [
        _portOnly,
        "@TestOn('vm')",
        'library;',
        "import 'dart:io';",
        "import 'package:flutter_chartjs/flutter_chartjs.dart';",
        "import 'package:flutter_test/flutter_test.dart';",
      ]);
  });

  List<String> run() => describeFindings(checkLibImports(tree.root).findings);

  test('passes a tree that keeps the rules', () {
    expect(run(), isEmpty);
    expect(checkLibImports(tree.root).files, 9);
  });

  test('rejects imports that lib/ never makes', () {
    tree.write('lib/src/widget.dart', [
      _portOnly,
      "import 'package:flutter/material.dart';",
      "import 'package:forui/forui.dart';",
      "import 'dart:io';",
      "import 'dart:js_interop';",
      "import 'package:web/web.dart';",
      "import 'package:collection/algorithms.dart';",
      "import 'package:flutter/animation.dart';",
    ]);
    expect(run(), [
      contains(
        'widget.dart:2: imports package:flutter/material.dart '
        '(Chart.js ADR 0001',
      ),
      contains(
        'widget.dart:3: imports package:forui/forui.dart '
        '(Chart.js ADR 0001',
      ),
      contains('widget.dart:4: imports dart:io (AGENTS.md rule 5'),
      contains('widget.dart:5: imports dart:js_interop (AGENTS.md rule 5'),
      contains('widget.dart:6: imports package:web/web.dart (AGENTS.md'),
      contains(
        'widget.dart:7: imports package:collection/algorithms.dart, '
        'which is not on the lib/ allowlist',
      ),
      contains(
        'widget.dart:8: imports package:flutter/animation.dart, '
        'which is not on the lib/ allowlist',
      ),
    ]);
  });

  test('allows package:collection/collection.dart in lib/ and pure layers', () {
    tree
      ..write('lib/src/js/js_array.dart', [
        _portOnly,
        "import 'package:collection/collection.dart' show mergeSort;",
      ])
      ..write('lib/src/helpers/helpers.core.dart', [
        _portOnly,
        "import 'package:collection/collection.dart' as c show mergeSort;",
        "import 'package:flutter_chartjs/src/js/js_array.dart';",
      ])
      ..write('lib/src/widget.dart', [
        _portOnly,
        "import 'package:collection/collection.dart'",
        '    show mergeSort;',
      ])
      ..write('test/port/js/js_array_test.dart', [
        _portOnly,
        "import 'package:flutter_chartjs/src/js/js_array.dart';",
        "import 'package:test/test.dart';",
      ]);
    expect(run(), isEmpty);
  });

  test(
    'imports package:collection/collection.dart only with show mergeSort',
    () {
      tree
        ..write('lib/src/js/js_array.dart', [
          _portOnly,
          "import 'package:collection/collection.dart';",
        ])
        ..write('lib/src/widget.dart', [
          _portOnly,
          "import 'package:collection/collection.dart' show mergeSort, sortBy;",
          "import 'package:collection/collection.dart' hide sortBy;",
        ]);
      const message =
          'imports package:collection/collection.dart without '
          '"show mergeSort" (Chart.js ADR 0010, Sort).';
      expect(run(), [
        'error: lib/src/js/js_array.dart:2: $message',
        'error: lib/src/widget.dart:2: $message',
        'error: lib/src/widget.dart:3: $message',
      ]);
    },
  );

  test('keeps the other package:collection libraries out of pure layers', () {
    tree.write('lib/src/js/js_array.dart', [
      _portOnly,
      "import 'package:collection/algorithms.dart';",
    ]);
    expect(run(), [
      equals(
        'error: lib/src/js/js_array.dart:2: imports '
        'package:collection/algorithms.dart, which is not on the lib/ '
        'allowlist (porting-flow.md 4, tool 1).',
      ),
      equals(
        'error: lib/src/js/js_array.dart:2: imports '
        'package:collection/algorithms.dart, but the file is in the pure '
        'layer (pure layers import only the pure allowlist, porting-flow.md '
        '3).',
      ),
    ]);
  });

  test('keeps own imports of lib/ inside lib/', () {
    tree.write('lib/src/widget.dart', [
      _portOnly,
      "import '../../tool/src/check.dart';",
      "import '../../../outside.dart';",
    ]);
    expect(run(), [
      equals(
        'error: lib/src/widget.dart:2: imports tool/src/check.dart, which is '
        'outside lib/ (porting-flow.md 4, tool 1).',
      ),
      equals(
        'error: lib/src/widget.dart:3: imports ../../../outside.dart, which '
        'is not on the lib/ allowlist (porting-flow.md 4, tool 1).',
      ),
    ]);
  });

  test('follows the pure layer through own imports', () {
    tree
      ..write('lib/src/helpers/helpers.canvas.dart', [
        _portOnly,
        "import '../canvas/context.dart';",
      ])
      ..write('lib/src/canvas/context.dart', [
        _portOnly,
        "import 'flutter_context.dart';",
      ])
      ..write('lib/src/canvas/flutter_context.dart', [
        _portOnly,
        "import 'dart:ui';",
      ]);
    expect(run(), [
      equals(
        'error: lib/src/canvas/flutter_context.dart:2: imports dart:ui, but '
        'the file is in the pure layer (reached from '
        'lib/src/helpers/helpers.canvas.dart -> lib/src/canvas/context.dart) '
        '(pure layers reach neither dart:ui nor package:flutter, '
        'porting-flow.md 3).',
      ),
    ]);
  });

  test('treats the core.defaults closure as pure', () {
    tree
      ..write('lib/src/core/core.defaults.dart', [
        _portOnly,
        "import 'package:flutter_chartjs/src/core/core.animations.dart';",
      ])
      ..write('lib/src/core/core.animations.dart', [
        _portOnly,
        "import 'package:flutter/scheduler.dart';",
      ])
      ..write('lib/src/core/core.controller.dart', [
        _portOnly,
        "import 'package:flutter/scheduler.dart';",
      ]);
    expect(run(), [
      startsWith(
        'error: lib/src/core/core.animations.dart:2: imports '
        'package:flutter/scheduler.dart, but the file is in the pure '
        'layer (reached from lib/src/core/core.defaults.dart)',
      ),
    ]);
  });

  test('excludes helpers.dom and helpers.extras from the roots', () {
    tree
      ..write('lib/src/helpers/helpers.dom.dart', [
        _portOnly,
        "import 'package:flutter/widgets.dart';",
      ])
      ..write('lib/src/helpers/helpers.extras.dart', [
        _portOnly,
        "import 'package:flutter/scheduler.dart';",
      ]);
    expect(run(), isEmpty);

    tree.write('lib/src/helpers/helpers.math.dart', [
      _ported,
      "import 'helpers.dom.dart';",
    ]);
    expect(run(), [
      contains(
        'lib/src/helpers/helpers.dom.dart:2: imports '
        'package:flutter/widgets.dart, but the file is in the pure layer '
        '(reached from lib/src/helpers/helpers.math.dart)',
      ),
    ]);
  });

  test('limits the tests that the web legs compile', () {
    tree
      ..write('test/a_test.dart', [
        _portOnly,
        "import 'package:flutter_chartjs/src/upstream.dart';",
        "import 'package:flutter_test/flutter_test.dart';",
        "import 'package:chartjs_test_utils/pure.dart';",
        "import 'package:chartjs_test_utils/chartjs_test_utils.dart';",
        "import 'support/io.dart';",
      ])
      ..write('test/support/io.dart', [_portOnly, "import 'dart:io';"]);
    expect(run(), [
      contains(
        'test/a_test.dart:2: imports lib/src/upstream.dart, which is '
        'not in the pure layer, but the file compiles for the web test '
        "legs. Add @TestOn('vm')",
      ),
      contains(
        'test/a_test.dart:3: imports '
        'package:flutter_test/flutter_test.dart, but the file compiles for '
        'the web test legs.',
      ),
      contains(
        'test/a_test.dart:5: imports '
        'package:chartjs_test_utils/chartjs_test_utils.dart, but',
      ),
      contains(
        'test/support/io.dart:2: imports dart:io, but the file '
        'compiles for the web test legs (reached from test/a_test.dart).',
      ),
    ]);

    tree.write('test/a_test.dart', [
      _portOnly,
      "@TestOn('vm')",
      'library;',
      "import 'package:flutter_test/flutter_test.dart';",
      "import 'support/io.dart';",
    ]);
    expect(run(), isEmpty);
  });

  test('checks each URI of a configurable import', () {
    tree.write('lib/src/js/js_number.dart', [
      _portOnly,
      "import 'js_math.dart'",
      "    if (dart.library.io) 'dart:io';",
    ]);
    expect(run(), [
      contains('lib/src/js/js_number.dart:2: imports dart:io (AGENTS.md'),
      contains(
        'lib/src/js/js_number.dart:2: imports dart:io, but the file '
        'is in the pure layer',
      ),
    ]);
  });

  test('keeps ported files away from lib/src/theme/', () {
    tree
      ..write('lib/src/theme/theme.dart', [_portOnly])
      ..write('lib/src/helpers/helpers.math.dart', [
        _ported,
        "import '../theme/theme.dart';",
      ])
      ..write('lib/src/widget.dart', [
        _portOnly,
        "import 'package:flutter_chartjs/src/theme/theme.dart';",
      ]);
    expect(run(), [
      equals(
        'error: lib/src/helpers/helpers.math.dart:2: imports '
        'lib/src/theme/theme.dart, but ported files never import '
        'lib/src/theme/ (Chart.js ADR 0001).',
      ),
    ]);
  });

  test('ignores directives in comments and strings', () {
    tree.write('lib/src/js/js_math.dart', [
      _portOnly,
      "// import 'dart:io';",
      "/* import 'dart:ui'; */",
      "const s = '''",
      "import 'dart:io';",
      "''';",
    ]);
    expect(run(), isEmpty);
  });

  group('harness package', () {
    late FileTree harness;

    setUp(() {
      harness = FileTree()
        ..write('pubspec.yaml', ['name: chartjs_test_utils'])
        ..write('lib/pure.dart', [
          _portOnly,
          "import 'dart:math';",
          "import 'package:test/test.dart';",
          "import 'package:flutter_chartjs/src/helpers/helpers.math.dart';",
          "import 'src/set_up.dart';",
        ])
        ..write('lib/src/set_up.dart', [
          _portOnly,
          "import 'package:test/scaffolding.dart';",
        ])
        ..write('lib/chartjs_test_utils.dart', [
          _portOnly,
          "import 'package:flutter_test/flutter_test.dart';",
        ]);
    });

    ({List<String> findings, int files}) runWithHarness() {
      final result = checkLibImports(
        tree.root,
        harnessDirectory: harness.root,
        harnessDisplayPrefix: 'h/',
      );
      return (findings: describeFindings(result.findings), files: result.files);
    }

    test('passes a pure.dart closure that keeps the rules', () {
      final result = runWithHarness();
      expect(result.findings, isEmpty);
      expect(result.files, 9 + 2);
    });

    test('keeps the pure.dart closure a pure layer', () {
      harness
        ..write('lib/pure.dart', [
          _portOnly,
          "import 'package:flutter/foundation.dart';",
          "import 'package:flutter_chartjs/src/widget.dart';",
          "import 'package:flutter_chartjs/flutter_chartjs.dart';",
          "import 'chartjs_test_utils.dart';",
          "import 'src/set_up.dart';",
        ])
        ..write('lib/src/set_up.dart', [_portOnly, "import 'dart:io';"]);
      expect(runWithHarness().findings, [
        equals(
          'error: h/lib/pure.dart:2: imports package:flutter/foundation.dart, '
          'but the file is in the pure layer of the harness (it imports only '
          'pure libraries, package:test and the pure layers of '
          'flutter_chartjs, porting-flow.md 3).',
        ),
        contains(
          'h/lib/pure.dart:3: imports package:flutter_chartjs/src/widget.dart, '
          'but',
        ),
        contains(
          'h/lib/pure.dart:4: imports '
          'package:flutter_chartjs/flutter_chartjs.dart, but',
        ),
        contains(
          'h/lib/chartjs_test_utils.dart:2: imports '
          'package:flutter_test/flutter_test.dart, but the file is in the '
          'pure layer of the harness (reached from lib/pure.dart)',
        ),
        contains(
          'h/lib/src/set_up.dart:2: imports dart:io, but the file is in the '
          'pure layer of the harness (reached from lib/pure.dart)',
        ),
      ]);
    });

    test('skips a harness without lib/pure.dart', () {
      harness.delete('lib/pure.dart');
      final result = runWithHarness();
      expect(result.findings, isEmpty);
      expect(result.files, 9);
    });
  });

  test('adds the display prefix to paths', () {
    tree.write('lib/src/js/js_math.dart', [_portOnly, "import 'dart:ui';"]);
    final findings = checkLibImports(
      tree.root,
      displayPrefix: 'packages/flutter_chartjs/',
    ).findings;
    expect(
      findings.single.path,
      'packages/flutter_chartjs/lib/src/js/js_math.dart',
    );
  });
}
