# Chart.js ADR 0174: Canvas values of option values without WebIDL conversions

- Status: accepted (2026-11-18): its code and the tests of section Tests pass.
- Date: 2026-11-18
- Supersedes: of [Chart.js ADR 0017](0017-element-properties.md) §8, the items on
  `lib/src/js/js_webidl.dart` and its functions, and the item "These functions model the DOM, not
  `core.element.ts`. Thus they are in `lib/src/js/`."
- Related: [Chart.js ADR 0173](0173-option-function-types.md), [Chart.js ADR 0145](0145-native-option-types.md),
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md)

## Context

Upstream gives an option value to a canvas setter as it is, for example `ctx.lineWidth = options.borderWidth`. The
DOM converts the value with the WebIDL type of the setter: `ToNumber` for a width, a `ToNumber` of each item for
`setLineDash`. The port had `lib/src/js/js_webidl.dart` for this. The options now hold Dart values: a number is a
`double`, a cap is a `StrokeCap`, a paint is a `ChartPaint`. The `ToNumber` of a string or a bool runs only for a
value of the wrong type.

## Decision

1. **A canvas value is the option value of the setter type.** `lib/src/canvas/canvas_values.dart` (a core layer)
   has the six functions, with their names. The JS runtime no longer has them.

   ```dart
   ctx
     ..lineWidth = canvasNumber(options.borderWidth)
     ..setLineDash(canvasLineDash(options.borderDash));
   ```

2. **No `ToNumber`.** `canvasNumber` gives the `double` of a `num`, and Dart `null` for each other value, which the
   canvas ignores. `canvasLineDash` gives a `List<double>` itself, or the `double` of each `num` item and NaN for
   another item: the canvas then ignores the whole dash, as the DOM does for NaN. A value that is not a List still
   throws a `TypeError`. A width and a dash change pixels only, so the port does not emulate `ToNumber` (Chart.js
   ADR 0034). An upstream spec with `borderWidth: '#daa'` gives the same result: the DOM ignores its NaN.
3. **The other functions keep their rules.** `canvasStyle` gives Dart `null` for the `undefined` sentinel, and the
   canvas validates the other values. `canvasLineCap`, `canvasLineJoin` and `canvasTextAlign` give the Flutter enum
   value, and a keyword stops a debug build.
4. **Not public.** No public library exports the file: the six functions are inner helpers of the elements, the
   scales and the plugins. `js_semantics.dart` and the app library no longer export them.
5. **Row.** `adapt-canvas-option-values` of `differences.md` has the difference.

## Rejected

- Keep `ToNumber` for a raw config: it changes only the pixels of a width given as a numeric string.
- Stop a debug build for a value of another type: the upstream specs give `borderWidth: '#daa'` on purpose.

## Consequences

- JS `null` as a width or a dash offset gives Dart `null`, which the canvas ignores. The DOM sets 0: the width 0
  is ignored too, and a dash offset of 0 is the default.
- A width or a dash item given as a numeric string, for example `'2'`, has no effect. The reference case
  `bottom, title with a string strokeWidth and no strokeColor` of `core.scale_test.dart` skips with
  `diverges: adapt-canvas-option-values`.

## Tests

- `test/port/canvas/canvas_values_test.dart`
- The element, scale, controller and plugin reference tests, which record the canvas calls.
- The full test list of AGENTS.md before a push.
