# Chart.js ADR 0178: No JS-semantics check

- Status: accepted (2026-11-18): the check is removed, and the tests of section Tests pass.
- Date: 2026-11-18
- Supersedes: of [Chart.js ADR 0146](0146-js-numeric-semantics.md), §8, the `js-ok` comments of §3, §4 and §5, and
  the `check_js_semantics_test.dart` bullet of section Tests; of [Chart.js ADR 0034](0034-no-display-only-js-exactness.md),
  in §1 the `js-ok` comments and the tool 3 bullet; of [Chart.js ADR 0035](0035-third-party-sources.md), in item 3 the
  tool 3 bullet; of [Chart.js ADR 0029](0029-fixture-smoke-runner.md), in item 7 `check:js-semantics`; of
  [Chart.js ADR 0040](0040-filler-targets-and-plain-points.md), in §3 the sentence of `check:js-semantics` and in §5
  the `js-ok` comment; of [Chart.js ADR 0041](0041-plugin-test-strategy.md), in §10 item 8 the `js-ok` comment; of
  [Chart.js ADR 0176](0176-number-text-and-string-ids.md), the last sentence of item 1 and the second bullet of
  section Tests; of [Chart.js ADR 0177](0177-no-number-text-helper.md), the last sentence of item 4 and the third
  bullet of section Tests.
- Related: [Chart.js ADR 0177](0177-no-number-text-helper.md)

## Context

Tool 3, `check:js-semantics`, flagged the Dart forms whose results differ from JavaScript: `%`, `.round()`, `pow(`,
`.sort(`, a `double` in a string, `max` and `min` with `num`, and `DateTime.now(`. A site that kept such a form
carried a `// js-ok: <reason>` comment. The port now gives typed Dart values, and Chart.js ADR 0177 gives a message
the Dart text of a number. The check then flagged plain Dart code, and the comments only silenced it.

## Decision

1. **The port has no JS-semantics check.** `tool/check_js_semantics.dart`, `tool/src/js_semantics.dart` and
   `test/tool/check_js_semantics_test.dart` are removed. `check:port`, the CI job `port-checks` and the melos scripts
   do not run it.
2. **The code has no `js-ok` comments.** A site that needs a reason has a plain comment.
3. **The rules of the numbers stay.** Chart.js ADR 0146 §1 to §7 still decide the Dart form of each JS form. The
   review and the tests apply them.
4. **`dartSdkPath` moves to `tool/src/dart_sdk.dart`.** The tool tests that resolve the library with
   `package:analyzer` import it from there.

## Rejected

- Keep the check without the rule of the number text: the other rules flag typed Dart code too, and each kept form
  needs a comment.

## Consequences

- A port of a new file gets no warning for a JS form with another result. The reviewer and the reference tests find
  it.
- The proposed ADRs of the D3, ECharts and zoom ports and ADRs 0008 and 0009 still name tool 3. A decision on each of
  them removes the tool.

## Tests

- `test/tool/public_api_test.dart`, `test/port/typed/names_test.dart` and
  `test/port/plugins/plugin.filler/point_implementers_test.dart` with `dartSdkPath` of `tool/src/dart_sdk.dart`.
- The full test list of AGENTS.md before a push.
