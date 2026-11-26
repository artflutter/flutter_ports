# D3 ADR 0013: Immutable `const` color values

- Status: accepted (2026-11-26): its code and the tests of section Tests pass.
- Date: 2026-11-26
- Supersedes: [D3 ADR 0012](0012-scale-chromatic-native-forms.md) §2 (fresh object per call requirement for lookup ramps and palettes)
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0011](0011-interpolate-native-forms.md)

## Context

Upstream `d3-color` represents colors as mutable JavaScript objects (`c.r = 0; c.opacity = 0.5;`).
In Dart and Flutter, mutable color classes carry two steep costs:

1. **Per-call heap allocations on lookup ramps and named parses.** Because callers might mutate a
   returned `Rgb`, `interpolateViridis` / `Magma` / `Inferno` / `Plasma`, named CSS color lookups
   (`color('steelblue')`), and same-space conversions (`Rgb.from(rgb)`, `Hsl.from(hsl)`, etc.) all
   had to allocate a fresh copy on every call. In `flutter_d3_scale_chromatic_port`, `call.viridis`
   was ~3× slower in native AOT than Node.js solely because of that per-call allocation.
2. **No compile-time constants.** Colors and palettes (`schemeCategory10`, `schemeBlues`, etc.)
   could not be `const`, forcing runtime hex decoding on startup and preventing use in `const`
   Flutter widgets and themes.

Meanwhile, `Color.copyWith(...)` (Flutter-idiomatic rename of upstream `copy`) covers functional
updates across all five color spaces, and no code in `flutter_d3_color_port`,
`flutter_d3_interpolate_port`, or `flutter_d3_scale_chromatic_port` mutates colors in place.

## Decision

1. **Immutable `const` color classes in `flutter_d3_color_port`.** `Color`, `Rgb`, `Hsl`, `Lab`,
   `Hcl` and `Cubehelix` declare `final double` channel fields and `const` primary constructors
   (`abstract class const Color()`, `class const Rgb(...)`, etc.). `Color.opacity` is a read-only
   getter (`double get opacity`). Callers derive modified colors with `copyWith(...)`.
2. **Zero-allocation identity reuse.** Because color values are immutable:
   - `rgbConvert`, `hslConvert`, `labConvert`, `hclConvert` and `cubehelixConvert` return the
     existing instance directly when `o` is already of that color space (`o.rgb()` / `o is X`), and
     return shared `const` NaN instances when `o == null`.
   - Named CSS color lookups (`_scanNamed`) return the cached `Rgb` directly with zero allocation.
3. **Compile-time `const` palettes and zero-allocation ramps in `flutter_d3_scale_chromatic_port`.**
   - `interpolateViridis`, `interpolateMagma`, `interpolateInferno` and `interpolatePlasma` index
     compile-time `const List<Rgb>` tables and return shared `const Rgb` entries directly with zero
     allocation per call.
   - All 11 categorical schemes (`schemeCategory10`, etc.) and 27 ColorBrewer discrete schemes
     (`schemeBrBG`, `schemeBlues`, etc.) are compile-time `const List<Rgb>` /
     `const List<List<Rgb>?>` constants.

## Rejected

- Keeping mutable fields and caching only inside a separate immutable wrapper type: splits the color
  hierarchy in two and breaks interoperability across D3 modules.
- Returning raw packed `int` or `String` from `interpolateViridis`: violates D3 ADR 0011/0012 typed
  color returns.

## Consequences

- Breaking API change in `flutter_d3_color_port`: channel fields (`r`, `g`, `b`, `h`, `s`, `l`,
  `a`, `c`, `opacity`) are `final`. Code that mutated channels in place switches to
  `c.copyWith(...)`.
- `Rgb`, `Hsl`, `Lab`, `Hcl`, `Cubehelix` and all `flutter_d3_scale_chromatic_port` palettes can be
  used in `const` expressions and Flutter `const` widgets.
- Zero per-call heap allocations in `interpolateViridis`/`Magma`/`Inferno`/`Plasma`, named CSS color
  parsing, and same-space conversions (`Rgb.from`, `Hsl.from`, `Lab.from`, `Hcl.from`,
  `Cubehelix.from`).

## Tests

- `packages/flutter_d3_color_port/test/port/immutable_test.dart`
- `packages/flutter_d3_color_port/test/rgb_test.dart`
- `packages/flutter_d3_color_port/test/hsl_test.dart`
- `packages/flutter_d3_color_port/test/lab_test.dart`
- `packages/flutter_d3_color_port/test/hcl_test.dart`
- `packages/flutter_d3_interpolate_port/test/port/color_values_test.dart`
- `packages/flutter_d3_scale_chromatic_port/test/port/color_values_test.dart`
