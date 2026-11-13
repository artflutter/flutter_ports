# Chart.js ADR 0136: `Math.pow(x, 2)` is `dart:math` `pow`

- Status: accepted (2026-11-13): its code and the tests of section Tests pass.
- Date: 2026-11-13
- Supersedes: the `jsSquare` parts of [Chart.js ADR 0045](0045-reference-engine-arm64.md): the
  `Math.pow(x, 2)` rule of §4, its table row and its tests.
- Related: Chart.js ADRs [0134](0134-dart-math-max-min.md) and
  [0135](0135-math-hypot-as-sqrt.md) (the other `Math` builtins).

## Context

Chart.js ADR 0045 added `jsSquare(x)` to `lib/src/js/js_math.dart` as the port of
`Math.pow(x, 2)`: it returns `x * x`. V8 gives the bits of `x * x` for `Math.pow(x, 2)` (23 million
probe inputs, Chart.js ADR 0045 §4), and `dart:math` `pow(x, 2.0)` gives the bits of `x * x` on the
VM, dart2js and dart2wasm (`js_math_test.dart`: a grid of 40 operands, overflow values near
1.4e154 and 20,000 seeded random bit patterns).

## Decision

1. `Math.pow(x, 2)` of ported code is `math.pow(x, 2.0).toDouble()`, with the `js-ok` comment of
   the `pow` rule of `check:js-semantics`. It is the upstream call, with no helper of the port.
2. `jsSquare` leaves `lib/src/js/js_math.dart`, `lib/js_semantics.dart` and
   `doc/public_api.txt`.

## Tests

- `test/port/js/js_math_test.dart` pins `dart:math` `pow(x, 2.0)` against `x * x`, bit for bit,
  and against the JS results of the special values.
- The full suite, `test:web`, `test:cases`, the fixture runs and `check:port` pass.

## Consequences

- The 13 sites read as upstream reads.
- On dart2wasm, `pow(x, 2.0)` costs more than `x * x` (Chart.js ADR 0045 measured about 8 times).
  The sites run a few times for each hit test, distance or curve point.
