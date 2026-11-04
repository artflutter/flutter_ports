# Estimates for the next three line-chart improvements

2026-11-04. Native M3 Max, macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7,
profile AOT, Impeller MetalSDF. Baseline: the existing ADR 0082 working tree.
**This is an investigation, not a production implementation. Library sources
in the working tree are unchanged.**

## Three proposals

1. **Varying-color-only traversal** (`varying`). Precompute the ordered varying
   keys and visit them instead of walking every static option key for each
   point. A callback or store that invalidates the raw plan resumes ordinary
   resolution at the next original key, preserving later static-field changes.
2. **Separate scalar callback path** (`scalar`). A context-only callback with a
   native scalar result avoids constructing the closure/descriptor environment
   for exceptional resolution. The plan captures already-cached descriptor
   inputs. Non-scalar returns and mutations enter a separate continuation with
   fresh views and the original descriptor snapshot; callbacks are not repeated.
3. **Native point drawing** (`entry`). Eligible built-in circle points enter a
   specialized native method. It retains the existing style setters, path
   construction, fill/stroke order and CircleBatch. It bypasses general marker
   dispatch and repeated fill/stroke classification. Prototype guards restrict
   it to native sRGB colors, supported transforms, positive finite dimensions,
   no dashes, source-over and global alpha 1.

The renderer already uses ordered atlas batching. A separate `packing` probe
reuses quantized centers for consecutive equal fill/stroke positions. It shows
little benefit and is excluded from `best`. `best` combines proposals 1, 2 and
the native entry, without packing.

## Controlled estimates

20,000 items, 800×480/DPR1. Each row averages two independent process medians;
full CPU is update + draw + paint-end medians, not a combined-call percentile.
Data generation is outside the CPU stopwatches. Each cell uses 700 ms warmup
and seven calibrated batches of approximately 160 ms.

The initial runtime-switch experiment introduced meaningful overhead, so the
primary results use separate binaries with compile-time switches. Variants run
in forward/reverse order with static/indexed controls and draw-only controls.
No builds, tests or profiling run concurrently with the timing processes.

| Variant | Connections off: ms | Saved | Connections on: ms | Saved |
| --- | ---: | ---: | ---: | ---: |
| baseline | 22.21 | 0.00 ms / 0.0% | 26.18 | 0.00 ms / 0.0% |
| varying | 19.82 | 2.39 ms / 10.8% | 24.60 | 1.58 ms / 6.0% |
| scalar | 18.46 | 3.75 ms / 16.9% | 24.24 | 1.94 ms / 7.4% |
| entry | 17.00 | 5.21 ms / 23.4% | 24.60 | 1.58 ms / 6.0% |
| packing | 21.95 | 0.26 ms / 1.2% | 25.79 | 0.38 ms / 1.5% |
| best | 13.73 | 8.48 ms / 38.2% | 19.62 | 6.56 ms / 25.1% |

These percentages are relative to the specialized all-off baseline. The actual
unchanged-library control averaged about 22.34 ms disconnected and 27.63 ms
connected, versus 22.21/26.18 ms for that specialized baseline. Both controls and
all individual runs are retained; small differences should not be overinterpreted.

The combined result is measured directly, not obtained by adding percentages.
Full-update component costs can move between update/draw as allocations and GC
interact. The native drawing entry also reduces draw-only CPU from approximately
3.36 to 2.62 ms for static colors, and 3.93 to 3.18–3.20 ms for indexed/scriptable
colors. Packing alone leaves draw-only CPU essentially unchanged.

## Behavior and rendering checks

- 114 existing resolver/owned-result regressions pass across the varying-only,
  scalar-only and combined variants.
- 15 additional tests cover two varying color callbacks, later static-field
  mutation, descriptor changes, index mutation and array returns.
- All counted variants execute 20,006 color callbacks per full update in this
  workload. No callback-result caching or point removal is used.
- After a two-second startup warmup, 300 native RGBA comparisons match exactly
  across DPR1/2, three radii, three border widths, two alpha levels, static/indexed
  colors, overlapping/off-canvas points, rotation and non-uniform fallback.
  The last path is filled/stroked again to exercise retained path/state behavior.
- Packing coordinates match the original arithmetic. Identity-transform variant
  atlas command buffers also match during the warmed checks.

An earlier cold-start check differed in the first small-circle scene for all
three drawing variants, while subsequent scenes matched. The warmed result does
not erase that discrepancy. It remains an implementation/renderer-validation
question before shipping a drawing change. These checks do not replace the full
canvas/fixture/golden/browser suite or broader custom-component compatibility.

## FPS and decision

The optional native frame check received no frame callbacks: every baseline row
had zero samples. Those rows are rejected, retained separately, and are not
reported as zero FPS or used to infer a frame-rate improvement.

The combined CPU estimate is promising for an unconnected 60 Hz case, but its
13.7 ms omits host/data-motion/raster costs. The connected result, about 19.6 ms,
already exceeds 16.67 ms before host overhead. **No 60 FPS claim is established.**

Recommended order: implement and validate 1+2 together, then the native-circle
entry behind an explicit backend capability and complete renderer checks.
Packing is low priority. Proposal 1 is relatively small; proposal 2 needs careful
cold-path and descriptor-snapshot handling; proposal 3 has the largest renderer
integration burden despite its useful CPU upside.

## Reproduction and evidence

Use a separate copy of the current working tree with the pinned lockfile and
SDK. Apply prototype.patch there, and restore color_estimates.dart.txt under
packages/flutter_chartjs_port/lib/src/core/color_estimates.dart. Restore the
saved probe/runner files under .dart_tool/three_estimates, removing .txt.
Production sources must not receive the experiment module or prototype patch.

`build_const.py` builds independent baseline/varying/scalar/entry/packing/best
apps. Its compile-time defines and binary hashes are recorded in metadata.json.
Restore the saved temporary MainFlutterWindow.swift.txt only in the isolated
copy for the frame probe. Sign temporary app copies using the
[category-layout recipe](../category-layout/README.md).
Run `caffeinate -diu python3 .dart_tool/three_estimates/run_const.py` with other
assistant work idle. The historical clean-control app is the preceding production
build; baseline_probe.dart.txt is its source. Runtime-switch exploration is
retained separately from the specialized results.

measurements.json.gz contains all accepted CPU rows. summary.json is the primary
comparison. Pixel, callback-count, regression and rejected-frame evidence are
separate. The raw prototype is not presented as a ready-to-merge patch.

## Follow-up: production resolver implementation and startup check

The [ADR 0083 production pass](../color-resolution/README.md) implements proposals
1 and 2. Four independent native startup sequences (baseline/prototype/prototype/
baseline) reproduce the cold-to-warm pixel transition in both renderer paths.
Each matched stage has identical pixels and commands. The earlier difference
therefore does not establish a prototype-specific rendering defect. The engine
startup cause remains unidentified; production renderer integration and its
full validation are still separate work.
