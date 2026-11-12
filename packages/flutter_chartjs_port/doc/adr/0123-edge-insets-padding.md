# Chart.js ADR 0123: Padding holds an EdgeInsets

- Status: accepted (2026-11-12): the implementation, specs, fixtures and native/browser tests pass.
- Date: 2026-11-12
- Supersedes: the padding option representation of ADR 0054 and the padding lowering of ADR 0052.
- Related: [ADR 0116](0116-text-style-fonts.md), [ADR 0115](0115-hand-ports-of-typed-data-fixtures.md).
- Difference: `adapt-edge-insets-padding`.

## Context

The typed API already accepts Flutter `EdgeInsets`, but lowered it into a `PaddingScope`. Layout, scales and plugins
then converted the option through `toPadding`, reading sides by name and allocating a second object. Raw configs
accepted a number or an object with sides and the `x`/`y` shorthands.

## Decision

1. `layout.padding`, scale title padding, legend title padding, title and subtitle padding, tooltip padding, and
   tick/point-label `backdropPadding` hold `EdgeInsets`, also in raw configs. The schema atom is `edgeInsets`.
2. A padding value is complete. `EdgeInsets.only(left: 8)` sets the other sides to zero. An absent option inherits
   its lower-priority scope as usual; it does not merge individual sides. An absent resolved value gives
   `EdgeInsets.zero`. A scalar, string or Map stops a debug build; release builds use zero for an invalid value.
3. Scriptable options return `EdgeInsets`. The existing scriptability/indexability descriptors stay, including the
   non-scriptable tick backdrop padding. Readers use the native sides, `horizontal` and `vertical`.
4. The typed API passes its padding directly to the scope. `paddingScope` is removed. The static data-update
   eligibility check accepts the exact `EdgeInsets` class; arbitrary subclasses retain the ordinary fallback.
5. Scalar spacing (`ticks.padding`, `pointLabels.padding`, legend label padding and box padding) remains numeric.
   Border widths and corner radii retain their existing representations. `PaddingScope`, `toTRBL` and `toPadding`
   remain for border widths, generic public helpers and internal minimum-padding inputs.
6. Core layers may import `package:flutter/painting.dart` with `show EdgeInsets`, alongside the existing font
   names. `check:lib-imports` enforces this explicit allowlist.
7. Reference generators write native padding literals and normalize padding observations to their four sides.
   Data fixtures with these padding options get hand ports, following ADR 0115; no runtime padding adapter is
   added to the library or harness. The 36 new hand ports retain the pinned fixture hashes.

## Tests

- `test/port/options/edge_insets_test.dart`: native storage, inheritance, complete replacement, scriptable values,
  old input rejection, data-only eligibility, and unchanged scalar spacing/border widths.
- Layout, scale, title, legend, tooltip, theme, typed-lowering and data-update tests.
- Upstream specs, fixture smoke tests and the observation oracle, including the hand-ported scriptable layout.
- The generated schema, import allowlist, source headers and typed-read ratchet.
