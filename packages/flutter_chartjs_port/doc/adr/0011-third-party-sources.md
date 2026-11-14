# Chart.js ADR 0011: Third-party sources

- Status: accepted (2026-10-19)
- Superseded by: [Chart.js ADR 0035](0035-third-party-sources.md) (2026-10-21)
- Date: 2026-10-19
- Supersedes: [Chart.js ADR 0005](0005-third-party-sources.md)
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0011-third-party-sources.md`

## Summary

This ADR listed the other projects that the Chart.js port translated, without pixelmatch and ICU:
`@kurkle/color`, chartjs-test-utils and fdlibm 5.3. Each source with a git repository was a reference-only
shallow submodule at its release tag. fdlibm was an unchanged copy of four netlib files. `port_sources.yaml`
listed each project with its pin, license and Dart targets. A new source needed an entry, a notice, a
`REUSE.toml` table and a header.

## Where each part went

- Item 1 (the submodules): [Chart.js ADR 0035](0035-third-party-sources.md) item 1.
- Item 2 (the copies, `third_party/fdlibm/`): [Chart.js ADR 0035](0035-third-party-sources.md) item 2.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) removes the fdlibm copy.
- Item 3 (the source list `port_sources.yaml`): [Chart.js ADR 0035](0035-third-party-sources.md) item 3.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) removes the fdlibm entry.
- Item 4 (the Dart targets): [Chart.js ADR 0035](0035-third-party-sources.md) item 4.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) removes the fdlibm targets.
- Item 5 (versions follow Chart.js): [Chart.js ADR 0035](0035-third-party-sources.md) item 5.
- Item 6 (licensing): [Chart.js ADR 0035](0035-third-party-sources.md) item 6.
  [Chart.js ADR 0122](0122-dart-math-without-fdlibm.md) removes the fdlibm notice and `LICENSES/SunPro.txt`.
- Item 7 (reference only): [Chart.js ADR 0035](0035-third-party-sources.md) item 7.
- Item 8 (new sources): [Chart.js ADR 0035](0035-third-party-sources.md) item 8.
