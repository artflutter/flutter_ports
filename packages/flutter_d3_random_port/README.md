# flutter_d3_random_port

A native, pure-Dart, fully statically typed port of
[d3-random](https://github.com/d3/d3-random) **3.0.1**: all 17 probability distribution generators
(`randomUniform`, `randomInt`, `randomNormal`, `randomLogNormal`, `randomBates`, `randomIrwinHall`,
`randomExponential`, `randomPareto`, `randomBernoulli`, `randomGeometric`, `randomBinomial`,
`randomGamma`, `randomBeta`, `randomWeibull`, `randomCauchy`, `randomLogistic`, `randomPoisson`)
with typed `.source(RandomSource)` factories, bit-exact 32-bit `randomLcg([num? seed])`, and typed
`Float64List`/`Int32List` batch `fill`/`sample` helpers — with **zero runtime dependencies**, **zero
`dynamic`**, zero Flutter import, and zero JavaScript runtime.

```dart
import 'package:flutter_d3_random_port/d3_random.dart';

// 1. Seeded deterministic PRNG matching upstream d3-random v3.0.1 bit-for-bit
final rng = randomLcg(0.42);
final normal = randomNormal.source(rng)(100, 15);
final x = normal(); // double

// 2. Discrete integer distributions return int directly
final die = randomInt.source(randomLcg(7))(1, 7);
final roll = die(); // int in [1, 6]
final hits = randomBinomial.source(randomLcg(0.5))(100, 0.35)(); // int

// 3. Batch sampling into typed Float64List / Int32List buffers
final gammaSamples = randomGamma.source(randomLcg(0.5)).sample(1000, 2, 1.5);
final poissonSamples = randomPoisson.source(randomLcg(0.5)).sample(1000, 12);
```

## Installing

```sh
dart pub add flutter_d3_random_port
```

- **Pure Dart (zero runtime dependencies, zero Flutter import):**
  `import 'package:flutter_d3_random_port/d3_random.dart';`
  (or `import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';`)
  Compiles cleanly for Dart VM, native AOT, JavaScript (`dart2js`), and WebAssembly (`dart2wasm`).

## API

- **Core typedefs & PRNG:** `RandomSource` (`double Function()`), `RandomGenerator`
  (`double Function()`), `RandomIntGenerator` (`int Function()`), `defaultRandomSource`,
  `randomLcg([num? seed])`, `randomLog1p`, `randomLog1m`, and `RandomGeneratorBatch` /
  `RandomIntGeneratorBatch` (`fill` and `sample`).
- **Continuous distributions (`RandomGenerator` / `Float64List` batch helpers):**
  `RandomUniform` (`randomUniform`), `RandomNormal` (`randomNormal`), `RandomLogNormal`
  (`randomLogNormal`), `RandomBates` (`randomBates`), `RandomIrwinHall` (`randomIrwinHall`),
  `RandomExponential` (`randomExponential`), `RandomPareto` (`randomPareto`), `RandomGamma`
  (`randomGamma`), `RandomBeta` (`randomBeta`), `RandomWeibull` (`randomWeibull`), `RandomCauchy`
  (`randomCauchy`), `RandomLogistic` (`randomLogistic`).
- **Discrete distributions (`RandomIntGenerator` / `Int32List` batch helpers):**
  `RandomInt` (`randomInt`), `RandomBernoulli` (`randomBernoulli`), `RandomGeometric`
  (`randomGeometric`), `RandomBinomial` (`randomBinomial`), `RandomPoisson` (`randomPoisson`).

## Performance

Benchmarked on Apple M3 Max (Node.js v24.22.1, macOS CLI/Flutter AOT, Chrome 157, Firefox 160,
Safari 27.0.1) and Pixel 8a (Android 17 AOT `--release`, Mobile Chrome 157, Mobile Firefox 160).
All values are median **ns/op** (lower is better; see
[doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_random_port/doc/performance.md)
for the complete 16-case breakdown including baseline vs optimized).

- **Native AOT:** macOS Flutter AOT beats desktop Node.js on **12/16 workloads** (up to **4.11×
  faster** on `lcg.draw_10000`, **2.11× faster** on `normal.fill_10000`, and **1.88× faster** on
  `binomial.draw_2000`); Pixel 8a Android AOT beats Mobile Chrome upstream JS on **14/16 workloads**
  (up to **3.83× faster**).
- **Web (`dart2wasm` & `dart2js`):** `dart2wasm` beats upstream JS on **16/16 workloads** in both
  Desktop Chrome (up to **10.63× faster**) and Mobile Chrome (up to **7.64× faster**), and on
  **12/16 workloads** in Desktop Firefox (up to **2.00× faster**); `dart2js` beats upstream JS on
  **16/16 workloads** in Mobile Chrome (up to **3.22× faster**) and **14/16 workloads** in Desktop
  Chrome.

### Native AOT vs Node.js (ns/op)

| Case | Node.js upstream | macOS AOT | Pixel 8a Android AOT | Pixel Chrome JS |
|---|---:|---:|---:|---:|
| `lcg.draw_10000` | 70,588 | **17,160** | **34,455** | 132,031 |
| `int.draw_10000` | 70,823 | **50,686** | 97,469 | 157,813 |
| `normal.draw_10000` | 221,092 | **116,105** | **169,109** | 389,063 |
| `logNormal.draw_10000` | 379,900 | **225,641** | **358,781** | 603,125 |
| `bernoulli.draw_10000` | 70,463 | **48,650** | 95,160 | 160,156 |
| `geometric.draw_10000` | 141,009 | **102,152** | 196,086 | 251,563 |
| `gamma.draw_10000` | 424,518 | **290,781** | 496,469 | 781,250 |
| `beta.draw_10000` | 1,183,643 | **783,469** | 1,190,938 | 1,875,000 |
| `weibull.draw_10000` | 293,246 | **233,164** | 374,656 | 459,375 |
| `binomial.draw_2000` | 622,159 | **331,781** | **432,703** | 1,062,500 |
| `poisson.draw_2000` | 542,660 | **335,453** | **426,516** | 975,000 |
| `normal.fill_10000` | 224,637 | **106,551** | **144,938** | 404,688 |

### Desktop & Mobile Browsers (ns/op, `upstream / dart2js / dart2wasm`)

| Case | Chrome 157 | Firefox 160 | Safari 27.0.1 | Pixel Chrome 157 | Pixel Firefox 160 |
|---|---|---|---|---|---|
| `lcg.draw_10000` | 118,359 / 67,574 / **11,132** | 66,406 / 105,469 / **33,203** | 17,578 / 132,813 / **11,230** | 132,031 / 64,840 / **17,285** | 62,500 / 66,406 / **60,547** |
| `uniform.draw_10000` | 117,969 / 66,406 / **11,132** | 66,406 / 101,563 / **62,500** | **11,230** / 125,000 / 35,156 | 133,594 / 89,063 / **27,734** | **62,500** / 66,406 / 125,000 |
| `normal.draw_10000` | 189,844 / 166,414 / **84,371** | 234,375 / 226,563 / **203,125** | **97,656** / 210,938 / 117,188 | 389,063 / 230,469 / **135,156** | 296,875 / **265,625** / 343,750 |
| `bates.draw_10000` | 1,075,000 / 903,125 / **116,410** | 656,250 / 1,000,000 / **562,500** | **97,656** / 1,375,000 / 296,875 | 1,375,000 / 637,500 / **207,813** | **656,250** / 812,500 / 1,125,000 |
| `gamma.draw_10000` | 404,687 / 334,375 / **177,344** | 500,000 / 468,750 / **437,500** | **218,750** / 421,875 / 265,625 | 781,250 / 470,328 / **239,078** | 656,250 / 593,750 / **562,500** |
| `beta.draw_10000` | 1,206,250 / 787,531 / **506,281** | 1,312,500 / **1,000,000** / 1,062,500 | **562,500** / 1,062,500 / 718,750 | 1,875,000 / 1,187,500 / **715,625** | 1,875,000 / **1,437,500** / 1,562,500 |
| `binomial.draw_2000` | 621,875 / 387,516 / **256,250** | 718,750 / 593,750 / **531,250** | 390,625 / 453,125 / **375,000** | 1,062,500 / 678,094 / **348,453** | 1,000,000 / 781,250 / **718,750** |
| `poisson.draw_2000` | 500,000 / 362,500 / **237,500** | 656,250 / 562,500 / **531,250** | **343,750** / 468,750 / 359,375 | 975,000 / 521,844 / **334,391** | 812,500 / **687,500** / 781,250 |
| `normal.fill_10000` | 229,688 / 149,227 / **59,770** | 265,625 / 187,500 / **171,875** | 117,188 / 210,938 / **109,375** | 404,688 / 125,781 / **99,215** | 437,500 / **195,313** / 250,000 |

## Upstream

- Upstream: [d3/d3-random](https://github.com/d3/d3-random) `v3.0.1` (`d3RandomVersion`).
- Differences from upstream:
  [doc/differences.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_random_port/doc/differences.md).
- Full benchmark report:
  [doc/performance.md](https://github.com/artflutter/flutter_ports/blob/main/packages/flutter_d3_random_port/doc/performance.md).

## License

ISC (matching upstream `d3-random`). See [LICENSE](LICENSE). This project is not affiliated with the
D3 project or Observable.
