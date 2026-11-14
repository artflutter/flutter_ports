# Chart.js ADR 0026: Number formatting on package:intl

- Status: accepted (2026-10-20)
- Superseded by: [Chart.js ADR 0119](0119-plain-intl-number-format.md) (2026-11-12)
- Date: 2026-10-20
- Supersedes: [Chart.js ADR 0008](0008-number-formatting-on-package-intl.md)
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:packages/flutter_chartjs_port/doc/adr/0026-number-formatting-on-package-intl.md`

## Summary

`Intl.NumberFormat` was the `NumberFormat` of package:intl behind the adapter `lib/src/js/js_intl.dart`.
The adapter mapped the JS locale and the JS options object onto package:intl.
Six guards wrote the digits without package:intl where package:intl threw or gave another value than V8.
The guards covered large numbers, NaN, the infinities, scientific notation and more than 15 fraction digits.
Chart.js ADR 0119 removed the adapter and the guards: the port uses package:intl as it is.

## Where each part went

- Decision 1 (the formatter is the `NumberFormat` of package:intl):
  [Chart.js ADR 0119](0119-plain-intl-number-format.md) decision 2. The adapter `js_intl.dart`: removed by
  Chart.js ADR 0119 decision 5.
- Decision 2 (the locale): [Chart.js ADR 0119](0119-plain-intl-number-format.md) decisions 1 and 3.
- Decision 3 (the mapping of the options): removed by [Chart.js ADR 0119](0119-plain-intl-number-format.md)
  decision 1. The tick option `format` holds a `NumberFormat`.
- Decision 4 (the unsupported options): removed by [Chart.js ADR 0119](0119-plain-intl-number-format.md)
  decision 1. An object of format options stops a debug build.
- Decision 5 (the six guards against package:intl defects): removed by
  [Chart.js ADR 0119](0119-plain-intl-number-format.md) decisions 4 and 5.
- Decision 6 (the cache and its key): [Chart.js ADR 0119](0119-plain-intl-number-format.md) decision 3.
  The String key of the option entries: removed by Chart.js ADR 0119 decision 5.
- Decision 7 (the row `adapt-intl-number-format`): [Chart.js ADR 0119](0119-plain-intl-number-format.md), Related.
- Decision 8 (the skip reason of a spec case with another V8 string): the general skip rule of
  [porting-flow.md](../porting-flow.md) §1 step 5. No spec case skips with this reason.
- Decision 9 (the tests): [Chart.js ADR 0119](0119-plain-intl-number-format.md), Tests. The tests against
  V8 reference strings: removed by Chart.js ADR 0119 decision 5.
- Decision 10 (more than 15 fraction digits below `2^53`): removed by
  [Chart.js ADR 0119](0119-plain-intl-number-format.md) decisions 4 and 5.
