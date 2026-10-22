# Prior art: ECharts in Dart and Flutter

Survey dates: the sweeps ran on **2026-10-20**. The author of these pages examined the key claims
and the volatile facts again on **2026-10-21**. Numbers that change over time (versions, dates,
downloads, likes, stars) are as of 2026-10-21.

**Question.** Does a native Dart or Flutter port of [Apache ECharts](https://echarts.apache.org)
or of its renderer [zrender](https://github.com/ecomfe/zrender) exist? Are the ECharts packages
ports, wrappers or new code? How does each one work?

**Answer.** No native Dart port of ECharts or zrender exists, full or partial at module scale.

- Each Dart package that shows an ECharts chart runs the JavaScript ECharts. It runs in a WebView
  on mobile and desktop. On the web, it runs in an `HtmlElementView` with an iframe or JS interop.
- Other Dart packages model only the option JSON. Some packages share only the name.
- The nearest native work is [`e_chart` and `e_chart_ext`](echarts-packages.md#pkg-e_chart). They
  are a Flutter rewrite of the ECharts option and coordinate model, with about 21.5k lines. Their
  algorithms are their own. Their source repository is gone. The last publish was on 2023-05-10.
- Two Dart packages translate one helper each.
  [`slidable_line_chart`](echarts-packages.md#pkg-slidable_line_chart) translates one branch of
  `drawSegment` of `src/chart/line/poly.ts`. [`graphic`](echarts-packages.md#pkg-graphic) has the
  zrender `smoothBezier`, by way of AntV F2.
- Three ports in other languages appeared in 2026: Swift, MoonBit and Pascal. They show that a
  port of ECharts 6.1.0 is possible. None of them is Dart.

## At a glance

"Kind" uses the terms of [ECharts packages](echarts-packages.md#terms). "ECharts" gives the
upstream version that the package bundles, loads or ports.

| Package or repository | Kind | ECharts | Draws with | Works on | License | State (2026-10-21) |
|---|---|---|---|---|---|---|
| [`e_chart`, `e_chart_ext`](echarts-packages.md#pkg-e_chart) (pub.dev) | native rewrite of the option model, own algorithms. d3 layouts in `e_chart_ext` | none. One link to the option docs | `CustomPainter` | Flutter. SDK `>=2.19.4 <3.0.0`, pub.dev tag `has:error` | Apache-2.0 template, no holder | abandoned. 0.0.1, 2023-05-10. Repository gone |
| [`slidable_line_chart`](echarts-packages.md#pkg-slidable_line_chart) (pub.dev) | own chart with one translated branch of `poly.ts` | `master`, not pinned | `CustomPainter` | all Flutter platforms | Apache-2.0, no `NOTICE` | 1.4.0, 2024-10-13. Last push 2026-09-01 |
| [`graphic`](echarts-packages.md#pkg-graphic) (pub.dev) | independent grammar of graphics with one zrender helper | none | `CustomPainter` | all Flutter platforms | MIT. The appendix does not name zrender | 2.7.0, 2026-02-25 |
| [`flutter_echarts`](echarts-packages.md#pkg-flutter_echarts) (pub.dev) | WebView | 5.4.3, bundled | WebView | Android, iOS, macOS | BSD-2-Clause. pub.dev shows unknown | archived. 2.5.0, 2023-08-31 |
| [`graphify`](echarts-packages.md#pkg-graphify) (pub.dev) | WebView. JS interop on the web | 5.5.0, bundled | WebView, `HtmlElementView` | Android, iOS, macOS, Windows, web | MIT | archived. 1.2.1, 2025-09-03 |
| [`fl_echarts`](echarts-packages.md#pkg-fl_echarts) (pub.dev) | WebView. An iframe on the web | 6.0.0, bundled | WebView, `HtmlElementView` | Android, iOS, macOS, Windows, web | MIT | 0.3.0, 2026-03-19 |
| [`echarts_flutter_plus`](echarts-packages.md#pkg-echarts_flutter_plus) (pub.dev) | JS interop | 5.5.0 from a CDN | `HtmlElementView` | web only | MIT | 0.0.8, 2025-12-24 |
| [`universal_echarts`](echarts-packages.md#pkg-universal_echarts) (pub.dev) | `flutter_echarts` on mobile. An iframe on the web | 5.0.0, bundled | WebView, `HtmlElementView` | Android, iOS, web | MIT | abandoned. 1.0.0+4, 2021-03-30, `has:error` |
| [Wrappers and copies on GitHub and other hosts](echarts-packages.md#pkg-wrappers) (about 20) | WebView or JS interop | 4.8.0 to 6.0.0-rc.1 | WebView, `HtmlElementView` | mostly Android and iOS | mostly none | 2019-2025 |
| [Option models](echarts-packages.md#pkg-options) (2) | option classes for the JavaScript ECharts | 4.x `option.json` | nothing | code generator, app code | none | 2019 |
| [`andy-sheng/EChartsSwift`](echarts-packages.md#pkg-echartsswift) (GitHub) | structural port in Swift | 6.1.0 plus 20 commits. zrender 6.1.0 plus 6 commits | Core Graphics | iOS 15, macOS 12 | none | active. Last push 2026-10-19 |
| [`OverflowCat/yuecharts`](echarts-packages.md#pkg-yuecharts) (GitHub) | partial port in MoonBit | not stated | SVG text | MoonBit native and wasm | Apache-2.0 | last push 2026-04-18 |
| [`ACTom/TyControls`](echarts-packages.md#pkg-tycontrols) (GitHub) | behavior port in Pascal, modules merged | 6.1.0 | a Lazarus control | Free Pascal desktop | modified LGPL | active. Last push 2026-10-21 |
| [Other non-Dart projects](echarts-packages.md#pkg-other-languages) | the JavaScript ECharts with a native renderer, or inspired engines | various | Skia, SVG, Go, Kotlin, Rust | not Dart | Apache-2.0, MIT, GPL-3.0 | 2023-2026 |
| [Name only](echarts-packages.md#pkg-ruleouts) | no ECharts code | none | own painters | Flutter | various | ruled out |

## Pages

- [ECharts packages](echarts-packages.md): each package and repository above, from its Dart API
  to its output. The page gives the ECharts version, the platforms, the license, the limitations,
  the takeaways and the evidence of each one. Its re-check marks name the claims that a second
  reader confirmed.
- [Chart.js prior art](../../../flutter_chartjs_port/doc/prior-art/README.md) and
  [D3 prior art](../../../flutter_d3_port/doc/prior-art/README.md): the surveys of the first two
  ports, with the same method. The D3 survey also covers the d3 code of
  [`e_chart_ext`](../../../flutter_d3_port/doc/prior-art/d3-packages.md#pkg-e_chart_ext).
- [Other JavaScript chart libraries](../../../../docs/prior-art/other-chart-libraries.md): the
  survey of 2026-10-16 for all ports. Its ECharts rows were the start of this survey.

## How the survey was done

1. **Five sweeps on 2026-10-20.** Each sweep was one agent with one source.
   - GitHub repository search: about 60 query strings, with the Dart filter and in all languages.
   - Sources in Chinese: Gitee, GitCode, Juejin, CSDN, the mirror pub.flutter-io.cn, and the
     issues and discussions of apache/echarts and ecomfe/zrender.
   - pub.dev and GitHub with archives: the pub.dev API, the `dependency:` filter and 32 archives.
   - GitHub code search over Dart for ECharts and zrender identifiers: about 60 queries, for
     example `SeriesModel`, `niceScaleExtent`, `getECData` and `zrender/src`.
   - pub.dev in full: the search pages, the `is:unlisted` filter, the name list
     `/api/package-names` (92,823 names), the metadata of 403 hits and 288 archives.
2. **Verification.** Three agents read the source of the nearest candidates again. They compared
   the code with the upstream files line by line.
3. **Completeness critic.** One agent searched other angles: Sourcegraph, GitHub repositories of
   2026 in all languages, code that cites upstream ECharts paths, and the 174 forks of
   `flutter_echarts`. It also searched pub.dev by date, GitLab, Codeberg, npm, the Wayback Machine
   and Software Heritage. It corrected six claims of the sweeps. These pages apply the corrections.
4. **Re-check on 2026-10-21.**
   - The author of these pages read the pub.dev API for 17 names and the GitHub API for 31
     repositories again. The name list had 92,932 names.
   - The author downloaded 7 archives again and read the key files of 9 repositories through the
     GitHub contents API.
   - A new repository search for ECharts repositories of 2026 found no new port. A code search
     for `"Ported from echarts/src"` found only `EChartsSwift` and `TyControls`.
5. **Static examination only.** The survey ran no package code and no `pub get`. It compared the code
   with the upstream files at the pin of this port: `third_party/echarts` at the tag `6.1.0` and
   `third_party/zrender` at the tag `6.1.0`.

## Limits of the search

A search cannot prove that no port exists. These gaps stay open:

- GitHub code search reads only the default branch of each repository. It skips many forks. The
  search hit rate limits several times. The agents sent the failed queries again later. Two
  queries did not run again.
- Gitee and GitCode code search by content needs a login. The survey used only their repository
  search. A Dart file with zrender names in a Gitee repository with a generic name stays hidden.
- grep.app blocked the survey with a challenge page. The index of Sourcegraph covers mostly
  popular repositories. Its zero hits are weak evidence.
- The survey read only the latest archive of each pub.dev package. An older version can hold
  ECharts code that a later version removed.
- The survey did not search Reddit, X, Discord, Hacker News, Bitbucket, SourceForge or the
  OpenHarmony registry ohpm.
- Private repositories and repositories after 2026-10-21 are not in the survey. Three LLM-driven
  ports appeared in 2026 (April, June and June). A Dart port can appear at any time. Run the
  repository search for new repositories again before each phase.

## Licenses

- **ECharts** is Apache-2.0. Its `NOTICE` names "The Apache Software Foundation"
  (`third_party/echarts/NOTICE:2`). Five ECharts files embed d3 code under BSD-3-Clause:
  `src/chart/treemap/treemapLayout.ts`, `src/chart/tree/layoutHelper.ts`,
  `src/chart/graph/forceHelper.ts`, `src/util/number.ts` and `src/scale/Time.ts`. The ECharts
  `LICENSE` names the first four (`third_party/echarts/LICENSE:209-222`).
  `src/scale/Time.ts:20-28` has the same d3 block
  ([ECharts ADR 0001](../adr/0001-upstream-sources.md) item 12).
- **zrender** is BSD-3-Clause in every version, not MIT and not Apache-2.0. Its `LICENSE` has
  "Copyright (c) 2017, Baidu Inc." (`third_party/zrender/LICENSE:1-3`). The npm license field is
  BSD-3-Clause for zrender 4.3.2, 5.6.0, 5.6.1 and 6.0.0. The GitHub API also gives BSD-3-Clause.
  Thus a Dart port of zrender needs the BSD-3-Clause notice of Baidu Inc.
- **Prior art.** Most packages drop the upstream notices:
  - `flutter_echarts` is BSD-2-Clause (LIN Chen). It bundles the minified ECharts with its Apache
    header. pub.dev shows the license as unknown.
  - `graphic` credits apache/echarts in `LICENSE_APPENDIX`. It does not credit zrender. Its
    `smoothBezier` code came from zrender through AntV F2.
  - `slidable_line_chart` is Apache-2.0. It has the URL of `poly.ts` but no `NOTICE` and no
    ECharts copyright line.
  - `e_chart` and `e_chart_ext` have the Apache-2.0 template with the placeholder
    "Copyright [yyyy] [name of copyright owner]". `e_chart_ext` has d3 code without the d3 notice.
  - `EChartsSwift` has no license file. Thus all rights stay with its author. It is prior art for
    ideas only.
  - `TyControls` is LGPL 2.1 with a static-link exception. Its code cannot go into an Apache-2.0
    package. It is prior art for ideas only.
  - `yuecharts` is Apache-2.0. It is MoonBit. Thus no code transfers.
  - `KCharts` is GPL-3.0. [AGENTS.md](../../../../AGENTS.md) forbids code from GPL projects.

## Conclusions for flutter_echarts_port

- **No native ECharts port for Flutter exists.** The case for a native port is
  [ADR 0001](../../../../docs/adr/0001-native-ports-not-wrappers.md). The wrappers show its
  reasons:
  - The `flutter_echarts` README says: "Since it is based on webview, this library has some
    inextricable instability and performance issues" (`README.md:19` of 2.5.0).
  - `echarts_flutter_plus` loads ECharts from a CDN at runtime.
  - No pub.dev wrapper supports Linux.
- **What each prior art teaches this port:**
  - `EChartsSwift`: a pin file, a "Ported from" header on each file, upstream names and JSON
    oracle fixtures from the JavaScript ECharts. These agree with the method of this repository.
    Its lock file labels a commit 20 commits after the tag `6.1.0` as "6.1.0". This port pins the
    tag commit. A later commit pin uses the version form `<last version>+<sha8>`, as the Chart.js
    port does.
  - `yuecharts` and `TyControls`: a port that merges modules or maps them loosely loses the
    upstream diff. This port mirrors the upstream file split (AGENTS.md rule 2).
  - `e_chart`: a rewrite of the option model with its own algorithms gives other ticks, other
    curves and other funnel sizes than ECharts. It had no tests and stopped after one release.
    Port the option model, the scales and the layouts from the pinned source.
  - `slidable_line_chart` and `graphic`: Dart packages copy the smooth-curve helpers of `poly.ts`
    and zrender without the notices. This port keeps the Apache-2.0 notice of ECharts, the
    BSD-3-Clause notice of zrender and the d3 notice of the five d3 files.
  - `e_chart_ext`: a chart library in Dart can need d3 layouts. ECharts embeds its own d3 code.
    The ports of the five d3 files get the d3 notice in the same change.
  - The wrappers: a typed option model alone does not draw a chart. It still needs the
    JavaScript ECharts.
- **[AGENTS.md](../../../../AGENTS.md) rule 1 forbids a port from any of them.** This port
  translates only the pinned upstream files of `third_party/echarts` and `third_party/zrender`.
  Each project on these pages is prior art only. It is neither a source nor a dependency.
- **Names.** `flutter_echarts` is the name of the WebView wrapper on pub.dev.
  [ADR 0007](../../../../docs/adr/0007-package-names.md) item 1 gives the form
  `flutter_<library>_port`. On 2026-10-21, `flutter_echarts_port`, `echarts_gallery` and
  `echarts_test_utils` gave HTTP 404 on the pub.dev API. No pub.dev name contains "zrender".
