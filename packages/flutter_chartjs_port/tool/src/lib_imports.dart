// Original code, not ported from Chart.js: the library import guard, tool 1.

/// The library import guard of porting-flow.md section 4, tool 1.
///
/// - `lib/` imports only the allowlist below (AGENTS.md rule 5).
/// - A pure-layer file, and every file that it imports, directly or not,
///   reaches neither `dart:ui` nor `package:flutter` (porting-flow.md 3).
/// - A test without `@TestOn('vm')` compiles for the web legs, so it and its
///   test imports use only pure layers, `package:test` and
///   `package:chartjs_test_utils/pure.dart`.
/// - Ported files do not import `lib/src/theme/` (Chart.js ADR 0001).
/// - `lib/` imports `package:collection/collection.dart` only with
///   `show mergeSort` (Chart.js ADR 0032, Sort).
/// - The `lib/pure.dart` closure of the harness package `chartjs_test_utils`
///   is a pure layer too. It also imports `package:test` and the pure layers
///   of the checked package (porting-flow.md 3).
library;

import 'dart:collection';
import 'dart:io';

import 'check_support.dart';
import 'dart_source.dart';
import 'headers.dart';

/// The `dart:` libraries of pure layers and web tests.
const Set<String> pureDartLibraries = {
  'dart:async',
  'dart:collection',
  'dart:convert',
  'dart:core',
  'dart:math',
  'dart:typed_data',
};

/// The other libraries of pure layers. [collectionLibrary] gives
/// `mergeSort` to `jsSort` from phase 2 (Chart.js ADR 0032, Sort).
/// `package:clock/clock.dart` gives `clock.now()` to `jsDateNow` from phase 5
/// (Chart.js ADR 0032, section 6).
const Set<String> purePackageLibraries = {
  collectionLibrary,
  'package:clock/clock.dart',
  'package:meta/meta.dart',
  'package:intl/intl.dart',
  'package:intl/number_symbols.dart',
  'package:intl/number_symbols_data.dart',
};

/// The library of `package:collection` that `lib/` can import.
const String collectionLibrary = 'package:collection/collection.dart';

/// The names that `lib/` shows from [collectionLibrary]. The other sorts of
/// the library are not those of `Array.prototype.sort` (Chart.js ADR 0032,
/// Sort).
const Set<String> collectionNames = {'mergeSort'};

/// The libraries that `lib/` can import in addition to the pure ones.
const Set<String> flutterLibraries = {
  'dart:ui',
  'package:flutter/foundation.dart',
  'package:flutter/gestures.dart',
  'package:flutter/painting.dart',
  'package:flutter/rendering.dart',
  'package:flutter/scheduler.dart',
  'package:flutter/semantics.dart',
  'package:flutter/services.dart',
  'package:flutter/widgets.dart',
};

/// URI prefixes that `lib/` never imports, with the rule that forbids them.
const Map<String, String> forbiddenInLib = {
  'package:flutter/material.dart': 'Chart.js ADR 0001: no Material in lib/',
  'package:flutter/cupertino.dart': 'Chart.js ADR 0001: no Cupertino in lib/',
  'package:material_ui/': 'Chart.js ADR 0001: no Material in lib/',
  'package:forui/': 'Chart.js ADR 0001: no forui in lib/',
  'dart:io': 'AGENTS.md rule 5: lib/ compiles for every platform',
  'dart:html': 'AGENTS.md rule 5: no JavaScript at runtime',
  'dart:js_interop': 'AGENTS.md rule 5: no JavaScript at runtime',
  'dart:js_interop_unsafe': 'AGENTS.md rule 5: no JavaScript at runtime',
  'package:web/': 'AGENTS.md rule 5: no JavaScript at runtime',
};

/// The pure-layer roots, as globs relative to the package. Each file that a
/// root imports, directly or not, is in the pure layer too. Thus the canvas
/// interface is pure because `helpers.canvas` imports it, and the
/// `core.defaults` closure is pure because `core.defaults` is a root.
///
/// `helpers.dom` is a root: it reads the canvas interface and the port-only
/// `NativeEvent`, not `dart:ui` (Chart.js ADR 0037). Of `lib/src/platform/`,
/// only `platform.base`, `platform.basic` and `native_event` are roots.
/// `platform.flutter`, `chart_host` and the platform `index` use the Flutter
/// framework.
///
/// `core.element` and every file of `lib/src/elements/` are roots (Chart.js
/// ADR 0017, section 10). Their specs run on the VM, dart2js and dart2wasm.
///
/// `core.config` and `core.adapters` are roots (Chart.js ADR 0021, section
/// 7). Their port-only tests run on the VM, dart2js and dart2wasm. So are
/// the port-only date files `date_*.dart` (Chart.js ADR 0024): the default
/// date adapter.
///
/// `core.interaction` and `core.layouts` are roots. Their upstream imports
/// are helpers other than `helpers.extras`. Their specs and port-only tests
/// run on the VM, dart2js and dart2wasm.
///
/// `core.animation` and the port-only `animation_spec` are roots (Chart.js
/// ADR 0019, section 1). `core.animations` and `core.animator` are not:
/// `core.animator` imports `helpers.extras`.
///
/// `core.typedRegistry` is a root (Chart.js ADR 0020, section 10). It imports
/// `core.defaults`, `helpers.core` and the JS runtime. `core.registry` and
/// `core.plugins` are not roots: `core.registry` imports `core.scale`, which
/// imports `helpers.extras`.
///
/// The theme compiler and the internal presets of `lib/src/theme/` are
/// roots (Chart.js ADR 0001, theming.md §7). Their port-only tests run on
/// the VM, dart2js and dart2wasm. The theme widget of phase 9 uses the
/// Flutter framework, so the directory is not a root as a whole.
const List<String> pureRoots = [
  'lib/src/js/**',
  'lib/src/types/**',
  'lib/src/kurkle_color/**',
  'lib/src/helpers/helpers.*.dart',
  'lib/src/core/core.defaults.dart',
  'lib/src/core/core.element.dart',
  'lib/src/core/core.config.dart',
  'lib/src/core/core.adapters.dart',
  'lib/src/core/date_*.dart',
  'lib/src/core/core.interaction.dart',
  'lib/src/core/core.layouts.dart',
  'lib/src/core/core.animation.dart',
  'lib/src/core/animation_spec.dart',
  'lib/src/core/core.typedRegistry.dart',
  'lib/src/elements/**',
  'lib/src/platform/platform.base.dart',
  'lib/src/platform/platform.basic.dart',
  'lib/src/platform/native_event.dart',
  'lib/src/theme/compile.dart',
  'lib/src/theme/presets.dart',
];

/// Files that match [pureRoots] but are not pure-layer roots.
/// `helpers.extras` imports `package:flutter/scheduler.dart` (Chart.js ADR
/// 0007, decision 10).
const List<String> pureRootExceptions = [
  'lib/src/helpers/helpers.extras.dart',
];

/// The test libraries that a test without `@TestOn('vm')` can import, in
/// addition to [pureDartLibraries]. An entry that ends with `/` is a prefix.
const Set<String> webTestLibraries = {
  'package:test/',
  'package:chartjs_test_utils/pure.dart',
};

/// The directory that ported files never import.
const String themeDirectory = 'lib/src/theme/';

/// The pure-layer root of the harness package (porting-flow.md 3).
const String harnessPureRoot = 'lib/pure.dart';

/// The libraries that the harness pure layer can import in addition to the
/// pure ones and the pure layers of the checked package. An entry that ends
/// with `/` is a prefix.
const Set<String> harnessPureLibraries = {'package:test/'};

/// One Dart file of the package.
final class _Library {
  _Library(this.path, this.source) : header = Header.parse(source.lines);

  /// The path relative to the package.
  final String path;
  final DartSource source;
  final Header header;
  final List<_Edge> edges = [];
}

/// One URI of a directive.
final class _Edge {
  _Edge(this.uri, this.line, this.target);

  final String uri;
  final int line;

  /// The package-relative path for a URI of this package, else null.
  final String? target;
}

/// Runs the guard over the package in [packageDirectory]. The paths in the
/// findings start with [displayPrefix].
///
/// When [harnessDirectory] holds a [harnessPureRoot], the guard also checks
/// the closure of that file. Its paths start with [harnessDisplayPrefix].
({List<Finding> findings, int files}) checkLibImports(
  String packageDirectory, {
  String displayPrefix = '',
  String? harnessDirectory,
  String harnessDisplayPrefix = '',
}) {
  final packageName = _packageName(packageDirectory);
  final libraries = _load(packageDirectory, packageName, const ['lib', 'test']);

  final findings = <Finding>[];
  void report(_Library library, int line, String message) {
    findings.add(Finding('$displayPrefix${library.path}', line, message));
  }

  // lib/ allowlist.
  for (final library in libraries.values) {
    if (!library.path.startsWith('lib/')) continue;
    for (final edge in library.edges) {
      final target = edge.target;
      if (target != null) {
        if (!target.startsWith('lib/')) {
          report(
            library,
            edge.line,
            'imports $target, which is outside lib/ (porting-flow.md 4, '
            'tool 1).',
          );
        }
        continue;
      }
      final forbidden = _forbiddenReason(edge.uri);
      if (forbidden != null) {
        report(library, edge.line, 'imports ${edge.uri} ($forbidden).');
      } else if (!_isLibAllowed(edge.uri)) {
        report(
          library,
          edge.line,
          'imports ${edge.uri}, which is not on the lib/ allowlist '
          '(porting-flow.md 4, tool 1).',
        );
      }
    }
  }

  // The sorts of package:collection.
  for (final library in libraries.values) {
    if (!library.path.startsWith('lib/')) continue;
    for (final directive in library.source.directives) {
      if (!directive.uris.contains(collectionLibrary)) continue;
      final shown = directive.shown;
      if (shown == null || !shown.every(collectionNames.contains)) {
        report(
          library,
          directive.line,
          '${directive.keyword}s $collectionLibrary without '
          '"show ${collectionNames.join(', ')}" (Chart.js ADR 0032, Sort).',
        );
      }
    }
  }

  // Pure layers: the closure of the roots.
  final rootPatterns = [for (final glob in pureRoots) globToRegExp(glob)];
  final exceptions = pureRootExceptions.toSet();
  final roots = [
    for (final path in libraries.keys)
      if (!exceptions.contains(path) &&
          rootPatterns.any((pattern) => pattern.hasMatch(path)))
        path,
  ];
  final pure = _closure(roots, libraries, (path) => path.startsWith('lib/'));
  for (final path in pure.keys) {
    final library = libraries[path]!;
    for (final edge in library.edges) {
      if (edge.target != null || _isPureAllowed(edge.uri)) continue;
      final reason =
          edge.uri == 'dart:ui' || edge.uri.startsWith('package:flutter/')
          ? 'pure layers reach neither dart:ui nor package:flutter'
          : 'pure layers import only the pure allowlist';
      report(
        library,
        edge.line,
        'imports ${edge.uri}, but the file is in the pure layer'
        '${_chain(path, pure)} ($reason, porting-flow.md 3).',
      );
    }
  }

  // Tests that the web legs compile.
  final entries = [
    for (final library in libraries.values)
      if (library.path.startsWith('test/') &&
          library.path.endsWith('_test.dart') &&
          !library.source.isVmOnly)
        library.path,
  ];
  final web = _closure(entries, libraries, (path) => path.startsWith('test/'));
  for (final path in web.keys) {
    final library = libraries[path]!;
    for (final edge in library.edges) {
      final target = edge.target;
      if (target != null && target.startsWith('test/')) continue;
      if (target != null && pure.containsKey(target)) continue;
      if (target == null && _isWebTestAllowed(edge.uri)) continue;
      final what = target == null
          ? edge.uri
          : '$target, which is not in the pure layer';
      report(
        library,
        edge.line,
        'imports $what, but the file compiles for the web test legs'
        "${_chain(path, web)}. Add @TestOn('vm') to the test, or import only "
        'pure layers, package:test and package:chartjs_test_utils/pure.dart '
        '(porting-flow.md 3).',
      );
    }
  }

  // Ported files and the theme.
  for (final library in libraries.values) {
    if (library.header.kind != HeaderKind.ported) continue;
    for (final edge in library.edges) {
      if (edge.target?.startsWith(themeDirectory) ?? false) {
        report(
          library,
          edge.line,
          'imports ${edge.target}, but ported files never import '
          '$themeDirectory (Chart.js ADR 0001).',
        );
      }
    }
  }

  var files = libraries.length;
  if (harnessDirectory != null &&
      File('$harnessDirectory/$harnessPureRoot').existsSync()) {
    files += _checkHarness(
      harnessDirectory,
      packageName,
      pure,
      findings,
      harnessDisplayPrefix,
    );
  }
  return (findings: findings, files: files);
}

/// Reads the Dart files in [directories] of the package in
/// [packageDirectory], with the edges of their directives.
SplayTreeMap<String, _Library> _load(
  String packageDirectory,
  String packageName,
  List<String> directories,
) {
  final libraries = SplayTreeMap<String, _Library>();
  for (final directory in directories) {
    for (final file in dartFilesUnder('$packageDirectory/$directory')) {
      final path = relativePath(packageDirectory, file);
      libraries[path] = _Library(
        path,
        DartSource(File(file).readAsStringSync()),
      );
    }
  }
  for (final library in libraries.values) {
    for (final directive in library.source.directives) {
      for (final uri in directive.uris) {
        library.edges.add(
          _Edge(uri, directive.line, _resolve(packageName, library.path, uri)),
        );
      }
    }
  }
  return libraries;
}

/// Checks the [harnessPureRoot] closure of the harness package in
/// [harnessDirectory]: it imports only pure libraries, the
/// [harnessPureLibraries] and the files of [pure], the pure layers of
/// package [packageName]. Returns the number of files in the closure.
int _checkHarness(
  String harnessDirectory,
  String packageName,
  Map<String, String?> pure,
  List<Finding> findings,
  String displayPrefix,
) {
  final harnessName = _packageName(harnessDirectory);
  final libraries = _load(harnessDirectory, harnessName, const ['lib']);
  final closure = _closure(
    [harnessPureRoot],
    libraries,
    (path) => path.startsWith('lib/'),
  );
  final checked = 'package:$packageName/';
  for (final path in closure.keys) {
    final library = libraries[path]!;
    for (final edge in library.edges) {
      final target = edge.target;
      if (target != null && target.startsWith('lib/')) continue;
      if (target == null && _isHarnessPureAllowed(edge.uri)) continue;
      if (edge.uri.startsWith(checked) &&
          pure.containsKey(
            normalizeRelative('lib/${edge.uri.substring(checked.length)}'),
          )) {
        continue;
      }
      findings.add(
        Finding(
          '$displayPrefix$path',
          edge.line,
          'imports ${target ?? edge.uri}, but the file is in the pure layer '
              'of the harness${_chain(path, closure)} (it imports only pure '
              'libraries, package:test and the pure layers of $packageName, '
              'porting-flow.md 3).',
        ),
      );
    }
  }
  return closure.length;
}

String _packageName(String packageDirectory) {
  final pubspec = File('$packageDirectory/pubspec.yaml').readAsLinesSync();
  for (final line in pubspec) {
    final match = RegExp(r'^name:\s*(\S+)').firstMatch(line);
    if (match != null) return match.group(1)!;
  }
  throw FormatException('$packageDirectory/pubspec.yaml has no name');
}

/// The package-relative path of [uri] in [from], or null if [uri] is not a
/// file of package [packageName].
String? _resolve(String packageName, String from, String uri) {
  final own = 'package:$packageName/';
  if (uri.startsWith(own)) {
    return normalizeRelative('lib/${uri.substring(own.length)}');
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return null;
  if (Uri.tryParse(uri)?.hasScheme ?? true) return null;
  final directory = from.contains('/')
      ? from.substring(0, from.lastIndexOf('/') + 1)
      : '';
  return normalizeRelative('$directory$uri');
}

String? _forbiddenReason(String uri) {
  for (final MapEntry(key: prefix, value: reason) in forbiddenInLib.entries) {
    if (prefix.endsWith('/') ? uri.startsWith(prefix) : uri == prefix) {
      return reason;
    }
  }
  return null;
}

bool _isPureAllowed(String uri) =>
    pureDartLibraries.contains(uri) || purePackageLibraries.contains(uri);

bool _isLibAllowed(String uri) =>
    _isPureAllowed(uri) || flutterLibraries.contains(uri);

bool _isHarnessPureAllowed(String uri) =>
    _isPureAllowed(uri) ||
    harnessPureLibraries.any(
      (entry) => entry.endsWith('/') ? uri.startsWith(entry) : uri == entry,
    );

bool _isWebTestAllowed(String uri) =>
    pureDartLibraries.contains(uri) ||
    webTestLibraries.any(
      (entry) => entry.endsWith('/') ? uri.startsWith(entry) : uri == entry,
    );

/// The files that [roots] reach through own-package edges to files that
/// [follow] accepts, each with the file it was reached from (null for a
/// root), in breadth-first order.
Map<String, String?> _closure(
  List<String> roots,
  Map<String, _Library> libraries,
  bool Function(String path) follow,
) {
  final reached = <String, String?>{for (final root in roots) root: null};
  final queue = Queue.of(roots);
  while (queue.isNotEmpty) {
    final library = libraries[queue.removeFirst()]!;
    for (final edge in library.edges) {
      final target = edge.target;
      if (target == null ||
          reached.containsKey(target) ||
          !libraries.containsKey(target) ||
          !follow(target)) {
        continue;
      }
      reached[target] = library.path;
      queue.add(target);
    }
  }
  return reached;
}

/// ` (reached from <root> -> ... -> <importer>)` when [path] is not a root
/// of [reached].
String _chain(String path, Map<String, String?> reached) {
  final chain = <String>[];
  for (var via = reached[path]; via != null; via = reached[via]) {
    chain.add(via);
  }
  if (chain.isEmpty) return '';
  return ' (reached from ${chain.reversed.join(' -> ')})';
}
