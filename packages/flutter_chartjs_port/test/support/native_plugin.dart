// Original code, not ported from Chart.js: the plugin of a reference Map.

/// The native [Plugin] of a plugin object of the reference data (Chart.js
/// ADR 0144).
///
/// The Node.js generators write an inline plugin as a Map with an `id` and
/// a function for each hook, for example `{'id': 'log', 'beforeEvent':
/// 'fn:logEvent'}`. The test replaces each `'fn:name'` with its Dart
/// function and gives the Map to [nativePlugin], which makes the native
/// plugin with the same hooks. A hook calls its function with the JS arity
/// of `(chart, args, options)`, as upstream calls `plugin[hook]`. A
/// cancelable hook cancels when the function returns `false`.
library;

import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/types/plugin.dart';

/// The native plugin of the reference plugin Map [map]: its `id` and a hook
/// for each function of a hook key. Another key throws an [ArgumentError].
///
/// ```dart
/// final plugin = nativePlugin({'id': 'log', 'beforeEvent': logEvent});
/// ```
Plugin<Object?> nativePlugin(Map<String, Object?> map) {
  for (final key in map.keys) {
    if (key != 'id' && !PluginHook.values.any((h) => h.jsName == key)) {
      throw ArgumentError.value(key, 'map', 'is not a plugin key');
    }
  }
  return Plugin<Object?>(
    id: map['id']! as String,
    install: _void(map['install']),
    start: _void(map['start']),
    stop: _void(map['stop']),
    beforeInit: _void(map['beforeInit']),
    afterInit: _void(map['afterInit']),
    beforeUpdate: _cancel(map['beforeUpdate']),
    afterUpdate: _void(map['afterUpdate']),
    beforeElementsUpdate: _void(map['beforeElementsUpdate']),
    reset: _void(map['reset']),
    beforeDatasetsUpdate: _cancel(map['beforeDatasetsUpdate']),
    afterDatasetsUpdate: _void(map['afterDatasetsUpdate']),
    beforeDatasetUpdate: _cancel(map['beforeDatasetUpdate']),
    afterDatasetUpdate: _void(map['afterDatasetUpdate']),
    beforeLayout: _cancel(map['beforeLayout']),
    beforeDataLimits: _void(map['beforeDataLimits']),
    afterDataLimits: _void(map['afterDataLimits']),
    beforeBuildTicks: _void(map['beforeBuildTicks']),
    afterBuildTicks: _void(map['afterBuildTicks']),
    afterLayout: _void(map['afterLayout']),
    beforeRender: _cancel(map['beforeRender']),
    afterRender: _void(map['afterRender']),
    beforeDraw: _cancel(map['beforeDraw']),
    afterDraw: _void(map['afterDraw']),
    beforeDatasetsDraw: _cancel(map['beforeDatasetsDraw']),
    afterDatasetsDraw: _void(map['afterDatasetsDraw']),
    beforeDatasetDraw: _cancel(map['beforeDatasetDraw']),
    afterDatasetDraw: _void(map['afterDatasetDraw']),
    beforeEvent: _cancel(map['beforeEvent']),
    afterEvent: _void(map['afterEvent']),
    resize: _void(map['resize']),
    beforeDestroy: _void(map['beforeDestroy']),
    afterDestroy: _void(map['afterDestroy']),
    uninstall: _void(map['uninstall']),
    beforeTooltipDraw: _cancel(map['beforeTooltipDraw']),
    afterTooltipDraw: _void(map['afterTooltipDraw']),
  );
}

/// The hook that cannot cancel of the function [function], or Dart `null`.
PluginHookFunction<A, Object?>? _void<A extends Object>(Object? function) =>
    function == null
    ? null
    : (chart, args, options) {
        jsCall(function, [chart, args, options]);
      };

/// The cancelable hook of the function [function], or Dart `null`: the
/// result `false` of the function cancels.
CancelableHookFunction<A, Object?>? _cancel<A extends Object>(
  Object? function,
) => function == null
    ? null
    : (chart, args, options) =>
          !identical(jsCall(function, [chart, args, options]), false);
