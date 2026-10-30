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
// trace entries and the steps. The functions of [_functions] and the setups
// of [_setups] have the bodies of the generator. The defaults restore of the
// harness puts back the defaults and the descriptors after each case
// (`setUpDefaultsRestore`).

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
import 'package:flutter_test/flutter_test.dart';

import '../scales/scale_chart_harness.dart'
    show copyReference, referenceMatcher, testReferenceOrigin;
import '../scales/scale_time_harness.dart' show atNow;
import 'resolver_trace_reference.dart';

/// The kind of the second argument of a user function: `'absent'` for the
/// [undefined] sentinel (an argument that the caller does not give),
/// `'resolver'` for a resolver proxy, else `'value'`.
String _kindOf(Object? b) => identical(b, undefined)
    ? 'absent'
    : b is JsProxyObject
    ? 'resolver'
    : 'value';

/// The trace entry of a call of the user function [name] with [a] and [b]
/// (`record` of the generator).
Map<String, Object?> _entry(String name, Object? a, Object? b) =>
    <String, Object?>{
      'fn': name,
      if (a is Map<String, Object?>)
        'ctx': <String, Object?>{
          for (final key in const [
            'type',
            'index',
            'dataIndex',
            'datasetIndex',
            'mode',
            'active',
          ])
            key: jsGet(a, key),
        }
      else
        'arg0': a,
      'arg1': _kindOf(b),
    };

/// `defaults.elements.point`.
AnyObject _point() => jsGet(jsGet(defaults, 'elements'), 'point')! as AnyObject;

/// The user functions of the generator, by name. Each call adds its entry
/// to [trace].
Map<String, Object?> _functions(List<Object?> trace) {
  Object? Function(Object?, Object?) fn(
    String name,
    Object? Function(Object? a, Object? b) body,
  ) => (a, b) {
    trace.add(_entry(name, a, b));
    return body(a, b);
  };
  double index(Object? ctx) => jsToNumber(jsGet(ctx, 'dataIndex'));
  return {
    'dsColor': fn('dsColor', (ctx, _) => index(ctx) % 2 == 0 ? 'red' : 'blue'),
    'lineBorderColor': fn('lineBorderColor', (_, _) => 'green'),
    'elementHitRadius': fn('elementHitRadius', (ctx, _) => index(ctx) + 1),
    'optionRotation': fn('optionRotation', (_, _) => 15.0),
    'defBorderWidth': fn('defBorderWidth', (_, _) => 2.0),
    'hoverColor': fn(
      'hoverColor',
      (_, options) =>
          jsToNumber(jsGet(options, 'radius')) > 5 ? 'black' : 'white',
    ),
    'barRadius': fn('barRadius', (ctx, _) => jsGet(ctx, 'dataIndex')),
    'arcRadius': fn('arcRadius', (ctx, _) => index(ctx) + 1),
    'listItem': fn('listItem', (_, _) => 3.0),
    'fallbackFn': fn('fallbackFn', (_, _) => 'radiusFallback'),
    'userScriptable': fn('userScriptable', (name, _) => name != 'radius'),
    'userIndexable': fn('userIndexable', (name, _) => name != 'hitRadius'),
    'radiusFn': fn('radiusFn', (_, _) => 5.0),
    'selfRadius': fn('selfRadius', (_, options) => jsGet(options, 'radius')),
    'writeParsed': fn('writeParsed', (ctx, _) {
      (ctx! as AnyObject)['parsed'] = <String, Object?>{
        'x': jsGet(jsGet(ctx, 'parsed'), 'x'),
        'y': 99.0,
      };
      return 1.0;
    }),
    'readParsed': fn(
      'readParsed',
      (ctx, _) => jsGet(jsGet(ctx, 'parsed'), 'y') == 99.0 ? 7.0 : 3.0,
    ),
    'writeRadius': fn('writeRadius', (ctx, options) {
      if (jsGet(ctx, 'dataIndex') == 2.0) {
        (options! as AnyObject)['radius'] = 9.0;
      }
      return 1.0;
    }),
    'addDefaultKey': fn('addDefaultKey', (ctx, _) {
      if (jsGet(ctx, 'dataIndex') == 1.0) _point()['extraKey'] = 5.0;
      return 'red';
    }),
    'namedRadius': fn('namedRadius', (_, _) => 4.0),
    'animDelay': fn(
      'animDelay',
      (ctx, _) => jsGet(ctx, 'type') == 'data' ? index(ctx) * 10 : 0.0,
    ),
    'animDuration': fn(
      'animDuration',
      (ctx, _) => jsGet(ctx, 'type') == 'data' ? 500 + 100 * index(ctx) : 700.0,
    ),
    'numbersDuration': fn('numbersDuration', (_, _) => 400.0),
    'animationFallback': fn('animationFallback', (_, _) => false),
    'deleteEasing': fn('deleteEasing', (ctx, _) {
      if (jsGet(ctx, 'dataIndex') == 1.0) {
        (jsGet(defaults, 'animation')! as AnyObject).remove('easing');
      }
      return 'red';
    }),
  };
}

/// The setups of the generator, by name. The defaults restore of the
/// harness is the cleanup.
final Map<String, void Function(Map<String, Object?> functions)> _setups = {
  'defBorderWidth': (f) => _point()['borderWidth'] = f['defBorderWidth'],
  'fallbackString': (f) => defaults.describe('elements.bar', <String, Object?>{
    '_fallback': 'radiusFallback',
  }),
  'fallbackTrue': (f) => defaults.describe('elements.bar', <String, Object?>{
    '_fallback': true,
  }),
  'fallbackFunction': (f) => defaults.describe(
    'elements.bar',
    <String, Object?>{'_fallback': f['fallbackFn']},
  ),
  'userDescriptors': (f) => defaults.describe(
    'elements.point',
    <String, Object?>{
      '_scriptable': f['userScriptable'],
      '_indexable': f['userIndexable'],
    },
  ),
  'extraKey': (f) {},
  'animationFallback': (f) => defaults.describe('animation', <String, Object?>{
    '_fallback': f['animationFallback'],
  }),
  'deleteEasing': (f) {},
};

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
  final Map<String, Object?> map =>
    depth >= 2 ? '<object>' : _nestedOf(map, depth),
  _ => v,
};

/// `nestedOf` of the generator.
Map<String, Object?> _nestedOf(Map<String, Object?> v, int depth) => {
  for (final key in jsObjectKeys(v))
    key: _nestedKeys.contains(key)
        ? _valueOf(jsGet(v, key), depth + 1)
        : '<skipped>',
};

/// `optionsOf` of the generator.
Map<String, Object?>? _optionsOf(Object? o) {
  if (o == null || identical(o, undefined)) return null;
  final map = o as Map<String, Object?>;
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
    default:
      throw ArgumentError.value(step, 'step', 'Not a step');
  }
  return undefined;
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
  final functions = _functions(trace);
  if (c.setup case final setup?) _setups[setup]!(functions);
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
