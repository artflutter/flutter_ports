# Chart.js ADR 0076: Cached native indexed element options

- Status: implemented; VM/JS/Wasm behavior and macOS performance validated.
- Date: 2026-11-03
- Related: ADRs 0054 and 0062; library-performance-audit.md finding 1.

## Decision

Reuse a private plan of already-cached raw element-option values in the exact
Config/OptionResolver path. It applies to native PointOptions and BarOptions
with ordinary scalar options and native SDK lists. This benefits point-based
controllers and bars without changing chart registration or public APIs.

The first resolution uses the ordinary resolver. A subsequent call may prepare
an ordered key/value plan only when every value and all descriptors are already
cached, the keys belong to the native result type, at least one option is indexed,
and the scriptable/indexable descriptors are booleans/undefined or the exact root
built-in predicates. Main and subresolver prefixes must agree. Custom descriptors,
functions, nested objects, unknown containers, hover prefixes, custom Config and
other result types keep the ordinary path.

The plan keeps raw list references, not selected values. Lengths and selected
entries are checked every call. No cross-frame or source-content stability promise
is required. Empty lists, nested selected values, foreign numeric values and
exceptional indices use the normal path. Plain nullable/undefined color entries
retain their ordinary results. A native store does not call the foreign-value
audit hook, so preflight cannot reorder that hook's observable effects.

The `$shared: false` store occurs before context creation, as upstream does.
A context factory that inspects or changes the supplied result sees the same
state; a declined fast fill does not repeat or overwrite that store. Context
creation/refresh still runs exactly once. The result must be a native
ScriptableContext with an own numeric index, converted to a JavaScript number
before the nonnegative/finite/integral guard and remainder. This preserves VM
integer rounding above 2^53. After creating
it, the implementation rechecks the configuration cache, plan identity and key
sequence. A context factory that writes/deletes resolver keys, clears the config
cache or changes keys falls through with the context it already created; it does
not call the factory twice or repeat the earlier needContext phase.

The controller qualifies native key-producing scopes by identity. Its own
key/prefix/scope containers bypass repeated generic-list runtime-type probes;
custom Config implementations still receive their original virtual call. Keys
are still enumerated afresh at the original observation point. The generic Config
entry keeps container guards. Failed eligibility is conservatively memoized by cache entry count, avoiding a
callback-path key scan. A changed key shape may remain on the ordinary path. New
cached reads and explicit writes/deletes force re-evaluation. Unsupported result
classes decline before any native-list probes.

Resolver writes/deletes invalidate the plan. Full configuration updates already
replace the resolver cache. Each controller call still receives its freshly allocated options object, with
the usual `$shared: false`, original key order and independent mutable fields.
Explicit context-factory mutations of the supplied result remain visible. Scalar fields are stored in the same order as the normal path. Callback
values are never memoized, and array indexing never suppresses a user List getter.

## Scope

This intentionally retains context refresh and the controller's ordinary scope/key
discovery. It does not promote equal resolved colors into shared mutable options.
Arcs and line-dataset options retain the normal path, as do callbacks. Native
Color lists may contain Color subclasses; opaque objects are rejected without
inspecting their runtime type. The container allowlist covers ordinary SDK
Color/Object/primitive list instantiations. A raw list inferred as
`List<MaterialColor>` remains on the ordinary path; use an SDK
`<Color>[Colors.red, Colors.blue]` list to select the optimized color path. The native
list allowlist is independent of the incremental-data source-stability contract.

## Validation

Focused differential tests compare the optimized path against an otherwise
identical Config subclass that keeps ordinary resolution. They exercise activation,
SDK list forms, live mutation/length changes, nested/empty values, null/undefined,
cache writes/deletes/clear, key changes, context/result mutation, custom List read traces,
custom descriptor/callback order, exceptional indices and foreign-audit effects.
The existing resolver suites, controller/reference and observation tests cover
integration. Browser checks must validate the SDK runtime-type guard on both JS
and Wasm. Paired AOT measurements must include unchanged static and callback
controls as well as indexed colors.


Full-suite and focused verification results, source hashes, paired timings and
rejected prototype measurements are retained in
[benchmarks/indexed-options](../benchmarks/indexed-options/README.md).
