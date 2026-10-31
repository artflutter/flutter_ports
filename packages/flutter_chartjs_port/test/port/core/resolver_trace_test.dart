// Original code, not ported from Chart.js: the resolver trace reference test.
@TestOn('vm')
library;

// The D2 reference trace of Chart.js ADR 0053: the charts of
// tool/reference/resolver_trace_reference.mjs on the port, against the data
// of a build of the pinned Chart.js. After each step, the test compares the
// resolved options of each element with their key order, the ordered calls
// of the user functions of the config, the result of the steps that give
// one, and for the animation cases the `$animations` of each element and of
// its options. The header of the generator gives the observations, the
// trace entries and the steps. The functions and the setups of
// resolver_trace_cases.dart have the bodies of the generator. The defaults
// restore of the harness puts back the defaults and the descriptors after
// each case (`setUpDefaultsRestore`).

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.animation.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.easing.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart'
    show ElementPropertyRead;
import 'package:flutter_test/flutter_test.dart';

import '../controllers/controller_chart_harness.dart' show ReferenceEvent;
import '../scales/scale_chart_harness.dart'
    show copyReference, referenceMatcher, testReferenceOrigin;
import '../scales/scale_time_harness.dart' show atNow;
import 'resolver_trace_cases.dart';
import 'resolver_trace_reference.dart';

/// The keys of an object option whose values the observation reads
/// (`NESTED_KEYS` of the generator).
const Set<String> _nestedKeys = {
  'topLeft',
  'topRight',
  'bottomLeft',
  'bottomRight',
  'outerStart',
  'outerEnd',
  'innerStart',
  'innerEnd',
  'a',
};

/// `valueOf` of the generator.
Object? _valueOf(Object? v, int depth) => switch (v) {
  Function() || JsFunction() || JsClass() => '<fn>',
  final List<Object?> list => [
    for (final item in list) _valueOf(item, depth + 1),
  ],
  final Object map when map is Map<String, Object?> || map is JsObjectFace =>
    depth >= 2 ? '<object>' : _nestedOf(map, depth),
  _ => v,
};

/// `nestedOf` of the generator.
Map<String, Object?> _nestedOf(Object v, int depth) => {
  for (final key in jsObjectKeys(v))
    key: _nestedKeys.contains(key)
        ? _valueOf(jsGet(v, key), depth + 1)
        : '<skipped>',
};

/// `optionsOf` of the generator.
Map<String, Object?>? _optionsOf(Object? o) {
  if (o == null || identical(o, undefined)) return null;
  final map = o;
  return {
    for (final key in jsObjectKeys(map))
      key: key == r'$animations'
          ? '<animations>'
          : _valueOf(jsGet(map, key), 1),
  };
}

/// The name of [easing] in `effects` (`easingName` of the generator).
String _easingName(double Function(double t) easing) {
  for (final MapEntry(:key, :value) in effects.entries) {
    if (identical(value, easing)) return key;
  }
  throw StateError('An easing function that is not an effect.');
}

/// `animationsOf` of the generator.
Object? _animationsOf(Object? anims) {
  if (anims == null || identical(anims, undefined)) return 'none';
  final map = anims as Map<String, Object?>;
  return {
    for (final key in jsObjectKeys(map))
      key: switch (map[key]! as Animation) {
        final a => <String, Object?>{
          'from': a.from,
          'to': a.to,
          'duration': a.duration,
          'start': a.start,
          'loop': a.loop,
          'easing': _easingName(a.easing),
        },
      },
  };
}

/// The dataset element and the data elements of the dataset [i].
List<Element> _elementsOf(Chart chart, int i) {
  final meta = chart.getDatasetMeta(i.toDouble());
  return [
    if (meta.dataset case final dataset?) dataset as Element,
    for (final element in meta.data) element as Element,
  ];
}

/// The count of the datasets of [chart].
int _datasetCount(Chart chart) =>
    (jsGet(chart.data, 'datasets')! as List<Object?>).length;

/// `datasetsOf` of the generator.
List<Object?> _datasetsOf(Chart chart) => [
  for (var i = 0; i < _datasetCount(chart); i++)
    switch (chart.getDatasetMeta(i.toDouble())) {
      final meta => <String, Object?>{
        'dataset': switch (meta.dataset) {
          final Element dataset => _optionsOf(dataset.options),
          _ => null,
        },
        'data': [
          for (final element in meta.data)
            _optionsOf((element as Element).options),
        ],
      },
    },
];

/// `animationsOfChart` of the generator.
List<Object?> _animationsOfChart(Chart chart) => [
  for (var i = 0; i < _datasetCount(chart); i++)
    [
      for (final element in _elementsOf(chart, i))
        <String, Object?>{
          'element': _animationsOf(element.$animations),
          'options': _animationsOf(
            element.options == null
                ? undefined
                : jsGet(element.options, r'$animations'),
          ),
        },
    ],
];

/// `applyStep` of the generator: the result of a step that gives one, or
/// [undefined].
Object? _applyStep(Chart chart, List<Object?> step) {
  switch (step) {
    case ['update']:
      chart.update();
    case ['update', final String mode]:
      chart.update(mode);
    case ['setActive', final List<Object?> items]:
      chart
        ..setActiveElements([
          for (final [d, i] in items.cast<List<Object?>>())
            <String, Object?>{'datasetIndex': d, 'index': i},
        ])
        ..update();
    case ['hide', final num d]:
      chart.hide(d.toDouble());
    case ['show', final num d]:
      chart.show(d.toDouble());
    case ['resolveNamed', final List<Object?> names]:
      // config.resolveNamedOptions with the scopes and the context of the
      // data element 0 of dataset 0 (core.datasetController.js:802-834).
      final controller = chart.getDatasetMeta(0).controller!;
      final config = chart.config;
      final scopeKeys = config.datasetElementScopeKeys(
        controller.type,
        'point',
      );
      final scopes = config.getOptionScopes(controller.getDataset(), scopeKeys);
      final result = config.resolveNamedOptions(
        scopes,
        names.cast<String>(),
        () => controller.getContext(0, false, 'default'),
        const ['point', ''],
      );
      return _optionsOf(result);
    case ['readOption', final String key]:
      return _valueOf(jsGet(chart.options, key), 0);
    case ['setOption', final String path, final Object? value]:
      final (object, key) = _parentOf(chart.options, path);
      jsSet(object, key, value);
    case ['setDefault', final String path, final Object? value]:
      // The defaults restore of the harness puts the old value back.
      final (object, key) = _parentOf(defaults, path);
      jsSet(object, key, value);
    case ['deleteDefault', final String path]:
      final (object, key) = _parentOf(defaults, path);
      jsDeleteKey(object, key);
    case ['readScale', final String id, final String path]:
      return _valueOf(_readPath(chart.scales[id]!.options, path), 0);
    case ['readLegend', final String path]:
      return _valueOf(_readPath(chart.legend!.options, path), 0);
    case ['legendItems', final String key]:
      return [
        for (final item in chart.legend!.legendItems!)
          _valueOf(jsGet(item, key), 1),
      ];
    case ['hitNear', final num d, final num i, final num dx, final num dy]:
      final element =
          chart.getDatasetMeta(d.toDouble()).data[i.toInt()]
              as ElementPropertyRead;
      final event = ReferenceEvent(
        jsToNumber(element['x']) + dx,
        jsToNumber(element['y']) + dy,
      );
      return [
        for (final item in chart.getElementsAtEventForMode(
          event,
          'point',
          <String, Object?>{'intersect': true},
          false,
        ))
          [item.datasetIndex, item.index],
      ];
    default:
      throw ArgumentError.value(step, 'step', 'Not a step');
  }
  return undefined;
}

/// The value at the dotted [path] under [root], read key by key with
/// [jsGet] (`readPath` of the generator).
Object? _readPath(Object? root, String path) {
  var value = root;
  for (final key in path.split('.')) {
    value = jsGet(value, key);
  }
  return value;
}

/// The object that holds the last key of the dotted [path] under [root],
/// and that key (`parentOf` of the generator).
(Object?, String) _parentOf(Object? root, String path) {
  final keys = path.split('.');
  final key = keys.removeLast();
  return (keys.isEmpty ? root : _readPath(root, keys.join('.')), key);
}

/// Expects [actual] to equal [expected], with the key order of each Map and
/// the number rules of [referenceMatcher]. [path] names the place in the
/// reason of a failure.
void _expectSame(Object? actual, Object? expected, String path) {
  switch (expected) {
    case final Map<String, Object?> map:
      expect(actual, isA<Map<String, Object?>>(), reason: path);
      final actualMap = actual! as Map<String, Object?>;
      expect(
        actualMap.keys.toList(),
        map.keys.toList(),
        reason: '$path: the keys in order',
      );
      for (final MapEntry(:key, :value) in map.entries) {
        _expectSame(actualMap[key], value, '$path.$key');
      }
    case final List<Object?> list:
      expect(actual, isA<List<Object?>>(), reason: path);
      final actualList = actual! as List<Object?>;
      expect(actualList.length, list.length, reason: '$path: the length');
      for (var i = 0; i < list.length; i++) {
        _expectSame(actualList[i], list[i], '$path[$i]');
      }
    default:
      expect(actual, referenceMatcher(expected), reason: path);
  }
}

/// The matcher of the throw `{name, message}` of a case. A JS `TypeError`
/// is a Dart [TypeError]. The `Error` of `Recursion detected` is a
/// [StateError] with the same message (helpers.config.ts:263-265).
Matcher _throwsError(Map<String, Object?> error) => switch (error['name']) {
  'TypeError' => throwsA(isA<TypeError>()),
  'Error' => throwsA(
    isA<StateError>().having((e) => e.message, 'message', error['message']),
  ),
  final name => throw ArgumentError.value(name, 'name', 'No Dart type'),
};

/// Runs the case [c]: the setup, `acquireChart` (the step `['init']`), then
/// each step, and compares each step with its expected entry.
void _runCase(ResolverTraceReferenceCase c) {
  final trace = <Object?>[];
  final functions = resolverTraceFunctions(trace);
  if (c.setup case final setup?) resolverTraceSetups[setup]!(functions);
  final expected = c.expected;
  final steps = expected['steps']! as List<Object?>;
  final error = expected['error'] as Map<String, Object?>?;
  Chart? chart;
  for (var k = 0; k < steps.length; k++) {
    final entry = steps[k]! as Map<String, Object?>;
    final step = entry['do']! as List<Object?>;
    final label = 'step $k $step';
    trace.clear();
    Object? run() => k == 0
        ? chart = acquireChart(
            copyReference(c.config, functions)! as AnyObject,
          )
        : _applyStep(chart!, step);
    if (error != null && (error['at']! as num).toInt() == k) {
      expect(run, _throwsError(error), reason: label);
      _expectSame(List.of(trace), entry['trace'], '$label: trace');
      return;
    }
    final result = run();
    _expectSame(List.of(trace), entry['trace'], '$label: trace');
    trace.clear();
    if (entry.containsKey('result')) {
      _expectSame(result, entry['result'], '$label: result');
    }
    final current = chart!;
    _expectSame(_datasetsOf(current), entry['datasets'], '$label: datasets');
    if (entry.containsKey('animations')) {
      _expectSame(
        _animationsOfChart(current),
        entry['animations'],
        '$label: animations',
      );
    }
    _expectSame(List.of(trace), entry['observeTrace'], '$label: observeTrace');
  }
  expect(error, isNull, reason: 'the case has an error after its last step');
}

void main() {
  testReferenceOrigin(
    node: resolverTraceReferenceNode,
    arch: resolverTraceReferenceArch,
    dist: resolverTraceReferenceDist,
    commit: resolverTraceReferenceCommit,
  );

  for (final c in resolverTraceReference) {
    testWidgets(c.name, (tester) async {
      atNow(resolverTraceReferenceNow, () => _runCase(c));
    });
  }
}
