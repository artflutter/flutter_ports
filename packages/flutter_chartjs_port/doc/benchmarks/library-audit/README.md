# Library-wide audit evidence

2026-11-03. [Findings](../../library-performance-audit.md). No production runtime
change. `metadata.json` identifies the commit, library source hash, supporting
source hashes, toolchain, timing protocol and verification.

## Files

- `forward.json`, `reverse.json`, `summary.json`: the existing chart cases at
  N=1000/5000, in two process sweeps. All eight types are represented. Line has
  static, alternating scriptable/indexed, and primitive-parsed controls.
- `controlled-{0,1}.json`, `controlled-summary.json`: static, single-entry
  indexed and constant-callback background colors on line/bar/radar, N=5000.
- `datasets-{0,1}.json`, `datasets-summary.json`: fixed 5000 points divided among
  1/10/100/500 line datasets, with static options and no plugins/animations.
- `profile-*.json.gz`: seven raw `getCpuSamples` responses, separate from timing.
  The `*-summary.json` companions retain functions with nonzero sample counts.
  `inclusive` overlaps with child functions; `self` is exclusive.
- `alloc-*.json.gz`: six before/after allocation-profile responses around 20
  updates of 5000 points, after 50 warmup updates. **Not valid allocation-rate
  evidence:** accumulated bytes equaled current bytes for every class. These
  are retained to document the attempted check, not presented as bytes/update.
- `*.dart.txt`, `*.py.txt`: source snapshots. The baseline entry was used for
  the original timings and five profiles; the extended entry adds controlled
  cases, many datasets and the allocation service extension.
- `verify_test.dart.txt`: temporary Flutter test, passed. Checks all element
  parsed values, selected geometry and selected colors/radius/border widths
  after three synchronized changes for the nine same-color configurations.
  This is not a raster comparison or a test of any proposed optimization.

## Reproduction

Restore the sources into `<repository>/.dart_tool/library_audit/`, dropping the
final `.txt` suffix. `baseline_probe.dart.txt` becomes `probe.dart` for the first
build. Keep `extra.dart`, `capture.dart`, `alloc.dart` and the Python launchers
beside it. Python launchers derive the repository root from that directory.

From `apps/chartjs_gallery`:

```
flutter build macos --profile -t ../../.dart_tool/library_audit/probe.dart --no-pub
```

Copy the resulting `build/macos/Build/Products/Profile/chartjs_gallery.app` to
`/tmp/chart-library-audit.app`. Follow the temporary-copy entitlement/signing
recipe in [category-layout](../category-layout/README.md) (allow-jit and
network.server, without the app sandbox). Keep repository app signing unchanged.
The executable name is `Contents/MacOS/chartjs_gallery`.

From the repository root, on an otherwise idle machine:

```
python3 .dart_tool/library_audit/run.py measure
python3 .dart_tool/library_audit/run.py profile
```

Then restore the extended `probe.dart.txt` as `probe.dart`, rebuild with the same
command, and copy/sign it separately as `/tmp/chart-library-audit-extra.app`.
Run sequentially:

```
python3 .dart_tool/library_audit/run_extra.py measure
python3 .dart_tool/library_audit/run_extra.py alloc
python3 .dart_tool/library_audit/profile_extra.py
python3 .dart_tool/library_audit/summarize.py
```

From the gallery directory, after all measurement is finished:

```
flutter test ../../.dart_tool/library_audit/verify_test.dart --no-pub --reporter expanded
```

Launchers overwrite only their own working artifacts in `.dart_tool/library_audit`;
the committed evidence here is not overwritten. They terminate their own profile
processes after collection. `run.py` parses both plain and `flutter:`-prefixed log
lines; the initial run's JSON files were reconstructed from the logs after fixing
that prefix parser. No timed loop changed.

The timing summary is the arithmetic mean of each process's batch median, per
phase. The full CPU estimate sums those phase medians per process before averaging.
CPU captures enable sampling, wait five seconds after service connection, clear
samples, then collect ten seconds. Captures include source-data mutation; phase
timings do not. Do not compare CPU percentages to exclusive phase timings as if
they were identical denominators.

No FPS, foreground-frame, GPU/raster, mobile or web claim is made. Profile AOT
allows VM-service sampling, but its absolute overhead need not match release.
The ordinary full-update workload is deliberately retained even though eligible
callers can use the existing `updateData()` API.
