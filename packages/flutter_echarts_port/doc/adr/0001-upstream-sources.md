# ECharts ADR 0001: Upstream sources

- Status: proposed
- Date: 2026-10-21
- Gate: ECharts phase 0. Phase 0 applies the pins, the pin checks, the license, the NOTICE and the
  CI checkout while the ADR is proposed (the D3 precedent).
- Related: [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) (the pin and the bump
  steps), [ADR 0006](../../../../docs/adr/0006-follow-upstream-between-releases.md) (ledger,
  backports and commit pins), [ADR 0007](../../../../docs/adr/0007-package-names.md) (the package
  name), [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) (the shared
  port tools), [Chart.js ADR 0035](../../../flutter_chartjs_port/doc/adr/0035-third-party-sources.md)
  (the precedent for other projects, accepted 2026-10-21),
  [D3 ADR 0001](../../../flutter_d3_port/doc/adr/0001-upstream-sources.md) (the template: holder
  rule, components table, `notices` key), [ECharts ADR 0002](0002-file-naming-and-layout.md) (the
  Dart paths and the `file_names` line), [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)
  (the spec harness and the reference generators that read `dist/`),
  [ECharts ADR 0006](0006-renderer-and-canvas-layer.md) (the SVG DOM patch is `n/a`),
  [ECharts ADR 0007](0007-environment-host-and-input-events.md) (the environment detection is
  replaced), [ECharts ADR 0008](0008-dates-locales-and-formatting.md) (the locale files),
  [ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md) (the themes)

## Context

[ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md) pins the upstream repository of each
port as a reference-only shallow submodule under `third_party/`, at a release tag. The tracked
version also lives in code. Two checks compare that version with the pin. Each port lists the
other projects that it takes code from in its own ADR.
[ADR 0006](../../../../docs/adr/0006-follow-upstream-between-releases.md) adds the upstream ledger,
the backports and the commit pins.
[Chart.js ADR 0035](../../../flutter_chartjs_port/doc/adr/0035-third-party-sources.md) applies these
rules to the Chart.js port. The porting lead accepted it on 2026-10-21. It supersedes Chart.js ADR
0011.
[D3 ADR 0001](../../../flutter_d3_port/doc/adr/0001-upstream-sources.md) applies them to the D3
port. A Chart.js ADR or a D3 ADR binds only its own port. Thus this ADR states each rule that it
takes.

In this ADR, a path `echarts/<path>` or `zrender/<path>` is relative to `third_party/`, at the pin.
A path `packages/flutter_chartjs_port/tool/<path>` names its lines at commit `4d50cd8` of `main`.

**Two repositories.** Apache ECharts lives in `apache/echarts`. Its renderer zrender lives in
`ecomfe/zrender`. ECharts imports zrender by the bare specifier `zrender/src/<path>`, for example
`echarts/src/util/number.ts:29`. Thus the port needs both repositories from phase 1.

**Versions.**
- `echarts/package.json:3` gives `"version": "6.1.0"`. `:76` requires `"tslib": "2.3.0"`. `:77`
  requires `"zrender": "6.1.0"`. Both requirements are exact versions, not ranges.
- `zrender/package.json:3` gives `"version": "6.1.0"`. `zrender/package.json:36` requires
  `"tslib": "2.3.0"`.
- The tag `6.1.0` of `apache/echarts` names the commit `c5a48f5f97d23e5379720870b8444cd05b50ffb4`.
  Its commit date is 2026-05-13. The tag `6.1.0-rc.2` names the same commit.
- The tag `6.1.0` of `ecomfe/zrender` names the commit `32b6686724832dcea026e9443d056ea216ed0ab2`.
  Its commit date is 2026-05-04.
- Both tags are lightweight. `git cat-file -t 6.1.0` gives `commit` in each submodule.
- The release tags have no `v` prefix. One old tag of each repository has a `v`: `v4.2.1-rc1` of
  ECharts and `v4.0.6` of zrender (`git ls-remote --tags`, 2026-10-21).
- On 2026-10-21, neither repository has a release tag after `6.1.0`. Only the `6.1.0-rc.*` tags
  come before it.
- The default branch of both repositories is `master` (`git ls-remote --symref <url> HEAD`).

**Licenses.**
- `echarts/LICENSE:1-202` is the Apache-2.0 text. The file has no copyright line of a holder. Its
  only `Copyright` line is the template line of the appendix (`echarts/LICENSE:190`).
- `echarts/LICENSE:209-222` is the section "Apache ECharts Subcomponents". It names four files
  that embed d3 code under BSD-3-Clause (`:216-221`). It refers to `/licenses/LICENSE-d3`
  (`:222`).
- `echarts/licenses/LICENSE-d3` has 27 lines. Line 1 is `Copyright 2010-2016 Mike Bostock`. The
  other lines are the BSD-3-Clause text.
- `echarts/NOTICE:1-5` gives `Apache ECharts`, `Copyright 2017-2026 The Apache Software Foundation`
  and the ASF attribution sentence.
- Each of the 596 `.ts` files of `echarts/src/` holds the 18-line ASF license comment block. In 589
  files, the block is at lines 1-18 (563 with `* ` lines, 26 with ` * ` lines). In 6 files a blank
  line comes first. In `src/visual/LegendVisualProvider.ts`, an import and a blank line come
  first. Each of the 28 `.ts` files of `echarts/test/ut/` also holds it.
- `zrender/LICENSE` is the BSD-3-Clause text. Its line 3 is `Copyright (c) 2017, Baidu Inc.`.
  `zrender/package.json:31` gives `"license": "BSD-3-Clause"`.
- Two zrender files hold a license comment block. `zrender/src/zrender.ts:1-9` is a banner with
  `Copyright (c) 2013, Baidu Inc.`. `zrender/src/core/OrientedBoundingRect.ts:1-18` is the ASF
  block of ECharts.

**Holder strings.** Tool 2 of the Chart.js port compares the holder of each `// Ported from` line
with `port_sources.yaml`. The package `LICENSE` must contain the same string. The last
`REUSE.toml` table of the file must list it
(`packages/flutter_chartjs_port/tool/src/port_headers.dart:947-967`). D3 ADR 0001 item 8 takes the
holder from the first copyright line of the repository `LICENSE`. The ECharts `LICENSE` has no
such line. Apache-2.0 puts the attribution in `NOTICE`.

The scaffold `packages/flutter_echarts_port/LICENSE` has 202 lines. It is the same text as
`LICENSES/Apache-2.0.txt` and as `echarts/LICENSE:1-202` (`diff`). It does not contain
`The Apache Software Foundation`. Thus the Chart.js holder check fails for each ECharts header
with this `LICENSE` alone.

**Header grammar.** The Chart.js pattern of a `// Ported from` line reads the project as `(\S+)`
(`packages/flutter_chartjs_port/tool/src/headers.dart:13-16`). The project name `Apache ECharts` has a
space. Thus the pattern does not match an ECharts header. The pattern reads the license up to the
first comma and the holder up to `).`. Thus `The Apache Software Foundation` and `Baidu Inc.` are
valid holders. The port-only marker (`headers.dart:19-21`) and the backport line (`:24-26`) name
Chart.js. [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) item 8 moves
these constants into a config of each port in stage 1.

**Language value.** The scaffold `tool/port_sources.yaml` gives `language: ts` for both entries
(`:52`, `:69`). Its comment at `:20` reads `"ts" is TypeScript`. The Chart.js tools accept only
`js` and `c` (`packages/flutter_chartjs_port/tool/src/port_headers.dart:89`). Tool 3 examines a file
only when its project has the language `js` (`packages/flutter_chartjs_port/tool/src/js_semantics.dart:236-240`).
The Chart.js file defines `js` as "JavaScript or TypeScript"
(`packages/flutter_chartjs_port/tool/port_sources.yaml:13`). Chart.js itself has TypeScript sources,
for example `src/helpers/helpers.math.ts`.

**Code from other projects.** Item 12 gives the scan and its results. The ECharts `LICENSE` names
four d3 files. The scan finds a fifth file with the same d3 block: `echarts/src/scale/Time.ts:20-28`.
zrender holds code that credits node-timsort, jsdiff and tween.js.

**Scaffold.** The scaffold change before this ADR did these steps:
- It added the two submodules (`.gitmodules:149-156`, `shallow = true`).
- It extended `tool/check_upstream_pin.sh:189-238` with the ECharts pins.
- It wrote `packages/flutter_echarts_port/test/upstream_test.dart`.
- It changed `packages/flutter_d3_port/test/upstream_test.dart`. That test now reads each
  `packages/*/tool/port_sources.yaml`, not two fixed files.
- It added the `REUSE.toml` table of the package, `LICENSES/Apache-2.0.txt`, the commit scope and
  the CI checkout.

**Maintainer decisions.** The maintainer did not yet decide the points of item 1. This ADR records
the proposals with the rest of the design. The porting lead (the agent that runs the phase) owns
the ADR statuses (AGENTS.md, the maintainer, 2026-10-21). It accepts this ADR when phase 0
implements it and its gates are green. The maintainer selects only the points of item 1. One of
them is the package name of ADR 0007 item 9. Thus the acceptance also waits for that selection.

## Decision

1. **Points for the maintainer.** This ADR proposes four decisions. The maintainer selects them.
   Phase 0 applies them while the ADR is proposed.
   1. The package is `flutter_echarts_port` (item 2).
      [ADR 0007](../../../../docs/adr/0007-package-names.md) item 9 says that the maintainer selects
      the name.
   2. The port's own code is Apache-2.0, as upstream ECharts (item 10).
   3. ECharts is at its newest release tag. zrender is at the exact version that the pinned
      ECharts `package.json` requires (item 4).
   4. The zrender files that credit node-timsort, jsdiff and tween.js get components and
      `notices` items (items 12 and 13).
      The alternative is the fsum rule of D3 ADR 0001 item 11.
2. **Package name (ADR 0007 item 9).** The library package is `flutter_echarts_port`, in
   `packages/flutter_echarts_port`. It stays `publish_to: none` until 0.1.0.
   - The name has the form `flutter_<library>_port` of ADR 0007 item 1. The form
     `flutter_<library>` is not free. `flutter_echarts` is a published WebView wrapper of ECharts
     ([the prior-art survey](../prior-art/README.md)).
   - The examination of ADR 0007 item 7 ran at 2026-10-21T07:51Z. The command was
     `curl -s -o /dev/null -w '%{http_code}' https://pub.dev/api/packages/<name>`.
   - `flutter_echarts_port`, `echarts_gallery` and `echarts_test_utils` gave 404.
   - The gallery app is `apps/echarts_gallery` (ADR 0007 item 4), from ECharts phase 6.
   - `echarts_test_utils` is the reserved name of a port-only harness package (ADR 0007 item 3).
     Phase 0 does not create it. [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)
     keeps the harness in `test/support/`.
   - The commit scope is `flutter_echarts_port` (ADR 0007 item 8).
   - Until the first release, a rename costs nothing (ADR 0007 item 10).
3. **Upstream repository and the second project.**
   - `apache/echarts` is the upstream repository of
     [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md). `third_party/echarts` pins it
     at the tag `6.1.0`, commit `c5a48f5f`.
   - The port-only `packages/flutter_echarts_port/lib/src/upstream.dart` holds
     `echartsVersion = '6.1.0'`.
   - zrender is the second project of the port, as `@kurkle/color` is for Chart.js.
     `third_party/zrender` pins it at the tag `6.1.0`, commit `32b66867`.
   - zrender gets its own constant `zrenderVersion = '6.1.0'` in the same file. ECharts requires
     one exact zrender version. The two checks of item 7 compare this constant with both
     `package.json` files. The Chart.js port and the D3 port keep no constant for their other
     projects.
4. **Pin rule.**
   - `third_party/echarts` is at the newest release tag of `apache/echarts`. Pre-release tags, for
     example `6.1.0-rc.2`, do not count.
   - `third_party/zrender` is at the tag of the exact version that `echarts/package.json` requires
     (`:77`). It is not at the newest zrender tag.
   - On 2026-10-21, both rules give `6.1.0`. Neither repository has a newer release tag.
5. **Tag form.** The tags have no `v` prefix.
   - The header version and the `version` of each entry are `6.1.0`.
   - The `ref` of each entry is `"6.1.0"`. Both tags are lightweight. Thus the `commit` of each
     entry is the commit that the tag names.
   - A commit pin writes `6.1.0+<sha8>`, with no `v`. The Chart.js form is `v4.5.1+7169e651`.
6. **Submodules.** Each repository is a reference-only shallow submodule at
   `third_party/<repository name>`.

   | Submodule | URL | Tag | Commit | Date | SPDX | Holder | Copyright line at the pin |
   |---|---|---|---|---|---|---|---|
   | `third_party/echarts` | `https://github.com/apache/echarts` | `6.1.0` | `c5a48f5f97d23e5379720870b8444cd05b50ffb4` | 2026-05-13 | Apache-2.0 | `The Apache Software Foundation` | `Copyright 2017-2026 The Apache Software Foundation` (`NOTICE:2`) |
   | `third_party/zrender` | `https://github.com/ecomfe/zrender` | `6.1.0` | `32b6686724832dcea026e9443d056ea216ed0ab2` | 2026-05-04 | BSD-3-Clause | `Baidu Inc.` | `Copyright (c) 2017, Baidu Inc.` (`LICENSE:3`) |

   - The date is the commit date of the tagged commit.
   - Each `.gitmodules` entry has `shallow = true`, as the Chart.js and D3 entries do.
   - The analysis excludes the submodules (`third_party/**` in `analysis_options.yaml`).
   - `dart run melos run upstream` clones every `third_party` submodule at its pin.
7. **Pin checks.**
   - `tool/check_upstream_pin.sh` (`dart run melos run upstream:check`, CI job `upstream-pin`)
     reads `echartsVersion` and `zrenderVersion` from `lib/src/upstream.dart` (`:192-193`).
   - The script compares the `ref` of each ECharts entry with its constant (`:213-232`).
   - It compares each gitlink with the commit of `refs/tags/<version>` (`check_pin`, `:122-157`).
     `git ls-remote` gives that commit. The script needs no submodule checkout.
   - It fails when one of the two entries is absent (`:235-238`).
   - `packages/flutter_echarts_port/test/upstream_test.dart` (`@TestOn('vm')`) runs these tests:
     - It compares `echartsVersion` with the `version` of `echarts/package.json`.
     - It compares `zrenderVersion` with the `zrender` dependency of `echarts/package.json`.
     - It compares `zrenderVersion` with the `version` of `zrender/package.json`.
     - It compares each gitlink (`git ls-files -s`) with the `commit` of its entry. This command
       reads the index. Thus it works for staged and for committed gitlinks.
   - The script and both port tests fail on a submodule of `.gitmodules` that no entry of a
     `packages/*/tool/port_sources.yaml` pins (`tool/check_upstream_pin.sh:240-250`). Thus a new
     submodule of any port needs an entry.
   - The D3 test needed this change for the third file. Phase 0 changes no other D3 file.
   - From ECharts phase 1, the shared tool 2 of `port_tools`
     ([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)) also compares
     each ECharts gitlink with its entry.
8. **Source list.** `packages/flutter_echarts_port/tool/port_sources.yaml` has two entries. They
   have the keys of the Chart.js file: `header`, `version`, `version_source`, `url`, `language`,
   `spdx`, `holder`, `pin` and `targets`.
   - `header` is `Apache ECharts` or `zrender`. `version_source` names the constant of item 3.
   - `language` is `js` for both entries. `js` is JavaScript or TypeScript, as in the Chart.js
     file. Phase 0 changes the scaffold value `ts` and its comment. Otherwise tool 3 skips every
     ECharts and zrender file.
   - `targets` holds the map of [ECharts ADR 0002](0002-file-naming-and-layout.md): `src/` to
     `lib/src/echarts/` or `lib/src/zrender/`, and `test/ut/spec/` to `test/specs/echarts/` or
     `test/specs/zrender/`.
   - The change that ports the first harness file adds its file target, for example
     `test/ut/core/utHelper.ts`.
   - `files` and `file_index` come with the first ported file.
   - The `notices` key of item 13 records code from a third project inside a repository.
9. **[ADR 0006](../../../../docs/adr/0006-follow-upstream-between-releases.md) for ECharts.**
   - **Status unit.** The status unit is one upstream source file, as in Chart.js and D3. A
     "module" of ADR 0006 items 2, 4 and 5 is one such file. [parity.md](../parity.md) groups the
     files by repository and folder.
   - **Ledger.** [The upstream ledger](../upstream-ledger.md) has two sections, `echarts` and
     `zrender`. A row is one merged upstream PR after the pinned tag on `master`. A commit without
     a PR also gets a row. The section lines read `Pinned: 6.1.0 (c5a48f5f). Watching: master.`
     and `Pinned: 6.1.0 (32b66867). Watching: master.`
   - **Bump first.** Before a file goes from `not started` to `in progress`, the porter lists the
     newer release tags of its repository (ADR 0006 item 4).
   - **Bump unit.** An ECharts bump moves `third_party/echarts`, its entry, `echartsVersion` and
     the headers of the ECharts files. ADR 0005 item 5 gives the steps.
   - **zrender follows ECharts.** The new `echarts/package.json` can name another zrender version.
     Then the same change also moves `third_party/zrender`, its entry, `zrenderVersion` and the
     zrender headers. The upstream test of item 7 fails on a mismatch.
   - **zrender alone.** A zrender bump without an ECharts bump can go only to the version that the
     pinned `echarts/package.json` requires. Thus, while ECharts stays at `6.1.0`, no zrender
     bump is possible. A newer zrender tag does not count for ADR 0006 item 4 until an ECharts
     release requires it.
   - **Commit pin.** The two conditions of ADR 0006 item 5 apply per repository. On 2026-10-21,
     both tags are less than 12 months old. Thus the first condition is false until 2027-05-04
     for zrender and until 2027-05-13 for ECharts.
   - **Commit pin version.** A commit pin writes `6.1.0+<sha8>` into the `version` of the entry
     and into its constant. A commit pin of ECharts reads the zrender version of the reviewed
     `package.json`. The PR of the first commit pin extends the checks of item 7, as ADR 0006
     states.
   - **Backport lines.** A backport line reads `// Upstream backport: apache/echarts@<sha8> (#<PR>).`
     or `// Upstream backport: ecomfe/zrender@<sha8> (#<PR>).`. The shared tool 2 takes
     `<owner>/<repo>` from the `url` of the entry (ADR 0008 item 8).
10. **License of the port's code.** The port's own code is Apache-2.0. Apache-2.0 section 4 gives
    four conditions for a redistribution of a derivative work:
    - **4(a), a copy of the license.** `packages/flutter_echarts_port/LICENSE` is the plain
      Apache-2.0 text (202 lines). It has no copyright line. Phase 1 adds the components of
      item 12 after the text.
    - **4(b), a notice in each changed file.** The `// Ported from` line of each Dart file states
      that the file is a Dart port of the named source file. The D3 port uses the same rule for
      ColorBrewer (D3 ADR 0001 item 10).
    - **4(c), the notices of the source form.** Each ported file keeps the upstream license
      comment block verbatim after its header lines (item 11). Dart accepts the `/* */` form.
      Thus the block stays byte for byte.
    - **4(d), the NOTICE.** `packages/flutter_echarts_port/NOTICE` starts with
      `flutter_echarts_port` and `Copyright 2026 Vasiliy Ditsyak`. One sentence states that the
      package is a Dart port of Apache ECharts. Then `echarts/NOTICE:1-5` follows unchanged.
    - `REUSE.toml` has the table `packages/flutter_echarts_port/**` (`REUSE.toml:47-57`). Its
      license is `Apache-2.0`. Its copyrights are `2017-2026 The Apache Software Foundation` and
      `2026 Vasiliy Ditsyak`. The table comes after the D3 table. The tables of item 12 come after
      it.
    - Phase 0 adds `LICENSES/Apache-2.0.txt`. `LICENSES/BSD-3-Clause.txt` and `LICENSES/MIT.txt`
      are present.
    - **Holder source.** The shared tool 2 of ADR 0008 stage 1 reads the holder from the package
      `LICENSE` or from the package `NOTICE`. This is a config value of the ECharts port. The
      Chart.js and D3 packages have no `NOTICE`. Thus their check does not change.
11. **Holder strings and the header block.**
    - Each project has one holder string. The header, `port_sources.yaml`, the package `LICENSE`
      or `NOTICE` and the last `REUSE.toml` table of the file use this string.
    - The holder is the first copyright line of the repository `LICENSE` at the pin, by the rule
      of D3 ADR 0001 item 8. The rule omits `Copyright`, `(c)`, the years and the comma before
      the name.
    - The ECharts `LICENSE` has no copyright line. Thus the ECharts holder comes from the first
      copyright line of `echarts/NOTICE` (`:2`).

    | Holder | Project | Source of the string |
    |---|---|---|
    | `The Apache Software Foundation` | Apache ECharts | `echarts/NOTICE:2` |
    | `Baidu Inc.` | zrender | `zrender/LICENSE:3` |

    Header examples:
    - `// Ported from Apache ECharts 6.1.0 src/util/number.ts (Apache-2.0, The Apache Software Foundation).`
    - `// Ported from Apache ECharts 6.1.0 test/ut/spec/util/number.test.ts (Apache-2.0, The Apache Software Foundation).`
    - `// Ported from zrender 6.1.0 src/core/matrix.ts (BSD-3-Clause, Baidu Inc.).`

    The port-only marker of the whole package is
    `// Original code, not ported from Apache ECharts: <reason>.` A port-only file of the zrender
    side uses the same marker.

    The header block of a ported file has this order:
    1. Line 1: the `// Ported from` line.
    2. Zero or more backport lines (item 9).
    3. `// ignore_for_file: file_names` when the file name fails the lint
       ([ECharts ADR 0002](0002-file-naming-and-layout.md)).
    4. The upstream license comment block, verbatim, when the upstream file has one. These blocks
       exist: the ASF block of each ECharts file, `zrender/src/zrender.ts:1-9`,
       `zrender/src/core/OrientedBoundingRect.ts:1-18`, and the d3 block of the five d3 files
       (item 12).
    5. Then `library;`, the imports and the code.

    The project name `Apache ECharts` has a space. The shared tool 2 of ADR 0008 stage 1 reads the
    project with the lazy pattern `(.+?)` before the version. This pattern gives the same result
    for each Chart.js and D3 header. Thus no Chart.js or D3 header changes.
12. **Other license components.** Each component is part of the change that ports the first file
    that it covers (AGENTS.md Licensing). A new `LICENSES/` file is part of the change with its
    first `REUSE.toml` annotation. `reuse lint` fails on a license file that no annotation uses.

    | Component | Evidence at the pin | SPDX | Holder string | Lines in the package `LICENSE` | Form | `LICENSES/` | `REUSE.toml` table | First phase |
    |---|---|---|---|---|---|---|---|---|
    | zrender, the whole repository | `zrender/LICENSE:3`, `zrender/package.json:31` | BSD-3-Clause | `Baidu Inc.` | `Copyright (c) 2017, Baidu Inc.` | a separate component with the full BSD-3-Clause text | `BSD-3-Clause.txt` (present) | `lib/src/zrender/**`, `test/specs/zrender/**` and the zrender harness files: `"BSD-3-Clause AND Apache-2.0"`, `2017 Baidu Inc.` and the port line | 1 |
    | d3, five ECharts files | `echarts/LICENSE:209-222`, `echarts/licenses/LICENSE-d3:1-27`, the d3 block of each file | BSD-3-Clause | `Mike Bostock` | `Copyright 2010-2016 Mike Bostock` | a separate component with the text of `LICENSE-d3` | `BSD-3-Clause.txt` (present) | the Dart ports of the five files: `"Apache-2.0 AND BSD-3-Clause"`, the ASF line, `2010-2016 Mike Bostock` and the port line | 1 |
    | Apache ECharts code inside zrender | `zrender/src/core/OrientedBoundingRect.ts:1-18` | Apache-2.0 | `The Apache Software Foundation` | none: the package `NOTICE` holds the ASF line | the package license | `Apache-2.0.txt` (present) | the Dart port of the file: `"Apache-2.0 AND BSD-3-Clause"`, the ASF line, `2017 Baidu Inc.` and the port line | 2 |
    | node-timsort | `zrender/src/core/timsort.ts:1` | MIT | `Marco Ziccardi` | `Copyright (c) 2015 Marco Ziccardi` | a separate component with the full MIT text | `MIT.txt` (present) | the Dart port of the file: `"MIT AND BSD-3-Clause AND Apache-2.0"`, `2015 Marco Ziccardi`, `2017 Baidu Inc.` and the port line | 2 |
    | jsdiff | `zrender/src/core/arrayDiff.ts:1-2` | BSD-3-Clause | `Kevin Decker` | `Copyright (c) 2009-2015, Kevin Decker <kpdecker@gmail.com>` | a separate component with the full BSD-3-Clause text | `BSD-3-Clause.txt` (present) | the Dart port of the file: `"BSD-3-Clause AND Apache-2.0"`, `2009-2015 Kevin Decker`, `2017 Baidu Inc.` and the port line | 2 |
    | tween.js | `zrender/src/animation/easing.ts:1-5` | MIT | `Tween.js authors` | `Copyright (c) 2010-2012 Tween.js authors.`, `Easing equations Copyright (c) 2001 Robert Penner` | a separate component with the full MIT text | `MIT.txt` (present) | the Dart port of the file: `"MIT AND BSD-3-Clause AND Apache-2.0"`, `2010-2012 Tween.js authors`, `2001 Robert Penner`, `2017 Baidu Inc.` and the port line | 3 |

    - **d3.** These are the five files and their phases:
      - `src/util/number.ts` (block `:20-27`, `quantile`), phase 1.
      - `src/scale/Time.ts` (block `:20-28`, `scaleLevels`, now `scaleIntervals` at `:285`),
        phase 4.
      - `src/chart/treemap/treemapLayout.ts` (block `:20-28`), phase 8.
      - `src/chart/tree/layoutHelper.ts` (block `:20-29`), phase 8.
      - `src/chart/graph/forceHelper.ts` (block `:20-28`), phase 8.

      The ECharts `LICENSE` names only four of them. `src/scale/Time.ts` has the same block. It
      refers to the same `/licenses/LICENSE-d3`. Thus the component covers five files. The d3 code
      comes through ECharts. The port pins no d3 repository for it. The D3 port pins d3 v7.9.0
      for its own code. The two ports share no file (ADR 0008 item 1).
    - **Apache ECharts code inside zrender.** The package license is already Apache-2.0. The
      package `NOTICE` already holds the ASF line. Thus the component adds no text to `LICENSE`.
    - **node-timsort.** The file `zrender/src/core/timsort.ts` has 671 lines. Its line 1 is the
      URL `https://github.com/mziccard/node-timsort`. It has no notice. It keeps the names of
      `src/timsort.js` on the default branch of node-timsort: `minRunLength`, `makeAscendingRun`,
      `reverseRun`, `binaryInsertionSort`, `gallopLeft`, `gallopRight` and the constants
      `DEFAULT_MIN_MERGE = 32` and `DEFAULT_MIN_GALLOPING = 7` (`gh api`, 2026-10-21). Thus the
      file is a translation of the node-timsort code, not a reference to an algorithm.
    - **jsdiff.** `zrender/src/core/arrayDiff.ts:2` reads
      `// Modified from https://github.com/kpdecker/jsdiff/blob/master/src/diff/base.js`. The
      jsdiff `LICENSE` is BSD-3-Clause (`gh api`, 2026-10-21).
    - **tween.js.** `zrender/src/animation/easing.ts:2` says in Chinese that the easing code comes
      from `https://github.com/sole/tween.js/blob/master/src/Tween.js`. The tween.js `LICENSE` is
      MIT. It also names Robert Penner for the easing equations (`gh api`, 2026-10-21).
    - **Date of the third-party licenses.** The node-timsort, jsdiff and tween.js licenses come
      from the default branches on 2026-10-21. The commit that zrender copied is not recorded. The
      change that adds a component compares the license text at the oldest tag of that project
      that the zrender history allows. It records the result in the component.
    - **No component.** These cases need no notice:
      - Zepto.js, `zrender/src/core/env.ts:54-56` (MIT, `(c) 2010-2013 Thomas Fuchs`). The
        comment stands above `detect` (`:58`). [ECharts ADR 0007](0007-environment-host-and-input-events.md)
        replaces the detection (row `platform-env-detect`). Thus no Zepto code enters the port.
      - snabbdom, `zrender/src/svg/patch.ts:1-9` (MIT). The DOM patch is `n/a`
        ([ECharts ADR 0006](0006-renderer-and-canvas-layer.md)).
      - tslib 2.3.0 (`echarts/package.json:76`, `zrender/package.json:36`). tslib holds the emit
        helpers of the TypeScript compiler. The port translates the TypeScript source, not the
        emitted code.
      - The commented-out `zOrder` after the earcut URL (`zrender/src/tool/morphPath.ts:530-549`).
        The port keeps the comment and ports no code from it.
      - References to algorithms, papers, bugs and browser behavior. Examples are
        `zrender/src/core/curve.ts:206`, `zrender/src/core/event.ts:184`,
        `zrender/src/core/PathProxy.ts:83`, `echarts/src/chart/treemap/treemapLayout.ts:200` and
        `echarts/src/util/number.ts:375`. D3 ADR 0001 item 10 gives the same rule.
      - `zrender/src/dom/HandlerProxy.ts:91` names hand.js. ECharts ADR 0007 replaces the file.
      - `echarts/src/coord/geo/geoTypes.ts:154-155` names the d3-geo stream API for type
        compatibility. The lines hold no d3 code.
      - The `@author` lines of zrender files (`src/core/bbox.ts:2`, five files of
        `src/svg-legacy/`). They name zrender contributors. The zrender `LICENSE` covers them.
    - **Review in phase 3.** `zrender/src/tool/morphPath.ts:551-552` names
      `https://github.com/w8r/hilbert/blob/master/hilbert.js#L30` above `hilbert` (`:553`). The
      w8r/hilbert `LICENSE` is the Apache-2.0 text with no copyright line (`gh api`, 2026-10-21).
      The phase 3 change that ports `morphPath.ts` compares `hilbert` with that file. A copy gets
      a `notices` item by item 13. Else the URL comment stays with no notice.
    - **Scan.** The scan ran on 2026-10-21 over `echarts/src` and `zrender/src` at the pins. It
      used these commands:
      1. `grep -rniE 'copyright|@license|licensed under|MIT license|BSD'`, without the lines of
         the ASF block.
      2. `grep -rlE 'A third-party license is embedded'`: five ECharts files, no zrender file.
      3. `grep -rniE 'd3\.js|github.com/d3'`.
      4. `grep -rnE '\(c\)|@author|All rights reserved'`.
      5. `grep -rnE 'copied|modified from|来自|参考|移植|源自|改自'`.
      6. `grep -rnoE 'https?://...'`, with a review of each URL by hand.

      The scan reads comments only. Code with no comment about its origin stays out of its reach.
13. **Embedded notices.** A `notices` list in an entry of `port_sources.yaml` records code from a
    third project inside that repository. The keys are those of D3 ADR 0001 item 12: `project`,
    `url`, `spdx`, `holder`, `evidence` and `files`.

    ```yaml
      - header: Apache ECharts
        # ... the keys of item 8
        notices:
          - project: d3
            url: https://github.com/d3/d3
            spdx: BSD-3-Clause
            holder: Mike Bostock
            evidence: licenses/LICENSE-d3:1-27
            files:
              - src/util/number.ts
              # ... the other four files of item 12
    ```

    - The ECharts entry gets one item: d3.
    - The zrender entry gets four items. These are Apache ECharts (`OrientedBoundingRect.ts`),
      node-timsort, jsdiff and tween.js.
    - An item is part of the change that ports the first file that it covers, with its `LICENSE`
      component.
    - A header never names a `notices` project. The header names the repository that the port
      reads.
    - From ECharts phase 1, the shared tool 2 of `port_tools`
      ([ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md)) reads the items.
      It fails when the package `LICENSE` or `NOTICE` does not name the holder. It fails when a
      path of `files` does not exist at the pin. It fails when the last `REUSE.toml` table of the
      Dart file of a path does not list the holder and the SPDX ID.
14. **CI checkout by path.** Each CI job that needs submodules fetches only the submodules that its
    steps read, by path.
    - The ubuntu leg of `test` fetches `third_party/echarts` and `third_party/zrender` for the
      ECharts `upstream_test.dart` (`.github/workflows/ci.yaml:48`).
    - The jobs of the Chart.js port keep their Chart.js paths (`ci.yaml:77`, `:94`, `:112`).
    - The job `upstream-pin` needs no submodule.
    - A later ECharts job or check adds the paths that it reads. Examples are tool 4 in phase 2 and
      the smoke runner of ECharts ADR 0005 in phase 6.
15. **Reference only.** The rules of [ADR 0005](../../../../docs/adr/0005-pin-upstream-sources.md)
    item 2 apply to both submodules.
    - Dart code never imports a file of `third_party/`.
    - No tool builds ECharts or zrender inside `third_party/`. A generator that needs a build uses
      the committed `echarts/dist/` or a throwaway clone outside the repository
      ([ECharts ADR 0005](0005-spec-harness-and-reference-tests.md)).
    - No package ships a file of `third_party/`.
16. **Not pinned and not ported.** The port pins only the two repositories of item 6. It does not
    pin d3, node-timsort, jsdiff, tween.js, Zepto.js, snabbdom, tslib or the npm tools of the
    upstream builds and tests. The port does not port these parts of the pinned repositories:
    - **`echarts/extension-src/`** (11 files: `bmap/` and `dataTool/`). `bmap` needs the Baidu
      Maps JavaScript API (`extension-src/bmap/BMapCoordSys.ts:78` declares `BMap`). Its status is
      `n/a`. A later ADR can add `dataTool`.
    - **`echarts/dist/`** (22 tracked files) and **`zrender/dist/`** (4 tracked files). These are
      build outputs. Only the reference generators of ECharts ADR 0005 read `echarts/dist/`.
    - **`echarts/build/`** and **`zrender/build/`**. These are the build scripts. For example,
      `echarts/build/build-i18n.js` writes the root `i18n/` folder.
    - **`echarts/ssr/client/`**. It hydrates a server-side SVG chart in a browser
      (`ssr/client/src/index.ts:42`, `hydrate(dom: HTMLElement, ...)`). Its status is `n/a`.
    - **`echarts/i18n/`** (55 files). These are build outputs of `src/i18n/`. The port ports
      `src/i18n/` ([ECharts ADR 0008](0008-dates-locales-and-formatting.md)).
    - **`echarts/theme/`** (36 theme files directly in `theme/`, 43 `.js` files with the
      subfolders, `git ls-files 'theme/*.js'`). No file of `src/` builds them.
      [ECharts ADR 0009](0009-dom-features-app-hooks-and-theming.md) decides them later.
    - **`echarts/test/runTest/`** (539 files). It is the screenshot runner of the visual pages, on
      puppeteer and pixelmatch (`test/runTest/package.json:8,10`).
    - **`echarts/test/types/`**. These are tests of the TypeScript declarations.
    - **`echarts/test/data/`** (137 files, 24 MB, `du -sh`). The origin of each file is not
      recorded. The port never copies them into the package. A VM-only test can read them in the
      submodule.
    - **`zrender/benchmark/`**. These are benchmarks.
    - **The npm test tools.** These are jest 26.6.3, ts-jest, jsdom 16.7.0, jest-canvas-mock 2.5.0
      and seedrandom 3.0.3 (`echarts/package-lock.json:6407-6408`, `:6425-6426`, `:8116-8117`,
      `:10034-10035`), puppeteer and pixelmatch.
      [ECharts ADR 0005](0005-spec-harness-and-reference-tests.md) replaces them.

    The visual pages (`echarts/test/*.html`, `zrender/test/*.html`) stay in the submodules.
    ECharts ADR 0005 decides how the port uses them.
17. **New sources.** Code from a project outside the two repositories needs four things in the
    same change:
    1. an entry in `port_sources.yaml`
    2. its notice in the package `LICENSE`
    3. a `REUSE.toml` table
    4. the header of AGENTS.md rule 2

    A source with a git repository also needs a shallow submodule. Code from a third project inside
    a pinned repository needs a `notices` item (item 13) in place of an entry. Never copy code from
    GPL or otherwise incompatible projects. A Dart port of ECharts never takes code from another
    port of ECharts ([the prior-art survey](../prior-art/README.md), AGENTS.md rule 1).

## Alternatives considered

- **The one-token project name `ECharts`.** Not chosen. It keeps the Chart.js header grammar. But
  the upstream name is "Apache ECharts" (`echarts/NOTICE:1`, `echarts/package.json:4`). The
  scaffold README and NOTICE also use this name. The lazy pattern costs one change in the shared
  tool 2. It leaves each Chart.js and D3 header parse unchanged.
- **No upstream license block in each ported file.** Rejected. Apache-2.0 section 4(c) asks to
  retain the notices of the source form. The 18 lines of each file are the notice of the ASF. The
  `LICENSE` and the `NOTICE` alone do not retain the block.
- **Copyright lines before the Apache text in the package `LICENSE`.** Rejected. The holder check
  then reads `LICENSE` only. But the ECharts `LICENSE` has no such line. A new line changes the
  text of `LICENSES/Apache-2.0.txt`. The ASF puts the attribution in `NOTICE`. Thus the shared
  tool 2 reads `NOTICE` for this port.
- **Separate `port_sources.yaml` entries for d3, node-timsort, jsdiff and tween.js.** Rejected. A
  header then names a project that the port does not read (AGENTS.md rule 1). Each entry also
  needs a pin.
- **No node-timsort, jsdiff or tween.js notice (the fsum rule).** Not chosen. zrender publishes
  these files under BSD-3-Clause with only a URL. D3 ADR 0001 item 11 follows upstream for
  `fsum.js`. But `fsum.js` follows an algorithm of CPython. The port reads no CPython file. The
  three zrender files translate code of a licensed project. The maintainer decides (item 1).
- **Four d3 files, as the ECharts `LICENSE` lists.** Rejected. `src/scale/Time.ts:20-28` carries
  the same d3 block. The notice of the file binds its port.
- **zrender at its newest tag.** Rejected. ECharts requires the exact version `6.1.0`
  (`echarts/package.json:77`). A newer zrender can break the pinned ECharts. Today the newest tag
  is the same.
- **A version constant for ECharts only.** Rejected. ADR 0005 item 4 asks for the version of the
  upstream repository in code. But the exact zrender requirement makes zrender a part of each
  ECharts pin. With `zrenderVersion`, the two checks compare the zrender pin with both
  `package.json` files.
- **`language: ts`.** Rejected. The tools accept only `js` and `c`. Tool 3 then skips every file.
  The Chart.js file already uses `js` for TypeScript sources.
- **A second `DIVERGES` tag `zrender`.** Rejected. ADR 0008 item 8 gives one tag and one
  `differences.md` for each port config. The upstream column of a row names the repository. Thus
  the files of both repositories use `// DIVERGES(echarts): <row id>, <reason>`.
- **`submodules: true` in each CI job.** Rejected. Each job then clones repositories that it does
  not read. The ECharts clone alone holds 24 MB of `test/data/`.

## Consequences

- `.gitmodules` lists 39 submodules: three of Chart.js, 34 of D3 and two of ECharts. A plain
  `git clone` downloads none of them. `dart run melos run upstream` clones all of them, at depth 1.
- Contributors read each ECharts and zrender source at its pin, as they read Chart.js and D3.
- Phase 0 changes the `language` of both entries to `js`.
- Phase 1 adds the zrender component and the d3 component, with the first zrender files and
  `src/util/number.ts`. Phase 2 adds the `OrientedBoundingRect.ts`, node-timsort and jsdiff
  components. Phase 3 adds the tween.js component.
- Stage 1 of [ADR 0008](../../../../docs/adr/0008-shared-js-runtime-and-port-tools.md) needs three
  config values for this port:
  1. two version constants: `echartsVersion` for `Apache ECharts` and `zrenderVersion` for
     `zrender`
  2. the lazy project pattern of item 11
  3. the holder source `LICENSE` or `NOTICE` of item 10
- ADR 0008 item 8 does not list these values yet. [porting-flow.md](../porting-flow.md) §7 asks
  for the change.
- ADR 0008 names D3 phase 1 as its gate. ECharts phase 1 also needs stage 1. If ECharts phase 1
  comes first, the porting flow records the order as an open question.
- The ledger has two sections. Both tags are recent. Thus no commit pin is due before 2027-05.
- An ECharts release that requires another zrender version gives one bump of both repositories.
- The first commit pin extends the checks of item 7. The checks compare the full version strings
  now.
- The ECharts `LICENSE` lists four d3 files. The port lists five. A bump examines the
  "Subcomponents" section and the embedded blocks again.
