// Original code, not ported from Chart.js: the inline plugin of ChartView.

/// The internal inline plugin of `ChartView` (Chart.js ADRs 0050 and 0051).
///
/// The widget puts it last in the `plugins` List of its root config, after
/// the inline plugins of the app. Registered plugins come before the inline
/// plugins (core.plugins.js:124-144). Thus its `beforeLayout` runs after the
/// `beforeLayout` of the registered colors plugin, and its `afterDraw` runs
/// after the `afterDraw` of the tooltip (plugin.tooltip.js:1246): the focus
/// ring is on top. The option `plugins.$chartView: false` turns it off
/// (core.plugins.js:146-151, 162-165): a theme switch then restores no
/// palette key, and the chart shows no focus ring.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show undefined;
import 'package:flutter_chartjs_port/src/options/option_scope.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/chart_shadow.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/plugin.dart'
    show DatasetDrawHookArgs;
import 'package:flutter_chartjs_port/src/widgets/chart_keyboard.dart';
import 'package:flutter_chartjs_port/src/widgets/chart_theme_switch.dart';

/// The id of the inline plugin of `ChartView`. The id is reserved.
@internal
const String chartViewPluginId = r'$chartView';

/// The internal inline plugin of a `ChartView`: a plugin Map (Chart.js ADR
/// 0038) with the id [chartViewPluginId]. Its `beforeUpdate` and
/// `beforeLayout` record the palette keys of [theme] (Chart.js ADR 0050,
/// "Runtime switch", step 4), and its `afterDraw` draws the focus ring of
/// [keys] (Chart.js ADR 0051, section 6). Its `beforeDatasetDraw` and
/// `afterDatasetDraw` draw the shadow of a dataset (Chart.js ADR 0107). The
/// hooks take the upstream parameter counts.
@internal
AnyObject createChartViewPlugin(ChartThemeSwitch theme, ChartKeyboard keys) {
  // Whether the last `beforeDatasetDraw` saved the context for a shadow.
  var shadowed = false;
  return <String, Object?>{
    'id': chartViewPluginId,
    'supportsDataUpdates': true,

    /// core.controller.js:490 `notifyPlugins('beforeUpdate', ...)`.
    'beforeUpdate': (types.Chart chart, Object? args, Object? options) {
      theme.beforeUpdate(chart);
    },

    /// core.controller.js:612 `notifyPlugins('beforeLayout', ...)`.
    'beforeLayout': (types.Chart chart, Object? args, Object? options) {
      theme.afterColorize(chart);
    },

    /// core.controller.js:793 `notifyPlugins('beforeDatasetDraw', args)`.
    'beforeDatasetDraw': (types.Chart chart, Object? args, Object? options) {
      shadowed = _beginShadow(chart, args);
    },

    /// core.controller.js:808 `notifyPlugins('afterDatasetDraw', args)`.
    'afterDatasetDraw': (types.Chart chart, Object? args, Object? options) {
      if (!shadowed) return;
      shadowed = false;
      chart.ctx?.restore();
    },

    /// core.controller.js:731 `notifyPlugins('afterDraw')`.
    'afterDraw': (types.Chart chart, Object? args, Object? options) {
      keys.paintRing(chart);
    },
  };
}

/// Sets the shadow of the dataset of [args] on the context of [chart]
/// (Chart.js ADRs 0107 and 0139), and gives whether it saved the context.
///
/// The dataset gives the shadow in its option `shadow`, a [ChartShadow]. The
/// plugin reads the dataset only: the shadow does not cascade from
/// `options.datasets` or from `options`. A dataset with no shadow keeps the
/// context as it is. Another value stops a debug build.
bool _beginShadow(types.Chart chart, Object? args) {
  final ctx = chart.ctx;
  if (ctx == null || args is! DatasetDrawHookArgs) return false;
  final shadow = readOption(
    args.meta?.controller?.getDataset(),
    OptionKey.shadow,
  );
  if (shadow is! ChartShadow) {
    assert(
      shadow == null || identical(shadow, undefined),
      'The option shadow takes a ChartShadow, not $shadow.',
    );
    return false;
  }
  ctx
    ..save()
    ..shadowColor = shadow.color
    ..shadowBlur = shadow.blur
    ..shadowOffsetX = shadow.offset.dx
    ..shadowOffsetY = shadow.offset.dy;
  return true;
}
