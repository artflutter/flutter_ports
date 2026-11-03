# ChartValue background-color prototype

2026-11-03. [ADR 0077](../../adr/0077-background-chart-value.md),
[performance.md §43](../../performance.md#43-sealed-background-color-api-prototype).
This experiment changes only Dataset.backgroundColor in the typed API.
The recorded candidate is the background-only API at commit `e0fe0bc`. The later
border-color migration is outside this comparison; use that revision for these
exact probes, or wrap their border colors with ChartValue.constant when adapting
them to the current API.

## Evidence

- `a1/b1/b2/a2.json`: original process results, baseline/candidate/candidate/baseline.
- `summary.json`: mean process medians and individual paired changes.
- `baseline-metadata.json`: the pre-prototype library hash. This baseline includes
  the already-implemented ADR 0076 indexed optimization; plain HEAD alone does not.
- `metadata.json`: candidate library identity, toolchain, protocol and limits.
- `candidate.patch`: typed-library migration relative to HEAD, plus widget docs.
  Install the new `chart_value.dart.txt` source separately; the patch does not
  include that previously untracked file. Retain the prior ADR 0076 core changes.
- `baseline_probe.dart.txt` / `probe.dart.txt`: old/new public API entry points.
  They differ only in background-value construction. Other chart settings match.
- `chart_value_test.dart.txt`: the 20-case value/Opt/equality/copyWith regressions.
- Compressed validation logs: typed and workspace suites, public API, README/
  gallery callers, browser probes, analysis and parity. Completion is recorded
  in `validation.json`.

Construction/lowering is an isolated microbenchmark that consumes ownKeyCount.
Its sub-microsecond differences are not a frame-time claim. The other stage
updates and paints an existing chart with unchanged data, including recording
completion/disposal. It excludes data writes, config lowering/reconciliation,
widget work, GPU/raster time and vsync. Color.toString diagnostics in profile
mode are not a correctness comparison. The normal typed/raw twins check values,
geometry and callbacks separately.

## Reproduction

Restore the chosen probe as `.dart_tool/chart_value/probe.dart` at the repository
root. For the baseline, restore the pre-prototype typed API while keeping the
indexed core optimization. From `apps/chartjs_gallery`:

```
flutter build macos --profile -t ../../.dart_tool/chart_value/probe.dart --no-pub
```

Keep separate copies of the baseline and candidate applications at
`/tmp/chart-value-a.app` and `/tmp/chart-value-b.app`. Use the temporary-copy
[category-layout entitlement/signing recipe](../category-layout/README.md).
Do not change production app signing. Restore measure.py/report.py from their
`.txt` snapshots into `.dart_tool/chart_value/` and run from the repository root:

```
python3 .dart_tool/chart_value/measure.py
python3 .dart_tool/chart_value/report.py
```

The script writes only its working artifacts in `.dart_tool/chart_value`.
No tests or builds should run alongside timing.

The permanent typed tests are VM-tagged because they import the framework-facing
app API. Browser verification copies chart_value_test.dart under the package's
test root, removes only `@TestOn('vm')`, runs it with `--platform chrome` and then
`--platform chrome --wasm`, and removes the temporary copy before import checks.
Flutter's web test compiler cannot resolve this probe from outside the test root.
