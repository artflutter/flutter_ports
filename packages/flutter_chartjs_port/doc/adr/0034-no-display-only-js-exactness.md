# Chart.js ADR 0034: No display-only JS exactness

- Status: accepted (2026-10-21)
- Date: 2026-10-21
- Supersedes: [Chart.js ADR 0009](0009-no-display-only-js-exactness.md)
- Related: [Chart.js ADR 0032](0032-js-numeric-semantics.md) (the JS numeric rules, `jsSin` and
  `jsCos`), [Chart.js ADR 0013](0013-canvas-model.md) (the canvas model, the bitmap space),
  [Chart.js ADR 0024](0024-dates.md) (the default date adapter),
  [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) (number formatting),
  [Chart.js ADR 0029](0029-fixture-smoke-runner.md) (the fixture smoke runner),
  [Chart.js ADR 0035](0035-third-party-sources.md) (the third-party sources, without pixelmatch),
  [porting-flow.md](../porting-flow.md) §1.1, §2.2, §2.3, §2.6 and §2.10

## Context

The port emulates JavaScript and browser behavior in many places. Some emulation changes what a
chart does. Other emulation only gives the same digits or pixels as V8 and Chrome. The second kind
costs code, reference data, notices and CI time. The user sees no difference.

Chart.js ADR 0009 (accepted 2026-10-18) stated the principle of this ADR. Two later decisions
changed facts that it states:
- Chart.js ADR 0009 put `Math.sin` and `Math.cos` on `dart:math`, because "a last-bit difference
  of `sin` or `cos` changes no pixel". Phase 7 found two charts where the last bit of `Math.sin`
  changes the hit element (Chart.js ADR 0032, Context). A CI run on Windows gave another arc for
  a doughnut query on the border of two arcs. A pie query on macOS gave another arc than V8.
- Chart.js ADR 0009 listed "The `dart:ui` context has the DPR base scale." Chart.js ADR 0013
  (accepted 2026-10-21) replaced that base scale with the bitmap space. Its Open item asks for a
  new ADR that supersedes Chart.js ADR 0009 with that item changed.

Chart.js ADR 0009 said only that the port emulates JavaScript where the result changes behavior.
Its section 2 counted pixel positions as behavior. AGENTS.md and
[porting-flow.md](../porting-flow.md) §1.1 listed five protected results: the ticks, the hit
element, the item order, the resolved option and a throw. This ADR states the protected behavior
as a rule. It adds layouts, scales, element properties, public return values and discrete
decisions. It removes draw positions. Chart.js ADR 0032 lists the protected `sin` and `cos` sites
at the pin.

This ADR states the complete current decision and supersedes Chart.js ADR 0009. Its Decision
keeps the section numbers of Chart.js ADR 0009.

**Measured facts.**
- By default, V8 13.6 does not use the fdlibm `pow`. It calls the platform C `pow`
  (`--use-std-math-pow`). An fdlibm port differed from the default `Math.pow` on 307 of 6,000
  reference rows, each by 1 ulp or less. Thus no pure-Dart port gives the reference bits for
  `pow`.
- `dart:math` `pow(10.0, k)` gives the V8 bits for each integer `k` from -340 to 320 on the VM,
  dart2js and dart2wasm.
- `lib/` had 72 calls of `sin` and `cos`. A probe moved each result by 1 ulp. The 52 calls whose
  results reach only a canvas call or an easing value failed 0 of 6,184 test cases. The other 20
  calls reach a layout, a scale, an element property or a hit test. Their move failed 15 or 16
  cases.
- `helpers.easing.tests.js` rounds each result to 1e-8. Some expected values lie on a rounding
  tie. For example, `easeInElastic(0.2)` gives the expected `-0.00195313` only because
  `Math.sin` returns `0.5000000000000001`.
- A naive `Math.log10` fails the logarithmic tick loop for 168 of 308 exponents. Below −π/2, a
  last-bit difference of `Math.atan2` changes the angle by 2π, and thus an arc hit test.

[Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) is a case of this principle.
Number formatting uses `package:intl`, not a copy of the ICU rules.

## Decision

**Principle.** The port does not reimplement JavaScript or browser behavior whose only effect is
exact equality of digits or pixels with V8 or Chrome. The port emulates JavaScript only where the
result changes protected behavior.

**Protected behavior.** For the same platform inputs, these results must equal the results of
the reference engine on every target. The platform inputs are the text measures, the clock and
the time zone. The JS emulation adds no difference to these results:
- the ticks: their values, their count and the ticks that show
- the hit element of an event or a query
- the item order, for example of the legend, the tooltip and the active elements
- the resolved option
- a throw: whether code throws, and where
- any value that reaches a layout, a scale (its size, its ticks, its label capacity), an element
  property, a hit test, a discrete decision, or a value that a public member returns

A draw position (a pixel) and display text are not protected by themselves, also when a public
member returns them. They are protected where they reach one of the items above, for example a
label width that selects the time unit.

The intermediate values of a running animation are not protected. An easing value reaches only
these values. The end values of an animation are protected.

### 1. `sin`, `cos` and `pow`

- `Math.sin` and `Math.cos` at a site whose result reaches protected behavior give the bits of
  the reference engine on every target. The port calls `jsSin` and `jsCos`, pure-Dart ports of
  fdlibm 5.3.
- `Math.sin` and `Math.cos` at a display-only site are `dart:math` `sin` and `cos` with `double`
  operands. A display-only site reaches only a canvas call or an easing value. It carries a
  `// js-ok` comment.
- A site whose result reaches both a canvas call and protected behavior is protected.
- `Math.pow` is `dart:math` `pow` with `double` operands and a `// js-ok` comment. The port has no
  fdlibm `pow`, no `pow` reference generator and no bit-for-bit `pow` test. `Math.pow(x, 2)` is
  `jsSquare(x)`, the product `x * x`, which is exact.
- `pow` also stays on `dart:math` at a protected site, for example in the tick code of the
  logarithmic scale. V8 and `dart:math` on the VM call the platform C `pow`. For an integer
  exponent, `pow(10.0, k)` gives the V8 bits (Context). If a test leg shows a difference of
  protected behavior at a `pow` site, a new ADR decides the form.
- `asin` of `calculateLabelRotation` stays on `dart:math` with `js-ok`. Its input, the label
  size, comes from the text layout of the platform.
- Tool 3 flags `dart:math` `sin` and `cos`. It also flags `pow(`, because `pow` on two `int`
  values overflows on the VM and dart2wasm.

### 2. `log10`, `atan2` and the other JS rules stay

The port keeps fdlibm ports of `Math.log10`, `Math.atan2`, `Math.sin` and `Math.cos`. It also
keeps `jsNumberToString`, `jsRound`, the `%` rule, `jsSort` and the `@kurkle/color` port. Their
results change tick values, font strings and thus text measures and layouts. They also change the
item order, the hit element and color parsing.

### 3. Canvas layer without Chromium geometry

The canvas layer has no Chromium-exact `arcTo` geometry, no arc curve math of Chromium (the Skia
arc-to-conic conversion) and no pixel matching. It keeps the Canvas 2D semantics that change
behavior. Among them:
- The current path is outside `save()` and `restore()`.
- Transforms apply when the code adds a point.
- Non-finite arguments do nothing.
- A negative radius in `arc`, `arcTo` or `ellipse` throws a `RangeError`. A sweep of 2π or more
  draws a full circle.
- The `dart:ui` context records in bitmap space, the device pixels of the DOM bitmap, with no base
  scale. The host maps the bitmap to the display size of the canvas. Thus `retinaScale` stays a
  line-by-line port. Content that the code drew at another device pixel ratio, or before the
  host attached, shows at the correct size.

### 4. No image comparison

The port has no image comparison against the upstream PNGs:
- no pixelmatch port
- no Canvas-call replay suite
- no fixture ledger of comparison results

The upstream manifest records the SHA-256 of each fixture config and PNG. No tool compares pixels
with the PNGs.

The fixture configs run as smoke tests. A smoke test builds the chart, runs the `run` hook of the
fixture and renders one frame. It passes when no step throws and the test framework reports no
error. The port can use Flutter goldens of its own for Flutter behavior.

### 5. Dates on `DateFormat`

The default date adapter formats with `DateFormat` of `package:intl`, with ICU pattern tokens. A
parse with a format reads an ICU pattern through `DateFormat`. A string without a format goes
through the scanners of the port for the moment `configFromString` grammars: ASP.NET, ISO 8601
and RFC 2822. Each other string is invalid. The port has no formatter or parser for moment format
tokens, and the test harness also has none. The calendar rules of the adapter (`startOf`, `add`,
`diff` and the time zone) give the results of chartjs-adapter-moment, because they change the
ticks.

A spec case or a fixture that asserts moment-token text or parses a moment format string skips
with `'diverges: adapt-date-moment-format'`. A port-only twin with ICU patterns can keep its
assertions.

## Alternatives considered

- **`dart:math` `sin` and `cos` at every site.** Chart.js ADR 0009 chose this form. Rejected now.
  The two hit ties of Context give another hit element than upstream, and the result differs
  between the CI legs (Chart.js ADR 0032).
- **The fdlibm `sin` and `cos` at every site.** Rejected. No protected result gains. The draw
  paths call `sin` and `cos` about 60,000 times in each frame of a 10,000-point `triangle` line.
- **Keep the fdlibm `pow`.** Rejected. It does not give the default V8 bits. A pure-Dart port
  cannot give the bits of each platform C `pow`.
- **Chromium-exact `arcTo` geometry and arc curve math.** Rejected. It needs a port of Chromium
  and Skia path code, with its BSD notice. Its only result is pixel equality with Chrome.
- **A DPR base scale in the `dart:ui` context.** Rejected (Chart.js ADR 0013). The host cannot
  show content that the code drew at another device pixel ratio at the correct size.
- **Image comparison against the upstream PNGs.** Rejected. It needs a pixelmatch port with an
  ISC notice and 592 Canvas-call recordings. It also needs a ledger of one row for each fixture
  PNG (667 at the pin), 15-21 MB of PNGs and a fixtures job pinned to the Skia renderer on Linux.
  Each `.fvmrc` change and each Chart.js bump re-runs the ledger. The 31 real-font fixtures do not
  match without the Chrome fonts.
- **A formatter and parser for moment format tokens.** Rejected. It needs a formatter and a lenient
  parser for the moment tokens, written from the moment documentation, and a Node.js script with
  a pinned moment for expected values. Only spec strings use it.

## Consequences

- Some spec cases and fixtures skip with `'diverges: <row id>'`, with a row in
  [differences.md](../differences.md). This includes the moment-token cases.
- The ported easing spec allows one unit of 1e-8 at the rounding ties. The `differences.md` row
  [`js-semantics-dart-math`](../differences.md#js-semantics-dart-math) records this tolerance.
- `pow` and the display-only `sin` and `cos` can give other last bits on the VM, dart2js and
  dart2wasm. No protected result depends on these bits.
- A new site whose result reaches protected behavior calls the exact builtin. If a test leg shows
  a difference of protected behavior, the porter finds the builtin and ports it. The porter does
  not drop the test. `pow` and `asin` are the exceptions of section 1.
- The parity status `verified` (visual parity against upstream renders) does not exist. `ported`
  is the last status of a module.
- The port has no pixelmatch code and no `third_party/pixelmatch` submodule.
- [porting-flow.md](../porting-flow.md) §2.2, §2.3, §2.6, §2.10, §3, §4 (tools 3 and 7), §5
  and §7 follow this ADR.
- AGENTS.md (Porting rules) and [porting-flow.md](../porting-flow.md) §1.1 list the protected
  behavior of this ADR.
- On acceptance, the code comments, the tool messages, AGENTS.md, porting-flow.md and the
  proposed ADRs that cite Chart.js ADR 0009 cite this ADR. Section numbers 1-5 stay the same.

## Evidence

- The `sin` and `cos` probe: `design/trig/judge.md`, `design/trig/spec.md` (working files of
  phase 7, not committed).
- The figures of `jsSin` and `jsCos`: [performance.md](../performance.md) §13.8.
