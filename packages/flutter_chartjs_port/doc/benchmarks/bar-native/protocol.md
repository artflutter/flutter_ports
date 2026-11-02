# Native rectangular bar protocol

Baseline 5dafa22. Candidate: optional fused native rectangle/ring drawing after
existing scalar bar geometry. Keep the generic canvas sequence for unsupported
contexts, shapes, colors, transforms and any draw that can notify user code.
Preserve pixels, style/save state, current path, clip and fill accounting/order.

Apple M3 Max, macOS profile AOT, Flutter 3.47.8 / Dart 3.13.7, Impeller,
800x480 DPR 1. A/B/B/A, seven 200ms batches after 800ms warmup, no concurrent
builds/tests. Primary bar draw/update/animation N=1000/5000/20000. Require >=15%
full-call gain on both 20k draw pairs and no repeatable control regression over
both 5% and 0.1ms. Controls: rounded/inflated bars, other chart types, multiple
datasets, indexed stacks and scriptable colors. Keep every result.

Use exact pixel twins against a subclass taking the original path. Cover empty
and nonempty interiors, borders/transparency, all blend modes, transforms/clips,
subsequent path use, save/restore, callback mutation/reentrancy, chunk boundaries,
pending circles, snapshots/clears/disposal and unsupported styles. Run workspace,
targeted JS/Wasm, fixtures, analysis, format, parity and port checks. No goldens.
Measure actual foreground FPS separately, with process-activity monitoring.
