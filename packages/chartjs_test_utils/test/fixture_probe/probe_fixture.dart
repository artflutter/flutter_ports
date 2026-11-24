// Original code, not ported from Chart.js: the probe of the fixture runner.
@TestOn('vm')
library;

// This file has no `_test.dart` suffix: a run of the folder `test/` does not
// pick it. `test/fixture_test.dart` runs it with
// `flutter test --tags fixtures --reporter json` and the environment
// `FIXTURES_REQUIRED=1`, and reads the events (Chart.js ADR 0029, probe
// E10). `manifest.json` and `fixtures.json` have the form of tool 4. The
// folder `upstream/` stands for `third_party/Chart.js/test/fixtures`: its
// files have no line end, so the SHA-256 does not depend on the checkout.
// The upstream file of the group `crlf` has CRLF line ends. Git writes no
// CRLF into a file of this repository. Thus `test/fixture_test.dart` writes
// it into a temporary directory and gives the path in the environment
// variable `FIXTURE_PROBE_CRLF`.

import 'dart:async';
import 'dart:io';

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

const String _folder = 'test/fixture_probe';

const FixtureSource _source = FixtureSource(
  manifest: '$_folder/manifest.json',
  data: '$_folder/fixtures.json',
  upstream: '$_folder/upstream',
);

/// A source without the upstream files.
FixtureSource _noCheckout({bool? required}) => FixtureSource(
  manifest: '$_folder/manifest.json',
  data: '$_folder/fixtures.json',
  upstream: '$_folder/no-checkout',
  requireUpstream: required,
);

/// A bar chart of 64 x 64 pixels.
ChartConfig _config({
  List<PluginOptions<Object?>>? pluginOptions,
  List<Plugin<Object?>>? plugins,
}) => ChartConfig(
  labels: const <Object>['a', 'b'],
  datasets: const [
    BarDataset(data: .values(<num?>[1, 2])),
  ],
  pluginOptions: pluginOptions,
  plugins: plugins,
);

/// The options of a chart of 64 x 64 pixels.
const AcquireOptions _options = AcquireOptions(
  canvas: HarnessCanvas(width: 64, height: 64),
);

/// A fixture with [config] and the [run] hook.
FixtureConfig _fixture(ChartConfig config, [FixtureRun? run]) =>
    FixtureConfig.typed(config, options: _options, run: run);

/// The options object of the config of [chart]: the root scope of its
/// typed config.
Object? _plugins(Chart chart) => jsGet(chart.config.options, 'plugins');

FixtureConfig _ruleNone() => _fixture(_config(), (chart) {
  expect(_plugins(chart), isFalse);
});

FixtureConfig _ruleInstance() =>
    _fixture(_config(plugins: <Plugin<Object?>>[]), (chart) {
      // The runner did not write false. initOptions of the config wrote
      // `{}` (core.config.js:118).
      expect(_plugins(chart), isNot(isFalse));
      expect(jsObjectKeys(_plugins(chart)), isEmpty);
    });

const LegendOptions _legend = LegendOptions(display: false);

FixtureConfig _ruleObject() =>
    _fixture(_config(pluginOptions: [_legend]), (chart) {
      // The object of the options stays.
      expect(jsObjectKeys(_plugins(chart)), ['legend']);
      expect(identical(jsGet(_plugins(chart), 'legend'), _legend), isTrue);
    });

FixtureConfig _pluginPath() => _fixture(_config(), (chart) {
  // The runner did not write false. initOptions of the config wrote
  // `{}` (core.config.js:118).
  expect(_plugins(chart), isNot(isFalse));
  expect(jsObjectKeys(_plugins(chart)), isEmpty);
});

Chart? _thrown;
bool _futureSettled = false;

FixtureConfig _runSync() => _fixture(_config(), (chart) {
  expect(chart.attached, isTrue);
  expect(chart.canvas, isNotNull);
});

FixtureConfig _runFuture() => _fixture(_config(), (chart) {
  final completer = Completer<void>();
  setTimeout(() {
    _futureSettled = true;
    completer.complete();
  }, 100);
  return completer.future;
});

FixtureConfig _runNever() =>
    _fixture(_config(), (chart) => Completer<void>().future);

FixtureConfig _runThrows() => _fixture(_config(), (chart) {
  _thrown = chart;
  throw StateError('probe sync error');
});

FixtureConfig _runAsyncThrows() => _fixture(_config(), (chart) async {
  await Future<void>.value();
  throw StateError('probe async error');
});

FixtureConfig _both() => _fixture(_config());

/// A config of `fixtures.json` that a ChartConfig cannot hold: no dataset.
FixtureConfig _noDataset() => FixtureConfig.map(<String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>['a', 'b'],
    'datasets': <Object?>[],
  },
}, options: _options);

/// A source whose upstream file `crlf/lines.json` has CRLF line ends, as a
/// checkout with `core.autocrlf=true` writes it. The manifest has the
/// SHA-256 of the LF form.
final FixtureSource _crlf = FixtureSource(
  manifest: '$_folder/manifest.json',
  data: '$_folder/fixtures.json',
  upstream: Platform.environment['FIXTURE_PROBE_CRLF'] ?? '$_folder/no-crlf',
);

const Map<String, String> _skips = {
  'source/skip.json': 'n/a: probe',
  'source/stale-skip.json': 'blocked: plugin.probe',
  'source/blocked.json': 'blocked: plugin.absent',
};

/// The generated configs of the pure data fixtures of `fixtures.json`
/// (Chart.js ADR 0199). The config of `source/both.json` throws: the hand
/// entry wins over it.
final Map<String, HandFixture> _data = {
  'scale.timeseries/a.json': (load: _both, sha256: 'e8f1f6e960d6'),
  'aXb/c.json': (load: _both, sha256: 'ac6400fa34ec'),
  'edge/xy.json': (load: _noDataset, sha256: 'e002adcf97f4'),
  'png/none.json': (load: _both, sha256: '6ea560d1be7c'),
  'source/both.json': (
    load: () => throw StateError('the data config of source/both.json'),
    sha256: '2962075a1175',
  ),
  'upstream/changed.json': (load: _both, sha256: '000000000000'),
  'upstream/missing.json': (load: _both, sha256: '3684e16651a1'),
  'crlf/lines.json': (load: _both, sha256: '7bdce19a0592'),
};

final Map<String, HandFixture> _hand = {
  'rule/none.js': (load: _ruleNone, sha256: 'eb4974ea86ff'),
  'rule/instance.js': (load: _ruleInstance, sha256: '09160988e285'),
  'rule/object.js': (load: _ruleObject, sha256: '7a57ebf3a407'),
  'plugin.x/keep.js': (load: _pluginPath, sha256: 'cdd6b374ec6f'),
  'run/sync.js': (load: _runSync, sha256: '65ae9e676a7a'),
  'run/future.js': (load: _runFuture, sha256: '9d27c1b420ba'),
  'run/never.js': (load: _runNever, sha256: 'd4f487782f25'),
  'run/throws.js': (load: _runThrows, sha256: '31b3dfa8f711'),
  'run/async-throws.js': (load: _runAsyncThrows, sha256: '0162c2ffb018'),
  'source/both.json': (load: _both, sha256: '2962075a1175'),
  'source/stale.js': (load: _both, sha256: '000000000000'),
};

void main() {
  Chart.register([
    BarController.jsClass,
    LineController.jsClass,
    CategoryScale.jsClass,
    LinearScale.jsClass,
    PointElement.jsClass,
    LineElement.jsClass,
    BarElement.jsClass,
    // A plugin for the stale skip of `source/stale-skip.json`.
    Plugin<Object?>(id: 'probe'),
  ]);

  group('probe', () {
    group(
      'prefix time',
      specsFromFixtures('scale.time', data: _data, source: _source),
    );
    group('prefix dot', specsFromFixtures('a.b', data: _data, source: _source));
    group(
      'prefix rest',
      specsFromFixtures('edge/x', data: _data, source: _source),
    );
    group('rule', specsFromFixtures('rule/', hand: _hand, source: _source));
    group(
      'plugin path',
      specsFromFixtures('plugin.x/', hand: _hand, source: _source),
    );
    group('run', specsFromFixtures('run/', hand: _hand, source: _source));
    test('the Future of the hook settled', () {
      expect(_futureSettled, isTrue);
    }, tags: fixturesTag);
    test('the chart of the hook that throws is released', () {
      expect(_thrown, isNotNull);
      expect(_thrown!.canvas, isNull);
      expect(Chart.instances.values, isNot(contains(_thrown)));
    }, tags: fixturesTag);
    group('png', specsFromFixtures('png/', data: _data, source: _source));
    group(
      'sources',
      specsFromFixtures(
        'source/',
        hand: _hand,
        data: _data,
        skips: _skips,
        source: _source,
      ),
    );
    group(
      'upstream',
      specsFromFixtures('upstream/', data: _data, source: _source),
    );
    group('crlf', specsFromFixtures('crlf/', data: _data, source: _crlf));
    group(
      'no checkout',
      specsFromFixtures(
        'aXb',
        data: _data,
        source: _noCheckout(required: false),
      ),
    );
    group(
      'no checkout required',
      specsFromFixtures(
        'aXb',
        data: _data,
        source: _noCheckout(required: true),
      ),
    );
    group(
      'no checkout env',
      specsFromFixtures('aXb', data: _data, source: _noCheckout()),
    );
    test('untagged', () {});
  });
}
