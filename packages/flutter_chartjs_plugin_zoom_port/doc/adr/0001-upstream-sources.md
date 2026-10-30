# Zoom ADR 0001: Upstream source, name and license

- Status: proposed
- Date: 2026-10-30
- Gate: zoom phase 0. Phase 0 applies the pin, the pin checks, the name, the license and the CI
  checkout while the ADR is proposed (the D3 and ECharts precedent).
- Related: [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) (the pin and the bump
  steps), [ADR 0006](../../../../docs/adr/0006-follow-upstream-between-releases.md) (ledger,
  backports and commit pins), [ADR 0007](../../../../docs/adr/0007-package-names.md) (the name
  rule and the pub.dev examination), [ADR 0009](../../../../docs/adr/0009-add-on-ports.md) (add-on
  ports), [Chart.js ADR 0035](../../../flutter_chartjs_port/doc/adr/0035-third-party-sources.md)
  (the `port_sources.yaml` schema), [Zoom ADR 0002](0002-file-naming-and-layout.md) (the Dart
  paths), [Zoom ADR 0003](0003-host-connection.md) (the connection to the host port)

## Context

**The upstream repository.** [chartjs/chartjs-plugin-zoom](https://github.com/chartjs/chartjs-plugin-zoom)
is the zoom and pan plugin of the Chart.js organization. Its `LICENSE.md` is MIT with the line
`Copyright (c) 2013-2024 chartjs-plugin-zoom contributors`. Its npm package has the peer
dependency `"chart.js": ">=3.2.0"` and no runtime dependency at the commit of item 2.

**Maintenance (GitHub API, 2026-10-30).** The plugin had 29 commits in the 12 months before
2026-10-30. Six people wrote 10 of them. Dependabot wrote the other 19. Of the Chart.js plugins
that the selection examined, zoom had the most commits from people. chartjs-plugin-annotation had
3, and chartjs-plugin-datalabels had no commit after 2024-01. The repository has 623 stars and 75
open issues and pull requests.

**The releases.** The last release is `v2.2.0` (2024-11-26). At `v2.2.0`, `package.json` has the
runtime dependency `hammerjs` `^2.0.8`. Hammer.js is a DOM gesture library. A port of Hammer.js is
out of scope. `master` is 34 commits after `v2.2.0`:

- PR #950 (2026-09-16) replaced Hammer.js with the DOM Pointer Events. `src/gestures.ts` (395 lines)
  is the new pan and pinch recognizer.
- The sources moved to TypeScript (`src/*.ts`).
- PR #968 and PR #969 (2026-09-16 and 2026-09-17) fixed the published type declarations.
- `package.json` on `master` still gives `"version": "2.2.0"`. The milestone 3.0.0 is open.

The head of `master` on 2026-10-30 is `fb81d3316bbf3504903b10d1a9bc8cd99173b5c4` (2026-10-02,
`chore(deps-dev): bump piscina from 4.7.0 to 4.9.4 (#983)`). The branch `release` is 229 commits
behind `master` and has no commit of its own.

**The size at that commit.** `src/` has 12 source files with 1,913 lines and 2 unit test files
(`src/scale.types.test.ts`, `src/utils.test.ts`) with 133 lines. `test/specs/` has 9 spec files
with 62 `it` calls. `test/fixtures/` has 12 fixture configs (`.js`) with 12 PNG images.
`test/index.js` is the set-up of the tests, with the helpers `triggerWheelEvent`,
`dispatchEvent`, `dispatchPointer`, `simulatePan` and `simulatePinch`.

**The test harness.** The tests use chartjs-test-utils `^0.5.0` and chartjs-adapter-date-fns
`^3.0.0` with date-fns `^2.21.1`. The repository has `packages/chartjs_test_utils`, the port of
chartjs-test-utils 0.4.0
([Chart.js ADR 0035](../../../flutter_chartjs_port/doc/adr/0035-third-party-sources.md)). The
range `v0.4.0...v0.5.0` of chartjs-test-utils has 6 commits. They change only `package.json`,
`package-lock.json`, `test/test.js` (1 line) and two CI files. `src/` is the same.

**The host.** The tests use chart.js `^4.4.8`. The Chart.js port is at Chart.js v4.6.1. Thus the
host pin is in the range of the tests and of the peer dependency.

**pub.dev examination (2026-10-30, 16:16 UTC).** The command
`curl -s -o /dev/null -w '%{http_code}' https://pub.dev/api/packages/<name>` gave 404 for
`flutter_chartjs_plugin_zoom_port`, `flutter_chartjs_plugin_zoom`, `chartjs_plugin_zoom`,
`chartjs_plugin_zoom_gallery` and `chartjs_zoom`.

## Decision

1. **The name.** The library package is `flutter_chartjs_plugin_zoom_port`
   (`packages/flutter_chartjs_plugin_zoom_port`), by ADR 0007 item 1 and ADR 0009 item 5. The
   name was free on pub.dev on 2026-10-30 (ADR 0007 item 7). The commit scope is
   `flutter_chartjs_plugin_zoom_port`. The docs name the decisions of this package
   "Zoom ADR NNNN".
2. **The pin.** A shallow git submodule `third_party/chartjs-plugin-zoom` pins the commit
   `fb81d3316bbf3504903b10d1a9bc8cd99173b5c4` of `master`. It is a commit pin of ADR 0006:
   - The version is `2.2.0+fb81d331`: the last release, `+`, and the first 8 hex digits of the
     commit. `chartjsPluginZoomVersion` in `lib/src/upstream.dart` gives it.
     `chartjsPluginZoomPackageVersion` gives the part before `+`, the `version` of the upstream
     `package.json` and of the plugin object.
   - The header version of rule 2 (AGENTS.md) is `v2.2.0+fb81d331`, for example
     `// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/core.ts (MIT, chartjs-plugin-zoom contributors).`
   - In `tool/port_sources.yaml`, `ref` and `commit` are the full commit. A fetch of the commit
     gives the pinned tree. A branch name moves.
3. **The checks.**
   - `test/upstream_test.dart` compares `chartjsPluginZoomPackageVersion` with the `package.json`
     of the submodule, the entry of `tool/port_sources.yaml` with the version, and the gitlink with
     the `commit` of the entry. It also fails on a submodule of `.gitmodules` that no
     `packages/*/tool/port_sources.yaml` pins.
   - `tool/check_upstream_pin.sh` (`upstream:check`, the CI job `upstream-pin`) fails unless the
     gitlink starts with the `<sha8>` of the version, equals the `commit` and the `ref` of the
     entry, and is not the commit of the tag `v2.2.0`. The tag `v2.2.0` must exist. For a release
     pin, the gitlink must be the commit of the tag `v<version>`.
   - The ubuntu legs of the CI job `test` check out the submodule for the upstream test.
4. **The license.** The code of the port is MIT, the license of upstream. The package `LICENSE`
   has the MIT text with `Copyright (c) 2013-2024 chartjs-plugin-zoom contributors` and
   `Copyright (c) 2026 Vasiliy Ditsyak`. `REUSE.toml` has a table for
   `packages/flutter_chartjs_plugin_zoom_port/**` with both holders, after the ECharts table. The
   holder string of the headers and of `port_sources.yaml` is `chartjs-plugin-zoom contributors`.
   The package ports no Chart.js code. Thus its `LICENSE` has no Chart.js notice.
5. **The harness.** The zoom tests use `packages/chartjs_test_utils` as the port of
   chartjs-test-utils `^0.5.0`. The `src/` of 0.4.0 and of 0.5.0 are the same. Thus the port of
   0.4.0 serves the tests, and no second submodule is necessary.
6. **The date adapter.** The time-scale tests of upstream use chartjs-adapter-date-fns. The port
   does not pin it in phase 0. [Zoom ADR 0003](0003-host-connection.md) item 9 gives the rule
   for the time-scale tests.
7. **The bump to 3.0.0.** When upstream tags a release after the pin (for example `v3.0.0`), a
   bump change moves the submodule to that tag, by the steps of ADR 0005 and rule 6 of AGENTS.md.
   The version becomes a plain release, for example `3.0.0`, and `ref` becomes the tag. The
   upstream ledger lists the commits after the pin until then.
8. **Package state.** The package stays `publish_to: none` until its first release. It depends
   on `flutter_chartjs_port` with a path dependency (ADR 0009 item 2).

## Alternatives considered

- **Pin the release `v2.2.0`.** Rejected. It needs Hammer.js, a DOM gesture library. The port of
  Hammer.js is a second port with no value after upstream removed it. The Pointer Events code of
  `master` maps to the events of the Flutter chart host.
- **Wait for the release 3.0.0.** Rejected. The milestone has no date. The commit pin has a
  defined path to the tag (item 7).
- **Pin the head of the branch by name.** Rejected. A branch moves. A pin is a commit.
- **A submodule for chartjs-test-utils 0.5.0.** Rejected. Its `src/` is the `src/` of the pinned
  0.4.0 (item 5).

## Consequences

- `third_party/chartjs-plugin-zoom` is the reference source of the port. It is not built, imported
  or shipped.
- The headers of the ported files name `v2.2.0+fb81d331` until the bump of item 7. The bump
  restamps them.
- The upstream ledger (`doc/upstream-ledger.md`) has no commit after the pin on 2026-10-30.
