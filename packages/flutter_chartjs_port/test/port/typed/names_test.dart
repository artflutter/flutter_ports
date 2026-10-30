// Original code, not ported from Chart.js: the name test of the typed API.
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

import '../../../tool/src/js_semantics.dart' show dartSdkPath;

// The name rules of Chart.js ADR 0052, section 8, over the 50 names of the
// typed API (probe J5 of the design panel checked 43 of them; the details
// class ChartAnimationDetails came with the typed animation callbacks, and
// the 6 names of the filler and the element options with the keys of the
// docs examples). The list holds each name of the ADR, also the names that
// a later commit adds.
// The test resolves the libraries with package:analyzer, as
// test/tool/public_api_test.dart does.
//
// 1. No typed name is a name of the `exports` of doc/upstream/manifest.json
//    (tool 4): the runtime exports of `src/index.ts` and
//    `src/helpers/index.ts` and the declarations of `src/types/*.d.ts`. The
//    port declares such names over time, and `chartjs.dart` exports them
//    (Chart.js ADR 0048, section 4): the app library would then report an
//    `ambiguous_export`.
// 2. No typed name is an export name of `package:flutter/widgets.dart`,
//    `material.dart`, `cupertino.dart` or `dart:ui`.
// 3. No typed name is an export name of `lib/chartjs.dart`,
//    `lib/helpers.dart` or of `lib/flutter_chartjs_port.dart` without the
//    exports of `lib/src/typed/typed.dart`.
//
// Each export name of `typed.dart` is a name of the list, and the app
// library exports it. A new typed name thus joins the list and passes the
// rules.

/// The 50 public names of the typed API (Chart.js ADR 0052, section 8).
const List<String> _typedNames = [
  // Config.
  'ChartConfig', 'ChartKind', 'IndexAxis',
  // Datasets.
  'Dataset', 'BarDataset', 'LineDataset', 'ScatterDataset', 'BubbleDataset',
  'PieDataset', 'DoughnutDataset', 'PolarAreaDataset', 'RadarDataset',
  'DataPoint',
  // Axes.
  'ChartAxis', 'CategoryAxis', 'LinearAxis', 'LogarithmicAxis', 'TimeAxis',
  'TimeSeriesAxis', 'RadialLinearAxis', 'AxisTicks', 'AxisGrid', 'AxisTitle',
  // Groups.
  'ChartLegend', 'ChartTitle', 'ChartTooltip', 'ChartFiller',
  'ChartInteraction', 'ChartAnimation',
  // Elements.
  'ChartElements', 'PointElementStyle', 'LineElementStyle', 'BarElementStyle',
  'ArcElementStyle',
  // Values.
  'ChartPosition', 'ChartAlign', 'ChartInteractionMode', 'ChartEasing',
  'ChartPointStyle', 'ChartFill', 'ChartLength',
  // Callbacks and views.
  'ChartEventDetails', 'ChartLegendEventDetails', 'ChartAnimationDetails',
  'AxisTickInfo', 'ChartHit', 'ChartContext', 'ChartTooltipItem',
  'ChartLegendItem', 'ChartScript',
];

/// The Flutter libraries of rule 2.
const List<String> _flutterLibraries = [
  'package:flutter/widgets.dart',
  'package:flutter/material.dart',
  'package:flutter/cupertino.dart',
  'dart:ui',
];

/// The absolute, normalized form of [path] for the analyzer.
String _normalized(String path) {
  final context = PhysicalResourceProvider.INSTANCE.pathContext;
  return context.normalize(context.absolute(path));
}

late AnalysisContextCollection _collection;
late AnalysisSession _session;

/// The export names of the library of the package at [path], without the
/// names of setters.
Future<Set<String>> _exportsOf(String path) async {
  final result = await _session.getResolvedLibrary(_normalized(path));
  if (result is! ResolvedLibraryResult) {
    throw StateError('$path: the analyzer gives $result');
  }
  return _names(result.element);
}

/// The export names of the library of [uri].
Future<Set<String>> _exportsOfUri(String uri) async {
  final result = await _session.getLibraryByUri(uri);
  if (result is! LibraryElementResult) {
    throw StateError('$uri: the analyzer gives $result');
  }
  return _names(result.element);
}

/// The export names of [library], without the names of setters.
Set<String> _names(LibraryElement library) => {
  for (final name in library.exportNamespace.definedNames2.keys)
    if (!name.endsWith('=')) name,
};

void main() {
  setUpAll(() {
    _collection = AnalysisContextCollection(
      includedPaths: [_normalized('lib')],
      sdkPath: dartSdkPath(),
    );
    _session = _collection
        .contextFor(_normalized('lib/flutter_chartjs_port.dart'))
        .currentSession;
  });

  tearDownAll(() => _collection.dispose());

  test('the list has 50 distinct names', () {
    expect(_typedNames.toSet(), hasLength(50));
  });

  test(
    'the app library exports each name of typed.dart, all from the list',
    () async {
      final typed = await _exportsOf('lib/src/typed/typed.dart');
      expect(typed.difference(_typedNames.toSet()), isEmpty);
      final app = await _exportsOf('lib/flutter_chartjs_port.dart');
      expect(typed.difference(app), isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('rule 1: no typed name is an upstream export or type name', () {
    final manifest = jsonDecode(
      File('doc/upstream/manifest.json').readAsStringSync(),
    ) as Map<String, Object?>;
    final exports = manifest['exports']! as Map<String, Object?>;
    final upstream = {
      for (final key in ['index', 'helpers', 'types'])
        for (final name
            in (exports[key]! as Map<String, Object?>)['names']!
                as List<Object?>)
          name! as String,
    };
    expect(upstream, contains('ChartType'));
    expect(upstream, contains('TooltipItem'));
    expect(_typedNames.where(upstream.contains), isEmpty);
  });

  test(
    'rule 2: no typed name is a Flutter name',
    () async {
      for (final uri in _flutterLibraries) {
        final flutter = await _exportsOfUri(uri);
        expect(_typedNames.where(flutter.contains), isEmpty, reason: uri);
      }
      // The control of the rule: `Easing` is a name of material.dart.
      expect(
        await _exportsOfUri('package:flutter/material.dart'),
        contains('Easing'),
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'rule 3: no typed name is another name of the port libraries',
    () async {
      final typed = await _exportsOf('lib/src/typed/typed.dart');
      final port = {
        ...await _exportsOf('lib/chartjs.dart'),
        ...await _exportsOf('lib/helpers.dart'),
        ...(await _exportsOf('lib/flutter_chartjs_port.dart')).difference(
          typed,
        ),
      };
      expect(_typedNames.where(port.contains), isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
