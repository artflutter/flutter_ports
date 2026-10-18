# Contributing

Thanks for helping. The porting rules live in [AGENTS.md](AGENTS.md#porting-rules). They apply
to people as much as to agents.

- **Setup:** Flutter 3.44.9 (`.fvmrc`), then `flutter pub get` and `dart run melos run upstream`
  at the repository root. `upstream` checks out every `third_party/` submodule. Install the git
  hooks with [lefthook](https://lefthook.dev) 1.0 or newer: `lefthook install`. The `test:web`
  script needs Google Chrome. To generate reference data, use an x64 build of Node.js v24.12.0
  ([AGENTS.md](AGENTS.md#tests); Chart.js ADR 0010).
- **DCO:** sign off every commit (`git commit -s`), certifying the
  [Developer Certificate of Origin](https://developercertificate.org/). The lefthook `commit-msg`
  hook and the CI `dco` job check for the `Signed-off-by` trailer.
- **Conventional Commits:** `type(scope): summary`. The scope is optional, but when given it must
  be listed in `commitlint.yaml` (for example `feat(flutter_chartjs): port helpers.math`). The
  lefthook `commit-msg` hook checks both.
- **Ported code:** translated from the pinned upstream source, with a header naming the upstream
  file, specs ported alongside, and the parity tracker updated
  ([packages/flutter_chartjs/doc/parity.md](packages/flutter_chartjs/doc/parity.md)). A file with
  no upstream source starts with `// Original code, not ported from Chart.js: <reason>.`
- **Licensing:** keep upstream notices. Code from another project also needs its notice in the
  package LICENSE, a `REUSE.toml` annotation and an entry in
  `packages/flutter_chartjs/tool/port_sources.yaml` (see [AGENTS.md](AGENTS.md#licensing);
  Chart.js ADR 0011). Never
  copy code from GPL or otherwise incompatible projects (see
  [packages/flutter_chartjs/doc/prior-art](packages/flutter_chartjs/doc/prior-art/README.md)).
  `reuse lint` runs in CI.
- **Before pushing:** these commands must pass at the repository root:
  - `dart run melos run format:check`
  - `dart run melos run analyze`
  - `dart run melos run test --no-select`
  - `dart run melos run test:web` (the web tests, with dart2js and dart2wasm in Chrome)
  - `dart run melos run test:cases` (the upstream spec cases, tool 5)
  - `dart run melos run check:port` (the import guard, the header check and the JS-semantics check)

  CI runs the same checks.
