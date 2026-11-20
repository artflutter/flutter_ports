# Chart.js ADR 0188: The point of an element is an Offset

- Status: accepted (2026-11-20): `getCenterPoint` and `tooltipPosition` give an `Offset`, and the tests, the fixtures and the port checks pass.
- Date: 2026-11-20
- Supersedes: nothing
- Related: [Chart.js ADR 0017](0017-element-properties.md), [Chart.js ADR 0187](0187-flutter-border-radius-corners.md)

## Context

`tooltipPosition` and `getCenterPoint` of an element give the object literal `{x, y}` upstream. The port
gave `ElementPoint`, a class of its own that implements the interface `Point`. Flutter has a value class for
a position: `Offset` of `dart:ui`. The interface `Point` also stands for the elements and the chart event,
which are mutable objects, and for an event position whose coordinate can be JS `null`.

## Decision

1. `Element.tooltipPosition` and `VisualElement.getCenterPoint` give an `Offset`, also in the add-on
   elements (the sankey `Flow`). A property in the `undefined` state gives NaN.

   ```dart
   final Offset center = (element as VisualElement).getCenterPoint();
   ```

2. `ElementPoint` is gone.
3. `Point` stays for the elements, the chart event, the interaction position, the drawing cursor of the
   tooltip (`TooltipPoint`) and `InterpolatedPoint`: these are mutable, or hold a JS `null` coordinate.
4. The distance metric of the interaction reads the center as an `Offset`. `IChart.isPointInArea` keeps its
   `Point` parameter, and the interaction gives it the center through a private `Point`.
5. `TooltipPosition` keeps its `x` and `y`: a user positioner can give any JS value there.

## Rejected

- An `Offset` for the interaction position: an `Offset` cannot hold the JS `null` that `inRange` reads as no
  test on an axis.
- An `Offset` for the helpers that take a `Point` (`distanceBetweenPoints`, `getAngleFromPoint`,
  `isPointInArea`): their callers pass elements in hot loops, and each call would make an `Offset`.

## Consequences

- Two `Offset` values with NaN are not equal. A test compares such a point with a matcher.
- An app reads `dx` and `dy` of the point.

## Tests

- `test/port/core/core.element_test.dart`
- `test/specs/element.point_test.dart`
- `test/specs/element.bar_test.dart`
- `test/port/controllers/controller_chart_harness.dart`
- `packages/flutter_chartjs_chart_sankey_port/test/specs/flow_test.dart`
