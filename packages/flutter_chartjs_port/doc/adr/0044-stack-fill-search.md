# Chart.js ADR 0044: Stack fill search

- Status: rejected (2026-10-29). The code A/B of section 6 gave ACCEPT on macOS and REJECT in
  the VS Code browser. Thus the change is not in the tree.
  [Chart.js ADR 0046](0046-stack-fill-search-result.md) records the result.
- Date: 2026-10-24
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0044-stack-fill-search.md`

## Summary

It proposed two port changes for the quadratic `stack` fill, with the upstream results.
The loop of `_boundSegment` got direct calls, an `int` index and inline helpers.
The stack line got a binary window search of the lines below.
The code A/B of §6 gave ACCEPT on macOS and REJECT in the VS Code browser.
There, the guard cell `fill.radar` and 9 control cells got slower. Thus the change left the tree.

## Where each part went

- §1 (the loop of `_boundSegment`, row `adapt-bound-segment-loop`): rejected, not in the code.
  [Chart.js ADR 0046](0046-stack-fill-search-result.md) item 2 keeps the row out of `differences.md`.
- §2 (the window search of the stack line, row `adapt-stack-line-window`): rejected, not in the code.
  [Chart.js ADR 0046](0046-stack-fill-search-result.md) item 3 names it as one possible new candidate.
- §3 (`interpolate` in two parts, `interpolateFrom`): rejected, not in the code.
- §4 (no second implementer of `types.Segment`): rejected, not in the code.
- §5 (the tests, the rows and the records): rejected, not in the code.
- §6 (the gates and the code A/B, which performance.md and Chart.js ADR 0046 cite):
  [Chart.js ADR 0046](0046-stack-fill-search-result.md) holds the result. Figures: performance.md §14.9.
- Open 1 (the device figures, which performance.md §14.7 cites): closed by the rejection.
  performance.md §14.9 has the iPhone 17 Pro run of the A/B.
- Open 2 (the literal path of the stack): closed by the rejection. The whole stack fill stays quadratic
  ([Chart.js ADR 0046](0046-stack-fill-search-result.md) item 1).
- Evidence E3 (the judge benchmark, which performance.md §14.9 and Chart.js ADR 0046 cite): in the full
  text only.
