# ADRs

An ADR (architecture decision record) records one decision. This file has the rules and the template of
the ADRs of all ports, and the list of the ADRs of this folder. Each folder below has a `README.md` with
its own list.

- `docs/adr/`: decisions for all ports ("ADR NNNN").
- `packages/flutter_chartjs_port/doc/adr/`: the Chart.js port ("Chart.js ADR NNNN").
- `packages/flutter_d3_port/doc/adr/`: the D3 port ("D3 ADR NNNN").
- `packages/flutter_echarts_port/doc/adr/`: the ECharts port ("ECharts ADR NNNN").
- `packages/flutter_chartjs_plugin_zoom_port/doc/adr/`: the zoom port ("Zoom ADR NNNN").
- `packages/flutter_chartjs_chart_sankey_port/doc/adr/`: the sankey port ("Sankey ADR NNNN").

## Rules

1. An ADR reads on its own. It does not tell the reader to combine it with other ADRs.
2. An accepted ADR does not change. A changed decision gets a new ADR that states the complete current
   decision and supersedes the old ADR, in whole or in part.
3. Only the header of an accepted ADR can change: a "Superseded by" or "Superseded in part by" line, a
   "Still in force" line, or the fix of a broken header line.
4. Code, docs and tool messages cite the ADR that holds the current rule.
5. An ADR that is superseded in whole, or rejected, can become a stub. The stub keeps the title, the header
   lines except "Related", a summary of at most 5 lines, a map from each old section to its new place, and the command that
   shows the full text (`git show <commit>:<path>`). The stub of a rejected ADR keeps the reason of the
   rejection. The file name and the number do not change. The maintainer approved this rule on 2026-11-14.
6. `dart run tool/adr_index.dart` writes the list of each folder from the header lines. With `--check`
   (`dart run melos run adr:index:check`, also in `check:port` and in the CI job `port-checks`), it fails
   on a stale list, and on a "Supersedes" line without the matching "Superseded by" or "Superseded in
   part by" line in the old ADR, or the reverse. A proposed ADR names its targets, but the targets name it
   only when it is accepted.

## Template

The target size is 600 words. The limit is 1,000 words. An ADR that merges several ADRs into one can
have up to 2,000 words.

```markdown
# Chart.js ADR NNNN: <title>

- Status: proposed
- Date: 2026-11-14
- Supersedes: [Chart.js ADR 0045](0045-reference-engine-arm64.md) §4 (or: nothing)
- Related: at most 3 links, with no description

## Context

At most 150 words: the problem and the constraint.

## Decision

1. One rule in each numbered item, code first. A number is never used again for another rule.

## Rejected

- <option>: the reason, in one line.

## Consequences

At most 5 bullets.

## Tests

The test files, with no description.
```

Some content goes to other places:

- Measurements go to `performance.md` of the package. The ADR has one line: "Figures: performance.md §N".
- The review history, design panels, gates, CI runs and test counts go to the commit message or to
  `.handover/`.
- Lists of files, guards and tests go to the dartdoc and to the tests.
- A difference from upstream goes to `differences.md`.
- An ADR does not copy upstream code or tables of upstream lines.
- An ADR that supersedes an ADR with cited section numbers keeps those section numbers for the same rules.

## List

The list below comes from the header of each ADR (`dart run tool/adr_index.dart`).

<!-- adr-index:start -->
- [0001](0001-native-ports-not-wrappers.md) Native ports, not wrappers: accepted.
- [0002](0002-pin-upstream-sources.md) Pin upstream sources as git submodules at release tags: accepted, superseded by 0005.
- [0003](0003-package-names.md) Package names: accepted, superseded by 0007.
- [0004](0004-follow-upstream-between-releases.md) Follow upstream between releases: accepted, superseded by 0006.
- [0005](0005-pin-upstream-sources.md) Pin upstream sources: accepted, supersedes 0002.
- [0006](0006-follow-upstream-between-releases.md) Follow upstream between releases: accepted, supersedes 0004.
- [0007](0007-package-names.md) Package names: accepted, supersedes 0003.
- [0008](0008-shared-js-runtime-and-port-tools.md) Shared JS runtime and port tools: proposed.
- [0009](0009-add-on-ports.md) Ports of add-on libraries: proposed.
- [0010](0010-primary-constructors.md) Primary constructors: accepted.
<!-- adr-index:end -->
