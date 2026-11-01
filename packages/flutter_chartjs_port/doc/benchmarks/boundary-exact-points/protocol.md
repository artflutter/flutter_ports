# Android boundary endpoint experiment

Baseline: `3441804` (the tree before this task). Candidate: private constant-boundary
endpoint search only. No shared interpolation, segment scanner or canvas changes.

Pixel 8a, serial 4B071JEKB17363, release arm64 APK, Flutter 3.47.8 / Dart 3.13.7.
Separate app ID `dev.artflutter.gap_fill_bench`. A/B/B/A, fresh processes,
nine 150 ms batches and 500 ms warmup per cell. Ten cells: radar draw/update,
ordinary line draw/update, stack draw/update at N=1000, then gap draw/update
at N=100 and N=1000. Three datasets for fills. Guard cases run first.
No builds or tests alongside timing. Record all runs and APK hashes.

Metric: sum of per-process medians for draw + recording completion, or update +
draw + completion; compare the median across two processes per variant. These
are CPU timings, not GPU raster times or FPS. Two pairs show direction only.

Primary question: material gap-fill gain at N=1000 in both run pairs, with no
repeatable guard slowdown exceeding both 0.1 ms and 5%. Smaller changes remain
inconclusive. No confidence interval is inferred from two pairs.

Battery temperature must be at most 34 C before each launch. Record battery and
thermal state before/after; wait for cooling if needed. Retain failed or incomplete
run metadata and do not discard a run based on its timings.

The baseline CPU profile is separate from release timing: 30 batches of 500 ms
with 1 s warmup, a 15 s startup delay, and VM CPU sampling.
