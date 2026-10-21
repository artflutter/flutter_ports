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
import 'package:flutter_chartjs/src/controllers/controller.bar.dart';
import 'package:flutter_chartjs/src/controllers/controller.line.dart';
import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/elements/element.bar.dart';
import 'package:flutter_chartjs/src/elements/element.line.dart';
import 'package:flutter_chartjs/src/elements/element.point.dart';
import 'package:flutter_chartjs/src/scales/scale.category.dart';
import 'package:flutter_chartjs/src/scales/scale.linear.dart';
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
Map<String, Object?> _config([Map<String, Object?> extra = const {}]) =>
    <String, Object?>{
      'type': 'bar',
      'data': <String, Object?>{
        'labels': <Object?>['a', 'b'],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[1, 2],
          },
        ],
      },
      ...extra,
    };

/// A hand fixture with [config] and the [run] hook.
Map<String, Object?> _fixture(
  Map<String, Object?> config, [
  Function? run,
]) => <String, Object?>{
  'config': config,
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 64, 'width': 64},
    'run': ?run,
  },
};

Map<String, Object?> _options(Map<String, Object?> config) =>
    config['options']! as Map<String, Object?>;

Map<String, Object?> _ruleNone() {
  final config = _config();
  return _fixture(config, (Chart chart) {
    expect(_options(config)['plugins'], isFalse);
  });
}

Map<String, Object?> _ruleInstance() {
  final config = _config({'plugins': <Object?>[]});
  return _fixture(config, (Chart chart) {
    // The runner did not write false. initOptions of the config wrote
    // `{}` (core.config.js:118).
    expect(_options(config)['plugins'], <String, Object?>{});
  });
}

final Map<String, Object?> _pluginOptions = <String, Object?>{
  'legend': false,
};

Map<String, Object?> _ruleObject() {
  final config = _config({
    'options': <String, Object?>{'plugins': _pluginOptions},
  });
  return _fixture(config, (Chart chart) {
    expect(identical(_options(config)['plugins'], _pluginOptions), isTrue);
  });
}

Map<String, Object?> _pluginPath() {
  final config = _config();
  return _fixture(config, (Chart chart) {
    // The runner did not write false. initOptions of the config wrote
    // `{}` (core.config.js:118).
    expect(_options(config)['plugins'], <String, Object?>{});
  });
}

Chart? _thrown;
bool _futureSettled = false;

Map<String, Object?> _runSync() => _fixture(_config(), (Chart chart) {
  expect(chart.attached, isTrue);
  expect(chart.canvas, isNotNull);
});

Map<String, Object?> _runFuture() => _fixture(_config(), (Chart chart) {
  final completer = Completer<void>();
  setTimeout(() {
    _futureSettled = true;
    completer.complete();
  }, 100);
  return completer.future;
});

Map<String, Object?> _runNever() =>
    _fixture(_config(), (Chart chart) => Completer<void>().future);

Map<String, Object?> _runThrows() => _fixture(_config(), (Chart chart) {
  _thrown = chart;
  throw StateError('probe sync error');
});

Map<String, Object?> _runAsyncThrows() =>
    _fixture(_config(), (Chart chart) async {
      await Future<void>.value();
      throw StateError('probe async error');
    });

Map<String, Object?> _both() => _fixture(_config());

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
    <String, Object?>{'id': 'probe'},
  ]);

  group('probe', () {
    group('prefix time', specsFromFixtures('scale.time', source: _source));
    group('prefix dot', specsFromFixtures('a.b', source: _source));
    group('prefix rest', specsFromFixtures('edge/x', source: _source));
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
    group('png', specsFromFixtures('png/', source: _source));
    group(
      'sources',
      specsFromFixtures('source/', hand: _hand, skips: _skips, source: _source),
    );
    group('upstream', specsFromFixtures('upstream/', source: _source));
    group('crlf', specsFromFixtures('crlf/', source: _crlf));
    group(
      'no checkout',
      specsFromFixtures('aXb', source: _noCheckout(required: false)),
    );
    group(
      'no checkout required',
      specsFromFixtures('aXb', source: _noCheckout(required: true)),
    );
    group('no checkout env', specsFromFixtures('aXb', source: _noCheckout()));
    test('untagged', () {});
  });
}
