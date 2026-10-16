# Agent onboarding

Dart pub workspace + Melos 8 monorepo of native Dart/Flutter ports of JavaScript chart
libraries. First port: Chart.js v4.5.1 → `packages/flutter_chartjs`.

## Commands

Run from the repository root. `melos` is a dev dependency: use `dart run melos …`.

- `flutter pub get`: resolve the whole workspace (single root `pubspec.lock`).
- `dart run melos run format` / `format:check`
- `dart run melos run analyze`: `dart analyze --fatal-infos` over the workspace.
- `dart run melos run test --no-select`: `flutter test` in every package with a `test/` dir.
  `--no-select` skips the interactive package picker.
- `dart run melos run upstream`: check out the pinned upstream sources (`third_party/Chart.js`).
- `dart run melos run upstream:check`: fail unless the submodule is pinned to the release tag named
  by `chartJsVersion`. CI runs it too.
- `dart run melos run gallery` (Chrome) / `gallery:macos` / `gallery:device` (Android/iOS):
  run the gallery.
- `dart run melos run gallery:build:web` / `gallery:build:android` / `gallery:build:ios`: build the
  gallery the way CI does (web with WebAssembly, debug APK, iOS without code signing).

## Layout

- `packages/flutter_chartjs`: the Chart.js port (library, `publish_to: none` until 0.1.0).
  - `doc/`: all Chart.js port docs: roadmap, parity tracker, design docs, Chart.js-only decisions
    (`doc/adr/`, numbered from 0001) and the Chart.js prior-art survey (`doc/prior-art/`).
- `apps/chartjs_gallery`: gallery app (Android, iOS, web, macOS); every Chart.js chart type,
  marked pending until ported.
- `third_party/Chart.js`: git submodule at tag `v4.5.1`. Reference only: never imported, built
  or shipped. Excluded from analysis.
- `tool/`: repository scripts (`check_upstream_pin.sh`).
- `docs/`: docs for all ports only. `docs/adr/`: decisions for all ports. `docs/prior-art/`: prior
  art for future ports. Docs for one port go in the `doc/` folder of its package.

## Porting rules

1. **Port from the pinned source.** Read the upstream file in `third_party/Chart.js` (check it out
   first). Never port from memory, from upstream `master`, or from other Dart chart libraries.
2. **Mirror upstream structure.** Same module split and names (Dart-cased), so upstream releases can
   be diffed and replayed. Each ported file starts with a header naming its source, license and
   holder, `// Ported from <project> <version> <path> (<SPDX license>, <copyright holder>).`, e.g.
   `// Ported from Chart.js v4.5.1 src/helpers/helpers.math.ts (MIT, Chart.js Contributors).`
3. **Port the specs.** Upstream `test/specs/<module>.tests.js` becomes a `flutter_test` file next to
   the code. Behaviour without an upstream spec still needs tests.
4. **Track parity.** Update the module's row in `packages/flutter_chartjs/doc/parity.md` in the same change.
5. **No JavaScript at runtime.** No WebView, no JS engine, no `dart:js_interop` in library code
   (ADR 0001). Library code must compile for every Flutter platform and for web WebAssembly.
6. **Bumping upstream** is its own change (ADR 0002). The submodule is a shallow clone without
   tags, so fetch both tags first:
   `git -C third_party/Chart.js fetch --depth 1 origin tag <old-tag> tag <new-tag>`,
   `git -C third_party/Chart.js checkout <new-tag>`, review
   `git -C third_party/Chart.js diff <old-tag> <new-tag> -- src test/specs`, then
   `git add third_party/Chart.js`, update `chartJsVersion`, and port the diff.
   `upstream:check` and `packages/flutter_chartjs/test/upstream_test.dart` fail on a mismatch.

## Licensing

- Chart.js is MIT. `packages/flutter_chartjs/LICENSE` lists both copyright holders and
  `REUSE.toml` annotates the paths. CI runs `reuse lint`.
- Code taken from any other project needs three things in the same change:
  1. its notice in `packages/flutter_chartjs/LICENSE`;
  2. a `REUSE.toml` annotation for the files, placed last because the last matching table wins
     and must list every holder;
  3. the file header from rule 2.

  For an MIT source, the notice is its copyright line, added to the existing MIT text. For example,
  `Copyright (c) 2018-2024 Jukka Kurkela` lands with the `@kurkle/color` port. For an Apache-2.0
  source, include the full license text as a separate component of the package LICENSE, along with
  its `NOTICE` content, and add `LICENSES/Apache-2.0.txt`.
- Never copy code from GPL or otherwise incompatible projects, even for "small" helpers.
  `flutter_web_chartjs` is GPL-3.0; current WebF is GPL-3.0 with an enterprise exception. Ideas
  only. See `packages/flutter_chartjs/doc/prior-art/`.

## Conventions

- Lints: `very_good_analysis` (root `analysis_options.yaml`, which also carries its formatter
  settings, so run Dart tools after `flutter pub get`). Public APIs are documented.
- Commits: Conventional Commits, signed off (`git commit -s`, DCO), for example
  `feat(flutter_chartjs): port helpers.math`. Checks:
  - lefthook ≥ 1.0 `commit-msg` hook (`lefthook install`): `commitlint_cli` checks the type, and
    the scope when one is given, against the list in `commitlint.yaml`; a second command requires a
    `Signed-off-by` trailer;
  - CI `dco` job: checks the sign-off on every pull-request commit.
- Toolchain: Flutter 3.44.9, pinned in `.fvmrc`; CI reads the same file.
