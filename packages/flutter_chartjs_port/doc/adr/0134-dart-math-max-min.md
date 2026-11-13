# Chart.js ADR 0134: `Math.max` and `Math.min` are `dart:math` `max` and `min` on doubles

- Status: accepted (2026-11-13): its code and the tests of section Tests pass.
- Date: 2026-11-13
- Supersedes: parts of [Chart.js ADR 0045](0045-reference-engine-arm64.md): in §4 the bullet of `Math.max` and
  `Math.min` with `double` operands (`jsMax`, `jsMin`, `jsMaxMinCompare` and their two code paths), the three rows of
  `Math.max` and `Math.min` with numbers in the translation table, the `_limitValue` form and the `max`/`min` item of
  the forbidden forms; in §8 the `max`/`min` item of tool 3; the `jsMax` and `jsMin` part of its test list; the
  alternative "`dart:math` `max` and `min` on every target"; and the consequence of the two code paths.
- Related: Chart.js ADR [0034](0034-no-display-only-js-exactness.md) (no display-only JS exactness), Chart.js ADR
  [0108](0108-input-surface-and-exports-for-add-on-plugins.md) and Chart.js ADR
  [0132](0132-exports-for-add-on-chart-types.md) (the exports of `lib/js_semantics.dart` for the add-on ports).

## Context

Chart.js ADR 0045 added `jsMax` and `jsMin` to `lib/src/js/js_math.dart` for speed on dart2wasm only. On the SDK of
Flutter 3.44.9, the generic `max<T extends num>` and `min` of `dart:math` boxed their `double` operands there:
`limitValue/10k` took 190.94 µs with `dart:math` and 12.56 µs with the comparisons of `jsMax` and `jsMin`. The results
of `jsMax` and `jsMin` were always the `dart:math` results (NaN for a NaN operand, +0 for `max(+0, -0)`, -0 for
`min(+0, -0)`, in either order), bit for bit on every target, and on the VM and dart2js they called `dart:math`. The
ADR said that a later ADR can remove the switch once the SDK stops the boxing.

In Dart 3.13.7 and 3.14.0-315.3.beta (the pinned Flutter 3.50.0-0.4.pre), the dart2wasm patch of `dart:math`
(`lib/_internal/wasm/common/math_patch.dart`) has a typed fast path: a call with two `double` operands inlines to one
`f64.max` or `f64.min` instruction. A standalone benchmark of `_limitValue` over 10,000 values on dart2wasm, run in
Node.js v24.22.1 on arm64, gave:

| SDK and level | `dart:math` | `jsMax`/`jsMin` |
|---|---|---|
| Dart 3.14, `-O1` | 8.02 µs | 11.95 µs |
| Dart 3.14, `-O2` | 8.03 µs | 12.19 µs |
| Dart 3.14, `-O4` | 8.43 µs | 11.77 µs |
| Dart 3.13.7, `-O2` | 8.26 µs | 12.08 µs |
| Dart 3.14, `-O0` (debug, no inlining) | 88.98 µs | 61.16 µs |

Only `-O0`, the debug build, is slower with `dart:math`. Every release level is about 1.5 times faster with it.

The fast path needs the type argument `double`. A call whose inferred type argument is `num` takes the slow generic
path and boxes. `jsMax(0, x)` hid this: its parameters are `double`, so the literal `0` was a double. `math.max(0, x)`
with a `double` x infers `num`. A call that is an operand of arithmetic infers `num` too, from the context of the
operator: in `s * math.min(l, 1 - l)` the parameter of `double.operator *` is `num`, so the type argument is `num`
although both operands are `double`.

## Decision

1. `Math.max(a, b)` and `Math.min(a, b)` with `double` operands are `dart:math` `max` and `min` with the type argument
   `double`, on every target. `jsMax`, `jsMin` and `jsMaxMinCompare` are gone from `js_math.dart`, from
   `lib/js_semantics.dart` and from `doc/public_api.txt`. The add-on ports import `dart:math` themselves.
2. The type argument must be `double`, explicit or inferred. A call with an `int` literal operand, and a call that is
   an operand of an operator or stands in another `num` context, writes it: `math.max<double>(x, 0)`, not
   `math.max(x, 0)`; with the explicit type argument the literal is a double. Where the context is `double` (an
   assignment to a `double`, a `double` return), inference gives `double`, and the lint `prefer_int_literals` keeps
   the literal an `int`. `Math.max(a, b, c)` is
   `math.max(a, math.max(b, c))`, and `Math.max(...xs)` is `xs.fold(double.negativeInfinity, math.max)` on a
   `List<double>`.
3. `Math.max` and `Math.min` with `int` operands (list indexes) stay `dart:math` `max` and `min` with `int` operands,
   as before.
4. `_limitValue` is `math.max(min, math.min(max, value))` on doubles, as `limitValue` of `helpers.math.dart` writes
   it. `num.clamp` stays forbidden.
5. Tool 3 (`check:js-semantics`) flags each call and tear-off of `dart:math` `max` and `min` whose type argument,
   explicit or inferred, is `num`. It no longer flags `double`. A kept site carries `// js-ok: <reason>`.

## Consequences

- The results do not change: `dart:math` `max` and `min` gave the `jsMax` and `jsMin` bits before. The observation
  oracle (O1) keeps its digests.
- The release builds of dart2wasm are about 1.5 times faster at these calls. A debug build without inlining
  (`-O0`) is slower.
- 68 calls of the three packages carry the type argument `<double>`: calls in arithmetic and calls with an `int`
  literal operand. A new call that infers `num` fails `check:port`.
- The fix of the lint `prefer_int_literals` reads the inferred parameter type: it turns `math.max(0.0, x)` into
  `math.max(0, x)`, which infers `num`, and `math.max(0.0, -0.0)` into `math.max(0, -0)`, which compares two `int`
  values. The explicit `<double>` is safe from it.
- `js_math.dart` has one code path for each builtin. No switch on the compiler remains.

## Tests

- `test/port/js/js_math_test.dart`, group `dart:math max and min`: the JS results of the special values (signed zeros,
  NaN in either position, infinities, the subnormal limit), the bits of `math.max` and `math.min` against the steps of
  `Math.max` and `Math.min` over the grid of 40 operands in both orders, and the fold of the spread form. It runs on
  the VM, dart2js and dart2wasm (`test:web`).
- `test/tool/check_js_semantics_test.dart`, `flags dart:math max and min with num operands`: `num` calls and tear-offs
  are flagged, `double` and `int` ones are not.
- `test/port/options/observation_test.dart` with unchanged digests, and the reference, spec and fixture tests of the
  three packages.
