// Original code, not ported from chartjs-plugin-zoom: the registry of the hand-ported fixture configs.
// The header text is longer than 80 columns and has no URI.
// ignore_for_file: lines_longer_than_80_chars

/// `jasmine.fixture` of `test/index.js:17-19` (seam H24, Zoom ADR 0002).
///
/// `test/specs/fixtures_test.dart` imports this file with the prefix
/// `fixture` and calls `group('zoom', fixture.specs('zoom'))` and
/// `group('pan', fixture.specs('pan'))`, as `fixtures.spec.js:2-3`. This
/// file is not a test entry: it has no `_test.dart` suffix and no `@TestOn`.
///
/// The runner is `specsFromFixtures` of the host harness (Chart.js ADR
/// 0029) with the [FixtureSource] of this package: the manifest
/// `test/fixtures/manifest.json` (written by
/// `tool/reference/fixtures_reference.mjs`) and the upstream fixture files
/// of `third_party/chartjs-plugin-zoom/test/fixtures/`. The runner checks
/// the SHA-256 of each upstream file against the manifest and the 12 hex
/// digits of each hand port, skips each fixture without the checkout (fails
/// with `FIXTURES_REQUIRED=1`) and tags each test `fixtures`.
///
/// Each config of the 12 fixtures runs code, so each is a hand port of
/// `hand/<path>.dart`. [handFixtures] wraps its `run` hook: the hook starts
/// the observations of `observe.dart`, the hand port records one at each
/// draw of the chart into its sprite canvas, and the wrapper adds one after
/// `run` and compares the list with `fixtures_reference.dart`, the
/// observations of the pinned sources in Node.js (row
/// `harness-fixture-observations`). The runner compares no image.
library;

import 'package:chartjs_test_utils/flutter.dart'
    show FixtureLoad, FixtureSource, HandFixture, specsFromFixtures;
import 'package:flutter_chartjs_port/chartjs.dart' show Chart;
import 'package:flutter_test/flutter_test.dart';

import 'fixtures_reference.dart';
import 'hand/pan/category-x-1.dart' as pan_category_x_1;
import 'hand/pan/category-x-10.dart' as pan_category_x_10;
import 'hand/pan/category-x-25.dart' as pan_category_x_25;
import 'hand/pan/category-x-5.dart' as pan_category_x_5;
import 'hand/pan/category-x-50.dart' as pan_category_x_50;
import 'hand/pan/time-day-left.dart' as pan_time_day_left;
import 'hand/pan/time-day-right.dart' as pan_time_day_right;
import 'hand/zoom/category-x.dart' as zoom_category_x;
import 'hand/zoom/drag.dart' as zoom_drag;
import 'hand/zoom/dragDrawTime.dart' as zoom_dragdrawtime;
import 'hand/zoom/update-reset.dart' as zoom_update_reset;
import 'hand/zoom/zoom-reset.dart' as zoom_zoom_reset;
import 'observe.dart';

/// The fixture files of this package. The manifest has no pure data
/// config, so the runner reads no data file.
const FixtureSource zoomFixtureSource = FixtureSource(
  manifest: 'test/fixtures/manifest.json',
  upstream: '../../third_party/chartjs-plugin-zoom/test/fixtures',
  submodule: 'third_party/chartjs-plugin-zoom',
);

/// `jasmine.fixture.specs(path)` of `test/index.js:17-19`.
void Function() specs(String path) =>
    specsFromFixtures(path, hand: handFixtures, source: zoomFixtureSource);

/// The hand-ported configs by fixture path.
///
/// Each entry maps the path relative to `test/fixtures/` to the `fixture`
/// function of `hand/<path>.dart`, with the observations of [_observed], and
/// the first 12 hex digits of the `sha256` of the upstream file in
/// `test/fixtures/manifest.json`.
final Map<String, HandFixture> handFixtures = {
  'pan/category-x-1.js': _observed(
    'pan/category-x-1.js',
    pan_category_x_1.fixture,
    '5571fc555872',
  ),
  'pan/category-x-10.js': _observed(
    'pan/category-x-10.js',
    pan_category_x_10.fixture,
    'cf1b969e03ad',
  ),
  'pan/category-x-25.js': _observed(
    'pan/category-x-25.js',
    pan_category_x_25.fixture,
    '6af636891640',
  ),
  'pan/category-x-5.js': _observed(
    'pan/category-x-5.js',
    pan_category_x_5.fixture,
    'f516efec65c1',
  ),
  'pan/category-x-50.js': _observed(
    'pan/category-x-50.js',
    pan_category_x_50.fixture,
    '5fba1615e29a',
  ),
  'pan/time-day-left.js': _observed(
    'pan/time-day-left.js',
    pan_time_day_left.fixture,
    'fb37420f625f',
  ),
  'pan/time-day-right.js': _observed(
    'pan/time-day-right.js',
    pan_time_day_right.fixture,
    '9f3cc86f4ad3',
  ),
  'zoom/category-x.js': _observed(
    'zoom/category-x.js',
    zoom_category_x.fixture,
    '2b2771ff25df',
  ),
  'zoom/drag.js': _observed('zoom/drag.js', zoom_drag.fixture, 'b91a7443f734'),
  'zoom/dragDrawTime.js': _observed(
    'zoom/dragDrawTime.js',
    zoom_dragdrawtime.fixture,
    '1b692b834cdf',
  ),
  'zoom/update-reset.js': _observed(
    'zoom/update-reset.js',
    zoom_update_reset.fixture,
    'd2b4b90107eb',
  ),
  'zoom/zoom-reset.js': _observed(
    'zoom/zoom-reset.js',
    zoom_zoom_reset.fixture,
    'c11fd080f8bc',
  ),
};

/// The hand port [load] of [path], with its `run` hook wrapped: the
/// observations of the run, and their compare with [fixturesReference].
// DIVERGES(zoom): harness-fixture-observations, the observed run hook.
HandFixture _observed(String path, FixtureLoad load, String sha256) => (
  load: () {
    final json = load();
    final options = json['options']! as Map<String, Object?>;
    final run = options['run']! as Object? Function(Chart);
    Object? observedRun(Chart chart) {
      final observations = startObservations(chart);
      void finish() {
        observations.add(observe(chart));
        endObservations();
        _compare(path, observations);
      }

      final result = run(chart);
      if (result is Future<Object?>) return result.then<void>((_) => finish());
      finish();
      return null;
    }

    options['run'] = observedRun;
    return json;
  },
  sha256: sha256,
);

/// Compares the [observations] of [path] with [fixturesReference], one
/// observation at a time.
void _compare(String path, List<Object?> observations) {
  final expected = fixturesReference[path];
  if (expected == null) {
    fail(
      '$path has no reference data: run '
      'tool/reference/fixtures_reference.mjs.',
    );
  }
  for (var i = 0; i < observations.length && i < expected.length; i++) {
    expect(
      observations[i],
      equals(expected[i]),
      reason: '$path: observation $i of ${expected.length}',
    );
  }
  expect(
    observations,
    hasLength(expected.length),
    reason: '$path: the count of the observations',
  );
}
