// Original code, not ported from Chart.js: the public API test.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:test/test.dart';

import '../../tool/src/dart_sdk.dart';

// The public API of the package (Chart.js ADR 0048, sections 5 and 6, and
// Chart.js ADR 0108): `lib/chartjs.dart` (the `chart.js` entry),
// `lib/helpers.dart` (the `chart.js/helpers` entry),
// `lib/flutter_chartjs_port.dart` (the app library) and
// `lib/js_semantics.dart` (the JS runtime for add-on ports). The test
// resolves the four libraries with package:analyzer.
//
// 1. The sorted export names of each library are the committed list
//    `doc/public_api.txt`. After a change of the public API, write the list
//    again with `PUBLIC_API_UPDATE=1 flutter test test/tool/public_api_test.dart`
//    and review its diff: after 0.1.0, each public name is a commitment.
// 2. The app library exports `chartjs.dart` without the names that
//    `package:flutter/widgets.dart`, `material.dart`, `cupertino.dart` or
//    `dart:ui` also have ([_flutterNames]), and it shares no name with them.
//    A file of an app imports it next to Flutter with no prefix and no
//    `hide`.
// 3. No exported top-level declaration has `@internal`.
// 4. `chartjs.dart` exports each public top-level declaration of each file
//    of `lib/src/` (ADR 0012). It covers each runtime export of
//    `src/index.ts`, a `_` export under its name without the `_`, and each
//    declaration of `src/types/*.d.ts` that a file of `lib/src/` declares.
//    `helpers.dart` covers each runtime export of `src/helpers/index.ts` (the
//    `exports` of `doc/upstream/manifest.json`, tool 4). A `_` export of
//    upstream stays out of it, except a name of `_addOnHelpers` (Chart.js ADR
//    0108).

/// The four public libraries, by their path in the package.
const List<String> _libraries = [
  'lib/chartjs.dart',
  'lib/flutter_chartjs_port.dart',
  'lib/helpers.dart',
  'lib/js_semantics.dart',
];

/// The `_` exports of `src/helpers/index.ts` that a ported add-on imports:
/// `helpers.dart` exports their Dart names (Chart.js ADR 0108).
const Set<String> _addOnHelpers = {'_isPointInArea'};

/// The runtime helpers of `src/helpers/index.ts` that `helpers.dart` does
/// not export, with the reason.
const Map<String, String> _notExportedHelpers = {
  'createContext':
      'each context is the typed class of its type, made with its '
      'constructor (row adapt-typed-contexts)',
  'getStyle':
      'the canvas has no style: its display size is displayWidth and '
      'displayHeight (row adapt-native-canvas-style)',
  'fontString':
      'no CSS font text: the canvas takes the TextStyle '
      '(row adapt-text-style-fonts)',
  'noop':
      'no empty default callback: a tooltip callback that is null takes the '
      'built-in default (row adapt-tooltip-callback-objects)',
  'toDimension':
      'the method pixelsOf of RadiusLength and amountOf of GraceLength '
      '(row adapt-length-objects)',
  'toPercentage':
      'the method fractionOf of RadiusLength (row adapt-length-objects)',
  'toFontString':
      'no CSS font text: the canvas takes the TextStyle '
      '(row adapt-text-style-fonts)',
  'toLineHeight':
      'the field lineHeight of ChartTextStyle (row adapt-text-style-fonts)',
};

/// The Flutter libraries of case 2.
const List<String> _flutterLibraries = [
  'package:flutter/widgets.dart',
  'package:flutter/material.dart',
  'package:material_ui/material_ui.dart',
  'package:flutter/cupertino.dart',
  'package:cupertino_ui/cupertino_ui.dart',
  'dart:ui',
];

/// The upstream names of `src/index.ts` whose Dart name differs (Chart.js
/// ADR 0012, Chart.js ADR 0038, section 1, Chart.js ADR 0037, section 1).
const Map<String, String> _dartNames = {
  'Colors': 'colors',
  'Decimation': 'decimation',
  'DomPlatform': 'FlutterPlatform',
  'Filler': 'filler',
  'Legend': 'legend',
  'SubTitle': 'subTitle',
  'Ticks': 'ticks',
  'Title': 'title',
  'Tooltip': 'tooltip',
};

/// The upper case constants of `helpers.math.ts` and their Dart names.
const Map<String, String> _helperConstants = {
  'HALF_PI': 'halfPi',
  'INFINITY': 'infinity',
  'PI': 'pi',
  'PITAU': 'piTau',
  'QUARTER_PI': 'quarterPi',
  'RAD_PER_DEG': 'radPerDeg',
  'TAU': 'tau',
  'TWO_THIRDS_PI': 'twoThirdsPi',
};

/// The names that the app library hides: Flutter has them too.
const Set<String> _flutterNames = {
  'Animation',
  'Element',
  'FilterCallback',
  'Title',
  'Tooltip',
};

/// The absolute, normalized form of [path] for the analyzer.
String _normalized(String path) {
  final context = PhysicalResourceProvider.INSTANCE.pathContext;
  return context.normalize(context.absolute(path));
}

late AnalysisContextCollection _collection;
late AnalysisSession _session;

/// The library of the package at [path].
Future<LibraryElement> _library(String path) async {
  final result = await _session.getResolvedLibrary(_normalized(path));
  if (result is! ResolvedLibraryResult) {
    throw StateError('$path: the analyzer gives $result');
  }
  return result.element;
}

/// The library of [uri], for example `package:flutter/widgets.dart`.
Future<LibraryElement> _libraryByUri(String uri) async {
  final result = await _session.getLibraryByUri(uri);
  if (result is! LibraryElementResult) {
    throw StateError('$uri: the analyzer gives $result');
  }
  return result.element;
}

/// The export names of [library], without the names of setters.
Set<String> _exportNames(LibraryElement library) => {
  for (final name in library.exportNamespace.definedNames2.keys)
    if (!name.endsWith('=')) name,
};

/// A top-level type declaration of a Dart file: a class, mixin, enum,
/// typedef, extension or extension type, and its name.
final RegExp _typeDeclaration = RegExp(
  r'^(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*'
  r'(?:class|mixin|enum|typedef|extension\s+type(?:\s+const)?|extension)'
  r'\s+([A-Za-z_]\w*)',
  multiLine: true,
);

/// The names of the top-level type declarations of the Dart files of
/// `lib/src/`.
Set<String> _declaredNames() => {
  for (final entity in Directory('lib/src').listSync(recursive: true))
    if (entity is File && entity.path.endsWith('.dart'))
      for (final match in _typeDeclaration.allMatches(
        entity.readAsStringSync(),
      ))
        match[1]!,
};

/// The public top-level names that the files of `lib/src/` declare.
Future<Set<String>> _sourceNames() async {
  final names = <String>{};
  for (final entity in Directory('lib/src').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final library = await _library(entity.path);
    for (final element in library.children) {
      final name = element.name;
      if (name != null && element.isPublic && !name.endsWith('=')) {
        names.add(name);
      }
    }
  }
  return names;
}

void main() {
  setUpAll(() {
    _collection = AnalysisContextCollection(
      includedPaths: [_normalized('lib')],
      sdkPath: dartSdkPath(),
    );
    _session = _collection
        .contextFor(_normalized(_libraries.first))
        .currentSession;
  });

  tearDownAll(() => _collection.dispose());

  test('the export names are the list of doc/public_api.txt', () async {
    final sections = <String>[];
    for (final path in _libraries) {
      final names = _exportNames(await _library(path)).toList()..sort();
      sections.add(['[$path]', ...names].join('\n'));
    }
    final text = '${sections.join('\n\n')}\n';
    final file = File('doc/public_api.txt');
    if (Platform.environment['PUBLIC_API_UPDATE'] == '1') {
      file.writeAsStringSync(text);
    }
    expect(
      file.readAsStringSync().replaceAll('\r\n', '\n'),
      text,
      reason:
          'The public API changed. Review the change, then write the list '
          'again with PUBLIC_API_UPDATE=1.',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('the app library shares no name with Flutter', () async {
    final app = _exportNames(await _library('lib/flutter_chartjs_port.dart'));
    final chartjs = _exportNames(await _library('lib/chartjs.dart'));
    expect(chartjs.difference(app), _flutterNames);
    for (final uri in _flutterLibraries) {
      final flutter = _exportNames(await _libraryByUri(uri));
      expect(app.intersection(flutter), isEmpty, reason: uri);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('no export is internal', () async {
    final findings = <String>{};
    for (final path in _libraries) {
      final names = (await _library(path)).exportNamespace.definedNames2;
      for (final MapEntry(key: name, value: element) in names.entries) {
        if (name.endsWith('=')) continue;
        if (element.metadata.hasInternal) {
          findings.add('$name has @internal');
        }
      }
    }
    expect(findings.toList()..sort(), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('types', () async {
    final manifest = jsonDecode(
      File('doc/upstream/manifest.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final exports = manifest['exports']! as Map<String, Object?>;
    List<String> list(String key) => [
      for (final name
          in (exports[key]! as Map<String, Object?>)['names']! as List<Object?>)
        name! as String,
    ];

    final chartjsNames = _exportNames(await _library('lib/chartjs.dart'));
    final findings = <String>[];

    // Each public top-level name of lib/src/.
    for (final name in await _sourceNames()) {
      if (!chartjsNames.contains(name)) {
        findings.add('chartjs.dart: $name is not exported');
      }
    }

    // src/index.ts: each runtime export, a `_` export without the `_`.
    for (final name in list('index')) {
      final dart = name.startsWith('_')
          ? name.substring(1)
          : _dartNames[name] ?? name;
      if (!chartjsNames.contains(dart)) {
        findings.add('chartjs.dart: $name ($dart) is not exported');
      }
    }

    // src/types/*.d.ts: each declaration that lib/src/ declares.
    final declared = _declaredNames();
    for (final name in list('types')) {
      if (declared.contains(name) && !chartjsNames.contains(name)) {
        findings.add('chartjs.dart: the type $name is not exported');
      }
    }

    // src/helpers/index.ts: each runtime export but the `_` exports that
    // no ported add-on imports.
    final helpers = _exportNames(await _library('lib/helpers.dart'));
    for (final name in _addOnHelpers) {
      if (!list('helpers').contains(name)) {
        findings.add('_addOnHelpers: $name is stale');
      }
    }
    for (final name in list('helpers')) {
      if (name.startsWith('_')) {
        final exported = helpers.contains(name.substring(1));
        if (_addOnHelpers.contains(name) && !exported) {
          findings.add('helpers.dart: $name is not exported');
        } else if (!_addOnHelpers.contains(name) && exported) {
          findings.add('helpers.dart: $name is exported');
        }
      } else if (!_notExportedHelpers.containsKey(name)) {
        final dart = _helperConstants[name] ?? name;
        if (!helpers.contains(dart)) {
          findings.add('helpers.dart: $name ($dart) is not exported');
        }
      }
    }
    expect(findings, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
