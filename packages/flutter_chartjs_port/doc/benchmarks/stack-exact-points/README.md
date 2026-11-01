# Exact-point stacked-fill experiment

This is the initial candidate B and its historical failed guard check. See
[the revision](revision/README.md) for the diagnosis and updated implementation.

Design and limits: [ADR 0058](../../adr/0058-stack-exact-point-search.md).
Results: [performance.md §23](../../performance.md#23-stacked-fill-exact-point-experiment).

**Not accepted for release.** Aligned stacked-fill drawing improved by about 97%
on both targets, but Chrome gap-fill draw time increased by 10.3% in both candidate
processes. The smaller macOS radar regression also repeats. All data are retained;
no runs were discarded or tuning series pooled into these results.

`measurements.json.gz` contains eight process records, 80 cells, their timing
summaries, native executable hashes and the browser backend/user agent.
`summary.json` retains the process medians and the combined comparison.
`metadata.json` pins the baseline, SDK and the two measured candidate source hashes.
`candidate.patch` reconstructs exactly those two files. The working source matched
the benchmark snapshot byte-for-byte at collection.

Recompute the recorded summary:

```sh
python3 report.py --recorded
```

Reproduce in a new empty temporary directory with the pinned Flutter SDK:

```sh
python3 setup.py --repo /path/to/flutter_ports --out /private/tmp/stack-rerun
cd /private/tmp/stack-rerun
python3 build.py
python3 run_macos.py
python3 run_chrome.py
python3 report.py
```

Run the two platforms sequentially, with no builds or tests during measurement.
Chrome runs release Wasm through the Flutter CLI and returns results to a local
HTTP receiver. Each platform uses A/B/B/A, two processes per variant. Each cell
warms for 250 ms and measures seven batches targeting 100 ms. The primary stacked
fill cells use N=100 and N=1000, draw and full update. Gap fill, radar and ordinary
line controls use N=1000. Every scene comes from the existing gallery harness.
The exact-matching shortcut is enabled only in B; shared interpolation, segment
helpers and radar sources are unchanged.

This is CPU-side chart work, not a raster/FPS result. The experiment is deliberately
small and has no confidence intervals or mobile measurements. Unsupported and
unaligned inputs retain the original algorithm and were checked for correctness,
not benchmarked. The guard regressions require diagnosis before any merge decision;
this evidence does not identify their cause.
