# ADR 0002: Pin upstream sources as git submodules at release tags

- Status: accepted
- Date: 2026-10-16
- Superseded by: [ADR 0005](0005-pin-upstream-sources.md) (2026-10-19)
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:docs/adr/0002-pin-upstream-sources.md`

## Summary

The upstream repository of each port was a shallow git submodule under `third_party/`, at a release tag.
The submodule was reference material only. No tool built it, no package shipped it, and no code imported it.
`chartJsVersion` held the version in code, and two checks kept it equal to the gitlink.
A bump was deliberate port work in one PR. The port did not use Dependabot.

## Where each part went

- Decision (the pin at a release tag): [ADR 0005](0005-pin-upstream-sources.md) item 1.
- Decision (reference material only): [ADR 0005](0005-pin-upstream-sources.md) item 2.
- Decision (the checkout with `melos run upstream`): [ADR 0005](0005-pin-upstream-sources.md) item 3.
- Decision (the version in code and its two checks): [ADR 0005](0005-pin-upstream-sources.md) item 4.
- Decision (the four bump steps, [ADR 0004](0004-follow-upstream-between-releases.md) cites step 3):
  [ADR 0005](0005-pin-upstream-sources.md) item 5.
- Decision (no Dependabot): [ADR 0005](0005-pin-upstream-sources.md) item 6.
- Consequences (local upstream sources, no download on a clone): [ADR 0005](0005-pin-upstream-sources.md)
  Consequences.
