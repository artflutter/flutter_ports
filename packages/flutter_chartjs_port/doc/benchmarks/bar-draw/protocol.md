# Ordinary bar drawing protocol

Baseline: 1d37d64 plus the validated ADR 0066 canvas recording change. Retain
that runtime patch and hashes; compare separate profile-AOT apps on Apple M3 Max,
macOS 27.0.1, Flutter 3.47.8 / Dart 3.13.7, Impeller, 800x480 at DPR 1.

First measure scalar geometry for the exact built-in bar with resolved typed
options, typed skipped edges, scalar finite border width, zero radius/inflation
and finite ordinary bounds. Preserve the canvas calls and their order, with the
original code for unsupported input. Do not add a native canvas shortcut unless
further profiling and measurement justify its extra state contract.

Use A/B/B/A, seven 200ms batches after 800ms warmup. Primary: bar draw, looping
animation and update at N=1000/5000/20000. Controls at N=1000/5000: rounded bars,
fixed thickness/inflation, line, bubble and doughnut. Require >=10% full-call
improvement in each 20k draw/animation pair, no repeatable full-call control
regression over both 5% and 0.1ms. Keep all measurements. No builds/tests alongside
measurement. Separate foreground runs measure actual animation FPS with exact
process activation, not inferred FPS from CPU times.

Correctness: compare canvas-call traces and exact pixels against the unchanged
path (a subclass), including geometry extremes, orientation, skipped borders,
transparency, transforms, clips, styles/current path after draw, and fallbacks for
raw/custom objects, radii, inflation and non-finite inputs. Run VM workspace tests,
targeted JS/Wasm checks, fixtures, analysis, formatting, parity and port checks.
No macOS golden updates.
