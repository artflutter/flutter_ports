# Incremental data update protocol

Production Chart.updateData versus chart.update('none') in the same profile
binary, with the same data generation included in each timed frame. Existing
full updates must retain behavior and stay within repeatable 5%/0.1ms regression
limits against the prior binary. No builds/tests during measurements.

M3 Max, macOS 27.0.1, Flutter 3.47.8/Dart 3.13.7, arm64 profile AOT/Impeller,
800x480 DPR1. Seven 200ms batches after 800ms warmup, forward/reverse case order.
Measure all eight chart types at 1k and bar/prepared-bar at 5k/20k. Require at
least 15% full-call savings in both 20k numeric-bar pairs, with every warmed
incremental call selecting the intended path. Report all types, including cases
where drawing dominates. Verify complete parsed data and element geometry
against a subsequent full update of the same data after every incremental case.
Measure actual foreground update FPS separately with activity monitoring.

Run reference twins for all types, fresh metadata, interaction/tooltip state,
stacks, typed input, data replacement, options/shape/resize invalidation,
plugin opt-in/cancellation/errors, custom components and dynamic-style fallback.
VM and both browser backends must pass. Finish workspace, fixtures, formatting,
analysis, public API, parity and port checks. No golden images are rewritten.

## Refinements discovered by the first comparison

The original line/scatter stress preset uses suggested (automatic) x bounds;
those runs correctly selected full fallback. Supported fixed-range comparisons
use a sorted, fixed x index in [0,1] and explicit bounds. Original automatic-range
presets remain separate fallback controls. Both compared calls use the same
fixed-point scene, including its data writes.

The first implementation rescanned every record on every call and missed narrow
prepared-Map list types in the older bar bulk guard. Retain those results as
preliminary. The corrected implementation validates a source array once per
full-update generation/replacement and trusts its documented numeric-only
mutation contract; native prepared lists reach the bulk updater.

Initial FPS runs were inactive. macOS reported loginwindow as frontmost, so no
background-run figures are accepted as foreground FPS evidence.
