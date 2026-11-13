// Original code, not ported from Chart.js: the data-only report of apply.
@TestOn('vm')
library;

import 'dart:ui' show Color, Locale;

import 'package:flutter/widgets.dart' show EdgeInsets, ValueKey;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_chartjs_port/src/typed/lower.dart'
    show ChartConfigLowering;
import 'package:flutter_test/flutter_test.dart';

// Chart.js ADR 0098: `ChartConfigLowering.apply` reports a new config that
// changed only dataset data Lists. Each case applies [next] over a lowering of
// [first] and reads the report.

const Color _red = Color(0xFFFF0000);
const Color _green = Color(0xFF00FF00);
const Color _blue = Color(0xFF0000FF);

const ValueKey<String> _a = ValueKey('a');
const ValueKey<String> _b = ValueKey('b');

final List<Object> _labels = <Object>['x', 'y'];

List<double> _data([int count = 2]) =>
    List<double>.generate(count, (i) => i + 1.0);

/// Lists that are not `const`: two configs get two Lists with equal items.
final List<Color> _pair = <Color>[_red, _green];
final List<double> _dash = <double>[2, 3];

ChartConfig _config(
  List<Dataset> datasets, {
  ChartKind type = ChartKind.bar,
  List<Object>? labels,
  ChartTitle? title,
  EdgeInsets? padding,
  ChartAnimation? animation = ChartAnimation.none,
  List<Map<String, Object?>>? plugins,
  Map<String, Object?>? extra,
}) => ChartConfig(
  type: type,
  labels: labels ?? _labels,
  datasets: datasets,
  title: title,
  padding: padding,
  animation: animation,
  plugins: plugins,
  extra: extra,
);

bool _report(ChartConfig first, ChartConfig next) {
  final lowering = ChartConfigLowering(first)..lower();
  expect(lowering.lastApplyDataOnly, isFalse);
  lowering.apply(next);
  return lowering.lastApplyDataOnly;
}

void main() {
  group('a report of data only', () {
    test('a new data List', () {
      expect(
        _report(
          _config([BarDataset(data: _data())]),
          _config([BarDataset(data: _data())]),
        ),
        isTrue,
      );
    });

    test('a new points List', () {
      List<DataPoint> points() => <DataPoint>[DataPoint(1, 2)];
      expect(
        _report(
          _config([ScatterDataset(points: points())], type: ChartKind.scatter),
          _config([ScatterDataset(points: points())], type: ChartKind.scatter),
        ),
        isTrue,
      );
    });

    test('two datasets, one with a new List and one with the same', () {
      final same = _data();
      expect(
        _report(
          _config([
            BarDataset(key: _a, data: _data()),
            BarDataset(key: _b, data: same),
          ]),
          _config([
            BarDataset(key: _a, data: _data()),
            BarDataset(key: _b, data: same),
          ]),
        ),
        isTrue,
      );
    });

    test('an equal indexed color in a new ChartValue', () {
      Dataset dataset() => BarDataset(
        data: _data(),
        backgroundColor: ChartValue.indexed(
          <Color>[..._pair].map(ChartPaint.solid).toList(),
        ),
      );
      expect(_report(_config([dataset()]), _config([dataset()])), isTrue);
    });

    test('an equal borderDash in a new List', () {
      Dataset dataset() =>
          LineDataset(data: _data(), borderDash: <double>[..._dash]);
      expect(
        _report(
          _config([dataset()], type: ChartKind.line),
          _config([dataset()], type: ChartKind.line),
        ),
        isTrue,
      );
    });

    test('a data List of another length: the chart checks that', () {
      expect(
        _report(
          _config([BarDataset(data: _data())]),
          _config([BarDataset(data: _data(3))]),
        ),
        isTrue,
      );
    });
  });

  group('no report of data only', () {
    final dataset = BarDataset(key: _a, data: _data());

    test('an equal config', () {
      final first = _config([dataset]);
      final lowering = ChartConfigLowering(first)
        ..lower()
        ..apply(_config([BarDataset(key: _a, data: _data())]));
      expect(lowering.lastApplyDataOnly, isTrue);
      final last = lowering.config;
      lowering.apply(last.copyWith(datasets: <Dataset>[...last.datasets]));
      expect(lowering.lastApplyDataOnly, isFalse);
    });

    test('a new lowering after a report', () {
      final first = _config([dataset]);
      final lowering = ChartConfigLowering(first)
        ..lower()
        ..apply(_config([BarDataset(key: _a, data: _data())]));
      expect(lowering.lastApplyDataOnly, isTrue);
      lowering.lower();
      expect(lowering.lastApplyDataOnly, isFalse);
    });

    test('the type', () {
      expect(
        _report(
          _config([BarDataset(data: _data())]),
          _config([BarDataset(data: _data())], type: ChartKind.line),
        ),
        isFalse,
      );
    });

    test('a new labels List with the same items', () {
      expect(
        _report(
          _config([BarDataset(data: _data())]),
          _config([BarDataset(data: _data())], labels: <Object>[..._labels]),
        ),
        isFalse,
      );
    });

    test('an option field', () {
      expect(
        _report(
          _config([BarDataset(data: _data())]),
          _config([
            BarDataset(data: _data()),
          ], title: const ChartTitle(text: 't')),
        ),
        isFalse,
      );
      expect(
        _report(
          _config([BarDataset(data: _data())]),
          _config([
            BarDataset(data: _data()),
          ], padding: const EdgeInsets.all(2)),
        ),
        isFalse,
      );
    });

    test('an entry of extra of the config', () {
      expect(
        _report(
          _config([BarDataset(data: _data())]),
          _config(
            [BarDataset(data: _data())],
            extra: const {'locale': Locale('de', 'DE')},
          ),
        ),
        isFalse,
      );
    });

    test('a replaced plugin', () {
      expect(
        _report(
          _config(
            [BarDataset(data: _data())],
            plugins: [
              <String, Object?>{'id': 'a'},
            ],
          ),
          _config(
            [BarDataset(data: _data())],
            plugins: [
              <String, Object?>{'id': 'b'},
            ],
          ),
        ),
        isFalse,
      );
    });

    test('a dataset key', () {
      expect(
        _report(
          _config([BarDataset(key: _a, data: _data())]),
          _config([BarDataset(key: _b, data: _data())]),
        ),
        isFalse,
      );
    });

    test('keyed datasets in a new order', () {
      expect(
        _report(
          _config([
            BarDataset(key: _a, data: _data()),
            BarDataset(key: _b, data: _data()),
          ]),
          _config([
            BarDataset(key: _b, data: _data()),
            BarDataset(key: _a, data: _data()),
          ]),
        ),
        isFalse,
      );
    });

    test('a new and a removed dataset', () {
      final one = _config([BarDataset(key: _a, data: _data())]);
      final two = _config([
        BarDataset(key: _a, data: _data()),
        BarDataset(key: _b, data: _data()),
      ]);
      expect(_report(one, two), isFalse);
      expect(_report(two, one), isFalse);
    });

    test('another dataset class at the index', () {
      expect(
        _report(
          _config([BarDataset(data: _data())]),
          _config([LineDataset(data: _data())]),
        ),
        isFalse,
      );
    });

    for (final (name, changed)
        in <(String, Dataset Function(List<double> data))>[
          ('a label', (data) => BarDataset(data: data, label: 'l')),
          ('hidden', (data) => BarDataset(data: data, hidden: true)),
          ('an order', (data) => BarDataset(data: data, order: 1)),
          ('a stack', (data) => BarDataset(data: data, stack: 's')),
          ('an axis id', (data) => BarDataset(data: data, yAxisID: 'y2')),
          ('a width', (data) => BarDataset(data: data, borderWidth: 2)),
          (
            'a constant color',
            (data) => BarDataset(
              data: data,
              backgroundColor: const ChartValue.constant(.solid(_red)),
            ),
          ),
          (
            'an extra entry',
            (data) =>
                BarDataset(data: data, extra: const {'clip': ChartClip.all(5)}),
          ),
        ]) {
      test('a dataset field that comes: $name', () {
        expect(
          _report(
            _config([BarDataset(data: _data())]),
            _config([changed(_data())]),
          ),
          isFalse,
        );
      });

      test('a dataset field that goes: $name', () {
        expect(
          _report(
            _config([changed(_data())]),
            _config([BarDataset(data: _data())]),
          ),
          isFalse,
        );
      });
    }

    test('a replaced indexed color', () {
      Dataset colored(List<Color> colors) => BarDataset(
        data: _data(),
        backgroundColor: ChartValue.indexed(
          colors.map(ChartPaint.solid).toList(),
        ),
      );
      expect(
        _report(
          _config([
            colored([_red, _green]),
          ]),
          _config([
            colored([_red, _blue]),
          ]),
        ),
        isFalse,
      );
      expect(
        _report(
          _config([
            colored([_red, _green]),
          ]),
          _config([
            colored([_red, _green, _blue]),
          ]),
        ),
        isFalse,
      );
    });

    test('a constant color that becomes an indexed one', () {
      expect(
        _report(
          _config([
            BarDataset(
              data: _data(),
              backgroundColor: const ChartValue.constant(.solid(_red)),
            ),
          ]),
          _config([
            BarDataset(
              data: _data(),
              backgroundColor: const ChartValue.indexed([
                ChartPaint.solid(_red),
              ]),
            ),
          ]),
        ),
        isFalse,
      );
    });

    test('a resolved color: a new bridge in each lowering', () {
      ChartPaint resolve(ChartContext context) => const ChartPaint.solid(_red);
      Dataset colored() => BarDataset(
        data: _data(),
        backgroundColor: ChartValue.resolver(resolve),
      );
      expect(_report(_config([colored()]), _config([colored()])), isFalse);
    });

    test('a new extra List with the same items: it goes by reference', () {
      Dataset dataset(List<Object?> list) => BarDataset(
        data: _data(),
        extra: <String, Object?>{'backgroundColor': list},
      );
      expect(
        _report(
          _config([
            dataset(<Object?>[_red]),
          ]),
          _config([
            dataset(<Object?>[_red]),
          ]),
        ),
        isFalse,
      );
    });

    test('the same extra List stays data only', () {
      final list = <Object?>[_red];
      Dataset dataset() => BarDataset(
        data: _data(),
        extra: <String, Object?>{'backgroundColor': list},
      );
      expect(_report(_config([dataset()]), _config([dataset()])), isTrue);
    });

    test('an equal extra Map of a dataset: a new scope in each lowering', () {
      Dataset dataset() => BarDataset(
        data: _data(),
        extra: const {
          'datalabels': {'a': 1},
        },
      );
      expect(_report(_config([dataset()]), _config([dataset()])), isFalse);
    });

    test('a data List that goes', () {
      expect(
        _report(
          _config([BarDataset(data: _data())]),
          _config([const BarDataset()]),
        ),
        isFalse,
      );
    });
  });

  group('the patch of an equal indexed color', () {
    test('still writes the new List and the new data', () {
      Dataset dataset() => BarDataset(
        data: _data(),
        backgroundColor: ChartValue.indexed(
          <Color>[..._pair].map(ChartPaint.solid).toList(),
        ),
      );
      final lowering = ChartConfigLowering(_config([dataset()]));
      final root = lowering.lower();
      final data = root.dataCell!.raw;
      final firstColors =
          (((data! as JsObjectFace)['datasets']! as List).single
              as JsObjectFace)['backgroundColor'];
      final next = dataset();
      lowering.apply(_config([next]));
      final scope = ((data as JsObjectFace)['datasets']! as List).single;
      final written = (scope as JsObjectFace)['backgroundColor']! as List;
      expect(written, [
        const ChartPaint.solid(_red),
        const ChartPaint.solid(_green),
      ]);
      expect(scope['data'], same((next as BarDataset).data));
      expect(written, isNot(same(firstColors)));
    });
  });

  group('animationOff', () {
    bool off(ChartConfig config) =>
        (ChartConfigLowering(config)..lower()).animationOff;

    test('ChartAnimation.none', () {
      expect(off(_config([BarDataset(data: _data())])), isTrue);
    });

    test('a copy of ChartAnimation.none', () {
      expect(
        off(
          _config(
            [BarDataset(data: _data())],
            animation: ChartAnimation.none.copyWith(
              duration: const Duration(seconds: 1),
            ),
          ),
        ),
        isTrue,
      );
    });

    test('no animation parameter', () {
      expect(
        off(_config([BarDataset(data: _data())], animation: null)),
        isFalse,
      );
    });

    test('an animation', () {
      expect(
        off(
          _config([
            BarDataset(data: _data()),
          ], animation: const ChartAnimation(duration: Duration(seconds: 1))),
        ),
        isFalse,
      );
    });

    test('false in extra', () {
      expect(
        off(
          _config(
            [BarDataset(data: _data())],
            animation: null,
            extra: const {'animation': false},
          ),
        ),
        isTrue,
      );
    });

    test('an object of extra over ChartAnimation.none', () {
      expect(
        off(
          _config(
            [BarDataset(data: _data())],
            extra: const {
              'animation': {'duration': 500},
            },
          ),
        ),
        isFalse,
      );
    });

    test('an imperative write into the live options', () {
      final lowering = ChartConfigLowering(
        _config([BarDataset(data: _data())]),
      );
      final root = lowering.lower();
      expect(lowering.animationOff, isTrue);
      (root.optionsCell!.raw! as ChartOptionsScope).animationCell =
          const OptValue<Object>(true);
      expect(lowering.animationOff, isFalse);
    });
  });
}
