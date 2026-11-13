# Chart.js ADR 0135: `Math.hypot` is `math.sqrt(a * a + b * b)`

- Status: accepted (2026-11-13): its code and the tests of section Tests pass.
- Date: 2026-11-13
- Supersedes: parts of [Chart.js ADR 0108](0108-input-surface-and-exports-for-add-on-plugins.md):
  §2 (`jsHypot`, `tool/reference/hypot_reference.mjs` and `test/port/js/hypot_reference.dart`),
  the `jsHypot` rows of its test list, and the rejected alternative "`math.sqrt(a * a + b * b)` for
  `Math.hypot`".
- Related: Chart.js ADR [0034](0034-no-display-only-js-exactness.md) (no display-only JS
  exactness), Chart.js ADR [0134](0134-dart-math-max-min.md) (`Math.max` and `Math.min`).

## Context

Chart.js ADR 0108 added `jsHypot` to `lib/src/js/js_math.dart`: the V8 form of `Math.hypot` with
two operands. It tests the infinities and NaN, divides both magnitudes by the larger one, adds the
squares, takes the square root and multiplies by the larger magnitude. The ADR rejected the plain
form `math.sqrt(a * a + b * b)`, because it differs from V8 in the last bit for about one pair in
three, and because it overflows for `1e200` and underflows for `1e-200`.

The only callers are the two `Math.hypot` sites of the zoom port (`gestures.dart`, from
`src/gestures.ts:38` and `:258`): the distance of two pointers for a pinch, and the length of the
pan delta. Both take pointer coordinates in logical pixels.

- At pixel sizes, the squares cannot overflow or underflow.
- The plain form differs from V8 only in the last bit. That bit changes no pixel, no tick and no
  scale range that a person can see. It changes a pan start only when a distance lands exactly on
  the pan threshold, and for whole-pixel deltas both forms give the exact result there, because
  `a * a + b * b` is exact and the square root is correctly rounded.
- A standalone benchmark over 10,000 pixel-size pairs on Node.js v24.22.1 arm64 and the pinned SDK
  gave:

| Target | `jsHypot` | `math.sqrt(a * a + b * b)` |
|---|---|---|
| VM JIT | 38.18 µs | 11.83 µs |
| VM AOT | 170.29 µs | 43.82 µs |
| dart2wasm `-O2` | 35.93 µs | 14.71 µs |
| dart2js `-O4` | 44.00 µs | 6.50 µs |

By Chart.js ADR 0034, the port emulates JavaScript only where the result changes behavior, not for
the exact digits only.

## Decision

1. `Math.hypot(a, b)` of ported code is `math.sqrt(a * a + b * b)` with `double` operands, written
   at the call site. The port has no runtime function for it.
2. `jsHypot` leaves `lib/src/js/js_math.dart`, and thus `lib/js_semantics.dart` and
   `doc/public_api.txt`.
3. `tool/reference/hypot_reference.mjs`, `test/port/js/hypot_reference.dart` and
   `test/port/js/js_math_hypot_test.dart` go.
4. A future caller with operands that can overflow or underflow (far beyond pixel sizes) gets its
   own decision.

## Tests

- The zoom specs, the 12 zoom fixtures and the range-only run (`test:fixtures:zoom`,
  `test:zoom:range-only`) pass with the plain form.
- `test/tool/public_api_test.dart` passes with the list without `jsHypot`.

## Consequences

- The two zoom sites are 2.4 to 6.8 times faster.
- The last bit of a pinch ratio or a pan length can differ from Chromium. No test compares that
  bit.
