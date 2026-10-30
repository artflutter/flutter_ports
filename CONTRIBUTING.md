# Contributing

Thanks for helping. The porting rules live in [AGENTS.md](AGENTS.md#porting-rules). They apply
to people as much as to agents.

- **Setup:** Flutter 3.47.7 with Dart 3.13.5 (`.fvmrc`), then `flutter pub get` and
  `dart run melos run upstream` at the repository root. `upstream` checks out every `third_party/`
  submodule. Install the git hooks with [lefthook](https://lefthook.dev) 1.0 or newer:
  `lefthook install`. The `test:web` script needs Google Chrome. To generate reference data, use
  the darwin-arm64 build of Node.js v24.22.1 ([AGENTS.md](AGENTS.md#tests); Chart.js ADR 0045).
  The fdlibm data stay frozen: only the x64 build of Node.js v24.12.0 writes them again.
- **DCO:** sign off every commit (`git commit -s`), certifying the
  [Developer Certificate of Origin](https://developercertificate.org/). The lefthook `commit-msg`
  hook and the CI `dco` job check for the `Signed-off-by` trailer.
- **Conventional Commits:** `type(scope): summary`. The scope is optional, but when given it must
  be listed in `commitlint.yaml` (for example `feat(flutter_chartjs_port): port helpers.math`). The
  lefthook `commit-msg` hook checks both. The scope of the D3 port is `flutter_d3_port`. The scope of the ECharts port is
  `flutter_echarts_port`. The scope of the chartjs-plugin-zoom port is
  `flutter_chartjs_plugin_zoom_port`.
- **Ported code:** translated from the pinned upstream source, with a header naming the upstream
  file, specs ported alongside, and the parity tracker updated
  ([packages/flutter_chartjs_port/doc/parity.md](packages/flutter_chartjs_port/doc/parity.md)). A file with
  no upstream source starts with `// Original code, not ported from Chart.js: <reason>.`
  In the D3 port, the parity tracker is
  [packages/flutter_d3_port/doc/parity.md](packages/flutter_d3_port/doc/parity.md). The D3
  port-only marker is `// Original code, not ported from D3: <reason>.`
  In the ECharts port, the parity tracker is
  [packages/flutter_echarts_port/doc/parity.md](packages/flutter_echarts_port/doc/parity.md). The
  ECharts port-only marker is `// Original code, not ported from Apache ECharts: <reason>.`
  In the chartjs-plugin-zoom port, the parity tracker is
  [packages/flutter_chartjs_plugin_zoom_port/doc/parity.md](packages/flutter_chartjs_plugin_zoom_port/doc/parity.md).
  Its port-only marker is `// Original code, not ported from chartjs-plugin-zoom: <reason>.` The
  port imports only the public libraries of `flutter_chartjs_port` (ADR 0009).
- **Licensing:** keep upstream notices. Code from another project also needs its notice in the
  package LICENSE, a `REUSE.toml` annotation and an entry in
  `packages/flutter_chartjs_port/tool/port_sources.yaml` (see [AGENTS.md](AGENTS.md#licensing);
  Chart.js ADR 0035). The D3 port is ISC. Its source list is
  `packages/flutter_d3_port/tool/port_sources.yaml` (D3 ADR 0001). The ECharts port is Apache-2.0,
  with a `NOTICE` file. Its source list is `packages/flutter_echarts_port/tool/port_sources.yaml`
  (ECharts ADR 0001). The chartjs-plugin-zoom port is MIT. Its source list is
  `packages/flutter_chartjs_plugin_zoom_port/tool/port_sources.yaml` (Zoom ADR 0001). Never
  copy code from GPL or otherwise incompatible projects (see
  [packages/flutter_chartjs_port/doc/prior-art](packages/flutter_chartjs_port/doc/prior-art/README.md)).
  `reuse lint` runs in CI.
- **Before pushing:** these commands must pass at the repository root:
  - `dart run melos run format:check`
  - `dart run melos run analyze`
  - `dart run melos run test --no-select`
  - `dart run melos run test:web` (the web tests, with dart2js and dart2wasm in Chrome)
  - `dart run melos run test:cases` (the upstream spec cases, tool 5)
  - `dart run melos run test:fixtures` (the upstream fixture smoke tests, tool 7; it needs the
    submodule `third_party/Chart.js`: `dart run melos run upstream`)
  - `dart run melos run check:port` (the import guard, the header check, the JS-semantics check
    and the check modes of tools 6 and 8; it needs the submodules: `dart run melos run upstream`)

  CI runs the same checks.
