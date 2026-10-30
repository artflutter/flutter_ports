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

import '../../tool/src/js_semantics.dart' show dartSdkPath;

// The public API of the package (Chart.js ADR 0048, sections 5 and 6):
// `lib/chartjs.dart` (the `chart.js` entry), `lib/helpers.dart` (the
// `chart.js/helpers` entry) and `lib/flutter_chartjs_port.dart` (the app
// library). The test resolves the three libraries with package:analyzer.
//
// 1. The sorted export names of each library are the committed list
//    `doc/public_api.txt`. After a change of the public API, write the list
//    again with `PUBLIC_API_UPDATE=1 flutter test test/tool/public_api_test.dart`
//    and review its diff: after 0.1.0, each public name is a commitment.
// 2. The app library shares no name with `package:flutter/widgets.dart`,
//    `material.dart`, `cupertino.dart` or `dart:ui`. A file of an app imports
//    it next to Flutter with no prefix and no `hide`.
// 3. No exported top-level declaration has `@internal`. Each member of an
//    exported concrete class whose first `///` line names an upstream `_`
//    member (the form "<file>:<line> `_name`") has `@internal`, because the
//    analyzer then reports a use from another package
//    (`invalid_use_of_internal_member`). `_internalFalseHits` lists the
//    members whose `_` name is not the member itself.
// 4. `chartjs.dart` covers each runtime export of `src/index.ts` and each
//    declaration of `src/types/*.d.ts` that a file of `lib/src/` declares as
//    a type of the same name, and `helpers.dart` covers each runtime export of
//    `src/helpers/index.ts` (the `exports` of `doc/upstream/manifest.json`,
//    tool 4). A `_` export of upstream stays internal. A covered name is an
//    export of the library, a name of its hide list, or a name of
//    `_notExported` with its reason.

/// The three public libraries, by their path in the package.
const List<String> _libraries = [
  'lib/chartjs.dart',
  'lib/flutter_chartjs_port.dart',
  'lib/helpers.dart',
];

/// The Flutter libraries of case 2.
const List<String> _flutterLibraries = [
  'package:flutter/widgets.dart',
  'package:flutter/material.dart',
  'package:flutter/cupertino.dart',
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

/// The names of `src/types/*.d.ts` that a library of `lib/src/` declares
/// and `chartjs.dart` does not export, each with its reason.
const Map<String, String> _notExported = {
  // Another declaration under the upstream name.
  'Color':
      'the class of @kurkle/color; the upstream type is a union of a '
      'string, a CanvasGradient and a CanvasPattern',
  'Legend':
      'the element class of plugin.legend; the upstream Legend is the '
      'plugin object, the export legend',
  'Title':
      'the element class of plugin.title; the upstream Title is the '
      'plugin object, the export title',
  'Tooltip':
      'the element class of plugin.tooltip; the upstream Tooltip is '
      'the plugin object, the export tooltip',
  // Not in the export list of Chart.js ADR 0048, section 5: a later export
  // is an addition (Open point of the phase 9 report).
  'AnimationEvent': 'not in the ADR 0048 export list',
  'AnimationSpec': 'not in the ADR 0048 export list',
  'Animator': 'not in the ADR 0048 export list',
  'AnyObject': 'not in the ADR 0048 export list',
  'ArcOptions': 'not in the ADR 0048 export list',
  'ArcProps': 'not in the ADR 0048 export list',
  'BarOptions': 'not in the ADR 0048 export list',
  'EasingFunction': 'not in the ADR 0048 export list',
  'InteractionItem': 'not in the ADR 0048 export list',
  'InteractionModeFunction': 'not in the ADR 0048 export list',
  'LineOptions': 'not in the ADR 0048 export list',
  'PointOptions': 'not in the ADR 0048 export list',
  'PointProps': 'not in the ADR 0048 export list',
  'Registry': 'not in the ADR 0048 export list',
  'RoundedRect': 'not in the ADR 0048 export list',
  'SplinePoint': 'not in the ADR 0048 export list',
  'TRBLCorners': 'not in the ADR 0048 export list',
  'TypedRegistry': 'not in the ADR 0048 export list',
  // The typed plugin of Chart.js ADR 0054 section 12: internal until the
  // typed public plugin API (its Open 2); a plugin of user code is a Map.
  'Plugin': 'the typed plugin of ADR 0054',
  // The typed contexts of Chart.js ADR 0054 section 11: internal, a context
  // is a ContextObject of lib/helpers.dart.
  'ScriptableChartContext': 'a typed context of ADR 0054',
  'ScriptableContext': 'a typed context of ADR 0054',
  'ScriptableLineSegmentContext': 'a typed context of ADR 0054',
  'ScriptableScaleContext': 'a typed context of ADR 0054',
  'ScriptableScalePointLabelContext': 'a typed context of ADR 0054',
  'ScriptableTooltipContext': 'a typed context of ADR 0054',
  // The typed plugin types of Chart.js ADR 0054 section 12 (the option
  // facades, the legend and tooltip items): internal in 0.1.0.
  'DecimationOptions': 'an internal typed plugin type of Chart.js ADR 0054',
  'FillerOptions': 'an internal typed plugin type of Chart.js ADR 0054',
  'LegendItem': 'an internal typed plugin type of Chart.js ADR 0054',
  'LegendOptions': 'an internal typed plugin type of Chart.js ADR 0054',
  'TitleOptions': 'an internal typed plugin type of Chart.js ADR 0054',
  'TooltipOptions': 'an internal typed plugin type of Chart.js ADR 0054',
};

/// The members of an exported concrete class whose `_` doc name is not the
/// member itself, each with its reason.
const Map<String, String> _internalFalseHits = {};

/// The first line of a doc comment that names an upstream `_` member:
/// `/// <file>:<line> \`_name...\``.
final RegExp _underscoreDoc = RegExp(
  r'^///\s*\S+\.(?:js|ts):[\d, :-]*\s*`(_[A-Za-z$][\w$]*)',
);

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

/// The names of the `hide` combinators of the exports of [library].
Set<String> _hiddenNames(LibraryElement library) => {
  for (final directive in library.firstFragment.libraryExports)
    for (final combinator in directive.combinators)
      if (combinator is HideElementCombinator) ...combinator.hiddenNames,
};

/// A top-level type declaration of a Dart file: a class, mixin, enum,
/// typedef, extension or extension type, and its name.
final RegExp _typeDeclaration = RegExp(
  r'^(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*'
  r'(?:class|mixin|enum|typedef|extension\s+type|extension)\s+([A-Za-z_]\w*)',
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

/// The public members of [element] that its source declares.
Iterable<Element> _members(ClassElement element) => [
  for (final member in <Element>[
    ...element.fields.where((f) => f.isOriginDeclaration),
    ...element.getters.where((g) => g.isOriginDeclaration),
    ...element.setters.where((s) => s.isOriginDeclaration),
    ...element.methods,
  ])
    if (member.isPublic) member,
];

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

  test(
    'the export names are the list of doc/public_api.txt',
    () async {
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
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'the app library shares no name with Flutter',
    () async {
      final app = _exportNames(
        await _library('lib/flutter_chartjs_port.dart'),
      );
      for (final uri in _flutterLibraries) {
        final flutter = _exportNames(await _libraryByUri(uri));
        expect(app.intersection(flutter), isEmpty, reason: uri);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'no export is internal, and each upstream _ member is',
    () async {
      final findings = <String>{};
      for (final path in _libraries) {
        final names = (await _library(path)).exportNamespace.definedNames2;
        for (final MapEntry(key: name, value: element) in names.entries) {
          if (name.endsWith('=')) continue;
          if (element.metadata.hasInternal) {
            findings.add('$name has @internal');
          }
          if (element is! ClassElement || element.isAbstract) continue;
          for (final member in _members(element)) {
            final doc = member.documentationComment?.split('\n').first;
            final match = doc == null ? null : _underscoreDoc.firstMatch(doc);
            if (match == null) continue;
            final key = '$name.${member.displayName}';
            if (_internalFalseHits.containsKey(key)) continue;
            if (!member.metadata.hasInternal) {
              findings.add('$key (upstream ${match[1]}) has no @internal');
            }
          }
        }
      }
      expect(findings.toList()..sort(), isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'types',
    () async {
      final manifest = jsonDecode(
        File('doc/upstream/manifest.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final exports = manifest['exports']! as Map<String, Object?>;
      List<String> list(String key) => [
        for (final name
            in (exports[key]! as Map<String, Object?>)['names']!
                as List<Object?>)
          name! as String,
      ];

      final chartjs = await _library('lib/chartjs.dart');
      final chartjsNames = _exportNames(chartjs);
      final hidden = _hiddenNames(chartjs);
      final findings = <String>[];

      // src/index.ts: each runtime export, a `_` export as a hidden name.
      for (final name in list('index')) {
        if (name.startsWith('_')) {
          final dart = name.substring(1);
          if (chartjsNames.contains(dart) || !hidden.contains(dart)) {
            findings.add('chartjs.dart: $name is not hidden as $dart');
          }
        } else {
          final dart = _dartNames[name] ?? name;
          if (!chartjsNames.contains(dart)) {
            findings.add('chartjs.dart: $name ($dart) is not exported');
          }
        }
      }

      // src/types/*.d.ts: each declaration that lib/src/ declares.
      final declared = _declaredNames();
      for (final name in list('types')) {
        if (!declared.contains(name)) continue;
        if (chartjsNames.contains(name) ||
            hidden.contains(name) ||
            _notExported.containsKey(name)) {
          continue;
        }
        findings.add('chartjs.dart: the type $name is not exported');
      }
      for (final name in _notExported.keys) {
        if (!declared.contains(name) || chartjsNames.contains(name)) {
          findings.add('_notExported: $name is stale');
        }
      }

      // src/helpers/index.ts: each runtime export but the `_` exports.
      final helpers = _exportNames(await _library('lib/helpers.dart'));
      for (final name in list('helpers')) {
        if (name.startsWith('_')) {
          if (helpers.contains(name.substring(1))) {
            findings.add('helpers.dart: $name is exported');
          }
        } else {
          final dart = _helperConstants[name] ?? name;
          if (!helpers.contains(dart)) {
            findings.add('helpers.dart: $name ($dart) is not exported');
          }
        }
      }
      expect(findings, isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
