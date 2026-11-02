# Element option cache-key reuse: Android protocol

Baseline: 6197449, the direct Flutter Color core. Candidate: retain one last
(element type name, resolved mode, joined key) triple per DatasetController.
Do not memoize option results or skip element-id conversion. Keep the original
joined-string dictionary and its collision behavior.

Pixel 8a, Android 17, Flutter 3.47.8 / Dart 3.13.7, release arm64, profiler off.
A/B/B/A, two fresh processes per variant. Nine 150 ms batches after 500 ms warmup.
No builds or tests alongside timing; retain every run and source/APK hash.
Temperature at most 34 C at launch, with battery and thermal state before/after.

Fifteen cells, guards first:
- Ordinary line draw N=5000; bar and radar draw N=1000; bubble draw N=5000;
  gap fill draw N=1000; shared line update N=5000; scriptable line update N=1000;
  tooltip hover frame N=1000 (first gallery variant).
- Bubble and unshared scatter updates at N=1000 and N=5000.
- Polar area and radar updates N=1000, bar update N=5000.

Primary: bubble and unshared scatter update CPU time at N=5000 must decrease by
at least 5% in both pairs. Also report the full update+draw+completion total.
No primary or guard full-call total may show a repeatable increase exceeding
both 0.1 ms and 5%. Other counts and cases provide context, not additional primary
acceptance gates. Two pairs show direction only; no confidence interval or GPU/FPS
claim. Values are medians across the per-process medians (sum the relevant
per-process components first). Do not discard a run because of its timing.

The baseline CPU profile is separate: bubble update N=5000, 15 s startup delay,
1 s warmup and thirty 500 ms batches. Five new semantic tests are checked against
the unchanged baseline before implementation, then against the candidate.
