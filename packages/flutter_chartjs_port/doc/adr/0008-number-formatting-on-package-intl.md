# Chart.js ADR 0008: Number formatting on package:intl

- Status: accepted (2026-10-18)
- Date: 2026-10-18
- Superseded by: [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) (2026-10-20)
- Full text: `git show 2ee913263ba0fad4d08b0e9744c3a86575286268:packages/flutter_chartjs_port/doc/adr/0008-number-formatting-on-package-intl.md`

## Summary

This ADR formatted numbers with the `NumberFormat` of package:intl, not with an ICU-exact formatter. A
port-only adapter, `jsNumberFormat`, mapped the JS locale and the JS options onto package:intl. Three guards
stopped the throws and some wrong digits of package:intl. A cache key of the option entries found a formatter.
The row `adapt-intl-number-format` recorded the differences from V8.

## Where each part went

- Item 1 (the adapter): [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) item 1.
  [Chart.js ADR 0119](0119-plain-intl-number-format.md) removes `jsNumberFormat` and uses package:intl as it
  is.
- Item 2 (the locale): [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) item 2.
  [Chart.js ADR 0119](0119-plain-intl-number-format.md) items 1 and 3 give a Flutter `Locale`.
- Item 3 (the options): [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) item 3.
  [Chart.js ADR 0119](0119-plain-intl-number-format.md) item 1 gives a `NumberFormat` in the tick option
  `format`.
- Item 4 (the unsupported options): [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) item 4.
  Removed by [Chart.js ADR 0119](0119-plain-intl-number-format.md).
- Item 5 (the guards): [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) item 5. Removed by
  [Chart.js ADR 0119](0119-plain-intl-number-format.md) item 4.
- Item 6 (the cache): [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) item 6.
  [Chart.js ADR 0119](0119-plain-intl-number-format.md) items 3 and 5 give the current cache key.
- Item 7 (the difference row): [Chart.js ADR 0119](0119-plain-intl-number-format.md) keeps the row
  `adapt-intl-number-format`.
- Item 8 (the spec cases that skip): [Chart.js ADR 0026](0026-number-formatting-on-package-intl.md) item 8. No
  spec case skips with this reason under [Chart.js ADR 0119](0119-plain-intl-number-format.md).
- Item 9 (the tests): [Chart.js ADR 0119](0119-plain-intl-number-format.md), Tests.
