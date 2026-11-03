# Sequential bar spacing evidence

Outcome: position reuse was rejected and removed; the sorted-value scan is
retained. Baseline: 3d10094, including numeric category parsing. The protocol was recorded
before measurement. Step 1 is completed and measured before implementing step 2.

Use the unchanged harness from ../bar-native/: copy `probe.dart.txt`,
`native.dart.txt` and `controller.dart.txt` to `.dart_tool/bar_update/`, dropping
`.txt`. Build from the gallery with:

```
flutter build macos --profile -t ../../.dart_tool/bar_update/probe.dart --dart-define=SECONDS=25
```

Keep `/tmp/primitive-parse-final.app` as baseline, `/tmp/bar-spacing-one.app` as
the rejected step-one prototype and `/tmp/bar-spacing-two.app` as the independent
sorted-value change. Sign only these temporary
copies as described in ../category-layout/README.md. Each `measure_*.py.txt`
selects its own app pair and writes unique result files. No tests or builds run
alongside measurements. Full calls sum update, draw and completion medians
within each process, then average the two process results per side.

## Step 1 attempts

The initial copied-index approach had an inconsistent pilot. Its patch, source
hashes and pilot rows are retained as `step-one-initial*`. The broader refinement
also used a numeric spacing loop, but its full 20k update regressed
19.735 → 20.081ms (1.8%); both pair changes were positive. It was rejected.
Its patch, hashes and helper are the `broad-*` files; all results are in
`spacing-one/`.

An allocation-free version with separate validation and spacing loops was also
below the gate; its complete results are in `spacing-one-final/` and its sources
are the `separate-*` files. The final step-one candidate fuses those two loops. It
validates native contiguous indexes while filling the existing pixel array;
other index layouts retain ordinary projection. State and complete index values
are checked again after the original callbacks/value gathering. Apply
`step-one.patch` to the baseline and install `bar_pixel_reuse.dart.txt` at
`lib/src/core/bar_pixel_reuse.dart`. `step-one-hashes.json` identifies this source.
The same helper before specialization is `broad-bar_pixel_reuse.dart.txt`, used
with both earlier patches.

The pixel browser probe is a temporary copy of the VM regression test without
its VM annotation. Run it using `flutter test --platform chrome`, then `--wasm`,
and remove it before static/port checks. The artifact `pixel_browser_probe.dart.txt`
retains the exact probe. No golden images are rewritten.

## Position reuse decision

Rejected. The fused pilot improved, but its first complete full-workload pair
regressed 20.511 → 20.898ms. The run was stopped once the acceptance gate could
no longer pass. `step-one-fused-measurements.json.gz` retains completed and
partial groups. Production source and its test were restored to baseline; the
prototype regression test is retained as `bar_pixel_reuse_test.dart.txt`.
Step 2 is measured independently against the original baseline, not this
rejected prototype. No position-reuse code is included in the final library.

## Retained sorted-value scan

Apply `step-two.patch` to the original baseline, then install
`bar_sorted_values.dart.txt` at `lib/src/core/bar_sorted_values.dart`.
`step-two-hashes.json` records the complete final library hashes. The helper is
also a framework-free root in the import checker, keeping its tests in both
regular web suites. Measurements are in `spacing-two/`.

Full 20k updates improve 20.100 → 19.620ms (2.4%); both pairs pass the 2% gate
(2.3%, 2.5%). Dataset updating falls 5.232 → 4.615ms (11.8%). No control exceeds
the repeated 5%/0.1ms threshold; animation CPU moves +4.6% overall and is retained
in the table, without asserting a causal relationship for each timing shift.

Foreground updates improve 39.06 → 42.87 FPS, build 22.13 → 20.90ms; animation
stays 59.92 → 59.96 FPS, build 13.77 → 14.12ms. All four processes remain active
at every check and yield 24 windows. These are local single-process observations,
not a mobile/web performance claim or proof of 60-FPS updates.
