// Original code, not ported from Chart.js: the test font of the harness.

/// The test font of the harness (Chart.js ADR 0015, porting-flow.md
/// section 3 and 2.8).
///
/// Upstream runs its specs in Chrome on Ubuntu. There, the default family of
/// Chart.js, `"'Helvetica Neue', 'Helvetica', 'Arial', sans-serif"`, resolves
/// to Liberation Sans, which has the metrics of Arial and Helvetica. The
/// flutter tester resolves every family to its square test font. Thus the
/// specs that measure text (`toBeCloseToPixel`) would measure other widths.
/// [installTestFont] registers Liberation Sans 2.1.5 (SIL OFL 1.1,
/// `lib/fonts/LICENSE`) under the names of [testFontFamilies].
///
/// This library is not a pure layer: it imports `dart:io` and
/// `package:flutter`. It runs in `flutter test` only.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// The family names that [installTestFont] registers.
///
/// - `Helvetica Neue`, `Helvetica` and `Arial`: the families of the Chart.js
///   default font (`core.defaults.js:55`).
/// - `Liberation Sans`: the name of the font itself.
/// - `sans-serif`: the generic family. A text style that names it gets the
///   test font. A text style with no family gets the square test font of the
///   flutter tester: a registered font cannot replace it.
const List<String> testFontFamilies = [
  'Helvetica Neue',
  'Helvetica',
  'Arial',
  'Liberation Sans',
  'sans-serif',
];

/// The font files of the test font, in `lib/fonts/`: regular, bold, italic
/// and bold italic. Each family of [testFontFamilies] gets all four. The
/// engine picks the face by the weight and the style of the text.
const List<String> testFontFiles = [
  'LiberationSans-Regular.ttf',
  'LiberationSans-Bold.ttf',
  'LiberationSans-Italic.ttf',
  'LiberationSans-BoldItalic.ttf',
];

/// The name of this package in `package_config.json`.
const String _packageName = 'chartjs_test_utils';

Future<void>? _installed;

/// Registers the test font under each name of [testFontFamilies].
///
/// The first call loads the files. Later calls in the same isolate return
/// the same future: the engine keeps registered fonts for the life of the
/// isolate.
Future<void> installTestFont() => _installed ??= _install();

Future<void> _install() async {
  final fontsDirectory = _packageLibDirectory().resolve('fonts/');
  final fonts = await Future.wait([
    for (final file in testFontFiles)
      File.fromUri(fontsDirectory.resolve(file)).readAsBytes(),
  ]);
  for (final family in testFontFamilies) {
    final loader = FontLoader(family);
    for (final bytes in fonts) {
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

/// The `lib/` directory of this package, as a directory URI.
///
/// `Isolate.resolvePackageUri` is not supported in the flutter tester. Thus
/// the function reads the `.dart_tool/package_config.json` of the current
/// directory or of its nearest ancestor that has one: `flutter test` runs in
/// the package directory, and the workspace root has the package config.
Uri _packageLibDirectory() {
  var directory = Directory.current.absolute;
  while (true) {
    final config = File('${directory.path}/.dart_tool/package_config.json');
    if (config.existsSync()) {
      final lib = _libDirectoryIn(config);
      if (lib != null) return lib;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError(
        'No .dart_tool/package_config.json above ${Directory.current.path} '
        'lists $_packageName. Run flutter pub get.',
      );
    }
    directory = parent;
  }
}

/// The `lib/` directory of this package in the package config [config], or
/// null when [config] does not list the package.
Uri? _libDirectoryIn(File config) {
  final json = jsonDecode(config.readAsStringSync()) as Map<String, Object?>;
  final packages = json['packages']! as List<Object?>;
  for (final package in packages.cast<Map<String, Object?>>()) {
    if (package['name'] != _packageName) continue;
    final rootUri = _directoryUri(package['rootUri']! as String);
    final root = config.uri.resolve(rootUri);
    return root.resolve(_directoryUri(package['packageUri'] as String? ?? ''));
  }
  return null;
}

/// [uri] with a trailing `/`, so that it resolves as a directory.
String _directoryUri(String uri) =>
    uri.isEmpty || uri.endsWith('/') ? uri : '$uri/';
