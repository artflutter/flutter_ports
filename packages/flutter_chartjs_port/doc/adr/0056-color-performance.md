# Chart.js ADR 0056: Profile-guided color implementation

- Status: proposed; the code and measurements exist, but the policy exception and durable
  reproduction package described below are not yet complete.
- Date: 2026-10-31
- Gate: acceptance of this record's local policy change, plus retention of the comparison
  sources and results.
- Proposed partial supersession: the general performance eligibility rule of
  [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13, as stated below. This takes
  effect only on acceptance of this record.
- Related: [Chart.js ADR 0020](0020-registry-and-component-classes.md) §13,
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md),
  [Chart.js ADR 0054](0054-typed-internal-model.md),
  [performance.md](../performance.md) §§17–19,
  [differences.md](../differences.md) (`adapt-kurkle-*`).

## Context

The Flutter 3.44 to 3.47 investigation localized a Wasm regression in the hex decoder's
string-keyed map. The controlled SDK comparison and binary intervention are recorded in
performance.md §17. Character-code decoding removed that dependency. Section 18 measures that
first fix across available platforms; it is a different baseline from section 19.

Subsequent Pixel 8a profiling found regex work, generic numeric conversion, copying, collections
and string concatenation in the color operation workloads. Section 19 measures the further
changes against the implementation **after** the hex fix. Its results justify faster color
operations. They do not establish faster whole-chart frames or apply to every Color method.

The code diverges structurally from @kurkle/color 0.3.2, so the current frame-only requirement of
Chart.js ADR 0020 §13 is material. This record proposes a computational-routine route for this
case. The phrase "accepted
implementation" in the performance report identifies the selected experimental candidate;
it is not an ADR status.

## Decision

### Local performance eligibility

For the Chart.js port, adopt this rule: operation measurements can justify an equivalent Dart
form or a local computational adaptation with explicit domain, ownership and fallback, tested
on affected compiler backends with realistic inputs. The adaptation is limited to a routine
and its private helpers, with no new public API, shared state or lifetime policy. Changes
to shared state, object models, dispatch, scheduling or rendering still require application-level
evidence. This replaces the general requirement in Chart.js ADR 0020 §13 that every structural
adaptation demonstrate a frame gain.

Keep the 0.1 ms resolution of the existing Chart.js frame comparisons; smaller differences do
not count as demonstrated frame gains. The historical plugin-dispatch conclusion of Chart.js
ADR 0020 and the `NumberSlots` alternative of Chart.js ADR 0019 remain unchanged. The typed model
of Chart.js ADR 0054 and the rejection of resolver memo/fast-path layers in Chart.js ADR 0053
remain in force. This decision introduces no shared-package extraction or host-interface change.

On acceptance, add a partial-supersession pointer to Chart.js ADR 0020 without rewriting its
historical evidence, and update `porting-flow.md` §1.1 to reference this adoption.

### Color implementation

Keep the public API and pinned upstream behavior. Use these local pure Dart implementations:

| Implementation | Invariant or fallback that makes it valid | Difference row |
|---|---|---|
| Decode hex from character codes and retain integer digits | Bitwise invalid digits still become zero; invalid short alpha still becomes NaN; arbitrary formatting channels preserve ToInt32 behavior. | `adapt-kurkle-hex-code-units` |
| Use direct conversion for proven numeric bounds | Retain the original arithmetic outside those bounds, including negative values, overflow and non-finite values; preserve rounding order. | `adapt-kurkle-byte-bounds` |
| Copy private RGBA fields and reuse private temporary results | Returned objects remain independent; clone preserves the b2n/n2b alpha round trip and validity behavior; mix applies setter-equivalent conversion. | `adapt-kurkle-color-copies` |
| Dispatch clearly identified syntax before name lookup | Preserve case rules, invalid-input results and the U+0130 behavior of names. | `adapt-kurkle-color-dispatch` |
| Parse a guarded common comma syntax with `simple_parse.dart` | The scanner accepts only its documented domain; every other form reaches the original regex; RGB and hue retain different alpha conversion rules. | `adapt-kurkle-simple-colors` |
| Convert regex decimal captures with `double.tryParse` | Captures already exclude other JS number syntaxes; malformed captures still produce NaN. | `adapt-kurkle-decimal-groups` |
| Construct fixed-length hue result literals and reuse private lists | Lists remain fresh and growable; callers' input lists are not mutated; numeric operations preserve their order. | `adapt-kurkle-hue-arrays` |
| Build RGB/hex output in an ASCII buffer on native/Wasm; concatenate on dart2js | The compiler selects an equivalent form; unusual RGB channels retain `jsNumberToString`; alpha and short-hex rules stay unchanged. | `adapt-kurkle-color-strings` |

The adaptations belong to the color implementation and its private helpers. They add no global
parsed-color cache, approximate lookup table, public API or change to the shared JS semantics.
The parsing fallback remains part of the implementation, not transitional code to remove later.
Local inlining hints are supported by this measured implementation, not a repository-wide default.

## Evidence and its limits

The canonical protocol, full tables and validation are in [performance.md](../performance.md)
§19. Android timings use Flutter 3.47.8 / Dart 3.13.7 release AOT on Pixel 8a, profiler off,
baseline/final/final/baseline in fresh processes, with warm-up and 15 batches per case.

| Selected operation | Before → after (ns/op) | Speedup |
|---|---:|---:|
| Common RGBA parsing | 1239.8 → 89.8 | 13.80x |
| Common HSL parsing | 1348.5 → 190.0 | 7.10x |
| RGB formatting | 198.7 → 45.9 | 4.33x |
| Clone and mix parsed colors | 183.2 → 84.2 | 2.17x |
| Parse and mix hex colors | 848.9 → 164.7 | 5.15x |

The corrected formatting implementation also improves the measured Chrome JS/Wasm workloads.
The initial unconditional ASCII-buffer version was rejected because RGB formatting was about
five times slower in dart2js. Remainder-arithmetic replacement and broad JS-runtime inlining did
not survive screening. These rejected experiments explain why this ADR chooses local, differing
backend forms instead of a general rule to replace concatenation or inline runtime helpers.

The differential comparison passed 1,234,644 comparisons on each of VM AOT, dart2js and
dart2wasm. The permanent [fast-path tests](../../test/port/kurkle_color/fast_paths_test.dart) and
[color tests](../../test/port/kurkle_color/index.esm_test.dart) cover the contracts and fallback
behavior. The focused suite passed 163 VM tests and 326 Chrome JS/Wasm tests; the spec suite,
workspace analysis, formatting and seven port checks passed. A baseline differential comparison
guards against new differences; upstream tests still define conformance.

The final Android series contains two process medians per side, not a confidence-interval study.
Other native devices were not reprofiled for these final changes. The earlier iPhone and desktop
figures in §18 concern the first hex fix. No whole-chart FPS, gamma-correct interpolation,
cold-start or allocation-byte improvement is claimed here. Cache hits do not receive a parser
speedup. The final mix conversion has a separate web guard; do not pool it with the preceding
17-case web series as if they measured identical candidate source.

## Acceptance and maintenance

The following remain before accepting this record:

1. Adopt this record's explicit partial supersession of Chart.js ADR 0020 §13,
   or supply the application evidence required by the existing policy and revise this record
   accordingly.
2. Promote the minimal benchmark/oracle sources, source snapshots or reconstructible patches,
   commands, metadata and process results to tracked files or a durable retrievable artifact.
   They currently live in ignored `.handover/kurkle-android-tuning/` and temporary build paths.
   The tracked report and tests retain the conclusions and contracts, but not the entire
   reproduction package. Retain the build/run commands, workload inputs, SDK/compiler settings,
   device metadata, individual process results and oracle needed to reproduce the comparison.
   Record that artifact's location here.

This is an evidence-retention and policy gate, not a requirement to repeat a measurement night.
Keep the existing markers and difference rows linked to §19. On an upstream or SDK update,
check the parser domain and conversion bounds against the new source, run correctness on the
three backends, and repeat affected performance comparisons before renewing speedup claims.
If a compiler no longer benefits from its specialized formatter, simplify the implementation
with measured evidence and record the changed decision in a superseding ADR.
