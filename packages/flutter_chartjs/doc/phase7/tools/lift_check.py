# Original code, not ported from Chart.js: the lift check of the phase 7
# test strategy (doc/phase7/design/test-strategy/spec.md section 4.1).
"""Checks the phase 7 classification records against a test run.

Usage (from packages/flutter_chartjs):

    flutter test --reporter json test/specs test/port > <scratch>/out.json
    python3 -I doc/phase7/tools/lift_check.py \
        doc/phase7/classification/all.json <scratch>/out.json [<wave>] [--list]

- A record of all.json names its Dart test with `dartFile`, `describe` and
  `it`. The full name is the `describe` names and the `it` name, joined with
  spaces, as tool 5 does. The JSON reporter gives the same full name in
  `test.name`.
- The wave of a record is the largest wave of the modules of its `modules`:
  controller.bar 1; controller.line, controller.bubble, controller.doughnut,
  controller.polarArea and controller.radar 2; controller.scatter,
  controller.pie and controllers/index 3; each other module 0.
- With a wave number, only the records of that wave or of an earlier wave
  get the rules. Without it, all records get the rules.
- Rules: a `phase7` record has a test that is not skipped and that has the
  result `success`. A `blocked: plugin.<id>` record has a test that skips
  with exactly that reason.
- The counts by spec file of all.json must equal the counts of
  classification/summary.md section 2 with decision D1 (the three legend
  cases of controller.bar are `phase7`): `phase7` 503, legend 21, tooltip
  11, filler 1.
- `--list` (with a wave number) prints the lift list of that wave: each
  record of exactly that wave that fails a rule, with the file, the full
  name and the current skip reason of the run.

The exit code is 1 when a record fails a rule or a count differs, else 0.
"""

import collections
import json
import sys

WAVES = {
    'controller.bar': 1,
    'controller.line': 2,
    'controller.bubble': 2,
    'controller.doughnut': 2,
    'controller.polarArea': 2,
    'controller.radar': 2,
    'controller.scatter': 3,
    'controller.pie': 3,
    'controllers/index': 3,
}

VERDICTS = (
    'phase7',
    'blocked: plugin.legend',
    'blocked: plugin.tooltip',
    'blocked: plugin.filler',
)

# summary.md section 2, with decision D1 for controller.bar (54 phase7, 0
# legend). The columns are the four verdicts of VERDICTS.
EXPECTED = {
    'test/specs/controller.bar_test.dart': (54, 0, 1, 0),
    'test/specs/controller.bubble_test.dart': (10, 0, 1, 0),
    'test/specs/controller.doughnut_test.dart': (12, 0, 1, 0),
    'test/specs/controller.line_test.dart': (33, 0, 1, 0),
    'test/specs/controller.polarArea_test.dart': (13, 0, 1, 0),
    'test/specs/controller.radar_test.dart': (11, 0, 1, 1),
    'test/specs/controller.scatter_test.dart': (4, 0, 2, 0),
    'test/specs/core.animator_test.dart': (1, 0, 0, 0),
    'test/specs/core.controller_test.dart': (37, 1, 3, 0),
    'test/specs/core.datasetController_test.dart': (43, 0, 0, 0),
    'test/specs/core.interaction_test.dart': (45, 0, 0, 0),
    'test/specs/core.layouts_test.dart': (5, 6, 0, 0),
    'test/specs/core.scale_test.dart': (31, 0, 0, 0),
    'test/specs/core.ticks_test.dart': (2, 0, 0, 0),
    'test/specs/element.line_test.dart': (1, 0, 0, 0),
    'test/specs/helpers.dom_test.dart': (2, 0, 0, 0),
    'test/specs/platform.basic_test.dart': (0, 2, 0, 0),
    'test/specs/platform.dom_test.dart': (2, 0, 0, 0),
    'test/specs/scale.category_test.dart': (13, 4, 0, 0),
    'test/specs/scale.linear_test.dart': (36, 2, 0, 0),
    'test/specs/scale.logarithmic_test.dart': (58, 0, 0, 0),
    'test/specs/scale.radialLinear_test.dart': (18, 3, 0, 0),
    'test/specs/scale.time_test.dart': (15, 3, 0, 0),
    'test/port/scales/scale.time_test.dart': (57, 0, 0, 0),
}
EXPECTED_TOTALS = (503, 21, 11, 1)


def wave_of(record):
    """The largest wave of the modules of the record."""
    return max([WAVES.get(module, 0) for module in record['modules']])


def full_name(record):
    """The group names and the test name, joined with spaces."""
    return ' '.join(list(record['describe']) + [record['it']])


def relative_path(path):
    """The path of a suite relative to packages/flutter_chartjs."""
    marker = 'packages/flutter_chartjs/'
    index = path.find(marker)
    return path[index + len(marker):] if index >= 0 else path


def read_run(path):
    """Maps (file, full name) to a list of (skip reason, result) pairs."""
    suites = {}
    starts = {}
    tests = collections.defaultdict(list)
    with open(path, encoding='utf-8') as source:
        for line in source:
            line = line.strip()
            if not line.startswith('{'):
                continue
            try:
                event = json.loads(line)
            except ValueError:
                continue
            kind = event.get('type')
            if kind == 'suite':
                suite = event['suite']
                suites[suite['id']] = relative_path(suite.get('path') or '')
            elif kind == 'testStart':
                test = event['test']
                metadata = test.get('metadata') or {}
                skip = metadata.get('skipReason') if metadata.get('skip') else None
                starts[test['id']] = (test['suiteID'], test['name'], skip)
            elif kind == 'testDone':
                if event.get('hidden'):
                    continue
                start = starts.get(event['testID'])
                if start is None:
                    continue
                suite_id, name, skip = start
                result = 'skipped' if event.get('skipped') else event['result']
                tests[(suites.get(suite_id, ''), name)].append((skip, result))
    return tests


def check_record(record, tests):
    """Gives (passes, current skip text) for one record."""
    runs = tests.get((record['dartFile'], full_name(record)))
    if not runs:
        return False, 'missing'
    verdict = record['verdict']
    skips = sorted({str(skip) for skip, _ in runs if skip is not None})
    current = ', '.join(skips) if skips else None
    if verdict == 'phase7':
        ok = all(skip is None and result == 'success' for skip, result in runs)
        if not ok and current is None:
            current = 'failed: ' + ', '.join(result for _, result in runs)
        return ok, current
    ok = all(skip == verdict and result == 'skipped' for skip, result in runs)
    return ok, current


def check_counts(records):
    """Gives the lines of the count check and the number of differences."""
    counts = collections.defaultdict(lambda: [0, 0, 0, 0])
    for record in records:
        counts[record['dartFile']][VERDICTS.index(record['verdict'])] += 1
    lines = []
    errors = 0
    for name in sorted(set(EXPECTED) | set(counts)):
        actual = tuple(counts.get(name, (0, 0, 0, 0)))
        expected = EXPECTED.get(name)
        if actual != expected:
            errors += 1
            lines.append(f'count differs: {name}: {actual}, expected {expected}')
    totals = tuple(sum(counts[name][i] for name in counts) for i in range(4))
    if totals != EXPECTED_TOTALS:
        errors += 1
        lines.append(f'totals differ: {totals}, expected {EXPECTED_TOTALS}')
    lines.append(
        'counts (phase7, legend, tooltip, filler): '
        f'{totals[0]}, {totals[1]}, {totals[2]}, {totals[3]}'
        + (' (as summary.md section 2 with D1)' if not errors else ''))
    return lines, errors


def main(argv):
    """Runs the check. Gives the exit code."""
    flags = [arg for arg in argv if arg.startswith('--')]
    args = [arg for arg in argv if not arg.startswith('--')]
    if len(args) not in (2, 3) or set(flags) - {'--list'}:
        print(__doc__)
        return 2
    wave = int(args[2]) if len(args) == 3 else None
    if '--list' in flags and wave is None:
        print('--list needs a wave number.')
        return 2
    with open(args[0], encoding='utf-8') as source:
        records = json.load(source)
    tests = read_run(args[1])

    failures = 0
    by_file = collections.defaultdict(lambda: [0, 0])
    lift = []
    for record in records:
        record_wave = wave_of(record)
        if wave is not None and record_wave > wave:
            continue
        ok, current = check_record(record, tests)
        by_file[record['dartFile']][0 if ok else 1] += 1
        if ok:
            continue
        failures += 1
        print(f'FAIL wave {record_wave} {record["dartFile"]}: '
              f'"{full_name(record)}" ({record["verdict"]}; now: {current})')
        if wave is not None and record_wave == wave:
            lift.append((record['dartFile'], full_name(record), current))

    count_lines, count_errors = check_counts(records)
    for line in count_lines:
        print(line)
    scope = f'wave {wave} and earlier' if wave is not None else 'all waves'
    print(f'records of {scope}, by file (pass, fail):')
    for name in sorted(by_file):
        passed, failed = by_file[name]
        print(f'  {name}: {passed}, {failed}')
    total_passed = sum(value[0] for value in by_file.values())
    print(f'{scope}: {total_passed + failures} records, {total_passed} pass, '
          f'{failures} fail; count differences: {count_errors}')
    if '--list' in flags:
        print(f'lift list of wave {wave} ({len(lift)} records):')
        for name, test, current in lift:
            print(f'  {name}\t{test}\t{current}')
    return 1 if failures or count_errors else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
