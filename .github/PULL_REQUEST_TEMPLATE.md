## What

<!-- What does this change, and why? For port work, name the upstream module(s), e.g. Chart.js v4.5.1 src/helpers/helpers.math.ts. -->

## Checklist

- [ ] `melos run format:check`, `melos run analyze` and `melos run test --no-select` pass
- [ ] Commits follow Conventional Commits and are signed off (`git commit -s`, DCO)
- [ ] Ported code is translated from the pinned upstream source (not from memory), names its upstream file in a header comment, and keeps the upstream copyright notice
- [ ] Ported behaviour is covered by tests (ported from the upstream specs where they exist)
- [ ] `packages/flutter_chartjs/doc/parity.md` is updated for every upstream module touched
- [ ] No code copied from GPL or otherwise incompatible projects (see `docs/prior-art/`)
