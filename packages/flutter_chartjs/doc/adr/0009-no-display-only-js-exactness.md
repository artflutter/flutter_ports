# Chart.js ADR 0009: No display-only JS exactness

- Status: accepted (2026-10-18)
- Date: 2026-10-18
- Related: [Chart.js ADR 0010](0010-js-numeric-semantics.md) (the JS numeric rules),
  [Chart.js ADR 0011](0011-third-party-sources.md) (the third-party sources, without pixelmatch),
  [porting-flow.md](../porting-flow.md) §2.2, §2.6 and §2.10

## Context

The port emulates JavaScript and browser behavior in many places. Some emulation changes what a
chart does. Other emulation only gives the same digits or pixels as V8 and Chrome. The second kind
costs code, reference data, notices and CI time. The user sees no difference.

**Principle.** The port does not reimplement JavaScript or browser behavior whose only effect is
exact equality of digits or pixels with V8 or Chrome. The port emulates JavaScript only where the
result changes behavior.

[Chart.js ADR 0008](0008-number-formatting-on-package-intl.md) is the first case of this principle.
Number formatting uses `package:intl`, not a copy of the ICU rules.

**Measured facts.**
- `jsPow` (`fdlibm_pow.dart`) gives the bits of the fdlibm `pow` of V8 13.6. By default, V8 13.6
  does not use that `pow`. It calls the platform C `pow` (`--use-std-math-pow`). Against the
  default `Math.pow`, 307 of 6,000 reference rows differ. All of them differ by 1 ulp or less.
  Thus the port does not give the reference bits for `pow` anyway.
- A last-bit difference of `sin` or `cos` changes no pixel. Chart code uses these values for arcs,
  label angles and easing curves.
- Only one upstream spec sees the difference: `helpers.easing.tests.js`. It rounds each result to
  1e-8. Some expected values lie on a rounding tie. For example, `easeInElastic(0.2)` gives the
  expected `-0.00195313` only because `Math.sin` returns `0.5000000000000001`
  ([Chart.js ADR 0010](0010-js-numeric-semantics.md), Context).

**Two fdlibm ports change behavior.** They stay:
- `Math.log10` (`fdlibm_log.dart`). `floor(log10(x))` selects the ticks of a logarithmic scale.
  A naive translation fails the spec loop for 168 of 308 exponents.
- `Math.atan2` (`fdlibm_atan.dart`). Below −π/2, a last-bit difference changes the angle by 2π
  (`helpers.math.ts:132-136`). Thus an arc hit test gives another result.

## Decision

### 1. `sin`, `cos` and `pow` on `dart:math`

`Math.sin`, `Math.cos` and `Math.pow` become `dart:math` `sin`, `cos` and `pow` with `double`
operands.
- Remove the fdlibm ports of `sin`, `cos` and `pow` and their helpers: `fdlibm_pow.dart`,
  `fdlibm_trig.dart`, `fdlibm_rem_pio2.dart` and `fdlibm_scalbn.dart`.
- Remove their eight netlib copies from `third_party/fdlibm/`, their reference generators
  (`pow_reference.mjs`, `trig_reference.mjs`) and their bit-for-bit tests.
- Tool 3 stops flagging `sin` and `cos`. It still flags `pow(`, because `pow` on two `int` values
  overflows on the VM and dart2wasm. A `pow` call with `double` operands carries `// js-ok`.

### 2. `log10`, `atan2` and the other JS rules stay

`fdlibm_log.dart` and `fdlibm_atan.dart` stay. `jsNumberToString`, `jsRound`, the `%` rule,
`jsSort` and the `@kurkle/color` port also stay. Their results change font strings, tick values,
pixel positions, legend order and color parsing.

### 3. Canvas layer without Chromium geometry

The canvas layer of phase 3 ([porting-flow.md](../porting-flow.md) §2.2) has no Chromium-exact
`arcTo` or arc sweep math. It keeps only the Canvas 2D semantics that change behavior:
- The current path is outside `save()` and `restore()`.
- Transforms apply when the code adds a point.
- Non-finite arguments do nothing.
- The `dart:ui` context has the DPR base scale.

### 4. No image comparison

The port has no image comparison against the upstream PNGs:
- no pixelmatch port
- no Canvas-call replay suite
- no fixture ledger of PNG hashes

The fixture configs can run as smoke tests. A smoke test builds the chart and renders one frame.
It passes when no exception occurs. The port can use Flutter goldens of its own for Flutter
behavior.

### 5. Dates on `DateFormat`

The default date adapter formats with `DateFormat` of `package:intl`, with ICU pattern tokens. The
port has no moment-compatible formatter or parser. The test harness also has none. Phase 6 ports
the time-scale specs. A spec case that asserts moment-token output or parses a moment format
string skips with `'diverges: <row id>'`.

## Alternatives considered

- **Keep the fdlibm `sin`, `cos` and `pow`.** Rejected. They cost four Dart files, eight
  netlib files, two reference generators and their tests. `pow` does not give the default V8
  bits. A pure-Dart port cannot give the bits of each platform C `pow`.
- **Chromium-exact `arcTo` and arc sweep.** Rejected. It needs a port of Chromium and Skia path
  code, with its BSD notice. Its only result is pixel equality with Chrome.
- **Image comparison against the upstream PNGs.** Rejected. It needs a pixelmatch port with an
  ISC notice, 592 Canvas-call recordings, a ledger of 662 PNGs, 15-21 MB of PNGs, and a fixtures
  job pinned to the Skia renderer on Linux. Each `.fvmrc` change and each Chart.js bump re-runs the
  ledger. The 31 real-font fixtures do not match without the Chrome fonts.
- **A moment-compatible formatter and parser.** Rejected. It needs a formatter and a lenient
  parser for the moment tokens, written from the moment documentation, and a Node.js script with
  a pinned moment for expected values. Only spec strings use it. 97 time-scale cases parse moment
  format strings. 58 cases check moment-token text.

## Consequences

- Some spec cases skip with `'diverges: <row id>'`, with a row in
  [differences.md](../differences.md). This includes the moment-token cases of phase 6.
- The ported easing spec allows the last-digit difference at the rounding ties. The
  `differences.md` row [`js-semantics-dart-math`](../differences.md#js-semantics-dart-math)
  records this tolerance.
- `sin`, `cos` and `pow` can give other last bits on the VM, dart2js and dart2wasm. No pixel
  depends on these bits. The easing spec uses the tolerance of
  [`js-semantics-dart-math`](../differences.md#js-semantics-dart-math).
- `third_party/pixelmatch` has no Dart target now. This ADR does not remove it. A follow-up change
  removes it and these references:
  - the submodule and its `.gitmodules` entry
  - the `port_sources.yaml` entry
  - the `REUSE.toml` comment
  - the pixelmatch pin in the list of third-party sources
    ([Chart.js ADR 0011](0011-third-party-sources.md) gives the list without it)
  - the pixelmatch cases of `test/tool/config_readers_test.dart`
  - the pixelmatch lines of AGENTS.md
- The parity status `verified` (visual parity against upstream renders) leaves the legend.
  `ported` is the last status of a module. A follow-up change removes `verified` from tool 5
  (`tool/src/spec_cases.dart`) and [upstream-tracking.md](../upstream-tracking.md). It also
  removes the fixture ledger and pixelmatch from upstream-tracking.md. Backport condition 2 of
  [ADR 0004](../../../../docs/adr/0004-follow-upstream-between-releases.md) names `verified`.
  [ADR 0006](../../../../docs/adr/0006-follow-upstream-between-releases.md) supersedes ADR 0004
  and states that condition without `verified`.
- [porting-flow.md](../porting-flow.md) §2.2, §2.3, §2.6, §2.10, §3, §4 (tools 3 and 7), §5 and
  §7 follow this ADR.
