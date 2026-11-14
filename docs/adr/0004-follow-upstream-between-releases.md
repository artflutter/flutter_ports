# ADR 0004: Follow upstream between releases

- Status: accepted (2026-10-18)
- Date: 2026-10-16
- Superseded by: [ADR 0006](0006-follow-upstream-between-releases.md) (2026-10-19)
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:docs/adr/0004-follow-upstream-between-releases.md`

## Summary

Each port kept an upstream ledger with one row for each merged upstream PR after the pin.
A port took a backport only for a fix, with the header line `// Upstream backport:`.
A bump came first when a newer tag existed. In a release drought, a commit pin took the improvements.
Item 7 amended the pin, the bump steps, the Dependabot reason and one consequence of ADR 0002.

## Where each part went

- Item 1 (the ledger): [ADR 0006](0006-follow-upstream-between-releases.md) item 1.
- Item 2 (backports carry fixes only): [ADR 0006](0006-follow-upstream-between-releases.md) item 2.
  [Chart.js ADR 0009](../../packages/flutter_chartjs_port/doc/adr/0009-no-display-only-js-exactness.md)
  removed the status `verified` of condition 2.
- Item 3 (the header line of a backport): [ADR 0006](0006-follow-upstream-between-releases.md) item 3.
- Item 4 (bump first): [ADR 0006](0006-follow-upstream-between-releases.md) item 4.
- Item 5 (the commit pin for improvements): [ADR 0006](0006-follow-upstream-between-releases.md) item 5.
- Item 6 (the bump scope): [ADR 0006](0006-follow-upstream-between-releases.md) item 6 and
  [ADR 0005](0005-pin-upstream-sources.md) item 5.
- Item 7, pin (the commit pin as the one exception to a tag): [ADR 0005](0005-pin-upstream-sources.md) item 1.
- Item 7, bump step 3 (the review of the source, spec and fixture paths): [ADR 0005](0005-pin-upstream-sources.md)
  item 5, step 3.
- Item 7, bump step 4 (the ledger rows, the headers and the version constant):
  [ADR 0005](0005-pin-upstream-sources.md) item 5, step 4.
- Item 7, Dependabot (the reason of dependabot-core #13052): [ADR 0005](0005-pin-upstream-sources.md) item 6.
- Item 7, Consequences (the ledger, the backports and the commit pin): [ADR 0005](0005-pin-upstream-sources.md)
  Consequences, third bullet.
