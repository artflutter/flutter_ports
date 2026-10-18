# ADR 0002: Pin upstream sources as git submodules at release tags

- Status: accepted
- Date: 2026-10-16
- Superseded by: [ADR 0005](0005-pin-upstream-sources.md) (2026-10-19)

## Context

A port is only checkable against an exact upstream version. Porting from memory or from a moving
branch makes behaviour drift silently and makes upstream releases impossible to replay.

## Decision

Each port's upstream repository is a shallow git submodule under `third_party/`, checked out at a
release tag. Chart.js: `third_party/Chart.js` at `v4.5.1` (commit `9c5cf9f`).

- The submodule is reference material only: it is never built, shipped or imported, and it is
  excluded from analysis and licensing checks of this tree.
- `melos run upstream` checks it out (`git submodule update --init --depth 1`).
- The tracked version also lives in code (`chartJsVersion` in `flutter_chartjs`). Two checks keep
  the two in step:
  - `tool/check_upstream_pin.sh` (`melos run upstream:check`, and the CI `upstream-pin` job)
    fails unless the recorded gitlink is exactly the commit of tag `v<chartJsVersion>`, looked up
    with `git ls-remote`. It needs no submodule checkout.
  - `upstream_test.dart` compares `chartJsVersion` with the checked-out submodule's
    `package.json` when the submodule is present.

  The version string alone is not enough: upstream `master` still reports `4.5.1`.
- Bumping upstream is deliberate port work. The submodule is a shallow clone without tags, so the
  sequence is:
  1. fetch both tags: `git -C third_party/Chart.js fetch --depth 1 origin tag <old-tag> tag <new-tag>`;
  2. check out the new tag;
  3. review `git -C third_party/Chart.js diff <old-tag> <new-tag> -- src test/specs`;
  4. `git add third_party/Chart.js`, then port the changes and update `chartJsVersion` and
     [parity.md](../../packages/flutter_chartjs/doc/parity.md).

  All of it goes in one PR.
- Dependabot's `gitsubmodule` updater is not used: it follows the upstream default branch, not
  release tags.

## Consequences

- Contributors and agents read upstream source locally at the exact version being ported.
- Cloning the repository does not download upstream unless asked for.
- Upstream fixes that land after the pinned tag (Chart.js `master` is 22 commits past `v4.5.1` as
  of 2026-10-16) are not picked up until the next deliberate bump.
