# ADR 0004: Follow upstream between releases

- Status: accepted (2026-10-18)
- Date: 2026-10-16
- Superseded by: [ADR 0006](0006-follow-upstream-between-releases.md) (2026-10-19)

## Context

ADR 0002 pins each upstream at a release tag. A port gets later upstream changes only at the next
bump. That rule costs much when an upstream releases rarely:

- Fixes can wait many months on the upstream default branch, also fixes for regressions in the
  pinned tag. Under ADR 0002, a port must then port the regression.
- Many upstream fixes have no spec change. Some have only image-fixture tests. ADR 0002 bump step 3
  reviews only the source and the specs.
- Labels and release notes can omit runtime changes. Changed paths are a better triage key.
- ADR 0002 rejects Dependabot because "it follows the upstream default branch, not release tags".
  That reason is out of date. Since dependabot-core #13052 (merged 2026-02-17, first released in
  v0.361.2 on 2026-02-18), the updater proposes the newest semver-tagged commit on the tracked
  branch.

The first port shows all of these problems. Its evidence (2026-10-16) is in
[the Chart.js upstream tracking](../../packages/flutter_chartjs/doc/upstream-tracking.md) §1.

## Decision

These rules apply to every port. Each port documents its own process in its package `doc/`
folder.

1. **Ledger.** Each port has an upstream ledger with one row for each merged upstream PR after the
   pin. Each row has a status. A bump PR cannot merge while a row in its range is open. Open
   upstream PRs get no rows.
2. **Backports carry fixes only.** A port can take a merged commit from the upstream default
   branch before the pin contains it only if all four conditions are true:
   1. It is a fix.
   2. It fixes a regression released up to the pinned tag, or a bug in a module whose status is
      `in progress`, `partial`, `ported` or `verified`.
   3. It applies to the pinned file and the recorded backports. It needs no other unreleased
      commit.
   4. The same PR records it: a ledger row, a header line, tests and the parity row.

   Features, behavior changes, refactors and types-only changes are never backports. A backport
   never moves the submodule.
3. **Header line.** A backport adds one line directly after the `// Ported from` line:
   `// Upstream backport: <owner>/<repo>@<sha8> (#<PR>).` The header version means "the upstream
   version that the porter last reconciled this file with". The bump that contains the commit
   removes the line.
4. **Bump first.** Before a module goes from `not started` to `in progress`, the porter lists the
   newer tags. If one exists, the bump PR comes first.
5. **Commit pin for improvements.** Before each phase of the port roadmap starts, the porter
   examines the modules of that phase. A commit pin is due when both of these conditions are true:
   - The newest upstream tag is more than 12 months old.
   - The upstream default branch has an unreleased feature or behavior change for a module of the
     phase.

   A change counts for the module of its runtime paths. A change to type declarations only does
   not count, because a port adds declared types only when a ported caller needs them.

   The next bump then goes to a reviewed commit of the default branch, not to a tag. The version
   constant of the port reads `<last version>+<sha8>`. The next tag ends the commit pin.
6. **Bump scope.** A bump reviews the upstream source, spec and fixture paths. It closes every
   ledger row of its range. It restamps the headers to the new version.
7. **Amendments to ADR 0002.** The body of ADR 0002 stays as it is. Its status line becomes
   "accepted; amended by ADR 0004". This text supersedes these parts of ADR 0002:
   - Pin: a commit pin (item 5) is the one exception to "checked out at a release tag".
   - Bump step 3: "review the diff of the source, spec and fixture paths between the two refs,
     and the bump report once it exists"
   - Bump step 4: "run `git add` on the submodule. Port the changes, close the ledger rows,
     restamp the headers, and update the version constant and the parity tracker."
   - Dependabot bullet: "The port does not use Dependabot's `gitsubmodule` updater. Since
     dependabot-core #13052 it proposes the newest semver-tagged commit on the tracked branch. But
     it rewrites only the gitlink. It sees no fixes between tags (ADR 0004)."
   - Consequences, third bullet: "The upstream ledger records each upstream change after the
     pinned tag. A fix that meets ADR 0004 can become a backport. In a release drought, ADR 0004
     allows a commit pin. All other changes wait for the next bump."

## Alternatives considered

- **Tag only, as in ADR 0002.** Rejected. A port must then port known regressions of the pinned
  tag. Improvements wait for the drought to end. A watcher of tags only stays silent while fixes
  merge.
- **Follow the default branch all the time.** Rejected. Each upstream merge becomes port work.
  Upstream builds from a package registry exist only for tags.
- **A curated fork branch,** as typescript-go did with `tsgo-port`. Rejected. It needs a
  maintained fork of each upstream and cherry-pick work for each fix.
- **Dependabot `gitsubmodule`.** Not used, for three reasons (dependabot-core `de71a59`):
  1. `file_updater.rb:15-17` writes only the gitlink. Its PR fails the pin check until a human
     ports the diff and updates the version constant.
  2. It never reports fixes between tags.
  3. After an API error, `package_details_fetcher.rb:44-50` uses the branch head instead. It is
     then possible that it proposes the HEAD of the default branch.
- **Renovate `git-submodules`.** Not used. Its update runs `checkout <newDigest>` without a fetch
  (`update.ts:29-35`). With `shallow = true`, that checkout fails (a local run reproduced the
  failure). Adoption needs five changes: enable the opt-in `git-submodules` manager, remove
  `shallow`, set `branch = <tag>`, add a regex manager for the version constant, and add
  `:gitSignOff`. It still sees tags only.
- **updatecli, `releases.atom`, newreleases.io.** Not used. updatecli has no submodule resource.
  Its `gitcommit` source (since v0.120.0) reports only the newest commit of a branch, not each
  merged PR. `releases.atom` and newreleases.io see tags only. A personal `releases.atom`
  subscription is the tag alert until a watch workflow exists.

## Consequences

- Each port needs its own ledger and its own tracking process, in its package `doc/` folder.
- A port can ship without a known regression of its pinned tag.
- Each backport costs a ledger row, a header line, a test and a confirmation at the next bump.
- A commit pin names a version that a package registry does not have. Tools that need a built
  upstream build it in a throwaway clone outside the repository, never in `third_party/`.
- The PR of the first commit pin extends `check_upstream_pin.sh`, `upstream_test.dart` and the
  header check to accept `<version>+<sha8>`.
- The comment in `.github/dependabot.yaml` gets the corrected reason.
