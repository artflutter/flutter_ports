# ADR 0003: Package names

- Status: accepted
- Date: 2026-10-16
- Superseded by: [ADR 0007](0007-package-names.md) (2026-10-22)
- Full text: `git show ac269e6feef50e1b382722e1ff4c17f0079cb130:docs/adr/0003-package-names.md`

## Summary

The Chart.js port took the pub.dev name `flutter_chartjs`, and its gallery app took `chartjs_gallery`.
On 2026-10-16, other packages held the names `chart`, `chartjs`, `chartjs2` and `chartjs_flutter`.
A later port took a free `flutter_<library>` name. A port with a taken name decided its name in its own ADR.

## Where each part went

- Context (the taken names of 2026-10-16): [ADR 0007](0007-package-names.md) Context, the pub.dev
  examination.
- Decision (the Chart.js name `flutter_chartjs`): [ADR 0007](0007-package-names.md) item 2, now
  `flutter_chartjs_port`.
- Decision (the gallery app `chartjs_gallery`): [ADR 0007](0007-package-names.md) items 2 and 4.
- Decision (the names of later ports): [ADR 0007](0007-package-names.md) items 1 and 9.
- Consequences (a rename before the first release costs nothing, [ADR 0007](0007-package-names.md) cites it):
  [ADR 0007](0007-package-names.md) item 10.
- Consequences (the README says that the package is a native port): [ADR 0007](0007-package-names.md) item 1.
