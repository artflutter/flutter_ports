# Stack search: guard diagnosis and revised comparison

This follows the initial failed guard comparison in the parent directory. Both
initial evidence and the measured original candidate B are retained there.
[Performance report](../../../performance.md#23-stacked-fill-exact-point-experiment)
and [ADR 0058](../../../adr/0058-stack-exact-point-search.md) describe the outcome.

The initial Chrome gap case followed radically different amounts of stack work.
A targeted fresh-process A/B/B/A run with only the gap case found +0.54% draw time
and +0.51% full-update time, rather than the initial +10.3%/+5.2%. This supports
workload-order sensitivity of the short benchmark. It does not establish a
specific GC/JIT cause. Two query-selection setup attempts executed the wrong cell
count and failed validation; they are not pooled with this comparison.

Candidate C additionally removes the synthetic LineElement used only to obtain
its segment runtime type. An internal constant gives that identity directly;
existing interpolation, segment-scanning and radar algorithms are unchanged.
This cleanup is separate from the evidence about benchmark ordering.

The final A/C/C/A comparison places gaps, radar and ordinary-line controls before
stacked fills. Settings remain 250 ms warmup and seven 100 ms batches. The current
source matches the four measured source-file hashes in metadata.json. Exact point
lookup keeps the large stack gain; remaining guard shifts are small in absolute
time and inconclusive in two pairs. No zero-regression, GPU/FPS or mobile claim.

`measurements.json.gz` contains all eight final process records;
`isolated-gaps.json.gz` contains the four original-candidate diagnostic runs.
`summary.json` includes individual process medians. Recompute with:

```sh
python3 report.py --recorded
```

Reconstruct A, original B, and revised C in an empty directory, with the pinned SDK:

```sh
python3 setup.py --repo /path/to/flutter_ports --out /private/tmp/stack-revision
cd /private/tmp/stack-revision
python3 build.py
python3 run_macos_final.py
python3 run_chrome_final.py
python3 report.py
```

`run_isolated_gaps.py` reproduces the diagnostic using A and B. Run it separately
from timing on other platforms. The final benchmark and diagnostic are different
series and must not be pooled. Chrome uses release Wasm and a local result receiver;
no browser-URL selection is needed for the diagnostic because it uses GUARD_ONLY.
