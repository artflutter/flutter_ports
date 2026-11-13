# chartjs-chart-sankey upstream ledger

This ledger records each merged upstream commit on `main` after the pinned tag of
kurkle/chartjs-chart-sankey. The rows are in the order of their commits, the oldest first.

[ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md) gives the rules for all
ports. [Sankey ADR 0001](adr/0001-upstream-sources.md) gives the pin. The columns, the kinds, the
actions and the statuses are those of the
[Chart.js ledger](../../flutter_chartjs_port/doc/upstream-ledger.md). These path classes apply:

- `runtime`: `src/**` without `src/**/*.test.ts`, `src/content/**`, `src/content.config.ts` and
  `src/env.d.ts`.
- `spec`: `test/specs/**` and `src/**/*.test.ts`.
- `harness`: `test/setup.js`, `test/utils/**` and the Vitest config files.
- `fixture`: `test/fixtures/**`.
- `types-test`: `test/types/**`.
- `build`: `package.json`, `package-lock.json`, `rollup.config.js`, the `tsconfig` files,
  `scripts/**` and `.github/**`.
- `docs`: `src/content/**`, `docs/**`, `samples/**`, `astro.config.mjs` and `README.md`.

## The pin

| Repository | Pin | Commit | Commit date | GitHub release |
|---|---|---|---|---|
| kurkle/chartjs-chart-sankey | 0.19.1 | 90b638b1 | 2026-09-12 | `v0.19.1` |

## Fetch

Phase 0 examined the repository on 2026-11-13:
`gh api repos/kurkle/chartjs-chart-sankey/compare/v0.19.1...HEAD` gave 19 commits after the pin. 14
of them update dependencies. The other 5 are rows below. None changes a `runtime`, `spec` or
`fixture` path.

## kurkle/chartjs-chart-sankey

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 5c5e6420 | | docs: put the demonstrated option in the config block | docs | none | docs-only | none | closed | | |
| 8179f3b7 | | docs: show the demonstrated option as a control | docs | none | docs-only | none | closed | | |
| 4b247316 | | docs: link and sort the option tables | docs | none | docs-only | none | closed | | |
| 1dd118b6 | | docs: tighten the heading scale and content padding | docs | none | docs-only | none | closed | | |
| f555baba | | ci: give every major dependency update its own pull request | build | none | build-only | none | closed | | |
