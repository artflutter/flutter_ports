# The curve and the markers of a dense line draw

These files are the evidence of [performance.md](../../performance.md) §66 and of Chart.js ADR 0104.

The runs used an Apple M3 Max, the built-in 120 Hz display, DPR 2, Flutter 3.50.0-0.4.pre with Impeller and a
native macOS profile build. The driver is `apps/chart_benchmark_lab/tool/perf_matrix.dart`, with 4 cells: line, scatter,
bubble and radar at 20,000 items with the full preset. Each cell has 2 seconds of warmup and 4 seconds of capture.

- `old-1.txt` and `old-2.txt` are two passes of a library equal to the library of commit `aed5829`.
- `new-1.txt` and `new-2.txt` are two passes of commit `1cacd10`.

The order was old, new, new, old. The Mac was in use by day, with the screen unlocked. The flag `MATRIX_IGNORE_COVER=1`
and the process argument `-NSAppSleepDisabled YES` were set, so that a covered window does not stop the capture. The
two old passes differ by up to 6% in line and by up to 8% in radar. Two runs for each side are a weak interval.
