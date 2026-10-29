// Original code, not ported from Chart.js: the one implementer of the point interfaces.
// ignore_for_file: lines_longer_than_80_chars
@TestOn('vm')
library;

// Chart.js ADR 0040, section 11: no class in lib/ other than the class
// `PointElement` of lib/src/elements/element.point.dart implements,
// extends or mixes in `types.PointElement`, `types.RadialPointElement` or
// `types.SplinePoint`. A second implementer anywhere in the program makes
// every curved line 64 to 70 % slower on AOT and about 2 times slower on
// dart2wasm, also in a chart without a fill (the Benchmarks of the ADR and
// performance.md). The test resolves the element model of lib/ with
// package:analyzer, as check:js-semantics does, and reads the
// `allSupertypes` of each class, mixin and enum. Thus a mixin application
// class (`class C = S with M implements I;`), a type alias of an interface
// and an indirect supertype do not escape the scan. It does not examine
// apps/ and test/ (ADR 0040, Open 4).

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/simpleArc.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

import '../../../../tool/src/js_semantics.dart' show dartSdkPath;

/// The point interfaces: the library URI and the name of each.
const Set<String> _pointInterfaces = {
  'package:flutter_chartjs_port/src/types/index.dart PointElement',
  'package:flutter_chartjs_port/src/types/index.dart RadialPointElement',
  'package:flutter_chartjs_port/src/types/geometric.dart SplinePoint',
};

/// The allowed declarations: the interfaces of lib/src/types/ and the
/// class of lib/src/elements/element.point.dart.
const Set<String> _allowed = {
  'package:flutter_chartjs_port/src/types/index.dart PointElement',
  'package:flutter_chartjs_port/src/types/index.dart RadialPointElement',
  'package:flutter_chartjs_port/src/elements/element.point.dart PointElement',
};

/// The absolute, normalized form of [path] for the analyzer.
String _normalized(String path) {
  final context = PhysicalResourceProvider.INSTANCE.pathContext;
  return context.normalize(context.absolute(path));
}

/// The classes, mixins and enums of the Dart files under [root] that have a
/// point interface in their `allSupertypes`, sorted. Each record is the
/// library URI and the name of the declaration, then the interface name.
Future<List<(String, String)>> pointImplementers(String root) async {
  final dir = _normalized(root);
  final files = [
    for (final entity in Directory(dir).listSync(recursive: true))
      if (entity is File && entity.path.endsWith('.dart'))
        _normalized(entity.path),
  ]..sort();
  final collection = AnalysisContextCollection(
    includedPaths: [dir],
    sdkPath: dartSdkPath(),
  );
  final libraries = <String, LibraryElement>{};
  try {
    for (final path in files) {
      final result = await collection
          .contextFor(path)
          .currentSession
          .getUnitElement(path);
      if (result is! UnitElementResult) {
        throw StateError('$path: the analyzer gives $result');
      }
      final library = result.fragment.element;
      libraries['${library.uri}'] = library;
    }
  } finally {
    await collection.dispose();
  }
  final found = <(String, String)>[];
  for (final library in libraries.values) {
    for (final element in <InterfaceElement>[
      ...library.classes,
      ...library.mixins,
      ...library.enums,
    ]) {
      for (final supertype in element.allSupertypes) {
        final interface = supertype.element;
        final key = '${interface.library.uri} ${interface.name}';
        if (_pointInterfaces.contains(key)) {
          found.add(('${library.uri} ${element.name}', interface.name!));
        }
      }
    }
  }
  return found..sort((a, b) => '$a'.compareTo('$b'));
}

/// The package config of the workspace with absolute root URIs, for a
/// folder outside the workspace.
String _absolutePackageConfig() {
  var dir = Directory.current.absolute;
  while (!File('${dir.path}/.dart_tool/package_config.json').existsSync()) {
    if (dir.parent.path == dir.path) {
      throw StateError('No .dart_tool/package_config.json above the package');
    }
    dir = dir.parent;
  }
  final file = File('${dir.path}/.dart_tool/package_config.json');
  final config = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  for (final package in config['packages']! as List<Object?>) {
    final entry = package! as Map<String, Object?>;
    entry['rootUri'] = file.uri.resolve(entry['rootUri']! as String).toString();
  }
  return jsonEncode(config);
}

/// The probe library of the scan test: two implementers that a text scan
/// does not find (the review finding F1), one direct implementer, one
/// indirect implementer, and four forms that are not implementers.
const String _probe = '''
import 'package:flutter_chartjs_port/src/elements/element.point.dart' as el;
import 'package:flutter_chartjs_port/src/types/geometric.dart' as geo;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

mixin Forward {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class AppPoint = Object with Forward implements types.PointElement;

typedef Spline = geo.SplinePoint;

final class AliasPoint with Forward implements Spline {}

final class Direct with Forward implements types.RadialPointElement {}

final class Indirect extends el.PointElement {}

class Bound<T extends types.PointElement> {}

// class Comment implements types.PointElement {}

const String text = 'class Text implements types.PointElement {}';

final class Other with Forward implements geo.Point {}
''';

void main() {
  test('the scan finds an implementer', () async {
    final temp = Directory.systemTemp.createTempSync('point_implementers_');
    addTearDown(() => temp.deleteSync(recursive: true));
    Directory('${temp.path}/.dart_tool').createSync();
    File(
      '${temp.path}/.dart_tool/package_config.json',
    ).writeAsStringSync(_absolutePackageConfig());
    File('${temp.path}/probe.dart').writeAsStringSync(_probe);
    final uri = Uri.file(_normalized('${temp.path}/probe.dart'));
    final found = await pointImplementers(temp.path);
    expect(found, [
      ('$uri AliasPoint', 'SplinePoint'),
      ('$uri AppPoint', 'PointElement'),
      ('$uri AppPoint', 'SplinePoint'),
      ('$uri Direct', 'PointElement'),
      ('$uri Direct', 'RadialPointElement'),
      ('$uri Direct', 'SplinePoint'),
      ('$uri Indirect', 'PointElement'),
      ('$uri Indirect', 'RadialPointElement'),
      ('$uri Indirect', 'SplinePoint'),
    ]);
  });

  test(
    'PointElement is the only implementer of the point interfaces in lib/',
    () async {
      final all = await pointImplementers('lib');
      // The scan reads lib/: it finds each allowed declaration.
      expect({for (final (name, _) in all) name}, containsAll(_allowed));
      final found = [
        for (final (name, interface) in all)
          if (!_allowed.contains(name)) '$name names $interface',
      ];
      expect(
        found,
        isEmpty,
        reason:
            'A second implementer of types.PointElement, RadialPointElement '
            'or SplinePoint slows every curved line (Chart.js ADR 0040, '
            'section 11, and the phase 8 figures of performance.md). Wrap '
            'the points in a PointElement instead.',
      );
    },
    // The resolution of each file of lib/ takes 25 to 30 s alone on an
    // M3 Max, and more beside the other test files of `melos run test`.
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('SimpleArc does not implement types.LineElement', () {
    final Object arc = SimpleArc(x: 0, y: 0, radius: 0);
    expect(arc, isNot(isA<types.LineElement>()));
  });
}
