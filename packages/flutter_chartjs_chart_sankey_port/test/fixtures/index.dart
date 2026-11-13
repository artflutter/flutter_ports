// Original code, not ported from chartjs-chart-sankey: the registry of the hand-ported fixture configs.
// The header text is longer than 80 columns and has no URI.
// ignore_for_file: lines_longer_than_80_chars

/// The fixtures of `test/utils/fixtures.js` (Sankey ADR 0002).
///
/// `test/specs/fixtures_test.dart` imports this file with the prefix
/// `fixture` and calls `group('fixtures', fixture.specs())`, as
/// `fixtures.spec.js:5`. This file is not a test entry: it has no
/// `_test.dart` suffix and no `@TestOn`.
///
/// The runner is `specsFromFixtures` of the host harness (Chart.js ADR
/// 0029) with the [FixtureSource] of this package: the manifest
/// `test/fixtures/manifest.json` (written by
/// `tool/reference/fixtures_reference.mjs`) and the upstream fixture files
/// of `third_party/chartjs-chart-sankey/test/fixtures/`. The runner checks
/// the SHA-256 of each upstream file against the manifest and the 12 hex
/// digits of each hand port, skips each fixture without the checkout (fails
/// with `FIXTURES_REQUIRED=1`) and tags each test `fixtures`. It makes the
/// chart as `buildChart` of `test/utils/chart.js:30-60` and `prepareConfig`
/// of `test/utils/fixtures.js:52-60` do: the canvas of `options.canvas`,
/// no animation, not responsive, and no plugin.
///
/// Each config of the 44 fixtures is an ES module, so each is a hand port
/// of `hand/<path>.dart`. [handFixtures] wraps its `run` hook: the wrapper
/// runs the hook of the fixture, records the observation of `observe.dart`
/// (the chart area, the nodes, the flows, and the rectangles, the texts and
/// the fills of one draw with their colors) and compares it with
/// `fixtures_reference.dart`, the observation of the pinned sources in
/// Node.js (row `harness-fixture-observations`). The runner compares no
/// image.
library;

import 'package:chartjs_test_utils/flutter.dart'
    show FixtureLoad, FixtureSource, HandFixture, specsFromFixtures;
import 'package:flutter_chartjs_port/chartjs.dart' show Chart;
import 'package:flutter_test/flutter_test.dart';

import 'fixtures_reference.dart';
import 'hand/basic-y-0.dart' as basic_y_0;
import 'hand/basic.dart' as basic;
import 'hand/border.dart' as border;
import 'hand/cash.dart' as cash;
import 'hand/color-mode-from.dart' as color_mode_from;
import 'hand/color-mode-gradient.dart' as color_mode_gradient;
import 'hand/color-mode-to.dart' as color_mode_to;
import 'hand/column.dart' as column;
import 'hand/energy.dart' as energy;
import 'hand/energy2.dart' as energy2;
import 'hand/issues/discussion108.dart' as issues_discussion108;
import 'hand/issues/issue102.dart' as issues_issue102;
import 'hand/issues/issue102b.dart' as issues_issue102b;
import 'hand/issues/issue106.dart' as issues_issue106;
import 'hand/issues/issue13.dart' as issues_issue13;
import 'hand/issues/issue146.dart' as issues_issue146;
import 'hand/issues/issue25.dart' as issues_issue25;
import 'hand/issues/issue45.dart' as issues_issue45;
import 'hand/issues/issue45b.dart' as issues_issue45b;
import 'hand/issues/issue45c.dart' as issues_issue45c;
import 'hand/issues/issue57.dart' as issues_issue57;
import 'hand/issues/issue57b.dart' as issues_issue57b;
import 'hand/issues/issue61.dart' as issues_issue61;
import 'hand/issues/issue72.dart' as issues_issue72;
import 'hand/issues/issue81.dart' as issues_issue81;
import 'hand/issues/issue82.dart' as issues_issue82;
import 'hand/issues/issue88.dart' as issues_issue88;
import 'hand/issues/issue99.dart' as issues_issue99;
import 'hand/issues/multiple-flows.dart' as issues_multiple_flows;
import 'hand/labels-multiline-padding.dart' as labels_multiline_padding;
import 'hand/labels-multiline.dart' as labels_multiline;
import 'hand/labels.dart' as labels;
import 'hand/no-border.dart' as no_border;
import 'hand/no-offset.dart' as no_offset;
import 'hand/node-min-size.dart' as node_min_size;
import 'hand/node-padding-even.dart' as node_padding_even;
import 'hand/node-padding-per-node.dart' as node_padding_per_node;
import 'hand/nodePadding.dart' as nodepadding;
import 'hand/nodeWidth.dart' as nodewidth;
import 'hand/parsing.dart' as parsing;
import 'hand/priority.dart' as priority;
import 'hand/readme.dart' as readme;
import 'hand/size-max.dart' as size_max;
import 'hand/size-min.dart' as size_min;
import 'observe.dart';

/// The fixture files of this package. The manifest has no pure data
/// config, so the runner reads no data file.
const FixtureSource sankeyFixtureSource = FixtureSource(
  manifest: 'test/fixtures/manifest.json',
  upstream: '../../third_party/chartjs-chart-sankey/test/fixtures',
  submodule: 'third_party/chartjs-chart-sankey',
);

/// The fixtures that do not run, by fixture path, each with its reason. No
/// skip covers a defect.
const Map<String, String> fixtureSkips = {};

/// `specsFromFixtures(path)` of `test/utils/fixtures.js:120-134`. The
/// default `''` is each fixture.
void Function() specs([String path = '']) => specsFromFixtures(
  path,
  hand: handFixtures,
  // The Map is empty and const, as the default: the analyzer reports the
  // argument while no fixture skips.
  // ignore: avoid_redundant_argument_values
  skips: fixtureSkips,
  source: sankeyFixtureSource,
);

/// The largest difference between a number of an observation and its
/// reference number, in pixels or in flow units.
///
/// Both sides compute the layout with the same double operations (`+`, `-`,
/// `*`, `/`, `min`, `max` and `abs`), and each label measures in Liberation
/// Sans on both sides. At the pin, each number of the 44 fixtures equals
/// its reference number: the run also passes with the tolerance 0. The
/// tolerance keeps a change of the last bit of a pixel from failing a
/// fixture (Chart.js ADR 0034).
const double fixtureTolerance = 1e-9;

/// The hand-ported configs by fixture path.
///
/// Each entry maps the path relative to `test/fixtures/` to the `fixture`
/// function of `hand/<path>.dart`, with the observation of [_observed], and
/// the first 12 hex digits of the `sha256` of the upstream file in
/// `test/fixtures/manifest.json`.
final Map<String, HandFixture> handFixtures = {
  'basic-y-0.js': _observed('basic-y-0.js', basic_y_0.fixture, 'f4c965bdfb3c'),
  'basic.js': _observed('basic.js', basic.fixture, '47a0de9d348f'),
  'border.js': _observed('border.js', border.fixture, 'f0a715ab3426'),
  'cash.js': _observed('cash.js', cash.fixture, '97593fb6eff6'),
  'color-mode-from.js': _observed(
    'color-mode-from.js',
    color_mode_from.fixture,
    '91b00e096b0c',
  ),
  'color-mode-gradient.js': _observed(
    'color-mode-gradient.js',
    color_mode_gradient.fixture,
    'aedf4dd886c2',
  ),
  'color-mode-to.js': _observed(
    'color-mode-to.js',
    color_mode_to.fixture,
    'd32dbc236ba1',
  ),
  'column.js': _observed('column.js', column.fixture, '7ecec8bf9821'),
  'energy.js': _observed('energy.js', energy.fixture, 'b15174d4e386'),
  'energy2.js': _observed('energy2.js', energy2.fixture, 'e4c90e6e33c6'),
  'issues/discussion108.js': _observed(
    'issues/discussion108.js',
    issues_discussion108.fixture,
    'c54d3d73ada1',
  ),
  'issues/issue102.js': _observed(
    'issues/issue102.js',
    issues_issue102.fixture,
    '15ff2a2ad86f',
  ),
  'issues/issue102b.js': _observed(
    'issues/issue102b.js',
    issues_issue102b.fixture,
    'c2adce088c3e',
  ),
  'issues/issue106.js': _observed(
    'issues/issue106.js',
    issues_issue106.fixture,
    '9150ee8b689f',
  ),
  'issues/issue13.js': _observed(
    'issues/issue13.js',
    issues_issue13.fixture,
    'f35e22d762a3',
  ),
  'issues/issue146.js': _observed(
    'issues/issue146.js',
    issues_issue146.fixture,
    'fe913e8c6e44',
  ),
  'issues/issue25.js': _observed(
    'issues/issue25.js',
    issues_issue25.fixture,
    'c6c006c0fa21',
  ),
  'issues/issue45.js': _observed(
    'issues/issue45.js',
    issues_issue45.fixture,
    'dd5c4d2cd3ce',
  ),
  'issues/issue45b.js': _observed(
    'issues/issue45b.js',
    issues_issue45b.fixture,
    '7aff87867f64',
  ),
  'issues/issue45c.js': _observed(
    'issues/issue45c.js',
    issues_issue45c.fixture,
    '358b72eb7272',
  ),
  'issues/issue57.js': _observed(
    'issues/issue57.js',
    issues_issue57.fixture,
    'da9d7fa1b20a',
  ),
  'issues/issue57b.js': _observed(
    'issues/issue57b.js',
    issues_issue57b.fixture,
    'cb3d31ebff6c',
  ),
  'issues/issue61.js': _observed(
    'issues/issue61.js',
    issues_issue61.fixture,
    '70b956ac73fa',
  ),
  'issues/issue72.js': _observed(
    'issues/issue72.js',
    issues_issue72.fixture,
    '1558c49c368d',
  ),
  'issues/issue81.js': _observed(
    'issues/issue81.js',
    issues_issue81.fixture,
    '30892963f5a6',
  ),
  'issues/issue82.js': _observed(
    'issues/issue82.js',
    issues_issue82.fixture,
    '9cf4f204efba',
  ),
  'issues/issue88.js': _observed(
    'issues/issue88.js',
    issues_issue88.fixture,
    '55d8900f3db8',
  ),
  'issues/issue99.js': _observed(
    'issues/issue99.js',
    issues_issue99.fixture,
    '5bbc94ae6dcf',
  ),
  'issues/multiple-flows.js': _observed(
    'issues/multiple-flows.js',
    issues_multiple_flows.fixture,
    '2cd98f486393',
  ),
  'labels-multiline-padding.js': _observed(
    'labels-multiline-padding.js',
    labels_multiline_padding.fixture,
    '401a945e83b4',
  ),
  'labels-multiline.js': _observed(
    'labels-multiline.js',
    labels_multiline.fixture,
    '307887db6c41',
  ),
  'labels.js': _observed('labels.js', labels.fixture, 'cb2690663b13'),
  'no-border.js': _observed('no-border.js', no_border.fixture, '2f0517b97b3d'),
  'no-offset.js': _observed('no-offset.js', no_offset.fixture, '1a05f8e6d3c5'),
  'node-min-size.js': _observed(
    'node-min-size.js',
    node_min_size.fixture,
    'e95c92101f3f',
  ),
  'node-padding-even.js': _observed(
    'node-padding-even.js',
    node_padding_even.fixture,
    '30562ce999bb',
  ),
  'node-padding-per-node.js': _observed(
    'node-padding-per-node.js',
    node_padding_per_node.fixture,
    '146ff251d416',
  ),
  'nodePadding.js': _observed(
    'nodePadding.js',
    nodepadding.fixture,
    '748a19672afe',
  ),
  'nodeWidth.js': _observed('nodeWidth.js', nodewidth.fixture, 'f2ecb5b21123'),
  'parsing.js': _observed('parsing.js', parsing.fixture, '6c317423023d'),
  'priority.js': _observed('priority.js', priority.fixture, 'e0284656da73'),
  'readme.js': _observed('readme.js', readme.fixture, '60b132c37d9c'),
  'size-max.js': _observed('size-max.js', size_max.fixture, 'b2b5731d2c55'),
  'size-min.js': _observed('size-min.js', size_min.fixture, '6466509d447d'),
};

/// The hand port [load] of [path], with its `run` hook wrapped: the hook of
/// the fixture, then the observation of the chart and its compare with
/// [fixturesReference].
// DIVERGES(sankey): harness-fixture-observations, the observed run hook.
HandFixture _observed(String path, FixtureLoad load, String sha256) => (
  load: () {
    final json = load();
    final options =
        (json['options'] ??= <String, Object?>{}) as Map<String, Object?>;
    final run = options['run'] as Object? Function(Chart)?;
    Object? observedRun(Chart chart) {
      void finish() => _compare(path, observe(chart));

      final result = run?.call(chart);
      if (result is Future<Object?>) return result.then<void>((_) => finish());
      finish();
      return null;
    }

    options['run'] = observedRun;
    return json;
  },
  sha256: sha256,
);

/// Compares the observation [actual] of [path] with [fixturesReference].
/// Two numbers are equal within [fixtureTolerance]; any other value
/// compares with `==`.
void _compare(String path, Map<String, Object?> actual) {
  final expected = fixturesReference[path];
  if (expected == null) {
    fail(
      '$path has no reference data: run '
      'tool/reference/fixtures_reference.mjs.',
    );
  }
  final differences = <String>[];
  _differences(expected, actual, '', differences);
  if (differences.isNotEmpty) {
    const shown = 40;
    fail(
      '$path: ${differences.length} differences from the reference '
      '(expected, then actual):\n'
      '${differences.take(shown).join('\n')}'
      '${differences.length > shown ? '\n...' : ''}',
    );
  }
}

/// Adds to [out] one line for each difference between [expected] and
/// [actual], the values at [where] of an observation.
void _differences(
  Object? expected,
  Object? actual,
  String where,
  List<String> out,
) {
  switch ((expected, actual)) {
    case (final num e, final num a):
      final equal =
          e == a || (e.isNaN && a.isNaN) || (e - a).abs() <= fixtureTolerance;
      if (!equal) out.add('$where: $e, $a (difference ${(e - a).abs()})');
    case (final List<Object?> e, final List<Object?> a):
      if (e.length != a.length) {
        out.add('$where: ${e.length} items, ${a.length} items');
      }
      for (var i = 0; i < e.length && i < a.length; i++) {
        // The first item of a node or of a draw call names it.
        final name = switch (e[i]) {
          [final String name, ...] => ' $name',
          _ => '',
        };
        _differences(e[i], a[i], '$where[$i$name]', out);
      }
    case (final Map<String, Object?> e, final Map<String, Object?> a):
      for (final key in {...e.keys, ...a.keys}) {
        if (!e.containsKey(key) || !a.containsKey(key)) {
          out.add('$where$key: only one side has the key');
        } else {
          _differences(e[key], a[key], '$where$key', out);
        }
      }
    default:
      if (expected != actual) out.add('$where: $expected, $actual');
  }
}
