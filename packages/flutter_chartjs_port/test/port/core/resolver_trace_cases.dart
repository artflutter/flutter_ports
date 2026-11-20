// Original code, not ported from Chart.js: the functions of the resolver trace.
@TestOn('vm')
library;

import 'dart:ui' as native_ui;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:test/test.dart' show TestOn, addTearDown;

import '../../support/context_keys.dart';

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
      if (a is Map<String, Object?> || a is JsObjectFace || a is ContextObject)
        'ctx': <String, Object?>{
          for (final key in const [
            'type',
            'index',
            'dataIndex',
            'datasetIndex',
            'mode',
            'active',
          ])
            key: contextRead(a, key),
        }
      else
        'arg0': a,
      'arg1': traceArgKind(b),
    };

/// `defaults.elements.point`.
JsObjectFace tracePointDefaults() =>
    jsGet(jsGet(defaults, 'elements'), 'point')! as JsObjectFace;

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
  // A descriptor takes the name only (Chart.js ADR 0173). The trace records
  // `undefined` for the second argument, as the JS call gives none.
  bool Function(String) descriptor(String name, bool Function(String) body) =>
      (key) {
        trace.add(traceEntry(name, key, undefined));
        return body(key);
      };
  double index(Object? ctx) => jsToNumber(contextRead(ctx, 'dataIndex'));
  return {
    'dsColor': fn(
      'dsColor',
      (ctx, _) => index(ctx) % 2 == 0
          ? const native_ui.Color.fromRGBO(255, 0, 0, 1)
          : const native_ui.Color.fromRGBO(0, 0, 255, 1),
    ),
    'lineBorderColor': fn(
      'lineBorderColor',
      (_, _) => const native_ui.Color.fromRGBO(0, 128, 0, 1),
    ),
    'elementHitRadius': fn('elementHitRadius', (ctx, _) => index(ctx) + 1),
    'optionRotation': fn('optionRotation', (_, _) => 15.0),
    'defBorderWidth': fn('defBorderWidth', (_, _) => 2.0),
    'hoverColor': fn(
      'hoverColor',
      (_, options) => jsToNumber(jsGet(options, 'radius')) > 5
          ? const native_ui.Color.fromRGBO(0, 0, 0, 1)
          : const native_ui.Color.fromRGBO(255, 255, 255, 1),
    ),
    'barRadius': fn('barRadius', (ctx, _) => contextRead(ctx, 'dataIndex')),
    'arcRadius': fn('arcRadius', (ctx, _) => index(ctx) + 1),
    'listItem': fn('listItem', (_, _) => 3.0),
    'fallbackFn': fn('fallbackFn', (_, _) => 'radiusFallback'),
    'userScriptable': descriptor('userScriptable', (name) => name != 'radius'),
    'userIndexable': descriptor('userIndexable', (name) => name != 'hitRadius'),
    'radiusFn': fn('radiusFn', (_, _) => 5.0),
    'selfRadius': fn('selfRadius', (_, options) => jsGet(options, 'radius')),
    'writeParsed': fn('writeParsed', (ctx, _) {
      (ctx! as ScriptableContext).parsed = <String, Object?>{
        'x': jsGet(contextRead(ctx, 'parsed'), 'x'),
        'y': 99.0,
      };
      return 1.0;
    }),
    'readParsed': fn(
      'readParsed',
      (ctx, _) => jsGet(contextRead(ctx, 'parsed'), 'y') == 99.0 ? 7.0 : 3.0,
    ),
    'writeRadius': fn('writeRadius', (ctx, options) {
      if (contextRead(ctx, 'dataIndex') == 2.0) {
        (options! as JsObjectFace)['radius'] = 9.0;
      }
      return 1.0;
    }),
    'addDefaultKey': fn('addDefaultKey', (ctx, _) {
      if (contextRead(ctx, 'dataIndex') == 1.0) {
        tracePointDefaults()['extraKey'] = 5.0;
      }
      return 'red';
    }),
    'namedRadius': fn('namedRadius', (_, _) => 4.0),
    'animDelay': fn(
      'animDelay',
      (ctx, _) => contextRead(ctx, 'type') == 'data' ? index(ctx) * 10 : 0.0,
    ),
    'animDuration': fn(
      'animDuration',
      (ctx, _) =>
          contextRead(ctx, 'type') == 'data' ? 500 + 100 * index(ctx) : 700.0,
    ),
    'numbersDuration': fn('numbersDuration', (_, _) => 400.0),
    'animationFallback': fn('animationFallback', (_, _) => false),
    'deleteEasing': fn('deleteEasing', (ctx, _) {
      if (contextRead(ctx, 'dataIndex') == 1.0) {
        (jsGet(defaults, 'animation')! as JsObjectFace).jsDelete('easing');
      }
      return 'red';
    }),
    'writeOtherDataset': fn('writeOtherDataset', (ctx, _) {
      if (contextRead(ctx, 'dataIndex') == 0.0) {
        final chart = contextRead(ctx, 'chart')! as Chart;
        final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
        (datasets[1]! as AnyObject)['pointRadius'] = 8.0;
      }
      return 'red';
    }),
    'gridWidth': fn(
      'gridWidth',
      (ctx, _) => jsToNumber(contextRead(ctx, 'index')) % 2 == 0 ? 2.0 : 1.0,
    ),
    'legendColor': fn(
      'legendColor',
      (_, _) => const native_ui.Color.fromRGBO(0, 255, 0, 1),
    ),
    'writeRadiusActive': fn('writeRadiusActive', (ctx, options) {
      if (jsTruthy(contextRead(ctx, 'active')) &&
          contextRead(ctx, 'dataIndex') == 2.0) {
        (options! as JsObjectFace)['radius'] = 9.0;
      }
      return 2.0;
    }),
    // A plugin hook: it records no call, as the generator.
    'writeColors': (Object? chart, Object? args, Object? options) {
      final datasets =
          jsGet((chart! as Chart).data, 'datasets')! as List<Object?>;
      (datasets[0]! as AnyObject)
        ..['backgroundColor'] = const ChartPaint.solid(
          native_ui.Color.fromRGBO(0, 128, 0, 1),
        )
        ..['borderColor'] = const ChartPaint.solid(
          native_ui.Color.fromRGBO(0, 0, 255, 1),
        );
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
  'fallbackTrue': (f) =>
      defaults.describe('elements.bar', <String, Object?>{'_fallback': true}),
  'fallbackFunction': (f) => defaults.describe(
    'elements.bar',
    <String, Object?>{'_fallback': f['fallbackFn']},
  ),
  'userDescriptors': (f) =>
      defaults.describe('elements.point', <String, Object?>{
        '_scriptable': f['userScriptable'],
        '_indexable': f['userIndexable'],
      }),
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
            as JsObjectFace)['dataElementType'] =
        'myBar';
    addTearDown(() => Chart.unregister([myBar]));
  },
};
