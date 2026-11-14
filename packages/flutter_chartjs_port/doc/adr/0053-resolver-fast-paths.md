# Chart.js ADR 0053: The resolver fast paths

- Status: rejected (2026-10-30). The maintainer rejected the memo and fast-path layers over the
  Map-based option model: "remove all your memo shit, every fucking shit should be typed". A
  typed internal model replaces them, with its own ADR. None of the changes of this ADR landed:
  the patches of §4 stay outside the tree. The measurement parts that landed with the proposal
  (the switch, the D1 and D2 tests, `test:nofast`, the bench cells, the P3 page) stay until the
  ADR of the typed model decides on them.
- Date: 2026-10-30
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0053-resolver-fast-paths.md`

## Summary

It proposed fast paths and memos over the Map-based option model, to bring the update near Chart.js speed.
Each change had a switch, differential tests and a night A/B gate. The release target was a P3 median of 1.5.
On 2026-10-30 the maintainer rejected the memo and fast-path layers and asked for a typed model.
No change of §4 or §5 landed. [Chart.js ADR 0054](0054-typed-internal-model.md) gives the typed internal model.
[Chart.js ADR 0054](0054-typed-internal-model.md) §17 keeps D2, the bench cells and the P3 page.

## Where each part went

- §1 (the exactness contract of a fast path): rejected, not in the code. The oracles of
  [Chart.js ADR 0054](0054-typed-internal-model.md) §15 check the typed model.
- §2 (the switch `PORT_FAST_PATHS` and the test leg `test:nofast`): removed by
  [Chart.js ADR 0054](0054-typed-internal-model.md) §17.
- §3, D1 (the differential test): removed by [Chart.js ADR 0054](0054-typed-internal-model.md) §17.
  Its configs feed the oracle O1 of §15.
- §3, D2 (the reference trace, which `status.yaml`, `parity.md` and AGENTS.md cite): kept by
  [Chart.js ADR 0054](0054-typed-internal-model.md) §15 and §17.
- §3, D3 (the pin tests of each change): rejected, not in the code.
- §4 (the changes Z, K, C1, F3, M and R2): rejected, not in the code.
  [Chart.js ADR 0054](0054-typed-internal-model.md) §4 allows no memo of the port.
- §5 (C7, the animations memo): rejected, not in the code. [Chart.js ADR 0054](0054-typed-internal-model.md)
  §4 forbids it.
- §6 (the marker ruling and the rows): rejected, not in the code.
- §7 (the night gate of each change): rejected, not in the code.
- §8 (the profiles, the series and the night calendar): rejected, not in the code.
- §9 (the bench cells `motion.line.delay`, `chart.c.indexable` and `chart.line.primitive`): kept by
  [Chart.js ADR 0054](0054-typed-internal-model.md) §17.
- §10 (the upstream page of P3 in `tool/reference/p3_page/`, which AGENTS.md and `status.yaml` cite):
  kept by [Chart.js ADR 0054](0054-typed-internal-model.md) §17.
- §11 (the release target, a P3 median of 1.5): rejected, not in the code.
  [Chart.js ADR 0054](0054-typed-internal-model.md) Open 1 records the release figure.
- §12 (the interface with Chart.js ADR 0052, no typed scope in the port): removed by
  [Chart.js ADR 0054](0054-typed-internal-model.md) §3 and §7.
- Open 1 to 4 (C6, C7, the upstream motion figures, the decisions of the porting lead): closed by the
  rejection.
