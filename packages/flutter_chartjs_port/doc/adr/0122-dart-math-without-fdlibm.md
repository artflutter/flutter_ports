# Chart.js ADR 0122: `dart:math` without the fdlibm ports

- Status: accepted (2026-11-12): its code and the tests of section Tests pass.
- Superseded by: [Chart.js ADR 0146](0146-js-numeric-semantics.md) (2026-11-14)
- Date: 2026-11-12
- Supersedes: parts of [Chart.js ADR 0045](0045-reference-engine-arm64.md): §2 (the x64 fdlibm data and their
  generators), §3 (the fdlibm ports `jsLog10`, `jsAtan2`, `jsSin` and `jsCos`, and the protected sites of `sin` and
  `cos`) and §8 (the tool 3 rule of the transcendental `dart:math` functions and its `js-ok` texts); and the fdlibm
  entry of [Chart.js ADR 0035](0035-third-party-sources.md) (the source list, the notice and the committed copy).
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0122-dart-math-without-fdlibm.md`

## Summary

This ADR removed the fdlibm 5.3 ports of `log10`, `atan2`, `sin` and `cos`, their frozen x64 data and the copy
`third_party/fdlibm`. `sin`, `cos`, `atan2` and `log` became `dart:math` as it is, at each site. `log10` became
`log(x) * log10e`, with the exponent itself for an exact power of ten. Tool 3 dropped its rule of these functions.
A reference test compared a last-bit value with a tolerance, and each arc hit query stayed checked.

## Where each part went

- Item 1 (`dart:math` as it is, no fdlibm code): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §3. The
  Supersedes line of Chart.js ADR 0146 names the fdlibm parts of [Chart.js ADR 0035](0035-third-party-sources.md).
- Item 2 (`log10` with the exact powers of ten): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §3, the
  `Math.log10` bullet.
- Item 3 (tool 3 without the transcendental functions): [Chart.js ADR 0146](0146-js-numeric-semantics.md) §3,
  first bullet, and §8.
- Item 4 (a tolerance for the last bit, the checked hit queries): [Chart.js ADR 0146](0146-js-numeric-semantics.md)
  §10, the tolerance bullet and the bullet that starts with "Each hit query stays checked".
- Item 4 (the pie border point in `hitBorders`): removed. Commit `e477f55b` removed the pie reference test, and no
  test passes `hitBorders` now.
- Consequences: [Chart.js ADR 0146](0146-js-numeric-semantics.md), Consequences, bullet 2.
