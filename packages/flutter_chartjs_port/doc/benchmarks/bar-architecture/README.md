# Architectural diagnosis

This is an isolation experiment, not a production optimization or a parity gate.
It compares full updates with a restricted values-only path, unchanged-data
updates, existing-chart drawing, and a raw native rectangle control. No production
library or gallery source was edited for this investigation.

Use the existing probe support from ../bar-native/ at `.dart_tool/bar_update/`.
Copy `probe.dart.txt` here to `.dart_tool/bar_architecture/probe.dart`, then from
the gallery build:

```
flutter build macos --profile -t ../../.dart_tool/bar_architecture/probe.dart
```

Copy the app to `/tmp/bar-architecture.app` and sign only that temporary copy as
in ../category-layout/README.md. Run once with `ARCH_RUN=a ARCH_REVERSE=0`, then
with `ARCH_RUN=b ARCH_REVERSE=1`. Results are `/tmp/architecture-a.jsonl` and
`/tmp/architecture-b.jsonl`. Seven 200ms batches follow 800ms warmup, N=800 and
20000, 800x480 DPR1, no builds/tests concurrently. These are CPU recording and
update timings, not raster timings or foreground FPS.

Both changing cases include data simulation and writes in the timed frame call.
The values-only prototype assumes a fixed category index, fixed linear bounds,
fixed layout/styles and positive numeric values. It writes bar y/height and draws.
It deliberately omits parsing, update hooks, option resolution and parsed-data
synchronization. It must not be exposed as a general chart.update replacement.
After each values-only case, every bar's x/y/base/width/height is compared with a
full update of that exact current data. All four checks match. This is geometry
verification for the restricted scene, not pixel/plugin/metadata parity.

At 20k, full-frame CPU is 20.198ms, values-only 10.521ms, unchanged-data update
18.538ms and draw-only 10.081ms. Full 800-item frames cost 1.508ms. The raw native
20k rectangle control costs 6.989ms, but uses opaque borderless prebuilt rects;
it is a lower-bound comparison, not an equivalent renderer replacement. The
existing chart still reports 20000 category ticks with both axes hidden.

The retained hypothesis is that an explicit values-only update contract and
change/version tracking have much greater potential than guarded local caching.
Resolution-aware overview rendering is a separate optional semantic choice.
Neither feature is implemented here, and no 60-FPS promise follows from these
CPU-only measurements. See performance.md §40 for the source audit and priorities.

## Prepared-data representation comparison

Build `prepared.dart.txt` instead, at `.dart_tool/bar_architecture/prepared.dart`.
Use a separate temporary app copy and the same ARCH_RUN/ARCH_REVERSE selectors.
Final files use `/tmp/architecture-prepared-clean-<run>.jsonl`. Three 20k cases
run forward/reverse: ordinary numeric input, parsing:false with ordinary x/y
Maps, and parsing:false with internal ParsedItem records. All include simulation
and data writes in the timed frame; prepared cases also copy the current numeric
values into their prepared objects, so their timing includes that extra loop.

The geometry check constructs a fresh ordinary numeric chart from the exact
current prepared values. All four checks match every bar. Earlier attempts to
change the existing chart from parsing:false to primitive parsing inside the
verification produced NaN geometry; those runs were invalidated and their error
logs are retained. Only the clean-reference runs are summarized.

Full-frame CPU: ordinary numeric input 19.003ms; prepared Maps 28.917ms;
internal prepared records 17.193ms. This is not advice to use private types.
It exposes a representation-dependent performance cliff: bulk numeric bar
updates require ParsedItem and fall back for ordinary prepared Maps. A coherent
supported native data contract should avoid this conflict between skipping
parsing and reaching the efficient update path.
