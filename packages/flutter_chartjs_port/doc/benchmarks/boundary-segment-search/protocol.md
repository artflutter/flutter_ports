# Boundary segment matching: Android protocol

Baseline: e942d50, including exact endpoint interpolation. Candidate: a scoped
cursor for exact target segment bounds on the same private constant boundaries.
No approximation, no retained chart cache and no new segment implementer.

Profile the baseline first. If boundary matching remains material, use the same
release harness as chapter 24: Pixel 8a, arm64 release, profiler off, A/B/B/A,
two fresh processes per variant. Ten cells: ordinary line draw/update, radar
fill draw/update and stack fill draw/update at N=1000, then gap fill draw/update
at N=100 and N=1000. Three datasets in each fill case; 800 x 480 canvas, DPR 1.
Nine 150 ms batches after 500 ms warmup per cell. Controls precede gap fills.
No builds or tests alongside timing. Preserve all completed runs and source hashes.

Primary criterion: a material N=1000 gap-fill gain in both pairs, with no
repeatable control slowdown exceeding both 0.1 ms and 5%. Small shifts are
inconclusive; two pairs do not provide confidence intervals. CPU metrics sum
per-process medians of draw + recording completion, plus update for full updates,
then take the median across the two processes. No GPU/FPS claim.

Require battery temperature at most 34 C at each start. Record battery and
thermal status before and after every run. Preserve any incomplete run metadata;
never remove a run based on its timing. Baseline profiling is separate: a 15 s
startup delay, 1 s warmup, 30 batches of 500 ms, VM CPU sampling.

Correctness: compare exact target bounds and complete fill parts against original
boundSegments/segments; exercise reordered/repeated ranges, misses, epsilon,
non-finite and reversed bounds, both axes and changing source geometry. Preserve
original native segment type/style/loop fields and every chart draw command.
Run VM/web tests, fixtures, public API, analysis, formatting and port checks.
