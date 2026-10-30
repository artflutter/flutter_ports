# Chart.js ADR 0047: The published archive

- Status: accepted (2026-10-30)
- Date: 2026-10-29
- Related: [ADR 0007](../../../../docs/adr/0007-package-names.md) (the package names; a harness
  stays `publish_to: none`), [Chart.js ADR 0035](0035-third-party-sources.md) (the third-party
  sources and their notices), [Chart.js ADR 0015](0015-text.md) (the test font stays outside the
  published archives), [porting-flow.md](../porting-flow.md) §2.12 (the published floor) and §7
  risk 7 (pana and the unpublished dev_dependency)

## Context

Phase 9 publishes `flutter_chartjs_port` 0.1.0 on pub.dev. pub.dev scores a package with pana.
Risk 7 of porting-flow.md §7 says that pana can reject the dev_dependency on the harness
`chartjs_test_utils`, which is `publish_to: none` (ADR 0007). Phase 9 ran pana first, before any
other change of the phase.

The runs (pana 0.23.19, Flutter 3.47.7, Dart 3.13.5, 2026-10-29; the reports are working files of
phase 9):

| Run | Package | Score |
|---|---|---|
| 1 | `7c958aa` in a worktree of the workspace | 125/160 |
| 2 | `7c958aa`, a copy of the package outside any workspace (as pub.dev sees the archive) | 125/160 |
| 3 | run 2 with `analysis_options.yaml` and `very_good_analysis` in the package, and `.pubignore` | 125/160 |
| 4 | run 3 with the path dev_dependency on the harness and without `publish_to` | 135/160 |

pana reads `publish_to` only from the `main` branch of the repository
(`repository/check_repository.dart:231`). Thus the second change of run 4 does not change the
score.

The points that runs 1 and 2 lose:
- **Pubspec (0/10).** pana clones the `repository` of the pubspec. Its `main` has `publish_to:
  none`, so pana cannot verify the repository.
- **License (5/10).** pana detects `MIT` and `SunPro` in `LICENSE`. SunPro is not OSI-approved.
  The SunPro component is the notice of the fdlibm ports `lib/src/js/fdlibm_*.dart` (Chart.js ADR
  0035).
- **Example (0/10).** The package has no `example/`.
- **Analysis (40/50).** 41 files of `lib/src/` do not match the formatter. pana formats with its
  own `analysis_options.yaml`. That file takes from the options of the package the `include:`,
  the `formatter:`, the analyzer errors and excludes, and the linter rules
  (`analysis_options.dart:73-177`). The package has no options file. Thus pana formats without
  `trailing_commas: preserve` of `very_good_analysis` 10.3.0. The workspace formats with it.

pana resolves the package only without its dev_dependencies: the outdated step
(`sdk_env.dart:519`) and the fallback of the downgrade step (`package_context.dart:200-206`)
remove all of them. Its `pub get` before `dart format` (`sdk_env.dart:349`) removes only the path,
git and custom-hosted dev_dependencies (`sdk_env.dart:659-676`). It keeps the hosted constraint
`chartjs_test_utils: ^0.0.1`, and it fails: the harness is not on pub.dev. The log of the later
`pub upgrade` shows the same failure: "chartjs_test_utils doesn't exist (could not find package
chartjs_test_utils at https://pub.dev)". Thus in run 3 the `include:` of `very_good_analysis` does
not resolve. A probe showed that `dart format` then ignores the whole options file. 41 files
change with the unresolved `include:`, and 0 files change with the `formatter:` section alone. In
run 4, pana drops the path dev_dependency, and its `pub get` resolves `very_good_analysis`. It
then formats with `trailing_commas: preserve`: 0 issues.

`dart pub publish --dry-run` accepts a path dev_dependency. The dry run of the change has 0
warnings, and its archive has 523 KB. The dry run of `7c958aa` without `.pubignore` has 4 MB. pana
keeps the analyzer problems and the format results only for `lib/`, `bin/` and `pubspec.yaml`
(`sdk_env.dart:819`).

## Decision

1. **The harness stays unpublished.** `chartjs_test_utils` stays `publish_to: none` (ADR 0007).
   `flutter_chartjs_port` names it as a path dev_dependency, `path: ../chartjs_test_utils`. Each
   other workspace member names `flutter_chartjs_port` as a path dependency too: the harness and
   the gallery. Thus a version bump of the port changes no other pubspec. The pub workspace
   resolves each path to its member.
2. **The archive.** `packages/flutter_chartjs_port/.pubignore` excludes `doc/`, `test/`, `tool/`,
   `dart_test.yaml` and `build/`. The archive has `lib/`, `example/`, `README.md`, `CHANGELOG.md`,
   `LICENSE`, `pubspec.yaml` and `analysis_options.yaml`. No reference source, no reference data,
   no test font and no tool goes into it (Chart.js ADRs 0015 and 0035). The README and the public
   dartdoc name a file outside the archive by an absolute URL of the repository.
3. **The analysis options.** `packages/flutter_chartjs_port/analysis_options.yaml` includes
   `package:very_good_analysis/analysis_options.yaml`, as the root file does. Its analyzer
   excludes are the root excludes without `third_party/**` and with `build/**`.
   `very_good_analysis` is a dev_dependency of the package with the constraint of the root
   (`^10.3.0`). The workspace analysis of the package keeps the same rules.
4. **The license.** `LICENSE` keeps the SunPro component of the fdlibm ports (Chart.js ADR 0035
   item 6). pana gives 5 of 10 license points for it.
5. **The example.** `packages/flutter_chartjs_port/example/main.dart` is one file: a small app with
   one chart of the public widget. It has no pubspec, so it is no package of ADR 0007. The
   workspace analyzes it as a file of `flutter_chartjs_port`. pana counts `example/main.dart` as an
   example. The docs unit of phase 9 writes it.
6. **The release commit** removes `publish_to: none` and sets the version. It also sets the
   `description` (50 to 180 characters, no "Work in progress") and adds a CHANGELOG entry with the
   version. pana reads the pubspec of `main` for the repository check. Thus `main` has the release
   pubspec before the upload.

## Alternatives considered

- **Publish the harness.** It needs a new ADR that supersedes ADR 0007. The archive of the harness
  then has the test font (SIL OFL 1.1). The pana runs show no need for it.
- **Keep the hosted constraint `chartjs_test_utils: ^0.0.1`.** pana loses the 10 analysis points:
  its `pub get` cannot resolve the `include:`.
- **An options file with only `formatter:`.** The format probe changes 0 files with it, and run 1
  had no other issue. Thus pana probably gives 50/50 (no pana run). But the nearest options file
  wins in the workspace analysis. Thus the package loses the rules of `very_good_analysis`.
- **Reformat `lib/` with the default style.** The default output is stable under `trailing_commas:
  preserve`. But each new trailing comma breaks it again. The reformat also moves lines that
  `canvas-cuts-plan.md` cites.
- **Keep `test/`, `tool/` and `doc/` in the archive.** The archive then has 4 MB in place of 523 KB.
- **The SunPro notice only in the headers of the fdlibm files.** The headers keep the notice, so
  the SunPro terms ("provided that this notice is preserved") hold. pana then gives 10 license
  points. But Chart.js ADR 0035 item 6 and AGENTS.md (Licensing) require the component in
  `LICENSE`, and pub.dev then shows only MIT for code that has a second license.
- **An example package in `example/`.** A workspace member has `resolution: workspace`, so `flutter
  pub get` fails in the example that a user unpacks. A package in `example/` also breaks the rule
  of ADR 0007 that the directory of a package is its name.

## Consequences

- The expected pana score of 0.1.0 is 155/160: 5 license points stay lost.
- pub.dev shows no test, tool or doc file of the package. The repository keeps them.
- A new dev_dependency of the package that is not on pub.dev is a path dependency.

## Open

1. Closed (2026-10-30): the pana score of the release. pana 0.23.19 on the archive of the release
   commit `d9011b5`, run after the push of `b397fbf`, gives 155 of 160 points: conventions 25 of
   30 (the SunPro notice costs 5 points, §4), documentation 20 of 20, platforms 20 of 20,
   analysis 50 of 50 and dependencies 40 of 40. `dart pub publish --dry-run` on `main` at
   `b397fbf` gives `flutter_chartjs_port 0.1.0`, 556 KB and 0 warnings.

## Evidence

- The working files of phase 9 in `.handover/phase9/pana/`: `pana-7c958aa.json` (run 1),
  `pana-solo-7c958aa.json` (run 2), `pana-v2.json` (run 3), `pana-v3.json` (run 4), their `.err`
  logs, `dry-run-7c958aa.txt` (4 MB), `dry-run-adr0047.txt` (523 KB, 0 warnings),
  `pana-release-b397fbf.json` (155 of 160) and `dryrun-main-b397fbf.txt` (556 KB, 0 warnings). Not
  committed.
- pana 0.23.19: `lib/src/analysis_options.dart:73-177` (the pass-through options),
  `lib/src/sdk_env.dart:349` (the `pub get` before format), `:519` (the outdated step without dev
  dependencies), `:659-676` (the dropped dev dependencies) and `:819` (the kept problems),
  `lib/src/package_context.dart:200-206` (the downgrade fallback) and
  `lib/src/repository/check_repository.dart:231` (`publish_to` of the repository).
