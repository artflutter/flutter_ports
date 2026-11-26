# D3 ADR 0012: Native forms of d3-scale-chromatic

- Status: accepted (2026-11-26): its code and the tests of section Tests pass.
- Date: 2026-11-26
- Related: [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md), [D3 ADR 0010](0010-native-values-and-factories.md), [D3 ADR 0011](0011-interpolate-native-forms.md), [ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md)

## Context

d3-scale-chromatic 3.1.0 defines 11 categorical palettes, 27 discrete/continuous ColorBrewer
schemes, 4 perceptually uniform lookup ramps (`viridis`, `magma`, `inferno`, `plasma`), 2
polynomial ramps (`cividis`, `turbo`), 4 Cubehelix ramps (`cubehelixDefault`, `warm`, `cool`,
`rainbow`) and `sinebow`. In JavaScript, `colors(specifier)` returns `#rrggbb` strings, every
interpolator returns a CSS color string, and `rainbow.js` and `sinebow.js` mutate and reuse a
single module-level color instance. Each ColorBrewer file also uses an ES default export and a
per-file `export var scheme` renamed in `src/index.js`.

Following [D3 ADR 0007](0007-native-dart-forms.md), [D3 ADR 0008](0008-module-packages.md),
[D3 ADR 0011](0011-interpolate-native-forms.md) and
[ADR 0011](../../../../docs/adr/0011-public-library-exports-every-file.md), the port lives in its
own package `flutter_d3_scale_chromatic_port`, depends on `flutter_d3_color_port` and
`flutter_d3_interpolate_port`, and exposes typed d3-color objects with zero JS runtime.

## Decision

1. **Typed palettes (`colors`).** `colors(String specifier)` parses each 6-hex-digit slice directly
   into an unmodifiable `List<Rgb>`. Categorical palettes (`schemeCategory10`, `schemeTableau10`,
   etc.) are `List<Rgb>`, and ColorBrewer discrete tables (`schemeBrBG`, `schemeBlues`, etc.) are
   unmodifiable `List<List<Rgb>?>` with `null` at indices 0, 1 and 2, matching upstream sparse
   indexing. Calling `.formatHex()` on any entry yields the upstream `'#rrggbb'` string.
2. **Typed fresh colors from interpolators.** Every `interpolate*` function takes `double t` and
   returns a fresh d3-color `Color` (`Rgb` for ColorBrewer, viridis family, cividis, turbo and
   sinebow; `Cubehelix` for cubehelixDefault, warm, cool and rainbow). No two calls share a mutable
   instance, and `ramp(scheme)` passes `scheme.last!` directly to `interpolateRgbBasis`.
3. **Edge inputs.** `interpolateCividis` and `interpolateTurbo` clamp out-of-range `t` to `[0, 1]`
   and propagate `NaN` as `Rgb(double.nan, double.nan, double.nan)`. The viridis lookup ramps clamp
   out-of-range `t` to the first or last entry and throw `UnsupportedError` on `NaN`, matching
   `interpolateDiscrete`. `interpolateRainbow` wraps `t` cyclically with `t -= t.floorToDouble()`
   and propagates `NaN` / infinities as `NaN` channels.
4. **Public names under ADR 0011.** Because `d3_scale_chromatic.dart` exports every file of
   `lib/src/` without `show`/`hide` combinators, each scheme file declares its public `scheme*` and
   `interpolate*` names directly (`schemeBrBG`, `interpolateBrBG`, etc.) instead of colliding on
   `scheme`. Unused `src/rampClosed.js` (imported by no upstream file and referencing `d3-scale`)
   has no Dart file.
5. **Flutter layer.** `lib/d3_scale_chromatic.dart` imports no Flutter library.
   `lib/flutter_d3_scale_chromatic_port.dart` adds `lib/src/ui/ui_scheme.dart` with
   `toUiColors()` on `List<Color>` and `toUiColorInterpolator()` on `Color Function(double t)`.
6. **ColorBrewer license notice.** Per [D3 ADR 0001](0001-upstream-sources.md) items 10 and 12,
   the package `LICENSE` carries both the ISC notice and the Apache-2.0 ColorBrewer notice,
   `tool/port_sources.yaml` records the 35 ColorBrewer files under `notices`, and `REUSE.toml`
   annotates those 35 files with `ISC AND Apache-2.0`.

## Rejected

- Returning `List<String>` / CSS strings: forces callers and `ramp()` to re-parse hex strings on
  every interpolation or Flutter `Color` conversion, contradicting D3 ADR 0011.
- Sharing a mutable module-level `Rgb`/`Cubehelix` in `rainbow`, `sinebow`, or `viridis`: risks
  silent aliasing bugs when callers store or mutate results.

## Consequences

- `flutter_d3_scale_chromatic_port` composes directly with `flutter_d3_color_port` and
  `flutter_d3_interpolate_port` with zero string parsing at runtime.
- `flutter_d3_port` re-exports both `d3_scale_chromatic.dart` and
  `flutter_d3_scale_chromatic_port.dart`.

## Tests

- `packages/flutter_d3_scale_chromatic_port/test/index_test.dart`
- `packages/flutter_d3_scale_chromatic_port/test/upstream_test.dart`
- `packages/flutter_d3_scale_chromatic_port/test/port/color_values_test.dart`
- `packages/flutter_d3_scale_chromatic_port/test/port/ui_scheme_test.dart`
- `packages/flutter_d3_scale_chromatic_port/test/port/reference_test.dart`
- `packages/flutter_d3_port/test/port/d3/index_test.dart`
