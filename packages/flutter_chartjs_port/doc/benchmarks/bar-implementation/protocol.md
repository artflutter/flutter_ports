# Bar implementation protocol

Baseline: commit 1d37d64, the investigated runtime. Compare isolated profile-AOT
macOS apps compiled from one harness against candidate production code. Keep
source hashes/patches. Apple M3 Max, Flutter 3.47.8, Impeller, 800x480 at DPR 1.
No builds or tests alongside measurement. Seven 200ms batches after 800ms warmup.

Run A/B/B/A with bar update, draw and looping animation at N=1000/5000/20000.
Controls: line update/draw, bubble update, doughnut draw and fixed-thickness bars
at N=1000/5000. Judge full calls (update+draw+host paint/record completion) per
process. Require at least 30% improvement on both 20k draw/animation pairs, and
20% on both update pairs. Reject repeatable control regressions above both 5%
and 0.1ms; investigate noisy controls separately rather than discarding results.
Use fresh foreground 25-second stress runs to report actual FPS separately.

Correctness: canvas pixel twins spanning splits, clips/transforms, partial clear,
compositing, gradients/patterns, text/images, pending circle batches, snapshots,
flattening and resize. If adding a bar-index plan, it must preserve custom
containers/getters/controllers/scales and mutations; no unguarded memo is eligible.
Run relevant tests, full VM package suite, fixture runner, analysis and port checks.
Do not update platform-pinned golden images on macOS. Retain all measurements.
