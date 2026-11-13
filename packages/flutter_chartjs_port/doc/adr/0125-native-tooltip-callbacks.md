# Chart.js ADR 0125: Native TooltipCallbacks

- Status: accepted (2026-11-13): native and browser tests, specs, fixtures, analysis and port checks pass.
- Date: 2026-11-12
- Revised: 2026-11-13

One immutable object holds the 14 upstream callbacks. Text hooks return `List<String>?`; style hooks return their
native result type or null. Null means the built-in default, and an empty text list means no output.

## Full types

Declarations use [Dart primary constructors](https://dart.dev/language/primary-constructors), supported from Dart 3.13.

The existing `ChartTooltipItem` view is promoted into the core. The contract below describes its native getters. Its implementation reuses
the existing tooltip item; it does not copy user data or introduce another item model. Extend `TypedTooltipItem` with
its existing implementation's `element` field as part of that move. The tooltip argument is the existing core model.

`ChartPaint` is a shared paint-value type in the core color library, first consumed here. It contains data only.

```dart
import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/src/helpers/point_style.dart' show PointStyle;
import 'package:flutter_chartjs_port/src/types/color.dart'
    show CanvasGradient, CanvasPattern;
import 'package:flutter_chartjs_port/src/types/index.dart' as core;

final class const TooltipCallbacks({
  final TooltipItemsCallback? beforeTitle,
  final TooltipItemsCallback? title,
  final TooltipItemsCallback? afterTitle,
  final TooltipItemsCallback? beforeBody,
  final TooltipItemsCallback? afterBody,
  final TooltipItemCallback<List<String>>? beforeLabel,
  final TooltipItemCallback<List<String>>? label,
  final TooltipItemCallback<List<String>>? afterLabel,
  final TooltipItemsCallback? beforeFooter,
  final TooltipItemsCallback? footer,
  final TooltipItemsCallback? afterFooter,
  final TooltipItemCallback<TooltipLabelStyle>? labelColor,
  final TooltipItemCallback<ChartPaint>? labelTextColor,
  final TooltipItemCallback<TooltipLabelPointStyle>? labelPointStyle,
}) {
  // Supplied fields replace base fields; null fields inherit them.
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

typedef TooltipItemsCallback = List<String>? Function(
  core.TooltipModel tooltip,
  List<ChartTooltipItem> items,
);

typedef TooltipItemCallback<T> = T? Function(
  core.TooltipModel tooltip,
  ChartTooltipItem item,
);

// The promoted existing view's contract, not a new stored item object.
abstract interface class ChartTooltipItem {
  core.Chart get chart;
  core.Element get element;
  int get datasetIndex;
  int get dataIndex;
  String get formattedValue;
  String? get datasetLabel;

  // User-owned data remains open and keeps its identity.
  Object? get label;
  Object? get raw;
  Object? get parsed;
  Object? get dataset;
}

// The renderer interprets these values; they cannot mutate canvas state.
sealed class const ChartPaint() {
  const factory ChartPaint.solid(Color color) = SolidChartPaint;
  const factory ChartPaint.gradient(CanvasGradient gradient) = GradientChartPaint;
  const factory ChartPaint.pattern(CanvasPattern pattern) = PatternChartPaint;
  const factory ChartPaint.unchanged() = UnchangedChartPaint;
}

final class const SolidChartPaint(final Color color) extends ChartPaint;

final class const GradientChartPaint(final CanvasGradient gradient)
    extends ChartPaint;

final class const PatternChartPaint(final CanvasPattern pattern)
    extends ChartPaint;

final class const UnchangedChartPaint() extends ChartPaint;

final class const TooltipCornerRadii({
  final double topLeft = 0,
  final double topRight = 0,
  final double bottomRight = 0,
  final double bottomLeft = 0,
}) {
  const TooltipCornerRadii.all(double radius)
      : this(
          topLeft: radius,
          topRight: radius,
          bottomRight: radius,
          bottomLeft: radius,
        );
}

final class TooltipLabelStyle({
  final ChartPaint borderColor = const ChartPaint.unchanged(),
  final ChartPaint backgroundColor = const ChartPaint.unchanged(),
  final double borderWidth = 1,
  List<double> borderDash = const [],
  final double borderDashOffset = 0,
  final TooltipCornerRadii borderRadius = const TooltipCornerRadii(),
}) {
  final List<double> borderDash = List<double>.unmodifiable(borderDash);
}

final class const TooltipLabelPointStyle._(
  final PointStyle? pointStyle,
  final double rotation,
) {
  const TooltipLabelPointStyle.draw(PointStyle pointStyle, {double rotation = 0})
      : this._(pointStyle, rotation);
  const TooltipLabelPointStyle.hidden() : this._(null, 0);
}

```

No result wrapper, text wrapper, extra context wrapper, or third item model is introduced. `TooltipLabelStyle` and
`TooltipLabelPointStyle` evolve the existing result records; do not keep duplicate public versions alongside them.
The existing tooltip model and user-data fields are outside this object's static-typing claim.

## Use and composition

Usage:

```dart
final base = TooltipCallbacks(
  title: (tooltip, items) => ['Selected: ${items.length}'],
  label: (tooltip, item) => [item.formattedValue],
);

final callbacks = base.merge(
  TooltipCallbacks(
    afterLabel: (tooltip, item) => [], // No extra text.
    label: (tooltip, item) => null, // Use the built-in label, not base.label.
  ),
);

final tooltip = ChartTooltip(callbacks: callbacks);

// Raw configs hold the same native object.
final options = <String, Object?>{
  'plugins': <String, Object?>{
    'tooltip': <String, Object?>{'callbacks': callbacks},
  },
};
```

Each typed dataset gains `tooltipCallbacks`; raw datasets use `dataset.tooltip.callbacks`. Dataset selection uses only
`beforeLabel`, `label`, `afterLabel`, `labelColor`, `labelTextColor`, and `labelPointStyle`.

Like [Flutter’s TextStyle.merge](https://api.flutter.dev/flutter/painting/TextStyle/merge.html), `merge(null)` returns
the receiver and non-null fields of the supplied object win. A null field inherits; it does not erase a base callback.
To request the built-in default, supply a callback returning null. To remove an own callback entirely, replace the configuration object with one that omits it.

## Fit to upstream

| Chart.js v4.6.1 | Proposed Dart |
| --- | --- |
| `options.plugins.tooltip.callbacks` with 14 named hooks | Same path and names; one `TooltipCallbacks` value |
| Callback `this` is the tooltip | First argument is the same tooltip model |
| Missing callback inherits | Null callback field inherits |
| Returning `undefined` invokes the built-in default | Returning null invokes the built-in default |
| Returning null, an empty string, or an empty array suppresses text | Returning `[]` suppresses text |
| Returning a string or string array | Returning `List<String>` |
| Dataset overrides six per-item hooks | Same six hooks; dataset title/footer callbacks are ignored |

Preserve the module layout, default callback logic, invocation order, item order and identity. A dataset callback that
returns null invokes the **built-in** callback directly; it does not fall through to a chart-level custom callback.
Built-in no-op callbacks finish with empty output, without recursive fallback.

The intentional text API break is normalization: every supplied list entry is one line. The callback layer performs no
automatic newline splitting. Callers split strings when they want multiple lines. Built-in defaults and migrated
fixtures must produce lists that preserve their existing drawing and geometry. Numeric values in observable tooltip
text may become strings; the original label/raw/parsed values on the item remain unchanged.

`merge` composes immutable values at configuration time. It does not authorize caching a stale callback snapshot for
an entire update. Runtime selection must preserve resolver/update visibility and reentrant behavior at invocation
boundaries. Typed closure replacement must still reach the newest callback without an unnecessary chart update;
raw configs keep their explicit update lifecycle. Pin these rules with traces during implementation.

## Paint, styles and extension points

- `ChartPaint` is a closed data union of supported renderer values. Plugins supply supported Color, gradient or pattern
  values through callbacks; there are no `applyFill`/`applyStroke` methods and no extra drawing hooks hidden in a color.
  Supporting a new renderer paint kind requires an explicit renderer change.
- `PointStyle` stays open for custom marker drawing. The promoted item view remains an open contract. Callback
  containers and style values are final; plugins customize function fields and compose sets with `merge`.
- `ChartPaint.unchanged()` keeps the current canvas paint. It differs from callback null, which requests the built-in
  default, and from a transparent solid Color.
- Tooltip boxes use one effective border width. The built-in producer computes the same effective width as the current
  renderer, including the existing scalar-zero fallback and maximum of edge widths. Custom native styles specify the
  exact width: zero means no border. Four scalar corner radii remain supported; no implicit elliptical corners.
- A returned `TooltipLabelPointStyle.hidden()` suppresses the marker. Returning null requests the built-in marker.

## Beta migration and implementation

Remove `titleText`, `labelText`, `footerText`, callback Maps, callback-specific `JsFunction` wrappers and
`TooltipCallbacksScope`. There is no compatibility dispatch path. Native `extra.callbacks` merges over the explicit typed
object using the same non-null-field precedence. Callback containers and style results are replaced rather than mutated by name. Plugin registration and
lifecycle hooks are unchanged.

1. Promote the existing item view and add these callback/style types in core-accessible libraries.
2. Add the native callbacks schema atom and field-wise composition at chart and dataset boundaries.
3. Migrate all 14 built-in callbacks and call sites to typed fields and direct calls; normalize text/style results once
   at their producers. Keep upstream functions recognizable for future bumps.
4. Expose the single chart/dataset callback API with live typed bindings; remove the superseded paths and migrate
   examples, fixtures, references, exports and documentation.
5. Verify inheritance versus fallback, empty output, dataset precedence, line handling, styles, identity, replacement
   and reentrancy. Run native/web suites, fixtures, upstream cases, public API and port checks; measure tooltip/hover
   performance rather than assuming a speedup.

The completed callback selection/invocation path has no string/OptionKey dispatch, `jsCall*`, by-name callback lookup,
or callback-specific `JsFunction` bridge. Dynamic operations at unrelated user-data boundaries remain explicit.

Sources: pinned Chart.js v4.6.1 `src/types/index.d.ts:2620-2768,2978-3023` and
`src/plugins/plugin.tooltip.js:94-120,344-455,533-639,789-854`; current `lib/src/plugins/plugin.tooltip.dart`,
`lib/src/typed/callbacks.dart`, `tool/options_schema.yaml`, and `lib/src/typed/lower.dart`.
