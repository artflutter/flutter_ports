# Chart.js ADR 0187: Corner options hold a Flutter BorderRadius

- Status: accepted (2026-11-20): the corner options are Flutter `BorderRadius` values, and the tests, the fixtures and the port checks pass.
- Date: 2026-11-20
- Supersedes: [Chart.js ADR 0123](0123-edge-insets-padding.md) item 6
- Related: [Chart.js ADR 0054](0054-typed-internal-model.md), [Chart.js ADR 0116](0116-text-style-fonts.md)

## Context

Upstream gives a corner option as `number | {topLeft, topRight, bottomLeft, bottomRight}`: the bar
`borderRadius` and `hoverBorderRadius`, the legend label `borderRadius`, the tooltip `cornerRadius` and the
point label `borderRadius`. The port held the object form as a scope of the kind `BorderRadius` and read it
by name. `toTRBLCorners` gave the interface `TRBLCorners`, and the tooltip label style had its own class
`TooltipCornerRadii`. Flutter has a class for the four corners. The bar reads the two forms differently:
`isObject(value)` decides whether a skipped edge cuts the corner of a number radius.

## Decision

1. The object form of each corner option above is a Flutter `BorderRadius`, also in a raw config. A number
   stays a number. The schema atom is `borderRadius`: `number | borderRadius`.

   ```dart
   BarDataset(extra: {'borderRadius': BorderRadius.only(topLeft: Radius.circular(8))});
   ```

2. `toTRBLCorners(value)` gives a `BorderRadius`: the value itself, or each corner of a number. The radius of
   a corner is its `Radius.x`. A Map stops a debug build, and a release build gives no radius.
3. The bar tests `value is BorderRadius` where upstream tests `isObject(value)`.
4. `TRBLCorners` and `TooltipCornerRadii` are gone. `RoundedRect.radius`, `LegendItem.borderRadius`,
   `TooltipLabelStyle.borderRadius`, `TooltipOptions.cornerRadius` and `LegendLabelOptions.borderRadius` are
   `BorderRadius` values. The legend label field is Dart `null` for a falsy option.
5. The arc `borderRadius` (`outerStart`, `outerEnd`, `innerStart`, `innerEnd`) has no Flutter class. It keeps
   its object form, the schema kind `ArcBorderRadius`.
6. An import has no `show` list, also `package:flutter/painting.dart` in a core layer. A name clash keeps its
   list: the generated option files import `package:intl/intl.dart` with `show NumberFormat`, because its
   `TextDirection` clashes with the one of `dart:ui`.
7. The reference generators write each upstream corner object as a `BorderRadius` literal. The resolver trace
   tests a scriptable key of a nested bar option with `borderWidth`, which keeps its object form.

## Rejected

- A `BorderRadius` for the number form too: the bar cannot tell a number from an object then.
- A port class for the corners: Flutter has one.

## Consequences

- A corner object with a function at a corner has no Dart form. A function of the whole option gives a
  `BorderRadius`.
- An elliptical `Radius` draws a circle of its `x`.
- The typed API keeps `double?` for `borderRadius` and `cornerRadius`; `extra` takes a `BorderRadius`.

## Tests

- `test/specs/helpers.options_test.dart`
- `test/port/helpers/helpers.options_test.dart`
- `test/port/options/schema_test.dart`
- `test/port/elements/element.bar_draw_reads_test.dart`
- `test/port/plugins/plugin.tooltip_test.dart`
- `test/port/core/resolver_trace_test.dart`
