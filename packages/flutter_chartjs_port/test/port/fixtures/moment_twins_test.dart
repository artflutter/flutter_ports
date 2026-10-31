// Original code, not ported from Chart.js: the ICU twins of the fixtures that parse with a moment format string (row adapt-date-moment-format).
@TestOn('vm')
library;

// The header text of FR section 5 is longer than 80 columns and has no URI.
// ignore_for_file: lines_longer_than_80_chars

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGetKey;
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/index.dart' show fixtureSkips;

/// The 36 pure data configs of FR Appendix C (Chart.js ADR 0029, section 9
/// item 4), in manifest order. Each one skips in the `auto` group of its
/// spec file with the reason [_reason].
const List<String> _twins = [
  'controller.bar/bar-thickness-absolute.json',
  'controller.bar/bar-thickness-flex.json',
  'controller.bar/bar-thickness-flex-offset.json',
  'controller.bar/bar-thickness-flex-single.json',
  'controller.bar/bar-thickness-flex-single-reverse.json',
  'controller.bar/bar-thickness-max.json',
  'controller.bar/bar-thickness-min-interval.json',
  'controller.bar/bar-thickness-min-interval-multi.json',
  'controller.bar/bar-thickness-multiple.json',
  'controller.bar/bar-thickness-no-overlap.json',
  'controller.bar/bar-thickness-offset.json',
  'controller.bar/bar-thickness-per-dataset.json',
  'controller.bar/bar-thickness-per-dataset-stacked.json',
  'controller.bar/bar-thickness-reverse.json',
  'controller.bar/bar-thickness-single.json',
  'controller.bar/bar-thickness-single-xy.json',
  'controller.bar/bar-thickness-stacked.json',
  'scale.time/labels.js',
  'scale.time/source-auto-linear.js',
  'scale.time/source-data-linear.js',
  'scale.time/source-labels-linear.js',
  'scale.time/source-labels-linear-offset-min-max.js',
  'scale.time/ticks-reverse.js',
  'scale.time/ticks-reverse-linear.js',
  'scale.time/ticks-reverse-linear-min-max.js',
  'scale.time/ticks-reverse-offset.js',
  'scale.timeseries/normalize.js',
  'scale.timeseries/source-auto.js',
  'scale.timeseries/source-data.js',
  'scale.timeseries/source-data-offset-min-max.js',
  'scale.timeseries/source-labels.js',
  'scale.timeseries/source-labels-offset-min-max.js',
  'scale.timeseries/ticks-reverse.js',
  'scale.timeseries/ticks-reverse-max.js',
  'scale.timeseries/ticks-reverse-min.js',
  'scale.timeseries/ticks-reverse-min-max.js',
];

/// The skip reason of the fixtures that the twins replace.
const String _reason = 'diverges: adapt-date-moment-format';

/// The ICU pattern of each moment pattern of the twins.
const Map<String, String> _icu = {'YYYY': 'yyyy', 'YYYY-MM': 'yyyy-MM'};

/// The twins with time values of the datasets that do not parse, with the
/// number of these values. A twin that is not a key has 0.
///
/// - In `scale.time/source-labels-linear-offset-min-max.js` and
///   `scale.time/ticks-reverse-linear-min-max.js`, the dataset has 6 values
///   and the chart has 5 labels. The sixth value has no label, so Chart.js
///   at the pin also parses `undefined` (1 value, the x64 Node.js probe of
///   the T1 fixes).
/// - `controller.bar/bar-thickness-no-overlap.json` is in [_differs].
const Map<String, int> _unparsed = {
  'controller.bar/bar-thickness-no-overlap.json': 4,
  'scale.time/source-labels-linear-offset-min-max.js': 1,
  'scale.time/ticks-reverse-linear-min-max.js': 1,
};

/// The twins that do not give the chart of Chart.js at the pin. [_examine]
/// does not examine their time scales.
///
/// `controller.bar/bar-thickness-no-overlap.json` has the parser `'YYYY-MM'`
/// and the x values `'2016'`, `'2017'`, `'2017-08'`, `'2024'` and `'2030'`.
/// moment parses in forgiving mode: a value that ends before the pattern
/// ends gives the date of the fields that moment read. Thus Chart.js at the
/// pin parses all 5 values. The `tryParse` of intl gives null for such a
/// value, so the port parses only `'2017-08'` (4 values in [_unparsed]). No
/// ICU pattern parses both `'2016'` and `'2017-08'`. The row
/// `adapt-date-moment-format` of `doc/differences.md` names this difference
/// (step 4 review, finding T1-R1). The entry in [_unparsed]
/// pins the port result, so that a change of the date adapter makes the
/// twin fail.
const Set<String> _differs = {'controller.bar/bar-thickness-no-overlap.json'};

/// The scale types that parse with the date adapter.
const Set<String> _timeTypes = {'time', 'timeseries'};

/// The `run` hook of a twin at [path] with [datasets] datasets: examines
/// the chart. [named] has the time values of the date strings of the config
/// ([_named]).
///
/// The fixture runner calls the hook after it acquires the chart
/// (fixture.js:63). The hook examines the parsed time values of the
/// datasets:
/// - The number of values that do not parse must be the number in
///   [_unparsed] (0 when [path] is not a key).
/// - When [path] is not in [_differs], each value that parses must be in
///   [named].
///
/// Then, when [path] is not in [_differs], the min and the max of each time
/// scale must be in [named], and the scale must have at least one tick. Each
/// tick must have a finite value, and a label that contains the 4-digit UTC
/// year of that value.
///
/// Chart.js at the pin gives these numbers and these properties for the
/// moment form of each of the 36 configs (the x64 Node.js probe of the T1
/// fixes). Thus a moment pattern that stays in the twin, or a defect of the
/// ICU parse or format, makes the twin fail. A smoke test alone fails only
/// on an exception.
Object? Function(Object?) _examine(
  String path,
  int datasets,
  Set<double> named,
) => (value) {
  final chart = value! as Chart;
  final differs = _differs.contains(path);
  var unparsed = 0;
  for (var i = 0; i < datasets; i++) {
    final meta = chart.getDatasetMeta(i);
    for (final scale in [meta.iScale, meta.vScale]) {
      if (scale is! Scale || !_timeTypes.contains(scale.type)) continue;
      for (final item in meta.parsed) {
        final time = jsGetKey(item, scale.axis);
        if (time is! num || !time.isFinite) {
          unparsed++;
        } else if (!differs) {
          expect(
            named.contains(time.toDouble()),
            isTrue,
            reason:
                '$path: the dataset $i has the time value $time, which no '
                'date string of the config gives',
          );
        }
      }
    }
  }
  expect(
    unparsed,
    _unparsed[path] ?? 0,
    reason: '$path: the number of time values that do not parse',
  );
  if (differs) return null;
  for (final MapEntry(key: id, value: scale) in chart.scales.entries) {
    if (!_timeTypes.contains(scale.type)) continue;
    expect(
      named.contains(scale.min) && named.contains(scale.max),
      isTrue,
      reason:
          '$path: the scale $id has the min ${scale.min} and the '
          'max ${scale.max}',
    );
    final ticks = scale.ticks ?? const <Tick>[];
    expect(ticks, isNotEmpty, reason: '$path: the scale $id has no tick');
    for (final tick in ticks) {
      final label = tick.label;
      final year = tick.value.isFinite
          ? DateTime.fromMillisecondsSinceEpoch(
              tick.value.toInt(),
              isUtc: true,
            ).year.toString().padLeft(4, '0')
          : null;
      expect(
        year != null && label is String && label.contains(year),
        isTrue,
        reason:
            '$path: the scale $id has the tick ${tick.value} with '
            'the label "$label"',
      );
    }
  }
  return null;
};

/// The time values of the date strings of [node]: each string `'YYYY'` or
/// `'YYYY-MM'` at any depth gives the UTC time value of the start of that
/// year or month.
///
/// The value is independent of the date adapter. The test zone is UTC
/// (`flutter_test_config.dart`).
Set<double> _named(Object? node) {
  final named = <double>{};
  final date = RegExp(r'^(\d{4})(?:-(\d{2}))?$');
  void walk(Object? node) {
    if (node is String) {
      if (date.firstMatch(node) case final match?) {
        final year = int.parse(match[1]!);
        final month = match[2] == null ? 1 : int.parse(match[2]!);
        named.add(DateTime.utc(year, month).millisecondsSinceEpoch.toDouble());
      }
    } else if (node is Map) {
      node.values.forEach(walk);
    } else if (node is List) {
      node.forEach(walk);
    }
  }

  walk(node);
  return named;
}

/// Loads the ICU twin of the fixture at [path] from [source], with the
/// `run` hook [_examine].
///
/// Throws a [StateError] when the fixture has a `run` hook.
Map<String, Object?> _load(FixtureSource source, String path) {
  final json = _toIcu(source.dataConfig(path));
  final config = json['config']! as Map<String, Object?>;
  final data = config['data']! as Map<String, Object?>;
  final datasets = (data['datasets'] as List<Object?>?)?.length ?? 0;
  final options =
      (json['options'] ??= <String, Object?>{}) as Map<String, Object?>;
  if (options.containsKey('run')) {
    throw StateError('$path: the fixture has a run hook.');
  }
  options['run'] = _examine(path, datasets, _named(config));
  return json;
}

/// Replaces the moment pattern at each `parser` key and each string value
/// of a `displayFormats` Map of [config] with its ICU pattern of [_icu].
///
/// Returns the same Map. Throws a [StateError] for another string at these
/// places, and when [config] has no moment pattern.
Map<String, Object?> _toIcu(Map<String, Object?> config) {
  var count = 0;
  String icu(Object path, String moment) {
    final pattern = _icu[moment];
    if (pattern == null) {
      throw StateError('$path: the moment pattern "$moment" has no twin.');
    }
    count++;
    return pattern;
  }

  void walk(Object? node) {
    if (node is Map<String, Object?>) {
      for (final MapEntry(:key, :value) in node.entries.toList()) {
        if (key == 'parser' && value is String) {
          node[key] = icu(key, value);
        } else if (key == 'displayFormats' && value is Map<String, Object?>) {
          for (final MapEntry(key: unit, value: format)
              in value.entries.toList()) {
            if (format is String) value[unit] = icu('$key.$unit', format);
          }
        } else {
          walk(value);
        }
      }
    } else if (node is List<Object?>) {
      node.forEach(walk);
    }
  }

  walk(config);
  if (count == 0) {
    throw StateError('the config has no moment pattern: it needs no twin.');
  }
  return config;
}

/// The prefix of [specsFromFixtures] that matches exactly [paths].
///
/// fixture.js:74 builds the regular expression `^<prefix>.+\.(json|js)$`.
/// A lookahead at the start keeps only the paths of the list.
String _exactly(Iterable<String> paths) =>
    '(?=(?:${paths.map(RegExp.escape).join('|')})\$)';

void main() {
  const source = FixtureSource();
  final items = {for (final item in source.items) item.path: item};

  // Each twin is a hand entry of the runner. Thus it has the checks of
  // Chart.js ADR 0029, section 3 item 5 and section 11: the SHA-256 of the
  // upstream file, the skip without the checkout, and the failure with
  // FIXTURES_REQUIRED=1. The runner throws a StateError for a path that is
  // not a fixture of the manifest.
  // The run hook of each twin examines the parsed values and the ticks of
  // its time scales (_examine).
  group(
    'adapt-date-moment-format',
    specsFromFixtures(
      _exactly(_twins),
      hand: {
        for (final path in _twins)
          path: (
            load: () => _load(source, path),
            sha256: items[path]?.sha256.substring(0, 12) ?? '',
          ),
      },
    ),
  );

  // Not tagged: the default run examines the list.
  group('twins', () {
    test('the twins are the pure data configs of the moment skips', () {
      final skipped = [
        for (final item in source.items)
          if (item.data && fixtureSkips[item.path] == _reason) item.path,
      ];
      expect(_twins, skipped);
    });

    test('_unparsed and _differs name only twins', () {
      expect(_twins, containsAll(_unparsed.keys));
      expect(_unparsed.keys, containsAll(_differs));
    });

    test('the twins match exactly the paths of the list', () {
      final regex = RegExp('^${_exactly(_twins)}.+\\.(json|js)\$');
      expect(
        [
          for (final item in source.items)
            if (regex.hasMatch(item.path)) item.path,
        ],
        _twins,
      );
    });

    test('_toIcu changes each moment pattern and keeps the Map', () {
      final config = <String, Object?>{
        'options': <String, Object?>{
          'scales': <String, Object?>{
            'x': <String, Object?>{
              'time': <String, Object?>{
                'parser': 'YYYY-MM',
                'displayFormats': <String, Object?>{'year': 'YYYY'},
              },
            },
          },
        },
        'data': <String, Object?>{
          'datasets': <Object?>[
            <String, Object?>{
              'parser': 'YYYY',
              'data': <Object?>['2017'],
            },
          ],
        },
      };
      expect(identical(_toIcu(config), config), isTrue);
      expect(config, {
        'options': {
          'scales': {
            'x': {
              'time': {
                'parser': 'yyyy-MM',
                'displayFormats': {'year': 'yyyy'},
              },
            },
          },
        },
        'data': {
          'datasets': [
            {
              'parser': 'yyyy',
              'data': ['2017'],
            },
          ],
        },
      });
    });

    test('_toIcu throws for another pattern and for no pattern', () {
      expect(
        () => _toIcu({'parser': 'MMM D'}),
        throwsA(isA<StateError>()),
      );
      expect(
        () => _toIcu({
          'displayFormats': <String, Object?>{'day': 'HH:mm'},
        }),
        throwsA(isA<StateError>()),
      );
      expect(() => _toIcu({'type': 'line'}), throwsA(isA<StateError>()));
    });
  });
}
