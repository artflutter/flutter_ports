// Original code, not ported from Chart.js: tests of tool 8, the port order.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../tool/port_order.dart' as command;
import '../../tool/src/check_support.dart';
import '../../tool/src/port_order.dart';
import 'file_tree.dart';

const String _package = 'packages/flutter_chartjs_port';
const String _blob = 'https://github.com/chartjs/Chart.js/blob/v4.5.1/';

const List<String> _portSources = [
  'sources:',
  '  - header: Chart.js',
  '    version: "v4.5.1"',
  '    url: https://github.com/chartjs/Chart.js',
  '    language: js',
  '    spdx: MIT',
  '    holder: Chart.js Contributors',
  '    pin:',
  '      kind: submodule',
  '      path: third_party/Chart.js',
  '      ref: "v4.5.1"',
  '      commit: 9c5cf9fac7ec04a71b516e2aff3f7d76876be369',
  '    targets:',
  '      - source: src/',
  '        dart: $_package/lib/src/',
  '  - header: "@kurkle/color"',
  '    version: "v0.3.2"',
  '    url: https://github.com/kurkle/color',
  '    language: js',
  '    spdx: MIT',
  '    holder: Jukka Kurkela',
  '    pin:',
  '      kind: submodule',
  '      path: third_party/kurkle-color',
  '      ref: "v0.3.2"',
  '      commit: eb0d1db26a35704553c93782bad8c3ac2d971597',
  '    targets:',
  '      - source: src/',
  '        dart: $_package/lib/src/kurkle_color/',
];

String _header(String path) =>
    '// Ported from Chart.js v4.5.1 $path (MIT, Chart.js Contributors).';

/// The package-relative Dart path of the upstream module [path].
String _dartPath(String path) =>
    'lib/${path.replaceFirst(RegExp(r'(\.d)?\.(js|ts)$'), '.dart')}';

/// A repository with a Chart.js pin, a package and its `parity.md`. The
/// modules `helpers.core`, `helpers/index`, `types/index.d.ts` and
/// `core.element` are done.
final class _Repo {
  _Repo() : tree = FileTree() {
    tree
      ..write('REUSE.toml', ['version = 1'])
      ..write('$_package/pubspec.yaml', ['name: flutter_chartjs_port'])
      ..write('$_package/tool/port_sources.yaml', _portSources)
      ..write('$_package/lib/src/types/geometric.dart', [
        _header('src/types/geometric.d.ts'),
        'abstract interface class Point {}',
      ]);
    module(
      'src/helpers/helpers.core.ts',
      ['export function merge() {}', 'export const each = 1;'],
      status: 'ported',
      dart: true,
    );
    module(
      'src/helpers/index.ts',
      ["export * from './helpers.core.js';"],
      status: 'ported',
      dart: true,
    );
    module(
      'src/types/index.d.ts',
      [
        "import Element from '../core/core.element.js';",
        'export declare class Chart {}',
      ],
      status: 'distributed',
    );
    tree.write('$_package/lib/src/types/index.dart', [
      _header('src/types/index.d.ts'),
      'abstract interface class Chart {}',
      'abstract interface class ChartEvent {}',
    ]);
    module(
      'src/core/core.element.ts',
      [
        "import type {Point} from '../types/geometric.js';",
        'export default class Element {}',
      ],
      status: 'ported (with notes)',
      dart: true,
    );
    module('src/types/geometric.d.ts', [
      'export interface Point {}',
    ], status: 'distributed');
  }

  final FileTree tree;
  final List<String> parity = [];

  /// Writes the upstream module [path] with [lines], its `parity.md` row
  /// with [status], and a Dart file with its header when [dart] is true.
  void module(
    String path,
    List<String> lines, {
    String? status,
    bool dart = false,
  }) {
    tree.write('third_party/Chart.js/$path', lines);
    if (status != null) {
      parity.add('| [`$path`]($_blob$path) | 1 | | $status |');
    }
    if (dart) tree.write('$_package/${_dartPath(path)}', [_header(path)]);
  }

  PortOrder compute() {
    tree.write('$_package/doc/parity.md', parity);
    return computePortOrder(
      PortOrderInput(repository: tree.root, package: tree.path(_package)),
    );
  }
}

ModuleReport _module(PortOrder order, String path) =>
    order.modules.singleWhere((m) => m.path == path);

List<String> _targets(Iterable<Dependency> dependencies) => [
  for (final dependency in dependencies) dependency.target,
];

List<String> _interfaces(ModuleReport module) => [
  for (final type in module.interfaces)
    '${type.name} ${type.from} ${type.declaredIn}',
];

String _binding(ImportBinding b) =>
    '${b.typeOnly ? 'type ' : ''}${b.imported}>${b.local}';

List<String> _imports(ModuleSyntax syntax) => [
  for (final i in syntax.imports)
    [
      '${i.line} ${i.kind.name}${i.typeOnly ? ' type' : ''} ${i.specifier}',
      '[${i.bindings.map(_binding).join(', ')}]',
    ].join(' '),
];

/// [parts] joined, for a long expected line in a list.
String _join(List<String> parts) => parts.join();

/// The text of an error finding with [message].
String _error(String message) => 'error: $message';

/// The text of a warning finding with [message].
String _warning(String message) => 'warning: $message';

void main() {
  group('parseModule', () {
    test('reads the import and export forms', () {
      final syntax = parseModule(
        [
          "import a from './a.js';",
          "import b, {c, d as e} from './b.js';",
          "import * as ns from './ns.js';",
          "import './side.js';",
          "import type {T} from './t.js';",
          "import {type U, v} from './u.js';",
          'import {',
          '  w,',
          "} from './w.js';",
          "export * from './all.js';",
          "export * as star from './star.js';",
          "export {default as X, y} from './x.js';",
          "export type {Z} from './z.js';",
          '/** @param {import("./doc.js").default} p',
          " * @type {import('./doc2.js')} */",
          'export const k = 1;',
          'export function f() {}',
          'export class K {}',
          'export {k as kk};',
          'export default class Main extends K {}',
        ].map((line) => '$line\n').join(),
      );
      expect(_imports(syntax), [
        '1 import ./a.js [default>a]',
        '2 import ./b.js [default>b, c>c, d>e]',
        '3 import ./ns.js [*>ns]',
        '4 import ./side.js []',
        '5 import type ./t.js [T>T]',
        '6 import ./u.js [type U>U, v>v]',
        '7 import ./w.js [w>w]',
        '10 reexportAll ./all.js []',
        '11 reexport ./star.js [*>star]',
        '12 reexport ./x.js [default>X, y>y]',
        '13 reexport type ./z.js [Z>Z]',
        '14 jsDoc type ./doc.js [default>default]',
        '15 jsDoc type ./doc2.js [*>*]',
      ]);
      expect(syntax.localExports, {
        'k': 'k',
        'f': 'f',
        'K': 'K',
        'kk': 'k',
        'default': 'default',
      });
      expect(syntax.defaultName, 'Main');
      expect(syntax.lines, 20);
      expect(syntax.imports[3].needsAll, isTrue);
      expect(syntax.imports[2].needsAll, isFalse);
    });

    test('reads the forms of export default and of TypeScript', () {
      final named = parseModule('class Chart {}\nexport default Chart;\n');
      expect(named.defaultName, 'Chart');
      expect(named.localExports, {'default': 'Chart'});
      final object = parseModule('export default {a: 1};\n');
      expect(object.defaultName, isNull);
      final instance = parseModule(
        'export default /* #__PURE__ */ new Registry();\n',
      );
      expect(instance.defaultName, isNull);
      final declarations = parseModule(
        [
          'export interface I {}',
          'export type T = string;',
          'export declare const D: number;',
          'export abstract class A {}',
          'export const enum E {}',
          'export async function* g() {}',
          'export default function named() {}',
        ].join('\n'),
      );
      expect(declarations.localExports.keys, [
        'I',
        'T',
        'D',
        'A',
        'E',
        'g',
        'default',
      ]);
      expect(declarations.defaultName, 'named');
    });

    test('skips imports in strings, comments, templates and regexps', () {
      final syntax = parseModule(
        [
          '#!/usr/bin/env node',
          '''const s = "import x from 'y'";''',
          "// import a from 'b';",
          "/* import c from 'd'; */",
          // A template with a nested template and braces.
          r"const t = `${`${'}'}`} import e from 'f'`;",
          "const r = /import g from 'h'/g;",
          'const q = a / 2 / b; const u = x.import;',
          "import('./dynamic.js');",
          'const o = {import: 1, export: 2};',
          'function inner() {',
          "  import h from 'i';",
          '}',
          r'const m = (s.match(/^(\d+)[/]px$/) || []).length;',
          "import real from './real.js';",
        ].join('\n'),
      );
      expect(_imports(syntax), ['14 import ./real.js [default>real]']);
    });

    test('counts the lines of string line continuations', () {
      for (final end in ['\n', '\r\n']) {
        final syntax = parseModule(
          [r"const s = 'a\", "b';", "import x from './x.js';", ''].join(end),
        );
        expect(_imports(syntax), ['3 import ./x.js [default>x]']);
        expect(syntax.lines, 3);
      }
    });

    test('names the line of a part that it cannot read', () {
      Matcher error(int line, String message) => isA<ModuleSyntaxError>()
          .having((e) => e.line, 'line', line)
          .having((e) => e.message, 'message', message);
      expect(
        () => parseModule("const a = 1;\nconst s = 'open\n"),
        throwsA(error(2, 'an unterminated string literal.')),
      );
      expect(
        () => parseModule('/* open\n\n'),
        throwsA(error(1, 'an unterminated comment.')),
      );
      expect(
        () => parseModule('const t = `open \${a}\n'),
        throwsA(error(1, 'an unterminated template literal.')),
      );
      expect(
        () => parseModule('const r = /open\n'),
        throwsA(error(1, 'an unterminated regular expression.')),
      );
      expect(
        () => parseModule('function f() {\n'),
        throwsA(error(2, 'a "{" without its "}".')),
      );
      expect(
        () => parseModule('}\n'),
        throwsA(error(1, 'a "}" without its "{".')),
      );
      expect(
        () => parseModule("import x = require('y');\n"),
        throwsA(error(1, 'an import form that the helper does not read.')),
      );
      expect(
        () => parseModule('export x;\n'),
        throwsA(
          error(1, 'an "export x" form that the helper does not read.'),
        ),
      );
    });
  });

  group('classifyStatus', () {
    test('reads the values of porting-flow.md section 1 step 7', () {
      ParityState state(String status) => classifyStatus(status).state;
      expect(state('not started'), ParityState.notStarted);
      expect(state('not started (phase 5)'), ParityState.notStarted);
      expect(state('in progress: the rest'), ParityState.inProgress);
      expect(state('ported (differences: 1 `adapt`)'), ParityState.done);
      expect(state('ported: the upstream export list'), ParityState.done);
      expect(state('replaced (Chart.js ADR 0014)'), ParityState.done);
      expect(state('distributed'), ParityState.done);
      expect(state('n/a: TypeScript type operators'), ParityState.done);
      expect(state('portedish'), ParityState.unknown);
      expect(state('done'), ParityState.unknown);
      expect(state(''), ParityState.unknown);
    });

    test('reads the symbols of a partial status', () {
      final partial = classifyStatus(
        'partial: `toFontString`, `_isPointInArea`. `drawPoint` comes later',
      );
      expect(partial.state, ParityState.partial);
      expect(partial.symbols, {'toFontString', '_isPointInArea'});
      expect(
        classifyStatus('partial: `a` (and `b` later)').symbols,
        {'a'},
      );
    });
  });

  group('parseParityRows', () {
    test('reads the status column of the linked rows of one project', () {
      final rows = parseParityRows(
        [
          '| Upstream file | Lines | Dart target | Status |',
          '|---|---:|---|---|',
          // A link to another path: not a row.
          '| [`src/a.js`](${_blob}src/x.js) | 3 | `lib/src/a.dart` | ported |',
          '| [`src/b.js`](${_blob}src/b.js) | 3 | | not started |',
          _join([
            '| [`src/c.js`](${_blob}src/c.js) | 3 | | ported (a ',
            r'\| b) |',
          ]),
          _join([
            '| [`src/d.js`](https://github.com/kurkle/color/blob/v0.3.2/',
            'src/d.js) | 1 | | ported |',
          ]),
          '| `lib/src/js/js_math.dart` | builtins | tests |',
          '| [`src/e.js`](${_blob}src/e.js) | 3 | | |',
        ].join('\n'),
        _blob,
      );
      expect(
        [for (final r in rows) '${r.line} ${r.path} ${r.status}'],
        [
          '4 src/b.js  not started ',
          r'5 src/c.js  ported (a \| b) ',
          '8 src/e.js  ',
        ],
      );
    });
  });

  group('phaseOf', () {
    test('follows the phase table of porting-flow.md section 5', () {
      expect(phaseOf('src/helpers/helpers.math.ts'), 1);
      expect(phaseOf('src/helpers/helpers.core.ts'), 2);
      expect(phaseOf('src/core/core.ticks.js'), 2);
      expect(phaseOf('src/helpers/helpers.canvas.ts'), 3);
      expect(phaseOf('src/platform/platform.dom.js'), 3);
      expect(phaseOf('src/core/core.element.ts'), 4);
      expect(phaseOf('src/core/core.registry.js'), 5);
      expect(phaseOf('src/scales/scale.time.js'), 6);
      expect(phaseOf('src/controllers/index.js'), 7);
      expect(phaseOf('src/plugins/plugin.filler/index.js'), 8);
      expect(phaseOf('src/index.ts'), 9);
      expect(phaseTitle(5), 'Phase 5 (Core)');
    });
  });

  group('computePortOrder', () {
    test('lists the ready and the blocked modules', () {
      final repo = _Repo()
        ..module('src/core/core.ready.js', [
          "import {merge} from '../helpers/index.js';",
          "import Element from './core.element.js';",
        ], status: 'not started')
        ..module('src/core/core.blocked.js', [
          "import Ready from './core.ready.js';",
          "import * as helpers from '../helpers/index.js';",
        ], status: 'not started');
      final order = repo.compute();
      expect(describeFindings(order.findings), isEmpty);
      final ready = _module(order, 'src/core/core.ready.js');
      expect(ready.category, ModuleCategory.ready);
      expect(ready.lines, 2);
      expect(ready.phase, 5);
      expect(ready.neededBy, 1);
      expect(_targets(ready.dependencies), [
        'src/helpers/helpers.core.ts',
        'src/core/core.element.ts',
      ]);
      expect(ready.dependencies.first.names, {'merge'});
      final blocked = _module(order, 'src/core/core.blocked.js');
      expect(blocked.category, ModuleCategory.blocked);
      expect(_targets(blocked.missing), ['src/core/core.ready.js']);
      expect(blocked.dependencies.last.target, 'src/helpers/index.ts');
      expect(blocked.dependencies.last.needsAll, isTrue);
      expect(
        _module(order, 'src/core/core.element.ts').category,
        ModuleCategory.done,
      );
      expect(order.files, 7 + 5);
      expect(
        [for (final m in order.modules) m.path],
        [
          'src/types/geometric.d.ts',
          'src/helpers/helpers.core.ts',
          'src/types/index.d.ts',
          'src/helpers/index.ts',
          'src/core/core.element.ts',
          'src/core/core.blocked.js',
          'src/core/core.ready.js',
        ],
        reason: 'phase order, then path order',
      );
    });

    test('reads the parity.md links of a commit pin', () {
      const commit = '7169e65147a47f3720957a6f156a33c838ab9f57';
      final repo = _Repo()
        ..module('src/core/core.ready.js', [
          "import Element from './core.element.js';",
        ], status: 'not started');
      repo.tree.write('$_package/tool/port_sources.yaml', [
        for (final line in _portSources)
          switch (line) {
            '    version: "v4.5.1"' => '    version: "v4.5.1+7169e651"',
            '      ref: "v4.5.1"' => '      ref: "$commit"',
            '      commit: 9c5cf9fac7ec04a71b516e2aff3f7d76876be369' =>
              '      commit: $commit',
            _ => line,
          },
      ]);
      const commitBlob = 'https://github.com/chartjs/Chart.js/blob/$commit/';
      final rows = [...repo.parity];
      repo.parity
        ..clear()
        ..addAll([for (final row in rows) row.replaceAll(_blob, commitBlob)]);
      final order = repo.compute();
      expect(describeFindings(order.findings), isEmpty);
      expect(order.version, 'v4.5.1+7169e651');
      expect(
        _module(order, 'src/core/core.element.ts').category,
        ModuleCategory.done,
      );
      expect(
        _module(order, 'src/core/core.ready.js').category,
        ModuleCategory.ready,
      );

      // A link with the tag of the release is not a link of the pin.
      repo.parity
        ..clear()
        ..addAll(rows);
      expect(
        describeFindings(repo.compute().findings),
        contains(
          _warning(
            '$_package/doc/parity.md: no row for src/core/core.ready.js: the '
            'helper counts it as not started.',
          ),
        ),
      );
    });

    test('resolves imported names through re-exports', () {
      final repo = _Repo()
        ..module('src/core/core.a.js', [
          'export default class A {}',
        ], status: 'not started')
        ..module('src/core/core.b.js', [
          "import A from './core.a.js';",
          'export {A as Renamed};',
          'export const own = 1;',
        ], status: 'not started')
        ..module('src/index.ts', [
          "export {default as A} from './core/core.a.js';",
          "export * from './core/core.b.js';",
          "export * from './helpers/index.js';",
        ], status: 'not started')
        ..module('src/plugins/plugin.c.ts', [
          "import {A, Renamed, own, merge, missing} from '../index.js';",
        ], status: 'not started');
      final order = repo.compute();
      final plugin = _module(order, 'src/plugins/plugin.c.ts');
      expect(_targets(plugin.dependencies), [
        'src/core/core.a.js',
        'src/core/core.b.js',
        'src/helpers/helpers.core.ts',
        'src/index.ts',
      ]);
      expect(plugin.dependencies[0].names, {'default'});
      expect(plugin.dependencies[1].names, {'own'});
      expect(plugin.dependencies[3].names, {'missing'});
      expect(_targets(plugin.missing), [
        'src/core/core.a.js',
        'src/core/core.b.js',
        'src/index.ts',
      ]);
      final index = _module(order, 'src/index.ts');
      expect(_targets(index.dependencies), [
        'src/core/core.a.js',
        'src/core/core.b.js',
        'src/helpers/index.ts',
      ]);
      expect(index.phase, 9);
    });

    test('lists type-only imports as interfaces', () {
      final repo = _Repo()
        ..module('src/core/core.types.ts', [
          "import type {Chart} from '../types/index.js';",
          "import {type ChartEvent, merge} from '../helpers/index.js';",
          "import {Point} from '../types/geometric.js';",
          "import type Later from './core.later.js';",
          "import type Element from './core.element.js';",
        ], status: 'not started')
        ..module('src/core/core.jsdoc.js', [
          "/** @typedef {import('./core.later.js').default} Later */",
          "/** @param {import('../types/index.js').Chart} chart */",
          "/** @param {import('./core.element.js').default} e */",
        ], status: 'not started')
        ..module('src/core/core.later.js', [
          "import x from './core.missing.js';",
          'export default class Later {}',
        ], status: 'not started')
        ..module('src/core/core.missing.js', [], status: 'not started');
      final order = repo.compute();
      final types = _module(order, 'src/core/core.types.ts');
      expect(types.category, ModuleCategory.ready);
      expect(_targets(types.dependencies), ['src/helpers/helpers.core.ts']);
      expect(_interfaces(types), [
        'Chart src/types/index.d.ts lib/src/types/index.dart',
        'ChartEvent src/helpers/index.ts lib/src/types/index.dart',
        'Point src/types/geometric.d.ts lib/src/types/geometric.dart',
        'Later src/core/core.later.js null',
        'Element src/core/core.element.ts null',
      ]);
      final jsDoc = _module(order, 'src/core/core.jsdoc.js');
      expect(jsDoc.category, ModuleCategory.ready);
      expect(jsDoc.dependencies, isEmpty);
      expect(_interfaces(jsDoc), [
        'Later src/core/core.later.js null',
        'Chart src/types/index.d.ts lib/src/types/index.dart',
        'Element src/core/core.element.ts null',
      ]);
      expect(
        _module(order, 'src/core/core.later.js').category,
        ModuleCategory.blocked,
      );
    });

    test('finds an interface in the Dart file of a done module', () {
      final repo = _Repo()
        ..module('src/core/core.uses.js', [
          "/** @param {import('./core.element.js').default} e */",
        ], status: 'not started');
      repo.tree.write('$_package/lib/src/core/core.element.dart', [
        _header('src/core/core.element.ts'),
        'class Element {}',
      ]);
      expect(_interfaces(_module(repo.compute(), 'src/core/core.uses.js')), [
        'Element src/core/core.element.ts lib/src/core/core.element.dart',
      ]);
    });

    test('takes the port state from the headers and parity.md', () {
      final repo = _Repo()
        ..module('src/core/core.started.js', [], status: 'not started')
        ..module('src/core/core.noRow.js', [])
        ..module('src/core/core.progress.js', [], status: 'in progress')
        ..module('src/core/core.na.js', [], status: 'n/a: a reason')
        ..module('src/core/core.odd.js', [], status: 'finished')
        ..module('src/core/core.lost.js', [], status: 'ported')
        ..module('src/core/core.moved.js', [], status: 'not started');
      repo.parity
        ..add(
          '| [`src/core/core.gone.js`](${_blob}src/core/core.gone.js) | 1 '
          '| | ported |',
        )
        ..add(
          '| [`src/core/core.na.js`](${_blob}src/core/core.na.js) | 1 '
          '| | ported |',
        );
      repo.tree
        ..write('$_package/lib/src/core/core.started.dart', [
          _header('src/core/core.started.js'),
        ])
        ..write('$_package/lib/src/core/core.progress.dart', [
          _header('src/core/core.progress.js'),
        ])
        ..write('$_package/lib/src/core/elsewhere.dart', [
          _header('src/core/core.moved.js'),
          '// Ported from Chart.js broken',
        ])
        ..write('$_package/lib/src/core/core.gone.dart', [
          _header('src/core/core.gone.js'),
        ]);
      final order = repo.compute();
      ModuleCategory category(String path) => _module(order, path).category;
      expect(category('src/core/core.started.js'), ModuleCategory.inProgress);
      expect(
        _module(order, 'src/core/core.started.js').dartFile,
        'lib/src/core/core.started.dart',
      );
      expect(category('src/core/core.noRow.js'), ModuleCategory.ready);
      expect(category('src/core/core.progress.js'), ModuleCategory.inProgress);
      expect(category('src/core/core.na.js'), ModuleCategory.done);
      expect(category('src/core/core.odd.js'), ModuleCategory.ready);
      expect(category('src/core/core.lost.js'), ModuleCategory.done);
      expect(category('src/core/core.moved.js'), ModuleCategory.ready);
      const parity = '$_package/doc/parity.md';
      const lib = '$_package/lib/src/core';
      expect(describeFindings(order.findings), [
        _warning(
          '$lib/core.gone.dart:1: src/core/core.gone.js is not a module of '
          'third_party/Chart.js/src.',
        ),
        _error(
          '$lib/elsewhere.dart:2: the header line does not match the grammar '
          'of porting-flow.md 4, tool 2.',
        ),
        _warning(
          '$lib/elsewhere.dart:1: the Dart path of src/core/core.moved.js is '
          '$lib/core.moved.dart, not this file: the helper does not count it.',
        ),
        _error(
          '$parity:9: the status "finished" of src/core/core.odd.js is not a '
          'value of porting-flow.md section 1 step 7 (not started, in '
          'progress, partial, ported, replaced, distributed, n/a).',
        ),
        _warning(
          '$parity:12: src/core/core.gone.js is not a module of '
          'third_party/Chart.js/src.',
        ),
        _warning(
          '$parity:13: a second row of src/core/core.na.js: the helper reads '
          'the first row (line 8).',
        ),
        _warning(
          '$parity: no row for src/core/core.noRow.js: the helper counts it '
          'as not started.',
        ),
        _warning(
          '$parity:10: the status of src/core/core.lost.js is "ported", but '
          'no Dart file at $lib/core.lost.dart names it in its header.',
        ),
      ]);
    });

    test('lets a partial module satisfy the imports of its symbols', () {
      final repo = _Repo()
        ..module(
          'src/core/core.partial.js',
          [
            'export function a() {}',
            'export function b() {}',
            'export default class P {}',
          ],
          status: 'partial: `a`, `P`',
          dart: true,
        )
        ..module('src/core/core.usesA.js', [
          "import P, {a} from './core.partial.js';",
        ], status: 'not started')
        ..module('src/core/core.usesB.js', [
          "import {a, b} from './core.partial.js';",
        ], status: 'not started')
        ..module('src/core/core.usesAll.js', [
          "import * as all from './core.partial.js';",
        ], status: 'not started');
      final order = repo.compute();
      expect(
        _module(order, 'src/core/core.partial.js').category,
        ModuleCategory.inProgress,
      );
      expect(
        _module(order, 'src/core/core.usesA.js').category,
        ModuleCategory.ready,
      );
      expect(
        _module(order, 'src/core/core.usesB.js').category,
        ModuleCategory.blocked,
      );
      expect(
        _module(order, 'src/core/core.usesAll.js').category,
        ModuleCategory.blocked,
      );
      expect(_module(order, 'src/core/core.partial.js').neededBy, 2);
    });

    test('makes the modules of an import cycle ready together', () {
      final repo = _Repo()
        ..module('src/core/core.cycleA.js', [
          "import B from './core.cycleB.js';",
        ], status: 'not started')
        ..module('src/core/core.cycleB.js', [
          "import A from './core.cycleA.js';",
          "import {merge} from '../helpers/helpers.core.js';",
        ], status: 'not started')
        ..module('src/core/core.cycleC.js', [
          "import A from './core.cycleC2.js';",
          "import W from './core.wait.js';",
        ], status: 'not started')
        ..module('src/core/core.cycleC2.js', [
          "import C from './core.cycleC.js';",
        ], status: 'not started')
        ..module('src/core/core.wait.js', [], status: 'in progress');
      final order = repo.compute();
      final a = _module(order, 'src/core/core.cycleA.js');
      expect(a.category, ModuleCategory.ready);
      expect(a.group, ['src/core/core.cycleB.js']);
      expect(
        _module(order, 'src/core/core.cycleB.js').group,
        ['src/core/core.cycleA.js'],
      );
      expect(
        _module(order, 'src/core/core.cycleC.js').category,
        ModuleCategory.blocked,
      );
      expect(
        _module(order, 'src/core/core.cycleC2.js').category,
        ModuleCategory.blocked,
      );
    });

    test('reads packages and JSON data', () {
      final repo = _Repo()
        ..module('src/core/core.color.js', [
          "import {Color} from '@kurkle/color';",
          "import {version} from '../../package.json';",
        ], status: 'not started')
        ..module('src/core/core.pad.js', [
          "import pad from 'left-pad';",
        ], status: 'not started');
      repo.tree.write('third_party/Chart.js/package.json', ['{}']);
      final order = repo.compute();
      expect(describeFindings(order.findings), isEmpty);
      final color = _module(order, 'src/core/core.color.js');
      expect(color.category, ModuleCategory.ready);
      expect(_targets(color.dependencies), ['@kurkle/color']);
      final pad = _module(order, 'src/core/core.pad.js');
      expect(pad.category, ModuleCategory.blocked);
      expect(pad.missing.single.kind, DependencyKind.package);
    });

    test(
      'reports modules that do not parse and imports that do not resolve',
      () {
        final repo = _Repo()
          ..module('src/core/core.broken.js', [
            "const s = 'open",
          ], status: 'not started')
          ..module('src/core/core.lost.js', [
            "import x from './nope.js';",
            "import y from '../../outside/far.js';",
          ], status: 'not started');
        final order = repo.compute();
        const src = 'third_party/Chart.js/src/core';
        expect(describeFindings(order.findings), [
          _error('$src/core.broken.js:1: an unterminated string literal.'),
          _error(
            '$src/core.lost.js:1: the import "./nope.js" does not resolve to '
            'a module of third_party/Chart.js/src.',
          ),
          _error(
            '$src/core.lost.js:2: the import "../../outside/far.js" does not '
            'resolve to a module of third_party/Chart.js/src.',
          ),
        ]);
        final broken = _module(order, 'src/core/core.broken.js');
        expect(broken.category, ModuleCategory.blocked);
        expect(broken.error, 'an unterminated string literal.');
        final lost = _module(order, 'src/core/core.lost.js');
        expect(lost.category, ModuleCategory.blocked);
        expect(
          [for (final d in lost.missing) '${d.kind.name} ${d.target}'],
          ['unresolved ./nope.js', 'unresolved ../../outside/far.js'],
        );
      },
    );

    test('throws on a missing input', () {
      final repo = _Repo();
      final tree = repo.tree;
      final input = PortOrderInput(
        repository: tree.root,
        package: tree.path(_package),
      );
      Matcher fails(String message) => throwsA(
        isA<PortOrderInputError>().having((e) => e.message, 'message', message),
      );
      expect(
        () => computePortOrder(input),
        fails('$_package/doc/parity.md does not exist.'),
      );
      tree.deleteDirectory('third_party/Chart.js/src');
      expect(
        () => computePortOrder(input),
        fails(
          'third_party/Chart.js/src is not checked out (dart run melos run '
          'upstream).',
        ),
      );
      tree.write('$_package/tool/port_sources.yaml', [
        'sources:',
        ..._portSources.skipWhile((line) => !line.contains('@kurkle')),
      ]);
      expect(
        () => computePortOrder(input),
        fails('$_package/tool/port_sources.yaml has no Chart.js entry.'),
      );
      tree.delete('$_package/tool/port_sources.yaml');
      expect(
        () => computePortOrder(input),
        throwsA(isA<PortOrderInputError>()),
      );
    });
  });

  group('output', () {
    late PortOrder order;

    setUp(() {
      final repo = _Repo()
        ..module('src/core/core.ready.js', [
          "import type {Chart, Missing} from '../types/index.js';",
        ], status: 'not started')
        ..module('src/core/core.cycleA.js', [
          "import B from './core.cycleB.js';",
        ], status: 'not started')
        ..module('src/core/core.cycleB.js', [
          "import A from './core.cycleA.js';",
        ], status: 'not started')
        ..module(
          'src/core/core.work.js',
          ["import R from './core.ready.js';"],
          status: 'in progress: the first half. More later',
          dart: true,
        )
        ..module('src/core/core.blocked.js', [
          "import R from './core.ready.js';",
          "import W from './core.work.js';",
          "import pad from 'left-pad';",
        ], status: 'not started')
        ..module('src/index.ts', [
          "export * from './core/core.blocked.js';",
        ], status: 'not started');
      order = repo.compute();
    });

    test('renders the text report', () {
      expect(renderPortOrder(order), '''
port:next: Chart.js v4.5.1, 11 modules in third_party/Chart.js/src: 5 done, 1 in progress, 3 ready, 2 blocked.

Ready to port, in phase order:
  Phase 5 (Core)
    src/core/core.cycleA.js (1 lines)
      port together with: src/core/core.cycleB.js
      interfaces: none
    src/core/core.cycleB.js (1 lines)
      port together with: src/core/core.cycleA.js
      interfaces: none
    src/core/core.ready.js (1 lines, needed by 2 modules)
      interfaces: Chart (lib/src/types/index.dart), Missing (not declared)

In progress:
  Phase 5 (Core)
    src/core/core.work.js (1 lines, needed by 1 module)
      Dart file: lib/src/core/core.work.dart
      parity.md: in progress
      waits for: src/core/core.ready.js (ready)

Blocked:
  Phase 5 (Core)
    src/core/core.blocked.js (3 lines, needed by 1 module)
      missing: src/core/core.ready.js (ready), src/core/core.work.js (in progress),
        left-pad (no entry in tool/port_sources.yaml)
  Phase 9 (Flutter API and release)
    src/index.ts (1 lines)
      missing: src/core/core.blocked.js (blocked)

''');
    });

    test('gives the same data as JSON', () {
      final json = portOrderJson(order);
      expect(jsonDecode(jsonEncode(json)), json);
      expect(json['summary'], {
        'modules': 11,
        'done': 5,
        'inProgress': 1,
        'ready': 3,
        'blocked': 2,
      });
      final ready = (json['ready']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(
        [for (final m in ready) m['module']],
        [
          'src/core/core.cycleA.js',
          'src/core/core.cycleB.js',
          'src/core/core.ready.js',
        ],
      );
      expect(ready.last['interfaces'], [
        {
          'name': 'Chart',
          'from': 'src/types/index.d.ts',
          'declaredIn': 'lib/src/types/index.dart',
        },
        {'name': 'Missing', 'from': 'src/types/index.d.ts', 'declaredIn': null},
      ]);
      final blocked = (json['blocked']! as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(blocked.first['missing'], [
        {
          'target': 'src/core/core.ready.js',
          'kind': 'module',
          'names': ['default'],
          'needsAll': false,
        },
        {
          'target': 'src/core/core.work.js',
          'kind': 'module',
          'names': ['default'],
          'needsAll': false,
        },
        {
          'target': 'left-pad',
          'kind': 'package',
          'names': ['default'],
          'needsAll': false,
        },
      ]);
      final work =
          (json['inProgress']! as List<Object?>).single!
              as Map<String, Object?>;
      expect(work['dart'], 'lib/src/core/core.work.dart');
      expect(work['parityStatus'], 'in progress: the first half. More later');
      expect(json['findings'], isEmpty);
    });
  });

  group('command', () {
    test('lists, checks and reports usage errors', () {
      final repo = _Repo()
        ..module('src/core/core.ready.js', [], status: 'not started');
      repo.tree.write('$_package/doc/parity.md', repo.parity);
      final package = repo.tree.path(_package);
      final out = StringBuffer();
      expect(command.run([package], out: out), 0);
      expect(
        out.toString(),
        startsWith('port:next: Chart.js v4.5.1, 6 modules'),
      );
      expect(out.toString(), contains('    src/core/core.ready.js (0 lines)'));

      out.clear();
      expect(command.run(['--check', package], out: out), 0);
      expect(
        out.toString(),
        'port:next --check: passed, 11 files, 0 errors, 0 warnings.\n',
      );

      out.clear();
      expect(command.run(['--json', package], out: out), 0);
      final json = jsonDecode(out.toString()) as Map<String, Object?>;
      expect((json['summary']! as Map<String, Object?>)['ready'], 1);

      repo.tree.write('third_party/Chart.js/src/core/core.broken.js', [
        '/* open',
      ]);
      out.clear();
      expect(command.run(['--check', package], out: out), 1);
      expect(out.toString(), contains('an unterminated comment.'));
      expect(
        out.toString(),
        endsWith('failed, 12 files, 1 errors, 1 warnings.\n'),
      );
      out.clear();
      expect(command.run(['--check', '--json', package], out: out), 1);
      expect(command.run([package], out: StringBuffer()), 0);

      out.clear();
      expect(command.run(['--bad'], out: out), 2);
      expect(
        out.toString(),
        startsWith('port:next: unexpected argument --bad'),
      );
      out.clear();
      expect(command.run([package, package], out: out), 2);
      out.clear();
      expect(command.run([repo.tree.path('none')], out: out), 2);
      expect(out.toString(), contains('has no pubspec.yaml'));
      out.clear();
      expect(command.run(['--help'], out: out), 0);
      expect(out.toString(), startsWith('Usage:'));

      repo.tree.deleteDirectory('third_party/Chart.js');
      out.clear();
      expect(command.run(['--check', package], out: out), 2);
      expect(out.toString(), contains('is not checked out'));
      repo.tree.delete('REUSE.toml');
      out.clear();
      expect(command.run([package], out: out), 2);
      expect(out.toString(), contains('no REUSE.toml'));
    });
  });

  group('the repository', () {
    final repository = findAncestorWith(Directory.current.path, 'REUSE.toml');
    final source = repository == null
        ? null
        : Directory('$repository/third_party/Chart.js/src');
    final skip = source == null
        ? 'not inside the flutter_ports repository'
        : source.existsSync() && source.listSync().isNotEmpty
        ? false
        : '${source.path} is missing: run `dart run melos run upstream`';

    test('reads every module of the pin', () {
      final order = computePortOrder(
        PortOrderInput(
          repository: repository!,
          package: '$repository/$_package',
        ),
      );
      final errors = order.findings.where((f) => f.isError);
      expect(describeFindings(errors), isEmpty);
      final files = [
        for (final entity in source!.listSync(recursive: true))
          if (entity is File &&
              moduleExtensions.any((e) => entity.path.endsWith(e)))
            entity,
      ];
      expect(order.modules, hasLength(files.length));
      for (final module in order.modules) {
        expect(module.error, isNull, reason: module.path);
        if (module.category == ModuleCategory.ready) {
          expect(
            module.missing,
            module.group.isEmpty ? isEmpty : isNotEmpty,
            reason: module.path,
          );
        }
      }
      ModuleReport report(String path) => _module(order, path);
      // core.controller.js:12 imports version from package.json: data.
      expect(
        report('src/core/core.controller.js').dependencies.map((d) => d.kind),
        everyElement(DependencyKind.module),
      );
      // plugin.colors.ts:1 imports through the barrel src/index.ts.
      expect(_targets(report('src/plugins/plugin.colors.ts').dependencies), [
        'src/controllers/controller.doughnut.js',
        'src/controllers/controller.polarArea.js',
        'src/core/core.defaults.js',
      ]);
      // helpers.dom.ts:2 imports the type of the concrete Chart class.
      expect(
        _interfaces(report('src/helpers/helpers.dom.ts')),
        contains('Chart src/core/core.controller.js lib/src/types/index.dart'),
      );
      expect(report('src/core/core.element.ts').category, ModuleCategory.done);
    }, skip: skip);
  });
}
