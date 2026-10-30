# chartjs-plugin-zoom upstream ledger

This ledger records each merged upstream PR on `master` after the pinned commit of
chartjs/chartjs-plugin-zoom. A commit on `master` without a PR also gets a row, with an empty PR
cell. The rows are in the order of their commits on `master`, the oldest first.

[ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md) gives the rules for all
ports. [Zoom ADR 0001](adr/0001-upstream-sources.md) gives the pin. At each phase start and at
each module start, the porter adds the new rows (ADR 0006 items 4 and 5). Do not put a pipe in a
cell, because a status script will parse a strict grammar.

The columns, the kinds, the actions and the statuses are those of the
[Chart.js ledger](../../flutter_chartjs_port/doc/upstream-ledger.md) and of
[the Chart.js upstream tracking](../../flutter_chartjs_port/doc/upstream-tracking.md) §3. These
path classes apply:

- `runtime`: `src/**` without `src/*.test.ts`. The type declarations are in the runtime files.
  Thus a change of a type declaration is a `runtime` path. Its kind is `types-only`.
- `spec`: `test/specs/**` and `src/*.test.ts`.
- `harness`: `test/index.js`, `karma.conf.cjs`, `jasmine.json` and `tsconfig.spec.json`.
- `fixture`: `test/fixtures/**`.
- `types-test`: `test/types/**`.
- `build`: `package.json`, `package-lock.json`, `rollup.config.js`, `rollup.dts.config.js`,
  `tsconfig.json`, `tsconfig.build.json`, `scripts/**` and `.github/**`.
- `docs`: `docs/**`, `samples/**`, `README.md`, `CONTRIBUTING.md` and `MAINTAINING.md`.

## The pin

| Repository | Pin | Commit | Commit date | GitHub release |
|---|---|---|---|---|
| chartjs/chartjs-plugin-zoom | 2.2.0+fb81d331 | fb81d331 | 2026-10-02 | none (`v2.2.0` is 2024-11-26) |

The pin contains the 34 commits of `v2.2.0...fb81d331`. They are not ledger rows. The bump to the
next release tag (Zoom ADR 0001 item 7) examines the commits between the pin and that tag.

## Fetch

Phase 0 examined the repository on 2026-10-30 at 16:31 UTC:

1. `gh api repos/chartjs/chartjs-plugin-zoom/compare/fb81d3316bbf3504903b10d1a9bc8cd99173b5c4...master`
   gave the status `identical`: `master` has no commit after the pin.
2. `gh api "/advisories?ecosystem=npm&affects=chartjs-plugin-zoom"` gave no advisory.
3. The open PRs (ADR 0006 item 1: no row) without the Dependabot PRs are #972 "Docs vitepress"
   (2026-09-17), #933 "Extend onZoom and onPan callbacks for syncing multiple charts" (2025-04-02)
   and #809 "refactor: VuePress to VitePress" (2024-03-11). #933 changes the callbacks of the
   options. A port of the callbacks examines it again.

## chartjs/chartjs-plugin-zoom

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|

No commit after the pin on 2026-10-30.
