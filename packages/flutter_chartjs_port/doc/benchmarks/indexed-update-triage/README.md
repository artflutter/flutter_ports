# Indexed update triage: classification, projection and fresh options

2026-11-05. Baseline: ADR 0085 / fd6e040. Apple M3 Max, macOS 27.0.1,
Flutter 3.47.8 / Dart 3.13.7, native profile AOT. Experiments remain isolated;
production library hashes are unchanged.

## Decision

**Promote bounded weak native-map classification reuse into a production-hardening
pass.** Do not promote the numeric shortcut or fresh-copy specialization on the
current evidence. The uncapped weak cache is rejected because it regresses
workloads that replace every map each update. The bounded version keeps the
stable-data benefit and limits that measured churn penalty to about 1%.

This is triage evidence, not shipped runtime code or a universal 60 FPS result.
The complete native mode matrix, browser and broader regression suites still
need to run on a final production implementation.

## Fresh profile changed the priority

The connected indexed capture has 10,279 CPU samples. NativePointCoordinates.accepts
appears in 32.2% of sampled stacks and Object.runtimeType in 28.1%. The unconnected
indexed capture agrees: 32.4% and 28.8%. PointOptions.clone appears in only about
0.8–1.0%. In the scriptable control, coordinate qualification is essentially
absent and runtimeType accounts for about 0.1%.

The existing last-Type cache avoids repeating the native-type-set lookup, but
still asks every map for runtimeType. That repeated work is much larger than
fresh option cloning in these workloads. Inclusive percentages overlap and
must not be added or directly interpreted as wall-clock milliseconds.

## Candidates

- **guard:** a controller-owned slot array of WeakReference entries remembers
  successful SDK-map classification by object identity across updates. Values
  remain live: x/y are checked again at their original point, and routes/custom
  objects retain their ordinary rejection. Replaced maps miss the cache. Weak
  references avoid retaining old user payloads. Cache size follows the point count.
- **numeric:** in the existing native indexed-color window, snapshot unaligned
  exact native linear-scale inputs and write numeric point fields directly in
  the original order. Arithmetic order and int16 clamping remain. Other scales,
  alignment, unsupported coordinates, active/custom points and callback paths
  retain ordinary processing. This is an isolated prototype, not a new public
  projection API.
- **fresh:** generate a fresh clone-with-background operation and specialize the
  single-varying-background-color case, avoiding generic store dispatch. It still
  creates a new independently mutable options object. Generator source is changed
  and regenerated; generated .g.dart files are never hand-edited.
- **combined:** all three candidates together, measured rather than adding gains.

All variants use separately compiled binaries with no runtime experiment branch
in the hot loop. The first matrix uses baseline/guard/numeric/fresh/combined and
the reverse order. Each process runs indexed updates with connections off/on,
20k items and 200 static labels, eight seconds per cell with two seconds excluded,
at 1036×520/DPR2 on the built-in display (maximum 120 Hz). Static/scriptable controls
are retained too. Builds/tests/profiling are idle during ordinary timings.

| Candidate | Connections off: mean UI ms | Connections on: mean UI ms |
| --- | ---: | ---: |
| baseline | 14.39 | 16.71 |
| guard | 10.32 | 11.86 |
| numeric | 14.23 | 16.42 |
| fresh | 14.29 | 16.46 |
| combined | 10.08 | 12.42 |

The guard candidate improves warm-map mean UI about 28–29%. Numeric/fresh changes
are small relative to variation; the combination does not consistently beat the
guard alone. Static/scriptable controls have small mixed differences, with no
new speed claim. The guard's separate CPU profile drops runtimeType from 28.1%
to about 0.1% of sampled stacks, confirming the targeted work was removed.

## Replacement-data regression and bounded fill

A benchmark-only beforeUpdate hook replaces every raw map with a new ordinary
map containing the same values. It runs identically in baseline and candidate.
The uncapped guard regresses mean UI from 17.98→19.89 ms without connections and
20.08→21.46 ms with connections: approximately 11% and 7% slower. Its weak-reference
entries are recreated without gaining reuse. Weak ownership alone is not enough.

The bounded prototype preserves the slot prefix as point counts change and
creates at most 1,024 new weak entries per prepared pass. Existing hits do not
consume that budget. Cache misses still use ordinary native classification and
live value checks. A stable 20k dataset can fill over roughly twenty passes;
continuously replaced maps do not create 20k new weak entries every update.
No coordinate value, option result or callback result is memoized.

Separate A/B/B/A comparisons use one common churn-aware harness for both builds:

| Bounded-cache workload | Connected | Baseline mean UI ms | Candidate mean UI ms | Reduction | UI p90 before → after ms |
| --- | --- | ---: | ---: | ---: | --- |
| plain | off | 13.64 | 9.48 | 30.5% | 14.67 / 14.89 → 10.59 / 10.83 |
| plain | on | 15.29 | 11.54 | 24.5% | 16.92 / 16.10 → 12.64 / 13.12 |
| churn | off | 18.77 | 18.70 | 0.3% | 20.98 / 22.08 → 21.31 / 22.06 |
| churn | on | 20.93 | 21.14 | -1.0% | 22.82 / 26.25 → 24.97 / 25.08 |

Stable-data mean UI improves about 30.5% without connections and 24.5% with them.
The churn comparison is effectively flat within this sample: 0.3% faster off,
1.0% slower on. That does not prove zero miss-path cost. Initial construction,
partially reused data and frequent structural changes need explicit production
coverage. Absolute costs differ between capture sessions; compare within each
matched experiment, not across separate tables.

A final bounded-cache CPU profile has 9,623 samples. RuntimeType is about 0.07%,
coordinate eligibility 6.6%, and LineController.updateElements 34.0% (inclusive).
The expensive type retrieval is replaced with identity/weak-target checks while
value validation remains. Fresh option cloning remains a small sampled component.

Separate GC-only captures show a modest change, not the main speedup: in equal
final-five-second windows, mean GC-labelled UI time is about 1.80→1.58 ms/frame,
while slowest-decile mean GC is about 2.48→2.45 ms. The primary gain is reduced
CPU classification work. GC intervals are unioned on the UI thread, excluding
background workers; no forced GC is requested. Heap accumulated counters equal
current counters, so snapshots are not allocation rates. Diagnostic timings
must not be added to or subtracted from the ordinary frame measurements.

## Compatibility and production gates

All six final variants (baseline, guard, numeric, fresh, combined and bounded)
pass the existing 54 focused point/indexed/line regressions. Extra diagnostic
cases compare ordinary/native projections over both axes, reversed scales,
aligned and unaligned pixels, null/NaN/integer values, active points and map
replacement. Cache tests cover live values, changed identity, resize and routed/
custom containers. Fresh-copy tests include missing/undefined/null/arbitrary
values, frozen sources, extra-key independence and key visibility. Extra counts
are 8 baseline, 11 guard, 8 numeric, 13 fresh, 16 combined and 11 bounded.

Before production adoption:

- Review the lifecycle and native-classification contract, including custom
  container/type-getter behavior and preservation of ordinary fallback reads.
- Keep per-pass classifier state distinct from the persistent weak identity slots;
  do not turn this into caching of coordinates, options or callbacks.
- Cover cache fill, growth/shrink, partial ranges, failures, active-point transitions,
  source replacement and mixed stable/churning datasets, including browser backends.
- Measure startup, memory overhead and the full native mode matrix on the final code.
- Keep data-only range/ordering eligibility unchanged; this work does not solve it.

The bounded prototype is the strongest candidate, but these are prerequisites
to shipping it. There is no claim that arbitrary callbacks or every configuration
now sustain 60 FPS.

## Artifacts and reproduction

metadata.json records the baseline library hashes, build hashes and scope.
summary.json preserves individual process rows, controls, uncapped replacement
results, bounded results, CPU functions and GC/frame intersections. Raw compressed
captures and visibility logs accompany them. Rejected development test attempts
remain distinguishable from the successful final checks.

Use an isolated copy at /tmp/indexed-triage-work with the pinned SDK/lockfile.
The saved baseline source hashes identify the starting library. Restore .txt
scripts under .dart_tool/indexed_triage. variants.py creates the source candidates;
its .before inputs are copies of the five baseline files named in that script.
Run the options generator after switching variants. guard/numeric/fresh/combined/
adaptive.patch preserve the exact source deltas, including generator changes.

The main build.py produces /tmp/indexed-triage-*.app. The churn-aware harness patch
and build_churn.py produce /tmp/indexed-churn-*.app. The saved native host selects
the display through BENCH_DISPLAY_ID; these runs use built-in display 1 at DPR2.
Sign temporary app copies with ../category-layout/probe.entitlements. Run frames.py,
churn_frames.py and adaptive_frames.py separately under caffeinate with builds and
tests idle. The capture/profile scripts run afterward. Extra tests are separate.
analyze.py and report.py regenerate summaries and verify unchanged production hashes.
