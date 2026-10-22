# ADR 0007: Package names

- Status: accepted (2026-10-22)
- Date: 2026-10-20 (revised 2026-10-22, before acceptance)
- Gate: D3 phase 0. Phase 0 applies the name `flutter_d3_port` and its commit scope. The Chart.js
  rename of 2026-10-22 applies the name `flutter_chartjs_port` and its commit scope.
- Supersedes: [ADR 0003](0003-package-names.md)
- Related: [ADR 0001](0001-native-ports-not-wrappers.md) (native ports, not wrappers),
  [ADR 0008](0008-shared-js-runtime-and-port-tools.md) (the shared packages),
  [Chart.js ADR 0001](../../packages/flutter_chartjs_port/doc/adr/0001-theming.md) (the
  design-system adapters),
  [ECharts ADR 0001](../../packages/flutter_echarts_port/doc/adr/0001-upstream-sources.md) (the
  ECharts name)

## Context

A pub.dev package name is permanent after its first release.
[ADR 0003](0003-package-names.md) (accepted 2026-10-16) named the Chart.js package
`flutter_chartjs` and its gallery app `chartjs_gallery`. For later ports, it gave this rule:
"Later ports take a free `flutter_<library>` name where possible" (`0003-package-names.md:25-27`).
Only a port whose `flutter_<library>` name is taken decides its name in its own ADR.

The repository now needs more names than ADR 0003 gives:
- **The harness.** `packages/chartjs_test_utils` is the port of chartjs-test-utils 0.4.0
  ([Chart.js ADR 0035](../../packages/flutter_chartjs_port/doc/adr/0035-third-party-sources.md)).
  ADR 0003 does not name it. The Chart.js porting flow planned a new ADR that supersedes ADR 0003
  and records `chartjs_test_utils`.
- **The design-system adapters.** Three Chart.js documents planned a new ADR that supersedes ADR
  0003. They are [theming.md](../../packages/flutter_chartjs_port/doc/theming.md) §5.3 item 1,
  Chart.js ADR 0001 and the forui survey (`prior-art/forui-theming.md`). In that ADR, first-party
  design-system adapters take the name of the library package with the suffix `_<system>`. The
  adapters stay `publish_to: none` until their first release. The first adapter is the forui
  adapter, after Chart.js 0.1.0.
- **The D3 port.** On 2026-10-20, the maintainer selected the name `flutter_d3_port` for the D3
  port. On the same day, `flutter_d3` was free on pub.dev. Thus ADR 0003 gives `flutter_d3`. The
  D3 name deviates from ADR 0003. A D3 ADR cannot record an exception, because an accepted ADR
  does not change.
- **The ECharts port.** `flutter_echarts` is a published WebView wrapper of ECharts. On
  2026-10-21, [ECharts ADR 0001](../../packages/flutter_echarts_port/doc/adr/0001-upstream-sources.md)
  recorded the name `flutter_echarts_port`.
- **One form for all ports.** On 2026-10-22, the maintainer selected one form for the library
  package of each port: the suffix `_port`. Thus the Chart.js package `flutter_chartjs` becomes
  `flutter_chartjs_port`. No package of the workspace had a release. Thus the rename costs
  nothing (ADR 0003, Consequences).
- **The shared packages.** [ADR 0008](0008-shared-js-runtime-and-port-tools.md) (proposed) adds a
  shared JS runtime package and a shared package of port tools. ADR 0003 has no rule for a package
  that two ports use.

**pub.dev examination (2026-10-20, 08:25-08:34 UTC).** The command
`curl -s -o /dev/null -w '%{http_code}' https://pub.dev/api/packages/<name>` gives 404 when no
package has the name. The name list `https://pub.dev/api/package-names` had 92,823 names at 08:34
UTC. The [D3 prior-art survey](../../packages/flutter_d3_port/doc/prior-art/README.md) read the
same list at 22:57 UTC on 2026-10-19. That list had 92,779 names.

| Name | Result |
|---|---|
| `flutter_chartjs`, `chartjs_test_utils`, `chartjs_gallery`, `flutter_chartjs_forui` | free |
| `flutter_d3_port`, `flutter_d3`, `d3_gallery`, `d3_test_utils` | free |
| `js_semantics`, `port_tools` | free |
| `chart`, `chartjs`, `chartjs2`, `chartjs_flutter` | taken, as ADR 0003 recorded on 2026-10-16 |
| `d3` | taken: `rwl/d3.dart` 0.2.0 (2015-12-15), "Data Driven Documents" |
| `d4` and 17 `d4_*` packages | taken: a D3 port (`github.com/luizbarboza/d4`), `d4` 0.6.0 (2024-09-08). It is prior art only ([D3 prior art](../../packages/flutter_d3_port/doc/prior-art/README.md)) |
| `d3d` | taken: `magic003/d3d` 0.0.1 (2014-07-19), "d3.js in Dart", a partial D3 v3 port on `dart:html`. It is prior art only ([D3 prior art](../../packages/flutter_d3_port/doc/prior-art/d3-packages.md#pkg-legacy)) |
| `d3_ui`, `d3dart`, `nvd3` | taken. Their descriptions name no D3 port |

**pub.dev examination (2026-10-22, 14:45 UTC).** The same command gave 404 for
`flutter_chartjs_port` and `flutter_chartjs_port_forui`.

This ADR states the complete naming rule. It supersedes ADR 0003.

## Decision

1. **Port libraries.** The library package of a port has the name `flutter_<library>_port`.
   `<library>` is the short upstream name in lower case, with `_` between words, for example
   `chartjs`, `d3` or `echarts`. The README and the pub.dev description of the package say that
   it is a native port ([ADR 0001](0001-native-ports-not-wrappers.md)).
2. **The names.** These names apply:

   | Package | Directory | Role | Release |
   |---|---|---|---|
   | `flutter_chartjs_port` | `packages/flutter_chartjs_port` | the Chart.js port | from 0.1.0 |
   | `chartjs_test_utils` | `packages/chartjs_test_utils` | the spec harness of the Chart.js port, a port of chartjs-test-utils 0.4.0 | `publish_to: none` |
   | `chartjs_gallery` | `apps/chartjs_gallery` | the gallery app of the Chart.js port | never |
   | `flutter_chartjs_port_forui` | `packages/flutter_chartjs_port_forui` | the forui adapter of `flutter_chartjs_port`, after Chart.js 0.1.0 (theming.md §5.3) | from its first release |
   | `flutter_d3_port` | `packages/flutter_d3_port` | the D3 port | from 0.1.0 (D3 phase 8) |
   | `d3_gallery` | `apps/d3_gallery` | the gallery app of the D3 port, from D3 phase 4 | never |
   | `flutter_echarts_port` | `packages/flutter_echarts_port` | the ECharts port ([ECharts ADR 0001](../../packages/flutter_echarts_port/doc/adr/0001-upstream-sources.md)) | from 0.1.0 |
   | `js_semantics` | `packages/js_semantics` | the shared JS runtime ([ADR 0008](0008-shared-js-runtime-and-port-tools.md)) | open, see ADR 0008 |
   | `port_tools` | `packages/port_tools` | the shared port tools, a dev package ([ADR 0008](0008-shared-js-runtime-and-port-tools.md)) | never |
   | `flutter_ports_workspace` | the repository root | the root of the pub workspace | never |

   The maintainer selected `flutter_d3_port` on 2026-10-20. The maintainer selected the suffix
   `_port` for all port libraries on 2026-10-22. Thus `flutter_chartjs` became
   `flutter_chartjs_port`.
3. **Harness packages.** A harness package that ports an upstream harness takes the npm name of
   that harness in snake case: `chartjs-test-utils` gives `chartjs_test_utils`. A port-only
   harness package takes the name `<library>_test_utils`. If the D3 port needs a harness package,
   its name is `d3_test_utils`.
   [D3 ADR 0004](../../packages/flutter_d3_port/doc/adr/0004-spec-harness.md) decides the D3
   harness. A harness package stays `publish_to: none`. A new ADR decides a release of a harness
   package.
4. **Galleries.** The gallery app of a port is `apps/<library>_gallery`. No gallery app goes to
   pub.dev.
5. **Design-system adapters.** A first-party adapter of a port library to a design system takes
   the name `<library package>_<system>`, for example `flutter_chartjs_port_forui`. An adapter
   stays `publish_to: none` until its first release.
6. **Shared packages.** A package that two or more ports use has no port name in its name. Its
   name starts with `flutter_` only if the package depends on Flutter. ADR 0008 proposes
   `js_semantics` (a pure Dart package) and `port_tools`. These two names apply when the
   maintainer accepts ADR 0008.
7. **Examination of pub.dev.** Before a change adds a package name to a `pubspec.yaml`, the
   porter examines pub.dev. `https://pub.dev/api/packages/<name>` must give 404 on that day. The
   ADR that gives the name records the date and the result.
8. **Directories and scopes.** The directory name of a package or an app is its package name. A
   package is in `packages/<name>`. An app is in `apps/<name>`. The name of each package and app
   of the workspace is a scope in `commitlint.yaml`. The change that adds the package to the
   workspace also adds the scope.

   The workspace root `flutter_ports_workspace` is not a package or an app of this item. Its
   directory is the repository root. Its name is not a scope. A change of the root files uses a
   repository-wide scope of `commitlint.yaml`, for example `repo` or `ci`.
9. **Later ports.** A later port applies items 1 and 3 to 8. Its first ADR records the name of
   its library package and the result of item 7. If the name of item 1 is not free, that ADR
   proposes another name. The maintainer selects the name. A name outside this rule needs a new
   ADR that supersedes this ADR.
10. **Renames.** A workspace package stays `publish_to: none` until its first release. Until then,
    a rename costs nothing. A rename moves the directory, the commit scope, the imports, the
    `REUSE.toml` paths, the CI paths and the doc paths in one change.

## Alternatives considered

- **A D3 ADR that records an exception to ADR 0003.** Rejected. It contradicts an accepted ADR.
  It does not supersede that ADR.
- **The name `flutter_d3`.** Rejected. It follows ADR 0003. It overrides the selection of the
  maintainer.
- **Two forms** (`flutter_<library>` or `flutter_<library>_port`, the maintainer selects one for
  each port). Rejected on 2026-10-22. Two forms give names of different shape for the same kind of
  package. The maintainer selected one form.
- **Only the form `flutter_<library>`.** Rejected. `flutter_echarts` is taken. The maintainer
  selected `flutter_d3_port`. The suffix `_port` also tells a reader that the package is a native
  port, not a wrapper.
- **Keep `flutter_chartjs`.** Rejected. It breaks the one form. No release uses the name, so a
  rename costs nothing now. `flutter_chartjs` is also the name of an unrelated GitHub wrapper
  (`pakhyunw/flutter_chartjs`) and is almost the name of the wrapper `chartjs_flutter`.
- **The adapter rule in a later ADR,** as theming.md §5.3 planned. Rejected. The forui adapter
  change then supersedes this ADR soon after. One ADR now states the complete rule.
- **No rule for shared packages.** Rejected. ADR 0008 needs two names. The ports import the
  shared runtime by its package name.

## Consequences

- ADR 0003 gets only the line `- Superseded by: [ADR 0007](0007-package-names.md) (2026-10-22)`.
  `docs/README.md` marks ADR 0003 as superseded.
- The Chart.js rename moved `packages/flutter_chartjs` to `packages/flutter_chartjs_port`, the
  library file to `lib/flutter_chartjs_port.dart`, the imports to `package:flutter_chartjs_port/`
  and the commit scope to `flutter_chartjs_port`. The docs, the CI paths, `REUSE.toml` and the
  generated reference data use the new name.
- The Chart.js documents that planned a superseder of ADR 0003 (the porting flow, theming.md and
  the forui survey) cite this ADR. Chart.js ADR 0001 keeps its text, with the new package name.
- The forui adapter change writes no ADR for its name. It still adds the `commitlint.yaml` scope,
  the AGENTS.md line, the package `LICENSE` and the `REUSE.toml` annotation (theming.md §5.3).
- D3 phase 0 added the scope `flutter_d3_port`. D3 phase 4 adds the scope `d3_gallery`. Stage 1
  of ADR 0008 adds the scopes `js_semantics` and `port_tools`.
- The README and the pub.dev description of each port library state that the package is a native
  port. The suffix `_port` helps, because the wrapper `chartjs_flutter` has a name close to the
  name of the Chart.js port.
