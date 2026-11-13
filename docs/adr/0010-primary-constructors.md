# ADR 0010: Primary constructors

- Status: accepted
- Date: 2026-11-13
- Gate: the migration commit. The lead accepts the ADR when the migration passes the full pre-push
  list of AGENTS.md.
- Related: [ADR 0001](0001-native-ports-not-wrappers.md) (native ports),
  [Chart.js ADR 0012](../../packages/flutter_chartjs_port/doc/adr/0012-dart-file-naming.md)
  (the upstream names),
  [Chart.js ADR 0054](../../packages/flutter_chartjs_port/doc/adr/0054-typed-internal-model.md)
  (rule 2 for the typed layers)

## Context

Dart 3.13 has primary constructors. A class, an enum or a mixin class can declare its constructor
in its header. A parameter with `final` or `var` declares a field. The class body keeps a `this`
body for the initializer list, the asserts, the statements and the doc comment of the constructor.
A secondary constructor names itself with `new` or `factory` and no class name:

```dart
/// A point.
class const Point(
  /// The horizontal coordinate.
  final double x,

  /// The vertical coordinate.
  final double y,
) {
  /// A point at [x] and [y].
  this : assert(x.isFinite && y.isFinite);

  /// The point at the origin.
  new origin() : this(0, 0);
}
```

The workspace floor `sdk: ^3.13.0` enables the feature. `very_good_analysis` 11.0.0 adds the lints
of the new form: `use_declaring_parameters`, `unnecessary_primary_constructor_body`,
`unnecessary_type_name_in_constructor` and `initialize_in_field_declaration`. The SDK lint
`use_primary_constructors` asks for the form on each class whose constructors allow it. `dart fix`
fixes each of these lints.

On 2026-11-13 the workspace has about 1,460 classes. `use_primary_constructors` flags 1,453
declarations, the generated files and the probes of the generator included.

## Decision

1. Each class, enum and mixin class of the workspace uses a primary constructor when its
   constructors allow it, also a class with no declared constructor (`class Foo() { ... }`). A
   class with two generative constructors that do not redirect keeps its constructors. Both
   `analysis_options.yaml` files turn on `use_primary_constructors`, so new code keeps the form.
2. A parameter that only initializes a field of the same name declares that field. Its doc comment
   moves into the header with it. A field initializer that reads only parameters moves to the field
   declaration (`initialize_in_field_declaration`).
3. A secondary constructor takes the form `new <name>(...)` or `factory <name>(...)`. The call
   sites do not change: `Foo.name(...)` and `Foo.new` stay valid.
4. Rule 2 of AGENTS.md stays. A ported class keeps its upstream name, its member names and the
   upstream order of its methods. Its fields can move into the header: a field is not a function,
   and the upstream function order is the diff anchor of a bump.
5. The generators write the form: `tool/src/options_gen.dart` of the Chart.js port (the enums
   `OptionKey` and `ScopeKind`, the scope classes, and the `new` names of the resolved options) and
   `tool/reference/animation_reference.mjs` (the class `AnimationAbsent`). No generated file changes
   by hand.
6. Exception: the analyzer of Dart 3.14 (also 3.15 dev) rejects each const instance of a class
   whose field initializer reads a super parameter when the superclass comes from another library.
   The VM accepts the same code. `ChartTextStyle` keeps its `lineHeight` initializer in the
   initializer list of its `this` body, with an ignore of `initialize_in_field_declaration` and a
   comment that names the bug. When a later SDK fixes the analyzer, the ignore goes.
7. A doc reference to a super parameter (`[newTarget]`, `[cfg]`) does not resolve in the doc of
   a `this` body. Such a name is a code span.
8. A hook argument class of `lib/src/types/plugin.dart` writes each key through the setter of its
   slot, not into a field. That file ignores `use_declaring_parameters`.

## Alternatives considered

- Convert only the classes with a declared constructor, and leave `use_primary_constructors` off.
  About 400 classes keep an implicit constructor. The rule then depends on the review, and a new
  class can take either form. Rejected: the maintainer asked for all classes.
- Keep the old form. Rejected: `very_good_analysis` 11.0.0 asks for declaring parameters and the
  new constructor names, and the form removes about 3,400 lines of field and constructor
  boilerplate.

## Consequences

- The migration changes about 440 files in one commit, mostly by `dart fix`. The observation
  digests (oracle O1) and the public API list do not change.
- A public class with an implicit constructor now has an explicit primary constructor. Each such
  public constructor has a doc comment on its `this` body (`public_member_api_docs`).
- A port that starts later (D3, ECharts) uses the form from its first ported file.
