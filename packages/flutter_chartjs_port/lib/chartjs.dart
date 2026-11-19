// Original code, not ported from Chart.js: the chart.js entry of the package.
/// The `chart.js` entry: each file of `lib/src/`, with no `hide`. It exports
/// the core library `package:flutter_chartjs_port/chartjs_core.dart` and the
/// files that use the Flutter framework.
///
/// A file with no import of `package:flutter/widgets.dart` imports this
/// library. Next to Flutter, an app imports
/// `package:flutter_chartjs_port/flutter_chartjs_port.dart`: it exports this
/// library without `Animation`, `Element`, `FilterCallback`, `Title` and
/// `Tooltip`, the names that Flutter also has.
///
/// Register the components before the first chart:
/// `Chart.register(registerables)`, or a List of the class values and the
/// plugins that the app needs (Chart.js ADR 0048, section 3).
library;

export 'package:flutter_chartjs_port/chartjs_core.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_colors.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_font_tracking.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_line_fan.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_ui_batch.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_ui_paint.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_ui_path.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_ui_shadow.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_ui_text.dart';
export 'package:flutter_chartjs_port/src/controllers/controller.bar.dart';
export 'package:flutter_chartjs_port/src/controllers/controller.bubble.dart';
export 'package:flutter_chartjs_port/src/controllers/controller.doughnut.dart';
export 'package:flutter_chartjs_port/src/controllers/controller.line.dart';
export 'package:flutter_chartjs_port/src/controllers/controller.pie.dart';
export 'package:flutter_chartjs_port/src/controllers/controller.polarArea.dart';
export 'package:flutter_chartjs_port/src/controllers/controller.radar.dart';
export 'package:flutter_chartjs_port/src/controllers/controller.scatter.dart';
export 'package:flutter_chartjs_port/src/controllers/index.dart';
export 'package:flutter_chartjs_port/src/core/animation_share.dart';
export 'package:flutter_chartjs_port/src/core/arc_option_preparation.dart';
export 'package:flutter_chartjs_port/src/core/bar_fast_loop.dart';
export 'package:flutter_chartjs_port/src/core/bar_skip_null.dart';
export 'package:flutter_chartjs_port/src/core/core.animations.dart';
export 'package:flutter_chartjs_port/src/core/core.animator.dart';
export 'package:flutter_chartjs_port/src/core/core.controller.dart';
export 'package:flutter_chartjs_port/src/core/core.datasetController.dart';
export 'package:flutter_chartjs_port/src/core/core.plugins.dart';
export 'package:flutter_chartjs_port/src/core/core.registry.dart';
export 'package:flutter_chartjs_port/src/core/core.scale.autoskip.dart';
export 'package:flutter_chartjs_port/src/core/core.scale.dart';
export 'package:flutter_chartjs_port/src/core/index.dart';
export 'package:flutter_chartjs_port/src/core/legend_item_options.dart';
export 'package:flutter_chartjs_port/src/core/point_bulk_update.dart';
export 'package:flutter_chartjs_port/src/core/point_option_preparation.dart';
export 'package:flutter_chartjs_port/src/core/primitive_parse.dart';
export 'package:flutter_chartjs_port/src/core/radial_positions.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.extras.dart';
export 'package:flutter_chartjs_port/src/helpers/index.dart';
export 'package:flutter_chartjs_port/src/index.dart';
export 'package:flutter_chartjs_port/src/platform/chart_host.dart';
export 'package:flutter_chartjs_port/src/platform/index.dart';
export 'package:flutter_chartjs_port/src/platform/platform.flutter.dart';
export 'package:flutter_chartjs_port/src/plugins/index.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.colors.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.subtitle.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.title.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.tooltip.dart';
export 'package:flutter_chartjs_port/src/scales/index.dart';
export 'package:flutter_chartjs_port/src/scales/scale.category.dart';
export 'package:flutter_chartjs_port/src/scales/scale.linear.dart';
export 'package:flutter_chartjs_port/src/scales/scale.linearbase.dart';
export 'package:flutter_chartjs_port/src/scales/scale.logarithmic.dart';
export 'package:flutter_chartjs_port/src/scales/scale.radialLinear.dart';
export 'package:flutter_chartjs_port/src/scales/scale.time.dart';
export 'package:flutter_chartjs_port/src/scales/scale.timeseries.dart';
export 'package:flutter_chartjs_port/src/theme/chart_theme.dart';
export 'package:flutter_chartjs_port/src/theme/theme_data.dart';
export 'package:flutter_chartjs_port/src/typed/axes.dart';
export 'package:flutter_chartjs_port/src/typed/callbacks.dart';
export 'package:flutter_chartjs_port/src/typed/chart_value.dart';
export 'package:flutter_chartjs_port/src/typed/config.dart';
export 'package:flutter_chartjs_port/src/typed/datasets.dart';
export 'package:flutter_chartjs_port/src/typed/elements.dart';
export 'package:flutter_chartjs_port/src/typed/groups.dart';
export 'package:flutter_chartjs_port/src/typed/lower.dart';
export 'package:flutter_chartjs_port/src/typed/props.dart';
export 'package:flutter_chartjs_port/src/typed/typed.dart';
export 'package:flutter_chartjs_port/src/types.dart';
export 'package:flutter_chartjs_port/src/upstream.dart';
export 'package:flutter_chartjs_port/src/widgets/chart_keyboard.dart';
export 'package:flutter_chartjs_port/src/widgets/chart_theme_switch.dart';
export 'package:flutter_chartjs_port/src/widgets/chart_view.dart';
export 'package:flutter_chartjs_port/src/widgets/chart_view_plugin.dart';
