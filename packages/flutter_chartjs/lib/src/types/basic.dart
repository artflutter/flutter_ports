// Ported from Chart.js v4.5.1 src/types/basic.d.ts (MIT, Chart.js Contributors).

/// The declarations of `src/types/basic.d.ts` as Dart types
/// (Chart.js ADR 0003, porting-flow.md 2.4).
///
/// `AnyObject` is `Record<string, any>`: a JS plain object. Chart.js ADR 0006
/// makes a JS plain object a `Map<String, Object?>`, so [AnyObject] is a
/// typedef of that Map type. Its phase-2 callers are `helpers.core.ts:5`,
/// `helpers.config.ts:2` and `helpers.config.types.ts:1`. Later callers
/// include `core.element.ts:1`, `core.adapters.ts:7` and `animation.d.ts:2`.
///
/// `EmptyObject` (basic.d.ts:3) waits for its first ported caller
/// (`index.d.ts`).
library;

/// basic.d.ts:2 `AnyObject`, `Record<string, any>`: a JS plain object
/// (Chart.js ADR 0006).
typedef AnyObject = Map<String, Object?>;
