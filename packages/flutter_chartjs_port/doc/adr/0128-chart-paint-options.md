# Chart.js ADR 0128: ChartPaint from options to canvas

- Status: accepted (2026-11-13): native/browser tests, fixtures, analysis and port checks pass.
- Superseded in part by: [Chart.js ADR 0147](0147-public-theme-api.md) (2026-11-14)
- Date: 2026-11-13
- Supersedes: the direct option-color representation of Chart.js ADRs 0057 and 0061, and the gradient and
  pattern wrappers of Chart.js ADR 0125 (section Decision).

## Decision

Every paint-capable color option holds `ChartPaint` from its source through
resolution to the canvas. A solid paint contains a Flutter `Color`; a
`ChartGradient` or `ChartPattern` is itself a paint. No reader wraps a color
and no drawing helper unwraps a paint. The canvas interprets the variant.
An absent optional paint retains the existing style through `ChartPaint.unchanged()`.

```dart
const paint = ChartPaint.solid(Color(0xFF008080));
const gradient = ChartGradient.linear(
  Offset.zero, Offset(0, 200), [Color(0xFF008080), Color(0x00008080)],
);
final pattern = ChartPattern(image, tileModeY: TileMode.decal);
```

The gradient constructors replace `createLinearGradient`,
`createRadialGradient`, `createConicGradient` and `addColorStop`.
`ChartPattern` replaces `createPattern`, with Flutter tile modes instead of
browser repetition strings. Gradients use the user space of each draw.
The renderer caches shaders by paint identity, transform and list contents;
a failed build never enters the cache. Stops are finite, ordered and within
`[0, 1]`. Gradient stops and shadow colors remain Flutter `Color` values.

Theme tokens and palette entries remain `Color`. Theme compilation and the
colors plugin create solid paints when they write paint options. Hover and
animation unwrap solids only for numerical channel arithmetic and return
solid paints. Gradients and patterns retain the upstream non-interpolated
behavior. Solid paint equality uses the underlying Flutter color, preserving
color space and channel precision.

## Dataset forms

The pinned `LineControllerDatasetOptions` applies
`ScriptableAndArrayOptions` both to `PointPrefixedOptions` and to
`CommonElementOptions` (`src/types/index.d.ts:189-196`). Our previous typed
API exposed only constants for the point-specific and hover colors. All
eight dataset fields now use `ChartValue<ChartPaint>?`: background, border,
hover background/border, point background/border, and point hover
background/border.

```dart
LineDataset(
  data: [1, 2, 3],
  borderColor: .constant(.solid(teal)),
  pointBackgroundColor: .indexed([.solid(teal), gradient]),
  pointHoverBackgroundColor: .resolver((context) =>
    context.dataIndex == 0 ? gradient : ChartPaint.solid(teal)),
)
```

The same variants apply to LineDataset, ScatterDataset and RadarDataset
point fields. Lowering retains `OptValue`, `OptList` or `OptFunction` without
calling user callbacks. Omission inherits; `copyWith(null)` retains the
existing value. Indexed lists repeat by index, and active resolution uses
the corresponding hover option. Element-style, text and scale fields take
`ChartPaint` directly where their existing typed API exposes a scalar.

Raw configurations keep their value/list/function forms, with `ChartPaint`
leaves. Static configuration validation rejects bare `Color` and CSS strings
for paint options. Foreign values retained by the option face keep their
existing canvas validation timing; item generation preserves baseline paints
when a user descriptor leaves a function unevaluated. The
low-level canvas can still accept Flutter `Color` for custom drawing.

This supersedes the direct option-color representation of ADRs 0057/0061,
the gradient/pattern wrappers introduced by ADR 0125, and the scalar-only
point color fields of the typed API. It preserves numerical color operations,
geometry, callback timing, and the native update optimizations for solid
paints.

## Verification

`point_paint_test.dart` covers lazy lowering and real normal/active resolution
for all three point-prefixed dataset classes. `direct_color_test.dart` covers
the raw and typed input contracts, palette, hover and animation. Canvas tests
cover solid identity, gradients, patterns, transformed text, repeated invalid
gradients and changed gradient lists. Existing upstream observations, typed
API twins, native-update twins, specs and fixture checks remain required.
