# Chart.js ADR 0122: `dart:math` without the fdlibm ports

- Status: accepted (2026-11-12): its code and the tests of section Tests pass.
- Date: 2026-11-12
- Supersedes: parts of [Chart.js ADR 0045](0045-reference-engine-arm64.md): §2 (the x64 fdlibm data and their
  generators), §3 (the fdlibm ports `jsLog10`, `jsAtan2`, `jsSin` and `jsCos`, and the protected sites of `sin` and
  `cos`) and §8 (the tool 3 rule of the transcendental `dart:math` functions and its `js-ok` texts); and the fdlibm
  entry of [Chart.js ADR 0035](0035-third-party-sources.md) (the source list, the notice and the committed copy).
- Related: Chart.js ADR [0034](0034-no-display-only-js-exactness.md) (no display-only JS exactness). The rows
  `adapt-log10-powers` and `js-semantics-dart-math`.

## Context

The port had pure-Dart copies of fdlibm 5.3 (`fdlibm_log.dart`, `fdlibm_atan.dart`, `fdlibm_trig.dart`, 1,392 lines),
so that `log10`, `atan2`, `sin` and `cos` gave the bits of V8 13.6 on x64 on every platform. Their reference data were
frozen: only an x64 build of Node.js v24.12.0 could write them. V8 on arm64 and Chrome differ from these bits for some
inputs too. Tool 3 flagged each other `dart:math` transcendental call without a `js-ok` comment.

A check of the 24 call sites before the change found two kinds. At the radial positions, the doughnut ratio, the
radial limits and the arc center, the result moves a pixel only. At the tick limit, the tick spacing, the label sizes
of autoskip and of the time unit, `log10` and the arc hit test (`getAngleFromPoint`), the result reaches a decision.
A last-bit difference changes such a decision only for an input exactly on a boundary.

## Decision

1. `sin`, `cos`, `atan2` and `log` are `dart:math` as it is, at each site. The fdlibm ports, their tests, their data,
   their generators, the copy `third_party/fdlibm`, its entry in `tool/port_sources.yaml`, its notice in the package
   `LICENSE`, its `REUSE.toml` tables and `LICENSES/SunPro.txt` are gone.
2. `log10` of `helpers.math.dart` is `log(x) * log10e`, with the exponent itself for an exact power of ten, as the
   fallback of earlier Chart.js versions did. Thus `log10(1000)` is 3, and the floor of a logarithm keeps its tick
   spacing, its label decimals and its logarithmic ticks at the powers of ten (row `adapt-log10-powers`).
3. Tool 3 no longer flags the transcendental `dart:math` functions. The `js-ok` comments of these sites are gone.
4. The last bit of a result can differ from V8 and between the platforms. A reference test compares such a value with
   a tolerance. A hit point exactly on the border of two arcs, which upstream finds in both arcs, is listed in the
   `hitBorders` of its controller test: point 12 (286, 302) of the pie case `the step toggleDataVisibility`.

## Consequences

- The O1 texts change in the last digits of 56 configs (each difference below 1e-9), and their digests are written
  again.
- A click exactly on the border of two arcs can hit one arc where Chart.js hits both. A real pointer almost never lands
  there.
- No x64 engine is needed for reference data any more.

## Tests

- `test/port/helpers/helpers.math_test.dart`, group `log10`: the powers of ten from 1e-15 to 1e22 and the special
  values.
- The controller, scale, element and spec reference tests, with the tolerance of the logarithmic case `fixture large
  values in a small range` and the arc center of the sin ties, and the pie border point.
- `test/port/options/observation_test.dart` with the new digests.
- `test/tool/check_js_semantics_test.dart` without the transcendental rule.
