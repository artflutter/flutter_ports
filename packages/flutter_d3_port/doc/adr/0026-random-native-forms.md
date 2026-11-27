# D3 ADR 0026: Native forms of d3-random

- Status: accepted (2026-11-27): its code and the tests of section Tests pass.
- Date: 2026-11-27
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0009](0009-native-spec-harness.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0017](0017-array-native-forms.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

`d3-random` 3.0.1 provides 17 probability distribution generators (`randomUniform`, `randomInt`,
`randomNormal`, `randomLogNormal`, `randomBates`, `randomIrwinHall`, `randomExponential`,
`randomPareto`, `randomBernoulli`, `randomGeometric`, `randomBinomial`, `randomGamma`,
`randomBeta`, `randomWeibull`, `randomCauchy`, `randomLogistic`, `randomPoisson`), each with a
`.source(source)` factory method for injecting a deterministic PRNG, plus the deterministic
32-bit linear congruential generator `randomLcg([seed])`.

Upstream JavaScript relies on callable function objects with attached `.source` properties,
`arguments.length` arity switching (`randomUniform`, `randomInt`), `Function.prototype.apply`
forwarding (`randomLogNormal`), implicit `+x` unary coercion, JS bitwise `| 0` / `>>> 0`
truncation in `randomLcg`, and `Math.log1p` (not present in `dart:math`).

Following [D3 ADR 0007](0007-native-dart-forms.md) (zero JS runtime),
[D3 ADR 0008](0008-module-packages.md) (one package per D3 module), and
[D3 ADR 0009](0009-native-spec-harness.md) (native `package:test` specs and Node.js reference
tests), `d3-random` 3.0.1 is ported as its own standalone pure-Dart package
`flutter_d3_random_port` with **zero runtime dependencies**, **zero Flutter imports**, **zero
`dynamic`**, **zero `Object?` escape hatches**, and **zero JS runtime**.

## Decision

1. **Pure Dart package (`d3_random.dart` and `flutter_d3_random_port.dart`) with zero runtime
   dependencies.**
   `package:flutter_d3_random_port/d3_random.dart` exports every file in `lib/src/` without
   `show`/`hide` combinators (ADR 0011) and imports only `dart:math` and `dart:typed_data`, so it
   compiles cleanly for the Dart VM, native AOT, `dart2js`, and `dart2wasm`.
   `package:flutter_d3_random_port/flutter_d3_random_port.dart` re-exports `d3_random.dart`.
   Internal helper names (`defaultRandomSource`, `randomLog1p`) are `random`-prefixed to avoid
   symbol collisions when re-exported by `flutter_d3_port`.

2. **Typed source and generator function aliases (`lib/src/defaultSource.dart`).**
   - `typedef RandomSource = double Function();` — uniform PRNG returning doubles in `[0, 1)`.
   - `typedef RandomGenerator = double Function();` — continuous distribution sampler returning
     `double`.
   - `typedef RandomIntGenerator = int Function();` — discrete distribution sampler returning
     `int`.
   - `double defaultRandomSource()` — default source backed by `dart:math.Random`.
   - `double randomLog1p(double x)` — accurate `ln(1 + x)` implementation avoiding catastrophic
     cancellation for small `|x|` and matching ECMAScript `Math.log1p(x)` edge cases (`x == -1`
     returns `-infinity`, `x < -1` or `NaN` returns `NaN`).

3. **Typed callable `.source(RandomSource)` factory classes for all 17 distributions.**
   Each upstream callable function with a `.source` property is modeled as a `final class` with a
   typed `call(...)` method and a typed `.source(RandomSource)` method returning a new factory
   bound to that source:
   - **Continuous (`RandomGenerator` / `double Function()`):**
     - `RandomUniform` (`randomUniform`): `call([num? min, num? max])` (1-argument form
       `randomUniform(max)` spans `[0, max)`, 0-argument spans `[0, 1)`, 2-argument spans
       `[min, max)`).
     - `RandomNormal` (`randomNormal`): `call([num mu = 0, num sigma = 1])`.
     - `RandomLogNormal` (`randomLogNormal`): `call([num mu = 0, num sigma = 1])`.
     - `RandomBates` (`randomBates`): `call(num n)` (`n == 0` returns the underlying `source`).
     - `RandomIrwinHall` (`randomIrwinHall`): `call(num n)` (`n <= 0` returns `() => 0.0`).
     - `RandomExponential` (`randomExponential`): `call(num lambda)`.
     - `RandomPareto` (`randomPareto`): `call(num alpha)` (throws `RangeError` for `alpha < 0`).
     - `RandomGamma` (`randomGamma`): `call(num k, [num theta = 1])` (throws `RangeError` for
       `k < 0`; preserves upstream's single shared Marsaglia polar normal generator per
       `RandomGamma` factory instance for bit-exact seeded parity).
     - `RandomBeta` (`randomBeta`): `call(num alpha, num beta)` (delegates to its own
       `RandomGamma` instance bound to `source`).
     - `RandomWeibull` (`randomWeibull`): `call(num k, [num a = 0, num b = 1])` (Weibull for
       `k > 0`, Gumbel for `k == 0`, Fréchet for `k < 0`).
     - `RandomCauchy` (`randomCauchy`): `call([num a = 0, num b = 1])`.
     - `RandomLogistic` (`randomLogistic`): `call([num a = 0, num b = 1])`.
   - **Discrete (`RandomIntGenerator` / `int Function()`):**
     - `RandomInt` (`randomInt`): `call(num min, [num? max])` (1-argument form `randomInt(max)`
       draws integers in `[0, floor(max) - 1]`; 2-argument draws in `[floor(min), floor(max) - 1]`).
     - `RandomBernoulli` (`randomBernoulli`): `call(num p)` (throws `RangeError` if `p < 0`,
       `p > 1`, or `p.isNaN`).
     - `RandomGeometric` (`randomGeometric`): `call(num p)` (throws `RangeError` if `p <= 0`,
       `p > 1`, or `p.isNaN`; because Dart `int` cannot represent `double.infinity`, the
       degenerate `p == 0` case that returns `Infinity` in JS throws `RangeError` in the typed
       integer API, recorded under `adapt-random-typed-api`).
     - `RandomBinomial` (`randomBinomial`): `call(int n, num p)`.
     - `RandomPoisson` (`randomPoisson`): `call(num lambda)`.

4. **Exact 32-bit unsigned LCG semantics across VM, AOT, Wasm, and dart2js (`lib/src/lcg.dart`).**
   `RandomSource randomLcg([num? seed])` implements upstream `d3-random` v3.0.1's Numerical
   Recipes LCG (`mul = 0x19660D`, `inc = 0x3C6EF35F`, `eps = 1 / 0x100000000`) with exact 32-bit
   unsigned modular arithmetic:
   - Seed initialization converts `0 <= seed && seed < 1 ? seed / eps : seed.abs()` using exact
     ECMAScript `ToUint32` modular reduction so fractional, negative, large, and edge seeds match
     Node.js bit-for-bit across 64-bit native integers (VM/AOT/Wasm) and 53-bit IEEE 754 JS
     doubles (`dart2js`).
   - Each step computes `state = (_mul * state + _inc) & 0xffffffff`. Because
     `0x19660D * 0xffffffff + 0x3C6EF35F = 7,149,080,513,909,408 < 2^53 - 1`, the intermediate
     product-plus-increment is exact in both 64-bit signed integers and IEEE 754 float64 without
     overflow or rounding, and `& 0xffffffff` yields the exact unsigned 32-bit state on every
     Dart target.

5. **Hot-path optimizations and typed batch helpers (`adapt-random-fast-forms`).**
   - Unboxed state fields in Marsaglia polar `randomNormal` (replacing nullable `double?` closure
     capture with unboxed `double` fields and caching `sqrt(-2 * log(r) / r)` across the paired
     draw — halving transcendental calls while producing bit-exact outputs).
   - Zero-closure direct draw paths in `randomGamma` (inlining Marsaglia-Tsang normal draws and
     eliminating the per-draw `multiplier` closure), `randomBeta`, `randomBinomial` (calling
     internal beta and geometric draw helpers without per-iteration closure allocations),
     `randomPoisson` (calling internal gamma and binomial draw helpers without per-iteration
     closure allocations), `randomWeibull` (eliminating `outerFunc` indirection), `randomBates` /
     `randomIrwinHall` (precomputed integer loop count and fractional weight), and
     `randomBernoulli` (branchless threshold comparison instead of `double.floor()`).
   - Typed batch fill/sample helpers (`fill(Float64List)` / `sample(int)` on continuous factories
     and `RandomGeneratorBatch`, and `fill(Int32List)` / `sample(int)` on discrete factories and
     `RandomIntGeneratorBatch`) that draw directly into typed arrays in tight monomorphic loops.

## Rejected

- Returning `Function` or `num Function()` for distributions: loses static `double` vs `int`
  distinction and forces callers to cast every draw.
- Allowing `randomGeometric(0)` to return `double` (`double.infinity`): would force
  `randomGeometric` to return `double Function()` instead of `int Function()`, breaking integer
  ergonomics for all valid `p ∈ (0, 1]` draws.
- Representing `.source` via `Expando` or untyped wrapper maps: loses static type checking and
  adds per-call overhead compared to `final class` callable factories.

## Consequences

- Upstream `d3-random` usage patterns such as `randomNormal.source(randomLcg(0.42))(0, 1)` translate
  nearly verbatim into fully statically typed Dart with zero `dynamic` and zero runtime casts.
- All 18 upstream test files (67 cases) plus Node.js bit-exact reference parity tests and
  faster-form twin tests run with zero `dart:io` imports on VM (including
  `--experimental-faster-testing`), Chrome JS, and Chrome Wasm.

## Tests

- `packages/flutter_d3_random_port/test/*_test.dart` (all 18 upstream test files, 67 cases)
- `packages/flutter_d3_random_port/test/port/reference_test.dart` (Node.js v3.0.1 bit-exact LCG and seeded distribution parity)
- `packages/flutter_d3_random_port/test/port/faster_forms_test.dart` (baseline vs optimized twin tests + batch fill parity)
- `packages/flutter_d3_random_port/test/upstream_test.dart` (upstream pin & `.gitmodules` tests)
- `packages/flutter_d3_port/test/port/d3/index_test.dart` (bundle re-export test)
