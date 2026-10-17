# Chart.js ADR 0003: Type-only dependencies

- Status: proposed
- Date: 2026-10-17

## Context

Upstream modules import TypeScript declarations with `import type`. The compiled JavaScript keeps
no trace of these imports. Dart has no type-only imports. [porting-flow.md](../porting-flow.md)
§2.4 proposed this decision. Its gate is phase 1, because the pilot file `helpers.math.dart` needs
a type.

- `helpers.math.ts:1` imports `Point` from `src/types/geometric.d.ts`. `src/types/index.d.ts:20`
  only re-exports it.
- Other helpers import the types of concrete classes, for example `Chart`, `ChartMeta` and `Scale`
  (`helpers.dataset.ts:1`, `helpers.extras.ts:1`, `helpers.dom.ts:1-3`).
- A Dart helper that imports a concrete module for a type inverts the upstream layering. It also
  brings `dart:ui` into a pure layer ([porting-flow.md](../porting-flow.md) §3).

Some declarations are unions. Dart cannot declare a union as a type alias:
- `CornerRadius` is `number | Partial<TRBLCorners>` (`geometric.d.ts:29`). In that file, only
  `RoundedRect.radius` (`:36`) uses it. `addRoundedRectPath` (`helpers.canvas.ts:498-500`) and
  `element.bar.js:182` reach it.
- `Padding` is `Partial<TRBL> | number | Point` (`geometric.d.ts:39`). The option types of
  `index.d.ts` use it (`:1707`, `:2862`).
- `toTRBL`, `toTRBLCorners` and `toPadding` take inline unions with similar members:
  `number | TRBL | Point` (`helpers.options.ts:75`), `number | TRBLCorners` (`:86`) and
  `number | TRBL` (`:98`). Phase 2 ports them.

The pilot (commit `421fc9f`) mirrored `geometric.d.ts` as `lib/src/types/geometric.dart`. Only
`Point` has members there, because `Point` is the only type with a ported caller. Probes on Dart
3.12.2 with very_good_analysis 10.3.0 (2026-10-17) gave these results:
- The prefix form `class Chart implements types.Chart` passes `dart analyze --fatal-infos`.
- An interface with one getter passes. An interface with one method fails the
  `one_member_abstracts` lint.
- `// ignore_for_file: one_member_abstracts` below the header removes that info.

## Decision

- Mirror each declaration file as a Dart library of `abstract interface class` declarations.
  The first two mappings are:
  - `src/types/geometric.d.ts` → `lib/src/types/geometric.dart` (`ChartArea`, `Point`, `TRBL`,
    `TRBLCorners`, `RoundedRect`, `SplinePoint`)
  - `src/types/index.d.ts` → `lib/src/types/index.dart` (`Chart`, `ChartMeta`, `Scale`,
    `ChartEvent`, `PointElement`, `LineElement`, `ActiveDataPoint`, `FontSpec` and the other
    types that ported callers need)
- Add a member only when a ported caller needs it. A TypeScript property becomes an abstract
  getter. A setter follows when a ported caller assigns through the type. `number` becomes
  `double`. `number | null` becomes `double?`.
- Give each declaration a `///` line with its upstream file and line, for example
  `` /// geometric.d.ts:10 `Point`. ``
- A type library imports only other type libraries. Thus it is a pure layer. For example,
  `index.d.ts:11` imports `ChartArea`, `Padding` and `Point` from `geometric.d.ts`. Thus
  `index.dart` imports `geometric.dart`.
- `Chart`, `Scale`, `PointElement` and `LineElement` are also the names of concrete classes. A file
  that needs both imports the type library with the prefix `types`, for example
  `class Chart implements types.Chart`.
- A type library carries `// ignore_for_file: one_member_abstracts` below its header. An interface
  with one method is a normal state while callers add members.
- A union waits for its first ported caller. That caller decides the Dart form of the union. Its PR
  records the form in the doc comment of the type library.
- An inline object type in a ported signature becomes a Dart record if ported code only reads it.
  For example, `getAngleFromPoint` returns `({double angle, double distance})` for
  `{angle, distance}` (`helpers.math.ts:138-141`).
- An inline object type becomes an `abstract interface class` in the same file if ported code
  writes its fields. For example, `MinMax` in `helpers.math.dart` is the target type of
  `_setMinAndMaxByKey` (`helpers.math.ts:81`).
- The `parity.md` row of a declaration file becomes `distributed` when its library exists.
  `geometric.d.ts` is `distributed` now.

## Consequences

- Pure layers can name `Chart`, `Scale` and the other types without an import of a concrete
  module.
- A type library grows one member at a time. Its members show what the ported callers read.
- The interfaces describe what ported code reads. They are not the public options API. The typed
  options API comes after 0.1.0, with its own ADR
  ([Chart.js ADR 0006](0006-options-representation-and-resolver.md)).
- A union stays open until its first caller. Phase 2 meets the first unions in `helpers.options`.
  There, option values arrive as `num` or as `Map<String, Object?>` (Chart.js ADR 0006).
- An upstream change of a declaration file gets an `api` row in the upstream ledger. Its port
  changes only the members that ported callers use
  ([upstream-tracking.md](../upstream-tracking.md) §2.4, §3).
