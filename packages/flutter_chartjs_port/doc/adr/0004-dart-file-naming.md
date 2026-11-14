# Chart.js ADR 0004: Dart file naming

- Status: accepted (2026-10-18)
- Date: 2026-10-17
- Superseded by: [Chart.js ADR 0012](0012-dart-file-naming.md) (2026-10-19)
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0004-dart-file-naming.md`

## Summary

This ADR mapped each upstream path to a Dart path by a fixed rule. File names kept the upstream spelling with
its dots and its case. `simpleArc.dart` kept its name and ignored the `file_names` lint. Identifiers were
Dart-cased. An upstream `_` export, and a `_` member that another module reads, dropped the underscore. Such a
member carried `@internal`.

## Where each part went

- Paths (the path table and the upstream spelling): [Chart.js ADR 0012](0012-dart-file-naming.md), "Paths".
- The `simpleArc` exception: [Chart.js ADR 0012](0012-dart-file-naming.md), "The `simpleArc` exception".
- Identifiers: [Chart.js ADR 0012](0012-dart-file-naming.md), "Identifiers".
- Underscore exports: [Chart.js ADR 0012](0012-dart-file-naming.md), "Underscore exports".
- Collisions: [Chart.js ADR 0012](0012-dart-file-naming.md), "Collisions".
- Underscore members: [Chart.js ADR 0012](0012-dart-file-naming.md), "Underscore members". That ADR adds the
  rule of the type libraries.
