# Live bar update optimization evidence

2026-11-02. ADR 0068. Baseline includes ADRs 0066/0067; this comparison measures
additional update-path improvements, not the earlier drawing gains.

## Reproduction

The baseline is `1d37d64` plus `baseline.patch`. The candidate is `1d37d64` plus
`candidate.patch`, and `bar_index_layout.dart.txt` copied to
`packages/flutter_chartjs_port/lib/src/core/bar_index_layout.dart`. The full
candidate patch includes the earlier canvas/drawing changes shared by both sides.
`metadata.json` records final source hashes and the environment.

Copy `probe.dart.txt`, `native.dart.txt` and `controller.dart.txt` to
`.dart_tool/bar_update/` at repository root, removing `.txt`. The copied controller
is the legacy investigation prototype; none of the reported cases selects it.
From `apps/chartjs_gallery`:

```
flutter build macos --profile -t ../../.dart_tool/bar_update/probe.dart --dart-define=SECONDS=25
```

Keep separate apps at `/tmp/bar-update-a.app` and `/tmp/bar-update-b.app`, signed
using the temporary-app recipe in ../category-layout/README.md. The measured
baseline was built in an isolated copy at `/tmp/bar-update-baseline-workspace`;
the working tree was never reverted for that build. Use explicit selectors from
`measure.py.txt`, not the legacy generic `baseline` selector.

## Measurements and protocol

Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, arm64 profile AOT,
Impeller, 800x480 at DPR 1. The prewritten protocol is `protocol.md`.
A/B/B/A, seven 200ms batches after 800ms warmup, no concurrent builds/tests.
`measurements.json.gz` retains all final and preliminary timing results.
`summary.json` contains full calls, components and both pair changes.

Primary cases: bar update/draw/animation at N=1000/5000/20000. Controls include
rounded/inflated bars, line/bubble/doughnut, two datasets at N=1000/5000, and
indexed stacks (`skipNull`) and scriptable colors at N=100/1000. Each full call
sums update/tick, draw and paint/completion within its process first.

Both 20k update pairs exceed the 20% full-call improvement gate: 34.9% and 36.1%.
No control has a repeatable regression above both 5% and 0.1ms. Animation's first
20k pair increases 5.5% while the reverse pair decreases 3.7%; both are retained.
Drawing inside an update increases slightly, even as the full call improves.

The first candidate repeatedly inspected generic runtime types and was slower
(84.6ms update against 44.1ms). Its profile attributes 59.5% of samples to
runtimeType. The identity-classification version reduces update time to 26.6ms;
its second profile motivates reusing the proof across cached primitive trait
reads and constructing the property record directly. These preliminary runs are
retained but excluded from the final summary. Raw ten-second profiles are
`profile-initial.json.gz` and `profile-identity.json.gz`; the capture scripts and
`profile.dart.txt` reproduce them with adapted local paths.

The final proof still observes both upstream topology points. It reuses the
first result only when the intervening trait computation is proven callback-free
from cached primitives. Values are never cached across user callbacks. This
refines the original protocol's two-read wording without weakening its behavior
or performance gates.

## Foreground frames and limits

`stress.py.txt` runs the actual StressProfileApp for 25 seconds per case at
N=20000/M=0, activating the exact process with NSRunningApplication. Every run
logs `active=true`; the summaries exclude startup. `stress-*.log` retains all
one-second windows and timing summaries, and `stress.json` contains parsed data.
There are 24–25 complete windows per run.

Foreground updates improve from 16.59 to 23.97 FPS. Average update work falls
42.87 → 21.95ms and average Flutter build 56.88 → 37.55ms. Animation remains
about 60 FPS (59.90 → 59.81). These are one process per cell on this Mac.
Continuous 20k updates still do not reach 60 FPS; drawing, parsing and the
remaining per-item update work exceed a 16.67ms budget. No mobile/web performance
claim is made.

## Correctness

The permanent `test/port/controllers/bar_index_layout_test.dart` compares against
a Chart subclass that disables the capability. It covers live data, options,
visibility, dimensions, dataset count, both orientations, typed/raw sources,
custom containers/scales, routed ids, cold caches, numeric key ordering,
scriptable mutation between observations, reentrant updates, numeric sorting and
property-record key/presence/foreign state. Existing bar specs/references and
workspace tests also run.

For browser checks, copy `browser_probe.dart.txt` temporarily to
`test/port/controllers/bar_update_browser_probe_test.dart`, run it with
`flutter test --platform chrome` and then `--platform chrome --wasm`, and remove
it before repository checks. `validation.json` and compressed logs record the
final outcomes. No golden image is changed.
