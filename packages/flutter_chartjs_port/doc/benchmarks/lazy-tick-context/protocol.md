# Deferred tick-context protocol

Baseline: the fully validated ADR 0064 implementation. Candidate: only deferred
context construction after a label-plan hit. No numeric-range or label-loop changes.

Apple M3 Max, macOS profile AOT, Flutter 3.47.8 / Dart 3.13.7, 800 × 480, N=20000.
Use the axis-pipeline-scan probe, with baseline, bounds, sample100, constant_font
and draw_only. Seven 200 ms batches follow 800 ms warmup. Order A/B/B/A; retain all
runs. Do not run builds/tests concurrently with timings. Require at least 10% less
layout CPU in each primary pair, equal layout outputs, and no repeatable control
regression exceeding both 5% and 0.1 ms of full-call cost. The unsupported/custom
scale case matters because it cannot use the deferred-context path.
