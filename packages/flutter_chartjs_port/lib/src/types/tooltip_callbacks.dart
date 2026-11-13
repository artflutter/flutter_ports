// Original code, not ported from Chart.js: native tooltip callback objects.

/// Native callbacks and result values (Chart.js ADR 0125).
library;

import 'package:flutter_chartjs_port/src/helpers/point_style.dart'
    show PointStyle;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart' show Undefined;
import 'package:flutter_chartjs_port/src/types/chart_paint.dart';
import 'package:flutter_chartjs_port/src/types/chart_tooltip_item.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart' show TRBLCorners;
import 'package:flutter_chartjs_port/src/types/index.dart' as core;
import 'package:meta/meta.dart' show internal;

/// The 14 tooltip hooks. An absent field inherits the corresponding hook.
/// A null callback result selects its built-in default; an empty text list
/// emits no lines. Raw and typed configurations use this same value.
final class const TooltipCallbacks({
  /// The `beforeTitle` hook; null inherits it.
  final TooltipItemsCallback? beforeTitle,

  /// The `title` hook; null inherits it.
  final TooltipItemsCallback? title,

  /// The `afterTitle` hook; null inherits it.
  final TooltipItemsCallback? afterTitle,

  /// The `beforeBody` hook; null inherits it.
  final TooltipItemsCallback? beforeBody,

  /// The `afterBody` hook; null inherits it.
  final TooltipItemsCallback? afterBody,

  /// The `beforeLabel` hook; null inherits it.
  final TooltipItemCallback<List<String>>? beforeLabel,

  /// The `label` hook; null inherits it.
  final TooltipItemCallback<List<String>>? label,

  /// The `afterLabel` hook; null inherits it.
  final TooltipItemCallback<List<String>>? afterLabel,

  /// The `beforeFooter` hook; null inherits it.
  final TooltipItemsCallback? beforeFooter,

  /// The `footer` hook; null inherits it.
  final TooltipItemsCallback? footer,

  /// The `afterFooter` hook; null inherits it.
  final TooltipItemsCallback? afterFooter,

  /// The `labelColor` hook; null inherits it.
  final TooltipItemCallback<TooltipLabelStyle>? labelColor,

  /// The `labelTextColor` hook; null inherits it.
  final TooltipItemCallback<ChartPaint>? labelTextColor,

  /// The `labelPointStyle` hook; null inherits it.
  final TooltipItemCallback<TooltipLabelPointStyle>? labelPointStyle,
}) {
  /// Creates a set of native callback overrides.
  this;

  /// Supplied fields replace base fields; null fields inherit them.
  TooltipCallbacks merge(TooltipCallbacks? other) {
    if (other == null) return this;
    return TooltipCallbacks(
      beforeTitle: other.beforeTitle ?? beforeTitle,
      title: other.title ?? title,
      afterTitle: other.afterTitle ?? afterTitle,
      beforeBody: other.beforeBody ?? beforeBody,
      afterBody: other.afterBody ?? afterBody,
      beforeLabel: other.beforeLabel ?? beforeLabel,
      label: other.label ?? label,
      afterLabel: other.afterLabel ?? afterLabel,
      beforeFooter: other.beforeFooter ?? beforeFooter,
      footer: other.footer ?? footer,
      afterFooter: other.afterFooter ?? afterFooter,
      labelColor: other.labelColor ?? labelColor,
      labelTextColor: other.labelTextColor ?? labelTextColor,
      labelPointStyle: other.labelPointStyle ?? labelPointStyle,
    );
  }
}

/// Internal reconciliation metadata; callback bodies are read live by lowering.
@internal
int? tooltipCallbacksPresence(TooltipCallbacks? callbacks) => callbacks == null
    ? null
    : (callbacks.beforeTitle == null ? 0 : 1) |
          (callbacks.title == null ? 0 : 2) |
          (callbacks.afterTitle == null ? 0 : 4) |
          (callbacks.beforeBody == null ? 0 : 8) |
          (callbacks.afterBody == null ? 0 : 16) |
          (callbacks.beforeLabel == null ? 0 : 32) |
          (callbacks.label == null ? 0 : 64) |
          (callbacks.afterLabel == null ? 0 : 128) |
          (callbacks.beforeFooter == null ? 0 : 256) |
          (callbacks.footer == null ? 0 : 512) |
          (callbacks.afterFooter == null ? 0 : 1024) |
          (callbacks.labelColor == null ? 0 : 2048) |
          (callbacks.labelTextColor == null ? 0 : 4096) |
          (callbacks.labelPointStyle == null ? 0 : 8192);

/// The native option boundary, with no callback-Map compatibility path.
@internal
TooltipCallbacks tooltipCallbacksOf(Object? value) {
  if (value is TooltipCallbacks) return value;
  assert(
    value == null || value is Undefined,
    'Tooltip callbacks hold a TooltipCallbacks, not $value.',
  );
  return const TooltipCallbacks();
}

/// A text hook over the ordered items, with the tooltip as explicit context.
typedef TooltipItemsCallback = List<String>? Function(
  core.TooltipModel tooltip,
  List<ChartTooltipItem> items,
);

/// A per-item hook. A null result requests the built-in callback.
typedef TooltipItemCallback<T> = T? Function(
  core.TooltipModel tooltip,
  ChartTooltipItem item,
);

/// The four scalar radii of a tooltip label box.
final class const TooltipCornerRadii({
  /// The `topLeft` corner radius in pixels.
  @override final double topLeft = 0,

  /// The `topRight` corner radius in pixels.
  @override final double topRight = 0,

  /// The `bottomRight` corner radius in pixels.
  @override final double bottomRight = 0,

  /// The `bottomLeft` corner radius in pixels.
  @override final double bottomLeft = 0,
}) implements TRBLCorners {
  /// Creates the four corner radii.
  this;

  /// The same radius for each corner.
  const new all(double radius)
    : this(
        topLeft: radius,
        topRight: radius,
        bottomRight: radius,
        bottomLeft: radius,
      );
}

/// The resolved native style returned by `labelColor`.
final class TooltipLabelStyle({
  /// The border paint; unchanged inherits the resolved item paint.
  final ChartPaint borderColor = const ChartPaint.unchanged(),

  /// The box fill; unchanged inherits the resolved item paint.
  final ChartPaint backgroundColor = const ChartPaint.unchanged(),

  /// The effective border width; zero draws no border.
  final double borderWidth = 1,
  List<double> borderDash = const [],

  /// The dash offset in pixels.
  final double borderDashOffset = 0,

  /// The four corner radii.
  final TooltipCornerRadii borderRadius = const TooltipCornerRadii(),
}) {
  /// Creates a label style, copying the supplied dash pattern.
  this;

  /// An immutable copy of the dash pattern.
  final List<double> borderDash = List<double>.unmodifiable(borderDash);
}

/// A point marker and its rotation, or an explicitly hidden marker.
final class const TooltipLabelPointStyle._(
  /// The native marker, or null when hidden.
  final PointStyle? pointStyle,

  /// The marker rotation in degrees.
  final double rotation,
) {
  /// Draws the native marker with the given rotation.
  const new draw(PointStyle pointStyle, {double rotation = 0})
    : this._(pointStyle, rotation);

  /// Suppresses the point marker.
  const new hidden() : this._(null, 0);
}
