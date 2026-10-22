# ECharts upstream ledger

This ledger records each merged upstream PR after the pinned tag of the two upstream
repositories of the port: apache/echarts and ecomfe/zrender. It has one section for each
repository, in the order of [`tool/port_sources.yaml`](../tool/port_sources.yaml). Each section
has one row for each merged PR on `master` after the pin. A commit on `master` without a PR also
gets a row, with an empty PR cell. The rows are in the order of their commits on `master`, the
oldest first.

[ADR 0006](../../../docs/adr/0006-follow-upstream-between-releases.md) gives the rules for all
ports. [ECharts ADR 0001](adr/0001-upstream-sources.md) gives the pins, the status unit (one
upstream source file), the bump unit and the backport lines. At each phase start and at each
module start, the porter adds the new rows of the two repositories (ADR 0006 items 4 and 5). Do
not put a pipe in a cell, because a status script will parse a strict grammar.

## Columns and values

The columns are the columns of the [Chart.js ledger](../../flutter_chartjs_port/doc/upstream-ledger.md).
[The Chart.js upstream tracking](../../flutter_chartjs_port/doc/upstream-tracking.md) §3 defines the
kinds, the actions and the statuses. The ECharts port has no tracking document of its own yet.
Until it has one, these path classes apply to apache/echarts:

- `runtime`: `src/**`. ECharts declares its types in the runtime files. Thus a change of a type
  declaration is a `runtime` path. Its kind is `types-only`.
- `harness`: `test/ut/core/**`, `test/ut/jest.config.cjs`, `test/ut/tsconfig.json` and
  `test/lib/**`. `test/lib/` holds the helpers of the visual pages.
- `spec`: `test/ut/spec/**`.
- `fixture`: the visual pages `test/*.html`, `test/data/**` and `test/runTest/actions/**`. From
  phase 6, tool 4 extracts the charts of the visual pages (ECharts ADR 0005).
- `types-test`: `test/types/**`.
- `dep`: the `dependencies` of `package.json`. At 6.1.0, these are `tslib` 2.3.0 and `zrender`
  6.1.0 (`package.json:75-78`). A new `zrender` version moves the zrender pin with the ECharts
  bump (ECharts ADR 0001).
- `docs`: the Markdown files of the repository root, for example `README.md` and `AGENTS.md`.
- `build`: all other paths. Examples are CI, lint and build config, lockfiles, dev dependencies,
  `dist/**`, `extension-src/**`, `ssr/client/**` and the root `i18n/` and `theme/` folders. The
  lockfile `test/runTest/package-lock.json` of the visual test runner is also `build`.

These path classes apply to ecomfe/zrender:

- `runtime`: `src/**`.
- `harness`: `test/ut/extendExpect.ts`, `test/ut/jest.config.js` and `test/ut/tsconfig.json`.
- `spec`: `test/ut/spec/**`.
- `fixture`: the visual pages `test/*.html`.
- `dep`: the `dependencies` of `package.json`. At 6.1.0, this is `tslib` 2.3.0
  (`package.json:35-37`).
- `docs`: the Markdown files of the repository root.
- `build`: all other paths, `dist/**` included.

The reference generators of ECharts ADR 0005 run `dist/echarts.js` of the pin. Thus a `dist/**`
change has an effect only at a bump.

The SHA cell gives the commit on `master`: the merge commit of the PR, or its squash commit. The
note gives the other commits of the PR branch, with their dates. Thus this file names each commit
after the pin. The `Modules` cell names the upstream source file, relative to the repository
root. The `Note` cell starts with the commit date of the commit on `master`. For an open row, the
note then names the roadmap phase of the file.

## Fetch

Phase 0 wrote the rows by hand on 2026-10-21 at 08:30 UTC, with these steps:

1. Find the default branch: `gh api repos/<owner>/<repo> --jq .default_branch`. The default
   branch of both repositories is `master`.
2. List the commits after the pin: `gh api repos/<owner>/<repo>/compare/6.1.0...master`. The
   result has 44 ECharts commits and 6 zrender commits on one page. Its status is `ahead`. Thus
   the pin is an ancestor of `master`.
3. Get the PR of each commit: `gh api repos/<owner>/<repo>/commits/<sha>/pulls`. A PR counts
   only with a merge date.
4. Get the files of each commit: `gh api repos/<owner>/<repo>/commits/<sha>`. Read the diff of
   each commit that changes `src/**`, with the media type `application/vnd.github.diff`.
5. List the tags: `git ls-remote --tags <url>`. List the branches:
   `gh api repos/<owner>/<repo>/branches`. Compare each release branch with the pin:
   `gh api repos/<owner>/<repo>/compare/6.1.0...<branch>`.

Take the URL from `tool/port_sources.yaml`. The dates are committer dates. Some commits have a
date before the tag date. The maintainers made 6.1.0 on the branch `release`. A commit on `master`
after the branch point is not in 6.1.0.

Each repository merged `release` back into `master` after the tag: ECharts #21621 and zrender
#1158. The second parent of each merge is the pin commit. `compare` of the pin with that parent
gives `identical`. Thus these two merges bring no change after the pin. GitHub compares a merge
commit with its first parent. Thus the file lists of #21621 and #1158 show the 6.1.0 release diff.
The pin already contains that diff.

`git ls-remote --tags` lists no tag after 6.1.0 in the two repositories. Thus no bump comes first
(ADR 0006 item 4). The pins are the newest tags:

| Repository | Pin | Commit | Commit date | GitHub release |
|---|---|---|---|---|
| apache/echarts | 6.1.0 | c5a48f5f | 2026-05-13 | 2026-05-19 |
| ecomfe/zrender | 6.1.0 | 32b66867 | 2026-05-04 | 2026-05-04 |

Signals:

- GitHub lists one advisory for each npm package
  (`gh api /advisories -f ecosystem=npm -f affects=<package>`). GHSA-fgmj-fm8m-jvvx, "Apache
  ECharts has a cross-site scripting (XSS) vulnerability", applies to echarts `< 6.1.0`. The pin
  contains the fix. GHSA-fhv8-fx5f-7fxf, "Prototype Pollution in the merge and clone helper
  methods", applies to zrender `>= 5.0.0, < 5.2.1` and `<= 4.3.2`. The pin 6.1.0 is outside these
  ranges.
- Open PRs get no row (ADR 0006 item 1). Phase 0 examined one open PR: zrender #1177, "Fix PR
  #1149" (2026-10-15). It fixes two defects of the merged PR #1149. The [zrender](#ecomfezrender)
  row of #1149 names them. Phase 0 did not examine the other open PRs or issues.

## Release branches

The ECharts branch `release` has 28 commits after 6.1.0. They are 13 merged PRs with the base
`release`. `compare master...release` gives `diverged`: `release` is 28 commits ahead of `master`
and 44 commits behind it. Thus `master` does not have these fixes. Nine more open ECharts PRs
have the base `release`.

ADR 0006 item 2 takes backports from the upstream default branch only. Thus these 13 PRs are not
backport candidates. The next tag of `release`, for example a 6.1.1, brings them. That tag makes
a bump come first (ADR 0006 item 4). The bump then adds their rows to the
[apache/echarts](#apacheecharts) section and closes them. Until then, this table lists them for
the triage of the bump. It has no status column.

| SHA | PR | Title | Paths | Modules | Kind | Phase | Note |
|---|---|---|---|---|---|---|---|
| bc21b40e | #21698 | fix(heatmap): prevent crash with missing coordinate system | runtime, spec | `src/chart/heatmap/HeatmapView.ts` | fix | 7 | 2026-07-20. Commit: c6741a77 (2026-07-20). It closes the issue #19060. A new spec file `test/ut/spec/series/heatmap.test.ts`. |
| c01658fb | #21697 | fix(stack): exclude empty values from `stackStrategy: 'all'` to avoid corrupting the sum | runtime, spec | `src/processor/dataStack.ts` | fix | 2 | 2026-07-21. Commit: 34304707 (2026-07-21). It closes the issue #21685. A new spec file `test/ut/spec/data/dataStack.test.ts`. |
| 9faba8ae | #21707 | fix(geo): tolerate singular view transform when chart size is zero | runtime, spec | `src/coord/View.ts` | fix | 7 | 2026-07-26. Commits: 3a5c3c53 and 1ec34627 (2026-07-26). It closes the issue #21706. A new spec file `test/ut/spec/component/geo/geo.test.ts`. |
| 409c69d4 | #21657 | fix(marker): correct markArea on inverse category axis | runtime, fixture | `src/coord/Axis.ts` | fix | 4 | 2026-07-29. Commit: 5966e301 (2026-07-29). It closes the issue #21652. The visual page `test/bar-markArea.html` gets new cases. |
| cd9de600 | #21747 | fix(type): allow null/undefined for axis `min` and `max` option | runtime, types-test | `src/coord/axisCommonTypes.ts` | types-only | 4 | 2026-09-04. Commit: 7d8ad6b2 (2026-09-04). It closes the issue #21746. A new type test `test/types/esm/axisMinMaxNullable.ts`. |
| ddfd8f8a | #21751 | fix(format): preserve literal replacement characters in values | runtime, spec | `src/util/format.ts` | fix | 4 | 2026-09-12. Commits: e32cec43 and 5e78e202 (2026-09-12). `formatTpl` and `formatTplSimple` give `replace` a replacement function in place of a replacement string (`src/util/format.ts:145-148,160-163` at 6.1.0). A `$` in a value then stays literal. A new spec file `test/ut/spec/util/format.test.ts`. ECharts ADR 0008 plans `jsStringReplace` with the substitution rules for these sites. |
| 84b69e48 | #21638 | fix(axis): make axis.min/max behave consistently with series.data and axis.dataMin/Max | runtime, harness, fixture | `src/coord/scaleRawExtentInfo.ts` | regression-fix | 6 | 2026-09-12. Commit: 80404103 (2026-05-30). Its commit message names a defect of 6.1.0: with `axis.min: NaN`, the axis is blank and no series is drawn. The change ignores an illegal `min` or `max`. It also changes `test/lib/testHelper.js` and the visual page `test/axis-extreme2.html`. |
| e8e3c4dc | #21736 | fix(core): makes the `opts` argument of `echartsInstance.getConnectedDataURL` optional | runtime, spec | `src/core/echarts.ts` | fix | 5 | 2026-09-14. Commit: 52b4f2be (2026-09-13). A new spec file `test/ut/spec/api/getConnectedDataURL.test.ts`. ECharts ADR 0009 decides the export API. |
| 8ce1ccff | #21734 | fix(candlestick/boxplot): accept null and undefined data items | runtime, spec | `src/chart/helper/whiskerBoxCommon.ts` | fix | 7 | 2026-09-14. Commit: 8c384ea4 (2026-09-13). A new spec file `test/ut/spec/series/whiskerBoxEmptyValue.test.ts`. |
| f6be3585 | #21733 | fix(tooltip): clear pending timers on dispose | runtime, spec | `src/component/tooltip/TooltipRichContent.ts`, `src/component/tooltip/TooltipView.ts` | fix | 6 | 2026-09-14. Commit: b9a61eda (2026-09-13). A new spec file `test/ut/spec/component/tooltip/dispose.test.ts`. |
| acb285f2 | #21702 | fix(bar): draw bars stacked over out-of-log-domain values from the axis start | runtime, spec, fixture | `src/layout/barGrid.ts` | fix | 6 | 2026-09-30. Commit: 8e9cbb5a (2026-07-21). A new spec file `test/ut/spec/series/barStackLog.test.ts`. The visual page `test/bar-log.html` gets new cases. |
| e020f5ae | #21785 | fix(i18n): fix typo and incorrect translations in langRO | runtime | `src/i18n/langRO.ts` | fix | 10 | 2026-10-12. Commit: f7b4e66a (2026-10-10). Three locale strings change. |
| 8ca03d46 | #21787 | fix(aria): preserve literal dollar sequences in label text | runtime, spec | `src/visual/aria.ts` | fix | 2 | 2026-10-13. Commit: 76cda4c2 (2026-10-12). It closes the issue #21786. The local `replace` helper gives `replace` a replacement function (`src/visual/aria.ts:257-260` at 6.1.0). A new spec file `test/ut/spec/series/aria-label.test.ts`. |

The other branches have no commit after 6.1.0 that `master` does not have:

- ECharts `next`: 0 commits ahead of 6.1.0 and 376 commits behind it.
- zrender `release`: identical to 6.1.0.
- zrender `next`: 0 commits ahead of 6.1.0 and 41 commits behind it.
- zrender `release-dev`: 0 commits ahead of 6.1.0 and 1 commit behind it.

The other branches of the two repositories are feature and fix branches. An example is the zrender
branch `feat/able_to_update_dpr_in_resize_fix2` of the open PR #1177.

## Overview

50 commits follow the pins. They are 22 merged PRs. Each commit belongs to a merged PR.

| Repository | Pin | Tag date | Commits | Rows | With PR | Open |
|---|---|---|---|---|---|---|
| [apache/echarts](#apacheecharts) | 6.1.0 (c5a48f5f) | 2026-05-13 | 44 | 20 | 20 | 7 |
| [ecomfe/zrender](#ecomfezrender) | 6.1.0 (32b66867) | 2026-05-04 | 6 | 2 | 2 | 1 |

Eight rows are open (`deferred`):

- 2 features: ECharts #21562 (sankey `sort`) and zrender #1149 (the device pixel ratio on a
  resize).
- 4 fixes: ECharts #21590, #21586, #21637 and #21699.
- 1 types-only change: ECharts #21489. It goes with zrender #1149.
- 1 comment fix: ECharts #21731.

The other 14 rows are `not-applicable`:

- 11 rows change lockfiles only. They are Dependabot PRs.
- 1 row changes docs only (ECharts #21587, `AGENTS.md`).
- 2 rows merge the 6.1.0 release into `master` (ECharts #21621 and zrender #1158).

The open rows add three upstream spec cases. At a bump to the current `master`, tool 4 then
counts 194 ECharts cases in place of 191:

- `test/ut/spec/component/helper/BrushController.test.ts`: a new file with 1 case (#21590,
  phase 8).
- `test/ut/spec/data/SeriesData.test.ts`: 1 new case (#21699, phase 4).
- `test/ut/spec/series/bar.test.ts`: a new chart spec with 1 case (#21699, phase 6).

The 13 PRs of the ECharts branch `release` add nine more spec files. The
[Release branches](#release-branches) section lists them.

## Commit pins (ADR 0006 item 5)

ADR 0006 item 5 makes a commit pin due when both of its conditions are true:

- The newest upstream tag is more than 12 months old.
- The default branch has an unreleased feature or behavior change for a module of the phase.

Each repository has its own newest tag (ECharts ADR 0001). A change counts for the module of its
`runtime` paths. A `types-only` change does not count.

The ECharts tag 6.1.0 is from 2026-05-13. It becomes more than 12 months old after 2027-05-13. The
zrender tag 6.1.0 is from 2026-05-04. It becomes more than 12 months old after 2027-05-04. Thus,
until these dates, the first condition is false. Until then, no phase start makes a commit pin
due.

ECharts ADR 0001 also limits a zrender bump to the version that the pinned ECharts requires.
On `master`, ECharts still requires zrender 6.1.0 (`package.json:77` at `master`). Thus a zrender
commit pin for #1149 also waits for an ECharts version that requires a newer zrender.

Before each phase starts, the porter does these steps for each repository:

1. List the tags after the pin (`git ls-remote --tags <url>`). If a newer release tag exists,
   the bump comes first (ADR 0006 item 4). Also compare the branch `release` with the pin.
2. Fetch `master`. Add the new rows to the section of the repository.
3. Examine the `runtime` rows of the files of the phase. A `feature` row or a `behavior-change`
   row makes a commit pin due if the tag is more than 12 months old.
4. Do each due commit pin as its own change before the phase starts.

A commit pin moves one repository to a reviewed commit of its `master`. Its version then reads
`6.1.0+<sha8>`. `echartsVersion` or `zrenderVersion` takes this form. The first commit pin of the
port also extends `tool/check_upstream_pin.sh`,
`packages/flutter_echarts_port/test/upstream_test.dart` and the header check. After that change,
they accept `<version>+<sha8>` (ADR 0006, Consequences).

On the rows of 2026-10-21, the phase starts give these results. New rows can change them.

| Phase | Files of the phase with an open row | Commit pin |
|---|---|---|
| 1 | None | None. |
| 2 | ECharts `src/data/Source.ts` (#21699). zrender `src/config.ts` and `src/core/PathProxy.ts` (#1149). | None while the tags are less than 12 months old. #21699 is a fix. It is a backport candidate (ADR 0006 item 2). #1149 is a feature of zrender. After 2027-05-04, it makes a zrender commit pin due, if ECharts then requires that zrender. |
| 3 | zrender `src/canvas/Layer.ts`, `src/canvas/Painter.ts`, `src/PainterBase.ts` and `src/zrender.ts` (#1149). | The same result as phase 2 for #1149. |
| 4 | None | None. |
| 5 | ECharts `src/core/echarts.ts` (#21489). | None. #21489 is `types-only`. It does not count. |
| 6 | None | None. |
| 7 | None | None. |
| 8 | ECharts `src/chart/sankey/SankeySeries.ts` and `src/chart/sankey/sankeyLayout.ts` (#21562). `src/component/helper/BrushController.ts` (#21590). Comment fixes in `src/chart/treemap/treemapLayout.ts`, `src/component/helper/cursorHelper.ts` and `src/coord/matrix/Matrix.ts` (#21731). | None while the ECharts tag is less than 12 months old. After 2027-05-13, #21562 (a feature) makes an ECharts commit pin due. #21590 is a fix. It is a backport candidate. |
| 9 | ECharts `src/component/visualMap/ContinuousView.ts` and `src/component/visualMap/VisualMapModel.ts` (#21586, #21637). | None. Both rows are fixes. They wait for the bump (see the rows). |
| 10 | None | None. |

## apache/echarts

Pinned: 6.1.0 (c5a48f5f). Watching: master. Last synced: 34f4d927 (2026-10-04).

The ECharts fixes of a patch release merge into the branch `release`, not into `master`. The
[Release branches](#release-branches) section lists them.

### After 6.1.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 7d6524e3 | #21590 | fix(parallel): preserve areaSelectStyle on persisted selection | runtime, spec | `src/component/helper/BrushController.ts` | fix | replay | deferred | | 2026-04-27. Phase 8. Commit: 0c0f4668 (2026-04-21). It closes the issue #21583. `updateCovers` merges each cover config into a clone of the current brush option. Without a brush option, it uses `DEFAULT_BRUSH_OPT`, as before (`src/component/helper/BrushController.ts:385` at 6.1.0). A new spec file `test/ut/spec/component/helper/BrushController.test.ts` has one case. It is a backport candidate (ADR 0006 item 2) when `BrushController.ts` is `in progress`. It applies to the pinned file. It needs no other unreleased commit. |
| d6a812f8 | #21562 | feat(sankey): support disabling node sorting. close #21561 | runtime, fixture | `src/chart/sankey/SankeySeries.ts`, `src/chart/sankey/sankeyLayout.ts` | feature | replay | deferred | | 2026-04-27. Phase 8. Commits: 624f520e (2026-03-31), 6418ca21 (2026-04-01) and c108d1f7 (2026-04-10). A new series option `sort`: `'desc'` (the default) or `null`. With `null`, `resolveCollisions` keeps the node order of each depth column (`src/chart/sankey/sankeyLayout.ts:364-366` at 6.1.0). The default keeps the 6.1.0 output. A new visual page `test/sankey-node-sorting.html`. A feature is never a backport (ADR 0006 item 2). After 2027-05-13, it makes an ECharts commit pin due at the start of phase 8 (ADR 0006 item 5). |
| b014e953 | #21621 | Merge 6.1.0 release to master | | | n/a | skip | not-applicable | | 2026-05-20. It merges the branch `release` into `master`. Its second parent is the pin c5a48f5f. Thus it has no change after the pin. The GitHub file list compares it with its first parent and shows the 6.1.0 release diff. |
| 09bf9147 | #21586 | fix(visualMap): prevent tooltip label overlap | runtime, fixture | `src/component/visualMap/ContinuousView.ts` | fix | replay | deferred | | 2026-05-22. Phase 9. Commits: 60292165 (2026-04-15) and 5979d16c (2026-04-17). The two handle labels of a continuous visualMap no longer overlap (`_updateHandle`, `src/component/visualMap/ContinuousView.ts:595-646` at 6.1.0). It also changes the input of a `visualMap.formatter` function. The visual page `test/visualMap-continuous.html` gets new cases. #21637 replaces most of this change. Thus this row alone is not a backport candidate. It waits for the bump with #21637. |
| ab0657b2 | #21587 | docs: add agents guide for contributors | docs | | n/a | skip | not-applicable | | 2026-05-26. Commits: dc34f61b, fdf18d11, 6225ce0d and f64ba6b6 (all 2026-04-16). Docs only (a new `AGENTS.md`). |
| 45775be4 | #21633 | chore(deps-dev): bump tmp from 0.2.4 to 0.2.7 | build | | n/a | skip | not-applicable | | 2026-05-28. Commit: dae507cb (2026-05-28). `package-lock.json` only. The `dependencies` of `package.json` do not change. |
| dc60bdd6 | #21489 | feat(canvas): update `devicePixelRatio` to prevent chart being blurry after resizing | runtime, build | `src/core/echarts.ts` | types-only | replay | deferred | | 2026-05-28. Phase 5. A squash commit. It adds the optional field `devicePixelRatio` to the interface `ResizeOpts` (`src/core/echarts.ts:312-317` at 6.1.0). `resize` already gives `opts` to `this._zr.resize` (`:1461`). Thus the runtime effect comes from zrender #1149. The CI change (`.github/workflows/ci.yml`) is a `build` path. A `types-only` change does not count for a commit pin (ADR 0006 item 5). The bump that brings this row also brings zrender #1149. |
| 20ecdf4c | #21637 | fixRegression: Fix the implementation of visualMap labels overlap. Fix #21586. | runtime, fixture | `src/component/visualMap/ContinuousView.ts`, `src/component/visualMap/VisualMapModel.ts` | fix | replay | deferred | | 2026-05-31. Phase 9. Commit: 06cd2ea5 (2026-05-30). It fixes defects of #21586, an unreleased PR. It removes the change of #21586 to the `visualMap.formatter` input. It moves the two labels apart. #21586 merged them into one label. A drag of the whole range sets the hover link position to the middle of the two handles (`src/component/visualMap/ContinuousView.ts:426` at 6.1.0). `VisualMapModel.ts` gets a comment only. A new action file `test/runTest/actions/visualMap-continuous.json`. This row needs #21586, another unreleased commit. Thus it fails ADR 0006 item 2 condition 3. It waits for the bump. |
| 5b0f1fd2 | #21665 | chore(deps-dev): bump js-yaml from 4.1.1 to 4.3.0 in /test/runTest | build | | n/a | skip | not-applicable | | 2026-07-01. Commit: d037ca69 (2026-06-30). `test/runTest/package-lock.json` only, the lockfile of the visual test runner. |
| 74e9e09a | #21692 | chore(deps): bump ws in /test/runTest | build | | n/a | skip | not-applicable | | 2026-07-15. Commit: bae1b32c (2026-07-14). `test/runTest/package-lock.json` only. |
| e647e774 | #21699 | fix(dataset): detect dimensions across sparse object-row datasets | runtime, spec | `src/data/Source.ts` | fix | replay | deferred | | 2026-07-23. Phase 2. Commits: db7241a6 (2026-07-17) and b6ace83a (2026-07-22). It closes the issue #11322. `objectRowsCollectDimensions` collects the keys of all object rows in their first order. At 6.1.0, it reads the keys of the first truthy row only (`src/data/Source.ts:403-410`). The output changes only for a later row with a key that no earlier row has. One new case in `test/ut/spec/data/SeriesData.test.ts` (phase 4). A new chart spec `test/ut/spec/series/bar.test.ts` with one case (phase 6). It is a backport candidate (ADR 0006 item 2) when `src/data/Source.ts` is `in progress`. It applies to the pinned file. It needs no other unreleased commit. |
| fac05685 | #21708 | chore(deps-dev): bump ws from 7.5.10 to 7.5.13 | build | | n/a | skip | not-applicable | | 2026-07-28. Commit: ce133783 (2026-07-26). `package-lock.json` only. The `dependencies` of `package.json` do not change. |
| 30076aed | #21713 | chore(deps): bump ip-address and socks in /test/runTest | build | | n/a | skip | not-applicable | | 2026-08-04. Commit: 56b86969 (2026-08-04). `test/runTest/package-lock.json` only. |
| 34d159a4 | #21745 | chore(deps-dev): bump browserslist from 4.24.2 to 4.28.8 | build | | n/a | skip | not-applicable | | 2026-09-04. Commit: 186f5a74 (2026-09-03). `package-lock.json` only. The `dependencies` of `package.json` do not change. |
| 018ed399 | #21748 | chore(deps): bump brace-expansion | build | | n/a | skip | not-applicable | | 2026-09-04. Commit: 72e0086d (2026-09-04). `package-lock.json` only. The `dependencies` of `package.json` do not change. |
| 854017e0 | #21750 | chore(deps-dev): bump js-yaml from 4.3.0 to 4.3.2 in /test/runTest | build | | n/a | skip | not-applicable | | 2026-09-11. Commit: 9b4f81dd (2026-09-10). `test/runTest/package-lock.json` only. |
| 984bf46b | #21731 | fix: correct 'becuase' typo in code comments | runtime | `src/chart/treemap/treemapLayout.ts`, `src/component/helper/cursorHelper.ts`, `src/coord/matrix/Matrix.ts` | n/a | replay | deferred | | 2026-09-12. Phase 8. A squash commit. Comment fixes only (`src/chart/treemap/treemapLayout.ts:184`, `src/component/helper/cursorHelper.ts:49` and `src/coord/matrix/Matrix.ts:188` at 6.1.0). It has no behavior change. The ported files keep the upstream comments. Thus the bump replays it. |
| ff39a914 | #21769 | chore(deps-dev): bump ip-address from 10.4.0 to 10.7.2 in /test/runTest | build | | n/a | skip | not-applicable | | 2026-09-30. Commit: 3fddf3a9 (2026-09-29). `test/runTest/package-lock.json` only. |
| 62e3373d | #21770 | chore(deps): bump brace-expansion from 1.1.11 to 1.1.21 in /test/runTest | build | | n/a | skip | not-applicable | | 2026-09-30. Commit: 490ce731 (2026-09-30). `test/runTest/package-lock.json` only. |
| 34f4d927 | #21777 | chore(deps): bump brace-expansion | build | | n/a | skip | not-applicable | | 2026-10-04. Commit: ad48870d (2026-10-03). `package-lock.json` only. The `dependencies` of `package.json` do not change. |

## ecomfe/zrender

Pinned: 6.1.0 (32b66867). Watching: master. Last synced: 34911103 (2026-05-26).

### After 6.1.0

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 55e3c0ee | #1158 | Merge 6.1.0 release to master | | | n/a | skip | not-applicable | | 2026-05-20. It merges the branch `release` into `master`. Its second parent is the pin 32b66867. Thus it has no change after the pin. The GitHub file list compares it with its first parent and shows the 6.1.0 release diff. |
| 34911103 | #1149 | feat(canvas): update DPR after resizing | runtime | `src/config.ts`, `src/core/PathProxy.ts`, `src/PainterBase.ts`, `src/zrender.ts`, `src/canvas/Layer.ts`, `src/canvas/Painter.ts` | feature | replay | deferred | | 2026-05-26. Phase 2 (`config.ts`, `PathProxy.ts`) and phase 3 (the other files). Commits: 96c8c0f3 (2026-01-22), 5a52347e (2026-01-30), b143ab68 (2026-02-02) and a2fefe33 (2026-05-26, a merge of `master` into the PR branch). `ZRender.resize` takes an optional `devicePixelRatio`. The painter and each layer then update their `dpr`. `src/config.ts` replaces the module-load constant `devicePixelRatio` with the function `getDevicePixelRatio()` (`src/config.ts:3-22` at 6.1.0). The function has no lower limit of 1 (`Math.max` at `:7-11`). `PathProxy` divides by its own `dpr` in place of the global value (`src/core/PathProxy.ts:12,180-181`). The open PR #1177 names two defects of this PR. The `eachLayer` callback of `Painter.resize` reads `this.dpr` in a plain function (`src/canvas/Painter.ts:1253-1255` at `master`). `PathProxy#setScale` runs before `PathProxy#setDPR`. ECharts ADR 0007 lets the host set the device pixel ratio of `src/config.ts`. The bump that brings this row compares that route with the new code. A feature is never a backport (ADR 0006 item 2). |
