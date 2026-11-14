# Chart.js ADR 0005: Third-party sources

- Status: accepted (2026-10-18)
- Date: 2026-10-17
- Superseded by: [Chart.js ADR 0011](0011-third-party-sources.md) (2026-10-19)
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0005-third-party-sources.md`

## Summary

This ADR pinned the other projects that the Chart.js port translated: `@kurkle/color`, chartjs-test-utils,
pixelmatch and fdlibm. A source with a git repository became a reference-only submodule at its release tag.
fdlibm became an unchanged copy of netlib files. `port_sources.yaml` listed each project with its pin, license
and Dart target. Dev-time tools read and ran reference sources, but no tool built or shipped them.

## Where each part went

- Item 1 (submodules at release tags): [Chart.js ADR 0035](0035-third-party-sources.md) item 1.
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) §4 removes the image comparison and thus
  pixelmatch.
- Item 2 (copies, `third_party/fdlibm/`): [Chart.js ADR 0035](0035-third-party-sources.md) item 2.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) removes the fdlibm copy.
- Item 3 (the source list `port_sources.yaml`): [Chart.js ADR 0035](0035-third-party-sources.md) item 3.
- Item 4 (Dart targets): [Chart.js ADR 0035](0035-third-party-sources.md) item 4.
  [Chart.js ADR 0034](0034-no-display-only-js-exactness.md) §4 removes the pixelmatch target.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) removes the fdlibm targets.
- Item 5 (versions follow Chart.js): [Chart.js ADR 0035](0035-third-party-sources.md) item 5.
- Item 6 (licensing): [Chart.js ADR 0035](0035-third-party-sources.md) item 6.
- Item 7 (reference-only use of each source, a clarification of root ADR 0002):
  [Chart.js ADR 0035](0035-third-party-sources.md) item 7.
- Item 8 (the status line of [ADR 0002](../../../../docs/adr/0002-pin-upstream-sources.md)): removed by
  [Chart.js ADR 0011](0011-third-party-sources.md).
  [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) supersedes ADR 0002.
