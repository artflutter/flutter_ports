// Original code, not ported from Chart.js: the library import guard, tool 1.

/// The library import guard of porting-flow.md section 4, tool 1.
///
/// - `lib/` imports only the allowlist below (AGENTS.md rule 5).
/// - A pure-layer file, and every file that it imports, directly or not,
///   may use `dart:ui` Color but no `package:flutter` framework (ADR 0061).
/// - A test without `@TestOn('vm')` compiles for the web legs, so it and its
///   test imports use only pure layers, `package:test` and
///   `package:chartjs_test_utils/pure.dart`.
/// - Ported files do not import `lib/src/theme/` (Chart.js ADR 0050).
/// - A file of `lib/src/widgets/` imports no component and no index of the
///   components: the widget registers no component (Chart.js ADR 0048,
///   section 3).
/// - A file of `lib/src/typed/` imports only the allowlist of the typed API,
///   and ported files do not import `lib/src/typed/` (Chart.js ADR 0052,
///   section 8).
/// - `lib/` imports `package:collection/collection.dart` only with
///   `show mergeSort` (Chart.js ADR 0045, Sort).
/// - The `lib/pure.dart` closure of the harness package `chartjs_test_utils`
///   is a pure layer too. It also imports `package:test` and the pure layers
///   of the checked package (porting-flow.md 3).
/// - An add-on port (ADR 0009) names its host package in the top-level key
///   `host` of its `tool/port_sources.yaml`. Its `lib/` and `test/` import
///   only the public libraries of the host, the libraries directly in the
///   `lib/` of the host, never `package:<host>/src/` (ADR 0009, item 3).
///   Its `test/` imports only [addOnHarnessLibraries] of the harness package
///   (ADR 0009, item 7).
library;

import 'dart:collection';
import 'dart:io';

import 'check_support.dart';
import 'dart_source.dart';
import 'headers.dart';
import 'port_headers.dart'
    show harnessPackageName, parsePortSourcesFile, portSourcesPath;

/// The `dart:` libraries of framework-free core layers and Flutter web tests.
/// The historical pure-layer names now include dart:ui Color (ADR 0061).
const Set<String> pureDartLibraries = {
  'dart:async',
  'dart:collection',
  'dart:convert',
  'dart:core',
  'dart:math',
  'dart:typed_data',
  'dart:ui',
};

/// The other libraries of pure layers. [collectionLibrary] gives
/// `mergeSort` to `jsSort` from phase 2 (Chart.js ADR 0045, Sort).
/// `package:clock/clock.dart` gives `clock.now()` to `jsDateNow` from phase 5
/// (Chart.js ADR 0045, section 6).
const Set<String> purePackageLibraries = {
  collectionLibrary,
  'package:clock/clock.dart',
  animationLibrary,
  'package:meta/meta.dart',
  'package:intl/intl.dart',
  'package:intl/number_symbols.dart',
  'package:intl/number_symbols_data.dart',
};

/// The Flutter library of the curve classes. A core layer imports it for
/// the value of the option `easing`, a Flutter `Curve`, and for no other
/// framework API.
const String animationLibrary = 'package:flutter/animation.dart';

/// The library of `package:collection` that `lib/` can import.
const String collectionLibrary = 'package:collection/collection.dart';

/// The names that `lib/` shows from [collectionLibrary]. The other sorts of
/// the library are not those of `Array.prototype.sort` (Chart.js ADR 0045,
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
  'package:flutter/material.dart': 'Chart.js ADR 0050: no Material in lib/',
  'package:flutter/cupertino.dart': 'Chart.js ADR 0050: no Cupertino in lib/',
  'package:material_ui/': 'Chart.js ADR 0050: no Material in lib/',
  'package:forui/': 'Chart.js ADR 0050: no forui in lib/',
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
/// `core.animator` imports `helpers.extras`. The port-only
/// `reduced_motion` is a root (Chart.js ADR 0049, section 7).
/// The port-only `tick_font_cache` is a root (Chart.js ADR 0063).
///
/// `core.typedRegistry` is a root (Chart.js ADR 0020, section 10). It imports
/// `core.defaults`, `helpers.core` and the JS runtime. `core.registry` and
/// `core.plugins` are not roots: `core.registry` imports `core.scale`, which
/// imports `helpers.extras`.
///
/// The theme compiler and the internal presets of `lib/src/theme/` are
/// roots (Chart.js ADR 0050, theming.md §7). Their port-only tests run on
/// the VM, dart2js and dart2wasm. The theme widget of phase 9 uses the
/// Flutter framework, so the directory is not a root as a whole.
///
/// The files of `lib/src/options/` (the typed internal model of Chart.js ADR
/// 0054: the option cell, the scope base and the generated scopes) are
/// roots.
///
/// `plugin.decimation` and the files of `plugin.filler/` are roots (Chart.js
/// ADR 0038, section 9). Their upstream imports are helpers other than
/// `helpers.extras`, the elements and their own files. Their port-only tests
/// of the pure parts run on the VM, dart2js and dart2wasm. The other plugin
/// files are not roots: `plugin.title`, `plugin.legend` and
/// `plugin.subtitle` reach `helpers.extras`, `plugin.tooltip` imports
/// `core.animations`, and `plugin.colors` imports the controllers.
const List<String> pureRoots = [
  'lib/src/js/**',
  'lib/src/options/**',
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
  'lib/src/core/reduced_motion.dart',
  'lib/src/core/tick_font_cache.dart',
  'lib/src/core/bar_sorted_values.dart',
  'lib/src/core/point_options.dart',
  'lib/src/core/core.typedRegistry.dart',
  'lib/src/elements/**',
  'lib/src/plugins/plugin.decimation.dart',
  'lib/src/plugins/plugin.filler/**',
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
/// [animationLibrary] gives the curve classes of the option `easing`: the
/// web legs run through Flutter.
const Set<String> webTestLibraries = {
  'package:test/',
  'package:chartjs_test_utils/pure.dart',
  animationLibrary,
};

/// The directory that ported files never import.
const String themeDirectory = 'lib/src/theme/';

/// The directory of the public widgets (Chart.js ADR 0049).
const String widgetsDirectory = 'lib/src/widgets/';

/// The files that a file of [widgetsDirectory] never imports: the
/// controllers, the scales, the elements, the plugins and the two indexes
/// that register them (Chart.js ADR 0048, section 3). An entry that ends
/// with `/` is a directory.
const List<String> widgetForbiddenTargets = [
  'lib/src/controllers/',
  'lib/src/scales/',
  'lib/src/elements/',
  'lib/src/plugins/',
  'lib/src/index.dart',
  'lib/src/index.umd.dart',
];

/// The directory of the typed API (Chart.js ADR 0052). Ported files never
/// import it.
const String typedDirectory = 'lib/src/typed/';

/// The libraries that a file of [typedDirectory] can import (Chart.js ADR
/// 0052, section 8).
const Set<String> typedLibraries = {
  'dart:ui',
  animationLibrary,
  'package:flutter/foundation.dart',
  'package:flutter/painting.dart',
  'package:meta/meta.dart',
};

/// The files of the package that a file of [typedDirectory] can import
/// (Chart.js ADR 0052, section 8). An entry that ends with `/` is a
/// directory.
///
/// The typed API writes option keys, not components: no file of
/// [typedDirectory] imports a controller, a scale, an element or a plugin,
/// so the tree shaking of Chart.js ADR 0048, section 3, stays. It reads
/// `Chart` of `core.controller`, `Scale` of `core.scale`, `TimeUnit` of
/// `core.adapters`, `InteractionMode` of `core.interaction`,
/// `TooltipPositioner` of `tooltip_position.dart` and `FillerDrawTime` of
/// `filler_draw_time.dart` (pure files with no plugin), the types of
/// `lib/src/types/`, the typed option scopes
/// of `lib/src/options/` (the lowering writes typed scopes, Chart.js ADR
/// 0054 §7) and the typed contexts of `helpers.options.dart` (the view
/// `ChartContext`, Chart.js ADR 0054 §11), three files of the JS runtime and
/// the conversions of `css.dart`. `helpers.options.dart` imports
/// `core.defaults`, `helpers.canvas`, `helpers.core`, the JS runtime and
/// `lib/src/types/`, no component. The cubic interpolation modes are the
/// pure `cubic_interpolation_mode.dart` and `helpers.curve.dart`, and the
/// base of the point styles is the pure `point_style.dart`.
const List<String> typedTargets = [
  typedDirectory,
  'lib/src/types/',
  'lib/src/options/',
  'lib/src/helpers/helpers.options.dart',
  'lib/src/helpers/cubic_interpolation_mode.dart',
  'lib/src/helpers/helpers.curve.dart',
  'lib/src/helpers/point_style.dart',
  'lib/src/core/core.adapters.dart',
  'lib/src/core/core.controller.dart',
  'lib/src/core/core.interaction.dart',
  'lib/src/core/data_update.dart',
  'lib/src/core/core.scale.dart',
  'lib/src/core/scale_option_enums.dart',
  'lib/src/js/js_function.dart',
  'lib/src/js/js_number.dart',
  'lib/src/js/js_undefined.dart',
  'lib/src/plugins/filler_draw_time.dart',
  'lib/src/plugins/tooltip_position.dart',
  'lib/src/theme/css.dart',
];

/// The pure-layer root of the harness package (porting-flow.md 3).
const String harnessPureRoot = 'lib/pure.dart';

/// The libraries that the harness pure layer can import in addition to the
/// pure ones and the pure layers of the checked package. An entry that ends
/// with `/` is a prefix.
const Set<String> harnessPureLibraries = {'package:test/'};

/// The libraries of the harness package that the tests of an add-on port can
/// import (ADR 0009, item 7). Other `package:chartjs_test_utils/` URIs, for
/// example `src/`, are errors.
const Set<String> addOnHarnessLibraries = {
  'package:$harnessPackageName/flutter.dart',
  'package:$harnessPackageName/pure.dart',
};

/// The host of an add-on port: its package name and its public libraries.
final class _Host {
  const _Host(this.name, this.libraries);

  /// The package name, for example `flutter_chartjs_port`.
  final String name;

  /// The URIs of the libraries directly in the `lib/` of the host, sorted.
  final List<String> libraries;
}

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
/// The guard skips the closure for an add-on port: the harness imports the
/// pure layers of the host, not of the add-on.
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

  final host = _readHost(packageDirectory, displayPrefix, findings);

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
      final hostImport = host == null ? null : _isHostAllowed(edge.uri, host);
      if (forbidden != null) {
        report(library, edge.line, 'imports ${edge.uri} ($forbidden).');
      } else if (hostImport != null) {
        if (!hostImport) {
          report(library, edge.line, _hostMessage(edge.uri, host!));
        }
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

  // The tests of an add-on port: the public libraries of the host and of
  // the harness.
  if (host != null) {
    for (final library in libraries.values) {
      if (!library.path.startsWith('test/')) continue;
      for (final edge in library.edges) {
        if (edge.target != null) continue;
        final uri = edge.uri;
        if (_isHostAllowed(uri, host) == false) {
          report(library, edge.line, _hostMessage(uri, host));
        } else if (uri.startsWith('package:$harnessPackageName/') &&
            !addOnHarnessLibraries.contains(uri)) {
          report(
            library,
            edge.line,
            'imports $uri, but the tests of an add-on port import only '
            '${addOnHarnessLibraries.join(' and ')} of the harness (ADR '
            '0009, item 7).',
          );
        }
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
          '"show ${collectionNames.join(', ')}" (Chart.js ADR 0045, Sort).',
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
      final reason = edge.uri.startsWith('package:flutter/')
          ? 'core layers import no package:flutter'
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

  // Ported files, the theme and the typed API.
  for (final library in libraries.values) {
    if (library.header.kind != HeaderKind.ported) continue;
    for (final edge in library.edges) {
      if (edge.target?.startsWith(themeDirectory) ?? false) {
        report(
          library,
          edge.line,
          'imports ${edge.target}, but ported files never import '
          '$themeDirectory (Chart.js ADR 0050).',
        );
      }
      if (edge.target?.startsWith(typedDirectory) ?? false) {
        report(
          library,
          edge.line,
          'imports ${edge.target}, but ported files never import '
          '$typedDirectory (Chart.js ADR 0052 §8).',
        );
      }
    }
  }

  // The allowlist of the typed API.
  for (final library in libraries.values) {
    if (!library.path.startsWith(typedDirectory)) continue;
    for (final edge in library.edges) {
      final target = edge.target;
      final allowed = target == null
          ? typedLibraries.contains(edge.uri)
          : typedTargets.any(
              (entry) => entry.endsWith('/')
                  ? target.startsWith(entry)
                  : target == entry,
            );
      if (!allowed) {
        report(
          library,
          edge.line,
          'imports ${target ?? edge.uri}, which is not on the allowlist of '
          '$typedDirectory (Chart.js ADR 0052 §8).',
        );
      }
    }
  }

  // The widgets and the components.
  for (final library in libraries.values) {
    if (!library.path.startsWith(widgetsDirectory)) continue;
    for (final edge in library.edges) {
      final target = edge.target;
      if (target == null) continue;
      final forbidden = widgetForbiddenTargets.any(
        (entry) =>
            entry.endsWith('/') ? target.startsWith(entry) : target == entry,
      );
      if (forbidden) {
        report(
          library,
          edge.line,
          'imports $target, but the widget registers no component '
          '(Chart.js ADR 0048 §3).',
        );
      }
    }
  }

  var files = libraries.length;
  if (harnessDirectory != null &&
      host == null &&
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

/// The host of the package in [packageDirectory] when it is an add-on port:
/// the top-level key `host` of its [portSourcesPath]. The host package is
/// next to the package. Null for a package without the key. Adds a finding
/// when the file or the host cannot be read.
_Host? _readHost(
  String packageDirectory,
  String displayPrefix,
  List<Finding> findings,
) {
  final file = File('$packageDirectory/$portSourcesPath');
  if (!file.existsSync()) return null;
  void report(String message) =>
      findings.add(Finding('$displayPrefix$portSourcesPath', null, message));
  final String? name;
  try {
    name = parsePortSourcesFile(file.readAsStringSync()).host;
  } on FileSystemException catch (e) {
    report(e.message);
    return null;
  } on FormatException catch (e) {
    report(e.message);
    return null;
  }
  if (name == null) return null;
  final parent = posixPath(Directory(packageDirectory).parent.path);
  final directory = '$parent/$name';
  final lib = Directory('$directory/lib');
  String? actual;
  try {
    actual = _packageName(directory);
  } on FileSystemException {
    actual = null;
  } on FormatException {
    actual = null;
  }
  if (actual != name || !lib.existsSync()) {
    report('the host package $name is not next to the package (ADR 0009).');
    return _Host(name, const []);
  }
  return _Host(
    name,
    [
      for (final entity in lib.listSync())
        if (entity is File && entity.path.endsWith('.dart'))
          'package:$name/${posixPath(entity.path).split('/').last}',
    ]..sort(),
  );
}

/// Whether [uri] is a library of [host] that an add-on port can import, or
/// null when [uri] is not a library of [host].
bool? _isHostAllowed(String uri, _Host host) {
  if (!uri.startsWith('package:${host.name}/')) return null;
  return host.libraries.contains(uri);
}

/// The finding of an import of [uri], a library of [host] that is not a
/// public library.
String _hostMessage(String uri, _Host host) {
  final libraries = host.libraries.isEmpty
      ? ''
      : ': ${host.libraries.join(', ')}';
  return 'imports $uri, but an add-on port imports only the public libraries '
      'of its host ${host.name}$libraries (ADR 0009, item 3).';
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
