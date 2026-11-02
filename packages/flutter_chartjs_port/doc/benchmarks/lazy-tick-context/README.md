# Deferred tick-context evidence

2026-11-02. This is one focused follow-up to ADR 0064. Only core.scale.dart changes
at runtime; candidate.patch is relative to the fully validated label-plan code.
The other runtime source hashes were checked against axis-label-plan/runtime-hashes.json.
No numeric-range or additional label-loop optimization is included.

Apple M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, profile AOT, Impeller.
Use axis-pipeline-scan/probe.dart.txt, copied to .dart_tool/layout_pipeline_probe.dart
at repository root, and build from apps/chartjs_gallery with:

```
flutter build macos --profile -t ../../.dart_tool/layout_pipeline_probe.dart
```

Keep separate baseline/candidate app copies. Use the temporary signing recipe
from category-layout/README.md. Launch with PIPELINE_MODE=measure,
PIPELINE_N=20000, PIPELINE_VARIANTS=baseline,bounds,sample100,constant_font,draw_only,
and a unique PIPELINE_RUN name. The app writes /tmp/pipeline-$PIPELINE_RUN.jsonl.
The order is A/B/B/A; seven 200 ms batches follow 800 ms warmup. No builds/tests
run concurrently with timings. All results are retained in measurements.json.gz;
summary.json gives aggregate and paired figures. The protocol predates the run.

profile-before.json.gz contains a separate fresh 10-second capture of the baseline,
using PIPELINE_MODE=profile and the same VM-service procedure as axis-pipeline-scan.
It identified context allocation among the remaining costs. It is not a timing
comparison or a claim that all layout work has been removed.

The constant_font custom-scale control cannot hit the category measurement plan;
sample100 also does not take the full-list plan path. They retain the original
context accesses and are checked for the added Tick storage cost. Layout outputs
are compared exactly across all four runs. All user callbacks remain active.

Browser validation uses a temporary copy of axis_label_plan_test.dart without the
VM annotation, initializing the binding and registering built-ins explicitly.
The retained browser_probe.dart.txt reproduces it. Copy it to
`test/port/core/lazy_context_browser_probe_test.dart`, run flutter test with
`--platform chrome` and then `--platform chrome --wasm`, and remove the temporary
file before the normal import guard. validation.json records final checks.
