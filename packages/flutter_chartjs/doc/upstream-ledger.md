# Chart.js upstream ledger

This ledger records each merged Chart.js PR after the pinned tag, with one row for each PR.
[upstream-tracking.md](upstream-tracking.md) defines the process (§2), the values of each column
(§3) and this format (§4.1). [ADR 0004](../../../docs/adr/0004-follow-upstream-between-releases.md)
(proposed) gives the rules for all ports. Phase 1 added these rows by hand from
upstream-tracking.md §6. At each module start, the porter adds the new rows (upstream-tracking.md
§4.3). Do not put a pipe in a cell, because the status script will parse a strict grammar.

Pinned: v4.5.1 (9c5cf9f). Watching: master. Last synced: 7169e651 (2026-10-03).

Signals: #12302 (milestone 4.6.0, core.ticks). #12286 (milestone 4.6.0, helpers.core). #12268 (fix for the security report #12265). #12205 (theming.md §9, legend crash after a font change). #11910 (theming.md §9, scale color defaults do not update). #12151 (report of the #12097 regression). #12269 (report of the #12097 regression). #7738 (touch tooltips never hide, ADR: Input events and interaction state).

## After v4.5.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 72c6742a | #12133 | Bump pnpm/action-setup from 4.1.0 to 4.2.0 | build | | n/a | skip | not-applicable | | CI workflows, Dependabot. Labels: dependencies, github_actions |
| f6310f2b | #12139 | Fix amount of category scales count in docs | docs | | n/a | skip | not-applicable | | Docs only. Label: type: documentation |
| 67f67ae8 | #12138 | Bump actions/setup-node from 5 to 6 | build | | n/a | skip | not-applicable | | CI workflows, Dependabot. Labels: dependencies, github_actions |
| 2bbb96cd | #12134 | docs: Add note about flexbox/grid layout responsivity issue | docs | | n/a | skip | not-applicable | | Docs only. Label: type: documentation |
| e8c58daf | #12130 | Enable scale title stroke (12092) | runtime, api, spec, docs, build | core.scale | feature | replay, api-only, theme-review | deferred | | Phase 5. Passes `title.strokeColor` and `title.strokeWidth` to `renderText` (`core.scale.js:1611-1619` at master). No defaults. Label: type: enhancement |
| 2898a6d1 | #12142 | Use integer canvas dimensions | runtime | helpers.dom | regression-fix | adapt | deferred | | from #12097, no upstream test. Backport due with helpers.dom in phase 3 if no tag contains it, with a Dart test in `test/port/`. `Math.floor` → `floorToDouble`. Label: type: bug |
| 6d4bf67c | #12159 | Bump js-yaml from 3.14.1 to 3.14.2 | build | | n/a | skip | not-applicable | | Dev lockfile, Dependabot. Lock versions of @kurkle/color and chartjs-test-utils do not change. Labels: dependencies, javascript |
| a1535568 | #12160 | Bump actions/checkout from 4 to 6 | build | | n/a | skip | not-applicable | | CI workflows, Dependabot. Labels: dependencies, github_actions |
| ab79c3bf | #12238 | Corrected spacing in pie/doughnut/polarArea (Fixes #10059) | runtime, api, spec, fixture, types-test, docs | element.arc, controller.doughnut, controller.polarArea | behavior-change | replay, golden-refresh | deferred | | Phases 4 and 7. New `spacingMode` defaults and descriptors. 5 PNGs re-rendered, 3 added. Arrives with 4.6.0 or the commit pin before phase 4 (upstream-tracking.md §2.4). Label: type: enhancement |
| cb02e1d2 | #12155 | Fix early exit from clearStacks | runtime, fixture | core.datasetController | fix | replay | deferred | | Phase 5. `return` → `continue` (`core.datasetController.js:220`). Fixture-only test. The fixture needs controller.line (phase 7). Label: type: bug |
| dc6bce40 | #12163 | Bump preactjs/compressed-size-action from 2 to 3 | build | | n/a | skip | not-applicable | | CI workflow, Dependabot. Labels: dependencies, github_actions |
| bb61a469 | #12207 | Bump minimatch from 3.1.2 to 3.1.5 | build | | n/a | skip | not-applicable | | Dev lockfile, Dependabot. Lock versions of @kurkle/color and chartjs-test-utils do not change. Labels: dependencies, javascript |
| 0fbceb2a | #12206 | Bump rollup from 3.20.2 to 3.30.0 | build | | n/a | skip | not-applicable | | Dev lockfile, Dependabot. Lock versions of @kurkle/color and chartjs-test-utils do not change. Labels: dependencies, javascript |
| 913fee4f | #12258 | Add a note that axis labels can span lines | docs | | n/a | skip | not-applicable | | Docs only. Label: type: documentation |
| 0ad783f1 | #12309 | Use node 24 for CI | build | | n/a | skip | not-applicable | | CI workflows. Label: type: chore |
| b9725745 | #12283 | filler plugin fill extends past line when offset: true + index scale min/max | runtime, fixture | plugin.filler/filler.drawing | fix | replay | deferred | | Phase 8. +20 lines in `filler.drawing.js`. Fixture-only test. Label: type: bug |
| d2ddcf9e | #12310 | Specify build script for compressed size | build | | n/a | skip | not-applicable | | CI workflow. Labels: type: chore, github_actions |
| 0db976ca | #12307 | Bump pnpm/action-setup from 4.2.0 to 6.1.0 | build | | n/a | skip | not-applicable | | CI workflows, Dependabot. Labels: dependencies, github_actions |
| afb3d647 | #12303 | Bump actions/checkout from 6 to 7 | build | | n/a | skip | not-applicable | | CI workflows, Dependabot. Labels: dependencies, github_actions |
| 6a86e238 | #12306 | Bump actions/setup-node from 6 to 7 | build | | n/a | skip | not-applicable | | CI workflows, Dependabot. Labels: dependencies, github_actions |
| 714b48cd | #12328 | test: stabilize overlapping polar-area labels across browsers | fixture | controller.polarArea | tests-only | golden-refresh | deferred | | Phase 7. `pointLabels/overlapping` config and PNG. No label. The PR title is "test: stabilize overlapping polar-area label fixture" |
| 7169e651 | #12321 | fix(types): allow scriptable and indexed grid tick widths | api, types-test | types/index.d.ts | types-only | api-only | deferred | | Typed options API (after 0.1.0). Already scriptable at runtime in v4.5.1 (`core.scale.defaults.js:34`, `core.scale.js:1098`). Label: type: types |
