# Chart.js ADR 0201: No extra Map in the typed API

- Status: accepted (2026-11-24): its code is on main, and the gates of AGENTS.md pass.
- Date: 2026-11-24
- Supersedes: of [Chart.js ADR 0052](0052-typed-public-api.md), §1 for the parameter `extra` of each
  class, §2 item 9 (the merge of `extra`) and §4 for the bullets on `extra`
- Related: [Chart.js ADR 0198](0198-remove-raw-chart-view.md), [Chart.js ADR 0199](0199-typed-fixture-configs.md),
  [Chart.js ADR 0191](0191-typed-axes.md)

## Context

Each class of the typed API had `extra`, a Map of Chart.js options that merged into the scope of the
class last (Chart.js ADR 0052). After the raw `ChartView` went (Chart.js ADR 0198), `extra` was the last
way into the library for option values by name: the apps used it for 54 options, and the tests for
about 1,200 values, most of them options that had no parameter yet. A Map path keeps the by-name
runtime of the library alive, and a typo in a key fails with no error.

## Decision

1. No class of the typed API has `extra`. `mergeExtra` is gone from the library. Each option is a
   typed parameter.

   ```dart
   // Before
   LinearAxis(.y, extra: {'stack': '1', 'offset': true, 'stackWeight': 2})
   // After
   LinearAxis(.y, stack: '1', offset: true, stackWeight: 2)
   ```

2. An option with two forms in Chart.js has a second parameter. A config gives one of the two, and
   both forms of one pair stop a debug build. The pairs: `borderRadius` and `borderRadiusCorners` (a
   `BorderRadius`), `borderWidth`, `borderWidths` (a `ChartValue<double>`) and `borderWidthSides` (an
   `EdgeInsets`), `spanGaps` and `spanGapsDistance`, `CategoryAxis.min`/`max` and `minIndex`/`maxIndex`,
   `TimeAxis.parser` and `parserFunction`, and an axis `border` and `borderFunction`.
3. A scriptable option of an axis part is a `ScaleValue<T>` (`.constant`, `.indexed`, `.resolver` of a
   `ScriptableScaleContext`), as `ChartValue<T>` is for a dataset.
4. The options of all datasets of a type are `ChartConfig.datasetDefaults`, a `List<Dataset>` that
   writes `options.datasets.<type>`. A dataset option at the options root of a config with one dataset
   type moves there; the root colors stay at the root, because the colors plugin reads them there.
5. The floating bars of a dataset are `DatasetData.ranges`, a List of `(start, end)` records.
6. The tests keep the value forms that only JavaScript has (a string number in `data`, a date text as
   `min`, a key that Chart.js does not declare) in the harness: `raw(object, map)` of
   `chartjs_test_utils` attaches a Map to a typed object, and `lowerForTest(config)` merges each Map
   into the lowered scope of its object, last, as `extra` merged. `scopeFromMap` of `pure.dart` is the
   Map merge of the tests. The config generators write `raw`.
7. A Chart.js option with no parameter has no typed form. The inline plugin `$chartView` of `ChartView`
   has no off switch in the typed API.

## Rejected

- A `Dataset.borderWidth` of `ChartValue<double>`: it changes 479 call sites for one indexed use.
- One class for each nested group (`time`, `pointLabels`): `TimeAxis` already had flat `unit` and
  `tooltipFormat`.
- Keep `extra` for the tests only: the library would keep its Map merge.

## Consequences

- An option that a new release of Chart.js adds needs a parameter before an app can set it.
- A typo in an option name is a compile error.
- O1 and the fixtures are unchanged: the raw options merge where `extra` merged.

## Tests

`test/port/typed/two_form_options_test.dart`, `test/port/typed/lowering_test.dart`,
`test/port/typed/value_semantics_test.dart`, `test/port/typed/key_check_test.dart`,
`test/port/options/observation_test.dart`.
