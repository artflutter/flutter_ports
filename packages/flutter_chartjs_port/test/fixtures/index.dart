// Original code, not ported from Chart.js: the registry of the hand-ported fixture configs and the fixture skips.
// The header text of Chart.js ADR 0029, section 5 item 1, is longer than 80
// columns and has no URI.
// ignore_for_file: lines_longer_than_80_chars

/// `jasmine.fixture` of Chart.js `test/index.js:15-17` (Chart.js ADR 0029,
/// sections 2 and 5).
///
/// A spec file with a fixture group imports this file with the prefix
/// `fixture` and calls `group('auto', fixture.specs('<prefix>'))` at the
/// upstream line. This file is not a test entry: it has no `_test.dart`
/// suffix and no `@TestOn`. Only VM test files import it.
library;

import 'package:chartjs_test_utils/flutter.dart';

import 'hand/controller.bar/aligned-pixels.dart'
    as controller_bar_aligned_pixels;
import 'hand/controller.bar/backgroundColor/scriptable.dart'
    as controller_bar_backgroundcolor_scriptable;
import 'hand/controller.bar/bar-animation-hide-show.dart'
    as controller_bar_bar_animation_hide_show;
import 'hand/controller.bar/baseLine/bottom.dart'
    as controller_bar_baseline_bottom;
import 'hand/controller.bar/baseLine/left.dart' as controller_bar_baseline_left;
import 'hand/controller.bar/baseLine/mid-x.dart'
    as controller_bar_baseline_mid_x;
import 'hand/controller.bar/baseLine/mid-y.dart'
    as controller_bar_baseline_mid_y;
import 'hand/controller.bar/baseLine/right.dart'
    as controller_bar_baseline_right;
import 'hand/controller.bar/baseLine/top.dart' as controller_bar_baseline_top;
import 'hand/controller.bar/baseLine/value-x.dart'
    as controller_bar_baseline_value_x;
import 'hand/controller.bar/baseLine/value-y.dart'
    as controller_bar_baseline_value_y;
import 'hand/controller.bar/borderColor/scriptable.dart'
    as controller_bar_bordercolor_scriptable;
import 'hand/controller.bar/borderRadius/border-radius.dart'
    as controller_bar_borderradius_border_radius;
import 'hand/controller.bar/borderSkipped/scriptable.dart'
    as controller_bar_borderskipped_scriptable;
import 'hand/controller.bar/borderWidth/scriptable-object.dart'
    as controller_bar_borderwidth_scriptable_object;
import 'hand/controller.bar/borderWidth/scriptable.dart'
    as controller_bar_borderwidth_scriptable;
import 'hand/controller.bar/chart-area-clip.dart'
    as controller_bar_chart_area_clip;
import 'hand/controller.bar/data/object-index-axis-y.dart'
    as controller_bar_data_object_index_axis_y;
import 'hand/controller.bar/floatBar/data-as-objects-horizontal.dart'
    as controller_bar_floatbar_data_as_objects_horizontal;
import 'hand/controller.bar/floatBar/float-bar-horizontal.dart'
    as controller_bar_floatbar_float_bar_horizontal;
import 'hand/controller.bar/floatBar/float-bar-stacked-horizontal.dart'
    as controller_bar_floatbar_float_bar_stacked_horizontal;
import 'hand/controller.bar/horizontal-borders.dart'
    as controller_bar_horizontal_borders;
import 'hand/controller.bar/minBarLength/horizontal-neg.dart'
    as controller_bar_minbarlength_horizontal_neg;
import 'hand/controller.bar/minBarLength/horizontal-pos.dart'
    as controller_bar_minbarlength_horizontal_pos;
import 'hand/controller.bar/minBarLength/horizontal-stacked-no-overlap.dart'
    as controller_bar_minbarlength_horizontal_stacked_no_overlap;
import 'hand/controller.bar/minBarLength/horizontal-stacked.dart'
    as controller_bar_minbarlength_horizontal_stacked;
import 'hand/controller.bar/minBarLength/horizontal.dart'
    as controller_bar_minbarlength_horizontal;
import 'hand/controller.bar/minBarLength/vertical.dart'
    as controller_bar_minbarlength_vertical;
import 'hand/controller.bar/skipNull/bar-skip-null-object-data.dart'
    as controller_bar_skipnull_bar_skip_null_object_data;
import 'hand/controller.bar/skipNull/bar-skip-null.dart'
    as controller_bar_skipnull_bar_skip_null;
import 'hand/controller.bar/stacking/issue-9105.dart'
    as controller_bar_stacking_issue_9105;
import 'hand/controller.bar/stacking/remove-dataset.dart'
    as controller_bar_stacking_remove_dataset;
import 'hand/controller.bar/stacking/replace-data.dart'
    as controller_bar_stacking_replace_data;
import 'hand/controller.bubble/clip.dart' as controller_bubble_clip;
import 'hand/controller.bubble/hover-radius-zero.dart'
    as controller_bubble_hover_radius_zero;
import 'hand/controller.bubble/padding-update.dart'
    as controller_bubble_padding_update;
import 'hand/controller.bubble/point-style.dart'
    as controller_bubble_point_style;
import 'hand/controller.bubble/radius-data.dart'
    as controller_bubble_radius_data;
import 'hand/controller.bubble/radius-scriptable.dart'
    as controller_bubble_radius_scriptable;
import 'hand/controller.doughnut/backgroundColor/scriptable.dart'
    as controller_doughnut_backgroundcolor_scriptable;
import 'hand/controller.doughnut/borderAlign/scriptable.dart'
    as controller_doughnut_borderalign_scriptable;
import 'hand/controller.doughnut/borderColor/scriptable.dart'
    as controller_doughnut_bordercolor_scriptable;
import 'hand/controller.doughnut/borderDash/scriptable.dart'
    as controller_doughnut_borderdash_scriptable;
import 'hand/controller.doughnut/borderRadius/scriptable.dart'
    as controller_doughnut_borderradius_scriptable;
import 'hand/controller.doughnut/borderWidth/scriptable.dart'
    as controller_doughnut_borderwidth_scriptable;
import 'hand/controller.doughnut/doughnut-NaN.dart'
    as controller_doughnut_doughnut_nan;
import 'hand/controller.doughnut/doughnut-animation-hide-last.dart'
    as controller_doughnut_doughnut_animation_hide_last;
import 'hand/controller.doughnut/doughnut-animation.dart'
    as controller_doughnut_doughnut_animation;
import 'hand/controller.doughnut/doughnut-full-to-semi.dart'
    as controller_doughnut_doughnut_full_to_semi;
import 'hand/controller.doughnut/doughnut-hidden-single.dart'
    as controller_doughnut_doughnut_hidden_single;
import 'hand/controller.doughnut/doughnut-hidden.dart'
    as controller_doughnut_doughnut_hidden;
import 'hand/controller.doughnut/doughnut-offset.dart'
    as controller_doughnut_doughnut_offset;
import 'hand/controller.doughnut/doughnut-outer-radius-percent.dart'
    as controller_doughnut_doughnut_outer_radius_percent;
import 'hand/controller.doughnut/doughnut-outer-radius-pixels.dart'
    as controller_doughnut_doughnut_outer_radius_pixels;
import 'hand/controller.doughnut/doughnut-rotation-circumference-8x8.dart'
    as controller_doughnut_doughnut_rotation_circumference_8x8;
import 'hand/controller.doughnut/doughnut-set-active-elements.dart'
    as controller_doughnut_doughnut_set_active_elements;
import 'hand/controller.doughnut/event-replay.dart'
    as controller_doughnut_event_replay;
import 'hand/controller.doughnut/pie-offset.dart'
    as controller_doughnut_pie_offset;
import 'hand/controller.line/backgroundColor/scriptable.dart'
    as controller_line_backgroundcolor_scriptable;
import 'hand/controller.line/backgroundColor/value.dart'
    as controller_line_backgroundcolor_value;
import 'hand/controller.line/borderCapStyle/scriptable.dart'
    as controller_line_bordercapstyle_scriptable;
import 'hand/controller.line/borderCapStyle/value.dart'
    as controller_line_bordercapstyle_value;
import 'hand/controller.line/borderColor/scriptable.dart'
    as controller_line_bordercolor_scriptable;
import 'hand/controller.line/borderColor/value.dart'
    as controller_line_bordercolor_value;
import 'hand/controller.line/borderDash/scriptable.dart'
    as controller_line_borderdash_scriptable;
import 'hand/controller.line/borderDash/value.dart'
    as controller_line_borderdash_value;
import 'hand/controller.line/borderDashOffset/scriptable.dart'
    as controller_line_borderdashoffset_scriptable;
import 'hand/controller.line/borderDashOffset/value.dart'
    as controller_line_borderdashoffset_value;
import 'hand/controller.line/borderJoinStyle/scriptable.dart'
    as controller_line_borderjoinstyle_scriptable;
import 'hand/controller.line/borderJoinStyle/value.dart'
    as controller_line_borderjoinstyle_value;
import 'hand/controller.line/borderWidth/scriptable.dart'
    as controller_line_borderwidth_scriptable;
import 'hand/controller.line/borderWidth/value.dart'
    as controller_line_borderwidth_value;
import 'hand/controller.line/borderWidth/zero.dart'
    as controller_line_borderwidth_zero;
import 'hand/controller.line/clip/default-x-max.dart'
    as controller_line_clip_default_x_max;
import 'hand/controller.line/clip/default-x-min.dart'
    as controller_line_clip_default_x_min;
import 'hand/controller.line/clip/default-x.dart'
    as controller_line_clip_default_x;
import 'hand/controller.line/clip/default-y-max.dart'
    as controller_line_clip_default_y_max;
import 'hand/controller.line/clip/default-y-min.dart'
    as controller_line_clip_default_y_min;
import 'hand/controller.line/clip/default-y.dart'
    as controller_line_clip_default_y;
import 'hand/controller.line/clip/false.dart' as controller_line_clip_false;
import 'hand/controller.line/clip/specified.dart'
    as controller_line_clip_specified;
import 'hand/controller.line/cubicInterpolationMode/scriptable.dart'
    as controller_line_cubicinterpolationmode_scriptable;
import 'hand/controller.line/cubicInterpolationMode/value.dart'
    as controller_line_cubicinterpolationmode_value;
import 'hand/controller.line/fill/no-border.dart'
    as controller_line_fill_no_border;
import 'hand/controller.line/fill/order-default.dart'
    as controller_line_fill_order_default;
import 'hand/controller.line/fill/order.dart' as controller_line_fill_order;
import 'hand/controller.line/fill/scriptable.dart'
    as controller_line_fill_scriptable;
import 'hand/controller.line/fill/value.dart' as controller_line_fill_value;
import 'hand/controller.line/issue-8902.dart' as controller_line_issue_8902;
import 'hand/controller.line/non-numeric-y.dart'
    as controller_line_non_numeric_y;
import 'hand/controller.line/point-style-offscreen-canvas.dart'
    as controller_line_point_style_offscreen_canvas;
import 'hand/controller.line/point-style.dart' as controller_line_point_style;
import 'hand/controller.line/pointBackgroundColor/indexable.dart'
    as controller_line_pointbackgroundcolor_indexable;
import 'hand/controller.line/pointBackgroundColor/scriptable.dart'
    as controller_line_pointbackgroundcolor_scriptable;
import 'hand/controller.line/pointBackgroundColor/value.dart'
    as controller_line_pointbackgroundcolor_value;
import 'hand/controller.line/pointBorderColor/indexable.dart'
    as controller_line_pointbordercolor_indexable;
import 'hand/controller.line/pointBorderColor/scriptable.dart'
    as controller_line_pointbordercolor_scriptable;
import 'hand/controller.line/pointBorderColor/value.dart'
    as controller_line_pointbordercolor_value;
import 'hand/controller.line/pointBorderWidth/indexable.dart'
    as controller_line_pointborderwidth_indexable;
import 'hand/controller.line/pointBorderWidth/scriptable.dart'
    as controller_line_pointborderwidth_scriptable;
import 'hand/controller.line/pointBorderWidth/value.dart'
    as controller_line_pointborderwidth_value;
import 'hand/controller.line/pointStyle/indexable.dart'
    as controller_line_pointstyle_indexable;
import 'hand/controller.line/pointStyle/scriptable.dart'
    as controller_line_pointstyle_scriptable;
import 'hand/controller.line/pointStyle/value.dart'
    as controller_line_pointstyle_value;
import 'hand/controller.line/radius/indexable.dart'
    as controller_line_radius_indexable;
import 'hand/controller.line/radius/scriptable-to-value.dart'
    as controller_line_radius_scriptable_to_value;
import 'hand/controller.line/radius/scriptable.dart'
    as controller_line_radius_scriptable;
import 'hand/controller.line/radius/value.dart' as controller_line_radius_value;
import 'hand/controller.line/rotation/indexable.dart'
    as controller_line_rotation_indexable;
import 'hand/controller.line/rotation/scriptable.dart'
    as controller_line_rotation_scriptable;
import 'hand/controller.line/rotation/value.dart'
    as controller_line_rotation_value;
import 'hand/controller.line/segments/gap.dart' as controller_line_segments_gap;
import 'hand/controller.line/segments/gradient.dart'
    as controller_line_segments_gradient;
import 'hand/controller.line/segments/range.dart'
    as controller_line_segments_range;
import 'hand/controller.line/segments/single.dart'
    as controller_line_segments_single;
import 'hand/controller.line/segments/slope.dart'
    as controller_line_segments_slope;
import 'hand/controller.line/segments/spanGaps.dart'
    as controller_line_segments_spangaps;
import 'hand/controller.line/showLine/dataset.dart'
    as controller_line_showline_dataset;
import 'hand/controller.line/showLine/false.dart'
    as controller_line_showline_false;
import 'hand/controller.line/stacking/order-default.dart'
    as controller_line_stacking_order_default;
import 'hand/controller.line/stacking/order-specified.dart'
    as controller_line_stacking_order_specified;
import 'hand/controller.line/stacking/single.dart'
    as controller_line_stacking_single;
import 'hand/controller.line/stacking/stack-cache.dart'
    as controller_line_stacking_stack_cache;
import 'hand/controller.line/stacking/updates.dart'
    as controller_line_stacking_updates;
import 'hand/controller.polarArea/backgroundColor/scriptable-dataset.dart'
    as controller_polararea_backgroundcolor_scriptable_dataset;
import 'hand/controller.polarArea/backgroundColor/scriptable-element-options.dart'
    as controller_polararea_backgroundcolor_scriptable_element_options;
import 'hand/controller.polarArea/borderAlign/scriptable-dataset.dart'
    as controller_polararea_borderalign_scriptable_dataset;
import 'hand/controller.polarArea/borderAlign/scriptable-element-options.dart'
    as controller_polararea_borderalign_scriptable_element_options;
import 'hand/controller.polarArea/borderColor/scriptable-dataset.dart'
    as controller_polararea_bordercolor_scriptable_dataset;
import 'hand/controller.polarArea/borderColor/scriptable-element-options.dart'
    as controller_polararea_bordercolor_scriptable_element_options;
import 'hand/controller.polarArea/borderDash/scriptable.dart'
    as controller_polararea_borderdash_scriptable;
import 'hand/controller.polarArea/borderWidth/scriptable-dataset.dart'
    as controller_polararea_borderwidth_scriptable_dataset;
import 'hand/controller.polarArea/borderWidth/scriptable-element-options.dart'
    as controller_polararea_borderwidth_scriptable_element_options;
import 'hand/controller.polarArea/last-slice-animate.dart'
    as controller_polararea_last_slice_animate;
import 'hand/controller.polarArea/pointLabels/overlapping.dart'
    as controller_polararea_pointlabels_overlapping;
import 'hand/controller.polarArea/polar-area-animation-rotate.dart'
    as controller_polararea_polar_area_animation_rotate;
import 'hand/controller.polarArea/polar-area-animation-scale.dart'
    as controller_polararea_polar_area_animation_scale;
import 'hand/controller.radar/backgroundColor/scriptable.dart'
    as controller_radar_backgroundcolor_scriptable;
import 'hand/controller.radar/backgroundColor/value.dart'
    as controller_radar_backgroundcolor_value;
import 'hand/controller.radar/borderCapStyle/scriptable.dart'
    as controller_radar_bordercapstyle_scriptable;
import 'hand/controller.radar/borderCapStyle/value.dart'
    as controller_radar_bordercapstyle_value;
import 'hand/controller.radar/borderColor/scriptable.dart'
    as controller_radar_bordercolor_scriptable;
import 'hand/controller.radar/borderColor/value.dart'
    as controller_radar_bordercolor_value;
import 'hand/controller.radar/borderDash/scriptable.dart'
    as controller_radar_borderdash_scriptable;
import 'hand/controller.radar/borderDash/value.dart'
    as controller_radar_borderdash_value;
import 'hand/controller.radar/borderDashOffset/scriptable.dart'
    as controller_radar_borderdashoffset_scriptable;
import 'hand/controller.radar/borderDashOffset/value.dart'
    as controller_radar_borderdashoffset_value;
import 'hand/controller.radar/borderJoinStyle/scriptable.dart'
    as controller_radar_borderjoinstyle_scriptable;
import 'hand/controller.radar/borderJoinStyle/value.dart'
    as controller_radar_borderjoinstyle_value;
import 'hand/controller.radar/borderWidth/scriptable.dart'
    as controller_radar_borderwidth_scriptable;
import 'hand/controller.radar/borderWidth/value.dart'
    as controller_radar_borderwidth_value;
import 'hand/controller.radar/borderWidth/zero.dart'
    as controller_radar_borderwidth_zero;
import 'hand/controller.radar/fill/scriptable.dart'
    as controller_radar_fill_scriptable;
import 'hand/controller.radar/fill/value.dart' as controller_radar_fill_value;
import 'hand/controller.radar/point-style.dart' as controller_radar_point_style;
import 'hand/controller.radar/pointBackgroundColor/indexable.dart'
    as controller_radar_pointbackgroundcolor_indexable;
import 'hand/controller.radar/pointBackgroundColor/scriptable.dart'
    as controller_radar_pointbackgroundcolor_scriptable;
import 'hand/controller.radar/pointBackgroundColor/value.dart'
    as controller_radar_pointbackgroundcolor_value;
import 'hand/controller.radar/pointBorderColor/indexable.dart'
    as controller_radar_pointbordercolor_indexable;
import 'hand/controller.radar/pointBorderColor/scriptable.dart'
    as controller_radar_pointbordercolor_scriptable;
import 'hand/controller.radar/pointBorderColor/value.dart'
    as controller_radar_pointbordercolor_value;
import 'hand/controller.radar/pointBorderWidth/indexable.dart'
    as controller_radar_pointborderwidth_indexable;
import 'hand/controller.radar/pointBorderWidth/scriptable.dart'
    as controller_radar_pointborderwidth_scriptable;
import 'hand/controller.radar/pointBorderWidth/value.dart'
    as controller_radar_pointborderwidth_value;
import 'hand/controller.radar/pointStyle/indexable.dart'
    as controller_radar_pointstyle_indexable;
import 'hand/controller.radar/pointStyle/scriptable.dart'
    as controller_radar_pointstyle_scriptable;
import 'hand/controller.radar/pointStyle/value.dart'
    as controller_radar_pointstyle_value;
import 'hand/controller.radar/radius/indexable.dart'
    as controller_radar_radius_indexable;
import 'hand/controller.radar/radius/scriptable.dart'
    as controller_radar_radius_scriptable;
import 'hand/controller.radar/radius/value.dart'
    as controller_radar_radius_value;
import 'hand/controller.radar/rotation/indexable.dart'
    as controller_radar_rotation_indexable;
import 'hand/controller.radar/rotation/scriptable.dart'
    as controller_radar_rotation_scriptable;
import 'hand/controller.radar/rotation/value.dart'
    as controller_radar_rotation_value;
import 'hand/controller.radar/showLine/value.dart'
    as controller_radar_showline_value;
import 'hand/controller.scatter/showLine/changed.dart'
    as controller_scatter_showline_changed;
import 'hand/core.interaction/drawActiveElementsOnTop-false.dart'
    as core_interaction_drawactiveelementsontop_false;
import 'hand/core.interaction/nearest-partial-bar.dart'
    as core_interaction_nearest_partial_bar;
import 'hand/core.interaction/nearest-point-behind-scale.dart'
    as core_interaction_nearest_point_behind_scale;
import 'hand/core.layouts/hidden-vertical-boxes.dart'
    as core_layouts_hidden_vertical_boxes;
import 'hand/core.layouts/no-boxes-all-padding.dart'
    as core_layouts_no_boxes_all_padding;
import 'hand/core.layouts/scriptable.dart' as core_layouts_scriptable;
import 'hand/core.layouts/stacked-boxes-max-index-without-clip.dart'
    as core_layouts_stacked_boxes_max_index_without_clip;
import 'hand/core.layouts/stacked-boxes-max-index.dart'
    as core_layouts_stacked_boxes_max_index;
import 'hand/core.layouts/stacked-boxes-max-without-clip.dart'
    as core_layouts_stacked_boxes_max_without_clip;
import 'hand/core.layouts/stacked-boxes-max.dart'
    as core_layouts_stacked_boxes_max;
import 'hand/core.layouts/stacked-boxes-with-weight.dart'
    as core_layouts_stacked_boxes_with_weight;
import 'hand/core.layouts/stacked-boxes.dart' as core_layouts_stacked_boxes;
import 'hand/core.scale/border-behind-elements.dart'
    as core_scale_border_behind_elements;
import 'hand/core.scale/cartesian-axis-border-settings.dart'
    as core_scale_cartesian_axis_border_settings;
import 'hand/core.scale/crossAlignment/cross-align-left-center.dart'
    as core_scale_crossalignment_cross_align_left_center;
import 'hand/core.scale/crossAlignment/cross-align-left-far-clipped.dart'
    as core_scale_crossalignment_cross_align_left_far_clipped;
import 'hand/core.scale/crossAlignment/cross-align-left-far.dart'
    as core_scale_crossalignment_cross_align_left_far;
import 'hand/core.scale/crossAlignment/cross-align-left-near.dart'
    as core_scale_crossalignment_cross_align_left_near;
import 'hand/core.scale/crossAlignment/cross-align-right-center.dart'
    as core_scale_crossalignment_cross_align_right_center;
import 'hand/core.scale/crossAlignment/cross-align-right-far-clipped.dart'
    as core_scale_crossalignment_cross_align_right_far_clipped;
import 'hand/core.scale/crossAlignment/cross-align-right-far.dart'
    as core_scale_crossalignment_cross_align_right_far;
import 'hand/core.scale/crossAlignment/cross-align-right-near.dart'
    as core_scale_crossalignment_cross_align_right_near;
import 'hand/core.scale/crossAlignment/mirror-cross-align-left-center.dart'
    as core_scale_crossalignment_mirror_cross_align_left_center;
import 'hand/core.scale/crossAlignment/mirror-cross-align-left-far.dart'
    as core_scale_crossalignment_mirror_cross_align_left_far;
import 'hand/core.scale/crossAlignment/mirror-cross-align-left-near.dart'
    as core_scale_crossalignment_mirror_cross_align_left_near;
import 'hand/core.scale/crossAlignment/mirror-cross-align-right-center.dart'
    as core_scale_crossalignment_mirror_cross_align_right_center;
import 'hand/core.scale/crossAlignment/mirror-cross-align-right-far.dart'
    as core_scale_crossalignment_mirror_cross_align_right_far;
import 'hand/core.scale/crossAlignment/mirror-cross-align-right-near.dart'
    as core_scale_crossalignment_mirror_cross_align_right_near;
import 'hand/core.scale/grid/border-over-grid.dart'
    as core_scale_grid_border_over_grid;
import 'hand/core.scale/grid/colors.dart' as core_scale_grid_colors;
import 'hand/core.scale/grid/scriptable-borderDash.dart'
    as core_scale_grid_scriptable_borderdash;
import 'hand/core.scale/label-offset-vertical-axes.dart'
    as core_scale_label_offset_vertical_axes;
import 'hand/core.scale/tick-backdrop-rotation.dart'
    as core_scale_tick_backdrop_rotation;
import 'hand/core.scale/tick-backdrop.dart' as core_scale_tick_backdrop;
import 'hand/core.scale/tick-drawing.dart' as core_scale_tick_drawing;
import 'hand/core.scale/tick-override-styles.dart'
    as core_scale_tick_override_styles;
import 'hand/core.scale/ticks/rotated-long.dart'
    as core_scale_ticks_rotated_long;
import 'hand/core.scale/ticks/rotated-multi-line.dart'
    as core_scale_ticks_rotated_multi_line;
import 'hand/core.scale/ticks/skip-by-callback.dart'
    as core_scale_ticks_skip_by_callback;
import 'hand/core.scale/x-axis-position-center.dart'
    as core_scale_x_axis_position_center;
import 'hand/core.scale/x-axis-position-dynamic.dart'
    as core_scale_x_axis_position_dynamic;
import 'hand/core.scale/y-axis-position-center.dart'
    as core_scale_y_axis_position_center;
import 'hand/core.scale/y-axis-position-dynamic.dart'
    as core_scale_y_axis_position_dynamic;
import 'hand/element.line/cubicInterpolationMode/monotone-horizontal.dart'
    as element_line_cubicinterpolationmode_monotone_horizontal;
import 'hand/element.line/cubicInterpolationMode/monotone-vertical.dart'
    as element_line_cubicinterpolationmode_monotone_vertical;
import 'hand/element.line/skip/all.dart' as element_line_skip_all;
import 'hand/element.line/skip/first-span.dart' as element_line_skip_first_span;
import 'hand/element.line/skip/first.dart' as element_line_skip_first;
import 'hand/element.line/skip/last-span.dart' as element_line_skip_last_span;
import 'hand/element.line/skip/last.dart' as element_line_skip_last;
import 'hand/element.line/skip/middle-span.dart'
    as element_line_skip_middle_span;
import 'hand/element.line/skip/middle.dart' as element_line_skip_middle;
import 'hand/element.line/stepped/after.dart' as element_line_stepped_after;
import 'hand/element.line/stepped/before.dart' as element_line_stepped_before;
import 'hand/element.line/stepped/default.dart' as element_line_stepped_default;
import 'hand/element.line/stepped/middle.dart' as element_line_stepped_middle;
import 'hand/element.line/tension/default.dart' as element_line_tension_default;
import 'hand/element.line/tension/one.dart' as element_line_tension_one;
import 'hand/element.line/tension/zero.dart' as element_line_tension_zero;
import 'hand/element.point/point-style-circle.dart'
    as element_point_point_style_circle;
import 'hand/element.point/point-style-cross-rot.dart'
    as element_point_point_style_cross_rot;
import 'hand/element.point/point-style-cross.dart'
    as element_point_point_style_cross;
import 'hand/element.point/point-style-dash.dart'
    as element_point_point_style_dash;
import 'hand/element.point/point-style-image.dart'
    as element_point_point_style_image;
import 'hand/element.point/point-style-line.dart'
    as element_point_point_style_line;
import 'hand/element.point/point-style-rect-rot.dart'
    as element_point_point_style_rect_rot;
import 'hand/element.point/point-style-rect-rounded.dart'
    as element_point_point_style_rect_rounded;
import 'hand/element.point/point-style-rect.dart'
    as element_point_point_style_rect;
import 'hand/element.point/point-style-star.dart'
    as element_point_point_style_star;
import 'hand/element.point/point-style-triangle.dart'
    as element_point_point_style_triangle;
import 'hand/element.point/rotation.dart' as element_point_rotation;
import 'hand/mixed/bar+line-stacked.dart' as mixed_bar_line_stacked;
import 'hand/mixed/bar+line.dart' as mixed_bar_line;
import 'hand/plugin.colors/dynamic-datasets-default.dart'
    as plugin_colors_dynamic_datasets_default;
import 'hand/plugin.colors/dynamic-datasets-force-override.dart'
    as plugin_colors_dynamic_datasets_force_override;
import 'hand/plugin.filler/line/above-below-vertical-linechart.dart'
    as plugin_filler_line_above_below_vertical_linechart;
import 'hand/plugin.filler/line/before-dataset-draw.dart'
    as plugin_filler_line_before_dataset_draw;
import 'hand/plugin.filler/line/before-datasets-draw.dart'
    as plugin_filler_line_before_datasets_draw;
import 'hand/plugin.filler/line/boundary/above-below-line-null-start.dart'
    as plugin_filler_line_boundary_above_below_line_null_start;
import 'hand/plugin.filler/line/boundary/above-below-line-null.dart'
    as plugin_filler_line_boundary_above_below_line_null;
import 'hand/plugin.filler/line/boundary/end-span.dart'
    as plugin_filler_line_boundary_end_span;
import 'hand/plugin.filler/line/boundary/end.dart'
    as plugin_filler_line_boundary_end;
import 'hand/plugin.filler/line/boundary/origin-span-dual.dart'
    as plugin_filler_line_boundary_origin_span_dual;
import 'hand/plugin.filler/line/boundary/origin-span.dart'
    as plugin_filler_line_boundary_origin_span;
import 'hand/plugin.filler/line/boundary/origin-spline-above.dart'
    as plugin_filler_line_boundary_origin_spline_above;
import 'hand/plugin.filler/line/boundary/origin-spline-span.dart'
    as plugin_filler_line_boundary_origin_spline_span;
import 'hand/plugin.filler/line/boundary/origin-spline.dart'
    as plugin_filler_line_boundary_origin_spline;
import 'hand/plugin.filler/line/boundary/origin-stepped-span.dart'
    as plugin_filler_line_boundary_origin_stepped_span;
import 'hand/plugin.filler/line/boundary/origin-stepped.dart'
    as plugin_filler_line_boundary_origin_stepped;
import 'hand/plugin.filler/line/boundary/origin.dart'
    as plugin_filler_line_boundary_origin;
import 'hand/plugin.filler/line/boundary/start-span.dart'
    as plugin_filler_line_boundary_start_span;
import 'hand/plugin.filler/line/boundary/start.dart'
    as plugin_filler_line_boundary_start;
import 'hand/plugin.filler/line/dataset/border.dart'
    as plugin_filler_line_dataset_border;
import 'hand/plugin.filler/line/dataset/clip-bounds-x-off.dart'
    as plugin_filler_line_dataset_clip_bounds_x_off;
import 'hand/plugin.filler/line/dataset/clip-bounds-x.dart'
    as plugin_filler_line_dataset_clip_bounds_x;
import 'hand/plugin.filler/line/dataset/clip-bounds-y-off.dart'
    as plugin_filler_line_dataset_clip_bounds_y_off;
import 'hand/plugin.filler/line/dataset/clip-bounds-y.dart'
    as plugin_filler_line_dataset_clip_bounds_y;
import 'hand/plugin.filler/line/dataset/dual.dart'
    as plugin_filler_line_dataset_dual;
import 'hand/plugin.filler/line/dataset/interpolated.dart'
    as plugin_filler_line_dataset_interpolated;
import 'hand/plugin.filler/line/dataset/no-border.dart'
    as plugin_filler_line_dataset_no_border;
import 'hand/plugin.filler/line/dataset/span-dual.dart'
    as plugin_filler_line_dataset_span_dual;
import 'hand/plugin.filler/line/dataset/span.dart'
    as plugin_filler_line_dataset_span;
import 'hand/plugin.filler/line/dataset/spline-span-above.dart'
    as plugin_filler_line_dataset_spline_span_above;
import 'hand/plugin.filler/line/dataset/spline-span-below.dart'
    as plugin_filler_line_dataset_spline_span_below;
import 'hand/plugin.filler/line/dataset/spline-span.dart'
    as plugin_filler_line_dataset_spline_span;
import 'hand/plugin.filler/line/dataset/spline.dart'
    as plugin_filler_line_dataset_spline;
import 'hand/plugin.filler/line/dataset/stepped.dart'
    as plugin_filler_line_dataset_stepped;
import 'hand/plugin.filler/line/drawTimeFillFalse/beforeDatasetDraw.dart'
    as plugin_filler_line_drawtimefillfalse_beforedatasetdraw;
import 'hand/plugin.filler/line/drawTimeFillFalse/beforeDatasetsDraw.dart'
    as plugin_filler_line_drawtimefillfalse_beforedatasetsdraw;
import 'hand/plugin.filler/line/drawTimeFillFalse/beforeDraw.dart'
    as plugin_filler_line_drawtimefillfalse_beforedraw;
import 'hand/plugin.filler/line/offset-scale-minmax.dart'
    as plugin_filler_line_offset_scale_minmax;
import 'hand/plugin.filler/line/points-outside-canvas-initial.dart'
    as plugin_filler_line_points_outside_canvas_initial;
import 'hand/plugin.filler/line/points-outside-canvas-update.dart'
    as plugin_filler_line_points_outside_canvas_update;
import 'hand/plugin.filler/line/segments/alignToPixels.dart'
    as plugin_filler_line_segments_aligntopixels;
import 'hand/plugin.filler/line/segments/gap.dart'
    as plugin_filler_line_segments_gap;
import 'hand/plugin.filler/line/segments/slope.dart'
    as plugin_filler_line_segments_slope;
import 'hand/plugin.filler/line/shape.dart' as plugin_filler_line_shape;
import 'hand/plugin.filler/line/stack-multiple-scales.dart'
    as plugin_filler_line_stack_multiple_scales;
import 'hand/plugin.filler/line/stack.dart' as plugin_filler_line_stack;
import 'hand/plugin.filler/line/value.dart' as plugin_filler_line_value;
import 'hand/plugin.filler/line/vertical.dart' as plugin_filler_line_vertical;
import 'hand/plugin.filler/radar/beforeDraw.dart'
    as plugin_filler_radar_beforedraw;
import 'hand/plugin.filler/radar/boundary/end-circular.dart'
    as plugin_filler_radar_boundary_end_circular;
import 'hand/plugin.filler/radar/boundary/end-span.dart'
    as plugin_filler_radar_boundary_end_span;
import 'hand/plugin.filler/radar/boundary/end.dart'
    as plugin_filler_radar_boundary_end;
import 'hand/plugin.filler/radar/boundary/origin-circular.dart'
    as plugin_filler_radar_boundary_origin_circular;
import 'hand/plugin.filler/radar/boundary/origin-span.dart'
    as plugin_filler_radar_boundary_origin_span;
import 'hand/plugin.filler/radar/boundary/origin-spline-span.dart'
    as plugin_filler_radar_boundary_origin_spline_span;
import 'hand/plugin.filler/radar/boundary/origin-spline.dart'
    as plugin_filler_radar_boundary_origin_spline;
import 'hand/plugin.filler/radar/boundary/origin.dart'
    as plugin_filler_radar_boundary_origin;
import 'hand/plugin.filler/radar/boundary/start-circular.dart'
    as plugin_filler_radar_boundary_start_circular;
import 'hand/plugin.filler/radar/boundary/start-span.dart'
    as plugin_filler_radar_boundary_start_span;
import 'hand/plugin.filler/radar/boundary/start.dart'
    as plugin_filler_radar_boundary_start;
import 'hand/plugin.filler/radar/dataset/border.dart'
    as plugin_filler_radar_dataset_border;
import 'hand/plugin.filler/radar/dataset/default.dart'
    as plugin_filler_radar_dataset_default;
import 'hand/plugin.filler/radar/dataset/span.dart'
    as plugin_filler_radar_dataset_span;
import 'hand/plugin.filler/radar/dataset/spline.dart'
    as plugin_filler_radar_dataset_spline;
import 'hand/plugin.filler/radar/value.dart' as plugin_filler_radar_value;
import 'hand/plugin.legend/borderRadius/legend-border-radius.dart'
    as plugin_legend_borderradius_legend_border_radius;
import 'hand/plugin.legend/horizontal-rtl-hitbox.dart'
    as plugin_legend_horizontal_rtl_hitbox;
import 'hand/plugin.legend/legend-doughnut-point-style.dart'
    as plugin_legend_legend_doughnut_point_style;
import 'hand/plugin.legend/maxWidth/infinity.dart'
    as plugin_legend_maxwidth_infinity;
import 'hand/plugin.legend/padding/2cols-with-padding.dart'
    as plugin_legend_padding_2cols_with_padding;
import 'hand/plugin.legend/padding/add-column.dart'
    as plugin_legend_padding_add_column;
import 'hand/plugin.legend/pointStyle-width/legend-pointStyle-width-default.dart'
    as plugin_legend_pointstyle_width_legend_pointstyle_width_default;
import 'hand/plugin.legend/pointStyle-width/legend-pointStyle-width.dart'
    as plugin_legend_pointstyle_width_legend_pointstyle_width;
import 'hand/plugin.title/scriptable-options.dart'
    as plugin_title_scriptable_options;
import 'hand/plugin.tooltip/box-padding.dart' as plugin_tooltip_box_padding;
import 'hand/plugin.tooltip/caret-position.dart'
    as plugin_tooltip_caret_position;
import 'hand/plugin.tooltip/color-box-border-dash.dart'
    as plugin_tooltip_color_box_border_dash;
import 'hand/plugin.tooltip/color-box-border-radius.dart'
    as plugin_tooltip_color_box_border_radius;
import 'hand/plugin.tooltip/corner-radius.dart' as plugin_tooltip_corner_radius;
import 'hand/plugin.tooltip/opacity.dart' as plugin_tooltip_opacity;
import 'hand/plugin.tooltip/point-style.dart' as plugin_tooltip_point_style;
import 'hand/plugin.tooltip/positioning.dart' as plugin_tooltip_positioning;
import 'hand/scale.category/invalid-data.dart' as scale_category_invalid_data;
import 'hand/scale.category/max-ticks-limit-a.dart'
    as scale_category_max_ticks_limit_a;
import 'hand/scale.category/max-ticks-limit-b.dart'
    as scale_category_max_ticks_limit_b;
import 'hand/scale.category/max-ticks-limit-norotation.dart'
    as scale_category_max_ticks_limit_norotation;
import 'hand/scale.category/ticks-from-data.dart'
    as scale_category_ticks_from_data;
import 'hand/scale.linear/grace/grace-10%25.dart'
    as scale_linear_grace_grace_10_;
import 'hand/scale.linear/grace/grace-beginAtZero.dart'
    as scale_linear_grace_grace_beginatzero;
import 'hand/scale.linear/grace/grace-neg.dart' as scale_linear_grace_grace_neg;
import 'hand/scale.linear/grace/grace-pos.dart' as scale_linear_grace_grace_pos;
import 'hand/scale.linear/grace/grace.dart' as scale_linear_grace_grace;
import 'hand/scale.linear/grace/issue-8912.dart'
    as scale_linear_grace_issue_8912;
import 'hand/scale.linear/tick-count-data-limits.dart'
    as scale_linear_tick_count_data_limits;
import 'hand/scale.logarithmic/large-range.dart'
    as scale_logarithmic_large_range;
import 'hand/scale.logarithmic/large-values-small-range.dart'
    as scale_logarithmic_large_values_small_range;
import 'hand/scale.logarithmic/med-range.dart' as scale_logarithmic_med_range;
import 'hand/scale.logarithmic/min-max.dart' as scale_logarithmic_min_max;
import 'hand/scale.logarithmic/null-values.dart'
    as scale_logarithmic_null_values;
import 'hand/scale.logarithmic/small-range.dart'
    as scale_logarithmic_small_range;
import 'hand/scale.radialLinear/anglelines-scriptable.dart'
    as scale_radiallinear_anglelines_scriptable;
import 'hand/scale.radialLinear/border-dash.dart'
    as scale_radiallinear_border_dash;
import 'hand/scale.radialLinear/circular-border-dash.dart'
    as scale_radiallinear_circular_border_dash;
import 'hand/scale.radialLinear/gridlines-scriptable.dart'
    as scale_radiallinear_gridlines_scriptable;
import 'hand/scale.radialLinear/pointLabels/background.dart'
    as scale_radiallinear_pointlabels_background;
import 'hand/scale.radialLinear/pointLabels/border-radius.dart'
    as scale_radiallinear_pointlabels_border_radius;
import 'hand/scale.radialLinear/pointLabels/scriptable-color-small.dart'
    as scale_radiallinear_pointlabels_scriptable_color_small;
import 'hand/scale.radialLinear/ticks-below-zero.dart'
    as scale_radiallinear_ticks_below_zero;
import 'hand/scale.time/autoskip-major.dart' as scale_time_autoskip_major;
import 'hand/scale.time/bar-large-gap-between-data.dart'
    as scale_time_bar_large_gap_between_data;
import 'hand/scale.time/custom-parser.dart' as scale_time_custom_parser;
import 'hand/scale.time/data-ty.dart' as scale_time_data_ty;
import 'hand/scale.time/data-xy.dart' as scale_time_data_xy;
import 'hand/scale.time/labels-date.dart' as scale_time_labels_date;
import 'hand/scale.time/negative-times.dart' as scale_time_negative_times;
import 'hand/scale.time/offset-auto-skip-ticks.dart'
    as scale_time_offset_auto_skip_ticks;
import 'hand/scale.time/offset-with-no-ticks.dart'
    as scale_time_offset_with_no_ticks;
import 'hand/scale.timeseries/data-timestamps.dart'
    as scale_timeseries_data_timestamps;
import 'hand/scale.timeseries/financial-daily.dart'
    as scale_timeseries_financial_daily;

/// `jasmine.fixture.specs(path)` of Chart.js `test/index.js:15-17`.
void Function() specs(String path) =>
    specsFromFixtures(path, hand: handFixtures, skips: fixtureSkips);

/// The hand-ported configs by fixture path (Chart.js ADR 0029, section 5):
/// the impure configs and the data configs with a class value (Chart.js ADR
/// 0115).
///
/// Each entry maps the path relative to `test/fixtures/` to the `fixture`
/// function of `hand/<path>.dart` and the first 12 hex digits of the
/// `sha256` of the upstream file in `doc/upstream/manifest.json`.
final Map<String, HandFixture> handFixtures = {
  'scale.radialLinear/pointLabels/border-radius.js': (
    load: scale_radiallinear_pointlabels_border_radius.fixture,
    sha256: 'b05b82ebab93',
  ),
  'scale.radialLinear/pointLabels/background.js': (
    load: scale_radiallinear_pointlabels_background.fixture,
    sha256: '1a660eaebfd1',
  ),
  'scale.category/max-ticks-limit-norotation.js': (
    load: scale_category_max_ticks_limit_norotation.fixture,
    sha256: '3878d06f86cf',
  ),
  'scale.category/max-ticks-limit-b.js': (
    load: scale_category_max_ticks_limit_b.fixture,
    sha256: '37b4891b511e',
  ),
  'scale.category/max-ticks-limit-a.js': (
    load: scale_category_max_ticks_limit_a.fixture,
    sha256: '09cf84f34777',
  ),
  'plugin.legend/padding/2cols-with-padding.js': (
    load: plugin_legend_padding_2cols_with_padding.fixture,
    sha256: 'ea51cab97ce5',
  ),
  'plugin.filler/radar/beforeDraw.js': (
    load: plugin_filler_radar_beforedraw.fixture,
    sha256: '7e340f017db3',
  ),
  'core.scale/tick-backdrop.js': (
    load: core_scale_tick_backdrop.fixture,
    sha256: '89d425983ffd',
  ),
  'core.scale/tick-backdrop-rotation.js': (
    load: core_scale_tick_backdrop_rotation.fixture,
    sha256: '2244f2079be2',
  ),
  'core.layouts/no-boxes-all-padding.js': (
    load: core_layouts_no_boxes_all_padding.fixture,
    sha256: 'a96320f7bf65',
  ),
  'controller.radar/borderJoinStyle/value.js': (
    load: controller_radar_borderjoinstyle_value.fixture,
    sha256: '89e13072caed',
  ),
  'controller.radar/borderDashOffset/value.js': (
    load: controller_radar_borderdashoffset_value.fixture,
    sha256: '96d39068cbc3',
  ),
  'controller.radar/borderCapStyle/value.js': (
    load: controller_radar_bordercapstyle_value.fixture,
    sha256: '681c1ef30ff1',
  ),
  'controller.line/stacking/order-specified.js': (
    load: controller_line_stacking_order_specified.fixture,
    sha256: '024ef20c876d',
  ),
  'controller.line/stacking/order-default.js': (
    load: controller_line_stacking_order_default.fixture,
    sha256: 'c244c7024756',
  ),
  'controller.line/fill/value.js': (
    load: controller_line_fill_value.fixture,
    sha256: 'd7169e78d375',
  ),
  'controller.line/fill/order.js': (
    load: controller_line_fill_order.fixture,
    sha256: '0e9b577b1cdd',
  ),
  'controller.line/fill/order-default.js': (
    load: controller_line_fill_order_default.fixture,
    sha256: '80f197d5f920',
  ),
  'controller.line/clip/specified.json': (
    load: controller_line_clip_specified.fixture,
    sha256: '343d3d39e643',
  ),
  'controller.line/clip/default-y.json': (
    load: controller_line_clip_default_y.fixture,
    sha256: 'ffe6d9f64bef',
  ),
  'controller.line/clip/default-y-min.json': (
    load: controller_line_clip_default_y_min.fixture,
    sha256: 'fd1f2d662266',
  ),
  'controller.line/clip/default-y-max.json': (
    load: controller_line_clip_default_y_max.fixture,
    sha256: '473da4a46f1f',
  ),
  'controller.line/clip/default-x.json': (
    load: controller_line_clip_default_x.fixture,
    sha256: '7e49d010b700',
  ),
  'controller.line/clip/default-x-min.json': (
    load: controller_line_clip_default_x_min.fixture,
    sha256: '7807f219cc9b',
  ),
  'controller.line/clip/default-x-max.json': (
    load: controller_line_clip_default_x_max.fixture,
    sha256: '73cc805e9739',
  ),
  'controller.line/borderWidth/zero.js': (
    load: controller_line_borderwidth_zero.fixture,
    sha256: 'b4e97a0f35c7',
  ),
  'controller.line/borderWidth/value.js': (
    load: controller_line_borderwidth_value.fixture,
    sha256: 'd68efe1a3394',
  ),
  'controller.line/borderJoinStyle/value.js': (
    load: controller_line_borderjoinstyle_value.fixture,
    sha256: '72a31c1febf4',
  ),
  'controller.line/borderDashOffset/value.js': (
    load: controller_line_borderdashoffset_value.fixture,
    sha256: 'd1ed7ceb00c9',
  ),
  'controller.line/borderDash/value.js': (
    load: controller_line_borderdash_value.fixture,
    sha256: '1a34431b0f91',
  ),
  'controller.line/borderColor/value.js': (
    load: controller_line_bordercolor_value.fixture,
    sha256: '164e97fb2070',
  ),
  'controller.line/borderCapStyle/value.js': (
    load: controller_line_bordercapstyle_value.fixture,
    sha256: '6d92a06c46c9',
  ),
  'controller.line/backgroundColor/value.js': (
    load: controller_line_backgroundcolor_value.fixture,
    sha256: 'ef8a36037f5c',
  ),
  'controller.doughnut/pie-offset.js': (
    load: controller_doughnut_pie_offset.fixture,
    sha256: '7068af66954b',
  ),
  'controller.doughnut/doughnut-offset.js': (
    load: controller_doughnut_doughnut_offset.fixture,
    sha256: '57720a497a90',
  ),
  'controller.bar/chart-area-clip.js': (
    load: controller_bar_chart_area_clip.fixture,
    sha256: '2f9db5b62975',
  ),
  'controller.bar/aligned-pixels.js': (
    load: controller_bar_aligned_pixels.fixture,
    sha256: 'ead0a91b2318',
  ),
  'controller.bar/backgroundColor/scriptable.js': (
    load: controller_bar_backgroundcolor_scriptable.fixture,
    sha256: '1d5df66bfb6c',
  ),
  'controller.bar/bar-animation-hide-show.js': (
    load: controller_bar_bar_animation_hide_show.fixture,
    sha256: '54bc5f98f241',
  ),
  'controller.bar/baseLine/bottom.js': (
    load: controller_bar_baseline_bottom.fixture,
    sha256: 'bf7389a85982',
  ),
  'controller.bar/baseLine/left.js': (
    load: controller_bar_baseline_left.fixture,
    sha256: 'a7584d49ea77',
  ),
  'controller.bar/baseLine/mid-x.js': (
    load: controller_bar_baseline_mid_x.fixture,
    sha256: 'eed3533edbc8',
  ),
  'controller.bar/baseLine/mid-y.js': (
    load: controller_bar_baseline_mid_y.fixture,
    sha256: 'cfff83a39b23',
  ),
  'controller.bar/baseLine/right.js': (
    load: controller_bar_baseline_right.fixture,
    sha256: '2127b4082736',
  ),
  'controller.bar/baseLine/top.js': (
    load: controller_bar_baseline_top.fixture,
    sha256: '12562cbfc513',
  ),
  'controller.bar/baseLine/value-x.js': (
    load: controller_bar_baseline_value_x.fixture,
    sha256: '6fad8533fb80',
  ),
  'controller.bar/baseLine/value-y.js': (
    load: controller_bar_baseline_value_y.fixture,
    sha256: 'fdb01c90f0ee',
  ),
  'controller.bar/borderColor/scriptable.js': (
    load: controller_bar_bordercolor_scriptable.fixture,
    sha256: '2a4ef42ba321',
  ),
  'controller.bar/borderRadius/border-radius.js': (
    load: controller_bar_borderradius_border_radius.fixture,
    sha256: '91fac525cd94',
  ),
  'controller.bar/borderSkipped/scriptable.js': (
    load: controller_bar_borderskipped_scriptable.fixture,
    sha256: '6b4cf1ab9ea3',
  ),
  'controller.bar/borderWidth/scriptable-object.js': (
    load: controller_bar_borderwidth_scriptable_object.fixture,
    sha256: 'f73270fb85f3',
  ),
  'controller.bar/borderWidth/scriptable.js': (
    load: controller_bar_borderwidth_scriptable.fixture,
    sha256: '7e6144b33e6b',
  ),
  'controller.bar/data/object-index-axis-y.js': (
    load: controller_bar_data_object_index_axis_y.fixture,
    sha256: 'b335b7fe6d0e',
  ),
  'controller.bar/floatBar/data-as-objects-horizontal.js': (
    load: controller_bar_floatbar_data_as_objects_horizontal.fixture,
    sha256: '1ef1ac1789cd',
  ),
  'controller.bar/floatBar/float-bar-horizontal.json': (
    load: controller_bar_floatbar_float_bar_horizontal.fixture,
    sha256: '4da91e5ed576',
  ),
  'controller.bar/floatBar/float-bar-stacked-horizontal.json': (
    load: controller_bar_floatbar_float_bar_stacked_horizontal.fixture,
    sha256: '478af8960681',
  ),
  'controller.bar/horizontal-borders.js': (
    load: controller_bar_horizontal_borders.fixture,
    sha256: '7fdf894e038c',
  ),
  'controller.bar/minBarLength/horizontal-neg.js': (
    load: controller_bar_minbarlength_horizontal_neg.fixture,
    sha256: '6388b7924f94',
  ),
  'controller.bar/minBarLength/horizontal-pos.js': (
    load: controller_bar_minbarlength_horizontal_pos.fixture,
    sha256: '3ba3f75361f6',
  ),
  'controller.bar/minBarLength/horizontal-stacked-no-overlap.js': (
    load: controller_bar_minbarlength_horizontal_stacked_no_overlap.fixture,
    sha256: '61ba97083fbe',
  ),
  'controller.bar/minBarLength/horizontal-stacked.js': (
    load: controller_bar_minbarlength_horizontal_stacked.fixture,
    sha256: 'b4fbc2aadbcd',
  ),
  'controller.bar/minBarLength/horizontal.js': (
    load: controller_bar_minbarlength_horizontal.fixture,
    sha256: '4b3baef268b0',
  ),
  'controller.bar/minBarLength/vertical.js': (
    load: controller_bar_minbarlength_vertical.fixture,
    sha256: '455703d2c031',
  ),
  'controller.bar/skipNull/bar-skip-null-object-data.js': (
    load: controller_bar_skipnull_bar_skip_null_object_data.fixture,
    sha256: '06288be84fdb',
  ),
  'controller.bar/skipNull/bar-skip-null.js': (
    load: controller_bar_skipnull_bar_skip_null.fixture,
    sha256: '4d1425937c7c',
  ),
  'controller.bar/stacking/issue-9105.js': (
    load: controller_bar_stacking_issue_9105.fixture,
    sha256: 'ce7347a8102d',
  ),
  'controller.bar/stacking/remove-dataset.js': (
    load: controller_bar_stacking_remove_dataset.fixture,
    sha256: '5a6f34ec96c3',
  ),
  'controller.bar/stacking/replace-data.js': (
    load: controller_bar_stacking_replace_data.fixture,
    sha256: '7baadef1b563',
  ),
  'controller.bubble/hover-radius-zero.js': (
    load: controller_bubble_hover_radius_zero.fixture,
    sha256: 'a04b0de742c5',
  ),
  'controller.bubble/padding-update.js': (
    load: controller_bubble_padding_update.fixture,
    sha256: '56bb5560a369',
  ),
  'controller.bubble/point-style.json': (
    load: controller_bubble_point_style.fixture,
    sha256: 'e4839b6d9045',
  ),
  'controller.bubble/radius-data.js': (
    load: controller_bubble_radius_data.fixture,
    sha256: 'd743535961d3',
  ),
  'controller.bubble/radius-scriptable.js': (
    load: controller_bubble_radius_scriptable.fixture,
    sha256: 'c48d604ae872',
  ),
  'controller.doughnut/backgroundColor/scriptable.js': (
    load: controller_doughnut_backgroundcolor_scriptable.fixture,
    sha256: 'f07e553df211',
  ),
  'controller.doughnut/borderAlign/scriptable.js': (
    load: controller_doughnut_borderalign_scriptable.fixture,
    sha256: 'f059fbf7636b',
  ),
  'controller.doughnut/borderColor/scriptable.js': (
    load: controller_doughnut_bordercolor_scriptable.fixture,
    sha256: 'a4f74bc4715a',
  ),
  'controller.doughnut/borderDash/scriptable.js': (
    load: controller_doughnut_borderdash_scriptable.fixture,
    sha256: '2ca3c9d61802',
  ),
  'controller.doughnut/borderRadius/scriptable.js': (
    load: controller_doughnut_borderradius_scriptable.fixture,
    sha256: '47db7edb7d90',
  ),
  'controller.doughnut/borderWidth/scriptable.js': (
    load: controller_doughnut_borderwidth_scriptable.fixture,
    sha256: 'a83ed1209e43',
  ),
  'controller.doughnut/doughnut-NaN.js': (
    load: controller_doughnut_doughnut_nan.fixture,
    sha256: '95af81606f6a',
  ),
  'controller.doughnut/doughnut-animation-hide-last.js': (
    load: controller_doughnut_doughnut_animation_hide_last.fixture,
    sha256: 'c761e7d40fcd',
  ),
  'controller.doughnut/doughnut-animation.js': (
    load: controller_doughnut_doughnut_animation.fixture,
    sha256: '9596716f3ae5',
  ),
  'controller.doughnut/doughnut-full-to-semi.js': (
    load: controller_doughnut_doughnut_full_to_semi.fixture,
    sha256: '14a4452ad83c',
  ),
  'controller.doughnut/doughnut-hidden-single.js': (
    load: controller_doughnut_doughnut_hidden_single.fixture,
    sha256: '5e8d8f50d3e1',
  ),
  'controller.doughnut/doughnut-hidden.js': (
    load: controller_doughnut_doughnut_hidden.fixture,
    sha256: '9bf0028a556b',
  ),
  'controller.doughnut/doughnut-outer-radius-percent.js': (
    load: controller_doughnut_doughnut_outer_radius_percent.fixture,
    sha256: '73d3f8802949',
  ),
  'controller.doughnut/doughnut-outer-radius-pixels.js': (
    load: controller_doughnut_doughnut_outer_radius_pixels.fixture,
    sha256: 'fb490602a898',
  ),
  'controller.doughnut/doughnut-rotation-circumference-8x8.js': (
    load: controller_doughnut_doughnut_rotation_circumference_8x8.fixture,
    sha256: '7e73c0795fe1',
  ),
  'controller.doughnut/doughnut-set-active-elements.js': (
    load: controller_doughnut_doughnut_set_active_elements.fixture,
    sha256: 'e1cc4cca158c',
  ),
  'controller.doughnut/event-replay.js': (
    load: controller_doughnut_event_replay.fixture,
    sha256: 'b60b32f584d9',
  ),
  'controller.line/backgroundColor/scriptable.js': (
    load: controller_line_backgroundcolor_scriptable.fixture,
    sha256: '6b335045acd5',
  ),
  'controller.line/borderCapStyle/scriptable.js': (
    load: controller_line_bordercapstyle_scriptable.fixture,
    sha256: '30478ff89367',
  ),
  'controller.line/borderColor/scriptable.js': (
    load: controller_line_bordercolor_scriptable.fixture,
    sha256: '9a669efd152f',
  ),
  'controller.line/borderDash/scriptable.js': (
    load: controller_line_borderdash_scriptable.fixture,
    sha256: 'c4d800f85779',
  ),
  'controller.line/borderDashOffset/scriptable.js': (
    load: controller_line_borderdashoffset_scriptable.fixture,
    sha256: '4d56a82aa879',
  ),
  'controller.line/borderJoinStyle/scriptable.js': (
    load: controller_line_borderjoinstyle_scriptable.fixture,
    sha256: 'df4607aa4d1a',
  ),
  'controller.line/borderWidth/scriptable.js': (
    load: controller_line_borderwidth_scriptable.fixture,
    sha256: 'd3b61f6f0aa2',
  ),
  'controller.line/clip/false.js': (
    load: controller_line_clip_false.fixture,
    sha256: 'f7987ae35e19',
  ),
  'controller.line/cubicInterpolationMode/scriptable.js': (
    load: controller_line_cubicinterpolationmode_scriptable.fixture,
    sha256: 'ce42a5d3d739',
  ),
  'controller.line/cubicInterpolationMode/value.js': (
    load: controller_line_cubicinterpolationmode_value.fixture,
    sha256: 'fb7f666ae6f0',
  ),
  'controller.line/fill/no-border.js': (
    load: controller_line_fill_no_border.fixture,
    sha256: '2c4c06669722',
  ),
  'controller.line/fill/scriptable.js': (
    load: controller_line_fill_scriptable.fixture,
    sha256: '6a79addf5883',
  ),
  'controller.line/issue-8902.js': (
    load: controller_line_issue_8902.fixture,
    sha256: '748de10df6e0',
  ),
  'controller.line/point-style-offscreen-canvas.json': (
    load: controller_line_point_style_offscreen_canvas.fixture,
    sha256: '1c583297f8d9',
  ),
  'controller.line/point-style.json': (
    load: controller_line_point_style.fixture,
    sha256: 'b660424602f0',
  ),
  'controller.line/pointBackgroundColor/scriptable.js': (
    load: controller_line_pointbackgroundcolor_scriptable.fixture,
    sha256: 'a1d05086a20c',
  ),
  'controller.line/pointBorderColor/scriptable.js': (
    load: controller_line_pointbordercolor_scriptable.fixture,
    sha256: '470ee8700c7c',
  ),
  'controller.line/pointBorderWidth/scriptable.js': (
    load: controller_line_pointborderwidth_scriptable.fixture,
    sha256: '43f2ab05206b',
  ),
  'controller.line/pointStyle/indexable.js': (
    load: controller_line_pointstyle_indexable.fixture,
    sha256: '2af01af5af33',
  ),
  'controller.line/pointStyle/scriptable.js': (
    load: controller_line_pointstyle_scriptable.fixture,
    sha256: '9bcfac10655f',
  ),
  'controller.line/pointStyle/value.js': (
    load: controller_line_pointstyle_value.fixture,
    sha256: '61ce6f0b6cd8',
  ),
  'controller.line/radius/scriptable-to-value.js': (
    load: controller_line_radius_scriptable_to_value.fixture,
    sha256: 'f645b7cc3706',
  ),
  'controller.line/radius/scriptable.js': (
    load: controller_line_radius_scriptable.fixture,
    sha256: '0defd6fe8d7a',
  ),
  'controller.line/rotation/indexable.js': (
    load: controller_line_rotation_indexable.fixture,
    sha256: '526ed66a10e5',
  ),
  'controller.line/rotation/scriptable.js': (
    load: controller_line_rotation_scriptable.fixture,
    sha256: '41944f013e0a',
  ),
  'controller.line/rotation/value.js': (
    load: controller_line_rotation_value.fixture,
    sha256: 'be2f073637a3',
  ),
  'controller.line/segments/gap.js': (
    load: controller_line_segments_gap.fixture,
    sha256: 'be95768577c4',
  ),
  'controller.line/segments/gradient.js': (
    load: controller_line_segments_gradient.fixture,
    sha256: 'e64f9d57138b',
  ),
  'controller.line/segments/range.js': (
    load: controller_line_segments_range.fixture,
    sha256: 'fc55b22345c7',
  ),
  'controller.line/segments/single.js': (
    load: controller_line_segments_single.fixture,
    sha256: 'c5600276f007',
  ),
  'controller.line/segments/slope.js': (
    load: controller_line_segments_slope.fixture,
    sha256: '0d16c2a0c10c',
  ),
  'controller.line/segments/spanGaps.js': (
    load: controller_line_segments_spangaps.fixture,
    sha256: '84de0635c353',
  ),
  'controller.line/stacking/single.js': (
    load: controller_line_stacking_single.fixture,
    sha256: '08e1bf476162',
  ),
  'controller.line/stacking/stack-cache.js': (
    load: controller_line_stacking_stack_cache.fixture,
    sha256: 'e4bff4bd0de9',
  ),
  'controller.line/stacking/updates.js': (
    load: controller_line_stacking_updates.fixture,
    sha256: '056f6b383174',
  ),
  'controller.polarArea/backgroundColor/scriptable-dataset.js': (
    load: controller_polararea_backgroundcolor_scriptable_dataset.fixture,
    sha256: 'e3a6e10b0445',
  ),
  'controller.polarArea/backgroundColor/scriptable-element-options.js': (
    load:
        controller_polararea_backgroundcolor_scriptable_element_options.fixture,
    sha256: '6f4f635ed74f',
  ),
  'controller.polarArea/borderAlign/scriptable-dataset.js': (
    load: controller_polararea_borderalign_scriptable_dataset.fixture,
    sha256: 'c0b710a0a565',
  ),
  'controller.polarArea/borderAlign/scriptable-element-options.js': (
    load: controller_polararea_borderalign_scriptable_element_options.fixture,
    sha256: 'f234f2f7af62',
  ),
  'controller.polarArea/borderColor/scriptable-dataset.js': (
    load: controller_polararea_bordercolor_scriptable_dataset.fixture,
    sha256: 'ded56fe689f2',
  ),
  'controller.polarArea/borderColor/scriptable-element-options.js': (
    load: controller_polararea_bordercolor_scriptable_element_options.fixture,
    sha256: '201e8c5aec6f',
  ),
  'controller.polarArea/borderDash/scriptable.js': (
    load: controller_polararea_borderdash_scriptable.fixture,
    sha256: 'ac0ff1f43b89',
  ),
  'controller.polarArea/borderWidth/scriptable-dataset.js': (
    load: controller_polararea_borderwidth_scriptable_dataset.fixture,
    sha256: '1f2a1caa8279',
  ),
  'controller.polarArea/borderWidth/scriptable-element-options.js': (
    load: controller_polararea_borderwidth_scriptable_element_options.fixture,
    sha256: 'e031e4be7d98',
  ),
  'controller.polarArea/last-slice-animate.js': (
    load: controller_polararea_last_slice_animate.fixture,
    sha256: '3a5f99ab5bd0',
  ),
  'controller.polarArea/pointLabels/overlapping.js': (
    load: controller_polararea_pointlabels_overlapping.fixture,
    sha256: 'd36ed140bae4',
  ),
  'controller.polarArea/polar-area-animation-rotate.js': (
    load: controller_polararea_polar_area_animation_rotate.fixture,
    sha256: '118993e3038a',
  ),
  'controller.polarArea/polar-area-animation-scale.js': (
    load: controller_polararea_polar_area_animation_scale.fixture,
    sha256: '5dc2b7a377f5',
  ),
  'controller.radar/backgroundColor/scriptable.js': (
    load: controller_radar_backgroundcolor_scriptable.fixture,
    sha256: 'f22197417af4',
  ),
  'controller.radar/borderCapStyle/scriptable.js': (
    load: controller_radar_bordercapstyle_scriptable.fixture,
    sha256: '5a54608b60d1',
  ),
  'controller.radar/borderColor/scriptable.js': (
    load: controller_radar_bordercolor_scriptable.fixture,
    sha256: '4c83d879eb43',
  ),
  'controller.radar/borderDash/scriptable.js': (
    load: controller_radar_borderdash_scriptable.fixture,
    sha256: '5d91acf7da68',
  ),
  'controller.radar/borderDashOffset/scriptable.js': (
    load: controller_radar_borderdashoffset_scriptable.fixture,
    sha256: '258285ab5d6a',
  ),
  'controller.radar/borderJoinStyle/scriptable.js': (
    load: controller_radar_borderjoinstyle_scriptable.fixture,
    sha256: '7bf9703db017',
  ),
  'controller.radar/borderWidth/scriptable.js': (
    load: controller_radar_borderwidth_scriptable.fixture,
    sha256: '0e135ebaad8c',
  ),
  'controller.radar/fill/scriptable.js': (
    load: controller_radar_fill_scriptable.fixture,
    sha256: '2e41806f6eec',
  ),
  'controller.radar/point-style.json': (
    load: controller_radar_point_style.fixture,
    sha256: '783139172038',
  ),
  'controller.radar/pointBackgroundColor/scriptable.js': (
    load: controller_radar_pointbackgroundcolor_scriptable.fixture,
    sha256: '8397c25979c5',
  ),
  'controller.radar/pointBorderColor/scriptable.js': (
    load: controller_radar_pointbordercolor_scriptable.fixture,
    sha256: 'a013479b11e7',
  ),
  'controller.radar/pointBorderWidth/scriptable.js': (
    load: controller_radar_pointborderwidth_scriptable.fixture,
    sha256: '3a4626248004',
  ),
  'controller.radar/pointStyle/indexable.js': (
    load: controller_radar_pointstyle_indexable.fixture,
    sha256: 'bcd7f3eeb78b',
  ),
  'controller.radar/pointStyle/scriptable.js': (
    load: controller_radar_pointstyle_scriptable.fixture,
    sha256: '5c91c66e1bc9',
  ),
  'controller.radar/pointStyle/value.js': (
    load: controller_radar_pointstyle_value.fixture,
    sha256: 'bf236ef43caa',
  ),
  'controller.radar/radius/scriptable.js': (
    load: controller_radar_radius_scriptable.fixture,
    sha256: '15fbd64fc078',
  ),
  'controller.radar/rotation/indexable.js': (
    load: controller_radar_rotation_indexable.fixture,
    sha256: 'c986426a9a3e',
  ),
  'controller.radar/rotation/scriptable.js': (
    load: controller_radar_rotation_scriptable.fixture,
    sha256: '1ab97bf9b6b1',
  ),
  'controller.radar/rotation/value.js': (
    load: controller_radar_rotation_value.fixture,
    sha256: '708f548ebe96',
  ),
  'controller.scatter/showLine/changed.js': (
    load: controller_scatter_showline_changed.fixture,
    sha256: '4f29b0a4faa8',
  ),
  'core.interaction/drawActiveElementsOnTop-false.js': (
    load: core_interaction_drawactiveelementsontop_false.fixture,
    sha256: '40e58cf68224',
  ),
  'core.interaction/nearest-partial-bar.js': (
    load: core_interaction_nearest_partial_bar.fixture,
    sha256: '7e8dcdf76bde',
  ),
  'core.interaction/nearest-point-behind-scale.js': (
    load: core_interaction_nearest_point_behind_scale.fixture,
    sha256: '438f249bbf9c',
  ),
  'core.layouts/hidden-vertical-boxes.js': (
    load: core_layouts_hidden_vertical_boxes.fixture,
    sha256: 'a17c3b74bfd2',
  ),
  'core.layouts/scriptable.js': (
    load: core_layouts_scriptable.fixture,
    sha256: '9fea029461b5',
  ),
  'core.scale/cartesian-axis-border-settings.json': (
    load: core_scale_cartesian_axis_border_settings.fixture,
    sha256: 'e777d91ba7f2',
  ),
  'core.scale/crossAlignment/cross-align-left-center.js': (
    load: core_scale_crossalignment_cross_align_left_center.fixture,
    sha256: '011594b9014e',
  ),
  'core.scale/crossAlignment/cross-align-left-far-clipped.js': (
    load: core_scale_crossalignment_cross_align_left_far_clipped.fixture,
    sha256: '8a1237e7e9bd',
  ),
  'core.scale/crossAlignment/cross-align-left-far.js': (
    load: core_scale_crossalignment_cross_align_left_far.fixture,
    sha256: '14ba9d5f1027',
  ),
  'core.scale/crossAlignment/cross-align-left-near.js': (
    load: core_scale_crossalignment_cross_align_left_near.fixture,
    sha256: '4ea6d0827174',
  ),
  'core.scale/crossAlignment/cross-align-right-center.js': (
    load: core_scale_crossalignment_cross_align_right_center.fixture,
    sha256: '4867a1f3c717',
  ),
  'core.scale/crossAlignment/cross-align-right-far-clipped.js': (
    load: core_scale_crossalignment_cross_align_right_far_clipped.fixture,
    sha256: '862e2f9a8fa2',
  ),
  'core.scale/crossAlignment/cross-align-right-far.js': (
    load: core_scale_crossalignment_cross_align_right_far.fixture,
    sha256: 'b15a3433ac9f',
  ),
  'core.scale/crossAlignment/cross-align-right-near.js': (
    load: core_scale_crossalignment_cross_align_right_near.fixture,
    sha256: 'fc4eb1c5e51d',
  ),
  'core.scale/crossAlignment/mirror-cross-align-left-center.js': (
    load: core_scale_crossalignment_mirror_cross_align_left_center.fixture,
    sha256: 'b54e8fad0bd7',
  ),
  'core.scale/crossAlignment/mirror-cross-align-left-far.js': (
    load: core_scale_crossalignment_mirror_cross_align_left_far.fixture,
    sha256: '4b0329cd813e',
  ),
  'core.scale/crossAlignment/mirror-cross-align-left-near.js': (
    load: core_scale_crossalignment_mirror_cross_align_left_near.fixture,
    sha256: '7871be73004a',
  ),
  'core.scale/crossAlignment/mirror-cross-align-right-center.js': (
    load: core_scale_crossalignment_mirror_cross_align_right_center.fixture,
    sha256: 'b3c3e846b673',
  ),
  'core.scale/crossAlignment/mirror-cross-align-right-far.js': (
    load: core_scale_crossalignment_mirror_cross_align_right_far.fixture,
    sha256: '45273c43d3ab',
  ),
  'core.scale/crossAlignment/mirror-cross-align-right-near.js': (
    load: core_scale_crossalignment_mirror_cross_align_right_near.fixture,
    sha256: 'd231166d04c1',
  ),
  'core.scale/grid/scriptable-borderDash.js': (
    load: core_scale_grid_scriptable_borderdash.fixture,
    sha256: 'bfa50f9c0576',
  ),
  'core.scale/label-offset-vertical-axes.json': (
    load: core_scale_label_offset_vertical_axes.fixture,
    sha256: 'de6c83a1cd77',
  ),
  'core.scale/tick-drawing.json': (
    load: core_scale_tick_drawing.fixture,
    sha256: '856a490fea99',
  ),
  'core.scale/tick-override-styles.json': (
    load: core_scale_tick_override_styles.fixture,
    sha256: '8111155a5266',
  ),
  'core.scale/ticks/rotated-long.js': (
    load: core_scale_ticks_rotated_long.fixture,
    sha256: '6033b9c29fa8',
  ),
  'core.scale/ticks/rotated-multi-line.js': (
    load: core_scale_ticks_rotated_multi_line.fixture,
    sha256: '1fe87c10efa3',
  ),
  'core.scale/ticks/skip-by-callback.js': (
    load: core_scale_ticks_skip_by_callback.fixture,
    sha256: 'dd604eb26882',
  ),
  'core.scale/x-axis-position-center.json': (
    load: core_scale_x_axis_position_center.fixture,
    sha256: '2efc414f0f0c',
  ),
  'core.scale/x-axis-position-dynamic.json': (
    load: core_scale_x_axis_position_dynamic.fixture,
    sha256: 'dfcccd0f2cbf',
  ),
  'core.scale/y-axis-position-center.json': (
    load: core_scale_y_axis_position_center.fixture,
    sha256: 'afa1befaf57d',
  ),
  'core.scale/y-axis-position-dynamic.json': (
    load: core_scale_y_axis_position_dynamic.fixture,
    sha256: 'cc576da0a24b',
  ),
  'element.line/cubicInterpolationMode/monotone-horizontal.js': (
    load: element_line_cubicinterpolationmode_monotone_horizontal.fixture,
    sha256: 'e157fe78a7f9',
  ),
  'element.line/cubicInterpolationMode/monotone-vertical.js': (
    load: element_line_cubicinterpolationmode_monotone_vertical.fixture,
    sha256: 'cd7f69c2deb6',
  ),
  'element.line/skip/all.js': (
    load: element_line_skip_all.fixture,
    sha256: 'db37d1922a70',
  ),
  'element.line/skip/first-span.js': (
    load: element_line_skip_first_span.fixture,
    sha256: 'cbf221a845db',
  ),
  'element.line/skip/first.js': (
    load: element_line_skip_first.fixture,
    sha256: 'e45abb146b75',
  ),
  'element.line/skip/last-span.js': (
    load: element_line_skip_last_span.fixture,
    sha256: '6f0121002736',
  ),
  'element.line/skip/last.js': (
    load: element_line_skip_last.fixture,
    sha256: '95674218f4f7',
  ),
  'element.line/skip/middle.js': (
    load: element_line_skip_middle.fixture,
    sha256: 'b018d834ca72',
  ),
  'element.point/point-style-circle.json': (
    load: element_point_point_style_circle.fixture,
    sha256: '7c3e0d406856',
  ),
  'element.point/point-style-cross-rot.json': (
    load: element_point_point_style_cross_rot.fixture,
    sha256: '620578a81b7e',
  ),
  'element.point/point-style-cross.json': (
    load: element_point_point_style_cross.fixture,
    sha256: '22c5a0c2491d',
  ),
  'element.point/point-style-dash.json': (
    load: element_point_point_style_dash.fixture,
    sha256: 'd8137f51627b',
  ),
  'element.point/point-style-image.js': (
    load: element_point_point_style_image.fixture,
    sha256: '637c90745876',
  ),
  'element.point/point-style-line.json': (
    load: element_point_point_style_line.fixture,
    sha256: '342b39396bf7',
  ),
  'element.point/point-style-rect-rot.json': (
    load: element_point_point_style_rect_rot.fixture,
    sha256: '5178013bb8de',
  ),
  'element.point/point-style-rect-rounded.json': (
    load: element_point_point_style_rect_rounded.fixture,
    sha256: '1039b03d8bf5',
  ),
  'element.point/point-style-rect.json': (
    load: element_point_point_style_rect.fixture,
    sha256: '88b8616e4ae3',
  ),
  'element.point/point-style-star.json': (
    load: element_point_point_style_star.fixture,
    sha256: '1dbb903ff31c',
  ),
  'element.point/point-style-triangle.json': (
    load: element_point_point_style_triangle.fixture,
    sha256: 'effb579d156b',
  ),
  'element.point/rotation.js': (
    load: element_point_rotation.fixture,
    sha256: 'ba75d266affa',
  ),
  'mixed/bar+line-stacked.js': (
    load: mixed_bar_line_stacked.fixture,
    sha256: '9bc9ec2e5a3e',
  ),
  'mixed/bar+line.js': (load: mixed_bar_line.fixture, sha256: 'f125d76e617a'),
  'plugin.colors/dynamic-datasets-default.js': (
    load: plugin_colors_dynamic_datasets_default.fixture,
    sha256: 'f855a092e685',
  ),
  'plugin.colors/dynamic-datasets-force-override.js': (
    load: plugin_colors_dynamic_datasets_force_override.fixture,
    sha256: 'f3ad48682a29',
  ),
  'plugin.filler/line/above-below-vertical-linechart.js': (
    load: plugin_filler_line_above_below_vertical_linechart.fixture,
    sha256: 'd57e7980d449',
  ),
  'plugin.filler/line/before-dataset-draw.js': (
    load: plugin_filler_line_before_dataset_draw.fixture,
    sha256: 'f1c3e3ffd23d',
  ),
  'plugin.filler/line/before-datasets-draw.js': (
    load: plugin_filler_line_before_datasets_draw.fixture,
    sha256: '75c315ee70b7',
  ),
  'plugin.filler/line/boundary/above-below-line-null-start.json': (
    load: plugin_filler_line_boundary_above_below_line_null_start.fixture,
    sha256: '056a90d9f162',
  ),
  'plugin.filler/line/boundary/above-below-line-null.json': (
    load: plugin_filler_line_boundary_above_below_line_null.fixture,
    sha256: '5fd8772ba62b',
  ),
  'plugin.filler/line/boundary/origin-spline-above.json': (
    load: plugin_filler_line_boundary_origin_spline_above.fixture,
    sha256: '464229ae7cf8',
  ),
  'plugin.filler/line/boundary/origin-spline-span.json': (
    load: plugin_filler_line_boundary_origin_spline_span.fixture,
    sha256: '0857764d15ef',
  ),
  'plugin.filler/line/boundary/origin-spline.json': (
    load: plugin_filler_line_boundary_origin_spline.fixture,
    sha256: '64f80b7f22d1',
  ),
  'plugin.filler/line/boundary/origin-stepped-span.json': (
    load: plugin_filler_line_boundary_origin_stepped_span.fixture,
    sha256: '3297a1dbfef5',
  ),
  'plugin.filler/line/boundary/origin-stepped.json': (
    load: plugin_filler_line_boundary_origin_stepped.fixture,
    sha256: '1219a3329e87',
  ),
  'plugin.filler/line/dataset/border.json': (
    load: plugin_filler_line_dataset_border.fixture,
    sha256: 'f09a964e16e9',
  ),
  'plugin.filler/line/dataset/clip-bounds-x-off.js': (
    load: plugin_filler_line_dataset_clip_bounds_x_off.fixture,
    sha256: '8836ab53d59c',
  ),
  'plugin.filler/line/dataset/clip-bounds-x.js': (
    load: plugin_filler_line_dataset_clip_bounds_x.fixture,
    sha256: 'bda46a00ed22',
  ),
  'plugin.filler/line/dataset/clip-bounds-y-off.js': (
    load: plugin_filler_line_dataset_clip_bounds_y_off.fixture,
    sha256: 'b5bbf8a1a659',
  ),
  'plugin.filler/line/dataset/clip-bounds-y.js': (
    load: plugin_filler_line_dataset_clip_bounds_y.fixture,
    sha256: '90bfcba6e0f9',
  ),
  'plugin.filler/line/dataset/dual.json': (
    load: plugin_filler_line_dataset_dual.fixture,
    sha256: 'd83b84901d83',
  ),
  'plugin.filler/line/dataset/interpolated.js': (
    load: plugin_filler_line_dataset_interpolated.fixture,
    sha256: '6b037bf196dd',
  ),
  'plugin.filler/line/dataset/no-border.json': (
    load: plugin_filler_line_dataset_no_border.fixture,
    sha256: 'bd4bb11fd06e',
  ),
  'plugin.filler/line/dataset/span-dual.json': (
    load: plugin_filler_line_dataset_span_dual.fixture,
    sha256: 'e3e6ad8a49ac',
  ),
  'plugin.filler/line/dataset/span.json': (
    load: plugin_filler_line_dataset_span.fixture,
    sha256: '86f8063a20bf',
  ),
  'plugin.filler/line/dataset/spline-span-above.json': (
    load: plugin_filler_line_dataset_spline_span_above.fixture,
    sha256: '1a335dcecb56',
  ),
  'plugin.filler/line/dataset/spline-span-below.json': (
    load: plugin_filler_line_dataset_spline_span_below.fixture,
    sha256: '8c509ad6ec22',
  ),
  'plugin.filler/line/dataset/spline-span.json': (
    load: plugin_filler_line_dataset_spline_span.fixture,
    sha256: '0eb077970b95',
  ),
  'plugin.filler/line/dataset/spline.json': (
    load: plugin_filler_line_dataset_spline.fixture,
    sha256: 'ffd7f1b534f6',
  ),
  'plugin.filler/line/dataset/stepped.json': (
    load: plugin_filler_line_dataset_stepped.fixture,
    sha256: 'ccfddf63096b',
  ),
  'plugin.filler/line/points-outside-canvas-update.js': (
    load: plugin_filler_line_points_outside_canvas_update.fixture,
    sha256: 'cff53652abd9',
  ),
  'plugin.filler/line/segments/alignToPixels.js': (
    load: plugin_filler_line_segments_aligntopixels.fixture,
    sha256: '7bafe2061cdb',
  ),
  'plugin.filler/line/segments/gap.js': (
    load: plugin_filler_line_segments_gap.fixture,
    sha256: '7c65b2aa556b',
  ),
  'plugin.filler/line/segments/slope.js': (
    load: plugin_filler_line_segments_slope.fixture,
    sha256: '2c5be7cc3c3d',
  ),
  'plugin.filler/line/vertical.js': (
    load: plugin_filler_line_vertical.fixture,
    sha256: 'ea3de3ba05d4',
  ),
  'plugin.filler/radar/dataset/border.json': (
    load: plugin_filler_radar_dataset_border.fixture,
    sha256: '94b5a3ac3142',
  ),
  'plugin.filler/radar/dataset/default.json': (
    load: plugin_filler_radar_dataset_default.fixture,
    sha256: '7f9fa3d736bc',
  ),
  'plugin.filler/radar/dataset/span.json': (
    load: plugin_filler_radar_dataset_span.fixture,
    sha256: '49fce1b429f2',
  ),
  'plugin.filler/radar/dataset/spline.json': (
    load: plugin_filler_radar_dataset_spline.fixture,
    sha256: 'f9bd42c61ec9',
  ),
  'plugin.legend/borderRadius/legend-border-radius.js': (
    load: plugin_legend_borderradius_legend_border_radius.fixture,
    sha256: '819fb07d37b6',
  ),
  'plugin.legend/horizontal-rtl-hitbox.js': (
    load: plugin_legend_horizontal_rtl_hitbox.fixture,
    sha256: '9936ce127cee',
  ),
  'plugin.legend/legend-doughnut-point-style.json': (
    load: plugin_legend_legend_doughnut_point_style.fixture,
    sha256: '45bf9d8ecf21',
  ),
  'plugin.legend/maxWidth/infinity.js': (
    load: plugin_legend_maxwidth_infinity.fixture,
    sha256: '66c879c203c1',
  ),
  'plugin.legend/padding/add-column.js': (
    load: plugin_legend_padding_add_column.fixture,
    sha256: 'bd23e530172e',
  ),
  'plugin.legend/pointStyle-width/legend-pointStyle-width-default.json': (
    load:
        plugin_legend_pointstyle_width_legend_pointstyle_width_default.fixture,
    sha256: 'd2952260c1a8',
  ),
  'plugin.legend/pointStyle-width/legend-pointStyle-width.json': (
    load: plugin_legend_pointstyle_width_legend_pointstyle_width.fixture,
    sha256: 'b903fe95c19e',
  ),
  'plugin.title/scriptable-options.js': (
    load: plugin_title_scriptable_options.fixture,
    sha256: '2a67dd8b043d',
  ),
  'plugin.tooltip/box-padding.js': (
    load: plugin_tooltip_box_padding.fixture,
    sha256: 'f1046694a16a',
  ),
  'plugin.tooltip/caret-position.js': (
    load: plugin_tooltip_caret_position.fixture,
    sha256: '204d3723a843',
  ),
  'plugin.tooltip/color-box-border-dash.js': (
    load: plugin_tooltip_color_box_border_dash.fixture,
    sha256: 'a13adb1b6eef',
  ),
  'plugin.tooltip/color-box-border-radius.js': (
    load: plugin_tooltip_color_box_border_radius.fixture,
    sha256: '98d9572c8437',
  ),
  'plugin.tooltip/corner-radius.js': (
    load: plugin_tooltip_corner_radius.fixture,
    sha256: '6806969b8ac2',
  ),
  'plugin.tooltip/opacity.js': (
    load: plugin_tooltip_opacity.fixture,
    sha256: '82f95f0a2fd0',
  ),
  'plugin.tooltip/point-style.js': (
    load: plugin_tooltip_point_style.fixture,
    sha256: '4d3b800e358b',
  ),
  'plugin.tooltip/positioning.js': (
    load: plugin_tooltip_positioning.fixture,
    sha256: '9644a47dcf84',
  ),
  'scale.category/invalid-data.js': (
    load: scale_category_invalid_data.fixture,
    sha256: 'ecf9428ec7ed',
  ),
  'scale.category/ticks-from-data.js': (
    load: scale_category_ticks_from_data.fixture,
    sha256: 'fdce887c4022',
  ),
  'scale.linear/grace/grace-10%.js': (
    load: scale_linear_grace_grace_10_.fixture,
    sha256: '0dc72726ef0f',
  ),
  'scale.linear/grace/grace-beginAtZero.js': (
    load: scale_linear_grace_grace_beginatzero.fixture,
    sha256: '5b2a4a7e4b8d',
  ),
  'scale.linear/grace/grace-neg.js': (
    load: scale_linear_grace_grace_neg.fixture,
    sha256: '627ac78c9874',
  ),
  'scale.linear/grace/grace-pos.js': (
    load: scale_linear_grace_grace_pos.fixture,
    sha256: '4df42ffe516b',
  ),
  'scale.linear/grace/grace.js': (
    load: scale_linear_grace_grace.fixture,
    sha256: 'ec3dadb2725a',
  ),
  'scale.linear/grace/issue-8912.js': (
    load: scale_linear_grace_issue_8912.fixture,
    sha256: '187500e243fa',
  ),
  'scale.linear/tick-count-data-limits.js': (
    load: scale_linear_tick_count_data_limits.fixture,
    sha256: 'd9342d4c09c8',
  ),
  'scale.radialLinear/anglelines-scriptable.js': (
    load: scale_radiallinear_anglelines_scriptable.fixture,
    sha256: '08e36231a454',
  ),
  'scale.radialLinear/gridlines-scriptable.js': (
    load: scale_radiallinear_gridlines_scriptable.fixture,
    sha256: '13a35dcc04b0',
  ),
  'scale.radialLinear/pointLabels/scriptable-color-small.js': (
    load: scale_radiallinear_pointlabels_scriptable_color_small.fixture,
    sha256: '00b299f9172d',
  ),
  'scale.radialLinear/ticks-below-zero.js': (
    load: scale_radiallinear_ticks_below_zero.fixture,
    sha256: 'c255b6ba2824',
  ),
  'scale.time/autoskip-major.js': (
    load: scale_time_autoskip_major.fixture,
    sha256: 'b0621b5b41ca',
  ),
  'scale.time/bar-large-gap-between-data.js': (
    load: scale_time_bar_large_gap_between_data.fixture,
    sha256: '64deb58590c8',
  ),
  'scale.time/custom-parser.js': (
    load: scale_time_custom_parser.fixture,
    sha256: '890aed904f37',
  ),
  'scale.time/data-ty.js': (
    load: scale_time_data_ty.fixture,
    sha256: 'cae64c65a083',
  ),
  'scale.time/data-xy.js': (
    load: scale_time_data_xy.fixture,
    sha256: 'f14f7eb1956c',
  ),
  'scale.time/labels-date.js': (
    load: scale_time_labels_date.fixture,
    sha256: '7c9efdf5f808',
  ),
  'scale.time/offset-auto-skip-ticks.js': (
    load: scale_time_offset_auto_skip_ticks.fixture,
    sha256: 'f82acaad46f8',
  ),
  'scale.time/offset-with-no-ticks.js': (
    load: scale_time_offset_with_no_ticks.fixture,
    sha256: '8b06d8cab19e',
  ),
  'scale.timeseries/financial-daily.js': (
    load: scale_timeseries_financial_daily.fixture,
    sha256: 'cd96e74c519b',
  ),
  'controller.bubble/clip.js': (
    load: controller_bubble_clip.fixture,
    sha256: 'c41c15bc92c3',
  ),
  'controller.line/non-numeric-y.json': (
    load: controller_line_non_numeric_y.fixture,
    sha256: '98d3079a8f72',
  ),
  'controller.line/pointBackgroundColor/indexable.js': (
    load: controller_line_pointbackgroundcolor_indexable.fixture,
    sha256: '4e6165c671f4',
  ),
  'controller.line/pointBackgroundColor/value.js': (
    load: controller_line_pointbackgroundcolor_value.fixture,
    sha256: '172cce47e400',
  ),
  'controller.line/pointBorderColor/indexable.js': (
    load: controller_line_pointbordercolor_indexable.fixture,
    sha256: 'e035eaae8d79',
  ),
  'controller.line/pointBorderColor/value.js': (
    load: controller_line_pointbordercolor_value.fixture,
    sha256: '0b6c7b638f62',
  ),
  'controller.line/pointBorderWidth/indexable.js': (
    load: controller_line_pointborderwidth_indexable.fixture,
    sha256: 'db079757f7cf',
  ),
  'controller.line/pointBorderWidth/value.js': (
    load: controller_line_pointborderwidth_value.fixture,
    sha256: '0d634475c832',
  ),
  'controller.line/radius/indexable.js': (
    load: controller_line_radius_indexable.fixture,
    sha256: 'a99264fb9ba2',
  ),
  'controller.line/radius/value.js': (
    load: controller_line_radius_value.fixture,
    sha256: '3c6a12ca99e0',
  ),
  'controller.line/showLine/dataset.js': (
    load: controller_line_showline_dataset.fixture,
    sha256: 'c862fa5f1bed',
  ),
  'controller.line/showLine/false.js': (
    load: controller_line_showline_false.fixture,
    sha256: 'cb7b1512cfcc',
  ),
  'controller.radar/backgroundColor/value.js': (
    load: controller_radar_backgroundcolor_value.fixture,
    sha256: 'a811a3838ef7',
  ),
  'controller.radar/borderColor/value.js': (
    load: controller_radar_bordercolor_value.fixture,
    sha256: '3a09140dbed0',
  ),
  'controller.radar/borderDash/value.js': (
    load: controller_radar_borderdash_value.fixture,
    sha256: '0508684d06e9',
  ),
  'controller.radar/borderWidth/value.js': (
    load: controller_radar_borderwidth_value.fixture,
    sha256: 'fbbcd39a64ed',
  ),
  'controller.radar/borderWidth/zero.js': (
    load: controller_radar_borderwidth_zero.fixture,
    sha256: '5e733e2d4e66',
  ),
  'controller.radar/fill/value.js': (
    load: controller_radar_fill_value.fixture,
    sha256: 'abe43fe26e56',
  ),
  'controller.radar/pointBackgroundColor/indexable.js': (
    load: controller_radar_pointbackgroundcolor_indexable.fixture,
    sha256: 'ab9b4df9fe3c',
  ),
  'controller.radar/pointBackgroundColor/value.js': (
    load: controller_radar_pointbackgroundcolor_value.fixture,
    sha256: 'a31e04268653',
  ),
  'controller.radar/pointBorderColor/indexable.js': (
    load: controller_radar_pointbordercolor_indexable.fixture,
    sha256: 'c3d832027132',
  ),
  'controller.radar/pointBorderColor/value.js': (
    load: controller_radar_pointbordercolor_value.fixture,
    sha256: 'e43b2e05b356',
  ),
  'controller.radar/pointBorderWidth/indexable.js': (
    load: controller_radar_pointborderwidth_indexable.fixture,
    sha256: '475d60b260a4',
  ),
  'controller.radar/pointBorderWidth/value.js': (
    load: controller_radar_pointborderwidth_value.fixture,
    sha256: 'b7b6ebbc3e28',
  ),
  'controller.radar/radius/indexable.js': (
    load: controller_radar_radius_indexable.fixture,
    sha256: 'ab44e9e099c8',
  ),
  'controller.radar/radius/value.js': (
    load: controller_radar_radius_value.fixture,
    sha256: 'b4068839907a',
  ),
  'controller.radar/showLine/value.js': (
    load: controller_radar_showline_value.fixture,
    sha256: '9cb757de6148',
  ),
  'element.line/skip/middle-span.js': (
    load: element_line_skip_middle_span.fixture,
    sha256: '286b611bb77a',
  ),
  'element.line/stepped/after.js': (
    load: element_line_stepped_after.fixture,
    sha256: '4814c2dd8861',
  ),
  'element.line/stepped/before.js': (
    load: element_line_stepped_before.fixture,
    sha256: '53f54cd7cead',
  ),
  'element.line/stepped/default.js': (
    load: element_line_stepped_default.fixture,
    sha256: '19c155a10d08',
  ),
  'element.line/stepped/middle.js': (
    load: element_line_stepped_middle.fixture,
    sha256: '6278d250c29b',
  ),
  'element.line/tension/default.js': (
    load: element_line_tension_default.fixture,
    sha256: '3c43071e0eb7',
  ),
  'element.line/tension/one.js': (
    load: element_line_tension_one.fixture,
    sha256: '9299be5059f9',
  ),
  'element.line/tension/zero.js': (
    load: element_line_tension_zero.fixture,
    sha256: '42c2b3b64ad4',
  ),
  'plugin.filler/line/boundary/end-span.json': (
    load: plugin_filler_line_boundary_end_span.fixture,
    sha256: 'b8d82d21bbed',
  ),
  'plugin.filler/line/boundary/end.json': (
    load: plugin_filler_line_boundary_end.fixture,
    sha256: '8e9560da3312',
  ),
  'plugin.filler/line/boundary/origin-span-dual.json': (
    load: plugin_filler_line_boundary_origin_span_dual.fixture,
    sha256: 'dd7cb6f60abe',
  ),
  'plugin.filler/line/boundary/origin-span.json': (
    load: plugin_filler_line_boundary_origin_span.fixture,
    sha256: '70e44ba3f128',
  ),
  'plugin.filler/line/boundary/origin.json': (
    load: plugin_filler_line_boundary_origin.fixture,
    sha256: 'f543e133289d',
  ),
  'plugin.filler/line/boundary/start-span.json': (
    load: plugin_filler_line_boundary_start_span.fixture,
    sha256: '2eeca87ccb38',
  ),
  'plugin.filler/line/boundary/start.json': (
    load: plugin_filler_line_boundary_start.fixture,
    sha256: '799aeeee22de',
  ),
  'plugin.filler/line/drawTimeFillFalse/beforeDatasetDraw.js': (
    load: plugin_filler_line_drawtimefillfalse_beforedatasetdraw.fixture,
    sha256: 'cdfb18aeb044',
  ),
  'plugin.filler/line/drawTimeFillFalse/beforeDatasetsDraw.js': (
    load: plugin_filler_line_drawtimefillfalse_beforedatasetsdraw.fixture,
    sha256: '63411777b6d5',
  ),
  'plugin.filler/line/drawTimeFillFalse/beforeDraw.js': (
    load: plugin_filler_line_drawtimefillfalse_beforedraw.fixture,
    sha256: '38b68a18e4a4',
  ),
  'plugin.filler/line/offset-scale-minmax.js': (
    load: plugin_filler_line_offset_scale_minmax.fixture,
    sha256: 'd54cf10ad44e',
  ),
  'plugin.filler/line/points-outside-canvas-initial.js': (
    load: plugin_filler_line_points_outside_canvas_initial.fixture,
    sha256: '009594cd8979',
  ),
  'plugin.filler/line/shape.js': (
    load: plugin_filler_line_shape.fixture,
    sha256: '8a625d91544e',
  ),
  'plugin.filler/line/stack-multiple-scales.js': (
    load: plugin_filler_line_stack_multiple_scales.fixture,
    sha256: '635970d68aad',
  ),
  'plugin.filler/line/stack.json': (
    load: plugin_filler_line_stack.fixture,
    sha256: '9c2707f9dd4a',
  ),
  'plugin.filler/line/value.json': (
    load: plugin_filler_line_value.fixture,
    sha256: '434c45f78dea',
  ),
  'plugin.filler/radar/boundary/end-circular.json': (
    load: plugin_filler_radar_boundary_end_circular.fixture,
    sha256: '6e55c212112e',
  ),
  'plugin.filler/radar/boundary/end-span.json': (
    load: plugin_filler_radar_boundary_end_span.fixture,
    sha256: '0cc9ee209f89',
  ),
  'plugin.filler/radar/boundary/end.json': (
    load: plugin_filler_radar_boundary_end.fixture,
    sha256: '38dad6e1b60c',
  ),
  'plugin.filler/radar/boundary/origin-circular.json': (
    load: plugin_filler_radar_boundary_origin_circular.fixture,
    sha256: '6aa5b7a79095',
  ),
  'plugin.filler/radar/boundary/origin-span.json': (
    load: plugin_filler_radar_boundary_origin_span.fixture,
    sha256: '3004e271547a',
  ),
  'plugin.filler/radar/boundary/origin-spline-span.json': (
    load: plugin_filler_radar_boundary_origin_spline_span.fixture,
    sha256: '5915a985a7ba',
  ),
  'plugin.filler/radar/boundary/origin-spline.json': (
    load: plugin_filler_radar_boundary_origin_spline.fixture,
    sha256: '2189102509a3',
  ),
  'plugin.filler/radar/boundary/origin.json': (
    load: plugin_filler_radar_boundary_origin.fixture,
    sha256: '10c3b90a279f',
  ),
  'plugin.filler/radar/boundary/start-circular.json': (
    load: plugin_filler_radar_boundary_start_circular.fixture,
    sha256: '19cf0bd096a1',
  ),
  'plugin.filler/radar/boundary/start-span.json': (
    load: plugin_filler_radar_boundary_start_span.fixture,
    sha256: '6f6639b6e9f0',
  ),
  'plugin.filler/radar/boundary/start.json': (
    load: plugin_filler_radar_boundary_start.fixture,
    sha256: 'f8744ee79db8',
  ),
  'plugin.filler/radar/value.json': (
    load: plugin_filler_radar_value.fixture,
    sha256: 'aaa76214d47d',
  ),
  'scale.logarithmic/large-range.js': (
    load: scale_logarithmic_large_range.fixture,
    sha256: '81c7e3f9081c',
  ),
  'scale.logarithmic/large-values-small-range.js': (
    load: scale_logarithmic_large_values_small_range.fixture,
    sha256: '04df6ffa055d',
  ),
  'scale.logarithmic/med-range.js': (
    load: scale_logarithmic_med_range.fixture,
    sha256: '5bd687bac1bc',
  ),
  'scale.logarithmic/min-max.js': (
    load: scale_logarithmic_min_max.fixture,
    sha256: 'fe9a17c75851',
  ),
  'scale.logarithmic/null-values.js': (
    load: scale_logarithmic_null_values.fixture,
    sha256: '2005172acbb5',
  ),
  'scale.logarithmic/small-range.js': (
    load: scale_logarithmic_small_range.fixture,
    sha256: '3aae77bb8618',
  ),
  'scale.time/negative-times.js': (
    load: scale_time_negative_times.fixture,
    sha256: '86c7641fd3d9',
  ),
  'scale.timeseries/data-timestamps.js': (
    load: scale_timeseries_data_timestamps.fixture,
    sha256: '6f5160d4e038',
  ),
  'core.layouts/stacked-boxes-max-index-without-clip.js': (
    load: core_layouts_stacked_boxes_max_index_without_clip.fixture,
    sha256: '5fd3d94af843',
  ),
  'core.layouts/stacked-boxes-max-index.js': (
    load: core_layouts_stacked_boxes_max_index.fixture,
    sha256: '11ec7a29bd91',
  ),
  'core.layouts/stacked-boxes-max-without-clip.js': (
    load: core_layouts_stacked_boxes_max_without_clip.fixture,
    sha256: 'c60139535633',
  ),
  'core.layouts/stacked-boxes-max.js': (
    load: core_layouts_stacked_boxes_max.fixture,
    sha256: '49fe800eca9e',
  ),
  'core.layouts/stacked-boxes-with-weight.js': (
    load: core_layouts_stacked_boxes_with_weight.fixture,
    sha256: '18b738bc7f49',
  ),
  'core.layouts/stacked-boxes.js': (
    load: core_layouts_stacked_boxes.fixture,
    sha256: '29d14ae0cdd4',
  ),
  'core.scale/border-behind-elements.js': (
    load: core_scale_border_behind_elements.fixture,
    sha256: 'c7bb57a9a680',
  ),
  'core.scale/grid/border-over-grid.js': (
    load: core_scale_grid_border_over_grid.fixture,
    sha256: 'ce9325e1ccf6',
  ),
  'core.scale/grid/colors.js': (
    load: core_scale_grid_colors.fixture,
    sha256: '49074bd4571b',
  ),
  'scale.radialLinear/border-dash.json': (
    load: scale_radiallinear_border_dash.fixture,
    sha256: '9ff3945a6d4f',
  ),
  'scale.radialLinear/circular-border-dash.json': (
    load: scale_radiallinear_circular_border_dash.fixture,
    sha256: '17246932f778',
  ),
};

/// The fixtures that skip, by fixture path (Chart.js ADR 0029, section 9).
///
/// - `'blocked: <module>'`: the upstream observations need a module that is
///   not ported yet. The runner fails a `'blocked: plugin.<id>'` skip as
///   stale when the plugin is registered, and `test:cases` fails a
///   `'blocked: <module>'` skip when each `src/` row of the module in
///   `parity.md` is `ported` (Chart.js ADR 0041, section 8). No entry has
///   this reason now.
/// - `'diverges: adapt-date-moment-format'`: the config parses with a
///   moment format string. `test/port/fixtures/moment_twins_test.dart` runs
///   the pure data configs with the ICU pattern.
const Map<String, String> fixtureSkips = {
  'controller.bar/bar-thickness-absolute.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-flex-offset.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-flex-single-reverse.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-flex-single.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-flex.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-max.json': 'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-min-interval-multi.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-min-interval.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-multiple.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-no-overlap.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-offset.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-per-dataset-stacked.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-per-dataset.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-reverse.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-single-xy.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-single.json':
      'diverges: adapt-date-moment-format',
  'controller.bar/bar-thickness-stacked.json':
      'diverges: adapt-date-moment-format',
  'scale.time/invalid-data.js': 'diverges: adapt-date-moment-format',
  'scale.time/labels.js': 'diverges: adapt-date-moment-format',
  'scale.time/skip-null-gridlines.js': 'diverges: adapt-date-moment-format',
  'scale.time/skip-undefined-gridlines.js':
      'diverges: adapt-date-moment-format',
  'scale.time/source-auto-linear.js': 'diverges: adapt-date-moment-format',
  'scale.time/source-data-linear.js': 'diverges: adapt-date-moment-format',
  'scale.time/source-labels-linear-offset-min-max.js':
      'diverges: adapt-date-moment-format',
  'scale.time/source-labels-linear.js': 'diverges: adapt-date-moment-format',
  'scale.time/ticks-reverse-linear-min-max.js':
      'diverges: adapt-date-moment-format',
  'scale.time/ticks-reverse-linear.js': 'diverges: adapt-date-moment-format',
  'scale.time/ticks-reverse-offset.js': 'diverges: adapt-date-moment-format',
  'scale.time/ticks-reverse.js': 'diverges: adapt-date-moment-format',
  'scale.timeseries/normalize.js': 'diverges: adapt-date-moment-format',
  'scale.timeseries/source-auto.js': 'diverges: adapt-date-moment-format',
  'scale.timeseries/source-data-offset-min-max.js':
      'diverges: adapt-date-moment-format',
  'scale.timeseries/source-data.js': 'diverges: adapt-date-moment-format',
  'scale.timeseries/source-labels-offset-min-max.js':
      'diverges: adapt-date-moment-format',
  'scale.timeseries/source-labels.js': 'diverges: adapt-date-moment-format',
  'scale.timeseries/ticks-reverse-max.js': 'diverges: adapt-date-moment-format',
  'scale.timeseries/ticks-reverse-min-max.js':
      'diverges: adapt-date-moment-format',
  'scale.timeseries/ticks-reverse-min.js': 'diverges: adapt-date-moment-format',
  'scale.timeseries/ticks-reverse.js': 'diverges: adapt-date-moment-format',
};
