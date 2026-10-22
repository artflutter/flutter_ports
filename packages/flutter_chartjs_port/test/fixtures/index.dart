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
import 'hand/controller.bar/borderSkipped/scriptable.dart'
    as controller_bar_borderskipped_scriptable;
import 'hand/controller.bar/borderWidth/scriptable-object.dart'
    as controller_bar_borderwidth_scriptable_object;
import 'hand/controller.bar/borderWidth/scriptable.dart'
    as controller_bar_borderwidth_scriptable;
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
import 'hand/controller.bubble/hover-radius-zero.dart'
    as controller_bubble_hover_radius_zero;
import 'hand/controller.bubble/padding-update.dart'
    as controller_bubble_padding_update;
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
import 'hand/controller.doughnut/doughnut-rotation-circumference-8x8.dart'
    as controller_doughnut_doughnut_rotation_circumference_8x8;
import 'hand/controller.doughnut/doughnut-set-active-elements.dart'
    as controller_doughnut_doughnut_set_active_elements;
import 'hand/controller.doughnut/event-replay.dart'
    as controller_doughnut_event_replay;
import 'hand/controller.line/borderCapStyle/scriptable.dart'
    as controller_line_bordercapstyle_scriptable;
import 'hand/controller.line/borderColor/scriptable.dart'
    as controller_line_bordercolor_scriptable;
import 'hand/controller.line/borderDash/scriptable.dart'
    as controller_line_borderdash_scriptable;
import 'hand/controller.line/borderDashOffset/scriptable.dart'
    as controller_line_borderdashoffset_scriptable;
import 'hand/controller.line/borderJoinStyle/scriptable.dart'
    as controller_line_borderjoinstyle_scriptable;
import 'hand/controller.line/borderWidth/scriptable.dart'
    as controller_line_borderwidth_scriptable;
import 'hand/controller.line/clip/false.dart' as controller_line_clip_false;
import 'hand/controller.line/cubicInterpolationMode/scriptable.dart'
    as controller_line_cubicinterpolationmode_scriptable;
import 'hand/controller.line/issue-8902.dart' as controller_line_issue_8902;
import 'hand/controller.line/pointBackgroundColor/scriptable.dart'
    as controller_line_pointbackgroundcolor_scriptable;
import 'hand/controller.line/pointBorderColor/scriptable.dart'
    as controller_line_pointbordercolor_scriptable;
import 'hand/controller.line/pointBorderWidth/scriptable.dart'
    as controller_line_pointborderwidth_scriptable;
import 'hand/controller.line/pointStyle/scriptable.dart'
    as controller_line_pointstyle_scriptable;
import 'hand/controller.line/radius/scriptable-to-value.dart'
    as controller_line_radius_scriptable_to_value;
import 'hand/controller.line/radius/scriptable.dart'
    as controller_line_radius_scriptable;
import 'hand/controller.line/rotation/scriptable.dart'
    as controller_line_rotation_scriptable;
import 'hand/controller.line/segments/gap.dart' as controller_line_segments_gap;
import 'hand/controller.line/segments/gradient.dart'
    as controller_line_segments_gradient;
import 'hand/controller.line/segments/range.dart'
    as controller_line_segments_range;
import 'hand/controller.line/segments/slope.dart'
    as controller_line_segments_slope;
import 'hand/controller.line/segments/spanGaps.dart'
    as controller_line_segments_spangaps;
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
import 'hand/controller.radar/borderCapStyle/scriptable.dart'
    as controller_radar_bordercapstyle_scriptable;
import 'hand/controller.radar/borderColor/scriptable.dart'
    as controller_radar_bordercolor_scriptable;
import 'hand/controller.radar/borderDash/scriptable.dart'
    as controller_radar_borderdash_scriptable;
import 'hand/controller.radar/borderDashOffset/scriptable.dart'
    as controller_radar_borderdashoffset_scriptable;
import 'hand/controller.radar/borderJoinStyle/scriptable.dart'
    as controller_radar_borderjoinstyle_scriptable;
import 'hand/controller.radar/borderWidth/scriptable.dart'
    as controller_radar_borderwidth_scriptable;
import 'hand/controller.radar/pointBackgroundColor/scriptable.dart'
    as controller_radar_pointbackgroundcolor_scriptable;
import 'hand/controller.radar/pointBorderColor/scriptable.dart'
    as controller_radar_pointbordercolor_scriptable;
import 'hand/controller.radar/pointBorderWidth/scriptable.dart'
    as controller_radar_pointborderwidth_scriptable;
import 'hand/controller.radar/pointStyle/scriptable.dart'
    as controller_radar_pointstyle_scriptable;
import 'hand/controller.radar/radius/scriptable.dart'
    as controller_radar_radius_scriptable;
import 'hand/controller.radar/rotation/scriptable.dart'
    as controller_radar_rotation_scriptable;
import 'hand/controller.scatter/showLine/changed.dart'
    as controller_scatter_showline_changed;
import 'hand/core.layouts/hidden-vertical-boxes.dart'
    as core_layouts_hidden_vertical_boxes;
import 'hand/core.layouts/scriptable.dart' as core_layouts_scriptable;
import 'hand/core.scale/crossAlignment/cross-align-left-far-clipped.dart'
    as core_scale_crossalignment_cross_align_left_far_clipped;
import 'hand/core.scale/crossAlignment/cross-align-right-far-clipped.dart'
    as core_scale_crossalignment_cross_align_right_far_clipped;
import 'hand/core.scale/grid/scriptable-borderDash.dart'
    as core_scale_grid_scriptable_borderdash;
import 'hand/core.scale/ticks/rotated-long.dart'
    as core_scale_ticks_rotated_long;
import 'hand/core.scale/ticks/rotated-multi-line.dart'
    as core_scale_ticks_rotated_multi_line;
import 'hand/core.scale/ticks/skip-by-callback.dart'
    as core_scale_ticks_skip_by_callback;
import 'hand/element.line/skip/all.dart' as element_line_skip_all;
import 'hand/element.line/skip/first-span.dart' as element_line_skip_first_span;
import 'hand/element.line/skip/first.dart' as element_line_skip_first;
import 'hand/element.line/skip/last-span.dart' as element_line_skip_last_span;
import 'hand/element.line/skip/last.dart' as element_line_skip_last;
import 'hand/element.line/skip/middle.dart' as element_line_skip_middle;
import 'hand/element.point/point-style-image.dart'
    as element_point_point_style_image;
import 'hand/element.point/rotation.dart' as element_point_rotation;
import 'hand/scale.category/invalid-data.dart' as scale_category_invalid_data;
import 'hand/scale.linear/tick-count-data-limits.dart'
    as scale_linear_tick_count_data_limits;
import 'hand/scale.radialLinear/anglelines-scriptable.dart'
    as scale_radiallinear_anglelines_scriptable;
import 'hand/scale.radialLinear/gridlines-scriptable.dart'
    as scale_radiallinear_gridlines_scriptable;
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
import 'hand/scale.time/offset-with-no-ticks.dart'
    as scale_time_offset_with_no_ticks;
import 'hand/scale.timeseries/financial-daily.dart'
    as scale_timeseries_financial_daily;

/// `jasmine.fixture.specs(path)` of Chart.js `test/index.js:15-17`.
void Function() specs(String path) =>
    specsFromFixtures(path, hand: handFixtures, skips: fixtureSkips);

/// The hand-ported configs by fixture path (Chart.js ADR 0029, section 5).
///
/// Each entry maps the path relative to `test/fixtures/` to the `fixture`
/// function of `hand/<path>.dart` and the first 12 hex digits of the
/// `sha256` of the upstream file in `doc/upstream/manifest.json`.
final Map<String, HandFixture> handFixtures = {
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
  'controller.line/issue-8902.js': (
    load: controller_line_issue_8902.fixture,
    sha256: '748de10df6e0',
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
  'controller.line/pointStyle/scriptable.js': (
    load: controller_line_pointstyle_scriptable.fixture,
    sha256: '9bcfac10655f',
  ),
  'controller.line/radius/scriptable-to-value.js': (
    load: controller_line_radius_scriptable_to_value.fixture,
    sha256: 'f645b7cc3706',
  ),
  'controller.line/radius/scriptable.js': (
    load: controller_line_radius_scriptable.fixture,
    sha256: '0defd6fe8d7a',
  ),
  'controller.line/rotation/scriptable.js': (
    load: controller_line_rotation_scriptable.fixture,
    sha256: '41944f013e0a',
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
  'controller.line/segments/slope.js': (
    load: controller_line_segments_slope.fixture,
    sha256: '0d16c2a0c10c',
  ),
  'controller.line/segments/spanGaps.js': (
    load: controller_line_segments_spangaps.fixture,
    sha256: '84de0635c353',
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
  'controller.radar/pointStyle/scriptable.js': (
    load: controller_radar_pointstyle_scriptable.fixture,
    sha256: '5c91c66e1bc9',
  ),
  'controller.radar/radius/scriptable.js': (
    load: controller_radar_radius_scriptable.fixture,
    sha256: '15fbd64fc078',
  ),
  'controller.radar/rotation/scriptable.js': (
    load: controller_radar_rotation_scriptable.fixture,
    sha256: '1ab97bf9b6b1',
  ),
  'controller.scatter/showLine/changed.js': (
    load: controller_scatter_showline_changed.fixture,
    sha256: '4f29b0a4faa8',
  ),
  'core.layouts/hidden-vertical-boxes.js': (
    load: core_layouts_hidden_vertical_boxes.fixture,
    sha256: 'a17c3b74bfd2',
  ),
  'core.layouts/scriptable.js': (
    load: core_layouts_scriptable.fixture,
    sha256: '9fea029461b5',
  ),
  'core.scale/crossAlignment/cross-align-left-far-clipped.js': (
    load: core_scale_crossalignment_cross_align_left_far_clipped.fixture,
    sha256: '8a1237e7e9bd',
  ),
  'core.scale/crossAlignment/cross-align-right-far-clipped.js': (
    load: core_scale_crossalignment_cross_align_right_far_clipped.fixture,
    sha256: '862e2f9a8fa2',
  ),
  'core.scale/grid/scriptable-borderDash.js': (
    load: core_scale_grid_scriptable_borderdash.fixture,
    sha256: 'bfa50f9c0576',
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
  'element.point/point-style-image.js': (
    load: element_point_point_style_image.fixture,
    sha256: '637c90745876',
  ),
  'element.point/rotation.js': (
    load: element_point_rotation.fixture,
    sha256: 'ba75d266affa',
  ),
  'scale.category/invalid-data.js': (
    load: scale_category_invalid_data.fixture,
    sha256: 'ecf9428ec7ed',
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
  'scale.time/offset-with-no-ticks.js': (
    load: scale_time_offset_with_no_ticks.fixture,
    sha256: '8b06d8cab19e',
  ),
  'scale.timeseries/financial-daily.js': (
    load: scale_timeseries_financial_daily.fixture,
    sha256: 'cd96e74c519b',
  ),
};

/// The fixtures that skip, by fixture path (Chart.js ADR 0029, section 9).
///
/// - `'blocked: plugin.<id>'`: the upstream observations need the plugin of
///   phase 8. The runner fails such a skip as stale when the plugin is
///   registered.
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
  'controller.line/backgroundColor/scriptable.js': 'blocked: plugin.filler',
  'controller.line/backgroundColor/value.js': 'blocked: plugin.filler',
  'controller.line/fill/no-border.js': 'blocked: plugin.filler',
  'controller.line/fill/order-default.js': 'blocked: plugin.filler',
  'controller.line/fill/order.js': 'blocked: plugin.filler',
  'controller.line/fill/scriptable.js': 'blocked: plugin.filler',
  'controller.line/fill/value.js': 'blocked: plugin.filler',
  'controller.line/showLine/false.js': 'blocked: plugin.filler',
  'controller.line/stacking/order-default.js': 'blocked: plugin.filler',
  'controller.line/stacking/order-specified.js': 'blocked: plugin.filler',
  'controller.line/stacking/single.js': 'blocked: plugin.filler',
  'controller.polarArea/pointLabels/withTitle/bottom-centered-45.js':
      'blocked: plugin.title',
  'controller.polarArea/pointLabels/withTitle/bottom-centered.js':
      'blocked: plugin.title',
  'controller.polarArea/pointLabels/withTitle/left-centered-45.js':
      'blocked: plugin.title',
  'controller.polarArea/pointLabels/withTitle/left-centered.js':
      'blocked: plugin.title',
  'controller.polarArea/pointLabels/withTitle/right-centered-45.js':
      'blocked: plugin.title',
  'controller.polarArea/pointLabels/withTitle/right-centered.js':
      'blocked: plugin.title',
  'controller.polarArea/pointLabels/withTitle/top-centered-45.js':
      'blocked: plugin.title',
  'controller.polarArea/pointLabels/withTitle/top-centered.js':
      'blocked: plugin.title',
  'controller.polarArea/pointLabels/withTitle/top-default-45.js':
      'blocked: plugin.title',
  'controller.polarArea/pointLabels/withTitle/top-default.js':
      'blocked: plugin.title',
  'controller.radar/backgroundColor/scriptable.js': 'blocked: plugin.filler',
  'controller.radar/backgroundColor/value.js': 'blocked: plugin.filler',
  'controller.radar/fill/scriptable.js': 'blocked: plugin.filler',
  'controller.radar/fill/value.js': 'blocked: plugin.filler',
  'controller.radar/showLine/value.js': 'blocked: plugin.filler',
  'core.interaction/drawActiveElementsOnTop-false.js':
      'blocked: plugin.subtitle',
  'core.interaction/nearest-partial-bar.js': 'blocked: plugin.tooltip',
  'core.interaction/nearest-point-behind-scale.js': 'blocked: plugin.tooltip',
  'core.layouts/refit-vertical-boxes.js': 'blocked: plugin.legend',
  'scale.radialLinear/gridlines-no-z.json': 'blocked: plugin.filler',
  'scale.radialLinear/gridlines-z.json': 'blocked: plugin.filler',
  'scale.time/invalid-data.js': 'diverges: adapt-date-moment-format',
  'scale.time/labels.js': 'diverges: adapt-date-moment-format',
  'scale.time/negative-times.js': 'blocked: plugin.filler',
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
