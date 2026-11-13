# Chart.js ADR 0138: `Math.round` is `roundToDouble()`

- Status: accepted (2026-11-13): its code and the tests of section Tests pass.
- Date: 2026-11-13
- Supersedes: the `jsRound` parts of [Chart.js ADR 0045](0045-reference-engine-arm64.md): the
  `Math.round` rule, its table rows and its tests.
- Related: Chart.js ADR [0034](0034-no-display-only-js-exactness.md) (no display-only JS
  exactness), Chart.js ADRs [0134](0134-dart-math-max-min.md), [0135](0135-math-hypot-as-sqrt.md)
  and [0136](0136-math-pow-square.md) (the other `Math` builtins).

## Context

Chart.js ADR 0045 added `jsRound(x)` to `lib/src/js/js_math.dart`, the JavaScript `Math.round`:
a half rounds up, toward +Infinity. `roundToDouble()` gives the same result on the VM (JIT and AOT),
dart2js and dart2wasm: a probe of 24 inputs (halves, near halves, signed zeros, values near 2^52,
the infinities and NaN) gave equal results on all four. It differs from `Math.round` only for a
negative exact half: `-0.5` gives -1 in place of -0, and `-2.5` gives -3 in place of -2.

The full suite with `roundToDouble()` found three places where that input occurs:

- `alignPixel` of `helpers.canvas.dart`: a 1 px line at 0 rounds `-0.5`. Chart.js draws the line at
  0.5, and the port draws it at -0.5, half outside the canvas. A line with no width at 0 draws at
  -1 in place of 0.
- `getValueForPixel` of the category scale: the start pixel of a scale with `offset` (each bar
  chart) has the raw value -0.5. Chart.js gives category 0, and the port gives -1.
- `getRelativePosition`: an event point outside the canvas at -2.5 gives -3 in place of -2.

No tick value, label or layout size changes.

## Decision

1. `Math.round(x)` of ported code is `x.roundToDouble()`. Row `adapt-dart-round` lists the three
   places.
2. `jsRound` leaves `lib/src/js/js_math.dart`, `lib/js_semantics.dart` and `doc/public_api.txt`.
   The zoom port and the Jasmine matcher `toBeCloseToPoint` of `chartjs_test_utils` use
   `roundToDouble()` too.
3. The `check:js-semantics` rule of `.roundToDouble()` goes. The rule of `.round()` names
   `roundToDouble()`.
4. The tests read the three places as the row states:
   - The 11 grid-line cases of `core.scale.tests.js` with a line at 0 skip as
     `diverges: adapt-dart-round`.
   - The reference harnesses accept a `moveTo` or `lineTo` coordinate of -1 or -0.5 where the
     reference has 0 or 0.5 (`_edgeArgMatcher` of `scale_chart_harness.dart`, `_calls` of
     `core.scale_test.dart`).
   - The probe `valueForPixel` of a category scale records the value of `Math.round` at a raw
     negative exact half (`_jsValueForPixel` of `scale_chart_harness.dart`).
   - The digests of the observation oracle O1 are written again (66 configs).

## Tests

- `test/port/helpers/helpers.canvas_test.dart` pins `alignPixel` of a negative half and of a 1 px
  line at 0, and `test/port/helpers/helpers.dom_test.dart` the event point at -2.5.
- The full suite, `test:web`, `test:cases`, the fixture runs and `check:port` pass.

## Consequences

- A grid or tick line at the left or the top edge of the canvas draws one pixel left or up of the
  line of Chart.js.
- The start pixel of a category scale with `offset` maps to no category.
- `js_math.dart` keeps only `numberEpsilon` and `jsToInt32`.
