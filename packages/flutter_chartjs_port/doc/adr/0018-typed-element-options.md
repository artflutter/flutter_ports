# Chart.js ADR 0018: Typed element options

- Status: accepted (2026-10-21)
- Superseded by: [Chart.js ADR 0054](0054-typed-internal-model.md) (2026-10-31)
- Date: 2026-10-19
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0018-typed-element-options.md`

## Summary

The resolved options of the four elements became the classes `PointOptions`, `LineOptions`, `BarOptions` and
`ArcOptions`. Each class extended `MapBase` and kept the known keys of its element in fields.
A getter read a known key with no Map lookup, and a plain Map still worked through `jsGet`.
The resolver and the option copies made the class of the element type.
Chart.js ADR 0054 keeps the typed classes, but no class is a Map.

## Where each part went

- §1 (the four classes that extend `MapBase`): [Chart.js ADR 0054](0054-typed-internal-model.md) §2 and §5.
  The resolved classes are generated and are not Maps.
- §2 (the known keys and the extra keys): [Chart.js ADR 0054](0054-typed-internal-model.md) §2 and §4.
- §3 (the Map protocol): [Chart.js ADR 0054](0054-typed-internal-model.md) §5, the face `JsObjectFace`.
- §3 (the key order of the resolved options): [Chart.js ADR 0054](0054-typed-internal-model.md) §17.
- §4 (the typed reads of the element code): [Chart.js ADR 0054](0054-typed-internal-model.md) §6 and §9.
- §5 (the producers: the resolver and the copies): [Chart.js ADR 0054](0054-typed-internal-model.md) §4 and §17.
- §6 (the element tests with plain Map options and with typed options): no ADR restates it.
  The dartdoc of the element tests keeps it, for example `test/port/elements/element.point_test.dart`.
- §6 (the figures): [performance.md](../performance.md) §8.
- Open (the frozen state of the cached shared options): [Chart.js ADR 0054](0054-typed-internal-model.md) §17.
- Open (the typed class for a list of names): [Chart.js ADR 0054](0054-typed-internal-model.md) §4.
