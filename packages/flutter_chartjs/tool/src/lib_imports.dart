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

/// The other libraries of pure layers.
const Set<String> purePackageLibraries = {
  'package:meta/meta.dart',
  'package:intl/intl.dart',
  'package:intl/number_symbols.dart',
  'package:intl/number_symbols_data.dart',
};

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
const List<String> pureRoots = [
  'lib/src/js/**',
  'lib/src/types/**',
  'lib/src/kurkle_color/**',
  'lib/src/helpers/helpers.*.dart',
  'lib/src/core/core.defaults.dart',
];

/// Files that match [pureRoots] but are not pure-layer roots.
const List<String> pureRootExceptions = [
  'lib/src/helpers/helpers.dom.dart',
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
({List<Finding> findings, int files}) checkLibImports(
  String packageDirectory, {
  String displayPrefix = '',
}) {
  final packageName = _packageName(packageDirectory);
  final libraries = SplayTreeMap<String, _Library>();
  for (final directory in const ['lib', 'test']) {
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

  return (findings: findings, files: libraries.length);
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
