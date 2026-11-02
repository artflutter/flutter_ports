# Chart.js ADR 0061: Flutter Color throughout the core

- Status: implemented and locally validated.
- Date: 2026-11-02
- Requested: use Flutter Color directly; drop standalone-Dart execution for the
  affected layers rather than introduce another platform adapter.
- Supersedes: ADR 0057's numerical built-in representation and installed bridge,
  and the no-dart:ui portion of earlier pure-layer/test-runner requirements.

## Decision

Solid colors are dart:ui Color from the first read, including default option
cells, palettes, compiled themes, resolved element options and animation/hover
results. Delete PreparedColor, the mutable reader/writer/type-check callbacks,
installNativeColorCodec and every setup call. No conditional implementation or
replacement registration mechanism is introduced. Scope/resolver reads return
the value they store, preserving native identity and color space.

The existing @kurkle/color arithmetic still implements upstream manipulation and
mixing. Its constructor reads a native Color directly, normalizing the channels
as before; its numeric RGBA working values are algorithm inputs, not a second
option-value representation. Native painting retains the original Color, its
alpha and its color space. Static CSS inputs remain rejected. Test-only decoders
still translate frozen upstream CSS reference data into native inputs.

## Layers and execution

The framework-free core can import dart:ui, but cannot import package:flutter
framework libraries. The existing pureRoots/pure.dart names remain for source
compatibility in internal tooling and the test harness; they no longer promise
standalone Dart execution. check:lib-imports enforces the framework boundary and
all existing component/theme/typed-API restrictions. Library code still imports
no dart:io, JavaScript interop or platform-specific external runtime.

Core tests run through Flutter on the VM and in Chrome (JavaScript/DDC and
WebAssembly). tool/test_web.dart selects files without @TestOn('vm') before
Flutter compiles the combined browser app, since runtime filtering is too late
for VM-only imports. The browser core tests retain mock text metrics; disk font
loading remains limited to VM paragraph/pixel tests. Release JS/Wasm gallery
builds remain supported. Core microbenchmarks run through bench_flutter_test.dart.
The old dart run/compile benchmark commands and standalone dart test are retired.

DDC canonicalizes signed zero in constant aggregate fixtures differently from
the former dart2js runner. Signed-zero tests now construct that value at runtime;
the exact sign assertions remain. The Set equality test supplies an explicit
comparator, because default Set NaN handling differs by backend. Source math and
collection algorithms do not change.

## Verification

The regression reads the raw default cell before any chart/canvas construction,
checks it is Color, and verifies that construction does not replace it or change
its public representation. Native identity, Display P3, exact alpha, invalid-input,
hover/animation and theme tests remain. CI shard tests must pass without setup
calls, and browser core tests must pass through Flutter in both compiler modes.
The public export list remains unchanged. Generated resolved options are updated
through options:gen. Existing golden files retain their native-alpha baseline.

## Validation outcome

- Chart core VM suite: 10,054 passed, 84 skipped. The other five workspace
  packages pass (524 tests, three skips).
- Flutter Chrome JavaScript and WebAssembly: 3,950 chart-core tests plus
  55 harness tests pass in each compiler mode; two existing skips per mode.
  Coverage matches the preceding suite; only the equality-policy case name and
  signed-zero display names change.
- Controller/plugin CI-style shards 1 and 2, with experimental faster testing:
  433 and 429 tests pass without any native-color installation call.
- Upstream case coverage: 958 passed, 78 skipped, no failures/missing cases.
- Fixtures: 628 passed, 39 expected skips; public export checks pass.
- All seven port checks, options generation check, format check and fatal-info
  analysis pass. The native-color and JS-runtime microbenchmark entry smokes pass.
- Release Android arm64 and web Wasm/JavaScript-fallback gallery builds pass.

The preceding checkpoint 0826d8d was pushed and its GitHub CI run 41367063319
passed before this refactor. These refactor results are local; the pinned Linux
goldens were not regenerated or compared on a Mac. Painting receives the same
native values and the existing golden files remain unchanged. No performance
claim is made from the benchmark smoke checks.
