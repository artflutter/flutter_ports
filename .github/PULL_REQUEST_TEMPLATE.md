## What

<!-- What does this change, and why? For port work, name the upstream module(s), e.g. Chart.js v4.6.1 src/helpers/helpers.math.ts. -->

## Checklist

- [ ] `dart run melos run format:check`, `analyze`, `test --no-select`, `test:web`, `test:cases`, `test:fixtures` and `check:port` pass
- [ ] Commits follow Conventional Commits and are signed off (`git commit -s`, DCO)
- [ ] Ported code is translated from the pinned upstream source (not from memory), names its upstream file in a header comment, and keeps the upstream copyright notice
- [ ] Ported behaviour is covered by tests (ported from the upstream specs where they exist)
- [ ] `packages/flutter_chartjs_port/doc/parity.md` is updated for every upstream module touched
- [ ] No code copied from GPL or otherwise incompatible projects (see `packages/flutter_chartjs_port/doc/prior-art/`)
