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
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/widgets/chart_keyboard.dart';
import 'package:flutter_chartjs_port/src/widgets/chart_theme_switch.dart';

/// The id of the inline plugin of `ChartView`. The id is reserved.
@internal
const String chartViewPluginId = r'$chartView';

/// The internal inline plugin of a `ChartView`: a plugin Map (Chart.js ADR
/// 0038) with the id [chartViewPluginId]. Its `beforeUpdate` and
/// `beforeLayout` record the palette keys of [theme] (Chart.js ADR 0050,
/// "Runtime switch", step 4), and its `afterDraw` draws the focus ring of
/// [keys] (Chart.js ADR 0051, section 6). The hooks take the upstream
/// parameter counts.
@internal
AnyObject createChartViewPlugin(ChartThemeSwitch theme, ChartKeyboard keys) =>
    <String, Object?>{
      'id': chartViewPluginId,

      /// core.controller.js:490 `notifyPlugins('beforeUpdate', ...)`.
      'beforeUpdate': (types.Chart chart, AnyObject args, AnyObject options) {
        theme.beforeUpdate(chart);
      },

      /// core.controller.js:612 `notifyPlugins('beforeLayout', ...)`.
      'beforeLayout': (types.Chart chart, AnyObject args, AnyObject options) {
        theme.afterColorize(chart);
      },

      /// core.controller.js:731 `notifyPlugins('afterDraw')`.
      'afterDraw': (types.Chart chart, AnyObject args, AnyObject options) {
        keys.paintRing(chart);
      },
    };
