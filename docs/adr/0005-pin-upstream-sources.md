# ADR 0005: Pin upstream sources

- Status: accepted (2026-10-19)
- Date: 2026-10-19
- Supersedes: [ADR 0002](0002-pin-upstream-sources.md)
- Related: [ADR 0006](0006-follow-upstream-between-releases.md) (ledger, backports and commit
  pins), [Chart.js ADR 0011](../../packages/flutter_chartjs_port/doc/adr/0011-third-party-sources.md)
  (the other projects that the Chart.js port takes code from)

## Context

A port can be checked only against an exact upstream version. Porting from memory or from a
moving branch makes the behavior drift with no signal. It also makes it impossible to replay
upstream releases.

ADR 0002 (2026-10-16) pinned each upstream as a shallow git submodule at a release tag. Two later
decisions changed parts of that rule:
- ADR 0004 (accepted 2026-10-18) allowed a commit pin in a release drought. It also widened the
  bump review and gave a new reason not to use Dependabot.
  [ADR 0006](0006-follow-upstream-between-releases.md) now holds the commit pin rule. This ADR
  holds the bump review and the Dependabot reason.
- Chart.js ADR 0005 (accepted 2026-10-18) said what "never built" means for dev-time tools. These
  tools can read and run reference sources. For example, the upstream manifest tool of the
  Chart.js port records the hash of each fixture PNG. It also runs the `describe` bodies of the
  upstream specs in a Node.js `vm`. The reference generators run JS builtins in Node.js.

This ADR restates the complete decision in one place. It supersedes ADR 0002.

## Decision

1. **Pin.** The upstream repository of each port is a shallow git submodule under `third_party/`.
   It is checked out at a release tag. A commit pin of
   [ADR 0006](0006-follow-upstream-between-releases.md) (item 5) is the only exception. Chart.js:
   `third_party/Chart.js` at `v4.5.1` (commit `9c5cf9f`).
2. **Reference only.** A submodule under `third_party/` is reference material:
   - Dart code never imports a reference source.
   - No tool builds a reference source inside `third_party/`. A tool that needs a built upstream
     builds it in a throwaway clone outside the repository.
   - No package ships a reference source. A published archive contains no `third_party/` file.
   - The analysis and the licensing checks of this tree exclude the submodules.

   Dev-time tools can read and evaluate reference sources, for example the specs, the JavaScript
   code and the fixture files.
3. **Checkout.** `melos run upstream` checks out every submodule
   (`git submodule update --init --depth 1`). A plain `git clone` downloads none of them.
4. **Version in code.** The tracked version also lives in code (`chartJsVersion` in
   `flutter_chartjs_port`). Two checks keep the two in step:
   - `tool/check_upstream_pin.sh` (`melos run upstream:check`, and the CI `upstream-pin` job)
     fails unless the recorded gitlink is exactly the commit of tag `v<chartJsVersion>`. It looks
     up the tag with `git ls-remote`. It needs no submodule checkout.
   - `upstream_test.dart` compares `chartJsVersion` with the `package.json` of the checked-out
     submodule when the submodule is present.

   The version string alone is not sufficient: upstream `master` still reports `4.5.1`.
5. **Bump.** A bump is deliberate port work. The submodule is a shallow clone without tags. Do
   these steps in one PR:
   1. Fetch both refs:
      `git -C third_party/Chart.js fetch --depth 1 origin tag <old-tag> tag <new-tag>`. For a
      commit pin, fetch the full SHA.
   2. Check out the new ref.
   3. Review the diff of the source, spec and fixture paths between the two refs, and the bump
      report when it exists.
   4. Run `git add` on the submodule. Port the changes, close the ledger rows, restamp the
      headers, and update the version constant and the parity tracker.
6. **No Dependabot.** The port does not use the Dependabot `gitsubmodule` updater. Since
   dependabot-core #13052, it proposes the newest semver-tagged commit on the tracked branch. But
   it rewrites only the gitlink, and it sees no fixes between tags.

## Alternatives considered

- **Port from a moving branch, or from memory.** Rejected. The behavior drifts with no signal,
  and upstream releases cannot be replayed.
- **Tag only, with no commit pin.** Rejected. A port must then port the known regressions of the
  pinned tag, and improvements wait for the drought to end
  ([ADR 0006](0006-follow-upstream-between-releases.md)).
- **Dependabot `gitsubmodule`.** Not used. It writes only the gitlink, so its PR fails the pin
  check until a person ports the diff. It never reports fixes between tags. After an API error,
  it can propose the head of the default branch.
- **Renovate `git-submodules`.** Not used. Its update runs `checkout <newDigest>` without a fetch.
  With `shallow = true`, that checkout fails. It also sees tags only.

## Consequences

- Contributors and agents read the upstream source locally, at the exact version that they port.
- A clone of the repository does not download upstream unless the contributor asks for it.
- The upstream ledger records each upstream change after the pinned tag. A fix that meets
  [ADR 0006](0006-follow-upstream-between-releases.md) can become a backport. In a release
  drought, ADR 0006 allows a commit pin. All other changes wait for the next bump.
- A tool that needs a built upstream, for example for a commit pin, builds it in a throwaway clone
  outside the repository, never in `third_party/`.
- Each port lists the other projects that it takes code from in its own ADR, for example
  [Chart.js ADR 0011](../../packages/flutter_chartjs_port/doc/adr/0011-third-party-sources.md).
