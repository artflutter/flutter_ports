# Upstream tracking for Chart.js

- Status: proposed ([ADR 0004](../../../docs/adr/0004-follow-upstream-between-releases.md), which amends
  [ADR 0002](../../../docs/adr/0002-pin-upstream-sources.md))
- Date: 2026-10-16
- Related: [porting-flow.md](porting-flow.md), [theming.md](theming.md),
  [upstream-ledger.md](upstream-ledger.md). Proposed future file:
  `packages/flutter_chartjs/doc/differences.md`.

This document defines how `flutter_chartjs` follows the Chart.js fixes and improvements that
upstream merges after the pinned tag (`v4.5.1`, commit `9c5cf9f`).

This document owns the upstream tooling:
- the upstream ledger, the upstream status script and the scheduled upstream watch workflow
- the bump report, the bump PR gate and the header restamp

[porting-flow.md](porting-flow.md) owns the per-module tooling:
- the header check, the library import guard and the JS-semantics check
- the upstream manifest, the parity generator and spec-case tracking
- the fixture runner and fixture ledger, and the port-order helper

## 1. Facts that drive the design

| Fact | Value |
|---|---|
| Cadence | 23 v4 releases. Median gap 44.5 days (79 days from v4.4.0), longest 121 days. All tags are on `master` |
| Drought | No release for 368 days. Milestone 4.6.0 has no due date. A release request (2026-07-01) got no maintainer reply |
| 22 commits after the pin | 12 build, dependency or CI (10 from Dependabot), 3 docs, 1 tests-only, 1 types-only, 3 fixes (#12142, #12155, #12283), 1 feature (#12130), 1 behavior change (#12238). 7 touch `src` or `test`: 37 files, +816/-49 |
| Unreleased regression fix | #12142 restores the `Math.floor` that #12097 removed from `retinaScale` in v4.5.1 |
| Volume | Runtime `src` commits per year: 305 (2021), 92, 34, 19, 16, 3 (2026). Merges come in bursts: 10 in four days of Sep 2026 |
| Open PRs | 110 (85 from 2026, 14 labeled or milestoned). Of the 84 that change runtime `src`, 61 are from 2026. Only 7 of the 84 are labeled or milestoned |
| Labels and notes | Maintainers apply labels by hand. In `v4.0.0-release..v4.5.1`, 5 of 12 unlabeled PRs changed runtime behavior. Release notes omit `type: infrastructure` (`release-drafter.yml:26-27`) |
| Tests | In `v4.0.0-release..v4.5.1`, 33 of 79 runtime commits (42%) change no test. Of the 46 tested ones, 22 have only fixture tests. #12142 has no test |
| Security | No security policy, 0 advisories. The fix PR #12268 for the public report #12265 is open |
| Other upstreams | Locked: `@kurkle/color` 0.3.2, `chartjs-test-utils` 0.4.0 (`pnpm-lock.yaml:2069, :4986`). chartjs-test-utils v1.0.0 (2026-10-11) uses Vitest and pixelmatch 7 |

Sources: a blobless Chart.js clone at `7169e651`, `gh api` and local git tests (2026-10-16).

A watcher of tags only was silent for a year in which three fixes merged. Volume is small but
bursty. A manual check at each module start is therefore enough at first. Labels and release
notes cannot drive triage. Changed paths can. Bumps must cover fixtures, because specs alone miss
upstream behavior changes.

## 2. Policy

### 2.1 Units

- **Unit of a bump: a release tag**, as in ADR 0002. A commit pin (§2.4) is the one exception.
- **Unit of triage: a merged upstream PR.** Chart.js squash-merges: all 249 commits since
  `v4.0.0-release` end in `(#NNNN)`.

### 2.2 Backport rule (fixes)

The port can take a merged upstream commit before the pin contains it only if all four
conditions are true:

1. **Kind.** It is a `fix` or a `regression-fix` (§3). Features, behavior changes, refactors and
   types-only changes are never backports.
2. **Scope.** It fixes a regression released up to the pinned tag (#12142 fixes #12097 from
   v4.5.1). Or it fixes a bug in a module whose status is `in progress`, `partial`, `ported` or
   `verified`. The status is in `parity.md` until the parity generator exists, then in
   `packages/flutter_chartjs/doc/status.yaml`. A `replaced` module has the status of its replacement file.
3. **Self-contained.** It applies to the pinned file plus the recorded backports.
4. **Recorded.** The same PR contains the `backported` ledger row, the header backport line, the
   trailers (§4.2), tests and the parity change of AGENTS.md rule 4. If upstream has no test
   (#12142), the porter writes one under `test/port/`.

A backport into a theme hunk host also re-applies the hunks. Then the porter runs their pinning
tests (theming.md §9).

The porter reads the commit with `git -C .dart_tool/chartjs-history show 2898a6d1` (§4.3). A
fetch into the submodule needs the full SHA (from the trailer or `rev-parse`), because
`git fetch` rejects an abbreviated SHA. That fetch leaves `HEAD` at `9c5cf9f`.

### 2.3 Bump first for modules not started

Before a module goes from `not started` to `in progress`, the porter runs the module-start check
(§4.3). If a newer tag exists, the bump PR comes first. If no newer tag exists, the porter ports
the module from the pin. Eligible fixes follow in the same PR, as separate commits with trailers.

### 2.4 Commit pin (improvements)

Backports carry fixes only. Improvements (features and behavior changes) arrive with a tag, or in
a release drought with a commit pin.

- **Trigger.** Before each phase from 2 to 8 starts, the porter runs the module-start check for
  the modules of the phase. A commit pin is due when both conditions are true:
  - The newest Chart.js tag is more than 12 months old.
  - `master` has an unreleased `feature` or `behavior-change` row for a module of the phase.

  A row counts for the module of its `runtime` paths. `api` paths do not count, because
  `lib/src/types` adds members only when a ported caller needs them (porting-flow.md §2.4).
- **Bump.** The next bump goes to the newest `master` commit with green upstream CI. It follows
  the full procedure (§5). The next tag ends the commit pin.
- **Version.** `chartJsVersion` becomes `<last version>+<sha8>`, for example `4.5.1+7169e651`.
  The headers become `v<last version>+<sha8>`, for example `Chart.js v4.5.1+7169e651`.
- **Tools.** The PR of the first commit pin extends three checks. `check_upstream_pin.sh` requires
  a gitlink that starts with `<sha8>`. `upstream_test.dart` compares the part before `+` with
  `package.json`. The header check accepts `+<sha8>`. Reference tools build Chart.js at the pinned
  commit in a throwaway clone outside the repository, because npm has no build of a commit.

On today's facts, phases 2 and 3 get no commit pin: their only post-pin change is the fix
#12142. Before phase 4, #12238 touches `element.arc`. Without a 4.6.0 tag, a commit pin then
comes first. `element.arc` then gets one port, with #12238.

### 2.5 Text changes in other files

These changes land when the maintainers accept ADR 0004, unless a row names a later PR. This
document owns the final text of AGENTS.md rules 1 and 6 and the backport sentence of rule 2.
porting-flow.md §6 links here for them.

| Where | Change |
|---|---|
| AGENTS.md rule 1 | Replace the last sentence with: "Never port from memory or from other Dart chart libraries. Port from upstream `master` only as a backport. A backport is one merged commit. It fixes a regression released up to the pinned tag, or a bug in a module with the status `in progress`, `partial`, `ported` or `verified`. Record it in `packages/flutter_chartjs/doc/upstream-ledger.md` and in the file header (`packages/flutter_chartjs/doc/upstream-tracking.md`). Sources from other projects follow `packages/flutter_chartjs/doc/porting-flow.md` §2.13." |
| AGENTS.md rule 2 | Add: "The header version names the upstream version that the porter last reconciled the file with. A backport adds the line `// Upstream backport: chartjs/Chart.js@<sha8> (#<PR>).` directly below it." |
| AGENTS.md rule 6 | Replace the text from "review" to the end of that sentence with: "review `git -C third_party/Chart.js diff <old-tag> <new-tag> -- src test/specs test/fixtures`. Then run `git add third_party/Chart.js` and update `chartJsVersion` and the Chart.js `version`, `ref` and `commit` in `packages/flutter_chartjs/tool/port_sources.yaml`. Port the diff for every started module. Close the ledger rows of the range. Restamp the headers (`packages/flutter_chartjs/doc/upstream-tracking.md` §4.8). Backports follow rule 1. They never move the submodule." Later PRs add the manifest step (tool 4, mid phase 2), the bump report command (`dart run melos run upstream:bump-report -- --from <old> --to <new>`, M6) and the fixture-ledger re-run |
| AGENTS.md Commands and Layout | Phase 1 adds the ledger to Layout. Each tool PR adds its entry (`upstream:status`, `upstream:ledger`, `upstream:ledger:check`, `upstream:bump-report`, the watch workflow, the issue templates), in the `dart run melos run …` form |
| ADR 0002 | Status line only: "accepted; amended by ADR 0004". [Chart.js ADR 0005](adr/0005-third-party-sources.md) adds its name when the maintainers accept it (porting-flow.md §2.13) |
| `.github/dependabot.yaml` lines 6-8 | Replace the outdated reason with the ADR 0004 reason |
| `packages/flutter_chartjs/doc/README.md` | Link ADR 0004. Phase 0 added the other links |
| `.github/PULL_REQUEST_TEMPLATE.md` | Add: "Backports: ledger row, header line, `Upstream-*` trailers. Bump PRs use Rebase and merge." |

### 2.6 Never tracked, and signals

- **Open upstream PRs** get no ledger rows.
- **Signals** are open items that the ledger header lists, each with a reason. They get no rows.
  The port does not port them before they merge. There are three kinds:
  1. Items in the next-release milestone: #12302 (`core.ticks`), #12286 (`helpers.core`).
  2. PRs that fix public security reports: #12268 (for #12265).
  3. A watch list of items that a design document or ADR names: #12205 and #11910
     (theming.md §9), #12151 and #12269 (reports of the #12097 regression), #7738 (ADR: Input
     events and interaction state).
- **Docs, website and CI commits** get `not-applicable` rows and nothing else.

## 3. Triage vocabulary

**Path classes.** A row lists every class that it touches. The classes for `src` are `runtime`
(`src/**` except `api`) and `api` (`src/types/**`, `src/types.ts`). The others are `harness`
(`test/index.js`, `karma.conf.cjs`), `spec`, `fixture`, `types-test` (`test/types/**`), `dep`
(lock versions of `@kurkle/color` or `chartjs-test-utils`), `docs` and `build` (other paths).
Rows that touch only `docs` and `build` are `not-applicable`. A `runtime` row without a
`type: *` label gets a manual review.

**Kinds.** Labels give a hint. Paths and the diff decide. `fix` (#12155), `regression-fix` (#12142,
a bug from a named released PR) and `feature` (#12130) keep the default output.
`behavior-change` (#12238) changes it. The others are `types-only` (#12321), `tests-only` (#12328)
and `n/a` (docs, build, runtime-neutral refactors such as #10879). A revert gets the kind of the
change that it reverts.

**Actions.** A row has one or more of `replay`, `adapt`, `api-only`, `spec-only`,
`golden-refresh`, `theme-review` (a visual default or option key changed,
[theming.md](theming.md) §9) and `skip`. `adapt` is for browser or DOM semantics. Its code
carries `// DIVERGES(chartjs):` wherever behavior differs or the port adds lines. Rows for a
`replaced` module are always `adapt`, against the replacement file. `api-only` changes only
`lib/src/types` (`distributed` rows) and, after 0.1.0, the typed options API.

**Statuses.** `pending` (not triaged) and `deferred` (waits for the bump that contains it) are
open. A bump PR cannot merge while a row in its range is open. The closed statuses:

| Status | Meaning |
|---|---|
| `backported` | ported early (§2.2). The bump confirms the final hunk and removes the header line |
| `ported` | replayed in the bump PR |
| `absorbed` | in the new pin, module not started |
| `not-applicable` | nothing to port, with a note: docs, build, a JS-only refactor or object-model bug, a later revert |
| `diverged` | deliberately not followed, with a `not-followed` row in `differences.md` |

## 4. Mechanisms

Mechanisms M1 to M8 come in the order of §7. Each one comes only when the port needs it. M9
links the ledger to the `differences.md` file of porting-flow.md.

### 4.1 M1: upstream ledger

```markdown
Pinned: v4.5.1 (9c5cf9f). Watching: master. Last synced: 7169e651 (2026-10-03).

Signals: #12268 (fix for the security report #12265). #7738 (touch tooltips never hide). …

## After v4.5.1

| SHA | PR | Title | Paths | Modules | Kind | Action | Status | Ref | Note |
|---|---|---|---|---|---|---|---|---|---|
| 2898a6d1 | #12142 | Use integer canvas dimensions | runtime | helpers.dom | regression-fix | adapt | deferred | | from #12097, no upstream test |
```

At a bump, the porter moves the rows of the range under `## v4.5.1 → v4.6.0 (#<bump PR>)`. `Ref`
is the `flutter_chartjs` PR that ported the row. The status script parses a strict grammar: one
table per section, fixed columns, no pipes in cells.

### 4.2 M2: conventions

**Header.** A Chart.js file starts with this block:
- Line 1 matches the rule-2 regex of the header check (porting-flow.md §4, tool 2). It has no
  `plus` form. Under a commit pin, its version group must also accept `+<sha8>`.
- Lines 2 to n, directly after line 1, are zero or more backport lines:
  `^// Upstream backport: chartjs/Chart\.js@([0-9a-f]{8}) \(#(\d+)\)\.$`.

```dart
// Ported from Chart.js v4.5.1 src/helpers/helpers.dom.ts (MIT, Chart.js Contributors).
// Upstream backport: chartjs/Chart.js@2898a6d1 (#12142).
```

- A Dart file ports one Chart.js file. AGENTS.md rule 2 and ADR 0001 ("same file split") stay as
  they are. If a release splits or merges upstream files, the bump PR does the same to the Dart
  files. porting-flow.md §2.13 owns the rules for sources from other projects.
- Backport hunks translate upstream lines. They carry no `DIVERGES(chartjs)` marker.
- The header check validates the grammar of both line types.
  `upstream:ledger:check` (M4) matches each backport SHA with a `backported` row.

**Trailers.** A backport commit carries `Upstream-PR: chartjs/Chart.js#12142` and
`Upstream-Commit: 2898a6d1c76e15c56690dc41be5f91a44a1e85b9`. A bump commit is
`chore(upstream): bump Chart.js to v4.6.0` with `Upstream-Tag: v4.6.0`. The ledger row and the
header line are the records of truth. Trailers help `git log` searches.

The repository allows squash merges. The default squash body joins all commit messages. Git
reads trailers only from the last paragraph: in a test with two trailer blocks,
`%(trailers:key=Upstream-Commit)` returned only the second SHA. Tools therefore read
`git log --format=%B` and match `^Upstream-(PR|Commit|Tag): ` on each line. Bump PRs use "Rebase
and merge". The restamp commit (M8) then stays separate on `main`.

### 4.3 M3: module-start check

Before a module goes to `in progress`, the porter runs these commands. The blobless clone (about
11 MB) lives in `.dart_tool/`. Run the first command once:

```sh
git clone --filter=blob:none --no-checkout https://github.com/chartjs/Chart.js .dart_tool/chartjs-history
git -C .dart_tool/chartjs-history fetch --tags origin
git -C .dart_tool/chartjs-history tag --contains v4.5.1
git -C .dart_tool/chartjs-history log --oneline v4.5.1..origin/master -- \
  src/helpers/helpers.dom.ts test/specs/helpers.dom.tests.js test/fixtures/helpers.dom
```

`tag --contains` lists the pin and each newer tag. The log lists the commits for the module. The
porter adds the new rows by hand. Then the porter applies §2.3 and §2.4. Do not use the shallow
submodule or `--shallow-exclude`: path-limited `git log` then lists the boundary commit by
mistake. Between module starts, a personal `releases.atom` subscription shows new tags.
Dependabot, Renovate and updatecli see tags only. ADR 0004 rejects them.

### 4.4 M4: status script and ledger check

`tool/upstream_status.dart` (pure Dart) replaces the commands of M3. Its commands run as
`dart run melos run <name>`. It groups the commits after the pin by PR, with path classes. It
maps them to Dart files through the headers. With `GH_TOKEN`, it adds labels. Its signals include
the lock versions on `master` and titles that match `security|vulnerab|prototype|xss|redos`
(`caseSensitive: false`).

- `upstream:status` writes a Markdown report. `--module <path>` limits it to one module.
  `--format=issue` writes an issue body. `--out=<file>` writes to a file.
- `upstream:ledger` appends the new rows as `pending`.
- `upstream:ledger:check` (`upstream_status.dart --check`, not `upstream:check`) runs offline on
  every PR, over the PR range. It fails on bad ledger grammar, on a backport line without a
  `backported` row, and on a `diverged` row without a `differences.md` row. It warns about a new
  backport line without an `Upstream-Commit:` line. The header check, not this script, pairs
  `DIVERGES(chartjs)` markers with `differences.md` rows.
- `--check-bump` is the gate (M7).

### 4.5 M5: scheduled watch, labels and templates

`.github/workflows/upstream-watch.yaml` runs weekly and on `workflow_dispatch`, with
`contents: read` and `issues: write`:

1. Run `upstream:status -- --format=issue --out=build/upstream.md` and
   `upstream:bump-report -- --from v<pin> --to origin/master --preview --out=build/preview.md`.
2. Write both files to `$GITHUB_STEP_SUMMARY`. Cut the issue body below 65,536 characters.
3. Find the open `upstream-watch` issue, or create it. If `$n` is empty or `null`, stop with an
   error. Then run `gh issue edit "$n" --body-file …`.
4. For each new tag, search `gh issue list --state all --search 'Bump Chart.js to vX.Y.Z in:title'`.
   If no issue exists, run `gh issue create`.

The watch makes no commits. It needs no sign-off. Outside `ci.yaml`, it keeps PR CI free of
issue permissions and API rate limits. If GitHub disables the schedule after 60 days without
activity, the module-start check still finds the changes. The templates are
`port-upstream-change.md` (§2.2 as its checklist) and `bump-upstream.md` (§5 as its checklist).

### 4.6 M6: bump report

`tool/bump_report.dart` runs as `dart run melos run upstream:bump-report -- --from <ref> --to <ref>`.
Build it in stages. Sections 1, 2, 4, 5, 8 and 9 come first. Sections 3 and 7 join in phase 3,
section 6 in phase 5. The coverage-test output joins section 6 in phase 6. Its inputs are the M3 clone, the upstream manifest of each ref
(porting-flow.md) and the fixture ledger.

- **Modes.** In a bump PR, the porter regenerates the manifest for the new ref locally (§5 step
  4). In CI, only the `upstream-manifest` job of porting-flow.md runs Node. The bump report reads
  the committed manifests. `--preview` uses git only. It omits sections 4 and 6, because they need
  the manifest of the new ref.
- **Function context.** Git has no built-in JavaScript funcname driver. With the default
  heuristic, `git diff -W` takes the column-0 `export default class` line as the function: for
  `core.scale.js` in v4.5.1..7169e651, 13 lines of diff become 1,550. The tool therefore runs git
  with its own attributes file (`*.js diff=chartjs`, `*.ts diff=chartjs`) and this
  `diff.chartjs.xfuncname`. Its first line excludes control statements:

```text
!^[ \t]*(if|else|for|while|switch|catch|return|do)([ \t(]|$)
^[ \t]*((export[ \t]+)?(default[ \t]+)?(async[ \t]+)?function[ \t].*|(static[ \t]+|get[ \t]+|set[ \t]+|async[ \t]+)*[A-Za-z_$][A-Za-z0-9_$]*[ \t]*\([^;]*\)[ \t]*\{[ \t]*)$
```

  The context is then the method that contains the change: 43 lines (`drawTitle`). A tool
  test pins that size.

Sections:

1. **Commits.** The ledger rows of the range. A flag on each `backported` row whose file changed
   again.
2. **src.** Changed files with their Dart files and module status. Hunks with function context,
   without import-only, comment-only and annotation-only hunks (such as #10879).
3. **JS-semantics hotspots.** Added `Math.round`, `Math.floor`, `Math.ceil`, `%`, `| 0`,
   `Math.log10`, `parseFloat`, `Number(`, string coercion and `.sort(`, for
   [Chart.js ADR 0002](adr/0002-js-numeric-semantics.md).
4. **Specs.** Added, removed and renamed cases (spec-case tracking).
5. **Fixtures.** Changes by config hash and PNG sha256, joined to the fixture ledger. A changed
   PNG makes its row stale. v4.5.1..master: 6 PNGs modified, 5 added.
6. **Defaults and theming.** The defaults-inventory diff from the manifest, the option-key diff of
   `src/types/index.d.ts`, the theme hunks in changed hosts, and the output of the theming
   coverage snapshot test (ADDED, REMOVED, CHANGED, theming.md §8, test 4). v4.5.1..master:
   #12130 adds `title.strokeColor` and `title.strokeWidth` with no defaults (`theme-review`).
   theming.md excludes the `spacingMode` defaults of #12238 as geometry.
7. **Event path.** Hunks with function context in `src/platform/**`, `core.interaction.js`,
   `core.controller.js`, `core.datasetController.js`, `plugin.tooltip.js`, `plugin.legend.js`,
   `helpers.dom.ts`, `helpers.core.ts`, the `events` default and their specs.
   v4.5.1..master changes only `clearStacks` and `retinaScale`, not event handling.
8. **Dependencies and license.** Lock versions of `@kurkle/color` and `chartjs-test-utils`. The
   diff of upstream `LICENSE.md`.
9. **Version strings.** The lines in `tool/version_strings.txt`. Today these are
   `packages/flutter_chartjs/lib/src/upstream.dart:5-6`, `packages/flutter_chartjs/README.md:19`,
   `README.md:17`, `packages/flutter_chartjs/doc/README.md:9` and its example header, `AGENTS.md:4, :66, :82`,
   `.github/PULL_REQUEST_TEMPLATE.md:3`, the Chart.js `version`, `ref` and `commit` in
   `packages/flutter_chartjs/tool/port_sources.yaml`, the `parity.md` links and a new
   `CHANGELOG.md` entry.
   The prior-art survey, the ADRs and the design documents are dated evidence. The bump does not
   restamp them.

### 4.7 M7: bump PR gate

`upstream:status -- --check-bump` runs in its own CI job when the `third_party/Chart.js` gitlink
differs from the PR base. It fails unless all these conditions are true:

1. No row in the range is `pending` or `deferred`.
2. Each `backported` and `ported` row has a `Ref`.
3. Each `diverged` row has a `differences.md` row.
4. Every header has the version that the new pin implies. Chart.js headers have the new
   version. The `@kurkle/color`, `chartjs-test-utils` and pixelmatch headers have their versions
   in the new Chart.js lockfile.
5. No `Upstream backport:` line names a commit in the new pin.
6. From phase 7, the fixture ledger has no stale rows in started modules.
7. The version strings of report section 9 name the new version.
8. The bump report is in the job summary.

### 4.8 M8: header restamp

After the port, the porter restamps the headers in a separate commit,
`chore(flutter_chartjs): restamp headers to v4.6.0`:

```sh
git grep -lz '^// Ported from Chart\.js v4\.5\.1 ' -- packages apps \
  | xargs -0 perl -pi -e 's{^// Ported from Chart\.js v4\.5\.1 }{// Ported from Chart.js v4.6.0 }'
```

The porter also removes each backport line whose commit is in the new pin. The `@kurkle/color`
headers, and the `chartjs-test-utils` and pixelmatch headers in `packages/chartjs_test_utils`,
follow the versions in the Chart.js lockfile (§5 step 10). Gate condition 4 covers every header.
The restamp therefore compares no upstream blobs.

### 4.9 M9: differences.md

porting-flow.md §4 defines the `packages/flutter_chartjs/doc/differences.md` schema. The port creates the file
with the first `DIVERGES(chartjs)` hunk. This document adds two links. Each `diverged` ledger row
has a `not-followed` row. The bump report lists every row whose upstream lines changed.

## 5. Bump procedure

Use one PR on the branch `upstream/chartjs-vX.Y.Z` (or `upstream/chartjs-<sha8>`), with no
feature work. A Flutter SDK bump is a separate PR (porting-flow.md §2.12, §3).

1. **Trigger.** The module-start check or the watch finds a tag, or §2.4 makes a commit pin due.
2. **Check out.** Fetch both refs and check out the new one (ADR 0002 steps 1-2). For a commit
   pin, fetch the full SHA.
3. **Rows.** Add the new rows. Move the rows of the range under the new section.
4. **Manifest and report.** Regenerate the upstream manifest (porting-flow.md) and the bump
   report. Before M6 exists, read
   `git -C third_party/Chart.js diff <old> <new> -- src test/specs test/fixtures`.
5. **Close every row.** Module not started: `absorbed`. Module started: `ported` or `diverged`.
   `backported`: compare with the final hunk. Types-only: `absorbed` until ADR: Typed options API
   exists. Docs and build: `not-applicable`.
6. **Port** the started modules: src hunks, spec cases, `api-only` rows, and Dart tests for
   runtime changes without upstream tests. If upstream splits or merges files, do the same.
7. **Fixtures.** Once the fixture runner is live, re-run the whole fixture ledger.
8. **Theming.** Run the coverage snapshot test and the light-preset test (theming.md §8, tests 3
   and 4). Update the snapshot, the `notThemed` list or the preset values. Re-apply the theme
   hunks in changed hosts. Then run their pinning tests.
9. **Events and JS semantics.** Read report sections 7 and 3. For events, update the
   input-mapping source that the parity generator reads. Then run `dart run melos run parity`.
10. **Dependencies.**
    - `@kurkle/color`: if its lock version changed, diff the two kurkle tags and port the change.
    - `chartjs-test-utils`: if its lock version changed, review the harness port. v1 (Vitest,
      Playwright, pixelmatch 7) keeps white blending unless a fixture sets `checkerboard: true`.
      Re-run the ledger rows of these fixtures and of changed PNGs. If upstream renames spec
      files, remap the case IDs.
11. **Licenses.** If a kurkle version or upstream `LICENSE.md` changed, update
    `packages/flutter_chartjs/LICENSE` and its `REUSE.toml` annotation in one commit.
    Then run `reuse lint`.
12. **Versions.** Run `git add third_party/Chart.js`. Update `chartJsVersion`, the Chart.js
    `version`, `ref` and `commit` in `packages/flutter_chartjs/tool/port_sources.yaml` and the
    strings of report section 9. Regenerate `parity.md`.
13. **Headers.** Restamp (M8).
14. **Gate and merge.** Once M7 exists, run the gate. Merge with "Rebase and merge".

## 6. Initial backlog

These are the 7 commits after v4.5.1 that touch `src` or `test`. Phases follow porting-flow.md
§5. Phase 1 seeds the ledger from this table by hand, with status `deferred`. A bump of
this range changes 9 `src` files (7 runtime, 2 api, about 154 substantive lines), 4 spec files
(+413 lines) and 11 fixtures. Until phase 3, a bump closes these 7 rows as `absorbed`. The 15
other rows stay `not-applicable`. A bump then takes about an
hour. From phase 3, rows of started modules are real replays.

| SHA | PR | Title | Paths | Kind | Action | Module (phase) | Notes |
|---|---|---|---|---|---|---|---|
| `e8c58daf` | #12130 | Enable scale title stroke | runtime, api, spec, docs, build | feature | replay, api-only, theme-review | `core.scale` (5) | Passes `title.strokeColor` and `title.strokeWidth` to `renderText` (`core.scale.js:1611-1619` at `master`). No defaults |
| `2898a6d1` | #12142 | Use integer canvas dimensions | runtime | regression-fix (#12097) | adapt | `helpers.dom` (3) | Backport in phase 3 if no tag contains it, with a Dart test. `Math.floor` → `floorToDouble` |
| `ab79c3bf` | #12238 | Corrected spacing in pie/doughnut/polarArea | runtime, api, spec, fixture, types-test, docs | behavior-change | replay, golden-refresh | `element.arc` (4), doughnut and polarArea (7) | New `spacingMode` defaults and descriptors. 5 PNGs re-rendered, 3 added. Arrives with 4.6.0 or the commit pin |
| `cb02e1d2` | #12155 | Fix early exit from clearStacks | runtime, fixture | fix | replay | `core.datasetController` (5), fixture needs `controller.line` (7) | `return` → `continue` (`core.datasetController.js:220`). Fixture-only test |
| `b9725745` | #12283 | filler fill past line with offset and min/max | runtime, fixture | fix | replay | `plugin.filler` (8) | +20 lines in `filler.drawing.js`. Fixture-only test |
| `714b48cd` | #12328 | Stabilize overlapping polar-area labels | fixture | tests-only | golden-refresh | polarArea fixtures (7) | No label. `pointLabels/overlapping` config and PNG |
| `7169e651` | #12321 | Scriptable and indexed grid tick widths | api, types-test | types-only | api-only | typed options API (after 0.1.0) | Already scriptable at runtime in v4.5.1 (`core.scale.defaults.js:34`, `core.scale.js:1098`) |

The other 15 rows start as `not-applicable`: 10 Dependabot bumps (none changes the locked
`@kurkle/color`), CI #12309 and #12310, and docs #12139, #12134 and #12258.

## 7. Plan by phase

Phase 0 ends when the six new documents land: the forui survey, porting-flow.md, theming.md,
this document and the proposed ADR 0004 and Chart.js ADR 0001.

| Phase | Upstream tracking work |
|---|---|
| 1 | Accept ADR 0004. Apply §2.5. Create the ledger (M1) by hand from §6. Use M2 and M3. If a tag ships, bump at once: these 7 rows become `absorbed` |
| 2 | Headers and backport lines apply from the first ported file |
| 3 | Backport #12142 with `helpers.dom` if no tag contains it. Write M4 (or earlier, at more than about 10 new rows in a quarter). Before the first bump whose range touches a started module, build M6 (without section 6), M7 and M8. Build M5 only after M4, when a maintainer asks |
| 4 | Apply §2.4 before the phase starts. On today's facts, a commit pin comes first |
| 5 | Add report section 6. #12155 is already in the pin (4.6.0 or the commit pin). It needs no backport |
| 7, 8 | Fixture-ledger re-runs join bumps (gate condition 6). #12283 is already in the pin |
| 9 | Each CHANGELOG entry names the Chart.js version and lists its backports |

## 8. Risks and open questions

**Risks:**
- **Release drought.** The gap is 368 days now. Each commit pin is a bump with real port work.
- **Unreleased code.** It is possible that upstream revises a commit before a tag. Report section
  1 flags a changed backport. The next bump replays the revision.
- **Harness migration.** A move to chartjs-test-utils v1 (Vitest, `*.spec.js`) changes case IDs.
  Pass/fail results change only for fixtures that set `checkerboard: true` or get new PNGs.
- **Silent security fixes.** Upstream publishes no advisories. It is possible that a regex DoS in
  color parsing also affects the port.

**Open questions.** porting-flow.md answers two earlier questions. A typed options API comes
after 0.1.0, with its own ADR (its §2.1). Port-only tests go under `test/port/` (its §1, step 5).

1. Do patch releases with type breaks (#12120 in v4.5.1, a break that the maintainers kept) bump the
   version of the typed options API?
2. If Chart.js moves to `@kurkle/color` 0.6.x, does the port follow that diff, or does it replace
   the color layer with a `DIVERGES` implementation?
3. Is 12 months the right drought limit for §2.4?
