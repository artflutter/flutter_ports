# Contributing

Thanks for helping. The porting rules live in [AGENTS.md](AGENTS.md#porting-rules). They apply
to people as much as to agents.

- **Setup:** Flutter 3.44.9 (`.fvmrc`), then `flutter pub get` and `dart run melos run upstream`
  at the repository root. Install the git hooks with [lefthook](https://lefthook.dev) 1.0 or
  newer: `lefthook install`.
- **DCO:** sign off every commit (`git commit -s`), certifying the
  [Developer Certificate of Origin](https://developercertificate.org/). The lefthook `commit-msg`
  hook and the CI `dco` job check for the `Signed-off-by` trailer.
- **Conventional Commits:** `type(scope): summary`. The scope is optional, but when given it must
  be listed in `commitlint.yaml` (for example `feat(flutter_chartjs): port helpers.math`). The
  lefthook `commit-msg` hook checks both.
- **Ported code:** translated from the pinned upstream source, with a header naming the upstream
  file, specs ported alongside, and the parity tracker updated
  ([packages/flutter_chartjs/doc/parity.md](packages/flutter_chartjs/doc/parity.md)).
- **Licensing:** keep upstream notices. Code from another project also needs its notice in the
  package LICENSE and a `REUSE.toml` annotation (see [AGENTS.md](AGENTS.md#licensing)). Never
  copy code from GPL or otherwise incompatible projects (see
  [docs/prior-art](packages/flutter_chartjs/doc/prior-art/README.md)). `reuse lint` runs in CI.
- **Before pushing:** `dart run melos run format:check`, `dart run melos run analyze` and
  `dart run melos run test --no-select` must pass.
