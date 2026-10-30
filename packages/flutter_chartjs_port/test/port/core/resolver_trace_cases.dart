// Original code, not ported from Chart.js: the functions of the resolver trace.
@TestOn('vm')
library;

// The user functions and the setups of the cases of
// tool/reference/resolver_trace_reference.mjs (D2 of Chart.js ADR 0053), by
// name. test/port/core/resolver_trace_test.dart (D2) and the observation
// oracle O1 (test/port/options/observation_test.dart) use them. Each
// function has the body of the function of the same name in the generator.
//
// This library is not a test file: `flutter test` runs only the files that
// end in `_test.dart`.

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.defaults.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/elements/element.bar.dart';
import 'package:flutter_chartjs_port/src/js/js_array.dart' show JsProxyObject;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/scales/scale.linear.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:test/test.dart' show TestOn, addTearDown;

/// The kind of the second argument of a user function: `'absent'` for the
/// [undefined] sentinel (an argument that the caller does not give),
/// `'resolver'` for a resolver proxy, else `'value'`.
String traceArgKind(Object? b) => identical(b, undefined)
    ? 'absent'
    : b is JsProxyObject
    ? 'resolver'
    : 'value';

/// The trace entry of a call of the user function [name] with [a] and [b]
/// (`record` of the generator).
Map<String, Object?> traceEntry(String name, Object? a, Object? b) =>
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
      'arg1': traceArgKind(b),
    };

/// `defaults.elements.point`.
AnyObject tracePointDefaults() =>
    jsGet(jsGet(defaults, 'elements'), 'point')! as AnyObject;

/// The user functions of the generator, by name. Each call adds its entry
/// to [trace].
Map<String, Object?> resolverTraceFunctions(List<Object?> trace) {
  Object? Function(Object?, Object?) fn(
    String name,
    Object? Function(Object? a, Object? b) body,
  ) => (a, b) {
    trace.add(traceEntry(name, a, b));
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
      if (jsGet(ctx, 'dataIndex') == 1.0) {
        tracePointDefaults()['extraKey'] = 5.0;
      }
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
    'writeOtherDataset': fn('writeOtherDataset', (ctx, _) {
      if (jsGet(ctx, 'dataIndex') == 0.0) {
        final chart = jsGet(ctx, 'chart')! as Chart;
        final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
        (datasets[1]! as AnyObject)['pointRadius'] = 8.0;
      }
      return 'red';
    }),
    'gridWidth': fn(
      'gridWidth',
      (ctx, _) => jsToNumber(jsGet(ctx, 'index')) % 2 == 0 ? 2.0 : 1.0,
    ),
    'legendColor': fn('legendColor', (_, _) => '#00ff00'),
    'writeRadiusActive': fn('writeRadiusActive', (ctx, options) {
      if (jsTruthy(jsGet(ctx, 'active')) && jsGet(ctx, 'dataIndex') == 2.0) {
        (options! as AnyObject)['radius'] = 9.0;
      }
      return 2.0;
    }),
    // A plugin hook: it records no call, as the generator.
    'writeColors': (Object? chart, Object? args, Object? options) {
      final datasets =
          jsGet((chart! as Chart).data, 'datasets')! as List<Object?>;
      (datasets[0]! as AnyObject)
        ..['backgroundColor'] = 'green'
        ..['borderColor'] = 'blue';
      return undefined;
    },
  };
}

/// The setups of the generator, by name. The defaults restore of the
/// harness is the cleanup.
final Map<String, void Function(Map<String, Object?> functions)>
resolverTraceSetups = {
  'defBorderWidth': (f) =>
      tracePointDefaults()['borderWidth'] = f['defBorderWidth'],
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
  // A user scale class: a subclass of LinearScale with its own id and one
  // more default key. The registry keeps it until the tear-down.
  'userScale': (f) {
    final myScale = JsClass(
      'MyScale',
      superclass: LinearScale.jsClass,
      statics: {
        'id': 'myScale',
        'defaults': <String, Object?>{'myScaleOption': 3.0},
      },
      construct: (newTarget, args) => LinearScale(scaleCfgArg(args)),
    );
    Chart.register([myScale]);
    addTearDown(() => Chart.unregister([myScale]));
  },
  // A user element class as the data element of the bar controller: a
  // subclass of BarElement with its own id.
  'userBar': (f) {
    final myBar = JsClass(
      'MyBar',
      superclass: BarElement.jsClass,
      statics: {
        'id': 'myBar',
        'defaults': <String, Object?>{'borderWidth': 2.0, 'myOption': 7.0},
      },
      construct: (newTarget, args) => BarElement(elementCfgArg(args)),
    );
    Chart.register([myBar]);
    (jsGet(jsGet(defaults, 'datasets'), 'bar')!
            as AnyObject)['dataElementType'] =
        'myBar';
    addTearDown(() => Chart.unregister([myBar]));
  },
};
