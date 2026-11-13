// Original code, not ported from Chart.js: the public library of the package.
/// Chart.js for Flutter: the widget `ChartView`, the theme API, the typed API
/// and the chart API. Register the components first:
/// `Chart.register(registerables)`.
///
/// A native Dart port of [Chart.js](https://www.chartjs.org) (Chart.js ADR
/// 0048, section 5). A file of an app imports this library next to
/// `package:flutter/widgets.dart` or `material.dart` with no prefix: it
/// exports `package:flutter_chartjs_port/chartjs.dart` without `Animation`
/// and `Element`, the two names that Flutter also has. Code that extends
/// Chart.js imports `chartjs.dart` and `helpers.dart` with a prefix.
///
/// The typed API (Chart.js ADR 0052) gives typed values, callback details
/// with `int` indexes and views of the chart objects. The library exports
/// it next to the Chart.js names: its names take none of them.
///
/// Register the components before the first chart, as the ESM entry of
/// Chart.js asks: `Chart.register(registerables)`, or a List of the class
/// values and plugin Maps of the chart types of the app. The palette of a
/// theme needs the `colors` plugin.
///
/// The roadmap and the parity tracker are in the `doc/` folder of the
/// repository:
/// https://github.com/artflutter/flutter_ports/tree/main/packages/flutter_chartjs_port/doc
library;

export 'package:flutter_chartjs_port/chartjs.dart' hide Animation, Element;
export 'package:flutter_chartjs_port/src/canvas/canvas.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_arc_sector.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_circle_run.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_colors.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_dense_curve.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_font_tracking.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_line_fan.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_partitioned_fill.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_rect_bar.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_ui_batch.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_ui_paint.dart';
export 'package:flutter_chartjs_port/src/canvas/canvas_ui_path.dart';
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
export 'package:flutter_chartjs_port/src/core/animation_spec.dart';
export 'package:flutter_chartjs_port/src/core/arc_option_preparation.dart'
    hide prepareNativeArcColors;
export 'package:flutter_chartjs_port/src/core/arc_options.dart'
    hide nativeArcClass, nativeArcElement, nativeArcScale;
export 'package:flutter_chartjs_port/src/core/bar_bulk_update.dart';
export 'package:flutter_chartjs_port/src/core/bar_index_layout.dart';
export 'package:flutter_chartjs_port/src/core/bar_sorted_values.dart';
export 'package:flutter_chartjs_port/src/core/category_label_source.dart';
export 'package:flutter_chartjs_port/src/core/chart_axis_reads.dart';
export 'package:flutter_chartjs_port/src/core/core.adapters.dart';
export 'package:flutter_chartjs_port/src/core/core.animation.dart'
    hide Animation, animationHasDuration, readProperty, writeProperty;
export 'package:flutter_chartjs_port/src/core/core.animations.dart'
    hide animatedPropOf;
export 'package:flutter_chartjs_port/src/core/core.animations.defaults.dart';
export 'package:flutter_chartjs_port/src/core/core.animator.dart'
    hide AnimationEvent, Anims;
export 'package:flutter_chartjs_port/src/core/core.config.dart';
export 'package:flutter_chartjs_port/src/core/core.controller.dart';
export 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    hide
        axisStackOf,
        dataItemValue,
        metaStringOf,
        parsedValueOf,
        presizeParsedNumbers,
        setPointAxis,
        setStackValue,
        stacksOf,
        visualValuesOf;
export 'package:flutter_chartjs_port/src/core/core.defaults.dart'
    hide Defaults, descriptors;
export 'package:flutter_chartjs_port/src/core/core.element.dart' hide Element;
export 'package:flutter_chartjs_port/src/core/core.interaction.dart';
export 'package:flutter_chartjs_port/src/core/core.layouts.dart';
export 'package:flutter_chartjs_port/src/core/core.layouts.defaults.dart';
export 'package:flutter_chartjs_port/src/core/core.plugins.dart'
    hide FilterCallback;
export 'package:flutter_chartjs_port/src/core/core.registry.dart';
export 'package:flutter_chartjs_port/src/core/core.scale.autoskip.dart';
export 'package:flutter_chartjs_port/src/core/core.scale.dart'
    hide tickCallbackOf;
export 'package:flutter_chartjs_port/src/core/core.scale.defaults.dart';
export 'package:flutter_chartjs_port/src/core/core.ticks.dart';
export 'package:flutter_chartjs_port/src/core/core.typedRegistry.dart';
export 'package:flutter_chartjs_port/src/core/data_update.dart'
    hide
        DataUpdateShape,
        DataUpdateSnapshot,
        RangeUpdateSnapshot,
        dataUpdateField,
        dataUpdateValues,
        nativeDataUpdateList,
        nativeDataUpdateObject,
        nativeDataUpdatePoint,
        nativeDataUpdateRoot,
        nativeOptionScope,
        registerDataUpdateTypes,
        staticDataUpdateOptions;
export 'package:flutter_chartjs_port/src/core/date_adapter.dart';
export 'package:flutter_chartjs_port/src/core/date_calendar.dart';
export 'package:flutter_chartjs_port/src/core/date_format.dart';
export 'package:flutter_chartjs_port/src/core/date_parse.dart';
export 'package:flutter_chartjs_port/src/core/date_zone.dart';
export 'package:flutter_chartjs_port/src/core/index.dart'
    hide Animation, Element;
export 'package:flutter_chartjs_port/src/core/legend_item_options.dart';
export 'package:flutter_chartjs_port/src/core/point_option_preparation.dart'
    hide
        cachedNativePointSizeFields,
        prepareNativeGapReads,
        prepareNativePointColors,
        prepareNativePointContexts,
        prepareNativePointResolution;
export 'package:flutter_chartjs_port/src/core/point_options.dart'
    hide
        NativeGapReads,
        NativePointContextReader,
        NativePointCoordinateCache,
        NativePointResolution,
        NativePointSizeFields,
        NativeTypedItems,
        canPrepareNativePointUpdate,
        nativePointChart,
        nativePointClass,
        nativePointDatasetIndex,
        nativePointElement,
        nativePointProjection,
        nativePointSize;
export 'package:flutter_chartjs_port/src/core/primitive_parse.dart';
export 'package:flutter_chartjs_port/src/core/radial_positions.dart'
    hide RadialPositions, plainOptionValue;
export 'package:flutter_chartjs_port/src/core/reduced_motion.dart';
export 'package:flutter_chartjs_port/src/core/scale_option_enums.dart';
export 'package:flutter_chartjs_port/src/core/scale_options.dart';
export 'package:flutter_chartjs_port/src/core/tick_font_cache.dart';
export 'package:flutter_chartjs_port/src/elements/element.arc.dart';
export 'package:flutter_chartjs_port/src/elements/element.bar.dart';
export 'package:flutter_chartjs_port/src/elements/element.line.dart'
    hide denseCurveScaleOfLine;
export 'package:flutter_chartjs_port/src/elements/element.point.dart';
export 'package:flutter_chartjs_port/src/elements/element_options.dart'
    hide numberOption, plainOption, rawOption;
export 'package:flutter_chartjs_port/src/elements/index.dart';
export 'package:flutter_chartjs_port/src/elements/line_dense_curve.dart';
export 'package:flutter_chartjs_port/src/helpers/cubic_interpolation_mode.dart';
export 'package:flutter_chartjs_port/src/helpers/grace_length.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.color.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    hide IndexedElementStyles, descriptors, parseObjectDataRadialScaleOf;
export 'package:flutter_chartjs_port/src/helpers/helpers.config.types.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    hide mergeNativeOptionValues, nativeMergeKind;
export 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.dataset.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.dom.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.easing.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.extras.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.interpolation.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.intl.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.math.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.options.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.rtl.dart';
export 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart'
    hide createBoundarySegment, nativeSegmentType;
export 'package:flutter_chartjs_port/src/helpers/index.dart'
    hide
        IndexedElementStyles,
        createBoundarySegment,
        easingEffects,
        mergeNativeOptionValues,
        nativeMergeKind,
        nativeSegmentType,
        parseObjectDataRadialScaleOf;
export 'package:flutter_chartjs_port/src/helpers/point_style.dart';
export 'package:flutter_chartjs_port/src/helpers/radius_length.dart';
export 'package:flutter_chartjs_port/src/index.dart' hide Animation, Element;
export 'package:flutter_chartjs_port/src/js/js_array.dart';
export 'package:flutter_chartjs_port/src/js/js_class.dart';
export 'package:flutter_chartjs_port/src/js/js_function.dart';
export 'package:flutter_chartjs_port/src/js/js_map.dart';
export 'package:flutter_chartjs_port/src/js/js_math.dart';
export 'package:flutter_chartjs_port/src/js/js_number.dart';
export 'package:flutter_chartjs_port/src/js/js_object.dart';
export 'package:flutter_chartjs_port/src/js/js_promise.dart';
export 'package:flutter_chartjs_port/src/js/js_undefined.dart';
export 'package:flutter_chartjs_port/src/js/js_webidl.dart';
export 'package:flutter_chartjs_port/src/kurkle_color/byte.dart';
export 'package:flutter_chartjs_port/src/kurkle_color/color.dart' hide Color;
export 'package:flutter_chartjs_port/src/kurkle_color/hex.dart';
export 'package:flutter_chartjs_port/src/kurkle_color/hue.dart';
export 'package:flutter_chartjs_port/src/kurkle_color/index.esm.dart'
    hide Color, color;
export 'package:flutter_chartjs_port/src/kurkle_color/names.dart';
export 'package:flutter_chartjs_port/src/kurkle_color/packed.dart';
export 'package:flutter_chartjs_port/src/kurkle_color/rgb.dart';
export 'package:flutter_chartjs_port/src/kurkle_color/simple_parse.dart';
export 'package:flutter_chartjs_port/src/kurkle_color/srgb.dart';
export 'package:flutter_chartjs_port/src/options/animated_prop.dart';
export 'package:flutter_chartjs_port/src/options/element_options_base.dart';
export 'package:flutter_chartjs_port/src/options/foreign_audit.dart'
    hide auditForeign, foreignAudit;
export 'package:flutter_chartjs_port/src/options/opt.dart';
export 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
export 'package:flutter_chartjs_port/src/options/option_scope.dart';
export 'package:flutter_chartjs_port/src/options/parsed.dart';
export 'package:flutter_chartjs_port/src/options/property_animation.dart'
    hide transitionIn, transitionModeOf;
export 'package:flutter_chartjs_port/src/options/props.dart';
export 'package:flutter_chartjs_port/src/options/raw_scope.dart';
export 'package:flutter_chartjs_port/src/options/resolved.g.dart';
export 'package:flutter_chartjs_port/src/options/scope_kinds.g.dart';
export 'package:flutter_chartjs_port/src/options/scopes.g.dart';
export 'package:flutter_chartjs_port/src/options/typed_record.dart';
export 'package:flutter_chartjs_port/src/platform/chart_host.dart'
    hide ChartPicturesLayer;
export 'package:flutter_chartjs_port/src/platform/index.dart';
export 'package:flutter_chartjs_port/src/platform/native_event.dart'
    hide invokeNativeEventListener, nativeEventStopped, setNativeEventTarget;
export 'package:flutter_chartjs_port/src/platform/platform.base.dart';
export 'package:flutter_chartjs_port/src/platform/platform.basic.dart';
export 'package:flutter_chartjs_port/src/platform/platform.flutter.dart';
export 'package:flutter_chartjs_port/src/plugins/decimation_algorithm.dart';
export 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
export 'package:flutter_chartjs_port/src/plugins/filler_draw_time.dart';
export 'package:flutter_chartjs_port/src/plugins/index.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.colors.dart'
    hide themeBackgroundColorsKey, themeBorderColorsKey;
export 'package:flutter_chartjs_port/src/plugins/plugin.decimation.dart'
    hide lttbDecimation, minMaxDecimation;
export 'package:flutter_chartjs_port/src/plugins/plugin.filler/boundary_point_search.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.drawing.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.helper.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.options.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.segment.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.target.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.target.stack.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.filler/partitioned_baseline_fill.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.filler/simpleArc.dart'
    hide SimpleArc;
export 'package:flutter_chartjs_port/src/plugins/plugin.filler/stack_point_search.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.legend.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.subtitle.dart';
export 'package:flutter_chartjs_port/src/plugins/plugin.title.dart' hide Title;
export 'package:flutter_chartjs_port/src/plugins/plugin.tooltip.dart'
    hide Tooltip;
export 'package:flutter_chartjs_port/src/plugins/plugin_options.dart';
export 'package:flutter_chartjs_port/src/plugins/tooltip_position.dart';
export 'package:flutter_chartjs_port/src/scales/index.dart';
export 'package:flutter_chartjs_port/src/scales/scale.category.dart';
export 'package:flutter_chartjs_port/src/scales/scale.linear.dart';
export 'package:flutter_chartjs_port/src/scales/scale.linearbase.dart';
export 'package:flutter_chartjs_port/src/scales/scale.logarithmic.dart';
export 'package:flutter_chartjs_port/src/scales/scale.radialLinear.dart';
export 'package:flutter_chartjs_port/src/scales/scale.time.dart';
export 'package:flutter_chartjs_port/src/scales/scale.timeseries.dart';
export 'package:flutter_chartjs_port/src/theme/chart_theme.dart';
export 'package:flutter_chartjs_port/src/theme/compile.dart';
export 'package:flutter_chartjs_port/src/theme/presets.dart';
export 'package:flutter_chartjs_port/src/theme/theme_data.dart'
    hide compileThemeData;
export 'package:flutter_chartjs_port/src/typed/axes.dart' hide lowerAxis;
export 'package:flutter_chartjs_port/src/typed/callbacks.dart';
export 'package:flutter_chartjs_port/src/typed/chart_value.dart';
export 'package:flutter_chartjs_port/src/typed/config.dart'
    hide optionFieldsEqual, pluginsEqual;
export 'package:flutter_chartjs_port/src/typed/datasets.dart' hide lowerDataset;
export 'package:flutter_chartjs_port/src/typed/elements.dart'
    hide lowerElements;
export 'package:flutter_chartjs_port/src/typed/groups.dart'
    hide
        lowerAnimation,
        lowerFiller,
        lowerInteraction,
        lowerLegend,
        lowerTitle,
        lowerTooltip,
        lowerTransitions;
export 'package:flutter_chartjs_port/src/typed/lower.dart'
    hide ChartConfigLowering, tooltipCallbacksTrampoline;
export 'package:flutter_chartjs_port/src/typed/props.dart';
export 'package:flutter_chartjs_port/src/typed/typed.dart';
export 'package:flutter_chartjs_port/src/types.dart' hide Animation, Element;
export 'package:flutter_chartjs_port/src/types/active_element.dart';
export 'package:flutter_chartjs_port/src/types/align.dart';
export 'package:flutter_chartjs_port/src/types/animation.dart' hide Animation;
export 'package:flutter_chartjs_port/src/types/arc_option_enums.dart';
export 'package:flutter_chartjs_port/src/types/axis_border.dart';
export 'package:flutter_chartjs_port/src/types/bar_option_enums.dart';
export 'package:flutter_chartjs_port/src/types/basic.dart';
export 'package:flutter_chartjs_port/src/types/chart_axis.dart';
export 'package:flutter_chartjs_port/src/types/chart_meta.dart';
export 'package:flutter_chartjs_port/src/types/chart_paint.dart';
export 'package:flutter_chartjs_port/src/types/chart_shadow.dart';
export 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
export 'package:flutter_chartjs_port/src/types/color.dart';
export 'package:flutter_chartjs_port/src/types/data_item.dart';
export 'package:flutter_chartjs_port/src/types/geometric.dart';
export 'package:flutter_chartjs_port/src/types/index.dart'
    hide
        BasePlatform,
        Chart,
        DatasetController,
        Element,
        LineElement,
        PointElement,
        RadialLinearScale,
        Scale,
        SimpleArc;
export 'package:flutter_chartjs_port/src/types/layout.dart';
export 'package:flutter_chartjs_port/src/types/legend_callbacks.dart';
export 'package:flutter_chartjs_port/src/types/legend_hit_box.dart';
export 'package:flutter_chartjs_port/src/types/legend_item.dart';
export 'package:flutter_chartjs_port/src/types/line_option_enums.dart';
export 'package:flutter_chartjs_port/src/types/line_segment_style.dart'
    hide lineSegmentStyleOf;
export 'package:flutter_chartjs_port/src/types/plugin.dart';
export 'package:flutter_chartjs_port/src/types/tick.dart' hide labelLinesOf;
export 'package:flutter_chartjs_port/src/types/tooltip_callbacks.dart'
    hide tooltipCallbacksOf, tooltipCallbacksPresence;
export 'package:flutter_chartjs_port/src/types/tooltip_item.dart'
    hide dataLabelLinesOf;
export 'package:flutter_chartjs_port/src/upstream.dart';
export 'package:flutter_chartjs_port/src/widgets/chart_keyboard.dart'
    hide ChartKeyboard;
export 'package:flutter_chartjs_port/src/widgets/chart_theme_switch.dart'
    hide ChartThemeSwitch;
export 'package:flutter_chartjs_port/src/widgets/chart_view.dart';
export 'package:flutter_chartjs_port/src/widgets/chart_view_plugin.dart'
    hide chartViewPluginId, createChartViewPlugin;
