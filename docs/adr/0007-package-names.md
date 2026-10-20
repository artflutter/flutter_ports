# ADR 0007: Package names

- Status: proposed
- Date: 2026-10-20
- Gate: D3 phase 0. Phase 0 applies the name `flutter_d3_port` and its commit scope.
- Supersedes: [ADR 0003](0003-package-names.md) (on acceptance)
- Related: [ADR 0001](0001-native-ports-not-wrappers.md) (native ports, not wrappers),
  [ADR 0008](0008-shared-js-runtime-and-port-tools.md) (the shared packages),
  [Chart.js ADR 0001](../../packages/flutter_chartjs/doc/adr/0001-theming.md) (the design-system
  adapters)

## Context

A pub.dev package name is permanent after its first release.
[ADR 0003](0003-package-names.md) (accepted 2026-10-16) named the Chart.js package
`flutter_chartjs` and its gallery app `chartjs_gallery`. For later ports, it gave this rule:
"Later ports take a free `flutter_<library>` name where possible" (`0003-package-names.md:25-27`).
Only a port whose `flutter_<library>` name is taken decides its name in its own ADR.

The repository now needs more names than ADR 0003 gives:
- **The harness.** `packages/chartjs_test_utils` is the port of chartjs-test-utils 0.4.0
  ([Chart.js ADR 0011](../../packages/flutter_chartjs/doc/adr/0011-third-party-sources.md)). ADR
  0003 does not name it. The Chart.js porting flow plans the fix: "A new ADR that supersedes ADR
  0003 records `chartjs_test_utils`" (`packages/flutter_chartjs/doc/porting-flow.md:973`).
- **The design-system adapters.** Three Chart.js documents plan a new ADR that supersedes ADR
  0003. They are [theming.md](../../packages/flutter_chartjs/doc/theming.md) §5.3 item 1
  (`theming.md:421-423`), Chart.js ADR 0001 (`0001-theming.md:107-110`) and the forui survey
  (`prior-art/forui-theming.md:497-500`). In that ADR, first-party design-system adapters take the
  name `flutter_chartjs_<system>`. The adapters stay `publish_to: none` until their first release.
  The first adapter is `flutter_chartjs_forui`, after Chart.js 0.1.0.
- **The D3 port.** On 2026-10-20, the maintainer selected the name `flutter_d3_port` for the D3
  port. On the same day, `flutter_d3` was free on pub.dev. Thus ADR 0003 gives `flutter_d3`. The
  D3 name deviates from ADR 0003. A D3 ADR cannot record an exception, because an accepted ADR
  does not change.
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

This ADR states the complete naming rule. It supersedes ADR 0003 on acceptance.

## Decision

1. **Port libraries.** The library package of a port has a name of the form `flutter_<library>`
   or `flutter_<library>_port`. `<library>` is the short upstream name in lower case, with `_`
   between words, for example `chartjs` or `d3`. The maintainer selects the form for each port.
   The README and the pub.dev description of the package say that it is a native port
   ([ADR 0001](0001-native-ports-not-wrappers.md)).
2. **The names.** These names apply:

   | Package | Directory | Role | Release |
   |---|---|---|---|
   | `flutter_chartjs` | `packages/flutter_chartjs` | the Chart.js port | from 0.1.0 |
   | `chartjs_test_utils` | `packages/chartjs_test_utils` | the spec harness of the Chart.js port, a port of chartjs-test-utils 0.4.0 | `publish_to: none` |
   | `chartjs_gallery` | `apps/chartjs_gallery` | the gallery app of the Chart.js port | never |
   | `flutter_chartjs_forui` | `packages/flutter_chartjs_forui` | the forui adapter of `flutter_chartjs`, after Chart.js 0.1.0 (theming.md §5.3) | from its first release |
   | `flutter_d3_port` | `packages/flutter_d3_port` | the D3 port | from 0.1.0 (D3 phase 8) |
   | `d3_gallery` | `apps/d3_gallery` | the gallery app of the D3 port, from D3 phase 4 | never |
   | `js_semantics` | `packages/js_semantics` | the shared JS runtime ([ADR 0008](0008-shared-js-runtime-and-port-tools.md)) | open, see ADR 0008 |
   | `port_tools` | `packages/port_tools` | the shared port tools, a dev package ([ADR 0008](0008-shared-js-runtime-and-port-tools.md)) | never |
   | `flutter_ports_workspace` | the repository root | the root of the pub workspace | never |

   The maintainer selected `flutter_d3_port` on 2026-10-20. `flutter_d3` was free on that day.
   Thus the D3 name deviates from the rule of ADR 0003. This ADR makes the form
   `flutter_<library>_port` a part of the rule.
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
   the name `<library package>_<system>`, for example `flutter_chartjs_forui`. An adapter stays
   `publish_to: none` until its first release.
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
   its library package and the result of item 7. If neither form of item 1 is free, that ADR
   proposes another name. The maintainer selects the name. A name outside this rule needs a new
   ADR that supersedes this ADR.
10. **Renames.** A workspace package stays `publish_to: none` until its first release. Until then,
    a rename costs nothing.

## Alternatives considered

- **A D3 ADR that records an exception to ADR 0003.** Rejected. It contradicts an accepted ADR.
  It does not supersede that ADR.
- **The name `flutter_d3`.** Rejected. It follows ADR 0003. It overrides the selection of the
  maintainer.
- **One form for all ports** (only `flutter_<library>`, or only `flutter_<library>_port`).
  Rejected. ADR 0003 (accepted) gave `flutter_chartjs`. The maintainer selected
  `flutter_d3_port`. One form renames one of the two packages.
- **The adapter rule in a later ADR,** as theming.md §5.3 plans. Rejected. The forui adapter change
  then supersedes this ADR soon after. One ADR now states the complete rule.
- **No rule for shared packages.** Rejected. ADR 0008 needs two names. The ports import the
  shared runtime by its package name.

## Consequences

- When the maintainer accepts this ADR, ADR 0003 gets only the line
  `- Superseded by: [ADR 0007](0007-package-names.md) (<date>)`. `docs/README.md` then marks ADR
  0003 as superseded.
- Four Chart.js documents plan a superseder of ADR 0003: the porting flow, theming.md, the forui
  survey and Chart.js ADR 0001. This ADR is that superseder. After acceptance, these citations of
  ADR 0003 are stale. The Chart.js work updates them. This ADR does not edit them:
  - `packages/flutter_chartjs/doc/porting-flow.md:973-975`
  - `packages/flutter_chartjs/doc/theming.md:421-423` (§5.3, item 1)
  - `packages/flutter_chartjs/doc/prior-art/forui-theming.md:497-500`
  - `packages/flutter_chartjs/doc/prior-art/README.md:119-120` (the taken Chart.js names)
- Chart.js ADR 0001 keeps its text. Its Consequences ask for a new ADR that supersedes ADR 0003
  (`0001-theming.md:107-110`). This ADR is that ADR.
- The forui adapter change writes no ADR for its name. It still adds the `commitlint.yaml` scope,
  the AGENTS.md line, the package `LICENSE` and the `REUSE.toml` annotation
  (`theming.md:424-426`).
- D3 phase 0 adds the scope `flutter_d3_port`. D3 phase 4 adds the scope `d3_gallery`. Stage 1 of
  ADR 0008 adds the scopes `js_semantics` and `port_tools`.
- The README and the pub.dev description of each port library state that the package is a native
  port. For `flutter_chartjs`, this statement matters, because the wrapper `chartjs_flutter` has
  an almost identical name.
