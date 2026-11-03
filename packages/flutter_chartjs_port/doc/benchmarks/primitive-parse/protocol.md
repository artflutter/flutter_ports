# Numeric/category parsing protocol

Baseline: 65fc68f, including native rectangular bars. Candidate: guarded numeric
primitive parsing shared by bars and the base dataset controller. Keep fresh
parsed records and original key order, null/nonfinite handling, live label/data
changes and ordinary fallback reads/conversions. No cross-update cache.

Same harness as ../bar-native/: Apple M3 Max, macOS profile AOT, Flutter 3.47.8 /
Dart 3.13.7, Impeller, 800x480 DPR1. A/B/B/A, seven 200ms batches after 800ms
warmup, no concurrent tests/builds. Primary update N=1000/5000/20000. Require at
least 8% full-call improvement in both 20k pairs. Controls include draw/animation,
line/bubble/doughnut, multiple datasets and scriptable/indexed bars; reject a
repeatable regression above both 5% and 0.1ms. Keep every run. Measure foreground
update FPS separately; require all activity samples true for reported runs.

Activation and reference twins cover bars/lines and both orientations, fresh
records/key order, partial ranges, null/nonfinite values, signed zero, missing
and duplicate labels, stacked datasets and live mutations. Unsupported/custom
scales/containers/conversions must retain ordinary parsing. Run VM/browser,
fixtures, analyzer, formatter and port/parity checks. No goldens are rewritten.
