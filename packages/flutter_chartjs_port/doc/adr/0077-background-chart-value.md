# Chart.js ADR 0077: Sealed dataset color values

- Status: prototype implemented; behavior validated and macOS comparison recorded.
- Date: 2026-11-03
- Scope: Dataset.backgroundColor and Dataset.borderColor across all eight typed
  dataset classes. The initial experiment measured backgroundColor only.
- Supersedes: the background/border-color companion parameters of ADR 0052 §§1, 3, 5.

## Public API

`Dataset.backgroundColor` and `Dataset.borderColor` are `ChartValue<Color>?`. The sealed public hierarchy
has three const factories and final variants:

- `ChartValue.constant(value)` → `ChartConstant<T>`.
- `ChartValue.indexed(values)` → `ChartIndexed<T>`.
- `ChartValue.resolver(callback)` → `ChartResolver<T>`.

The separate `backgroundColors`, `backgroundColorFor`, `borderColors` and
`borderColorFor` parameters are removed from Dataset and its constructors/copyWith
methods. This is an intentional
source-breaking prototype of the typed API: a plain Color becomes
`ChartValue.constant(color)`, a list becomes `.indexed(list)`, and the old
callback parameter becomes `.resolver(callback)`. No Object-typed compatibility
union is introduced. Only the app library exports the four new names.

Element defaults, point-specific colors, hover colors, tooltip/theme colors,
raw configs and all
other options retain their current types. The raw Chart.js API still receives
ordinary Color/list/function values; ChartValue is not a new raw-option format.

An omitted/null constructor parameter inherits the default. `copyWith(null)`
retains the current value, as before. A non-null value can replace any previous
variant, so switching constant/indexed/resolver no longer requires clearing
competing fields. Indexed source lists are treated as immutable configuration;
empty lists remain representable for compatibility with the previous API.

## Value semantics

Equality distinguishes variants, then compares constant values with Dart ==,
indexed values by ordered item equality, and callbacks with Dart function
identity/equality (including equal method tear-offs). It deliberately does not
compare generic runtimeType: equivalent values inferred as Color and a Color
subclass compare symmetrically and have equal hashes. Lists are not copied by
the const constructor; each lowering copies them into a mutable engine list.

Stable callback references remain important. A new closure on each Flutter
build is a different configuration value, just as with backgroundColorFor.
Diagnostics include the variant and its value/list/callback.

## Opt integration

Lowering switches by the public variant through toOptionCell and stores that
cell directly with OptionScope.store:

- constant → OptValue<T>;
- indexed → OptList<T>, holding a fresh mutable List<Object?>;
- resolver → OptFunction<T>, holding a fresh two-argument raw callback bridge.

The bridge forwards the typed ChartContext view without copying it or evaluating
the callback during lowering. It preserves the previous two-argument JS-call
adapter. `extra` still merges last, including explicit null and key-order rules.
Reconciliation keeps the existing raw-value comparison/invalidation behavior.

This removes raw-value classification at the public-to-scope boundary. It does
**not** replace the existing general resolver: that layer still exposes/reads
raw values where Chart.js compatibility requires them, and uses ADR 0076's
indexed point/bar plan when eligible. No ported module imports typed/. A public
sealed wrapper alone is not evidence of an additional per-element speedup.

## Validation and experiment

Typed/raw chart twins, callback and reconciliation tests are migrated. New tests
cover variant matching, equality/hash symmetry across generic types, direct Opt
kinds, copied/empty lists, callback laziness, extra precedence, and copyWith across
all eight datasets. Updated README snippets are executed in a temporary widget
test. Public-name collision and export checks include the four new names.

The AOT comparison measures construction plus lowerDataset separately from full
update plus native paint/record completion, for line/bar and static/indexed/
resolver colors. Both versions use the existing optimized core. Thus it measures
this API/lowering experiment rather than comparing against the pre-ADR-0076
resolver. Source snapshots, paired results and limits are retained in
[benchmarks/chart-value](../benchmarks/chart-value/README.md).


## Result of the original background-only experiment

The constructor/lowering microbenchmark is 5–11% faster, an absolute saving of
about 0.02–0.04 microseconds per dataset. Full update/paint changes range from
-0.7% to +2.8%; there is no meaningful additional rendering speedup. The main
result is a single type-safe parameter and straightforward variant switching.
The existing resolver remains the next performance boundary, rather than an
assumed benefit of introducing the public sealed type.

All 442 typed tests and 10,867 workspace tests pass. The 20 new value tests pass
on VM, JS and Wasm. The migrated README snippets execute, the public-name/export
checks pass, and analysis, formatting, generated parity and port checks are clean.


## Border-color follow-up

The remaining borderColor/borderColors/borderColorFor triplet now uses the same
ChartValue<Color> field and direct Opt lowering. No other triplets remain in the
typed API. The obsolete colorOption/colorScript adapters and constructor
exclusivity assertions are removed. Background and border variants can change
independently through copyWith. Indexed lists retain mutable engine copies,
callbacks remain lazy, and raw extra values still win in the original key order.
This extension makes no additional rendering-performance claim.


Border follow-up validation: all 10,877 workspace tests pass with Melos C2.
The expanded 31-case ChartValue suite passes on VM, JavaScript and WebAssembly,
and the updated README snippets compile and run. Existing typed/raw twins cover
chart output while the focused tests pin independent variants, copied lists,
lazy callbacks, explicit raw nulls and option-key order.
